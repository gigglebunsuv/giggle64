class_name Feather
extends Rock
## One of Corvax's flung feathers: like an octorok's rock (it hurts the hero,
## and his shield bats it back), but it flies along all three axes, faster.

const FEATHER_SPEED := 13.0


func _ready() -> void:
	mesh_path = "res://assets/models/feather_mesh.tres" if mesh_path.ends_with("rock_mesh.tres") else mesh_path
	super._ready()


func launch(from: Vector3, dir: Vector3, by: Node3D) -> void:
	shooter = by
	global_position = from
	velocity = dir.normalized() * FEATHER_SPEED
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.BACK
	global_basis = Basis.looking_at(dir.normalized(), up)
