extends "res://tools/world/tower_region.gd"
## The Sapphire Sanctum, under the old chapel's crypt in the Batela Fells: the
## Sapphire Order's hideout, where they study the Fari Incunabulum. A
## monastery of blue-black stone going down and down, lit by the Order's
## commanded fire. Deep in it, in a vault older than the Order, lies a
## spark of Lothelye's starlight, the one light the Gauntlet cannot rule (the
## Starlight Lantern). Chapter III's dungeon; its master is Incunax, the
## Bound Page; past it, the Order's ritual chamber.
##
## Storeys, top down (north is -Z); each way down is a drop through a hole,
## with a ladder back up:
##   1F (y 0)    entry     in from the crypt stairs
##               nave      the Order's chapel: sapphire knights, the Map;
##                         locked north (Key 1)
##               vestry    west: three stakes for the Iron Mallet -> Key 1
##               belfry    east: the Compass on a ledge (Hookshot)
##               sacristy  north: the hole down
##   B1 (y -8)   scriptor. desks and mages; locked south (Key 2)
##               cloister  west: dead garden, torches lit by arrow -> Key 2
##               cells     east: a fight behind shutters; a cracked cell
##                         (bombs) holds a lost page
##               archive   under the nave: shelves, a false one (Looking
##                         Glass), the hole down
##   B2 (y -16)  well      the old well; locked north (Key 3)
##               gallery   west: a chest high up (Hookshot) -> Key 3
##               library   east: a cracked wall (bombs) -> Piece of Heart
##               warden    north: the Sapphire Warden; beaten, the grate in
##                         the floor falls away
##   B3 (y -24)  starvault Lothelye's starlight: the Starlight Lantern; a
##                         sapphire ward over the door out
##               star hall four star braziers open the floor; shades unseen
##                         but in starlight; warded doors either side
##               ward_w    two star braziers -> the Boss Key
##               ward_e    a fight; the fifth lost page
##   B4 (y -32)  ante      in by the hole; the boss door north
##               boss      Incunax, the Bound Page
##               ritual    the Order's ritual chamber (Story.sanctum_ritual);
##                         the blue warp home

const D := "sapphire_sanctum"
const STONE := Color(0.5, 0.52, 0.66)
const SAPPHIRE := Color(0.3, 0.38, 0.9)
## The grate over the hole in the Warden's floor, and the trapdoor in the
## star hall's.
const WARDEN_HOLE := Vector3(0.0, -16.0, -38.65)
const STAR_HOLE := Vector3(0.0, -24.0, 4.65)


func setup() -> void:
	id = "sapphire_sanctum"
	interior = true
	seed_value = 1515
	x_min = -46.0
	x_max = 46.0
	z_min = -78.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B4", -32.0], ["B3", -24.0], ["B2", -16.0], ["B1", -8.0], ["1F", 0.0]]
	entry_floor = 4
	wall_col = STONE
	ceil_col = Color(0.22, 0.24, 0.36)
	slab_col = Color(0.46, 0.48, 0.62)
	rooms = {
		# 1F
		"entry": {"f": 4, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"nave": {"f": 4, "r": Rect2(-14, -16, 28, 30), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"vestry": {"f": 4, "r": Rect2(-36, -8, 16, 16), "h": 6.0, "doors": [{"side": "e", "at": 0.0}]},
		"belfry": {"f": 4, "r": Rect2(20, -8, 16, 16), "h": 6.5, "doors": [{"side": "w", "at": 0.0}]},
		"sacristy": {"f": 4, "r": Rect2(-8, -46, 16, 18), "h": 6.0, "doors": [{"side": "s", "at": 0.0}]},
		# B1
		"scriptorium": {"f": 3, "r": Rect2(-12, -50, 24, 24), "h": 6.5, "doors": [{"side": "w", "at": -38.0}, {"side": "e", "at": -38.0}, {"side": "s", "at": 0.0}]},
		"cloister": {"f": 3, "r": Rect2(-40, -48, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": -38.0}], "ceiling": false},
		"cells": {"f": 3, "r": Rect2(20, -48, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": -38.0}]},
		"archive": {"f": 3, "r": Rect2(-14, -16, 28, 26), "h": 6.5, "doors": [{"side": "n", "at": 0.0}]},
		# B2
		"well": {"f": 2, "r": Rect2(-12, -14, 24, 24), "h": 6.5, "doors": [{"side": "w", "at": -2.0}, {"side": "e", "at": -2.0}, {"side": "n", "at": 0.0}]},
		"gallery": {"f": 2, "r": Rect2(-40, -12, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": -2.0}]},
		"library": {"f": 2, "r": Rect2(20, -12, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": -2.0}]},
		"warden": {"f": 2, "r": Rect2(-14, -50, 28, 26), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B3
		"starvault": {"f": 1, "r": Rect2(-10, -48, 20, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.62, 0.66, 0.86)},
		"star_hall": {"f": 1, "r": Rect2(-14, -18, 28, 28), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "w", "at": -4.0}, {"side": "e", "at": -4.0}]},
		"ward_w": {"f": 1, "r": Rect2(-40, -14, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": -4.0}]},
		"ward_e": {"f": 1, "r": Rect2(20, -14, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": -4.0}]},
		# B4
		"ante": {"f": 0, "r": Rect2(-10, -6, 20, 16), "h": 6.0, "doors": [{"side": "n", "at": 0.0}]},
		"boss": {"f": 0, "r": Rect2(-16, -44, 32, 32), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "col": Color(0.42, 0.44, 0.62)},
		"ritual": {"f": 0, "r": Rect2(-10, -72, 20, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.38, 0.38, 0.6)},
	}
	corridors = [
		{"f": 4, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 4, "r": Rect2(-20, -2, 6, 4), "x": true},
		{"f": 4, "r": Rect2(14, -2, 6, 4), "x": true},
		{"f": 4, "r": Rect2(-2, -28, 4, 12), "x": false},
		{"f": 3, "r": Rect2(-20, -40, 8, 4), "x": true},
		{"f": 3, "r": Rect2(12, -40, 8, 4), "x": true},
		{"f": 3, "r": Rect2(-2, -26, 4, 10), "x": false},
		{"f": 2, "r": Rect2(-20, -4, 8, 4), "x": true},
		{"f": 2, "r": Rect2(12, -4, 8, 4), "x": true},
		{"f": 2, "r": Rect2(-2, -24, 4, 10), "x": false},
		{"f": 1, "r": Rect2(-2, -28, 4, 10), "x": false},
		{"f": 1, "r": Rect2(-20, -6, 6, 4), "x": true},
		{"f": 1, "r": Rect2(14, -6, 6, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -12, 4, 6), "x": false},
		{"f": 0, "r": Rect2(-2, -52, 4, 8), "x": false},
	]
	holes = [
		# The sacristy's floor, over the scriptorium's ladder.
		{"f": 4, "r": ladder_hole(-4.0, -38.0, Vector2(1, 0))},
		# The archive's floor, over the well's ladder.
		{"f": 3, "r": ladder_hole(8.0, -2.0, Vector2(-1, 0))},
		# The Warden's floor, over the starvault's ladder (a grate until he falls).
		{"f": 2, "r": ladder_hole(0.0, -40.0, Vector2(0, 1))},
		# The star hall's floor, over the antechamber's ladder (shut until the braziers burn).
		{"f": 1, "r": ladder_hole(0.0, 6.0, Vector2(0, -1))},
	]
	mood = {
		"sky_top": Color.html("0e1020"), "sky_mid": Color.html("0e1020"), "sky_horizon": Color.html("0e1020"),
		"cloud": Color.html("0e1020"), "cloud_amount": 0.0,
		"fog": Color.html("0c0e1e"), "fog_begin": 12.0, "fog_end": 52.0,
		"ambient": Color.html("4a4e78"), "sun": Color.html("b8c0ff"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.4, "fill": Color.html("3a3a7a"), "fill_energy": 0.45,
		"horizon": Color.html("0e1020"), "hill_height": 0.0,
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


## Blue-black flagstones set with sapphire chips; the star hall's floor
## carries an eight-pointed star; the ritual chamber, a sigil ring.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["080a14", "0a0c18"])
	var p := Vector2(x, z)
	if f == 1 and (rooms.star_hall.r as Rect2).has_point(p):
		var q := p - room_center("star_hall")
		var a := fposmod(atan2(q.y, q.x), TAU / 8.0) - TAU / 16.0
		if q.length() < 9.0 - absf(a) * 14.0 and q.length() > 1.0:
			return Color.html("b8c4ec").darkened(r.randf_range(0.0, 0.08))
	if f == 0 and (rooms.ritual.r as Rect2).has_point(p):
		var d := p.distance_to(room_center("ritual"))
		if absf(d - 6.0) < 0.35 or absf(d - 3.5) < 0.25:
			return Color.html("5a6aff")
	var seam := fposmod(x, 2.0) < 0.1 or fposmod(z + (1.0 if int(floor(x / 2.0)) % 2 == 0 else 0.0), 2.0) < 0.1
	if seam:
		return Color.html("1e2034")
	if r.randf() < 0.012:
		return Color.html("4a5ad8")
	return Color.html(["3e4258", "444862", "3a3e54"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08) + 0.04 * (4 - f))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "batela_fells", "from_sapphire_sanctum", Color(0.4, 0.42, 0.6))
	k.entrance("from_batela_fells", 0.0, 27.0, 0.0)
	_entry(k)
	_nave(k)
	_vestry(k)
	_belfry(k)
	_sacristy(k)
	_scriptorium(k)
	_cloister(k)
	_cells(k)
	_archive(k)
	_well(k)
	_gallery(k)
	_library(k)
	_warden(k)
	_starvault(k)
	_star_hall(k)
	_ward_w(k)
	_ward_e(k)
	_ante(k)
	_boss(k)
	_ritual(k)


# --- Decoration -----------------------------------------------------------------

func _fires(k, rid: String, inset := 2.2) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.sapphire_brazier(p.x, p.y, y)


## A banner of the Order (a sapphire eye on midnight blue) on a wall.
func _banner(k, x: float, y: float, z: float, yaw: float) -> void:
	k.banner(x, y, z, yaw, Color.html("1a1e4a"), 2.6)


func _shelves(k, a: Vector2, b: Vector2, y: float) -> void:
	var d := b - a
	var n: int = maxi(1, int(d.length() / 2.0))
	var m = k._tmp()
	var rng: RandomNumberGenerator = k.rng
	var yaw := -atan2(d.y, d.x)
	for i in n:
		var c := a + d * ((i + 0.5) / n)
		m.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(c.x, y, c.y)))
		m.box(Vector3(0, 1.4, 0), Vector3(d.length() / n - 0.1, 2.8, 0.6), Color.html("3a2a22"))
		for row in 4:
			for j in 5:
				var col: Color = [Color.html("6a2a2a"), Color.html("2a3a6a"), Color.html("4a5a2a"), Color.html("5a4a2a")][rng.randi() % 4]
				m.box(Vector3(-0.7 + j * 0.35, 0.45 + row * 0.65, -0.28), Vector3(0.28, 0.5, 0.05), col)
		m.pop()
		k.col_box(Vector3(c.x, y + 1.4, c.y), Vector3(d.length() / n - 0.1, 2.8, 0.6), yaw)
	k.merge(m, "wood")


func _desk(k, x: float, z: float, yaw: float, y: float) -> void:
	var m = k._tmp()
	m.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z)))
	m.box(Vector3(0, 0.8, 0), Vector3(1.6, 0.1, 0.8), Color.html("4a3628"))
	for s in [Vector2(-0.7, -0.3), Vector2(0.7, -0.3), Vector2(-0.7, 0.3), Vector2(0.7, 0.3)]:
		m.box(Vector3(s.x, 0.4, s.y), Vector3(0.08, 0.8, 0.08), Color.html("3a2a1e"))
	m.box(Vector3(0.2, 0.88, 0), Vector3(0.5, 0.06, 0.35), Color.html("d8c8a0"))
	m.pop()
	k.merge(m, "wood")
	k.col_box(Vector3(x, y + 0.45, z), Vector3(1.6, 0.9, 0.8), yaw)


## A grate (or trapdoor) over a hole in the floor at `at` (its top), which
## falls away once `flag` is set.
func _cover(k, at: Vector3, flag: String) -> void:
	var m = k._tmp(false)
	for i in 6:
		m.box(Vector3(-1.2 + i * 0.48, -0.1, 0), Vector3(0.12, 0.2, 2.8), Color.html("2a2c3a"))
	for j in 3:
		m.box(Vector3(0, -0.1, -1.0 + j * 1.0), Vector3(2.8, 0.2, 0.12), Color.html("2a2c3a"))
	m.box(Vector3(0, -0.15, 0), Vector3(0.5, 0.25, 0.5), Color.html("4a5ad8"))
	k.flag_barrier(at + Vector3(0, -0.15, 0), Vector3(2.9, 0.3, 2.9), 0.0, flag, m, "char")


# --- 1F --------------------------------------------------------------------------

func _entry(k) -> void:
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.5, z, 6.0, 0.45, false, "stone", 0.0)
	k.sapphire_brazier(-2.6, 19.5, 0.0)
	k.sapphire_brazier(2.6, 19.5, 0.0)
	k.pot(4.8, 28.5)
	k.pot(4.8, 27.5, "heart")
	k.pot(-4.8, 28.5, "arrows_10")
	k.examine(Vector3(-4.0, 0.0, 19.0), 0.0, [{"text": "Words cut over the stair, in a newer hand than the stone:\n*THE DREAMER'S LIGHT IS NOT OURS TO COMMAND. SEAL IT BELOW.*", "instant": true}])


func _nave(k) -> void:
	# Pews down both sides, the altar at the north end with the Order's lectern.
	for z in [8.0, 4.0, 0.0, -4.0]:
		for sx in [-1.0, 1.0]:
			k.block(Vector3(sx * 6.5, 0.45, z), Vector3(5.0, 0.9, 1.0), 0.0, "wood", Color(0.55, 0.42, 0.34))
	for z in [10.0, 0.0, -10.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 11.5, z, 6.5, 0.5, false, "stone", 0.0)
	k.platform(0.0, -12.0, Vector2(8.0, 3.0), 0.5, "stone", STONE.darkened(0.2))
	_banner(k, -5.0, 4.6, -15.4, 0.0)
	_banner(k, 5.0, 4.6, -15.4, 0.0)
	_fires(k, "nave", 2.0)
	k.book(Vector3(-2.5, 1.4, -12.0), 0.0, "THE ORDER'S DAYBOOK", [
		"*Day 12.* The crypt wards hold. The Batela peasants have not come near. The chapel's old bell rang by itself at midnight; Brother Callis wept.",
		"*Day 19.* The Archmagus has found the vault the old monks sealed. A spark of the Dreamer's own light, sleeping in a jar. It will not burn for us. It will not burn at all for us.",
		"*Day 26.* Ward the vault. Bury it. No flame we command can touch it, and the Gauntlet cannot rule it. It is the one thing in the world that frightens him.",
	], Color.html("1a1e4a"))
	k.chest(10.0, -12.0, -PI / 2.0, "map", false, D + ":chest_map", "", 0.0)
	k.locked_door(0.0, -17.4, 0.0, D + ":door_key1")
	k.pot(-12.5, 12.5)
	k.pot(12.5, 12.5, "magic_small")


func _vestry(k) -> void:
	_fires(k, "vestry", 1.8)
	var flags: Array = []
	for s in [[-33.0, -5.0, "stake_a"], [-33.0, 5.0, "stake_b"], [-24.0, 0.0, "stake_c"]]:
		k.mallet_stake(s[0], s[1], D + ":" + s[2], 0.0)
		flags.append(D + ":" + s[2])
	k.flag_all(flags, D + ":stakes")
	k.chest(-28.0, -6.5, 0.0, "small_key", false, D + ":chest_key1", D + ":stakes", 0.0)
	_shelves(k, Vector2(-35.0, 7.5), Vector2(-29.0, 7.5), 0.0)
	k.examine(Vector3(-22.0, 0.0, 6.0), k.yaw_of(Vector2(-1, 0)), [{"text": "A note pinned to the wardrobe:\n*The Archmagus wants these pegs struck down every night. Nobody remembers why. Do it anyway.*", "instant": true}])


func _belfry(k) -> void:
	_fires(k, "belfry", 1.8)
	# A ledge high on the east wall, the Compass on it; a target over it for the Hookshot.
	k.block(Vector3(34.5, 1.75, 0.0), Vector3(3.0, 3.5, 6.0), 0.0, "stone", STONE.darkened(0.15))
	k.chest(34.5, 0.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", 3.5)
	k.hook_target(Vector3(35.9, 5.2, 0.0), -PI / 2.0)
	# The old bell, fallen and cracked.
	var bm = k._tmp(false)
	bm.prism(Vector3(26.0, 0.0, 4.0), 1.1, Vector3(26.2, 1.4, 4.1), 0.6, 12, Color.html("4a4a3a"))
	k.merge(bm, "char")
	k.col_cyl(Vector3(26.0, 0.0, 4.0), 1.0, 1.4)
	k.pot(22.0, -6.5, "bombs_5")
	k.pot(22.0, 6.5)


func _sacristy(k) -> void:
	var y := room_y("sacristy")
	_fires(k, "sacristy", 1.8)
	_shelves(k, Vector2(-7.5, -44.5), Vector2(7.5, -44.5), y)
	k.pot(6.5, -30.0, "magic_small")


# --- B1 -------------------------------------------------------------------------

func _scriptorium(k) -> void:
	var y := room_y("scriptorium")
	ladder_up(k, 3, -4.0, -38.0, Vector2(1, 0))
	_fires(k, "scriptorium", 2.0)
	for p in [Vector2(5, -46), Vector2(5, -40), Vector2(5, -34), Vector2(-8, -46), Vector2(-8, -30)]:
		_desk(k, p.x, p.y, PI * 0.5, y)
	k.book(Vector3(5.2, y + 0.9, -40.0), PI * 0.5, "A COPYIST'S NOTES", [
		"*From the Fari Incunabulum, folio 9:* a soul given in bargain is kept, not spent...",
		"He is not the master. He is the key. When the Gauntlet has burned enough, the door will open from our side, and our Lord will push from his.",
		"Pages 2, 4, 5 and 11 are missing. The Archmagus blames the peasants. I blame the wind.",
	], Color.html("2a2a4a"))
	k.locked_door(0.0, -24.6, 0.0, D + ":door_key2", false, y)


func _cloister(k) -> void:
	var y := room_y("cloister")
	var c := room_center("cloister")
	# A dead garden under an open sky of rock, a lit brazier in the middle; the
	# four unlit torches round it take fire from an arrow shot through it.
	for i in 6:
		var a := TAU * i / 6.0
		k.tree_dead(c.x + cos(a) * 6.5, c.y + sin(a) * 6.5, 0.9)
	k.torch(c.x, c.y, true, "", y)
	var flags: Array = []
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var f := D + ":cloister_torch_%d" % i
		k.torch(c.x + cos(a) * 8.0, c.y + sin(a) * 8.0, false, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":cloister_lit")
	k.chest(c.x - 8.0, c.y, PI / 2.0, "small_key", false, D + ":chest_key2", D + ":cloister_lit", y)
	k.pot(c.x + 8.5, c.y + 8.5, "arrows_10", false, y)
	k.pot(c.x + 8.5, c.y - 8.5, "arrows_10", false, y)
	k.examine(Vector3(c.x + 8.5, y, c.y), k.yaw_of(Vector2(-1, 0)), [{"text": "A brass plaque on the brazier's stand:\n*FROM ONE FLAME, FOUR. SEND IT ON THE WING.*", "instant": true}])


func _cells(k) -> void:
	var y := room_y("cells")
	k.shutter(20.6, -38.0, PI / 2.0, "cells", y)
	_fires(k, "cells", 1.8)
	# Little cells along the north wall; one cracked shut.
	for x in [24.0, 30.0, 36.0]:
		k.wall_line([Vector2(x - 2.8, -42.0), Vector2(x - 2.8, -47.6)], 3.0, 0.4, "stone", STONE, false, y)
	# (A gap at x 34.5..37.5 for the cracked wall.)
	k.wall_line([Vector2(39.6, -42.0), Vector2(37.5, -42.0)], 3.0, 0.4, "stone", STONE, false, y)
	k.wall_line([Vector2(34.5, -42.0), Vector2(21.2, -42.0)], 3.0, 0.4, "stone", STONE, false, y)
	k.bomb_wall(36.0, -42.0, 0.0, D + ":cell_wall", y)
	k.incunabulum_page(36.0, -45.5, 4, y)
	k.chest(24.0, -45.0, 0.0, "bombs_10", false, D + ":chest_cells", D + ":cells_clear", y)


func _archive(k) -> void:
	var y := room_y("archive")
	# (The ladder up from the well, through the hole in this floor.)
	ladder_up(k, 2, 8.0, -2.0, Vector2(-1, 0))
	_fires(k, "archive", 2.0)
	for z in [-10.0, -4.0, 2.0]:
		_shelves(k, Vector2(-12.5, z), Vector2(-3.0, z), y)
	_shelves(k, Vector2(-12.5, 7.5), Vector2(12.5, 7.5), y)
	# One shelf is false (the Looking Glass shows it): rupees behind it.
	k.block(Vector3(12.0, y + 1.5, -10.0), Vector3(3.6, 3.0, 0.5), 0.0, "stone", STONE)
	k.lens_block(Vector3(10.4, y + 1.5, -12.5), Vector3(0.5, 3.0, 4.6), "fake", "stone", STONE)
	k.chest(12.6, -12.5, -PI / 2.0, "rupee_red", false, D + ":chest_lens", "", y)


# --- B2 -------------------------------------------------------------------------

func _well(k) -> void:
	var y := room_y("well")
	var c := room_center("well")
	_fires(k, "well", 2.0)
	# The old well in the middle, black water far down.
	var m = k._tmp()
	m.prism(Vector3(c.x - 4.0, y, c.y + 3.0), 1.6, Vector3(c.x - 4.0, y + 0.9, c.y + 3.0), 1.6, 10, STONE.darkened(0.25))
	m.prism(Vector3(c.x - 4.0, y + 0.88, c.y + 3.0), 1.3, Vector3(c.x - 4.0, y + 0.9, c.y + 3.0), 1.3, 10, Color.html("0a0c14"))
	k.merge(m, "stone")
	k.col_cyl(Vector3(c.x - 4.0, y, c.y + 3.0), 1.6, 0.9)
	k.locked_door(0.0, -15.4, 0.0, D + ":door_key3", false, y)
	k.pot(-10.5, 8.5, "heart", false, y)
	k.pot(-10.5, 7.5, "", false, y)


func _gallery(k) -> void:
	var y := room_y("gallery")
	_fires(k, "gallery", 1.8)
	# A balcony high on the west wall with the key; a target over it for the Hookshot.
	k.block(Vector3(-38.5, y + 1.75, -2.0), Vector3(3.0, 3.5, 8.0), 0.0, "stone", STONE.darkened(0.15))
	k.chest(-38.5, -2.0, PI / 2.0, "small_key", false, D + ":chest_key3", "", y + 3.5)
	k.hook_target(Vector3(-39.9, y + 5.2, -2.0), PI / 2.0)
	for z in [-9.0, 5.0]:
		k.statue(-30.0, z, k.yaw_of(Vector2(1, 0)), 1.0, "stone", y)


func _library(k) -> void:
	var y := room_y("library")
	_fires(k, "library", 1.8)
	for x in [24.0, 30.0]:
		_shelves(k, Vector2(x, -10.5), Vector2(x, 2.0), y)
	k.bomb_wall(39.4, 4.0, -PI / 2.0, D + ":library_wall", y)
	k.chest(41.6, 4.0, -PI / 2.0, "heart_piece", false, D + ":chest_heart", "", y)
	k.block(Vector3(41.6, y + 1.5, 1.4), Vector3(3.0, 3.0, 0.4), 0.0, "stone", STONE)
	k.block(Vector3(41.6, y + 1.5, 6.6), Vector3(3.0, 3.0, 0.4), 0.0, "stone", STONE)
	k.pot(36.0, -10.5, "bombs_5", false, y)


func _warden(k) -> void:
	var y := room_y("warden")
	k.shutter(0.0, -24.6, 0.0, "warden", y)
	_fires(k, "warden", 2.0)
	for x in [-8.0, 8.0]:
		for z in [-44.0, -30.0]:
			k.pillar(x, z, 6.5, 0.6, false, "stone", y)
	_cover(k, WARDEN_HOLE, D + ":warden_clear")
	_banner(k, 0.0, y + 4.6, -49.4, 0.0)


# --- B3 -------------------------------------------------------------------------

func _starvault(k) -> void:
	var y := room_y("starvault")
	var c := room_center("starvault")
	ladder_up(k, 1, 0.0, -40.0, Vector2(0, 1))
	# Older than the Order: pale stone, stars carved on the walls, and the
	# jar of starlight on its plinth (the big chest holds it).
	for i in 6:
		var a := TAU * i / 6.0
		k.pillar(c.x + cos(a) * 7.5, c.y + sin(a) * 7.5, 6.5, 0.45, false, "stone", y)
	k.platform(c.x, c.y - 6.0, Vector2(5.0, 3.0), y + 0.6, "stone", Color(0.8, 0.84, 0.95))
	k.chest(c.x, c.y - 6.0, 0.0, "starlight_lantern", true, D + ":chest_starlight", "", y + 0.6)
	for p in [Vector2(-7.5, -46.5), Vector2(7.5, -46.5)]:
		k.star_brazier(p.x, p.y, D + ":vault_star_%s" % ("w" if p.x < 0 else "e"), y)
	# The Order's ward across the way out: the starlight is the only way past.
	k.sapphire_ward(0.0, -28.8, 0.0, 3.4, D + ":ward_vault", y)


func _star_hall(k) -> void:
	var y := room_y("star_hall")
	var c := room_center("star_hall")
	var flags: Array = []
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var f := D + ":hall_star_%d" % i
		k.star_brazier(c.x + cos(a) * 9.0, c.y + sin(a) * 9.0, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":star_hall_lit")
	_cover(k, STAR_HOLE, D + ":star_hall_lit")
	k.sapphire_ward(-14.6, -4.0, PI / 2.0, 3.4, D + ":ward_w", y)
	k.sapphire_ward(14.6, -4.0, PI / 2.0, 3.4, D + ":ward_e", y)
	k.examine(Vector3(c.x - 4.0, y, c.y - 12.5), 0.0, [{"text": "An inscription in the old monks' hand, half chiseled away by the Order:\n*FOUR STARS LIT, THE FLOOR OPENS TO THE DEEP.*", "instant": true}])
	k.pot(-12.5, 8.5, "magic_small", false, y)
	k.pot(12.5, 8.5, "magic_small", false, y)


func _ward_w(k) -> void:
	var y := room_y("ward_w")
	var c := room_center("ward_w")
	var flags: Array = []
	for s in [-1.0, 1.0]:
		var f := D + ":ward_w_star_%d" % (0 if s < 0 else 1)
		k.star_brazier(c.x - 5.0, c.y + s * 6.0, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":ward_w_lit")
	k.chest(c.x - 7.0, c.y, PI / 2.0, "boss_key", true, D + ":chest_boss_key", D + ":ward_w_lit", y)
	_fires(k, "ward_w", 1.8)


func _ward_e(k) -> void:
	var y := room_y("ward_e")
	var c := room_center("ward_e")
	k.shutter(20.6, -4.0, PI / 2.0, "ward_e", y)
	_fires(k, "ward_e", 1.8)
	k.incunabulum_page(c.x + 6.0, c.y, 5, y)
	k.pot(c.x + 7.5, c.y + 7.5, "heart", false, y)


# --- B4 -------------------------------------------------------------------------

func _ante(k) -> void:
	var y := room_y("ante")
	ladder_up(k, 0, 0.0, 6.0, Vector2(0, -1))
	_fires(k, "ante", 1.8)
	k.locked_door(0.0, -7.4, 0.0, D + ":boss_door", true, y)
	for p in [Vector2(-8.5, 8.5), Vector2(8.5, 8.5), Vector2(-8.5, -4.5)]:
		k.pot(p.x, p.y, ["heart", "magic_small", "arrows_10"][int(p.x > 0) + int(p.y < 0) * 2], false, y)


func _boss(k) -> void:
	var y := room_y("boss")
	var rb: Rect2 = rooms.boss.r
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	for p in [Vector2(rb.position.x + 2.0, rb.position.y + 2.0), Vector2(rb.end.x - 2.0, rb.position.y + 2.0),
			Vector2(rb.position.x + 2.0, rb.end.y - 2.0), Vector2(rb.end.x - 2.0, rb.end.y - 2.0)]:
		k.sapphire_brazier(p.x, p.y, y)
	for i in 8:
		var a := TAU * i / 8.0
		k.pillar(cos(a) * 13.0, -28.0 + sin(a) * 13.0, 6.5, 0.6, i % 3 == 0, "stone", y)
	var clear := D + ":boss_clear"
	k.heart_container(0.0, -16.0, clear, D + ":heart_container", y)
	k.flag_bars(0.0, -44.6, 0.0, clear, y)


func _ritual(k) -> void:
	var y := room_y("ritual")
	var c := room_center("ritual")
	for i in 6:
		var a := TAU * i / 6.0
		k.sapphire_brazier(c.x + cos(a) * 6.0, c.y + sin(a) * 6.0, y)
	k.platform(c.x, c.y - 7.5, Vector2(6.0, 2.5), y + 0.5, "stone", STONE.darkened(0.3))
	k.mark("cs_ritual_mage", Vector3(c.x, y + 0.5, c.y - 7.5), 0.0)
	k.mark("cs_ritual_hero", Vector3(c.x, y, c.y + 6.0), PI)
	k.mark("cs_ritual_cam", Vector3(c.x + 6.0, y + 3.0, c.y + 8.0))
	k.story_trigger("sanctum_ritual", Rect2(c.x - 8.0, c.y + 2.0, 16.0, 6.0), y, "ch3:seal_cracked", D + ":boss_clear")
	k.blue_warp(c.x, c.y + 1.0, "ch3:seal_cracked", "batela_fells", "warp_sapphire_sanctum", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(3)
	var b2 := fy(2)
	var b3 := fy(1)
	var b4 := fy(0)
	k.enemy("sapphire_knight", -6.0, 2.0, 0.0, {"room": "nave"}, 0.0)
	k.enemy("sapphire_knight", 6.0, -6.0, 0.0, {"room": "nave"}, 0.0)
	k.enemy("fire_keese", 0.0, 6.0, 0.0, {"room": "nave"}, 4.0)
	k.enemy("keese", -28.0, 0.0, 0.0, {"room": "vestry"}, 3.5)
	k.enemy("sapphire_mage", 0.0, -38.0, 0.0, {"room": "sacristy"}, 0.0)
	k.enemy("sapphire_mage", -6.0, -44.0, 0.0, {"room": "scriptorium"}, b1)
	k.enemy("sapphire_mage", 8.0, -30.0, PI, {"room": "scriptorium"}, b1)
	k.enemy("charred_stalfos", 28.0, -36.0, PI / 2.0, {"room": "cells"}, b1)
	k.enemy("charred_stalfos", 34.0, -32.0, PI / 2.0, {"room": "cells"}, b1)
	k.enemy("fire_keese", 30.0, -38.0, 0.0, {"room": "cells"}, b1 + 3.5)
	k.enemy("keese", -30.0, -38.0, 0.0, {"room": "cloister"}, b1 + 4.0)
	k.enemy("sapphire_knight", -4.0, -6.0, 0.0, {"room": "well"}, b2)
	k.enemy("sapphire_knight", 6.0, 4.0, PI, {"room": "well"}, b2)
	k.enemy("sapphire_mage", 30.0, -4.0, -PI / 2.0, {"room": "library"}, b2)
	k.enemy("sapphire_warden", 0.0, -40.0, 0.0, {"room": "warden"}, b2)
	k.enemy("shade", -6.0, -8.0, 0.0, {"room": "star_hall"}, b3 + 1.3)
	k.enemy("shade", 6.0, 2.0, 0.0, {"room": "star_hall"}, b3 + 1.3)
	k.enemy("shade", -30.0, -2.0, 0.0, {"room": "ward_w"}, b3 + 1.3)
	k.enemy("sapphire_knight", 28.0, -8.0, -PI / 2.0, {"room": "ward_e"}, b3)
	k.enemy("sapphire_mage", 34.0, 2.0, -PI / 2.0, {"room": "ward_e"}, b3)
	k.enemy("shade", 30.0, 0.0, 0.0, {"room": "ward_e"}, b3 + 1.3)
	k.enemy("incunax", 0.0, -30.0, 0.0, {"room": "boss", "arena_radius": 11.0, "floor_y": b4}, b4 + 3.2)
