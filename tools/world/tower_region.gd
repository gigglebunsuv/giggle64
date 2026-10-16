extends "res://tools/world/region.gd"
## A dungeon of several storeys stacked FLOOR_H apart (the goddess towers).
##
## The lowest storey stands on the area's painted terrain; every storey above
## it gets a stone floor slab under each of its rooms and passages, with holes
## left where a drop or a lift shaft opens onto the storey below. A room's
## ceiling block sits under the slab of the storey above with a gap between
## them, so no two faces share a plane.
##
## Subclasses fill `floors`, `rooms`, `corridors` and `holes` in setup(), then
## place everything else in build_rooms(k). The pause map and the minimap show
## one storey at a time (map_floors / map_walkable_floor).

## Height between storeys. A room on one storey may be up to ROOM_MAX tall
## (taller rooms run up through the storey above, which must leave the space
## clear).
const FLOOR_H := 8.0
const ROOM_MAX := 6.6
const CORRIDOR_H := 4.0
## Thickness of an upper storey's floor slab.
const SLAB := 0.5

## [name, floor height] per storey, bottom first.
var floors: Array = []
## room id -> {"f": storey, "r": Rect2, "h": height, "doors": Array, plus
## optional "ceiling" (false = open), "col", "mat", "map" (false = left off the map)}.
var rooms := {}
## {"f": storey, "r": Rect2, "x": runs along x}
var corridors: Array = []
## {"f": storey, "r": Rect2}: openings in a storey's floor slab.
var holes: Array = []
## The storey the hero enters on (the default map).
var entry_floor := 0
var wall_col := Color(1, 1, 1)
var wall_mat := "stone"
var ceil_col := Color(0.55, 0.5, 0.48)
var slab_col := Color(1, 1, 1)
var slab_mat := "stone"


func fy(f: int) -> float:
	return float(floors[f][1])


func room_y(id: String) -> float:
	return fy(rooms[id].f)


func room_rect(id: String) -> Rect2:
	return rooms[id].r


func room_center(id: String) -> Vector2:
	return (rooms[id].r as Rect2).get_center()


## The room on the storey at height `y` that holds (x, z), or "" (a corridor).
## WorldKit.enemy binds unbound enemies to it, so none hunts through a floor.
func room_at(x: float, z: float, y: float) -> String:
	var f := -1
	for i in floors.size():
		if fy(i) <= y + 0.5:
			f = i
	for id: String in rooms:
		if int(rooms[id].f) == f and (rooms[id].r as Rect2).has_point(Vector2(x, z)):
			return id
	return ""


## The lowest storey is the painted terrain.
func base_height(_x: float, _z: float) -> float:
	return fy(0)


## Override: the floor's color on storey `f` (the painted terrain for the
## lowest storey, and the maps of all of them).
func floor_paint(_x: float, _z: float, _f: int, r: RandomNumberGenerator) -> Color:
	return Color(0.6, 0.55, 0.5).darkened(r.randf_range(0.0, 0.08))


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	return floor_paint(x, z, 0, r)


func surface_at(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "stone"


func map_floors() -> Array:
	return floors.duplicate(true)


func map_floor_count() -> int:
	return floors.size()


func _in_hole(p: Vector2, f: int) -> bool:
	for ho: Dictionary in holes:
		if ho.f == f and (ho.r as Rect2).has_point(p):
			return true
	return false


func map_walkable_floor(x: float, z: float, f: int) -> bool:
	var p := Vector2(x, z)
	if _in_hole(p, f):
		return false
	for id: String in rooms:
		var rm: Dictionary = rooms[id]
		if rm.f == f and rm.get("map", true) and (rm.r as Rect2).has_point(p):
			return true
	for c: Dictionary in corridors:
		if c.f == f and (c.r as Rect2).has_point(p):
			return true
	return false


func map_floor_color(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	return floor_paint(x, z, f, r)


## The single-floor map (and the minimap before any storey is known) shows the
## entrance storey.
func map_walkable(x: float, z: float) -> bool:
	return map_walkable_floor(x, z, entry_floor)


func holes_on(f: int) -> Array:
	var out: Array = []
	for ho: Dictionary in holes:
		if ho.f == f:
			out.append(ho.r)
	return out


func build(k) -> void:
	k.place_y = fy(entry_floor)
	var slabs := {}
	for id: String in rooms:
		var rm: Dictionary = rooms[id]
		var y := fy(rm.f)
		var shafts: Array = holes_on(rm.f + 1) if rm.h <= ROOM_MAX else []
		# The ceiling reaches up to the underside of the storey above.
		var top := fy(rm.f + 1) - SLAB if rm.h <= ROOM_MAX and rm.f + 1 < floors.size() else INF
		k.dungeon_room(rm.r, y, rm.h, rm.get("doors", []), rm.get("col", wall_col), rm.get("mat", wall_mat), ceil_col, rm.get("ceiling", true), shafts, top)
		k.room_zone(id, rm.r, y, minf(rm.h, ROOM_MAX))
		if rm.f > 0:
			var slab := (rm.r as Rect2).grow(0.8)
			_note_slab(slabs, rm.f, slab, id)
			k.floor_slab(slab, y, holes_on(rm.f), rm.get("floor_mat", slab_mat), rm.get("floor_col", slab_col))
	for c: Dictionary in corridors:
		var y := fy(c.f)
		k.dungeon_corridor(c.r, y, CORRIDOR_H, c.x, wall_col, wall_mat, ceil_col)
		if c.f > 0:
			var cr: Rect2 = c.r
			# Under the passage and its side walls, stopping where the rooms'
			# slabs (which run under the rooms' walls) begin.
			var slab := cr.grow_individual(-0.8, 0.8, -0.8, 0.8) if c.x else cr.grow_individual(0.8, -0.8, 0.8, -0.8)
			_note_slab(slabs, c.f, slab, "passage")
			k.floor_slab(slab, y, holes_on(c.f), slab_mat, slab_col)
	build_rooms(k)


## Overlapping slabs on one storey would z-fight: rooms need a passage (or a
## gap of at least two wall thicknesses) between them.
func _note_slab(slabs: Dictionary, f: int, r: Rect2, what: String) -> void:
	var list: Array = slabs.get(f, [])
	for other: Array in list:
		var o: Rect2 = other[0]
		if o.intersects(r) and o.intersection(r).get_area() > 0.001:
			push_error("%s: the floor under %s overlaps %s on storey %d" % [id, what, other[1], f])
	list.append([r, what])
	slabs[f] = list


## The hole a ladder from the storey below climbs through (see ladder_up):
## (x, z) is the middle of the ladder's pier face, `out` the way it faces.
static func ladder_hole(x: float, z: float, out: Vector2) -> Rect2:
	var c := Vector2(x, z) + out * 1.35
	return Rect2(c - Vector2(1.3, 1.3), Vector2(2.6, 2.6))


## A ladder from storey `f` up through ladder_hole(x, z, out) into storey
## f + 1: it hangs on the face of a stone pier under the hole's far edge, so
## the hero climbs it facing -`out` and steps off onto the floor over the pier.
func ladder_up(k, f: int, x: float, z: float, out: Vector2) -> void:
	var y := fy(f)
	var top := fy(f + 1)
	var c := Vector2(x, z) - out * 0.4
	var size := Vector3(0.8, top - SLAB - y, 2.6) if out.x != 0.0 else Vector3(2.6, top - SLAB - y, 0.8)
	k.block(Vector3(c.x, (y + top - SLAB) * 0.5, c.y), size, 0.0, wall_mat, wall_col * Color(0.9, 0.9, 0.9))
	k.ladder(x + out.x * 0.05, z + out.y * 0.05, out, y, top)


## Override: everything in the rooms.
func build_rooms(_k) -> void:
	pass
