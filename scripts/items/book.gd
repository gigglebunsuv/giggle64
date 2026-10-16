class_name Book
extends Node3D
## A book lying open on a table or lectern (the Haven Library). A reads it:
## the A button says READ and the pages show in the wooden text box one after
## another, like a sign with more to say.

## The pages, one text box each; *stars* color words.
@export var pages: PackedStringArray = []
@export var title := ""


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("books")


func interact_label() -> String:
	return "READ"


func interact(player: Node) -> void:
	if Dialogue.active:
		return
	var script: Array = []
	if title != "":
		script.append({"text": "*%s*" % title, "instant": true})
	for p in pages:
		script.append({"text": p, "instant": true})
	if player is PlayerController:
		(player as PlayerController).begin_talk(self)
	Dialogue.start(script, self, "wooden")
	await Dialogue.finished
	if player is PlayerController and is_instance_valid(player):
		(player as PlayerController).end_talk()
