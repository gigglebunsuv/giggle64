extends RefCounted
## Meshes for the goddess towers' new things: Ladhellin Tower's turning bronze
## mirrors and carved sun switches, and Skyreach Spire's Wind Boots, wind vanes
## and gust vents. Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 1300


func run(materials: Dictionary) -> void:
	M = materials
	_light_mirror()
	_sun_switch()
	_boots("leather", _c("8a5a32"), _c("6a4024"), false)
	_boots("wind", _c("a8d4f0"), _c("6a9ac8"), true)


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


## A great round mirror of polished bronze in a sandstone frame, held up on a
## turning drum. Its face looks along -Z; the disc's middle is 1.15 m up, at
## the height the Mirror Shield throws light.
func _light_mirror() -> void:
	var k := _k()
	var stone := _c("d8c090")
	var bronze := _c("b8803a")
	# The drum it turns on, and the post.
	k.prism(Vector3(0, 0, 0), 0.55, Vector3(0, 0.3, 0), 0.5, 10, stone.darkened(0.15))
	k.prism(Vector3(0, 0.3, 0), 0.12, Vector3(0, 0.55, 0), 0.12, 6, bronze.darkened(0.3))
	# The frame: a ring of short blocks round the disc.
	var c := Vector3(0, 1.15, 0)
	for i in 14:
		var a := TAU * i / 14.0
		k.push(Transform3D(Basis(Vector3.BACK, a), c))
		k.box(Vector3(0, 0.6, 0.02), Vector3(0.3, 0.14, 0.16), stone)
		k.pop()
	# Two arms from the post up to the frame's sides.
	for sx in [-1.0, 1.0]:
		k.prism(Vector3(0, 0.5, 0), 0.06, Vector3(0.62 * sx, 1.0, 0.04), 0.05, 5, bronze.darkened(0.3))
	k.smooth_normals(40.0)
	var mesh := k.build(M.char)
	# The polished face (unshaded, so it reads bright).
	var g := _k()
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), c))
	g.prism(Vector3(0, 0.02, 0), 0.56, Vector3(0, -0.05, 0), 0.56, 18, _c("f8e0a0"))
	g.prism(Vector3(0, -0.05, 0), 0.56, Vector3(0, -0.08, 0), 0.5, 18, bronze)
	g.pop()
	g.add_to(mesh, M.glow)
	_save(mesh, "light_mirror_mesh.tres")


## A square sandstone plaque with a sun carved on it: a round face ringed with
## twelve rays. The plaque is 1.3 m across and 0.2 m deep, its face toward
## -Z and its middle at the node; the sun is its last surface (it glows when
## the light wakes it).
func _sun_switch() -> void:
	var k := _k()
	k.box(Vector3(0, 0, 0.0), Vector3(1.3, 1.3, 0.2), _c("c8b080"))
	k.box(Vector3(0, 0, -0.1), Vector3(1.1, 1.1, 0.04), _c("a89060"))
	var mesh := k.build(M.char)
	var g := _k()
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0, -0.12)))
	g.prism(Vector3(0, 0, 0), 0.24, Vector3(0, -0.06, 0), 0.22, 14, _c("ffffff"))
	g.pop()
	for i in 12:
		var a := TAU * i / 12.0
		g.push(Transform3D(Basis(Vector3.BACK, a), Vector3(0, 0, -0.13)))
		g.prism(Vector3(0, 0.28, 0), 0.06, Vector3(0, 0.46, 0), 0.0, 3, _c("ffffff"))
		g.pop()
	# The material is shared: SunSwitch tints its own copy.
	var mat: StandardMaterial3D = (M.glow as StandardMaterial3D).duplicate()
	g.add_to(mesh, mat)
	_save(mesh, "sun_switch_mesh.tres")


## A pair of boots side by side (for the get-item scene and the icon): tall
## shafts with a turned-down cuff. The Wind Boots are sky blue with a white
## wing at each ankle.
func _boots(id: String, col: Color, dark: Color, wings: bool) -> void:
	var k := _k()
	for sx in [-1.0, 1.0]:
		var x: float = 0.07 * sx
		k.prism(Vector3(x, 0.02, 0.0), 0.05, Vector3(x, 0.2, 0.0), 0.048, 8, col)
		k.prism(Vector3(x, 0.19, 0.0), 0.058, Vector3(x, 0.23, 0.0), 0.06, 8, dark)
		k.box(Vector3(x, 0.025, -0.045), Vector3(0.085, 0.05, 0.13), col)
		k.box(Vector3(x, 0.004, -0.02), Vector3(0.09, 0.012, 0.18), dark)
		if wings:
			for i in 3:
				k.face_dir([Vector3(x + 0.05 * sx, 0.12, 0.02), Vector3(x + (0.12 + i * 0.02) * sx, 0.2 - i * 0.04, 0.05 + i * 0.02), Vector3(x + 0.05 * sx, 0.16, 0.06)], _c("ffffff"), Vector3(sx, 0, 0))
				k.face_dir([Vector3(x + 0.05 * sx, 0.12, 0.02), Vector3(x + 0.05 * sx, 0.16, 0.06), Vector3(x + (0.12 + i * 0.02) * sx, 0.2 - i * 0.04, 0.05 + i * 0.02)], _c("e8eef8"), Vector3(-sx, 0, 0))
	k.smooth_normals(45.0)
	_save(k.build(M.char), "boots_%s_mesh.tres" % id)
