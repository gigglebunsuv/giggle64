extends Enemy
## Carapax, the armored abyssal crab: master of the Lake Shrine.
##
## Its fight follows Gohma's in OoT (Boss_Goma): the shell turns every blow;
## the one weak point is the great eye on its stalk. Strike the eye (an arrow,
## the boomerang, or the sword if it can be reached) and the crab is thrown on
## its back, legs kicking, its soft underside open to the sword for a few
## seconds. Its attacks:
## - stalking sideways round the hero, out of reach;
## - a claw raised high and slammed down when he comes close;
## - a lowered charge across the chamber; if it hits a wall it reels, dazed,
##   with its eye drooping low (an easy target);
## - a fan of bubbles that drift after him (the sword or shield pops them).
## At half strength it moves and attacks faster and blows more bubbles.
## Its tells (Telegraph): a band along the floor where a charge will run, a
## ring under the raised claw, and the eye glowing whenever a hit on it
## would throw the crab over.

enum State { WAIT, ROAR, STALK, SNAP_WINDUP, SNAP, RECOVER, CHARGE_WINDUP, CHARGE, DAZED, SPIT, FLIP, FLIPPED, UNFLIP, DEAD }

const TITLE := "CARAPAX"
const SUBTITLE := "ARMORED ABYSSAL CRAB"

var state := State.WAIT
var _t := 0.0
var _plan := 3.0
var _strafe := 1.0
var _flip_hits := 0
var _eye: Node3D
var _eye_hurt: Hurtbox
var _phase2 := false
var _tell: Telegraph
var _eye_glow: Telegraph


func _ready() -> void:
	corpse_time = 2.2
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 8.0
	_eye = model.find_child("Eye", true, false) as Node3D
	var part := EnemyPart.new()
	part.name = "EyePart"
	part.part = "eye"
	part.creature = self
	add_child(part)
	_eye_hurt = Hurtbox.new()
	_eye_hurt.name = "EyeHurtbox"
	_eye_hurt.collision_layer = 16
	_eye_hurt.collision_mask = 0
	_eye_hurt.receiver = part
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.8
	cs.shape = s
	_eye_hurt.add_child(cs)
	_eye_hurt.top_level = true
	add_child(_eye_hurt)


## The lock-on rests on the great eye (its one weak point), so the boomerang,
## arrows and the Hookshot all fly at it.
func aim_point() -> Vector3:
	return _eye.global_position + Vector3.UP * 0.1 if _eye else super.aim_point()


func marker_point() -> Vector3:
	return _eye.global_position + Vector3.UP * 0.75 if _eye else super.marker_point()


func target_height() -> float:
	return _eye.global_position.y - global_position.y if _eye else target_offset


func is_flipped() -> bool:
	return state in [State.FLIP, State.FLIPPED]


func _physics_process(delta: float) -> void:
	if _eye and _eye_hurt:
		_eye_hurt.global_position = _eye.global_position + Vector3.UP * 0.1
	if _dead:
		return
	# The eye glows while a hit on it would throw the crab over.
	var open := _eye != null and not is_flipped() and not (state in [State.WAIT, State.ROAR, State.UNFLIP])
	if open and not is_instance_valid(_eye_glow):
		_eye_glow = Telegraph.glow(get_parent(), _eye.global_position, 0.75, 9999.0, Color(1.0, 0.95, 0.45, 0.32), _eye)
	elif not open and is_instance_valid(_eye_glow):
		_eye_glow.finish()
		_eye_glow = null
	if is_instance_valid(_tell) and state == State.CHARGE_WINDUP:
		_tell.global_position = global_position + _forward() * 6.0 + Vector3.UP * 0.06
		_tell.global_basis = Basis(Vector3.UP, facing_yaw)
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var to := _flat_to(p.global_position) if alive else Vector3.FORWARD
	var dist := to.length()
	var rate := 1.4 if _phase2 else 1.0
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			if alive and dist < 17.0:
				_go(State.ROAR)
		State.ROAR:
			_turn_to(p.global_position, 120.0, delta)
			if _t >= 1.4:
				_plan = 2.0
				_go(State.STALK)
		State.STALK:
			if not alive:
				_brake(delta, 6.0)
				model.play(&"idle", 0.2)
			else:
				_turn_to(p.global_position, 140.0 * rate, delta)
				# Sidle round him, keeping out of his reach.
				var side := Vector3(-to.z, 0, to.x).normalized() * _strafe
				var keep := to.normalized() * clampf(dist - 7.0, -1.0, 1.0)
				var v := (side + keep).normalized() * 2.4 * rate
				velocity.x = move_toward(velocity.x, v.x, 6.0 * delta)
				velocity.z = move_toward(velocity.z, v.z, 6.0 * delta)
				model.play(&"walk", 0.15, rate)
				if is_on_wall():
					_strafe = -_strafe
				if _t >= _plan:
					_choose(dist)
		State.SNAP_WINDUP:
			_brake(delta, 10.0)
			if alive:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 0.7 / rate:
				_go(State.SNAP)
		State.SNAP:
			if attack_hitbox:
				if _t >= 0.04 and _t < 0.16 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.16:
					attack_hitbox.deactivate()
			if _t >= 0.1 and _t - delta < 0.1:
				Sfx.play("boss_stomp", -3.0)
				if alive and p.camera_rig:
					p.camera_rig.shake(0.1, 0.3)
			if _t >= 0.25:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta, 10.0)
			if _t >= 0.6 / rate:
				_go(State.STALK)
		State.CHARGE_WINDUP:
			_brake(delta, 10.0)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.6 / rate:
				_go(State.CHARGE)
		State.CHARGE:
			var v := _forward() * 9.0 * rate
			velocity.x = v.x
			velocity.z = v.z
			if is_on_wall() and _t > 0.15:
				# Slammed into the wall: dazed, eye drooping.
				velocity = -_forward() * 3.0
				Sfx.play("boss_stomp", 0.0, 0.0, 0.8)
				if alive and p.camera_rig:
					p.camera_rig.shake(0.2, 0.5)
				_go(State.DAZED)
			elif _t >= 1.7:
				_go(State.RECOVER)
		State.DAZED:
			_brake(delta, 8.0)
			if _t >= 2.0:
				_go(State.STALK)
		State.SPIT:
			_brake(delta, 10.0)
			if alive:
				_turn_to(p.global_position, 120.0, delta)
			if _t >= 0.35 and _t - delta < 0.35:
				_spit()
			if _t >= 0.6:
				_go(State.STALK)
		State.FLIP:
			_brake(delta, 10.0)
			if _t >= 0.6:
				_go(State.FLIPPED)
		State.FLIPPED:
			_brake(delta, 10.0)
			if _t >= 4.5 or _flip_hits >= 3:
				_go(State.UNFLIP)
		State.UNFLIP:
			if _t >= 0.6:
				_plan = 1.5
				_go(State.STALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _choose(dist: float) -> void:
	if dist < 5.0:
		_go(State.SNAP_WINDUP)
	elif dist > 9.0 and _rng.randf() < 0.55:
		_go(State.CHARGE_WINDUP)
	else:
		_go(State.SPIT)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if is_instance_valid(_tell):
		_tell.finish()
	_tell = null
	if attack_hitbox and s != State.SNAP and s != State.CHARGE:
		attack_hitbox.deactivate()
	match s:
		State.ROAR:
			model.play(&"roar", 0.1, 1.0, true)
			Sfx.play("boss_roar", 0.0, 0.0)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 2.2, 9.0)
			var p := _player()
			if p and p.camera_rig:
				p.camera_rig.shake(0.15, 1.0)
		State.STALK:
			_plan = _rng.randf_range(1.6, 3.2) / (1.4 if _phase2 else 1.0)
			if _rng.randf() < 0.4:
				_strafe = -_strafe
		State.SNAP_WINDUP:
			model.play(&"snap_windup", 0.08, 1.4 if _phase2 else 1.0, true)
			_tell = Telegraph.ring(get_parent(), global_position + _forward() * 2.6, 1.9, 0.7 / (1.4 if _phase2 else 1.0) + 0.1)
		State.SNAP:
			model.play(&"snap", 0.02, 1.0, true)
		State.RECOVER:
			model.play(&"recover", 0.05, 1.0, true)
		State.CHARGE_WINDUP:
			model.play(&"charge_windup", 0.08, 1.0, true)
			Sfx.play("boss_roar", -6.0, 0.05, 1.3)
			_tell = Telegraph.strip(get_parent(), global_position + _forward() * 1.0, _forward(), 10.0, 3.0, 0.6 / (1.4 if _phase2 else 1.0) + 0.05)
		State.CHARGE:
			model.play(&"charge", 0.05)
			if attack_hitbox:
				attack_hitbox.activate()
		State.DAZED:
			model.play(&"idle", 0.1, 0.4)
		State.SPIT:
			model.play(&"spit", 0.06, 1.0, true)
		State.FLIP:
			model.play(&"flip", 0.04, 1.0, true)
			Sfx.play("boss_hurt", -2.0)
			_flip_hits = 0
		State.FLIPPED:
			model.play(&"flipped", 0.05)
		State.UNFLIP:
			model.play(&"unflip", 0.05, 1.0, true)
			Sfx.play("boss_stomp", -4.0)


func _spit() -> void:
	var n := 5 if _phase2 else 3
	Sfx.play("bubble_pop", -2.0, 0.05, 0.5)
	for i in n:
		var a := (float(i) / (n - 1) - 0.5) * deg_to_rad(60.0)
		var dir := _forward().rotated(Vector3.UP, a)
		var b := Bubble.new()
		get_parent().add_child(b)
		b.launch(global_position + Vector3.UP * 1.6 + _forward() * 2.0, dir * 4.0, self)


# --- Damage -------------------------------------------------------------------

## The shell: blows bounce off it, unless it lies on its back.
func _guard(_info: HitInfo) -> int:
	if is_flipped():
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -3.0, 0.08, 0.7)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	_flip_hits += 1
	Sfx.play("boss_hurt", -2.0, 0.08)
	model.play(&"hurt", 0.02, 1.0, true)
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.05, 0.15)


## The eye, struck: thrown onto its back.
func part_hit(part_name: String, info: HitInfo) -> int:
	if part_name != "eye" or _dead or not (info.attacker is PlayerController):
		return Hurtbox.Result.IGNORED
	if is_flipped() or state in [State.WAIT, State.ROAR, State.UNFLIP]:
		return Hurtbox.Result.BLOCKED
	model.flash(Color(1.0, 1.0, 0.7), 0.12)
	_go(State.FLIP)
	return Hurtbox.Result.HIT


func part_boomerang(part_name: String, b: Node3D) -> void:
	var info := HitInfo.new()
	info.attacker = GameManager.player
	info.source_position = b.global_position
	part_hit(part_name, info)


func _die() -> void:
	state = State.DEAD
	if is_instance_valid(_eye_glow):
		_eye_glow.finish()
	_eye_hurt.set_deferred("monitorable", false)
	_eye_hurt.set_deferred("collision_layer", 0)
	World.play_track("")
	Sfx.play("boss_die", 0.0, 0.0)
	model.play(&"death", 0.05, 1.0, true)
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 1.5)
	for i in 6:
		get_tree().create_timer(0.25 * i).timeout.connect(func() -> void:
			if is_inside_tree():
				Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3(randf_range(-1.5, 1.5), 1.5, randf_range(-1.5, 1.5)), 10, 3.0, 4.0, 1.2, 2.0, Color(0.5, 0.7, 1.2)))
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
	tween.tween_callback(queue_free)
