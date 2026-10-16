extends RefCounted
## What Clover says. She keeps the horses on the farm in the Southern Fields:
## easy-going, horse-mad, a little competitive. Biscuit is her favorite.
## She runs the jumping course in the corral (FenceCourse): clear it and
## Biscuit is the hero's (the Sugar Cube that calls her); clear it fast and
## Clover's spare Big Wallet is his too.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy.

const MET := "clover_met"
const OWNED := "horse_owned"
const WALLET := "clover_wallet"
## Her first gift once Biscuit is the hero's: a bottle of the ranch's milk.
## After that she fills an empty bottle with milk for MILK_PRICE rupees.
const MILK := "clover_milk"
const MILK_PRICE := 15


static func lines(_npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Clover", _npc) if Progress.flag(MET) else []
	if not trade.is_empty():
		return trade
	if Progress.flag("castle_fallen") and Progress.flag(MET):
		var fallen: Array = [{"text": "The horses won't settle since the castle caught fire. Biscuit keeps looking north. She's braver than me, that one.", "anim": "talk"}]
		if Progress.has_item("bow"):
			fallen.append(_range_offer())
		return fallen
	var pages: Array = []
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		pages = [
			{"text": "Howdy, stranger! Name's *Clover*. These are my horses, and that sweet golden girl in the corral is *Biscuit*.", "anim": "happy"},
			{"text": "She's got a mind of her own, but she sure seems to like you. Go on, walk up and press *A* to hop on!", "anim": "talk"},
		]
	if not Progress.flag(OWNED):
		pages.append({"text": "Want to run my *jumping course*? Ride through the *START* arch, jump all three fences round the track and back through the arch in under a *minute*.", "anim": "talk", "choices": [
			["Let's ride!", [
				{"text": "Yee-haw! The clock starts when you ride through the arch. Press *A* to spur her on, but don't wear her out!", "anim": "happy", "event": "arm"},
			]],
			["Maybe later", [{"text": "Biscuit'll be waiting!", "anim": "talk"}]],
		]})
		return pages
	if not Progress.flag(WALLET):
		pages.append({"text": "Think you two can clear the course in under *16 seconds*? Do it and my spare *Big Wallet* is yours!", "anim": "talk", "choices": [
			["You're on!", [{"text": "Ha! Show me what you've got!", "anim": "happy", "event": "arm"}]],
			["Not now", [{"text": "Biscuit needs a good run now and then, you hear?", "anim": "talk"}]],
		]})
		return pages
	if not Progress.flag(MILK):
		pages.append({"text": "Oh, before I forget! Here, take this. Fresh from Buttercup, our cow. Best milk in Haven, if I say so myself!", "anim": "happy", "event": "milk"})
		return pages
	if "empty" in Progress.bottles:
		pages.append({"text": "That's an empty bottle you've got there! Want me to fill it with milk? Just *%d Coins*." % MILK_PRICE, "anim": "talk", "choices": [
			["Yes, please", [{"text": "Comin' right up!", "anim": "happy", "event": "refill"}]],
			["No thanks", [{"text": "Suit yourself!", "anim": "talk"}]],
		]})
		return pages
	if Progress.has_item("bow") and _npc.talks % 2 == 1:
		return pages + [_range_offer()]
	var chats := [
		{"text": "Out on the open fields, use the *Sugar Cube* and Biscuit will come running. She can't go into towns, though!", "anim": "talk"},
		{"text": "Don't you forget to brush her. And give her a carrot. And tell her she's pretty.", "anim": "happy"},
		{"text": "Folks say there are archery targets by the road in the big field. Bet you can't hit them all from the saddle!", "anim": "talk"},
	]
	return pages + [chats[(_npc.talks - 1) % chats.size()]]


## A round on the target range (ArcheryRange) by the crossroads.
static func _range_offer() -> Dictionary:
	var play: Array = [{"text": "Yee-haw! The clock starts now! Every *gold center*, partner. Go, go, go!", "anim": "happy", "event": "range"}]
	if Progress.rupees < ArcheryRange.FEE:
		play = [{"text": "Twenty Coins a round, partner. Come back when your purse is heavier!", "anim": "talk"}]
	return {"text": "How about a round on my *target range* by the crossroads? Every *gold center* in *45 seconds* for *%d Coins*. There's a prize for a clean round!" % ArcheryRange.FEE, "anim": "talk", "choices": [
		["Let's shoot!", play],
		["Not now", [{"text": "Biscuit says you're chicken. I'm just passin' it on.", "anim": "talk"}]],
	]}


static func on_event(npc: Node, ev: String) -> void:
	if ev == "milk":
		Progress.set_flag(MILK)
		npc.gifts.append("bottle_milk")
	elif ev == "refill":
		if Progress.rupees < MILK_PRICE:
			Sfx.play("error", -4.0)
			Dialogue.start([{"text": "Oh! You're a little short on Coins, partner. Come back when you've got *%d*." % MILK_PRICE, "anim": "talk"}], npc)
		elif Progress.bottles.find("empty") >= 0:
			Progress.add_rupees(-MILK_PRICE)
			Progress.set_bottle(Progress.bottles.find("empty"), "milk")
			Sfx.play("bottle_pour", -4.0)
	if ev == "range" and Progress.add_rupees(-ArcheryRange.FEE):
		for r in npc.get_tree().get_nodes_in_group("archery_ranges"):
			(r as ArcheryRange).start()
	if ev == "arm":
		for c in npc.get_tree().get_nodes_in_group("fence_courses"):
			(c as FenceCourse).arm()
