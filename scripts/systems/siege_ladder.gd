class_name SiegeLadder
extends Node3D
## A goblin scaling ladder thrown up against Haven's palisade (the Siege of
## Haven). Its foot stands outside the wall (this node, facing the wall along
## -Z); its iron hooks bite over the top, and a knotted rope hangs down the
## inside. While it stands, a goblin comes over every CLIMB_EVERY seconds
## (no more than MAX_UP of its own alive at once). Cut the rope or knock the
## hooks off (a sword or mallet blow on the inside, the Hurtbox there) and
## the ladder topples back over the wall.

signal toppled

const CLIMB_EVERY := 4.5
const MAX_UP := 2
## The wall's thickness and height (the region's palisade).
const WALL_T := 0.8
const WALL_H := 3.4

var side := ""
var standing := true
var _t := 0.0
var _up: Array[Node] = []
var _pivot: Node3D
var _hurt: Hurtbox


func _ready() -> void:
	add_to_group("siege_ladders")
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var mi := MeshInstance3D.new()
	mi.mesh = load("res://assets/models/siege_ladder_mesh.tres") if ResourceLoader.exists("res://assets/models/siege_ladder_mesh.tres") else null
	_pivot.add_child(mi)
	# Leaning in at the wall: the foot 1.6 m out, the hooks over the top.
	_pivot.rotation.x = -atan2(1.6, WALL_H + 0.4)
	position.z += 1.6
	# The rope down the inside and the knock-off point (a hurtbox the hero's
	# sword can reach from the ground inside).
	var rope := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.04
	cm.height = WALL_H
	rope.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.6, 0.42)
	rope.material_override = mat
	rope.name = "Rope"
	rope.position = Vector3(0, WALL_H * 0.5, -1.6 - WALL_T - 0.15)
	add_child(rope)
	_hurt = Hurtbox.new()
	_hurt.name = "Hurtbox"
	_hurt.collision_layer = 16
	_hurt.collision_mask = 0
	_hurt.receiver = self
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.6, 0.8)
	cs.shape = box
	_hurt.add_child(cs)
	_hurt.position = Vector3(0, 1.4, -1.6 - WALL_T - 0.4)
	add_child(_hurt)
	Sfx.play("wood_crash", -6.0, 0.05, 1.4)


func is_targetable() -> bool:
	return false


## A blow on the rope or hooks from inside: over it goes.
func take_hit(_info: HitInfo) -> int:
	if not standing:
		return Hurtbox.Result.IGNORED
	topple()
	return Hurtbox.Result.HIT


func topple() -> void:
	if not standing:
		return
	standing = false
	_hurt.set_deferred("monitorable", false)
	_hurt.set_deferred("collision_layer", 0)
	Sfx.play("wood_crash", -2.0, 0.05, 1.1)
	toppled.emit()
	var t := create_tween()
	t.tween_property(_pivot, "rotation:x", 1.2, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var rope := get_node_or_null("Rope") as Node3D
	if rope:
		rope.visible = false
	t.tween_property(self, "position:y", position.y - 3.0, 0.6)
	t.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if not standing:
		return
	_t += delta
	_up = _up.filter(func(e: Node) -> bool: return is_instance_valid(e) and e.is_in_group("enemies"))
	if _t >= CLIMB_EVERY and _up.size() < MAX_UP:
		_t = 0.0
		_climb_over()


## A goblin heaves itself over the top and drops down inside.
func _climb_over() -> void:
	var e := (load("res://scenes/enemies/basic_enemy.tscn") as PackedScene).instantiate() as Enemy
	e.drop_table = 1
	e.tint = Color(1.1, 0.85, 0.8)
	e.set_meta("siege", side)
	get_parent().add_child(e)
	e.global_position = global_transform * Vector3(0, WALL_H + 0.2, -1.6 - WALL_T - 1.0)
	e.facing_yaw = rotation.y + PI
	e.rotation.y = e.facing_yaw
	_up.append(e)
	Sfx.play("enemy_alert", -4.0, 0.08)
