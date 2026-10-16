class_name GoblinArcher
extends Enemy
## A Cinder Goblin with a short bow (Chapter IV's war bands): it keeps its
## distance, draws, and looses an arrow straight at the hero (any shield
## stops it; the Mirror Shield sends it back). Too close, it backs away and
## then shoots again. Hit, it reels.

enum State { IDLE, AIM, LOOSE, BACK, HURT, STUNNED, DEAD }

@export var notice_range := 16.0
@export var keep_away := 4.5
@export var draw_time := 0.9
@export var arrow_damage := 1
@export var arrow_speed := 15.0

var state := State.IDLE
var _t := 0.0
var _cool := 1.0


func _ready() -> void:
	corpse_time = 1.4
	super._ready()
	_cool = _rng.randf_range(0.6, 1.8)
	# The bow in its left fist (the club stays put away).
	var hand := model.find_child("HandL", true, false) as Node3D if model else null
	if hand and ResourceLoader.exists("res://assets/models/bow_mesh.tres"):
		var bow := MeshInstance3D.new()
		bow.name = "Bow"
		bow.mesh = load("res://assets/models/bow_mesh.tres")
		bow.position = Vector3(0, -0.12, 0)
		bow.rotation = Vector3(0, PI / 2.0, 0)
		bow.scale = Vector3.ONE * 1.3
		hand.add_child(bow)
	var club := model.find_child("Club", true, false) as Node3D if model else null
	if club:
		club.visible = false


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if p else 99.0
	if stun_left > 0.0:
		stun_left -= delta
		_brake(delta)
		model.play(&"stunned", 0.1)
		_fall(delta)
		move_and_slide()
		return
	match state:
		State.IDLE:
			_brake(delta)
			model.play(&"idle", 0.2)
			if alive and dist < notice_range * Progress.stealth() and _can_see_player(notice_range, 6.0):
				_turn_to(p.global_position, 220.0, delta)
				if dist < keep_away:
					_go(State.BACK)
				elif _cool <= 0.0:
					_go(State.AIM)
		State.AIM:
			_brake(delta)
			if alive:
				_turn_to(p.global_position, 260.0, delta)
			if _t >= draw_time:
				_go(State.LOOSE)
		State.LOOSE:
			_brake(delta)
			if _t >= 0.05 and _t - delta < 0.05:
				_shoot()
			if _t >= 0.4:
				_cool = _rng.randf_range(1.4, 2.4)
				_go(State.IDLE)
		State.BACK:
			if alive:
				_turn_to(p.global_position, 260.0, delta)
				var away := -_flat_to(p.global_position).normalized() * 2.6
				velocity.x = away.x
				velocity.z = away.z
			model.play(&"walk", 0.15, -1.0)
			if _t >= 0.9 or dist > keep_away + 2.0:
				_go(State.AIM if _cool <= 0.0 else State.IDLE)
		State.HURT:
			_brake(delta)
			if _t >= 0.4:
				_go(State.IDLE)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.AIM:
			model.play(&"windup", 0.08, 1.4, true)
			Sfx.play("bow_draw", -6.0, 0.05, 0.9)
		State.LOOSE:
			model.play(&"attack", 0.03, 1.0, true)
		State.HURT:
			model.play(&"hurt", 0.02, 1.0, true)


func _shoot() -> void:
	var arrow := Rock.new()
	arrow.mesh_path = "res://assets/models/arrow_mesh.tres"
	arrow.spin = false
	arrow.damage = arrow_damage
	arrow.speed = arrow_speed
	arrow.life = 1.6
	arrow.burst_tint = Color(0.6, 0.45, 0.3)
	get_parent().add_child(arrow)
	var p := _player()
	var dir := _forward()
	if p:
		dir = _flat_to(p.global_position).normalized()
	arrow.launch(global_position + Vector3.UP * 1.2 + dir * 0.6, dir, self)
	Sfx.play("bow_shoot", -4.0, 0.06)


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	_go(State.HURT)


func _die() -> void:
	state = State.DEAD
	super._die()
