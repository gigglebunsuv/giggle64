class_name EnemyController
extends Enemy
## Cinder Goblin AI: a small finite-state machine.
##
## idle/patrol -> alert -> chase -> windup (telegraph) -> attack -> recover -> chase.
## Sword hits interrupt it; a blocked attack leaves it stunned and open.

enum State { IDLE, PATROL, ALERT, CHASE, WINDUP, ATTACK, RECOVER, HURT, STUNNED, RETURN, DEAD }

## At most this many enemies may be winding up / attacking at once, so the
## player is never swarmed (enemies take turns, as in OoT).
const MAX_ATTACKERS := 2
static var _active_attackers := 0

@export_group("Senses")
@export var detection_range := 9.0
@export var close_detection_range := 4.5
@export_range(0.0, 180.0) var view_half_angle_deg := 75.0
@export var lose_range := 15.0
@export var leash_range := 20.0

@export_group("Movement")
@export var chase_speed := 2.8
@export var patrol_speed := 1.1
@export var patrol_radius := 3.5
@export var acceleration := 14.0
@export var turn_speed_deg := 300.0

@export_group("Attack")
@export var attack_range := 1.7
@export var attack_damage := 1
@export var alert_time := 0.5
@export var windup_time := 0.6
@export var attack_time := 0.25
@export var recover_time := 0.8
@export var attack_cooldown := 0.7
@export var lunge_speed := 3.5

@export_group("Reactions")
@export var hurt_time := 0.4
@export var stun_time := 1.1
@export var knockback_scale := 1.0

var state: State = State.IDLE

var _state_time := 0.0
var _cooldown := 0.0
var _patrol_point := Vector3.ZERO
var _idle_wait := 2.0
var _has_token := false
var _stuck_time := 0.0
var _avoid_dir := 0.0


func _ready() -> void:
	corpse_time = 1.6
	super._ready()
	_idle_wait = _rng.randf_range(1.0, 3.0)
	attack_hitbox.damage = attack_damage


func _exit_tree() -> void:
	_release_token()


func is_targetable() -> bool:
	return state != State.DEAD and is_inside_tree()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	var player := _player()
	var to_player := Vector3.ZERO
	var dist := INF
	if player:
		to_player = player.global_position - global_position
		to_player.y = 0.0
		dist = to_player.length()
	var player_valid := player != null and not player.is_dead()

	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle")
			if player_valid and _can_see(player, dist, to_player):
				_set_state(State.ALERT)
			elif _state_time > _idle_wait:
				var a := _rng.randf_range(0.0, TAU)
				_patrol_point = _home + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(1.0, patrol_radius)
				_set_state(State.PATROL)
		State.PATROL:
			_move_toward(_patrol_point, patrol_speed, delta)
			model.play(&"walk", 0.1, 0.6)
			if player_valid and _can_see(player, dist, to_player):
				_set_state(State.ALERT)
			elif _flat_dist(_patrol_point) < 0.4 or _state_time > 6.0:
				_idle_wait = _rng.randf_range(1.5, 3.5)
				_set_state(State.IDLE)
		State.ALERT:
			_brake(delta)
			if player:
				_turn_toward(player.global_position, delta * 2.0)
			if _state_time >= alert_time:
				_set_state(State.CHASE)
		State.CHASE:
			if not player_valid or dist > lose_range or _flat_dist(_home) > leash_range:
				_set_state(State.RETURN)
			elif dist <= attack_range:
				_brake(delta)
				_turn_toward(player.global_position, delta)
				model.play(&"idle")
				if _cooldown <= 0.0 and _facing_dot(to_player) > 0.8 and _take_token():
					_set_state(State.WINDUP)
			else:
				_move_toward(player.global_position, chase_speed, delta)
				model.play(&"walk", 0.1, 1.0)
		State.WINDUP:
			_brake(delta)
			if player:
				_turn_toward(player.global_position, delta * 0.6)
			if _state_time >= windup_time:
				_set_state(State.ATTACK)
		State.ATTACK:
			var f := _forward() * maxf(lunge_speed * (1.0 - _state_time / attack_time), 0.0)
			velocity.x = f.x
			velocity.z = f.z
			if _state_time >= attack_time:
				_set_state(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _state_time >= recover_time:
				_cooldown = attack_cooldown
				_set_state(State.CHASE)
		State.HURT:
			_brake(delta, 0.5)
			if _state_time >= hurt_time:
				_set_state(State.CHASE)
		State.STUNNED:
			_brake(delta, 0.5)
			if _state_time >= stun_time:
				_cooldown = attack_cooldown
				_set_state(State.CHASE)
		State.RETURN:
			_move_toward(_home, patrol_speed * 1.6, delta)
			model.play(&"walk", 0.1, 0.8)
			if player_valid and dist < detection_range and _flat_dist(_home) < leash_range * 0.5 and _can_see(player, dist, to_player):
				_set_state(State.ALERT)
			elif _flat_dist(_home) < 0.5:
				_set_state(State.IDLE)
		State.DEAD:
			_brake(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	rotation.y = facing_yaw


func _set_state(new_state: State) -> void:
	var old := state
	if old == State.DEAD:
		return
	state = new_state
	_state_time = 0.0
	if old == State.ATTACK:
		attack_hitbox.deactivate()
	if new_state not in [State.WINDUP, State.ATTACK, State.RECOVER]:
		_release_token()
	match new_state:
		State.ALERT:
			model.play(&"alert", 0.05, 1.0, true)
			Sfx.play("enemy_alert", -6.0)
		State.WINDUP:
			model.play(&"windup", 0.08, 1.0, true)
		State.ATTACK:
			model.play(&"attack", 0.02, 1.0, true)
			attack_hitbox.activate()
			Sfx.play("enemy_attack", -3.0)
		State.RECOVER:
			model.play(&"recover", 0.05, 1.0, true)
		State.HURT:
			model.play(&"hurt", 0.02, 1.0, true)
		State.STUNNED:
			model.play(&"stunned", 0.05, 1.0, true)


# --- Senses & movement --------------------------------------------------------

func _can_see(player: PlayerController, dist: float, to_player: Vector3) -> bool:
	if dist > detection_range or absf(player.global_position.y - global_position.y) > 4.0:
		return false
	if dist > close_detection_range and _facing_dot(to_player) < cos(deg_to_rad(view_half_angle_deg)):
		return false
	var eye := global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(eye, player.global_position + Vector3.UP * 1.0, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _facing_dot(to: Vector3) -> float:
	return _forward().dot(to.normalized()) if to.length() > 0.01 else 1.0


func _move_toward(point: Vector3, speed: float, delta: float) -> void:
	var to := point - global_position
	to.y = 0.0
	var dir := to.normalized() if to.length() > 0.05 else Vector3.ZERO
	dir = (dir + _separation() * 0.8).limit_length(1.0)
	# If blocked by a wall for a moment, sidestep around it.
	if is_on_wall() and dir != Vector3.ZERO:
		_stuck_time += delta
		if _stuck_time > 0.35 and _avoid_dir == 0.0:
			_avoid_dir = 1.0 if _rng.randf() < 0.5 else -1.0
	else:
		_stuck_time = maxf(_stuck_time - delta, 0.0)
		if _stuck_time == 0.0:
			_avoid_dir = 0.0
	if _avoid_dir != 0.0:
		dir = (dir + dir.cross(Vector3.UP) * _avoid_dir * 1.2).normalized()
	var target_v := dir * speed
	velocity.x = move_toward(velocity.x, target_v.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_v.z, acceleration * delta)
	if dir.length() > 0.1:
		_turn_toward(global_position + dir, delta)


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var d: Vector3 = global_position - (other as Node3D).global_position
		d.y = 0.0
		var l := d.length()
		if l > 0.01 and l < 1.6:
			push += d / l * (1.6 - l)
	return push


func _turn_toward(point: Vector3, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	var diff := angle_difference(facing_yaw, atan2(-to.x, -to.z))
	var step := deg_to_rad(turn_speed_deg) * delta
	facing_yaw += clampf(diff, -step, step)


func _brake(delta: float, scale := 1.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * scale * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * scale * delta)


func _take_token() -> bool:
	if _has_token:
		return true
	if _active_attackers >= MAX_ATTACKERS:
		return false
	_active_attackers += 1
	_has_token = true
	return true


func _release_token() -> void:
	if _has_token:
		_has_token = false
		_active_attackers = maxi(_active_attackers - 1, 0)


# --- Damage -------------------------------------------------------------------

## Called by the Hurtbox. Returns a Hurtbox.Result.
func take_hit(info: HitInfo) -> int:
	if state == State.DEAD:
		return Hurtbox.Result.IGNORED
	_frozen_blow(info)
	health.apply_damage(info.damage)
	model.flash(Color(1.0, 0.95, 0.8), 0.08)
	if health.is_dead:
		return Hurtbox.Result.HIT
	Sfx.play("enemy_hurt")
	var away := global_position - info.source_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -_forward()
	velocity.x = away.x * info.knockback * knockback_scale
	velocity.z = away.z * info.knockback * knockback_scale
	if info.attacker:
		_turn_toward(info.attacker.global_position, 10.0)
	_set_state(State.HURT)
	return Hurtbox.Result.HIT


func _on_attack_landed(_hurtbox: Hurtbox, result: int) -> void:
	if result == Hurtbox.Result.BLOCKED:
		# Recoil off the shield and stagger, leaving an opening.
		var back := -_forward() * 3.0
		velocity.x = back.x
		velocity.z = back.z
		_set_state(State.STUNNED)


func _on_died() -> void:
	_dead = true
	_set_state(State.DEAD)
	state = State.DEAD
	attack_hitbox.deactivate()
	_release_token()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 1
	hurtbox.set_deferred("monitorable", false)
	attack_hitbox.set_deferred("monitoring", false)
	model.play(&"death", 0.03, 1.0, true)
	Sfx.play("enemy_death")
	died.emit()
	drop_items()
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "position:y", -0.8, 0.6)
	tween.tween_callback(queue_free)
