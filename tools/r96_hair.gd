extends RefCounted
class_name R96Hair
## Sculpted hair for the Render96-style promo models (never used in game).
## Each head gets its own hair mesh built from many tapered locks, the way the
## OoT3D models layer clumps of hair: locks are combed along the real head
## surface (roots at the crown or part, running over the scalp), then leave it
## and fall under gravity with a little curl. Every lock is a swept ellipse,
## darker underneath and toward the roots, catching light partway down.

## The game models' hair colors, stripped from their heads.
static var STRIP := {
	"mira": [Color.html("a4482a"), Color.html("7a321c"), Color.html("bc5a34")],
	"himeko": [Color.html("16141c"), Color.html("0a090e"), Color.html("34304a")],
	"firebuns": [Color.html("8a4e2c"), Color.html("6a3820"), Color.html("a8643a")],
	"mara": [Color.html("141018"), Color.html("08060a"), Color.html("2a2230")],
}

const SIDES := 8
const SEGS := 26

## Head wraps from gen_characters: [y, radius_x, radius_z, z offset].
const WOMAN_HEAD := [
	[-0.03, 0.058, 0.054, -0.064], [0.015, 0.094, 0.086, -0.042], [0.06, 0.111, 0.104, -0.024],
	[0.105, 0.117, 0.114, -0.012], [0.15, 0.119, 0.119, -0.004], [0.195, 0.119, 0.122, 0.0],
	[0.24, 0.114, 0.122, 0.005], [0.285, 0.092, 0.102, 0.01], [0.33, 0.0, 0.0, 0.014],
]
const HERO_HEAD := [
	[-0.03, 0.065, 0.06, -0.075], [0.02, 0.105, 0.095, -0.05], [0.07, 0.125, 0.115, -0.03],
	[0.12, 0.13, 0.125, -0.016], [0.17, 0.132, 0.13, -0.006], [0.22, 0.132, 0.135, 0.0],
	[0.27, 0.125, 0.135, 0.006], [0.32, 0.1, 0.112, 0.012], [0.37, 0.0, 0.0, 0.016],
]

var rings: Array
var head: R96Head
var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var idx := PackedInt32Array()
var rng := RandomNumberGenerator.new()
var dark: Color
var base: Color
var light: Color


func _init(head_rings: Array, hair: Color, hair_d: Color, hair_l: Color, seed_value := 7, id := "") -> void:
	rings = head_rings
	if id != "":
		head = R96Head.shape(id)
	base = hair
	dark = hair_d
	light = hair_l
	rng.seed = seed_value


# --- The head surface -------------------------------------------------------------------

## Point on the head wrap at azimuth `a` (degrees, 0 = the face's front, -Z)
## and height y, pushed out along the surface normal by `lift`.
func surf(a: float, y: float, lift := 0.0) -> Vector3:
	var p := _raw(a, y)
	if lift != 0.0:
		p += normal(a, y) * lift
	return p


func _raw(a: float, y: float) -> Vector3:
	if head:
		return head.point(a, clampf(y, head._chin_y(), head.y_top))
	var rx := 0.0
	var rz := 0.0
	var off := 0.0
	if y <= rings[0][0]:
		rx = rings[0][1]
		rz = rings[0][2]
		off = rings[0][3]
	elif y >= rings[-1][0]:
		off = rings[-1][3]
	else:
		for i in rings.size() - 1:
			var r0: Array = rings[i]
			var r1: Array = rings[i + 1]
			if y >= r0[0] and y <= r1[0]:
				var t: float = (y - r0[0]) / (r1[0] - r0[0])
				# Round the crown off (the wrap closes to a point at the top).
				if i == rings.size() - 2:
					var k := sqrt(maxf(0.0, 1.0 - t * t))
					rx = r0[1] * k
					rz = r0[2] * k
				else:
					rx = lerpf(r0[1], r1[1], t)
					rz = lerpf(r0[2], r1[2], t)
				off = lerpf(r0[3], r1[3], t)
				break
	var ar := deg_to_rad(a)
	return Vector3(sin(ar) * rx, y, off - cos(ar) * rz)


func normal(a: float, y: float) -> Vector3:
	var da := 1.5
	var dy := 0.004
	var pa := _raw(a + da, y) - _raw(a - da, y)
	var py := _raw(a, minf(y + dy, rings[-1][0] - 0.0005)) - _raw(a, y - dy)
	var n := pa.cross(py).normalized()
	var c := Vector3(0, y, _raw(0, y).z + _raw(180, y).z) * Vector3(0, 1, 0.5)
	if n.dot(_raw(a, y) - c) < 0.0:
		n = -n
	if n.length_squared() < 0.5:
		n = (_raw(a, y) - c).normalized()
	return n


## Points along the scalp from (a0, y0) to (a1, y1), lifted off it.
func comb(a0: float, y0: float, a1: float, y1: float, lift0: float, lift1: float, n := 6) -> Array:
	var out: Array = []
	for i in n + 1:
		var t := float(i) / n
		out.append(surf(lerpf(a0, a1, t), lerpf(y0, y1, t), lerpf(lift0, lift1, t)))
	return out


## Continues a path past its end: falling under gravity from its last
## direction, `length` long, ending with `curl` (a sideways vector).
func fall(path: Array, length: float, curl := Vector3.ZERO, steps := 5, stiff := 0.5) -> Array:
	var p: Vector3 = path[-1]
	var d: Vector3 = (path[-1] - path[-2]).normalized()
	var seg := length / steps
	var out := path.duplicate()
	for i in steps:
		var t := float(i + 1) / steps
		d = (d * stiff + Vector3.DOWN * (1.0 - stiff)).normalized()
		d = (d + curl * t * 0.6).normalized()
		p += d * seg
		out.append(p)
	return out


# --- Locks -----------------------------------------------------------------------------

## Sweeps one lock along `pts` (a Catmull-Rom spline through them). `w` is
## the half-width, `th` the half-thickness. `blunt` cuts the tip square (a
## hime cut) instead of tapering it to a point. `out_hint` overrides the
## direction the flat side faces (defaults to away from the head's axis).
func lock(pts: Array, w: float, th: float, blunt := false, shade := 1.0, out_hint := Vector3.ZERO, tip := 0.0) -> void:
	var spline := _spline(pts, SEGS)
	var n := spline.size()
	var jitter := rng.randf_range(0.92, 1.08) * shade
	var start := verts.size()
	for i in n:
		var t := float(i) / (n - 1)
		var p: Vector3 = spline[i]
		var tan: Vector3 = (spline[mini(i + 1, n - 1)] - spline[maxi(i - 1, 0)]).normalized()
		var o := out_hint if out_hint != Vector3.ZERO else Vector3(p.x, 0.0, p.z - 0.004).normalized()
		o = (o - tan * o.dot(tan)).normalized()
		if o.length_squared() < 0.5:
			o = tan.cross(Vector3.RIGHT).normalized()
		var s := tan.cross(o).normalized()
		var prof := maxf(_profile(t, blunt), tip * (1.0 - pow(t, 8.0)))
		var ww := w * prof
		var tt := th * maxf(prof, 0.35 if blunt else 0.0)
		var c := _color(t) * jitter
		for k in SIDES:
			var ang := TAU * k / SIDES
			var cs := cos(ang)
			var sn := sin(ang)
			# A lens-shaped clump: flatter on top, edges a little pinched.
			var off := s * cs * ww + o * sn * tt * (1.0 - 0.25 * absf(cs))
			verts.append(p + off)
			var nn := (s * cs / maxf(ww, 1e-4) + o * sn / maxf(tt, 1e-4)).normalized()
			norms.append(nn if ww > 1e-5 else tan)
			var under := clampf(-sn, 0.0, 1.0)
			var cc := c.lerp(dark * 0.55, under * 0.55)
			cc.a = 1.0
			cols.append(cc)
	for i in n - 1:
		for k in SIDES:
			var a := start + i * SIDES + k
			var b := start + i * SIDES + (k + 1) % SIDES
			var c := a + SIDES
			var d := b + SIDES
			idx.append_array([a, c, b, b, c, d])
	# Root and (for a blunt cut) tip caps.
	var ends: Array[int] = [0]
	if blunt:
		ends.append(n - 1)
	for end: int in ends:
		var ci := verts.size()
		var mid := Vector3.ZERO
		for k in SIDES:
			mid += verts[start + end * SIDES + k]
		verts.append(mid / SIDES)
		var tn: Vector3 = (spline[mini(end + 1, n - 1)] - spline[maxi(end - 1, 0)]).normalized()
		norms.append(-tn if end == 0 else tn)
		cols.append(_color(float(end) / (n - 1)) * jitter)
		for k in SIDES:
			var a := start + end * SIDES + k
			var b := start + end * SIDES + (k + 1) % SIDES
			if end == 0:
				idx.append_array([ci, b, a])
			else:
				idx.append_array([ci, a, b])


func _profile(t: float, blunt: bool) -> float:
	var root := smoothstep(0.0, 0.12, t) * 0.45 + 0.55
	if blunt:
		return root * (1.0 - 0.15 * t)
	return root * pow(maxf(0.0, 1.0 - pow(t, 2.2)), 0.75) * (1.0 + 0.15 * sin(t * PI))


func _color(t: float) -> Color:
	var c := dark.lerp(base, smoothstep(0.0, 0.3, t))
	c = c.lerp(light, exp(-pow((t - 0.55) / 0.16, 2.0)) * 0.55)
	return c


func _spline(pts: Array, per: int) -> Array:
	var out: Array = []
	var m := pts.size()
	for i in m - 1:
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, m - 1)]
		var steps := maxi(2, per / (m - 1))
		for j in steps:
			var t := float(j) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[-1])
	return out


func build(gloss := 0.55) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 1.0 - gloss
	m.metallic_specular = 0.6
	m.rim_enabled = true
	m.rim = 0.3
	m.rim_tint = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, m)
	return mesh


# --- Styles -------------------------------------------------------------------------------
# Each returns the hair mesh in the Head joint's space.

static func style(id: String) -> ArrayMesh:
	match id:
		"mira":
			return _mira()
		"himeko":
			return _himeko()
		"firebuns":
			return _firebuns()
		"mara":
			return _mara()
		"lothelye":
			return null   # she keeps her veil
		"gigglebuns":
			return _beard()
	return null


## The scalp: locks radiating from a crown point down over the back and
## sides to a hairline, so no skin shows through between the outer layers.
func _scalp(crown_a: float, crown_y: float, step: float, end_y: float, skip_front: float, w := 0.034, lift := 0.008) -> void:
	var a := -180.0
	while a < 180.0:
		if absf(a) > skip_front:
			var ae := a + rng.randf_range(-3, 3)
			lock(comb(crown_a + a * 0.05, crown_y, ae, end_y + rng.randf_range(-0.01, 0.01), lift, lift + 0.004, 6), w, 0.011, false, 0.95)
		a += step


static func _mira() -> ArrayMesh:
	var h := R96Hair.new(WOMAN_HEAD, Color.html("a4482a"), Color.html("6a2a16"), Color.html("d0703e"), 11, "mira")
	# Everything is drawn back to the high ponytail, tied at the back of the crown.
	var tie := Vector3(0, 0.275, 0.118)
	var a := -180.0
	while a < 180.0:
		if absf(a) > 50.0:
			var y_end := 0.06 if absf(a) > 120.0 else 0.13
			var pts := h.comb(a, y_end, a * 0.6 + signf(a) * 72.0 if absf(a) < 120 else a, 0.23, 0.007, 0.012, 5)
			pts.append(tie + Vector3(signf(a) * 0.015, 0, 0))
			pts.reverse()
			h.lock(pts, 0.041, 0.013, false, 1.0, Vector3.ZERO, 0.55)
		a += 11.0
	# Top: from the crown forward and down into the fringe.
	for i in 13:
		var fa := -48.0 + i * 8.0 + h.rng.randf_range(-2, 2)
		var tip_y := 0.218 + h.rng.randf_range(-0.012, 0.006) + absf(fa) * 0.0002
		var pts := h.comb(fa * 0.15 - 4.0, 0.33, fa * 0.85, 0.262, 0.004, 0.018, 4)
		pts.append(h.surf(fa, tip_y, 0.016))
		h.lock(pts, 0.032, 0.012)
	# Locks framing her cheeks.
	for sx in [-1.0, 1.0]:
		for j in 3:
			var aa: float = sx * (62.0 + j * 9.0)
			var pts := h.comb(sx * 20.0, 0.31, aa, 0.2, 0.01, 0.016, 4)
			pts = h.fall(pts, 0.16 - j * 0.02, Vector3(-sx * 0.15, 0, -0.3), 5, 0.45)
			h.lock(pts, 0.035, 0.013)
	# The ponytail: a sheaf flaring out of the tie and swinging down the back.
	for i in 11:
		var ang := TAU * i / 11.0
		var spread := Vector3(cos(ang) * 0.025, sin(ang) * 0.012, 0)
		var pts: Array = [tie + spread * 0.3, tie + Vector3(0, 0.03, 0.05) + spread, tie + Vector3(0, 0.0, 0.11) + spread * 1.8]
		pts = h.fall(pts, 0.36 + h.rng.randf_range(-0.05, 0.05), Vector3(spread.x * 4.0, 0, 0.15), 6, 0.62)
		h.lock(pts, 0.030, 0.016, false, 1.0, Vector3(0, 0, 1))
	return h.build()


static func _himeko() -> ArrayMesh:
	var h := R96Hair.new(WOMAN_HEAD, Color.html("1a1822"), Color.html("08070c"), Color.html("4a4668"), 13, "himeko")
	# Long straight hair from the crown down the back to the waist, cut square.
	var a := -180.0
	while a < 180.0:
		if absf(a) > 64.0:
			var pts := h.comb(a * 0.1, 0.33, a, 0.17, 0.006, 0.016, 5)
			var length := 0.62 if absf(a) > 100.0 else 0.2
			pts = h.fall(pts, length, Vector3(signf(a) * 0.04, 0, 0.0), 6, 0.2)
			h.lock(pts, 0.043, 0.016, true)
		a += 9.0
	# Blunt bangs, cut in one straight line above the brows.
	for i in 17:
		var fa := -50.0 + i * 6.25
		var pts := h.comb(fa * 0.2, 0.33, fa * 0.9, 0.25, 0.005, 0.017, 4)
		pts.append(h.surf(fa, 0.219, 0.019))
		h.lock(pts, 0.030, 0.012, true)
	# Hime side locks hanging past the cheeks, cut square at the jaw.
	for sx in [-1.0, 1.0]:
		for j in 4:
			var aa: float = sx * (60.0 + j * 7.0)
			var pts := h.comb(sx * 8.0, 0.32, aa, 0.2, 0.01, 0.017, 4)
			pts = h.fall(pts, 0.16, Vector3.ZERO, 4, 0.1)
			h.lock(pts, 0.030, 0.013, true)
	return h.build(0.65)


static func _firebuns() -> ArrayMesh:
	var h := R96Hair.new(WOMAN_HEAD, Color.html("8a4e2c"), Color.html("4a2414"), Color.html("c07a46"), 7, "firebuns")
	# Parted in the middle; the locks comb away from the part over the top
	# and fall straight past the cheeks to the shoulders, leaving the face clear.
	for sx in [-1.0, 1.0]:
		var a := 62.0
		while a < 182.0:
			var aa: float = sx * a
			var y_end := 0.2 if a < 100 else 0.16
			var pts := h.comb(sx * 2.0, 0.326, aa, y_end, 0.004, 0.015, 5)
			pts = h.fall(pts, 0.34 + h.rng.randf_range(-0.03, 0.03), Vector3(sx * 0.04, 0, 0.06 if a > 90 else -0.03), 6, 0.2)
			h.lock(pts, 0.04, 0.014)
			a += 10.0
		# Curtain fringe: off the part, over the temples, down beside the eyes.
		for j in 5:
			var pts := h.comb(sx * 3.0, 0.325, sx * (14.0 + j * 9.0), 0.25 - j * 0.004, 0.006, 0.018, 4)
			pts = h.fall(pts, 0.05 + j * 0.035, Vector3(sx * 0.35, 0, -0.1), 4, 0.45)
			h.lock(pts, 0.032, 0.013)
	return h.build()


static func _mara() -> ArrayMesh:
	var h := R96Hair.new(WOMAN_HEAD, Color.html("16121c"), Color.html("060408"), Color.html("3e3450"), 17, "mara")
	var a := -180.0
	while a < 180.0:
		if absf(a) > 56.0:
			var pts := h.comb(a * 0.1, 0.33, a, 0.18, 0.006, 0.016, 5)
			pts = h.fall(pts, 0.2, Vector3(signf(a) * 0.03, 0, 0), 5, 0.15)
			h.lock(pts, 0.043, 0.016, true)
		a += 9.0
	for i in 15:
		var fa := -48.0 + i * 6.85
		var pts := h.comb(fa * 0.2, 0.33, fa * 0.9, 0.245, 0.005, 0.017, 4)
		pts.append(h.surf(fa, 0.214, 0.019))
		h.lock(pts, 0.032, 0.012, true)
	return h.build(0.6)


static func _lothelye() -> ArrayMesh:
	var h := R96Hair.new(WOMAN_HEAD, Color.html("eeeef8"), Color.html("a8a8c8"), Color.html("ffffff"), 19)
	for sx in [-1.0, 1.0]:
		var a := 58.0
		while a < 182.0:
			var aa: float = sx * a
			var y_end := 0.2 if a < 100 else 0.16
			var pts := h.comb(sx * 1.5, 0.328, aa, y_end, 0.004, 0.015, 5)
			pts = h.fall(pts, 0.55 + h.rng.randf_range(-0.06, 0.04), Vector3(sx * 0.12, 0, 0.08 if a > 90 else -0.04), 7, 0.3)
			h.lock(pts, 0.04, 0.014)
			a += 9.0
		# Parted over the brow, swept back over the temples.
		for j in 5:
			var pts := h.comb(sx * 2.0, 0.326, sx * (12.0 + j * 9.5), 0.255, 0.006, 0.016, 4)
			pts.append(h.surf(sx * (40.0 + j * 9.0), 0.21, 0.02))
			h.lock(pts, 0.032, 0.012)
	return h.build(0.5)


## Sir Gigglebuns IV is bald: his "hair" is the full beard and mustache,
## sculpted as clumps over the painted beard.
static func _beard() -> ArrayMesh:
	var h := R96Hair.new(HERO_HEAD, Color.html("4a2a18"), Color.html("2e180e"), Color.html("6a4026"), 4, "gigglebuns")
	h._beard_shell()
	# The mustache: thick sweeps from under the nose out past the corners of
	# the mouth.
	for sx in [-1.0, 1.0]:
		for j in 3:
			var pts: Array = [h.surf(sx * (2.0 + j * 2.0), 0.117 - j * 0.003, 0.009),
				h.surf(sx * 12.0, 0.111 - j * 0.003, 0.013), h.surf(sx * 22.0, 0.098 - j * 0.003, 0.012),
				h.surf(sx * 29.0, 0.079 - j * 0.004, 0.009)]
			h.lock(pts, 0.016, 0.008, false, 0.85)
	return h.build(0.4)


## The full beard as one sculpted shell over the jaw: a smooth offset of the
## head surface, thick in the middle and thin at its upper edge, grooved with
## strands, running past the chin to a point.
func _beard_shell() -> void:
	var chin := head._chin_y()
	var cols_n := 84
	var rows_n := 40
	var start := verts.size()
	var grid_pts: Array = []
	for i in cols_n + 1:
		var a := lerpf(-100.0, 100.0, float(i) / cols_n)
		var aa := absf(a)
		# The beard line: under the lip at the middle, just under the nose
		# beside it, along the cheekbones, then up the sideburns to the ears.
		var top := lerpf(0.081, 0.11, smoothstep(9.0, 15.0, aa))
		top = lerpf(top, 0.145, smoothstep(26.0, 44.0, aa))
		top = lerpf(top, 0.215, smoothstep(62.0, 82.0, aa))
		var front := pow(maxf(0.0, cos(deg_to_rad(a))), 3.0)
		var drop := 0.055 * front + 0.012          # how far past the chin it hangs
		var col: Array = []
		for j in rows_n + 1:
			var t := float(j) / rows_n
			var y := lerpf(top, chin - drop, t)
			var p: Vector3
			var n: Vector3
			if y >= chin + 0.004:
				p = surf(a, y)
				n = normal(a, y)
			else:
				# Past the chin: hang down and a little forward, gathering in.
				var p0 := surf(a * lerpf(1.0, 0.55, front), chin + 0.004)
				var below := (chin + 0.004 - y)
				p = p0 + Vector3(-p0.x * below * 6.0, -below, -below * 0.45)
				n = Vector3(p.x, 0.0, p.z + 0.03).normalized().lerp(Vector3(0, -0.3, -1).normalized(), front * 0.5).normalized()
			var edge := smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.9, 1.0, t) * 0.6)
			var groove := 0.0025 * sin(a * 0.55 + sin(y * 90.0) * 1.3) + 0.0015 * sin(a * 1.7 + y * 140.0)
			var thick := (0.013 + 0.006 * front) * edge + groove * edge
			col.append([p + n * thick, n, t, groove])
		grid_pts.append(col)
	for i in cols_n + 1:
		for j in rows_n + 1:
			var e: Array = grid_pts[i][j]
			verts.append(e[0])
			norms.append(e[1])
			var t: float = e[2]
			var g: float = e[3]
			var c := base.lerp(light, clampf(g * 160.0, 0.0, 1.0) * 0.5 + exp(-pow((t - 0.55) / 0.2, 2.0)) * 0.25)
			c = c.lerp(dark, clampf(-g * 200.0, 0.0, 1.0) * 0.55 + (1.0 - smoothstep(0.0, 0.25, t)) * 0.35)
			c.a = 1.0
			cols.append(c)
	for i in cols_n:
		for j in rows_n:
			var a := start + i * (rows_n + 1) + j
			var b := a + 1
			var c := a + rows_n + 1
			var d := c + 1
			idx.append_array([a, c, b, b, c, d])
	# Ragged tips along the bottom edge: short locks hanging off the shell.
	for i in range(int(cols_n * 0.36), int(cols_n * 0.64), 3):
		var e: Array = grid_pts[i][rows_n - 2]
		var e2: Array = grid_pts[i][rows_n]
		var p0: Vector3 = e[0]
		var p1: Vector3 = e2[0]
		var d := (p1 - p0).normalized()
		lock([p0, p1, p1 + d * rng.randf_range(0.015, 0.03) + Vector3(0, -0.004, -0.006)], 0.022, 0.007, false, 0.95)
