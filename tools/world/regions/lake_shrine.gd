extends "res://tools/world/region.gd"
## The Lake Shrine, the first dungeon: a sunken temple under the island in
## Mirror Lake, built in blue-green stone carved with waves, hung with coral,
## loud with falling water. It is themed on water but nothing here needs
## swimming. Its treasure is the Boomerang.
##
## Rooms (north is -Z; floors at 0 unless noted):
##   r0 Entry Hall      the stairs down from the island; pots, bats; a wall
##                      of brittle coral seals the north-west corner: only a
##                      thrown pot breaks it, and a chest is behind it
##   r1 Bell Hall       the hub: a sunken pool under the great bell, the boss
##                      door up on the north gallery (y 4) between two falls;
##                      a floor switch on a pedestal too tall to climb: throw
##                      a pot onto it and a chest appears
##   r2 Coral Hall      west: two Stalfos behind shutters -> Small Key 1
##   r3 Sunken Bridge   east (locked, key 1): a pit splits the room; shoot the
##                      crystal across it to raise the bridge; the Map
##   r4 Knight's Hall   beyond: the Tide Knight behind shutters -> Boomerang
##   r5 Gallery of Falls north: a deep pit with a key on a pillar in its
##                      middle -> fetch Small Key 2 with the boomerang;
##                      Shell Blades; the Compass
##   r6 Hall of the Key west (locked, key 2): a Stalfos and bats guard the
##                      Boss Key; a floor switch lifts the bars back to r3
##   r7 Abyssal Chamber behind the boss door (y 4): Carapax, the shrine's
##                      master; the heart container and the blue warp home

const D := "lake_shrine"
## [rect, floor y, height]
const ROOMS := {
	"r0": [Rect2(-7, 19, 14, 18), 0.0, 7.0],
	"r1": [Rect2(-15, -15, 30, 30), 0.0, 14.0],
	"r2": [Rect2(-41, -11, 22, 22), 0.0, 8.0],
	"r3": [Rect2(19, -11, 28, 22), 0.0, 9.0],
	"r4": [Rect2(51, -14, 28, 28), 0.0, 10.0],
	"r5": [Rect2(51, -46, 28, 28), 0.0, 10.0],
	"r6": [Rect2(19, -43, 28, 28), 0.0, 9.0],
	"r7": [Rect2(-14, -47, 28, 28), 4.0, 15.0],
}
## [rect, floor y, along x]
const CORRIDORS := [
	[Rect2(-2, 15, 4, 4), 0.0, false],
	[Rect2(-19, -2, 4, 4), 0.0, true],
	[Rect2(15, -2, 4, 4), 0.0, true],
	[Rect2(47, -2, 4, 4), 0.0, true],
	[Rect2(63, -18, 4, 4), 0.0, false],
	[Rect2(47, -31, 4, 4), 0.0, true],
	[Rect2(22, -15, 4, 4), 0.0, false],
	[Rect2(-2, -19, 4, 4), 4.0, false],
]
const DOORS := {
	"r0": [{"side": "n", "at": 0.0}],
	"r1": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 4.0}],
	"r2": [{"side": "e", "at": 0.0}],
	"r3": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 24.0}],
	"r4": [{"side": "w", "at": 0.0}, {"side": "n", "at": 65.0}],
	"r5": [{"side": "s", "at": 65.0}, {"side": "w", "at": -29.0}],
	"r6": [{"side": "e", "at": -29.0}, {"side": "s", "at": 24.0}],
	"r7": [{"side": "s", "at": 0.0}],
}
const PITS := [Rect2(29, -12, 8, 24), Rect2(56, -41, 18, 18)]
const POOLS := [Rect2(-41, -4, 6, 8), Rect2(31, -30, 8, 6)]
const HUB_POOL := Vector2(0, 6)
const HUB_POOL_R := 4.5
const PIT_Y := -8.0
const POOL_Y := -0.6
const WATER := -0.12
const ISLAND := Vector2(65, -32)
## The Bell Hall's switch pedestal, and the height of its top.
const PEDESTAL := Vector2(9.5, 3.0)
const PEDESTAL_Y := 3.4


func setup() -> void:
	id = "lake_shrine"
	interior = true
	seed_value = 151
	x_min = -45.0
	x_max = 83.0
	z_min = -50.0
	z_max = 40.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	water = []
	for p: Rect2 in PITS:
		water.append({"rect": p, "y": -3.5, "col": Color(0.08, 0.2, 0.3, 0.92)})
	for p: Rect2 in POOLS:
		water.append({"rect": p, "y": WATER, "col": Color(0.25, 0.55, 0.65, 0.7)})
	water.append({"rect": Rect2(HUB_POOL.x - HUB_POOL_R, HUB_POOL.y - HUB_POOL_R, HUB_POOL_R * 2.0, HUB_POOL_R * 2.0), "y": WATER, "col": Color(0.25, 0.55, 0.7, 0.7)})
	mood = {
		"sky_top": Color.html("0c1a20"), "sky_mid": Color.html("0c1a20"), "sky_horizon": Color.html("0c1a20"),
		"cloud": Color.html("0c1a20"), "cloud_amount": 0.0,
		"fog": Color.html("0a161c"), "fog_begin": 16.0, "fog_end": 62.0,
		"ambient": Color.html("4a6c7a"), "sun": Color.html("9cc4d4"), "sun_rot": Vector3(-68, 25, 0),
		"sun_energy": 0.55, "fill": Color.html("2e5866"), "fill_energy": 0.5,
		"horizon": Color.html("0c1a20"), "hill_height": 0.0,
	}


func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	for pit: Rect2 in PITS:
		if pit.has_point(p):
			return PIT_Y
	for pool: Rect2 in POOLS:
		if pool.has_point(p):
			return POOL_Y
	if p.distance_to(HUB_POOL) < HUB_POOL_R:
		return POOL_Y
	return 0.0


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if h < -2.0:
		return pick(r, ["0e1a24", "122230"])
	if h < -0.3:
		return pick(r, ["2a5a66", "326670"])
	var p := Vector2(x, z)
	if absf(x) < 15.0 and absf(z) < 15.0:
		# The hub's floor: rings of blue and white mosaic rippling out from the pool.
		var d := p.distance_to(HUB_POOL) + sin(atan2(z - HUB_POOL.y, x - HUB_POOL.x) * 6.0) * 0.35
		var ring := int(d / 1.5) % 3
		var c: Color = [Color.html("3e6e8a"), Color.html("c8d8d4"), Color.html("4a86a0")][ring]
		return c.darkened(r.randf_range(0.0, 0.08))
	# Square flagstones with dark grout; a band of wave tiles along the walls.
	var gx := fposmod(x, 2.0)
	var gz := fposmod(z, 2.0)
	if gx < 0.12 or gz < 0.12:
		return Color.html("2e4248")
	var tile := (int(floor(x / 2.0)) + int(floor(z / 2.0))) % 2
	return Color.html("58787e" if tile == 0 else "628490").darkened(r.randf_range(0.0, 0.1))


func surface_at(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "stone"


## The map shows the rooms and passages, not the solid rock between them.
func map_walkable(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	for pit: Rect2 in PITS:
		if pit.has_point(p):
			return false
	for key: String in ROOMS:
		if (ROOMS[key][0] as Rect2).has_point(p):
			return true
	for c: Array in CORRIDORS:
		if (c[0] as Rect2).has_point(p):
			return true
	return false


func build(k) -> void:
	# Raised floors: the hub's north gallery, the passage to the boss and his chamber.
	k.platform(0, -11, Vector2(30, 8), 4.0, "shrine", Color(0.8, 0.92, 0.95))
	# (It stops where the boss chamber's floor begins: overlapping, they z-fought.)
	k.platform(0, -16.6, Vector2(4, 3.2), 4.0, "shrine", Color(0.8, 0.92, 0.95))
	var r7: Rect2 = ROOMS.r7[0]
	k.platform(r7.get_center().x, r7.get_center().y, r7.size + Vector2(1.6, 1.6), 4.0, "shrine", Color(0.72, 0.85, 0.9))
	k.stairs(0, -1, 0.0, 6.0, 6.0, 4.0, "shrine")
	for key: String in ROOMS:
		var room: Array = ROOMS[key]
		k.dungeon_room(room[0], room[1], room[2], DOORS[key], Color(1, 1, 1))
		k.room_zone(key, room[0], room[1], room[2])
	for c: Array in CORRIDORS:
		k.dungeon_corridor(c[0], c[1], 4.0, c[2])
	# The way out: the door up to the island, and where the hero arrives.
	k.door_link(Vector3(0, 0, 36.98), 0.0, 1.8, 2.8, "lake", "from_lake_shrine")
	k.entrance("from_lake", 0.0, 34.0, 0.0)
	_entry_hall(k)
	_bell_hall(k)
	_coral_hall(k)
	_bridge_room(k)
	_knight_hall(k)
	_gallery(k)
	_key_room(k)
	_boss_chamber(k)


# --- Decoration -----------------------------------------------------------------

func _torch(k, x: float, z: float, y := 0.0) -> void:
	k.brazier(x, z, true, y)


## A cluster of coral branches.
func _coral(k, x: float, z: float, s := 1.0, y := 0.0) -> void:
	var c = k._tmp()
	var cols := [Color(1, 0.8, 0.8), Color(1, 0.65, 0.55), Color(0.95, 0.9, 0.7)]
	for i in 5:
		var a: float = TAU * i / 5.0 + k.rng.randf() * 0.5
		var base := Vector3(x + cos(a) * 0.25 * s, y, z + sin(a) * 0.25 * s)
		var top := base + Vector3(cos(a) * 0.35, k.rng.randf_range(0.7, 1.3), sin(a) * 0.35) * s
		c.prism(base, 0.09 * s, top, 0.04 * s, 5, cols[i % 3])
		c.icosa(top, Vector3(0.1, 0.1, 0.1) * s, 0.2, cols[(i + 1) % 3])
	k.merge(c, "coral")


## Swaying strands of sea grass.
func _weed(k, x: float, z: float, y := 0.0) -> void:
	var w = k._tmp(false)
	for i in 5:
		var p := Vector3(x + k.rng.randf_range(-0.5, 0.5), y - 0.05, z + k.rng.randf_range(-0.5, 0.5))
		var t := p + Vector3(k.rng.randf_range(-0.3, 0.3), k.rng.randf_range(0.8, 1.6), k.rng.randf_range(-0.3, 0.3))
		w.face_dir([p - Vector3(0.06, 0, 0), p + Vector3(0.06, 0, 0), t], Color.html("2e7a6a"), Vector3(0, 0, 1))
		w.face_dir([p - Vector3(0.06, 0, 0), p + Vector3(0.06, 0, 0), t], Color.html("246458"), Vector3(0, 0, -1))
	k.merge(w, "char")


## A column ringed with shell carvings.
func _column(k, x: float, z: float, hh: float, y := 0.0) -> void:
	k.pillar(x, z, hh, 0.55, false, "shrine", y)
	var g = k._tmp(false)
	for yy in [1.2, hh - 1.0]:
		g.prism(Vector3(x, y + yy, z), 0.62, Vector3(x, y + yy + 0.2, z), 0.62, 8, Color.html("d8c8a0"))
	k.merge(g, "char")


## Carved fish leaping along a wall (relief), facing `n` (out of the wall).
func _fish_relief(k, p: Vector3, n: Vector3) -> void:
	var f = k._tmp(false)
	var side := Vector3(-n.z, 0, n.x)
	for i in 3:
		var c := p + side * (i - 1) * 1.4 + Vector3(0, sin(i * 1.7) * 0.3, 0)
		f.box(c + n * 0.05, Vector3(0.7, 0.3, 0.7) * (side.abs() + Vector3(0, 1, 0)) + n.abs() * 0.08, Color.html("8ab8bc"))
		# The tail sits a little further back than the body, so their faces never share a plane.
		f.box(c + side * 0.45 + n * 0.035, (Vector3(0.25, 0.4, 0.25) * (side.abs() + Vector3(0, 1, 0))) + n.abs() * 0.06, Color.html("8ab8bc"))
	k.merge(f, "char")


## A glowing sea crystal growing out of the floor (a little light in the gloom).
func _crystals(k, x: float, z: float, y := 0.0) -> void:
	var c = k._tmp(false)
	for i in 4:
		var a: float = TAU * i / 4.0 + k.rng.randf()
		var base := Vector3(x + cos(a) * 0.3, y, z + sin(a) * 0.3)
		c.prism(base, 0.12, base + Vector3(cos(a) * 0.2, k.rng.randf_range(0.5, 1.1), sin(a) * 0.2), 0.0, 5, Color.html("6ad8e8"))
	k.merge(c, "glow")


# --- Rooms ----------------------------------------------------------------------

func _entry_hall(k) -> void:
	for z in [24.0, 32.0]:
		for sx in [-1.0, 1.0]:
			_column(k, sx * 5.0, z, 7.0)
	_torch(k, -2.5, 21.0)
	_torch(k, 2.5, 21.0)
	_fish_relief(k, Vector3(-6.95, 3.5, 28), Vector3(1, 0, 0))
	_fish_relief(k, Vector3(6.95, 3.5, 28), Vector3(-1, 0, 0))
	_coral(k, 5.5, 35.5, 1.0)
	# A wall of brittle coral has grown across the corner by the way in, taller
	# than any throw can clear, with a chest behind it; the pots by the door
	# break it when thrown.
	k.chest(-6.3, 36.3, -PI / 4.0, "rupee_red", false, D + ":chest_crust")
	k.brittle_crust(-4.8, 34.8, -PI / 4.0, D + ":crust_r0", Vector3(6.6, 5.0, 1.0))
	_weed(k, -6.0, 20.5)
	_weed(k, 6.0, 20.5)
	k.pot(-5.8, 22.0, "heart", true)
	k.pot(5.8, 22.0, "", true)


func _bell_hall(k) -> void:
	# The great bell, hanging over the pool on a heavy chain. It swings from
	# the chain's foot (scripts/dungeon/temple_bell.gd), clapper and all.
	var bc := Vector3(HUB_POOL.x, 0, HUB_POOL.y)
	var bell = k._tmp()
	bell.prism(Vector3(0, -3.4, 0), 2.1, Vector3(0, -2.4, 0), 1.7, 12, Color.html("c89a50"))
	bell.prism(Vector3(0, -2.4, 0), 1.7, Vector3(0, -0.6, 0), 1.1, 12, Color.html("b88a44"))
	bell.prism(Vector3(0, -0.6, 0), 1.1, Vector3(0, -0.1, 0), 0.4, 12, Color.html("a87a3a"))
	bell.prism(Vector3(0, -3.6, 0), 2.2, Vector3(0, -3.3, 0), 2.2, 12, Color.html("4a8a7a"))
	bell.prism(Vector3(0, -4.4, 0), 0.12, Vector3(0, -3.4, 0), 0.12, 6, Color.html("6a5a3a"))
	bell.icosa(Vector3(0, -4.5, 0), Vector3(0.3, 0.3, 0.3), 0.0, Color.html("6a5a3a"))
	k.scripted_mesh("res://scripts/dungeon/temple_bell.gd", "GreatBell", bc + Vector3(0, 12.0, 0), bell, "char", {"flag": D + ":bell"})
	var chain = k._tmp(false)
	for i in 6:
		chain.box(bc + Vector3(0, 12.1 + i * 0.32, 0), Vector3(0.12, 0.26, 0.12) if i % 2 == 0 else Vector3(0.06, 0.26, 0.22), Color.html("3a3a44"))
	k.merge(chain, "char")
	# The pool's rim, and coral and grass round it.
	var rim = k._tmp()
	for i in 16:
		var a0 := TAU * i / 16.0
		var a1 := TAU * (i + 1) / 16.0
		var p0 := Vector3(cos(a0), 0, sin(a0)) * (HUB_POOL_R + 0.25) + bc
		var p1 := Vector3(cos(a1), 0, sin(a1)) * (HUB_POOL_R + 0.25) + bc
		# Every other stone stands 2 cm taller, so the overlapping ends of
		# neighbors never share a top plane (they z-fought).
		var rh := 0.24 + 0.02 * (i % 2)
		var mid := (p0 + p1) * 0.5 + Vector3(0, rh * 0.5, 0)
		rim.push(Transform3D(Basis(Vector3.UP, -(a0 + a1) * 0.5 + PI / 2.0), mid))
		rim.box(Vector3.ZERO, Vector3(p0.distance_to(p1) + 0.08, rh, 0.45), Color(0.85, 0.95, 0.95))
		rim.pop()
	k.merge(rim, "stone")
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		if i % 2 == 0:
			_coral(k, HUB_POOL.x + cos(a) * 5.6, HUB_POOL.y + sin(a) * 5.6, 0.9)
		else:
			_weed(k, HUB_POOL.x + cos(a) * 5.6, HUB_POOL.y + sin(a) * 5.6)
	# Columns round the hall, torches at the doors.
	for p in [Vector2(-11, -4), Vector2(11, -4), Vector2(-11, 11), Vector2(11, 11)]:
		_column(k, p.x, p.y, 14.0)
	_torch(k, -2.6, 13.5)
	_torch(k, 2.6, 13.5)
	_torch(k, -13.5, -2.6)
	_torch(k, 13.5, -2.6)
	# Up on the gallery: the boss door between two falls of water into basins.
	for sx in [-1.0, 1.0]:
		k.waterfall(Vector3(sx * 7.0, 12.5, -14.9), 2.6, 8.3, Vector2(0, 1))
		k.water_plane(Rect2(sx * 7.0 - 2.0, -14.8, 4.0, 2.6), 4.1, Color(0.3, 0.6, 0.7, 0.75))
		var lip = k._tmp()
		lip.box(Vector3(sx * 7.0, 4.15, -12.1), Vector3(4.2, 0.3, 0.3), Color(0.85, 0.95, 0.95))
		k.merge(lip, "stone")
	_torch(k, -2.8, -13.5, 4.0)
	_torch(k, 2.8, -13.5, 4.0)
	k.locked_door(0.0, -15.4, 0.0, D + ":boss_door", true, 4.0)
	for p in [Vector2(-13.5, 13.5), Vector2(13.5, 13.5), Vector2(-13.5, 6.0), Vector2(13.5, 6.0)]:
		k.pot(p.x, p.y, "", true)
	# A floor switch on a pedestal too tall to climb (over OoT's 111-unit reach):
	# only a pot thrown up onto it presses it, and a chest appears beside it.
	k.platform(PEDESTAL.x, PEDESTAL.y, Vector2(1.8, 1.8), PEDESTAL_Y, "shrine", Color(0.8, 0.92, 0.95))
	var band = k._tmp(false)
	# A band round the pedestal just under its top (flush with it, it z-fought).
	band.box(Vector3(PEDESTAL.x, PEDESTAL_Y - 0.25, PEDESTAL.y), Vector3(2.0, 0.3, 2.0), Color.html("d8c8a0"))
	k.merge(band, "char")
	k.floor_switch(PEDESTAL.x, PEDESTAL.y, D + ":r1_pedestal", PEDESTAL_Y)
	k.chest(PEDESTAL.x, PEDESTAL.y + 2.6, PI, "rupee_red", false, D + ":chest_pedestal", D + ":r1_pedestal")
	# More pots to throw, out of the way of the hall's middle.
	for p in [Vector2(13.0, -1.0), Vector2(13.0, 0.5)]:
		k.pot(p.x, p.y, "", true)


func _coral_hall(k) -> void:
	k.shutter(-18.6, 0.0, PI / 2.0, "r2")
	k.waterfall(Vector3(-40.9, 6.5, 0.0), 3.0, 6.4, Vector2(1, 0))
	for p in [Vector2(-35, -8), Vector2(-35, 8), Vector2(-25, -8), Vector2(-25, 8)]:
		_column(k, p.x, p.y, 8.0)
	for p in [Vector2(-39, -9.5), Vector2(-39, 9.5), Vector2(-30, -10), Vector2(-21, 9.5)]:
		_coral(k, p.x, p.y, k.rng.randf_range(1.0, 1.5))
	_weed(k, -33, -5)
	_weed(k, -33, 5)
	_torch(k, -20.5, -3.0)
	_torch(k, -20.5, 3.0)
	_fish_relief(k, Vector3(-30, 4.0, -10.95), Vector3(0, 0, 1))
	_fish_relief(k, Vector3(-30, 4.0, 10.95), Vector3(0, 0, -1))
	k.pot(-22.5, -9.5, "", true)
	k.pot(-22.5, 9.5, "arrows_10", true)
	k.chest(-29.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key1", D + ":r2_clear")


func _bridge_room(k) -> void:
	k.locked_door(15.4, 0.0, PI / 2.0, D + ":door_key1")
	k.void_zone(Vector3(33, -5.0, 0), Vector3(8, 2.0, 24), 2)
	# The pit's walls slope over its outer meter (x 28-29 and 36-37), so the
	# bridge spans from rim to rim. (Laid over the flat floor beyond, its top
	# z-fought with it.)
	k.flag_bridge(Rect2(28.0, -1.6, 9.0, 3.2), 0.0, D + ":r3_bridge", 7.0)
	k.crystal_switch(43.5, -6.0, D + ":r3_bridge")
	# Broken stubs of the old bridge on both rims.
	for x in [28.5, 36.5]:
		var stub = k._tmp()
		stub.box(Vector3(x, -1.0, -2.0), Vector3(1.0, 2.0, 0.6), Color(0.7, 0.8, 0.82))
		stub.box(Vector3(x, -1.0, 2.0), Vector3(1.0, 2.0, 0.6), Color(0.7, 0.8, 0.82))
		k.merge(stub, "shrine")
	k.chest(22.0, 7.5, 0.0, "map", false, D + ":chest_map")
	_torch(k, 20.5, -3.0)
	_torch(k, 45.5, 3.0)
	_crystals(k, 44.5, 9.0)
	_crystals(k, 21.0, -9.5)
	_coral(k, 26.0, 9.5, 1.2)
	_weed(k, 40.0, -9.5)
	_weed(k, 40.0, 9.5)
	k.pot(26.5, -9.5, "arrows_10", true)
	k.pot(27.5, -9.6, "", true)


func _knight_hall(k) -> void:
	k.shutter(50.6, 0.0, PI / 2.0, "r4")
	k.shutter(65.0, -14.4, 0.0, "r4")
	for p in [Vector2(57, -8), Vector2(73, -8), Vector2(57, 8), Vector2(73, 8)]:
		_column(k, p.x, p.y, 10.0)
	for p in [Vector2(53, -12), Vector2(77, -12), Vector2(53, 12), Vector2(77, 12)]:
		_torch(k, p.x, p.y)
	# Banners of the shrine's guard.
	for x in [60.0, 70.0]:
		k.banner(x, 8.0, 13.7, PI, Color.html("2a6a8a"), 3.5)
	k.chest(65.0, -2.0, PI / 2.0, "boomerang", true, D + ":chest_boomerang", D + ":r4_clear")


func _gallery(k) -> void:
	k.void_zone(Vector3(ISLAND.x, -5.0, ISLAND.y), Vector3(18, 2.0, 18), 2)
	# The pillar in the middle of the pit, a small key on top (fetch it with the boomerang).
	k.platform(ISLAND.x, ISLAND.y, Vector2(3.0, 3.0), 0.0, "shrine", Color(0.8, 0.92, 0.95))
	var cap = k._tmp()
	cap.box(Vector3(ISLAND.x, 0.1, ISLAND.y), Vector3(3.4, 0.2, 3.4), Color(0.85, 0.95, 0.95))
	k.merge(cap, "stone")
	# Falls from the north wall into the pit.
	for x in [60.0, 70.0]:
		k.waterfall(Vector3(x, 9.5, -45.9), 3.5, 13.0, Vector2(0, 1))
	k.locked_door(50.6, -29.0, PI / 2.0, D + ":door_key2")
	k.chest(77.0, -43.5, PI / 2.0, "compass", false, D + ":chest_compass")
	for p in [Vector2(53, -20), Vector2(77, -20), Vector2(53, -44)]:
		_torch(k, p.x, p.y)
	_coral(k, 76.5, -26.0, 1.3)
	_coral(k, 53.5, -38.0, 1.1)
	_crystals(k, 77.5, -32.0)
	k.pot(55.0, -19.6, "", true)
	k.pot(75.0, -19.6, "heart", true)


func _key_room(k) -> void:
	k.flag_bars(24.0, -14.6, 0.0, D + ":r6_switch")
	k.floor_switch(24.0, -19.5, D + ":r6_switch")
	k.chest(38.0, -36.0, -PI / 2.0, "boss_key", true, D + ":chest_boss_key", D + ":r6_clear")
	for p in [Vector2(28, -24), Vector2(28, -36), Vector2(42, -24)]:
		_column(k, p.x, p.y, 9.0)
	_torch(k, 45.5, -26.0)
	_torch(k, 45.5, -32.0)
	_torch(k, 20.5, -41.0)
	_coral(k, 21.0, -26.0, 1.2)
	_weed(k, 33.0, -33.5)
	_crystals(k, 44.5, -41.0)
	k.pot(45.0, -17.0, "", true)
	k.pot(21.0, -17.0, "arrows_10", true)


func _boss_chamber(k) -> void:
	var y := 4.0
	k.shutter(0.0, -18.6, 0.0, "r7", y)
	var r7: Rect2 = ROOMS.r7[0]
	var c := r7.get_center()
	# A ring of broken columns and channels of water round the arena.
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var p := c + Vector2(cos(a), sin(a)) * 11.5
		k.pillar(p.x, p.y, 6.0 + (i % 3) * 2.0, 0.7, i % 3 == 1, "shrine", y)
	for side in [-1.0, 1.0]:
		k.water_plane(Rect2(c.x + side * 12.6 - 0.7, r7.position.y + 2.0, 1.4, r7.size.y - 4.0), y + 0.08, Color(0.25, 0.55, 0.7, 0.75))
		k.waterfall(Vector3(c.x + side * 13.9, y + 12.0, c.y), 4.0, 12.0, Vector2(-side, 0))
	for p in [Vector2(-12.5, -45.5), Vector2(12.5, -45.5), Vector2(-12.5, -20.5), Vector2(12.5, -20.5)]:
		_torch(k, p.x, p.y, y)
	_crystals(k, -6.0, -45.5, y)
	_crystals(k, 6.0, -45.5, y)
	k.heart_container(c.x, c.y - 4.0, D + ":r7_clear", D + ":heart_container", y)
	k.blue_warp(c.x, c.y + 5.0, D + ":r7_clear", "lake", "warp_lake_shrine", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	k.enemy("keese", -3.0, 27.0, 0.0, {"room": "r0"}, 3.5)
	k.enemy("keese", 3.5, 30.0, 0.0, {"room": "r0"}, 3.5)
	k.enemy("keese", 9.0, 8.0, 0.0, {"room": "r1"}, 5.0)
	k.enemy("stalfos", -33.0, -4.0, PI / 2.0, {"room": "r2"})
	k.enemy("stalfos", -33.0, 4.0, PI / 2.0, {"room": "r2"})
	k.enemy("snapper_coral", 25.0, -6.0, 0.0, {"room": "r3"})
	k.enemy("snapper_coral", 24.0, 4.0, 0.0, {"room": "r3"})
	k.enemy("keese", 41.0, 4.0, 0.0, {"room": "r3"}, 4.0)
	k.enemy("tide_knight", 71.0, 0.0, PI / 2.0, {"room": "r4"})
	k.enemy("shellblade", 54.0, -24.0, 0.0, {"room": "r5"})
	k.enemy("shellblade", 76.0, -24.0, 0.0, {"room": "r5"})
	k.enemy("stalfos", 33.0, -30.0, -PI / 2.0, {"room": "r6"})
	k.enemy("keese", 30.0, -38.0, 0.0, {"room": "r6"}, 4.0)
	k.enemy("keese", 40.0, -22.0, 0.0, {"room": "r6"}, 4.0)
	var r7: Rect2 = ROOMS.r7[0]
	k.enemy("carapax", r7.get_center().x, r7.get_center().y - 3.0, 0.0, {"room": "r7"}, 4.1)
	k.collectible("small_key", ISLAND.x, ISLAND.y, 0.25)
