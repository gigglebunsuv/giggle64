class_name GetItem
extends RefCounted
## Receiving a treasure (from a chest, or the boss's heart container), after
## OoT's get-item sequence (Player_SetupGetItem / func_8083E5A8): the hero
## turns toward the camera and holds the item up in both hands while a fanfare
## plays and a text box names it. The item takes effect at once.

const ITEMS := {
	"boomerang": {"mesh": "boomerang_mesh", "fanfare": "fanfare_big", "scale": 1.6, "text": [
		"You got the *Boomerang*!",
		"Put it on X or Y on the *Select Item* screen, then press that button to throw it.",
		"It stuns foes, flips switches and fetches things from afar!",
	]},
	"small_key": {"mesh": "small_key_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": [
		"You found a *Small Key*!\nIt opens one locked door in this dungeon.",
	]},
	"map": {"mesh": "map_mesh", "fanfare": "fanfare_item", "scale": 1.4, "text": [
		"You found the *Dungeon Map*!\nPress START and turn to the map screen to see the rooms of this place.",
	]},
	"compass": {"mesh": "compass_mesh", "fanfare": "fanfare_item", "scale": 1.4, "text": [
		"You found the *Compass*!\nNow the map shows the chests, and the lair of this place's master.",
	]},
	"boss_key": {"mesh": "boss_key_mesh", "fanfare": "fanfare_big", "scale": 1.3, "text": [
		"You got the *Boss Key*!\nNow you can open the great door to the lair of this shrine's master.",
	]},
	"heart_container": {"mesh": "heart_container_mesh", "fanfare": "heart_container", "scale": 1.0, "text": [
		"You got a *Heart Vessel*!\nYour life energy grows by one heart and is filled to the brim!",
	]},
	"bun_piece_alan": {"mesh": "bun_piece_alan_mesh", "fanfare": "fanfare_big", "scale": 2.2, "rot": Vector3(70, 0, 0), "text": [
		"You got *Alan's Bun Piece*!",
		"A piece of the goddesses' *Bun*, warm as a field at harvest. The Goddess of the Harvest left it here in her keeping.",
		"Two more pieces are hidden in the great towers of Haven. With all three, the *Bun Sword* can be drawn.",
	]},
	"bun_piece_serielye": {"mesh": "bun_piece_serielye_mesh", "fanfare": "fanfare_big", "scale": 2.2, "rot": Vector3(70, 0, 0), "text": [
		"You got *Serielye's Bun Piece*!",
		"A piece of the goddesses' *Bun*, hot to the touch. The Goddess of Destruction hid it deep in the desert's tower.",
	]},
	"bun_piece_aphiel": {"mesh": "bun_piece_aphiel_mesh", "fanfare": "fanfare_big", "scale": 2.2, "rot": Vector3(70, 0, 0), "text": [
		"You got *Aphiel's Bun Piece*!",
		"A piece of the goddesses' *Bun*, light as a cloud. The Lady of the Sky kept it at the top of the world.",
	]},
	"starlight_lantern": {"mesh": "starlight_lantern_mesh", "fanfare": "fanfare_big", "scale": 2.6, "text": [
		"You got the *Starlight Lantern*!",
		"Lothelye's starlight burns in your lantern now: a cold blue flame the *Gauntlet of Fire* cannot command.",
		"Sapphire wards gutter out before it, star braziers wake to it, and what hides in the dark is laid bare.",
	]},
	"dark_prophecy": {"mesh": "dark_prophecy_mesh", "fanfare": "fanfare_big", "scale": 1.8, "rot": Vector3(20, 0, 0), "text": [
		"You got a copy of *Bunsriel's Dark Prophecy*!",
		"A thin black book in a script too old to read. The ink moves when you aren't looking.",
		"Somebody in Haven might be able to read it. *Ottilie*, at the library?",
	]},
	# Chapter IV, "The Fall of Bunsriel".
	"grave_spade": {"mesh": "grave_spade_mesh", "fanfare": "fanfare_big", "scale": 1.3, "rot": Vector3(90, 0, 20), "offset": Vector3(0, -0.4, 0), "text": [
		"You got the *Grave Spade*!",
		"Wren's own spade, worn smooth by forty years of Batela graves. Put it on X or Y and press the button to dig.",
		"Dig where the earth is soft and dark. Who knows what's buried there?",
	]},
	"sapphire_staff": {"mesh": "sapphire_staff_mesh", "fanfare": "fanfare_big", "scale": 1.2, "rot": Vector3(90, 0, 30), "offset": Vector3(0, -0.4, 0), "text": [
		"You got the *Sapphire Staff*!",
		"The battle-mage's staff, its sapphire still humming. Use it to conjure a great *sapphire block* in front of you.",
		"The block is heavy enough to hold down a switch, solid enough to stand on, and it stops fire cold.",
		"It takes *magic*. Use the staff again to dispel it.",
	]},
	"starfall_arrows": {"mesh": "starfall_arrow_mesh", "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(0, 90, -50), "text": [
		"You got the *Starfall Arrows*!",
		"Arrows tipped with Lothelye's own starlight. Put them on X or Y and fire them like the bow.",
		"Each one takes *magic*.",
		"They pierce the Order's wards, wake star eyes and braziers, and burn away flame that no water can quench.",
	]},
	"astral_seal": {"mesh": "astral_seal_mesh", "fanfare": "fanfare_big", "scale": 2.0, "rot": Vector3(15, 0, 0), "text": [
		"You got the *Astral Seal*!",
		"A crystal of the Astral Dimension, the prison Lothelye made long ago. Cold as the space between the stars.",
		"Lothelye said it will know its moment. When Firebuns falls, it will hold him.",
	]},
	"iron_flail": {"mesh": "iron_flail_mesh", "fanfare": "fanfare_big", "scale": 1.2, "rot": Vector3(80, 0, 20), "offset": Vector3(0, -0.3, 0), "text": [
		"You got the *Iron Flail*!",
		"The Jailer's ball and chain: a spiked iron ball on a chain as long as a room.",
		"Put it on X or Y and press that button to hurl the ball straight ahead. It swings back on its chain.",
		"It smashes barred gates and cracked stone, rings bells far off, and knocks an undead knight's shield aside!",
	]},
	"lothelyes_dream": {"mesh": "lothelyes_dream_mesh", "fanfare": "fanfare_big", "scale": 2.2, "rot": Vector3(0, 0, 0), "text": [
		"You got *Lothelye's Dream*!",
		"The last of the goddess's gifts: a dream of the astral way, held in a sliver of moonlight.",
		"Put it on X or Y and press that button to dream awake.",
		"While you dream, paths of *dream-light* hold you up, and the veils of the waking world fall away.",
		"Dreaming draws on your *magic* all the while. Use it again to wake.",
	]},
	"ember_rod": {"mesh": "ember_rod_mesh", "fanfare": "fanfare_big", "scale": 1.3, "rot": Vector3(90, 0, 25), "offset": Vector3(0, -0.4, 0), "text": [
		"You got the *Ember Rod*!",
		"A rod of black iron with a coal of Cinderhold's fire caught in its head.",
		"Put it on X or Y and press that button to throw a fireball!",
		"It lights torches, burns thorns and webs, and melts rime-ice.",
		"The undead fear it. Each fireball takes a little magic.",
	]},
	"questlord_gauntlets": {"mesh": "questlord_gauntlets_mesh", "fanfare": "fanfare_big", "scale": 1.7, "rot": Vector3(20, 0, 0), "text": [
		"You got the *Questlord's Gauntlets*!",
		"Gauntlets of old Questlord steel, worn by Haven's first knights.",
		"With them, your grip is as strong as iron.",
		"Face a *great stone* and press A to take hold of it, then drag it away with all your strength!",
	]},
	"longshot": {"mesh": "longshot_mesh", "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(0, 90, 0), "text": [
		"You got the *Long Grapple*!",
		"Your Grapple Hook's chain is twice as long now! It reaches targets the Grapple Hook never could.",
	]},
	"bomb_bag_up": {"mesh": "bomb_bag_mesh", "fanfare": "fanfare_big", "scale": 1.4, "text": [
		"You got a *Bigger Bomb Bag*!
Now you can carry more Bombs!",
	]},
	"nut_pouch_up": {"mesh": "puff_nut_mesh", "fanfare": "fanfare_big", "scale": 2.0, "text": [
		"You got a *Bigger Puff Nut Pouch*!
Now you can carry more Puff Nuts!",
	]},
	"rupee_purple": {"mesh": "rupee_purple_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": [
		"You got a *Purple Coin*!
That's *fifty* coins!",
	]},
	"rupee_gold": {"mesh": "rupee_gold_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": [
		"You got a *Gold Coin*!
That's *one hundred* coins!",
	]},
	"shield_polish": {"mesh": "shield_wooden_flat_mesh", "fanfare": "fanfare_big", "scale": 1.1, "rot": Vector3(-90, 0, 0), "text": [
		"Your shields have been *gilded*!",
		"Pink worked the Haven Guard's gold leaf into the rim of every shield you own. They shine like a captain's.",
	]},
	# The trade chain (TradeLines): each thing replaces the last in the PACK.
	"trade_horseshoe": {"mesh": "trade_horseshoe_mesh", "fanfare": "fanfare_item", "scale": 2.0, "text": [
		"You got Clover's *Lucky Horseshoe*!",
		"Cracked right through, and strangely heavy. It glitters like a night sky. A smith might make something of it.",
	]},
	"trade_sketch": {"mesh": "trade_sketch_mesh", "fanfare": "fanfare_item", "scale": 2.0, "text": [
		"You got *Pink's Sketch*!",
		"A charcoal shield, covered in question marks. Show it to *Ottilie*: she keeps the old armory ledgers.",
	]},
	"trade_card": {"mesh": "trade_card_mesh", "fanfare": "fanfare_item", "scale": 2.0, "text": [
		"You got Ottilie's *Library Card*!",
		"Show it to *Marigold* at her shop. She borrowed the armory ledger, to press flowers in.",
	]},
	"trade_ledger": {"mesh": "trade_ledger_mesh", "fanfare": "fanfare_item", "scale": 1.8, "text": [
		"You got the *Armory Ledger*!",
		"One page is missing: the one with the shield pattern. Marigold wrapped a fish in it, for *Mira*...",
	]},
	"trade_page": {"mesh": "trade_page_mesh", "fanfare": "fanfare_item", "scale": 2.0, "text": [
		"You got the *Pattern Page*!",
		"The Questlord's Shield, drawn in faded ink. It smells faintly of fish. Take it to *Pink*!",
	]},
	"rupee_red": {"mesh": "rupee_red_mesh", "fanfare": "fanfare_item", "scale": 1.8, "text": ["You got a *Red Coin*!\nThat's twenty coins!"]},
	"rupee_blue": {"mesh": "rupee_blue_mesh", "fanfare": "fanfare_item", "scale": 1.8, "text": ["You got a *Blue Coin*!\nThat's five coins!"]},
	"arrows_10": {"mesh": "arrow_bundle_mesh", "fanfare": "fanfare_item", "scale": 1.4, "text": ["You got *10 Arrows*!"]},
	"big_quiver": {"mesh": "quiver_mesh", "fanfare": "fanfare_item", "scale": 1.2, "text": [
		"You got the *Big Quiver*!\nNow you can carry up to *40* arrows!",
	]},
	"big_wallet": {"mesh": "big_wallet_mesh", "fanfare": "fanfare_big", "scale": 1.4, "text": [
		"You got the *Big Wallet*!\nNow you can carry up to *200* Coins!",
	]},
	"sugar_cube": {"mesh": "sugar_cube_mesh", "fanfare": "fanfare_big", "scale": 1.8, "text": [
		"You got a *Sugar Cube*!",
		"Put it on X or Y and use it out on the open fields: your horse will come running for it!",
	]},
	"bomb_bag": {"mesh": "bomb_bag_mesh", "fanfare": "fanfare_big", "scale": 1.5, "text": [
		"You got a *Bomb Bag*! It's full of *20 Bombs*.",
		"Put Bombs on X or Y. Press the button to pull one out, lit, then press again (or A or B) to throw it.",
		"Stand still and press A to set it down instead.",
		"Blast cracked walls and boulders, and keep well clear!",
	]},
	"bombs_10": {"mesh": "bomb_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": ["You got *10 Bombs*!"]},
	"bloom_rod": {"mesh": "bloom_rod_mesh", "fanfare": "fanfare_big", "scale": 1.5, "rot": Vector3(0, 0, 30), "text": [
		"You got the *Bloom Rod*!",
		"A rod of living bogwood. Put it on X or Y, hold the button to aim and let go to fling a seed.",
		"On firm ground the seed bursts into a sturdy *bloom-pod*: climb it, weigh down switches, or *grapple* onto it!",
		"On water or sludge it opens into a *lily pad* you can stand on. Only one bloom grows at a time.",
	]},
	"bottle": {"mesh": "bottle_empty_mesh", "fanfare": "fanfare_big", "scale": 1.7, "text": [
		"You got an *Empty Bottle*!",
		"Put it on X or Y and swing it at a *fairy* to catch her. Fairies come out over the flowers after dark.",
		"A fairy in a bottle heals you when you let her out, and if you fall in battle she brings you back!",
	]},
	"bottle_milk": {"mesh": "bottle_milk_mesh", "fanfare": "fanfare_big", "scale": 1.7, "text": [
		"You got a *Bottle of Milk*!",
		"Fresh from the ranch! Put it on X or Y and drink it to restore *five hearts*. There are two drinks in it.",
		"Once it's empty, the bottle is yours to keep.",
	]},
	"sun_arrows": {"mesh": "sun_arrow_mesh", "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(90, 0, 0), "text": [
		"You got the *Sun Arrows*!",
		"Put them on X or Y and fire them from your bow. Each one takes a little *magic* as it flies.",
		"A Sun Arrow strikes hard and bursts into the goddesses' light. It wakes *sun switches* from afar.",
		"And nothing that hides in shadow can hide from it!",
	]},
	"frost_arrows": {"mesh": "frost_arrow_mesh", "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(90, 0, 0), "text": [
		"You got the *Frost Arrows*!",
		"Put them on X or Y and fire them from your bow. Each one takes a little *magic*.",
		"They freeze foes solid, and the next blow shatters the ice for double damage.",
		"Shoot one into open water and it freezes a *floe* you can stand on!",
	]},
	"puff_nuts": {"mesh": "puff_nut_mesh", "fanfare": "fanfare_item", "scale": 2.4, "text": [
		"You got *Puff Nuts*! The pouch holds up to *20*.",
		"Put them on X or Y and press the button to throw one.",
		"It bursts in a flash of spores that leaves every foe nearby *dazed*.",
	]},
	"puff_nuts_10": {"mesh": "puff_nut_mesh", "fanfare": "fanfare_item", "scale": 2.4, "text": ["You got *10 Puff Nuts*!"]},
	"iron_mallet": {"mesh": "iron_mallet_mesh", "fanfare": "fanfare_big", "scale": 1.3, "rot": Vector3(90, 0, 20), "offset": Vector3(0, -0.4, 0), "text": [
		"You got the *Iron Mallet*!",
		"Put it on X or Y and press the button to swing it overhead and bring it down with all your strength.",
		"It smashes brittle crust and boulders, drives foes into the ground, and the ground shakes where it lands!",
	]},
	"fishing_rod": {"mesh": "fishing_rod_mesh", "fanfare": "fanfare_big", "scale": 0.8, "rot": Vector3(90, 0, 15), "offset": Vector3(0, -0.5, 0), "text": [
		"You got a *Fishing Rod* of your own!",
		"Put it on X or Y, face open water from the shore and press the button to fish. Any pond, river or lake will do!",
	]},
	"lantern": {"mesh": "lantern_mesh", "fanfare": "fanfare_big", "scale": 2.0, "offset": Vector3(0, 0.3, 0), "text": [
		"You got the *Lantern*!",
		"Put it on X or Y and press the button to light it or put it out.",
		"It hangs at your belt and lights the dark round you.",
		"Use it right next to an unlit *torch* to light the torch!",
	]},
	"looking_glass": {"mesh": "looking_glass_mesh", "fanfare": "fanfare_big", "scale": 1.6, "text": [
		"You got *Mira's Looking Glass*!",
		"Put it on X or Y and press the button to look through it. It shows what is hidden, and what isn't really there.",
		"Looking through it slowly drains your *magic*. Press the button again to lower it.",
	]},
	"alans_harvest": {"mesh": "alans_harvest_mesh", "fanfare": "fanfare_big", "scale": 2.4, "text": [
		"You got *Alan's Harvest*!",
		"A blessing of Alan, Goddess of the Harvest. Put it on X or Y and use it to call up a ring of green light.",
		"It heals *three hearts*, and the plants all round you burst into bloom and give up what they hold.",
		"Each use takes *magic*.",
	]},
	"aphiels_gale": {"mesh": "aphiels_gale_mesh", "fanfare": "fanfare_big", "scale": 2.4, "text": [
		"You got *Aphiel's Gale*!",
		"A blessing of Aphiel, Lady of the Sky. Use it once to set a *Gale Point* where you stand.",
		"Use it again in the same place to be carried back to the point on the wind. Each use takes *magic*.",
	]},
	"serielyes_ruin": {"mesh": "serielyes_ruin_mesh", "fanfare": "fanfare_big", "scale": 2.4, "text": [
		"You got *Serielye's Ruin*!",
		"A blessing of Serielye, Goddess of Destruction. Use it to loose a blast of force all round you.",
		"It hurls foes back and breaks brittle things. It takes *magic*.",
	]},
	"double_magic": {"mesh": "magic_large_mesh", "fanfare": "heart_container", "scale": 2.6, "text": [
		"Lothelye's light pours into you... Your *Magic Meter* has doubled!",
		"Now you can use the goddesses' blessings and your magic arrows twice as long before it runs dry.",
	]},
	"double_defense": {"mesh": "heart_container_mesh", "fanfare": "heart_container", "scale": 1.2, "text": [
		"Lothelye's light shines round your heart... Your *defense* has doubled!",
		"Now every blow you take does only half the damage. Your hearts are rimmed in white to show it.",
	]},
	"bun_bracers": {"mesh": "bun_bracers_mesh", "fanfare": "fanfare_big", "scale": 1.8, "rot": Vector3(20, 0, 0), "text": [
		"You got the *Bun Bracers*!",
		"Aladriel's old bracers, stamped with a golden bun. They make your arms as strong as hers!",
		"Now you can lift *heavy rocks* that wouldn't budge before. Stand in front of one and press *A*.",
	]},
	"silver_scale": {"mesh": "silver_scale_mesh", "fanfare": "fanfare_big", "scale": 2.2, "text": [
		"You got the *Silver Scale*!",
		"A scale from the lord of Mirror Lake. Now you can dive *twice as deep*! Press *A* while swimming to dive.",
	]},
	"golden_scale": {"mesh": "golden_scale_mesh", "fanfare": "fanfare_big", "scale": 2.2, "text": [
		"You got the *Golden Scale*!",
		"It shines like the lake at sunset. Now you can dive *deeper still*, to the very bottom of any water!",
	]},
	"giant_wallet": {"mesh": "giant_wallet_mesh", "fanfare": "fanfare_big", "scale": 1.4, "text": [
		"You got the *Giant Wallet*!\nNow you can carry up to *500* Coins!",
	]},
	"biggest_quiver": {"mesh": "quiver_mesh", "fanfare": "fanfare_big", "scale": 1.3, "text": [
		"You got the *Biggest Quiver*!\nNow you can carry up to *50* arrows!",
	]},
	"hookshot": {"mesh": "hookshot_mesh", "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(0, 90, 0), "text": [
		"You got the *Grapple Hook*!",
		"It's a spring-loaded chain that you can shoot. Put it on X or Y, hold the button to aim, and let go to fire!",
		"It bites into wooden targets and pulls you to them. It can stun foes and fetch things from afar, too!",
	]},
}


## The presentation of `item`: swords ("sword_<id>") and shields
## ("shield_<id>") come from Equipment; the sword is held up point first, the
## shield face to the camera.
static func definition(item: String) -> Dictionary:
	if item.begins_with("sword_"):
		var sw := Equipment.sword(item.trim_prefix("sword_"))
		var text: Array = ["You got the *%s*!" % sw.title, sw.text,
			"Change swords on the *Equipment* screen (press START and turn the page)."]
		if sw.get("two_handed", false):
			text.insert(2, "It hits far harder than any other blade, but it swings slower, and there's no shield to hide behind. No *Shield Bash* while it's out, either!")
		return {"mesh": "%s_mesh" % item, "fanfare": "fanfare_big", "scale": 0.85 if sw.get("two_handed", false) else 1.0,
			"rot": Vector3(90, 0, 0), "offset": Vector3(0, -0.35, 0), "text": text}
	if item.begins_with("boots_"):
		var bt := Equipment.boots(item.trim_prefix("boots_"))
		return {"mesh": "%s_mesh" % item, "fanfare": "fanfare_big", "scale": 1.6, "rot": Vector3(10, 30, 0),
			"text": ["You got the *%s*!" % bt.title, bt.text,
				"Put them on and take them off on the *Equipment* screen (press START and turn the page)."]}
	if item.begins_with("tunic_"):
		var tu := Equipment.tunic(item.trim_prefix("tunic_"))
		return {"mesh": "%s_mesh" % item, "fanfare": "fanfare_big", "scale": 1.5, "rot": Vector3(15, 0, 0),
			"text": ["You got the *%s*!" % tu.title, tu.text,
				"Change tunics on the *Equipment* screen (press START and turn the page)."]}
	if item.begins_with("vanity_"):
		var va := Equipment.vanity(item.trim_prefix("vanity_"))
		return {"mesh": "tunic_%s_mesh" % item.trim_prefix("vanity_"), "fanfare": "fanfare_big", "scale": 1.5, "rot": Vector3(15, 0, 0),
			"text": ["You got the *%s*!" % va.title, va.text,
				"Wear it over any tunic, or put it away, on the *Equipment* screen. The tunic underneath still works!"]}
	if item.begins_with("shield_"):
		var sh := Equipment.shield(item.trim_prefix("shield_"))
		return {"mesh": "%s_flat_mesh" % item, "fanfare": "fanfare_big", "scale": 1.1, "rot": Vector3(-90, 0, 0),
			"text": ["You got the *%s*!" % sh.title, sh.text,
				"Change shields on the *Equipment* screen (press START and turn the page)."]}
	if item.begins_with("bun_piece_") and ITEMS.has(item):
		var bp: Dictionary = ITEMS[item].duplicate(true)
		# Counted before apply(): this piece and the ones already held.
		var n := Progress.bun_piece_count() + (0 if Progress.has_bun_piece(item.trim_prefix("bun_piece_")) else 1)
		if item != "bun_piece_alan":
			bp.text.append("That's *%d* of the three pieces! %s" % [n, "Take them to the pedestal in the *Hidden Forest*!" if n >= 3 else "One more lies in another tower."])
		return bp
	if ITEMS.has(item) and Progress.magic_cost(item) > 0 and Progress.magic_max <= 0:
		# The first magic item brings the magic meter with it.
		var mg: Dictionary = ITEMS[item].duplicate(true)
		mg.text.append("You feel a new power stir within you! A blue *Magic Meter* has appeared under your hearts. Magic jars from pots and foes refill it.")
		return mg
	if item.begins_with("chart_"):
		var n := int(item.trim_prefix("chart_"))
		var have := TreasureCharts.scraps() + (0 if Progress.flag(TreasureCharts.scrap_flag(n)) else 1)
		return {"mesh": "chart_scrap_mesh", "fanfare": "fanfare_item", "scale": 1.6, "rot": Vector3(20, 0, 0), "text": [
			"You found a *scrap of an old treasure chart*!",
			"An X is inked on it, with a scrawled note: *%s*" % TreasureCharts.hint(n),
			"That's *%d* of six scraps. Your *Journal* keeps them. Bring a spade!" % have,
		]}
	if item.begins_with("incunabulum_page_"):
		var n := int(item.trim_prefix("incunabulum_page_"))
		var have := IncunabulumLines.found() + (0 if Progress.flag(IncunabulumLines.flag_of(n)) else 1)
		var text: Array = ["You found a *page of the Fari Incunabulum*!
It's headed: *%s*." % IncunabulumLines.TITLES.get(n, "")]
		text.append_array(IncunabulumLines.PAGES.get(n, []))
		text.append("That's *%d* of the five lost pages. Your *Journal* keeps count of them." % have)
		return {"mesh": "incunabulum_page_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": text}
	if item == "starlight_lantern":
		var sl: Dictionary = ITEMS[item].duplicate(true)
		if not Progress.has_item("lantern"):
			sl.text.insert(1, "It's a lantern of its own, too: put it on X or Y and press the button to light it.")
		return sl
	if item == "quiver_up":
		var to := Progress.BIG_QUIVER if Progress.arrows_max < Progress.BIG_QUIVER else Progress.BIGGEST_QUIVER
		if Progress.arrows_max >= Progress.BIGGEST_QUIVER:
			return {"mesh": "rupee_purple_mesh", "fanfare": "fanfare_item", "scale": 1.6, "text": [
				"Your quiver is already the biggest there is! Have this instead: a *Purple Coin*, fifty Coins."]}
		return {"mesh": "quiver_mesh", "fanfare": "fanfare_big", "scale": 1.3, "text": [
			"You got a *Bigger Quiver*!
Now you can carry up to *%d* arrows!" % to]}
	if item == "heart_piece":
		# The message counts the pieces (OoT's 0x8B and the "you have N pieces" texts).
		var n := Progress.heart_pieces + 1
		var text: Array = ["You got a *Heart Shard*!"]
		match n:
			1: text.append("Collect four shards to make a new *Heart Vessel*.")
			2: text.append("You've collected two pieces. Two more make a whole heart!")
			3: text.append("Three pieces! Only one more to go!")
			_: text.append("You've collected four shards, and they've become a new *Heart Vessel*! Your life energy grows by one heart!")
		return {"mesh": "heart_piece_mesh", "fanfare": "heart_container" if n >= 4 else "fanfare_item", "scale": 1.4, "text": text}
	return ITEMS.get(item, {"mesh": "rupee_green_mesh", "fanfare": "fanfare_item", "text": ["You got something!"]})


## Gives `item` to the hero and plays the presentation; returns when the text
## box closes.
static func present(player: PlayerController, item: String) -> void:
	var def := definition(item)
	apply(player, item)
	player.begin_item_get()
	var mi := MeshInstance3D.new()
	mi.name = "HeldItem"
	mi.mesh = load("res://assets/models/%s.tres" % def.mesh)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player.add_child(mi)
	mi.position = Vector3(0, 2.2, -0.05) + def.get("offset", Vector3.ZERO)
	var rot: Vector3 = def.get("rot", Vector3.ZERO)
	mi.rotation = Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	mi.scale = Vector3.ONE * def.get("scale", 1.0)
	Sfx.play(def.fanfare, -2.0, 0.0)
	await player.get_tree().create_timer(0.7).timeout
	if not is_instance_valid(player):
		return
	Dialogue.start(def.text.duplicate(), null)
	await Dialogue.finished
	if is_instance_valid(mi):
		mi.queue_free()
	if is_instance_valid(player):
		player.end_talk()
	# A goddess's piece of the Bun: her voice (StoryBeats, Beta 1.5.0).
	if item.begins_with("bun_piece_") and Guide.auto_scenes:
		await StoryBeats.bun_piece(item.trim_prefix("bun_piece_"))


## The item's effect.
static func apply(player: PlayerController, item: String) -> void:
	var d := World.dungeon_id()
	if item.begins_with("sword_"):
		Progress.give_sword(item.trim_prefix("sword_"))
		return
	if item.begins_with("shield_"):
		Progress.give_shield(item.trim_prefix("shield_"))
		return
	if item.begins_with("boots_"):
		Progress.give_boots(item.trim_prefix("boots_"))
		return
	if item.begins_with("tunic_"):
		Progress.give_tunic(item.trim_prefix("tunic_"))
		return
	if item.begins_with("vanity_"):
		Progress.give_vanity(item.trim_prefix("vanity_"))
		return
	if item.begins_with("bun_piece_"):
		Progress.set_flag("bun_piece:" + item.trim_prefix("bun_piece_"))
		return
	if item.begins_with("incunabulum_page_"):
		Progress.set_flag(IncunabulumLines.flag_of(int(item.trim_prefix("incunabulum_page_"))))
		return
	if item.begins_with("chart_"):
		Progress.set_flag(TreasureCharts.scrap_flag(int(item.trim_prefix("chart_"))))
		return
	if item.begins_with("trade_"):
		Progress.set_trade(item.trim_prefix("trade_"))
		return
	match item:
		"boomerang":
			Progress.give_item("boomerang")
		"small_key":
			Progress.add_key(d)
		"map", "compass", "boss_key":
			Progress.give_dungeon_item(d, item)
		"heart_container":
			Progress.heart_container()
			player.health.max_health = Progress.max_health
			player.health.heal(Progress.max_health)
		"heart_piece":
			if Progress.add_heart_piece():
				player.health.max_health = Progress.max_health
				player.health.heal(Progress.max_health)
		"rupee_red":
			Progress.add_rupees(20)
		"rupee_blue":
			Progress.add_rupees(5)
		"arrows_10":
			Progress.add_arrows(10)
		"big_quiver":
			Progress.arrows_max = maxi(Progress.arrows_max, Progress.BIG_QUIVER)
			Progress.add_arrows(Progress.arrows_max)
		"biggest_quiver":
			Progress.arrows_max = Progress.BIGGEST_QUIVER
			Progress.add_arrows(Progress.arrows_max)
		"big_wallet":
			Progress.wallet = maxi(Progress.wallet, Progress.BIG_WALLET)
			Progress.changed.emit()
		"giant_wallet":
			Progress.wallet = Progress.GIANT_WALLET
			Progress.changed.emit()
		"bun_bracers":
			Progress.give_bracers(1)
		"questlord_gauntlets":
			Progress.give_bracers(2)
		"silver_scale":
			Progress.give_scale(1)
		"golden_scale":
			Progress.give_scale(2)
		"sugar_cube", "hookshot", "bloom_rod", "iron_mallet", "fishing_rod", "lantern", "grave_spade", "iron_flail":
			Progress.give_item(item)
		"astral_seal":
			Progress.give_item(item)
			Progress.set_flag("ch4:astral_seal")
		"sapphire_staff", "starfall_arrows", "ember_rod", "lothelyes_dream":
			if Progress.magic_max <= 0:
				Progress.give_magic_meter()
			Progress.give_item(item)
		"longshot":
			Progress.set_flag(Progress.LONGSHOT)
			Progress.give_item("hookshot")
		"bomb_bag_up":
			Progress.upgrade_bomb_bag()
		"quiver_up":
			if Progress.arrows_max >= Progress.BIGGEST_QUIVER:
				Progress.add_rupees(50)
			else:
				Progress.arrows_max = Progress.BIG_QUIVER if Progress.arrows_max < Progress.BIG_QUIVER else Progress.BIGGEST_QUIVER
				Progress.add_arrows(Progress.arrows_max)
		"nut_pouch_up":
			Progress.upgrade_nut_pouch()
		"rupee_purple":
			Progress.add_rupees(50)
		"rupee_gold":
			Progress.add_rupees(100)
		"shield_polish":
			Progress.set_flag("shield_polish")
			Progress.gear_changed.emit()
		"dark_prophecy":
			Progress.set_flag("ch3:prophecy")
		"starlight_lantern":
			Progress.give_item("lantern")
			Progress.set_flag(Progress.STARLIGHT)
		"double_magic":
			Progress.give_magic_meter(Progress.MAGIC_SINGLE * 2)
		"double_defense":
			Progress.give_double_defense()
		"sun_arrows", "frost_arrows", "looking_glass", "alans_harvest", "aphiels_gale", "serielyes_ruin":
			if Progress.magic_max <= 0:
				Progress.give_magic_meter()
			Progress.give_item(item)
		"puff_nuts":
			Progress.give_nut_pouch(10)
		"puff_nuts_10":
			Progress.add_nuts(10)
		"bottle":
			Progress.give_bottle("empty")
		"bottle_milk":
			Progress.give_bottle("milk")
		"bomb_bag":
			Progress.give_bomb_bag()
		"bombs_10":
			Progress.add_bombs(10)
