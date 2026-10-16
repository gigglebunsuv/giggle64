extends Node
## Screenshots of Pink's Armory and the new gear in the real game view, for
## visual checks (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/armory_capture.tscn -- --automation --out=<dir>
## The shop front in Old Castle Town, the room, talking to Pink and getting a
## sword, the Questlords on their bench, the HUD with each sword, a Bun Sword
## beam, and the pause screen's EQUIPMENT and SELECT ITEM pages.

var out_dir := "user://armory_captures"
var _main: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	Progress.give_item("boomerang")
	# The shop front, seen across the square and from the street.
	await _load("castle_town", "from_armory")
	var p := GameManager.player
	await _frames(60)
	_view(p, Vector3(-18, 0, -14), Vector3(-35, 3, -21))
	await _frames(30)
	await _shot("01_front_square")
	_view(p, Vector3(-26, 0, -30), Vector3(-34, 3.5, -19))
	await _frames(30)
	await _shot("02_front_street")
	p.global_position = Vector3(-31.5, 0.5, -21)
	p.face_direction(Vector3(-1, 0, 0))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(40)
	await _shot("03_front_door")
	# Inside.
	await _load("armory", "from_castle_town")
	p = GameManager.player
	await _frames(90)
	await _shot("04_inside")
	_view(p, Vector3(2.5, 0, 2.5), Vector3(-3, 1, -2.5))
	await _frames(30)
	await _shot("05_pink_forge")
	_view(p, Vector3(1.5, 0, -1.0), Vector3(-5.5, 0.8, 0.6))
	await _frames(30)
	await _shot("06_questlords")
	_view(p, Vector3(-1, 0, 1.5), Vector3(4, 2, -4.5))
	await _frames(30)
	await _shot("07_weapon_walls")
	# Talk to Aladriel (Idrith blushes), then to Pink for a sword.
	var ala := World.area_node.get_node("Features/Aladriel") as Node3D
	await _face_npc(p, ala, 1.0)
	await _tap("interact")
	await _secs(2.0)
	await _tap("interact")
	await _secs(2.2)
	await _shot("08_aladriel_talk")
	await _finish_talk(p)
	var pink := World.area_node.get_node("Features/Pink") as Node3D
	await _face_npc(p, pink, 1.5)
	await _tap("interact")
	for i in 12:
		await _secs(1.2)
		if Dialogue.phase == Dialogue.Phase.CHOOSING:
			break
		await _tap("interact")
	await _shot("09_pink_menu")
	await _tap("interact")
	for i in 12:
		await _secs(1.2)
		if p.item_get:
			break
		await _tap("interact")
	await _secs(1.0)
	await _shot("10_got_sword")
	await _finish_talk(p)
	# The HUD with each sword (and the boomerang and bow on X / Y).
	var ids := ["red", "magical", "bun"]
	for i in ids.size():
		Progress.give_sword(ids[i])
		Progress.give_shield(["iron", "mirror", "mirror"][i])
		p.global_position = Vector3(1.0, 0.5, 2.5)
		p.face_direction(Vector3(0, 0, -1))
		World.area_node.get_node("CameraRig").snap_behind_target()
		await _frames(30)
		await _shot("11_hud_%s" % ids[i])
	# A swing with full health looses a beam.
	await _tap("attack")
	await _frames(16)
	await _shot("12_beam")
	await _frames(40)
	# The pause pages.
	_press("pause")
	await _frames(40)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	pm.page = pm.Page.EQUIP
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	pm.equip_cursor = Vector2i(3, 0)
	await _frames(30)
	await _shot("13_equipment")
	pm.page = pm.Page.ITEM
	pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
	await _frames(20)
	await _shot("14_items")
	# Mid-flip, to see the five-sided drum.
	pm._flip(false)
	await _secs(0.17)
	await _shot("15_flip")
	get_tree().quit()


func _finish_talk(p: PlayerController) -> void:
	for i in 40:
		if not Dialogue.active and p.state != PlayerController.State.TALK:
			break
		await _tap("interact")
		await _secs(0.4)
	await _frames(20)


func _face_npc(p: PlayerController, npc: Node3D, dist: float) -> void:
	var to_me := npc.global_basis * Vector3(0, 0, -1)
	p.global_position = npc.global_position + to_me * dist + Vector3(0, 0.1, 0)
	p.face_direction(-to_me)
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(40)


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
	p.global_position = Vector3(eye.x, eye.y + 1.0, eye.z)
	p.face_direction(flat)
	World.area_node.get_node("CameraRig").snap_behind_target()


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
