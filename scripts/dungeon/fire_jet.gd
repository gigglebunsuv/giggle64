class_name FireJet
extends Node3D
## A jet of the Gauntlet's fire (the burning Citadel, Chapter IV): a vent in
## the wall that breathes a long tongue of flame along -Z every `period`
## seconds for `burn` seconds (or always, `period` 0). It burns whoever it
## touches. A Sapphire Staff block set in its path stops the flame there
## (the Order's sapphire takes no fire), and the space beyond is safe.

@export var length := 8.0
@export var period := 3.0
@export var burn := 1.6
@export var phase := 0.0

const DAMAGE := 2
const RADIUS := 0.7

var _t := 0.0
var _flames: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _reach := 0.0
var _hurt_cool := 0.0


func _ready() -> void:
	add_to_group("fire_jets")
	_t = phase
	var vent := MeshInstance3D.new()
	var vm := CylinderMesh.new()
	vm.top_radius = 0.35
	vm.bottom_radius = 0.45
	vm.height = 0.4
	vent.mesh = vm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.18)
	vent.material_override = mat
	vent.rotation.x = PI / 2.0
	add_child(vent)
	var n := maxi(3, int(length / 0.9))
	for i in n:
		var f := MeshInstance3D.new()
		f.mesh = load("res://assets/models/flame_mesh.tres")
		f.scale = Vector3.ONE * 1.8
		f.position = Vector3(0, -0.3, -0.6 - i * (length / n))
		add_child(f)
		_flames.append(f)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.omni_range = 6.0
	_light.position = Vector3(0, 0, -length * 0.5)
	add_child(_light)


func active() -> bool:
	return period <= 0.0 or fmod(_t, period) < burn


func _physics_process(delta: float) -> void:
	_t += delta
	_hurt_cool = maxf(_hurt_cool - delta, 0.0)
	var on := active()
	_reach = length
	if on:
		# A block in the way stops the flame at its face.
		var from := global_position
		var to := global_transform * Vector3(0, 0, -length)
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and hit.collider is SapphireBlock:
			_reach = from.distance_to(hit.position)
	for i in _flames.size():
		var f := _flames[i]
		f.visible = on and -f.position.z < _reach
		if f.visible:
			f.scale = Vector3.ONE * (1.6 + sin(_t * 18.0 + i) * 0.25)
	_light.light_energy = 2.0 if on else 0.3
	if not on or _hurt_cool > 0.0:
		return
	var p := GameManager.player
	if p == null or p.is_dead():
		return
	var local := to_local(p.global_position + Vector3.UP * 0.9)
	if local.z < 0.0 and -local.z < _reach and Vector2(local.x, local.y).length() < RADIUS + 0.4:
		_hurt_cool = 1.0
		var info := HitInfo.new()
		info.damage = DAMAGE
		info.knockback = 7.0
		info.unblockable = not Equipment.guard().get("fireproof", false)
		info.attacker = self
		info.source_position = global_position
		p.take_hit(info)
