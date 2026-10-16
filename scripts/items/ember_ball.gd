class_name EmberBall
extends Node3D
## A fireball from the Ember Rod (Chapter V, after ALttP's Fire Rod): it flies
## straight ahead until it strikes something, and burns what it touches.
## - Torches: an unlit one is lit (not a star brazier: that takes starlight).
## - Burnables ("burnables": thorns, webs, rime-ice): burnt away or melted.
## - Ice sheets on the frozen falls (MalletStake.brittle): melted.
## - Creatures: a scorching blow (HitInfo.kind "ember"), twice as hard to the
##   undead (group "undead"); creatures of fire ("fireproof") shrug it off,
##   and anything frozen thaws.
## It bursts on a wall, or burns out after LIFE seconds.

const SPEED := 15.0
const LIFE := 1.15
const RADIUS := 0.45
const DAMAGE := 2

var dir := Vector3.FORWARD
var from_player: Node3D
var _t := 0.0
var _done := false
var _flame: MeshInstance3D
var _light: OmniLight3D


func launch(by: Node3D, at: Vector3, direction: Vector3) -> void:
	from_player = by
	global_position = at
	dir = direction.normalized()
	_flame = MeshInstance3D.new()
	_flame.name = "Flame"
	_flame.mesh = load("res://assets/models/flame_mesh.tres")
	_flame.scale = Vector3.ONE * 1.4
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.22)
	_light.light_energy = 2.2
	_light.omni_range = 5.0
	_light.shadow_enabled = false
	add_child(_light)
	var trail := CPUParticles3D.new()
	trail.name = "Trail"
	trail.amount = 18
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.direction = Vector3.UP
	trail.spread = 40.0
	trail.initial_velocity_min = 0.3
	trail.initial_velocity_max = 0.9
	trail.gravity = Vector3(0, 1.0, 0)
	trail.scale_amount_min = 0.12
	trail.scale_amount_max = 0.22
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.6, 0.2, 0.8)
	mat.vertex_color_use_as_albedo = true
	qm.material = mat
	trail.mesh = qm
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.6, 0.15, 0.05, 0.0))
	trail.color_ramp = grad
	add_child(trail)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var step := dir * SPEED * delta
	var from := global_position
	var to := from + step
	# Walls and floors (layer 1): burst there.
	var q := PhysicsRayQueryParameters3D.create(from, to + dir * RADIUS, 1)
	if from_player is CollisionObject3D:
		q.exclude = [(from_player as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position = hit.position - dir * 0.2
		_touch(true, hit.collider)
		return
	global_position = to
	_flame.rotation.y += delta * 9.0
	if _touch(false, null) or _t >= LIFE:
		_burst()


## Everything burnable within reach; true once it has struck something solid.
func _touch(wall: bool, collider: Object) -> bool:
	var at := global_position
	var struck := wall
	for n in get_tree().get_nodes_in_group("torches"):
		var t := n as Torch
		if t and not t.lit and not t.star and (t.global_position + Vector3.UP * t.bowl_height).distance_to(at) < 1.0:
			t.light_up()
			struck = true
	for n in get_tree().get_nodes_in_group("burnables"):
		var b := n as Node3D
		if b and b.is_inside_tree() and (b.call("burn_reach") as float) >= b.global_position.distance_to(at) - 0.2:
			b.call("ember_hit", self)
			struck = true
	if collider and collider is Node and (collider as Node).has_method("ember_hit"):
		(collider as Node).call("ember_hit", self)
	for n in get_tree().get_nodes_in_group("mallet_targets"):
		var m := n as MalletStake
		if m and m.brittle and _near_sheet(m, at):
			m.call("ember_hit", self)
			struck = true
	for hb in _hurtboxes(at):
		var info := HitInfo.new()
		var r: Node = hb.receiver
		info.damage = DAMAGE * (2 if r and r.is_in_group("undead") else 1)
		info.knockback = 3.0
		info.kind = "ember"
		info.attacker = from_player
		info.source_position = at - dir
		if r and r.is_in_group("fireproof"):
			Sfx.play("shield_block", -8.0, 0.05, 1.4)
		else:
			if r is Enemy and (r as Enemy).frozen:
				(r as Enemy)._undaze()
			hb.receive_hit(info)
		struck = true
		break
	if struck:
		_burst()
	return struck


func _near_sheet(m: MalletStake, at: Vector3) -> bool:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	return absf(local.x) < half.x + RADIUS and local.y > -0.3 and local.y < m.size.y + 0.3 and absf(local.z) < half.z + RADIUS + 0.4


func _hurtboxes(at: Vector3) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), at)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	var out: Array = []
	for h in get_world_3d().direct_space_state.intersect_shape(q, 8):
		var hb := h.collider as Hurtbox
		if hb and hb.monitorable and hb.receiver != from_player:
			out.append(hb)
	return out


func _burst() -> void:
	if _done:
		return
	_done = true
	Sfx.play("fire_whoosh", -8.0, 0.08, 1.3)
	if get_parent():
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 8, 2.5, 2.5, 0.4, 0.4, Color(2.0, 1.0, 0.3))
	_flame.visible = false
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 0.0, 0.25)
	tw.tween_callback(queue_free)
