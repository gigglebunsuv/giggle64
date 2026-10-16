extends "res://tests/armory_capture.gd"
## Screenshots for the bug-fix update after Beta 1.3.1 (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/bugfix_capture.tscn -- --automation --out=<dir> [--only=a,b]
## Groups:
##   entrances  every dungeon as the hero walks in (its default entrance), at
##              a few moments of the walk-in
##   caves      every cave mouth and loading zone in the open regions, from
##              its return spot looking in
##   pause      the SELECT ITEM and EQUIPMENT pages with everything owned
##   sword      the awakened (pink) Bun Sword in the hand and on the HUD
##   hearts     the HUD with 22 hearts and the double magic meter

const DUNGEONS := ["lake_shrine", "southern_tower", "ladhellin_tower", "skyreach_spire", "bog_tower", "castle",
	"frostpeak_hollow", "sun_trial", "sapphire_sanctum", "westmarch_fortress", "temple_of_bun", "citadel_assault",
	"barrow_of_kings", "cinder_vault"]
const REGIONS := ["field", "village", "castle_town", "forest", "hidden_forest", "marsh", "southern_fields", "desert",
	"cliffs", "snow", "lake", "forest_of_the_dead", "batela_fells", "dark_forest", "cinderhold"]

var _only_areas: Array = []


func _ready() -> void:
	out_dir = "user://bugfix_captures"
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
		elif a.begins_with("--areas="):
			_only_areas = Array(a.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	for group in ["entrances", "arrival", "chest", "caves", "bombs", "pause", "sword", "hearts", "fp"]:
		if only.is_empty() or group in only:
			await call("_cap_" + group)
	get_tree().quit()


func _wanted(area: String) -> bool:
	return _only_areas.is_empty() or area in _only_areas


func _cap_entrances() -> void:
	for d: String in DUNGEONS:
		if not _wanted(d):
			continue
		World.area_id = d
		await _load(d, "")
		for t in [0.15, 0.7, 1.6]:
			await _secs(0.15 if t == 0.15 else (0.55 if t == 0.7 else 0.9))
			await _shot("entrance_%s_%02d" % [d, int(t * 10)])


## Through a door for real (World.change_area): the arrival shot from inside,
## then the camera gliding round behind; and out again through the door.
func _cap_arrival() -> void:
	for pair: Array in [["southern_fields", "southern_tower"], ["village", "hero_house"], ["lake", "lake_shrine"]]:
		if not _wanted(pair[1]):
			continue
		await _load(pair[0], "from_" + String(pair[1]))
		await _frames(60)
		World.change_area(pair[1], "")
		var last := 0.0
		for t: float in [1.5, 1.9, 2.4, 3.0, 3.8]:
			await _secs(t - last)
			last = t
			await _shot("arrival_%s_%02d" % [pair[1], int(t * 10)])
		# And out through its door.
		for i in 120:
			if not World.transitioning:
				break
			await _frames(1)
		var p := GameManager.player
		var door: Door = null
		for d in get_tree().get_nodes_in_group("doors"):
			if (d as Door).global_position.distance_to(p.global_position) < 9.0:
				door = d
		if door:
			var front := -door.global_basis.z
			p.global_position = door.global_position + Vector3(front.x, 0, front.z).normalized() * 1.1 + Vector3.UP * 0.1
			p.face_direction(-front)
			World.area_node.get_node("CameraRig").snap_behind_target()
			await _frames(20)
			door.interact(p)
			await _secs(0.45)
			await _shot("exitdoor_%s_a" % pair[1])
			await _secs(0.4)
			await _shot("exitdoor_%s_b" % pair[1])
			for i in 200:
				if not World.transitioning:
					break
				await _frames(1)


## Opening a small and a big chest (the treasure-box camera).
func _cap_chest() -> void:
	await _load("lake_shrine", "")
	await _frames(60)
	var p := GameManager.player
	var chests := get_tree().get_nodes_in_group("chests")
	var done := 0
	for c in chests:
		var ch := c as TreasureChest
		if ch == null or ch.opened or not ch.visible or done >= 2:
			continue
		var front := -ch.global_basis.z
		p.global_position = ch.global_position + Vector3(front.x, 0, front.z).normalized() * 1.0 + Vector3.UP * 0.1
		p.face_direction(-front)
		World.area_node.get_node("CameraRig").snap_behind_target()
		await _frames(20)
		ch.interact(p)
		await _secs(0.5)
		await _shot("chest_%d_open" % done)
		await _secs(1.4)
		await _shot("chest_%d_item" % done)
		for i in 10:
			await _tap("interact")
			await _secs(0.5)
			if not Dialogue.active:
				break
		await _secs(1.0)
		await _shot("chest_%d_after" % done)
		done += 1


## The bombable walls and boulders, seen from a few steps off.
func _cap_bombs() -> void:
	for area: String in ["field", "forest", "snow", "cliffs", "lake_shrine", "southern_tower", "bog_tower", "castle"]:
		if not _wanted(area):
			continue
		await _load(area, "")
		await _frames(30)
		var walls: Array = get_tree().get_nodes_in_group("bombables").map(func(n: Node) -> String: return String(n.get_path()))
		var i := 0
		for path: String in walls.slice(0, 2):
			await _load(area, "")
			await _frames(40)
			var w := get_node_or_null(path) as Node3D
			if w == null:
				continue
			var front := -w.global_basis.z
			front = Vector3(front.x, 0, front.z).normalized()
			var p := GameManager.player
			p.global_position = w.global_position + front * 4.5 + Vector3.UP * 0.5
			p.face_direction(-front)
			World.area_node.get_node("CameraRig").snap_behind_target()
			await _frames(40)
			await _shot("bomb_%s_%d" % [area, i])
			i += 1


func _cap_caves() -> void:
	for area: String in REGIONS:
		if not _wanted(area):
			continue
		await _load(area, "")
		await _frames(30)
		var exits: Array = []
		for n in World.area_node.find_children("*", "Area3D", true, false):
			if n.get_script() and n.get_script().resource_path.get_file() == "area_exit.gd":
				exits.append([String(n.name), (n as Node3D).global_position, String(n.get("target_area"))])
		var marks := {}
		for m in World.area_node.get_node("Entrances").get_children():
			marks[String(m.name)] = (m as Node3D).global_position
		for ex: Array in exits:
			var at: Vector3 = ex[1]
			var from: Variant = marks.get("from_" + String(ex[2]))
			if from == null or (from as Vector3).distance_to(at) > 14.0:
				continue
			await _load(area, "")
			await _frames(40)
			var p := GameManager.player
			var start: Vector3 = from
			p.global_position = start + Vector3.UP * 0.3
			p.face_direction(Vector3(at.x - start.x, 0, at.z - start.z))
			p.velocity = Vector3.ZERO
			World.area_node.get_node("CameraRig").snap_behind_target()
			await _frames(30)
			await _shot("cave_%s_%s" % [area, String(ex[0]).trim_prefix("To_")])


func _cap_pause() -> void:
	Progress.reset()
	for id: String in Progress.ITEM_GRID:
		if id != "" and not id.begins_with("bottle_"):
			Progress.give_item(id)
	for i in 4:
		Progress.give_item("bottle_%d" % i)
	for s in Equipment.SWORD_ORDER:
		Progress.give_sword(s)
	for s in Equipment.SHIELD_ORDER:
		Progress.give_shield(s)
	for t in Equipment.TUNIC_ORDER:
		Progress.give_tunic(t)
	for v in ["regalia", "knight"]:
		Progress.give_vanity(v)
	for b in Equipment.BOOT_ORDER:
		Progress.give_boots(b)
	Progress.magic_max = 96
	Progress.magic = 96
	Progress.assign("item_x", "ember_rod")
	Progress.assign("item_y", "fishing_rod")
	await _load("field", "from_village")
	await _frames(60)
	var pm = _main.get_node("GameView/GameViewport/PauseMenu/Screen")
	for page in [["items", pm.Page.ITEM, Vector2i(6, 1)], ["equipment", pm.Page.EQUIP, Vector2i(5, 2)]]:
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
		pm.page = page[1]
		pm._eye = -pm.page_dirs[pm.page] * pm.EYE_DIST
		pm.phase = pm.Phase.OPEN
		if page[0] == "items":
			pm.item_cursor = page[2]
		else:
			pm.equip_cursor = page[2]
		await _frames(30)
		await _shot("pause_%s" % page[0])
		await _tap("pause")
		await _secs(0.8)


func _cap_sword() -> void:
	Progress.reset()
	Progress.give_sword("bun")
	Progress.equip_sword("bun")
	await _load("field", "from_village")
	await _frames(60)
	var p := GameManager.player
	await _shot("sword_bun_asleep")
	Progress.set_flag(Progress.SWORD_AWAKE)
	Progress.gear_changed.emit()
	p._set_sword_drawn(true)
	await _frames(20)
	World.area_node.get_node("CameraRig").snap_behind_target()
	p.face_direction(Vector3(1, 0, 0))
	await _frames(20)
	await _shot("sword_bun_awake")


## First person with the sword drawn and Himeko's regalia (its cape) on:
## the bow aimed, then swapped for the Hookshot.
func _cap_fp() -> void:
	Progress.reset()
	Progress.give_vanity("regalia")
	Progress.toggle_vanity("regalia")
	Progress.give_item("hookshot")
	Progress.assign("item_x", "bow")
	Progress.assign("item_y", "hookshot")
	await _load("field", "from_village")
	await _frames(60)
	var p := GameManager.player
	p._set_sword_drawn(true)
	await _frames(10)
	await _shot("fp_0_sword_drawn")
	await _tap("item_x")
	await _secs(0.6)
	await _shot("fp_1_bow")
	p.look_pitch = 0.5
	await _secs(0.4)
	await _shot("fp_2_bow_up")
	await _tap("item_y")
	await _secs(0.5)
	await _shot("fp_3_hookshot")


func _cap_hearts() -> void:
	Progress.reset()
	Progress.max_health = 44
	Progress.magic_max = 96
	Progress.magic = 70
	await _load("field", "from_village")
	await _frames(60)
	var p := GameManager.player
	p.health.max_health = 44
	p.health.health = 31
	p.health.health_changed.emit(31, 44)
	await _frames(10)
	await _shot("hud_22_hearts")
	Progress.max_health = 6
	Progress.magic_max = 48
	Progress.magic = 48
	p.health.max_health = 6
	p.health.health = 6
	p.health.health_changed.emit(6, 6)
	await _frames(10)
	await _shot("hud_3_hearts")
