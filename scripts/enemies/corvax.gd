extends Enemy
## Corvax, the Harvest Crow: master of the Southern Tower, nesting on its roof.
##
## A boss built round the tower's treasure, as OoT's bosses are round theirs:
## - It wheels round the roof high out of reach, then either hovers and flings
##   a volley of feathers (the shield bats them back), or screeches and
##   swoops down across the roof, talons first, and climbs away again.
## - Its feathers turn the sword and arrows only make it flinch. But the
##   Hookshot bites into it (OoT's ACTOR_FLAG_HOOKSHOT_PULLS_ACTOR): it is
##   dragged down out of the sky and crashes onto the roof, dazed, wings
##   flailing, open to the sword for a few seconds before it takes off again.
## - Half beaten it flies faster and flings more feathers.

enum State { PERCH, SCREECH, CIRCLE, SWOOP_WINDUP, SWOOP, CLIMB, FEATHERS, FLINCH, PULLED, GROUNDED, TAKEOFF, DEAD }

## Title card and music when it wakes ("" = none, as for a mini-boss).
@export var title := "CORVAX"
@export var subtitle := "THE HARVEST CROW"
@export var music := "boss_battle"
## How it circles: radius and height over its roost.
@export var circle_r := 9.0
@export var circle_h := 6.5
## What it flings (Skyreach's wyvern throws icicles).
@export var missile_mesh := "res://assets/models/feather_mesh.tres"
const SWOOP_H := 1.3

@export var notice_range := 15.0

var state := State.PERCH
var _t := 0.0
var _angle := 0.0
var _plan := 4.0
var _floor_y := 0.0
var _swoop_from := Vector3.ZERO
var _swoop_dir := Vector3.FORWARD
var _thrown := 0
var _ground_hits := 0
var _phase2 := false
var _flap_t := 0.0


func _ready() -> void:
	corpse_time = 2.5
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 8.0
	add_to_group("bosses")


## The middle of the roof it circles (where it was placed).
func _centre() -> Vector3:
	return Vector3(_home.x, _floor_y, _home.z)


func is_grounded() -> bool:
	return state == State.GROUNDED


var _found_floor := false


func _physics_process(delta: float) -> void:
	if not _found_floor:
		# The roof under its perch.
		_found_floor = true
		var q := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 20.0, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		_floor_y = hit.position.y if not hit.is_empty() else global_position.y - 3.0
	if _dead:
		velocity.y = maxf(velocity.y - 18.0 * delta, -12.0)
		if global_position.y <= _floor_y + 0.6:
			velocity = Vector3.ZERO
			global_position.y = _floor_y + 0.6
		move_and_slide()
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var rate := 1.35 if _phase2 else 1.0
	match state:
		State.PERCH:
			velocity = Vector3.ZERO
			model.play(&"hover", 0.2)
			if alive and global_position.distance_to(p.global_position) < notice_range:
				_go(State.SCREECH)
		State.SCREECH:
			velocity = Vector3.ZERO
			if alive:
				_turn_to(p.global_position, 120.0, delta)
			if _t >= 1.4:
				_plan = 3.0
				_angle = atan2(global_position.z - _centre().z, global_position.x - _centre().x)
				_go(State.CIRCLE)
		State.CIRCLE:
			_angle += 0.55 * rate * delta
			var want := _centre() + Vector3(cos(_angle) * circle_r, circle_h, sin(_angle) * circle_r)
			_fly_to(want, 9.0 * rate, delta)
			# Facing along the circle.
			facing_yaw = _yaw_to(global_position + Vector3(-sin(_angle), 0, cos(_angle)))
			model.play(&"fly", 0.2, rate)
			_flap(delta, 0.9 / rate)
			if _t >= _plan and alive:
				_go(State.SWOOP_WINDUP if _rng.randf() < 0.6 else State.FEATHERS)
		State.SWOOP_WINDUP:
			_fly_to(global_position, 0.0, delta)
			if alive:
				_turn_to(p.global_position, 240.0, delta)
			if _t >= 0.8 / rate:
				_swoop_from = global_position
				var aim := p.global_position + Vector3.UP * SWOOP_H if alive else _centre()
				_swoop_dir = (aim - global_position).normalized()
				_go(State.SWOOP)
		State.SWOOP:
			# Down the line to just over the roof, then skimming on past him.
			var v := _swoop_dir * 15.0 * rate
			if global_position.y <= _floor_y + SWOOP_H and v.y < 0.0:
				v.y = 0.0
				_swoop_dir.y = 0.0
				_swoop_dir = _swoop_dir.normalized()
			velocity = v
			facing_yaw = _yaw_to(global_position + Vector3(v.x, 0, v.z))
			if attack_hitbox and not attack_hitbox.active and global_position.y < _floor_y + 3.0:
				attack_hitbox.activate()
			var out := Vector2(global_position.x - _centre().x, global_position.z - _centre().z).length()
			if _t >= 2.4 or (out > circle_r + 2.0 and _t > 0.6) or is_on_wall():
				_go(State.CLIMB)
		State.CLIMB:
			_angle = atan2(global_position.z - _centre().z, global_position.x - _centre().x)
			var want := _centre() + Vector3(cos(_angle) * circle_r, circle_h, sin(_angle) * circle_r)
			_fly_to(want, 8.0, delta)
			model.play(&"fly", 0.15, 1.3)
			_flap(delta, 0.6)
			if global_position.distance_to(want) < 1.0 or _t > 2.5:
				_plan = _rng.randf_range(2.5, 4.5) / rate
				_go(State.CIRCLE)
		State.FEATHERS:
			_fly_to(global_position, 0.0, delta)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			var count := 5 if _phase2 else 3
			if _t >= 0.6 + _thrown * 0.4 and _thrown < count:
				_throw_feather(p)
			if _t >= 0.8 + count * 0.4:
				_plan = _rng.randf_range(2.5, 4.0) / rate
				_go(State.CIRCLE)
		State.FLINCH:
			_fly_to(global_position + Vector3.UP * 0.5, 2.0, delta)
			if _t >= 0.5:
				_go(State.CLIMB)
		State.PULLED:
			# Dragged down along the chain toward the hero; it crashes in front of him.
			var target := (p.global_position + _flat_to(global_position).normalized() * 3.0) if alive else _centre()
			target.y = _floor_y + 0.5
			_fly_to(target, 16.0, delta)
			if global_position.distance_to(target) < 0.8 or _t > 1.4:
				global_position.y = _floor_y + 0.5
				Sfx.play("boss_stomp", -2.0, 0.0, 1.2)
				if alive and p.camera_rig:
					p.camera_rig.shake(0.15, 0.4)
				_go(State.GROUNDED)
		State.GROUNDED:
			velocity = Vector3.ZERO
			if _t >= 4.5 or _ground_hits >= 3:
				_go(State.TAKEOFF)
		State.TAKEOFF:
			velocity = Vector3(0, 4.0, 0)
			_flap(delta, 0.4)
			if _t >= 1.0:
				_go(State.CLIMB)
	move_and_slide()
	rotation.y = facing_yaw


## Eases toward `want` at up to `speed` m/s.
func _fly_to(want: Vector3, speed: float, delta: float) -> void:
	var to := want - global_position
	var v := to.limit_length(speed) if to.length() > 0.05 else Vector3.ZERO
	velocity = velocity.lerp(v, 1.0 - exp(-4.0 * delta))


func _flap(delta: float, period: float) -> void:
	_flap_t += delta
	if _flap_t >= period:
		_flap_t = 0.0
		Sfx.play("wing_flap", -2.0, 0.08, 0.5)


func _throw_feather(p: PlayerController) -> void:
	_thrown += 1
	if p == null:
		return
	var from := global_position + _forward() * 1.2
	var f := Feather.new()
	f.mesh_path = missile_mesh
	get_parent().add_child(f)
	f.launch(from, (p.global_position + Vector3.UP * 1.0) - from, self)
	Sfx.play("boomerang_throw", -4.0, 0.08, 0.7)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SWOOP:
		attack_hitbox.deactivate()
	match s:
		State.SCREECH:
			model.play(&"screech", 0.1, 1.0, true)
			Sfx.play("keese_cry", 0.0, 0.0, 0.45)
			if title != "":
				Cutscene.boss_intro(self, title, subtitle, music, 0.0, 8.0)
			elif music != "":
				World.play_track(music)
			elif not has_meta("battle"):
				# A wyvern on its own (no name card): a mini-boss.
				set_meta("battle", "miniboss")
				World.start_battle("miniboss")
		State.SWOOP_WINDUP:
			model.play(&"screech", 0.1, 1.4, true)
			Sfx.play("keese_cry", -2.0, 0.05, 0.5)
		State.SWOOP:
			model.play(&"swoop", 0.08)
			Sfx.play("heavy_swing", -2.0, 0.05, 0.6)
		State.FEATHERS:
			_thrown = 0
			model.play(&"hover", 0.1)
		State.FLINCH:
			model.play(&"hover", 0.05, 1.6)
		State.PULLED:
			model.play(&"swoop", 0.05)
			Sfx.play("keese_cry", -2.0, 0.0, 0.6)
		State.GROUNDED:
			_ground_hits = 0
			model.play(&"grounded", 0.1)
		State.TAKEOFF:
			model.play(&"hover", 0.1, 1.5)
			Sfx.play("wing_flap", 0.0, 0.0, 0.4)


## The Hookshot bites into it: down it comes.
func hookshot_hit(_h: Node3D) -> void:
	if _dead or state in [State.PERCH, State.GROUNDED, State.PULLED, State.TAKEOFF]:
		return
	_go(State.PULLED)


## An arrow or the boomerang only makes it flinch in the air.
func boomerang_hit(_b: Node3D) -> void:
	if state in [State.CIRCLE, State.FEATHERS, State.SWOOP_WINDUP, State.CLIMB]:
		_go(State.FLINCH)


## The sword only bites while it is down.
func _guard(info: HitInfo) -> int:
	if state == State.GROUNDED:
		return Hurtbox.Result.HIT
	if state in [State.CIRCLE, State.FEATHERS, State.SWOOP_WINDUP, State.CLIMB] and not (info.attacker is PlayerController and (info.attacker as PlayerController).state in [PlayerController.State.ATTACK, PlayerController.State.JUMPSLASH]):
		_go(State.FLINCH)
	Sfx.play("shield_block", -6.0, 0.05, 1.4)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	_ground_hits += 1
	Sfx.play("boss_hurt", -2.0, 0.05, 1.3)
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	Sfx.play("boss_die", 0.0)
	Fragments.burst(get_parent(), load("res://assets/models/feather_mesh.tres"), global_position + Vector3.UP * 0.5, 24, 4.0, 5.0, 2.4, 2.0)
	model.play(&"death", 0.05, 1.0, true)
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "scale", Vector3.ONE * 0.01, 0.8)
	tween.tween_callback(queue_free)
