class_name Shutter
extends AnimatableBody3D
## A stone shutter over a doorway (OoT's Door_Shutter, "front clear" type): it
## waits up inside the wall above the door, drops shut when its room
## (DungeonRoom) starts a fight, and rises again when the room is cleared.
## The node sits on the doorway's floor, facing along the passage.

const RISE := 3.4

@export var room_id := ""

var closed := false
var _base := Vector3.ZERO


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	add_to_group("shutters")
	_base = position
	for m in ["shutter_mesh", "shutter_emblem_mesh"]:
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/%s.tres" % m)
		add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.2, 0.3)
	cs.shape = box
	cs.position = Vector3(0, 1.6, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)
	position = _base + Vector3.UP * RISE


func close() -> void:
	if closed:
		return
	closed = true
	Sfx.play("shutter_close", -2.0)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "position", _base, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func open() -> void:
	if not closed:
		return
	closed = false
	Sfx.play("shutter_open", -3.0)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "position", _base + Vector3.UP * RISE, 0.8).set_trans(Tween.TRANS_SINE)
