class_name IncunabulumPage
extends Area3D
## A page torn out of the Fari Incunabulum, the Sapphire Order's forbidden
## tome: it floats, turning, where it was lost; touching it reads it (the
## get-item scene, then its words) and keeps it in the JOURNAL. Five pages are
## scattered between the Forest of the Dead and the Sapphire Sanctum
## (incunabulum_lines.gd holds their words; flags "incunabulum:<n>").

@export var page := 1

var _mesh: MeshInstance3D
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	if Progress.flag(IncunabulumLines.flag_of(page)):
		queue_free()
		return
	_mesh = MeshInstance3D.new()
	_mesh.name = "Page"
	_mesh.mesh = load("res://assets/models/incunabulum_page_mesh.tres")
	_mesh.scale = Vector3.ONE * 1.6
	add_child(_mesh)
	var light := OmniLight3D.new()
	light.name = "Glow"
	light.light_color = Color(0.5, 0.65, 1.0)
	light.light_energy = 0.6
	light.omni_range = 2.5
	add_child(light)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.7
	cs.shape = s
	add_child(cs)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	if _mesh == null:
		return
	_t += delta
	_mesh.position.y = sin(_t * 1.8) * 0.1
	_mesh.rotation.y = _t * 1.2
	_mesh.rotation.z = sin(_t * 0.9) * 0.15


func _on_body(body: Node3D) -> void:
	if _taken or not (body is PlayerController):
		return
	_taken = true
	visible = false
	await GetItem.present(body as PlayerController, "incunabulum_page_%d" % page)
	queue_free()
