class_name Explosion
extends Node3D
## A bomb's blast (EnBom_Explode and its EffectSsBomb2 flash). The sphere grows
## 8 OoT units a 20 Hz frame for 10 frames, to 80 units (2.4 m): every hurtbox
## it reaches takes the blow once (the hero's too: AT_TYPE_ALL), and every
## "bombables" node in reach (cracked walls, boulders, brittle coral, bloom
## pods) gets bomb_hit(). The area's light flares and fades, and the camera
## quakes (Camera_RequestQuake(2, 11, 8)).

const UNIT := 0.03
const GROW := 8.0
const FRAMES := 10.0
## Blast damage: enemies (stronger than a sword stroke) and the hero (one heart).
const DAMAGE := 3
const HERO_DAMAGE := 2

var source: Node3D = null
var _t := 0.0
var _hit := {}
var _ball: MeshInstance3D
var _light: OmniLight3D


static func at(parent: Node, pos: Vector3, by: Node3D = null) -> Explosion:
	var e := Explosion.new()
	e.name = "Explosion"
	e.source = by
	if parent == null:
		parent = World.area_node
	parent.add_child(e)
	e.global_position = pos
	return e


func radius() -> float:
	return minf(_t * 20.0, FRAMES) * GROW * UNIT


func _ready() -> void:
	Sfx.play("bomb_explode", 0.0, 0.06)
	var p := GameManager.player
	if is_instance_valid(p):
		var d := p.global_position.distance_to(global_position)
		GameManager.rumble(clampf(1.0 - d / 20.0, 0.2, 1.0), 0.35)
		if p.camera_rig and d < 25.0:
			p.camera_rig.shake(0.22 * clampf(1.0 - d / 25.0, 0.2, 1.0), 0.45)
	if Cutscene.active:
		Cutscene.shake(0.12, 0.4)
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	_ball.mesh = sphere
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.85, 0.45, 0.9)
	m.disable_fog = true
	_ball.material_override = m
	_ball.scale = Vector3.ONE * 0.1
	add_child(_ball)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.7, 0.35)
	_light.light_energy = 4.0
	_light.omni_range = 10.0
	add_child(_light)
	# Smoke and sparks.
	var parent := get_parent()
	Fragments.burst(parent, load("res://assets/models/rock_chip_mesh.tres"), global_position, 10, 5.0, 6.0, 0.8, 1.0, Color(0.25, 0.22, 0.2))
	Fragments.burst(parent, load("res://assets/models/shard_mesh.tres"), global_position, 14, 6.0, 7.0, 0.5, 0.6, Color(2.0, 1.4, 0.5))


func _physics_process(delta: float) -> void:
	_t += delta
	var r := radius()
	if _t < FRAMES / 20.0 + 0.05:
		_blast(r)
	var k := clampf(_t / 0.6, 0.0, 1.0)
	_ball.scale = Vector3.ONE * maxf(r, 0.1)
	(_ball.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.85 - k * 0.5, 0.45 - k * 0.35, (1.0 - k) * 0.9)
	_light.light_energy = 4.0 * (1.0 - k)
	if _t > 0.7:
		queue_free()


func _blast(r: float) -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = maxf(r, 0.2)
	q.shape = s
	q.transform = Transform3D(Basis(), global_position)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16 | 8
	for hit in space.intersect_shape(q, 32):
		var hb := hit.collider as Hurtbox
		if hb == null or not hb.monitorable or _hit.has(hb.receiver):
			continue
		_hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = HERO_DAMAGE if hb.receiver is PlayerController else DAMAGE
		info.knockback = 9.0
		info.heavy = true
		info.attacker = source
		info.source_position = global_position
		info.bomb = true
		info.unblockable = true
		hb.receive_hit(info)
	for n in get_tree().get_nodes_in_group("bombables"):
		var node := n as Node3D
		if node == null or _hit.has(node) or not node.is_inside_tree():
			continue
		var reach: float = node.call("bomb_reach") if node.has_method("bomb_reach") else 1.2
		if node.global_position.distance_to(global_position) < r + reach:
			_hit[node] = true
			node.call("bomb_hit", global_position)
	# Floor switches under it are pressed by the blast.
	for sw in get_tree().get_nodes_in_group("switches"):
		if sw.has_method("weigh_down"):
			sw.weigh_down(global_position - Vector3.UP * 0.25)
