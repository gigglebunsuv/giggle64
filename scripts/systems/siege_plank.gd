extends Node3D
## A loose plank on the inside of Haven's gate (SiegeGate): sticking out
## askew while the gate is damaged; a blow of the Iron Mallet drives it home
## and mends the gate (group "mallet_targets", PlayerItems._mallet_blow).

var gate: Node3D
var loose := false
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.3, 0.12)
	_mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.26)
	_mesh.material_override = mat
	add_child(_mesh)
	set_loose(false)


func set_loose(on: bool) -> void:
	loose = on
	if on:
		add_to_group("mallet_targets")
	else:
		remove_from_group("mallet_targets")
	if _mesh:
		_mesh.rotation = Vector3(0.3, 0.2, 0.35) if on else Vector3.ZERO
		_mesh.position = Vector3(0, 0, 0.18) if on else Vector3.ZERO


func mallet_hit(_by: Node3D) -> void:
	if not loose or gate == null:
		return
	gate.call("mend")
