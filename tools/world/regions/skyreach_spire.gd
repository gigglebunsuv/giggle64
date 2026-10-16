extends "res://tools/world/tower_region.gd"
## Skyreach Spire, the last and greatest of the goddess towers: a spire of
## blue stone and ice above Frostpeak, seven storeys from the ice caves under
## the summit to its open crown in the clouds. Gales howl through it. Its
## treasure is the Wind Boots, which hold fast against the wind and glide on
## it. Its master, Aeolos the Storm Eye, guards Aphiel's bun piece.
##
## Storeys (north is -Z; W, C, E, N name the columns):
##   B1 (y -8)  crevasse W  a gale over a chasm -> the Compass
##              grotto C    a frozen lake (ice underfoot), freezards; the lift
##              icefall E   under the gale hall's hole -> Small Key 1
##              vault N     frozen treasure
##   1F (y 0)   entry S     in from Frostpeak
##              foyer C     the Map; the lift down to the grotto
##              galehall E  a gale that blows the hero into a hole in the floor
##              frostkeep W (Small Key 1) the Frost Knight -> the Wind Boots;
##                          the ladder up
##   2F (y 8)   iceworks W  floors of ice round a pit
##              bellows C   a chasm the wind blows across (turn the vane, then
##                          glide on it) to the wellhead
##              ledge2 E    a ledge over a drop in the teeth of the gale (the
##                          Wind Boots hold); the ladder up
##              wellhead N  a Piece of Heart
##   3F (y 16)  ladderwell E wind wisps
##              chasm C     glide across on the wind
##              freezer W   freezards -> Small Key 2; the ladder up
##              belfry N    beyond the chasm
##   4F (y 24)  ledge4 W    another ledge over a drop
##              vanehall C  (Small Key 2) strike the vane to wake the lift up
##              keyroom E   -> Small Key 3
##              rookery N   ice keese
##   5F (y 32)  skybridge C walkways between pits
##              aerie W     (Small Key 3) open to the sky: Frostwing -> the Boss Key
##              ante E      the boss door; stairs two storeys up to the crown
##   6F (y 40)  summit C    the open crown: Aeolos; then the heart container,
##                          Aphiel's bun piece and the blue warp

const D := "skyreach_spire"
const W := Rect2(-40, -12, 22, 24)
const C := Rect2(-14, -14, 28, 28)
const E := Rect2(18, -12, 22, 24)
const N := Rect2(-12, -44, 24, 24)
const S := Rect2(-6, 18, 12, 12)
const WC := Rect2(-18, -2, 4, 4)
const CE := Rect2(14, -2, 4, 4)
const CN := Rect2(-2, -20, 4, 6)
## Where the ladders' piers stand (face middle, way they face) on each storey.
const LADDERS := {1: [Vector2(-23, -9), Vector2(-1, 0)], 2: [Vector2(32, 9), Vector2(-1, 0)], 3: [Vector2(-23, 9), Vector2(-1, 0)]}
## The pits: [storey, rect] (holes in the floor with a void just under).
const PITS := [
	[2, Rect2(-14, -12, 28, 8)], [2, Rect2(34, -12, 6, 24)], [2, Rect2(-32, -6, 8, 10)],
	[3, Rect2(-5, -14, 10, 28)],
	[4, Rect2(-40, -12, 6, 24)],
	[5, Rect2(2, 2, 12, 12)], [5, Rect2(-14, 2, 12, 12)],
	[6, Rect2(-14, -14, 28, 3)], [6, Rect2(-14, 11, 28, 3)], [6, Rect2(-14, -11, 3, 22)], [6, Rect2(11, -11, 3, 16)],
]
const GALEHALL_HOLE := Rect2(24, -11, 12, 5)
const LIFT_DOWN := Vector2(9, -9)
const LIFT_UP := Vector2(-9, -9)
const CREVASSE_PIT := Rect2(-36, 2, 14, 8)

## The aerie and the crown are open to the sky.
var open_sky := true


func setup() -> void:
	id = "skyreach_spire"
	interior = true
	seed_value = 307
	x_min = -44.0
	x_max = 44.0
	z_min = -48.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0], ["4F", 24.0], ["5F", 32.0], ["6F", 40.0]]
	entry_floor = 1
	wall_mat = "stone"
	slab_mat = "stone"
	wall_col = Color(0.78, 0.86, 1.0)
	ceil_col = Color(0.5, 0.56, 0.68)
	slab_col = Color(0.82, 0.88, 1.0)
	var cave := Color(0.62, 0.74, 0.9)
	var ice := Color(0.85, 0.95, 1.0)
	var all4 := [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]
	rooms = {
		# B1: the ice caves.
		"crevasse": {"f": 0, "r": W, "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": cave},
		"grotto": {"f": 0, "r": C, "h": 6.5, "doors": all4.duplicate(true), "col": cave},
		"icefall": {"f": 0, "r": E, "h": 6.5, "doors": [{"side": "w", "at": 0.0}], "col": cave},
		"vault": {"f": 0, "r": N, "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": cave},
		# 1F.
		"entry": {"f": 1, "r": S, "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"foyer": {"f": 1, "r": C, "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"galehall": {"f": 1, "r": E, "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"frostkeep": {"f": 1, "r": W, "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		# 2F.
		"iceworks": {"f": 2, "r": W, "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "floor_mat": "ice", "floor_col": ice},
		"bellows": {"f": 2, "r": C, "h": 6.5, "doors": all4.duplicate(true)},
		"ledge2": {"f": 2, "r": E, "h": 3.0, "doors": [{"side": "w", "at": 0.0}], "ceiling": false},
		"wellhead": {"f": 2, "r": N, "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# 3F.
		"freezer": {"f": 3, "r": W, "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "floor_mat": "ice", "floor_col": ice},
		"chasm": {"f": 3, "r": C, "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": -9.0}]},
		"ladderwell": {"f": 3, "r": E, "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"belfry": {"f": 3, "r": N, "h": 6.5, "doors": [{"side": "s", "at": -9.0}]},
		# 4F.
		"ledge4": {"f": 4, "r": W, "h": 3.0, "doors": [{"side": "e", "at": 0.0}], "ceiling": false},
		"vanehall": {"f": 4, "r": C, "h": 6.5, "doors": all4.duplicate(true)},
		"keyroom": {"f": 4, "r": E, "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"rookery": {"f": 4, "r": N, "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# 5F.
		"aerie": {"f": 5, "r": W, "h": 5.0, "doors": [{"side": "e", "at": 0.0}], "ceiling": false},
		"skybridge": {"f": 5, "r": C, "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": -9.0}]},
		"ante": {"f": 5, "r": E, "h": 14.5, "doors": [{"side": "w", "at": -9.0}, {"side": "w", "at": 8.5, "y0": 8.0}]},
		# 6F.
		"boss": {"f": 6, "r": C, "h": 2.5, "doors": [{"side": "e", "at": 8.5}], "ceiling": false},
	}
	corridors = [
		{"f": 0, "r": WC, "x": true}, {"f": 0, "r": CE, "x": true}, {"f": 0, "r": CN, "x": false},
		{"f": 1, "r": WC, "x": true}, {"f": 1, "r": CE, "x": true}, {"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 2, "r": WC, "x": true}, {"f": 2, "r": CE, "x": true}, {"f": 2, "r": CN, "x": false},
		{"f": 3, "r": WC, "x": true}, {"f": 3, "r": CE, "x": true}, {"f": 3, "r": Rect2(-11, -20, 4, 6), "x": false},
		{"f": 4, "r": WC, "x": true}, {"f": 4, "r": CE, "x": true}, {"f": 4, "r": CN, "x": false},
		{"f": 5, "r": WC, "x": true}, {"f": 5, "r": Rect2(14, -11, 4, 4), "x": true},
		{"f": 6, "r": Rect2(14, 6.5, 4, 4), "x": true},
	]
	holes = [
		{"f": 1, "r": Rect2(LIFT_DOWN - Vector2(1.6, 1.6), Vector2(3.2, 3.2))},
		{"f": 1, "r": GALEHALL_HOLE},
		{"f": 5, "r": Rect2(LIFT_UP - Vector2(1.6, 1.6), Vector2(3.2, 3.2))},
	]
	for f: int in LADDERS:
		holes.append({"f": f + 1, "r": ladder_hole(LADDERS[f][0].x, LADDERS[f][0].y, LADDERS[f][1])})
	for p: Array in PITS:
		holes.append({"f": p[0], "r": p[1]})
	water = []
	mood = {
		# Cold blue light within; a white, windy sky over the crown.
		"sky_top": Color.html("4a6ab0"), "sky_mid": Color.html("9ab4e0"), "sky_horizon": Color.html("e8f0ff"),
		"cloud": Color.html("ffffff"), "cloud_amount": 0.6,
		"fog": Color.html("1a2436"), "fog_begin": 18.0, "fog_end": 70.0,
		"ambient": Color.html("5a6a8a"), "sun": Color.html("e8f0ff"), "sun_rot": Vector3(-55, -30, 0),
		"sun_energy": 0.7, "fill": Color.html("6a7aa8"), "fill_energy": 0.45,
		"horizon": Color.html("a8b8d8"), "hill_height": 0.0,
	}


## The lowest storey: a deep chasm under the crevasse.
func base_height(x: float, z: float) -> float:
	if CREVASSE_PIT.has_point(Vector2(x, z)):
		return fy(0) - 6.0
	return fy(0)


func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if f == 0:
		if CREVASSE_PIT.has_point(p):
			return Color.html("0a1020")
		var inside := false
		for id: String in ["crevasse", "grotto", "icefall", "vault"]:
			if (rooms[id].r as Rect2).grow(1.0).has_point(p):
				inside = true
		for c: Dictionary in corridors:
			if c.f == 0 and (c.r as Rect2).has_point(p):
				inside = true
		if not inside:
			return Color.html("0e1422")
		if C.has_point(p) or W.has_point(p):
			# Frozen lake ice, with pale cracks.
			var crack := absf(sin(x * 0.9 + sin(z * 0.7) * 2.0)) < 0.06 or absf(sin(z * 1.1 - x * 0.3)) < 0.05
			return Color.html("e8f6ff") if crack else Color.html("a8d0f0").lerp(Color.html("c8e4f8"), r.randf_range(0.0, 0.5))
		return Color.html(["6a7a90", "727e94", "667488"][posmod(int(floor(x / 2.0)) + int(floor(z / 2.0)), 3)])
	for pit: Array in PITS:
		if pit[0] == f and (pit[1] as Rect2).has_point(p):
			return Color.html("101828")
	if (f == 2 and W.has_point(p)) or (f == 3 and W.has_point(p)):
		return Color.html("b8dcf8").lerp(Color.html("d8ecff"), r.randf_range(0.0, 0.4))
	var tx := int(floor(x / 2.0))
	var tz := int(floor(z / 2.0))
	if fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08:
		return Color.html("5a6680")
	return Color.html(["9aaac8", "a2b2d0", "92a2c0"][posmod(tx + tz * 2, 3)]).darkened(r.randf_range(0.0, 0.06))


func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	var p := Vector2(x, z)
	return "ice" if C.has_point(p) or W.has_point(p) else "stone"


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "snow", "from_skyreach_spire")
	k.entrance("from_snow", 0.0, 27.0, 0.0)
	for f: int in LADDERS:
		ladder_up(k, f, LADDERS[f][0].x, LADDERS[f][0].y, LADDERS[f][1])
	# A void under every pit, so a fall comes back to the room's entrance.
	# It sits two meters down, so a leap that falls a little short can still
	# catch the far ledge.
	for p: Array in PITS:
		var r: Rect2 = p[1]
		var c := r.get_center()
		k.void_zone(Vector3(c.x, fy(p[0]) - 3.0, c.y), Vector3(r.size.x, 2.0, r.size.y), 2)
	_b1(k)
	_f1(k)
	_f2(k)
	_f3(k)
	_f4(k)
	_f5(k)
	_summit(k)


# --- Decoration -----------------------------------------------------------------

func _torch(k, x: float, z: float, y: float) -> void:
	k.brazier(x, z, true, y)


func _lamps(k, r: Rect2, y: float, inset := 1.6) -> void:
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


func _icicles(k, r: Rect2, y: float, n := 10) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 7.0 + r.position.y * 13.0 + y)
	var m = k._tmp(false)
	for i in n:
		var x := rng.randf_range(r.position.x + 1.0, r.end.x - 1.0)
		var z := rng.randf_range(r.position.y + 1.0, r.end.y - 1.0)
		var l := rng.randf_range(0.6, 1.6)
		m.prism(Vector3(x, y, z), 0.18, Vector3(x, y - l, z), 0.0, 5, Color(0.85, 0.95, 1.0))
	k.merge(m, "ice")


func _crystal_rock(k, x: float, z: float, y: float, s := 1.0) -> void:
	k.spire(x, z, 0.5 * s, 2.5 * s, "ice", Color(0.8, 0.92, 1.0), 0.2, 5)
	k.block(Vector3(x, y + 1.0 * s, z), Vector3(0.9 * s, 2.0 * s, 0.9 * s), 0.0, "ice", Color(0.82, 0.94, 1.0))


# --- B1 ------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(0)
	# The crevasse: a gale off the chasm's far side; the Compass beyond.
	k.wind_zone(Vector3(-29, y + 1.5, -2), Vector3(22, 3.0, 8), Vector3(0, 0, 1), 3.2)
	var pc := CREVASSE_PIT.get_center()
	k.void_zone(Vector3(pc.x, y - 5.0, pc.y), Vector3(CREVASSE_PIT.size.x, 2.0, CREVASSE_PIT.size.y), 2)
	k.chest(-37.5, -9.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", y)
	_lamps(k, W, y)
	_icicles(k, W, y + 6.5)
	# The grotto: the frozen lake, the lift up to the foyer.
	k.lift(Vector3(LIFT_DOWN.x, y, LIFT_DOWN.y), Vector3(3.0, 0.6, 3.0), Vector3(0, 8, 0), "stone", Color(0.8, 0.88, 1.0))
	for p in [Vector2(-8, 6), Vector2(6, 8), Vector2(-9, -6)]:
		_crystal_rock(k, p.x, p.y, y)
	_lamps(k, C, y)
	_icicles(k, C, y + 6.5, 16)
	# The icefall: under the gale hall's hole; Small Key 1.
	k.block(Vector3(39.2, y + 3.0, 0), Vector3(1.6, 6.0, 8.0), 0.0, "ice", Color(0.85, 0.95, 1.0))
	k.chest(30.0, 8.0, PI, "small_key", false, D + ":chest_key1", "", y)
	_lamps(k, E, y)
	_icicles(k, E, y + 6.5)
	# The frozen vault.
	k.chest(0.0, -40.0, 0.0, "rupee_red", false, D + ":chest_vault", "", y)
	for p in [Vector2(-9, -41), Vector2(9, -41), Vector2(-9, -23)]:
		k.pot(p.x, p.y, "", false, y)
	_lamps(k, N, y)


# --- 1F ------------------------------------------------------------------------

func _f1(k) -> void:
	var y := fy(1)
	# Entry.
	_torch(k, -2.6, 19.5, y)
	_torch(k, 2.6, 19.5, y)
	k.pot(4.4, 28.4, "heart", false, y)
	# Foyer: the Map.
	for p in [Vector2(-8, -8), Vector2(8, 8), Vector2(-8, 8)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	k.chest(-11.0, 11.0, PI / 2.0, "map", false, D + ":chest_map", "", y)
	k.locked_door(-15.4, 0.0, PI / 2.0, D + ":door_key1", false, y)
	_lamps(k, C, y)
	# The gale hall: the wind blows north into the hole over the icefall.
	k.wind_zone(Vector3(29, y + 1.5, 0), Vector3(22, 3.0, 24), Vector3(0, 0, -1), 3.5)
	k.pot(37.5, 10.0, "rupee_blue", false, y)
	_lamps(k, E, y)
	# The Frost Knight's keep: the Wind Boots.
	k.shutter(-18.6, 0.0, PI / 2.0, "frostkeep", y)
	k.chest(-33.0, 0.0, -PI / 2.0, "boots_wind", true, D + ":chest_wind_boots", D + ":frostkeep_clear", y)
	_lamps(k, W, y)


# --- 2F ------------------------------------------------------------------------

func _f2(k) -> void:
	var y := fy(2)
	# Iceworks: ice floors round a pit.
	_lamps(k, W, y)
	_icicles(k, W, y + 6.5)
	# Bellows: the wind across the chasm blows south until the vane is
	# struck, then north: glide with it to the wellhead.
	k.wind_zone(Vector3(0, y + 2.5, -8), Vector3(28, 6.0, 12), Vector3(0, 0, 1), 4.5, {"flag": D + ":bellows_vane", "dir_on": Vector3(0, 0, -1)})
	k.crystal_switch(-10.0, 10.0, D + ":bellows_vane", y)
	for x in [-12.0, 12.0]:
		k.block(Vector3(x, y + 3.0, -3.4), Vector3(1.2, 6.0, 0.6), 0.0, "stone", Color(0.7, 0.78, 0.92))
	_lamps(k, Rect2(-14, -2, 28, 16), y)
	# Ledge 2: the gale off the drop; the ladder up.
	k.wind_zone(Vector3(26, y + 1.5, 0), Vector3(16, 3.0, 24), Vector3(1, 0, 0), 6.0)
	_torch(k, 20.0, -10.5, y)
	_torch(k, 20.0, 10.5, y)
	# The wellhead: a Piece of Heart.
	k.block(Vector3(0, y + 0.5, -34), Vector3(2.0, 1.0, 2.0), 0.0, "stone", Color(0.9, 0.95, 1.0))
	k.heart_piece(0.0, -34.0, D + ":heart_piece", y + 1.0)
	_lamps(k, N, y)


# --- 3F ------------------------------------------------------------------------

func _f3(k) -> void:
	var y := fy(3)
	_lamps(k, E, y)
	# The chasm: the wind blows west across it; glide on it.
	k.wind_zone(Vector3(0, y + 2.5, 0), Vector3(20, 6.0, 28), Vector3(-1, 0, 0), 4.5)
	_lamps(k, C, y)
	# The freezer: Small Key 2 once its freezards are broken.
	k.shutter(-18.6, 0.0, PI / 2.0, "freezer", y)
	k.chest(-36.0, -8.0, -PI / 2.0, "small_key", false, D + ":chest_key2", D + ":freezer_clear", y)
	_lamps(k, W, y)
	# The belfry.
	k.chest(8.0, -40.0, 0.0, "arrows_10", false, D + ":chest_belfry", "", y)
	k.pot(-9.0, -41.0, "rupee_red", false, y)
	_lamps(k, N, y)


# --- 4F ------------------------------------------------------------------------

func _f4(k) -> void:
	var y := fy(4)
	# Ledge 4: the gale off the drop on the west.
	k.wind_zone(Vector3(-29, y + 1.5, 0), Vector3(22, 3.0, 24), Vector3(-1, 0, 0), 6.0)
	# The vane hall: strike the vane high on its post to wake the lift.
	k.locked_door(-16.6, 0.0, PI / 2.0, D + ":door_key2", false, y)
	k.block(Vector3(8, y + 2.5, -8), Vector3(0.8, 5.0, 0.8), 0.0, "stone", Color(0.75, 0.82, 0.95)).set_meta("no_climb", true)
	k.crystal_switch(8.0, -8.0, D + ":vane_lift", y + 5.0)
	k.lift(Vector3(LIFT_UP.x, y, LIFT_UP.y), Vector3(3.0, 0.6, 3.0), Vector3(0, 8, 0), "stone", Color(0.8, 0.88, 1.0), {"flag": D + ":vane_lift"})
	_lamps(k, C, y)
	# The key room.
	k.shutter(18.6, 0.0, PI / 2.0, "keyroom", y)
	k.chest(36.0, 0.0, PI / 2.0, "small_key", false, D + ":chest_key3", D + ":keyroom_clear", y)
	_lamps(k, E, y)
	# The rookery: behind a false wall in the north (Looking Glass), a chest.
	k.lens_alcove(Vector2(0.0, -44.0), Vector2(0, 1), 3.0, 2.4, y, "rupee_red", D + ":chest_lens", "stone", Color(0.82, 0.9, 1.0))
	k.pot(-9.0, -41.0, "heart", false, y)
	k.pot(9.0, -41.0, "arrows_10", false, y)
	_lamps(k, N, y)


# --- 5F ------------------------------------------------------------------------

func _f5(k) -> void:
	var y := fy(5)
	# The skybridge: walkways between pits, a gale across the south.
	k.wind_zone(Vector3(0, y + 1.5, 8), Vector3(28, 3.0, 12), Vector3(1, 0, 0), 5.0)
	k.locked_door(-16.6, 0.0, PI / 2.0, D + ":door_key3", false, y)
	k.locked_door(16.0, -9.0, PI / 2.0, D + ":boss_door", true, y)
	_lamps(k, Rect2(-14, -14, 28, 16), y)
	# The aerie: Frostwing's nest; the Boss Key.
	k.shutter(-18.6, 0.0, PI / 2.0, "aerie", y)
	k.chest(-34.0, 0.0, -PI / 2.0, "boss_key", true, D + ":chest_boss_key", D + ":aerie_clear", y)
	# The antechamber: stairs two storeys up to the crown's door.
	k.stairs(21.5, -6.0, PI, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(21.5, y + FLOOR_H * 0.5, 8.5), Vector3(7.0, FLOOR_H, 7.0), 0.0, "stone", Color(0.82, 0.88, 1.0))
	_lamps(k, E, y)


func _summit(k) -> void:
	var y := fy(6)
	var c := C.get_center()
	k.shutter(13.4, 8.5, PI / 2.0, "boss", y)
	for p in [Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8)]:
		_crystal_rock(k, p.x, p.y, y, 0.8)
	var clear := D + ":boss_clear"
	k.heart_container(c.x - 3.0, c.y + 4.0, clear, D + ":heart_container", y)
	k.bun_piece(c.x + 3.0, c.y + 4.0, "aphiel", clear, y)
	k.blue_warp(c.x, c.y - 4.0, clear, "snow", "warp_skyreach_spire", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(0)
	var f2 := fy(2)
	var f3 := fy(3)
	var f4 := fy(4)
	var f5 := fy(5)
	k.enemy("ice_keese", -30.0, -6.0, 0.0, {"room": "crevasse"}, b1 + 4.0)
	k.enemy("freezard", -6.0, -8.0, PI, {"room": "grotto"}, b1)
	k.enemy("freezard", 7.0, 2.0, PI / 2.0, {"room": "grotto"}, b1)
	k.enemy("ice_keese", 30.0, -4.0, 0.0, {"room": "icefall"}, b1 + 4.0)
	k.enemy("ice_keese", 26.0, 4.0, 0.0, {"room": "icefall"}, b1 + 4.0)
	k.enemy("ice_keese", 0.0, -32.0, 0.0, {"room": "vault"}, b1 + 4.0)
	k.enemy("wind_wisp", 0.0, -6.0, 0.0, {"room": "foyer"}, 2.5)
	k.enemy("frost_knight", -30.0, 0.0, -PI / 2.0, {"room": "frostkeep"})
	k.enemy("ice_keese", -30.0, 6.0, 0.0, {"room": "iceworks"}, f2 + 4.0)
	k.enemy("wind_wisp", 26.0, -6.0, 0.0, {"room": "ledge2"}, f2 + 2.0)
	k.enemy("wind_wisp", 30.0, 2.0, 0.0, {"room": "ladderwell"}, f3 + 2.5)
	k.enemy("wind_wisp", 24.0, -6.0, 0.0, {"room": "ladderwell"}, f3 + 2.5)
	k.enemy("freezard", -30.0, -6.0, PI / 2.0, {"room": "freezer"}, f3)
	k.enemy("freezard", -30.0, 6.0, PI / 2.0, {"room": "freezer"}, f3)
	k.enemy("ice_keese", -26.0, 0.0, 0.0, {"room": "freezer"}, f3 + 4.0)
	k.enemy("ice_keese", 0.0, -30.0, 0.0, {"room": "belfry"}, f3 + 4.0)
	k.enemy("wind_wisp", -26.0, 6.0, 0.0, {"room": "ledge4"}, f4 + 2.0)
	k.enemy("frost_knight", 0.0, 4.0, 0.0, {"room": "vanehall"}, f4)
	k.enemy("wind_wisp", 30.0, -6.0, 0.0, {"room": "keyroom"}, f4 + 2.5)
	k.enemy("ice_keese", 30.0, 6.0, 0.0, {"room": "keyroom"}, f4 + 4.0)
	k.enemy("freezard", 26.0, 0.0, PI / 2.0, {"room": "keyroom"}, f4)
	k.enemy("ice_keese", -6.0, -30.0, 0.0, {"room": "rookery"}, f4 + 4.0)
	k.enemy("ice_keese", 6.0, -34.0, 0.0, {"room": "rookery"}, f4 + 4.0)
	k.enemy("wind_wisp", 0.0, -8.0, 0.0, {"room": "skybridge"}, f5 + 2.5)
	k.enemy("wyvern", -29.0, 0.0, 0.0, {"room": "aerie"}, f5 + 3.0)
	k.enemy("storm_eye", 0.0, 0.0, 0.0, {"room": "boss"}, fy(6))
