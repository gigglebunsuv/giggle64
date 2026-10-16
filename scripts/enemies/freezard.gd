extends Enemy
## A Freezard of Skyreach Spire, after OoT's EnFz: a lump of living ice with a
## grim face that never moves from its spot. When the hero is near it turns
## to him and breathes a freezing mist; between breaths it can be chipped
## apart with the sword. A burning arrow melts it at once.

enum State { IDLE, BREATHE, REST, DEAD }

@export var notice_range := 7.0
@export var breath_time := 1.5
@export var rest_time := 2.0

var state := State.IDLE
var _t := 0.0
var _mist: CPUParticles3D


func _ready() -> void:
	corpse_time = 0.6
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 2
		attack_hitbox.knockback = 3.0
	_mist = CPUParticles3D.new()
	_mist.name = "Mist"
	_mist.position = Vector3(0, 1.4, -0.5)
	_mist.amount = 40
	_mist.lifetime = 0.7
	_mist.emitting = false
	_mist.direction = Vector3(0, -0.2, -1)
	_mist.spread = 14.0
	_mist.initial_velocity_min = 4.0
	_mist.initial_velocity_max = 5.5
	_mist.gravity = Vector3.ZERO
	_mist.scale_amount_min = 0.6
	_mist.scale_amount_max = 1.4
	var quad := QuadMesh.new()
	quad.size = Vector2(0.4, 0.4)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.85, 0.95, 1.0, 0.5)
	quad.material = m
	_mist.mesh = quad
	add_child(_mist)


func _physics_process(delta: float) -> void:
	_t += delta
	if _dead:
		_mist.emitting = false
		return
	var p := _player()
	var alive := p != null and not p.is_dead()
	var dist := _flat_dist(p.global_position) if alive else 99.0
	match state:
		State.IDLE:
			model.play(&"idle", 0.2)
			if alive and dist < notice_range:
				_turn_to(p.global_position, 90.0, delta)
				if _t > 0.8:
					_go(State.BREATHE)
		State.BREATHE:
			if alive:
				_turn_to(p.global_position, 40.0, delta)
			if attack_hitbox and _t > 0.2 and not attack_hitbox.active:
				attack_hitbox.activate()
			if _t >= breath_time:
				_go(State.REST)
		State.REST:
			if _t >= rest_time:
				_go(State.IDLE)
	rotation.y = facing_yaw


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.BREATHE:
		attack_hitbox.deactivate()
	_mist.emitting = s == State.BREATHE
	match s:
		State.BREATHE:
			model.play(&"breathe", 0.1, 1.0, true)
			Sfx.play("sand_hiss", -6.0, 0.1, 1.4)
		State.REST:
			model.play(&"idle", 0.2)


## No knockback: it is rooted to its spot.
func _hurt(_info: HitInfo) -> void:
	Sfx.play("crystal_hit", -8.0, 0.1, 0.7)


## Made of ice: a Frost Arrow does it no harm.
func can_freeze() -> bool:
	return false


func burn() -> void:
	if _dead:
		return
	Sfx.play("splash_big", -4.0, 0.05, 1.4)
	health.apply_damage(health.health)


func _die() -> void:
	state = State.DEAD
	_mist.emitting = false
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.0, 16, 2.5, 3.5, 1.2, 1.0, Color(0.8, 0.95, 1.2))
	Sfx.play("crystal_hit", -2.0, 0.05, 0.5)
	super._die()
