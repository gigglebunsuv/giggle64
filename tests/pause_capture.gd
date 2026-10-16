extends Node
## Screenshots of the pause screen pages, a page flip in progress, the area map
## and the minimap, for visual checks (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/pause_capture.tscn -- --automation --out=<dir>

var out_dir := "user://pause_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a == "--wide":
			GameManager.widescreen = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	World.area_id = "field"
	World.entrance_id = "from_village"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(150)
	await _shot("00_minimap")
	_press("pause")
	await _frames(6)
	await _shot("01_opening")
	await _frames(30)
	await _shot("02_item")
	for i in 3:
		_press("shield")
		await _frames(20)
		await _shot("%02d_switching_%d" % [3 + i * 2, i])
		await _frames(50)
		await _shot("%02d_page_%d" % [4 + i * 2, i + 1])
	# Back to the map page and zoom into the area map.
	_press("shield")
	await _frames(70)
	_press("shield")
	await _frames(70)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	pm.page = pm.Page.MAP
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	pm.phase = pm.Phase.OPEN
	pm.map_zoom = false
	await _frames(10)
	await _shot("09_world_map")
	(pm._pages[1] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_world_map_raw.png"))
	(pm._pages[0] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_item_raw.png"))
	(pm._pages[3] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_options_raw.png"))
	pm.map_zoom = true
	await _frames(10)
	await _shot("10_area_map")
	(pm._pages[1] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_map_raw.png"))
	get_tree().quit()


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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	vp.get_texture().get_image().save_png(out_dir.path_join(shot_name + ".png"))
