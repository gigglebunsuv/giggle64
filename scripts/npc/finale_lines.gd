extends RefCounted
## The end of Chapter V (Beta 1.5.0): the Ashwick scout in the Sanctum Ruin's
## cages, and the things to read in the Astral Rift (the hub's plaque, each
## drift's stone, the hall of remembrance).


static func lines(who: Node) -> Array:
	if who is Examine:
		return _read(String((who as Examine).key))
	match String(who.npc_name):
		"Ashwick Scout":
			return _scout()
	return ["..."]


static func _scout() -> Array:
	if Progress.flag("ch5:velloran_done"):
		return [{"text": "Is it... is he gone? Velloran? Ha. Wait till Elder Maud hears. I'll find my own way home, Knight. Go and do whatever comes next.", "anim": "happy"}]
	return [
		{"text": "Knight?! Of Haven? Oh, thank the stars. They caught me watching the chapel two nights ago.", "anim": "talk"},
		{"text": "They're all through there, round a circle of blue fire. Velloran's the one in white. He hasn't stopped chanting since the sky broke.", "anim": "talk"},
		{"text": "And Knight, his ward. Steel just rings off it. I saw one of my arrows bounce. If you've got anything that shines like starlight, now's the time.", "anim": "talk"},
	]


static func _read(key: String) -> Array:
	match key:
		"hub_plaque":
			var lit := 0
			for i in 4:
				if Progress.flag("astral_rift:lock%d" % (i + 1)):
					lit += 1
			if lit >= 4:
				return [{"text": "All four star locks are burning. Over the dais, the dream stair climbs to the highest ring.\n*DREAM, AND CLIMB.*", "instant": true}]
			return [{"text": "Words of starlight, set in the floor:\n*FOUR STARS FOR FOUR DRIFTS OF MEMORY. LIGHT THEM, AND THE WAY TO THE HEART WILL BE DREAMED.*\n(%d of 4 lit.)" % lit, "instant": true}]
		"drift_2":
			return [{"text": "*THE SPIRES OF MEMORY.* The wind of Skyreach, and towers that are no longer anywhere at all.", "instant": true}]
		"drift_3":
			return [{"text": "*THE BURNING HALLS.* The Citadel burns here still, in memory. The fire remembers being commanded.", "instant": true}]
		"drift_4":
			return [{"text": "*THE BARROW OF NIGHT.* The kings' stones, Mara's bells, and the dead who do not know they may rest.", "instant": true}]
		"remembrance":
			return [
				{"text": "A hall of statues, each one a thing you have fought, carved in pale stone by no hand at all: the Gullagog, Incunax, Grukk, the Hollow King, Magmaw, Mara...", "instant": true},
				{"text": "At the end of the row stands an empty plinth. On it, scratched in a careful hand: *FOR WHATEVER COMES NEXT.*", "instant": true},
			]
	return ["..."]
