extends "res://tools/world/region.gd"
## Desert of Ladhellin: rolling dunes in sandstone walls, flat-topped mesas, an
## oasis with palms, half-buried ruins, and Ladhellin Tower (dungeon 3, sealed)
## with its purple roof on a paved plaza. At the foot of the great south-east
## mesa, the Sun Trial, sealed by a heavy stone only the Bun Bracers lift.

const TOWER := Vector2(18, -12)
const OASIS := Vector2(-28, 26)

var paths: Array = [
	[Vector2(-70, -15), Vector2(-30, -14), Vector2(4, -12)],
	[Vector2(18, 2), Vector2(20, 30), Vector2(20, 65)],
	[Vector2(24, -4), Vector2(44, 2), Vector2(70, 4)],
	# The overgrown track south to the Dark Forest (Chapter IV).
	[Vector2(20, 38), Vector2(36, 48), Vector2(50, 60)],
]
## Where the brambles of the Dark Forest choke the track until the hero
## remembers the legend of the grove (Chapter IV, "ch4:grove_known").
const BRAMBLE := Vector2(50.0, 52.0)


func setup() -> void:
	id = "desert"
	seed_value = 81
	x_min = -65.0
	x_max = 65.0
	z_min = -60.0
	z_max = 60.0
	rim_height = 17.0
	rim_margin = 8.0
	cliff_col = Color(1.15, 0.88, 0.62)
	rock_col = Color.html("b88a5a")
	links = [
		{"to": "field", "p": Vector2(-65, -15), "d": Vector2(1, 0), "w": 6.0, "y": 0.6},
		{"to": "south_road", "p": Vector2(20, 60), "d": Vector2(0, -1), "w": 6.0, "y": 0.6},
		# The old Batela road east, lost in an endless sandstorm until the
		# Order's map shows the way (Chapter III).
		{"to": "forest_of_the_dead", "p": Vector2(65, 4), "d": Vector2(-1, 0), "w": 5.0, "y": 0.6},
		# South-east, into the Dark Forest (Chapter IV).
		{"to": "dark_forest", "p": Vector2(50, 60), "d": Vector2(0, -1), "w": 5.0, "y": 0.6},
	]
	water = [{"rect": Rect2(OASIS.x - 11, OASIS.y - 10, 22, 20), "y": 0.0, "col": Color(0.3, 0.6, 0.75, 0.75)}]
	mood = {
		"sky_top": Color.html("5a88d0"), "sky_mid": Color.html("a0b8d8"), "sky_horizon": Color.html("f2e2c4"),
		"cloud": Color.html("fff8ec"), "cloud_amount": 0.15,
		"fog": Color.html("e8d8b8"), "fog_begin": 35.0, "fog_end": 145.0,
		"ambient": Color.html("8a7a62"), "sun": Color.html("fff0d0"), "sun_energy": 1.1, "sun_rot": Vector3(-65, -20, 0),
		"fill": Color.html("8a6a5a"),
		"horizon": Color.html("c8a882"), "hill_height": 12.0, "particles": "dust",
		"far": [
			{"type": "mesa", "yaw": 70.0, "w": 50.0, "h": 18.0, "col": Color.html("d0a882")},
			{"type": "mesa", "yaw": 140.0, "w": 70.0, "h": 12.0, "col": Color.html("c89e7a")},
			{"type": "mesa", "yaw": 220.0, "w": 40.0, "h": 22.0, "col": Color.html("d4ae88")},
		],
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	# Ridged dunes.
	var n := noise.get_noise_2d(x * 1.3 + z * 0.4, z * 0.9)
	var h := 0.6 + pow(1.0 - absf(n), 3.0) * 4.0
	h = lerpf(h, 0.8, 1.0 - smoothstep(13.0, 18.0, Vector2(x, z).distance_to(TOWER)))
	h = lerpf(h * 0.5 + 0.4, h, smoothstep(2.0, 9.0, path_dist(x, z)))
	var d := Vector2(x, z).distance_to(OASIS)
	if d < 12.0:
		h = lerpf(-0.9, h, smoothstep(5.0, 12.0, d))
	return h


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	if Vector2(x, z).distance_to(TOWER) < 11.0:
		return "stone"
	if Vector2(x, z).distance_to(OASIS) < 12.0 and h < 0.4:
		return super.surface_at(x, z, h, r)
	return "sand"


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var dt := Vector2(x, z).distance_to(TOWER)
	if dt < 11.0:
		var ring := int(dt / 1.8) % 2
		return pick(r, ["d8c09a", "e0c8a2"] if ring == 0 else ["c8ac84", "d0b48c"])
	var dox := Vector2(x, z).distance_to(OASIS)
	if dox < 12.0 and h < 0.4:
		return pick(r, ["8a7a52", "96865a"]) if h < 0.05 else pick(r, ["7a9a4a", "88a650"])
	if path_dist(x, z) < 2.2 + r.randf_range(-0.5, 0.5):
		return pick(r, ["c49e6a", "cca672"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	var sand := Color.html("dcb67c").lerp(Color.html("eccc94"), clampf(b + 0.5 + r.randf_range(-0.1, 0.1), 0.0, 1.0))
	return sand.darkened(clampf(0.25 - h * 0.05, 0.0, 0.2))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var sand := Color(1, 0.97, 0.92)
	# Ladhellin Tower on its plaza, flanked by statues, door toward the west road.
	k.platform(TOWER.x, TOWER.y, Vector2(20.0, 20.0), 1.05, "sandstone", sand)
	k.tower(TOWER.x, TOWER.y, 5.2, 26.0, "sandstone", sand, Color.html("7a4aa8"), k.yaw_of(Vector2(-1, 0)),
		{"sides": 12, "roof_h": 9.0, "y": 1.05, "seal": "open"})
	# The door into the tower, framed in sandstone, facing the west road.
	var door_x := TOWER.x - 5.2 * 1.04
	var frame = k._tmp()
	for sz in [-1.0, 1.0]:
		frame.box(Vector3(door_x - 0.05, 1.05 + 1.6, TOWER.y + sz * 1.3), Vector3(0.6, 3.2, 0.5), sand * Color(0.95, 0.88, 0.75))
	frame.box(Vector3(door_x - 0.05, 1.05 + 3.45, TOWER.y), Vector3(0.65, 0.5, 3.1), sand * Color(0.95, 0.88, 0.75))
	k.merge(frame, "sandstone")
	k.door_link(Vector3(door_x - 0.02, 1.05, TOWER.y), k.yaw_of(Vector2(-1, 0)), 1.8, 2.8, "ladhellin_tower", "from_desert", Color(0.9, 0.8, 0.6))
	k.entrance("from_ladhellin_tower", door_x - 2.2, TOWER.y, k.yaw_of(Vector2(-1, 0)))
	k.entrance("warp_ladhellin_tower", door_x - 2.4, TOWER.y + 1.5, k.yaw_of(Vector2(-1, 0)))
	for sz in [-1.0, 1.0]:
		k.statue(TOWER.x - 8.0, TOWER.y + sz * 3.5, k.yaw_of(Vector2(-1, 0)), 1.1, "sandstone", 1.05)
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		if absf(cos(a) + 1.0) < 0.3:
			continue
		k.pillar(TOWER.x + cos(a) * 9.0, TOWER.y + sin(a) * 9.0, 5.0, 0.55, i % 2 == 0, "sandstone", 1.05)
	k.stairs(TOWER.x - 12.5, TOWER.y, -PI * 0.5, 6.0, 2.5, 1.1 - k.h(TOWER.x - 12.5, TOWER.y), "sandstone")
	# Mesas and a natural arch.
	for m in [[Vector2(-40, -38), 9.0, 15.0], [Vector2(45, 30), 8.0, 12.0], [Vector2(-10, 40), 6.0, 10.0], [Vector2(48, -40), 7.0, 18.0], [Vector2(-48, 8), 5.0, 9.0]]:
		k.spire(m[0].x, m[0].y, m[1], m[2], "sandstone", Color(1.08, 0.86, 0.66), 0.85, 9)
	k.spire(-15, -38, 2.2, 9.0, "sandstone", Color(1.05, 0.85, 0.66), 0.9, 6)
	k.spire(-5, -40, 2.2, 9.5, "sandstone", Color(1.05, 0.85, 0.66), 0.9, 6)
	k.block(Vector3(-10, k.h(-10, -39) + 10.2, -39), Vector3(15.0, 2.2, 4.0), 0.2, "sandstone", Color(1.05, 0.85, 0.66))
	# The Sun Trial: a carved doorway in the great mesa's west foot, a sun
	# disc over it, and a heavy stone before it.
	var trial := Vector2(40.6, -40.0)
	k.spring_cave(trial.x, trial.y, k.yaw_of(Vector2(-1, 0)), "sun_trial", "", {"tint": Color(1.1, 0.9, 0.62), "w": 3.2, "h": 3.6})
	var disc = k._tmp(false)
	disc.push(Transform3D(Basis(Vector3.UP, k.yaw_of(Vector2(-1, 0))) * Basis(Vector3.RIGHT, PI / 2.0), k.g(trial.x, trial.y) + Vector3(-0.6, 5.0, 0)))
	disc.prism(Vector3(0, -0.05, 0), 0.9, Vector3(0, 0.05, 0), 0.9, 12, Color.html("e8b838"))
	for i in 8:
		var a := TAU * i / 8.0
		disc.box(Vector3(cos(a) * 1.15, 0.0, sin(a) * 1.15), Vector3(0.2, 0.08, 0.2), Color.html("f0c850"))
	disc.pop()
	k.merge(disc, "char")
	# Two great stones across the doorway, set close in its mouth; only the
	# Bun Bracers shift them, and until both are gone nothing gets past them
	# into the dark (the stones are round: a bar behind them fills the gaps).
	k.heavy_rock(trial.x - 0.9, trial.y - 0.82, "sun_trial:stone")
	k.heavy_rock(trial.x - 0.9, trial.y + 0.82, "sun_trial:stone2")
	k.flag_all(["sun_trial:stone", "sun_trial:stone2"], "sun_trial:open")
	k.flag_barrier(Vector3(trial.x - 0.6, k.h(trial.x - 0.6, trial.y) + 1.6, trial.y), Vector3(1.6, 3.2, 4.4), 0.0, "sun_trial:open")
	k.entrance("warp_sun_trial", trial.x - 4.5, trial.y + 1.5, k.yaw_of(Vector2(-1, 0)))
	# The old east road: a wall of sand the wind never lets fall, until the
	# Order's map (the Sun Trial) shows the way through it.
	# Bank to bank: the road's banks either side are walkable, and a narrower
	# wall could be walked round up them (Beta 1.5.1).
	k.dust_wall(56.0, 4.0, k.yaw_of(Vector2(-1, 0)), 26.0, "ch2:trail_found")
	for sz in [-1.0, 1.0]:
		k.pillar(52.0, 4.0 + sz * 5.5, 4.5, 0.55, sz > 0.0, "sandstone")
	# The brambles over the Dark Forest track: black thorns, solid, until the
	# hero remembers the legend of the grove.
	var br = k._tmp()
	# They choke the track from bank to bank (its floor is 10 m across and
	# its banks rise 5 m either side; Beta 1.5.1 widened them up the banks).
	for i in 30:
		var a := TAU * i / 30.0
		var bx := BRAMBLE.x + cos(a) * 11.0
		br.icosa(Vector3(bx, k.h(bx, BRAMBLE.y) + 1.0 + (i % 3) * 0.5, BRAMBLE.y + sin(a) * 0.8), Vector3(1.3, 1.2, 0.9), 0.3, Color.html("2a2a24"))
		br.prism(Vector3(BRAMBLE.x + cos(a) * 10.0, k.h(bx, BRAMBLE.y) + 1.2, BRAMBLE.y), 0.06, Vector3(BRAMBLE.x + cos(a) * 11.6, k.h(bx, BRAMBLE.y) + 2.4, BRAMBLE.y - 0.6), 0.0, 4, Color.html("4a3a2a"))
	k.flag_barrier(Vector3(BRAMBLE.x, k.h(BRAMBLE.x, BRAMBLE.y) + 4.5, BRAMBLE.y), Vector3(24.0, 10.0, 2.0), 0.0, "ch4:grove_known", br, "char")
	# Serielye's Spring: a cave mouth in a heap of dark rock under the arch.
	k.spring_cave(-10.0, -41.5, k.yaw_of(Vector2(0, 1)), "spring_serielye", "", {"mound": true, "tint": Color(0.8, 0.55, 0.5)})
	# The oasis.
	for i in 7:
		var a := TAU * i / 7.0 + r.randf() * 0.3
		k.tree_palm(OASIS.x + cos(a) * 9.5, OASIS.y + sin(a) * 8.5, r.randf_range(0.8, 1.15))
	for i in 6:
		var a := TAU * i / 6.0
		k.reeds(OASIS.x + cos(a) * 6.0, OASIS.y + sin(a) * 5.5, 4, Color.html("7a8a3a"))
	# Ruins: broken walls and columns half-buried in sand.
	k.wall_line([Vector2(-30, 0), Vector2(-20, 2), Vector2(-18, 10)], 2.2, 1.0, "sandstone", sand)
	k.wall_line([Vector2(30, 20), Vector2(38, 14)], 1.6, 1.0, "sandstone", sand)
	for p in [Vector2(-24, 6), Vector2(-27, 9), Vector2(34, 10), Vector2(0, 20), Vector2(4, 24)]:
		k.pillar(p.x, p.y, 4.0, 0.6, true, "sandstone")
	# Cacti, dry bushes, rocks and bones.
	for i in 80:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		if path_dist(x, z) < 3.0 or in_corridor(x, z, 3.0) or Vector2(x, z).distance_to(TOWER) < 14.0 or Vector2(x, z).distance_to(OASIS) < 12.0:
			continue
		match i % 5:
			0, 1:
				k.cactus(x, z, r.randf_range(0.7, 1.3))
			2:
				k.bush(x, z, r.randf_range(0.5, 0.9), Color(0.85, 0.7, 0.45))
			3:
				k.rock(x, z, r.randf_range(0.5, 1.4), "sandstone", true, Color(1.05, 0.88, 0.7))
			4:
				k.rock(x, z, 0.25, "char", false, Color.html("e8e0d0"))


## The desert: leevers under the sand, a warning sign, pots in the ruins and
## dry scrub.
func populate(k) -> void:
	k.signpost(-54, -10, Vector2(-48, -12), "*Desert of Ladhellin*\nTravelers beware!\nSand Spinners lurk beneath the sand.")
	k.signpost(47, 9, Vector2(40, 8), "*East: the old Batela road*\nClosed by the Eternal Sandstorm.\nNo one has passed in years.")
	for c in [Vector2(-15, -15), Vector2(10, 25), Vector2(35, -35), Vector2(-35, -25), Vector2(40, 10)]:
		k.enemies_near("leever", c, 12.0, 1)
	for p in [Vector2(-25, 4), Vector2(-21, 4.5), Vector2(33, 13)]:
		k.pot(p.x, p.y)
	k.pot(-26.5, 7.0, "rupee_red")
	for c in [OASIS + Vector2(12, -4), Vector2(-45, 35), Vector2(30, 45)]:
		k.shrubs_near(c, 5.0, 4, Color(1.1, 0.95, 0.55))
		k.lift_rocks_near(c, 6.0, 2, Color(1.2, 1.0, 0.7))
	k.collectible("rupee_red", -10, -39, k.h(-10, -39) + 11.6)
	k.signpost(42.0, 44.0, Vector2(44.0, 50.0), "*South-east: the Dark Forest*\nNo road. No return.\n\nThe brambles grow back\nas fast as they are cut.")
	# The second treasure chart's X, in the oasis palms' shade.
	k.dig_spot("chart_2", OASIS.x + 11.0, OASIS.y - 9.0, TreasureCharts.prize(2), {"soil": "sand"})
	# On top of the rock arch, a Piece of Heart; a wooden target pegged under
	# the arch's south rim is the way up (the Hookshot).
	var top: float = k.h(-10, -39) + 11.3
	k.heart_piece(-13.0, -39.0, "desert:arch_heart", top)
	# Chapter V's old-world secret: a great stone in the north cliffs (the Gauntlets).
	k.cave_in_cliff(-30, -36, Vector2(0, -1), 3.2, 3.2, "great", "heart_piece")
	# Beta 1.4.0: a Ladhellin strongroom behind an iron grate (the Iron Flail).
	k.cave_in_cliff(-20, 30, Vector2(0, 1), 3.2, 3.2, "flail", "rupee_purple")
	k.hook_target(Vector3(-10.0, top - 0.95, -36.92), PI)
