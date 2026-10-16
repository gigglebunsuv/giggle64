class_name PuffNut
extends Node3D
## A thrown Puff Nut, after OoT's Deku Nut (EnArrow's ARROW_NUT): it flies in
## a low arc and bursts on the first thing it touches, or on landing, in a
## flash of spores. Every creature within BURST_RADIUS that can see the flash
## is dazed (Enemy.daze) for DAZE_TIME; it does no harm.

const SPEED := 9.0
const GRAVITY := 14.0
const LIFE := 1.2
const BURST_RADIUS := 4.0
const DAZE_TIME := 4.0
const HIT_MASK := 1 | 16

var velocity := Vector3.ZERO
var thrower: CollisionObject3D = null
var burst := false
var _t := 0.0


func _ready() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var path := "res://assets/models/puff_nut_mesh.tres"
	mi.mesh = load(path) if ResourceLoader.exists(path) else SphereMesh.new()
	if not ResourceLoader.exists(path):
		mi.scale = Vector3.ONE * 0.12
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	add_to_group("puff_nuts")


func launch(by: CollisionObject3D, from: Vector3, dir: Vector3) -> void:
	thrower = by
	global_position = from
	velocity = dir.normalized() * SPEED + Vector3.UP * 2.0


func _physics_process(delta: float) -> void:
	if burst:
		return
	_t += delta
	velocity.y -= GRAVITY * delta
	var from := global_position
	var to := from + velocity * delta
	var q := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK)
	q.collide_with_areas = true
	if thrower:
		var ex: Array[RID] = [thrower.get_rid()]
		var hb := thrower.get_node_or_null("Hurtbox") as Area3D
		if hb:
			ex.append(hb.get_rid())
		q.exclude = ex
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var hb := hit.collider as Hurtbox
		if hb and hb.receiver is Collectible:
			global_position = to
			return
		global_position = hit.position
		pop()
		return
	global_position = to
	rotate_x(delta * 12.0)
	if _t >= LIFE:
		pop()


## The burst: a white flash and a puff of spores, and every creature near it dazed.
func pop() -> void:
	if burst:
		return
	burst = true
	Sfx.play("nut_pop", -2.0, 0.05)
	SpellEffect.make(get_parent(), "flash", global_position)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 12, 2.5, 3.0, 0.5, 0.7, Color(1.4, 1.35, 0.9))
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null or en.is_dead() or en.global_position.distance_to(global_position) > BURST_RADIUS:
			continue
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, en.global_position + Vector3.UP * en.target_height() * 0.6, 1)
		if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			en.daze(DAZE_TIME)
	queue_free()
