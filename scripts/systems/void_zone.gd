class_name VoidZone
extends Area3D
## Deep water the hero cannot cross yet (there is no swimming): stepping in
## returns him to where he entered the area, like an OoT void-out.

@export var damage := 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # player
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and not body.is_dead():
		body.void_out(damage)
