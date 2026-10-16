class_name AreaExit
extends Area3D
## Loading zone: when the hero walks in, World fades out and loads `target_area`,
## placing him at its entrance `target_entrance`.

@export var target_area := ""
@export var target_entrance := ""
## Open only once `need_flag` is set, and no more after `hide_flag` (the
## Astral Rift's mouth over Black Water Ridge).
@export var need_flag := ""
@export var hide_flag := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # player
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if need_flag != "" and not Progress.flag(need_flag):
		return
	if hide_flag != "" and Progress.flag(hide_flag):
		return
	if body is PlayerController and not body.is_dead() and GameManager.state == GameManager.GameState.PLAYING:
		World.change_area(target_area, target_entrance)
