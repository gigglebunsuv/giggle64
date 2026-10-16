class_name Mara
extends Enemy
## MARA, the Scourge of Bunsriel: master of Ridge Keep, fought one-on-one at
## the top of the black falls (Beta 1.4.0). Once a knight who drowned at the
## Ridge holding a king's road; now the dead answer to her. Her war-glaive
## held across her body turns any blow from in front. Her fight is built
## round the PARRY:
## - SWEEP: the glaive drawn back (a ring on the ground), then a wide cut.
##   Block it and she presses on; PARRY it and she reels, guard wide open
##   (STAGGER). A Shield Bash as she winds up knocks her off balance too.
## - THRUST: a lunge straight down a line (a strip on the ground). Step aside
##   and she overreaches (OPEN) for a moment.
## - Twice (at two thirds and one third of her strength) she raises the
##   glaive and the drowned climb out of the black water (two Stalfos).
## - Half beaten, she grows quicker and adds the SLAM: the glaive brought
##   down overhead, the stone shaking round it (no shield stops it); the blade
##   bites deep and she must wrench it free (STUCK).
## Blows from behind always land, as do bombs; a greatsword's cleave knocks
## her guard aside for a breath. Beaten, Story.mara_falls.

enum State { WAIT, WAKE, WALK, SWEEP_WINDUP, SWEEP, THRUST_WINDUP, THRUST, OPEN, SLAM_WINDUP, SLAM, STUCK, STAGGER, SUMMON, RECOVER, DEAD }

const TITLE := "MARA"
const SUBTITLE := "THE SCOURGE OF BUNSRIEL"
const STAGGER_TIME := 2.6
const OPEN_TIME := 1.3
const STUCK_TIME := 1.8
const SLAM_RADIUS := 3.6
const THRUST_SPEED := 11.0
const THRUST_LEN := 0.5
const SUMMON_SCENE := "res://scenes/enemies/stalfos.tscn"

var state := State.WAIT
var _t := 0.0
var _plan := 1.2
var _summons := 0
var _raised: Array[Node] = []
var _thrust_dir := Vector3.FORWARD
var _phase2 := false
var _tell: Node3D


func _ready() -> void:
	corpse_time = 3.0
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 7.0


func target_height() -> float:
	return 1.7


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	var quick := 1.25 if _phase2 else 1.0
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			_brake(delta)
			if alive and dist < 13.0 and absf(p.global_position.y - global_position.y) < 3.0:
				_go(State.WAKE)
		State.WAKE:
			_brake(delta)
			if _t >= 2.4:
				_go(State.WALK)
		State.WALK:
			if alive:
				_turn_to(p.global_position, 120.0 * quick, delta)
				if dist > 3.0:
					var v := _forward() * 2.4 * quick
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.2, 0.9 * quick)
				else:
					_brake(delta)
					model.play(&"guard", 0.15)
			var want := _summon_due()
			if want:
				_go(State.SUMMON)
			elif _t >= _plan / quick:
				if _phase2 and randf() < 0.3:
					_go(State.SLAM_WINDUP)
				elif dist > 4.5 or randf() < 0.3:
					_go(State.THRUST_WINDUP)
				else:
					_go(State.SWEEP_WINDUP)
		State.SWEEP_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 80.0, delta)
			if _t >= 0.75 / quick:
				_go(State.SWEEP)
		State.SWEEP:
			_brake(delta)
			if attack_hitbox:
				if _t >= 0.08 and _t < 0.3 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.3:
					attack_hitbox.deactivate()
			if _t >= 0.55:
				# Blocked or dodged, she presses on with a lunge.
				_go(State.THRUST_WINDUP if randf() < 0.45 else State.RECOVER)
		State.THRUST_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 140.0, delta)
				_thrust_dir = _forward()
			if _t >= 0.6 / quick:
				_go(State.THRUST)
		State.THRUST:
			var v2 := _thrust_dir * THRUST_SPEED
			velocity.x = v2.x
			velocity.z = v2.z
			if attack_hitbox and not attack_hitbox.active:
				attack_hitbox.activate()
			if _t >= THRUST_LEN or is_on_wall():
				_go(State.OPEN)
		State.OPEN:
			_brake(delta, 10.0)
			if _t >= OPEN_TIME:
				_go(State.RECOVER)
		State.SLAM_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 0.85:
				_go(State.SLAM)
		State.SLAM:
			_brake(delta)
			if _t >= 0.14 and _t - delta < 0.14:
				_quake()
			if _t >= 0.45:
				_go(State.STUCK)
		State.STUCK:
			_brake(delta, 20.0)
			if _t >= STUCK_TIME:
				_go(State.RECOVER)
		State.STAGGER:
			_brake(delta, 8.0)
			if _t >= STAGGER_TIME:
				_go(State.RECOVER)
		State.SUMMON:
			_brake(delta)
			if _t >= 0.7 and _t - delta < 0.7:
				_call_drowned()
			if _t >= 1.6:
				_go(State.WALK)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.6:
				_plan = randf_range(0.7, 1.4)
				_go(State.WALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _summon_due() -> bool:
	var frac := float(health.health) / float(maxi(health.max_health, 1))
	return (_summons == 0 and frac <= 0.66) or (_summons == 1 and frac <= 0.33)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s not in [State.SWEEP, State.THRUST]:
		attack_hitbox.deactivate()
	if is_instance_valid(_tell):
		_tell.queue_free()
	match s:
		State.WAKE:
			model.play(&"point", 0.3)
			Sfx.play("undead_rise", -2.0, 0.0, 0.7)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "mara_battle", 1.9, 6.5)
		State.SWEEP_WINDUP:
			model.play(&"windup", 0.1, 1.0, true)
			Sfx.play("heavy_swing", -8.0, 0.05, 0.8)
			_tell = Telegraph.ring(get_parent(), global_position + _forward() * 1.8, 2.6, 0.8)
		State.SWEEP:
			model.play(&"sweep", 0.04, 1.0, true)
			Sfx.play("heavy_swing", 0.0, 0.05, 0.75)
		State.THRUST_WINDUP:
			model.play(&"windup", 0.1, 0.8, true)
			Sfx.play("bone_rattle", -6.0, 0.05, 1.2)
			_tell = Telegraph.strip(get_parent(), global_position + _forward() * 1.0, _forward(), THRUST_SPEED * THRUST_LEN + 1.5, 1.4, 0.65)
		State.THRUST:
			model.play(&"thrust", 0.03, 1.0, true)
			Sfx.play("heavy_swing", -2.0, 0.05, 1.1)
		State.OPEN:
			model.play(&"stagger", 0.1, 0.8)
		State.SLAM_WINDUP:
			model.play(&"raise", 0.1)
			Sfx.play("undead_rise", -6.0, 0.05, 1.2)
			_tell = Telegraph.ring(get_parent(), global_position + _forward() * 2.2, SLAM_RADIUS, 0.9)
		State.SLAM:
			model.play(&"slam", 0.03, 1.0, true)
		State.STUCK:
			model.play(&"kneel", 0.2)
			Sfx.play("wall_hit_hard", 0.0, 0.0, 0.6)
		State.STAGGER:
			model.play(&"stagger", 0.08, 1.0, true)
			Sfx.play("boss_hurt", -2.0, 0.05, 1.1)
		State.SUMMON:
			model.play(&"raise", 0.15)
			Sfx.play("undead_rise", 2.0, 0.0, 0.8)
		State.RECOVER:
			model.play(&"guard", 0.15)


func _quake() -> void:
	var at := global_position + _forward() * 2.2
	Sfx.play("mallet_smash", 3.0, 0.0, 0.55)
	SpellEffect.make(get_parent(), "quake", at)
	Telegraph.shockwave(get_parent(), at, SLAM_RADIUS + 0.4, 0.4)
	GameManager.rumble(0.8, 0.4)
	var p := GameManager.player
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 0.4)
	if p and not p.is_dead() and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < SLAM_RADIUS \
			and absf(p.global_position.y - global_position.y) < 1.5:
		var info := HitInfo.new()
		info.damage = 3
		info.knockback = 8.0
		info.unblockable = true
		info.attacker = self
		info.source_position = at
		p.take_hit(info)


## The drowned climb out of the black water at either side of her.
func _call_drowned() -> void:
	_summons += 1
	var ps := load(SUMMON_SCENE) as PackedScene
	if ps == null:
		return
	for sx: float in [-1.0, 1.0]:
		var e: Node3D = ps.instantiate()
		get_parent().add_child(e)
		var side := Vector3(-_forward().z, 0, _forward().x) * sx * 5.0
		e.global_position = global_position + side
		e.set("facing_yaw", facing_yaw)
		e.set("tint", Color(0.55, 0.62, 0.8))
		Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), e.global_position, 10, 3.0, 3.0, 0.6, 0.6, Color(0.1, 0.12, 0.16))
		_raised.append(e)


## Her blow turned by the Parry: she reels, wide open.
func parried(_by: Node3D) -> void:
	if state in [State.SWEEP, State.THRUST]:
		var v := -_forward() * 3.0
		velocity.x = v.x
		velocity.z = v.z
		_go(State.STAGGER)


func _bashed(info: HitInfo) -> int:
	if state in [State.SWEEP_WINDUP, State.THRUST_WINDUP]:
		_go(State.OPEN)
		var away := _flat_to(info.source_position) * -1.0
		velocity = away.normalized() * 2.5 if away.length() > 0.01 else Vector3.ZERO
		return Hurtbox.Result.HIT
	Sfx.play("shield_block", -4.0, 0.05, 0.9)
	return Hurtbox.Result.BLOCKED


func _guard(info: HitInfo) -> int:
	if state in [State.WAIT, State.WAKE]:
		return Hurtbox.Result.IGNORED
	if state in [State.STAGGER, State.OPEN, State.STUCK, State.SUMMON] or info.bomb or info.kind == "thrust":
		return Hurtbox.Result.HIT
	if info.cleave and state in [State.WALK, State.RECOVER]:
		_go(State.OPEN)
		return Hurtbox.Result.HIT
	var to := _flat_to(info.source_position)
	if to.length() > 0.01 and _forward().dot(to.normalized()) < -0.25:
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -2.0, 0.08, 1.1)
	if state == State.WALK and randf() < 0.5:
		_go(State.SWEEP_WINDUP)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -2.0, 0.08, 1.2)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.4, 6, 2.6, 2.6, 0.5, 0.6, Color(0.4, 0.5, 0.9))


func stun(_seconds: float) -> void:
	pass


func daze(_seconds: float, _ice := false) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	if is_instance_valid(_tell):
		_tell.queue_free()
	Sfx.play("boss_die", 0.0, 0.0, 1.0)
	model.play(&"kneel", 0.2)
	for e in _raised:
		if is_instance_valid(e):
			e.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and is_instance_valid(e) and e is Enemy:
			(e as Enemy).queue_free()
	await get_tree().create_timer(1.4, false).timeout
	if is_instance_valid(self):
		await Story.mara_falls(self)
