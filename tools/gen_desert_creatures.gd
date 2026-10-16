extends "res://tools/gen_creatures.gd"
## The creatures of Ladhellin Tower (built like gen_creatures.gd):
##
##   mummy        a sun-priest in grave-wrappings that shambles and clutches
##                (after OoT's Gibdo)
##   mummy_lord   the crypt's mini-boss: a crowned high priest twice as tall
##   shade        a wisp of darkness in a tattered hood, solid only in sunlight
##   sand_beetle  the Gear Beetle in sand-colored armor
##   sentinel     the second mini-boss: the Tide Knight's armor in gold
##   wyrm         Kherash the Sand Devourer, the boss: a great armored wyrm
##                (its head; the body is a chain of wyrm_segment models)
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_mummy("mummy", 1.0, false)
	_build_mummy("mummy_lord", 1.0, true)
	_build_shade()
	_build_wyrm()
	_build_wyrm_segment()
	_desert_scenes()


func _desert_scenes() -> void:
	enemy_scene("mummy", {"script": "res://scripts/enemies/mummy.gd", "model": "mummy", "hp": 5,
		"body": [0.38, 1.85, 0.93], "hurt": [0.5, 2.0, 1.0], "hit": [Vector3(1.0, 1.0, 1.2), Vector3(0, 1.3, -0.8)], "shadow": 0.5,
		"exports": {"target_offset": 2.0, "boomerang_stun": 1.5, "drop_table": 1}})
	enemy_scene("mummy_lord", {"script": "res://scripts/enemies/mummy_lord.gd", "model": "mummy_lord", "hp": 14,
		"body": [0.75, 3.6, 1.8], "hurt": [0.95, 3.8, 1.9], "hit": [Vector3(1.8, 1.8, 2.2), Vector3(0, 2.4, -1.5)], "shadow": 1.0,
		"exports": {"target_offset": 3.9, "boomerang_stun": 0.0, "drop_table": 11}})
	enemy_scene("shade", {"script": "res://scripts/enemies/shade.gd", "model": "shade", "hp": 3, "floating": true,
		"body": [0.35, 1.4, 0.2], "hurt": [0.55, 1.6, 0.2], "hit": [Vector3(0.9, 0.9, 0.9), Vector3(0, 0.2, -0.5)], "shadow": 0.4,
		"exports": {"target_offset": 0.9, "boomerang_stun": 0.0, "drop_table": 1}})
	enemy_scene("sand_beetle", {"script": "res://scripts/enemies/gear_beetle.gd", "model": "gear_beetle", "hp": 2,
		"body": [0.5, 0.9, 0.45], "hurt": [0.65, 1.0, 0.45], "hit": [Vector3(1.0, 0.7, 1.0), Vector3(0, 0.4, -0.7)], "shadow": 0.6,
		"exports": {"target_offset": 1.0, "boomerang_stun": 3.0, "drop_table": 1, "tint": Color(1.25, 1.05, 0.7)}})
	enemy_scene("sentinel", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 18,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(1.35, 1.12, 0.55), "start_rate": 1.25,
			"title_name": "SENTINEL", "title_epithet": "The Desert's Golden Guard"}})
	enemy_scene("wyrm", {"script": "res://scripts/enemies/wyrm.gd", "model": "wyrm", "hp": 12, "floating": true,
		"body": [0.9, 1.8, 0.0], "hurt": [1.25, 2.6, 0.0], "hit": [Vector3(2.2, 1.8, 2.6), Vector3(0, 0, -1.0)], "shadow": 1.6,
		"exports": {"target_offset": 0.8, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Mummy ----------------------------------------------------------------------

## A gaunt figure bound head to foot in gray-yellow linen, the bands showing as
## alternating stripes, a few loose strips hanging; a dark slit with two pale
## points for eyes. The lord is the same figure twice the size, in a gold
## crown and a collar of lapis, his wrappings darker.
func _build_mummy(file: String, _scale: float, lord: bool) -> void:
	var WRAP := _c("cfc4a0") if not lord else _c("b8a678")
	var WRAP_D := _c("a89c78") if not lord else _c("8e7e58")
	var GOLD := _c("e8c050")
	var LAPIS := _c("2a4ab0")
	var EYE := _c("f0e8a0") if not lord else _c("ff8a3a")
	var s := 2.0 if lord else 1.0
	_root = Node3D.new()
	_root.name = file.to_pascal_case() + "Model"
	_paths = {}
	var root := _root
	var band := func(i: int) -> Color: return WRAP if i % 2 == 0 else WRAP_D
	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.95 * s, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.12 * s, 0.14 * s, 0.11 * s, WRAP_D], [0.0, 0.17 * s, 0.13 * s, WRAP], [0.08 * s, 0.16 * s, 0.12 * s, WRAP_D]], 8)
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.06 * s, 0), func(p: Parts) -> void:
		var k := p.k()
		var rings: Array = []
		for i in 7:
			var y := i * 0.075 * s
			var r := (0.15 + sin(float(i) / 6.0 * PI) * 0.035) * s
			rings.append([y, r, r * 0.72, band.call(i)])
		rings.append([0.5 * s, 0.07 * s, 0.07 * s, WRAP])
		k.loft(rings, 9)
		var h := p.k("hard")
		if lord:
			# A broad collar of gold and lapis.
			h.loft([[0.38 * s, 0.2 * s, 0.16 * s, GOLD], [0.42 * s, 0.24 * s, 0.19 * s, LAPIS], [0.45 * s, 0.15 * s, 0.12 * s, GOLD]], 10)
		# A loose strip hanging from the waist.
		h.slab(Vector3(0.08 * s, 0.02 * s, -0.12 * s), Vector2(0.05, 0.01) * s, Vector3(0.1 * s, -0.35 * s, -0.14 * s), Vector2(0.04, 0.01) * s, WRAP_D)
	)
	_joint(torso, "head", "Head", Vector3(0, 0.52 * s, -0.01 * s), func(p: Parts) -> void:
		var k := p.k()
		var rings: Array = []
		for i in 6:
			var y := i * 0.05 * s
			var r := (0.1 + sin(float(i) / 5.0 * PI) * 0.03) * s
			rings.append([y, r, r * 1.05, band.call(i + 1)])
		rings.append([0.29 * s, 0.0, 0.0, WRAP])
		k.loft(rings, 8)
		var h := p.k("hard")
		h.box(Vector3(0, 0.15 * s, -0.11 * s), Vector3(0.15, 0.035, 0.03) * s, _c("201810"))
		if lord:
			# The crown: a gold band with a sun disc and a lapis cobra rearing.
			h.prism(Vector3(0, 0.24 * s, 0), 0.13 * s, Vector3(0, 0.34 * s, 0), 0.15 * s, 10, GOLD)
			h.prism(Vector3(0, 0.36 * s, -0.12 * s), 0.07 * s, Vector3(0, 0.38 * s, -0.12 * s), 0.07 * s, 10, GOLD)
			h.icosa(Vector3(0, 0.42 * s, -0.1 * s), Vector3(0.03, 0.06, 0.03) * s, 0.0, LAPIS)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.04 * sx * s, 0.15 * s, -0.125 * s), Vector3(0.025, 0.02, 0.006) * s, EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.2 * side * s, 0.42 * s, 0), func(p: Parts) -> void:
			p.k().loft([[0.03 * s, 0.0, 0.0, WRAP], [0.0, 0.055 * s, 0.055 * s, WRAP], [-0.14 * s, 0.05 * s, 0.05 * s, WRAP_D], [-0.3 * s, 0.045 * s, 0.045 * s, WRAP]], 6)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.3 * s, 0), func(p: Parts) -> void:
			p.k().loft([[0.0, 0.045 * s, 0.045 * s, WRAP], [-0.14 * s, 0.04 * s, 0.04 * s, WRAP_D], [-0.27 * s, 0.035 * s, 0.035 * s, WRAP]], 6)
		)
		_joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.27 * s, 0), func(p: Parts) -> void:
			var k := p.k()
			k.icosa(Vector3(0, -0.06 * s, 0), Vector3(0.045, 0.07, 0.035) * s, 0.15, WRAP_D)
			var h := p.k("hard")
			for i in 3:
				h.prism(Vector3((i - 1) * 0.022 * s, -0.1 * s, -0.01 * s), 0.012 * s, Vector3((i - 1) * 0.026 * s, -0.17 * s, -0.03 * s), 0.004 * s, 4, WRAP)
		)
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.1 * side * s, -0.06 * s, 0), func(p: Parts) -> void:
			p.k().loft([[0.03 * s, 0.0, 0.0, WRAP], [0.0, 0.07 * s, 0.07 * s, WRAP], [-0.2 * s, 0.06 * s, 0.06 * s, WRAP_D], [-0.42 * s, 0.05 * s, 0.05 * s, WRAP]], 6)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.42 * s, 0), func(p: Parts) -> void:
			p.k().loft([[0.0, 0.05 * s, 0.05 * s, WRAP], [-0.2 * s, 0.045 * s, 0.045 * s, WRAP_D], [-0.42 * s, 0.04 * s, 0.04 * s, WRAP]], 6)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.43 * s, 0), func(p: Parts) -> void:
			p.k().box(Vector3(0, -0.03 * s, -0.05 * s), Vector3(0.09, 0.05, 0.2) * s, WRAP_D)
		)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.95 * s, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var arms_out := {"shoulder_r": [[0.0, V.call(70, 0, 8)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "shoulder_l": [[0.0, V.call(70, 0, -8)]], "elbow_l": [[0.0, V.call(10, 0, 0)]]}
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.95 * s, 0)], [1.2, V.call(0, 0.93 * s, 0)]],
		"torso": [[0.0, V.call(-6, 0, 4)], [1.2, V.call(-8, 0, -4)]], "head": [[0.0, V.call(10, 10, 0)], [1.2, V.call(14, -10, 8)]],
		"shoulder_r": [[0.0, V.call(5, 0, 6)]], "shoulder_l": [[0.0, V.call(5, 0, -6)]],
	}, rest)
	var walk := {
		"hips@pos": [[0.0, V.call(0, 0.93 * s, 0)], [0.55, V.call(0, 0.97 * s, 0)], [1.1, V.call(0, 0.93 * s, 0)], [1.65, V.call(0, 0.97 * s, 0)]],
		"torso": [[0.0, V.call(-14, 0, 6)], [1.1, V.call(-14, 0, -6)]], "head": [[0.0, V.call(18, 0, -6)], [1.1, V.call(18, 0, 6)]],
		"leg_r": [[0.0, V.call(25, 0, 3)], [1.1, V.call(-15, 0, 3)]], "knee_r": [[0.0, V.call(-10, 0, 0)], [0.8, V.call(-40, 0, 0)], [1.1, V.call(-10, 0, 0)]],
		"leg_l": [[0.0, V.call(-15, 0, -3)], [1.1, V.call(25, 0, -3)]], "knee_l": [[0.0, V.call(-10, 0, 0)], [1.9, V.call(-40, 0, 0)], [2.2, V.call(-10, 0, 0)]],
	}
	walk.merge(arms_out)
	_anim(lib, "walk", 2.2, true, walk, rest)
	_anim(lib, "reach", 0.75, false, {
		"torso": [[0.0, V.call(-10, 0, 0)], [0.75, V.call(10, 0, 0)]], "head": [[0.0, V.call(10, 0, 0)], [0.75, V.call(-15, 0, 0)]],
		"shoulder_r": [[0.0, V.call(70, 0, 8)], [0.75, V.call(150, 0, 20)]], "elbow_r": [[0.0, V.call(10, 0, 0)], [0.75, V.call(30, 0, 0)]],
		"shoulder_l": [[0.0, V.call(70, 0, -8)], [0.75, V.call(150, 0, -20)]], "elbow_l": [[0.0, V.call(10, 0, 0)], [0.75, V.call(30, 0, 0)]],
	}, rest)
	_anim(lib, "grab", 0.4, false, {
		"hips@pos": [[0.0, V.call(0, 0.95 * s, 0)], [0.15, V.call(0, 0.9 * s, -0.2 * s)], [0.4, V.call(0, 0.95 * s, 0)]],
		"torso": [[0.0, V.call(10, 0, 0)], [0.15, V.call(-30, 0, 0)], [0.4, V.call(-15, 0, 0)]],
		"shoulder_r": [[0.0, V.call(150, 0, 20)], [0.15, V.call(85, 0, -5)]], "elbow_r": [[0.0, V.call(30, 0, 0)], [0.15, V.call(20, 0, 0)]],
		"shoulder_l": [[0.0, V.call(150, 0, -20)], [0.15, V.call(85, 0, 5)]], "elbow_l": [[0.0, V.call(30, 0, 0)], [0.15, V.call(20, 0, 0)]],
	}, rest)
	_anim(lib, "sweep", 0.5, false, {
		"torso": [[0.0, V.call(-10, -60, 0)], [0.2, V.call(-15, 80, 0)], [0.5, V.call(-10, 120, 0)]],
		"shoulder_r": [[0.0, V.call(90, 0, 70)]], "shoulder_l": [[0.0, V.call(90, 0, -70)]],
	}, rest)
	_anim(lib, "stunned", 0.8, true, {
		"torso": [[0.0, V.call(-25, 10, 8)], [0.4, V.call(-25, -10, -8)]], "head": [[0.0, V.call(25, 0, 10)], [0.4, V.call(25, 0, -10)]],
		"shoulder_r": [[0.0, V.call(-10, 0, 20)]], "shoulder_l": [[0.0, V.call(-10, 0, -20)]],
	}, rest)
	_anim(lib, "death", 1.0, false, {
		"hips@pos": [[0.0, V.call(0, 0.95 * s, 0)], [0.6, V.call(0, 0.5 * s, 0.1 * s)], [1.0, V.call(0, 0.25 * s, 0.4 * s)]],
		"hips": [[0.0, V.call(0, 0, 0)], [1.0, V.call(-75, 0, 0)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-90, 0, 0)]], "knee_l": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-90, 0, 0)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, file + ".tscn")


# --- Shade ----------------------------------------------------------------------

## A tattered dark hood over a void with two violet eyes, a ragged cloak that
## trails to nothing, and two long clawed hands.
func _build_shade() -> void:
	var CLOTH := _c("2a1e3a")
	var CLOTH_L := _c("4a3a62")
	var VOID := _c("08060c")
	var CLAW := _c("6a5a8a")
	var EYE := _c("c070ff")
	_root = Node3D.new()
	_root.name = "ShadeModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.0, 0), func(p: Parts) -> void:
		var k := p.k()
		# The cloak: wide at the bottom, ragged, up to the shoulders.
		k.loft([[-0.75, 0.42, 0.38, CLOTH], [-0.4, 0.32, 0.28, CLOTH], [0.0, 0.26, 0.22, CLOTH_L], [0.35, 0.2, 0.17, CLOTH]], 9, false)
		var h := p.k("hard")
		for i in 9:
			var a := TAU * i / 9.0
			h.prism(Vector3(cos(a) * 0.38, -0.72, sin(a) * 0.34), 0.07, Vector3(cos(a) * 0.42, -1.05 - (i % 3) * 0.1, sin(a) * 0.38), 0.0, 3, CLOTH)
	)
	_joint(body, "head", "Head", Vector3(0, 0.38, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.2, 0.2, CLOTH], [0.18, 0.19, 0.2, CLOTH_L], [0.34, 0.1, 0.12, CLOTH], [0.46, 0.0, 0.0, CLOTH]], 8)
		var h := p.k("hard")
		h.icosa(Vector3(0, 0.15, -0.12), Vector3(0.12, 0.12, 0.06), 0.0, VOID)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.05 * sx, 0.17, -0.17), Vector3(0.025, 0.018, 0.01), 0.0, EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var arm := _joint(body, "arm" + sfx, "Arm" + nsfx, Vector3(0.22 * side, 0.28, 0), func(p: Parts) -> void:
			p.k().loft([[0.0, 0.07, 0.07, CLOTH], [-0.3, 0.06, 0.06, CLOTH_L], [-0.5, 0.05, 0.05, CLOTH]], 6)
		)
		_joint(arm, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.5, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			for i in 3:
				h.prism(Vector3((i - 1) * 0.03, 0, 0), 0.018, Vector3((i - 1) * 0.05, -0.22, -0.06), 0.0, 4, CLAW)
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "float", 1.6, true, {
		"body@pos": [[0.0, V.call(0, 0, 0)], [0.8, V.call(0, 0.12, 0)]],
		"body": [[0.0, V.call(5, 0, 4)], [0.8, V.call(5, 0, -4)]],
		"arm_r": [[0.0, V.call(20, 0, 15)], [0.8, V.call(30, 0, 20)]], "arm_l": [[0.0, V.call(20, 0, -15)], [0.8, V.call(30, 0, -20)]],
		"head": [[0.0, V.call(10, 8, 0)], [0.8, V.call(10, -8, 0)]],
	}, rest)
	_anim(lib, "swipe", 0.8, false, {
		"body": [[0.0, V.call(5, 0, 0)], [0.3, V.call(-25, 0, 0)], [0.8, V.call(5, 0, 0)]],
		"arm_r": [[0.0, V.call(20, 0, 15)], [0.25, V.call(150, 0, 40)], [0.45, V.call(40, 0, -20)], [0.8, V.call(20, 0, 15)]],
		"arm_l": [[0.0, V.call(20, 0, -15)], [0.35, V.call(150, 0, -40)], [0.55, V.call(40, 0, 20)], [0.8, V.call(20, 0, -15)]],
	}, rest)
	_anim(lib, "reel", 0.5, true, {
		"body": [[0.0, V.call(25, 0, 20)], [0.25, V.call(25, 0, -20)]],
		"head": [[0.0, V.call(-30, 0, 0)]],
		"arm_r": [[0.0, V.call(140, 0, 30)]], "arm_l": [[0.0, V.call(140, 0, -30)]],
	}, rest)
	_anim(lib, "stunned", 0.5, true, {"body": [[0.0, V.call(25, 0, 20)], [0.25, V.call(25, 0, -20)]]}, rest)
	_anim(lib, "death", 0.8, false, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.8, V.call(0, -0.6, 0)]], "body": [[0.0, V.call(0, 0, 0)], [0.8, V.call(40, 180, 0)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "shade.tscn")


# --- Kherash, the wyrm ------------------------------------------------------------

## The head: a long armored skull in sandstone-colored plates with a ridge
## of horns, one great amber eye in the brow, and a hinged lower jaw lined
## with teeth. The node sits in the middle of the head.
func _build_wyrm() -> void:
	var PLATE := _c("c8a060")
	var PLATE_D := _c("8a6a3a")
	var BELLY := _c("e8d0a0")
	var MOUTH := _c("6a1a1a")
	var TOOTH := _c("f0ecd8")
	var EYE := _c("ffb030")
	_root = Node3D.new()
	_root.name = "WyrmModel"
	_paths = {}
	var root := _root
	var skull := _joint(root, "skull", "Skull", Vector3(0, 0.0, 0), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, 0, -1), Vector3(0, 0.1, 0.9)))
		k.loft([[0.0, 0.85, 0.75, PLATE_D], [0.5, 0.95, 0.8, PLATE], [1.2, 0.8, 0.6, PLATE], [1.9, 0.45, 0.35, PLATE], [2.2, 0.15, 0.12, PLATE_D]], 10)
		k.pop()
		var h := p.k("hard")
		# The horn ridge down the back of the head, and plates over the eye.
		for i in 5:
			var z := 0.9 - i * 0.35
			h.prism(Vector3(0, 0.75 - i * 0.04, z), 0.12, Vector3(0, 1.25 - i * 0.06, z + 0.35), 0.0, 4, PLATE_D)
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.55 * sx, 0.45, 0.6), 0.1, Vector3(0.95 * sx, 0.9, 1.1), 0.0, 4, PLATE_D)
		# The upper teeth.
		for i in 6:
			var x := -0.38 + i * 0.15
			h.prism(Vector3(x, -0.18, -0.6 - absf(x) * 0.6), 0.04, Vector3(x, -0.38, -0.62 - absf(x) * 0.6), 0.0, 4, TOOTH)
		h.box(Vector3(0, -0.15, -0.3), Vector3(0.7, 0.08, 1.4), MOUTH)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.45, -0.75), Vector3(0.24, 0.2, 0.12), 0.0, EYE, true)
		g.icosa(Vector3(0, 0.45, -0.85), Vector3(0.06, 0.15, 0.04), 0.0, _c("2a0a00"))
	)
	_joint(skull, "jaw", "Jaw", Vector3(0, -0.25, 0.6), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.1, -1), Vector3.ZERO))
		k.loft([[0.0, 0.55, 0.35, BELLY], [0.8, 0.45, 0.28, PLATE], [1.6, 0.2, 0.14, PLATE_D]], 8)
		k.pop()
		var h := p.k("hard")
		for i in 5:
			var x := -0.3 + i * 0.15
			h.prism(Vector3(x, 0.1, -0.7 - absf(x) * 0.6), 0.035, Vector3(x, 0.32, -0.72 - absf(x) * 0.6), 0.0, 4, TOOTH)
		h.box(Vector3(0, 0.12, -0.6), Vector3(0.55, 0.06, 1.1), MOUTH)
	)
	var lib := AnimationLibrary.new()
	var rest := {"skull": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "rear", 1.4, true, {
		"skull": [[0.0, V.call(-8, 0, 5)], [0.7, V.call(-4, 0, -5)]],
		"jaw": [[0.0, V.call(15, 0, 0)], [0.7, V.call(25, 0, 0)]],
	}, rest)
	_anim(lib, "roar", 2.0, false, {
		"skull": [[0.0, V.call(0, 0, 0)], [0.4, V.call(-35, 0, 0)], [1.6, V.call(-30, 0, 0)], [2.0, V.call(-8, 0, 0)]],
		"jaw": [[0.0, V.call(5, 0, 0)], [0.4, V.call(45, 0, 0)], [1.6, V.call(45, 0, 0)], [2.0, V.call(15, 0, 0)]],
	}, rest)
	_anim(lib, "bite", 0.6, false, {
		"skull": [[0.0, V.call(-15, 0, 0)], [0.15, V.call(10, 0, 0)], [0.6, V.call(-5, 0, 0)]],
		"jaw": [[0.0, V.call(50, 0, 0)], [0.2, V.call(0, 0, 0)], [0.6, V.call(15, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.8, true, {
		"skull": [[0.0, V.call(15, 0, 25)], [0.4, V.call(15, 0, 15)]],
		"jaw": [[0.0, V.call(35, 0, 0)]],
	}, rest)
	_anim(lib, "death", 2.0, false, {
		"skull": [[0.0, V.call(15, 0, 25)], [2.0, V.call(30, 0, 70)]],
		"jaw": [[0.0, V.call(35, 0, 0)], [2.0, V.call(55, 0, 0)]],
	}, rest)
	_finish_character(root, lib)
	(root.get_node("AnimationPlayer") as AnimationPlayer).autoplay = "rear"
	_save_scene(root, "wyrm.tscn")


## One ring of the wyrm's body: a thick armored hoop of overlapping plates,
## pale belly scales underneath, a spine of short horns on top. It runs along
## -Z.
func _build_wyrm_segment() -> void:
	var root := Node3D.new()
	root.name = "WyrmSegment"
	var k := MeshKit.new(461)
	k.push(_aim(Vector3(0, 0, -1), Vector3(0, 0, 0.55)))
	k.loft([[0.0, 0.62, 0.55, _c("8a6a3a")], [0.25, 0.78, 0.68, _c("c8a060")], [0.75, 0.74, 0.64, _c("b89050")], [1.1, 0.6, 0.52, _c("8a6a3a")]], 10)
	k.pop()
	k.box(Vector3(0, -0.52, 0), Vector3(0.7, 0.2, 0.9), _c("e8d0a0"))
	k.prism(Vector3(0, 0.6, 0.1), 0.1, Vector3(0, 1.0, 0.3), 0.0, 4, _c("6a4a2a"))
	k.smooth_normals(50.0)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = k.build(_mats.char)
	root.add_child(mi)
	mi.owner = root
	_save_scene(root, "wyrm_segment.tscn")
