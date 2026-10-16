extends Enemy
## A Mummy of Ladhellin Tower, after OoT's Gibdo (EnRd): a sun-priest wrapped
## in old linen, standing still as a statue until the hero comes near. Then
## it shambles after him, slowly; close in, it raises its arms and lunges to
## clutch at him. Its wrappings are dry as tinder: a burning arrow sets it
## ablaze, and the flames do far more than the sword.

enum State { IDLE, SHAMBLE, REACH, GRAB, RECOVER, STUNNED, DEAD }

@export var notice_range := 7.0
@export var walk_speed := 1.1
@export var reach_time := 0.75

var state := State.IDLE
var _t := 0.0
var _groan := 0.0


func _ready() -> void:
	corpse_time = 1.0
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 5.0


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta, 10.0)
		model.play(&"stunned", 0.1)
		if attack_hitbox:
			attack_hitbox.deactivate()
		_fall(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if alive and dist < notice_range and _can_see_player(notice_range):
				Sfx.play("mummy_moan", -4.0, 0.1)
				_go(State.SHAMBLE)
		State.SHAMBLE:
			if not alive or dist > notice_range * 2.0:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 120.0, delta)
				velocity.x = _forward().x * walk_speed
				velocity.z = _forward().z * walk_speed
				model.play(&"walk", 0.15)
				_groan -= delta
				if _groan <= 0.0:
					_groan = _rng.randf_range(3.0, 6.0)
					Sfx.play("mummy_moan", -10.0, 0.15)
				if dist < 1.7:
					_go(State.REACH)
		State.REACH:
			# Arms up; it only turns over the first part of the reach.
			_brake(delta)
			if alive and _t < reach_time * 0.35:
				_turn_to(p.global_position, 150.0, delta)
			if _t >= reach_time:
				_go(State.GRAB)
		State.GRAB:
			var v := _forward() * maxf(2.6 * (1.0 - _t / 0.3), 0.0)
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.25 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.25:
					attack_hitbox.deactivate()
			if _t >= 0.4:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= 1.1:
				_go(State.SHAMBLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.GRAB:
		attack_hitbox.deactivate()
	match s:
		State.REACH:
			model.play(&"reach", 0.08, 1.0, true)
		State.GRAB:
			model.play(&"grab", 0.03, 1.0, true)
			Sfx.play("mummy_moan", -2.0, 0.05, 1.2)
		State.RECOVER:
			model.play(&"idle", 0.2)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	if state == State.IDLE:
		_go(State.SHAMBLE)


## A burning arrow (Arrow.burning): the dry linen goes up.
func burn() -> void:
	if _dead:
		return
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.4, 12, 2.0, 3.0, 1.2, 1.0, Color(1.8, 0.8, 0.2))
	Sfx.play("torch_light", -2.0)
	health.apply_damage(4)
	stun(1.2)


func _die() -> void:
	state = State.DEAD
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.0, 10, 2.5, 3.5, 1.4, 1.0, Color(0.95, 0.9, 0.75))
	Sfx.play("mummy_moan", -2.0, 0.05, 0.7)
	super._die()
