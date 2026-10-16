class_name FloorSwitch
extends Area3D
## A rusty floor switch (OoT's Obj_Switch, floor type): stepping on it presses
## the plate down with a clunk and sets its Progress flag. It stays down. A pot
## or rock thrown onto it presses it too (see Throwable).

@export var flag := ""

var pressed := false
var _plate: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("switches")
	var frame := MeshInstance3D.new()
	frame.mesh = load("res://assets/models/floor_switch_frame_mesh.tres")
	add_child(frame)
	_plate = MeshInstance3D.new()
	_plate.name = "Plate"
	(_plate as MeshInstance3D).mesh = load("res://assets/models/floor_switch_mesh.tres")
	add_child(_plate)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 0.8, 1.0)
	cs.shape = box
	cs.position = Vector3(0, 0.4, 0)
	add_child(cs)
	body_entered.connect(_on_body)
	pressed = flag != "" and Progress.flag(flag)
	if pressed:
		_plate.position.y = -0.12


func _on_body(body: Node3D) -> void:
	if body is PlayerController:
		press()


## Something heavy broke at `pos`: it presses the switch if it landed on it.
func weigh_down(pos: Vector3) -> void:
	var d := pos - global_position
	if Vector2(d.x, d.z).length() < 0.9 and d.y > -0.3 and d.y < 0.8:
		press()


func press() -> void:
	if pressed:
		return
	pressed = true
	Sfx.play("switch_press", -2.0)
	var t := create_tween()
	t.tween_property(_plate, "position:y", -0.12, 0.2)
	if flag != "":
		Progress.set_flag(flag)
