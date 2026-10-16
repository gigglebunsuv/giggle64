extends RefCounted
## Builds the low-poly character models and their animations.
##
## Construction follows the N64 Zelda approach (see the adult hero model in
## Ocarina of Time): every limb is a smooth, low-sided tube on its own joint, the
## tubes overlap at the joints so no gaps open when they bend, shading is Gouraud
## (averaged vertex normals) and the face details are painted into a small
## texture instead of being modeled.
##
## Characters face -Z; their right side is +X. Each limb mesh is parented to a
## joint Node3D, which the AnimationPlayer rotates.
##
## Rotation conventions for the animation data (degrees, applied as XYZ euler):
## - Limbs hanging down (legs, arms): +X swings the limb forward.
## - Upright parts (torso, head): -X leans forward, +X leans back.
## - +Z rolls toward the character's left (raises the right arm outward).

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

## Collects one MeshKit per material while a limb is being built.
class Parts:
	const MK := preload("res://tools/mesh_kit.gd")
	var kits := {}
	var _seed := 0

	func _init(seed_value: int) -> void:
		_seed = seed_value

	## "char": smooth vertex-colored; "hard": vertex-colored with crisp edges
	## (weapons, armor); "face_*": textured head wraps; "glow": unshaded.
	func k(key := "char") -> MK:
		if not kits.has(key):
			var m := MK.new(_seed + kits.size() * 7)
			m.shade_jitter = 0.0 if key == "glow" else 0.03
			m.textured = key.begins_with("face")
			kits[key] = m
		return kits[key]


var _mats := {}
var _root: Node3D
var _paths := {}
var _seed := 100


func run(materials: Dictionary) -> void:
	_mats = materials
	_build_gigglebuns()
	_build_gear()
	_build_goblin()
	_build_mira()
	_build_armory_folk()
	_build_lothelye()
	_build_avalon()
	_build_armory_props()
	_build_townsfolk()
	_build_himeko()
	_build_hilde()
	_build_tansy()
	_build_ashwick()
	_build_horse()
	_build_props(materials)


# --- Helpers ------------------------------------------------------------------

func _c(h: String) -> Color:
	return Color.html(h)


## Creates a joint node under `parent` (registered by `key` for animation tracks)
## and attaches the meshes produced by `build` (a Callable taking a Parts).
func _joint(parent: Node3D, key: String, node_name: String, pos: Vector3, build: Callable = Callable()) -> Node3D:
	var j := Node3D.new()
	j.name = node_name
	j.position = pos
	parent.add_child(j)
	_paths[key] = str(_root.get_path_to(j))
	if build.is_valid():
		_build_meshes(j, node_name, build)
	return j


## Like _joint, for rigid props (sword, shield, club) that may be animated by key.
func _attach(parent: Node3D, node_name: String, pos: Vector3, build: Callable, key := "") -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.position = pos
	parent.add_child(n)
	if key != "":
		_paths[key] = str(_root.get_path_to(n))
	_build_meshes(n, node_name, build)
	return n


func _build_meshes(node: Node3D, node_name: String, build: Callable) -> void:
	_seed += 1
	var p := Parts.new(_seed * 13)
	build.call(p)
	var mesh := ArrayMesh.new()
	for key: String in p.kits:
		if key == "glow":
			continue
		var kit: MeshKit = p.kits[key]
		kit.smooth_normals(25.0 if key in ["hard", "chrome"] else 70.0)
		kit.add_to(mesh, _mats["char" if key == "hard" else key])
	if mesh.get_surface_count() > 0:
		_mesh_child(node, node_name + "Mesh", mesh)
	if p.kits.has("glow"):
		var mi := _mesh_child(node, node_name + "Glow", p.kits.glow.build(_mats.glow))
		mi.set_meta("no_tint", true)


func _mesh_child(parent: Node3D, node_name: String, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _set_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner(child, owner)


func _save_scene(root: Node, file: String) -> void:
	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, MODEL_DIR + file)
	if err != OK:
		push_error("Failed to save %s: %s" % [file, err])
	root.free()


## Rotation that turns a loft's +Y axis to point along `dir` (for feet, snouts, ears...).
func _aim(dir: Vector3, origin: Vector3) -> Transform3D:
	var y := dir.normalized()
	var x := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.BACK
	var z := x.cross(y).normalized()
	x = y.cross(z).normalized()
	return Transform3D(Basis(x, y, z), origin)


## Keys are eased into one another (Beta 1.6.0): every track of two or more
## keys is sampled SMOOTH_RATE times a second along a monotone cubic through
## its keys, per Euler component, the way OoT's skeletons store a pose for
## every frame. A monotone curve never overshoots a key, so held poses stay
## still and feet never dip through the floor; between keys the motion flows
## with no stop at each one (a key is a rest only where the curve turns back).
## Looping tracks wrap their slopes round the loop; a one-shot eases out of its
## first key and into its last. `smooth = false` keeps the old straight lines.
const SMOOTH_RATE := 30.0


## data: { joint_key: [[time, Vector3 euler_degrees], ...], "hips@pos": [[time, Vector3], ...] }
## Unlisted joints are keyed at their rest rotation so animations never leak poses.
func _anim(lib: AnimationLibrary, anim_name: String, length: float, loop: bool, data: Dictionary, rest_pos: Dictionary, smooth := true) -> void:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for key in _paths:
		if not data.has(key):
			data[key] = [[0.0, Vector3.ZERO]]
	for key in rest_pos:
		if not data.has(key + "@pos"):
			data[key + "@pos"] = [[0.0, rest_pos[key]]]
	for key: String in data:
		var is_pos := key.ends_with("@pos")
		var is_scale := key.ends_with("@scale")
		var joint := key.trim_suffix("@pos").trim_suffix("@scale")
		if not _paths.has(joint):
			push_error("Unknown joint '%s' in animation %s" % [joint, anim_name])
			continue
		var keys: Array = data[key].duplicate()
		if loop and keys.size() > 1 and keys.back()[0] < length:
			keys.append([length, keys[0][1]])
		var kind := Animation.TYPE_POSITION_3D if is_pos else (Animation.TYPE_SCALE_3D if is_scale else Animation.TYPE_ROTATION_3D)
		var idx := a.add_track(kind)
		a.track_set_path(idx, NodePath(_paths[joint]))
		a.track_set_interpolation_type(idx, Animation.INTERPOLATION_LINEAR)
		if smooth and keys.size() > 1:
			# Eased per Euler component, a jump past 180 degrees turns the long
			# way round (a straight slerp took the short way): flag it.
			if kind == Animation.TYPE_ROTATION_3D and OS.get_environment("G64_ANIM_CHECK") != "":
				for i in range(1, keys.size()):
					var dv: Vector3 = keys[i][1] - keys[i - 1][1]
					if maxf(absf(dv.x), maxf(absf(dv.y), absf(dv.z))) > 180.0:
						print("ANIM_CHECK %s %s %.2f: %s -> %s" % [anim_name, key, keys[i][0], keys[i - 1][1], keys[i][1]])
			keys = _smooth_keys(keys, loop, length)
		for k in keys:
			if is_pos:
				a.position_track_insert_key(idx, k[0], k[1])
			elif is_scale:
				a.scale_track_insert_key(idx, k[0], k[1])
			else:
				var e: Vector3 = k[1]
				a.rotation_track_insert_key(idx, k[0], Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z))))
	lib.add_animation(anim_name, a)


## Resamples [[time, Vector3], ...] along a monotone cubic Hermite curve
## (Fritsch-Butland slopes, per component). Every original key is kept.
func _smooth_keys(keys: Array, loop: bool, length: float) -> Array:
	keys.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var n := keys.size()
	var ts: Array[float] = []
	var vs: Array[Vector3] = []
	for k in keys:
		ts.append(float(k[0]))
		vs.append(k[1])
	# A loop whose last key closes on the first: its ends share one slope.
	var closed: bool = loop and n > 2 and is_equal_approx(ts[n - 1], length) and vs[n - 1].is_equal_approx(vs[0])
	var slopes: Array[Vector3] = []
	for i in n:
		var m := Vector3.ZERO
		var has_prev := i > 0
		var has_next := i < n - 1
		var t0 := 0.0
		var v0 := Vector3.ZERO
		var t2 := 0.0
		var v2 := Vector3.ZERO
		if has_prev:
			t0 = ts[i - 1]
			v0 = vs[i - 1]
		elif closed:
			has_prev = true
			t0 = ts[n - 2] - length
			v0 = vs[n - 2]
		if has_next:
			t2 = ts[i + 1]
			v2 = vs[i + 1]
		elif closed:
			has_next = true
			t2 = ts[1] + length
			v2 = vs[1]
		if has_prev and has_next:
			var h0 := maxf(ts[i] - t0, 1e-4)
			var h1 := maxf(t2 - ts[i], 1e-4)
			for c in 3:
				var d0 := (vs[i][c] - v0[c]) / h0
				var d1 := (v2[c] - vs[i][c]) / h1
				if d0 * d1 > 0.0:
					m[c] = 3.0 * (h0 + h1) / ((2.0 * h1 + h0) / d0 + (h1 + 2.0 * h0) / d1)
		slopes.append(m)
	var out: Array = []
	var step := 1.0 / SMOOTH_RATE
	for i in n - 1:
		var ta := ts[i]
		var tb := ts[i + 1]
		var h := tb - ta
		out.append([ta, vs[i]])
		if h <= step * 1.01:
			continue
		var count := int(ceil(h / step))
		for j in range(1, count):
			var s := float(j) / count
			var s2 := s * s
			var s3 := s2 * s
			var v := vs[i] * (2.0 * s3 - 3.0 * s2 + 1.0) + slopes[i] * h * (s3 - 2.0 * s2 + s) \
				+ vs[i + 1] * (-2.0 * s3 + 3.0 * s2) + slopes[i + 1] * h * (s3 - s2)
			out.append([ta + s * h, v])
	out.append([ts[n - 1], vs[n - 1]])
	return out


func _finish_character(root: Node3D, lib: AnimationLibrary) -> void:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	ap.add_animation_library("", lib)
	ap.autoplay = "idle"
	root.set_script(load("res://scripts/systems/character_model.gd"))


# --- Sir Gigglebuns IV --------------------------------------------------------
#
# Proportions follow the adult hero of Ocarina of Time scaled to 1.85 m:
# hip joints at 48% of the height, knees at 27%, ankles at 8%, shoulders at 73%
# (half-width 11%), neck at 78%. Upper arm 0.27 m, forearm 0.23 m, big fists and
# boots, broad chest tapering to the belt, and a flared tunic hem.

func _build_gigglebuns() -> void:
	var SKIN := _c("e3b08a")
	var SKIN_D := _c("c9946e")
	var TUNIC := _c("8c1d17")
	var TUNIC_L := _c("a3261d")
	var TUNIC_D := _c("6a140f")
	var PANTS := _c("9b9ea3")
	var PANTS_D := _c("80838a")
	var BOOT := _c("2b2b31")
	var BOOT_L := _c("3a3a42")
	var BOOT_D := _c("19191d")
	var GLOVE := _c("6e4630")
	var GLOVE_D := _c("573522")
	var BELT := _c("5a3820")
	var BRASS := _c("c9a64e")
	var STRAP := _c("6b4529")
	var BAG := _c("2b2b30")
	var WHITE := Color.WHITE

	_root = Node3D.new()
	_root.name = "SirGigglebunsModel"
	_paths = {}
	var root := _root

	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.92, 0), func(p: Parts) -> void:
		var k := p.k()
		# Seat of the trousers (mostly hidden by the tunic hem).
		k.loft([[-0.14, 0.11, 0.09, PANTS], [-0.06, 0.15, 0.11, PANTS], [0.06, 0.155, 0.11, PANTS]], 8)
		# Tunic hem flaring over the hips, darker at the bottom edge.
		k.loft([
			[-0.16, 0.20, 0.155, TUNIC_D, Vector2(0, 0.005)], [-0.10, 0.195, 0.15, TUNIC],
			[0.0, 0.175, 0.13, TUNIC], [0.07, 0.165, 0.12, TUNIC],
		], 10)
		# Belt and brass buckle.
		k.loft([[0.06, 0.172, 0.127, BELT], [0.115, 0.17, 0.125, BELT]], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.088, -0.13), Vector3(0.07, 0.055, 0.02), BRASS)
		h.box(Vector3(0, 0.088, -0.142), Vector3(0.03, 0.022, 0.008), BELT)
		# Black satchel on the back-left hip.
		k.push(Transform3D(Basis(Vector3.UP, deg_to_rad(-35)), Vector3(-0.15, -0.04, 0.12)))
		k.loft([[-0.09, 0.07, 0.035, BAG], [0.02, 0.085, 0.045, BAG], [0.07, 0.08, 0.04, _c("3a3a40")], [0.08, 0.07, 0.035, BAG]], 6)
		k.pop()
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.08, 0), func(p: Parts) -> void:
		var k := p.k()
		# V-shaped chest: narrow waist, broad upper chest, sloping shoulders.
		k.loft([
			[0.0, 0.15, 0.11, TUNIC_D], [0.10, 0.165, 0.118, TUNIC, Vector2(0, -0.004)],
			[0.20, 0.19, 0.128, TUNIC_L, Vector2(0, -0.012)], [0.28, 0.205, 0.126, TUNIC, Vector2(0, -0.01)],
			[0.34, 0.17, 0.112, TUNIC], [0.39, 0.095, 0.08, TUNIC_D], [0.41, 0.07, 0.065, TUNIC_D],
		], 10)
		# V-neck opening showing the throat.
		k.tri_vc([Vector3(-0.055, 0.375, -0.098), Vector3(0.055, 0.375, -0.098), Vector3(0, 0.28, -0.142)],
			[SKIN, SKIN, SKIN_D], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.3, 0))
		# Shoulder strap running from the right shoulder to the left hip, front and back.
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-36)), Vector3(0.0, 0.2, -0.128)))
		h.box(Vector3.ZERO, Vector3(0.045, 0.5, 0.015), STRAP)
		h.pop()
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(36)), Vector3(0.0, 0.2, 0.125)))
		h.box(Vector3.ZERO, Vector3(0.045, 0.5, 0.015), STRAP)
		h.pop()
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-20)), Vector3(0.13, 0.355, 0.0)))
		h.box(Vector3.ZERO, Vector3(0.05, 0.02, 0.27), STRAP)
		h.pop()
	)
	_joint(torso, "head", "Head", Vector3(0, 0.45, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.09, 0.06, 0.058, SKIN_D], [0.0, 0.062, 0.06, SKIN_D], [0.05, 0.065, 0.065, SKIN]], 6, false)
		# Head wrap: rings every 5 cm from under the beard to the crown, so the
		# painted face texture lands on the right features (see gen_media.gd).
		var f := p.k("face_gigglebuns")
		f.loft([
			[-0.03, 0.065, 0.06, WHITE, Vector2(0, -0.075)],
			[0.02, 0.105, 0.095, WHITE, Vector2(0, -0.05)],
			[0.07, 0.125, 0.115, WHITE, Vector2(0, -0.03)],
			[0.12, 0.13, 0.125, WHITE, Vector2(0, -0.016)],
			[0.17, 0.132, 0.13, WHITE, Vector2(0, -0.006)],
			[0.22, 0.132, 0.135, WHITE, Vector2(0, 0.0)],
			[0.27, 0.125, 0.135, WHITE, Vector2(0, 0.006)],
			[0.32, 0.1, 0.112, WHITE, Vector2(0, 0.012)],
			[0.37, 0.0, 0.0, WHITE, Vector2(0, 0.016)],
		], 10)
		# Nose and ears.
		k.tri_vc([Vector3(-0.024, 0.15, -0.135), Vector3(0.024, 0.15, -0.135), Vector3(0, 0.155, -0.172)], [SKIN_D, SKIN_D, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.18, -0.1))
		k.tri_vc([Vector3(-0.024, 0.15, -0.135), Vector3(0, 0.155, -0.172), Vector3(0, 0.215, -0.14)], [SKIN_D, SKIN, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.18, -0.1))
		k.tri_vc([Vector3(0.024, 0.15, -0.135), Vector3(0, 0.215, -0.14), Vector3(0, 0.155, -0.172)], [SKIN_D, SKIN, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.18, -0.1))
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx, 0.15, 0.25), Vector3(0.115 * sx, 0.19, 0.02)))
			k.loft([[0.0, 0.025, 0.045, SKIN_D], [0.035, 0.022, 0.04, SKIN], [0.05, 0.0, 0.0, SKIN]], 5)
			k.pop()
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.2 * side, 0.33, 0), func(p: Parts) -> void:
			# Short red sleeve over a rounded shoulder, then the bare upper arm.
			p.k().loft([
				[0.075, 0.0, 0.0, TUNIC], [0.055, 0.065, 0.068, TUNIC], [0.0, 0.088, 0.084, TUNIC_L],
				[-0.1, 0.076, 0.074, TUNIC_D], [-0.104, 0.056, 0.056, SKIN], [-0.2, 0.052, 0.05, SKIN],
				[-0.27, 0.046, 0.046, SKIN_D], [-0.3, 0.0, 0.0, SKIN_D],
			], 7)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.27, 0), func(p: Parts) -> void:
			# Forearm with a fingerless leather glove cuff.
			p.k().loft([
				[0.035, 0.0, 0.0, SKIN_D], [0.01, 0.045, 0.045, SKIN], [-0.07, 0.05, 0.052, SKIN],
				[-0.1, 0.06, 0.062, GLOVE], [-0.2, 0.052, 0.054, GLOVE_D], [-0.235, 0.0, 0.0, GLOVE_D],
			], 7)
		)
		_joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.23, 0), func(p: Parts) -> void:
			# Big closed fist and thumb, N64-style.
			var k := p.k()
			k.loft([
				[0.015, 0.035, 0.035, GLOVE], [-0.02, 0.048, 0.058, GLOVE], [-0.075, 0.044, 0.058, SKIN],
				[-0.105, 0.03, 0.04, SKIN_D], [-0.115, 0.0, 0.0, SKIN_D],
			], 6)
			k.push(_aim(Vector3(0, -0.6, -1), Vector3(-0.02 * side, -0.035, -0.04)))
			k.loft([[0.0, 0.02, 0.02, GLOVE], [0.04, 0.017, 0.017, SKIN], [0.055, 0.0, 0.0, SKIN]], 5)
			k.pop()
		)
		if side > 0:
			_attach(_root.get_node(_paths["hand_r"]), "Sword", Vector3(0, -0.06, 0), func(p: Parts) -> void:
				_sword_parts(p, "squire")
			, "sword")
			# Scabbard across the back on the shoulder strap, hilt over the right
			# shoulder; the sheathed hilt shows only while the sword is put away.
			var back := _attach(torso, "SwordBack", Vector3(0.07, 0.16, 0.17), func(p: Parts) -> void:
				_scabbard_parts(p, "squire")
			)
			back.basis = Basis(Vector3.BACK, deg_to_rad(-29))
			_attach(back, "SheathedSword", Vector3(0, 0.26, 0), func(p: Parts) -> void:
				_sheathed_parts(p, "squire")
			)
		else:
			_attach(elbow, "Shield", Vector3(-0.065, -0.13, 0), func(p: Parts) -> void:
				_shield_parts(p, "wooden", SHIELD_ARM)
			, "shield")
			# The bow in the left fist (shown while it is out). Its limbs arc in the
			# hand's Y-Z plane, so with the arm held out the bow stands upright and
			# the tips bend back toward the archer (+Y) with the string between them.
			_attach(_root.get_node(_paths["hand_l"]), "Bow", Vector3(0, -0.07, 0), _bow_parts)
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.09 * side, -0.03, 0), func(p: Parts) -> void:
			p.k().loft([
				[0.06, 0.0, 0.0, PANTS], [0.04, 0.075, 0.08, PANTS], [-0.05, 0.088, 0.094, PANTS],
				[-0.2, 0.074, 0.08, PANTS], [-0.34, 0.058, 0.064, PANTS_D], [-0.4, 0.0, 0.0, PANTS_D],
			], 8)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.38, 0), func(p: Parts) -> void:
			# Shin disappearing into a tall boot with a turned-down cuff.
			p.k().loft([
				[0.04, 0.0, 0.0, PANTS_D], [0.02, 0.052, 0.056, PANTS], [-0.06, 0.058, 0.064, PANTS_D],
				[-0.1, 0.074, 0.08, BOOT_L], [-0.145, 0.074, 0.08, BOOT_D], [-0.15, 0.064, 0.07, BOOT],
				[-0.28, 0.058, 0.064, BOOT], [-0.37, 0.052, 0.058, BOOT_D], [-0.39, 0.0, 0.0, BOOT_D],
			], 8)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.37, 0), func(p: Parts) -> void:
			# Boot foot, lofted forward from the heel: ring Z is world height here.
			var k := p.k()
			k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			k.loft([
				[-0.075, 0.048, 0.06, BOOT_D, Vector2(0, -0.08)], [-0.05, 0.06, 0.075, BOOT, Vector2(0, -0.065)],
				[0.04, 0.062, 0.07, BOOT, Vector2(0, -0.07)], [0.12, 0.055, 0.048, BOOT_L, Vector2(0, -0.092)],
				[0.175, 0.034, 0.03, BOOT, Vector2(0, -0.11)],
			], 7)
			k.pop()
		)

	# The shield slung on the back while the bow is out (hidden otherwise).
	_attach(torso, "ShieldBack", Vector3(-0.02, 0.2, 0.2), func(p: Parts) -> void:
		_shield_parts(p, "wooden", SHIELD_BACK)
	)

	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.92, 0)}
	_gigglebuns_anims(lib, rest)
	_finish_character(root, lib)
	_save_scene(root, "sir_gigglebuns.tscn")


# --- Swords and shields ----------------------------------------------------------
#
# Each sword and shield is built by one function in the frame of the node that
# holds it on the hero (Sword in the right fist, SheathedSword and SwordBack on
# the back, Shield on the left forearm, ShieldBack on the back). The hero's
# model is generated with the Squire's Sword and Wooden Shield; _build_gear
# saves every piece as its own mesh so CharacterModel.set_gear can swap them.

## Shield frames: built along +Y (thickness), turned so the face points out
## along -X of the forearm, or out of the back.
var SHIELD_ARM := Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO)
var SHIELD_BACK := Transform3D(Basis(Vector3.BACK, deg_to_rad(12)) * Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO)

## Per sword: blade length past the guard, width scale, blade colors (base,
## tip), hilt colors (guard, grip, pommel), scabbard colors (leather, fittings),
## whether the blade is polished (the chrome material), and the guard shape.
var SWORD_SPECS := {
	"squire": {"len": 0.86, "w": 1.0, "blade": ["b9c1ca", "e6edf4"], "hilt": ["c9a64e", "5a3a22", "c9a64e"],
		"sheath": ["4a2f1c", "c9a64e"], "chrome": false, "guard": "up"},
	"red": {"len": 0.98, "w": 1.05, "blade": ["4c4e56", "70737c"], "hilt": ["1e1d22", "b0202c", "1e1d22"],
		"sheath": ["1e1d22", "b0202c"], "chrome": false, "guard": "flat", "gem": "e8303a"},
	"magical": {"len": 1.12, "w": 1.3, "blade": ["eef4ff", "ffffff"], "hilt": ["2a50d8", "1a2c88", "c8d4e8"],
		"sheath": ["1a2c88", "c8d4e8"], "chrome": true, "guard": "up", "gem": "8ad0ff"},
	"bun": {"len": 1.16, "w": 1.35, "blade": ["f0c040", "ffe890"], "hilt": ["2e7040", "1c4a26", "e8b830"],
		"sheath": ["143a1c", "e8b830"], "chrome": true, "guard": "down", "gem": "ffe070"},
	# The Bun Sword once it wakes in the Temple of Bun: the blade turns pink.
	"bun_awake": {"len": 1.16, "w": 1.35, "blade": ["f06ab4", "ffc6e6"], "hilt": ["2e7040", "1c4a26", "f0a8d0"],
		"sheath": ["143a1c", "f0a8d0"], "chrome": true, "guard": "down", "gem": "ff8ad2"},
	# Aladriel's giant sword (Beta 1.4.0), the hero's two-handed blade: as long
	# as he is tall nearly, broad, a gold guard and a grip long enough for two fists.
	"great": {"len": 1.5, "w": 1.9, "blade": ["c4ccd6", "eef2f6"], "hilt": ["c8a85a", "6a4428", "c8a85a"],
		"sheath": ["3a2818", "c8a85a"], "chrome": true, "guard": "flat", "gem": "4aa8e0", "grip": 2.5},
}


## The sword in the fist: built along +Y, then rotated so the blade points
## down the hand's -Z axis. The blade is thin across the hand's X, so its flat
## faces stand vertical with the edges up and down, the way OoT's hero holds his sword.
func _sword_parts(p: Parts, id: String) -> void:
	var s: Dictionary = SWORD_SPECS[id]
	var b := p.k("chrome" if s.chrome else "hard")
	var w: float = s.w
	var tip: float = s.len
	var body := tip - 0.2 * (1.0 + (w - 1.0) * 0.5)
	b.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(0.26, 1, 1)), Vector3.ZERO))
	b.prism(Vector3(0, 0.08, 0), 0.05 * w, Vector3(0, body, 0), 0.06 * w, 4, _c(s.blade[0]))
	b.prism(Vector3(0, body, 0), 0.06 * w, Vector3(0, tip, 0), 0.0, 4, _c(s.blade[1]))
	b.pop()
	_hilt(p.k("hard"), Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), id)


## The hilt showing over the shoulder while the sword is put away: upside down
## (blade into the scabbard) and turned so the guard lies flat across the back.
func _sheathed_parts(p: Parts, id: String) -> void:
	_hilt(p.k("hard"), Transform3D(Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, PI), Vector3.ZERO), id)


## The scabbard across the back, longer for longer blades.
func _scabbard_parts(p: Parts, id: String) -> void:
	var s: Dictionary = SWORD_SPECS[id]
	var h := p.k("hard")
	var leather := _c(s.sheath[0])
	var fit := _c(s.sheath[1])
	var bottom: float = -0.45 - (s.len - 0.86)
	var wide: float = 1.0 + (s.w - 1.0) * 0.6
	h.push(Transform3D(Basis.from_scale(Vector3(wide, 1, 0.3)), Vector3.ZERO))
	h.prism(Vector3(0, bottom, 0), 0.05, Vector3(0, 0.15, 0), 0.075, 4, leather, 0.0, fit)
	h.pop()
	h.prism(Vector3(0, bottom - 0.02, 0), 0.0, Vector3(0, bottom + 0.02, 0), 0.025 * wide, 4, fit)
	h.box(Vector3(0, 0.16, 0), Vector3(0.16 * wide, 0.03, 0.05), fit)
	h.box(Vector3(0, -0.15, 0), Vector3(0.15 * wide, 0.025, 0.045), fit)


## Guard, grip and pommel, built along +Y from the guard (the blade would
## continue up +Y). The crossguard spans the blade's width; its ends curl
## toward the blade ("up"), stay straight ("flat") or point down toward the
## hand ("down", the Bun Sword).
func _hilt(h: MeshKit, t: Transform3D, id: String) -> void:
	var s: Dictionary = SWORD_SPECS[id]
	var guard := _c(s.hilt[0])
	var grip := _c(s.hilt[1])
	var pommel := _c(s.hilt[2])
	var span: float = 0.22 * (1.0 + (s.w - 1.0) * 0.6)
	# A two-handed sword's grip runs on further (`grip` times the usual).
	var low: float = 0.05 - 0.12 * float(s.get("grip", 1.0))
	h.push(t)
	h.prism(Vector3(0, 0.05, 0), 0.025, Vector3(0, 0.09, 0), 0.03, 6, guard)
	h.prism(Vector3(0, low, 0), 0.02, Vector3(0, 0.05, 0), 0.022, 5, grip)
	# Grip wrapping: a few darker bands.
	var gy := low + 0.03
	while gy < 0.03:
		h.prism(Vector3(0, gy, 0), 0.0235, Vector3(0, gy + 0.012, 0), 0.0235, 5, grip.darkened(0.3))
		gy += 0.03
	h.prism(Vector3(0, low - 0.04, 0), 0.03, Vector3(0, low, 0), 0.022, 6, pommel)
	h.box(Vector3(0, 0.075, 0), Vector3(0.035, 0.04, span), guard)
	match s.guard:
		"up":
			for sz in [-1.0, 1.0]:
				h.prism(Vector3(0, 0.075, span * 0.5 * sz), 0.022, Vector3(0, 0.13, (span * 0.5 + 0.01) * sz), 0.012, 4, guard)
		"down":
			# Quillons sweeping down past the grip toward the hand.
			for sz in [-1.0, 1.0]:
				h.prism(Vector3(0, 0.075, span * 0.5 * sz), 0.024, Vector3(0, 0.02, (span * 0.5 + 0.03) * sz), 0.018, 4, guard)
				h.prism(Vector3(0, 0.02, (span * 0.5 + 0.03) * sz), 0.018, Vector3(0, -0.04, (span * 0.5 + 0.02) * sz), 0.0, 4, pommel)
		"flat":
			for sz in [-1.0, 1.0]:
				h.box(Vector3(0, 0.075, span * 0.5 * sz), Vector3(0.045, 0.05, 0.03), guard)
	if s.has("gem"):
		for sx in [-1.0, 1.0]:
			h.prism(Vector3(0.018 * sx, 0.075, 0), 0.016, Vector3(0.026 * sx, 0.075, 0), 0.008, 6, _c(s.gem))
		h.prism(Vector3(0, low - 0.055, 0), 0.016, Vector3(0, low - 0.04, 0), 0.02, 6, _c(s.gem))
	h.pop()


## A shield in the frame `t` (see SHIELD_ARM / SHIELD_BACK).
func _shield_parts(p: Parts, id: String, t: Transform3D) -> void:
	var h := p.k("hard")
	h.push(t)
	match id:
		"wooden":
			# Octagonal wooden shield with an iron rim, a red band and a steel boss.
			h.prism(Vector3(0, 0.0, 0), 0.3, Vector3(0, 0.035, 0), 0.3, 8, _c("4b4b53"), PI / 8.0)
			h.prism(Vector3(0, 0.035, 0), 0.268, Vector3(0, 0.052, 0), 0.262, 8, _c("7c5331"), PI / 8.0)
			h.box(Vector3(0, 0.056, 0), Vector3(0.46, 0.01, 0.06), _c("5e3d22"))
			h.box(Vector3(0, 0.058, 0), Vector3(0.06, 0.012, 0.46), _c("8c1d17"))
			h.prism(Vector3(0, 0.052, 0), 0.08, Vector3(0, 0.1, 0), 0.04, 8, _c("a6a6b0"), PI / 8.0)
		"iron":
			# Round iron shield: dark rim, a raised cross, rivets and a big boss.
			var face := _c("8c9098")
			var dark := _c("3a3c44")
			h.prism(Vector3(0, 0.0, 0), 0.32, Vector3(0, 0.04, 0), 0.32, 12, dark)
			h.prism(Vector3(0, 0.04, 0), 0.29, Vector3(0, 0.06, 0), 0.27, 12, face)
			h.box(Vector3(0, 0.065, 0), Vector3(0.5, 0.012, 0.07), dark.lightened(0.15))
			h.box(Vector3(0, 0.066, 0), Vector3(0.07, 0.012, 0.5), dark.lightened(0.15))
			for i in 12:
				var a := TAU * (i + 0.5) / 12.0
				h.prism(Vector3(cos(a) * 0.25, 0.055, sin(a) * 0.25), 0.014, Vector3(cos(a) * 0.25, 0.075, sin(a) * 0.25), 0.006, 5, _c("d0d4dc"))
			h.prism(Vector3(0, 0.06, 0), 0.09, Vector3(0, 0.11, 0), 0.05, 10, _c("b8bcc4"))
			h.prism(Vector3(0, 0.11, 0), 0.05, Vector3(0, 0.125, 0), 0.0, 10, _c("dadee6"))
		"mirror":
			# Tall polished shield: red and gold rim, mirror face, and a red sun
			# with gold rays in the middle.
			var c := p.k("chrome")
			c.push(t)
			c.push(Transform3D(Basis.from_scale(Vector3(0.85, 1, 1.15)), Vector3.ZERO))
			c.prism(Vector3(0, 0.035, 0), 0.3, Vector3(0, 0.055, 0), 0.29, 12, _c("e8eef8"))
			c.pop()
			c.pop()
			h.push(Transform3D(Basis.from_scale(Vector3(0.85, 1, 1.15)), Vector3.ZERO))
			h.prism(Vector3(0, 0.0, 0), 0.34, Vector3(0, 0.035, 0), 0.34, 12, _c("b02028"))
			h.prism(Vector3(0, 0.035, 0), 0.34, Vector3(0, 0.05, 0), 0.31, 12, _c("d8b040"))
			h.pop()
			for i in 8:
				var a := TAU * i / 8.0
				var d := Vector3(cos(a), 0, sin(a))
				h.push(_aim(d, Vector3(0, 0.06, 0)))
				h.prism(Vector3(0, 0.05, 0), 0.02, Vector3(0, 0.15, 0), 0.0, 3, _c("e8c050"))
				h.pop()
			h.prism(Vector3(0, 0.055, 0), 0.065, Vector3(0, 0.08, 0), 0.05, 10, _c("c82830"))
			h.prism(Vector3(0, 0.08, 0), 0.05, Vector3(0, 0.09, 0), 0.0, 10, _c("e84850"))
		"questlord":
			# Aladriel's old starmetal shield, forged anew: a tall heater of
			# midnight-blue starmetal flecked with stars, a gold rim, and the
			# Questlords' sign: a great sword crossed by two scimitars.
			var star := _c("2a3a6a")
			var rim := _c("d8b040")
			h.push(Transform3D(Basis.from_scale(Vector3(0.9, 1, 1.2)), Vector3.ZERO))
			h.prism(Vector3(0, 0.0, 0), 0.33, Vector3(0, 0.035, 0), 0.33, 6, rim, PI / 6.0)
			h.prism(Vector3(0, 0.035, 0), 0.3, Vector3(0, 0.055, 0), 0.29, 6, star, PI / 6.0)
			h.pop()
			# A point at the bottom, like a heater shield.
			h.prism(Vector3(0, 0.0, 0.34), 0.12, Vector3(0, 0.035, 0.34), 0.08, 3, rim, PI / 2.0)
			for i in 9:
				var a := TAU * i / 9.0 + 0.3
				var r := 0.08 + (i % 3) * 0.06
				h.box(Vector3(cos(a) * r, 0.058, sin(a) * r * 1.3), Vector3(0.012, 0.006, 0.012), _c("e8eeff"))
			# The great sword down the middle, the scimitars crossed over it.
			h.box(Vector3(0, 0.062, 0.02), Vector3(0.035, 0.008, 0.44), _c("c8ccd8"))
			h.box(Vector3(0, 0.064, -0.13), Vector3(0.14, 0.01, 0.03), rim)
			for sx in [-1.0, 1.0]:
				h.push(Transform3D(Basis(Vector3.UP, sx * 0.6), Vector3(0, 0.066, 0.02)))
				h.box(Vector3(0, 0, 0), Vector3(0.024, 0.006, 0.36), _c("e8eaf0"))
				h.box(Vector3(0, 0.002, -0.17), Vector3(0.06, 0.008, 0.02), rim)
				h.pop()
	h.pop()


## The bow, held in the left fist (see the hero's Bow node).
func _bow_parts(p: Parts) -> void:
	var WOOD := _c("7c5331")
	var WOOD_D := _c("5e3d22")
	var GRIP := _c("5a3a22")
	var h := p.k("hard")
	var pts: Array[Vector3] = []
	for i in 9:
		var t := -1.0 + i * 0.25
		pts.append(Vector3(0, 0.13 * t * t, t * 0.56))
	for i in 8:
		var a := pts[i]
		var b := pts[i + 1]
		var r0 := lerpf(0.024, 0.011, absf(-1.0 + i * 0.25))
		var r1 := lerpf(0.024, 0.011, absf(-1.0 + (i + 1) * 0.25))
		h.push(_aim(b - a, a))
		h.prism(Vector3.ZERO, r0, Vector3(0, (b - a).length(), 0), r1, 5, WOOD if i % 7 != 0 else WOOD_D)
		h.pop()
	h.box(Vector3(0, 0.0, 0), Vector3(0.05, 0.05, 0.11), GRIP)
	var s := pts[8] - pts[0]
	h.push(_aim(s, pts[0]))
	h.prism(Vector3.ZERO, 0.004, Vector3(0, s.length(), 0), 0.004, 3, _c("e8e4d8"))
	h.pop()


## One standalone mesh from a Parts build (glow parts left out).
func _parts_mesh(build: Callable) -> ArrayMesh:
	_seed += 1
	var p := Parts.new(_seed * 13)
	build.call(p)
	var mesh := ArrayMesh.new()
	for key: String in p.kits:
		if key == "glow":
			continue
		var kit: MeshKit = p.kits[key]
		kit.smooth_normals(25.0 if key in ["hard", "chrome"] else 70.0)
		kit.add_to(mesh, _mats["char" if key == "hard" else key])
	return mesh


## Every sword and shield as its own mesh, for Equipment and the icons.
func _build_gear() -> void:
	for id: String in SWORD_SPECS:
		_save_res(_parts_mesh(func(p: Parts) -> void: _sword_parts(p, id)), "sword_%s_mesh.tres" % id)
		_save_res(_parts_mesh(func(p: Parts) -> void: _sheathed_parts(p, id)), "sword_%s_hilt_mesh.tres" % id)
		_save_res(_parts_mesh(func(p: Parts) -> void: _scabbard_parts(p, id)), "scabbard_%s_mesh.tres" % id)
	for id: String in ["wooden", "iron", "mirror", "questlord"]:
		_save_res(_parts_mesh(func(p: Parts) -> void: _shield_parts(p, id, SHIELD_ARM)), "shield_%s_mesh.tres" % id)
		_save_res(_parts_mesh(func(p: Parts) -> void: _shield_parts(p, id, SHIELD_BACK)), "shield_%s_back_mesh.tres" % id)
		# Face-up (+Y) for icons and the shop wall.
		_save_res(_parts_mesh(func(p: Parts) -> void: _shield_parts(p, id, Transform3D.IDENTITY)), "shield_%s_flat_mesh.tres" % id)
	# The bow on its own (icons), built as in the hero's left fist.
	_save_res(_parts_mesh(_bow_parts), "bow_mesh.tres")


func _gigglebuns_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# Shared "ready stance" values: sword low at the right side, shield arm bent.
	var arm_r := Vector3(10, 0, 8)
	var elbow_r := Vector3(35, 0, 0)
	var hand_r := Vector3(-20, 0, 0)
	var arm_l := Vector3(5, 0, -10)
	var elbow_l := Vector3(20, 0, 0)

	_anim(lib, "RESET", 0.1, false, {}, rest)

	# Standing: breathing, and the weight drifting slowly from foot to foot
	# (OoT's link_normal_wait sways the same way), the arms easing with it.
	_anim(lib, "idle", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.92, 0)], [0.6, V.call(0.012, 0.912, 0)], [1.2, V.call(0, 0.906, 0)], [1.8, V.call(-0.012, 0.912, 0)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 2, 1.6)], [1.2, V.call(0, 0, 0)], [1.8, V.call(0, -2, -1.6)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.6, V.call(-2, -1.5, -1.6)], [1.2, V.call(-3, 0, 0)], [1.8, V.call(-2, 1.5, 1.6)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.6, V.call(2, 3, 0)], [1.2, V.call(3, 0, 0)], [1.8, V.call(2, -4, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.6, arm_r + V.call(2, 0, 1)], [1.2, arm_r + V.call(4, 0, 2)], [1.8, arm_r + V.call(2, 0, 1)]],
		"elbow_r": [[0.0, elbow_r], [1.2, elbow_r + V.call(7, 0, 0)]],
		"hand_r": [[0.0, hand_r], [1.2, hand_r + V.call(-4, 0, 0)]],
		"shoulder_l": [[0.0, arm_l], [0.6, arm_l + V.call(2, 0, -1)], [1.2, arm_l + V.call(4, 0, -2)], [1.8, arm_l + V.call(2, 0, -1)]],
		"elbow_l": [[0.0, elbow_l], [1.2, elbow_l + V.call(5, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.6, V.call(-1, 0, 1.5)], [1.2, V.call(0, 0, 3)], [1.8, V.call(1, 0, 4.5)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.6, V.call(1, 0, -4.5)], [1.2, V.call(0, 0, -3)], [1.8, V.call(-1, 0, -1.5)]],
		"knee_r": [[0.0, V.call(-2, 0, 0)], [0.6, V.call(-1, 0, 0)], [1.2, V.call(-5, 0, 0)], [1.8, V.call(-7, 0, 0)]],
		"knee_l": [[0.0, V.call(-2, 0, 0)], [0.6, V.call(-7, 0, 0)], [1.2, V.call(-5, 0, 0)], [1.8, V.call(-1, 0, 0)]],
		"foot_r": [[0.0, V.call(0, 0, -3)], [0.6, V.call(1, 0, -1.5)], [1.2, V.call(3, 0, -3)], [1.8, V.call(4, 0, -4.5)]],
		"foot_l": [[0.0, V.call(0, 0, 3)], [0.6, V.call(4, 0, 4.5)], [1.2, V.call(3, 0, 3)], [1.8, V.call(1, 0, 1.5)]],
	}, rest)

	# Walk and run cycles. Each is one full stride (two steps); the controller sets
	# the playback rate from ground speed, the way OoT advances its 29-frame walk
	# cycle by a speed-dependent amount each frame. The right foot strikes at the
	# start and the left halfway (the footstep sounds key off those two points).
	# Eight poses a stride: strike, load, mid-stance, push-off, then the swing
	# with the knee folding up and reaching through. The run leans into it,
	# pumps the arms with the elbows bent, and leaves the ground between steps
	# (the hips ride highest in the flight); the walk rolls over a straight leg
	# (highest at mid-stance).
	var gait := func(n: String, L: float, run: bool, sword := false) -> void:
		var ph := [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]
		var hip: Array = [30, 18, -2, -28, -36, -6, 42, 40] if run else [22, 14, 2, -12, -20, -8, 12, 22]
		var knee: Array = [-14, -38, -26, -18, -42, -108, -84, -32] if run else [-4, -14, -6, -8, -25, -56, -30, -6]
		var foot: Array = [-8, 6, 10, 26, 34, 20, 0, -10] if run else [-12, 0, 2, 10, 22, 10, -4, -12]
		var hy: Array = [0.885, 0.855, 0.875, 0.915, 0.885, 0.855, 0.875, 0.915] if run else [0.895, 0.905, 0.918, 0.905, 0.895, 0.905, 0.918, 0.905]
		var data := {"hips@pos": [], "hips": [], "torso": [], "head": [], "leg_r": [], "knee_r": [], "foot_r": [],
			"leg_l": [], "knee_l": [], "foot_l": [], "shoulder_r": [], "elbow_r": [], "shoulder_l": [], "elbow_l": [],
			"hand_r": [[0.0, V.call(-36, 0, 0) if sword else hand_r]]}
		for i in 8:
			var t: float = ph[i] * L
			var o := (i + 4) % 8
			# The swing of the cycle: +1 with the right leg forward, -1 with the left.
			var c := cos(ph[i] * TAU)
			data["hips@pos"].append([t, V.call(0, hy[i], 0)])
			data["hips"].append([t, V.call(0, 7.0 * c if run else 5.0 * c, (2.0 if run else 3.0) * sin(ph[i] * TAU))])
			data["torso"].append([t, V.call(-8.0 if run else -3.0, (-13.0 if run else -7.0) * c, 0)])
			data["head"].append([t, V.call(6.0 if run else 2.0, (5.0 if run else 3.0) * c, 0)])
			data["leg_r"].append([t, V.call(hip[i], 0, 3)])
			data["knee_r"].append([t, V.call(knee[i], 0, 0)])
			data["foot_r"].append([t, V.call(foot[i], 0, 0)])
			data["leg_l"].append([t, V.call(hip[o], 0, -3)])
			data["knee_l"].append([t, V.call(knee[o], 0, 0)])
			data["foot_l"].append([t, V.call(foot[o], 0, 0)])
			# Each arm swings against its leg, a touch behind it.
			var ac := cos(ph[i] * TAU - 0.35)
			if sword:
				# The blade held low and level at his side, swinging a little.
				data["shoulder_r"].append([t, V.call(14 - 14 * ac, 0, 14)])
				data["elbow_r"].append([t, V.call(30 + 6 * ac, 0, 0)])
				data["shoulder_l"].append([t, V.call(5 + 42 * ac, 0, -12)])
				data["elbow_l"].append([t, V.call(82 - 16 * ac, 0, 0)])
			elif run:
				data["shoulder_r"].append([t, V.call(5 - 42 * ac, 0, 12)])
				data["elbow_r"].append([t, V.call(82 + 16 * ac, 0, 0)])
				data["shoulder_l"].append([t, V.call(5 + 42 * ac, 0, -12)])
				data["elbow_l"].append([t, V.call(82 - 16 * ac, 0, 0)])
			else:
				data["shoulder_r"].append([t, V.call(2 - 22 * ac, 0, 9)])
				data["elbow_r"].append([t, V.call(28 - 10 * ac, 0, 0)])
				data["shoulder_l"].append([t, V.call(2 + 22 * ac, 0, -9)])
				data["elbow_l"].append([t, V.call(28 + 10 * ac, 0, 0)])
		_anim(lib, n, L, true, data, rest)
	gait.call("run", 0.56, true)
	# OoT runs differently with the sword out (the blade would otherwise pump
	# up past his face); the controller picks this one while it is drawn.
	gait.call("run_sword", 0.56, true, true)
	gait.call("walk", 0.84, false)

	# Sidestep cycle for strafing while locked on. Played forward it steps to the
	# right, backward it steps to the left.
	var side := {"hips@pos": [], "hips": [], "torso": [[0.0, V.call(-6, 4, 0)]], "head": [[0.0, V.call(4, -4, 0)]],
		"leg_r": [], "knee_r": [], "foot_r": [], "leg_l": [], "knee_l": [], "foot_l": [],
		"shoulder_r": [], "elbow_r": [[0.0, V.call(42, 0, 0)]], "hand_r": [[0.0, V.call(-42, 0, 0)]],
		"shoulder_l": [[0.0, V.call(35, -20, -15)]], "elbow_l": [[0.0, V.call(70, 0, 0)]]}
	for i in 8:
		var ph := i / 8.0
		var t := ph * 0.6
		var sn := sin(ph * TAU)
		# The right foot reaches out (first half), the left closes in after it.
		var reach := maxf(sn, 0.0)
		var close := maxf(-sn, 0.0)
		side["hips@pos"].append([t, V.call(0, 0.885 + 0.028 * absf(sn), 0)])
		side["hips"].append([t, V.call(0, 0, 4 * sn)])
		side["leg_r"].append([t, V.call(8 + 8 * reach, 0, 4 + 18 * reach)])
		side["knee_r"].append([t, V.call(-18 - 24 * reach, 0, 0)])
		side["foot_r"].append([t, V.call(10 + 10 * reach, 0, -4 - 10 * reach)])
		side["leg_l"].append([t, V.call(8 + 8 * close, 0, -4 + 16 * close)])
		side["knee_l"].append([t, V.call(-18 - 24 * close, 0, 0)])
		side["foot_l"].append([t, V.call(10 + 10 * close, 0, 4 - 8 * close)])
		side["shoulder_r"].append([t, V.call(22 + 3 * sn, 0, 14)])
	_anim(lib, "sidestep", 0.6, true, side, rest)

	_anim(lib, "turn", 0.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.91, 0)], [0.1, V.call(0, 0.93, 0)], [0.2, V.call(0, 0.91, 0)], [0.3, V.call(0, 0.93, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.1, V.call(20, 0, 6)], [0.2, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-35, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.2, V.call(0, 0, -3)], [0.3, V.call(20, 0, -6)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.2, V.call(0, 0, 0)], [0.3, V.call(-35, 0, 0)]],
		"shoulder_r": [[0.0, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l]], "elbow_l": [[0.0, elbow_l]],
	}, rest)

	_anim(lib, "jump", 0.3, false, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.1, V.call(0, 0.94, 0)], [0.3, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(-15, 0, 0)], [0.1, V.call(-4, 0, 0)]],
		"head": [[0.0, V.call(8, 0, 0)], [0.1, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(35, 0, 0)], [0.1, V.call(10, 0, 0)], [0.3, V.call(45, 0, 0)]],
		"knee_r": [[0.0, V.call(-65, 0, 0)], [0.1, V.call(-10, 0, 0)], [0.3, V.call(-80, 0, 0)]],
		"foot_r": [[0.0, V.call(30, 0, 0)], [0.1, V.call(20, 0, 0)]],
		"leg_l": [[0.0, V.call(35, 0, 0)], [0.1, V.call(0, 0, 0)], [0.3, V.call(10, 0, 0)]],
		"knee_l": [[0.0, V.call(-65, 0, 0)], [0.1, V.call(-5, 0, 0)], [0.3, V.call(-35, 0, 0)]],
		"foot_l": [[0.0, V.call(30, 0, 0)], [0.1, V.call(25, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-25, 0, 15)], [0.1, V.call(45, 0, 25)]],
		"elbow_r": [[0.0, V.call(30, 0, 0)], [0.1, V.call(40, 0, 0)]],
		"hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(-25, 0, -15)], [0.1, V.call(45, 0, -25)]],
		"elbow_l": [[0.0, V.call(30, 0, 0)], [0.1, V.call(40, 0, 0)]],
	}, rest)

	_anim(lib, "fall", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)]],
		"leg_r": [[0.0, V.call(25, 0, 4)], [0.3, V.call(15, 0, 4)]],
		"knee_r": [[0.0, V.call(-40, 0, 0)], [0.3, V.call(-25, 0, 0)]],
		"leg_l": [[0.0, V.call(5, 0, -4)], [0.3, V.call(15, 0, -4)]],
		"knee_l": [[0.0, V.call(-20, 0, 0)], [0.3, V.call(-35, 0, 0)]],
		"foot_r": [[0.0, V.call(25, 0, 0)]], "foot_l": [[0.0, V.call(25, 0, 0)]],
		"shoulder_r": [[0.0, V.call(25, 0, 45)], [0.3, V.call(25, 0, 55)]],
		"elbow_r": [[0.0, V.call(30, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(25, 0, -45)], [0.3, V.call(25, 0, -55)]],
		"elbow_l": [[0.0, V.call(30, 0, 0)]],
	}, rest)

	_anim(lib, "land", 0.2, false, {
		"hips@pos": [[0.0, V.call(0, 0.76, 0)], [0.2, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(-18, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(50, 0, 3)], [0.2, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(-90, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"foot_r": [[0.0, V.call(40, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(50, 0, -3)], [0.2, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(-90, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"foot_l": [[0.0, V.call(40, 0, 0)], [0.2, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-10, 0, 25)], [0.2, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(-10, 0, -25)], [0.2, arm_l]], "elbow_l": [[0.0, elbow_l]],
	}, rest)

	# A hard landing from a great height (func_80843E64, landing_damage): down on
	# one knee with a hand to the ground, held, then up again.
	_anim(lib, "land_hard", 0.9, false, {
		"hips@pos": [[0.0, V.call(0, 0.58, 0.02)], [0.6, V.call(0, 0.6, 0.02)], [0.9, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(-38, 0, 0)], [0.6, V.call(-30, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(30, 0, 0)], [0.6, V.call(20, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(95, 0, 4)], [0.6, V.call(90, 0, 4)], [0.9, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(-130, 0, 0)], [0.6, V.call(-125, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"foot_r": [[0.0, V.call(35, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(20, 0, -6)], [0.6, V.call(20, 0, -6)], [0.9, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(-110, 0, 0)], [0.6, V.call(-105, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"foot_l": [[0.0, V.call(-20, 0, 0)], [0.9, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-40, 0, 20)], [0.6, V.call(-35, 0, 20)], [0.9, arm_r]], "elbow_r": [[0.0, V.call(10, 0, 0)], [0.9, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(40, 0, -25)], [0.6, V.call(35, 0, -25)], [0.9, arm_l]], "elbow_l": [[0.0, V.call(5, 0, 0)], [0.9, elbow_l]],
	}, rest)

	# Sliding down a slippery slope facing downhill (down_slope_slip): crouched,
	# leaning back, arms out for balance.
	_anim(lib, "slope_slip", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.74, -0.05)], [0.3, V.call(0, 0.72, -0.05)], [0.6, V.call(0, 0.74, -0.05)]],
		"torso": [[0.0, V.call(10, 0, 3)], [0.3, V.call(10, 0, -3)], [0.6, V.call(10, 0, 3)]],
		"head": [[0.0, V.call(12, 0, 0)]],
		"leg_r": [[0.0, V.call(55, 0, 8)]], "knee_r": [[0.0, V.call(-80, 0, 0)]], "foot_r": [[0.0, V.call(30, 0, 0)]],
		"leg_l": [[0.0, V.call(30, 0, -8)]], "knee_l": [[0.0, V.call(-60, 0, 0)]], "foot_l": [[0.0, V.call(25, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-15, 0, 70)], [0.3, V.call(-10, 0, 62)], [0.6, V.call(-15, 0, 70)]], "elbow_r": [[0.0, V.call(15, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(-15, 0, -62)], [0.3, V.call(-10, 0, -70)], [0.6, V.call(-15, 0, -62)]], "elbow_l": [[0.0, V.call(15, 0, 0)]],
	}, rest)

	# Sliding backward down a slope, facing uphill (up_slope_slip): bent over,
	# hands reaching for the slope.
	_anim(lib, "slope_slip_up", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.76, 0.06)], [0.3, V.call(0, 0.74, 0.06)], [0.6, V.call(0, 0.76, 0.06)]],
		"torso": [[0.0, V.call(-45, 0, 0)], [0.3, V.call(-42, 0, 0)], [0.6, V.call(-45, 0, 0)]],
		"head": [[0.0, V.call(-25, 0, 0)]],
		"leg_r": [[0.0, V.call(40, 0, 6)]], "knee_r": [[0.0, V.call(-50, 0, 0)]], "foot_r": [[0.0, V.call(10, 0, 0)]],
		"leg_l": [[0.0, V.call(45, 0, -6)]], "knee_l": [[0.0, V.call(-55, 0, 0)]], "foot_l": [[0.0, V.call(10, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-80, 0, 15)], [0.3, V.call(-70, 0, 15)], [0.6, V.call(-80, 0, 15)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(-70, 0, -15)], [0.3, V.call(-80, 0, -15)], [0.6, V.call(-70, 0, -15)]], "elbow_l": [[0.0, V.call(10, 0, 0)]],
	}, rest)

	# Forward roll (OoT: 20 frames at 1.25x speed = 0.53 s). The hips joint spins
	# a full turn forward while the body tucks into a ball.
	var tuck := {
		"torso": V.call(-45, 0, 0), "head": V.call(-25, 0, 0),
		"leg_r": V.call(115, 0, 6), "knee_r": V.call(-140, 0, 0), "foot_r": V.call(30, 0, 0),
		"leg_l": V.call(115, 0, -6), "knee_l": V.call(-140, 0, 0), "foot_l": V.call(30, 0, 0),
		"shoulder_r": V.call(70, 0, 15), "elbow_r": V.call(80, 0, 0), "hand_r": V.call(-30, 0, 0),
		"shoulder_l": V.call(70, 0, -15), "elbow_l": V.call(80, 0, 0),
	}
	var roll := {
		"hips@pos": [[0.0, V.call(0, 0.85, 0)], [0.08, V.call(0, 0.42, 0)], [0.42, V.call(0, 0.42, 0)], [0.53, V.call(0, 0.92, 0)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-90, 0, 0)], [0.2, V.call(-180, 0, 0)], [0.3, V.call(-270, 0, 0)], [0.42, V.call(-360, 0, 0)]],
	}
	for key in tuck:
		roll[key] = [[0.0, Vector3.ZERO], [0.08, tuck[key]], [0.4, tuck[key]], [0.53, Vector3.ZERO]]
	roll["shoulder_r"][3] = [0.53, arm_r]
	roll["elbow_r"][3] = [0.53, elbow_r]
	_anim(lib, "roll", 0.53, false, roll, rest)

	# Backflip while locked on: a full backward turn of the hips in the air.
	var flip := {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.06, V.call(0, 0.7, 0)], [0.36, V.call(0, 0.7, 0)], [0.48, V.call(0, 0.92, 0)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.1, V.call(90, 0, 0)], [0.19, V.call(180, 0, 0)], [0.28, V.call(270, 0, 0)], [0.38, V.call(360, 0, 0)]],
	}
	var flip_tuck := tuck.duplicate()
	flip_tuck["torso"] = V.call(-25, 0, 0)
	flip_tuck["leg_r"] = V.call(80, 0, 6)
	flip_tuck["leg_l"] = V.call(80, 0, -6)
	flip_tuck["knee_r"] = V.call(-110, 0, 0)
	flip_tuck["knee_l"] = V.call(-110, 0, 0)
	for key in flip_tuck:
		flip[key] = [[0.0, Vector3.ZERO], [0.07, flip_tuck[key]], [0.34, flip_tuck[key]], [0.48, Vector3.ZERO]]
	_anim(lib, "backflip", 0.48, false, flip, rest)

	# Side hops: a short skip sideways, legs tucked, body tilted into the hop.
	for variant in [["sidehop_r", 1.0], ["sidehop_l", -1.0]]:
		var d: float = variant[1]
		_anim(lib, variant[0], 0.32, false, {
			"hips@pos": [[0.0, V.call(0, 0.86, 0)], [0.08, V.call(0, 0.9, 0)], [0.32, V.call(0, 0.9, 0)]],
			"hips": [[0.0, V.call(0, 0, 0)], [0.1, V.call(0, 0, 14 * d)], [0.32, V.call(0, 0, 4 * d)]],
			"torso": [[0.0, V.call(-8, 0, 0)], [0.1, V.call(-6, 0, -10 * d)]],
			"leg_r": [[0.0, V.call(15, 0, 4)], [0.1, V.call(35, 0, 12 * d + 4)], [0.32, V.call(25, 0, 6)]],
			"knee_r": [[0.0, V.call(-30, 0, 0)], [0.1, V.call(-70, 0, 0)], [0.32, V.call(-45, 0, 0)]],
			"leg_l": [[0.0, V.call(15, 0, -4)], [0.1, V.call(35, 0, 12 * d - 4)], [0.32, V.call(25, 0, -6)]],
			"knee_l": [[0.0, V.call(-30, 0, 0)], [0.1, V.call(-70, 0, 0)], [0.32, V.call(-45, 0, 0)]],
			"shoulder_r": [[0.0, arm_r], [0.1, V.call(20, 0, 45)]], "elbow_r": [[0.0, elbow_r], [0.1, V.call(40, 0, 0)]], "hand_r": [[0.0, hand_r]],
			"shoulder_l": [[0.0, arm_l], [0.1, V.call(20, 0, -45)]], "elbow_l": [[0.0, elbow_l], [0.1, V.call(40, 0, 0)]],
		}, rest)

	_sword_anims(lib, rest)

	# Jump slash (Lpower_jump_kiru): the hero springs up with the sword swung
	# high behind his head and his knees tucked, and holds it there until he
	# lands; then (Lpower_jump_kiru_hit / _end) the blade comes down in a
	# vertical chop into a deep crouch and he straightens up.
	var raised := {
		"torso": V.call(8, 0, 0), "head": V.call(-6, 0, 0),
		"shoulder_r": V.call(165, 0, 6), "elbow_r": V.call(50, 0, 0), "hand_r": V.call(-15, 0, 0),
		"shoulder_l": V.call(30, 0, -35), "elbow_l": V.call(50, 0, 0),
		"leg_r": V.call(55, 0, 4), "knee_r": V.call(-95, 0, 0), "foot_r": V.call(30, 0, 0),
		"leg_l": V.call(20, 0, -4), "knee_l": V.call(-60, 0, 0), "foot_l": V.call(25, 0, 0),
	}
	var js := {"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.1, V.call(0, 0.95, 0)], [0.45, V.call(0, 0.95, 0)]]}
	for key: String in raised:
		js[key] = [[0.0, Vector3.ZERO], [0.14, raised[key]], [0.45, raised[key] + V.call(4, 0, 0)]]
	js["shoulder_r"][0] = [0.0, arm_r]
	js["elbow_r"][0] = [0.0, elbow_r]
	js["hand_r"][0] = [0.0, hand_r]
	_anim(lib, "jumpslash", 0.45, false, js, rest)
	var chop := {
		"torso": V.call(-24, 0, 0), "head": V.call(14, 0, 0),
		"shoulder_r": V.call(58, 0, 4), "elbow_r": V.call(4, 0, 0), "hand_r": V.call(-78, 0, 0),
		"shoulder_l": V.call(-20, 0, -40), "elbow_l": V.call(40, 0, 0),
		"leg_l": V.call(72, 0, -6), "knee_l": V.call(-100, 0, 0), "foot_l": V.call(28, 0, 0),
		"leg_r": V.call(-8, 0, 8), "knee_r": V.call(-70, 0, 0), "foot_r": V.call(55, 0, 0),
	}
	var jl := {"hips@pos": [[0.0, V.call(0, 0.86, 0)], [0.07, V.call(0, 0.6, 0.04)], [0.28, V.call(0, 0.62, 0.04)], [0.5, V.call(0, 0.91, 0)]]}
	var stand := {"shoulder_r": arm_r, "elbow_r": elbow_r, "hand_r": hand_r, "shoulder_l": arm_l, "elbow_l": elbow_l,
		"leg_r": V.call(0, 0, 3), "leg_l": V.call(0, 0, -3)}
	for key: String in chop:
		var from: Vector3 = raised.get(key, Vector3.ZERO)
		jl[key] = [[0.0, from], [0.07, chop[key]], [0.28, chop[key]], [0.5, stand.get(key, Vector3.ZERO)]]
	_anim(lib, "jumpslash_land", 0.5, false, jl, rest)

	# The Knight's Techniques (Chapter V). "spin_attack": the blade held out
	# flat at arm's length, low in a wide stance, while the body turns a full
	# circle (the controller turns him). "spin_charge": crouched, the blade
	# drawn back low at his side, gathering strength. "shield_bash": a shove
	# behind the shield with the weight thrown forward.
	_anim(lib, "spin_attack", 0.42, false, {
		"hips@pos": [[0.0, V.call(0, 0.86, 0)], [0.1, V.call(0, 0.8, 0)], [0.32, V.call(0, 0.8, 0)], [0.42, V.call(0, 0.88, 0)]],
		"torso": [[0.0, V.call(-6, 20, 0)], [0.1, V.call(-10, -10, 0)], [0.42, V.call(-6, -20, 0)]],
		"head": [[0.0, V.call(4, -10, 0)], [0.42, V.call(4, 10, 0)]],
		"shoulder_r": [[0.0, V.call(80, 40, 0)], [0.1, V.call(86, -60, 0)], [0.32, V.call(86, -70, 0)], [0.42, V.call(60, -40, 0)]],
		"elbow_r": [[0.0, V.call(20, 0, 0)], [0.1, V.call(6, 0, 0)], [0.42, V.call(20, 0, 0)]],
		"hand_r": [[0.0, V.call(-70, 90, 0)], [0.1, V.call(-82, 90, 0)], [0.42, V.call(-60, 90, 0)]],
		"shoulder_l": [[0.0, V.call(20, 0, -40)], [0.42, V.call(20, 0, -50)]], "elbow_l": [[0.0, V.call(45, 0, 0)]],
		"leg_l": [[0.0, V.call(32, 0, -14)]], "knee_l": [[0.0, V.call(-48, 0, 0)]], "foot_l": [[0.0, V.call(16, 0, 0)]],
		"leg_r": [[0.0, V.call(-14, 0, 14)]], "knee_r": [[0.0, V.call(-26, 0, 0)]], "foot_r": [[0.0, V.call(30, 0, 0)]],
	}, rest)
	_anim(lib, "spin_charge", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.3, V.call(0, 0.83, 0)]],
		"torso": [[0.0, V.call(-10, 30, 0)], [0.3, V.call(-11, 32, 0)]], "head": [[0.0, V.call(6, -28, 0)]],
		"shoulder_r": [[0.0, V.call(20, 60, 30)], [0.3, V.call(22, 62, 32)]], "elbow_r": [[0.0, V.call(30, 0, 0)]], "hand_r": [[0.0, V.call(-60, 90, 0)]],
		"shoulder_l": [[0.0, V.call(40, -20, -20)]], "elbow_l": [[0.0, V.call(60, 0, 0)]],
		"leg_l": [[0.0, V.call(28, 0, -12)]], "knee_l": [[0.0, V.call(-40, 0, 0)]], "foot_l": [[0.0, V.call(12, 0, 0)]],
		"leg_r": [[0.0, V.call(-12, 0, 12)]], "knee_r": [[0.0, V.call(-24, 0, 0)]], "foot_r": [[0.0, V.call(24, 0, 0)]],
	}, rest)
	_anim(lib, "shield_bash", 0.38, false, {
		"hips@pos": [[0.0, V.call(0, 0.86, 0)], [0.1, V.call(0, 0.82, -0.12)], [0.38, V.call(0, 0.88, 0)]],
		"torso": [[0.0, V.call(-6, -18, 0)], [0.1, V.call(-18, 10, 0)], [0.38, V.call(-6, 0, 0)]],
		"head": [[0.0, V.call(6, 10, 0)], [0.1, V.call(10, -6, 0)], [0.38, V.call(0, 0, 0)]],
		"shoulder_l": [[0.0, V.call(50, -10, -20)], [0.1, V.call(88, 10, -6)], [0.25, V.call(84, 6, -8)], [0.38, V.call(55, -20, -20)]],
		"elbow_l": [[0.0, V.call(90, 0, 0)], [0.1, V.call(30, 0, 0)], [0.38, V.call(80, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.1, V.call(-20, 0, 20)], [0.38, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.1, V.call(40, 0, -4)], [0.38, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-40, 0, 0)], [0.38, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.1, V.call(-25, 0, 4)], [0.38, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.1, V.call(-12, 0, 0)], [0.38, V.call(0, 0, 0)]],
	}, rest)
	# The knighting (Chapter V): down on his right knee, head bowed, left hand
	# on the raised left knee.
	_anim(lib, "kneel", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.5, 0.08)], [0.8, V.call(0, 0.495, 0.08)]],
		"torso": [[0.0, V.call(-8, 0, 0)]], "head": [[0.0, V.call(28, 0, 0)], [0.8, V.call(30, 0, 0)]],
		"leg_l": [[0.0, V.call(85, 0, -4)]], "knee_l": [[0.0, V.call(-90, 0, 0)]], "foot_l": [[0.0, V.call(5, 0, 0)]],
		"leg_r": [[0.0, V.call(-10, 0, 4)]], "knee_r": [[0.0, V.call(-95, 0, 0)]], "foot_r": [[0.0, V.call(40, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, 0, -10)]], "elbow_l": [[0.0, V.call(50, 0, 0)]],
		"shoulder_r": [[0.0, V.call(5, 0, 10)]], "elbow_r": [[0.0, V.call(20, 0, 0)]], "hand_r": [[0.0, hand_r]],
	}, rest)
	# Dragging a great stone (the Questlord's Gauntlets): crouched, both hands
	# gripping it at arm's length, leaning back, stepping backward.
	_anim(lib, "pull", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.74, 0.06)], [0.2, V.call(0, 0.71, 0.08)], [0.4, V.call(0, 0.74, 0.06)], [0.6, V.call(0, 0.71, 0.08)]],
		"torso": [[0.0, V.call(-14, 0, 0)], [0.4, V.call(-10, 0, 0)]], "head": [[0.0, V.call(10, 0, 0)]],
		"shoulder_r": [[0.0, V.call(78, 0, 10)], [0.4, V.call(74, 0, 10)]], "elbow_r": [[0.0, V.call(12, 0, 0)]], "hand_r": [[0.0, V.call(-20, 0, 0)]],
		"shoulder_l": [[0.0, V.call(78, 0, -10)], [0.4, V.call(74, 0, -10)]], "elbow_l": [[0.0, V.call(12, 0, 0)]],
		"leg_r": [[0.0, V.call(50, 0, 6)], [0.2, V.call(20, 0, 6)], [0.4, V.call(-10, 0, 6)], [0.6, V.call(30, 0, 6)]],
		"knee_r": [[0.0, V.call(-80, 0, 0)], [0.2, V.call(-50, 0, 0)], [0.4, V.call(-30, 0, 0)], [0.6, V.call(-70, 0, 0)]],
		"leg_l": [[0.0, V.call(-10, 0, -6)], [0.2, V.call(30, 0, -6)], [0.4, V.call(50, 0, -6)], [0.6, V.call(20, 0, -6)]],
		"knee_l": [[0.0, V.call(-30, 0, 0)], [0.2, V.call(-70, 0, 0)], [0.4, V.call(-80, 0, 0)], [0.6, V.call(-50, 0, 0)]],
		"foot_r": [[0.0, V.call(20, 0, 0)]], "foot_l": [[0.0, V.call(20, 0, 0)]],
	}, rest)

	# On horseback: astride the saddle, knees out round the horse's barrel,
	# both hands forward on the reins. "ride_gallop" rises in the stirrups
	# and leans into the wind.
	var seat_legs := {
		"leg_r": V.call(62, 0, 28), "knee_r": V.call(-78, 0, 0), "foot_r": V.call(20, 0, 0),
		"leg_l": V.call(62, 0, -28), "knee_l": V.call(-78, 0, 0), "foot_l": V.call(20, 0, 0),
		"shoulder_r": V.call(38, -14, 10), "elbow_r": V.call(62, 0, 0), "hand_r": V.call(-20, 0, 0),
		"shoulder_l": V.call(38, 14, -10), "elbow_l": V.call(62, 0, 0),
	}
	var ride := {"hips@pos": [[0.0, V.call(0, 0.92, 0)], [0.9, V.call(0, 0.935, 0)]], "torso": [[0.0, V.call(-6, 0, 0)], [0.9, V.call(-4, 0, 0)]]}
	for key: String in seat_legs:
		ride[key] = [[0.0, seat_legs[key]]]
	_anim(lib, "ride", 1.8, true, ride, rest)
	var gal := {"hips@pos": [[0.0, V.call(0, 0.95, 0.02)], [0.25, V.call(0, 1.02, -0.02)]], "torso": [[0.0, V.call(-18, 0, 0)], [0.25, V.call(-12, 0, 0)]],
		"head": [[0.0, V.call(12, 0, 0)], [0.25, V.call(8, 0, 0)]]}
	for key: String in seat_legs:
		gal[key] = [[0.0, seat_legs[key]]]
	gal["leg_r"] = [[0.0, V.call(50, 0, 26)], [0.25, V.call(40, 0, 24)]]
	gal["leg_l"] = [[0.0, V.call(50, 0, -26)], [0.25, V.call(40, 0, -24)]]
	gal["knee_r"] = [[0.0, V.call(-85, 0, 0)], [0.25, V.call(-70, 0, 0)]]
	gal["knee_l"] = [[0.0, V.call(-85, 0, 0)], [0.25, V.call(-70, 0, 0)]]
	_anim(lib, "ride_gallop", 0.5, true, gal, rest)

	# Swimming (gPlayerAnim_link_swimer_*). The water line sits at his chest:
	# "swim" lies him forward into a breaststroke, arms reaching ahead and
	# sweeping out and back while the legs kick; "swim_wait" treads water
	# upright, hands sculling; "dive" tips him head first under.
	var sw := 0.75
	_anim(lib, "swim", sw, true, {
		"hips@pos": [[0.0, V.call(0, 1.12, 0.12)], [sw * 0.5, V.call(0, 1.16, 0.12)]],
		"hips": [[0.0, V.call(-62, 0, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)], [sw * 0.5, V.call(-4, 0, 0)]],
		"head": [[0.0, V.call(40, 0, 0)], [sw * 0.5, V.call(32, 0, 0)]],
		"shoulder_r": [[0.0, V.call(168, 0, 8)], [sw * 0.35, V.call(120, 0, 70)], [sw * 0.6, V.call(40, 0, 40)], [sw * 0.85, V.call(110, 0, 10)]],
		"elbow_r": [[0.0, V.call(10, 0, 0)], [sw * 0.35, V.call(25, 0, 0)], [sw * 0.6, V.call(95, 0, 0)], [sw * 0.85, V.call(70, 0, 0)]],
		"hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(168, 0, -8)], [sw * 0.35, V.call(120, 0, -70)], [sw * 0.6, V.call(40, 0, -40)], [sw * 0.85, V.call(110, 0, -10)]],
		"elbow_l": [[0.0, V.call(10, 0, 0)], [sw * 0.35, V.call(25, 0, 0)], [sw * 0.6, V.call(95, 0, 0)], [sw * 0.85, V.call(70, 0, 0)]],
		"leg_r": [[0.0, V.call(-10, 0, 8)], [sw * 0.4, V.call(40, 0, 20)], [sw * 0.7, V.call(-5, 0, 4)]],
		"knee_r": [[0.0, V.call(-15, 0, 0)], [sw * 0.4, V.call(-95, 0, 0)], [sw * 0.7, V.call(-10, 0, 0)]],
		"leg_l": [[0.0, V.call(-10, 0, -8)], [sw * 0.4, V.call(40, 0, -20)], [sw * 0.7, V.call(-5, 0, -4)]],
		"knee_l": [[0.0, V.call(-15, 0, 0)], [sw * 0.4, V.call(-95, 0, 0)], [sw * 0.7, V.call(-10, 0, 0)]],
		"foot_r": [[0.0, V.call(40, 0, 0)]], "foot_l": [[0.0, V.call(40, 0, 0)]],
	}, rest)
	_anim(lib, "swim_wait", 1.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.9, 0)], [0.6, V.call(0, 0.93, 0)]],
		"hips": [[0.0, V.call(-12, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)]],
		"shoulder_r": [[0.0, V.call(35, 0, 55)], [0.6, V.call(35, 0, 25)]],
		"elbow_r": [[0.0, V.call(40, 0, 0)], [0.6, V.call(60, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(35, 0, -55)], [0.6, V.call(35, 0, -25)]],
		"elbow_l": [[0.0, V.call(40, 0, 0)], [0.6, V.call(60, 0, 0)]],
		"leg_r": [[0.0, V.call(25, 0, 6)], [0.6, V.call(-5, 0, 6)]],
		"knee_r": [[0.0, V.call(-60, 0, 0)], [0.6, V.call(-20, 0, 0)]],
		"leg_l": [[0.0, V.call(-5, 0, -6)], [0.6, V.call(25, 0, -6)]],
		"knee_l": [[0.0, V.call(-20, 0, 0)], [0.6, V.call(-60, 0, 0)]],
		"foot_r": [[0.0, V.call(30, 0, 0)]], "foot_l": [[0.0, V.call(30, 0, 0)]],
	}, rest)
	_anim(lib, "dive", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 1.0, 0.2)]],
		"hips": [[0.0, V.call(-120, 0, 0)]],
		"head": [[0.0, V.call(20, 0, 0)]],
		"shoulder_r": [[0.0, V.call(172, 0, 6)], [0.4, V.call(150, 0, 40)]], "elbow_r": [[0.0, V.call(6, 0, 0)], [0.4, V.call(30, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(172, 0, -6)], [0.4, V.call(150, 0, -40)]], "elbow_l": [[0.0, V.call(6, 0, 0)], [0.4, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-15, 0, 4)], [0.4, V.call(15, 0, 4)]], "knee_r": [[0.0, V.call(-10, 0, 0)], [0.4, V.call(-50, 0, 0)]],
		"leg_l": [[0.0, V.call(15, 0, -4)], [0.4, V.call(-15, 0, -4)]], "knee_l": [[0.0, V.call(-50, 0, 0)], [0.4, V.call(-10, 0, 0)]],
		"foot_r": [[0.0, V.call(45, 0, 0)]], "foot_l": [[0.0, V.call(45, 0, 0)]],
	}, rest)

	# Shield raised in front: upper arm forward/inward, forearm vertical,
	# shield rotated about the forearm so its face points forward.
	var block_pose := {
		"hips@pos": [[0.0, V.call(0, 0.91, 0)], [0.12, V.call(0, 0.86, 0)]],
		"torso": [[0.0, V.call(-4, 0, 0)], [0.12, V.call(-8, -8, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.12, V.call(6, 0, 0)]],
		"shoulder_l": [[0.0, arm_l], [0.12, V.call(58, -32, 0)]],
		"elbow_l": [[0.0, elbow_l], [0.12, V.call(118, 0, 0)]],
		"shield": [[0.0, V.call(0, 0, 0)], [0.12, V.call(0, 62, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.12, V.call(25, 0, 18)]],
		"elbow_r": [[0.0, elbow_r], [0.12, V.call(45, 0, 0)]],
		"hand_r": [[0.0, hand_r], [0.12, V.call(-5, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.12, V.call(20, 0, -5)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-28, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.12, V.call(-12, 0, 5)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-18, 0, 0)]],
		"foot_r": [[0.0, V.call(0, 0, 0)], [0.12, V.call(25, 0, 0)]],
	}
	_anim(lib, "block", 0.12, false, block_pose, rest)

	_anim(lib, "block_hit", 0.25, false, {
		"hips@pos": [[0.0, V.call(0, 0.83, 0.06)], [0.25, V.call(0, 0.86, 0)]],
		"torso": [[0.0, V.call(4, -8, 0)], [0.25, V.call(-8, -8, 0)]],
		"shoulder_l": [[0.0, V.call(50, -26, 0)], [0.25, V.call(58, -32, 0)]],
		"elbow_l": [[0.0, V.call(125, 0, 0)], [0.25, V.call(118, 0, 0)]],
		"shield": [[0.0, V.call(0, 62, 0)]],
		"shoulder_r": [[0.0, V.call(25, 0, 18)]], "elbow_r": [[0.0, V.call(45, 0, 0)]], "hand_r": [[0.0, V.call(-5, 0, 0)]],
		"leg_l": [[0.0, V.call(20, 0, -5)]], "knee_l": [[0.0, V.call(-28, 0, 0)]],
		"leg_r": [[0.0, V.call(-12, 0, 5)]], "knee_r": [[0.0, V.call(-18, 0, 0)]], "foot_r": [[0.0, V.call(25, 0, 0)]],
	}, rest)

	# OoT's "defense" pose without Z-targeting: crouched low behind the shield,
	# front knee forward and back knee deep, sword held low behind.
	var crouch := {
		"hips@pos": V.call(0, 0.64, 0.03),
		"torso": V.call(-16, -10, 0), "head": V.call(14, 6, 0),
		"leg_l": V.call(68, 0, -6), "knee_l": V.call(-95, 0, 0), "foot_l": V.call(26, 0, 0),
		"leg_r": V.call(22, 0, 8), "knee_r": V.call(-88, 0, 0), "foot_r": V.call(62, 0, 0),
		"shoulder_l": V.call(62, -30, 0), "elbow_l": V.call(112, 0, 0), "shield": V.call(0, 62, 0),
		"shoulder_r": V.call(-12, 0, 22), "elbow_r": V.call(40, 0, 0), "hand_r": V.call(-15, 0, 0),
	}
	var crouch_in := {}
	for key: String in crouch:
		var from: Vector3 = rest["hips"] if key == "hips@pos" else Vector3.ZERO
		crouch_in[key] = [[0.0, from], [0.12, crouch[key]]]
	_anim(lib, "block_crouch", 0.12, false, crouch_in, rest)
	var crouch_hit := {}
	for key: String in crouch:
		crouch_hit[key] = [[0.0, crouch[key]], [0.25, crouch[key]]]
	crouch_hit["hips@pos"] = [[0.0, V.call(0, 0.6, 0.1)], [0.25, crouch["hips@pos"]]]
	crouch_hit["torso"] = [[0.0, V.call(-4, -10, 0)], [0.25, crouch["torso"]]]
	crouch_hit["shoulder_l"] = [[0.0, V.call(54, -24, 0)], [0.25, crouch["shoulder_l"]]]
	_anim(lib, "block_crouch_hit", 0.25, false, crouch_hit, rest)

	# Putting the sword away: the right hand reaches over the right shoulder to
	# the scabbard (the sword swaps to the back half way through) and comes back.
	_anim(lib, "sheathe", 0.5, false, {
		"torso": [[0.0, V.call(0, 0, 0)], [0.2, V.call(4, -12, 0)], [0.5, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.2, V.call(-4, 10, 0)], [0.5, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.2, V.call(155, 0, 12)], [0.3, V.call(155, 0, 12)], [0.5, arm_r]],
		"elbow_r": [[0.0, elbow_r], [0.2, V.call(105, 0, 0)], [0.3, V.call(105, 0, 0)], [0.5, elbow_r]],
		"hand_r": [[0.0, hand_r], [0.2, V.call(-30, 0, 0)], [0.5, hand_r]],
		"shoulder_l": [[0.0, arm_l]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(0, 0, -3)]],
	}, rest)

	_anim(lib, "hurt", 0.4, false, {
		"hips@pos": [[0.0, V.call(0, 0.9, 0.05)], [0.4, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(22, 0, 5)], [0.4, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(18, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(20, 0, 50)], [0.4, arm_r]], "elbow_r": [[0.0, V.call(20, 0, 0)], [0.4, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(20, 0, -50)], [0.4, arm_l]], "elbow_l": [[0.0, V.call(20, 0, 0)], [0.4, elbow_l]],
		"leg_r": [[0.0, V.call(-10, 0, 3)], [0.4, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(15, 0, -3)], [0.4, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(-20, 0, 0)], [0.4, V.call(0, 0, 0)]],
	}, rest)

	# Holding up a new treasure (OoT's get-item pose): both hands high over his
	# head, chin up, feet set apart.
	_anim(lib, "item_get", 0.35, false, {
		"hips@pos": [[0.0, V.call(0, 0.9, 0)], [0.2, V.call(0, 0.94, 0)], [0.35, V.call(0, 0.93, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.35, V.call(8, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.35, V.call(14, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.25, V.call(172, 0, 18)], [0.35, V.call(168, 0, 16)]],
		"elbow_r": [[0.0, elbow_r], [0.35, V.call(22, 0, 0)]], "hand_r": [[0.0, hand_r], [0.35, V.call(-10, 0, 0)]],
		"shoulder_l": [[0.0, arm_l], [0.25, V.call(172, 0, -18)], [0.35, V.call(168, 0, -16)]],
		"elbow_l": [[0.0, elbow_l], [0.35, V.call(22, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.35, V.call(0, 0, 8)]], "leg_l": [[0.0, V.call(0, 0, -3)], [0.35, V.call(0, 0, -8)]],
	}, rest)
	# Throwing the boomerang: a sidearm fling from the right hand.
	_anim(lib, "throw", 0.4, false, {
		"torso": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-4, 35, 0)], [0.22, V.call(-8, -30, 0)], [0.4, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.12, V.call(70, 0, 70)], [0.22, V.call(80, 0, 20)], [0.4, arm_r]],
		"elbow_r": [[0.0, elbow_r], [0.12, V.call(100, 0, 0)], [0.22, V.call(10, 0, 0)], [0.4, elbow_r]],
		"hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.22, V.call(-12, 0, 3)], [0.4, V.call(0, 0, 3)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.22, V.call(14, 0, -3)], [0.4, V.call(0, 0, -3)]],
	}, rest)

	# Lifting a pot, rock or shrub (OoT's carryB): squat and take hold of it
	# (the controller attaches it at 0.13 s), then stand and raise it over his
	# head into the carry pose the controller layers on the upper body.
	var carry_up := {
		"torso": V.call(4, 0, 0), "head": V.call(-6, 0, 0),
		"shoulder_r": V.call(165, 0, 16), "elbow_r": V.call(30, 0, 0), "hand_r": V.call(-40, 0, 0),
		"shoulder_l": V.call(165, 0, -16), "elbow_l": V.call(30, 0, 0),
	}
	_anim(lib, "lift", 0.5, false, {
		"hips@pos": [[0.0, rest["hips"]], [0.13, V.call(0, 0.6, 0.06)], [0.22, V.call(0, 0.64, 0.05)], [0.38, V.call(0, 0.9, 0)], [0.5, rest["hips"]]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.13, V.call(-38, 0, 0)], [0.22, V.call(-30, 0, 0)], [0.38, V.call(-4, 0, 0)], [0.5, carry_up["torso"]]],
		"head": [[0.0, V.call(0, 0, 0)], [0.13, V.call(20, 0, 0)], [0.38, V.call(4, 0, 0)], [0.5, carry_up["head"]]],
		"shoulder_r": [[0.0, arm_r], [0.13, V.call(62, 0, 14)], [0.22, V.call(70, 0, 14)], [0.38, V.call(130, 0, 22)], [0.5, carry_up["shoulder_r"]]],
		"elbow_r": [[0.0, elbow_r], [0.13, V.call(18, 0, 0)], [0.22, V.call(40, 0, 0)], [0.38, V.call(70, 0, 0)], [0.5, carry_up["elbow_r"]]],
		"hand_r": [[0.0, hand_r], [0.13, V.call(-30, 0, 0)], [0.5, carry_up["hand_r"]]],
		"shoulder_l": [[0.0, arm_l], [0.13, V.call(62, 0, -14)], [0.22, V.call(70, 0, -14)], [0.38, V.call(130, 0, -22)], [0.5, carry_up["shoulder_l"]]],
		"elbow_l": [[0.0, elbow_l], [0.13, V.call(18, 0, 0)], [0.22, V.call(40, 0, 0)], [0.38, V.call(70, 0, 0)], [0.5, carry_up["elbow_l"]]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.13, V.call(62, 0, 8)], [0.22, V.call(58, 0, 8)], [0.38, V.call(12, 0, 4)], [0.5, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.13, V.call(-100, 0, 0)], [0.22, V.call(-92, 0, 0)], [0.38, V.call(-20, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"foot_r": [[0.0, V.call(0, 0, 0)], [0.13, V.call(36, 0, 0)], [0.38, V.call(8, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.13, V.call(62, 0, -8)], [0.22, V.call(58, 0, -8)], [0.38, V.call(12, 0, -4)], [0.5, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.13, V.call(-100, 0, 0)], [0.22, V.call(-92, 0, 0)], [0.38, V.call(-20, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"foot_l": [[0.0, V.call(0, 0, 0)], [0.13, V.call(36, 0, 0)], [0.38, V.call(8, 0, 0)], [0.5, V.call(0, 0, 0)]],
	}, rest)
	# Throwing it (OoT's throw): hands back behind the head, then a two-handed
	# heave forward with a step (released at 0.1 s), and back to standing.
	_anim(lib, "throw_carry", 0.45, false, {
		"hips@pos": [[0.0, rest["hips"]], [0.12, V.call(0, 0.86, -0.03)], [0.3, V.call(0, 0.88, -0.02)], [0.45, rest["hips"]]],
		"torso": [[0.0, carry_up["torso"]], [0.05, V.call(12, 0, 0)], [0.13, V.call(-18, 0, 0)], [0.3, V.call(-10, 0, 0)], [0.45, V.call(0, 0, 0)]],
		"head": [[0.0, carry_up["head"]], [0.05, V.call(-10, 0, 0)], [0.13, V.call(6, 0, 0)], [0.45, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, carry_up["shoulder_r"]], [0.05, V.call(176, 0, 18)], [0.13, V.call(105, 0, 16)], [0.3, V.call(80, 0, 14)], [0.45, arm_r]],
		"elbow_r": [[0.0, carry_up["elbow_r"]], [0.05, V.call(75, 0, 0)], [0.13, V.call(8, 0, 0)], [0.3, V.call(15, 0, 0)], [0.45, elbow_r]],
		"hand_r": [[0.0, carry_up["hand_r"]], [0.13, V.call(-10, 0, 0)], [0.45, hand_r]],
		"shoulder_l": [[0.0, carry_up["shoulder_l"]], [0.05, V.call(176, 0, -18)], [0.13, V.call(105, 0, -16)], [0.3, V.call(80, 0, -14)], [0.45, arm_l]],
		"elbow_l": [[0.0, carry_up["elbow_l"]], [0.05, V.call(75, 0, 0)], [0.13, V.call(8, 0, 0)], [0.3, V.call(15, 0, 0)], [0.45, elbow_l]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.12, V.call(28, 0, -4)], [0.3, V.call(24, 0, -4)], [0.45, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-30, 0, 0)], [0.3, V.call(-26, 0, 0)], [0.45, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.12, V.call(-16, 0, 4)], [0.3, V.call(-12, 0, 4)], [0.45, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.12, V.call(-10, 0, 0)], [0.45, V.call(0, 0, 0)]],
		"foot_r": [[0.0, V.call(0, 0, 0)], [0.12, V.call(20, 0, 0)], [0.45, V.call(0, 0, 0)]],
	}, rest)

	# Bonking into a wall during a roll (OoT: knocked back onto his seat).
	_anim(lib, "bonk", 0.5, false, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0.04)], [0.12, V.call(0, 0.42, 0.08)], [0.35, V.call(0, 0.42, 0.08)], [0.5, V.call(0, 0.92, 0)]],
		"torso": [[0.0, V.call(25, 0, 0)], [0.12, V.call(-20, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(25, 0, 0)], [0.12, V.call(5, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(30, 0, 6)], [0.12, V.call(85, 0, 10)], [0.35, V.call(85, 0, 10)], [0.5, V.call(0, 0, 3)]],
		"knee_r": [[0.0, V.call(-30, 0, 0)], [0.12, V.call(-40, 0, 0)], [0.35, V.call(-40, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(30, 0, -6)], [0.12, V.call(85, 0, -10)], [0.35, V.call(85, 0, -10)], [0.5, V.call(0, 0, -3)]],
		"knee_l": [[0.0, V.call(-30, 0, 0)], [0.12, V.call(-40, 0, 0)], [0.35, V.call(-40, 0, 0)], [0.5, V.call(0, 0, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, 40)], [0.12, V.call(-20, 0, 25)], [0.5, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(30, 0, -40)], [0.12, V.call(-20, 0, -25)], [0.5, arm_l]], "elbow_l": [[0.0, elbow_l]],
	}, rest)

	# --- Climbing (the controller moves the body; these give the limbs) ---------
	# Hanging from a ledge (jump_climb_hold / _wait): arms straight up to the edge
	# and a little forward, body against the wall, legs dangling and swaying.
	var hang := {
		"hips@pos": V.call(0, 0.92, 0.04),
		"torso": V.call(-4, 0, 0), "head": V.call(10, 0, 0),
		"shoulder_r": V.call(162, 0, -4), "elbow_r": V.call(12, 0, 0), "hand_r": V.call(-30, 0, 0),
		"shoulder_l": V.call(162, 0, 4), "elbow_l": V.call(12, 0, 0),
		"leg_r": V.call(8, 0, 4), "knee_r": V.call(-14, 0, 0), "foot_r": V.call(30, 0, 0),
		"leg_l": V.call(-4, 0, -4), "knee_l": V.call(-8, 0, 0), "foot_l": V.call(30, 0, 0),
	}
	var hang_anim := {}
	for key: String in hang:
		hang_anim[key] = [[0.0, hang[key]]]
	hang_anim["leg_r"] = [[0.0, hang["leg_r"]], [0.8, V.call(-2, 0, 4)]]
	hang_anim["leg_l"] = [[0.0, hang["leg_l"]], [0.8, V.call(8, 0, -4)]]
	_anim(lib, "hang", 1.6, true, hang_anim, rest)

	# Pulling up from the hang (jump_climb_up): elbows bend and push down, one
	# knee comes up onto the edge, a crouch on top, then standing.
	var standing := {
		"hips@pos": V.call(0, 0.92, 0), "torso": V.call(0, 0, 0), "head": V.call(0, 0, 0),
		"shoulder_r": arm_r, "elbow_r": elbow_r, "hand_r": hand_r, "shoulder_l": arm_l, "elbow_l": elbow_l,
		"leg_r": V.call(0, 0, 3), "knee_r": V.call(0, 0, 0), "foot_r": V.call(0, 0, 0),
		"leg_l": V.call(0, 0, -3), "knee_l": V.call(0, 0, 0), "foot_l": V.call(0, 0, 0),
	}
	var pull := {
		"hips@pos": V.call(0, 0.86, 0.05), "torso": V.call(-32, 0, 0), "head": V.call(14, 0, 0),
		"shoulder_r": V.call(35, 0, 12), "elbow_r": V.call(95, 0, 0), "hand_r": V.call(-40, 0, 0),
		"shoulder_l": V.call(35, 0, -12), "elbow_l": V.call(95, 0, 0),
		"leg_r": V.call(85, 0, 6), "knee_r": V.call(-110, 0, 0), "foot_r": V.call(20, 0, 0),
		"leg_l": V.call(-10, 0, -4), "knee_l": V.call(-25, 0, 0), "foot_l": V.call(35, 0, 0),
	}
	var crouch_top := {
		"hips@pos": V.call(0, 0.62, 0.02), "torso": V.call(-28, 0, 0), "head": V.call(16, 0, 0),
		"shoulder_r": V.call(30, 0, 18), "elbow_r": V.call(45, 0, 0), "hand_r": V.call(-20, 0, 0),
		"shoulder_l": V.call(30, 0, -18), "elbow_l": V.call(45, 0, 0),
		"leg_r": V.call(80, 0, 6), "knee_r": V.call(-120, 0, 0), "foot_r": V.call(40, 0, 0),
		"leg_l": V.call(35, 0, -5), "knee_l": V.call(-100, 0, 0), "foot_l": V.call(60, 0, 0),
	}
	var climb_up := {}
	for key: String in standing:
		climb_up[key] = [[0.0, hang[key]], [0.32, pull[key]], [0.66, crouch_top[key]], [1.0, standing[key]]]
	_anim(lib, "hang_up", 1.0, false, climb_up, rest)

	# Stepping up onto chest-high (100step_up) and head-high (150step_up) ledges:
	# reach up, plant the hands, knee onto the top, rise.
	var reach := {
		"hips@pos": V.call(0, 0.9, 0), "torso": V.call(-8, 0, 0), "head": V.call(12, 0, 0),
		"shoulder_r": V.call(135, 0, 6), "elbow_r": V.call(25, 0, 0), "hand_r": V.call(-30, 0, 0),
		"shoulder_l": V.call(135, 0, -6), "elbow_l": V.call(25, 0, 0),
		"leg_r": V.call(10, 0, 3), "knee_r": V.call(-20, 0, 0), "foot_r": V.call(10, 0, 0),
		"leg_l": V.call(0, 0, -3), "knee_l": V.call(-10, 0, 0), "foot_l": V.call(10, 0, 0),
	}
	for variant in [["climb_low", 0.55], ["climb_high", 0.8]]:
		var L: float = variant[1]
		var step := {}
		for key: String in standing:
			step[key] = [[0.0, reach[key]], [L * 0.3, pull[key]], [L * 0.68, crouch_top[key]], [L, standing[key]]]
		_anim(lib, variant[0], L, false, step, rest)

	# Springing up the wall to catch a high ledge (250jump_start): arms overhead.
	_anim(lib, "jump_reach", 0.3, false, {
		"hips@pos": [[0.0, V.call(0, 0.8, 0)], [0.12, V.call(0, 0.94, 0)]],
		"torso": [[0.0, V.call(-14, 0, 0)], [0.12, V.call(-2, 0, 0)]],
		"head": [[0.0, V.call(6, 0, 0)], [0.12, V.call(14, 0, 0)]],
		"shoulder_r": [[0.0, V.call(-20, 0, 10)], [0.12, V.call(165, 0, -2)]],
		"elbow_r": [[0.0, V.call(30, 0, 0)], [0.12, V.call(10, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(-20, 0, -10)], [0.12, V.call(165, 0, 2)]],
		"elbow_l": [[0.0, V.call(30, 0, 0)], [0.12, V.call(10, 0, 0)]],
		"leg_r": [[0.0, V.call(40, 0, 3)], [0.12, V.call(5, 0, 3)]], "knee_r": [[0.0, V.call(-70, 0, 0)], [0.12, V.call(-10, 0, 0)]],
		"leg_l": [[0.0, V.call(40, 0, -3)], [0.12, V.call(-5, 0, -3)]], "knee_l": [[0.0, V.call(-70, 0, 0)], [0.12, V.call(-5, 0, 0)]],
		"foot_r": [[0.0, V.call(25, 0, 0)], [0.12, V.call(30, 0, 0)]], "foot_l": [[0.0, V.call(25, 0, 0)], [0.12, V.call(30, 0, 0)]],
	}, rest)

	# Climbing a ladder (climb_upL / climb_upR): one full cycle is two rungs; the
	# controller plays half a cycle per rung (backward going down).
	var rung_a := {
		"hips@pos": V.call(0, 0.92, 0.05), "torso": V.call(-6, 0, 0), "head": V.call(8, 0, 0),
		"shoulder_r": V.call(150, 0, -4), "elbow_r": V.call(40, 0, 0), "hand_r": V.call(-30, 0, 0),
		"shoulder_l": V.call(100, 0, 4), "elbow_l": V.call(70, 0, 0),
		"leg_r": V.call(62, 0, 4), "knee_r": V.call(-88, 0, 0), "foot_r": V.call(25, 0, 0),
		"leg_l": V.call(12, 0, -4), "knee_l": V.call(-22, 0, 0), "foot_l": V.call(15, 0, 0),
	}
	var rung_b := rung_a.duplicate()
	rung_b["shoulder_r"] = V.call(100, 0, -4)
	rung_b["elbow_r"] = V.call(70, 0, 0)
	rung_b["shoulder_l"] = V.call(150, 0, 4)
	rung_b["elbow_l"] = V.call(40, 0, 0)
	rung_b["leg_r"] = V.call(12, 0, 4)
	rung_b["knee_r"] = V.call(-22, 0, 0)
	rung_b["foot_r"] = V.call(15, 0, 0)
	rung_b["leg_l"] = V.call(62, 0, -4)
	rung_b["knee_l"] = V.call(-88, 0, 0)
	rung_b["foot_l"] = V.call(25, 0, 0)
	var ladder := {}
	for key: String in rung_a:
		ladder[key] = [[0.0, rung_a[key]], [0.5, rung_b[key]]]
	_anim(lib, "ladder_climb", 1.0, true, ladder, rest)

	_anim(lib, "death", 1.2, false, {
		"hips@pos": [[0.0, V.call(0, 0.92, 0)], [0.3, V.call(0, 0.62, 0)], [0.7, V.call(0, 0.2, 0.1)], [1.2, V.call(0, 0.18, 0.1)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.3, V.call(0, 0, 0)], [0.7, V.call(82, 0, 0)], [1.2, V.call(84, 0, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.3, V.call(-25, 0, 0)], [0.7, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.3, V.call(-20, 0, 0)], [0.7, V.call(10, 20, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.3, V.call(70, 0, 3)], [0.7, V.call(15, 0, 6)], [1.2, V.call(10, 0, 8)]],
		"knee_r": [[0.0, V.call(0, 0, 0)], [0.3, V.call(-120, 0, 0)], [0.7, V.call(-30, 0, 0)], [1.2, V.call(-20, 0, 0)]],
		"leg_l": [[0.0, V.call(0, 0, -3)], [0.3, V.call(70, 0, -3)], [0.7, V.call(5, 0, -6)], [1.2, V.call(0, 0, -8)]],
		"knee_l": [[0.0, V.call(0, 0, 0)], [0.3, V.call(-120, 0, 0)], [0.7, V.call(-15, 0, 0)], [1.2, V.call(-10, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.3, V.call(-20, 0, 25)], [0.7, V.call(0, 0, 80)], [1.2, V.call(0, 0, 85)]],
		"elbow_r": [[0.0, elbow_r], [0.7, V.call(15, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l], [0.3, V.call(-20, 0, -25)], [0.7, V.call(0, 0, -80)], [1.2, V.call(0, 0, -85)]],
		"elbow_l": [[0.0, elbow_l], [0.7, V.call(15, 0, 0)]],
	}, rest)
	# Asleep on his back (the model lies along its +Z: turn it to fit the
	# bed), breathing slowly, head rolled a little to one side.
	var lie := {
		"hips@pos": [[0.0, V.call(0, 0.13, 0)]],
		"hips": [[0.0, V.call(88, 0, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [1.5, V.call(-3, 0, 0)]],
		"head": [[0.0, V.call(4, 18, 0)], [1.5, V.call(2, 20, 0)]],
		"shoulder_r": [[0.0, V.call(8, 0, 8)]], "elbow_r": [[0.0, V.call(20, 0, 0)]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(30, 0, -10)]], "elbow_l": [[0.0, V.call(70, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(2, 0, -4)]],
		"knee_r": [[0.0, V.call(-4, 0, 0)]], "knee_l": [[0.0, V.call(-10, 0, 0)]],
		"foot_r": [[0.0, V.call(30, 0, 0)]], "foot_l": [[0.0, V.call(30, 0, 0)]],
	}
	_anim(lib, "sleep", 3.0, true, lie, rest)
	# Waking: he sits up with his legs out along the bed, stretches both arms
	# over his head with a big yawn, then rubs his eyes.
	_anim(lib, "wake", 3.0, false, {
		"hips@pos": [[0.0, V.call(0, 0.13, 0)], [0.7, V.call(0, 0.12, 0.05)], [3.0, V.call(0, 0.12, 0.05)]],
		"hips": [[0.0, V.call(88, 0, 0)], [0.7, V.call(2, 0, 0)], [3.0, V.call(0, 0, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [0.7, V.call(8, 0, 0)], [1.5, V.call(-12, 0, 0)], [2.2, V.call(6, 0, 0)], [3.0, V.call(4, 0, 0)]],
		"head": [[0.0, V.call(4, 18, 0)], [0.7, V.call(-6, 0, 0)], [1.5, V.call(24, 0, 0)], [2.2, V.call(-12, 0, 0)], [3.0, V.call(-4, -10, 0)]],
		"shoulder_r": [[0.0, V.call(8, 0, 8)], [0.7, V.call(20, 0, 12)], [1.2, V.call(165, 0, 18)], [1.8, V.call(170, 0, 22)], [2.3, V.call(60, 25, 0)], [3.0, V.call(25, 0, 12)]],
		"elbow_r": [[0.0, V.call(20, 0, 0)], [1.2, V.call(20, 0, 0)], [2.3, V.call(130, 0, 0)], [3.0, V.call(30, 0, 0)]],
		"hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(30, 0, -10)], [0.7, V.call(20, 0, -12)], [1.2, V.call(165, 0, -18)], [1.8, V.call(170, 0, -22)], [2.3, V.call(25, 0, -12)]],
		"elbow_l": [[0.0, V.call(70, 0, 0)], [1.2, V.call(20, 0, 0)], [2.3, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)], [0.7, V.call(86, 0, 4)], [3.0, V.call(86, 0, 4)]],
		"leg_l": [[0.0, V.call(2, 0, -4)], [0.7, V.call(84, 0, -4)], [3.0, V.call(84, 0, -4)]],
		"knee_r": [[0.0, V.call(-4, 0, 0)], [0.7, V.call(-6, 0, 0)]], "knee_l": [[0.0, V.call(-10, 0, 0)], [0.7, V.call(-12, 0, 0)]],
		"foot_r": [[0.0, V.call(30, 0, 0)]], "foot_l": [[0.0, V.call(30, 0, 0)]],
	}, rest)


## Builds an animation from whole poses: [[time, {joint: euler, "hips@pos": Vector3}], ...].
## A joint missing from a pose holds the value of `base` (the stance the move
## starts from and returns to), so every pose is complete.
func _pose_anim(lib: AnimationLibrary, anim_name: String, length: float, poses: Array, base: Dictionary, rest: Dictionary, loop := false) -> void:
	var data := {}
	var joints := {}
	for p in poses:
		for j in (p[1] as Dictionary):
			joints[j] = true
	for j in base:
		joints[j] = true
	for j in joints:
		var keys: Array = []
		for p in poses:
			var pose: Dictionary = p[1]
			keys.append([p[0], pose.get(j, base.get(j, Vector3(0, 0.92, 0) if j == "hips@pos" else Vector3.ZERO))])
		data[j] = keys
	_anim(lib, anim_name, length, loop, data, rest)


## The sword (Beta 1.6.0), after OoT's func_80837818: which cut comes out
## depends on the stick (in the hero's own frame) and on Z-targeting, and the
## third cut of the same kind in a row is its finisher (unk_845 >= 3, the
## *_kiru_finsh animations):
##   slash_left   PLAYER_MWA_RIGHT_SLASH (Lside_kiru): the forehand, right to
##                left (standing still, or the stick to the left or back)
##   slash_right  PLAYER_MWA_LEFT_SLASH (Rside_kiru): the backhand, left to
##                right (the stick to the right)
##   slash_down   PLAYER_MWA_FORWARD_SLASH (normal_kiru): a diagonal chop from
##                high on the right (running, or Z-targeting with the stick still)
##   stab         PLAYER_MWA_STAB (pierce_kiru): the thrust (Z + stick forward)
## and each one's "_fin" finisher. The hero is right-handed, so OoT's left and
## right are mirrored. In every cut the blade leads with its edge: through the
## horizontal ones the forearm rolls a quarter turn (hand_r Y, round the
## forearm) so the flat lies level, and the chops keep it upright. The timings
## match PlayerCombat.SWINGS.
func _sword_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var ready := {
		"hips@pos": V.call(0, 0.91, 0), "torso": V.call(-5, 0, 0), "head": V.call(0, 0, 0),
		"shoulder_r": V.call(10, 0, 8), "elbow_r": V.call(35, 0, 0), "hand_r": V.call(-20, 0, 0),
		"shoulder_l": V.call(5, 0, -10), "elbow_l": V.call(20, 0, 0),
		"leg_r": V.call(0, 0, 3), "knee_r": V.call(0, 0, 0), "foot_r": V.call(0, 0, 0),
		"leg_l": V.call(0, 0, -3), "knee_l": V.call(0, 0, 0), "foot_l": V.call(0, 0, 0),
	}
	# The fighting stance through a cut: the left foot forward, knees bent,
	# the shield held in front of the chest.
	var lunge := {
		"hips@pos": V.call(0, 0.85, -0.05),
		"leg_l": V.call(32, 0, -4), "knee_l": V.call(-42, 0, 0), "foot_l": V.call(10, 0, 0),
		"leg_r": V.call(-22, 0, 5), "knee_r": V.call(-16, 0, 0), "foot_r": V.call(32, 0, 0),
		"shoulder_l": V.call(38, 18, -22), "elbow_l": V.call(78, 0, 0),
	}
	var set_ := func(a: Dictionary, b: Dictionary) -> Dictionary:
		var c := a.duplicate()
		c.merge(b, true)
		return c

	# Horizontal cuts. `d` = -1 for the forehand (right to left), +1 for the
	# backhand; the roll is the same both ways, since the blade has two edges.
	for spec in [["slash_left", -1.0, false], ["slash_right", 1.0, false], ["slash_left_fin", -1.0, true], ["slash_right_fin", 1.0, true]]:
		var n: String = spec[0]
		var d: float = spec[1]
		var fin: bool = spec[2]
		var big := 1.35 if fin else 1.0
		# Cocked: the blade drawn back to the side it starts from, the body
		# wound up away from the cut, the forearm already rolled.
		var cock: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.88, 0.02),
			"leg_l": V.call(14, 0, -4), "knee_l": V.call(-24, 0, 0),
			"leg_r": V.call(-8, 0, 5), "knee_r": V.call(-20, 0, 0),
			"torso": V.call(-4, 30 * d * big, 0), "head": V.call(0, -22 * d, 0),
			"shoulder_r": (V.call(62, -82 * big, 14) if d < 0 else V.call(48, 62, -6)),
			"elbow_r": (V.call(58, 0, 0) if d < 0 else V.call(96, 0, 0)),
			"hand_r": (V.call(-58, 90, 0) if d < 0 else V.call(-62, 90, 0)),
		})
		# Mid-cut: the arm straight out in front, the blade an extension of it.
		var mid: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.84, -0.06 * big),
			"torso": V.call(-10, 4 * d, 0), "head": V.call(0, -4 * d, 0),
			"shoulder_r": V.call(84, 8 * d, 2), "elbow_r": V.call(8, 0, 0), "hand_r": V.call(-82, 90, 0),
		})
		# Follow-through: carried round past the far side, the body unwound.
		var follow: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.84, -0.07 * big),
			"torso": V.call(-12, -34 * d * big, 0), "head": V.call(0, 22 * d, 0),
			"shoulder_r": (V.call(78, 78 * big, -8) if d < 0 else V.call(76, -80 * big, 16)),
			"elbow_r": V.call(18, 0, 0), "hand_r": V.call(-76, 90, 0),
		})
		var settle: Dictionary = set_.call(follow, {
			"shoulder_r": (V.call(66, 70 * big, -6) if d < 0 else V.call(64, -72 * big, 18)),
			"elbow_r": V.call(30, 0, 0), "hand_r": V.call(-62, 70, 0),
			"torso": V.call(-10, -28 * d * big, 0),
		})
		if fin:
			# The finisher winds up further, steps through and sweeps wider.
			var step: Dictionary = set_.call(mid, {"hips@pos": V.call(0, 0.8, -0.16), "leg_l": V.call(48, 0, -4), "knee_l": V.call(-60, 0, 0),
				"leg_r": V.call(-34, 0, 6), "knee_r": V.call(-12, 0, 0), "foot_r": V.call(40, 0, 0)})
			follow["hips@pos"] = V.call(0, 0.8, -0.18)
			settle["hips@pos"] = V.call(0, 0.81, -0.18)
			_pose_anim(lib, n, 0.56, [[0.0, ready], [0.1, cock], [0.16, step], [0.24, follow], [0.36, settle], [0.56, ready]], ready, rest)
		else:
			_pose_anim(lib, n, 0.42, [[0.0, ready], [0.06, cock], [0.12, mid], [0.19, follow], [0.27, settle], [0.42, ready]], ready, rest)

	# The diagonal chop: up over the right shoulder, down across to the left.
	for spec in [["slash_down", false], ["slash_down_fin", true]]:
		var n: String = spec[0]
		var fin: bool = spec[1]
		var up: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.94 if fin else 0.9, 0.03),
			"leg_l": V.call(16, 0, -4), "knee_l": V.call(-20, 0, 0), "leg_r": V.call(-6, 0, 5), "knee_r": V.call(-10, 0, 0),
			"torso": V.call(10 if fin else 6, -14, 0), "head": V.call(-8, 10, 0),
			"shoulder_r": V.call(172, -18, 16), "elbow_r": V.call(78, 0, 0), "hand_r": V.call(-34, 0, 0),
			"shoulder_l": V.call(60, 10, -30),
		})
		var mid: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.84, -0.06),
			"torso": V.call(-10, -4, 0), "head": V.call(4, 2, 0),
			"shoulder_r": V.call(118, 0, 8), "elbow_r": V.call(14, 0, 0), "hand_r": V.call(-62, 0, 0),
		})
		var down: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.7 if fin else 0.8, -0.1 if fin else -0.07),
			"leg_l": V.call(58 if fin else 46, 0, -4), "knee_l": V.call(-82 if fin else -62, 0, 0),
			"leg_r": V.call(-26, 0, 6), "knee_r": V.call(-44 if fin else -24, 0, 0), "foot_r": V.call(44, 0, 0),
			"torso": V.call(-34 if fin else -24, 16, 0), "head": V.call(18, -10, 0),
			"shoulder_r": V.call(46, 16, 2), "elbow_r": V.call(4, 0, 0), "hand_r": V.call(-84, 0, 0),
		})
		var hold: Dictionary = set_.call(down, {"shoulder_r": V.call(42, 18, 2), "elbow_r": V.call(12, 0, 0), "hand_r": V.call(-74, 0, 0)})
		if fin:
			_pose_anim(lib, n, 0.6, [[0.0, ready], [0.14, up], [0.2, mid], [0.25, down], [0.4, hold], [0.6, ready]], ready, rest)
		else:
			_pose_anim(lib, n, 0.42, [[0.0, ready], [0.07, up], [0.12, mid], [0.17, down], [0.27, hold], [0.42, ready]], ready, rest)

	# The thrust: the blade drawn back level at the hip, then driven straight
	# out with the right shoulder turned in behind it.
	for spec in [["stab", false], ["stab_fin", true]]:
		var n: String = spec[0]
		var fin: bool = spec[1]
		var draw: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.86, 0.04),
			"leg_l": V.call(18, 0, -4), "knee_l": V.call(-30, 0, 0), "leg_r": V.call(-10, 0, 5), "knee_r": V.call(-22, 0, 0),
			"torso": V.call(-6, -24, 0), "head": V.call(0, 20, 0),
			"shoulder_r": V.call(8, -14, 22), "elbow_r": V.call(104, 0, 0), "hand_r": V.call(-88, 90, 0),
		})
		var out: Dictionary = set_.call(lunge, {
			"hips@pos": V.call(0, 0.76 if fin else 0.82, -0.22 if fin else -0.12),
			"leg_l": V.call(56 if fin else 44, 0, -4), "knee_l": V.call(-74 if fin else -58, 0, 0),
			"leg_r": V.call(-36 if fin else -30, 0, 6), "knee_r": V.call(-8, 0, 0), "foot_r": V.call(46, 0, 0),
			"torso": V.call(-14, 22, 0), "head": V.call(2, -18, 0),
			"shoulder_r": V.call(86, 14, 2), "elbow_r": V.call(0, 0, 0), "hand_r": V.call(-90, 90, 0),
		})
		if fin:
			var hold: Dictionary = set_.call(out, {"shoulder_r": V.call(84, 12, 2), "elbow_r": V.call(6, 0, 0)})
			_pose_anim(lib, n, 0.52, [[0.0, ready], [0.09, draw], [0.16, out], [0.32, hold], [0.52, ready]], ready, rest)
		else:
			var hold: Dictionary = set_.call(out, {"shoulder_r": V.call(80, 10, 4), "elbow_r": V.call(12, 0, 0)})
			_pose_anim(lib, n, 0.36, [[0.0, ready], [0.05, draw], [0.11, out], [0.2, hold], [0.36, ready]], ready, rest)

	# The old names (title attract scene, the dark double) play the two cuts.
	lib.add_animation("attack_1", lib.get_animation("slash_left"))
	lib.add_animation("attack_2", lib.get_animation("slash_right"))


# --- Mira (Mirror Lake) -------------------------------------------------------
#
# A young woman who lives by the lake: adult proportions at 1.68 m (shorter and
# slighter than the hero), a long teal dress with a cream apron, white puffed
# sleeves, auburn hair in a high ponytail tied with a red ribbon. The face is
# painted (gen_media.gd _face_mira): big green eyes, a stubborn little frown
# and a permanent blush.

func _build_mira() -> void:
	var SKIN := _c("f0c8a8")
	var SKIN_D := _c("d8a888")
	var DRESS := _c("2e7d7a")
	var DRESS_L := _c("3a9894")
	var DRESS_D := _c("235f5d")
	var APRON := _c("ece2c8")
	var APRON_D := _c("d4c8a8")
	var BLOUSE := _c("f4f0e6")
	var BLOUSE_D := _c("dcd6c8")
	var HAIR := _c("a4482a")
	var HAIR_D := _c("7a321c")
	var HAIR_L := _c("bc5a34")
	var RIBBON := _c("e0405a")
	var RIBBON_D := _c("b02a40")
	var STOCKING := _c("3a3040")
	var SHOE := _c("5a3a28")
	var SHOE_D := _c("3e2818")
	var WHITE := Color.WHITE

	_root = Node3D.new()
	_root.name = "MiraModel"
	_paths = {}
	var root := _root

	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.84, 0), func(p: Parts) -> void:
		var k := p.k()
		# Long skirt flaring from the waist to just above the ankles.
		k.loft([
			[-0.73, 0.27, 0.245, DRESS_D], [-0.69, 0.285, 0.26, DRESS_D], [-0.5, 0.255, 0.23, DRESS],
			[-0.25, 0.205, 0.18, DRESS], [-0.05, 0.16, 0.135, DRESS_L], [0.06, 0.13, 0.105, DRESS],
		], 12)
		# Apron hanging from the waist, leaning out with the skirt.
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(11)), Vector3(0, -0.24, -0.19)))
		h.box(Vector3.ZERO, Vector3(0.27, 0.62, 0.012), APRON)
		h.box(Vector3(0, -0.3, -0.004), Vector3(0.27, 0.03, 0.014), APRON_D)
		h.pop()
		# Apron strings tied in a bow at the back.
		k.loft([[0.02, 0.137, 0.112, APRON], [0.06, 0.133, 0.108, APRON]], 12)
		h.box(Vector3(0.05, 0.04, 0.12), Vector3(0.08, 0.05, 0.02), APRON)
		h.box(Vector3(-0.05, 0.04, 0.12), Vector3(0.08, 0.05, 0.02), APRON)
		h.box(Vector3(0.03, -0.06, 0.125), Vector3(0.03, 0.14, 0.01), APRON_D)
		h.box(Vector3(-0.03, -0.06, 0.125), Vector3(0.03, 0.14, 0.01), APRON_D)
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.07, 0), func(p: Parts) -> void:
		var k := p.k()
		# Fitted bodice, narrow waist, softly rounded chest, white collar.
		k.loft([
			[0.0, 0.125, 0.1, DRESS_D], [0.1, 0.13, 0.102, DRESS], [0.19, 0.15, 0.118, DRESS_L, Vector2(0, -0.008)],
			[0.26, 0.152, 0.108, DRESS, Vector2(0, -0.004)], [0.31, 0.125, 0.092, BLOUSE],
			[0.35, 0.075, 0.065, BLOUSE_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# Apron bib and straps over the shoulders.
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-6)), Vector3(0, 0.15, -0.112)))
		h.box(Vector3.ZERO, Vector3(0.17, 0.2, 0.01), APRON)
		h.pop()
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(8 * sx)), Vector3(0.075 * sx, 0.27, 0.0)))
			h.box(Vector3(0, 0, -0.105), Vector3(0.03, 0.06, 0.01), APRON)
			h.box(Vector3(0, 0.02, 0), Vector3(0.03, 0.01, 0.2), APRON)
			h.box(Vector3(0, -0.1, 0.1), Vector3(0.03, 0.2, 0.01), APRON)
			h.pop()
	)
	_joint(torso, "head", "Head", Vector3(0, 0.4, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.08, 0.05, 0.048, SKIN_D], [0.0, 0.052, 0.05, SKIN_D], [0.04, 0.056, 0.056, SKIN]], 6, false)
		# Head wrap: nine evenly spaced rings so the painted face lands right.
		var f := p.k("face_mira")
		f.loft([
			[-0.03, 0.058, 0.054, WHITE, Vector2(0, -0.064)],
			[0.015, 0.094, 0.086, WHITE, Vector2(0, -0.042)],
			[0.06, 0.111, 0.104, WHITE, Vector2(0, -0.024)],
			[0.105, 0.117, 0.114, WHITE, Vector2(0, -0.012)],
			[0.15, 0.119, 0.119, WHITE, Vector2(0, -0.004)],
			[0.195, 0.119, 0.122, WHITE, Vector2(0, 0.0)],
			[0.24, 0.114, 0.122, WHITE, Vector2(0, 0.005)],
			[0.285, 0.092, 0.102, WHITE, Vector2(0, 0.01)],
			[0.33, 0.0, 0.0, WHITE, Vector2(0, 0.014)],
		], 10)
		# Small nose.
		k.tri_vc([Vector3(-0.016, 0.13, -0.118), Vector3(0.016, 0.13, -0.118), Vector3(0, 0.135, -0.142)], [SKIN_D, SKIN_D, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		k.tri_vc([Vector3(-0.016, 0.13, -0.118), Vector3(0, 0.135, -0.142), Vector3(0, 0.18, -0.122)], [SKIN_D, SKIN, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		k.tri_vc([Vector3(0.016, 0.13, -0.118), Vector3(0, 0.18, -0.122), Vector3(0, 0.135, -0.142)], [SKIN_D, SKIN, SKIN], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		# Hair: a shell over the back and top of the head (set back, so the face
		# stays clear), side locks framing the cheeks, and the high ponytail.
		k.loft([
			[0.03, 0.098, 0.098, HAIR_D, Vector2(0, 0.034)], [0.11, 0.128, 0.128, HAIR, Vector2(0, 0.028)],
			[0.19, 0.131, 0.134, HAIR_L, Vector2(0, 0.022)], [0.26, 0.124, 0.13, HAIR, Vector2(0, 0.016)],
			[0.31, 0.1, 0.11, HAIR, Vector2(0, 0.01)], [0.35, 0.0, 0.0, HAIR_L, Vector2(0, 0.004)],
		], 10)
		for sx in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-6 * sx)), Vector3(0.108 * sx, 0.0, -0.045)))
			k.loft([[-0.02, 0.0, 0.0, HAIR_D], [0.02, 0.018, 0.02, HAIR], [0.16, 0.026, 0.03, HAIR], [0.25, 0.022, 0.03, HAIR_L]], 5)
			k.pop()
		k.push(_aim(Vector3(0, -1, 0.3), Vector3(0, 0.27, 0.12)))
		k.loft([
			[0.0, 0.05, 0.05, HAIR], [0.07, 0.062, 0.055, HAIR_L], [0.22, 0.058, 0.05, HAIR],
			[0.38, 0.04, 0.035, HAIR_D], [0.47, 0.0, 0.0, HAIR_D],
		], 7)
		k.pop()
		# Ribbon tied round the ponytail: two loops and two tails.
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(28 * sx)), Vector3(0.05 * sx, 0.29, 0.14)))
			h.box(Vector3.ZERO, Vector3(0.08, 0.045, 0.02), RIBBON)
			h.pop()
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-14 * sx)), Vector3(0.025 * sx, 0.23, 0.15)))
			h.box(Vector3.ZERO, Vector3(0.025, 0.09, 0.01), RIBBON_D)
			h.pop()
		h.box(Vector3(0, 0.285, 0.145), Vector3(0.035, 0.035, 0.03), RIBBON_D)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.165 * side, 0.3, 0), func(p: Parts) -> void:
			# Puffed white sleeve, then the slim bare upper arm.
			p.k().loft([
				[0.06, 0.0, 0.0, BLOUSE], [0.045, 0.06, 0.06, BLOUSE], [-0.03, 0.075, 0.075, BLOUSE],
				[-0.1, 0.058, 0.058, BLOUSE_D], [-0.11, 0.04, 0.04, SKIN], [-0.22, 0.037, 0.037, SKIN],
				[-0.25, 0.0, 0.0, SKIN_D],
			], 7)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.24, 0), func(p: Parts) -> void:
			p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.12, 0.032, 0.033, SKIN], [-0.2, 0.026, 0.026, SKIN_D], [-0.215, 0.0, 0.0, SKIN_D]], 6)
		)
		_joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.21, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.01, 0.024, 0.024, SKIN], [-0.03, 0.034, 0.044, SKIN], [-0.075, 0.03, 0.04, SKIN], [-0.095, 0.0, 0.0, SKIN_D]], 6)
			k.push(_aim(Vector3(0, -0.6, -1), Vector3(-0.015 * side, -0.03, -0.03)))
			k.loft([[0.0, 0.014, 0.014, SKIN], [0.035, 0.0, 0.0, SKIN]], 5)
			k.pop()
		)
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.08 * side, -0.03, 0), func(p: Parts) -> void:
			p.k().loft([[0.05, 0.0, 0.0, STOCKING], [0.03, 0.065, 0.07, STOCKING], [-0.18, 0.058, 0.062, STOCKING], [-0.36, 0.045, 0.05, STOCKING], [-0.4, 0.0, 0.0, STOCKING]], 7)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.36, 0), func(p: Parts) -> void:
			p.k().loft([[0.03, 0.0, 0.0, STOCKING], [0.01, 0.044, 0.048, STOCKING], [-0.2, 0.036, 0.04, STOCKING], [-0.33, 0.03, 0.034, STOCKING], [-0.35, 0.0, 0.0, STOCKING]], 7)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.34, 0), func(p: Parts) -> void:
			# Little brown shoes.
			var k := p.k()
			k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			k.loft([
				[-0.06, 0.036, 0.045, SHOE_D, Vector2(0, -0.075)], [-0.035, 0.044, 0.06, SHOE, Vector2(0, -0.065)],
				[0.06, 0.042, 0.05, SHOE, Vector2(0, -0.07)], [0.115, 0.03, 0.03, SHOE_D, Vector2(0, -0.085)],
				[0.13, 0.0, 0.0, SHOE_D, Vector2(0, -0.09)],
			], 7)
			k.pop()
		)

	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.84, 0)}
	_mira_anims(lib, rest)
	_finish_character(root, lib)
	_save_scene(root, "mira.tscn")


func _mira_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	# Arms folded across the chest: upper arms forward and in, forearms turned
	# across the body by twisting the upper arm.
	var fold_r: Vector3 = V.call(22, 74, -6)
	var fold_l: Vector3 = V.call(24, -74, 6)
	var fold_elbow: Vector3 = V.call(96, 0, 0)

	_anim(lib, "RESET", 0.1, false, {}, rest)

	_anim(lib, "idle", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.832, 0)]],
		"hips": [[0.0, V.call(0, 0, 2)], [1.2, V.call(0, 0, -1)]],
		"torso": [[0.0, V.call(1, 0, -2)], [1.2, V.call(2, 0, 1)]],
		"head": [[0.0, V.call(4, 6, 3)], [1.2, V.call(2, 4, 1)]],
		"shoulder_r": [[0.0, fold_r], [1.2, fold_r + V.call(3, 0, 0)]], "elbow_r": [[0.0, fold_elbow]],
		"shoulder_l": [[0.0, fold_l], [1.2, fold_l + V.call(3, 0, 0)]], "elbow_l": [[0.0, fold_elbow + V.call(4, 0, 0)]],
		"hand_r": [[0.0, V.call(0, 0, 0)]], "hand_l": [[0.0, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(2, 0, 3)]], "leg_l": [[0.0, V.call(-3, 0, -2)]],
		"knee_l": [[0.0, V.call(-8, 0, 0)]], "foot_l": [[0.0, V.call(6, 0, 0)]],
	}, rest)

	# Talking: right hand on the hip, the left one making her point.
	_anim(lib, "talk", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"hips": [[0.0, V.call(0, 0, -3)]],
		"torso": [[0.0, V.call(0, 4, 2)], [0.8, V.call(-2, 2, 2)]],
		"head": [[0.0, V.call(0, 0, -4)], [0.4, V.call(-6, 0, -2)], [0.8, V.call(2, -4, -5)], [1.2, V.call(-4, 0, -3)]],
		"shoulder_r": [[0.0, V.call(-15, 0, 32)]], "elbow_r": [[0.0, V.call(105, 0, 0)]], "hand_r": [[0.0, V.call(-10, 0, 20)]],
		"shoulder_l": [[0.0, V.call(45, -15, -12)], [0.4, V.call(65, -25, -18)], [0.8, V.call(40, -10, -10)], [1.2, V.call(60, -20, -16)]],
		"elbow_l": [[0.0, V.call(70, 0, 0)], [0.4, V.call(45, 0, 0)], [0.8, V.call(80, 0, 0)], [1.2, V.call(50, 0, 0)]],
		"hand_l": [[0.0, V.call(-10, 0, 0)], [0.4, V.call(-30, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 4)]], "leg_l": [[0.0, V.call(4, 0, -2)]], "knee_l": [[0.0, V.call(-6, 0, 0)]],
	}, rest)

	# Hmph: arms folded tight, chin up, head turned pointedly away.
	_anim(lib, "huff", 2.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"hips": [[0.0, V.call(0, 6, 2)]],
		"torso": [[0.0, V.call(3, -12, 0)], [1.0, V.call(4, -14, 0)]],
		"head": [[0.0, V.call(12, 52, 4)], [1.0, V.call(14, 55, 5)]],
		"shoulder_r": [[0.0, fold_r + V.call(4, 4, 0)]], "elbow_r": [[0.0, fold_elbow + V.call(8, 0, 0)]],
		"shoulder_l": [[0.0, fold_l + V.call(4, -4, 0)]], "elbow_l": [[0.0, fold_elbow + V.call(10, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(-4, 0, -3)]],
	}, rest)

	# Flustered: hands clasped up by her chin, looking down, a nervous shake.
	_anim(lib, "fluster", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.2, V.call(0, 0.85, 0)], [0.4, V.call(0, 0.84, 0)], [0.6, V.call(0, 0.85, 0)]],
		"torso": [[0.0, V.call(-6, 0, 0)]],
		"head": [[0.0, V.call(-14, 10, 0)], [0.2, V.call(-12, -8, 0)], [0.4, V.call(-14, 10, 0)], [0.6, V.call(-12, -8, 0)]],
		"shoulder_r": [[0.0, V.call(55, 40, -8)]], "elbow_r": [[0.0, V.call(128, 0, 0)]], "hand_r": [[0.0, V.call(-20, 0, 0)]],
		"shoulder_l": [[0.0, V.call(55, -40, 8)]], "elbow_l": [[0.0, V.call(128, 0, 0)]], "hand_l": [[0.0, V.call(-20, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 2)]], "leg_l": [[0.0, V.call(6, 0, -1)]], "knee_l": [[0.0, V.call(-14, 0, 0)]], "foot_l": [[0.0, V.call(10, 0, 0)]],
	}, rest)

	# Sitting on the end of the dock at dusk (the title's Mirror Lake scene):
	# legs over the edge, feet swinging slowly in turn, her old rod in her
	# right hand. The model stands on the boards a little back from the edge.
	var dock: Vector3 = V.call(0, 0.1, 0.04)
	var rod_r := {"shoulder_r": [[0.0, V.call(36, 0, 8)]], "elbow_r": [[0.0, V.call(30, 0, 0)]], "hand_r": [[0.0, V.call(-30, 0, 0)]]}
	var rod_low := {"shoulder_r": [[0.0, V.call(22, 0, 8)]], "elbow_r": [[0.0, V.call(24, 0, 0)]], "hand_r": [[0.0, V.call(-22, 0, 0)]]}
	var sitting := func(extra: Dictionary) -> Dictionary:
		var d := {
			"hips@pos": [[0.0, dock]],
			"leg_r": [[0.0, V.call(82, 0, 3)]], "leg_l": [[0.0, V.call(82, 0, -3)]],
			"knee_r": [[0.0, V.call(-80, 0, 0)], [1.6, V.call(-62, 0, 0)]],
			"knee_l": [[0.0, V.call(-64, 0, 0)], [1.6, V.call(-82, 0, 0)]],
			"foot_r": [[0.0, V.call(-12, 0, 0)]], "foot_l": [[0.0, V.call(-8, 0, 0)]],
			"shoulder_l": [[0.0, V.call(30, -22, 4)]], "elbow_l": [[0.0, V.call(58, 0, 0)]], "hand_l": [[0.0, V.call(-10, 0, 0)]],
		}
		d.merge(rod_r, true)
		d.merge(extra, true)
		return d
	# Watching the float, a slow breath in the shoulders.
	_anim(lib, "sit_fish", 3.2, true, sitting.call({
		"torso": [[0.0, V.call(8, 0, 0)], [1.6, V.call(5, 0, 0)]],
		"head": [[0.0, V.call(-10, 0, 0)], [1.6, V.call(-8, 2, 0)]],
	}), rest)
	# Talking to the lake: head up a little, the free hand making her point.
	_anim(lib, "sit_talk", 3.2, true, sitting.call({
		"torso": [[0.0, V.call(4, 0, 0)]],
		"head": [[0.0, V.call(0, 0, -3)], [0.8, V.call(-4, -4, -1)], [1.6, V.call(2, 2, -4)], [2.4, V.call(-2, 0, -2)]],
		"shoulder_l": [[0.0, V.call(40, -20, -6)], [0.8, V.call(55, -28, -10)], [1.6, V.call(36, -16, -4)], [2.4, V.call(50, -24, -8)]],
		"elbow_l": [[0.0, V.call(70, 0, 0)], [0.8, V.call(48, 0, 0)], [1.6, V.call(76, 0, 0)], [2.4, V.call(52, 0, 0)]],
	}), rest)
	# A sigh: shoulders down, head bowed, the rod drooping.
	_anim(lib, "sit_sigh", 3.2, true, sitting.call({
		"torso": [[0.0, V.call(16, 0, 0)], [1.6, V.call(13, 0, 0)]],
		"head": [[0.0, V.call(-20, 6, 2)], [1.6, V.call(-17, 4, 1)]],
		"shoulder_r": rod_low.shoulder_r, "elbow_r": rod_low.elbow_r, "hand_r": rod_low.hand_r,
	}), rest)
	# Looking up at the sky, leaning back on her left hand.
	_anim(lib, "sit_look", 3.2, true, sitting.call({
		"torso": [[0.0, V.call(-10, 0, 0)], [1.6, V.call(-8, 0, 0)]],
		"head": [[0.0, V.call(26, -4, 0)], [1.6, V.call(24, -2, 0)]],
		"shoulder_l": [[0.0, V.call(-36, 0, 16)]], "elbow_l": [[0.0, V.call(6, 0, 0)]], "hand_l": [[0.0, V.call(30, 0, 0)]],
		"shoulder_r": rod_low.shoulder_r, "elbow_r": rod_low.elbow_r, "hand_r": rod_low.hand_r,
	}), rest)
	# A bite: the rod jerks up and she sits up straight (plays once).
	_anim(lib, "sit_tug", 0.7, false, sitting.call({
		"torso": [[0.0, V.call(8, 0, 0)], [0.15, V.call(-6, 0, 0)], [0.7, V.call(-2, 0, 0)]],
		"head": [[0.0, V.call(-10, 0, 0)], [0.15, V.call(6, 0, 0)], [0.7, V.call(2, 0, 0)]],
		"shoulder_r": [[0.0, V.call(36, 0, 8)], [0.15, V.call(95, 0, 8)], [0.7, V.call(80, 0, 8)]],
		"elbow_r": [[0.0, V.call(30, 0, 0)], [0.15, V.call(40, 0, 0)], [0.7, V.call(50, 0, 0)]],
		"shoulder_l": [[0.0, V.call(30, -22, 4)], [0.15, V.call(70, -10, 0)], [0.7, V.call(60, -14, 0)]],
	}), rest)
	# Holding the little fish up in her left hand to look at it.
	_anim(lib, "sit_hold", 2.0, true, sitting.call({
		"torso": [[0.0, V.call(0, 6, 0)]],
		"head": [[0.0, V.call(6, 14, 4)], [1.0, V.call(4, 18, 6)]],
		"shoulder_l": [[0.0, V.call(58, -20, 0)], [1.0, V.call(60, -18, 0)]], "elbow_l": [[0.0, V.call(52, 0, 0)]], "hand_l": [[0.0, V.call(-4, 0, 0)], [1.0, V.call(4, 0, 0)]],
		"shoulder_r": rod_low.shoulder_r, "elbow_r": rod_low.elbow_r, "hand_r": rod_low.hand_r,
	}), rest)
	# Letting it go: the left hand swings out low over the water (plays once).
	_anim(lib, "sit_toss", 0.8, false, sitting.call({
		"torso": [[0.0, V.call(0, 6, 0)], [0.35, V.call(12, 0, 0)], [0.8, V.call(8, 0, 0)]],
		"head": [[0.0, V.call(6, 14, 4)], [0.35, V.call(-14, 0, 0)], [0.8, V.call(-12, 0, 0)]],
		"shoulder_l": [[0.0, V.call(58, -20, 0)], [0.35, V.call(56, -6, 0)], [0.8, V.call(34, -18, 4)]],
		"elbow_l": [[0.0, V.call(52, 0, 0)], [0.35, V.call(14, 0, 0)], [0.8, V.call(50, 0, 0)]],
		"shoulder_r": rod_low.shoulder_r, "elbow_r": rod_low.elbow_r, "hand_r": rod_low.hand_r,
	}), rest)


# --- Pink's Armory: Pink, Aladriel and Idrith -----------------------------------------
#
# The three share Mira's skeleton and head layout (a painted face wrap, hips
# at 0.84 m) and are scaled for height. Each brings her own clothes and hair
# through the callables in `look`:
#   hips(p), torso(p), head(p), sleeve(p, side), forearm(p, side), hand(p, side),
#   thigh(p, side), shin(p, side), foot(p, side), extra(root) (props on joints).
# Aladriel and Idrith get a "Blush" (hidden until CharacterModel.set_blush).

func _build_woman(model_name: String, file: String, face: String, skin: Color, skin_d: Color, look: Dictionary, anims: Callable, height := 1.0) -> void:
	var WHITE := Color.WHITE
	_root = Node3D.new()
	_root.name = model_name
	_paths = {}
	var root := _root
	root.scale = Vector3.ONE * height
	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.84, 0), look.hips)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.07, 0), look.torso)
	var head := _joint(torso, "head", "Head", Vector3(0, 0.4, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.08, 0.05, 0.048, skin_d], [0.0, 0.052, 0.05, skin_d], [0.04, 0.056, 0.056, skin]], 6, false)
		var f := p.k(face)
		f.loft([
			[-0.03, 0.058, 0.054, WHITE, Vector2(0, -0.064)],
			[0.015, 0.094, 0.086, WHITE, Vector2(0, -0.042)],
			[0.06, 0.111, 0.104, WHITE, Vector2(0, -0.024)],
			[0.105, 0.117, 0.114, WHITE, Vector2(0, -0.012)],
			[0.15, 0.119, 0.119, WHITE, Vector2(0, -0.004)],
			[0.195, 0.119, 0.122, WHITE, Vector2(0, 0.0)],
			[0.24, 0.114, 0.122, WHITE, Vector2(0, 0.005)],
			[0.285, 0.092, 0.102, WHITE, Vector2(0, 0.01)],
			[0.33, 0.0, 0.0, WHITE, Vector2(0, 0.014)],
		], 10)
		k.tri_vc([Vector3(-0.016, 0.13, -0.118), Vector3(0.016, 0.13, -0.118), Vector3(0, 0.135, -0.142)], [skin_d, skin_d, skin], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		k.tri_vc([Vector3(-0.016, 0.13, -0.118), Vector3(0, 0.135, -0.142), Vector3(0, 0.18, -0.122)], [skin_d, skin, skin], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		k.tri_vc([Vector3(0.016, 0.13, -0.118), Vector3(0, 0.18, -0.122), Vector3(0, 0.135, -0.142)], [skin_d, skin, skin], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.15, -0.09))
		look.head.call(p)
	)
	if look.get("blush", false):
		# Rosy cheeks, shown while her sweetheart is being talked to.
		var bk := MeshKit.new(_seed)
		for sx in [-1.0, 1.0]:
			bk.push(_aim(Vector3(0.45 * sx, 0, -1), Vector3(0.058 * sx, 0.125, -0.096)))
			bk.push(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.55)), Vector3.ZERO))
			bk.prism(Vector3(0, 0.0, 0), 0.026, Vector3(0, 0.004, 0), 0.026, 8, Color.html("ff7a90"))
			bk.pop()
			bk.pop()
		var blush := _mesh_child(head, "Blush", bk.build(_mats.glow))
		blush.visible = false
		blush.set_meta("no_tint", true)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.165 * side, 0.3, 0), func(p: Parts) -> void: look.sleeve.call(p, side))
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.24, 0), func(p: Parts) -> void: look.forearm.call(p, side))
		_joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.21, 0), func(p: Parts) -> void: look.hand.call(p, side))
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.08 * side, -0.03, 0), func(p: Parts) -> void: look.thigh.call(p, side))
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.36, 0), func(p: Parts) -> void: look.shin.call(p, side))
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.34, 0), func(p: Parts) -> void: look.foot.call(p, side))
	if look.has("extra"):
		look.extra.call(root)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.84, 0)}
	anims.call(lib, rest)
	_finish_character(root, lib)
	_save_scene(root, file)


## A bare (or gloved) hand: a small fist and thumb.
func _lady_hand(p: Parts, side: float, col: Color, col_d: Color) -> void:
	var k := p.k()
	k.loft([[0.01, 0.024, 0.024, col], [-0.03, 0.034, 0.044, col], [-0.075, 0.03, 0.04, col], [-0.095, 0.0, 0.0, col_d]], 6)
	k.push(_aim(Vector3(0, -0.6, -1), Vector3(-0.015 * side, -0.03, -0.03)))
	k.loft([[0.0, 0.014, 0.014, col], [0.035, 0.0, 0.0, col]], 5)
	k.pop()


## A boot foot lofted forward from the heel.
func _lady_foot(p: Parts, col: Color, col_d: Color, length := 1.0) -> void:
	var k := p.k()
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.loft([
		[-0.06, 0.036, 0.045, col_d, Vector2(0, -0.075)], [-0.035, 0.044, 0.06, col, Vector2(0, -0.065)],
		[0.06 * length, 0.042, 0.05, col, Vector2(0, -0.07)], [0.115 * length, 0.03, 0.03, col_d, Vector2(0, -0.085)],
		[0.13 * length, 0.0, 0.0, col_d, Vector2(0, -0.09)],
	], 7)
	k.pop()


## Long straight hair hanging down the back from the crown (a flat-backed
## curtain that widens toward the ends) plus locks framing the face.
func _long_hair(k: MeshKit, hair: Color, hair_d: Color, hair_l: Color, length: float, width: float, lock_len: float) -> void:
	k.loft([
		[0.03, 0.098, 0.098, hair_d, Vector2(0, 0.034)], [0.11, 0.13, 0.13, hair, Vector2(0, 0.028)],
		[0.19, 0.133, 0.136, hair_l, Vector2(0, 0.022)], [0.26, 0.126, 0.132, hair, Vector2(0, 0.016)],
		[0.31, 0.1, 0.11, hair, Vector2(0, 0.01)], [0.35, 0.0, 0.0, hair_l, Vector2(0, 0.004)],
	], 10)
	k.loft([
		[-length, width * 1.05, 0.03, hair_d, Vector2(0, 0.11)], [-length * 0.6, width, 0.045, hair, Vector2(0, 0.105)],
		[-length * 0.25, width * 0.95, 0.055, hair_l, Vector2(0, 0.1)], [0.05, 0.115, 0.08, hair, Vector2(0, 0.07)],
		[0.2, 0.11, 0.07, hair, Vector2(0, 0.05)],
	], 8)
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-4 * sx)), Vector3(0.1 * sx, 0.0, -0.02)))
		k.loft([[-lock_len, 0.0, 0.0, hair_d], [-lock_len + 0.04, 0.018, 0.03, hair], [0.1, 0.026, 0.045, hair], [0.25, 0.024, 0.05, hair_l]], 6)
		k.pop()


func _build_armory_folk() -> void:
	_build_pink()
	_build_aladriel()
	_build_idrith()


# --- Pink ---------------------------------------------------------------------
#
# The armorer: warm brown skin, long cute pink hair to the waist with a star
# clip, a long yellow tunic belted at the waist, brown work gloves and boots,
# and a smith's hammer in her right hand.

func _build_pink() -> void:
	var SKIN := _c("7a4a32")
	var SKIN_D := _c("623a26")
	var TUNIC := _c("f2c832")
	var TUNIC_L := _c("ffd84a")
	var TUNIC_D := _c("d0a420")
	var BELT := _c("6a4028")
	var LEG := _c("5a3a24")
	var BOOT := _c("7a4a28")
	var BOOT_D := _c("5a341c")
	var GLOVE := _c("8a5a34")
	var HAIR := _c("f27ab8")
	var HAIR_D := _c("d0568f")
	var HAIR_L := _c("ff9ccb")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		# The tunic hangs long, to the middle of the shins, flaring a little.
		k.loft([
			[-0.62, 0.25, 0.23, TUNIC_D], [-0.58, 0.255, 0.235, TUNIC_D], [-0.35, 0.225, 0.2, TUNIC],
			[-0.1, 0.18, 0.15, TUNIC_L], [0.03, 0.14, 0.115, TUNIC], [0.07, 0.13, 0.105, TUNIC],
		], 12)
		k.loft([[0.0, 0.142, 0.117, BELT], [0.05, 0.136, 0.111, BELT]], 12)
		p.k("hard").box(Vector3(0, 0.025, -0.115), Vector3(0.05, 0.04, 0.012), _c("e8c050"))
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.104, TUNIC_D], [0.1, 0.135, 0.106, TUNIC], [0.19, 0.155, 0.122, TUNIC_L, Vector2(0, -0.008)],
			[0.26, 0.156, 0.112, TUNIC, Vector2(0, -0.004)], [0.31, 0.128, 0.094, TUNIC],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# Rounded neckline showing the collarbone.
		k.tri_vc([Vector3(-0.05, 0.32, -0.092), Vector3(0.05, 0.32, -0.092), Vector3(0, 0.27, -0.115)],
			[SKIN, SKIN, SKIN_D], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.25, 0))
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.6, 0.13, 0.2)
		# A little yellow star clip over her right ear.
		var h := p.k("hard")
		h.push(_aim(Vector3(1, 0.2, -0.2), Vector3(0.112, 0.22, -0.03)))
		for i in 5:
			var a := TAU * i / 5.0
			h.box(Vector3(cos(a) * 0.016, 0.0, sin(a) * 0.016), Vector3(0.022, 0.012, 0.022), _c("ffe040"))
		h.pop()
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, TUNIC], [0.045, 0.06, 0.06, TUNIC], [-0.03, 0.068, 0.068, TUNIC_L],
			[-0.16, 0.052, 0.052, TUNIC], [-0.2, 0.056, 0.056, TUNIC_D], [-0.21, 0.04, 0.04, SKIN],
			[-0.25, 0.0, 0.0, SKIN_D],
		], 7)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.036, 0.036, SKIN], [-0.11, 0.034, 0.035, SKIN],
			[-0.13, 0.042, 0.042, GLOVE], [-0.2, 0.034, 0.034, GLOVE], [-0.215, 0.0, 0.0, GLOVE]], 6)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, GLOVE, GLOVE.darkened(0.2))
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, LEG], [0.03, 0.068, 0.072, LEG], [-0.18, 0.06, 0.064, LEG], [-0.36, 0.047, 0.052, LEG], [-0.4, 0.0, 0.0, LEG]], 7)
	var _shin_part := func(p: Parts, _side: float) -> void:
		# Tall boots with a turned-down cuff below the knee.
		p.k().loft([[0.03, 0.0, 0.0, LEG], [0.01, 0.046, 0.05, LEG], [-0.05, 0.05, 0.054, BOOT],
			[-0.09, 0.052, 0.056, BOOT_D], [-0.1, 0.045, 0.049, BOOT], [-0.33, 0.036, 0.04, BOOT], [-0.35, 0.0, 0.0, BOOT_D]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT_D)
	var _extra_part := func(root: Node3D) -> void:
		# The smith's hammer, its handle along the fist's -Z like the hero's sword.
		_attach(root.get_node(_paths["hand_r"]), "Hammer", Vector3(0, -0.05, 0), func(p: Parts) -> void:
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			h.prism(Vector3(0, -0.08, 0), 0.018, Vector3(0, 0.3, 0), 0.016, 6, _c("7a5030"))
			h.box(Vector3(0, 0.33, 0), Vector3(0.06, 0.07, 0.17), _c("4a4a52"))
			h.box(Vector3(0, 0.33, 0.09), Vector3(0.068, 0.078, 0.02), _c("6a6a74"))
			h.box(Vector3(0, 0.33, -0.09), Vector3(0.068, 0.078, 0.02), _c("6a6a74"))
			h.pop()
		, "hammer")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part, "extra": _extra_part}
	_build_woman("PinkModel", "pink.tscn", "face_pink", SKIN, SKIN_D, look, _pink_anims)


func _pink_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Working the anvil: raise the hammer high, bring it down on the anvil in
	# front at 0.55 s (the Armorer script rings the anvil then), lift again.
	_anim(lib, "idle", 1.1, true, {
		"hips@pos": [[0.0, V.call(0, 0.83, 0)], [0.55, V.call(0, 0.81, 0)], [0.8, V.call(0, 0.83, 0)]],
		"hips": [[0.0, V.call(0, -10, 0)]],
		"torso": [[0.0, V.call(4, 6, 0)], [0.45, V.call(-2, 4, 0)], [0.55, V.call(-14, 2, 0)], [0.8, V.call(-6, 4, 0)]],
		"head": [[0.0, V.call(-10, -4, 0)], [0.55, V.call(-18, -4, 0)]],
		"shoulder_r": [[0.0, V.call(118, 0, -12)], [0.4, V.call(128, 0, -12)], [0.55, V.call(52, 0, -6)], [0.75, V.call(64, 0, -6)], [1.1, V.call(118, 0, -12)]],
		"elbow_r": [[0.0, V.call(35, 0, 0)], [0.4, V.call(40, 0, 0)], [0.55, V.call(15, 0, 0)], [0.75, V.call(25, 0, 0)], [1.1, V.call(35, 0, 0)]],
		"hand_r": [[0.0, V.call(25, 0, 0)], [0.4, V.call(35, 0, 0)], [0.55, V.call(-65, 0, 0)], [0.75, V.call(-45, 0, 0)], [1.1, V.call(25, 0, 0)]],
		"shoulder_l": [[0.0, V.call(42, -8, 8)]], "elbow_l": [[0.0, V.call(55, 0, 0)]], "hand_l": [[0.0, V.call(-20, 0, 0)]],
		"leg_r": [[0.0, V.call(-6, 0, 4)]], "leg_l": [[0.0, V.call(10, 0, -4)]], "knee_l": [[0.0, V.call(-10, 0, 0)]],
	}, rest)
	# Talking: hammer resting on her shoulder, the other hand chatting away.
	_anim(lib, "talk", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"hips": [[0.0, V.call(0, 0, 3)]],
		"torso": [[0.0, V.call(0, -3, -2)], [0.8, V.call(-2, -1, -2)]],
		"head": [[0.0, V.call(0, 0, 5)], [0.4, V.call(-5, 4, 3)], [0.8, V.call(2, -3, 6)], [1.2, V.call(-3, 0, 4)]],
		"shoulder_r": [[0.0, V.call(-10, 0, 14)]], "elbow_r": [[0.0, V.call(25, 0, 0)]], "hand_r": [[0.0, V.call(-75, 0, 0)]],
		"shoulder_l": [[0.0, V.call(45, 15, 12)], [0.4, V.call(62, 25, 18)], [0.8, V.call(40, 10, 10)], [1.2, V.call(58, 20, 16)]],
		"elbow_l": [[0.0, V.call(70, 0, 0)], [0.4, V.call(45, 0, 0)], [0.8, V.call(80, 0, 0)], [1.2, V.call(50, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(5, 0, -3)]], "knee_l": [[0.0, V.call(-8, 0, 0)]],
	}, rest)
	# Standing (the castle): hammer at her side, weight on one leg.
	_anim(lib, "stand", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.835, 0)]],
		"hips": [[0.0, V.call(0, 0, 3)]],
		"shoulder_r": [[0.0, V.call(6, 0, -6)]], "elbow_r": [[0.0, V.call(15, 0, 0)]], "hand_r": [[0.0, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(4, 0, 6)]], "elbow_l": [[0.0, V.call(12, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(5, 0, -3)]], "knee_l": [[0.0, V.call(-8, 0, 0)]],
	}, rest)
	# Worried: hands clasped to her chest, head down.
	_anim(lib, "worried", 1.8, true, {
		"head": [[0.0, V.call(-14, 0, 4)], [0.9, V.call(-10, 0, -4)]],
		"torso": [[0.0, V.call(-6, 0, 0)]],
		"shoulder_r": [[0.0, V.call(40, 30, -10)]], "elbow_r": [[0.0, V.call(110, 0, 0)]], "hand_r": [[0.0, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, -30, 10)]], "elbow_l": [[0.0, V.call(110, 0, 0)]],
	}, rest)
	_anim(lib, "walk", 0.9, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.225, V.call(0, 0.86, 0)], [0.45, V.call(0, 0.84, 0)], [0.675, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.45, V.call(24, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)], [0.45, V.call(-24, 0, 0)]],
		"knee_r": [[0.0, V.call(-8, 0, 0)], [0.225, V.call(-40, 0, 0)], [0.45, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.45, V.call(-8, 0, 0)], [0.675, V.call(-40, 0, 0)]],
		"shoulder_r": [[0.0, V.call(18, 0, -6)], [0.45, V.call(-18, 0, -6)]], "hand_r": [[0.0, V.call(-80, 0, 0)]],
		"shoulder_l": [[0.0, V.call(-18, 0, 6)], [0.45, V.call(18, 0, 6)]],
	}, rest)
	# Delighted: a little bounce, hammer raised.
	_anim(lib, "happy", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.3, V.call(0, 0.87, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)]],
		"head": [[0.0, V.call(8, 0, -6)], [0.3, V.call(8, 0, 6)]],
		"shoulder_r": [[0.0, V.call(160, 0, -20)]], "elbow_r": [[0.0, V.call(20, 0, 0)]],
		"shoulder_l": [[0.0, V.call(60, 0, 30)]], "elbow_l": [[0.0, V.call(90, 0, 0)]],
	}, rest)


# --- Aladriel -------------------------------------------------------------------
#
# Questlord of Ladhellin, a little tall: short messy brown hair with a pale
# streak, a gray swirled breastplate over a green tunic, a white pauldron on
# her left shoulder, the heart pendant Idrith made her on a black choker,
# brown gloves, dark shorts, white thigh-high socks and tall black boots.

func _build_aladriel() -> void:
	var SKIN := _c("fbeee4")
	var SKIN_D := _c("e6d2c4")
	var GREEN := _c("3e6a3a")
	var GREEN_L := _c("4e7e48")
	var GREEN_D := _c("2c4e2a")
	var PLATE := _c("b4b6bc")
	var PLATE_D := _c("8a8c94")
	var SHORTS := _c("3c3c40")
	var SOCK := _c("f2f0ee")
	var BOOT := _c("2c2c30")
	var BOOT_D := _c("1c1c20")
	var GLOVE := _c("6a3e24")
	var STRAP := _c("5a3820")
	var HAIR := _c("9a5530")
	var HAIR_D := _c("74391e")
	var HAIR_L := _c("c07a50")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([[-0.12, 0.13, 0.1, SHORTS], [-0.05, 0.15, 0.115, SHORTS], [0.06, 0.135, 0.105, SHORTS]], 10)
		# The tunic's hem: longer front and back panels over the shorts.
		k.loft([[-0.1, 0.17, 0.14, GREEN_D], [-0.06, 0.168, 0.136, GREEN], [0.04, 0.145, 0.115, GREEN], [0.08, 0.13, 0.105, GREEN_L]], 10)
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8)), Vector3(0, -0.12, -0.13)))
		h.box(Vector3.ZERO, Vector3(0.16, 0.16, 0.012), GREEN)
		h.pop()
		# Belt, buckle and the pouch on her right hip.
		k.loft([[0.0, 0.15, 0.12, STRAP], [0.04, 0.148, 0.118, STRAP]], 10)
		h.box(Vector3(0, 0.02, -0.12), Vector3(0.045, 0.035, 0.012), _c("e0c050"))
		h.box(Vector3(0.15, -0.05, 0.02), Vector3(0.05, 0.12, 0.09), STRAP)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.102, SKIN_D], [0.06, 0.128, 0.1, GREEN_D], [0.12, 0.138, 0.106, GREEN],
			[0.2, 0.156, 0.12, GREEN_L, Vector2(0, -0.006)], [0.27, 0.158, 0.112, GREEN], [0.31, 0.13, 0.094, GREEN],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# Bare midriff under the breastplate.
		k.loft([[0.0, 0.125, 0.098, SKIN], [0.07, 0.126, 0.099, SKIN]], 10)
		# The breastplate over the chest, with two raised swirls.
		var h := p.k("hard")
		h.loft([[0.12, 0.13, 0.03, PLATE_D, Vector2(0, -0.1)], [0.2, 0.15, 0.04, PLATE, Vector2(0, -0.108)], [0.29, 0.13, 0.03, PLATE, Vector2(0, -0.1)]], 8)
		for sx in [-1.0, 1.0]:
			for i in 6:
				var a := TAU * i / 6.0
				h.box(Vector3(0.06 * sx + cos(a) * 0.025, 0.21 + sin(a) * 0.025, -0.15), Vector3(0.012, 0.012, 0.01), PLATE_D.darkened(0.3))
		# The strap from her right shoulder across to the left hip.
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-30)), Vector3(0.0, 0.16, -0.152)))
		h.box(Vector3.ZERO, Vector3(0.03, 0.42, 0.01), STRAP)
		h.pop()
		# The choker and Idrith's pink heart pendant.
		k.loft([[0.355, 0.068, 0.06, _c("1a1a1e")], [0.375, 0.06, 0.054, _c("1a1a1e")]], 8)
		h.push(Transform3D(Basis(Vector3.BACK, PI / 4.0), Vector3(0, 0.31, -0.1)))
		h.box(Vector3.ZERO, Vector3(0.024, 0.024, 0.012), _c("f070a0"))
		h.pop()
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		# Short, messy hair: a cap with spikes sticking out back and sides.
		k.loft([
			[0.03, 0.105, 0.105, HAIR_D, Vector2(0, 0.03)], [0.11, 0.132, 0.132, HAIR, Vector2(0, 0.024)],
			[0.19, 0.136, 0.138, HAIR_L, Vector2(0, 0.018)], [0.26, 0.128, 0.134, HAIR, Vector2(0, 0.012)],
			[0.31, 0.104, 0.112, HAIR, Vector2(0, 0.008)], [0.355, 0.0, 0.0, HAIR_L, Vector2(0, 0.004)],
		], 10)
		var spikes := [[Vector3(-0.8, 0.1, 0.4), Vector3(-0.1, 0.16, 0.06)], [Vector3(0.8, 0.2, 0.3), Vector3(0.1, 0.18, 0.06)],
			[Vector3(-0.3, 0.3, 1), Vector3(-0.04, 0.2, 0.11)], [Vector3(0.4, 0.1, 1), Vector3(0.05, 0.12, 0.11)],
			[Vector3(-0.9, -0.5, 0.1), Vector3(-0.11, 0.06, -0.01)], [Vector3(0.9, -0.5, 0.1), Vector3(0.11, 0.06, -0.01)],
			[Vector3(-0.5, 0.8, 0.5), Vector3(-0.06, 0.29, 0.03)], [Vector3(0, -0.4, 1), Vector3(0.0, 0.05, 0.1)]]
		for s: Array in spikes:
			k.push(_aim(s[0], s[1]))
			k.loft([[0.0, 0.035, 0.03, HAIR], [0.08, 0.0, 0.0, HAIR_D]], 4)
			k.pop()
	var _sleeve_part := func(p: Parts, side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, GREEN], [0.045, 0.06, 0.06, GREEN], [-0.03, 0.07, 0.07, GREEN_L],
			[-0.1, 0.06, 0.06, GREEN_D], [-0.11, 0.04, 0.04, SKIN], [-0.22, 0.038, 0.038, SKIN], [-0.25, 0.0, 0.0, SKIN_D],
		], 7)
		if side < 0.0:
			# The big white pauldron on her left shoulder.
			var h := p.k("hard")
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-20)), Vector3(-0.03, 0.03, 0)))
			h.loft([[-0.06, 0.1, 0.09, _c("d8dade")], [0.02, 0.105, 0.095, _c("f0f2f4")], [0.06, 0.07, 0.07, _c("f0f2f4")], [0.08, 0.0, 0.0, _c("e0e2e6")]], 8)
			h.pop()
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.08, 0.033, 0.034, SKIN],
			[-0.1, 0.048, 0.05, GLOVE], [-0.2, 0.034, 0.034, GLOVE], [-0.215, 0.0, 0.0, GLOVE]], 6)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, GLOVE, GLOVE.darkened(0.2))
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, SHORTS], [0.03, 0.068, 0.072, SHORTS], [-0.07, 0.064, 0.068, SHORTS],
			[-0.08, 0.06, 0.064, SKIN], [-0.13, 0.058, 0.062, SKIN], [-0.14, 0.06, 0.064, SOCK],
			[-0.36, 0.047, 0.052, SOCK], [-0.4, 0.0, 0.0, SOCK]], 7)
		# The tall boot's pointed top over the knee.
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-8)), Vector3(0, -0.33, -0.05)))
		h.prism(Vector3(0, -0.03, 0), 0.03, Vector3(0, 0.07, 0), 0.0, 3, BOOT)
		h.pop()
	var _shin_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, BOOT], [0.04, 0.054, 0.058, BOOT], [-0.05, 0.05, 0.054, BOOT],
			[-0.25, 0.038, 0.042, BOOT], [-0.33, 0.034, 0.038, BOOT_D], [-0.35, 0.0, 0.0, BOOT_D]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT_D, 1.05)
	var look := {"blush": true, "hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part}
	_build_woman("AladrielModel", "aladriel.tscn", "face_aladriel", SKIN, SKIN_D, look, _seated_anims.bind(true), 1.06)


# --- Lothelye -------------------------------------------------------------------
#
# The Cosmic Deity, who dreamed Bunsriel. She only ever appears as a vision,
# floating: bright white hair falling past her knees, a gold circlet with a
# star over her brow, and a long goddess's gown of white and gold whose hem
# fades into the night sky, scattered with little gold stars. Wide bell
# sleeves, a gold sash with a star clasp, and a pale mantle on her shoulders.
# No legs are modeled: the gown reaches the floor and trails below it.

func _build_lothelye() -> void:
	var SKIN := _c("fbf0ea")
	var SKIN_D := _c("eadad2")
	var GOWN := _c("f4f2fa")
	var GOWN_L := _c("ffffff")
	var GOWN_D := _c("d8d4ea")
	var NIGHT := _c("3a3a8a")
	var NIGHT_D := _c("1e1e5a")
	var GOLD := _c("e8c060")
	var GOLD_L := _c("fff0a0")
	var MANTLE := _c("e6e0f6")
	var HAIR := _c("f4f4fa")
	var HAIR_D := _c("d4d4e6")
	var HAIR_L := _c("ffffff")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		# The gown: white at the waist, flaring to the floor, its hem fading
		# into a starry night blue.
		k.loft([
			[-0.92, 0.36, 0.34, NIGHT_D], [-0.84, 0.35, 0.33, NIGHT], [-0.66, 0.31, 0.29, GOWN_D.lerp(NIGHT, 0.5)],
			[-0.46, 0.26, 0.24, GOWN_D], [-0.22, 0.2, 0.17, GOWN], [-0.04, 0.155, 0.125, GOWN_L], [0.07, 0.13, 0.105, GOWN],
		], 14)
		# A gold border above the night of the hem.
		k.loft([[-0.62, 0.305, 0.285, GOLD], [-0.59, 0.3, 0.28, GOLD_L]], 14, false)
		# The sash, its star clasp, and the long ends falling in front.
		k.loft([[0.0, 0.142, 0.117, GOLD], [0.05, 0.136, 0.111, GOLD_L]], 12)
		var h := p.k("hard")
		for i in 2:
			var sx := 1.0 - 2.0 * i
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(6.0 * sx)) * Basis(Vector3.RIGHT, deg_to_rad(-6)), Vector3(0.03 * sx, -0.2, -0.13)))
			h.box(Vector3.ZERO, Vector3(0.04, 0.4, 0.01), GOLD)
			h.pop()
		var g := p.k("glow")
		for i in 5:
			var a := TAU * i / 5.0
			g.box(Vector3(cos(a) * 0.016, 0.025 + sin(a) * 0.016, -0.125), Vector3(0.016, 0.016, 0.01), GOLD_L)
		# Little gold stars scattered over the hem.
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 34:
			var a := rng.randf() * TAU
			var y := rng.randf_range(-0.9, -0.66)
			var t := inverse_lerp(-0.92, -0.66, y)
			var rx := lerpf(0.36, 0.31, t) + 0.004
			var rz := lerpf(0.34, 0.29, t) + 0.004
			var c := Vector3(sin(a) * rx, y, -cos(a) * rz)
			var sz := rng.randf_range(0.008, 0.016)
			g.push(_aim(Vector3(c.x, 0, c.z), c))
			g.box(Vector3.ZERO, Vector3(sz, 0.002, sz), GOLD_L if i % 3 else Color.WHITE)
			g.pop()
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.104, GOWN_D], [0.1, 0.134, 0.104, GOWN], [0.19, 0.152, 0.118, GOWN_L, Vector2(0, -0.006)],
			[0.26, 0.152, 0.11, GOWN, Vector2(0, -0.004)], [0.31, 0.126, 0.092, GOWN],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# A low, rounded neckline and a gold collar.
		k.tri_vc([Vector3(-0.06, 0.32, -0.09), Vector3(0.06, 0.32, -0.09), Vector3(0, 0.255, -0.116)],
			[SKIN, SKIN, SKIN_D], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, 0.25, 0))
		k.loft([[0.355, 0.07, 0.062, GOLD], [0.372, 0.062, 0.056, GOLD_L]], 10)
		# The mantle: a short cape over the shoulders and back.
		var h := p.k("hard")
		h.loft([[0.12, 0.2, 0.15, MANTLE, Vector2(0, 0.03)], [0.24, 0.19, 0.14, MANTLE, Vector2(0, 0.015)], [0.33, 0.13, 0.1, GOWN_L], [0.36, 0.08, 0.07, GOLD]], 12, false)
		# A pale blue gem at the neckline.
		var g := p.k("glow")
		g.box(Vector3(0, 0.295, -0.106), Vector3(0.026, 0.026, 0.01), _c("bfe4ff"))
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		# Bright white hair falling past her knees.
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 1.05, 0.15, 0.42)
		# The gold circlet, its star rising over her brow.
		var h := p.k("hard")
		h.loft([[0.2, 0.124, 0.126, GOLD], [0.218, 0.124, 0.126, GOLD_L]], 14, false)
		var g := p.k("glow")
		g.push(Transform3D(Basis.IDENTITY, Vector3(0, 0.25, -0.13)))
		# Four rays, the upper one longest, like a rising star.
		for i in 4:
			var ray := 0.05 if i == 0 else 0.03
			g.push(Transform3D(Basis(Vector3.BACK, TAU * i / 4.0), Vector3.ZERO))
			g.box(Vector3(0, ray * 0.5, 0), Vector3(0.012, ray, 0.008), GOLD_L)
			g.pop()
		g.box(Vector3.ZERO, Vector3(0.02, 0.02, 0.01), Color.WHITE)
		g.pop()
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, GOWN], [0.045, 0.062, 0.062, GOWN], [-0.03, 0.07, 0.07, GOWN_L],
			[-0.16, 0.075, 0.075, GOWN], [-0.25, 0.08, 0.08, GOWN_D],
		], 8)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		var k := p.k()
		# The bell sleeve widening to a gold-edged mouth; the wrist inside it.
		k.loft([[0.03, 0.08, 0.08, GOWN], [-0.08, 0.1, 0.1, GOWN_L], [-0.17, 0.125, 0.125, GOWN],
			[-0.19, 0.13, 0.13, GOLD], [-0.2, 0.125, 0.125, GOLD_L], [-0.205, 0.06, 0.06, GOWN_D.darkened(0.3)], [-0.2, 0.0, 0.0, GOWN_D.darkened(0.4)]], 9)
		k.loft([[-0.14, 0.032, 0.032, SKIN], [-0.21, 0.03, 0.03, SKIN], [-0.22, 0.0, 0.0, SKIN_D]], 6)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _none := func(_p: Parts, _side: float) -> void: pass
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _none, "shin": _none, "foot": _none}
	_build_woman("LothelyeModel", "lothelye.tscn", "face_lothelye", SKIN, SKIN_D, look, _lothelye_anims, 1.08)


func _lothelye_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Floating: a slow rise and fall, arms a little open, palms out.
	_anim(lib, "idle", 3.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.6, V.call(0, 0.88, 0)]],
		"torso": [[0.0, V.call(2, 0, 0)], [1.6, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(-4, 0, 3)], [1.6, V.call(-2, 0, -2)]],
		"shoulder_r": [[0.0, V.call(6, 0, 16)], [1.6, V.call(10, 0, 20)]], "elbow_r": [[0.0, V.call(25, 0, 0)]], "hand_r": [[0.0, V.call(0, 60, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, -16)], [1.6, V.call(10, 0, -20)]], "elbow_l": [[0.0, V.call(25, 0, 0)]], "hand_l": [[0.0, V.call(0, -60, 0)]],
	}, rest)
	# Speaking: one hand opening toward the listener and back.
	_anim(lib, "talk", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.87, 0)]],
		"head": [[0.0, V.call(-4, 0, 2)], [0.6, V.call(-8, 4, -2)], [1.2, V.call(-3, -2, 3)], [1.8, V.call(-6, 2, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, 18)], [0.8, V.call(52, 10, 26)], [1.6, V.call(38, 4, 20)]],
		"elbow_r": [[0.0, V.call(50, 0, 0)], [0.8, V.call(30, 0, 0)], [1.6, V.call(45, 0, 0)]], "hand_r": [[0.0, V.call(-20, 70, 0)]],
		"shoulder_l": [[0.0, V.call(8, 0, -16)]], "elbow_l": [[0.0, V.call(30, 0, 0)]], "hand_l": [[0.0, V.call(0, -60, 0)]],
	}, rest)
	# Raising both arms up and out (the world dreamed into being).
	_anim(lib, "raise", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.86, 0)], [1.2, V.call(0, 0.9, 0)]],
		"torso": [[0.0, V.call(6, 0, 0)]],
		"head": [[0.0, V.call(16, 0, 0)], [1.2, V.call(20, 0, 0)]],
		"shoulder_r": [[0.0, V.call(150, 0, 34)], [1.2, V.call(156, 0, 40)]], "elbow_r": [[0.0, V.call(15, 0, 0)]], "hand_r": [[0.0, V.call(-10, 80, 0)]],
		"shoulder_l": [[0.0, V.call(150, 0, -34)], [1.2, V.call(156, 0, -40)]], "elbow_l": [[0.0, V.call(15, 0, 0)]], "hand_l": [[0.0, V.call(-10, -80, 0)]],
	}, rest)
	# Reaching out with her right hand (calling, or blessing someone).
	_anim(lib, "reach", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.87, 0)]],
		"torso": [[0.0, V.call(-4, -8, 0)]],
		"head": [[0.0, V.call(-6, 4, 0)]],
		"shoulder_r": [[0.0, V.call(84, 0, 8)], [1.2, V.call(90, 0, 10)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "hand_r": [[0.0, V.call(-40, 90, 0)]],
		"shoulder_l": [[0.0, V.call(10, 0, -18)]], "elbow_l": [[0.0, V.call(30, 0, 0)]], "hand_l": [[0.0, V.call(0, -60, 0)]],
	}, rest)
	# Hands folded at her heart, head bowed a little (a farewell, a blessing).
	_anim(lib, "bless", 3.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.5, V.call(0, 0.87, 0)]],
		"head": [[0.0, V.call(-12, 0, 4)], [1.5, V.call(-10, 0, 2)]],
		"shoulder_r": [[0.0, V.call(40, 30, -10)]], "elbow_r": [[0.0, V.call(105, 0, 0)]], "hand_r": [[0.0, V.call(-70, 0, 0)]],
		"shoulder_l": [[0.0, V.call(40, -30, 10)]], "elbow_l": [[0.0, V.call(105, 0, 0)]], "hand_l": [[0.0, V.call(-70, 0, 0)]],
	}, rest)
	# Sorrow: head down, one hand at her brow (the war remembered).
	_anim(lib, "sorrow", 3.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.83, 0)], [1.5, V.call(0, 0.85, 0)]],
		"torso": [[0.0, V.call(-8, 0, 0)]],
		"head": [[0.0, V.call(-22, 6, 0)], [1.5, V.call(-18, 4, 0)]],
		"shoulder_r": [[0.0, V.call(120, -20, -20)]], "elbow_r": [[0.0, V.call(110, 0, 0)]], "hand_r": [[0.0, V.call(-30, 0, 0)]],
		"shoulder_l": [[0.0, V.call(8, 0, -12)]], "elbow_l": [[0.0, V.call(25, 0, 0)]],
	}, rest)


# --- Avalon ---------------------------------------------------------------------
#
# Avalon (Val), Warrior of the Cosmos, Keeper of the Stars and Keeper of Hope,
# born of the prayers of Bunsriel's people. She waits in the Astral Dimension,
# floating: short blue hair in a soft chin-length bob, kind brown eyes, and a
# beautiful white gown (a fitted bodice under a silver-trimmed neckline, puffed
# off-shoulder sleeves, a layered floor-length skirt scattered with little
# pale stars, a silver sash with a star clasp). A silver star clip in her hair
# and a star pendant at her throat. Her hands rest on the pommel of the
# Luminous Blade (Cosmolite from Ladhellin, lit with Lothelye's starlight),
# planted point-down before her. No legs: the gown reaches the floor.

func _build_avalon() -> void:
	var SKIN := _c("fcece2")
	var SKIN_D := _c("ecd4c6")
	var GOWN := _c("f6f6fc")
	var GOWN_L := _c("ffffff")
	var GOWN_D := _c("d6dcee")
	var VEIL := _c("e8eefa")
	var SILVER := _c("b8c6e2")
	var SILVER_L := _c("eef4ff")
	var STAR := _c("bfe2ff")
	var HAIR := _c("4a7ce0")
	var HAIR_D := _c("3058b0")
	var HAIR_L := _c("7aa8f6")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		# The skirt: fitted at the waist, falling to the floor in a soft A-line.
		k.loft([
			[-0.9, 0.31, 0.29, GOWN_D], [-0.83, 0.305, 0.285, GOWN], [-0.62, 0.27, 0.25, GOWN_L],
			[-0.4, 0.22, 0.2, GOWN], [-0.2, 0.17, 0.145, GOWN_L], [-0.03, 0.134, 0.11, GOWN], [0.07, 0.12, 0.098, GOWN],
		], 16)
		k.loft([[-0.86, 0.31, 0.29, SILVER], [-0.835, 0.307, 0.287, SILVER_L]], 16, false)
		# The overskirt: a second, paler layer ending at the knee, silver-hemmed.
		k.loft([
			[-0.56, 0.262, 0.242, SILVER], [-0.53, 0.258, 0.238, VEIL], [-0.36, 0.215, 0.195, GOWN_L],
			[-0.18, 0.172, 0.148, VEIL], [-0.02, 0.138, 0.114, GOWN_L],
		], 16, false)
		# The sash, its ends falling behind her.
		k.loft([[-0.005, 0.138, 0.114, SILVER], [0.045, 0.13, 0.106, SILVER_L]], 14)
		var h := p.k("hard")
		for i in 2:
			var sx := 1.0 - 2.0 * i
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(5.0 * sx)) * Basis(Vector3.RIGHT, deg_to_rad(8)), Vector3(0.035 * sx, -0.24, 0.13)))
			h.box(Vector3.ZERO, Vector3(0.045, 0.48, 0.01), SILVER_L)
			h.pop()
		var g := p.k("glow")
		_star(g, Vector3(0, 0.02, -0.112), Vector3(0, 0, -1), 0.03, SILVER_L)
		_star(g, Vector3(0, 0.02, -0.114), Vector3(0, 0, -1), 0.012, STAR)
		# Little pale stars scattered over the lower skirt.
		var rng := RandomNumberGenerator.new()
		rng.seed = 307
		for i in 30:
			var a := rng.randf() * TAU
			var y := rng.randf_range(-0.82, -0.6)
			var t := inverse_lerp(-0.9, -0.62, y)
			var rx := lerpf(0.31, 0.27, t) + 0.004
			var rz := lerpf(0.29, 0.25, t) + 0.004
			var c := Vector3(sin(a) * rx, y, -cos(a) * rz)
			_star(g, c, Vector3(c.x, 0, c.z), rng.randf_range(0.012, 0.022), STAR if i % 3 else Color.WHITE)
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		# The bodice, up to a silver-trimmed neckline across the bust; bare
		# shoulders above it.
		k.loft([
			[0.0, 0.122, 0.098, GOWN_D], [0.1, 0.126, 0.098, GOWN], [0.19, 0.146, 0.114, GOWN_L, Vector2(0, -0.006)],
			[0.235, 0.148, 0.11, GOWN, Vector2(0, -0.005)], [0.262, 0.146, 0.104, SKIN, Vector2(0, -0.004)],
			[0.31, 0.126, 0.09, SKIN], [0.35, 0.072, 0.062, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		k.loft([[0.228, 0.151, 0.114, SILVER, Vector2(0, -0.005)], [0.246, 0.15, 0.111, SILVER_L, Vector2(0, -0.005)]], 12, false)
		# A thin chain and the star pendant at her throat.
		var g := p.k("glow")
		_star(g, Vector3(0, 0.282, -0.1), Vector3(0, 0.15, -1), 0.022, STAR)
		_star(g, Vector3(0, 0.282, -0.102), Vector3(0, 0.15, -1), 0.009, Color.WHITE)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# The bob: a soft, rounded chin-length cut from the crown, hugging the
		# head and curling in at the ends, open at the face.
		k.loft([
			[0.032, 0.104, 0.088, HAIR_D, Vector2(0, 0.06)], [0.05, 0.126, 0.108, HAIR, Vector2(0, 0.055)],
			[0.09, 0.135, 0.122, HAIR_L, Vector2(0, 0.045)], [0.15, 0.134, 0.128, HAIR, Vector2(0, 0.032)],
			[0.21, 0.129, 0.129, HAIR_L, Vector2(0, 0.018)], [0.27, 0.12, 0.126, HAIR, Vector2(0, 0.008)],
		], 18, false)
		# Soft tapered tips along the lower edge, so it ends in strands rather
		# than a hard line.
		for i in 9:
			var a := deg_to_rad(lerpf(72.0, 288.0, i / 8.0))
			var c := Vector3(sin(a) * 0.11, 0.05, 0.055 - cos(a) * 0.094)
			var inward := Vector3(-sin(a), 0, cos(a)) * 0.55
			k.push(_aim(Vector3(0, -1, 0) + inward, c))
			k.loft([[-0.012, 0.026, 0.014, HAIR], [0.018, 0.018, 0.01, HAIR], [0.036, 0.0, 0.0, HAIR_D]], 5)
			k.pop()
		# Rounded locks framing her cheeks, tapering to a point.
		for sx in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-5 * sx)), Vector3(0.1 * sx, 0.0, -0.05)))
			k.loft([[0.03, 0.0, 0.0, HAIR_D], [0.06, 0.014, 0.016, HAIR], [0.14, 0.02, 0.022, HAIR], [0.2, 0.016, 0.018, HAIR_L], [0.22, 0.0, 0.0, HAIR]], 7)
			k.pop()
		# The silver star clip over her left temple.
		var g := p.k("glow")
		_star(g, Vector3(-0.096, 0.25, -0.082), Vector3(-0.75, 0.15, -0.65), 0.04, SILVER_L)
		_star(g, Vector3(-0.099, 0.251, -0.085), Vector3(-0.75, 0.15, -0.65), 0.016, STAR)
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		# Bare shoulder, then a soft off-shoulder puff of white.
		p.k().loft([
			[0.03, 0.0, 0.0, SKIN], [0.02, 0.044, 0.044, SKIN], [-0.01, 0.052, 0.052, SKIN],
			[-0.02, 0.078, 0.078, GOWN_L], [-0.075, 0.084, 0.084, GOWN], [-0.115, 0.062, 0.062, SILVER],
			[-0.125, 0.042, 0.042, SKIN], [-0.22, 0.036, 0.036, SKIN], [-0.25, 0.0, 0.0, SKIN_D],
		], 8)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.145, 0.03, 0.03, SKIN],
			[-0.155, 0.035, 0.035, SILVER], [-0.175, 0.035, 0.035, SILVER_L], [-0.185, 0.029, 0.029, SKIN],
			[-0.21, 0.026, 0.026, SKIN], [-0.22, 0.0, 0.0, SKIN_D],
		], 7)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _none := func(_p: Parts, _side: float) -> void: pass
	var _extra := func(root: Node3D) -> void:
		# The Luminous Blade, carried on the hips so it floats with her.
		_attach(root.get_node(_paths["hips"]), "LuminousBlade", Vector3(0, -0.035, -0.3), _luminous_blade_parts, "blade")
	var look := {"blush": true, "hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part,
		"forearm": _forearm_part, "hand": _hand_part, "thigh": _none, "shin": _none, "foot": _none, "extra": _extra}
	_build_woman("AvalonModel", "avalon.tscn", "face_avalon", SKIN, SKIN_D, look, _avalon_anims, 1.02)


## A flat five-pointed star centered on `c`, facing along `n`.
func _star(k: MeshKit, c: Vector3, n: Vector3, r: float, col: Color) -> void:
	k.push(_aim(n, c))
	for i in 5:
		k.push(Transform3D(Basis(Vector3.UP, TAU * i / 5.0), Vector3.ZERO))
		k.tri_vc([Vector3(-r * 0.28, 0, 0), Vector3(r * 0.28, 0, 0), Vector3(0, 0, -r)], [col, col, col],
			[Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, -1, 0))
		k.pop()
	k.prism(Vector3(0, -0.002, 0), r * 0.36, Vector3(0, 0.002, 0), r * 0.36, 5, col)
	k.pop()


## The Luminous Blade, point down along -Y from the guard at the origin: a
## blade of starlit Cosmolite, a silver crossguard curling up at the tips with
## a sapphire at its heart, a deep-blue grip and a star for a pommel.
func _luminous_blade_parts(p: Parts) -> void:
	var g := p.k("glow")
	var CORE := _c("f4faff")
	var PALE := _c("cfe6ff")
	var BLUE := _c("8cbcff")
	g.push(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 0.28)), Vector3.ZERO))
	g.loft([[-0.84, 0.0, 0.0, BLUE], [-0.75, 0.034, 0.034, PALE], [-0.38, 0.04, 0.04, CORE], [-0.02, 0.044, 0.044, CORE]], 4)
	g.pop()
	# The fuller, a line of deeper blue down each face.
	for sz in [-1.0, 1.0]:
		g.box(Vector3(0, -0.37, 0.0125 * sz), Vector3(0.008, 0.6, 0.002), BLUE)
	var h := p.k("hard")
	var SILVER := _c("c8d4ec")
	var SILVER_D := _c("8a9ac0")
	var GRIP := _c("26306a")
	h.box(Vector3(0, 0.0, 0), Vector3(0.2, 0.03, 0.04), SILVER)
	for sx in [-1.0, 1.0]:
		h.prism(Vector3(0.1 * sx, 0.0, 0), 0.02, Vector3(0.125 * sx, 0.045, 0), 0.008, 4, SILVER)
	h.prism(Vector3(0, 0.015, 0), 0.026, Vector3(0, 0.035, 0), 0.02, 6, SILVER_D)
	h.prism(Vector3(0, 0.03, 0), 0.018, Vector3(0, 0.15, 0), 0.016, 6, GRIP)
	var gy := 0.045
	while gy < 0.14:
		h.prism(Vector3(0, gy, 0), 0.0195, Vector3(0, gy + 0.01, 0), 0.0195, 6, SILVER_D)
		gy += 0.03
	h.prism(Vector3(0, 0.15, 0), 0.02, Vector3(0, 0.165, 0), 0.026, 6, SILVER)
	_star(g, Vector3(0, 0.0, -0.021), Vector3(0, 0, -1), 0.022, _c("5a9cff"))
	_star(g, Vector3(0, 0.0, 0.021), Vector3(0, 0, 1), 0.022, _c("5a9cff"))
	_star(g, Vector3(0, 0.19, 0), Vector3(0, 0, -1), 0.04, CORE)
	_star(g, Vector3(0, 0.19, 0.001), Vector3(0, 0, 1), 0.04, CORE)


func _avalon_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var on_pommel := {
		"shoulder_r": [[0.0, V.call(16, 40, 13)]], "elbow_r": [[0.0, V.call(71, 0, 0)]], "hand_r": [[0.0, V.call(15, 120, -40)]],
		"shoulder_l": [[0.0, V.call(19, -40, -12)]], "elbow_l": [[0.0, V.call(57, 0, 0)]], "hand_l": [[0.0, V.call(-10, -90, 35)]],
	}
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Floating with both hands on the pommel of her sword, head tilted kindly.
	var idle := on_pommel.duplicate()
	idle.merge({
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.8, V.call(0, 0.87, 0)]],
		"head": [[0.0, V.call(-6, 0, 6)], [1.8, V.call(-4, 2, 4)]],
	})
	_anim(lib, "idle", 3.6, true, idle, rest)
	# Speaking: her right hand lifts from the sword, open toward the listener.
	_anim(lib, "talk", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.865, 0)]],
		"head": [[0.0, V.call(-5, 0, 5)], [0.6, V.call(-8, 4, 2)], [1.2, V.call(-4, -2, 6)], [1.8, V.call(-6, 2, 3)]],
		"shoulder_r": [[0.0, V.call(29, -9, 6)], [1.2, V.call(36, -4, 10)]], "elbow_r": [[0.0, V.call(85, 0, 0)], [1.2, V.call(70, 0, 0)]],
		"hand_r": [[0.0, V.call(-5, -40, 5)]],
		"shoulder_l": on_pommel.shoulder_l, "elbow_l": on_pommel.elbow_l, "hand_l": on_pommel.hand_l,
	}, rest)
	# Her right hand at her heart (hope given, a blessing).
	_anim(lib, "bless", 3.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.5, V.call(0, 0.865, 0)]],
		"head": [[0.0, V.call(-12, 0, 6)], [1.5, V.call(-10, 0, 4)]],
		"shoulder_r": [[0.0, V.call(26, 64, 22)]], "elbow_r": [[0.0, V.call(116, 0, 0)]], "hand_r": [[0.0, V.call(30, -160, 25)]],
		"shoulder_l": on_pommel.shoulder_l, "elbow_l": on_pommel.elbow_l, "hand_l": on_pommel.hand_l,
	}, rest)


# --- Idrith ---------------------------------------------------------------------
#
# Leader of the Questlords of Ladhellin: long blonde hair, a lavender tunic
# with a brown belt, a gray collar and a long deep-blue cloak, pale gray
# leggings and soft brown boots.

func _build_idrith() -> void:
	var SKIN := _c("fdf0e6")
	var SKIN_D := _c("ead8ca")
	var TUNIC := _c("9a8aa8")
	var TUNIC_L := _c("ae9ebc")
	var TUNIC_D := _c("7e6e8e")
	var CLOAK := _c("4a4a8c")
	var CLOAK_D := _c("34346a")
	var COLLAR := _c("7a7a7e")
	var BELT := _c("5a3820")
	var LEG := _c("a8a290")
	var BOOT := _c("4a3018")
	var BOOT_D := _c("34200e")
	var HAIR := _c("e8d08a")
	var HAIR_D := _c("c8ae68")
	var HAIR_L := _c("f8e8b0")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.38, 0.225, 0.2, TUNIC_D], [-0.34, 0.228, 0.205, TUNIC_D], [-0.18, 0.2, 0.175, TUNIC],
			[-0.03, 0.16, 0.135, TUNIC_L], [0.06, 0.13, 0.105, TUNIC],
		], 12)
		k.loft([[0.0, 0.142, 0.117, BELT], [0.045, 0.137, 0.112, BELT]], 12)
		p.k("hard").box(Vector3(0.03, 0.022, -0.115), Vector3(0.045, 0.035, 0.012), _c("e0c050"))
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.125, 0.1, TUNIC_D], [0.1, 0.13, 0.102, TUNIC], [0.19, 0.148, 0.116, TUNIC_L, Vector2(0, -0.006)],
			[0.26, 0.15, 0.108, TUNIC, Vector2(0, -0.003)], [0.31, 0.125, 0.092, TUNIC],
			[0.34, 0.085, 0.075, COLLAR], [0.39, 0.07, 0.065, COLLAR],
		], 10)
		# The cloak: over the shoulders and down her back to the calves.
		k.loft([
			[-0.78, 0.22, 0.12, CLOAK_D, Vector2(0, 0.1)], [-0.4, 0.2, 0.1, CLOAK, Vector2(0, 0.08)],
			[0.0, 0.18, 0.08, CLOAK, Vector2(0, 0.06)], [0.25, 0.19, 0.08, CLOAK, Vector2(0, 0.045)],
			[0.33, 0.17, 0.07, CLOAK_D, Vector2(0, 0.035)],
		], 10)
		# The gray collar standing up round the neck.
		k.loft([[0.31, 0.11, 0.1, COLLAR], [0.36, 0.09, 0.085, COLLAR], [0.4, 0.075, 0.07, COLLAR.lightened(0.1)]], 10)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.62, 0.14, 0.32)
		# A stray strand on top.
		k.push(_aim(Vector3(0.3, 1, -0.4), Vector3(0.02, 0.33, -0.02)))
		k.loft([[0.0, 0.012, 0.008, HAIR], [0.07, 0.0, 0.0, HAIR_L]], 4)
		k.pop()
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, CLOAK], [0.045, 0.064, 0.064, CLOAK], [-0.03, 0.07, 0.07, CLOAK],
			[-0.08, 0.05, 0.05, TUNIC], [-0.22, 0.042, 0.042, TUNIC_D], [-0.25, 0.0, 0.0, TUNIC_D],
		], 7)
	var _forearm_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, TUNIC], [0.01, 0.04, 0.04, TUNIC], [-0.15, 0.038, 0.039, TUNIC_L],
			[-0.19, 0.03, 0.03, SKIN], [-0.215, 0.0, 0.0, SKIN]], 6)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _thigh_part := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, LEG], [0.03, 0.066, 0.07, LEG], [-0.18, 0.058, 0.062, LEG], [-0.36, 0.046, 0.05, LEG], [-0.4, 0.0, 0.0, LEG]], 7)
	var _shin_part := func(p: Parts, _side: float) -> void:
		# Soft boots to the knee, with a slouchy top.
		p.k().loft([[0.03, 0.0, 0.0, LEG], [0.0, 0.05, 0.054, BOOT], [-0.04, 0.054, 0.058, BOOT],
			[-0.07, 0.046, 0.05, BOOT_D], [-0.33, 0.036, 0.04, BOOT], [-0.35, 0.0, 0.0, BOOT_D]], 7)
	var _foot_part := func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT_D)
	var look := {"blush": true, "hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part, "hand": _hand_part, "thigh": _thigh_part, "shin": _shin_part, "foot": _foot_part}
	_build_woman("IdrithModel", "idrith.tscn", "face_idrith", SKIN, SKIN_D, look, _seated_anims.bind(false), 0.97)


## Sitting on the bench in the armory, side by side: Aladriel (`left_one`, on
## the left as you face them) with her right arm round Idrith, Idrith leaning
## into her with her head on her shoulder and her hands in her lap. Each has
## "idle", "talk" (still seated) and "shy" (blushing, while the other is
## being talked to). Hips sit at bench height, thighs level, shins down.
func _seated_anims(lib: AnimationLibrary, rest: Dictionary, left_one: bool) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var seat: Vector3 = V.call(0, 0.5, 0.04)
	var legs := {
		"leg_r": [[0.0, V.call(86, 0, 3 if left_one else 1)]], "leg_l": [[0.0, V.call(84, 0, -6 if left_one else -1)]],
		"knee_r": [[0.0, V.call(-80, 0, 0)]], "knee_l": [[0.0, V.call(-86, 0, 0)]],
		"foot_r": [[0.0, V.call(-4, 0, 0)]], "foot_l": [[0.0, V.call(2, 0, 0)]],
	}
	var base := {}
	if left_one:
		# Aladriel: sitting tall, her right arm round Idrith's shoulders, left
		# hand on her knee.
		base = {
			"hips@pos": [[0.0, seat]], "hips": [[0.0, V.call(0, -8, 0)]],
			"torso": [[0.0, V.call(2, -4, -3)]], "head": [[0.0, V.call(0, -6, -6)]],
			"shoulder_r": [[0.0, V.call(-12, 0, 78)]], "elbow_r": [[0.0, V.call(55, 0, 0)]], "hand_r": [[0.0, V.call(0, 0, 0)]],
			"shoulder_l": [[0.0, V.call(30, -10, 10)]], "elbow_l": [[0.0, V.call(40, 0, 0)]],
		}
	else:
		# Idrith: leaning into Aladriel, head on her shoulder, hands in her lap.
		base = {
			"hips@pos": [[0.0, seat]], "hips": [[0.0, V.call(0, 8, 0)]],
			"torso": [[0.0, V.call(-4, 6, 12)]], "head": [[0.0, V.call(-4, 10, 16)]],
			"shoulder_r": [[0.0, V.call(28, 30, -6)]], "elbow_r": [[0.0, V.call(62, 0, 0)]], "hand_r": [[0.0, V.call(-10, 0, 0)]],
			"shoulder_l": [[0.0, V.call(30, -30, 6)]], "elbow_l": [[0.0, V.call(62, 0, 0)]], "hand_l": [[0.0, V.call(-10, 0, 0)]],
		}
	var merged := func(extra: Dictionary) -> Dictionary:
		var d := legs.duplicate()
		d.merge(base, true)
		d.merge(extra, true)
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 3.0, true, merged.call({
		"hips@pos": [[0.0, seat], [1.5, seat + V.call(0, -0.006, 0)]],
	}), rest)
	# On their feet (the castle): standing, talking, walking, and their guard,
	# back to back with swords up (as they stood against Dailah).
	_anim(lib, "stand", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.835, 0)]],
		"shoulder_r": [[0.0, V.call(6, 0, -6)]], "elbow_r": [[0.0, V.call(15, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, 6)]], "elbow_l": [[0.0, V.call(15, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(4, 0, -3)]], "knee_l": [[0.0, V.call(-6, 0, 0)]],
	}, rest)
	_anim(lib, "stand_talk", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"head": [[0.0, V.call(2, 0, 0)], [0.4, V.call(-4, 6, 0)], [0.8, V.call(2, -4, 0)], [1.2, V.call(-2, 2, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, -12)], [0.4, V.call(55, 0, -20)], [0.8, V.call(35, 0, -12)], [1.2, V.call(50, 0, -18)]],
		"elbow_r": [[0.0, V.call(60, 0, 0)], [0.4, V.call(35, 0, 0)], [0.8, V.call(65, 0, 0)]],
		"shoulder_l": [[0.0, V.call(6, 0, 6)]], "elbow_l": [[0.0, V.call(15, 0, 0)]],
	}, rest)
	_anim(lib, "walk", 0.9, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.225, V.call(0, 0.86, 0)], [0.45, V.call(0, 0.84, 0)], [0.675, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.45, V.call(24, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)], [0.45, V.call(-24, 0, 0)]],
		"knee_r": [[0.0, V.call(-8, 0, 0)], [0.225, V.call(-40, 0, 0)], [0.45, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.45, V.call(-8, 0, 0)], [0.675, V.call(-40, 0, 0)]],
		"shoulder_r": [[0.0, V.call(18, 0, -6)], [0.45, V.call(-18, 0, -6)]],
		"shoulder_l": [[0.0, V.call(-18, 0, 6)], [0.45, V.call(18, 0, 6)]],
	}, rest)
	_anim(lib, "guard", 1.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.78, 0)], [0.5, V.call(0, 0.77, 0)]],
		"torso": [[0.0, V.call(-6, 10 if left_one else -10, 0)]],
		"shoulder_r": [[0.0, V.call(95, 0, -20)]], "elbow_r": [[0.0, V.call(40, 0, 0)]], "hand_r": [[0.0, V.call(30, 0, 0)]],
		"shoulder_l": [[0.0, V.call(70, 0, 20)]], "elbow_l": [[0.0, V.call(50, 0, 0)]], "hand_l": [[0.0, V.call(30, 0, 0)]],
		"leg_r": [[0.0, V.call(-14, 0, 10)]], "leg_l": [[0.0, V.call(16, 0, -10)]], "knee_r": [[0.0, V.call(-16, 0, 0)]], "knee_l": [[0.0, V.call(-16, 0, 0)]],
	}, rest)
	# A sword cut from the guard (the Siege of Haven, at the hero's side): the
	# blade up and back, then down and across.
	_anim(lib, "swing", 0.6, false, {
		"hips@pos": [[0.0, V.call(0, 0.78, 0)], [0.25, V.call(0, 0.76, -0.05)], [0.6, V.call(0, 0.78, 0)]],
		"torso": [[0.0, V.call(-6, 30, 0)], [0.2, V.call(4, 40, 0)], [0.32, V.call(-14, -35, 0)], [0.6, V.call(-6, 0, 0)]],
		"shoulder_r": [[0.0, V.call(95, 0, -20)], [0.2, V.call(165, 0, -10)], [0.32, V.call(55, 0, -30)], [0.6, V.call(95, 0, -20)]],
		"elbow_r": [[0.0, V.call(40, 0, 0)], [0.2, V.call(60, 0, 0)], [0.32, V.call(10, 0, 0)], [0.6, V.call(40, 0, 0)]],
		"hand_r": [[0.0, V.call(30, 0, 0)]],
		"shoulder_l": [[0.0, V.call(70, 0, 20)], [0.32, V.call(40, 0, 30)], [0.6, V.call(70, 0, 20)]], "elbow_l": [[0.0, V.call(50, 0, 0)]],
		"leg_r": [[0.0, V.call(-14, 0, 10)], [0.32, V.call(-24, 0, 10)]], "leg_l": [[0.0, V.call(16, 0, -10)], [0.32, V.call(30, 0, -10)]],
		"knee_r": [[0.0, V.call(-16, 0, 0)]], "knee_l": [[0.0, V.call(-16, 0, 0)], [0.32, V.call(-30, 0, 0)]],
	}, rest)
	# Slumped, worn out from the fight (sitting against the cell wall).
	_anim(lib, "weary", 3.0, true, merged.call({
		"hips@pos": [[0.0, seat], [1.5, seat + V.call(0, -0.01, 0)]],
		"torso": [[0.0, V.call(-12, 0, 6 if left_one else -6)]],
		"head": [[0.0, V.call(-20, 0, 8 if left_one else -8)], [1.5, V.call(-16, 0, 6 if left_one else -6)]],
	}), rest)
	# Out walking together (the title's desert scene): the inner hands held
	# between them (Aladriel's right, Idrith's left), swinging a little in
	# step, the outer arm swinging freely.
	var inner := "shoulder_r" if left_one else "shoulder_l"
	var outer := "shoulder_l" if left_one else "shoulder_r"
	var out_side := 1.0 if left_one else -1.0
	var hand_walk := {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.225, V.call(0, 0.86, 0)], [0.45, V.call(0, 0.84, 0)], [0.675, V.call(0, 0.86, 0)]],
		"leg_r": [[0.0, V.call(-24, 0, 0)], [0.45, V.call(24, 0, 0)]], "leg_l": [[0.0, V.call(24, 0, 0)], [0.45, V.call(-24, 0, 0)]],
		"knee_r": [[0.0, V.call(-8, 0, 0)], [0.225, V.call(-40, 0, 0)], [0.45, V.call(-6, 0, 0)]],
		"knee_l": [[0.0, V.call(-6, 0, 0)], [0.45, V.call(-8, 0, 0)], [0.675, V.call(-40, 0, 0)]],
		"head": [[0.0, V.call(0, -8 * out_side, 0)]],
		"torso": [[0.0, V.call(0, -4 * out_side, 0)]],
	}
	hand_walk[inner] = [[0.0, V.call(10, 0, 22 * out_side)], [0.45, V.call(2, 0, 22 * out_side)]]
	hand_walk["elbow" + inner.trim_prefix("shoulder")] = [[0.0, V.call(14, 0, 0)]]
	hand_walk["hand" + inner.trim_prefix("shoulder")] = [[0.0, V.call(0, 0, -10 * out_side)]]
	hand_walk[outer] = [[0.0, V.call(-18 if left_one else 18, 0, 6 * out_side)], [0.45, V.call(18 if left_one else -18, 0, 6 * out_side)]]
	_anim(lib, "walk_hand", 0.9, true, hand_walk, rest)
	# Sitting, looking up at the stars.
	_anim(lib, "stargaze", 3.0, true, merged.call({
		"hips@pos": [[0.0, seat], [1.5, seat + V.call(0, -0.006, 0)]],
		"torso": [[0.0, V.call(-8, -4, -3)]] if left_one else [[0.0, V.call(-8, 6, 10)]],
		"head": [[0.0, V.call(26, -6, -4)], [1.5, V.call(24, -10, -4)]] if left_one else [[0.0, V.call(22, 6, 12)], [1.5, V.call(24, 10, 12)]],
	}), rest)
	if left_one:
		# Talking: sitting up, her free hand making the point.
		_anim(lib, "talk", 1.6, true, merged.call({
			"torso": [[0.0, V.call(0, -2, -2)], [0.8, V.call(-3, 0, -2)]],
			"head": [[0.0, V.call(4, 0, -4)], [0.4, V.call(-4, 4, -2)], [0.8, V.call(2, -2, -5)], [1.2, V.call(-2, 2, -3)]],
			"shoulder_l": [[0.0, V.call(50, -15, 14)], [0.4, V.call(70, -20, 20)], [0.8, V.call(45, -10, 12)], [1.2, V.call(65, -20, 18)]],
			"elbow_l": [[0.0, V.call(70, 0, 0)], [0.4, V.call(40, 0, 0)], [0.8, V.call(75, 0, 0)], [1.2, V.call(45, 0, 0)]],
		}), rest)
		# Flustered: looking down and away, the free hand rubbing her neck.
		_anim(lib, "shy", 1.2, true, merged.call({
			"head": [[0.0, V.call(-16, 24, -4)], [0.6, V.call(-14, 20, -2)]],
			"shoulder_l": [[0.0, V.call(150, -40, 10)]], "elbow_l": [[0.0, V.call(130, 0, 0)]], "hand_l": [[0.0, V.call(-20, 0, 0)]],
		}), rest)
		# Leaning in toward Idrith (for her kiss), head tipped to meet her.
		_anim(lib, "lean_in", 2.0, true, merged.call({
			"torso": [[0.0, V.call(0, -8, -12)]],
			"head": [[0.0, V.call(-6, -14, -14)], [1.0, V.call(-5, -12, -15)]],
		}), rest)
	else:
		# Talking: lifting her head a little, one hand moving shyly.
		_anim(lib, "talk", 1.8, true, merged.call({
			"torso": [[0.0, V.call(-2, 4, 8)]],
			"head": [[0.0, V.call(2, 8, 10)], [0.6, V.call(-2, 4, 12)], [1.2, V.call(0, 10, 9)]],
			"shoulder_r": [[0.0, V.call(45, 20, -10)], [0.6, V.call(55, 25, -14)], [1.2, V.call(42, 18, -10)]],
			"elbow_r": [[0.0, V.call(95, 0, 0)], [0.6, V.call(80, 0, 0)]],
		}), rest)
		# Shy: hands up to her cheeks, head ducked against Aladriel.
		_anim(lib, "shy", 1.4, true, merged.call({
			"head": [[0.0, V.call(-14, 14, 18)], [0.7, V.call(-12, 10, 20)]],
			"shoulder_r": [[0.0, V.call(55, 40, -8)]], "elbow_r": [[0.0, V.call(130, 0, 0)]], "hand_r": [[0.0, V.call(-20, 0, 0)]],
			"shoulder_l": [[0.0, V.call(55, -40, 8)]], "elbow_l": [[0.0, V.call(130, 0, 0)]], "hand_l": [[0.0, V.call(-20, 0, 0)]],
		}), rest)
		# A little kiss on Aladriel's cheek: up off her shoulder, stretching
		# over, a hand on Aladriel's arm.
		_anim(lib, "kiss", 2.0, true, merged.call({
			"hips": [[0.0, V.call(0, 14, 0)]],
			"torso": [[0.0, V.call(-6, 18, 20)]],
			"head": [[0.0, V.call(14, 30, 12)], [1.0, V.call(15, 32, 13)]],
			"shoulder_l": [[0.0, V.call(50, -10, -20)]], "elbow_l": [[0.0, V.call(40, 0, 0)]],
		}), rest)


# --- Props in the armory ----------------------------------------------------------

## Aladriel's giant sword, Idrith's sheathed scimitar and Pink's anvil, built
## upright (the scimitar along its own curve), point down, for the armory.
func _build_armory_props() -> void:
	_save_res(_parts_mesh(func(p: Parts) -> void:
		var h := p.k("hard")
		h.push(Transform3D(Basis.from_scale(Vector3(1, 1, 0.22)), Vector3.ZERO))
		h.prism(Vector3(0, 0.0, 0), 0.0, Vector3(0, 0.18, 0), 0.075, 4, _c("e6eaf0"))
		h.prism(Vector3(0, 0.18, 0), 0.075, Vector3(0, 1.3, 0), 0.07, 4, _c("d0d6de"))
		h.pop()
		h.box(Vector3(0, 1.32, 0), Vector3(0.38, 0.045, 0.06), _c("c8a85a"))
		h.prism(Vector3(0, 1.34, 0), 0.026, Vector3(0, 1.58, 0), 0.024, 6, _c("6a4428"))
		h.prism(Vector3(0, 1.58, 0), 0.04, Vector3(0, 1.64, 0), 0.0, 6, _c("c8a85a"))
	), "giant_sword_mesh.tres")
	_save_res(_parts_mesh(func(p: Parts) -> void:
		var h := p.k("hard")
		var pts: Array[Vector3] = []
		for i in 7:
			var t := i / 6.0
			pts.append(Vector3(0.12 * t * t, t * 0.75, 0))
		for i in 6:
			var a := pts[i]
			var b := pts[i + 1]
			h.push(_aim(b - a, a))
			h.push(Transform3D(Basis.from_scale(Vector3(1, 1, 0.4)), Vector3.ZERO))
			h.prism(Vector3.ZERO, 0.035 + 0.006 * i, Vector3(0, (b - a).length(), 0), 0.041 + 0.006 * i, 6, _c("2c2a24"))
			h.pop()
			h.pop()
		h.prism(Vector3(0.0, -0.06, 0), 0.0, Vector3(0, 0.02, 0), 0.04, 6, _c("e8c040"))
		h.box(Vector3(0.12, 0.77, 0), Vector3(0.16, 0.025, 0.04), _c("e8c040"))
		h.prism(Vector3(0.12, 0.78, 0), 0.02, Vector3(0.1, 0.93, 0), 0.018, 6, _c("e8c040"))
		h.prism(Vector3(0.1, 0.93, 0), 0.03, Vector3(0.08, 0.97, 0), 0.0, 6, _c("8a1818"))
	), "scimitar_mesh.tres")
	_save_res(_parts_mesh(func(p: Parts) -> void:
		var h := p.k("hard")
		var iron := _c("3a3a42")
		h.slab(Vector3(0, 0, 0), Vector2(0.5, 0.4), Vector3(0, 0.12, 0), Vector2(0.36, 0.28), iron.darkened(0.2))
		h.slab(Vector3(0, 0.12, 0), Vector2(0.2, 0.18), Vector3(0, 0.5, 0), Vector2(0.18, 0.16), iron)
		h.box(Vector3(0, 0.6, 0), Vector3(0.62, 0.2, 0.24), iron.lightened(0.15))
		h.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(-0.31, 0.64, 0)))
		h.prism(Vector3(0, 0, 0), 0.09, Vector3(0, 0.26, 0), 0.0, 4, iron.lightened(0.1), PI / 4.0)
		h.pop()
		h.box(Vector3(0, 0.705, 0), Vector3(0.6, 0.01, 0.22), _c("8a8c94"))
	), "anvil_mesh.tres")


# --- Cinder Goblin (enemy) ----------------------------------------------------
#
# A squat, hunched brute in the same construction style: barrel chest, long
# arms with big fists, short bowed legs, a heavy jaw and a painted face.

func _build_goblin() -> void:
	var SKIN := _c("8a4630")
	var SKIN_L := _c("a35a3c")
	var SKIN_D := _c("6a3222")
	var HIDE := _c("5c4733")
	var HIDE_D := _c("47372a")
	var IRON := _c("3d3d45")
	var IRON_L := _c("55555f")
	var RUST := _c("7e4a24")
	var BONE := _c("d8cdaa")
	var WOOD := _c("6b4a2a")
	var WOOD_D := _c("553a20")
	var SPIKE := _c("55555e")
	var EYE := _c("ffb12e")
	var WHITE := Color.WHITE

	_root = Node3D.new()
	_root.name = "CinderGoblinModel"
	_paths = {}
	var root := _root

	var hips := _joint(root, "hips", "Hips", Vector3(0, 0.55, 0), func(p: Parts) -> void:
		var k := p.k()
		# Hide loincloth over the hips, rope belt, and a hanging front flap.
		k.loft([[-0.16, 0.17, 0.15, HIDE_D], [-0.06, 0.18, 0.155, HIDE], [0.06, 0.18, 0.15, HIDE]], 9)
		k.loft([[0.0, 0.19, 0.16, RUST], [0.07, 0.185, 0.155, RUST]], 9)
		k.push(Transform3D(Basis(), Vector3(0, -0.14, -0.15)))
		k.loft([[-0.14, 0.08, 0.02, HIDE_D], [0.0, 0.1, 0.025, HIDE], [0.12, 0.09, 0.02, HIDE]], 4)
		k.pop()
	)
	var torso := _joint(hips, "torso", "Torso", Vector3(0, 0.06, 0), func(p: Parts) -> void:
		var k := p.k()
		# Barrel chest pitched forward, with a hump on the back.
		k.loft([
			[0.0, 0.18, 0.15, SKIN_D], [0.12, 0.22, 0.18, SKIN, Vector2(0, -0.02)],
			[0.26, 0.25, 0.185, SKIN_L, Vector2(0, -0.05)], [0.37, 0.23, 0.16, SKIN, Vector2(0, -0.08)],
			[0.45, 0.13, 0.11, SKIN_D, Vector2(0, -0.12)], [0.48, 0.0, 0.0, SKIN_D, Vector2(0, -0.13)],
		], 10)
		k.push(_aim(Vector3(0, 1, 0.2), Vector3(0, 0.16, 0.06)))
		k.loft([[0.0, 0.0, 0.0, SKIN_D], [0.06, 0.15, 0.09, SKIN_D], [0.2, 0.16, 0.1, SKIN], [0.3, 0.0, 0.0, SKIN]], 8)
		k.pop()
		# Crude iron chest plate and shoulder pads with bone spikes.
		var h := p.k("hard")
		h.slab(Vector3(0, 0.1, -0.175), Vector2(0.28, 0.04), Vector3(0, 0.36, -0.245), Vector2(0.36, 0.04), IRON)
		h.box(Vector3(0, 0.23, -0.225), Vector3(0.05, 0.05, 0.03), IRON_L)
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-18 * sx)), Vector3(0.25 * sx, 0.38, -0.07)))
			h.prism(Vector3(0, -0.04, 0), 0.12, Vector3(0, 0.05, 0), 0.075, 6, IRON)
			h.prism(Vector3(0, 0.05, 0), 0.035, Vector3(0, 0.17, 0), 0.0, 4, BONE)
			h.pop()
	)
	_joint(torso, "head", "Head", Vector3(0, 0.4, -0.16), func(p: Parts) -> void:
		# Head wrap with evenly spaced rings (4 cm) so the painted face lines up:
		# a broad jaw at the bottom, a heavy brow, and a low skull.
		var f := p.k("face_goblin")
		f.loft([
			[-0.02, 0.09, 0.07, WHITE, Vector2(0, -0.07)],
			[0.02, 0.15, 0.13, WHITE, Vector2(0, -0.05)],
			[0.06, 0.16, 0.15, WHITE, Vector2(0, -0.04)],
			[0.1, 0.15, 0.155, WHITE, Vector2(0, -0.035)],
			[0.14, 0.14, 0.16, WHITE, Vector2(0, -0.03)],
			[0.18, 0.15, 0.16, WHITE, Vector2(0, -0.025)],
			[0.22, 0.14, 0.15, WHITE, Vector2(0, -0.01)],
			[0.26, 0.11, 0.12, WHITE, Vector2(0, 0.0)],
			[0.3, 0.0, 0.0, WHITE, Vector2(0, 0.01)],
		], 10)
		var k := p.k()
		# Long pointed ears.
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(sx, 0.35, 0.3), Vector3(0.13 * sx, 0.16, 0.0)))
			k.loft([[0.0, 0.035, 0.06, SKIN_D], [0.06, 0.025, 0.045, SKIN], [0.16, 0.0, 0.0, SKIN_L]], 5)
			k.pop()
		var h := p.k("hard")
		# Iron skullcap with horns.
		h.prism(Vector3(0, 0.22, -0.01), 0.155, Vector3(0, 0.3, 0.0), 0.1, 8, IRON, PI / 8.0)
		h.prism(Vector3(0, 0.3, 0.0), 0.1, Vector3(0, 0.33, 0.01), 0.04, 8, IRON_L, PI / 8.0)
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-48.0 * sx)) * Basis(Vector3.RIGHT, deg_to_rad(-15)), Vector3(0.11 * sx, 0.27, 0.0)))
			h.prism(Vector3.ZERO, 0.045, Vector3(0, 0.12, 0), 0.03, 5, BONE)
			h.prism(Vector3(0, 0.12, 0), 0.03, Vector3(0, 0.22, -0.04), 0.0, 5, BONE)
			h.pop()
			# Lower tusks.
			h.prism(Vector3(0.075 * sx, 0.04, -0.18), 0.018, Vector3(0.085 * sx, 0.12, -0.2), 0.0, 4, BONE)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.box(Vector3(0.055 * sx, 0.155, -0.183), Vector3(0.05, 0.03, 0.01), EYE)
	)
	for side in [1.0, -1.0]:
		var sfx := "_r" if side > 0 else "_l"
		var nsfx := "R" if side > 0 else "L"
		var shoulder := _joint(torso, "shoulder" + sfx, "Shoulder" + nsfx, Vector3(0.29 * side, 0.3, -0.07), func(p: Parts) -> void:
			p.k().loft([
				[0.07, 0.0, 0.0, SKIN], [0.04, 0.085, 0.085, SKIN], [-0.06, 0.09, 0.088, SKIN_L],
				[-0.2, 0.072, 0.075, SKIN], [-0.27, 0.06, 0.062, SKIN_D], [-0.3, 0.0, 0.0, SKIN_D],
			], 7)
		)
		var elbow := _joint(shoulder, "elbow" + sfx, "Elbow" + nsfx, Vector3(0, -0.26, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([
				[0.04, 0.0, 0.0, SKIN_D], [0.01, 0.065, 0.065, SKIN], [-0.09, 0.075, 0.075, SKIN_L],
				[-0.24, 0.06, 0.06, SKIN], [-0.27, 0.0, 0.0, SKIN_D],
			], 7)
			# Rusty iron bracer.
			k.loft([[-0.09, 0.083, 0.083, RUST], [-0.2, 0.074, 0.074, _c("6a3c1c")]], 7)
		)
		var hand := _joint(elbow, "hand" + sfx, "Hand" + nsfx, Vector3(0, -0.26, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([
				[0.02, 0.05, 0.05, SKIN_D], [-0.03, 0.07, 0.075, SKIN_D], [-0.1, 0.068, 0.078, SKIN],
				[-0.14, 0.045, 0.055, SKIN_D], [-0.155, 0.0, 0.0, SKIN_D],
			], 6)
			var h := p.k("hard")
			for i in 3:
				h.prism(Vector3((i - 1) * 0.035, -0.13, -0.05), 0.014, Vector3((i - 1) * 0.04, -0.18, -0.08), 0.0, 4, BONE)
		)
		if side > 0:
			_attach(hand, "Club", Vector3(0, -0.07, 0), func(p: Parts) -> void:
				var k := p.k()
				k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
				k.loft([
					[-0.1, 0.03, 0.03, WOOD_D], [0.25, 0.04, 0.04, WOOD], [0.4, 0.07, 0.065, WOOD],
					[0.65, 0.095, 0.09, WOOD], [0.74, 0.08, 0.075, WOOD_D], [0.77, 0.0, 0.0, WOOD_D],
				], 7)
				k.pop()
				var h := p.k("hard")
				h.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
				for i in 5:
					var a := TAU * i / 5.0 + 0.4
					var d := Vector3(cos(a), 0, sin(a))
					var y := 0.5 + (i % 2) * 0.12
					h.prism(Vector3(0, y, 0) + d * 0.07, 0.022, Vector3(0, y + 0.03, 0) + d * 0.16, 0.0, 4, SPIKE)
				h.pop()
			, "club")
		var leg := _joint(hips, "leg" + sfx, "Leg" + nsfx, Vector3(0.12 * side, -0.12, 0), func(p: Parts) -> void:
			p.k().loft([
				[0.06, 0.0, 0.0, SKIN], [0.04, 0.085, 0.09, SKIN], [-0.06, 0.09, 0.095, SKIN_L],
				[-0.17, 0.07, 0.075, SKIN], [-0.23, 0.0, 0.0, SKIN_D],
			], 7)
		)
		var knee := _joint(leg, "knee" + sfx, "Knee" + nsfx, Vector3(0, -0.2, 0), func(p: Parts) -> void:
			p.k().loft([
				[0.04, 0.0, 0.0, SKIN_D], [0.02, 0.062, 0.066, SKIN], [-0.08, 0.06, 0.064, SKIN],
				[-0.17, 0.05, 0.055, SKIN_D], [-0.2, 0.0, 0.0, SKIN_D],
			], 7)
		)
		_joint(knee, "foot" + sfx, "Foot" + nsfx, Vector3(0, -0.18, 0), func(p: Parts) -> void:
			var k := p.k()
			k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
			k.loft([
				[-0.06, 0.05, 0.035, SKIN_D, Vector2(0, -0.015)], [-0.02, 0.07, 0.045, SKIN_D, Vector2(0, -0.01)],
				[0.1, 0.075, 0.04, SKIN, Vector2(0, -0.02)], [0.17, 0.06, 0.03, SKIN_D, Vector2(0, -0.03)],
				[0.19, 0.0, 0.0, SKIN_D, Vector2(0, -0.035)],
			], 6)
			k.pop()
			var h := p.k("hard")
			for i in 3:
				h.prism(Vector3((i - 1) * 0.045, -0.04, -0.16), 0.013, Vector3((i - 1) * 0.05, -0.05, -0.22), 0.0, 4, BONE)
		)

	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 0.55, 0)}
	_goblin_anims(lib, rest)
	_finish_character(root, lib)
	_save_scene(root, "cinder_goblin.tscn")


func _goblin_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var arm_r := Vector3(25, 0, 15)
	var elbow_r := Vector3(45, 0, 0)
	var hand_r := Vector3(-15, 0, 0)
	var arm_l := Vector3(15, 0, -15)
	var elbow_l := Vector3(30, 0, 0)
	var windup_r := Vector3(165, 0, 12)
	var smash_r := Vector3(55, 0, 6)

	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 1.2, true, {
		"hips@pos": [[0.0, V.call(0, 0.55, 0)], [0.6, V.call(0, 0.53, 0)]],
		"torso": [[0.0, V.call(-15, 0, 0)], [0.6, V.call(-20, 0, 0)]],
		"head": [[0.0, V.call(12, 0, 0)], [0.6, V.call(16, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.6, arm_r + V.call(5, 0, 0)]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l], [0.6, arm_l + V.call(5, 0, 0)]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(10, 0, 6)]], "knee_r": [[0.0, V.call(-20, 0, 0)]], "foot_r": [[0.0, V.call(10, 0, 0)]],
		"leg_l": [[0.0, V.call(10, 0, -6)]], "knee_l": [[0.0, V.call(-20, 0, 0)]], "foot_l": [[0.0, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "walk", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.53, 0)], [0.15, V.call(0, 0.57, 0)], [0.3, V.call(0, 0.53, 0)], [0.45, V.call(0, 0.57, 0)]],
		"hips": [[0.0, V.call(0, 0, 6)], [0.3, V.call(0, 0, -6)]],
		"torso": [[0.0, V.call(-25, 0, -4)], [0.3, V.call(-25, 0, 4)]],
		"head": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(35, 0, 4)], [0.15, V.call(10, 0, 4)], [0.3, V.call(-25, 0, 4)], [0.45, V.call(20, 0, 4)]],
		"knee_r": [[0.0, V.call(-15, 0, 0)], [0.15, V.call(-20, 0, 0)], [0.3, V.call(-30, 0, 0)], [0.45, V.call(-70, 0, 0)]],
		"leg_l": [[0.0, V.call(-25, 0, -4)], [0.15, V.call(20, 0, -4)], [0.3, V.call(35, 0, -4)], [0.45, V.call(10, 0, -4)]],
		"knee_l": [[0.0, V.call(-30, 0, 0)], [0.15, V.call(-70, 0, 0)], [0.3, V.call(-15, 0, 0)], [0.45, V.call(-20, 0, 0)]],
		"shoulder_r": [[0.0, V.call(5, 0, 15)], [0.3, V.call(45, 0, 15)]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(45, 0, -15)], [0.3, V.call(5, 0, -15)]], "elbow_l": [[0.0, elbow_l]],
	}, rest)
	_anim(lib, "alert", 0.45, false, {
		"hips@pos": [[0.0, V.call(0, 0.5, 0)], [0.15, V.call(0, 0.78, 0)], [0.3, V.call(0, 0.52, 0)], [0.45, V.call(0, 0.55, 0)]],
		"torso": [[0.0, V.call(-20, 0, 0)], [0.15, V.call(5, 0, 0)], [0.45, V.call(-15, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.15, V.call(-15, 0, 0)], [0.45, V.call(12, 0, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.15, V.call(130, 0, 35)], [0.45, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l], [0.15, V.call(130, 0, -35)], [0.45, arm_l]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(20, 0, 6)], [0.15, V.call(-5, 0, 6)], [0.3, V.call(20, 0, 6)]], "knee_r": [[0.0, V.call(-40, 0, 0)], [0.15, V.call(-10, 0, 0)], [0.3, V.call(-40, 0, 0)]],
		"leg_l": [[0.0, V.call(20, 0, -6)], [0.15, V.call(-5, 0, -6)], [0.3, V.call(20, 0, -6)]], "knee_l": [[0.0, V.call(-40, 0, 0)], [0.15, V.call(-10, 0, 0)], [0.3, V.call(-40, 0, 0)]],
	}, rest)
	# Telegraph: club raised high overhead and held.
	_anim(lib, "windup", 0.5, false, {
		"hips@pos": [[0.0, V.call(0, 0.55, 0)], [0.5, V.call(0, 0.52, 0.04)]],
		"torso": [[0.0, V.call(-15, 0, 0)], [0.5, V.call(12, 15, 0)]],
		"head": [[0.0, V.call(12, 0, 0)], [0.5, V.call(-5, -10, 0)]],
		"shoulder_r": [[0.0, arm_r], [0.5, windup_r]], "elbow_r": [[0.0, elbow_r], [0.5, V.call(55, 0, 0)]], "hand_r": [[0.0, hand_r], [0.5, V.call(-85, 0, 0)]],
		"shoulder_l": [[0.0, arm_l], [0.5, V.call(60, 0, -25)]], "elbow_l": [[0.0, elbow_l], [0.5, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(10, 0, 6)], [0.5, V.call(-15, 0, 6)]], "knee_r": [[0.0, V.call(-20, 0, 0)], [0.5, V.call(-20, 0, 0)]],
		"leg_l": [[0.0, V.call(10, 0, -6)], [0.5, V.call(30, 0, -6)]], "knee_l": [[0.0, V.call(-20, 0, 0)], [0.5, V.call(-35, 0, 0)]],
	}, rest)
	_anim(lib, "attack", 0.25, false, {
		"hips@pos": [[0.0, V.call(0, 0.52, 0.04)], [0.08, V.call(0, 0.47, -0.06)], [0.25, V.call(0, 0.47, -0.06)]],
		"torso": [[0.0, V.call(12, 15, 0)], [0.08, V.call(-40, -10, 0)], [0.25, V.call(-40, -10, 0)]],
		"head": [[0.0, V.call(-5, -10, 0)], [0.08, V.call(30, 0, 0)]],
		"shoulder_r": [[0.0, windup_r], [0.08, smash_r], [0.25, smash_r]], "elbow_r": [[0.0, V.call(55, 0, 0)], [0.08, V.call(10, 0, 0)]], "hand_r": [[0.0, V.call(-85, 0, 0)], [0.08, V.call(-105, 0, 0)]],
		"shoulder_l": [[0.0, V.call(60, 0, -25)], [0.08, V.call(-20, 0, -30)]], "elbow_l": [[0.0, V.call(20, 0, 0)]],
		"leg_r": [[0.0, V.call(-15, 0, 6)], [0.08, V.call(-25, 0, 6)]], "knee_r": [[0.0, V.call(-20, 0, 0)]],
		"leg_l": [[0.0, V.call(30, 0, -6)], [0.08, V.call(45, 0, -6)]], "knee_l": [[0.0, V.call(-35, 0, 0)], [0.08, V.call(-55, 0, 0)]],
	}, rest)
	_anim(lib, "recover", 0.6, false, {
		"hips@pos": [[0.0, V.call(0, 0.47, -0.06)], [0.6, V.call(0, 0.55, 0)]],
		"torso": [[0.0, V.call(-40, -10, 0)], [0.6, V.call(-15, 0, 0)]],
		"head": [[0.0, V.call(30, 0, 0)], [0.6, V.call(12, 0, 0)]],
		"shoulder_r": [[0.0, smash_r], [0.6, arm_r]], "elbow_r": [[0.0, V.call(10, 0, 0)], [0.6, elbow_r]], "hand_r": [[0.0, V.call(-105, 0, 0)], [0.6, hand_r]],
		"shoulder_l": [[0.0, V.call(-20, 0, -30)], [0.6, arm_l]], "elbow_l": [[0.0, V.call(20, 0, 0)], [0.6, elbow_l]],
		"leg_r": [[0.0, V.call(-25, 0, 6)], [0.6, V.call(10, 0, 6)]], "knee_r": [[0.0, V.call(-20, 0, 0)]],
		"leg_l": [[0.0, V.call(45, 0, -6)], [0.6, V.call(10, 0, -6)]], "knee_l": [[0.0, V.call(-55, 0, 0)], [0.6, V.call(-20, 0, 0)]],
	}, rest)
	_anim(lib, "hurt", 0.35, false, {
		"hips@pos": [[0.0, V.call(0, 0.53, 0.06)], [0.35, V.call(0, 0.55, 0)]],
		"torso": [[0.0, V.call(20, 0, 8)], [0.35, V.call(-15, 0, 0)]],
		"head": [[0.0, V.call(30, 0, 0)], [0.35, V.call(12, 0, 0)]],
		"shoulder_r": [[0.0, V.call(30, 0, 55)], [0.35, arm_r]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, V.call(30, 0, -55)], [0.35, arm_l]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(-10, 0, 6)], [0.35, V.call(10, 0, 6)]], "leg_l": [[0.0, V.call(25, 0, -6)], [0.35, V.call(10, 0, -6)]],
		"knee_r": [[0.0, V.call(-20, 0, 0)]], "knee_l": [[0.0, V.call(-30, 0, 0)], [0.35, V.call(-20, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.8, true, {
		"hips@pos": [[0.0, V.call(0, 0.52, 0)]],
		"torso": [[0.0, V.call(-10, 0, -12)], [0.4, V.call(-10, 0, 12)]],
		"head": [[0.0, V.call(5, 0, 15)], [0.4, V.call(5, 0, -15)]],
		"shoulder_r": [[0.0, V.call(0, 0, 10)], [0.4, V.call(5, 0, 18)]], "elbow_r": [[0.0, V.call(10, 0, 0)]], "hand_r": [[0.0, V.call(-50, 0, 0)]],
		"shoulder_l": [[0.0, V.call(5, 0, -18)], [0.4, V.call(0, 0, -10)]], "elbow_l": [[0.0, V.call(10, 0, 0)]],
		"leg_r": [[0.0, V.call(10, 0, 8)]], "knee_r": [[0.0, V.call(-25, 0, 0)]],
		"leg_l": [[0.0, V.call(10, 0, -8)]], "knee_l": [[0.0, V.call(-25, 0, 0)]],
	}, rest)
	_anim(lib, "death", 0.9, false, {
		"hips@pos": [[0.0, V.call(0, 0.55, 0)], [0.25, V.call(0, 0.5, 0.15)], [0.6, V.call(0, 0.18, 0.3)], [0.9, V.call(0, 0.16, 0.3)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.25, V.call(-15, 0, 0)], [0.6, V.call(-10, 0, 85)], [0.9, V.call(-10, 0, 88)]],
		"torso": [[0.0, V.call(-15, 0, 0)], [0.25, V.call(25, 0, 0)], [0.6, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(12, 0, 0)], [0.25, V.call(35, 0, 0)], [0.6, V.call(0, 0, 10)]],
		"shoulder_r": [[0.0, arm_r], [0.25, V.call(40, 0, 70)], [0.6, V.call(20, 0, 30)]], "elbow_r": [[0.0, elbow_r]], "hand_r": [[0.0, hand_r]],
		"shoulder_l": [[0.0, arm_l], [0.25, V.call(40, 0, -70)], [0.6, V.call(60, 0, -20)]], "elbow_l": [[0.0, elbow_l]],
		"leg_r": [[0.0, V.call(10, 0, 6)], [0.6, V.call(20, 0, 10)]], "knee_r": [[0.0, V.call(-20, 0, 0)], [0.6, V.call(-40, 0, 0)]],
		"leg_l": [[0.0, V.call(10, 0, -6)], [0.6, V.call(-5, 0, -4)]], "knee_l": [[0.0, V.call(-20, 0, 0)], [0.6, V.call(-10, 0, 0)]],
	}, rest)


# --- Small shared props -------------------------------------------------------

func _build_props(materials: Dictionary) -> void:
	# Blob shadow: a dark translucent octagon, the classic N64 character shadow.
	var k := MeshKit.new(5)
	var ring: Array = []
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		ring.append(Vector3(cos(a), 0, sin(a)) * 0.5)
	k.face_dir(ring, Color(0, 0, 0, 0.5), Vector3.UP)
	_save_res(k.build(materials.shadow), "blob_shadow_mesh.tres")

	# Lock-on marker: a spinning downward-pointing pyramid.
	var m := MeshKit.new(6)
	m.prism(Vector3(0, 0.0, 0), 0.0, Vector3(0, 0.3, 0), 0.16, 4, _c("ffd23a"))
	_save_res(m.build(materials.glow), "target_marker_mesh.tres")

	# Flame used by torches and the death "poof".
	var f := MeshKit.new(7)
	f.prism(Vector3(0, 0, 0), 0.12, Vector3(0, 0.12, 0), 0.14, 5, _c("ff7a1a"))
	f.prism(Vector3(0, 0.12, 0), 0.14, Vector3(0, 0.45, 0), 0.0, 5, _c("ffc23a"))
	_save_res(f.build(materials.glow), "flame_mesh.tres")

	# Arrow (EnArrow): shaft along -Z (its flight direction), steel head, red
	# and white fletching at the back. About 0.85 m long.
	var a := MeshKit.new(8)
	a.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	a.prism(Vector3(0, -0.42, 0), 0.008, Vector3(0, 0.36, 0), 0.008, 4, _c("b08a5a"))
	a.prism(Vector3(0, 0.36, 0), 0.022, Vector3(0, 0.45, 0), 0.0, 4, _c("a8acb4"))
	for i in 3:
		var ang := TAU * i / 3.0
		var d := Vector3(cos(ang), 0, sin(ang))
		var col := _c("c8302a") if i == 0 else _c("f0ece0")
		var vane := [Vector3(0, -0.42, 0), Vector3(0, -0.26, 0), Vector3(0, -0.3, 0) + d * 0.035, Vector3(0, -0.42, 0) + d * 0.035]
		a.face_dir(vane, col, Vector3(d.z, 0, -d.x))
		a.face_dir(vane, col, Vector3(-d.z, 0, d.x))
	a.pop()
	_save_res(a.build(materials.char), "arrow_mesh.tres")

	# A bundle of arrows for pickups: three shafts tied with a band.
	var bundle := MeshKit.new(9)
	for i in 3:
		var off := Vector3((i - 1) * 0.035, 0, (i % 2) * 0.03)
		bundle.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(65 + i * 8)), off))
		bundle.prism(Vector3(0, -0.3, 0), 0.012, Vector3(0, 0.25, 0), 0.012, 4, _c("c09a64"))
		bundle.prism(Vector3(0, 0.25, 0), 0.028, Vector3(0, 0.33, 0), 0.0, 4, _c("c0c4cc"))
		bundle.prism(Vector3(0, -0.34, 0), 0.03, Vector3(0, -0.24, 0), 0.03, 3, _c("e03a30"))
		bundle.pop()
	bundle.box(Vector3(0, 0, 0.015), Vector3(0.14, 0.05, 0.08), _c("6a4a2a"))
	_save_res(bundle.build(materials.glow), "arrow_bundle_mesh.tres")

	_build_gauntlet(materials)


# --- The Gauntlet of Fire -------------------------------------------------------

## The Gauntlet of Fire, heavily simplified from its concept art: a brown leather
## fist with a gold back plate and red diamond gem, four knuckle spikes, and three
## shingled gold cuff plates with red trim and pointed fronts. Points up (+Y from
## elbow to knuckles), back of the hand toward -Z. About 0.7 m tall.
## The title screen uses a render of it (tools/render_title_art.tscn).
func _build_gauntlet(materials: Dictionary) -> void:
	var k := MeshKit.new(11)
	k.shade_jitter = 0.04
	var gold := _c("f2c445")
	var gold_dark := _c("c48a26")
	var trim := _c("8e1a1c")
	var leather := _c("5e2c1c")
	var leather_dark := _c("3e1a12")
	var gem := _c("e01e2c")
	# Leather sleeve inside the cuff, so no gaps show between the plates.
	k.loft([[-0.01, 0.078, 0.06, leather_dark], [0.4, 0.074, 0.058, leather_dark]], 8)
	# Cuff plates from the elbow up; each one's flared lower edge overlaps the plate below.
	var plates := [
		[0.0, 0.15, Vector2(0.118, 0.092), Vector2(0.096, 0.074), 0.05],
		[0.12, 0.26, Vector2(0.108, 0.084), Vector2(0.088, 0.068), 0.045],
		[0.23, 0.37, Vector2(0.1, 0.078), Vector2(0.08, 0.062), 0.04],
	]
	for p: Array in plates:
		var y0: float = p[0]
		var y1: float = p[1]
		var r0: Vector2 = p[2]
		var r1: Vector2 = p[3]
		var dip: float = p[4]
		var rings: Array = [
			_cuff_ring(y0, r0, dip, 0.0),
			_cuff_ring(y0 + 0.014, r0.lerp(r1, 0.1), dip, 0.1),
			_cuff_ring(y0 + 0.015, r0.lerp(r1, 0.11), dip, 0.11),
			_cuff_ring(y1, r1, dip, 1.0),
		]
		var cols := [trim, trim, gold_dark, gold]
		_cuff_band(k, rings, cols, Vector3(0, (y0 + y1) * 0.5, 0))
		# A small red diamond stud above the point.
		var stud_y := y0 + 0.045
		var stud_z := -r0.lerp(r1, 0.3).y - 0.004
		_diamond(k, Vector3(0, stud_y, stud_z), Vector2(0.012, 0.02), 0.012, trim)
	# Wrist strap.
	k.loft([[0.36, 0.08, 0.064, leather_dark], [0.4, 0.08, 0.064, leather_dark]], 8)
	# The fist.
	k.loft([
		[0.38, 0.072, 0.058, leather], [0.44, 0.088, 0.07, leather], [0.52, 0.097, 0.078, leather],
		[0.6, 0.092, 0.075, leather], [0.645, 0.062, 0.052, leather_dark], [0.66, 0.0, 0.0, leather_dark],
	], 8)
	# Thumb guard on the side.
	k.icosa(Vector3(-0.098, 0.5, -0.02), Vector3(0.034, 0.052, 0.036), 0.08, gold_dark)
	# Back plate: gold, an inset red border, gold again, and the gem.
	k.box(Vector3(0, 0.515, -0.083), Vector3(0.205, 0.165, 0.024), gold_dark)
	k.box(Vector3(0, 0.515, -0.0955), Vector3(0.175, 0.135, 0.002), trim)
	k.box(Vector3(0, 0.515, -0.0975), Vector3(0.155, 0.115, 0.002), gold)
	_diamond(k, Vector3(0, 0.515, -0.0985), Vector2(0.036, 0.052), 0.036, gem)
	# Knuckle spikes along the top of the plate.
	for x in [-0.07, -0.024, 0.024, 0.07]:
		var base := Vector3(x, 0.585, -0.062)
		var tall := 0.085 if absf(x) < 0.05 else 0.07
		k.prism(base, 0.021, base + Vector3(x * 0.25, tall, -0.012), 0.0, 4, gold, PI / 4.0)
	k.smooth_normals(35.0)
	_save_res(k.build(materials.char), "gauntlet_mesh.tres")


## One ring of a cuff plate: an ellipse whose front (-Z) dips down by `dip`
## (scaled by `dip_k`) into the plate's pointed tip.
func _cuff_ring(y: float, r: Vector2, dip: float, dip_k: float) -> Array:
	var pts: Array = []
	for i in 12:
		var a := TAU * i / 12.0
		var front := maxf(cos(a), 0.0)
		pts.append(Vector3(sin(a) * r.x, y - dip * (1.0 - dip_k) * pow(front, 3.0), -cos(a) * r.y))
	return pts


## Joins the cuff rings into an open band (vertex color per ring).
func _cuff_band(k: MeshKit, rings: Array, cols: Array, center: Vector3) -> void:
	for ri in rings.size() - 1:
		var a: Array = rings[ri]
		var b: Array = rings[ri + 1]
		for i in a.size():
			var j := (i + 1) % a.size()
			k.tri_vc([a[i], a[j], b[j]], [cols[ri], cols[ri], cols[ri + 1]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], center)
			k.tri_vc([a[i], b[j], b[i]], [cols[ri], cols[ri + 1], cols[ri + 1]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], center)


## A faceted diamond (half an octahedron) facing -Z, centered at `c`:
## `half` is its half width and height, `depth` how far it stands out.
func _diamond(k: MeshKit, c: Vector3, half: Vector2, depth: float, col: Color) -> void:
	var rim := [c + Vector3(0, half.y, 0), c + Vector3(half.x, 0, 0), c + Vector3(0, -half.y, 0), c + Vector3(-half.x, 0, 0)]
	var apex := c + Vector3(0, 0, -depth)
	var inside := c + Vector3(0, 0, depth)
	for i in 4:
		var facet := col.lightened(0.15) if i < 2 else col.darkened(0.15)
		k.face([rim[i], rim[(i + 1) % 4], apex], facet, inside)


func _save_res(res: Resource, file: String) -> void:
	var err := ResourceSaver.save(res, MODEL_DIR + file)
	if err != OK:
		push_error("Failed to save %s: %s" % [file, err])


# --- Townsfolk: Ottilie, Marigold and Clover --------------------------------------
#
# Built like Pink and the Questlords (_build_woman, Mira's skeleton) with
# their own clothes and painted faces:
# - Ottilie keeps the Haven Library: an older lady, silver hair in a bun, round
#   spectacles, a long plum dress under a knitted moss-green cardigan, a book
#   always in her hand.
# - Marigold runs the general store in Haven Village: freckled, ginger hair in
#   two short bunches, a white blouse, a russet skirt and a long green apron.
# - Clover looks after the horses on the farm in the Southern Fields: tanned,
#   dark braids under a wide straw hat, a red checked shirt, blue overalls and
#   work boots.

func _build_townsfolk() -> void:
	_build_ottilie()
	_build_marigold()
	_build_clover()


func _simple_sleeve(cloth: Color, cloth_l: Color, cloth_d: Color, cuff: Color, skin: Color, skin_d: Color) -> Callable:
	return func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, cloth], [0.045, 0.06, 0.06, cloth], [-0.03, 0.066, 0.066, cloth_l],
			[-0.16, 0.05, 0.05, cloth], [-0.2, 0.054, 0.054, cuff], [-0.21, 0.038, 0.038, skin],
			[-0.25, 0.0, 0.0, skin_d],
		], 7)


func _simple_forearm(cloth: Color, cloth_l: Color, skin: Color) -> Callable:
	return func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, cloth], [0.01, 0.038, 0.038, cloth], [-0.14, 0.036, 0.037, cloth_l],
			[-0.17, 0.03, 0.03, skin], [-0.215, 0.0, 0.0, skin]], 6)


func _skirt_hips(skirt: Color, skirt_l: Color, skirt_d: Color, belt: Color, length: float) -> Callable:
	return func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-length, 0.25, 0.23, skirt_d], [-length + 0.04, 0.255, 0.235, skirt_d], [-length * 0.55, 0.225, 0.2, skirt],
			[-0.1, 0.18, 0.15, skirt_l], [0.03, 0.14, 0.115, skirt], [0.07, 0.13, 0.105, skirt],
		], 12)
		k.loft([[0.0, 0.142, 0.117, belt], [0.05, 0.136, 0.111, belt]], 12)


func _plain_leg(col: Color) -> Callable:
	return func(p: Parts, _side: float) -> void:
		p.k().loft([[0.05, 0.0, 0.0, col], [0.03, 0.066, 0.07, col], [-0.18, 0.058, 0.062, col], [-0.36, 0.046, 0.05, col], [-0.4, 0.0, 0.0, col]], 7)


func _plain_shin(col: Color, boot: Color, boot_d: Color) -> Callable:
	return func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, col], [0.01, 0.044, 0.048, col], [-0.2, 0.036, 0.04, col],
			[-0.24, 0.042, 0.046, boot], [-0.33, 0.036, 0.04, boot], [-0.35, 0.0, 0.0, boot_d]], 7)


## A head of hair: a cap over the crown, as on Mira and Aladriel.
func _hair_cap(k: MeshKit, hair: Color, hair_d: Color, hair_l: Color) -> void:
	k.loft([
		[0.03, 0.1, 0.1, hair_d, Vector2(0, 0.032)], [0.11, 0.13, 0.132, hair, Vector2(0, 0.026)],
		[0.19, 0.134, 0.136, hair_l, Vector2(0, 0.02)], [0.26, 0.126, 0.13, hair, Vector2(0, 0.014)],
		[0.31, 0.1, 0.108, hair, Vector2(0, 0.008)], [0.35, 0.0, 0.0, hair_l, Vector2(0, 0.004)],
	], 10)


func _build_ottilie() -> void:
	var SKIN := _c("f2d2bc")
	var SKIN_D := _c("dcb8a0")
	var DRESS := _c("6a2e5a")
	var DRESS_L := _c("7e3a6c")
	var DRESS_D := _c("521f44")
	var CARDI := _c("6a8a4a")
	var CARDI_L := _c("7e9e5a")
	var CARDI_D := _c("526e38")
	var HAIR := _c("d8d8e0")
	var HAIR_D := _c("b0b0bc")
	var HAIR_L := _c("f0f0f6")
	var SHOE := _c("3a2a22")
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.135, 0.108, CARDI_D], [0.1, 0.14, 0.11, CARDI], [0.19, 0.155, 0.122, CARDI_L, Vector2(0, -0.006)],
			[0.26, 0.152, 0.11, CARDI, Vector2(0, -0.003)], [0.31, 0.126, 0.094, CARDI],
			[0.34, 0.08, 0.07, DRESS], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# The dress showing between the cardigan's fronts, and its buttons.
		var h := p.k("hard")
		h.box(Vector3(0, 0.17, -0.118), Vector3(0.06, 0.28, 0.012), DRESS)
		for i in 4:
			h.box(Vector3(0.042, 0.06 + i * 0.07, -0.122), Vector3(0.016, 0.016, 0.01), _c("e8d8a0"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		# Hair swept back into a round bun high at the back.
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		k.icosa(Vector3(0, 0.3, 0.1), Vector3(0.075, 0.07, 0.07), 0.1, HAIR)
		# Round spectacles on her nose.
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			for i in 8:
				var a := TAU * i / 8.0
				h.box(Vector3(0.045 * sx + cos(a) * 0.026, 0.155 + sin(a) * 0.026, -0.123), Vector3(0.012, 0.012, 0.006), _c("b89038"))
		h.box(Vector3(0, 0.16, -0.125), Vector3(0.03, 0.006, 0.006), _c("b89038"))
	var extra := func(root: Node3D) -> void:
		# A red book held against her in her left hand.
		_attach(root.get_node(_paths["hand_l"]), "Book", Vector3(0, -0.08, -0.02), func(p: Parts) -> void:
			var h := p.k("hard")
			h.box(Vector3(0, 0, 0), Vector3(0.05, 0.2, 0.15), _c("8a2a2a"))
			h.box(Vector3(0.002, 0, 0), Vector3(0.042, 0.19, 0.14), _c("f0e8d0"))
		, "book")
	var look := {
		"hips": _skirt_hips(DRESS, DRESS_L, DRESS_D, CARDI_D, 0.74),
		"torso": torso, "head": head,
		"sleeve": _simple_sleeve(CARDI, CARDI_L, CARDI_D, CARDI_D, CARDI, CARDI_D),
		"forearm": _simple_forearm(CARDI, CARDI_L, SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(DRESS_D),
		"shin": _plain_shin(DRESS_D, SHOE, SHOE.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, SHOE, SHOE.darkened(0.3), 0.9),
		"extra": extra,
	}
	_build_woman("OttilieModel", "ottilie.tscn", "face_ottilie", SKIN, SKIN_D, look, _townsfolk_anims.bind(true), 0.96)


func _build_marigold() -> void:
	var SKIN := _c("f6d6c0")
	var SKIN_D := _c("e0bca4")
	var BLOUSE := _c("f6f2e8")
	var BLOUSE_L := _c("fffcf4")
	var BLOUSE_D := _c("dcd6c8")
	var SKIRT := _c("a04a2a")
	var SKIRT_L := _c("b85a36")
	var SKIRT_D := _c("803a20")
	var APRON := _c("4a8a4a")
	var APRON_D := _c("3a6e3a")
	var HAIR := _c("d0602a")
	var HAIR_D := _c("a8461c")
	var HAIR_L := _c("e8783a")
	var STOCK := _c("efe6d8")
	var SHOE := _c("6a3a22")
	var skirt := _skirt_hips(SKIRT, SKIRT_L, SKIRT_D, APRON_D, 0.6)
	var hips := func(p: Parts) -> void:
		skirt.call(p)
		# The long apron over the front of the skirt.
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(6)), Vector3(0, -0.24, -0.205)))
		h.box(Vector3.ZERO, Vector3(0.3, 0.52, 0.012), APRON)
		h.box(Vector3(0, 0.1, -0.008), Vector3(0.12, 0.09, 0.008), APRON_D)
		h.pop()
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.104, BLOUSE_D], [0.1, 0.135, 0.106, BLOUSE], [0.19, 0.155, 0.122, BLOUSE_L, Vector2(0, -0.008)],
			[0.26, 0.156, 0.112, BLOUSE, Vector2(0, -0.004)], [0.31, 0.128, 0.094, BLOUSE],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# The apron's bib and its straps.
		var h := p.k("hard")
		h.box(Vector3(0, 0.12, -0.13), Vector3(0.19, 0.2, 0.014), APRON)
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.075 * sx, 0.255, -0.108), Vector3(0.03, 0.1, 0.014), APRON)
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# Two short bunches tied low behind the ears with green ribbons.
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(0.5 * sx, -1, 0.4), Vector3(0.1 * sx, 0.08, 0.05)))
			k.loft([[0.0, 0.035, 0.035, HAIR], [0.06, 0.05, 0.05, HAIR_L], [0.13, 0.0, 0.0, HAIR_D]], 6)
			k.pop()
			p.k("hard").box(Vector3(0.1 * sx, 0.08, 0.05), Vector3(0.03, 0.03, 0.03), APRON)
	var forearm := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.2, 0.03, 0.03, SKIN], [-0.215, 0.0, 0.0, SKIN]], 6)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(BLOUSE, BLOUSE_L, BLOUSE_D, BLOUSE_D, SKIN, SKIN_D),
		"forearm": forearm,
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(STOCK),
		"shin": _plain_shin(STOCK, SHOE, SHOE.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, SHOE, SHOE.darkened(0.3)),
	}
	_build_woman("MarigoldModel", "marigold.tscn", "face_marigold", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 0.98)


func _build_clover() -> void:
	var SKIN := _c("b07a52")
	var SKIN_D := _c("946240")
	var SHIRT := _c("c8382e")
	var SHIRT_L := _c("e04a3a")
	var SHIRT_D := _c("a02a22")
	var DENIM := _c("3a5a9a")
	var DENIM_L := _c("4a6aae")
	var DENIM_D := _c("2c467a")
	var HAIR := _c("2a1c16")
	var HAIR_D := _c("1a100c")
	var HAIR_L := _c("3e2a20")
	var STRAW := _c("e8c870")
	var STRAW_D := _c("c8a450")
	var BOOT := _c("6a4428")
	var hips := func(p: Parts) -> void:
		p.k().loft([[-0.12, 0.13, 0.1, DENIM], [-0.05, 0.15, 0.115, DENIM], [0.06, 0.135, 0.105, DENIM_L]], 10)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.104, SHIRT_D], [0.1, 0.135, 0.106, SHIRT], [0.19, 0.155, 0.122, SHIRT_L, Vector2(0, -0.008)],
			[0.26, 0.156, 0.112, SHIRT, Vector2(0, -0.004)], [0.31, 0.128, 0.094, SHIRT],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		# The overalls' bib and straps.
		var h := p.k("hard")
		h.box(Vector3(0, 0.1, -0.125), Vector3(0.2, 0.2, 0.014), DENIM)
		h.box(Vector3(0, 0.12, -0.134), Vector3(0.08, 0.06, 0.006), DENIM_D)
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.075 * sx, 0.25, -0.105), Vector3(0.03, 0.12, 0.014), DENIM)
			h.box(Vector3(0.075 * sx, 0.2, -0.134), Vector3(0.02, 0.02, 0.008), _c("e0c050"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# Two braids over her shoulders.
		for sx in [-1.0, 1.0]:
			k.push(_aim(Vector3(0.15 * sx, -1, 0.1), Vector3(0.11 * sx, 0.08, 0.02)))
			k.loft([[0.0, 0.03, 0.03, HAIR], [0.1, 0.026, 0.026, HAIR_L], [0.2, 0.022, 0.022, HAIR], [0.26, 0.0, 0.0, HAIR_D]], 6)
			k.pop()
		# A wide straw hat with a red band.
		var h := p.k("hard")
		h.prism(Vector3(0, 0.27, 0), 0.25, Vector3(0, 0.285, 0), 0.25, 12, STRAW_D)
		h.prism(Vector3(0, 0.285, 0), 0.13, Vector3(0, 0.38, 0), 0.11, 10, STRAW)
		h.prism(Vector3(0, 0.29, 0), 0.132, Vector3(0, 0.32, 0), 0.128, 10, SHIRT)
	var forearm := func(p: Parts, _side: float) -> void:
		# Rolled-up sleeves.
		p.k().loft([[0.03, 0.0, 0.0, SHIRT_D], [0.01, 0.042, 0.042, SHIRT_D], [-0.04, 0.036, 0.036, SKIN], [-0.2, 0.031, 0.031, SKIN], [-0.215, 0.0, 0.0, SKIN]], 6)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(SHIRT, SHIRT_L, SHIRT_D, SHIRT_D, SHIRT, SHIRT_D),
		"forearm": forearm,
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(DENIM),
		"shin": _plain_shin(DENIM, BOOT, BOOT.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT.darkened(0.3), 1.05),
	}
	_build_woman("CloverModel", "clover.tscn", "face_clover", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 1.0)


## Standing folk: "idle" (a gentle sway; Ottilie, the `reader`, reads her
## book), "talk" (one hand chatting) and "happy" (a little bounce, hands clasped).
func _townsfolk_anims(lib: AnimationLibrary, rest: Dictionary, reader: bool) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	var hold_l: Vector3 = V.call(28, -22, 6) if reader else V.call(4, 0, -6)
	var hold_el: Vector3 = V.call(78, 0, 0) if reader else V.call(12, 0, 0)
	_anim(lib, "idle", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.2, V.call(0, 0.835, 0)]],
		"torso": [[0.0, V.call(0, 0, 0)], [1.2, V.call(-2, 0, 0)]],
		"head": [[0.0, V.call(-14 if reader else 0, 0, 0)], [1.2, V.call(-16 if reader else 3, 4, 0)]],
		"shoulder_r": [[0.0, V.call(4, 0, 6)], [1.2, V.call(6, 0, 8)]], "elbow_r": [[0.0, V.call(12, 0, 0)]],
		"shoulder_l": [[0.0, hold_l]], "elbow_l": [[0.0, hold_el]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(0, 0, -3)]],
	}, rest)
	_anim(lib, "talk", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"hips": [[0.0, V.call(0, 0, 2)]],
		"torso": [[0.0, V.call(0, -3, -1)], [0.8, V.call(-2, -1, -1)]],
		"head": [[0.0, V.call(0, 0, 4)], [0.4, V.call(-4, 4, 2)], [0.8, V.call(2, -3, 5)], [1.2, V.call(-3, 0, 3)]],
		"shoulder_r": [[0.0, V.call(45, 15, 12)], [0.4, V.call(62, 25, 18)], [0.8, V.call(40, 10, 10)], [1.2, V.call(58, 20, 16)]],
		"elbow_r": [[0.0, V.call(70, 0, 0)], [0.4, V.call(45, 0, 0)], [0.8, V.call(80, 0, 0)], [1.2, V.call(50, 0, 0)]],
		"shoulder_l": [[0.0, hold_l]], "elbow_l": [[0.0, hold_el]],
		"leg_r": [[0.0, V.call(0, 0, 3)]], "leg_l": [[0.0, V.call(5, 0, -3)]], "knee_l": [[0.0, V.call(-8, 0, 0)]],
	}, rest)
	_anim(lib, "happy", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.3, V.call(0, 0.865, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)]],
		"head": [[0.0, V.call(8, 0, -6)], [0.3, V.call(8, 0, 6)]],
		"shoulder_r": [[0.0, V.call(55, 35, -8)]], "elbow_r": [[0.0, V.call(120, 0, 0)]],
		"shoulder_l": [[0.0, V.call(55, -35, 8)]], "elbow_l": [[0.0, V.call(120, 0, 0)]],
	}, rest)


# --- Hilde -----------------------------------------------------------------------
#
# The keeper of the mountain hut on Frostpeak, who sells warm clothes to
# travelers foolish enough to come up the peak. Sturdy and weathered, at 1.7 m:
# a long coat of deep blue wool trimmed with white fur at the hem, cuffs and
# collar, a wide leather belt, thick gray trousers tucked into fur-topped
# boots, mittens, and a round fur hat over a long gray-blonde braid. The face
# (gen_media.gd _face_hilde): ruddy cheeks, pale blue eyes, a wry smile.

func _build_hilde() -> void:
	var SKIN := _c("f0c8b0")
	var SKIN_D := _c("d8aa92")
	var COAT := _c("2e4a7a")
	var COAT_L := _c("3a5a90")
	var COAT_D := _c("223860")
	var FUR := _c("f2f0ea")
	var FUR_D := _c("d8d4cc")
	var BELT := _c("5a3a22")
	var TROUSER := _c("6a6a70")
	var BOOT := _c("4a3424")
	var HAIR := _c("c8bc98")
	var HAIR_D := _c("a89c7a")
	var HAIR_L := _c("e0d6b4")
	var coat_hips := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.6, 0.27, 0.24, FUR_D], [-0.55, 0.27, 0.245, FUR], [-0.5, 0.25, 0.225, COAT_D], [-0.3, 0.23, 0.2, COAT],
			[-0.08, 0.19, 0.16, COAT_L], [0.03, 0.15, 0.12, COAT], [0.07, 0.14, 0.11, COAT],
		], 12)
		k.loft([[0.0, 0.152, 0.124, BELT], [0.06, 0.146, 0.118, BELT]], 12)
		p.k("hard").box(Vector3(0, 0.03, -0.125), Vector3(0.05, 0.04, 0.012), _c("b8a060"))
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.14, 0.11, COAT_D], [0.1, 0.145, 0.112, COAT], [0.19, 0.165, 0.128, COAT_L, Vector2(0, -0.008)],
			[0.26, 0.166, 0.118, COAT, Vector2(0, -0.004)], [0.31, 0.135, 0.1, FUR_D],
			[0.35, 0.1, 0.09, FUR], [0.37, 0.06, 0.06, SKIN],
		], 10)
		# Toggles down the front.
		var h := p.k("hard")
		for i in 3:
			h.box(Vector3(0, 0.08 + i * 0.07, -0.128), Vector3(0.05, 0.014, 0.014), _c("d8c8a0"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# The round fur hat.
		k.loft([[0.2, 0.135, 0.14, FUR_D], [0.24, 0.14, 0.145, FUR], [0.33, 0.13, 0.135, FUR], [0.39, 0.0, 0.0, FUR_D]], 10)
		# The long braid down her back.
		for i in 6:
			var t := float(i) / 6.0
			k.icosa(Vector3(0, 0.04 - i * 0.075, 0.13 + t * 0.03), Vector3(0.032, 0.04, 0.032) * (1.0 - t * 0.3), 0.0, HAIR if i % 2 == 0 else HAIR_L)
		k.icosa(Vector3(0, -0.41, 0.16), Vector3(0.024, 0.02, 0.024), 0.0, _c("8a3030"))
	var sleeve := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, COAT], [0.045, 0.066, 0.066, COAT], [-0.03, 0.072, 0.072, COAT_L],
			[-0.17, 0.062, 0.062, COAT], [-0.2, 0.07, 0.07, FUR], [-0.23, 0.066, 0.066, FUR_D], [-0.25, 0.0, 0.0, COAT_D],
		], 7)
	var forearm := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, COAT], [0.01, 0.045, 0.045, COAT], [-0.15, 0.042, 0.042, COAT_L], [-0.17, 0.05, 0.05, FUR], [-0.215, 0.0, 0.0, FUR_D]], 6)
	var look := {
		"hips": coat_hips, "torso": torso, "head": head,
		"sleeve": sleeve, "forearm": forearm,
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, _c("8a2a2a"), _c("6a1a1a")),
		"thigh": _plain_leg(TROUSER),
		"shin": func(p: Parts, _side: float) -> void:
			p.k().loft([[0.03, 0.0, 0.0, TROUSER], [0.01, 0.046, 0.05, TROUSER], [-0.16, 0.04, 0.044, TROUSER],
				[-0.18, 0.06, 0.064, FUR], [-0.22, 0.056, 0.06, FUR_D], [-0.24, 0.046, 0.05, BOOT], [-0.33, 0.042, 0.046, BOOT], [-0.35, 0.0, 0.0, BOOT.darkened(0.3)]], 7),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT.darkened(0.3), 1.1),
	}
	_build_woman("HildeModel", "hilde.tscn", "face_hilde", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 1.02)


# --- Tansy -----------------------------------------------------------------------
#
# A Castle Town street sharp who runs a cup-and-ball game for coins, then a
# refugee in Himeko's palace (still running it). Small and quick, at 1.58 m:
# a red-and-white striped cap over short auburn hair, a green waistcoat over a
# cream shirt with rolled sleeves, a short brown skirt, striped stockings and
# scuffed boots. The face (gen_media.gd _face_tansy): freckles, green eyes,
# a sly grin.

func _build_tansy() -> void:
	var SKIN := _c("f4d4bc")
	var SKIN_D := _c("dcb8a0")
	var SHIRT := _c("f0e8d4")
	var SHIRT_D := _c("d4cab4")
	var VEST := _c("2e6a3e")
	var VEST_L := _c("3a7e4c")
	var VEST_D := _c("22502e")
	var SKIRT := _c("6a4a30")
	var SKIRT_L := _c("7e5a3a")
	var SKIRT_D := _c("523622")
	var HAIR := _c("a8482a")
	var HAIR_D := _c("84361e")
	var HAIR_L := _c("c4603a")
	var STRIPE_A := _c("c83a3a")
	var STRIPE_B := _c("f0ece4")
	var BOOT := _c("4a3020")
	var hips := _skirt_hips(SKIRT, SKIRT_L, SKIRT_D, VEST_D, 0.34)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.104, VEST_D], [0.1, 0.135, 0.106, VEST], [0.19, 0.152, 0.12, VEST_L, Vector2(0, -0.008)],
			[0.26, 0.152, 0.11, VEST, Vector2(0, -0.004)], [0.31, 0.124, 0.092, SHIRT_D],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.2, -0.122), Vector3(0.05, 0.16, 0.01), SHIRT)
		for i in 3:
			h.box(Vector3(0.03, 0.06 + i * 0.06, -0.112), Vector3(0.018, 0.018, 0.01), _c("d8b050"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR_D, HAIR_L)
		# The striped cap, its peak tipped forward.
		for i in 4:
			var y := 0.24 + i * 0.03
			k.loft([[y, 0.14 - i * 0.012, 0.145 - i * 0.012, STRIPE_A if i % 2 == 0 else STRIPE_B], [y + 0.03, 0.13 - i * 0.012, 0.135 - i * 0.012, STRIPE_A if i % 2 == 0 else STRIPE_B]], 10)
		k.loft([[0.36, 0.08, 0.085, STRIPE_A], [0.38, 0.0, 0.0, STRIPE_A]], 10)
		p.k("hard").box(Vector3(0, 0.25, -0.15), Vector3(0.16, 0.012, 0.08), STRIPE_A.darkened(0.2))
		k.icosa(Vector3(0, 0.4, 0), Vector3(0.025, 0.025, 0.025), 0.0, STRIPE_B)
	var sleeve := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, SHIRT], [0.045, 0.058, 0.058, SHIRT], [-0.03, 0.062, 0.062, SHIRT],
			[-0.14, 0.055, 0.055, SHIRT_D], [-0.17, 0.058, 0.058, SHIRT_D], [-0.18, 0.036, 0.036, SKIN], [-0.24, 0.0, 0.0, SKIN_D],
		], 7)
	var forearm := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, SKIN], [0.01, 0.034, 0.034, SKIN], [-0.2, 0.03, 0.03, SKIN], [-0.215, 0.0, 0.0, SKIN]], 6)
	var striped := func(p: Parts, _side: float) -> void:
		var rings: Array = [[0.05, 0.0, 0.0, STRIPE_B]]
		for i in 6:
			rings.append([0.03 - i * 0.07, 0.064 - i * 0.003, 0.068 - i * 0.003, STRIPE_A if i % 2 == 0 else STRIPE_B])
		rings.append([-0.4, 0.0, 0.0, STRIPE_A])
		p.k().loft(rings, 7)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": sleeve, "forearm": forearm,
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": striped,
		"shin": _plain_shin(STRIPE_B, BOOT, BOOT.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT.darkened(0.3)),
	}
	_build_woman("TansyModel", "tansy.tscn", "face_tansy", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 0.94)


# --- The people of Ashwick (Beta 1.1.0) -------------------------------------------
#
# The last of the Batela folk, camped on the Fells after Firebuns burned his
# own land. Elder Maud keeps the camp; Wren keeps its graves; Odile wore the
# king's colors once; Tamsin is ten and not afraid of anything.

func _build_ashwick() -> void:
	_build_maud()
	_build_wren()
	_build_odile()
	_build_tamsin()


# Elder Maud: small and bent with age, at 1.55 m: a long dress of dark moss
# wool, a shawl in the faded red of old Batela, a gray headscarf over a white
# bun, a walking apron with pockets. The face (gen_media.gd _face_maud): lined,
# gray eyes, a tired mouth.
func _build_maud() -> void:
	var SKIN := _c("e8c4a8")
	var SKIN_D := _c("cca68c")
	var DRESS := _c("44483a")
	var DRESS_L := _c("525844")
	var DRESS_D := _c("34382c")
	var SHAWL := _c("7a3a2e")
	var SHAWL_D := _c("5e2a22")
	var APRON := _c("a89a80")
	var SCARF := _c("7a7874")
	var HAIR := _c("e8e6e0")
	var hips := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.62, 0.24, 0.22, DRESS_D], [-0.58, 0.245, 0.225, DRESS_D], [-0.3, 0.215, 0.19, DRESS],
			[-0.08, 0.18, 0.15, DRESS_L], [0.03, 0.14, 0.115, DRESS], [0.07, 0.13, 0.105, DRESS],
		], 12)
		var h := p.k("hard")
		h.box(Vector3(0, -0.2, -0.19), Vector3(0.2, 0.36, 0.01), APRON)
		h.box(Vector3(0.05, -0.28, -0.196), Vector3(0.08, 0.07, 0.008), APRON.darkened(0.15))
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.105, DRESS_D], [0.1, 0.135, 0.108, DRESS], [0.18, 0.15, 0.12, SHAWL_D, Vector2(0, 0.01)],
			[0.25, 0.158, 0.122, SHAWL, Vector2(0, 0.014)], [0.31, 0.13, 0.1, SHAWL],
			[0.35, 0.072, 0.064, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		p.k("hard").box(Vector3(0, 0.27, -0.125), Vector3(0.03, 0.03, 0.012), _c("b8a060"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.12), HAIR)
		# The headscarf, tied back, and the bun peeking out under it.
		k.loft([[0.16, 0.14, 0.145, SCARF.darkened(0.1)], [0.24, 0.142, 0.148, SCARF], [0.33, 0.12, 0.128, SCARF], [0.37, 0.0, 0.0, SCARF.darkened(0.1)]], 10)
		k.icosa(Vector3(0, 0.12, 0.14), Vector3(0.06, 0.055, 0.05), 0.0, HAIR)
		k.icosa(Vector3(0, 0.2, 0.15), Vector3(0.035, 0.05, 0.02), 0.0, SCARF.darkened(0.15))
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(SHAWL, SHAWL, SHAWL_D, DRESS_D, SKIN, SKIN_D),
		"forearm": _simple_forearm(DRESS, DRESS_L, SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(DRESS_D),
		"shin": _plain_shin(DRESS_D, _c("3a2a20"), _c("2a1e16")),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, _c("3a2a20"), _c("2a1e16")),
	}
	_build_woman("MaudModel", "maud.tscn", "face_maud", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 0.93)


# Wren, the gravekeeper: tall and thin, at 1.74 m: a long hooded cloak of
# charcoal wool over a gray smock, dark trousers and muddy boots, a spade
# badge pinned at the throat. The face (gen_media.gd _face_wren): pale, dark
# hair under the hood, heavy-lidded, a small sad smile.
func _build_wren() -> void:
	var SKIN := _c("f0d8c8")
	var SKIN_D := _c("d4baa8")
	var CLOAK := _c("383a42")
	var CLOAK_L := _c("464852")
	var CLOAK_D := _c("2a2c32")
	var SMOCK := _c("7a7a74")
	var TROUSER := _c("3a3632")
	var BOOT := _c("3a2a1e")
	var HAIR := _c("2a2226")
	var hips := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.7, 0.26, 0.24, CLOAK_D], [-0.66, 0.265, 0.245, CLOAK], [-0.35, 0.235, 0.21, CLOAK],
			[-0.1, 0.185, 0.16, CLOAK_L], [0.03, 0.145, 0.12, CLOAK], [0.07, 0.135, 0.11, CLOAK],
		], 12)
		p.k("hard").box(Vector3(0, -0.3, -0.21), Vector3(0.16, 0.56, 0.01), SMOCK)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.105, CLOAK_D], [0.1, 0.132, 0.106, CLOAK], [0.19, 0.15, 0.118, CLOAK_L, Vector2(0, -0.006)],
			[0.26, 0.152, 0.112, CLOAK], [0.31, 0.13, 0.098, CLOAK_D],
			[0.35, 0.07, 0.062, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.12, -0.124), Vector3(0.07, 0.18, 0.01), SMOCK)
		h.box(Vector3(0, 0.3, -0.118), Vector3(0.025, 0.04, 0.01), _c("a8acb4"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.2), HAIR.lightened(0.15))
		# The hood, pushed back off the brow.
		k.loft([[0.0, 0.15, 0.16, CLOAK_D, Vector2(0, 0.05)], [0.12, 0.155, 0.165, CLOAK, Vector2(0, 0.04)],
			[0.26, 0.15, 0.158, CLOAK_L, Vector2(0, 0.03)], [0.36, 0.11, 0.12, CLOAK, Vector2(0, 0.03)], [0.4, 0.0, 0.0, CLOAK_D, Vector2(0, 0.04)]], 10)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(CLOAK, CLOAK_L, CLOAK_D, CLOAK_D, SKIN, SKIN_D),
		"forearm": _simple_forearm(SMOCK, SMOCK.lightened(0.1), SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, _c("5a5048"), _c("443c36")),
		"thigh": _plain_leg(TROUSER),
		"shin": _plain_shin(TROUSER, BOOT, BOOT.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT.darkened(0.3), 1.05),
	}
	_build_woman("WrenModel", "wren.tscn", "face_wren", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 1.04)


# Odile, once a guard of Batela Keep: broad and scarred, at 1.76 m: a dented
# breastplate over chainmail, a tabard in the Firebuns red with a flame worn
# almost away, leather bracers, gray trousers and greaves. Short black hair.
# The face (gen_media.gd _face_odile): a scar through one brow, hard brown eyes.
func _build_odile() -> void:
	var SKIN := _c("c8946e")
	var SKIN_D := _c("aa785a")
	var STEEL := _c("8a8c94")
	var STEEL_L := _c("a8aab2")
	var STEEL_D := _c("5e6068")
	var MAIL := _c("6a6c72")
	var TABARD := _c("6a1e1a")
	var TABARD_D := _c("4e1612")
	var LEATHER := _c("6a4a30")
	var TROUSER := _c("5a5a5e")
	var HAIR := _c("1e1a1a")
	var hips := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.34, 0.2, 0.18, MAIL.darkened(0.1)], [-0.3, 0.2, 0.18, MAIL], [-0.1, 0.18, 0.155, MAIL],
			[0.03, 0.15, 0.125, MAIL], [0.07, 0.14, 0.115, MAIL],
		], 12)
		k.loft([[0.0, 0.152, 0.127, LEATHER], [0.05, 0.146, 0.121, LEATHER]], 12)
		var h := p.k("hard")
		h.box(Vector3(0, -0.18, -0.17), Vector3(0.18, 0.4, 0.01), TABARD)
		h.box(Vector3(0, -0.18, 0.17), Vector3(0.18, 0.4, 0.01), TABARD_D)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.145, 0.118, STEEL_D], [0.1, 0.15, 0.12, STEEL], [0.19, 0.17, 0.132, STEEL_L, Vector2(0, -0.01)],
			[0.26, 0.17, 0.122, STEEL, Vector2(0, -0.004)], [0.31, 0.14, 0.104, STEEL_D],
			[0.35, 0.08, 0.07, MAIL], [0.37, 0.054, 0.054, SKIN],
		], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.14, -0.136), Vector3(0.14, 0.2, 0.012), TABARD)
		# The Firebuns flame, almost worn away.
		h.box(Vector3(0, 0.16, -0.143), Vector3(0.04, 0.08, 0.005), _c("a86a3a"))
		for s in [-1.0, 1.0]:
			h.box(Vector3(s * 0.12, 0.3, 0), Vector3(0.1, 0.05, 0.14), STEEL)
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.2), HAIR.lightened(0.2))
	var bracer := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, MAIL], [0.01, 0.042, 0.042, MAIL], [-0.04, 0.046, 0.046, LEATHER],
			[-0.15, 0.044, 0.044, LEATHER], [-0.17, 0.034, 0.034, SKIN], [-0.215, 0.0, 0.0, SKIN]], 6)
	var greave := func(p: Parts, _side: float) -> void:
		p.k().loft([[0.03, 0.0, 0.0, TROUSER], [0.01, 0.048, 0.052, STEEL_D], [-0.18, 0.044, 0.048, STEEL],
			[-0.24, 0.046, 0.05, LEATHER], [-0.33, 0.04, 0.044, LEATHER], [-0.35, 0.0, 0.0, LEATHER.darkened(0.3)]], 7)
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(MAIL, MAIL.lightened(0.1), MAIL.darkened(0.1), STEEL, MAIL, MAIL),
		"forearm": bracer,
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, LEATHER, LEATHER.darkened(0.2)),
		"thigh": _plain_leg(TROUSER),
		"shin": greave,
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, LEATHER, LEATHER.darkened(0.3), 1.1),
	}
	_build_woman("OdileModel", "odile.tscn", "face_odile", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 1.05)


# Tamsin: ten years old, at about 1.15 m: a patched green smock dress over
# brown leggings, a too-big knitted cardigan, scuffed little boots, and a
# mop of brown hair. The face (gen_media.gd _face_tamsin): freckles, big
# eyes, a gap-toothed grin.
func _build_tamsin() -> void:
	var SKIN := _c("f4d6c0")
	var SKIN_D := _c("dcbaa4")
	var SMOCK := _c("6a7a4a")
	var SMOCK_L := _c("7a8a58")
	var SMOCK_D := _c("54603a")
	var KNIT := _c("a8846a")
	var KNIT_D := _c("8a6a54")
	var LEG := _c("5a4434")
	var BOOT := _c("4a3424")
	var HAIR := _c("6a4428")
	var hips := _skirt_hips(SMOCK, SMOCK_L, SMOCK_D, SMOCK_D, 0.3)
	var torso := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.13, 0.105, KNIT_D], [0.1, 0.135, 0.108, KNIT], [0.19, 0.15, 0.12, KNIT, Vector2(0, -0.006)],
			[0.26, 0.15, 0.112, KNIT], [0.31, 0.124, 0.094, KNIT_D],
			[0.35, 0.07, 0.062, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 10)
		var h := p.k("hard")
		h.box(Vector3(0, 0.15, -0.124), Vector3(0.08, 0.2, 0.01), SMOCK)
		h.box(Vector3(-0.07, 0.08, -0.12), Vector3(0.05, 0.05, 0.01), _c("8a5a7a"))
	var head := func(p: Parts) -> void:
		var k := p.k()
		_hair_cap(k, HAIR, HAIR.darkened(0.2), HAIR.lightened(0.2))
		# A mop of curls.
		for i in 7:
			var a := TAU * i / 7.0
			k.icosa(Vector3(cos(a) * 0.11, 0.24 + (i % 2) * 0.04, sin(a) * 0.11), Vector3(0.05, 0.05, 0.05), 0.0, HAIR if i % 2 == 0 else HAIR.lightened(0.15))
	var look := {
		"hips": hips, "torso": torso, "head": head,
		"sleeve": _simple_sleeve(KNIT, KNIT, KNIT_D, KNIT_D, SKIN, SKIN_D),
		"forearm": _simple_forearm(KNIT, KNIT, SKIN),
		"hand": func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D),
		"thigh": _plain_leg(LEG),
		"shin": _plain_shin(LEG, BOOT, BOOT.darkened(0.3)),
		"foot": func(p: Parts, _side: float) -> void: _lady_foot(p, BOOT, BOOT.darkened(0.3)),
	}
	_build_woman("TamsinModel", "tamsin.tscn", "face_tamsin", SKIN, SKIN_D, look, _townsfolk_anims.bind(false), 0.68)


# --- Himeko ---------------------------------------------------------------------
#
# The self-styled Princess of Haven Village (she is not one). Built like the
# townsfolk (_build_woman) at 1.66 m: a crimson furisode kimono with long
# swinging sleeves and sakura scattered over its hem, a broad gold obi tied in
# a big bow at the back, a white under-collar, white tabi and red zori. Glossy
# black hair to her waist in a hime cut (the blunt bangs are painted, the side
# locks cut square at her cheeks), a kanzashi of red blossoms with gold
# dangles over her right ear, and an open folding fan always in her right hand.
# The face (gen_media.gd _face_himeko): big brown eyes, lids lowered a touch,
# a pleased one-sided smile.

func _build_himeko() -> void:
	var SKIN := _c("fae6d8")
	var SKIN_D := _c("ead0be")
	var KIMONO := _c("b8182a")
	var KIMONO_L := _c("d02a3a")
	var KIMONO_D := _c("8a1020")
	var LINING := _c("f4a0b8")
	var OBI := _c("e0b84a")
	var OBI_L := _c("f4d878")
	var OBI_D := _c("b08a2a")
	var COLLAR := _c("f8f4ee")
	var SAKURA := _c("ffc8d8")
	var SAKURA_D := _c("f08aa8")
	var HAIR := _c("16141c")
	var HAIR_D := _c("0a090e")
	var HAIR_L := _c("34304a")
	var TABI := _c("f8f6f0")
	var ZORI := _c("c8203a")
	var _hips_part := func(p: Parts) -> void:
		var k := p.k()
		# The kimono's skirt: a straight column to the ankles, the pink lining
		# showing at the hem.
		k.loft([
			[-0.8, 0.168, 0.15, LINING], [-0.78, 0.172, 0.154, KIMONO_D], [-0.6, 0.18, 0.162, KIMONO],
			[-0.32, 0.188, 0.166, KIMONO_L], [-0.08, 0.162, 0.134, KIMONO], [0.07, 0.135, 0.11, KIMONO],
		], 14)
		# The front panel's edge, slanting across (left over right).
		var h := p.k("hard")
		h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-8)), Vector3(0.04, -0.38, -0.168)))
		h.box(Vector3.ZERO, Vector3(0.012, 0.82, 0.008), KIMONO_D)
		h.pop()
		# Sakura blossoms over the hem: five petals round a darker heart.
		var rng := RandomNumberGenerator.new()
		rng.seed = 91
		for i in 26:
			var a := rng.randf() * TAU
			var y := rng.randf_range(-0.76, -0.46)
			var t := inverse_lerp(-0.8, -0.32, y)
			var c := Vector3(sin(a) * (lerpf(0.172, 0.188, t) + 0.003), y, -cos(a) * (lerpf(0.154, 0.166, t) + 0.003))
			var sz := rng.randf_range(0.012, 0.02)
			h.push(_aim(Vector3(c.x, 0, c.z), c))
			for j in 5:
				var pa := TAU * j / 5.0
				h.box(Vector3(cos(pa) * sz, sin(pa) * sz, 0), Vector3(sz * 0.9, sz * 0.9, 0.003), SAKURA)
			h.box(Vector3.ZERO, Vector3(sz * 0.6, sz * 0.6, 0.004), SAKURA_D)
			h.pop()
	var _torso_part := func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[0.0, 0.142, 0.115, OBI_D], [0.02, 0.15, 0.122, OBI], [0.15, 0.152, 0.124, OBI_L], [0.17, 0.146, 0.118, OBI_D],
			[0.19, 0.15, 0.116, KIMONO_L, Vector2(0, -0.006)], [0.26, 0.15, 0.108, KIMONO, Vector2(0, -0.003)], [0.31, 0.124, 0.092, KIMONO],
			[0.35, 0.075, 0.065, SKIN_D], [0.37, 0.05, 0.05, SKIN],
		], 12)
		var h := p.k("hard")
		# The collar crossing left over right, white under-collar inside.
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(24.0 * sx)), Vector3(0.03 * sx, 0.28, -0.1)))
			h.box(Vector3.ZERO, Vector3(0.03, 0.15, 0.012), COLLAR)
			h.box(Vector3(0.022 * sx, -0.005, -0.002), Vector3(0.016, 0.15, 0.012), KIMONO_D)
			h.pop()
		# The obi's red cord and its knot in front.
		h.loft([[0.085, 0.154, 0.126, KIMONO], [0.095, 0.154, 0.126, KIMONO]], 12, false)
		h.icosa(Vector3(0, 0.09, -0.13), Vector3(0.022, 0.018, 0.014), 0.0, KIMONO_L)
		# The big bow at the back: two wings and the knot, and its tails.
		for sx in [-1.0, 1.0]:
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(18.0 * sx)), Vector3(0.09 * sx, 0.11, 0.15)))
			h.box(Vector3.ZERO, Vector3(0.16, 0.11, 0.05), OBI)
			h.box(Vector3(0, 0, 0.026), Vector3(0.14, 0.02, 0.004), OBI_D)
			h.pop()
			h.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-10.0 * sx)), Vector3(0.04 * sx, -0.06, 0.145)))
			h.box(Vector3.ZERO, Vector3(0.06, 0.2, 0.02), OBI_L)
			h.pop()
		h.box(Vector3(0, 0.11, 0.17), Vector3(0.06, 0.08, 0.05), OBI_D)
	var _head_part := func(p: Parts) -> void:
		var k := p.k()
		# Long black hair to her waist.
		_long_hair(k, HAIR, HAIR_D, HAIR_L, 0.62, 0.15, 0.02)
		# Hime cut: the side locks fall straight past her cheeks, cut square.
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.118 * sx, 0.15, -0.035), Vector3(0.026, 0.22, 0.075), HAIR)
			h.box(Vector3(0.121 * sx, 0.15, -0.035), Vector3(0.022, 0.21, 0.02), HAIR_L)
		# The kanzashi over her right ear: red blossoms, a gold comb, dangles.
		h.box(Vector3(-0.12, 0.28, 0.02), Vector3(0.012, 0.03, 0.09), OBI)
		for i in 3:
			var c := Vector3(-0.125, 0.29 + (i % 2) * 0.03, -0.01 + i * 0.03)
			for j in 5:
				var a := TAU * j / 5.0
				h.box(c + Vector3(0, cos(a) * 0.016, sin(a) * 0.016), Vector3(0.008, 0.016, 0.016), KIMONO_L if i != 1 else SAKURA)
			h.box(c + Vector3(-0.004, 0, 0), Vector3(0.008, 0.01, 0.01), OBI_L)
		for i in 3:
			h.box(Vector3(-0.13, 0.23 - i * 0.012, 0.0 + i * 0.022), Vector3(0.004, 0.08 + i * 0.02, 0.004), OBI_L)
	var _sleeve_part := func(p: Parts, _side: float) -> void:
		p.k().loft([
			[0.06, 0.0, 0.0, KIMONO], [0.045, 0.064, 0.064, KIMONO], [-0.03, 0.072, 0.072, KIMONO_L],
			[-0.16, 0.078, 0.078, KIMONO], [-0.25, 0.082, 0.082, KIMONO_D],
		], 8)
	var _forearm_part := func(p: Parts, side: float) -> void:
		var k := p.k()
		k.loft([[0.03, 0.08, 0.08, KIMONO], [-0.1, 0.09, 0.09, KIMONO_L], [-0.16, 0.088, 0.088, KIMONO],
			[-0.17, 0.084, 0.084, LINING], [-0.175, 0.04, 0.04, KIMONO_D], [-0.17, 0.0, 0.0, KIMONO_D]], 9)
		k.loft([[-0.14, 0.03, 0.03, SKIN], [-0.21, 0.028, 0.028, SKIN], [-0.22, 0.0, 0.0, SKIN_D]], 6)
		# The furisode's long sleeve: a deep pocket of cloth hanging from the
		# back of the forearm (below it whenever the arm is raised), its edge
		# lined in pink, sakura near its end.
		var h := p.k("hard")
		h.box(Vector3(0.0, -0.1, 0.17), Vector3(0.05, 0.22, 0.26), KIMONO)
		h.box(Vector3(0.0, -0.1, 0.305), Vector3(0.052, 0.22, 0.02), LINING)
		for j in 3:
			h.box(Vector3(0.027 * side, -0.05 - j * 0.05, 0.2 + j * 0.03), Vector3(0.004, 0.022, 0.022), SAKURA)
	var _hand_part := func(p: Parts, side: float) -> void: _lady_hand(p, side, SKIN, SKIN_D)
	var _foot_part := func(p: Parts, _side: float) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
		k.loft([[-0.05, 0.03, 0.04, TABI], [0.06, 0.036, 0.045, TABI], [0.1, 0.025, 0.03, TABI], [0.11, 0.0, 0.0, TABI]], 7)
		k.pop()
		var h := p.k("hard")
		h.box(Vector3(0, -0.075, -0.03), Vector3(0.085, 0.02, 0.2), ZORI)
	var _none := func(_p: Parts, _side: float) -> void: pass
	var _extra := func(root: Node3D) -> void:
		# The open folding fan in her right hand: gold ribs, plum paper with
		# a pink border.
		_attach(root.get_node(_paths["hand_r"]), "Fan", Vector3(0, -0.07, -0.02), func(p: Parts) -> void:
			var h := p.k("hard")
			for i in 9:
				var a := deg_to_rad(-62.0 + i * 15.5)
				h.push(Transform3D(Basis(Vector3.FORWARD, a), Vector3.ZERO))
				h.box(Vector3(0, -0.11, 0.002), Vector3(0.05, 0.16, 0.004), _c("7a2a5a") if i % 2 else _c("8a3a6a"))
				h.box(Vector3(0, -0.185, 0.003), Vector3(0.05, 0.018, 0.005), SAKURA)
				h.box(Vector3(0, -0.1, -0.002), Vector3(0.006, 0.2, 0.004), OBI)
				h.pop()
		, "fan")
	var look := {"hips": _hips_part, "torso": _torso_part, "head": _head_part, "sleeve": _sleeve_part, "forearm": _forearm_part,
		"hand": _hand_part, "thigh": _none, "shin": _none, "foot": _foot_part, "extra": _extra}
	_build_woman("HimekoModel", "himeko.tscn", "face_himeko", SKIN, SKIN_D, look, _himeko_anims, 0.99)


## Himeko's poses: "idle" (left hand at her obi, the fan fluttering at her
## chest), "talk" (the fan pointing this way and that), "laugh" (the fan at
## her lips, chin up: "Ohohoho!"), "pout" (arms folded, head turned away) and
## "happy" (a little bounce on her toes).
func _himeko_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	# Her left hand rests elegantly at her obi.
	var hip_l: Vector3 = V.call(16, -30, 4)
	var hip_el: Vector3 = V.call(76, 0, 0)
	_anim(lib, "idle", 2.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [1.0, V.call(0, 0.836, 0)]],
		"hips": [[0.0, V.call(0, 0, 3)]],
		"torso": [[0.0, V.call(3, 0, -2)], [1.0, V.call(2, 0, -2)]],
		"head": [[0.0, V.call(8, -6, 4)], [1.0, V.call(9, -4, 5)]],
		"shoulder_r": [[0.0, V.call(32, 18, 8)]], "elbow_r": [[0.0, V.call(100, 0, 0)]],
		"hand_r": [[0.0, V.call(0, 0, -10)], [0.25, V.call(0, 0, 10)], [0.5, V.call(0, 0, -10)], [0.75, V.call(0, 0, 10)]],
		"shoulder_l": [[0.0, hip_l]], "elbow_l": [[0.0, hip_el]], "hand_l": [[0.0, V.call(0, 0, 0)]],
		"leg_r": [[0.0, V.call(0, 0, 2)]], "leg_l": [[0.0, V.call(4, 0, -2)]], "knee_l": [[0.0, V.call(-6, 0, 0)]],
	}, rest)
	_anim(lib, "talk", 1.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"hips": [[0.0, V.call(0, 0, 3)]],
		"torso": [[0.0, V.call(2, -4, -2)], [0.8, V.call(3, 2, -1)]],
		"head": [[0.0, V.call(6, 0, 4)], [0.4, V.call(10, 5, 2)], [0.8, V.call(4, -4, 6)], [1.2, V.call(8, 0, 3)]],
		"shoulder_r": [[0.0, V.call(55, 15, 14)], [0.4, V.call(75, 25, 22)], [0.8, V.call(50, 10, 12)], [1.2, V.call(70, 20, 18)]],
		"elbow_r": [[0.0, V.call(60, 0, 0)], [0.4, V.call(35, 0, 0)], [0.8, V.call(70, 0, 0)], [1.2, V.call(40, 0, 0)]],
		"shoulder_l": [[0.0, hip_l]], "elbow_l": [[0.0, hip_el]], "hand_l": [[0.0, V.call(0, 0, 0)]],
		"leg_l": [[0.0, V.call(4, 0, -2)]], "knee_l": [[0.0, V.call(-6, 0, 0)]],
	}, rest)
	_anim(lib, "laugh", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.15, V.call(0, 0.85, 0)], [0.3, V.call(0, 0.84, 0)], [0.45, V.call(0, 0.85, 0)]],
		"torso": [[0.0, V.call(-6, 0, 0)], [0.15, V.call(-8, 0, 0)]],
		"head": [[0.0, V.call(18, -10, -4)], [0.15, V.call(22, -10, -4)]],
		"shoulder_r": [[0.0, V.call(70, 34, -4)]], "elbow_r": [[0.0, V.call(128, 0, 0)]], "hand_r": [[0.0, V.call(-20, 0, 30)]],
		"shoulder_l": [[0.0, hip_l]], "elbow_l": [[0.0, hip_el]], "hand_l": [[0.0, V.call(0, 0, 0)]],
	}, rest)
	_anim(lib, "pout", 2.0, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)]],
		"torso": [[0.0, V.call(-2, 0, 0)], [1.0, V.call(-3, 0, 0)]],
		"head": [[0.0, V.call(10, 38, -4)], [1.0, V.call(12, 40, -4)]],
		"shoulder_r": [[0.0, V.call(42, -30, 4)]], "elbow_r": [[0.0, V.call(105, 0, 0)]], "hand_r": [[0.0, V.call(0, 0, -30)]],
		"shoulder_l": [[0.0, V.call(42, 30, -4)]], "elbow_l": [[0.0, V.call(105, 0, 0)]], "hand_l": [[0.0, V.call(0, 0, 30)]],
	}, rest)
	_anim(lib, "happy", 0.6, true, {
		"hips@pos": [[0.0, V.call(0, 0.84, 0)], [0.3, V.call(0, 0.865, 0)]],
		"torso": [[0.0, V.call(4, 0, 0)]],
		"head": [[0.0, V.call(10, 0, -6)], [0.3, V.call(10, 0, 6)]],
		"shoulder_r": [[0.0, V.call(55, 25, 6)]], "elbow_r": [[0.0, V.call(110, 0, 0)]],
		"hand_r": [[0.0, V.call(0, 0, -15)], [0.15, V.call(0, 0, 15)], [0.3, V.call(0, 0, -15)], [0.45, V.call(0, 0, 15)]],
		"shoulder_l": [[0.0, V.call(55, -35, 8)]], "elbow_l": [[0.0, V.call(120, 0, 0)]],
	}, rest)


# --- Biscuit, the horse ------------------------------------------------------------
#
# A palomino mare from the farm in the Southern Fields: a golden-cream coat,
# white mane, tail and socks, a red saddle on a blue blanket and a red bridle.
# Built like the people (smooth lofts per joint, overlapping at the joints),
# about Epona's size: 1.55 m at the withers, 2.2 m nose to tail. She faces -Z;
# "Body" is the root joint and the four legs hang from it in two parts.
# The "Saddle" marker is where the rider sits.

func _build_horse() -> void:
	var COAT := _c("e2c088")
	var COAT_L := _c("f0d4a0")
	var COAT_D := _c("c49c64")
	var MANE := _c("f6f2ea")
	var MANE_D := _c("dcd6c8")
	var SOCK := _c("f2eee6")
	var HOOF := _c("4a3a2a")
	var MUZZLE := _c("d8b4a0")
	var SADDLE := _c("b8302a")
	var SADDLE_D := _c("8a2018")
	var BLANKET := _c("3a5aa8")
	var LEATHER := _c("5a3a22")
	var GOLD := _c("e8c050")
	_root = Node3D.new()
	_root.name = "HorseModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "hips", "Body", Vector3(0, 1.22, 0), func(p: Parts) -> void:
		var k := p.k()
		k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		# Along +Y here = toward the tail (+Z).
		k.loft([
			[-0.95, 0.0, 0.0, COAT_D], [-0.9, 0.16, 0.2, COAT], [-0.75, 0.27, 0.34, COAT_L], [-0.45, 0.3, 0.37, COAT],
			[-0.1, 0.29, 0.35, COAT_L], [0.3, 0.3, 0.36, COAT], [0.65, 0.31, 0.37, COAT_L], [0.88, 0.25, 0.3, COAT],
			[1.0, 0.0, 0.0, COAT_D],
		], 10)
		k.pop()
		# The blue blanket and the red saddle with its horn and stirrups.
		var h := p.k("hard")
		h.box(Vector3(0, 0.3, -0.05), Vector3(0.66, 0.06, 0.9), BLANKET)
		for sx in [-1.0, 1.0]:
			h.box(Vector3(sx * 0.32, 0.12, -0.05), Vector3(0.03, 0.36, 0.86), BLANKET)
		h.box(Vector3(0, 0.36, -0.05), Vector3(0.44, 0.08, 0.62), SADDLE)
		h.box(Vector3(0, 0.42, 0.22), Vector3(0.4, 0.1, 0.12), SADDLE_D)
		h.box(Vector3(0, 0.44, -0.3), Vector3(0.14, 0.14, 0.08), SADDLE_D)
		h.prism(Vector3(0, 0.5, -0.32), 0.035, Vector3(0, 0.6, -0.34), 0.03, 6, GOLD)
		for sx in [-1.0, 1.0]:
			h.box(Vector3(sx * 0.33, -0.08, -0.08), Vector3(0.025, 0.55, 0.04), LEATHER)
			h.box(Vector3(sx * 0.36, -0.38, -0.08), Vector3(0.1, 0.03, 0.12), GOLD)
		# The girth strap under the belly.
		h.box(Vector3(0, -0.28, -0.08), Vector3(0.62, 0.04, 0.08), LEATHER)
	)
	# Where the rider sits.
	var seat_marker := Marker3D.new()
	seat_marker.name = "Saddle"
	seat_marker.position = Vector3(0, 0.42, -0.04)
	body.add_child(seat_marker)
	var neck := _joint(body, "neck", "Neck", Vector3(0, 0.12, -0.78), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, 0.62, -0.78), Vector3.ZERO))
		k.loft([[-0.1, 0.21, 0.28, COAT], [0.15, 0.19, 0.25, COAT_L], [0.4, 0.16, 0.2, COAT], [0.62, 0.13, 0.16, COAT_D]], 8)
		k.pop()
		# The white mane along the top of the neck.
		var m := p.k()
		m.push(_aim(Vector3(0, 0.62, -0.78), Vector3(0, 0.06, 0.1)))
		m.loft([[-0.05, 0.05, 0.13, MANE_D], [0.25, 0.055, 0.12, MANE], [0.6, 0.045, 0.09, MANE]], 4)
		m.pop()
	)
	_joint(neck, "head", "Head", Vector3(0, 0.38, -0.48), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -0.55, -1), Vector3.ZERO))
		k.loft([[-0.1, 0.12, 0.14, COAT], [0.08, 0.125, 0.15, COAT_L], [0.32, 0.1, 0.12, COAT], [0.52, 0.09, 0.1, MUZZLE], [0.6, 0.0, 0.0, MUZZLE]], 8)
		k.pop()
		# Ears, eyes and the forelock.
		for sx in [-1.0, 1.0]:
			k.prism(Vector3(0.06 * sx, 0.08, 0.02), 0.035, Vector3(0.07 * sx, 0.2, 0.04), 0.0, 4, COAT_D)
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.1 * sx, 0.03, -0.12), Vector3(0.02, 0.04, 0.05), _c("1a1410"))
			h.box(Vector3(0.105 * sx, 0.04, -0.125), Vector3(0.01, 0.012, 0.012), _c("ffffff"))
		h.box(Vector3(0, 0.1, -0.06), Vector3(0.12, 0.05, 0.12), MANE)
		# The red bridle: noseband, cheek straps, reins back to the saddle.
		h.push(_aim(Vector3(0, -0.5, -1), Vector3.ZERO))
		h.loft([[0.38, 0.09, 0.105, SADDLE], [0.42, 0.09, 0.105, SADDLE]], 8, false)
		h.pop()
		for sx in [-1.0, 1.0]:
			h.box(Vector3(0.105 * sx, -0.06, -0.2), Vector3(0.015, 0.03, 0.3), SADDLE)
	)
	_joint(body, "tail", "Tail", Vector3(0, 0.18, 0.95), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, -1, 0.35), Vector3.ZERO))
		k.loft([[-0.04, 0.05, 0.05, MANE_D], [0.15, 0.09, 0.07, MANE], [0.5, 0.1, 0.06, MANE], [0.78, 0.04, 0.03, MANE_D], [0.84, 0.0, 0.0, MANE_D]], 6)
		k.pop()
	)
	for leg in [["fl", -0.2, -0.62, true], ["fr", 0.2, -0.62, true], ["bl", -0.2, 0.66, false], ["br", 0.2, 0.66, false]]:
		var id: String = leg[0]
		var front: bool = leg[3]
		var nm := id.to_upper()
		var upper := _joint(body, "leg_" + id, "Leg" + nm, Vector3(leg[1], -0.12, leg[2]), func(p: Parts) -> void:
			var k := p.k()
			# Hind legs carry a heavier thigh.
			var top := 0.15 if front else 0.19
			k.loft([[0.12, top * 0.9, top, COAT], [-0.1, top * 0.75, top * 0.85, COAT], [-0.35, 0.075, 0.085, COAT_D], [-0.56, 0.06, 0.065, COAT_D]], 8)
		)
		var lower := _joint(upper, "knee_" + id, "Knee" + nm, Vector3(0, -0.55, 0), func(p: Parts) -> void:
			var k := p.k()
			k.loft([[0.04, 0.06, 0.065, COAT_D], [-0.2, 0.045, 0.05, COAT], [-0.32, 0.05, 0.055, SOCK], [-0.47, 0.05, 0.055, SOCK]], 8)
		)
		_joint(lower, "hoof_" + id, "Hoof" + nm, Vector3(0, -0.47, 0), func(p: Parts) -> void:
			p.k("hard").prism(Vector3(0, -0.05, -0.01), 0.07, Vector3(0, 0.02, -0.01), 0.055, 8, HOOF)
		)
	var lib := AnimationLibrary.new()
	var rest := {"hips": Vector3(0, 1.22, 0)}
	_horse_anims(lib, rest)
	_finish_character(root, lib)
	_save_scene(root, "horse.tscn")


## Biscuit's moves. Legs: +X swings a leg forward, a negative knee folds the
## lower leg back. "Body" bobs and pitches with each gait.
func _horse_anims(lib: AnimationLibrary, rest: Dictionary) -> void:
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 2.4, true, {
		"hips@pos": [[0.0, V.call(0, 1.22, 0)], [1.2, V.call(0, 1.21, 0)]],
		"neck": [[0.0, V.call(0, 0, 0)], [1.2, V.call(-4, 3, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.8, V.call(6, -4, 0)], [1.6, V.call(-2, 4, 0)]],
		"tail": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 18)], [1.2, V.call(0, 0, -10)], [1.8, V.call(0, 0, 6)]],
		"leg_br": [[0.0, V.call(-4, 0, 0)]], "knee_br": [[0.0, V.call(-12, 0, 0)]], "hoof_br": [[0.0, V.call(20, 0, 0)]],
	}, rest)
	# Walk: four beats, one hoof at a time (left hind, left fore, right hind, right fore).
	var L := 1.0
	var order := {"bl": 0.0, "fl": 0.25, "br": 0.5, "fr": 0.75}
	var walk := {
		"hips@pos": [[0.0, V.call(0, 1.22, 0)], [L * 0.25, V.call(0, 1.24, 0)], [L * 0.5, V.call(0, 1.22, 0)], [L * 0.75, V.call(0, 1.24, 0)]],
		"neck": [[0.0, V.call(-4, 0, 0)], [L * 0.5, V.call(4, 0, 0)]],
		"tail": [[0.0, V.call(6, 0, 6)], [L * 0.5, V.call(6, 0, -6)]],
	}
	for id: String in order:
		_gait_leg(walk, id, L, order[id], 22.0, -60.0)
	_anim(lib, "walk", L, true, walk, rest)
	# Trot: diagonal pairs together.
	L = 0.6
	var trot := {
		"hips@pos": [[0.0, V.call(0, 1.2, 0)], [L * 0.25, V.call(0, 1.27, 0)], [L * 0.5, V.call(0, 1.2, 0)], [L * 0.75, V.call(0, 1.27, 0)]],
		"neck": [[0.0, V.call(-2, 0, 0)], [L * 0.25, V.call(4, 0, 0)], [L * 0.5, V.call(-2, 0, 0)], [L * 0.75, V.call(4, 0, 0)]],
		"tail": [[0.0, V.call(12, 0, 0)], [L * 0.5, V.call(18, 0, 0)]],
	}
	for id: String in {"fl": 0.0, "br": 0.0, "fr": 0.5, "bl": 0.5}:
		_gait_leg(trot, id, L, {"fl": 0.0, "br": 0.0, "fr": 0.5, "bl": 0.5}[id], 28.0, -80.0)
	_anim(lib, "trot", L, true, trot, rest)
	# Gallop: the body rocks, hind legs push together, then the forelegs reach.
	L = 0.5
	var gallop := {
		"hips@pos": [[0.0, V.call(0, 1.16, 0)], [L * 0.3, V.call(0, 1.32, 0)], [L * 0.6, V.call(0, 1.2, 0)]],
		"hips": [[0.0, V.call(8, 0, 0)], [L * 0.3, V.call(-4, 0, 0)], [L * 0.6, V.call(-8, 0, 0)]],
		"neck": [[0.0, V.call(-14, 0, 0)], [L * 0.3, V.call(6, 0, 0)], [L * 0.6, V.call(-6, 0, 0)]],
		"head": [[0.0, V.call(6, 0, 0)], [L * 0.5, V.call(-6, 0, 0)]],
		"tail": [[0.0, V.call(30, 0, 0)], [L * 0.5, V.call(45, 0, 0)]],
	}
	for id: String in {"bl": 0.0, "br": 0.08, "fl": 0.45, "fr": 0.55}:
		_gait_leg(gallop, id, L, {"bl": 0.0, "br": 0.08, "fl": 0.45, "fr": 0.55}[id], 42.0, -95.0)
	_anim(lib, "gallop", L, true, gallop, rest)
	# Jumping a fence: gathers, launches with the forelegs tucked, stretches over.
	_anim(lib, "jump", 0.8, false, {
		"hips@pos": [[0.0, V.call(0, 1.18, 0)], [0.8, V.call(0, 1.22, 0)]],
		"hips": [[0.0, V.call(18, 0, 0)], [0.3, V.call(8, 0, 0)], [0.55, V.call(-12, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"neck": [[0.0, V.call(-10, 0, 0)], [0.4, V.call(-20, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"leg_fl": [[0.0, V.call(30, 0, 0)], [0.25, V.call(70, 0, 0)], [0.6, V.call(20, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"knee_fl": [[0.0, V.call(-30, 0, 0)], [0.25, V.call(-120, 0, 0)], [0.6, V.call(-10, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"leg_fr": [[0.0, V.call(30, 0, 0)], [0.25, V.call(75, 0, 0)], [0.6, V.call(25, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"knee_fr": [[0.0, V.call(-30, 0, 0)], [0.25, V.call(-125, 0, 0)], [0.6, V.call(-10, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"leg_bl": [[0.0, V.call(20, 0, 0)], [0.25, V.call(-40, 0, 0)], [0.6, V.call(-20, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"knee_bl": [[0.0, V.call(-40, 0, 0)], [0.25, V.call(-10, 0, 0)], [0.6, V.call(-70, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"leg_br": [[0.0, V.call(20, 0, 0)], [0.25, V.call(-45, 0, 0)], [0.6, V.call(-25, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"knee_br": [[0.0, V.call(-40, 0, 0)], [0.25, V.call(-10, 0, 0)], [0.6, V.call(-75, 0, 0)], [0.8, V.call(0, 0, 0)]],
		"tail": [[0.0, V.call(20, 0, 0)], [0.4, V.call(60, 0, 0)], [0.8, V.call(10, 0, 0)]],
	}, rest)
	# Rearing up with a neigh (EnHorse_StartRearing), forelegs pawing the air.
	_anim(lib, "rear", 1.2, false, {
		"hips@pos": [[0.0, V.call(0, 1.22, 0)], [0.35, V.call(0, 1.5, 0.35)], [0.85, V.call(0, 1.5, 0.35)], [1.2, V.call(0, 1.22, 0)]],
		"hips": [[0.0, V.call(0, 0, 0)], [0.35, V.call(38, 0, 0)], [0.85, V.call(40, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"neck": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-15, 0, 0)], [0.85, V.call(-10, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"head": [[0.0, V.call(0, 0, 0)], [0.4, V.call(15, 0, 0)], [0.85, V.call(10, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"leg_fl": [[0.0, V.call(0, 0, 0)], [0.35, V.call(40, 0, 0)], [0.55, V.call(70, 0, 0)], [0.75, V.call(35, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"knee_fl": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-90, 0, 0)], [0.55, V.call(-40, 0, 0)], [0.75, V.call(-100, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"leg_fr": [[0.0, V.call(0, 0, 0)], [0.35, V.call(65, 0, 0)], [0.55, V.call(35, 0, 0)], [0.75, V.call(70, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"knee_fr": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-40, 0, 0)], [0.55, V.call(-100, 0, 0)], [0.75, V.call(-40, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"leg_bl": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-38, 0, 0)], [0.85, V.call(-40, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"leg_br": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-38, 0, 0)], [0.85, V.call(-40, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"knee_bl": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-10, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"knee_br": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-10, 0, 0)], [1.2, V.call(0, 0, 0)]],
		"tail": [[0.0, V.call(0, 0, 0)], [0.5, V.call(-20, 0, 0)], [1.2, V.call(0, 0, 0)]],
	}, rest)


## One leg's stride in a gait cycle of `length` seconds: planted and pushing
## back for the first half after `phase`, lifted (knee folded) and swung
## forward for the second.
func _gait_leg(data: Dictionary, id: String, length: float, phase: float, swing: float, fold: float) -> void:
	var keys_leg: Array = []
	var keys_knee: Array = []
	for i in 9:
		var t := i / 8.0
		var p := fmod(t - phase + 1.0, 1.0)
		var leg := 0.0
		var knee := 0.0
		if p < 0.55:
			leg = lerpf(swing, -swing, p / 0.55)
			knee = -6.0
		else:
			var q := (p - 0.55) / 0.45
			leg = lerpf(-swing, swing, q)
			knee = fold * sin(q * PI)
		keys_leg.append([t * length, Vector3(leg, 0, 0)])
		keys_knee.append([t * length, Vector3(knee, 0, 0)])
	keys_leg.pop_back()
	keys_knee.pop_back()
	data["leg_" + id] = keys_leg
	data["knee_" + id] = keys_knee
