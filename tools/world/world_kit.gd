extends RefCounted
## Builds one area scene from a region description: terrain, sky, light and fog,
## water, props and buildings, loading zones and entrances, the hero and camera.
##
## Props are merged into a few big meshes per material and 48 m chunk (cheap to
## draw on the Compatibility renderer); their collision shapes all live on one
## StaticBody3D. Every primitive keeps its own stretched (never tiled) UVs.

const MeshKit := preload("res://tools/mesh_kit.gd")
const CHUNK := 48.0
const SKY_RADIUS := 240.0

var R   # the region (tools/world/region.gd)
var M: Dictionary
var root: Node3D
var rng := RandomNumberGenerator.new()

var _batches := {}
var _props_root: Node3D
var _collision: StaticBody3D
var _exits: Node3D
var _entrances: Node3D
var _misc: Node3D
## Dungeon entrances, shown on the minimap and the pause map.
var _icons: Node3D
var _seed := 100
## Material of the last batch merged: collision shapes made right after it take
## their footstep surface from it (see MAT_SURFACE and _shape).
var _last_mat := ""
## Shallow water of the area for footsteps: [[Rect2 (x, z), y], ...].
var _water: Array = []
## Everything solid placed so far, for finding open ground (see is_free):
## a list of {"xf": Transform3D, "e": Vector3 half extents} boxes, bucketed
## into 8 m cells.
var _solids: Array = []
var _solid_cells := {}
const SOLID_CELL := 8.0

## Footstep surface of collision shapes, by the material of the prop they belong to.
const MAT_SURFACE := {
	"wood": "wood", "door": "wood", "bark": "wood", "thatch": "wood",
	"snow": "snow", "ice": "ice", "leaves": "grass", "pine": "grass",
}


func build(region, materials: Dictionary) -> Node3D:
	R = region
	M = materials
	rng.seed = R.seed_value * 97 + 3
	root = Node3D.new()
	root.name = R.id.to_pascal_case()
	root.set_meta("area_id", R.id)
	root.set_meta("bounds", Vector3((R.x_max - R.x_min) * 0.5, (R.z_max - R.z_min) * 0.5, 0))
	root.set_meta("rect", Rect2(R.x_min, R.z_min, R.x_max - R.x_min, R.z_max - R.z_min))
	_environment()
	_terrain()
	_props_root = _node(root, "Props")
	_collision = StaticBody3D.new()
	_collision.name = "PropCollision"
	_collision.collision_layer = 1
	_collision.collision_mask = 0
	root.add_child(_collision)
	_misc = _node(root, "Features")
	_exits = _node(root, "Exits")
	_entrances = _node(root, "Entrances")
	_icons = _node(root, "MapIcons")
	for w in R.water:
		water_plane(w.rect, w.y, w.get("col", Color(0.25, 0.45, 0.7, 0.72)))
	for l in R.links:
		_link(l)
	R.build(self)
	if R.has_method("populate"):
		R.populate(self)
	if R.link_name() in WAYSTONE_AREAS:
		_auto_waystone()
	if R.has_method("map_floors"):
		root.set_meta("floors", R.map_floors())
	_flush_batches()
	root.set_meta("water", _water)
	_boundary()
	# Interiors have no sky, unless part of them is open to it (a roof).
	if not R.interior or R.get("open_sky") == true:
		_sky()
	_hero()
	return root


## The regions with a waystone (Waystone.ORDER), set beside the first road in.
const WAYSTONE_AREAS := ["village", "field", "forest", "hidden_forest", "marsh", "southern_fields", "desert", "cliffs", "snow", "lake", "batela_fells", "cinderhold", "black_water_ridge"]


func _auto_waystone() -> void:
	if R.links.is_empty():
		return
	var l: Dictionary = R.links[0]
	var d: Vector2 = (l.d as Vector2).normalized()
	var base: Vector2 = l.p + d * (float(l.spawn) + 5.0) + Vector2(-d.y, d.x) * 5.0
	# A region may name its own spot (the cliffs' first tier, over the lake).
	if R.get("waystone_at") is Vector2:
		base = R.get("waystone_at")
	var at := spot(base, 8.0, 2.0)
	if at == Vector2.INF:
		at = spot(base, 16.0, 1.5)
	if at == Vector2.INF:
		push_warning("%s: no room for its waystone" % R.id)
		return
	waystone(at.x, at.y, yaw_of((l.p - at).normalized()))


## A waystone (Waystone) at `x, z`, its eye facing `yaw` (-Z), and the
## "waystone" entrance just in front of it.
func waystone(x: float, z: float, yaw: float, y := INF) -> void:
	var p := g(x, z, -0.1) if y == INF else Vector3(x, y, z)
	var w := _dyn("res://scripts/systems/waystone.gd", "Waystone", p, yaw, {"area": R.link_name()}, Node3D.new())
	var k := MeshKit.new(_seed + _misc.get_child_count())
	k.prism(Vector3(0, 0, 0), 0.75, Vector3(0, 0.3, 0), 0.7, 6, c("6a6a72"))
	k.prism(Vector3(0, 0.3, 0), 0.5, Vector3(0, 2.3, 0), 0.32, 5, c("8a8a94"))
	k.prism(Vector3(0, 2.3, 0), 0.32, Vector3(0, 2.7, 0), 0.0, 5, c("9a9aa4"))
	k.box(Vector3(0, 1.7, -0.36), Vector3(0.28, 0.28, 0.06), c("2a3a6a"))
	var mi := MeshInstance3D.new()
	mi.name = "Stone"
	mi.mesh = k.build(M.char)
	w.add_child(mi)
	var e := MeshKit.new(_seed + 7)
	e.icosa(Vector3(0, 1.7, -0.4), Vector3(0.1, 0.1, 0.04), 0.0, c("c8e0ff"))
	var em := MeshInstance3D.new()
	em.name = "Eye"
	em.mesh = e.build(M.glow)
	w.add_child(em)
	var light := OmniLight3D.new()
	light.name = "Glow"
	light.position = Vector3(0, 1.7, -0.6)
	light.light_color = c("a8c8ff")
	light.light_energy = 0.9
	light.omni_range = 4.0
	w.add_child(light)
	col_cyl(p, 0.6, 2.6)
	var front := Basis(Vector3.UP, yaw) * Vector3(0, 0, -2.2)
	entrance("waystone", p.x + front.x, p.z + front.z, yaw)


# --- Basics -------------------------------------------------------------------

## In a tower the terrain is its lowest storey; things placed without a height
## stand on `place_y` (the storey the hero enters on) instead.
var place_y := INF


func h(x: float, z: float) -> float:
	return R.height(x, z) if place_y == INF else place_y


func g(x: float, z: float, dy := 0.0) -> Vector3:
	return Vector3(x, h(x, z) + dy, z)


func c(hex: String) -> Color:
	return Color.html(hex)


func _node(parent: Node, node_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	parent.add_child(n)
	return n


func _tmp(textured := true) -> MeshKit:
	_seed += 1
	var k := MeshKit.new(_seed)
	k.textured = textured
	k.shade_jitter = 0.06
	return k


## Appends a finished temporary kit (world-space triangles) to the batch for `mat`.
func merge(k: MeshKit, mat: String) -> void:
	_last_mat = mat
	if k.verts.is_empty():
		return
	var p := k.verts[0]
	var key := "%s|%d|%d" % [mat, floori(p.x / CHUNK), floori(p.z / CHUNK)]
	if not _batches.has(key):
		_batches[key] = MeshKit.new(1)
	var b: MeshKit = _batches[key]
	b.verts.append_array(k.verts)
	b.normals.append_array(k.normals)
	b.colors.append_array(k.colors)
	b.uvs.append_array(k.uvs)


func _flush_batches() -> void:
	var keys := _batches.keys()
	keys.sort()
	var meshes := {}
	for key: String in keys:
		var parts := key.split("|")
		var chunk := parts[1] + "_" + parts[2]
		if not meshes.has(chunk):
			meshes[chunk] = ArrayMesh.new()
		(_batches[key] as MeshKit).add_to(meshes[chunk], M[parts[0]])
	for chunk: String in meshes:
		_mesh_instance(_props_root, "Chunk_" + chunk, meshes[chunk])


func _mesh_instance(parent: Node, node_name: String, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# --- Collision ----------------------------------------------------------------

## Collision shapes can carry flags the hero's climbing reads: "no_climb" (never
## a ledge), "ladder" (climbable, OoT's WALL_FLAG_1) and "climb_with_a" (blocks
## that wait for A, WALL_FLAG_6).
func _shape(shape: Shape3D, xform: Transform3D) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = "C%d" % _collision.get_child_count()
	cs.shape = shape
	cs.transform = xform
	cs.set_meta("surface", MAT_SURFACE.get(_last_mat, "stone"))
	_collision.add_child(cs)
	_record_solid(shape, xform)
	return cs


## Notes a collision shape's footprint (as an oriented box) for is_free().
func _record_solid(shape: Shape3D, xform: Transform3D) -> void:
	var xf := xform
	var e := Vector3.ZERO
	if shape is BoxShape3D:
		e = (shape as BoxShape3D).size * 0.5
	elif shape is CylinderShape3D:
		var c := shape as CylinderShape3D
		e = Vector3(c.radius, c.height * 0.5, c.radius)
	elif shape is ConvexPolygonShape3D:
		var pts := (shape as ConvexPolygonShape3D).points
		if pts.is_empty():
			return
		var box := AABB(xform * pts[0], Vector3.ZERO)
		for v in pts:
			box = box.expand(xform * v)
		xf = Transform3D(Basis(), box.get_center())
		e = box.size * 0.5
	else:
		return
	# Last-resort walls round the whole area are not "in the way".
	if e.x > 60.0 or e.z > 60.0:
		return
	var idx := _solids.size()
	_solids.append({"xf": xf, "e": e})
	var reach := Vector2(e.x, e.z).length() + 1.0
	var o := xf.origin
	for cx in range(floori((o.x - reach) / SOLID_CELL), floori((o.x + reach) / SOLID_CELL) + 1):
		for cz in range(floori((o.z - reach) / SOLID_CELL), floori((o.z + reach) / SOLID_CELL) + 1):
			var key := Vector2i(cx, cz)
			if not _solid_cells.has(key):
				_solid_cells[key] = []
			_solid_cells[key].append(idx)


## True if nothing solid stands within `pad` meters of (x, z) at ground level.
func is_free(x: float, z: float, pad := 1.0) -> bool:
	var gy := h(x, z)
	for cx in range(floori((x - pad) / SOLID_CELL), floori((x + pad) / SOLID_CELL) + 1):
		for cz in range(floori((z - pad) / SOLID_CELL), floori((z + pad) / SOLID_CELL) + 1):
			for idx: int in _solid_cells.get(Vector2i(cx, cz), []):
				var sd: Dictionary = _solids[idx]
				var xf: Transform3D = sd.xf
				var e: Vector3 = sd.e
				var lp: Vector3 = xf.affine_inverse() * Vector3(x, gy + 0.8, z)
				if absf(lp.x) < e.x + pad and absf(lp.z) < e.z + pad and absf(lp.y) < e.y + 1.5:
					return false
	return true


## True if nothing solid recorded stands within `pad` meters of (x, z) at
## the height `y` (a floor's level: a dungeon storey's, not the terrain's).
func free_at(x: float, y: float, z: float, pad := 0.5) -> bool:
	for cx in range(floori((x - pad) / SOLID_CELL), floori((x + pad) / SOLID_CELL) + 1):
		for cz in range(floori((z - pad) / SOLID_CELL), floori((z + pad) / SOLID_CELL) + 1):
			for idx: int in _solid_cells.get(Vector2i(cx, cz), []):
				var sd: Dictionary = _solids[idx]
				var xf: Transform3D = sd.xf
				var e: Vector3 = sd.e
				var lp: Vector3 = xf.affine_inverse() * Vector3(x, y + 0.8, z)
				if absf(lp.x) < e.x + pad and absf(lp.z) < e.z + pad and absf(lp.y) < e.y + 0.7:
					return false
	return true


## A random open spot within `radius` of `c`: inside the play area, off the
## exit corridors, above `min_y` (water), on gentle ground and clear of
## anything solid by `pad`. Vector2.INF if none was found.
func spot(c: Vector2, radius: float, pad := 1.2, min_y := -INF, tries := 40) -> Vector2:
	for i in tries:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * radius
		var p := c + Vector2(cos(a), sin(a)) * d
		if not R.inside(p.x, p.y, R.rim_margin + 3.0) or R.in_corridor(p.x, p.y, 3.0):
			continue
		var hh := h(p.x, p.y)
		if hh < min_y:
			continue
		if absf(h(p.x + 1.0, p.y) - hh) > 0.6 or absf(h(p.x, p.y + 1.0) - hh) > 0.6:
			continue
		if not is_free(p.x, p.y, pad):
			continue
		return p
	return Vector2.INF


## Places `count` of `kind` near `c` (see enemy()), each on an open spot.
func enemies_near(kind: String, c: Vector2, radius: float, count: int, opts := {}, min_y := -INF) -> void:
	for i in count:
		var p := spot(c, radius, 1.5, min_y)
		if p != Vector2.INF:
			enemy(kind, p.x, p.y, rng.randf() * TAU, opts)


## Places `count` shrubs on open ground near `c`.
func shrubs_near(c: Vector2, radius: float, count: int, tint := Color(1, 1, 1), min_y := -INF) -> void:
	for i in count:
		var p := spot(c, radius, 0.6, min_y, 12)
		if p != Vector2.INF:
			shrub(p.x, p.y, true, tint)


## Places `count` liftable rocks on open ground near `c`.
func lift_rocks_near(c: Vector2, radius: float, count: int, tint := Color(1, 1, 1), min_y := -INF) -> void:
	for i in count:
		var p := spot(c, radius, 0.7, min_y, 12)
		if p != Vector2.INF:
			lift_rock(p.x, p.y, tint)


## Sets the footstep surface of a collision shape (see scripts/systems/surface.gd).
func surface(cs: CollisionShape3D, surface_name: String) -> CollisionShape3D:
	cs.set_meta("surface", surface_name)
	return cs


func col_box(center: Vector3, size: Vector3, yaw := 0.0) -> CollisionShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return _shape(s, Transform3D(Basis(Vector3.UP, yaw), center))


func col_box_basis(center: Vector3, size: Vector3, basis: Basis) -> CollisionShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return _shape(s, Transform3D(basis, center))


func col_points(points: PackedVector3Array) -> CollisionShape3D:
	var s := ConvexPolygonShape3D.new()
	s.points = points
	return _shape(s, Transform3D.IDENTITY)


func col_cyl(base: Vector3, r: float, height: float) -> void:
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = height
	_shape(s, Transform3D(Basis(), base + Vector3(0, height * 0.5, 0)))


func col_convex(k: MeshKit) -> void:
	var s := ConvexPolygonShape3D.new()
	s.points = k.verts
	_shape(s, Transform3D.IDENTITY)


## Invisible wall between two ground points.
func invisible_wall(a: Vector2, b: Vector2, height := 8.0, y := INF) -> void:
	var mid := (a + b) * 0.5
	var base := h(mid.x, mid.y) if y == INF else y
	var d := b - a
	col_box(Vector3(mid.x, base + height * 0.5 - 1.0, mid.y), Vector3(d.length(), height + 2.0, 0.6), -atan2(d.y, d.x))


func invisible_path(pts: Array, height := 8.0) -> void:
	for i in pts.size() - 1:
		invisible_wall(pts[i], pts[i + 1], height)


# --- Environment, terrain, sky ------------------------------------------------

func _environment() -> void:
	var m: Dictionary = R.mood
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = m.fog
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = m.ambient
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = m.fog
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.0
	env.fog_depth_curve = 1.0
	env.fog_depth_begin = m.fog_begin
	env.fog_depth_end = m.fog_end
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	we.camera_attributes = CameraAttributesPractical.new()
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	var rot: Vector3 = m.sun_rot
	sun.rotation = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), 0)
	sun.light_color = m.sun
	sun.light_energy = m.get("sun_energy", 1.0)
	sun.shadow_enabled = false
	root.add_child(sun)
	# OoT scene lighting (EnvLightSettings in environment.h): ambient plus two
	# directional lights, a key (light1) and a dimmer fill (light2) from the far side.
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation = Vector3(deg_to_rad(-25.0), deg_to_rad(rot.y + 180.0), 0)
	fill.light_color = m.get("fill", Color(m.ambient) * 0.6)
	fill.light_energy = m.get("fill_energy", 0.45)
	fill.shadow_enabled = false
	root.add_child(fill)


func _terrain() -> void:
	var b: Rect2 = R.terrain_bounds()
	var nx := int(ceil(b.size.x / R.cell))
	var nz := int(ceil(b.size.y / R.cell))
	var dx := b.size.x / nx
	var dz := b.size.y / nz
	var hs := PackedFloat32Array()
	hs.resize((nx + 1) * (nz + 1))
	for iz in nz + 1:
		for ix in nx + 1:
			hs[iz * (nx + 1) + ix] = R.height(b.position.x + ix * dx, b.position.y + iz * dz)
	var at := func(ix: int, iz: int) -> float:
		return hs[clampi(iz, 0, nz) * (nx + 1) + clampi(ix, 0, nx)]
	var y_lo := INF
	var y_hi := -INF
	for v in hs:
		y_lo = minf(y_lo, v)
		y_hi = maxf(y_hi, v)
	var ground := MeshKit.new(1)
	var cliff := MeshKit.new(2)
	var vtx := func(ix: int, iz: int) -> Array:
		var x := b.position.x + ix * dx
		var z := b.position.y + iz * dz
		var y: float = at.call(ix, iz)
		var n := Vector3((at.call(ix - 1, iz) - at.call(ix + 1, iz)) / (2.0 * dx), 1.0,
			(at.call(ix, iz - 1) - at.call(ix, iz + 1)) / (2.0 * dz)).normalized()
		# Hollows a little darker, ridges a little lighter (baked vertex shading).
		var around: float = (at.call(ix - 2, iz) + at.call(ix + 2, iz) + at.call(ix, iz - 2) + at.call(ix, iz + 2)) * 0.25
		var shade := clampf(1.0 + (y - around) * 0.06 + R.detail.get_noise_2d(x * 0.3, z * 0.3) * 0.05, 0.78, 1.1)
		return [Vector3(x, y, z), n, Color(shade, shade, shade)]
	var cache := {}
	for iz in nz:
		for ix in nx:
			var q: Array = []
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var key := Vector2i(ix + o.x, iz + o.y)
				if not cache.has(key):
					cache[key] = vtx.call(key.x, key.y)
				q.append(cache[key])
			var tris := [[0, 1, 2], [0, 2, 3]] if (ix + iz) % 2 == 0 else [[0, 1, 3], [1, 2, 3]]
			for t in tris:
				var p0: Vector3 = q[t[0]][0]
				var p1: Vector3 = q[t[1]][0]
				var p2: Vector3 = q[t[2]][0]
				var fn := (p2 - p0).cross(p1 - p0).normalized()
				var steep: bool = fn.y < R.cliff_normal_y
				var kit := cliff if steep else ground
				for i: int in t:
					var p: Vector3 = q[i][0]
					kit.verts.append(p)
					kit.normals.append(q[i][1])
					var col: Color = q[i][2]
					if steep:
						col = Color(col.r * R.cliff_col.r, col.g * R.cliff_col.g, col.b * R.cliff_col.b)
						# Wrap the cliff texture around the area once; v follows height.
						var u := (p.x - b.position.x) / b.size.x if absf(fn.z) > absf(fn.x) else (p.z - b.position.y) / b.size.y
						kit.uvs.append(Vector2(u, 1.0 - (p.y - y_lo) / maxf(y_hi - y_lo, 1.0)))
					else:
						kit.uvs.append(Vector2((p.x - b.position.x) / b.size.x, (p.z - b.position.y) / b.size.y))
					kit.colors.append(col)
	var mesh := ArrayMesh.new()
	ground.add_to(mesh, M["ground_" + R.id])
	cliff.add_to(mesh, M.cliff_rock)
	var body := StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	body.collision_mask = 0
	var sg: Array = R.surface_grid()
	body.set_meta("surface_grid", sg[0])
	body.set_meta("surface_rect", sg[1])
	body.set_meta("surface_size", sg[2])
	root.add_child(body)
	_mesh_instance(body, "TerrainMesh", mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)


func _sky() -> void:
	var sky := Node3D.new()
	sky.name = "SkyDome"
	sky.set_script(load("res://scripts/systems/sky_dome.gd"))
	root.add_child(sky)
	var k := MeshKit.new(4)
	var seg := 24
	var elevs := [-25.0, -6.0, 0.0, 6.0, 14.0, 26.0, 42.0, 62.0, 90.0]
	for r in elevs.size() - 1:
		var e0 := deg_to_rad(elevs[r])
		var e1 := deg_to_rad(elevs[r + 1])
		var v0 := clampf((90.0 - elevs[r]) / 100.0, 0.0, 1.0)
		var v1 := clampf((90.0 - elevs[r + 1]) / 100.0, 0.0, 1.0)
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p00 := Vector3(sin(a0) * cos(e0), sin(e0), -cos(a0) * cos(e0)) * SKY_RADIUS
			var p10 := Vector3(sin(a1) * cos(e0), sin(e0), -cos(a1) * cos(e0)) * SKY_RADIUS
			var p01 := Vector3(sin(a0) * cos(e1), sin(e1), -cos(a0) * cos(e1)) * SKY_RADIUS
			var p11 := Vector3(sin(a1) * cos(e1), sin(e1), -cos(a1) * cos(e1)) * SKY_RADIUS
			var uv := [Vector2(float(i) / seg, v0), Vector2(float(i + 1) / seg, v0), Vector2(float(i + 1) / seg, v1), Vector2(float(i) / seg, v1)]
			_inward_quad(k, [p00, p10, p11, p01], uv, Color.WHITE)
	_mesh_instance(sky, "Dome", k.build(M["sky_" + R.id]))
	# Distant silhouettes: a ring of hills and the region's landmarks, drawn without fog.
	var far := MeshKit.new(8)
	var hr := RandomNumberGenerator.new()
	hr.seed = R.seed_value + 11
	var hills := 32
	var hill_col: Color = R.mood.horizon
	var hill_h: float = R.mood.get("hill_height", 10.0)
	var tops: Array = []
	for i in hills:
		tops.append(hr.randf_range(hill_h * 0.3, hill_h))
	for i in hills:
		var a0 := TAU * i / hills
		var a1 := TAU * (i + 1) / hills
		var rr := SKY_RADIUS - 15.0
		var t0 := Vector3(sin(a0) * rr, tops[i], -cos(a0) * rr)
		var t1 := Vector3(sin(a1) * rr, tops[(i + 1) % hills], -cos(a1) * rr)
		far.face_dir([Vector3(t0.x, -60, t0.z), Vector3(t1.x, -60, t1.z), t1, t0], hill_col, -(t0 + t1) * Vector3(1, 0, 1))
	for f in R.mood.get("far", []):
		_far_feature(far, f)
	_mesh_instance(sky, "Horizon", far.build(M.sky))
	if R.mood.has("particles"):
		_particles(sky, R.mood.particles)


func _inward_quad(k: MeshKit, p: Array, uv: Array, col: Color) -> void:
	for t in [[0, 1, 2], [0, 2, 3]]:
		var a: Vector3 = p[t[0]]
		var b: Vector3 = p[t[1]]
		var cc: Vector3 = p[t[2]]
		var n := -(a + b + cc).normalized()
		var order := [t[0], t[2], t[1]] if (b - a).cross(cc - a).dot(n) > 0 else [t[0], t[1], t[2]]
		for idx: int in order:
			k.verts.append(p[idx])
			k.normals.append(n)
			k.colors.append(col)
			k.uvs.append(uv[idx])


## A landmark on the horizon: {"type": "peak"|"castle"|"mesa"|"tower", "yaw": deg
## clockwise from north, "w", "h", "col", "snow": bool}.
func _far_feature(k: MeshKit, f: Dictionary) -> void:
	var yaw := deg_to_rad(f.yaw)
	var dist := SKY_RADIUS - 25.0
	var dir := Vector3(sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, sin(yaw))
	var base := dir * dist + Vector3(0, -20, 0)
	var col: Color = f.col
	var w: float = f.w
	var hh: float = f.h
	match f.type:
		"peak":
			var top := base + Vector3(0, hh + 20, 0) + right * w * 0.08
			var l := base - right * w * 0.5
			var r := base + right * w * 0.5
			k.face_dir([l, r, top], col, -dir)
			var shoulder := base + right * w * 0.28 + Vector3(0, hh * 0.55 + 20, 0)
			k.face_dir([base + right * 0.05 * w, r + right * w * 0.2, shoulder], col.darkened(0.12), -dir)
			if f.get("snow", false):
				var s := 0.3
				var sl := top.lerp(l, s)
				var sr := top.lerp(r, s)
				k.face_dir([sl - dir * 0.5, sr - dir * 0.5, top - dir * 0.5], Color(0.93, 0.95, 1.0), -dir)
		"mesa":
			var l := base - right * w * 0.5
			var r := base + right * w * 0.5
			var tl := base - right * w * 0.38 + Vector3(0, hh + 20, 0)
			var tr := base + right * w * 0.42 + Vector3(0, hh + 20, 0)
			k.face_dir([l, r, tr, tl], col, -dir)
		"castle", "tower":
			var towers: Array = [[0.0, 1.0, 0.16]] if f.type == "tower" else [[-0.42, 0.62, 0.1], [-0.18, 0.8, 0.1], [0.0, 1.0, 0.14], [0.2, 0.78, 0.1], [0.42, 0.6, 0.1]]
			if f.type == "castle":
				var wl := base - right * w * 0.5
				var wr := base + right * w * 0.5
				k.face_dir([wl, wr, wr + Vector3(0, 20 + hh * 0.4, 0), wl + Vector3(0, 20 + hh * 0.4, 0)], col, -dir)
			for t in towers:
				var cx: Vector3 = base + right * w * t[0] - dir * 0.5
				var th: float = 20 + hh * t[1]
				var tw: float = w * t[2]
				var bl: Vector3 = cx - right * tw * 0.5
				var br: Vector3 = cx + right * tw * 0.5
				k.face_dir([bl, br, br + Vector3(0, th, 0), bl + Vector3(0, th, 0)], col.darkened(0.05), -dir)
				var roof: Color = f.get("roof", col.darkened(0.2))
				k.face_dir([bl + Vector3(0, th, 0) - right * tw * 0.12 - dir * 0.2, br + Vector3(0, th, 0) + right * tw * 0.12 - dir * 0.2, cx + Vector3(0, th + tw * 1.4, 0) - dir * 0.2], roof, -dir)


func _particles(parent: Node3D, kind: String) -> void:
	var p := CPUParticles3D.new()
	p.name = "Particles"
	p.local_coords = false
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	match kind:
		"snow":
			quad.size = Vector2(0.07, 0.07)
			p.amount = 500
			p.lifetime = 5.0
			p.position = Vector3(0, 10, 0)
			p.emission_box_extents = Vector3(22, 1, 22)
			p.direction = Vector3(0.3, -1, 0.1)
			p.spread = 15.0
			p.gravity = Vector3(0, -1.2, 0)
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 1.8
			p.color = Color(1, 1, 1, 0.9)
		"motes":
			quad.size = Vector2(0.06, 0.06)
			p.amount = 120
			p.lifetime = 6.0
			p.position = Vector3(0, 1.5, 0)
			p.emission_box_extents = Vector3(16, 2, 16)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.gravity = Vector3(0, 0.05, 0)
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.25
			p.color = Color(0.75, 1.0, 0.7, 0.85)
		"embers":
			# Sparks and ash drifting up from the burning town.
			quad.size = Vector2(0.07, 0.07)
			p.amount = 220
			p.lifetime = 5.0
			p.position = Vector3(0, 0.5, 0)
			p.emission_box_extents = Vector3(22, 2, 22)
			p.direction = Vector3(0.2, 1, 0.1)
			p.spread = 25.0
			p.gravity = Vector3(0.2, 0.35, 0)
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.2
			p.color = Color(1.0, 0.55, 0.2, 0.9)
		"ghost":
			# Pale motes drifting between dead trees (the Forest of the Dead).
			quad.size = Vector2(0.05, 0.05)
			p.amount = 140
			p.lifetime = 7.0
			p.position = Vector3(0, 1.2, 0)
			p.emission_box_extents = Vector3(18, 2, 18)
			p.direction = Vector3(0.2, 0.3, 0)
			p.spread = 180.0
			p.gravity = Vector3(0, 0.02, 0)
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.2
			p.color = Color(0.65, 0.85, 1.0, 0.7)
		"ash":
			# Gray ash drifting down out of a dead sky (the Batela Fells).
			quad.size = Vector2(0.07, 0.07)
			p.amount = 420
			p.lifetime = 6.0
			p.position = Vector3(0, 10, 0)
			p.emission_box_extents = Vector3(22, 1, 22)
			p.direction = Vector3(0.5, -1, 0.2)
			p.spread = 25.0
			p.gravity = Vector3(0.15, -0.6, 0)
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.2
			p.color = Color(0.55, 0.53, 0.5, 0.85)
		"dust":
			quad.size = Vector2(0.05, 0.05)
			p.amount = 160
			p.lifetime = 4.0
			p.position = Vector3(0, 1.0, 0)
			p.emission_box_extents = Vector3(18, 1.5, 18)
			p.direction = Vector3(1, 0.1, 0.2)
			p.spread = 20.0
			p.gravity = Vector3(0, -0.1, 0)
			p.initial_velocity_min = 1.5
			p.initial_velocity_max = 3.0
			p.color = Color(0.95, 0.85, 0.6, 0.6)
	parent.add_child(p)


func _hero() -> void:
	var player: Node3D = load("res://scenes/player/player.tscn").instantiate()
	player.name = "Player"
	if _entrances.get_child_count() > 0:
		var m: Node3D = _entrances.get_child(0)
		player.transform = Transform3D(Basis(Vector3.UP, m.rotation.y), m.position)
	root.add_child(player)
	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://scripts/camera/adventure_camera.gd"))
	root.add_child(rig)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.fov = 60.0
	cam.near = 0.1
	cam.far = 300.0
	rig.add_child(cam)
	rig.set("target", player)
	player.set("camera_rig", rig)


func _boundary() -> void:
	# Last-resort walls just inside the terrain's outer edge (at the corridor ends).
	var o: float = R.outer - 2.0
	var x0: float = R.x_min - o
	var x1: float = R.x_max + o
	var z0: float = R.z_min - o
	var z1: float = R.z_max + o
	for seg in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x0, z1)], [Vector2(x0, z1), Vector2(x0, z0)]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var mid := (a + b) * 0.5
		var d := b - a
		col_box(Vector3(mid.x, 20, mid.y), Vector3(d.length(), 140, 1.0), -atan2(d.y, d.x))


# --- Exits and entrances ------------------------------------------------------

static func yaw_of(dir: Vector2) -> float:
	return atan2(-dir.x, -dir.y)


func _link(l: Dictionary) -> void:
	var p: Vector2 = l.p
	var d: Vector2 = l.d.normalized()
	var yaw := yaw_of(d)
	var ex := Area3D.new()
	ex.name = "To_" + l.to
	ex.set_script(load("res://scripts/systems/area_exit.gd"))
	ex.set("target_area", l.to)
	ex.set("target_entrance", "from_" + R.link_name())
	ex.position = Vector3(p.x, l.y + 2.5, p.y)
	ex.rotation.y = yaw
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(l.w * 2.0 + l.wall * 2.0, 8.0, 2.0)
	cs.shape = box
	ex.add_child(cs)
	_exits.add_child(ex)
	var s: Vector2 = p + d * l.spawn
	entrance("from_" + l.to, s.x, s.y, yaw)
	# Fog-colored veil at the far end of the corridor, so it fades into haze.
	var far: Vector2 = p - d * (R.outer - 1.5)
	var right := Vector3(-d.y, 0, d.x)
	var half: float = l.w + l.wall + 6.0
	var centre := Vector3(far.x, l.y - 3.0, far.y)
	var k := _tmp(false)
	k.shade_jitter = 0.0
	var top := Vector3(0, maxf(R.rim_height, 10.0) + 2.0, 0)
	k.face_dir([centre - right * half, centre + right * half, centre + right * half + top, centre - right * half + top],
		R.mood.fog, Vector3(d.x, 0, d.y))
	merge(k, "veil")


func entrance(entrance_name: String, x: float, z: float, yaw: float) -> void:
	var m := Marker3D.new()
	m.name = entrance_name
	m.position = g(x, z, 0.05)
	m.rotation.y = yaw
	_entrances.add_child(m)


func void_zone(center: Vector3, size: Vector3, damage := 0) -> void:
	var a := Area3D.new()
	a.name = "DeepWater%d" % _misc.get_child_count()
	a.set_script(load("res://scripts/systems/void_zone.gd"))
	a.set("damage", damage)
	a.position = center
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	a.add_child(cs)
	_misc.add_child(a)


func void_cylinder(center: Vector3, r: float, height: float) -> void:
	var a := Area3D.new()
	a.name = "DeepWater%d" % _misc.get_child_count()
	a.set_script(load("res://scripts/systems/void_zone.gd"))
	a.position = center
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = height
	cs.shape = cyl
	a.add_child(cs)
	_misc.add_child(a)


# --- Water --------------------------------------------------------------------

func water_plane(rect: Rect2, y: float, col: Color) -> void:
	var k := _tmp()
	k.shade_jitter = 0.0
	k.uv_box = AABB(Vector3(rect.position.x, y, rect.position.y), Vector3(rect.size.x, 0.01, rect.size.y))
	k.uv_box_locked = true
	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := rect.end.x
	var z1 := rect.end.y
	k.face_dir([Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)], col, Vector3.UP)
	var mi := _mesh_instance(_misc, "Water%d" % _misc.get_child_count(), k.build(M.water))
	mi.set_meta("water_y", y)
	_water.append([rect, y])


## A curtain of falling water facing `facing` (Vector2 direction), with spray at the foot.
## `col`: the water (Black Water Ridge's falls are black).
func waterfall(top: Vector3, width: float, drop: float, facing: Vector2, col := Color(0.75, 0.88, 1.0, 0.85)) -> void:
	var f := Vector3(facing.x, 0, facing.y).normalized()
	var right := Vector3(-f.z, 0, f.x)
	var k := _tmp()
	k.shade_jitter = 0.0
	var a := top - right * width * 0.5
	var b := top + right * width * 0.5
	k.uv_box = AABB(top - Vector3(width, drop, width), Vector3(width * 2.0, drop, width * 2.0))
	k.uv_box_locked = true
	var lean := f * 0.8
	k.face_dir([a, b, b + Vector3(0, -drop, 0) + lean, a + Vector3(0, -drop, 0) + lean], col, f)
	_mesh_instance(_misc, "Waterfall%d" % _misc.get_child_count(), k.build(M.water))
	var spray := _tmp(false)
	for i in 4:
		var p := top + Vector3(0, -drop, 0) + lean + right * width * (i / 3.0 - 0.5) + f * 0.4
		spray.icosa(p, Vector3(width * 0.22, 0.5, width * 0.18), 0.25, Color(0.92, 0.96, 1.0).lerp(Color(col.r, col.g, col.b), 0.8 if col.v < 0.3 else 0.0))
	merge(spray, "char")


# --- Nature -------------------------------------------------------------------

## Ways that must stay open: the walkway of every exit corridor, and the
## approach to every cave mouth and door (added as they are built). A tree,
## rock, stump, log or cactus scattered onto one is left out, so nothing
## stands in a way in or out.
var _keep_clear: Array = []


## Keeps a circle clear of scattered props from now on.
func keep_clear(c: Vector2, r: float) -> void:
	_keep_clear.append([c, r])


## True when a prop of radius `r` at (x, z) would stand in a way in or out.
func in_the_way(x: float, z: float, r := 0.5) -> bool:
	if R != null and "links" in R and R.has_method("seg_dist"):
		for l: Dictionary in R.links:
			if not l.get("corridor", true):
				continue
			var lp: Vector2 = l.p
			var ld: Vector2 = l.d
			var inner: Vector2 = lp + ld * (R.rim_margin + R.rim_run + R.rim_wobble + 6.0)
			if R.seg_dist(Vector2(x, z), lp - ld * R.outer, inner) < maxf(float(l.w) - 1.2, 1.8) + r:
				return true
	for kc: Array in _keep_clear:
		if Vector2(x, z).distance_to(kc[0]) < float(kc[1]) + r:
			return true
	return false


func tree_round(x: float, z: float, s := 1.0, leaf := Color(1, 1, 1)) -> void:
	if in_the_way(x, z, 0.5 * s):
		return
	var p := g(x, z)
	var hh := 3.2 * s * rng.randf_range(0.85, 1.15)
	var trunk := _tmp()
	trunk.push(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))
	trunk.prism(Vector3(0, -0.3, 0), 0.38 * s, Vector3(0, hh, 0), 0.22 * s, 6, Color(1, 1, 1))
	trunk.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-50)), Vector3(0.1 * s, hh * 0.55, 0)))
	trunk.prism(Vector3.ZERO, 0.09 * s, Vector3(0, 0.9 * s, 0), 0.04 * s, 4, Color(1, 1, 1))
	trunk.pop()
	trunk.pop()
	merge(trunk, "bark")
	var crown := _tmp()
	var cr := 2.0 * s * rng.randf_range(0.85, 1.15)
	crown.icosa(p + Vector3(0, hh + cr * 0.55, 0), Vector3(cr, cr * 0.8, cr), 0.18, leaf, true)
	crown.icosa(p + Vector3(cr * 0.45, hh + cr * 0.15, cr * 0.2), Vector3(cr * 0.6, cr * 0.5, cr * 0.6), 0.2, leaf * 0.9)
	merge(crown, "leaves")
	col_cyl(p, 0.38 * s, hh)


## The giant trunks of the forest: they vanish up into the fog.
func tree_giant(x: float, z: float, r := 1.2, hh := 30.0) -> void:
	var p := g(x, z, -0.4)
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))
	k.prism(Vector3.ZERO, r * 1.2, Vector3(0, hh * 0.35, 0), r * 0.95, 7, Color(1, 1, 1))
	k.prism(Vector3(0, hh * 0.35, 0), r * 0.95, Vector3(0, hh, 0), r * 0.7, 7, Color(0.9, 0.9, 0.9))
	for i in 4:
		var a := TAU * i / 4.0 + rng.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		k.slab(d * r * 0.9, Vector2(r * 0.7, r * 0.7), d * r * 1.9 + Vector3(0, -0.3, 0), Vector2(0.2, 0.2), Color(0.95, 0.95, 0.95))
		k.slab(d * r * 0.5 + Vector3(0, 0.0, 0), Vector2(r * 0.6, r * 0.6), d * r * 0.8 + Vector3(0, r * 1.6, 0), Vector2(0.1, 0.1), Color(0.95, 0.95, 0.95))
	for i in 2:
		var a := rng.randf() * TAU
		k.push(Transform3D(Basis(Vector3(sin(a), 0, -cos(a)), deg_to_rad(60)), Vector3(0, hh * rng.randf_range(0.45, 0.7), 0)))
		k.prism(Vector3.ZERO, r * 0.3, Vector3(0, r * 3.5, 0), r * 0.1, 5, Color(1, 1, 1))
		k.pop()
	k.pop()
	merge(k, "bark")
	var crown := _tmp()
	for i in 3:
		var o := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * r * 3.0
		var cr := r * rng.randf_range(4.0, 6.0)
		crown.icosa(p + Vector3(0, hh * rng.randf_range(0.85, 1.0), 0) + o, Vector3(cr, cr * 0.5, cr), 0.2, Color(0.75, 0.8, 0.75))
	merge(crown, "leaves")
	col_cyl(p, r * 1.05, hh)


func tree_pine(x: float, z: float, s := 1.0, snow := false) -> void:
	if in_the_way(x, z, 0.4 * s):
		return
	var p := g(x, z)
	var trunk := _tmp()
	trunk.prism(p + Vector3(0, -0.3, 0), 0.25 * s, p + Vector3(0, 1.4 * s, 0), 0.18 * s, 5, Color(0.85, 0.85, 0.85))
	merge(trunk, "bark")
	var k := _tmp()
	var caps := _tmp()
	var tiers := 3
	for i in tiers:
		var y0 := (1.0 + i * 1.5) * s
		var r := (1.9 - i * 0.45) * s
		var top := y0 + 2.2 * s
		var off := rng.randf() * TAU
		k.prism(p + Vector3(0, y0, 0), r, p + Vector3(0, top, 0), 0.0, 7, Color(1, 1, 1), off)
		if snow:
			caps.prism(p + Vector3(0, lerpf(y0, top, 0.45) + 0.06, 0), r * 0.58, p + Vector3(0, top + 0.08, 0), 0.0, 7, Color(1, 1, 1), off)
	merge(k, "pine")
	merge(caps, "snow")
	col_cyl(p, 0.3 * s, 3.0 * s)


func tree_dead(x: float, z: float, s := 1.0) -> void:
	if in_the_way(x, z, 0.5 * s):
		return
	var p := g(x, z, -0.2)
	var k := _tmp()
	var col := Color(0.72, 0.68, 0.66)
	k.push(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p))
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)) * s
	var mid := Vector3(0, 2.2 * s, 0) + lean
	var top := mid + Vector3(0, 2.0 * s, 0) - lean * 0.6
	k.prism(Vector3.ZERO, 0.4 * s, mid, 0.26 * s, 5, col)
	_branch(k, mid, top, 0.26 * s, 0.1 * s, col)
	for i in 4:
		var a := rng.randf() * TAU
		var from := Vector3.ZERO.lerp(mid, rng.randf_range(0.6, 1.0))
		var to := from + Vector3(cos(a) * 1.4, rng.randf_range(0.5, 1.4), sin(a) * 1.4) * s
		_branch(k, from, to, 0.12 * s, 0.03 * s, col)
	k.pop()
	merge(k, "bark")
	col_cyl(p, 0.4 * s, 3.5 * s)


## Tapered limb between two points (local to the kit's transform).
func _branch(k: MeshKit, a: Vector3, b: Vector3, r0: float, r1: float, col: Color) -> void:
	var d := b - a
	var basis := Basis()
	if d.normalized().abs() != Vector3.UP:
		var axis := Vector3.UP.cross(d.normalized()).normalized()
		basis = Basis(axis, Vector3.UP.angle_to(d.normalized()))
	k.push(Transform3D(basis, a))
	k.prism(Vector3.ZERO, r0, Vector3(0, d.length(), 0), r1, 4, col)
	k.pop()


func tree_palm(x: float, z: float, s := 1.0) -> void:
	if in_the_way(x, z, 0.4 * s):
		return
	var p := g(x, z, -0.2)
	var k := _tmp()
	var bend := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * 0.5 * s
	var prev := p
	var top := p
	for i in 5:
		var t := (i + 1) / 5.0
		top = p + Vector3(0, 6.0 * s * t, 0) + bend * t * t * 4.0
		_branch(k, prev, top, 0.3 * s * (1.0 - t * 0.4), 0.26 * s * (1.0 - t * 0.4), Color(1, 1, 1))
		prev = top
	merge(k, "bark")
	var fr := _tmp()
	for i in 7:
		var a := TAU * i / 7.0 + rng.randf() * 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var tip := top + d * 3.0 * s + Vector3(0, -1.4 * s, 0)
		var midp := top + d * 1.6 * s + Vector3(0, 0.3 * s, 0)
		var side := Vector3(-d.z, 0, d.x) * 0.45 * s
		fr.face_dir([top, midp + side, tip, midp - side], Color(0.85, 1.0, 0.8), Vector3.UP)
	merge(fr, "leaves")
	col_cyl(p, 0.3 * s, 5.0 * s)


## The great tree of the Hidden Forest.
func tree_great(x: float, z: float, s := 1.0) -> void:
	var p := g(x, z, -0.5)
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, 0.4), p))
	k.prism(Vector3.ZERO, 3.2 * s, Vector3(0, 6 * s, 0), 2.4 * s, 9, Color(1, 1, 1))
	k.prism(Vector3(0, 6 * s, 0), 2.4 * s, Vector3(0.6, 13 * s, 0.3), 1.6 * s, 9, Color(0.95, 0.95, 0.95))
	for i in 7:
		var a := TAU * i / 7.0
		var d := Vector3(cos(a), 0, sin(a))
		k.slab(d * 2.4 * s, Vector2(1.6, 1.6) * s, d * 6.0 * s + Vector3(0, -0.6, 0), Vector2(0.4, 0.4) * s, Color(0.9, 0.9, 0.9))
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		_branch(k, Vector3(0, 10 * s, 0), Vector3(cos(a) * 7.0, 15.0, sin(a) * 7.0) * s, 0.9 * s, 0.4 * s, Color(1, 1, 1))
	k.pop()
	merge(k, "bark")
	var crown := _tmp()
	crown.icosa(p + Vector3(0, 17 * s, 0), Vector3(11, 5.5, 11) * s, 0.15, Color(0.95, 1.0, 0.9), true)
	for i in 6:
		var a := TAU * i / 6.0
		crown.icosa(p + Vector3(cos(a) * 8.0, 14.5, sin(a) * 8.0) * s, Vector3(5, 3.5, 5) * s, 0.2, Color(0.85, 0.95, 0.85))
	merge(crown, "leaves")
	col_cyl(p, 3.0 * s, 12.0 * s)


func bush(x: float, z: float, s := 1.0, col := Color(0.85, 0.95, 0.85)) -> void:
	var k := _tmp()
	var r := 0.6 * s
	k.icosa(g(x, z, r * 0.35), Vector3(r, r * 0.7, r), 0.2, col)
	merge(k, "leaves")


func rock(x: float, z: float, s := 1.0, mat := "rock", collide := true, col := Color(1, 1, 1)) -> void:
	if collide and s > 0.45 and in_the_way(x, z, s):
		return
	var k := _tmp()
	k.icosa(g(x, z, s * 0.3), Vector3(s, s * rng.randf_range(0.55, 0.85), s * rng.randf_range(0.8, 1.1)), 0.22, col)
	merge(k, mat)
	if collide and s > 0.45:
		col_convex(k)


## Tall irregular stone column or mesa with a flat top.
func spire(x: float, z: float, r: float, hh: float, mat := "rock", col := Color(1, 1, 1), top_scale := 0.7, sides := 7) -> void:
	var p := g(x, z, -0.5)
	var k := _tmp()
	var bottom: Array = []
	var top: Array = []
	for i in sides:
		var a := TAU * i / sides + rng.randf_range(-0.2, 0.2)
		var rr := r * rng.randf_range(0.8, 1.15)
		bottom.append(p + Vector3(cos(a) * rr, 0, sin(a) * rr))
		top.append(p + Vector3(cos(a) * rr * top_scale, hh * rng.randf_range(0.95, 1.05), sin(a) * rr * top_scale))
	var box := AABB(p - Vector3(r, 0, r), Vector3(r * 2, hh, r * 2))
	k.uv_box = box
	k.uv_box_locked = true
	var center := p + Vector3(0, hh * 0.5, 0)
	for i in sides:
		var j := (i + 1) % sides
		k.face([bottom[i], bottom[j], top[j], top[i]], col, center)
	k.face(top, col * 1.08, center)
	merge(k, mat)
	col_convex(k)


func cactus(x: float, z: float, s := 1.0) -> void:
	if in_the_way(x, z, 0.4 * s):
		return
	var p := g(x, z, -0.1)
	var k := _tmp(false)
	var col := c("3f6a2a")
	k.prism(p, 0.28 * s, p + Vector3(0, 2.4 * s, 0), 0.24 * s, 6, col)
	k.icosa(p + Vector3(0, 2.4 * s, 0), Vector3(0.24, 0.18, 0.24) * s, 0.0, col)
	for side in [-1.0, 1.0]:
		var y := rng.randf_range(0.8, 1.4) * s
		var arm := p + Vector3(0.55 * side * s, y, 0)
		k.box(p + Vector3(0.3 * side * s, y, 0), Vector3(0.5 * s, 0.32 * s, 0.32 * s), col * 0.95)
		k.prism(arm, 0.17 * s, arm + Vector3(0, 0.8 * s, 0), 0.15 * s, 5, col)
	merge(k, "char")
	col_cyl(p, 0.3 * s, 2.4 * s)


func reeds(x: float, z: float, count := 6, col := Color.html("6a7a3a")) -> void:
	var k := _tmp(false)
	for i in count:
		var p := g(x + rng.randf_range(-0.8, 0.8), z + rng.randf_range(-0.8, 0.8), -0.1)
		var t := p + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(1.0, 1.8), rng.randf_range(-0.2, 0.2))
		k.face_dir([p - Vector3(0.05, 0, 0), p + Vector3(0.05, 0, 0), t], col, Vector3(0, 0, 1))
		k.face_dir([p - Vector3(0.05, 0, 0), p + Vector3(0.05, 0, 0), t], col * 0.85, Vector3(0, 0, -1))
		if i % 3 == 0:
			k.prism(t - Vector3(0, 0.3, 0), 0.05, t, 0.04, 4, c("5a3a22"))
	merge(k, "char")


func flowers(x: float, z: float, radius := 2.0, count := 8, cols := ["d8382c", "f0d040", "f0f0f0"]) -> void:
	var k := _tmp(false)
	for i in count:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * radius
		var p := g(x + cos(a) * d, z + sin(a) * d)
		k.box(p + Vector3(0, 0.14, 0), Vector3(0.03, 0.28, 0.03), c("3c6a22"))
		k.icosa(p + Vector3(0, 0.32, 0), Vector3(0.1, 0.07, 0.1), 0.15, c(cols[i % cols.size()]))
	merge(k, "char")


func stump(x: float, z: float, s := 1.0) -> void:
	if in_the_way(x, z, 0.7 * s):
		return
	var k := _tmp()
	var p := g(x, z, -0.2)
	k.prism(p, 0.7 * s, p + Vector3(0, 0.8 * s, 0), 0.6 * s, 7, Color(1, 1, 1), 0.0, c("b89a6a"))
	merge(k, "bark")
	col_cyl(p, 0.65 * s, 0.9 * s)


func log(x: float, z: float, length := 4.0, yaw := 0.0, r := 0.45) -> void:
	if in_the_way(x, z, length * 0.5):
		return
	var k := _tmp()
	var p := g(x, z, r * 0.7)
	k.push(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI / 2.0), p))
	k.prism(Vector3(0, -length * 0.5, 0), r, Vector3(0, length * 0.5, 0), r * 0.9, 7, Color(1, 1, 1), 0.0, c("b89a6a"))
	k.pop()
	merge(k, "bark")
	col_box(p, Vector3(length, r * 1.8, r * 1.8), yaw)


func mushroom(x: float, z: float, s := 1.0, cap := Color.html("c03a2a")) -> void:
	var k := _tmp(false)
	var p := g(x, z)
	k.prism(p, 0.12 * s, p + Vector3(0, 0.5 * s, 0), 0.1 * s, 5, c("e8dcc0"))
	k.prism(p + Vector3(0, 0.45 * s, 0), 0.42 * s, p + Vector3(0, 0.75 * s, 0), 0.0, 7, cap)
	merge(k, "char")


func lily(x: float, z: float, y: float) -> void:
	var k := _tmp(false)
	var p := Vector3(x, y + 0.02, z)
	var pts: Array = []
	var notch := rng.randf() * TAU
	for i in 7:
		var a := notch + 0.5 + (TAU - 1.0) * i / 6.0
		pts.append(p + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.35, 0.5))
	pts.append(p)
	k.face_dir(pts, c("3a7a30"), Vector3.UP)
	merge(k, "char")


# --- Buildings ----------------------------------------------------------------

## Gabled house. `front` faces +Z before `yaw` is applied (door side).
## opts: wall (material), roof (material), storeys, chimney, door (bool), timber_col.
func house(x: float, z: float, yaw: float, w: float, d: float, wall_h: float, wall_col: Color, roof_col: Color, opts := {}) -> void:
	var base := g(x, z) if not opts.has("y") else Vector3(x, opts.y, z)
	base.y -= 0.2
	var basis := Basis(Vector3.UP, yaw)
	var xf := Transform3D(basis, base)
	var wall_mat: String = opts.get("wall", "plaster")
	var roof_mat: String = opts.get("roof", "roof")
	var roof_h: float = opts.get("roof_h", minf(w, d) * 0.55)
	var o := 0.35
	var body := _tmp()
	body.push(xf)
	body.box(Vector3(0, wall_h * 0.5, 0), Vector3(w, wall_h, d), wall_col)
	# Gable ends carry the wall material up to the ridge.
	for sz in [-1.0, 1.0]:
		var zz: float = sz * d * 0.5
		body.uv_box = AABB(Vector3(-w * 0.5, wall_h, zz), Vector3(w, roof_h, 0.01))
		body.uv_box_locked = true
		body.face([Vector3(-w * 0.5, wall_h, zz), Vector3(w * 0.5, wall_h, zz), Vector3(0, wall_h + roof_h, zz)], wall_col, Vector3(0, wall_h, 0))
		body.uv_box_locked = false
	body.pop()
	merge(body, wall_mat)
	# Roof ridge runs along X... rotated so the gables face front/back (along Z).
	var roof := _tmp()
	roof.push(xf)
	var ridge := wall_h + roof_h
	for sx in [-1.0, 1.0]:
		var e := Vector3(sx * (w * 0.5 + o), wall_h - o * roof_h / (w * 0.5), 0)
		var pts := [Vector3(e.x, e.y, -d * 0.5 - o), Vector3(e.x, e.y, d * 0.5 + o), Vector3(0, ridge, d * 0.5 + o), Vector3(0, ridge, -d * 0.5 - o)]
		roof.hexa([pts[0], pts[1], pts[2], pts[3], pts[0] + Vector3(0, 0.18, 0), pts[1] + Vector3(0, 0.18, 0), pts[2] + Vector3(0, 0.18, 0), pts[3] + Vector3(0, 0.18, 0)], roof_col)
	if opts.get("chimney", false):
		roof.box(Vector3(w * 0.25, ridge - 0.2, -d * 0.2), Vector3(0.6, 1.6, 0.6), c("8a7a6a"))
	roof.pop()
	merge(roof, roof_mat)
	# Door and windows.
	var trim := _tmp(false)
	trim.push(xf)
	var dark := c("1c1a26")
	if opts.get("door", true):
		var dw: float = opts.get("door_w", 1.2)
		trim.box(Vector3(opts.get("door_x", 0.0), 1.1, d * 0.5 + 0.05), Vector3(dw + 0.3, 2.35, 0.1), c("4a3a2a"))
	var storeys: int = opts.get("storeys", maxi(1, int(wall_h / 2.8)))
	for st in storeys:
		var wy: float = 1.6 + st * 2.8 if storeys > 1 else 1.7
		if wy + 0.6 > wall_h:
			break
		var cols := maxi(1, int(w / 2.6))
		for i in cols:
			var wx := -w * 0.5 + w * (i + 0.5) / cols
			if st == 0 and absf(wx - opts.get("door_x", 0.0)) < 1.2 and opts.get("door", true):
				continue
			trim.box(Vector3(wx, wy, d * 0.5 + 0.04), Vector3(0.75, 0.9, 0.08), dark)
			trim.box(Vector3(wx, wy, -d * 0.5 - 0.04), Vector3(0.75, 0.9, 0.08), dark)
		var side_cols := maxi(1, int(d / 3.0))
		for i in side_cols:
			var wz := -d * 0.5 + d * (i + 0.5) / side_cols
			trim.box(Vector3(w * 0.5 + 0.04, wy, wz), Vector3(0.08, 0.9, 0.75), dark)
			trim.box(Vector3(-w * 0.5 - 0.04, wy, wz), Vector3(0.08, 0.9, 0.75), dark)
	trim.pop()
	merge(trim, "char")
	if opts.get("door", true):
		var door := _tmp()
		door.push(xf)
		door.box(Vector3(opts.get("door_x", 0.0), 1.05, d * 0.5 + 0.08), Vector3(opts.get("door_w", 1.2), 2.1, 0.1), Color(1, 1, 1))
		door.pop()
		merge(door, "door")
	var hull := PackedVector3Array()
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			hull.append(xf * Vector3(sx * w, 0.0, sz * d))
			hull.append(xf * Vector3(sx * w, wall_h, sz * d))
	hull.append(xf * Vector3(0, wall_h + roof_h, -d * 0.5))
	hull.append(xf * Vector3(0, wall_h + roof_h, d * 0.5))
	col_points(hull)


## Round (or many-sided) tower with a conical roof and a sealed door facing `door_yaw`.
func tower(x: float, z: float, r: float, hh: float, wall_mat: String, wall_col: Color, roof_col: Color, door_yaw := 0.0, opts := {}) -> void:
	var p := g(x, z, -0.3) if not opts.has("y") else Vector3(x, opts.y, z)
	var sides: int = opts.get("sides", 10)
	var k := _tmp()
	k.prism(p, r * 1.08, p + Vector3(0, hh, 0), r, sides, wall_col)
	if opts.get("crenel", false):
		for i in sides:
			var a := TAU * (i + 0.5) / sides
			k.box(p + Vector3(cos(a) * r * 1.02, hh + 0.45, sin(a) * r * 1.02), Vector3(0.7, 0.9, 0.7), wall_col)
	merge(k, wall_mat)
	var roof_h: float = opts.get("roof_h", r * 1.8)
	if roof_h > 0.0:
		var rk := _tmp()
		rk.prism(p + Vector3(0, hh - 0.1, 0), r * 1.25, p + Vector3(0, hh + roof_h, 0), 0.0, sides, roof_col)
		merge(rk, opts.get("roof", "roof"))
	# Window slits up the shaft.
	var slits := _tmp(false)
	var levels := int(hh / 4.5)
	for i in levels:
		var a := door_yaw + PI * 0.5 * (i % 4) + 0.6
		var dir := Vector3(-sin(a), 0, -cos(a))
		slits.push(Transform3D(Basis(Vector3.UP, a), p + dir * (r * 1.0) + Vector3(0, 4.0 + i * 4.5, 0)))
		slits.box(Vector3.ZERO, Vector3(0.45, 1.2, 0.2), c("16141e"))
		slits.pop()
	merge(slits, "char")
	var dd := Vector3(-sin(door_yaw), 0, -cos(door_yaw))
	# "seal": "open" leaves the doorway for the caller (a door into an interior).
	if opts.get("seal", "wood") != "open":
		sealed_door(p + dd * (r * 1.04) + Vector3(0, 0.3, 0), door_yaw, opts.get("door_w", 1.8), opts.get("door_h", 2.8), opts.get("seal", "wood"), opts.get("seal_col", Color(0.3, 0.5, 1.0)))
	col_cyl(p, r * 1.05, hh)


## Wall along a polyline of ground points. Walls follow the ground under each segment.
func wall_line(pts: Array, wall_h: float, t: float, mat: String, col: Color, crenel := false, y := INF) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var mid := (a + b) * 0.5
		var dvec := b - a
		var length := dvec.length()
		var yaw := -atan2(dvec.y, dvec.x)
		var base := minf(h(a.x, a.y), minf(h(b.x, b.y), h(mid.x, mid.y))) - 0.4 if y == INF else y
		var k := _tmp()
		k.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, base, mid.y)))
		k.box(Vector3(0, wall_h * 0.5, 0), Vector3(length + t, wall_h, t), col)
		if crenel:
			var n := int(length / 1.6)
			for j in n:
				var cx := -length * 0.5 + (j + 0.5) * length / n
				k.box(Vector3(cx, wall_h + 0.4, 0), Vector3(0.8, 0.8, t * 1.02), col)
		k.pop()
		merge(k, mat)
		col_box(Vector3(mid.x, base + wall_h * 0.5, mid.y), Vector3(length + t, wall_h, t), yaw)


## Two towers joined by an arch over a passage `opening` wide, facing along `yaw`.
func gatehouse(x: float, z: float, yaw: float, opening: float, hh: float, mat: String, col: Color, roof_col := Color(0, 0, 0, 0)) -> void:
	var base := g(x, z, -0.4)
	var basis := Basis(Vector3.UP, yaw)
	var tw := 3.2
	for sx in [-1.0, 1.0]:
		var cpos := base + basis * Vector3(sx * (opening * 0.5 + tw * 0.5), 0, 0)
		var k := _tmp()
		k.push(Transform3D(basis, cpos))
		k.box(Vector3(0, hh * 0.5, 0), Vector3(tw, hh, tw), col)
		for cx in [-1.0, 1.0]:
			for cz in [-1.0, 1.0]:
				k.box(Vector3(cx * tw * 0.35, hh + 0.4, cz * tw * 0.35), Vector3(0.7, 0.8, 0.7), col)
		k.pop()
		merge(k, mat)
		if roof_col.a > 0.0:
			var rk := _tmp()
			rk.prism(cpos + Vector3(0, hh, 0), tw * 0.8, cpos + Vector3(0, hh + tw * 1.2, 0), 0.0, 4, roof_col, PI / 4.0 + yaw)
			merge(rk, "roof")
		col_box(cpos + Vector3(0, hh * 0.5, 0), Vector3(tw, hh, tw), yaw)
	var arch := _tmp()
	arch.push(Transform3D(basis, base))
	arch.box(Vector3(0, hh - 1.2, 0), Vector3(opening + 0.2, 2.4, tw * 0.9), col)
	arch.pop()
	merge(arch, mat)
	col_box(base + Vector3(0, hh - 1.2, 0), Vector3(opening, 2.4, tw * 0.9), yaw)


func fence(pts: Array, col := Color(0.9, 0.9, 0.9), post_h := 1.1) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var dvec := b - a
		var n := maxi(1, int(dvec.length() / 2.2))
		var k := _tmp()
		for j in n + 1:
			var q := a.lerp(b, float(j) / n)
			var p := g(q.x, q.y, -0.1)
			k.prism(p, 0.09, p + Vector3(0, post_h, 0), 0.08, 4, col)
		for j in n:
			var q0 := a.lerp(b, float(j) / n)
			var q1 := a.lerp(b, float(j + 1) / n)
			for ry in [0.45, 0.85]:
				var p0 := g(q0.x, q0.y, ry * post_h)
				var p1 := g(q1.x, q1.y, ry * post_h)
				_branch(k, p0, p1, 0.05, 0.05, col)
		merge(k, "wood")
		var mid := (a + b) * 0.5
		col_box(g(mid.x, mid.y, post_h * 0.5), Vector3(dvec.length(), post_h + 0.4, 0.25), -atan2(dvec.y, dvec.x)).set_meta("no_climb", true)


## Bridge deck from `a` to `b` (deck-top points), arching up by `rise` in the middle, with rails.
func bridge(a: Vector3, b: Vector3, width: float, mat := "wood", rise := 0.6, rail_col := Color(0.85, 0.85, 0.85), rail_mat := "wood", rails := true) -> void:
	var segs := 6
	var pts: Array = []
	for i in segs + 1:
		var t := float(i) / segs
		pts.append(a.lerp(b, t) + Vector3(0, sin(t * PI) * rise, 0))
	var flat := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
	var right := Vector3(-flat.z, 0, flat.x)
	var yaw := atan2(-flat.x, -flat.z)
	for i in segs:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var mid := (p0 + p1) * 0.5
		var dvec := p1 - p0
		var basis := Basis.looking_at(dvec.normalized(), Vector3.UP)
		var k := _tmp()
		k.push(Transform3D(basis, mid))
		k.box(Vector3(0, -0.18, 0), Vector3(width, 0.36, dvec.length() + 0.05), Color(1, 1, 1))
		k.pop()
		merge(k, mat)
		col_box_basis(mid + basis * Vector3(0, -0.18, 0), Vector3(width, 0.36, dvec.length() + 0.05), basis)
		# Rails (solid, so nobody walks off the side).
		if not rails:
			var post := _tmp()
			for sx in [-1.0, 1.0]:
				var q: Vector3 = p0 + right * sx * (width * 0.5 - 0.1)
				post.prism(q + Vector3(0, -1.6, 0), 0.1, q, 0.1, 4, rail_col)
			merge(post, rail_mat)
			continue
		for sx in [-1.0, 1.0]:
			var r0: Vector3 = p0 + right * sx * (width * 0.5 - 0.1)
			var r1: Vector3 = p1 + right * sx * (width * 0.5 - 0.1)
			var rk := _tmp()
			rk.prism(r0, 0.09, r0 + Vector3(0, 1.0, 0), 0.08, 4, rail_col)
			_branch(rk, r0 + Vector3(0, 0.95, 0), r1 + Vector3(0, 0.95, 0), 0.07, 0.07, rail_col)
			if i == segs - 1:
				rk.prism(r1, 0.09, r1 + Vector3(0, 1.0, 0), 0.08, 4, rail_col)
			merge(rk, rail_mat)
			col_box_basis((r0 + r1) * 0.5 + Vector3(0, 0.6, 0), Vector3(0.2, 1.3, dvec.length()), basis).set_meta("no_climb", true)
	var _unused := yaw


## Visual steps with a smooth ramp collider, climbing `rise` along the stairs' facing.
func stairs(x: float, z: float, yaw: float, width: float, length: float, rise: float, mat := "stone", base_y := INF) -> void:
	var base := Vector3(x, h(x, z) if base_y == INF else base_y, z)
	var basis := Basis(Vector3.UP, yaw)
	var steps := maxi(2, int(rise / 0.3))
	var k := _tmp()
	k.push(Transform3D(basis, base))
	for i in steps:
		var t := float(i + 1) / steps
		var sl := length * (1.0 - float(i) / steps)
		# Each slab sits exactly on the one below: overlapping slabs z-fight.
		k.box(Vector3(0, rise * t - rise / steps * 0.5, -length + sl * 0.5), Vector3(width, rise / steps, sl), Color(1, 1, 1))
	k.pop()
	merge(k, mat)
	var ramp := ConvexPolygonShape3D.new()
	var pts := PackedVector3Array()
	for v in [Vector3(-width * 0.5, 0, 0), Vector3(width * 0.5, 0, 0), Vector3(-width * 0.5, rise, -length), Vector3(width * 0.5, rise, -length),
			Vector3(-width * 0.5, 0, -length), Vector3(width * 0.5, 0, -length)]:
		pts.append(v)
	ramp.points = pts
	_shape(ramp, Transform3D(basis, base))


## Paved platform (flat top at `top_y`).
func platform(x: float, z: float, size: Vector2, top_y: float, mat := "stone", col := Color(1, 1, 1), yaw := 0.0) -> void:
	var low := minf(h(x, z), top_y) - 2.0
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(x, 0, z)))
	k.box(Vector3(0, (top_y + low) * 0.5, 0), Vector3(size.x, top_y - low, size.y), col)
	k.pop()
	merge(k, mat)
	col_box(Vector3(x, (top_y + low) * 0.5, z), Vector3(size.x, top_y - low, size.y), yaw)


## The floor of an upper storey: a slab whose top is at `top_y` over the x/z
## rectangle `r`, with `holes` (Rect2s) left open where the storey below shows
## through (drops, lift shafts). Built as the fewest boxes that tile the rest.
func floor_slab(r: Rect2, top_y: float, holes: Array = [], mat := "stone", col := Color(1, 1, 1), thick := 0.5) -> void:
	var xs: Array[float] = [r.position.x, r.end.x]
	var cut: Array[Rect2] = []
	for hr: Rect2 in holes:
		if r.intersects(hr):
			cut.append(r.intersection(hr))
			xs.append(maxf(hr.position.x, r.position.x))
			xs.append(minf(hr.end.x, r.end.x))
	xs.sort()
	for i in xs.size() - 1:
		var x0 := xs[i]
		var x1 := xs[i + 1]
		if x1 - x0 < 0.01:
			continue
		var mid := (x0 + x1) * 0.5
		var spans: Array = [[r.position.y, r.end.y]]
		for hr in cut:
			if mid <= hr.position.x or mid >= hr.end.x:
				continue
			var rest: Array = []
			for sp: Array in spans:
				if hr.end.y <= sp[0] or hr.position.y >= sp[1]:
					rest.append(sp)
					continue
				if hr.position.y > sp[0]:
					rest.append([sp[0], hr.position.y])
				if hr.end.y < sp[1]:
					rest.append([hr.end.y, sp[1]])
			spans = rest
		for sp: Array in spans:
			if sp[1] - sp[0] < 0.01:
				continue
			block(Vector3(mid, top_y - thick * 0.5, (sp[0] + sp[1]) * 0.5), Vector3(x1 - x0, thick, sp[1] - sp[0]), 0.0, mat, col * rng.randf_range(0.96, 1.03))


## A platform that rides between its place and `travel` away (scripts/dungeon/
## lift.gd): it sets off once the hero stands on it, and comes to fetch him
## when he waits by either end. `loop` keeps it shuttling on its own.
func lift(center: Vector3, size: Vector3, travel: Vector3, mat := "stone", col := Color(1, 1, 1), opts := {}) -> Node3D:
	var props := {"travel": travel}
	props.merge(opts)
	var b := _dyn("res://scripts/dungeon/lift.gd", "Lift", center, 0.0, props, AnimatableBody3D.new())
	var k := MeshKit.new(_seed)
	_seed += 1
	k.textured = true
	k.box(Vector3(0, -size.y * 0.5, 0), size, col)
	# A darker rim round the top so its edge reads against the floor below.
	for e in [[Vector3(0, -0.05, size.z * 0.5 - 0.1), Vector3(size.x, 0.12, 0.2)], [Vector3(0, -0.05, -size.z * 0.5 + 0.1), Vector3(size.x, 0.12, 0.2)],
			[Vector3(size.x * 0.5 - 0.1, -0.05, 0), Vector3(0.2, 0.12, size.z - 0.4)], [Vector3(-size.x * 0.5 + 0.1, -0.05, 0), Vector3(0.2, 0.12, size.z - 0.4)]]:
		k.box(e[0] + Vector3(0, 0.02, 0), e[1], col.darkened(0.35))
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = k.build(M[mat])
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(0, -size.y * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone" if mat != "wood" else "wood")
	b.add_child(cs)
	return b


## Free-standing solid block (lintels, slabs, ledges).
func block(center: Vector3, size: Vector3, yaw := 0.0, mat := "stone", col := Color(1, 1, 1)) -> CollisionShape3D:
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, yaw), center))
	k.box(Vector3.ZERO, size, col)
	k.pop()
	merge(k, mat)
	return col_box(center, size, yaw)


## Closed doorway: a stone frame around a door. kind "wood" = barred wooden door,
## "seal" = stone slab with a glowing emblem, "grate" = iron bars over darkness.
func sealed_door(pos: Vector3, yaw: float, w: float, hh: float, kind := "wood", emblem := Color(0.3, 0.5, 1.0)) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var xf := Transform3D(basis, pos)
	var frame := _tmp()
	frame.push(xf)
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(sx * (w * 0.5 + 0.3), hh * 0.5, 0), Vector3(0.6, hh, 0.7), Color(1, 1, 1))
	frame.box(Vector3(0, hh + 0.35, 0), Vector3(w + 1.2, 0.7, 0.75), Color(1, 1, 1))
	frame.pop()
	merge(frame, "stone")
	var slab := _tmp()
	slab.push(xf)
	match kind:
		"seal":
			slab.box(Vector3(0, hh * 0.5, -0.05), Vector3(w, hh, 0.3), Color(0.85, 0.85, 0.9))
			slab.pop()
			merge(slab, "seal")
			var em := _tmp(false)
			em.push(xf * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, hh * 0.55, -0.22)))
			em.prism(Vector3(0, -0.06, 0), w * 0.3, Vector3(0, 0.06, 0), w * 0.3, 8, emblem)
			em.pop()
			merge(em, "glow")
		"grate":
			slab.pop()
			var gr := _tmp(false)
			gr.push(xf)
			gr.box(Vector3(0, hh * 0.5, 0.25), Vector3(w, hh, 0.05), c("08080c"))
			var bars := int(w / 0.35)
			for i in bars:
				gr.box(Vector3(-w * 0.5 + (i + 0.5) * w / bars, hh * 0.5, -0.05), Vector3(0.08, hh, 0.08), c("3a3a44"))
			for yy in [0.4, hh * 0.5, hh - 0.3]:
				gr.box(Vector3(0, yy, -0.05), Vector3(w, 0.1, 0.1), c("3a3a44"))
			gr.pop()
			merge(gr, "char")
		_:
			slab.box(Vector3(0, hh * 0.5, -0.05), Vector3(w, hh, 0.3), Color(1, 1, 1))
			slab.pop()
			merge(slab, "door")
			var bar := _tmp(false)
			bar.push(xf)
			bar.box(Vector3(0, hh * 0.5, -0.25), Vector3(w + 0.4, 0.25, 0.12), c("3a3a44"))
			bar.box(Vector3(0, hh * 0.5, -0.32), Vector3(0.4, 0.5, 0.1), c("6a5a2a"))
			bar.pop()
			merge(bar, "char")
	col_box(pos + basis * Vector3(0, hh * 0.5, 0), Vector3(w + 1.2, hh, 0.8), yaw)
	if kind == "seal":
		var icon := Marker3D.new()
		icon.name = "Dungeon%d" % _icons.get_child_count()
		icon.position = pos
		_icons.add_child(icon)


## Cave mouth in a slope: a dark hollow framed by rocks, blocked by a boulder,
## a grate, or ("bomb") a cracked boulder a bomb breaks: then `prize` (a
## GetItem chest id, or "heart_piece") shows in the mouth.
## The flag a cave's way in (and its prize) is known by: `flag` when given,
## else made from the region and the spot. A region drawn in two versions
## (the field, and the field at war) passes the same `flag` in both, so a
## cave opened (and its prize taken) in one stays so in the other.
func _cave_key(x: float, z: float, flag: String) -> String:
	return flag if flag != "" else "%s:cave_%d_%d" % [R.id, int(x), int(z)]


func cave(x: float, z: float, yaw: float, w := 3.0, hh := 3.0, block := "boulder", prize := "", flag := "") -> void:
	var basis := Basis(Vector3.UP, yaw)
	var fwd := basis * Vector3(0, 0, -1)
	var p := g(x, z, -0.2)
	keep_clear(Vector2(p.x + fwd.x * 2.4, p.z + fwd.z * 2.4), 2.2)
	var k := _tmp(false)
	k.push(Transform3D(basis, p))
	k.face_dir([Vector3(-w * 0.5, 0, 0.6), Vector3(w * 0.5, 0, 0.6), Vector3(w * 0.4, hh, 0.6), Vector3(0, hh * 1.15, 0.6), Vector3(-w * 0.4, hh, 0.6)], c("07060a"), Vector3(0, 0, -1))
	k.pop()
	merge(k, "char")
	var rk := _tmp()
	for i in 5:
		var a := PI * i / 4.0
		var rp := p + basis * Vector3(cos(a) * (w * 0.62), sin(a) * hh * 0.95 + 0.2, 0.2)
		rk.icosa(rp, Vector3(1.2, 1.1, 1.3) * rng.randf_range(0.8, 1.2), 0.25, Color(1, 1, 1))
	merge(rk, "rock")
	col_box(p + basis * Vector3(0, hh * 0.5, 0.6), Vector3(w, hh, 1.2), yaw)
	if block == "bomb":
		var open_flag := _cave_key(x, z, flag)
		bomb_boulder(p.x + fwd.x * 0.6, p.z + fwd.z * 0.6, yaw, open_flag, p.y)
		var at := p + fwd * 1.7
		if prize == "heart_piece":
			heart_piece(at.x, at.z, open_flag + "_heart", at.y + 0.2, open_flag)
		elif prize != "":
			chest(at.x, at.z, yaw, prize, false, open_flag + "_chest", open_flag, at.y)
	elif block == "heavy":
		# A heavy rock (the Bun Bracers) sits in the hollow over the prize.
		var gone := _cave_key(x, z, flag)
		var at := p + fwd * 1.5
		heavy_rock(at.x, at.z, gone, at.y + 0.15)
		if prize == "heart_piece":
			heart_piece(at.x, at.z, gone + "_heart", at.y + 0.35, gone)
		elif prize != "":
			chest(at.x, at.z, yaw, prize, false, gone + "_chest", gone, at.y + 0.15)
	elif block == "great":
		# A great stone (the Questlord's Gauntlets) dragged out of the mouth.
		var moved := _cave_key(x, z, flag)
		var at := p + fwd * 1.6
		great_stone(at.x, at.z, yaw + PI, moved, at.y - 0.1)
		var inner := p + fwd * 1.1
		if prize == "heart_piece":
			heart_piece(inner.x, inner.z, moved + "_heart", inner.y + 0.4, moved)
		elif prize != "":
			chest(inner.x, inner.z, yaw, prize, false, moved + "_chest", moved, inner.y + 0.1)
	elif block == "thorns" or block == "rime":
		# Black thorns or rime-ice (the Ember Rod) choking the mouth.
		var gone := _cave_key(x, z, flag)
		var at := p + fwd * 0.9
		burnable(block, at.x, at.z, yaw, gone, Vector3(w + 0.4, hh, 1.0), at.y - 0.1)
		var inner := p + fwd * 0.9
		if prize == "heart_piece":
			heart_piece(inner.x, inner.z, gone + "_heart", inner.y + 0.4, gone)
		elif prize != "":
			chest(inner.x, inner.z, yaw, prize, false, gone + "_chest", gone, inner.y + 0.1)
	elif block == "flail":
		# An old iron grate rusted across the mouth (Beta 1.4.0): only the
		# Iron Flail's ball bursts it.
		var gone := _cave_key(x, z, flag)
		var at := p + fwd * 0.7
		flail_target("gate", at.x, at.z, gone, at.y - 0.1, {"yaw": yaw, "size": w + 0.2, "tall": hh})
		var inner := p + fwd * 1.2
		if prize == "heart_piece":
			heart_piece(inner.x, inner.z, gone + "_heart", inner.y + 0.4, gone)
		elif prize != "":
			chest(inner.x, inner.z, yaw, prize, false, gone + "_chest", gone, inner.y + 0.1)
	elif block == "boulder":
		var b := _tmp()
		b.icosa(p + fwd * 0.4 + Vector3(0, w * 0.4, 0), Vector3(w * 0.48, w * 0.45, w * 0.42), 0.15, Color(0.85, 0.82, 0.8))
		merge(b, "rock")
		col_convex(b)
	else:
		sealed_door(p - fwd * 0.4 + Vector3(0, 0, 0), yaw + PI, w * 0.85, hh * 0.9, "grate")


## A cave mouth that leads somewhere (a Goddess Spring): built like cave(),
## but walking into the dark hollow loads `target_area`, and the hero comes
## back out at "from_<target_area>" in front of it. `block` "bomb" seals it
## with a cracked boulder (BombWall, flag "<target_area>:open") until a bomb
## breaks it. opts: y (the mouth's floor), w / h (its size), mound (a heap
## of rocks behind it, for a mouth on open ground), tint (the rocks' color).
func spring_cave(x: float, z: float, yaw: float, target_area: String, block := "", opts := {}) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var fwd := basis * Vector3(0, 0, -1)
	var p := g(x, z, -0.2) if not opts.has("y") else Vector3(x, opts.y, z)
	var w: float = opts.get("w", 3.0)
	var hh: float = opts.get("h", 3.2)
	var tint: Color = opts.get("tint", Color(1, 1, 1))
	keep_clear(Vector2(p.x + fwd.x * 2.8, p.z + fwd.z * 2.8), 2.6)
	if opts.get("mound", false):
		var m := _tmp()
		for i in 11:
			var a := PI * i / 10.0
			var mp := p + basis * Vector3(cos(a) * (w * 0.9 + 1.2), sin(a) * hh * 0.9 + 0.3, 2.2 + rng.randf_range(-0.4, 0.8))
			m.icosa(mp, Vector3(1.8, 1.7, 2.0) * rng.randf_range(0.85, 1.25), 0.25, tint)
		m.icosa(p + basis * Vector3(0, hh * 1.05, 2.4), Vector3(w * 0.8, 1.6, 2.4), 0.25, tint)
		m.icosa(p + basis * Vector3(0, hh * 0.5, 3.6), Vector3(w + 1.6, hh * 0.9, 2.2), 0.2, tint)
		merge(m, "rock")
		col_box(p + basis * Vector3(0, hh * 0.65, 2.6), Vector3(w + 3.4, hh * 1.3, 4.2), yaw)
	var k := _tmp(false)
	k.push(Transform3D(basis, p))
	k.face_dir([Vector3(-w * 0.5, 0, 0.6), Vector3(w * 0.5, 0, 0.6), Vector3(w * 0.4, hh, 0.6), Vector3(0, hh * 1.15, 0.6), Vector3(-w * 0.4, hh, 0.6)], c("07060a"), Vector3(0, 0, -1))
	k.pop()
	merge(k, "char")
	var rk := _tmp()
	for i in 5:
		var a := PI * i / 4.0
		var rp := p + basis * Vector3(cos(a) * (w * 0.62), sin(a) * hh * 0.95 + 0.2, 0.2)
		rk.icosa(rp, Vector3(1.2, 1.1, 1.3) * rng.randf_range(0.8, 1.2), 0.25, tint)
	merge(rk, "rock")
	col_box(p + basis * Vector3(0, hh * 0.5, 0.6), Vector3(w, hh, 1.2), yaw)
	# The way in: a loading zone across the mouth, just before the dark.
	var ex := Area3D.new()
	ex.name = "To_" + target_area
	ex.set_script(load("res://scripts/systems/area_exit.gd"))
	ex.set("target_area", target_area)
	ex.set("target_entrance", "from_" + R.link_name())
	# Shut until a flag (the frozen falls over Frostpeak Hollow, Beta 1.5.0).
	ex.set("need_flag", opts.get("need_flag", ""))
	ex.position = p + basis * Vector3(0, 1.2, -0.2)
	ex.rotation.y = yaw
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(w * 0.8, 2.4, 0.7)
	cs.shape = box
	ex.add_child(cs)
	_exits.add_child(ex)
	var out := p + fwd * 2.6
	var mark := Marker3D.new()
	mark.name = "from_" + target_area
	mark.position = out + Vector3(0, 0.25, 0)
	mark.rotation.y = yaw
	_entrances.add_child(mark)
	if block == "bomb":
		bomb_boulder(p.x + fwd.x * 0.7, p.z + fwd.z * 0.7, yaw, target_area + ":open", p.y)


## A spring_cave at the foot of the first cliff found along `dir`, facing back out.
func spring_cave_in_cliff(x: float, z: float, dir: Vector2, target_area: String, block := "", opts := {}) -> void:
	var p := cliff_spot(x, z, dir)
	spring_cave(p.x, p.z, yaw_of(-dir), target_area, block, opts)


## Walks from (x, z) along `dir` until the ground rises into a cliff; returns the foot of it.
func cliff_spot(x: float, z: float, dir: Vector2, rise := 2.5) -> Vector3:
	var d := dir.normalized()
	var base := h(x, z)
	var p := Vector2(x, z)
	for i in 160:
		var q := p + d * 0.5
		if h(q.x, q.y) > base + rise:
			break
		p = q
	p -= d * 0.6
	return g(p.x, p.y)


## A sealed cave at the foot of the first cliff found along `dir`, facing back out.
func cave_in_cliff(x: float, z: float, dir: Vector2, w := 3.0, hh := 3.0, block := "boulder", prize := "", flag := "") -> void:
	var p := cliff_spot(x, z, dir)
	cave(p.x, p.z, yaw_of(-dir), w, hh, block, prize, flag)


## A fire burning on the ground (a house ablaze, a fallen beam): a cluster of
## flickering flames with a warm light. `size` scales it.
func fire(x: float, z: float, size := 1.0, y := INF, with_light := true) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var f := Node3D.new()
	f.name = "Fire%d" % _misc.get_child_count()
	f.position = p
	f.set_script(load("res://scripts/systems/torch_flicker.gd"))
	_misc.add_child(f)
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var mi := MeshInstance3D.new()
		mi.name = "FlameMesh%d" % i
		mi.mesh = load("res://assets/models/flame_mesh.tres")
		mi.position = Vector3(cos(a) * 0.35, 0.0, sin(a) * 0.35) * size if i > 0 else Vector3.ZERO
		mi.scale = Vector3.ONE * size * (2.6 if i == 0 else 1.8)
		f.add_child(mi)
	if not with_light:
		return
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 1.0 * size, 0)
	light.light_color = c("ff8a3a")
	light.light_energy = 1.6
	light.omni_range = 7.0 * size
	f.add_child(light)


## A heap of broken masonry and charred beams, solid, never a ledge.
func rubble(x: float, z: float, yaw := 0.0, s := 1.0, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), p)
	display_mesh("res://assets/models/rubble_mesh.tres", xf)
	col_box(p + Vector3(0, 0.4 * s, 0), Vector3(2.4 * s, 0.8 * s, 2.2 * s), yaw).set_meta("no_climb", true)


## A cracked stretch of wall (BombWall) facing `yaw`: a bomb opens it and sets `flag`.
func bomb_wall(x: float, z: float, yaw: float, flag: String, y := INF) -> Node3D:
	return _dyn("res://scripts/dungeon/bomb_wall.gd", "CrackedWall", g(x, z) if y == INF else Vector3(x, y, z), yaw, {"flag": flag}, StaticBody3D.new())


## A cracked boulder (BombWall) a bomb breaks, setting `flag`.
func bomb_boulder(x: float, z: float, yaw: float, flag: String, y := INF) -> Node3D:
	return _dyn("res://scripts/dungeon/bomb_wall.gd", "CrackedBoulder", g(x, z) if y == INF else Vector3(x, y, z), yaw, {"flag": flag, "boulder": true}, StaticBody3D.new())


func well(x: float, z: float) -> void:
	var p := g(x, z, -0.1)
	var k := _tmp()
	k.prism(p, 1.1, p + Vector3(0, 0.9, 0), 1.1, 10, Color(1, 1, 1), 0.0, c("1a1a20"))
	merge(k, "stone")
	var wd := _tmp()
	for sx in [-1.0, 1.0]:
		wd.box(p + Vector3(sx * 0.95, 1.6, 0), Vector3(0.15, 1.5, 0.15), Color(1, 1, 1))
	wd.box(p + Vector3(0, 2.4, 0), Vector3(2.3, 0.12, 0.15), Color(1, 1, 1))
	merge(wd, "wood")
	var roof := _tmp()
	roof.push(Transform3D(Basis(), p + Vector3(0, 2.4, 0)))
	for sz in [-1.0, 1.0]:
		roof.hexa([Vector3(-1.3, 0, sz * 1.1), Vector3(1.3, 0, sz * 1.1), Vector3(1.3, 0.8, 0), Vector3(-1.3, 0.8, 0),
			Vector3(-1.3, 0.1, sz * 1.1), Vector3(1.3, 0.1, sz * 1.1), Vector3(1.3, 0.9, 0), Vector3(-1.3, 0.9, 0)], c("a84a34"))
	roof.pop()
	merge(roof, "roof")
	col_cyl(p, 1.1, 1.0)


func fountain(x: float, z: float, r := 4.0, y := INF) -> void:
	var p := g(x, z, -0.1) if y == INF else Vector3(x, y, z)
	var k := _tmp()
	k.prism(p, r, p + Vector3(0, 0.8, 0), r, 12, Color(1, 1, 1))
	k.prism(p + Vector3(0, 0.8, 0), 0.6, p + Vector3(0, 2.2, 0), 0.45, 8, Color(1, 1, 1))
	k.prism(p + Vector3(0, 2.2, 0), 1.5, p + Vector3(0, 2.5, 0), 1.2, 10, Color(1, 1, 1))
	k.prism(p + Vector3(0, 2.5, 0), 0.25, p + Vector3(0, 3.3, 0), 0.15, 6, Color(1, 1, 1))
	merge(k, "stone")
	var wk := _tmp()
	wk.shade_jitter = 0.0
	var ring: Array = []
	for i in 12:
		var a := TAU * i / 12.0
		ring.append(p + Vector3(cos(a) * (r - 0.3), 0.7, sin(a) * (r - 0.3)))
	wk.uv_box = AABB(p - Vector3(r, 0, r), Vector3(r * 2, 1, r * 2))
	wk.uv_box_locked = true
	wk.face_dir(ring, Color(0.4, 0.65, 0.9, 0.8), Vector3.UP)
	_mesh_instance(_misc, "FountainWater%d" % _misc.get_child_count(), wk.build(M.water))
	col_cyl(p, r, 0.9)


func stall(x: float, z: float, yaw: float, cloth: Color) -> void:
	var p := g(x, z)
	var basis := Basis(Vector3.UP, yaw)
	var k := _tmp()
	k.push(Transform3D(basis, p))
	k.box(Vector3(0, 0.5, 0), Vector3(3.0, 1.0, 1.4), Color(1, 1, 1))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(sx * 1.4, 1.3, sz * 0.75), Vector3(0.12, 2.6, 0.12), Color(0.9, 0.9, 0.9))
	k.pop()
	merge(k, "wood")
	var awn := _tmp(false)
	awn.push(Transform3D(basis, p))
	awn.hexa([Vector3(-1.7, 2.5, -1.0), Vector3(1.7, 2.5, -1.0), Vector3(1.7, 2.2, 1.3), Vector3(-1.7, 2.2, 1.3),
		Vector3(-1.7, 2.62, -1.0), Vector3(1.7, 2.62, -1.0), Vector3(1.7, 2.32, 1.3), Vector3(-1.7, 2.32, 1.3)], cloth)
	for i in 4:
		awn.icosa(Vector3(-1.0 + i * 0.65, 1.15, 0.1), Vector3(0.25, 0.18, 0.25), 0.2, c(["d84a2a", "e8c040", "7ab040", "c86a2a"][i]))
	awn.pop()
	merge(awn, "char")
	col_box(p + Vector3(0, 0.6, 0), Vector3(3.0, 1.2, 1.4), yaw)


func crate(x: float, z: float, yaw := 0.0, s := 1.0, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, yaw), p))
	k.box(Vector3(0, s * 0.5, 0), Vector3(s, s, s), Color(1, 1, 1))
	k.pop()
	merge(k, "wood")
	col_box(p + Vector3(0, s * 0.5, 0), Vector3(s, s, s), yaw)


func barrel(x: float, z: float) -> void:
	var p := g(x, z)
	var k := _tmp()
	k.prism(p, 0.38, p + Vector3(0, 0.5, 0), 0.45, 8, Color(1, 1, 1))
	k.prism(p + Vector3(0, 0.5, 0), 0.45, p + Vector3(0, 1.0, 0), 0.38, 8, Color(1, 1, 1))
	merge(k, "wood")
	col_cyl(p, 0.44, 1.0)


func lamp(x: float, z: float) -> void:
	var p := g(x, z)
	var k := _tmp(false)
	k.prism(p, 0.12, p + Vector3(0, 3.0, 0), 0.08, 5, c("2c2c34"))
	k.box(p + Vector3(0, 3.25, 0), Vector3(0.4, 0.5, 0.4), c("2c2c34"))
	merge(k, "char")
	var glow := _tmp(false)
	glow.box(p + Vector3(0, 3.25, 0), Vector3(0.3, 0.38, 0.3) * 1.05, c("ffd890"))
	merge(glow, "glow")
	col_cyl(p, 0.15, 3.0)


## A readable (and cuttable) sign (scripts/items/signpost.gd) whose board
## faces `toward` (a ground point the reader comes from).
func signpost(x: float, z: float, toward: Vector2, text: String) -> void:
	var n := StaticBody3D.new()
	n.name = "Sign%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/signpost.gd"))
	n.set("text", text)
	n.position = g(x, z, -0.05)
	n.rotation.y = yaw_of(toward - Vector2(x, z))
	_misc.add_child(n)


## A cuttable shrub (scripts/items/shrub.gd). `regrow` shrubs grow back
## (ENKUSA_TYPE_1); `tint` colors the leaves.
func shrub(x: float, z: float, regrow := true, tint := Color(1, 1, 1), y := INF) -> void:
	var n := Node3D.new()
	n.name = "Shrub%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/shrub.gd"))
	n.set("regrow", regrow)
	n.set("tint", tint)
	n.position = g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	n.rotation.y = rng.randf() * TAU
	_misc.add_child(n)


## A small rock the hero can lift and throw (scripts/items/lift_rock.gd, En_Ishi).
func lift_rock(x: float, z: float, tint := Color(1, 1, 1), y := INF) -> void:
	var n := StaticBody3D.new()
	n.name = "LiftRock%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/lift_rock.gd"))
	n.set("tint", tint)
	n.position = g(x, z, -0.03) if y == INF else Vector3(x, y, z)
	n.rotation.y = rng.randf() * TAU
	_misc.add_child(n)
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.5, 0.6)
	_record_solid(box, Transform3D(Basis(), n.position + Vector3.UP * 0.25))


## A heavy rock (LiftRock.heavy): only the Bun Bracers lift it. Lifted away,
## `gone_flag` (if any) keeps it gone.
func heavy_rock(x: float, z: float, gone_flag := "", y := INF, drop_table := 0) -> void:
	var n := StaticBody3D.new()
	n.name = "HeavyRock%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/lift_rock.gd"))
	n.set("heavy", true)
	n.set("gone_flag", gone_flag)
	n.set("drop_table", drop_table)
	n.position = g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	n.rotation.y = rng.randf() * TAU
	_misc.add_child(n)
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.1, 1.3)
	_record_solid(box, Transform3D(Basis(), n.position + Vector3.UP * 0.55))


## A great stone (GreatStone, Chapter V): only the Questlord's Gauntlets drag
## it. It is gripped from its local +Z side (turned by `yaw`) and dragged
## that way; `flag` keeps it moved.
func great_stone(x: float, z: float, yaw: float, flag: String, y := INF, roll_side := 1.0, tint := Color(1, 1, 1), need_flag := "", wait_text := "") -> Node3D:
	var pos := g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	var n := _dyn("res://scripts/dungeon/great_stone.gd", "GreatStone", pos, yaw, {"flag": flag, "roll_side": roll_side, "tint": tint, "need_flag": need_flag, "wait_text": wait_text}, StaticBody3D.new())
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.15
	cyl.height = 2.3
	_record_solid(cyl, Transform3D(Basis(), pos + Vector3.UP * 1.15))
	return n


## Thorns, web or rime-ice (Burnable, Chapter V): the Ember Rod's fire clears
## it. `size` is its box (width across `yaw`, height, depth).
func burnable(kind: String, x: float, z: float, yaw: float, flag: String, size := Vector3(3.0, 2.6, 0.8), y := INF) -> Node3D:
	var pos := g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	return _dyn("res://scripts/dungeon/burnable.gd", "Burnable", pos, yaw, {"kind": kind, "flag": flag, "size": size}, StaticBody3D.new())


## Something for the Knight's Techniques (TechniqueTarget): mode "seal",
## "plate", "ring" or "pell".
func technique_target(mode: String, x: float, z: float, flag: String, y := INF, opts := {}) -> Node3D:
	var pos := g(x, z) if y == INF else Vector3(x, y, z)
	var props := {"mode": mode, "flag": flag}
	props.merge(opts)
	var yaw: float = opts.get("yaw", 0.0)
	props.erase("yaw")
	return _dyn("res://scripts/dungeon/technique_target.gd", "Technique" + mode.capitalize(), pos, yaw, props, StaticBody3D.new())


## Something only the Iron Flail breaks or rings (FlailTarget, Beta 1.4.0):
## mode "gate", "pillar" or "bell"; opts: yaw, size, tall.
func flail_target(mode: String, x: float, z: float, flag: String, y := INF, opts := {}) -> Node3D:
	var pos := g(x, z) if y == INF else Vector3(x, y, z)
	var props := {"mode": mode, "flag": flag}
	props.merge(opts)
	var yaw: float = opts.get("yaw", 0.0)
	props.erase("yaw")
	return _dyn("res://scripts/dungeon/flail_target.gd", "Flail" + mode.capitalize(), pos, yaw, props, StaticBody3D.new())


## A Looking Glass secret (LensObject): a box `size` at `center` (its middle),
## either "hidden" (a solid platform only the glass shows) or "fake" (a wall
## the hero walks straight through, the glass shows it for an illusion).
func lens_block(center: Vector3, size: Vector3, mode: String, mat := "stone", col := Color(1, 1, 1)) -> Node3D:
	var b := _dyn("res://scripts/dungeon/lens_object.gd", "Lens" + mode.capitalize(), center, 0.0, {"mode": mode}, StaticBody3D.new())
	var k := MeshKit.new(_seed)
	k.textured = true
	k.box(Vector3.ZERO, size, col)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = k.build(M[mat])
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.set_meta("no_climb", mode == "fake")
	cs.set_meta("surface", "stone")
	b.add_child(cs)
	return b


## Dream-light for Lothelye's Dream (DreamLight): a "path" slab solid only
## while the hero dreams (pale violet, faint and shimmering when awake), or a
## "veil" of the waking dark, solid until he dreams. `center` is the middle of
## the box.
func dream_light(center: Vector3, size: Vector3, mode := "path", col := Color(0.72, 0.64, 1.0)) -> Node3D:
	var b := _dyn("res://scripts/dungeon/dream_light.gd", "Dream" + mode.capitalize(), center, 0.0, {"mode": mode}, StaticBody3D.new())
	var k := MeshKit.new(_seed)
	if mode == "path":
		# A slab of light with a brighter rim, and little stars set in it.
		k.box(Vector3.ZERO, size, col)
		k.box(Vector3(0, size.y * 0.5 + 0.01, 0), Vector3(size.x - 0.2, 0.02, size.z - 0.2), col.lightened(0.35))
		var r := RandomNumberGenerator.new()
		r.seed = int(absf(center.x * 13.0 + center.z * 7.0))
		for i in maxi(2, int(size.x * size.z * 0.4)):
			k.icosa(Vector3(r.randf_range(-0.45, 0.45) * size.x, size.y * 0.5 + 0.03, r.randf_range(-0.45, 0.45) * size.z), Vector3(0.04, 0.02, 0.04), 0.0, Color(1, 1, 1))
	else:
		k.box(Vector3.ZERO, size, Color(0.08, 0.06, 0.16))
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = k.build(M.glow)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.set_meta("no_climb", mode == "veil")
	cs.set_meta("surface", "stone")
	b.add_child(cs)
	return b


## A star lock of the Astral Rift (StarLock): props flag, need_flag, pan_to,
## pan_text, display, star_col.
func star_lock(x: float, z: float, y: float, props: Dictionary) -> Node3D:
	var b := _dyn("res://scripts/dungeon/star_lock.gd", "StarLock", Vector3(x, y, z), 0.0, props, StaticBody3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/star_lock_mesh.tres")
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.5
	cyl.height = 0.9
	cs.shape = cyl
	cs.position = Vector3.UP * 0.45
	cs.set_meta("no_climb", true)
	b.add_child(cs)
	keep_clear(Vector2(x, z), 1.0)
	return b


## A ring of starlight (AstralGate) that carries the hero to the Marker3D
## `target` in the same area; asleep until `need_flag`.
func astral_gate(x: float, z: float, y: float, yaw: float, target: String, need_flag := "", asleep_text := "") -> Node3D:
	var a := _dyn("res://scripts/dungeon/astral_gate.gd", "AstralGate", Vector3(x, y, z), yaw,
		{"target": target, "need_flag": need_flag, "asleep_text": asleep_text}, Area3D.new())
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.1
	cyl.height = 3.0
	cs.shape = cyl
	cs.position = Vector3.UP * 1.5
	a.add_child(cs)
	return a


## A secret alcove against a room's wall (Looking Glass): solid side walls
## and a false front (LensObject "fake") the hero walks straight through,
## with a chest inside. `at` is the middle of the wall it backs onto, `out`
## the way into the room; it is `width` wide and `depth` deep, 3 m tall.
func lens_alcove(at: Vector2, out: Vector2, width: float, depth: float, y: float, item: String, flag: String, mat := "stone", col := Color(1, 1, 1)) -> void:
	var o := out.normalized()
	var side := Vector2(-o.y, o.x)
	var hh := 3.0
	for sx in [-1.0, 1.0]:
		var c: Vector2 = at + o * depth * 0.5 + side * sx * (width * 0.5 + 0.25)
		var size := Vector3(0.5, hh, depth) if absf(o.x) < 0.5 else Vector3(depth, hh, 0.5)
		block(Vector3(c.x, y + hh * 0.5, c.y), size, 0.0, mat, col)
	var f: Vector2 = at + o * (depth + 0.25)
	var fsize := Vector3(width + 1.0, hh, 0.5) if absf(o.x) < 0.5 else Vector3(0.5, hh, width + 1.0)
	lens_block(Vector3(f.x, y + hh * 0.5, f.y), fsize, "fake", mat, col)
	var cp: Vector2 = at + o * depth * 0.45
	chest(cp.x, cp.y, yaw_of(o), item, false, flag, "", y)


## A stake for the Iron Mallet (MalletStake): one blow drives it down and sets `flag`.
func mallet_stake(x: float, z: float, flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/mallet_stake.gd", "Stake", g(x, z) if y == INF else Vector3(x, y, z), 0.0, {"flag": flag}, StaticBody3D.new())


## A sheet of ice the Iron Mallet shatters (MalletStake.brittle), `size` wide,
## its face toward `yaw`.
func ice_sheet(x: float, z: float, yaw: float, flag: String, size := Vector3(4.0, 5.0, 0.6), y := INF) -> void:
	_dyn("res://scripts/dungeon/mallet_stake.gd", "IceSheet", g(x, z) if y == INF else Vector3(x, y, z), yaw, {"flag": flag, "brittle": true, "size": size}, StaticBody3D.new())


## Something to CHECK (Examine): `pages` of text, or a lines script; its front faces `yaw`.
func examine(pos: Vector3, yaw: float, pages: Array, lines_path := "", key := "", reach := 1.4) -> Node3D:
	var props := {"pages": pages, "key": key, "reach": reach}
	if lines_path != "":
		props["lines_script"] = load(lines_path)
	return _dyn("res://scripts/items/examine.gd", "Examine", pos, yaw, props, Node3D.new())


## Scenery shown only once `flag` is set (scripts/systems/flag_visible.gd): the
## kit `mk` (built in area coordinates) drawn with material `mat`. No collision.
func flag_props(flag: String, mk: MeshKit, mat: String, hide_flag := "") -> Node3D:
	var n := _dyn("res://scripts/systems/flag_visible.gd", "FlagProps", Vector3.ZERO, 0.0, {"flag": flag, "hide_flag": hide_flag}, Node3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mk.build(M[mat])
	n.add_child(mi)
	return n


## A solid barrier that goes once `gone_flag` is set (FlagBarrier): `mk`'s
## mesh in `mat`, a box `size` around `center`, turned `yaw`.
func flag_barrier(center: Vector3, size: Vector3, yaw: float, gone_flag: String, mk: MeshKit = null, mat := "rock", need_flag := "") -> Node3D:
	var b := _dyn("res://scripts/systems/flag_barrier.gd", "Barrier", center, yaw, {"gone_flag": gone_flag, "need_flag": need_flag}, StaticBody3D.new())
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.set_meta("no_climb", true)
	b.add_child(cs)
	if mk:
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = mk.build(M[mat])
		b.add_child(mi)
	return b


## A wall of whirling dust across a pass, `width` wide, facing `yaw`: solid
## until `gone_flag` is set (the old east road out of the desert).
func dust_wall(x: float, z: float, yaw: float, width: float, gone_flag: String, col := Color(0.9, 0.78, 0.55)) -> void:
	var p := g(x, z)
	var k := _tmp(false)
	k.shade_jitter = 0.0
	for i in 5:
		var off := (i - 2) * 0.7
		var a := col.lightened(0.08 * i)
		a.a = 0.55
		k.box(Vector3(0, 4.0 + i * 0.3, off), Vector3(width, 8.0 + i * 0.6, 0.05), a)
	var b := flag_barrier(p, Vector3(width, 10.0, 3.0), yaw, gone_flag, null)
	b.position.y += 5.0
	var mi := MeshInstance3D.new()
	mi.name = "Veil"
	mi.mesh = k.build(M["shadow"])
	mi.position.y = -5.0
	b.add_child(mi)
	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	dust.mesh = quad
	dust.amount = 260
	dust.lifetime = 2.5
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(width * 0.5, 4.0, 1.5)
	dust.direction = Vector3(1, 0.2, 0)
	dust.spread = 40.0
	dust.gravity = Vector3(0, 0, 0)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 6.0
	dust.color = Color(col.r, col.g, col.b, 0.5)
	b.add_child(dust)


## A loading zone `size` across at `pos`, facing `yaw`, into `target_area` at
## `target_entrance` (the Forest of the Dead's wrong ways lead back into
## the woods themselves).
func area_exit(pos: Vector3, yaw: float, size: Vector3, target_area: String, target_entrance: String) -> void:
	var ex := Area3D.new()
	ex.name = "To_%s_%d" % [target_area, _exits.get_child_count()]
	ex.set_script(load("res://scripts/systems/area_exit.gd"))
	ex.set("target_area", target_area)
	ex.set("target_entrance", target_entrance)
	ex.position = pos
	ex.rotation.y = yaw
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	ex.add_child(cs)
	_exits.add_child(ex)


## A wisp of the dead (wisp_light.gd) bobbing at `pos`, drifting toward `toward`.
func wisp(pos: Vector3, toward: Vector3, chime := true) -> void:
	_dyn("res://scripts/systems/wisp_light.gd", "Wisp", pos, 0.0, {"toward": toward, "chime": chime}, Node3D.new())


## A music zone (MusicZone): `track` plays while the hero is inside the box.
func music_zone(center: Vector3, size: Vector3, track: String) -> void:
	var z := _dyn("res://scripts/systems/music_zone.gd", "MusicZone", center, 0.0, {"track": track}, Area3D.new())
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	z.add_child(cs)


## A place where the story moves on (StoryTrigger): Story.<scene>() plays when
## the hero walks into `r` (x/z) at height `y`, once (`flag`), and only after
## `need` if given.
func story_trigger(scene: String, r: Rect2, y: float, flag: String, need := "", tall := 3.0) -> void:
	var a := Area3D.new()
	a.name = "Story_" + scene
	a.set_script(load("res://scripts/systems/story_trigger.gd"))
	a.set("scene", scene)
	a.set("flag", flag)
	a.set("need_flag", need)
	a.position = Vector3(r.get_center().x, y + tall * 0.5, r.get_center().y)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(r.size.x, tall, r.size.y)
	cs.shape = box
	a.add_child(cs)
	_misc.add_child(a)


## A named spot for cutscenes (Story._spot finds it by name).
func mark(mark_name: String, pos: Vector3, yaw := 0.0) -> void:
	var m := Marker3D.new()
	m.name = mark_name
	m.position = pos
	m.rotation.y = yaw
	_misc.add_child(m)


## Page `n` of the Fari Incunabulum (IncunabulumPage), torn out and lost: it
## floats over the ground at `x, z`; touching it reads it into the journal.
func incunabulum_page(x: float, z: float, n: int, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	_dyn("res://scripts/items/incunabulum_page.gd", "IncunabulumPage", p + Vector3(0, 0.9, 0), 0.0, {"page": n}, Area3D.new())


## A camp tent: a ridge of canvas over two poles, its open end facing `yaw`.
func tent(x: float, z: float, yaw: float, w: float, d: float, hh: float, cloth: Color, y := INF) -> void:
	var p := g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, yaw), p))
	var hw := w * 0.5
	var hd := d * 0.5
	for sx in [-1.0, 1.0]:
		k.face([Vector3(sx * hw, 0, -hd), Vector3(sx * hw, 0, hd), Vector3(0, hh, hd), Vector3(0, hh, -hd)], cloth.darkened(0.12 if sx > 0 else 0.0), Vector3(sx * 4.0, hh, 0))
	# The closed back.
	k.face([Vector3(-hw, 0, hd), Vector3(hw, 0, hd), Vector3(0, hh, hd)], cloth.darkened(0.2), Vector3(0, hh * 0.4, hd + 4.0))
	k.box(Vector3(0, hh * 0.5, -hd - 0.05), Vector3(0.08, hh, 0.08), Color.html("5a4630"))
	k.box(Vector3(0, hh + 0.02, 0), Vector3(0.08, 0.08, d + 0.2), Color.html("5a4630"))
	k.pop()
	merge(k, "char")
	col_box(p + Basis(Vector3.UP, yaw) * Vector3(0, hh * 0.35, hd * 0.3), Vector3(w * 0.8, hh * 0.7, d * 0.6), yaw).set_meta("no_climb", true)


## A target range (ArcheryRange) named `range_id`, its shooting line at `x, z`.
func archery_range(x: float, z: float, range_id: String) -> void:
	_dyn("res://scripts/items/archery_range.gd", "ArcheryRange", g(x, z), 0.0, {"range_id": range_id}, Node3D.new())


## Tansy's cup game (scripts/items/cup_game.gd): her table, its front toward `yaw`.
func cup_game(x: float, z: float, yaw: float, y := INF) -> Node3D:
	return _dyn("res://scripts/items/cup_game.gd", "CupGame", g(x, z) if y == INF else Vector3(x, y, z), yaw, {}, Node3D.new())


## The rooster of Haven (scripts/npc/rooster.gd), wandering round `x, z`.
func rooster(x: float, z: float, y := INF) -> void:
	_dyn("res://scripts/npc/rooster.gd", "Rooster", g(x, z) if y == INF else Vector3(x, y, z), rng.randf() * TAU, {}, CharacterBody3D.new())


## A clay pot (scripts/items/pot.gd) holding `item` ("" = a random drop).
func pot(x: float, z: float, item := "", glazed := false, y := INF) -> void:
	var n := StaticBody3D.new()
	n.name = "Pot%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/pot.gd"))
	n.set("item", item)
	n.set("glazed", glazed)
	n.position = g(x, z) if y == INF else Vector3(x, y, z)
	n.rotation.y = rng.randf() * TAU
	_misc.add_child(n)


## An item lying in the world for good (a rupee on a ledge, a heart...).
func collectible(kind: String, x: float, z: float, y := INF) -> void:
	var n := Area3D.new()
	n.name = "Item%d" % _misc.get_child_count()
	n.set_script(load("res://scripts/items/collectible.gd"))
	n.set("kind", kind)
	n.position = g(x, z, 0.05) if y == INF else Vector3(x, y, z)
	_misc.add_child(n)


## A creature from res://scenes/enemies/<kind>.tscn, facing `yaw`, with its
## exported settings overridden by `opts`.
func enemy(kind: String, x: float, z: float, yaw := 0.0, opts := {}, y := INF) -> Node3D:
	var path := "res://scenes/enemies/%s.tscn" % kind
	if not ResourceLoader.exists(path):
		push_error("WorldKit: no enemy scene %s" % path)
		return null
	var e: Node3D = load(path).instantiate()
	e.name = "%s%d" % [kind.to_pascal_case(), _enemies().get_child_count()]
	for key in opts:
		if key == "room":
			# The dungeon room it belongs to (DungeonRoom counts it).
			e.set_meta("room", opts[key])
		else:
			e.set(key, opts[key])
	if not opts.has("room") and y != INF and R.has_method("room_at"):
		var rid: String = R.room_at(x, z, y)
		if rid != "":
			e.set_meta("room", rid)
	# Never inside a table or a pillar: the nearest open spot round about.
	if y != INF and not free_at(x, y, z, 0.45):
		var moved := false
		for ring in range(1, 9):
			for i in 12:
				var a := TAU * i / 12.0
				var q := Vector2(x, z) + Vector2(cos(a), sin(a)) * ring * 0.5
				if free_at(q.x, y, q.y, 0.45):
					x = q.x
					z = q.y
					moved = true
					break
			if moved:
				break
	e.position = g(x, z, 0.1) if y == INF else Vector3(x, y, z)
	e.rotation.y = yaw
	_enemies().add_child(e)
	return e


func _enemies() -> Node3D:
	var n := root.get_node_or_null("Enemies") as Node3D
	if n == null:
		n = _node(root, "Enemies")
	return n


func haystack(x: float, z: float, s := 1.0) -> void:
	var k := _tmp()
	var p := g(x, z, -0.1)
	k.prism(p, 1.2 * s, p + Vector3(0, 1.0 * s, 0), 1.1 * s, 8, Color(1, 1, 1))
	k.prism(p + Vector3(0, 1.0 * s, 0), 1.1 * s, p + Vector3(0, 2.0 * s, 0), 0.0, 8, Color(1, 1, 1))
	merge(k, "thatch")
	col_cyl(p, 1.15 * s, 1.6 * s)


func windmill(x: float, z: float, yaw: float) -> void:
	var p := g(x, z, -0.3)
	var k := _tmp()
	k.prism(p, 3.2, p + Vector3(0, 10, 0), 2.2, 8, Color(1, 1, 1))
	merge(k, "plaster")
	var rk := _tmp()
	rk.prism(p + Vector3(0, 9.9, 0), 2.8, p + Vector3(0, 13.5, 0), 0.0, 8, c("8a4a32"))
	merge(rk, "roof")
	var basis := Basis(Vector3.UP, yaw)
	var hub := p + Vector3(0, 9.0, 0) + basis * Vector3(0, 0, 2.6)
	var bl := _tmp()
	bl.push(Transform3D(basis, hub))
	bl.box(Vector3.ZERO, Vector3(0.6, 0.6, 0.8), Color(0.8, 0.8, 0.8))
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		bl.push(Transform3D(Basis(Vector3(0, 0, 1), a), Vector3(0, 0, 0.3)))
		bl.box(Vector3(0, 3.6, 0), Vector3(0.25, 7.0, 0.12), Color(0.85, 0.85, 0.85))
		bl.box(Vector3(0.75, 4.2, 0.02), Vector3(1.3, 5.0, 0.06), Color(1, 1, 1))
		bl.pop()
	bl.pop()
	merge(bl, "wood")
	sealed_door(p + basis * Vector3(0, 0, 3.05), yaw + PI, 1.3, 2.3, "wood")
	col_cyl(p, 3.0, 10.0)


func statue(x: float, z: float, yaw: float, s := 1.0, mat := "stone", y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var k := _tmp()
	k.push(Transform3D(Basis(Vector3.UP, yaw), p))
	k.box(Vector3(0, 0.6 * s, 0), Vector3(1.4, 1.2, 1.4) * s, Color(1, 1, 1))
	k.slab(Vector3(0, 1.2 * s, 0), Vector2(0.8, 0.6) * s, Vector3(0, 2.8 * s, 0), Vector2(0.6, 0.45) * s, Color(0.95, 0.95, 0.95))
	k.icosa(Vector3(0, 3.15 * s, 0), Vector3(0.38, 0.42, 0.38) * s, 0.05, Color(0.95, 0.95, 0.95))
	k.prism(Vector3(0.5 * s, 1.2 * s, -0.1 * s), 0.08 * s, Vector3(0.5 * s, 3.6 * s, -0.1 * s), 0.05 * s, 4, Color(0.9, 0.9, 0.9))
	k.pop()
	merge(k, mat)
	col_box(p + Vector3(0, 1.4 * s, 0), Vector3(1.4, 2.8, 1.4) * s, yaw)


func pillar(x: float, z: float, hh := 4.0, r := 0.5, broken := false, mat := "stone", y := INF) -> void:
	var p := g(x, z, -0.1) if y == INF else Vector3(x, y, z)
	var k := _tmp()
	k.box(p + Vector3(0, 0.15, 0), Vector3(r * 2.6, 0.3, r * 2.6), Color(1, 1, 1))
	var top := hh * (rng.randf_range(0.35, 0.75) if broken else 1.0)
	k.prism(p, r, p + Vector3(0, top, 0), r * 0.9, 8, Color(1, 1, 1))
	if not broken:
		k.box(p + Vector3(0, hh + 0.15, 0), Vector3(r * 2.4, 0.3, r * 2.4), Color(1, 1, 1))
	merge(k, mat)
	col_cyl(p, r, top)


func banner(x: float, y: float, z: float, yaw: float, col: Color, length := 2.5) -> void:
	var k := _tmp(false)
	k.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z)))
	k.box(Vector3(0, 0, 0), Vector3(1.3, 0.08, 0.08), c("3a3030"))
	k.face_dir([Vector3(-0.55, 0, 0.05), Vector3(0.55, 0, 0.05), Vector3(0.55, -length, 0.05), Vector3(0, -length - 0.4, 0.05), Vector3(-0.55, -length, 0.05)], col, Vector3(0, 0, 1))
	k.face_dir([Vector3(-0.55, 0, 0.04), Vector3(0.55, 0, 0.04), Vector3(0.55, -length, 0.04), Vector3(0, -length - 0.4, 0.04), Vector3(-0.55, -length, 0.04)], col * 0.8, Vector3(0, 0, -1))
	k.pop()
	merge(k, "char")


## Iron brazier stand; unlit ones are future puzzle torches.
func brazier(x: float, z: float, lit := false, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var k := _tmp(false)
	k.prism(p, 0.25, p + Vector3(0, 1.0, 0), 0.12, 5, c("3a3a42"))
	k.prism(p + Vector3(0, 1.0, 0), 0.15, p + Vector3(0, 1.3, 0), 0.4, 6, c("4a4a52"), 0.0, c("1a1416"))
	merge(k, "char")
	col_cyl(p, 0.3, 1.3)
	if lit:
		var flame := Node3D.new()
		flame.name = "Flame%d" % _misc.get_child_count()
		flame.position = p + Vector3(0, 1.3, 0)
		flame.set_script(load("res://scripts/systems/torch_flicker.gd"))
		_misc.add_child(flame)
		var mi := MeshInstance3D.new()
		mi.name = "FlameMesh"
		mi.mesh = load("res://assets/models/flame_mesh.tres")
		flame.add_child(mi)
		var light := OmniLight3D.new()
		light.name = "Light"
		light.position = Vector3(0, 0.5, 0)
		light.light_color = c("ff9a4a")
		light.light_energy = 1.2
		light.omni_range = 6.0
		flame.add_child(light)


## A brazier that can be lit (scripts/dungeon/torch.gd): an arrow shot through
## a lit one catches fire and lights an unlit one, setting `flag`.
func torch(x: float, z: float, lit: bool, flag := "", y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var t := _dyn("res://scripts/dungeon/torch.gd", "Torch", p, 0.0, {"lit_at_start": lit, "flag": flag}, StaticBody3D.new())
	var k := MeshKit.new(_seed + _misc.get_child_count())
	k.prism(Vector3.ZERO, 0.25, Vector3(0, 1.0, 0), 0.12, 5, c("3a3a42"))
	k.prism(Vector3(0, 1.0, 0), 0.15, Vector3(0, 1.3, 0), 0.4, 6, c("4a4a52"), 0.0, c("1a1416"))
	var mi := MeshInstance3D.new()
	mi.name = "Stand"
	mi.mesh = k.build(M.char)
	t.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.32
	cyl.height = 1.3
	cs.shape = cyl
	cs.position = Vector3(0, 0.65, 0)
	cs.set_meta("no_climb", true)
	t.add_child(cs)


## A star brazier (Torch with `star`): pale silver stone with a star on its
## bowl; only the Starlight Lantern lights it, and it burns blue (sets `flag`).
func star_brazier(x: float, z: float, flag: String, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var t := _dyn("res://scripts/dungeon/torch.gd", "StarBrazier", p, 0.0, {"lit_at_start": false, "flag": flag, "star": true}, StaticBody3D.new())
	var k := MeshKit.new(_seed + _misc.get_child_count())
	k.prism(Vector3.ZERO, 0.28, Vector3(0, 1.0, 0), 0.14, 6, c("9aa4c0"))
	k.prism(Vector3(0, 1.0, 0), 0.16, Vector3(0, 1.3, 0), 0.42, 8, c("b8c2dc"), 0.0, c("1a1e2e"))
	for i in 4:
		var a := TAU * i / 4.0
		k.box(Vector3(cos(a) * 0.3, 1.18, sin(a) * 0.3), Vector3(0.08, 0.08, 0.08), c("e8eeff"))
	var mi := MeshInstance3D.new()
	mi.name = "Stand"
	mi.mesh = k.build(M.char)
	t.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.34
	cyl.height = 1.3
	cs.shape = cyl
	cs.position = Vector3(0, 0.65, 0)
	cs.set_meta("no_climb", true)
	t.add_child(cs)


## A brazier burning with the Order's commanded fire, violet-blue (scenery).
func sapphire_brazier(x: float, z: float, y := INF) -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var k := _tmp(false)
	k.prism(p, 0.25, p + Vector3(0, 1.0, 0), 0.12, 5, c("2a2a3a"))
	k.prism(p + Vector3(0, 1.0, 0), 0.15, p + Vector3(0, 1.3, 0), 0.4, 6, c("3a3a5a"), 0.0, c("12101e"))
	merge(k, "char")
	col_cyl(p, 0.3, 1.3)
	var flame := Node3D.new()
	flame.name = "SapphireFlame%d" % _misc.get_child_count()
	flame.position = p + Vector3(0, 1.3, 0)
	flame.set_script(load("res://scripts/systems/torch_flicker.gd"))
	_misc.add_child(flame)
	var mi := MeshInstance3D.new()
	mi.name = "FlameMesh"
	mi.mesh = load("res://assets/models/sapphire_flame_mesh.tres")
	flame.add_child(mi)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 0.5, 0)
	light.light_color = c("6a5aff")
	light.light_energy = 1.2
	light.omni_range = 6.0
	flame.add_child(light)


## A sapphire ward (SapphireWard) `width` wide across a doorway at `x, z`,
## facing `yaw`: the Starlight Lantern puts it out and sets `flag`.
func sapphire_ward(x: float, z: float, yaw: float, width: float, flag: String, y := INF, height := 3.0) -> void:
	_dyn("res://scripts/dungeon/sapphire_ward.gd", "SapphireWard", g(x, z) if y == INF else Vector3(x, y, z), yaw, {"width": width, "height": height, "flag": flag}, StaticBody3D.new())


## Sets `result` once every flag in `flags` is set (two braziers opening a door).
func flag_all(flags: Array, result: String) -> void:
	_dyn("res://scripts/dungeon/flag_all.gd", "FlagAll", Vector3.ZERO, 0.0, {"flags": PackedStringArray(flags), "result": result}, Node3D.new())


## A round wooden hookshot target (OoT's hookshot-able surfaces): its face
## toward `yaw` (-Z) on a wall at `pos`. The Hookshot bites into it.
func hook_target(pos: Vector3, yaw: float) -> void:
	var b := StaticBody3D.new()
	b.name = "HookTarget%d" % _misc.get_child_count()
	b.position = pos
	b.rotation.y = yaw
	b.add_to_group("hook_targets", true)
	_misc.add_child(b)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/hook_target_mesh.tres")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = 0.14
	cs.shape = cyl
	cs.rotation = Vector3(PI / 2.0, 0, 0)
	cs.set_meta("hookable", true)
	cs.set_meta("no_climb", true)
	b.add_child(cs)


# --- Climbing, doors, people and archery --------------------------------------

## A wooden ladder against a wall. (x, z) is on the wall face, `out` points away
## from the wall toward the climber. The collider is flagged "ladder" and ends
## flush with `top_y`, so the hero climbs over the top onto what is there; the
## rails stick up a little higher as hand holds. Rungs are 15 OoT units apart.
func ladder(x: float, z: float, out: Vector2, bottom_y: float, top_y: float, width := 0.8) -> void:
	var o := Vector3(out.x, 0, out.y).normalized()
	var basis := Basis(Vector3.UP, atan2(o.x, o.z))
	var base := Vector3(x, bottom_y, z)
	var k := _tmp()
	k.push(Transform3D(basis, base))
	var rail_top := top_y - bottom_y + 0.9
	for sx in [-0.5, 0.5]:
		k.box(Vector3(sx * width, rail_top * 0.5, 0.09), Vector3(0.09, rail_top, 0.09), Color(0.9, 0.85, 0.8))
	var rung := 15.0 * 0.03
	var y := rung
	while y < top_y - bottom_y + 0.05:
		k.box(Vector3(0, y, 0.09), Vector3(width, 0.06, 0.07), Color(1, 1, 1))
		y += rung
	k.pop()
	merge(k, "wood")
	var cs := col_box_basis(base + basis * Vector3(0, (top_y - bottom_y) * 0.5, 0.075), Vector3(width + 0.1, top_y - bottom_y, 0.15), basis)
	cs.set_meta("ladder", true)


## A door into another area (an interior, or back outside). `pos` is the middle
## of the doorway on the floor and `yaw` turns the door's outside (-Z) toward
## whoever opens it. The leaf hinges on its left edge and swings inward.
func door_link(pos: Vector3, yaw: float, w: float, hh: float, target_area: String, target_entrance := "", leaf_col := Color(1, 1, 1), need_flag := "", bar_flag := "", barred_text := "") -> Node3D:
	var door := Node3D.new()
	door.name = "Door_" + target_area
	door.set_script(load("res://scripts/systems/door.gd"))
	door.set("target_area", target_area)
	door.set("need_flag", need_flag)
	door.set("bar_flag", bar_flag)
	door.set("barred_text", barred_text)
	door.set("target_entrance", target_entrance if target_entrance != "" else "from_" + R.link_name())
	door.position = pos
	door.rotation.y = yaw
	_exits.add_child(door)
	var door_front := Basis(Vector3.UP, yaw) * Vector3(0, 0, -1)
	keep_clear(Vector2(pos.x + door_front.x * 1.8, pos.z + door_front.z * 1.8), 1.6)
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(-w * 0.5, 0, 0)
	door.add_child(leaf)
	var k := MeshKit.new(_seed)
	k.textured = true
	k.box(Vector3(w * 0.5, hh * 0.5, 0), Vector3(w, hh, 0.08), leaf_col)
	var knob := MeshKit.new(_seed + 1)
	knob.prism(Vector3(w * 0.85, hh * 0.47, -0.04), 0.04, Vector3(w * 0.85, hh * 0.47, -0.1), 0.04, 6, c("c9a64e"))
	var mesh := k.build(M.door)
	knob.add_to(mesh, M.char)
	_mesh_instance(leaf, "LeafMesh", mesh)
	# The dark doorway behind the leaf.
	var gap := _tmp(false)
	gap.push(Transform3D(Basis(Vector3.UP, yaw), pos))
	gap.box(Vector3(0, hh * 0.5, 0.06), Vector3(w, hh, 0.02), c("100c10"))
	gap.pop()
	merge(gap, "char")
	return door


## A person who talks (scripts/npc/npc.gd) using the model `model_scene` and
## the lines in `lines_path`. opts: script (an Npc subclass), turn_body,
## partner (a sibling NPC's name), seated (no blob shadow, a lower body).
func npc(npc_name: String, model_scene: String, lines_path: String, x: float, z: float, yaw: float, y := INF, opts := {}) -> void:
	var n := Node3D.new()
	n.name = npc_name
	n.set_script(load(opts.get("script", "res://scripts/npc/npc.gd")))
	n.set("turn_body", opts.get("turn_body", true))
	n.set("partner_name", opts.get("partner", ""))
	if opts.has("idle"):
		n.set("idle_anim", StringName(opts.idle))
	n.set("show_flag", opts.get("show", ""))
	n.set("hide_flag", opts.get("hide", ""))
	n.set("npc_name", npc_name)
	n.set("lines_script", load(lines_path))
	n.position = g(x, z) if y == INF else Vector3(x, y, z)
	n.rotation.y = yaw
	_misc.add_child(n)
	var model: Node3D = load(model_scene).instantiate()
	model.name = "Model"
	n.add_child(model)
	# Solid like an enemy (layer 3), so she is never mistaken for a ledge.
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 4
	body.collision_mask = 0
	n.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.6
	cs.shape = cap
	cs.position = Vector3(0, 0.8, 0)
	body.add_child(cs)
	if opts.get("seated", false):
		return
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = load("res://assets/models/blob_shadow_mesh.tres")
	shadow.set_script(load("res://scripts/systems/blob_shadow.gd"))
	shadow.set("radius", 0.4)
	n.add_child(shadow)


## A straw archery target on two legs, its painted face toward `yaw` (-Z).
## Rings from the edge in: white, red, white, red, and the gold center.
func archery_target(x: float, z: float, yaw: float, y := INF, prize_flag := "", prize_any := false, range_id := "") -> void:
	var p := g(x, z) if y == INF else Vector3(x, y, z)
	var t := StaticBody3D.new()
	t.name = "Target%d" % _misc.get_child_count()
	t.set_script(load("res://scripts/items/archery_target.gd"))
	t.position = p
	t.rotation.y = yaw
	t.set_meta("face_height", 1.35)
	if range_id != "":
		t.set_meta("range", range_id)
	if prize_flag != "":
		t.set_meta("prize_flag", prize_flag)
		t.set_meta("prize_any", prize_any)
	_misc.add_child(t)
	var legs := MeshKit.new(_seed + 3)
	legs.textured = true
	for sx in [-1.0, 1.0]:
		legs.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(8 * sx)), Vector3(0.42 * sx, 0, 0.12)))
		legs.box(Vector3(0, 0.75, 0), Vector3(0.1, 1.5, 0.1), Color(0.85, 0.8, 0.75))
		legs.pop()
	legs.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-25)), Vector3(0, 0, 0.55)))
	legs.box(Vector3(0, 0.75, 0), Vector3(0.09, 1.5, 0.09), Color(0.8, 0.75, 0.7))
	legs.pop()
	_mesh_instance(t, "Legs", legs.build(M.wood))
	var board := Node3D.new()
	board.name = "Board"
	board.position = Vector3(0, 1.35, 0)
	t.add_child(board)
	var face := MeshKit.new(_seed + 4)
	face.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	face.prism(Vector3(0, -0.06, 0), 0.62, Vector3(0, 0.08, 0), 0.62, 12, c("c8a860"))
	var rings := [[0.6, "f0ece0"], [0.48, "c83028"], [0.36, "f0ece0"], [0.24, "c83028"], [0.13, "f0c020"]]
	var lift := -0.065
	for r in rings:
		face.prism(Vector3(0, lift - 0.004, 0), r[0], Vector3(0, lift, 0), r[0], 12, c(r[1]))
		lift -= 0.004
	face.pop()
	_mesh_instance(board, "Face", face.build(M.char))
	var cs := CollisionShape3D.new()
	cs.name = "BoardShape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.62
	cyl.height = 0.16
	cs.shape = cyl
	cs.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 1.35, 0.01))
	cs.set_meta("no_climb", true)
	t.add_child(cs)
	var post := CollisionShape3D.new()
	post.name = "PostShape"
	var pb := BoxShape3D.new()
	pb.size = Vector3(1.0, 0.9, 0.3)
	post.shape = pb
	post.position = Vector3(0, 0.45, 0.12)
	post.set_meta("no_climb", true)
	t.add_child(post)


## A bundle of `amount` arrows lying at (x, z).
func arrow_pickup(x: float, z: float, amount := 10, y := INF) -> void:
	var a := Area3D.new()
	a.name = "Arrows%d" % _misc.get_child_count()
	a.set_script(load("res://scripts/items/arrow_pickup.gd"))
	a.set("amount", amount)
	a.position = g(x, z) if y == INF else Vector3(x, y, z)
	_misc.add_child(a)


## Walls, floor-to-ceiling, for an interior: a box room `w` x `d` (x, z) with
## walls `hh` high and a ceiling, centered on (x, z) at floor height `y`.
func room(x: float, z: float, w: float, d: float, hh: float, y: float, wall_mat: String, wall_col: Color, ceil_col: Color) -> void:
	var t := 0.4
	for side in [[Vector3(0, 0, -d * 0.5 - t * 0.5), Vector3(w + t * 2, hh, t)], [Vector3(0, 0, d * 0.5 + t * 0.5), Vector3(w + t * 2, hh, t)],
			[Vector3(-w * 0.5 - t * 0.5, 0, 0), Vector3(t, hh, d)], [Vector3(w * 0.5 + t * 0.5, 0, 0), Vector3(t, hh, d)]]:
		var off: Vector3 = side[0]
		var size: Vector3 = side[1]
		block(Vector3(x + off.x, y + hh * 0.5, z + off.z), size, 0.0, wall_mat, wall_col)
	block(Vector3(x, y + hh + 0.2, z), Vector3(w + t * 2, 0.4, d + t * 2), 0.0, wall_mat, ceil_col)
	# Exposed ceiling beams.
	var beams := _tmp()
	var n := maxi(2, int(w / 2.0))
	for i in n:
		var bx := x - w * 0.5 + (i + 0.5) * w / n
		beams.box(Vector3(bx, y + hh - 0.15, z), Vector3(0.22, 0.3, d), c("6a4a30"))
	merge(beams, "wood")


## A tall house with a flat roof deck behind a railing (a lookout). `front`
## (the door side) faces local +Z before `yaw`. opts: wall (material), y,
## gap ("east" / "west" / "north" / "south": an opening in the railing, for a
## ladder), door_w. Returns the height of the deck floor.
func deck_house(x: float, z: float, yaw: float, w: float, d: float, wall_h: float, wall_col: Color, trim_col: Color, opts := {}) -> float:
	var base := g(x, z) if not opts.has("y") else Vector3(x, opts.y, z)
	base.y -= 0.2
	var basis := Basis(Vector3.UP, yaw)
	var xf := Transform3D(basis, base)
	var wall_mat: String = opts.get("wall", "wood")
	var deck := wall_h + 0.25
	var body := _tmp()
	body.push(xf)
	body.box(Vector3(0, wall_h * 0.5, 0), Vector3(w, wall_h, d), wall_col)
	body.pop()
	merge(body, wall_mat)
	# Roof deck planks, corner posts and a band of trim under the deck.
	var top := _tmp()
	top.push(xf)
	top.box(Vector3(0, wall_h + 0.125, 0), Vector3(w, 0.25, d), trim_col.lightened(0.15))
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			top.box(Vector3(sx * w, wall_h * 0.5, sz * d), Vector3(0.3, wall_h + 0.1, 0.3), trim_col)
	top.box(Vector3(0, wall_h - 0.1, d * 0.5 + 0.03), Vector3(w + 0.1, 0.2, 0.08), trim_col)
	top.box(Vector3(0, wall_h - 0.1, -d * 0.5 - 0.03), Vector3(w + 0.1, 0.2, 0.08), trim_col)
	top.pop()
	merge(top, "wood")
	# Railing round the deck, open on the `gap` side over the ladder.
	var gap: String = opts.get("gap", "")
	var rail := _tmp()
	rail.push(xf)
	var edges := {
		"south": [Vector3(-w * 0.5, 0, d * 0.5), Vector3(w * 0.5, 0, d * 0.5)],
		"north": [Vector3(w * 0.5, 0, -d * 0.5), Vector3(-w * 0.5, 0, -d * 0.5)],
		"east": [Vector3(w * 0.5, 0, d * 0.5), Vector3(w * 0.5, 0, -d * 0.5)],
		"west": [Vector3(-w * 0.5, 0, -d * 0.5), Vector3(-w * 0.5, 0, d * 0.5)],
	}
	for side: String in edges:
		var a: Vector3 = edges[side][0]
		var b: Vector3 = edges[side][1]
		var inward := -Vector3(a.x + b.x, 0, a.z + b.z).normalized() * 0.1
		var segs: Array = [[0.0, 1.0]]
		if side == gap:
			segs = [[0.0, 0.3], [0.7, 1.0]]
		for sg in segs:
			var p0: Vector3 = a.lerp(b, sg[0]) + inward + Vector3(0, deck, 0)
			var p1: Vector3 = a.lerp(b, sg[1]) + inward + Vector3(0, deck, 0)
			var n := maxi(1, int(p0.distance_to(p1) / 1.1))
			for i in n + 1:
				var q := p0.lerp(p1, float(i) / n)
				rail.box(q + Vector3(0, 0.45, 0), Vector3(0.1, 0.9, 0.1), trim_col)
			var mid := (p0 + p1) * 0.5
			var seg_len := p0.distance_to(p1)
			var dir := (p1 - p0).normalized()
			var ry := atan2(-dir.z, dir.x)
			rail.push(Transform3D(Basis(Vector3.UP, ry), mid + Vector3(0, 0.85, 0)))
			rail.box(Vector3.ZERO, Vector3(seg_len, 0.08, 0.1), trim_col.lightened(0.1))
			rail.pop()
			var cs := col_box(xf * (mid + Vector3(0, 0.55, 0)), Vector3(seg_len, 1.1, 0.2), yaw + ry)
			cs.set_meta("no_climb", true)
	rail.pop()
	merge(rail, "wood")
	# Windows on every wall, and a frame round the door.
	var trim := _tmp(false)
	trim.push(xf)
	var dark := c("1c1a26")
	var dw: float = opts.get("door_w", 1.2)
	trim.box(Vector3(0, 1.15, d * 0.5 + 0.05), Vector3(dw + 0.3, 2.45, 0.1), c("4a3a2a"))
	for wy in [1.8, 3.3]:
		if wy + 0.6 > wall_h:
			continue
		for sx in [-0.3, 0.3]:
			if wy < 2.5:
				trim.box(Vector3(sx * w, wy, d * 0.5 + 0.04), Vector3(0.8, 0.9, 0.08), dark)
			trim.box(Vector3(sx * w, wy, -d * 0.5 - 0.04), Vector3(0.8, 0.9, 0.08), dark)
		if wy > 2.5:
			trim.box(Vector3(0, wy, d * 0.5 + 0.04), Vector3(0.8, 0.9, 0.08), dark)
		trim.box(Vector3(-w * 0.5 - 0.04, wy, 0), Vector3(0.08, 0.9, 0.8), dark)
	trim.pop()
	merge(trim, "char")
	surface(col_box(base + basis * Vector3(0, deck * 0.5, 0), Vector3(w, deck, d), yaw), "wood")
	return base.y + deck


# --- Dungeons -----------------------------------------------------------------

## Longest stretch of wall built as one block, so the brick texture keeps its scale.
const WALL_STRETCH := 6.0


## A dungeon room: walls round `r` (an x/z rectangle) from floor height `y` up
## `hh`, with a ceiling, and gaps for doorways. Each door is {"side": "n", "s",
## "w" or "e", "at": the x (n/s) or z (w/e) of its middle, "w": width,
## "h": height, "y0": its sill above the floor}. Walls stand outside the
## rectangle. Doorways get stone jambs.
func dungeon_room(r: Rect2, y: float, hh: float, doors: Array, col := Color(1, 1, 1), mat := "shrine", ceil_col := Color(0.55, 0.65, 0.7), ceiling := true, ceil_holes := [], ceil_top := INF) -> void:
	var t := 0.8
	for side: String in ["n", "s", "w", "e"]:
		var along_x := side == "n" or side == "s"
		var fixed: float = r.position.y - t * 0.5 if side == "n" else (r.end.y + t * 0.5 if side == "s" else (r.position.x - t * 0.5 if side == "w" else r.end.x + t * 0.5))
		var a0: float = (r.position.x if along_x else r.position.y) - t
		var a1: float = (r.end.x if along_x else r.end.y) + t
		var gaps: Array = []
		for d: Dictionary in doors:
			if d.side == side:
				gaps.append([d.at - d.get("w", 2.4) * 0.5, d.at + d.get("w", 2.4) * 0.5, d.get("h", 3.2), d.get("y0", 0.0)])
		gaps.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var cur := a0
		for gp: Array in gaps:
			_wall_run(along_x, fixed, cur, gp[0], y, hh, t, col, mat)
			# Below a raised sill, and the lintel above the opening.
			if gp[3] > 0.0:
				# A hair below the sill height: the floor laid through the
				# doorway covers it instead of sharing its plane.
				_wall_run(along_x, fixed, gp[0], gp[1], y, gp[3] - 0.03, t, col, mat)
			_wall_run(along_x, fixed, gp[0], gp[1], y + gp[3] + gp[2], hh - gp[3] - gp[2], t, col, mat)
			_door_jambs(along_x, fixed, gp[0], gp[1], y + gp[3], gp[2], t)
			cur = gp[1]
		_wall_run(along_x, fixed, cur, a1, y, hh, t, col, mat)
	var ctr := r.get_center()
	if not ceiling:
		return
	# Normally 0.8 m thick; in a tower it fills up to the floor of the storey
	# above (`ceil_top`), so no hollow is left between them.
	var thick := 0.8 if ceil_top == INF else ceil_top - (y + hh)
	if ceil_holes.is_empty() and ceil_top == INF:
		block(Vector3(ctr.x, y + hh + 0.4, ctr.y), Vector3(r.size.x + t * 2.0, 0.8, r.size.y + t * 2.0), 0.0, mat, ceil_col)
	else:
		# Shafts up to the storey above (a ladder's, a lift's) pierce it.
		floor_slab(r.grow(t), y + hh + thick, ceil_holes, mat, ceil_col, thick)
	# A dark band where the walls meet the ceiling.
	var band := _tmp(false)
	# (The bands along x stop short of the corners, where the others run.)
	for side in [[Vector3(ctr.x, y + hh - 0.2, r.position.y + 0.05), Vector3(r.size.x - 0.2, 0.4, 0.1)], [Vector3(ctr.x, y + hh - 0.2, r.end.y - 0.05), Vector3(r.size.x - 0.2, 0.4, 0.1)],
			[Vector3(r.position.x + 0.05, y + hh - 0.2, ctr.y), Vector3(0.1, 0.4, r.size.y)], [Vector3(r.end.x - 0.05, y + hh - 0.2, ctr.y), Vector3(0.1, 0.4, r.size.y)]]:
		band.box(side[0], side[1], c("1e3238"))
	merge(band, "char")


## A straight run of wall along x (or z) at `fixed`, from `a` to `b`.
func _wall_run(along_x: bool, fixed: float, a: float, b: float, y: float, hh: float, t: float, col: Color, mat: String) -> void:
	if b - a < 0.05 or hh < 0.05:
		return
	var n := maxi(1, ceili((b - a) / WALL_STRETCH))
	var step := (b - a) / n
	for i in n:
		var m := a + step * (i + 0.5)
		var center := Vector3(m, y + hh * 0.5, fixed) if along_x else Vector3(fixed, y + hh * 0.5, m)
		var size := Vector3(step, hh, t) if along_x else Vector3(t, hh, step)
		var cs := block(center, size, 0.0, mat, col * rng.randf_range(0.95, 1.05))
		cs.set_meta("no_climb", true)


## Square stone jambs and a carved lintel round a doorway. Each piece stands
## well proud of the one behind it, and the lintel hangs a little below the
## wall over the opening, so no two faces share a plane (they z-fought).
func _door_jambs(along_x: bool, fixed: float, a: float, b: float, y: float, hh: float, t: float) -> void:
	var k := _tmp()
	for e in [a, b]:
		# From just under the floor up into the lintel.
		var p := Vector3(e, y + hh * 0.5 - 0.05, fixed) if along_x else Vector3(fixed, y + hh * 0.5 - 0.05, e)
		k.box(p, Vector3(0.5, hh + 0.1, t + 0.3) if along_x else Vector3(t + 0.3, hh + 0.1, 0.5), Color(0.8, 0.95, 0.95))
	var mid := (a + b) * 0.5
	# The lintel: from 6 cm under the top of the opening to 0.5 m over it.
	var top := Vector3(mid, y + hh + 0.22, fixed) if along_x else Vector3(fixed, y + hh + 0.22, mid)
	k.box(top, Vector3(b - a + 1.0, 0.56, t + 0.45) if along_x else Vector3(t + 0.45, 0.56, b - a + 1.0), Color(0.75, 0.9, 0.9))
	merge(k, "stone")
	var gl := _tmp(false)
	gl.box(top, Vector3(0.5, 0.3, t + 0.6) if along_x else Vector3(t + 0.6, 0.3, 0.5), c("4ac8c0"))
	merge(gl, "glow")


## A passage between two rooms: walls along both sides and a ceiling over the
## x/z rectangle `r` (open at both ends, running along x when `along_x`).
func dungeon_corridor(r: Rect2, y: float, hh: float, along_x: bool, col := Color(1, 1, 1), mat := "shrine", ceil_col := Color(0.55, 0.65, 0.7)) -> void:
	var t := 0.8
	var ctr := r.get_center()
	# The ends stop 5 cm inside the rooms' walls: flush with the walls' faces
	# they z-fought, and the ceiling no longer juts out into the rooms.
	var e := 0.05
	if along_x:
		_wall_run(true, r.position.y - t * 0.5, r.position.x + e, r.end.x - e, y, hh, t, col, mat)
		_wall_run(true, r.end.y + t * 0.5, r.position.x + e, r.end.x - e, y, hh, t, col, mat)
		block(Vector3(ctr.x, y + hh + 0.4, ctr.y), Vector3(r.size.x - e * 2.0, 0.8, r.size.y + t * 2.0), 0.0, mat, ceil_col)
	else:
		_wall_run(false, r.position.x - t * 0.5, r.position.y + e, r.end.y - e, y, hh, t, col, mat)
		_wall_run(false, r.end.x + t * 0.5, r.position.y + e, r.end.y - e, y, hh, t, col, mat)
		block(Vector3(ctr.x, y + hh + 0.4, ctr.y), Vector3(r.size.x + t * 2.0, 0.8, r.size.y - e * 2.0), 0.0, mat, ceil_col)


## The room's DungeonRoom area (respawn point, shutters, clear flag), inset
## from its walls so the hero is well inside before the doors shut.
func room_zone(room_id: String, r: Rect2, y: float, hh: float) -> void:
	var a := Area3D.new()
	a.name = "Room_" + room_id
	a.set_script(load("res://scripts/dungeon/dungeon_room.gd"))
	a.set("room_id", room_id)
	a.set("dungeon", R.id)
	var ctr := r.get_center()
	a.position = Vector3(ctr.x, y + hh * 0.5, ctr.y)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(r.size.x - 2.4, 1.0), hh, maxf(r.size.y - 2.4, 1.0))
	cs.shape = box
	a.add_child(cs)
	_misc.add_child(a)


func _dyn(script: String, node_name: String, pos: Vector3, yaw: float, props: Dictionary, base: Node3D) -> Node3D:
	base.name = "%s%d" % [node_name, _misc.get_child_count()]
	base.set_script(load(script))
	for key in props:
		base.set(key, props[key])
	base.position = pos
	base.rotation.y = yaw
	_misc.add_child(base)
	return base


## A treasure chest (scripts/dungeon/chest.gd) whose front faces `yaw` (-Z).
func chest(x: float, z: float, yaw: float, item: String, big: bool, flag: String, appear_flag := "", y := INF) -> void:
	_dyn("res://scripts/dungeon/chest.gd", "Chest", g(x, z) if y == INF else Vector3(x, y, z), yaw,
		{"item": item, "big": big, "flag": flag, "appear_flag": appear_flag}, StaticBody3D.new())


## A chest only Mira's Looking Glass shows (TreasureChest.lens_hidden).
func lens_chest(x: float, z: float, yaw: float, item: String, flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/chest.gd", "LensChest", g(x, z) if y == INF else Vector3(x, y, z), yaw,
		{"item": item, "big": false, "flag": flag, "lens_hidden": true}, StaticBody3D.new())


## Brittle coral over a hidden chest: a thrown pot or rock breaks it and sets `flag`.
func brittle_crust(x: float, z: float, yaw: float, flag: String, size := Vector3(1.6, 1.3, 1.4), y := INF) -> void:
	_dyn("res://scripts/dungeon/brittle_crust.gd", "BrittleCrust", g(x, z) if y == INF else Vector3(x, y, z), yaw, {"flag": flag, "size": size}, StaticBody3D.new())


## A shutter that seals a doorway while room `room_id` is fought over.
func shutter(x: float, z: float, yaw: float, room_id: String, y := 0.0) -> void:
	_dyn("res://scripts/dungeon/shutter.gd", "Shutter", Vector3(x, y, z), yaw, {"room_id": room_id}, AnimatableBody3D.new())


## A locked doorway (small key, or the boss key with `boss`).
func locked_door(x: float, z: float, yaw: float, flag: String, boss := false, y := 0.0) -> void:
	_dyn("res://scripts/dungeon/locked_door.gd", "LockedDoor", Vector3(x, y, z), yaw, {"flag": flag, "boss": boss}, StaticBody3D.new())


func crystal_switch(x: float, z: float, flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/crystal_switch.gd", "Crystal", g(x, z) if y == INF else Vector3(x, y, z), 0.0, {"flag": flag}, StaticBody3D.new())


func floor_switch(x: float, z: float, flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/floor_switch.gd", "FloorSwitch", g(x, z) if y == INF else Vector3(x, y, z), 0.0, {"flag": flag}, Area3D.new())


## Iron bars in a doorway that lift away when `flag` is set.
func flag_bars(x: float, z: float, yaw: float, flag: String, y := 0.0) -> void:
	var b := _dyn("res://scripts/dungeon/flag_mover.gd", "Bars", Vector3(x, y + 3.4, z), yaw, {"flag": flag, "offset": Vector3(0, -3.4, 0), "time": 1.0}, AnimatableBody3D.new())
	var mi := MeshInstance3D.new()
	mi.mesh = load("res://assets/models/bars_mesh.tres")
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.2, 0.3)
	cs.shape = box
	cs.position = Vector3(0, 1.6, 0)
	cs.set_meta("no_climb", true)
	b.add_child(cs)


## A stone bridge over `r` (x/z rectangle), its top at `top_y`, that rises
## `drop` meters out of the depths when `flag` is set.
func flag_bridge(r: Rect2, top_y: float, flag: String, drop: float) -> void:
	var ctr := r.get_center()
	var b := _dyn("res://scripts/dungeon/flag_mover.gd", "Bridge", Vector3(ctr.x, top_y, ctr.y), 0.0, {"flag": flag, "offset": Vector3(0, -drop, 0), "time": 2.0}, AnimatableBody3D.new())
	var k := MeshKit.new(_seed)
	k.textured = true
	k.box(Vector3(0, -0.5, 0), Vector3(r.size.x, 1.0, r.size.y), Color(0.85, 0.95, 0.95))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0, -1.5, sx * (r.size.y * 0.5 - 0.3)), Vector3(r.size.x, 1.0, 0.6), Color(0.7, 0.8, 0.82))
	var mi := MeshInstance3D.new()
	mi.mesh = k.build(M.shrine)
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(r.size.x, 1.0, r.size.y)
	cs.shape = box
	cs.position = Vector3(0, -0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	b.add_child(cs)


## A scripted static body (`script`) at `pos` drawing the kit `mk`, which was
## built in coordinates relative to `pos`, with material `mat`.
func scripted_mesh(script: String, node_name: String, pos: Vector3, mk: MeshKit, mat: String, props := {}) -> Node3D:
	var b := _dyn(script, node_name, pos, 0.0, props, StaticBody3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mk.build(M[mat])
	b.add_child(mi)
	return b


## The blue warp out of a dungeon, shown once `flag` is set.
func blue_warp(x: float, z: float, flag: String, target_area: String, target_entrance: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/blue_warp.gd", "Warp", g(x, z) if y == INF else Vector3(x, y, z), 0.0,
		{"flag": flag, "target_area": target_area, "target_entrance": target_entrance}, Area3D.new())


## A heart container that appears once `flag` is set (the boss is beaten).
func heart_container(x: float, z: float, flag: String, taken_flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/heart_container.gd", "HeartContainer", g(x, z) if y == INF else Vector3(x, y, z), 0.0,
		{"appear_flag": flag, "flag": taken_flag}, Area3D.new())


## A Piece of Heart, hidden here until taken (`flag`); `appear_flag` keeps it
## out of sight until a game is won.
## Sunlight falling through an oculus onto the floor at (x, y, z): stand in
## it with the Mirror Shield raised to throw the light (scripts/dungeon/sun_shaft.gd).
func sun_shaft(x: float, z: float, y: float, height := 7.0, flag := "", radius := 1.1) -> Node3D:
	return _dyn("res://scripts/dungeon/sun_shaft.gd", "SunShaft", Vector3(x, y, z), 0.0, {"height": height, "flag": flag, "radius": radius}, Node3D.new())


## A slit in the wall letting a beam of sunlight shine straight along `yaw`
## (-Z) from `pos`, by itself.
func sun_beam(pos: Vector3, yaw: float, flag := "") -> Node3D:
	return _dyn("res://scripts/dungeon/sun_shaft.gd", "SunBeam", pos, yaw, {"beam": true, "flag": flag}, Node3D.new())


## A bronze mirror on a turning stand, its face toward `yaw` (LightMirror).
func light_mirror(x: float, z: float, yaw: float, y: float, fixed := false, step := 1) -> Node3D:
	var b := _dyn("res://scripts/dungeon/light_mirror.gd", "Mirror", Vector3(x, y, z), yaw, {"fixed": fixed, "step": step}, StaticBody3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/light_mirror_mesh.tres")
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.5, 0.3)
	cs.shape = box
	cs.position = Vector3(0, 1.1, 0)
	cs.set_meta("no_climb", true)
	b.add_child(cs)
	var base := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55
	cyl.height = 0.35
	base.shape = cyl
	base.position = Vector3(0, 0.17, 0)
	base.set_meta("no_climb", true)
	b.add_child(base)
	return b


## A sun face carved on a wall, its face toward `yaw` (SunSwitch).
func sun_switch(pos: Vector3, yaw: float, flag: String) -> Node3D:
	var b := _dyn("res://scripts/dungeon/sun_switch.gd", "SunSwitch", pos, yaw, {"flag": flag}, StaticBody3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/sun_switch_mesh.tres")
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.3, 0.3)
	cs.shape = box
	cs.set_meta("no_climb", true)
	b.add_child(cs)
	return b


## A gale over the box `size` at `center` (scripts/dungeon/wind_zone.gd)
## blowing along `dir`; `opts` may give "flag" + "dir_on" (a vane turns it)
## or "stop_flag" (it dies away).
func wind_zone(center: Vector3, size: Vector3, dir: Vector3, strength := 4.0, opts := {}) -> Node3D:
	var props := {"dir": dir, "strength": strength}
	props.merge(opts)
	var a := _dyn("res://scripts/dungeon/wind_zone.gd", "Wind", center, 0.0, props, Area3D.new())
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	a.add_child(cs)
	return a


## Quicksand over the x/z rectangle `r` on the floor at `y`
## (scripts/dungeon/quicksand.gd); its look is painted by the region.
func quicksand(r: Rect2, y: float, damage := 2) -> void:
	var c := r.get_center()
	# Shallow, so whoever stands on a stepping stone (0.5 m up) is clear of it.
	var a := _dyn("res://scripts/dungeon/quicksand.gd", "Quicksand", Vector3(c.x, y + 0.2, c.y), 0.0, {"damage": damage}, Area3D.new())
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(r.size.x, 0.4, r.size.y)
	cs.shape = box
	a.add_child(cs)


## A goddess's bun piece floating over the beaten master's lair (a
## HeartContainer showing a GetItem id instead).
func bun_piece(x: float, z: float, goddess: String, appear_flag: String, y := INF) -> void:
	_dyn("res://scripts/dungeon/heart_container.gd", "BunPiece", g(x, z) if y == INF else Vector3(x, y, z), 0.0,
		{"appear_flag": appear_flag, "flag": "bun_piece:" + goddess, "item": "bun_piece_" + goddess}, Area3D.new())


func heart_piece(x: float, z: float, flag: String, y := INF, appear_flag := "") -> void:
	_dyn("res://scripts/items/heart_piece.gd", "HeartPiece", g(x, z) if y == INF else Vector3(x, y, z), 0.0,
		{"flag": flag, "appear_flag": appear_flag}, Area3D.new())


## A book lying open (scripts/items/book.gd) at `pos`, its spine along `yaw`.
func book(pos: Vector3, yaw: float, title: String, pages: Array, cover := Color.html("8a2a2a")) -> void:
	var b := _dyn("res://scripts/items/book.gd", "Book", pos, yaw, {"title": title, "pages": PackedStringArray(pages)}, Node3D.new())
	var k := MeshKit.new(_seed + _misc.get_child_count())
	k.box(Vector3(0, 0.012, 0), Vector3(0.46, 0.024, 0.32), cover)
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-6 * sx)), Vector3(0.11 * sx, 0.034, 0)))
		k.box(Vector3.ZERO, Vector3(0.21, 0.025, 0.29), c("f2ead6"))
		for i in 5:
			k.box(Vector3(0, 0.0135, -0.1 + i * 0.045), Vector3(0.16, 0.002, 0.012), c("6a5a4a"))
		k.pop()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = k.build(M.char)
	b.add_child(mi)


## Raised block letters (the pixel font's glyphs, one small box per pixel) on
## a wall: `text` centered on `center`, reading along the direction `yaw`
## faces (the letters face local +Z after `yaw`), `px` meters per pixel.
func pixel_text(text: String, center: Vector3, yaw: float, px: float, col: Color, depth := 0.04) -> void:
	var k := _tmp(false)
	k.push(Transform3D(Basis(Vector3.UP, yaw), center))
	var width := (text.length() * 6 - 1) * px
	for i in text.length():
		var rows: Array = PixelFont.GLYPHS.get(text[i].to_upper(), [])
		for r in rows.size():
			var line: String = rows[r]
			for cx in line.length():
				if line[cx] != "#":
					continue
				var x := -width * 0.5 + (i * 6 + cx + 0.5) * px
				var y := (3.0 - r) * px
				k.box(Vector3(x, y, depth * 0.5), Vector3(px * 1.02, px * 1.02, depth), col)
	k.pop()
	merge(k, "char")


## A prop showing a generated mesh (a sword on the wall, a shield on a rack).
func display_mesh(mesh_path: String, xform: Transform3D) -> void:
	if not ResourceLoader.exists(mesh_path):
		push_error("display_mesh: missing %s" % mesh_path)
		return
	var mi := MeshInstance3D.new()
	mi.name = "Display%d" % _misc.get_child_count()
	mi.mesh = load(mesh_path)
	mi.transform = xform
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_misc.add_child(mi)


# --- Chapter IV ---------------------------------------------------------------------

## Soft earth for the Grave Spade (DigSpot) at `x, z`: dug once (flag
## "dug:<id>") it gives `prize`. opts: loose, reveal_flag, need_flag, soil.
func dig_spot(id: String, x: float, z: float, prize := "", opts := {}, y := INF) -> Node3D:
	var props := {"id": id, "prize": prize, "loose": opts.get("loose", false), "reveal_flag": opts.get("reveal_flag", ""),
		"need_flag": opts.get("need_flag", ""), "soil": opts.get("soil", "earth")}
	return _dyn("res://scripts/items/dig_spot.gd", "DigSpot", g(x, z, -0.05) if y == INF else Vector3(x, y, z), 0.0, props, Node3D.new())


## A goblin war camp (WarCamp) round `x, z`: its creatures within `radius`
## are counted, and when they are all beaten `flag` is set and its banner burns.
func war_camp(flag: String, x: float, z: float, radius := 12.0) -> Node3D:
	return _dyn("res://scripts/systems/war_camp.gd", "WarCamp", g(x, z), 0.0, {"flag": flag, "radius": radius}, Node3D.new())


## Firebuns' war banner (a black cloth and a flame) standing at `x, z`.
func war_banner(x: float, z: float, yaw: float, y := INF) -> void:
	var p := g(x, z, -0.1) if y == INF else Vector3(x, y, z)
	display_mesh("res://assets/models/war_banner_mesh.tres", Transform3D(Basis(Vector3.UP, yaw), p))
	col_cyl(p, 0.12, 4.0)


## A goblin cage at `x, z` whose door is barred until `open_flag` is set.
func goblin_cage(x: float, z: float, yaw: float, open_flag: String, y := INF) -> void:
	var p := g(x, z, -0.05) if y == INF else Vector3(x, y, z)
	var basis := Basis(Vector3.UP, yaw)
	var mk := MeshKit.new(_seed + _misc.get_child_count())
	var pole := c("4a3424")
	for i in 7:
		var t := -1.1 + i * (2.2 / 6.0)
		for s in [-1.1, 1.1]:
			mk.prism(p + basis * Vector3(t, 0, s), 0.05, p + basis * Vector3(t, 2.2, s), 0.045, 5, pole)
			if s > 0.0 or absf(t) > 0.5:
				mk.prism(p + basis * Vector3(s, 0, t), 0.05, p + basis * Vector3(s, 2.2, t), 0.045, 5, pole)
	mk.box(p + Vector3(0, 2.3, 0), Vector3(2.5, 0.08, 2.5), c("6a5a44"))
	merge(mk, "wood")
	for s in [-1.1, 1.1]:
		col_box(p + basis * Vector3(0, 1.1, s), Vector3(2.3, 2.2, 0.2), yaw).set_meta("no_climb", true)
	col_box(p + basis * Vector3(1.1, 1.1, 0), Vector3(0.2, 2.2, 2.3), yaw).set_meta("no_climb", true)
	# The door on the -X side: lashed shut until the camp is broken.
	var door := MeshKit.new(_seed + 3)
	for j in 4:
		var t := -0.9 + j * 0.6
		door.prism(p + basis * Vector3(-1.1, 0, t), 0.05, p + basis * Vector3(-1.1, 2.2, t), 0.045, 5, pole.lightened(0.1))
	door.box(p + basis * Vector3(-1.1, 1.2, 0), Vector3(0.12, 0.14, 2.0), c("8a7a54"))
	flag_barrier(p + basis * Vector3(-1.1, 1.1, 0), Vector3(0.3, 2.2, 2.2), yaw, open_flag, door, "wood")


## A soldier of the lost garrison (Garrison): found where they are trapped,
## or (`home`) safe in the refuge once rescued.
func garrison_soldier(id: String, x: float, z: float, yaw: float, home := false, y := INF) -> void:
	var name_: String = load("res://scripts/npc/garrison.gd").soldier_name(id)
	var flag := "rescue:" + id
	npc(name_, "res://assets/models/haven_soldier.tscn", "res://scripts/npc/soldier_lines.gd", x, z, yaw, y,
		{"show": flag} if home else {"hide": flag})
