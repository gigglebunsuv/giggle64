class_name SiegeOgre
extends Enemy
## Grukk the Siegebreaker, master of Westmarch Fortress (Chapter IV): an ogre
## in siege iron with a battering ram for a club, the one that broke the
## fortress gate. His armor turns every blade, but:
## - he CHARGES at the hero across the yard, head down. If he ploughs into a
##   wall, a pillar or a Sapphire Staff block, he is knocked senseless to
##   one knee (DAZED): now the gaps in his iron are open to the sword;
## - a bomb's blast (or a Mirror Shield's returned bolt) staggers him too;
## - close in, he raises the ram and SLAMS it down: the ground shakes (a
##   ring of rubble round the blow); keep back or be thrown;
## - wounded, he hurls burning barrels (they burst into flame where they land).

enum State { WAIT, ROAR, STALK, SLAM_WINDUP, SLAM, CHARGE_WINDUP, CHARGE, DAZED, THROW, RECOVER, HURT, DEAD }

const TITLE := "GRUKK"
const SUBTITLE := "THE SIEGEBREAKER"
const SLAM_RADIUS := 4.0
const CHARGE_SPEED := 11.0
const DAZE_TIME := 4.0

var state := State.WAIT
var _t := 0.0
var _plan := 1.4
var _dir := Vector3.FORWARD
var _floor_y := 0.0


func _ready() -> void:
	corpse_time = 2.6
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 10.0
	_floor_y = global_position.y


func is_dazed_down() -> bool:
	return state == State.DAZED


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	var wild := health.health < health.max_health / 2
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			_brake(delta)
			if alive and dist < 14.0 and absf(p.global_position.y - global_position.y) < 3.0:
				_go(State.ROAR)
		State.ROAR:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 2.6:
				_go(State.STALK)
		State.STALK:
			if not alive:
				_brake(delta)
				model.play(&"idle", 0.2)
			else:
				_turn_to(p.global_position, 110.0, delta)
				if dist > 3.2:
					var v := _forward() * (2.4 if wild else 1.9)
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.15, 0.7)
				else:
					_brake(delta)
					model.play(&"idle", 0.2)
				if _t >= _plan:
					_choose(dist, wild)
		State.SLAM_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 60.0, delta)
			if _t >= 0.75:
				_go(State.SLAM)
		State.SLAM:
			_brake(delta)
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.2 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.2:
					attack_hitbox.deactivate()
			if _t >= 0.08 and _t - delta < 0.08:
				_quake()
			if _t >= 0.5:
				_go(State.RECOVER)
		State.CHARGE_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.9:
				_dir = _forward()
				_go(State.CHARGE)
		State.CHARGE:
			var v := _dir * CHARGE_SPEED
			velocity.x = v.x
			velocity.z = v.z
			if attack_hitbox and not attack_hitbox.active:
				attack_hitbox.activate()
			if _t >= 2.6:
				_go(State.RECOVER)
		State.DAZED:
			_brake(delta, 20.0)
			if _t >= DAZE_TIME:
				_go(State.RECOVER)
		State.THROW:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 160.0, delta)
			if _t >= 0.3 and _t - delta < 0.3 and p:
				_barrel(p.global_position)
			if _t >= 0.8:
				_plan = randf_range(1.0, 1.8)
				_go(State.STALK)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.9:
				_plan = randf_range(1.0, 1.8)
				_go(State.STALK)
		State.HURT:
			_brake(delta)
			if _t >= 0.5:
				_go(State.DAZED if stun_left > 0.0 else State.STALK)
	_fall(delta)
	move_and_slide()
	if state == State.CHARGE and _t > 0.25:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var n := c.get_normal()
			if absf(n.y) < 0.5 and n.dot(_dir) < -0.5:
				var hit := c.get_collider()
				if hit is SapphireBlock:
					(hit as SapphireBlock).shatter()
				_crash()
				break
	rotation.y = facing_yaw


func _choose(dist: float, wild: bool) -> void:
	var r := randf()
	if dist < 3.6 and r < 0.6:
		_go(State.SLAM_WINDUP)
	elif dist > 6.0 and r < 0.7:
		_go(State.CHARGE_WINDUP)
	elif wild and r < 0.85:
		_go(State.THROW)
	else:
		_go(State.CHARGE_WINDUP)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s not in [State.SLAM, State.CHARGE]:
		attack_hitbox.deactivate()
	match s:
		State.ROAR:
			model.play(&"alert", 0.1, 0.6, true)
			Sfx.play("ogre_roar", 0.0, 0.0)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 2.6, 9.0)
		State.SLAM_WINDUP:
			model.play(&"windup", 0.08, 0.7, true)
			Sfx.play("heavy_swing", -4.0, 0.05, 0.5)
		State.SLAM:
			model.play(&"attack", 0.02, 1.0, true)
		State.CHARGE_WINDUP:
			model.play(&"windup", 0.1, 0.5, true)
			Sfx.play("ogre_roar", -6.0, 0.05, 1.2)
		State.CHARGE:
			model.play(&"charge", 0.1)
			Sfx.play("boss_stomp", -2.0, 0.05, 0.8)
		State.DAZED:
			model.play(&"kneel", 0.15)
			Sfx.play("boss_hurt", -2.0, 0.05, 0.6)
		State.THROW:
			model.play(&"throw", 0.06, 1.0, true)
		State.RECOVER:
			model.play(&"recover", 0.08, 0.7, true)
		State.HURT:
			model.play(&"hurt", 0.02, 0.8, true)


## He ploughs into something solid: down on one knee, seeing stars.
func _crash() -> void:
	velocity = -_dir * 3.0
	Sfx.play("wall_hit_hard", 2.0, 0.0, 0.5)
	Sfx.play("quake_rumble", -2.0, 0.0)
	GameManager.rumble(0.9, 0.4)
	var p := GameManager.player
	if p and p.camera_rig:
		p.camera_rig.shake(0.25, 0.5)
	stun_left = DAZE_TIME
	_go(State.DAZED)


func _quake() -> void:
	var at := global_position + _forward() * 2.4
	Sfx.play("mallet_smash", 2.0, 0.0, 0.6)
	SpellEffect.make(get_parent(), "quake", at)
	GameManager.rumble(0.7, 0.3)
	var p := GameManager.player
	if p and not p.is_dead() and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < SLAM_RADIUS and absf(p.global_position.y - global_position.y) < 1.5:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 8.0
		info.unblockable = true
		info.attacker = self
		info.source_position = at
		p.take_hit(info)


## A burning barrel, lobbed at `to`: it bursts into flame where it lands.
func _barrel(to: Vector3) -> void:
	var orb := Rock.new()
	orb.mesh_path = "res://assets/models/fire_orb_mesh.tres"
	orb.damage = 2
	orb.speed = 9.0
	orb.life = 2.2
	orb.burst_tint = Color(2.0, 1.1, 0.4)
	get_parent().add_child(orb)
	var aim := (to - global_position)
	aim.y = 0.0
	orb.launch(global_position + Vector3.UP * 2.4 + _forward() * 1.0, aim.normalized(), self)
	Sfx.play("throw", -2.0, 0.05, 0.6)


## His iron turns blades, except while he is down; a bomb staggers him.
func _guard(info: HitInfo) -> int:
	if state in [State.WAIT, State.ROAR]:
		return Hurtbox.Result.IGNORED
	if state == State.DAZED or state == State.HURT:
		return Hurtbox.Result.HIT
	if info.bomb or info.reflected:
		stun_left = DAZE_TIME * 0.7
		return Hurtbox.Result.HIT
	Sfx.play("shield_block", -2.0, 0.08, 0.6)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -2.0, 0.08, 0.8)
	if state != State.DAZED:
		_go(State.HURT)
	else:
		model.play(&"hurt", 0.02, 0.8, true)
		# Still down; back to kneeling once the flinch is over.
		get_tree().create_timer(0.4, false).timeout.connect(func() -> void:
			if is_instance_valid(self) and state == State.DAZED and not _dead:
				model.play(&"kneel", 0.15))


func stun(_seconds: float) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	Sfx.play("boss_die", 0.0, 0.0)
	model.play(&"death", 0.05, 0.7, true)
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "position:y", -2.0, 1.2)
	tween.tween_callback(queue_free)
