extends Enemy
## Gullagog, the Mire Toad: master of the Bog Tower, a toad the size of a
## cottage that has grown fat on everything that fell into the bog.
##
## Built round the tower's treasure, as OoT's bosses are round theirs (King
## Dodongo swallows a bomb, z_boss_dodongo.c): its warty hide turns every
## blade, but when it opens its great mouth to suck the hero in, a seed from
## the Bloom Rod (or a bomb) thrown down its throat bursts inside it. It
## chokes, swells and rolls onto its back, kicking, with its soft belly open
## to the sword for a few seconds. Its moves:
## - a crouch and a great leap at the hero; landing sends a shockwave through
##   the mud that hurts anyone close by (jump clear, or be far enough away);
## - a lash of its sticky tongue straight ahead (the shield turns it);
## - the inhale: mouth gaping, it draws the hero toward it; reach its mouth
##   and it gulps him down and spits him out, hurt.
## At half strength it moves faster, leaps twice in a row and inhales longer.
##
## Its tells (Telegraph): a ring on the mud where a leap will land, as wide
## as the shockwave, which then bursts outward; a red band along the line its
## tongue will lash; and while it inhales, its gaping mouth glows (and the
## lock-on moves onto it). On its back, its belly glows white.

enum State { WAIT, ROAR, IDLE, CROUCH, LEAP, LAND, TONGUE_WINDUP, TONGUE, INHALE, GULP, CHOKE, FLIPPED, UNFLIP, DEAD }

const TITLE := "GULLAGOG"
const SUBTITLE := "GLUTTONOUS MIRE TOAD"
## The shockwave's reach and the tongue's.
const QUAKE_R := 3.6
const TONGUE_LEN := 6.5
const INHALE_PULL := 5.5
const FLIP_TIME := 5.0

var state := State.WAIT
var _t := 0.0
var _plan := 1.4
var _phase2 := false
var _leaps := 0
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _tongue_hit := false
var _mouth: Node3D
var _mouth_hurt: Hurtbox
var _floor_y := 0.0
## The tell on screen now (a tongue's band, the mouth's or belly's glow).
var _tell: Telegraph


func _ready() -> void:
	corpse_time = 2.4
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 9.0
	_mouth = model.find_child("Jaw", true, false) as Node3D
	var part := EnemyPart.new()
	part.name = "MouthPart"
	part.part = "mouth"
	part.creature = self
	add_child(part)
	_mouth_hurt = Hurtbox.new()
	_mouth_hurt.name = "MouthHurtbox"
	_mouth_hurt.collision_layer = 0
	_mouth_hurt.collision_mask = 0
	_mouth_hurt.monitorable = false
	_mouth_hurt.receiver = part
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 1.1
	cs.shape = s
	_mouth_hurt.add_child(cs)
	_mouth_hurt.top_level = true
	add_child(_mouth_hurt)
	_floor_y = global_position.y


func is_flipped() -> bool:
	return state in [State.CHOKE, State.FLIPPED]


## Where its open mouth is (seeds and bombs go in here).
func mouth_point() -> Vector3:
	return global_position + Vector3.UP * 1.3 + _forward() * 2.0


func _mouth_open(on: bool) -> void:
	_mouth_hurt.set_deferred("monitorable", on)
	_mouth_hurt.set_deferred("collision_layer", 16 if on else 0)


## While it inhales, the lock-on and every shot go for the open mouth.
func aim_point() -> Vector3:
	return mouth_point() if state == State.INHALE else super.aim_point()


func marker_point() -> Vector3:
	return mouth_point() + Vector3.UP * 1.0 if state == State.INHALE else super.marker_point()


func _end_tell() -> void:
	if is_instance_valid(_tell):
		_tell.finish()
	_tell = null


func _physics_process(delta: float) -> void:
	_mouth_hurt.global_position = mouth_point()
	if is_instance_valid(_tell):
		if state == State.TONGUE_WINDUP:
			_tell.global_position = global_position + _forward() * (0.8 + TONGUE_LEN * 0.5) + Vector3.UP * 0.06
			_tell.global_basis = Basis(Vector3.UP, facing_yaw)
		elif state == State.INHALE:
			_tell.global_position = mouth_point()
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var to := _flat_to(p.global_position) if alive else _forward()
	var dist := to.length()
	var rate := 1.35 if _phase2 else 1.0
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			_brake(delta)
			if alive and dist < 13.0 and absf(p.global_position.y - global_position.y) < 3.0:
				_go(State.ROAR)
		State.ROAR:
			_brake(delta)
			_turn_to(p.global_position, 90.0, delta)
			if _t >= 2.4:
				_go(State.IDLE)
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2, rate)
			if alive:
				_turn_to(p.global_position, 120.0 * rate, delta)
			if _t >= _plan / rate and alive:
				_choose(dist)
		State.CROUCH:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.45 / rate:
				_leap_from = global_position
				var target := p.global_position if alive else global_position + _forward() * 6.0
				var max_leap := 9.0
				var d := target - global_position
				d.y = 0.0
				if d.length() > max_leap:
					d = d.normalized() * max_leap
				_leap_to = Vector3(global_position.x + d.x, _floor_y, global_position.z + d.z)
				_go(State.LEAP)
		State.LEAP:
			var dur := 0.85 / rate
			var k := clampf(_t / dur, 0.0, 1.0)
			var pos := _leap_from.lerp(_leap_to, k)
			pos.y = _floor_y + sin(k * PI) * 4.0
			velocity = (pos - global_position) / maxf(delta, 0.001)
			move_and_slide()
			if k >= 1.0:
				global_position.y = _floor_y
				velocity = Vector3.ZERO
				_go(State.LAND)
			rotation.y = facing_yaw
			return
		State.LAND:
			_brake(delta, 20.0)
			if _t >= 0.5 / rate:
				_leaps -= 1
				if _leaps > 0:
					_go(State.CROUCH)
				else:
					_plan = randf_range(0.8, 1.6)
					_go(State.IDLE)
		State.TONGUE_WINDUP:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 160.0, delta)
			if _t >= 0.65 / rate:
				_go(State.TONGUE)
		State.TONGUE:
			_brake(delta)
			if not _tongue_hit and _t >= 0.12:
				_tongue_hit = true
				_lash(p)
			if _t >= 0.7:
				_plan = randf_range(0.7, 1.3)
				_go(State.IDLE)
		State.INHALE:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 50.0, delta)
				var mouth := mouth_point()
				var pull := Vector3(mouth.x - p.global_position.x, 0, mouth.z - p.global_position.z)
				if pull.length() < 1.8 and not p.is_invulnerable():
					_go(State.GULP)
				elif pull.length() < 14.0 and not p.in_cutscene:
					p.wind_push += pull.normalized() * INHALE_PULL * (1.0 if pull.length() > 4.0 else 1.3)
			if _t >= (4.0 if _phase2 else 3.2):
				_mouth_open(false)
				_plan = randf_range(1.0, 1.6)
				_go(State.IDLE)
		State.GULP:
			_brake(delta)
			if _t >= 0.5 and _t - delta < 0.5 and alive:
				var info := HitInfo.new()
				info.damage = 2
				info.knockback = 14.0
				info.unblockable = true
				info.attacker = self
				info.source_position = global_position
				p.global_position = mouth_point() + _forward() * 0.8
				p.take_hit(info)
				Sfx.play("boss_roar", -4.0, 0.05, 1.6)
			if _t >= 1.1:
				_plan = 1.0
				_go(State.IDLE)
		State.CHOKE:
			_brake(delta)
			if _t >= 1.0:
				_go(State.FLIPPED)
		State.FLIPPED:
			_brake(delta)
			if _t >= FLIP_TIME / (1.2 if _phase2 else 1.0):
				_go(State.UNFLIP)
		State.UNFLIP:
			_brake(delta)
			if _t >= 0.9:
				_plan = 0.6
				_go(State.IDLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _choose(dist: float) -> void:
	var r := randf()
	if dist < 4.5 and r < 0.6:
		_go(State.TONGUE_WINDUP)
	elif r < (0.45 if _phase2 else 0.35):
		_go(State.INHALE)
	elif dist > 6.0 or r < 0.7:
		_leaps = 2 if _phase2 else 1
		_go(State.CROUCH)
	else:
		_go(State.TONGUE_WINDUP)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	_end_tell()
	match s:
		State.ROAR:
			model.play(&"roar", 0.1, 1.0, true)
			Sfx.play("toad_croak", 0.0, 0.0, 0.8)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 1.6, 9.0)
		State.CROUCH:
			model.play(&"crouch", 0.08, 1.0, true)
		State.LEAP:
			model.play(&"leap", 0.05)
			Sfx.play("hop", -2.0, 0.05, 0.5)
			# Where it will come down, and how far the shockwave will reach.
			Telegraph.ring(get_parent(), _leap_to, QUAKE_R, 0.85 / (1.35 if _phase2 else 1.0) + 0.05)
		State.LAND:
			model.play(&"land", 0.04, 1.0, true)
			Telegraph.shockwave(get_parent(), global_position, QUAKE_R + 0.4, 0.4)
			_quake()
		State.TONGUE_WINDUP:
			model.play(&"tongue_windup", 0.08, 1.0, true)
			Sfx.play("toad_croak", -6.0, 0.05, 1.3)
			_tongue_hit = false
			_tell = Telegraph.strip(get_parent(), global_position + _forward() * 0.8, _forward(), TONGUE_LEN, 2.4, 0.65 / (1.35 if _phase2 else 1.0) + 0.1)
		State.TONGUE:
			model.play(&"tongue", 0.03, 1.0, true)
			Sfx.play("whip_crack", -2.0, 0.05)
		State.INHALE:
			model.play(&"inhale", 0.1)
			Sfx.play("toad_inhale", -2.0, 0.0)
			_mouth_open(true)
			# The open throat glows: the place to throw a seed or a bomb.
			_tell = Telegraph.glow(get_parent(), mouth_point(), 0.9, 4.2 if _phase2 else 3.4, Color(0.75, 1.0, 0.35, 0.5))
		State.GULP:
			_mouth_open(false)
			model.play(&"tongue", 0.05, 1.0, true)
			Sfx.play("toad_croak", -2.0, 0.05, 0.6)
		State.CHOKE:
			_mouth_open(false)
			model.play(&"choke", 0.05, 1.0, true)
			Sfx.play("boss_hurt", -2.0, 0.0, 1.2)
		State.FLIPPED:
			model.play(&"flipped", 0.08)
			Sfx.play("boss_stomp", -4.0, 0.05, 1.2)
			# The soft belly, open to the sword.
			_tell = Telegraph.glow(get_parent(), global_position + Vector3.UP * 1.2, 1.6, FLIP_TIME, Color(1.0, 1.0, 0.85, 0.28), self)
		State.UNFLIP:
			model.play(&"unflip", 0.05, 1.0, true)
			Sfx.play("boss_stomp", -4.0, 0.05, 0.9)


## The landing's shockwave through the mud.
func _quake() -> void:
	Sfx.play("boss_stomp", 0.0, 0.05, 0.8)
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.18, 0.5)
	Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3.UP * 0.2, 14, 4.0, 3.0, 0.8, 1.0, Color(0.35, 0.3, 0.2))
	if p and not p.is_dead() and p.is_on_floor() and global_position.distance_to(p.global_position) < QUAKE_R:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 10.0
		info.unblockable = true
		info.attacker = self
		info.source_position = global_position
		p.take_hit(info)


## The tongue lashes straight out: the shield turns it.
func _lash(p: PlayerController) -> void:
	if p == null or p.is_dead():
		return
	var rel := p.global_position - global_position
	var along := rel.dot(_forward())
	var side := (rel - _forward() * along)
	side.y = 0.0
	if along > 0.5 and along < TONGUE_LEN and side.length() < 1.3 and absf(rel.y) < 2.0:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 8.0
		info.attacker = self
		info.source_position = global_position + _forward() * 1.5
		var r := p.take_hit(info)
		if r == Hurtbox.Result.BLOCKED:
			# Stung on the shield's rim, it reels back a moment.
			_plan = 1.6
			stun(0.6)


# --- Damage -------------------------------------------------------------------

## Its hide turns blades, unless it lies on its back.
func _guard(info: HitInfo) -> int:
	if state == State.FLIPPED:
		return Hurtbox.Result.HIT
	if info.bomb and state != State.INHALE:
		# A blast on its hide only makes it flinch.
		Sfx.play("boss_hurt", -6.0, 0.05, 1.4)
		return Hurtbox.Result.BLOCKED
	Sfx.play("shield_block", -4.0, 0.08, 0.6)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -2.0, 0.08)
	model.flash(Color(1.0, 0.9, 0.7), 0.1)
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.05, 0.15)


## A seed (or anything bursting) down its throat while it inhales.
func choke() -> void:
	if state != State.INHALE or _dead:
		return
	model.flash(Color(0.8, 1.0, 0.6), 0.15)
	_go(State.CHOKE)


## The mouth: a bomb's blast, an arrow or the sword into its open throat.
func part_hit(part_name: String, info: HitInfo) -> int:
	if part_name != "mouth" or _dead or state != State.INHALE:
		return Hurtbox.Result.IGNORED
	if info.bomb:
		choke()
		return Hurtbox.Result.HIT
	# Arrows and blades into the gullet just make it gag.
	Sfx.play("boss_hurt", -6.0, 0.05, 1.5)
	return Hurtbox.Result.BLOCKED


## A Bloom Rod seed struck it (BloomSeed): in its open mouth it chokes; on
## its hide the seed only scatters.
func bloom_hit(seed: Node3D) -> void:
	if state == State.INHALE and seed.global_position.distance_to(mouth_point()) < 2.6:
		choke()
	else:
		Sfx.play("grass_cut", -6.0, 0.1, 0.8)


func part_boomerang(_part_name: String, _b: Node3D) -> void:
	pass


func stun(seconds: float) -> void:
	if state in [State.IDLE, State.TONGUE, State.TONGUE_WINDUP]:
		_plan = maxf(_plan, seconds + 0.6)
		state = State.IDLE
		_t = 0.0
		model.play(&"idle", 0.1, 0.5)


func _die() -> void:
	state = State.DEAD
	_end_tell()
	_mouth_open(false)
	World.play_track("")
	Sfx.play("boss_die", 0.0, 0.0)
	model.play(&"death", 0.05, 1.0, true)
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 1.5)
	for i in 6:
		get_tree().create_timer(0.25 * i).timeout.connect(func() -> void:
			if is_inside_tree():
				Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3(randf_range(-1.5, 1.5), 1.5, randf_range(-1.5, 1.5)), 10, 3.0, 4.0, 1.2, 2.0, Color(0.6, 0.9, 0.4)))
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
	tween.tween_callback(queue_free)
