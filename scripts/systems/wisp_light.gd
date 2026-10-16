extends Node3D
## A wisp of the Batela dead in the Forest of the Dead: a pale blue light that
## bobs at the mouth of the right way on, and chimes softly when the hero is
## near (OoT's Lost Woods tells the way by Saria's song; these woods by the
## light and the chime). It drifts a little toward the lane it marks.

@export var toward := Vector3.FORWARD
@export var chime := true

var _t := 0.0
var _next := 0.0
var _base := Vector3.ZERO
var _light: OmniLight3D
var _orb: MeshInstance3D


func _ready() -> void:
	_base = position
	_t = randf() * TAU
	_orb = MeshInstance3D.new()
	_orb.name = "Orb"
	var s := SphereMesh.new()
	s.radius = 0.16
	s.height = 0.32
	s.radial_segments = 8
	s.rings = 4
	_orb.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.7, 0.9, 1.0)
	m.disable_fog = true
	_orb.material_override = m
	_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_orb)
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var hs := SphereMesh.new()
	hs.radius = 0.36
	hs.height = 0.72
	hs.radial_segments = 8
	hs.rings = 4
	halo.mesh = hs
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.albedo_color = Color(0.5, 0.8, 1.0, 0.25)
	hm.disable_fog = true
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	_light = OmniLight3D.new()
	_light.name = "Light"
	_light.light_color = Color(0.6, 0.85, 1.0)
	_light.light_energy = 1.2
	_light.omni_range = 5.0
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	var drift := toward.normalized() * (sin(_t * 0.7) * 0.5 + 0.5) * 1.2
	position = _base + drift + Vector3(sin(_t * 1.3) * 0.25, sin(_t * 2.1) * 0.3, cos(_t * 1.1) * 0.25)
	_light.light_energy = 1.0 + sin(_t * 3.0) * 0.25
	if not chime:
		return
	_next -= delta
	var p := GameManager.player
	if _next <= 0.0 and is_instance_valid(p) and p.global_position.distance_to(global_position) < 12.0:
		_next = 3.5 + randf() * 1.5
		var near := 1.0 - p.global_position.distance_to(global_position) / 12.0
		Sfx.play("wisp_chime", lerpf(-22.0, -9.0, near), 0.08)
