class_name Velloran
extends Enemy
## ARCHMAGUS VELLORAN, master of the Sapphire Order (Beta 1.5.0): the Order's
## last stand in the ruin of the Sapphire Sanctum. He floats over the ritual
## circle inside a WARD of the Order's blue fire that turns every blade:
## - a fan of five sapphire bolts (a shield turns them; the Mirror Shield
##   sends them home, and one that strikes him through the ward breaks it);
## - SAPPHIRE FALL: shards drop where the hero stands (a shadow marks each);
## - LOOSE PAGES: torn pages of the Incunabulum flap at the hero (keese).
## A Starfall Arrow (Lothelye's light, the one light the Order's fire cannot
## bend) breaks the ward: he drops to the floor, dazed, and the blade can
## reach him until he rises and calls the ward back. Below half his strength
## he blinks round the circle between spells, and casts faster. Beaten, he
## falls for good (Story.velloran_falls).

enum State { WAIT, WARDED, FAN, FALL, PAGES, BLINK, FALLEN, RISE, DEAD }

const TITLE := "ARCHMAGUS VELLORAN"
const SUBTITLE := "Master of the Sapphire Order"
## How far round the circle he blinks, and his height over it while warded.
const RING := 6.0
const FLOAT := 0.9
const FALLEN_TIME := 4.5
const NOTICE := 14.0

var state := State.WAIT
var warded := true
var _t := 0.0
var _gap := 1.2
var _casts := 0
var _marks: Array[Node3D] = []
var _ward_mesh: MeshInstance3D
var _ward_mat: StandardMaterial3D
var _pages: Array[Node] = []


func _ready() -> void:
	corpse_time = 2.0
	super._ready()
	add_to_group("bosses")
	_make_ward()
	global_position = _home + Vector3.UP * FLOAT


func is_targetable() -> bool:
	return super.is_targetable() and state != State.WAIT


func _make_ward() -> void:
	_ward_mesh = MeshInstance3D.new()
	_ward_mesh.name = "Ward"
	var s := SphereMesh.new()
	s.radius = 1.3
	s.height = 2.6
	s.radial_segments = 16
	s.rings = 8
	_ward_mesh.mesh = s
	_ward_mat = StandardMaterial3D.new()
	_ward_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ward_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ward_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ward_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ward_mat.albedo_color = Color(0.35, 0.45, 1.0, 0.35)
	_ward_mesh.material_override = _ward_mat
	_ward_mesh.position = Vector3.UP * 1.1
	_ward_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ward_mesh)


func _set_ward(on: bool) -> void:
	warded = on
	_ward_mesh.visible = on


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_update_marks(delta)
	_ward_mat.albedo_color.a = 0.28 + 0.08 * sin(_t * 5.0)
	var p := _player()
	var alive := p != null and not p.is_dead() and not p.in_cutscene
	velocity = Vector3.ZERO
	match state:
		State.WAIT:
			model.play(&"idle", 0.2)
			if alive and Progress.flag("ch5:velloran_met") and _flat_dist(p.global_position) < NOTICE and absf(p.global_position.y - _home.y) < 4.0:
				Cutscene.boss_intro(self, TITLE, SUBTITLE, "velloran_battle", 2.6, 7.0)
				_go(State.WARDED)
		State.WARDED:
			model.play(&"idle", 0.2)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= _gap and alive and not Cutscene.active:
				_next_spell()
		State.FAN:
			if alive:
				_turn_to(p.global_position, 160.0, delta)
			if _t >= 0.5 and _t - delta < 0.5:
				_fan()
			if _t >= 1.0:
				_after_spell()
		State.FALL:
			if _t >= 0.35 and _t - delta < 0.35 and alive:
				for i in (4 if _phase2() else 3):
					var off := Vector3(randf_range(-1.8, 1.8), 0, randf_range(-1.8, 1.8)) if i > 0 else Vector3.ZERO
					_mark(Vector3(p.global_position.x, _home.y, p.global_position.z) + off, 0.9 + i * 0.22)
			if _t >= 1.4:
				_after_spell()
		State.PAGES:
			if _t >= 0.5 and _t - delta < 0.5:
				_loose_pages()
			if _t >= 1.1:
				_after_spell()
		State.BLINK:
			if model:
				model.scale = Vector3.ONE * (clampf(1.0 - _t / 0.25, 0.05, 1.0) if _t < 0.25 else clampf((_t - 0.25) / 0.25, 0.05, 1.0))
			if _t >= 0.25 and _t - delta < 0.25:
				var a := _rng.randf() * TAU
				global_position = _home + Vector3(cos(a) * RING, FLOAT, sin(a) * RING)
				Sfx.play("mage_appear", -6.0, 0.08, 0.7)
			if _t >= 0.5:
				model.scale = Vector3.ONE
				_go(State.WARDED)
		State.FALLEN:
			model.play(&"stunned", 0.1)
			global_position.y = move_toward(global_position.y, _home.y, delta * 6.0)
			if _t >= FALLEN_TIME:
				_go(State.RISE)
		State.RISE:
			global_position.y = move_toward(global_position.y, _home.y + FLOAT, delta * 3.0)
			if _t >= 0.6:
				_set_ward(true)
				Sfx.play("ward_out", -2.0, 0.0, 0.6)
				_go(State.BLINK if _phase2() else State.WARDED)
	rotation.y = facing_yaw


func _phase2() -> bool:
	return health.health <= health.max_health / 2


func _next_spell() -> void:
	_casts += 1
	var roll := _rng.randf()
	if _casts % 4 == 0 and _alive_pages() < 3:
		_go(State.PAGES)
	elif roll < 0.55:
		_go(State.FAN)
	else:
		_go(State.FALL)


func _after_spell() -> void:
	_gap = _rng.randf_range(0.5, 0.9) if _phase2() else _rng.randf_range(0.9, 1.5)
	_go(State.BLINK if _phase2() and _rng.randf() < 0.6 else State.WARDED)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.FAN, State.FALL, State.PAGES:
			model.play(&"cast", 0.08, 1.0, true)
			Sfx.play("mage_cast", -2.0, 0.06, 0.75)
		State.BLINK:
			Sfx.play("mage_appear", -6.0, 0.08, 0.9)
		State.FALLEN:
			model.scale = Vector3.ONE
			model.play(&"stunned", 0.05)


func _fan() -> void:
	var p := _player()
	var aim := _forward()
	if p:
		aim = _flat_to(p.global_position).normalized()
	# Bolts fly level, at the hero's chest (he floats just over the circle).
	var from := Vector3(global_position.x, _home.y + 1.3, global_position.z)
	for i in 5:
		var a := (float(i) - 2.0) * deg_to_rad(13.0)
		var bolt := Rock.new()
		bolt.mesh_path = "res://assets/models/sapphire_bolt_mesh.tres"
		bolt.spin = false
		bolt.damage = 2
		bolt.speed = 13.0
		bolt.burst_tint = Color(0.5, 0.75, 1.4)
		get_parent().add_child(bolt)
		bolt.launch(from + aim * 0.8, aim.rotated(Vector3.UP, a), self)


## Torn pages of the Incunabulum: they flap at the hero like keese.
func _loose_pages() -> void:
	for i in 2:
		var e := (load("res://scenes/enemies/keese.tscn") as PackedScene).instantiate() as Enemy
		if has_meta("room"):
			e.set_meta("room", get_meta("room"))
		e.drop_table = 2
		e.tint = Color(1.4, 1.3, 1.0)
		get_parent().add_child(e)
		var a := TAU * i / 2.0 + randf()
		e.global_position = global_position + Vector3(cos(a) * 2.0, 1.0, sin(a) * 2.0)
		_pages.append(e)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), e.global_position, 8, 2.0, 2.0, 0.5, 0.6, Color(1.4, 1.3, 1.0))
	Sfx.play("page_flutter", -2.0, 0.1, 0.7)


func _alive_pages() -> int:
	_pages = _pages.filter(func(n: Node) -> bool: return is_instance_valid(n))
	return _pages.size()


func _mark(at: Vector3, delay: float) -> void:
	var m := MeshInstance3D.new()
	m.name = "FallMark"
	m.mesh = load("res://assets/models/blob_shadow_mesh.tres")
	m.top_level = true
	m.set_meta("delay", delay)
	m.set_meta("t", 0.0)
	get_parent().add_child(m)
	m.global_position = Vector3(at.x, at.y + 0.05, at.z)
	m.scale = Vector3.ONE * 2.2
	_marks.append(m)


func _update_marks(delta: float) -> void:
	for m in _marks.duplicate():
		if not is_instance_valid(m):
			_marks.erase(m)
			continue
		var t: float = float(m.get_meta("t")) + delta
		m.set_meta("t", t)
		var delay: float = m.get_meta("delay")
		m.scale = Vector3.ONE * lerpf(2.2, 1.0, clampf(t / delay, 0.0, 1.0))
		if t >= delay:
			_marks.erase(m)
			var at: Vector3 = m.global_position
			m.queue_free()
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), at + Vector3.UP * 0.4, 10, 3.0, 3.0, 0.6, 0.8, Color(0.5, 0.7, 1.4))
			Sfx.play("crystal_hit", -2.0, 0.08, 0.7)
			var p := GameManager.player
			if p and not p.is_dead() and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < 1.2 and absf(p.global_position.y - at.y) < 1.5:
				var info := HitInfo.new()
				info.damage = 2
				info.knockback = 5.0
				info.unblockable = true
				info.attacker = self
				info.source_position = at
				p.take_hit(info)


## Lothelye's light: the ward breaks and he falls.
func starfall_hit(_arrow: Node3D) -> void:
	if warded and state != State.WAIT and not _dead:
		_break_ward()


func _break_ward() -> void:
	_set_ward(false)
	Sfx.play("ward_out", 2.0, 0.0, 0.8)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.1, 18, 4.0, 3.0, 0.8, 0.9, Color(0.6, 0.7, 1.6))
	_go(State.FALLEN)


func _guard(info: HitInfo) -> int:
	if warded:
		# His own bolt, sent home through the ward, breaks it.
		if info.reflected:
			_break_ward()
			return Hurtbox.Result.HIT
		Sfx.play("shield_block", -4.0, 0.06, 0.6)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func _bashed(_info: HitInfo) -> int:
	Sfx.play("shield_block", -4.0, 0.05, 0.7)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	model.play(&"hurt", 0.02, 1.0, true)
	# Struck while down, he is up again the sooner.
	if state == State.FALLEN:
		_t = maxf(_t, FALLEN_TIME - 1.6)


func daze(_seconds: float, _ice := false) -> void:
	pass


func stun(_seconds: float) -> void:
	pass


func _die() -> void:
	state = State.DEAD
	for m in _marks:
		if is_instance_valid(m):
			m.queue_free()
	_marks.clear()
	for e in _pages:
		if is_instance_valid(e):
			e.queue_free()
	_set_ward(false)
	model.scale = Vector3.ONE
	model.play(&"stunned", 0.1)
	Sfx.play("boss_die", 0.0, 0.0, 1.1)
	await get_tree().create_timer(1.2, false).timeout
	if is_instance_valid(self):
		await Story.velloran_falls(self)
