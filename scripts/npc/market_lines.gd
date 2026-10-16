extends RefCounted
## Castle Town's market square (Beta 1.5.0): the stall-keepers (each with
## something real for sale on the counter), people passing through, and PIP,
## the King's page, who cries the day's news by the fountain (Gossip.news:
## the story's next step). The same people come back to the square in every
## age of the town but the fallen one; in the war Pip runs messages in the
## refuge, and during the fall waits in Himeko's palace.


static func lines(npc: Node) -> Array:
	var who := String(npc.npc_name)
	var e := HouseLines.era()
	match who:
		"Pip":
			return _pip(npc, e)
		"Fruit Seller":
			return _seller(npc, e, "Apples, pears, sweet red ones from the Southern Fields! A heart's worth of goodness for ten Coins. That's on the counter. Help yourself, then pay me.",
				"Every apple I sold this year came from trees the goblins didn't burn. I thank each tree personally.",
				"Fruit's sweeter since you went west, Sir Knight. Or maybe it's just me.")
		"Fletcher":
			return _seller(npc, e, "Arrows, ten for twenty! Fletched with goose feathers, straight as the King's road. Straighter. The King's road has a bend in it.",
				"I made arrows for the siege for a week straight. My fingers still smell of glue.",
				"Arrows for the Ridge? I've made a batch with silver heads. Silver for the dead. It's tradition. It might even work.")
		"Baker's Girl":
			return _seller(npc, e, "Honey buns! Idrith's own recipe, she says. Three hearts' worth of happiness! Twenty-five Coins. Bettany makes them; I sell them; you eat them. Everybody wins.",
				"Bettany's oven survived the fire, so the honey buns survived too. Some things are just meant to be.",
				"A honey bun for the road west, Sir Knight? Mara's dead don't eat. More for you.")
		"Potion Stall":
			return _seller(npc, e, "Red potions! Pour one in a bottle and it'll put every heart back. Forty Coins. Hazel's recipe; she'd want me to say that.",
				"Business was very good in the war. I'd rather it had been very bad.",
				"Potions for knights! Take two. Take one for the Commander, she never stops to buy her own.")
		"Townsman":
			return _passer(npc, e, ["Lovely day for the market. Every day's a lovely day for the market, when you sell turnips."],
				["Feels strange to walk through the square again without stepping round rubble."])
		"Townswoman":
			return _passer(npc, e, ["I come every morning to hear the page shout the news. He makes everything sound very exciting. Even the weather."],
				["The page is still shouting the news after all these years. His voice has broken, but he hasn't noticed."])
	return [Gossip.rumor()]


## Pip by the fountain: an introduction the first time, then the news.
static func _pip(npc: Node, e: String) -> Array:
	if int(npc.get("talks")) == 0:
		var hello := {
			"ch1": "Sir Gigglebuns! You came! I'm the herald now, too, as well as the page. Well, the King said 'go and shout somewhere else, Pip', and I chose here.",
			"fallen": "Sir Gigglebuns! The Princess let me stay. I'm helping. Mostly by telling everyone what's happening. Somebody has to!",
			"war": "Sir Gigglebuns! I'm running messages for Captain Rowena! Every message! I've worn out two pairs of boots.",
			"peace": "Sir Gigglebuns! Back in the square, where the news is! The King's very busy rebuilding, so I'm doing the shouting.",
			"ch5": "Sir Gigglebuns! SIR Gigglebuns! Knight Gigglebuns! You haven't changed a bit. I have. I'm taller. Look.",
			"end": "SIR GIGGLEBUNS! You're back! You did it! I've been shouting it for three days. I can barely talk. I'm going to keep going.",
		}
		return [{"text": String(hello.get(e, hello.ch1)), "anim": "happy"}, Gossip.news()]
	return [Gossip.news()]


static func _seller(npc: Node, e: String, before: String, peace: String, later: String) -> Array:
	if int(npc.get("talks")) % 2 == 1:
		return [Gossip.rumor()]
	var t := before
	if e == "peace":
		t = peace
	elif e in ["ch5", "end"]:
		t = later
	return [{"text": t, "anim": "talk"}]


static func _passer(npc: Node, e: String, before: Array, after: Array) -> Array:
	if int(npc.get("talks")) % 2 == 1:
		return [Gossip.rumor()]
	var src := before if e == "ch1" else after
	return [{"text": String(src[0]), "anim": "talk"}]
