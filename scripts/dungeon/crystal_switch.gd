class_name CrystalSwitch
extends StaticBody3D
## A crystal switch on a stone stand (OoT's Obj_Switch, crystal type): red
## until struck by the sword, an arrow or the boomerang, then blue, and it sets
## its Progress flag (doors, bridges and chests wait on it). It stays on.

@export var flag := ""

var on := false
var _crystal: MeshInstance3D
var _mat: StandardMaterial3D
var _spin := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("switches")
	var base := MeshInstance3D.new()
	base.mesh = load("res://assets/models/crystal_base_mesh.tres")
	add_child(base)
	_crystal = MeshInstance3D.new()
	_crystal.name = "Crystal"
	_crystal.mesh = load("res://assets/models/crystal_mesh.tres")
	_crystal.position = Vector3(0, 0.45, 0)
	add_child(_crystal)
	_mat = (_crystal.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_crystal.material_override = _mat
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 1.35
	cs.shape = cyl
	cs.position = Vector3(0, 0.67, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hs := SphereShape3D.new()
	hs.radius = 0.5
	hcs.shape = hs
	hcs.position = Vector3(0, 0.9, 0)
	hb.add_child(hcs)
	add_child(hb)
	on = flag != "" and Progress.flag(flag)
	_colour()


func _colour() -> void:
	_mat.albedo_color = Color(0.45, 0.7, 1.6) if on else Color(1.6, 0.35, 0.3)


func take_hit(info: HitInfo) -> int:
	if info.attacker is PlayerController:
		activate()
	return Hurtbox.Result.HIT


func arrow_hit(_arrow: Node3D, _point: Vector3) -> void:
	activate()


func boomerang_hit(_b: Node3D) -> void:
	activate()


func activate() -> void:
	Sfx.play("crystal_hit", -3.0, 0.0)
	if on:
		return
	on = true
	_colour()
	if flag != "":
		Progress.set_flag(flag)


func _process(delta: float) -> void:
	_spin += delta * (2.0 if on else 0.6)
	_crystal.rotation.y = _spin
