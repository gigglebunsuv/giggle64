extends RefCounted
## What the soldiers of the lost garrison say (Garrison). Found trapped, they
## thank the hero and set off for Haven (flag "rescue:<id>", on the last page
## so they stay to finish talking); safe in the refuge, they say their piece.

static func lines(npc: Node) -> Array:
	var id := Garrison.id_of(String(npc.npc_name))
	if id == "":
		return ["..."]
	if Garrison.is_rescued(id):
		return [{"text": String(Garrison.SOLDIERS[id][2]), "anim": "talk"}]
	var where := String(Garrison.SOLDIERS[id][1])
	var first: String
	match where:
		"camp_1", "camp_2", "camp_3":
			first = "You broke the camp! I thought I'd die in that cage. Haven's own knight... thank you."
		"westmarch":
			first = "The bars are open? You came for us! I thought the whole fortress had forgotten the cells."
		_:
			first = "Sir Gigglebuns? Oh, thank the goddesses. I've been hiding out here since the fortresses fell."
	return [
		{"text": first, "anim": "happy"},
		{"text": "Captain Rowena's holding Haven Village, they say. I'll make for the refuge. Go on, there are others out there!", "anim": "talk", "event": "rescue"},
	]


static func on_event(npc: Node, ev: String) -> void:
	if ev == "rescue":
		var id := Garrison.id_of(String(npc.npc_name))
		if id != "":
			# Once the talk is over: they set off (and leave the scene).
			Dialogue.finished.connect(func() -> void:
				Progress.set_flag(Garrison.flag_of(id))
				Sfx.play("secret", -4.0, 0.0), CONNECT_ONE_SHOT)
