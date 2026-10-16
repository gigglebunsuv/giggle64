extends RefCounted
## Accumulates flat-shaded, vertex-colored triangles for building low-poly meshes.
##
## Every primitive is convex, so faces are automatically oriented away from the
## primitive's center. Godot treats clockwise triangles as front faces, so faces
## are emitted in that order.

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()

## When true, faces get UVs that stretch the texture once across `uv_box`
## (textures never tile). Primitives set `uv_box` to their own bounds unless
## `uv_box_locked` is set (e.g. the terrain stretches one texture over itself).
var textured := false
var uv_box := AABB(Vector3.ZERO, Vector3.ONE)
var uv_box_locked := false
## Forces top-down UV projection for every face (terrain).
var uv_top_down := false
## Random brightness variation applied per face, for a hand-shaded look.
var shade_jitter := 0.0
var rng := RandomNumberGenerator.new()

var _xform := Transform3D.IDENTITY
var _stack: Array[Transform3D] = []


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


func push(t: Transform3D) -> void:
	_stack.append(_xform)
	_xform = _xform * t


func pop() -> void:
	_xform = _stack.pop_back()


func is_empty() -> bool:
	return verts.is_empty()


func triangle_count() -> int:
	return verts.size() / 3


# --- Faces --------------------------------------------------------------------

## Adds a planar polygon. Orientation is chosen so the normal points away from `center`.
func face(pts: Array, col: Color, center: Vector3) -> void:
	var p: Array[Vector3] = []
	for v in pts:
		p.append(_xform * v)
	var n := _newell(p)
	if n.length_squared() < 1e-12:
		return
	var fc := Vector3.ZERO
	for v in p:
		fc += v
	fc /= p.size()
	var uv := _stretched_uvs(pts)
	if n.dot(fc - _xform * center) < 0.0:
		p.reverse()
		uv.reverse()
		n = -n
	_emit_polygon(p, uv, n.normalized(), col)


## Adds a planar polygon whose normal should point along `hint` (world-space direction).
func face_dir(pts: Array, col: Color, hint: Vector3) -> void:
	var p: Array[Vector3] = []
	for v in pts:
		p.append(_xform * v)
	var n := _newell(p)
	if n.length_squared() < 1e-12:
		return
	var uv := _stretched_uvs(pts)
	if n.dot(_xform.basis * hint) < 0.0:
		p.reverse()
		uv.reverse()
		n = -n
	_emit_polygon(p, uv, n.normalized(), col)


func _newell(p: Array[Vector3]) -> Vector3:
	var n := Vector3.ZERO
	for i in p.size():
		var a := p[i]
		var b := p[(i + 1) % p.size()]
		n.x += (a.y - b.y) * (a.z + b.z)
		n.y += (a.z - b.z) * (a.x + b.x)
		n.z += (a.x - b.x) * (a.y + b.y)
	return n


## Projects local-space points along the face's dominant axis and normalizes them
## to `uv_box`, so the texture is stretched once over the primitive.
func _stretched_uvs(pts: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not textured:
		for v in pts:
			out.append(Vector2.ZERO)
		return out
	var local: Array[Vector3] = []
	for v in pts:
		local.append(v)
	var a := _newell(local).abs()
	var o := uv_box.position
	var sz := uv_box.size
	sz = Vector3(maxf(sz.x, 0.001), maxf(sz.y, 0.001), maxf(sz.z, 0.001))
	for v: Vector3 in local:
		var r := (v - o) / sz
		if uv_top_down or (a.y >= a.x and a.y >= a.z):
			out.append(Vector2(r.x, r.z))
		elif a.x >= a.z:
			out.append(Vector2(r.z, 1.0 - r.y))
		else:
			out.append(Vector2(r.x, 1.0 - r.y))
	return out


func _auto_box(pts: Array) -> void:
	if uv_box_locked or pts.is_empty():
		return
	var box := AABB(pts[0], Vector3.ZERO)
	for v in pts:
		box = box.expand(v)
	uv_box = box


func _emit_polygon(p: Array[Vector3], uv: Array[Vector2], n: Vector3, col: Color) -> void:
	var c := col
	if shade_jitter > 0.0:
		var k := 1.0 + rng.randf_range(-shade_jitter, shade_jitter)
		c = Color(clampf(col.r * k, 0, 1), clampf(col.g * k, 0, 1), clampf(col.b * k, 0, 1), col.a)
	# p winds counter-clockwise around n; Godot wants clockwise front faces.
	for i in range(1, p.size() - 1):
		_emit_vertex(p[0], uv[0], n, c)
		_emit_vertex(p[i + 1], uv[i + 1], n, c)
		_emit_vertex(p[i], uv[i], n, c)


func _emit_vertex(v: Vector3, uv: Vector2, n: Vector3, c: Color) -> void:
	verts.append(v)
	normals.append(n)
	colors.append(c)
	uvs.append(uv)


# --- Primitives ---------------------------------------------------------------

## Eight-corner solid: four bottom corners followed by four top corners, same order.
func hexa(c: Array, col: Color, side_cols: Array = []) -> void:
	_auto_box(c)
	var center := Vector3.ZERO
	for v in c:
		center += v
	center /= 8.0
	var cols: Array = side_cols if side_cols.size() == 6 else [col, col, col, col, col, col]
	face([c[0], c[1], c[2], c[3]], cols[0], center)
	face([c[4], c[5], c[6], c[7]], cols[1], center)
	face([c[0], c[1], c[5], c[4]], cols[2], center)
	face([c[1], c[2], c[6], c[5]], cols[3], center)
	face([c[2], c[3], c[7], c[6]], cols[4], center)
	face([c[3], c[0], c[4], c[7]], cols[5], center)


## Rectangle (x/z extents) at p0 joined to rectangle at p1: a tapered box between two heights.
func slab(p0: Vector3, s0: Vector2, p1: Vector3, s1: Vector2, col: Color) -> void:
	var a := s0 * 0.5
	var b := s1 * 0.5
	hexa([
		p0 + Vector3(-a.x, 0, -a.y), p0 + Vector3(a.x, 0, -a.y), p0 + Vector3(a.x, 0, a.y), p0 + Vector3(-a.x, 0, a.y),
		p1 + Vector3(-b.x, 0, -b.y), p1 + Vector3(b.x, 0, -b.y), p1 + Vector3(b.x, 0, b.y), p1 + Vector3(-b.x, 0, b.y),
	], col)


func box(center: Vector3, size: Vector3, col: Color) -> void:
	var h := size.y * 0.5
	slab(center - Vector3(0, h, 0), Vector2(size.x, size.z), center + Vector3(0, h, 0), Vector2(size.x, size.z), col)


## Low-sided prism / cylinder / cone along the Y axis from p0 to p1.
func prism(p0: Vector3, r0: float, p1: Vector3, r1: float, sides: int, col: Color, angle_offset := 0.0, cap_col := Color(0, 0, 0, 0)) -> void:
	var center := (p0 + p1) * 0.5
	var ring0: Array = []
	var ring1: Array = []
	for i in sides:
		var t := TAU * float(i) / sides + angle_offset
		var d := Vector3(cos(t), 0, sin(t))
		ring0.append(p0 + d * r0)
		ring1.append(p1 + d * r1)
	_auto_box(ring0 + ring1 + [p0, p1])
	var cc := col if cap_col.a == 0.0 else cap_col
	for i in sides:
		var j := (i + 1) % sides
		if r0 > 0.0 and r1 > 0.0:
			face([ring0[i], ring0[j], ring1[j], ring1[i]], col, center)
		elif r1 <= 0.0:
			face([ring0[i], ring0[j], p1], col, center)
		else:
			face([ring0[i], ring0[j], p0], col, center)
	if r0 > 0.0:
		face(ring0, cc, center)
	if r1 > 0.0:
		face(ring1, cc, center)


## Jittered icosahedron: rocks, canopies, bushes.
func icosa(center: Vector3, radius: Vector3, jitter: float, col: Color, subdivide := false) -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var vs: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var fs: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	for i in vs.size():
		vs[i] = vs[i].normalized()
	if subdivide:
		var cache := {}
		var nf: Array = []
		for f in fs:
			var m: Array = []
			for k in 3:
				var a: int = f[k]
				var b: int = f[(k + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not cache.has(key):
					vs.append(((vs[a] + vs[b]) * 0.5).normalized())
					cache[key] = vs.size() - 1
				m.append(cache[key])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		fs = nf
	var pts: Array[Vector3] = []
	for v in vs:
		var k := 1.0 + rng.randf_range(-jitter, jitter)
		pts.append(center + Vector3(v.x * radius.x, v.y * radius.y, v.z * radius.z) * k)
	_auto_box(pts)
	for f in fs:
		face([pts[f[0]], pts[f[1]], pts[f[2]]], col, center)


## Lofted solid along the local Y axis, for rounded character limbs (like the
## N64 Zelda models: smooth, low-sided tubes that overlap at the joints).
## `rings` holds [y, radius_x, radius_z, color] or [y, radius_x, radius_z, color, Vector2 xz_offset].
## A ring with zero radius closes that end to a point; otherwise the end gets a flat cap.
## The texture (if any) wraps once around the loft with u = 0.5 at the front (-Z),
## and runs from v = 0 at the last ring to v = 1 at the first.
func loft(rings: Array, sides: int, cap_ends := true) -> void:
	var grid: Array = []   # per ring: Array[Vector3] of sides + 1 points (last duplicates the first)
	var all_pts: Array = []
	for r: Array in rings:
		var off: Vector2 = r[4] if r.size() > 4 else Vector2.ZERO
		var row: Array[Vector3] = []
		for i in sides + 1:
			var a := -PI + TAU * float(i) / sides
			row.append(Vector3(off.x + sin(a) * r[1], r[0], off.y - cos(a) * r[2]))
		grid.append(row)
		all_pts.append_array(row)
	_auto_box(all_pts)
	var center := Vector3.ZERO
	for p in all_pts:
		center += p
	center /= all_pts.size()
	var n_r := rings.size()
	for ri in n_r - 1:
		var c0: Color = rings[ri][3]
		var c1: Color = rings[ri + 1][3]
		var v0 := 1.0 - float(ri) / (n_r - 1)
		var v1 := 1.0 - float(ri + 1) / (n_r - 1)
		for i in sides:
			var u0 := float(i) / sides
			var u1 := float(i + 1) / sides
			var a: Vector3 = grid[ri][i]
			var b: Vector3 = grid[ri][i + 1]
			var c: Vector3 = grid[ri + 1][i + 1]
			var d: Vector3 = grid[ri + 1][i]
			tri_vc([a, b, c], [c0, c0, c1], [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1)], center)
			tri_vc([a, c, d], [c0, c1, c1], [Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1)], center)
	if cap_ends:
		for end in [0, n_r - 1]:
			var r: Array = rings[end]
			if r[1] <= 0.0 or r[2] <= 0.0:
				continue
			var off: Vector2 = r[4] if r.size() > 4 else Vector2.ZERO
			var mid := Vector3(off.x, r[0], off.y)
			var v := 1.0 if end == 0 else 0.0
			for i in sides:
				tri_vc([mid, grid[end][i], grid[end][i + 1]], [r[3], r[3], r[3]],
					[Vector2(0.5, v), Vector2(float(i) / sides, v), Vector2(float(i + 1) / sides, v)], center)


## Triangle with per-vertex colors and explicit UVs, oriented away from `center`.
func tri_vc(pts: Array, cols: Array, tuv: Array, center: Vector3) -> void:
	var p: Array[Vector3] = [_xform * pts[0], _xform * pts[1], _xform * pts[2]]
	var n := (p[1] - p[0]).cross(p[2] - p[0])
	if n.length_squared() < 1e-14:
		return
	var uv: Array = tuv if textured else [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var cs: Array = cols.duplicate()
	if shade_jitter > 0.0:
		var k := 1.0 + rng.randf_range(-shade_jitter, shade_jitter) * 0.5
		for i in 3:
			var col: Color = cs[i]
			cs[i] = Color(clampf(col.r * k, 0, 1), clampf(col.g * k, 0, 1), clampf(col.b * k, 0, 1), col.a)
	var fc := (p[0] + p[1] + p[2]) / 3.0
	var order := [0, 2, 1]
	if n.dot(fc - _xform * center) < 0.0:
		n = -n
		order = [0, 1, 2]
	n = n.normalized()
	# Clockwise front faces for Godot.
	for i: int in order:
		_emit_vertex(p[i], uv[i], n, cs[i])


## Replaces flat face normals with averaged (Gouraud) normals. Faces meeting at
## more than `crease_deg` keep a hard edge, so caps, soles and rims stay crisp.
func smooth_normals(crease_deg := 65.0) -> void:
	var cos_crease := cos(deg_to_rad(crease_deg))
	var buckets := {}
	for i in verts.size():
		var key := Vector3i((verts[i] * 2000.0).round())
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(i)
	var out := normals.duplicate()
	for key in buckets:
		var ids: Array = buckets[key]
		for i: int in ids:
			var fi := normals[i]
			var acc := Vector3.ZERO
			for j: int in ids:
				if fi.dot(normals[j]) >= cos_crease:
					acc += normals[j]
			out[i] = acc.normalized() if acc.length_squared() > 1e-12 else fi
	normals = out


# --- Output -------------------------------------------------------------------

func add_to(mesh: ArrayMesh, material: Material) -> void:
	if verts.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)


func build(material: Material) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	add_to(mesh, material)
	return mesh
