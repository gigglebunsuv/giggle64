extends Node
## Screenshots of Beta 1.0.0's screens for visual checks (windowed): the
## EQUIPMENT page with the tunics and upgrades, the JOURNAL, OPTIONS >
## CONTROLS, the hero in the Knight's Regalia, the HUD's cold countdown in
## Frostpeak Hollow, and the title screen.
##   Godot --path <project> --resolution 640x480 res://tests/beta_capture.tscn -- --automation --out=<dir>

var out_dir := "user://beta_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	World.area_id = "village"
	World.entrance_id = "home"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(90)
	# A file well into Chapter II.
	for f in ["woke_up", "lake_shrine:r7_clear", "bun_piece:alan", "himeko:met", "himeko:fish_given", "mira_rod", "lake:big_fish", "game_beaten", "ch2:shelter_met"]:
		Progress.set_flag(f)
	Progress.give_item("iron_mallet")
	for t in ["tide", "frost", "shade"]:
		Progress.give_tunic(t)
	Progress.give_vanity("regalia")
	Progress.give_bracers(1)
	Progress.give_scale(1)
	Progress.wallet = Progress.GIANT_WALLET
	Progress.give_magic_meter()
	await _frames(20)
	await _shot("01_regalia_in_village")
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	_press("pause")
	await _frames(40)
	_press("target")
	await _frames(40)
	pm.equip_cursor = Vector2i(4, pm.TUNIC_ROW_INDEX)
	await _frames(10)
	await _shot("02_equipment")
	(pm._pages[pm.Page.EQUIP] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_equipment_raw.png"))
	for i in 4:
		_press("shield")
		await _frames(30)
	await _frames(20)
	await _shot("03_journal")
	(pm._pages[pm.Page.JOURNAL] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_journal_raw.png"))
	_press("shield")
	await _frames(40)
	pm.sub_list = "CONTROLS"
	pm.option_cursor = 0
	await _frames(10)
	(pm._pages[pm.Page.OPTIONS] as SubViewport).get_texture().get_image().save_png(out_dir.path_join("page_controls_raw.png"))
	pm.sub_list = ""
	_press("pause")
	await _frames(30)
	# The cold, in Frostpeak Hollow.
	Progress.equip_tunic("haven")
	World.warp("frostpeak_hollow")
	await _frames(240)
	await _shot("04_hollow_cold")
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
