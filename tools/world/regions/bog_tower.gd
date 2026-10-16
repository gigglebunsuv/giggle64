extends "res://tools/world/tower_region.gd"
## The Bog Tower in the West Marshlands: a drowned watchtower of mossy green
## stone, split by the roots of the bog, its cellar flooded and its upper
## floors sinking into sludge. An item dungeon like the Lake Shrine (no bun
## piece): its treasure is the Bloom Rod, its master Gullagog, the Mire Toad.
##
## Storeys (north is -Z):
##   B1 (y -8)  cellar    under the sluice, flooded ankle deep: rats and
##                        bones behind shutters -> Small Key 2; the Compass;
##                        a cracked wall hides a Piece of Heart (bombs)
##              knight    under the Root Hall (Small Key 2): the Mire Knight
##                        behind shutters -> the Bloom Rod
##   1F (y 0)   entry     in from the marsh
##              hub       the Root Hall, two storeys tall round a great root:
##                        the Map; a ledge along the north wall too tall to
##                        climb (grow a bloom-pod to step up), a ladder from
##                        it to the gallery and the way to 2F
##              snare     west: snappers and a bog stalfos -> Small Key 1
##              sluice    east (Small Key 1): stepping stones over sinking
##                        sludge to the hole down to the cellar
##   2F (y 8)   pond      a pond of deadly sludge: lily pads across the gaps
##                        between its islets -> Small Key 3
##              pillars   west (Small Key 3): switches on two pillars too tall
##                        to climb (pods weigh them down) lift the bars north;
##                        the Boss Key on an island in a pit (plant a pod on
##                        it and hookshot across)
##              stairs    a stairwell up to 3F and the boss door
##   3F (y 16)  boss      the bog on the roof, open to the sky: Gullagog;
##                        then the heart container and the blue warp

const MK := preload("res://tools/mesh_kit.gd")
const D := "bog_tower"
const MOSS := Color(0.62, 0.78, 0.6)
## The Root Hall's north ledge (too tall to climb) and the gallery over it.
const LEDGE_TOP := 3.0
const LEDGE_Z := Vector2(-14, -8)
const GALLERY_Z := Vector2(-14, -10)
## The pond's sludge: its surface, and the islets and landings standing out of it.
const SLUDGE_Y := 8.3
const ISLET_TOP := 8.45
const POND_PADS := [
	[Rect2(-12, -23, 24, 3)], [Rect2(-1.5, -28, 3, 3)], [Rect2(-1.5, -33, 3, 3)],
	[Rect2(-12, -36, 8.5, 6)], [Rect2(-1.5, -38, 3, 3)], [Rect2(-12, -46, 24, 6)],
]
## The sluice's sinking sludge and its stepping stones.
const SLUICE_SLUDGE := Rect2(21, -11, 13, 22)
const SLUICE_STONES := [Vector2(22.6, 0.0), Vector2(25.6, 1.4), Vector2(28.6, -0.4), Vector2(31.6, 1.0), Vector2(31.6, -2.2), Vector2(32.6, -5.4)]
## The pit in the pillar room and the island in it.
const PIT := Rect2(-42, -32, 9, 12)
const ISLAND := Rect2(-40.5, -28, 4, 4)
## Mud pools in the corners of the roof.
const ROOF_POOLS := [Rect2(-43, -99, 6, 6), Rect2(-23, -99, 6, 6), Rect2(-43, -79, 6, 6), Rect2(-23, -79, 6, 6)]

## The roof (the boss room) is open to the sky.
var open_sky := true


func setup() -> void:
	id = "bog_tower"
	interior = true
	seed_value = 191
	x_min = -48.0
	x_max = 44.0
	z_min = -104.0
	z_max = 36.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0]]
	entry_floor = 1
	wall_col = Color(0.78, 0.9, 0.76)
	ceil_col = Color(0.32, 0.4, 0.3)
	slab_col = Color(0.75, 0.86, 0.72)
	var wood := Color(0.78, 0.7, 0.55)
	rooms = {
		"cellar": {"f": 0, "r": Rect2(18, -11, 22, 22), "h": 6.5, "doors": [{"side": "w", "at": 0.0}], "col": Color(0.6, 0.72, 0.6)},
		"knight": {"f": 0, "r": Rect2(-12, -12, 24, 24), "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.62, 0.74, 0.62)},
		"entry": {"f": 1, "r": Rect2(-6, 18, 12, 14), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"hub": {"f": 1, "r": Rect2(-14, -14, 28, 28), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		"snare": {"f": 1, "r": Rect2(-38, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"sluice": {"f": 1, "r": Rect2(18, -11, 22, 22), "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"pond": {"f": 2, "r": Rect2(-12, -46, 24, 26), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": -33.0}], "floor_col": Color(0.4, 0.46, 0.32)},
		"pillars": {"f": 2, "r": Rect2(-42, -46, 24, 26), "h": 6.5, "doors": [{"side": "e", "at": -33.0}, {"side": "n", "at": -30.0}], "floor_col": wood, "floor_mat": "wood"},
		"stairs": {"f": 2, "r": Rect2(-37, -66, 14, 16), "h": 14.5, "doors": [{"side": "s", "at": -30.0}, {"side": "n", "at": -30.0, "y0": 8.0}]},
		"boss": {"f": 3, "r": Rect2(-44, -100, 28, 28), "h": 6.0, "doors": [{"side": "s", "at": -30.0}], "ceiling": false},
	}
	corridors = [
		{"f": 0, "r": Rect2(12, -2, 6, 4), "x": true},
		{"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-18, -2, 4, 4), "x": true},
		{"f": 1, "r": Rect2(14, -2, 4, 4), "x": true},
		{"f": 2, "r": Rect2(-2, -20, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-18, -35, 6, 4), "x": true},
		{"f": 2, "r": Rect2(-32, -50, 4, 4), "x": false},
		{"f": 3, "r": Rect2(-32, -72, 4, 6), "x": false},
	]
	holes = [
		# The hole in the sluice's floor where the ladder climbs from the cellar.
		{"f": 1, "r": ladder_hole(38.0, -6.0, Vector2(-1, 0))},
		# The pit round the Boss Key's island.
		{"f": 2, "r": PIT},
	]
	water = [
		{"rect": Rect2(18, -11, 22, 22), "y": -7.6, "col": Color(0.3, 0.4, 0.28, 0.82)},
	]
	mood = {
		# Green gloom inside; over the roof a low, heavy marsh sky.
		"sky_top": Color.html("3a4050"), "sky_mid": Color.html("5a6050"), "sky_horizon": Color.html("9a9a78"),
		"cloud": Color.html("7e7c68"), "cloud_amount": 0.8,
		"fog": Color.html("1a2418"), "fog_begin": 14.0, "fog_end": 62.0,
		"ambient": Color.html("4e5c48"), "sun": Color.html("c8d0a8"), "sun_rot": Vector3(-55, -50, 0),
		"sun_energy": 0.7, "fill": Color.html("3a4a5a"), "fill_energy": 0.4,
		"horizon": Color.html("4a5040"), "hill_height": 0.0,
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


## Mossy flagstones, sludge in the sluice and the pond, planks in the pillar
## room, and black mud on the roof.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if not _inside(x, z, f):
		return pick(r, ["10140e", "141a10"])
	if f == 1 and SLUICE_SLUDGE.has_point(p):
		return pick(r, ["3a4224", "424a2a", "363e20"]).darkened(r.randf_range(0.0, 0.1))
	if f == 2 and (rooms.pond.r as Rect2).has_point(p):
		return pick(r, ["2e3a1e", "344222", "28341a"])
	if f == 2 and (rooms.pillars.r as Rect2).has_point(p):
		var plank := int(floor(z / 0.6))
		var c := Color.html(["8a7a58", "96845e", "7e6e50"][posmod(plank, 3)])
		if fposmod(z, 0.6) < 0.05:
			c = Color.html("3a3020")
		return c.darkened(r.randf_range(0.0, 0.1))
	if f == 3:
		for pool: Rect2 in ROOF_POOLS:
			if pool.has_point(p):
				return pick(r, ["2a2e18", "32361c"])
		return pick(r, ["4a4026", "54482c", "40381e"]).darkened(r.randf_range(0.0, 0.08))
	var seam := fposmod(x, 1.6) < 0.1 or fposmod(z + (0.8 if int(floor(x / 1.6)) % 2 == 0 else 0.0), 1.6) < 0.1
	if seam:
		return Color.html("2a3226")
	var base := Color.html(["6a7a62", "72826a", "64745c"][r.randi() % 3])
	# Moss creeping over the stones.
	if noise.get_noise_2d(x * 4.0, z * 4.0) > 0.15:
		base = base.lerp(Color.html("4a7a34"), 0.5)
	return base.darkened(r.randf_range(0.0, 0.12) + (0.15 if f == 0 else 0.0))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 31.98), 0.0, 1.8, 2.8, "marsh", "from_bog_tower")
	k.entrance("from_marsh", 0.0, 29.0, 0.0)
	_cellar(k)
	_knight(k)
	_entry(k)
	_hub(k)
	_snare(k)
	_sluice(k)
	_pond(k)
	_pillars(k)
	_stairwell(k)
	_roof(k)


# --- Decoration -----------------------------------------------------------------

## A thick root snaking from `a` to `b` through `mid`.
func _root(k, a: Vector3, mid: Vector3, b: Vector3, r := 0.35) -> void:
	var m = k._tmp()
	var pts := [a, a.lerp(mid, 0.5) + Vector3(0, 0.15, 0), mid, mid.lerp(b, 0.5) + Vector3(0, 0.1, 0), b]
	for i in pts.size() - 1:
		var rr := r * (1.0 - float(i) / pts.size() * 0.5)
		m.prism(pts[i], rr, pts[i + 1], rr * 0.85, 6, Color(0.55, 0.42, 0.3))
	k.merge(m, "bark")


func _moss_hang(k, x: float, y: float, z: float, yaw: float, length := 2.0) -> void:
	k.banner(x, y, z, yaw, Color.html("4a6a32"), length)


func _torch(k, x: float, z: float, y := 0.0) -> void:
	k.brazier(x, z, true, y)


func _lamps(k, rid: String, inset := 2.5) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


func _railing(k, a: Vector3, b: Vector3) -> void:
	var rail = k._tmp()
	var n := maxi(2, int(a.distance_to(b) / 2.0) + 1)
	for i in n:
		var p := a.lerp(b, float(i) / (n - 1))
		rail.box(p + Vector3(0, 0.5, 0), Vector3(0.12, 1.0, 0.12), Color(0.6, 0.5, 0.38))
	var mid := (a + b) * 0.5 + Vector3(0, 1.0, 0)
	var along := b - a
	rail.box(mid, Vector3(maxf(absf(along.x), 0.14), 0.12, maxf(absf(along.z), 0.14)), Color(0.6, 0.5, 0.38))
	k.merge(rail, "wood")
	k.col_box((a + b) * 0.5 + Vector3(0, 0.55, 0), Vector3(maxf(absf(along.x), 0.2), 1.1, maxf(absf(along.z), 0.2))).set_meta("no_climb", true)


## Sludge that swallows whoever steps in (a void zone just under its surface),
## drawn as a dark green skin over `r` on the floor at `floor_y`. Bloom Rod
## seeds open into lily pads on its surface (the "sludge" marker).
func _sludge_pit(k, r: Rect2, floor_y: float, surface_y: float) -> void:
	var m = k._tmp(false)
	m.shade_jitter = 0.0
	var x0 := r.position.x
	var z0 := r.position.y
	var x1 := r.end.x
	var z1 := r.end.y
	m.face_dir([Vector3(x0, surface_y, z0), Vector3(x1, surface_y, z0), Vector3(x1, surface_y, z1), Vector3(x0, surface_y, z1)], Color.html("2c3a1c"), Vector3.UP)
	# Bubbles of scum on its skin.
	var rng: RandomNumberGenerator = k.rng
	for i in int(r.get_area() / 6.0):
		var p := Vector3(rng.randf_range(x0 + 0.4, x1 - 0.4), surface_y + 0.01, rng.randf_range(z0 + 0.4, z1 - 0.4))
		m.prism(p, rng.randf_range(0.08, 0.22), p + Vector3(0, 0.02, 0), 0.05, 6, Color.html("4a5a2a"))
	k.merge(m, "char")
	var mark := Marker3D.new()
	mark.name = "Sludge%d" % k._misc.get_child_count()
	mark.add_to_group("sludge", true)
	mark.set_meta("rect", r)
	mark.set_meta("y", surface_y)
	k._misc.add_child(mark)
	var vz_top := surface_y - 0.1
	k.void_zone(Vector3(r.get_center().x, (floor_y + vz_top) * 0.5 - 0.5, r.get_center().y), Vector3(r.size.x, vz_top - floor_y + 1.0, r.size.y), 2)


# --- B1 -------------------------------------------------------------------------

func _cellar(k) -> void:
	var y := room_y("cellar")
	# The stone pier under the hole in the sluice's floor; the ladder on its face.
	ladder_up(k, 0, 38.0, -6.0, Vector2(-1, 0))
	k.shutter(18.6, 0.0, PI / 2.0, "cellar", y)
	_lamps(k, "cellar")
	for p in [Vector2(23, -6), Vector2(23, 6), Vector2(31, -6)]:
		k.pillar(p.x, p.y, 6.5, 0.5, true, "stone", y)
	_root(k, Vector3(19, y + 5.5, -9), Vector3(26, y + 3.0, -8), Vector3(30, y, -4), 0.4)
	k.chest(29.0, 0.0, PI / 2.0, "small_key", false, D + ":chest_key2", D + ":cellar_clear", y)
	k.chest(38.0, -9.5, PI, "compass", false, D + ":chest_compass", "", y)
	# The nook in the south-east corner, walled off by cracked stone.
	k.block(Vector3(35.2, y + 3.0, 8.5), Vector3(0.5, 6.0, 5.0), 0.0, "stone", wall_col * Color(0.8, 0.85, 0.8))
	k.block(Vector3(38.8, y + 3.0, 8.5), Vector3(0.5, 6.0, 5.0), 0.0, "stone", wall_col * Color(0.8, 0.85, 0.8))
	k.block(Vector3(37.0, y + 5.0, 6.3), Vector3(3.2, 2.0, 0.6), 0.0, "stone", wall_col * Color(0.8, 0.85, 0.8))
	k.bomb_wall(37.0, 6.3, 0.0, D + ":cellar_wall", y)
	k.heart_piece(37.0, 9.2, D + ":heart_piece", y + 0.3)
	for p in [Vector2(20.5, 9.5), Vector2(21.5, 9.5), Vector2(33.5, 9.5)]:
		k.pot(p.x, p.y, "", false, y)


func _knight(k) -> void:
	var y := room_y("knight")
	k.locked_door(16.6, 0.0, PI / 2.0, D + ":door_key2", false, y)
	k.shutter(11.4, 0.0, PI / 2.0, "knight", y)
	_lamps(k, "knight")
	for p in [Vector2(-7, -7), Vector2(7, -7), Vector2(-7, 7), Vector2(7, 7)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	# The great root of the hall above breaks through the ceiling here.
	_root(k, Vector3(-2, y + 6.4, -2), Vector3(-1, y + 3.0, -4), Vector3(-6, y, -9), 0.55)
	_root(k, Vector3(2, y + 6.4, 1), Vector3(4, y + 2.5, 3), Vector3(9, y, 6), 0.45)
	for x in [-4.0, 4.0]:
		_moss_hang(k, x, y + 5.5, -11.0, PI, 3.0)
	k.chest(0.0, -8.0, PI, "bloom_rod", true, D + ":chest_bloom_rod", D + ":knight_clear", y)


# --- 1F --------------------------------------------------------------------------

func _entry(k) -> void:
	for z in [22.0, 28.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.5, z, 6.5, 0.45, z > 25.0, "stone", 0.0)
	_torch(k, -2.6, 19.5)
	_torch(k, 2.6, 19.5)
	_root(k, Vector3(-6, 5.5, 20), Vector3(-4, 2.0, 24), Vector3(-5.5, 0, 29), 0.3)
	k.pot(4.8, 30.5)
	k.pot(4.8, 29.5, "heart")
	k.pot(-4.8, 30.5)


func _hub(k) -> void:
	# The great root, rising from the floor and spreading across the ceiling.
	var g = k._tmp()
	g.prism(Vector3(0, 0, 3), 2.2, Vector3(0.3, 6.0, 3), 1.7, 9, Color(0.55, 0.42, 0.3))
	g.prism(Vector3(0.3, 6.0, 3), 1.7, Vector3(0, 14.5, 2.5), 1.3, 9, Color(0.5, 0.38, 0.28))
	k.merge(g, "bark")
	k.col_cyl(Vector3(0, 0, 3), 2.2, 14.5)
	for a in [0.4, 1.9, 3.3, 4.6]:
		var d := Vector3(cos(a), 0, sin(a))
		_root(k, Vector3(0, 0.4, 3) + d * 1.8, Vector3(0, 0.2, 3) + d * 4.0, Vector3(0, 0.0, 3) + d * 6.5, 0.4)
		_root(k, Vector3(0.2, 13.0, 2.8) + d * 1.2, Vector3(0, 13.8, 2.5) + d * 6.0, Vector3(0, 14.4, 2.5) + d * 12.0, 0.35)
	# The ledge along the north wall, too tall to climb: a bloom-pod is the
	# step up. A pier carries the ladder from it to the gallery.
	k.block(Vector3(0, LEDGE_TOP * 0.5, (LEDGE_Z.x + LEDGE_Z.y) * 0.5), Vector3(28, LEDGE_TOP, LEDGE_Z.y - LEDGE_Z.x), 0.0, "stone", wall_col * Color(0.85, 0.9, 0.85))
	var up := fy(2)
	k.block(Vector3(0, up - 0.25, (GALLERY_Z.x + GALLERY_Z.y) * 0.5), Vector3(28, 0.5, GALLERY_Z.y - GALLERY_Z.x), 0.0, "wood", Color(0.8, 0.72, 0.58))
	k.block(Vector3(0, (LEDGE_TOP + up - 0.5) * 0.5, GALLERY_Z.y - 0.4), Vector3(2.6, up - 0.5 - LEDGE_TOP, 0.8), 0.0, "stone", wall_col * Color(0.8, 0.85, 0.8))
	k.ladder(0.0, GALLERY_Z.y + 0.05, Vector2(0, 1), LEDGE_TOP, up)
	_railing(k, Vector3(-13.8, up, GALLERY_Z.y - 0.1), Vector3(-1.6, up, GALLERY_Z.y - 0.1))
	_railing(k, Vector3(1.6, up, GALLERY_Z.y - 0.1), Vector3(13.8, up, GALLERY_Z.y - 0.1))
	for x in [-10.0, -5.0, 5.0, 10.0]:
		_moss_hang(k, x, LEDGE_TOP - 0.1, LEDGE_Z.y + 0.05, 0.0, 1.6)
	_torch(k, -2.6, 12.5)
	_torch(k, 2.6, 12.5)
	_torch(k, -12.5, 2.6)
	_torch(k, 12.5, 2.6)
	_torch(k, -11.0, LEDGE_Z.x + 1.5, LEDGE_TOP)
	_torch(k, 11.0, LEDGE_Z.x + 1.5, LEDGE_TOP)
	_torch(k, -2.6, GALLERY_Z.x + 1.2, up)
	_torch(k, 2.6, GALLERY_Z.x + 1.2, up)
	k.locked_door(15.4, 0.0, PI / 2.0, D + ":door_key1")
	k.chest(-9.0, 9.0, PI * 0.5, "map", false, D + ":chest_map")
	for p in [Vector2(10.5, 12.5), Vector2(12.0, 12.5), Vector2(-12.5, 11.0), Vector2(12.5, -6.5)]:
		k.pot(p.x, p.y, "", false)


func _snare(k) -> void:
	k.shutter(-18.6, 0.0, PI / 2.0, "snare")
	_lamps(k, "snare", 1.8)
	_root(k, Vector3(-37.5, 4.5, -8), Vector3(-32, 1.5, -6), Vector3(-26, 0, -2), 0.4)
	_root(k, Vector3(-37.5, 5.0, 7), Vector3(-33, 2.0, 5), Vector3(-30, 0, 8.5), 0.35)
	k.chest(-28.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key1", D + ":snare_clear")
	k.pot(-36.5, -8.5, "arrows_10")
	k.pot(-35.5, -8.5)
	k.pot(-36.5, 8.5, "bombs_5")


func _sluice(k) -> void:
	k.quicksand(SLUICE_SLUDGE, 0.0)
	for p: Vector2 in SLUICE_STONES:
		k.block(Vector3(p.x, 0.25, p.y), Vector3(2.4, 0.5, 2.4), 0.0, "stone", Color(0.7, 0.8, 0.66))
	_lamps(k, "sluice", 1.6)
	# The old sluice gates on the east wall, rusted shut.
	var gate = k._tmp(false)
	for z in [-8.0, 8.0]:
		gate.box(Vector3(39.7, 2.5, z), Vector3(0.2, 5.0, 3.0), Color.html("3a3a34"))
		for i in 5:
			gate.box(Vector3(39.55, 2.5, z - 1.2 + i * 0.6), Vector3(0.12, 5.0, 0.12), Color.html("6a5a3a"))
	k.merge(gate, "char")
	k.pot(38.5, 9.5, "")
	k.pot(37.5, 9.5, "heart")


# --- 2F --------------------------------------------------------------------------

func _pond(k) -> void:
	var y := room_y("pond")
	_sludge_pit(k, rooms.pond.r, y, SLUDGE_Y)
	for pad: Array in POND_PADS:
		var r: Rect2 = pad[0]
		k.block(Vector3(r.get_center().x, (y + ISLET_TOP) * 0.5, r.get_center().y), Vector3(r.size.x, ISLET_TOP - y, r.size.y), 0.0, "stone", Color(0.62, 0.72, 0.56))
	_lamps(k, "pond", 1.6)
	for p in [Vector2(-9.5, -44.5), Vector2(9.5, -44.5)]:
		k.pillar(p.x, p.y, 6.5, 0.45, false, "stone", ISLET_TOP)
	_root(k, Vector3(11.8, y + 5.5, -38), Vector3(8, y + 2.5, -36), Vector3(6, SLUDGE_Y, -33), 0.35)
	k.chest(0.0, -44.0, PI, "small_key", false, D + ":chest_key3", "", ISLET_TOP)
	k.pot(9.0, -21.5, "", false, ISLET_TOP)
	k.pot(-9.0, -21.5, "heart", false, ISLET_TOP)
	k.pot(-10.5, -31.0, "", false, ISLET_TOP)


func _pillars(k) -> void:
	var y := room_y("pillars")
	k.locked_door(-13.4, -33.0, PI / 2.0, D + ":door_key3", false, y)
	_lamps(k, "pillars", 1.6)
	# Two pillars too tall to climb, a floor switch on each: weigh them down.
	for s in [[-36.0, -40.0, "pillar_w"], [-24.0, -40.0, "pillar_e"]]:
		k.block(Vector3(s[0], y + 1.6, s[1]), Vector3(1.2, 3.2, 1.2), 0.0, "stone", Color(0.66, 0.76, 0.6)).set_meta("no_climb", true)
		k.floor_switch(s[0], s[1], D + ":" + s[2], y + 3.2)
	k.flag_all([D + ":pillar_w", D + ":pillar_e"], D + ":pillars")
	k.flag_bars(-30.0, -46.4, 0.0, D + ":pillars", y)
	# The pit and the Boss Key's island; falling in returns the hero to the door.
	k.void_zone(Vector3(PIT.get_center().x, y - 5.0, PIT.get_center().y), Vector3(PIT.size.x, 2.0, PIT.size.y), 2)
	k.block(Vector3(ISLAND.get_center().x, y - 3.0, ISLAND.get_center().y), Vector3(ISLAND.size.x, 6.0, ISLAND.size.y), 0.0, "stone", Color(0.62, 0.72, 0.56))
	k.chest(-39.6, -26.0, -PI / 2.0, "boss_key", true, D + ":chest_boss_key", "", y)
	# A post with a target on the near side, for the way back.
	k.block(Vector3(-31.0, y + 1.6, -26.0), Vector3(0.8, 3.2, 0.8), 0.0, "wood", Color(0.7, 0.58, 0.42)).set_meta("no_climb", true)
	k.hook_target(Vector3(-31.48, y + 2.1, -26.0), PI / 2.0)
	k.pot(-19.5, -44.5, "", false, y)
	k.pot(-20.5, -44.5, "bombs_5", false, y)


func _stairwell(k) -> void:
	var y := room_y("stairs")
	k.stairs(-30.0, -52.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(-30.0, y + FLOOR_H * 0.5, -64.5), Vector3(6.0, FLOOR_H, 3.0), 0.0, "stone", Color(0.7, 0.8, 0.66))
	_lamps(k, "stairs", 1.6)
	_torch(k, -32.4, -64.5, y + FLOOR_H)
	_torch(k, -27.6, -64.5, y + FLOOR_H)
	k.locked_door(-30.0, -68.0, 0.0, D + ":boss_door", true, fy(3))


# --- 3F --------------------------------------------------------------------------

func _roof(k) -> void:
	var y := room_y("boss")
	var rb: Rect2 = rooms.boss.r
	var c := rb.get_center()
	k.shutter(-30.0, rb.end.y - 0.6, 0.0, "boss", y)
	for pool: Rect2 in ROOF_POOLS:
		k.quicksand(pool, y, 2)
	var crenel = k._tmp()
	for side in [rb.position.y, rb.end.y]:
		var x := rb.position.x + 1.0
		while x < rb.end.x:
			if absf(x - c.x) > 2.0 or side == rb.position.y:
				crenel.box(Vector3(x, y + 6.4, side), Vector3(1.0, 0.8, 0.9), Color(0.7, 0.82, 0.68))
			x += 2.0
	for side in [rb.position.x, rb.end.x]:
		var z := rb.position.y + 1.0
		while z < rb.end.y:
			crenel.box(Vector3(side, y + 6.4, z), Vector3(0.9, 0.8, 1.0), Color(0.7, 0.82, 0.68))
			z += 2.0
	k.merge(crenel, "stone")
	for p in [Vector2(rb.position.x + 1.5, rb.position.y + 1.5), Vector2(rb.end.x - 1.5, rb.position.y + 1.5),
			Vector2(rb.position.x + 1.5, rb.end.y - 1.5), Vector2(rb.end.x - 1.5, rb.end.y - 1.5)]:
		_torch(k, p.x, p.y, y)
	for p in [Vector2(-36, -90), Vector2(-24, -82), Vector2(-33, -77), Vector2(-26, -95)]:
		k.reeds(p.x, p.y, 7)
	var clear := D + ":boss_clear"
	k.heart_container(c.x, c.y + 4.0, clear, D + ":heart_container", y)
	k.blue_warp(c.x, c.y - 4.0, clear, "marsh", "warp_bog_tower", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(0)
	var f2 := fy(2)
	var f3 := fy(3)
	k.enemy("keese", -3.0, 25.0, 0.0, {"room": "entry"}, 3.5)
	k.enemy("keese", 3.0, 22.0, 0.0, {"room": "entry"}, 4.0)
	k.enemy("snapper", -9.0, -5.0, 0.0, {"room": "hub"})
	k.enemy("snapper", 9.0, -5.0, 0.0, {"room": "hub"})
	k.enemy("keese", 6.0, 8.0, 0.0, {"room": "hub"}, 6.0)
	k.enemy("bog_stalfos", -28.0, -3.0, PI / 2.0, {"room": "snare"})
	k.enemy("snapper", -33.0, 6.0, 0.0, {"room": "snare"})
	k.enemy("snapper", -24.0, 7.0, 0.0, {"room": "snare"})
	k.enemy("rat", -32.0, -6.0, PI / 2.0, {"room": "snare"})
	k.enemy("keese", 26.0, -6.0, 0.0, {"room": "sluice"}, 3.5)
	k.enemy("keese", 32.0, 6.0, 0.0, {"room": "sluice"}, 3.5)
	k.enemy("rat", 25.0, -4.0, PI, {"room": "cellar"}, b1)
	k.enemy("rat", 33.0, 3.0, 0.0, {"room": "cellar"}, b1)
	k.enemy("rat", 27.0, 6.0, 0.0, {"room": "cellar"}, b1)
	k.enemy("bog_stalfos", 33.0, -4.0, PI / 2.0, {"room": "cellar"}, b1)
	k.enemy("keese", 29.0, -8.0, 0.0, {"room": "cellar"}, b1 + 4.0)
	k.enemy("mire_knight", 0.0, 0.0, -PI / 2.0, {"room": "knight"}, b1)
	k.enemy("snapper", 6.0, -44.0, 0.0, {"room": "pond"}, ISLET_TOP)
	k.enemy("keese", -4.0, -30.0, 0.0, {"room": "pond"}, f2 + 4.0)
	k.enemy("keese", 5.0, -38.0, 0.0, {"room": "pond"}, f2 + 4.0)
	k.enemy("bog_stalfos", -30.0, -38.0, 0.0, {"room": "pillars"}, f2)
	k.enemy("snapper", -21.0, -24.0, 0.0, {"room": "pillars"}, f2)
	k.enemy("snapper", -21.0, -42.0, 0.0, {"room": "pillars"}, f2)
	k.enemy("keese", -32.0, -56.0, 0.0, {"room": "stairs"}, f2 + 4.0)
	k.enemy("keese", -28.0, -60.0, 0.0, {"room": "stairs"}, f2 + 7.0)
	var rb: Rect2 = rooms.boss.r
	k.enemy("gullagog", rb.get_center().x, rb.get_center().y - 5.0, 0.0, {"room": "boss"}, f3)
