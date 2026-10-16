extends Enemy
## The Tide Knight, mini-boss of the Lake Shrine, after OoT's Iron Knuckle
## (EnIk, z_en_ik.c):
## - It plods toward the hero and never flinches from a blow.
## - Close in front, it raises its cleaver high and brings it down (a long,
##   telegraphed chop that the shield cannot hold: it knocks the hero flat),
##   or now and then a wide sweep across its front, which also catches him
##   at its side.
## - It swings at a hero behind its back only once he has stayed there for a
##   while (EnIk's 40-frame count before its single horizontal attack), and
##   it turns only part way as the sweep winds up, so its back stays safe.
## - After an attack it stands open for a moment.
## - Half beaten, it throws off its plate armor (EnIk's armor coming off)
##   and fights on faster and fiercer.
## - A knight with a `title_name` is a dungeon's mini-boss: the first time it
##   sees the hero, the camera turns to it and its name card shows (as
##   Majora's Mask names its mini-bosses), then it comes on.
## - The Mire Knight (`burrows`), once its armor is off, sinks into the bog
##   now and then: a trail of bubbles hunts the hero across the floor, stops,
##   boils, and the knight bursts up out of the muck where it stopped. Step
##   away when the bubbles boil, then strike while it hauls itself free.

enum State { IDLE, WALK, CHOP_WINDUP, CHOP, SWEEP_WINDUP, SWEEP, RECOVER, SHED, SINK, UNDER, BOIL, RISE, DEAD }

## How deep the model goes while it is under the bog.
const SINK_DEPTH := 2.8
## Seconds a close hero must stay round its back before it sweeps at him
## (EnIk: 40 frames), and how fast it turns (degrees a second) as the sweep
## winds up.
const BEHIND_TIME := 2.0
const SWEEP_TURN := 100.0

@export var notice_range := 16.0
## How much faster than the Tide Knight it fights (Ladhellin's Sentinel).
@export var start_rate := 1.0
## Mini-boss name card on first sight ("" = none) and the line above it.
@export var title_name := ""
@export var title_epithet := ""
## Unarmoured, it sinks into the floor and bursts up under the hero.
@export var burrows := false

var state := State.IDLE
var armoured := true
var _t := 0.0
var _sweep: Hitbox
var _speed := 1.1
var _rate := 1.0
var _step_t := 0.0
## Seconds until it may sink again, the burst's hitbox, and its body's
## collision layer while above ground.
var _burrow_cd := 3.0
var _burst: Hitbox
var _layer := 0
var _bubble_t := 0.0
var _behind_t := 0.0


func _ready() -> void:
	corpse_time = 1.6
	super._ready()
	_rate = start_rate
	_speed = 1.1 * start_rate
	if attack_hitbox:
		attack_hitbox.damage = 4
		attack_hitbox.knockback = 9.0
		attack_hitbox.unblockable = true
	# A second, wide hitbox for the sweep: the cleaver's arc in front of it
	# and out to both sides, never behind its back (it turns to face the hero
	# as it winds up, EnIk's horizontal swing).
	_sweep = Hitbox.new()
	_sweep.name = "SweepHitbox"
	_sweep.collision_layer = 64
	_sweep.collision_mask = 8
	_sweep.attacker = self
	_sweep.damage = 3
	_sweep.knockback = 8.0
	var cs := CollisionShape3D.new()
	var arc := BoxShape3D.new()
	# Its back edge stays in front of the knight's middle, so a hero round
	# its back (even half way, at its hip) is clear of the cleaver.
	arc.size = Vector3(5.6, 1.6, 2.8)
	cs.shape = arc
	cs.position = Vector3(0, 1.0, -1.6)
	_sweep.add_child(cs)
	add_child(_sweep)
	if burrows:
		_burst = Hitbox.new()
		_burst.name = "BurstHitbox"
		_burst.collision_layer = 64
		_burst.collision_mask = 8
		_burst.attacker = self
		_burst.damage = 3
		_burst.knockback = 9.0
		_burst.unblockable = true
		var bcs := CollisionShape3D.new()
		var bcyl := CylinderShape3D.new()
		bcyl.radius = 1.7
		bcyl.height = 2.4
		bcs.shape = bcyl
		bcs.position = Vector3(0, 1.0, 0)
		_burst.add_child(bcs)
		add_child(_burst)


func _physics_process(delta: float) -> void:
	if _dead:
		_fall(delta)
		_brake(delta)
		move_and_slide()
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			# Its name card holds it still until the camera comes back.
			if Cutscene.active:
				pass
			elif alive and dist < notice_range:
				if title_name != "":
					Cutscene.boss_intro(self, title_name, title_epithet, World.MINIBOSS_TRACK, 2.2, 6.5, 2.6)
				if not Cutscene.active:
					_go(State.WALK)
		State.WALK:
			if not alive:
				_go(State.IDLE)
			else:
				_turn_to(p.global_position, 90.0 * _rate, delta)
				var ahead := _forward().dot(_flat_to(p.global_position).normalized())
				_burrow_cd -= delta
				if burrows and not armoured and _burrow_cd <= 0.0 and dist > 2.5:
					_go(State.SINK)
				elif dist < 3.3:
					_brake(delta)
					# Turning on the spot it shuffles its feet; squared up, it stands.
					var off := absf(_forward().signed_angle_to(_flat_to(p.global_position).normalized(), Vector3.UP))
					if off > 0.35:
						model.play(&"walk", 0.25, 0.6 * _rate)
					else:
						model.play(&"idle", 0.3)
					if ahead > 0.6:
						_go(State.CHOP_WINDUP if _rng.randf() < 0.7 else State.SWEEP_WINDUP)
					elif ahead >= 0.0:
						_go(State.SWEEP_WINDUP)
					else:
						# Round its back it keeps turning, and swings only if
						# the hero stays there.
						_behind_t += delta
						if _behind_t >= BEHIND_TIME / _rate:
							_go(State.SWEEP_WINDUP)
				else:
					_behind_t = 0.0
					var v := _forward() * _speed
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.2, _speed / 1.1)
					# A heavy footfall twice per stride (the walk cycle is 1.4 s).
					_step_t += delta
					if _step_t >= 0.7 * 1.1 / _speed:
						_step_t = 0.0
						Sfx.play("heavy_step", -6.0, 0.05)
		State.CHOP_WINDUP:
			# EnIk_VerticalAttack never turns once the axe goes up, so stepping
			# aside or flipping back takes the hero out of the chop's line.
			_brake(delta)
			if _t >= 0.8 / _rate:
				_go(State.CHOP)
		State.CHOP:
			if attack_hitbox:
				if _t >= 0.06 and _t < 0.2 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.2:
					attack_hitbox.deactivate()
			if _t >= 0.1 and _t - delta < 0.1:
				Sfx.play("boss_stomp", -4.0, 0.05, 1.3)
				if alive and p.camera_rig:
					p.camera_rig.shake(0.08, 0.25)
			if _t >= 0.25:
				_go(State.RECOVER)
		State.SWEEP_WINDUP:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, SWEEP_TURN * _rate, delta)
			if _t >= 0.6 / _rate:
				_go(State.SWEEP)
		State.SWEEP:
			if _t >= 0.08 and _t < 0.32 and not _sweep.active:
				_sweep.activate()
			elif _t >= 0.32:
				_sweep.deactivate()
			if _t >= 0.4:
				_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= 0.9 / _rate:
				_go(State.WALK)
		State.SHED:
			_brake(delta)
			if _t >= 1.0:
				_go(State.WALK)
		State.SINK:
			_brake(delta)
			model.position.y = -SINK_DEPTH * clampf(_t / 0.7, 0.0, 1.0)
			if _t >= 0.7:
				_go(State.UNDER)
		State.UNDER:
			# Only bubbles show where it is: they hunt the hero for a while.
			if alive:
				_turn_to(p.global_position, 360.0, delta)
				var v := _flat_to(p.global_position).normalized() * 3.4 if dist > 0.3 else Vector3.ZERO
				velocity.x = v.x
				velocity.z = v.z
			else:
				_brake(delta)
			_bubbles(delta, 0.12, 0.35)
			if _t >= 1.8:
				_go(State.BOIL)
		State.BOIL:
			# It stops and the muck boils: the moment to get clear.
			_brake(delta, 30.0)
			_bubbles(delta, 0.04, 0.6)
			if _t >= 0.55:
				_go(State.RISE)
		State.RISE:
			model.position.y = -SINK_DEPTH * (1.0 - clampf(_t / 0.25, 0.0, 1.0))
			if _t >= 0.05 and _t < 0.3 and not _burst.active:
				_burst.activate()
			elif _t >= 0.3:
				_burst.deactivate()
			if _t >= 0.45:
				_go(State.RECOVER)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	_behind_t = 0.0
	if attack_hitbox and s != State.CHOP:
		attack_hitbox.deactivate()
	if s != State.SWEEP:
		_sweep.deactivate()
	if _burst and s != State.RISE:
		_burst.deactivate()
	match s:
		State.CHOP_WINDUP:
			model.play(&"chop_windup", 0.08, _rate, true)
			Sfx.play("heavy_swing", -8.0, 0.05, 0.6)
		State.CHOP:
			model.play(&"chop", 0.02, 1.0, true)
			Sfx.play("heavy_swing", -2.0)
		State.SWEEP_WINDUP:
			model.play(&"sweep_windup", 0.08, _rate, true)
		State.SWEEP:
			model.play(&"sweep", 0.02, 1.0, true)
			Sfx.play("heavy_swing", -2.0, 0.05, 1.2)
		State.SHED:
			model.play(&"hurt", 0.03, 1.0, true)
		State.SINK:
			model.play(&"recover", 0.1, 0.6, true)
			Sfx.play("splash_big", -6.0, 0.05, 0.6)
			_set_hurtbox(false)
			_layer = collision_layer
			# Under the bog it passes beneath the hero's feet.
			collision_layer = 0
		State.UNDER:
			model.visible = false
		State.BOIL:
			Sfx.play("bubble_pop", -2.0, 0.1, 0.6)
		State.RISE:
			model.visible = true
			model.play(&"sweep", 0.02, 1.0, true)
			Sfx.play("splash_big", 0.0, 0.05, 0.75)
			Sfx.play("heavy_swing", -2.0, 0.05, 0.8)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.4, 14, 3.0, 5.0, 1.0, 1.6, Color(0.35, 0.45, 0.25))
			var pl := _player()
			if pl and pl.camera_rig:
				pl.camera_rig.shake(0.1, 0.3)
		State.RECOVER:
			model.play(&"recover", 0.05, _rate, true)
			# After bursting up it takes longer to haul itself free.
			if collision_layer == 0:
				collision_layer = _layer
				_set_hurtbox(true)
				model.position.y = 0.0
				_t = -0.8 / _rate
				_burrow_cd = _rng.randf_range(5.0, 8.0)


## It does not flinch; when half beaten its armor bursts off.
func _hurt(_info: HitInfo) -> void:
	Sfx.play("armor_clang", -6.0, 0.08)
	if armoured and health.health <= health.max_health / 2:
		_shed()
		_burrow_cd = 2.5


func _shed() -> void:
	armoured = false
	_speed = 2.1
	_rate = 1.5
	for n in ["ArmorChest", "ArmorShoulderL", "ArmorShoulderR"]:
		var part := model.find_child(n, true, false) as Node3D
		if part:
			part.visible = false
	Sfx.play("armor_clang", 0.0)
	Sfx.play("boss_hurt", -6.0, 0.05, 1.4)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.8, 16, 4.0, 4.0, 1.4, 2.2, Color(0.55, 0.8, 0.9))
	_go(State.SHED)


## Mud bubbles rising where it swims under the floor (every `every` seconds,
## up to `size` across).
func _bubbles(delta: float, every: float, size: float) -> void:
	_bubble_t -= delta
	if _bubble_t > 0.0 or get_parent() == null:
		return
	_bubble_t = every
	var b := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = size * _rng.randf_range(0.4, 0.6)
	sph.height = sph.radius * 1.4
	sph.radial_segments = 8
	sph.rings = 4
	b.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.3, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	b.material_override = mat
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(_rng.randf_range(-0.6, 0.6), 0.05, _rng.randf_range(-0.6, 0.6))
	b.scale = Vector3.ONE * 0.2
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector3.ONE, 0.25)
	tw.tween_property(b, "scale", Vector3.ONE * 1.3, 0.1)
	tw.tween_callback(b.queue_free)
	if _rng.randf() < 0.35:
		Sfx.play("bubble_pop", -12.0, 0.2, 0.7)


func _die() -> void:
	if collision_layer == 0 and _layer != 0:
		collision_layer = _layer
	model.visible = true
	model.position.y = 0.0
	state = State.DEAD
	_sweep.deactivate()
	Sfx.play("boss_stomp", -2.0)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.5, 20, 3.5, 4.5, 1.8, 2.0, Color(0.6, 0.85, 0.95))
	super._die()
