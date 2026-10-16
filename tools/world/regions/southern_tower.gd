extends "res://tools/world/tower_region.gd"
## The Southern Tower, the first of the goddess towers: an old brick granary
## and mill on the farmland of the Southern Fields, four storeys of grain
## sacks, wooden beams and cog wheels. Strawmen walk its halls and rats run
## in its flooded cellar. Its treasure is the Hookshot; its master, Corvax
## the Harvest Crow, guards Alan's bun piece on the roof.
##
## Storeys (north is -Z):
##   B1 (y -8)  cistern   under the store, flooded ankle deep: rats; the ladder
##                        up through the store's floor
##              wheel     the mill's great water wheel, jammed: a crystal on its
##                        axle starts it (the mill runs: the cogs upstairs turn,
##                        the store's bars lift)
##              den       the rats' den: clear it for Small Key 2
##   1F (y 0)   entry     in from the fields
##              hub       the Granary, two storeys tall round its millstone:
##                        the Map; a gallery on the north wall at 2F height,
##                        reached with the Hookshot (a wooden target under it)
##              loom      west: strawmen and a Gear Beetle -> Small Key 1; the
##                        Compass
##              store     east (Small Key 1): two storeys of sacks, the hole
##                        down to the cellar, and stairs up to a barred door
##                        at 2F (the bars lift when the mill runs)
##   2F (y 8)   gears     the gear works (Small Key 2): mill-driven platforms
##                        shuttle across a pit -> Small Key 3
##              mill      the Rust Knight behind shutters -> the Hookshot
##              loft      the grain loft: hookshot across its pit to the Boss Key
##              stairs    a stairwell two storeys tall (Small Key 3) up to 3F
##   3F (y 16)  ante      the hall before the roof: the boss door
##              boss      the roof, open to the sky: Corvax; then the heart
##                        container, Alan's bun piece and the blue warp

const MK := preload("res://tools/mesh_kit.gd")
const D := "southern_tower"
const BRICK := ["b8604a", "c46c52", "aa5844"]
## The Granary's gallery at 2F height along its north wall.
const GALLERY_Z := Vector2(-14, -8)
const MILL_FLAG := D + ":mill_running"

## The roof (the boss room) is open to the evening sky.
var open_sky := true


func setup() -> void:
	id = "southern_tower"
	interior = true
	seed_value = 171
	x_min = -44.0
	x_max = 44.0
	z_min = -118.0
	z_max = 36.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0]]
	entry_floor = 1
	wall_col = Color(1.0, 0.82, 0.74)
	ceil_col = Color(0.55, 0.42, 0.34)
	slab_col = Color(0.95, 0.78, 0.68)
	var wood := Color(0.92, 0.78, 0.62)
	rooms = {
		# B1: the cellar.
		"cistern": {"f": 0, "r": Rect2(18, -12, 22, 24), "h": 6.5, "doors": [{"side": "w", "at": 0.0}], "col": Color(0.78, 0.68, 0.62)},
		"wheel": {"f": 0, "r": Rect2(-10, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}, {"side": "w", "at": 0.0}], "col": Color(0.78, 0.68, 0.62)},
		"den": {"f": 0, "r": Rect2(-36, -8, 18, 16), "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.72, 0.62, 0.56)},
		# 1F.
		"entry": {"f": 1, "r": Rect2(-6, 18, 12, 14), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"hub": {"f": 1, "r": Rect2(-14, -14, 28, 28), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		"loom": {"f": 1, "r": Rect2(-38, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"store": {"f": 1, "r": Rect2(18, -12, 22, 24), "h": 14.5, "doors": [{"side": "w", "at": 0.0}, {"side": "n", "at": 37.5, "y0": 8.0}]},
		# 2F: wooden floors.
		"gears": {"f": 2, "r": Rect2(18, -42, 22, 24), "h": 6.5, "doors": [{"side": "s", "at": 37.5}, {"side": "w", "at": -30.0}], "floor_col": wood, "floor_mat": "wood"},
		"mill": {"f": 2, "r": Rect2(-12, -44, 24, 26), "h": 6.5, "doors": [{"side": "e", "at": -30.0}, {"side": "w", "at": -30.0}, {"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "floor_col": wood, "floor_mat": "wood"},
		"loft": {"f": 2, "r": Rect2(-40, -42, 22, 24), "h": 6.5, "doors": [{"side": "e", "at": -30.0}], "floor_col": wood, "floor_mat": "wood"},
		"stairs": {"f": 2, "r": Rect2(-7, -64, 14, 16), "h": 14.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0, "y0": 8.0}]},
		# 3F.
		"ante": {"f": 3, "r": Rect2(-8, -82, 16, 14), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"boss": {"f": 3, "r": Rect2(-14, -114, 28, 28), "h": 6.0, "doors": [{"side": "s", "at": 0.0}], "ceiling": false},
	}
	corridors = [
		{"f": 0, "r": Rect2(10, -2, 8, 4), "x": true},
		{"f": 0, "r": Rect2(-18, -2, 8, 4), "x": true},
		{"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-18, -2, 4, 4), "x": true},
		{"f": 1, "r": Rect2(14, -2, 4, 4), "x": true},
		{"f": 2, "r": Rect2(35.5, -18, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-2, -18, 4, 4), "x": false},
		{"f": 2, "r": Rect2(12, -32, 6, 4), "x": true},
		{"f": 2, "r": Rect2(-18, -32, 6, 4), "x": true},
		{"f": 2, "r": Rect2(-2, -48, 4, 4), "x": false},
		{"f": 3, "r": Rect2(-2, -68, 4, 4), "x": false},
		{"f": 3, "r": Rect2(-2, -86, 4, 4), "x": false},
	]
	holes = [
		# The hole in the store's floor where the ladder climbs from the cistern.
		{"f": 1, "r": Rect2(18, 8.6, 2.55, 2.6)},
		# The pits of the gear works and the grain loft.
		{"f": 2, "r": Rect2(18, -36, 22, 12)},
		{"f": 2, "r": Rect2(-34, -42, 12, 24)},
	]
	water = [
		{"rect": Rect2(18, -12, 22, 24), "y": -7.55, "col": Color(0.3, 0.38, 0.32, 0.8)},
		{"rect": Rect2(-10, -3, 20, 6), "y": -7.4, "col": Color(0.28, 0.4, 0.42, 0.8)},
	]
	mood = {
		# Warm, dusty light inside; the sky over the roof is a gold evening.
		"sky_top": Color.html("3a58b0"), "sky_mid": Color.html("8a8ac8"), "sky_horizon": Color.html("f0b878"),
		"cloud": Color.html("ffe0b8"), "cloud_amount": 0.35,
		"fog": Color.html("2a1a14"), "fog_begin": 18.0, "fog_end": 70.0,
		"ambient": Color.html("7a5c4a"), "sun": Color.html("ffd0a0"), "sun_rot": Vector3(-60, -40, 0),
		"sun_energy": 0.75, "fill": Color.html("6a5a7a"), "fill_energy": 0.4,
		"horizon": Color.html("8a6a5a"), "hill_height": 0.0,
	}


## Damp flagstones in the cellar (dark earth beyond its rooms, under the
## pits), herringbone brick on 1F, planks on 2F, worn brick on top.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	match f:
		0:
			var inside := false
			for id: String in ["cistern", "wheel", "den"]:
				if (rooms[id].r as Rect2).grow(1.0).has_point(Vector2(x, z)):
					inside = true
			for c: Dictionary in corridors:
				if c.f == 0 and (c.r as Rect2).has_point(Vector2(x, z)):
					inside = true
			if not inside:
				return pick(r, ["1a1210", "20160f"])
			var seam := fposmod(x, 1.5) < 0.1 or fposmod(z + (0.75 if int(floor(x / 1.5)) % 2 == 0 else 0.0), 1.5) < 0.1
			return Color.html("3a3230") if seam else Color.html(pick_hex(r, ["5a524a", "625a50", "544c44"])).darkened(r.randf_range(0.0, 0.1))
		2:
			var plank := int(floor(x / 0.6))
			var c := Color.html(["a8805a", "b48a62", "9e7854"][posmod(plank, 3)])
			if fposmod(x, 0.6) < 0.05:
				c = Color.html("5a3a24")
			return c.darkened(r.randf_range(0.0, 0.08))
	var bx := x * 2.0
	var bz := z * 2.0
	var row := int(floor(bz / 1.0))
	var off := 0.5 if row % 2 == 0 else 0.0
	var seam := fposmod(bz, 1.0) < 0.1 or fposmod(bx * 0.5 + off, 1.0) < 0.06
	if seam:
		return Color.html("5a3a2a")
	var c := Color.html(BRICK[posmod(row + int(floor(bx * 0.5 + off)), 3)])
	if f == 1 and (rooms.hub.r as Rect2).has_point(Vector2(x, z)) and Vector2(x, z).length() < 6.0:
		c = c.lerp(Color.html("d8c08a"), 0.35)
	return c.darkened(r.randf_range(0.0, 0.1))


func pick_hex(r: RandomNumberGenerator, list: Array) -> String:
	return list[r.randi() % list.size()]


func build_rooms(k) -> void:
	# The way out to the fields, and where the hero arrives.
	k.door_link(Vector3(0, 0, 31.98), 0.0, 1.8, 2.8, "southern_fields", "from_southern_tower")
	k.entrance("from_southern_fields", 0.0, 29.0, 0.0)
	_cistern(k)
	_wheel(k)
	_den(k)
	_entry(k)
	_hub(k)
	_loom(k)
	_store(k)
	_gears(k)
	_mill(k)
	_loft(k)
	_stairwell(k)
	_ante(k)
	_roof(k)


# --- Decoration -----------------------------------------------------------------

func _beam(k, a: Vector3, b: Vector3, w := 0.4) -> void:
	var m = k._tmp()
	var mid := (a + b) * 0.5
	var basis := Basis.looking_at((b - a).normalized(), Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.BACK)
	m.push(Transform3D(basis, mid))
	m.box(Vector3.ZERO, Vector3(w, w, a.distance_to(b)), Color(0.75, 0.6, 0.45))
	m.pop()
	k.merge(m, "wood")


## A heap of grain sacks.
func _sacks(k, x: float, z: float, y := 0.0) -> void:
	var s = k._tmp(false)
	for i in 4:
		var p := Vector3(x + (i % 2) * 0.7 - 0.35, y + 0.3 + (i / 2) * 0.45, z + (i / 2) * 0.2)
		s.icosa(p, Vector3(0.38, 0.3, 0.3), 0.1, Color.html(["d8c49a", "ccb88c"][i % 2]))
	k.merge(s, "char")


## A big wooden cog wheel standing against a wall, built about its own center
## into the kit `g` (so it can turn as a Spinner).
func _cog_mesh(g, r: float) -> void:
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	g.prism(Vector3(0, -0.15, 0), r, Vector3(0, 0.15, 0), r, 16, Color(0.7, 0.55, 0.4))
	g.prism(Vector3(0, -0.2, 0), r * 0.25, Vector3(0, 0.2, 0), r * 0.25, 8, Color(0.5, 0.4, 0.3))
	for i in 16:
		var a := TAU * i / 16.0
		g.push(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * (r + 0.15), 0, sin(a) * (r + 0.15))))
		g.box(Vector3.ZERO, Vector3(0.3, 0.26, 0.24), Color(0.62, 0.48, 0.34))
		g.pop()
	g.pop()


## A cog on the wall facing `yaw`, which turns while the mill runs.
func _cog(k, c: Vector3, yaw: float, r: float, dir := 1.0) -> void:
	var g := MK.new(int(absf(c.x * 13.0 + c.z * 7.0 + c.y)))
	g.textured = true
	_cog_mesh(g, r)
	var sp = k._dyn("res://scripts/dungeon/spinner.gd", "Cog", c, yaw, {"flag": MILL_FLAG, "axis": Vector3(0, 0, 1), "speed": 25.0 * dir / maxf(r, 0.5)}, Node3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = g.build(k.M.wood)
	sp.add_child(mi)


func _torch(k, x: float, z: float, y := 0.0) -> void:
	k.brazier(x, z, true, y)


func _wall_lamps(k, id: String, inset := 2.5) -> void:
	var r: Rect2 = rooms[id].r
	var y := room_y(id)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		_torch(k, p.x, p.y, y)


func _railing(k, a: Vector3, b: Vector3) -> void:
	var rail = k._tmp()
	var n := maxi(2, int(a.distance_to(b) / 2.0) + 1)
	for i in n:
		var p := a.lerp(b, float(i) / (n - 1))
		rail.box(p + Vector3(0, 0.5, 0), Vector3(0.12, 1.0, 0.12), Color(0.7, 0.55, 0.42))
	var mid := (a + b) * 0.5 + Vector3(0, 1.0, 0)
	var along := b - a
	rail.box(mid, Vector3(maxf(absf(along.x), 0.14), 0.12, maxf(absf(along.z), 0.14)), Color(0.7, 0.55, 0.42))
	k.merge(rail, "wood")
	k.col_box((a + b) * 0.5 + Vector3(0, 0.55, 0), Vector3(maxf(absf(along.x), 0.2), 1.1, maxf(absf(along.z), 0.2))).set_meta("no_climb", true)


# --- B1: the cellar ---------------------------------------------------------------

func _cistern(k) -> void:
	var y := room_y("cistern")
	# The stone pier under the far edge of the hole in the store's floor; the
	# ladder hangs on its face.
	k.block(Vector3(21.0, (y - 0.5) * 0.5, 9.9), Vector3(0.8, -0.5 - y, 2.6), 0.0, "stone", Color(0.8, 0.7, 0.62))
	k.ladder(20.55, 9.9, Vector2(-1, 0), y, 0.0)
	for p in [Vector2(22, -8), Vector2(36, -8), Vector2(36, 4), Vector2(29, -2)]:
		k.pillar(p.x, p.y, 6.5, 0.5, false, "stone", y)
	_wall_lamps(k, "cistern")
	_sacks(k, 37.5, 9.5, y)
	k.pot(24.5, 10.5, "", false, y)
	k.pot(25.5, 10.5, "heart", false, y)
	k.chest(37.5, -9.5, PI, "rupee_red", false, D + ":chest_cistern", "", y)


func _wheel(k) -> void:
	var y := room_y("wheel")
	_wall_lamps(k, "wheel")
	# The great water wheel in its channel, turning once the mill runs.
	var g := MK.new(431)
	g.textured = true
	var rr := 2.6
	g.push(Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3.ZERO))
	g.prism(Vector3(0, -1.0, 0), rr, Vector3(0, -0.85, 0), rr, 16, Color(0.6, 0.46, 0.32))
	g.prism(Vector3(0, 0.85, 0), rr, Vector3(0, 1.0, 0), rr, 16, Color(0.6, 0.46, 0.32))
	g.prism(Vector3(0, -1.2, 0), 0.35, Vector3(0, 1.2, 0), 0.35, 8, Color(0.45, 0.36, 0.28))
	for i in 12:
		var a := TAU * i / 12.0
		g.push(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * (rr - 0.2), 0, sin(a) * (rr - 0.2))))
		g.box(Vector3.ZERO, Vector3(0.6, 2.0, 0.12), Color(0.72, 0.56, 0.4))
		g.pop()
	g.pop()
	var sp = k._dyn("res://scripts/dungeon/spinner.gd", "WaterWheel", Vector3(0, y + 2.4, 0), 0.0, {"flag": MILL_FLAG, "axis": Vector3(1, 0, 0), "speed": -40.0}, Node3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = g.build(k.M.wood)
	sp.add_child(mi)
	k.col_cyl(Vector3(0, y, 0), 1.2, 5.0)
	# The axle bearings on stone piers either side of the channel, and the
	# crystal set in the jammed brake on the north one.
	for sx in [-1.0, 1.0]:
		k.block(Vector3(sx * 1.6, y + 1.2, 0), Vector3(0.8, 2.4, 1.2), 0.0, "stone", Color(0.75, 0.68, 0.62))
	k.crystal_switch(0.0, -4.5, MILL_FLAG, y + 3.4)
	k.block(Vector3(0, y + 1.7, -4.5), Vector3(1.0, 3.4, 1.0), 0.0, "stone", Color(0.7, 0.62, 0.56)).set_meta("no_climb", true)
	_cog(k, Vector3(-9.6, y + 3.5, 6.0), PI * 0.5, 1.8)
	_cog(k, Vector3(9.6, y + 3.0, -6.0), -PI * 0.5, 1.4, -1.0)
	k.pot(-8.5, 8.5, "arrows_10", false, y)
	k.pot(8.5, 8.5, "", false, y)


func _den(k) -> void:
	var y := room_y("den")
	k.shutter(-18.6, 0.0, PI / 2.0, "den", y)
	_wall_lamps(k, "den")
	for p in [Vector2(-33, -5), Vector2(-33, 5), Vector2(-24, 6)]:
		_sacks(k, p.x, p.y, y)
	k.chest(-30.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key2", D + ":den_clear", y)
	# Behind a false wall on the north side (Mira's Looking Glass), a red rupee.
	k.lens_alcove(Vector2(-27.0, -8.0), Vector2(0, 1), 3.0, 2.4, y, "rupee_red", D + ":chest_lens", "stone", wall_col * Color(0.85, 0.8, 0.78))
	# Three old pegs in the floor: drive them down with the Iron Mallet and a
	# chest appears (Beta 1.7.0; the Mallet comes later, in the castle).
	var stakes: Array = []
	for s in [[-34.5, 0.0, "stake_a"], [-23.5, -4.5, "stake_b"], [-23.5, 2.5, "stake_c"]]:
		k.mallet_stake(s[0], s[1], D + ":" + s[2], y)
		stakes.append(D + ":" + s[2])
	k.flag_all(stakes, D + ":stakes")
	k.chest(-21.5, -6.2, PI, "rupee_purple", false, D + ":chest_stakes", D + ":stakes", y)


# --- 1F --------------------------------------------------------------------------

func _entry(k) -> void:
	for z in [22.0, 28.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.5, z, 6.5, 0.45, false, "stone", 0.0)
	_torch(k, -2.6, 19.5)
	_torch(k, 2.6, 19.5)
	_sacks(k, -4.8, 30.5)
	k.pot(4.8, 30.5)
	k.pot(4.8, 29.5, "heart")
	_beam(k, Vector3(-6, 6.0, 25), Vector3(6, 6.0, 25))


func _hub(k) -> void:
	# The great millstone on its spindle in the middle, turning once the mill
	# runs, and the spindle beam up into the dark.
	var ms := MK.new(77)
	ms.textured = true
	ms.prism(Vector3(0, 0, 0), 3.0, Vector3(0, 0.9, 0), 3.0, 16, Color(0.75, 0.72, 0.68))
	ms.prism(Vector3(0, 0.9, 0), 2.6, Vector3(0, 1.4, 0), 2.4, 16, Color(0.7, 0.66, 0.62))
	for i in 4:
		var a := TAU * i / 4.0
		ms.box(Vector3(cos(a) * 1.6, 1.45, sin(a) * 1.6), Vector3(0.5, 0.1, 0.2), Color(0.55, 0.52, 0.48))
	var sp = k._dyn("res://scripts/dungeon/spinner.gd", "Millstone", Vector3.ZERO, 0.0, {"flag": MILL_FLAG, "axis": Vector3.UP, "speed": 20.0}, Node3D.new())
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = ms.build(k.M.rock)
	sp.add_child(mi)
	k.col_cyl(Vector3(0, 0, 0), 3.0, 1.4)
	_beam(k, Vector3(0, 1.4, 0), Vector3(0, 14.5, 0), 0.6)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		_beam(k, Vector3(0, 10.0, 0), Vector3(cos(a) * 13.5, 13.0, sin(a) * 13.5), 0.35)
	# The gallery at 2F height along the north wall, its railing, the beams
	# under it, and the wooden target under its rim: the way up.
	var up := fy(2)
	k.block(Vector3(0, up - 0.25, (GALLERY_Z.x + GALLERY_Z.y) * 0.5), Vector3(28, 0.5, GALLERY_Z.y - GALLERY_Z.x), 0.0, "wood", Color(0.9, 0.76, 0.62))
	for x in [-12.0, -6.0, 6.0, 12.0]:
		_beam(k, Vector3(x, 0, GALLERY_Z.y - 0.3), Vector3(x, up - 0.5, GALLERY_Z.y - 0.3), 0.4)
	_railing(k, Vector3(-13.8, up, GALLERY_Z.y - 0.1), Vector3(-1.6, up, GALLERY_Z.y - 0.1))
	_railing(k, Vector3(1.6, up, GALLERY_Z.y - 0.1), Vector3(13.8, up, GALLERY_Z.y - 0.1))
	k.hook_target(Vector3(0, up - 0.9, GALLERY_Z.y + 0.08), PI)
	_cog(k, Vector3(-13.6, 5.0, 6.0), PI * 0.5, 2.6)
	_cog(k, Vector3(13.6, 4.0, 5.0), -PI * 0.5, 2.0, -1.0)
	for p in [Vector2(-11, 10), Vector2(11, 10), Vector2(-11, 2)]:
		_sacks(k, p.x, p.y)
	_torch(k, -2.6, 12.5)
	_torch(k, 2.6, 12.5)
	_torch(k, -12.5, -2.6)
	_torch(k, 12.5, -2.6)
	_torch(k, 12.5, 2.6)
	k.locked_door(15.4, 0.0, PI / 2.0, D + ":door_key1")
	k.chest(-9.0, 9.0, PI * 0.5, "map", false, D + ":chest_map")
	for p in [Vector2(10.5, 12.5), Vector2(12.0, 12.5), Vector2(-12.5, -6.0)]:
		k.pot(p.x, p.y, "", false)
	_torch(k, -2.6, GALLERY_Z.x + 1.5, up)
	_torch(k, 2.6, GALLERY_Z.x + 1.5, up)


func _loom(k) -> void:
	k.shutter(-18.6, 0.0, PI / 2.0, "loom")
	_cog(k, Vector3(-37.6, 3.0, -4.0), PI * 0.5, 2.2)
	_cog(k, Vector3(-37.6, 2.2, 5.0), PI * 0.5, 1.4, -1.0)
	for p in [Vector2(-34, -8), Vector2(-22, 8)]:
		_sacks(k, p.x, p.y)
	_torch(k, -20.5, -3.0)
	_torch(k, -20.5, 3.0)
	k.chest(-28.0, 0.0, -PI / 2.0, "small_key", false, D + ":chest_key1", D + ":loom_clear")
	k.chest(-35.5, 8.0, -PI / 2.0, "compass", false, D + ":chest_compass")
	k.pot(-36.5, -8.5, "arrows_10")
	k.pot(-35.5, -8.5)


func _store(k) -> void:
	var up := fy(2)
	_wall_lamps(k, "store")
	# Stairs up the east side to a landing at 2F height and the barred door.
	k.stairs(37.5, 10.5, 0.0, 3.0, 12.0, up, "stone", 0.0)
	k.block(Vector3(37.9, up * 0.5, -6.75), Vector3(4.2, up, 10.5), 0.0, "stone", Color(0.9, 0.74, 0.66))
	_railing(k, Vector3(35.85, up, -11.8), Vector3(35.85, up, -1.6))
	k.flag_bars(37.5, -12.4, 0.0, MILL_FLAG, up)
	for p in [Vector2(21, -9), Vector2(21, -3), Vector2(26, 9), Vector2(30, -9), Vector2(24, -9)]:
		_sacks(k, p.x, p.y)
	# A ring of sacks round the hole in the floor.
	for p in [Vector2(23.4, 9.5), Vector2(23.4, 11.4)]:
		k.pot(p.x, p.y)
	_cog(k, Vector3(18.4, 9.0, -4.0), PI * 0.5, 2.4)
	for x in [24.0, 31.0]:
		_beam(k, Vector3(x, 12.0, -12), Vector3(x, 12.0, 12), 0.4)


# --- 2F --------------------------------------------------------------------------

func _gears(k) -> void:
	var y := room_y("gears")
	var r: Rect2 = rooms.gears.r
	k.locked_door(37.5, -16.4, 0.0, D + ":door_key2", false, y)
	_wall_lamps(k, "gears")
	# Falling into the pit returns the hero to where he came in.
	k.void_zone(Vector3(29, y - 5.0, -30), Vector3(22, 2.0, 12), 2)
	# Two platforms on the mill's drive shuttle across: one by the east wall,
	# one by the west (to the pots in the far corner).
	k.lift(Vector3(36.0, y, -25.6), Vector3(3.0, 0.6, 3.0), Vector3(0, 0, -8.8), "wood", Color(0.85, 0.7, 0.55), {"loop": true, "flag": MILL_FLAG, "speed": 2.0, "rest": 1.4})
	k.lift(Vector3(21.5, y, -34.4), Vector3(3.0, 0.6, 3.0), Vector3(0, 0, 8.8), "wood", Color(0.85, 0.7, 0.55), {"loop": true, "flag": MILL_FLAG, "speed": 2.4, "rest": 1.0})
	for x in [22.0, 30.0, 38.0]:
		_cog(k, Vector3(x, y + 3.2, r.position.y + 0.4), 0.0, 1.6, -1.0 if int(x) % 4 == 0 else 1.0)
	_beam(k, Vector3(18, y + 5.5, -30), Vector3(40, y + 5.5, -30), 0.4)
	k.chest(30.0, -39.5, 0.0, "small_key", false, D + ":chest_key3", "", y)
	k.pot(20.0, -40.5, "rupee_blue", false, y)
	k.pot(21.0, -40.5, "", false, y)


func _mill(k) -> void:
	var y := room_y("mill")
	for s in [[11.4, -30.0, PI / 2.0], [-11.4, -30.0, PI / 2.0], [0.0, -18.6, 0.0], [0.0, -43.4, 0.0]]:
		k.shutter(s[0], s[1], s[2], "mill", y)
	for p in [Vector2(-7, -24), Vector2(7, -24), Vector2(-7, -38), Vector2(7, -38)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	# Either side of the north doorway (one across it hid the way out).
	_cog(k, Vector3(-6.8, y + 3.5, -43.6), 0.0, 3.0)
	_cog(k, Vector3(6.8, y + 3.0, -43.6), 0.0, 2.2, -1.0)
	_wall_lamps(k, "mill")
	for x in [-4.0, 4.0]:
		k.banner(x, y + 5.5, -19.0, PI, Color.html("8a3a2a"), 3.0)
	k.chest(0.0, -31.0, PI, "hookshot", true, D + ":chest_hookshot", D + ":mill_clear", y)
	k.locked_door(0.0, -46.0, 0.0, D + ":door_key3", false, y)


func _loft(k) -> void:
	var y := room_y("loft")
	_wall_lamps(k, "loft", 1.6)
	k.void_zone(Vector3(-28, y - 5.0, -30), Vector3(12, 2.0, 24), 2)
	# The island in the middle of the pit, with a post carrying a target on
	# each side; a target on a post on the far (west) ledge.
	k.block(Vector3(-28, y - 0.5, -30), Vector3(4, 1.0, 4), 0.0, "wood", Color(0.85, 0.7, 0.55))
	# (Each post's east face looks back toward the way in, its west face on.)
	for p in [Vector3(-26.8, y, -30), Vector3(-38.4, y, -26), Vector3(-20.6, y, -26)]:
		k.block(Vector3(p.x, y + 1.6, p.z), Vector3(0.8, 3.2, 0.8), 0.0, "wood", Color(0.8, 0.62, 0.45)).set_meta("no_climb", true)
		if p.x > -38.0:
			k.hook_target(Vector3(p.x - 0.48, y + 2.1, p.z), PI / 2.0)
		if p.x < -21.0:
			k.hook_target(Vector3(p.x + 0.48, y + 2.1, p.z), -PI / 2.0)
	_sacks(k, -38, -40, y)
	_sacks(k, -21, -40, y)
	k.chest(-37.0, -33.0, PI / 2.0, "boss_key", true, D + ":chest_boss_key", "", y)
	k.pot(-38.5, -20.5, "", false, y)
	k.pot(-38.5, -21.5, "arrows_10", false, y)


func _stairwell(k) -> void:
	var y := room_y("stairs")
	# Up the middle to a landing at 3F height and the door north.
	k.stairs(0.0, -50.0, 0.0, 3.0, 11.0, FLOOR_H, "stone", y)
	k.block(Vector3(0, y + FLOOR_H * 0.5, -62.5), Vector3(6.0, FLOOR_H, 3.0), 0.0, "stone", Color(0.9, 0.74, 0.66))
	_wall_lamps(k, "stairs", 1.6)
	_torch(k, -2.4, -62.5, y + FLOOR_H)
	_torch(k, 2.4, -62.5, y + FLOOR_H)


# --- 3F --------------------------------------------------------------------------

func _ante(k) -> void:
	var y := room_y("ante")
	_wall_lamps(k, "ante", 1.6)
	for x in [-5.0, 5.0]:
		k.pillar(x, -75, 6.5, 0.5, false, "stone", y)
	k.locked_door(0.0, -84.0, 0.0, D + ":boss_door", true, y)
	k.pot(-6.5, -80.5, "heart", false, y)
	k.pot(6.5, -80.5, "", false, y)


func _roof(k) -> void:
	var y := room_y("boss")
	var r5: Rect2 = rooms.boss.r
	var c := r5.get_center()
	k.shutter(0.0, r5.end.y - 0.6, 0.0, "boss", y)
	# Battlements round the roof, and an old scarecrow's post in the middle.
	var crenel = k._tmp()
	for side in [r5.position.y, r5.end.y]:
		var x := r5.position.x + 1.0
		while x < r5.end.x:
			if absf(x) > 2.0 or side == r5.position.y:
				crenel.box(Vector3(x, y + 6.4, side), Vector3(1.0, 0.8, 0.9), Color(0.95, 0.75, 0.66))
			x += 2.0
	for side in [r5.position.x, r5.end.x]:
		var z := r5.position.y + 1.0
		while z < r5.end.y:
			crenel.box(Vector3(side, y + 6.4, z), Vector3(0.9, 0.8, 1.0), Color(0.95, 0.75, 0.66))
			z += 2.0
	k.merge(crenel, "stone")
	var post = k._tmp()
	post.prism(Vector3(c.x, y, c.y), 0.15, Vector3(c.x, y + 2.6, c.y), 0.12, 6, Color(0.6, 0.45, 0.3))
	post.box(Vector3(c.x, y + 2.2, c.y), Vector3(2.0, 0.12, 0.12), Color(0.6, 0.45, 0.3))
	k.merge(post, "wood")
	k.col_cyl(Vector3(c.x, y, c.y), 0.2, 2.6)
	for p in [Vector2(r5.position.x + 1.5, r5.position.y + 1.5), Vector2(r5.end.x - 1.5, r5.position.y + 1.5), Vector2(r5.position.x + 1.5, r5.end.y - 1.5), Vector2(r5.end.x - 1.5, r5.end.y - 1.5)]:
		_torch(k, p.x, p.y, y)
	_sacks(k, -12.0, c.y - 2.0, y)
	_sacks(k, 12.0, c.y - 8.0, y)
	var clear := D + ":boss_clear"
	k.heart_container(c.x - 3.0, c.y + 4.0, clear, D + ":heart_container", y)
	k.bun_piece(c.x + 3.0, c.y + 4.0, "alan", clear, y)
	k.blue_warp(c.x, c.y - 4.0, clear, "southern_fields", "warp_southern_tower", y)
	k.heart_piece(r5.end.x - 2.0, r5.position.y + 2.0, D + ":heart_piece", y)


# --- Creatures ------------------------------------------------------------------

func populate(k) -> void:
	var b1 := fy(0)
	var f2 := fy(2)
	var f3 := fy(3)
	k.enemy("rat", 26.0, 4.0, PI, {"room": "cistern"}, b1)
	k.enemy("rat", 32.0, -4.0, 0.0, {"room": "cistern"}, b1)
	k.enemy("rat", 24.0, -6.0, 0.0, {"room": "cistern"}, b1)
	k.enemy("keese", -6.0, 6.0, 0.0, {"room": "wheel"}, b1 + 4.5)
	k.enemy("keese", 6.0, -6.0, 0.0, {"room": "wheel"}, b1 + 4.5)
	k.enemy("rat", -30.0, -4.0, PI / 2.0, {"room": "den"}, b1)
	k.enemy("rat", -30.0, 4.0, PI / 2.0, {"room": "den"}, b1)
	k.enemy("rat", -24.0, -4.0, PI / 2.0, {"room": "den"}, b1)
	k.enemy("rat", -24.0, 4.0, PI / 2.0, {"room": "den"}, b1)
	k.enemy("strawman", -27.0, 0.0, PI / 2.0, {"room": "den"}, b1)
	k.enemy("strawman", 2.5, 24.0, PI, {"room": "entry"})
	k.enemy("keese", -8.0, -8.0, 0.0, {"room": "hub"}, 5.0)
	k.enemy("straw_archer", 8.0, -11.0, PI, {"room": "hub"}, fy(2))
	k.enemy("strawman", -32.0, -5.0, PI / 2.0, {"room": "loom"})
	k.enemy("strawman", -32.0, 5.0, PI / 2.0, {"room": "loom"})
	k.enemy("gear_beetle", -25.0, 0.0, PI / 2.0, {"room": "loom"})
	k.enemy("rat", 28.0, 2.0, PI / 2.0, {"room": "store"})
	k.enemy("gear_beetle", 26.0, -6.0, PI / 2.0, {"room": "store"})
	k.enemy("straw_archer", 26.0, -39.0, 0.0, {"room": "gears"}, f2)
	k.enemy("straw_archer", 34.0, -39.0, 0.0, {"room": "gears"}, f2)
	k.enemy("keese", 29.0, -30.0, 0.0, {"room": "gears"}, f2 + 3.0)
	k.enemy("rust_knight", 0.0, -36.0, 0.0, {"room": "mill"}, f2)
	k.enemy("straw_archer", -28.0, -31.0, -PI / 2.0, {"room": "loft"}, f2)
	k.enemy("gear_beetle", -38.0, -38.0, -PI / 2.0, {"room": "loft"}, f2)
	k.enemy("gear_beetle", -38.0, -22.0, -PI / 2.0, {"room": "loft"}, f2)
	k.enemy("keese", -3.0, -56.0, 0.0, {"room": "stairs"}, f2 + 4.0)
	k.enemy("keese", 3.0, -54.0, 0.0, {"room": "stairs"}, f2 + 6.0)
	k.enemy("strawman", -4.0, -76.0, 0.0, {"room": "ante"}, f3)
	k.enemy("strawman", 4.0, -76.0, 0.0, {"room": "ante"}, f3)
	k.enemy("straw_archer", 0.0, -80.5, 0.0, {"room": "ante"}, f3)
	var r5: Rect2 = rooms.boss.r
	k.enemy("corvax", r5.get_center().x, r5.get_center().y - 6.0, 0.0, {"room": "boss"}, f3 + 3.0)
