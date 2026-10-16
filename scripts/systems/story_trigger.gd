class_name StoryTrigger
extends Area3D
## A place where the story moves on: when the hero walks in (and `flag` is
## not set yet, and `need_flag` is, if given) the Story scene named `scene`
## plays (Story.<scene>()), once.

@export var scene := ""
@export var flag := ""
@export var need_flag := ""

var _busy := false
var _poll := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(_on_body)


## The hero may already stand inside when the scene can start: arriving in
## an area (the trigger by the way in sees him while the screen still fades
## in) or once a needed flag is set. Look again now and then.
func _physics_process(delta: float) -> void:
	if _busy:
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.25
	for b in get_overlapping_bodies():
		_on_body(b)


func _on_body(body: Node3D) -> void:
	if _busy or not (body is PlayerController) or (body as PlayerController).is_dead():
		return
	if flag != "" and Progress.flag(flag):
		return
	if need_flag != "" and not Progress.flag(need_flag):
		return
	if Cutscene.active or World.transitioning or not Story.has_method(scene):
		return
	_busy = true
	await Story.call(scene)
	_busy = false
