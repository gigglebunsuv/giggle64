extends "res://tools/gen_creatures.gd"
## The creatures of the Lake Shrine (built like gen_creatures.gd):
##
##   stalfos       drowned skeleton swordsmen with coral-crusted shields (EnTest)
##   shellblade    biting clams, armored until they open (EnSb)
##   tide_knight   the mini-boss: a huge armored knight with a cleaver, after
##                 OoT's Iron Knuckle (EnIk)
##   carapax       the shrine's master: a giant armored crab with one eye on a
##                 stalk (the boss; its plan follows Gohma's: stun the eye, then
##                 strike the soft underside)
##
## Creatures face -Z.


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_stalfos()
	_build_shellblade()
	_build_tide_knight()
	_build_carapax()
	_build_bubble()
	_shrine_scenes()


func _shrine_scenes() -> void:
	enemy_scene("stalfos", {"script": "res://scripts/enemies/stalfos.gd", "model": "stalfos", "hp": 6,
		"body": [0.38, 1.8, 0.9], "hurt": [0.48, 1.9, 0.95], "hit": [Vector3(0.7, 1.4, 1.8), Vector3(0, 1.0, -1.3)], "shadow": 0.5,
		"exports": {"target_offset": 1.95, "boomerang_stun": 2.0, "drop_table": 11}})
	enemy_scene("shellblade", {"script": "res://scripts/enemies/shellblade.gd", "model": "shellblade", "hp": 2,
		"body": [0.5, 0.9, 0.4], "hurt": [0.6, 1.0, 0.4], "hit": [Vector3(1.1, 0.8, 1.2), Vector3(0, 0.4, -0.8)], "shadow": 0.65,
		"exports": {"target_offset": 0.9, "boomerang_stun": 3.5, "drop_table": 1}})
	enemy_scene("tide_knight", {"script": "res://scripts/enemies/tide_knight.gd", "model": "tide_knight", "hp": 14,
		"body": [0.6, 2.4, 1.2], "hurt": [0.75, 2.6, 1.25], "hit": [Vector3(1.0, 2.2, 2.6), Vector3(0, 1.0, -1.9)], "shadow": 0.85,
		"exports": {"target_offset": 2.7, "boomerang_stun": 0.0, "drop_table": 11,
			"title_name": "TIDE KNIGHT", "title_epithet": "Guardian of the Lake Shrine"}})
	enemy_scene("carapax", {"script": "res://scripts/enemies/carapax.gd", "model": "carapax", "hp": 8,
		"body": [1.9, 3.8, 1.9], "hurt": [2.2, 4.4, 1.9], "hit": [Vector3(3.0, 2.0, 3.0), Vector3(0, 1.0, -3.0)], "shadow": 2.4,
		"exports": {"target_offset": 3.4, "boomerang_stun": 0.0, "drop_table": -1}})


# --- Stalfos (EnTest) -----------------------------------------------------------

## A tall skeleton swordsman, its bones green with weed and crusted with
## coral, eyes burning sea-blue. Built on the humanoid joint layout.
func _build_stalfos() -> void:
	var BONE := _c("d8d0b0")
	var BONE_D := _c("aca486")
	var CORAL := _c("e07a6a")
	var WEED := _c("3a7a5a")
	var METAL := _c("6a8c8c")
	var METAL_L := _c("9ababa")
	var EYE := _c("60f0ff")
	_root = Node3D.new()
	_root.name = "StalfosModel"
	_paths = {}
	var root := _root
	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.98, 0), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0, 0), Vector3(0.17, 0.09, 0.11), 0.1, BONE)
		k.loft([[-0.3, 0.0, 0.0, WEED], [-0.05, 0.19, 0.13, WEED], [0.02, 0.18, 0.12, WEED]], 7)
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.05, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.035, 0.035, BONE_D], [0.45, 0.035, 0.035, BONE_D]], 5)
		# The ribcage: bands of bone over dark gaps.
		var rings: Array = []
		for i in 9:
			var y := 0.14 + i * 0.035
			var r := 0.13 + sin(float(i) / 8.0 * PI) * 0.05
			rings.append([y, r, r * 0.75, BONE if i % 2 == 0 else _c("2a2a24"), Vector2(0, -0.02)])
		k.loft(rings, 9, false)
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.icosa(Vector3(0.19 * sx, 0.44, 0), Vector3(0.09, 0.07, 0.09), 0.15, BONE)
			for i in 3:
				h.icosa(Vector3(0.2 * sx + (i - 1) * 0.03, 0.5, (i - 1) * 0.05), Vector3(0.035, 0.035, 0.035), 0.3, CORAL)
	)
	_joint(torso, "head", "Head", Vector3(0, 0.5, -0.02), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.12, 0), Vector3(0.12, 0.13, 0.14), 0.05, BONE, true)
		k.box(Vector3(0, 0.0, -0.05), Vector3(0.14, 0.06, 0.12), BONE_D)
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.05 * sx, 0.12, -0.125), Vector3(0.055, 0.05, 0.02), _c("101010"))
		h.box(Vector3(0, 0.07, -0.135), Vector3(0.025, 0.04, 0.01), _c("201810"))
		for i in 4:
			h.box(Vector3(-0.045 + i * 0.03, 0.025, -0.115), Vector3(0.018, 0.025, 0.01), _c("f0ecdc"))
		# A barnacle crust on the crown.
		for i in 4:
			h.icosa(Vector3(-0.05 + i * 0.035, 0.24, 0.02 - (i % 2) * 0.04), Vector3(0.03, 0.025, 0.03), 0.3, _c("c8c0a8"))
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.05 * sx, 0.12, -0.137), Vector3(0.025, 0.022, 0.005), EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.22 * side, 0.42, 0), func(p: Parts) -> void:
			p.k().loft([[0.03, 0.0, 0.0, BONE], [0.0, 0.035, 0.035, BONE], [-0.28, 0.028, 0.028, BONE], [-0.31, 0.04, 0.04, BONE_D]], 5)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.3, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.0, 0.03, 0.03, BONE], [-0.26, 0.024, 0.024, BONE], [-0.28, 0.0, 0.0, BONE]], 5)
			if side < 0:
				k.loft([[-0.05, 0.033, 0.033, WEED], [-0.15, 0.03, 0.03, WEED]], 5)
		)
		var hand := _joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.28, 0), func(p: Parts) -> void:
			var k := p.k()
			k.icosa(Vector3(0, -0.05, 0), Vector3(0.045, 0.06, 0.04), 0.2, BONE_D)
		)
		if side > 0:
			_attach(hand, "Sword", Vector3(0, -0.06, 0), func(p: Parts) -> void:
				var h := p.k("hard")
				h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
				h.box(Vector3(0, -0.04, 0), Vector3(0.035, 0.16, 0.035), _c("4a3a2a"))
				h.box(Vector3(0, 0.05, 0), Vector3(0.22, 0.035, 0.05), METAL)
				h.slab(Vector3(0, 0.06, 0), Vector2(0.07, 0.015), Vector3(0.02, 0.78, 0), Vector2(0.09, 0.012), METAL_L)
				h.prism(Vector3(0.02, 0.78, 0), 0.05, Vector3(0.0, 0.92, 0), 0.0, 4, METAL_L)
				for i in 3:
					h.icosa(Vector3(0.03, 0.25 + i * 0.18, 0.012), Vector3(0.025, 0.025, 0.015), 0.3, CORAL)
				h.pop()
			, "sword")
		else:
			_attach(elbow, "Shield", Vector3(-0.06, -0.15, 0), func(p: Parts) -> void:
				var h := p.k("hard")
				h.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
				h.prism(Vector3(0, 0, 0), 0.3, Vector3(0, 0.04, 0), 0.3, 9, METAL)
				h.prism(Vector3(0, 0.04, 0), 0.26, Vector3(0, 0.06, 0), 0.24, 9, _c("5a7070"))
				h.prism(Vector3(0, 0.06, 0), 0.07, Vector3(0, 0.11, 0), 0.03, 6, METAL_L)
				for i in 6:
					var a := TAU * i / 6.0
					h.icosa(Vector3(cos(a) * 0.18, 0.07, sin(a) * 0.18), Vector3(0.04, 0.03, 0.04), 0.3, CORAL if i % 2 == 0 else _c("c8c0a8"))
				h.pop()
			, "shield")
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.1 * side, -0.05, 0), func(p: Parts) -> void:
			p.k().loft([[0.03, 0.0, 0.0, BONE], [0.0, 0.04, 0.04, BONE], [-0.4, 0.032, 0.032, BONE], [-0.44, 0.045, 0.045, BONE_D]], 5)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.43, 0), func(p: Parts) -> void:
			p.k().loft([[0.0, 0.035, 0.035, BONE], [-0.4, 0.03, 0.03, BONE], [-0.43, 0.0, 0.0, BONE]], 5)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.43, 0), func(p: Parts) -> void:
			var k := p.k()
			k.box(Vector3(0, -0.03, -0.06), Vector3(0.08, 0.04, 0.2), BONE_D)
		)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.98, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# Beta 1.6.0: EnTest fences on bent knees, bouncing lightly, the blade up
	# and the shield out in front, and every move goes through that stance.
	# Its blade's flat faces the hand's Y, so a level cut needs no roll; the
	# chop rolls the wrist a quarter turn so the edge comes down first.
	var guard_r: Vector3 = V.call(46, 0, 22)
	var guard_l: Vector3 = V.call(62, -30, -20)
	var stance := {
		"hips@pos": V.call(0, 0.93, 0), "torso": V.call(-10, 6, 0), "head": V.call(6, -6, 0),
		"shoulder_r": guard_r, "elbow_r": V.call(72, 0, 0), "hand_r": V.call(-34, 0, 0),
		"shoulder_l": guard_l, "elbow_l": V.call(80, 0, 0),
		"leg_r": V.call(-12, 0, 7), "knee_r": V.call(-24, 0, 0), "foot_r": V.call(24, 0, 0),
		"leg_l": V.call(26, 0, -6), "knee_l": V.call(-34, 0, 0), "foot_l": V.call(8, 0, 0),
	}
	var with := func(a: Dictionary, b: Dictionary) -> Dictionary:
		var c := a.duplicate()
		c.merge(b, true)
		return c
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Idle: the fencer's bounce, twice a loop, the blade's point weaving and
	# the skull cocking from side to side.
	var bob_lo: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.9, 0), "knee_r": V.call(-32, 0, 0), "knee_l": V.call(-42, 0, 0),
		"leg_r": V.call(-8, 0, 7), "leg_l": V.call(30, 0, -6), "foot_r": V.call(28, 0, 0), "foot_l": V.call(12, 0, 0),
		"torso": V.call(-13, 6, 0), "elbow_r": V.call(78, 0, 0), "shoulder_r": guard_r + V.call(4, 0, 0)})
	_pose_anim(lib, "idle", 1.0, [[0.0, stance], [0.25, with.call(bob_lo, {"head": V.call(8, -2, 8)})],
		[0.5, with.call(stance, {"hand_r": V.call(-28, 0, 0)})], [0.75, with.call(bob_lo, {"head": V.call(8, -10, -8)})], [1.0, stance]], stance, rest, true)
	# Walk: a crouched stalk, guard held up, the skull steady over the hips.
	var walk := {"hips@pos": [], "hips": [], "torso": [], "head": [], "leg_r": [], "knee_r": [], "foot_r": [],
		"leg_l": [], "knee_l": [], "foot_l": [], "shoulder_r": [], "elbow_r": [], "hand_r": [[0.0, V.call(-34, 0, 0)]],
		"shoulder_l": [[0.0, guard_l]], "elbow_l": [[0.0, V.call(80, 0, 0)]]}
	var hip := [28, 16, 0, -16, -24, -10, 14, 26]
	var knee := [-16, -30, -20, -18, -36, -70, -46, -18]
	var foot := [-6, 6, 8, 18, 26, 14, -2, -8]
	for i in 8:
		var ph := i / 8.0
		var t := ph * 0.7
		var o := (i + 4) % 8
		var c := cos(ph * TAU)
		walk["hips@pos"].append([t, V.call(0, 0.92 + 0.025 * absf(sin(ph * TAU)), 0)])
		walk["hips"].append([t, V.call(0, 6 * c, 2 * sin(ph * TAU))])
		walk["torso"].append([t, V.call(-12, -6 * c, 0)])
		walk["head"].append([t, V.call(8, 5 * c, 0)])
		walk["leg_r"].append([t, V.call(hip[i], 0, 5)])
		walk["knee_r"].append([t, V.call(knee[i], 0, 0)])
		walk["foot_r"].append([t, V.call(foot[i], 0, 0)])
		walk["leg_l"].append([t, V.call(hip[o], 0, -5)])
		walk["knee_l"].append([t, V.call(knee[o], 0, 0)])
		walk["foot_l"].append([t, V.call(foot[o], 0, 0)])
		walk["shoulder_r"].append([t, guard_r + V.call(-6 * c, 0, 0)])
		walk["elbow_r"].append([t, V.call(72 + 6 * c, 0, 0)])
	_anim(lib, "walk", 0.7, true, walk, rest)
	# Strafe (EnTest's side-step while circling the hero): played forward it
	# steps to its right, backward to its left; guard up all the while.
	var strafe := {"hips@pos": [], "torso": [[0.0, V.call(-12, 8, 0)]], "head": [[0.0, V.call(8, -8, 0)]],
		"leg_r": [], "knee_r": [], "foot_r": [[0.0, V.call(22, 0, -6)]], "leg_l": [], "knee_l": [], "foot_l": [[0.0, V.call(10, 0, 6)]],
		"shoulder_r": [], "elbow_r": [[0.0, V.call(72, 0, 0)]], "hand_r": [[0.0, V.call(-34, 0, 0)]],
		"shoulder_l": [[0.0, guard_l]], "elbow_l": [[0.0, V.call(80, 0, 0)]]}
	for i in 8:
		var ph := i / 8.0
		var t := ph * 0.6
		var s := sin(ph * TAU)
		# The right foot reaches out (first half), then the left closes up to it.
		var reach := maxf(s, 0.0)
		var close := maxf(-s, 0.0)
		strafe["hips@pos"].append([t, V.call(0, 0.92 + 0.03 * absf(s), 0)])
		strafe["leg_r"].append([t, V.call(-10 + 10 * reach, 0, 7 + 16 * reach)])
		strafe["knee_r"].append([t, V.call(-24 - 26 * reach, 0, 0)])
		strafe["leg_l"].append([t, V.call(24 + 8 * close, 0, -6 + 14 * close)])
		strafe["knee_l"].append([t, V.call(-34 - 24 * close, 0, 0)])
		strafe["shoulder_r"].append([t, guard_r + V.call(3 * s, 0, 0)])
	_anim(lib, "strafe", 0.6, true, strafe, rest)
	# Guard: the shield punched out to meet the blow, the body braced behind it.
	var block: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.88, 0.04), "torso": V.call(-16, 12, 0), "head": V.call(10, -10, 0),
		"shoulder_l": V.call(86, -40, -10), "elbow_l": V.call(58, 0, 0), "shoulder_r": V.call(24, 0, 32),
		"knee_l": V.call(-46, 0, 0), "knee_r": V.call(-32, 0, 0)})
	_pose_anim(lib, "guard", 0.25, [[0.0, stance], [0.06, block], [0.25, with.call(block, {"shoulder_l": V.call(78, -36, -14), "elbow_l": V.call(66, 0, 0)})]], stance, rest)
	# The horizontal slash (EnTest_SlashDown's quick cut): the blade drawn back
	# over the right shoulder, held, then flung across in front.
	var cocked: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.9, 0.03), "torso": V.call(-6, -40, 0), "head": V.call(6, 30, 0),
		"shoulder_r": V.call(84, -72, 12), "elbow_r": V.call(30, 0, 0), "hand_r": V.call(-74, 0, 0),
		"leg_l": V.call(18, 0, -6), "knee_l": V.call(-28, 0, 0)})
	var anticip: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.89, 0.01), "torso": V.call(-14, -16, 0),
		"shoulder_r": V.call(64, -36, 16), "elbow_r": V.call(60, 0, 0), "hand_r": V.call(-56, 0, 0)})
	_pose_anim(lib, "windup", 0.4, [[0.0, stance], [0.12, anticip], [0.3, cocked], [0.4, with.call(cocked, {"shoulder_r": V.call(85, -76, 12), "torso": V.call(-6, -44, 0)})]], stance, rest)
	var cut_mid: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.86, -0.06), "torso": V.call(-14, 6, 0), "head": V.call(6, -4, 0),
		"shoulder_r": V.call(86, 4, 4), "elbow_r": V.call(8, 0, 0), "hand_r": V.call(-82, 0, 0),
		"leg_l": V.call(40, 0, -6), "knee_l": V.call(-50, 0, 0), "leg_r": V.call(-22, 0, 7), "knee_r": V.call(-16, 0, 0)})
	var cut_end: Dictionary = with.call(cut_mid, {"torso": V.call(-16, 42, 0), "head": V.call(6, -26, 0),
		"shoulder_r": V.call(84, 80, -10), "elbow_r": V.call(16, 0, 0), "hand_r": V.call(-78, 0, 0)})
	_pose_anim(lib, "slash", 0.3, [[0.0, with.call(cocked, {"shoulder_r": V.call(85, -76, 12), "torso": V.call(-6, -44, 0)})],
		[0.05, cut_mid], [0.11, cut_end], [0.3, with.call(cut_end, {"shoulder_r": V.call(72, 72, -8), "elbow_r": V.call(30, 0, 0)})]], stance, rest)
	# The leaping chop (EnTest_SetupJumpslash): down into a crouch, up with
	# the blade raised two-handed over its skull, and down with it.
	var crouch: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.76, 0.04), "torso": V.call(-24, 0, 0), "head": V.call(14, 0, 0),
		"leg_r": V.call(30, 0, 7), "knee_r": V.call(-64, 0, 0), "foot_r": V.call(34, 0, 0),
		"leg_l": V.call(44, 0, -6), "knee_l": V.call(-74, 0, 0), "foot_l": V.call(30, 0, 0),
		"shoulder_r": V.call(30, 0, 24), "elbow_r": V.call(70, 0, 0)})
	var aloft: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.28, 0), "torso": V.call(16, 0, 0), "head": V.call(-8, 0, 0),
		"shoulder_r": V.call(176, 0, 8), "elbow_r": V.call(46, 0, 0), "hand_r": V.call(-26, 90, 0),
		"shoulder_l": V.call(150, 0, -16), "elbow_l": V.call(60, 0, 0),
		"leg_r": V.call(64, 0, 7), "knee_r": V.call(-96, 0, 0), "leg_l": V.call(40, 0, -6), "knee_l": V.call(-86, 0, 0)})
	var chopped: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.84, -0.12), "torso": V.call(-42, 0, 0), "head": V.call(22, 0, 0),
		"shoulder_r": V.call(56, 0, 6), "elbow_r": V.call(4, 0, 0), "hand_r": V.call(-78, 90, 0),
		"shoulder_l": V.call(54, 0, -12), "elbow_l": V.call(24, 0, 0),
		"leg_r": V.call(-14, 0, 7), "knee_r": V.call(-30, 0, 0), "leg_l": V.call(48, 0, -6), "knee_l": V.call(-66, 0, 0)})
	_pose_anim(lib, "jump_chop", 0.7, [[0.0, stance], [0.12, crouch], [0.32, aloft], [0.46, with.call(aloft, {"hips@pos": V.call(0, 1.1, -0.06), "shoulder_r": V.call(150, 0, 8)})],
		[0.54, chopped], [0.7, with.call(chopped, {"hips@pos": V.call(0, 0.86, -0.1), "torso": V.call(-34, 0, 0)})]], stance, rest)
	# Hurt: the hit snaps it back, skull lolling, then it gathers itself.
	var struck: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.94, 0.08), "torso": V.call(18, -8, 12), "head": V.call(28, 14, 16),
		"shoulder_r": V.call(16, 0, 52), "elbow_r": V.call(40, 0, 0), "shoulder_l": V.call(22, 0, -50), "elbow_l": V.call(50, 0, 0),
		"leg_l": V.call(10, 0, -8), "knee_l": V.call(-20, 0, 0)})
	_pose_anim(lib, "hurt", 0.35, [[0.0, struck], [0.12, with.call(struck, {"torso": V.call(10, -4, 6), "head": V.call(18, 8, 8)})], [0.35, stance]], stance, rest)
	# Stunned: swaying where it stands, arms hanging, the jaw slack.
	_anim(lib, "stunned", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.94, 0)], [0.2, V.call(0.02, 0.93, 0)], [0.4, V.call(0, 0.94, 0)], [0.6, V.call(-0.02, 0.93, 0)]],
		"torso": [[0.0, V.call(10, 0, -12)], [0.2, V.call(14, 6, 0)], [0.4, V.call(10, 0, 12)], [0.6, V.call(14, -6, 0)]],
		"head": [[0.0, V.call(22, 0, 12)], [0.2, V.call(28, -8, 0)], [0.4, V.call(22, 0, -12)], [0.6, V.call(28, 8, 0)]],
		"shoulder_r": [[0.0, V.call(6, 0, 14)], [0.4, V.call(10, 0, 20)]], "elbow_r": [[0.0, V.call(18, 0, 0)]], "hand_r": [[0.0, V.call(-10, 0, 0)]],
		"shoulder_l": [[0.0, V.call(10, 0, -20)], [0.4, V.call(6, 0, -14)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(4, 0, 8)]], "knee_r": [[0.0, V.call(-22, 0, 0)], [0.4, V.call(-16, 0, 0)]],
		"leg_l": [[0.0, V.call(6, 0, -8)]], "knee_l": [[0.0, V.call(-16, 0, 0)], [0.4, V.call(-24, 0, 0)]],
	}, rest)
	# Hop back: a crouch, a spring backward with the knees tucked, and down
	# again into its guard.
	var spring: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.12, 0.06), "torso": V.call(6, 0, 0),
		"leg_r": V.call(34, 0, 7), "knee_r": V.call(-72, 0, 0), "leg_l": V.call(30, 0, -6), "knee_l": V.call(-70, 0, 0)})
	_pose_anim(lib, "hop_back", 0.4, [[0.0, with.call(crouch, {"shoulder_r": guard_r, "elbow_r": V.call(72, 0, 0)})], [0.16, spring],
		[0.32, with.call(stance, {"hips@pos": V.call(0, 0.86, 0), "knee_r": V.call(-40, 0, 0), "knee_l": V.call(-48, 0, 0)})], [0.4, stance]], stance, rest)
	# Death: the knees go, the skull drops, and it folds down onto the bones.
	_pose_anim(lib, "death", 0.8, [[0.0, struck], [0.25, with.call(stance, {"hips@pos": V.call(0, 0.7, 0.04), "torso": V.call(24, 0, 14), "head": V.call(30, 20, 20),
		"knee_r": V.call(-70, 0, 0), "knee_l": V.call(-80, 0, 0), "leg_r": V.call(30, 0, 12), "leg_l": V.call(40, 0, -12),
		"shoulder_r": V.call(10, 0, 40), "shoulder_l": V.call(10, 0, -40), "elbow_r": V.call(20, 0, 0), "elbow_l": V.call(20, 0, 0)})],
		[0.8, {"hips@pos": V.call(0, 0.22, 0.1), "torso": V.call(52, 0, 22), "head": V.call(44, 30, 30),
		"leg_r": V.call(84, 0, 22), "knee_r": V.call(-124, 0, 0), "leg_l": V.call(84, 0, -22), "knee_l": V.call(-124, 0, 0),
		"shoulder_r": V.call(0, 0, 64), "shoulder_l": V.call(0, 0, -64), "elbow_r": V.call(10, 0, 0), "elbow_l": V.call(10, 0, 0),
		"hand_r": V.call(-10, 0, 0), "foot_r": V.call(10, 0, 0), "foot_l": V.call(10, 0, 0)}]], stance, rest)
	_finish_character(root, lib)
	_save_scene(root, "stalfos.tscn")


# --- Shell Blade (EnSb) ---------------------------------------------------------

## A big ridged clam: two shells hinged at the back, a pale tongue and one
## eye inside, and a row of teeth round the lip.
func _build_shellblade() -> void:
	var SHELL := _c("6a8ab0")
	var SHELL_D := _c("4a6488")
	var RIDGE := _c("a8c0d8")
	var FLESH := _c("e88a90")
	var TOOTH := _c("f0ece0")
	_root = Node3D.new()
	_root.name = "ShellbladeModel"
	_paths = {}
	var root := _root
	var shell_half := func(k: MeshKit, h: MeshKit, up: float) -> void:
		# A dome: the rim (wide, at y 0) rising to the crown 0.3 above (or below).
		var rings: Array = []
		for i in 7:
			var t := float(i) / 6.0
			var r := cos(t * PI * 0.5) * 0.62 + 0.001
			rings.append([up * sin(t * PI * 0.5) * 0.3, r, r * 0.85, SHELL if i % 2 == 0 else SHELL_D])
		if up < 0.0:
			rings.reverse()
		k.loft(rings, 12)
		for i in 7:
			var a := PI + PI * (i + 0.5) / 7.0
			var d := Vector3(cos(a), 0, sin(a))
			h.box(d * 0.33 + Vector3(0, up * 0.2, 0), Vector3(0.05, 0.06, 0.05) + d.abs() * 0.4, RIDGE)
		for i in 9:
			var a := PI + PI * (i + 0.5) / 9.0
			var d := Vector3(cos(a), 0, sin(a))
			h.prism(d * 0.6 + Vector3(0, up * 0.01, 0), 0.035, d * 0.56 + Vector3(0, -up * 0.07, 0), 0.0, 4, TOOTH)
	_joint(root, "bottom", "Bottom", Vector3(0, 0.32, 0), func(p: Parts) -> void:
		var k := p.k()
		var h := p.k("hard")
		shell_half.call(k, h, -1.0)
		h.box(Vector3(0, 0.02, -0.05), Vector3(0.6, 0.06, 0.6), FLESH)
		h.icosa(Vector3(0, 0.08, -0.25), Vector3(0.18, 0.08, 0.14), 0.1, FLESH.darkened(0.1))
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.12, -0.08), Vector3(0.09, 0.09, 0.07), 0.0, Color.WHITE)
		g.box(Vector3(0, 0.12, -0.15), Vector3(0.03, 0.08, 0.01), _c("101010"))
	)
	_joint(root.get_node("Bottom"), "top", "Top", Vector3(0, 0.0, 0.5), func(p: Parts) -> void:
		var k := p.k()
		var h := p.k("hard")
		k.push(Transform3D(Basis(), Vector3(0, 0, -0.5)))
		h.push(Transform3D(Basis(), Vector3(0, 0, -0.5)))
		shell_half.call(k, h, 1.0)
		k.pop()
		h.pop()
	)
	var lib := AnimationLibrary.new()
	var rest := {"bottom": Vector3(0, 0.32, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 1.4, true, {"top": [[0.0, V.call(3, 0, 0)], [0.7, V.call(8, 0, 0)]]}, rest)
	_anim(lib, "hop", 0.4, false, {"bottom@pos": [[0.0, V.call(0, 0.32, 0)], [0.2, V.call(0, 0.75, 0)], [0.4, V.call(0, 0.32, 0)]],
		"bottom": [[0.0, V.call(0, 0, 0)], [0.2, V.call(-10, 0, 0)], [0.4, V.call(0, 0, 0)]], "top": [[0.0, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "open", 0.3, false, {"top": [[0.0, V.call(5, 0, 0)], [0.3, V.call(60, 0, 0)]]}, rest)
	_anim(lib, "bite", 0.25, false, {"top": [[0.0, V.call(60, 0, 0)], [0.08, V.call(0, 0, 0)]],
		"bottom@pos": [[0.0, V.call(0, 0.32, 0)], [0.08, V.call(0, 0.38, -0.3)], [0.25, V.call(0, 0.32, 0)]]}, rest)
	_anim(lib, "stunned", 0.6, true, {"top": [[0.0, V.call(70, 0, 0)], [0.3, V.call(62, 0, 0)]], "bottom": [[0.0, V.call(0, 0, 8)], [0.3, V.call(0, 0, -8)]]}, rest)
	_anim(lib, "death", 0.6, false, {"top": [[0.0, V.call(60, 0, 0)], [0.6, V.call(110, 0, 0)]], "bottom": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 40)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "shellblade.tscn")


# --- Tide Knight (EnIk) ---------------------------------------------------------

## A huge knight in barnacled blue-green plate trimmed with gold, a finned helm
## with a glowing slit, and a heavy cleaver. Its plates (ArmorChest,
## ArmorShoulderL/R) can be shed (the Iron Knuckle loses its armor).
func _build_tide_knight() -> void:
	var PLATE := _c("4a6e7e")
	var PLATE_D := _c("34525e")
	var PLATE_L := _c("6a92a2")
	var GOLD := _c("c8a040")
	var SUIT := _c("26323a")
	var SUIT_L := _c("36444c")
	var STEEL := _c("a8b4bc")
	var GRIP := _c("4a3424")
	var GLOW := _c("60e8ff")
	_root = Node3D.new()
	_root.name = "TideKnightModel"
	_paths = {}
	var root := _root
	var hips := _joint(root, "hips", "Hips", Vector3(0, 1.25, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.2, 0.22, 0.18, SUIT], [0.0, 0.26, 0.2, SUIT_L], [0.12, 0.27, 0.21, SUIT]], 9)
		var h := p.k("hard")
		# Tasset plates over the hips.
		for sx in [-1.0, 0.0, 1.0]:
			h.slab(Vector3(sx * 0.17, -0.02, -0.21), Vector2(0.17, 0.04), Vector3(sx * 0.19, -0.33, -0.25), Vector2(0.15, 0.04), PLATE)
		h.box(Vector3(0, 0.1, 0), Vector3(0.58, 0.07, 0.46), GOLD)
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.12, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.26, 0.2, SUIT], [0.3, 0.33, 0.25, SUIT_L], [0.55, 0.3, 0.22, SUIT], [0.62, 0.12, 0.1, SUIT]], 9)
	)
	_attach(torso, "ArmorChest", Vector3.ZERO, func(p: Parts) -> void:
		var h := p.k("hard")
		h.loft([[0.05, 0.3, 0.24, PLATE_D], [0.32, 0.37, 0.29, PLATE], [0.52, 0.34, 0.26, PLATE_L], [0.6, 0.2, 0.16, PLATE]], 10)
		h.box(Vector3(0, 0.33, -0.29), Vector3(0.1, 0.4, 0.03), GOLD)
		for i in 5:
			h.icosa(Vector3(-0.2 + i * 0.1, 0.12 + (i % 2) * 0.08, 0.27), Vector3(0.04, 0.035, 0.03), 0.3, _c("c8c0a8"))
	)
	_joint(torso, "head", "Head", Vector3(0, 0.66, -0.02), func(p: Parts) -> void:
		var h := p.k("hard")
		h.loft([[0.0, 0.14, 0.15, PLATE_D], [0.1, 0.17, 0.19, PLATE], [0.26, 0.16, 0.18, PLATE_L], [0.36, 0.08, 0.09, PLATE], [0.38, 0.0, 0.0, PLATE]], 9)
		h.box(Vector3(0, 0.16, -0.18), Vector3(0.24, 0.05, 0.03), _c("0c1014"))
		# The fin crest.
		h.face_dir([Vector3(0, 0.3, -0.12), Vector3(0, 0.62, 0.05), Vector3(0, 0.42, 0.28), Vector3(0, 0.3, 0.18)], _c("2a8a9a"), Vector3(1, 0, 0))
		h.face_dir([Vector3(0, 0.3, -0.12), Vector3(0, 0.62, 0.05), Vector3(0, 0.42, 0.28), Vector3(0, 0.3, 0.18)], _c("246e7c"), Vector3(-1, 0, 0))
		h.box(Vector3(0, 0.06, -0.17), Vector3(0.3, 0.05, 0.04), GOLD)
		var g := p.k("glow")
		g.box(Vector3(0, 0.16, -0.196), Vector3(0.18, 0.025, 0.005), GLOW)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.38 * side, 0.5, 0), func(p: Parts) -> void:
			p.k().loft([[0.05, 0.0, 0.0, SUIT], [0.0, 0.1, 0.1, SUIT_L], [-0.38, 0.085, 0.085, SUIT], [-0.42, 0.0, 0.0, SUIT]], 7)
		)
		_attach(shoulder, "ArmorShoulder" + nsfx, Vector3.ZERO, func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-20 * side)), Vector3(0.04 * side, 0.02, 0)))
			h.prism(Vector3(0, -0.08, 0), 0.2, Vector3(0, 0.1, 0), 0.12, 8, PLATE)
			h.prism(Vector3(0, -0.1, 0), 0.21, Vector3(0, -0.07, 0), 0.21, 8, GOLD)
			h.pop()
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.42, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.loft([[0.03, 0.0, 0.0, PLATE], [0.0, 0.09, 0.09, PLATE], [-0.34, 0.1, 0.1, PLATE_L], [-0.38, 0.0, 0.0, PLATE]], 7)
		)
		var hand := _joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.38, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.icosa(Vector3(0, -0.07, 0), Vector3(0.09, 0.1, 0.09), 0.1, PLATE_D)
		)
		if side > 0:
			# The cleaver: a long haft with a broad crescent blade.
			_attach(hand, "Cleaver", Vector3(0, -0.08, 0), func(p: Parts) -> void:
				var h := p.k("hard")
				h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
				h.prism(Vector3(0, -0.5, 0), 0.04, Vector3(0, 1.4, 0), 0.04, 6, GRIP)
				h.box(Vector3(0, 1.1, 0), Vector3(0.12, 0.12, 0.08), GOLD)
				var blade := [Vector3(0.0, 0.9, 0), Vector3(0.62, 1.0, 0), Vector3(0.72, 1.45, 0), Vector3(0.55, 1.85, 0), Vector3(0.0, 1.55, 0)]
				for i in 3:
					var a: Vector3 = blade[0]
					var b: Vector3 = blade[i + 1]
					var c: Vector3 = blade[i + 2]
					h.hexa([a + Vector3(0, 0, -0.025), b + Vector3(0, 0, -0.025), c + Vector3(0, 0, -0.025), c + Vector3(0, 0, -0.025),
						a + Vector3(0, 0, 0.025), b + Vector3(0, 0, 0.025), c + Vector3(0, 0, 0.025), c + Vector3(0, 0, 0.025)], STEEL)
				h.pop()
			, "cleaver")
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.15 * side, -0.08, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.loft([[0.05, 0.0, 0.0, SUIT], [0.0, 0.13, 0.13, SUIT_L], [-0.5, 0.11, 0.11, PLATE], [-0.56, 0.0, 0.0, PLATE]], 7)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.55, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.icosa(Vector3(0, 0, -0.06), Vector3(0.1, 0.1, 0.08), 0.0, GOLD)
			h.loft([[0.0, 0.11, 0.11, PLATE], [-0.48, 0.1, 0.1, PLATE_L], [-0.52, 0.0, 0.0, PLATE]], 7)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.52, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.box(Vector3(0, -0.06, -0.08), Vector3(0.2, 0.12, 0.38), PLATE_D)
		)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 1.25, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# Beta 1.6.0: EnIk is all weight. Its plod rolls the hips over each planted
	# foot, the windups gather and hang, and the blows follow through and take
	# a moment to haul back. The cleaver's edge is on the hand's +X and its
	# flat faces the hand's Y: the chop rolls the grip so the edge comes down
	# first (hand Y -90), the sweep so it leads across (hand Y 180).
	var arm_r: Vector3 = V.call(30, 0, 15)
	var arm_l: Vector3 = V.call(20, 0, -15)
	var stance := {
		"hips@pos": V.call(0, 1.23, 0), "hips": V.call(0, 0, 0), "torso": V.call(-6, 0, 0), "head": V.call(2, 0, 0),
		"shoulder_r": arm_r, "elbow_r": V.call(50, 0, 0), "hand_r": V.call(-40, 0, 0),
		"shoulder_l": arm_l, "elbow_l": V.call(40, 0, 0),
		"leg_r": V.call(-5, 0, 5), "knee_r": V.call(-10, 0, 0), "foot_r": V.call(15, 0, 0),
		"leg_l": V.call(15, 0, -5), "knee_l": V.call(-15, 0, 0), "foot_l": V.call(0, 0, 0),
	}
	var with := func(a: Dictionary, b: Dictionary) -> Dictionary:
		var c := a.duplicate()
		c.merge(b, true)
		return c
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Idle: slow heavy breaths that lift the shoulders, the cleaver's head
	# dipping with them.
	_pose_anim(lib, "idle", 1.8, [[0.0, stance],
		[0.9, with.call(stance, {"hips@pos": V.call(0, 1.205, 0), "torso": V.call(-10, 0, 0), "head": V.call(6, 0, 0),
			"shoulder_r": arm_r + V.call(4, 0, 2), "elbow_r": V.call(56, 0, 0), "shoulder_l": arm_l + V.call(3, 0, -2), "elbow_l": V.call(46, 0, 0),
			"knee_r": V.call(-14, 0, 0), "knee_l": V.call(-20, 0, 0), "foot_r": V.call(18, 0, 0), "foot_l": V.call(4, 0, 0)})],
		[1.8, stance]], stance, rest, true)
	# The plod: each foot comes down hard (the hips drop and the knee gives
	# under the weight), the body rolls out over it, and the free leg swings
	# through low. The cleaver rides at its right side; the left fist swings.
	var walk := {"hips@pos": [], "hips": [], "torso": [], "head": [], "leg_r": [], "knee_r": [], "foot_r": [],
		"leg_l": [], "knee_l": [], "foot_l": [], "shoulder_r": [], "elbow_r": [], "hand_r": [[0.0, V.call(-40, 0, 0)]],
		"shoulder_l": [], "elbow_l": []}
	var hip := [24, 16, 2, -12, -20, -6, 12, 22]
	var knee := [-8, -26, -12, -10, -24, -46, -30, -10]
	var foot := [-8, 6, 6, 14, 20, 8, -4, -8]
	var drop := [0.0, -0.06, -0.02, 0.01, 0.0, -0.06, -0.02, 0.01]
	for i in 8:
		var ph := i / 8.0
		var t := ph * 1.4
		var o := (i + 4) % 8
		var c := cos(ph * TAU)
		var sway := sin(ph * TAU)
		walk["hips@pos"].append([t, V.call(0.05 * c, 1.23 + drop[i], 0)])
		walk["hips"].append([t, V.call(0, 7 * c, -4 * c)])
		walk["torso"].append([t, V.call(-7, -6 * c, 5 * c)])
		walk["head"].append([t, V.call(3, 3 * c, -2 * c)])
		walk["leg_r"].append([t, V.call(hip[i], 0, 5 + 3 * maxf(sway, 0.0))])
		walk["knee_r"].append([t, V.call(knee[i], 0, 0)])
		walk["foot_r"].append([t, V.call(foot[i], 0, 0)])
		walk["leg_l"].append([t, V.call(hip[o], 0, -5 - 3 * maxf(-sway, 0.0))])
		walk["knee_l"].append([t, V.call(knee[o], 0, 0)])
		walk["foot_l"].append([t, V.call(foot[o], 0, 0)])
		walk["shoulder_r"].append([t, arm_r + V.call(-8 * c, 0, 0)])
		walk["elbow_r"].append([t, V.call(50 + 6 * c, 0, 0)])
		walk["shoulder_l"].append([t, arm_l + V.call(14 * c, 0, 0)])
		walk["elbow_l"].append([t, V.call(40 - 8 * c, 0, 0)])
	_anim(lib, "walk", 1.4, true, walk, rest)
	# The overhead chop (EnIk_VerticalAttack): it sinks, then heaves the
	# cleaver up two-handed and rears back with it, and holds it there,
	# trembling, before it falls.
	var gather: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.16, 0.02), "torso": V.call(-14, 0, 0), "head": V.call(8, 0, 0),
		"shoulder_r": V.call(70, 0, 12), "elbow_r": V.call(70, 0, 0), "hand_r": V.call(-80, -90, 0),
		"shoulder_l": V.call(74, 0, -20), "elbow_l": V.call(74, 0, 0),
		"knee_r": V.call(-22, 0, 0), "knee_l": V.call(-28, 0, 0), "leg_l": V.call(22, 0, -5)})
	var high: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.27, 0.06), "torso": V.call(20, 0, 0), "head": V.call(-12, 0, 0),
		"shoulder_r": V.call(176, 0, 10), "elbow_r": V.call(52, 0, 0), "hand_r": V.call(-88, -90, 0),
		"shoulder_l": V.call(166, 0, -28), "elbow_l": V.call(62, 0, 0),
		"leg_l": V.call(24, 0, -5), "knee_l": V.call(-6, 0, 0), "leg_r": V.call(-12, 0, 5), "knee_r": V.call(-4, 0, 0), "foot_r": V.call(24, 0, 0)})
	var tremble: Dictionary = with.call(high, {"torso": V.call(23, 0, 1), "shoulder_r": V.call(179, 0, 11), "shoulder_l": V.call(169, 0, -27)})
	_pose_anim(lib, "chop_windup", 0.8, [[0.0, stance], [0.18, gather], [0.5, high], [0.64, tremble], [0.8, high]], stance, rest)
	var falling: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.18, -0.08), "torso": V.call(-14, 0, 0), "head": V.call(4, 0, 0),
		"shoulder_r": V.call(118, 0, 8), "elbow_r": V.call(18, 0, 0), "hand_r": V.call(-88, -90, 0),
		"shoulder_l": V.call(112, 0, -14), "elbow_l": V.call(26, 0, 0),
		"leg_l": V.call(34, 0, -5), "knee_l": V.call(-40, 0, 0)})
	var struck: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.06, -0.18), "torso": V.call(-46, 0, 0), "head": V.call(22, 0, 0),
		"shoulder_r": V.call(58, 0, 5), "elbow_r": V.call(4, 0, 0), "hand_r": V.call(-86, -90, 0),
		"shoulder_l": V.call(58, 0, -10), "elbow_l": V.call(10, 0, 0),
		"leg_l": V.call(46, 0, -5), "knee_l": V.call(-62, 0, 0), "leg_r": V.call(-16, 0, 5), "knee_r": V.call(-26, 0, 0), "foot_r": V.call(34, 0, 0)})
	_pose_anim(lib, "chop", 0.25, [[0.0, high], [0.06, falling], [0.12, struck], [0.25, with.call(struck, {"hips@pos": V.call(0, 1.08, -0.18), "torso": V.call(-44, 0, 0)})]], stance, rest)
	# Recover: it stays bent over the buried blade a moment, then wrenches it
	# free and straightens up.
	var wrench: Dictionary = with.call(struck, {"hips@pos": V.call(0, 1.12, -0.14), "torso": V.call(-34, 8, 0), "head": V.call(14, -6, 0),
		"shoulder_r": V.call(68, 0, 8), "elbow_r": V.call(22, 0, 0), "hand_r": V.call(-70, -60, 0)})
	_pose_anim(lib, "recover", 0.9, [[0.0, with.call(struck, {"hips@pos": V.call(0, 1.08, -0.18), "torso": V.call(-44, 0, 0)})],
		[0.35, with.call(struck, {"hips@pos": V.call(0, 1.09, -0.17), "torso": V.call(-42, 2, 0)})], [0.55, wrench], [0.9, stance]], stance, rest)
	# The sweep (EnIk's horizontal attack): the cleaver drawn back past the
	# right hip, the body wound round after it; then one great turning swing
	# across the front, stepping into it, and on round past the left.
	var drawn: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.15, 0.04), "hips": V.call(0, -14, 0), "torso": V.call(-8, -54, 0), "head": V.call(4, 40, 0),
		"shoulder_r": V.call(70, -70, 30), "elbow_r": V.call(34, 0, 0), "hand_r": V.call(-74, 180, 0),
		"shoulder_l": V.call(70, 50, -10), "elbow_l": V.call(90, 0, 0),
		"leg_r": V.call(-10, 0, 9), "knee_r": V.call(-30, 0, 0), "leg_l": V.call(16, 0, -9), "knee_l": V.call(-34, 0, 0)})
	_pose_anim(lib, "sweep_windup", 0.6, [[0.0, stance], [0.2, with.call(drawn, {"torso": V.call(-8, -34, 0), "shoulder_r": V.call(56, -40, 26), "hand_r": V.call(-60, 120, 0)})],
		[0.5, drawn], [0.6, with.call(drawn, {"torso": V.call(-8, -58, 0)})]], stance, rest)
	var across: Dictionary = with.call(stance, {"hips@pos": V.call(0, 1.12, -0.1), "hips": V.call(0, 6, 0), "torso": V.call(-12, 4, 0), "head": V.call(2, -4, 0),
		"shoulder_r": V.call(84, 0, 8), "elbow_r": V.call(8, 0, 0), "hand_r": V.call(-82, 180, 0),
		"shoulder_l": V.call(60, 20, -20), "elbow_l": V.call(60, 0, 0),
		"leg_l": V.call(38, 0, -7), "knee_l": V.call(-44, 0, 0), "leg_r": V.call(-20, 0, 7), "knee_r": V.call(-16, 0, 0)})
	var round_: Dictionary = with.call(across, {"hips": V.call(0, 18, 0), "torso": V.call(-12, 60, 0), "head": V.call(2, -38, 0),
		"shoulder_r": V.call(80, 80, -14), "elbow_r": V.call(14, 0, 0), "hand_r": V.call(-78, 180, 0),
		"shoulder_l": V.call(30, 0, -50), "elbow_l": V.call(30, 0, 0)})
	_pose_anim(lib, "sweep", 0.4, [[0.0, with.call(drawn, {"torso": V.call(-8, -58, 0)})], [0.1, across], [0.22, round_],
		[0.4, with.call(round_, {"torso": V.call(-10, 54, 0), "shoulder_r": V.call(70, 74, -12), "elbow_r": V.call(24, 0, 0)})]], stance, rest)
	# A flinch that barely moves it: the plate rings and the head jolts.
	_pose_anim(lib, "hurt", 0.3, [[0.0, with.call(stance, {"hips@pos": V.call(0, 1.22, 0.05), "torso": V.call(12, 0, 6), "head": V.call(16, 6, 6)})],
		[0.1, with.call(stance, {"torso": V.call(4, 0, 2), "head": V.call(6, 2, 2)})], [0.3, stance]], stance, rest)
	# Death: it drops to its knees, sways, and topples forward on its face.
	var knees: Dictionary = with.call(stance, {"hips@pos": V.call(0, 0.72, 0.1), "torso": V.call(-22, 0, 4), "head": V.call(-14, 0, 0),
		"leg_r": V.call(84, 0, 5), "knee_r": V.call(-104, 0, 0), "foot_r": V.call(30, 0, 0),
		"leg_l": V.call(12, 0, -5), "knee_l": V.call(-100, 0, 0), "foot_l": V.call(40, 0, 0),
		"shoulder_r": V.call(10, 0, 30), "elbow_r": V.call(20, 0, 0), "shoulder_l": V.call(4, 0, -30), "elbow_l": V.call(20, 0, 0)})
	_pose_anim(lib, "death", 1.4, [[0.0, stance], [0.5, knees], [0.8, with.call(knees, {"torso": V.call(-14, 0, -6), "head": V.call(-24, 0, 0)})],
		[1.4, with.call(knees, {"hips@pos": V.call(0, 0.45, 0.4), "torso": V.call(-82, 0, 10), "head": V.call(-30, 0, 0),
			"shoulder_r": V.call(-10, 0, 40), "shoulder_l": V.call(-10, 0, -40)})]], stance, rest)
	_finish_character(root, lib)
	_save_scene(root, "tide_knight.tscn")


# --- Carapax, the shrine's master ---------------------------------------------------

## A giant crab in a domed shell barnacled with coral, six jointed legs, two
## great claws, and one huge glowing eye on a stalk. Its soft pale underside
## shows when it is thrown on its back.
func _build_carapax() -> void:
	var SHELL := _c("2a4a7a")
	var SHELL_L := _c("3a6a9a")
	var SHELL_D := _c("1a2e50")
	var BELLY := _c("e8d4a8")
	var LEG := _c("8a3a3a")
	var LEG_D := _c("5a2228")
	var CLAW := _c("a84a3a")
	var CORAL := _c("e07a6a")
	var EYE := _c("e8ff70")
	_root = Node3D.new()
	_root.name = "CarapaxModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 1.9, 0), func(p: Parts) -> void:
		var k := p.k()
		# The dome (above), the belly (below), a fringe of plates round the rim.
		k.loft([[-0.75, 0.0, 0.0, BELLY], [-0.7, 1.2, 0.95, BELLY], [-0.45, 1.9, 1.5, BELLY.darkened(0.1)], [-0.2, 2.15, 1.7, SHELL_D],
			[0.15, 2.1, 1.65, SHELL], [0.6, 1.75, 1.35, SHELL_L], [1.0, 1.1, 0.85, SHELL], [1.2, 0.0, 0.0, SHELL]], 14)
		var h := p.k("hard")
		for i in 14:
			var a := TAU * i / 14.0
			var d := Vector3(cos(a) * 2.15, 0, sin(a) * 1.7)
			h.prism(d * 0.98 + Vector3(0, -0.25, 0), 0.22, d * 1.1 + Vector3(0, -0.4, 0), 0.0, 4, SHELL_D)
		for i in 16:
			var a := TAU * i / 16.0 + 0.2
			var rr := 0.5 + (i % 3) * 0.35
			h.icosa(Vector3(cos(a) * rr * 1.2, 1.05 - rr * 0.2, sin(a) * rr), Vector3(0.14, 0.12, 0.14), 0.3, CORAL if i % 2 == 0 else _c("c8c0a8"))
		# Mouth parts at the front.
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.18 * sx, -0.25, -1.62), Vector3(0.2, 0.35, 0.12), LEG_D)
		h.box(Vector3(0, -0.15, -1.66), Vector3(0.3, 0.15, 0.08), _c("1a0a0a"))
	)
	var stalk := _joint(body, "stalk", "Stalk", Vector3(0, 0.75, -1.05), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.14, 0.14, SHELL_D], [0.5, 0.11, 0.11, LEG], [0.95, 0.12, 0.12, LEG_D]], 7)
	)
	_joint(stalk, "eye", "Eye", Vector3(0, 1.0, 0), func(p: Parts) -> void:
		var h := p.k("hard")
		h.icosa(Vector3(0, 0.1, 0), Vector3(0.36, 0.36, 0.36), 0.0, LEG_D, true)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.12, -0.12), Vector3(0.3, 0.3, 0.28), 0.0, EYE, true)
		g.box(Vector3(0, 0.12, -0.4), Vector3(0.08, 0.32, 0.02), _c("101008"))
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		# Claws: shoulder out at the front corners, a forearm, a big pincer.
		var arm := _joint(body, "arm" + sfx, "Arm" + nsfx, Vector3(1.35 * side, -0.1, -1.1), func(p: Parts) -> void:
			var k := p.k()
			k.push(_aim(Vector3(0.6 * side, 0.15, -1.0), Vector3.ZERO))
			k.loft([[0.0, 0.22, 0.22, LEG_D], [0.5, 0.2, 0.2, LEG], [1.0, 0.18, 0.18, LEG_D]], 7)
			k.pop()
		)
		var fore := _joint(arm, "fore" + sfx, "Fore" + nsfx, Vector3(0.6 * side, 0.15, -1.0).normalized() * 1.0, func(p: Parts) -> void:
			var k := p.k()
			k.push(_aim(Vector3(-0.2 * side, 0.3, -1.0), Vector3.ZERO))
			k.loft([[0.0, 0.2, 0.2, LEG], [0.5, 0.32, 0.26, CLAW], [1.1, 0.34, 0.28, CLAW], [1.5, 0.12, 0.1, CLAW.darkened(0.2)], [1.7, 0.0, 0.0, CLAW.darkened(0.3)]], 8)
			k.pop()
		)
		_joint(fore, "pincer" + sfx, "Pincer" + nsfx, Vector3(-0.2 * side, 0.3, -1.0).normalized() * 0.9 + Vector3(0, 0.2, 0), func(p: Parts) -> void:
			var k := p.k()
			k.push(_aim(Vector3(-0.15 * side, 0.15, -1.0), Vector3.ZERO))
			k.loft([[0.0, 0.14, 0.12, CLAW], [0.5, 0.12, 0.1, CLAW], [0.85, 0.0, 0.0, CLAW.darkened(0.3)]], 7)
			k.pop()
		)
		for i in 3:
			var z := -0.3 + i * 0.6
			var mount := Node3D.new()
			mount.name = "LegMount%s%d" % [nsfx, i]
			mount.position = Vector3(1.6 * side, -0.35, z)
			mount.rotation.y = 0.0 if side > 0 else PI
			body.add_child(mount)
			var leg := _joint(mount, "leg%s%d" % [sfx, i], "Leg%s%d" % [nsfx, i], Vector3.ZERO, func(p: Parts) -> void:
				var k := p.k()
				k.push(_aim(Vector3(1, 0.6, 0), Vector3.ZERO))
				k.loft([[0.0, 0.13, 0.13, LEG_D], [0.6, 0.11, 0.11, LEG], [0.95, 0.1, 0.1, LEG_D]], 6)
				k.pop()
			)
			_joint(leg, "shin%s%d" % [sfx, i], "Shin%s%d" % [nsfx, i], Vector3(1, 0.6, 0).normalized() * 0.95, func(p: Parts) -> void:
				var k := p.k()
				k.push(_aim(Vector3(0.45, -1, 0), Vector3.ZERO))
				k.loft([[0.0, 0.1, 0.1, LEG], [0.9, 0.06, 0.06, LEG_D], [1.9, 0.0, 0.0, _c("2a1010")]], 6)
				k.pop()
			)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 1.9, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var legs: Array = []
	for s in ["_r", "_l"]:
		for i in 3:
			legs.append("%s%d" % [s, i])
	var claws_up := {"arm_r": [[0.0, V.call(0, 0, 0)]], "arm_l": [[0.0, V.call(0, 0, 0)]]}
	_anim(lib, "RESET", 0.1, false, {}, rest)
	var idle := {"body@pos": [[0.0, V.call(0, 1.9, 0)], [0.8, V.call(0, 1.82, 0)]], "stalk": [[0.0, V.call(-5, 0, 4)], [0.8, V.call(5, 0, -4)]],
		"pincer_r": [[0.0, V.call(0, 0, 0)], [0.4, V.call(20, 0, 0)], [0.8, V.call(0, 0, 0)]], "pincer_l": [[0.0, V.call(15, 0, 0)], [0.4, V.call(0, 0, 0)], [0.8, V.call(15, 0, 0)]]}
	_anim(lib, "idle", 1.6, true, idle, rest)
	var walk := {"body@pos": [[0.0, V.call(0, 1.9, 0)], [0.2, V.call(0, 1.98, 0)], [0.4, V.call(0, 1.9, 0)], [0.6, V.call(0, 1.98, 0)]],
		"stalk": [[0.0, V.call(0, 0, 6)], [0.4, V.call(0, 0, -6)]]}
	for i in legs.size():
		var l: String = legs[i]
		var ph := 0.4 * (i % 2)
		walk["leg" + l] = [[0.0, V.call(0, 15 if i % 2 == 0 else -15, 15)], [0.4, V.call(0, -15 if i % 2 == 0 else 15, 0)]]
		var _unused := ph
	_anim(lib, "walk", 0.8, true, walk, rest)
	# Claw snap: the right claw rises high and opens, then slams down shut.
	_anim(lib, "snap_windup", 0.7, false, {"arm_r": [[0.0, V.call(0, 0, 0)], [0.7, V.call(55, 0, 25)]], "fore_r": [[0.0, V.call(0, 0, 0)], [0.7, V.call(-35, 0, 0)]],
		"pincer_r": [[0.0, V.call(0, 0, 0)], [0.7, V.call(50, 0, 0)]], "body": [[0.0, V.call(0, 0, 0)], [0.7, V.call(8, 0, -6)]]}, rest)
	_anim(lib, "snap", 0.25, false, {"arm_r": [[0.0, V.call(55, 0, 25)], [0.1, V.call(-30, 0, 5)], [0.25, V.call(-30, 0, 5)]], "fore_r": [[0.0, V.call(-35, 0, 0)], [0.1, V.call(20, 0, 0)]],
		"pincer_r": [[0.0, V.call(50, 0, 0)], [0.1, V.call(0, 0, 0)]], "body": [[0.0, V.call(8, 0, -6)], [0.1, V.call(-8, 0, 4)], [0.25, V.call(-8, 0, 4)]]}, rest)
	_anim(lib, "recover", 0.6, false, {"arm_r": [[0.0, V.call(-30, 0, 5)], [0.6, V.call(0, 0, 0)]], "fore_r": [[0.0, V.call(20, 0, 0)], [0.6, V.call(0, 0, 0)]],
		"body": [[0.0, V.call(-8, 0, 4)], [0.6, V.call(0, 0, 0)]]}, rest)
	# Charge: body lowered, claws forward, legs running.
	var charge := {"body@pos": [[0.0, V.call(0, 1.6, 0)], [0.1, V.call(0, 1.7, 0)], [0.2, V.call(0, 1.6, 0)]], "body": [[0.0, V.call(-8, 0, 0)]],
		"arm_r": [[0.0, V.call(-20, 0, -10)]], "arm_l": [[0.0, V.call(-20, 0, 10)]], "stalk": [[0.0, V.call(-30, 0, 0)]]}
	for i in legs.size():
		var l: String = legs[i]
		charge["leg" + l] = [[0.0, V.call(0, 25 if i % 2 == 0 else -25, 20)], [0.1, V.call(0, -25 if i % 2 == 0 else 25, 0)]]
	_anim(lib, "charge", 0.2, true, charge, rest)
	_anim(lib, "charge_windup", 0.6, false, {"body@pos": [[0.0, V.call(0, 1.9, 0)], [0.6, V.call(0, 1.5, 0.2)]], "body": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-10, 0, 0)]],
		"arm_r": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-20, 0, -10)]], "arm_l": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-20, 0, 10)]]}, rest)
	# Spit: rears back and blows a fan of bubbles.
	_anim(lib, "spit", 0.6, false, {"body": [[0.0, V.call(0, 0, 0)], [0.25, V.call(18, 0, 0)], [0.4, V.call(-10, 0, 0)], [0.6, V.call(0, 0, 0)]],
		"arm_r": [[0.0, V.call(0, 0, 0)], [0.25, V.call(30, 0, 30)], [0.6, V.call(0, 0, 0)]], "arm_l": [[0.0, V.call(0, 0, 0)], [0.25, V.call(30, 0, -30)], [0.6, V.call(0, 0, 0)]]}, rest)
	# Stunned with its eye struck: thrown onto its back, legs kicking.
	var flip := {"body@pos": [[0.0, V.call(0, 1.9, 0)], [0.3, V.call(0, 2.6, 0)], [0.6, V.call(0, 1.3, 0)]], "body": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 180)]],
		"stalk": [[0.0, V.call(0, 0, 0)], [0.6, V.call(60, 0, 0)]]}
	_anim(lib, "flip", 0.6, false, flip, rest)
	var kick := {"body@pos": [[0.0, V.call(0, 1.3, 0)]], "body": [[0.0, V.call(0, 0, 180)], [0.3, V.call(0, 8, 176)]], "stalk": [[0.0, V.call(60, 0, 10)], [0.3, V.call(60, 0, -10)]]}
	for i in legs.size():
		var l: String = legs[i]
		kick["leg" + l] = [[0.0, V.call(0, 0, 30 if i % 2 == 0 else -10)], [0.15, V.call(0, 0, -10 if i % 2 == 0 else 30)]]
	_anim(lib, "flipped", 0.3, true, kick, rest)
	_anim(lib, "unflip", 0.6, false, {"body@pos": [[0.0, V.call(0, 1.3, 0)], [0.3, V.call(0, 2.5, 0)], [0.6, V.call(0, 1.9, 0)]], "body": [[0.0, V.call(0, 0, 180)], [0.6, V.call(0, 0, 360)]]}, rest)
	_anim(lib, "hurt", 0.3, false, {"body@pos": [[0.0, V.call(0, 1.3, 0)]], "body": [[0.0, V.call(0, 0, 180)], [0.1, V.call(10, 0, 170)], [0.3, V.call(0, 0, 180)]]}, rest)
	_anim(lib, "roar", 1.4, false, {"body": [[0.0, V.call(0, 0, 0)], [0.4, V.call(15, 0, 0)], [1.1, V.call(15, 0, 0)], [1.4, V.call(0, 0, 0)]],
		"arm_r": [[0.0, V.call(0, 0, 0)], [0.4, V.call(70, 0, 40)], [1.1, V.call(70, 0, 40)], [1.4, V.call(0, 0, 0)]],
		"arm_l": [[0.0, V.call(0, 0, 0)], [0.4, V.call(70, 0, -40)], [1.1, V.call(70, 0, -40)], [1.4, V.call(0, 0, 0)]],
		"pincer_r": [[0.0, V.call(0, 0, 0)], [0.4, V.call(45, 0, 0)], [0.6, V.call(0, 0, 0)], [0.8, V.call(45, 0, 0)], [1.0, V.call(0, 0, 0)]],
		"pincer_l": [[0.0, V.call(0, 0, 0)], [0.4, V.call(45, 0, 0)], [0.6, V.call(0, 0, 0)], [0.8, V.call(45, 0, 0)], [1.0, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "death", 2.0, false, {"body@pos": [[0.0, V.call(0, 1.3, 0)], [2.0, V.call(0, 0.9, 0)]], "body": [[0.0, V.call(0, 0, 180)], [2.0, V.call(10, 0, 190)]],
		"stalk": [[0.0, V.call(60, 0, 0)], [2.0, V.call(100, 0, 20)]]}, rest)
	_finish_character(root, lib)
	_save_scene(root, "carapax.tscn")


## The boss's bubble: a pale translucent sphere with a glint.
func _build_bubble() -> void:
	var k := MeshKit.new(91)
	k.icosa(Vector3.ZERO, Vector3(0.45, 0.45, 0.45), 0.0, Color(0.6, 0.85, 1.0, 0.55), true)
	k.icosa(Vector3(-0.15, 0.18, -0.3), Vector3(0.08, 0.08, 0.04), 0.0, Color(1, 1, 1, 0.9))
	_save_res(k.build(_mats.water), "bubble_mesh.tres")
