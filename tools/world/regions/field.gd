extends "res://tools/world/region.gd"
## Bunsriel Fields: the open hub of Haven (about Hyrule Field's size). A snowmelt
## river from the Northeastern Cliffs crosses its north half to the marshes;
## dirt roads run from a central crossroads to every region.

const HUB := Vector2(0, 10)
const RIVER: Array[Vector2] = [
	Vector2(150, -64), Vector2(112, -64), Vector2(95, -62), Vector2(70, -50), Vector2(40, -43),
	Vector2(10, -46), Vector2(-20, -40), Vector2(-50, -28), Vector2(-80, -18), Vector2(-100, -14), Vector2(-150, -14),
]
const WATER_Y := -0.5
const POND := Vector2(32, 70)
const TREE_HILL := Vector2(-45, 40)
const LOOKOUT := Vector2(55, -12)
## Westmarch Fortress, one of the Citadel of Haven's three fortresses, on the
## field's south-west hills: its walls, and the gate into the dungeon
## (shut until the war, Chapter IV).
const WESTMARCH := Rect2(-104, 50, 20, 24)
const WESTMARCH_GATE := Vector2(-84, 62)

var paths: Array = [
	[HUB, Vector2(2, -20), Vector2(0, -60), Vector2(0, -105)],                                   # castle town
	[HUB, Vector2(-25, 2)],
	[Vector2(-25, 2), Vector2(-45, -18), Vector2(-56, -30), Vector2(-68, -55), Vector2(-80, -105)],  # forest
	[Vector2(-25, 2), Vector2(-70, -3), Vector2(-120, -4)],                                       # marsh
	[HUB, Vector2(-20, 20), Vector2(-55, 62), Vector2(-75, 105)],                                 # southern fields
	[HUB, Vector2(-3, 55), Vector2(-5, 105)],                                                     # village
	[HUB, Vector2(35, 45), Vector2(70, 75), Vector2(80, 105)],                                    # south road
	[HUB, Vector2(45, 18), Vector2(80, 22), Vector2(120, 25)],                                    # desert
	[Vector2(45, 18), Vector2(68, -15), Vector2(72, -48), Vector2(92, -68), Vector2(120, -72)],    # cliffs
]


func setup() -> void:
	id = "field"
	seed_value = 11
	x_min = -115.0
	x_max = 115.0
	z_min = -100.0
	z_max = 100.0
	cell = 3.0
	tex_size = 512
	rim_height = 18.0
	rim_margin = 9.0
	rim_run = 6.0
	cliff_col = Color(0.78, 0.74, 0.64)
	rock_col = Color.html("7a7266")
	links = [
		{"to": "castle_town", "p": Vector2(0, -100), "d": Vector2(0, 1), "w": 7.0, "y": 0.4},
		{"to": "forest", "p": Vector2(-80, -100), "d": Vector2(0, 1), "w": 6.0, "y": 0.6},
		{"to": "cliffs", "p": Vector2(115, -72), "d": Vector2(-1, 0), "w": 9.0, "y": 0.5},
		{"to": "desert", "p": Vector2(115, 25), "d": Vector2(-1, 0), "w": 7.0, "y": 0.6},
		{"to": "south_road", "p": Vector2(80, 100), "d": Vector2(0, -1), "w": 6.0, "y": 0.5},
		{"to": "village", "p": Vector2(-5, 100), "d": Vector2(0, -1), "w": 6.0, "y": 0.5},
		{"to": "southern_fields", "p": Vector2(-75, 100), "d": Vector2(0, -1), "w": 7.0, "y": 0.5},
		{"to": "marsh", "p": Vector2(-115, -6), "d": Vector2(1, 0), "w": 9.0, "y": 0.4},
	]
	water = [{"rect": Rect2(-140, -125, 280, 250), "y": WATER_Y, "col": Color(0.32, 0.55, 0.85, 0.75)}]
	mood = {
		"sky_top": Color.html("2a58d4"), "sky_mid": Color.html("5a8ae6"), "sky_horizon": Color.html("bcd6f4"),
		"cloud": Color.html("ffffff"), "cloud_amount": 0.45,
		"fog": Color.html("c4d8ee"), "fog_begin": 45.0, "fog_end": 175.0,
		"ambient": Color.html("6c7290"), "sun": Color.html("fff2dc"), "sun_rot": Vector3(-52, 35, 0),
		"horizon": Color.html("8494b8"), "hill_height": 14.0,
		"far": [
			{"type": "castle", "yaw": 0.0, "w": 70.0, "h": 34.0, "col": Color.html("8c94b6"), "roof": Color.html("4a5aa8")},
			{"type": "peak", "yaw": 48.0, "w": 130.0, "h": 75.0, "col": Color.html("9aa2c2"), "snow": true},
			{"type": "mesa", "yaw": 100.0, "w": 60.0, "h": 22.0, "col": Color.html("c8aa92")},
			{"type": "peak", "yaw": 310.0, "w": 90.0, "h": 28.0, "col": Color.html("5a7a6a")},
		],
	}


func path_dist(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(p, pts))
	return best


func river_dist(x: float, z: float) -> float:
	return poly_dist(Vector2(x, z), RIVER)


func base_height(x: float, z: float) -> float:
	var hills := noise.get_noise_2d(x, z) * 4.0 + 1.6
	hills += bump(x, z, TREE_HILL, 30.0) * 7.0
	hills += bump(x, z, LOOKOUT, 22.0) * 6.5
	hills += bump(x, z, Vector2(62, 62), 26.0) * 4.5
	hills += bump(x, z, Vector2(-72, -62), 24.0) * 5.0
	hills += bump(x, z, Vector2(-92, 45), 22.0) * 4.0
	var damp := lerpf(0.3, 1.0, smoothstep(3.0, 14.0, path_dist(x, z)))
	return 0.3 + maxf(hills, 0.0) * damp


func height(x: float, z: float) -> float:
	var h := super.height(x, z)
	# The river and the pond are carved last, so they cut through the exit corridors too.
	var dr := river_dist(x, z)
	if dr < 9.0:
		h = lerpf(-1.3, h, smoothstep(3.0, 9.0, dr))
	var dp := Vector2(x, z).distance_to(POND)
	if dp < 12.0:
		h = lerpf(-1.1, h, smoothstep(5.0, 12.0, dp))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var d := path_dist(x, z) + r.randf_range(-0.5, 0.5)
	if d < 2.4:
		return pick(r, ["8a6a3c", "967444", "a2804c"])
	var dr := minf(river_dist(x, z), Vector2(x, z).distance_to(POND) - 3.0)
	if h < 0.1 and dr < 9.0:
		return pick(r, ["6e6446", "7a6e4c", "86785a"])
	var blotch := noise.get_noise_2d(x * 2.5, z * 2.5)
	var grass := Color.html("4e8a2c").lerp(Color.html("6aac40"), clampf(blotch * 0.9 + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))
	if d < 3.4 and r.randf() < 0.5:
		grass = grass.lerp(Color.html("8a6a3c"), 0.5)
	# Darker grass toward the forest, sun-dried toward the desert.
	grass = grass.lerp(Color.html("3a6a2a"), clampf(1.0 - Vector2(x, z).distance_to(Vector2(-100, -90)) / 70.0, 0.0, 0.6))
	grass = grass.lerp(Color.html("b0a060"), clampf(1.0 - Vector2(x, z).distance_to(Vector2(120, 25)) / 50.0, 0.0, 0.75))
	if h > 12.0:
		grass = grass.darkened(0.15)
	if r.randf() < 0.012:
		return Color.html("f0f0e0") if r.randf() < 0.5 else Color.html("e8d040")
	return grass


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# Bridges where the roads cross the river.
	k.bridge(k.g(1.5, -53), k.g(0.5, -38), 6.0, "stone", 1.0, Color(1, 1, 1), "stone")
	k.bridge(k.g(-59, -33.5), k.g(-51, -19.5), 4.0, "wood", 0.7)
	k.bridge(k.g(70, -57), k.g(72.5, -41), 4.0, "wood", 0.7)
	# The castle road enters the town through its outer gatehouse.
	k.gatehouse(0, -94, 0.0, 9.0, 11.0, "stone", Color(0.95, 0.93, 0.9), Color.html("4a5aa8"))
	k.wall_line([Vector2(6.1, -94), Vector2(30, -96), Vector2(52, -99)], 9.0, 2.2, "stone", Color(0.95, 0.93, 0.9), true)
	k.wall_line([Vector2(-6.1, -94), Vector2(-30, -96), Vector2(-50, -99)], 9.0, 2.2, "stone", Color(0.95, 0.93, 0.9), true)
	k.banner(-6.3, k.h(0, -94) + 8.5, -92.2, 0.0, Color.html("3048a8"))
	k.banner(6.3, k.h(0, -94) + 8.5, -92.2, 0.0, Color.html("3048a8"))
	# Haven Village's timber gate.
	k.gatehouse(-5, 93, PI, 8.0, 6.5, "wood", Color(0.95, 0.9, 0.85), Color.html("a04a30"))
	# A ranch-style fence and gate toward the Southern Fields.
	k.fence([Vector2(-110, 82), Vector2(-96, 86), Vector2(-84, 88)], Color(0.95, 0.9, 0.85))
	k.fence([Vector2(-66, 88), Vector2(-50, 84), Vector2(-38, 80)], Color(0.95, 0.9, 0.85))
	for sx in [-1.0, 1.0]:
		k.pillar(-75 + sx * 8.0, 89, 3.0, 0.35, false, "wood")
	# Sandstone markers toward the desert, orange rock toward the cliffs, dead trees by the marsh.
	for z in [15.0, 35.0]:
		k.spire(103, z, 2.0, 7.0, "sandstone", Color(1, 0.95, 0.9))
	for z in [-86.0, -58.0]:
		k.spire(104, z, 2.6, 9.0, "rock", Color(1.15, 0.8, 0.6))
	for z in [-22.0, 8.0, 14.0]:
		k.tree_dead(-104 + r.randf_range(-2, 2), z, 1.1)
	for x in [68.0, 92.0]:
		k.spire(x, 92, 2.4, 8.0, "rock", Color(1.05, 0.85, 0.7))
	# Forest edge: big trees flanking the path north-west.
	for p in [Vector2(-90, -88), Vector2(-70, -88), Vector2(-94, -76), Vector2(-64, -80), Vector2(-100, -66)]:
		k.tree_round(p.x, p.y, 1.6, Color(0.8, 0.9, 0.8))
	# The lone great tree on its hill, and the stone ring on the lookout hill.
	k.tree_round(TREE_HILL.x, TREE_HILL.y, 2.4)
	k.flowers(TREE_HILL.x + 4, TREE_HILL.y + 3, 3.5, 14)
	for i in 9:
		var a := TAU * i / 9.0
		var px := LOOKOUT.x + cos(a) * 7.5
		var pz := LOOKOUT.y + sin(a) * 7.5
		k.pillar(px, pz, 4.5, 0.6, i % 3 == 1)
	k.platform(LOOKOUT.x, LOOKOUT.y, Vector2(4.0, 4.0), k.h(LOOKOUT.x, LOOKOUT.y) + 0.4)
	# The pond in the south-east.
	for i in 8:
		var a := TAU * i / 8.0 + r.randf() * 0.4
		k.reeds(POND.x + cos(a) * 7.0, POND.y + sin(a) * 6.5, 5)
	for i in 6:
		k.lily(POND.x + r.randf_range(-4, 4), POND.y + r.randf_range(-3.5, 3.5), WATER_Y)
	# A sealed cave in the eastern cliffs, and another in the north-west hills.
	# The caves keep the flags they always had, named here so the field at war
	# (which builds this same field) shares them: a cave opened, or its prize
	# taken, before the war stays so through it (Beta 1.6.1).
	k.cave_in_cliff(90, 60, Vector2(1, 0), 3.4, 3.4, "bomb", "heart_piece", "field:cave_107_60")
	# A hollow in the north-west hills, a heavy rock in its mouth (the Bun Bracers).
	k.cave_in_cliff(-90, 30, Vector2(-1, 0), 3.0, 3.0, "heavy", "rupee_purple", "field:cave_-105_30")
	# Chapter V's old-world secret: a great stone (the Questlord's Gauntlets).
	k.cave_in_cliff(60, -84, Vector2(0, -1), 3.4, 3.4, "great", "bomb_bag_up", "field:cave_60_-89")
	# Beta 1.4.0: an old iron grate only the Iron Flail bursts.
	k.cave_in_cliff(-60, -84, Vector2(0, -1), 3.2, 3.2, "flail", "rupee_gold", "field:cave_-60_-90")
	_westmarch(k)
	# Scattered trees, bushes and rocks, kept off the roads, river and corridors.
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 4000:
		tries += 1
		var x := r.randf_range(x_min + 12, x_max - 12)
		var z := r.randf_range(z_min + 12, z_max - 12)
		if not _clear(x, z, 7.0):
			continue
		var dens := noise.get_noise_2d(x * 1.7 + 100, z * 1.7) + (0.35 if x < -40 and z < 0 else 0.0)
		if dens < 0.05:
			continue
		if r.randf() < 0.75:
			k.tree_round(x, z, r.randf_range(0.9, 1.4), Color(1, 1, 1).lerp(Color(0.85, 1.0, 0.8), r.randf()))
		else:
			k.bush(x, z, r.randf_range(0.9, 1.6))
		placed += 1
	for i in 70:
		var x := r.randf_range(x_min + 12, x_max - 12)
		var z := r.randf_range(z_min + 12, z_max - 12)
		if _clear(x, z, 4.0):
			k.rock(x, z, r.randf_range(0.3, 1.5))
	for i in 40:
		var x := r.randf_range(x_min + 12, x_max - 12)
		var z := r.randf_range(z_min + 12, z_max - 12)
		if _clear(x, z, 3.0):
			k.bush(x, z, r.randf_range(0.6, 1.1))
	for i in 30:
		var x := r.randf_range(x_min + 12, x_max - 12)
		var z := r.randf_range(z_min + 12, z_max - 12)
		if _clear(x, z, 3.0):
			k.flowers(x, z, 2.0, 7)


func _clear(x: float, z: float, pad: float) -> bool:
	return path_dist(x, z) > pad and river_dist(x, z) > pad + 5.0 and not in_corridor(x, z, pad) \
		and Vector2(x, z).distance_to(POND) > 13.0 and Vector2(x, z).distance_to(LOOKOUT) > 11.0 \
		and Vector2(x, z).distance_to(TREE_HILL) > 6.0 and not WESTMARCH.grow(7.0).has_point(Vector2(x, z))


## Westmarch Fortress: gray curtain walls with a tower at each corner and a
## gatehouse on the east, facing the field.
func _westmarch(k) -> void:
	var r := WESTMARCH
	var stone := Color(0.82, 0.8, 0.78)
	var gt := WESTMARCH_GATE
	k.wall_line([Vector2(gt.x, gt.y - 3.5), Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.position.y),
		Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(gt.x, gt.y + 3.5)], 8.0, 1.6, "stone", stone, true)
	for p in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		k.tower(p.x, p.y, 2.8, 12.0, "stone", stone, Color.html("3a4a8a"))
	k.gatehouse(gt.x, gt.y, PI / 2.0, 5.0, 9.0, "stone", stone, Color.html("3a4a8a"))
	k.banner(gt.x + 1.7, k.h(gt.x, gt.y) + 7.5, gt.y - 3.2, -PI / 2.0, Color.html("3048a8"))
	k.banner(gt.x + 1.7, k.h(gt.x, gt.y) + 7.5, gt.y + 3.2, -PI / 2.0, Color.html("3048a8"))
	var gy: float = k.h(gt.x, gt.y) - 0.2
	# Open once Haven has held through the night (Beta 1.5.1: it opened with
	# the war, which let the camps and the siege be skipped).
	k.door_link(Vector3(gt.x - 0.6, gy, gt.y), -PI / 2.0, 4.0, 4.6, "westmarch_fortress", "", Color(0.7, 0.6, 0.5), "ch4:siege_won", "",
		"The great gate of Westmarch Fortress is shut and barred.\nA sentry calls down from the wall: \"Move along! The garrison keeps its gate shut in these times.\"")
	k.entrance("from_westmarch_fortress", gt.x + 5.0, gt.y, -PI / 2.0)
	# The keep's bulk inside the walls, seen over them.
	var c := r.get_center()
	k.block(Vector3(c.x - 2.0, k.h(c.x, c.y) + 6.0, c.y), Vector3(10.0, 12.0, 12.0), 0.0, "stone", stone.darkened(0.08))


## Life on the field: grass along the roads, tektites on the hills, octoroks
## in the river, snapping plants at the forest's edge, signs at the forks and
## a few rupees for the curious.
func populate(k) -> void:
	k.signpost(4.5, 13.5, HUB, "*Bunsriel Fields*\nNorth: Old Castle Town\nSouth: Haven Village\n\nWest: The Forest, West Marshlands\nEast: Desert of Ladhellin\nNorth-east: Northeastern Cliffs\n\nSouth-east: The South Road\nto Mirror Lake")
	k.signpost(-29, 6, Vector2(-20, 6), "North-west: *The Forest*\nWest: *West Marshlands*")
	k.signpost(49, 14, Vector2(42, 10), "East: *Desert of Ladhellin*\nNorth: *Northeastern Cliffs*")
	k.signpost(38, 41, Vector2(30, 40), "South-east: *The South Road*\nIt leads on to Mirror Lake.")
	for c in [Vector2(-12, 30), Vector2(14, -10), Vector2(-40, 20), Vector2(30, 30), Vector2(-60, 70), Vector2(60, 5),
			Vector2(-10, 75), Vector2(-75, -20), Vector2(80, -40), Vector2(20, -75), Vector2(-50, -50), Vector2(85, 70)]:
		k.shrubs_near(c, 6.0, 7)
	# Small rocks to lift and throw (En_Ishi), by the roads and the stone ring.
	for c in [Vector2(-12, 30), Vector2(30, 30), Vector2(60, 5), Vector2(-50, -50), Vector2(20, -75), Vector2(-75, -20)]:
		k.lift_rocks_near(c, 7.0, 2)
	# Two heavy rocks (the Bun Bracers) with rupees under them.
	k.heavy_rock(LOOKOUT.x - 3.0, LOOKOUT.y + 12.0, "", INF, 12)
	k.heavy_rock(TREE_HILL.x - 8.0, TREE_HILL.y + 7.0, "", INF, 12)
	k.enemies_near("tektite", LOOKOUT, 18.0, 3)
	k.enemies_near("tektite", Vector2(62, 62), 14.0, 2)
	k.enemies_near("tektite", TREE_HILL + Vector2(10, -6), 12.0, 1)
	k.enemies_near("snapper", Vector2(-82, -78), 10.0, 3)
	for p in [Vector2(-20, -40), Vector2(40, -43), Vector2(-80, -18)]:
		var q: Vector2 = RIVER[0]
		var best := INF
		for i in RIVER.size() - 1:
			var a: Vector2 = RIVER[i]
			var b: Vector2 = RIVER[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var c: Vector2 = a + ab * t
			if c.distance_to(p) < best:
				best = c.distance_to(p)
				q = c
		k.enemy("octorok", q.x, q.y, 0.0, {}, WATER_Y - 0.45)
	k.collectible("rupee_red", LOOKOUT.x, LOOKOUT.y, k.h(LOOKOUT.x, LOOKOUT.y) + 0.45)
	# The first treasure chart's X: at the great tree's roots, on the castle side.
	k.dig_spot("chart_1", TREE_HILL.x + 1.5, TREE_HILL.y - 5.5, TreasureCharts.prize(1))
	# Horseback archery: five targets along the north side of the desert road.
	# Hit every one (from the saddle is the fun way) and a Piece of Heart turns up.
	k.signpost(44.0, 24.5, Vector2(44.0, 30.0), "*Horseback Archery*\nHit all five targets along\nthe road for a prize!")
	for i in 5:
		var x := 50.0 + i * 7.0
		var z := 18.0 + (x - 45.0) / 35.0 * 4.0 - 8.0
		k.archery_target(x, z, PI, INF, "field:archery_prize", true)
	k.heart_piece(84.0, 14.0, "field:archery_heart", INF, "field:archery_prize")
	for i in 3:
		var a := TAU * i / 3.0
		k.collectible("rupee_blue", TREE_HILL.x + cos(a) * 3.5, TREE_HILL.y + sin(a) * 3.5)
