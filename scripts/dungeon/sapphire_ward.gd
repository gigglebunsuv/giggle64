class_name SapphireWard
extends StaticBody3D
## A sapphire ward (the Sapphire Sanctum): a curtain of the Order's cold blue
## fire across a doorway, the Gauntlet's flame bent to the Order's will. It is
## solid, and it burns whoever touches it. Lothelye's starlight is the one
## light the Gauntlet does not rule: bring the lit Starlight Lantern close
## and the ward gutters out (setting `flag`) and stays out.

## Width of the curtain (it spans its local X), and its height.
@export var width := 3.0
@export var height := 3.0
@export var flag := ""
## How close the lit Starlight Lantern must come.
const REACH := 3.5
const BURN := 2

var _flames: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _t := 0.0
var _fade := -1.0
var _burned := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("sapphire_wards")
	if flag != "" and Progress.flag(flag):
		queue_free()
		return
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, 0.6)
	cs.shape = box
	cs.position = Vector3(0, height * 0.5, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)
	var n := maxi(3, int(width / 0.45))
	for i in n:
		var mi := MeshInstance3D.new()
		mi.name = "Flame%d" % i
		mi.mesh = load("res://assets/models/sapphire_flame_mesh.tres")
		mi.position = Vector3(-width * 0.5 + (i + 0.5) * width / n, 0.0, 0.0)
		mi.scale = Vector3(2.2, height / 0.6 * 0.9, 2.2)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_flames.append(mi)
	_light = OmniLight3D.new()
	_light.name = "Light"
	_light.position = Vector3(0, height * 0.5, 0)
	_light.light_color = Color(0.45, 0.4, 1.0)
	_light.light_energy = 1.4
	_light.omni_range = maxf(width, 5.0)
	add_child(_light)


func _physics_process(delta: float) -> void:
	_t += delta
	if _fade >= 0.0:
		_fade += delta
		var k := clampf(1.0 - _fade / 0.8, 0.0, 1.0)
		for f in _flames:
			f.scale.y = height / 0.6 * 0.9 * k
		_light.light_energy = 1.4 * k
		if _fade >= 0.8:
			queue_free()
		return
	for i in _flames.size():
		_flames[i].scale.y = height / 0.6 * (0.85 + sin(_t * 6.0 + i * 1.7) * 0.08)
	var p := GameManager.player
	if not is_instance_valid(p) or p.is_dead():
		return
	var local := to_local(p.global_position)
	if PlayerItems.lantern_lit and PlayerItems.starlight() and absf(local.x) < width * 0.5 + REACH and absf(local.z) < REACH and absf(local.y) < 3.0:
		gutter_out()
		return
	# Touching it burns.
	_burned = maxf(_burned - delta, 0.0)
	if _burned <= 0.0 and absf(local.x) < width * 0.5 + 0.2 and absf(local.z) < 0.75 and local.y > -0.5 and local.y < height:
		_burned = 1.0
		# The Questlord's Shield turns the Order's fire.
		if p.is_shielding() and Equipment.guard().get("fireproof", false):
			Sfx.play("shield_block", -6.0, 0.08, 1.2)
			return
		var info := HitInfo.new()
		info.damage = BURN
		info.knockback = 6.0
		info.attacker = self
		info.source_position = global_position + global_transform.basis.z * (-1.0 if local.z > 0.0 else 1.0)
		p.take_hit(info)


## Lothelye's starlight reached it.
func gutter_out() -> void:
	if _fade >= 0.0:
		return
	_fade = 0.0
	Sfx.play("ward_out", -2.0, 0.05)
	if flag != "":
		Progress.set_flag(flag)
	for c in find_children("*", "CollisionShape3D", false, false):
		(c as CollisionShape3D).set_deferred("disabled", true)
