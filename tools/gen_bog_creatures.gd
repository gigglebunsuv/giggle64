extends "res://tools/gen_sky_creatures.gd"
## The creatures of the Bog Tower (built like gen_creatures.gd):
##
##   bog_stalfos  a Stalfos crusted with moss and silt
##   mire_knight  the mini-boss: the Tide Knight's armor gone green with slime
##   gullagog     Gullagog the Mire Toad, the boss: a toad the size of a cottage
##                with a jaw that drops open to inhale, a long sticky tongue,
##                bulging eyes and a pale belly
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_gullagog()
	_bog_scenes()


func _bog_scenes() -> void:
	enemy_scene("bog_stalfos", {"script": "res://scripts/enemies/stalfos.gd", "model": "stalfos", "hp": 6,
		"body": [0.38, 1.8, 0.9], "hurt": [0.48, 1.9, 0.95], "hit": [Vector3(0.7, 1.4, 1.8), Vector3(0, 1.0, -1.3)], "shadow": 0.5,
		"exports": {"target_offset": 1.95, "boomerang_stun": 2.0, "drop_table": 11, "tint": Color(0.72, 0.95, 0.62)}})
	enemy_scene("mire_knight", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 14,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11, "tint": Color(0.62, 0.92, 0.5),
			"title_name": "MIRE KNIGHT", "title_epithet": "Sunken Warden of the Bog", "burrows": true}})
	enemy_scene("gullagog", {"script": "res://scripts/enemies/gullagog.gd", "model": "gullagog", "hp": 12,
		"body": [1.6, 3.2, 1.4], "hurt": [2.0, 3.6, 1.5], "hit": [Vector3(3.6, 2.4, 3.6), Vector3(0, 1.2, 0)], "shadow": 2.6,
		"exports": {"target_offset": 3.0, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Gullagog ----------------------------------------------------------------------

## A squat mud-green toad 3.6 m wide: a broad warty back over a pale yellow
## belly, the head one with the body under two bulging gold eyes, a lower
## jaw (its own joint, dropping open) holding a pink tongue that shoots out
## (scaled along -Z), and four legs, the hind ones folded fat at its sides.
func _build_gullagog() -> void:
	var SKIN := _c("5a7a32")
	var SKIN_D := _c("3e5a22")
	var SKIN_L := _c("7a9a42")
	var WART := _c("8a8a3a")
	var BELLY := _c("e0d08a")
	var MOUTH := _c("6a1e24")
	var TONGUE := _c("e86a8a")
	var EYE := _c("f0c030")
	_root = Node3D.new()
	_root.name = "GullagogModel"
	_paths = {}
	var root := _root
	# The body joint sits at the middle of the bulk, so it can roll over.
	var body := _joint(root, "body", "Body", Vector3(0, 1.3, 0), func(p: Parts) -> void:
		var k := p.k()
		# Squashed bulk, front (-Z) to back.
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		k.loft([
			[-1.9, 0.0, 0.0, SKIN_D], [-1.75, 0.9, 0.6, SKIN], [-1.2, 1.6, 1.05, SKIN_L], [-0.3, 1.85, 1.2, SKIN_L],
			[0.6, 1.75, 1.15, SKIN], [1.4, 1.35, 0.95, SKIN], [1.85, 0.7, 0.55, SKIN_D], [2.0, 0.0, 0.0, SKIN_D],
		], 14)
		k.pop()
		# The pale belly underneath.
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, -0.55, 0)))
		k.loft([[-1.5, 0.0, 0.0, BELLY], [-1.2, 1.2, 0.6, BELLY], [0.2, 1.5, 0.75, BELLY], [1.3, 1.1, 0.55, BELLY], [1.6, 0.0, 0.0, BELLY]], 12)
		k.pop()
		# Warts across the back.
		var r := RandomNumberGenerator.new()
		r.seed = 51
		for i in 26:
			var a := r.randf_range(-2.4, 2.4)
			var zz := r.randf_range(-1.2, 1.6)
			var pos := Vector3(sin(a) * 1.55, cos(a) * 1.0 + 0.1, zz)
			if pos.y < 0.0:
				continue
			k.icosa(pos, Vector3.ONE * r.randf_range(0.1, 0.2), 0.05, WART)
		var h := p.k("hard")
		# The upper lip line and the dark gullet behind it.
		h.box(Vector3(0, -0.15, -1.72), Vector3(2.4, 0.16, 0.2), SKIN_D)
		h.box(Vector3(0, -0.45, -1.4), Vector3(2.0, 0.5, 0.4), MOUTH)
		# Bulging eyes on top of the head.
		for sx in [-1.0, 1.0]:
			k.icosa(Vector3(0.8 * sx, 0.95, -1.15), Vector3(0.5, 0.45, 0.5), 0.0, SKIN)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.88 * sx, 1.08, -1.5), Vector3(0.34, 0.3, 0.2), 0.0, EYE)
			g.box(Vector3(0.88 * sx, 1.08, -1.69), Vector3(0.36, 0.1, 0.02), _c("1a1008"))
	)
	var jaw := _joint(body, "jaw", "Jaw", Vector3(0, -0.35, -0.6), func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		k.loft([[-1.25, 0.0, 0.0, BELLY], [-1.1, 1.05, 0.25, BELLY], [-0.4, 1.25, 0.32, BELLY], [0.3, 1.0, 0.25, BELLY], [0.5, 0.0, 0.0, BELLY]], 10)
		k.pop()
		var h := p.k("hard")
		h.box(Vector3(0, 0.18, -0.55), Vector3(1.9, 0.08, 1.1), MOUTH)
	)
	_joint(jaw, "tongue", "Tongue", Vector3(0, 0.2, -0.4), func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		k.loft([[-1.0, 0.0, 0.0, TONGUE], [-0.95, 0.28, 0.12, TONGUE], [-0.4, 0.2, 0.1, TONGUE], [0.0, 0.18, 0.08, TONGUE.darkened(0.2)]], 8)
		k.pop()
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var fore := _joint(body, "arm" + sfx, "Arm" + nsfx, Vector3(1.2 * side, -0.6, -0.9), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.1, 0.0, 0.0, SKIN], [0.05, 0.3, 0.3, SKIN], [-0.5, 0.24, 0.24, SKIN], [-0.7, 0.0, 0.0, SKIN_D]], 7)
			k.box(Vector3(0.0, -0.7, -0.25), Vector3(0.55, 0.12, 0.6), SKIN_D)
		)
		fore.position.y = -0.6
		_joint(body, "leg" + sfx, "Leg" + nsfx, Vector3(1.45 * side, -0.4, 0.9), func(p: Parts) -> void:
			var k := p.k()
			# The fat folded thigh, and the long foot tucked forward under it.
			k.icosa(Vector3(0.1 * side, 0.0, 0.0), Vector3(0.7, 0.75, 1.0), 0.04, SKIN)
			k.box(Vector3(0.15 * side, -0.82, -0.5), Vector3(0.7, 0.14, 1.3), SKIN_D)
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 1.3, 0), "tongue": Vector3(0, 0.2, -0.4)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Breathing: the throat swells and the body bobs.
	_anim(lib, "idle", 1.6, true, {
		"body@pos": [[0.0, V.call(0, 1.3, 0)], [0.8, V.call(0, 1.36, 0)]],
		"jaw": [[0.0, V.call(0, 0, 0)], [0.8, V.call(6, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "roar", 2.2, false, {
		"body@pos": [[0.0, V.call(0, 1.3, 0)], [0.4, V.call(0, 1.7, 0)], [1.8, V.call(0, 1.7, 0)], [2.2, V.call(0, 1.3, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.4, V.call(18, 0, 0)], [1.8, V.call(18, 0, 0)], [2.2, V.call(0, 0, 0)]],
		"jaw": [[0.0, V.call(0, 0, 0)], [0.4, V.call(50, 0, 0)], [1.0, V.call(42, 0, 0)], [1.8, V.call(50, 0, 0)], [2.2, V.call(0, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)], [0.5, V.call(1, 1, 1.2)], [1.8, V.call(1, 1, 1.0)], [2.2, V.call(1, 1, 0.3)]],
		"arm_r": [[0.0, V.call(0, 0, 0)], [0.4, V.call(-30, 0, 0)]], "arm_l": [[0.0, V.call(0, 0, 0)], [0.4, V.call(-30, 0, 0)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "crouch", 0.45, false, {
		"body@pos": [[0.0, V.call(0, 1.3, 0)], [0.45, V.call(0, 0.95, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.45, V.call(-8, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 0)], [0.45, V.call(-15, 0, 10)]], "leg_l": [[0.0, V.call(0, 0, 0)], [0.45, V.call(-15, 0, -10)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "leap", 0.6, true, {
		"body@pos": [[0.0, V.call(0, 1.4, 0)]],
		"body": [[0.0, V.call(14, 0, 0)], [0.3, V.call(8, 0, 0)]],
		"leg_r": [[0.0, V.call(55, 0, -10)], [0.3, V.call(38, 0, -14)]], "leg_l": [[0.0, V.call(55, 0, 10)], [0.3, V.call(38, 0, 14)]],
		"arm_r": [[0.0, V.call(-50, 0, -15)], [0.3, V.call(-62, 0, -22)]], "arm_l": [[0.0, V.call(-50, 0, 15)], [0.3, V.call(-62, 0, 22)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "land", 0.5, false, {
		"body@pos": [[0.0, V.call(0, 0.9, 0)], [0.5, V.call(0, 1.3, 0)]],
		"body": [[0.0, V.call(-6, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "tongue_windup", 0.65, false, {
		"body": [[0.0, V.call(0, 0, 0)], [0.65, V.call(-10, 0, 0)]],
		"jaw": [[0.0, V.call(0, 0, 0)], [0.65, V.call(10, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	_anim(lib, "tongue", 0.7, false, {
		"body": [[0.0, V.call(-10, 0, 0)], [0.1, V.call(6, 0, 0)], [0.7, V.call(0, 0, 0)]],
		"jaw": [[0.0, V.call(10, 0, 0)], [0.08, V.call(30, 0, 0)], [0.5, V.call(30, 0, 0)], [0.7, V.call(0, 0, 0)]],
		"tongue": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-30, 0, 0)], [0.4, V.call(-25, 0, 0)], [0.7, V.call(0, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)], [0.12, V.call(1, 1, 6.0)], [0.35, V.call(1, 1, 5.5)], [0.6, V.call(1, 1, 0.3)]],
		"body@scale": [[0.0, V.call(1, 1, 1)]],
	}, rest)
	# Mouth gaping, the body heaving as it draws in the air.
	_anim(lib, "inhale", 0.8, true, {
		"body@pos": [[0.0, V.call(0, 1.45, 0)], [0.4, V.call(0, 1.5, 0)]],
		"body": [[0.0, V.call(12, 0, 0)]],
		"body@scale": [[0.0, V.call(1.0, 1.0, 1.0)], [0.4, V.call(1.06, 1.08, 1.04)]],
		"jaw": [[0.0, V.call(58, 0, 0)], [0.4, V.call(62, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
	}, rest)
	# Choking: it swells up and rolls onto its back.
	_anim(lib, "choke", 1.0, false, {
		"body@pos": [[0.0, V.call(0, 1.45, 0)], [0.6, V.call(0, 1.8, 0)], [1.0, V.call(0, 1.5, 0)]],
		"body": [[0.0, V.call(12, 0, 0)], [0.6, V.call(20, 0, 30)], [1.0, V.call(0, 0, 180)]],
		"body@scale": [[0.0, V.call(1, 1, 1)], [0.6, V.call(1.25, 1.3, 1.2)], [1.0, V.call(1.15, 1.15, 1.1)]],
		"jaw": [[0.0, V.call(58, 0, 0)], [0.5, V.call(10, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
	}, rest)
	_anim(lib, "flipped", 0.5, true, {
		"body@pos": [[0.0, V.call(0, 1.5, 0)]],
		"body": [[0.0, V.call(0, 0, 180)], [0.25, V.call(0, 0, 176)]],
		"body@scale": [[0.0, V.call(1.15, 1.15, 1.1)]],
		"jaw": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(20, 0, 0)], [0.25, V.call(-30, 0, 0)]], "leg_l": [[0.0, V.call(-30, 0, 0)], [0.25, V.call(20, 0, 0)]],
		"arm_r": [[0.0, V.call(-40, 0, 0)], [0.25, V.call(10, 0, 0)]], "arm_l": [[0.0, V.call(10, 0, 0)], [0.25, V.call(-40, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 1.4)]],
	}, rest)
	_anim(lib, "unflip", 0.9, false, {
		"body@pos": [[0.0, V.call(0, 1.5, 0)], [0.5, V.call(0, 2.1, 0)], [0.9, V.call(0, 1.3, 0)]],
		"body": [[0.0, V.call(0, 0, 180)], [0.5, V.call(0, 0, 90)], [0.9, V.call(0, 0, 0)]],
		"body@scale": [[0.0, V.call(1.15, 1.15, 1.1)], [0.9, V.call(1, 1, 1)]],
		"tongue@scale": [[0.0, V.call(1, 1, 0.3)]],
	}, rest)
	_anim(lib, "death", 2.0, false, {
		"body@pos": [[0.0, V.call(0, 1.5, 0)], [2.0, V.call(0, 0.9, 0)]],
		"body": [[0.0, V.call(0, 0, 180)], [0.6, V.call(0, 0, 200)], [2.0, V.call(0, 0, 180)]],
		"body@scale": [[0.0, V.call(1.15, 1.15, 1.1)], [2.0, V.call(1.3, 0.6, 1.3)]],
		"jaw": [[0.0, V.call(40, 0, 0)]],
		"tongue@scale": [[0.0, V.call(1, 1, 2.0)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "gullagog.tscn")
