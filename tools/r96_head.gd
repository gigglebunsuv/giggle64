extends RefCounted
class_name R96Head
## Sculpted heads for the Render96-style promo models (never used in game).
## Replaces the game's egg-shaped head wrap with a more angular OoT3D-style
## head: full skull, cheekbones, a tapered jaw down to a defined chin, a brow
## ridge, slight eye sockets, a real nose and small ears. The UVs follow the
## game's head-wrap layout exactly (u = 0.5 + azimuth / 360 with the front at
## the center, v from the crown to under the chin, linear in height), so the
## painted faces land where they always did.

## Per character: the wrap's height range (y_bot, y_top), the game's rings
## (for the skull's overall size), and the jaw and feature shaping.
const SHAPES := {
	"woman": {"jaw": 1.0, "cheek": 0.04, "nose": 0.033, "brow": 0.006, "eye_y": 0.185, "lower": 0.15, "ears": 0.0},
	"mira": {"jaw": 0.96, "cheek": 0.035, "nose": 0.027, "brow": 0.005, "eye_y": 0.183, "lower": 0.145, "ears": 0.0},
	"himeko": {"jaw": 0.92, "cheek": 0.03, "nose": 0.025, "brow": 0.004, "eye_y": 0.178, "lower": 0.142, "ears": 0.0},
	"firebuns": {"jaw": 1.06, "cheek": 0.05, "nose": 0.040, "brow": 0.009, "eye_y": 0.186, "lower": 0.158, "ears": 0.0},
	"mara": {"jaw": 0.95, "cheek": 0.06, "nose": 0.035, "brow": 0.008, "eye_y": 0.185, "lower": 0.152, "ears": 0.0},
	"lothelye": {"jaw": 0.94, "cheek": 0.03, "nose": 0.025, "brow": 0.004, "eye_y": 0.176, "lower": 0.142, "ears": 0.0},
	"gigglebuns": {"jaw": 1.16, "cheek": 0.04, "nose": 0.046, "brow": 0.011, "eye_y": 0.206, "lower": 0.165, "ears": 1.0},
}

## How far the shortened head (and its hair) is lowered onto the neck.
const DROP := 0.025

const COLS := 72
const ROWS := 56

var rings: Array
var y_bot: float
var y_top: float
var sh: Dictionary


## A head shape (no mesh) for `id`, for the hair kit to comb over.
static func shape(id: String) -> R96Head:
	var h := R96Head.new()
	h.rings = R96Hair.HERO_HEAD if id == "gigglebuns" else R96Hair.WOMAN_HEAD
	h.y_bot = h.rings[0][0]
	h.y_top = h.rings[-1][0]
	h.sh = SHAPES.get(id, SHAPES.woman)
	return h


static func build(id: String, face_mat: Material, skin_mat: Material, skin: Color, skin_d: Color) -> ArrayMesh:
	var h := shape(id)
	var mesh := ArrayMesh.new()
	h._wrap(mesh, face_mat)
	if h.sh.ears > 0.0:
		h._ears(mesh, skin_mat, skin, skin_d)
	return mesh


## The base wrap size at height y (the game's rings, with a rounded crown).
func _ring(y: float) -> Array:
	if y <= rings[0][0]:
		return [rings[0][1], rings[0][2], rings[0][3]]
	for i in rings.size() - 1:
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		if y >= r0[0] and y <= r1[0]:
			var t: float = (y - r0[0]) / (r1[0] - r0[0])
			if i == rings.size() - 2:
				var k := sqrt(maxf(0.0, 1.0 - t * t))
				return [r0[1] * k, r0[2] * k, lerpf(r0[3], r1[3], t)]
			return [lerpf(r0[1], r1[1], t), lerpf(r0[2], r1[2], t), lerpf(r0[3], r1[3], t)]
	return [0.0, 0.0, rings[-1][3]]


## Where the chin ends: well above the old wrap's bottom ring (which sat
## low and made the jaw long).
func _chin_y() -> float:
	return float(sh.get("chin_y", y_bot + 0.055))


func _g(x: float, c: float, w: float) -> float:
	return exp(-pow((x - c) / w, 2.0))


## The sculpted surface point at azimuth a (degrees, 0 = front) and the
## painted face's height y. The shape follows proportions measured off the
## OoT3D adult Link reference (shape only): a wide, flat front plane through
## the eyes and cheekbones; the mouth halfway from chin to eyes; a pronounced
## wedge nose with its tip three quarters of the way up; the jaw narrowing to
## about 30% at a small square chin; in profile the jaw line slants from the
## chin back up to the ear; the brow and forehead slope back.
func point(a: float, y: float) -> Vector3:
	var E: float = sh.eye_y
	var C := _chin_y()
	var W: float = sh.get("w", 0.122 if rings == R96Hair.WOMAN_HEAD else 0.134)
	var Fz: float = sh.get("front", -0.118 if rings == R96Hair.WOMAN_HEAD else -0.128)
	var back_skull: float = sh.get("back", 0.128 if rings == R96Hair.WOMAN_HEAD else 0.14)
	var top := y_top + 0.004
	var ar := deg_to_rad(a)
	var sa := sin(ar)
	var ca := cos(ar)
	var gy := geo_y(y)
	var w: float
	var front: float
	var back: float
	var n_front := 2.7
	var hg := 1.0
	if y >= E:
		# The skull: an ellipsoid from the eye line to the crown, its front
		# sloping back from the brow.
		var q := clampf((y - E) / (top - E), 0.0, 1.0)
		var k := sqrt(maxf(0.0, 1.0 - q * q))
		w = W * (1.0 + 0.03 * sin(q * PI)) * k
		front = Fz * pow(k, 0.85)
		back = back_skull * sqrt(maxf(0.0, 1.0 - pow(q * 0.98, 2.0)))
		n_front = lerpf(2.7, 2.0, smoothstep(0.2, 0.7, q))
	else:
		var h := clampf((y - C) / (E - C), 0.0, 1.0)
		hg = _hgeo(h)
		# Half-width down the face: cheekbones -> mouth -> a small chin.
		var wk := _curve(hg, [[0.0, 0.18], [0.06, 0.3], [0.25, 0.5], [0.5, 0.74], [0.75, 0.9], [0.92, 1.0], [1.0, 1.0]])
		w = W * wk * (float(sh.get("jaw", 1.0)) if hg < 0.6 else 1.0)
		w += float(sh.cheek) * _g(hg, 0.84, 0.12) * W
		front = Fz + 0.008 * pow(1.0 - hg, 1.5)
		# The jaw line in profile: from the chin back and up to the ear.
		back = lerpf(Fz + 0.05, back_skull, pow(smoothstep(0.0, 1.0, hg), 0.75))
		if hg < 0.06:
			var k := sqrt(hg / 0.06)
			w *= lerpf(0.4, 1.0, k)
			back = lerpf(Fz + 0.02, back, k)
	var zc := (front + back) * 0.5
	var rzf := zc - front
	var rzb := back - zc
	var n := n_front if ca > 0.0 else 2.0
	var ex := 2.0 / n
	var x := signf(sa) * pow(absf(sa), ex) * w
	var z := zc - signf(ca) * pow(absf(ca), ex) * (rzf if ca > 0.0 else rzb)
	var p := Vector3(x, gy, z)
	var fr := pow(maxf(0.0, ca), 2.0)
	# The nose: a wedge from the bridge to a tip 3/4 up, tucked under to the lip.
	var P: float = sh.nose
	var nose := 0.0
	if hg < 1.05:
		nose = P * _curve(hg, [[0.6, 0.0], [0.66, 0.35], [0.73, 1.0], [0.8, 0.82], [0.9, 0.45], [1.0, 0.18], [1.05, 0.0]])
	var nw := lerpf(0.019, 0.011, smoothstep(0.73, 1.0, hg))
	p.z -= nose * exp(-pow(x / nw, 2.0)) * fr
	for s in [-1.0, 1.0]:
		p.z -= P * 0.22 * _g(hg, 0.68, 0.05) * exp(-pow((x - s * 0.013) / 0.008, 2.0)) * fr
	# Brow ridge, eye sockets, lips, the point of the chin.
	if y >= E:
		var qb := (y - E) / (top - E)
		p.z -= float(sh.brow) * _g(qb, 0.16, 0.07) * exp(-pow(x / 0.075, 2.0))
	for s in [-1.0, 1.0]:
		p.z += 0.004 * _g(gy, E, 0.012) * exp(-pow((x - s * 0.045) / 0.022, 2.0)) * fr
	p.z -= 0.003 * _g(hg, 0.5, 0.06) * exp(-pow(x / 0.025, 2.0)) * fr
	p.z -= 0.004 * _g(hg, 0.18, 0.1) * exp(-pow(x / 0.03, 2.0)) * fr
	return p


## Feature heights: the painted face's (chin 0, mouth 0.39, nose 0.64, eyes 1)
## onto the reference's (mouth 0.5, nose 0.73).
func _hgeo(h: float) -> float:
	return h + 0.12 * sin(PI * h)


func _curve(t: float, pts: Array) -> float:
	if t <= pts[0][0]:
		return pts[0][1]
	for i in pts.size() - 1:
		if t <= pts[i + 1][0]:
			var u: float = (t - pts[i][0]) / (pts[i + 1][0] - pts[i][0])
			u = u * u * (3.0 - 2.0 * u)
			return lerpf(pts[i][1], pts[i + 1][1], u)
	return pts[-1][1]


## The painted face's heights (texture space) -> the sculpted head's.
func geo_y(y: float) -> float:
	var E: float = sh.eye_y
	if y >= E:
		return y
	var C := _chin_y()
	var h := clampf((y - C) / (E - C), 0.0, 1.0)
	return E - (1.0 - _hgeo(h)) * float(sh.get("lower", 0.15))


func _wrap(mesh: ArrayMesh, mat: Material) -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var y_low := _chin_y()
	for j in ROWS + 1:
		var y := lerpf(y_top, y_low, float(j) / ROWS)
		var v := (y_top - y) / (y_top - y_bot)
		for i in COLS + 1:
			var u := float(i) / COLS
			var a := (u - 0.5) * 360.0
			verts.append(point(a, y))
			uvs.append(Vector2(u, v))
			cols.append(Color.WHITE)
	# A neck under the jaw, down into the collar.
	var chin_geo := geo_y(y_low)
	var neck_rows := 6
	for j in range(1, neck_rows + 1):
		var y := lerpf(chin_geo + 0.03, -0.06, float(j) / neck_rows)
		for i in COLS + 1:
			var u := float(i) / COLS
			var ar := deg_to_rad((u - 0.5) * 360.0)
			var nr := 0.05 if rings == R96Hair.WOMAN_HEAD else 0.058
			verts.append(Vector3(sin(ar) * nr, y, 0.006 - cos(ar) * nr * 0.95))
			uvs.append(Vector2(0.5, 0.455))   # plain skin from the bridge of the nose
			cols.append(Color.WHITE)
	var rows_all := ROWS + neck_rows
	for j in rows_all:
		if j == ROWS:
			pass
		for i in COLS:
			var a := j * (COLS + 1) + i
			var b := a + 1
			var c := a + COLS + 1
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	# Smooth normals, welding the u seam and the crown.
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for f in idx.size() / 3:
		var p0 := verts[idx[f * 3]]
		var p1 := verts[idx[f * 3 + 1]]
		var p2 := verts[idx[f * 3 + 2]]
		var n := (p2 - p0).cross(p1 - p0)
		for k in 3:
			norms[idx[f * 3 + k]] += n
	var weld := {}
	for i in verts.size():
		var key := Vector3i((verts[i] * 10000.0).round())
		weld[key] = weld.get(key, Vector3.ZERO) + norms[i]
	for i in verts.size():
		norms[i] = (weld[Vector3i((verts[i] * 10000.0).round())] as Vector3).normalized()
		# Outward check (the crown and chin points).
		var c := Vector3(0, verts[i].y, 0)
		if norms[i].dot(verts[i] - c) < 0.0 and absf(verts[i].y - y_top) > 0.01:
			norms[i] = -norms[i]
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(mesh.get_surface_count() - 1, mat)


## Small ears: a curled shell set on the sides at eye height.
func _ears(mesh: ArrayMesh, mat: Material, skin: Color, skin_d: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ey: float = sh.eye_y
	for s in [-1.0, 1.0]:
		var base := point(s * 90.0, ey - 0.01)
		var n := 10
		var m := 6
		var grid: Array = []
		for i in n + 1:
			var t := float(i) / n
			var ang := lerpf(-PI * 0.55, PI * 0.6, t)
			var row: Array = []
			for k in m + 1:
				var w := float(k) / m
				# Outline of the ear (taller than wide), cupped toward the front.
				var rad := 0.034 * w
				var px := cos(ang) * rad * 0.7
				var py := sin(ang) * rad + 0.004
				var out := 0.012 * w * (1.0 - 0.4 * w) + 0.004 * sin(w * PI)
				var cup := -0.006 * sin(w * PI)
				row.append(base + Vector3(s * (out + 0.002), py, px + cup + 0.012))
			grid.append(row)
		for i in n:
			for k in m:
				var q: Array = [grid[i][k], grid[i + 1][k], grid[i + 1][k + 1], grid[i][k + 1]]
				for tri in [[0, 1, 2], [0, 2, 3]]:
					for vi: int in tri:
						var w := float(k + (1 if vi >= 2 else 0)) / m
						st.set_color(skin.lerp(skin_d, 0.6 * (1.0 - w)))
						st.add_vertex(q[vi])
	st.generate_normals()
	var em := st.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, em.surface_get_arrays(0))
	mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
