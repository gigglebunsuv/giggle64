class_name Equipment
extends RefCounted
## The hero's swords, shields, boots and tunics: names, strength and the generated meshes
## (tools/gen_characters.gd builds each piece in the same frame as the one on
## the hero's model, so CharacterModel.set_gear swaps the meshes in place).
##
## Swords go up in tiers like OoT's (Kokiri 1, Master 2, Biggoron 4 damage);
## longer blades reach further, so the sword's hitbox grows with `reach`.
## Icons are rendered from the same meshes by tools/render_icons.gd.

const SWORDS := {
	"squire": {"name": "SQUIRE'S SWORD", "title": "Squire's Sword", "damage": 1, "reach": 0.0,
		"text": "A plain, trusty blade. Every knight of Haven starts with one."},
	"red": {"name": "RED SWORD", "title": "Red Sword", "damage": 2, "reach": 0.12,
		"text": "A longer blade of dark steel with a red hilt. It hits harder."},
	"magical": {"name": "MAGICAL SWORD", "title": "Magical Sword", "damage": 3, "reach": 0.26,
		"text": "A long, broad blade of shining white steel. It cuts like nothing else."},
	"bun": {"name": "BUN SWORD", "title": "Bun Sword", "damage": 4, "reach": 0.3, "beam": true,
		"text": "The legendary blade of the Hidden Forest. With full health it fires beams of magic!"},
	# Aladriel's giant sword (Beta 1.4.0), after OoT's Biggoron's Sword: held in
	# both hands, so the shield rides on the back while it is out and R guards
	# with the flat of the blade (BLADE_GUARD). `slow` stretches each swing.
	"great": {"name": "QUESTLORD'S GREATSWORD", "title": "Questlord's Greatsword", "damage": 8, "reach": 0.62,
		"two_handed": true, "slow": 1.3,
		"text": "Aladriel's giant sword, bigger than you are! Swing it with both hands: your shield goes on your back, and the shield button guards with the flat of the blade."},
}
const SWORD_ORDER := ["squire", "red", "magical", "bun", "great"]
## The Bun Sword once it wakes in the Temple of Bun (Chapter IV): it takes
## the Bun Sword's place, cuts harder, and its beam is starlight, loosed at
## any health, that puts out the Order's wards and lights star braziers.
const AWAKENED := {"name": "BUN SWORD", "title": "Bun Sword (Awakened)", "damage": 6, "reach": 0.34, "beam": true, "starlight": true,
	"text": "Awake at last, the goddesses' blade has turned rose-pink and shines with Lothelye's starlight. Its beam flies at any health, and the Order's magic breaks before it."}

## block_push: how far a blocked blow shoves the hero (OoT's shield recoil).
## heavy: stops blows too heavy for the Wooden Shield (the Tide Knight's chop).
## mirror: batters every projectile straight back at whoever sent it.
const SHIELDS := {
	"wooden": {"name": "WOODEN SHIELD", "title": "Wooden Shield", "block_push": 2.5, "half_angle": 75.0,
		"text": "An iron-rimmed wooden shield. Light, but heavy blows go right through it."},
	"iron": {"name": "IRON SHIELD", "title": "Iron Shield", "block_push": 1.0, "half_angle": 85.0, "heavy": true,
		"text": "A solid iron shield. Even the heaviest blows hardly move you."},
	"mirror": {"name": "SILVERED SHIELD", "title": "Silvered Shield", "block_push": 1.0, "half_angle": 90.0, "heavy": true, "mirror": true,
		"text": "A polished shield that throws any projectile right back at its sender!"},
	# The trade chain's prize (Beta 1.1.0): Aladriel's old shield pattern forged
	# in starmetal by Pink. fireproof: the Order's wards and fire spells break
	# on it while the hero guards.
	"questlord": {"name": "QUESTLORD'S SHIELD", "title": "Questlord's Shield", "block_push": 0.5, "half_angle": 110.0, "heavy": true, "fireproof": true,
		"text": "Aladriel's old starmetal shield, forged anew by Pink. The widest guard of all, and fire and sapphire magic break harmlessly on it."},
}
const SHIELD_ORDER := ["wooden", "iron", "mirror", "questlord"]
## The guard of a two-handed sword (OoT's Biggoron's Sword under R): the
## broad blade held crosswise stops blows from the front, heavy ones too,
## but it is narrower than a shield, turns nothing back and is no help
## against fire.
const BLADE_GUARD := {"name": "BLADE GUARD", "title": "Blade Guard", "block_push": 2.0, "half_angle": 60.0, "heavy": true}

## Boots, worn like OoT's (the EQUIPMENT page's third row).
## wind: the gales of Skyreach Spire cannot push him, and holding A in the air
## he glides.
const BOOTS := {
	"leather": {"name": "LEATHER BOOTS", "title": "Leather Boots",
		"text": "Sturdy riding boots. Good for walking, and not much else."},
	"wind": {"name": "WIND BOOTS", "title": "Wind Boots", "wind": true, "tint": Color(0.75, 0.95, 1.25),
		"text": "They hold fast against any wind. Hold A in the air to glide, and ride the wind!"},
	# Westmarch Fortress (Chapter IV), after OoT's Iron Boots: in water he
	# sinks and walks the bottom; no gale can move him; he walks slowly.
	"anchor": {"name": "ANCHOR BOOTS", "title": "Anchor Boots", "anchor": true, "tint": Color(0.55, 0.55, 0.62),
		"text": "Boots of black iron, as heavy as an anchor. In deep water you sink and walk along the bottom, and no wind can move you."},
}
const BOOT_ORDER := ["leather", "wind", "anchor"]

## Tunics, worn like OoT's (the EQUIPMENT page's third row). `palette` maps
## the Haven Tunic's colors on the hero's model to the tunic's own
## (CharacterModel.set_outfit recolors the vertex colors).
## breathe: under water he can stay down as long as he likes (OoT's Zora Tunic).
## warm: the bitter cold of Frostpeak Hollow cannot touch him (the Goron
##   Tunic's answer to heat, turned to frost).
## stealth: sentries and creatures notice him from only this far (a share of
##   their usual range).
const TUNICS := {
	"haven": {"name": "HAVEN TUNIC", "title": "Haven Tunic", "palette": {},
		"text": "The red tunic of a knight of Haven. Warm in spring, cool in summer, and very red."},
	"tide": {"name": "TIDE TUNIC", "title": "Tide Tunic", "breathe": true,
		"palette": {"8c1d17": "1d5a8c", "a3261d": "2a76b0", "6a140f": "123e66", "9b9ea3": "c8d8e0", "80838a": "a0b4c0"},
		"text": "A tunic woven from lake weed and moonlight. Wearing it, you can stay under water as long as you like!"},
	"frost": {"name": "FROST MANTLE", "title": "Frost Mantle", "warm": true,
		"palette": {"8c1d17": "e8ecf2", "a3261d": "ffffff", "6a140f": "8aa6c8", "9b9ea3": "6a7a90", "80838a": "56647a", "6e4630": "e0e4ea", "573522": "b8c0cc"},
		"text": "A thick white mantle lined with snow-fox fur. The bitter cold of Frostpeak Hollow can't touch you in it."},
	"shade": {"name": "SHADE CLOAK", "title": "Shade Cloak", "stealth": 0.45,
		"palette": {"8c1d17": "2e2a3a", "a3261d": "3e3850", "6a140f": "1a1824", "9b9ea3": "4a4658", "80838a": "363244", "6e4630": "2a2630", "573522": "1e1a24"},
		"text": "A cloak as dark as the space between stars. Sentries and creatures only notice you from very close."},
}
const TUNIC_ORDER := ["haven", "tide", "frost", "shade"]

## Vanity outfits: worn over any tunic for the look of it (the tunic's power
## still works underneath). Himeko's gift to her knight, who she says is
## dressed like a turnip farmer.
const VANITY := {
	"regalia": {"name": "KNIGHT'S REGALIA", "title": "Knight's Regalia", "cape": true,
		"palette": {"8c1d17": "f4ecdc", "a3261d": "fffaf0", "6a140f": "b8202e", "9b9ea3": "b01e2a", "80838a": "8a1620",
			"6e4630": "fafafa", "573522": "d8d8dc", "5a3820": "d8b050", "6b4529": "d8b050", "2b2b31": "1e1418", "3a3a42": "2e2228", "19191d": "120c0e"},
		"text": "A princess's knight must be beautifully dressed! Ivory and crimson, gold trim, and a cape that sways as you run."},
	# The knighting (Chapter V): the tabard of a sworn Knight of Haven.
	"knight": {"name": "KNIGHT'S TABARD", "title": "Knight's Tabard", "cape": true, "cape_cols": ["2a4a92", "1a2e62", "d8dce4"],
		"palette": {"8c1d17": "2a4a92", "a3261d": "3a5cb0", "6a140f": "1a2e62", "9b9ea3": "d8dce4", "80838a": "b0b6c2",
			"6e4630": "e8e8ee", "573522": "c0c4cc", "5a3820": "c8ccd8", "6b4529": "c8ccd8", "2b2b31": "1a1e2e", "3a3a42": "262a3c", "19191d": "10121a"},
		"text": "The tabard of a sworn Knight of Haven: deep Haven blue and silver, the bun crest on the breast, and a knight's cape."},
}


static func sword(id: String) -> Dictionary:
	if id == AWAKE_LOOK or (id == "bun" and _awake()):
		return SWORDS.bun.merged(AWAKENED, true)
	return SWORDS.get(id, SWORDS.squire)


## The look of the hero's sword: the Bun Sword turns pink once it wakes
## ("bun_awake" meshes and icon); every other sword looks as it is.
const AWAKE_LOOK := "bun_awake"


static func sword_look(id: String) -> String:
	return AWAKE_LOOK if id == "bun" and _awake() else id


## (Looked up by path: the asset generators load this script without autoloads.)
static func _awake() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var progress: Node = tree.root.get_node_or_null("Progress") if tree else null
	return progress != null and progress.call("flag", "ch4:sword_awake")


static func shield(id: String) -> Dictionary:
	return SHIELDS.get(id, SHIELDS.wooden)


## Whether the sword `id` (default: the one equipped) takes both hands.
static func two_handed(id := "") -> bool:
	if id == "":
		id = _equipped_sword()
	return SWORDS.get(id, {}).get("two_handed", false)


## What stops blows when the hero guards: the equipped shield, or the blade
## itself with a two-handed sword.
static func guard() -> Dictionary:
	if two_handed():
		return BLADE_GUARD
	return shield(_equipped("shield"))


static func _equipped_sword() -> String:
	return _equipped("sword")


static func _equipped(prop: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var progress: Node = tree.root.get_node_or_null("Progress") if tree else null
	return str(progress.get(prop)) if progress else ""


static func boots(id: String) -> Dictionary:
	return BOOTS.get(id, BOOTS.leather)


static func tunic(id: String) -> Dictionary:
	return TUNICS.get(id, TUNICS.haven)


static func vanity(id: String) -> Dictionary:
	return VANITY.get(id, {})


## Mesh resources made by tools/gen_characters.gd (in the frame of the node
## that holds them on the hero).
static func sword_mesh(id: String) -> String:
	return "res://assets/models/sword_%s_mesh.tres" % id


static func sword_hilt_mesh(id: String) -> String:
	return "res://assets/models/sword_%s_hilt_mesh.tres" % id


static func scabbard_mesh(id: String) -> String:
	return "res://assets/models/scabbard_%s_mesh.tres" % id


static func shield_mesh(id: String) -> String:
	return "res://assets/models/shield_%s_mesh.tres" % id


static func shield_back_mesh(id: String) -> String:
	return "res://assets/models/shield_%s_back_mesh.tres" % id


## Icon pictures (tools/render_icons.gd): "sword_red", "shield_iron", "bow"...
static func icon_path(icon: String) -> String:
	return "res://assets/textures/icons/%s.png" % icon
