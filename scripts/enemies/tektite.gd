extends Enemy
## Tektite, after OoT's EnTite (z_en_tite.c):
## - It waits until the hero comes within 300 units (9 m) and 80 units of
##   height, turns to face him, crouches and jumps.
## - Within 180 units (5.4 m) it makes attack jumps (velocity.y 8, speed 4,
##   gravity -1) that hurt on contact; farther off it hops closer (velocity.y
##   10, speed 4), one to three jumps in a row (vQueuedJumps) before resting.
## - Red tektites take 2 points of damage, blue ones 4 (colChkInfo.health).

enum State { IDLE, TURN, CROUCH, AIR, LAND, HURT, STUNNED, DEAD }

@export var notice_range := 9.0
@export var attack_range := 5.4

var state := State.IDLE
var _t := 0.0
var _jumps := 0
var _attack_jump := false
var _rest := 1.0


func _ready() -> void:
	super._ready()
	_rest = _rng.randf_range(0.75, 1.5)


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	var p := _player()
	var near := p != null and not p.is_dead() and _flat_dist(p.global_position) < notice_range \
		and absf(p.global_position.y - global_position.y) < 2.4
	stun_left = maxf(stun_left - delta, 0.0)
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.15)
			if near and _t > _rest:
				_go(State.TURN)
		State.TURN:
			_brake(delta)
			_turn_to(p.global_position if p else global_position, 540.0, delta)
			if p == null or absf(angle_difference(facing_yaw, _yaw_to(p.global_position))) < 0.2 or _t > 0.6:
				_go(State.CROUCH)
		State.CROUCH:
			_brake(delta)
			if _t >= 0.25:
				_jump()
		State.AIR:
			if is_on_floor() and _t > 0.1:
				_land()
		State.LAND:
			_brake(delta, 20.0)
			if _t >= 0.2:
				_jumps -= 1
				if _jumps > 0 and near:
					_go(State.TURN)
				else:
					_rest = _rng.randf_range(0.6, 1.2)
					_go(State.IDLE)
		State.HURT:
			_brake(delta, 8.0)
			if _t >= 0.35 and is_on_floor():
				_go(State.IDLE)
		State.STUNNED:
			_brake(delta, 10.0)
			if stun_left <= 0.0:
				_go(State.IDLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.TURN:
			if _jumps <= 0:
				_jumps = _rng.randi_range(1, 3)
		State.CROUCH:
			model.play(&"crouch", 0.08, 1.0, true)
		State.LAND:
			model.play(&"land", 0.04, 1.0, true)
		State.HURT:
			model.play(&"hurt", 0.03, 1.0, true)
		State.STUNNED:
			model.play(&"stunned", 0.05)
	if s != State.AIR and attack_hitbox:
		attack_hitbox.deactivate()


func _jump() -> void:
	var p := _player()
	var dist := _flat_dist(p.global_position) if p else 99.0
	_attack_jump = dist <= attack_range
	var vy := 8.0 if _attack_jump else 10.0
	var speed := 4.0 * OOT_SPEED
	if _attack_jump:
		# Land on him rather than past him.
		var t_air := 2.0 * vy * OOT_SPEED / OOT_GRAVITY
		speed = minf(speed, dist / t_air)
	velocity = _forward() * speed
	velocity.y = vy * OOT_SPEED
	gravity = OOT_GRAVITY
	_go(State.AIR)
	model.play(&"jump", 0.04, 1.0, true)
	Sfx.play("hop", -8.0)
	if _attack_jump and attack_hitbox:
		attack_hitbox.activate()


func _land() -> void:
	Sfx.play("land", -10.0, 0.08, 0.8)
	_go(State.LAND)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	velocity.y = 3.0
	_go(State.HURT)


func stun(seconds: float) -> void:
	super.stun(seconds)
	if not _dead:
		_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	super._die()
