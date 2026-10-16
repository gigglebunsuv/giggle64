class_name BombWall
extends StaticBody3D
## A cracked wall or a cracked boulder (OoT's Bg_Breakwall and the bombable
## boulders, Obj_Bombiwa): blades, arrows and thrown pots only knock on it; a
## bomb's blast shatters it, sets its Progress flag and plays the discovery
## chime. It stays broken. `boulder` picks the round cave-plugging rock.

@export var flag := ""
@export var boulder := false

const WALL_SIZE := Vector3(3.0, 3.4, 0.6)
const BOULDER_SIZE := Vector3(3.0, 2.7, 2.4)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	add_to_group("bombables")
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/%s.tres" % ("bomb_boulder_mesh" if boulder else "cracked_wall_mesh"))
	add_child(mi)
	var size := BOULDER_SIZE if boulder else WALL_SIZE
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(0, size.y * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	add_child(cs)


func bomb_reach() -> float:
	return 2.0 if boulder else 1.8


func bomb_hit(_from: Vector3) -> void:
	if flag != "":
		Progress.set_flag(flag)
	var parent := get_parent()
	var at := global_position + Vector3.UP * 1.4
	Sfx.play("rock_break", 0.0, 0.05, 0.8)
	Sfx.play("puzzle_solved", -3.0, 0.0)
	Fragments.burst(parent, load("res://assets/models/rock_chip_mesh.tres"), at, 22, 4.5, 6.0, 1.3, 2.2, Color(0.75, 0.72, 0.68))
	queue_free()
