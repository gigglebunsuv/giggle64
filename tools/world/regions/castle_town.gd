extends "res://tools/world/region.gd"
## Old Castle Town: a walled market town of tall, brightly painted houses on
## blue-gray cobbles (the January 1997 castle town shots), a market square with
## a fountain, a canal, and the sealed Castle of Bunsriel to the north. The
## timber hall on the west side of the square is Pink's Armory (`armory`).
##
## With `fallen` (castle_town_fallen.gd) the same town after Firebuns III
## takes it: houses charred and some fallen in, fires in the streets, the
## market in ruins, the armory barred, goblins and Sapphire Order mages in
## the streets, and the castle gate broken open (the way into `castle`).

const SQUARE := Vector2(0, 2)
const CANAL_Z := -38.0
const CANAL_HALF := 3.0
const CANAL_Y := -1.0
const CASTLE_Z := -66.0
const WALL_COLS := ["e8a046", "e8d070", "9ab84a", "f0e8d0", "e8b0a0", "a8b8d0", "d88a5a", "c8c060"]
const ROOF_COLS := ["b84a32", "8a3a2a", "b84a32", "7a5a3a", "4a5aa8", "a0402a"]
const CHAR := Color(0.16, 0.13, 0.12)

## The town after the takeover.
var fallen := false
## The armory's door onto the square (the rebuilt town places its own).
var armory_door := true
## Years later (castle_town_restored): the old royal chapel east of the
## square opens onto the Barrow of Kings, and no trees grow in the Knights' Yard.
var chapel_open := false
var tree_skip := Rect2()


func setup() -> void:
	id = "castle_town"
	seed_value = 31
	x_min = -55.0
	x_max = 55.0
	z_min = -80.0
	z_max = 45.0
	tex_size = 512
	rim_height = 0.0
	links = [{"to": "field", "p": Vector2(0, 45), "d": Vector2(0, -1), "w": 3.5, "y": 0.2, "corridor": false, "spawn": 7.0}]
	water = [{"rect": Rect2(-75, CANAL_Z - CANAL_HALF, 150, CANAL_HALF * 2.0), "y": CANAL_Y, "col": Color(0.3, 0.45, 0.7, 0.8)}]
	mood = {
		"sky_top": Color.html("3c3480"), "sky_mid": Color.html("7466b0"), "sky_horizon": Color.html("d0b4d4"),
		"cloud": Color.html("dccce8"), "cloud_amount": 0.7,
		"fog": Color.html("b4a6c6"), "fog_begin": 35.0, "fog_end": 130.0,
		"ambient": Color.html("7a6c8c"), "sun": Color.html("fff0e0"), "sun_rot": Vector3(-48, 25, 0),
		"fill": Color.html("6a5a9a"),
		"horizon": Color.html("6a5c84"), "hill_height": 8.0,
		"far": [{"type": "peak", "yaw": 60.0, "w": 120.0, "h": 70.0, "col": Color.html("8a84a8"), "snow": true}],
	}


func base_height(x: float, z: float) -> float:
	var h := 0.2 + detail.get_noise_2d(x, z) * 0.04
	# Castle grounds rise north of the canal.
	h += smoothstep(-44.0, -60.0, z) * 3.0
	var dc := absf(z - CANAL_Z)
	if dc < CANAL_HALF + 0.6 and z > -44.0:
		h = lerpf(-2.2, h, smoothstep(CANAL_HALF - 0.2, CANAL_HALF + 0.4, dc))
	return h


func street(x: float, z: float) -> bool:
	return absf(x) < 5.0 or absf(z - SQUARE.y) < 4.5 or Vector2(x, z).distance_to(SQUARE) < 17.0 \
		or (absf(absf(x) - 30.0) < 3.5 and z > -34.0)


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if z < -44.0:
		# Castle lawns with a pale gravel avenue to the gate.
		if absf(x) < 4.0 and z > CASTLE_Z:
			return pick(r, ["c8c0b0", "d0c8b8"]).lerp(CHAR, 0.4 if fallen else 0.0)
		var lawn := Color.html("4a8a34").lerp(Color.html("68a444"), clampf(noise.get_noise_2d(x * 3.0, z * 3.0) + 0.5 + r.randf_range(-0.1, 0.1), 0.0, 1.0))
		return lawn.lerp(Color.html("3a3426"), 0.65) if fallen else lawn
	if h < -0.5:
		return Color.html("5a6070")
	# Big blue-gray cobbles in staggered rows; streets a little paler.
	var cell := 1.4
	var row := floori(z / cell)
	var off := 0.5 * cell if row % 2 == 0 else 0.0
	var fx := fposmod(x + off, cell * 1.3) / (cell * 1.3)
	var fz := fposmod(z, cell) / cell
	var mortar := fx < 0.14 or fz < 0.16
	var base := Color.html("8a90a4") if street(x, z) else Color.html("747a8e")
	if Vector2(x, z).distance_to(SQUARE) < 16.0 and int(Vector2(x, z).distance_to(SQUARE) / 2.5) % 2 == 0:
		base = Color.html("9a9aa8")
	if fallen:
		# Soot and scorch marks over everything.
		base = base.lerp(CHAR, 0.35 + clampf(noise.get_noise_2d(x * 2.0, z * 2.0), 0.0, 0.5))
	if mortar:
		return base.darkened(0.35)
	return base * r.randf_range(0.88, 1.1)


## The street facades built so far (HouseData.ct_door numbers them).
var _house_n := 0


## A row of town houses along a street edge from a to b, fronts facing `face` (yaw).
## Two of every three open onto an interior (HouseData, Beta 1.5.0).
func _row(k, a: Vector2, b: Vector2, face: float, depth: float, count: int, r: RandomNumberGenerator) -> void:
	var length := a.distance_to(b)
	var w := length / count
	for i in count:
		var p := a.lerp(b, (i + 0.5) / count)
		var back := Vector2(sin(face), cos(face)) * -(depth * 0.5)
		var hh := r.randf_range(5.5, 9.0)
		var wall := Color.html(WALL_COLS[r.randi_range(0, WALL_COLS.size() - 1)])
		var roof := Color.html(ROOF_COLS[r.randi_range(0, ROOF_COLS.size() - 1)])
		var hid := HouseData.ct_door(_house_n)
		_house_n += 1
		if fallen:
			wall = wall.lerp(CHAR, 0.6)
			roof = roof.lerp(CHAR, 0.75)
			if (i + int(absf(a.x) + absf(a.y))) % 3 == 0:
				# Burnt out and fallen in: a stump of wall, rubble and fire.
				var c := Vector2(p.x + back.x, p.y + back.y)
				k.house(c.x, c.y, face, w - 0.4, depth, 2.2, wall, roof, {"wall": "plaster", "door": false, "roof_h": 0.4})
				k.rubble(c.x + r.randf_range(-1.0, 1.0), c.y + r.randf_range(-1.0, 1.0), r.randf() * TAU, 1.1)
				k.fire(c.x, c.y, 1.3, k.h(c.x, c.y) + 1.0, i % 2 == 0)
				continue
		var wall_mat := "timber" if r.randf() < 0.3 else "plaster"
		var chimney := r.randf() < 0.4
		var door_look := r.randf() < 0.8
		k.house(p.x + back.x, p.y + back.y, face, w - 0.4, depth, hh, wall, roof,
			{"wall": wall_mat, "chimney": chimney, "door": door_look or hid != ""})
		if hid != "":
			_house_door(k, hid, Vector2(p.x + back.x, p.y + back.y), face, depth)
		if r.randf() < 0.35 and not fallen:
			var f := Vector2(sin(face), cos(face))
			k.banner(p.x + f.x * 0.2, k.h(p.x, p.y) + hh - 0.6, p.y + f.y * 0.2, face, Color.html(["3048a8", "a83030", "d8b030"][r.randi_range(0, 2)]), 2.0)


## The door of a house you can walk into, and its entrance outside. While
## the town is fallen the doors are barred; in the rebuilt town, until the
## homes are paid for (the Rebuilding Fund), scaffolding blocks them.
func _house_door(k, hid: String, c: Vector2, face: float, depth: float) -> void:
	var f := Vector2(sin(face), cos(face))
	var at := c + f * (depth * 0.5 + 0.06)
	var y: float = k.h(c.x, c.y) - 0.2
	var need := ""
	var text := ""
	if fallen:
		need = "town:never"
		text = "The door is barred and black with soot. Nobody has been home for a long time."
	elif id == "castle_town_rebuilt":
		need = "rebuild:homes"
		text = "Scaffolding covers the doorway, and a sign: *REBUILDING. THE FAMILY WILL BE HOME SOON.*"
	k.door_link(Vector3(at.x, y, at.y), face + PI, 1.2, 2.1, hid, "from_castle_town", Color(0.85, 0.75, 0.6), need, "", text)
	var out := c + f * (depth * 0.5 + 1.6)
	k.entrance("from_" + hid, out.x, out.y, face + PI)


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var stone := Color(0.95, 0.93, 0.9)
	# Town walls and the south gatehouse.
	k.gatehouse(0, 43, PI, 7.0, 11.0, "stone", stone, Color.html("4a5aa8"))
	k.wall_line([Vector2(-5.1, 43), Vector2(-56, 43), Vector2(-56, CASTLE_Z)], 10.0, 2.0, "stone", stone, true)
	k.wall_line([Vector2(5.1, 43), Vector2(56, 43), Vector2(56, CASTLE_Z)], 10.0, 2.0, "stone", stone, true)
	for p in [Vector2(-56, 43), Vector2(56, 43), Vector2(-56, -12), Vector2(56, -12)]:
		k.tower(p.x, p.y, 3.0, 14.0, "stone", stone, Color.html("4a5aa8"), PI, {"crenel": true, "roof_h": 5.0})
	# Houses: the main street, around the square, and the side streets.
	_row(k, Vector2(-5, 40), Vector2(-5, 20), PI * 0.5, 7.0, 3, r)
	_row(k, Vector2(5, 20), Vector2(5, 40), -PI * 0.5, 7.0, 3, r)
	_row(k, Vector2(-5, -18), Vector2(-5, -33), PI * 0.5, 7.0, 2, r)
	_row(k, Vector2(5, -33), Vector2(5, -18), -PI * 0.5, 7.0, 2, r)
	for side in [-1.0, 1.0]:
		var x0: float = side * 18.0
		var x1: float = side * 26.5
		_row(k, Vector2(x0, 6.5), Vector2(x1, 6.5), PI, 7.0, 1, r)
		_row(k, Vector2(x1, -2.5), Vector2(x0, -2.5), 0.0, 7.0, 1, r)
		_row(k, Vector2(side * 33.5, 6.5), Vector2(side * 52, 6.5), PI, 7.0, 2, r)
		_row(k, Vector2(side * 52, -2.5), Vector2(side * 33.5, -2.5), 0.0, 7.0, 2, r)
		# Along the side streets.
		_row(k, Vector2(side * 26.5, 40), Vector2(side * 26.5, 15), side * PI * 0.5, 7.0, 3, r)
		_row(k, Vector2(side * 33.5, 15), Vector2(side * 33.5, 40), -side * PI * 0.5, 7.0, 3, r)
		_row(k, Vector2(side * 26.5, -10), Vector2(side * 26.5, -32), side * PI * 0.5, 7.0, 2, r)
		_row(k, Vector2(side * 8, 40), Vector2(side * 19, 40), PI, 6.0, 2, r)
	# The temple (east) and Pink's Armory (west) on the north side of the square.
	k.house(42, -21, -PI * 0.5, 12.0, 16.0, 9.0, Color(0.96, 0.95, 0.92), Color.html("5a5a6a"), {"wall": "stone", "door": false, "roof_h": 5.0})
	if chapel_open:
		k.door_link(k.g(33.6, -21, 0.0), k.yaw_of(Vector2(-1, 0)), 2.4, 3.6, "barrow_of_kings", "from_castle_town_restored", Color(0.95, 0.85, 0.55), "ch5:barrow_open", "",
			"The chapel doors are sealed with the kings' gold wax.
*BENEATH LIES THE BARROW OF KINGS. LET THEM SLEEP.*")
		k.entrance("from_barrow_of_kings", 28.6, -21.0, k.yaw_of(Vector2(-1, 0)))
	else:
		k.sealed_door(k.g(33.6, -21, 0.0), k.yaw_of(Vector2(-1, 0)), 2.4, 3.6, "seal", Color(1.0, 0.85, 0.3))
	for z in [-26.0, -16.0]:
		k.pillar(31.8, z, 6.0, 0.55)
	_armory_front(k)
	# The market square.
	k.fountain(SQUARE.x, SQUARE.y, 4.5)
	var cloths := [Color.html("c83a2a"), Color.html("2a6ac8"), Color.html("d8a020"), Color.html("3a9a4a")]
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		if absf(cos(a)) > 0.92 or absf(sin(a)) > 0.92:
			continue
		var p := SQUARE + Vector2(cos(a), sin(a)) * 11.5
		if fallen:
			# The market stalls smashed and burning.
			k.rubble(p.x, p.y, a, 0.9)
			if i % 2 == 0:
				k.fire(p.x, p.y, 1.0, INF, i % 4 == 0)
			continue
		k.stall(p.x, p.y, atan2(-cos(a), -sin(a)) + PI, cloths[i % 4])
	for i in 6:
		var a := TAU * i / 6.0
		k.lamp(SQUARE.x + cos(a) * 15.5, SQUARE.y + sin(a) * 15.5)
	for p in [Vector2(-8, 13), Vector2(9, -9), Vector2(-9, -8), Vector2(21, 11), Vector2(-22, 11)]:
		for j in 3:
			if j < 2:
				k.barrel(p.x + j * 0.95, p.y)
			else:
				k.crate(p.x + 0.4, p.y + 1.1, 0.3, 0.9)
	for z in [36.0, 26.0, -22.0, -30.0]:
		k.lamp(-3.8, z)
		k.lamp(3.8, z + 4.0)
	# The canal: parapets with gaps where the bridges cross.
	for xr in [[-54.0, -34.0], [-26.0, -6.0], [6.0, 26.0], [34.0, 54.0]]:
		for zs in [-1.0, 1.0]:
			var zz: float = CANAL_Z + zs * (CANAL_HALF + 0.35)
			k.wall_line([Vector2(xr[0], zz), Vector2(xr[1], zz)], 1.0, 0.6, "stone", stone, false, 0.0)
	k.bridge(Vector3(0, 0.2, CANAL_Z + 4.5), Vector3(0, 0.2, CANAL_Z - 4.5), 10.0, "stone", 0.8, stone, "stone")
	for sx in [-30.0, 30.0]:
		k.bridge(Vector3(sx, 0.2, CANAL_Z + 4.5), Vector3(sx, 0.2, CANAL_Z - 4.5), 6.0, "stone", 0.6, stone, "stone")
	# Castle grounds: trees, hedges and statues lining the avenue.
	for z in [-48.0, -55.0, -62.0]:
		for sx in [-1.0, 1.0]:
			k.tree_round(sx * 9.0, z, 1.1)
			k.bush(sx * 5.5, z + 2.5, 0.8)
	for sx in [-1.0, 1.0]:
		k.statue(sx * 5.5, CASTLE_Z + 7.0, 0.0 if sx < 0 else PI, 1.0)
	for j in 14:
		var x := r.randf_range(-48, 48)
		var z := r.randf_range(-62, -46)
		if absf(x) > 13.0 and not tree_skip.grow(2.0).has_point(Vector2(x, z)):
			k.tree_round(x, z, r.randf_range(0.9, 1.3))
	# The Castle of Bunsriel: curtain wall, towers, the keep, and its sealed gate.
	var cy: float = k.h(0, CASTLE_Z)
	k.wall_line([Vector2(-56, CASTLE_Z), Vector2(-3.2, CASTLE_Z)], 13.0, 3.0, "stone", stone, true, cy - 0.5)
	k.wall_line([Vector2(3.2, CASTLE_Z), Vector2(56, CASTLE_Z)], 13.0, 3.0, "stone", stone, true, cy - 0.5)
	k.wall_line([Vector2(-3.2, CASTLE_Z), Vector2(3.2, CASTLE_Z)], 13.0, 3.0, "stone", stone, true, cy + 6.5)
	if fallen:
		_broken_gate(k, cy)
	else:
		k.sealed_door(Vector3(0, cy, CASTLE_Z + 1.6), PI, 5.2, 6.5, "seal", Color(0.3, 0.5, 1.0))
	var flag_col := Color.html("2a1a3a") if fallen else Color.html("3048a8")
	k.banner(-5.0, cy + 11.5, CASTLE_Z + 1.6, 0.0, flag_col, 4.0)
	k.banner(5.0, cy + 11.5, CASTLE_Z + 1.6, 0.0, flag_col, 4.0)
	for x in [-40.0, -14.0, 14.0, 40.0]:
		k.tower(x, CASTLE_Z, 3.2, 19.0, "stone", stone, Color.html("4a5aa8"), 0.0, {"crenel": true, "roof_h": 7.0, "y": cy - 0.5, "seal": "grate", "door_w": 1.4, "door_h": 2.4})
	k.house(0, -82, 0.0, 26.0, 14.0, 20.0, stone, Color.html("4a5aa8"), {"wall": "stone", "door": false, "y": cy, "roof_h": 7.0})
	for p in [Vector2(-13, -75), Vector2(13, -75), Vector2(-13, -89), Vector2(13, -89)]:
		k.tower(p.x, p.y, 3.0, 28.0, "stone", stone, Color.html("4a5aa8"), 0.0, {"roof_h": 8.0, "y": cy, "seal": "grate", "door_w": 1.0, "door_h": 2.0})
	k.tower(0, -84, 4.0, 36.0, "stone", stone, Color.html("3a4a98"), 0.0, {"roof_h": 11.0, "y": cy, "seal": "grate", "door_w": 1.0, "door_h": 2.0})
	if fallen:
		# Fire on the battlements and the towers.
		for x in [-40.0, -14.0, 14.0, 40.0]:
			k.fire(x, CASTLE_Z, 1.6, cy + 19.0, absf(x) < 20.0)
		for x in [-30.0, 26.0]:
			k.fire(x, CASTLE_Z + 0.5, 1.4, cy + 13.0, false)


## The castle gate after the takeover: the great doors burst off their
## hinges and lying in the gateway, scorched, and the dark way in.
func _broken_gate(k, cy: float) -> void:
	var pos := Vector3(0, cy, CASTLE_Z + 1.6)
	var frame = k._tmp()
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(sx * 2.9, cy + 3.25, CASTLE_Z + 1.6), Vector3(0.6, 6.5, 0.7), Color(0.55, 0.52, 0.5))
	frame.box(Vector3(0, cy + 6.85, CASTLE_Z + 1.6), Vector3(6.4, 0.7, 0.75), Color(0.55, 0.52, 0.5))
	k.merge(frame, "stone")
	var doors = k._tmp()
	doors.push(Transform3D(Basis(Vector3.UP, 0.3) * Basis(Vector3.RIGHT, -1.45), Vector3(-1.8, cy + 0.25, CASTLE_Z + 4.2)))
	doors.box(Vector3.ZERO, Vector3(2.4, 5.6, 0.3), Color(0.35, 0.28, 0.22))
	doors.pop()
	doors.push(Transform3D(Basis(Vector3.UP, -0.5) * Basis(Vector3.BACK, 0.25) * Basis(Vector3.RIGHT, -1.2), Vector3(2.2, cy + 0.8, CASTLE_Z + 3.4)))
	doors.box(Vector3.ZERO, Vector3(2.4, 5.6, 0.3), Color(0.3, 0.24, 0.2))
	doors.pop()
	k.merge(doors, "door")
	k.door_link(pos, PI, 3.2, 4.4, "castle", "from_castle_town", Color(0.2, 0.18, 0.2))
	k.entrance("from_castle", 0.0, CASTLE_Z + 5.5, PI)
	k.fire(-3.6, CASTLE_Z + 3.0, 1.0, cy, true)
	k.fire(3.6, CASTLE_Z + 3.0, 1.0, cy, false)


## Pink's Armory: a timber hall facing the square, with ARMORY in gold block
## letters across its front, a sword-and-shield sign hanging out over the
## street on an iron bracket, weapon racks either side of the door and an
## anvil out front, so you can tell what it is from across the square.
func _armory_front(k) -> void:
	var c := Vector2(-42, -21)
	var yaw := PI * 0.5
	k.house(c.x, c.y, yaw, 12.0, 14.0, 8.0, Color.html("d8c8a0"), Color.html("8a3a2a"), {"wall": "timber", "door": false})
	var front_x := c.x + 7.0
	var gy: float = k.h(front_x + 0.5, c.y)
	if fallen:
		# Barred and scorched: Pink is not here.
		k.sealed_door(Vector3(front_x + 0.2, gy, c.y), yaw, 1.4, 2.4, "wood")
		k.fire(front_x + 1.5, c.y + 3.2, 0.8, gy, false)
	elif armory_door:
		k.door_link(Vector3(front_x + 0.06, gy, c.y), yaw + PI, 1.4, 2.4, "armory")
		k.entrance("from_armory", front_x + 1.8, c.y, -PI * 0.5)
	var trim = k._tmp(false)
	trim.box(Vector3(front_x + 0.05, gy + 1.25, c.y), Vector3(0.12, 2.65, 1.8), Color.html("4a2e1c"))
	# The name board over the door.
	trim.box(Vector3(front_x + 0.06, gy + 3.55, c.y), Vector3(0.1, 1.15, 7.4), Color.html("4a2e1c"))
	trim.box(Vector3(front_x + 0.1, gy + 3.55, c.y), Vector3(0.06, 0.95, 7.2), Color.html("8a2a2a"))
	k.merge(trim, "char")
	k.pixel_text("PINK'S ARMORY", Vector3(front_x + 0.13, gy + 3.55, c.y), yaw, 0.085, Color.html("f0c850"))
	# The hanging sign on its bracket, board edge-on to the wall so it reads
	# from up and down the street: a shield with two crossed swords.
	var arm_y: float = gy + 4.6
	var sign = k._tmp(false)
	sign.box(Vector3(front_x + 0.9, arm_y, c.y + 2.6), Vector3(1.8, 0.07, 0.07), Color.html("2c2c30"))
	sign.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(-35)), Vector3(front_x + 0.45, arm_y - 0.35, c.y + 2.6)))
	sign.box(Vector3.ZERO, Vector3(0.9, 0.05, 0.05), Color.html("2c2c30"))
	sign.pop()
	for hx in [0.6, 1.5]:
		sign.box(Vector3(front_x + hx, arm_y - 0.2, c.y + 2.6), Vector3(0.03, 0.4, 0.03), Color.html("2c2c30"))
	var board := Vector3(front_x + 1.05, arm_y - 0.95, c.y + 2.6)
	sign.box(board, Vector3(1.3, 1.1, 0.08), Color.html("6a4428"))
	for sz in [-1.0, 1.0]:
		sign.box(board + Vector3(0, 0, 0.045 * sz), Vector3(1.18, 0.98, 0.02), Color.html("2a4a8a"))
		# Crossed swords behind a red shield, both faces.
		for d in [-1.0, 1.0]:
			sign.push(Transform3D(Basis(Vector3.BACK, deg_to_rad(40 * d)), board + Vector3(0, 0, 0.06 * sz)))
			sign.box(Vector3(0, 0.05, 0), Vector3(0.06, 0.85, 0.02), Color.html("e0e6ee"))
			sign.box(Vector3(0, -0.3, 0), Vector3(0.24, 0.05, 0.025), Color.html("e8c050"))
			sign.pop()
		sign.push(Transform3D(Basis.IDENTITY, board + Vector3(0, -0.02, 0.07 * sz)))
		sign.slab(Vector3(0, 0.25, 0), Vector2(0.44, 0.02), Vector3(0, -0.05, 0), Vector2(0.4, 0.02), Color.html("c83a2a"))
		sign.slab(Vector3(0, -0.05, 0), Vector2(0.4, 0.02), Vector3(0, -0.3, 0), Vector2(0.04, 0.02), Color.html("c83a2a"))
		sign.box(Vector3(0, 0.02, 0.012), Vector3(0.08, 0.08, 0.01), Color.html("e8c050"))
		sign.pop()
	k.merge(sign, "char")
	# Weapon racks either side of the door and an anvil out front.
	for side in [-1.0, 1.0]:
		var rz: float = c.y + side * 2.2
		var rack = k._tmp(false)
		rack.box(Vector3(front_x + 0.35, gy + 0.45, rz), Vector3(0.5, 0.08, 1.4), Color.html("6a4428"))
		rack.box(Vector3(front_x + 0.35, gy + 1.25, rz), Vector3(0.5, 0.08, 1.4), Color.html("6a4428"))
		for e in [-0.65, 0.65]:
			rack.box(Vector3(front_x + 0.35, gy + 0.75, rz + e), Vector3(0.08, 1.5, 0.08), Color.html("5a3820"))
		k.merge(rack, "char")
		k.col_box(Vector3(front_x + 0.35, gy + 0.75, rz), Vector3(0.5, 1.5, 1.4))
		var swords: Array = ["squire", "red", "magical"] if side < 0 else ["red", "squire", "bun"]
		for i in swords.size():
			# Point down between the bars, flat toward the square.
			var up := Basis(Vector3.RIGHT, -PI * 0.5)
			k.display_mesh("res://assets/models/sword_%s_mesh.tres" % swords[i], Transform3D(up, Vector3(front_x + 0.35, gy + 1.35, rz - 0.45 + i * 0.45)))
		k.display_mesh("res://assets/models/shield_%s_flat_mesh.tres" % ("iron" if side < 0 else "wooden"),
			Transform3D(Basis(Vector3.BACK, -PI * 0.5), Vector3(front_x + 0.04, gy + 2.15, rz)))
	k.display_mesh("res://assets/models/anvil_mesh.tres", Transform3D(Basis(Vector3.UP, 0.3), Vector3(front_x + 2.3, gy, c.y - 3.6)))
	k.col_box(Vector3(front_x + 2.3, gy + 0.35, c.y - 3.6), Vector3(0.62, 0.7, 0.3), 0.3)
	k.banner(front_x + 0.15, gy + 6.6, c.y - 4.2, yaw, Color.html("c83a2a"), 2.2)
	k.banner(front_x + 0.15, gy + 6.6, c.y + 4.2, yaw, Color.html("c83a2a"), 2.2)


## The market: pots by the stalls and barrels, a sign at the gate, rupees on
## the canal bridges. No monsters inside the walls (until the town falls).
func populate(k) -> void:
	if fallen:
		_populate_fallen(k)
		return
	k.signpost(-4.0, 36, Vector2(0, 32), "*Old Castle Town*\nThe market square lies ahead.\n\nThe Castle of Bunsriel stands\nbeyond the canal to the north.")
	k.signpost(-31.0, -17.5, Vector2(-26, -14), "*Pink's Armory*\nSwords, shields and repairs.\n\nThe finest forge in town!")
	k.signpost(-4.5, CANAL_Z + 6.0, Vector2(0, CANAL_Z + 9.0), "North: *Castle of Bunsriel*\nThe gate is sealed.")
	for p in [Vector2(-7.0, 11.8), Vector2(-8.0, 11.9), Vector2(11.0, -9.0), Vector2(-10.6, -8.0), Vector2(23.0, 11.0), Vector2(-20.0, 11.0)]:
		k.pot(p.x, p.y)
	k.pot(9.4, -10.4, "rupee_red")
	for x in [-30.0, 30.0]:
		k.collectible("rupee_blue", x, CANAL_Z, 1.1)
	for c in [Vector2(-30, -55), Vector2(30, -55), Vector2(-20, -48), Vector2(20, -48)]:
		k.shrubs_near(c, 5.0, 5)
	# Tansy's cups, east of the fountain (gone to Himeko's palace after the fall).
	var to_square := (SQUARE - Vector2(8.5, 7.5)).normalized()
	k.cup_game(8.5, 7.5, k.yaw_of(to_square)).set("hide_flag", "castle_fallen")
	var behind := Vector2(8.5, 7.5) - to_square * 0.75
	k.npc("Tansy", "res://assets/models/tansy.tscn", "res://scripts/npc/tansy_lines.gd", behind.x, behind.y, k.yaw_of(to_square), INF, {"hide": "castle_fallen"})
	_market(k)


## The market's people (Beta 1.5.0): a keeper behind each stall with one
## thing for sale on the counter, two people passing through, and Pip, the
## King's page and herald, by the fountain. `show` holds them back until a
## flag (the rebuilt town's market district).
func _market(k, show := "") -> void:
	var sellers := {1: ["Fruit Seller", "folk_farmer", "heart", 10, "heart_mesh"], 3: ["Fletcher", "folk_grocer", "arrows_10", 20, "arrow_bundle_mesh"],
		5: ["Baker's Girl", "folk_baker", "honey_bun", 25, "honey_bun_mesh"], 7: ["Potion Stall", "folk_innkeeper", "red_potion", 40, "bottle_red_potion_mesh"]}
	for i: int in sellers:
		var a := TAU * i / 8.0 + 0.2
		var out := Vector2(cos(a), sin(a))
		var keeper := SQUARE + out * 13.0
		var sv: Array = sellers[i]
		k.npc(String(sv[0]), "res://assets/models/%s.tscn" % sv[1], "res://scripts/npc/market_lines.gd", keeper.x, keeper.y, k.yaw_of(-out), INF, {"show": show})
		var ware := SQUARE + out * 11.0
		var wy: float = k.h(ware.x, ware.y) + 1.02
		var w: Node3D = k._dyn("res://scripts/items/shop_item.gd", "Ware", Vector3(ware.x, wy, ware.y), 0.0,
			{"kind": sv[2], "price": sv[3], "mesh": sv[4]}, Node3D.new())
		if show != "":
			w.set("show_flag", show)
	k.npc("Townsman", "res://assets/models/folk_merchant.tscn", "res://scripts/npc/market_lines.gd", -6.0, 8.0, PI * 0.25, INF, {"show": show})
	k.npc("Townswoman", "res://assets/models/folk_washer.tscn", "res://scripts/npc/market_lines.gd", 6.5, -5.0, -PI * 0.7, INF, {"show": show})
	k.npc("Pip", "res://assets/models/pip.tscn", "res://scripts/npc/market_lines.gd", SQUARE.x + 3.4, SQUARE.y + 4.6, PI * 0.15, INF)


## The fallen town: scorched signs, goblins looting the streets, Sapphire
## Order mages keeping watch over the square and the castle bridge, keese
## turned to embers, and pots still holding what was left behind.
func _populate_fallen(k) -> void:
	k.signpost(-4.0, 36, Vector2(0, 32), "*Old Castle Town*\nThe sign is scorched black.\n\nSmoke rises from the castle\nbeyond the canal.")
	k.signpost(-31.0, -17.5, Vector2(-26, -14), "*Pink's Armory*\nThe door is barred from outside.\n\nScratched under the sign:\n\"Gone to fight at the castle. -P\"")
	k.signpost(-4.5, CANAL_Z + 6.0, Vector2(0, CANAL_Z + 9.0), "North: *Castle of Bunsriel*\nIts gate has been torn open.")
	for p in [Vector2(-7.0, 11.8), Vector2(-8.0, 11.9), Vector2(11.0, -9.0), Vector2(-10.6, -8.0), Vector2(23.0, 11.0), Vector2(-20.0, 11.0)]:
		k.pot(p.x, p.y)
	k.pot(9.4, -10.4, "bombs_5")
	k.pot(-9.4, 14.0, "heart")
	for c in [Vector2(0, 26), Vector2(18, 2), Vector2(-18, 2)]:
		k.enemies_near("basic_enemy", c, 5.0, 2)
	k.enemy("sapphire_mage", 0.0, -12.0, 0.0, {"roam": 6.0})
	k.enemy("sapphire_mage", 0.0, CANAL_Z - 10.0, 0.0, {"roam": 5.0})
	k.enemy("fire_keese", -14.0, -4.0, 0.0, {}, 4.0)
	k.enemy("fire_keese", 16.0, 16.0, 0.0, {}, 4.0)
	k.enemy("fire_keese", 0.0, CANAL_Z - 16.0, 0.0, {}, 6.0)
