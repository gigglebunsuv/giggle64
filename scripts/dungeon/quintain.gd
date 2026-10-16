class_name Quintain
extends StaticBody3D
## A quintain on the marsh-front camp's training ground (Beta 1.4.0): a post
## with a swinging arm and a sandbag. While the hero stands in front of it,
## it draws the arm back (a creak and a shake: the tell) and swings. Shield
## up and bash just as it comes (the PARRY): PARRIES_NEEDED parries in a row
## set `flag`. A plain guard just stops it; a miss knocks him down.

const PERIOD := 2.6
const WINDUP := 0.7
const SWING := 0.25
const REACH := 2.6
const PARRIES_NEEDED := 3

@export var flag := ""
## Only there once this flag is set (the knights' camp: "ch5:cinder_done").
@export var need_flag := ""

var parries := 0
var _t := 0.0
var _arm: Node3D
var _phase := 0
var _parried_now := false


func _ready() -> void:
	if need_flag != "" and not Progress.flag(need_flag):
		set_physics_process(false)
		queue_free()
		return
	collision_layer = 1
	collision_mask = 0
	add_to_group("quintains")
	var post := MeshInstance3D.new()
	post.name = "Post"
	if ResourceLoader.exists("res://assets/models/training_pell_mesh.tres"):
		post.mesh = load("res://assets/models/training_pell_mesh.tres")
	add_child(post)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 1.9, 0.5)
	cs.shape = box
	cs.position = Vector3(0, 0.95, 0)
	add_child(cs)
	_arm = Node3D.new()
	_arm.name = "Arm"
	_arm.position = Vector3(0, 1.55, 0)
	add_child(_arm)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.26)
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 2.2)
	bm.material = mat
	beam.mesh = bm
	beam.position = Vector3(0, 0, -0.9)
	_arm.add_child(beam)
	var bag := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.78, 0.7, 0.5)
	sm.material = bag_mat
	bag.mesh = sm
	bag.position = Vector3(0, -0.15, -1.95)
	_arm.add_child(bag)
	# The other end: a little shield for the hero to aim at.
	var shield := MeshInstance3D.new()
	var shm := CylinderMesh.new()
	shm.top_radius = 0.28
	shm.bottom_radius = 0.28
	shm.height = 0.06
	var sh_mat := StandardMaterial3D.new()
	sh_mat.albedo_color = Color(0.25, 0.4, 0.72)
	shm.material = sh_mat
	shield.mesh = shm
	shield.rotation.x = PI * 0.5
	shield.position = Vector3(0, 0, 0.22)
	_arm.add_child(shield)


func done() -> bool:
	return flag != "" and Progress.flag(flag)


func _physics_process(delta: float) -> void:
	var p := GameManager.player
	var near := is_instance_valid(p) and not p.is_dead() and _in_front(p)
	match _phase:
		0:
			_arm.rotation.y = lerp_angle(_arm.rotation.y, 0.0, 1.0 - exp(-6.0 * delta))
			_t += delta if near else 0.0
			if _t >= PERIOD:
				_go(1)
		1:
			# The tell: the arm drawn back, creaking and shaking.
			_arm.rotation.y = lerpf(0.0, 0.9, clampf(_t / WINDUP, 0.0, 1.0)) + sin(_t * 60.0) * 0.03
			_t += delta
			if _t >= WINDUP:
				_go(2)
		2:
			_arm.rotation.y = lerpf(0.9, -1.4, clampf(_t / SWING, 0.0, 1.0))
			_t += delta
			if _t >= SWING * 0.55 and _t - delta < SWING * 0.55:
				_strike(p)
			if _t >= SWING + 0.4:
				_go(0)


func _go(phase: int) -> void:
	_phase = phase
	_t = 0.0
	match phase:
		1:
			Sfx.play("bone_rattle", -6.0, 0.05, 1.4)
		2:
			Sfx.play("heavy_swing", -4.0, 0.05, 1.1)


## The hero stands in the arm's sweep, before the post.
func _in_front(p: Node3D) -> bool:
	var to := p.global_position - global_position
	var flat := Vector2(to.x, to.z)
	if flat.length() > REACH + 0.6 or absf(to.y) > 1.6:
		return false
	var fwd := -global_transform.basis.z
	return Vector2(fwd.x, fwd.z).dot(flat.normalized()) > 0.3


func _strike(p: PlayerController) -> void:
	if not is_instance_valid(p) or not _in_front(p):
		return
	_parried_now = false
	var info := HitInfo.new()
	info.damage = 1
	info.knockback = 5.0
	info.attacker = self
	# From the post itself: a hero who has bashed right up to it still has it in front.
	info.source_position = global_position
	p.take_hit(info)
	if _parried_now:
		parries += 1
		if parries >= PARRIES_NEEDED and not done():
			if flag != "":
				Progress.set_flag(flag)
			Sfx.play("puzzle_solved", -2.0)
	else:
		parries = 0


## The hero's Parry turned the arm: it bounces back.
func parried(_by: Node3D) -> void:
	_parried_now = true
	_go(0)
	_arm.rotation.y = 1.1
