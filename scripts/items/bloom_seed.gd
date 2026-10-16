class_name BloomSeed
extends Node3D
## A seed flung from the Bloom Rod (the Bog Tower's treasure). It flies
## straight along the line of sight, fast, and takes root where it lands:
## - on floor (anything flat enough to stand on) it bursts into a bloom-pod
##   (BloomPod): a sturdy bulb to climb onto, weigh down a switch with, or
##   shoot the Hookshot into;
## - on water, or on the Bog Tower's sinking sludge, it opens into a giant
##   lily pad to stand on;
## - against a wall it only scatters leaves;
## - a creature it strikes is snared by sprouting vines for a moment (a
##   creature with bloom_hit() reacts in its own way: the Mire Toad chokes).
## Only one bloom grows at a time: a new one withers the last.

const RANGE := 14.0
const SPEED := 26.0
## World (1) and hurtboxes (16).
const MASK := 1 | 16

var shooter: PlayerController = null
var _dir := Vector3.FORWARD
var _travelled := 0.0
var _mesh: MeshInstance3D
var _done := false


func _ready() -> void:
	top_level = true
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/bloom_seed_mesh.tres")
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	add_to_group("bloom_seeds")


func launch(by: PlayerController, from: Vector3, dir: Vector3) -> void:
	shooter = by
	_dir = dir.normalized()
	global_position = from


func _physics_process(delta: float) -> void:
	if _done:
		return
	var step := SPEED * delta
	var from := global_position
	var to := from + _dir * step
	_mesh.rotation.x += delta * 18.0
	# Water first: a seed meeting the surface opens on it.
	var wy := _water_crossing(from, to)
	if not is_nan(wy):
		var t := (from.y - wy) / maxf(from.y - to.y, 0.0001)
		_take_root(from.lerp(to, clampf(t, 0.0, 1.0)), true)
		return
	var q := PhysicsRayQueryParameters3D.create(from, to, MASK)
	q.collide_with_areas = true
	if is_instance_valid(shooter):
		q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var hb := hit.collider as Hurtbox
		if hb:
			if is_instance_valid(shooter) and hb.receiver == shooter:
				hit = {}
			else:
				_strike(hb, hit.position)
				return
		if not hit.is_empty():
			var n: Vector3 = hit.normal
			if n.y > 0.6:
				_take_root(hit.position, _in_sludge(hit.position))
			else:
				_fizzle(hit.position)
			return
	global_position = to
	_travelled += step
	if _travelled >= RANGE:
		# Out of reach, it drops and comes to nothing.
		_fizzle(global_position)


## The height of a water surface the step from `a` to `b` passes down
## through (NAN = none), from the area's "water" list.
func _water_crossing(a: Vector3, b: Vector3) -> float:
	var area := World.area_node if is_instance_valid(World.area_node) else null
	if area == null:
		return NAN
	for w: Array in area.get_meta("water", []):
		var rect: Rect2 = w[0]
		var y := float(w[1])
		if a.y >= y and b.y < y and rect.has_point(Vector2(b.x, b.z)):
			return y
	# Deep sludge (the Bog Tower's pond): markers with its rect and surface.
	for m in get_tree().get_nodes_in_group("sludge"):
		var node := m as Node3D
		var sr: Rect2 = node.get_meta("rect", Rect2())
		var sy := float(node.get_meta("y", -INF))
		if a.y >= sy and b.y < sy and sr.has_point(Vector2(b.x, b.z)):
			return sy
	return NAN


static func _in_sludge(p: Vector3) -> bool:
	for n in Engine.get_main_loop().get_nodes_in_group("quicksand"):
		var a := n as Area3D
		if a == null:
			continue
		for c in a.get_children():
			var cs := c as CollisionShape3D
			if cs and cs.shape is BoxShape3D:
				var local := cs.global_transform.affine_inverse() * p
				var e := (cs.shape as BoxShape3D).size * 0.5
				if absf(local.x) <= e.x and absf(local.z) <= e.z and local.y <= e.y + 0.3 and local.y >= -e.y - 0.6:
					return true
	return false


func _take_root(at: Vector3, pad: bool) -> void:
	_done = true
	var parent := get_parent()
	BloomPod.grow(parent, at, pad, shooter.facing_yaw if is_instance_valid(shooter) else 0.0)
	queue_free()


func _strike(hb: Hurtbox, at: Vector3) -> void:
	_done = true
	var r := hb.receiver
	if r and r.has_method("bloom_hit"):
		r.call("bloom_hit", self)
	elif r is Enemy:
		(r as Enemy).stun(2.0)
		Sfx.play("lift_plant", -4.0, 0.1, 0.8)
	elif r and r.has_method("boomerang_hit"):
		# Switches and the like take a seed like a tap.
		r.call("boomerang_hit", self)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), at, 8, 2.2, 2.4, 0.8, 1.0, Color(0.7, 1.0, 0.6))
	queue_free()


func _fizzle(at: Vector3) -> void:
	_done = true
	Sfx.play("grass_cut", -8.0, 0.1, 1.3)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), at, 6, 1.8, 2.0, 0.7, 0.8, Color(0.7, 1.0, 0.6))
	queue_free()
