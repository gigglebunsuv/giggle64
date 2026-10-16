class_name Hurtbox
extends Area3D
## A damageable region. Forwards hits to `receiver`, which must implement
## `take_hit(info: HitInfo) -> int` returning a Hurtbox.Result value.

enum Result { IGNORED, HIT, BLOCKED }

@export var receiver: Node


func _ready() -> void:
	monitoring = false
	monitorable = true
	if receiver == null:
		receiver = owner


func receive_hit(info: HitInfo) -> int:
	if receiver and receiver.has_method("take_hit"):
		return receiver.take_hit(info)
	return Result.IGNORED
