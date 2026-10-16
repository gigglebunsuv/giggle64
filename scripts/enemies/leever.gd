extends Enemy
## Leever, after OoT's EnReeba (z_en_reeba.c): it lies buried in the sand.
## When the hero comes within range it burrows to a spot just ahead of him,
## bursts up spinning (EnReeba_Surface) and chases him for a few seconds
## (EnReeba_Move), hurting on contact, then sinks back into the sand
## (EnReeba_Bury) to try again.

enum State { BURIED, TUNNEL, RISE, CHASE, SINK, HURT, STUNNED, DEAD }

@export var notice_range := 12.0
## Chasing speed in m/s.
@export var chase_speed := 3.4
@export var chase_time := 5.0

var state := State.BURIED
var _t := 0.0
var _wait := 0.0
var _spin := 0.0


func _ready() -> void:
	super._ready()
	_bury(true)
	_wait = _rng.randf_range(0.0, 1.5)


func is_targetable() -> bool:
	return super.is_targetable() and state in [State.CHASE, State.HURT, State.STUNNED, State.RISE]


func _physics_process(delta: float) -> void:
	if _dead:
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	match state:
		State.BURIED:
			velocity = Vector3.ZERO
			if alive and _t > _wait and _flat_dist(p.global_position) < notice_range:
				_go(State.TUNNEL)
		State.TUNNEL:
			# Travel unseen to a few meters ahead of the hero.
			var spot := p.global_position + p.forward() * 3.0 if alive else _home
			var to := _flat_to(spot)
			velocity = to.limit_length(9.0)
			velocity.y = 0.0
			if to.length() < 0.4 or _t > 1.2:
				velocity = Vector3.ZERO
				_bury(false)
				_go(State.RISE)
				model.play(&"rise", 0.02, 1.0, true)
				Sfx.play("step_sand_0", -2.0, 0.05, 0.6)
				Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.2, 8, 2.0, 3.5, 0.8, 1.2, Color(1.3, 1.1, 0.7))
		State.RISE:
			velocity = Vector3.ZERO
			_spin += 20.0 * delta * (_t / 0.5)
			if _t >= 0.5:
				_go(State.CHASE)
				model.play(&"idle", 0.1)
				if attack_hitbox:
					attack_hitbox.activate()
		State.CHASE:
			_spin += 20.0 * delta
			if alive:
				var to := _flat_to(p.global_position)
				var want := to.normalized() * chase_speed
				velocity.x = move_toward(velocity.x, want.x, 8.0 * delta)
				velocity.z = move_toward(velocity.z, want.z, 8.0 * delta)
				facing_yaw = _yaw_to(p.global_position)
			if _t >= chase_time or not alive:
				_go(State.SINK)
				model.play(&"sink", 0.05, 1.0, true)
		State.SINK:
			_brake(delta)
			_spin += 10.0 * delta
			if _t >= 0.6:
				_bury(true)
				_wait = _rng.randf_range(1.5, 3.0)
				_go(State.BURIED)
		State.HURT:
			_brake(delta, 6.0)
			_spin += 6.0 * delta
			if _t >= 0.4:
				_go(State.CHASE)
				if attack_hitbox:
					attack_hitbox.activate()
		State.STUNNED:
			_brake(delta, 10.0)
			model.play(&"stunned", 0.05)
			if stun_left <= 0.0:
				_go(State.CHASE)
				model.play(&"idle", 0.1)
				if attack_hitbox:
					attack_hitbox.activate()
	_fall(delta)
	move_and_slide()
	rotation.y = 0.0
	if model:
		model.rotation.y = _spin


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.CHASE:
		attack_hitbox.deactivate()


func _bury(b: bool) -> void:
	_set_hurtbox(not b)
	collision_layer = 0 if b else 4
	collision_mask = 1 if b else 7
	var shadow := get_node_or_null("BlobShadow") as Node3D
	if shadow:
		shadow.visible = not b
	if b and model:
		model.play(&"buried", 0.0, 1.0, true)


func _on_attack_landed(_hb: Hurtbox, _result: int) -> void:
	# One bite per pass: back off a moment before biting again.
	velocity = -_forward() * 3.0
	_go(State.HURT)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)


func stun(seconds: float) -> void:
	if _dead or state in [State.BURIED, State.TUNNEL]:
		return
	super.stun(seconds)
	_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	super._die()
