class_name BottledFish
extends Node3D
## A fish let out of a bottle (OoT's bottled fish, EnFish dropped by the
## player): it leaps from the bottle in an arc. Into water, it splashes and
## swims down out of sight; on dry land it flops about for a few seconds,
## then wriggles off (gone in a puff, as OoT's fish do).

const GRAVITY := 9.8
const FLOP_TIME := 4.0

var velocity := Vector3.ZERO
var _mesh: MeshInstance3D
var _t := 0.0
var _landed := false
var _in_water := false
var _water_y := NAN
var _floor_y := 0.0


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.mesh = load("res://assets/models/fish_mesh.tres")
	_mesh.scale = Vector3.ONE * 0.4
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


## Lets the fish leap out ahead of `from` along `dir`.
func leap(dir: Vector3) -> void:
	velocity = dir.normalized() * 3.2 + Vector3.UP * 3.0
	rotation.y = atan2(-dir.x, -dir.z)


func _physics_process(delta: float) -> void:
	_t += delta
	var area := World.area_node if is_instance_valid(World.area_node) else null
	if _in_water:
		# Swimming down and away, fading into the deep.
		global_position += (-global_basis.z * 1.2 + Vector3.DOWN * 0.6) * delta
		_mesh.rotation.z = sin(_t * 14.0) * 0.25
		if global_position.y < _water_y - 1.2 or _t > 2.5:
			queue_free()
		return
	if not _landed:
		velocity.y -= GRAVITY * delta
		var next := global_position + velocity * delta
		_mesh.rotation.x = clampf(-velocity.y * 0.25, -1.2, 1.2)
		_water_y = Surface.water_level(area, next)
		if not is_nan(_water_y) and next.y <= _water_y and velocity.y < 0.0:
			global_position = Vector3(next.x, _water_y, next.z)
			_enter_water()
			return
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, next + Vector3.DOWN * 0.05, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and velocity.y < 0.0:
			global_position = hit.position
			_floor_y = hit.position.y
			_landed = true
			_t = 0.0
			Sfx.play("step_water_0", -8.0, 0.15, 1.4)
			return
		global_position = next
		if _t > 4.0:
			queue_free()
		return
	# Flopping on dry land: little hops, rolling side to side.
	var hop := absf(sin(_t * 7.0)) * 0.12
	global_position.y = _floor_y + 0.06 + hop
	_mesh.rotation = Vector3(0.0, sin(_t * 3.0) * 0.6, PI * 0.5 + sin(_t * 9.0) * 0.5)
	if _t > FLOP_TIME:
		Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position, 5, 1.5, 1.0, 0.4, 0.6, Color(1.6, 1.6, 1.6))
		queue_free()


func _enter_water() -> void:
	_in_water = true
	_t = 0.0
	Sfx.play("splash_big", -10.0, 0.1, 1.5)
