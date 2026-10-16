extends MeshInstance3D
## N64-style blob shadow: a dark disc projected straight down onto the ground
## beneath its parent, shrinking as the parent rises.

@export var radius := 0.45
@export var max_height := 6.0
@export_flags_3d_physics var ground_mask := 1


func _ready() -> void:
	top_level = true


func _physics_process(_delta: float) -> void:
	var origin := (get_parent() as Node3D).global_position + Vector3.UP * 0.3
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * max_height, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		visible = false
		return
	visible = true
	var drop: float = origin.y - hit.position.y
	var s := radius * 2.0 * clampf(1.0 - drop / max_height, 0.3, 1.0)
	var n: Vector3 = hit.normal
	var x := n.cross(Vector3.BACK).normalized()
	if x.length_squared() < 0.01:
		x = Vector3.RIGHT
	var z := x.cross(n).normalized()
	global_transform = Transform3D(Basis(x * s, n, z * s), hit.position + n * 0.03)
