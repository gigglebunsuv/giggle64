class_name EnemyScale
extends RefCounted
## How tough the creatures are. Each dungeon has a tier (its place in the
## hero's journey); a creature that wakes up inside one gets more health,
## hits harder, moves and notices a little quicker for every tier, and its
## name in the Bestiary gets a rank ("Veteran Goblin").
##
## On top of a dungeon's own tier:
## - the Bun Sword: once the hero has drawn it, every creature in Haven is
##   BUN_SWORD_TIERS tougher for good (the dark knows the blade is out);
## - from Chapter III's dungeons on (the Sapphire Sanctum, tier 5, and every
##   one after), LATE_DUNGEON_TIERS more;
## - the open regions (tier 0 at first) grow with the story, OVERWORLD_BY_CHAPTER.
## Bosses do not use the tiers: each is set for its own fight, BOSS_HEALTH.

## The dungeons in the order the hero meets them.
const TIERS := {
	"lake_shrine": 0,
	"southern_tower": 1,
	"ladhellin_tower": 2,
	"skyreach_spire": 3,
	"bog_tower": 3,
	"castle": 4,
	"frostpeak_hollow": 4,
	"sun_trial": 5,
	"sapphire_sanctum": 5,
	"westmarch_fortress": 6,
	"temple_of_bun": 7,
	"citadel_assault": 8,
	"barrow_of_kings": 8,
	"cinder_vault": 9,
	"ridge_keep": 10,
}
## Open regions where the dead are stronger than elsewhere (Black Water
## Ridge: "where the undead are strongest"), and stronger again at night
## (Beta 1.4.0).
const AREA_EXTRA := {"black_water_ridge": 1}
const NIGHT_AREAS := ["black_water_ridge"]
## Extra health per tier (x the creature's base), extra hit damage per tier,
## and how much quicker per tier (its exported speeds and wind-ups, and how
## far off it notices the hero).
const HEALTH_PER_TIER := 0.25
const DAMAGE_PER_TIER := 0.12
const HASTE_PER_TIER := 0.025
## The Bun Sword's permanent step up, the late dungeons' extra step, and the
## first tier counted as a late (Chapter III or after) dungeon.
const BUN_SWORD_TIERS := 2
const LATE_DUNGEON_TIERS := 1
const LATE_FROM := 5
## The open regions' tier in each chapter (before the Bun Sword's step).
const OVERWORLD_BY_CHAPTER := {1: 0, 2: 1, 3: 2, 4: 3, 5: 4}
const MAX_TIER := 13
## The rank a creature carries at each tier.
const RANKS := ["", "", "Veteran", "Veteran", "Elite", "Elite", "Dread", "Dread", "Ancient", "Ancient", "Mythic", "Mythic", "Mythic", "Mythic"]
## Bosses (by kind): health times their base, so a boss takes a proper
## number of blows from the sword the hero will have by then (the Bun Sword
## cuts 4, awake 6).
const BOSS_HEALTH := {
	"carapax": 1.5, "corvax": 1.6, "wyrm": 1.8, "storm_eye": 2.0, "gullagog": 3.0,
	"sleetcoil": 2.8, "incunax": 3.2, "siege_ogre": 1.8, "pedestal_guardian": 2.0,
	"hollow_king": 2.1, "magmaw": 4.5, "mara": 2.4,
}
## Tests turn scaling off so they can count hits against base health.
static var enabled := true


## The tier of a creature waking up in `area` now.
static func tier(area: String) -> int:
	if not enabled:
		return 0
	var t: int
	if TIERS.has(area):
		t = TIERS[area]
		if t >= LATE_FROM:
			t += LATE_DUNGEON_TIERS
	else:
		t = OVERWORLD_BY_CHAPTER.get(_chapter(), 0) + int(AREA_EXTRA.get(area, 0))
		if area in NIGHT_AREAS and _night():
			t += 1
	if _bun_sword():
		t += BUN_SWORD_TIERS
	return mini(t, MAX_TIER)


static func health(base: int, t: int) -> int:
	return maxi(base, roundi(base * (1.0 + HEALTH_PER_TIER * t)))


static func damage(base: int, t: int) -> int:
	if base <= 0:
		return base
	return maxi(base, roundi(base * (1.0 + DAMAGE_PER_TIER * t)))


## Speed multiplier at tier `t` (wind-ups and rests are divided by it).
static func haste(t: int) -> float:
	return 1.0 + HASTE_PER_TIER * t


## A boss's health for its fight (its base without scaling).
static func boss_health(kind: String, base: int) -> int:
	if not enabled:
		return base
	return roundi(base * float(BOSS_HEALTH.get(kind, 1.0)))


static func rank(t: int) -> String:
	return RANKS[clampi(t, 0, RANKS.size() - 1)]


## A slightly darker, richer tint for the tougher ranks, so a Dread goblin
## looks like one.
static func tint(t: int) -> Color:
	if t < 2:
		return Color(1, 1, 1)
	var k := minf((t - 1) * 0.05, 0.35)
	return Color(1.0 - k * 0.3, 1.0 - k, 1.0 - k * 0.7)


## (Looked up by path: the asset generators load this script without autoloads.)
static func _progress() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Progress") if tree else null


static func _bun_sword() -> bool:
	var p := _progress()
	return p != null and bool(p.call("has_sword", "bun"))


static func _chapter() -> int:
	var p := _progress()
	if p == null:
		return 1
	return Quests.chapter_of(p.get("flags"))


static func _night() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var dn: Node = tree.root.get_node_or_null("DayNight") if tree else null
	return dn != null and bool(dn.call("is_night"))
