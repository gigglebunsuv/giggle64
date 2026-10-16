extends "res://scripts/enemies/strawman.gd"
## A Scarecrow Archer of the Southern Tower: a strawman in a red coat that
## keeps its distance. It turns on its pole to face the hero, draws back its
## stick arm and flings a straw bolt; when he comes close it hops away. The
## shield turns its bolts (the Mirror Shield sends them straight back), and
## it burns like any strawman.

enum Shot { WAIT, AIM, THROW, RETREAT }

@export var shoot_range := 16.0
@export var keep_away := 4.5

var shot := Shot.WAIT
var _st := 0.0


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_st += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta)
		model.play(&"stunned", 0.1)
		_fall(delta)
		move_and_slide()
		return
	match shot:
		Shot.WAIT:
			_brake(delta)
			model.play(&"idle", 0.2)
			if alive and dist < shoot_range and _can_see_player(shoot_range):
				_turn_to(p.global_position, 200.0, delta)
				if dist < keep_away:
					_shoot_go(Shot.RETREAT)
				elif _st > 1.4:
					_shoot_go(Shot.AIM)
		Shot.AIM:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 160.0, delta)
			if _st >= 0.6:
				_shoot_go(Shot.THROW)
		Shot.THROW:
			_brake(delta)
			if _st >= 0.15 and _st - delta < 0.15:
				_fire()
			if _st >= 0.6:
				_shoot_go(Shot.WAIT)
		Shot.RETREAT:
			# Hop back away from the hero.
			var phase := fmod(_st, 0.5)
			var airborne := phase > 0.12 and phase < 0.45
			if alive:
				var away := -_flat_to(p.global_position).normalized()
				var v := away * (hop_speed * 1.2 if airborne else 0.0)
				velocity.x = v.x
				velocity.z = v.z
				_turn_to(p.global_position, 200.0, delta)
			model.play(&"hop", 0.1)
			if _st > 1.5 or is_on_wall() or dist > keep_away * 1.8:
				_shoot_go(Shot.WAIT)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _shoot_go(s: Shot) -> void:
	shot = s
	_st = 0.0
	match s:
		Shot.AIM:
			model.play(&"windup", 0.06, 1.0, true)
		Shot.THROW:
			model.play(&"spin", 0.02, 1.6, true)


func _fire() -> void:
	var bolt := Rock.new()
	bolt.mesh_path = "res://assets/models/straw_bolt_mesh.tres"
	bolt.spin = false
	get_parent().add_child(bolt)
	var p := _player()
	var dir := _forward()
	if p:
		dir = _flat_to(p.global_position).normalized()
	bolt.launch(global_position + Vector3.UP * 1.5 + dir * 0.6, dir, self)
	Sfx.play("bow_shoot", -6.0, 0.05, 0.8)
