class_name Garrison
extends RefCounted
## The lost garrison (Chapter IV side quest): eight soldiers of the Haven
## Guard cut off when the fortresses fell. Each one found and spoken to makes
## for Haven (flag "rescue:<id>") and turns up in the refuge; Captain Rowena
## rewards every second one.
##
## Where they are: one caged in each goblin war camp, two out on the burning
## field, three in Westmarch Fortress's cells.

## id -> [name, where (for the soldier's own words), what they say once home].
const SOLDIERS := {
	"ansel": ["Guard Ansel", "field", "Ansel, ma'am! Hid under the west bridge three days. I'm never eating river fish again."],
	"brin": ["Guard Brin", "camp_1", "The goblins wanted me to cook for them. I burned everything. On purpose. Mostly."],
	"corwen": ["Guard Corwen", "camp_2", "Corwen of Eastgate. I saw the east beacon go out. I'll tell anyone who'll listen what that was like."],
	"della": ["Guard Della", "camp_3", "Della. I'm back on the wall tonight. Somebody has to be."],
	"edda": ["Guard Edda", "field", "My leg's mending. The goddesses' own knight carried me off that hill, you know. Well, walked me."],
	"fenn": ["Guard Fenn", "westmarch", "Fenn, of Westmarch. We held the cells as long as we could. Then we were in them."],
	"gwyn": ["Guard Gwyn", "westmarch", "Gwyn, ma'am. If I never see a sapphire again, it'll be too soon."],
	"hollis": ["Guard Hollis", "westmarch", "Hollis. The Questlords got us out of the hall. You got us out of the hole. I owe everybody."],
}
## Rescues at which Captain Rowena gives something, and what.
const REWARDS := {2: "bomb_bag_up", 4: "quiver_up", 6: "heart_piece", 8: "shield_polish"}


static func flag_of(id: String) -> String:
	return "rescue:" + id


static func is_rescued(id: String) -> bool:
	return Progress.flag(flag_of(id))


static func rescued() -> int:
	var n := 0
	for id: String in SOLDIERS:
		if is_rescued(id):
			n += 1
	return n


static func soldier_name(id: String) -> String:
	return String(SOLDIERS.get(id, ["Guard", "", ""])[0])


static func id_of(npc_name: String) -> String:
	for id: String in SOLDIERS:
		if soldier_name(id) == npc_name:
			return id
	return ""
