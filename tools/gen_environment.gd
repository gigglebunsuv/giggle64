extends RefCounted
## Builds the test area: terrain, ruin, trees, rocks, sky dome and boundaries.

const MeshKit := preload("res://tools/mesh_kit.gd")
const Layout := preload("res://tools/level_layout.gd")
const OUT := "res://scenes/environment/test_environment.tscn"

var M: Dictionary
var _root: Node3D
var _props: Node3D
var _seed := 500


func run(materials: Dictionary) -> void:
	M = materials
	_root = Node3D.new()
	_root.name = "TestEnvironment"
	_build_terrain()
	_props = Node3D.new()
	_props.name = "Props"
	_root.add_child(_props)
	_build_ruin()
	_build_field_ruins()
	_build_outcrop()
	_build_trees()
	_build_rocks_and_plants()
	_build_misc()
	_build_boundary()
	_build_sky()
	_save()


func _c(h: String) -> Color:
	return Color.html(h)


func _kit(textured := true) -> MeshKit:
	_seed += 1
	var k := MeshKit.new(_seed)
	k.textured = textured
	k.shade_jitter = 0.06
	return k


func _h(x: float, z: float) -> float:
	return Layout.height(x, z)


func _mesh_instance(parent: Node, node_name: String, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Static prop with a mesh and an optional collision shape.
func _static(node_name: String, pos: Vector3, mesh: Mesh, shape: Shape3D = null, shape_xform := Transform3D.IDENTITY, parent: Node = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	(parent if parent else _props).add_child(body)
	if mesh:
		_mesh_instance(body, "Mesh", mesh)
	if shape:
		var cs := CollisionShape3D.new()
		cs.name = "Collision"
		cs.shape = shape
		cs.transform = shape_xform
		body.add_child(cs)
	return body


func _box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


func _convex_from(mesh: ArrayMesh) -> ConvexPolygonShape3D:
	var s := ConvexPolygonShape3D.new()
	s.points = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return s


# --- Terrain ------------------------------------------------------------------

func _build_terrain() -> void:
	var ground := MeshKit.new(1)
	ground.textured = true
	ground.uv_top_down = true
	ground.uv_box_locked = true
	ground.uv_box = AABB(Vector3(Layout.X_MIN, -50, Layout.Z_MIN), Vector3(Layout.X_MAX - Layout.X_MIN, 100, Layout.Z_MAX - Layout.Z_MIN))
	ground.shade_jitter = 0.05
	var nx := int((Layout.X_MAX - Layout.X_MIN) / Layout.CELL)
	var nz := int((Layout.Z_MAX - Layout.Z_MIN) / Layout.CELL)
	var pt := func(ix: int, iz: int) -> Vector3:
		var x := Layout.X_MIN + ix * Layout.CELL
		var z := Layout.Z_MIN + iz * Layout.CELL
		return Vector3(x, _h(x, z), z)
	for iz in nz:
		for ix in nx:
			var a: Vector3 = pt.call(ix, iz)
			var b: Vector3 = pt.call(ix + 1, iz)
			var c: Vector3 = pt.call(ix + 1, iz + 1)
			var d: Vector3 = pt.call(ix, iz + 1)
			# Darken low hollows and lift high ground a little, N64 vertex-color style.
			var avg := (a.y + b.y + c.y + d.y) * 0.25
			var shade := clampf(0.88 + avg * 0.05, 0.8, 1.08)
			var col := Color(shade, shade, shade)
			# Alternate the diagonal for a less regular look.
			if (ix + iz) % 2 == 0:
				ground.face_dir([a, b, c], col, Vector3.UP)
				ground.face_dir([a, c, d], col, Vector3.UP)
			else:
				ground.face_dir([a, b, d], col, Vector3.UP)
				ground.face_dir([b, c, d], col, Vector3.UP)
	# East cliff face dropping into the void.
	var cliff := MeshKit.new(2)
	cliff.textured = true
	cliff.uv_box_locked = true
	cliff.uv_box = AABB(Vector3(Layout.X_MAX - 2, -16, Layout.Z_MIN), Vector3(4, 22, Layout.Z_MAX - Layout.Z_MIN))
	cliff.shade_jitter = 0.08
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var prev_low := Vector3(Layout.X_MAX - 0.6, -14, Layout.Z_MIN)
	for iz in nz:
		var top0: Vector3 = pt.call(nx, iz)
		var top1: Vector3 = pt.call(nx, iz + 1)
		var low1 := Vector3(Layout.X_MAX - rng.randf_range(0.3, 1.6), -14, top1.z)
		cliff.face_dir([top0, top1, low1, prev_low], Color(1, 1, 1), Vector3.RIGHT)
		prev_low = low1

	var mesh := ArrayMesh.new()
	ground.add_to(mesh, M.ground)
	cliff.add_to(mesh, M.cliff)
	var body := StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	_root.add_child(body)
	_mesh_instance(body, "TerrainMesh", mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)


# --- Ruin at the north end ----------------------------------------------------

func _build_ruin() -> void:
	var ruin := Node3D.new()
	ruin.name = "Ruin"
	_props.add_child(ruin)
	var STONE := Color(1, 1, 1)
	var base_y := _h(0, Layout.RUIN.y) - 0.1
	var top := base_y + 1.0
	var zf := -22.5   # platform front edge
	var zb := -28.5   # platform back edge

	var k := _kit()
	k.box(Vector3(0, base_y + 0.5, (zf + zb) * 0.5), Vector3(12, 1.0, zb - zf if zb > zf else zf - zb), STONE)
	_static("Platform", Vector3.ZERO, k.build(M.stone), _box_shape(Vector3(12, 1.0, 6)), Transform3D(Basis(), Vector3(0, base_y + 0.5, (zf + zb) * 0.5)), ruin)

	# Steps (visual) with a smooth ramp collider so the player can walk up.
	var steps := _kit()
	steps.box(Vector3(0, base_y + 0.33, zf + 0.35), Vector3(5, 0.66, 0.7), STONE)
	steps.box(Vector3(0, base_y + 0.165, zf + 1.05), Vector3(5, 0.33, 0.7), STONE)
	var ramp := ConvexPolygonShape3D.new()
	ramp.points = PackedVector3Array([
		Vector3(-2.5, base_y, zf + 1.9), Vector3(2.5, base_y, zf + 1.9),
		Vector3(-2.5, base_y, zf), Vector3(2.5, base_y, zf),
		Vector3(-2.5, top, zf), Vector3(2.5, top, zf),
	])
	_static("Steps", Vector3.ZERO, steps.build(M.stone), ramp, Transform3D.IDENTITY, ruin)

	# Gateway: two pillars and a slightly slipped lintel.
	for sx in [-1.0, 1.0]:
		var p := _kit()
		p.slab(Vector3(0, 0, 0), Vector2(1.0, 1.0), Vector3(0, 3.6, 0), Vector2(0.85, 0.85), STONE)
		p.box(Vector3(0, 0.15, 0), Vector3(1.2, 0.3, 1.2), STONE)
		_static("Pillar" + ("R" if sx > 0 else "L"), Vector3(2.5 * sx, top, zf - 1.2), p.build(M.stone), _box_shape(Vector3(1.0, 3.6, 1.0)), Transform3D(Basis(), Vector3(0, 1.8, 0)), ruin)
	var lintel := _kit()
	lintel.box(Vector3.ZERO, Vector3(6.4, 0.7, 1.2), STONE)
	var lb := _static("Lintel", Vector3(0, top + 3.95, zf - 1.2), lintel.build(M.stone), _box_shape(Vector3(6.4, 0.7, 1.2)), Transform3D.IDENTITY, ruin)
	lb.rotation_degrees = Vector3(0, 3, -3)

	# Back wall with the dark doorway into the Gauntlet of Fire.
	var wz := zb + 0.45
	for sx in [-1.0, 1.0]:
		var w := _kit()
		w.box(Vector3(0, 1.75, 0), Vector3(4.6, 3.5, 0.9), STONE)
		w.box(Vector3(1.3 * sx, 3.75, 0), Vector3(2.0, 0.5, 0.9), STONE)
		_static("BackWall" + ("R" if sx > 0 else "L"), Vector3(3.65 * sx, top, wz), w.build(M.stone), _box_shape(Vector3(4.6, 3.5, 0.9)), Transform3D(Basis(), Vector3(0, 1.75, 0)), ruin)
	var over := _kit()
	over.box(Vector3(0, 0, 0), Vector3(2.7, 1.0, 0.9), STONE)
	_static("DoorLintel", Vector3(0, top + 3.0, wz), over.build(M.stone), _box_shape(Vector3(2.7, 1.0, 0.9)), Transform3D.IDENTITY, ruin)
	var glow := MeshKit.new(3)
	var hot := _c("8a2408")
	var dark := _c("120404")
	# Inner faces of the recess, lit from below by unseen fire.
	glow.face_dir([Vector3(-1.35, 0, -0.5), Vector3(1.35, 0, -0.5), Vector3(1.35, 2.5, -0.5), Vector3(-1.35, 2.5, -0.5)], dark, Vector3.BACK)
	glow.face_dir([Vector3(-1.35, 0, -0.5), Vector3(1.35, 0, -0.5), Vector3(1.35, 0.9, -0.5), Vector3(-1.35, 0.9, -0.5)], hot, Vector3.BACK)
	glow.face_dir([Vector3(-1.35, 0.02, 0.45), Vector3(1.35, 0.02, 0.45), Vector3(1.35, 0.02, -0.5), Vector3(-1.35, 0.02, -0.5)], _c("3a0c04"), Vector3.UP)
	var door := _static("Doorway", Vector3(0, top, wz), glow.build(M.glow), _box_shape(Vector3(2.7, 2.5, 0.4)), Transform3D(Basis(), Vector3(0, 1.25, 0.1)), ruin)
	door.set_meta("note", "Sealed entrance to the Gauntlet of Fire (future content).")

	# Crumbled side walls.
	for sx in [-1.0, 1.0]:
		var sw := _kit()
		sw.box(Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 3.2), STONE)
		sw.box(Vector3(0, 2.1, -0.8), Vector3(0.8, 0.6, 1.6), STONE)
		_static("SideWall" + ("R" if sx > 0 else "L"), Vector3(5.6 * sx, top, zb + 2.2), sw.build(M.stone), _box_shape(Vector3(0.8, 1.8, 3.2)), Transform3D(Basis(), Vector3(0, 0.9, 0)), ruin)

	# Torches flanking the steps.
	for sx in [-1.0, 1.0]:
		_torch(ruin, Vector3(3.3 * sx, top, zf - 0.3), "Torch" + ("R" if sx > 0 else "L"))


func _torch(parent: Node, pos: Vector3, node_name: String) -> void:
	var k := _kit(false)
	k.prism(Vector3(0, 0, 0), 0.12, Vector3(0, 1.1, 0), 0.08, 5, _c("3b3b42"))
	k.prism(Vector3(0, 1.1, 0), 0.12, Vector3(0, 1.3, 0), 0.26, 6, _c("4a4a52"))
	var body := _static(node_name, pos, k.build(M.char), _box_shape(Vector3(0.3, 1.3, 0.3)), Transform3D(Basis(), Vector3(0, 0.65, 0)), parent)
	var flame := Node3D.new()
	flame.name = "Flame"
	flame.position = Vector3(0, 1.28, 0)
	flame.set_script(load("res://scripts/systems/torch_flicker.gd"))
	body.add_child(flame)
	_mesh_instance(flame, "FlameMesh", load("res://assets/models/flame_mesh.tres"))
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 0.5, 0)
	light.light_color = _c("ff8a3a")
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.shadow_enabled = false
	flame.add_child(light)


# --- Scattered ruins / collision test obstacles -------------------------------

func _build_field_ruins() -> void:
	var STONE := Color(1, 1, 1)
	# Broken standing column.
	var col := _kit()
	col.prism(Vector3(0, 0, 0), 0.5, Vector3(0, 1.7, 0), 0.45, 8, STONE)
	col.hexa([
		Vector3(-0.32, 1.7, -0.32), Vector3(0.32, 1.7, -0.32), Vector3(0.32, 1.7, 0.32), Vector3(-0.32, 1.7, 0.32),
		Vector3(-0.2, 2.0, -0.2), Vector3(0.25, 2.3, -0.1), Vector3(0.2, 1.95, 0.2), Vector3(-0.25, 1.85, 0.2),
	], STONE)
	col.box(Vector3(0, 0.1, 0), Vector3(1.2, 0.2, 1.2), STONE)
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.5
	cyl.height = 2.0
	_static("BrokenColumn", Vector3(8, _h(8, -8) - 0.1, -8), col.build(M.stone), cyl, Transform3D(Basis(), Vector3(0, 1.0, 0)))
	# Fallen column lying on its side.
	var fallen := _kit()
	fallen.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
	fallen.prism(Vector3(0, -1.6, 0), 0.45, Vector3(0, 1.6, 0), 0.45, 8, STONE)
	fallen.pop()
	var fc := CylinderShape3D.new()
	fc.radius = 0.45
	fc.height = 3.2
	var fb := _static("FallenColumn", Vector3(10.5, _h(10.5, -11.5) + 0.35, -11.5), fallen.build(M.stone), fc, Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
	fb.rotation_degrees.y = 25
	# Low walls.
	for data in [[Vector3(-8.5, 0, -13), Vector3(3.4, 1.2, 0.8), 15.0], [Vector3(-10, 0, -10.6), Vector3(0.8, 0.8, 2.2), 15.0], [Vector3(7.5, 0, 3.5), Vector3(2.6, 0.9, 0.7), -30.0]]:
		var p: Vector3 = data[0]
		var s: Vector3 = data[1]
		var w := _kit()
		w.box(Vector3(0, s.y * 0.5, 0), s, STONE)
		var b := _static("LowWall", Vector3(p.x, _h(p.x, p.z) - 0.1, p.z), w.build(M.stone), _box_shape(s), Transform3D(Basis(), Vector3(0, s.y * 0.5, 0)))
		b.rotation_degrees.y = data[2]
	# East-edge rail stones along the cliff (with gaps).
	for z in [-20.0, -13.0, -6.5, 5.0, 11.5, 18.0]:
		var r := _kit()
		r.slab(Vector3(0, 0, 0), Vector2(0.7, 1.6), Vector3(0, 0.8, 0), Vector2(0.55, 1.4), STONE)
		_static("RailStone", Vector3(Layout.X_MAX - 1.2, _h(Layout.X_MAX - 1.2, z) - 0.1, z), r.build(M.stone), _box_shape(Vector3(0.7, 0.8, 1.6)), Transform3D(Basis(), Vector3(0, 0.4, 0)))


# --- Rocky outcrop on the plateau ---------------------------------------------

func _build_outcrop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var c := Layout.PLATEAU
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var ang := wrapf(a, -PI, PI)
		if absf(ang) < 0.55:
			continue   # Keep the ramp side (east) open.
		var r := rng.randf_range(6.3, 7.3)
		var x := c.x + cos(a) * r
		var z := c.y + sin(a) * r
		var size := rng.randf_range(1.2, 2.0)
		_rock("OutcropRock", Vector3(x, _h(x, z) - 0.3, z), Vector3(size, size * rng.randf_range(0.8, 1.3), size), rng)
	# A tall standing spire on top of the plateau.
	_rock("Spire", Vector3(c.x - 1.5, _h(c.x - 1.5, c.y + 1) - 0.2, c.y + 1), Vector3(0.9, 2.6, 0.9), rng)


func _rock(node_name: String, pos: Vector3, radius: Vector3, rng: RandomNumberGenerator, collide := true) -> void:
	var k := _kit()
	k.icosa(Vector3(0, radius.y * 0.55, 0), radius, 0.22, Color(1, 1, 1))
	var mesh := k.build(M.rock)
	var body := _static(node_name, pos, mesh, _convex_from(mesh) if collide else null)
	body.rotation_degrees.y = rng.randf_range(0, 360)


# --- Trees --------------------------------------------------------------------

func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for p in [Vector2(-12, 15), Vector2(11, 20), Vector2(-20, 11), Vector2(19, 3), Vector2(14, -17),
			Vector2(-20, -17), Vector2(6, 26), Vector2(-8, 24), Vector2(-14, -24), Vector2(12, -26)]:
		var h := rng.randf_range(2.8, 3.6)
		var trunk := _kit()
		trunk.prism(Vector3(0, -0.3, 0), 0.38, Vector3(0, h, 0), 0.22, 6, Color(1, 1, 1))
		trunk.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-50)), Vector3(0.1, h * 0.55, 0)))
		trunk.prism(Vector3.ZERO, 0.09, Vector3(0, 0.9, 0), 0.04, 4, Color(1, 1, 1))
		trunk.pop()
		var canopy := _kit()
		var cr := rng.randf_range(1.7, 2.3)
		canopy.icosa(Vector3(0, h + cr * 0.55, 0), Vector3(cr, cr * 0.8, cr), 0.18, Color(1, 1, 1), true)
		canopy.icosa(Vector3(cr * 0.45, h + cr * 0.15, cr * 0.2), Vector3(cr * 0.6, cr * 0.5, cr * 0.6), 0.2, Color(0.9, 0.9, 0.9))
		var mesh := ArrayMesh.new()
		trunk.add_to(mesh, M.bark)
		canopy.add_to(mesh, M.leaves)
		var shape := CylinderShape3D.new()
		shape.radius = 0.38
		shape.height = h
		var body := _static("Tree", Vector3(p.x, _h(p.x, p.y), p.y), mesh, shape, Transform3D(Basis(), Vector3(0, h * 0.5, 0)))
		body.rotation_degrees.y = rng.randf_range(0, 360)


# --- Decorative rocks, bushes, flowers ----------------------------------------

func _build_rocks_and_plants() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for p in [Vector2(-5, 12), Vector2(9, 9), Vector2(16, -6), Vector2(-14, 4), Vector2(4, -18), Vector2(-4, -6),
			Vector2(18, 15), Vector2(-17, 18), Vector2(21, -12), Vector2(-9, -20), Vector2(3, 6), Vector2(-22, 2)]:
		var s := rng.randf_range(0.35, 0.95)
		_rock("Rock", Vector3(p.x, _h(p.x, p.y) - s * 0.25, p.y), Vector3(s, s * 0.7, s), rng, s > 0.5)
	for p in [Vector2(-11, 13), Vector2(12.5, 21.5), Vector2(-19, 13), Vector2(17.5, 4.5), Vector2(-7, 22), Vector2(13, -15.5), Vector2(-4, 26), Vector2(20, -2)]:
		var k := _kit()
		var r := rng.randf_range(0.45, 0.75)
		k.icosa(Vector3(0, r * 0.5, 0), Vector3(r, r * 0.7, r), 0.2, Color(0.85, 0.95, 0.85))
		_static("Bush", Vector3(p.x, _h(p.x, p.y) - 0.1, p.y), k.build(M.leaves))
	var flowers := _kit(false)
	for p in [Vector2(-2.6, 17), Vector2(-3.4, 16.2), Vector2(3.8, 12.4), Vector2(-10.4, 15.6), Vector2(4.6, 13.1),
			Vector2(-6, 2.5), Vector2(6.2, -2.0), Vector2(-3.2, -10.5), Vector2(9.5, 18.6)]:
		var base := Vector3(p.x, _h(p.x, p.y), p.y)
		flowers.box(base + Vector3(0, 0.15, 0), Vector3(0.03, 0.3, 0.03), _c("3c6a22"))
		flowers.box(base + Vector3(0.08, 0.06, 0), Vector3(0.16, 0.03, 0.06), _c("4a7a28"))
		flowers.icosa(base + Vector3(0, 0.34, 0), Vector3(0.11, 0.08, 0.11), 0.15, _c("c8241c"))
		flowers.box(base + Vector3(0, 0.36, 0), Vector3(0.05, 0.05, 0.05), _c("f0c030"))
	_mesh_instance(_props, "Flowers", flowers.build(M.char))


func _build_misc() -> void:
	# Crate stack near the spawn for collision testing.
	for data in [[Vector3(5.2, 0, 15), 0.0], [Vector3(6.3, 0, 15.4), 12.0], [Vector3(5.6, 1.0, 15.1), 35.0]]:
		var p: Vector3 = data[0]
		var k := _kit()
		k.box(Vector3(0, 0.5, 0), Vector3(1, 1, 1), Color(1, 1, 1))
		var b := _static("Crate", Vector3(p.x, _h(5.6, 15.2) + p.y, p.z), k.build(M.wood), _box_shape(Vector3(1, 1, 1)), Transform3D(Basis(), Vector3(0, 0.5, 0)))
		b.rotation_degrees.y = data[1]
	# Wooden signpost by the spawn.
	var s := _kit()
	s.box(Vector3(0, 0.6, 0), Vector3(0.12, 1.2, 0.12), Color(0.85, 0.85, 0.85))
	s.box(Vector3(0, 1.15, 0), Vector3(0.9, 0.5, 0.08), Color(1, 1, 1))
	var sb := _static("Signpost", Vector3(2.4, _h(2.4, 22), 22), s.build(M.wood), _box_shape(Vector3(0.2, 1.2, 0.2)), Transform3D(Basis(), Vector3(0, 0.6, 0)))
	sb.rotation_degrees.y = -20
	# Fence posts along the south edge of the clearing.
	for i in 6:
		var x := -9.0 + i * 1.6
		if absf(x) < 2.5:
			continue
		var f := _kit()
		f.prism(Vector3(0, 0, 0), 0.1, Vector3(0, 1.0, 0), 0.09, 4, Color(0.9, 0.9, 0.9))
		_static("FencePost", Vector3(x, _h(x, 26.5) - 0.05, 26.5), f.build(M.wood), _box_shape(Vector3(0.2, 1.0, 0.2)), Transform3D(Basis(), Vector3(0, 0.5, 0)))


# --- Invisible boundary -------------------------------------------------------

func _build_boundary() -> void:
	var b := Node3D.new()
	b.name = "Boundary"
	_root.add_child(b)
	var walls := [
		["WestWall", Vector3(-26.5, 10, -2), Vector3(1, 40, 70)],
		["NorthWall", Vector3(-3, 10, -31.5), Vector3(62, 40, 1)],
		["SouthWall", Vector3(-3, 10, 27.5), Vector3(62, 40, 1)],
	]
	for w in walls:
		_static(w[0], w[1], null, _box_shape(w[2]), Transform3D.IDENTITY, b)


# --- Sky dome, sun and distant volcano ----------------------------------------

func _build_sky() -> void:
	var sky := Node3D.new()
	sky.name = "SkyDome"
	sky.set_script(load("res://scripts/systems/sky_dome.gd"))
	_root.add_child(sky)
	var k := MeshKit.new(4)
	var R := 180.0
	var rings := [[-25.0, _c("2a1a2c")], [0.0, _c("c46a4e")], [8.0, _c("b45a5e")], [22.0, _c("7a3e66")], [45.0, _c("3e2652")], [90.0, _c("1a1236")]]
	var seg := 12
	for r in rings.size() - 1:
		var e0: float = deg_to_rad(rings[r][0])
		var e1: float = deg_to_rad(rings[r + 1][0])
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p00 := Vector3(cos(a0) * cos(e0), sin(e0), sin(a0) * cos(e0)) * R
			var p10 := Vector3(cos(a1) * cos(e0), sin(e0), sin(a1) * cos(e0)) * R
			var p01 := Vector3(cos(a0) * cos(e1), sin(e1), sin(a0) * cos(e1)) * R
			var p11 := Vector3(cos(a1) * cos(e1), sin(e1), sin(a1) * cos(e1)) * R
			_sky_quad(k, [p00, p10, p11, p01], [rings[r][1], rings[r][1], rings[r + 1][1], rings[r + 1][1]])
	_mesh_instance(sky, "Dome", k.build(M.sky))

	var far := MeshKit.new(8)
	far.shade_jitter = 0.0
	# Setting sun, low in the west.
	var sun_dir := Vector3(-0.85, 0.12, -0.5).normalized()
	var sun_c := sun_dir * 170.0
	var right := sun_dir.cross(Vector3.UP).normalized()
	var up := right.cross(sun_dir).normalized()
	for layer in [[13.0, _c("f0a040")], [9.0, _c("ffd070")]]:
		var pts: Array = []
		for i in 10:
			var a := TAU * i / 10.0
			pts.append(sun_c - sun_dir * (1.0 if layer[0] < 10 else 0.0) + (right * cos(a) + up * sin(a)) * layer[0])
		far.face_dir(pts, layer[1], -sun_dir)
	# Distant ridge of jagged hills all around.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var hills := 24
	var prev := Vector3.ZERO
	var first := Vector3.ZERO
	for i in hills + 1:
		var a := TAU * (i % hills) / hills
		var top := Vector3(cos(a) * 150.0, rng.randf_range(1, 7) if i < hills else first.y, sin(a) * 150.0)
		if i == 0:
			first = top
		else:
			var b0 := Vector3(prev.x, -40, prev.z)
			var b1 := Vector3(top.x, -40, top.z)
			far.face_dir([b0, b1, top, prev], _c("7a4a58"), -Vector3(top.x + prev.x, 0, top.z + prev.z))
		prev = top
	# The volcano of the Gauntlet of Fire, far to the north.
	var vc := Vector3(14, -2, -175)
	var ring: Array = []
	for i in 9:
		var a := TAU * i / 9.0
		ring.append(vc + Vector3(cos(a) * rng.randf_range(30, 36), 0, sin(a) * rng.randf_range(22, 26)))
	var crater: Array = []
	for i in 9:
		var a := TAU * i / 9.0
		crater.append(vc + Vector3(cos(a) * 7.0, 40 + rng.randf_range(-1.5, 1.5), sin(a) * 5.5))
	for i in 9:
		var j := (i + 1) % 9
		var lava := i == 2 or i == 6
		far.face([ring[i], ring[j], crater[j], crater[i]], _c("7a3a24") if lava else _c("3e2630"), vc + Vector3(0, 20, 0))
	far.face_dir(crater, _c("ff7a20"), Vector3.UP)
	_mesh_instance(sky, "Horizon", far.build(M.sky))


func _sky_quad(k: MeshKit, p: Array, cols: Array) -> void:
	# Per-vertex gradient: emit as two triangles facing the dome center.
	k.shade_jitter = 0.0
	var tris := [[0, 1, 2], [0, 2, 3]]
	for t in tris:
		var a: Vector3 = p[t[0]]
		var b: Vector3 = p[t[1]]
		var c: Vector3 = p[t[2]]
		var n := -(a + b + c).normalized()
		var winding := (b - a).cross(c - a)
		var order := [t[0], t[2], t[1]] if winding.dot(n) > 0 else [t[0], t[1], t[2]]
		for idx in order:
			k.verts.append(p[idx])
			k.normals.append(n)
			k.colors.append(cols[idx])
			k.uvs.append(Vector2.ZERO)


func _set_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner(child, owner)


func _save() -> void:
	_set_owner(_root, _root)
	var ps := PackedScene.new()
	var err := ps.pack(_root)
	if err == OK:
		err = ResourceSaver.save(ps, OUT)
	if err != OK:
		push_error("Failed to save environment: %s" % err)
	_root.free()
