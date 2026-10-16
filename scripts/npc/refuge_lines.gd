extends RefCounted
## What people say in Haven Village while it is the last refuge (Chapter IV):
## Captain Rowena of the Haven Guard (the war's news, and the lost garrison's
## rewards), Posy (her lost dog Pepper), the gate guard, and two things to
## read: the Guard's war map and the memorial to the fallen.
##
## Pages follow the Dialogue format; "anim" picks the pose.

const MET := "ch4:captain_met"


static func lines(who: Node) -> Array:
	if who is Examine:
		match String((who as Examine).key):
			"war_map":
				return _war_map()
			"memorial":
				return _memorial()
		return ["..."]
	match String(who.npc_name):
		"Captain Rowena":
			return _rowena(who)
		"Posy":
			return _posy(who)
		"Gate Guard":
			return _guard(who)
		"Aladriel", "Idrith":
			return _questlords(who)
	return ["..."]


static func _questlords(npc: Node) -> Array:
	var ala := String(npc.npc_name) == "Aladriel"
	if not Progress.has_item("grave_spade"):
		return [{"text": "The old way into the grove is buried. Wren in Ashwick buries things for a living. She'd know how to dig one up." if ala
			else "Ashwick is east, past the desert and the Forest of the Dead. Ask *Wren*, the gravekeeper. P-please hurry.", "anim": "talk"}]
	if not Progress.flag("ch4:sword_awake"):
		return [{"text": "The Dark Forest is south of the desert, past the brambles. Whatever you meet in there, it can't be worse than Grukk." if ala
			else "Ottilie says the grove is where the sword sleeps. Then go and wake it. We'll hold Haven until you're back.", "anim": "talk"}]
	return [{"text": "The sword... it's shining. Like it's breathing. Go, knight. The Citadel is waiting, and so is he." if ala
		else "We'll be right behind you. Always. That's what Questlords do.", "anim": "talk"}]


static func on_event(npc: Node, ev: String) -> void:
	match ev:
		"met":
			Progress.set_flag(MET)
		"garrison":
			for n: int in Garrison.REWARDS:
				var f := "garrison:reward_%d" % n
				if Garrison.rescued() >= n and not Progress.flag(f):
					Progress.set_flag(f)
					npc.gifts.append(String(Garrison.REWARDS[n]))
					if n == 8:
						Progress.set_flag("garrison:all_thanked")
					break
		"pepper_asked":
			Progress.set_flag("pepper:asked")
		"pepper_thanks":
			Progress.set_flag("pepper:rewarded")
			npc.gifts.append("rupee_purple")


static func _garrison_due() -> int:
	for n: int in Garrison.REWARDS:
		if Garrison.rescued() >= n and not Progress.flag("garrison:reward_%d" % n):
			return n
	return 0


static func _rowena(npc: Node) -> Array:
	# Met only after the camps were already broken (they can be found first).
	if not Progress.flag(MET) and Progress.flag("ch4:camps"):
		return [
			{"text": "Sir Gigglebuns. Rowena, captain of what's left of the Haven Guard. So *you're* the one who broke those war camps. I owe you a drink, and a lot more than that.", "anim": "happy"},
			{"text": "And keep your eyes open out there: I've *eight soldiers* unaccounted for. Send any you find home to me.", "anim": "talk", "event": "met"},
		]
	if not Progress.flag(MET):
		return [
			{"text": "Sir Gigglebuns. Rowena, captain of what's left of the Haven Guard. I wish we were meeting on a better day.", "anim": "talk"},
			{"text": "*Northwatch* fell three nights ago. We saw its beacon go out from the wall. *Eastgate* still holds. Westmarch too, for now.", "anim": "talk"},
			{"text": "Firebuns' goblins have pitched three *war camps* across Bunsriel Fields, right between Eastgate and us. Nothing gets through. Not food, not news, not soldiers.", "anim": "talk"},
			{"text": "Break those camps and Eastgate can breathe. And keep your eyes open out there: I've *eight soldiers* unaccounted for. Send any you find home to me.", "anim": "talk", "event": "met"},
		]
	var due := _garrison_due()
	if due > 0:
		var pages: Array = [{"text": "%s of my soldiers home, and every one of them talking about you. Here: the Guard looks after its own, and its friends." % ["Two", "Two", "Four", "Four", "Six", "Six", "Eight", "Eight", "Eight"][clampi(due, 0, 8)], "anim": "happy", "event": "garrison"}]
		if due == 8:
			pages.append({"text": "All eight. Every one. I asked Pink to work our gold leaf into your shields. Don't argue: it's an order.", "anim": "happy"})
		return pages
	if not Progress.flag("ch4:camps"):
		var left := 0
		for f: String in WarCamp.CAMP_FLAGS:
			if not Progress.flag(f):
				left += 1
		return [{"text": "%d war camp%s still standing out on the field. Look for the smoke and the black banners." % [left, "s" if left != 1 else ""], "anim": "talk"}]
	if not Progress.flag("ch4:siege_won"):
		return [
			{"text": "Eastgate's gone dark. That means they're coming here next. Tonight, if I'm any judge.", "anim": "talk"},
			{"text": "Take the wall with us. The *ballista* is on the gatehouse, up the stair. Aladriel holds the east of the wall, Idrith the west. You go where it's worst.", "anim": "talk"},
		]
	if not Progress.flag("westmarch_fortress:boss_clear"):
		return [
			{"text": "We held. I still can't believe it. But that mage fled *west*, toward *Westmarch*, and Idrith and Aladriel rode after it at first light.", "anim": "talk"},
			{"text": "Westmarch is the last fortress standing. If it falls, Haven's alone. Go. *West of the field*, on the hills.", "anim": "talk"},
		]
	if not Progress.has_item("grave_spade"):
		return [
			{"text": "Three fortresses, and not one left. People are talking about leaving Haven. Leaving for where, I keep asking. Nobody answers.", "anim": "talk"},
			{"text": "You said the old way into that grove is *buried*. Then you want someone who knows how to dig up old ways. Ashwick has a gravekeeper, doesn't it?", "anim": "talk"},
		]
	var chats := [
		{"text": "Whatever you're doing out there, keep doing it. The children have started playing knights again.", "anim": "happy"},
		{"text": "The wall holds. The Guard holds. Go and do the thing only you can do.", "anim": "talk"},
		{"text": "I keep the names on the memorial myself. I carve them small, so there's room. I hope I never need the room.", "anim": "talk"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


static func _posy(npc: Node) -> Array:
	if Progress.flag("pepper:home"):
		if not Progress.flag("pepper:rewarded"):
			return [
				{"text": "PEPPER! You found him! You found him! He's all sooty and he smells like goblins and he's PERFECT!", "anim": "happy"},
				{"text": "Here, this is my whole savings. Don't say no! Pepper says thank you too. Say thank you, Pepper!", "anim": "happy", "event": "pepper_thanks"},
			]
		var chats := [
			{"text": "Pepper barks at you because he likes you. He barks at goblins because he doesn't.", "anim": "happy"},
			{"text": "When I grow up I'm going to be in the Haven Guard. Pepper too. He'll be a captain.", "anim": "talk"},
		]
		return [chats[(npc.talks - 1) % chats.size()]]
	if Progress.flag("pepper:found"):
		return [{"text": "Is that... is that barking? Is he with you?! PEPPER!", "anim": "happy"}]
	if not Progress.flag("pepper:asked"):
		return [
			{"text": "Mister knight... have you seen a dog? He's little and black and brown and his name is *Pepper*.", "anim": "talk"},
			{"text": "He ran away when the goblins came to our farm. Mama says he's gone. But I heard barking from where the goblins camp, out on the field. I *know* I did.", "anim": "talk", "event": "pepper_asked"},
		]
	return [{"text": "Pepper's out there somewhere. Near the goblins' tents, I bet. He always goes where he's not supposed to.", "anim": "talk"}]


static func _guard(npc: Node) -> Array:
	if Siege.active() and Progress.flag("ch4:eastgate_fallen"):
		return [{"text": "Steady, steady... When the horns sound, it's ladders first. Cut the ropes from inside!", "anim": "talk"}]
	if Progress.flag("ch4:siege_won"):
		var after := [
			{"text": "I was on this gate all night. I don't remember half of it. I remember you, though.", "anim": "talk"},
			{"text": "The ballista's still up there if you want a go. Mind the kick.", "anim": "happy"},
		]
		return [after[(npc.talks - 1) % after.size()]]
	return [{"text": "Gate's open by day for refugees. We bar it at dusk. Captain's orders.", "anim": "talk"}]


static func _war_map() -> Array:
	var state := func(f: String, fallen_text: String, holds_text: String) -> String:
		return fallen_text if Progress.flag(f) else holds_text
	return [{"text": "The Guard's war map, pinned flat with daggers. Little wooden towers mark the Citadel of Haven's three fortresses:\n*NORTHWATCH*: knocked over.\n*EASTGATE*: %s\n*WESTMARCH*: %s" % [
		state.call("ch4:eastgate_fallen", "knocked over.", "standing, a red pin in it."),
		state.call("ch4:westmarch_fallen", "knocked over.", "standing.")], "instant": true}]


static func _memorial() -> Array:
	return [
		{"text": "Names are carved small and close across the stone. At the top:\n*THE FALLEN OF THE CITADEL OF HAVEN. WE WILL KEEP THE WATCH.*", "instant": true},
		{"text": "*Northwatch:* Sergeant Harlan Voss, Guard Ilse Marrow, Guard Teodor Penn, Guard Wyn Ashby...\n*Eastgate:* Lieutenant Corra Dane, Guard Mattias Hale, Guard Pell Brightwater...", "instant": true},
		{"text": "And near the bottom, in an older hand:\n*Saelith and Varro, Questlords of Ladhellin, who held the east road.*\nSomeone has left two small scimitars of folded paper beneath them.", "instant": true},
	]
