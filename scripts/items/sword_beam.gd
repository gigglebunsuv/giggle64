class_name SwordBeam
extends Node3D
## A crescent of golden magic loosed by the Bun Sword when the hero swings it
## with full health (the classic Zelda sword beam). It flies straight ahead,
## hurts the first foe it meets and bursts on walls.

const SPEED := 15.0
const LIFE := 0.6
const DAMAGE := 2

var velocity := Vector3.ZERO
var _life := LIFE
var _mesh: MeshInstance3D
## The awakened Bun Sword's beam (Chapter IV): blue-white starlight that
## hits a little harder and puts out the Order's wards and lights star
## braziers it passes.
var starlight := false


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/sword_beam_mesh.tres")
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Stood up as an arch facing the way it flies (seen whole from behind),
	# tilted like the slash that loosed it.
	_mesh.rotation = Vector3(PI * 0.5, 0.0, 0.45)
	add_child(_mesh)
	if starlight:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.75, 0.85, 1.25)
		m.disable_fog = true
		_mesh.material_override = m


## Sends the beam from `from` along the flat direction `dir`.
func launch(from: Vector3, dir: Vector3) -> void:
	global_position = from
	velocity = Vector3(dir.x, 0, dir.z).normalized() * SPEED
	rotation.y = atan2(-velocity.x, -velocity.z)


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_burst()
		return
	_mesh.scale = Vector3.ONE * (1.3 + 0.15 * sin(_life * 40.0))
	var from := global_position
	var to := from + velocity * delta
	if starlight:
		_starlight_touch()
	# The world (1) and enemy hurtboxes (16).
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	q.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		global_position = to
		return
	var hb := hit.collider as Hurtbox
	if hb:
		var info := HitInfo.new()
		info.damage = DAMAGE + (1 if starlight else 0)
		info.knockback = 2.5
		info.attacker = GameManager.player
		info.source_position = from - velocity.normalized()
		if hb.receive_hit(info) == Hurtbox.Result.IGNORED:
			global_position = to
			return
		Sfx.play("sword_hit", -4.0)
	_burst()


## Starlight puts out a ward and lights a star brazier it passes close to.
func _starlight_touch() -> void:
	for w in get_tree().get_nodes_in_group("sapphire_wards"):
		var ward := w as SapphireWard
		if ward and ward.global_position.distance_to(global_position) < ward.width * 0.5 + 1.0:
			ward.gutter_out()
	for t in get_tree().get_nodes_in_group("torches"):
		var torch := t as Torch
		if torch and torch.star and not torch.lit and torch.global_position.distance_to(global_position) < 1.6:
			torch.light_up()


func _burst() -> void:
	Sfx.play("magic_burst", -8.0, 0.1)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 6, 2.0, 1.0, 0.3, 0.5, Color(0.9, 1.0, 1.5) if starlight else Color(1.6, 1.3, 0.5))
	queue_free()
