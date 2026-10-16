extends Node
## Screenshots of the crouched shield aimed with the stick, the shield stab and
## a Stalfos's committed windup, for visual checks (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/combat_capture.tscn -- --out=<dir>

var out_dir := "user://combat_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	World.area_id = "test_area"
	World.entrance_id = ""
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(20)
	var p := GameManager.player
	var cam: AdventureCamera = World.area_node.get_node("CameraRig")
	for e in get_tree().get_nodes_in_group("enemies"):
		e.global_position = Vector3(-20, 3.5, -4)
		e.set_physics_process(false)
	# The camera is set behind the hero facing -Z, then he turns to face it
	# three-quarters on.
	p.global_position = Vector3(0, 0.3, 10)
	p.face_direction(Vector3(0, 0, -1))
	cam.snap_behind_target()
	await _frames(10)
	p.face_direction(Vector3(0.7, 0, 1))
	# Let the area title card fade.
	await _secs(4.0)
	_act("shield", true)
	await _secs(0.4)
	await _shot("01_crouch")
	p.debug_use_move_input = true
	for d: Array in [["02_aim_left", Vector3(1, 0, -0.7)], ["03_aim_right", Vector3(-1, 0, 0.7)], ["04_aim_up", Vector3(-0.7, 0, -1)], ["05_aim_down", Vector3(0.7, 0, 1)]]:
		p.debug_move_input = (d[1] as Vector3).normalized()
		await _secs(0.5)
		await _shot(d[0])
	p.debug_move_input = Vector3(1, 0, -0.7).normalized()
	await _secs(0.3)
	_act("attack", true)
	await _frames(4)
	_act("attack", false)
	await _secs(0.08)
	await _shot("06_stab_aimed")
	p.debug_move_input = Vector3.ZERO
	await _secs(0.5)
	_act("attack", true)
	await _frames(4)
	_act("attack", false)
	await _secs(0.08)
	await _shot("07_stab_ahead")
	_act("shield", false)
	p.debug_use_move_input = false
	get_tree().quit()


func _act(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	vp.get_texture().get_image().save_png(out_dir.path_join(shot_name + ".png"))
