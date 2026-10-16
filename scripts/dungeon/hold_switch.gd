class_name HoldSwitch
extends Area3D
## A heavy iron weight plate (Westmarch Fortress, Chapter IV): it sinks only
## while something heavy stands on it (the hero on his feet, or a Sapphire
## Staff block) and rises again when the weight is gone. Every plate sharing
## a `result` flag must be held down at once to set it, and then that stays.
## With `footing`, the hero must be standing (not swimming): under water,
## only the Anchor Boots hold it down.

@export var result := ""
@export var footing := false

var held := false
var _plate: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	monitorable = false
	add_to_group("hold_switches")
	var frame := MeshInstance3D.new()
	frame.mesh = load("res://assets/models/floor_switch_frame_mesh.tres")
	frame.scale = Vector3(1.4, 1.0, 1.4)
	add_child(frame)
	_plate = MeshInstance3D.new()
	_plate.name = "Plate"
	_plate.mesh = load("res://assets/models/floor_switch_mesh.tres")
	_plate.scale = Vector3(1.4, 1.0, 1.4)
	add_child(_plate)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.9, 1.4)
	cs.shape = box
	cs.position = Vector3(0, 0.45, 0)
	add_child(cs)
	if result != "" and Progress.flag(result):
		_plate.position.y = -0.12


func _weighed() -> bool:
	for b in get_overlapping_bodies():
		if b is SapphireBlock:
			return true
		if b is PlayerController:
			var p := b as PlayerController
			if p.is_dead():
				continue
			if footing and (p.is_swimming() or not p.is_on_floor()):
				continue
			return true
	return false


func _physics_process(_delta: float) -> void:
	if result != "" and Progress.flag(result):
		return
	var now := _weighed()
	if now == held:
		return
	held = now
	Sfx.play("switch_press", -4.0 if held else -10.0, 0.05, 1.0 if held else 1.3)
	var t := create_tween()
	t.tween_property(_plate, "position:y", -0.12 if held else 0.0, 0.15)
	if held and result != "":
		for s in get_tree().get_nodes_in_group("hold_switches"):
			var hs := s as HoldSwitch
			if hs and hs.result == result and not hs.held:
				return
		Progress.set_flag(result)
		Sfx.play("puzzle_solved", -3.0, 0.0)
