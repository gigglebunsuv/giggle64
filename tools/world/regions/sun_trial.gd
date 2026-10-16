extends "res://tools/world/tower_region.gd"
## The Trial of the Sun, at the foot of the great mesa in the Desert of
## Ladhellin: a small temple the Questlords once swore to guard, sealed by two
## great stones (the Bun Bracers lift them). The Sapphire Order came for the
## Sunstone kept in its sanctum, to feed the Gauntlet's flame, and took it;
## they never found the trial's own treasure, the Sun Arrows. Chapter II's
## second dungeon, short and bright.
##
## Rooms (one storey, north is -Z):
##   entry     in from the desert
##   court     open to the sky: a shaft of sun, a mirror to turn; wake both
##             suns on the walls with the Mirror Shield and the bars north lift
##   shades    west: dark, its shades seen only in a crack of sunlight, behind
##             shutters -> the Small Key
##   guardian  north (bars, then the Small Key): the Sunwarden -> the Sun
##             Arrows; a sun high over the north door, too high for any
##             mirror: a Sun Arrow wakes it
##   sanctum   the empty pedestal, the Order's scorched map (the trail), a
##             Piece of Heart, and the blue warp back to the desert

const D := "sun_trial"
const SAND := Color(1.0, 0.92, 0.75)
const GOLD := Color(0.95, 0.75, 0.25)

var open_sky := true


func setup() -> void:
	id = "sun_trial"
	interior = true
	seed_value = 281
	x_min = -44.0
	x_max = 20.0
	z_min = -70.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["1F", 0.0]]
	entry_floor = 0
	wall_col = Color(1.0, 0.9, 0.72)
	wall_mat = "sandstone"
	ceil_col = Color(0.55, 0.45, 0.32)
	slab_col = Color(0.95, 0.85, 0.68)
	rooms = {
		"entry": {"f": 0, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"court": {"f": 0, "r": Rect2(-14, -14, 28, 28), "h": 7.0, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "n", "at": 0.0}], "ceiling": false},
		"shades": {"f": 0, "r": Rect2(-38, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.6, 0.52, 0.42)},
		"guardian": {"f": 0, "r": Rect2(-12, -44, 24, 22), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"sanctum": {"f": 0, "r": Rect2(-8, -66, 16, 16), "h": 6.0, "doors": [{"side": "s", "at": 0.0}], "ceiling": false},
	}
	corridors = [
		{"f": 0, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 0, "r": Rect2(-18, -2, 4, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -22, 4, 8), "x": false},
		{"f": 0, "r": Rect2(-2, -50, 4, 6), "x": false},
	]
	holes = []
	mood = {
		# A hard blue sky over the open court; warm stone shadow inside.
		"sky_top": Color.html("4a7ac8"), "sky_mid": Color.html("98b8e0"), "sky_horizon": Color.html("f0dcb8"),
		"cloud": Color.html("fff8ec"), "cloud_amount": 0.1,
		"fog": Color.html("3a2a1a"), "fog_begin": 18.0, "fog_end": 70.0,
		"ambient": Color.html("7a6248"), "sun": Color.html("fff0c8"), "sun_rot": Vector3(-75, -20, 0),
		"sun_energy": 1.1, "fill": Color.html("6a4a3a"), "fill_energy": 0.35,
		"horizon": Color.html("c8a882"), "hill_height": 0.0,
	}


func _inside(x: float, z: float) -> bool:
	for rid: String in rooms:
		if (rooms[rid].r as Rect2).grow(1.0).has_point(Vector2(x, z)):
			return true
	for c: Dictionary in corridors:
		if (c.r as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## Sandstone tiles laid in rings round a gold sun in the court; dark in the
## room of shades.
func floor_paint(x: float, z: float, _f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z):
		return pick(r, ["1a140e", "201810"])
	var p := Vector2(x, z)
	if p.length() < 2.2:
		return Color.html("e8b838").darkened(r.randf_range(0.0, 0.1))
	if p.length() < 12.0 and absf(fmod(p.length(), 2.4) - 1.2) < 0.08:
		return Color.html("b8903a")
	if (rooms.shades.r as Rect2).has_point(p):
		return pick(r, ["4a3e30", "524434", "443828"])
	var seam := fposmod(x, 1.6) < 0.08 or fposmod(z, 1.6) < 0.08
	if seam:
		return Color.html("8a6a44")
	return Color.html(["e0c48c", "d8bc84", "e8cc96"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "desert", "from_sun_trial", Color(1.0, 0.9, 0.7))
	k.entrance("from_desert", 0.0, 27.0, 0.0)
	_entry(k)
	_court(k)
	_shades(k)
	_guardian(k)
	_sanctum(k)


func _torch(k, x: float, z: float) -> void:
	k.brazier(x, z, true, 0.0)


## A sun carved on a wall: a gold disc with rays (decoration).
func _sun_relief(k, pos: Vector3, yaw: float, size := 1.0) -> void:
	var m = k._tmp(false)
	m.push(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI / 2.0), pos))
	m.prism(Vector3(0, -0.04, 0), 0.6 * size, Vector3(0, 0.04, 0), 0.6 * size, 12, GOLD)
	for i in 12:
		var a := TAU * i / 12.0
		m.box(Vector3(cos(a), 0.0, sin(a)) * 0.85 * size, Vector3(0.14, 0.06, 0.14) * size, GOLD.lightened(0.15))
	m.pop()
	k.merge(m, "char")


func _entry(k) -> void:
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.5, z, 6.0, 0.5, false, "sandstone", 0.0)
	_torch(k, -2.6, 19.5)
	_torch(k, 2.6, 19.5)
	_sun_relief(k, Vector3(0, 4.2, 18.4), 0.0, 1.2)
	k.pot(4.8, 28.5, "magic_small")
	k.pot(-4.8, 28.5, "heart")


func _court(k) -> void:
	# Sun through the open roof: wake the east sun straight from the shaft,
	# and the west one by the mirror.
	k.sun_shaft(0.0, 0.0, 0.0, 9.0)
	k.sun_switch(Vector3(13.88, 1.3, -4.0), PI / 2.0, D + ":court_east")
	k.sun_switch(Vector3(-13.88, 1.3, -9.0), -PI / 2.0, D + ":court_west")
	k.light_mirror(-7.0, 4.0, PI, 0.0)
	k.pillar(-6.0, -6.0, 7.0, 0.6, false, "sandstone", 0.0)
	k.flag_all([D + ":court_east", D + ":court_west"], D + ":court")
	k.flag_bars(0.0, -14.6, 0.0, D + ":court", 0.0)
	for p in [Vector2(-11, 11), Vector2(11, 11), Vector2(11, -11), Vector2(-11, -11)]:
		k.statue(p.x, p.y, k.yaw_of(-p), 1.0, "sandstone", 0.0)
	k.pot(12.0, 12.5, "arrows_10")
	k.pot(-12.0, 12.5, "")


func _shades(k) -> void:
	k.shutter(-18.6, 0.0, PI / 2.0, "shades")
	# A crack in the roof lets one shaft of sun in: the only light to see them by.
	k.sun_shaft(-28.0, 0.0, 0.0, 6.0)
	k.chest(-35.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key", D + ":shades_clear", 0.0)
	for p in [Vector2(-36.5, 8.5), Vector2(-35.5, 8.5)]:
		k.pot(p.x, p.y, "", false, 0.0)


func _guardian(k) -> void:
	k.locked_door(0.0, -20.6, 0.0, D + ":door_key")
	k.shutter(0.0, -22.6, 0.0, "guardian")
	_torch(k, -9.5, -24.5)
	_torch(k, 9.5, -24.5)
	_torch(k, -9.5, -41.5)
	_torch(k, 9.5, -41.5)
	for x in [-6.0, 6.0]:
		k.pillar(x, -33.0, 6.5, 0.6, false, "sandstone", 0.0)
	k.chest(0.0, -30.0, PI, "sun_arrows", true, D + ":chest_sun_arrows", D + ":guardian_clear", 0.0)
	# The sun high over the north door, past any mirror's reach: a Sun Arrow wakes it.
	k.sun_switch(Vector3(0.0, 5.0, -43.88), 0.0, D + ":sanctum")
	k.flag_bars(0.0, -44.6, 0.0, D + ":sanctum", 0.0)
	_sun_relief(k, Vector3(-6.0, 4.0, -43.6), 0.0)
	_sun_relief(k, Vector3(6.0, 4.0, -43.6), 0.0)


func _sanctum(k) -> void:
	var c := room_center("sanctum")
	# The empty pedestal, scorched where the Sunstone burned.
	var ped = k._tmp(false)
	ped.prism(Vector3(c.x, 0.0, c.y - 2.0), 0.9, Vector3(c.x, 0.9, c.y - 2.0), 0.7, 8, SAND.darkened(0.1))
	ped.prism(Vector3(c.x, 0.9, c.y - 2.0), 0.75, Vector3(c.x, 1.0, c.y - 2.0), 0.75, 8, Color.html("2a1c14"))
	k.merge(ped, "sandstone")
	k.col_cyl(Vector3(c.x, 0.0, c.y - 2.0), 0.85, 1.0)
	k.examine(Vector3(c.x, 0.0, c.y - 0.9), PI, [], "res://scripts/npc/order_map_lines.gd", "pedestal", 1.5)
	# The Order's map, dropped on the floor by the door.
	var paper = k._tmp(false)
	paper.box(Vector3(c.x + 3.0, 0.02, c.y + 4.0), Vector3(0.8, 0.02, 0.6), Color.html("e0d0a8"))
	paper.box(Vector3(c.x + 3.25, 0.03, c.y + 3.85), Vector3(0.3, 0.01, 0.25), Color.html("2a1c14"))
	paper.box(Vector3(c.x + 2.8, 0.03, c.y + 4.1), Vector3(0.5, 0.01, 0.02), Color.html("c83a2a"))
	k.merge(paper, "char")
	var map: Node3D = k.examine(Vector3(c.x + 3.0, 0.0, c.y + 4.0), 0.0, [], "res://scripts/npc/order_map_lines.gd", "map", 1.4)
	map.set("front_only", false)
	_sun_relief(k, Vector3(c.x, 4.0, c.y - 7.6), 0.0, 1.6)
	k.heart_piece(c.x - 5.0, c.y - 5.0, D + ":heart_piece", 0.3)
	k.blue_warp(c.x - 3.0, c.y + 4.0, "ch2:trail_found", "desert", "warp_sun_trial", 0.0)


func populate(k) -> void:
	k.enemy("leever", -6.0, 6.0, 0.0, {"room": "court"})
	k.enemy("leever", 6.0, -8.0, 0.0, {"room": "court"})
	k.enemy("shade", -30.0, -5.0, 0.0, {"room": "shades"}, 1.3)
	k.enemy("shade", -26.0, 5.0, 0.0, {"room": "shades"}, 1.3)
	k.enemy("mummy", -34.0, 4.0, PI / 2.0, {"room": "shades"})
	k.enemy("sunwarden", 0.0, -36.0, 0.0, {"room": "guardian"})
