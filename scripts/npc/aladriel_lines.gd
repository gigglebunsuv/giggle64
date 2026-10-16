extends RefCounted
## What Aladriel says. A Questlord of Ladhellin: bold and brash, a little
## tall, never far from her giant sword, and very soft about Idrith, who sits
## beside her on the armory bench. (Idrith blushes while you talk to her.)
##
## Anims: idle, talk, shy (blushing).

const MET := "aladriel_met"
## Beta 1.4.0: once the hero is knighted, Aladriel hands down her old giant
## sword (the Questlord's Greatsword, Equipment "great").
const GREATSWORD := "sword_great"


static func lines(npc: Node) -> Array:
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "Hah! Another adventurer? You've got the look. I'm *Aladriel*, Questlord of *Ladhellin*.", "anim": "talk"},
			{"text": "And this is *Idrith*, our leader. And, uh... my girlfriend.", "anim": "shy"},
			{"text": "Don't let the quiet act fool you. She's the bravest of all of us.", "anim": "talk"},
		]
	if Progress.flag("ch5:knight") and not Progress.has_sword("great"):
		return _greatsword()
	var chats := [
		[{"text": "See this sword? Bigger than you, right? I once split a boulder clean in half with it.", "anim": "talk"},
			{"text": "...Idrith says I have to stop doing that to boulders.", "anim": "shy"}],
		[{"text": "This necklace? Idrith made it for me. I am never taking it off. Ever.", "anim": "shy"}],
		[{"text": "The *Desert of Ladhellin* is our home turf. If the sand starts moving, that's a *Sand Spinner*. Hit it before it hits you!", "anim": "talk"}],
		[{"text": "Spiders? Ha! I'm not scared of spiders. I just like them very, very dead...", "anim": "talk"},
			{"text": "...preferably before Idrith sees them.", "anim": "shy"}],
		[{"text": "We Questlords swore to protect Bunsriel. Me, I mostly swore to protect *her*. Same thing, really.", "anim": "shy"}],
		[{"text": "Idrith picked out my armor, y'know. Said it brings out my eyes.", "anim": "talk"},
			{"text": "...It totally does.", "anim": "shy"}],
		[{"text": "A whole ruin came down on us once. I held the ceiling up long enough for Idrith to get out.", "anim": "talk"},
			{"text": "She cried for a week. Worth it. Don't tell her I said that.", "anim": "shy"}],
		[{"text": "She leads, I swing the sword. Best arrangement in the kingdom. She always knows where we should go.", "anim": "talk"}],
	]
	return chats[(npc.talks - 2) % chats.size()]


static func _greatsword() -> Array:
	return [
		{"text": "Well, well! *Sir Gigglebuns*! Look at you, all knighted up and shiny.", "anim": "talk"},
		{"text": "Y'know, my old sword's been gathering dust since Pink forged me a new one. A bigger one. Obviously.", "anim": "talk"},
		{"text": "...Idrith says we can't keep two giant swords in the house.", "anim": "shy"},
		{"text": "So it's yours, knight! Hold it with *both hands*, and sling that shield on your back while it's out. Trust me.", "anim": "talk",
			"event": "give_greatsword"},
	]


static func on_event(npc: Node, ev: String) -> void:
	if ev == "give_greatsword" and not Progress.has_sword("great"):
		npc.gifts.append(GREATSWORD)
