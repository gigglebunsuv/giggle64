extends "res://tests/armory_capture.gd"
## Screenshots of the big update in the real game view, for visual checks
## (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/update_capture.tscn -- --automation --out=<dir> [--only=a,b]
## Groups: town (library, shop), forest (Bun Sword pedestal), lake (fishing,
## swimming), moves (jump slash), horse, tower (the Southern Tower, the hookshot).


func _ready() -> void:
	out_dir = "user://update_captures"
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	for group in ["town", "forest", "lake", "moves", "horse", "tower"]:
		if only.is_empty() or group in only:
			await call("_cap_" + group)
	get_tree().quit()


func _cap_town() -> void:
	await _load("village", "from_library")
	var p := GameManager.player
	await _frames(60)
	_view(p, Vector3(30, 0, 12), Vector3(30, 3, 26))
	await _frames(30)
	await _shot("town_01_library_front")
	await _load("library", "from_village")
	p = GameManager.player
	await _frames(90)
	await _shot("town_02_library_in")
	_view(p, Vector3(0, 0, 4.5), Vector3(0, 2.5, -6))
	await _frames(30)
	await _shot("town_03_library_gallery")
	_view(p, Vector3(-1.5, 0, 5.0), Vector3(2.0, 1, 4.6))
	await _frames(30)
	await _shot("town_04_ottilie")
	await _load("village", "from_shop")
	p = GameManager.player
	await _frames(60)
	_view(p, Vector3(-24, 0, -14), Vector3(-27, 2.5, -24))
	await _frames(30)
	await _shot("town_05_shop_front")
	await _load("shop", "from_village")
	p = GameManager.player
	await _frames(90)
	await _shot("town_06_shop_in")
	Progress.rupees = 60
	var ware := get_tree().get_nodes_in_group("shop_items")[0] as Node3D
	p.global_position = Vector3(ware.global_position.x, 0.1, ware.global_position.z + 0.95)
	p.face_direction(Vector3(0, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(30)
	await _tap("interact")
	await _secs(1.6)
	await _shot("town_07_shop_buy")
	await _finish_talk(p)


func _cap_forest() -> void:
	await _load("hidden_forest", "")
	var p := GameManager.player
	await _frames(60)
	_view(p, Vector3(0, 0, 8), Vector3(0, 1.5, -4))
	await _frames(30)
	await _shot("forest_01_stones")
	Progress.set_flag("hidden_forest:stones_awake")
	await _frames(30)
	_view(p, Vector3(1.5, 0, 0.0), Vector3(0, 1.5, -4))
	await _frames(30)
	await _shot("forest_02_bun_sword")


func _cap_lake() -> void:
	await _load("lake", "from_lake_house")
	var p := GameManager.player
	Progress.set_flag("mira_rod")
	await _frames(60)
	var spot := get_tree().get_nodes_in_group("fishing_spots")[0] as FishingSpot
	var out := -spot.global_basis.z
	p.global_position = spot.global_position - out * 0.9 + Vector3.UP * 0.2
	p.face_direction(out)
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(30)
	await _tap("interact")
	await _frames(20)
	await _shot("lake_01_rod_out")
	_press("interact")
	await _secs(0.1)
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _secs(0.9)
	var up := InputEventAction.new()
	up.action = "interact"
	up.pressed = false
	Input.parse_input_event(up)
	await _secs(1.5)
	await _shot("lake_02_cast")
	await _tap("attack")
	await _frames(20)
	await _tap("attack")
	await _frames(20)
	# Swimming in the lake.
	p.global_position = Vector3(5, 0.3, 30)
	p.face_direction(Vector3(1, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _secs(3.0)
	await _shot("lake_03_float")
	p.debug_use_move_input = true
	p.debug_move_input = Vector3(0.7, 0, -0.7)
	await _secs(1.4)
	await _shot("lake_04_swim")
	p.debug_move_input = Vector3.ZERO
	var dv := InputEventAction.new()
	dv.action = "interact"
	dv.pressed = true
	Input.parse_input_event(dv)
	await _secs(0.9)
	await _shot("lake_05_dive")
	var du := InputEventAction.new()
	du.action = "interact"
	du.pressed = false
	Input.parse_input_event(du)
	p.debug_use_move_input = false
	await _secs(2.0)


func _cap_moves() -> void:
	await _load("test_area", "")
	var p := GameManager.player
	await _frames(60)
	var e := get_tree().get_nodes_in_group("enemies")[0] as Node3D
	e.set_physics_process(false)
	p.global_position = e.global_position + Vector3(0, 0.3, 3.6)
	p.face_direction(Vector3(0, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(20)
	_press("target")
	await _frames(10)
	await _tap("interact")
	await _secs(0.22)
	await _shot("moves_01_jumpslash_air")
	await _secs(0.24)
	await _shot("moves_02_jumpslash_land")
	await _secs(1.0)


func _cap_horse() -> void:
	await _load("southern_fields", "from_field")
	var p := GameManager.player
	await _frames(60)
	_view(p, Vector3(26, 0, 14), Vector3(32, 1, 30))
	await _frames(40)
	await _shot("horse_01_corral")
	var h := get_tree().get_nodes_in_group("horses")[0] as Horse
	var clover := World.area_node.get_node("Features/Clover") as Node3D
	await _face_npc(p, clover, 1.4)
	await _shot("horse_02_clover")
	# Riding on the open castle road in the field.
	await _load("field", "")
	p = GameManager.player
	await _frames(40)
	var pos := Vector3(0, 0, 4)
	h = Horse.spawn(World.area_node, pos + Vector3(0, 1.0, 0), 0.0)
	await _frames(20)
	var side := h.global_basis * Vector3(-1.3, 0, 0)
	p.global_position = h.global_position + side + Vector3.UP * 0.2
	p.face_direction(-side)
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(20)
	await _tap("interact")
	await _frames(30)
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(20)
	await _shot("horse_03_mounted")
	p.debug_use_move_input = true
	p.debug_move_input = Vector3(0, 0, -1)
	await _secs(2.0)
	await _shot("horse_04_gallop")
	p.debug_move_input = Vector3(0.7, 0, -0.7)
	await _secs(0.8)
	await _shot("horse_06_turn")
	p.debug_move_input = Vector3.ZERO
	p.debug_use_move_input = false
	await _secs(1.0)
	# The field's horseback archery targets, seen from the road.
	await _load("field", "")
	p = GameManager.player
	await _frames(60)
	_view(p, Vector3(46, 0, 22), Vector3(64, 1, 13))
	await _frames(40)
	await _shot("horse_05_archery_road")


func _cap_tower() -> void:
	await _load("southern_fields", "from_southern_tower")
	var p := GameManager.player
	await _frames(60)
	_view(p, Vector3(-5, 0, 20), Vector3(-5, 4, 34))
	await _frames(40)
	await _shot("tower_01_outside")
	Progress.set_flag("southern_tower:door")
	await _load("southern_tower", "from_southern_fields")
	p = GameManager.player
	await _frames(90)
	await _shot("tower_02_entry")
	_view(p, Vector3(6, 0, 11), Vector3(-2, 4, -10))
	await _frames(40)
	await _shot("tower_03_granary")
	_view(p, Vector3(-20, 0, 6), Vector3(-34, 1, -2))
	await _frames(40)
	await _shot("tower_04_loom")
	_view(p, Vector3(20, 0, 8), Vector3(34, 2, -2))
	await _frames(40)
	await _shot("tower_05_mill")
	# The Hookshot up to the gallery.
	Progress.give_item("hookshot")
	Progress.assign("item_y", "hookshot")
	p.global_position = Vector3(4.0, 0.3, -2.0)
	p.face_direction(Vector3(-0.4, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _frames(20)
	var ev := InputEventAction.new()
	ev.action = "item_y"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(4)
	var target := Vector3(0, 5.1, -7.9)
	var d := target - p.aim_origin()
	p.look_yaw = atan2(-d.x, -d.z)
	p.look_pitch = atan2(d.y, Vector2(d.x, d.z).length())
	await _secs(0.5)
	await _shot("tower_06_hookshot_aim")
	var up := InputEventAction.new()
	up.action = "item_y"
	up.pressed = false
	Input.parse_input_event(up)
	await _secs(0.35)
	await _shot("tower_07_hookshot_fly")
	await _secs(2.0)
	p.respawn()
	await _frames(5)
	_view(p, Vector3(0, 6, -24), Vector3(0, 7, -36))
	await _frames(40)
	await _shot("tower_08_gear_hall")
	# The roof and Corvax.
	p.global_position = Vector3(0, 6.3, -54.0)
	p.face_direction(Vector3(0, 0, -1))
	World.area_node.get_node("CameraRig").snap_behind_target()
	await _secs(2.4)
	await _shot("tower_09_corvax_title")
	await _secs(2.5)
	await _shot("tower_10_corvax_circle")
