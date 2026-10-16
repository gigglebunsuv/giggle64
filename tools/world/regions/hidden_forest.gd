extends "res://tools/world/region.gd"
## The Hidden Forest: a sacred grove behind the stone gate. A misty lake with
## three standing stones, and on its island the great tree and the pedestal
## where the Bun Sword rests. Each stone carries a rune gem facing the island;
## strike all three so they glow together (arrows from the island, the
## boomerang, or swim out with the sword) and the stones wake: the Bun Sword
## appears in the pedestal.

const LAKE := Vector2(0, -8)
const LAKE_R := 22.0
## Wide enough that the pedestal stands well back from the water, with dry
## ground all round it and up to the last stepping stone.
const ISLAND_R := 9.0
const WATER_Y := -0.4


func setup() -> void:
	id = "hidden_forest"
	seed_value = 51
	x_min = -45.0
	x_max = 45.0
	z_min = -45.0
	z_max = 45.0
	rim_height = 15.0
	rim_margin = 7.0
	cliff_col = Color(0.6, 0.68, 0.6)
	rock_col = Color.html("4a5a4e")
	links = [{"to": "forest", "p": Vector2(0, 45), "d": Vector2(0, -1), "w": 4.0, "y": 0.6}]
	water = [{"rect": Rect2(LAKE.x - LAKE_R - 4, LAKE.y - LAKE_R - 4, LAKE_R * 2 + 8, LAKE_R * 2 + 8), "y": WATER_Y, "col": Color(0.3, 0.6, 0.62, 0.75)}]
	mood = {
		"sky_top": Color.html("2a5a6c"), "sky_mid": Color.html("5a9a9a"), "sky_horizon": Color.html("a8dccc"),
		"cloud": Color.html("d0f4e4"), "cloud_amount": 0.5,
		"fog": Color.html("9cccbe"), "fog_begin": 10.0, "fog_end": 75.0,
		"ambient": Color.html("5a8a7a"), "sun": Color.html("f0fff0"), "sun_rot": Vector3(-65, 40, 0),
		"fill": Color.html("4a7a8a"),
		"horizon": Color.html("3a6a5a"), "hill_height": 34.0, "particles": "motes",
	}


func base_height(x: float, z: float) -> float:
	var h := 0.6 + noise.get_noise_2d(x * 2.0, z * 2.0) * 1.2
	var d := Vector2(x, z).distance_to(LAKE)
	if d < LAKE_R + 5.0:
		h = lerpf(-1.3, h, smoothstep(LAKE_R - 4.0, LAKE_R + 5.0, d))
	# A gentle shore (a steep one is smoothed away by the terrain grid).
	h = maxf(h, lerpf(-2.5, 1.0, 1.0 - smoothstep(ISLAND_R - 1.0, ISLAND_R + 2.5, d)))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if h < WATER_Y + 0.25:
		return pick(r, ["3a5a4a", "44644e"])
	if absf(x) < 1.6 and z > 14.0 and r.randf() < 0.8:
		return pick(r, ["8a7a5a", "968664"])
	if r.randf() < 0.03:
		return pick(r, ["f0f0ff", "a0e0ff", "f8e070"])
	return Color.html("3a7a46").lerp(Color.html("5aa25a"), clampf(noise.get_noise_2d(x * 4.0, z * 4.0) + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	k.tree_great(LAKE.x + 1.5, LAKE.y - 2.5, 1.0)
	# The pedestal facing the stepping stones, between two lit braziers.
	var ped: Vector3 = k.g(LAKE.x, LAKE.y + 4.0)
	k.platform(ped.x, ped.z, Vector2(3.0, 3.0), ped.y + 0.5)
	k.pillar(ped.x, ped.z, 0.9, 0.5, false, "stone", ped.y + 0.5)
	k._dyn("res://scripts/items/bun_pedestal.gd", "BunPedestal", Vector3(ped.x, ped.y + 0.5, ped.z), 0.0, {}, Node3D.new())
	k.brazier(ped.x - 2.2, ped.z + 1.0, true, ped.y)
	k.brazier(ped.x + 2.2, ped.z + 1.0, true, ped.y)
	# Where the hero stands again after the takeover's cutscene.
	k.entrance("pedestal", ped.x, ped.z + 2.6, 0.0)
	# Stepping stones from the south shore to the island.
	for z in [16.0, 12.5, 9.0, 5.5, 2.0]:
		k.platform(r.randf_range(-0.6, 0.6), z, Vector2(2.4, 2.2), WATER_Y + 0.35, "stone", Color(0.85, 0.9, 0.85), r.randf() * 0.6)
	# The three standing stones in the water (from the pixel map).
	for p in [Vector2(-13, -14), Vector2(13, -14), Vector2(0, -26)]:
		k.statue(p.x, p.y, atan2(LAKE.x - p.x, LAKE.y - p.y), 1.3, "stone", WATER_Y - 0.4)
		var to: Vector2 = (LAKE - p).normalized()
		k._dyn("res://scripts/items/stone_rune.gd", "Rune", Vector3(p.x + to.x * 0.62, WATER_Y - 0.4 + 2.5, p.y + to.y * 0.62), 0.0, {}, StaticBody3D.new())
	# A ring of tall trees, ferns, glowing flowers.
	for i in 22:
		var a := TAU * i / 22.0 + r.randf_range(-0.1, 0.1)
		var p := Vector2(cos(a) * 36.0, sin(a) * 34.0)
		if not in_corridor(p.x, p.y, 4.0):
			k.tree_giant(p.x, p.y, r.randf_range(0.8, 1.3), r.randf_range(16.0, 24.0))
	for i in 40:
		var a := r.randf() * TAU
		var d := r.randf_range(LAKE_R + 3.0, 32.0)
		var x := LAKE.x + cos(a) * d
		var z := LAKE.y + sin(a) * d
		if in_corridor(x, z) or (absf(x) < 2.5 and z > 12.0):
			continue
		match i % 4:
			0:
				k.flowers(x, z, 1.8, 8, ["a0e0ff", "f0f0ff", "f8e070"])
			1:
				k.bush(x, z, r.randf_range(0.7, 1.2), Color(0.7, 0.95, 0.85))
			2:
				k.mushroom(x, z, r.randf_range(0.6, 1.1), Color.html("6ac0d8"))
			3:
				k.reeds(x, z, 4, Color.html("3a6a4a"))
	for i in 10:
		var lx := LAKE.x + r.randf_range(-18, 18)
		var lz := LAKE.y + r.randf_range(-18, 18)
		if Vector2(lx, lz).distance_to(LAKE) > ISLAND_R:
			k.lily(lx, lz, WATER_Y)
	# Alan's Spring: a cave in the east cliff between two of the great trees,
	# sealed by a cracked boulder (a bomb opens it).
	k.spring_cave_in_cliff(30.0, 4.8, Vector2(1, 0), "spring_alan", "bomb", {"tint": Color(0.75, 0.9, 0.8)})


## The Hidden Forest is still and quiet: only grass and a few rupees glinting
## by the water.
func populate(k) -> void:
	for c in [Vector2(-25, 20), Vector2(25, 20), Vector2(-30, -20), Vector2(30, -25)]:
		k.shrubs_near(c, 5.0, 5, Color(0.75, 1.0, 0.9), WATER_Y + 0.2)
	for p in [Vector2(-13, -14), Vector2(13, -14)]:
		k.collectible("rupee_blue", p.x, p.y, WATER_Y + 3.4)
