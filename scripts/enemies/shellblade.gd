extends Enemy
## Shell Blade, after OoT's EnSb (z_en_sb.c): a big clam that hops toward the
## hero with its shell shut (blows just clang off it), then gapes open and
## lunges to bite. Only its soft inside can be hurt: strike while it is open,
## or knock it open and dazed with the boomerang.

enum State { IDLE, HOP, OPEN, BITE, CLOSE, STUNNED, HURT, DEAD }

@export var notice_range := 8.0

var state := State.IDLE
var _t := 0.0
var _hops := 0


func _ready() -> void:
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2


func is_open() -> bool:
	return state in [State.OPEN, State.BITE, State.STUNNED, State.HURT]


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.15)
			if alive and dist < notice_range and _t > 0.6:
				_go(State.HOP)
		State.HOP:
			if _t < 0.05:
				_turn_to(p.global_position if alive else global_position, 2000.0, 1.0)
				var step := minf(dist - 1.6, 1.6)
				velocity = _forward() * maxf(step, 0.0) / 0.4
				velocity.y = 4.0
			if _t > 0.15 and is_on_floor():
				_brake(delta, 30.0)
			if _t >= 0.55:
				if not alive or dist > notice_range * 1.5:
					_go(State.IDLE)
				elif dist < 2.2:
					_go(State.OPEN)
				else:
					_go(State.HOP)
		State.OPEN:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.5:
				_go(State.BITE)
		State.BITE:
			var lunge := _forward() * maxf(5.0 * (1.0 - _t / 0.25), 0.0)
			velocity.x = lunge.x
			velocity.z = lunge.z
			if attack_hitbox:
				if _t >= 0.03 and _t < 0.15 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.15:
					attack_hitbox.deactivate()
			if _t >= 0.4:
				_go(State.CLOSE)
		State.CLOSE:
			_brake(delta)
			if _t >= 0.6:
				_go(State.HOP)
		State.STUNNED:
			_brake(delta, 10.0)
			model.play(&"stunned", 0.05)
			if stun_left <= 0.0:
				_go(State.CLOSE)
		State.HURT:
			_brake(delta, 10.0)
			if _t >= 0.4:
				_go(State.CLOSE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.BITE:
		attack_hitbox.deactivate()
	match s:
		State.HOP:
			model.play(&"hop", 0.04, 1.0, true)
			Sfx.play("hop", -10.0, 0.05, 0.6)
		State.OPEN:
			model.play(&"open", 0.05, 1.0, true)
			Sfx.play("shell_clamp", -6.0, 0.05, 1.3)
		State.BITE:
			model.play(&"bite", 0.02, 1.0, true)
			Sfx.play("snap", -4.0, 0.05, 0.7)
		State.CLOSE:
			model.play(&"idle", 0.1)
		State.STUNNED:
			model.play(&"stunned", 0.05)


## Shut, the shell turns every blow.
func _guard(_info: HitInfo) -> int:
	if is_open():
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -4.0, 0.08, 1.3)
	return Hurtbox.Result.BLOCKED


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)
	model.play(&"stunned", 0.03)


func stun(seconds: float) -> void:
	super.stun(seconds)
	if not _dead:
		_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	super._die()
