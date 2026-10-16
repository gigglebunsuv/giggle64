extends Enemy
## Octorok, after OoT's EnOkuta (z_en_okuta.c): it lives under the water.
## When the hero is in range (but not right on top of it) it pops up, turns
## to face him and spits rocks (EnOkuta_SpawnProjectile); the rocks can be
## knocked back with the shield, and a returned rock kills it. It dives when
## he comes close or after a few shots, and comes up again later.

enum State { HIDDEN, RISE, AIM, SHOOT, SINK, STUNNED, DEAD }

@export var notice_range := 14.0
@export var too_close := 2.5
@export var shots := 3

var state := State.HIDDEN
var _t := 0.0
var _left := 0
var _wait := 0.0


func _ready() -> void:
	super._ready()
	_hide(true)


## Octoroks float at the water surface where they were placed.
func _snap_to_ground() -> void:
	_home = global_position


func is_targetable() -> bool:
	return super.is_targetable() and state in [State.AIM, State.SHOOT, State.STUNNED]


func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if _dead:
		return
	_t += delta
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var dist := _flat_dist(p.global_position) if p and not p.is_dead() else 99.0
	match state:
		State.HIDDEN:
			if dist < notice_range and dist > too_close and _t > _wait:
				_hide(false)
				_left = shots
				_go(State.RISE)
				model.play(&"rise", 0.02, 1.0, true)
				Sfx.play("step_water_0", -4.0, 0.05, 0.7)
		State.RISE:
			_turn_to(p.global_position, 360.0, delta)
			if _t >= 0.4:
				_go(State.AIM)
		State.AIM:
			model.play(&"idle", 0.1)
			_turn_to(p.global_position, 300.0, delta)
			if dist < too_close or dist > notice_range + 4.0 or _left <= 0:
				_sink()
			elif _t > 1.4 and absf(angle_difference(facing_yaw, _yaw_to(p.global_position))) < 0.25:
				_go(State.SHOOT)
				model.play(&"shoot", 0.03, 1.0, true)
		State.SHOOT:
			if _t >= 0.15 and _left > 0 and _t - delta < 0.15:
				_spit()
			if _t >= 0.4:
				_go(State.AIM)
		State.SINK:
			if _t >= 0.4:
				_hide(true)
				_wait = _rng.randf_range(2.0, 3.5)
				_go(State.HIDDEN)
		State.STUNNED:
			model.play(&"stunned", 0.05)
			if stun_left <= 0.0:
				_sink()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0


func _sink() -> void:
	_go(State.SINK)
	model.play(&"sink", 0.05, 1.0, true)


func _hide(h: bool) -> void:
	_set_hurtbox(not h)
	collision_layer = 0 if h else 4
	if h and model:
		model.play(&"hidden", 0.0, 1.0, true)


func _spit() -> void:
	_left -= 1
	var rock := Rock.new()
	get_parent().add_child(rock)
	var mouth := global_position + Vector3.UP * 0.45 + _forward() * 0.75
	rock.launch(mouth, _forward(), self)
	Sfx.play("bubble_pop", -4.0, 0.05, 0.6)


func stun(seconds: float) -> void:
	if _dead or state == State.HIDDEN:
		return
	super.stun(seconds)
	_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	Sfx.play("splash_big", -4.0)
	super._die()
