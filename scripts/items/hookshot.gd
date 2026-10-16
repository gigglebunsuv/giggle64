class_name Hookshot
extends Node3D
## The Hookshot's chain and tip in flight, after OoT's ArmsHook (z_arms_hook.c):
## - It shoots at 20 units a frame (x1.5) for 13 frames, about 11.7 m.
## - A line test along each frame's travel finds what it meets. A surface
##   flagged "hookable" (the wooden targets) holds it, and the hero is pulled
##   to it at 30 units a frame (ArmsHook_PullPlayer); anything else bounces it
##   back with a spark (NA_SE_IT_HOOKSHOT_REFLECT).
## - A creature it strikes is stunned (like the boomerang) and takes a little
##   damage; a rupee, heart or key it meets is dragged back to the hero.
## - Out of reach, or on a miss, it reels back in at 200 units a frame.

enum Phase { SHOOT, RETURN, PULL, DONE }

const OOT_FPS := 20.0
const OOT_RATE := 1.5
const UNIT := 0.03
const SPEED := 20.0
const LIFE := 13.0
const RETURN_SPEED := 200.0
const PULL_SPEED := 30.0
const LINKS := 40
## The world (1) and hurtboxes (16: creatures, and the pickups' own).
const HIT_MASK := 1 | 16

signal finished

var phase := Phase.SHOOT
var shooter: PlayerController
## Where it bit in, and the surface's normal (for the pull).
var anchor := Vector3.ZERO
var anchor_normal := Vector3.ZERO
var hit_object: Object = null
var _dir := Vector3.FORWARD
## The Longshot (Chapter IV) flies twice as long, so twice as far.
var _timer := LIFE * (2.0 if Progress.flag(Progress.LONGSHOT) else 1.0)
var _tip: MeshInstance3D
var _links: Array[MeshInstance3D] = []
var _carried: Node3D = null


func _ready() -> void:
	top_level = true
	_tip = MeshInstance3D.new()
	_tip.name = "Tip"
	_tip.mesh = load("res://assets/models/hookshot_tip_mesh.tres")
	_tip.top_level = true
	add_child(_tip)
	var link_mesh: Mesh = load("res://assets/models/hookshot_link_mesh.tres")
	for i in LINKS:
		var l := MeshInstance3D.new()
		l.mesh = link_mesh
		l.top_level = true
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(l)
		_links.append(l)
	add_to_group("hookshots")


static func mps(units: float) -> float:
	return units * OOT_RATE * OOT_FPS * UNIT


## Fires from `from` along `dir`.
func launch(by: PlayerController, from: Vector3, dir: Vector3) -> void:
	shooter = by
	_dir = dir.normalized()
	_tip.global_position = from
	_face(_dir)
	Sfx.play("hookshot_fire", -3.0, 0.05)


func tip_position() -> Vector3:
	return _tip.global_position


## Where the chain starts: the launcher in the hero's hand.
func origin() -> Vector3:
	return shooter.hookshot_origin() if is_instance_valid(shooter) else _tip.global_position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(shooter):
		queue_free()
		return
	var frames := delta * OOT_FPS
	match phase:
		Phase.SHOOT:
			_timer -= frames
			var from := _tip.global_position
			var to := from + _dir * mps(SPEED) * delta
			if _test(from, to):
				pass
			elif _timer <= 0.0:
				_go_back()
			else:
				_tip.global_position = to
		Phase.RETURN:
			var home := origin()
			var step := mps(RETURN_SPEED) * delta
			var to := home - _tip.global_position
			if to.length() <= step:
				_finish()
				return
			_tip.global_position += to.normalized() * step
			if is_instance_valid(_carried):
				_carried.global_position = _tip.global_position
		Phase.PULL:
			# The hero drives himself along (PlayerController._state_hookfly);
			# the chain just spans the gap.
			pass
	_draw_chain()


## The line test for this frame's travel. True when something stopped it.
func _test(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK)
	q.collide_with_areas = true
	q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	hit_object = hit.collider
	_tip.global_position = hit.position
	# A creature: stunned, nicked, and the chain comes back.
	var hb := hit.collider as Hurtbox
	if hb:
		if hb.receiver == shooter:
			return false
		var target: Node = hb.receiver
		# A rupee, heart or key: it rides the tip back to him.
		if target and target.has_method("attach_to"):
			target.attach_to(_tip)
			_carried = target as Node3D
			Sfx.play("hookshot_stick", -6.0)
			_go_back()
			return true
		if target is EnemyPart:
			target = (target as EnemyPart).creature
		if target and target.has_method("hookshot_hit"):
			target.hookshot_hit(self)
		elif target and target.has_method("boomerang_hit"):
			target.boomerang_hit(self)
			var info := HitInfo.new()
			info.damage = 1
			info.knockback = 1.0
			info.attacker = shooter
			info.source_position = from
			hb.receive_hit(info)
		Sfx.play("hookshot_stick", -4.0)
		_go_back()
		return true
	var shape := _hit_shape(hit)
	if shape and shape.get_meta("hookable", false):
		anchor = hit.position
		anchor_normal = hit.normal
		phase = Phase.PULL
		Sfx.play("hookshot_stick", -2.0)
		shooter.hook_pull(self)
		return true
	# Anything else: it glances off.
	Sfx.play("hookshot_reflect", -3.0, 0.05)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), hit.position, 4, 1.8, 1.2, 0.25, 0.18, Color(2.0, 1.6, 0.6))
	_go_back()
	return true


static func _hit_shape(hit: Dictionary) -> Node:
	var body := hit.get("collider") as CollisionObject3D
	if body == null or not hit.has("shape"):
		return null
	var owner_id := body.shape_find_owner(hit.shape)
	if owner_id < 0:
		return null
	return body.shape_owner_get_owner(owner_id) as Node


func _go_back() -> void:
	phase = Phase.RETURN


## The hero arrived (or let go): the chain is put away.
func release() -> void:
	_finish()


func _finish() -> void:
	if phase == Phase.DONE:
		return
	phase = Phase.DONE
	if is_instance_valid(_carried) and is_instance_valid(shooter):
		_carried.global_position = shooter.global_position + Vector3.UP * 0.5
		if _carried.has_method("collect"):
			_carried.collect(shooter)
	finished.emit()
	queue_free()


func _face(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.BACK
	_tip.global_basis = Basis.looking_at(dir.normalized(), up)


func _draw_chain() -> void:
	var a := origin()
	var b := _tip.global_position
	var span := b - a
	var n := span.length()
	var dir := span / maxf(n, 0.001)
	var basis := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.BACK)
	for i in LINKS:
		var l := _links[i]
		var k := (i + 0.5) / LINKS
		l.visible = n > 0.2
		l.global_transform = Transform3D(basis.rotated(dir, PI * 0.5 * (i % 2)), a + span * k)
	if phase != Phase.PULL:
		_face(_dir if phase == Phase.SHOOT else -span)
