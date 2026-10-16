extends "res://tools/world/tower_region.gd"
## Frostpeak Hollow, under the frozen falls on Frostpeak's east cliff: caverns
## of blue ice and old stone where the mountain's meltwater runs black and
## freezing. The Sapphire Order camped here on their way east, and bound the
## Meltwater Serpent to guard their trail. The cold is bitter (WorldData
## "chill": the Frost Mantle keeps it off). Chapter II's first dungeon; its
## treasure is the Frost Arrows, its master Sleetcoil.
##
## Storeys (north is -Z):
##   B1 (y -8)  knight    under the Icefall (the hole in its floor): the
##                        Rimeguard behind shutters -> the Frost Arrows
##              cistern   under the Great Cavern, split by a channel of
##                        freezing water: freeze floes across it (Frost Arrows)
##                        -> Small Key 2, and a ladder up into the Cavern
##   1F (y 0)   entry     in from Frostpeak
##              cavern    the Great Cavern, two storeys tall: the Map; a basin
##                        of freezing water with a chest on its islet (floes
##                        again, for a Piece of Heart); locked north (Key 2)
##              stakes    west: three stakes to drive in with the Iron Mallet
##                        -> Small Key 1, and the Compass
##              icefall   east (Small Key 1): freezards and ice keese behind
##                        shutters; the hole down to the Rimeguard
##              stair     north (Small Key 2): a stairwell up to 2F
##   2F (y 8)   gallery   frost stalfos behind shutters -> the Boss Key;
##                        through a false wall (Looking Glass), rupees
##              boss      the serpent's pool, ringed with ice: Sleetcoil;
##                        then the heart container, the blue warp home, and
##                        the letter the Order left behind

const D := "frostpeak_hollow"
const ICE := Color(0.82, 0.92, 1.0)
const DEEP := Color(0.25, 0.38, 0.55, 0.85)
## The Cavern's basin of freezing water (raised rim) and the islet in it.
const BASIN := Rect2(2, -12, 10, 9)
const BASIN_Y := 0.55
const ISLET := Rect2(6.2, -8.6, 1.8, 1.8)
## The cistern's channel of freezing water, north to south across the room.
const CHANNEL := Rect2(-3.5, -12, 7, 24)
const CHANNEL_Y := -7.45
## The serpent's pool in the boss room.
const POOL := Rect2(-7, -93, 14, 14)
const POOL_Y := 8.3


func setup() -> void:
	id = "frostpeak_hollow"
	interior = true
	seed_value = 271
	x_min = -48.0
	x_max = 44.0
	z_min = -104.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0]]
	entry_floor = 1
	wall_col = Color(0.8, 0.9, 1.0)
	ceil_col = Color(0.35, 0.45, 0.6)
	slab_col = Color(0.78, 0.88, 0.98)
	rooms = {
		"knight": {"f": 0, "r": Rect2(18, -11, 22, 22), "h": 6.5, "doors": [{"side": "w", "at": 0.0}], "col": Color(0.72, 0.84, 0.98)},
		"cistern": {"f": 0, "r": Rect2(-12, -12, 24, 24), "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.7, 0.82, 0.96)},
		"entry": {"f": 1, "r": Rect2(-6, 18, 12, 12), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"cavern": {"f": 1, "r": Rect2(-14, -14, 28, 28), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"stakes": {"f": 1, "r": Rect2(-38, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"icefall": {"f": 1, "r": Rect2(18, -11, 22, 22), "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"stair": {"f": 1, "r": Rect2(-8, -40, 16, 18), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		"gallery": {"f": 2, "r": Rect2(-12, -66, 24, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"boss": {"f": 2, "r": Rect2(-14, -100, 28, 28), "h": 9.0, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.74, 0.86, 1.0)},
	}
	corridors = [
		{"f": 0, "r": Rect2(12, -2, 6, 4), "x": true},
		{"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-18, -2, 4, 4), "x": true},
		{"f": 1, "r": Rect2(14, -2, 4, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -22, 4, 8), "x": false},
		{"f": 2, "r": Rect2(-2, -46, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-2, -72, 4, 6), "x": false},
	]
	holes = [
		# The hole in the Icefall's floor where the ladder climbs from the Rimeguard's hall.
		{"f": 1, "r": ladder_hole(38.0, -6.0, Vector2(-1, 0))},
		# The hole in the Cavern's floor over the cistern's ladder.
		{"f": 1, "r": ladder_hole(-10.6, -8.0, Vector2(1, 0))},
	]
	water = [
		{"rect": BASIN.grow(-0.4), "y": BASIN_Y, "col": DEEP},
		{"rect": CHANNEL, "y": CHANNEL_Y, "col": DEEP},
		{"rect": POOL, "y": POOL_Y, "col": Color(0.22, 0.36, 0.55, 0.88)},
	]
	mood = {
		"sky_top": Color.html("1a2436"), "sky_mid": Color.html("1a2436"), "sky_horizon": Color.html("1a2436"),
		"cloud": Color.html("1a2436"), "cloud_amount": 0.0,
		"fog": Color.html("142034"), "fog_begin": 14.0, "fog_end": 60.0,
		"ambient": Color.html("6a7ea0"), "sun": Color.html("d8ecff"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.55, "fill": Color.html("4a6a9a"), "fill_energy": 0.45,
		"horizon": Color.html("1a2436"), "hill_height": 0.0, "particles": "snow",
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


func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "ice" if Vector2(x, z).distance_to(Vector2(0, 0)) < 9.0 else "stone"


## Frosted flagstones veined with ice; dark water in the channel and pools.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if not _inside(x, z, f):
		return pick(r, ["0c1018", "10141e"])
	if (f == 0 and CHANNEL.has_point(p)) or (f == 1 and BASIN.has_point(p)) or (f == 2 and POOL.has_point(p)):
		return pick(r, ["1a2a40", "1e3048", "16263a"])
	if f == 2 and (rooms.boss.r as Rect2).has_point(p):
		return pick(r, ["b8d4ec", "c4dcf2", "aecce6"]).darkened(r.randf_range(0.0, 0.08))
	var seam := fposmod(x, 1.8) < 0.1 or fposmod(z + (0.9 if int(floor(x / 1.8)) % 2 == 0 else 0.0), 1.8) < 0.1
	if seam:
		return Color.html("3a4a62")
	var base := Color.html(["7a8aa4", "8494ae", "74849e"][r.randi() % 3])
	if noise.get_noise_2d(x * 3.0, z * 3.0) > 0.2:
		base = base.lerp(Color.html("c8e0f4"), 0.55)
	return base.darkened(r.randf_range(0.0, 0.1) + (0.12 if f == 0 else 0.0))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "snow", "from_frostpeak_hollow", Color(0.85, 0.95, 1.0))
	k.entrance("from_snow", 0.0, 27.0, 0.0)
	_knight(k)
	_cistern(k)
	_entry(k)
	_cavern(k)
	_stakes(k)
	_icefall(k)
	_stair(k)
	_gallery(k)
	_boss(k)


# --- Decoration -----------------------------------------------------------------

func _torch(k, x: float, z: float, y := 0.0) -> void:
	k.brazier(x, z, true, y)


func _lamps(k, rid: String, inset := 2.5) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


## Icicles hanging from a ceiling at height `top`, scattered over `r`.
func _icicles(k, r: Rect2, top: float, n: int) -> void:
	var m = k._tmp(false)
	var rng: RandomNumberGenerator = k.rng
	for i in n:
		var p := Vector3(rng.randf_range(r.position.x + 1, r.end.x - 1), top, rng.randf_range(r.position.y + 1, r.end.y - 1))
		var len := rng.randf_range(0.4, 1.4)
		m.prism(p, rng.randf_range(0.08, 0.2), p - Vector3(0, len, 0), 0.0, 5, ICE.lightened(rng.randf_range(0.0, 0.2)))
	k.merge(m, "glow")


## Spires of ice growing up from the floor at height `y`.
func _ice_spires(k, pts: Array, y: float) -> void:
	var m = k._tmp()
	var rng: RandomNumberGenerator = k.rng
	for p: Vector2 in pts:
		var r := rng.randf_range(0.5, 0.9)
		var hh := rng.randf_range(1.6, 3.2)
		m.prism(Vector3(p.x, y, p.y), r, Vector3(p.x, y + hh, p.y), r * 0.2, 5, ICE.lightened(rng.randf_range(0.0, 0.15)), rng.randf() * TAU)
		k.col_cyl(Vector3(p.x, y, p.y), r * 0.8, hh)
	k.merge(m, "ice")


## A channel or basin of freezing water: a void zone just under its surface
## returns whoever falls in to the room's door, a little colder (Frost Arrows
## freeze floes on the water to cross).
func _freezing(k, r: Rect2, floor_y: float, surface_y: float) -> void:
	var top := surface_y - 0.15
	k.void_zone(Vector3(r.get_center().x, (floor_y + top) * 0.5 - 0.3, r.get_center().y), Vector3(r.size.x, top - floor_y + 0.6, r.size.y), 2)


# --- B1 -------------------------------------------------------------------------

func _knight(k) -> void:
	var y := room_y("knight")
	ladder_up(k, 0, 38.0, -6.0, Vector2(-1, 0))
	k.shutter(18.6, 0.0, PI / 2.0, "knight", y)
	_lamps(k, "knight", 2.0)
	_ice_spires(k, [Vector2(21, -8), Vector2(21, 8), Vector2(37, 8)], y)
	_icicles(k, rooms.knight.r, y + 6.4, 18)
	k.chest(30.0, 0.0, PI / 2.0, "frost_arrows", true, D + ":chest_frost_arrows", D + ":knight_clear", y)
	for p in [Vector2(37.5, 9.5), Vector2(38.5, 9.5)]:
		k.pot(p.x, p.y, "magic_small" if p.x < 38.0 else "", false, y)


func _cistern(k) -> void:
	var y := room_y("cistern")
	k.shutter(11.4, 0.0, PI / 2.0, "cistern", y)
	_freezing(k, CHANNEL, y, CHANNEL_Y)
	# Both banks stand at the height of a floe, so the hero steps straight on.
	var bank := CHANNEL_Y + 0.05
	k.block(Vector3((CHANNEL.end.x + 10.6) * 0.5, (y + bank) * 0.5, 0.0), Vector3(10.6 - CHANNEL.end.x, bank - y, 24.0), 0.0, "stone", Color(0.72, 0.82, 0.95))
	k.block(Vector3((CHANNEL.position.x - 12.0) * 0.5, (y + bank) * 0.5, 0.0), Vector3(CHANNEL.position.x + 12.0, bank - y, 24.0), 0.0, "stone", Color(0.72, 0.82, 0.95))
	_lamps(k, "cistern", 1.8)
	_icicles(k, rooms.cistern.r, y + 6.4, 16)
	# The far (west) bank: the key, and the ladder up into the Cavern.
	ladder_up(k, 0, -10.6, -8.0, Vector2(1, 0))
	k.chest(-9.0, 7.0, PI / 2.0, "small_key", false, D + ":chest_key2", "", bank)
	# Arrows in the pots on the near bank, for the floes.
	k.pot(9.5, 10.5, "arrows_10", false, bank)
	k.pot(9.5, -10.5, "magic_small", false, bank)
	k.examine(Vector3(5.0, bank, 9.0), k.yaw_of(Vector2(-1, 0)), [{"text": "Words scratched into the ice:\n*Only a fool would swim in it. Only a cleverer fool would make it into ice.*", "instant": true}])


# --- 1F --------------------------------------------------------------------------

func _entry(k) -> void:
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.5, z, 6.5, 0.45, z > 25.0, "stone", 0.0)
	_torch(k, -2.6, 19.5)
	_torch(k, 2.6, 19.5)
	_icicles(k, rooms.entry.r, 6.4, 8)
	k.pot(4.8, 28.5)
	k.pot(4.8, 27.5, "heart")
	k.pot(-4.8, 28.5, "arrows_10")


func _cavern(k) -> void:
	# The basin of freezing water, its rim of ice, and the islet in it.
	var rim = k._tmp()
	for side in [[Vector3(BASIN.get_center().x, 0.3, BASIN.position.y), Vector3(BASIN.size.x + 0.8, 0.6, 0.8)],
			[Vector3(BASIN.get_center().x, 0.3, BASIN.end.y), Vector3(BASIN.size.x + 0.8, 0.6, 0.8)],
			[Vector3(BASIN.position.x, 0.3, BASIN.get_center().y), Vector3(0.8, 0.6, BASIN.size.y)],
			[Vector3(BASIN.end.x, 0.3, BASIN.get_center().y), Vector3(0.8, 0.6, BASIN.size.y)]]:
		rim.box(side[0], side[1], ICE.darkened(0.15))
	k.merge(rim, "ice")
	for side in [[Vector3(BASIN.get_center().x, 0.3, BASIN.position.y), Vector3(BASIN.size.x + 0.8, 0.6, 0.8)],
			[Vector3(BASIN.get_center().x, 0.3, BASIN.end.y), Vector3(BASIN.size.x + 0.8, 0.6, 0.8)],
			[Vector3(BASIN.position.x, 0.3, BASIN.get_center().y), Vector3(0.8, 0.6, BASIN.size.y)],
			[Vector3(BASIN.end.x, 0.3, BASIN.get_center().y), Vector3(0.8, 0.6, BASIN.size.y)]]:
		k.col_box(side[0], side[1])
	_freezing(k, BASIN.grow(-0.4), 0.0, BASIN_Y)
	k.block(Vector3(ISLET.get_center().x, 0.32, ISLET.get_center().y), Vector3(ISLET.size.x, 0.64, ISLET.size.y), 0.0, "stone", Color(0.7, 0.8, 0.92))
	k.chest(ISLET.get_center().x, ISLET.get_center().y, PI, "heart_piece", false, D + ":chest_heart", "", 0.64)
	# A frozen waterfall down the north wall, and spires round the hall.
	k.block(Vector3(-8.0, 7.0, -13.3), Vector3(5.0, 14.0, 0.8), 0.0, "ice", ICE)
	_ice_spires(k, [Vector2(-11, 11), Vector2(11, 11), Vector2(-11, -11), Vector2(-4, 10), Vector2(4, 10)], 0.0)
	_icicles(k, rooms.cavern.r, 14.4, 40)
	_torch(k, -2.6, 12.5)
	_torch(k, 2.6, 12.5)
	_torch(k, -12.5, 2.6)
	_torch(k, 12.5, 2.6)
	_torch(k, -2.6, -12.5)
	_torch(k, 2.6, -12.5)
	k.locked_door(15.4, 0.0, PI / 2.0, D + ":door_key1")
	k.locked_door(0.0, -15.4, 0.0, D + ":door_key2")
	k.chest(-9.0, 9.0, PI * 0.5, "map", false, D + ":chest_map")
	for p in [Vector2(10.5, 12.5), Vector2(12.0, 12.5), Vector2(-12.5, 4.5)]:
		k.pot(p.x, p.y, "", false)


func _stakes(k) -> void:
	_lamps(k, "stakes", 1.8)
	_icicles(k, rooms.stakes.r, 6.4, 12)
	# Three stakes: drive them all into the ice and the key's chest appears.
	var flags: Array = []
	for s in [[-34.0, -6.0, "stake_a"], [-34.0, 6.0, "stake_b"], [-26.0, 0.0, "stake_c"]]:
		k.mallet_stake(s[0], s[1], D + ":" + s[2], 0.0)
		flags.append(D + ":" + s[2])
	k.flag_all(flags, D + ":stakes")
	k.chest(-30.0, -8.5, 0.0, "small_key", false, D + ":chest_key1", D + ":stakes", 0.0)
	k.chest(-36.0, 8.5, PI, "compass", false, D + ":chest_compass", "", 0.0)
	k.examine(Vector3(-21.0, 0.0, 6.5), k.yaw_of(Vector2(-1, 0)), [{"text": "Words scratched into the ice:\n*Three posts hold the cold in place. Strike them down, and the way is yours.*", "instant": true}])
	k.pot(-36.5, -8.5, "bombs_5")


func _icefall(k) -> void:
	k.shutter(18.6, 0.0, PI / 2.0, "icefall")
	_lamps(k, "icefall", 1.6)
	_icicles(k, rooms.icefall.r, 6.4, 16)
	_ice_spires(k, [Vector2(24, 8), Vector2(34, 8), Vector2(29, -8)], 0.0)
	k.pot(38.5, 9.5, "")
	k.pot(37.5, 9.5, "heart")


func _stair(k) -> void:
	var y := room_y("stair")
	k.stairs(0.0, -24.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(0.0, y + FLOOR_H * 0.5, -38.5), Vector3(6.0, FLOOR_H, 3.0), 0.0, "stone", Color(0.74, 0.84, 0.96))
	_lamps(k, "stair", 1.6)
	_torch(k, -2.4, -38.5, y + FLOOR_H)
	_torch(k, 2.4, -38.5, y + FLOOR_H)
	_icicles(k, rooms.stair.r, 14.4, 14)


# --- 2F --------------------------------------------------------------------------

func _gallery(k) -> void:
	var y := room_y("gallery")
	k.shutter(0.0, -46.6, 0.0, "gallery", y)
	_lamps(k, "gallery", 1.8)
	_icicles(k, rooms.gallery.r, y + 6.4, 16)
	_ice_spires(k, [Vector2(-8, -50), Vector2(8, -50), Vector2(-8, -62), Vector2(8, -62)], y)
	k.chest(0.0, -60.0, PI, "boss_key", true, D + ":chest_boss_key", D + ":gallery_clear", y)
	# A false wall in the east alcove (Looking Glass): rupees behind it.
	k.block(Vector3(10.0, y + 1.5, -53.5), Vector3(3.6, 3.0, 0.5), 0.0, "stone", wall_col)
	k.block(Vector3(10.0, y + 1.5, -58.5), Vector3(3.6, 3.0, 0.5), 0.0, "stone", wall_col)
	k.lens_block(Vector3(8.4, y + 1.5, -56.0), Vector3(0.5, 3.0, 4.6), "fake", "stone", wall_col)
	k.chest(10.6, -56.0, -PI / 2.0, "rupee_red", false, D + ":chest_lens", "", y)
	k.locked_door(0.0, -68.0, 0.0, D + ":boss_door", true, y)


func _boss(k) -> void:
	var y := room_y("boss")
	var rb: Rect2 = rooms.boss.r
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	_freezing(k, POOL, y, POOL_Y)
	for p in [Vector2(rb.position.x + 1.5, rb.position.y + 1.5), Vector2(rb.end.x - 1.5, rb.position.y + 1.5),
			Vector2(rb.position.x + 1.5, rb.end.y - 1.5), Vector2(rb.end.x - 1.5, rb.end.y - 1.5)]:
		_torch(k, p.x, p.y, y)
	_ice_spires(k, [Vector2(-11, -97), Vector2(11, -97), Vector2(-11, -75), Vector2(11, -75)], y)
	_icicles(k, rb, y + 8.9, 30)
	var clear := D + ":boss_clear"
	k.heart_container(0.0, -76.0, clear, D + ":heart_container", y)
	k.blue_warp(6.0, -76.5, clear, "snow", "warp_frostpeak_hollow", y)
	# What the Order left behind: a letter on a camp stool (once the serpent is beaten).
	var stool = k._tmp(false)
	stool.box(Vector3(-6.0, y + 0.3, -76.0), Vector3(0.7, 0.6, 0.7), Color.html("5a4a3a"))
	stool.box(Vector3(-6.0, y + 0.61, -76.0), Vector3(0.36, 0.01, 0.26), Color.html("e8dcc0"))
	k.merge(stool, "char")
	var letter: Node3D = k.examine(Vector3(-6.0, y, -76.0), 0.0, [], "res://scripts/npc/order_letter_lines.gd", "hollow_letter", 1.6)
	letter.set("front_only", false)
	letter.set("show_flag", clear)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(0)
	var f2 := fy(2)
	# (The entry is left quiet: nothing pounces the moment he walks in.)
	k.enemy("ice_keese", -8.0, 8.0, 0.0, {"room": "cavern"}, 5.0)
	k.enemy("frost_stalfos", -6.0, 4.0, PI, {"room": "cavern"})
	k.enemy("ice_keese", 6.0, 6.0, 0.0, {"room": "cavern"}, 6.0)
	k.enemy("tektite_blue", -8.0, -6.0, 0.0, {"room": "cavern"})
	k.enemy("frost_stalfos", -30.0, 4.0, PI / 2.0, {"room": "stakes"})
	k.enemy("ice_keese", -30.0, -4.0, 0.0, {"room": "stakes"}, 4.0)
	k.enemy("freezard", 30.0, -6.0, PI / 2.0, {"room": "icefall"})
	k.enemy("freezard", 30.0, 6.0, PI / 2.0, {"room": "icefall"})
	k.enemy("ice_keese", 25.0, 0.0, 0.0, {"room": "icefall"}, 4.0)
	k.enemy("ice_keese", 34.0, 0.0, 0.0, {"room": "icefall"}, 4.5)
	k.enemy("frost_stalfos", 24.0, 4.0, PI / 2.0, {"room": "icefall"})
	k.enemy("rimeguard", 26.0, 0.0, -PI / 2.0, {"room": "knight"}, b1)
	k.enemy("ice_keese", 6.0, -6.0, 0.0, {"room": "cistern"}, b1 + 4.0)
	k.enemy("tektite_blue", 8.0, 5.0, 0.0, {"room": "cistern"}, b1)
	k.enemy("ice_keese", 0.0, -32.0, 0.0, {"room": "stair"}, 4.0)
	k.enemy("frost_stalfos", -6.0, -56.0, 0.0, {"room": "gallery"}, f2)
	k.enemy("frost_stalfos", 6.0, -56.0, 0.0, {"room": "gallery"}, f2)
	k.enemy("freezard", 0.0, -63.0, 0.0, {"room": "gallery"}, f2)
	k.enemy("sleetcoil", POOL.get_center().x, POOL.get_center().y, 0.0, {"room": "boss", "arena_radius": 5.0, "rim_y": f2}, POOL_Y)
