class_name Examine
extends Node3D
## Something to look at more closely (a portrait, a plaque, a notice): A says
## CHECK in front of it and its words come up, as OoT does for anything that
## is not a person. The front faces local -Z; it can only be read from in
## front (`front_only`).
##
## `lines_script` (optional) gives the pages instead: a static
## `lines(examine) -> Array` (Dialogue format), so they can change with the
## story; otherwise `pages` is shown as it is.

@export var pages: Array = []
@export var lines_script: Script
@export var front_only := true
@export var reach := 1.4
## An id the lines script can tell spots apart by.
@export var key := ""
## Only there once this flag is set ("" = always).
@export var show_flag := ""


func _ready() -> void:
	add_to_group("interactable")


func can_interact(by: Node3D) -> bool:
	if show_flag != "" and not Progress.flag(show_flag):
		return false
	if not front_only:
		return true
	var front := -global_basis.z
	var to := by.global_position - global_position
	return Vector2(front.x, front.z).dot(Vector2(to.x, to.z)) > 0.0


func interact_reach() -> float:
	return reach


func interact_label() -> String:
	return "CHECK"


func interact(player: Node) -> void:
	if Dialogue.active:
		return
	var shown: Array = lines_script.call("lines", self) if lines_script else pages.duplicate()
	if shown.is_empty():
		return
	if player is PlayerController:
		(player as PlayerController).begin_talk(self)
	# A page with an "event" goes to the lines script's on_event (as an Npc's does).
	var hook := func(page: Dictionary) -> void:
		if page.has("event") and lines_script and lines_script.has_method("on_event"):
			lines_script.call("on_event", self, String(page.event))
	Dialogue.page_started.connect(hook)
	Dialogue.start(shown, self)
	await Dialogue.finished
	if Dialogue.page_started.is_connected(hook):
		Dialogue.page_started.disconnect(hook)
	if player is PlayerController and is_instance_valid(player):
		(player as PlayerController).end_talk()
