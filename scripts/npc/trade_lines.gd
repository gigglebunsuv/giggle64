class_name TradeLines
extends RefCounted
## The trade chain (Beta 1.1.0) that ends in the Questlord's Shield, shared by
## the five people in it. Each NPC's lines ask lines_for() first; when it is
## that person's turn they say their piece, and the next thing in the chain
## is handed over after the talk (the NPC's gifts, GetItem "trade_<stage>").
##
##   Clover (Haven Village)  LUCKY HORSESHOE, cracked: starmetal from a falling star
##   Pink                    takes it: Aladriel's old shield was starmetal; she
##                           needs its pattern -> SMITH'S SKETCH
##   Ottilie (library)       the pattern is in the old armory ledger, which
##                           Marigold borrowed -> LIBRARY CARD
##   Marigold (shop)         the ledger, short one page (it wrapped a fish
##                           for Mira) -> ARMORY LEDGER
##   Mira (Mirror Lake)      kept the page (not because the drawing was nice)
##                           -> PATTERN PAGE
##   Pink                    forges the Questlord's Shield (trade "done")


static func lines_for(who: String, npc: Node) -> Array:
	var t := Progress.trade
	match who:
		"Clover":
			if t == "":
				_give(npc, "trade_horseshoe")
				return [
					{"text": "See this old horseshoe? Gran swore it came off a falling star. Never brought me a lick of luck, and now it's cracked right through.", "anim": "talk"},
					{"text": "Here, you have it. Maybe a smith can make something of it. Or maybe it'll bring YOU some luck, knight.", "anim": "happy"},
				]
		"Pink":
			if t == "horseshoe":
				_give(npc, "trade_sketch")
				return [
					{"text": "Wait. Wait wait wait. Is that... STARMETAL?! Where did you even GET this?!", "anim": "happy"},
					{"text": "Aladriel's old shield was starmetal, did you know? The *Questlord's Shield*. Lost in the sandstorms of Kholukkhaz. I could forge it again!", "anim": "talk"},
					{"text": "But I'd need the old pattern. The castle's *armory ledgers* had it, and Ottilie keeps the old ledgers at the *library*. Show her my sketch!", "anim": "talk"},
				]
			if t == "page":
				_give(npc, "shield_questlord")
				Progress.set_trade("done")
				return [
					{"text": "THE PATTERN! Smelling faintly of fish, but THE PATTERN! Give it here, give it here!", "anim": "happy"},
					{"text": "Starmetal heats slow and cools fast, so... hold still, this is the fun part...", "anim": "talk"},
					{"text": "*CLANG. CLANG. CLANG.* ...There. The *Questlord's Shield*, back in the world. Aladriel's going to cry. Don't tell her I said that.", "anim": "happy"},
				]
			if t in ["sketch", "card", "ledger"]:
				return [{"text": "Any luck with the pattern? Ottilie at the library keeps the old ledgers. I can't wait to get my hands on that starmetal!", "anim": "talk"}]
		"Ottilie":
			if t == "sketch":
				_give(npc, "trade_card")
				return [
					{"text": "A shield pattern from the old armory ledgers? Oh, how exciting! We did have the ledger... I lent it out. To *Marigold*.", "anim": "talk"},
					{"text": "She said she wanted to press flowers in it. Flowers! In a ledger! Take my *library card* and fetch it back for me, would you, dear?", "anim": "talk"},
				]
			if t in ["card", "ledger"]:
				return [{"text": "Marigold has the ledger, dear. At her shop. Do bring it back before she presses a cabbage in it.", "anim": "talk"}]
		"Marigold":
			if t == "card":
				_give(npc, "trade_ledger")
				return [
					{"text": "Ottilie's library card! Ooh, I'm in trouble. The ledger! Of course, of course, here it is...", "anim": "talk"},
					{"text": "...Ah. Funny story. One of the pages, the one with the pretty shield on it? I may have wrapped a fish in it. For *Mira*. It was a very good fish.", "anim": "happy"},
				]
			if t == "ledger":
				return [{"text": "Mira might still have that page. She never throws anything away. She'd never admit it, though!", "anim": "talk"}]
		"Mira":
			if t == "ledger":
				_give(npc, "trade_page")
				return [
					{"text": "A page? With a shield drawn on it? Why would I have... Hmph. Fine. It's in the drawer.", "anim": "talk"},
					{"text": "It's NOT because the drawing was nice or anything! It was just... a good page for wrapping things. Take it already!", "anim": "talk"},
				]
	return []


static func _give(npc: Node, item: String) -> void:
	if npc != null and "gifts" in npc:
		(npc.gifts as Array).append(item)


## A reminder of the current thing and where it goes next (pressing its button).
static func hint() -> String:
	match Progress.trade:
		"horseshoe":
			return "Clover's *Lucky Horseshoe*. Cracked starmetal, heavy as a stone. *Pink* would know what to make of it."
		"sketch":
			return "*Pink's Sketch* of a shield. *Ottilie* keeps the old armory ledgers at the library."
		"card":
			return "Ottilie's *Library Card*. *Marigold* has the ledger, at her shop."
		"ledger":
			return "The *Armory Ledger*, one page short. Marigold wrapped a fish in it, for *Mira*."
		"page":
			return "The *Pattern Page*: the Questlord's Shield. Take it to *Pink*!"
	return "Nothing much to look at."
