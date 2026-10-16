class_name Drops
extends RefCounted
## Random item drops, after Item_DropCollectibleRandom (z_en_item00.c).
##
## A drop picks one of 16 slots of a table at random. The tables below are
## OoT's sItemDropIds tables with the items Haven has no use for (seeds for a
## slingshot, Deku sticks) as nothing, and seeds
## turned into small bundles of arrows the way func_8001F404 does for adult Link.
## func_8001F404 also turns a heart into a green rupee at full health, and
## drops nothing the hero cannot use (arrows without the bow, bombs without
## the bomb bag). The bomb slots (ITEM00_BOMBS_A) are back now that Marigold
## sells the bag.
## "flexible" (ITEM00_FLEXIBLE) gives what the hero needs most: hearts when he
## is low, then arrows when the quiver is nearly empty, then a red rupee when
## he is nearly broke; otherwise nothing.

const NONE := ""
const TABLES := {
	# COLLECTIBLE_DROP_TABLE_0: grass and bushes.
	0: ["rupee_green", "rupee_blue", "", "nuts_5", "rupee_blue", "rupee_green", "magic_small", "heart",
		"heart", "", "", "flexible", "arrows_5", "arrows_5", "", "rupee_blue"],
	# COLLECTIBLE_DROP_TABLE_1: most enemies.
	1: ["rupee_green", "", "rupee_green", "rupee_blue", "heart", "magic_small", "heart", "",
		"flexible", "", "bombs_5", "nuts_5", "arrows_5", "", "", "magic_small"],
	# Pots (TABLE_2-like): mostly hearts and rupees.
	2: ["rupee_green", "heart", "rupee_green", "rupee_blue", "heart", "bombs_5", "rupee_green", "arrows_5",
		"flexible", "magic_small", "heart", "nuts_5", "arrows_5", "bombs_5", "magic_large", "heart"],
	# COLLECTIBLE_DROP_TABLE_11: hearts only (big enemies).
	11: ["heart", "heart", "heart", "heart", "heart", "heart", "heart", "heart",
		"heart", "heart", "heart", "heart", "heart", "heart", "heart", "heart"],
	# COLLECTIBLE_DROP_TABLE_12: blue and red rupees.
	12: ["rupee_red", "rupee_blue", "rupee_blue", "rupee_red", "rupee_blue", "rupee_blue", "rupee_blue", "rupee_red",
		"rupee_red", "rupee_blue", "rupee_red", "rupee_blue", "rupee_red", "rupee_red", "rupee_red", "rupee_red"],
}
## sDropQuantities: table 11 and 12 drops come three at a time.
const QUANTITY := {11: 3, 12: 3}


## Drops from `table` at `pos` under `parent`. Returns the items spawned.
static func random(table: int, pos: Vector3, parent: Node, rng: RandomNumberGenerator = null) -> Array:
	var slots: Array = TABLES.get(table, TABLES[0])
	var i := (rng.randi() if rng else randi()) % slots.size()
	var id: String = slots[i]
	if id == "flexible":
		id = _flexible()
	var out: Array = []
	if id == "":
		return out
	for n in QUANTITY.get(table, 1):
		var c := spawn(id, pos, parent, true)
		if c:
			out.append(c)
	return out


## Spawns a collectible. Dropped items pop up and vanish after a while;
## placed ones stay. Returns null if the item would be useless (func_8001F404).
static func spawn(id: String, pos: Vector3, parent: Node, dropped: bool) -> Collectible:
	if dropped:
		id = usable(id)
	if id == "":
		return null
	var c := Collectible.new()
	c.kind = id
	c.dropped = dropped
	parent.add_child(c)
	c.global_position = pos
	return c


## func_8001F404: what an item drop actually becomes for this hero.
static func usable(id: String) -> String:
	if id.begins_with("arrows") and not Progress.has_item("bow"):
		return ""
	if id.begins_with("bombs") and not Progress.has_item("bombs"):
		return ""
	if id.begins_with("nuts") and not Progress.has_item("puff_nuts"):
		return ""
	if id.begins_with("magic") and Progress.magic_max <= 0:
		return ""
	if id == "heart":
		var p := GameManager.player
		if p and p.health.health >= p.health.max_health:
			return "rupee_green"
	return id


static func _flexible() -> String:
	var p := GameManager.player
	if p:
		var hp := p.health.health
		if hp <= 6:   # three hearts or less (in half hearts)
			return "heart"
	if Progress.has_item("bow") and Progress.arrows < 6:
		return "arrows_10"
	if Progress.has_item("bombs") and Progress.bombs < 4:
		return "bombs_5"
	if Progress.magic_max > 0 and Progress.magic < 12:
		return "magic_small"
	if Progress.rupees < 11:
		return "rupee_red"
	return ""
