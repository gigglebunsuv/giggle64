extends RefCounted
## What Hilde says, at the mountain hut on Frostpeak. She has kept the hut for
## thirty winters, sells warm clothes to anyone daft enough to climb up here,
## and has opinions about all of them. The Frost Mantle (MANTLE_PRICE) keeps
## out the cold of Frostpeak Hollow.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy, idle.

const MET := "hilde_met"
const MANTLE_PRICE := 90


static func lines(npc: Node) -> Array:
	var pages: Array = []
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		pages.append({"text": "Well! A visitor, all the way up here. And in a *short-sleeved tunic*. On Frostpeak.", "anim": "talk"})
		pages.append({"text": "I'm *Hilde*. I keep this hut, and I sell warm things to fools. You look like my best customer yet.", "anim": "happy"})
	if Progress.has_tunic("frost"):
		var chats := [
			{"text": "That mantle suits you. Keep the hood up in the Hollow, the wind down there has teeth.", "anim": "talk"},
			{"text": "Strange folk came up the mountain a while back. Blue robes, blue gems. Didn't buy a thing. Rude.", "anim": "talk"},
			{"text": "Thirty winters I've kept this hut. The falls never froze solid like that before those blue-robed folk came.", "anim": "idle"},
		]
		pages.append(chats[(npc.talks - 1) % chats.size()])
		return pages
	pages.append({"text": "Going down into that hollow behind the falls? You'll freeze solid in a minute and a half. Trust me.", "anim": "talk"})
	var buy: Array = [{"text": "Ha! Sold. Wear it well, and don't come back with frostbitten ears.", "anim": "happy", "event": "buy"}]
	if Progress.rupees < MANTLE_PRICE:
		buy = [{"text": "You haven't got enough Coins. Fur doesn't grow on trees, you know. It grows on foxes.", "anim": "talk"}]
	pages.append({"text": "My *Frost Mantle*, then: snow-fox fur, triple-stitched. *%d Coins*, and worth every one." % MANTLE_PRICE, "anim": "talk", "choices": [
		["Buy it", buy],
		["Not now", [{"text": "Suit yourself. Come back when your teeth start chattering.", "anim": "idle"}]],
	]})
	return pages


static func on_event(npc: Node, ev: String) -> void:
	if ev == "buy" and Progress.add_rupees(-MANTLE_PRICE):
		Sfx.play("rupee", -2.0)
		npc.gifts.append("tunic_frost")
