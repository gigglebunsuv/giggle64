extends Enemy
## A mage of the Sapphire Order, the guild that serves Firebuns III. Like
## OoT's Poes and the Wizzrobes of later games it never stands still for long:
## it fades in at a spot near where it keeps watch, turns on the hero, raises
## its staff and throws a bolt of sapphire, then fades out again and appears
## somewhere else. The bolt is turned by any shield (the Mirror Shield sends
## it straight back at the caster). Only while it is there can it be struck.

enum State { HIDDEN, APPEAR, WATCH, CAST, VANISH, STUNNED, DEAD }

@export var notice_range := 14.0
## How far from its post it may appear.
@export var roam := 5.0

var state := State.HIDDEN
var _t := 0.0
var _wait := 0.6


func _ready() -> void:
	super._ready()
	_set_shown(false)
	_wait = _rng.randf_range(0.3, 1.2)


func is_targetable() -> bool:
	return super.is_targetable() and state in [State.WATCH, State.CAST, State.STUNNED]


func _set_shown(on: bool) -> void:
	if model:
		model.visible = on
	# Out of sight it is out of the way too.
	collision_layer = 4 if on else 0
	_set_hurtbox(on)
	var shadow := get_node_or_null("BlobShadow") as Node3D
	if shadow:
		shadow.visible = on


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead()
	velocity = Vector3.ZERO
	if stun_left > 0.0 and state != State.HIDDEN:
		stun_left -= delta
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
				model.scale = Vector3.ONE * clampf(_t / 0.5, 0.05, 1.0)
			if _t >= 0.5:
				_go(State.WATCH)
		State.WATCH:
			model.play(&"idle", 0.2)
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.7:
				_go(State.CAST)
		State.CAST:
			if alive:
				_turn_to(p.global_position, 120.0, delta)
			if _t >= 0.45 and _t - delta < 0.45:
				_fire()
			if _t >= 1.1:
				_go(State.VANISH)
		State.VANISH:
			if model:
				model.scale = Vector3.ONE * clampf(1.0 - _t / 0.4, 0.05, 1.0)
			if _t >= 0.4:
				_set_shown(false)
				_wait = _rng.randf_range(0.8, 1.8)
				_go(State.HIDDEN)
	rotation.y = facing_yaw


## Somewhere near its post, on the floor, a little way from the hero.
func _pick_spot(p: PlayerController) -> void:
	for i in 12:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(1.0, roam)
		var spot := _home + Vector3(cos(a) * d, 0, sin(a) * d)
		if spot.distance_to(p.global_position) < 4.0:
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
			Sfx.play("mage_appear", -6.0, 0.08)
		State.CAST:
			model.play(&"cast", 0.08, 1.0, true)
			Sfx.play("mage_cast", -4.0, 0.06)
		State.VANISH:
			Sfx.play("mage_appear", -8.0, 0.08, 0.8)
			if model:
				model.scale = Vector3.ONE


func _fire() -> void:
	var bolt := Rock.new()
	bolt.mesh_path = "res://assets/models/sapphire_bolt_mesh.tres"
	bolt.spin = false
	bolt.damage = 2
	bolt.speed = 11.0
	bolt.burst_tint = Color(0.5, 0.75, 1.4)
	get_parent().add_child(bolt)
	var p := _player()
	var dir := _forward()
	if p:
		dir = _flat_to(p.global_position).normalized()
	bolt.launch(global_position + Vector3.UP * 1.6 + dir * 0.7, dir, self)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	model.play(&"hurt", 0.02, 1.0, true)
	if state in [State.WATCH, State.CAST]:
		_go(State.VANISH)


func stun(seconds: float) -> void:
	if state in [State.WATCH, State.CAST]:
		stun_left = maxf(stun_left, seconds)
		state = State.STUNNED


func _die() -> void:
	state = State.DEAD
	if model:
		model.scale = Vector3.ONE
		model.play(&"death", 0.03, 1.0, true)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.2, 12, 3.0, 3.5, 0.9, 1.0, Color(0.5, 0.75, 1.4))
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	if model:
		tween.tween_property(model, "scale", Vector3.ONE * 0.01, 0.4)
	tween.tween_callback(queue_free)
