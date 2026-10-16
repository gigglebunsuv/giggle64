extends RefCounted
## Meshes for Beta 1.4.0 ("Black Water Ridge", Chapter V, second half): the
## Iron Flail (whole, for the item-get and its icon; the handle alone in the
## fist while the ball flies; the spiked ball). Saved as .tres meshes in
## res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 7400


func run(materials: Dictionary) -> void:
	M = materials
	_flail_handle()
	_flail_ball()
	_flail_whole()
	print("gen_ridge_items: done")


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


## The handle: a short haft of dark wood bound in iron, a ring at the end
## where the chain hangs. Along -Z from the fist (as the hero's sword).
func _handle(k: MeshKit) -> void:
	var wood := _c("4a3424")
	var iron := _c("3a3a42")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.1, 0), 0.03, Vector3(0, 0.42, 0), 0.034, 6, wood)
	for y in [-0.06, 0.12, 0.3]:
		k.prism(Vector3(0, y, 0), 0.04, Vector3(0, y + 0.05, 0), 0.04, 6, iron)
	k.prism(Vector3(0, 0.42, 0), 0.05, Vector3(0, 0.48, 0), 0.03, 6, iron)
	k.pop()


func _flail_handle() -> void:
	var k := _k()
	_handle(k)
	k.smooth_normals(40.0)
	_save(k.build(M.char), "iron_flail_handle_mesh.tres")


## The ball: black iron, eight squat spikes.
func _ball(k: MeshKit, c: Vector3, r: float) -> void:
	var iron := _c("2e2e34")
	var spike := _c("6a6a74")
	k.icosa(c, Vector3(r, r, r), 0.0, iron, true)
	var dirs := [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK,
		Vector3(1, 1, 1).normalized(), Vector3(-1, -1, 1).normalized()]
	for d: Vector3 in dirs:
		k.prism(c + d * r * 0.85, r * 0.28, c + d * r * 1.55, 0.0, 4, spike)


func _flail_ball() -> void:
	var k := _k()
	_ball(k, Vector3.ZERO, 0.26)
	_save(k.build(M.char), "iron_flail_ball_mesh.tres")


## The whole flail: the handle, a sagging chain, and the ball hanging below.
func _flail_whole() -> void:
	var k := _k()
	_handle(k)
	var iron := _c("3a3a42")
	var a := Vector3(0, 0, -0.48)
	var b := Vector3(0, -0.5, -0.62)
	for i in 6:
		var t := float(i) / 5.0
		k.icosa(a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.05, 0), Vector3(0.035, 0.035, 0.035), 0.0, iron)
	_ball(k, b + Vector3(0, -0.24, 0), 0.22)
	_save(k.build(M.char), "iron_flail_mesh.tres")
