extends "res://tools/world/region.gd"
## The South Road: an old trade road through a red-rock canyon, from the field
## (and a branch from the desert) east to Mirror Lake. It crosses a deep gorge
## on a railed bridge, passes a ruined watchtower and a broken wagon, and ends
## at a sealed cave (from the blueprint).

const GORGE_HALF := 7.0

var road: Array[Vector2] = [Vector2(-55, -35), Vector2(-50, -5), Vector2(-22, 4), Vector2(-9, 0), Vector2(9, 0), Vector2(25, -2), Vector2(55, 8), Vector2(85, 4)]
var branch: Array[Vector2] = [Vector2(25, -2), Vector2(45, -10), Vector2(45, -35)]


func setup() -> void:
	id = "south_road"
	seed_value = 111
	x_min = -80.0
	x_max = 80.0
	z_min = -28.0
	z_max = 28.0
	rim_height = 20.0
	rim_margin = 6.0
	rim_run = 5.0
	cliff_col = Color(1.1, 0.72, 0.56)
	rock_col = Color.html("9a5a40")
	links = [
		{"to": "field", "p": Vector2(-55, -28), "d": Vector2(0, 1), "w": 5.0, "y": 0.6},
		{"to": "desert", "p": Vector2(45, -28), "d": Vector2(0, 1), "w": 5.0, "y": 0.6},
		{"to": "lake", "p": Vector2(80, 4), "d": Vector2(-1, 0), "w": 5.0, "y": 0.6},
	]
	water = [{"rect": Rect2(-GORGE_HALF - 2, -18, GORGE_HALF * 2 + 4, 36), "y": -20.0, "col": Color(0.3, 0.5, 0.7, 0.85)}]
	mood = {
		"sky_top": Color.html("2a58d0"), "sky_mid": Color.html("6a92e0"), "sky_horizon": Color.html("dae0ee"),
		"cloud": Color.html("ffffff"), "cloud_amount": 0.3,
		"fog": Color.html("d8d0c8"), "fog_begin": 40.0, "fog_end": 150.0,
		"ambient": Color.html("7a6860"), "sun": Color.html("fff0dc"), "sun_rot": Vector3(-50, 60, 0),
		"fill": Color.html("6a5a6a"),
		"horizon": Color.html("a0807a"), "hill_height": 26.0,
	}


func road_dist(x: float, z: float) -> float:
	return minf(poly_dist(Vector2(x, z), road), poly_dist(Vector2(x, z), branch))


func base_height(x: float, z: float) -> float:
	var h := 0.6 + noise.get_noise_2d(x * 2.0, z * 2.0) * 1.5 + 0.8
	h = lerpf(0.6, h, smoothstep(2.5, 9.0, road_dist(x, z)))
	return h


func height(x: float, z: float) -> float:
	var h := super.height(x, z)
	# A deep gorge splits the canyon floor (falling in voids out, as in OoT).
	var g := 1.0 - smoothstep(GORGE_HALF - 1.0, GORGE_HALF + 0.5, absf(x + sin(z * 0.15) * 1.0))
	# It ends in sheer walls inside the canyon instead of cutting through the rim.
	g *= 1.0 - smoothstep(14.0, 17.0, absf(z))
	return lerpf(h, -26.0 + h * 0.3, g)


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if road_dist(x, z) < 2.4 + r.randf_range(-0.4, 0.4):
		return pick(r, ["b49064", "be9a6c", "a8865a"])
	if h < -5.0:
		return pick(r, ["6a4436", "5a3a2e"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	return Color.html("9a6a48").lerp(Color.html("b8885a"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0)) \
		if b > -0.2 else Color.html("7a7a42").lerp(Color.html("8a8448"), r.randf())


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	k.bridge(Vector3(-10.5, 0.6, 0), Vector3(10.5, 0.6, 0), 4.0, "wood", 0.5, Color(0.8, 0.75, 0.7))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.pillar(sx * 10.8, sz * 2.4, 1.6, 0.18, false, "wood")
	# Ruined watchtower, milestones and a broken wagon.
	k.tower(-36, 16, 3.2, 9.0, "stone", Color(0.95, 0.9, 0.85), Color(0, 0, 0), k.yaw_of(Vector2(0.3, -1)), {"roof_h": 0.0, "crenel": true})
	for p in [Vector2(-44, -10), Vector2(-28, 7), Vector2(20, -4.5), Vector2(40, 8), Vector2(66, 9)]:
		k.pillar(p.x, p.y, 1.2, 0.3, false)
	k.block(k.g(32, 5, 0.6), Vector3(2.4, 0.8, 4.0), 0.4, "wood")
	k.crate(33.5, 2.5, 0.3, 0.9)
	k.barrel(30.5, 7.5)
	k.log(30, 3.5, 2.6, 1.9, 0.5)
	k.cave_in_cliff(66, -6, Vector2(0, -1), 3.2, 3.2, "grate")
	# Boulders, spires, dry brush and dead trees along the canyon floor.
	for i in 80:
		var x := r.randf_range(x_min + 5, x_max - 5)
		var z := r.randf_range(z_min + 5, z_max - 5)
		if road_dist(x, z) < 4.0 or in_corridor(x, z, 3.0) or absf(x) < GORGE_HALF + 4.0:
			continue
		match i % 5:
			0, 1:
				k.rock(x, z, r.randf_range(0.6, 1.8), "rock", true, Color(1.1, 0.8, 0.65))
			2:
				k.spire(x, z, r.randf_range(1.0, 2.0), r.randf_range(5.0, 11.0), "rock", Color(1.1, 0.75, 0.58), 0.6, 6)
			3:
				k.bush(x, z, r.randf_range(0.5, 0.9), Color(0.85, 0.75, 0.5))
			4:
				k.tree_dead(x, z, r.randf_range(0.7, 1.1))


## The canyon road: tektites among the boulders, pots by the broken wagon,
## brush, and a signpost at each end.
func populate(k) -> void:
	k.signpost(-50, -18, Vector2(-54, -24), "*The South Road*\nEast: Mirror Lake\nNorth-east: Desert of Ladhellin")
	k.signpost(70, 10, Vector2(75, 5), "East: *Mirror Lake*\nWest: Bunsriel Fields")
	k.enemies_near("tektite", Vector2(-30, 15), 12.0, 1)
	k.enemies_near("tektite", Vector2(55, -15), 12.0, 2)
	for p in [Vector2(34.5, 4.0), Vector2(35.2, 4.8)]:
		k.pot(p.x, p.y)
	k.pot(29.5, 8.8, "rupee_blue")
	for c in [Vector2(-40, 0), Vector2(20, 12), Vector2(60, 15)]:
		k.shrubs_near(c, 5.0, 5, Color(0.95, 0.9, 0.65))
		k.lift_rocks_near(c, 6.0, 2, Color(1.1, 0.85, 0.7))
