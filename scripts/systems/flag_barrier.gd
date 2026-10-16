class_name FlagBarrier
extends StaticBody3D
## A barrier the story removes: solid and seen until `gone_flag` is set, then
## gone (the sandstorm choking the desert's old east road until the Order's
## map shows the way through, the crypt gate in the Batela Fells until Elder
## Maud opens it).

@export var gone_flag := ""
## Only there once this flag is set ("" = from the start): the knights' camp
## at the marsh's west end (Beta 1.4.0).
@export var need_flag := ""


func _ready() -> void:
	_refresh()
	Progress.changed.connect(_refresh)


func _refresh() -> void:
	var gone := (gone_flag != "" and Progress.flag(gone_flag)) or (need_flag != "" and not Progress.flag(need_flag))
	visible = not gone
	for c in find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", gone)
	for c in find_children("*", "CPUParticles3D", true, false):
		(c as CPUParticles3D).emitting = not gone
