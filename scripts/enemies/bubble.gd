class_name Bubble
extends Node3D
## A bubble blown by Carapax: it drifts toward the hero, bending a little
## toward him as it goes, and bursts on whatever it meets (hurting him unless
## his shield takes it). The sword or an arrow pops it harmlessly; it bursts
## by itself after five seconds. The Mirror Shield throws it back at
## whoever blew it, and then it bursts on whatever it meets (an eye, say).

const LIFE := 5.0

var velocity := Vector3.ZERO
var shooter: Node3D = null
var reflected := false
var _life := LIFE
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("projectiles")
	_mesh = MeshInstance3D.new()
	_mesh.mesh = load("res://assets/models/bubble_mesh.tres")
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.45
	cs.shape = s
	hb.add_child(cs)
	add_child(hb)


func launch(from: Vector3, vel: Vector3, by: Node3D) -> void:
	global_position = from
	velocity = vel
	shooter = by


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		pop()
		return
	var p := GameManager.player
	if reflected:
		_fly_back(delta)
		return
	if p and not p.is_dead():
		var chest := p.global_position + Vector3.UP * 1.0
		var want := (chest - global_position).normalized() * velocity.length()
		velocity = velocity.lerp(want, 0.6 * delta)
		if global_position.distance_to(chest) < 0.8:
			var info := HitInfo.new()
			info.damage = 1
			info.knockback = 3.0
			info.attacker = shooter
			info.source_position = global_position - velocity.normalized()
			if p.take_hit(info) == Hurtbox.Result.BLOCKED and Equipment.guard().get("mirror", false) 					and is_instance_valid(shooter):
				_reflect()
				return
			pop()
			return
	var to := global_position + velocity * delta
	var q := PhysicsRayQueryParameters3D.create(global_position, to, 1)
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		pop()
		return
	global_position = to
	_mesh.scale = Vector3.ONE * (1.0 + sin(_life * 9.0) * 0.06)


func _reflect() -> void:
	reflected = true
	_life = LIFE
	var to := (shooter.global_position + Vector3.UP * 1.6) - global_position
	velocity = to.normalized() * maxf(velocity.length(), 4.0) * 1.6
	Sfx.play("crystal_hit", -10.0, 0.05, 1.5)


## Flying back off the Mirror Shield: it bursts on the first wall or hurtbox
## (the hero's excepted), striking it as if he had.
func _fly_back(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	q.collide_with_areas = true
	var own := get_node_or_null("Hurtbox") as Area3D
	if own:
		q.exclude = [own.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		global_position = to
		return
	var hb := hit.collider as Hurtbox
	if hb:
		var info := HitInfo.new()
		info.damage = 2
		info.knockback = 2.0
		info.attacker = GameManager.player
		info.source_position = from - velocity.normalized()
		hb.receive_hit(info)
	pop()


func take_hit(info: HitInfo) -> int:
	if info.attacker is PlayerController:
		pop()
		return Hurtbox.Result.HIT
	return Hurtbox.Result.IGNORED


func boomerang_hit(_b: Node3D) -> void:
	pop()


func pop() -> void:
	if is_queued_for_deletion():
		return
	Sfx.play("bubble_pop", -6.0, 0.1)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position, 5, 1.5, 1.0, 0.4, 0.6, Color(0.7, 0.9, 1.2))
	queue_free()
