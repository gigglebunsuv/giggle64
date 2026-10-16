class_name Bomb
extends Throwable
## A bomb, after OoT's EnBom (z_en_bom.c). The hero pulls one out of the bag
## lit and holds it overhead like a pot; A, B or an item button throws it, and
## with the stick at rest A sets it down at his feet.
## - The fuse burns 70 frames (3.5 s at 20 Hz) whether held, flying or lying
##   still; the bomb flashes red faster as it runs down.
## - Thrown, it falls with gravity -1.2, bounces off the floor at 0.3x when it
##   lands faster than 3 units a frame, rebounds off walls keeping 0.7 of its
##   speed, and skids to a stop (speed -1 a frame on the ground, -0.08 in the air).
## - It explodes where it is: a sphere growing 8 units a frame for 10 frames
##   (2.4 m across at its widest) hurts everything in it, the hero too
##   (AT_TYPE_ALL), shakes the camera (Camera_RequestQuake 2, 11, 8) and breaks
##   whatever is "bombable" (cracked walls, boulders, brittle coral).
## - Falling in water puts it out.

const FUSE := 70.0
const BOUNCE := 0.3
const WALL_KEEP := 0.7

## Frames of fuse left (20 Hz).
var fuse := FUSE
var _resting := false
var _flash := 0.0


static func make() -> Bomb:
	var b := Bomb.new()
	b.kind = Throwable.Kind.ROCK
	b.name = "Bomb"
	b._mesh = MeshInstance3D.new()
	b._mesh.name = "Mesh"
	b._mesh.mesh = load("res://assets/models/bomb_mesh.tres")
	b._mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(b._mesh)
	return b


func _ready() -> void:
	super._ready()
	add_to_group("bombs")
	Sfx.play("bomb_fuse", -6.0, 0.05)


func rest_offset() -> float:
	return 0.02


func release(yaw: float, speed: float, vy: float) -> void:
	phase = Phase.FLYING
	_resting = false
	velocity_oot = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed + Vector3.UP * vy
	_spin = Vector2.ZERO
	_spin_target = Vector2.ZERO


## Set down gently at the hero's feet (no throw).
func set_down(at: Vector3) -> void:
	phase = Phase.FLYING
	global_position = at
	velocity_oot = Vector3.ZERO


func drop() -> void:
	release(rotation.y, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if phase == Phase.DONE:
		return
	var f := delta * OOT_FPS
	fuse -= f
	_update_flash(delta)
	if fuse <= 0.0:
		explode()
		return
	if phase == Phase.HELD:
		return
	_life += delta
	velocity_oot.y = maxf(velocity_oot.y - 1.2 * f, -20.0)
	var flat := Vector2(velocity_oot.x, velocity_oot.z)
	var on_ground := _ground_below(0.06)
	flat = flat.move_toward(Vector2.ZERO, (1.0 if on_ground else 0.08) * f)
	velocity_oot.x = flat.x
	velocity_oot.z = flat.y
	var from := global_position + Vector3.UP * RADIUS
	var motion := velocity_oot * OOT_RATE * UNIT * f
	if motion.length() < 0.0001:
		return
	# Down onto the floor: a bounce, or settling.
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), from)
	q.motion = motion
	q.collision_mask = WORLD_MASK
	var space := get_world_3d().direct_space_state
	var r := space.cast_motion(q)
	if r.size() > 0 and r[1] < 1.0:
		global_position += motion * r[0]
		q.transform = Transform3D(Basis(), global_position + Vector3.UP * RADIUS + motion * (r[1] - r[0]))
		var info := space.get_rest_info(q)
		var n: Vector3 = info.get("normal", Vector3.UP)
		if n.y > 0.6:
			if velocity_oot.y < -3.0:
				velocity_oot.y *= -BOUNCE
				Sfx.play("bomb_bounce", -8.0, 0.1)
			else:
				velocity_oot.y = 0.0
		else:
			# EnBom_Move: rebound off the wall, keeping 0.7 of the speed.
			var hv := Vector3(velocity_oot.x, 0, velocity_oot.z)
			var nf := Vector3(n.x, 0, n.z).normalized()
			if hv.dot(nf) < 0.0:
				hv = (hv - 2.0 * hv.dot(nf) * nf) * WALL_KEEP
				velocity_oot.x = hv.x
				velocity_oot.z = hv.z
				Sfx.play("bomb_bounce", -10.0, 0.1)
		return
	global_position += motion
	if _in_water():
		# Out it goes: no blast.
		phase = Phase.DONE
		queue_free()
	elif global_position.y < -60.0:
		queue_free()


func _ground_below(dist: float) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * dist, WORLD_MASK)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## Faster red flashes as the fuse runs down (the timer & flashSpeedScale test).
func _update_flash(delta: float) -> void:
	if not is_instance_valid(_mesh):
		return
	var period := 0.5 if fuse > 40.0 else (0.25 if fuse > 20.0 else 0.1)
	_flash += delta
	var on := fmod(_flash, period) < period * 0.5 and fuse < 60.0
	_mesh.material_override = _red() if on else null


static var _red_mat: StandardMaterial3D = null


static func _red() -> StandardMaterial3D:
	if _red_mat == null:
		_red_mat = StandardMaterial3D.new()
		_red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_red_mat.albedo_color = Color(1.0, 0.25, 0.15)
	return _red_mat


## Even a carried pot breaks when it is hit; a bomb in hand still goes off.
func smash() -> void:
	explode()


func explode() -> void:
	if phase == Phase.DONE:
		return
	phase = Phase.DONE
	var parent := get_parent()
	var p := GameManager.player
	if is_instance_valid(p) and p.held == self:
		p.held = null
		p.model.set_shield_on_back(false)
	Explosion.at(parent, global_position + Vector3.UP * 0.25, thrower)
	queue_free()
