class_name ShadowWolf
extends Enemy
## A shadow wolf of the Dark Forest (Chapter IV, after OoT's Wolfos): it
## circles the hero just out of reach, waiting for his back, then lunges.
## Struck from the front it leaps aside; it howls to the others nearby, and
## the Starlight Lantern's light makes it shy.

enum State { IDLE, CIRCLE, LUNGE, RECOVER, DODGE, HURT, DEAD }

@export var notice_range := 14.0
@export var circle_range := 4.0

var state := State.IDLE
var _t := 0.0
var _side := 1.0
var _plan := 2.0
var _shy := 0.0


func _ready() -> void:
	corpse_time = 1.2
	super._ready()
	_side = 1.0 if randf() < 0.5 else -1.0
	if attack_hitbox:
		attack_hitbox.damage = 1
		attack_hitbox.knockback = 5.0


## The Starlight Lantern's light (PlayerItems._starlight_reveal).
func light_hit(delta: float, _from: Vector3) -> void:
	_shy = minf(_shy + delta * 2.0, 2.0)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_shy = maxf(_shy - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta)
		model.play(&"stunned", 0.1)
		_fall(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if alive and dist < notice_range * Progress.stealth():
				Sfx.play("night_howl", -10.0, 0.1, 1.5)
				_go(State.CIRCLE)
		State.CIRCLE:
			if not alive:
				_go(State.IDLE)
			else:
				var to := _flat_to(p.global_position)
				var want := circle_range + _shy * 2.0
				var radial := to.normalized() * (to.length() - want) * 1.5
				var tangent := Vector3(-to.z, 0, to.x).normalized() * 3.2 * _side
				var v := (radial + tangent).limit_length(5.5)
				velocity.x = v.x
				velocity.z = v.z
				facing_yaw = atan2(-v.x, -v.z) if v.length() > 0.5 else facing_yaw
				model.play(&"run", 0.15)
				# It lunges when behind or beside him, or when its patience runs out.
				var behind := p.forward().dot(-to.normalized()) < 0.2
				if _shy <= 0.1 and dist < want + 1.0 and (behind or _t > _plan):
					_go(State.LUNGE)
		State.LUNGE:
			if _t < 0.05 and p:
				_turn_to(p.global_position, 2000.0, delta)
			var v := _forward() * (9.0 if _t < 0.35 else 1.0)
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox:
				if _t < 0.35 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.35:
					attack_hitbox.deactivate()
			if _t >= 0.5:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.5:
				_side = -_side
				_plan = randf_range(1.6, 3.0)
				_go(State.CIRCLE)
		State.DODGE:
			if _t < 0.3:
				var p2 := _player()
				var away := Vector3.ZERO
				if p2:
					var to := _flat_to(p2.global_position).normalized()
					away = Vector3(-to.z, 0, to.x) * _side * 7.0 - to * 2.0
				velocity.x = away.x
				velocity.z = away.z
			else:
				_brake(delta, 20.0)
			if _t >= 0.5:
				_go(State.CIRCLE)
		State.HURT:
			_brake(delta)
			if _t >= 0.35:
				_go(State.CIRCLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.LUNGE:
		attack_hitbox.deactivate()
	match s:
		State.LUNGE:
			model.play(&"lunge", 0.04, 1.0, true)
			Sfx.play("snap", -4.0, 0.08, 0.7)
		State.DODGE:
			model.play(&"run", 0.05, 1.6)
			Sfx.play("hop", -8.0, 0.08, 0.9)
		State.HURT:
			model.play(&"hurt", 0.02, 1.0, true)


## Struck at from the front while circling, it leaps aside.
func _guard(info: HitInfo) -> int:
	if info.bomb or info.reflected:
		return Hurtbox.Result.HIT
	if state == State.CIRCLE and _flat_to(info.source_position).normalized().dot(_forward()) > 0.4 and randf() < 0.6:
		_go(State.DODGE)
		return Hurtbox.Result.IGNORED
	return Hurtbox.Result.HIT


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)


func _die() -> void:
	state = State.DEAD
	super._die()
