extends Node
## The hero's inventory and story flags for the current play session; SaveGame
## writes it to one of three files (to_dict / from_dict). Items sit on the two item buttons the way OoT puts them on
## the C buttons: X and Y here, with RB as OoT's C-Up (first-person view).
##
## Ammo follows OoT's inventory (z_inventory.c gUpgradeCapacities): the first
## quiver holds 30 arrows and the first wallet 99 rupees.
## Dungeon items are kept per dungeon, like gSaveContext.inventory.dungeonKeys
## and dungeonItems: small keys, the map, the compass and the boss key.

signal changed
## The equipped sword or shield changed (the hero swaps the meshes on his model).
signal gear_changed

const ITEMS := {
	"bow": {"name": "BOW", "ammo": "arrows"},
	"sun_arrows": {"name": "SUN ARROWS", "ammo": "arrows", "magic": 8},
	"frost_arrows": {"name": "FROST ARROWS", "ammo": "arrows", "magic": 4},
	"starfall_arrows": {"name": "STARFALL ARROWS", "ammo": "arrows", "magic": 6},
	"bombs": {"name": "BOMBS", "ammo": "bombs"},
	"puff_nuts": {"name": "PUFF NUTS", "ammo": "nuts"},
	"boomerang": {"name": "BOOMERANG"},
	"hookshot": {"name": "GRAPPLE HOOK"},
	"bloom_rod": {"name": "BLOOM ROD"},
	"iron_mallet": {"name": "IRON MALLET"},
	"grave_spade": {"name": "GRAVE SPADE"},
	"fishing_rod": {"name": "FISHING ROD"},
	"lantern": {"name": "LANTERN"},
	"looking_glass": {"name": "MIRA'S LOOKING GLASS", "magic": 1},
	"alans_harvest": {"name": "ALAN'S HARVEST", "magic": 12},
	"aphiels_gale": {"name": "APHIEL'S GALE", "magic": 12},
	"serielyes_ruin": {"name": "SERIELYE'S RUIN", "magic": 12},
	"sapphire_staff": {"name": "SAPPHIRE STAFF", "magic": 6},
	"ember_rod": {"name": "EMBER ROD", "magic": 2},
	"iron_flail": {"name": "IRON FLAIL"},
	"lothelyes_dream": {"name": "LOTHELYE'S DREAM", "magic": 4},
	"astral_seal": {"name": "ASTRAL SEAL"},
	"sugar_cube": {"name": "SUGAR CUBE"},
	# The trade chain's current thing (named by `trade`, TRADE_NAMES).
	"trade_item": {"name": "TRADE ITEM"},
	"bottle_0": {"name": "BOTTLE", "bottle": 0},
	"bottle_1": {"name": "BOTTLE", "bottle": 1},
	"bottle_2": {"name": "BOTTLE", "bottle": 2},
	"bottle_3": {"name": "BOTTLE", "bottle": 3},
}
## What a bottle can hold, and its name on the pause screen (OoT's bottle
## contents: an empty bottle catches a fairy; milk is two drinks; the red
## potion fills every heart; a fairy revives the hero when he falls).
const BOTTLE_NAMES := {"empty": "EMPTY BOTTLE", "fairy": "FAIRY", "milk": "MILK", "half_milk": "MILK (HALF)", "red_potion": "RED POTION", "fish": "FISH"}
const MAX_BOTTLES := 4
## The Lantern holds Lothelye's starlight (the Starlight Lantern, from the
## Sapphire Sanctum): it lights star braziers and puts out the Order's wards.
const STARLIGHT := "starlight"
## The goddesses' pieces of the Bun, one in each great tower: Alan's (the
## harvest) in the Southern Tower, Serielye's (destruction) in Ladhellin Tower
## and Aphiel's (the sky) in Skyreach Spire. All three draw the Bun Sword.
const BUN_PIECES := ["alan", "serielye", "aphiel"]
const BUN_PIECE_NAMES := {"alan": "ALAN", "serielye": "SERIELYE", "aphiel": "APHIEL"}
## SELECT ITEM grid order (7 x 4 since Beta 1.1.0; "" is a slot kept for an
## item still to come, see FUTURE_SLOTS and design/masterplan.txt), one row
## per section: ARMS (everything that takes ammo, and the Iron Flail), TOOLS (the Lantern among
## them), MAGIC (everything that costs magic: the Ember Rod, the Looking
## Glass, the goddesses' blessings, the Sapphire Staff) and the PACK (the bottles
## along the bottom row as in OoT, the Sugar Cube and the trade item).
const ITEM_COLS := 7
const ITEM_GRID := ["bow", "sun_arrows", "frost_arrows", "starfall_arrows", "bombs", "puff_nuts", "iron_flail",
	"boomerang", "hookshot", "bloom_rod", "iron_mallet", "grave_spade", "lantern", "fishing_rod",
	"ember_rod", "looking_glass", "alans_harvest", "aphiels_gale", "serielyes_ruin", "lothelyes_dream", "sapphire_staff",
	"bottle_0", "bottle_1", "bottle_2", "bottle_3", "sugar_cube", "trade_item", "astral_seal"]
## The empty slots and the items planned for them (the masterplan): left
## dark until their chapter brings them.
const FUTURE_SLOTS := {}
## The Hookshot's upgrade (from the burning Citadel): the same chain, twice as long.
const LONGSHOT := "longshot"
## The Bun Sword woken in the Temple of Bun.
const SWORD_AWAKE := "ch4:sword_awake"
## The bigger bags (gUpgradeCapacities: bombs 20/30/40, nuts 20/30/40).
const BOMB_BAG_SIZES := [20, 30, 40]
const NUT_POUCH_SIZES := [20, 30, 40]
## The trade chain (Beta 1.1.0), in order: Clover's cracked horseshoe of
## starmetal, Pink's sketch, Ottilie's library card, the armory ledger from
## Marigold, the pattern page from Mira; then Pink forges the Questlord's
## Shield. `trade` holds the current one ("" = none, or "done").
const TRADE_ORDER := ["horseshoe", "sketch", "card", "ledger", "page"]
const TRADE_NAMES := {"horseshoe": "LUCKY HORSESHOE", "sketch": "SMITH'S SKETCH", "card": "LIBRARY CARD",
	"ledger": "ARMORY LEDGER", "page": "PATTERN PAGE"}
## The section names down the left of the SELECT ITEM page, one per row.
const ITEM_SECTIONS := ["ARMS", "TOOLS", "MAGIC", "PACK"]
const QUIVER_SIZE := 30
const WALLET_SIZE := 99
## The wallets (OoT's 99 / 200 / 500): the Big Wallet from Clover, the Giant
## Wallet from Tansy's cup game.
const BIG_WALLET := 200
const GIANT_WALLET := 500
## The quivers (gUpgradeCapacities 30 / 40 / 50): Mira's and the range's.
const BIG_QUIVER := 40
const BIGGEST_QUIVER := 50
## The scales (OoT's Silver and Golden Scale): how deep a dive goes, in OoT
## units (D_80854784: 120 without one, 240, 360). Mira gives them for big fish.
const DIVE_DEPTHS := [120.0, 240.0, 360.0]
const SCALE_NAMES := ["", "SILVER SCALE", "GOLDEN SCALE"]
## Bracers (OoT's Goron's Bracelet line): the Bun Bracers lift heavy rocks;
## the Questlord's Gauntlets (the Barrow of Kings, Chapter V) also grip and
## drag the great stones (GreatStone).
const BRACER_NAMES := ["", "BUN BRACERS", "QUESTLORD'S GAUNTLETS"]
## The first bomb bag holds 20 (gUpgradeCapacities' bomb bag sizes 20/30/40).
const BOMB_BAG_SIZE := 20
## The first Puff Nut pouch holds 20 (OoT's Deku Nut capacities 20/30/40).
const NUT_POUCH_SIZE := 20
## OoT's magic meter: 48 units (0x30) for the single meter, 96 for the double.
const MAGIC_SINGLE := 48
## Starting health in half hearts: three hearts, as in OoT (22 by the end of
## the game: 12 heart containers and 28 Pieces of Heart).
const START_HEALTH := 6

## Items owned, by id.
var items := {}
## Item on each button ("" = empty).
var buttons := {"item_x": "", "item_y": ""}
var arrows := 0
var arrows_max := QUIVER_SIZE
var bombs := 0
var bombs_max := 0
var nuts := 0
var nuts_max := 0
## Magic (OoT's magic meter): none until the first magic item is found.
var magic := 0
var magic_max := 0
## Defense (OoT's double defense, from Lothelye's spring): 1 normal, 2 halves
## the damage of every blow and rims the hearts in white.
var defense := 1
## Aphiel's Gale's warp point (OoT's Farore's Wind): {"area", "pos", "yaw"} or {}.
var gale_point := {}
## Story and world flags (talked to someone, opened something...).
var flags := {}
var rupees := 0
var wallet := WALLET_SIZE
## Maximum health in half hearts (heart containers add 2).
var max_health := START_HEALTH
## Per dungeon id: {"keys": int, "map": bool, "compass": bool, "boss_key": bool}.
var dungeons := {}
## Swords and shields owned (Equipment ids) and the ones in use (OoT's
## EQUIPMENT subscreen: one of each is equipped at a time).
var swords := {}
var shields := {}
var sword := "squire"
var shield := "wooden"
var boots := {}
var boot := "leather"
## Tunics owned and the one worn (Equipment.TUNICS).
var tunics := {}
var tunic := "haven"
## Vanity outfits owned (Equipment.VANITY) and the one worn over the tunic ("" = none).
var vanity := {}
var vanity_on := ""
## Strength: 0 none, 1 the Bun Bracers (heavy rocks), 2 the Questlord's Gauntlets (great stones).
var bracers := 0
## Diving: 0 no scale, 1 the Silver Scale, 2 the Golden Scale.
var scale := 0
## The Bestiary: per kind of creature beaten, {"n": how many, "tier": the
## toughest rank met (EnemyScale)}.
var bestiary := {}
## Pieces of Heart toward the next heart (0-3), and all ever found.
var heart_pieces := 0
var heart_pieces_found := 0
## The heaviest fish landed at Mirror Lake, in pounds (0 = none yet).
var fish_record := 0
## The heaviest of each kind of fish landed anywhere (FishingSpot.SPECIES), in
## pounds: Mira pins them up on her wall.
var fish_records := {}
## What each bottle holds (one entry per bottle owned), see BOTTLE_NAMES.
var bottles: Array = []
## The trade chain's stage (TRADE_ORDER), "" before it, "done" after the shield.
var trade := ""
## The hour of the day, 0..24 (DayNight).
var day_time := 9.0
## The save file this game was loaded from or last saved to (-1 = none).
var slot := -1
## Time played, in seconds (Beta 1.6.1): it runs while the game is being
## played, not on the title or the pause screen.
var play_time := 0.0

## Saved by SaveGame (in this order); ints are restored from JSON's floats.
const SAVED_INTS := ["arrows", "arrows_max", "bombs", "bombs_max", "nuts", "nuts_max", "magic", "magic_max", "defense", "rupees", "wallet", "max_health", "heart_pieces", "heart_pieces_found", "fish_record", "bracers", "scale"]
const SAVED_DICTS := ["items", "buttons", "flags", "dungeons", "swords", "shields", "boots", "tunics", "vanity", "fish_records", "bestiary"]
const SAVED_STRINGS := ["sword", "shield", "boot", "tunic", "vanity_on", "trade"]


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and int(gm.get("state")) == 1:
		play_time += delta


## Time played as H:MM.
static func clock_text(seconds: float) -> String:
	var m := int(seconds) / 60
	return "%d:%02d" % [m / 60, m % 60]


## A fresh game: the hero starts with the bow on X and a full quiver.
func reset() -> void:
	items = {"bow": true}
	buttons = {"item_x": "bow", "item_y": ""}
	arrows = QUIVER_SIZE
	arrows_max = QUIVER_SIZE
	bombs = 0
	bombs_max = 0
	nuts = 0
	nuts_max = 0
	magic = 0
	magic_max = 0
	defense = 1
	gale_point = {}
	flags = {}
	rupees = 0
	wallet = WALLET_SIZE
	max_health = START_HEALTH
	dungeons = {}
	swords = {"squire": true}
	shields = {"wooden": true}
	sword = "squire"
	shield = "wooden"
	boots = {"leather": true}
	boot = "leather"
	tunics = {"haven": true}
	tunic = "haven"
	vanity = {}
	vanity_on = ""
	bracers = 0
	scale = 0
	fish_records = {}
	bestiary = {}
	heart_pieces = 0
	heart_pieces_found = 0
	fish_record = 0
	bottles = []
	trade = ""
	day_time = 9.0
	slot = -1
	play_time = 0.0
	changed.emit()


## Everything worth keeping, for SaveGame.
func to_dict() -> Dictionary:
	var d := {}
	for key in SAVED_INTS + SAVED_STRINGS:
		d[key] = get(key)
	for key in SAVED_DICTS:
		d[key] = (get(key) as Dictionary).duplicate(true)
	d["bottles"] = bottles.duplicate()
	d["day_time"] = day_time
	d["play_time"] = int(play_time)
	if not gale_point.is_empty():
		var gp: Vector3 = gale_point.pos
		d["gale"] = {"area": gale_point.area, "pos": [gp.x, gp.y, gp.z], "yaw": gale_point.yaw}
	return d


## Restores a game from to_dict()'s output (as read back from JSON).
func from_dict(d: Dictionary) -> void:
	reset()
	for key in SAVED_INTS:
		if d.has(key):
			set(key, int(d[key]))
	play_time = float(d.get("play_time", 0.0))
	for key in SAVED_STRINGS:
		if d.has(key):
			set(key, String(d[key]))
	for key in SAVED_DICTS:
		if d.get(key) is Dictionary:
			set(key, (d[key] as Dictionary).duplicate(true))
	if d.get("bottles") is Array:
		for b in d.bottles:
			if BOTTLE_NAMES.has(String(b)) and bottles.size() < MAX_BOTTLES:
				bottles.append(String(b))
	day_time = fposmod(float(d.get("day_time", 9.0)), 24.0)
	if d.get("gale") is Dictionary and (d.gale.get("pos") is Array) and d.gale.pos.size() == 3:
		var gp: Array = d.gale.pos
		gale_point = {"area": String(d.gale.get("area", "")), "pos": Vector3(float(gp[0]), float(gp[1]), float(gp[2])), "yaw": float(d.gale.get("yaw", 0.0))}
	# JSON numbers come back as floats: the dungeon key counts are ints.
	for id in dungeons:
		var dd: Dictionary = dungeons[id]
		dd["keys"] = int(dd.get("keys", 0))
	_migrate_southern_tower()
	boots["leather"] = true
	if not has_boots(boot):
		boot = "leather"
	tunics["haven"] = true
	if not has_tunic(tunic):
		tunic = "haven"
	if vanity_on != "" and not vanity.get(vanity_on, false):
		vanity_on = ""
	bracers = clampi(bracers, 0, BRACER_NAMES.size() - 1)
	scale = clampi(scale, 0, DIVE_DEPTHS.size() - 1)
	for k in fish_records.keys():
		fish_records[k] = int(fish_records[k])
	gear_changed.emit()
	changed.emit()


## Saves from before the goddess towers. The Southern Tower was rebuilt
## storeys high, and its old rooms were r0-r5 (Corvax's roof r5). A tower
## already beaten counts as beaten in the new one, every door open and chest
## emptied, and Corvax's fall gives Alan's bun piece. The chests and locked
## doors kept their flag names, so a tower left halfway keeps what was found.
func _migrate_southern_tower() -> void:
	const D := "southern_tower:"
	if flag(D + "r5_clear") and not flag(D + "boss_clear"):
		for f in ["boss_clear", "mill_running", "loom_clear", "den_clear", "mill_clear", "door_key1", "door_key2", "door_key3",
				"boss_door", "chest_key1", "chest_key2", "chest_key3", "chest_map", "chest_compass", "chest_hookshot", "chest_boss_key", "chest_cistern"]:
			flags[D + f] = true
		flags["bun_piece:alan"] = true
		dungeon("southern_tower").keys = 0
	elif flag(D + "chest_hookshot"):
		# The Rust Knight already fell in the old Mill Room.
		flags[D + "mill_clear"] = true


func has_bun_piece(goddess: String) -> bool:
	return flag("bun_piece:" + goddess)


func bun_piece_count() -> int:
	return BUN_PIECES.filter(func(g: String) -> bool: return has_bun_piece(g)).size()


func has_item(id: String) -> bool:
	if ITEMS.has(id) and ITEMS[id].has("bottle"):
		return int(ITEMS[id].bottle) < bottles.size()
	return items.get(id, false)


## The name of an item on the pause screen (a bottle by what it holds).
func item_name(id: String) -> String:
	if ITEMS.has(id) and ITEMS[id].has("bottle"):
		return BOTTLE_NAMES.get(bottle(int(ITEMS[id].bottle)), "BOTTLE")
	if id == "lantern" and flag(STARLIGHT):
		return "STARLIGHT LANTERN"
	if id == "hookshot" and flag(LONGSHOT):
		return "LONG GRAPPLE"
	if id == "trade_item":
		return TRADE_NAMES.get(trade, "TRADE ITEM")
	return ITEMS[id].name if ITEMS.has(id) else ""


## The icon an item shows (a bottle's shows what is in it).
func icon_id(id: String) -> String:
	if ITEMS.has(id) and ITEMS[id].has("bottle"):
		return "bottle_" + bottle(int(ITEMS[id].bottle))
	if id == "lantern" and flag(STARLIGHT):
		return "starlight_lantern"
	if id == "hookshot" and flag(LONGSHOT):
		return "longshot"
	if id == "trade_item" and TRADE_NAMES.has(trade):
		return "trade_" + trade
	return id


## Moves the trade chain on to `stage` (TRADE_ORDER), or ends it ("done").
func set_trade(stage: String) -> void:
	trade = stage
	if TRADE_NAMES.has(stage):
		items["trade_item"] = true
	else:
		items.erase("trade_item")
		for b in ["item_x", "item_y"]:
			if buttons.get(b, "") == "trade_item":
				buttons[b] = ""
	changed.emit()


## What bottle `i` holds ("" = no such bottle).
func bottle(i: int) -> String:
	return String(bottles[i]) if i >= 0 and i < bottles.size() else ""


func give_bottle(content := "empty") -> void:
	if bottles.size() < MAX_BOTTLES:
		bottles.append(content)
		changed.emit()


func set_bottle(i: int, content: String) -> void:
	if i >= 0 and i < bottles.size():
		bottles[i] = content
		changed.emit()


## Empties the first bottle holding `content`; false when none does.
func take_from_bottle(content: String) -> bool:
	var i := bottles.find(content)
	if i < 0:
		return false
	bottles[i] = "empty"
	changed.emit()
	return true


func item_on(button: String) -> String:
	return buttons.get(button, "")


## OoT lets an item sit on only one C button: assigning it elsewhere moves it.
func assign(button: String, id: String) -> void:
	for b: String in buttons:
		if buttons[b] == id:
			buttons[b] = ""
	buttons[button] = id
	changed.emit()


func ammo_of(id: String) -> int:
	match ITEMS.get(id, {}).get("ammo", ""):
		"arrows":
			return arrows
		"bombs":
			return bombs
		"nuts":
			return nuts
	return -1


## How much of an item's ammo can be carried (-1 = it takes none).
func ammo_max_of(id: String) -> int:
	match ITEMS.get(id, {}).get("ammo", ""):
		"arrows":
			return arrows_max
		"bombs":
			return bombs_max
		"nuts":
			return nuts_max
	return -1


## The bomb bag: bombs on a free button and a full bag.
func give_bomb_bag() -> void:
	bombs_max = maxi(bombs_max, BOMB_BAG_SIZE)
	bombs = bombs_max
	give_item("bombs")


## The next bomb bag up (30, then 40), filled.
func upgrade_bomb_bag() -> void:
	for size: int in BOMB_BAG_SIZES:
		if size > bombs_max:
			bombs_max = size
			break
	bombs = bombs_max
	if not has_item("bombs"):
		give_item("bombs")
	changed.emit()


## The next Puff Nut pouch up (30, then 40), filled.
func upgrade_nut_pouch() -> void:
	for size: int in NUT_POUCH_SIZES:
		if size > nuts_max:
			nuts_max = size
			break
	nuts = nuts_max
	if not has_item("puff_nuts"):
		give_item("puff_nuts")
	changed.emit()


func add_bombs(n: int) -> int:
	var before := bombs
	bombs = clampi(bombs + n, 0, bombs_max)
	changed.emit()
	return bombs - before


func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	changed.emit()
	return true


## The Puff Nut pouch: nuts on a free button and `n` nuts in it.
func give_nut_pouch(n := 10) -> void:
	nuts_max = maxi(nuts_max, NUT_POUCH_SIZE)
	nuts = clampi(nuts + n, 0, nuts_max)
	give_item("puff_nuts")


func add_nuts(n: int) -> int:
	var before := nuts
	nuts = clampi(nuts + n, 0, nuts_max)
	changed.emit()
	return nuts - before


func use_nut() -> bool:
	if nuts <= 0:
		return false
	nuts -= 1
	changed.emit()
	return true


# --- Magic ----------------------------------------------------------------------

## What using an item costs in magic (0 = nothing).
static func magic_cost(id: String) -> int:
	return int(ITEMS.get(id, {}).get("magic", 0))


## The magic meter appears full (the first magic item brings it, see GetItem).
func give_magic_meter(units := MAGIC_SINGLE) -> void:
	magic_max = maxi(magic_max, units)
	magic = magic_max
	changed.emit()


## Double defense: blows take half as much (OoT halves the damage; a blow
## always takes at least half a heart).
func give_double_defense() -> void:
	defense = 2
	changed.emit()


func defended(damage: int) -> int:
	if defense <= 1 or damage <= 0:
		return damage
	return maxi(1, (damage + 1) / 2)


## Spends `n` magic; false (and nothing spent) when there is too little.
func use_magic(n: int) -> bool:
	if n <= 0:
		return true
	if magic < n:
		return false
	magic -= n
	changed.emit()
	return true


func add_magic(n: int) -> int:
	var before := magic
	magic = clampi(magic + n, 0, magic_max)
	changed.emit()
	return magic - before


func add_arrows(n: int) -> int:
	var before := arrows
	arrows = clampi(arrows + n, 0, arrows_max)
	changed.emit()
	return arrows - before


func use_arrow() -> bool:
	if arrows <= 0:
		return false
	arrows -= 1
	changed.emit()
	return true


## A story or world flag. "time:night" and "time:day" read the clock
## (DayNight) instead, so a chest can wait for nightfall.
func flag(f: String) -> bool:
	if f.begins_with("time:"):
		return DayNight.flag(f)
	return flags.get(f, false)


func set_flag(f: String, value := true) -> void:
	flags[f] = value
	changed.emit()


## Rupees in or out, clamped to the wallet. Returns false if there were too few to pay.
func add_rupees(n: int) -> bool:
	if rupees + n < 0:
		return false
	rupees = clampi(rupees + n, 0, wallet)
	changed.emit()
	return true


func give_item(id: String) -> void:
	items[id] = true
	# A new item goes on a free button, as OoT puts the first C item on C-Left.
	if not buttons.values().has(id):
		for b: String in ["item_x", "item_y"]:
			if buttons[b] == "":
				buttons[b] = id
				break
	changed.emit()


func heart_container() -> void:
	max_health += 2
	changed.emit()


## One more Piece of Heart; returns true when it completes a heart
## (OoT: four pieces raise healthCapacity by 0x10 and refill it).
func add_heart_piece() -> bool:
	heart_pieces_found += 1
	heart_pieces += 1
	if heart_pieces >= 4:
		heart_pieces = 0
		heart_container()
		return true
	changed.emit()
	return false


# --- Dungeon items ------------------------------------------------------------

func dungeon(id: String) -> Dictionary:
	if not dungeons.has(id):
		dungeons[id] = {"keys": 0, "map": false, "compass": false, "boss_key": false}
	return dungeons[id]


func keys(id: String) -> int:
	return dungeon(id).keys if id != "" else 0


func add_key(id: String) -> void:
	if id == "":
		return
	dungeon(id).keys += 1
	changed.emit()


func use_key(id: String) -> bool:
	if keys(id) <= 0:
		return false
	dungeon(id).keys -= 1
	changed.emit()
	return true


func has_dungeon_item(id: String, item: String) -> bool:
	return id != "" and dungeon(id).get(item, false)


func give_dungeon_item(id: String, item: String) -> void:
	dungeon(id)[item] = true
	changed.emit()


# --- Swords and shields ---------------------------------------------------------

func has_sword(id: String) -> bool:
	return swords.get(id, false)


func has_shield(id: String) -> bool:
	return shields.get(id, false)


## A new sword is equipped at once, as OoT does when Link draws a new blade.
func give_sword(id: String) -> void:
	swords[id] = true
	equip_sword(id)


func give_shield(id: String) -> void:
	shields[id] = true
	equip_shield(id)


func equip_sword(id: String) -> void:
	if not has_sword(id):
		return
	sword = id
	gear_changed.emit()
	changed.emit()


func equip_shield(id: String) -> void:
	if not has_shield(id):
		return
	shield = id
	gear_changed.emit()
	changed.emit()


func has_boots(id: String) -> bool:
	return boots.get(id, false)


## New boots are put on at once.
func give_boots(id: String) -> void:
	boots[id] = true
	equip_boots(id)


func equip_boots(id: String) -> void:
	if not has_boots(id):
		return
	boot = id
	gear_changed.emit()
	changed.emit()


## Wearing the Wind Boots.
func wind_boots() -> bool:
	return Equipment.boots(boot).get("wind", false)


## Wearing the Anchor Boots.
func anchor_boots() -> bool:
	return Equipment.boots(boot).get("anchor", false)


# --- Tunics and the vanity outfit -------------------------------------------------

func has_tunic(id: String) -> bool:
	return tunics.get(id, false)


## A new tunic is put on at once.
func give_tunic(id: String) -> void:
	tunics[id] = true
	equip_tunic(id)


func equip_tunic(id: String) -> void:
	if not has_tunic(id):
		return
	tunic = id
	gear_changed.emit()
	changed.emit()


## Breathing under water (the Tide Tunic).
func breathes_water() -> bool:
	return Equipment.tunic(tunic).get("breathe", false)


## Proof against the cold (the Frost Mantle).
func cold_proof() -> bool:
	return Equipment.tunic(tunic).get("warm", false)


## How far foes notice the hero, as a share of their usual range (the Shade Cloak).
func stealth() -> float:
	return float(Equipment.tunic(tunic).get("stealth", 1.0))


func has_vanity(id: String) -> bool:
	return vanity.get(id, false)


## A gift of clothes is put on at once.
func give_vanity(id: String) -> void:
	vanity[id] = true
	vanity_on = id
	gear_changed.emit()
	changed.emit()


## Puts the outfit on, or takes it off if it is on.
func toggle_vanity(id: String) -> void:
	if not has_vanity(id):
		return
	vanity_on = "" if vanity_on == id else id
	gear_changed.emit()
	changed.emit()


# --- Strength and diving -------------------------------------------------------------

## Strong enough for the heavy rocks (the Bun Bracers).
func can_lift_heavy() -> bool:
	return bracers >= 1


## Strong enough to drag the great stones (the Questlord's Gauntlets).
func can_pull_great() -> bool:
	return bracers >= 2


func give_bracers(level := 1) -> void:
	bracers = maxi(bracers, level)
	changed.emit()


func give_scale(level: int) -> void:
	scale = maxi(scale, level)
	changed.emit()


## How deep a dive goes, in OoT units.
func dive_depth() -> float:
	return DIVE_DEPTHS[clampi(scale, 0, DIVE_DEPTHS.size() - 1)]


## Records a landed fish of `species`; true when it beats that kind's record.
func record_fish(species: String, pounds: int) -> bool:
	var best := int(fish_records.get(species, 0))
	if pounds <= best:
		return false
	fish_records[species] = pounds
	changed.emit()
	return true


## A creature of `kind` beaten at `tier` (the Bestiary).
func note_kill(kind: String, tier: int) -> void:
	if kind == "":
		return
	var e: Dictionary = bestiary.get(kind, {"n": 0, "tier": 0})
	e["n"] = int(e.get("n", 0)) + 1
	e["tier"] = maxi(int(e.get("tier", 0)), tier)
	bestiary[kind] = e


## The Bun Sword has woken (the Temple of Bun).
func sword_awake() -> bool:
	return flag(SWORD_AWAKE)


## The next sword or shield tier not owned yet ("" when all are).
func next_sword() -> String:
	for id: String in Equipment.SWORD_ORDER:
		if not has_sword(id):
			return id
	return ""


func next_shield() -> String:
	for id: String in Equipment.SHIELD_ORDER:
		if not has_shield(id):
			return id
	return ""
