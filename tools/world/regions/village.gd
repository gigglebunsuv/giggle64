extends "res://tools/world/region.gd"
## Haven Village: the hero's home town, tucked against the hills south of the
## field. Plaza with a fountain, shops (NW), houses (NE), the hero's home on its
## mound (SW), the library (SE), the old well, and on the east lane the pink
## "palace" of Himeko, the self-styled Princess of Haven Village.

const PLAZA := Vector2(0, 0)
const HOME := Vector2(-30, 30)
const LIBRARY := Vector2(30, 28)
## Himeko's palace: a pink two-storey house with two little turrets, facing
## the east lane across its rose garden.
const PALACE := Vector2(30, -9)
const PALACE_W := 12.0
const PALACE_D := 8.0
## The refuge (Chapter IV) opens the village's north side onto the field
## approach: no rim trees across it.
var north_open := false

var paths: Array = [
	[Vector2(0, -50), Vector2(0, -12)],
	[Vector2(-55, 12), Vector2(-14, 6)],
	[Vector2(0, 8), Vector2(0, 20)],
	[Vector2(6, -8), Vector2(24, -21), Vector2(40, -21)],
	[Vector2(-6, -8), Vector2(-22, -18)],
	[Vector2(-4, 10), Vector2(-26, 24)],
	[Vector2(4, 10), Vector2(28, 21)],
	[Vector2(30, -21), Vector2(30, -13.5)],
]


func setup() -> void:
	id = "village"
	seed_value = 21
	x_min = -50.0
	x_max = 50.0
	z_min = -45.0
	z_max = 45.0
	rim_height = 11.0
	rim_margin = 7.0
	rim_run = 5.0
	cliff_col = Color(0.8, 0.74, 0.62)
	rock_col = Color.html("7a705e")
	links = [
		{"to": "field", "p": Vector2(0, -45), "d": Vector2(0, 1), "w": 5.0, "y": 0.4},
		{"to": "southern_fields", "p": Vector2(-50, 12), "d": Vector2(1, 0), "w": 5.0, "y": 1.2},
	]
	mood = {
		"sky_top": Color.html("3a68d8"), "sky_mid": Color.html("7aa0e8"), "sky_horizon": Color.html("f0dcc4"),
		"cloud": Color.html("fffaf0"), "cloud_amount": 0.35,
		"fog": Color.html("e6dcc8"), "fog_begin": 30.0, "fog_end": 125.0,
		"ambient": Color.html("7a7068"), "sun": Color.html("ffe8c8"), "sun_rot": Vector3(-40, -30, 0),
		"horizon": Color.html("8a9a84"), "hill_height": 14.0,
		"far": [
			{"type": "castle", "yaw": 0.0, "w": 40.0, "h": 22.0, "col": Color.html("a0a4bc"), "roof": Color.html("5a68a8")},
			{"type": "peak", "yaw": 35.0, "w": 90.0, "h": 55.0, "col": Color.html("a8acc4"), "snow": true},
		],
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	var h := 0.4 + (z + 45.0) / 90.0 * 1.8 + noise.get_noise_2d(x * 2.0, z * 2.0) * 0.6
	h += mesa(x, z, HOME, 7.0, 11.5) * 2.2
	h += mesa(x, z, LIBRARY, 9.0, 12.0) * 0.8
	h = lerpf(h, 1.25, mesa(x, z, PALACE, 8.0, 10.5))
	var plaza := 1.0 - smoothstep(13.0, 17.0, Vector2(x, z).distance_to(PLAZA))
	return lerpf(h, 1.3, plaza)


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	return "stone" if Vector2(x, z).distance_to(PLAZA) < 13.0 else super.surface_at(x, z, h, r)


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var dp := Vector2(x, z).distance_to(PLAZA)
	if dp < 13.0 + r.randf_range(-0.4, 0.4):
		# Plaza paving in rings around the fountain.
		var ring := int(dp / 1.6) % 2
		return pick(r, ["b8ac94", "c4b8a0"] if ring == 0 else ["aca088", "b8ac94"])
	var d := path_dist(x, z) + r.randf_range(-0.4, 0.4)
	if d < 2.0:
		return pick(r, ["a88a5a", "b49664", "bea26e"])
	var blotch := noise.get_noise_2d(x * 3.0, z * 3.0)
	var grass := Color.html("5a9032").lerp(Color.html("78aa44"), clampf(blotch + 0.5 + r.randf_range(-0.1, 0.1), 0.0, 1.0))
	if r.randf() < 0.02:
		return pick(r, ["f0e8e0", "e8c840", "e07080"])
	return grass


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	k.gatehouse(0, -38, 0.0, 7.0, 6.0, "wood", Color(0.95, 0.9, 0.85), Color.html("a04a30"))
	k.fountain(PLAZA.x, PLAZA.y, 3.8)
	for a in [0.4, 1.9, 3.5, 5.0]:
		k.lamp(cos(a) * 11.0, sin(a) * 11.0)
	# The hero's home: a timber cottage with a thatched roof on its mound.
	k.house(HOME.x, HOME.y, PI, 7.5, 6.5, 3.4, Color(1, 0.97, 0.9), Color(1, 1, 1), {"wall": "timber", "roof": "thatch", "chimney": true, "door": false})
	var hy: float = k.h(HOME.x, HOME.y) - 0.2
	k.door_link(Vector3(HOME.x, hy, HOME.y - 3.31), 0.0, 1.2, 2.1, "hero_house", "from_village")
	k.entrance("home", HOME.x, HOME.y - 6.0, 0.0)
	k.fence([Vector2(-40, 22), Vector2(-40, 38), Vector2(-21, 38), Vector2(-21, 34)], Color(0.95, 0.9, 0.85))
	k.flowers(HOME.x + 5.0, HOME.y - 4.5, 1.6, 9)
	k.flowers(HOME.x - 5.0, HOME.y - 4.5, 1.6, 9)
	k.barrel(HOME.x + 4.6, HOME.y - 2.0)
	# Shops around their lane, with stalls in front.
	# Marigold's Goods, the general store, with its sign over the door.
	k.house(-27, -27, 0.0, 8.0, 6.0, 4.2, Color.html("e8a050"), Color.html("b84a32"), {"door_x": 1.5, "door": false})
	var sy: float = k.h(-27, -27) - 0.2
	k.door_link(Vector3(-25.5, sy, -23.94), PI, 1.2, 2.1, "shop", "", Color(1, 1, 1), "", "castle_fallen",
		"A note is nailed to the door:\n*CLOSED*\n\"Gone to my sister's in the hills till the smoke clears. Stay safe! -Marigold\"")
	k.entrance("from_shop", -25.5, -21.8, PI)
	var board = k._tmp(false)
	board.box(Vector3(-27, sy + 3.0, -23.9), Vector3(5.2, 0.7, 0.08), Color.html("4a2e1c"))
	board.box(Vector3(-27, sy + 3.0, -23.86), Vector3(5.0, 0.55, 0.04), Color.html("3a6a3a"))
	k.merge(board, "char")
	k.pixel_text("MARIGOLD'S GOODS", Vector3(-27, sy + 3.0, -23.83), 0.0, 0.05, Color.html("f0d060"))
	k.house(-15, -29, 0.0, 6.0, 6.0, 5.0, Color.html("e8d070"), Color.html("8a5a3a"))
	_cottage_door(k, "hv_1", Vector2(-15, -29), 0.0, 6.0)
	k.house(-36, -15, PI * 0.5, 6.0, 7.0, 4.0, Color.html("f0e8d8"), Color.html("4a5aa8"), {"wall": "timber"})
	_cottage_door(k, "hv_2", Vector2(-36, -15), PI * 0.5, 7.0)
	for p in [Vector2(-24, -19), Vector2(-17, -20), Vector2(-30, -21)]:
		k.stall(p.x, p.y, PI, [Color.html("c83a2a"), Color.html("2a6ac8"), Color.html("d8a020")][r.randi_range(0, 2)])
	for i in 4:
		k.crate(-11.5 + r.randf_range(-0.8, 0.8), -24.5 + i * 0.3, r.randf() * 0.5, 0.8)
	# Houses lining the lane to the east.
	var walls := ["e8a050", "f0e8d8", "9ab84a", "e8b0a0", "e8d070", "a8b8d0"]
	var roofs := ["b84a32", "8a3a2a", "b84a32", "7a5a3a", "4a5aa8", "b84a32"]
	var i := 0
	var lane := {15.0: "hv_3", 25.0: "hv_4", 35.0: "hv_5"}
	for x in [15.0, 25.0, 35.0]:
		k.house(x, -29, 0.0, 7.0, 6.0, 4.0 + (i % 2) * 1.2, Color.html(walls[i]), Color.html(roofs[i]), {"chimney": i % 2 == 0, "wall": "timber" if i == 2 else "plaster"})
		_cottage_door(k, lane[x], Vector2(x, -29), 0.0, 6.0)
		i += 1
		if x < 20.0:
			k.house(x, -13, PI, 7.0, 6.0, 4.0 + (i % 2) * 1.2, Color.html(walls[i]), Color.html(roofs[i]), {"chimney": i % 2 == 1})
			_cottage_door(k, "hv_6", Vector2(x, -13), PI, 6.0)
		i += 1
	_palace(k)
	# The library, with its round reading tower.
	k.house(LIBRARY.x, LIBRARY.y, PI, 12.0, 9.0, 6.0, Color(0.9, 0.92, 1.0), Color.html("4a5aa8"), {"wall": "stone", "storeys": 2, "door": false})
	# Its door opens now that Ottilie has finished cataloguing.
	var ly: float = k.h(LIBRARY.x, LIBRARY.y) - 0.2
	k.door_link(Vector3(LIBRARY.x, ly, LIBRARY.y - 4.56), 0.0, 1.2, 2.1, "library")
	k.entrance("from_library", LIBRARY.x, LIBRARY.y - 6.5, 0.0)
	k.tower(LIBRARY.x + 6.5, LIBRARY.y + 4.0, 2.3, 11.0, "stone", Color(0.9, 0.92, 1.0), Color.html("4a5aa8"), PI)
	k.statue(LIBRARY.x - 7.5, LIBRARY.y - 7.0, 0.0, 0.8)
	# The old well (the blueprint's well, south of the plaza) and the bell tower.
	k.well(0, 22)
	k.tower(39, 4, 2.4, 12.0, "stone", Color(0.95, 0.9, 0.85), Color.html("b84a32"), PI * 0.5, {"sides": 4, "door_w": 1.4, "door_h": 2.4})
	# Gardens, hedges and trees.
	k.fence([Vector2(-44, -4), Vector2(-30, -4), Vector2(-30, 4), Vector2(-44, 4)], Color(0.95, 0.9, 0.85))
	for x in range(-42, -31, 3):
		for z in [-2.0, 1.0]:
			k.bush(x, z, 0.5, Color(0.7, 1.0, 0.6))
	for p in [Vector2(-42, -36), Vector2(-20, -38), Vector2(18, -38), Vector2(40, -36), Vector2(42, 14), Vector2(18, 36),
			Vector2(-12, 36), Vector2(-42, 10), Vector2(12, 14), Vector2(-14, 14), Vector2(42, -4), Vector2(-8, -36)]:
		k.tree_round(p.x + r.randf_range(-1, 1), p.y + r.randf_range(-1, 1), r.randf_range(1.0, 1.3))
	for j in 30:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		if path_dist(x, z) > 3.0 and Vector2(x, z).distance_to(PLAZA) > 15.0 and not in_corridor(x, z):
			if j % 3 == 0:
				k.flowers(x, z, 1.5, 6)
			else:
				k.bush(x, z, r.randf_range(0.6, 1.0))
	# Trees along the rim top.
	for j in 24:
		var a := TAU * j / 24.0
		var x := cos(a) * 58.0
		var z := sin(a) * 52.0
		x = clampf(x, x_min - 4, x_max + 4)
		z = clampf(z, z_min - 4, z_max + 4)
		if not in_corridor(x, z, 5.0):
			var scale := r.randf_range(1.2, 1.6)
			if not (north_open and z < -40.0):
				k.tree_round(x, z, scale, Color(0.85, 0.95, 0.85))


## Himeko's palace: pink plaster and a plum roof, gold trim, a turret at each
## front corner flying her banners, a red carpet up the steps to the door,
## and roses (only the best) all round. Inside is its own area, himeko_house.
func _palace(k) -> void:
	var pink := Color.html("f4c4d4")
	var plum := Color.html("7a2a5a")
	var gold := Color.html("e0b84a")
	k.house(PALACE.x, PALACE.y, PI, PALACE_W, PALACE_D, 5.4, pink, plum, {"storeys": 2, "door": false, "roof_h": 3.4})
	var py: float = k.h(PALACE.x, PALACE.y) - 0.2
	var front := PALACE.y - PALACE_D * 0.5
	# Gold trim under the eaves and round the doorway, a balcony over the door.
	var trim = k._tmp(false)
	trim.box(Vector3(PALACE.x, py + 5.35, front - 0.06), Vector3(PALACE_W + 0.1, 0.2, 0.08), gold)
	trim.box(Vector3(PALACE.x, py + 2.55, front - 0.08), Vector3(2.4, 0.22, 0.1), gold)
	for sx in [-1.0, 1.0]:
		trim.box(Vector3(PALACE.x + sx * 1.1, py + 1.3, front - 0.08), Vector3(0.2, 2.5, 0.1), gold)
	trim.box(Vector3(PALACE.x, py + 3.05, front - 0.75), Vector3(3.4, 0.16, 1.5), Color.html("f8e8f0"))
	for i in 7:
		trim.box(Vector3(PALACE.x - 1.6 + i * 0.533, py + 3.4, front - 1.45), Vector3(0.08, 0.6, 0.08), gold)
	trim.box(Vector3(PALACE.x, py + 3.72, front - 1.45), Vector3(3.4, 0.08, 0.1), gold)
	# Her crest over the balcony: a gold fan on a plum ground.
	trim.box(Vector3(PALACE.x, py + 4.5, front - 0.05), Vector3(1.2, 0.9, 0.06), plum)
	for i in 7:
		var a := deg_to_rad(-60.0 + i * 20.0)
		trim.push(Transform3D(Basis(Vector3.BACK, a), Vector3(PALACE.x, py + 4.2, front - 0.1)))
		trim.box(Vector3(0, 0.3, 0), Vector3(0.07, 0.6, 0.03), gold)
		trim.pop()
	k.merge(trim, "char")
	k.door_link(Vector3(PALACE.x, py + 0.2, front - 0.06), 0.0, 1.3, 2.2, "himeko_house", "from_village", Color(1.0, 0.85, 0.9))
	k.entrance("from_himeko_house", PALACE.x, front - 2.4, 0.0)
	# The turrets, with their pennants.
	for sx in [-1.0, 1.0]:
		var tx: float = PALACE.x + sx * (PALACE_W * 0.5 + 0.2)
		var tz: float = front + 0.4
		k.tower(tx, tz, 1.3, 7.5, "plaster", pink, plum, 0.0, {"sides": 10, "seal": "open", "roof_h": 3.2})
		k.banner(tx, py + 6.8, tz - 1.38, 0.0, Color.html("c83a7a"), 2.0)
	# The red carpet up to the door, and the low step under it.
	k.platform(PALACE.x, front - 0.7, Vector2(2.6, 1.2), py + 0.25, "stone", Color(1.0, 0.95, 0.96))
	var carpet = k._tmp(false)
	carpet.box(Vector3(PALACE.x, py + 0.27, front - 0.75), Vector3(1.3, 0.02, 1.2), Color.html("b8182a"))
	for j in 5:
		var cz := front - 1.6 - j * 1.2
		carpet.box(Vector3(PALACE.x, k.h(PALACE.x, cz) + 0.03, cz), Vector3(1.3, 0.04, 1.2), Color.html("b8182a"))
		carpet.box(Vector3(PALACE.x - 0.68, k.h(PALACE.x, cz) + 0.035, cz), Vector3(0.06, 0.04, 1.2), gold)
		carpet.box(Vector3(PALACE.x + 0.68, k.h(PALACE.x, cz) + 0.035, cz), Vector3(0.06, 0.04, 1.2), gold)
	k.merge(carpet, "char")
	# Her rose garden behind a white fence with gold-tipped posts.
	var gz := front - 1.0
	k.fence([Vector2(PALACE.x - 1.6, gz - 6.0), Vector2(PALACE.x - 7.5, gz - 6.0), Vector2(PALACE.x - 7.5, gz)], Color(1.0, 0.98, 0.98))
	k.fence([Vector2(PALACE.x + 1.6, gz - 6.0), Vector2(PALACE.x + 7.5, gz - 6.0), Vector2(PALACE.x + 7.5, gz)], Color(1.0, 0.98, 0.98))
	for sx in [-1.0, 1.0]:
		for j in 3:
			k.flowers(PALACE.x + sx * (3.0 + j * 1.6), gz - 2.6 - (j % 2) * 1.6, 1.3, 9, ["d8203a", "f070a0", "fff0f4"])
		k.bush(PALACE.x + sx * 6.4, gz - 4.6, 0.8, Color(0.75, 1.0, 0.7))
	k.lamp(PALACE.x - 2.2, gz - 6.6)
	k.lamp(PALACE.x + 2.2, gz - 6.6)


## Haven Village is safe: no monsters, but pots to break by the shops, grass
## in the gardens, signs and a few rupees tucked away.
func populate(k) -> void:
	# Years later (Chapter V): grown-up Pepper comes visiting, by the hero's door.
	k._dyn("res://scripts/npc/pepper.gd", "Pepper", k.g(HOME.x + 2.0, HOME.y - 7.5), PI, {"grown": true}, Node3D.new())
	k.signpost(4.5, -33, Vector2(4.5, -26), "*Haven Village*\nHome of Sir Gigglebuns IV,\nknight of Haven.")
	k.signpost(-43, 8, Vector2(-36, 8), "West: *Southern Fields*\nNorth: *Bunsriel Fields*")
	k.signpost(LIBRARY.x - 4.0, LIBRARY.y - 7.5, LIBRARY + Vector2(-4, -12), "*Haven Library*\nOpen to all!\nPlease mind the rug.")
	k.signpost(PALACE.x - 2.6, PALACE.y - PALACE_D * 0.5 - 7.6, Vector2(PALACE.x - 2.6, -24.0), "*The Palace of Princess Himeko*\nPrincess of Haven Village\n\nCommoners are welcome.\nPlease wipe your feet.")
	for p in [Vector2(-31.5, -23.0), Vector2(-32.5, -22.2), Vector2(-11.5, -21.5), Vector2(-10.6, -22.4), Vector2(11.0, -18.5), Vector2(28.0, -18.4), Vector2(29.0, -17.6)]:
		k.pot(p.x, p.y)
	k.pot(HOME.x + 4.6, HOME.y - 3.4, "rupee_blue")
	for c in [Vector2(-20, 20), Vector2(20, 20), Vector2(40, -20), Vector2(-40, 25), Vector2(10, 38)]:
		k.shrubs_near(c, 5.0, 5)
	k.collectible("rupee_green", 0.0, 22.0, k.h(0, 22) + 3.45)
	k.collectible("rupee_red", LIBRARY.x + 4.0, LIBRARY.y + 7.0)
	# After the sealing (Chapter IV): Ashwick's people, come to live in Haven.
	k.npc("Maud", "res://assets/models/maud.tscn", "res://scripts/npc/maud_lines.gd", 12.0, 24.0, PI * 0.8, INF, {"show": "ch4:peace"})
	k.npc("Tamsin", "res://assets/models/tamsin.tscn", "res://scripts/npc/ashwick_lines.gd", -6.0, 14.0, PI * 0.2, INF, {"show": "ch4:peace"})
	# The rooster who crows the hero awake, pecking about near his house.
	k.rooster(HOME.x + 6.0, HOME.y - 8.0)


## The door of a cottage you can walk into (HouseData, Beta 1.5.0), on the
## house's front (local +Z turned by `face`), and its entrance outside.
func _cottage_door(k, hid: String, c: Vector2, face: float, depth: float) -> void:
	var f := Vector2(sin(face), cos(face))
	var at := c + f * (depth * 0.5 + 0.06)
	var y: float = k.h(c.x, c.y) - 0.2
	k.door_link(Vector3(at.x, y, at.y), face + PI, 1.2, 2.1, hid, "from_village", Color(0.85, 0.75, 0.6))
	var out := c + f * (depth * 0.5 + 1.6)
	k.entrance("from_" + hid, out.x, out.y, face + PI)
