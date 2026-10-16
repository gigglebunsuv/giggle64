class_name DreamLight
extends StaticBody3D
## Something that answers LOTHELYE'S DREAM (PlayerItems.set_dream, Beta 1.5.0):
## - "path": a floor or step of dream-light. Awake, it is only a faint
##   shimmer you could put your hand through; while the hero dreams it is
##   bright and solid, and he walks on it (the astral way, the Rift's bridges).
## - "veil": a wall of the waking world's dark that the Dream sees through:
##   solid and dim while awake, gone while dreaming.
## Its picture is the child MeshInstance3D named "Mesh"; its shape the child
## CollisionShape3D named "Shape". Group "dream_light".

@export_enum("path", "veil") var mode := "path"

var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _on := false
var _t := 0.0


func _ready() -> void:
	add_to_group("dream_light")
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	_shape = get_node_or_null("Shape") as CollisionShape3D
	dream(PlayerItems.dreaming)


## The Dream's call: `on` while the hero dreams.
func dream(on: bool) -> void:
	_on = on
	var solid := on if mode == "path" else not on
	if _shape:
		_shape.set_deferred("disabled", not solid)
	if _mesh:
		_mesh.visible = true
		_mesh.transparency = (0.15 if solid else 0.82) if mode == "path" else (0.0 if solid else 0.92)


func is_solid() -> bool:
	return _on if mode == "path" else not _on


func _process(delta: float) -> void:
	if _mesh == null or mode != "path" or _on:
		return
	# Awake: a slow shimmer, so a sharp eye sees where the way would be.
	_t += delta
	_mesh.transparency = 0.8 + 0.08 * sin(_t * 2.2 + global_position.x * 0.4)
