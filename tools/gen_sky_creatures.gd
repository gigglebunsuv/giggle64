extends "res://tools/gen_tower_creatures.gd"
## The creatures of Skyreach Spire (built like gen_creatures.gd):
##
##   freezard     a lump of living ice that breathes freezing mist (OoT's EnFz)
##   ice_keese    keese in frost-white
##   wind_wisp    a little cloud that blows gusts at the hero
##   frost_knight the first mini-boss: the Tide Knight's armor iced over
##   wyvern       the second mini-boss: Frostwing, an ice wyvern (on the great
##                birds' joints, so it flies with Corvax's AI and animations)
##   storm_eye    Aeolos the Storm Eye, the boss: one great eye in a shell of
##                four plates of storm-cloud ice
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_freezard()
	_build_wisp()
	_build_wyvern()
	_build_storm_eye()
	_build_icicle()
	_sky_scenes()


func _sky_scenes() -> void:
	enemy_scene("freezard", {"script": "res://scripts/enemies/freezard.gd", "model": "freezard", "hp": 4,
		"body": [0.6, 1.8, 0.9], "hurt": [0.7, 2.0, 1.0], "hit": [Vector3(1.6, 1.4, 3.2), Vector3(0, 1.0, -2.2)], "shadow": 0.7,
		"exports": {"target_offset": 2.0, "boomerang_stun": 0.0, "drop_table": 1}})
	enemy_scene("ice_keese", {"script": "res://scripts/enemies/keese.gd", "model": "keese", "hp": 1, "floating": true,
		"body": [0.25, 0.5, 0.0], "hurt": [0.4, 0.8, 0.0], "hit": [Vector3(0.7, 0.6, 0.7), Vector3(0, 0, 0)], "shadow": 0.3,
		"exports": {"target_offset": 0.3, "boomerang_stun": 4.0, "boomerang_damage": 1, "tint": Color(0.75, 1.0, 1.5)}})
	enemy_scene("wind_wisp", {"script": "res://scripts/enemies/wind_wisp.gd", "model": "wind_wisp", "hp": 2, "floating": true,
		"body": [0.4, 0.8, 0.0], "hurt": [0.6, 1.2, 0.0], "shadow": 0.4,
		"exports": {"target_offset": 0.4, "boomerang_stun": 2.0, "boomerang_damage": 1, "drop_table": 1}})
	enemy_scene("frost_knight", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 16,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(0.8, 1.05, 1.4), "start_rate": 1.15}})
	enemy_scene("wyvern", {"script": "res://scripts/enemies/corvax.gd", "model": "wyvern", "hp": 12, "floating": true,
		"body": [1.1, 2.2, 0.0], "hurt": [1.5, 3.0, 0.0], "hit": [Vector3(3.0, 1.6, 3.0), Vector3(0, -0.6, -0.5)], "shadow": 2.0,
		"exports": {"target_offset": 0.6, "boomerang_stun": 0.0, "drop_table": 11, "title": "", "music": "", "circle_r": 7.0, "circle_h": 6.0,
			"missile_mesh": "res://assets/models/icicle_mesh.tres"}})
	enemy_scene("storm_eye", {"script": "res://scripts/enemies/storm_eye.gd", "model": "storm_eye", "hp": 12, "floating": true,
		"body": [1.4, 2.8, 0.0], "hurt": [1.7, 3.4, 0.0], "hit": [Vector3(3.0, 3.0, 3.0), Vector3(0, 0, 0)], "shadow": 2.0,
		"exports": {"target_offset": 0.2, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Freezard -------------------------------------------------------------------

## A rounded heap of blue-white ice, wider at the base, a frosty crown of
## spikes, deep-set glowing eyes and a gaping mouth.
func _build_freezard() -> void:
	var ICE := _c("b8e0f8")
	var ICE_D := _c("7ab0d8")
	var DEEP := _c("1a3a5a")
	var EYE := _c("e8fbff")
	_root = Node3D.new()
	_root.name = "FreezardModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.0, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.85, 0.8, ICE_D], [0.5, 0.78, 0.72, ICE], [1.1, 0.6, 0.55, ICE], [1.6, 0.42, 0.4, ICE_D], [1.95, 0.0, 0.0, ICE]], 9)
		var h := p.k("hard")
		for i in 7:
			var a := TAU * i / 7.0
			h.prism(Vector3(cos(a) * 0.3, 1.7, sin(a) * 0.3), 0.12, Vector3(cos(a) * 0.45, 2.2 + (i % 2) * 0.2, sin(a) * 0.45), 0.0, 4, ICE)
		h.icosa(Vector3(0, 1.05, -0.55), Vector3(0.22, 0.15, 0.1), 0.0, DEEP)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.18 * sx, 1.45, -0.45), Vector3(0.08, 0.05, 0.04), 0.0, EYE)
	)
	body.position = Vector3.ZERO
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.0, true, {"body": [[0.0, V.call(0, -4, 0)], [1.0, V.call(0, 4, 0)]]}, rest)
	_anim(lib, "breathe", 1.5, false, {"body": [[0.0, V.call(0, 0, 0)], [0.2, V.call(-12, 0, 0)], [1.3, V.call(-10, 0, 0)], [1.5, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "stunned", 0.4, true, {"body": [[0.0, V.call(0, 0, 4)], [0.2, V.call(0, 0, -4)]]}, rest)
	_anim(lib, "death", 0.6, false, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, -1.2, 0)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "freezard.tscn")


# --- Wind wisp ------------------------------------------------------------------

## A puff of white cloud in three lumps, with round dark eyes and pursed lips.
func _build_wisp() -> void:
	var CLOUD := _c("f4f8ff")
	var CLOUD_D := _c("c8d4e8")
	_root = Node3D.new()
	_root.name = "WindWispModel"
	_paths = {}
	var root := _root
	_joint(root, "body", "Body", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0, 0), Vector3(0.45, 0.38, 0.4), 0.05, CLOUD, true)
		k.icosa(Vector3(0.38, -0.05, 0.1), Vector3(0.28, 0.24, 0.26), 0.05, CLOUD_D, true)
		k.icosa(Vector3(-0.38, -0.05, 0.1), Vector3(0.28, 0.24, 0.26), 0.05, CLOUD_D, true)
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.icosa(Vector3(0.14 * sx, 0.1, -0.36), Vector3(0.06, 0.08, 0.03), 0.0, _c("2a3a5a"))
		h.icosa(Vector3(0, -0.1, -0.4), Vector3(0.07, 0.06, 0.05), 0.0, _c("8aa0c8"))
	)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "float", 1.2, true, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0.1, 0)]], "body": [[0.0, V.call(0, 0, 6)], [0.6, V.call(0, 0, -6)]]}, rest)
	_anim(lib, "swell", 0.6, false, {"body@scale": [[0.0, V.call(1, 1, 1)], [0.6, V.call(1.35, 1.25, 1.3)]]}, rest)
	_anim(lib, "blow", 0.9, false, {"body@scale": [[0.0, V.call(1.35, 1.25, 1.3)], [0.2, V.call(0.85, 0.85, 1.1)], [0.9, V.call(1, 1, 1)]]}, rest)
	_anim(lib, "stunned", 0.4, true, {"body": [[0.0, V.call(0, 0, 20)], [0.2, V.call(0, 0, -20)]]}, rest)
	_anim(lib, "death", 0.4, false, {"body@scale": [[0.0, V.call(1, 1, 1)], [0.4, V.call(0.1, 0.1, 0.1)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "wind_wisp.tscn")


# --- Frostwing, the ice wyvern --------------------------------------------------

## A lean pale-blue wyvern: a long body and neck, a horned head with a frosty
## glow in its jaws, membrane wings on the same joints as Corvax's, clawed
## legs and a long tail.
func _build_wyvern() -> void:
	var SCALE := _c("8ab8e0")
	var SCALE_L := _c("c8e4f8")
	var BELLY := _c("e8f4ff")
	var MEMB := _c("6a90c8")
	var HORN := _c("f0f4f8")
	var EYE := _c("80f0ff")
	_root = Node3D.new()
	_root.name = "WyvernModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		k.loft([[-1.1, 0.0, 0.0, SCALE], [-0.9, 0.3, 0.32, SCALE], [-0.3, 0.5, 0.55, SCALE_L], [0.3, 0.45, 0.5, SCALE], [0.9, 0.25, 0.28, SCALE], [1.1, 0.0, 0.0, SCALE]], 9)
		k.pop()
		k.box(Vector3(0, -0.4, 0.0), Vector3(0.5, 0.12, 1.2), BELLY)
		var h := p.k("hard")
		for i in 6:
			h.prism(Vector3(0, 0.45, -0.7 + i * 0.3), 0.08, Vector3(0, 0.75, -0.6 + i * 0.3), 0.0, 4, SCALE_L)
	)
	_joint(body, "head", "Head", Vector3(0, 0.35, -1.05), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.05, -1), Vector3(0, 0.05, 0.15)))
		k.loft([[0.0, 0.3, 0.3, SCALE], [0.4, 0.3, 0.26, SCALE_L], [0.8, 0.16, 0.14, SCALE], [0.95, 0.0, 0.0, SCALE]], 8)
		k.pop()
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.15 * sx, 0.25, 0.05), 0.07, Vector3(0.35 * sx, 0.55, 0.45), 0.0, 4, HORN)
		h.box(Vector3(0, -0.12, -0.35), Vector3(0.3, 0.06, 0.6), _c("1a3a5a"))
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.18 * sx, 0.14, -0.3), Vector3(0.06, 0.05, 0.04), 0.0, EYE)
		g.icosa(Vector3(0, -0.1, -0.55), Vector3(0.08, 0.04, 0.12), 0.0, EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nm := "R" if side > 0 else "L"
		var wing := _joint(body, "wing" + sfx, "Wing" + nm, Vector3(0.45 * side, 0.3, -0.3), func(p: Parts) -> void:
			var k := p.k()
			k.prism(Vector3.ZERO, 0.12, Vector3(1.5 * side, 0.05, 0.1), 0.08, 6, SCALE)
			k.face_dir([Vector3(0, 0.0, 0.1), Vector3(1.5 * side, 0.05, 0.1), Vector3(1.4 * side, 0.0, 1.1), Vector3(0.1 * side, 0.0, 0.9)], MEMB, Vector3.UP)
			k.face_dir([Vector3(0, -0.01, 0.1), Vector3(1.5 * side, 0.04, 0.1), Vector3(1.4 * side, -0.01, 1.1), Vector3(0.1 * side, -0.01, 0.9)], MEMB.darkened(0.2), Vector3.DOWN)
		)
		_joint(wing, "tip" + sfx, "Tip" + nm, Vector3(1.5 * side, 0.05, 0.1), func(p: Parts) -> void:
			var k := p.k()
			k.prism(Vector3.ZERO, 0.08, Vector3(1.5 * side, 0.0, 0.2), 0.03, 5, SCALE)
			k.face_dir([Vector3(0, 0.0, 0.0), Vector3(1.5 * side, 0.0, 0.2), Vector3(0.9 * side, 0.0, 1.0), Vector3(0, 0.0, 1.0)], MEMB, Vector3.UP)
			k.face_dir([Vector3(0, -0.01, 0.0), Vector3(1.5 * side, -0.01, 0.2), Vector3(0.9 * side, -0.01, 1.0), Vector3(0, -0.01, 1.0)], MEMB.darkened(0.2), Vector3.DOWN)
		)
		_joint(body, "leg" + sfx, "Leg" + nm, Vector3(0.3 * side, -0.4, 0.3), func(p: Parts) -> void:
			var h := p.k("hard")
			h.prism(Vector3.ZERO, 0.12, Vector3(0, -0.55, 0.05), 0.08, 5, SCALE)
			for i in 3:
				var a := -0.5 + i * 0.5
				h.prism(Vector3(0, -0.55, 0.05), 0.04, Vector3(sin(a) * 0.25, -0.7, -cos(a) * 0.25), 0.0, 4, HORN)
		)
	_joint(body, "tail", "Tail", Vector3(0, 0.0, 1.05), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.1, 1), Vector3.ZERO))
		k.loft([[0.0, 0.25, 0.22, SCALE], [0.8, 0.14, 0.12, SCALE], [1.6, 0.05, 0.05, SCALE_L]], 6)
		k.pop()
		var h := p.k("hard")
		h.prism(Vector3(0, 0.0, 1.55), 0.15, Vector3(0, 0.0, 1.95), 0.0, 3, HORN)
	)
	var lib := _bird_anims()
	_finish_character(root, lib)
	_save_scene(root, "wyvern.tscn")


# --- Aeolos, the Storm Eye -------------------------------------------------------

## A great pale eye in a dark storm-blue sphere, inside four curved plates of
## cloud-gray ice that close round it like a bud; a ring of cloud puffs about
## its middle. The plates open on their hinges at the equator.
func _build_storm_eye() -> void:
	var CORE := _c("2a3a6a")
	var EYE_W := _c("f8f8ff")
	var IRIS := _c("40d0ff")
	var PLATE := _c("98a8c8")
	var PLATE_D := _c("68789a")
	var CLOUD := _c("e8eef8")
	_root = Node3D.new()
	_root.name = "StormEyeModel"
	_paths = {}
	var root := _root
	var core := _joint(root, "core", "Core", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3.ZERO, Vector3(0.95, 0.95, 0.95), 0.0, CORE, true)
		var h := p.k("hard")
		for i in 10:
			var a := TAU * i / 10.0
			h.icosa(Vector3(cos(a) * 1.55, (i % 2) * 0.15 - 0.05, sin(a) * 1.55), Vector3(0.45, 0.3, 0.45), 0.08, CLOUD, true)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.0, -0.75), Vector3(0.55, 0.55, 0.3), 0.0, EYE_W, true)
		g.icosa(Vector3(0, 0.0, -0.98), Vector3(0.28, 0.28, 0.12), 0.0, IRIS, true)
		g.icosa(Vector3(0, 0.0, -1.06), Vector3(0.12, 0.12, 0.06), 0.0, _c("0a0a1a"))
	)
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var dir := Vector3(cos(a), 0, sin(a))
		_joint(core, "plate_%d" % i, "Plate%d" % i, dir * 1.0, func(p: Parts) -> void:
			var k := p.k()
			# A curved petal from the equator up over the top.
			var rings: Array = []
			for j in 6:
				var t := float(j) / 5.0
				var up := sin(t * PI * 0.5) * 1.35
				var out := cos(t * PI * 0.5) * 0.35
				var w := 0.95 * (1.0 - t * 0.6)
				rings.append([dir * out + Vector3(0, up, 0), w])
			for j in 5:
				var a0: Array = rings[j]
				var a1: Array = rings[j + 1]
				var side := Vector3(-dir.z, 0, dir.x)
				var p0: Vector3 = a0[0]
				var p1: Vector3 = a1[0]
				var w0: float = a0[1]
				var w1: float = a1[1]
				var col := PLATE if j % 2 == 0 else PLATE_D
				k.face_dir([p0 - side * w0, p0 + side * w0, p1 + side * w1, p1 - side * w1], col, dir + Vector3.UP * 0.3)
				k.face_dir([p0 - side * w0 - dir * 0.1, p1 - side * w1 - dir * 0.1, p1 + side * w1 - dir * 0.1, p0 + side * w0 - dir * 0.1], PLATE_D, -dir)
		)
	var lib := AnimationLibrary.new()
	var rest := {"core": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	var closed := {"core": [[0.0, V.call(0, 0, 0)], [1.5, V.call(0, 180, 0)], [3.0, V.call(0, 360, 0)]]}
	var opened := {"core": [[0.0, V.call(0, 0, 0)]]}
	var opening := {}
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		# Hinged at the equator, each plate tips outward (about its own tangent).
		var tilt := V.call(sin(a) * 70.0, 0, -cos(a) * 70.0) as Vector3
		closed["plate_%d" % i] = [[0.0, Vector3.ZERO]]
		opened["plate_%d" % i] = [[0.0, tilt], [0.5, tilt * 1.08], [1.0, tilt]]
		opening["plate_%d" % i] = [[0.0, Vector3.ZERO], [0.8, tilt]]
	_anim(lib, "closed", 3.0, true, closed, rest)
	_anim(lib, "open", 0.8, false, opening, rest)
	_anim(lib, "gale", 1.0, true, opened, rest)
	var stunned := opened.duplicate(true)
	stunned["core"] = [[0.0, V.call(25, 0, 10)], [0.5, V.call(25, 0, -10)], [1.0, V.call(25, 0, 10)]]
	_anim(lib, "stunned", 1.0, true, stunned, rest)
	var death := opened.duplicate(true)
	death["core"] = [[0.0, V.call(0, 0, 0)], [2.0, V.call(60, 200, 40)]]
	_anim(lib, "death", 2.0, false, death, rest)
	_finish_character(root, lib)
	_save_scene(root, "storm_eye.tscn")


## An icicle flung by Frostwing and Aeolos: a long spike of blue ice.
func _build_icicle() -> void:
	var k := MeshKit.new(4451)
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.25, 0), 0.07, Vector3(0, 0.4, 0), 0.0, 5, _c("c8ecff"))
	k.pop()
	k.smooth_normals(40.0)
	_save_res(k.build(_mats.glow), "icicle_mesh.tres")
