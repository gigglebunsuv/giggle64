extends RefCounted
## Meshes for the "Night Falls" update (alpha 1.5.0): the bottles and what
## they hold (empty, a fairy, milk, half milk, a red potion), and the fairy
## herself. Saved as .tres meshes in res://assets/models/.
##
## A bottle is OoT's: a squat round glass bottle (0.24 m tall, origin at its
## base) with a short neck, a lip and a cork, the contents showing through.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"
## What each bottle mesh holds: [fill color, fill height 0..1, glows].
const CONTENTS := {
	"empty": [Color(0, 0, 0, 0), 0.0, false],
	"fairy": [Color(1.0, 0.72, 0.9), 0.0, true],
	"milk": [Color(0.97, 0.96, 0.9), 0.85, false],
	"half_milk": [Color(0.97, 0.96, 0.9), 0.42, false],
	"red_potion": [Color(0.9, 0.12, 0.16), 0.85, false],
	"fish": [Color(0.45, 0.7, 0.95, 0.75), 0.85, false],
}

var M: Dictionary
var _seed := 2600


func run(materials: Dictionary) -> void:
	M = materials
	M = M.duplicate()
	M["glass"] = _glass_material()
	for content: String in CONTENTS:
		_bottle(content)
	_fairy()


## Clear glass: vertex colors with their alpha, lit, seen from both sides.
func _glass_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.roughness = 0.15
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var path := "res://assets/materials/glass.tres"
	ResourceSaver.save(m, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _c(h: String) -> Color:
	return Color.html(h)


func _k() -> MeshKit:
	_seed += 1
	return MeshKit.new(_seed)


func _save(res: Resource, file: String) -> void:
	var err := ResourceSaver.save(res, MODEL_DIR + file)
	if err != OK:
		push_error("Failed to save %s: %s" % [file, err])


func _bottle(content: String) -> void:
	var spec: Array = CONTENTS[content]
	var glass := Color(0.75, 0.9, 0.96, 0.4)
	var g := _k()
	# The glass: a round body, the shoulder, the neck and a lip.
	g.loft([
		[0.0, 0.0, 0.0, glass.darkened(0.2)], [0.005, 0.06, 0.06, glass.darkened(0.1)], [0.03, 0.085, 0.085, glass],
		[0.09, 0.095, 0.095, glass.lightened(0.12)], [0.14, 0.085, 0.085, glass], [0.175, 0.045, 0.045, glass],
		[0.2, 0.03, 0.03, glass.darkened(0.05)], [0.215, 0.038, 0.038, glass.lightened(0.15)], [0.225, 0.034, 0.034, glass],
	], 12, false)
	g.smooth_normals(70.0)
	var mesh := ArrayMesh.new()
	# The contents first (seen through the glass), then the glass, the cork.
	var fill: Color = spec[0]
	var level: float = spec[1]
	if level > 0.0:
		var f := _k()
		var top := 0.012 + 0.15 * level
		var rings := [[0.008, 0.0, 0.0, fill.darkened(0.15)], [0.012, 0.075, 0.075, fill.darkened(0.08)]]
		for y in [0.04, 0.09, 0.14]:
			if y < top:
				var rr := 0.083 if y < 0.12 else 0.07
				rings.append([y, rr, rr, fill])
		var rt := 0.08 if top < 0.12 else (0.07 if top < 0.15 else 0.04)
		rings.append([top, rt, rt, fill.lightened(0.1)])
		rings.append([top + 0.0005, 0.0, 0.0, fill.lightened(0.15)])
		f.loft(rings, 12)
		f.smooth_normals(70.0)
		f.add_to(mesh, M.char)
	if spec[2]:
		# A fairy curled up inside, glowing.
		var fy := _k()
		fy.icosa(Vector3(0, 0.08, 0), Vector3(0.045, 0.045, 0.045), 0.0, fill)
		fy.icosa(Vector3(0, 0.08, 0), Vector3(0.07, 0.06, 0.07), 0.1, fill.lightened(0.3))
		fy.add_to(mesh, M.glow)
	if content == "fish":
		# A little fish swimming in the water, nose to one side.
		var fs := _k()
		fs.push(Transform3D(Basis(Vector3.UP, PI / 2.0).rotated(Vector3.FORWARD, 0.25), Vector3(0, 0.085, 0)))
		fs.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		fs.loft([[-0.06, 0.0, 0.0, _c("8a9a5a")], [-0.04, 0.014, 0.022, _c("9aaa6a")], [0.0, 0.016, 0.026, _c("8a9a5a")], [0.035, 0.008, 0.012, _c("7a8a4a")]], 8)
		fs.pop()
		fs.face_dir([Vector3(0, 0, 0.03), Vector3(0, 0.022, 0.062), Vector3(0, -0.022, 0.062)], _c("5a6a3a"), Vector3(1, 0, 0))
		fs.face_dir([Vector3(0, 0, 0.03), Vector3(0, -0.022, 0.062), Vector3(0, 0.022, 0.062)], _c("5a6a3a"), Vector3(-1, 0, 0))
		fs.icosa(Vector3(0.012, 0.006, -0.045), Vector3(0.005, 0.005, 0.005), 0.0, _c("101010"))
		fs.icosa(Vector3(-0.012, 0.006, -0.045), Vector3(0.005, 0.005, 0.005), 0.0, _c("101010"))
		fs.pop()
		fs.smooth_normals(60.0)
		fs.add_to(mesh, M.char)
	g.add_to(mesh, M.glass)
	var cork := _k()
	cork.prism(Vector3(0, 0.205, 0), 0.026, Vector3(0, 0.25, 0), 0.031, 8, _c("b8865a"))
	cork.add_to(mesh, M.char)
	_save(mesh, "bottle_%s_mesh.tres" % content)


## The fairy's glow: a bright core inside a soft pink halo.
func _fairy() -> void:
	var k := _k()
	k.icosa(Vector3.ZERO, Vector3(0.06, 0.06, 0.06), 0.0, Color(1.0, 0.95, 0.98), true)
	k.icosa(Vector3.ZERO, Vector3(0.11, 0.11, 0.11), 0.08, Color(1.0, 0.65, 0.88))
	_save(k.build(M.glow), "fairy_mesh.tres")
