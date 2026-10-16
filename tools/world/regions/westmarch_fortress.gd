extends "res://tools/world/tower_region.gd"
## Westmarch Fortress, the last of the Citadel of Haven's three fortresses
## (Chapter IV's first dungeon): gray royal stone, Haven blue banners torn,
## the yard full of goblins, Firebuns' war banners on the walls, Idrith and
## Aladriel holding out in the great hall. Its prizes are the Anchor Boots
## (the armory) and the Sapphire Staff (taken from the Order battle-mage in
## the west tower); its master is Grukk the Siegebreaker, on the keep roof.
##
## Storeys (north is -Z; W, C, E, N name the columns):
##   B1 (y -8)  cells W     the garrison's cells: a fight; three soldiers
##              cistern C   the flooded cistern: octoroks; an underwater
##                          plate (the Anchor Boots) opens the tunnel north
##              cellar E    rats; the ladder up to the mess; a cracked wall
##              store NE    behind it: rupees and a treasure chart
##              sunken N    beyond the tunnel: Small Key 2 on a ledge
##   1F (y 0)   gate S      in from the field
##              yard C      open sky: goblins, archers, a boar rider
##              stables W   a fight -> Small Key 1; ladders up and down
##              mess E      the Map; down to the cellar, up to the barracks
##              hall N      (Small Key 1) Idrith and Aladriel; a ladder up
##              chapel NW   the Compass
##              smithy NE   a Piece of Heart on a high shelf (Hookshot)
##   2F (y 8)   armory W   a fight -> the Anchor Boots
##              mage NW     (Small Key 2) the Order battle-mage -> the Staff
##              weights N   two iron weight plates -> the Boss Key
##              barracks E  a fight -> Small Key 3
##              keyroom NE  (Small Key 3) the ladder up to the roof
##   3F (y 16)  ante NE     the boss door
##              roof N      Grukk the Siegebreaker; then the fortress falls

const D := "westmarch_fortress"
const STONE := Color(0.8, 0.78, 0.76)
const DARK := Color(0.6, 0.58, 0.58)
const WATER_Y := -5.2
const LADDERS := [
	[0, -23.0, 6.0, Vector2(-1, 0)], [0, 23.0, 6.0, Vector2(1, 0)],
	[1, -23.0, -6.0, Vector2(-1, 0)], [1, 23.0, -6.0, Vector2(1, 0)],
	[1, 8.0, -44.0, Vector2(0, 1)], [2, 36.0, -26.0, Vector2(0, -1)],
]


func setup() -> void:
	id = "westmarch_fortress"
	interior = true
	seed_value = 1616
	x_min = -46.0
	x_max = 46.0
	z_min = -56.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0]]
	entry_floor = 1
	wall_col = STONE
	ceil_col = Color(0.32, 0.3, 0.3)
	slab_col = Color(0.78, 0.76, 0.72)
	var burnt := Color(0.7, 0.64, 0.6)
	rooms = {
		# B1
		"cells": {"f": 0, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": DARK},
		"cistern": {"f": 0, "r": Rect2(-15, -14, 30, 28), "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "col": DARK},
		"cellar": {"f": 0, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}, {"side": "n", "at": 30.0}], "col": DARK},
		"sunken": {"f": 0, "r": Rect2(-10, -48, 20, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": DARK.darkened(0.1)},
		"store": {"f": 0, "r": Rect2(21, -46, 18, 18), "h": 6.0, "doors": [{"side": "s", "at": 30.0}], "col": DARK},
		# 1F
		"gate": {"f": 1, "r": Rect2(-7, 18, 14, 12), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}], "col": burnt},
		"yard": {"f": 1, "r": Rect2(-15, -14, 30, 28), "h": 6.0, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "ceiling": false, "col": burnt},
		"stables": {"f": 1, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "floor_mat": "wood", "floor_col": Color(0.7, 0.58, 0.42)},
		"mess": {"f": 1, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "floor_mat": "wood", "floor_col": Color(0.7, 0.58, 0.42)},
		"hall": {"f": 1, "r": Rect2(-12, -48, 24, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": -36.0}, {"side": "e", "at": -36.0}]},
		"chapel": {"f": 1, "r": Rect2(-40, -46, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": -36.0}], "col": Color(0.88, 0.86, 0.84)},
		"smithy": {"f": 1, "r": Rect2(20, -46, 20, 20), "h": 6.5, "doors": [{"side": "w", "at": -36.0}], "col": burnt.darkened(0.1)},
		# 2F
		"armoury": {"f": 2, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "n", "at": -30.0}]},
		"mage": {"f": 2, "r": Rect2(-40, -46, 20, 24), "h": 6.5, "doors": [{"side": "s", "at": -30.0}, {"side": "e", "at": -34.0}], "col": Color(0.72, 0.74, 0.86)},
		"weights": {"f": 2, "r": Rect2(-12, -46, 24, 24), "h": 6.5, "doors": [{"side": "w", "at": -34.0}, {"side": "e", "at": -34.0}]},
		"barracks": {"f": 2, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "n", "at": 30.0}], "floor_mat": "wood", "floor_col": Color(0.7, 0.58, 0.42)},
		"keyroom": {"f": 2, "r": Rect2(20, -46, 20, 24), "h": 6.0, "doors": [{"side": "s", "at": 30.0}, {"side": "w", "at": -34.0}]},
		# 3F
		"ante": {"f": 3, "r": Rect2(20, -46, 20, 24), "h": 6.0, "doors": [{"side": "w", "at": -34.0}]},
		"boss": {"f": 3, "r": Rect2(-18, -52, 34, 32), "h": 4.0, "doors": [{"side": "e", "at": -34.0}], "ceiling": false, "col": burnt},
	}
	corridors = [
		{"f": 0, "r": Rect2(-20, -2, 5, 4), "x": true},
		{"f": 0, "r": Rect2(15, -2, 5, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -28, 4, 14), "x": false},
		{"f": 0, "r": Rect2(28, -28, 4, 18), "x": false},
		{"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-20, -2, 5, 4), "x": true},
		{"f": 1, "r": Rect2(15, -2, 5, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -24, 4, 10), "x": false},
		{"f": 1, "r": Rect2(-20, -38, 8, 4), "x": true},
		{"f": 1, "r": Rect2(12, -38, 8, 4), "x": true},
		{"f": 2, "r": Rect2(-32, -22, 4, 12), "x": false},
		{"f": 2, "r": Rect2(-20, -36, 8, 4), "x": true},
		{"f": 2, "r": Rect2(12, -36, 8, 4), "x": true},
		{"f": 2, "r": Rect2(28, -22, 4, 12), "x": false},
		{"f": 3, "r": Rect2(16, -36, 4, 4), "x": true},
	]
	holes = []
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	mood = {
		"sky_top": Color.html("2a1e22"), "sky_mid": Color.html("6a3a2a"), "sky_horizon": Color.html("c06a3a"),
		"cloud": Color.html("4a3028"), "cloud_amount": 0.7,
		"fog": Color.html("3a2a26"), "fog_begin": 14.0, "fog_end": 70.0,
		"ambient": Color.html("6a5a58"), "sun": Color.html("ffc090"), "sun_rot": Vector3(-55, 40, 0),
		"sun_energy": 0.7, "fill": Color.html("4a4a6a"), "fill_energy": 0.4,
		"horizon": Color.html("3a2420"), "hill_height": 0.0, "particles": "embers",
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


## Big gray flagstones; straw in the stables, rushes in the hall, the
## cistern's floor slimed green.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["0c0a0a", "100e0e"])
	var p := Vector2(x, z)
	if f == 0 and ((rooms.cistern.r as Rect2).has_point(p) or (rooms.sunken.r as Rect2).has_point(p) or Rect2(-2, -28, 4, 14).has_point(p)):
		return Color.html(["2e3a2a", "34402e", "2a3426"][r.randi() % 3])
	if f == 1 and (rooms.yard.r as Rect2).has_point(p):
		return Color.html(["6a6058", "5e5650", "726860", "4a4440"][r.randi() % 4])
	if f == 1 and (rooms.hall.r as Rect2).has_point(p) and absf(x) < 2.5:
		return Color.html("6a2a2a").darkened(r.randf_range(0.0, 0.1))
	var seam := fposmod(x, 2.4) < 0.1 or fposmod(z + (1.2 if int(floor(x / 2.4)) % 2 == 0 else 0.0), 2.4) < 0.1
	if seam:
		return Color.html("3a3634")
	return Color.html(["8a8680", "807c76", "908c86"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08) + 0.05 * (2 - f))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "field", "from_westmarch_fortress", Color(0.62, 0.52, 0.42))
	k.entrance("from_field", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	k.water_plane(Rect2(-15, -48, 30, 62), WATER_Y, Color(0.22, 0.32, 0.28, 0.8))
	_b1(k)
	_f1(k)
	_f2(k)
	_f3(k)


func _torch(k, x: float, z: float, y: float) -> void:
	k.torch(x, z, true, "", y)


func _torches(k, rid: String, inset := 1.8) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


func _haven_banner(k, x: float, y: float, z: float, yaw: float) -> void:
	k.banner(x, y, z, yaw, Color.html("2a4a9a"), 2.6)


# --- B1 -------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(0)
	# The cells: bars across three cells along the west wall, the soldiers
	# behind them; they lift when the warders fall.
	k.shutter(-20.6, 0.0, PI / 2.0, "cells", y)
	for z in [-6.0, 0.0, 6.0]:
		k.block(Vector3(-34.0, y + 1.5, z + 2.9), Vector3(10.0, 3.0, 0.4), 0.0, "stone", DARK)
		k.flag_bars(-29.2, z, PI / 2.0, D + ":cells_clear", y)
		# The cell front either side of the bars (the bars are 2.4 m wide).
		for s in [-1.0, 1.0]:
			k.block(Vector3(-29.2, y + 1.5, z + s * 2.0), Vector3(0.4, 3.0, 1.6), 0.0, "stone", DARK)
	k.block(Vector3(-34.0, y + 1.5, -8.9), Vector3(10.0, 3.0, 0.4), 0.0, "stone", DARK)
	_torches(k, "cells")
	# The cistern: stepping stones and a walk round the edge; the plate under
	# the water at the north end (only the Anchor Boots stand on it).
	for p in [Vector2(-5, 6), Vector2(4, -2), Vector2(-3, -8)]:
		k.platform(p.x, p.y, Vector2(2.4, 2.4), WATER_Y + 0.5, "stone", DARK.darkened(0.1))
	k._dyn("res://scripts/dungeon/hold_switch.gd", "TunnelPlate", Vector3(0, y, -11.5), 0.0, {"result": D + ":tunnel_open", "footing": true}, Area3D.new())
	k.flag_bars(0.0, -14.3, 0.0, D + ":tunnel_open", y)
	# The lintel over the tunnel's mouth: under water, the only way is down.
	k.block(Vector3(0, -5.0, -15.0), Vector3(4.4, 2.0, 1.2), 0.0, "stone", DARK)
	k.examine(Vector3(4.0, WATER_Y + 0.5, -2.0), PI, [{"text": "Chalked on the cistern wall by some bored guard:\n*THE OLD TUNNEL GATE OPENS FROM THE BOTTOM. GOOD LUCK SWIMMING DOWN THERE IN IRON.*", "instant": true}])
	# The cellar: barrels; the cracked wall north to the old store.
	for p in [Vector2(36, -7), Vector2(37, -4), Vector2(36, 7)]:
		k.barrel(p.x, p.y)
	k.bomb_wall(30.0, -10.4, 0.0, D + ":store_wall", y)
	_torches(k, "cellar")
	k.chest(30.0, -42.0, 0.0, "chart_3", false, D + ":chest_chart", "", y)
	k.chest(24.0, -42.0, 0.0, "rupee_red", false, D + ":chest_store", "", y)
	k.pot(36.0, -42.0, "bombs_5", false, y)
	_torches(k, "store")
	# The sunken room: a ledge above the water, Small Key 2 on it.
	k.platform(0.0, -44.0, Vector2(10.0, 4.0), WATER_Y + 0.7, "stone", DARK)
	k.chest(0.0, -44.5, 0.0, "small_key", false, D + ":chest_key2", "", WATER_Y + 0.7)


# --- 1F -------------------------------------------------------------------------

func _f1(k) -> void:
	var y := fy(1)
	# The gate passage in from the field.
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 5.0, z, 6.0, 0.45, false, "stone", y)
	k.pot(5.4, 28.5, "heart", false, y)
	k.pot(-5.4, 28.5, "arrows_10", false, y)
	k.examine(Vector3(-4.5, y, 19.0), PI, [{"text": "A notice nailed to the gate post, half burnt:\n*ORDERS FOR THE GARRISON OF WESTMARCH. HOLD THE WEST ROAD. THE QUESTLORDS COMMAND IN THE CAPTAIN'S ABSENCE.*", "instant": true}])
	# The yard: siege rubble, a broken ram, the goblins' banner.
	for p in [Vector2(-9, 8), Vector2(10, -9), Vector2(-11, -10)]:
		k.rubble(p.x, p.y, k.rng.randf() * TAU, 1.0, y)
	k.platform(10.0, 8.0, Vector2(6.0, 4.0), y + 1.6, "stone", STONE.darkened(0.1))
	k.war_banner(0.0, -10.5, 0.0, y)
	k.crate(-12.0, 11.0, 0.2, 1.0, y)
	k.crate(-12.5, 9.6, -0.3, 0.8, y)
	# The stables: hay, a fight, Small Key 1.
	k.shutter(-20.6, 0.0, PI / 2.0, "stables", y)
	for z in [-7.0, -2.5, 2.0]:
		k.block(Vector3(-38.0, y + 0.7, z), Vector3(3.0, 1.4, 0.3), 0.0, "wood", Color(0.6, 0.45, 0.3))
	k.haystack(-36.0, 7.0, 1.0)
	k.chest(-30.0, 7.5, PI, "small_key", false, D + ":chest_key1", D + ":stables_clear", y)
	_torches(k, "stables")
	# The mess: long tables, the Map.
	for z in [-5.0, 0.0]:
		k.block(Vector3(31.0, y + 0.45, z), Vector3(10.0, 0.9, 1.4), 0.0, "wood", Color(0.55, 0.42, 0.3))
	k.chest(37.5, 6.0, -PI / 2.0, "map", false, D + ":chest_map", "", y)
	_torches(k, "mess")
	# The great hall: the Questlords' barricade, the rushes, Haven's banners.
	k.locked_door(0.0, -24.4, 0.0, D + ":door_key1", false, y)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		k.crate(x, -30.0, k.rng.randf() * 0.4, 1.1, y)
	for z in [-44.0, -36.0, -28.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 10.0, z, 6.5, 0.55, false, "stone", y)
	_haven_banner(k, -4.0, y + 4.6, -47.4, 0.0)
	_haven_banner(k, 4.0, y + 4.6, -47.4, 0.0)
	k.npc("Aladriel", "res://assets/models/aladriel.tscn", "res://scripts/npc/westmarch_lines.gd", -2.0, -38.0, 0.0, y, {"idle": "guard", "partner": "Idrith"})
	k.npc("Idrith", "res://assets/models/idrith.tscn", "res://scripts/npc/westmarch_lines.gd", 2.0, -38.0, 0.0, y, {"idle": "guard", "partner": "Aladriel"})
	# The chapel: the Compass at the altar.
	k.platform(-30.0, -44.0, Vector2(6.0, 2.4), y + 0.5, "stone", STONE)
	k.chest(-30.0, -44.0, 0.0, "compass", false, D + ":chest_compass", "", y + 0.5)
	for x in [-36.0, -24.0]:
		k.statue(x, -43.0, 0.0, 0.9, "stone", y)
	k.pot(-38.0, -28.0, "magic_small", false, y)
	_torches(k, "chapel")
	# The smithy: a cold forge, and a chest high on the racks (Hookshot).
	k.block(Vector3(36.0, y + 1.0, -40.0), Vector3(3.0, 2.0, 3.0), 0.0, "stone", DARK)
	k.fire(36.0, -40.0, 0.7, y + 2.0, true)
	k.block(Vector3(38.5, y + 2.25, -30.0), Vector3(3.0, 4.5, 6.0), 0.0, "wood", Color(0.5, 0.38, 0.28))
	k.chest(38.5, -30.0, -PI / 2.0, "heart_piece", false, D + ":chest_heart", "", y + 4.5)
	k.hook_target(Vector3(39.9, y + 6.2, -30.0), -PI / 2.0)
	k.pot(22.0, -44.0, "bombs_5", false, y)
	k.pot(22.0, -42.5, "bombs_5", false, y)


# --- 2F -------------------------------------------------------------------------

func _f2(k) -> void:
	var y := fy(2)
	# The armory: racks of spears, a fight, the Anchor Boots.
	k.shutter(-30.0, -10.6, 0.0, "armoury", y)
	for x in [-37.0, -33.0]:
		k.block(Vector3(x, y + 1.0, 8.6), Vector3(3.0, 2.0, 0.4), 0.0, "wood", Color(0.5, 0.38, 0.28))
	k.chest(-34.0, 4.0, PI, "boots_anchor", true, D + ":chest_anchor", D + ":armoury_clear", y)
	_torches(k, "armoury")
	k.locked_door(-30.0, -10.4, 0.0, D + ":door_key2", false, y)
	# The west tower: the battle-mage's study; the Staff once it falls.
	k.shutter(-30.0, -22.6, 0.0, "mage", y)
	k.chest(-30.0, -42.0, 0.0, "sapphire_staff", true, D + ":chest_staff", D + ":mage_clear", y)
	for p in [Vector2(-37, -43), Vector2(-23, -43), Vector2(-37, -25), Vector2(-23, -25)]:
		k.sapphire_brazier(p.x, p.y, y)
	# The weights: two plates; held at once, the bars before the Boss Key lift.
	for x in [-6.0, 6.0]:
		k._dyn("res://scripts/dungeon/hold_switch.gd", "WeightPlate", Vector3(x, y, -30.0), 0.0, {"result": D + ":weights"}, Area3D.new())
	k.block(Vector3(-2.6, y + 1.75, -42.0), Vector3(0.5, 3.5, 6.0), 0.0, "stone", STONE)
	k.block(Vector3(2.6, y + 1.75, -42.0), Vector3(0.5, 3.5, 6.0), 0.0, "stone", STONE)
	k.flag_bars(0.0, -39.2, 0.0, D + ":weights", y)
	# Posts either side of the grille, out to the walls.
	for s in [-1.0, 1.0]:
		k.block(Vector3(s * 1.8, y + 1.75, -39.2), Vector3(1.2, 3.5, 0.5), 0.0, "stone", STONE)
	k.chest(0.0, -43.5, 0.0, "boss_key", true, D + ":chest_boss_key", "", y)
	k.examine(Vector3(-9.0, y, -24.0), 0.0, [{"text": "An inscription by the plates:\n*TWO ARE NEEDED TO OPEN THE QUARTERMASTER'S GRILLE. THE QUARTERMASTER NEVER HAD A FRIEND.*", "instant": true}])
	_torches(k, "weights")
	# The barracks: bunks, a fight, Small Key 3.
	k.shutter(30.0, -10.6, 0.0, "barracks", y)
	for x in [24.0, 28.0, 32.0, 36.0]:
		k.block(Vector3(x, y + 0.5, 7.0), Vector3(1.4, 1.0, 2.6), 0.0, "wood", Color(0.55, 0.42, 0.3))
	k.chest(37.5, -6.0, -PI / 2.0, "small_key", false, D + ":chest_key3", D + ":barracks_clear", y)
	_torches(k, "barracks")
	# The key room: the door from the barracks; the ladder to the roof.
	k.locked_door(30.0, -22.4, 0.0, D + ":door_key3", false, y)
	_torches(k, "keyroom")


# --- 3F -------------------------------------------------------------------------

func _f3(k) -> void:
	var y := fy(3)
	k.locked_door(19.6, -34.0, PI / 2.0, D + ":boss_door", true, y)
	for p in [Vector2(36, -44), Vector2(36, -24)]:
		k.pot(p.x, p.y, "heart", false, y)
	k.pot(24.0, -44.0, "magic_small", false, y)
	# The keep roof: four great chimney stacks Grukk can be run into, crates.
	var rb: Rect2 = rooms.boss.r
	k.shutter(rb.end.x - 0.6, -34.0, PI / 2.0, "boss", y)
	for p in [Vector2(-9, -44), Vector2(7, -44), Vector2(-9, -28), Vector2(7, -28)]:
		k.block(Vector3(p.x, y + 2.0, p.y), Vector3(2.4, 4.0, 2.4), 0.0, "stone", STONE.darkened(0.15))
	k.war_banner(-1.0, -50.5, 0.0, y)
	var clear := D + ":boss_clear"
	var c := rb.get_center()
	k.heart_container(c.x, c.y + 2.0, clear, D + ":heart_container", y)
	k.mark("cs_wm_hero", Vector3(c.x, y, c.y + 6.0), PI)
	k.mark("cs_wm_cam", Vector3(c.x + 8.0, y + 4.0, c.y + 10.0))
	k.story_trigger("westmarch_fall", Rect2(c.x - 2.5, c.y - 0.5, 5.0, 5.0), y, "ch4:westmarch_fallen", clear)


func populate(k) -> void:
	var b1 := fy(0)
	var f1 := fy(1)
	var f2 := fy(2)
	var f3 := fy(3)
	# 1F
	k.enemy("basic_enemy", -6.0, 4.0, 0.0, {}, f1)
	k.enemy("basic_enemy", 6.0, -4.0, 0.0, {}, f1)
	k.enemy("basic_enemy", -4.0, -8.0, 0.0, {}, f1)
	k.enemy("goblin_archer", 10.0, 8.0, 0.0, {}, f1 + 1.6)
	k.enemy("goblin_archer", -10.0, -6.0, PI, {}, f1)
	k.enemy("boar_rider", 0.0, 0.0, PI, {}, f1)
	k.enemy("basic_enemy", -30.0, -4.0, 0.0, {"room": "stables"}, f1)
	k.enemy("basic_enemy", -26.0, 4.0, 0.0, {"room": "stables"}, f1)
	k.enemy("goblin_archer", -36.0, 0.0, -PI / 2.0, {"room": "stables"}, f1)
	k.enemy("basic_enemy", 28.0, 4.0, PI / 2.0, {}, f1)
	k.enemy("basic_enemy", 33.0, -6.0, PI / 2.0, {}, f1)
	k.enemy("keese", -30.0, -36.0, 0.0, {}, f1 + 3.5)
	k.enemy("keese", -26.0, -32.0, 0.0, {}, f1 + 3.5)
	k.enemy("sapphire_knight", -30.0, -32.0, 0.0, {}, f1)
	k.enemy("fire_keese", 28.0, -36.0, 0.0, {}, f1 + 3.5)
	k.enemy("fire_keese", 32.0, -30.0, 0.0, {}, f1 + 3.5)
	# B1
	k.enemy("sapphire_knight", -30.0, -4.0, 0.0, {"room": "cells"}, b1)
	k.enemy("basic_enemy", -26.0, 4.0, 0.0, {"room": "cells"}, b1)
	k.enemy("basic_enemy", -24.0, -6.0, 0.0, {"room": "cells"}, b1)
	k.enemy("octorok", -4.0, 0.0, 0.0, {}, WATER_Y - 0.45)
	k.enemy("octorok", 6.0, 8.0, PI, {}, WATER_Y - 0.45)
	k.enemy("rat", 28.0, 4.0, 0.0, {}, b1)
	k.enemy("rat", 34.0, -2.0, 0.0, {}, b1)
	k.enemy("rat", 25.0, -6.0, 0.0, {}, b1)
	# 2F
	k.enemy("rust_knight", -34.0, -2.0, PI, {"room": "armoury"}, f2)
	k.enemy("rust_knight", -26.0, 2.0, PI, {"room": "armoury"}, f2)
	k.enemy("battle_mage", -30.0, -34.0, 0.0, {"room": "mage"}, f2)
	k.enemy("sapphire_mage", 0.0, -26.0, PI, {}, f2)
	k.enemy("basic_enemy", 26.0, 0.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", 32.0, 2.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", 35.0, -4.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("goblin_archer", 24.0, -6.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("keese", 30.0, -34.0, 0.0, {}, f2 + 3.5)
	# 3F
	k.enemy("siege_ogre", -1.0, -38.0, 0.0, {"room": "boss"}, f3)
	# The three soldiers of the lost garrison in the cells.
	for s in [["fenn", -6.0], ["gwyn", 0.0], ["hollis", 6.0]]:
		k.garrison_soldier(s[0], -34.0, s[1], PI / 2.0, false, b1)
