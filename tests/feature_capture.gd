extends Node
## Screenshots of the climbing, first-person, bow, talking and map features in
## the real game view, for visual checks (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/feature_capture.tscn -- --automation --out=<dir>

var out_dir := "user://feature_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	await _load("lake", "from_lake_house")
	var p := GameManager.player
	var cam: AdventureCamera = World.area_node.get_node("CameraRig")
	# Mira's house from the dock, then from the south-east with the ladder.
	await _frames(90)
	_view(p, Vector3(-2, 0, -40), Vector3(-2, 2.5, -52))
	await _frames(30)
	await _shot("01_house_front")
	p.global_position = Vector3(1.5, 2.0, -46.5)
	p.face_direction(Vector3(-0.6, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _secs(1.0)
	await _shot("01b_house_door")
	_view(p, Vector3(6, 0, -44), Vector3(1.5, 3, -52))
	await _frames(30)
	await _shot("02_house_ladder")
	# On the ladder, half way up.
	var ladder := _ladder_shape()
	if ladder:
		var out := ladder.global_basis.z.normalized()
		var foot := ladder.global_position + out * 1.2
		p.global_position = Vector3(foot.x, ladder.global_position.y - 1.5, foot.z)
		p.face_direction(-out)
		cam.snap_behind_target()
		p.debug_use_move_input = true
		p.debug_move_input = -out
		await _frames(100)
		p.debug_move_input = Vector3.ZERO
		await _frames(20)
		await _shot("03_on_ladder")
		p.debug_move_input = -out
		for i in 400:
			await _frames(1)
			if p.state == PlayerController.State.IDLE and p.global_position.y > ladder.global_position.y:
				break
		p.debug_use_move_input = false
		await _frames(40)
		cam.snap_behind_target()
		await _frames(10)
		await _shot("04_roof_deck")
	# The targets, then aiming at them in first person.
	_view(p, Vector3(-4, 0, -51), Vector3(-17, 1.3, -51))
	await _frames(30)
	await _shot("05_targets")
	p.global_position = Vector3(-5, 2.0, -51)
	p.face_direction(Vector3(-1, 0, -0.1))
	cam.snap_behind_target()
	await _frames(40)
	Input.action_press("item_x")
	await _frames(40)
	await _shot("06_aiming")
	Input.action_release("item_x")
	await _frames(12)
	await _shot("07_arrow_flying")
	await _frames(30)
	p.debug_look_input = Vector2.ZERO
	await _shot("08_arrow_stuck")
	await _tap("attack")
	await _frames(20)
	# First-person look across the lake.
	p.face_direction(Vector3(0.3, 0, 1))
	cam.snap_behind_target()
	await _tap("first_person")
	await _frames(30)
	await _shot("09_first_person")
	await _tap("first_person")
	await _frames(10)
	# Inside the house, talking to Mira.
	await _load("lake_house", "from_lake")
	p = GameManager.player
	await _frames(90)
	await _shot("10_inside")
	var mira := World.area_node.get_node("Features/Mira") as Node3D
	var to_me := mira.global_basis * Vector3(0, 0, -1)
	p.global_position = mira.global_position + to_me * 1.3
	p.face_direction(-to_me)
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(10)
	await _tap("interact")
	await _secs(2.5)
	await _shot("11_talk_1")
	for i in 3:
		await _tap("interact")
		await _secs(0.3)
		await _tap("interact")
		await _secs(2.5)
	await _shot("12_talk_2")
	for i in 2:
		await _tap("interact")
		await _secs(0.3)
		await _tap("interact")
		await _secs(2.5)
	await _shot("13_talk_3")
	Dialogue.cancel()
	# Hanging from a ledge in the test area.
	await _load("test_area", "")
	p = GameManager.player
	await _frames(30)
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3.5, 3)
	cs.shape = box
	b.add_child(cs)
	World.area_node.add_child(b)
	b.global_position = Vector3(10, 1.25, 0)
	p.global_position = Vector3(10, 0.5, 4)
	p.face_direction(Vector3(0, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	p.debug_use_move_input = true
	p.debug_move_input = Vector3(0, 0, -1)
	for i in 200:
		await _frames(1)
		if p.state == PlayerController.State.HANG:
			break
	p.debug_use_move_input = false
	await _frames(30)
	await _shot("14_hanging")
	p.debug_use_move_input = true
	await _frames(25)
	await _shot("15_climbing_up")
	p.debug_use_move_input = false
	await _frames(60)
	# The pause screen's world map.
	World.area_id = "lake_house"
	_press("pause")
	await _frames(40)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	pm.page = pm.Page.MAP
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	await _frames(20)
	await _shot("16_world_map")
	pm.page = pm.Page.ITEM
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	pm.item_cursor = Vector2i(0, 0)
	await _frames(20)
	await _shot("17_items")
	get_tree().quit()


func _load(area: String, entrance: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(5)


## Puts the camera at `eye` looking at `at` by parking the hero there.
func _view(p: PlayerController, eye: Vector3, at: Vector3) -> void:
	var flat := Vector3(at.x - eye.x, 0, at.z - eye.z)
	p.global_position = Vector3(eye.x, eye.y + 5.0, eye.z) - flat.normalized() * -0.5
	p.face_direction(flat)
	World.area_node.get_node("CameraRig").snap_behind_target()


func _ladder_shape() -> CollisionShape3D:
	for cs in World.area_node.get_node("PropCollision").get_children():
		if cs.get_meta("ladder", false):
			return cs
	return null


func _tap(action: String) -> void:
	_press(action)
	await _frames(3)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	vp.get_texture().get_image().save_png(out_dir.path_join(shot_name + ".png"))
