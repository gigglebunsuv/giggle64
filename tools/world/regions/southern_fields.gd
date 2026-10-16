extends "res://tools/world/region.gd"
## Southern Fields: farmland in golden afternoon light. Farmhouse and barn,
## plowed fields, a windmill, an orchard and a pond, Clover's horse corral
## with its jumping course (and Biscuit), and the brick Southern Tower (its
## door wants the two braziers lit).

const CROSS := Vector2(0, -5)
const TOWER := Vector2(-5, 38)
const POND := Vector2(36, 12)
const CROPS := Rect2(-52, -22, 30, 26)
## Clover's corral, its jumping track (an oval round its middle) and the gap
## in its north fence.
const CORRAL := Rect2(18, 24, 34, 24)
const TRACK_C := Vector2(35, 36)
const TRACK_R := Vector2(12, 8)
const CORRAL_GAP := Vector2(22, 28)
## Clover's target range: the shooting line and its targets.
const RANGE_LINE := Vector2(9, -14)
const RANGE_TARGETS: Array[Vector2] = [Vector2(2, -28), Vector2(9, -32), Vector2(16, -28), Vector2(5, -38), Vector2(13, -40)]

var paths: Array = [
	[Vector2(25, -60), Vector2(20, -30), CROSS, Vector2(30, 14), Vector2(65, 20)],
	[CROSS, Vector2(-20, -24), Vector2(-36, -30)],
	[CROSS, Vector2(-4, 28)],
	[Vector2(-4, 28), Vector2(-30, 32), Vector2(-46, 34)],
]


func setup() -> void:
	id = "southern_fields"
	seed_value = 71
	x_min = -60.0
	x_max = 60.0
	z_min = -55.0
	z_max = 55.0
	rim_height = 12.0
	rim_margin = 8.0
	cliff_col = Color(0.85, 0.78, 0.62)
	rock_col = Color.html("8a7a5e")
	links = [
		{"to": "field", "p": Vector2(25, -55), "d": Vector2(0, 1), "w": 6.0, "y": 0.5},
		{"to": "village", "p": Vector2(60, 20), "d": Vector2(-1, 0), "w": 5.0, "y": 0.6},
	]
	water = [{"rect": Rect2(POND.x - 12, POND.y - 10, 24, 20), "y": -0.3, "col": Color(0.35, 0.55, 0.75, 0.75)}]
	mood = {
		"sky_top": Color.html("3a68d0"), "sky_mid": Color.html("8aa8e0"), "sky_horizon": Color.html("f8d8a4"),
		"cloud": Color.html("fff0d8"), "cloud_amount": 0.35,
		"fog": Color.html("eedab2"), "fog_begin": 40.0, "fog_end": 145.0,
		"ambient": Color.html("7a6c5a"), "sun": Color.html("ffd8a0"), "sun_rot": Vector3(-30, -70, 0),
		"horizon": Color.html("a08a6e"), "hill_height": 10.0,
		"far": [
			{"type": "castle", "yaw": 30.0, "w": 30.0, "h": 16.0, "col": Color.html("b8aab0"), "roof": Color.html("6a6aa0")},
			{"type": "peak", "yaw": 45.0, "w": 80.0, "h": 45.0, "col": Color.html("b0a8b8"), "snow": true},
		],
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	var h := 0.5 + maxf(noise.get_noise_2d(x * 1.4, z * 1.4) * 2.5, -0.2)
	h += bump(x, z, Vector2(-44, 38), 16.0) * 3.0
	h += bump(x, z, Vector2(40, -36), 14.0) * 1.5
	# Flat farmland and the tower plaza.
	if CROPS.grow(4.0).has_point(Vector2(x, z)):
		h = lerpf(h, 0.6, 0.85)
	if CORRAL.grow(3.0).has_point(Vector2(x, z)):
		h = lerpf(h, 0.7, 0.9)
	h = lerpf(h, 0.7, 1.0 - smoothstep(9.0, 13.0, Vector2(x, z).distance_to(TOWER)))
	h = lerpf(h * 0.5 + 0.3, h, smoothstep(2.0, 8.0, path_dist(x, z)))
	var dp := Vector2(x, z).distance_to(POND)
	if dp < 10.0:
		h = lerpf(-1.0, h, smoothstep(4.0, 10.0, dp))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var d := path_dist(x, z) + r.randf_range(-0.4, 0.4)
	if d < 2.0:
		return pick(r, ["a88a58", "b49462", "bea06c"])
	if CROPS.has_point(Vector2(x, z)):
		# Plowed rows, alternating soil and green shoots.
		var row := int(floorf((x - CROPS.position.x) / 1.6))
		if row % 2 == 0:
			return pick(r, ["6a4a2a", "74522e"])
		return pick(r, ["6a8a2a", "7a9a30"]) if z < -8.0 else pick(r, ["c8a840", "d4b44a"])
	if Vector2(x, z).distance_to(TOWER) < 8.0:
		return pick(r, ["c8b48a", "d4c094"])
	if CORRAL.has_point(Vector2(x, z)):
		# Trampled earth on the track, grass in the middle.
		var e := Vector2((x - TRACK_C.x) / TRACK_R.x, (z - TRACK_C.y) / TRACK_R.y).length()
		if absf(e - 1.0) < 0.28 + r.randf_range(-0.04, 0.04):
			return pick(r, ["a08458", "aa8e60", "967a50"])
	if h < 0.0 and Vector2(x, z).distance_to(POND) < 10.0:
		return pick(r, ["6a6040", "766a48"])
	var b := noise.get_noise_2d(x * 3.0, z * 3.0)
	return Color.html("6a9a34").lerp(Color.html("a0b048"), clampf(b + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var fence_col := Color(0.95, 0.9, 0.82)
	# Farmhouse, barn and haystacks.
	k.house(-38, -38, 0.0, 9.0, 7.0, 4.0, Color(1, 0.96, 0.88), Color(1, 1, 1), {"wall": "timber", "roof": "thatch", "chimney": true})
	k.house(-20, -42, 0.0, 10.0, 8.0, 5.5, Color.html("b84a3a"), Color.html("5a3a2a"), {"wall": "wood", "door_w": 2.6})
	for p in [Vector2(-10, -38), Vector2(-8, -34), Vector2(-12, -33)]:
		k.haystack(p.x, p.y, r.randf_range(0.8, 1.1))
	k.fence([Vector2(CROPS.position.x, CROPS.position.y), Vector2(CROPS.end.x, CROPS.position.y), Vector2(CROPS.end.x, CROPS.end.y - 6.0)], fence_col)
	k.fence([Vector2(CROPS.end.x, CROPS.end.y), Vector2(CROPS.position.x, CROPS.end.y), Vector2(CROPS.position.x, CROPS.position.y)], fence_col)
	k.windmill(12, -28, PI * 0.25)
	# Orchard rows in the north-east.
	for x in range(28, 52, 6):
		for z in range(-44, -26, 6):
			k.tree_round(x + r.randf_range(-0.6, 0.6), z + r.randf_range(-0.6, 0.6), 0.85, Color(0.9, 1.0, 0.8))
	# The Southern Tower on its paved plaza, with two unlit braziers at the door.
	k.platform(TOWER.x, TOWER.y, Vector2(16.0, 14.0), 0.95, "stone", Color(1.0, 0.95, 0.85))
	k.stairs(TOWER.x, TOWER.y - 9.2, PI, 6.0, 2.2, 0.95 - k.h(TOWER.x, TOWER.y - 9.2) + 0.05, "stone")
	k.tower(TOWER.x, TOWER.y + 1.0, 4.5, 20.0, "stone", Color(1.0, 0.72, 0.58), Color.html("8a3a2a"), 0.0,
		{"sides": 8, "crenel": true, "roof_h": 6.0, "y": 0.95, "seal": "open"})
	# The door into the tower, barred until both braziers by it are lit: shoot
	# an arrow through the torch at the foot of the stairs so it catches fire,
	# and on into each brazier.
	var door_z := TOWER.y + 1.0 - 4.5 * 1.04
	var frame = k._tmp()
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(TOWER.x + sx * 1.25, 0.95 + 1.5, door_z + 0.05), Vector3(0.5, 3.0, 0.6), Color(1.0, 0.75, 0.62))
	frame.box(Vector3(TOWER.x, 0.95 + 3.25, door_z + 0.05), Vector3(3.0, 0.5, 0.65), Color(1.0, 0.75, 0.62))
	k.merge(frame, "stone")
	k.door_link(Vector3(TOWER.x, 0.95, door_z - 0.02), 0.0, 1.8, 2.8, "southern_tower", "from_southern_fields", Color(0.95, 0.75, 0.6), "southern_tower:door")
	k.flag_bars(TOWER.x, door_z - 0.35, 0.0, "southern_tower:door", 0.95)
	k.entrance("from_southern_tower", TOWER.x, door_z - 2.2, 0.0)
	k.entrance("warp_southern_tower", TOWER.x + 1.5, door_z - 2.4, 0.0)
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		k.torch(TOWER.x + sx * 3.2, TOWER.y - 5.0, false, "southern_tower:brazier_%d" % i, 0.95)
	k.torch(TOWER.x - 4.0, TOWER.y - 13.0, true)
	k.flag_all(["southern_tower:brazier_0", "southern_tower:brazier_1"], "southern_tower:door")
	k.cave_in_cliff(-40, 34, Vector2(-1, 0), 3.0, 3.0, "bomb", "rupee_red")
	# A Spring of Lothelye behind a cracked boulder in the north-east hills.
	k.spring_cave_in_cliff(44.0, -40.0, Vector2(1, 0), "spring_lothelye_defense", "bomb")
	_corral(k)
	for i in 8:
		var a := TAU * i / 8.0
		k.reeds(POND.x + cos(a) * 7.0, POND.y + sin(a) * 6.0, 5)
	# Hedgerows, trees and flowers.
	for i in 70:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		if path_dist(x, z) < 4.0 or in_corridor(x, z, 3.0) or CROPS.grow(3.0).has_point(Vector2(x, z)) \
				or Vector2(x, z).distance_to(TOWER) < 12.0 or Vector2(x, z).distance_to(POND) < 10.0 \
				or Rect2(-44, -48, 40, 18).has_point(Vector2(x, z)) or Rect2(24, -48, 30, 26).has_point(Vector2(x, z)) \
				or Vector2(x, z).distance_to(Vector2(12, -28)) < 6.0 or CORRAL.grow(5.0).has_point(Vector2(x, z)):
			continue
		match i % 5:
			0, 1:
				k.tree_round(x, z, r.randf_range(0.9, 1.3))
			2:
				k.bush(x, z, r.randf_range(0.7, 1.2))
			3:
				k.flowers(x, z, 2.0, 8, ["f0d040", "f0f0e0", "e06a40"])
			4:
				k.rock(x, z, r.randf_range(0.4, 1.0))


## Clover's corral: a white fence with a gap facing the farm road, the
## start arch over the track, three low fences to jump round the oval, a
## water trough, Clover by the gap and Biscuit grazing inside.
func _corral(k) -> void:
	var col := Color(0.95, 0.92, 0.86)
	var c := CORRAL
	var gap := CORRAL_GAP
	k.fence([Vector2(gap.y, c.position.y), Vector2(c.end.x, c.position.y), Vector2(c.end.x, c.end.y),
		Vector2(c.position.x, c.end.y), Vector2(c.position.x, c.position.y), Vector2(gap.x, c.position.y)], col)
	# The three jumps round the track: east, south and west of the oval.
	for j in [[Vector2(TRACK_C.x + TRACK_R.x, TRACK_C.y), true], [Vector2(TRACK_C.x, TRACK_C.y + TRACK_R.y), false],
			[Vector2(TRACK_C.x - TRACK_R.x, TRACK_C.y), true]]:
		var p: Vector2 = j[0]
		var span := Vector2(2.4, 0) if j[1] else Vector2(0, 2.4)
		k.fence([p - span, p + span], Color(0.9, 0.3, 0.25), 1.0)
	# The start / finish arch on the north side of the track.
	var a := Vector2(TRACK_C.x, TRACK_C.y - TRACK_R.y)
	var ay: float = k.h(a.x, a.y)
	var arch = k._tmp()
	for sz in [-1.0, 1.0]:
		arch.box(Vector3(a.x, ay + 1.6, a.y + sz * 3.2), Vector3(0.25, 3.2, 0.25), Color(0.95, 0.92, 0.86))
	arch.box(Vector3(a.x, ay + 3.3, a.y), Vector3(0.3, 0.5, 6.8), Color(0.8, 0.25, 0.2))
	k.merge(arch, "wood")
	k.pixel_text("START", Vector3(a.x + 0.17, ay + 3.3, a.y), PI * 0.5, 0.07, Color.html("f0e0a0"))
	k.pixel_text("START", Vector3(a.x - 0.17, ay + 3.3, a.y), -PI * 0.5, 0.07, Color.html("f0e0a0"))
	k._dyn("res://scripts/horse/fence_course.gd", "FenceCourse", Vector3(a.x, ay, a.y), 0.0,
		{"gate_size": Vector3(2.0, 4.0, 6.4), "own_time": 60.0, "wallet_time": 16.0}, Node3D.new())
	# A water trough and a hay bale by the fence.
	k.block(Vector3(c.end.x - 1.2, k.h(c.end.x - 1.2, c.position.y + 3.0) + 0.3, c.position.y + 3.0), Vector3(0.8, 0.6, 2.0), 0.0, "wood", Color(0.75, 0.6, 0.45))
	k.haystack(c.position.x + 2.0, c.end.y - 2.0, 0.8)
	# Clover at the gap, and Biscuit inside.
	k.npc("Clover", "res://assets/models/clover.tscn", "res://scripts/npc/clover_lines.gd", (gap.x + gap.y) * 0.5, c.position.y - 2.2, 0.0)
	var horse := CharacterBody3D.new()
	horse.set_script(load("res://scripts/horse/horse.gd"))
	var model: Node3D = load("res://assets/models/horse.tscn").instantiate()
	model.name = "Model"
	horse.add_child(model)
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = load("res://assets/models/blob_shadow_mesh.tres")
	shadow.set_script(load("res://scripts/systems/blob_shadow.gd"))
	shadow.set("radius", 0.9)
	horse.add_child(shadow)
	horse.name = "Biscuit"
	horse.position = k.g(TRACK_C.x - 4.0, TRACK_C.y - TRACK_R.y + 2.5, 0.05)
	horse.rotation.y = PI * 0.5
	k._misc.add_child(horse)


## Farmland: pots by the farmhouse, grass in the hedgerows, snapping plants by
## the pond, and the crossroads sign.
func populate(k) -> void:
	k.signpost(4, -9, CROSS + Vector2(2, 2), "*Southern Fields*\nNorth-east: Bunsriel Fields\nEast: Haven Village\n\nSouth: the Southern Tower")
	k.signpost(TOWER.x + 3.5, TOWER.y - 12.5, Vector2(TOWER.x + 3.5, TOWER.y - 18.0), "*The Southern Tower*\nIts door opens to fire.\nLight both braziers.")
	k.signpost(CORRAL_GAP.x - 2.5, CORRAL.position.y - 3.0, Vector2(CORRAL_GAP.x - 2.5, CORRAL.position.y - 8.0), "*Clover's Horses*\nPlease close the gate!\n(There is no gate.)")
	for p in [Vector2(-33.0, -33.5), Vector2(-32.2, -34.3), Vector2(-43.5, -33.8), Vector2(-15.0, -37.4)]:
		k.pot(p.x, p.y)
	for c in [Vector2(20, 0), Vector2(-15, 15), Vector2(40, 35), Vector2(-40, 30), Vector2(25, -10)]:
		k.shrubs_near(c, 6.0, 6)
	k.enemies_near("snapper", POND + Vector2(10, -9), 5.0, 2)
	k.enemies_near("tektite", Vector2(-30, 12), 10.0, 1)
	k.collectible("rupee_blue", -10, -36, k.h(-10, -38) + 2.1)
	# Clover's target range: a shooting line by the crossroads and five targets
	# across the meadow to the north (clover_lines.gd starts a round).
	var line := RANGE_LINE
	var rail = k._tmp()
	for i in 5:
		rail.box(k.g(line.x - 3.0 + i * 1.5, line.y) + Vector3(0, 0.45, 0), Vector3(0.12, 0.9, 0.12), Color(0.7, 0.55, 0.4))
	rail.box(k.g(line.x, line.y) + Vector3(0, 0.85, 0), Vector3(6.2, 0.1, 0.1), Color(0.75, 0.6, 0.45))
	k.merge(rail, "wood")
	for t: Vector2 in RANGE_TARGETS:
		k.archery_target(t.x, t.y, k.yaw_of((line - t).normalized()), INF, "", false, "clover")
	k.archery_range(line.x, line.y, "clover")
	k.signpost(line.x + 4.0, line.y + 1.0, line + Vector2(4, 6), "*Clover's Target Range*\nEvery gold center in 45 seconds!\n\nAsk Clover at the corral.")
