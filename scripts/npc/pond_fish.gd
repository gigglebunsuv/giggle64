extends Node3D
## The fish in Himeko's palace pond: it only lives there once the hero has
## brought her one in a bottle (`flag`), and then it swims slow circles just
## under the water, turning back now and then.

@export var flag := ""
@export var radius := 0.6

var _mesh: MeshInstance3D
var _t := 0.0
var _dir := 1.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "Fish"
	_mesh.mesh = load("res://assets/models/fish_mesh.tres")
	_mesh.scale = Vector3.ONE * 0.32
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_t = randf() * TAU
	_refresh()
	Progress.changed.connect(_refresh)


func _refresh() -> void:
	visible = flag == "" or Progress.flag(flag)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta * 0.7 * _dir
	if fmod(_t, 9.0) < delta * 0.7:
		_dir = -_dir
	var p := Vector3(cos(_t), 0.0, sin(_t)) * radius
	_mesh.position = p + Vector3(0, sin(_t * 3.0) * 0.01, 0)
	# Nose along the way it swims, the tail wagging.
	var along := Vector3(-sin(_t), 0.0, cos(_t)) * _dir
	_mesh.rotation = Vector3(0, atan2(-along.x, -along.z), 0) + Vector3(0, sin(_t * 9.0) * 0.15, 0)
