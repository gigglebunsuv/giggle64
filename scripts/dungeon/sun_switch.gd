class_name SunSwitch
extends StaticBody3D
## A sun face carved in the stone (OoT's Spirit Temple sun switches): held in
## a beam of light for a moment it blazes up, sets its flag and stays lit.
## Its MeshInstance3D child "Mesh" has the face as its last surface, which
## glows.

const WAKE_TIME := 0.4

@export var flag := ""

var on := false
var _light := 0.0
var _mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("sun_switches")
	var face := get_node_or_null("Mesh") as MeshInstance3D
	if face and face.mesh:
		var last := face.mesh.get_surface_count() - 1
		var m := face.mesh.surface_get_material(last) as StandardMaterial3D
		if m:
			_mat = m.duplicate()
			face.set_surface_override_material(last, _mat)
	on = flag != "" and Progress.flag(flag)
	_colour()


func light_hit(delta: float, _dir: Vector3) -> void:
	if on:
		return
	_light += delta
	_colour()
	if _light >= WAKE_TIME:
		on = true
		Sfx.play("puzzle_solved", -3.0, 0.0)
		if flag != "":
			Progress.set_flag(flag)
		_colour()


func _colour() -> void:
	if _mat == null:
		return
	if on:
		_mat.albedo_color = Color(2.0, 1.6, 0.6)
	else:
		_mat.albedo_color = Color(0.7, 0.55, 0.3).lerp(Color(1.8, 1.4, 0.6), clampf(_light / WAKE_TIME, 0.0, 1.0))
