class_name Burnable
extends StaticBody3D
## Something the Ember Rod's fire gets rid of (Chapter V):
## - "thorns": a wall of black thorns across a way (it burns away),
## - "web": a sheet of old web across a doorway (it shrivels up in a flash),
## - "rime": a block of rime-ice, frozen hard (no blade or hammer marks it;
##   the fire melts it to a puddle of steam).
## Gone, it sets `flag` and stays gone. `size` is its box (centered over its
## foot); the mesh is "<kind>_mesh" from tools/gen_ch5_items.gd, scaled to fit.

@export var kind := "thorns"
@export var flag := ""
@export var size := Vector3(3.0, 2.6, 0.8)

var burning := false
var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	add_to_group("burnables")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	var path := "res://assets/models/%s_mesh.tres" % kind
	if ResourceLoader.exists(path):
		_mesh.mesh = load(path)
	# The meshes are made 1 m to a side; stretched to the box.
	_mesh.scale = size
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(0, size.y * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "ice" if kind == "rime" else "wood")
	add_child(cs)


## How close a fireball must come (its center to this foot).
func burn_reach() -> float:
	return maxf(size.x, size.y) * 0.6 + 0.4


## The sword just bounces off (thorns tangle it, ice rings).
func is_blade_proof() -> bool:
	return true


func ember_hit(_by: Node3D) -> void:
	if burning:
		return
	burning = true
	remove_from_group("burnables")
	if flag != "":
		Progress.set_flag(flag)
	var shape := get_node_or_null("Shape") as CollisionShape3D
	if shape:
		shape.set_deferred("disabled", true)
	var top := global_position + Vector3.UP * size.y * 0.5
	if kind == "rime":
		Sfx.play("sizzle", 0.0, 0.05)
		SpellEffect.make(get_parent(), "steam", global_position)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), top, 12, 2.0, 3.0, 0.6, 0.8, Color(0.8, 0.92, 1.0))
	else:
		Sfx.play("fire_whoosh", 0.0, 0.05, 0.8)
		var fire := Node3D.new()
		fire.set_script(load("res://scripts/systems/torch_flicker.gd"))
		get_parent().add_child(fire)
		fire.global_position = global_position
		var fm := MeshInstance3D.new()
		fm.mesh = load("res://assets/models/flame_mesh.tres")
		fm.scale = Vector3(size.x, size.y, maxf(size.z, 1.0)) * 0.9
		fire.add_child(fm)
		var tw0 := fire.create_tween()
		tw0.tween_interval(0.9)
		tw0.tween_property(fire, "scale", Vector3.ONE * 0.05, 0.4)
		tw0.tween_callback(fire.queue_free)
		Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), top, 14, 3.0, 3.0, 0.8, 0.9, Color(0.2, 0.12, 0.08))
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3(size.x, 0.05, size.z), 0.9 if kind == "rime" else 0.7).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: Sfx.play("puzzle_solved", -4.0))
	tw.tween_callback(queue_free)
