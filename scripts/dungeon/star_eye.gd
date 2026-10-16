class_name StarEye
extends StaticBody3D
## A star eye of the Temple of Bun (Chapter IV): a stone boss on a wall with a
## closed eye of pale crystal. A Starfall Arrow opens it (Arrow.starfall_hit):
## it blazes white. With `hold` > 0 it closes again after that many seconds;
## every eye sharing a `result` flag must be open at once to set it (and then
## they all stay open). With no result, its own `flag` is set and stays.

@export var flag := ""
@export var result := ""
@export var hold := 0.0

var open := false
var _t := 0.0
var _mat: StandardMaterial3D
var _light: OmniLight3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("star_eyes")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 0.4)
	cs.shape = box
	cs.set_meta("no_climb", true)
	add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	if ResourceLoader.exists("res://assets/models/star_eye_mesh.tres"):
		mi.mesh = load("res://assets/models/star_eye_mesh.tres")
		var m := mi.mesh.surface_get_material(mi.mesh.get_surface_count() - 1)
		if m is StandardMaterial3D:
			_mat = (m as StandardMaterial3D).duplicate()
			mi.set_surface_override_material(mi.mesh.get_surface_count() - 1, _mat)
	add_child(mi)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.85, 0.9, 1.0)
	_light.omni_range = 5.0
	_light.position = Vector3(0, 0, -0.6)
	add_child(_light)
	var done := (flag != "" and Progress.flag(flag)) or (result != "" and Progress.flag(result))
	_show(done)
	open = done


func _show(on: bool) -> void:
	if _mat:
		_mat.albedo_color = Color(1.3, 1.35, 1.5) if on else Color(0.25, 0.27, 0.32)
	_light.light_energy = 1.6 if on else 0.0


func starfall_hit(_arrow: Node3D) -> void:
	if open:
		return
	open = true
	_t = 0.0
	_show(true)
	Sfx.play("goddess_chime", -4.0, 0.05, 1.2)
	if result == "":
		if flag != "":
			Progress.set_flag(flag)
		return
	for e in get_tree().get_nodes_in_group("star_eyes"):
		var se := e as StarEye
		if se and se.result == result and not se.open:
			return
	Progress.set_flag(result)
	Sfx.play("puzzle_solved", -3.0, 0.0)


func _physics_process(delta: float) -> void:
	if not open or hold <= 0.0 or (result != "" and Progress.flag(result)):
		return
	_t += delta
	if _t >= hold:
		open = false
		_show(false)
		Sfx.play("ward_out", -8.0, 0.05, 1.6)
