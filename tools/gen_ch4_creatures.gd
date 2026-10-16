extends "res://tools/gen_fells_creatures.gd"
## The creatures of Beta 1.2.0 (Chapter IV, "The Fall of Bunsriel"):
##
##   boar_rider        a goblin on a war boar with a spear: charges in
##                     straight runs (scripts/enemies/boar_rider.gd)
##   siege_ogre        Grukk the Siegebreaker, master of Westmarch Fortress:
##                     a hulking ogre in siege iron with a battering-ram club
##                     (scripts/enemies/siege_ogre.gd)
##   pedestal_guardian the stone knight of the Temple of Bun, a great eye of
##                     starlight shut in its breastplate
##                     (scripts/enemies/pedestal_guardian.gd)
##   shadow_wolf       a lean black wolf of the Dark Forest (scripts/enemies/shadow_wolf.gd)
##
## and scenes over models made elsewhere: goblin_archer (the Cinder Goblin with
## a bow), battle_mage (the Order's mage, in war colors) and dark_gigglebuns
## (the hero's own shape, the Temple's trial). Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_boar_rider()
	_build_brute("siege_ogre.tscn", "SiegeOgreModel", 2.3, {
		"skin": _c("7a3e2a"), "skin_l": _c("944e36"), "skin_d": _c("5e2c1e"), "hide": _c("4a3a2a"),
		"iron": _c("3a3a40"), "iron_l": _c("5a5a64"), "trim": _c("8a3a1a"), "bone": _c("d8cdaa"), "eye": _c("ff8a2a"),
		"face": "face_goblin", "weapon": "ram"})
	_build_brute("pedestal_guardian.tscn", "PedestalGuardianModel", 2.9, {
		"skin": _c("8e8c88"), "skin_l": _c("a4a29c"), "skin_d": _c("6a6864"), "hide": _c("7a7872"),
		"iron": _c("9a9890"), "iron_l": _c("bab8ae"), "trim": _c("c8a84a"), "bone": _c("e8e0c8"), "eye": _c("bcd0ff"),
		"face": "", "weapon": "greatsword", "stone": true})
	_build_wolf()
	_build_pepper()
	_build_haven_guard("RowenaModel", "rowena.tscn", "face_rowena", true)
	_build_haven_guard("HavenSoldierModel", "haven_soldier.tscn", "face_soldier", false)
	_build_posy()
	enemy_scene("goblin_archer", {"script": "res://scripts/enemies/goblin_archer.gd", "model": "cinder_goblin", "hp": 3,
		"body": [0.38, 1.3, 0.65], "hurt": [0.5, 1.45, 0.72], "shadow": 0.5,
		"exports": {"target_offset": 1.3, "drop_table": 2}})
	enemy_scene("boar_rider", {"script": "res://scripts/enemies/boar_rider.gd", "model": "boar_rider", "hp": 6,
		"body": [0.6, 1.5, 0.8], "hurt": [0.8, 2.0, 1.0], "hit": [Vector3(1.4, 1.2, 1.0), Vector3(0, 0.8, -1.1)], "shadow": 1.0,
		"exports": {"target_offset": 1.8, "boomerang_stun": 1.5, "drop_table": 2}})
	enemy_scene("battle_mage", {"script": "res://scripts/enemies/battle_mage.gd", "model": "sapphire_mage", "hp": 16,
		"body": [0.4, 1.8, 0.9], "hurt": [0.55, 1.9, 0.95], "shadow": 0.6,
		"exports": {"target_offset": 1.6, "boomerang_stun": 1.0, "drop_table": -1, "tint": Color(1.15, 0.8, 0.75)}})
	enemy_scene("siege_ogre", {"script": "res://scripts/enemies/siege_ogre.gd", "model": "siege_ogre", "hp": 30,
		"body": [1.0, 3.0, 1.5], "hurt": [1.3, 3.4, 1.7], "hit": [Vector3(3.0, 2.4, 2.6), Vector3(0, 1.2, -1.9)], "shadow": 1.8,
		"exports": {"target_offset": 2.8, "boomerang_stun": 0.0, "drop_table": -1}})
	enemy_scene("pedestal_guardian", {"script": "res://scripts/enemies/pedestal_guardian.gd", "model": "pedestal_guardian", "hp": 28,
		"body": [1.2, 4.0, 2.0], "hurt": [1.4, 4.2, 2.1], "hit": [Vector3(4.4, 2.0, 3.2), Vector3(0, 1.0, -2.2)], "shadow": 2.2,
		"exports": {"target_offset": 3.0, "boomerang_stun": 0.0, "drop_table": -1}})
	enemy_scene("dark_gigglebuns", {"script": "res://scripts/enemies/dark_gigglebuns.gd", "model": "sir_gigglebuns", "hp": 16,
		"body": [0.35, 1.8, 0.9], "hurt": [0.45, 1.85, 0.92], "hit": [Vector3(1.6, 1.2, 1.5), Vector3(0, 1.0, -0.95)], "shadow": 0.55,
		"exports": {"target_offset": 1.6, "boomerang_stun": 0.0, "drop_table": -1, "tint": Color(0.32, 0.26, 0.45)}})
	enemy_scene("shadow_wolf", {"script": "res://scripts/enemies/shadow_wolf.gd", "model": "shadow_wolf", "hp": 5,
		"body": [0.45, 0.9, 0.5], "hurt": [0.6, 1.4, 0.6], "hit": [Vector3(1.0, 0.8, 1.2), Vector3(0, 0.6, -0.9)], "shadow": 0.7,
		"exports": {"target_offset": 0.9, "boomerang_stun": 2.0, "drop_table": 1}})
	print("gen_ch4_creatures: done")


# --- Quadrupeds -------------------------------------------------------------------

## A four-legged body: a lofted barrel along Z (the head end toward -Z), a
## head on a neck joint, four legs of two joints each. Returns the body joint.
## `look`: body [len, girth, height, col, col_d], head (Callable(p)), leg
## [length, thick, col, hoof_col], tail (Callable(p) or null).
func _quad(root: Node3D, hip_y: float, look: Dictionary) -> Node3D:
	var b: Array = look.body
	var blen: float = b[0]
	var girth: float = b[1]
	var tall: float = b[2]
	var col: Color = b[3]
	var col_d: Color = b[4]
	var body := _joint(root, "body", "Body", Vector3(0, hip_y, 0), func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
		k.loft([
			[-blen * 0.55, 0.0, 0.0, col_d], [-blen * 0.5, girth * 0.6, tall * 0.55, col_d], [-blen * 0.3, girth, tall, col],
			[0.0, girth * 1.05, tall * 1.05, col], [blen * 0.3, girth * 1.0, tall * 1.1, col], [blen * 0.48, girth * 0.7, tall * 0.85, col_d],
			[blen * 0.56, 0.0, 0.0, col_d],
		], 10)
		k.pop()
		if look.has("back"):
			look.back.call(p)
	)
	_joint(body, "head", "Head", Vector3(0, tall * 0.25, -blen * 0.55), look.head)
	var leg: Array = look.leg
	var llen: float = leg[0]
	var thick: float = leg[1]
	for spec in [["leg_fl", -1.0, -1.0], ["leg_fr", 1.0, -1.0], ["leg_bl", -1.0, 1.0], ["leg_br", 1.0, 1.0]]:
		var key: String = spec[0]
		var sx: float = spec[1]
		var sz: float = spec[2]
		var upper := _joint(body, key, key.to_pascal_case(), Vector3(girth * 0.62 * sx, -tall * 0.3, blen * 0.32 * sz), func(p: Parts) -> void:
			p.k().loft([[0.06, 0.0, 0.0, col], [0.03, thick * 1.3, thick * 1.5, col], [-llen * 0.5, thick, thick * 1.1, col_d], [-llen * 0.55, 0.0, 0.0, col_d]], 6)
		)
		_joint(upper, key + "_low", (key + "_low").to_pascal_case(), Vector3(0, -llen * 0.5, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.03, 0.0, 0.0, col_d], [0.01, thick * 0.9, thick * 0.95, col_d], [-llen * 0.45, thick * 0.7, thick * 0.75, col_d], [-llen * 0.5, 0.0, 0.0, col_d]], 6)
			k.box(Vector3(0, -llen * 0.48, -0.02), Vector3(thick * 1.6, 0.06, thick * 2.0), leg[3])
		)
	if look.get("tail") is Callable:
		_joint(body, "tail", "Tail", Vector3(0, tall * 0.4, blen * 0.55), look.tail)
	return body


## Quadruped cycles over the _quad joints (+ "rider"/"arm" keys if present).
func _quad_anims(lib: AnimationLibrary, rest: Dictionary, hip_y: float, stride: float, extra := {}) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	var idle := {
		"body@pos": [[0.0, V.call(0, hip_y, 0)], [0.7, V.call(0, hip_y - 0.02, 0)]],
		"head": [[0.0, V.call(5, 0, 0)], [0.7, V.call(10, 4, 0)]],
	}
	idle.merge(extra.get("idle", {}))
	_anim(lib, "idle", 1.4, true, idle, rest)
	for spec in [["run", 0.42, 1.0], ["charge", 0.3, 1.35]]:
		var t: float = spec[1]
		var a: float = stride * float(spec[2])
		var run := {
			"body@pos": [[0.0, V.call(0, hip_y, 0)], [t * 0.25, V.call(0, hip_y + 0.06, 0)], [t * 0.5, V.call(0, hip_y, 0)], [t * 0.75, V.call(0, hip_y + 0.06, 0)]],
			"body": [[0.0, V.call(-3, 0, 0)], [t * 0.5, V.call(3, 0, 0)]],
			"head": [[0.0, V.call(15 if spec[0] == "charge" else 0, 0, 0)], [t * 0.5, V.call(20 if spec[0] == "charge" else 6, 0, 0)]],
			"leg_fl": [[0.0, V.call(a, 0, 0)], [t * 0.5, V.call(-a, 0, 0)]], "leg_fl_low": [[0.0, V.call(-10, 0, 0)], [t * 0.25, V.call(-50, 0, 0)], [t * 0.5, V.call(-5, 0, 0)]],
			"leg_fr": [[0.0, V.call(-a * 0.6, 0, 0)], [t * 0.5, V.call(a, 0, 0)]], "leg_fr_low": [[0.0, V.call(-5, 0, 0)], [t * 0.75, V.call(-50, 0, 0)]],
			"leg_bl": [[0.0, V.call(-a, 0, 0)], [t * 0.5, V.call(a, 0, 0)]], "leg_bl_low": [[0.0, V.call(30, 0, 0)], [t * 0.5, V.call(5, 0, 0)]],
			"leg_br": [[0.0, V.call(a * 0.6, 0, 0)], [t * 0.5, V.call(-a, 0, 0)]], "leg_br_low": [[0.0, V.call(5, 0, 0)], [t * 0.75, V.call(35, 0, 0)]],
		}
		run.merge(extra.get(spec[0], {}))
		_anim(lib, spec[0], t, true, run, rest)
	var hurt := {
		"body@pos": [[0.0, V.call(0, hip_y + 0.05, 0.1)], [0.35, V.call(0, hip_y, 0)]],
		"body": [[0.0, V.call(-12, 0, 8)], [0.35, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(-25, 0, 0)], [0.35, V.call(5, 0, 0)]],
	}
	hurt.merge(extra.get("hurt", {}))
	_anim(lib, "hurt", 0.35, false, hurt, rest)
	var stunned := {
		"body@pos": [[0.0, V.call(0, hip_y - 0.08, 0)]],
		"body": [[0.0, V.call(4, 0, -6)], [0.5, V.call(4, 0, 6)]],
		"head": [[0.0, V.call(30, 20, 0)], [0.5, V.call(30, -20, 0)]],
		"leg_fl": [[0.0, V.call(-20, 0, -10)]], "leg_fr": [[0.0, V.call(-20, 0, 10)]],
	}
	stunned.merge(extra.get("stunned", {}))
	_anim(lib, "stunned", 1.0, true, stunned, rest)
	var lunge := {
		"body@pos": [[0.0, V.call(0, hip_y, 0)], [0.15, V.call(0, hip_y + 0.25, -0.2)], [0.4, V.call(0, hip_y, -0.3)]],
		"body": [[0.0, V.call(10, 0, 0)], [0.15, V.call(-15, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(-10, 0, 0)], [0.2, V.call(25, 0, 0)]],
		"leg_fl": [[0.0, V.call(-40, 0, 0)], [0.2, V.call(50, 0, 0)]], "leg_fr": [[0.0, V.call(-40, 0, 0)], [0.2, V.call(50, 0, 0)]],
		"leg_bl": [[0.0, V.call(30, 0, 0)], [0.2, V.call(-40, 0, 0)]], "leg_br": [[0.0, V.call(30, 0, 0)], [0.2, V.call(-40, 0, 0)]],
	}
	lunge.merge(extra.get("lunge", {}))
	_anim(lib, "lunge", 0.4, false, lunge, rest)
	var death := {
		"body@pos": [[0.0, V.call(0, hip_y, 0)], [0.5, V.call(0, hip_y * 0.45, 0.1)], [1.0, V.call(0, hip_y * 0.4, 0.1)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.5, V.call(0, 0, 80)], [1.0, V.call(0, 0, 88)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.5, V.call(20, 0, 0)]],
		"leg_fl": [[0.0, V.call(0, 0, 0)], [0.5, V.call(30, 0, 0)]], "leg_bl": [[0.0, V.call(0, 0, 0)], [0.5, V.call(-30, 0, 0)]],
	}
	death.merge(extra.get("death", {}))
	_anim(lib, "death", 1.0, false, death, rest)


## A goblin on a war boar: bristled brown boar with tusks and a hide saddle,
## and a goblin rider in iron with a long spear couched forward.
func _build_boar_rider() -> void:
	var HIDE := _c("5a4030")
	var HIDE_D := _c("3e2c20")
	var BRISTLE := _c("2a2018")
	var TUSK := _c("e8dcc0")
	var SKIN := _c("8a4630")
	var SKIN_D := _c("6a3222")
	var IRON := _c("3d3d45")
	var WOOD := _c("6b4a2a")
	var WHITE := Color.WHITE
	_root = Node3D.new()
	_root.name = "BoarRiderModel"
	_paths = {}
	var root := _root
	var back := func(p: Parts) -> void:
		var k := p.k()
		# A bristled ridge down the spine and the saddle cloth.
		for i in 8:
			k.prism(Vector3(0, 0.38, -0.7 + i * 0.18), 0.05, Vector3(0, 0.52, -0.74 + i * 0.18), 0.0, 4, BRISTLE)
		var h := p.k("hard")
		h.box(Vector3(0, 0.42, 0.05), Vector3(0.7, 0.06, 0.6), _c("6a2a1a"))
		h.box(Vector3(0, 0.2, 0.05), Vector3(0.9, 0.42, 0.04), _c("5a2216"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0 - 0.3), Vector3.ZERO))
		k.loft([[0.0, 0.3, 0.3, HIDE], [0.25, 0.26, 0.25, HIDE], [0.45, 0.16, 0.15, HIDE_D], [0.55, 0.13, 0.12, _c("3a2a26")], [0.57, 0.0, 0.0, _c("2a1e1a")]], 8)
		k.pop()
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx * 0.5, 1, 0.3), Vector3(0.16 * sx, 0.2, 0.0)))
			k.loft([[0.0, 0.05, 0.03, HIDE_D], [0.12, 0.0, 0.0, HIDE_D]], 4)
			k.pop()
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.1 * sx, -0.18, -0.42), 0.03, Vector3(0.18 * sx, -0.02, -0.5), 0.0, 4, TUSK)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.13 * sx, 0.08, -0.2), Vector3(0.04, 0.03, 0.02), _c("ff4a1a"))
	var tail := func(p: Parts) -> void:
		p.k().loft([[0.0, 0.03, 0.03, HIDE_D], [-0.25, 0.0, 0.0, BRISTLE]], 4)
	var body := _quad(root, 0.85, {"body": [1.9, 0.42, 0.42, HIDE, HIDE_D], "back": back, "head": head,
		"leg": [0.62, 0.08, HIDE_D, _c("2a2018")], "tail": tail})
	# The rider sits back on the saddle: a goblin torso, head and spear arm.
	var rider := _joint(body, "rider", "Rider", Vector3(0, 0.45, 0.1), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.17, 0.14, SKIN_D], [0.15, 0.2, 0.16, SKIN], [0.32, 0.2, 0.15, SKIN], [0.42, 0.1, 0.08, SKIN_D], [0.45, 0.0, 0.0, SKIN_D]], 9)
		var h := p.k("hard")
		h.slab(Vector3(0, 0.08, -0.15), Vector2(0.26, 0.04), Vector3(0, 0.32, -0.19), Vector2(0.3, 0.04), IRON)
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.21 * sx, 0.32, 0.0), 0.1, Vector3(0.21 * sx, 0.4, 0.0), 0.07, 6, IRON)
			# Legs astride the boar.
			k.push(_aim(Vector3(sx, -0.8, -0.2), Vector3(0.14 * sx, 0.0, 0.0)))
			k.loft([[0.0, 0.07, 0.07, SKIN], [0.3, 0.05, 0.05, SKIN_D], [0.34, 0.0, 0.0, SKIN_D]], 6)
			k.pop()
	)
	_joint(rider, "rider_head", "RiderHead", Vector3(0, 0.45, -0.06), func(p: Parts) -> void:
		var f := p.k("face_goblin")
		f.loft([
			[-0.02, 0.09, 0.07, WHITE, Vector2(0, -0.07)], [0.02, 0.15, 0.13, WHITE, Vector2(0, -0.05)],
			[0.06, 0.16, 0.15, WHITE, Vector2(0, -0.04)], [0.1, 0.15, 0.155, WHITE, Vector2(0, -0.035)],
			[0.14, 0.14, 0.16, WHITE, Vector2(0, -0.03)], [0.18, 0.15, 0.16, WHITE, Vector2(0, -0.025)],
			[0.22, 0.14, 0.15, WHITE, Vector2(0, -0.01)], [0.26, 0.11, 0.12, WHITE, Vector2(0, 0.0)], [0.3, 0.0, 0.0, WHITE, Vector2(0, 0.01)],
		], 10)
		var h := p.k("hard")
		h.prism(Vector3(0, 0.22, -0.01), 0.155, Vector3(0, 0.3, 0.0), 0.1, 8, IRON, PI / 8.0)
		h.prism(Vector3(0, 0.3, 0.0), 0.04, Vector3(0, 0.45, 0.04), 0.0, 4, _c("8a2a1a"))
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.055 * sx, 0.155, -0.183), Vector3(0.05, 0.03, 0.01), _c("ffb12e"))
	)
	var arm := _joint(rider, "arm", "SpearArm", Vector3(0.24, 0.3, -0.04), func(p: Parts) -> void:
		p.k().loft([[0.05, 0.0, 0.0, SKIN], [0.03, 0.07, 0.07, SKIN], [-0.28, 0.06, 0.06, SKIN_D], [-0.3, 0.0, 0.0, SKIN_D]], 6)
	)
	_attach(arm, "Spear", Vector3(0, -0.28, 0), func(p: Parts) -> void:
		var k := p.k("hard")
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
		k.prism(Vector3(0, -0.6, 0), 0.025, Vector3(0, 1.4, 0), 0.025, 5, WOOD)
		k.prism(Vector3(0, 1.4, 0), 0.06, Vector3(0, 1.7, 0), 0.0, 4, IRON)
		k.box(Vector3(0, 1.25, 0), Vector3(0.18, 0.12, 0.01), _c("8a2a1a"))
		k.pop()
	, "spear")
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.85, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var couch := {"arm": [[0.0, V.call(80, 0, 0)]], "rider": [[0.0, V.call(-10, 0, 0)]], "rider_head": [[0.0, V.call(5, 0, 0)]]}
	_quad_anims(lib, rest, 0.85, 34.0, {
		"idle": {"arm": [[0.0, V.call(20, 0, 10)], [0.7, V.call(25, 0, 10)]], "rider": [[0.0, V.call(0, 0, 0)], [0.7, V.call(-3, 0, 0)]]},
		"run": {"arm": [[0.0, V.call(60, 0, 0)]], "rider": [[0.0, V.call(-6, 0, 0)], [0.21, V.call(0, 0, 0)]]},
		"charge": couch,
		"hurt": {"rider": [[0.0, V.call(25, 0, 0)], [0.35, V.call(0, 0, 0)]], "arm": [[0.0, V.call(0, 0, 40)]]},
		"stunned": {"rider": [[0.0, V.call(10, 0, -15)], [0.5, V.call(10, 0, 15)]], "arm": [[0.0, V.call(0, 0, 30)]]},
		"lunge": couch,
	})
	_finish_character(root, lib)
	_save_scene(root, "boar_rider.tscn")


## A lean black wolf of the Dark Forest: narrow chest, long legs and muzzle,
## ragged ruff, eyes of cold violet.
func _build_wolf() -> void:
	var FUR := _c("2a2630")
	var FUR_D := _c("1a181e")
	var FUR_L := _c("3e3a46")
	_root = Node3D.new()
	_root.name = "ShadowWolfModel"
	_paths = {}
	var root := _root
	var back := func(p: Parts) -> void:
		var k := p.k()
		for i in 6:
			k.prism(Vector3(0, 0.2, -0.42 + i * 0.07), 0.06, Vector3(0, 0.3, -0.48 + i * 0.07), 0.0, 4, FUR_L)
	var head := func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0 - 0.15), Vector3.ZERO))
		k.loft([[0.0, 0.14, 0.14, FUR], [0.12, 0.13, 0.12, FUR], [0.3, 0.06, 0.07, FUR_D], [0.36, 0.0, 0.0, _c("0a0a0e")]], 8)
		k.pop()
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx * 0.3, 1, 0.2), Vector3(0.08 * sx, 0.1, 0.02)))
			k.loft([[0.0, 0.04, 0.025, FUR_D], [0.14, 0.0, 0.0, FUR_D]], 4)
			k.pop()
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.065 * sx, 0.05, -0.12), Vector3(0.035, 0.02, 0.02), _c("c89aff"))
	var tail := func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.4, 1), Vector3.ZERO))
		k.loft([[0.0, 0.05, 0.05, FUR], [0.2, 0.07, 0.07, FUR_L], [0.45, 0.0, 0.0, FUR_D]], 5)
		k.pop()
	_quad(root, 0.62, {"body": [1.15, 0.22, 0.26, FUR, FUR_D], "back": back, "head": head, "leg": [0.55, 0.05, FUR_D, _c("0e0e12")], "tail": tail})
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.62, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_quad_anims(lib, rest, 0.62, 40.0, {
		"idle": {"tail": [[0.0, V.call(0, 15, 0)], [0.7, V.call(0, -15, 0)]]},
		"run": {"tail": [[0.0, V.call(-10, 0, 0)]]},
	})
	_finish_character(root, lib)
	_save_scene(root, "shadow_wolf.tscn")


# --- Brutes -----------------------------------------------------------------------

## A hulking biped on the Cinder Goblin's skeleton (so _goblin_anims fit it),
## scaled up by `size`: the Siege Ogre (iron and hide, a battering-ram club)
## and the Pedestal Guardian (living stone, a stone greatsword, an eye of
## starlight in its breastplate, marked "Eye").
func _build_brute(file: String, model_name: String, size: float, look: Dictionary) -> void:
	var SKIN: Color = look.skin
	var SKIN_L: Color = look.skin_l
	var SKIN_D: Color = look.skin_d
	var HIDE: Color = look.hide
	var IRON: Color = look.iron
	var IRON_L: Color = look.iron_l
	var TRIM: Color = look.trim
	var BONE: Color = look.bone
	var EYE: Color = look.eye
	var stone: bool = look.get("stone", false)
	var WHITE := Color.WHITE
	_root = Node3D.new()
	_root.name = model_name
	_paths = {}
	var root := _root
	root.scale = Vector3.ONE * size
	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.55, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.18, 0.19, 0.17, HIDE.darkened(0.15)], [-0.06, 0.2, 0.175, HIDE], [0.06, 0.2, 0.17, HIDE]], 9)
		var h := p.k("hard")
		h.loft([[0.0, 0.21, 0.18, IRON], [0.07, 0.205, 0.175, IRON_L]], 9)
		h.box(Vector3(0, -0.16, -0.17), Vector3(0.22, 0.3, 0.03), TRIM)
		h.box(Vector3(0, -0.16, 0.17), Vector3(0.22, 0.3, 0.03), TRIM.darkened(0.2))
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.06, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.2, 0.17, SKIN_D], [0.12, 0.25, 0.2, SKIN, Vector2(0, -0.02)],
			[0.26, 0.28, 0.21, SKIN_L, Vector2(0, -0.05)], [0.37, 0.26, 0.18, SKIN, Vector2(0, -0.08)],
			[0.45, 0.15, 0.12, SKIN_D, Vector2(0, -0.12)], [0.48, 0.0, 0.0, SKIN_D, Vector2(0, -0.13)],
		], 10)
		var h := p.k("hard")
		# A great breastplate and pauldrons.
		h.slab(Vector3(0, 0.08, -0.19), Vector2(0.34, 0.05), Vector3(0, 0.38, -0.26), Vector2(0.42, 0.05), IRON)
		h.box(Vector3(0, 0.38, -0.25), Vector3(0.44, 0.05, 0.06), TRIM)
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-18 * sx)), Vector3(0.28 * sx, 0.38, -0.07)))
			h.prism(Vector3(0, -0.05, 0), 0.15, Vector3(0, 0.06, 0), 0.09, 6, IRON_L)
			if not stone:
				h.prism(Vector3(0, 0.06, 0), 0.04, Vector3(0, 0.2, 0), 0.0, 4, BONE)
			h.pop()
		if stone:
			# The eye of starlight in the breastplate, behind a carved lid.
			var g := p.k("glow")
			g.icosa(Vector3(0, 0.24, -0.29), Vector3(0.08, 0.05, 0.02), 0.0, EYE)
			h.box(Vector3(0, 0.3, -0.29), Vector3(0.22, 0.03, 0.03), TRIM)
		else:
			# A chain of trophies over the chest.
			for i in 5:
				h.icosa(Vector3(-0.16 + i * 0.08, 0.28 - absf(i - 2) * 0.03, -0.27), Vector3(0.025, 0.03, 0.02), 0.0, BONE)
	)
	var eye := Marker3D.new()
	eye.name = "Eye"
	eye.position = Vector3(0, 0.24, -0.3)
	torso.add_child(eye)
	_joint(torso, "head", "Head", Vector3(0, 0.42, -0.14), func(p: Parts) -> void:
		var h := p.k("hard")
		if look.face != "":
			var f := p.k(look.face)
			f.loft([
				[-0.02, 0.09, 0.07, WHITE, Vector2(0, -0.07)], [0.02, 0.15, 0.13, WHITE, Vector2(0, -0.05)],
				[0.06, 0.16, 0.15, WHITE, Vector2(0, -0.04)], [0.1, 0.15, 0.155, WHITE, Vector2(0, -0.035)],
				[0.14, 0.14, 0.16, WHITE, Vector2(0, -0.03)], [0.18, 0.15, 0.16, WHITE, Vector2(0, -0.025)],
				[0.22, 0.14, 0.15, WHITE, Vector2(0, -0.01)], [0.26, 0.11, 0.12, WHITE, Vector2(0, 0.0)], [0.3, 0.0, 0.0, WHITE, Vector2(0, 0.01)],
			], 10)
			# A dented iron helm with a nose guard, horns of bone.
			h.prism(Vector3(0, 0.2, -0.01), 0.165, Vector3(0, 0.3, 0.0), 0.11, 8, IRON, PI / 8.0)
			h.box(Vector3(0, 0.16, -0.17), Vector3(0.03, 0.1, 0.02), IRON_L)
			for sx in [-1.0, 1.0]:
				h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-60.0 * sx)), Vector3(0.13 * sx, 0.26, 0.0)))
				h.prism(Vector3.ZERO, 0.05, Vector3(0, 0.16, 0), 0.0, 5, BONE)
				h.pop()
				h.prism(Vector3(0.075 * sx, 0.04, -0.18), 0.02, Vector3(0.085 * sx, 0.13, -0.2), 0.0, 4, BONE)
		else:
			# A great helm of stone: a slit for eyes, a crest.
			h.prism(Vector3(0, -0.02, 0), 0.15, Vector3(0, 0.3, 0), 0.16, 8, IRON, PI / 8.0)
			h.prism(Vector3(0, 0.3, 0), 0.16, Vector3(0, 0.36, 0), 0.06, 8, IRON_L, PI / 8.0)
			h.box(Vector3(0, 0.42, 0.02), Vector3(0.04, 0.16, 0.3), TRIM)
			var g := p.k("glow")
			g.box(Vector3(0, 0.15, -0.155), Vector3(0.18, 0.025, 0.01), EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.31 * side, 0.3, -0.07), func(p: Parts) -> void:
			p.k().loft([
				[0.07, 0.0, 0.0, SKIN], [0.04, 0.1, 0.1, SKIN], [-0.06, 0.11, 0.105, SKIN_L],
				[-0.2, 0.09, 0.09, SKIN], [-0.27, 0.075, 0.075, SKIN_D], [-0.3, 0.0, 0.0, SKIN_D],
			], 7)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.26, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.04, 0.0, 0.0, SKIN_D], [0.01, 0.08, 0.08, SKIN], [-0.09, 0.09, 0.09, SKIN_L], [-0.24, 0.075, 0.075, SKIN], [-0.27, 0.0, 0.0, SKIN_D]], 7)
			var h := p.k("hard")
			h.loft([[-0.08, 0.1, 0.1, IRON], [-0.2, 0.09, 0.09, IRON_L]], 7)
		)
		var hand := _joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.26, 0), func(p: Parts) -> void:
			p.k().loft([[0.02, 0.06, 0.06, SKIN_D], [-0.03, 0.085, 0.09, SKIN_D], [-0.1, 0.08, 0.09, SKIN], [-0.14, 0.055, 0.065, SKIN_D], [-0.155, 0.0, 0.0, SKIN_D]], 6)
		)
		if side > 0:
			_attach(hand, "Club", Vector3(0, -0.07, 0), func(p: Parts) -> void:
				var k := p.k("hard")
				k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
				if look.weapon == "ram":
					# A battering ram for a club: a log banded in iron, a ram's head of iron.
					k.prism(Vector3(0, -0.12, 0), 0.04, Vector3(0, 0.3, 0), 0.05, 7, _c("5a4028"))
					k.prism(Vector3(0, 0.3, 0), 0.11, Vector3(0, 0.95, 0), 0.13, 8, _c("6a4a2a"))
					for y in [0.4, 0.65, 0.9]:
						k.prism(Vector3(0, y, 0), 0.14, Vector3(0, y + 0.05, 0), 0.14, 8, IRON)
					k.prism(Vector3(0, 0.95, 0), 0.15, Vector3(0, 1.08, 0), 0.1, 8, IRON_L)
					for sx in [-1.0, 1.0]:
						k.prism(Vector3(0.08 * sx, 1.02, 0), 0.04, Vector3(0.16 * sx, 1.0, 0.08), 0.0, 4, IRON_L)
				elif look.weapon == "flail":
					# The Jailer's flail (Beta 1.4.0): an iron-bound haft, a heavy
					# chain, and a spiked black ball hanging from it.
					k.prism(Vector3(0, -0.12, 0), 0.04, Vector3(0, 0.34, 0), 0.045, 7, _c("4a3424"))
					for y in [-0.06, 0.12, 0.28]:
						k.prism(Vector3(0, y, 0), 0.05, Vector3(0, y + 0.04, 0), 0.05, 7, IRON)
					for i in 6:
						var t := float(i) / 5.0
						k.icosa(Vector3(0, 0.38 + t * 0.42, -sin(t * PI) * 0.06), Vector3(0.035, 0.035, 0.035), 0.0, IRON_L)
					k.icosa(Vector3(0, 0.98, 0), Vector3(0.17, 0.17, 0.17), 0.0, _c("26262c"), true)
					for d: Vector3 in [Vector3.UP, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
						k.prism(Vector3(0, 0.98, 0) + d * 0.14, 0.05, Vector3(0, 0.98, 0) + d * 0.27, 0.0, 4, IRON_L)
				else:
					# A stone greatsword, gold at the cross.
					k.prism(Vector3(0, -0.12, 0), 0.035, Vector3(0, 0.12, 0), 0.035, 6, _c("5a5048"))
					k.box(Vector3(0, 0.14, 0), Vector3(0.36, 0.05, 0.07), TRIM)
					k.box(Vector3(0, 0.75, 0), Vector3(0.16, 1.2, 0.05), IRON_L)
					k.prism(Vector3(0, 1.35, 0), 0.09, Vector3(0, 1.5, 0), 0.0, 4, IRON_L, PI / 4.0)
				k.pop()
			, "club")
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.13 * side, -0.12, 0), func(p: Parts) -> void:
			p.k().loft([[0.06, 0.0, 0.0, SKIN], [0.04, 0.1, 0.105, SKIN], [-0.06, 0.105, 0.11, SKIN_L], [-0.17, 0.085, 0.09, SKIN], [-0.23, 0.0, 0.0, SKIN_D]], 7)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.2, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.04, 0.0, 0.0, SKIN_D], [0.02, 0.075, 0.08, SKIN], [-0.08, 0.072, 0.078, SKIN], [-0.17, 0.062, 0.068, SKIN_D], [-0.2, 0.0, 0.0, SKIN_D]], 7)
			var h := p.k("hard")
			h.loft([[-0.02, 0.085, 0.09, IRON], [-0.15, 0.078, 0.084, IRON_L]], 7)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.18, 0), func(p: Parts) -> void:
			var k := p.k("hard")
			k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			k.loft([[-0.07, 0.06, 0.045, IRON], [-0.02, 0.085, 0.055, IRON], [0.11, 0.09, 0.05, IRON_L], [0.19, 0.07, 0.035, IRON], [0.21, 0.0, 0.0, IRON]], 6)
			k.pop()
		)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.55, 0)}
	_goblin_anims(lib, rest)
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# Head down, club couched like a ram, legs pounding.
	_anim(lib, "charge", 0.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.52, 0)], [0.1, V.call(0, 0.57, 0)], [0.2, V.call(0, 0.52, 0)], [0.3, V.call(0, 0.57, 0)]],
		"torso": [[0.0, V.call(-45, 0, -3)], [0.2, V.call(-45, 0, 3)]],
		"head": [[0.0, V.call(35, 0, 0)]],
		"shoulder_r": [[0.0, V.call(80, 0, 10)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "hand_r": [[0.0, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(70, 0, -20)]], "elbow_l": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(45, 0, 4)], [0.2, V.call(-30, 0, 4)]], "knee_r": [[0.0, V.call(-20, 0, 0)], [0.1, V.call(-70, 0, 0)], [0.2, V.call(-15, 0, 0)]],
		"leg_l": [[0.0, V.call(-30, 0, -4)], [0.2, V.call(45, 0, -4)]], "knee_l": [[0.0, V.call(-15, 0, 0)], [0.3, V.call(-70, 0, 0)]],
	}, rest)
	# Down on one knee (the guardian's eye bared, the ogre dazed against a wall).
	_anim(lib, "kneel", 1.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.32, 0.05)], [0.6, V.call(0, 0.31, 0.05)]],
		"torso": [[0.0, V.call(15, 0, 0)], [0.6, V.call(18, 0, 3)]],
		"head": [[0.0, V.call(20, 0, 0)], [0.6, V.call(25, 10, 0)]],
		"shoulder_r": [[0.0, V.call(20, 0, 25)]], "elbow_r": [[0.0, V.call(30, 0, 0)]], "hand_r": [[0.0, V.call(-40, 0, 0)]],
		"shoulder_l": [[0.0, V.call(30, 0, -20)]], "elbow_l": [[0.0, V.call(60, 0, 0)]],
		"leg_r": [[0.0, V.call(80, 0, 4)]], "knee_r": [[0.0, V.call(-95, 0, 0)]], "foot_r": [[0.0, V.call(15, 0, 0)]],
		"leg_l": [[0.0, V.call(-5, 0, -4)]], "knee_l": [[0.0, V.call(-90, 0, 0)]], "foot_l": [[0.0, V.call(0, 0, 0)]],
	}, rest)
	# A sweep of the weapon across the front, right to left.
	_anim(lib, "sweep", 0.5, false, {
		"hips@pos": [[0.0, V.call(0, 0.53, 0)]],
		"torso": [[0.0, V.call(-10, -50, 0)], [0.25, V.call(-15, 40, 0)], [0.5, V.call(-12, 45, 0)]],
		"shoulder_r": [[0.0, V.call(80, 0, 70)], [0.25, V.call(80, 0, -10)], [0.5, V.call(70, 0, -20)]], "elbow_r": [[0.0, V.call(20, 0, 0)]], "hand_r": [[0.0, V.call(-90, 0, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, -30)]], "elbow_l": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-15, 0, 8)]], "leg_l": [[0.0, V.call(20, 0, -8)]], "knee_l": [[0.0, V.call(-30, 0, 0)]],
	}, rest)
	_anim(lib, "throw", 0.6, false, {
		"torso": [[0.0, V.call(10, 30, 0)], [0.3, V.call(-30, -20, 0)], [0.6, V.call(-15, 0, 0)]],
		"shoulder_l": [[0.0, V.call(170, 0, -20)], [0.3, V.call(40, 0, -20)], [0.6, V.call(15, 0, -15)]], "elbow_l": [[0.0, V.call(40, 0, 0)], [0.3, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(25, 0, 15)]], "elbow_r": [[0.0, V.call(45, 0, 0)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, file)


# --- Chapter IV's people ----------------------------------------------------------

## Pepper, Posy's dog: a scruffy little black-and-tan terrier, ears up, tail
## going. (No enemy scene: the Pepper script drives the model.)
func _build_pepper() -> void:
	var FUR := _c("2a2420")
	var TAN := _c("b07840")
	_root = Node3D.new()
	_root.name = "PepperModel"
	_paths = {}
	var root := _root
	var head := func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.02, -0.02), Vector3(0.1, 0.09, 0.1), 0.02, FUR, true)
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, -0.01, -0.08)))
		k.loft([[0.0, 0.055, 0.05, TAN], [0.08, 0.04, 0.035, TAN], [0.1, 0.0, 0.0, _c("1a1410")]], 6)
		k.pop()
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx * 0.3, 1, 0), Vector3(0.06 * sx, 0.07, 0.0)))
			k.loft([[0.0, 0.03, 0.015, FUR], [0.08, 0.0, 0.0, FUR]], 4)
			k.pop()
			k.box(Vector3(0.04 * sx, 0.05, -0.09), Vector3(0.025, 0.02, 0.01), TAN)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.04 * sx, 0.03, -0.098), Vector3(0.016, 0.016, 0.008), _c("1a1210"))
	var tail := func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, 1, 0.5), Vector3.ZERO))
		k.loft([[0.0, 0.025, 0.025, FUR], [0.14, 0.0, 0.0, FUR]], 4)
		k.pop()
	_quad(root, 0.26, {"body": [0.42, 0.1, 0.11, FUR, FUR.darkened(0.2)], "head": head, "leg": [0.22, 0.025, TAN, _c("1a1410")], "tail": tail})
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.26, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_quad_anims(lib, rest, 0.26, 40.0, {
		"idle": {"tail": [[0.0, V.call(0, 30, 0)], [0.2, V.call(0, -30, 0)], [0.4, V.call(0, 30, 0)], [0.6, V.call(0, -30, 0)], [0.8, V.call(0, 30, 0)], [1.0, V.call(0, -30, 0)], [1.2, V.call(0, 30, 0)]]},
		"run": {"tail": [[0.0, V.call(20, 0, 0)]]},
	})
	# A happy bark: up on the hind legs a moment.
	_anim(lib, "bark", 0.4, false, {
		"body@pos": [[0.0, V.call(0, 0.26, 0)], [0.12, V.call(0, 0.3, 0)], [0.4, V.call(0, 0.26, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-20, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-25, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"tail": [[0.0, V.call(0, 30, 0)], [0.2, V.call(0, -30, 0)], [0.4, V.call(0, 30, 0)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "pepper.tscn")


## A soldier of the Haven Guard (the captain with a plumed helm and a red
## sash): mail, a blue tabard with Haven's white tower, a round steel helm,
## leather boots.
func _build_haven_guard(model_name: String, file: String, face: String, captain: bool) -> void:
	var SKIN := _c("d8a888") if captain else _c("e8c0a0")
	var SKIN_D := _c("bc8c6c") if captain else _c("cca484")
	var STEEL := _c("8a8e98")
	var STEEL_L := _c("aab0ba")
	var STEEL_D := _c("5e626c")
	var MAIL := _c("6a6e76")
	var TABARD := _c("2a4a9a")
	var TABARD_D := _c("1e3672")
	var LEATHER := _c("6a4a30")
	var TROUSER := _c("4a4a52")
	var HAIR := _c("8a3a22") if captain else _c("5a3a24")
	var hips := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.34, 0.2, 0.18, MAIL.darkened(0.1)], [-0.3, 0.2, 0.18, MAIL], [-0.1, 0.18, 0.155, MAIL], [0.03, 0.15, 0.125, MAIL], [0.07, 0.14, 0.115, MAIL]], 12)
		k.loft([[0.0, 0.152, 0.127, LEATHER], [0.05, 0.146, 0.121, LEATHER]], 12)
		var h := p.k("hard")
		h.box(Vector3(0, -0.18, -0.17), Vector3(0.2, 0.4, 0.01), TABARD)
		h.box(Vector3(0, -0.18, 0.17), Vector3(0.2, 0.4, 0.01), TABARD_D)
		if captain:
			h.box(Vector3(0.1, 0.02, -0.15), Vector3(0.08, 0.2, 0.02), _c("b02a20"))
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.145, 0.118, MAIL], [0.1, 0.15, 0.12, MAIL], [0.19, 0.168, 0.13, MAIL.lightened(0.08)], [0.26, 0.168, 0.12, MAIL], [0.31, 0.14, 0.104, MAIL.darkened(0.1)], [0.35, 0.08, 0.07, MAIL], [0.37, 0.054, 0.054, SKIN]], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.14, -0.136), Vector3(0.2, 0.24, 0.012), TABARD)
		h.box(Vector3(0, 0.14, 0.13), Vector3(0.2, 0.24, 0.012), TABARD_D)
		# The white tower of Haven on the chest.
		h.box(Vector3(0, 0.16, -0.143), Vector3(0.04, 0.09, 0.005), _c("f0f0f4"))
		h.box(Vector3(0, 0.215, -0.143), Vector3(0.07, 0.02, 0.005), _c("f0f0f4"))
		for sx in [-1.0, 1.0]:
			h.box(Vector3(sx * 0.13, 0.31, 0), Vector3(0.11, 0.05, 0.15), STEEL)
		if captain:
			h.slab(Vector3(-0.12, 0.3, -0.13), Vector2(0.03, 0.01), Vector3(0.1, 0.02, -0.14), Vector2(0.03, 0.01), _c("b02a20"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.2), HAIR.lightened(0.2))
		var h := p.k("hard")
		h.prism(Vector3(0, 0.19, 0), 0.124, Vector3(0, 0.27, 0), 0.115, 10, STEEL)
		h.prism(Vector3(0, 0.27, 0), 0.115, Vector3(0, 0.33, 0), 0.03, 10, STEEL_L)
		h.prism(Vector3(0, 0.185, 0), 0.13, Vector3(0, 0.2, 0), 0.13, 10, STEEL_D)
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.115 * sx, 0.13, -0.02), Vector3(0.02, 0.1, 0.08), STEEL)
		if captain:
			for i in 5:
				h.box(Vector3(0, 0.36 + i * 0.012, 0.03 + i * 0.03), Vector3(0.03, 0.05, 0.05), _c("c83a2a"))
	var greave := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, TROUSER], [0.01, 0.048, 0.052, STEEL_D], [-0.18, 0.044, 0.048, STEEL], [-0.24, 0.046, 0.05, LEATHER], [-0.33, 0.04, 0.044, LEATHER], [-0.35, 0.0, 0.0, LEATHER.darkened(0.3)]], 7)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(MAIL, MAIL.lightened(0.1), MAIL.darkened(0.1), STEEL, MAIL, MAIL),
		"forearm": _simple_forearm(MAIL, MAIL, LEATHER),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, LEATHER, LEATHER.darkened(0.2)),
		"thigh": _plain_leg(TROUSER),
		"shin": greave,
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, LEATHER, LEATHER.darkened(0.3), 1.1),
	}
	_build_woman(model_name, file, face, SKIN, SKIN_D, look, _guard_anims, 1.06 if captain else 1.02)


## Haven's soldiers and knights: the townsfolk's idle / talk / happy, and
## (Beta 1.4.0, the knights fighting beside the hero on Black Water Ridge,
## Ally) "walk", "stand", "guard" (sword ready) and "swing" (a cut).
func _guard_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	_townsfolk_anims(lib, rest, false)
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "stand", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"shoulder_r": [[0.0, V.call(6, 0, 8)]], "elbow_r": [[0.0, V.call(14, 0, 0)]],
		"shoulder_l": [[0.0, V.call(4, 0, -6)]], "elbow_l": [[0.0, V.call(12, 0, 0)]],
	}, rest)
	_anim(lib, "walk", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.2, V.call(0, 0.86, 0)], [0.4, V.call(0, 0.84, 0)], [0.6, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.4, V.call(24, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)], [0.4, V.call(-24, 0, 0)]],
		"knee_r": [[0.0, V.call(-8, 0, 0)], [0.2, V.call(-40, 0, 0)], [0.4, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.4, V.call(-8, 0, 0)], [0.6, V.call(-40, 0, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, 10)]], "elbow_r": [[0.0, V.call(50, 0, 0)]], "hand_r": [[0.0, V.call(-40, 0, 0)]],
		"shoulder_l": [[0.0, V.call(-18, 0, -8)], [0.4, V.call(18, 0, -8)]],
	}, rest)
	var ready := {
		"hips@pos": [[0.0, V.call(0, 0.8, 0)], [0.6, V.call(0, 0.79, 0)]],
		"torso": [[0.0, V.call(6, -14, 0)]], "head": [[0.0, V.call(-4, 14, 0)]],
		"shoulder_r": [[0.0, V.call(42, 0, 10)]], "elbow_r": [[0.0, V.call(52, 0, 0)]], "hand_r": [[0.0, V.call(-44, 0, 0)]],
		"shoulder_l": [[0.0, V.call(30, 0, -22)]], "elbow_l": [[0.0, V.call(60, 0, 0)]],
		"leg_r": [[0.0, V.call(12, 0, 8)]], "leg_l": [[0.0, V.call(-14, 0, -8)]],
		"knee_r": [[0.0, V.call(-16, 0, 0)]], "knee_l": [[0.0, V.call(-10, 0, 0)]],
	}
	_anim(lib, "guard", 1.2, true, ready, rest)
	var cut := ready.duplicate()
	cut["torso"] = [[0.0, V.call(6, -14, 0)], [0.22, V.call(0, 30, 0)], [0.32, V.call(10, -34, 0)], [0.6, V.call(6, -14, 0)]]
	cut["shoulder_r"] = [[0.0, V.call(42, 0, 10)], [0.22, V.call(150, 0, 40)], [0.32, V.call(60, -40, -10)], [0.6, V.call(42, 0, 10)]]
	cut["elbow_r"] = [[0.0, V.call(52, 0, 0)], [0.22, V.call(40, 0, 0)], [0.32, V.call(8, 0, 0)], [0.6, V.call(52, 0, 0)]]
	cut["hand_r"] = [[0.0, V.call(-44, 0, 0)], [0.22, V.call(-10, 0, 0)], [0.32, V.call(-20, 0, 0)], [0.6, V.call(-44, 0, 0)]]
	_anim(lib, "swing", 0.6, false, cut, rest)


## Posy, about eight, a refugee of Castle Town: a blue pinafore over a white
## blouse, red shoes, two blonde pigtails tied with ribbons.
func _build_posy() -> void:
	var SKIN := _c("fae0cc")
	var SKIN_D := _c("e2c4b0")
	var DRESS := _c("4a6ac8")
	var DRESS_L := _c("5a7ad8")
	var DRESS_D := _c("3a54a8")
	var BLOUSE := _c("f4f0ec")
	var SHOE := _c("b02a2a")
	var HAIR := _c("e8c060")
	var hips := _skirt_hips(DRESS, DRESS_L, DRESS_D, DRESS_D, 0.28)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.13, 0.105, DRESS_D], [0.1, 0.135, 0.108, DRESS], [0.19, 0.145, 0.115, BLOUSE], [0.26, 0.145, 0.108, BLOUSE], [0.31, 0.12, 0.09, BLOUSE], [0.35, 0.07, 0.062, SKIN_D], [0.37, 0.05, 0.05, SKIN]], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.12, -0.115), Vector3(0.16, 0.16, 0.01), DRESS)
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.2), HAIR.lightened(0.2))
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx, -0.6, 0.2), Vector3(0.12 * sx, 0.2, 0.03)))
			k.loft([[0.0, 0.04, 0.04, HAIR], [0.1, 0.035, 0.035, HAIR.lightened(0.1)], [0.2, 0.0, 0.0, HAIR]], 6)
			k.pop()
			k.icosa(Vector3(0.12 * sx, 0.2, 0.03), Vector3(0.03, 0.03, 0.03), 0.0, _c("d83a5a"))
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(BLOUSE, BLOUSE, BLOUSE.darkened(0.08), BLOUSE, SKIN, SKIN_D),
		"forearm": _simple_forearm(SKIN, SKIN, SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(_c("f0e8e0")),
		"shin": _plain_shin(_c("f0e8e0"), SHOE, SHOE.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, SHOE, SHOE.darkened(0.3)),
	}
	_build_woman("PosyModel", "posy.tscn", "face_posy", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 0.62)
