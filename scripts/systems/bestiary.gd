class_name Bestiary
extends RefCounted
## The Bestiary (Beta 1.2.0): a page of the JOURNAL listing every kind of
## creature the hero has beaten (Progress.bestiary, kept by Enemy._on_died),
## how many, and the toughest rank he has met it at (EnemyScale: a goblin
## beaten in Westmarch Fortress is a DREAD GOBLIN).

const NAMES := {
	"basic_enemy": "CINDER GOBLIN", "goblin_archer": "GOBLIN ARCHER", "boar_rider": "BOAR RIDER",
	"keese": "CAVE BAT", "fire_keese": "FIRE BAT", "ice_keese": "ICE BAT", "tektite": "RED HOPPER", "tektite_blue": "BLUE HOPPER",
	"snapper": "SNAPPER", "snapper_coral": "CORAL SNAPPER", "leever": "SAND SPINNER", "octorok": "ROCK SPITTER", "rat": "RAT",
	"stalfos": "SKELETON", "charred_stalfos": "CHARRED SKELETON", "frost_stalfos": "FROST SKELETON", "bog_stalfos": "BOG SKELETON",
	"shellblade": "SHELLBLADE", "tide_knight": "TIDE KNIGHT", "rust_knight": "RUST KNIGHT", "gear_beetle": "GEAR BEETLE",
	"strawman": "STRAWMAN", "straw_archer": "STRAW ARCHER", "mummy": "MUMMY", "mummy_lord": "MUMMY LORD", "shade": "SHADE",
	"sand_beetle": "SAND BEETLE", "sentinel": "SENTINEL", "freezard": "FROST IDOL", "wind_wisp": "WIND WISP",
	"frost_knight": "FROST KNIGHT", "mire_knight": "MIRE KNIGHT", "rimeguard": "RIMEGUARD", "sunwarden": "SUNWARDEN",
	"sapphire_mage": "SAPPHIRE MAGE", "sapphire_knight": "SAPPHIRE KNIGHT", "sapphire_warden": "SAPPHIRE WARDEN",
	"battle_mage": "BATTLE-MAGE", "shadow_wolf": "SHADOW WOLF", "dark_gigglebuns": "DARK GIGGLEBUNS",
	"cinder_wyvern": "CINDER WYVERN", "wyvern": "FROSTWING",
	"carapax": "CARAPAX", "corvax": "CORVAX", "wyrm": "KHERASH", "storm_eye": "AEOLOS", "gullagog": "GULLAGOG",
	"sleetcoil": "SLEETCOIL", "incunax": "INCUNAX", "siege_ogre": "GRUKK", "pedestal_guardian": "PEDESTAL GUARDIAN",
	"gaoler": "THE JAILER", "mara": "MARA",
}


static func name_of(kind: String) -> String:
	return String(NAMES.get(kind, kind.replace("_", " ").to_upper()))


## "VETERAN STALFOS x4", most beaten first.
static func lines() -> Array:
	var kinds: Array = Progress.bestiary.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool:
		return int(Progress.bestiary[a].get("n", 0)) > int(Progress.bestiary[b].get("n", 0)))
	var out: Array = []
	for k: String in kinds:
		var e: Dictionary = Progress.bestiary[k]
		var rank := EnemyScale.rank(int(e.get("tier", 0)))
		out.append("%s%s x%d" % [rank.to_upper() + " " if rank != "" else "", name_of(k), int(e.get("n", 0))])
	return out


static func count() -> int:
	return Progress.bestiary.size()
