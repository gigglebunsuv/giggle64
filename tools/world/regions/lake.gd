extends "res://tools/world/region.gd"
## Mirror Lake: a wide blue lake in a ring of cliffs at the end of the South
## Road. Sandy beaches, a fishing dock and hut, a chain of plank bridges over
## two islets to the central island and its domed Lake Shrine (sealed).
## Mira lives in the tall house on the north shore: its door leads inside
## (lake_house), a ladder climbs to the lookout deck on its roof, and three
## archery targets stand on the beach to the west.
## The far end of the dock is a fishing spot (Mira lends the rod), and the
## three targets hide a Piece of Heart for the archer who hits every gold
## center. The lake is deep: the hero swims in it.
## Out past the islets the bed drops away: a sunken chest lies 7 m down (the
## Tide Tunic, for a diver with the Silver Scale), and a trench in the east
## goes down to 11 m (a Piece of Heart for the Golden Scale).

const WATER_Y := 0.0
const CENTER := Vector2(10, 5)
const LAKE_R := 44.0
const ISLAND := Vector2(12, 8)
const ISLAND_R := 9.0
const ISLETS: Array[Vector2] = [Vector2(-26, -21), Vector2(-9, -9)]
const SHORE_A := Vector2(-42, -32)
const HUT := Vector2(-2, -52)
const HUT_W := 7.0
const HUT_D := 6.0
## The sunken chest's ledge, and the deep trench.
const SUNKEN := Vector2(34, 22)
const SUNKEN_Y := -7.0
const TRENCH := Vector2(30, -14)
const TRENCH_R := 5.0
## Archery targets along the north shore, west of the house.
const TARGETS: Array[Vector2] = [Vector2(-11, -55), Vector2(-17, -49), Vector2(-25, -54)]


func setup() -> void:
	id = "lake"
	seed_value = 121
	x_min = -70.0
	x_max = 70.0
	z_min = -70.0
	z_max = 70.0
	rim_height = 15.0
	rim_margin = 8.0
	cliff_col = Color(0.85, 0.82, 0.72)
	rock_col = Color.html("7a7468")
	links = [{"to": "south_road", "p": Vector2(-70, -45), "d": Vector2(1, 0), "w": 5.0, "y": 1.2}]
	water = [{"rect": Rect2(-90, -90, 180, 180), "y": WATER_Y, "col": Color(0.2, 0.45, 0.8, 0.8)}]
	mood = {
		"sky_top": Color.html("2050c8"), "sky_mid": Color.html("5a8ae8"), "sky_horizon": Color.html("c8e0f8"),
		"cloud": Color.html("ffffff"), "cloud_amount": 0.4,
		"fog": Color.html("c6dcf0"), "fog_begin": 45.0, "fog_end": 175.0,
		"ambient": Color.html("6a7898"), "sun": Color.html("fff8e8"), "sun_rot": Vector3(-55, -120, 0),
		"horizon": Color.html("7a90b8"), "hill_height": 18.0,
	}


func base_height(x: float, z: float) -> float:
	var shore := 1.2 + noise.get_noise_2d(x * 1.5, z * 1.5) * 1.2
	var d := Vector2(x, z).distance_to(CENTER)
	var h := lerpf(-8.0, shore, smoothstep(LAKE_R - 14.0, LAKE_R + 2.0, d))
	h = maxf(h, lerpf(-9.0, 1.1, 1.0 - smoothstep(ISLAND_R - 3.0, ISLAND_R + 2.0, Vector2(x, z).distance_to(ISLAND))))
	for p in ISLETS:
		h = maxf(h, lerpf(-9.0, 0.8, 1.0 - smoothstep(2.0, 5.0, Vector2(x, z).distance_to(p))))
	# The trench in the lake bed.
	h = minf(h, lerpf(-11.2, 2.0, smoothstep(TRENCH_R - 2.5, TRENCH_R + 1.0, Vector2(x, z).distance_to(TRENCH))))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if h < -0.4:
		return pick(r, ["4a6a7a", "547484"]) if h > -3.0 else pick(r, ["2a4a6a", "30506e"])
	if h < 1.3:
		return pick(r, ["d8c494", "e0cc9c", "ccb888"])
	var b := noise.get_noise_2d(x * 3.0, z * 3.0)
	return Color.html("4e8a34").lerp(Color.html("6aa444"), clampf(b + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# The bridge chain from the west shore over the islets to the island.
	var chain: Array[Vector2] = [SHORE_A, ISLETS[0], ISLETS[1], ISLAND]
	for i in chain.size() - 1:
		var a: Vector2 = chain[i]
		var b: Vector2 = chain[i + 1]
		var dir := (b - a).normalized()
		var a_r := 4.0 if i > 0 else 0.0
		var b_r := ISLAND_R - 2.5 if i == chain.size() - 2 else 3.0
		var pa: Vector2 = a + dir * a_r
		var pb: Vector2 = b - dir * b_r
		k.bridge(Vector3(pa.x, maxf(k.h(pa.x, pa.y), 0.5), pa.y), Vector3(pb.x, maxf(k.h(pb.x, pb.y), 0.5), pb.y), 3.0, "wood", 0.8)
	for p in ISLETS:
		k.tree_round(p.x + 1.0, p.y - 1.0, 0.9)
	# The moonlit chest: on the first islet, beside the bridges, only after
	# dark (DayNight; Mira hints that things shine out here at night). It
	# holds an empty bottle.
	var bridge_dir := (ISLETS[1] - SHORE_A).normalized()
	var side := Vector2(-bridge_dir.y, bridge_dir.x)
	var moon_at: Vector2 = ISLETS[0] + side * 1.8
	k.chest(moon_at.x, moon_at.y, k.yaw_of(-side), "bottle", false, "lake:moon_chest", "time:night")
	# On the second islet stands a chest no one can see: Mira's Looking Glass
	# shows it (a Piece of Heart).
	var lens_at: Vector2 = ISLETS[1] - side * 1.8
	k.lens_chest(lens_at.x, lens_at.y, k.yaw_of(side), "heart_piece", "lake:lens_chest")
	# The domed Lake Shrine, its door facing the bridge. The door leads down
	# into the shrine (lake_shrine), the first dungeon.
	var face: float = k.yaw_of((ISLETS[1] - ISLAND).normalized())
	k.tower(ISLAND.x, ISLAND.y + 1.0, 4.2, 6.0, "stone", Color(0.92, 0.95, 1.0), Color.html("3a6ac0"), face, {"sides": 12, "roof_h": 4.5, "seal": "open"})
	var out := (ISLETS[1] - ISLAND).normalized()
	var dp: Vector2 = ISLAND + Vector2(0, 1.0) + out * 4.62
	var frame = k._tmp()
	frame.push(Transform3D(Basis(Vector3.UP, face), Vector3(dp.x, k.h(dp.x, dp.y), dp.y)))
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(sx * 1.2, 1.5, 0), Vector3(0.5, 3.0, 0.6), Color(0.9, 0.95, 1.0))
	frame.box(Vector3(0, 3.25, 0), Vector3(3.0, 0.5, 0.65), Color(0.9, 0.95, 1.0))
	frame.pop()
	k.merge(frame, "stone")
	k.door_link(Vector3(dp.x, k.h(dp.x, dp.y), dp.y), face, 1.8, 2.8, "lake_shrine", "from_lake", Color(0.75, 0.9, 1.0))
	var ep: Vector2 = dp + out * 1.8
	k.entrance("from_lake_shrine", ep.x, ep.y, k.yaw_of(out))
	var wp: Vector2 = dp + out * 1.6 + Vector2(-out.y, out.x) * 1.2
	k.entrance("warp_lake_shrine", wp.x, wp.y, k.yaw_of(out))
	# Beta 1.5.0: out of the shrine for the first time, the road ahead.
	k.story_trigger("lake_done", Rect2(dp.x - 6.0, dp.y - 6.0, 12.0, 12.0), k.h(dp.x, dp.y) - 1.0, "ch1:lake_told", "lake_shrine:r7_clear", 4.0)
	for i in 6:
		var a := TAU * i / 6.0
		k.pillar(ISLAND.x + cos(a) * 6.5, ISLAND.y + 1.0 + sin(a) * 6.5, 3.5, 0.35, i == 4)
	# Mira's house on the north shore: a tall wooden lookout with a roof deck,
	# the ladder up its east side, and its door toward the dock.
	var deck_y: float = k.deck_house(HUT.x, HUT.y, 0.0, HUT_W, HUT_D, 4.3, Color(1.0, 0.95, 0.86), Color.html("8a5e3e"), {"wall": "wood", "gap": "east"})
	var east: float = HUT.x + HUT_W * 0.5
	k.ladder(east, HUT.y, Vector2(1, 0), k.h(east + 0.4, HUT.y) - 0.1, deck_y)
	var door_z: float = HUT.y + HUT_D * 0.5
	k.door_link(Vector3(HUT.x, k.h(HUT.x, door_z + 0.6), door_z + 0.06), PI, 1.2, 2.2, "lake_house")
	k.entrance("from_lake_house", HUT.x, door_z + 1.8, PI)
	# Up on the deck: a bundle of arrows and a couple of crates.
	k.arrow_pickup(HUT.x - 1.6, HUT.y - 0.8, 10, deck_y)
	k.crate(HUT.x - 2.6, HUT.y - 2.0, 0.3, 0.8, deck_y)
	k.crate(HUT.x - 2.5, HUT.y - 1.1, -0.2, 0.6, deck_y)
	# Archery targets facing the house, and arrows to practice with.
	for t in TARGETS:
		k.archery_target(t.x, t.y, k.yaw_of(Vector2(1, 0)), INF, "lake:archery_prize")
	k.arrow_pickup(-8.0, -50.0, 5)
	k.heart_piece(-19.0, -55.5, "lake:archery_heart", INF, "lake:archery_prize")
	# On the lake bed, deep enough that only a dive reaches it: a little
	# handful of rupees (it held a Piece of Heart until there were fewer).
	var bed := CENTER + Vector2(cos(PI * 0.25), sin(PI * 0.25)) * 38.0
	for i in 3:
		k.collectible("rupee_red", bed.x + (i - 1) * 0.9, bed.y + (0.4 if i == 1 else 0.0), k.h(bed.x, bed.y) + 0.3)
	# The sunken chest on its rock ledge, seven meters down.
	k.block(Vector3(SUNKEN.x, (k.h(SUNKEN.x, SUNKEN.y) + SUNKEN_Y) * 0.5, SUNKEN.y), Vector3(2.4, SUNKEN_Y - k.h(SUNKEN.x, SUNKEN.y), 2.4), 0.3, "rock", Color(0.5, 0.6, 0.65))
	k.chest(SUNKEN.x, SUNKEN.y, k.yaw_of((CENTER - SUNKEN).normalized()), "tunic_tide", true, "lake:tide_chest", "", SUNKEN_Y)
	# At the very bottom of the trench, a Piece of Heart.
	k.heart_piece(TRENCH.x, TRENCH.y, "lake:trench_heart", k.h(TRENCH.x, TRENCH.y) + 0.4)
	var dock_a: Vector3 = k.g(HUT.x + 1.0, HUT.y + 5.0)
	k.bridge(Vector3(dock_a.x, maxf(dock_a.y, 0.6), dock_a.z), Vector3(HUT.x + 1.0, 0.6, HUT.y + 20.0), 2.6, "wood", 0.0, Color(0.8, 0.75, 0.7))
	# Fishing off the end of the dock, out over the lake.
	k._dyn("res://scripts/items/fishing_spot.gd", "FishingSpot", Vector3(HUT.x + 1.0, 0.6, HUT.y + 19.4), PI, {"water_y": WATER_Y}, Node3D.new())
	for i in 3:
		k.barrel(HUT.x - 4.0, HUT.y + 1.5 + i * 1.0)
	k.cave_in_cliff(40, 45, Vector2(1, 1), 3.2, 3.2, "bomb", "bombs_10")
	# Beta 1.4.0: an old fishing store behind an iron grate (the Iron Flail).
	k.cave_in_cliff(-40, -45, Vector2(-1, -1), 3.2, 3.2, "flail", "rupee_gold")
	# Shore trees, reeds and rocks.
	for i in 110:
		var a := r.randf() * TAU
		var dd := r.randf_range(LAKE_R - 4.0, 64.0)
		var x := CENTER.x + cos(a) * dd
		var z := CENTER.y + sin(a) * dd
		if not inside(x, z, 6.0) or in_corridor(x, z, 3.0) or Vector2(x, z).distance_to(HUT) < 8.0 or Vector2(x, z).distance_to(SHORE_A) < 5.0:
			continue
		var near_target := false
		for t in TARGETS:
			near_target = near_target or Vector2(x, z).distance_to(t) < 3.5 or Vector2(x, z).distance_to((t + HUT) * 0.5) < 2.0
		if near_target:
			continue
		var hh := height(x, z)
		if hh < 0.3:
			if i % 3 == 0:
				k.reeds(x, z, 6)
			continue
		match i % 5:
			0, 1:
				if hh > 1.4:
					k.tree_round(x, z, r.randf_range(0.9, 1.4))
				else:
					k.reeds(x, z, 5)
			2:
				k.rock(x, z, r.randf_range(0.5, 1.5))
			3:
				k.bush(x, z, r.randf_range(0.6, 1.1))
			4:
				k.flowers(x, z, 1.8, 6, ["f0f0f0", "f0d040", "80a0f0"])


## Mirror Lake: octoroks out on the water, grass on the beaches, pots by
## Mira's house and signs at the bridge and her door.
func populate(k) -> void:
	k.signpost(SHORE_A.x + 3.0, SHORE_A.y - 3.0, SHORE_A + Vector2(-3, -6), "The bridges lead to\nthe *Lake Shrine*.")
	k.signpost(HUT.x + 2.4, HUT.y + 5.5, HUT + Vector2(2.4, 9.0), "*Mira's House*\nNo visitors.\n(That means you.)")
	for p in [Vector2(-25, 0), Vector2(30, -20), Vector2(-5, 30)]:
		k.enemy("octorok", p.x, p.y, 0.0, {"notice_range": 16.0}, WATER_Y - 0.45)
	for p in [Vector2(HUT.x - 4.4, HUT.y - 1.8), Vector2(HUT.x - 4.4, HUT.y - 2.7)]:
		k.pot(p.x, p.y)
	for c in [Vector2(-50, -20), Vector2(-30, -55), Vector2(40, -45), Vector2(55, 30)]:
		k.shrubs_near(c, 6.0, 5, Color(1, 1, 1), 1.3)
		k.lift_rocks_near(c, 6.0, 1, Color(1, 1, 1), 1.3)
	# The third treasure chart's X: the west shore by the old landing.
	var c3: Vector2 = k.spot(SHORE_A + Vector2(4.0, 6.0), 6.0, 1.2)
	if c3 != Vector2.INF:
		k.dig_spot("chart_3", c3.x, c3.y, TreasureCharts.prize(3))
