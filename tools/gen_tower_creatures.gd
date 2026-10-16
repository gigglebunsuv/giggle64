extends "res://tools/gen_creatures.gd"
## The creatures of the Southern Tower (built like gen_creatures.gd):
##
##   strawman     a scarecrow come to life: it hops on its pole after the hero
##                and whirls its stick arms (a little like OoT's scarecrows,
##                and the spinning attacks of EnWallmas-era straw foes)
##   gear_beetle  a beetle under a cog-toothed shell that turns the sword from
##                the front; the Hookshot or the boomerang flips it over
##   rust_knight  the mini-boss: the Tide Knight's armor gone red with rust
##   corvax       the tower's master: a giant harvest crow that circles the
##                roof and swoops; the Hookshot drags it down to the sword
##   rat          cellar rats that scurry in and bite
##   straw_archer a strawman in a red coat that keeps away and flings straw
##                bolts (the shield turns them back)
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_strawman()
	_build_gear_beetle()
	_build_corvax()
	_build_feather()
	_build_rat()
	_build_straw_bolt()
	_tower_scenes()


func _tower_scenes() -> void:
	enemy_scene("strawman", {"script": "res://scripts/enemies/strawman.gd", "model": "strawman", "hp": 4,
		"body": [0.35, 1.9, 0.95], "hurt": [0.5, 2.0, 1.2], "hit": [Vector3(3.6, 1.0, 3.6), Vector3(0, 1.45, 0)], "shadow": 0.45,
		"exports": {"target_offset": 2.1, "boomerang_stun": 2.5, "drop_table": 1}})
	enemy_scene("gear_beetle", {"script": "res://scripts/enemies/gear_beetle.gd", "model": "gear_beetle", "hp": 2,
		"body": [0.5, 0.9, 0.45], "hurt": [0.65, 1.0, 0.45], "hit": [Vector3(1.0, 0.7, 1.0), Vector3(0, 0.4, -0.7)], "shadow": 0.6,
		"exports": {"target_offset": 1.0, "boomerang_stun": 3.0, "drop_table": 1}})
	enemy_scene("rust_knight", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 16,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(1.0, 0.62, 0.45),
			"title_name": "RUST KNIGHT", "title_epithet": "Keeper of the Mill"}})
	enemy_scene("rat", {"script": "res://scripts/enemies/rat.gd", "model": "rat", "hp": 1,
		"body": [0.25, 0.5, 0.25], "hurt": [0.4, 0.8, 0.3], "hit": [Vector3(0.6, 0.5, 0.7), Vector3(0, 0.25, -0.5)], "shadow": 0.35,
		"exports": {"target_offset": 0.6, "boomerang_stun": 4.0, "boomerang_damage": 1, "drop_table": 1}})
	enemy_scene("straw_archer", {"script": "res://scripts/enemies/straw_archer.gd", "model": "strawman", "hp": 3,
		"body": [0.35, 1.9, 0.95], "hurt": [0.5, 2.0, 1.2], "shadow": 0.45,
		"exports": {"target_offset": 2.1, "boomerang_stun": 2.5, "drop_table": 1, "tint": Color(1.25, 0.6, 0.55)}})
	enemy_scene("corvax", {"script": "res://scripts/enemies/corvax.gd", "model": "corvax", "hp": 10, "floating": true,
		"body": [1.1, 2.2, 0.0], "hurt": [1.5, 3.0, 0.0], "hit": [Vector3(3.0, 1.6, 3.0), Vector3(0, -0.6, -0.5)], "shadow": 2.0,
		"exports": {"target_offset": 0.6, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Strawman -------------------------------------------------------------------

## A scarecrow on a single pole: a stuffed burlap body in a patched blue shirt,
## a sack head with a stitched grin and button eyes under a floppy straw hat,
## and two stick arms tufted with straw.
func _build_strawman() -> void:
	var SACK := _c("c8a870")
	var SACK_D := _c("a88a54")
	var SHIRT := _c("4a6aa8")
	var SHIRT_D := _c("34508a")
	var PATCH := _c("c84a3a")
	var STRAW := _c("e8cc6a")
	var STRAW_D := _c("c8a848")
	var WOOD := _c("6a4a2a")
	var HAT := _c("d8b860")
	_root = Node3D.new()
	_root.name = "StrawmanModel"
	_paths = {}
	var root := _root
	var hips := _joint(root, "hips", "Hips", Vector3(0, 1.05, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.15, 0.2, 0.17, SHIRT_D], [0.0, 0.24, 0.2, SHIRT], [0.3, 0.26, 0.21, SHIRT], [0.5, 0.2, 0.16, SHIRT_D], [0.56, 0.0, 0.0, SHIRT_D]], 8)
		var h := p.k("hard")
		h.box(Vector3(0.1, 0.25, -0.2), Vector3(0.12, 0.12, 0.02), PATCH)
		h.box(Vector3(0, -0.02, 0), Vector3(0.5, 0.06, 0.42), _c("5a3a22"))
		# Straw poking out at the waist and collar.
		for i in 10:
			var a := TAU * i / 10.0
			h.prism(Vector3(cos(a) * 0.2, -0.15, sin(a) * 0.16), 0.03, Vector3(cos(a) * 0.26, -0.32, sin(a) * 0.22), 0.0, 3, STRAW)
	)
	_joint(hips, "head", "Head", Vector3(0, 0.62, 0), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.16, 0), Vector3(0.2, 0.21, 0.19), 0.12, SACK, true)
		k.prism(Vector3(0, -0.02, 0), 0.07, Vector3(0, 0.05, 0), 0.1, 6, SACK_D)
		var h := p.k("hard")
		# Button eyes and a stitched grin.
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.075 * sx, 0.2, -0.17), 0.035, Vector3(0.075 * sx, 0.2, -0.2), 0.035, 6, _c("1a1a22"))
		for i in 7:
			var x := -0.09 + i * 0.03
			h.box(Vector3(x, 0.09 - absf(x) * 0.25, -0.188), Vector3(0.022, 0.008, 0.01), _c("2a1a12"))
			h.box(Vector3(x, 0.09 - absf(x) * 0.25, -0.19), Vector3(0.004, 0.03, 0.01), _c("2a1a12"))
		# The floppy straw hat.
		h.prism(Vector3(0, 0.3, 0), 0.34, Vector3(0, 0.33, 0), 0.32, 10, HAT)
		h.prism(Vector3(0, 0.33, 0), 0.15, Vector3(0, 0.46, 0.02), 0.12, 8, HAT)
		h.prism(Vector3(0, 0.34, 0), 0.155, Vector3(0, 0.37, 0), 0.155, 8, PATCH)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		_joint(hips, "shoulder" + sfx, "Shoulder" + ("R" if side > 0 else "L"), Vector3(0.2 * side, 0.42, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			# A stick arm straight out, with a straw tuft for a hand.
			h.prism(Vector3(0, 0, 0), 0.04, Vector3(0.95 * side, 0.02, 0), 0.03, 5, WOOD)
			p.k().loft([[0.05, 0.075, 0.075, SHIRT], [0.35, 0.065, 0.065, SHIRT_D], [0.4, 0.0, 0.0, SHIRT_D]], 6)
			for i in 6:
				var a := TAU * i / 6.0
				h.prism(Vector3(0.95 * side, 0.02, 0), 0.025, Vector3((1.12 + cos(a) * 0.03) * side, 0.02 + sin(a) * 0.1, cos(a) * 0.1), 0.0, 3, STRAW_D)
		)
	_joint(hips, "pole", "Pole", Vector3(0, -0.05, 0), func(p: Parts) -> void:
		p.k("hard").prism(Vector3(0, 0, 0), 0.06, Vector3(0, -1.0, 0), 0.05, 6, WOOD)
	)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 1.05, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.0, true, {
		"hips": [[0.0, V.call(0, 0, 3)], [1.0, V.call(0, 0, -3)]],
		"head": [[0.0, V.call(6, 10, 4)], [1.0, V.call(4, -10, -4)]],
		"shoulder_r": [[0.0, V.call(0, 0, -6)], [1.0, V.call(0, 0, 4)]], "shoulder_l": [[0.0, V.call(0, 0, 6)], [1.0, V.call(0, 0, -4)]],
	}, rest)
	# A hop on the pole: crouch, spring, land.
	_anim(lib, "hop", 0.5, true, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0)], [0.12, V.call(0, 1.0, 0)], [0.3, V.call(0, 1.45, 0)], [0.5, V.call(0, 1.0, 0)]],
		"hips": [[0.0, V.call(-8, 0, 0)], [0.3, V.call(6, 0, 0)], [0.5, V.call(-8, 0, 0)]],
		"head": [[0.0, V.call(-10, 0, 0)], [0.3, V.call(12, 0, 0)]],
		"shoulder_r": [[0.0, V.call(0, 0, -20)], [0.3, V.call(0, 0, 25)]], "shoulder_l": [[0.0, V.call(0, 0, 20)], [0.3, V.call(0, 0, -25)]],
	}, rest)
	_anim(lib, "windup", 0.6, false, {
		"hips": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 70, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-10, -50, 0)]],
		"shoulder_r": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 18)]], "shoulder_l": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, -18)]],
	}, rest)
	var spin := {"hips": []}
	for i in 9:
		spin["hips"].append([i * 0.1, V.call(0, 70 - i * 90, 0)])
	spin["shoulder_r"] = [[0.0, V.call(0, 0, 10)]]
	spin["shoulder_l"] = [[0.0, V.call(0, 0, -10)]]
	spin["head"] = [[0.0, V.call(15, 0, 0)]]
	_anim(lib, "spin", 0.8, false, spin, rest)
	_anim(lib, "stunned", 0.8, true, {
		"hips": [[0.0, V.call(0, 0, 14)], [0.4, V.call(0, 0, -14)]],
		"head": [[0.0, V.call(25, 0, 20)], [0.4, V.call(25, 0, -20)]],
		"shoulder_r": [[0.0, V.call(0, 0, -50)]], "shoulder_l": [[0.0, V.call(0, 0, 50)]],
	}, rest)
	_anim(lib, "death", 0.9, false, {
		"hips@pos": [[0.0, V.call(0, 1.05, 0)], [0.9, V.call(0, 0.25, 0.3)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.9, V.call(85, 0, 10)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.9, V.call(30, 30, 0)]],
		"shoulder_r": [[0.0, V.call(0, 0, 0)], [0.9, V.call(0, 0, -40)]], "shoulder_l": [[0.0, V.call(0, 0, 0)], [0.9, V.call(0, 0, 30)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "strawman.tscn")


# --- Gear Beetle ----------------------------------------------------------------

## A squat brass-and-iron beetle under a domed shell ringed with cog teeth,
## a horned head with pincers, and six short legs.
func _build_gear_beetle() -> void:
	var SHELL := _c("8a6a3a")
	var SHELL_L := _c("b08a4a")
	var IRON := _c("4a4a52")
	var BELLY := _c("c8b890")
	var EYE := _c("ff6a2a")
	_root = Node3D.new()
	_root.name = "GearBeetleModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.42, 0), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.08, 0.05), Vector3(0.5, 0.3, 0.55), 0.04, SHELL, true)
		k.icosa(Vector3(0, -0.06, 0.05), Vector3(0.42, 0.14, 0.48), 0.04, BELLY, true)
		var h := p.k("hard")
		# The cog teeth round the shell's rim and a hub on top.
		for i in 12:
			var a := TAU * i / 12.0
			h.push(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 0.5, 0.02, 0.05 + sin(a) * 0.55)))
			h.box(Vector3.ZERO, Vector3(0.14, 0.1, 0.1), IRON)
			h.pop()
		h.prism(Vector3(0, 0.3, 0.05), 0.16, Vector3(0, 0.4, 0.05), 0.12, 8, SHELL_L)
		h.prism(Vector3(0, 0.4, 0.05), 0.05, Vector3(0, 0.44, 0.05), 0.05, 6, IRON)
	)
	_joint(body, "head", "Head", Vector3(0, 0.0, -0.5), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.02, -0.12), Vector3(0.2, 0.14, 0.17), 0.05, IRON, true)
		var h := p.k("hard")
		h.prism(Vector3(0, 0.1, -0.2), 0.04, Vector3(0, 0.3, -0.32), 0.0, 4, SHELL_L)
		for sx in [-1.0, 1.0]:
			h.push(_aim(Vector3(0.4 * sx, -0.1, -1), Vector3(0.1 * sx, -0.02, -0.24)))
			h.prism(Vector3.ZERO, 0.035, Vector3(0, 0.16, 0), 0.0, 4, IRON)
			h.pop()
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.1 * sx, 0.07, -0.25), Vector3(0.035, 0.035, 0.03), 0.0, EYE)
	)
	for i in 6:
		var side := 1.0 if i < 3 else -1.0
		var z := -0.25 + (i % 3) * 0.25
		_joint(body, "leg_%d" % i, "Leg%d" % i, Vector3(0.35 * side, -0.08, z), func(p: Parts) -> void:
			var h := p.k("hard")
			h.prism(Vector3.ZERO, 0.04, Vector3(0.22 * side, 0.05, 0), 0.035, 4, IRON)
			h.prism(Vector3(0.22 * side, 0.05, 0), 0.035, Vector3(0.3 * side, -0.34, 0), 0.015, 4, IRON)
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.42, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 1.2, true, {
		"body@pos": [[0.0, V.call(0, 0.42, 0)], [0.6, V.call(0, 0.4, 0)]],
		"head": [[0.0, V.call(0, 6, 0)], [0.6, V.call(0, -6, 0)]],
	}, rest)
	var walk := {"body@pos": [[0.0, V.call(0, 0.42, 0)], [0.1, V.call(0, 0.45, 0)], [0.2, V.call(0, 0.42, 0)], [0.3, V.call(0, 0.45, 0)]]}
	for i in 6:
		var a := 1.0 if (i % 2 == 0) == (i < 3) else -1.0
		walk["leg_%d" % i] = [[0.0, V.call(0, 25 * a, 0)], [0.2, V.call(0, -25 * a, 0)]]
	_anim(lib, "walk", 0.4, true, walk, rest)
	var charge := walk.duplicate(true)
	charge["body"] = [[0.0, V.call(-10, 0, 0)]]
	charge["head"] = [[0.0, V.call(-15, 0, 0)]]
	_anim(lib, "charge", 0.2, true, charge, rest)
	# Flipped on its back, legs kicking in the air.
	var flipped := {"body@pos": [[0.0, V.call(0, 0.5, 0)]], "body": [[0.0, V.call(0, 0, 180)], [0.3, V.call(0, 0, 172)], [0.6, V.call(0, 0, 188)]]}
	for i in 6:
		flipped["leg_%d" % i] = [[0.0, V.call(0, 0, 30 if i < 3 else -30)], [0.15, V.call(0, 0, -10 if i < 3 else 10)], [0.3, V.call(0, 0, 30 if i < 3 else -30)]]
	_anim(lib, "flipped", 0.6, true, flipped, rest)
	_anim(lib, "stunned", 0.6, true, flipped, rest)
	_anim(lib, "death", 0.6, false, {
		"body@pos": [[0.0, V.call(0, 0.5, 0)], [0.6, V.call(0, 0.25, 0)]],
		"body": [[0.0, V.call(0, 0, 180)], [0.6, V.call(0, 0, 180)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "gear_beetle.tscn")


# --- Corvax ---------------------------------------------------------------------

## The Harvest Crow: a giant black crow with a ragged ruff, a pale bone-like
## beak, three burning red eyes, wings six meters across and a fan tail. A
## frayed red harvest ribbon is tied round one leg. "Body" is its center.
func _build_corvax() -> void:
	var BLACK := _c("1e1a26")
	var BLACK_L := _c("2e2a3a")
	var SHEEN := _c("3a3a5a")
	var BEAK := _c("d8d0b8")
	var BEAK_D := _c("a8a088")
	var EYE := _c("ff3a2a")
	var TALON := _c("4a4038")
	var RIBBON := _c("c83a2a")
	_root = Node3D.new()
	_root.name = "CorvaxModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		k.loft([[-1.0, 0.0, 0.0, BLACK], [-0.85, 0.42, 0.45, BLACK_L], [-0.4, 0.62, 0.66, BLACK], [0.2, 0.55, 0.6, SHEEN], [0.75, 0.3, 0.32, BLACK], [1.0, 0.0, 0.0, BLACK]], 10)
		k.pop()
		# The ragged ruff round the neck.
		var h := p.k("hard")
		for i in 12:
			var a := TAU * i / 12.0
			h.prism(Vector3(cos(a) * 0.45, sin(a) * 0.45, -0.8), 0.12, Vector3(cos(a) * 0.65, sin(a) * 0.62, -0.55), 0.0, 3, BLACK_L)
	)
	_joint(body, "head", "Head", Vector3(0, 0.3, -1.0), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.05, -0.15), Vector3(0.4, 0.38, 0.45), 0.06, BLACK, true)
		var h := p.k("hard")
		# The long pale beak, a little open.
		h.push(_aim(Vector3(0, -0.15, -1), Vector3(0, 0.02, -0.5)))
		h.loft([[0.0, 0.16, 0.12, BEAK_D], [0.35, 0.1, 0.08, BEAK], [0.75, 0.0, 0.0, BEAK]], 6)
		h.pop()
		h.push(_aim(Vector3(0, -0.45, -1), Vector3(0, -0.06, -0.48)))
		h.loft([[0.0, 0.12, 0.08, BEAK_D], [0.5, 0.0, 0.0, BEAK_D]], 6)
		h.pop()
		# A crest of feathers.
		for i in 4:
			h.prism(Vector3(0, 0.38, 0.0 + i * 0.1), 0.06, Vector3(0, 0.62 - i * 0.05, 0.25 + i * 0.12), 0.0, 3, BLACK_L)
		var g := p.k("glow")
		for e in [Vector3(0.24, 0.18, -0.38), Vector3(-0.24, 0.18, -0.38), Vector3(0, 0.32, -0.44)]:
			g.icosa(e, Vector3(0.07, 0.06, 0.04), 0.0, EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nm := "R" if side > 0 else "L"
		var wing := _joint(body, "wing" + sfx, "Wing" + nm, Vector3(0.5 * side, 0.3, -0.3), func(p: Parts) -> void:
			var k := p.k()
			# The inner wing: an arm bone and a sheet of long feathers trailing behind.
			k.prism(Vector3.ZERO, 0.16, Vector3(1.5 * side, 0.05, 0.1), 0.1, 6, BLACK_L)
			for i in 6:
				var x: float = (0.15 + i * 0.25) * side
				k.face_dir([Vector3(x, 0.02, 0.0), Vector3(x + 0.26 * side, 0.02, 0.05), Vector3(x + 0.2 * side, 0.0, 1.0 - i * 0.06)], BLACK if i % 2 == 0 else SHEEN, Vector3.UP)
				k.face_dir([Vector3(x, 0.0, 0.0), Vector3(x + 0.26 * side, 0.0, 0.05), Vector3(x + 0.2 * side, -0.02, 1.0 - i * 0.06)], BLACK, Vector3.DOWN)
		)
		_joint(wing, "tip" + sfx, "Tip" + nm, Vector3(1.5 * side, 0.05, 0.1), func(p: Parts) -> void:
			var k := p.k()
			k.prism(Vector3.ZERO, 0.1, Vector3(1.4 * side, 0.0, 0.3), 0.04, 5, BLACK_L)
			# The long primaries fanning out to the tip.
			for i in 5:
				var x: float = (0.1 + i * 0.28) * side
				var tip: Vector3 = Vector3((1.5 + i * 0.08) * side, -0.02, 0.4 + i * 0.12) if i == 4 else Vector3(x + 0.35 * side, 0.0, 1.1 - i * 0.12)
				k.face_dir([Vector3(x, 0.02, 0.0), Vector3(x + 0.3 * side, 0.02, 0.06), tip], SHEEN if i % 2 else BLACK, Vector3.UP)
				k.face_dir([Vector3(x, 0.0, 0.0), Vector3(x + 0.3 * side, 0.0, 0.06), tip], BLACK, Vector3.DOWN)
		)
		_joint(body, "leg" + sfx, "Leg" + nm, Vector3(0.25 * side, -0.45, 0.25), func(p: Parts) -> void:
			var h := p.k("hard")
			h.prism(Vector3.ZERO, 0.08, Vector3(0, -0.6, 0), 0.06, 5, TALON)
			for i in 3:
				var a := -0.5 + i * 0.5
				h.prism(Vector3(0, -0.6, 0), 0.04, Vector3(sin(a) * 0.3, -0.75, -cos(a) * 0.3), 0.0, 4, TALON)
			h.prism(Vector3(0, -0.6, 0), 0.04, Vector3(0, -0.7, 0.25), 0.0, 4, TALON)
			if side > 0:
				h.prism(Vector3(0, -0.3, 0), 0.1, Vector3(0, -0.4, 0), 0.1, 6, RIBBON)
				h.prism(Vector3(0.05, -0.36, 0.08), 0.05, Vector3(0.3, -0.7, 0.4), 0.02, 3, RIBBON)
		)
	_joint(body, "tail", "Tail", Vector3(0, 0.05, 0.95), func(p: Parts) -> void:
		var k := p.k()
		for i in 7:
			var a := -0.6 + i * 0.2
			k.face_dir([Vector3(0, 0, 0), Vector3(sin(a) * 1.1 - 0.1, 0, cos(a) * 1.1), Vector3(sin(a) * 1.1 + 0.1, 0, cos(a) * 1.1)], BLACK if i % 2 else SHEEN, Vector3.UP)
			k.face_dir([Vector3(0, -0.01, 0), Vector3(sin(a) * 1.1 - 0.1, -0.01, cos(a) * 1.1), Vector3(sin(a) * 1.1 + 0.1, -0.01, cos(a) * 1.1)], BLACK, Vector3.DOWN)
	)
	var lib := _bird_anims()
	_finish_character(root, lib)
	_save_scene(root, "corvax.tscn")


## One of Corvax's flung feathers: a long black quill with a pale shaft.
func _build_feather() -> void:
	var k := MeshKit.new(4441)
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.3, 0), 0.015, Vector3(0, 0.35, 0), 0.008, 4, _c("d8d0b8"))
	k.pop()
	k.face_dir([Vector3(0, 0, 0.25), Vector3(0.09, 0, -0.1), Vector3(0, 0, -0.32)], _c("1e1a26"), Vector3.UP)
	k.face_dir([Vector3(0, 0, 0.25), Vector3(-0.09, 0, -0.1), Vector3(0, 0, -0.32)], _c("2e2a3a"), Vector3.UP)
	k.face_dir([Vector3(0, -0.005, 0.25), Vector3(0.09, -0.005, -0.1), Vector3(0, -0.005, -0.32)], _c("1e1a26"), Vector3.DOWN)
	k.face_dir([Vector3(0, -0.005, 0.25), Vector3(-0.09, -0.005, -0.1), Vector3(0, -0.005, -0.32)], _c("2e2a3a"), Vector3.DOWN)
	var err := ResourceSaver.save(k.build(_mats.char), MODEL_DIR + "feather_mesh.tres")
	if err != OK:
		push_error("Failed to save the feather")


# --- Rat ------------------------------------------------------------------------

## A fat gray cellar rat: a pear-shaped body, a pointed snout with whiskers
## and a pink nose, round pink ears, red eyes, little legs and a long tail.
func _build_rat() -> void:
	var FUR := _c("7a7268")
	var FUR_L := _c("9a9288")
	var FUR_D := _c("5a524a")
	var PINK := _c("e89a9a")
	_root = Node3D.new()
	_root.name = "RatModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.22, 0), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, 0, -1), Vector3(0, 0, 0.3)))
		k.loft([[0.0, 0.0, 0.0, FUR_D], [0.08, 0.14, 0.13, FUR_D], [0.25, 0.2, 0.18, FUR], [0.45, 0.17, 0.16, FUR_L], [0.58, 0.1, 0.1, FUR], [0.62, 0.0, 0.0, FUR]], 8)
		k.pop()
	)
	_joint(body, "head", "Head", Vector3(0, 0.04, -0.3), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.15, -1), Vector3(0, 0, 0.02)))
		k.loft([[0.0, 0.1, 0.1, FUR], [0.1, 0.1, 0.09, FUR_L], [0.22, 0.04, 0.04, FUR_L], [0.25, 0.0, 0.0, FUR]], 8)
		k.pop()
		var h := p.k("hard")
		h.icosa(Vector3(0, -0.02, -0.25), Vector3(0.025, 0.02, 0.02), 0.0, PINK)
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.UP, 0.3 * sx), Vector3(0.07 * sx, 0.09, 0.0)))
			h.prism(Vector3.ZERO, 0.055, Vector3(0, 0.015, 0), 0.055, 8, PINK)
			h.pop()
			for w in [-1.0, 1.0]:
				h.prism(Vector3(0.03 * sx, -0.01, -0.21), 0.004, Vector3(0.13 * sx, -0.01 + 0.02 * w, -0.18), 0.002, 3, _c("e8e0d8"))
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.055 * sx, 0.05, -0.1), Vector3(0.02, 0.02, 0.018), 0.0, _c("e83030"))
	)
	_joint(body, "tail", "Tail", Vector3(0, -0.02, 0.32), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.2, 1), Vector3.ZERO))
		k.loft([[0.0, 0.035, 0.035, PINK], [0.25, 0.022, 0.022, PINK], [0.5, 0.008, 0.008, PINK]], 5)
		k.pop()
	)
	for leg in [["leg_fl", Vector3(-0.1, -0.1, -0.18)], ["leg_fr", Vector3(0.1, -0.1, -0.18)], ["leg_bl", Vector3(-0.12, -0.1, 0.18)], ["leg_br", Vector3(0.12, -0.1, 0.18)]]:
		_joint(body, leg[0], String(leg[0]).to_pascal_case(), leg[1], func(p: Parts) -> void:
			var h := p.k("hard")
			h.prism(Vector3.ZERO, 0.035, Vector3(0, -0.11, 0), 0.025, 5, FUR_D)
			h.box(Vector3(0, -0.12, -0.03), Vector3(0.05, 0.02, 0.07), PINK)
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.22, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 0.8, true, {
		"head": [[0.0, V.call(5, 10, 0)], [0.2, V.call(-5, 0, 0)], [0.4, V.call(5, -10, 0)], [0.6, V.call(-5, 0, 0)]],
		"tail": [[0.0, V.call(0, 15, 0)], [0.4, V.call(0, -15, 0)]],
	}, rest)
	_anim(lib, "run", 0.24, true, {
		"body@pos": [[0.0, V.call(0, 0.22, 0)], [0.06, V.call(0, 0.27, 0)], [0.12, V.call(0, 0.22, 0)], [0.18, V.call(0, 0.27, 0)]],
		"leg_fl": [[0.0, V.call(40, 0, 0)], [0.12, V.call(-40, 0, 0)]], "leg_fr": [[0.0, V.call(-40, 0, 0)], [0.12, V.call(40, 0, 0)]],
		"leg_bl": [[0.0, V.call(-40, 0, 0)], [0.12, V.call(40, 0, 0)]], "leg_br": [[0.0, V.call(40, 0, 0)], [0.12, V.call(-40, 0, 0)]],
		"tail": [[0.0, V.call(10, 20, 0)], [0.12, V.call(10, -20, 0)]],
	}, rest)
	_anim(lib, "bite", 0.35, false, {
		"body@pos": [[0.0, V.call(0, 0.22, 0)], [0.1, V.call(0, 0.4, -0.1)], [0.35, V.call(0, 0.22, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.1, V.call(15, 0, 0)], [0.35, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-25, 0, 0)], [0.2, V.call(10, 0, 0)], [0.35, V.call(0, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.6, true, {"body": [[0.0, V.call(0, 0, 160)], [0.3, V.call(0, 0, 175)]], "leg_fl": [[0.0, V.call(30, 0, 0)], [0.3, V.call(-30, 0, 0)]], "leg_br": [[0.0, V.call(-30, 0, 0)], [0.3, V.call(30, 0, 0)]]}, rest)
	_anim(lib, "death", 0.5, false, {"body": [[0.0, V.call(0, 0, 0)], [0.3, V.call(0, 0, 175)]], "body@pos": [[0.0, V.call(0, 0.22, 0)], [0.2, V.call(0, 0.5, 0)], [0.5, V.call(0, 0.1, 0)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "rat.tscn")


## A straw bolt: a sharpened stake with a tuft of straw for a flight.
func _build_straw_bolt() -> void:
	var k := MeshKit.new(78)
	k.prism(Vector3(0, 0, 0.25), 0.025, Vector3(0, 0, -0.2), 0.025, 5, _c("8a6a3a"))
	k.prism(Vector3(0, 0, -0.2), 0.025, Vector3(0, 0, -0.32), 0.0, 5, _c("c8b080"))
	for i in 5:
		var a := TAU * i / 5.0
		k.prism(Vector3(0, 0, 0.18), 0.012, Vector3(cos(a) * 0.07, sin(a) * 0.07, 0.36), 0.004, 3, _c("e8cc6a"))
	k.smooth_normals(50.0)
	_save_res(k.build(_mats.char), "straw_bolt_mesh.tres")


## The great birds' animations (Corvax, and Skyreach's ice wyvern, built on
## the same joints): fly, hover, swoop, screech, grounded, death.
func _bird_anims() -> AnimationLibrary:
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Flying: slow, heavy beats.
	_anim(lib, "fly", 0.9, true, {
		"body@pos": [[0.0, V.call(0, -0.15, 0)], [0.45, V.call(0, 0.15, 0)]],
		"wing_r": [[0.0, V.call(0, 0, 35)], [0.45, V.call(0, 0, -30)]], "wing_l": [[0.0, V.call(0, 0, -35)], [0.45, V.call(0, 0, 30)]],
		"tip_r": [[0.0, V.call(0, 0, 20)], [0.45, V.call(0, 0, -25)]], "tip_l": [[0.0, V.call(0, 0, -20)], [0.45, V.call(0, 0, 25)]],
		"leg_r": [[0.0, V.call(60, 0, 0)]], "leg_l": [[0.0, V.call(60, 0, 0)]],
		"head": [[0.0, V.call(-6, 0, 0)], [0.45, V.call(4, 0, 0)]],
	}, rest)
	# Hovering: fast beats, body upright-ish, talons forward.
	_anim(lib, "hover", 0.45, true, {
		"body": [[0.0, V.call(25, 0, 0)]],
		"wing_r": [[0.0, V.call(0, 0, 55)], [0.22, V.call(0, 0, -25)]], "wing_l": [[0.0, V.call(0, 0, -55)], [0.22, V.call(0, 0, 25)]],
		"tip_r": [[0.0, V.call(0, 0, 30)], [0.22, V.call(0, 0, -30)]], "tip_l": [[0.0, V.call(0, 0, -30)], [0.22, V.call(0, 0, 30)]],
		"leg_r": [[0.0, V.call(-20, 0, 0)]], "leg_l": [[0.0, V.call(-20, 0, 0)]],
		"head": [[0.0, V.call(-25, 0, 0)]],
	}, rest)
	# Swooping: wings swept back, talons reaching forward.
	_anim(lib, "swoop", 0.4, true, {
		"body": [[0.0, V.call(-15, 0, 0)], [0.2, V.call(-12, 0, 0)]],
		"wing_r": [[0.0, V.call(0, -55, 10)], [0.2, V.call(0, -50, 4)]], "wing_l": [[0.0, V.call(0, 55, -10)], [0.2, V.call(0, 50, -4)]],
		"tip_r": [[0.0, V.call(0, -30, 0)], [0.2, V.call(0, -40, 8)]], "tip_l": [[0.0, V.call(0, 30, 0)], [0.2, V.call(0, 40, -8)]],
		"leg_r": [[0.0, V.call(-60, 0, 0)], [0.2, V.call(-66, 0, 0)]], "leg_l": [[0.0, V.call(-60, 0, 0)], [0.2, V.call(-66, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.2, V.call(6, 0, 0)]],
	}, rest)
	_anim(lib, "screech", 1.0, false, {
		"body": [[0.0, V.call(20, 0, 0)], [0.5, V.call(30, 0, 0)], [1.0, V.call(20, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.3, V.call(45, 0, 0)], [0.8, V.call(40, 0, 0)], [1.0, V.call(0, 0, 0)]],
		"wing_r": [[0.0, V.call(0, 0, 40)], [0.3, V.call(0, 0, 70)], [1.0, V.call(0, 0, 40)]], "wing_l": [[0.0, V.call(0, 0, -40)], [0.3, V.call(0, 0, -70)], [1.0, V.call(0, 0, -40)]],
	}, rest)
	# Dragged down: sprawled on the floor, wings flailing, head lolling.
	_anim(lib, "grounded", 0.8, true, {
		"body@pos": [[0.0, V.call(0, -0.2, 0)]],
		"body": [[0.0, V.call(-10, 0, 8)], [0.4, V.call(-10, 0, -8)]],
		"wing_r": [[0.0, V.call(0, 0, -10)], [0.2, V.call(0, 0, 20)], [0.4, V.call(0, 0, -10)]], "wing_l": [[0.0, V.call(0, 0, 10)], [0.2, V.call(0, 0, -20)], [0.4, V.call(0, 0, 10)]],
		"tip_r": [[0.0, V.call(0, 0, -20)]], "tip_l": [[0.0, V.call(0, 0, 20)]],
		"head": [[0.0, V.call(-30, 20, 15)], [0.4, V.call(-30, -20, -15)]],
		"leg_r": [[0.0, V.call(90, 0, 0)]], "leg_l": [[0.0, V.call(90, 0, 0)]],
	}, rest)
	_anim(lib, "death", 1.6, false, {
		"body@pos": [[0.0, V.call(0, 0, 0)], [1.6, V.call(0, -0.3, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.8, V.call(-20, 30, 60)], [1.6, V.call(-10, 40, 90)]],
		"wing_r": [[0.0, V.call(0, 0, 40)], [1.6, V.call(0, 0, -30)]], "wing_l": [[0.0, V.call(0, 0, -40)], [1.6, V.call(0, 0, 60)]],
		"head": [[0.0, V.call(0, 0, 0)], [1.6, V.call(-40, 40, 0)]],
	}, rest)
	return lib
