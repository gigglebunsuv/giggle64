extends "res://tests/armory_capture.gd"
## Gameplay screenshots for the back of the box (windowed, 480p, 4:3):
##   Godot --path <project> --resolution 640x480 res://tests/box_capture.tscn -- --automation --out=<dir> [--only=a,b]
## Riding Biscuit across Haven Field, a sword fight at dusk, the Iron Flail in
## Ridge Keep, Firebuns III in fallen Castle Town, the bow drawn at the lake,
## and the SELECT ITEM page.

const FLAGS := ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned",
	"ch5:cinder_done", "ch5:front_seen", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done"]

var _only: PackedStringArray = []


func _ready() -> void:
	out_dir = "user://box_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			_only = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	GameManager.render_index = 1
	GameManager.using_gamepad = true
	GameManager.glyph_family = 3
	GameManager.set_meta("no_hints", true)
	Progress.reset()
	for f in FLAGS:
		Progress.set_flag(f)
	Progress.max_health = 26
	Progress.give_sword("bun")
	Progress.give_shield("mirror")
	Progress.give_magic_meter()
	Progress.give_bomb_bag()
	for id in ["bow", "hookshot", "boomerang", "bloom_rod", "iron_flail", "ember_rod", "lantern"]:
		Progress.give_item(id)
	Progress.assign("item_x", "bow")
	Progress.assign("item_y", "bombs")
	Progress.rupees = 214
	if _wants("ride"):
		await _ride()
	if _wants("fight"):
		await _fight()
	if _wants("tower"):
		await _tower()
	if _wants("legend"):
		await _legend()
	if _wants("bow"):
		await _bow()
	if _wants("pause"):
		await _pause()
	if _wants("firebuns"):
		await _firebuns()
	get_tree().quit()


func _wants(shot: String) -> bool:
	return _only.is_empty() or shot in _only


func _p() -> PlayerController:
	return GameManager.player


func _rig_snap() -> void:
	var rig := World.area_node.get_node("CameraRig")
	rig.snap_behind_target()
	for c in rig.find_children("*", "Camera3D", true, false):
		(c as Camera3D).make_current()


func _ground(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 40, z), Vector3(x, -40, z), 1)
	var hit := _p().get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if not hit.is_empty() else 0.0


func _place(pos: Vector3, facing: Vector3) -> void:
	var p := _p()
	p.global_position = Vector3(pos.x, _ground(pos.x, pos.z) + 0.2, pos.z)
	p.face_direction(facing)
	_rig_snap()


func _enemy(kind: String, at: Vector3, face_to: Vector3) -> Node3D:
	var e: Node3D = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
	if "title_name" in e:
		e.set("title_name", "")
	World.area_node.add_child(e)
	e.global_position = Vector3(at.x, _ground(at.x, at.z), at.z)
	var d := face_to - at
	var yaw := atan2(d.x, d.z)
	if "facing_yaw" in e:
		e.set("facing_yaw", yaw)
	e.rotation.y = yaw
	return e


## Galloping on Biscuit up the castle road through Haven Field.
func _ride() -> void:
	DayNight.set_hour(16.5)
	await _load("field", "")
	await _secs(5.0)
	var start := Vector3(0, 0, 30)
	var h := Horse.spawn(World.area_node, Vector3(start.x, _ground(start.x, start.z) + 0.1, start.z), 0.0)
	await _frames(5)
	_p().mount(h, true)
	await _frames(5)
	_rig_snap()
	var p := _p()
	p.debug_use_move_input = true
	p.debug_move_input = Vector3(0, 0, -1)
	await _secs(0.6)
	await _tap("interact")
	await _secs(1.6)
	await _shot("ride")
	p.debug_use_move_input = false


## A sword fight with goblins in the field at dusk.
func _fight() -> void:
	DayNight.set_hour(18.4)
	await _load("field", "")
	await _secs(5.0)
	var c := Vector3(10, 0, 10)
	_place(c, Vector3(0, 0, -1))
	await _frames(10)
	_enemy("basic_enemy", c + Vector3(0.3, 0, -2.0), c)
	_enemy("basic_enemy", c + Vector3(-2.4, 0, -3.4), c)
	_enemy("goblin_archer", c + Vector3(2.6, 0, -5.5), c)
	await _frames(20)
	Input.action_press("target")
	await _frames(20)
	await _tap("attack")
	await _frames(7)
	await _shot("fight")
	Input.action_release("target")


## A fight with Stalfos in the Southern Tower.
func _tower() -> void:
	DayNight.set_hour(14.0)
	await _load("southern_tower", "")
	await _secs(5.0)
	var p := _p()
	var c := p.global_position
	var fwd := p.forward()
	var side := fwd.cross(Vector3.UP)
	_enemy("stalfos", c + fwd * 2.4 + side * 0.4, c)
	_enemy("keese", c + fwd * 4.0 - side * 1.5 + Vector3.UP * 1.8, c)
	await _frames(20)
	Input.action_press("target")
	await _frames(20)
	await _tap("attack")
	await _frames(8)
	await _shot("tower")
	Input.action_release("target")


## Lothelye's legend at the Bun Sword's pedestal: the first few text boxes.
func _legend() -> void:
	DayNight.set_hour(14.0)
	World.area_id = "hidden_forest"
	await _load("hidden_forest", "pedestal")
	await _frames(20)
	var ped: Node3D = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is BunPedestal:
			ped = n
	var p := _p()
	p.global_position = ped.global_position + Vector3(0, 0.1, 1.2)
	p.face_direction(Vector3(0, 0, -1))
	await _secs(4.0)
	Story.legend(ped)
	var page := 0
	var t := 0.0
	while page < 7 and t < 90.0:
		await _secs(0.1)
		t += 0.1
		if Dialogue.active and Dialogue.phase == Dialogue.Phase.WAITING:
			page += 1
			await _shot("legend_%d" % page)
			await _secs(0.2)
			await _tap("interact")


## Facing Firebuns III, wrapped in the Gauntlet's flame, on the burning roof
## of the Citadel (Chapter IV), Mirror Shield up.
func _firebuns() -> void:
	for f in ["ch4:sword_awake", "ch4:astral_seal", "ch4:roof_seen"]:
		Progress.set_flag(f)
	DayNight.set_hour(20.0)
	await _load("citadel_assault", "")
	await _secs(2.0)
	var fb: Node3D = null
	for b in get_tree().get_nodes_in_group("bosses"):
		if b.get("sealing") == true:
			fb = b
	if fb == null:
		push_error("box_capture: no Firebuns on the roof")
		return
	fb.call("wake")
	for i in 120:
		await get_tree().physics_frame
		if Cutscene.active:
			Cutscene.end()
	var p := _p()
	var fwd := -fb.global_basis.z
	var at := fb.global_position + fwd * 6.0 + fb.global_basis.x * 0.6
	p.global_position = at + Vector3.UP * 0.3
	p.face_direction(fb.global_position - at)
	_rig_snap()
	fb.set("state", 2)
	Input.action_press("target")
	await _frames(15)
	Input.action_press("shield")
	await _secs(1.2)
	# Hold him where he stands (he would stalk right up to the hero).
	fb.process_mode = Node.PROCESS_MODE_DISABLED
	await _secs(2.3)
	# A wider camera over his shoulder, so both of them are in the frame.
	var hp := p.global_position
	var to := (fb.global_position - hp) * Vector3(1, 0, 1)
	var dir := to.normalized()
	var right := dir.cross(Vector3.UP)
	var cam := Camera3D.new()
	cam.fov = 55.0
	World.area_node.add_child(cam)
	cam.global_position = hp - dir * 2.4 + right * 2.2 + Vector3.UP * 1.5
	cam.look_at(hp + to * 0.62 + Vector3.UP * 1.2)
	cam.make_current()
	await _frames(4)
	await _shot("firebuns")
	Input.action_release("shield")
	Input.action_release("target")


## Drawing the bow on the lake shore.
func _bow() -> void:
	DayNight.set_hour(11.0)
	await _load("lake", "")
	await _secs(5.0)
	_rig_snap()
	await _frames(10)
	await _tap("item_x")
	await _frames(40)
	await _shot("bow")
	await _tap("interact")
	await _frames(20)


## The SELECT ITEM page.
func _pause() -> void:
	DayNight.set_hour(12.0)
	await _load("village", "")
	await _secs(5.0)
	_press("pause")
	await _frames(45)
	await _shot("pause")
