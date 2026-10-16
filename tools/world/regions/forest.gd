extends "res://tools/world/region.gd"
## The Forest: giant trunks rising into gray-lilac fog (the 1996 forest shots),
## a winding path north to the Hidden Forest gate, a pond and a sealed cave.

const CLEARING := Vector2(-5, 0)
const POND := Vector2(32, -22)
const GATE := Vector2(-30, -52)
const WATER_Y := -0.4

var paths: Array = [
	[Vector2(20, 65), Vector2(15, 35), Vector2(2, 15), CLEARING, Vector2(-15, -25), Vector2(-30, -65)],
	[Vector2(2, 15), Vector2(20, -5), POND],
	[Vector2(15, 35), Vector2(42, 35)],
]


func setup() -> void:
	id = "forest"
	seed_value = 41
	x_min = -60.0
	x_max = 60.0
	z_min = -60.0
	z_max = 60.0
	rim_height = 13.0
	rim_margin = 8.0
	cliff_col = Color(0.62, 0.6, 0.5)
	rock_col = Color.html("4a4a3e")
	links = [
		{"to": "field", "p": Vector2(20, 60), "d": Vector2(0, -1), "w": 5.0, "y": 0.4},
		{"to": "hidden_forest", "p": Vector2(-30, -60), "d": Vector2(0, 1), "w": 4.0, "y": 0.6},
	]
	water = [{"rect": Rect2(POND.x - 14, POND.y - 14, 28, 28), "y": WATER_Y, "col": Color(0.25, 0.4, 0.45, 0.8)}]
	mood = {
		"sky_top": Color.html("8a8ea8"), "sky_mid": Color.html("a8aac0"), "sky_horizon": Color.html("c4c4d4"),
		"cloud": Color.html("d8d8e4"), "cloud_amount": 0.8,
		"fog": Color.html("b8b8cc"), "fog_begin": 4.0, "fog_end": 50.0,
		"ambient": Color.html("5c6458"), "sun": Color.html("e8ecd4"), "sun_energy": 0.85, "sun_rot": Vector3(-62, 10, 0),
		"fill": Color.html("4a5a6a"),
		"horizon": Color.html("8a8c9c"), "hill_height": 40.0,
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	var h := 0.6 + noise.get_noise_2d(x * 1.5, z * 1.5) * 2.0
	h += bump(x, z, Vector2(44, 32), 14.0) * 4.0
	h = lerpf(h, 0.6, smoothstep(14.0, 8.0, Vector2(x, z).distance_to(CLEARING)))
	h = lerpf(h * 0.4 + 0.4, h, smoothstep(2.0, 7.0, path_dist(x, z)))
	var dp := Vector2(x, z).distance_to(POND)
	if dp < 13.0:
		h = lerpf(-1.2, h, smoothstep(5.0, 13.0, dp))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var d := path_dist(x, z) + r.randf_range(-0.5, 0.5)
	if d < 1.8:
		return pick(r, ["6a5236", "76603e", "5e4a30"])
	if h < WATER_Y + 0.2 and Vector2(x, z).distance_to(POND) < 13.0:
		return pick(r, ["4a4a32", "56543a"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	if b > 0.35 and r.randf() < 0.7:
		return pick(r, ["5a4a30", "64543a"])   # leaf litter
	return Color.html("2e5222").lerp(Color.html("4a7232"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# The gate to the Hidden Forest: a mossy stone arch with unlit braziers.
	var moss := Color(0.72, 0.86, 0.7)
	k.gatehouse(GATE.x, GATE.y, 0.0, 6.0, 7.5, "stone", moss)
	for sx in [-1.0, 1.0]:
		k.brazier(GATE.x + sx * 6.5, GATE.y + 4.0)
	k.cave_in_cliff(42, 35, Vector2(1, 0), 3.2, 3.2, "bomb", "rupee_purple")
	# Chapter V's old-world secret: a hollow choked with black thorns (the Ember Rod).
	k.cave_in_cliff(-40, 10, Vector2(-1, 0), 3.2, 3.2, "thorns", "heart_piece")
	# The great stump in the clearing.
	k.stump(CLEARING.x, CLEARING.y, 3.0)
	for i in 5:
		var a := TAU * i / 5.0
		k.mushroom(CLEARING.x + cos(a) * 4.5, CLEARING.y + sin(a) * 4.5, r.randf_range(0.8, 1.4))
	# Giant trunks everywhere except the path, clearing and pond.
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < 75 and tries < 5000:
		tries += 1
		var p := Vector2(r.randf_range(x_min - 6, x_max + 6), r.randf_range(z_min - 6, z_max + 6))
		if path_dist(p.x, p.y) < 5.0 or p.distance_to(CLEARING) < 13.0 or p.distance_to(POND) < 15.0 or in_corridor(p.x, p.y, 4.0):
			continue
		var ok := true
		for q in placed:
			if p.distance_to(q) < 8.0:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		k.tree_giant(p.x, p.y, r.randf_range(0.9, 1.8), r.randf_range(26.0, 36.0))
	# Undergrowth.
	for i in 90:
		var x := r.randf_range(x_min + 6, x_max - 6)
		var z := r.randf_range(z_min + 6, z_max - 6)
		if path_dist(x, z) < 2.5 or in_corridor(x, z) or Vector2(x, z).distance_to(POND) < 12.0:
			continue
		match i % 6:
			0, 1, 2:
				k.bush(x, z, r.randf_range(0.6, 1.3), Color(0.6, 0.75, 0.6))
			3:
				k.mushroom(x, z, r.randf_range(0.5, 1.0), Color.html(["c03a2a", "d8c050", "9a6ac8"][r.randi_range(0, 2)]))
			4:
				k.rock(x, z, r.randf_range(0.5, 1.3), "rock", true, Color(0.7, 0.85, 0.7))
			5:
				k.reeds(x, z, 4, Color.html("3a5a2a"))
	for i in 6:
		var x := r.randf_range(-45, 45)
		var z := r.randf_range(-45, 45)
		if path_dist(x, z) > 4.0 and Vector2(x, z).distance_to(POND) > 14.0 and Vector2(x, z).distance_to(CLEARING) > 6.0:
			k.log(x, z, r.randf_range(3.0, 6.0), r.randf() * PI, 0.5)
	for i in 4:
		var x := r.randf_range(-40, 40)
		var z := r.randf_range(-40, 40)
		if path_dist(x, z) > 3.0:
			k.stump(x, z, r.randf_range(0.8, 1.4))
	for i in 10:
		var a := TAU * i / 10.0
		k.reeds(POND.x + cos(a) * 8.5, POND.y + sin(a) * 8.5, 5, Color.html("4a6a32"))
	for i in 8:
		k.lily(POND.x + r.randf_range(-5, 5), POND.y + r.randf_range(-5, 5), WATER_Y)


## The Forest: snapping plants along the winding path, bats under the trees,
## shrubs round the clearing, a sign at the old gate and rupees on the great
## stump.
func populate(k) -> void:
	k.signpost(GATE.x + 4.5, GATE.y + 8.0, GATE + Vector2(0, 12), "Beyond this gate lies\n*The Hidden Forest*.\n\nTravelers who stray from the path\nhere are seldom seen again...")
	for c in [Vector2(10, 35), Vector2(-15, 15), Vector2(-20, -25), Vector2(15, -40)]:
		k.enemies_near("snapper", c, 9.0, 1)
	k.enemies_near("snapper", CLEARING, 12.0, 2)
	for c in [Vector2(-30, 10), Vector2(30, 10)]:
		var p: Vector2 = k.spot(c, 10.0)
		if p != Vector2.INF:
			k.enemy("keese", p.x, p.y, 0.0, {}, k.h(p.x, p.y) + 3.0)
	for c in [CLEARING + Vector2(8, 6), CLEARING + Vector2(-8, -6), Vector2(20, 45), Vector2(-25, -35), POND + Vector2(-15, 4)]:
		k.shrubs_near(c, 5.0, 6, Color(0.8, 0.95, 0.8))
	k.collectible("rupee_blue", CLEARING.x, CLEARING.y, k.h(CLEARING.x, CLEARING.y) + 2.25)
	k.collectible("rupee_green", CLEARING.x + 0.8, CLEARING.y + 0.6, k.h(CLEARING.x, CLEARING.y) + 2.25)
