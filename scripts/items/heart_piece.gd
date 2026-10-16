class_name HeartPiece
extends Area3D
## A Piece of Heart (OoT's Item_B_Heart / EnItem00 ITEM00_HEART_PIECE): a
## quarter of a heart container, turning slowly where it is hidden. Touching
## it plays the get-item scene; every fourth piece makes a new heart.
## `flag` remembers it has been taken. `appear_flag` (optional) keeps it
## hidden until set (a prize that turns up when a game is won).

@export var flag := ""
@export var appear_flag := ""

var _mesh: MeshInstance3D
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("heart_pieces")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Piece"
	_mesh.mesh = load("res://assets/models/heart_piece_mesh.tres")
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	cs.shape = s
	cs.position = Vector3(0, 0.6, 0)
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
		Sfx.play("item_pop", -4.0)


func _set_shown(on: bool) -> void:
	visible = on
	set_deferred("monitoring", on)


func _process(delta: float) -> void:
	_t += delta
	_mesh.position.y = 0.6 + sin(_t * 2.2) * 0.08
	_mesh.rotation.y = _t * 1.8


func _on_body(body: Node3D) -> void:
	if _taken or not visible or not (body is PlayerController):
		return
	_taken = true
	if flag != "":
		Progress.set_flag(flag)
	visible = false
	await GetItem.present(body as PlayerController, "heart_piece")
	queue_free()
