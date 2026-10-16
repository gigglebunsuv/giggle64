extends Enemy
## Keese, after OoT's EnFirefly (z_en_firefly.c): a bat that hangs about its
## roost flapping, and when the hero comes near (within about 8 m and in
## sight) flies at his head in a weaving line, touches him, then flies up and
## away before turning to dive again. One hit (or the boomerang) brings it down.

enum State { HOVER, DIVE, RETREAT, STUNNED, DEAD }

@export var notice_range := 8.0
## Flying speed in m/s (OoT keese fly at 4 units a frame).
@export var fly_speed := 3.6

var state := State.HOVER
var _t := 0.0
var _retreat_to := Vector3.ZERO
var _phase := 0.0


func _ready() -> void:
	super._ready()
	_phase = _rng.randf() * TAU


## Keese hang in the air: no settling to the ground.
func _snap_to_ground() -> void:
	_home = global_position


func _physics_process(delta: float) -> void:
	_t += delta
	_phase += delta * 6.0
	if _dead:
		velocity.y -= 12.0 * delta
		move_and_slide()
		return
	stun_left = maxf(stun_left - delta, 0.0)
	var p := _player()
	var head := p.global_position + Vector3.UP * 1.3 if p else _home
	match state:
		State.HOVER:
			model.play(&"idle", 0.1)
			var drift := _home + Vector3(sin(_phase * 0.4) * 0.6, sin(_phase * 0.7) * 0.25, cos(_phase * 0.3) * 0.6)
			velocity = (drift - global_position) * 2.0
			if p:
				_turn_to(p.global_position, 360.0, delta)
			if _can_see_player(notice_range, 6.0) and _t > 0.6:
				_go(State.DIVE)
		State.DIVE:
			model.play(&"swoop", 0.08)
			var to := head - global_position
			var side := Vector3(-to.z, 0, to.x).normalized() * sin(_phase) * 1.2
			velocity = (to.normalized() * fly_speed + side).limit_length(fly_speed * 1.2)
			_turn_to(head, 720.0, delta)
			if to.length() < 0.5 or _t > 4.0 or p == null or p.is_dead():
				_retreat()
		State.RETREAT:
			model.play(&"idle", 0.1)
			velocity = (_retreat_to - global_position).limit_length(fly_speed)
			if global_position.distance_to(_retreat_to) < 0.6 or _t > 2.0:
				_go(State.HOVER if not _can_see_player(notice_range * 1.5, 6.0) else State.DIVE)
		State.STUNNED:
			model.play(&"stunned", 0.05)
			velocity = velocity.move_toward(Vector3(0, -2.0, 0), 8.0 * delta)
			if is_on_floor():
				velocity.y = 0.0
			if stun_left <= 0.0:
				_retreat()
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox:
		if s == State.DIVE:
			attack_hitbox.activate.call_deferred()
		else:
			attack_hitbox.deactivate()
	if s == State.DIVE:
		Sfx.play("keese_cry", -10.0, 0.1)


func _retreat() -> void:
	var away := global_position - (_player().global_position if _player() else _home)
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
	_retreat_to = global_position + away.rotated(Vector3.UP, _rng.randf_range(-0.8, 0.8)) * 4.0 + Vector3.UP * 1.5
	_retreat_to.y = maxf(_retreat_to.y, _home.y)
	_go(State.RETREAT)


func _on_attack_landed(_hb: Hurtbox, _result: int) -> void:
	_retreat.call_deferred()


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_retreat()


func stun(seconds: float) -> void:
	super.stun(seconds)
	if not _dead:
		_go(State.STUNNED)


func _die() -> void:
	state = State.DEAD
	if model:
		model.play(&"death", 0.03, 1.0, true)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position, 5, 1.5, 2.0, 0.7, 0.8, Color(0.3, 0.2, 0.35))
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(queue_free)
