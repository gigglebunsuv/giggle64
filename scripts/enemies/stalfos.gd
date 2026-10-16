extends Enemy
## Drowned Stalfos, after OoT's EnTest (z_en_test.c): a skeleton swordsman
## that fights like a fencer.
## - It walks up to the hero, then circles him sideways (EnTest_SetupWalkAndBlock).
## - With its shield up it blocks blows and arrows that come from in front
##   (the hero has to strike after its own attacks, or from the side).
## - It slashes when close, or leaps in with an overhead chop from further off
##   (EnTest_SetupJumpslash); after attacking it is open for a moment.
## - Hurt, it hops back out of reach (EnTest_SetupJumpBack).
## - It falls apart into a heap of bones when beaten.

enum State { IDLE, APPROACH, STRAFE, WINDUP, SLASH, JUMP, RECOVER, HURT, HOP_BACK, STUNNED, DEAD }

## How long into the windup it still turns toward the hero (4 OoT frames).
const WINDUP_TURN_TIME := 0.13
## The raised blade is held a little longer than EnTest's, so a back flip on
## seeing it carries the hero clear.
const WINDUP_TIME := 0.5

@export var notice_range := 10.0
@export var walk_speed := 1.8
@export var strafe_speed := 1.5

var state := State.IDLE
var _t := 0.0
var _strafe_dir := 1.0
var _strafe_time := 1.5
var _guard_flash := 0.0


func _ready() -> void:
	corpse_time = 0.8
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
	_guard_flash = maxf(_guard_flash - delta, 0.0)
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.15)
			if _can_see_player(notice_range):
				_go(State.APPROACH)
		State.APPROACH:
			_face(p, delta, 400.0)
			if not alive or dist > notice_range * 1.6:
				_go(State.IDLE)
			elif dist > 2.6:
				_move(_forward(), walk_speed, delta)
				model.play(&"walk", 0.1, walk_speed / 1.8)
			else:
				_strafe_dir = 1.0 if _rng.randf() < 0.5 else -1.0
				_strafe_time = _rng.randf_range(0.8, 1.8)
				_go(State.STRAFE)
		State.STRAFE:
			_face(p, delta, 400.0)
			var side := Vector3(-_forward().z, 0, _forward().x) * _strafe_dir
			var keep := _forward() * clampf(dist - 2.4, -1.0, 1.0)
			_move((side + keep).normalized(), strafe_speed, delta)
			# EnTest side-steps round the hero (its "strafe" steps to its
			# right played forward, to its left played backward).
			if _guard_flash > 0.0:
				model.play(&"guard", 0.1)
			else:
				model.play(&"strafe", 0.12, _strafe_dir * strafe_speed / 1.5)
			if is_on_wall():
				_strafe_dir = -_strafe_dir
			if not alive:
				_go(State.IDLE)
			elif _t >= _strafe_time:
				if dist < 2.7:
					_go(State.WINDUP)
				elif dist < 5.0:
					_go(State.JUMP)
				else:
					_go(State.APPROACH)
		State.WINDUP:
			_brake(delta)
			# EnTest_SlashDown turns only over its first 4 frames, then the
			# blade is committed: a side hop or back flip now gets clear.
			if _t < WINDUP_TURN_TIME:
				_face(p, delta, 200.0)
			if _t >= WINDUP_TIME:
				_go(State.SLASH)
		State.SLASH:
			# It stands its ground as it cuts (EnTest sets its speed to 0).
			_brake(delta, 20.0)
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.2 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.2:
					attack_hitbox.deactivate()
			if _t >= 0.3:
				_go(State.RECOVER)
		State.JUMP:
			if attack_hitbox:
				if _t >= 0.4 and _t < 0.6 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.6:
					attack_hitbox.deactivate()
			if _t > 0.15 and is_on_floor() and _t > 0.55:
				_brake(delta, 20.0)
			if _t >= 0.75:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			model.play(&"idle", 0.2)
			if _t >= 0.7:
				_go(State.STRAFE)
		State.HURT:
			_brake(delta, 10.0)
			if _t >= 0.35:
				_go(State.HOP_BACK)
		State.HOP_BACK:
			if _t >= 0.4 and is_on_floor():
				_brake(delta, 20.0)
				_go(State.STRAFE)
		State.STUNNED:
			_brake(delta, 10.0)
			model.play(&"stunned", 0.05)
			if stun_left <= 0.0:
				_go(State.STRAFE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _face(p: PlayerController, delta: float, rate: float) -> void:
	if p:
		_turn_to(p.global_position, rate, delta)


func _move(dir: Vector3, speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, dir.x * speed, 12.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 12.0 * delta)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SLASH and s != State.JUMP:
		attack_hitbox.deactivate()
	match s:
		State.WINDUP:
			model.play(&"windup", 0.06, 1.0, true)
		State.SLASH:
			model.play(&"slash", 0.02, 1.0, true)
			Sfx.play("sword_swing", -4.0, 0.08, 0.8)
		State.JUMP:
			model.play(&"jump_chop", 0.04, 1.0, true)
			var p := _player()
			var dist := _flat_dist(p.global_position) if p else 3.0
			velocity = _forward() * clampf((dist - 1.3) / 0.55, 0.0, 7.0)
			velocity.y = 6.0
			Sfx.play("hop", -6.0, 0.05, 0.7)
		State.RECOVER:
			model.play(&"idle", 0.2)
		State.HURT:
			model.play(&"hurt", 0.03, 1.0, true)
		State.HOP_BACK:
			model.play(&"hop_back", 0.04, 1.0, true)
			velocity = -_forward() * 5.0
			velocity.y = 4.5
		State.STUNNED:
			model.play(&"stunned", 0.05)


## The shield stops blows and arrows from in front while it is on guard.
func _guard(info: HitInfo) -> int:
	if not (state in [State.IDLE, State.APPROACH, State.STRAFE]):
		return Hurtbox.Result.HIT
	var to := _flat_to(info.source_position)
	if to.length() > 0.01 and _forward().dot(to.normalized()) > cos(deg_to_rad(70.0)):
		Sfx.play("shield_block", -2.0, 0.05, 0.85)
		_guard_flash = 0.4
		model.play(&"guard", 0.02, 1.0, true)
		# Sometimes it answers a blocked blow at once.
		if _rng.randf() < 0.45 and _flat_dist(info.source_position) < 3.0:
			_go(State.WINDUP)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)


func stun(seconds: float) -> void:
	super.stun(seconds)
	if not _dead:
		_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	Sfx.play("bone_rattle", -2.0)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.0, 14, 2.5, 3.5, 1.4, 1.2, Color(1.6, 1.55, 1.3))
	super._die()
