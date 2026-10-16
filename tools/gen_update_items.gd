extends RefCounted
## Meshes for the things added in the big update: the Piece of Heart, the
## fishing rod, its float and the fish of Mirror Lake, the Big Wallet, the
## Sugar Cube that calls the horse, and the Hookshot with its chain, tip and
## the targets it bites into. Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 900


func run(materials: Dictionary) -> void:
	M = materials
	_heart_piece()
	_fishing()
	_wallet()
	_sugar_cube()
	_hookshot()
	_shop_goods()
	_bun_pieces()


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


## A quarter of the heart container: its left lobe and the edge running down
## to the point, in a lighter, glassy red with a pale rim where it broke off.
func _heart_piece() -> void:
	var k := _k()
	k.shade_jitter = 0.0
	var s := 1.6
	var col := _c("e8384a")
	k.icosa(Vector3(-0.07, 0.05, 0) * s, Vector3(0.085, 0.085, 0.05) * s, 0.0, col, true)
	# The wedge down to the point, its broken edges pale.
	var a := Vector3(-0.155, 0.04, 0) * s
	var b := Vector3(0.0, 0.07, 0) * s
	var p := Vector3(0.0, -0.14, 0) * s
	var t := Vector3(0, 0, 0.05 * s)
	k.face_dir([a + t, b + t, p + t], col, Vector3(0, 0, 1))
	k.face_dir([a - t, p - t, b - t], col, Vector3(0, 0, -1))
	k.face_dir([a + t, p + t, p - t, a - t], col.darkened(0.15), Vector3(-1, -0.5, 0))
	k.face_dir([b + t, b - t, p - t, p + t], _c("ffd0d6"), Vector3(1, 0, 0))
	k.smooth_normals(60.0)
	_save(k.build(M.char), "heart_piece_mesh.tres")


## Mira's fishing rod (a long tapering pole with a reel), the red and white
## float, and a fish (scaled per catch).
func _fishing() -> void:
	var r := _k()
	r.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	r.prism(Vector3(0, -0.25, 0), 0.022, Vector3(0, 0.15, 0), 0.02, 6, _c("4a3020"))
	r.prism(Vector3(0, 0.15, 0), 0.016, Vector3(0, 2.1, 0), 0.006, 5, _c("c8a060"))
	r.prism(Vector3(-0.03, 0.02, 0), 0.05, Vector3(0.03, 0.02, 0), 0.05, 8, _c("8a8a94"))
	r.pop()
	_save(r.build(M.char), "fishing_rod_mesh.tres")
	var f := _k()
	f.icosa(Vector3(0, 0.03, 0), Vector3(0.05, 0.04, 0.05), 0.0, _c("f0f0f0"), true)
	f.icosa(Vector3(0, -0.01, 0), Vector3(0.05, 0.035, 0.05), 0.0, _c("e02a2a"), true)
	f.prism(Vector3(0, 0.06, 0), 0.008, Vector3(0, 0.12, 0), 0.004, 4, _c("e02a2a"))
	_save(f.build(M.char), "fishing_float_mesh.tres")
	# A fish one meter long (scaled to its size): body along -Z, tail at +Z.
	var fish := _k()
	fish.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	fish.loft([
		[-0.5, 0.0, 0.0, _c("6a7a4a")], [-0.42, 0.06, 0.08, _c("8a9a5a")], [-0.25, 0.1, 0.15, _c("9aaa6a")],
		[0.0, 0.1, 0.16, _c("8a9a5a")], [0.25, 0.06, 0.1, _c("7a8a4a")], [0.38, 0.03, 0.04, _c("6a7a3a")],
	], 8)
	fish.pop()
	fish.face_dir([Vector3(0, 0, 0.36), Vector3(0, 0.16, 0.58), Vector3(0, -0.16, 0.58)], _c("5a6a3a"), Vector3(1, 0, 0))
	fish.face_dir([Vector3(0, 0, 0.36), Vector3(0, -0.16, 0.58), Vector3(0, 0.16, 0.58)], _c("5a6a3a"), Vector3(-1, 0, 0))
	fish.face_dir([Vector3(0, 0.12, -0.1), Vector3(0, 0.24, 0.05), Vector3(0, 0.1, 0.15)], _c("5a6a3a"), Vector3(1, 0, 0))
	fish.face_dir([Vector3(0, 0.12, -0.1), Vector3(0, 0.1, 0.15), Vector3(0, 0.24, 0.05)], _c("5a6a3a"), Vector3(-1, 0, 0))
	for sx in [-1.0, 1.0]:
		fish.icosa(Vector3(0.06 * sx, 0.04, -0.38), Vector3(0.018, 0.018, 0.018), 0.0, _c("101010"))
	fish.smooth_normals(60.0)
	_save(fish.build(M.char), "fish_mesh.tres")
	# The dark shape of a fish under the water.
	var sh := _k()
	sh.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	sh.loft([[-0.5, 0.0, 0.0, _c("1a2a30")], [-0.3, 0.02, 0.14, _c("1a2a30")], [0.1, 0.02, 0.13, _c("1a2a30")], [0.5, 0.0, 0.0, _c("1a2a30")]], 6)
	sh.pop()
	_save(sh.build(M.shadow), "fish_shadow_mesh.tres")


## The Big Wallet: a plump leather purse tied with a cord.
func _wallet() -> void:
	var k := _k()
	k.icosa(Vector3(0, 0.1, 0), Vector3(0.16, 0.13, 0.09), 0.08, _c("a0582a"), true)
	k.prism(Vector3(0, 0.2, 0), 0.07, Vector3(0, 0.28, 0), 0.1, 8, _c("b8683a"))
	k.prism(Vector3(0, 0.205, 0), 0.075, Vector3(0, 0.225, 0), 0.075, 8, _c("e8c050"))
	k.icosa(Vector3(0, 0.1, -0.085), Vector3(0.05, 0.05, 0.01), 0.0, _c("3ad04a"))
	k.smooth_normals(60.0)
	_save(k.build(M.char), "big_wallet_mesh.tres")


## A sugar cube on a little paper wrap: the horse comes for it.
func _sugar_cube() -> void:
	var k := _k()
	k.box(Vector3(0, 0.0, 0), Vector3(0.2, 0.02, 0.2), _c("e8d8b0"))
	k.box(Vector3(0, 0.07, 0), Vector3(0.11, 0.11, 0.11), _c("fbfbf6"))
	k.box(Vector3(0.03, 0.13, -0.02), Vector3(0.03, 0.01, 0.03), _c("e8eef8"))
	_save(k.build(M.char), "sugar_cube_mesh.tres")


## The Hookshot (OoT's ITEM_HOOKSHOT): a stocky launcher with a grip and a
## spring drum, the barbed tip, one chain link, and the round wooden target.
## The launcher points along -Z like the hero's sword in his fist.
func _hookshot() -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.06, 0), 0.05, Vector3(0, 0.3, 0), 0.045, 8, _c("8a8a96"))
	k.prism(Vector3(0, 0.3, 0), 0.06, Vector3(0, 0.34, 0), 0.06, 8, _c("5a5a66"))
	k.prism(Vector3(0, 0.05, 0.0), 0.075, Vector3(0, 0.15, 0.0), 0.075, 10, _c("6a4a8a"))
	k.pop()
	# The grip below the barrel.
	k.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20)), Vector3(0, -0.02, 0.04)))
	k.prism(Vector3(0, -0.14, 0), 0.03, Vector3(0, 0.0, 0), 0.032, 6, _c("4a3020"))
	k.pop()
	_save(k.build(M.char), "hookshot_mesh.tres")
	var tip := _k()
	tip.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	tip.prism(Vector3(0, -0.04, 0), 0.04, Vector3(0, 0.08, 0), 0.0, 6, _c("d0d0dc"))
	for i in 3:
		var a := TAU * i / 3.0
		tip.push(Transform3D(Basis(Vector3.UP, a), Vector3.ZERO))
		tip.prism(Vector3(0.0, 0.0, 0), 0.012, Vector3(0.06, -0.06, 0), 0.004, 4, _c("b0b0bc"))
		tip.pop()
	tip.pop()
	_save(tip.build(M.char), "hookshot_tip_mesh.tres")
	var link := _k()
	link.box(Vector3.ZERO, Vector3(0.025, 0.025, 0.09), _c("9a9aa6"))
	_save(link.build(M.char), "hookshot_link_mesh.tres")
	# The target: a round wooden plate, a pale bullseye, studded rim.
	var t := _k()
	t.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	t.prism(Vector3(0, -0.05, 0), 0.42, Vector3(0, 0.05, 0), 0.42, 12, _c("8a5a30"))
	t.prism(Vector3(0, -0.056, 0), 0.3, Vector3(0, -0.05, 0), 0.3, 12, _c("d8b878"))
	t.prism(Vector3(0, -0.062, 0), 0.13, Vector3(0, -0.056, 0), 0.13, 10, _c("8a5a30"))
	for i in 8:
		var a := TAU * i / 8.0
		t.box(Vector3(cos(a) * 0.36, -0.06, sin(a) * 0.36), Vector3(0.05, 0.02, 0.05), _c("5a5a66"))
	t.pop()
	_save(t.build(M.wood), "hook_target_mesh.tres")


## Goods on Marigold's counter: a honey bun on a doily, and the Big Quiver.
func _shop_goods() -> void:
	var b := _k()
	b.prism(Vector3(0, 0.0, 0), 0.16, Vector3(0, 0.01, 0), 0.16, 12, _c("f4f0e8"))
	b.icosa(Vector3(0, 0.07, 0), Vector3(0.12, 0.07, 0.12), 0.05, _c("c88a3a"), true)
	b.icosa(Vector3(0, 0.12, 0), Vector3(0.08, 0.03, 0.08), 0.0, _c("f4e0a0"), true)
	b.smooth_normals(60.0)
	_save(b.build(M.char), "honey_bun_mesh.tres")
	var q := _k()
	q.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(15)), Vector3.ZERO))
	q.prism(Vector3(0, 0.0, 0), 0.09, Vector3(0, 0.55, 0), 0.11, 8, _c("8a5a30"))
	q.prism(Vector3(0, 0.1, 0), 0.095, Vector3(0, 0.14, 0), 0.095, 8, _c("e8c050"))
	q.prism(Vector3(0, 0.45, 0), 0.115, Vector3(0, 0.49, 0), 0.115, 8, _c("e8c050"))
	for i in 6:
		var a := TAU * i / 6.0
		var p := Vector3(cos(a) * 0.05, 0.55, sin(a) * 0.05)
		q.prism(p, 0.01, p + Vector3(0, 0.12, 0), 0.01, 4, _c("c8a060"))
		q.box(p + Vector3(0, 0.15, 0), Vector3(0.012, 0.07, 0.04), _c("f0f0f0"))
	q.pop()
	_save(q.build(M.char), "quiver_mesh.tres")


## The goddesses' bun pieces: each a third of one round golden bun, domed on
## top with the pale crumb showing where it was broken, and a gem in the
## goddess's color set in its crust (Alan's harvest green, Serielye's crimson,
## Aphiel's sky blue). The piece lies flat; its point is at the origin and it
## opens toward -Z.
func _bun_pieces() -> void:
	var gems := {"alan": _c("5ad040"), "serielye": _c("e8283a"), "aphiel": _c("58b8ff")}
	for goddess: String in gems:
		var gem: Color = gems[goddess]
		var k := _k()
		k.shade_jitter = 0.0
		var crust := _c("d8983e").lerp(gem, 0.12)
		var crumb := _c("f6e4bc")
		var base := _c("a86a2c")
		var rr := 0.16
		var hh := 0.08
		var lift := 0.02
		var rings := 5
		var segs := 8
		var a0 := -PI / 3.0
		var a1 := PI / 3.0
		var pt := func(i: int, j: int) -> Vector3:
			var r := rr * float(i) / rings
			var a := lerpf(a0, a1, float(j) / segs)
			var y := lift + hh * sqrt(maxf(1.0 - pow(r / rr, 2.0), 0.0))
			return Vector3(sin(a) * r, y, -cos(a) * r)
		# The domed top.
		for i in rings:
			for j in segs:
				var q: Array = [pt.call(i, j), pt.call(i + 1, j), pt.call(i + 1, j + 1), pt.call(i, j + 1)]
				var c := crust.darkened(0.08 * float(i) / rings)
				if i == 0:
					k.face_dir([q[0], q[1], q[2]], c, Vector3.UP)
				else:
					k.face_dir(q, c, Vector3.UP)
		# The rim down to the base, and the flat base.
		for j in segs:
			var top_a: Vector3 = pt.call(rings, j)
			var top_b: Vector3 = pt.call(rings, j + 1)
			var out := Vector3(top_a.x + top_b.x, 0, top_a.z + top_b.z).normalized()
			k.face_dir([top_a, top_b, Vector3(top_b.x, 0, top_b.z), Vector3(top_a.x, 0, top_a.z)], base, out)
			k.face_dir([Vector3.ZERO, Vector3(top_a.x, 0, top_a.z), Vector3(top_b.x, 0, top_b.z)], base, Vector3.DOWN)
		# The two broken faces, crumb pale.
		for edge in [[0, -1.0], [segs, 1.0]]:
			var j: int = edge[0]
			var prof: Array = [Vector3.ZERO]
			for i in range(0, rings + 1):
				prof.append(pt.call(i, j))
			var end: Vector3 = pt.call(rings, j)
			prof.append(Vector3(end.x, 0, end.z))
			var a := lerpf(a0, a1, float(j) / segs)
			var side := Vector3(cos(a), 0, sin(a)) * float(edge[1])
			k.face_dir(prof, crumb, side)
		k.smooth_normals(40.0)
		var mesh := k.build(M.char)
		# The gem set in the crust, a little proud of the dome.
		var g := _k()
		g.shade_jitter = 0.0
		var at: Vector3 = pt.call(2, segs / 2)
		g.icosa(at + Vector3(0, 0.012, 0), Vector3(0.028, 0.02, 0.028), 0.0, gem, true)
		g.add_to(mesh, M.glow)
		_save(mesh, "bun_piece_%s_mesh.tres" % goddess)
