class_name SiegeGate
extends StaticBody3D
## Haven Village's north gate in the Siege of Haven (Chapter IV): two timber
## leaves barred across the gatehouse. While the siege runs (`shut`) it is
## solid, and every war boar that rams it batters it (`ram`); at 0 it gives
## way and the wave is lost. Between waves three loose planks on its inside
## face can be hammered home with the Iron Mallet (each mends 4).
## Out of the siege the leaves stand open against the walls.

signal broken

const MAX_HP := 12
const PLANK_MEND := 4

@export var width := 7.0
@export var height := 5.6

var hp := MAX_HP
var shut := false
var _shape: CollisionShape3D
var _leaves: Array[Node3D] = []
var _planks: Array[Node3D] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	add_to_group("siege_gates")
	_shape = CollisionShape3D.new()
	_shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, 0.7)
	_shape.shape = box
	_shape.position = Vector3(0, height * 0.5, 0)
	_shape.set_meta("no_climb", true)
	_shape.disabled = true
	add_child(_shape)
	for sx in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.name = "Leaf%s" % ("L" if sx < 0 else "R")
		hinge.position = Vector3(sx * width * 0.5, 0, 0)
		add_child(hinge)
		var mk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(width * 0.5, height, 0.35)
		mk.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.3, 0.2)
		mk.material_override = mat
		mk.position = Vector3(-sx * width * 0.25, height * 0.5, 0)
		hinge.add_child(mk)
		# Iron bands across the leaf.
		for y in [0.8, height - 0.8]:
			var band := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(width * 0.5, 0.18, 0.4)
			band.mesh = bb
			var bmat := StandardMaterial3D.new()
			bmat.albedo_color = Color(0.25, 0.25, 0.28)
			band.material_override = bmat
			band.position = Vector3(-sx * width * 0.25, y, 0)
			hinge.add_child(band)
		_leaves.append(hinge)
	for i in 3:
		var plank := Node3D.new()
		plank.name = "Plank%d" % i
		plank.set_script(load("res://scripts/systems/siege_plank.gd"))
		plank.set("gate", self)
		plank.position = Vector3(-2.0 + i * 2.0, 1.2, 0.45)
		add_child(plank)
		_planks.append(plank)
	set_shut(false)


func set_shut(on: bool) -> void:
	shut = on
	collision_layer = 1 if on else 0
	_shape.set_deferred("disabled", not on)
	for i in _leaves.size():
		var sx := -1.0 if i == 0 else 1.0
		var t := create_tween()
		t.tween_property(_leaves[i], "rotation:y", 0.0 if on else sx * -1.7, 0.8)
	_refresh_planks()


func ram(amount := 1) -> void:
	if not shut or hp <= 0:
		return
	hp = maxi(hp - amount * 2, 0)
	GameManager.rumble(0.6, 0.25)
	var p := GameManager.player
	if p and p.camera_rig and p.global_position.distance_to(global_position) < 25.0:
		p.camera_rig.shake(0.12, 0.3)
	Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3(0, 2.0, -0.6), 8, 3.0, 3.0, 0.6, 0.8, Color(0.5, 0.36, 0.24))
	_refresh_planks()
	if hp <= 0:
		Sfx.play("wood_crash", 2.0, 0.0, 0.7)
		broken.emit()


## A plank hammered home.
func mend() -> void:
	hp = mini(hp + PLANK_MEND, MAX_HP)
	Sfx.play("anvil", -4.0, 0.05, 0.8)
	_refresh_planks()


func reset_hp(to := MAX_HP) -> void:
	hp = to
	_refresh_planks()


## The loose planks stand out while there is damage to mend.
func _refresh_planks() -> void:
	var missing := ceili(float(MAX_HP - hp) / PLANK_MEND)
	for i in _planks.size():
		_planks[i].call("set_loose", shut and i < missing)
