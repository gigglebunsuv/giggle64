class_name MalletStake
extends StaticBody3D
## A wooden stake capped with iron, after OoT's Megaton Hammer posts: one blow
## of the Iron Mallet (PlayerItems' "mallet_targets") drives it into the ground
## and sets `flag` (bars lift, a bridge drops...). Driven stakes stay down.
## A `brittle` target is a sheet of ice (the frozen falls) that shatters
## instead, opening the way behind it.

@export var flag := ""
@export var brittle := false
## The sheet's size, for its collision (brittle only).
@export var size := Vector3(4.0, 5.0, 0.6)

var driven := false
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("mallet_targets")
	collision_layer = 1
	collision_mask = 0
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/%s.tres" % ("ice_sheet_mesh" if brittle else "mallet_stake_mesh"))
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size if brittle else Vector3(0.36, 0.72, 0.36)
	cs.shape = box
	cs.position = Vector3(0, box.size.y * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "ice" if brittle else "wood")
	add_child(cs)
	if flag != "" and Progress.flag(flag):
		_settle()


func _settle() -> void:
	driven = true
	remove_from_group("mallet_targets")
	if brittle:
		queue_free()
	else:
		_mesh.position.y = -0.62
		collision_layer = 0


func mallet_hit(_by: Node3D) -> void:
	if driven:
		return
	driven = true
	remove_from_group("mallet_targets")
	if flag != "":
		Progress.set_flag(flag)
	if brittle:
		Sfx.play("ice_shatter", 0.0, 0.05)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 2.0, 24, 4.0, 5.0, 1.2, 1.6, Color(0.8, 0.92, 1.0))
		Sfx.play("puzzle_solved", -4.0)
		queue_free()
		return
	Sfx.play("puzzle_solved", -4.0)
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(_mesh, "position:y", -0.62, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## The Ember Rod's fire melts a sheet of ice as surely as the mallet breaks it.
func ember_hit(_by: Node3D) -> void:
	if not brittle or driven:
		return
	Sfx.play("sizzle", 0.0, 0.05)
	SpellEffect.make(get_parent(), "steam", global_position + Vector3.UP * 1.0)
	mallet_hit(_by)
