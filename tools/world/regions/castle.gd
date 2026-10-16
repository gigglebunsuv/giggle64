extends "res://tools/world/tower_region.gd"
## The Castle of Haven, the last dungeon, after Firebuns III took it: white
## royal stone scorched black, carpets burnt, banners torn, fires still
## burning, sapphire crystals of the Order's magic grown over the walls, and
## his goblins, mages and knights everywhere. Thirty rooms on seven storeys,
## from the dungeons up to the throne room under a burning sky.
##
## Storeys (north is -Z):
##   B2 (y -16) store     supplies left by the guards (bombs, arrows)
##              prison    the cells; mages; the way north and east
##              cell      Pink, Aladriel and Idrith, behind bars that lift
##                        when the Warden falls (the rescue scene)
##              warden    the Sapphire Warden (mini-boss)
##              oubliette behind a cracked wall: a Piece of Heart
##   B1 (y -8)  guard     the guardroom: Small Key 3
##              wine      the wine cellar, under the pantry, ankle deep
##              treasury  behind a cracked wall: rupees
##              cistern   a pit across the old cistern: plant a bloom-pod on
##                        the far ledge and hookshot over
##              crypt     the royal crypt: a floor switch opens the trapdoor
##                        up into the chapel; a hole down into the prison
##   1F (y 0)   gate      in from the town: a bomb bag (or more bombs)
##              hall      the Great Hall, two storeys tall: the Map
##              west      the armory: a Sapphire Knight -> Small Key 1;
##                        a ladder up to the library
##              east      the kitchens (Small Key 1): a cracked wall north;
##                        a ladder up to the solar
##              pantry    stores and rupees; the hole down to the cellar
##              chapel    a sunbeam through the broken roof: light the sun
##                        on the wall with the Mirror Shield -> Small Key 2
##              court     the burnt garden, open to the sky (Small Key 2): fire
##                        arrows through the brazier into the two dark ones
##                        lift the bars to the keep
##              keep      a stairwell two storeys tall up to 2F
##   2F (y 8)   library   above the armory: the Compass
##              solar     above the kitchens: switches on high shelves (pods)
##              barracks  shutters: knights and goblins
##              war       the war room: the model of the castle, rupees
##              bell      the bell tower (Small Key 3), two storeys, up to 3F
##   3F (y 16)  rampart_e a gale along the broken rampart (Wind Boots)
##              keep3     the keep's third floor
##              rampart_w sunlight, a mirror and a sun switch -> Small Key 4
##              stair     a stairwell (Small Key 4) up to 4F
##   4F (y 24)  roof      the Cinder Wyvern (mini-boss) on the roof
##              ante      a stairwell up to 5F; the boss door (Pink's key)
##   5F (y 32)  throne    the throne room, its roof burnt away: Firebuns III

const MK := preload("res://tools/mesh_kit.gd")
const D := "castle"
const STONE := Color(0.86, 0.84, 0.82)
const CHAR := Color(0.2, 0.17, 0.16)
const CARPET := Color(0.6, 0.12, 0.12)
const SAPPHIRE := Color(0.35, 0.6, 1.0)
## The cistern's pit and the ledge across it.
const CISTERN_PIT := Rect2(-16, -42, 32, 10)
## The hole over the ladder from the crypt up into the chapel (its trapdoor).
const TRAP_LADDER := Vector2(-48.0, -37.0)

var open_sky := true


func setup() -> void:
	id = "castle"
	interior = true
	seed_value = 241
	x_min = -62.0
	x_max = 62.0
	z_min = -290.0
	z_max = 40.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B2", -16.0], ["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0], ["4F", 24.0], ["5F", 32.0]]
	entry_floor = 2
	wall_col = Color(0.88, 0.86, 0.84)
	ceil_col = Color(0.35, 0.3, 0.3)
	slab_col = Color(0.86, 0.84, 0.8)
	var dark := Color(0.62, 0.6, 0.62)
	var burnt := Color(0.7, 0.62, 0.58)
	rooms = {
		# B2: the dungeons.
		"store": {"f": 0, "r": Rect2(-58, -12, 28, 24), "h": 6.5, "doors": [{"side": "n", "at": -44.0}], "col": dark},
		"prison": {"f": 0, "r": Rect2(-58, -48, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": -44.0}, {"side": "e", "at": -27.0}, {"side": "n", "at": -44.0}], "col": dark},
		# South of the cistern's pit above, so the pit never opens into it.
		"cell": {"f": 0, "r": Rect2(-22, -31, 14, 16), "h": 6.5, "doors": [{"side": "w", "at": -27.0}], "col": dark},
		"warden": {"f": 0, "r": Rect2(-58, -86, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": -44.0}, {"side": "e", "at": -74.0}], "col": dark},
		"oubliette": {"f": 0, "r": Rect2(-22, -82, 16, 16), "h": 6.5, "doors": [{"side": "w", "at": -74.0}], "col": dark.darkened(0.15)},
		# B1: the cellars.
		"guard": {"f": 1, "r": Rect2(-58, -12, 28, 24), "h": 6.5, "doors": [{"side": "n", "at": -44.0}], "col": dark},
		"crypt": {"f": 1, "r": Rect2(-58, -48, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": -44.0}, {"side": "e", "at": -36.0}], "col": dark},
		"cistern": {"f": 1, "r": Rect2(-16, -50, 32, 30), "h": 6.5, "doors": [{"side": "w", "at": -36.0}, {"side": "e", "at": -36.0}], "col": dark},
		"wine": {"f": 1, "r": Rect2(34, -46, 20, 20), "h": 6.5, "doors": [{"side": "w", "at": -36.0}, {"side": "s", "at": 44.0}], "col": dark},
		"treasury": {"f": 1, "r": Rect2(34, -12, 20, 20), "h": 6.5, "doors": [{"side": "n", "at": 44.0}], "col": dark},
		# 1F.
		"gate": {"f": 2, "r": Rect2(-8, 20, 16, 14), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}], "col": burnt},
		"hall": {"f": 2, "r": Rect2(-18, -14, 36, 28), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "col": burnt},
		"west": {"f": 2, "r": Rect2(-58, -12, 28, 24), "h": 6.5, "doors": [{"side": "e", "at": 0.0}, {"side": "n", "at": -44.0}]},
		"east": {"f": 2, "r": Rect2(30, -12, 28, 24), "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "n", "at": 44.0}], "col": burnt},
		"pantry": {"f": 2, "r": Rect2(34, -46, 20, 20), "h": 6.5, "doors": [{"side": "s", "at": 44.0}]},
		"chapel": {"f": 2, "r": Rect2(-58, -48, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": -44.0}], "col": Color(0.92, 0.9, 0.88)},
		"court": {"f": 2, "r": Rect2(-16, -50, 32, 30), "h": 6.0, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "ceiling": false, "col": burnt},
		"keep": {"f": 2, "r": Rect2(-12, -86, 24, 24), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		# 2F.
		"library": {"f": 3, "r": Rect2(-58, -12, 28, 24), "h": 6.5, "doors": [], "floor_col": Color(0.78, 0.66, 0.5), "floor_mat": "wood"},
		"solar": {"f": 3, "r": Rect2(30, -12, 28, 24), "h": 6.5, "doors": [], "floor_col": Color(0.78, 0.66, 0.5), "floor_mat": "wood"},
		"barracks": {"f": 3, "r": Rect2(-12, -120, 24, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": -108.0}, {"side": "e", "at": -108.0}]},
		"war": {"f": 3, "r": Rect2(-46, -120, 22, 24), "h": 6.5, "doors": [{"side": "e", "at": -108.0}], "floor_col": Color(0.78, 0.66, 0.5), "floor_mat": "wood"},
		"bell": {"f": 3, "r": Rect2(24, -120, 22, 24), "h": 14.5, "doors": [{"side": "w", "at": -108.0}, {"side": "n", "at": 35.0, "y0": 8.0}]},
		# 3F.
		"rampart_e": {"f": 4, "r": Rect2(24, -154, 22, 24), "h": 4.0, "doors": [{"side": "s", "at": 35.0}, {"side": "w", "at": -142.0}], "ceiling": false, "col": burnt},
		"keep3": {"f": 4, "r": Rect2(-12, -154, 24, 24), "h": 6.5, "doors": [{"side": "e", "at": -142.0}, {"side": "w", "at": -142.0}, {"side": "n", "at": 0.0}]},
		"rampart_w": {"f": 4, "r": Rect2(-46, -154, 22, 24), "h": 4.0, "doors": [{"side": "e", "at": -142.0}], "ceiling": false, "col": burnt},
		"stair": {"f": 4, "r": Rect2(-12, -188, 24, 24), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		# 4F.
		"roof": {"f": 5, "r": Rect2(-20, -226, 40, 32), "h": 4.0, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "ceiling": false, "col": burnt},
		"ante": {"f": 5, "r": Rect2(-8, -246, 16, 16), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		# 5F.
		"throne": {"f": 6, "r": Rect2(-16, -284, 32, 32), "h": 9.0, "doors": [{"side": "s", "at": 0.0}], "ceiling": false, "col": burnt},
	}
	corridors = [
		{"f": 0, "r": Rect2(-46, -24, 4, 12), "x": false},
		{"f": 0, "r": Rect2(-30, -29, 8, 4), "x": true},
		{"f": 0, "r": Rect2(-46, -62, 4, 14), "x": false},
		{"f": 0, "r": Rect2(-30, -76, 8, 4), "x": true},
		{"f": 1, "r": Rect2(-46, -24, 4, 12), "x": false},
		{"f": 1, "r": Rect2(-30, -38, 14, 4), "x": true},
		{"f": 1, "r": Rect2(16, -38, 18, 4), "x": true},
		{"f": 1, "r": Rect2(42, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-2, 14, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-30, -2, 12, 4), "x": true},
		{"f": 2, "r": Rect2(18, -2, 12, 4), "x": true},
		{"f": 2, "r": Rect2(-46, -24, 4, 12), "x": false},
		{"f": 2, "r": Rect2(42, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-2, -20, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-2, -62, 4, 12), "x": false},
		{"f": 3, "r": Rect2(-2, -96, 4, 10), "x": false},
		{"f": 3, "r": Rect2(-24, -110, 12, 4), "x": true},
		{"f": 3, "r": Rect2(12, -110, 12, 4), "x": true},
		{"f": 4, "r": Rect2(33, -130, 4, 10), "x": false},
		{"f": 4, "r": Rect2(12, -144, 12, 4), "x": true},
		{"f": 4, "r": Rect2(-24, -144, 12, 4), "x": true},
		{"f": 4, "r": Rect2(-2, -164, 4, 10), "x": false},
		{"f": 5, "r": Rect2(-2, -194, 4, 6), "x": false},
		{"f": 5, "r": Rect2(-2, -230, 4, 4), "x": false},
		{"f": 6, "r": Rect2(-2, -252, 4, 6), "x": false},
	]
	holes = [
		# Ladders: west wing -> library, kitchens -> solar, pantry -> wine
		# cellar, prison -> crypt (and on up through the trapdoor to the chapel).
		{"f": 3, "r": ladder_hole(-56.0, 8.0, Vector2(1, 0))},
		{"f": 3, "r": ladder_hole(56.0, 8.0, Vector2(-1, 0))},
		{"f": 2, "r": ladder_hole(52.0, -30.0, Vector2(-1, 0))},
		{"f": 1, "r": ladder_hole(-33.0, -40.0, Vector2(-1, 0))},
		{"f": 2, "r": ladder_hole(TRAP_LADDER.x, TRAP_LADDER.y, Vector2(1, 0))},
		# The cistern's pit.
		{"f": 1, "r": CISTERN_PIT},
	]
	water = [
		{"rect": Rect2(34, -46, 20, 20), "y": -7.6, "col": Color(0.3, 0.26, 0.3, 0.82)},
	]
	mood = {
		# Gloom and firelight inside; above the open rooms a sky of smoke and flame.
		"sky_top": Color.html("1a0a10"), "sky_mid": Color.html("4a1612"), "sky_horizon": Color.html("b8401e"),
		"cloud": Color.html("3a201c"), "cloud_amount": 0.9,
		"fog": Color.html("1a0e0c"), "fog_begin": 16.0, "fog_end": 70.0,
		"ambient": Color.html("5c5a66"), "sun": Color.html("ffb88a"), "sun_rot": Vector3(-40, 30, 0),
		"sun_energy": 0.7, "fill": Color.html("4a5a8a"), "fill_energy": 0.5,
		"horizon": Color.html("2a1010"), "hill_height": 0.0, "particles": "embers",
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


## Scorched flagstones; a burnt red carpet up the middle of the hall and the
## throne room; damp stone below; planks in the upper rooms.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["0e0a0a", "120c0c"])
	if (f == 2 and absf(x) < 2.6 and z > -14.0 and z < 34.0) or (f == 6 and absf(x) < 3.0 and z > -276.0):
		var c := CARPET.lerp(CHAR, clampf(noise.get_noise_2d(x * 3.0, z * 3.0) + 0.3, 0.0, 0.8))
		if absf(x) > 2.3 and absf(x) < 2.6 or absf(x) > 2.7:
			c = Color(0.75, 0.6, 0.25).lerp(CHAR, 0.5)
		return c.darkened(r.randf_range(0.0, 0.08))
	for rid in ["library", "solar", "war"]:
		if f == rooms[rid].f and (rooms[rid].r as Rect2).has_point(Vector2(x, z)):
			var plank := int(floor(x / 0.6))
			var pc := Color.html(["8a6e4e", "967856", "7e6446"][posmod(plank, 3)]).lerp(CHAR, 0.25)
			if fposmod(x, 0.6) < 0.05:
				pc = Color.html("2a1e14")
			return pc.darkened(r.randf_range(0.0, 0.1))
	var big := 1.8 if f >= 2 else 1.4
	var seam := fposmod(x, big) < 0.08 or fposmod(z + (big * 0.5 if int(floor(x / big)) % 2 == 0 else 0.0), big) < 0.08
	if seam:
		return Color.html("2a2424")
	var base := Color.html(["b0aaa4", "bab4ae", "a8a29c"][r.randi() % 3])
	if f < 2:
		base = base.darkened(0.35)
	# Soot and scorch marks.
	base = base.lerp(CHAR, clampf(noise.get_noise_2d(x * 2.5, z * 2.5) * 1.4, 0.0, 0.7))
	return base.darkened(r.randf_range(0.0, 0.1))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 33.98), 0.0, 2.4, 3.2, "castle_town", "from_castle", Color(0.4, 0.34, 0.3))
	k.entrance("from_castle_town", 0.0, 31.0, 0.0)
	_store(k)
	_prison(k)
	_cell(k)
	_warden(k)
	_oubliette(k)
	_guard(k)
	_crypt(k)
	_cistern(k)
	_wine(k)
	_treasury(k)
	_gate(k)
	_hall(k)
	_west(k)
	_east(k)
	_pantry(k)
	_chapel(k)
	_court(k)
	_keep(k)
	_library(k)
	_solar(k)
	_barracks(k)
	_war(k)
	_bell(k)
	_rampart_e(k)
	_keep3(k)
	_rampart_w(k)
	_stair(k)
	_roof(k)
	_ante(k)
	_throne(k)


# --- Decoration -----------------------------------------------------------------

func _torch(k, x: float, z: float, y := 0.0) -> void:
	k.brazier(x, z, true, y)


func _lamps(k, rid: String, inset := 2.5) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


## A torn, scorched banner of Haven on a wall.
func _banner(k, x: float, y: float, z: float, yaw: float, length := 3.0) -> void:
	k.banner(x, y, z, yaw, Color.html("2a3a7a").lerp(CHAR, 0.45), length)


## A cluster of sapphire crystals grown out of the floor (the Order's magic).
func _crystals(k, x: float, z: float, y: float, s := 1.0) -> void:
	var g = k._tmp(false)
	for i in 5:
		var a := TAU * i / 5.0 + x
		var lean := Vector3(cos(a) * 0.25, 1.0, sin(a) * 0.25).normalized()
		var base := Vector3(x + cos(a) * 0.35 * s, y, z + sin(a) * 0.35 * s)
		var hgt := (0.9 + 0.35 * (i % 3)) * s
		g.prism(base, 0.16 * s, base + lean * hgt, 0.0, 5, SAPPHIRE.lerp(Color.WHITE, 0.15 * (i % 2)))
	k.merge(g, "glow")
	k.col_cyl(Vector3(x, y, z), 0.55 * s, 1.2 * s)


## A stretch of stone balustrade (no climbing over it).
func _parapet(k, a: Vector3, b: Vector3, hgt := 1.1) -> void:
	var rail = k._tmp()
	var along := b - a
	rail.box((a + b) * 0.5 + Vector3(0, hgt * 0.5, 0), Vector3(maxf(absf(along.x), 0.4), hgt, maxf(absf(along.z), 0.4)), STONE.lerp(CHAR, 0.3))
	k.merge(rail, "stone")
	k.col_box((a + b) * 0.5 + Vector3(0, hgt * 0.5, 0), Vector3(maxf(absf(along.x), 0.4), hgt, maxf(absf(along.z), 0.4))).set_meta("no_climb", true)


## Crenellations round an open rooftop room.
func _crenels(k, rid: String, gaps: Array = []) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid) + float(rooms[rid].h)
	var cr = k._tmp()
	for side in [r.position.y, r.end.y]:
		var x := r.position.x + 1.0
		while x < r.end.x:
			var skip := false
			for gx in gaps:
				if absf(x - float(gx)) < 2.0:
					skip = true
			if not skip:
				cr.box(Vector3(x, y + 0.4, side), Vector3(1.0, 0.8, 0.9), STONE.lerp(CHAR, 0.3))
			x += 2.0
	for side in [r.position.x, r.end.x]:
		var z := r.position.y + 1.0
		while z < r.end.y:
			cr.box(Vector3(side, y + 0.4, z), Vector3(0.9, 0.8, 1.0), STONE.lerp(CHAR, 0.3))
			z += 2.0
	k.merge(cr, "stone")


## A named spot for the Story's cutscenes (World.area_node.find_child(name)).
func _mark(k, mark_name: String, pos: Vector3, yaw := 0.0) -> void:
	var m := Marker3D.new()
	m.name = mark_name
	m.position = pos
	m.rotation.y = yaw
	k._misc.add_child(m)


## A place where the story moves on (StoryTrigger).
func _story_trigger(k, scene: String, r: Rect2, y: float, flag: String, need := "") -> void:
	var a := Area3D.new()
	a.name = "Story_" + scene
	a.set_script(load("res://scripts/systems/story_trigger.gd"))
	a.set("scene", scene)
	a.set("flag", flag)
	a.set("need_flag", need)
	a.position = Vector3(r.get_center().x, y + 1.5, r.get_center().y)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(r.size.x, 3.0, r.size.y)
	cs.shape = box
	a.add_child(cs)
	k._misc.add_child(a)


# --- B2: the dungeons ---------------------------------------------------------------

func _store(k) -> void:
	var y := room_y("store")
	_lamps(k, "store", 1.8)
	for p in [Vector2(-54, -8), Vector2(-50, -8), Vector2(-34, 8), Vector2(-38, 8)]:
		k.crate(p.x, p.y, 0.2, 1.0, y)
	for p in [Vector2(-55.5, 9.5), Vector2(-54.5, 9.5), Vector2(-33.5, -9.5)]:
		k.pot(p.x, p.y, "", false, y)
	k.chest(-44.0, 8.5, PI, "bombs_10", false, D + ":chest_store_bombs", "", y)
	k.chest(-52.0, 2.0, -PI / 2.0, "arrows_10", false, D + ":chest_store_arrows", "", y)


func _prison(k) -> void:
	var y := room_y("prison")
	_lamps(k, "prison", 1.8)
	# The cells along the west wall: iron bars, straw, old bones.
	var bars = k._tmp(false)
	for z in [-44.0, -36.0, -28.0]:
		for i in 12:
			bars.box(Vector3(-52.0, y + 1.6, z - 2.6 + i * 0.47), Vector3(0.08, 3.2, 0.08), Color.html("3a3a44"))
		bars.box(Vector3(-52.0, y + 3.2, z), Vector3(0.12, 0.12, 5.6), Color.html("3a3a44"))
		bars.box(Vector3(-55.0, y + 3.2, z + 2.8), Vector3(6.0, 6.4, 0.3), wall_col * Color(0.6, 0.6, 0.62))
	k.merge(bars, "char")
	k.col_box(Vector3(-52.0, y + 1.6, -36.0), Vector3(0.3, 3.2, 20.0)).set_meta("no_climb", true)
	# The ladder up through the crypt floor (and the hole above it).
	ladder_up(k, 0, -33.0, -40.0, Vector2(-1, 0))
	_crystals(k, -36.0, -46.0, y, 0.9)
	_crystals(k, -33.0, -34.0, y, 0.7)


func _cell(k) -> void:
	var y := room_y("cell")
	var r: Rect2 = rooms.cell.r
	# The bars across the cell door lift when the Warden falls.
	k.flag_bars(-22.4, -27.0, PI / 2.0, D + ":warden_clear", y)
	_torch(k, -9.5, -29.5, y)
	_torch(k, -9.5, -16.5, y)
	# A stone bench along the north wall, straw on the floor.
	k.block(Vector3(-14.0, y + 0.25, -29.6), Vector3(5.0, 0.5, 1.2), 0.0, "stone", wall_col * Color(0.7, 0.7, 0.72)).set_meta("no_climb", true)
	var straw = k._tmp(false)
	for i in 8:
		straw.box(Vector3(-20 + i * 1.4, y + 0.02, -18.0 + (i % 3) * 0.6), Vector3(1.2, 0.04, 0.5), Color.html("b89a5a"))
	k.merge(straw, "char")
	# Pink, Aladriel and Idrith, worn out from holding the castle.
	k.npc("Aladriel", "res://assets/models/aladriel.tscn", "res://scripts/npc/castle_folk_lines.gd", -14.5, -29.3, PI, y, {"turn_body": false, "partner": "Idrith", "seated": true, "idle": "weary"})
	k.npc("Idrith", "res://assets/models/idrith.tscn", "res://scripts/npc/castle_folk_lines.gd", -13.5, -29.3, PI, y, {"turn_body": false, "partner": "Aladriel", "seated": true, "idle": "weary"})
	k.npc("Pink", "res://assets/models/pink.tscn", "res://scripts/npc/castle_folk_lines.gd", -11.5, -25.0, PI / 2.0, y, {"idle": "worried"})
	_mark(k, "cs_rescue_hero", Vector3(-19.0, y, -27.0), -PI / 2.0)
	_mark(k, "cs_rescue_cam", Vector3(-20.5, y + 2.6, -21.0))
	_story_trigger(k, "rescue", Rect2(-20.5, -29.5, 11.0, 13.0), y, D + ":rescued", D + ":warden_clear")
	k.pot(-21.0, -16.0, "heart", false, y)


func _warden(k) -> void:
	var y := room_y("warden")
	k.shutter(-44.0, -62.6, 0.0, "warden", y)
	_lamps(k, "warden", 2.0)
	for p in [Vector2(-52, -80), Vector2(-36, -80), Vector2(-52, -68), Vector2(-36, -68)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	_crystals(k, -56.0, -84.0, y, 1.2)
	_crystals(k, -32.0, -84.0, y, 1.1)
	_banner(k, -44.0, y + 5.5, -85.7, 0.0, 3.5)
	# The cracked wall into the oubliette.
	k.bomb_wall(-29.6, -74.0, PI / 2.0, D + ":oubliette_wall", y)


func _oubliette(k) -> void:
	var y := room_y("oubliette")
	_torch(k, -20.0, -80.0, y)
	var bones = k._tmp(false)
	for i in 6:
		bones.box(Vector3(-18 + i * 1.6, y + 0.05, -70.0 - (i % 3)), Vector3(0.6, 0.08, 0.1), Color.html("e8e0d0"))
	k.merge(bones, "char")
	k.block(Vector3(-14.0, y + 0.5, -78.0), Vector3(2.0, 1.0, 2.0), 0.0, "stone", wall_col * Color(0.7, 0.7, 0.72))
	k.heart_piece(-14.0, -78.0, D + ":heart_piece", y + 1.0)


# --- B1: the cellars ----------------------------------------------------------------

func _guard(k) -> void:
	var y := room_y("guard")
	_lamps(k, "guard", 1.8)
	# The guards' table and stools, knocked over.
	k.block(Vector3(-44.0, y + 0.45, 0.0), Vector3(4.0, 0.9, 1.6), 0.2, "wood", Color(0.6, 0.48, 0.36)).set_meta("no_climb", true)
	k.crate(-50.0, 6.0, 0.4, 1.0, y)
	k.crate(-36.0, -6.0, 0.1, 1.0, y)
	k.chest(-44.0, 8.5, PI, "small_key", false, D + ":chest_key3", D + ":guard_clear", y)
	k.shutter(-44.0, -12.6, 0.0, "guard", y)


func _crypt(k) -> void:
	var y := room_y("crypt")
	_lamps(k, "crypt", 1.8)
	for p in [Vector2(-50, -42), Vector2(-50, -30), Vector2(-38, -42), Vector2(-38, -30)]:
		k.block(Vector3(p.x, y + 0.45, p.y), Vector3(1.2, 0.9, 2.6), 0.0, "stone", wall_col * Color(0.62, 0.62, 0.66))
		k.block(Vector3(p.x, y + 0.98, p.y), Vector3(1.35, 0.16, 2.75), 0.0, "stone", wall_col * Color(0.72, 0.72, 0.76))
	# The ladder on up to the chapel, under its trapdoor; a floor switch opens it.
	ladder_up(k, 1, TRAP_LADDER.x, TRAP_LADDER.y, Vector2(1, 0))
	k.floor_switch(-36.0, -26.5, D + ":trapdoor", y)
	# The hole down to the prison (the prison's ladder comes up through it).
	_banner(k, -44.0, y + 5.0, -47.7, 0.0, 3.0)


func _cistern(k) -> void:
	var y := room_y("cistern")
	_lamps(k, "cistern", 1.8)
	# The pit across the middle; falling in returns the hero to the door.
	k.void_zone(Vector3(0, y - 6.0, CISTERN_PIT.get_center().y), Vector3(CISTERN_PIT.size.x, 2.0, CISTERN_PIT.size.y), 2)
	var stain = k._tmp(false)
	stain.face_dir([Vector3(-16, y - 7.0, -42), Vector3(16, y - 7.0, -42), Vector3(16, y - 7.0, -32), Vector3(-16, y - 7.0, -32)], Color.html("1a1820"), Vector3.UP)
	# The pit's own dark sides, down to the stain.
	var x0 := CISTERN_PIT.position.x
	var x1 := CISTERN_PIT.end.x
	var z0 := CISTERN_PIT.position.y
	var z1 := CISTERN_PIT.end.y
	var lo := y - 7.0
	var hi := y - 0.5
	var side := Color.html("24222a")
	stain.face_dir([Vector3(x0, lo, z0), Vector3(x1, lo, z0), Vector3(x1, hi, z0), Vector3(x0, hi, z0)], side, Vector3(0, 0, 1))
	stain.face_dir([Vector3(x0, lo, z1), Vector3(x1, lo, z1), Vector3(x1, hi, z1), Vector3(x0, hi, z1)], side, Vector3(0, 0, -1))
	stain.face_dir([Vector3(x0, lo, z0), Vector3(x0, lo, z1), Vector3(x0, hi, z1), Vector3(x0, hi, z0)], side, Vector3(1, 0, 0))
	stain.face_dir([Vector3(x1, lo, z0), Vector3(x1, lo, z1), Vector3(x1, hi, z1), Vector3(x1, hi, z0)], side, Vector3(-1, 0, 0))
	k.merge(stain, "char")
	# A low wall along the near rim (one gap where a pod can be planted beyond).
	for p in [Vector3(-16, y, -31.6), Vector3(8, y, -31.6)]:
		_parapet(k, p, p + Vector3(8.0, 0, 0), 0.9)
	k.signpost(-6.0, -29.0, Vector2(-6.0, -24.0), "*The Old Cistern*\nNo bridge, and no hold for a hook\non the far side...\n\nSomething that grows might.")
	_crystals(k, 13.5, -46.5, y, 0.9)
	_crystals(k, -13.5, -47.0, y, 0.8)
	k.pot(13.5, -21.5, "", false, y)
	k.pot(12.5, -21.5, "bombs_5", false, y)


func _wine(k) -> void:
	var y := room_y("wine")
	ladder_up(k, 1, 52.0, -30.0, Vector2(-1, 0))
	_lamps(k, "wine", 1.6)
	for z in [-44.0, -40.0]:
		for x in [36.5, 39.0, 41.5]:
			k.barrel(x, z)
	k.bomb_wall(44.0, -25.6, 0.0, D + ":treasury_wall", y)
	k.pot(52.5, -44.5, "", false, y)
	k.pot(51.5, -44.5, "heart", false, y)


func _treasury(k) -> void:
	var y := room_y("treasury")
	_torch(k, 36.0, 6.0, y)
	_torch(k, 52.0, 6.0, y)
	k.chest(44.0, 4.0, PI, "rupee_red", true, D + ":chest_treasury", "", y)
	for p in [Vector2(37, -10), Vector2(51, -10), Vector2(37, 2), Vector2(51, 2)]:
		k.pot(p.x, p.y, "rupee_blue", true, y)


# --- 1F --------------------------------------------------------------------------

func _gate(k) -> void:
	for z in [23.0, 30.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 6.0, z, 6.5, 0.5, z > 26.0, "stone", 0.0)
	_torch(k, -3.5, 21.5)
	_torch(k, 3.5, 21.5)
	k.rubble(-5.5, 26.0, 0.4, 0.8)
	k.fire(5.5, 27.0, 0.9, 0.0, false)
	# Bombs for the castle (a full bag if the hero never bought one).
	k.chest(-5.5, 31.5, PI / 2.0, "bomb_bag", false, D + ":chest_bombs")
	k.pot(5.5, 32.5)
	k.pot(4.5, 32.5, "heart")


func _hall(k) -> void:
	var up := fy(3)
	for z in [-9.0, -2.0, 5.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 11.0, z, 14.5, 0.8, z == -2.0 and sx > 0.0, "stone", 0.0)
	# The great chandelier, fallen and smashed in the middle of the floor.
	var ch = k._tmp(false)
	ch.prism(Vector3(3, 0.1, -4), 2.4, Vector3(3, 0.35, -4), 2.2, 10, Color.html("6a5a3a"))
	for i in 8:
		var a := TAU * i / 8.0
		ch.prism(Vector3(3 + cos(a) * 2.0, 0.3, -4 + sin(a) * 2.0), 0.05, Vector3(3 + cos(a) * 2.3, 0.9, -4 + sin(a) * 2.3), 0.04, 4, Color.html("8a7a4a"))
	k.merge(ch, "char")
	k.col_cyl(Vector3(3, 0, -4), 2.3, 0.6)
	k.fire(-12.0, 9.0, 1.2, 0.0, true)
	k.fire(13.0, -10.0, 1.0, 0.0, false)
	k.rubble(-13.0, -10.0, 0.6, 1.1)
	for x in [-6.0, 6.0]:
		_banner(k, x, 12.5, -13.7, 0.0, 5.0)
	_torch(k, -16.0, 12.0)
	_torch(k, 16.0, 12.0)
	_torch(k, -16.0, -12.0)
	_crystals(k, 15.5, 11.0, 0.0, 1.0)
	_crystals(k, -15.0, -4.0, 0.0, 0.9)
	k.chest(-8.0, 8.0, PI / 2.0, "map", false, D + ":chest_map")
	k.locked_door(23.0, 0.0, PI / 2.0, D + ":door_key1")
	k.locked_door(0.0, -17.0, 0.0, D + ":door_key2")
	for p in [Vector2(16.5, 12.5), Vector2(-16.5, 0.0), Vector2(16.5, -5.0)]:
		k.pot(p.x, p.y)


func _west(k) -> void:
	var y := room_y("west")
	k.shutter(-30.6, 0.0, PI / 2.0, "west", y)
	_lamps(k, "west", 1.8)
	# Weapon racks along the walls, emptied by the invaders: uprights, a back
	# board and two rails, a few spears the goblins left leaning in them.
	# They stand against the north and south walls (the north one in two
	# lengths either side of the door to the stair).
	for r: Array in [[-44.0, 11.4, 10.0], [-51.5, -11.4, 6.0], [-36.5, -11.4, 6.0]]:
		var cx: float = r[0]
		var z: float = r[1]
		var length: float = r[2]
		var wall_side: float = signf(z)
		var rack = k._tmp(false)
		var wood := Color.html("5a4028")
		rack.box(Vector3(cx, y + 0.9, z + wall_side * 0.22), Vector3(length, 1.8, 0.08), wood.darkened(0.25))
		var posts := int(length / 2.0) + 1
		for i in posts:
			rack.box(Vector3(cx - length * 0.5 + i * length / (posts - 1), y + 0.95, z), Vector3(0.14, 1.9, 0.44), wood)
		for ry: float in [0.5, 1.25]:
			rack.box(Vector3(cx, y + ry, z - wall_side * 0.16), Vector3(length, 0.09, 0.12), wood.lightened(0.08))
		for sx: float in [cx - length * 0.3, cx + length * 0.05, cx + length * 0.32]:
			rack.prism(Vector3(sx, y + 0.02, z - wall_side * 0.12), 0.035, Vector3(sx + 0.15, y + 2.1, z + wall_side * 0.12), 0.03, 5, Color.html("6a4a2a"))
			rack.prism(Vector3(sx + 0.15, y + 2.1, z + wall_side * 0.12), 0.05, Vector3(sx + 0.17, y + 2.35, z + wall_side * 0.13), 0.0, 4, Color.html("a8a8b0"))
		k.merge(rack, "char")
		k.col_box(Vector3(cx, y + 0.95, z), Vector3(length + 0.2, 1.9, 0.56)).set_meta("no_climb", true)
	k.chest(-36.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key1", D + ":west_clear", y)
	# The royal Iron Mallet, too heavy for the goblins to carry off: its chest
	# by the far wall (Chapter II, once Pink has told him of it).
	k.chest(-54.0, -3.0, -PI / 2.0, "iron_mallet", true, D + ":chest_iron_mallet", "ch2:shelter_met", y)
	# The ladder up into the library.
	ladder_up(k, 2, -56.0, 8.0, Vector2(1, 0))
	k.pot(-56.5, -10.0, "arrows_10", false, y)
	k.pot(-55.5, -10.0, "", false, y)


func _east(k) -> void:
	var y := room_y("east")
	_lamps(k, "east", 1.8)
	# The kitchens: hearths still burning, tables, pots.
	# (Clear of the cracked wall at x 44, which a hearth used to block.)
	for x in [35.0, 39.5, 52.0]:
		k.block(Vector3(x, y + 1.0, -11.2), Vector3(3.0, 2.0, 1.2), 0.0, "stone", wall_col * Color(0.55, 0.5, 0.5))
		k.fire(x, -10.8, 0.7, y + 0.2, x == 39.5)
	k.block(Vector3(44, y + 0.45, 2.0), Vector3(8.0, 0.9, 1.8), 0.0, "wood", Color(0.62, 0.5, 0.38)).set_meta("no_climb", true)
	# The cracked wall across the way north to the pantry.
	k.bomb_wall(44.0, -12.4, PI, D + ":kitchen_wall", y)
	# The ladder up into the solar.
	ladder_up(k, 2, 56.0, 8.0, Vector2(-1, 0))
	for p in [Vector2(32.0, 10.5), Vector2(33.0, 10.5), Vector2(55.5, -2.0)]:
		k.pot(p.x, p.y, "", false, y)


func _pantry(k) -> void:
	var y := room_y("pantry")
	_lamps(k, "pantry", 1.6)
	for p in [Vector2(36.5, -44.0), Vector2(36.5, -40.0), Vector2(41.0, -44.0)]:
		k.crate(p.x, p.y, 0.3, 1.0, y)
	k.chest(44.0, -43.5, 0.0, "rupee_red", false, D + ":chest_pantry", "", y)
	k.pot(36.5, -28.0, "bombs_5", false, y)


func _chapel(k) -> void:
	var y := room_y("chapel")
	_torch(k, -56.0, -26.5, y)
	_torch(k, -32.0, -26.5, y)
	# Pews, overturned; the altar under the broken roof's sunbeam.
	for z in [-32.0, -28.5]:
		for sx in [-1.0, 1.0]:
			k.block(Vector3(-44.0 + sx * 6.0, y + 0.4, z), Vector3(7.0, 0.8, 0.6), 0.0, "wood", Color(0.6, 0.48, 0.36)).set_meta("no_climb", true)
	k.block(Vector3(-44.0, y + 0.55, -45.5), Vector3(4.0, 1.1, 1.6), 0.0, "stone", Color(0.95, 0.93, 0.9))
	# Light through the hole in the roof; the sun carved on the east wall wakes
	# to it (turn the Mirror Shield toward it).
	k.sun_shaft(-44.0, -38.0, y, 6.4, "", 1.6)
	k.sun_switch(Vector3(-30.12, y + 1.3, -38.0), PI / 2.0, D + ":chapel_sun")
	k.chest(-50.0, -44.0, PI / 2.0, "small_key", false, D + ":chest_key2", D + ":chapel_sun", y)
	# The trapdoor over the ladder up from the crypt (opened from below).
	var trap := ladder_hole(TRAP_LADDER.x, TRAP_LADDER.y, Vector2(1, 0))
	var lid: Node3D = k._dyn("res://scripts/dungeon/flag_mover.gd", "Trapdoor", Vector3(trap.get_center().x + 2.8, y - 0.13, trap.get_center().y), 0.0,
		{"flag": D + ":trapdoor", "offset": Vector3(-2.8, 0, 0), "time": 0.8}, AnimatableBody3D.new())
	var lk := MK.new(77)
	lk.box(Vector3.ZERO, Vector3(2.8, 0.3, 2.8), Color(0.55, 0.42, 0.3))
	var lmi := MeshInstance3D.new()
	lmi.mesh = lk.build(k.M.wood)
	lid.add_child(lmi)
	var lcs := CollisionShape3D.new()
	var lbox := BoxShape3D.new()
	lbox.size = Vector3(2.8, 0.3, 2.8)
	lcs.shape = lbox
	lcs.set_meta("no_climb", true)
	lid.add_child(lcs)
	for x in [-50.0, -38.0]:
		_banner(k, x, y + 5.5, -47.7, 0.0, 3.0)


func _court(k) -> void:
	var y := room_y("court")
	var r: Rect2 = rooms.court.r
	# The burnt garden: dead hedges, a dry fountain, scorched trees.
	k.fountain(0.0, -35.0, 3.5, y)
	for p in [Vector2(-11, -26), Vector2(11, -26), Vector2(-11, -44), Vector2(11, -44)]:
		k.tree_dead(p.x, p.y, 1.1)
	for p in [Vector2(-6, -24), Vector2(6, -46)]:
		k.rubble(p.x, p.y, 0.3, 0.8)
	# The way into the keep, barred: two dark braziers either side of it, and
	# a burning one across the garden (shoot an arrow through it into them).
	for i in 2:
		var sx := -1.0 if i == 0 else 1.0
		k.torch(sx * 3.5, -47.5, false, D + ":court_torch_%d" % i, y)
	k.torch(0.0, -23.0, true, "", y)
	k.flag_all([D + ":court_torch_0", D + ":court_torch_1"], D + ":keep_open")
	k.flag_bars(0.0, -50.4, 0.0, D + ":keep_open", y)
	_crenels(k, "court")
	k.fire(-13.5, -48.0, 1.0, y, true)
	k.fire(13.0, -22.0, 0.8, y, false)


func _keep(k) -> void:
	var y := room_y("keep")
	k.stairs(0.0, -64.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(0.0, y + FLOOR_H * 0.5, -80.5), Vector3(6.0, FLOOR_H, 11.0), 0.0, "stone", wall_col * Color(0.8, 0.78, 0.78))
	_lamps(k, "keep", 1.8)
	_torch(k, -2.4, -84.5, y + FLOOR_H)
	_torch(k, 2.4, -84.5, y + FLOOR_H)
	_banner(k, -8.0, y + 6.0, -85.7, 0.0, 4.0)
	_banner(k, 8.0, y + 6.0, -85.7, 0.0, 4.0)


# --- 2F --------------------------------------------------------------------------

func _library(k) -> void:
	var y := room_y("library")
	_lamps(k, "library", 1.6)
	# Shelves along the walls, half of them burning.
	var shelf = k._tmp()
	for z in [-11.4, 11.4]:
		shelf.box(Vector3(-44, y + 1.6, z), Vector3(24.0, 3.2, 0.8), Color(0.55, 0.4, 0.28))
	k.merge(shelf, "wood")
	for z in [-11.4, 11.4]:
		k.col_box(Vector3(-44, y + 1.6, z), Vector3(24.0, 3.2, 0.8)).set_meta("no_climb", true)
	k.fire(-50.0, -10.0, 0.8, y + 3.2, true)
	k.fire(-38.0, 10.0, 0.8, y + 3.2, false)
	k.book(Vector3(-44.0, y + 0.95, 0.0), 0.0, "Annals of Haven", [
		"*The Three Fortresses*\nThe Citadel of Haven was raised in three rings of wall, so that no foe might take it in a day.",
		"*Of the Gauntlet*\nIt is written in Bunsriel's Dark Prophecy that a king who has died shall rise, and every flame shall bow to him.",
		"...the rest of the page is burnt away.",
	])
	k.block(Vector3(-44.0, y + 0.45, 0.0), Vector3(2.0, 0.9, 1.2), 0.0, "wood", Color(0.6, 0.48, 0.36)).set_meta("no_climb", true)
	k.chest(-34.0, 0.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", y)


func _solar(k) -> void:
	var y := room_y("solar")
	_lamps(k, "solar", 1.6)
	# Two switches on top of tall cabinets: grow bloom-pods on them.
	for s in [[36.0, -6.0, "solar_w"], [52.0, -6.0, "solar_e"]]:
		k.block(Vector3(s[0], y + 1.6, s[1]), Vector3(1.2, 3.2, 1.2), 0.0, "wood", Color(0.5, 0.38, 0.26)).set_meta("no_climb", true)
		k.floor_switch(s[0], s[1], D + ":" + s[2], y + 3.2)
	k.flag_all([D + ":solar_w", D + ":solar_e"], D + ":solar_open")
	k.chest(44.0, -9.0, 0.0, "bombs_10", true, D + ":chest_solar", D + ":solar_open", y)
	k.block(Vector3(44.0, y + 0.3, 6.0), Vector3(4.0, 0.6, 2.4), 0.0, "wood", Color(0.62, 0.3, 0.3)).set_meta("no_climb", true)


func _barracks(k) -> void:
	var y := room_y("barracks")
	for s in [[0.0, -96.6, 0.0], [-12.6, -108.0, PI / 2.0], [12.6, -108.0, PI / 2.0]]:
		k.shutter(s[0], s[1], s[2], "barracks", y)
	_lamps(k, "barracks", 1.8)
	for z in [-116.0, -112.0, -104.0, -100.0]:
		for sx in [-1.0, 1.0]:
			k.block(Vector3(sx * 8.5, y + 0.3, z), Vector3(3.0, 0.6, 1.4), 0.0, "wood", Color(0.6, 0.48, 0.36)).set_meta("no_climb", true)
	k.locked_door(16.0, -108.0, PI / 2.0, D + ":door_key3", false, y)


func _war(k) -> void:
	var y := room_y("war")
	_lamps(k, "war", 1.6)
	# The map table of Haven, a model of the castle on it.
	k.block(Vector3(-35.0, y + 0.5, -108.0), Vector3(6.0, 1.0, 4.0), 0.0, "wood", Color(0.55, 0.42, 0.3)).set_meta("no_climb", true)
	var model = k._tmp(false)
	model.box(Vector3(-35.0, y + 1.1, -108.0), Vector3(5.6, 0.04, 3.6), Color.html("6a8a4a"))
	model.box(Vector3(-35.0, y + 1.3, -108.6), Vector3(1.2, 0.4, 1.0), Color.html("d8d4cc"))
	model.box(Vector3(-35.0, y + 1.6, -108.6), Vector3(0.4, 0.6, 0.4), Color.html("d8d4cc"))
	k.merge(model, "char")
	_banner(k, -35.0, y + 5.5, -119.7, 0.0, 3.5)
	k.chest(-43.0, -100.0, -PI / 2.0, "rupee_red", false, D + ":chest_war", "", y)
	k.pot(-44.5, -118.0, "heart", false, y)
	k.pot(-26.0, -118.0, "", false, y)


func _bell(k) -> void:
	var y := room_y("bell")
	k.stairs(35.0, -98.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(35.0, y + FLOOR_H * 0.5, -114.5), Vector3(6.0, FLOOR_H, 11.0), 0.0, "stone", wall_col * Color(0.8, 0.78, 0.78))
	_lamps(k, "bell", 1.6)
	# The great bell, fallen to the floor and cracked.
	var bell = k._tmp(false)
	bell.prism(Vector3(28.0, y, -104.0), 1.6, Vector3(28.0, y + 2.2, -104.0), 0.9, 12, Color.html("a88a4a"))
	bell.prism(Vector3(28.0, y + 2.2, -104.0), 0.9, Vector3(28.0, y + 2.6, -104.0), 0.3, 12, Color.html("8a6a3a"))
	k.merge(bell, "char")
	k.col_cyl(Vector3(28.0, y, -104.0), 1.6, 2.6)


# --- 3F --------------------------------------------------------------------------

func _rampart_e(k) -> void:
	var y := room_y("rampart_e")
	var r: Rect2 = rooms.rampart_e.r
	_crenels(k, "rampart_e", [36.0, 38.0])
	# The east side has fallen away: a gale off the burning town blows across
	# the walk toward the gap (the Wind Boots hold the hero fast).
	k.void_zone(Vector3(r.end.x + 3.0, y - 6.0, r.get_center().y), Vector3(6.0, 2.0, r.size.y), 2)
	k.block(Vector3(r.end.x - 0.4, y + 0.3, r.get_center().y), Vector3(0.8, 0.6, r.size.y), 0.0, "stone", STONE.lerp(CHAR, 0.3)).set_meta("no_climb", true)
	k.wind_zone(Vector3(r.get_center().x, y + 1.5, r.get_center().y), Vector3(r.size.x - 2.0, 3.0, r.size.y - 4.0), Vector3(1, 0, 0), 6.0)
	for p in [Vector2(28.0, -148.0), Vector2(28.0, -136.0)]:
		k.fire(p.x, p.y, 0.9, y, p.y > -140.0)
	k.rubble(40.0, -150.0, 0.2, 0.8)


func _keep3(k) -> void:
	var y := room_y("keep3")
	_lamps(k, "keep3", 1.8)
	for p in [Vector2(-6, -148), Vector2(6, -148), Vector2(-6, -136), Vector2(6, -136)]:
		k.pillar(p.x, p.y, 6.5, 0.55, false, "stone", y)
	_crystals(k, 0.0, -142.0, y, 1.3)
	k.locked_door(0.0, -158.0, 0.0, D + ":door_key4", false, y)
	_banner(k, -8.0, y + 5.5, -153.7, 0.0, 3.0)
	_banner(k, 8.0, y + 5.5, -153.7, 0.0, 3.0)


func _rampart_w(k) -> void:
	var y := room_y("rampart_w")
	_crenels(k, "rampart_w")
	# Sunlight through the smoke; a bronze mirror to turn it onto the sun
	# carved on the tower wall. It starts facing the light (throwing it straight
	# back); two turns swing its face round to the sun.
	k.sun_shaft(-42.0, -134.0, y, 8.0, "", 1.6)
	k.light_mirror(-28.0, -134.0, PI / 2.0, y, false, -1)
	k.sun_switch(Vector3(-28.0, y + 1.3, -153.88), PI, D + ":rampart_sun")
	k.chest(-40.0, -150.0, 0.0, "small_key", false, D + ":chest_key4", D + ":rampart_sun", y)
	k.fire(-44.0, -150.0, 0.8, y, true)


func _stair(k) -> void:
	var y := room_y("stair")
	k.stairs(0.0, -166.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(0.0, y + FLOOR_H * 0.5, -182.5), Vector3(6.0, FLOOR_H, 11.0), 0.0, "stone", wall_col * Color(0.8, 0.78, 0.78))
	_lamps(k, "stair", 1.8)
	_torch(k, -2.4, -186.5, y + FLOOR_H)
	_torch(k, 2.4, -186.5, y + FLOOR_H)


# --- 4F --------------------------------------------------------------------------

func _roof(k) -> void:
	var y := room_y("roof")
	var r: Rect2 = rooms.roof.r
	k.shutter(0.0, r.end.y - 0.6, 0.0, "roof", y)
	k.shutter(0.0, r.position.y + 0.6, 0.0, "roof", y)
	_crenels(k, "roof")
	for p in [Vector2(-16, -222), Vector2(16, -222), Vector2(-16, -198), Vector2(16, -198)]:
		_torch(k, p.x, p.y, y)
	for p in [Vector2(-10, -212), Vector2(10, -206)]:
		k.rubble(p.x, p.y, 0.5, 0.9)
	# Two broken chimney stacks for cover from its fire.
	for p in [Vector3(-12.0, y, -208.0), Vector3(12.0, y, -214.0)]:
		k.block(Vector3(p.x, y + 1.2, p.z), Vector3(1.6, 2.4, 1.6), 0.0, "stone", STONE.lerp(CHAR, 0.4)).set_meta("no_climb", true)


func _ante(k) -> void:
	var y := room_y("ante")
	k.stairs(0.0, -232.0, 0.0, 3.0, 9.5, FLOOR_H, "stone", y)
	k.block(Vector3(0.0, y + FLOOR_H * 0.5, -243.75), Vector3(6.0, FLOOR_H, 4.5), 0.0, "stone", wall_col * Color(0.8, 0.78, 0.78))
	_lamps(k, "ante", 1.6)
	_torch(k, -2.4, -244.5, y + FLOOR_H)
	_torch(k, 2.4, -244.5, y + FLOOR_H)
	k.locked_door(0.0, -248.0, 0.0, D + ":boss_door", true, fy(6))


# --- 5F --------------------------------------------------------------------------

func _throne(k) -> void:
	var y := room_y("throne")
	var r: Rect2 = rooms.throne.r
	k.shutter(0.0, r.end.y - 0.6, 0.0, "throne", y)
	# The dais and the throne of Haven, its back to the burning sky.
	k.block(Vector3(0.0, y + 0.25, -278.0), Vector3(10.0, 0.5, 6.0), 0.0, "stone", Color(0.9, 0.88, 0.86))
	var th = k._tmp()
	th.box(Vector3(0.0, y + 0.8, -279.2), Vector3(1.8, 0.6, 1.4), Color(0.75, 0.6, 0.3))
	th.box(Vector3(0.0, y + 2.6, -279.9), Vector3(1.8, 3.4, 0.3), Color(0.75, 0.6, 0.3))
	th.box(Vector3(0.0, y + 4.4, -279.9), Vector3(2.4, 0.5, 0.4), Color(0.85, 0.7, 0.35))
	for sx in [-1.0, 1.0]:
		th.box(Vector3(sx * 0.9, y + 1.3, -279.2), Vector3(0.2, 0.6, 1.4), Color(0.75, 0.6, 0.3))
	k.merge(th, "wood")
	k.col_box(Vector3(0.0, y + 2.0, -279.5), Vector3(2.0, 4.0, 1.6)).set_meta("no_climb", true)
	for z in [-270.0, -262.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 9.0, z, 9.0, 0.7, z == -262.0 and sx < 0.0, "stone", y)
	for sx in [-1.0, 1.0]:
		k.fire(sx * 13.0, -280.0, 1.5, y, true)
		k.fire(sx * 13.0, -258.0, 1.2, y, false)
		_banner(k, sx * 5.0, y + 7.5, -283.7, 0.0, 6.0)
	_crenels(k, "throne", [0.0])
	_mark(k, "cs_throne_cam", Vector3(4.5, y + 2.6, -262.0))
	_mark(k, "cs_throne_hero", Vector3(0.0, y, -262.0), 0.0)
	_mark(k, "cs_throne_door", Vector3(0.0, y, -253.0), 0.0)
	_story_trigger(k, "throne_room", Rect2(-15.0, -266.0, 30.0, 10.0), y, D + ":throne_seen")


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b2 := fy(0)
	var b1 := fy(1)
	var f2 := fy(3)
	var f3 := fy(4)
	var f4 := fy(5)
	var f5 := fy(6)
	k.enemy("basic_enemy", -3.0, 26.0, 0.0, {"room": "gate"})
	k.enemy("fire_keese", 3.0, 24.0, 0.0, {"room": "gate"}, 3.5)
	k.enemy("basic_enemy", -8.0, -6.0, 0.0, {"room": "hall"})
	k.enemy("basic_enemy", 8.0, 4.0, 0.0, {"room": "hall"})
	k.enemy("sapphire_mage", 0.0, -8.0, 0.0, {"room": "hall", "roam": 7.0})
	k.enemy("fire_keese", -6.0, 6.0, 0.0, {"room": "hall"}, 7.0)
	k.enemy("sapphire_knight", -44.0, 0.0, -PI / 2.0, {"room": "west"})
	k.enemy("basic_enemy", -50.0, -6.0, 0.0, {"room": "west"})
	k.enemy("basic_enemy", -50.0, 6.0, 0.0, {"room": "west"})
	k.enemy("sapphire_mage", 44.0, 4.0, 0.0, {"room": "east", "roam": 5.0})
	k.enemy("fire_keese", 38.0, -4.0, 0.0, {"room": "east"}, 4.0)
	k.enemy("charred_stalfos", 44.0, -38.0, 0.0, {"room": "pantry"})
	k.enemy("rat", 40.0, -40.0, 0.0, {"room": "wine"}, b1)
	k.enemy("rat", 48.0, -34.0, 0.0, {"room": "wine"}, b1)
	k.enemy("keese", 44.0, -42.0, 0.0, {"room": "wine"}, b1 + 4.0)
	k.enemy("sapphire_mage", 0.0, -46.0, 0.0, {"room": "cistern", "roam": 4.0}, b1)
	k.enemy("fire_keese", -8.0, -28.0, 0.0, {"room": "cistern"}, b1 + 4.0)
	k.enemy("charred_stalfos", -44.0, -40.0, 0.0, {"room": "crypt"}, b1)
	k.enemy("charred_stalfos", -40.0, -28.0, 0.0, {"room": "crypt"}, b1)
	k.enemy("sapphire_mage", -44.0, 0.0, 0.0, {"room": "guard", "roam": 6.0}, b1)
	k.enemy("basic_enemy", -50.0, 4.0, 0.0, {"room": "guard"}, b1)
	k.enemy("basic_enemy", -38.0, -4.0, 0.0, {"room": "guard"}, b1)
	k.enemy("sapphire_mage", -40.0, -36.0, 0.0, {"room": "prison", "roam": 5.0}, b2)
	k.enemy("rat", -36.0, -30.0, 0.0, {"room": "prison"}, b2)
	k.enemy("rat", -38.0, -44.0, 0.0, {"room": "prison"}, b2)
	k.enemy("rat", -46.0, -6.0, 0.0, {"room": "store"}, b2)
	k.enemy("keese", -40.0, 4.0, 0.0, {"room": "store"}, b2 + 4.0)
	k.enemy("sapphire_warden", -44.0, -76.0, 0.0, {"room": "warden"}, b2)
	k.enemy("charred_stalfos", -44.0, -44.0, 0.0, {"room": "chapel"})
	k.enemy("fire_keese", -6.0, -30.0, 0.0, {"room": "court"}, 4.0)
	k.enemy("fire_keese", 6.0, -40.0, 0.0, {"room": "court"}, 4.0)
	k.enemy("basic_enemy", -8.0, -40.0, 0.0, {"room": "court"})
	k.enemy("fire_keese", -4.0, -72.0, 0.0, {"room": "keep"}, 6.0)
	k.enemy("sapphire_mage", -50.0, 0.0, 0.0, {"room": "library", "roam": 5.0}, f2)
	k.enemy("fire_keese", 44.0, 4.0, 0.0, {"room": "solar"}, f2 + 3.5)
	k.enemy("sapphire_knight", 0.0, -112.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", -6.0, -104.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", 6.0, -104.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("sapphire_mage", -35.0, -114.0, 0.0, {"room": "war", "roam": 4.0}, f2)
	k.enemy("fire_keese", 30.0, -110.0, 0.0, {"room": "bell"}, f2 + 6.0)
	k.enemy("fire_keese", 40.0, -104.0, 0.0, {"room": "bell"}, f2 + 9.0)
	k.enemy("charred_stalfos", 30.0, -142.0, 0.0, {"room": "rampart_e"}, f3)
	k.enemy("sapphire_mage", 0.0, -142.0, 0.0, {"room": "keep3", "roam": 5.0}, f3)
	k.enemy("sapphire_knight", 0.0, -138.0, 0.0, {"room": "keep3"}, f3)
	k.enemy("charred_stalfos", -36.0, -146.0, 0.0, {"room": "rampart_w"}, f3)
	k.enemy("fire_keese", -4.0, -176.0, 0.0, {"room": "stair"}, f3 + 6.0)
	k.enemy("cinder_wyvern", 0.0, -212.0, 0.0, {"room": "roof"}, f4 + 4.0)
	k.enemy("sapphire_mage", 0.0, -238.0, 0.0, {"room": "ante", "roam": 2.5}, f4)
	k.enemy("firebuns", 0.0, -277.6, PI, {"room": "throne"}, f5 + 0.5)
