extends RefCounted
## Meshes for Beta 1.3.0 ("Firebuns Returns", Chapter V, first half): the
## Ember Rod, the Questlord's Gauntlets, the great stones, the Ember Rod's
## burnables (black thorns, old web, rime-ice), the Knight's Techniques'
## targets (the kings' floor seals, the yard's straw target, rune bells,
## straw dummies, the shield pell). Saved as .tres meshes in res://assets/models/.
## The burnables are made 1 m to a side, their foot at the origin (Burnable
## stretches them to its box).

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 7300


func run(materials: Dictionary) -> void:
	M = materials
	_ember_rod()
	_gauntlets()
	_great_stone()
	_thorns()
	_web()
	_rime()
	_floor_seal()
	_training_plate()
	_rune_bell()
	_training_dummy()
	_pell()
	print("gen_ch5_items: done")


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


## The Ember Rod: a rod of black iron wound with red-gold wire, a cage of
## iron claws at the head holding a glowing coal. Along -Z from the fist.
func _ember_rod() -> void:
	var k := _k()
	var iron := _c("2a2424")
	var gold := _c("c8783a")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.2, 0), 0.022, Vector3(0, 0.7, 0), 0.026, 6, iron)
	for y in [-0.1, 0.1, 0.3, 0.5]:
		k.prism(Vector3(0, y, 0), 0.03, Vector3(0, y + 0.05, 0), 0.03, 6, gold)
	for i in 4:
		var a := TAU * i / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		k.prism(Vector3(0, 0.7, 0) + d * 0.02, 0.012, Vector3(0, 0.82, 0) + d * 0.07, 0.009, 4, iron)
		k.prism(Vector3(0, 0.82, 0) + d * 0.07, 0.009, Vector3(0, 0.9, 0) + d * 0.03, 0.0, 4, gold)
	k.pop()
	k.smooth_normals(40.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0, -0.81), Vector3(0.06, 0.06, 0.07), 0.15, _c("ff7a2a"), true)
	g.icosa(Vector3(0, 0, -0.81), Vector3(0.035, 0.035, 0.04), 0.0, _c("ffe0a0"))
	g.add_to(mesh, M.glow)
	_save(mesh, "ember_rod_mesh.tres")


## The Questlord's Gauntlets: a pair of steel gauntlets with flared cuffs,
## knuckle plates and a gold Questlord's sun on each back.
func _gauntlets() -> void:
	var k := _k()
	var steel := _c("9aa0aa")
	var dark := _c("5a606a")
	var gold := _c("d8b050")
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0) * Basis(Vector3.UP, sx * 0.25), Vector3(sx * 0.11, 0, 0)))
		k.prism(Vector3(0, -0.09, 0), 0.07, Vector3(0, 0.02, 0), 0.05, 10, steel)
		k.prism(Vector3(0, 0.02, 0), 0.05, Vector3(0, 0.1, 0), 0.045, 10, dark)
		for i in 3:
			k.box(Vector3(0, 0.1 + i * 0.022, -0.02), Vector3(0.08, 0.018, 0.05), steel.lightened(0.1))
		k.prism(Vector3(0, -0.095, 0), 0.075, Vector3(0, -0.075, 0), 0.075, 10, gold)
		k.icosa(Vector3(0, 0.0, -0.05), Vector3(0.022, 0.022, 0.01), 0.0, gold)
		k.pop()
	k.smooth_normals(45.0)
	_save(k.build(M.char), "questlord_gauntlets_mesh.tres")


## A great stone: a rounded boulder 2.3 m high, worn smooth where hands
## gripped it (two pale bands), its foot at the origin.
func _great_stone() -> void:
	var k := _k()
	k.icosa(Vector3(0, 1.15, 0), Vector3(1.2, 1.15, 1.2), 0.12, _c("8a8480"), true)
	k.icosa(Vector3(0.3, 1.9, -0.2), Vector3(0.6, 0.4, 0.55), 0.15, _c("7a746e"))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(sx * 0.5, 1.2, 1.02), Vector3(0.35, 0.5, 0.12), _c("b8b2a8"))
	k.smooth_normals(50.0)
	_save(k.build(M.rock if M.has("rock") else M.char), "great_stone_mesh.tres")


## Black thorns: a tangle of spiked briars in a 1 m box.
func _thorns() -> void:
	var k := _k()
	var col := _c("1e1a1a")
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for i in 22:
		var a := Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.0, 1.0), rng.randf_range(-0.4, 0.4))
		var b := a + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.3, 0.3), rng.randf_range(-0.2, 0.2))
		k.prism(a, 0.04, b, 0.02, 5, col.lightened(rng.randf_range(0.0, 0.1)))
		for j in 2:
			var t := a.lerp(b, 0.3 + j * 0.4)
			k.prism(t, 0.015, t + Vector3(rng.randf_range(-0.1, 0.1), 0.1, rng.randf_range(-0.1, 0.1)), 0.0, 3, _c("3a2a28"))
	_save(k.build(M.char), "thorns_mesh.tres")


## Old web: a sheet of gray strands across a doorway, 1 m to a side.
func _web() -> void:
	var k := _k()
	var col := _c("c8c4bc")
	for i in 7:
		var a := TAU * i / 7.0
		k.prism(Vector3(0, 0.5, 0), 0.008, Vector3(cos(a) * 0.5, 0.5 + sin(a) * 0.5, 0), 0.008, 3, col)
	for r in [0.15, 0.3, 0.45]:
		for i in 7:
			var a0 := TAU * i / 7.0
			var a1 := TAU * (i + 1) / 7.0
			k.prism(Vector3(cos(a0) * r, 0.5 + sin(a0) * r, 0), 0.006, Vector3(cos(a1) * r, 0.5 + sin(a1) * r, 0), 0.006, 3, col)
	_save(k.build(M.char), "web_mesh.tres")


## Rime-ice: a block of frost-white ice, rough-faced, 1 m to a side.
func _rime() -> void:
	var k := _k()
	k.box(Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), _c("d8e8f6"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 8:
		k.icosa(Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.2, 0.95), rng.randf_range(-0.45, 0.45)), Vector3(0.18, 0.2, 0.18), 0.2, _c("eef6ff"))
	_save(k.build(M.ice if M.has("ice") else M.char), "rime_mesh.tres")


## The kings' floor seal: a cracked slab of slate set with an iron crown,
## 1 m across and 0.3 thick, centered on the origin.
func _floor_seal() -> void:
	var k := _k()
	k.box(Vector3(0, 0.0, 0), Vector3(1.0, 0.3, 1.0), _c("5a5c66"))
	k.box(Vector3(0, 0.152, 0), Vector3(0.3, 0.01, 0.3), _c("3a3a40"))
	for i in 5:
		var a := TAU * i / 5.0
		k.box(Vector3(cos(a) * 0.12, 0.155, sin(a) * 0.12), Vector3(0.04, 0.012, 0.04), _c("8a7440"))
	for d in [Vector3(0.45, 0.153, 0.1), Vector3(-0.3, 0.153, -0.35), Vector3(0.2, 0.153, -0.4)]:
		k.box(d * Vector3(0.5, 1, 0.5), Vector3(0.5, 0.008, 0.015), _c("1a1a20"))
	_save(k.build(M.stone if M.has("stone") else M.char), "floor_seal_mesh.tres")


## The yard's straw target on the ground: rings of red and straw, 1 m across.
func _training_plate() -> void:
	var k := _k()
	k.prism(Vector3(0, 0.0, 0), 0.5, Vector3(0, 0.04, 0), 0.5, 16, _c("d8c070"))
	k.prism(Vector3(0, 0.04, 0), 0.32, Vector3(0, 0.05, 0), 0.32, 16, _c("c83a2a"))
	k.prism(Vector3(0, 0.05, 0), 0.18, Vector3(0, 0.06, 0), 0.18, 16, _c("d8c070"))
	k.prism(Vector3(0, 0.06, 0), 0.07, Vector3(0, 0.07, 0), 0.07, 12, _c("c83a2a"))
	_save(k.build(M.char), "training_plate_mesh.tres")


## A rune bell: a bronze bell hung from a stone post, 1.6 m tall.
func _rune_bell() -> void:
	var k := _k()
	k.prism(Vector3(0, 0, 0), 0.18, Vector3(0, 1.5, 0), 0.14, 6, _c("6a6a74"))
	k.box(Vector3(0, 1.55, -0.2), Vector3(0.1, 0.1, 0.5), _c("4a4a54"))
	k.prism(Vector3(0, 1.45, -0.38), 0.05, Vector3(0, 1.1, -0.38), 0.18, 10, _c("b8883a"))
	var mesh := k.build(M.char)
	var g := _k()
	g.prism(Vector3(0, 0.8, -0.181), 0.06, Vector3(0, 0.84, -0.181), 0.06, 6, _c("8ad8ff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "rune_bell_mesh.tres")


## A straw training dummy on a post: a sack body, a straw head, arms of sticks.
func _training_dummy() -> void:
	var k := _k()
	var straw := _c("d8c070")
	var sack := _c("a88a5a")
	k.prism(Vector3(0, 0, 0), 0.06, Vector3(0, 1.0, 0), 0.06, 6, _c("6a4a2a"))
	k.loft([[0.7, 0.0, 0.0, sack], [0.75, 0.2, 0.16, sack], [1.1, 0.24, 0.2, sack.lightened(0.1)], [1.35, 0.18, 0.15, sack], [1.4, 0.0, 0.0, sack]], 8)
	k.icosa(Vector3(0, 1.6, 0), Vector3(0.16, 0.18, 0.16), 0.15, straw)
	k.box(Vector3(0, 1.2, 0), Vector3(1.1, 0.06, 0.06), _c("6a4a2a"))
	k.box(Vector3(0, 1.05, -0.21), Vector3(0.3, 0.06, 0.02), _c("c83a2a"))
	k.smooth_normals(50.0)
	_save(k.build(M.char), "training_dummy_mesh.tres")


## The shield pell: a thick post with a crossbar, and (a mesh of its own, so
## it can be knocked off) a battered round wooden shield on its -Z face.
func _pell() -> void:
	var k := _k()
	k.prism(Vector3(0, 0, 0), 0.16, Vector3(0, 1.8, 0), 0.14, 8, _c("7a5a3a"))
	k.box(Vector3(0, 1.3, 0), Vector3(0.9, 0.1, 0.1), _c("6a4a2a"))
	k.prism(Vector3(0, 0, 0), 0.4, Vector3(0, 0.12, 0), 0.4, 8, _c("5a4a3a"))
	k.smooth_normals(45.0)
	_save(k.build(M.char), "training_pell_mesh.tres")
	var s := _k()
	s.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 1.1, -0.22)))
	s.prism(Vector3(0, -0.04, 0), 0.38, Vector3(0, 0.04, 0), 0.38, 12, _c("9a7444"))
	s.prism(Vector3(0, 0.04, 0), 0.08, Vector3(0, 0.08, 0), 0.06, 8, _c("6a6a74"))
	s.pop()
	_save(s.build(M.char), "training_pell_shield_mesh.tres")
