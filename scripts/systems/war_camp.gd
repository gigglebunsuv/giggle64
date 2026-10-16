class_name WarCamp
extends Node3D
## A goblin war camp on the burning field (Chapter IV): tents, a fire, a war
## banner, a caged soldier. The creatures standing within `radius` when the
## area loads belong to it; once they are all beaten, `flag` is set (the
## cage's door falls open and the camp's chest appears) and the banner burns.
## The last of the three camps broken, the east beacon goes out
## (Story.eastgate_falls).
## Beta 1.4.0: Mara's three undead camps on Black Water Ridge (`ridge`): each
## has a bone fire burning green that goes out when the camp is broken, and
## the last one snaps the chains on the Keep's gate (Story.camps_broken).

const CAMP_FLAGS := ["ch4:camp_1", "ch4:camp_2", "ch4:camp_3"]
const RIDGE_FLAGS := ["ridge:camp_1", "ridge:camp_2", "ridge:camp_3"]

@export var flag := ""
@export var radius := 12.0
## One of Mara's camps on Black Water Ridge.
@export var ridge := false

var _foes: Array[Node] = []
var _armed := false


func _ready() -> void:
	add_to_group("war_camps")
	_gather.call_deferred()


func _gather() -> void:
	if not is_inside_tree():
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n and Vector2(n.global_position.x - global_position.x, n.global_position.z - global_position.z).length() < radius:
			_foes.append(n)
	if Progress.flag(flag):
		# Broken already: the camp lies empty.
		for f in _foes:
			f.queue_free()
		_foes.clear()
		return
	_armed = not _foes.is_empty()


func foes_left() -> int:
	_foes = _foes.filter(func(f: Node) -> bool: return is_instance_valid(f) and f.is_in_group("enemies"))
	return _foes.size()


func _physics_process(_delta: float) -> void:
	if not _armed or Progress.flag(flag):
		return
	if foes_left() == 0:
		_armed = false
		broken()


func broken() -> void:
	Progress.set_flag(flag)
	Sfx.play("puzzle_solved", -3.0, 0.0)
	if ridge:
		Story._burst(global_position + Vector3.UP * 1.2, Color(0.55, 1.0, 0.6), 2.6)
		Sfx.play("goddess_chime", -6.0, 0.0, 0.8)
		var all_ridge := true
		for f: String in RIDGE_FLAGS:
			if not Progress.flag(f):
				all_ridge = false
		if all_ridge and not Progress.flag("ch5:camps_done"):
			Story.camps_broken.call_deferred()
		return
	Story._flames(global_position + Vector3(1.4, 0, 0), 1.2, true)
	Sfx.play("fire_whoosh", -4.0, 0.0, 0.8)
	var all := true
	for f: String in CAMP_FLAGS:
		if not Progress.flag(f):
			all = false
	if all and not Progress.flag("ch4:camps"):
		Progress.set_flag("ch4:camps")
		Story.eastgate_falls.call_deferred()
