extends Enemy
## A Wind Wisp of Skyreach Spire: a little cloud with a puffed-out face that
## drifts about its perch. Every so often it turns to the hero, swells and
## blows a gust that shoves him away (off a ledge, as like as not) unless he
## stands firm in the Wind Boots. One cut bursts it.

enum State { DRIFT, SWELL, BLOW, DEAD }

const GUST := 7.0
const GUST_RANGE := 8.0

@export var notice_range := 10.0

var state := State.DRIFT
var _t := 0.0
var _phase := 0.0


func _ready() -> void:
	corpse_time = 0.4
	super._ready()
	_phase = _rng.randf() * TAU


func _snap_to_ground() -> void:
	_home = global_position


func _physics_process(delta: float) -> void:
	_t += delta
	_phase += delta
	if _dead:
		velocity = Vector3.ZERO
		return
	var p := _player()
	var alive := p != null and not p.is_dead()
	var to := (p.global_position + Vector3.UP * 1.0 - global_position) if alive else Vector3.ZERO
	match state:
		State.DRIFT:
			model.play(&"float", 0.2)
			var want := _home + Vector3(cos(_phase * 0.7) * 1.5, sin(_phase * 1.3) * 0.4, sin(_phase * 0.7) * 1.5)
			velocity = (want - global_position) * 1.5
			if alive and to.length() < notice_range:
				_turn_to(p.global_position, 200.0, delta)
				if _t > 2.6:
					_go(State.SWELL)
		State.SWELL:
			velocity = velocity.lerp(Vector3.ZERO, clampf(delta * 4.0, 0.0, 1.0))
			if alive:
				_turn_to(p.global_position, 300.0, delta)
			if _t >= 0.6:
				_go(State.BLOW)
		State.BLOW:
			velocity = Vector3.ZERO
			if alive and to.length() < GUST_RANGE and _forward().dot(Vector3(to.x, 0, to.z).normalized()) > 0.7:
				var push := Vector3(to.x, 0, to.z).normalized() * GUST * (1.0 - to.length() / GUST_RANGE * 0.5)
				p.wind_push += push
			if _t >= 0.9:
				_go(State.DRIFT)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.SWELL:
			model.play(&"swell", 0.05, 1.0, true)
		State.BLOW:
			model.play(&"blow", 0.03, 1.0, true)
			Sfx.play("boomerang_throw", -4.0, 0.05, 0.5)


func _die() -> void:
	state = State.DEAD
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 10, 2.0, 2.5, 0.8, 0.6, Color(1.2, 1.2, 1.3))
	Sfx.play("bubble_pop", -2.0, 0.05, 0.7)
	super._die()
