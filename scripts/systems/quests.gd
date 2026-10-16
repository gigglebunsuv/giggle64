class_name Quests
extends RefCounted
## The hero's journal (the pause screen's JOURNAL page): the main story, chapter
## by chapter, and the errands Haven's people give him. A quest shows once
## its `start` is met; each step ticks off when its condition is met, and the
## quest is done when the last step is.
##
## Conditions are strings:
##   "flag:<f>"      a Progress flag (Progress.flag)
##   "item:<id>"     an item owned (Progress.has_item)
##   "tunic:<id>"    a tunic owned
##   "bottle:<c>"    a bottle holding <c>
##   "fish:<lb>"     the Mirror Lake record at least <lb> pounds
##   "springs:<n>"   at least <n> Goddess Springs found
##   "scale:<n>"     at least that scale
##   "wallet:<n>"    a wallet holding at least <n>
##   "quiver:<n>"    a quiver holding at least <n>
##   "pages:<n>"     at least <n> pages of the Fari Incunabulum found
##   "rescued:<n>"   at least <n> of the lost garrison sent home to Haven
##   "charts:<n>"    at least <n> scraps of the old treasure charts found
##   "dug:<n>"       at least <n> of the charts' treasures dug up
##   "rebuilt:<n>"   at least <n> of Castle Town's districts rebuilt
##   "epitaphs:<n>"  at least <n> of the Barrow kings' epitaphs read
##   "any:<a>|<b>"   either condition

const MAIN := "main"
const SIDE := "side"

## Quest order is the page's order (main story first). Each quest:
## {id, kind, title, giver, start, steps: [[text, condition], ...]}.
const QUESTS := [
	{"id": "ch1", "kind": MAIN, "title": "THE GAUNTLET OF FIRE", "giver": "CHAPTER I", "start": "flag:woke_up", "steps": [
		["Clear the Lake Shrine on Mirror Lake.", "flag:lake_shrine:r7_clear"],
		["Win Alan's bun piece in the Southern Tower.", "flag:bun_piece:alan"],
		["Win Serielye's bun piece in Ladhellin Tower.", "flag:bun_piece:serielye"],
		["Win Aphiel's bun piece atop Skyreach Spire.", "flag:bun_piece:aphiel"],
		["Find what the Bog Tower hides, out in the West Marshlands.", "item:bloom_rod"],
		["Draw the Bun Sword in the Hidden Forest.", "flag:legend_told"],
		["Storm the Castle of Haven.", "flag:castle:rescued"],
		["Face Firebuns III on his throne.", "flag:game_beaten"],
	]},
	{"id": "ch2", "kind": MAIN, "title": "THE GAUNTLET'S TRAIL", "giver": "CHAPTER II", "start": "flag:game_beaten", "steps": [
		["Find Castle Town's survivors at Himeko's palace.", "flag:ch2:shelter_met"],
		["Recover the Iron Mallet from the castle armory.", "item:iron_mallet"],
		["Smash into Frostpeak Hollow, behind the frozen falls.", "flag:visited:frostpeak_hollow"],
		["Defeat the master of Frostpeak Hollow.", "flag:frostpeak_hollow:boss_clear"],
		["Tell Aladriel what you found.", "flag:ch2:bracers"],
		["Lift the great stone off the Sun Trial in the desert.", "flag:visited:sun_trial"],
		["Pass the Sun Trial.", "flag:sun_trial:done"],
		["Read where the Gauntlet's trail leads.", "flag:ch2:trail_found"],
	]},
	{"id": "ch3", "kind": MAIN, "title": "THE BATELA FELLS", "giver": "CHAPTER III", "start": "flag:ch2:trail_found", "steps": [
		["Follow the trail east, through the Forest of the Dead.", "flag:visited:batela_fells"],
		["Find the survivors' camp in the Batela Fells.", "flag:ch3:maud_met"],
		["Climb to the ruins of Batela Keep.", "flag:ch3:keep_duel"],
		["Hear what Elder Maud has to say.", "flag:ch3:confession"],
		["Go down into the crypt under the old chapel.", "flag:visited:sapphire_sanctum"],
		["Find the light the Gauntlet cannot command.", "flag:starlight"],
		["Defeat the master of the Sapphire Sanctum.", "flag:sapphire_sanctum:boss_clear"],
		["Stop the Order's ritual.", "flag:ch3:seal_cracked"],
		["Take the Dark Prophecy to Ottilie in Haven Library.", "flag:ch3:prophecy_read"],
	]},
	{"id": "ch4", "kind": MAIN, "title": "THE FALL OF BUNSRIEL", "giver": "CHAPTER IV", "start": "flag:ch4:war", "steps": [
		["Find Captain Rowena of the Haven Guard in Haven Village.", "flag:ch4:captain_met"],
		["Break the three goblin war camps on Bunsriel Fields.", "flag:ch4:camps"],
		["Hold Haven Village through the night.", "flag:ch4:siege_won"],
		["Reach Westmarch Fortress, west of the field, where Idrith and Aladriel hold out.", "flag:visited:westmarch_fortress"],
		["Defeat the master of Westmarch Fortress.", "flag:westmarch_fortress:boss_clear"],
		["Bring the survivors home to Haven.", "flag:ch4:despair"],
		["Ask Wren the gravekeeper in Ashwick about the buried way into the grove.", "item:grave_spade"],
		["Find the sacred grove in the Dark Forest, south of the desert.", "flag:ch4:temple_found"],
		["Pass the trial of the Temple of Bun.", "flag:ch4:sword_awake"],
		["Receive Lothelye's gift at the Temple's heart.", "flag:ch4:astral_seal"],
		["Storm the burning Citadel.", "flag:visited:citadel_assault"],
		["Face Firebuns III on the throne-room roof.", "flag:ch4:sealed"],
	]},
	{"id": "ch5", "kind": MAIN, "title": "FIREBUNS RETURNS", "giver": "CHAPTER V", "start": "flag:ch5:knight", "steps": [
		["Report to Commander Rowena in the Knights' Yard, by the castle.", "flag:ch5:yard_met"],
		["Pass Rowena's three trials: the Great Spin, the Down Thrust and the Shield Bash.", "flag:ch5:trained"],
		["Go down into the Barrow of Kings, under the old royal chapel.", "flag:visited:barrow_of_kings"],
		["Lay the Hollow King to rest.", "flag:barrow_of_kings:boss_clear"],
		["Follow the burning one to Cinderhold, east past the Northeastern Cliffs.", "flag:visited:cinderhold"],
		["Find the way into the Cinder Vault.", "flag:visited:cinder_vault"],
		["Defeat the master of the Cinder Vault.", "flag:cinder_vault:boss_clear"],
		["Reach the Gauntlet of Fire's old cradle.", "flag:ch5:cinder_done"],
		["Find the knights' camp at the west end of the West Marshlands.", "flag:ch5:front_seen"],
		["Learn the Parry from Commander Rowena.", "flag:front:parry_done"],
		["Follow Firebuns and Mara west, to Black Water Ridge beyond the marshes.", "flag:ch5:ridge_reached"],
		["Break Mara's three camps on the Ridge, with the knights of Haven.", "flag:ch5:camps_done"],
		["Find the way into Ridge Keep, at the top of the falls.", "flag:visited:ridge_keep"],
		["Face Mara, the Scourge of Bunsriel.", "flag:ch5:mara_done"],
		["Hear Rowena's news under the crack in the sky.", "flag:ch5:rift_seen"],
		["Find the Sapphire Order's last stand, in the crypt under the old chapel of the Batela Fells.", "flag:ch5:velloran_met"],
		["Defeat Archmagus Velloran.", "flag:ch5:velloran_done"],
		["Go to Lothelye's spring on the islet in the West Marshlands.", "flag:ch5:dream"],
		["Raise the cracked Astral Seal under the crack, at the top of Black Water Ridge.", "flag:ch5:rift_open"],
		["Light the four star locks of the Astral Rift.", "flag:astral_rift:lock4"],
		["Climb the dream stair to the heart of the Rift.", "flag:rift:blessed"],
		["End it.", "flag:ch5:firebuns_end"],
	]},
	{"id": "springs", "kind": SIDE, "title": "THE GODDESS SPRINGS", "giver": "LEGEND", "start": "any:springs:1|flag:legend_told", "steps": [
		["Find a Goddess Spring.", "springs:1"],
		["Find three Goddess Springs.", "springs:3"],
		["Find all five Goddess Springs.", "springs:5"],
	]},
	{"id": "incunabulum", "kind": SIDE, "title": "THE LOST PAGES", "giver": "FARI INCUNABULUM", "start": "pages:1", "steps": [
		["Find a page of the Fari Incunabulum.", "pages:1"],
		["Find three of the lost pages.", "pages:3"],
		["Find all five lost pages.", "pages:5"],
	]},
	{"id": "garrison", "kind": SIDE, "title": "THE LOST GARRISON", "giver": "CAPTAIN ROWENA", "start": "flag:ch4:captain_met", "steps": [
		["Find a lost soldier of the Haven Guard and send them home.", "rescued:1"],
		["Send four soldiers home to Haven.", "rescued:4"],
		["Send all eight soldiers home to Haven.", "rescued:8"],
		["Report to Captain Rowena.", "flag:garrison:all_thanked"],
	]},
	{"id": "charts", "kind": SIDE, "title": "THE BURIED CHARTS", "giver": "OLD CHARTS", "start": "charts:1", "steps": [
		["Dig where a chart scrap's X marks the spot.", "dug:1"],
		["Find all six chart scraps.", "charts:6"],
		["Dig up all six of the charts' treasures.", "dug:6"],
	]},
	{"id": "pepper", "kind": SIDE, "title": "WHERE IS PEPPER?", "giver": "POSY", "start": "flag:pepper:asked", "steps": [
		["Find Posy's dog, Pepper, somewhere out on the burning field.", "flag:pepper:found"],
		["Bring Pepper home to Posy in Haven Village.", "flag:pepper:home"],
	]},
	{"id": "rebuild", "kind": SIDE, "title": "REBUILDING CASTLE TOWN", "giver": "MARIGOLD", "start": "flag:ch4:peace", "steps": [
		["Give Coins to the Rebuilding Fund in Old Castle Town.", "rebuilt:1"],
		["Rebuild two of the town's districts.", "rebuilt:2"],
		["Rebuild all four districts.", "rebuilt:4"],
	]},
	{"id": "kings", "kind": SIDE, "title": "THE KINGS OF HAVEN", "giver": "THE BARROW", "start": "epitaphs:1", "steps": [
		["Read an epitaph in the Barrow of Kings.", "epitaphs:1"],
		["Read all seven kings' epitaphs.", "epitaphs:7"],
		["Find what the seven kings kept together.", "flag:barrow:kings_vault"],
	]},
	{"id": "himeko", "kind": SIDE, "title": "A FISH FOR THE PRINCESS", "giver": "HIMEKO", "start": "flag:himeko:met", "steps": [
		["Catch a fish and keep it in an empty bottle.", "any:bottle:fish|flag:himeko:fish_given"],
		["Bring it to Himeko's palace pond.", "flag:himeko:fish_given"],
		["Visit Princess Himeko again.", "flag:himeko:regalia"],
	]},
	{"id": "mira_fish", "kind": SIDE, "title": "THE LAKE'S LEGEND", "giver": "MIRA", "start": "flag:mira_rod", "steps": [
		["Land a fish of ten pounds at Mirror Lake.", "flag:lake:big_fish"],
		["Show Mira.", "flag:lake:fish_prize"],
		["Land a fish of twelve pounds.", "fish:12"],
		["Show Mira again.", "scale:1"],
		["Land a fourteen-pound monster.", "fish:14"],
		["Show Mira one last time.", "scale:2"],
	]},
	{"id": "tide", "kind": SIDE, "title": "THE SUNKEN CHEST", "giver": "MIRA", "start": "scale:1", "steps": [
		["Dive to the deepest bed of Mirror Lake.", "tunic:tide"],
	]},
	{"id": "mantle", "kind": SIDE, "title": "WARM CLOTHES", "giver": "HILDE", "start": "flag:hilde_met", "steps": [
		["Buy the Frost Mantle at Hilde's hut on Frostpeak.", "tunic:frost"],
	]},
	{"id": "lantern", "kind": SIDE, "title": "THE LIBRARIAN'S LANTERN", "giver": "OTTILIE", "start": "flag:ottilie_met", "steps": [
		["Visit Haven Library again.", "flag:ottilie_lantern"],
	]},
	{"id": "range", "kind": SIDE, "title": "CLOVER'S TARGET RANGE", "giver": "CLOVER", "start": "flag:range:played", "steps": [
		["Hit every target on the range.", "quiver:50"],
	]},
	{"id": "tansy", "kind": SIDE, "title": "TANSY'S CUP GAME", "giver": "TANSY", "start": "flag:tansy:played", "steps": [
		["Win five rounds in a row.", "wallet:500"],
	]},
	{"id": "rooster", "kind": SIDE, "title": "THE ROOSTER OF HAVEN", "giver": "HAVEN VILLAGE", "start": "flag:rooster:angry", "steps": [
		["Learn your lesson.", "flag:rooster:angry"],
	]},
]


static func check(cond: String) -> bool:
	if cond == "":
		return true
	var colon := cond.find(":")
	var kind := cond.substr(0, colon)
	var arg := cond.substr(colon + 1)
	match kind:
		"flag":
			return Progress.flag(arg)
		"item":
			return Progress.has_item(arg)
		"tunic":
			return Progress.has_tunic(arg)
		"bottle":
			return arg in Progress.bottles
		"fish":
			return Progress.fish_record >= int(arg)
		"springs":
			var n := 0
			for f: String in SaveGame.SPRING_FLAGS:
				if Progress.flag(f):
					n += 1
			return n >= int(arg)
		"scale":
			return Progress.scale >= int(arg)
		"wallet":
			return Progress.wallet >= int(arg)
		"quiver":
			return Progress.arrows_max >= int(arg)
		"pages":
			return IncunabulumLines.found() >= int(arg)
		"rescued":
			return Garrison.rescued() >= int(arg)
		"charts":
			return TreasureCharts.scraps() >= int(arg)
		"dug":
			return TreasureCharts.dug() >= int(arg)
		"rebuilt":
			return RebuildFund.rebuilt() >= int(arg)
		"epitaphs":
			return BarrowLines.read() >= int(arg)
		"any":
			for part in arg.split("|"):
				if check(part):
					return true
			return false
	return false


## The Bestiary's page in the journal (Bestiary): not a quest, a list.
const BESTIARY := {"id": "bestiary", "kind": SIDE, "title": "BESTIARY", "giver": "YOUR NOTES", "start": "", "steps": []}


## The quests begun so far: unfinished ones first (main story at the top), then
## those done; the Bestiary last, once anything is beaten.
static func known() -> Array:
	var open: Array = []
	var done: Array = []
	for q: Dictionary in QUESTS:
		if not check(String(q.start)):
			continue
		(done if is_done(q) else open).append(q)
	var out: Array = open + done
	if Bestiary.count() > 0:
		out.append(BESTIARY)
	return out


static func is_done(q: Dictionary) -> bool:
	if q.id == "bestiary":
		return false
	for st: Array in q.steps:
		if not check(String(st[1])):
			return false
	return true


## The steps to show: every one already done, and the next one.
static func shown_steps(q: Dictionary) -> Array:
	if q.id == "bestiary":
		var rows: Array = [["%d KINDS OF CREATURE BEATEN." % Bestiary.count(), false]]
		for l: String in Bestiary.lines():
			rows.append([l, false])
		return rows
	var out: Array = []
	for st: Array in q.steps:
		var ok := check(String(st[1]))
		out.append([st[0], ok])
		if not ok:
			break
	# The kings' epitaphs: each one read, in the order of their tombs.
	if q.id == "kings":
		for l: String in BarrowLines.journal_lines():
			out.append([l, true])
	# The treasure charts: each scrap's scrawl, struck through once dug.
	if q.id == "charts":
		for l: Array in TreasureCharts.journal_lines():
			out.append(["X: " + String(l[0]), bool(l[1])])
	return out


## The chapter a file's story flags have reached (1 until the first ending).
static func chapter_of(flags: Dictionary) -> int:
	if flags.get("ch5:knight", false):
		return 5
	if flags.get("ch3:prophecy_read", false):
		return 4
	if flags.get("ch2:trail_found", false):
		return 3
	if flags.get("game_beaten", false):
		return 2
	return 1


static func find(id: String) -> Dictionary:
	for q: Dictionary in QUESTS:
		if q.id == id:
			return q
	return {}


## The next thing to do in quest `id` ("" when it is done or unknown).
static func next_step(id: String) -> String:
	var q := find(id)
	if q.is_empty():
		return ""
	for st: Array in q.steps:
		if not check(String(st[1])):
			return String(st[0])
	return ""
