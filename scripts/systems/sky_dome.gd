extends Node3D
## Keeps the sky dome, sun and distant volcano centered on the active camera so
## they read as infinitely far away (they are drawn without fog).


func _ready() -> void:
	process_priority = 100


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		global_position = cam.global_position
