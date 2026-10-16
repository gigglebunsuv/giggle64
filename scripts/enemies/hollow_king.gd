class_name HollowKing
extends Enemy
## The Hollow King, master of the Barrow of Kings (Chapter V): Harrow, the
## king who bargained with the dark for a crown that would never fall, risen
## by Mara in rusted royal plate with a cold green fire for a face. He keeps
## his greatsword up across his body: the blade turns any blow from in front.
## - He sweeps it across the hall (a wide blow; shield it, or roll away).
##   Before the sweep he winds it back: a SHIELD BASH then knocks him off his
##   feet, guard wide open (KNEEL).
## - He slams it down two-handed: the floor shakes round him, and the blade
##   bites so deep into the stone that he must wrench it free (STUCK).
## - Half beaten, he calls two of his sworn knights up out of the floor.
## Beaten, the green fire goes out and he speaks (Story.hollow_king_freed).

enum State { WAIT, WAKE, WALK, SWEEP_WINDUP, SWEEP, SLAM_WINDUP, SLAM, STUCK, KNEEL, RECOVER, SUMMON, DEAD }

const TITLE := "THE HOLLOW KING"
const SUBTITLE := "HARROW, WHO WOULD NOT FALL"
const KNEEL_TIME := 3.6
const STUCK_TIME := 2.4
const SLAM_RADIUS := 4.0
const KNIGHT_SCENE := "res://scenes/enemies/barrow_knight.tscn"

var state := State.WAIT
var _t := 0.0
var _plan := 1.4
var _called := false
var _knights: Array[Node] = []
var _fire: OmniLight3D


func _ready() -> void:
	corpse_time = 3.0
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 8.0
	_fire = OmniLight3D.new()
	_fire.light_color = Color(0.45, 1.0, 0.6)
	_fire.light_energy = 1.4
	_fire.omni_range = 5.0
	_fire.position = Vector3(0, 3.2, -0.3)
	add_child(_fire)


func target_height() -> float:
	return 2.6 if state != State.KNEEL else 1.6


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	var quick := 1.25 if _called else 1.0
	_fire.light_energy = 1.4 + sin(_t * 9.0) * 0.25
	match state:
		State.WAIT:
			model.play(&"kneel", 0.2)
			_brake(delta)
			if alive and dist < 12.0 and absf(p.global_position.y - global_position.y) < 3.0:
				_go(State.WAKE)
		State.WAKE:
			_brake(delta)
			if _t >= 2.6:
				_go(State.WALK)
		State.WALK:
			if alive:
				_turn_to(p.global_position, 90.0 * quick, delta)
				if dist > 3.4:
					var v := _forward() * 1.7 * quick
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.2, 0.7 * quick)
				else:
					_brake(delta)
					model.play(&"idle", 0.2)
			if not _called and health.health <= health.max_health / 2:
				_go(State.SUMMON)
			elif _t >= _plan / quick:
				_go(State.SWEEP_WINDUP if dist < 4.5 and randf() < 0.6 else State.SLAM_WINDUP)
		State.SWEEP_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 70.0, delta)
			if _t >= 0.9 / quick:
				_go(State.SWEEP)
		State.SWEEP:
			_brake(delta)
			if attack_hitbox:
				if _t >= 0.1 and _t < 0.35 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.35:
					attack_hitbox.deactivate()
			if _t >= 0.6:
				_go(State.RECOVER)
		State.SLAM_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 0.8 / quick:
				_go(State.SLAM)
		State.SLAM:
			_brake(delta)
			if _t >= 0.12 and _t - delta < 0.12:
				_quake()
			if _t >= 0.5:
				_go(State.STUCK)
		State.STUCK:
			_brake(delta, 20.0)
			if _t >= STUCK_TIME / quick:
				_go(State.RECOVER)
		State.KNEEL:
			_brake(delta, 20.0)
			if _t >= KNEEL_TIME:
				_go(State.RECOVER)
		State.SUMMON:
			_brake(delta)
			if _t >= 0.6 and _t - delta < 0.6:
				_call_knights()
			if _t >= 1.6:
				_go(State.WALK)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.8:
				_plan = randf_range(0.9, 1.6)
				_go(State.WALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SWEEP:
		attack_hitbox.deactivate()
	match s:
		State.WAKE:
			model.play(&"alert", 0.4, 0.5, true)
			Sfx.play("undead_rise", 0.0, 0.0, 0.6)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 2.8, 9.0)
		State.SWEEP_WINDUP:
			model.play(&"windup", 0.1, 0.6, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.45)
		State.SWEEP:
			model.play(&"sweep", 0.04, 1.0, true)
			Sfx.play("heavy_swing", 0.0, 0.05, 0.55)
		State.SLAM_WINDUP:
			model.play(&"windup", 0.1, 0.5, true)
			Sfx.play("bone_rattle", -4.0, 0.05, 0.6)
		State.SLAM:
			model.play(&"attack", 0.03, 0.8, true)
		State.STUCK:
			model.play(&"kneel", 0.2, 0.5)
			Sfx.play("wall_hit_hard", 0.0, 0.0, 0.5)
		State.KNEEL:
			model.play(&"kneel", 0.12)
			Sfx.play("boss_hurt", -2.0, 0.05, 0.6)
		State.SUMMON:
			model.play(&"alert", 0.2, 0.7, true)
			Sfx.play("undead_rise", 2.0, 0.0, 0.8)
		State.RECOVER:
			model.play(&"recover", 0.1, 0.6, true)


func _quake() -> void:
	Sfx.play("mallet_smash", 3.0, 0.0, 0.45)
	SpellEffect.make(get_parent(), "quake", global_position + _forward() * 2.0)
	GameManager.rumble(0.8, 0.4)
	var p := GameManager.player
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 0.4)
	if p and not p.is_dead() and _flat_dist(p.global_position) < SLAM_RADIUS and absf(p.global_position.y - global_position.y) < 1.5:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 8.0
		info.unblockable = true
		info.attacker = self
		info.source_position = global_position
		p.take_hit(info)


## Two sworn knights out of the floor either side of him.
func _call_knights() -> void:
	_called = true
	var ps := load(KNIGHT_SCENE) as PackedScene
	if ps == null:
		return
	for sx: float in [-1.0, 1.0]:
		var k: Node3D = ps.instantiate()
		get_parent().add_child(k)
		var side := Vector3(-_forward().z, 0, _forward().x) * sx * 4.0
		k.global_position = global_position + side + _forward() * 1.0
		k.set("facing_yaw", facing_yaw)
		Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), k.global_position, 12, 3.0, 3.0, 0.8, 0.8, Color(0.4, 0.42, 0.46))
		_knights.append(k)


## The blade across his body turns blows from in front; a bash as he winds
## back knocks him down; kneeling or stuck, he is open.
func _bashed(info: HitInfo) -> int:
	if state == State.SWEEP_WINDUP or state == State.SLAM_WINDUP:
		_go(State.KNEEL)
		var away := _flat_to(info.source_position) * -1.0
		velocity = away.normalized() * 3.0 if away.length() > 0.01 else Vector3.ZERO
		return Hurtbox.Result.HIT
	Sfx.play("shield_block", -4.0, 0.05, 0.6)
	return Hurtbox.Result.BLOCKED


func _guard(info: HitInfo) -> int:
	if state in [State.WAIT, State.WAKE]:
		return Hurtbox.Result.IGNORED
	if state in [State.KNEEL, State.STUCK] or info.bomb:
		return Hurtbox.Result.HIT
	var to := _flat_to(info.source_position)
	if to.length() > 0.01 and _forward().dot(to.normalized()) < 0.0:
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -2.0, 0.08, 0.7)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -2.0, 0.08, 0.7)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 2.0, 8, 3.0, 3.0, 0.6, 0.8, Color(1.2, 1.15, 1.0))


func stun(_seconds: float) -> void:
	pass


func daze(_seconds: float, _ice := false) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	Sfx.play("boss_die", 0.0, 0.0, 0.7)
	model.play(&"kneel", 0.2)
	for k in _knights:
		if is_instance_valid(k):
			k.queue_free()
	_fire.light_energy = 0.4
	await get_tree().create_timer(1.6, false).timeout
	if is_instance_valid(self):
		await Story.hollow_king_freed(self)
