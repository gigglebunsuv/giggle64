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
	# Online, a creature is the host's to hurt: a client's blow goes there.
	if Net.forward_hit(receiver, info):
		return Result.HIT
	if receiver and receiver.has_method("take_hit"):
		return receiver.take_hit(info)
	return Result.IGNORED
