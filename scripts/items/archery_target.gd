class_name ArcheryTarget
extends StaticBody3D
## A straw archery target on a post. Arrows stick in it; a hit near the center
## rings a bell and the board rocks back. Counts its hits for curious players
## (and the tests).

signal hit(bullseye: bool)

## Radius of the painted face and of its gold center, in meters.
@export var face_radius := 0.6
@export var bullseye_radius := 0.14

var hits := 0
var bullseyes := 0
## Targets sharing a "prize_flag" meta make a set: put an arrow in every
## one's gold center (or, with the meta "prize_any", just hit every one) and
## the flag is set (a prize appears).
var prize_flag := ""
var _board: Node3D
var _rock := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_board = get_node_or_null("Board")
	add_to_group("archery_targets")
	prize_flag = get_meta("prize_flag", "")


## Called by an Arrow that sticks in this target.
func arrow_hit(arrow: Node3D, point: Vector3) -> void:
	hits += 1
	var centre := global_position + global_basis * Vector3(0, face_centre_height(), 0)
	var bull := point.distance_to(centre) <= bullseye_radius + 0.03
	if bull:
		bullseyes += 1
		Sfx.play("target_bell", -2.0)
	else:
		Sfx.play("target_hit", -4.0)
	_rock = 1.0
	# The arrow rocks with the board.
	if _board and is_instance_valid(arrow):
		arrow.reparent(_board)
	hit.emit(bull)
	_check_prize()


func _check_prize() -> void:
	if prize_flag == "" or Progress.flag(prize_flag):
		return
	var any: bool = get_meta("prize_any", false)
	for t in get_tree().get_nodes_in_group("archery_targets"):
		var at := t as ArcheryTarget
		if at.prize_flag != prize_flag:
			continue
		if (at.hits if any else at.bullseyes) <= 0:
			return
	Progress.set_flag(prize_flag)
	Sfx.play("puzzle_solved", -2.0, 0.0)


func face_centre_height() -> float:
	return get_meta("face_height", 1.35)


func _process(delta: float) -> void:
	if _board and _rock > 0.0:
		_rock = maxf(_rock - delta * 2.5, 0.0)
		_board.rotation.x = -sin((1.0 - _rock) * 18.0) * 0.12 * _rock
