extends Enemy
## Snapper, a biting plant after OoT's Deku Baba (z_en_dekubaba.c):
## - It hides below its leaves until the hero comes within about 5 m, then
##   rises on its stalk, sways and turns its head to follow him.
## - When he is in reach it rears back with its jaws open and lunges to bite
##   (EnDekubaba_PrepareLunge / _Lunge), then pulls back.
## - A hit stuns it limp for a moment (EnDekubaba_SetupHit); the second kills
##   it. It sinks back down when the hero walks away. It never moves from its
##   roots.

enum State { HIDDEN, RISE, IDLE, WINDUP, BITE, RECOVER, STUNNED, HURT, SINK, DEAD }

@export var notice_range := 5.0
@export var bite_range := 2.8

var state := State.HIDDEN
var _t := 0.0
var _cool := 0.0


func _ready() -> void:
	super._ready()
	_set_hidden(true)


func is_targetable() -> bool:
	return super.is_targetable() and state != State.HIDDEN and state != State.SINK


func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if _dead:
		return
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var dist := _flat_dist(p.global_position) if p and not p.is_dead() else 99.0
	match state:
		State.HIDDEN:
			if dist < notice_range and absf(p.global_position.y - global_position.y) < 3.0:
				_set_hidden(false)
				_go(State.RISE)
				model.play(&"rise", 0.02, 1.0, true)
				Sfx.play("grass_cut", -10.0, 0.05, 0.7)
		State.RISE:
			_face(p, delta)
			if _t >= 0.35:
				_go(State.IDLE)
		State.IDLE:
			model.play(&"idle", 0.15)
			_face(p, delta)
			if dist > notice_range + 2.5:
				_go(State.SINK)
				model.play(&"rise", 0.05, -1.0, true)
			elif dist < bite_range and _cool <= 0.0 and _t > 0.4:
				_go(State.WINDUP)
				model.play(&"windup", 0.06, 1.0, true)
		State.WINDUP:
			_face(p, delta, 120.0)
			if _t >= 0.4:
				_go(State.BITE)
				model.play(&"bite", 0.02, 1.0, true)
				Sfx.play("snap", -4.0)
		State.BITE:
			if attack_hitbox:
				if _t >= 0.06 and _t < 0.25 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.25:
					attack_hitbox.deactivate()
			if _t >= 0.35:
				_go(State.RECOVER)
				model.play(&"recover", 0.05, 1.0, true)
		State.RECOVER:
			if _t >= 0.5:
				_cool = 0.8
				_go(State.IDLE)
		State.HURT:
			if _t >= 0.3:
				_go(State.IDLE)
		State.STUNNED:
			model.play(&"stunned", 0.08)
			if stun_left <= 0.0:
				_go(State.IDLE)
		State.SINK:
			if _t >= 0.35:
				_set_hidden(true)
				_go(State.HIDDEN)
	rotation.y = facing_yaw


func _face(p: PlayerController, delta: float, rate := 240.0) -> void:
	if p:
		_turn_to(p.global_position, rate, delta)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.BITE:
		attack_hitbox.deactivate()


func _set_hidden(h: bool) -> void:
	_set_hurtbox(not h)
	collision_layer = 0 if h else 4
	if h and model:
		model.play(&"hide", 0.0, 1.0, true)


func _hurt(_info: HitInfo) -> void:
	stun(1.6)


func stun(seconds: float) -> void:
	if _dead or state == State.HIDDEN:
		return
	super.stun(seconds)
	_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.0, 8, 2.0, 3.0, 1.0, 1.4, tint)
	super._die()
