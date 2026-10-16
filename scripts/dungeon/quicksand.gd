class_name Quicksand
extends Area3D
## Sinking sand (OoT's quicksand floors in the Haunted Wasteland and the
## Spirit Temple): while the hero stands in it he wades at half speed and
## sinks, slowly while he keeps moving and fast when he stands still. Sunk to
## his chest, the sand swallows him and he comes back at the room's entrance,
## hurt. Out of the sand he shakes it off.

## Meters a second he sinks standing still, and while moving.
const SINK_STILL := 0.5
const SINK_MOVING := 0.1
const SWALLOW := 1.1

@export var damage := 2

var _hero_in := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("quicksand")
	body_entered.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_hero_in = true)
	body_exited.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_hero_in = false)


func _physics_process(delta: float) -> void:
	var p := GameManager.player
	if not _hero_in or not is_instance_valid(p) or p.is_dead() or not p.is_on_floor():
		return
	p.in_sand = 0.1
	var moving := p.speed_oot > 1.0
	var before := p.sink
	p.sink = minf(p.sink + (SINK_MOVING if moving else SINK_STILL) * delta, SWALLOW)
	if floorf(before * 4.0) != floorf(p.sink * 4.0):
		Sfx.play("step_sand_0", -4.0, 0.2, 0.6)
	if p.sink >= SWALLOW:
		p.sink = 0.0
		p.in_sand = 0.0
		Sfx.play("splash_big", -6.0, 0.1, 0.5)
		p.void_out(damage)
