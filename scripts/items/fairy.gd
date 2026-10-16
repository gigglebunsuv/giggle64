class_name Fairy
extends Node3D
## A healing fairy, after OoT's EnElf (the fairies of fountains and grass):
## a soft pink light with wings that bobs and wanders round where she
## appeared, with a faint tinkling.
## - Walking into her: she circles the hero and heals EIGHT hearts, then flies
##   off (OoT's fairy heals 8 hearts).
## - Swinging an empty bottle at her (PlayerController's bottle) catches her.
## - Let out of a bottle (`released`), she heals at once and flies away.

const HEAL := 16
const TOUCH_RANGE := 0.75
const WANDER_R := 1.6

## Let out of a bottle: heals the hero straight away, then leaves.
@export var released := false

var _home := Vector3.ZERO
var _t := 0.0
var _phase := 0.0
var _leaving := false
var _body: MeshInstance3D
var _wings: Array[MeshInstance3D] = []
var _sound: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("fairies")
	_home = position
	_phase = randf() * TAU
	_body = MeshInstance3D.new()
	_body.name = "Glow"
	var path := "res://assets/models/fairy_mesh.tres"
	if ResourceLoader.exists(path):
		_body.mesh = load(path)
	else:
		var s := SphereMesh.new()
		s.radius = 0.1
		s.height = 0.2
		_body.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.75, 0.9)
		_body.material_override = m
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)
	for side in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.22, 0.16)
		w.mesh = q
		var wm := StandardMaterial3D.new()
		wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		wm.albedo_color = Color(0.9, 0.85, 1.0, 0.55)
		w.material_override = wm
		w.position = Vector3(0.11 * side, 0.03, 0)
		w.set_meta("side", side)
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(w)
		_wings.append(w)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.9)
	light.light_energy = 0.8
	light.omni_range = 3.0
	add_child(light)
	_sound = AudioStreamPlayer3D.new()
	_sound.bus = "SFX"
	_sound.unit_size = 2.0
	_sound.max_distance = 14.0
	var loop_path := "res://assets/audio/fairy_loop.wav"
	if ResourceLoader.exists(loop_path):
		var st: AudioStreamWAV = load(loop_path)
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		_sound.stream = st
		_sound.volume_db = -6.0
		add_child(_sound)
		_sound.play()
	if released:
		_heal_hero()


func _process(delta: float) -> void:
	_t += delta
	for w in _wings:
		var side: float = w.get_meta("side")
		w.rotation.y = side * (0.4 + 0.5 * sin(_t * 38.0))
	if _leaving:
		position += Vector3(0.6, 2.2, 0.3) * delta
		scale = scale.move_toward(Vector3.ZERO, delta * 0.6)
		if scale.x <= 0.01:
			queue_free()
		return
	# Wandering in loose loops round home, bobbing as she goes.
	var a := _t * 0.9 + _phase
	var target := _home + Vector3(cos(a) * WANDER_R * 0.8, 0.25 * sin(_t * 3.1 + _phase), sin(a * 1.3) * WANDER_R * 0.6)
	position = position.lerp(target, 1.0 - exp(-delta * 2.5))
	var p := GameManager.player
	if is_instance_valid(p) and not p.is_dead() and not p.in_cutscene:
		if global_position.distance_to(p.global_position + Vector3.UP * 0.9) < TOUCH_RANGE + 0.5:
			_heal_hero()


## Caught in a bottle: she vanishes here (she lives in the bottle now).
func catch() -> void:
	if _leaving:
		return
	queue_free()


func _heal_hero() -> void:
	if _leaving:
		return
	_leaving = true
	var p := GameManager.player
	if is_instance_valid(p) and not p.is_dead():
		p.health.heal(HEAL)
	Sfx.play("fairy_heal", -2.0, 0.0)
