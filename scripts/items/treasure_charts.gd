class_name TreasureCharts
extends RefCounted
## The old treasure charts (Chapter IV side quest, "The Buried Charts"): six
## torn scraps, each with an X and a scrawled hint, and under each X a
## treasure for the Grave Spade (a DigSpot with id "chart_<n>").
##
## Scraps: Wren gives the first with the spade; the others lie in a war camp,
## Westmarch Fortress, the Dark Forest, the Temple of Bun and the Citadel.

## n -> [the hint on the scrap, the prize under the X].
const CHARTS := {
	1: ["The lone hill in the middle of the fields: dig at the great tree's roots, on the castle side.", "rupee_purple"],
	2: ["In the desert, where the oasis palms throw their shade.", "heart_piece"],
	3: ["Mirror Lake's west shore, where the old landing looks out over the islets.", "nut_pouch_up"],
	4: ["Out behind the hermit's hut in the West Marshlands.", "rupee_gold"],
	5: ["By Hilde's hut on Frostpeak, where the snow drifts deepest.", "rupee_purple"],
	6: ["Under the burnt bell tower in the Batela Fells, among the ashes.", "rupee_gold"],
}


static func scrap_flag(n: int) -> String:
	return "chart:%d" % n


static func dug_flag(n: int) -> String:
	return "dug:chart_%d" % n


static func hint(n: int) -> String:
	return String(CHARTS.get(n, ["", ""])[0])


static func prize(n: int) -> String:
	return String(CHARTS.get(n, ["", ""])[1])


static func scraps() -> int:
	var n := 0
	for i: int in CHARTS:
		if Progress.flag(scrap_flag(i)):
			n += 1
	return n


static func dug() -> int:
	var n := 0
	for i: int in CHARTS:
		if Progress.flag(dug_flag(i)):
			n += 1
	return n


## The journal's list: each scrap found, and whether its treasure is up.
static func journal_lines() -> Array:
	var out: Array = []
	for i: int in CHARTS:
		if Progress.flag(scrap_flag(i)):
			out.append([hint(i), Progress.flag(dug_flag(i))])
	return out
