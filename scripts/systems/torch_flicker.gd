extends Node3D
## Steps the flame's scale and light energy at a low rate for a choppy, retro flicker.
##
## Its light only shines near the hero (Beta's performance pass): beyond
## LIGHT_RANGE, or more than a storey above or below him (the towers and the
## castle stack many lit rooms), the light is switched off, and it fades in
## and out at the edge (Light3D distance fade). The flame itself still shows.

## How far from the hero a flame's light still shines, and the storey gap.
const LIGHT_RANGE := 34.0
const STOREY_GAP := 7.0

@export var step_time := 0.09

var _timer := 0.0
var _base_energy := 1.0
var _rng := RandomNumberGenerator.new()
@onready var _light: OmniLight3D = get_node_or_null("Light")


func _ready() -> void:
	_rng.randomize()
	if _light:
		_base_energy = _light.light_energy
		_light.distance_fade_enabled = true
		_light.distance_fade_begin = LIGHT_RANGE - 8.0
		_light.distance_fade_length = 8.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = step_time
	scale = Vector3(_rng.randf_range(0.9, 1.1), _rng.randf_range(0.8, 1.15), _rng.randf_range(0.9, 1.1))
	rotation.y = _rng.randf_range(0.0, TAU)
	if _light:
		_light.light_energy = _base_energy * _rng.randf_range(0.8, 1.1)
		_light.visible = _near_hero()


## Within reach of the hero (or there is no hero: the title's views).
func _near_hero() -> bool:
	var p := GameManager.player
	if not is_instance_valid(p) or not p.is_inside_tree() or GameManager.state == GameManager.GameState.TITLE or Cutscene.active:
		return true
	var d := global_position - p.global_position
	return absf(d.y) < STOREY_GAP and Vector2(d.x, d.z).length() < LIGHT_RANGE
