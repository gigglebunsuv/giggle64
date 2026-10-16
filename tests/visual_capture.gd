extends Node
## Plays a short scripted sequence in the real game and saves screenshots of the
## raw 320x240 game viewport and the upscaled window, for visual verification.
##
## Run windowed (needs a GPU):
##   Godot --path <project> --resolution 1280x960 res://tests/visual_capture.tscn -- --automation --skip-title --out=<absolute dir>

var out_dir := "user://captures"
var _vp: SubViewport
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = "--title" not in OS.get_cmdline_user_args()
	World.area_id = "test_area"
	World.entrance_id = ""
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_vp = _main.get_node("GameView/GameViewport")
	await _frames(60)
	if GameManager.state == GameManager.GameState.TITLE:
		await _shot("00_title")
		await _window("00_title_window")
		_main.get_node("GameView/GameViewport/TitleScreen/Screen").start_at("test_area")
		await _frames(10)
	var player: PlayerController = GameManager.player
	var cam: AdventureCamera = _main.get_node("GameView/GameViewport/TestArea/CameraRig")
	await _shot("01_spawn")
	await _window("01_spawn_window")

	player.debug_use_move_input = true
	player.debug_move_input = Vector3(0, 0, -1)
	await _frames(80)
	await _shot("02_walk_north")
	player.debug_move_input = Vector3(0, 0, 1)
	await _frames(40)
	await _shot("03_turned_around")
	player.debug_move_input = Vector3.ZERO
	await _frames(20)
	Input.action_press("camera_recenter")
	await _frames(2)
	Input.action_release("camera_recenter")
	await _frames(30)
	await _shot("04_recentered")

	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _frames(9)
	await _shot("05_attack")
	await _frames(90)
	Input.action_press("shield")
	await _frames(40)
	await _shot("06_block")
	Input.action_release("shield")
	await _frames(10)
	# Z with nothing in range: parallel mode, letterbox and strafing.
	Input.action_press("target")
	await _frames(20)
	await _window("06b_z_parallel_window")
	Input.action_press("move_left")
	await _frames(25)
	await _shot("06c_z_strafe")
	Input.action_press("shield")
	await _frames(15)
	await _shot("06d_z_shield_strafe")
	Input.action_release("shield")
	Input.action_release("move_left")
	Input.action_release("target")
	await _frames(20)

	# Stand near the first goblin and let it come at us.
	player.debug_use_move_input = false
	player.global_position = Vector3(-5.5, 0.3, 7.0)
	player.facing_yaw = 0.0
	cam.snap_behind_target()
	await _frames(100)
	await _shot("07_encounter")
	Input.action_press("target")
	await _frames(2)
	Input.action_release("target")
	await _frames(30)
	await _shot("08_target_lock")
	await _frames(25)
	await _shot("08b_target_lock_later")

	# Free-camera overview shots.
	var free := Camera3D.new()
	free.fov = 60
	free.far = 300
	_vp.add_child(free)
	free.global_position = Vector3(18, 16, 30)
	free.look_at(Vector3(-2, 0, -6))
	free.current = true
	await _frames(3)
	await _shot("09_overview_south")
	free.global_position = Vector3(-3, 6, -12)
	free.look_at(Vector3(0, 2.5, -26))
	await _frames(3)
	await _shot("10_ruin")
	free.global_position = Vector3(-6, 7, 6)
	free.look_at(Vector3(-17, 2, -4))
	await _frames(3)
	await _shot("11_outcrop")
	free.global_position = player.global_position + player.forward() * 2.4 + Vector3(0.6, 1.4, 0)
	free.look_at(player.global_position + Vector3(0, 1.1, 0))
	await _frames(3)
	await _shot("12_player_closeup")
	free.global_position = Vector3(10, 8, 12)
	free.look_at(Vector3(24, 0, 0))
	await _frames(3)
	await _shot("13_east_cliff")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	img.save_png(out_dir.path_join(file + ".png"))
	print("captured %s (%dx%d)" % [file, img.get_width(), img.get_height()])


func _window(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(file + ".png"))
	print("captured %s (%dx%d)" % [file, img.get_width(), img.get_height()])
