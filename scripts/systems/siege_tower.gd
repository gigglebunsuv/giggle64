class_name SiegeTower
extends StaticBody3D
## A goblin siege tower rolling on Haven's palisade (the Siege of Haven): it
## creaks forward from the field toward `dock` (a point by the wall). Three
## ballista bolts break it apart. If it reaches the wall its drawbridge
## crashes down and goblins pour over (it keeps pressing the wall until it is
## broken).

signal destroyed
signal docked

const HP := 3
const SPEED := 1.4

var dock := Vector3.ZERO
var side := ""
var hp := HP
var at_wall := false
var _mesh: MeshInstance3D
var _dead := false
var _poured := 0
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("siege_towers")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 7.4, 3.2)
	cs.shape = box
	cs.position = Vector3(0, 3.7, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = load("res://assets/models/siege_tower_mesh.tres") if ResourceLoader.exists("res://assets/models/siege_tower_mesh.tres") else null
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	if not at_wall:
		var to := dock - global_position
		to.y = 0.0
		if to.length() < 0.3:
			at_wall = true
			Sfx.play("wood_crash", 0.0, 0.0, 0.8)
			docked.emit()
			_t = 0.0
			return
		global_position += to.normalized() * minf(SPEED * delta, to.length())
		rotation.y = atan2(-to.x, -to.z)
		_mesh.rotation.z = sin(_t * 3.0) * 0.015
		if fmod(_t, 2.2) < delta:
			Sfx.play("wood_crash", -16.0, 0.1, 0.5)
		return
	# At the wall: a goblin over the drawbridge every few seconds.
	if _t >= 3.5 and _poured < 6:
		_t = 0.0
		_poured += 1
		var e := (load("res://scenes/enemies/basic_enemy.tscn") as PackedScene).instantiate() as Enemy
		e.drop_table = 1
		e.tint = Color(1.1, 0.85, 0.8)
		e.set_meta("siege", side)
		get_parent().add_child(e)
		e.global_position = global_transform * Vector3(0, 3.6, -3.2)


## A ballista bolt struck it.
func bolt_hit() -> void:
	if _dead:
		return
	hp -= 1
	Sfx.play("wood_crash", 0.0, 0.05, 1.0)
	Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3(0, 4.0, 0), 12, 4.0, 4.0, 0.8, 1.0, Color(0.5, 0.36, 0.24))
	if hp <= 0:
		_break()


func _break() -> void:
	_dead = true
	collision_layer = 0
	destroyed.emit()
	Sfx.play("wood_crash", 3.0, 0.0, 0.6)
	var t := create_tween()
	t.tween_property(self, "rotation:x", 1.4, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "position:y", position.y - 4.0, 1.0)
	t.tween_callback(queue_free)


func is_broken() -> bool:
	return _dead
