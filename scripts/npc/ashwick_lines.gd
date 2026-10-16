extends RefCounted
## The other people of Ashwick, by name: Wren (the gravekeeper, who tends the
## camp's dead and knows the wisps of the Forest of the Dead are Batela's
## own), Odile (who stood guard at Batela Keep the night the king was
## poisoned, and did nothing) and Tamsin (ten, and not afraid of anything).
##
## Pages follow the Dialogue format; "anim": talk, happy, idle.


static func lines(npc: Node) -> Array:
	match String(npc.npc_name):
		"Wren":
			return _wren(npc)
		"Odile":
			return _odile(npc)
		"Tamsin":
			return _tamsin(npc)
	return []


static func _pick(npc: Node, chats: Array) -> Array:
	return [chats[(npc.talks - 1) % chats.size()]]


static func _wren(npc: Node) -> Array:
	if Progress.flag("ch4:grove_known") and not Progress.has_item("grave_spade"):
		npc.gifts.append("grave_spade")
		npc.gifts.append("chart_1")
		return [
			{"text": "You're back. And you've got a digging look about you. Don't argue, I know the look.", "anim": "talk"},
			{"text": "A buried way into a grove in the Dark Forest? That's old earth. Old earth wants an old spade.", "anim": "idle"},
			{"text": "Take mine. It dug every grave in Batela for forty years, and my mother's before that. It knows how to be gentle with what's buried.", "anim": "talk"},
			{"text": "And this was in the handle's case. An old treasure chart, a scrap of one. My mother never could make sense of it. Maybe you will.", "anim": "talk"},
		]
	if Progress.flag("ch4:sealed"):
		return _pick(npc, [{"text": "Maud says we're going to Haven. All of us. To live. I'll need a new spade, I suppose. Keep that one.", "anim": "happy"}])
	if npc.talks == 1:
		return [
			{"text": "Mind the graves. ...No, you're fine. I'm *Wren*. I dig them. Somebody has to.", "anim": "talk"},
			{"text": "You came through the forest? Then you met them. The lights. Those are our people, the ones who didn't make it out. They still show the living the way.", "anim": "idle"},
		]
	var chats := [
		{"text": "If you ever need to dig where the dead sleep, come and find me. I've a spade that's older than the Keep.", "anim": "talk"},
		{"text": "The wisps chime when they're glad. They've been chiming a lot since you came through.", "anim": "happy"},
		{"text": "There's an old bell hung in a dead tree, out in the forest's east clearing. We used to ring it for funerals. Nobody rings it now.", "anim": "idle"},
	]
	if Progress.flag("ch3:seal_cracked"):
		chats.append({"text": "Something changed under the chapel. The dead are quieter now. Like they're holding their breath.", "anim": "idle"})
	return _pick(npc, chats)


static func _odile(npc: Node) -> Array:
	if npc.talks == 1:
		return [
			{"text": "You've got the look of a soldier. Haven's, by the tunic. I'm *Odile*. I wore the king's red once.", "anim": "talk"},
			{"text": "Don't. I know what he was. I stood at his door for six years. Selfish, cruel, petty. But he was ours.", "anim": "idle"},
		]
	if Progress.flag("ch3:keep_duel") and not Progress.flag("ch3:seal_cracked"):
		return _pick(npc, [
			{"text": "You fought him and you're standing. That means he let you live. That's worse, knight. That means he wants something.", "anim": "talk"},
			{"text": "I was on guard the night they poisoned him. I heard the cup go down. I didn't open the door. ...Maud told you, didn't she.", "anim": "idle"},
		])
	return _pick(npc, [
		{"text": "The Keep's walls were never breached, not in four hundred years. It took the king himself to burn it.", "anim": "talk"},
		{"text": "The blue-robes walked right past this camp like we weren't here. Like we were already ash.", "anim": "idle"},
		{"text": "Firebuns II was born in that keep, they say, or the first one was. The family portraits are still up in the hall, what's left of them.", "anim": "talk"},
	])


static func _tamsin(npc: Node) -> Array:
	if Progress.flag("ch4:peace") and World.area_id != "batela_fells":
		return _pick(npc, [
			{"text": "The trees here have LEAVES on! Green ones! I counted forty-one and then a bird sat on me.", "anim": "happy"},
			{"text": "Posy from Castle Town says her dog is the best dog. Pepper IS the best dog. I'm letting her be right.", "anim": "happy"},
			{"text": "I'm a knight-cook now. I knighted a pie. It was a very brave pie.", "anim": "happy"},
		])
	if npc.talks == 1:
		return [
			{"text": "Are you a *knight*?! A real one? Can I hold your sword? I won't swing it. Much.", "anim": "happy"},
			{"text": "I'm *Tamsin*. I'm ten. I walked all the way through the Forest of the Dead and I didn't cry once. The lights showed us the way!", "anim": "talk"},
		]
	return _pick(npc, [
		{"text": "Wren says the lights in the forest are our grandmas and grandpas. Mine was probably the bossy one.", "anim": "happy"},
		{"text": "What's Haven like? Are there trees with leaves on? Real green ones?", "anim": "talk"},
		{"text": "When I grow up I'm going to be a knight too. Or a cook. Knight-cook.", "anim": "happy"},
		{"text": "Maud cries sometimes when she thinks nobody's looking. I always look.", "anim": "idle"},
	])
