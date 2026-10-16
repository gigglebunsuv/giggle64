extends Node3D
## Scenery that is only there while the story says so: shown once `flag` is set
## (and hidden again once `hide_flag` is). The refugees' bedrolls in Himeko's
## palace after the fall, for one.

@export var flag := ""
@export var hide_flag := ""


func _ready() -> void:
	_refresh()
	Progress.changed.connect(_refresh)


func _refresh() -> void:
	visible = (flag == "" or Progress.flag(flag)) and (hide_flag == "" or not Progress.flag(hide_flag))
