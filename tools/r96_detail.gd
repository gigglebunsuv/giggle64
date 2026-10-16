extends RefCounted
class_name R96Detail
## Extra gear and trim for the Render96-style promo models (never used in
## game), built with MeshKit and hung on the model's joints before R96Kit
## remasters it, so it is subdivided and painted with everything else.
## Creative liberties: embroidered trims, studs, buckles, straps, a pouch, a
## crest and a wind-swept cape.

const MeshKit := preload("res://tools/mesh_kit.gd")

## Colors the palettes in R96Kit know: gold embroidery, the cape, a gem.
const EMBROIDERY := Color("d8a840")
const EMBROIDERY_D := Color("b08428")
const GOLD := Color("c9a64e")
const LEATHER := Color("6b4529")
const LEATHER_D := Color("5a3820")
const CAPE := Color("a01c26")
const CAPE_D := Color("6e1018")
const GEM := Color("c01828")


static func apply(id: String, model: Node3D, wind := Vector3(0.55, 0.0, 0.35)) -> void:
	match id:
		"gigglebuns":
			_hero(model, wind)


static func _j(m: Node, n: String) -> Node3D:
	return m.find_child(n, true, false) as Node3D


static func _add(parent: Node3D, name: String, k: MeshKit) -> void:
	if parent == null or k.is_empty():
		return
	k.smooth_normals(70.0)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = k.build(mat)
	parent.add_child(mi)


## A band around a loft: [y0, y1], radii and z offset, pushed out a little.
static func _band(k: MeshKit, y0: float, y1: float, rx: float, rz: float, off: float, col: Color, out := 1.035, sides := 28) -> void:
	k.loft([
		[y0, rx * 0.985, rz * 0.985, col, Vector2(0, off)], [y0, rx * out, rz * out, col, Vector2(0, off)],
		[y1, rx * out, rz * out, col, Vector2(0, off)], [y1, rx * 0.985, rz * 0.985, col, Vector2(0, off)],
	], sides, false)


static func _stud(k: MeshKit, p: Vector3, r: float, col: Color) -> void:
	k.icosa(p, Vector3(r, r, r), 0.0, col, true)


static func _hero(m: Node3D, wind: Vector3) -> void:
	var hips := _j(m, "Hips")
	var torso := _j(m, "Torso")
	# Tunic hem: a broad band of gold embroidery, and studs on the belt.
	var k := MeshKit.new(3)
	_band(k, -0.164, -0.128, 0.2, 0.155, 0.005, EMBROIDERY)
	_band(k, -0.131, -0.124, 0.197, 0.152, 0.005, EMBROIDERY_D, 1.04)
	for i in 12:
		var a := deg_to_rad(28.0 + i * 25.0)
		if absf(sin(a)) < 0.25 and cos(a) > 0.0:
			continue
		_stud(k, Vector3(sin(a) * 0.176, 0.0875, -cos(a) * 0.131), 0.0075, GOLD)
	# A round gold boss over the buckle, set with a red stone.
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.088, -0.142)))
	k.prism(Vector3(0, -0.006, 0), 0.026, Vector3(0, 0.006, 0), 0.022, 16, GOLD)
	k.pop()
	_stud(k, Vector3(0, 0.088, -0.152), 0.01, GEM)
	# A leather pouch on the right hip, flap and clasp.
	k.push(Transform3D(Basis(Vector3.UP, deg_to_rad(-38)), Vector3(0.15, 0.035, -0.09)))
	k.box(Vector3(0, 0, 0), Vector3(0.075, 0.085, 0.04), LEATHER)
	k.box(Vector3(0, 0.03, -0.023), Vector3(0.078, 0.035, 0.008), LEATHER_D)
	_stud(k, Vector3(0, 0.012, -0.029), 0.007, GOLD)
	k.pop()
	_add(hips, "R96HipGear", k)
	# The chest: a gold crest of Haven pinned where the strap crosses.
	var c := MeshKit.new(5)
	c.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.BACK, 0.0), Vector3(0.062, 0.255, -0.138)))
	c.prism(Vector3(0, -0.005, 0), 0.03, Vector3(0, 0.006, 0), 0.026, 6, GOLD, PI / 6.0)
	c.pop()
	_stud(c, Vector3(0.062, 0.255, -0.146), 0.011, GEM)
	_add(torso, "R96Crest", c)
	for side in ["L", "R"]:
		var sx := -1.0 if side == "L" else 1.0
		# Embroidered sleeve hems.
		var s := MeshKit.new(7)
		_band(s, -0.106, -0.084, 0.078, 0.076, 0.0, EMBROIDERY, 1.06, 20)
		_add(_j(m, "Shoulder" + side), "R96SleeveTrim", s)
		# Bracer straps and buckles over the gloves.
		var e := MeshKit.new(9)
		for y in [-0.128, -0.172]:
			_band(e, y - 0.009, y + 0.009, 0.058, 0.06, 0.0, LEATHER_D, 1.08, 16)
			e.box(Vector3(0.064 * sx, y, -0.0), Vector3(0.008, 0.022, 0.02), GOLD)
		_add(_j(m, "Elbow" + side), "R96Bracers", e)
		# Boot straps with buckles.
		var b := MeshKit.new(11)
		_band(b, -0.215, -0.195, 0.062, 0.068, 0.0, LEATHER, 1.07, 18)
		b.box(Vector3(0.067 * sx, -0.205, -0.012), Vector3(0.008, 0.026, 0.024), GOLD)
		_add(_j(m, "Knee" + side), "R96BootStraps", b)
	_cape(torso, wind)


## A crimson cape from the shoulders, streaming back and to one side in the
## wind, with gold embroidery along its edges.
static func _cape(torso: Node3D, wind: Vector3) -> void:
	var k := MeshKit.new(13)
	var cols_n := 18
	var rows_n := 22
	var grid: Array = []
	for i in rows_n + 1:
		var t := float(i) / rows_n
		var row: Array = []
		for j in cols_n + 1:
			var u := float(j) / cols_n
			# Top edge: an arc behind the neck from shoulder to shoulder.
			var ang := lerpf(-1.75, 1.75, u)
			var top := Vector3(sin(ang) * 0.19, 0.37, cos(ang) * 0.115 + 0.02)
			var spread := 1.0 + 0.9 * t
			var p := Vector3(top.x * spread, top.y - t * 1.05, top.z + 0.1 * t)
			# Wind: the lower cape lifts back and sweeps aside, in rolling folds.
			var w := pow(t, 1.4)
			p += wind * w * 0.9
			p.y += w * 0.22 * wind.length()
			p.z += 0.055 * sin(u * 9.0 + t * 2.5) * (0.3 + t)
			p.x += 0.03 * sin(u * 7.0 + t * 4.0) * t
			var edge := minf(minf(u, 1.0 - u) * cols_n, (1.0 - t) * rows_n + 9.0)
			var col := EMBROIDERY if (edge < 0.8 or i == rows_n) else (CAPE if fmod(u * 9.0 + 0.5, 1.0) > 0.25 else CAPE_D)
			if i == 0:
				col = GOLD
			row.append([p, col])
		grid.append(row)
	var center := Vector3(0, 0.0, -0.4)
	for i in rows_n:
		for j in cols_n:
			var a: Array = grid[i][j]
			var b: Array = grid[i][j + 1]
			var cc: Array = grid[i + 1][j + 1]
			var d: Array = grid[i + 1][j]
			k.tri_vc([a[0], b[0], cc[0]], [a[1], b[1], cc[1]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], center)
			k.tri_vc([a[0], cc[0], d[0]], [a[1], cc[1], d[1]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], center)
	_add(torso, "R96Cape", k)
