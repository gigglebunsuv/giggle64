class_name Gaoler
extends Enemy
## The Jailer, Ridge Keep's mini-boss (Beta 1.4.0): a drowned jailer risen
## by Mara, huge and slow, swinging the Iron Flail on its chain. His iron
## hide turns blows from in front while he stands ready.
## - He winds the flail round and SWEEPS it across the cell (block it; a
##   PARRY knocks him reeling, wide open: STAGGER).
## - He heaves it overhead and SLAMS it down: the floor shakes round the ball
##   (no shield stops that), and the ball sticks fast in the stone while he
##   wrenches it free (STUCK, open).
## - A Shield Bash as he winds up, a bomb, the Down Thrust's shock or a
##   greatsword's cleave also break his guard.
## Beaten, the room clears and the Iron Flail's chest appears.

enum State { WAIT, WALK, SWEEP_WINDUP, SWEEP, SLAM_WINDUP, SLAM, STUCK, STAGGER, RECOVER, DEAD }

const TITLE := "THE JAILER"
const SUBTITLE := "Keeper of the Drowned Cells"
const STUCK_TIME := 2.2
const STAGGER_TIME := 2.6
const SLAM_RADIUS := 3.2

var state := State.WAIT
var _t := 0.0
var _plan := 1.2
var _named := false


func _ready() -> void:
	corpse_time = 1.6
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 8.0


func target_height() -> float:
	return 2.2


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	var quick := EnemyScale.haste(tier) * (1.2 if health.health <= health.max_health / 2 else 1.0)
	if stun_left > 0.0 and state in [State.WALK, State.RECOVER]:
		stun_left = maxf(stun_left - delta, 0.0)
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			_brake(delta)
			if alive and dist < 11.0 and absf(p.global_position.y - global_position.y) < 3.0:
				if not _named:
					_named = true
					Cutscene.boss_intro(self, TITLE, SUBTITLE, World.MINIBOSS_TRACK, 2.2, 7.0, 2.4)
				_go(State.WALK)
		State.WALK:
			if alive:
				_turn_to(p.global_position, 80.0 * quick, delta)
				if dist > 3.2:
					var v := _forward() * 1.5 * quick
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.2, 0.7 * quick)
				else:
					_brake(delta)
					model.play(&"idle", 0.2)
			if _t >= _plan / quick:
				_go(State.SWEEP_WINDUP if dist < 4.2 and randf() < 0.65 else State.SLAM_WINDUP)
		State.SWEEP_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 60.0, delta)
			if _t >= 0.85 / quick:
				_go(State.SWEEP)
		State.SWEEP:
			_brake(delta)
			if attack_hitbox:
				if _t >= 0.1 and _t < 0.32 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.32:
					attack_hitbox.deactivate()
			if _t >= 0.6:
				_go(State.RECOVER)
		State.SLAM_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 0.9 / quick:
				_go(State.SLAM)
		State.SLAM:
			_brake(delta)
			if _t >= 0.14 and _t - delta < 0.14:
				_quake()
			if _t >= 0.45:
				_go(State.STUCK)
		State.STUCK:
			_brake(delta, 20.0)
			if _t >= STUCK_TIME / quick:
				_go(State.RECOVER)
		State.STAGGER:
			_brake(delta, 10.0)
			if _t >= STAGGER_TIME:
				_go(State.RECOVER)
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
		State.SWEEP_WINDUP:
			model.play(&"windup", 0.1, 0.6, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.5)
			Telegraph.ring(get_parent(), global_position + _forward() * 2.0, 2.8, 0.85)
		State.SWEEP:
			model.play(&"sweep", 0.04, 1.0, true)
			Sfx.play("heavy_swing", 0.0, 0.05, 0.6)
		State.SLAM_WINDUP:
			model.play(&"windup", 0.1, 0.5, true)
			Sfx.play("bone_rattle", -4.0, 0.05, 0.5)
			Telegraph.ring(get_parent(), global_position + _forward() * 2.4, SLAM_RADIUS, 0.95)
		State.SLAM:
			model.play(&"attack", 0.03, 0.8, true)
		State.STUCK:
			model.play(&"kneel", 0.2, 0.5)
			Sfx.play("wall_hit_hard", 0.0, 0.0, 0.5)
		State.STAGGER:
			model.play(&"kneel", 0.12)
			Sfx.play("boss_hurt", -2.0, 0.05, 0.7)
		State.RECOVER:
			model.play(&"recover", 0.1, 0.6, true)


func _quake() -> void:
	var at := global_position + _forward() * 2.4
	Sfx.play("mallet_smash", 3.0, 0.0, 0.5)
	SpellEffect.make(get_parent(), "quake", at)
	Telegraph.shockwave(get_parent(), at, SLAM_RADIUS + 0.4, 0.4)
	GameManager.rumble(0.7, 0.35)
	var p := GameManager.player
	if p and p.camera_rig:
		p.camera_rig.shake(0.18, 0.35)
	if p and not p.is_dead() and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < SLAM_RADIUS \
			and absf(p.global_position.y - global_position.y) < 1.5:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 8.0
		info.unblockable = true
		info.attacker = self
		info.source_position = at
		p.take_hit(info)


func _reel() -> void:
	_go(State.STAGGER)


## A parry as the flail comes round sends him reeling.
func parried(_by: Node3D) -> void:
	if state == State.SWEEP:
		_reel()


func _bashed(info: HitInfo) -> int:
	if state in [State.SWEEP_WINDUP, State.SLAM_WINDUP]:
		_reel()
		var away := _flat_to(info.source_position) * -1.0
		velocity = away.normalized() * 2.5 if away.length() > 0.01 else Vector3.ZERO
		return Hurtbox.Result.HIT
	Sfx.play("shield_block", -4.0, 0.05, 0.6)
	return Hurtbox.Result.BLOCKED


func _guard(info: HitInfo) -> int:
	if state == State.WAIT:
		return Hurtbox.Result.IGNORED
	if state in [State.STUCK, State.STAGGER] or info.bomb or info.kind == "thrust":
		return Hurtbox.Result.HIT
	if info.cleave and state in [State.WALK, State.RECOVER, State.SWEEP_WINDUP, State.SLAM_WINDUP]:
		_reel()
		return Hurtbox.Result.HIT
	var to := _flat_to(info.source_position)
	if to.length() > 0.01 and _forward().dot(to.normalized()) < -0.2:
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -2.0, 0.08, 0.6)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -4.0, 0.08, 0.8)


func stun(_seconds: float) -> void:
	pass


func daze(_seconds: float, _ice := false) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	if attack_hitbox:
		attack_hitbox.deactivate()
	Sfx.play("boss_die", -2.0, 0.0, 0.8)
	super._die()
