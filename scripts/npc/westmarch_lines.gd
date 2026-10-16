extends RefCounted
## What Aladriel and Idrith say in Westmarch Fortress's great hall (Chapter
## IV), where they hold out behind a barricade with the last of the garrison.

const MET := "ch4:westmarch_met"


static func lines(npc: Node) -> Array:
	var first := not Progress.flag(MET)
	match String(npc.npc_name):
		"Aladriel":
			if first:
				Progress.set_flag(MET)
				return [
					{"text": "Knight! You made it through the yard. Good. We've been holding this hall since the gate went down.", "anim": "talk"},
					{"text": "The mage from Haven came here. It's up in the *west tower* now, and an ogre the goblins call *Grukk* has the keep roof. He broke the gate with his bare club.", "anim": "talk"},
					{"text": "The tower's stair runs up from the *armory*, west, over the stables. Its door's locked. The garrison's keys went down into the *cellars* with the prisoners.", "anim": "talk"},
					{"text": "Idrith and I hold this hall. You take the fight to them. Go.", "anim": "talk"},
				]
			if Progress.flag("westmarch_fortress:mage_clear"):
				return [{"text": "The mage is gone? Then it's only Grukk. The roof's reached from the *north-east*, up through the barracks' side of the keep.", "anim": "talk"}]
			return [{"text": "The armory is above the stables. Whatever's in there, the mage wanted it kept from us.", "anim": "talk"}]
		"Idrith":
			if first:
				Progress.set_flag(MET)
				return [
					{"text": "Y-you came! Of course you came. Aladriel said you would. She says that about everything, but she was right.", "anim": "talk"},
					{"text": "The garrison's soldiers were taken down to the *cells*, under the stables. If you find them... please. They're only frightened.", "anim": "talk"},
				]
			if Progress.flag("westmarch_fortress:cells_clear"):
				return [{"text": "You freed the cells? Oh, thank you. Thank you. I'll tell Rowena, if we ever see Haven again.", "anim": "happy"}]
			return [{"text": "We're all right here. Aladriel hasn't sat down in two days, but we're all right.", "anim": "talk"}]
	return ["..."]
