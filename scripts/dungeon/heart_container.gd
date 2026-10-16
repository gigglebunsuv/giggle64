class_name HeartContainer
extends Area3D
## The heart container left by a dungeon's master (OoT's Item_B_Heart): it
## appears floating and turning once `appear_flag` is set, and touching it
## plays the get-item scene: one more heart, all of them refilled.

@export var appear_flag := ""
## Set once it has been taken.
@export var flag := ""
## What it is (a GetItem id): the heart container, or a goddess's bun piece.
@export var item := "heart_container"

var _mesh: MeshInstance3D
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("heart_containers")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Heart"
	_mesh.mesh = load("res://assets/models/%s.tres" % GetItem.definition(item).mesh)
	if item != "heart_container":
		_mesh.scale = Vector3.ONE * 2.4
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.9
	cs.shape = s
	cs.position = Vector3(0, 1.0, 0)
	add_child(cs)
	body_entered.connect(_on_body)
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	_set_shown(appear_flag == "" or Progress.flag(appear_flag))
	if not visible:
		Progress.changed.connect(_check)


func _check() -> void:
	if not visible and Progress.flag(appear_flag):
		Progress.changed.disconnect(_check)
		_set_shown(true)


func _set_shown(on: bool) -> void:
	visible = on
	set_deferred("monitoring", on)


func _process(delta: float) -> void:
	_t += delta
	_mesh.position.y = 1.0 + sin(_t * 2.0) * 0.12
	_mesh.rotation.y = _t * 1.5


func _on_body(body: Node3D) -> void:
	if _taken or not visible or not (body is PlayerController):
		return
	_taken = true
	if flag != "":
		Progress.set_flag(flag)
	visible = false
	await GetItem.present(body as PlayerController, item)
	queue_free()
