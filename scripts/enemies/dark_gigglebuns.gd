class_name DarkGigglebuns
extends Enemy
## Dark Gigglebuns (the Temple of Bun's trial of the pure heart, Chapter IV):
## the hero's own shadow, stepped out of the mirror-still pool. It fights as
## he does, and it mirrors him: it moves to the place opposite his across the
## hall's center, and it answers a swing with its own shield (from the front)
## and a counter-cut.
##
## The trial is not won by the sword. Beaten down, the shadow KNEELS and lays
## its blade on the floor. Strike it while it kneels and it rises whole again
## ("a heart that strikes the fallen is not pure"). Put the sword away, or
## simply stand and do not strike for a few breaths, and the shadow bows,
## and fades: the trial is passed.

enum State { RISE, MIRROR, ATTACK, GUARD, HURT, KNEEL, FADE, DEAD }

## How long the hero must hold his blade while the shadow kneels.
const MERCY_TIME := 5.0
## Where the hall's middle is (set by the region; else its home).
@export var center := Vector3.INF

var state := State.RISE
var _t := 0.0
var _cool := 1.2
var _mercy := 0.0
var _rises := 0
var _struck_kneeling := false


func _ready() -> void:
	corpse_time = 2.0
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 6.0
	if center == Vector3.INF:
		center = global_position
	if model and model.has_method("set_gear"):
		model.call("set_gear", "bun", "mirror")
	_go(State.RISE)


func _mirror_point(p: PlayerController) -> Vector3:
	var c := Vector3(center.x, global_position.y, center.z)
	var m := c - (p.global_position - c)
	m.y = global_position.y
	return m


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	match state:
		State.RISE:
			_brake(delta)
			if model:
				model.scale = Vector3.ONE * clampf(_t / 1.0, 0.05, 1.0)
			if _t >= 1.2:
				_go(State.MIRROR)
		State.MIRROR:
			if not alive:
				_brake(delta)
				model.play(&"idle", 0.2)
			else:
				_turn_to(p.global_position, 360.0, delta)
				# Close in to fight when near; otherwise keep to the mirrored spot.
				var goal := p.global_position if dist < 4.0 else _mirror_point(p)
				var to := _flat_to(goal)
				if to.length() > 1.4:
					var v := to.normalized() * minf(to.length() * 2.0, 4.5)
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"run_sword", 0.12, 1.1)
				else:
					_brake(delta)
					model.play(&"idle", 0.2)
				# It swings when the hero stands within reach and lowers his guard.
				if dist < 2.1 and _cool <= 0.0 and not p.is_shielding():
					_go(State.ATTACK)
				elif dist < 2.3 and p.combat.is_attacking() and from_front(p.global_position):
					_go(State.GUARD)
		State.ATTACK:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 200.0, delta)
			if attack_hitbox:
				if _t >= 0.12 and _t < 0.28 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.28:
					attack_hitbox.deactivate()
			if _t >= 0.5:
				_cool = randf_range(0.8, 1.4)
				_go(State.MIRROR)
		State.GUARD:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 300.0, delta)
			if _t >= 0.45:
				_cool = 0.0
				_go(State.ATTACK)
		State.HURT:
			_brake(delta)
			if _t >= 0.35:
				_go(State.MIRROR)
		State.KNEEL:
			_brake(delta, 20.0)
			model.play(&"sleep", 0.3)
			var holding := alive and not p.combat.is_attacking()
			if holding:
				_mercy += delta
			if p and not p.sword_drawn and alive:
				_mercy += delta * 2.0
			if _mercy >= MERCY_TIME:
				_go(State.FADE)
		State.FADE:
			if model:
				model.scale = Vector3.ONE * clampf(1.0 - _t / 1.6, 0.02, 1.0)
			if _t >= 1.6:
				_dead = true
				remove_from_group("enemies")
				collision_layer = 0
				_set_hurtbox(false)
				died.emit()
				queue_free()
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func from_front(pos: Vector3) -> bool:
	return _flat_to(pos).normalized().dot(_forward()) > 0.3


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.ATTACK:
		attack_hitbox.deactivate()
	match s:
		State.RISE:
			if model:
				model.scale = Vector3.ONE * 0.05
			Sfx.play("shade_shriek", -6.0, 0.0, 0.6)
		State.ATTACK:
			model.play(&"attack_1" if randf() < 0.5 else &"attack_2", 0.03, 1.0, true)
			Sfx.play("sword_swing", -4.0, 0.06, 0.8)
		State.GUARD:
			model.play(&"block", 0.05, 1.0, true)
		State.HURT:
			model.play(&"hurt", 0.02, 1.0, true)
		State.KNEEL:
			_mercy = 0.0
			_struck_kneeling = false
			Sfx.play("shiver", -4.0, 0.0, 0.7)
			Dialogue.start(["The shadow sinks to its knees, and lays its sword on the floor before you."], null)
		State.FADE:
			Sfx.play("goddess_chime", -2.0, 0.0)


## Head-on, it guards like the hero does.
func _guard(info: HitInfo) -> int:
	if state in [State.RISE, State.FADE]:
		return Hurtbox.Result.IGNORED
	if state == State.KNEEL:
		return Hurtbox.Result.HIT
	if state == State.GUARD and from_front(info.source_position):
		Sfx.play("shield_block", -2.0, 0.06)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func take_hit(info: HitInfo) -> int:
	if state == State.KNEEL:
		# Struck while it kneels: it rises whole.
		_struck_kneeling = true
		_rises += 1
		health.reset()
		Sfx.play("shade_shriek", -2.0, 0.0, 0.8)
		Dialogue.start(["The shadow rises again, whole. A voice echoes through the hall:\n*\"A heart that strikes the fallen is not pure.\"*"], null)
		_go(State.MIRROR)
		return Hurtbox.Result.HIT
	var r := _guard(info)
	if r != Hurtbox.Result.HIT:
		return r
	if health.health - info.damage <= 0:
		health.health = 1
		health.health_changed.emit(health.health, health.max_health)
		if model:
			model.flash(Color(1.0, 0.95, 0.8), 0.08)
		_go(State.KNEEL)
		return Hurtbox.Result.HIT
	return super.take_hit(info)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)


func stun(seconds: float) -> void:
	if state == State.MIRROR:
		stun_left = seconds
		_go(State.HURT)
