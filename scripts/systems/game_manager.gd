extends Node
## Global game state (title / playing / paused), level bookkeeping, settings,
## controller rumble and window helpers.

signal state_changed(new_state: int)
signal enemy_count_changed(alive: int, total: int)
signal settings_changed

enum GameState { TITLE, PLAYING, PAUSED }

## The version on the title screen (and in bug reports), and its tagline.
const VERSION := "BETA 1.9.0"
const TAGLINE := "FELLOWSHIP"

## Selectable frame rates. 21 is the "OoT" option: Ocarina of Time's game logic
## runs at 20 Hz on NTSC hardware and its frame rate hovers around 20-21 fps, so
## at 21 both the simulation and the picture tick at that rate (choppy, on purpose).
const FRAME_RATES := [60, 30, 21]
const SETTINGS_PATH := "user://settings.cfg"
## Modern camera speeds (SLOW / NORMAL / FAST): multipliers of the base orbit rate.
const CAMERA_SPEEDS := [0.6, 1.0, 1.6]
const CAMERA_SPEED_NAMES := ["SLOW", "NORMAL", "FAST"]
## GRAPHICS > RESOLUTION: the height the 3D world is drawn at (4:3). 240 is
## the N64's; the HUD and menus keep their 320x240 layout at every size.
const RENDER_HEIGHTS := [240, 480, 720, 1080, 1440, 2160]
const RENDER_NAMES := ["240P", "480P", "720P", "1080P", "1440P", "4K"]
## GRAPHICS > ASPECT RATIO 16:9: the 2D layout's width (240 * 16 / 9, rounded
## to an even number). Every 2D layer keeps its 320x240 layout centered in it;
## the HUD's left and right groups move out to the edges.
const WIDE_WIDTH := 426
## SOUND page defaults (slider steps out of 10).
## The actions the OPTIONS page's CONTROLS list can rebind, with their row
## names. Each keeps one keyboard key (or mouse button) and one gamepad
## button (or trigger); binding a new one replaces the old of the same kind.
const REMAP_ACTIONS := [
	["interact", "ACTION (A)"], ["attack", "SWORD (B)"], ["item_x", "ITEM X"], ["item_y", "ITEM Y"],
	["shield", "SHIELD"], ["target", "TARGET"], ["first_person", "LOOK"], ["camera_recenter", "RECENTER"],
	["walk", "WALK"], ["minimap", "MAP TOGGLE"], ["pause", "START"],
]
const DEFAULT_VOLUMES := {"master": 10, "music": 8, "sfx": 8, "footsteps": 7, "ambience": 7, "text": 8}

## Current frame rate (one of FRAME_RATES).
var frame_rate := 60
var rumble_enabled := true
## OoT's Z-target option (gSaveContext.zTargetSetting): false = Switch (a lock-on
## stays until Z is pressed again), true = Hold (it ends when Z is released).
var z_target_hold := false
## Corner minimap on/off (OoT toggles it with L).
var minimap_enabled := true
## First-person look and aiming: false = push up to look up, true = push up to
## look down (OoT's own first-person controls are inverted like a flight stick).
var invert_look := false
## Camera style: false = CLASSIC (OoT: the camera follows on its own and the
## right stick does nothing), true = MODERN (the right stick, or the mouse,
## orbits it; OoT's following resumes a moment after it is let go).
var camera_modern := false
## Index into CAMERA_SPEEDS for the modern camera.
var camera_speed := 1
## Modern camera: push right to swing the view left instead of right.
var camera_invert_x := false
## GRAPHICS: the soft bilinear upscale (the N64's look). Off = sharp pixels.
var smoothing := true
## GRAPHICS: each area's depth fog.
var fog_enabled := true
## GRAPHICS: the aiming reticle for the bow and the boomerang.
var crosshair := true
## Lothelye's guiding light (Guide): a column of light on the road to the
## story's next goal, out in the open.
var guide_beacon := true
## GRAPHICS: index into RENDER_HEIGHTS.
var render_index := 0
## GRAPHICS > TRUE N64 MODE (off by default): the RDP's 3-point texture
## filter, 16-bit dithered color and the VI's filters (N64Mode). It holds the
## picture at 240 lines whatever RESOLUTION says.
var true_n64 := false
## GRAPHICS > N64 MIPMAPS: with TRUE N64 MODE, the RDP's 2-cycle LOD blend.
var n64_mipmaps := false
## GRAPHICS > ASPECT RATIO: false = 4:3 (the N64's), true = 16:9 (the world
## is drawn wider; the camera keeps its height of view).
var widescreen := false
## GRAPHICS > HUD STYLE: false = CLASSIC (OoT's buttons), true = MODERN (the
## four face buttons in a diamond, shown with the pad's own glyphs).
var hud_modern := false
## GRAPHICS > BUTTON ICONS: index into Glyphs.FAMILIES (0 = AUTO, read from
## the pad's name).
var glyph_family := 0
## SOUND: each bus's volume as a slider step 0..AudioMix.STEPS (AudioMix.SLIDERS).
var volumes := DEFAULT_VOLUMES.duplicate()
## SOUND > OUTPUT: everything mixed down to one channel.
var mono_audio := false
## SOUND > PAUSE MUFFLE: music and ambience muffled behind the pause screen.
var pause_muffle := true
## Cutscenes watched at least once (any file): START skips them next time.
var seen_scenes := {}
## Mouse look speed in radians per pixel of motion (first person and aiming).
var mouse_sensitivity := 0.0035
var mouse_motion := Vector2.ZERO
## True when the most recent input came from a gamepad (switches HUD prompts).
var using_gamepad := false

var state: GameState = GameState.TITLE
var player: PlayerController = null
var enemies_total := 0
var enemies_alive := 0
## Skip the title screen (set by --skip-title, or after "Restart Area").
var skip_title := false
## Automation mode (--automation): never capture the mouse or auto-pause.
var automation := false
## Handheld mode (--handheld, passed by the PortMaster launcher): a new install
## starts at 30 fps, prompts use the handheld's button names, and the mouse is
## never captured or the game paused on focus loss (there is no desktop).
var handheld := false


## Each remappable action's bindings as the project set them (reset_controls).
var _default_events := {}


func _ready() -> void:
	for a: Array in REMAP_ACTIONS:
		_default_events[a[0]] = InputMap.action_get_events(a[0]).duplicate()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	skip_title = "--skip-title" in args
	automation = "--automation" in args or DisplayServer.get_name() == "headless"
	handheld = "--handheld" in args
	if handheld:
		frame_rate = 30
		var saver: Node = load("res://scripts/systems/handheld.gd").new()
		saver.name = "Handheld"
		add_child(saver)
	if handheld or "--perf" in args or Array(args).any(func(a: String) -> bool: return a.begins_with("--perf-area=")):
		var probe: Node = load("res://scripts/systems/perf_probe.gd").new()
		probe.name = "PerfProbe"
		add_child(probe)
	# Automated runs keep the default settings so results do not depend on the
	# player's saved options.
	if not automation:
		_load_settings()
	for a in args:
		if a.begins_with("--fps="):
			frame_rate = int(a.substr(6))
	if not automation or frame_rate != 60:
		apply_frame_rate()
	using_gamepad = not Input.get_connected_joypads().is_empty()
	# Screenshot tools (the manual, the box): Xbox glyphs with no pad attached.
	if "--pad-glyphs" in args:
		using_gamepad = true
		glyph_family = 1
	Input.joy_connection_changed.connect(func(_d: int, connected: bool) -> void:
		using_gamepad = connected or not Input.get_connected_joypads().is_empty())


# --- Settings -----------------------------------------------------------------

## Applies `frame_rate` to both rendering and the physics tick, so movement,
## animation and the camera all update at that rate.
func apply_frame_rate() -> void:
	Engine.physics_ticks_per_second = frame_rate
	Engine.max_fps = frame_rate
	Engine.max_physics_steps_per_frame = 8


func cycle_frame_rate() -> void:
	var i := FRAME_RATES.find(frame_rate)
	frame_rate = FRAME_RATES[(i + 1) % FRAME_RATES.size()]
	apply_frame_rate()
	_save_settings()
	settings_changed.emit()


func toggle_rumble() -> void:
	rumble_enabled = not rumble_enabled
	_save_settings()
	settings_changed.emit()
	if rumble_enabled:
		rumble(0.6, 0.2)


func toggle_z_target_mode() -> void:
	z_target_hold = not z_target_hold
	_save_settings()
	settings_changed.emit()


func toggle_minimap() -> void:
	minimap_enabled = not minimap_enabled
	_save_settings()
	settings_changed.emit()


func toggle_invert_look() -> void:
	invert_look = not invert_look
	_save_settings()
	settings_changed.emit()


func toggle_camera_mode() -> void:
	camera_modern = not camera_modern
	_changed()


func cycle_camera_speed() -> void:
	camera_speed = (camera_speed + 1) % CAMERA_SPEEDS.size()
	_changed()


func camera_speed_scale() -> float:
	return CAMERA_SPEEDS[clampi(camera_speed, 0, CAMERA_SPEEDS.size() - 1)]


func toggle_camera_invert_x() -> void:
	camera_invert_x = not camera_invert_x
	_changed()


func toggle_smoothing() -> void:
	smoothing = not smoothing
	_changed()


func toggle_fog() -> void:
	fog_enabled = not fog_enabled
	_changed()


func toggle_crosshair() -> void:
	crosshair = not crosshair
	_changed()


func toggle_guide_beacon() -> void:
	guide_beacon = not guide_beacon
	_changed()


func cycle_resolution() -> void:
	render_index = (render_index + 1) % RENDER_HEIGHTS.size()
	_changed()


func toggle_true_n64() -> void:
	true_n64 = not true_n64
	_changed()


func toggle_n64_mipmaps() -> void:
	n64_mipmaps = not n64_mipmaps
	_changed()


func render_height() -> int:
	if true_n64:
		return 240
	return RENDER_HEIGHTS[clampi(render_index, 0, RENDER_HEIGHTS.size() - 1)]


## Width of the picture at `height` lines (4:3 or 16:9, even).
func render_width(height: int) -> int:
	if widescreen:
		return int(round(height * 8.0 / 9.0)) * 2
	return int(round(height * 4.0 / 3.0))


func toggle_widescreen() -> void:
	widescreen = not widescreen
	_changed()


## Width of the 2D layout space: 320, or WIDE_WIDTH in 16:9.
func ui_width() -> float:
	return float(WIDE_WIDTH) if widescreen else 320.0


## How far the 320-wide layouts sit in from the left edge (0 in 4:3). Every
## CanvasLayer in the game view is offset by this much.
func ui_pad() -> float:
	return (ui_width() - 320.0) * 0.5


## The whole screen in a centered 320x240 layout's coordinates (wider than
## 0..320 in 16:9), for fades and backdrops.
func screen_rect() -> Rect2:
	return Rect2(-ui_pad(), 0.0, ui_width(), 240.0)


func toggle_hud_style() -> void:
	hud_modern = not hud_modern
	_changed()


func cycle_glyphs() -> void:
	glyph_family = (glyph_family + 1) % 4
	_changed()


## A SOUND slider's step (0..10).
func volume(key: String) -> int:
	return int(volumes.get(key, DEFAULT_VOLUMES.get(key, 10)))


## Moves a SOUND slider by `d` steps.
func nudge_volume(key: String, d: int) -> void:
	volumes[key] = clampi(volume(key) + d, 0, AudioMix.STEPS)
	_changed()


func toggle_mono() -> void:
	mono_audio = not mono_audio
	_changed()


func toggle_pause_muffle() -> void:
	pause_muffle = not pause_muffle
	_changed()


## Notes a cutscene as watched (kept with the settings, across files).
func mark_seen(scene_id: String) -> void:
	if scene_id == "" or seen_scenes.has(scene_id):
		return
	seen_scenes[scene_id] = true
	_save_settings()


func has_seen(scene_id: String) -> bool:
	return scene_id != "" and seen_scenes.has(scene_id)


func _changed() -> void:
	_save_settings()
	settings_changed.emit()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var fr: int = cfg.get_value("video", "frame_rate", 60)
	frame_rate = fr if fr in FRAME_RATES else 60
	rumble_enabled = cfg.get_value("input", "rumble", true)
	z_target_hold = cfg.get_value("input", "z_target_hold", false)
	minimap_enabled = cfg.get_value("video", "minimap", true)
	invert_look = cfg.get_value("input", "invert_look", false)
	camera_modern = cfg.get_value("input", "camera_modern", false)
	camera_speed = clampi(cfg.get_value("input", "camera_speed", 1), 0, CAMERA_SPEEDS.size() - 1)
	camera_invert_x = cfg.get_value("input", "camera_invert_x", false)
	smoothing = cfg.get_value("video", "smoothing", true)
	fog_enabled = cfg.get_value("video", "fog", true)
	crosshair = cfg.get_value("video", "crosshair", true)
	guide_beacon = cfg.get_value("game", "guide_beacon", true)
	render_index = clampi(cfg.get_value("video", "render_index", 0), 0, RENDER_HEIGHTS.size() - 1)
	true_n64 = cfg.get_value("video", "true_n64", false)
	n64_mipmaps = cfg.get_value("video", "n64_mipmaps", false)
	hud_modern = cfg.get_value("video", "hud_modern", false)
	widescreen = cfg.get_value("video", "widescreen", false)
	glyph_family = clampi(cfg.get_value("input", "glyph_family", 0), 0, 3)
	for key: String in DEFAULT_VOLUMES:
		volumes[key] = clampi(int(cfg.get_value("sound", key, DEFAULT_VOLUMES[key])), 0, 10)
	mono_audio = cfg.get_value("sound", "mono", false)
	pause_muffle = cfg.get_value("sound", "pause_muffle", true)
	for sid in cfg.get_value("scenes", "seen", []):
		seen_scenes[String(sid)] = true
	for a: Array in REMAP_ACTIONS:
		var saved = cfg.get_value("controls", a[0], []) if cfg.has_section_key("controls", a[0]) else []
		if saved is Array and not (saved as Array).is_empty():
			InputMap.action_erase_events(a[0])
			for e in saved:
				var ev := _event_from(e)
				if ev:
					InputMap.action_add_event(a[0], ev)


func _save_settings() -> void:
	if automation:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("video", "frame_rate", frame_rate)
	cfg.set_value("input", "rumble", rumble_enabled)
	cfg.set_value("input", "z_target_hold", z_target_hold)
	cfg.set_value("video", "minimap", minimap_enabled)
	cfg.set_value("input", "invert_look", invert_look)
	cfg.set_value("input", "camera_modern", camera_modern)
	cfg.set_value("input", "camera_speed", camera_speed)
	cfg.set_value("input", "camera_invert_x", camera_invert_x)
	cfg.set_value("video", "smoothing", smoothing)
	cfg.set_value("video", "fog", fog_enabled)
	cfg.set_value("video", "crosshair", crosshair)
	cfg.set_value("game", "guide_beacon", guide_beacon)
	cfg.set_value("video", "render_index", render_index)
	cfg.set_value("video", "true_n64", true_n64)
	cfg.set_value("video", "n64_mipmaps", n64_mipmaps)
	cfg.set_value("video", "hud_modern", hud_modern)
	cfg.set_value("video", "widescreen", widescreen)
	cfg.set_value("input", "glyph_family", glyph_family)
	for key: String in volumes:
		cfg.set_value("sound", key, volumes[key])
	cfg.set_value("sound", "mono", mono_audio)
	cfg.set_value("sound", "pause_muffle", pause_muffle)
	cfg.set_value("scenes", "seen", seen_scenes.keys())
	for a: Array in REMAP_ACTIONS:
		if not _same_events(InputMap.action_get_events(a[0]), _default_events.get(a[0], [])):
			cfg.set_value("controls", a[0], InputMap.action_get_events(a[0]).map(_event_to))
	cfg.save(SETTINGS_PATH)


# --- Controls ---------------------------------------------------------------------

## The action behind a CONTROLS row ("" for other rows).
static func remap_label(row: String) -> String:
	for a: Array in REMAP_ACTIONS:
		if a[1] == row:
			return a[0]
	return ""


## What kind of input an event is: "key", "mouse" or "pad".
static func _kind(e: InputEvent) -> String:
	if e is InputEventKey:
		return "key"
	if e is InputEventMouseButton:
		return "mouse"
	return "pad" if e is InputEventJoypadButton or e is InputEventJoypadMotion else ""


## Binds `event` to `action`: it replaces every binding the action had of the
## same kind (keys, mouse buttons or gamepad). Another action already using
## that input takes the action's old binding instead, so nothing is left
## unbound.
func remap(action: String, event: InputEvent) -> void:
	var ev := _clean(event)
	if ev == null:
		return
	var kind := _kind(ev)
	var olds: Array = InputMap.action_get_events(action).filter(func(e: InputEvent) -> bool: return _kind(e) == kind)
	for a: Array in REMAP_ACTIONS:
		if a[0] == action:
			continue
		for e in InputMap.action_get_events(a[0]):
			if _same(e, ev):
				InputMap.action_erase_event(a[0], e)
				if not olds.is_empty():
					InputMap.action_add_event(a[0], (olds[0] as InputEvent).duplicate())
	for e in olds:
		InputMap.action_erase_event(action, e)
	InputMap.action_add_event(action, ev)
	_changed()


func reset_controls() -> void:
	for a: Array in REMAP_ACTIONS:
		InputMap.action_erase_events(a[0])
		for e in _default_events.get(a[0], []):
			InputMap.action_add_event(a[0], e)
	_changed()


## The action's bindings as the CONTROLS row shows them: "J / B".
func binding_text(action: String) -> String:
	var key := "-"
	var pad := "-"
	for e in InputMap.action_get_events(action):
		if _kind(e) == "key" and key == "-":
			key = _event_name(e)
		elif _kind(e) == "pad" and pad == "-":
			pad = _event_name(e)
	# No key: the mouse button, if it has one.
	if key == "-":
		for e in InputMap.action_get_events(action):
			if _kind(e) == "mouse":
				key = _event_name(e)
				break
	return "%s / %s" % [key, pad]


static func _event_name(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
		return OS.get_keycode_string(code).to_upper().left(7)
	if e is InputEventMouseButton:
		return ["", "LMB", "RMB", "MMB"][e.button_index] if e.button_index <= 3 else "MB%d" % e.button_index
	if e is InputEventJoypadButton:
		var names := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "BACK", 6: "START", 7: "LS", 8: "RS", 9: "LB", 10: "RB", 11: "UP", 12: "DOWN", 13: "LEFT", 14: "RIGHT"}
		return names.get(e.button_index, "BTN%d" % e.button_index)
	if e is InputEventJoypadMotion:
		return {4: "LT", 5: "RT"}.get(e.axis, "AXIS%d" % e.axis)
	return "?"


## A copy of a pressed input that is fit to bind (device-free, unpressed).
static func _clean(e: InputEvent) -> InputEvent:
	if e is InputEventKey:
		var k := InputEventKey.new()
		k.physical_keycode = e.physical_keycode if e.physical_keycode != 0 else e.keycode
		return k
	if e is InputEventMouseButton:
		var m := InputEventMouseButton.new()
		m.button_index = e.button_index
		return m
	if e is InputEventJoypadButton:
		var b := InputEventJoypadButton.new()
		b.button_index = e.button_index
		b.device = -1
		return b
	if e is InputEventJoypadMotion:
		var j := InputEventJoypadMotion.new()
		j.axis = e.axis
		j.axis_value = 1.0 if e.axis_value > 0.0 else -1.0
		j.device = -1
		return j
	return null


static func _same(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class():
		return false
	if a is InputEventKey:
		return (a.physical_keycode if a.physical_keycode != 0 else a.keycode) == (b.physical_keycode if b.physical_keycode != 0 else b.keycode)
	if a is InputEventMouseButton or a is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


static func _same_events(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for e in a:
		if not b.any(func(o: InputEvent) -> bool: return _same(e, o)):
			return false
	return true


static func _event_to(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		return {"t": "key", "c": e.physical_keycode if e.physical_keycode != 0 else e.keycode}
	if e is InputEventMouseButton:
		return {"t": "mouse", "b": e.button_index}
	if e is InputEventJoypadButton:
		return {"t": "joy", "b": e.button_index}
	if e is InputEventJoypadMotion:
		return {"t": "axis", "a": e.axis, "v": e.axis_value}
	return {}


static func _event_from(d) -> InputEvent:
	if not (d is Dictionary):
		return null
	match String(d.get("t", "")):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.get("c", 0))
			return k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(d.get("b", 1))
			return m
		"joy":
			var b := InputEventJoypadButton.new()
			b.button_index = int(d.get("b", 0))
			b.device = -1
			return b
		"axis":
			var j := InputEventJoypadMotion.new()
			j.axis = int(d.get("a", 0))
			j.axis_value = float(d.get("v", 1.0))
			j.device = -1
			return j
	return null


## Vibrates every connected XInput/SDL gamepad. `strength` 0..1 drives the strong
## motor; the weak motor gets a bit more for a sharper buzz.
func rumble(strength: float, duration: float) -> void:
	if not rumble_enabled:
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, clampf(strength * 1.2, 0.0, 1.0), clampf(strength, 0.0, 1.0), duration)


## Mouse motion since the last call (first-person look and aiming read it).
func take_mouse_motion() -> Vector2:
	var m := mouse_motion
	mouse_motion = Vector2.ZERO
	return m


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and state == GameState.PLAYING:
		mouse_motion += (event as InputEventMouseMotion).relative
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_gamepad = false


## Called by the main scene before its children are ready.
func reset_level() -> void:
	clear_area()
	_set_state(GameState.PLAYING if skip_title else GameState.TITLE)


## Forgets the current area's player and enemies (World calls it before loading an area).
func clear_area() -> void:
	player = null
	enemies_total = 0
	enemies_alive = 0
	enemy_count_changed.emit(0, 0)


func register_player(p: PlayerController) -> void:
	player = p


func register_enemy(enemy: Enemy) -> void:
	enemies_total += 1
	enemies_alive += 1
	enemy.died.connect(_on_enemy_died)
	enemy_count_changed.emit(enemies_alive, enemies_total)


func _on_enemy_died() -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)
	enemy_count_changed.emit(enemies_alive, enemies_total)


func start_game() -> void:
	if state == GameState.TITLE:
		_set_state(GameState.PLAYING)


func pause_game() -> void:
	if state == GameState.PLAYING and not World.transitioning:
		_set_state(GameState.PAUSED)


func resume_game() -> void:
	if state == GameState.PAUSED:
		_set_state(GameState.PLAYING)


## Reloads the current area at the entrance the hero last came through.
func restart_area() -> void:
	Cutscene.stop_skip()
	skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()


## Back to the title screen (after the ending): a fresh boot of the main scene.
func return_to_title() -> void:
	Cutscene.stop_skip()
	skip_title = false
	get_tree().paused = false
	Dialogue.cancel()
	World.area_id = WorldData.START_AREA
	World.entrance_id = WorldData.START_ENTRANCE
	World.play_track("")
	Progress.reset()
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func toggle_fullscreen() -> void:
	var w := get_window()
	w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


func _set_state(new_state: GameState) -> void:
	state = new_state
	get_tree().paused = new_state != GameState.PLAYING
	if not automation and not handheld:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if new_state == GameState.PLAYING else Input.MOUSE_MODE_VISIBLE
	state_changed.emit(new_state)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	if state == GameState.PLAYING and Input.is_action_just_pressed("minimap"):
		toggle_minimap()
		Sfx.play("menu_move", -6.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not automation and not handheld:
		pause_game()
