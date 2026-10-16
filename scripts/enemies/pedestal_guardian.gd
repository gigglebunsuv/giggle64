class_name PedestalGuardian
extends Enemy
## The Pedestal Guardian, master of the Temple of Bun (Chapter IV): a knight
## of living stone set to keep the sacred grove's heart since Saga III. No
## blade marks its stone. In its breastplate a lid hides an eye of
## Lothelye's starlight:
## - it sweeps its stone greatsword across the hall (the shield holds it),
##   and stamps the floor (the ground shakes round it);
## - between blows the lid slides up and the eye blazes for a few seconds: a
##   STARFALL ARROW into it brings the Guardian down to one knee, its helm
##   bowed, for the sword;
## - each time it rises it is quicker, and the eye opens for less time.

enum State { WAIT, WAKE, WALK, SWEEP_WINDUP, SWEEP, STOMP_WINDUP, STOMP, EYE, KNEEL, RECOVER, DEAD }

const TITLE := "THE PEDESTAL GUARDIAN"
const SUBTITLE := "KEEPER OF THE SACRED GROVE"
const KNEEL_TIME := 5.0
const STOMP_RADIUS := 4.5

var state := State.WAIT
var _t := 0.0
var _plan := 1.6
var _eye: Node3D
var _eye_light: OmniLight3D
var _eye_hurt: Hurtbox
var _downs := 0


func _ready() -> void:
	corpse_time = 3.0
	super._ready()
	add_to_group("bosses")
	add_to_group("star_eyes")
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 9.0
	_eye = model.find_child("Eye", true, false) as Node3D
	_eye_light = OmniLight3D.new()
	_eye_light.light_color = Color(0.75, 0.82, 1.0)
	_eye_light.light_energy = 0.0
	_eye_light.omni_range = 6.0
	if _eye:
		_eye.add_child(_eye_light)


## Where the eye is (a Starfall Arrow aims here).
func eye_point() -> Vector3:
	return _eye.global_position if _eye else global_position + Vector3.UP * 3.0


func eye_open() -> bool:
	return state == State.EYE


func target_height() -> float:
	return 3.0 if state != State.KNEEL else 1.8


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	var quick := 1.0 + _downs * 0.18
	_eye_light.light_energy = move_toward(_eye_light.light_energy, 2.4 if state == State.EYE else 0.0, delta * 6.0)
	match state:
		State.WAIT:
			model.play(&"kneel", 0.2)
			_brake(delta)
			if alive and dist < 12.0 and absf(p.global_position.y - global_position.y) < 3.0:
				_go(State.WAKE)
		State.WAKE:
			_brake(delta)
			if _t >= 2.8:
				_go(State.WALK)
		State.WALK:
			if alive:
				_turn_to(p.global_position, 80.0 * quick, delta)
				if dist > 3.6:
					var v := _forward() * 1.6 * quick
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.2, 0.6 * quick)
				else:
					_brake(delta)
					model.play(&"idle", 0.2)
			if _t >= _plan / quick:
				_choose(dist)
		State.SWEEP_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 60.0, delta)
			if _t >= 0.8 / quick:
				_go(State.SWEEP)
		State.SWEEP:
			_brake(delta)
			if attack_hitbox:
				if _t >= 0.1 and _t < 0.35 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.35:
					attack_hitbox.deactivate()
			if _t >= 0.6:
				_go(State.EYE if randf() < 0.55 else State.RECOVER)
		State.STOMP_WINDUP:
			_brake(delta)
			if _t >= 0.7 / quick:
				_go(State.STOMP)
		State.STOMP:
			_brake(delta)
			if _t >= 0.08 and _t - delta < 0.08:
				_quake()
			if _t >= 0.6:
				_go(State.EYE)
		State.EYE:
			_brake(delta)
			model.play(&"idle", 0.2, 0.5)
			if p:
				_turn_to(p.global_position, 40.0, delta)
			if _t >= maxf(3.2 - _downs * 0.5, 1.6):
				_go(State.RECOVER)
		State.KNEEL:
			_brake(delta, 20.0)
			if _t >= KNEEL_TIME:
				_downs += 1
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.8:
				_plan = randf_range(1.0, 1.8)
				_go(State.WALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _choose(dist: float) -> void:
	if dist < 4.2 and randf() < 0.65:
		_go(State.SWEEP_WINDUP)
	else:
		_go(State.STOMP_WINDUP)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SWEEP:
		attack_hitbox.deactivate()
	match s:
		State.WAKE:
			model.play(&"alert", 0.4, 0.4, true)
			Sfx.play("quake_rumble", 0.0, 0.0, 0.7)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 3.2, 10.0)
		State.SWEEP_WINDUP:
			model.play(&"windup", 0.1, 0.6, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.4)
		State.SWEEP:
			model.play(&"sweep", 0.04, 1.0, true)
			Sfx.play("heavy_swing", 0.0, 0.05, 0.5)
		State.STOMP_WINDUP:
			model.play(&"windup", 0.1, 0.5, true)
		State.STOMP:
			model.play(&"attack", 0.03, 0.8, true)
		State.EYE:
			Sfx.play("goddess_chime", -6.0, 0.0, 0.8)
		State.KNEEL:
			model.play(&"kneel", 0.15)
			Sfx.play("boss_hurt", -2.0, 0.05, 0.5)
		State.RECOVER:
			model.play(&"recover", 0.1, 0.6, true)


func _quake() -> void:
	Sfx.play("mallet_smash", 3.0, 0.0, 0.4)
	SpellEffect.make(get_parent(), "quake", global_position)
	GameManager.rumble(0.8, 0.4)
	var p := GameManager.player
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 0.4)
	if p and not p.is_dead() and _flat_dist(p.global_position) < STOMP_RADIUS and absf(p.global_position.y - global_position.y) < 1.5:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 9.0
		info.unblockable = true
		info.attacker = self
		info.source_position = global_position
		p.take_hit(info)


## A Starfall Arrow (Arrow.starfall_hit / its burst near the eye).
func starfall_hit(arrow: Node3D) -> void:
	if state != State.EYE:
		return
	if arrow and arrow.global_position.distance_to(eye_point()) > 2.2:
		return
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), eye_point(), 14, 3.0, 3.0, 0.8, 0.8, Color(1.2, 1.3, 1.6))
	_go(State.KNEEL)


func _guard(info: HitInfo) -> int:
	if state in [State.WAIT, State.WAKE]:
		return Hurtbox.Result.IGNORED
	if state == State.KNEEL:
		return Hurtbox.Result.HIT
	Sfx.play("wall_hit_hard", -2.0, 0.08, 0.7)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -2.0, 0.08, 0.7)
	Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3.UP * 2.0, 8, 3.0, 3.0, 0.6, 0.8, Color(0.8, 0.78, 0.7))


func stun(_seconds: float) -> void:
	pass


func daze(_seconds: float, _ice := false) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	Sfx.play("boss_die", 0.0, 0.0, 0.8)
	model.play(&"kneel", 0.2)
	var tween := create_tween()
	for i in 6:
		tween.tween_callback(func() -> void:
			Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3(randf_range(-1, 1), randf_range(0.5, 3.5), randf_range(-1, 1)), 14, 4.0, 4.0, 1.0, 1.2, Color(0.8, 0.78, 0.7))
			Sfx.play("rock_break", -2.0, 0.1))
		tween.tween_interval(0.4)
	tween.tween_property(model, "scale", Vector3(1.0, 0.05, 1.0) * model.scale.x, 0.6)
	tween.tween_callback(queue_free)
