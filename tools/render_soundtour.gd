extends Node
## The sound tour (the CC0 / CC BY sound swap, 2026-10-20): every sound effect,
## footstep, ambience loop and jingle heard where it happens, filmed the way
## render_showcase.gd films the animations. The candidate sounds come from a
## folder outside the project (--sounds=, default _giggle64_work/sfx_swap/out)
## and take over res://assets/audio/<name>.wav in the resource cache, so the
## game's own files are left alone. Windowed, recorded by Movie Maker:
##   Godot --path <project> --resolution 1280x720 --fixed-fps 30
##     --write-movie <dir>/f.avi res://tools/render_soundtour.tscn
##     -- --automation --out=<dir> [--sounds=<dir>] [--only=ambience,hero,...]
##     [--nointro] [--nooutro]   (to film the tour in parts and join them)
## Every sound the game starts is logged with its frame (sounds.json). When a
## stop's action did not start one of its sounds, the stop plays it itself,
## with the right thing on screen, and logs it as "cued".
## _giggle64_work/sfx_swap/make_tour.py makes the video.

const FPS := 30.0
const SOUNDS := "G:/Games/Godot Games/_giggle64_work/sfx_swap/out"
const SECTIONS := ["ambience", "hero", "combat", "items", "horse", "world", "creatures", "siege", "magic", "jingles", "ui"]

var _args := {}
var _main: Node
var _frame := 0
var _out := ""
var _recording := false
var _saves: Array[int] = []
var _hide_hud := false
var p: PlayerController
var _cam: Camera3D
var _orbit := false
var _orbit_center := Vector3.ZERO
var _orbit_yaw := 0.0
var _orbit_r := 5.0
var _orbit_h := 1.6
var _area := ""
## [{frame, title, sub, section?, card?}]: what make_tour.py writes over the picture.
var _captions: Array = []
## [{frame, name, how}]: every sound heard, "game" (the game started it),
## "cued" (the stop played it) or "loop" (an ambience or loop, marked by hand).
var _heard: Array = []
var _cueing := false
var _section := ""
## The candidate streams, kept alive so they stay in the resource cache.
var _keep: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	GameManager.widescreen = true
	GameManager.render_index = int(_args.get("res", "2"))
	GameManager.smoothing = true
	GameManager.guide_beacon = false
	GameManager.minimap_enabled = false
	GameManager.skip_title = true
	Guide.auto_scenes = false
	var mi := AudioServer.get_bus_index("Music")
	if mi >= 0:
		AudioServer.set_bus_mute(mi, true)
	_out = _args.get("out", "")
	_swap_sounds(_args.get("sounds", SOUNDS))
	Sfx.played.connect(_on_played)
	RenderingServer.frame_post_draw.connect(_grab)
	var only: PackedStringArray = (_args.get("only", "") as String).split(",", false)
	await _boot("field")
	if not _args.has("nointro"):
		await _title_card("GIGGLE 64 - THE NEW SOUNDS", "EVERY SOUND, WHERE IT HAPPENS", 3.0)
	for s: String in SECTIONS:
		if only.is_empty() or s in only:
			_section = s.to_upper()
			await call("_" + s)
	if not _args.has("nooutro"):
		await _title_card("GIGGLE 64", "SOUNDS: CC0 AND CC BY RECORDINGS - SEE DOCS/AUDIO_CREDITS.MD", 3.0)
	_recording = false
	for t in _saves:
		WorkerThreadPool.wait_for_task_completion(t)
	_saves.clear()
	_captions.append({"frame": _frame, "title": "", "sub": "", "end": true})
	if _out != "":
		for pair in [["captions.json", _captions], ["sounds.json", _heard]]:
			var f := FileAccess.open(_out.path_join(pair[0]), FileAccess.WRITE)
			f.store_string(JSON.stringify(pair[1], "  "))
			f.close()
	var names := {}
	for h: Dictionary in _heard:
		names[h.name] = true
	print("soundtour: %d sounds heard, %d cued" % [names.size(), _heard.filter(func(h: Dictionary) -> bool: return h.how == "cued").size()])
	await _frames(2)
	get_tree().quit()


## Every .wav in `dir` takes the place of res://assets/audio/<same name>.
func _swap_sounds(dir: String) -> void:
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".wav"):
			continue
		var s := AudioStreamWAV.load_from_file(dir.path_join(f))
		if s == null:
			push_warning("soundtour: could not read " + f)
			continue
		s.take_over_path(Sfx.AUDIO_DIR + f)
		_keep.append(s)
		n += 1
	print("soundtour: %d candidate sounds from %s" % [n, dir])


func _on_played(sfx_name: String) -> void:
	if _recording:
		_heard.append({"frame": _frame, "name": sfx_name, "how": "cued" if _cueing else "game"})


func _process(_delta: float) -> void:
	_frame += 1
	if _main:
		var vp := _main.get_node_or_null("GameView/GameViewport")
		if vp:
			for n in ["TransitionLayer", "DebugLayer"]:
				var l := vp.get_node_or_null(n) as CanvasLayer
				if l:
					l.visible = false
			var hud := vp.get_node_or_null("HUD") as CanvasLayer
			if hud:
				hud.visible = not _hide_hud
		World.title_alpha = 0.0
	if _orbit and _cam:
		_orbit_yaw += 0.25 / FPS
		_cam.global_position = _orbit_center + Vector3(sin(_orbit_yaw) * _orbit_r, _orbit_h, cos(_orbit_yaw) * _orbit_r)
		_cam.look_at(_orbit_center, Vector3.UP)
		_cam.current = true


# --- Booting, frames, captions --------------------------------------------------

func _boot(area: String, entrance := "") -> void:
	if _main:
		_recording = false
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(2)
	GameManager.start_game()
	World.fade = 0.0
	World.title_alpha = 0.0
	World.title_duration = 0.0
	await _frames(30)
	p = GameManager.player
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
	_cam = Camera3D.new()
	_cam.fov = 50.0
	World.area_node.add_child(_cam)
	_orbit = false
	_area = area
	_recording = true


## Boots `area` unless the tour is already there.
func _visit(area: String) -> void:
	if _area != area or _main == null:
		await _boot(area)
	_game_cam()


func caption(title: String, sub := "") -> void:
	_captions.append({"frame": _frame, "title": title, "sub": sub, "section": _section})
	print("soundtour: %d %s" % [_frame, title])


func _title_card(title: String, sub: String, secs: float) -> void:
	_recording = true
	_captions.append({"frame": _frame, "title": title, "sub": sub, "card": true})
	await _secs(secs)
	_captions.append({"frame": _frame, "title": "", "sub": ""})


func _grab() -> void:
	if _out == "" or _main == null or not _recording:
		return
	var vp := _main.get_node_or_null("GameView/GameViewport") as SubViewport
	if vp == null:
		return
	var path := _out.path_join("c%06d.jpg" % _frame)
	var img := vp.get_texture().get_image()
	_saves.append(WorkerThreadPool.add_task(func() -> void: img.save_jpg(path, 0.92)))
	while _saves.size() > 12:
		WorkerThreadPool.wait_for_task_completion(_saves.pop_front())


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(s: float) -> void:
	await _frames(int(round(s * FPS)))


# --- Stops ------------------------------------------------------------------------

## One stop: a caption, an action, then any of `want` the action did not start
## is played by hand (with whatever the action left on screen).
func _stop(title: String, sub: String, want: Array, action: Callable) -> void:
	caption(title, sub)
	var from := _frame
	if action.is_valid():
		await action.call()
	await _cue_missing(want, from)


func _heard_since(sfx_name: String, from: int) -> bool:
	for h: Dictionary in _heard:
		if h.frame >= from and h.name == sfx_name:
			return true
	return false


func _cue_missing(want: Array, from: int) -> void:
	for n: String in want:
		if not _heard_since(n, from):
			await _cue(n)


## Plays `sfx_name` as the game would, then waits for it to finish.
func _cue(sfx_name: String, wait := true) -> void:
	_cueing = true
	Sfx.play(sfx_name, 0.0, 0.0)
	_cueing = false
	if wait:
		var s: AudioStream = Sfx._stream(sfx_name)
		await _secs(clampf(s.get_length() if s else 0.5, 0.35, 4.0) + 0.3)


## A looping sound that does not go through Sfx (ambience, the fairy, the
## boomerang, the title wind): logged by hand.
func _mark_loop(sfx_name: String) -> void:
	_heard.append({"frame": _frame, "name": sfx_name, "how": "loop"})


## Plays a loop file directly for `secs` (the title wind).
func _play_loop(sfx_name: String, secs: float) -> void:
	var st := load(Sfx.AUDIO_DIR + sfx_name + ".wav") as AudioStreamWAV
	if st == null:
		return
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = int(st.get_length() * st.mix_rate)
	var pl := AudioStreamPlayer.new()
	pl.stream = st
	pl.bus = "SFX"
	add_child(pl)
	pl.play()
	_mark_loop(sfx_name)
	await _secs(secs)
	pl.queue_free()


# --- Placing the hero and the camera ------------------------------------------

func _game_cam() -> void:
	_orbit = false
	if _cam:
		_cam.current = false
	var rig := World.area_node.get_node_or_null("CameraRig") as AdventureCamera if World.area_node else null
	if rig:
		rig.snap_behind_target()


func _orbit_hero(r := 5.0, h := 1.6) -> void:
	_orbit_center = p.global_position + Vector3.UP * 1.0
	_orbit_r = r
	_orbit_h = h
	_orbit_yaw = p.rotation.y + PI * 0.75
	_orbit = true


## The director's camera at `from`, looking at `at`.
func _look(from: Vector3, at: Vector3) -> void:
	_orbit = false
	_cam.global_position = from
	_cam.look_at(at, Vector3.UP)
	_cam.current = true


## Looks across the hero and `target` from the side.
func _frame_pair(target: Vector3) -> void:
	var mid := (p.global_position + target) * 0.5 + Vector3.UP * 0.9
	var d := target - p.global_position
	d.y = 0.0
	var side := d.normalized().cross(Vector3.UP) if d.length() > 0.1 else Vector3.RIGHT
	_look(mid + side * maxf(4.5, d.length() * 1.4) + Vector3.UP * 1.6 - d.normalized() * 1.0, mid)


func _place(pos: Vector3, yaw: float) -> void:
	p.global_position = pos
	p.facing_yaw = yaw
	p.rotation.y = yaw
	p.velocity = Vector3.ZERO
	var rig := World.area_node.get_node_or_null("CameraRig") as AdventureCamera
	if rig:
		rig.snap_behind_target()


func _ground(x: float, z: float, from_y := 40.0) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, from_y - 120.0, z), 1)
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	return null if hit.is_empty() else hit.position


## The hero `dist` in front of `node`, facing it (from wherever he is now).
func _go_to(node: Node3D, dist := 2.2) -> void:
	var t := node.global_position
	var d := p.global_position - t
	d.y = 0.0
	if d.length() < 0.1:
		d = Vector3(0, 0, 1)
	var at := t + d.normalized() * dist
	var g = _ground(at.x, at.z, t.y + 4.0)
	if g != null:
		at = g + Vector3.UP * 0.2
	var face := t - at
	_place(at, atan2(-face.x, -face.z))
	await _secs(0.3)


## The node of a class (its class_name, or its script's file name for the
## scripts without one) in the area nearest the hero.
func _find(cls: String) -> Node3D:
	var best: Node3D = null
	var bd := INF
	for n in World.area_node.find_children("*", "Node3D", true, false):
		var sc: Script = n.get_script()
		if sc and (sc.get_global_name() == cls or sc.resource_path.get_file().get_basename() == cls):
			var dd := (n as Node3D).global_position.distance_to(p.global_position)
			if dd < bd:
				bd = dd
				best = n
	return best


func _walk(dir: Vector3, secs: float) -> void:
	var who := p
	who.debug_use_move_input = true
	who.debug_move_input = dir
	await _secs(secs)
	# (A walk can end in an area exit or a story scene that frees him.)
	if is_instance_valid(who):
		who.debug_move_input = Vector3.ZERO
		who.debug_use_move_input = false


## Presses as an input event (menus listen for events; the event also sets
## the polled action state the hero reads).
func _press(action: String, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _tap(action: String) -> void:
	_press(action, true)
	await _frames(2)
	_press(action, false)


func _hold(action: String, secs: float) -> void:
	_press(action, true)
	await _secs(secs)
	_press(action, false)


## Somewhere near the hero where the ground is `surface` with room to walk
## `room` m: [start, direction], or [] if there is none within `radius`.
func _find_surface(surface: String, radius := 70.0, room := 6.0) -> Array:
	var c := p.global_position
	var area := World.area_node
	var r := 0.0
	while r <= radius:
		var steps := maxi(1, int(r * 1.2))
		for k in steps:
			var a := TAU * k / steps
			var at := c + Vector3(cos(a), 0, sin(a)) * r
			var g = _ground(at.x, at.z, c.y + 25.0)
			if g == null or _surface_at(g, area) != surface:
				continue
			for dk in 8:
				var dir := Vector3(cos(TAU * dk / 8.0), 0, sin(TAU * dk / 8.0))
				var ok := true
				for s in [room * 0.25, room * 0.5, room * 0.75, room]:
					var q = _ground(g.x + dir.x * s, g.z + dir.z * s, g.y + 3.0)
					if q == null or absf(q.y - g.y) > 0.8 or _surface_at(q, area) != surface:
						ok = false
						break
				if ok:
					return [g + Vector3.UP * 0.2, dir]
		r += 3.0
	return []


func _surface_at(pos: Vector3, area: Node) -> String:
	if Surface.water_at(area, pos + Vector3.UP * 0.2) != "":
		return "water"
	return Surface.under(p.get_world_3d(), pos + Vector3.UP * 0.3, area, 0.6)


## Walks the hero over `surface` for `secs`, if there is any near.
func _walk_on(surface: String, secs := 3.5) -> bool:
	var small := surface in ["carpet", "ice", "wood"]
	var spot := _find_surface(surface, 160.0 if small else 70.0, 3.0 if small else 6.0)
	if spot.is_empty():
		print("soundtour: no %s ground in %s" % [surface, _area])
		return false
	var dir: Vector3 = spot[1]
	_place(spot[0], atan2(-dir.x, -dir.z))
	_game_cam()
	await _secs(0.4)
	await _walk(dir, secs)
	return true


func _spawn(path: String, dist: float, active := false) -> Node3D:
	var e: Node3D = (load(path) as PackedScene).instantiate()
	World.area_node.add_child(e)
	var at := p.global_position + p.forward() * dist
	var g = _ground(at.x, at.z, at.y + 4.0)
	e.global_position = (g + Vector3.UP * 0.1) if g != null else at
	e.look_at(Vector3(p.global_position.x, e.global_position.y, p.global_position.z), Vector3.UP)
	e.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	return e


func _hit(target: Node, damage: int) -> void:
	if not is_instance_valid(target) or not target.has_method("take_hit"):
		return
	var info := HitInfo.new()
	info.damage = damage
	info.attacker = p
	info.source_position = p.global_position
	target.take_hit(info)


func _heal() -> void:
	if p and p.health:
		p.health.health = p.health.max_health


# =============================================================================
# 1. Ambience and footsteps, area by area
# =============================================================================

func _ambience() -> void:
	await _title_card("AMBIENCE AND FOOTSTEPS", "EACH AREA'S BED, THEN THE GROUND UNDERFOOT", 2.5)
	# The title screen's wind, over the snowfields.
	await _visit("snow")
	_hide_hud = true
	_orbit_hero(7.0, 2.4)
	caption("WIND_LOOP", "The wind under the title screen")
	await _play_loop("wind_loop", 4.0)
	var stops := [
		# [area, ambience, surface or "", where]
		["field", "amb_field", "grass", "Bunsriel Fields"],
		["field", "amb_field", "dirt", "Bunsriel Fields, the castle road"],
		["village", "amb_village", "dirt", "Haven Village"],
		["castle_town", "amb_town", "stone", "Old Castle Town"],
		["castle_town_fallen", "amb_ruins", "", "Old Castle Town, fallen"],
		["forest", "amb_forest", "grass", "The Forest"],
		["hidden_forest", "amb_hidden", "", "The Hidden Forest"],
		["marsh", "amb_marsh", "mud", "West Marshlands"],
		["southern_fields", "amb_farm", "dirt", "Southern Fields"],
		["desert", "amb_desert", "sand", "Desert of Ladhellin"],
		["cliffs", "amb_cliffs", "", "Northeastern Cliffs"],
		["snow", "amb_snow", "snow", "Frostpeak"],
		["frostpeak_hollow", "amb_snow", "ice", "Frostpeak Hollow"],
		["lake", "amb_lake", "water", "Mirror Lake, the shallows"],
		["hero_house", "amb_hearth", "wood", "Gigglebuns' house"],
		["himeko_house", "amb_hearth", "carpet", "Himeko's palace"],
		["lake_shrine", "amb_shrine", "stone", "Lake Shrine"],
		["bog_tower", "amb_bog", "", "Bog Tower"],
		["forest_of_the_dead", "amb_dead", "", "Forest of the Dead"],
		["batela_fells", "amb_fells", "", "The Batela Fells"],
		["field_war", "amb_war", "", "Bunsriel Fields at war"],
		["barrow_of_kings", "amb_crypt", "", "Barrow of Kings"],
		["cinderhold", "amb_cinder", "ash", "Cinderhold"],
		["astral_rift", "amb_vision", "", "The Astral Rift"],
	]
	for s: Array in stops:
		await _visit(s[0])
		_hide_hud = true
		_orbit_hero()
		var steps := ("STEP_%s_0 / _1" % s[2].to_upper()) if s[2] != "" else ""
		caption(s[1].to_upper() + (("  +  " + steps) if steps != "" else ""), s[3])
		_mark_loop(s[1])
		await _secs(3.5)
		if s[2] != "":
			var from := _frame
			await _walk_on(s[2], 2.5 if s[2] in ["carpet", "ice", "wood"] else 3.5)
			await _cue_missing(["step_%s_0" % s[2], "step_%s_1" % s[2]], from)
	# Night, and rain on the stones.
	await _boot("field")
	DayNight.set_hour(23.0)
	_hide_hud = true
	_orbit_hero()
	caption("AMB_NIGHT  +  OWL_HOOT  +  NIGHT_HOWL", "Bunsriel Fields at night (owl_hoot is not used by the game yet)")
	_mark_loop("amb_night")
	await _secs(2.5)
	await _cue("owl_hoot")
	await _cue("night_howl")
	await _secs(1.0)
	Progress.set_flag(Weather.RAIN_FLAG)
	await _boot("village")
	DayNight.set_hour(12.0)
	_hide_hud = true
	_orbit_hero()
	caption("AMB_RAIN  +  STEP_WET_0 / _1", "Rain on Haven Village, wet paths underfoot")
	_mark_loop("amb_rain")
	await _secs(4.5)
	await _walk_on("dirt")
	await _cue_missing(["step_wet_0", "step_wet_1"], _frame - int(4 * FPS))
	Progress.set_flag(Weather.RAIN_FLAG, false)
	_hide_hud = false


# =============================================================================
# 2. The hero: jumping, climbing, ladders, swimming
# =============================================================================

func _hero() -> void:
	await _title_card("THE HERO", "JUMPING, CLIMBING, LADDERS, SWIMMING", 2.5)
	await _boot("test_area")
	_hide_hud = false
	await _stop("JUMP  +  LAND", "Running off the ruin platform", ["jump", "land"], func() -> void:
		_place(Vector3(4.5, 2.0, -24.5), PI)
		await _secs(0.8)
		await _walk(Vector3(0, 0, 1), 2.2)
		await _secs(0.6))
	await _stop("LEDGE_GRAB  +  CLIMB", "Jumping for a 3 m ledge and pulling up", ["ledge_grab", "climb"], func() -> void:
		var gy: float = _ground(10.0, 1.5) .y if _ground(10.0, 1.5) != null else 0.0
		_box(Vector3(10.0, gy + 1.25, 0.0), Vector3(4.0, 3.5, 3.0))
		_place(Vector3(10.0, gy + 0.3, 4.0), 0.0)
		await _secs(0.5)
		await _walk(Vector3(0, 0, -1), 3.5)
		await _secs(0.8))
	await _stop("LADDER_STEP", "Up a ladder and over the top", ["ladder_step"], func() -> void:
		var gy: float = _ground(-10.0, 2.0).y if _ground(-10.0, 2.0) != null else 0.0
		var top := gy + 4.2
		_box(Vector3(-10.0, gy + 1.85, 0.0), Vector3(4.0, 4.7, 3.0))
		_box(Vector3(-10.0, gy - 0.1 + (top - gy + 0.1) * 0.5, 1.575), Vector3(0.9, top - gy + 0.1, 0.15), {"ladder": true})
		_place(Vector3(-9.8, gy + 0.3, 4.0), 0.0)
		await _secs(0.5)
		await _walk(Vector3(0, 0, -1), 6.0)
		await _secs(0.5))
	await _stop("PLAYER_HURT", "A blow from behind", ["player_hurt"], func() -> void:
		_place(Vector3(0, 0.3, 10), 0.0)
		await _secs(0.4)
		var info := HitInfo.new()
		info.damage = 1
		info.source_position = p.global_position + p.forward() * -2.0
		p.take_hit(info)
		await _secs(1.2)
		_heal())
	await _stop("LOW_HEALTH", "One heart left: the alarm", ["low_health"], func() -> void:
		p.health.health = 1
		await _secs(3.0)
		_heal()
		await _secs(0.4))
	await _boot("lake")
	await _stop("SWIM_STROKE  +  STEP_WATER", "Wading in and swimming out in Mirror Lake", ["swim_stroke", "step_water_0", "step_water_1"], func() -> void:
		_place(Vector3(10, 0.2, 30), 0.0)
		_game_cam()
		await _secs(3.0)
		await _walk(Vector3(0, 0, -1), 3.0)
		await _secs(0.5))
	await _stop("SPLASH_BIG", "Something heavy hits the water", ["splash_big"], Callable())


## A solid box (layer 1) in the area; `meta` flags its shape (as the tests' _fixture).
func _box(center: Vector3, size: Vector3, meta := {}) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	for k in meta:
		cs.set_meta(k, meta[k])
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	b.add_child(mi)
	World.area_node.add_child(b)
	b.global_position = center
	return b


# =============================================================================
# 3. Combat
# =============================================================================

func _combat() -> void:
	await _title_card("COMBAT", "THE SWORD, THE SHIELD, AND WHAT THEY HIT", 2.5)
	await _boot("field")
	_hide_hud = false
	_heal()
	var home := p.global_position
	await _stop("SWORD_SWING", "Three cuts at the air", ["sword_swing"], func() -> void:
		_game_cam()
		for i in 3:
			await _tap("attack")
			await _secs(0.45)
		await _secs(0.6))
	await _stop("ENEMY_ALERT  +  ENEMY_ATTACK", "A goblin notices him and swings", ["enemy_alert", "enemy_attack"], func() -> void:
		_place(home, 0.0)
		var g := _spawn("res://scenes/enemies/basic_enemy.tscn", 7.0, true)
		_frame_pair(g.global_position)
		for i in 10:
			await _secs(0.5)
			_heal()
		g.queue_free())
	await _stop("SWORD_HIT  +  ENEMY_HURT  +  ENEMY_DEATH", "A combo on a goblin", ["sword_hit", "enemy_hurt", "enemy_death"], func() -> void:
		_place(home, 0.0)
		_game_cam()
		var g := _spawn("res://scenes/enemies/basic_enemy.tscn", 1.4)
		await _secs(0.4)
		for i in 6:
			await _tap("attack")
			await _secs(0.45)
		_hit(g, 99)
		await _secs(1.6))
	await _stop("SPIN_CHARGE  +  SPIN_READY  +  SPIN_ATTACK", "Holding B for the Great Spin", ["spin_charge", "spin_ready", "spin_attack"], func() -> void:
		Progress.set_flag(PlayerCombat.TECH_SPIN)
		_place(home, 0.0)
		_game_cam()
		await _secs(0.3)
		await _hold("attack", 1.8)
		await _secs(1.4))
	await _stop("SHIELD_BLOCK", "A goblin's blow on the shield", ["shield_block"], func() -> void:
		_place(home, 0.0)
		var g := _spawn("res://scenes/enemies/basic_enemy.tscn", 1.8)
		_frame_pair(g.global_position)
		Input.action_press("shield")
		await _secs(0.4)
		var info := HitInfo.new()
		info.damage = 1
		info.attacker = g
		info.source_position = g.global_position
		p.take_hit(info)
		await _secs(0.9)
		Input.action_release("shield")
		g.queue_free())
	await _stop("SHIELD_BASH", "Shield up, A: the bash", ["shield_bash"], func() -> void:
		Progress.set_flag(PlayerCombat.TECH_BASH)
		_place(home, 0.0)
		_game_cam()
		Input.action_press("shield")
		await _secs(0.4)
		await _tap("interact")
		await _secs(0.8)
		Input.action_release("shield")
		await _secs(0.3))
	await _stop("DOWN_THRUST", "The downward thrust", ["down_thrust"], func() -> void:
		Progress.set_flag(PlayerCombat.TECH_THRUST)
		_place(home, 0.0)
		_game_cam())
	await _stop("WALL_HIT_SOFT  +  WALL_HIT_HARD", "The blade glancing off a wall", ["wall_hit_soft", "wall_hit_hard"], func() -> void:
		_place(home, 0.0)
		var at := p.global_position + p.forward() * 1.3 + Vector3.UP * 1.0
		_box(at, Vector3(3.0, 2.5, 0.4))
		_game_cam()
		await _secs(0.4)
		for i in 3:
			await _tap("attack")
			await _secs(0.5)
		await _secs(0.4))
	await _stop("HEAVY_SWING  +  ARMOR_CLANG  +  HEAVY_STEP", "A knight's great swing, and its armour", ["heavy_swing", "armor_clang", "heavy_step"], func() -> void:
		_place(home, 0.0)
		var k := _spawn("res://scenes/enemies/barrow_knight.tscn", 4.0, true)
		_frame_pair(k.global_position)
		for i in 10:
			await _secs(0.5)
			_heal()
		_hit(k, 1)
		await _secs(0.8)
		k.queue_free())
	await _boot("lake")
	var target := _find("ArcheryTarget")
	await _stop("TARGET_HIT  +  TARGET_BELL", "The archery range at Mirror Lake", ["target_hit", "target_bell"], func() -> void:
		if target:
			await _go_to(target, 6.0)
			_frame_pair(target.global_position)
			await _secs(0.5))


# =============================================================================
# 4. Items
# =============================================================================

func _items() -> void:
	await _title_card("ITEMS", "EVERYTHING IN THE BAG", 2.5)
	await _boot("field")
	_hide_hud = false
	var home := p.global_position
	for id in ["bow", "boomerang", "hookshot", "bloom_rod", "iron_mallet", "grave_spade", "ember_rod", "looking_glass", "puff_nuts",
			"alans_harvest", "aphiels_gale", "serielyes_ruin", "sun_arrows"]:
		Progress.give_item(id)
	Progress.give_magic_meter()
	Progress.add_magic(99)
	Progress.give_bomb_bag()
	Progress.add_bombs(20)
	Progress.give_nut_pouch(20)
	Progress.arrows = 30
	var use := func(id: String, hold := 0.0, after := 1.6) -> void:
		_place(home, 0.0)
		_game_cam()
		Progress.assign("item_x", id)
		await _secs(0.3)
		if hold > 0.0:
			p.debug_bow_hold = true
		p._use_item("item_x")
		await _secs(hold)
		p.debug_bow_hold = false
		await _secs(after)
		if p.state == PlayerController.State.LOOK or p.state == PlayerController.State.AIM:
			p._leave_first_person()
		await _secs(0.4)
	await _stop("CAMERA_IN  +  BOW_DRAW  +  ARROW_SHOOT  +  ARROW_STICK  +  CAMERA_OUT", "The bow, into the ground ahead",
		["camera_in", "bow_draw", "arrow_shoot", "arrow_stick", "camera_out"], func() -> void: await use.call("bow", 1.4, 1.4))
	await _stop("BOW_FLICK", "The bow with no arrows", ["bow_flick"], func() -> void:
		Progress.arrows = 0
		await use.call("bow", 1.0, 1.0)
		Progress.arrows = 30)
	await _stop("ARROW_HIT", "An arrow into a goblin", ["arrow_hit"], func() -> void:
		var g := _spawn("res://scenes/enemies/basic_enemy.tscn", 6.0)
		_frame_pair(g.global_position)
		await _secs(0.3)
		await _cue("arrow_hit")
		g.queue_free())
	await _stop("SUN_ARROW", "A sun arrow", ["sun_arrow"], func() -> void: await use.call("sun_arrows", 1.4, 1.4))
	await _stop("BOOMERANG_THROW  +  BOOMERANG_SPIN  +  BOOMERANG_CATCH", "Thrown out and back", ["boomerang_throw", "boomerang_catch"], func() -> void:
		_mark_loop("boomerang_spin")
		await use.call("boomerang", 1.0, 3.0))
	await _stop("HOOKSHOT_FIRE  +  HOOKSHOT_REFLECT", "The hookshot at open air", ["hookshot_fire", "hookshot_reflect"], func() -> void:
		await use.call("hookshot", 1.2, 1.8))
	await _stop("HOOKSHOT_STICK", "The hookshot biting into a target", ["hookshot_stick"], Callable())
	await _stop("BOMB_FUSE  +  THROW  +  BOMB_BOUNCE  +  BOMB_EXPLODE", "A bomb: lit, thrown, gone", ["bomb_fuse", "throw", "bomb_bounce", "bomb_explode"], func() -> void:
		_place(home, 0.0)
		_game_cam()
		Progress.assign("item_x", "bombs")
		await _secs(0.3)
		p._use_item("item_x")
		await _secs(0.8)
		await _walk(Vector3(0, 0, -1), 0.4)
		await _tap("interact")
		await _secs(4.0))
	await _stop("SEED_SHOOT  +  BLOOM_GROW", "The bloom rod", ["seed_shoot", "bloom_grow"], func() -> void: await use.call("bloom_rod", 1.2, 1.6))
	await _stop("NUT_POP", "A puff nut", ["nut_pop"], func() -> void: await use.call("puff_nuts", 0.0, 1.6))
	await _stop("MALLET_SMASH", "The iron mallet", ["mallet_smash"], func() -> void: await use.call("iron_mallet", 0.0, 1.6))
	await _stop("DIG", "The grave spade", ["dig"], func() -> void: await use.call("grave_spade", 0.0, 2.0))
	await _stop("EMBER_CAST", "The ember rod", ["ember_cast"], func() -> void: await use.call("ember_rod", 1.0, 1.6))
	await _stop("LENS_ON", "The looking glass", ["lens_on"], func() -> void: await use.call("looking_glass", 0.0, 2.0))
	await _stop("MAGIC_CAST", "Alan's Harvest", ["magic_cast"], func() -> void: await use.call("alans_harvest", 0.0, 2.4))
	await _stop("WARP_WIND", "Aphiel's Gale", ["warp_wind"], func() -> void: await use.call("aphiels_gale", 0.0, 2.4))
	await _boot("field")
	home = p.global_position
	Progress.give_bottle("empty")
	await _stop("BOTTLE_SWING", "An empty bottle swung", ["bottle_swing"], func() -> void: await use.call("bottle_0", 0.0, 1.4))
	await _stop("BOTTLE_CATCH", "Something caught in it", ["bottle_catch"], Callable())
	Progress.set_bottle(0, "milk")
	await _stop("BOTTLE_POUR", "A drink of milk", ["bottle_pour"], func() -> void:
		p.health.health = 3
		await use.call("bottle_0", 0.0, 2.2)
		_heal())


# =============================================================================
# 5. Biscuit
# =============================================================================

func _horse() -> void:
	await _title_card("BISCUIT", "RIDING", 2.5)
	await _boot("field")
	# Biscuit on the castle road, heading north: long, straight and open (the
	# riding tests' spot), a rail across it at z -14.
	var gy0 = _ground(0.0, 4.0)
	var h := Horse.spawn(World.area_node, Vector3(0.0, (gy0.y if gy0 != null else 0.0) + 0.1, 4.0), 0.0)
	var gr = _ground(0.0, -14.0)
	_box(Vector3(0.0, (gr.y if gr != null else 0.0) + 0.5, -14.0), Vector3(5.0, 1.0, 0.3))
	_place(h.global_position + Vector3(-1.3, 0.2, 2.5), 0.0)
	await _secs(0.5)
	await _stop("HORSE_NEIGH  +  HORSE_SNORT", "Biscuit, standing", ["horse_neigh", "horse_snort"], func() -> void:
		_frame_pair(h.global_position)
		await _secs(1.0))
	await _stop("HORSE_STEP  +  HORSE_SPUR  +  HORSE_JUMP  +  HORSE_LAND", "Mounted, a gallop, a carrot spent, over a rail",
			["horse_step", "horse_spur", "horse_jump", "horse_land"], func() -> void:
		var side := h.global_basis * Vector3(-1.3, 0, 0)
		p.global_position = h.global_position + side + Vector3.UP * 0.2
		p.face_direction(-side)
		await _secs(0.5)
		await _tap("interact")
		await _secs(0.6)
		_game_cam()
		p.debug_use_move_input = true
		p.debug_move_input = Vector3(0, 0, -1)
		await _secs(1.4)
		await _tap("interact")
		for i in 150:
			await _frames(1)
			if h.global_position.z < -20.0:
				break
		p.debug_move_input = Vector3(0, 0, 1)
		await _secs(1.5)
		p.debug_move_input = Vector3.ZERO)
	await _stop("CARROT_RECOVER", "A carrot grows back", ["carrot_recover"], func() -> void:
		await _secs(3.5)
		p.debug_use_move_input = false)


# =============================================================================
# 6. The world: doors, chests, pots, switches, stones
# =============================================================================

func _world() -> void:
	await _title_card("THE WORLD", "DOORS, CHESTS, POTS, SWITCHES, STONES", 2.5)
	_hide_hud = false
	# The Lake Shrine: a dungeon's furniture.
	await _boot("lake_shrine")
	await _object_stop("TreasureChest", "CHEST_OPEN", "A chest in the Lake Shrine", ["chest_open"], func(n: Node3D) -> void:
		n.interact(p)
		for i in 8:
			await _secs(0.6)
			await _tap("interact"))
	await _object_stop("Shutter", "SHUTTER_CLOSE  +  SHUTTER_OPEN", "A dungeon gate falling and rising", ["shutter_close", "shutter_open"], func(n: Node3D) -> void:
		n.close()
		await _secs(1.6)
		n.open()
		await _secs(1.6))
	await _object_stop("FloorSwitch", "SWITCH_PRESS  +  PUZZLE_SOLVED", "A floor switch", ["switch_press", "puzzle_solved"], func(n: Node3D) -> void:
		n.press()
		await _secs(3.0))
	await _object_stop("LockedDoor", "DOOR_UNLOCK", "A locked door and a small key", ["door_unlock"], Callable())
	await _object_stop("CrystalSwitch", "CRYSTAL_HIT", "A crystal switch struck", ["crystal_hit"], func(n: Node3D) -> void:
		_hit(n, 1)
		await _secs(1.6))
	await _object_stop("BrittleCrust", "ROCK_BREAK", "A brittle crust smashed", ["rock_break"], func(n: Node3D) -> void:
		var info := HitInfo.new()
		info.damage = 4
		info.heavy = true
		info.attacker = p
		info.source_position = p.global_position
		n.take_hit(info)
		await _secs(1.2))
	# The castle: pots, torches, signs, cracked walls.
	await _boot("castle")
	await _object_stop("Pot", "LIFT_POT  +  THROW  +  POT_BREAK", "A pot lifted, thrown, smashed", ["lift_pot", "throw", "pot_break"], func(n: Node3D) -> void:
		_game_cam()
		n.lift(p)
		await _secs(1.0)
		await _tap("interact")
		await _secs(1.4))
	await _object_stop("Torch", "TORCH_LIGHT", "A torch catching", ["torch_light"], func(n: Node3D) -> void:
		n.light_up()
		await _secs(1.4))
	await _object_stop("Signpost", "SIGN_CUT", "A signpost cut in half", ["sign_cut"], func(n: Node3D) -> void:
		_hit(n, 1)
		await _secs(1.2))
	await _object_stop("BombWall", "ROCK_BREAK  +  PUZZLE_SOLVED", "A cracked wall blown open", ["rock_break"], func(n: Node3D) -> void:
		n.bomb_hit(p.global_position)
		await _secs(2.4))
	await _object_stop("SunShaft", "LIGHT_HUM", "A shaft of sunlight", ["light_hum"], func(_n: Node3D) -> void: await _secs(2.0))
	# The field: grass, rocks, the great stone.
	await _boot("field")
	await _object_stop("Shrub", "GRASS_CUT  +  BUSH_CUT", "A shrub cut down", ["grass_cut", "bush_cut"], func(n: Node3D) -> void:
		n.cut_down()
		await _secs(1.2))
	await _object_stop("Shrub", "LIFT_PLANT", "A shrub pulled up", ["lift_plant"], func(n: Node3D) -> void:
		_game_cam()
		n.lift(p)
		await _secs(1.4))
	Progress.give_item("questlord_gauntlets")
	await _object_stop("LiftRock", "LIFT_ROCK", "A rock lifted", ["lift_rock"], func(n: Node3D) -> void:
		_game_cam()
		n.lift(p)
		await _secs(1.6))
	await _object_stop("GreatStone", "STONE_GRIP  +  STONE_DRAG  +  QUAKE_RUMBLE", "The great stone dragged", ["stone_grip", "stone_drag", "quake_rumble"], func(n: Node3D) -> void:
		n.interact(p)
		await _secs(4.0))
	# Doors, cups, an anvil, books.
	await _boot("village")
	await _object_stop("Door", "DOOR_OPEN", "A house door in Haven", ["door_open"], func(n: Node3D) -> void:
		n.interact(p)
		await _secs(1.6))
	await _boot("castle_town")
	await _object_stop("CupGame", "CUP_LIFT  +  CUP_SLIDE", "The shell game in Old Castle Town", ["cup_lift", "cup_slide"], Callable())
	await _boot("armory")
	await _object_stop("", "ANVIL", "Pink's armory", ["anvil"], Callable())
	await _boot("castle_town_restored")
	await _object_stop("TechniqueTarget", "WOOD_BREAK  +  TEMPLE_BELL", "The training posts in Castle Town", ["wood_break", "temple_bell"], Callable())
	await _boot("field_war")
	await _object_stop("", "WOOD_CRASH", "A siege ladder crashing down", ["wood_crash"], Callable())
	# Fire, ice and lava.
	await _boot("forest")
	await _object_stop("Burnable", "FIRE_WHOOSH  +  SIZZLE", "Brambles burned away", ["fire_whoosh", "sizzle"], Callable())
	await _boot("snow")
	await _object_stop("MalletStake", "ICE_CRACK  +  ICE_SHATTER  +  ICE_FREEZE", "Ice in Frostpeak", ["ice_crack", "ice_shatter", "ice_freeze"], Callable())
	await _boot("cinder_vault")
	await _object_stop("", "LAVA_BUBBLE", "Lava in the Cinder Vault", ["lava_bubble"], Callable())
	await _boot("village")
	await _object_stop("", "BOOK_SLAM  +  PAGE_FLUTTER", "Haven's books (the Incunax's sounds)", ["book_slam", "page_flutter"], Callable())


## A stop at the nearest `cls` in the area (or where the hero stands when
## `cls` is "" or not here): the hero in front of it, the camera across them.
func _object_stop(cls: String, title: String, sub: String, want: Array, action: Callable) -> void:
	var n: Node3D = _find(cls) if cls != "" else null
	if n:
		await _go_to(n, 1.1 if cls in ["Pot", "Shrub", "LiftRock"] else 2.2)
		_frame_pair(n.global_position)
	else:
		_hide_hud = true
		_orbit_hero(4.5, 1.4)
	await _stop(title, sub, want, func() -> void:
		if n and action.is_valid():
			await action.call(n)
		else:
			await _secs(0.6))
	_hide_hud = false


# =============================================================================
# 7. Creatures
# =============================================================================

func _creatures() -> void:
	await _title_card("CREATURES", "THE BESTIARY, AND THE ANIMALS", 2.5)
	var list := [
		# [area, scene, title, where, sounds]
		["forest", "keese", "KEESE_CRY", "A keese in the forest", ["keese_cry"]],
		["castle", "rat", "RAT_SQUEAK", "A rat in the castle", ["rat_squeak"]],
		["barrow_of_kings", "stalfos", "BONE_RATTLE  +  HOP", "A stalfos in the Barrow", ["bone_rattle", "hop"]],
		["desert", "mummy", "MUMMY_MOAN", "A mummy in the desert", ["mummy_moan"]],
		["forest_of_the_dead", "shade", "SHADE_SHRIEK", "A shade in the Forest of the Dead", ["shade_shriek"]],
		["lake", "octorok", "BUBBLE_POP  +  SPLASH_BIG", "An octorok in Mirror Lake", ["bubble_pop", "splash_big"]],
		["lake_shrine", "shellblade", "SHELL_CLAMP  +  SNAP", "A shellblade in the Lake Shrine", ["shell_clamp", "snap"]],
		["desert", "leever", "SAND_HISS", "A leever in the desert", ["sand_hiss"]],
		["field", "shadow_wolf", "SNAP  +  HOP", "A shadow wolf", ["snap", "hop"]],
		["field", "tektite", "HOP  +  JUMP  +  LAND", "A tektite", ["hop"]],
		["cliffs", "corvax", "WING_FLAP", "Corvax over the cliffs", ["wing_flap"]],
		["field_war", "boar_rider", "BOAR_SQUEAL", "A boar rider", ["boar_squeal"]],
		["field_war", "siege_ogre", "OGRE_ROAR", "The siege ogre", ["ogre_roar"]],
		["snow", "sleetcoil", "SERPENT_ROAR", "Sleetcoil in the snow", ["serpent_roar"]],
		["marsh", "gullagog", "TOAD_CROAK  +  TOAD_INHALE  +  WHIP_CRACK", "Gullagog, the Mire Toad", ["toad_croak", "toad_inhale", "whip_crack"]],
		["lake_shrine", "carapax", "BOSS_ROAR  +  BOSS_STOMP  +  BOSS_HURT  +  BOSS_DIE", "Carapax, a boss", ["boss_roar", "boss_stomp", "boss_hurt", "boss_die"]],
		["barrow_of_kings", "hollow_king", "UNDEAD_RISE", "The Hollow King", ["undead_rise"]],
		["castle", "firebuns", "FIREBUNS_LAUGH", "Firebuns III", ["firebuns_laugh"]],
		["batela_fells", "dark_gigglebuns", "SHIVER", "The shadow knight", ["shiver"]],
	]
	for c: Array in list:
		await _visit(c[0])
		_heal()
		var e := _spawn("res://scenes/enemies/%s.tscn" % c[1], 7.0, true)
		_frame_pair(e.global_position)
		await _stop(c[2], c[3], c[4], func() -> void:
			for i in 6:
				await _secs(0.5)
				_heal())
		if is_instance_valid(e):
			e.queue_free()
	# The animals.
	await _boot("village")
	await _object_stop("Rooster", "ROOSTER  +  COCK-A-DOODLE  +  CLUCK  +  ROOSTER_ANGRY", "Haven's rooster", ["rooster", "cluck", "rooster_angry"], func(n: Node3D) -> void:
		_hit(n, 1)
		await _secs(1.4))
	await _object_stop("Pepper", "DOG_BARK", "Pepper the dog", ["dog_bark"], Callable())


# =============================================================================
# 7b. The siege: archers and the ballista
# =============================================================================

func _siege() -> void:
	await _title_card("THE SIEGE", "ARCHERS AND THE BALLISTA", 2.0)
	await _visit("field")
	_heal()
	var archer := _spawn("res://scenes/enemies/goblin_archer.tscn", 9.0, true)
	_frame_pair(archer.global_position)
	await _stop("BOW_SHOOT  +  BOW_DRAW", "A goblin archer", ["bow_shoot"], func() -> void:
		for i in 10:
			await _secs(0.5)
			_heal())
	if is_instance_valid(archer):
		archer.queue_free()
	await _boot("village_refuge")
	await _object_stop("Ballista", "BALLISTA_FIRE  +  ARROW_STICK", "The ballista at the Haven Refuge", ["ballista_fire"], func(n: Node3D) -> void:
		n.interact(p)
		await _secs(1.0)
		n.fire()
		await _secs(2.0)
		n.leave()
		await _secs(0.5))


# =============================================================================
# 8. Magic and the story
# =============================================================================

func _magic() -> void:
	await _title_card("MAGIC AND THE STORY", "GODDESSES, MAGES, WARPS, WAR", 2.5)
	await _boot("spring_alan")
	await _object_stop("GoddessSpring", "GODDESS_APPEAR  +  GODDESS_CHIME", "Alan's spring", ["goddess_appear", "goddess_chime"], func(n: Node3D) -> void:
		n.appear(p)
		for i in 10:
			await _secs(0.5)
			await _tap("interact"))
	await _object_stop("Fairy", "FAIRY_LOOP  +  FAIRY_HEAL", "A fairy in the spring", ["fairy_heal"], func(n: Node3D) -> void:
		_mark_loop("fairy_loop")
		p.health.health = 2
		await _secs(1.2)
		p.global_position = n.global_position
		await _secs(2.4)
		_heal())
	await _boot("lake_shrine")
	await _object_stop("BlueWarp", "WARP", "The blue warp", ["warp"], Callable())
	await _object_stop("TempleBell", "TARGET_BELL", "The shrine bell", ["target_bell"], func(n: Node3D) -> void:
		n.strike(p.global_position)
		await _secs(2.0))
	await _boot("forest_of_the_dead")
	await _object_stop("wisp_light", "WISP_CHIME", "A wisp in the Forest of the Dead", ["wisp_chime"], Callable())
	await _boot("sapphire_sanctum")
	await _object_stop("SapphireWard", "WARD_OUT", "A sapphire ward guttering out", ["ward_out"], Callable())
	_heal()
	var mage := _spawn("res://scenes/enemies/sapphire_mage.tscn", 6.0, true)
	_frame_pair(mage.global_position)
	await _stop("MAGE_APPEAR  +  MAGE_CAST", "A mage of the Sapphire Order", ["mage_appear", "mage_cast"], func() -> void:
		for i in 8:
			await _secs(0.5)
			_heal())
	if is_instance_valid(mage):
		mage.queue_free()
	await _boot("field")
	await _stop("SWORD_BEAM  +  MAGIC_BURST", "The sword's beam at full health", ["sword_beam", "magic_burst"], Callable())
	await _boot("field_war")
	await _object_stop("", "WAR_HORN  +  BEACON_FLARE", "Bunsriel at war", ["war_horn", "beacon_flare"], Callable())
	await _boot("castle_town")
	await _object_stop("", "ALARM", "The alarm over Old Castle Town", ["alarm"], Callable())
	await _boot("astral_rift")
	await _object_stop("AstralGate", "WARP  +  GODDESS_CHIME", "The Astral Rift's gate", ["goddess_chime"], Callable())


# =============================================================================
# 9. Jingles
# =============================================================================

func _jingles() -> void:
	await _title_card("JINGLES", "ON THE MOTIFS, IN XADRA'S LOZ SOUNDFONT", 2.5)
	await _boot("field")
	_hide_hud = false
	var home := p.global_position
	for it: Array in [["small_key", "FANFARE_ITEM", "A small key: the main motif"],
			["longshot", "FANFARE_BIG", "The longshot: the main motif, full brass"],
			["heart_container", "HEART_CONTAINER", "A heart container: Lothelye's theme"]]:
		await _stop(it[1], it[2], [it[1].to_lower()], func() -> void:
			_place(home, 0.0)
			_game_cam()
			await _secs(0.3)
			GetItem.present(p, it[0])
			for i in 9:
				await _secs(0.6)
				await _tap("interact"))
	var pick := func(kind: String) -> void:
		var c := Drops.spawn(kind, p.global_position + p.forward() * 1.5 + Vector3.UP * 0.3, World.area_node, false)
		await _secs(0.5)
		if is_instance_valid(c):
			c.collect(p)
		await _secs(1.6)
	await _stop("RUPEE", "A green rupee", ["rupee"], func() -> void: await pick.call("rupee_green"))
	await _stop("RUPEE_BIG", "A red rupee", ["rupee_big"], func() -> void: await pick.call("rupee_red"))
	await _stop("HEART", "A recovery heart", ["heart"], func() -> void:
		p.health.health = 4
		await pick.call("heart")
		_heal())
	await _stop("PICKUP", "A bundle of arrows", ["pickup"], func() -> void: await pick.call("arrows"))
	await _stop("MAGIC_REFILL", "A magic jar", ["magic_refill"], func() -> void:
		Progress.give_magic_meter()
		Progress.use_magic(20)
		await pick.call("magic_large"))
	await _stop("CARROT_RECOVER", "Biscuit's carrot (heard in the riding section too)", ["carrot_recover"], Callable())
	await _stop("PUZZLE_SOLVED", "A secret found", ["puzzle_solved"], Callable())
	await _stop("FAIRY_HEAL", "A fairy's healing: Avalon's motif", ["fairy_heal"], Callable())
	await _boot("hero_house")
	await _stop("REST_JINGLE", "A rest in the hero's bed: the main motif as a lullaby", ["rest_jingle"], func() -> void:
		DayNight.rest(DayNight.hour() + 8.0)
		await _secs(5.0))
	await _boot("spring_alan")
	await _stop("GODDESS_APPEAR", "Lothelye's theme on the choir", ["goddess_appear"], Callable())
	await _stop("GODDESS_CHIME", "The close of Lothelye's theme", ["goddess_chime"], Callable())


# =============================================================================
# 10. Menus and text
# =============================================================================

func _ui() -> void:
	await _title_card("MENUS AND TEXT", "", 2.0)
	await _boot("village")
	_hide_hud = false
	await _stop("MSG_OPEN  +  MSG_NEXT  +  MSG_CLOSE", "A text box", ["msg_open", "msg_next", "msg_close"], func() -> void:
		Dialogue.start(["The new sounds of Bunsriel: every one a recording, shared under Creative Commons.", "Trimmed, layered and leveled for the game."], null)
		for i in 8:
			await _secs(0.7)
			await _tap("interact")
		await _secs(0.6))
	await _stop("MENU_MOVE  +  MENU_SELECT  +  ITEM_POP", "The pause menu", ["menu_move", "menu_select", "item_pop"], func() -> void:
		await _tap("pause")
		await _secs(1.0)
		for a in ["move_right", "move_right", "move_back", "move_left"]:
			await _tap(a)
			await _secs(0.4)
		await _tap("interact")
		await _secs(0.6)
		await _tap("pause")
		await _secs(0.8))
	await _stop("ERROR", "Nothing on the button", ["error"], func() -> void:
		Progress.assign("item_x", "bombs")
		Progress.bombs = 0
		p._use_item("item_x")
		await _secs(0.8))
	await _stop("RUPEE_TICK", "The wallet counting up", ["rupee_tick"], func() -> void:
		Progress.add_rupees(60)
		await _secs(2.5))
