extends Enemy
## Incunax, the Bound Page: master of the Sapphire Sanctum. A tome torn from
## the Fari Incunabulum and given a will by the Order, bound shut in sapphire
## chains, with one eye on the page at its heart.
##
## Its fight borrows from Phantom Ganon's and Gohma's (Boss_Ganondrof,
## Boss_Goma): the covers turn every blow; the eye is the weak point.
## - it drifts round the chamber out of reach, watching;
## - it throws its covers wide and casts: sapphire bolts fly at the hero,
##   and its eye stares out, bare. An arrow (or the Hookshot, or the
##   Boomerang) in the eye brings it crashing down, open on its back;
## - down, its pages lie open to the sword for a few seconds, then it heaves
##   itself up again;
## - at half strength it casts faster and calls up shades from its pages,
##   unseen in the gloom: the Starlight Lantern lays them bare.

enum State { WAIT, ROAR, DRIFT, OPEN, CAST, CLOSE, SUMMON, FALL, DOWN, RISE, DEAD }

const TITLE := "INCUNAX"
const SUBTITLE := "THE BOUND PAGE"
## How high it floats over the floor while drifting.
const HOVER := 3.2
const DOWN_TIME := 4.5
const DOWN_HITS := 3

## The chamber: its middle (set by the room) and how far it drifts from it.
@export var arena_radius := 7.0
@export var floor_y := 0.0

var state := State.WAIT
var _t := 0.0
var _plan := 2.5
var _orbit := 1.0
var _phase2 := false
var _down_hits := 0
var _shades: Array[Node3D] = []
var _eye: Node3D
var _eye_hurt: Hurtbox
var _centre := Vector3.ZERO


func _ready() -> void:
	corpse_time = 2.4
	super._ready()
	add_to_group("bosses")
	_centre = global_position
	floor_y = global_position.y if floor_y == 0.0 else floor_y
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 7.0
	_eye = model.find_child("Eye", true, false) as Node3D
	var part := EnemyPart.new()
	part.name = "EyePart"
	part.part = "eye"
	part.creature = self
	add_child(part)
	_eye_hurt = Hurtbox.new()
	_eye_hurt.name = "EyeHurtbox"
	_eye_hurt.collision_layer = 0
	_eye_hurt.collision_mask = 0
	_eye_hurt.receiver = part
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.55
	cs.shape = s
	_eye_hurt.add_child(cs)
	_eye_hurt.top_level = true
	add_child(_eye_hurt)
	model.play(&"idle", 0.0)


func is_down() -> bool:
	return state in [State.FALL, State.DOWN]


func _eye_open(on: bool) -> void:
	_eye_hurt.set_deferred("collision_layer", 16 if on else 0)


func _physics_process(delta: float) -> void:
	if _eye and _eye_hurt:
		_eye_hurt.global_position = _eye.global_position
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	var rate := 1.35 if _phase2 else 1.0
	var want_y := floor_y + HOVER
	match state:
		State.WAIT:
			velocity = Vector3.ZERO
			if alive and _flat_dist(p.global_position) < 14.0:
				_go(State.ROAR)
		State.ROAR:
			if alive:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 1.6:
				_go(State.DRIFT)
		State.DRIFT:
			if alive:
				_turn_to(p.global_position, 120.0, delta)
				# Circle the chamber's middle, keeping its distance from him.
				var from_c := global_position - _centre
				from_c.y = 0.0
				if from_c.length() < 0.5:
					from_c = Vector3.FORWARD
				var tangent := Vector3(-from_c.z, 0, from_c.x).normalized() * _orbit
				var radial := -from_c.normalized() * clampf((from_c.length() - arena_radius * 0.75) * 0.6, -1.0, 1.0)
				var v := (tangent + radial).normalized() * 2.6 * rate
				velocity.x = move_toward(velocity.x, v.x, 5.0 * delta)
				velocity.z = move_toward(velocity.z, v.z, 5.0 * delta)
			else:
				_brake(delta, 4.0)
			if _t >= _plan:
				if _phase2 and _live_shades() < 2 and _rng.randf() < 0.5:
					_go(State.SUMMON)
				else:
					_go(State.OPEN)
		State.OPEN:
			_brake(delta, 6.0)
			if alive:
				_turn_to(p.global_position, 160.0, delta)
			if _t >= 0.6:
				_go(State.CAST)
		State.CAST:
			_brake(delta, 6.0)
			if alive:
				_turn_to(p.global_position, 140.0, delta)
			for at in ([0.4, 1.0, 1.6] if not _phase2 else [0.3, 0.75, 1.2, 1.65]):
				if _t >= at and _t - delta < at:
					_bolt()
			if _t >= (2.2 if not _phase2 else 2.0):
				_go(State.CLOSE)
		State.CLOSE:
			_brake(delta, 6.0)
			if _t >= 0.4:
				_go(State.DRIFT)
		State.SUMMON:
			_brake(delta, 6.0)
			if _t >= 0.5 and _t - delta < 0.5:
				_summon()
			if _t >= 1.4:
				_go(State.CLOSE)
		State.FALL:
			want_y = floor_y + 0.7
			velocity.x = 0.0
			velocity.z = 0.0
			if _t >= 0.5:
				_go(State.DOWN)
		State.DOWN:
			want_y = floor_y + 0.7
			velocity.x = 0.0
			velocity.z = 0.0
			if _t >= DOWN_TIME or _down_hits >= DOWN_HITS:
				_go(State.RISE)
		State.RISE:
			if _t >= 0.8:
				_plan = 1.2
				_go(State.DRIFT)
	velocity.y = clampf((want_y - global_position.y) * 4.0, -9.0, 4.0)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	_eye_open(s in [State.OPEN, State.CAST])
	match s:
		State.ROAR:
			model.play(&"open", 0.1, 1.0, true)
			Sfx.play("boss_roar", -2.0, 0.0, 0.8)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 2.0, 8.0)
		State.DRIFT:
			model.play(&"idle", 0.2)
			_plan = _rng.randf_range(2.0, 3.4) / (1.35 if _phase2 else 1.0)
			if _rng.randf() < 0.35:
				_orbit = -_orbit
		State.OPEN:
			model.play(&"open", 0.06, 1.0, true)
			Sfx.play("page_flutter", -2.0, 0.08)
		State.CAST:
			model.play(&"cast", 0.08)
		State.CLOSE:
			model.play(&"close", 0.05, 1.0, true)
			Sfx.play("book_slam", -3.0, 0.08)
		State.SUMMON:
			model.play(&"cast", 0.08, 1.6)
			Sfx.play("shade_shriek", -4.0, 0.1, 0.7)
		State.FALL:
			model.play(&"fall", 0.04, 1.0, true)
			Sfx.play("boss_hurt", -2.0)
			_down_hits = 0
		State.DOWN:
			model.play(&"down", 0.05)
			Sfx.play("boss_stomp", -2.0)
			var p := _player()
			if p and p.camera_rig:
				p.camera_rig.shake(0.15, 0.4)
		State.RISE:
			model.play(&"rise", 0.05, 1.0, true)
			Sfx.play("book_slam", -4.0, 0.08, 0.8)


## A sapphire bolt from its open pages, at the hero.
func _bolt() -> void:
	var p := _player()
	var from := global_position + _forward() * 0.8
	var aim := _forward()
	if p:
		aim = (p.global_position + Vector3.UP * 0.9 - from).normalized()
	Sfx.play("fire_whoosh", -4.0, 0.08, 1.6)
	var orb := Rock.new()
	orb.mesh_path = "res://assets/models/sapphire_orb_mesh.tres"
	orb.damage = 2
	orb.speed = 9.0
	orb.life = 2.6
	orb.burst_tint = Color(0.6, 0.7, 2.0)
	get_parent().add_child(orb)
	orb.launch(from, aim, self)


## Two shades torn from its pages, hidden in the gloom.
func _summon() -> void:
	var ps: PackedScene = load("res://scenes/enemies/shade.tscn")
	for i in 2:
		var a := _rng.randf() * TAU
		var e: Node3D = ps.instantiate()
		get_parent().add_child(e)
		e.global_position = Vector3(_centre.x + cos(a) * arena_radius * 0.6, floor_y + 1.3, _centre.z + sin(a) * arena_radius * 0.6)
		_shades.append(e)


func _live_shades() -> int:
	_shades = _shades.filter(func(e: Node3D) -> bool: return is_instance_valid(e) and not e.is_dead())
	return _shades.size()


# --- Damage -------------------------------------------------------------------

## Its covers: blows glance off them, unless it lies open on its back.
func _guard(_info: HitInfo) -> int:
	if state == State.DOWN:
		return Hurtbox.Result.HIT
	Sfx.play("armor_clang", -4.0, 0.08, 1.2)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	_down_hits += 1
	Sfx.play("boss_hurt", -2.0, 0.08)
	model.play(&"hurt", 0.02, 1.0, true)
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.05, 0.15)


## The eye, struck while it stares out: down it comes.
func part_hit(part_name: String, info: HitInfo) -> int:
	if part_name != "eye" or _dead or not (info.attacker is PlayerController):
		return Hurtbox.Result.IGNORED
	if state not in [State.OPEN, State.CAST]:
		return Hurtbox.Result.BLOCKED
	model.flash(Color(0.7, 0.8, 1.0), 0.12)
	_go(State.FALL)
	return Hurtbox.Result.HIT


func part_boomerang(part_name: String, b: Node3D) -> void:
	var info := HitInfo.new()
	info.attacker = GameManager.player
	info.source_position = b.global_position
	part_hit(part_name, info)


func _die() -> void:
	state = State.DEAD
	_eye_open(false)
	for e in _shades:
		if is_instance_valid(e):
			e.queue_free()
	World.play_track("")
	Sfx.play("boss_die", 0.0, 0.0)
	model.play(&"death", 0.05, 1.0, true)
	var p := _player()
	if p and p.camera_rig:
		p.camera_rig.shake(0.2, 1.5)
	for i in 8:
		get_tree().create_timer(0.22 * i).timeout.connect(func() -> void:
			if is_inside_tree():
				Fragments.burst(get_parent(), load("res://assets/models/incunabulum_page_mesh.tres"), global_position + Vector3(randf_range(-1.2, 1.2), 1.0, randf_range(-1.2, 1.2)), 6, 3.0, 4.0, 1.2, 2.0, Color(1, 1, 1)))
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	tween.tween_property(model, "scale", Vector3(0.01, 0.01, 0.01), 0.8)
	tween.tween_callback(queue_free)
