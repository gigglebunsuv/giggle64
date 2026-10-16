class_name WindZone
extends Area3D
## A gale blowing through part of Skyreach Spire (from a vent, a broken
## window, the open sky): while the hero is inside it pushes him along `dir`
## at `strength` m/s, enough to shove him off a ledge, unless he wears the
## Wind Boots. With `flag` set, the wind swings round to `dir_on` (a wind vane
## turned by a switch); with `stop_flag` set it dies away.
## Streaks of drifting snow show which way it blows.

@export var dir := Vector3(1, 0, 0)
@export var strength := 4.0
@export var flag := ""
@export var dir_on := Vector3(-1, 0, 0)
@export var stop_flag := ""

var _hero_in := false
var _snow: CPUParticles3D
var _size := Vector3.ONE


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("wind_zones")
	body_entered.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_hero_in = true)
	body_exited.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_hero_in = false)
	for c in get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			_size = ((c as CollisionShape3D).shape as BoxShape3D).size
	_snow = CPUParticles3D.new()
	_snow.name = "Snow"
	_snow.amount = clampi(int(_size.x * _size.z * 0.6), 12, 120)
	_snow.lifetime = 1.4
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = _size * 0.5
	_snow.gravity = Vector3.ZERO
	_snow.spread = 6.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.55)
	quad.material = m
	_snow.mesh = quad
	add_child(_snow)
	_aim_snow()


func blowing() -> Vector3:
	if stop_flag != "" and Progress.flag(stop_flag):
		return Vector3.ZERO
	var d := dir_on if flag != "" and Progress.flag(flag) else dir
	d.y = 0.0
	return d.normalized() * strength


func _aim_snow() -> void:
	var w := blowing()
	_snow.emitting = w != Vector3.ZERO
	if w != Vector3.ZERO:
		_snow.direction = w.normalized()
		_snow.initial_velocity_min = strength * 2.0
		_snow.initial_velocity_max = strength * 2.6


func _physics_process(_delta: float) -> void:
	_aim_snow()
	var p := GameManager.player
	if _hero_in and is_instance_valid(p) and not p.is_dead():
		p.wind_push += blowing()
