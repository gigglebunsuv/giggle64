class_name Lift
extends AnimatableBody3D
## A stone platform that carries the hero between two stops: where it was
## placed and `travel` away (OoT's dungeon elevators, Bg_*_Elevator). It sets
## off a moment after he steps on, and when he waits beside the far stop it
## comes to fetch him. With `loop` it shuttles back and forth on its own (the
## Southern Tower's gear-driven platforms).
##
## Its MeshInstance3D and CollisionShape3D are children; the top face is at the
## node's origin.

@export var travel := Vector3(0, 8, 0)
## Meters per second at full speed.
@export var speed := 2.5
@export var loop := false
## Seconds it rests at each stop while looping.
@export var rest := 1.2
## The lift only works once this flag is set ("" = always).
@export var flag := ""

## 0 = at the placed stop, 1 = at the far stop.
var at := 0
var moving := false
var _home := Vector3.ZERO
var _ride_time := 0.0
var _rest_time := 0.0
var _half := Vector2(1.5, 1.5)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	add_to_group("lifts")
	_home = position
	for c in get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			var s: Vector3 = ((c as CollisionShape3D).shape as BoxShape3D).size
			_half = Vector2(s.x, s.z) * 0.5


func active() -> bool:
	return flag == "" or Progress.flag(flag)


func stop_position(i: int) -> Vector3:
	return _home + travel * float(i)


## The hero stands on the top face.
func carrying(p: Node3D) -> bool:
	if p == null or not (p as CharacterBody3D).is_on_floor():
		return false
	var local := p.global_position - global_position
	return absf(local.x) <= _half.x + 0.2 and absf(local.z) <= _half.y + 0.2 and absf(local.y) < 0.4


func _physics_process(delta: float) -> void:
	if moving or not active():
		return
	if loop:
		_rest_time += delta
		if _rest_time >= rest:
			_go(1 - at)
		return
	var p := GameManager.player
	if not is_instance_valid(p) or p.is_dead():
		return
	if carrying(p):
		_ride_time += delta
		if _ride_time >= 0.4:
			_go(1 - at)
		return
	_ride_time = 0.0
	# Waiting by the other stop: come and fetch him.
	var other: Vector3 = stop_position(1 - at) + (get_parent() as Node3D).global_position
	var flat := Vector2(p.global_position.x - other.x, p.global_position.z - other.z)
	if absf(p.global_position.y - other.y) < 1.2 and flat.length() < maxf(_half.x, _half.y) + 3.0:
		_go(1 - at)


func _go(stop: int) -> void:
	moving = true
	_rest_time = 0.0
	_ride_time = 0.0
	var to := stop_position(stop)
	var time := maxf(position.distance_to(to) / speed, 0.3)
	Sfx.play("shutter_open", -10.0, 0.05, 0.7)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "position", to, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func() -> void:
		at = stop
		moving = false)
