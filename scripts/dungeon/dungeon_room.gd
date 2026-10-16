class_name DungeonRoom
extends Area3D
## One room of a dungeon (OoT loads dungeons room by room).
## - Walking in sets the hero's respawn point: falling into a pit returns him
##   to where he entered the room (RESPAWN_MODE_DOWN), as in OoT.
## - If creatures of this room (meta "room" = room_id) are alive when he comes
##   in, the room's shutters (group "shutters", same room_id) slam shut until
##   they are all beaten (OoT's Door_Shutter "clear the room" doors); then the
##   shutters open, the secret jingle plays and the room's clear flag is set
##   (chests waiting on it appear). A cleared room stays cleared.

@export var room_id := ""
@export var dungeon := "lake_shrine"

var cleared := false
var _active := false
## Whether creatures of this room were alive when it loaded: once they are all
## beaten the room clears, even if the last fell outside it.
var _had_enemies := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("rooms")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	cleared = Progress.flag(clear_flag())
	if cleared:
		_remove_enemies.call_deferred()
	else:
		_count_enemies.call_deferred()


func _count_enemies() -> void:
	_had_enemies = not room_enemies().is_empty()


## Whether `p` is in the room (with `margin` meters to spare sideways, so the
## doorways count; never as high as the storey above, 8 m up).
func contains(p: Vector3, margin := 2.0) -> bool:
	var cs := get_node_or_null("Shape") as CollisionShape3D
	if cs == null or not (cs.shape is BoxShape3D):
		return true
	var local := global_transform.affine_inverse() * p
	var half := (cs.shape as BoxShape3D).size * 0.5
	return absf(local.x) <= half.x + margin and absf(local.z) <= half.z + margin 		and local.y >= -half.y - 1.0 and local.y <= half.y + 0.8


func clear_flag() -> String:
	return "%s:%s_clear" % [dungeon, room_id]


func room_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e: Node) -> bool: return e.get_meta("room", "") == room_id)


func _shutters() -> Array:
	return get_tree().get_nodes_in_group("shutters").filter(func(s: Node) -> bool: return s.room_id == room_id)


func _remove_enemies() -> void:
	for e: Node in room_enemies():
		e.queue_free()


func _on_enter(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	(body as PlayerController).set_respawn(body.global_transform)
	if cleared or room_enemies().is_empty():
		return
	_active = true
	for s: Node in _shutters():
		s.close()


func _on_exit(body: Node3D) -> void:
	# Leaving with the room unbeaten (only possible without shutters).
	if body is PlayerController and _shutters().is_empty():
		_active = false


func _physics_process(_delta: float) -> void:
	if (_active or _had_enemies) and not cleared and room_enemies().is_empty():
		_clear()


func _clear() -> void:
	cleared = true
	_active = false
	Progress.set_flag(clear_flag())
	for s: Node in _shutters():
		s.open()
	Sfx.play("puzzle_solved", -3.0, 0.0)
