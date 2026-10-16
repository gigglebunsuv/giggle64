class_name FlagMover
extends AnimatableBody3D
## Something solid that moves once a Progress flag is set and stays moved:
## iron bars that lift out of a doorway, or a stone bridge that rises out of a
## pit (OoT's switch-linked Bg_ actors). Its meshes and collision shapes are its
## children; it starts displaced by `offset` and moves back to where it was
## placed when `flag` is set (so a bridge waits below, bars wait in the door
## and `offset` is negative), or the other way round with `reverse`.

@export var flag := ""
## Displacement while the flag is not set.
@export var offset := Vector3(0, -6, 0)
@export var time := 1.5
@export var sound := "shutter_open"

var done := false
var _home := Vector3.ZERO


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	add_to_group("flag_movers")
	_home = position
	if flag != "" and Progress.flag(flag):
		done = true
	else:
		position = _home + offset
		Progress.changed.connect(_check)


func _check() -> void:
	if done or not Progress.flag(flag):
		return
	done = true
	Progress.changed.disconnect(_check)
	Sfx.play(sound, -3.0)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "position", _home, time).set_trans(Tween.TRANS_SINE)
