extends Node
## Screenshots of the HUD styles and button icons (windowed):
##   Godot --path <project> res://tests/hud_capture.tscn -- --automation

func _ready() -> void:
	GameManager.skip_title = true
	World.area_id = "field"
	World.entrance_id = ""
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 60:
		await get_tree().process_frame
	Progress.give_bomb_bag()
	Progress.give_item("bloom_rod")
	Progress.assign("item_y", "bombs")
	var vp: SubViewport = main.get_node("GameView/GameViewport")
	var out := "G:/Games/Godot Games/_giggle64_work/tmp/hud_"
	var shots := [["classic_kb", false, false, 0, 0], ["classic_xbox", false, true, 1, 0], ["modern_xbox", true, true, 1, 0],
		["modern_ps", true, true, 2, 0], ["modern_nintendo", true, true, 3, 0], ["modern_kb", true, false, 0, 0], ["modern_ps_1080", true, true, 2, 3],
		["classic_kb_wide", false, false, 0, 0, true], ["modern_xbox_wide", true, true, 1, 0, true], ["classic_xbox_wide_720", false, true, 1, 2, true]]
	for s in shots:
		GameManager.hud_modern = s[1]
		GameManager.using_gamepad = s[2]
		GameManager.glyph_family = s[3]
		GameManager.render_index = s[4]
		GameManager.widescreen = s.size() > 5 and s[5]
		GameManager.settings_changed.emit()
		for i in 20:
			await get_tree().process_frame
		vp.get_texture().get_image().save_png(out + s[0] + ".png")
	GameManager.render_index = 0
	GameManager.widescreen = false
	get_tree().quit()
