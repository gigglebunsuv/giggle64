extends "res://tools/world/tower_region.gd"
## The Temple of Bun, under the sacred grove of the Dark Forest (Chapter IV):
## the old pedestal temple of Saga III, where Gigglebuns III and Firebuns II
## once came. Pale stone veined with gold, the grove's roots grown through
## its walls, star braziers and star eyes of Lothelye's priests. Its trial is
## of the heart: the hero's own shadow (Dark Gigglebuns), which must not be
## struck when it yields. Its treasure is the Starfall Arrows; its master the
## Pedestal Guardian; at its heart the old pedestal, where the Bun Sword
## wakes and Lothelye gives the Astral Seal.
##
## Storeys, top down (north is -Z); each way down is a drop with a ladder back:
##   1F (y 0)    stair S     down from the grove
##               narthex C   murals of Saga III; locked north (Key 1)
##               roots_w W   roots through the floor: dig -> Key 1
##               roots_e E   shades in the dark (Starlight Lantern); the Map
##               choir N     four star braziers open the floor
##   B1 (y -8)   well N      in by the drop
##               pool C      the mirror-still pool; locked south (Key 2)
##               mirror W    the trial: Dark Gigglebuns -> the Starfall Arrows
##               lamps E     two star eyes -> Key 2
##               crypt S     the knights' tombs; the Compass; the drop down
##   B2 (y -16)  ossuary S   in by the drop; a cracked wall
##               descent C   two weight plates open the floor
##               eyes_w W    three star eyes at once -> Key 3
##               roots_deep E dig spots: a treasure chart
##               bell N      (Key 3) across a chasm by Hookshot -> the Boss Key
##   B3 (y -24)  nave C      in by the drop; the boss door north
##               spring W    a fairy's pool
##               keeper E    the priests' vault
##               boss N      the Pedestal Guardian
##               heart NN    the old pedestal: the sword wakes (Story.temple_heart)

const D := "temple_of_bun"
const STONE := Color(0.9, 0.86, 0.76)
const GOLD := Color(0.86, 0.7, 0.36)
const LADDERS := [
	[2, 0.0, -40.0, Vector2(0, 1)],
	[1, 0.0, 24.0, Vector2(0, -1)],
	[0, 0.0, 6.0, Vector2(0, -1)],
]
const CHOIR_HOLE := Vector3(0.0, 0.0, -38.65)
const DESCENT_HOLE := Vector3(0.0, -16.0, 4.65)


func setup() -> void:
	id = "temple_of_bun"
	interior = true
	seed_value = 1717
	x_min = -46.0
	x_max = 46.0
	z_min = -84.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B3", -24.0], ["B2", -16.0], ["B1", -8.0], ["1F", 0.0]]
	entry_floor = 3
	wall_col = STONE
	ceil_col = Color(0.4, 0.36, 0.3)
	slab_col = Color(0.84, 0.8, 0.7)
	var root := Color(0.72, 0.62, 0.5)
	rooms = {
		# 1F
		"stair": {"f": 3, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"narthex": {"f": 3, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"roots_w": {"f": 3, "r": Rect2(-38, -9, 18, 18), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": root},
		"roots_e": {"f": 3, "r": Rect2(20, -9, 18, 18), "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "col": root.darkened(0.2)},
		"choir": {"f": 3, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B1
		"well": {"f": 2, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		"pool": {"f": 2, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "s", "at": 0.0}], "col": Color(0.86, 0.88, 0.94)},
		"mirror": {"f": 2, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.6, 0.62, 0.72)},
		"lamps": {"f": 2, "r": Rect2(20, -10, 20, 20), "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"crypt": {"f": 2, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}], "col": STONE.darkened(0.15)},
		# B2
		"ossuary": {"f": 1, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}], "col": STONE.darkened(0.25)},
		"descent": {"f": 1, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"eyes_w": {"f": 1, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"roots_deep": {"f": 1, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "col": root.darkened(0.3)},
		"bell": {"f": 1, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B3
		"nave": {"f": 0, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"spring": {"f": 0, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.78, 0.84, 0.9)},
		"keeper": {"f": 0, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"boss": {"f": 0, "r": Rect2(-16, -50, 32, 32), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "col": STONE.darkened(0.1)},
		"heart": {"f": 0, "r": Rect2(-10, -80, 20, 22), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.95, 0.94, 0.98)},
	}
	corridors = [
		{"f": 3, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 3, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 3, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 3, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 2, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 2, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 1, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 1, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 1, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 0, "r": Rect2(-20, -2, 6, 4), "x": true},
		{"f": 0, "r": Rect2(14, -2, 6, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -18, 4, 6), "x": false},
		{"f": 0, "r": Rect2(-2, -58, 4, 8), "x": false},
	]
	holes = []
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	mood = {
		"sky_top": Color.html("14121c"), "sky_mid": Color.html("14121c"), "sky_horizon": Color.html("14121c"),
		"cloud": Color.html("14121c"), "cloud_amount": 0.0,
		"fog": Color.html("181620"), "fog_begin": 14.0, "fog_end": 58.0,
		"ambient": Color.html("6a6478"), "sun": Color.html("f0e8ff"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.5, "fill": Color.html("5a5470"), "fill_energy": 0.45,
		"horizon": Color.html("14121c"), "hill_height": 0.0,
	}


func _inside(x: float, z: float, f: int) -> bool:
	for rid: String in rooms:
		var rm: Dictionary = rooms[rid]
		if rm.f == f and (rm.r as Rect2).grow(1.0).has_point(Vector2(x, z)):
			return true
	for c: Dictionary in corridors:
		if c.f == f and (c.r as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## Pale flagstones with gold seams; root-earth in the root rooms; the pool's
## floor a mirror-dark blue; a great eight-pointed star in the heart.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["0c0a0e", "100e12"])
	var p := Vector2(x, z)
	for rid in ["roots_w", "roots_e", "roots_deep"]:
		if rooms[rid].f == f and (rooms[rid].r as Rect2).has_point(p):
			return Color.html(["4a3a2a", "54422e", "3e3024"][r.randi() % 3])
	if f == 2 and (rooms.pool.r as Rect2).has_point(p) and p.distance_to(room_center("pool")) < 8.0:
		return Color.html("1a2440").lightened(r.randf_range(0.0, 0.06))
	if f == 0 and (rooms.heart.r as Rect2).has_point(p):
		var q := p - room_center("heart")
		var a := fposmod(atan2(q.y, q.x), TAU / 8.0) - TAU / 16.0
		if q.length() < 8.0 - absf(a) * 12.0 and q.length() > 1.5:
			return Color.html("f0e0a0")
	var seam := fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08
	if seam:
		return Color.html("b8964a")
	return Color.html(["d8d0bc", "d0c8b4", "e0d8c4"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.06) + 0.05 * (3 - f))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.6, 2.4, "dark_forest", "from_temple_of_bun", Color(0.85, 0.82, 0.7))
	k.entrance("from_dark_forest", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	_f1(k)
	_b1(k)
	_b2(k)
	_b3(k)


func _lamps(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", y)


## A grate over a hole in the floor at `at` (its top), gone once `flag` is set.
func _cover(k, at: Vector3, flag: String) -> void:
	var m = k._tmp(false)
	for i in 6:
		m.box(Vector3(-1.2 + i * 0.48, -0.1, 0), Vector3(0.12, 0.2, 2.8), GOLD.darkened(0.3))
	for j in 3:
		m.box(Vector3(0, -0.1, -1.0 + j * 1.0), Vector3(2.8, 0.2, 0.12), GOLD.darkened(0.3))
	k.flag_barrier(at + Vector3(0, -0.15, 0), Vector3(2.9, 0.3, 2.9), 0.0, flag, m, "char")


func _star_eye(k, pos: Vector3, yaw: float, opts: Dictionary) -> void:
	k._dyn("res://scripts/dungeon/star_eye.gd", "StarEye", pos, yaw, opts, StaticBody3D.new())


## Roots grown through the wall and floor: thick twisting trunks.
func _roots(k, rid: String, n: int) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	var m = k._tmp()
	var rng: RandomNumberGenerator = k.rng
	for i in n:
		var a := Vector3(rng.randf_range(r.position.x + 1.0, r.end.x - 1.0), y + 6.0, r.position.y + 0.5)
		var b := Vector3(rng.randf_range(r.position.x + 2.0, r.end.x - 2.0), y, rng.randf_range(r.position.y + 2.0, r.end.y - 2.0))
		m.prism(a, 0.5, (a + b) * 0.5 + Vector3(rng.randf_range(-1, 1), 0, 0), 0.38, 6, Color.html("5a4430"))
		m.prism((a + b) * 0.5 + Vector3(rng.randf_range(-1, 1), 0, 0), 0.38, b, 0.2, 6, Color.html("4a3828"))
	k.merge(m, "bark")


# --- 1F ---------------------------------------------------------------------------

func _f1(k) -> void:
	# The stair down from the grove.
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.6, z, 6.0, 0.45, false, "stone", 0.0)
	k.pot(4.2, 28.5, "heart")
	# The narthex: murals of Saga III on its walls.
	k.examine(Vector3(-12.4, 0.0, -4.0), -PI / 2.0, [], "res://scripts/npc/temple_lines.gd", "mural_1")
	k.examine(Vector3(12.4, 0.0, -4.0), PI / 2.0, [], "res://scripts/npc/temple_lines.gd", "mural_2")
	for z in [-8.0, 0.0, 8.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 10.0, z, 6.5, 0.5, false, "stone", 0.0)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key1", false, 0.0)
	_lamps(k, "narthex")
	# West roots: soft earth where the roots broke the floor; Key 1 is buried.
	_roots(k, "roots_w", 4)
	k.dig_spot("temple_key1", -32.0, 4.0, "small_key", {}, 0.0)
	k.dig_spot("temple_root_a", -26.0, -5.0, "rupee_red", {"loose": true}, 0.0)
	k.dig_spot("temple_root_b", -34.0, -5.0, "heart", {"loose": true}, 0.0)
	k.examine(Vector3(-21.0, 0.0, 6.0), PI / 2.0, [{"text": "Scratched into the stone by some long-ago pilgrim:\n*THE TEMPLE GAVE MY KEY TO THE ROOTS. THE ROOTS WILL NOT GIVE IT BACK.*", "instant": true}])
	# East roots: dark, and the shades in it.
	_roots(k, "roots_e", 3)
	k.chest(34.0, 6.0, PI, "map", false, D + ":chest_map", "", 0.0)
	# The choir: four star braziers; lit, the floor before the altar opens.
	var flags: Array = []
	var c := room_center("choir")
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var f := D + ":choir_star_%d" % i
		k.star_brazier(c.x + cos(a) * 7.0, c.y + sin(a) * 6.0, f, 0.0)
		flags.append(f)
	k.flag_all(flags, D + ":choir_lit")
	_cover(k, CHOIR_HOLE, D + ":choir_lit")
	k.platform(0.0, -44.0, Vector2(6.0, 2.0), 0.5, "stone", GOLD)
	k.examine(Vector3(0.0, 0.5, -42.8), PI, [{"text": "On the altar, in gold:\n*BY HER LIGHT, NOT THEIRS, THE WAY DOWN IS OPENED.*", "instant": true}])


# --- B1 ---------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(2)
	_lamps(k, "well")
	# The mirror-still pool and its inscription.
	var pc := room_center("pool")
	k.water_plane(Rect2(pc.x - 7.0, pc.y - 7.0, 14.0, 14.0), y + 0.05, Color(0.2, 0.26, 0.45, 0.75))
	k.examine(Vector3(pc.x, y, pc.y - 8.5), PI, [], "res://scripts/npc/temple_lines.gd", "pool")
	k.locked_door(0.0, 12.4, PI, D + ":door_key2", false, y)
	_lamps(k, "pool")
	# The trial of the mirror: the shadow; beaten (mercifully), the Arrows.
	k.shutter(-20.6, 0.0, PI / 2.0, "mirror", y)
	var mc := room_center("mirror")
	k.chest(mc.x - 6.0, mc.y, PI / 2.0, "starfall_arrows", true, D + ":chest_starfall", D + ":mirror_clear", y)
	for i in 6:
		var a := TAU * i / 6.0
		k.pillar(mc.x + cos(a) * 7.5, mc.y + sin(a) * 7.5, 6.5, 0.4, false, "stone", y)
	# The lamp room: two star eyes high on the east wall -> Key 2.
	_star_eye(k, Vector3(39.6, y + 4.0, -5.0), PI / 2.0, {"flag": D + ":eye_a"})
	_star_eye(k, Vector3(39.6, y + 4.0, 5.0), PI / 2.0, {"flag": D + ":eye_b"})
	k.flag_all([D + ":eye_a", D + ":eye_b"], D + ":lamps_lit")
	k.chest(32.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key2", D + ":lamps_lit", y)
	k.examine(Vector3(21.5, y, 6.0), -PI / 2.0, [{"text": "Two stone eyes, high on the far wall, closed in sleep.\n*ONLY STARLIGHT OPENS THEM.*", "instant": true}])
	_lamps(k, "lamps")
	# The crypt: the knights' tombs; the Compass; the drop down.
	for x in [-4.5, 4.5]:
		k.block(Vector3(x, y + 0.5, 25.5), Vector3(1.6, 1.0, 3.2), 0.0, "stone", STONE.darkened(0.2))
	k.examine(Vector3(-4.5, y, 23.3), 0.0, [], "res://scripts/npc/temple_lines.gd", "tomb")
	k.chest(4.5, 21.0, PI, "compass", false, D + ":chest_compass", "", y)


# --- B2 ---------------------------------------------------------------------------

func _b2(k) -> void:
	var y := fy(1)
	k.bomb_wall(6.6, 24.0, -PI / 2.0, D + ":ossuary_wall", y)
	k.chest(8.8, 24.0, -PI / 2.0, "rupee_red", false, D + ":chest_ossuary", "", y)
	k.block(Vector3(8.8, y + 1.5, 21.4), Vector3(3.0, 3.0, 0.4), 0.0, "stone", STONE)
	k.block(Vector3(8.8, y + 1.5, 26.6), Vector3(3.0, 3.0, 0.4), 0.0, "stone", STONE)
	k.pot(-5.0, 28.5, "bombs_5", false, y)
	k.pot(-5.0, 27.5, "arrows_10", false, y)
	# The descent: two weight plates; held at once, the floor grate opens.
	for x in [-7.0, 7.0]:
		k._dyn("res://scripts/dungeon/hold_switch.gd", "WeightPlate", Vector3(x, y, -4.0), 0.0, {"result": D + ":descent_open"}, Area3D.new())
	_cover(k, DESCENT_HOLE, D + ":descent_open")
	k.examine(Vector3(-12.4, y, 4.0), -PI / 2.0, [{"text": "Carved by the plates:\n*THE WEIGHT OF TWO, OR ONE AND HIS OWN MAKING.*", "instant": true}])
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key3", false, y)
	_lamps(k, "descent")
	# Three eyes: all open at once (each stays open a few breaths) -> Key 3.
	for p in [Vector3(-39.6, y + 4.5, -6.0), Vector3(-39.6, y + 4.5, 0.0), Vector3(-39.6, y + 4.5, 6.0)]:
		_star_eye(k, p, -PI / 2.0, {"result": D + ":eyes_open", "hold": 6.0})
	k.chest(-28.0, 0.0, PI / 2.0, "small_key", false, D + ":chest_key3", D + ":eyes_open", y)
	_lamps(k, "eyes_w")
	# Deep roots: soft earth; a treasure chart under one.
	_roots(k, "roots_deep", 4)
	k.dig_spot("temple_chart", 34.0, 6.0, "chart_5", {}, y)
	k.dig_spot("temple_root_c", 26.0, -6.0, "rupee_blue", {"loose": true}, y)
	k.dig_spot("temple_root_d", 35.0, -5.0, "magic_small", {"loose": true}, y)
	# The bell room: a chasm across the middle; targets carry the Hookshot over.
	# The bell room: the Boss Key on a ledge high on the north wall; a target
	# over it is the way up (the Hookshot).
	var bc := room_center("bell")
	k.block(Vector3(bc.x, y + 1.75, bc.y - 8.5), Vector3(8.0, 3.5, 3.0), 0.0, "stone", STONE.darkened(0.12))
	k.chest(bc.x, bc.y - 8.5, 0.0, "boss_key", true, D + ":chest_boss_key", "", y + 3.5)
	k.hook_target(Vector3(bc.x + 2.5, y + 5.4, bc.y - 9.9), 0.0)
	var bm = k._tmp(false)
	bm.prism(Vector3(bc.x + 7.0, y + 4.6, bc.y - 8.0), 0.9, Vector3(bc.x + 7.0, y + 6.2, bc.y - 8.0), 0.5, 12, GOLD)
	k.merge(bm, "char")


# --- B3 ---------------------------------------------------------------------------

func _b3(k) -> void:
	var y := fy(0)
	_lamps(k, "nave")
	for z in [-8.0, 0.0, 8.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 11.0, z, 6.5, 0.55, false, "stone", y)
	k.locked_door(0.0, -12.4, 0.0, D + ":boss_door", true, y)
	# The spring: a fairy's pool.
	var sc := room_center("spring")
	k.water_plane(Rect2(sc.x - 4.0, sc.y - 4.0, 8.0, 8.0), y + 0.05, Color(0.5, 0.7, 0.9, 0.7))
	k.pot(sc.x + 7.0, sc.y + 7.0, "heart", false, y)
	k.pot(sc.x + 7.0, sc.y - 7.0, "magic_small", false, y)
	# The keeper's vault.
	k.chest(34.0, 0.0, -PI / 2.0, "rupee_gold", false, D + ":chest_vault", "", y)
	for z in [-7.0, 7.0]:
		k.statue(36.0, z, -PI / 2.0, 0.9, "stone", y)
	# The Guardian's hall.
	var rb: Rect2 = rooms.boss.r
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	for i in 8:
		var a := TAU * i / 8.0
		k.pillar(cos(a) * 13.0, -34.0 + sin(a) * 13.0, 6.5, 0.6, i % 3 == 0, "stone", y)
	var clear := D + ":boss_clear"
	k.heart_container(0.0, -24.0, clear, D + ":heart_container", y)
	k.flag_bars(0.0, -50.6, 0.0, clear, y)
	# The heart: the old pedestal on its dais.
	var hc := room_center("heart")
	k.platform(hc.x, hc.y - 3.0, Vector2(6.0, 6.0), y + 0.6, "stone", Color(0.95, 0.92, 0.84))
	# The old pedestal: a block of pale stone with a slot of gold for a blade.
	var pm = k._tmp()
	var pb := Vector3(hc.x, y + 0.6, hc.y - 3.0)
	pm.box(pb + Vector3(0, 0.15, 0), Vector3(1.6, 0.3, 1.6), STONE.darkened(0.1))
	pm.box(pb + Vector3(0, 0.6, 0), Vector3(1.1, 0.6, 1.1), STONE)
	pm.box(pb + Vector3(0, 0.95, 0), Vector3(1.3, 0.12, 1.3), GOLD)
	pm.box(pb + Vector3(0, 1.02, 0), Vector3(0.12, 0.04, 0.5), Color.html("2a2418"))
	k.merge(pm, "stone")
	k.col_box(pb + Vector3(0, 0.5, 0), Vector3(1.4, 1.0, 1.4))
	for i in 6:
		var a := TAU * i / 6.0
		k.star_brazier(hc.x + cos(a) * 7.0, hc.y + sin(a) * 7.0, D + ":heart_star_%d" % i, y)
	k.mark("cs_heart_hero", Vector3(hc.x, y, hc.y + 4.0), 0.0)
	k.mark("cs_heart_pedestal", Vector3(hc.x, y + 0.6, hc.y - 3.0))
	k.mark("cs_heart_cam", Vector3(hc.x + 6.0, y + 3.0, hc.y + 6.0))
	k.story_trigger("temple_heart", Rect2(hc.x - 8.0, hc.y + 2.0, 16.0, 6.0), y, "ch4:sword_awake", clear)
	k.blue_warp(hc.x, hc.y + 7.0, "ch4:astral_seal", "dark_forest", "warp_temple_of_bun", y)


func populate(k) -> void:
	var b1 := fy(2)
	var b2 := fy(1)
	var b3 := fy(0)
	k.enemy("stalfos", -4.0, 2.0, 0.0, {}, 0.0)
	k.enemy("keese", 6.0, -4.0, 0.0, {}, 4.0)
	k.enemy("shadow_wolf", -30.0, 0.0, 0.0, {}, 0.0)
	k.enemy("shade", 26.0, -2.0, 0.0, {}, 1.3)
	k.enemy("shade", 32.0, 4.0, 0.0, {}, 1.3)
	k.enemy("stalfos", 0.0, -36.0, 0.0, {}, 0.0)
	k.enemy("keese", -4.0, -38.0, 0.0, {}, b1 + 4.0)
	k.enemy("shadow_wolf", 4.0, 2.0, 0.0, {}, b1)
	k.enemy("dark_gigglebuns", -30.0, 0.0, PI / 2.0, {"room": "mirror", "center": Vector3(-30.0, b1, 0.0)}, b1)
	k.enemy("stalfos", 28.0, -5.0, 0.0, {}, b1)
	k.enemy("rat", -3.0, 26.0, 0.0, {}, b1)
	k.enemy("stalfos", 4.0, 0.0, 0.0, {}, b2)
	k.enemy("stalfos", -6.0, -6.0, 0.0, {}, b2)
	k.enemy("keese", -28.0, -4.0, 0.0, {}, b2 + 4.0)
	k.enemy("shadow_wolf", 28.0, 2.0, 0.0, {}, b2)
	k.enemy("shadow_wolf", 32.0, -4.0, 0.0, {}, b2)
	k.enemy("keese", 0.0, -30.0, 0.0, {}, b2 + 4.0)
	k.enemy("stalfos", 6.0, 6.0, 0.0, {}, b3)
	k.enemy("shade", -6.0, -6.0, 0.0, {}, b3 + 1.3)
	k.enemy("pedestal_guardian", 0.0, -38.0, 0.0, {"room": "boss"}, b3)
