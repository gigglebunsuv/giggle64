extends RefCounted
## Meshes for "The Fall of Castle Town" update: bombs and the bomb bag, the
## Bog Tower's Bloom Rod with its seed, bloom-pod and lily pad, cracked walls
## and boulders for bombs to break, and the castle's sapphire bolt and
## Gauntlet-fire burst. Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 1700


func run(materials: Dictionary) -> void:
	M = materials
	_bomb()
	_bomb_bag()
	_bloom_rod()
	_bloom_seed()
	_bloom_pod()
	_lily_pad()
	_cracked_wall()
	_bomb_boulder()
	_sapphire_bolt()
	_fire_orb()
	_rubble()


func _c(h: String) -> Color:
	return Color.html(h)


func _k(textured := false) -> MeshKit:
	_seed += 1
	var k := MeshKit.new(_seed)
	k.textured = textured
	return k


func _save(res: Resource, file: String) -> void:
	var err := ResourceSaver.save(res, MODEL_DIR + file)
	if err != OK:
		push_error("Failed to save %s: %s" % [file, err])


## OoT's bomb: a navy-blue ball (0.36 m across) with a brass cap, a short
## stub of fuse and its spark. The origin is the bottom of the ball.
func _bomb() -> void:
	var k := _k()
	var blue := _c("2a3a8a")
	k.loft([
		[0.0, 0.0, 0.0, blue.darkened(0.3)], [0.03, 0.1, 0.1, blue.darkened(0.15)], [0.09, 0.165, 0.165, blue],
		[0.18, 0.185, 0.185, blue.lightened(0.12)], [0.27, 0.165, 0.165, blue.lightened(0.05)], [0.33, 0.1, 0.1, blue],
		[0.36, 0.0, 0.0, blue],
	], 10)
	k.prism(Vector3(0, 0.33, 0), 0.06, Vector3(0, 0.39, 0), 0.055, 8, _c("c8a040"))
	k.prism(Vector3(0, 0.39, 0), 0.014, Vector3(0.02, 0.45, 0), 0.012, 5, _c("e8e0c8"))
	k.smooth_normals(60.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0.022, 0.465, 0), Vector3(0.03, 0.03, 0.03), 0.0, _c("ffd060"))
	g.add_to(mesh, M.glow)
	_save(mesh, "bomb_mesh.tres")


## A plump drawstring bag of brown cloth with a bomb face peeking out.
func _bomb_bag() -> void:
	var k := _k()
	var cloth := _c("9a6a3a")
	k.loft([
		[0.0, 0.0, 0.0, cloth.darkened(0.3)], [0.03, 0.12, 0.11, cloth.darkened(0.15)], [0.12, 0.17, 0.16, cloth],
		[0.22, 0.15, 0.14, cloth.lightened(0.1)], [0.28, 0.07, 0.07, cloth.darkened(0.1)], [0.32, 0.09, 0.09, cloth],
		[0.34, 0.0, 0.0, cloth],
	], 10)
	k.prism(Vector3(0, 0.275, 0), 0.075, Vector3(0, 0.29, 0), 0.075, 10, _c("c83a2a"))
	# A bomb's curve showing at the mouth and a stitched skull-ish emblem.
	k.icosa(Vector3(0.0, 0.33, 0.0), Vector3(0.06, 0.05, 0.06), 0.0, _c("2a3a8a"))
	k.box(Vector3(0, 0.14, -0.165), Vector3(0.08, 0.08, 0.01), _c("e8d8a0"))
	k.smooth_normals(55.0)
	_save(k.build(M.char), "bomb_bag_mesh.tres")


## The Bloom Rod: a crooked staff of dark bogwood (0.62 m, held along the
## fist's -Z like the sword), wound with green vines, a bulb at its head that
## splits into five pink petals round a glowing seed.
func _bloom_rod() -> void:
	var k := _k()
	var wood := _c("5a3e24")
	var vine := _c("4a8a32")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.12, 0), 0.02, Vector3(0.01, 0.2, 0), 0.022, 6, wood)
	k.prism(Vector3(0.01, 0.2, 0), 0.022, Vector3(-0.01, 0.44, 0), 0.024, 6, wood.lightened(0.08))
	for i in 6:
		var y := -0.05 + i * 0.08
		k.push(Transform3D(Basis(Vector3.UP, i * 1.1) * Basis(Vector3.BACK, 0.5), Vector3(0, y, 0)))
		k.box(Vector3.ZERO, Vector3(0.055, 0.012, 0.012), vine)
		k.pop()
	k.icosa(Vector3(-0.01, 0.48, 0), Vector3(0.05, 0.05, 0.05), 0.0, vine.darkened(0.1))
	for i in 5:
		var a := TAU * i / 5.0
		k.push(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.BACK, 0.7), Vector3(-0.01, 0.5, 0)))
		k.slab(Vector3(0, 0, 0), Vector2(0.02, 0.008), Vector3(0, 0.09, 0), Vector2(0.045, 0.006), _c("f08ab8"))
		k.pop()
	k.pop()
	k.smooth_normals(50.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(-0.01, 0.0, -0.53), Vector3(0.028, 0.028, 0.028), 0.0, _c("d8ff90"))
	g.add_to(mesh, M.glow)
	_save(mesh, "bloom_rod_mesh.tres")


## The seed in flight: a glowing green kernel with a leaf.
func _bloom_seed() -> void:
	var g := _k()
	g.icosa(Vector3.ZERO, Vector3(0.08, 0.1, 0.08), 0.0, _c("c8ff80"))
	g.box(Vector3(0, 0.1, 0.04), Vector3(0.02, 0.06, 0.08), _c("6ad040"))
	_save(g.build(M.glow), "bloom_seed_mesh.tres")


## A bloom-pod: a fat green bulb 1.3 m across and 1.5 m tall (its collision
## is a box of that size), ribbed like a pumpkin, with broad leaves round its
## foot and a crown of pink petals folded shut over a flat top to stand on.
func _bloom_pod() -> void:
	var k := _k()
	var green := _c("4a9a3a")
	var dark := _c("2e6a26")
	var rings := [
		[0.0, 0.52, 0.52, dark], [0.25, 0.66, 0.66, green.darkened(0.1)], [0.7, 0.7, 0.7, green],
		[1.15, 0.62, 0.62, green.lightened(0.08)], [1.42, 0.5, 0.5, green], [1.5, 0.0, 0.0, green.lightened(0.15)],
	]
	k.loft(rings, 12)
	# Ribs.
	for i in 8:
		var a := TAU * i / 8.0
		k.push(Transform3D(Basis(Vector3.UP, a), Vector3.ZERO))
		k.slab(Vector3(0, 0.1, -0.6), Vector2(0.06, 0.04), Vector3(0, 1.3, -0.57), Vector2(0.05, 0.04), dark)
		k.pop()
	# Leaves splayed round the foot.
	for i in 5:
		var a := TAU * i / 5.0 + 0.3
		var d := Vector3(-sin(a), 0, -cos(a))
		k.face_dir([d * 0.5 + Vector3(0, 0.05, 0), d * 1.05 + Vector3(0, 0.02, 0) + Vector3(d.z, 0, -d.x) * 0.25, d * 1.25 + Vector3(0, 0.12, 0), d * 1.05 + Vector3(0, 0.02, 0) - Vector3(d.z, 0, -d.x) * 0.25], _c("5ab040"), Vector3.UP)
	# Pink petals folded over the top.
	for i in 6:
		var a := TAU * i / 6.0
		k.push(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -0.5), Vector3(0, 1.38, 0)))
		k.slab(Vector3(0, 0, -0.05), Vector2(0.12, 0.03), Vector3(0, 0.0, -0.4), Vector2(0.2, 0.02), _c("f07ab0"))
		k.pop()
	k.smooth_normals(55.0)
	_save(k.build(M.char), "bloom_pod_mesh.tres")


## A giant lily pad, 2.6 m across with a notch, and a pink bloom by its rim.
## Its top is at the node (it sits on the water's surface).
func _lily_pad() -> void:
	var k := _k()
	var green := _c("4a9a3a")
	var n := 18
	var pts: Array = []
	for i in n:
		var a := TAU * i / n + 0.17
		var r := 1.3 if i != 0 else 0.4
		pts.append(Vector3(cos(a) * r, 0.0, sin(a) * r))
	for i in n:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % n]
		k.face_dir([Vector3(0, 0.02, 0), b, a], green.lightened(0.05 if i % 2 else 0.0), Vector3.UP)
		k.face_dir([a, b, b + Vector3(0, -0.12, 0), a + Vector3(0, -0.12, 0)], green.darkened(0.25), Vector3(a.x + b.x, 0, a.z + b.z))
		k.face_dir([Vector3(0, -0.12, 0), a + Vector3(0, -0.12, 0), b + Vector3(0, -0.12, 0)], green.darkened(0.4), Vector3.DOWN)
	# Veins.
	for i in 6:
		var a := TAU * i / 6.0 + 0.5
		k.box(Vector3(cos(a) * 0.6, 0.025, sin(a) * 0.6), Vector3(1.0, 0.01, 0.03), _c("8ad060"))
	for i in 6:
		var a := TAU * i / 6.0
		k.push(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -0.6), Vector3(0.85, 0.02, 0.6)))
		k.slab(Vector3(0, 0, 0), Vector2(0.05, 0.02), Vector3(0, 0, -0.16), Vector2(0.08, 0.01), _c("f8a0c8"))
		k.pop()
	_save(k.build(M.char), "lily_pad_mesh.tres")


## A cracked stretch of wall, 3 m wide and 3.4 m tall, 0.6 m deep (OoT's
## Bg_Breakwall): it has to read as weak at a glance, from either side. Its
## blocks are pale and dusty, set unevenly (some pushed out, some sunk), and
## a dark star of fissures bursts from a broken hollow in the middle, its
## arms forking out to the edges; crumbs of stone lie heaped at its foot.
func _cracked_wall() -> void:
	var k := _k()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var stone := _c("aaa396")
	var dusty := _c("c4bba8")
	var crack := _c("1c1814")
	# The wall as uneven blocks: four courses, staggered.
	var rows := 4
	var row_h := 3.4 / rows
	for r in rows:
		var x := -1.5
		var w := 0.6 + (0.25 if r % 2 == 1 else 0.0)
		while x < 1.49:
			var bw := minf(w + rng.randf_range(-0.1, 0.25), 1.5 - x)
			var out := rng.randf_range(-0.04, 0.07)
			var col := stone.lerp(dusty, rng.randf_range(0.0, 0.7)).darkened(rng.randf_range(0.0, 0.12))
			k.box(Vector3(x + bw * 0.5, row_h * (r + 0.5), 0), Vector3(bw - 0.03, row_h - 0.03, 0.6 + out * 2.0), col)
			x += bw
			w = rng.randf_range(0.55, 0.95)
	# Mortar lines darker between the blocks, both faces.
	for face: float in [-1.0, 1.0]:
		var z := face * 0.32
		for r in range(1, rows):
			k.box(Vector3(0, row_h * r, z), Vector3(3.0, 0.035, 0.01), _c("5a5248"))
		# The burst in the middle: a dark broken hollow...
		var c := Vector3(rng.randf_range(-0.2, 0.2), 1.55, z)
		k.icosa(c, Vector3(0.42, 0.36, 0.05), 0.15, crack)
		k.icosa(c + Vector3(0.0, 0.0, face * 0.01), Vector3(0.62, 0.52, 0.03), 0.2, _c("5e554a"))
		# ...and the fissures forking out from it.
		for i in 7:
			var a := TAU * i / 7.0 + rng.randf_range(-0.2, 0.2)
			_fissure(k, rng, c, Vector2(cos(a), sin(a)), 0.6 + rng.randf_range(0.0, 0.8), 0.1, crack, 1, face)
	# Crumbs heaped at its foot on both sides.
	for i in 14:
		var side := -1.0 if i % 2 == 0 else 1.0
		var s := rng.randf_range(0.08, 0.2)
		k.icosa(Vector3(rng.randf_range(-1.3, 1.3), s * 0.6, side * rng.randf_range(0.38, 0.65)), Vector3(s, s * 0.7, s), 0.25, dusty.darkened(rng.randf_range(0.0, 0.2)))
	_save(k.build(M.stone), "cracked_wall_mesh.tres")


## A fissure from `from` along `dir` (on the wall's face plane, z fixed),
## `length` long and `width` wide at the root, forking `forks` more times:
## flat quads laid on the face (`face` -1 front, +1 back), two triangles a step.
func _fissure(k: MeshKit, rng: RandomNumberGenerator, from: Vector3, dir: Vector2, length: float, width: float, col: Color, forks: int, face: float) -> void:
	var p := from
	var d := dir.normalized()
	var steps := 2
	var seg := length / steps
	var nrm := Vector3(0, 0, face)
	for s in steps:
		d = d.rotated(rng.randf_range(-0.45, 0.45)).normalized()
		var q := p + Vector3(d.x, d.y, 0.0) * seg
		q.x = clampf(q.x, -1.45, 1.45)
		q.y = clampf(q.y, 0.05, 3.35)
		var w0 := width * (1.0 - float(s) / steps * 0.5) * 0.5
		var w1 := width * (1.0 - float(s + 1) / steps * 0.5) * 0.5
		var across := Vector3(-(q.y - p.y), q.x - p.x, 0.0).normalized()
		k.face_dir([p - across * w0, q - across * w1, q + across * w1, p + across * w0], col, nrm)
		if forks > 0 and rng.randf() < 0.6:
			_fissure(k, rng, q, d.rotated(rng.randf_range(0.5, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0)), length * 0.5, w1 * 1.6, col, forks - 1, face)
		p = q


## A big cracked boulder plugging a cave mouth (OoT's Obj_Bombiwa: bombs
## break it). Brown and dull beside the gray rock round it, split all over
## by deep dark cracks that run right round it, with chips flaked off its
## shoulders and lying at its foot, so it reads as breakable from any side.
func _bomb_boulder() -> void:
	var k := _k()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7171
	var body := _c("a8865e")
	k.icosa(Vector3(0, 1.3, 0), Vector3(1.6, 1.4, 1.3), 0.14, body, true)
	# Lumps where the stone has started to come apart.
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		k.icosa(Vector3(cos(a) * 1.05, 1.3 + sin(a * 2.0) * 0.5, sin(a) * 0.85), Vector3(0.55, 0.5, 0.5), 0.2, body.darkened(rng.randf_range(0.05, 0.2)))
	var crack := _c("181410")
	# Cracks running round it: rings of short dark strokes over the surface.
	for band in 3:
		var y := 0.55 + band * 0.75
		var r_xz := 1.62 * sqrt(maxf(1.0 - pow((y - 1.3) / 1.45, 2.0), 0.05))
		var n := 14
		var a0 := rng.randf_range(0.0, TAU)
		for i in n:
			if rng.randf() < 0.25:
				continue
			var a := a0 + TAU * i / n
			var pos := Vector3(cos(a) * r_xz * 1.0, y + rng.randf_range(-0.15, 0.15), sin(a) * r_xz * 0.82)
			k.push(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, rng.randf_range(-0.8, 0.8)), pos))
			k.box(Vector3.ZERO, Vector3(0.05, 0.42, 0.62), crack)
			k.pop()
	# Down its front and back, long forked splits.
	for face: float in [-1.0, 1.0]:
		for i in 3:
			var x := (i - 1) * 0.55
			k.push(Transform3D(Basis(Vector3.BACK, rng.randf_range(-0.4, 0.4)), Vector3(x, 1.35, face * 1.2)))
			k.box(Vector3.ZERO, Vector3(0.09, 1.3, 0.12), crack)
			k.pop()
	# Chips at its foot.
	for i in 10:
		var a := rng.randf_range(0.0, TAU)
		var s := rng.randf_range(0.12, 0.26)
		k.icosa(Vector3(cos(a) * 1.75, s * 0.5, sin(a) * 1.5), Vector3(s, s * 0.7, s), 0.25, body.darkened(0.15))
	_save(k.build(M.rock), "bomb_boulder_mesh.tres")


## A Sapphire Order bolt: a spinning blue crystal shard with a glow.
func _sapphire_bolt() -> void:
	var g := _k()
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	g.prism(Vector3(0, -0.28, 0), 0.0, Vector3(0, 0.0, 0), 0.12, 6, _c("60a8ff"))
	g.prism(Vector3(0, 0.0, 0), 0.12, Vector3(0, 0.22, 0), 0.0, 6, _c("b8e0ff"))
	g.pop()
	_save(g.build(M.glow), "sapphire_bolt_mesh.tres")


## A ball of the Gauntlet's fire (the final battle's fireballs).
func _fire_orb() -> void:
	var g := _k()
	g.icosa(Vector3.ZERO, Vector3(0.32, 0.32, 0.32), 0.12, _c("ffb040"))
	g.icosa(Vector3(0, 0, 0.12), Vector3(0.22, 0.22, 0.3), 0.15, _c("ffe080"))
	_save(g.build(M.glow), "fire_orb_mesh.tres")


## A heap of broken masonry and charred beams (the ruined town and castle).
func _rubble() -> void:
	var k := _k()
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for i in 9:
		var p := Vector3(r.randf_range(-1.1, 1.1), r.randf_range(0.1, 0.5), r.randf_range(-1.0, 1.0))
		k.icosa(p, Vector3(r.randf_range(0.3, 0.6), r.randf_range(0.25, 0.45), r.randf_range(0.3, 0.55)), 0.2, _c("8a847c").darkened(r.randf_range(0.0, 0.3)))
	for i in 3:
		k.push(Transform3D(Basis(Vector3.UP, r.randf() * PI) * Basis(Vector3.BACK, r.randf_range(-0.4, 0.4)), Vector3(r.randf_range(-0.6, 0.6), 0.45, r.randf_range(-0.5, 0.5))))
		k.box(Vector3.ZERO, Vector3(2.2, 0.2, 0.22), _c("2a1e16"))
		k.pop()
	k.smooth_normals(30.0)
	_save(k.build(M.char), "rubble_mesh.tres")
