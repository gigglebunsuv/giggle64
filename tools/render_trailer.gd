extends Node
## Trailer footage: plays one directed shot of the real game (areas, hero,
## creatures, story scenes) with the HUD, text boxes and title cards hidden,
## for Godot's Movie Maker to pace and record. Run windowed, one shot per run:
##   Godot --path <project> --resolution 1920x1080 --fixed-fps 30
##     --write-movie <dir>/f.avi res://tools/render_trailer.tscn
##     -- --automation --shot=<id> --out=<dir>
## The game draws at 1080p 16:9, and the game viewport itself is saved as
## <dir>/c<frame>.png while a shot records (rec()); Movie Maker's own frames
## come at the project's window size, so only its sound (f.avi) is used.
## Music is muted (the trailer's own track is laid on afterwards); sound
## effects and ambience are recorded. <dir>/marks.json holds the frames of
## the shot's marks (frame n = n / FPS seconds into f.avi's sound).
## The cut, music and titles are put together by
## _giggle64_work/trailer/make_trailer.py.

## Movie Maker's --fixed-fps.
const FPS := 30.0

var _args := {}
var _main: Node
var _frame := 0
var _marks := {}
## The director's own camera (null = the game's camera or a cutscene's).
var _cam: Camera3D
## Camera keys being played: [{t, eye, at, fov}], times from _cam_t0.
var _keys: Array = []
var _cam_t := 0.0
var _smooth_eye := Vector3.ZERO
var _smooth_at := Vector3.ZERO
var _smooth_set := false
var _hide_ui := true
var _auto_text := true
var _out := ""
var _recording := false
var _saves: Array[int] = []
## --scout=N: every Nth frame saved small (s<frame>.jpg) from the start, with
## the fade over it, to choose footage from. --ranges=a-b,c-d: the frames in
## those ranges saved full size, whatever the shot says.
var _scout := 0
var _ranges: Array = []
var _fades := {}
## The attract scene playing (its fade is logged while scouting).
var _scene: TitleScene


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	GameManager.widescreen = true
	# 1080P (scouting draws smaller: --res=<RENDER_HEIGHTS index>).
	GameManager.render_index = int(_args.get("res", "3"))
	GameManager.smoothing = true
	GameManager.guide_beacon = false
	GameManager.crosshair = false
	GameManager.minimap_enabled = false
	GameManager.skip_title = true
	_mute_music()
	_out = _args.get("out", "")
	_scout = int(_args.get("scout", "0"))
	for r in String(_args.get("ranges", "")).split(",", false):
		var ab := r.split("-")
		_ranges.append([int(ab[0]), int(ab[1])])
	if _args.has("max"):
		get_tree().create_timer(float(_args.max), true, false, true).timeout.connect(_give_up)
	RenderingServer.frame_post_draw.connect(_grab)
	var shot: String = _args.get("shot", "test")
	if not has_method("_shot_" + shot):
		push_error("render_trailer: no shot '%s'" % shot)
		get_tree().quit(1)
		return
	await call("_shot_" + shot)
	_recording = false
	for t in _saves:
		WorkerThreadPool.wait_for_task_completion(t)
	_saves.clear()
	_save_marks()
	await _frames(2)
	get_tree().quit()


func _process(delta: float) -> void:
	_frame += 1
	if _hide_ui:
		_hide_overlays()
	if _auto_text and Dialogue.active:
		Dialogue.auto = true
	if _cam and not _keys.is_empty():
		_cam_t += delta
		_apply_keys()
		# A cutscene's end hands the picture back to the follow camera.
		if not Cutscene.active and not _cam.current:
			_cam.current = true


# --- Booting and the picture ---------------------------------------------------

## Loads the game straight into `area` at `entrance` and waits for it to settle.
func _boot(area: String, entrance := "", settle := 20) -> void:
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(2)
	GameManager.start_game()
	World.fade = 0.0
	World.title_alpha = 0.0
	World.title_duration = 0.0
	await _frames(settle)
	var gv := _main.get_node("GameView/GameViewport") as SubViewport
	print("render_trailer: window %s, game viewport %s, wide %s, h %d" % [get_window().size, gv.size, GameManager.widescreen, GameManager.render_height()])


func _hide_overlays() -> void:
	if _main == null:
		return
	var vp := _main.get_node_or_null("GameView/GameViewport")
	if vp == null:
		return
	for n in ["HUD", "TransitionLayer", "DebugLayer"]:
		var l := vp.get_node_or_null(n) as CanvasLayer
		if l:
			l.visible = false
	World.title_alpha = 0.0


func _mute_music() -> void:
	var i := AudioServer.get_bus_index("Music")
	if i >= 0:
		AudioServer.set_bus_mute(i, true)


## Starts or stops saving the game's picture.
func rec(on := true) -> void:
	_recording = on
	mark("rec_in" if on else "rec_out")


func _give_up() -> void:
	print("render_trailer: --max reached")
	_recording = false
	_ranges = []
	_scout = 0
	for t in _saves:
		WorkerThreadPool.wait_for_task_completion(t)
	_saves.clear()
	_save_marks()
	get_tree().quit()


func _grab() -> void:
	if _out == "" or _main == null:
		return
	var vp := _main.get_node_or_null("GameView/GameViewport") as SubViewport
	if vp == null:
		return
	var path := ""
	var full := _recording
	for r: Array in _ranges:
		full = full or (_frame >= int(r[0]) and _frame <= int(r[1]))
	if full:
		path = _out.path_join("c%06d.png" % _frame)
	elif _scout > 0 and _frame % _scout == 0:
		path = _out.path_join("s%06d.jpg" % _frame)
		_fades[str(_frame)] = snappedf(maxf(World.fade, _scene.fade if is_instance_valid(_scene) else 0.0), 0.01)
	else:
		return
	var img := vp.get_texture().get_image()
	if path.ends_with(".jpg"):
		img.resize(480, 270, Image.INTERPOLATE_BILINEAR)
		_saves.append(WorkerThreadPool.add_task(func() -> void: img.save_jpg(path, 0.85)))
	else:
		_saves.append(WorkerThreadPool.add_task(func() -> void: img.save_png(path)))
	_saves.append(WorkerThreadPool.add_task(func() -> void: img.save_png(path)))
	# Keep the queue short.
	while _saves.size() > 12:
		WorkerThreadPool.wait_for_task_completion(_saves.pop_front())


func mark(label: String) -> void:
	_marks[label] = _frame
	print("render_trailer: mark %s at frame %d" % [label, _frame])


func _save_marks() -> void:
	if _out == "":
		return
	var path := _out.path_join("marks.json")
	if not _fades.is_empty():
		_marks["fades"] = _fades
	_marks["last"] = _frame
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(_marks, "  "))
	f.close()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(s: float) -> void:
	await _frames(int(round(s * FPS)))


# --- The director's camera -----------------------------------------------------

## Takes the picture with the director's camera, playing `keys`
## ([{t, eye, at, fov}] with smooth easing between keys).
func cam_path(keys: Array) -> void:
	if _cam == null:
		_cam = Camera3D.new()
		_cam.far = 900.0
		World.area_node.add_child(_cam)
	_keys = keys
	_cam_t = 0.0
	_smooth_set = false
	_apply_keys()
	_cam.current = true


func _apply_keys() -> void:
	var k0: Dictionary = _keys[0]
	var k1: Dictionary = _keys[-1]
	for i in range(_keys.size() - 1):
		if _cam_t >= float(_keys[i].t) and _cam_t <= float(_keys[i + 1].t):
			k0 = _keys[i]
			k1 = _keys[i + 1]
			break
	var span := maxf(0.0001, float(k1.t) - float(k0.t))
	var u := clampf((_cam_t - float(k0.t)) / span, 0.0, 1.0)
	if _cam_t > float(_keys[-1].t):
		u = 1.0
	var ease_mode: String = k1.get("ease", "inout")
	match ease_mode:
		"linear":
			pass
		"out":
			u = 1.0 - pow(1.0 - u, 2.0)
		"in":
			u = u * u
		_:
			u = u * u * (3.0 - 2.0 * u)
	var eye: Vector3 = _pos(k0.eye).lerp(_pos(k1.eye), u)
	var at: Vector3 = _pos(k0.at).lerp(_pos(k1.at), u)
	_cam.fov = lerpf(float(k0.get("fov", 50.0)), float(k1.get("fov", k0.get("fov", 50.0))), u)
	# "smooth": each frame the camera moves only that fraction of the way
	# (a steadier picture for cameras that follow fighters).
	var sm := float(k0.get("smooth", 0.0))
	if sm > 0.0 and _smooth_set:
		eye = _smooth_eye.lerp(eye, sm)
		at = _smooth_at.lerp(at, sm)
	_smooth_eye = eye
	_smooth_at = at
	_smooth_set = true
	if eye.distance_to(at) > 0.001:
		_cam.look_at_from_position(eye, at, Vector3.UP)


## A key position: a Vector3, or a Callable giving one (to follow something).
func _pos(v: Variant) -> Vector3:
	if v is Callable:
		return (v as Callable).call()
	return v


func game_camera() -> void:
	if _cam:
		_cam.current = false
	_keys = []
	var p := GameManager.player
	if p and p.camera_rig and p.camera_rig.camera:
		p.camera_rig.camera.current = true


# --- The hero ------------------------------------------------------------------

func hero() -> PlayerController:
	return GameManager.player


func move(dir: Vector3) -> void:
	var p := hero()
	p.debug_use_move_input = dir != Vector3.ZERO
	p.debug_move_input = dir


func tap(action: String, hold_frames := 2) -> void:
	Input.action_press(action)
	await _frames(hold_frames)
	Input.action_release(action)


## A point `h` meters above the hero (for camera keys that follow him).
func follow(offset := Vector3(0, 1.0, 0)) -> Callable:
	return func() -> Vector3: return hero().global_position + offset


# --- Shots ---------------------------------------------------------------------

func _shot_test() -> void:
	await _boot("field", "from_village")
	var p := hero()
	var start := p.global_position
	var fwd := p.forward()
	var side := Vector3(-fwd.z, 0, fwd.x)
	rec()
	move(fwd)
	cam_path([
		{"t": 0.0, "eye": start - fwd * 4.0 + side * 3.0 + Vector3.UP * 1.6, "at": follow(), "fov": 45.0},
		{"t": 4.0, "eye": start + fwd * 6.0 + side * 4.0 + Vector3.UP * 2.5, "at": follow(), "fov": 45.0},
	])
	await _secs(4.0)
	rec(false)


# --- Whole scenes (for scouting, then picking ranges) ----------------------------

func _debug_menu() -> DebugMenu:
	return _main.get_node("GameView/GameViewport/DebugLayer/DebugMenu") as DebugMenu


## A story scene as the debug menu's SCENES tab plays it (--scene=<id>).
func _shot_story() -> void:
	await _boot(_args.get("from", "village"), "")
	var id: String = _args.get("scene", "legend")
	_debug_menu()._play_scene(id)
	mark("scene_call")
	var t := 0
	while not Cutscene.active and t < 30 * 40:
		await _frames(1)
		t += 1
	mark("scene_start")
	while Cutscene.active:
		await _frames(1)
	mark("scene_end")
	await _secs(0.5)


## One of the title's attract scenes (--scene=<index>), as the debug menu
## plays it but without its letterbox and boxes.
func _shot_attract() -> void:
	await _boot("village", "")
	GameManager._set_state(GameManager.GameState.TITLE)
	var scene := DebugMenu.attract_scene(int(_args.get("scene", "0")))
	_scene = scene
	add_child(scene)
	var done := {"ok": false}
	scene.finished.connect(func() -> void: done.ok = true)
	var vp := _main.get_node("GameView/GameViewport") as SubViewport
	scene.start(vp)
	mark("scene_start")
	while not done.ok:
		await _frames(1)
	mark("scene_end")


# --- Gameplay shots --------------------------------------------------------------

## The hero's kit for a shot: "early" (squire sword, wooden shield, Haven
## tunic) or "late" (the awakened Bun Sword, the Questlord shield and the
## Knight's Regalia with its cape).
func gear(kit: String) -> void:
	DebugMenu.infinite_health = true
	if kit == "late":
		for f in ["ch4:sword_awake", "ch5:knight", PlayerCombat.TECH_SPIN]:
			Progress.flags[f] = true
		Progress.swords["bun"] = true
		Progress.sword = "bun"
		Progress.shields["questlord"] = true
		Progress.shield = "questlord"
		Progress.vanity_on = "regalia"
	else:
		Progress.flags[PlayerCombat.TECH_SPIN] = true


func ground(x: float, z: float, from_y := 40.0) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, from_y - 80.0, z), 1)
	var hit := World.area_node.get_world_3d().direct_space_state.intersect_ray(q)
	return float(hit.position.y) if not hit.is_empty() else 0.0


func on_ground(x: float, z: float, from_y := 40.0) -> Vector3:
	return Vector3(x, ground(x, z, from_y), z)


func place(pos: Vector3, dir: Vector3) -> void:
	var p := hero()
	p.set("_auto_walk_time", 0.0)
	p.input_enabled = true
	p.global_position = pos + Vector3.UP * 0.3
	p.velocity = Vector3.ZERO
	p.face_direction(dir)
	if p.camera_rig:
		p.camera_rig.snap_behind_target()


func spawn(kind: String, pos: Vector3, face: Vector3 = Vector3.ZERO) -> Node3D:
	var e := (load("res://scenes/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Node3D
	World.area_node.add_child(e)
	e.global_position = pos + Vector3.UP * 0.2
	if face != Vector3.ZERO:
		e.rotation.y = atan2(-face.x, -face.z)
		if "facing_yaw" in e:
			e.set("facing_yaw", e.rotation.y)
	if "_home" in e:
		e.set("_home", e.global_position)
	return e


## Every creature in the area but `keep` sent far off and stilled.
func clear_enemies(keep: Array = []) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in keep or not (e is Node3D):
			continue
		(e as Node3D).global_position += Vector3(0, -200, 0)
		e.set_physics_process(false)
		e.set_process(false)
		(e as Node3D).visible = false


## A camera point circling `centre` (a Callable): radius `r`, height `h`,
## from angle a0 to a1 (degrees, 0 = +X, 90 = +Z) over `time` seconds.
func orbit(centre: Callable, r: float, h: float, a0: float, a1: float, time: float) -> Callable:
	return func() -> Vector3:
		var k := clampf(_cam_t / time, 0.0, 1.0)
		var a := deg_to_rad(lerpf(a0, a1, k))
		return (centre.call() as Vector3) + Vector3(cos(a) * r, h, sin(a) * r)


## An offset in the horse's own frame (x right, z ahead), following her.
func horse_follow(h: Node3D, local: Vector3) -> Callable:
	return func() -> Vector3:
		var fwd := -h.global_basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := Vector3(-fwd.z, 0, fwd.x)
		return h.global_position + right * local.x + Vector3.UP * local.y + fwd * local.z


func node_follow(n: Node3D, offset: Vector3) -> Callable:
	return func() -> Vector3: return n.global_position + offset if is_instance_valid(n) else offset


## Biscuit at a gallop down the castle road in Bunsriel Fields, filmed
## alongside, then from the road ahead as she thunders past.
func _shot_horse() -> void:
	gear("early")
	await _boot("field", "from_village")
	clear_enemies()
	var start := on_ground(0, 4)
	var h := Horse.spawn(World.area_node, start + Vector3.UP * 0.1, 0.0)
	await _frames(5)
	var side := h.global_basis * Vector3(-1.3, 0, 0)
	hero().global_position = h.global_position + side + Vector3.UP * 0.2
	hero().face_direction(-side)
	await _frames(15)
	await tap("interact")
	await _frames(25)
	move(Vector3(0, 0, -1))
	await _secs(1.8)
	mark("gallop")
	rec()
	cam_path([
		{"t": 0.0, "eye": horse_follow(h, Vector3(5.5, 1.2, -0.5)), "at": horse_follow(h, Vector3(0, 1.4, 0.8)), "fov": 46.0},
		{"t": 3.0, "eye": horse_follow(h, Vector3(5.0, 1.7, 2.0)), "at": horse_follow(h, Vector3(0, 1.4, 0.6)), "fov": 46.0, "ease": "linear"},
	])
	await _secs(1.2)
	await tap("interact")
	await _secs(1.8)
	mark("take2")
	var hf := -h.global_basis.z
	hf.y = 0.0
	hf = hf.normalized()
	var hr := Vector3(-hf.z, 0, hf.x)
	var spot := h.global_position + hf * 22.0 - hr * 2.4
	var ahead := on_ground(spot.x, spot.z) + Vector3.UP * 1.0
	cam_path([
		{"t": 0.0, "eye": ahead, "at": node_follow(h, Vector3(0, 1.3, 0)), "fov": 42.0},
		{"t": 4.0, "eye": ahead, "at": node_follow(h, Vector3(0, 1.3, 0)), "fov": 42.0},
	])
	await _secs(2.6)
	mark("take3")
	cam_path([
		{"t": 0.0, "eye": horse_follow(h, Vector3(-1.2, 0.7, 6.0)), "at": horse_follow(h, Vector3(0, 1.5, 0)), "fov": 50.0},
		{"t": 3.0, "eye": horse_follow(h, Vector3(-3.5, 1.4, 4.0)), "at": horse_follow(h, Vector3(0, 1.5, 0)), "fov": 50.0},
	])
	await _secs(3.0)
	rec(false)


## The war camp in Bunsriel Fields (Chapter IV): the hero wades into the
## goblins round their fire, cutting left and right.
func _shot_camp() -> void:
	gear("late")
	Progress.flags["ch4:war"] = true
	await _boot("field_war", "from_village")
	var fire := Vector3(-30, 0, -62)
	var keep: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and (e as Node3D).global_position.distance_to(fire) < 25.0:
			keep.append(e)
	clear_enemies(keep)
	print("render_trailer: camp foes ", keep.size())
	var stand := on_ground(fire.x + 3.0, fire.z + 9.0)
	place(stand, Vector3(0, 0, -1))
	await _frames(10)
	rec()
	var orb := orbit(follow(Vector3.ZERO), 4.6, 1.9, 40.0, 150.0, 14.0)
	cam_path([
		{"t": 0.0, "eye": orb, "at": follow(Vector3(0, 1.0, -0.8)), "fov": 52.0, "smooth": 0.15},
		{"t": 14.0, "eye": orb, "at": follow(Vector3(0, 1.0, -0.8)), "fov": 52.0, "smooth": 0.15},
	])
	move(Vector3(-0.15, 0, -1))
	await _secs(0.8)
	move(Vector3.ZERO)
	for i in 10:
		Input.action_press("target")
		await _frames(2)
		await tap("attack")
		await _frames(9)
		await tap("attack")
		await _frames(9)
		await tap("attack")
		await _frames(14)
		Input.action_release("target")
		var foe := _nearest_foe(14.0)
		if foe:
			move((foe.global_position - hero().global_position).normalized())
			await _frames(8)
			move(Vector3.ZERO)
	rec(false)


func _nearest_foe(within: float) -> Node3D:
	var best: Node3D = null
	var bd := within
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and (e as Node3D).visible:
			var d := (e as Node3D).global_position.distance_to(hero().global_position)
			if d < bd:
				bd = d
				best = e
	return best


## The Great Spin: a ring of goblins closes in; he gathers his strength and
## cuts them all down at once.
func _shot_spin() -> void:
	gear("late")
	await _boot("field", "from_village")
	clear_enemies()
	var c := on_ground(-5, 60)
	place(c, Vector3(0, 0, -1))
	await _frames(15)
	var foes: Array = []
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var p := on_ground(c.x + sin(a) * 2.2, c.z + cos(a) * 2.2)
		var e := spawn("basic_enemy", p, c - p)
		foes.append(e)
	await _frames(5)
	for e in foes:
		e.set_physics_process(false)
	rec()
	var orb := orbit(func() -> Vector3: return c, 4.4, 3.1, 60.0, 125.0, 4.5)
	cam_path([
		{"t": 0.0, "eye": orb, "at": c + Vector3(0, 0.9, 0), "fov": 55.0},
		{"t": 4.5, "eye": orb, "at": c + Vector3(0, 0.9, 0), "fov": 55.0},
	])
	await _secs(0.6)
	Input.action_press("attack")
	await _secs(1.5)
	Input.action_release("attack")
	await _secs(2.4)
	rec(false)


## A bomb lobbed into a knot of goblins.
func _shot_bomb() -> void:
	gear("early")
	Progress.give_bomb_bag()
	Progress.assign("item_x", "bombs")
	await _boot("field", "from_village")
	clear_enemies()
	var c := on_ground(-5, 62)
	place(c, Vector3(0, 0, -1))
	await _frames(15)
	var foes: Array = []
	var land: Vector3 = c + Vector3(float(_args.get("land_x", "0")), 0, float(_args.get("land_z", "-10.4")))
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		var p := on_ground(land.x + sin(a) * 1.3, land.z + cos(a) * 1.3)
		foes.append(spawn("basic_enemy", p, c - p))
	await _frames(5)
	for e in foes:
		e.set_physics_process(false)
	rec()
	cam_path([
		{"t": 0.0, "eye": c + Vector3(3.5, 1.5, 1.8), "at": c + Vector3(0, 1.1, -2.5), "fov": 50.0},
		{"t": 1.4, "eye": c + Vector3(3.5, 1.5, 1.8), "at": c + Vector3(0, 1.1, -2.5), "fov": 50.0},
		{"t": 3.4, "eye": c + Vector3(3.6, 1.5, -6.0), "at": land + Vector3(0, 0.8, 0), "fov": 50.0},
		{"t": 6.0, "eye": c + Vector3(3.9, 1.7, -6.4), "at": land + Vector3(0, 0.8, 0), "fov": 50.0},
	])
	await _secs(0.4)
	await tap("item_x")
	await _secs(0.6)
	await tap("attack")
	for i in 40:
		await _frames(3)
		for b in get_tree().get_nodes_in_group("bombs") + World.area_node.find_children("*", "Bomb", true, false):
			if b is Node3D:
				print("render_trailer: bomb %d at %s (from hero %s)" % [i, (b as Node3D).global_position, (b as Node3D).global_position - c])
	rec(false)


## The Hookshot across the West Marshlands to the tower's islet.
func _shot_hookshot() -> void:
	gear("early")
	Progress.give_item("hookshot")
	Progress.assign("item_y", "hookshot")
	await _boot("marsh", "")
	clear_enemies()
	var tower := Vector3(-28, 0, -25)
	var target: Node3D = null
	for t in get_tree().get_nodes_in_group("hook_targets"):
		if Vector2((t as Node3D).global_position.x - tower.x, (t as Node3D).global_position.z - tower.z).length() < 12.0:
			target = t
	var end := Vector3(-12.7, 0, -18.9)
	var back := (Vector3(2, 0, -6) - end).normalized()
	var stand := end + back * 1.3
	stand.y = ground(stand.x, stand.z, 3.0) + 0.1
	place(stand, target.global_position - stand)
	await _frames(20)
	var to := (target.global_position - stand) * Vector3(1, 0, 1)
	var side := Vector3(-to.z, 0, to.x).normalized()
	rec()
	cam_path([
		{"t": 0.0, "eye": stand + side * 3.2 - to.normalized() * 2.0 + Vector3.UP * 1.4, "at": stand + to * 0.5 + Vector3.UP * 1.0, "fov": 55.0},
		{"t": 4.0, "eye": stand + side * 4.5 + to * 0.3 + Vector3.UP * 2.0, "at": target.global_position, "fov": 55.0},
	])
	await _secs(0.3)
	var p := hero()
	Input.action_press("item_y")
	await _frames(3)
	for i in 2:
		var d := target.global_position - p.aim_origin()
		p.look_yaw = atan2(-d.x, -d.z)
		p.look_pitch = atan2(d.y, Vector2(d.x, d.z).length())
		await _secs(0.25)
	Input.action_release("item_y")
	await _secs(3.0)
	rec(false)


## Swimming and diving in Mirror Lake.
func _shot_swim() -> void:
	gear("early")
	await _boot("lake", "")
	clear_enemies()
	var at := Vector3(TitleMira.SEAT.x + 2.0, 0.0, TitleMira.SEAT.y + 6.0)
	at.y = Surface.water_level(World.area_node, at) if not is_nan(Surface.water_level(World.area_node, at)) else ground(at.x, at.z) + 0.5
	place(at, Vector3(1, 0, 0))
	await _secs(2.5)
	print("render_trailer: swim state ", hero().state, " at ", hero().global_position)
	rec()
	cam_path([
		{"t": 0.0, "eye": follow(Vector3(-3.2, 2.4, 2.6)), "at": follow(Vector3(1.2, 0.1, 0)), "fov": 50.0},
		{"t": 6.0, "eye": follow(Vector3(-1.2, 2.8, 3.6)), "at": follow(Vector3(1.6, -0.1, 0)), "fov": 50.0},
	])
	move(Vector3(1, 0, 0))
	await _secs(2.5)
	Input.action_press("interact")
	await _secs(1.6)
	Input.action_release("interact")
	await _secs(2.0)
	rec(false)


## The duel in the great hall of Batela Keep: Firebuns III himself, sword
## and flame, against the hero.
func _shot_duel() -> void:
	gear("late")
	for f in ["castle_fallen", "legend_told", "game_beaten", "ch3:arrived", "ch3:keep_duel"]:
		Progress.flags[f] = true
	await _boot("batela_fells", "")
	clear_enemies()
	var mark_fb := World.area_node.find_child("cs_keep_firebuns", true, false) as Node3D
	var mark_hero := World.area_node.find_child("cs_keep_hero", true, false) as Node3D
	var fb := (load("res://scenes/enemies/firebuns.tscn") as PackedScene).instantiate() as Node3D
	fb.set("duel", true)
	World.area_node.add_child(fb)
	fb.global_position = mark_fb.global_position
	fb.rotation.y = PI
	fb.set("facing_yaw", PI)
	var hpos := mark_hero.global_position
	place(hpos, fb.global_position - hpos)
	await _frames(10)
	fb.call("wake")
	await _fight(fb, 15.0)


## A fight filmed by the game's own camera, Z-targeting `foe`: close in,
## two cuts, raise the shield, again, for `secs` seconds.
func _fight(foe: Node3D, secs: float, parry := false) -> void:
	GameManager.z_target_hold = true
	# Over the hero's shoulder, a little to the side, both of them in frame.
	var side_k := float(_args.get("side", "1.0"))
	var eye := func() -> Vector3:
		var h := hero().global_position
		var f := foe.global_position if is_instance_valid(foe) else h + Vector3.FORWARD
		var axis := (f - h) * Vector3(1, 0, 1)
		var d := clampf(axis.length(), 1.5, 8.0)
		axis = axis.normalized()
		var side := Vector3(-axis.z, 0, axis.x) * side_k
		return h - axis * (2.6 + d * 0.25) + side * (1.8 + d * 0.2) + Vector3.UP * 2.0
	var at := func() -> Vector3:
		var h := hero().global_position
		var f := foe.global_position if is_instance_valid(foe) else h
		return (h + f) * 0.5 + Vector3.UP * 1.3
	cam_path([{"t": 0.0, "eye": eye, "at": at, "fov": 52.0, "smooth": 0.12}, {"t": 99.0, "eye": eye, "at": at, "fov": 52.0, "smooth": 0.12}])
	Input.action_press("target")
	await _frames(15)
	rec()
	var t := 0
	while t < int(secs * FPS) and is_instance_valid(foe):
		var to := foe.global_position - hero().global_position
		to.y = 0
		if to.length() > 2.6:
			move(to.normalized())
			await _frames(10)
			move(Vector3.ZERO)
			t += 10
		if parry:
			Input.action_press("shield")
			await _frames(14)
			await tap("attack")
			Input.action_release("shield")
			await _frames(8)
			t += 24
		await tap("attack")
		await _frames(10)
		await tap("attack")
		await _frames(12)
		Input.action_press("shield")
		await _frames(16)
		Input.action_release("shield")
		await _frames(4)
		t += 46
	rec(false)
	Input.action_release("target")


## Mara at the top of Ridge Keep: her glaive sweeps, his parry, the riposte.
func _shot_mara() -> void:
	gear("late")
	Progress.flags[PlayerCombat.TECH_PARRY] = true
	await _boot("ridge_keep", "")
	var m: Node3D = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Mara:
			m = e
	clear_enemies([m])
	var fwd: Vector3 = m.call("_forward")
	var stand := m.global_position + fwd * 5.0
	place(stand, m.global_position - stand)
	await _frames(20)
	await _fight(m, 15.0, true)


# --- Scenery -----------------------------------------------------------------------

## One of the title screen's walks (TitleFlyover.SHOTS[--i]) with the real
## hero, the area alive around him, and the same camera.
func _shot_fly() -> void:
	gear(_args.get("kit", "early"))
	var s: Dictionary = TitleFlyover.SHOTS[int(_args.get("i", "0"))]
	await _boot(s["area"], "")
	clear_enemies()
	var from: Vector2 = s["from"]
	var to: Vector2 = s["to"]
	var fwd := Vector3(to.x - from.x, 0, to.y - from.y).normalized()
	var right := Vector3(-fwd.z, 0, fwd.x)
	var start := on_ground(from.x, from.y)
	place(start, fwd)
	await _frames(20)
	var time := float(_args.get("time", "9.0"))
	var cams: Array = s["cam"]
	var fixed: bool = s["mode"] == "fixed"
	var look_h := float(s.get("look", 1.2))
	var ahead := float(s.get("ahead", 0.0))
	var eye_at := func(k: float) -> Vector3:
		var local: Vector3 = (cams[0] as Vector3).lerp(cams[1], TitleFlyover._ease(k))
		var origin := start if fixed else hero().global_position
		var e := origin + right * local.x + fwd * local.z + Vector3.UP * local.y
		e.y = maxf(e.y, ground(e.x, e.z, e.y + 6.0) + 0.6)
		return e
	cam_path([
		{"t": 0.0, "eye": func() -> Vector3: return eye_at.call(_cam_t / time), "at": func() -> Vector3: return hero().global_position + Vector3.UP * look_h + fwd * ahead, "fov": 55.0},
		{"t": time, "eye": func() -> Vector3: return eye_at.call(_cam_t / time), "at": func() -> Vector3: return hero().global_position + Vector3.UP * look_h + fwd * ahead, "fov": 55.0},
	])
	rec()
	var walk_end := time * float(s.get("stop", 1.0))
	var dist := Vector2(to - from).length()
	# Walk at the pace that covers the walk in its time (OoT's walk is ~2 m/s).
	move(fwd * float(_args.get("pace", "0.6")))
	await _secs(walk_end)
	move(Vector3.ZERO)
	await _secs(time - walk_end)
	rec(false)



## A boss in its own lair (--area, --kind: part of its scene's file name): the
## hero is set down before it and the game plays its intro and the fight.
func _shot_boss() -> void:
	gear(_args.get("kit", "late"))
	await _boot(_args.get("area", "castle"), _args.get("entrance", ""))
	var kind: String = _args.get("kind", "cinder_wyvern")
	var boss: Node3D = null
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and (e as Node).scene_file_path.get_file().get_basename() == kind:
			boss = e
	if boss == null:
		for e in World.area_node.find_children("*", "", true, false):
			if e is Node3D and e.scene_file_path.get_file().get_basename() == kind:
				boss = e
	print("render_trailer: boss ", boss, " at ", boss.global_position if boss else Vector3.ZERO)
	if boss == null:
		return
	clear_enemies([boss])
	var away := Vector3(float(_args.get("dx", "0")), 0, float(_args.get("dz", "8")))
	var stand := boss.global_position + away
	stand.y = ground(stand.x, stand.z, boss.global_position.y + 4.0)
	place(stand, boss.global_position - stand)
	game_camera()
	rec()
	var t := 0
	while t < int(float(_args.get("time", "10")) * FPS) and is_instance_valid(boss):
		await _frames(1)
		t += 1
		if t == int(4.0 * FPS):
			GameManager.z_target_hold = true
			Input.action_press("target")
		if t > int(4.5 * FPS) and t % 40 == 0 and not Cutscene.active:
			tap("attack")
	rec(false)
