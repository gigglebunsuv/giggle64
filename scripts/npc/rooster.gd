class_name Rooster
extends CharacterBody3D
## The rooster of Haven Village (the one that crows the hero awake), after
## OoT's cuccos (En_Niw): he pecks about near his home, scurries off when
## chased, and squawks and flutters when struck. Strike him too often
## (ANGER_HITS) and he crows a terrible crow: a flock of roosters comes
## swooping down out of the sky at the hero for a while (OoT's cucco revenge,
## EnNiw_SpawnAttackNiw), each peck half a heart. He calms down afterward.

const ANGER_HITS := 5
const FLOCK := 9
const FLOCK_TIME := 9.0
const WANDER_SPEED := 0.9
const FLEE_SPEED := 3.6
const NOTICE := 3.0
const GRAVITY := 14.0

enum State { PECK, WALK, FLEE, FLUTTER, CROW }

var state := State.PECK
var hits := 0
## A flock is out (the HUD-free warning is the crow itself).
var angry := false
var _t := 0.0
var _home := Vector3.ZERO
var _goal := Vector3.ZERO
var _mesh: MeshInstance3D
var _flock: Array[Node3D] = []
var _flock_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_home = global_position
	_goal = _home
	add_to_group("roosters")
	collision_layer = 4
	collision_mask = 1
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/rooster_mesh.tres")
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.18
	cap.height = 0.5
	cs.shape = cap
	cs.position = Vector3(0, 0.25, 0)
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hbox := BoxShape3D.new()
	hbox.size = Vector3(0.5, 0.55, 0.55)
	hcs.shape = hbox
	hcs.position = Vector3(0, 0.3, 0)
	hb.add_child(hcs)
	add_child(hb)


func take_hit(info: HitInfo) -> int:
	if not (info.attacker is PlayerController) or state == State.CROW:
		return Hurtbox.Result.IGNORED
	hits += 1
	Sfx.play("cluck", 0.0, 0.1, 1.3)
	var away := global_position - info.source_position
	away.y = 0.0
	velocity = away.normalized() * 4.0 + Vector3.UP * 3.5
	_set_state(State.FLUTTER)
	if hits >= ANGER_HITS and not angry:
		_set_state(State.CROW)
	return Hurtbox.Result.HIT


func _set_state(s: State) -> void:
	state = s
	_t = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var p := GameManager.player
	var to_p := (p.global_position - global_position) if is_instance_valid(p) else Vector3(99, 0, 0)
	to_p.y = 0.0
	match state:
		State.PECK:
			_brake(delta)
			_mesh.rotation.x = 0.35 if fmod(_t, 0.8) < 0.2 else 0.0
			if to_p.length() < NOTICE and is_instance_valid(p) and p.speed_oot > 2.0:
				_set_state(State.FLEE)
			elif _t > _rng.randf_range(1.5, 3.0):
				var a := _rng.randf() * TAU
				_goal = _home + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.5, 3.0)
				_set_state(State.WALK)
		State.WALK:
			_mesh.rotation.x = 0.0
			_steer(_goal - global_position, WANDER_SPEED, delta)
			if Vector2(global_position.x - _goal.x, global_position.z - _goal.z).length() < 0.3 or _t > 4.0:
				_set_state(State.PECK)
			elif to_p.length() < NOTICE and is_instance_valid(p) and p.speed_oot > 2.0:
				_set_state(State.FLEE)
		State.FLEE:
			_steer(-to_p, FLEE_SPEED, delta)
			if fmod(_t, 0.5) < delta:
				Sfx.play("cluck", -8.0, 0.1)
			if to_p.length() > NOTICE * 2.0 or _t > 3.0:
				_set_state(State.PECK)
		State.FLUTTER:
			_mesh.rotation.z = sin(_t * 30.0) * 0.3
			if _t > 0.6 and is_on_floor():
				_mesh.rotation.z = 0.0
				_set_state(State.FLEE)
		State.CROW:
			_brake(delta)
			_mesh.rotation.x = -0.4
			if _t < delta * 1.5:
				Sfx.play("rooster_angry", 2.0, 0.0)
			if _t > 1.2:
				_mesh.rotation.x = 0.0
				_call_flock()
				_set_state(State.FLEE)
	move_and_slide()
	_update_flock(delta)


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)


func _steer(dir: Vector3, speed: float, delta: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		_brake(delta)
		return
	var want := dir.normalized() * speed
	velocity.x = move_toward(velocity.x, want.x, 12.0 * delta)
	velocity.z = move_toward(velocity.z, want.z, 12.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 1.0 - exp(-10.0 * delta))


## The flock: roosters swooping in from all round, high up, at the hero.
func _call_flock() -> void:
	angry = true
	Progress.set_flag("rooster:angry")
	_flock_t = FLOCK_TIME
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	for i in FLOCK:
		var bird := MeshInstance3D.new()
		bird.name = "AngryRooster%d" % i
		bird.mesh = _mesh.mesh
		bird.set_meta("delay", i * 0.45)
		bird.set_meta("peck", 0.0)
		get_parent().add_child(bird)
		var a := TAU * i / FLOCK + _rng.randf() * 0.4
		bird.global_position = p.global_position + Vector3(cos(a) * 16.0, 7.0 + _rng.randf() * 3.0, sin(a) * 16.0)
		bird.visible = false
		_flock.append(bird)


func _update_flock(delta: float) -> void:
	if _flock.is_empty():
		return
	_flock_t -= delta
	var p := GameManager.player
	for bird in _flock:
		if not is_instance_valid(bird):
			continue
		var wait: float = bird.get_meta("delay") - delta
		bird.set_meta("delay", wait)
		if wait > 0.0:
			continue
		bird.visible = true
		var target := (p.global_position + Vector3.UP * 1.0) if is_instance_valid(p) else bird.global_position
		if _flock_t <= 0.0:
			# Their temper spent, they fly off up and away.
			target = bird.global_position + (bird.global_position - target).normalized() * 5.0 + Vector3.UP * 4.0
		var to := target - bird.global_position
		var step := minf(to.length(), 7.5 * delta)
		bird.global_position += to.normalized() * step if to.length() > 0.01 else Vector3.ZERO
		bird.rotation.y = atan2(-to.x, -to.z)
		bird.rotation.z = sin(Time.get_ticks_msec() * 0.04 + bird.get_index()) * 0.4
		var peck: float = bird.get_meta("peck") - delta
		bird.set_meta("peck", peck)
		if _flock_t > 0.0 and is_instance_valid(p) and to.length() < 0.7 and peck <= 0.0:
			bird.set_meta("peck", 1.2)
			var hit := HitInfo.new()
			hit.damage = 1
			hit.knockback = 2.0
			hit.attacker = self
			hit.source_position = bird.global_position
			p.take_hit(hit)
			Sfx.play("cluck", -2.0, 0.1, 1.2)
	if _flock_t < -3.0:
		for bird in _flock:
			if is_instance_valid(bird):
				bird.queue_free()
		_flock.clear()
		angry = false
		hits = 0
