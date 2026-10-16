class_name StarLock
extends StaticBody3D
## A star lock of the Astral Rift (Beta 1.5.0): a silver pedestal with a star
## of glass in its top. When the island it stands on has given up its
## guardian (`need_flag`, the room's clear flag) and the hero comes near, the
## star kindles (`flag`), and the camera turns to show what it woke far away
## (the Marker3D `pan_to`, with `pan_text`): the next astral gate, or the
## dream stair. A "display" lock (the hub's four) only shows `flag`.

@export var flag := ""
@export var need_flag := ""
@export var pan_to := ""
@export_multiline var pan_text := ""
@export var display := false
@export var star_col := Color(0.8, 0.85, 1.0)

const REACH := 6.0

var _star: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D
var _lit := false
var _busy := false
var _t := 0.0


func _ready() -> void:
	add_to_group("star_locks")
	_star = MeshInstance3D.new()
	_star.name = "Star"
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	sm.radial_segments = 8
	sm.rings = 4
	_star.mesh = sm
	_star.position = Vector3.UP * 1.35
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.disable_fog = true
	_star.material_override = _mat
	add_child(_star)
	_light = OmniLight3D.new()
	_light.position = Vector3.UP * 1.5
	_light.omni_range = 7.0
	_light.light_color = star_col
	add_child(_light)
	_lit = flag != "" and Progress.flag(flag)
	_look()
	Progress.changed.connect(_on_progress)


func _on_progress() -> void:
	if display and not _lit and Progress.flag(flag):
		_lit = true
		_look()


func _look() -> void:
	_mat.albedo_color = star_col if _lit else Color(0.16, 0.16, 0.22)
	_light.light_energy = 2.0 if _lit else 0.0
	_star.scale = Vector3.ONE * (1.0 if _lit else 0.7)


func is_lit() -> bool:
	return _lit


func _physics_process(delta: float) -> void:
	_t += delta
	_star.position.y = 1.35 + (sin(_t * 2.0) * 0.08 if _lit else 0.0)
	if _lit or display or _busy:
		return
	if need_flag != "" and not Progress.flag(need_flag):
		return
	var p := GameManager.player
	if not is_instance_valid(p) or p.is_dead() or Cutscene.active or World.transitioning:
		return
	if p.global_position.distance_to(global_position) > REACH or absf(p.global_position.y - global_position.y) > 2.5:
		return
	kindle()


## The star lights: its flag set, and the camera shows what woke.
func kindle() -> void:
	if _lit or _busy:
		return
	_busy = true
	_lit = true
	_look()
	Sfx.play("puzzle_solved", -2.0)
	Sfx.play("goddess_chime", -4.0, 0.0, 1.1)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.4, 16, 3.0, 3.0, 0.8, 0.9, Color(star_col.r * 1.6, star_col.g * 1.6, star_col.b * 1.6))
	if flag != "":
		Progress.set_flag(flag)
	if pan_to != "":
		await Story.unlock_pan(pan_to, pan_text)
	_busy = false
