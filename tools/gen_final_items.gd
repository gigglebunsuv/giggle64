extends RefCounted
## Meshes for Beta 1.5.0 ("The Astral Rift", the end of Chapter V): Lothelye's
## Dream (the last spell), the star lock the Rift's memory islands light, and
## the shards of Firebuns III's broken ice prison. Saved as .tres meshes in
## res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 7500


func run(materials: Dictionary) -> void:
	M = materials
	_dream()
	_star_lock()
	_prison_shard()
	_scythe()
	print("gen_final_items: done")


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


## Lothelye's Dream: a thin silver crescent moon cradling a teardrop of pale
## violet dream-light, three small stars round it. About 0.3 m tall.
func _dream() -> void:
	var k := _k()
	var silver := _c("d0d8e8")
	# The crescent: short prisms along an arc, thick in the middle, tapering.
	var n := 9
	for i in n:
		var a0 := lerpf(-2.3, 2.3, float(i) / n)
		var a1 := lerpf(-2.3, 2.3, float(i + 1) / n)
		var r0 := 0.012 + 0.018 * (1.0 - absf(lerpf(-1.0, 1.0, float(i) / n)))
		var r1 := 0.012 + 0.018 * (1.0 - absf(lerpf(-1.0, 1.0, float(i + 1) / n)))
		var p0 := Vector3(sin(a0) * 0.13, -cos(a0) * 0.13, 0)
		var p1 := Vector3(sin(a1) * 0.13, -cos(a1) * 0.13, 0)
		k.prism(p0, r0, p1, r1, 6, silver if i % 2 == 0 else silver.darkened(0.12))
	var mesh := k.build(M.char)
	var g := _k()
	# The teardrop, point up.
	g.prism(Vector3(0, -0.06, 0), 0.0, Vector3(0, -0.02, 0), 0.05, 8, _c("b8a8ff"))
	g.prism(Vector3(0, -0.02, 0), 0.05, Vector3(0, 0.03, 0), 0.04, 8, _c("cfc4ff"))
	g.prism(Vector3(0, 0.03, 0), 0.04, Vector3(0, 0.12, 0), 0.0, 8, _c("eeeaff"))
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		g.icosa(Vector3(cos(a) * 0.17, sin(a) * 0.17, 0.0), Vector3(0.016, 0.016, 0.016), 0.0, _c("ffffff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "lothelyes_dream_mesh.tres")


## A star lock: a low silver pedestal with an eight-pointed star of glass
## lying in its top (dark until lit; the light is the scene's, not the mesh's).
func _star_lock() -> void:
	var k := _k()
	var stone := _c("8a8ca8")
	k.prism(Vector3(0, 0, 0), 0.55, Vector3(0, 0.2, 0), 0.5, 8, stone.darkened(0.2))
	k.prism(Vector3(0, 0.2, 0), 0.32, Vector3(0, 0.75, 0), 0.26, 8, stone)
	k.prism(Vector3(0, 0.75, 0), 0.42, Vector3(0, 0.88, 0), 0.42, 8, stone.lightened(0.15))
	for i in 8:
		var a := TAU * i / 8.0
		var r := 0.36 if i % 2 == 0 else 0.2
		k.prism(Vector3(0, 0.89, 0), 0.04, Vector3(cos(a) * r, 0.9, sin(a) * r), 0.0, 4, _c("c8ccec"))
	_save(k.build(M.char), "star_lock_mesh.tres")


## A shard of the broken ice prison: a long jagged blade of pale crystal,
## its foot at the origin, about 2 m tall.
func _prison_shard() -> void:
	var k := _k()
	k.prism(Vector3(0, 0, 0), 0.4, Vector3(0.1, 1.2, 0.05), 0.22, 5, _c("a8c8f0"))
	k.prism(Vector3(0.1, 1.2, 0.05), 0.22, Vector3(0.05, 2.1, -0.08), 0.0, 5, _c("d8ecff"))
	k.prism(Vector3(0.2, 0.2, 0.1), 0.18, Vector3(0.55, 0.9, 0.2), 0.0, 4, _c("c0dcf8"))
	_save(k.build(M.glow), "prison_shard_mesh.tres")


## The scythe glimpsed after the credits (Saga V's Lord of Death): a long
## black haft and a great pale crescent blade, held upright from the hand.
func _scythe() -> void:
	var k := _k()
	var haft := _c("16141a")
	k.prism(Vector3(0, -0.8, 0), 0.025, Vector3(0, 1.4, 0), 0.03, 6, haft)
	k.prism(Vector3(0, 1.38, 0), 0.04, Vector3(0, 1.46, 0), 0.04, 6, _c("4a4650"))
	var mesh := k.build(M.char)
	var b := _k()
	var steel := _c("c8ccd8")
	var n := 10
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var a0 := lerpf(0.0, 2.4, t0)
		var a1 := lerpf(0.0, 2.4, t1)
		var r := 0.62
		var p0 := Vector3(-sin(a0) * r, 1.42 - (1.0 - cos(a0)) * r * 0.55, 0)
		var p1 := Vector3(-sin(a1) * r, 1.42 - (1.0 - cos(a1)) * r * 0.55, 0)
		b.prism(p0, lerpf(0.07, 0.0, t0) + 0.005, p1, lerpf(0.07, 0.0, t1) + 0.005, 4, steel if i % 2 == 0 else steel.darkened(0.15))
	b.add_to(mesh, M.char)
	_save(mesh, "scythe_mesh.tres")
