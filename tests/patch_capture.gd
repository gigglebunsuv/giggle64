extends "res://tests/armory_capture.gd"
## Screenshots of the Beta 1.3.1 patch in the real game view (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/patch_capture.tscn -- --automation --out=<dir> [--only=a,b]
## Groups: waystone (the waystone menu), n64 (the same views with TRUE N64 MODE
## off, on, and on with N64 MIPMAPS), options (the GRAPHICS list).


func _ready() -> void:
	out_dir = "user://patch_captures"
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	for group in ["waystone", "n64", "options"]:
		if only.is_empty() or group in only:
			await call("_cap_" + group)
	get_tree().quit()


func _cap_waystone() -> void:
	for a in ["village", "field", "forest", "marsh", "desert", "lake", "cliffs", "batela_fells"]:
		Progress.set_flag(Waystone.flag_of(a))
	await _load("village", "waystone")
	await _frames(60)
	var stone := get_tree().get_nodes_in_group("interactable").filter(func(n: Node) -> bool: return n is Waystone)[0] as Waystone
	var menu := WaystoneMenu.choose(stone.area)
	await _frames(30)
	await _shot("waystone_01_menu")
	menu.move_cursor(Vector2i(0, 1))
	menu.move_cursor(Vector2i(1, 0))
	await _frames(10)
	await _shot("waystone_02_cursor")
	menu.cursor = Waystone.ORDER.find("snow")
	await _frames(10)
	await _shot("waystone_03_unfound")
	menu.close("")
	await _frames(5)


func _cap_n64() -> void:
	for spot: Array in [["field", "", Vector3.ZERO, Vector3.ZERO], ["village", "", Vector3.ZERO, Vector3.ZERO], ["lake_shrine", "", Vector3.ZERO, Vector3.ZERO]]:
		await _load(spot[0], spot[1])
		await _frames(80)
		var p := GameManager.player
		# Close on the hero's back, then the wide view.
		for mode in [[false, false, "off"], [true, false, "on"], [true, true, "lod"]]:
			GameManager.true_n64 = mode[0]
			GameManager.n64_mipmaps = mode[1]
			GameManager.settings_changed.emit()
			await _frames(20)
			await _shot("n64_%s_%s" % [spot[0], mode[2]])
		GameManager.true_n64 = false
		GameManager.n64_mipmaps = false
		GameManager.settings_changed.emit()
		await _frames(5)
	print("n64 converted surfaces check done")


func _cap_options() -> void:
	await _load("field", "from_village")
	await _frames(90)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = "pause"
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(40)
	pm.page = pm.Page.OPTIONS
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	pm.phase = pm.Phase.OPEN
	pm.option_cursor = pm.OPTIONS.find("GRAPHICS")
	pm._accept()
	await _frames(10)
	(pm._pages[int(pm.Page.OPTIONS)] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("options_graphics_raw.png"))
	await _shot("options_graphics")
