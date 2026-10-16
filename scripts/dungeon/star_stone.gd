class_name StarStone
extends Node3D
## A star-stone of the Dark Forest (Chapter IV): a low mossy waymark that Lothelye's
## priests set at the mouth of each true lane. In common light it is only a
## stone; hold the lit Starlight Lantern near it (REACH) and the star cut in
## its face blazes, a beam of pale light points down the lane it marks, and
## it chimes. It goes dim again when the light goes.

const REACH := 9.0

var lit := false
var _glow: MeshInstance3D
var _beam: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("star_stones")
	var stone := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.1, 0.5)
	stone.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.32, 0.36, 0.3)
	stone.material_override = sm
	stone.position = Vector3(0, 0.55, 0)
	add_child(stone)
	_glow = MeshInstance3D.new()
	var star := PrismMesh.new()
	star.size = Vector3(0.45, 0.45, 0.04)
	_glow.mesh = star
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(0.9, 0.95, 1.3)
	gm.disable_fog = true
	_glow.material_override = gm
	_glow.position = Vector3(0, 0.7, -0.27)
	add_child(_glow)
	_beam = MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.18, 0.02, 7.0)
	_beam.mesh = bb
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.albedo_color = Color(0.8, 0.85, 1.0, 0.45)
	beam_mat.disable_fog = true
	_beam.material_override = beam_mat
	_beam.position = Vector3(0, 0.08, -4.0)
	add_child(_beam)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.75, 0.82, 1.0)
	_light.omni_range = 6.0
	_light.position = Vector3(0, 1.2, -0.6)
	add_child(_light)
	_set_lit(false)


func _set_lit(on: bool) -> void:
	lit = on
	_glow.visible = on
	_beam.visible = on
	_light.light_energy = 1.4 if on else 0.0


func _physics_process(_delta: float) -> void:
	var p := GameManager.player
	var shown := is_instance_valid(p) and PlayerItems.lantern_lit and PlayerItems.starlight() \
		and p.global_position.distance_to(global_position) < REACH
	if shown != lit:
		_set_lit(shown)
		if shown:
			Sfx.play("wisp_chime", -4.0, 0.05, 1.3)
