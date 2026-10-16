class_name FlagAll
extends Node
## Sets `result` once every flag in `flags` is set (both braziers lit opens
## the Southern Tower's door).

@export var flags: PackedStringArray = []
@export var result := ""


func _ready() -> void:
	Progress.changed.connect(_check)
	_check()


func _check() -> void:
	if result == "" or Progress.flag(result):
		return
	for f in flags:
		if not Progress.flag(f):
			return
	Progress.set_flag(result)
	Sfx.play("puzzle_solved", -2.0, 0.0)
