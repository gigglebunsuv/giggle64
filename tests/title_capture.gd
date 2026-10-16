extends Node
## Captures the boot sequence for visual review: both splash screens, every
## title backdrop shot (start and end of its drift, without the logo), the
## title itself, the attract scene, the file select (main menu, the area
## list) and the game starting in the chosen area. `--wide` captures in 16:9;
## `--attract` only an attract scene (a frame every half second; `--scene=N`
## picks which, 0 the hero and the rat, 1 Mira, 2 the Questlords).
##
## Run windowed (needs a GPU):
##   Godot --path <project> --resolution 640x480 res://tests/title_capture.tscn -- --automation --out=<absolute dir>

var out_dir := "user://captures"
var _vp: SubViewport
var _main: Node
var _title: Node


func _ready() -> void:
	var attract_only := false
	var scene := -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a == "--wide":
			GameManager.widescreen = true
		elif a == "--attract":
			attract_only = true
		elif a.begins_with("--scene="):
			scene = int(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = false
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	_vp = _main.get_node("GameView/GameViewport")
	_title = _main.get_node("GameView/GameViewport/TitleScreen/Screen")
	if attract_only:
		await _seconds(0.5)
		_title.start_attract(scene)
		var i := 0
		while _title.phase == _title.Phase.ATTRACT:
			await _seconds(0.5)
			await _shot("attract_%02d" % i)
			i += 1
		get_tree().quit()
		return
	await _seconds(1.2)
	await _shot("00_splash_1")
	await _seconds(3.6)
	await _shot("01_splash_2")
	while _title.phase == _title.Phase.SPLASH:
		await _frames(1)
	await _seconds(2.0)
	await _shot("02_title")
	var fly: TitleFlyover = _title._flyover
	for i in fly.SHOTS.size():
		fly.shot = i - 1
		fly._next_shot()
		_title._logo_alpha = 0.0
		for end in [0.12, 0.5, 0.92]:
			fly._t = fly.SHOT_TIME * end
			_title._logo_alpha = 0.0
			await _frames(3)
			fly._t = fly.SHOT_TIME * end
			fly._update_shot()
			_title._logo_alpha = 0.0
			await _shot("03_shot_%d_%s_%d" % [i, fly.SHOTS[i]["area"], int(end * 100)])
	fly.shot = -1
	fly._next_shot()
	await _seconds(2.0)
	await _shot("04_title_composite")
	await _press("ui_accept")
	await _seconds(1.5)
	await _shot("05_file_select")
	await _press("ui_down")
	await _seconds(0.3)
	await _shot("06_file_2")
	await _press("ui_accept")
	await _seconds(1.0)
	await _shot("07_area_list")
	for i in 3:
		await _press("ui_down")
		await _seconds(0.15)
	await _shot("08_area_list_moved")
	await _press("ui_accept")
	await _seconds(1.0)
	await _shot("09_starting")
	await _seconds(2.0)
	await _shot("10_in_game")
	print("title_capture: state=%s area=%s" % [GameManager.state, World.area_id])
	get_tree().quit()


func _press(action: String) -> void:
	# Queued like real input, so it is "just pressed" during the next frame.
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	img.save_png(out_dir.path_join(file + ".png"))
	print("captured %s" % file)
