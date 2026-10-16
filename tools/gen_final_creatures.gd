extends "res://tools/gen_castle_creatures.gd"
## Characters and creatures for Beta 1.5.0 ("The Astral Rift", the end of
## Chapter V):
##   velloran        ARCHMAGUS VELLORAN, master of the Sapphire Order: the
##                   mage's frame in white and gold, a tall sapphire crown of a
##                   hood, a great staff (model + boss scene; velloran.gd)
##   serielye        SERIELYE, goddess of destruction and balance, from the
##                   user's art: long silver hair over one red eye, a golden
##                   star halo, ram's horns, a navy cape, a brown tunic with a
##                   red bow, dark-red stockings, black boots, a long thin sword
##   firebuns_final  FIREBUNS III for the last battle (firebuns_final.gd), on
##                   his own model
##   shadow_hand     a hand of Denangdyn's shadow (phase 3; shadow_hand.gd)
## It extends the castle generator for the Sapphire mage's animations.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_velloran()
	_build_serielye()
	_build_shadow_hand()
	_build_all_folk()
	enemy_scene("velloran", {"script": "res://scripts/enemies/velloran.gd", "model": "velloran", "hp": 28, "floating": true,
		"body": [0.45, 2.0, 1.0], "hurt": [0.6, 2.2, 1.05], "shadow": 0.55,
		"exports": {"target_offset": 2.3, "boomerang_stun": 0.0, "drop_table": -1}})
	enemy_scene("firebuns_final", {"script": "res://scripts/enemies/firebuns_final.gd", "model": "firebuns", "hp": 60,
		"body": [0.42, 2.0, 1.0], "hurt": [0.55, 2.2, 1.05], "hit": [Vector3(3.0, 1.8, 2.6), Vector3(0, 1.0, -1.6)], "shadow": 0.6,
		"exports": {"target_offset": 2.0, "boomerang_stun": 0.0, "drop_table": -1}})
	enemy_scene("shadow_hand", {"script": "res://scripts/enemies/shadow_hand.gd", "model": "shadow_hand", "hp": 6, "floating": true,
		"body": [0.6, 1.2, 0.6], "hurt": [0.8, 1.6, 0.6], "hit": [Vector3(2.4, 1.2, 2.4), Vector3(0, 0.3, 0)], "shadow": 1.2,
		"exports": {"target_offset": 0.8, "boomerang_stun": 0.0, "drop_table": -1}})
	print("gen_final_creatures: done")


# --- Velloran --------------------------------------------------------------------

## The Archmagus: the Order's robes made white and gold, sapphires down the
## front, a tall pointed crown of a hood set with a great gem, and a staff
## taller than he is, crowned with a sapphire the size of a fist.
func _build_velloran() -> void:
	var SKIN := _c("d8c0b0")
	var SKIN_D := _c("b8a090")
	var ROBE := _c("e8eaf4")
	var ROBE_L := _c("ffffff")
	var ROBE_D := _c("b4b8cc")
	var BLUE := _c("2a3a8a")
	var GOLD := _c("d8b050")
	var GEM := _c("4a90ff")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.82, 0.28, 0.26, BLUE], [-0.78, 0.29, 0.27, GOLD], [-0.74, 0.28, 0.26, ROBE], [-0.3, 0.21, 0.19, ROBE_L], [0.06, 0.15, 0.12, ROBE]], 12)
		k.loft([[0.0, 0.155, 0.125, BLUE], [0.05, 0.15, 0.12, BLUE]], 12)
		var h := p.k("hard")
		h.box(Vector3(0, -0.38, -0.2), Vector3(0.08, 0.76, 0.01), BLUE)
		h.box(Vector3(0, -0.38, -0.205), Vector3(0.02, 0.76, 0.01), GOLD)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.14, 0.11, ROBE], [0.12, 0.15, 0.115, ROBE_L], [0.26, 0.16, 0.115, ROBE], [0.34, 0.11, 0.09, ROBE_D], [0.4, 0.075, 0.07, ROBE_D]], 10)
		# A mantle of the Order's blue over the shoulders, gold-edged.
		k.loft([[0.2, 0.22, 0.17, BLUE], [0.27, 0.2, 0.16, BLUE], [0.33, 0.15, 0.13, GOLD], [0.37, 0.1, 0.095, BLUE]], 12)
		var h := p.k("hard")
		h.box(Vector3(0, 0.18, -0.12), Vector3(0.04, 0.34, 0.01), GOLD)
		var g := p.k("glow")
		for i in 3:
			g.icosa(Vector3(0, 0.08 + i * 0.1, -0.124), Vector3(0.022, 0.022, 0.012), 0.0, GEM)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		# The hood rises into a tall crown, banded in gold.
		k.loft([[0.0, 0.135, 0.135, ROBE_D, Vector2(0, 0.025)], [0.12, 0.15, 0.15, ROBE, Vector2(0, 0.02)], [0.25, 0.145, 0.145, ROBE_L, Vector2(0, 0.025)],
			[0.33, 0.12, 0.12, GOLD, Vector2(0, 0.03)], [0.36, 0.115, 0.115, BLUE, Vector2(0, 0.03)], [0.56, 0.0, 0.0, BLUE, Vector2(0, 0.06)]], 10)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.38, -0.115), Vector3(0.03, 0.04, 0.015), 0.0, GEM)
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.04 * sx, 0.15, -0.118), Vector3(0.015, 0.01, 0.006), 0.0, _c("c8f0ff"))
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.06, 0.0, 0.0, ROBE], [0.045, 0.075, 0.075, ROBE], [-0.2, 0.09, 0.09, ROBE_L], [-0.25, 0.0, 0.0, ROBE_D]], 7)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, ROBE], [0.01, 0.075, 0.075, ROBE], [-0.17, 0.1, 0.1, ROBE_L], [-0.19, 0.102, 0.102, GOLD], [-0.21, 0.0, 0.0, ROBE_D]], 7)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, ROBE_D], [0.03, 0.06, 0.065, ROBE_D], [-0.4, 0.0, 0.0, ROBE_D]], 6)
	var _shin_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, ROBE_D], [0.0, 0.045, 0.05, ROBE_D], [-0.35, 0.0, 0.0, ROBE_D]], 6)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, _c("e0d8c0"), _c("a89870"))
	var _extra_part := func(root: Node3D) -> void:
		_attach(root.get_node(_paths["hand_r"]), "Staff", Vector3(0, -0.05, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			h.prism(Vector3(0, -1.0, 0), 0.024, Vector3(0, 0.85, 0), 0.026, 6, _c("e8e0c8"))
			for y in [-0.6, 0.0, 0.5]:
				h.prism(Vector3(0, y, 0), 0.032, Vector3(0, y + 0.04, 0), 0.032, 6, GOLD)
			for i in 4:
				var a := TAU * i / 4.0
				h.prism(Vector3(0, 0.82, 0), 0.016, Vector3(cos(a) * 0.1, 1.06, sin(a) * 0.1), 0.01, 4, GOLD)
			h.pop()
			var g := p.k("glow")
			g.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			g.prism(Vector3(0, 0.88, 0), 0.0, Vector3(0, 1.0, 0), 0.085, 8, GEM)
			g.prism(Vector3(0, 1.0, 0), 0.085, Vector3(0, 1.18, 0), 0.0, 8, _c("b8e0ff"))
			g.pop()
		, "staff")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("VelloranModel", "velloran.tscn", "face_mage", SKIN, SKIN_D, look, _mage_anims, 1.14)


# --- Serielye --------------------------------------------------------------------

func _build_serielye() -> void:
	var SKIN := _c("f4e6de")
	var SKIN_D := _c("dcc8bc")
	var HAIR := _c("b8bcc8")
	var HAIR_D := _c("8a8e9c")
	var HAIR_L := _c("e0e2ea")
	var TUNIC := _c("7a5232")
	var TUNIC_L := _c("94683e")
	var TUNIC_D := _c("5a3a22")
	var CAPE := _c("1e2a5a")
	var CAPE_D := _c("121a3a")
	var BOW := _c("b0182a")
	var SHORTS := _c("16141a")
	var STOCK := _c("6a1420")
	var STOCK_D := _c("4a0c14")
	var BOOT := _c("1a181c")
	var BOOT_L := _c("34303a")
	var HORN := _c("8a6e48")
	var HORN_D := _c("5a4630")
	var GOLD := _c("e8c050")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		# Black shorts under the tunic's hem.
		k.loft([[-0.16, 0.15, 0.12, SHORTS], [-0.04, 0.15, 0.12, SHORTS], [0.07, 0.13, 0.105, TUNIC]], 12)
		# The tunic's hem, falling to the top of the thigh.
		k.loft([[-0.12, 0.175, 0.15, TUNIC_D], [-0.08, 0.17, 0.145, TUNIC], [0.0, 0.15, 0.125, TUNIC_L], [0.07, 0.135, 0.11, TUNIC]], 12, false)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.13, 0.104, TUNIC], [0.12, 0.134, 0.104, TUNIC_L], [0.22, 0.146, 0.11, TUNIC], [0.3, 0.13, 0.095, TUNIC_D],
			[0.34, 0.07, 0.062, SKIN_D], [0.38, 0.05, 0.05, SKIN]], 10)
		# The cape's high collar round the shoulders.
		k.loft([[0.24, 0.18, 0.15, CAPE_D], [0.31, 0.17, 0.14, CAPE], [0.38, 0.09, 0.085, CAPE], [0.42, 0.075, 0.07, CAPE_D]], 12, false)
		# The red ribbon bow at her collar, two tails hanging.
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(30.0 * sx)), Vector3(0.025 * sx, 0.27, -0.112)))
			h.box(Vector3.ZERO, Vector3(0.045, 0.026, 0.012), BOW)
			h.pop()
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-12.0 * sx)), Vector3(0.012 * sx, 0.2, -0.114)))
			h.box(Vector3.ZERO, Vector3(0.012, 0.12, 0.008), BOW)
			h.pop()
		h.box(Vector3(0, 0.27, -0.116), Vector3(0.018, 0.02, 0.012), BOW.darkened(0.2))
		# The cross pendant at the throat.
		var g := p.k("glow")
		g.box(Vector3(0, 0.33, -0.07), Vector3(0.008, 0.04, 0.006), GOLD)
		g.box(Vector3(0, 0.338, -0.07), Vector3(0.026, 0.008, 0.006), GOLD)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# Long hair down her back, past the shoulder blades, and the locks.
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.42, 0.15, 0.24)
		# The heavy side fringe swept down over one eye (over the painted
		# fringe on the face texture), tapering to a point at the cheek.
		k.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(16)) * Basis(Vector3.RIGHT, deg_to_rad(-12)), Vector3(-0.04, 0.27, -0.108)))
		k.loft([[-0.15, 0.0, 0.0, HAIR_D], [-0.12, 0.022, 0.01, HAIR], [-0.06, 0.036, 0.013, HAIR_L], [0.0, 0.042, 0.015, HAIR], [0.05, 0.036, 0.014, HAIR_D]], 6)
		k.pop()
		# Ram's horns, curling up, back and round from the crown.
		var hk := p.k("hard")
		for sx in [-1.0, 1.0]:
			var base := Vector3(0.075 * sx, 0.29, -0.01)
			var prev := base
			var n := 10
			var r0 := 0.075
			for i in n:
				var th := float(i + 1) / n * 1.7 * PI
				var r := lerpf(r0, 0.03, float(i + 1) / n)
				var pt := base + Vector3(sx * 0.07 * float(i + 1) / n, r * sin(th), r0 - r * cos(th))
				var w0 := lerpf(0.03, 0.008, float(i) / n)
				var w1 := lerpf(0.03, 0.008, float(i + 1) / n)
				hk.prism(prev, w0, pt, w1, 6, HORN if i % 2 == 0 else HORN_D)
				prev = pt
		# Pointed ears.
		for sx in [-1.0, 1.0]:
			k.prism(Vector3(0.112 * sx, 0.15, 0.0), 0.018, Vector3(0.17 * sx, 0.19, 0.03), 0.0, 4, SKIN)
		# The golden halo, a ring with an eight-pointed star of pale blue in it.
		var g := p.k("glow")
		# Tilted back toward the viewer, as she is drawn.
		var hc := Vector3(0, 0.43, 0.06)
		var tilt := Basis(Vector3.RIGHT, deg_to_rad(-32))
		for i in 16:
			var a0 := TAU * i / 16.0
			var a1 := TAU * (i + 1) / 16.0
			g.prism(hc + tilt * Vector3(cos(a0) * 0.13, 0, sin(a0) * 0.13), 0.009, hc + tilt * Vector3(cos(a1) * 0.13, 0, sin(a1) * 0.13), 0.009, 4, GOLD)
		for i in 8:
			var a := TAU * i / 8.0
			var rr := 0.12 if i % 2 == 0 else 0.07
			g.prism(hc, 0.016, hc + tilt * Vector3(cos(a) * rr, 0, sin(a) * rr), 0.0, 4, _c("a8c8ff") if i % 2 == 0 else _c("e0ecff"))
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, TUNIC], [0.045, 0.062, 0.062, TUNIC], [-0.03, 0.068, 0.068, TUNIC_L],
			[-0.1, 0.06, 0.06, TUNIC_D], [-0.11, 0.04, 0.04, SKIN], [-0.22, 0.036, 0.036, SKIN], [-0.25, 0.0, 0.0, SKIN_D],
		], 7)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.16, 0.029, 0.029, SKIN], [-0.21, 0.026, 0.026, SKIN_D], [-0.22, 0.0, 0.0, SKIN_D]], 7)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, SKIN], [0.03, 0.064, 0.068, SKIN], [-0.16, 0.06, 0.064, SKIN],
			[-0.17, 0.062, 0.066, STOCK_D], [-0.2, 0.06, 0.064, STOCK], [-0.36, 0.047, 0.05, STOCK], [-0.4, 0.0, 0.0, STOCK]], 7)
	var _shin_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, STOCK], [0.01, 0.046, 0.05, STOCK], [-0.08, 0.042, 0.046, STOCK],
			[-0.1, 0.05, 0.054, BOOT_L], [-0.12, 0.048, 0.052, BOOT], [-0.33, 0.04, 0.044, BOOT], [-0.35, 0.0, 0.0, BOOT]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT_L, 1.05)
	var _extra_part := func(root: Node3D) -> void:
		# The navy cape from the shoulders almost to the floor, open at the front.
		# Two panels hang from the shoulders behind the arms and meet at the
		# back, so the front stays open on the tunic (as in the art).
		_attach(root.get_node(_paths["torso"]), "Cape", Vector3(0, 0.33, 0.0), func(p: Parts) -> void:
			var c := p.k("hard")
			var rows := [[0.02, 0.17, 0.02], [-0.2, 0.22, 0.06], [-0.5, 0.27, 0.1], [-0.8, 0.31, 0.13], [-1.12, 0.35, 0.16]]
			var segs := 8
			for ri in rows.size() - 1:
				var r0: Array = rows[ri]
				var r1: Array = rows[ri + 1]
				for si in segs:
					# Round the back from one shoulder to the other (not the front).
					var a0 := lerpf(-PI * 0.62, PI * 0.62, float(si) / segs)
					var a1 := lerpf(-PI * 0.62, PI * 0.62, float(si + 1) / segs)
					var q := func(row: Array, a: float) -> Vector3:
						return Vector3(sin(a) * float(row[1]), float(row[0]), cos(a) * (float(row[1]) * 0.62 + float(row[2])))
					var p00: Vector3 = q.call(r0, a0)
					var p01: Vector3 = q.call(r0, a1)
					var p10: Vector3 = q.call(r1, a0)
					var p11: Vector3 = q.call(r1, a1)
					var col := CAPE if (si + ri) % 2 == 0 else CAPE_D
					c.face_dir([p00, p01, p11, p10], col, Vector3(sin((a0 + a1) * 0.5), 0, cos((a0 + a1) * 0.5)))
					c.face_dir([p01, p00, p10, p11], CAPE_D.darkened(0.3), -Vector3(sin((a0 + a1) * 0.5), 0, cos((a0 + a1) * 0.5)))
		)
		# The long, thin sword in her right hand, point down.
		_attach(root.get_node(_paths["hand_r"]), "Sword", Vector3(0, -0.06, -0.01), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.3)), Vector3.ZERO))
			h.loft([[-1.0, 0.0, 0.0, _c("c8d0d8")], [-0.94, 0.016, 0.016, _c("dce4ea")], [-0.05, 0.02, 0.02, _c("eef2f6")], [0.0, 0.02, 0.02, _c("b8c0c8")]], 4)
			h.pop()
			h.box(Vector3(0, 0.0, 0), Vector3(0.16, 0.022, 0.03), _c("1a1a1e"))
			h.prism(Vector3(0, 0.01, 0), 0.016, Vector3(0, 0.13, 0), 0.015, 6, _c("2a2026"))
			h.prism(Vector3(0, 0.13, 0), 0.02, Vector3(0, 0.15, 0), 0.0, 6, _c("1a1a1e"))
		, "sword")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part,
		"hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("SerielyeModel", "serielye.tscn", "face_serielye", SKIN, SKIN_D, look, _serielye_anims, 1.1)


func _serielye_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# The sword held low at her right side, point to the ground.
	var sword_low := {"shoulder_r": [[0.0, V.call(6, 0, -12)]], "elbow_r": [[0.0, V.call(14, 0, 0)]], "hand_r": [[0.0, V.call(-70, 0, 20)]]}
	var with := func(base: Dictionary, extra: Dictionary) -> Dictionary:
		var d := base.duplicate()
		d.merge(extra, true)
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Hanging a hand's breadth above the ground, utterly still but for the
	# slow rise and fall, her left arm loose.
	_anim(lib, "idle", 4.0, true, with.call(sword_low, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)], [2.0, V.call(0, 0.98, 0)]],
		"leg_r": [[0.0, V.call(4, 0, 2)]], "leg_l": [[0.0, V.call(8, 0, -2)]], "knee_r": [[0.0, V.call(-8, 0, 0)]], "knee_l": [[0.0, V.call(-14, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, 12)]], "elbow_l": [[0.0, V.call(10, 0, 0)]],
		"head": [[0.0, V.call(-4, 0, 0)], [2.0, V.call(-6, 0, 0)]],
	}), rest)
	_anim(lib, "talk", 2.4, true, with.call(sword_low, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)], [1.2, V.call(0, 0.97, 0)]],
		"leg_r": [[0.0, V.call(4, 0, 2)]], "leg_l": [[0.0, V.call(8, 0, -2)]], "knee_r": [[0.0, V.call(-8, 0, 0)]], "knee_l": [[0.0, V.call(-14, 0, 0)]],
		"head": [[0.0, V.call(-2, 0, 0)], [1.2, V.call(-6, 4, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, 14)], [1.2, V.call(28, 0, 18)]], "elbow_l": [[0.0, V.call(40, 0, 0)]],
	}), rest)
	# Her left hand raised, open, toward what she is about to end.
	_anim(lib, "raise", 1.2, false, with.call(sword_low, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)]],
		"leg_r": [[0.0, V.call(4, 0, 2)]], "leg_l": [[0.0, V.call(8, 0, -2)]], "knee_l": [[0.0, V.call(-14, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, 12)], [1.2, V.call(95, 0, 6)]], "elbow_l": [[0.0, V.call(10, 0, 0)], [1.2, V.call(4, 0, 0)]],
		"hand_l": [[0.0, V.call(0, 0, 0)], [1.2, V.call(-70, 0, 0)]],
		"head": [[0.0, V.call(-4, 0, 0)], [1.2, V.call(4, 0, 0)]],
	}), rest)
	# Closing the hand: the snuffing.
	_anim(lib, "close", 0.6, false, with.call(sword_low, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)]],
		"shoulder_l": [[0.0, V.call(95, 0, 6)], [0.6, V.call(80, 0, 10)]], "elbow_l": [[0.0, V.call(4, 0, 0)], [0.6, V.call(30, 0, 0)]],
		"hand_l": [[0.0, V.call(-70, 0, 0)], [0.6, V.call(-20, 0, 40)]],
	}), rest)
	# The sword raised to point at someone (the hero, who does not answer).
	_anim(lib, "point", 1.0, false, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)]],
		"shoulder_r": [[0.0, V.call(6, 0, -12)], [1.0, V.call(88, 0, -4)]], "elbow_r": [[0.0, V.call(14, 0, 0)], [1.0, V.call(0, 0, 0)]],
		"hand_r": [[0.0, V.call(-70, 0, 20)], [1.0, V.call(-90, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, 12)]],
	}, rest)


# --- Denangdyn's shadow -----------------------------------------------------------

## A hand of the shadow: a huge clawed hand of smoke-black with violet light
## in its seams, its wrist trailing off into nothing. One joint ("Hand") so
## the script can curl and slam it.
func _build_shadow_hand() -> void:
	_root = Node3D.new()
	_root.name = "ShadowHandModel"
	_paths = {}
	var BLACK := _c("0c0a14")
	var DARK := _c("1c1428")
	var VIOLET := _c("9a6aff")
	var hand := _joint(_root, "hand", "Hand", Vector3(0, 0.8, 0), func(p: Parts) -> void:
		var k := p.k()
		# The palm and the wrist fading up into smoke.
		k.loft([[0.0, 0.42, 0.18, BLACK], [0.35, 0.36, 0.2, DARK], [0.8, 0.22, 0.16, BLACK], [1.4, 0.0, 0.0, DARK]], 8)
		for i in 4:
			var x := lerpf(-0.3, 0.3, i / 3.0)
			k.prism(Vector3(x, 0.0, -0.1), 0.07, Vector3(x * 1.1, -0.45, -0.35), 0.05, 5, BLACK)
			k.prism(Vector3(x * 1.1, -0.45, -0.35), 0.05, Vector3(x * 1.15, -0.75, -0.25), 0.0, 5, DARK)
		k.prism(Vector3(0.38, 0.05, 0.0), 0.07, Vector3(0.6, -0.3, -0.2), 0.0, 5, BLACK)
		var g := p.k("glow")
		g.box(Vector3(0, 0.3, -0.19), Vector3(0.5, 0.02, 0.01), VIOLET)
		g.icosa(Vector3(0, 0.15, -0.2), Vector3(0.06, 0.06, 0.03), 0.0, VIOLET)
	)
	var lib := AnimationLibrary.new()
	var rest := {"hand": Vector3(0, 0.8, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.0, true, {"hand": [[0.0, V.call(0, 0, 0)], [1.0, V.call(8, 0, 4)]]}, rest)
	_anim(lib, "raise", 0.6, false, {"hand": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-40, 0, 0)]]}, rest)
	_anim(lib, "slam", 0.25, false, {"hand": [[0.0, V.call(-40, 0, 0)], [0.25, V.call(30, 0, 0)]]}, rest)
	_anim(lib, "stunned", 1.0, true, {"hand": [[0.0, V.call(30, 0, 10)], [0.5, V.call(30, 0, -10)]]}, rest)
	_anim(lib, "death", 0.8, false, {"hand": [[0.0, V.call(0, 0, 0)], [0.8, V.call(60, 0, 30)]]}, rest)
	_finish_character(_root, lib)
	_save_scene(_root, "shadow_hand.tscn")


# --- The townsfolk (tools/folk_specs.gd) ---------------------------------------------

func _build_all_folk() -> void:
	for spec: Dictionary in preload("res://tools/folk_specs.gd").FOLK:
		_build_folk(spec)


## One townsperson from a spec (see folk_specs.gd): the shared lady frame
## (every character here is built on it), clothes, hair, a hat and something
## in hand.
func _build_folk(spec: Dictionary) -> void:
	var SKIN := _c(String(spec.skin))
	var SKIN_D := SKIN.darkened(0.1)
	var HAIR := _c(String(spec.hair))
	var HAIR_D := HAIR.darkened(0.22)
	var HAIR_L := HAIR.lightened(0.18)
	var TOP := _c(String(spec.top))
	var TRIM := _c(String(spec.get("trim", spec.top)))
	var LEGS := _c(String(spec.get("legs", "5a4a3a")))
	var SHOES := _c(String(spec.get("shoes", "3a2a1a")))
	var skirt: bool = spec.get("bottom", "trousers") == "skirt"
	var child: bool = float(spec.get("height", 1.0)) < 0.75
	var apron: String = spec.get("apron", "")
	var style: String = spec.get("style", "short")
	var hat: String = spec.get("hat", "")
	var held: String = spec.get("held", "")
	var hips: Callable
	if skirt:
		hips = _skirt_hips(LEGS, LEGS.lightened(0.1), LEGS.darkened(0.15), TRIM, 0.42 if child else 0.7)
	else:
		hips = func(p: Parts) -> void:
			var k := p.k()
			k.loft([[-0.1, 0.15, 0.12, LEGS], [0.0, 0.15, 0.12, LEGS], [0.07, 0.135, 0.11, TOP]], 12)
			k.loft([[-0.02, 0.152, 0.122, TRIM.darkened(0.3)], [0.03, 0.152, 0.122, TRIM.darkened(0.3)]], 12)
	var hips_all := func(p: Parts) -> void:
		hips.call(p)
		if apron != "":
			var h := p.k("hard")
			h.box(Vector3(0, -0.22 if skirt else -0.12, -0.17 if skirt else -0.135), Vector3(0.24, 0.42 if skirt else 0.26, 0.01), _c(apron))
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.13, 0.105, TOP], [0.12, 0.136, 0.106, TOP.lightened(0.06)], [0.24, 0.146, 0.11, TOP],
			[0.31, 0.12, 0.09, TRIM], [0.35, 0.07, 0.062, SKIN_D], [0.37, 0.05, 0.05, SKIN]], 10)
		if apron != "":
			var h := p.k("hard")
			h.box(Vector3(0, 0.12, -0.112), Vector3(0.18, 0.2, 0.01), _c(apron))
	var head := func(p: Parts) -> void:
		var k := p.k()
		if style != "bald":
			_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		match style:
			"long":
				_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.34, 0.13, 0.2)
			"bun":
				k.icosa(Vector3(0, 0.3, 0.11), Vector3(0.06, 0.06, 0.06), 0.1, HAIR)
			"pigtails":
				for sx in [-1.0, 1.0]:
					k.push(_aim(Vector3(sx, -0.6, 0.2), Vector3(0.12 * sx, 0.2, 0.03)))
					k.loft([[0.0, 0.04, 0.04, HAIR], [0.1, 0.035, 0.035, HAIR_L], [0.2, 0.0, 0.0, HAIR]], 6)
					k.pop()
			"tied":
				k.push(_aim(Vector3(0, -0.8, 0.6), Vector3(0, 0.22, 0.11)))
				k.loft([[0.0, 0.035, 0.035, HAIR], [0.12, 0.03, 0.03, HAIR_L], [0.2, 0.0, 0.0, HAIR_D]], 6)
				k.pop()
			"bald":
				# A ring of hair low round the back of the head.
				k.loft([[0.1, 0.122, 0.122, HAIR_D, Vector2(0, 0.012)], [0.16, 0.124, 0.124, HAIR, Vector2(0, 0.012)]], 10, false)
		match hat:
			"cap":
				var blue := _c("2a3a98")
				k.loft([[0.27, 0.13, 0.13, blue.darkened(0.2)], [0.3, 0.15, 0.14, blue], [0.36, 0.12, 0.12, blue.lightened(0.1)], [0.39, 0.0, 0.0, blue]], 10)
				var h := p.k("hard")
				h.push(_aim(Vector3(0.5, 0.6, 0.6), Vector3(0.07, 0.34, 0.06)))
				h.loft([[0.0, 0.004, 0.004, _c("f0f0f8")], [0.06, 0.03, 0.006, _c("ffffff")], [0.2, 0.0, 0.0, _c("e8e8f0")]], 4)
				h.pop()
			"straw":
				var straw := _c("e0c070")
				k.loft([[0.27, 0.22, 0.22, straw.darkened(0.15)], [0.28, 0.22, 0.22, straw], [0.29, 0.12, 0.12, straw], [0.38, 0.11, 0.11, straw.lightened(0.1)], [0.4, 0.0, 0.0, straw]], 12)
			"felt":
				var felt := TRIM.darkened(0.25)
				k.loft([[0.27, 0.165, 0.165, felt.darkened(0.2)], [0.285, 0.165, 0.165, felt], [0.295, 0.12, 0.12, felt], [0.37, 0.11, 0.11, felt.lightened(0.08)], [0.4, 0.0, 0.0, felt]], 10)
			"kerchief":
				var cloth := TRIM.lerp(_c("c84a3a"), 0.5)
				k.loft([[0.17, 0.124, 0.13, cloth.darkened(0.15), Vector2(0, 0.02)], [0.26, 0.135, 0.138, cloth, Vector2(0, 0.015)], [0.33, 0.1, 0.11, cloth, Vector2(0, 0.01)], [0.37, 0.0, 0.0, cloth]], 10)
			"hood":
				var hood := TOP.darkened(0.1)
				k.loft([[0.0, 0.135, 0.135, hood.darkened(0.15), Vector2(0, 0.03)], [0.14, 0.15, 0.15, hood, Vector2(0, 0.02)], [0.27, 0.142, 0.142, hood.lightened(0.06), Vector2(0, 0.03)],
					[0.34, 0.1, 0.1, hood, Vector2(0, 0.05)], [0.4, 0.0, 0.0, hood.darkened(0.1), Vector2(0, 0.08)]], 10)
	var extra := func(root: Node3D) -> void:
		if held == "":
			return
		var hand := "hand_l" if held in ["basket"] else "hand_r"
		_attach(root.get_node(_paths[hand]), "Held", Vector3(0, -0.08, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			match held:
				"scroll":
					h.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
					h.prism(Vector3(0, -0.12, 0), 0.03, Vector3(0, 0.12, 0), 0.03, 8, _c("f0e8d0"))
					h.prism(Vector3(0, -0.13, 0), 0.036, Vector3(0, -0.11, 0), 0.036, 8, _c("a83a2a"))
					h.pop()
				"bread":
					h.icosa(Vector3(0, -0.02, -0.04), Vector3(0.1, 0.05, 0.06), 0.05, _c("c88a40"))
				"cane":
					h.prism(Vector3(0, 0.05, 0), 0.016, Vector3(0, -0.75, 0), 0.014, 6, _c("6a4a2a"))
				"broom":
					h.prism(Vector3(0, 0.6, 0), 0.016, Vector3(0, -0.8, 0), 0.016, 6, _c("8a6a3a"))
					h.prism(Vector3(0, -0.8, 0), 0.03, Vector3(0, -1.05, 0), 0.08, 8, _c("d8b860"))
				"basket":
					h.prism(Vector3(0, -0.14, 0), 0.1, Vector3(0, -0.04, 0), 0.12, 8, _c("b88a4a"))
					h.icosa(Vector3(0, -0.02, 0), Vector3(0.06, 0.04, 0.06), 0.1, _c("e84a3a"))
				"lute":
					h.push(Transform3D(Basis(Vector3.BACK, -0.9), Vector3(0.05, 0.0, -0.1)))
					h.icosa(Vector3(0, -0.1, 0), Vector3(0.12, 0.15, 0.05), 0.0, _c("a8703a"))
					h.prism(Vector3(0, 0.02, 0), 0.02, Vector3(0, 0.34, 0), 0.016, 4, _c("6a4022"))
					h.box(Vector3(0, 0.37, 0.0), Vector3(0.05, 0.06, 0.03), _c("4a2a14"))
					h.pop()
				"fiddle":
					h.push(Transform3D(Basis(Vector3.RIGHT, -1.2), Vector3(0, 0.0, -0.06)))
					h.icosa(Vector3(0, -0.05, 0), Vector3(0.07, 0.12, 0.035), 0.0, _c("8a4a22"))
					h.prism(Vector3(0, 0.06, 0), 0.014, Vector3(0, 0.22, 0), 0.012, 4, _c("2a1a10"))
					h.pop()
				"drum":
					h.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(-0.1, 0.0, -0.1)))
					h.prism(Vector3(0, -0.08, 0), 0.16, Vector3(0, 0.08, 0), 0.16, 10, _c("c86a3a"))
					h.prism(Vector3(0, 0.08, 0), 0.165, Vector3(0, 0.09, 0), 0.165, 10, _c("f0e8d8"))
					h.pop()
		)
	var look := {
		"hips": hips_all, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(TOP, TOP.lightened(0.06), TOP.darkened(0.1), TRIM, SKIN, SKIN_D),
		"forearm": _simple_forearm(TOP, TOP.lightened(0.05), SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(LEGS),
		"shin": _plain_shin(LEGS, SHOES, SHOES.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, SHOES, SHOES.darkened(0.3)),
		"extra": extra,
	}
	var model_name := String(spec.id).to_pascal_case() + "Model"
	_build_woman(model_name, String(spec.id) + ".tscn", "face_" + String(spec.id), SKIN, SKIN_D, look, _folk_anims, float(spec.get("height", 1.0)))


## The townsfolk's poses: the shared idle/talk/happy, plus a walk (Pip running
## in, people about the market), a bow, and "play" for the tavern band.
func _folk_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	_townsfolk_anims(lib, rest, false)
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "walk", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.2, V.call(0, 0.86, 0)], [0.4, V.call(0, 0.84, 0)], [0.6, V.call(0, 0.86, 0)], [0.8, V.call(0, 0.84, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.4, V.call(24, 0, 0)], [0.8, V.call(-24, 0, 0)]],
		"leg_l": [[0.0, V.call(24, 0, 0)], [0.4, V.call(-24, 0, 0)], [0.8, V.call(24, 0, 0)]],
		"knee_r": [[0.0, V.call(-10, 0, 0)], [0.2, V.call(-40, 0, 0)], [0.4, V.call(-6, 0, 0)], [0.8, V.call(-10, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.4, V.call(-10, 0, 0)], [0.6, V.call(-40, 0, 0)], [0.8, V.call(-6, 0, 0)]],
		"shoulder_r": [[0.0, V.call(18, 0, -6)], [0.4, V.call(-18, 0, -6)], [0.8, V.call(18, 0, -6)]],
		"shoulder_l": [[0.0, V.call(-18, 0, 6)], [0.4, V.call(18, 0, 6)], [0.8, V.call(-18, 0, 6)]],
		"elbow_r": [[0.0, V.call(20, 0, 0)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
	}, rest)
	_anim(lib, "bow", 1.4, false, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.4, V.call(38, 0, 0)], [1.0, V.call(38, 0, 0)], [1.4, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.4, V.call(14, 0, 0)], [1.4, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(0, 0, -8)], [0.4, V.call(40, 0, -30)], [1.4, V.call(0, 0, -8)]], "elbow_r": [[0.0, V.call(10, 0, 0)], [0.4, V.call(90, 0, 0)], [1.4, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "play", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.3, V.call(0, 0.83, 0)]],
		"head": [[0.0, V.call(4, 0, 4)], [0.3, V.call(8, 0, -4)], [0.6, V.call(4, 0, 4)]],
		"shoulder_r": [[0.0, V.call(30, 0, -10)], [0.3, V.call(42, 0, -14)], [0.6, V.call(30, 0, -10)]], "elbow_r": [[0.0, V.call(70, 0, 0)], [0.3, V.call(56, 0, 0)], [0.6, V.call(70, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, 20)]], "elbow_l": [[0.0, V.call(80, 0, 0)]],
	}, rest)
