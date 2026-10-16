extends Enemy
## A Cinderling (Chapter V): a slug of living magma from the slopes and
## forges of Cinderhold, as long as a dog, its black crust cracked with fire.
## It oozes about until the hero comes near, then hunches up and flings
## itself at him, burning what it touches, and oozes off to cool. Made of
## fire, it shrugs off the Ember Rod; a Frost Arrow crusts it solid (and the
## next blow shatters it); a sword cut splatters it.

enum State { IDLE, OOZE, CHASE, HUNCH, LUNGE, COOL, DEAD }

@export var notice_range := 9.0
@export var chase_speed := 2.0

var state := State.IDLE
var _t := 0.0
var _wander := Vector3.ZERO
var _glow: OmniLight3D


func _ready() -> void:
	corpse_time = 0.6
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 5.0
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.5, 0.2)
	_glow.light_energy = 1.0
	_glow.omni_range = 3.0
	_glow.position = Vector3(0, 0.5, 0)
	add_child(_glow)


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	_glow.light_energy = 0.9 + sin(_t * 5.0) * 0.25
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	var noticed := alive and dist < notice_range and absf(p.global_position.y - global_position.y) < 2.5
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta, 10.0)
		model.play(&"idle", 0.1, 0.3)
		_fall(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if noticed:
				_go(State.CHASE)
			elif _t > 2.0:
				_wander = Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
				_go(State.OOZE)
		State.OOZE:
			_turn_to(global_position + _wander, 120.0, delta)
			velocity.x = _forward().x * 0.8
			velocity.z = _forward().z * 0.8
			model.play(&"walk", 0.2, 0.6)
			if noticed:
				_go(State.CHASE)
			elif _t > 1.6 or is_on_wall():
				_go(State.IDLE)
		State.CHASE:
			if not noticed and dist > notice_range * 1.6:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 160.0, delta)
				velocity.x = _forward().x * chase_speed
				velocity.z = _forward().z * chase_speed
				model.play(&"walk", 0.15, 1.0)
				if dist < 3.2:
					_go(State.HUNCH)
		State.HUNCH:
			_brake(delta, 10.0)
			if p:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.55:
				_go(State.LUNGE)
		State.LUNGE:
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.4 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.4:
					attack_hitbox.deactivate()
			if _t > 0.2 and is_on_floor():
				_brake(delta, 12.0)
			if _t >= 0.7:
				_go(State.COOL)
		State.COOL:
			_brake(delta, 8.0)
			model.play(&"idle", 0.2, 0.5)
			if _t >= 1.4:
				_go(State.CHASE if noticed else State.IDLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.LUNGE:
		attack_hitbox.deactivate()
	match s:
		State.HUNCH:
			model.play(&"attack", 0.08, 0.6, true)
			Sfx.play("lava_bubble", -6.0, 0.1)
		State.LUNGE:
			velocity = _forward() * 6.0
			velocity.y = 4.0
			Sfx.play("fire_whoosh", -8.0, 0.1, 1.4)


## Fire does nothing to fire.
func can_freeze() -> bool:
	return true


func _die() -> void:
	state = State.DEAD
	Sfx.play("lava_bubble", -2.0, 0.1, 1.3)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.3, 12, 3.0, 3.5, 0.6, 0.7, Color(1.8, 0.7, 0.25))
	_glow.light_energy = 0.0
	super._die()
