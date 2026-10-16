class_name RebuildFund
extends RefCounted
## Rebuilding Old Castle Town after Firebuns is sealed (Chapter IV's peace):
## the Rebuilding Fund's board in the town square takes Rupees for one
## district at a time. A district paid for is rebuilt (flag
## "rebuild:<district>"): its rubble cleared, its scaffolds down, and its
## people and shops back.

## District -> [name on the board, Rupees, what comes back].
const DISTRICTS := {
	"market": ["THE MARKET", 100, "the market stalls, and Tansy's cup game"],
	"fountain": ["THE FOUNTAIN SQUARE", 80, "the old fountain, running again"],
	"homes": ["THE HOMES", 120, "the townsfolk's houses, and the people in them"],
	"armory": ["PINK'S ARMORY", 150, "Pink's armory, open for business"],
}
const ORDER := ["market", "fountain", "homes", "armory"]


static func flag_of(district: String) -> String:
	return "rebuild:" + district


static func is_rebuilt(district: String) -> bool:
	return Progress.flag(flag_of(district))


static func rebuilt() -> int:
	var n := 0
	for d: String in ORDER:
		if is_rebuilt(d):
			n += 1
	return n


## The board's talk: what each district still needs, and a choice per one.
static func board_pages() -> Array:
	var open: Array = ORDER.filter(func(d: String) -> bool: return not is_rebuilt(d))
	if open.is_empty():
		return [{"text": "*THE REBUILDING FUND*\nEvery district is rebuilt! Thank you, Sir Gigglebuns.\n-the people of Old Castle Town", "instant": true}]
	var choices: Array = []
	for d: String in open:
		var info: Array = DISTRICTS[d]
		var give: Array = [{"text": "You drop *%d* Coins into the box." % int(info[1]), "event": "fund_" + d}] if Progress.rupees >= int(info[1]) 			else [{"text": "You don't have enough Coins for that district yet. It needs *%d*." % int(info[1])}]
		choices.append(["%s (%d)" % [String(info[0]).capitalize(), int(info[1])], [{"text": "Give *%d* Coins to rebuild %s?" % [int(info[1]), info[2]], "choices": [
			["Give", give], ["Not yet", []],
		]}]])
		if choices.size() >= 2 and open.size() > 2:
			break
	choices.append(["Leave it", []])
	return [{"text": "*THE REBUILDING FUND*\nHelp us bring Old Castle Town back! Pick a district:", "choices": choices}]


## Pays for `district`: false (and nothing spent) without the Rupees.
static func fund(district: String) -> bool:
	if is_rebuilt(district) or not DISTRICTS.has(district):
		return false
	if not Progress.add_rupees(-int(DISTRICTS[district][1])):
		return false
	Progress.set_flag(flag_of(district))
	return true
