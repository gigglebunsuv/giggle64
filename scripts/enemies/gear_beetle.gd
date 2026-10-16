extends Enemy
## A Gear Beetle of the Southern Tower. Its cog-ringed shell turns the sword
## aside from the front and sides; only its underside is soft. It scuttles
## toward the hero and, lined up with him, lowers its head and charges.
## The Hookshot or the boomerang knocks it onto its back, legs kicking, for a
## few seconds: then the sword finds its belly. (A jump slash from above
## cracks the shell anyway.)

enum State { IDLE, WALK, CHARGE, RECOVER, FLIPPED, DEAD }

@export var notice_range := 10.0
@export var flip_time := 4.0

var state := State.IDLE
var _t := 0.0


func _ready() -> void:
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 5.0


func is_flipped() -> bool:
	return state == State.FLIPPED


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
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if alive and dist < notice_range:
				_go(State.WALK)
		State.WALK:
			if not alive:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 160.0, delta)
				var v := _forward() * 1.6
				velocity.x = v.x
				velocity.z = v.z
				model.play(&"walk", 0.15)
				var ahead := _forward().dot(_flat_to(p.global_position).normalized())
				if dist < 6.0 and ahead > 0.95 and _t > 1.0:
					_go(State.CHARGE)
		State.CHARGE:
			var v := _forward() * 6.5
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox and not attack_hitbox.active:
				attack_hitbox.activate()
			if is_on_wall() or _t > 1.2:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t > 0.8:
				_go(State.WALK)
		State.FLIPPED:
			_brake(delta)
			if _t >= flip_time:
				# Rights itself with a clatter.
				Sfx.play("armor_clang", -10.0, 0.05, 1.4)
				_go(State.WALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.CHARGE:
		attack_hitbox.deactivate()
	match s:
		State.CHARGE:
			model.play(&"charge", 0.05)
			Sfx.play("heavy_step", -8.0, 0.05, 1.6)
		State.RECOVER:
			model.play(&"idle", 0.1)
		State.FLIPPED:
			model.play(&"flipped", 0.05, 1.0, true)


## The boomerang or the Hookshot: over it goes.
func boomerang_hit(_b: Node3D) -> void:
	flip()


func hookshot_hit(_h: Node3D) -> void:
	flip()


func flip() -> void:
	if _dead:
		return
	stun_left = 0.0
	Sfx.play("armor_clang", -4.0, 0.05, 1.2)
	velocity.y = 3.0
	_go(State.FLIPPED)


## The shell turns the sword unless it is on its back (or the blow comes
## down from above in a jump slash).
func _guard(info: HitInfo) -> int:
	if state == State.FLIPPED:
		return Hurtbox.Result.HIT
	var hero := info.attacker as PlayerController
	if hero and hero.state == PlayerController.State.JUMPSLASH:
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -6.0, 0.08, 1.5)
	return Hurtbox.Result.BLOCKED
