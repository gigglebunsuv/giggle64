extends "res://tools/gen_tower_creatures.gd"
## The creatures of Beta 1.1.0 (Chapter III, the Batela Fells):
##
##   incunax   Incunax, the Bound Page: master of the Sapphire Sanctum, a
##             tome torn from the Fari Incunabulum and given a will: two great
##             covers bound in sapphire chains, and on its open pages one
##             staring eye (scripts/enemies/incunax.gd)
##
## The Sanctum's other foes are the castle's (sapphire knights and mages, the
## Sapphire Warden) and the desert's shades. Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_incunax()
	enemy_scene("incunax", {"script": "res://scripts/enemies/incunax.gd", "model": "incunax", "hp": 14, "floating": true,
		"body": [1.3, 2.6, 0.0], "hurt": [1.6, 3.0, 0.0], "hit": [Vector3(2.6, 2.6, 2.6), Vector3(0, 0, 0)], "shadow": 1.8,
		"exports": {"target_offset": 0.3, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Incunax --------------------------------------------------------------------

## The tome stands on end, spine toward +Z, its covers (each about 2.4 m tall)
## swinging open to the sides like doors. Inside, the pages: a fan of yellowed
## leaves covered in blue script, and in the middle of them the Eye.
func _build_incunax() -> void:
	var LEATHER := _c("2a2a4a")
	var LEATHER_D := _c("1a1a30")
	var BRASS := _c("8a7a4a")
	var CHAIN := _c("5a6a9a")
	var PAGE := _c("d8c8a0")
	var PAGE_D := _c("b8a880")
	var INK := _c("2a3a7a")
	var GEM := _c("4a6aff")
	_root = Node3D.new()
	_root.name = "IncunaxModel"
	_paths = {}
	var root := _root
	var spine := _joint(root, "spine", "Spine", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		# The spine: a rounded leather back with brass bands.
		k.box(Vector3(0, 0, 0.58), Vector3(0.7, 2.5, 0.16), LEATHER_D)
		for y in [-0.9, -0.3, 0.3, 0.9]:
			k.box(Vector3(0, y, 0.6), Vector3(0.76, 0.1, 0.18), BRASS)
		# The eye-page bound to the spine, facing -Z, and the Eye on it: hidden
		# while the covers' pages are closed over it.
		var pg := p.k("hard")
		pg.box(Vector3(0, 0, 0.46), Vector3(0.62, 2.2, 0.06), PAGE)
		for i in 8:
			pg.box(Vector3(0, 0.95 - i * 0.27, 0.425), Vector3(0.5, 0.03, 0.01), INK)
		var eye := p.k("glow")
		eye.icosa(Vector3(0, 0.0, 0.4), Vector3(0.26, 0.42, 0.07), 0.0, _c("f4f0ff"), true)
		eye.icosa(Vector3(0, 0.0, 0.35), Vector3(0.14, 0.2, 0.04), 0.0, GEM, true)
		eye.icosa(Vector3(0, 0.0, 0.33), Vector3(0.06, 0.09, 0.03), 0.0, _c("0a0a1a"))
	)
	var eye_mark := Marker3D.new()
	eye_mark.name = "Eye"
	eye_mark.position = Vector3(0, 0.0, 0.3)
	spine.add_child(eye_mark)
	for side in [-1.0, 1.0]:
		var key := "cover_l" if side < 0.0 else "cover_r"
		# Hinged at the spine's edges; closed, each cover runs forward (-Z)
		# with its half of the pages on the inside, meeting in the middle.
		_joint(spine, key, "Cover" + ("L" if side < 0.0 else "R"), Vector3(side * 0.32, 0, 0.5), func(p: Parts) -> void:
			var k := p.k()
			k.box(Vector3(0, 0, -0.66), Vector3(0.1, 2.5, 1.32), LEATHER)
			var pg := p.k("hard")
			pg.box(Vector3(-side * 0.16, 0, -0.66), Vector3(0.22, 2.3, 1.22), PAGE_D)
			for i in 6:
				pg.box(Vector3(-side * 0.16, 0, -0.1 - i * 0.22), Vector3(0.23, 2.28, 0.02), PAGE)
			for i in 9:
				pg.box(Vector3(-side * 0.275, 0.9 - i * 0.22, -0.66), Vector3(0.01, 0.04, 0.9), INK)
			# Brass corners and a sapphire boss on the outside.
			var h := p.k("hard")
			for cy in [-1.15, 1.15]:
				for cz in [-0.08, -1.24]:
					h.box(Vector3(side * 0.06, cy, cz), Vector3(0.04, 0.22, 0.22), BRASS)
			h.icosa(Vector3(side * 0.08, 0, -0.66), Vector3(0.08, 0.28, 0.28), 0.0, BRASS)
			var g := p.k("glow")
			g.icosa(Vector3(side * 0.13, 0, -0.66), Vector3(0.06, 0.16, 0.16), 0.0, GEM, true)
			# The chains bound round it.
			for cy in [-0.6, 0.6]:
				for i in 5:
					h.box(Vector3(side * 0.08, cy, -0.12 - i * 0.26), Vector3(0.06, 0.07, 0.16), CHAIN if i % 2 == 0 else CHAIN.darkened(0.25))
		)
	# Loose chains trailing under it.
	_joint(spine, "chains", "Chains", Vector3(0, -1.2, 0.3), func(p: Parts) -> void:
		var h := p.k("hard")
		for c in 3:
			var x := (c - 1) * 0.4
			for i in 6:
				h.box(Vector3(x, -i * 0.18, 0), Vector3(0.07, 0.14, 0.06) if i % 2 == 0 else Vector3(0.06, 0.14, 0.07), CHAIN if i % 2 == 0 else CHAIN.darkened(0.25))
	)
	var lib := AnimationLibrary.new()
	var rest := {"spine": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Covers closed (folded together over the pages, toward -Z).
	var shut := {"cover_l": [[0.0, V.call(0, -8, 0)]], "cover_r": [[0.0, V.call(0, 8, 0)]]}
	var idle := shut.duplicate(true)
	idle["spine"] = [[0.0, V.call(0, 0, -4)], [1.0, V.call(3, 0, 4)], [2.0, V.call(0, 0, -4)]]
	idle["chains"] = [[0.0, V.call(8, 0, 0)], [1.0, V.call(-8, 0, 0)], [2.0, V.call(8, 0, 0)]]
	_anim(lib, "idle", 2.0, true, idle, rest)
	# Opened wide: each cover swung back about its hinge.
	var wide := {"cover_l": [[0.0, V.call(0, 95, 0)]], "cover_r": [[0.0, V.call(0, -95, 0)]]}
	var opening := {"cover_l": [[0.0, V.call(0, -8, 0)], [0.6, V.call(0, 95, 0)]], "cover_r": [[0.0, V.call(0, 8, 0)], [0.6, V.call(0, -95, 0)]]}
	_anim(lib, "open", 0.6, false, opening, rest)
	var closing := {"cover_l": [[0.0, V.call(0, 95, 0)], [0.4, V.call(0, -8, 0)]], "cover_r": [[0.0, V.call(0, -95, 0)], [0.4, V.call(0, 8, 0)]]}
	_anim(lib, "close", 0.4, false, closing, rest)
	var cast := wide.duplicate(true)
	cast["cover_l"] = [[0.0, V.call(0, 95, 0)], [0.2, V.call(0, 100, 0)], [0.4, V.call(0, 95, 0)]]
	cast["cover_r"] = [[0.0, V.call(0, -95, 0)], [0.2, V.call(0, -100, 0)], [0.4, V.call(0, -95, 0)]]
	cast["spine"] = [[0.0, V.call(6, 0, 0)], [0.2, V.call(10, 0, 0)], [0.4, V.call(6, 0, 0)]]
	_anim(lib, "cast", 0.4, true, cast, rest)
	# Struck in the eye: it falls flat on its back, covers splayed, pages up.
	var down := wide.duplicate(true)
	down["spine"] = [[0.0, V.call(90, 0, 0)], [0.6, V.call(86, 0, 0)], [1.2, V.call(90, 0, 0)]]
	down["chains"] = [[0.0, V.call(0, 0, 0)]]
	_anim(lib, "down", 1.2, true, down, rest)
	var fall := {"spine": [[0.0, V.call(0, 0, 0)], [0.5, V.call(90, 0, 0)]], "cover_l": [[0.0, V.call(0, 95, 0)]], "cover_r": [[0.0, V.call(0, -95, 0)]]}
	_anim(lib, "fall", 0.5, false, fall, rest)
	var hurt := down.duplicate(true)
	hurt["spine"] = [[0.0, V.call(90, 0, 0)], [0.1, V.call(78, 0, 8)], [0.3, V.call(90, 0, 0)]]
	_anim(lib, "hurt", 0.3, false, hurt, rest)
	var rise := {"spine": [[0.0, V.call(90, 0, 0)], [0.8, V.call(0, 0, 0)]], "cover_l": [[0.0, V.call(0, 95, 0)], [0.8, V.call(0, -8, 0)]],
		"cover_r": [[0.0, V.call(0, -95, 0)], [0.8, V.call(0, 8, 0)]]}
	_anim(lib, "rise", 0.8, false, rise, rest)
	var death := wide.duplicate(true)
	death["spine"] = [[0.0, V.call(0, 0, 0)], [1.0, V.call(30, 180, 20)], [2.0, V.call(80, 400, 40)]]
	_anim(lib, "death", 2.0, false, death, rest)
	_finish_character(root, lib)
	_save_scene(root, "incunax.tscn")
