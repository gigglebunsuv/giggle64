class_name BrittleCrust
extends StaticBody3D
## Brittle coral grown over a way through or a hidden corner. The sword, arrows
## and the boomerang only clang off it; something heavy thrown at it (a pot or
## a rock, see Throwable) shatters it and sets its Progress flag. It stays broken.

@export var flag := ""
## Its extent in meters (the mound mesh is stretched to fit: a wall of coral
## sealing a corner, or a lump over a chest).
@export var size := Vector3(1.6, 1.3, 1.4)

const MESH_SIZE := Vector3(1.6, 1.3, 1.4)

var broken := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/coral_crust_mesh.tres")
	mi.scale = size / MESH_SIZE
	add_child(mi)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(0, size.y * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hbox := BoxShape3D.new()
	hbox.size = size + Vector3(0.3, 0.2, 0.3)
	hcs.shape = hbox
	hcs.position = Vector3(0, size.y * 0.5, 0)
	hb.add_child(hcs)
	add_child(hb)


func take_hit(info: HitInfo) -> int:
	if broken:
		return Hurtbox.Result.IGNORED
	if not info.heavy:
		Sfx.play("shield_block", -6.0, 0.05, 0.8)
		return Hurtbox.Result.BLOCKED
	shatter()
	return Hurtbox.Result.HIT


func shatter() -> void:
	if broken:
		return
	broken = true
	Sfx.play("rock_break", -2.0)
	for i in 3:
		var at := global_position + global_basis.x * (i - 1) * size.x * 0.3 + Vector3.UP * size.y * (0.3 + 0.2 * i)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), at, 14, 3.0, 4.0, 1.0, 1.6, Color(1.4, 0.75, 0.7))
	if flag != "":
		Progress.set_flag(flag)
	queue_free()
