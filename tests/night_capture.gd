extends Node
## Screenshots for the 1.5.0 update (windowed): an area at noon, dusk, night
## and dawn; the OPTIONS > SOUND page; the debug menu's SCENES tab; the map
## page's clock.
##   Godot --path <project> --resolution 640x480 res://tests/night_capture.tscn -- --automation --out=<dir> [--areas=field,village]

var out_dir := "user://night_captures"
var _main: Node


func _ready() -> void:
	var areas := ["field", "village", "lake"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--areas="):
			areas = Array(a.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	DayNight.frozen = true
	for area: String in areas:
		for hr in [12.0, 18.0, 23.0, 5.8]:
			Progress.day_time = hr
			await _load(area, "")
			await _frames(90)
			await _shot("%s_%02d" % [area, int(hr * 10)])
	Progress.day_time = 21.0
	await _load("field", "")
	await _frames(60)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	_press("pause")
	await _frames(40)
	pm.page = pm.Page.MAP
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	await _frames(10)
	await _shot("pause_map_clock")
	pm.page = pm.Page.OPTIONS
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	await _frames(10)
	await _shot("pause_options")
	pm.sub_list = "SOUND"
	pm.option_cursor = 1
	GameManager.volumes["footsteps"] = 5
	await _frames(10)
	await _shot("pause_sound")
	_press("pause")
	await _frames(40)
	var dbg: DebugMenu = _main.find_child("DebugMenu", true, false)
	dbg.open()
	dbg._set_tab(DebugMenu.TABS.find("SCENES"))
	await _frames(5)
	await _shot("debug_scenes")
	dbg._set_tab(DebugMenu.TABS.find("SOUND"))
	await _frames(5)
	await _shot("debug_sound")
	get_tree().quit()


func _load(area: String, entrance: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _press(action: String) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, label])
