extends "res://tools/gen_bog_creatures.gd"
## The people and creatures of the fall of Castle Town (built like
## gen_creatures.gd):
##
##   firebuns         Firebuns III, risen king of Batela Fells (the user's
##                    picture, at adult size): long brown hair, layered khaki
##                    plate with flared pauldrons, spikes on the left one, a
##                    red sash and loincloth, a purple cape, the clawed
##                    Gauntlet of Fire on his left hand and a broadsword
##   sapphire_mage    a hooded mage of the Sapphire Order with a crystal staff
##   enemy scenes     the mages, Sapphire Knights and their Warden, charred
##                    Stalfos, fire keese, the Cinder Wyvern, and Firebuns
##                    himself for the last fight
##
## People face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_firebuns()
	_build_mage()
	_castle_scenes()


func _castle_scenes() -> void:
	enemy_scene("sapphire_mage", {"script": "res://scripts/enemies/sapphire_mage.gd", "model": "sapphire_mage", "hp": 4, "floating": true,
		"body": [0.4, 1.8, 0.95], "hurt": [0.5, 2.0, 1.0], "shadow": 0.45,
		"exports": {"target_offset": 2.1, "boomerang_stun": 2.0, "drop_table": 2}})
	enemy_scene("sapphire_knight", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 14,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(0.6, 0.72, 1.35), "start_rate": 1.15}})
	enemy_scene("sapphire_warden", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 20,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(0.42, 0.5, 1.2), "start_rate": 1.3,
			"title_name": "SAPPHIRE WARDEN", "title_epithet": "Jailer of the Sapphire Order"}})
	enemy_scene("charred_stalfos", {"script": "res://scripts/enemies/stalfos.gd", "model": "stalfos", "hp": 8,
		"body": [0.38, 1.8, 0.9], "hurt": [0.48, 1.9, 0.95], "hit": [Vector3(0.7, 1.4, 1.8), Vector3(0, 1.0, -1.3)], "shadow": 0.5,
		"exports": {"target_offset": 1.95, "boomerang_stun": 2.0, "drop_table": 2, "tint": Color(0.7, 0.48, 0.4)}})
	enemy_scene("fire_keese", {"script": "res://scripts/enemies/keese.gd", "model": "keese", "hp": 1, "floating": true,
		"body": [0.25, 0.5, 0.0], "hurt": [0.4, 0.8, 0.0], "hit": [Vector3(0.7, 0.6, 0.7), Vector3(0, 0, 0)], "shadow": 0.3,
		"exports": {"target_offset": 0.3, "boomerang_stun": 4.0, "boomerang_damage": 1, "tint": Color(1.7, 0.85, 0.4)}})
	enemy_scene("cinder_wyvern", {"script": "res://scripts/enemies/corvax.gd", "model": "wyvern", "hp": 12, "floating": true,
		"body": [1.1, 2.2, 0.0], "hurt": [1.5, 3.0, 0.0], "hit": [Vector3(3.0, 1.6, 3.0), Vector3(0, -0.6, -0.5)], "shadow": 2.0,
		"exports": {"target_offset": 0.6, "boomerang_stun": 0.0, "drop_table": 11, "title": "", "music": "", "circle_r": 7.0, "circle_h": 6.0,
			"missile_mesh": "res://assets/models/fire_orb_mesh.tres", "tint": Color(1.5, 0.7, 0.45)}})
	enemy_scene("firebuns", {"script": "res://scripts/enemies/firebuns.gd", "model": "firebuns", "hp": 40,
		"body": [0.45, 2.0, 1.0], "hurt": [0.6, 2.2, 1.05], "hit": [Vector3(1.4, 1.8, 2.6), Vector3(0, 1.0, -1.7)], "shadow": 0.6,
		"exports": {"target_offset": 2.3, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Firebuns III -------------------------------------------------------------------

func _build_firebuns() -> void:
	var SKIN := _c("f6d2a6")
	var SKIN_D := _c("dcb088")
	var ARMOR := _c("a89a6a")
	var ARMOR_L := _c("c8ba84")
	var ARMOR_D := _c("7e7048")
	var RED := _c("a83a30")
	var RED_D := _c("7a2620")
	var CAPE := _c("6a4a8a")
	var CAPE_D := _c("4a3466")
	var UNDER := _c("3a3048")
	var HAIR := _c("8a4e2c")
	var HAIR_D := _c("6a3820")
	var HAIR_L := _c("a8643a")
	var EMBER := _c("ff8a2a")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.14, 0.15, 0.12, UNDER], [-0.04, 0.165, 0.13, UNDER], [0.07, 0.15, 0.12, UNDER]], 10)
		var h := p.k("hard")
		# Tassets: overlapping plates round the hips, flaring out.
		for i in 3:
			var y := 0.02 - i * 0.08
			h.loft([[y - 0.09, 0.2 + i * 0.012, 0.16 + i * 0.01, ARMOR_D], [y, 0.18 + i * 0.01, 0.145 + i * 0.008, ARMOR_L if i == 0 else ARMOR]], 10)
		# The red loincloth hanging long in front, and the sash round the waist.
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(4)), Vector3(0, -0.32, -0.16)))
		h.box(Vector3.ZERO, Vector3(0.2, 0.62, 0.014), RED)
		h.box(Vector3(0, -0.3, 0.0), Vector3(0.2, 0.04, 0.016), RED_D)
		h.pop()
		k.loft([[0.0, 0.17, 0.135, RED], [0.06, 0.168, 0.133, RED_D]], 10)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.14, 0.11, UNDER], [0.1, 0.15, 0.115, UNDER], [0.34, 0.08, 0.07, SKIN_D], [0.38, 0.055, 0.055, SKIN]], 10)
		var h := p.k("hard")
		# The breastplate: broad and ridged, in layered bands.
		h.loft([[0.04, 0.155, 0.12, ARMOR_D], [0.12, 0.17, 0.13, ARMOR], [0.2, 0.19, 0.145, ARMOR_L, Vector2(0, -0.006)],
			[0.27, 0.19, 0.14, ARMOR, Vector2(0, -0.004)], [0.32, 0.15, 0.11, ARMOR_D]], 10)
		for i in 3:
			h.box(Vector3(0, 0.1 + i * 0.07, -0.142 - i * 0.004), Vector3(0.22 - i * 0.02, 0.012, 0.01), ARMOR_D)
		# The red sash over his right shoulder, across to the left hip.
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(32)), Vector3(0.02, 0.18, -0.155)))
		h.box(Vector3.ZERO, Vector3(0.085, 0.5, 0.02), RED)
		h.box(Vector3(0.03, 0.0, -0.005), Vector3(0.02, 0.5, 0.02), RED_D)
		h.pop()
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(32)), Vector3(0.0, 0.2, 0.15)))
		h.box(Vector3.ZERO, Vector3(0.085, 0.5, 0.02), RED_D)
		h.pop()
		# The purple cape, from the shoulders down his back to the calves.
		k.loft([
			[-0.92, 0.25, 0.1, CAPE_D, Vector2(0, 0.14)], [-0.5, 0.23, 0.09, CAPE, Vector2(0, 0.12)],
			[-0.1, 0.21, 0.08, CAPE, Vector2(0, 0.1)], [0.2, 0.2, 0.08, CAPE, Vector2(0, 0.075)],
			[0.33, 0.17, 0.07, CAPE_D, Vector2(0, 0.05)],
		], 10)
		# A gorget round the neck.
		h.loft([[0.3, 0.1, 0.09, ARMOR_D], [0.36, 0.085, 0.078, ARMOR]], 10)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.72, 0.15, 0.42)
	var _sleeve_part := func(p: Parts, side: float) -> void:
		var k := p.k()
		k.loft([[0.06, 0.0, 0.0, UNDER], [0.04, 0.07, 0.07, UNDER], [-0.2, 0.058, 0.058, UNDER], [-0.25, 0.0, 0.0, UNDER]], 7)
		var h := p.k("hard")
		# Three flared pauldron plates, overlapping down the upper arm.
		for i in 3:
			var y := 0.04 - i * 0.07
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-18 * side)), Vector3(0.03 * side, y, 0)))
			h.slab(Vector3(0, 0.03, 0), Vector2(0.15 - i * 0.012, 0.14 - i * 0.01), Vector3(0.05 * side, -0.05, 0), Vector2(0.17 - i * 0.012, 0.16 - i * 0.01), ARMOR_L if i == 0 else ARMOR)
			h.pop()
		# Spikes sweeping up and back off the left pauldron.
		if side < 0.0:
			for i in 4:
				h.push(_aim(Vector3(-0.4, 1.0, 0.5 + i * 0.15), Vector3(-0.06 + i * 0.012, 0.08, 0.04 + i * 0.03)))
				h.prism(Vector3.ZERO, 0.025, Vector3(0, 0.24 - i * 0.03, 0), 0.0, 4, ARMOR_L)
				h.pop()
	var _forearm_part := func(p: Parts, side: float) -> void:
		var h := p.k("hard")
		var big := 1.25 if side < 0.0 else 1.0
		h.loft([[0.03, 0.0, 0.0, ARMOR], [0.01, 0.045 * big, 0.045 * big, ARMOR], [-0.12, 0.05 * big, 0.05 * big, ARMOR_L], [-0.2, 0.06 * big, 0.06 * big, ARMOR_D], [-0.215, 0.0, 0.0, ARMOR_D]], 7)
		if side < 0.0:
			# The Gauntlet of Fire: an ember set in the cuff.
			var g := p.k("glow")
			g.icosa(Vector3(0, -0.12, -0.065), Vector3(0.025, 0.025, 0.015), 0.0, EMBER)
	var _hand_part := func(p: Parts, side: float) -> void:
		var h := p.k("hard")
		h.loft([[0.01, 0.03, 0.03, ARMOR], [-0.03, 0.04, 0.05, ARMOR], [-0.075, 0.035, 0.045, ARMOR_L], [-0.1, 0.0, 0.0, ARMOR_D]], 6)
		if side < 0.0:
			# Hooked claws over the knuckles.
			for i in 3:
				h.push(_aim(Vector3(0, -0.6, -1), Vector3(-0.02 + i * 0.02, -0.08, -0.03)))
				h.prism(Vector3.ZERO, 0.009, Vector3(0, 0.07, 0), 0.0, 4, ARMOR_L)
				h.pop()
	var _thigh_part := func(p: Parts, _side: float) -> void:
		var k := p.k()
		k.loft([[0.05, 0.0, 0.0, UNDER], [0.03, 0.075, 0.08, UNDER], [-0.36, 0.055, 0.06, UNDER], [-0.4, 0.0, 0.0, UNDER]], 7)
		var h := p.k("hard")
		h.loft([[-0.02, 0.082, 0.088, ARMOR_L], [-0.2, 0.07, 0.076, ARMOR], [-0.34, 0.06, 0.066, ARMOR_D]], 7)
		h.icosa(Vector3(0, -0.37, -0.05), Vector3(0.06, 0.06, 0.05), 0.0, ARMOR_L)
	var _shin_part := func(p: Parts, _side: float) -> void:
		var h := p.k("hard")
		h.loft([[0.03, 0.0, 0.0, ARMOR], [0.01, 0.058, 0.062, ARMOR], [-0.12, 0.06, 0.064, ARMOR_L], [-0.32, 0.05, 0.054, ARMOR], [-0.35, 0.0, 0.0, ARMOR_D]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, ARMOR, ARMOR_D, 1.15)
	var _extra_part := func(root: Node3D) -> void:
		# The broadsword in his left (clawed) fist, blade along the fist's -Z.
		_attach(root.get_node(_paths["hand_l"]), "Broadsword", Vector3(0, -0.05, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			h.prism(Vector3(0, -0.14, 0), 0.022, Vector3(0, 0.1, 0), 0.022, 6, _c("4a3a6a"))
			h.icosa(Vector3(0, -0.16, 0), Vector3(0.035, 0.035, 0.035), 0.0, ARMOR_L)
			h.box(Vector3(0, 0.12, 0), Vector3(0.32, 0.05, 0.06), ARMOR_L)
			for sx in [-1.0, 1.0]:
				h.prism(Vector3(0.15 * sx, 0.12, 0), 0.025, Vector3(0.2 * sx, 0.2, 0), 0.0, 4, ARMOR)
			h.slab(Vector3(0, 0.15, 0), Vector2(0.13, 0.025), Vector3(0, 1.05, 0), Vector2(0.11, 0.022), _c("d8dee8"))
			h.slab(Vector3(0, 1.05, 0), Vector2(0.11, 0.022), Vector3(0, 1.22, 0), Vector2(0.01, 0.01), _c("e8eef6"))
			h.box(Vector3(0, 0.6, -0.024), Vector3(0.025, 0.8, 0.004), _c("a8b0c0"))
			h.pop()
		, "sword")
		# The Gauntlet's flame: a glow round the clawed fist (shown when it burns).
		var flame := MeshInstance3D.new()
		flame.name = "GauntletFlame"
		flame.mesh = load(MODEL_DIR + "flame_mesh.tres")
		flame.scale = Vector3(1.6, 1.6, 1.6)
		flame.position = Vector3(0, -0.06, 0)
		flame.visible = false
		flame.set_meta("no_tint", true)
		root.get_node(_paths["hand_l"]).add_child(flame)
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("FirebunsModel", "firebuns.tscn", "face_firebuns", SKIN, SKIN_D, look, _firebuns_anims, 1.12)


func _firebuns_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# The sword held point down at his left side.
	var sword_down := {"shoulder_l": [[0.0, V.call(8, 0, 8)]], "elbow_l": [[0.0, V.call(20, 0, 0)]], "hand_l": [[0.0, V.call(-90, 0, 0)]]}
	var with := func(base: Dictionary, extra: Dictionary) -> Dictionary:
		var d := base.duplicate()
		d.merge(extra, true)
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.4, true, with.call(sword_down, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.835, 0)]],
		"torso": [[0.0, V.call(2, 0, 0)], [1.2, V.call(3, 0, 0)]],
		"head": [[0.0, V.call(-4, 0, 0)]],
		"shoulder_r": [[0.0, V.call(4, 0, -6)]], "elbow_r": [[0.0, V.call(12, 0, 0)]],
		"leg_r": [[0.0, V.call(-3, 0, 5)]], "leg_l": [[0.0, V.call(3, 0, -5)]],
	}), rest)
	_anim(lib, "walk", 1.0, true, with.call(sword_down, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.25, V.call(0, 0.86, 0)], [0.5, V.call(0, 0.84, 0)], [0.75, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.5, V.call(24, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)], [0.5, V.call(-24, 0, 0)]],
		"knee_r": [[0.0, V.call(-10, 0, 0)], [0.25, V.call(-40, 0, 0)], [0.5, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.5, V.call(-10, 0, 0)], [0.75, V.call(-40, 0, 0)]],
		"shoulder_r": [[0.0, V.call(18, 0, -6)], [0.5, V.call(-18, 0, -6)]],
		"torso": [[0.0, V.call(-2, 4, 0)], [0.5, V.call(-2, -4, 0)]],
	}), rest)
	# Speaking: chin up, the right hand turned out in a commanding sweep.
	_anim(lib, "talk", 2.0, true, with.call(sword_down, {
		"head": [[0.0, V.call(6, 0, 0)], [0.6, V.call(2, 8, 0)], [1.3, V.call(4, -6, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)]],
		"shoulder_r": [[0.0, V.call(40, 0, -30)], [0.7, V.call(70, 0, -45)], [1.4, V.call(45, 0, -30)]],
		"elbow_r": [[0.0, V.call(40, 0, 0)], [0.7, V.call(10, 0, 0)], [1.4, V.call(35, 0, 0)]],
		"hand_r": [[0.0, V.call(0, 0, -30)]],
	}), rest)
	# Laughing: head thrown back, shoulders shaking.
	_anim(lib, "laugh", 0.5, true, with.call(sword_down, {
		"head": [[0.0, V.call(28, 0, 0)], [0.25, V.call(22, 0, 0)]],
		"torso": [[0.0, V.call(10, 0, 0)], [0.25, V.call(6, 0, 0)]],
		"shoulder_r": [[0.0, V.call(10, 0, -24)], [0.25, V.call(14, 0, -30)]], "elbow_r": [[0.0, V.call(30, 0, 0)]],
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.25, V.call(0, 0.85, 0)]],
	}), rest)
	# Pointing the broadsword at the hero.
	_anim(lib, "point", 1.6, true, {
		"torso": [[0.0, V.call(0, 20, 0)]], "head": [[0.0, V.call(-2, -18, 0)]],
		"shoulder_l": [[0.0, V.call(88, 0, -4)], [0.8, V.call(90, 0, -4)]], "elbow_l": [[0.0, V.call(4, 0, 0)]], "hand_l": [[0.0, V.call(-4, 0, 0)]],
		"shoulder_r": [[0.0, V.call(8, 0, -10)]], "elbow_r": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(-10, 0, 6)]], "leg_l": [[0.0, V.call(12, 0, -4)]], "knee_l": [[0.0, V.call(-8, 0, 0)]],
	}, rest)
	# The Gauntlet raised high, its fire roaring, the broadsword pointing at
	# the sky from the clawed fist.
	_anim(lib, "raise", 1.0, true, {
		"torso": [[0.0, V.call(8, -6, 0)]], "head": [[0.0, V.call(18, 0, 0)]],
		"shoulder_l": [[0.0, V.call(168, 0, -8)], [0.5, V.call(172, 0, -6)]], "elbow_l": [[0.0, V.call(8, 0, 0)]], "hand_l": [[0.0, V.call(-90, 0, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, -40)]], "elbow_r": [[0.0, V.call(40, 0, 0)]],
		"leg_r": [[0.0, V.call(-6, 0, 8)]], "leg_l": [[0.0, V.call(6, 0, -8)]],
	}, rest)
	# Thrusting the Gauntlet forward to throw fire.
	_anim(lib, "cast", 0.8, false, {
		"torso": [[0.0, V.call(0, 15, 0)], [0.3, V.call(-8, -20, 0)], [0.8, V.call(0, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, 20)], [0.3, V.call(92, 0, 0)], [0.6, V.call(90, 0, 0)], [0.8, V.call(10, 0, 8)]],
		"elbow_l": [[0.0, V.call(80, 0, 0)], [0.3, V.call(2, 0, 0)], [0.8, V.call(20, 0, 0)]],
		"hand_l": [[0.0, V.call(-90, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, 0)], [0.3, V.call(-16, 0, 0)]], "leg_r": [[0.0, V.call(0, 0, 0)], [0.3, V.call(14, 0, 0)]],
	}, rest)
	_anim(lib, "slash_windup", 0.6, false, {
		"torso": [[0.0, V.call(0, 0, 0)], [0.6, V.call(6, 35, 0)]],
		"shoulder_l": [[0.0, V.call(8, 0, 8)], [0.6, V.call(165, 0, 30)]], "elbow_l": [[0.0, V.call(20, 0, 0)], [0.6, V.call(50, 0, 0)]],
		"hand_l": [[0.0, V.call(-90, 0, 0)], [0.6, V.call(30, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-10, 0, 0)]], "leg_r": [[0.0, V.call(0, 0, 0)], [0.6, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "slash", 0.35, false, {
		"torso": [[0.0, V.call(6, 35, 0)], [0.15, V.call(-14, -30, 0)], [0.35, V.call(-10, -25, 0)]],
		"shoulder_l": [[0.0, V.call(165, 0, 30)], [0.15, V.call(40, 0, -10)], [0.35, V.call(30, 0, -10)]],
		"elbow_l": [[0.0, V.call(50, 0, 0)], [0.15, V.call(5, 0, 0)]],
		"hand_l": [[0.0, V.call(30, 0, 0)], [0.15, V.call(-50, 0, 0)], [0.35, V.call(-60, 0, 0)]],
		"leg_l": [[0.0, V.call(-10, 0, 0)], [0.15, V.call(-22, 0, 0)]], "leg_r": [[0.0, V.call(10, 0, 0)], [0.15, V.call(16, 0, 0)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.15, V.call(-14, 0, 0)]],
	}, rest)
	_anim(lib, "recover", 0.7, false, {
		"torso": [[0.0, V.call(-10, -25, 0)], [0.7, V.call(0, 0, 0)]],
		"shoulder_l": [[0.0, V.call(30, 0, -10)], [0.7, V.call(8, 0, 8)]], "elbow_l": [[0.0, V.call(5, 0, 0)], [0.7, V.call(20, 0, 0)]],
		"hand_l": [[0.0, V.call(-60, 0, 0)], [0.7, V.call(-90, 0, 0)]],
	}, rest)
	_anim(lib, "guard", 1.2, true, {
		"torso": [[0.0, V.call(-4, 10, 0)], [0.6, V.call(-1, 12, 0)]], "head": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-3, -2, 0)]],
		"shoulder_l": [[0.0, V.call(60, 30, 20)], [0.6, V.call(63, 30, 20)]], "elbow_l": [[0.0, V.call(70, 0, 0)]], "hand_l": [[0.0, V.call(0, 0, 60)]],
		"shoulder_r": [[0.0, V.call(30, 0, -15)], [0.6, V.call(33, 0, -17)]], "elbow_r": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-12, 0, 8)]], "leg_l": [[0.0, V.call(14, 0, -8)]], "knee_r": [[0.0, V.call(-12, 0, 0)], [0.6, V.call(-15, 0, 0)]], "knee_l": [[0.0, V.call(-12, 0, 0)], [0.6, V.call(-15, 0, 0)]],
		"hips@pos": [[0.0, V.call(0, 0.8, 0)], [0.6, V.call(0, 0.787, 0)]],
	}, rest)
	_anim(lib, "hurt", 0.4, false, with.call(sword_down, {
		"torso": [[0.0, V.call(0, 0, 0)], [0.1, V.call(16, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.1, V.call(20, 0, 0)], [0.4, V.call(0, 0, 0)]],
	}), rest)
	_anim(lib, "stagger", 1.2, true, with.call(sword_down, {
		"torso": [[0.0, V.call(-24, 0, 6)], [0.6, V.call(-20, 0, -4)]], "head": [[0.0, V.call(-10, 0, 8)], [0.6, V.call(-6, 0, -8)]],
		"hips@pos": [[0.0, V.call(0, 0.74, 0)], [0.6, V.call(0, 0.76, 0)]],
		"knee_r": [[0.0, V.call(-30, 0, 0)]], "knee_l": [[0.0, V.call(-24, 0, 0)]], "leg_r": [[0.0, V.call(20, 0, 0)]], "leg_l": [[0.0, V.call(14, 0, 0)]],
		"shoulder_r": [[0.0, V.call(40, 0, -10)]], "elbow_r": [[0.0, V.call(60, 0, 0)]],
	}), rest)
	# Seated on the throne of Haven, sword across his knees.
	_anim(lib, "sit", 3.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.55, 0.05)], [1.5, V.call(0, 0.545, 0.05)]],
		"leg_r": [[0.0, V.call(84, 0, 6)]], "leg_l": [[0.0, V.call(84, 0, -6)]], "knee_r": [[0.0, V.call(-84, 0, 0)]], "knee_l": [[0.0, V.call(-84, 0, 0)]],
		"torso": [[0.0, V.call(-4, 0, 0)]], "head": [[0.0, V.call(-6, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, 10)]], "elbow_l": [[0.0, V.call(40, 0, 0)]], "hand_l": [[0.0, V.call(-10, 70, 0)]],
		"shoulder_r": [[0.0, V.call(36, 0, -12)]], "elbow_r": [[0.0, V.call(46, 0, 0)]],
	}, rest)


# --- Sapphire Order mage -------------------------------------------------------------

## A tall hooded figure in deep-blue robes edged in silver, sapphires at the
## collar, a long staff topped by a blue crystal in the right hand.
func _build_mage() -> void:
	var SKIN := _c("c8b0a0")
	var SKIN_D := _c("a89080")
	var ROBE := _c("2a3a8a")
	var ROBE_L := _c("3a4aa8")
	var ROBE_D := _c("1c2864")
	var TRIM := _c("c8d0e0")
	var GEM := _c("60a8ff")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.8, 0.26, 0.24, ROBE_D], [-0.76, 0.27, 0.25, TRIM], [-0.72, 0.26, 0.24, ROBE], [-0.3, 0.2, 0.18, ROBE_L], [0.06, 0.14, 0.11, ROBE]], 12)
		k.loft([[0.0, 0.145, 0.118, _c("3a3a44")], [0.05, 0.14, 0.113, _c("3a3a44")]], 12)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.13, 0.104, ROBE], [0.12, 0.14, 0.11, ROBE_L], [0.26, 0.15, 0.11, ROBE], [0.34, 0.1, 0.085, ROBE_D], [0.4, 0.07, 0.065, ROBE_D]], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.18, -0.115), Vector3(0.03, 0.34, 0.01), TRIM)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.32, -0.095), Vector3(0.025, 0.025, 0.015), 0.0, GEM)
		# The cowl over the shoulders.
		k.loft([[0.22, 0.2, 0.16, ROBE_D], [0.3, 0.17, 0.14, ROBE], [0.36, 0.11, 0.1, ROBE_D]], 10)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		# The deep hood, pointed at the back, open at the front.
		k.loft([[0.0, 0.13, 0.13, ROBE_D, Vector2(0, 0.025)], [0.12, 0.145, 0.145, ROBE, Vector2(0, 0.02)], [0.25, 0.14, 0.14, ROBE_L, Vector2(0, 0.03)],
			[0.33, 0.1, 0.1, ROBE, Vector2(0, 0.05)], [0.42, 0.0, 0.0, ROBE_D, Vector2(0, 0.09)]], 10)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.04 * sx, 0.15, -0.115), Vector3(0.015, 0.01, 0.006), 0.0, _c("a8e8ff"))
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.06, 0.0, 0.0, ROBE], [0.045, 0.07, 0.07, ROBE], [-0.2, 0.08, 0.08, ROBE_L], [-0.25, 0.0, 0.0, ROBE_D]], 7)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, ROBE], [0.01, 0.07, 0.07, ROBE], [-0.18, 0.09, 0.09, ROBE_L], [-0.2, 0.092, 0.092, TRIM], [-0.21, 0.0, 0.0, ROBE_D]], 7)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, ROBE_D], [0.03, 0.06, 0.065, ROBE_D], [-0.4, 0.0, 0.0, ROBE_D]], 6)
	var _shin_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, ROBE_D], [0.0, 0.045, 0.05, ROBE_D], [-0.35, 0.0, 0.0, ROBE_D]], 6)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, _c("2a2a30"), _c("1a1a20"))
	var _extra_part := func(root: Node3D) -> void:
		_attach(root.get_node(_paths["hand_r"]), "Staff", Vector3(0, -0.05, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			h.prism(Vector3(0, -0.9, 0), 0.02, Vector3(0, 0.75, 0), 0.022, 6, _c("4a3a2a"))
			for i in 3:
				var a := TAU * i / 3.0
				h.prism(Vector3(0, 0.72, 0), 0.015, Vector3(cos(a) * 0.07, 0.92, sin(a) * 0.07), 0.01, 4, TRIM)
			h.pop()
			var g := p.k("glow")
			g.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			g.prism(Vector3(0, 0.78, 0), 0.0, Vector3(0, 0.88, 0), 0.06, 6, GEM)
			g.prism(Vector3(0, 0.88, 0), 0.06, Vector3(0, 1.02, 0), 0.0, 6, _c("b8e0ff"))
			g.pop()
		, "staff")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("SapphireMageModel", "sapphire_mage.tscn", "face_mage", SKIN, SKIN_D, look, _mage_anims, 1.04)


func _mage_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var staff := {"shoulder_r": [[0.0, V.call(20, 0, -8)]], "elbow_r": [[0.0, V.call(60, 0, 0)]], "hand_r": [[0.0, V.call(10, 0, 0)]]}
	var with := func(base: Dictionary, extra: Dictionary) -> Dictionary:
		var d := base.duplicate()
		d.merge(extra, true)
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Hovering a little off the floor, robes swaying.
	_anim(lib, "idle", 2.0, true, with.call(staff, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)], [1.0, V.call(0, 1.08, 0)]],
		"leg_r": [[0.0, V.call(6, 0, 0)]], "leg_l": [[0.0, V.call(10, 0, 0)]], "knee_r": [[0.0, V.call(-10, 0, 0)]], "knee_l": [[0.0, V.call(-14, 0, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, 10)]], "elbow_l": [[0.0, V.call(50, 0, 0)]],
		"head": [[0.0, V.call(-6, 0, 0)]],
	}), rest)
	_anim(lib, "walk", 2.0, true, with.call(staff, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)], [1.0, V.call(0, 1.06, 0)]],
		"torso": [[0.0, V.call(-8, 0, 0)]],
		"leg_r": [[0.0, V.call(20, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)]], "knee_r": [[0.0, V.call(-20, 0, 0)]], "knee_l": [[0.0, V.call(-24, 0, 0)]],
	}), rest)
	# Raising the staff, then thrusting the crystal forward.
	_anim(lib, "cast", 0.8, false, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.4, V.call(8, 0, 0)], [0.55, V.call(-10, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(20, 0, -8)], [0.4, V.call(160, 0, -10)], [0.55, V.call(80, 0, -4)], [0.8, V.call(40, 0, -8)]],
		"elbow_r": [[0.0, V.call(60, 0, 0)], [0.4, V.call(20, 0, 0)], [0.55, V.call(5, 0, 0)]],
		"hand_r": [[0.0, V.call(-80, 0, 0)], [0.4, V.call(-10, 0, 0)], [0.55, V.call(-10, 0, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, 10)], [0.4, V.call(60, 0, 30)], [0.8, V.call(20, 0, 10)]],
		"leg_r": [[0.0, V.call(6, 0, 0)]], "leg_l": [[0.0, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "talk", 1.6, true, with.call(staff, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"head": [[0.0, V.call(4, 0, 0)], [0.8, V.call(0, 6, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, 20)], [0.8, V.call(55, 0, 25)]], "elbow_l": [[0.0, V.call(60, 0, 0)]],
	}), rest)
	_anim(lib, "hurt", 0.4, false, with.call(staff, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.1, V.call(18, 0, 0)], [0.4, V.call(0, 0, 0)]],
	}), rest)
	_anim(lib, "stunned", 0.8, true, with.call(staff, {
		"hips@pos": [[0.0, V.call(0, 0.9, 0)]],
		"torso": [[0.0, V.call(-12, 0, 8)], [0.4, V.call(-12, 0, -8)]], "head": [[0.0, V.call(-10, 0, 10)], [0.4, V.call(-10, 0, -10)]],
	}), rest)
	_anim(lib, "death", 1.0, false, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)], [1.0, V.call(0, 0.3, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [1.0, V.call(-50, 0, 0)]], "head": [[0.0, V.call(0, 0, 0)], [1.0, V.call(-30, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 0)], [1.0, V.call(80, 0, 0)]], "leg_l": [[0.0, V.call(0, 0, 0)], [1.0, V.call(80, 0, 0)]],
	}, rest)
