extends Enemy
## A Strawman of the Southern Tower: a scarecrow that has come to life. It
## stands swaying on its pole until the hero comes near, then hops after him
## (one bounce every half second); close in, it twists up and whirls its stick
## arms round in a full circle, then stands dizzy for a moment, open to the
## sword. Straw burns: a burning arrow sets it alight and it goes up at once.

enum State { IDLE, HOP, WINDUP, SPIN, DIZZY, STUNNED, DEAD }

@export var notice_range := 9.0
@export var hop_speed := 2.6

var state := State.IDLE
var _t := 0.0


func _ready() -> void:
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 6.0


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
		_brake(delta)
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
				_go(State.HOP)
		State.HOP:
			if not alive or dist > notice_range * 1.6:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 240.0, delta)
				# It only moves while in the air (the hop is half a second).
				var phase := fmod(_t, 0.5)
				var airborne := phase > 0.12 and phase < 0.45
				var v := _forward() * (hop_speed if airborne else 0.0)
				velocity.x = v.x
				velocity.z = v.z
				if phase < 0.12 and fmod(_t - delta, 0.5) >= 0.12 - delta and fmod(_t - delta, 0.5) < 0.12:
					Sfx.play("hop", -10.0, 0.1, 0.8)
				model.play(&"hop", 0.1)
				if dist < 2.2:
					_go(State.WINDUP)
		State.WINDUP:
			_brake(delta)
			if _t >= 0.6:
				_go(State.SPIN)
		State.SPIN:
			_brake(delta, 6.0)
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.7 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.7:
					attack_hitbox.deactivate()
			if _t >= 0.8:
				_go(State.DIZZY)
		State.DIZZY:
			_brake(delta)
			if _t >= 1.2:
				_go(State.HOP)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SPIN:
		attack_hitbox.deactivate()
	match s:
		State.WINDUP:
			model.play(&"windup", 0.06, 1.0, true)
			Sfx.play("bush_cut", -8.0, 0.05, 0.6)
		State.SPIN:
			model.play(&"spin", 0.02, 1.0, true)
			Sfx.play("heavy_swing", -4.0, 0.05, 1.4)
		State.DIZZY:
			model.play(&"stunned", 0.1)


func stun(seconds: float) -> void:
	super.stun(seconds)
	if attack_hitbox:
		attack_hitbox.deactivate()


## A burning arrow (Arrow.burning): the straw goes up in flames.
func burn() -> void:
	if _dead:
		return
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.4, 12, 2.0, 3.0, 1.2, 1.0, Color(1.8, 0.8, 0.2))
	Sfx.play("torch_light", -2.0)
	health.apply_damage(health.health)


func _die() -> void:
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.2, 10, 2.5, 3.5, 1.4, 1.0, Color(1.0, 0.85, 0.4))
	Sfx.play("bush_cut", -2.0, 0.05, 0.7)
	super._die()
