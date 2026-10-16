class_name FlailBall
extends Node3D
## The Iron Flail's ball (Beta 1.4.0, ALttP's Ball and Chain): hurled
## straight ahead from the hero's fist, it flies out to RANGE (or until it
## meets a wall) and swings back on its chain. On the way out it hits:
## - creatures: a heavy blow (HitInfo.heavy, and cleave: an undead knight's
##   shield is knocked aside, as by a greatsword or a Shield Bash);
## - anything in group "flail_targets" (FlailTarget: barred gates, cracked
##   pillars, bells): flail_hit(hero);
## each thing once a throw. The chain is a row of iron links from the fist.

const SPEED := 24.0
const RETURN_SPEED := 20.0
const RANGE := 8.5
const RADIUS := 0.55
const DAMAGE := 4
const LINKS := 10

var hero: PlayerController
var dir := Vector3.FORWARD
var _out := true
var _travel := 0.0
var _hit := {}
var _ball: MeshInstance3D
var _links: Array[MeshInstance3D] = []


func launch(by: PlayerController, direction: Vector3) -> void:
	hero = by
	dir = Vector3(direction.x, 0.0, direction.z).normalized()
	global_position = _fist()
	_ball = MeshInstance3D.new()
	_ball.name = "Ball"
	var path := "res://assets/models/iron_flail_ball_mesh.tres"
	if ResourceLoader.exists(path):
		_ball.mesh = load(path)
	else:
		var sm := SphereMesh.new()
		sm.radius = 0.28
		sm.height = 0.56
		_ball.mesh = sm
	add_child(_ball)
	var link_mesh := SphereMesh.new()
	link_mesh.radius = 0.05
	link_mesh.height = 0.1
	link_mesh.radial_segments = 6
	link_mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.32, 0.36)
	mat.metallic = 0.6
	link_mesh.material = mat
	for i in LINKS:
		var l := MeshInstance3D.new()
		l.mesh = link_mesh
		l.top_level = true
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(l)
		_links.append(l)


func _fist() -> Vector3:
	if not is_instance_valid(hero):
		return global_position
	var hand := hero.model.get_node_or_null(PlayerItems.HAND) as Node3D
	return hand.global_transform * Vector3(0, -0.08, 0) if hand else hero.global_position + Vector3.UP * 1.2


func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero) or hero.is_dead():
		queue_free()
		return
	_ball.rotate_x(delta * 14.0)
	if _out:
		var step := SPEED * delta
		var from := global_position
		var to := from + dir * step
		var q := PhysicsRayQueryParameters3D.create(from, to + dir * RADIUS, 1)
		q.exclude = [hero.get_rid()]
		var wall := get_world_3d().direct_space_state.intersect_ray(q)
		if not wall.is_empty():
			to = (wall.position as Vector3) - dir * RADIUS
			_clang(wall)
			_out = false
		global_position = to
		_travel += step
		_strike()
		if _travel >= RANGE:
			_out = false
	else:
		var home := _fist()
		var to_home := home - global_position
		if to_home.length() < RETURN_SPEED * delta + 0.3:
			queue_free()
			return
		global_position += to_home.normalized() * RETURN_SPEED * delta
	_draw_chain()


func _draw_chain() -> void:
	var a := _fist()
	var b := global_position
	var sag := clampf(a.distance_to(b) * 0.06, 0.0, 0.4)
	for i in _links.size():
		var t := float(i + 1) / float(_links.size() + 1)
		_links[i].global_position = a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * sag


func _clang(hit: Dictionary) -> void:
	Sfx.play("wall_hit_hard", -2.0, 0.06, 0.7)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), hit.position, 6, 2.6, 2.0, 0.3, 0.22, Color(2.0, 1.4, 0.4))
	if is_instance_valid(hero) and hero.camera_rig:
		hero.camera_rig.shake(0.04, 0.12)


## Everything the ball meets on its way out.
func _strike() -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), global_position)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	for h in space.intersect_shape(q, 16):
		var hb := h.collider as Hurtbox
		if hb == null or hb.receiver == hero or _hit.has(hb.receiver):
			continue
		_hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = DAMAGE
		info.knockback = 7.0
		info.heavy = true
		info.cleave = true
		info.kind = "flail"
		info.attacker = hero
		info.source_position = hero.global_position
		if hb.receive_hit(info) == Hurtbox.Result.HIT:
			Sfx.play("sword_hit", 0.0, 0.05, 0.7)
			GameManager.rumble(0.5, 0.12)
		_out = false
	for n in get_tree().get_nodes_in_group("flail_targets"):
		var node := n as Node3D
		if node == null or _hit.has(node) or not node.is_inside_tree():
			continue
		var reach := float(node.call("flail_reach")) if node.has_method("flail_reach") else 1.2
		if node.global_position.distance_to(global_position) < reach + RADIUS:
			_hit[node] = true
			node.call("flail_hit", hero)
			_out = false
