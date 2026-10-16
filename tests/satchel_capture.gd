extends Node
## Screenshots for "The Satchel" (1.6.0): the SELECT ITEM page with every
## item, the other pages in their new dress, the HUD's magic meter, the
## Looking Glass view and the items' effects (windowed):
##   Godot --path <project> --resolution 960x720 res://tests/satchel_capture.tscn -- --out=<dir>

var out_dir := "user://satchel_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a == "--wide":
			GameManager.widescreen = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	World.area_id = "lake"
	World.entrance_id = ""
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(120)
	_give_everything()
	await _frames(10)
	await _shot("00_hud_magic")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	_press("pause")
	await _frames(40)
	pm.item_cursor = Vector2i(1, 2)
	await _frames(20)
	await _shot("01_select_item")
	for i in pm.PAGE_COUNT:
		(pm._pages[i] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_%d_raw.png" % i))
	pm.item_cursor = Vector2i(0, 3)
	await _frames(10)
	await _shot("02_select_item_pack")
	_press("target")
	await _frames(40)
	await _shot("03_equipment")
	_press("shield")
	await _frames(40)
	_press("shield")
	await _frames(40)
	await _shot("04_map")
	_press("pause")
	await _frames(40)
	# Effects: the Looking Glass view, then the blessings and the mallet.
	var p: PlayerController = GameManager.player
	Progress.assign("item_x", "looking_glass")
	_press("item_x")
	await _frames(30)
	await _shot("05_looking_glass")
	_press("first_person")
	await _frames(20)
	for pair in [["serielyes_ruin", 20], ["alans_harvest", 30], ["iron_mallet", 18]]:
		Progress.assign("item_x", pair[0])
		_press("item_x")
		await _frames(pair[1])
		await _shot("06_" + String(pair[0]))
		await _frames(60)
	# A frost floe on the lake.
	var waters: Array = World.area_node.get_meta("water", [])
	if not waters.is_empty():
		var r: Rect2 = waters[0][0]
		var wy: float = waters[0][1]
		var at := Vector3(r.get_center().x, wy, r.get_center().y)
		IceFloe.freeze_at(World.area_node, at)
		p.global_position = at + Vector3(0, 0.4, 0)
		await _frames(60)
		await _shot("07_ice_floe")
	get_tree().quit()


func _give_everything() -> void:
	for id: String in Progress.ITEM_GRID:
		if id == "" or id.begins_with("bottle_"):
			continue
		if id == "bombs":
			Progress.give_bomb_bag()
		elif id == "puff_nuts":
			Progress.give_nut_pouch(14)
		else:
			Progress.give_item(id)
	for b in ["fairy", "milk", "red_potion", "empty"]:
		Progress.give_bottle(b)
	Progress.give_magic_meter()
	Progress.use_magic(10)
	Progress.assign("item_x", "bow")
	Progress.assign("item_y", "lantern")
	Progress.arrows = 22


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
