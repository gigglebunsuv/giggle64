class_name Spinner
extends Node3D
## Machinery that turns once a flag is set (the Southern Tower's water wheel,
## millstone and cog wheels when the mill is running): its children rotate
## about `axis` at `speed` degrees a second. With no flag it always turns.

@export var flag := ""
@export var axis := Vector3.UP
@export var speed := 30.0

var running := false


func _ready() -> void:
	add_to_group("spinners")
	running = flag == "" or Progress.flag(flag)


func _process(delta: float) -> void:
	if not running:
		running = Progress.flag(flag)
		return
	rotate_object_local(axis.normalized(), deg_to_rad(speed) * delta)
