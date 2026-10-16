class_name PinkLines
extends RefCounted
## What Pink says. She runs the armory in Old Castle Town: cheerful, proud of
## her work, and (since Marigold had a word with her) charging for it now.
## She sells the next sword and shield tier one at a time: the Red Sword (80),
## the Magical Sword (180, which needs the Big Wallet) and the Iron Shield (60).
## The Mirror Shield and the Bun Sword are not hers to sell: one lies in
## Ladhellin Tower, the other waits in the Hidden Forest for the three
## goddesses' bun pieces.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy.

const MET := "pink_met"
const PRICES := {"red": 80, "magical": 180, "iron": 60}
## She can't forge a blade until its metal can reach her: the Red Sword's
## ore comes up the south road (held by the goblins until the Southern Tower
## falls), the Magical Sword's moon-silver with the Ladhellin caravans (which
## won't cross the desert until its tower is quiet).
const UNLOCK := {"red": "southern_tower:boss_clear", "magical": "ladhellin_tower:boss_clear"}


static func can_forge(id: String) -> bool:
	return not UNLOCK.has(id) or Progress.flag(UNLOCK[id])


static func lines(npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Pink", npc) if Progress.flag(MET) else []
	if not trade.is_empty():
		return trade
	var pages: Array = []
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		pages = _first_meeting()
	# What the salvage crews dug out of places now closed (Beta 1.5.1).
	pages.append_array(CatchUp.pink())
	pages.append({"text": "So! What'll it be today?", "anim": "talk", "choices": [
		["Upgrade my sword", _sword()],
		["A sturdier shield", _shield()],
		["Just looking", [_chat(npc)]],
	]})
	return pages


static func on_event(npc: Node, ev: String) -> void:
	if CatchUp.on_event(npc, ev):
		return
	match ev:
		"buy_sword":
			var id := Progress.next_sword()
			if id in PRICES and can_forge(id) and Progress.add_rupees(-PRICES[id]):
				npc.gifts.append("sword_" + id)
		"buy_shield":
			var id := Progress.next_shield()
			if id in PRICES and Progress.add_rupees(-PRICES[id]):
				npc.gifts.append("shield_" + id)


static func _first_meeting() -> Array:
	return [
		{"text": "Oh! A customer! Welcome to *Pink's Armory*, the finest forge in all of *Old Castle Town*!", "anim": "happy"},
		{"text": "I'm *Pink*. I make swords, I mend shields, and I hit hot metal with a hammer all day long. Best job there is!", "anim": "talk"},
		{"text": "Ooh, is that a *Squire's Sword*? Cute! ...But we can do *much* better than that.", "anim": "talk"},
	]


## An offer: the pitch, the price, and Buy / No thanks. `ev` hands it over.
static func _offer(pitch: String, id: String, ev: String) -> Array:
	var price: int = PRICES[id]
	var buy: Array
	if price > Progress.wallet:
		buy = [{"text": "Oh... that's more Coins than your wallet can even hold! Come back with a bigger one, okay?", "anim": "talk"}]
	elif Progress.rupees < price:
		buy = [{"text": "Hmm, you're a little short. *%d* Coins, remember? Cut some grass, break some pots!" % price, "anim": "talk"}]
	else:
		buy = [{"text": "Sold! Thank you kindly! Here you go!", "anim": "happy", "event": ev}]
	return [
		{"text": pitch, "anim": "talk"},
		{"text": "It's yours for *%d* Coins. Deal?" % price, "anim": "talk", "choices": [
			["Buy it", buy],
			["No thanks", [{"text": "No rush! It'll be right here on the wall.", "anim": "talk"}]],
		]},
	]


static func _sword() -> Array:
	match Progress.next_sword():
		"red" when not can_forge("red"):
			return [
				{"text": "A *Red Sword*? Oh, I'd love to! But I can't. Not yet.", "anim": "talk"},
				{"text": "Its steel comes from the ore pits down south, and the goblins hold the whole *south road* now. Not one cart has come up since spring!", "anim": "talk"},
				{"text": "They say their nest is that old tower in the *Southern Fields*. Somebody clears that out, and I'll have ore by the next morning. Hint, hint!", "anim": "happy"},
			]
		"magical" when not can_forge("magical"):
			return [
				{"text": "The *Magical Sword*... It's forged from *moon-silver*, and only the Ladhellin caravans bring it across the desert.", "anim": "talk"},
				{"text": "But they won't set out while *Ladhellin Tower* wakes the dead out there. The last caravan came back with half its camels!", "anim": "talk"},
				{"text": "Quiet that tower, and the silver will come. Then I'll make you something that *shines*.", "anim": "happy"},
			]
		"red":
			return _offer("A *Red Sword*, then! Dark steel, a red grip, and a little longer than what you've got.", "red", "buy_sword")
		"magical":
			return _offer("Ready for the *Magical Sword*? Longer, broader, and polished till it shines like the moon.", "magical", "buy_sword")
		"bun":
			return [
				{"text": "The *Bun Sword*? Oh, that one on my wall is just a copy I made for fun.", "anim": "talk"},
				{"text": "The real one sleeps in the *Hidden Forest*, on an old pedestal between three standing stones.", "anim": "talk"},
				{"text": "They say it only shows itself to a knight who carries the three goddesses' *bun pieces*. One from each of the great towers!", "anim": "happy"},
			]
		"great" when Progress.flag("ch5:knight"):
			return [
				{"text": "Something bigger than the *Bun Sword*? Ha! Ask *Aladriel*. I just forged her a new one, and her old one needs a home.", "anim": "happy"},
			]
	return [{"text": "You've got the *Bun Sword*! There's nothing finer in all of Bunsriel. Even I can't top that!", "anim": "happy"}]


static func _shield() -> Array:
	match Progress.next_shield():
		"iron":
			return _offer("An *Iron Shield*! Solid iron, riveted all round. It'll stop blows that go straight through wood.", "iron", "buy_shield")
		"mirror":
			return [
				{"text": "A *Silvered Shield*? Oh, I wish! Nobody alive knows how to make one.", "anim": "talk"},
				{"text": "The old sun-priests of *Ladhellin* had one, though. They say it's still up in their tower, out in the desert.", "anim": "talk"},
				{"text": "If you ever find it, bring it by! I'd love just to *look* at it.", "anim": "happy"},
			]
	return [{"text": "That's the best shield I've got! Mind you don't scratch it.", "anim": "talk"}]


static func _chat(npc: Node) -> Dictionary:
	var chats := [
		{"text": "*Aladriel* and *Idrith*? They're regulars. Well... mostly they come for the bench. And each other.", "anim": "talk"},
		{"text": "Hammer, anvil, fire. That's the whole secret! Okay, and about ten years of burnt fingers.", "anim": "happy"},
		{"text": "Every blade on that wall, I made myself. The dents are the customers' fault.", "anim": "talk"},
		{"text": "Marigold says giving swords away is bad business. ...She's right. Don't tell her I said so.", "anim": "happy"},
	]
	return chats[(npc.talks - 1) % chats.size()]
