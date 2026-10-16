class_name MusicZone
extends Area3D
## A patch of a region with its own music (Ashwick's camp in the Batela
## Fells): while the hero stands in it, `track` plays instead of the area's,
## day or night, and the area's track comes back when he leaves.

@export var track := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # player
	monitorable = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body is PlayerController:
		World.set_zone_track(track)


func _on_exit(body: Node3D) -> void:
	if body is PlayerController and World.zone_track == track:
		World.set_zone_track("")
