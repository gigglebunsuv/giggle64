extends Enemy
## A cellar rat of the Southern Tower: small, quick and easily killed. It
## noses about until the hero comes near, then scurries straight at him, bites
## with a little leap, and scampers off to come round again. One cut or one
## arrow finishes it, and the boomerang knocks it out cold.

enum State { IDLE, SNIFF, RUSH, BITE, SCAMPER, STUNNED, DEAD }

@export var notice_range := 8.0
@export var rush_speed := 5.2

var state := State.IDLE
var _t := 0.0
var _wander := Vector3.ZERO


func _ready() -> void:
	corpse_time = 0.5
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 1
		attack_hitbox.knockback = 3.0


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
	# Only a hero on this floor counts: never the one a storey above or below.
	var noticed := alive and dist < notice_range and _can_see_player(notice_range * 1.5, 2.0)
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta, 10.0)
		model.play(&"stunned", 0.1)
		_fall(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if noticed:
				_go(State.RUSH)
			elif _t > 1.5:
				_wander = Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
				_go(State.SNIFF)
		State.SNIFF:
			# A little trot about, nose down.
			_turn_to(global_position + _wander, 360.0, delta)
			velocity.x = _forward().x * 1.4
			velocity.z = _forward().z * 1.4
			model.play(&"run", 0.1, 0.6)
			if noticed:
				_go(State.RUSH)
			elif _t > 0.8 or is_on_wall():
				_go(State.IDLE)
		State.RUSH:
			if not alive or dist > notice_range * 1.8 or absf(p.global_position.y - global_position.y) > 2.5:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 500.0, delta)
				velocity.x = _forward().x * rush_speed
				velocity.z = _forward().z * rush_speed
				model.play(&"run", 0.08, 1.4)
				if dist < 1.4:
					_go(State.BITE)
		State.BITE:
			# The leap forward with the teeth bared.
			var v := _forward() * maxf(4.0 * (1.0 - _t / 0.25), 0.0)
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.2 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.2:
					attack_hitbox.deactivate()
			if _t >= 0.35:
				_go(State.SCAMPER)
		State.SCAMPER:
			# Off to one side, then round for another go.
			if alive:
				var away := -_flat_to(p.global_position).normalized().rotated(Vector3.UP, 0.9)
				_turn_to(global_position + away, 600.0, delta)
			velocity.x = _forward().x * rush_speed * 0.8
			velocity.z = _forward().z * rush_speed * 0.8
			model.play(&"run", 0.08, 1.4)
			if _t > 0.9 or is_on_wall():
				_go(State.RUSH if alive else State.IDLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.BITE:
		attack_hitbox.deactivate()
	match s:
		State.BITE:
			model.play(&"bite", 0.03, 1.0, true)
			Sfx.play("rat_squeak", -6.0, 0.15)
		State.RUSH:
			if _rng.randf() < 0.5:
				Sfx.play("rat_squeak", -10.0, 0.2)


func _die() -> void:
	state = State.DEAD
	Sfx.play("rat_squeak", -4.0, 0.1, 1.3)
	super._die()
