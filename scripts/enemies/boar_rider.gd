class_name BoarRider
extends Enemy
## A goblin on a war boar (Chapter IV): it sizes the hero up, paws the
## ground, and charges in a straight line with its spear couched. Head-on the
## boar's tusked skull turns blades; from the side, or once it has thundered
## past and skids round, it can be struck. A charge into a wall (or a
## Sapphire Staff block) leaves it dazed and open.
##
## In the Siege of Haven it charges the village gate instead (`gate`): each
## run that reaches it batters the gate (gate.ram()).

enum State { IDLE, PAW, CHARGE, SKID, STUNNED, HURT, DEAD }

@export var notice_range := 18.0
@export var charge_speed := 9.5
@export var charge_time := 2.4
## The gate it rams in the siege (a node with ram(amount)).
var gate: Node3D = null

var state := State.IDLE
var _t := 0.0
var _dir := Vector3.FORWARD
var _wander := Vector3.ZERO


func _ready() -> void:
	corpse_time = 1.6
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 9.0


func _target() -> Vector3:
	if is_instance_valid(gate):
		return gate.global_position
	var p := _player()
	return p.global_position if p else global_position + _forward() * 5.0


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := (p != null and not p.is_dead()) or is_instance_valid(gate)
	var to := _flat_to(_target())
	var dist := to.length()
	if stun_left > 0.0 and state != State.STUNNED:
		_go(State.STUNNED)
	match state:
		State.IDLE:
			model.play(&"idle", 0.2)
			_brake(delta, 8.0)
			if alive and (is_instance_valid(gate) or (dist < notice_range * Progress.stealth())):
				_turn_to(_target(), 180.0, delta)
				if _t > 0.8:
					_go(State.PAW)
		State.PAW:
			_brake(delta)
			_turn_to(_target(), 260.0, delta)
			if _t >= 0.7:
				_dir = _forward()
				_go(State.CHARGE)
		State.CHARGE:
			var v := _dir * charge_speed
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox and not attack_hitbox.active:
				attack_hitbox.activate()
			if is_instance_valid(gate) and dist < 3.0:
				gate.call("ram", 1)
				Sfx.play("wood_crash", 0.0, 0.05)
				_bounce()
				return
			if _t >= charge_time:
				_go(State.SKID)
		State.SKID:
			_brake(delta, 10.0)
			_turn_to(_target(), 140.0, delta)
			if _t >= 1.0:
				_go(State.PAW)
		State.STUNNED:
			_brake(delta, 14.0)
			stun_left = maxf(stun_left - delta, 0.0)
			if _t >= 2.6 and stun_left <= 0.0:
				_go(State.IDLE)
		State.HURT:
			_brake(delta)
			if _t >= 0.4:
				_go(State.SKID)
	_fall(delta)
	move_and_slide()
	# A charge that ploughs into something solid (a wall, a block) dazes it.
	if state == State.CHARGE and _t > 0.2 and get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var n := c.get_normal()
			if absf(n.y) < 0.5 and n.dot(_dir) < -0.6:
				var hit := c.get_collider()
				if hit is SapphireBlock:
					(hit as SapphireBlock).shatter()
				_bounce()
				break
	rotation.y = facing_yaw


## Rebounds off whatever it hit, dazed.
func _bounce() -> void:
	velocity = -_dir * 4.0
	stun_left = 2.0
	Sfx.play("wall_hit_hard", 0.0, 0.05, 0.6)
	if attack_hitbox:
		attack_hitbox.deactivate()
	_go(State.STUNNED)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.CHARGE:
		attack_hitbox.deactivate()
	match s:
		State.PAW:
			model.play(&"idle", 0.1, 2.5)
			Sfx.play("horse_snort", -2.0, 0.05, 0.6)
		State.CHARGE:
			model.play(&"charge", 0.1)
			Sfx.play("boar_squeal", -2.0, 0.08)
		State.SKID:
			model.play(&"run", 0.15, 0.6)
		State.STUNNED:
			model.play(&"stunned", 0.1)
		State.HURT:
			model.play(&"hurt", 0.02, 1.0, true)


## The tusked skull turns blades head-on while it charges or paws.
func _guard(info: HitInfo) -> int:
	if info.bomb or info.reflected or state in [State.STUNNED, State.SKID, State.HURT]:
		return Hurtbox.Result.HIT
	var from := _flat_to(info.source_position).normalized()
	if state in [State.CHARGE, State.PAW] and from.dot(_forward()) > 0.5:
		Sfx.play("shield_block", -4.0, 0.08, 0.7)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	if state != State.STUNNED:
		_go(State.HURT)


func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	super._die()
