extends "res://tools/world/region.gd"
## The Batela Fells: Firebuns III's homeland, which he burned with the
## Gauntlet of Fire. Upland moors of ash and burnt heather under a dead gray
## sky, ash still falling; charred pines, two dead villages, a black tarn,
## the burnt bell tower, and on the north ridge the ruins of Batela Keep,
## where Firebuns ruled and was poisoned in his sleep. The last of his people
## camp at Ashwick. Under the old chapel's crypt lies the Sapphire Sanctum,
## the Order's hideout. Chapter III.
##
## North is -Z. The road comes in from the Forest of the Dead in the west.

const CAMP := Vector2(-20, 30)
const KEEP := Vector2(12, -44)
const KEEP_Y := 6.0
const CHAPEL := Vector2(-50, -24)
const TARN := Vector2(46, 26)
const TARN_Y := -1.1
const BELL := Vector2(56, -22)
const VILLAGE_W := Vector2(-48, 4)
const VILLAGE_E := Vector2(28, -4)
## The burnt bell tower: footprint half-size, the ledge and the top.
const BELL_HALF := 2.6
const BELL_LEDGE := 7.0
const BELL_TOP := 14.0

var paths: Array = [
	[Vector2(-90, 20), Vector2(-56, 22), CAMP + Vector2(-8, 0)],
	[CAMP + Vector2(6, -6), Vector2(-4, 4), Vector2(8, -14), KEEP + Vector2(0, 22)],
	[Vector2(-4, 4), Vector2(-30, -4), CHAPEL + Vector2(0, 10)],
	[Vector2(8, -14), VILLAGE_E, Vector2(44, -14), BELL + Vector2(-6, 0)],
	[CAMP + Vector2(10, 4), Vector2(20, 22), TARN + Vector2(-16, 0)],
]


func setup() -> void:
	id = "batela_fells"
	seed_value = 1100
	x_min = -80.0
	x_max = 80.0
	z_min = -70.0
	z_max = 66.0
	rim_height = 18.0
	rim_margin = 8.0
	cliff_col = Color(0.6, 0.57, 0.54)
	rock_col = Color.html("4e4a46")
	links = [
		{"to": "forest_of_the_dead", "p": Vector2(-80, 20), "d": Vector2(1, 0), "w": 5.0, "y": 0.4},
	]
	water = [{"rect": Rect2(TARN.x - 13, TARN.y - 10, 26, 20), "y": TARN_Y, "col": Color(0.1, 0.12, 0.14, 0.9)}]
	mood = {
		"sky_top": Color.html("3a3634"), "sky_mid": Color.html("5a544e"), "sky_horizon": Color.html("8a7a6a"),
		"cloud": Color.html("6a625a"), "cloud_amount": 0.75,
		"fog": Color.html("625a52"), "fog_begin": 18.0, "fog_end": 110.0,
		"ambient": Color.html("6a625a"), "sun": Color.html("d8c0a0"), "sun_energy": 0.6, "sun_rot": Vector3(-35, 40, 0),
		"fill": Color.html("5a4a44"), "fill_energy": 0.35,
		"horizon": Color.html("4a443e"), "hill_height": 16.0, "particles": "ash",
		"far": [
			{"type": "mesa", "yaw": 20.0, "w": 60.0, "h": 22.0, "col": Color.html("4a443e")},
			{"type": "mesa", "yaw": 110.0, "w": 80.0, "h": 14.0, "col": Color.html("524a44")},
			{"type": "mesa", "yaw": 300.0, "w": 50.0, "h": 26.0, "col": Color.html("463e3a")},
		],
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var h := 0.6 + noise.get_noise_2d(x * 0.9, z * 0.9) * 3.2 + detail.get_noise_2d(x * 0.3, z * 0.3) * 0.4
	# The keep's ridge in the north, climbing from the moor.
	h += mesa(x, z, KEEP, 20.0, 34.0) * (KEEP_Y - 0.6)
	h = lerpf(h, KEEP_Y, mesa(x, z, KEEP, 17.0, 19.0))
	# The road up to the keep: a ramp cut into the ridge's south face.
	var ramp := seg_dist(p, KEEP + Vector2(0, 16), KEEP + Vector2(0, 34))
	if ramp < 4.5:
		var t := clampf((p.y - (KEEP.y + 16.0)) / 18.0, 0.0, 1.0)
		h = lerpf(h, lerpf(KEEP_Y, 1.0, t), 1.0 - smoothstep(3.0, 4.5, ramp))
	# Level ground for the camp, the chapel and the tower.
	for c in [[CAMP, 14.0, 0.8], [CHAPEL, 12.0, 0.9], [BELL, 6.0, 1.0], [VILLAGE_W, 10.0, 0.8], [VILLAGE_E, 9.0, 0.9]]:
		var flat := 1.0 - smoothstep(float(c[1]) * 0.7, float(c[1]), p.distance_to(c[0]))
		h = lerpf(h, c[2], flat)
	# The tarn's basin.
	var dt := Vector2((x - TARN.x) / 1.3, z - TARN.y).length()
	if dt < 15.0:
		h = lerpf(TARN_Y - 1.8, h, smoothstep(7.0, 15.0, dt))
	# Paths worn a little flatter.
	h = lerpf(h * 0.6 + 0.3, h, smoothstep(1.5, 6.0, path_dist(x, z)))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if Vector2((x - TARN.x) / 1.3, z - TARN.y).length() < 11.0 and h < TARN_Y + 0.3:
		return pick(r, ["2a2622", "322c26"])
	if p.distance_to(KEEP) < 17.0:
		var seam := fposmod(x, 2.0) < 0.12 or fposmod(z, 2.0) < 0.12
		return Color.html("4a4440") if seam else pick(r, ["6a645e", "625c56", "726c64"])
	if path_dist(x, z) < 1.8 + r.randf_range(-0.4, 0.4):
		return pick(r, ["6a5e50", "625648", "70645a"])
	if p.distance_to(CAMP) < 11.0:
		return pick(r, ["5a5040", "625846", "54493a"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	var ash := Color.html("4a4642").lerp(Color.html("6e6862"), clampf(b + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))
	# Burnt heather in patches, a dull purple-brown.
	if detail.get_noise_2d(x * 1.5, z * 1.5) > 0.25:
		ash = ash.lerp(Color.html("5a4448"), 0.5)
	if r.randf() < 0.02:
		return Color.html("8a3a20")   # embers still glowing in the ash
	return ash


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	if Vector2(x, z).distance_to(KEEP) < 17.0:
		return "stone"
	return super.surface_at(x, z, h, r) if path_dist(x, z) < 2.0 else "ash"


func build(k) -> void:
	# The first sight of the Fells, just out of the forest road.
	k.story_trigger("fells_arrive", Rect2(-70.0, 13.0, 8.0, 14.0), k.h(-66.0, 20.0) - 1.0, "ch3:arrived", "", 5.0)
	_camp(k)
	_keep(k)
	_chapel(k)
	_bell_tower(k)
	_villages(k)
	_scatter(k)


# --- Ashwick ------------------------------------------------------------------

func _camp(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var cloths := [Color.html("8a7a5a"), Color.html("6a5a4a"), Color.html("7a6a6a"), Color.html("8a8270"), Color.html("6a6a5a")]
	# A ring of tents round the fire, Elder Maud's the big one on the north side.
	var tents := ["aw_1", "aw_2", "aw_3"]
	for i in 6:
		var a := TAU * i / 6.0 + 0.5
		var at := CAMP + Vector2(cos(a), sin(a)) * 9.0
		if absf(a - TAU * 0.75) < 0.4:
			continue
		var face: float = k.yaw_of((CAMP - at).normalized())
		k.tent(at.x, at.y, face, 3.2, 3.6, 2.2, cloths[i % cloths.size()])
		# Three of them you can step into (HouseData, Beta 1.5.0).
		if not tents.is_empty():
			var hid: String = tents.pop_front()
			var f := (CAMP - at).normalized()
			var door := at + f * 1.85
			k.door_link(Vector3(door.x, k.h(door.x, door.y), door.y), face, 1.1, 1.8, hid, "from_batela_fells", Color(0.5, 0.45, 0.38))
			var out := at + f * 3.3
			k.entrance("from_" + hid, out.x, out.y, face)
	var maud := CAMP + Vector2(0, -10.5)
	k.tent(maud.x, maud.y, 0.0 + PI, 5.2, 5.0, 3.0, Color.html("7a5a4a"))
	k.mark("cs_ashwick_bed", Vector3(maud.x, k.h(maud.x, maud.y) + 0.05, maud.y + 0.6), PI)
	k.mark("cs_ashwick_cam", Vector3(maud.x + 3.2, k.h(maud.x, maud.y) + 2.0, maud.y + 4.5))
	k.entrance("ashwick_bed", maud.x, maud.y + 5.0, PI)
	# The fire and the cook pot.
	k.fire(CAMP.x, CAMP.y, 0.9)
	var pot = k._tmp(false)
	var pp: Vector3 = k.g(CAMP.x + 1.6, CAMP.y + 0.4)
	pot.prism(pp, 0.42, pp + Vector3(0, 0.5, 0), 0.5, 10, Color.html("2a2826"))
	for s in [-1.0, 1.0]:
		pot.box(pp + Vector3(s * 0.7, 0.6, 0), Vector3(0.06, 1.2, 0.06), Color.html("4a3a28"))
	pot.box(pp + Vector3(0, 1.2, 0), Vector3(1.5, 0.06, 0.06), Color.html("4a3a28"))
	k.merge(pot, "char")
	k.col_cyl(pp, 0.5, 0.6)
	for i in 5:
		var a := TAU * i / 5.0 + 1.0
		k.log(CAMP.x + cos(a) * 3.2, CAMP.y + sin(a) * 3.2, 1.8, a + PI * 0.5, 0.25)
	# Carts, crates and what little they saved.
	for c in [[CAMP + Vector2(12, 4), 0.4], [CAMP + Vector2(-12, 6), -0.6], [CAMP + Vector2(10, -6), 1.2]]:
		var at: Vector2 = c[0]
		k.crate(at.x, at.y, c[1])
		k.crate(at.x + 0.9, at.y + 0.3, c[1] + 0.3, 0.8)
		k.barrel(at.x - 0.6, at.y + 1.0)
	k.fence([CAMP + Vector2(-15, 10), CAMP + Vector2(-8, 15), CAMP + Vector2(4, 15), CAMP + Vector2(14, 9)], Color(0.6, 0.55, 0.5))
	# Washing lines and banners of the old Batela colors, faded.
	k.banner(maud.x - 2.8, k.h(maud.x, maud.y) + 3.4, maud.y + 2.5, PI, Color.html("6a2a2a"), 1.6)
	k.banner(maud.x + 2.8, k.h(maud.x, maud.y) + 3.4, maud.y + 2.5, PI, Color.html("6a2a2a"), 1.6)
	k.music_zone(Vector3(CAMP.x, k.h(CAMP.x, CAMP.y) + 3.0, CAMP.y - 1.0), Vector3(34, 10, 34), "ashwick")
	k.signpost(CAMP.x - 15.0, CAMP.y - 4.0, CAMP + Vector2(-22, -6), "*Ashwick*\nAll who flee the fire are welcome.\nPlease keep the dead out of the camp.")


# --- Batela Keep ------------------------------------------------------------------

func _keep(k) -> void:
	var y := KEEP_Y
	var col := Color(0.62, 0.6, 0.58)
	var dark := Color(0.45, 0.43, 0.42)
	# The outer wall round the ridge top, broken and blackened.
	var ring: Array = []
	for i in 13:
		var a := TAU * i / 12.0 + PI * 0.5
		ring.append(KEEP + Vector2(cos(a) * 16.0, sin(a) * 14.0))
	for i in 12:
		if i == 0 or i == 5 or i == 9:
			continue   # breaches: the gate (south) and two falls of stone
		k.wall_line([ring[i], ring[i + 1]], 3.5 if i % 3 != 1 else 1.8, 1.2, "stone", col, i % 2 == 0, y - 0.3)
	k.gatehouse(KEEP.x, KEEP.y + 14.5, 0.0, 4.5, 7.0, "stone", col)
	for i in [0, 5, 9]:
		var mid: Vector2 = ((ring[i] as Vector2) + (ring[i + 1] as Vector2)) * 0.5
		if i != 0:
			k.rubble(mid.x, mid.y, 0.3 * i, 1.3, y)
	# The great hall: its roof long gone, two walls standing, the throne on its dais.
	var hall := KEEP + Vector2(0, -4)
	k.wall_line([hall + Vector2(-9, -8), hall + Vector2(9, -8)], 7.0, 1.0, "stone", dark, true, y - 0.2)
	k.wall_line([hall + Vector2(-9, -8), hall + Vector2(-9, 2)], 5.0, 1.0, "stone", dark, false, y - 0.2)
	k.wall_line([hall + Vector2(9, -8), hall + Vector2(9, -3)], 3.0, 1.0, "stone", dark, false, y - 0.2)
	k.platform(hall.x, hall.y - 5.5, Vector2(6.0, 3.0), y + 0.6, "stone", dark)
	var throne = k._tmp()
	var tp := Vector3(hall.x, y + 0.6, hall.y - 6.2)
	throne.box(tp + Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 1.0), Color.html("3a2a2a"))
	throne.box(tp + Vector3(0, 1.6, -0.4), Vector3(1.4, 2.4, 0.25), Color.html("3a2a2a"))
	throne.box(tp + Vector3(0, 2.9, -0.4), Vector3(0.5, 0.5, 0.25), Color.html("8a6a2a"))
	k.merge(throne, "stone")
	k.col_box(tp + Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 1.0))
	for x in [-6.0, -2.0, 2.0, 6.0]:
		k.pillar(hall.x + x, hall.y - 1.0, 6.0 if absf(x) < 4.0 else 3.0, 0.55, absf(x) > 4.0, "stone", y)
	# The Firebuns portraits on the hall's back wall (Examine): the Evil King,
	# the good Firebuns who died a hero, and an empty frame.
	for i in 3:
		var px := hall.x - 4.0 + i * 4.0
		var frame = k._tmp(false)
		var fp := Vector3(px, y + 3.0, hall.y - 7.45)
		frame.box(fp, Vector3(1.6, 2.0, 0.08), Color.html("6a4a1a"))
		var paint: Color = [Color.html("6a1a1a"), Color.html("2a4a6a"), Color.html("1a1614")][i]
		frame.box(fp + Vector3(0, 0, 0.05), Vector3(1.3, 1.7, 0.02), paint)
		if i < 2:
			frame.box(fp + Vector3(0, 0.25, 0.07), Vector3(0.5, 0.6, 0.02), Color.html("d8a888"))
			frame.box(fp + Vector3(0, 0.62, 0.075), Vector3(0.55, 0.18, 0.02), Color.html("e86a2a") if i == 0 else Color.html("e8c040"))
		k.merge(frame, "char")
		var ex: Node3D = k.examine(Vector3(px, y, hall.y - 6.6), 0.0, [], "res://scripts/npc/batela_lines.gd", "portrait_%d" % (i + 1), 1.6)
		ex.set("front_only", false)
	# Where Firebuns waits, and the duel.
	k.mark("cs_keep_firebuns", Vector3(hall.x, y + 0.6, hall.y - 5.0), 0.0)
	k.mark("cs_keep_hero", Vector3(hall.x, y, hall.y + 4.0), PI)
	k.mark("cs_keep_cam", Vector3(hall.x + 5.0, y + 3.0, hall.y + 8.0))
	k.story_trigger("keep_duel", Rect2(hall.x - 8.0, hall.y - 2.0, 16.0, 8.0), y, "ch3:keep_duel", "ch3:maud_met")
	k.entrance("keep_hall", hall.x, hall.y + 6.0, 0.0)
	# Braziers burning cold and blue at the gate: the Order's work.
	for s in [-1.0, 1.0]:
		k.brazier(KEEP.x + s * 4.0, KEEP.y + 11.0, true, y)


# --- The chapel and its crypt ------------------------------------------------

func _chapel(k) -> void:
	var col := Color(0.66, 0.64, 0.6)
	var c := CHAPEL
	# The nave's broken walls, the altar and a fallen bell.
	k.wall_line([c + Vector2(-6, 9), c + Vector2(-6, -9), c + Vector2(-2, -11)], 4.5, 0.9, "stone", col)
	k.wall_line([c + Vector2(2, -11), c + Vector2(6, -9), c + Vector2(6, 2)], 3.5, 0.9, "stone", col)
	k.wall_line([c + Vector2(6, 6), c + Vector2(6, 9)], 2.0, 0.9, "stone", col)
	k.pillar(c.x - 3.0, c.y + 9.0, 5.0, 0.5, true, "stone")
	k.pillar(c.x + 3.0, c.y + 9.0, 3.0, 0.5, true, "stone")
	k.platform(c.x, c.y - 7.0, Vector2(4.0, 1.6), 1.6, "stone", col.darkened(0.2))
	k.rubble(c.x + 3.0, c.y - 2.0, 0.6, 1.0)
	for z in [3.0, 0.0, -3.0]:
		for s in [-1.0, 1.0]:
			k.log(c.x + s * 2.6, c.y + z, 2.6, PI * 0.5, 0.18)
	# The crypt: a stone mouth in the floor of the nave, steps going down,
	# behind an iron gate that only Elder Maud can open.
	var crypt := c + Vector2(0, 3.5)
	var mk = k._tmp()
	var base: Vector3 = k.g(crypt.x, crypt.y)
	mk.box(base + Vector3(0, 1.3, -1.5), Vector3(4.2, 2.6, 0.6), col.darkened(0.25))
	for s in [-1.0, 1.0]:
		mk.box(base + Vector3(s * 1.8, 1.3, 0.0), Vector3(0.6, 2.6, 3.0), col.darkened(0.25))
	mk.box(base + Vector3(0, 2.8, -0.2), Vector3(4.4, 0.5, 3.4), col.darkened(0.3))
	k.merge(mk, "stone")
	# Its walls can't be climbed to drop in behind the gate, and the door
	# itself waits for Maud as well (Beta 1.5.1).
	k.col_box(base + Vector3(0, 1.3, -1.5), Vector3(4.2, 2.6, 0.6)).set_meta("no_climb", true)
	for s in [-1.0, 1.0]:
		k.col_box(base + Vector3(s * 1.8, 1.3, 0.0), Vector3(0.6, 2.6, 3.0)).set_meta("no_climb", true)
	k.door_link(base + Vector3(0, 0, -1.15), PI, 1.8, 2.4, "sapphire_sanctum", "from_batela_fells", Color(0.25, 0.3, 0.5), "ch3:confession")
	k.entrance("from_sapphire_sanctum", crypt.x, crypt.y + 3.5, 0.0)
	k.entrance("warp_sapphire_sanctum", crypt.x + 2.0, crypt.y + 5.0, 0.0)
	var gate = k._tmp(false)
	for i in 6:
		gate.box(Vector3(-1.0 + i * 0.4, 1.2, 0), Vector3(0.08, 2.4, 0.08), Color.html("3a3a40"))
	for yy in [0.3, 1.2, 2.2]:
		gate.box(Vector3(0, yy, 0), Vector3(2.4, 0.1, 0.1), Color.html("3a3a40"))
	gate.box(Vector3(0, 1.2, 0.08), Vector3(0.35, 0.35, 0.08), Color.html("4a5ac8"))
	k.flag_barrier(base + Vector3(0, 0, 1.4), Vector3(3.0, 3.0, 0.4), 0.0, "ch3:confession", gate, "char")


# --- The burnt bell tower ----------------------------------------------------------

func _bell_tower(k) -> void:
	var b := BELL
	var g0: float = k.h(b.x, b.y)
	var col := Color(0.5, 0.47, 0.44)
	# The square shaft, charred black at the top.
	k.block(Vector3(b.x, g0 + BELL_TOP * 0.5 - 0.3, b.y), Vector3(BELL_HALF * 2.0, BELL_TOP, BELL_HALF * 2.0), 0.0, "stone", col)
	# The ledge on the south face, halfway up: the ladder reaches it, and no further.
	k.block(Vector3(b.x, g0 + BELL_LEDGE - 0.25, b.y + BELL_HALF + 0.9), Vector3(3.0, 0.5, 1.8), 0.0, "stone", col.darkened(0.1))
	k.ladder(b.x - 0.8, b.y + BELL_HALF + 1.82, Vector2(0, 1), g0, g0 + BELL_LEDGE)
	# A charred beam over the top, a Hookshot target in it.
	k.hook_target(Vector3(b.x, g0 + BELL_TOP - 0.6, b.y + BELL_HALF + 0.02), PI)
	# The top: the broken frame and the cracked bell.
	var top := g0 + BELL_TOP - 0.3
	var bm = k._tmp(false)
	for s in [-1.0, 1.0]:
		bm.box(Vector3(b.x + s * 1.9, top + 1.4, b.y), Vector3(0.3, 2.8, 0.3), Color.html("2a2420"))
	bm.box(Vector3(b.x, top + 2.9, b.y), Vector3(4.2, 0.3, 0.3), Color.html("2a2420"))
	bm.prism(Vector3(b.x + 0.4, top, b.y + 0.6), 0.8, Vector3(b.x + 0.3, top + 1.0, b.y + 0.5), 0.45, 10, Color.html("5a5040"))
	k.merge(bm, "char")
	k.col_cyl(Vector3(b.x + 0.4, top, b.y + 0.6), 0.8, 1.0)
	k.mark("bell_top", Vector3(b.x - 1.0, top, b.y - 1.0))


# --- The dead villages ---------------------------------------------------------------

## A burnt cottage: two or three stubs of wall, a heap of rubble, black beams.
func _ruin(k, x: float, z: float, yaw: float, r: RandomNumberGenerator) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var c := Vector2(x, z)
	var pts: Array = []
	for v in [Vector2(-3, -2.5), Vector2(3, -2.5), Vector2(3, 2.5), Vector2(-3, 2.5)]:
		var w := basis * Vector3(v.x, 0, v.y)
		pts.append(c + Vector2(w.x, w.z))
	for i in 4:
		if r.randf() < 0.3:
			continue
		k.wall_line([pts[i], pts[(i + 1) % 4]], r.randf_range(1.2, 3.0), 0.5, "plaster", Color(0.45, 0.42, 0.4))
	k.rubble(x + r.randf_range(-1.0, 1.0), z + r.randf_range(-1.0, 1.0), r.randf() * TAU, r.randf_range(0.9, 1.3))
	k.log(x, z, 5.0, yaw + r.randf_range(-0.4, 0.4), 0.2)


func _villages(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for v in [[VILLAGE_W, 3], [VILLAGE_E, 3]]:
		var c: Vector2 = v[0]
		for i in int(v[1]):
			var a := TAU * i / float(v[1]) + 0.4
			var at := c + Vector2(cos(a), sin(a)) * 6.5
			_ruin(k, at.x, at.y, a, r)
		k.well(c.x, c.y)
		k.fire(c.x + 3.5, c.y - 2.0, 0.4, INF, false)


# --- The moor -----------------------------------------------------------------

func _scatter(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for i in 140:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		var p := Vector2(x, z)
		if path_dist(x, z) < 3.5 or in_corridor(x, z, 3.0):
			continue
		if p.distance_to(CAMP) < 17.0 or p.distance_to(KEEP) < 20.0 or p.distance_to(CHAPEL) < 13.0 or p.distance_to(BELL) < 7.0:
			continue
		if Vector2((x - TARN.x) / 1.3, z - TARN.y).length() < 14.0 or p.distance_to(VILLAGE_W) < 11.0 or p.distance_to(VILLAGE_E) < 10.0:
			continue
		match i % 6:
			0, 1, 2:
				k.tree_dead(x, z, r.randf_range(0.8, 1.5))
			3:
				k.rock(x, z, r.randf_range(0.5, 1.5), "rock", true, Color(0.7, 0.66, 0.62))
			4:
				k.bush(x, z, r.randf_range(0.4, 0.8), Color(0.45, 0.4, 0.38))
			5:
				k.stump(x, z, r.randf_range(0.7, 1.1))
	# Standing stones on the moor, older than the Firebuns.
	for i in 5:
		var a := TAU * i / 5.0
		k.spire(-58.0 + cos(a) * 5.0, 44.0 + sin(a) * 5.0, 0.6, 3.0, "rock", Color(0.6, 0.58, 0.55), 0.8, 5)


func populate(k) -> void:
	# Ashwick's people.
	var maud := CAMP + Vector2(0, -7.6)
	k.npc("Maud", "res://assets/models/maud.tscn", "res://scripts/npc/maud_lines.gd", maud.x, maud.y, 0.0, INF, {"hide": "ch4:peace"})
	k.npc("Wren", "res://assets/models/wren.tscn", "res://scripts/npc/ashwick_lines.gd", CAMP.x - 7.5, CAMP.y + 5.0, k.yaw_of(Vector2(1, -0.5)))
	k.npc("Odile", "res://assets/models/odile.tscn", "res://scripts/npc/ashwick_lines.gd", CAMP.x + 6.0, CAMP.y - 2.5, k.yaw_of(Vector2(-1, 0.3)))
	k.npc("Tamsin", "res://assets/models/tamsin.tscn", "res://scripts/npc/ashwick_lines.gd", CAMP.x - 2.5, CAMP.y + 3.0, k.yaw_of(Vector2(0.4, -1)), INF, {"hide": "ch4:peace"})
	# The moor: charred stalfos among the dead trees, fire keese over the ruins.
	for c in [Vector2(-40, -10), Vector2(30, 10), Vector2(-10, -20), Vector2(50, -40), Vector2(-60, 40)]:
		k.enemies_near("charred_stalfos", c, 8.0, 1)
	for c in [VILLAGE_W, VILLAGE_E, CHAPEL]:
		k.enemies_near("fire_keese", c, 6.0, 2)
	k.enemies_near("keese", BELL + Vector2(-8, 6), 5.0, 2)
	for p in [VILLAGE_W + Vector2(2, 3), VILLAGE_W + Vector2(-2, -3), VILLAGE_E + Vector2(3, -2)]:
		k.pot(p.x, p.y)
	k.pot(VILLAGE_E.x - 3.0, VILLAGE_E.y + 2.0, "rupee_red")
	for c in [Vector2(-30, 50), Vector2(30, 45), Vector2(-60, -45)]:
		k.lift_rocks_near(c, 6.0, 2, Color(0.75, 0.7, 0.65))
		k.shrubs_near(c, 5.0, 3, Color(0.6, 0.55, 0.5))
	# The burnt bell tower's Piece of Heart, and two pages of the Incunabulum.
	k.heart_piece(BELL.x - 1.0, BELL.y - 1.0, "fells:bell_heart", k.h(BELL.x, BELL.y) + BELL_TOP)
	k.incunabulum_page(VILLAGE_W.x + 4.0, VILLAGE_W.y - 5.0, 2)
	k.incunabulum_page(KEEP.x - 12.0, KEEP.y + 6.0, 3, KEEP_Y)
	# The sixth treasure chart's X: in the ashes under the burnt bell tower.
	var c6: Vector2 = k.spot(BELL + Vector2(-5.0, 5.0), 5.0, 1.2)
	if c6 != Vector2.INF:
		k.dig_spot("chart_6", c6.x, c6.y, TreasureCharts.prize(6), {"soil": "ash"})
