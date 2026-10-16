class_name BattleMage
extends Enemy
## An Order battle-mage (Chapter IV): the war's sapphire sorcerer, in red and
## gold over the Order's blue. Like the Sanctum's mages it blinks from place
## to place, but it fights to hold ground:
## - a fan of three sapphire bolts (any shield turns them; the Mirror Shield
##   sends them home and staggers it);
## - SAPPHIRE FALL: crystals drop out of the air where the hero stands (a
##   shadow marks each a moment before);
## - at half health it calls up two goblins, once.
## It carries the Sapphire Staff (Westmarch's mini-boss; the staff lies in
## the chest that its fall opens). In the Siege of Haven it leads the last
## wave and, beaten low (`flee_at`), escapes west instead of dying.

signal fled

enum State { HIDDEN, APPEAR, WATCH, FAN, FALL, VANISH, STUNNED, FLEE, DEAD }

@export var notice_range := 18.0
@export var roam := 7.0
## Health at which it flees (0 = it fights to the end).
@export var flee_at := 0

var state := State.HIDDEN
var _t := 0.0
var _wait := 0.8
var _called := false
var _marks: Array[Node3D] = []


func _ready() -> void:
	corpse_time = 1.6
	super._ready()
	_set_shown(false)


func is_targetable() -> bool:
	return super.is_targetable() and state in [State.WATCH, State.FAN, State.FALL, State.STUNNED]


func _set_shown(on: bool) -> void:
	if model:
		model.visible = on
	collision_layer = 4 if on else 0
	_set_hurtbox(on)
	var shadow := get_node_or_null("BlobShadow") as Node3D
	if shadow:
		shadow.visible = on


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_update_marks(delta)
	var p := _player()
	var alive := p != null and not p.is_dead()
	velocity = Vector3.ZERO
	if stun_left > 0.0 and state in [State.WATCH, State.FAN, State.FALL, State.STUNNED]:
		stun_left -= delta
		state = State.STUNNED
		model.play(&"stunned", 0.1)
		if stun_left <= 0.0:
			_go(State.VANISH)
		return
	match state:
		State.HIDDEN:
			if _t >= _wait and alive and _home.distance_to(p.global_position) < notice_range:
				_pick_spot(p)
				_go(State.APPEAR)
		State.APPEAR:
			if alive:
				_turn_to(p.global_position, 400.0, delta)
			if model:
				model.scale = Vector3.ONE * clampf(_t / 0.4, 0.05, 1.0)
			if _t >= 0.4:
				_go(State.WATCH)
		State.WATCH:
			model.play(&"idle", 0.2)
			if alive:
				_turn_to(p.global_position, 240.0, delta)
			if _t >= 0.5:
				if not _called and health.health <= health.max_health / 2:
					_call_goblins()
				_go(State.FALL if randf() < 0.4 else State.FAN)
		State.FAN:
			if alive:
				_turn_to(p.global_position, 140.0, delta)
			if _t >= 0.45 and _t - delta < 0.45:
				_fan()
			if _t >= 1.0:
				_go(State.VANISH)
		State.FALL:
			if _t >= 0.3 and _t - delta < 0.3 and alive:
				for i in 3:
					var off := Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)) if i > 0 else Vector3.ZERO
					_mark(p.global_position + off, 0.9 + i * 0.25)
			if _t >= 1.4:
				_go(State.VANISH)
		State.VANISH:
			if model:
				model.scale = Vector3.ONE * clampf(1.0 - _t / 0.35, 0.05, 1.0)
			if _t >= 0.35:
				_set_shown(false)
				_wait = _rng.randf_range(0.5, 1.2)
				_go(State.HIDDEN)
		State.FLEE:
			if model:
				model.scale = Vector3.ONE * clampf(1.0 - _t / 0.8, 0.02, 1.0)
				model.position.y = _t * 2.0
			if _t >= 0.8:
				_set_shown(false)
				_dead = true
				remove_from_group("enemies")
				fled.emit()
				queue_free()
	rotation.y = facing_yaw


func _pick_spot(p: PlayerController) -> void:
	for i in 14:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(2.0, roam)
		var spot := _home + Vector3(cos(a) * d, 0, sin(a) * d)
		if spot.distance_to(p.global_position) < 4.5:
			continue
		var q := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 2.0, spot + Vector3.DOWN * 3.0, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			continue
		global_position = hit.position
		return
	global_position = _home


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.APPEAR:
			_set_shown(true)
			model.scale = Vector3.ONE * 0.05
			model.play(&"idle", 0.0)
			Sfx.play("mage_appear", -4.0, 0.08, 0.85)
		State.FAN, State.FALL:
			model.play(&"cast", 0.08, 1.0, true)
			Sfx.play("mage_cast", -2.0, 0.06, 0.85)
		State.VANISH:
			Sfx.play("mage_appear", -6.0, 0.08, 0.7)
			if model:
				model.scale = Vector3.ONE
		State.FLEE:
			Sfx.play("firebuns_laugh", -6.0, 0.0, 1.35)
			_set_hurtbox(false)


func _fan() -> void:
	var p := _player()
	var aim := _forward()
	if p:
		aim = _flat_to(p.global_position).normalized()
	for i in 3:
		var a := (float(i) - 1.0) * deg_to_rad(16.0)
		var bolt := Rock.new()
		bolt.mesh_path = "res://assets/models/sapphire_bolt_mesh.tres"
		bolt.spin = false
		bolt.damage = 2
		bolt.speed = 12.0
		bolt.burst_tint = Color(0.5, 0.75, 1.4)
		get_parent().add_child(bolt)
		bolt.launch(global_position + Vector3.UP * 1.6 + aim * 0.8, aim.rotated(Vector3.UP, a), self)


## A shadow on the floor at `at`, and `delay` later a sapphire shard falls there.
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


func _call_goblins() -> void:
	_called = true
	Sfx.play("war_horn", -4.0, 0.0, 1.2)
	for i in 2:
		var e := (load("res://scenes/enemies/basic_enemy.tscn") as PackedScene).instantiate() as Enemy
		if has_meta("room"):
			e.set_meta("room", get_meta("room"))
		e.drop_table = 1
		get_parent().add_child(e)
		var a := TAU * i / 2.0 + randf()
		e.global_position = global_position + Vector3(cos(a) * 2.5, 0.2, sin(a) * 2.5)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), e.global_position + Vector3.UP, 8, 2.0, 2.0, 0.5, 0.6, Color(0.5, 0.7, 1.4))


func take_hit(info: HitInfo) -> int:
	if flee_at > 0 and not _dead and state != State.FLEE and health.health - info.damage <= flee_at:
		health.health = maxi(health.health - info.damage, 1)
		health.health_changed.emit(health.health, health.max_health)
		_go(State.FLEE)
		return Hurtbox.Result.HIT
	return super.take_hit(info)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	model.play(&"hurt", 0.02, 1.0, true)
	if info.reflected:
		stun(1.6)
	elif state in [State.WATCH, State.FAN, State.FALL]:
		_go(State.VANISH)


func stun(seconds: float) -> void:
	if state in [State.WATCH, State.FAN, State.FALL, State.STUNNED]:
		stun_left = maxf(stun_left, seconds)
		state = State.STUNNED


func _die() -> void:
	state = State.DEAD
	for m in _marks:
		if is_instance_valid(m):
			m.queue_free()
	_marks.clear()
	if model:
		model.scale = Vector3.ONE
		model.play(&"death", 0.03, 1.0, true)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.2, 16, 3.0, 4.0, 1.0, 1.0, Color(0.5, 0.75, 1.4))
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	if model:
		tween.tween_property(model, "scale", Vector3.ONE * 0.01, 0.4)
	tween.tween_callback(queue_free)
