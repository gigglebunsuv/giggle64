extends Enemy
## A Shade of Ladhellin Tower, after OoT's Poes and the Shadow Temple's
## unseen foes: a wisp of the tower's old darkness in a tattered hood. In the
## gloom it is all but invisible and nothing touches it; it drifts round the
## hero and darts in to rake him. Caught in a beam of sunlight it is laid
## bare: it reels, stunned and solid, and the sword can cut it down.

enum State { DRIFT, DART, RETREAT, REVEALED, DEAD }

## Seconds it stays solid after the light leaves it.
const REVEAL_TIME := 4.0
## Light needed (seconds in the beam) to lay it bare.
const LIGHT_NEEDED := 0.15

@export var notice_range := 12.0
@export var hover := 1.3

var state := State.DRIFT
var revealed := 0.0
var _t := 0.0
var _orbit := 1.0
var _light := 0.0
var _alpha := 0.12


func _ready() -> void:
	corpse_time = 0.8
	super._ready()
	_orbit = 1.0 if _rng.randf() < 0.5 else -1.0
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 4.0
	_apply_alpha()


## Shades float: no settling to the ground.
func _snap_to_ground() -> void:
	_home = global_position


func is_targetable() -> bool:
	return revealed > 0.0 and super.is_targetable()


func light_hit(delta: float, _dir: Vector3) -> void:
	if _dead:
		return
	_light += delta
	if _light >= LIGHT_NEEDED:
		if state != State.REVEALED:
			Sfx.play("shade_shriek", -3.0, 0.1)
			_go(State.REVEALED)
		revealed = REVEAL_TIME


## The sword passes through it in the dark.
func _guard(_info: HitInfo) -> int:
	return Hurtbox.Result.HIT if revealed > 0.0 else Hurtbox.Result.IGNORED


func _physics_process(delta: float) -> void:
	_t += delta
	_light = maxf(_light - delta * 0.5, 0.0)
	if _dead:
		velocity.y -= 8.0 * delta
		move_and_slide()
		return
	var want_alpha := 1.0 if revealed > 0.0 else 0.12
	_alpha = move_toward(_alpha, want_alpha, delta * 3.0)
	_apply_alpha()
	var p := _player()
	var alive := p != null and not p.is_dead()
	var target := (p.global_position if alive else _home) + Vector3.UP * hover
	match state:
		State.DRIFT:
			model.play(&"float", 0.2)
			if alive and global_position.distance_to(p.global_position) < notice_range:
				# Circle the hero at a few meters, bobbing.
				var to := _flat_to(p.global_position)
				var side := Vector3(-to.z, 0, to.x).normalized() * _orbit
				var want := to.normalized() * (to.length() - 3.5)
				var v := (want * 0.8 + side * 1.6)
				v.y = (target.y + sin(_t * 2.0) * 0.3 - global_position.y) * 2.0
				velocity = velocity.lerp(v, clampf(delta * 3.0, 0.0, 1.0))
				_turn_to(p.global_position, 300.0, delta)
				if _t > 3.0:
					_go(State.DART)
			else:
				velocity = velocity.lerp((_home - global_position) * 0.8, clampf(delta * 2.0, 0.0, 1.0))
		State.DART:
			if alive:
				_turn_to(p.global_position, 500.0, delta)
				var to3 := (p.global_position + Vector3.UP * 1.1) - global_position
				velocity = to3.normalized() * 5.5
			if attack_hitbox and not attack_hitbox.active and _t > 0.1:
				attack_hitbox.activate()
			if _t > 0.8 or (alive and global_position.distance_to(p.global_position + Vector3.UP * 1.1) < 0.6):
				_go(State.RETREAT)
		State.RETREAT:
			if alive:
				var away := -_flat_to(p.global_position).normalized() * 4.0
				away.y = (target.y + 0.8 - global_position.y) * 2.0
				velocity = velocity.lerp(away, clampf(delta * 4.0, 0.0, 1.0))
			if _t > 1.0:
				_go(State.DRIFT)
		State.REVEALED:
			revealed = maxf(revealed - delta, 0.0)
			model.play(&"reel", 0.1)
			# Stunned at first, then it shakes itself and drifts again (still solid).
			velocity = velocity.lerp(Vector3(0, (target.y - 0.4 - global_position.y), 0), clampf(delta * 3.0, 0.0, 1.0))
			if revealed <= 0.0:
				_go(State.DRIFT)
	if state != State.REVEALED:
		revealed = maxf(revealed - delta, 0.0)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.DART:
		attack_hitbox.deactivate()
	match s:
		State.DART:
			model.play(&"swipe", 0.05, 1.0, true)
			Sfx.play("keese_cry", -8.0, 0.1, 0.6)


func _apply_alpha() -> void:
	if model == null:
		return
	model.visible = _alpha > 0.02
	model.set_meta("alpha", _alpha)
	for m in model.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).transparency = 1.0 - _alpha


func _die() -> void:
	state = State.DEAD
	Sfx.play("shade_shriek", -2.0, 0.05, 0.8)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.4, 12, 2.0, 3.0, 1.0, 0.8, Color(0.25, 0.15, 0.35))
	super._die()
