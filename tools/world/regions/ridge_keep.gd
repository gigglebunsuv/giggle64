extends "res://tools/world/tower_region.gd"
## Ridge Keep, Mara's fortress at the top of Black Water Ridge (Chapter V,
## Beta 1.4.0): a black keep built over the falls, its lower halls half
## drowned in still black water, its cells full of the drowned. Its treasure
## is the IRON FLAIL, carried by the Jailer; its master MARA, fought on the
## open roof at the top of the falls. The way goes UP, storey by storey.
##
## Storeys, bottom up (north is -Z):
##   1F (y 0)    gate S      in from the Ridge; Mara's words over the door
##               hall C      a fight (shutters); an iron grate north (the
##                           Flail, later): the chapel
##               cells E     the Map; the drowned in their cages; a ladder up
##               crypt far E black water: a crystal switch over it raises a
##                           causeway -> Key 1
##               cistern W   thorns (the Ember Rod) over the Compass
##               chapel N    behind the grate: the drowned knights' roll,
##                           a treasure
##   2F (y 8)    armory E    in by the ladder; undead knights
##               barracks C  a fight; locked north (Key 1)
##               kennels S   a chest
##               jail W      the JAILER (mini-boss) -> the IRON FLAIL; an
##                           iron grate west (the Flail)
##               oubliette   behind the grate -> Key 2
##               sluice N    locked (Key 1); a ladder up
##   3F (y 16)   bridge N    in by the ladder, north of a chasm: a cracked
##                           pillar (the Flail) falls across it
##               hall C      a fight; locked south (Key 2)
##               gallery E   four cold torches (the Ember Rod) -> a treasure
##               chains W    three iron bells hung high (the Flail) open the
##                           way west
##               loft far W  the Boss Key
##               tower S     locked (Key 2); a ladder up
##   4F (y 24)   stair S     in by the ladder
##               ramparts C  the open roof between the falls; the boss door
##                           north (the Boss Key)
##               watches E/W lookouts
##               falls N     the top of the falls: MARA

const D := "ridge_keep"
const BASALT := Color(0.26, 0.26, 0.3)
const DROWN := Color(0.3, 0.34, 0.38)
const BLACK_WATER := Color(0.04, 0.05, 0.08, 0.9)
## Ladders up: [storey below, pier x, pier z, out].
const LADDERS := [
	[0, 26.0, 6.0, Vector2(1, 0)],
	[1, -5.5, -42.0, Vector2(1, 0)],
	[2, -3.0, 24.0, Vector2(1, 0)],
]
## The chasm across the bridge hall (3F), open down into the sluice.
const CHASM := Rect2(-11.0, -37.5, 22.0, 3.5)
const PILLAR := Vector2(6.0, -38.6)


func setup() -> void:
	id = "ridge_keep"
	interior = true
	seed_value = 1404
	x_min = -66.0
	x_max = 66.0
	z_min = -70.0
	z_max = 36.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["1F", 0.0], ["2F", 8.0], ["3F", 16.0], ["4F", 24.0]]
	entry_floor = 0
	wall_col = BASALT
	ceil_col = Color(0.16, 0.16, 0.2)
	slab_col = Color(0.3, 0.3, 0.34)
	var cross := func(f: int, s_room: Rect2) -> Array:
		return [
			{"f": f, "r": Rect2(-2, 12, 4, s_room.position.y - 12.0), "x": false},
			{"f": f, "r": Rect2(-20, -2, 6, 4), "x": true},
			{"f": f, "r": Rect2(14, -2, 6, 4), "x": true},
			{"f": f, "r": Rect2(-2, -26, 4, 14), "x": false},
		]
	rooms = {
		# 1F
		"gate": {"f": 0, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"hall": {"f": 0, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"cells": {"f": 0, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}]},
		"crypt": {"f": 0, "r": Rect2(46, -8, 14, 16), "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "col": DROWN},
		"cistern": {"f": 0, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": DROWN},
		"chapel": {"f": 0, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# 2F
		"kennels": {"f": 1, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}]},
		"barracks": {"f": 1, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"armory": {"f": 1, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"gaol": {"f": 1, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}, {"side": "w", "at": 0.0}], "col": DROWN},
		"oubliette": {"f": 1, "r": Rect2(-60, -8, 14, 16), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": DROWN.darkened(0.2)},
		"sluice": {"f": 1, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": DROWN},
		# 3F
		"tower": {"f": 2, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}]},
		"great": {"f": 2, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"gallery": {"f": 2, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"chains": {"f": 2, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}, {"side": "w", "at": 0.0}]},
		"loft": {"f": 2, "r": Rect2(-60, -8, 14, 16), "h": 6.0, "doors": [{"side": "e", "at": 0.0}]},
		"bridge": {"f": 2, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# 4F: the roof, open to the sky between the falls.
		"stair": {"f": 3, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}]},
		"ramparts": {"f": 3, "r": Rect2(-14, -12, 28, 24), "h": 3.0, "ceiling": false, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"watch_e": {"f": 3, "r": Rect2(20, -10, 20, 20), "h": 3.0, "ceiling": false, "doors": [{"side": "w", "at": 0.0}]},
		"watch_w": {"f": 3, "r": Rect2(-40, -10, 20, 20), "h": 3.0, "ceiling": false, "doors": [{"side": "e", "at": 0.0}]},
		"boss": {"f": 3, "r": Rect2(-16, -58, 32, 32), "h": 3.0, "ceiling": false, "doors": [{"side": "s", "at": 0.0}], "col": BASALT.darkened(0.25)},
	}
	corridors = []
	corridors.append_array(cross.call(0, rooms.gate.r))
	corridors.append({"f": 0, "r": Rect2(40, -2, 6, 4), "x": true})
	corridors.append_array(cross.call(1, rooms.kennels.r))
	corridors.append({"f": 1, "r": Rect2(-46, -2, 6, 4), "x": true})
	corridors.append_array(cross.call(2, rooms.tower.r))
	corridors.append({"f": 2, "r": Rect2(-46, -2, 6, 4), "x": true})
	corridors.append_array(cross.call(3, rooms.stair.r))
	holes = []
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	holes.append({"f": 2, "r": CHASM})
	mood = {
		"sky_top": Color.html("0a0c14"), "sky_mid": Color.html("161a26"), "sky_horizon": Color.html("2a3040"),
		"cloud": Color.html("1a1c26"), "cloud_amount": 0.6,
		"fog": Color.html("161a22"), "fog_begin": 14.0, "fog_end": 70.0,
		"ambient": Color.html("4e5468"), "sun": Color.html("aab4d0"), "sun_rot": Vector3(-60, 30, 0),
		"sun_energy": 0.5, "fill": Color.html("2a3048"), "fill_energy": 0.5,
		"horizon": Color.html("0a0c14"), "hill_height": 0.0,
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


## Black stone flags; the drowned rooms wet and green-black; the roof's
## stones pale with spray.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["06060a", "08080c"])
	var seam := fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08
	if seam:
		return Color.html("121218")
	var p := Vector2(x, z)
	for rid in ["crypt", "cistern", "gaol", "oubliette", "sluice"]:
		if rooms[rid].f == f and (rooms[rid].r as Rect2).has_point(p):
			return Color.html(["243028", "1e2a24", "28342c"][r.randi() % 3])
	if f == 3:
		return Color.html(["4a4e58", "444852", "50545e"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.06))
	return Color.html(["2e2e36", "2a2a32", "32323a"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.06))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 2.0, 3.0, "black_water_ridge", "from_ridge_keep", Color(0.24, 0.22, 0.26))
	k.entrance("from_black_water_ridge", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	_f1(k)
	_f2(k)
	_f3(k)
	_f4(k)


func _lights(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", y)


## A shallow pool of black water across part of a room.
func _black_water(k, r: Rect2, y: float) -> void:
	k.water_plane(r, y + 0.08, BLACK_WATER)


# --- 1F -----------------------------------------------------------------------------

func _f1(k) -> void:
	k.examine(Vector3(-3.0, 0.0, 18.8), PI, [{"text": "Scratched into the black stone over the door, deep, as if with a blade:\n*I HELD THIS ROAD. NO ONE CAME.*\n-M.", "instant": true}])
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.6, z, 6.0, 0.45, false, "stone", 0.0)
	# The hall: a fight; the iron grate over the way north.
	k.shutter(13.4, 0.0, PI / 2.0, "hall", 0.0)
	k.shutter(-13.4, 0.0, PI / 2.0, "hall", 0.0)
	k.flail_target("gate", 0.0, -12.4, D + ":chapel_grate", 0.0, {"size": 2.6, "tall": 3.2})
	k.examine(Vector3(-3.0, 0.0, -10.4), PI, [{"text": "An iron grate, rusted fast into the stone. No key-hole, no hinge. Something heavy might burst it.", "instant": true}])
	for p in [Vector2(-9.0, -7.0), Vector2(9.0, -7.0), Vector2(-9.0, 7.0), Vector2(9.0, 7.0)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", 0.0)
	_lights(k, "hall")
	# The cells: the Map; the drowned in their cages; the ladder up.
	for i in 3:
		k.goblin_cage(34.0, -6.0 + i * 5.0, -PI / 2.0, "", 0.0)
	k.chest(24.0, -6.5, PI, "map", false, D + ":chest_map", "", 0.0)
	k.examine(Vector3(30.0, 0.0, 8.0), PI, [{"text": "The cages are full of bones, still in old Haven mail, green with the black water. Their hands are on the bars.", "instant": true}])
	_lights(k, "cells")
	# The crypt: black water; a crystal switch across it raises a causeway.
	var cr: Rect2 = rooms.crypt.r
	_black_water(k, Rect2(cr.position.x + 3.0, cr.position.y, 6.0, cr.size.y), 0.0)
	k.void_zone(Vector3(cr.position.x + 6.0, -1.0, cr.get_center().y), Vector3(6.0, 1.0, cr.size.y), 1)
	k.crystal_switch(cr.end.x - 1.8, cr.get_center().y + 4.0, D + ":crypt_switch", 0.0)
	k.flag_bridge(Rect2(cr.position.x + 3.0, cr.get_center().y - 1.2, 6.0, 2.4), 0.0, D + ":crypt_switch", 2.0)
	k.chest(cr.end.x - 1.8, cr.get_center().y - 2.0, -PI / 2.0, "small_key", false, D + ":chest_key1", "", 0.0)
	k.examine(Vector3(cr.position.x + 1.6, 0.0, cr.position.y + 2.0), -PI / 2.0, [{"text": "The water here is black and very still. Nothing in it moves... but you would not put a hand in it.\nA crystal glints on the far side.", "instant": true}])
	_lights(k, "crypt", 1.5)
	# The cistern: black water round the edges; thorns over the Compass.
	var ci: Rect2 = rooms.cistern.r
	_black_water(k, Rect2(ci.position.x, ci.position.y, ci.size.x, 4.0), 0.0)
	k.burnable("thorns", ci.position.x + 3.0, ci.get_center().y, PI * 0.5, D + ":cistern_thorns", Vector3(4.2, 2.8, 1.0), 0.0)
	# (Too sheer to climb: over them is no way round the thorns. Beta 1.5.1.)
	k.block(Vector3(ci.position.x + 2.2, 1.5, ci.get_center().y - 2.6), Vector3(4.4, 3.0, 0.6), 0.0, "stone", BASALT).set_meta("no_climb", true)
	k.block(Vector3(ci.position.x + 2.2, 1.5, ci.get_center().y + 2.6), Vector3(4.4, 3.0, 0.6), 0.0, "stone", BASALT).set_meta("no_climb", true)
	k.chest(ci.position.x + 1.4, ci.get_center().y, PI / 2.0, "compass", false, D + ":chest_compass", "", 0.0)
	_lights(k, "cistern")
	# The chapel, behind the grate: the drowned knights' roll.
	k.examine(Vector3(0.0, 0.0, -44.0), 0.0, [{"text": "A roll of names carved on the chapel wall, and above them:\n*THE KING'S ROAD GUARD. WE HELD THE RIDGE A HUNDRED DAYS.*\nThe last name is cut deeper than the rest: *MARA*.", "instant": true}])
	k.chest(-6.0, -42.0, 0.0, "rupee_gold", true, D + ":chest_chapel", "", 0.0)
	for p in [Vector2(-7.0, -32.0), Vector2(7.0, -32.0)]:
		k.statue(p.x, p.y, 0.0, 1.0, "stone", 0.0)
	_lights(k, "chapel")


# --- 2F -----------------------------------------------------------------------------

func _f2(k) -> void:
	var y := fy(1)
	_lights(k, "armory")
	k.chest(36.0, 6.0, -PI / 2.0, "arrows_10", false, D + ":chest_armory", "", y)
	for i in 4:
		k.display_mesh("res://assets/models/sword_red_mesh.tres", Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(39.4, y + 0.2, -6.0 + i * 1.2)))
	# The barracks: a fight; locked north (Key 1).
	k.shutter(13.4, 0.0, PI / 2.0, "barracks", y)
	k.shutter(-13.4, 0.0, PI / 2.0, "barracks", y)
	k.shutter(0.0, 11.4, 0.0, "barracks", y)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key1", false, y)
	for p in [Vector2(-9.0, -7.0), Vector2(9.0, -7.0), Vector2(-9.0, 7.0), Vector2(9.0, 7.0)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	_lights(k, "barracks")
	# The kennels.
	k.chest(4.0, 27.0, PI, "bombs_10", false, D + ":chest_kennels", "", y)
	_lights(k, "kennels", 1.5)
	# The jail: the Jailer; beaten, the Iron Flail. A grate west.
	k.shutter(-20.6, 0.0, PI / 2.0, "gaol", y)
	var gc := room_center("gaol")
	k.chest(gc.x + 5.0, gc.y + 6.0, -PI / 2.0, "iron_flail", true, D + ":chest_flail", D + ":gaol_clear", y)
	for i in 3:
		k.goblin_cage(gc.x - 6.0 + i * 5.0, gc.y - 7.6, 0.0, "", y)
	k.flail_target("gate", -40.6, 0.0, D + ":oubliette_grate", y, {"yaw": PI / 2.0, "size": 2.6, "tall": 3.2})
	_lights(k, "gaol")
	# The oubliette: Key 2.
	var oc := room_center("oubliette")
	k.chest(oc.x - 3.0, oc.y, PI / 2.0, "small_key", false, D + ":chest_key2", "", y)
	k.examine(Vector3(oc.x, y, oc.y + 6.0), PI, [{"text": "Scratched on the wall, hundreds of little lines in rows. Someone counted days here. Then they stopped.", "instant": true}])
	_lights(k, "oubliette", 1.5)
	# The sluice: locked (Key 1 used from the barracks); black channels; the
	# ladder up.
	var sr: Rect2 = rooms.sluice.r
	_black_water(k, Rect2(sr.position.x + 0.5, sr.position.y + 0.5, 4.0, sr.size.y - 1.0), y)
	_black_water(k, Rect2(sr.end.x - 4.5, sr.position.y + 0.5, 4.0, sr.size.y - 1.0), y)
	k.examine(Vector3(2.0, y, -30.0), PI, [{"text": "Great wheels and rusted gates. Once they let the falls' water out of the keep. Now the water only comes in.", "instant": true}])
	_lights(k, "sluice")


# --- 3F -----------------------------------------------------------------------------

func _f3(k) -> void:
	var y := fy(2)
	# The bridge hall: in by the ladder north of the chasm; the cracked pillar.
	k.flail_target("pillar", PILLAR.x, PILLAR.y, D + ":pillar_down", y, {"tall": 4.2})
	k.flag_bridge(Rect2(PILLAR.x - 0.7, CHASM.position.y - 0.6, 1.4, CHASM.size.y + 1.2), y, D + ":pillar_down", 0.3)
	k.examine(Vector3(-4.0, y, -40.0), PI, [{"text": "The floor has fallen away across the hall; far below, black water. A cracked pillar leans at the edge, as if it wanted to fall.", "instant": true}])
	_lights(k, "bridge")
	# The great hall: a fight; locked south (Key 2).
	k.shutter(13.4, 0.0, PI / 2.0, "great", y)
	k.shutter(-13.4, 0.0, PI / 2.0, "great", y)
	k.locked_door(0.0, 12.4, 0.0, D + ":door_key2", false, y)
	for p in [Vector2(-9.0, -7.0), Vector2(9.0, -7.0), Vector2(-9.0, 7.0), Vector2(9.0, 7.0)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	_lights(k, "great")
	# The gallery: four cold torches -> a treasure.
	var flags: Array = []
	var gc := room_center("gallery")
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var f := D + ":gallery_t%d" % i
		k.torch(gc.x + cos(a) * 6.0, gc.y + sin(a) * 6.0, false, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":gallery_lit")
	k.chest(gc.x + 6.0, gc.y, -PI / 2.0, "rupee_purple", false, D + ":chest_gallery", D + ":gallery_lit", y)
	k.examine(Vector3(gc.x - 8.0, y, gc.y + 7.0), PI * 0.75, [{"text": "Four torches, cold for a hundred years. The damp has got into everything.\nIt will take more than a spark.", "instant": true}])
	# The chains: three bells hung high; rung, the bars west lift.
	var bells: Array = []
	var cc := room_center("chains")
	for i in 3:
		var f := D + ":bell_%d" % i
		k.flail_target("bell", cc.x - 6.0 + i * 6.0, cc.y - 8.0 + (i % 2) * 4.0, f, y, {"tall": 4.4})
		bells.append(f)
	k.flag_all(bells, D + ":bells_rung")
	k.flag_bars(-40.6, 0.0, PI / 2.0, D + ":bells_rung", y)
	k.examine(Vector3(cc.x + 7.0, y, cc.y + 7.0), PI * 0.75, [{"text": "Three iron bells hang high under the ceiling, far out of reach of any sword.\n*RING ALL THREE AND THE WAY OPENS.*", "instant": true}])
	_lights(k, "chains")
	# The loft: the Boss Key.
	var lc := room_center("loft")
	k.chest(lc.x - 3.0, lc.y, PI / 2.0, "boss_key", true, D + ":chest_boss_key", "", y)
	_lights(k, "loft", 1.5)
	_lights(k, "tower", 1.5)


# --- 4F -----------------------------------------------------------------------------

func _f4(k) -> void:
	var y := fy(3)
	k.pot(4.5, 28.5, "heart", false, y)
	k.pot(-4.5, 28.5, "magic_small", false, y)
	# The ramparts, open to the sky; the boss door north.
	k.locked_door(0.0, -12.4, 0.0, D + ":boss_door", true, y)
	k.pot(36.0, -6.0, "magic_small", false, y)
	k.chest(36.0, 6.0, -PI / 2.0, "rupee_red", false, D + ":chest_watch_e", "", y)
	k.pot(-36.0, -6.0, "arrows_10", false, y)
	k.pot(-36.0, 6.0, "heart", false, y)
	# The top of the falls: Mara.
	var rb: Rect2 = rooms.boss.r
	var bc := room_center("boss")
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	for i in 6:
		var a := TAU * i / 6.0 + PI / 6.0
		k.pillar(bc.x + cos(a) * 13.0, bc.y + sin(a) * 13.0, 4.0, 0.6, i % 2 == 1, "stone", y)
	var clear := D + ":boss_clear"
	k.heart_container(bc.x, bc.y + 9.0, clear, D + ":heart_container", y)
	k.blue_warp(bc.x, bc.y + 4.0, "ch5:mara_done", "black_water_ridge", "warp_ridge_keep", y)
	# The great black falls pour off the roof's north edge, and from the
	# cliffs either side.
	var black := Color(0.16, 0.18, 0.26, 0.9)
	k.waterfall(Vector3(bc.x, y + 0.2, rb.position.y - 1.0), 14.0, 30.0, Vector2(0, -1), black)
	for sx in [-1.0, 1.0]:
		k.waterfall(Vector3(bc.x + sx * 22.0, y + 22.0, rb.position.y - 4.0), 6.0, 40.0, Vector2(0, 1), black)
	k.mark("cs_falls_top", Vector3(bc.x, y + 9.0, rb.position.y - 6.0))
	k.block(Vector3(bc.x, y + 4.0, rb.position.y - 8.0), Vector3(30.0, 8.0, 4.0), 0.0, "stone", BASALT.darkened(0.3))


func populate(k) -> void:
	var f2 := fy(1)
	var f3 := fy(2)
	var f4 := fy(3)
	k.enemy("keese", 0.0, 2.0, 0.0, {}, 4.0)
	k.enemy("stalfos", -5.0, -3.0, PI, {"room": "hall"}, 0.0)
	k.enemy("stalfos", 5.0, -3.0, PI, {"room": "hall"}, 0.0)
	k.enemy("barrow_knight", 0.0, -6.0, PI, {"room": "hall"}, 0.0)
	k.enemy("stalfos", 28.0, 0.0, PI / 2.0, {}, 0.0)
	k.enemy("keese", -30.0, 0.0, 0.0, {}, 3.5)
	k.enemy("barrow_knight", 28.0, -2.0, PI / 2.0, {}, f2)
	k.enemy("stalfos", 30.0, 4.0, PI / 2.0, {}, f2)
	k.enemy("barrow_knight", -5.0, -3.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("barrow_knight", 5.0, -3.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("keese", 0.0, 4.0, 0.0, {"room": "barracks"}, f2 + 3.5)
	k.enemy("keese", 0.0, 24.0, 0.0, {}, f2 + 3.5)
	k.enemy("gaoler", -32.0, 0.0, PI / 2.0, {"room": "gaol"}, f2)
	k.enemy("stalfos", 0.0, -40.0, 0.0, {}, f2)
	k.enemy("barrow_knight", -5.0, 3.0, 0.0, {"room": "great"}, f3)
	k.enemy("barrow_knight", 5.0, 3.0, 0.0, {"room": "great"}, f3)
	k.enemy("stalfos", 0.0, -5.0, 0.0, {"room": "great"}, f3)
	k.enemy("keese", 30.0, 0.0, 0.0, {}, f3 + 3.5)
	k.enemy("stalfos", -30.0, 4.0, 0.0, {}, f3)
	k.enemy("stalfos", -4.0, 0.0, PI, {}, f4)
	k.enemy("stalfos", 4.0, -4.0, PI, {}, f4)
	k.enemy("barrow_knight", 0.0, -8.0, PI, {}, f4)
	k.enemy("keese", -6.0, 4.0, 0.0, {}, f4 + 3.0)
	k.enemy("keese", 6.0, 4.0, 0.0, {}, f4 + 3.0)
	k.enemy("mara", 0.0, -46.0, 0.0, {"room": "boss"}, f4)
