class_name CatchUp
extends RefCounted
## Nothing is lost for good (Beta 1.5.1). Some places close for ever as the
## story moves on: the burning Citadel once Firebuns is sealed, the war-time
## field and refuge at the peace, and the castle itself (its gate sealed while
## the town is rebuilt). Whatever the hero left behind in them turns up again
## after the peace, from someone who would have found it:
##   Captain Rowena (the rebuilt town's gate, then the Knights' Yard): the
##     lost garrison's stragglers, all her rewards for them, and the chart
##     scrap from the goblin camps' loot;
##   Pink (her armory): from the salvage crews, the Longshot and the chart
##     scrap out of the Citadel, and the castle oubliette's Piece of Heart;
##   Posy: if Pepper was never brought home, he found his own way back.
## Each list is empty when nothing is owed; the "event" on its last page
## hands everything over (the gifts follow the talk).

const ROWENA_EVENT := "catch_up_rowena"
const PINK_EVENT := "catch_up_pink"
const POSY_EVENT := "catch_up_posy"
## The chart scraps that lay only in closing places.
const CAMP_CHART := 2
const CITADEL_CHART := 6
const CASTLE_HEART := "castle:heart_piece"


static func _after_peace() -> bool:
	return Progress.flag("ch4:peace")


# --- Rowena ---------------------------------------------------------------------

static func _garrison_owed() -> bool:
	if Garrison.rescued() < Garrison.SOLDIERS.size():
		return true
	for n: int in Garrison.REWARDS:
		if not Progress.flag("garrison:reward_%d" % n):
			return true
	return false


static func rowena() -> Array:
	if not _after_peace():
		return []
	var owed_men := _garrison_owed()
	var owed_chart := not Progress.flag(TreasureCharts.scrap_flag(CAMP_CHART))
	if not owed_men and not owed_chart:
		return []
	var pages: Array = []
	if owed_men:
		pages.append({"text": "Before I forget. The last of the lost garrison straggled home after the sealing, every one of them, still telling stories about you.", "anim": "happy"})
		pages.append({"text": "The Guard looks after its own, and its friends. These were waiting for you. Don't argue: it's an order.", "anim": "talk"})
	if owed_chart:
		pages.append({"text": "And when we cleared out the goblin camps, one of their chests had this in it. A scrap of an old treasure chart. I'd say it's yours.", "anim": "talk"})
	(pages[-1] as Dictionary)["event"] = ROWENA_EVENT
	return pages


# --- Pink -----------------------------------------------------------------------

static func pink() -> Array:
	if not _after_peace():
		return []
	var long := Progress.has_item("hookshot") and not Progress.flag(Progress.LONGSHOT)
	var chart := not Progress.flag(TreasureCharts.scrap_flag(CITADEL_CHART))
	var heart := not Progress.flag(CASTLE_HEART)
	if not long and not chart and not heart:
		return []
	var pages: Array = [{"text": "Oh, good, you're here! The salvage crews keep bringing me things they've dug out of the old castle. Some of it's got your name all over it.", "anim": "happy"}]
	if long:
		pages.append({"text": "This grapple hook head was frozen solid in the Citadel's library. I thawed it out and fitted it to yours. Twice the chain! Don't thank me, it was fun.", "anim": "happy"})
	if chart:
		pages.append({"text": "And this scrap of a treasure chart was in the Citadel's vault. Treasure's not my business, but it's definitely yours.", "anim": "talk"})
	if heart:
		pages.append({"text": "Oh, and this was down in a hole behind the castle's dungeon wall. It's warm. It feels like it's *beating*. Here, you have it!", "anim": "talk"})
	(pages[-1] as Dictionary)["event"] = PINK_EVENT
	return pages


# --- Posy -----------------------------------------------------------------------

static func posy() -> Array:
	if not _after_peace() or not Progress.flag("pepper:asked") or Progress.flag("pepper:rewarded"):
		return []
	return [
		{"text": "Pepper came home all by himself after the war! He was sitting on the doorstep, all sooty, like he'd only popped out.", "anim": "happy"},
		{"text": "But you went out looking for him in all that fire, so this is still yours. My whole savings! Say thank you, Pepper!", "anim": "happy", "event": POSY_EVENT},
	]


# --- Handing it over -------------------------------------------------------------

## For the lines scripts' on_event: true if `ev` was a catch-up (and was handled).
static func on_event(npc: Node, ev: String) -> bool:
	match ev:
		ROWENA_EVENT:
			for id: String in Garrison.SOLDIERS:
				Progress.set_flag(Garrison.flag_of(id))
			for n: int in Garrison.REWARDS:
				var f := "garrison:reward_%d" % n
				if not Progress.flag(f):
					Progress.set_flag(f)
					npc.gifts.append(String(Garrison.REWARDS[n]))
			Progress.set_flag("garrison:all_thanked")
			if not Progress.flag(TreasureCharts.scrap_flag(CAMP_CHART)):
				npc.gifts.append("chart_%d" % CAMP_CHART)
			return true
		PINK_EVENT:
			if Progress.has_item("hookshot") and not Progress.flag(Progress.LONGSHOT):
				npc.gifts.append("longshot")
			if not Progress.flag(TreasureCharts.scrap_flag(CITADEL_CHART)):
				npc.gifts.append("chart_%d" % CITADEL_CHART)
			if not Progress.flag(CASTLE_HEART):
				Progress.set_flag(CASTLE_HEART)
				npc.gifts.append("heart_piece")
			return true
		POSY_EVENT:
			for f in ["pepper:found", "pepper:home", "pepper:rewarded"]:
				Progress.set_flag(f)
			npc.gifts.append("rupee_purple")
			return true
	return false
