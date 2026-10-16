extends RefCounted
## What Elder Maud says, at Ashwick, the survivors' camp in the Batela Fells.
## She keeps the camp together. Long ago she was one of the people who
## poisoned Firebuns III in his sleep, and she believes the burning of the
## Fells was his revenge for it (her confession is a scene: Story.ch3_confession,
## after the duel at the Keep).
##
## Pages follow the Dialogue format; "anim": talk, happy, idle.

const MET := "ch3:maud_met"


static func lines(npc: Node) -> Array:
	# After the sealing, in Haven: Ashwick's people are its neighbors now.
	if Progress.flag("ch4:peace") and World.area_id != "batela_fells":
		var peace := [
			{"text": "Haven gave us a field by the river and timber for houses. Timber! I'd forgotten wood could be anything but ash.", "anim": "happy"},
			{"text": "I still dream of the Keep. But now, when I wake, there are birds. The birds help.", "anim": "talk"},
			{"text": "You froze him and sent him away. Not dead. *Held.* ...That is a kinder thing than we did to him. Thank you for it.", "anim": "idle"},
		]
		return [peace[(npc.talks - 1) % peace.size()]]
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "A traveler? Out of the Forest of the Dead, and still breathing? Sit, sit by the fire before you fall down.", "anim": "talk"},
			{"text": "I'm *Maud*. I keep Ashwick, for what it's worth. We're all that's left of Batela. The rest of us... the forest has them now.", "anim": "idle"},
			{"text": "He came back, you know. Our king. *Firebuns III*. Dead and buried, and he came back with a fire in his fist, and he burned his own land to the ground.", "anim": "talk"},
			{"text": "And not a month ago, men in blue robes came over the moor. The *Sapphire Order*. They went down into the crypt under the *old chapel*, west of here, and they put a ward on the gate.", "anim": "talk"},
			{"text": "Odile swears she's seen a figure on the walls of *Batela Keep* at night, up on the north ridge. A tall one, with a light in his hand.", "anim": "idle"},
			{"text": "If you mean to go up there... come back, young knight. Ashwick has buried enough.", "anim": "talk"},
		]
	if not Progress.flag("ch3:keep_duel"):
		var hints := [
			{"text": "The Keep is up on the north ridge. Take the road past the old well; it climbs right up to the gate.", "anim": "talk"},
			{"text": "The crypt under the old chapel has an iron gate. I have the key to it, yes. But you don't want to go down there. Not yet.", "anim": "idle"},
			{"text": "Eat something before you go. Everyone in Ashwick who has gone up to the Keep alone has... well. Eat something.", "anim": "talk"},
		]
		return [hints[(npc.talks - 1) % hints.size()]]
	if not Progress.flag("ch3:confession"):
		return [{"text": "Lie still. You've been through enough for one night.", "anim": "idle"}]
	if not Progress.flag("visited:sapphire_sanctum"):
		return [
			{"text": "The crypt gate under the chapel is open now. Whatever those blue-robes are doing down there, end it.", "anim": "talk"},
			{"text": "...Thank you for not looking at me differently. Or for being polite enough to pretend.", "anim": "idle"},
		]
	if not Progress.flag("ch3:seal_cracked"):
		var chats := [
			{"text": "Wren says the wisps in the forest have been restless since you came. She thinks they're watching over you.", "anim": "talk"},
			{"text": "There were old stories, in Batela, about a light the fire can't touch. Starlight, my grandmother said. I always thought it was a lullaby.", "anim": "idle"},
		]
		return [chats[(npc.talks - 1) % chats.size()]]
	if not Progress.flag("ch3:prophecy_read"):
		return [
			{"text": "The whole Fells shook when you came up out of that crypt. Every fire in the camp flared blue for a moment, then gold again.", "anim": "talk"},
			{"text": "That book you're carrying, the prophecy... I can't read the old script. Take it home to someone who can. Someone in Haven.", "anim": "talk"},
		]
	var later := [
		{"text": "We're planting again, a little. Nothing grows in ash, they say. We'll see.", "anim": "happy"},
		{"text": "You'll always have a place at this fire, young knight. Always.", "anim": "happy"},
	]
	return [later[(npc.talks - 1) % later.size()]]
