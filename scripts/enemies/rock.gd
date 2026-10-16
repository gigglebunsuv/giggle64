class_name Rock
extends Node3D
## A rock spat by an octorok (EnOkuta's projectile): it flies straight at 10
## units a frame (9 m/s) for two seconds. It hurts the hero; if he catches it
## on his shield it flies back the way it came (OoT reflects it off the
## shield) and then hurts whatever it hits, its owner included. It breaks on
## walls.

const SPEED := 9.0
const LIFE := 2.0

## What flies: the octorok's rock, or a scarecrow archer's straw bolt.
var mesh_path := "res://assets/models/rock_mesh.tres"
var spin := true
## Damage to the hero (a reflected one does `damage + 1` to its target).
var damage := 1
## Flight speed (m/s) and how long it flies.
var speed := SPEED
var life := LIFE
## The break sound and fragments' tint (a fireball bursts into embers).
var burst_tint := Color(0.7, 0.68, 0.65)
var velocity := Vector3.ZERO
var shooter: Node3D = null
var reflected := false
var _life := LIFE


func _ready() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load(mesh_path)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	add_to_group("projectiles")


func launch(from: Vector3, dir: Vector3, by: Node3D) -> void:
	shooter = by
	global_position = from
	_life = life
	velocity = Vector3(dir.x, 0, dir.z).normalized() * speed


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_break()
		return
	var from := global_position
	var to := from + velocity * delta
	# World (1), the hero's hurtbox (8) and, once reflected, enemy hurtboxes (16).
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 8 | (16 if reflected else 0))
	q.collide_with_areas = true
	var ex: Array[RID] = []
	if shooter and is_instance_valid(shooter) and not reflected:
		var hb := shooter.get_node_or_null("Hurtbox") as Area3D
		if hb:
			ex.append(hb.get_rid())
		if shooter is CollisionObject3D:
			ex.append((shooter as CollisionObject3D).get_rid())
	var hero := GameManager.player
	if reflected and hero:
		ex.append(hero.get_rid())
		var phb := hero.get_node_or_null("Hurtbox") as Area3D
		if phb:
			ex.append(phb.get_rid())
	q.exclude = ex
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		global_position = to
		if spin:
			rotation.x += 12.0 * delta
		else:
			rotation.y = atan2(-velocity.x, -velocity.z)
		return
	var hb := hit.collider as Hurtbox
	if hb:
		var info := HitInfo.new()
		info.damage = damage if not reflected else damage + 1
		info.reflected = reflected
		info.knockback = 3.0
		info.attacker = GameManager.player if reflected else shooter
		info.source_position = from - velocity.normalized() * 1.0
		var r := hb.receive_hit(info)
		if r == Hurtbox.Result.BLOCKED and not reflected:
			# Batted back off the shield; the Mirror Shield sends it straight
			# at the octorok that spat it.
			reflected = true
			velocity = -velocity
			if Equipment.guard().get("mirror", false) and is_instance_valid(shooter):
				var aim := shooter.global_position + Vector3.UP * 0.5 - from
				velocity = Vector3(aim.x, 0, aim.z).normalized() * speed * 1.3
			_life = life
			global_position = from
			return
		if r == Hurtbox.Result.IGNORED:
			global_position = to
			return
	_break()


func _break() -> void:
	Sfx.play("pot_break", -12.0, 0.1, 1.4)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 5, 1.5, 2.0, 0.6, 0.8, burst_tint)
	queue_free()
