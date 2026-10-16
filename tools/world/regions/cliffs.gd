extends "res://tools/world/region.gd"
## Northeastern Cliffs: a climb up orange rock (the January 1997 mountain shots)
## in four tiers joined by switchback ramps. Snowmelt from Frostpeak cascades
## down three falls into a pool and flows out west to become the field's river.
## A sealed mini-dungeon door is set into the second cliff.

const TIERS := [0.4, 10.0, 21.0, 33.0]
## Cliff lines between tiers (z) - tier 0 is south of the first line.
const EDGES := [23.0, -7.0, -37.0]
const STREAM_X := 12.0
## Where the waystone stands (world_kit._auto_waystone): the first tier, west of the stream.
var waystone_at := Vector2(-6, 10)
const POOL := Vector2(12, 38)
## Ramps: [center x, half width, z at the low end, z at the high end, from tier].
const RAMPS := [[-33.0, 5.0, 44.0, 20.0, 0], [31.0, 5.0, 19.0, -10.0, 1], [-25.0, 5.0, -10.0, -40.0, 2]]
const STREAM_OUT: Array[Vector2] = [Vector2(12, 38), Vector2(0, 50), Vector2(-75, 50)]


func setup() -> void:
	id = "cliffs"
	seed_value = 91
	x_min = -50.0
	x_max = 50.0
	z_min = -65.0
	z_max = 65.0
	rim_height = 28.0
	rim_margin = 8.0
	rim_run = 6.0
	cliff_col = Color(1.2, 0.74, 0.52)
	rock_col = Color.html("b0663e")
	links = [
		{"to": "field", "p": Vector2(-50, 45), "d": Vector2(1, 0), "w": 7.0, "y": 0.4},
		{"to": "snow", "p": Vector2(10, -65), "d": Vector2(0, 1), "w": 6.0, "y": 33.0},
		# Chapter V: the old east pass to Cinderhold, behind a great stone.
		{"to": "cinderhold", "p": Vector2(50, -20), "d": Vector2(-1, 0), "w": 4.5, "y": 21.0},
	]
	water = [
		{"rect": Rect2(-80, EDGES[0], 135, 70), "y": -0.1, "col": Color(0.35, 0.55, 0.8, 0.78)},
		{"rect": Rect2(STREAM_X - 3, EDGES[1], 6, EDGES[0] - EDGES[1]), "y": TIERS[1] - 0.35, "col": Color(0.35, 0.55, 0.8, 0.78)},
		{"rect": Rect2(STREAM_X - 3, EDGES[2], 6, EDGES[1] - EDGES[2]), "y": TIERS[2] - 0.35, "col": Color(0.35, 0.55, 0.8, 0.78)},
		{"rect": Rect2(STREAM_X - 3, -75, 6, EDGES[2] + 75), "y": TIERS[3] - 0.35, "col": Color(0.35, 0.55, 0.8, 0.78)},
	]
	mood = {
		"sky_top": Color.html("4c4c98"), "sky_mid": Color.html("8e86c4"), "sky_horizon": Color.html("e2c8d8"),
		"cloud": Color.html("f2e8f2"), "cloud_amount": 0.4,
		"fog": Color.html("d0bed0"), "fog_begin": 40.0, "fog_end": 155.0,
		"ambient": Color.html("7a6070"), "sun": Color.html("fff0d8"), "sun_rot": Vector3(-40, -40, 0),
		"fill": Color.html("6a5a8a"),
		"horizon": Color.html("9a7a84"), "hill_height": 34.0,
		"far": [{"type": "peak", "yaw": 0.0, "w": 150.0, "h": 90.0, "col": Color.html("a8a4c4"), "snow": true}],
	}


func tier_height(z: float) -> float:
	var h: float = TIERS[0]
	for i in EDGES.size():
		h = lerpf(h, TIERS[i + 1], smoothstep(EDGES[i] + 1.5, EDGES[i] - 1.5, z))
	return h


func base_height(x: float, z: float) -> float:
	var h := tier_height(z) + noise.get_noise_2d(x * 2.0, z * 2.0) * 0.8
	for rp in RAMPS:
		var f := 1.0 - smoothstep(rp[1] - 1.0, rp[1] + 1.0, absf(x - rp[0]))
		if f <= 0.0:
			continue
		var t := clampf((z - rp[2]) / (rp[3] - rp[2]), 0.0, 1.0)
		var low: float = TIERS[rp[4]]
		var high: float = TIERS[rp[4] + 1]
		var ramp_h := lerpf(low, high, t)
		var inside := z <= maxf(rp[2], rp[3]) + 1.0 and z >= minf(rp[2], rp[3]) - 1.0
		if inside and ramp_h > h:
			h = lerpf(h, ramp_h, f)
	# The stream's channel on every tier, and the pool at the foot of the falls.
	var tier_h := tier_height(z)
	if absf(x - STREAM_X) < 4.0 and z < EDGES[0]:
		h = lerpf(tier_h - 0.9, h, smoothstep(2.0, 4.0, absf(x - STREAM_X)))
	var dp := Vector2(x, z).distance_to(POOL)
	if dp < 12.0 and z > EDGES[0]:
		h = lerpf(-1.0, h, smoothstep(6.0, 12.0, dp))
	return h


func height(x: float, z: float) -> float:
	var h := super.height(x, z)
	# The outflow is carved last so it runs through the exit corridor to the field.
	var ds := poly_dist(Vector2(x, z), STREAM_OUT)
	if ds < 5.0 and z > EDGES[0] + 2.0:
		h = lerpf(-0.8, h, smoothstep(2.0, 5.0, ds))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if h < 0.0 and z > EDGES[0]:
		return pick(r, ["6a5a48", "74644e"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	if h > 30.0:
		if b + r.randf_range(-0.3, 0.3) > -0.1:
			return pick(r, ["e8ecf4", "f0f2f8", "dce2ec"])
	if h < 3.0:
		return Color.html("6a7a3a").lerp(Color.html("8a7a44"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))
	return Color.html("a86a42").lerp(Color.html("c48a56"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# Three falls down the tier cliffs, feeding the pool.
	for i in EDGES.size():
		var top_y: float = TIERS[i + 1] - 0.35
		var drop: float = TIERS[i + 1] - TIERS[i] + 0.6
		k.waterfall(Vector3(STREAM_X, top_y, EDGES[i] - 1.2), 4.5, drop, Vector2(0, 1))
	# Plank bridges over the stream on the upper tiers.
	k.bridge(Vector3(STREAM_X - 4.5, TIERS[1] + 0.1, 8), Vector3(STREAM_X + 4.5, TIERS[1] + 0.1, 8), 3.0, "wood", 0.4)
	k.bridge(Vector3(STREAM_X - 4.5, TIERS[2] + 0.1, -22), Vector3(STREAM_X + 4.5, TIERS[2] + 0.1, -22), 3.0, "wood", 0.4)
	k.bridge(k.g(-20, 44), k.g(-20, 56), 3.5, "wood", 0.5)
	# The sealed mini-dungeon door in the second cliff, and a cave in the east wall.
	var door: Vector3 = k.cliff_spot(-12, 4, Vector2(0, -1), 3.0)
	k.cave_in_cliff(26, 45, Vector2(1, 0), 3.2, 3.2, "bomb", "rupee_red")
	_watch_bells(k)
	# The east pass to Cinderhold: a great stone rolled across it long ago
	# (the Questlord's Gauntlets drag it away). It waits for the Hollow King,
	# who tells the hero to go east (the gauntlets are won halfway through his
	# Barrow, so the pass could be opened before him. Beta 1.5.1).
	k.great_stone(44.0, -20.0, -PI * 0.5, "cliffs:pass_open", TIERS[2] - 0.05, 1.0, Color(1.1, 0.8, 0.65), "ch5:barrow_done",
		"You take hold of the great stone in the Questlord's grip... and far away to the west, under Castle Town, a dead bell tolls in the Barrow of Kings.
Your hands fall from the stone. The kings are not at rest yet. Whatever waits east can wait.")
	# The pass is ten meters wide: it narrows here to a cleft between rock
	# shoulders, and the stone fills the cleft. A bar behind the stone holds
	# the last finger-width gaps until it is dragged away.
	for side in [-1.0, 1.0]:
		for i in 7:
			var zz: float = -20.0 + side * (2.25 + i * 1.6)
			k.spire(44.7 + r.randf_range(-0.35, 0.35), zz, 1.3, 6.0 + i * 1.1 + r.randf_range(0.0, 1.2), "rock", Color(1.05, 0.74, 0.56), 0.6, 7)
		k.col_box(Vector3(44.7, TIERS[2] + 5.0, -20.0 + side * 7.4), Vector3(2.6, 10.0, 10.4)).set_meta("no_climb", true)
	k.flag_barrier(Vector3(45.6, TIERS[2] + 1.6, -20.0), Vector3(0.5, 3.2, 2.6), 0.0, "cliffs:pass_open")
	k.examine(Vector3(41.0, TIERS[2], -23.4), PI * 0.25, [], "res://scripts/npc/chapter5_lines.gd", "cliff_stone")
	# The sealed door in the second cliff: two braziers, cold for an age. The
	# Ember Rod's fire lights them, and the seal opens on a Piece of Heart.
	_fire_seal(k, door)
	# Aphiel's Spring: an open cave halfway up the mountain, in the cliff over
	# the third tier's east end.
	k.spring_cave_in_cliff(34.0, -26.0, Vector2(0, -1), "spring_aphiel", "", {"tint": Color(1.15, 0.8, 0.62)})
	# Rock spires, boulders and hardy pines (snow-dusted at the top).
	for i in 70:
		var x := r.randf_range(x_min + 7, x_max - 7)
		var z := r.randf_range(z_min + 7, z_max - 7)
		if in_corridor(x, z, 3.0) or absf(x - STREAM_X) < 6.0 or Vector2(x, z).distance_to(POOL) < 12.0:
			continue
		var on_ramp := false
		for rp in RAMPS:
			if absf(x - rp[0]) < rp[1] + 2.0 and z < maxf(rp[2], rp[3]) + 3.0 and z > minf(rp[2], rp[3]) - 3.0:
				on_ramp = true
		var near_edge := false
		for e in EDGES:
			if absf(z - e) < 5.0:
				near_edge = true
		if on_ramp or near_edge:
			continue
		var hh := height(x, z)
		match i % 4:
			0:
				k.tree_pine(x, z, r.randf_range(0.8, 1.2), hh > 30.0)
			1:
				k.rock(x, z, r.randf_range(0.6, 1.6), "rock", true, Color(1.15, 0.8, 0.62))
			2:
				k.spire(x, z, r.randf_range(1.0, 1.8), r.randf_range(4.0, 8.0), "rock", Color(1.15, 0.78, 0.58), 0.55, 6)
			3:
				k.bush(x, z, r.randf_range(0.5, 0.9), Color(0.85, 0.8, 0.55))
	for i in 8:
		var a := TAU * i / 8.0
		k.reeds(POOL.x + cos(a) * 8.0, POOL.y + sin(a) * 7.0, 4)


## The climb: tektites on the tiers (blue near the snow), bats about the
## cave, hardy grass, a sign at the foot and a rupee for the climbers.
func populate(k) -> void:
	k.signpost(-37, 40, Vector2(-40, 45), "*Northeastern Cliffs*\nThe path climbs past the falls\nto *Frostpeak*.")
	k.enemies_near("tektite", Vector2(-10, 40), 14.0, 2)
	k.enemies_near("tektite", Vector2(-20, 10), 12.0, 1)
	k.enemies_near("tektite_blue", Vector2(-15, -50), 12.0, 2)
	for c in [Vector2(28, 40), Vector2(25, -20)]:
		var p: Vector2 = k.spot(c, 8.0)
		if p != Vector2.INF:
			k.enemy("keese", p.x, p.y, 0.0, {}, k.h(p.x, p.y) + 3.0)
	for c in [Vector2(-30, 50), Vector2(30, 30), Vector2(-35, 0), Vector2(30, -30)]:
		k.shrubs_near(c, 5.0, 5, Color(0.95, 0.9, 0.65))
		k.lift_rocks_near(c, 6.0, 2, Color(1.15, 0.85, 0.65))
	k.collectible("rupee_red", -40, -50, TIERS[3] + 0.4)
	# Tucked away on the top tier's far corner, past the falls.
	k.heart_piece(38.0, -58.0, "cliffs:heart_piece")


## The fire seal (Chapter V, an old-world secret): both braziers lit (the
## Ember Rod, or burning arrows from one to the other once one is lit), the
## seal slides away into the rock; inside, a Piece of Heart.
func _fire_seal(k, door: Vector3) -> void:
	var gone := "cliffs:fire_seal"
	k.torch(door.x - 2.6, door.z + 1.5, false, gone + "_l", door.y)
	k.torch(door.x + 2.6, door.z + 1.5, false, gone + "_r", door.y)
	k.flag_all([gone + "_l", gone + "_r"], gone)
	var frame = k._tmp()
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(door.x + sx * 1.4, door.y + 1.6, door.z - 0.1), Vector3(0.6, 3.2, 0.7), Color(1, 1, 1))
	frame.box(Vector3(door.x, door.y + 3.55, door.z - 0.1), Vector3(3.4, 0.7, 0.75), Color(1, 1, 1))
	k.merge(frame, "stone")
	var slab = k._tmp()
	slab.box(Vector3(door.x, door.y + 1.6, door.z - 0.15), Vector3(2.2, 3.2, 0.3), Color(0.85, 0.85, 0.9))
	var em = k._tmp(false)
	em.prism(Vector3(door.x, door.y + 1.76, door.z + 0.0), 0.66, Vector3(door.x, door.y + 1.76, door.z + 0.06), 0.66, 8, Color(1.0, 0.5, 0.2))
	k.flag_barrier(Vector3(door.x, door.y + 1.6, door.z - 0.15), Vector3(2.2, 3.2, 0.4), 0.0, gone, slab, "seal")
	k.flag_props("", em, "glow", gone)
	# The dark of the little chamber behind it, and the prize in the doorway.
	var cm = k._tmp(false)
	cm.box(Vector3(door.x, door.y + 1.6, door.z - 0.55), Vector3(2.4, 3.2, 0.3), Color.html("0a0808"))
	k.merge(cm, "char")
	k.heart_piece(door.x, door.z + 0.9, gone + "_heart", door.y + 0.4, gone)
	k.examine(Vector3(door.x + 3.6, door.y, door.z + 1.8), PI, [{"text": "Two braziers either side of a sealed door, cold for an age. The seal bears a flame.
*LIGHT BOTH FIRES AND THE MOUNTAIN WILL OPEN.*", "instant": true}])


## Beta 1.4.0: the old watch bells, three iron bells on tall posts on the
## lowest tier, far out of a sword's reach. The Iron Flail rings them; all
## three rung, the watchmen's strongbox appears.
func _watch_bells(k) -> void:
	var flags: Array = []
	var placed := 0
	for i in 3:
		var at: Vector2 = k.spot(Vector2(-26.0 + i * 7.0, 26.0), 6.0, 1.6)
		if at == Vector2.INF:
			continue
		var y: float = k.h(at.x, at.y)
		k.pillar(at.x, at.y, 4.6, 0.16, false, "wood", y)
		var f := "cliffs:watch_bell_%d" % i
		k.flail_target("bell", at.x, at.y, f, y, {"tall": 4.4})
		flags.append(f)
		placed += 1
	if placed == 0:
		return
	k.flag_all(flags, "cliffs:watch_bells")
	var c: Vector2 = k.spot(Vector2(-19.0, 32.0), 6.0, 1.6)
	if c != Vector2.INF:
		k.chest(c.x, c.y, PI, "rupee_purple", false, "cliffs:watch_chest", "cliffs:watch_bells")
		k.examine(Vector3(c.x + 1.6, k.h(c.x + 1.6, c.y + 1.0), c.y + 1.0), PI * 0.8, [{"text": "An old watchmen's notice, nailed to a stump:\n*RING ALL THREE BELLS IF THE DEAD COME DOWN FROM THE RIDGE.*\nNobody rang them. Nobody needed to. Until now.", "instant": true}])
