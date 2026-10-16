extends "res://tools/gen_ch4_creatures.gd"
## The creatures of Beta 1.3.0 (Chapter V, first half, "Firebuns Returns"):
##
##   cinderling      a slug of living magma from Cinderhold, its black crust
##                   cracked with fire (scripts/enemies/cinderling.gd)
##   hollow_king     Harrow, the Hollow King, master of the Barrow of Kings: a
##                   giant in rusted royal plate, a crowned helm with green
##                   fire for a face (scripts/enemies/hollow_king.gd)
##   mara            Mara, the Scourge of Bunsriel (cutscenes for now): tall,
##                   in black spiked plate and a ragged crimson cloak, a horned
##                   iron circlet, a long black war-glaive
##
## and scenes over models made elsewhere: barrow_knight / barrow_champion /
## ember_knight (the Stalfos in risen-knight colors, BarrowKnight), the
## vault_warden (the Tide Knight in Serielye's red and gold) and magmaw (the
## wyrm, in magma). Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_cinderling()
	_build_brute("hollow_king.tscn", "HollowKingModel", 2.5, {
		"skin": _c("8a8478"), "skin_l": _c("a49e90"), "skin_d": _c("666054"), "hide": _c("3a2a3a"),
		"iron": _c("5a5a52"), "iron_l": _c("7a7a6e"), "trim": _c("c8a84a"), "bone": _c("d8d0b8"), "eye": _c("6aff9a"),
		"face": "", "weapon": "greatsword", "stone": false})
	_build_mara()
	var knight_body := {"body": [0.38, 1.8, 0.9], "hurt": [0.48, 1.9, 0.95], "hit": [Vector3(0.8, 1.4, 1.9), Vector3(0, 1.0, -1.3)], "shadow": 0.5}
	enemy_scene("barrow_knight", knight_body.merged({"script": "res://scripts/enemies/barrow_knight.gd", "model": "stalfos", "hp": 8,
		"exports": {"target_offset": 1.95, "boomerang_stun": 1.5, "drop_table": 2, "tint": Color(0.62, 0.7, 0.86), "walk_speed": 1.6}}))
	enemy_scene("barrow_champion", knight_body.merged({"script": "res://scripts/enemies/barrow_knight.gd", "model": "stalfos", "hp": 18,
		"exports": {"target_offset": 1.95, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(1.35, 1.15, 0.7), "slash_damage": 3,
			"title_name": "BARROW CHAMPION", "title_epithet": "First Sword of the Old Kings"}}))
	enemy_scene("ember_knight", knight_body.merged({"script": "res://scripts/enemies/barrow_knight.gd", "model": "stalfos", "hp": 10,
		"exports": {"target_offset": 1.95, "boomerang_stun": 1.0, "drop_table": 2, "tint": Color(1.25, 0.6, 0.42), "slash_damage": 3}}))
	enemy_scene("vault_warden", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 22,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(1.5, 0.78, 0.55), "start_rate": 1.35,
			"title_name": "VAULT WARDEN", "title_epithet": "Serielye's Keeper of the Fire"}})
	enemy_scene("cinderling", {"script": "res://scripts/enemies/cinderling.gd", "model": "cinderling", "hp": 4,
		"body": [0.45, 0.9, 0.5], "hurt": [0.6, 1.0, 0.5], "hit": [Vector3(1.0, 0.8, 1.3), Vector3(0, 0.4, -0.8)], "shadow": 0.6,
		"exports": {"target_offset": 0.7, "boomerang_stun": 2.0, "drop_table": 1}})
	enemy_scene("hollow_king", {"script": "res://scripts/enemies/hollow_king.gd", "model": "hollow_king", "hp": 40,
		"body": [1.1, 3.4, 1.7], "hurt": [1.35, 3.8, 1.9], "hit": [Vector3(4.0, 2.2, 3.0), Vector3(0, 1.2, -2.1)], "shadow": 2.0,
		"exports": {"target_offset": 2.6, "boomerang_stun": 0.0, "drop_table": -1}})
	enemy_scene("magmaw", {"script": "res://scripts/enemies/magmaw.gd", "model": "wyrm", "hp": 16, "floating": true,
		"body": [0.9, 1.8, 0.0], "hurt": [1.25, 2.6, 0.0], "hit": [Vector3(2.2, 1.8, 2.6), Vector3(0, 0, -1.0)], "shadow": 1.6,
		"exports": {"target_offset": 0.8, "boomerang_stun": 0.0, "drop_table": -1}})
	print("gen_ch5_creatures: done")


# --- Cinderling ---------------------------------------------------------------

## A long low slug of black crust over molten orange, glowing cracks along
## its back, two ember eyes on stalks. The body is one joint (it hunches by
## rotating), the head another.
func _build_cinderling() -> void:
	var CRUST := _c("2a2220")
	var CRUST_L := _c("3e3230")
	var MAGMA := Color(1.8, 0.7, 0.25)
	var EYE := Color(2.0, 1.4, 0.5)
	_root = Node3D.new()
	_root.name = "CinderlingModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.28, 0), func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
		k.loft([[0.55, 0.0, 0.0, CRUST], [0.5, 0.12, 0.08, CRUST], [0.3, 0.26, 0.22, CRUST_L], [0.0, 0.3, 0.26, CRUST_L],
			[-0.3, 0.26, 0.22, CRUST], [-0.48, 0.16, 0.12, CRUST], [-0.55, 0.0, 0.0, CRUST]], 9)
		k.pop()
		var g := p.k("glow")
		for i in 6:
			var z := -0.38 + i * 0.15
			g.box(Vector3(0.03 * (1 if i % 2 else -1), 0.22 - absf(z) * 0.18, z), Vector3(0.05, 0.03, 0.12), MAGMA)
		g.box(Vector3(0, 0.0, 0.0), Vector3(0.5, 0.05, 0.9), MAGMA * 0.8)
	)
	_joint(body, "head", "Head", Vector3(0, 0.1, -0.5), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.0, -0.05), Vector3(0.17, 0.14, 0.16), 0.1, CRUST_L)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			k.prism(Vector3(0.07 * sx, 0.08, -0.08), 0.025, Vector3(0.1 * sx, 0.24, -0.12), 0.015, 5, CRUST)
			g.icosa(Vector3(0.1 * sx, 0.26, -0.12), Vector3(0.035, 0.035, 0.035), 0.0, EYE)
		g.box(Vector3(0, -0.04, -0.2), Vector3(0.14, 0.03, 0.02), MAGMA)
	)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.28, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 1.6, true, {
		"body@pos": [[0.0, V.call(0, 0.28, 0)], [0.8, V.call(0, 0.25, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.8, V.call(2, 0, 0)]],
		"head": [[0.0, V.call(0, -10, 0)], [0.8, V.call(6, 10, 0)]],
	}, rest)
	_anim(lib, "walk", 0.8, true, {
		"body@pos": [[0.0, V.call(0, 0.28, 0)], [0.2, V.call(0, 0.32, 0)], [0.4, V.call(0, 0.28, 0)], [0.6, V.call(0, 0.32, 0)]],
		"body": [[0.0, V.call(0, 6, 0)], [0.4, V.call(0, -6, 0)]],
		"head": [[0.0, V.call(0, -8, 0)], [0.4, V.call(0, 8, 0)]],
	}, rest)
	_anim(lib, "attack", 0.6, false, {
		"body@pos": [[0.0, V.call(0, 0.28, 0)], [0.5, V.call(0, 0.4, 0.15)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.5, V.call(-35, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.5, V.call(25, 0, 0)]],
	}, rest)
	_anim(lib, "hurt", 0.3, false, {
		"body": [[0.0, V.call(10, 0, 8)], [0.3, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(-20, 0, 0)], [0.3, V.call(0, 0, 0)]],
	}, rest)
	_anim(lib, "death", 0.6, false, {
		"body@pos": [[0.0, V.call(0, 0.28, 0)], [0.6, V.call(0, 0.08, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 25)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.6, V.call(40, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.8, true, {
		"head": [[0.0, V.call(20, 15, 0)], [0.4, V.call(20, -15, 0)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "cinderling.tscn")


# --- Mara -------------------------------------------------------------------------

## Mara, the Scourge of Bunsriel: built like the other women (_build_woman) at
## 1.15 height. Black plate edged in old bronze, spikes on the pauldrons, a
## ragged crimson cloak to the ankles, black hair cut hard at the brow under a
## horned iron circlet, and a long black war-glaive in her right hand.
func _build_mara() -> void:
	var SKIN := _c("b8b0b8")
	var SKIN_D := _c("8e8690")
	var PLATE := _c("26222a")
	var PLATE_L := _c("3a343e")
	var PLATE_D := _c("16131a")
	var BRONZE := _c("8a6a3a")
	var CLOAK := _c("6a1420")
	var CLOAK_D := _c("440c14")
	var HAIR := _c("141018")
	var HAIR_D := _c("08060a")
	var HAIR_L := _c("2a2230")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.14, 0.15, 0.12, PLATE_D], [-0.04, 0.165, 0.13, PLATE_D], [0.07, 0.15, 0.12, PLATE]], 10)
		var h := p.k("hard")
		for i in 3:
			var y := 0.02 - i * 0.09
			h.loft([[y - 0.1, 0.21 + i * 0.014, 0.17 + i * 0.012, PLATE_D], [y, 0.19 + i * 0.012, 0.15 + i * 0.01, PLATE_L if i == 0 else PLATE]], 10)
		h.loft([[0.0, 0.17, 0.135, BRONZE], [0.05, 0.168, 0.133, BRONZE.darkened(0.2)]], 10)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.14, 0.11, PLATE_D], [0.1, 0.15, 0.115, PLATE_D], [0.34, 0.08, 0.07, SKIN_D], [0.38, 0.055, 0.055, SKIN]], 10)
		var h := p.k("hard")
		h.loft([[0.04, 0.15, 0.12, PLATE_D], [0.12, 0.165, 0.13, PLATE], [0.2, 0.18, 0.14, PLATE_L, Vector2(0, -0.006)],
			[0.27, 0.18, 0.135, PLATE, Vector2(0, -0.004)], [0.32, 0.14, 0.105, PLATE_D]], 10)
		h.box(Vector3(0, 0.2, -0.15), Vector3(0.03, 0.18, 0.02), BRONZE)
		# The ragged cloak, cut into tatters at the hem.
		k.loft([
			[-0.98, 0.27, 0.1, CLOAK_D, Vector2(0, 0.15)], [-0.5, 0.24, 0.09, CLOAK, Vector2(0, 0.12)],
			[-0.1, 0.22, 0.08, CLOAK, Vector2(0, 0.1)], [0.2, 0.2, 0.08, CLOAK, Vector2(0, 0.075)],
			[0.33, 0.17, 0.07, CLOAK_D, Vector2(0, 0.05)],
		], 10)
		for i in 5:
			h.box(Vector3(-0.2 + i * 0.1, -1.02, 0.17), Vector3(0.05, 0.12, 0.02), CLOAK_D)
		h.loft([[0.3, 0.1, 0.09, PLATE_D], [0.36, 0.085, 0.078, PLATE]], 10)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.5, 0.14, 0.3)
		var h := p.k("hard")
		# The horned iron circlet.
		h.loft([[0.24, 0.125, 0.128, PLATE], [0.27, 0.122, 0.126, PLATE_L]], 12, false)
		for sx in [-1.0, 1.0]:
			h.push(_aim(Vector3(0.6 * sx, 1.0, 0.4), Vector3(0.1 * sx, 0.27, 0.02)))
			h.prism(Vector3.ZERO, 0.03, Vector3(0, 0.2, 0), 0.0, 5, PLATE_L)
			h.pop()
	var _sleeve_part := func(p: Parts, side: float) -> void:
		var k := p.k()
		k.loft([[0.06, 0.0, 0.0, PLATE_D], [0.04, 0.07, 0.07, PLATE_D], [-0.2, 0.058, 0.058, PLATE_D], [-0.25, 0.0, 0.0, PLATE_D]], 7)
		var h := p.k("hard")
		for i in 2:
			var y := 0.04 - i * 0.08
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-20 * side)), Vector3(0.03 * side, y, 0)))
			h.slab(Vector3(0, 0.03, 0), Vector2(0.16 - i * 0.015, 0.15 - i * 0.012), Vector3(0.05 * side, -0.05, 0), Vector2(0.18 - i * 0.015, 0.17 - i * 0.012), PLATE_L if i == 0 else PLATE)
			h.pop()
		for i in 3:
			h.push(_aim(Vector3(0.5 * side, 1.0, 0.2 * (i - 1)), Vector3(0.08 * side, 0.08, -0.05 + i * 0.05)))
			h.prism(Vector3.ZERO, 0.022, Vector3(0, 0.16, 0), 0.0, 4, BRONZE)
			h.pop()
	var _forearm_part := func(p: Parts, _side: float) -> void:
		var h := p.k("hard")
		h.loft([[0.03, 0.0, 0.0, PLATE], [0.01, 0.045, 0.045, PLATE], [-0.12, 0.05, 0.05, PLATE_L], [-0.2, 0.058, 0.058, PLATE_D], [-0.215, 0.0, 0.0, PLATE_D]], 7)
	var _hand_part := func(p: Parts, _side: float) -> void:
		var h := p.k("hard")
		h.loft([[0.01, 0.03, 0.03, PLATE], [-0.03, 0.04, 0.05, PLATE], [-0.075, 0.035, 0.045, PLATE_L], [-0.1, 0.0, 0.0, PLATE_D]], 6)
	var _thigh_part := func(p: Parts, _side: float) -> void:
		var k := p.k()
		k.loft([[0.05, 0.0, 0.0, PLATE_D], [0.03, 0.075, 0.08, PLATE_D], [-0.36, 0.055, 0.06, PLATE_D], [-0.4, 0.0, 0.0, PLATE_D]], 7)
		var h := p.k("hard")
		h.loft([[-0.02, 0.082, 0.088, PLATE_L], [-0.2, 0.07, 0.076, PLATE], [-0.34, 0.06, 0.066, PLATE_D]], 7)
	var _shin_part := func(p: Parts, _side: float) -> void:
		var h := p.k("hard")
		h.loft([[0.03, 0.0, 0.0, PLATE], [0.01, 0.058, 0.062, PLATE], [-0.12, 0.06, 0.064, PLATE_L], [-0.32, 0.05, 0.054, PLATE], [-0.35, 0.0, 0.0, PLATE_D]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, PLATE, PLATE_D, 1.15)
	var _extra_part := func(root: Node3D) -> void:
		# The war-glaive in her right fist: a long black haft, a broad curved
		# blade of dark steel at the top, a bronze spike at the foot.
		_attach(root.get_node(_paths["hand_r"]), "Glaive", Vector3(0, -0.05, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			h.prism(Vector3(0, -0.9, 0), 0.022, Vector3(0, 1.1, 0), 0.022, 6, _c("1a161c"))
			h.prism(Vector3(0, -0.9, 0), 0.03, Vector3(0, -1.08, 0), 0.0, 4, BRONZE)
			h.box(Vector3(0, 1.12, 0), Vector3(0.12, 0.06, 0.06), BRONZE)
			h.slab(Vector3(0, 1.15, 0), Vector2(0.16, 0.02), Vector3(0.05, 1.6, 0), Vector2(0.09, 0.016), _c("4a4a56"))
			h.slab(Vector3(0.05, 1.6, 0), Vector2(0.09, 0.016), Vector3(0.12, 1.78, 0), Vector2(0.01, 0.01), _c("5a5a66"))
			h.pop()
		, "glaive")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("MaraModel", "mara.tscn", "face_mara", SKIN, SKIN_D, look, _mara_anims, 1.15)


func _mara_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# The glaive held upright at her right side, its foot on the ground.
	var glaive_up := {"shoulder_r": [[0.0, V.call(20, 0, 12)]], "elbow_r": [[0.0, V.call(60, 0, 0)]], "hand_r": [[0.0, V.call(-60, 0, 0)]]}
	var with := func(base: Dictionary, extra: Dictionary) -> Dictionary:
		var d := base.duplicate()
		d.merge(extra, true)
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.6, true, with.call(glaive_up, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.3, V.call(0, 0.835, 0)]],
		"torso": [[0.0, V.call(2, 0, 0)], [1.3, V.call(3, 0, 0)]], "head": [[0.0, V.call(-4, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, -8)]], "elbow_l": [[0.0, V.call(14, 0, 0)]],
		"leg_r": [[0.0, V.call(-3, 0, 6)]], "leg_l": [[0.0, V.call(3, 0, -6)]],
	}), rest)
	_anim(lib, "walk", 1.1, true, with.call(glaive_up, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.275, V.call(0, 0.86, 0)], [0.55, V.call(0, 0.84, 0)], [0.825, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-22, 0, 0)], [0.55, V.call(22, 0, 0)]], "leg_l": [[0.0, V.call(22, 0, 0)], [0.55, V.call(-22, 0, 0)]],
		"knee_r": [[0.0, V.call(-10, 0, 0)], [0.275, V.call(-38, 0, 0)], [0.55, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.55, V.call(-10, 0, 0)], [0.825, V.call(-38, 0, 0)]],
		"shoulder_l": [[0.0, V.call(16, 0, -8)], [0.55, V.call(-16, 0, -8)]],
	}), rest)
	_anim(lib, "talk", 2.2, true, with.call(glaive_up, {
		"head": [[0.0, V.call(4, 0, 0)], [0.8, V.call(0, 8, 0)], [1.5, V.call(2, -6, 0)]],
		"shoulder_l": [[0.0, V.call(30, 0, -26)], [0.8, V.call(55, 0, -40)], [1.6, V.call(35, 0, -26)]],
		"elbow_l": [[0.0, V.call(40, 0, 0)], [0.8, V.call(10, 0, 0)], [1.6, V.call(35, 0, 0)]],
	}), rest)
	# Raising the glaive high, calling the dead up.
	_anim(lib, "raise", 1.2, true, {
		"torso": [[0.0, V.call(8, 6, 0)]], "head": [[0.0, V.call(16, 0, 0)]],
		"shoulder_r": [[0.0, V.call(168, 0, 8)], [0.6, V.call(172, 0, 6)]], "elbow_r": [[0.0, V.call(8, 0, 0)]], "hand_r": [[0.0, V.call(-90, 0, 0)]],
		"shoulder_l": [[0.0, V.call(50, 0, -50)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(-6, 0, 8)]], "leg_l": [[0.0, V.call(6, 0, -8)]],
	}, rest)
	# The glaive leveled at the hero.
	_anim(lib, "point", 1.6, true, {
		"torso": [[0.0, V.call(0, -20, 0)]], "head": [[0.0, V.call(-2, 18, 0)]],
		"shoulder_r": [[0.0, V.call(80, 0, 6)], [0.8, V.call(82, 0, 6)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "hand_r": [[0.0, V.call(-10, 0, 0)]],
		"shoulder_l": [[0.0, V.call(8, 0, -10)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
		"leg_l": [[0.0, V.call(-10, 0, -6)]], "leg_r": [[0.0, V.call(12, 0, 4)]], "knee_r": [[0.0, V.call(-8, 0, 0)]],
	}, rest)
	# Beta 1.4.0, her fight (Mara): the glaive across her body (guard), drawn
	# back to the right (windup), a wide cut right to left (sweep), a lunge
	# (thrust), brought down overhead (slam), reeling (stagger), down on one
	# knee (kneel).
	_anim(lib, "guard", 1.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0)], [0.6, V.call(0, 0.79, 0)]],
		"torso": [[0.0, V.call(6, -18, 0)]], "head": [[0.0, V.call(-4, 16, 0)]],
		"shoulder_r": [[0.0, V.call(55, 30, 10)]], "elbow_r": [[0.0, V.call(60, 0, 0)]], "hand_r": [[0.0, V.call(-40, 0, -50)]],
		"shoulder_l": [[0.0, V.call(60, -30, -10)]], "elbow_l": [[0.0, V.call(60, 0, 0)]],
		"leg_r": [[0.0, V.call(14, 0, 8)]], "leg_l": [[0.0, V.call(-16, 0, -8)]], "knee_r": [[0.0, V.call(-18, 0, 0)]], "knee_l": [[0.0, V.call(-10, 0, 0)]],
	}, rest)
	_anim(lib, "windup", 0.7, false, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0)]],
		"torso": [[0.0, V.call(6, -18, 0)], [0.5, V.call(0, -50, 0)]], "head": [[0.0, V.call(-4, 16, 0)], [0.5, V.call(0, 40, 0)]],
		"shoulder_r": [[0.0, V.call(55, 30, 10)], [0.5, V.call(70, -10, 70)]], "elbow_r": [[0.0, V.call(60, 0, 0)], [0.5, V.call(20, 0, 0)]], "hand_r": [[0.0, V.call(-40, 0, -50)], [0.5, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(60, -30, -10)], [0.5, V.call(30, 0, -30)]], "elbow_l": [[0.0, V.call(60, 0, 0)], [0.5, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(14, 0, 8)]], "leg_l": [[0.0, V.call(-16, 0, -8)]], "knee_r": [[0.0, V.call(-18, 0, 0)]],
	}, rest)
	_anim(lib, "sweep", 0.5, false, {
		"hips@pos": [[0.0, V.call(0, 0.78, 0)]],
		"torso": [[0.0, V.call(0, -50, 0)], [0.22, V.call(-10, 40, 0)], [0.5, V.call(-6, 45, 0)]],
		"shoulder_r": [[0.0, V.call(80, 0, 70)], [0.22, V.call(80, 0, -10)], [0.5, V.call(70, 0, -20)]], "elbow_r": [[0.0, V.call(20, 0, 0)]], "hand_r": [[0.0, V.call(-90, 0, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, -30)]], "elbow_l": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-15, 0, 8)]], "leg_l": [[0.0, V.call(20, 0, -8)]], "knee_l": [[0.0, V.call(-30, 0, 0)]],
	}, rest)
	_anim(lib, "thrust", 0.5, false, {
		"hips@pos": [[0.0, V.call(0, 0.76, 0)]],
		"torso": [[0.0, V.call(14, -24, 0)]], "head": [[0.0, V.call(-10, 22, 0)]],
		"shoulder_r": [[0.0, V.call(86, 0, 4)]], "elbow_r": [[0.0, V.call(6, 0, 0)]], "hand_r": [[0.0, V.call(-6, 0, 0)]],
		"shoulder_l": [[0.0, V.call(70, 0, -10)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(40, 0, 6)]], "knee_r": [[0.0, V.call(-40, 0, 0)]], "leg_l": [[0.0, V.call(-30, 0, -6)]], "knee_l": [[0.0, V.call(-10, 0, 0)]],
	}, rest)
	_anim(lib, "slam", 0.45, false, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0)], [0.2, V.call(0, 0.7, 0)]],
		"torso": [[0.0, V.call(-10, 0, 0)], [0.15, V.call(35, 0, 0)]], "head": [[0.0, V.call(10, 0, 0)], [0.15, V.call(-20, 0, 0)]],
		"shoulder_r": [[0.0, V.call(170, 0, 8)], [0.15, V.call(70, 0, 8)]], "elbow_r": [[0.0, V.call(8, 0, 0)]], "hand_r": [[0.0, V.call(-90, 0, 0)], [0.15, V.call(-40, 0, 0)]],
		"shoulder_l": [[0.0, V.call(160, 0, -8)], [0.15, V.call(70, 0, -8)]], "elbow_l": [[0.0, V.call(10, 0, 0)]],
		"leg_r": [[0.0, V.call(20, 0, 8)]], "knee_r": [[0.0, V.call(-30, 0, 0)]], "leg_l": [[0.0, V.call(-20, 0, -8)]],
	}, rest)
	_anim(lib, "stagger", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0.04)], [0.3, V.call(0, 0.78, 0.06)]],
		"torso": [[0.0, V.call(-22, 18, 8)], [0.3, V.call(-26, 14, 10)]], "head": [[0.0, V.call(-18, 0, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, 50)]], "elbow_r": [[0.0, V.call(20, 0, 0)]], "hand_r": [[0.0, V.call(-30, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, -50)]], "elbow_l": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-20, 0, 8)]], "leg_l": [[0.0, V.call(10, 0, -10)]], "knee_r": [[0.0, V.call(-20, 0, 0)]],
	}, rest)
	_anim(lib, "kneel", 1.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.46, 0.05)]],
		"torso": [[0.0, V.call(18, 0, 0)], [0.6, V.call(20, 0, 2)]], "head": [[0.0, V.call(24, 0, 0)]],
		"shoulder_r": [[0.0, V.call(60, 0, 10)]], "elbow_r": [[0.0, V.call(50, 0, 0)]], "hand_r": [[0.0, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, -20)]], "elbow_l": [[0.0, V.call(40, 0, 0)]],
		"leg_r": [[0.0, V.call(80, 0, 4)]], "knee_r": [[0.0, V.call(-95, 0, 0)]], "leg_l": [[0.0, V.call(-5, 0, -4)]], "knee_l": [[0.0, V.call(-90, 0, 0)]],
	}, rest)
	_anim(lib, "laugh", 0.5, true, with.call(glaive_up, {
		"head": [[0.0, V.call(24, 0, 0)], [0.25, V.call(18, 0, 0)]],
		"torso": [[0.0, V.call(8, 0, 0)], [0.25, V.call(5, 0, 0)]],
	}), rest)
