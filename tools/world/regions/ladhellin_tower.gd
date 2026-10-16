extends "res://tools/world/tower_region.gd"
## Ladhellin Tower, the second of the goddess towers: the sandstone temple of
## the old sun-priests in the Desert of Ladhellin, five storeys from the crypt
## to the Sun Chamber open to the sky. Its treasure is the Mirror Shield, and
## the tower's later rooms are puzzles of sunlight thrown with it. Its master,
## Kherash the Sand Devourer, guards Serielye's bun piece.
##
## Storeys (north is -Z):
##   B1 (y -8)  descent   a stairwell two storeys tall down from the shrine
##              crypt     rows of coffins and their mummies
##              ossuary   clear it for Small Key 2; the Compass
##              lord      (Small Key 2) the Mummy Lord -> the Mirror Shield
##   1F (y 0)   entry     in from the desert
##              hall      the Great Hall, two storeys tall: two shafts of sun
##                        through its oculi, stairs up to a gallery and a door
##                        barred until the light wakes the sun on its east wall
##              court     a court of quicksand crossed on stepping stones ->
##                        Small Key 1
##              vault     beyond the sand: a Piece of Heart
##              shrine    (Small Key 1) the Map; the way down to the crypt
##   2F (y 8)   sunroom   light from an oculus, a mirror to turn: two suns
##                        unbar the doors east and west
##              beetles   sand beetles round quicksand -> Small Key 3
##              colonnade a beam through a slit, two mirrors to turn: the sun
##                        on the west wall unbars the stairs
##              stair2    a stairwell two storeys tall up to 3F
##   3F (y 16)  shadehall dark, its shades seen only in the oculus's light
##              mirrors3  a beam from the north wall and three mirrors
##              sentinel  (Small Key 3) the Sentinel -> the Boss Key
##              stair4    a stairwell two storeys tall up to 4F
##   4F (y 24)  ante      the boss door
##              boss      the Sun Chamber, open to the sky: Kherash; then the
##                        heart container, Serielye's bun piece, the blue warp

const D := "ladhellin_tower"
const TILE := ["e0c48c", "d8bc84", "e8cc96"]
## Quicksand floors: [storey, rect].
const SANDS := [[1, Rect2(-40, -10, 16, 22)], [2, Rect2(24, -38, 6, 16)], [2, Rect2(33, -30, 7, 8)]]
## The stepping stones across the court's quicksand.
const STONES := [Vector2(-26.2, 3.0), Vector2(-29.2, 4.6), Vector2(-32.2, 2.6), Vector2(-35.2, 4.2), Vector2(-38.0, 2.2), Vector2(-33.2, -1.0), Vector2(-33.0, -4.2), Vector2(-33.0, -7.4)]

## The Sun Chamber is open to the sky.
var open_sky := true


func setup() -> void:
	id = "ladhellin_tower"
	interior = true
	seed_value = 233
	x_min = -48.0
	x_max = 46.0
	z_min = -100.0
	z_max = 38.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0], ["4F", 24.0]]
	entry_floor = 1
	wall_mat = "sandstone"
	slab_mat = "sandstone"
	wall_col = Color(1.0, 0.92, 0.78)
	ceil_col = Color(0.62, 0.52, 0.4)
	slab_col = Color(1.0, 0.9, 0.72)
	var crypt := Color(0.7, 0.64, 0.58)
	var dark := Color(0.55, 0.5, 0.52)
	rooms = {
		# B1: the crypt.
		"descent": {"f": 0, "r": Rect2(24, -36, 16, 18), "h": 14.5, "doors": [{"side": "s", "at": 32.0, "y0": 8.0}, {"side": "w", "at": -28.0}], "col": crypt},
		"crypt": {"f": 0, "r": Rect2(-6, -40, 22, 20), "h": 6.5, "doors": [{"side": "e", "at": -28.0}, {"side": "w", "at": -30.0}, {"side": "n", "at": 5.0}], "col": crypt},
		"ossuary": {"f": 0, "r": Rect2(-30, -40, 18, 20), "h": 6.5, "doors": [{"side": "e", "at": -30.0}], "col": crypt},
		"lord": {"f": 0, "r": Rect2(-6, -72, 22, 24), "h": 6.5, "doors": [{"side": "s", "at": 5.0}], "col": crypt},
		# 1F.
		"entry": {"f": 1, "r": Rect2(-6, 22, 12, 12), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"hall": {"f": 1, "r": Rect2(-16, -14, 32, 32), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 2.0}, {"side": "e", "at": 2.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		"court": {"f": 1, "r": Rect2(-44, -10, 22, 24), "h": 6.5, "doors": [{"side": "e", "at": 2.0}, {"side": "n", "at": -33.0}]},
		"vault": {"f": 1, "r": Rect2(-42, -30, 18, 14), "h": 6.5, "doors": [{"side": "s", "at": -33.0}]},
		"shrine": {"f": 1, "r": Rect2(22, -10, 20, 24), "h": 6.5, "doors": [{"side": "w", "at": 2.0}, {"side": "n", "at": 32.0}]},
		# 2F.
		"sunroom": {"f": 2, "r": Rect2(-12, -42, 24, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "e", "at": -30.0}, {"side": "w", "at": -30.0}]},
		"beetles": {"f": 2, "r": Rect2(20, -42, 22, 24), "h": 6.5, "doors": [{"side": "w", "at": -30.0}]},
		"colonnade": {"f": 2, "r": Rect2(-44, -42, 24, 24), "h": 6.5, "doors": [{"side": "e", "at": -30.0}, {"side": "n", "at": -34.0}]},
		"stair2": {"f": 2, "r": Rect2(-40, -66, 16, 16), "h": 14.5, "doors": [{"side": "s", "at": -34.0}, {"side": "n", "at": -32.0, "y0": 8.0}]},
		# 3F.
		"shadehall": {"f": 3, "r": Rect2(-44, -96, 24, 22), "h": 6.5, "doors": [{"side": "s", "at": -32.0}, {"side": "e", "at": -86.0}], "col": dark},
		"mirrors3": {"f": 3, "r": Rect2(-12, -96, 24, 22), "h": 6.5, "doors": [{"side": "w", "at": -86.0}, {"side": "e", "at": -86.0}]},
		"sentinel": {"f": 3, "r": Rect2(20, -96, 22, 22), "h": 6.5, "doors": [{"side": "w", "at": -86.0}, {"side": "s", "at": 32.0}]},
		"stair4": {"f": 3, "r": Rect2(24, -66, 16, 18), "h": 14.5, "doors": [{"side": "n", "at": 32.0}, {"side": "s", "at": 32.0, "y0": 8.0}]},
		# 4F.
		"ante": {"f": 4, "r": Rect2(22, -42, 20, 18), "h": 6.5, "doors": [{"side": "n", "at": 32.0}, {"side": "w", "at": -33.0}]},
		"boss": {"f": 4, "r": Rect2(-16, -44, 32, 34), "h": 6.0, "doors": [{"side": "e", "at": -33.0}], "ceiling": false},
	}
	corridors = [
		{"f": 0, "r": Rect2(16, -30, 8, 4), "x": true},
		{"f": 0, "r": Rect2(-12, -32, 6, 4), "x": true},
		{"f": 0, "r": Rect2(3, -48, 4, 8), "x": false},
		{"f": 1, "r": Rect2(-2, 18, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-22, 0, 6, 4), "x": true},
		{"f": 1, "r": Rect2(16, 0, 6, 4), "x": true},
		{"f": 1, "r": Rect2(-35, -16, 4, 6), "x": false},
		{"f": 1, "r": Rect2(30, -18, 4, 8), "x": false},
		{"f": 2, "r": Rect2(-2, -18, 4, 4), "x": false},
		{"f": 2, "r": Rect2(12, -32, 8, 4), "x": true},
		{"f": 2, "r": Rect2(-20, -32, 8, 4), "x": true},
		{"f": 2, "r": Rect2(-36, -50, 4, 8), "x": false},
		{"f": 3, "r": Rect2(-34, -74, 4, 8), "x": false},
		{"f": 3, "r": Rect2(-20, -88, 8, 4), "x": true},
		{"f": 3, "r": Rect2(12, -88, 8, 4), "x": true},
		{"f": 3, "r": Rect2(30, -74, 4, 8), "x": false},
		{"f": 4, "r": Rect2(30, -48, 4, 6), "x": false},
		{"f": 4, "r": Rect2(16, -35, 6, 4), "x": true},
	]
	holes = []
	water = []
	mood = {
		# Hot, golden light inside; a white-hot sky over the Sun Chamber.
		"sky_top": Color.html("3a78d8"), "sky_mid": Color.html("8ab8e8"), "sky_horizon": Color.html("f8e0b0"),
		"cloud": Color.html("fff4e0"), "cloud_amount": 0.15,
		"fog": Color.html("3a2a1a"), "fog_begin": 20.0, "fog_end": 75.0,
		"ambient": Color.html("8a6a48"), "sun": Color.html("fff0c8"), "sun_rot": Vector3(-70, -30, 0),
		"sun_energy": 0.85, "fill": Color.html("7a6a5a"), "fill_energy": 0.35,
		"horizon": Color.html("c8a070"), "hill_height": 0.0,
	}


func in_sand(x: float, z: float, f: int) -> bool:
	for s: Array in SANDS:
		if s[0] == f and (s[1] as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## Crypt flagstones below; sandstone tiles above, the quicksand pale and
## rippled; the Sun Chamber's floor is drifted sand.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if in_sand(x, z, f):
		var ripple := sin(x * 1.7 + sin(z * 0.6) * 2.0) * 0.5 + 0.5
		return Color.html("e8cc8c").lerp(Color.html("c8a464"), ripple * 0.6).darkened(r.randf_range(0.0, 0.05))
	if f == 4:
		var dune := sin(x * 0.4 + z * 0.25) * 0.5 + 0.5
		return Color.html("ecd29a").lerp(Color.html("d8b878"), dune * 0.5).darkened(r.randf_range(0.0, 0.05))
	if f == 0:
		var inside := false
		for id: String in ["descent", "crypt", "ossuary", "lord"]:
			if (rooms[id].r as Rect2).grow(1.0).has_point(Vector2(x, z)):
				inside = true
		for c: Dictionary in corridors:
			if c.f == 0 and (c.r as Rect2).has_point(Vector2(x, z)):
				inside = true
		if not inside:
			return Color.html("1a140e")
		var seam := fposmod(x, 2.0) < 0.1 or fposmod(z, 2.0) < 0.1
		return Color.html("4a4038") if seam else Color.html(["7a6e60", "72665a", "807464"][posmod(int(floor(x / 2.0)) + int(floor(z / 2.0)), 3)]).darkened(r.randf_range(0.0, 0.08))
	var tx := int(floor(x / 1.5))
	var tz := int(floor(z / 1.5))
	if fposmod(x, 1.5) < 0.08 or fposmod(z, 1.5) < 0.08:
		return Color.html("a08060")
	var c := Color.html(TILE[posmod(tx + tz * 2, 3)])
	# A sun inlaid in the Great Hall's floor.
	if f == 1 and Vector2(x, z - 2.0).length() < 4.0:
		c = c.lerp(Color.html("e8a040"), 0.5 if Vector2(x, z - 2.0).length() < 1.6 or int(Vector2(x, z - 2.0).angle() * 6.0 / PI) % 2 == 0 else 0.15)
	if f == 3 and (rooms.shadehall.r as Rect2).has_point(Vector2(x, z)):
		c = c.darkened(0.45)
	return c.darkened(r.randf_range(0.0, 0.08))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 33.98), 0.0, 1.8, 2.8, "desert", "from_ladhellin_tower")
	k.entrance("from_desert", 0.0, 31.0, 0.0)
	_descent(k)
	_crypt(k)
	_ossuary(k)
	_lord(k)
	_entry(k)
	_hall(k)
	_court(k)
	_vault(k)
	_shrine(k)
	_sunroom(k)
	_beetles(k)
	_colonnade(k)
	_stair2(k)
	_shadehall(k)
	_mirrors3(k)
	_sentinel(k)
	_stair4(k)
	_ante(k)
	_sun_chamber(k)


# --- Decoration -----------------------------------------------------------------

func _torch(k, x: float, z: float, y: float) -> void:
	k.brazier(x, z, true, y)


func _lamps(k, id: String, inset := 2.5) -> void:
	var r: Rect2 = rooms[id].r
	var y := room_y(id)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


## A stone coffin with a carved lid.
func _coffin(k, x: float, z: float, y: float, yaw := 0.0) -> void:
	k.block(Vector3(x, y + 0.45, z), Vector3(1.1, 0.9, 2.4), yaw, "sandstone", Color(0.82, 0.74, 0.62))
	k.block(Vector3(x, y + 0.98, z), Vector3(1.25, 0.16, 2.55), yaw, "sandstone", Color(0.92, 0.82, 0.66))


func _obelisk(k, x: float, z: float, y: float, hh := 4.0) -> void:
	var m = k._tmp()
	m.prism(Vector3(x, y, z), 0.5, Vector3(x, y + hh, z), 0.32, 4, Color(0.95, 0.85, 0.66), PI / 4.0)
	m.prism(Vector3(x, y + hh, z), 0.32, Vector3(x, y + hh + 0.6, z), 0.0, 4, Color(0.95, 0.75, 0.35), PI / 4.0)
	k.merge(m, "sandstone")
	k.col_box(Vector3(x, y + hh * 0.5, z), Vector3(0.8, hh, 0.8), PI / 4.0).set_meta("no_climb", true)


func _railing(k, a: Vector3, b: Vector3) -> void:
	var along := b - a
	var r = k._tmp()
	r.box((a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(maxf(absf(along.x), 0.3), 0.9, maxf(absf(along.z), 0.3)), Color(0.95, 0.85, 0.66))
	k.merge(r, "sandstone")
	k.col_box((a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(maxf(absf(along.x), 0.3), 0.9, maxf(absf(along.z), 0.3))).set_meta("no_climb", true)


# --- B1: the crypt ---------------------------------------------------------------

func _descent(k) -> void:
	var y := room_y("descent")
	# The landing at 1F height by the door from the shrine, and the stairs
	# down to the crypt floor.
	k.block(Vector3(32, y + 4.0, -20), Vector3(6, 8, 4), 0.0, "sandstone", Color(0.9, 0.82, 0.7))
	k.stairs(32.0, -33.5, PI, 3.0, 11.5, 8.0, "sandstone", y)
	_lamps(k, "descent", 1.6)


func _crypt(k) -> void:
	var y := room_y("crypt")
	for x in [-2.0, 4.0, 10.0]:
		for z in [-36.0, -25.0]:
			_coffin(k, x, z, y)
	_lamps(k, "crypt", 1.6)
	k.locked_door(5.0, -44.0, 0.0, D + ":door_key2", false, y)
	k.pot(14.5, -38.5, "", false, y)
	k.pot(14.5, -37.5, "arrows_10", false, y)


func _ossuary(k) -> void:
	var y := room_y("ossuary")
	k.shutter(-12.6, -30.0, PI / 2.0, "ossuary", y)
	_lamps(k, "ossuary", 1.6)
	for z in [-38.0, -22.0]:
		_coffin(k, -27.0, z, y, PI / 2.0)
	k.chest(-21.0, -30.0, -PI / 2.0, "small_key", false, D + ":chest_key2", D + ":ossuary_clear", y)
	k.chest(-28.5, -30.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", y)


func _lord(k) -> void:
	var y := room_y("lord")
	k.shutter(5.0, -48.6, 0.0, "lord", y)
	# Braziers burning round the walls: arrows shot through them catch fire.
	for p in [Vector2(-3, -51), Vector2(13, -51), Vector2(-3, -69), Vector2(13, -69), Vector2(-3, -60), Vector2(13, -60)]:
		_torch(k, p.x, p.y, y)
	for x in [-1.0, 11.0]:
		_obelisk(k, x, -64.0, y, 5.0)
	k.chest(5.0, -66.0, 0.0, "shield_mirror", true, D + ":chest_mirror_shield", D + ":lord_clear", y)


# --- 1F --------------------------------------------------------------------------

func _entry(k) -> void:
	for z in [25.0, 31.0]:
		for sx in [-1.0, 1.0]:
			_obelisk(k, sx * 4.5, z, 0.0, 4.0)
	_torch(k, -2.6, 23.5, 0.0)
	_torch(k, 2.6, 23.5, 0.0)
	k.pot(4.6, 32.6, "heart", false, 0.0)
	k.pot(-4.6, 32.6, "", false, 0.0)


func _hall(k) -> void:
	var up := fy(2)
	# Stairs up the west side to a gallery along the north wall at 2F height.
	k.stairs(-11.0, 8.0, 0.0, 3.0, 12.0, up, "sandstone", 0.0)
	k.block(Vector3(0, up - 0.25, -9.0), Vector3(32, 0.5, 10), 0.0, "sandstone", Color(0.96, 0.86, 0.7))
	for x in [-6.0, 0.0, 6.0, 12.0]:
		k.pillar(x, -4.6, up - 0.5, 0.45, false, "sandstone", 0.0)
	_railing(k, Vector3(-9.3, up, -4.2), Vector3(15.8, up, -4.2))
	k.flag_bars(0.0, -14.4, 0.0, D + ":hall_sun", up)
	# Two shafts of sun through oculi in the roof; the sun on the east wall.
	k.sun_shaft(6.0, 6.0, 0.0, 14.0)
	k.sun_shaft(-5.0, 11.0, 0.0, 14.0)
	k.sun_switch(Vector3(15.88, 1.3, -8.0), PI / 2.0, D + ":hall_sun")
	for p in [Vector2(-14, 16), Vector2(14, 16), Vector2(14, -12)]:
		_torch(k, p.x, p.y, 0.0)
	_torch(k, -6.0, -12.5, up)
	_torch(k, 6.0, -12.5, up)
	for p in [Vector2(14.5, 10.5), Vector2(14.5, 11.5), Vector2(-14.5, -1.0)]:
		k.pot(p.x, p.y, "", false, 0.0)
	k.locked_door(18.5, 2.0, PI / 2.0, D + ":door_key1", false, 0.0)


func _court(k) -> void:
	for s: Array in SANDS:
		if s[0] == 1:
			k.quicksand(s[1], 0.0)
	for p: Vector2 in STONES:
		k.block(Vector3(p.x, 0.25, p.y), Vector3(2.4, 0.5, 2.4), 0.0, "sandstone", Color(0.88, 0.8, 0.66))
	_lamps(k, "court", 1.6)
	k.chest(-42.5, 2.0, -PI / 2.0, "small_key", false, D + ":chest_key1", "", 0.0)


func _vault(k) -> void:
	_lamps(k, "vault", 1.6)
	k.block(Vector3(-33.0, 0.5, -26.0), Vector3(2.0, 1.0, 2.0), 0.0, "sandstone", Color(0.95, 0.8, 0.5))
	k.heart_piece(-33.0, -26.0, D + ":heart_piece", 1.0)
	k.pot(-40.5, -28.5, "rupee_blue", false, 0.0)
	k.pot(-25.5, -28.5, "", false, 0.0)
	# A false stretch of the west wall (Mira's Looking Glass) hides a chest.
	k.lens_alcove(Vector2(-42.0, -23.0), Vector2(1, 0), 3.0, 2.4, 0.0, "rupee_red", D + ":chest_lens", "sandstone", wall_col)


func _shrine(k) -> void:
	_lamps(k, "shrine", 1.6)
	for z in [-6.0, 10.0]:
		_coffin(k, 38.0, z, 0.0, PI / 2.0)
	_obelisk(k, 26.0, -6.0, 0.0)
	_obelisk(k, 26.0, 10.0, 0.0)
	k.chest(38.0, 2.0, -PI / 2.0, "map", false, D + ":chest_map", "", 0.0)
	# Pegs for the Iron Mallet, and a chest when all three are down (Beta 1.7.0).
	var stakes: Array = []
	for st in [[31.0, -6.5, "stake_a"], [31.0, 10.5, "stake_b"], [34.5, -2.5, "stake_c"]]:
		k.mallet_stake(st[0], st[1], D + ":" + st[2], 0.0)
		stakes.append(D + ":" + st[2])
	k.flag_all(stakes, D + ":stakes")
	k.chest(32.0, 12.4, 0.0, "rupee_purple", false, D + ":chest_stakes", D + ":stakes", 0.0)


# --- 2F --------------------------------------------------------------------------

func _sunroom(k) -> void:
	var y := room_y("sunroom")
	k.sun_shaft(0.0, -30.0, y, 6.4)
	# East: straight from the light. West: round a pillar, by the mirror.
	k.sun_switch(Vector3(11.88, y + 1.3, -34.0), PI / 2.0, D + ":sun_east")
	k.sun_switch(Vector3(-11.88, y + 1.3, -26.0), -PI / 2.0, D + ":sun_west")
	k.pillar(-6.5, -27.8, 6.5, 0.6, false, "sandstone", y)
	k.light_mirror(-8.0, -22.0, PI, y)
	k.flag_bars(12.4, -30.0, PI / 2.0, D + ":sun_east", y)
	k.flag_bars(-12.4, -30.0, PI / 2.0, D + ":sun_west", y)
	_lamps(k, "sunroom", 1.6)


func _beetles(k) -> void:
	var y := room_y("beetles")
	for s: Array in SANDS:
		if s[0] == 2:
			k.quicksand(s[1], y)
	_lamps(k, "beetles", 1.6)
	k.block(Vector3(37.0, y + 0.3, -38.5), Vector3(4.0, 0.6, 3.0), 0.0, "sandstone", Color(0.95, 0.82, 0.6))
	k.chest(37.0, -38.5, 0.0, "small_key", false, D + ":chest_key3", "", y + 0.6)
	k.pot(40.5, -20.5, "", false, y)
	k.pot(39.5, -20.5, "rupee_blue", false, y)


func _colonnade(k) -> void:
	var y := room_y("colonnade")
	# A slit in the west wall throws a beam east; mirror one sends it north to
	# mirror two, which sends it west onto the sun.
	k.sun_beam(Vector3(-43.8, y + 1.15, -24.0), -PI / 2.0)
	k.light_mirror(-32.0, -24.0, PI, y)
	k.light_mirror(-32.0, -38.0, -PI / 2.0, y)
	k.sun_switch(Vector3(-43.88, y + 1.3, -38.0), -PI / 2.0, D + ":colonnade_sun")
	k.flag_bars(-34.0, -42.4, 0.0, D + ":colonnade_sun", y)
	for p in [Vector2(-26, -20.5), Vector2(-26, -40), Vector2(-38, -20.5), Vector2(-38, -28), Vector2(-26, -30)]:
		k.pillar(p.x, p.y, 6.5, 0.55, false, "sandstone", y)
	_torch(k, -22.0, -20.0, y)
	_torch(k, -22.0, -40.0, y)


func _stair2(k) -> void:
	var y := room_y("stair2")
	k.stairs(-32.0, -52.0, 0.0, 3.0, 11.0, FLOOR_H, "sandstone", y)
	k.block(Vector3(-32.0, y + FLOOR_H * 0.5, -64.5), Vector3(6.0, FLOOR_H, 3.0), 0.0, "sandstone", Color(0.9, 0.82, 0.7))
	_lamps(k, "stair2", 1.6)


# --- 3F --------------------------------------------------------------------------

func _shadehall(k) -> void:
	var y := room_y("shadehall")
	# No braziers: only the light from the oculus.
	k.sun_shaft(-32.0, -85.0, y, 6.4)
	k.shutter(-32.0, -74.6, 0.0, "shadehall", y)
	k.shutter(-20.6, -86.0, PI / 2.0, "shadehall", y)
	for p in [Vector2(-40, -92), Vector2(-24, -92), Vector2(-40, -78), Vector2(-24, -78)]:
		_obelisk(k, p.x, p.y, y, 5.0)


func _mirrors3(k) -> void:
	var y := room_y("mirrors3")
	k.sun_beam(Vector3(-8.0, y + 1.15, -95.8), PI)
	k.light_mirror(-8.0, -80.0, PI / 2.0, y)
	k.light_mirror(6.0, -80.0, PI, y)
	k.light_mirror(6.0, -92.0, PI / 2.0, y)
	k.sun_switch(Vector3(11.88, y + 1.3, -92.0), PI / 2.0, D + ":mirrors_sun")
	k.flag_bars(12.4, -86.0, PI / 2.0, D + ":mirrors_sun", y)
	_lamps(k, "mirrors3", 1.6)


func _sentinel(k) -> void:
	var y := room_y("sentinel")
	k.locked_door(17.0, -86.0, PI / 2.0, D + ":door_key3", false, y)
	k.shutter(20.6, -86.0, PI / 2.0, "sentinel", y)
	k.shutter(32.0, -74.6, 0.0, "sentinel", y)
	_lamps(k, "sentinel", 1.6)
	for p in [Vector2(24, -92), Vector2(38, -92)]:
		_obelisk(k, p.x, p.y, y, 5.0)
	k.chest(31.0, -92.0, 0.0, "boss_key", true, D + ":chest_boss_key", D + ":sentinel_clear", y)


func _stair4(k) -> void:
	var y := room_y("stair4")
	k.stairs(32.0, -64.0, PI, 3.0, 11.0, FLOOR_H, "sandstone", y)
	k.block(Vector3(32.0, y + FLOOR_H * 0.5, -50.5), Vector3(6.0, FLOOR_H, 5.0), 0.0, "sandstone", Color(0.9, 0.82, 0.7))
	_lamps(k, "stair4", 1.6)


# --- 4F --------------------------------------------------------------------------

func _ante(k) -> void:
	var y := room_y("ante")
	_lamps(k, "ante", 1.6)
	k.locked_door(19.0, -33.0, PI / 2.0, D + ":boss_door", true, y)
	k.pot(40.5, -25.5, "heart", false, y)
	k.pot(40.5, -40.5, "", false, y)


func _sun_chamber(k) -> void:
	var y := room_y("boss")
	var r: Rect2 = rooms.boss.r
	var c := r.get_center()
	k.shutter(r.end.x - 0.6, -33.0, PI / 2.0, "boss", y)
	# The light falls into the middle of the sand through the open roof.
	k.sun_shaft(c.x, c.y, y, 10.0)
	for p in [Vector2(r.position.x + 2, r.position.y + 2), Vector2(r.end.x - 2, r.position.y + 2), Vector2(r.position.x + 2, r.end.y - 2), Vector2(r.end.x - 2, r.end.y - 2)]:
		_obelisk(k, p.x, p.y, y, 5.5)
	var clear := D + ":boss_clear"
	k.heart_container(c.x - 3.0, c.y + 5.0, clear, D + ":heart_container", y)
	k.bun_piece(c.x + 3.0, c.y + 5.0, "serielye", clear, y)
	k.blue_warp(c.x, c.y - 5.0, clear, "desert", "warp_ladhellin_tower", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(0)
	var f2 := fy(2)
	var f3 := fy(3)
	var f4 := fy(4)
	k.enemy("mummy", 1.0, -30.5, PI, {"room": "crypt"}, b1)
	k.enemy("mummy", 7.0, -30.5, PI, {"room": "crypt"}, b1)
	k.enemy("keese", 10.0, -24.0, 0.0, {"room": "crypt"}, b1 + 4.0)
	k.enemy("mummy", -24.0, -26.0, PI / 2.0, {"room": "ossuary"}, b1)
	k.enemy("mummy", -24.0, -34.0, PI / 2.0, {"room": "ossuary"}, b1)
	k.enemy("rat", -18.0, -24.0, PI / 2.0, {"room": "ossuary"}, b1)
	k.enemy("rat", -18.0, -36.0, PI / 2.0, {"room": "ossuary"}, b1)
	k.enemy("mummy_lord", 5.0, -62.0, 0.0, {"room": "lord"}, b1)
	k.enemy("leever", -30.0, 8.0, 0.0, {"room": "court"})
	k.enemy("mummy", -42.0, -6.0, -PI / 2.0, {"room": "court"})
	k.enemy("keese", 8.0, -2.0, 0.0, {"room": "hall"}, 6.0)
	k.enemy("mummy", 34.0, 8.0, PI / 2.0, {"room": "shrine"})
	k.enemy("mummy", -6.0, -38.0, 0.0, {"room": "sunroom"}, f2)
	k.enemy("sand_beetle", 27.0, -24.0, PI / 2.0, {"room": "beetles"}, f2)
	k.enemy("sand_beetle", 36.0, -22.0, PI / 2.0, {"room": "beetles"}, f2)
	k.enemy("sand_beetle", 30.0, -40.0, PI / 2.0, {"room": "beetles"}, f2)
	k.enemy("keese", -36.0, -32.0, 0.0, {"room": "colonnade"}, f2 + 4.0)
	k.enemy("shade", -38.0, -88.0, 0.0, {"room": "shadehall"}, f3 + 1.3)
	k.enemy("shade", -26.0, -80.0, 0.0, {"room": "shadehall"}, f3 + 1.3)
	k.enemy("shade", -30.0, -92.0, 0.0, {"room": "shadehall"}, f3 + 1.3)
	k.enemy("mummy", 0.0, -86.0, 0.0, {"room": "mirrors3"}, f3)
	k.enemy("sentinel", 31.0, -84.0, 0.0, {"room": "sentinel"}, f3)
	k.enemy("mummy", 28.0, -30.0, 0.0, {"room": "ante"}, f4)
	var r: Rect2 = rooms.boss.r
	k.enemy("wyrm", r.get_center().x, r.get_center().y, 0.0, {"room": "boss", "arena_radius": 13.0}, f4)
