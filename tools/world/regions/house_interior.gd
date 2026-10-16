extends "res://tools/world/region.gd"
## A house you can walk into (Beta 1.5.0): one generator for every interior
## in HouseData.HOUSES (Castle Town's homes and shops, Haven's cottages,
## Ashwick's tents). gen_world sets `next_id` before making one; setup() reads
## the house's entry and builds a room furnished for its kind, its people
## standing where they would (behind a counter, by the hearth, on the
## tavern's little stage), and the door in the south wall leading back out to
## the "from_<id>" entrance in the parent area.

static var next_id := ""

const FLOOR_Y := 0.0
const PLANK := ["8a6440", "946c46", "7e5a3a", "9a7450"]

var house := {}
var kind := "home"
var W := 9.0
var D := 7.0
var WALL_H := 3.6


func setup() -> void:
	id = next_id
	house = HouseData.HOUSES.get(id, {})
	kind = house.get("kind", "home")
	match kind:
		"inn":
			W = 14.0
			D = 11.0
			WALL_H = 4.2
		"tent":
			W = 6.5
			D = 6.0
			WALL_H = 3.0
		"scholar", "shop", "apothecary":
			W = 10.0
			D = 8.0
	interior = true
	seed_value = 2000 + id.hash() % 1000
	x_min = -W * 0.5
	x_max = W * 0.5
	z_min = -D * 0.5
	z_max = D * 0.5
	outer = 3.0
	cell = 1.0
	tex_size = 128
	rim_height = 0.0
	links = []
	water = []
	var warm := kind != "tent"
	mood = {
		"sky_top": Color.html("2a1e18"), "sky_mid": Color.html("2a1e18"), "sky_horizon": Color.html("2a1e18"),
		"cloud": Color.html("2a1e18"), "cloud_amount": 0.0,
		"fog": Color.html("1a120e"), "fog_begin": 20.0, "fog_end": 60.0,
		"ambient": Color.html("8a7866" if warm else "6a665e"), "sun": Color.html("fff0c8" if warm else "d8d0c0"), "sun_rot": Vector3(-60, 30, 0),
		"sun_energy": 0.8, "fill": Color.html("6a7a9a"), "fill_energy": 0.3,
		"horizon": Color.html("2a1e18"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func surface_at(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "ash" if kind == "tent" else "wood"


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	if kind == "tent":
		return Color.html(["4a4440", "524c46", "48423c"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.1))
	var row := int(floor((x + 20.0) / 0.45))
	var c := Color.html(PLANK[row % PLANK.size()])
	if fposmod(x + 20.0, 0.45) < 0.035 or fposmod(z + 20.0 + row * 0.9, 2.2) < 0.035:
		return c.darkened(0.35)
	# A rug in the middle of the room.
	if absf(x) < W * 0.2 and absf(z) < D * 0.18:
		return Color.html(["a83a3a", "3a5aa8", "6a8a3a"][id.hash() % 3]).darkened(0.1 if fposmod(x * 3.0, 1.0) < 0.5 else 0.0)
	return c.darkened(r.randf_range(0.0, 0.08))


func build(k) -> void:
	var wall := Color.html(String(house.get("wall", "f0e0c8")))
	var parent_link: String = house.get("parent", "castle_town")
	if kind == "tent":
		_tent_walls(k, wall)
	else:
		k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "plaster", wall, Color(0.7, 0.58, 0.46))
		for wx in [-W * 0.3, W * 0.3]:
			var pane = k._tmp(false)
			pane.box(Vector3(wx, 1.8, D * 0.5 - 0.05), Vector3(1.0, 0.9, 0.04), Color.html("f0e8d0"))
			k.merge(pane, "glow")
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.2, 2.2, parent_link, "from_" + id, Color(0.85, 0.75, 0.6) if kind != "tent" else Color(0.5, 0.45, 0.38))
	k.entrance("from_" + parent_link, 0.0, D * 0.5 - 1.3, 0.0)
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0, WALL_H - 0.6, 0.0)
	lamp.light_color = Color.html("ffd8a0")
	lamp.light_energy = 0.95
	lamp.omni_range = maxf(W, D) * 1.1
	k._misc.add_child(lamp)
	match kind:
		"home":
			_home(k)
		"bakery":
			_counter(k, Color(0.78, 0.6, 0.42))
			_oven(k)
			_sacks(k)
			_goods(k, "bread")
		"tailor":
			_counter(k, Color(0.7, 0.52, 0.4))
			_bolts(k)
			_mannequin(k, Vector2(W * 0.5 - 1.2, 0.6))
		"grocer":
			_counter(k, Color(0.7, 0.6, 0.4))
			_goods(k, "veg")
			_crates(k)
		"scholar":
			_bookshelves(k)
			_desk(k)
		"inn":
			_inn(k)
		"workshop":
			_bench(k)
			_crates(k)
		"shop":
			_counter(k, Color(0.72, 0.56, 0.4))
			_goods(k, "glass")
		"apothecary":
			_counter(k, Color(0.6, 0.5, 0.36))
			_goods(k, "bottles")
			_cauldron(k)
		"chandler":
			_counter(k, Color(0.7, 0.56, 0.4))
			_goods(k, "candles")
		"tent":
			_tent(k)
	if kind != "inn" and kind != "tent":
		_hearth(k)


func populate(k) -> void:
	var spots := _spots()
	var folk: Array = house.get("folk", [])
	for i in folk.size():
		var f: Array = folk[i]
		var model := "res://assets/models/%s.tscn" % f[1]
		var s: Vector3 = spots[mini(i, spots.size() - 1)]
		var opts := {"show": String(f[2]), "hide": String(f[3])}
		# The band plays while nobody is talking to them.
		if String(f[1]).begins_with("folk_bard"):
			opts["idle"] = "play"
		k.npc(String(f[0]), model, "res://scripts/npc/house_lines.gd", s.x, s.z, s.y, FLOOR_Y, opts)


## Where the people stand: (x, yaw, z) per kind.
func _spots() -> Array:
	var cz := -D * 0.5 + 1.25
	match kind:
		"inn":
			return [Vector3(-W * 0.5 + 1.6, PI * 0.5, -1.0), Vector3(-1.6, 0.0, -D * 0.5 + 1.6), Vector3(0.0, 0.0, -D * 0.5 + 1.5), Vector3(1.6, 0.0, -D * 0.5 + 1.6)]
		"bakery", "tailor", "grocer", "shop", "apothecary", "chandler":
			return [Vector3(0.6, 0.0, cz - 0.1), Vector3(-1.6, 0.0, cz - 0.1)]
		"scholar":
			return [Vector3(1.6, PI * 0.15, -D * 0.5 + 2.0), Vector3(-1.6, 0.0, 0.5)]
		"tent":
			return [Vector3(0.8, PI * 0.1, -0.6), Vector3(-1.2, 0.0, 0.2)]
	return [Vector3(1.0, PI * 0.1, -0.4), Vector3(-1.4, -PI * 0.1, 0.2)]


## Furniture: solid, but never a ledge to climb.
func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color) -> void:
	var cs: CollisionShape3D = k.block(center, size, 0.0, mat, col)
	cs.set_meta("no_climb", true)


func _home(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# A bed in a back corner, its blanket in a color of the house's own.
	var bx := -W * 0.5 + 1.0
	var bz := -D * 0.5 + 1.4
	_solid(k, Vector3(bx, 0.3, bz), Vector3(1.3, 0.6, 2.1), "wood", Color(0.6, 0.42, 0.28))
	var bed = k._tmp(false)
	bed.box(Vector3(bx, 0.64, bz + 0.2), Vector3(1.32, 0.1, 1.6), Color.html(["8c1d17", "2a4a8a", "4a6a2a", "8a5a2a"][id.hash() % 4]))
	bed.box(Vector3(bx, 0.66, bz - 0.75), Vector3(1.0, 0.16, 0.45), Color.html("fafaf4"))
	k.merge(bed, "char")
	# The table and two stools.
	_solid(k, Vector3(0.2, 0.4, -0.2), Vector3(1.6, 0.8, 1.0), "wood", Color(0.66, 0.48, 0.32))
	for sx in [-1.0, 1.0]:
		_solid(k, Vector3(0.2 + sx * 1.2, 0.22, -0.2), Vector3(0.45, 0.44, 0.45), "wood", Color(0.58, 0.42, 0.28))
	var top = k._tmp(false)
	top.prism(Vector3(0.3, 0.82, -0.2), 0.16, Vector3(0.3, 0.92, -0.2), 0.2, 8, Color.html("b88a4a"))
	for i in 3:
		top.icosa(Vector3(0.2 + i * 0.1, 0.96, -0.2), Vector3(0.05, 0.04, 0.05), 0.0, Color.html(["e84a3a", "f0d040", "c88a40"][i]))
	k.merge(top, "char")
	# A cupboard and a shelf of pots.
	_solid(k, Vector3(W * 0.5 - 0.4, 1.0, -D * 0.5 + 1.2), Vector3(0.6, 2.0, 1.6), "wood", Color(0.62, 0.46, 0.3))
	var shelf = k._tmp(false)
	for i in 4:
		shelf.prism(Vector3(-W * 0.5 + 2.8 + i * 0.45, 1.7, -D * 0.5 + 0.3), 0.1, Vector3(-W * 0.5 + 2.8 + i * 0.45, 1.95, -D * 0.5 + 0.3), 0.08, 6, Color.html(["c8603a", "4a8ac8", "e8c050", "8ab84a"][(i + r.randi()) % 4]))
	k.merge(shelf, "char")
	_solid(k, Vector3(-W * 0.5 + 3.5, 1.6, -D * 0.5 + 0.25), Vector3(2.2, 0.08, 0.4), "wood", Color(0.6, 0.44, 0.3))


func _hearth(k) -> void:
	var hx := W * 0.5 - 0.35
	var hz := 0.8
	_solid(k, Vector3(hx, 1.2, hz), Vector3(0.7, 2.4, 1.8), "stone", Color(0.6, 0.56, 0.52))
	var glow = k._tmp(false)
	glow.box(Vector3(hx - 0.36, 0.45, hz), Vector3(0.04, 0.6, 0.9), Color.html("ff9a3a"))
	k.merge(glow, "glow")
	var fl := OmniLight3D.new()
	fl.name = "HearthLight"
	fl.position = Vector3(hx - 0.8, 0.8, hz)
	fl.light_color = Color.html("ff9a4a")
	fl.light_energy = 0.9
	fl.omni_range = 4.5
	fl.set_script(load("res://scripts/systems/torch_flicker.gd"))
	k._misc.add_child(fl)


func _counter(k, col: Color) -> void:
	var cz := -D * 0.5 + 2.0
	_solid(k, Vector3(0, 0.5, cz), Vector3(W - 3.0, 1.0, 0.7), "wood", col)
	var top = k._tmp()
	top.box(Vector3(0, 1.03, cz), Vector3(W - 2.8, 0.06, 0.8), col.darkened(0.25))
	k.merge(top, "wood")
	_solid(k, Vector3(0, 1.3, -D * 0.5 + 0.3), Vector3(W - 1.5, 2.6, 0.5), "wood", col.darkened(0.1))


func _goods(k, what: String) -> void:
	var r: RandomNumberGenerator = k.rng
	var cz := -D * 0.5 + 2.0
	var g = k._tmp(false)
	var glow = k._tmp(false)
	var x := -W * 0.5 + 2.0
	while x < W * 0.5 - 2.0:
		var p := Vector3(x, 1.06, cz)
		match what:
			"bread":
				g.icosa(p + Vector3(0, 0.07, 0), Vector3(0.16, 0.07, 0.09), 0.05, Color.html(["c88a40", "b8783a", "d89a50"][r.randi() % 3]))
			"veg":
				for j in 3:
					g.icosa(p + Vector3(-0.1 + j * 0.1, 0.06, r.randf_range(-0.1, 0.1)), Vector3(0.06, 0.06, 0.06), 0.1, Color.html(["e84a3a", "f0d040", "8ad84a", "f08a2a", "a84ad8"][r.randi() % 5]))
			"glass":
				glow.prism(p, 0.06, p + Vector3(0, 0.22, 0), 0.04, 6, Color.html(["8ad8ff", "c8f0ff", "f0b8ff", "b8ffc8"][r.randi() % 4]))
			"bottles":
				glow.prism(p, 0.06, p + Vector3(0, 0.18, 0), 0.06, 6, Color.html(["e83a3a", "3ae86a", "3a8ae8", "e8c83a"][r.randi() % 4]))
				g.prism(p + Vector3(0, 0.18, 0), 0.03, p + Vector3(0, 0.24, 0), 0.03, 6, Color.html("8a6a4a"))
			"candles":
				g.prism(p, 0.04, p + Vector3(0, r.randf_range(0.15, 0.3), 0), 0.04, 6, Color.html("f4f0e4"))
				glow.icosa(p + Vector3(0, 0.34, 0), Vector3(0.02, 0.04, 0.02), 0.0, Color.html("ffcc5a"))
		x += r.randf_range(0.45, 0.7)
	# The shelves behind, stocked the same.
	for shelf in [0.8, 1.5, 2.2]:
		var sx := -W * 0.5 + 1.2
		while sx < W * 0.5 - 1.2:
			var sp := Vector3(sx, shelf, -D * 0.5 + 0.62)
			match what:
				"bread", "veg":
					g.prism(sp, 0.15, sp + Vector3(0, 0.16, 0), 0.18, 8, Color.html("b88a4a"))
				"glass", "bottles":
					glow.prism(sp, 0.05, sp + Vector3(0, 0.2, 0), 0.04, 6, Color.html(["8ad8ff", "e83a3a", "3ae86a", "e8c83a", "f0b8ff"][r.randi() % 5]))
				"candles":
					g.prism(sp, 0.035, sp + Vector3(0, 0.22, 0), 0.035, 6, Color.html("f4f0e4"))
			sx += r.randf_range(0.4, 0.6)
	k.merge(g, "char")
	k.merge(glow, "glow")


func _oven(k) -> void:
	var ox := -W * 0.5 + 1.0
	var oz := 0.4
	_solid(k, Vector3(ox, 1.0, oz), Vector3(1.4, 2.0, 1.6), "stone", Color(0.72, 0.42, 0.32))
	var g = k._tmp(false)
	g.box(Vector3(ox + 0.71, 0.7, oz), Vector3(0.02, 0.5, 0.7), Color.html("ff8a2a"))
	k.merge(g, "glow")


func _sacks(k) -> void:
	for p in [Vector2(W * 0.5 - 0.7, 2.2), Vector2(W * 0.5 - 0.7, 2.9), Vector2(-W * 0.5 + 0.7, 2.6)]:
		var sack = k._tmp(false)
		sack.icosa(Vector3(p.x, 0.35, p.y), Vector3(0.3, 0.36, 0.28), 0.1, Color.html("e8dcc0"))
		k.merge(sack, "char")


func _crates(k) -> void:
	k.crate(-W * 0.5 + 0.8, D * 0.5 - 1.6, 0.2, 0.9, FLOOR_Y)
	k.crate(-W * 0.5 + 0.8, D * 0.5 - 2.6, 0.5, 0.8, FLOOR_Y)
	k.barrel(W * 0.5 - 0.7, D * 0.5 - 1.6)


func _bolts(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var g = k._tmp(false)
	for shelf in [0.8, 1.5, 2.2]:
		var x := -W * 0.5 + 1.3
		while x < W * 0.5 - 1.3:
			var c := Color.html(["c83a6a", "3a6ac8", "e8c050", "3aa86a", "8a3ac8", "e88a3a"][r.randi() % 6])
			g.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(x, shelf + 0.1, -D * 0.5 + 0.62)))
			g.prism(Vector3(0, -0.18, 0), 0.1, Vector3(0, 0.18, 0), 0.1, 8, c)
			g.pop()
			x += 0.42
	k.merge(g, "char")


func _mannequin(k, at: Vector2) -> void:
	var g = k._tmp(false)
	g.prism(Vector3(at.x, 0.0, at.y), 0.2, Vector3(at.x, 0.05, at.y), 0.2, 8, Color.html("4a3a2a"))
	g.prism(Vector3(at.x, 0.05, at.y), 0.03, Vector3(at.x, 0.9, at.y), 0.03, 6, Color.html("4a3a2a"))
	g.prism(Vector3(at.x, 0.9, at.y), 0.18, Vector3(at.x, 1.5, at.y), 0.22, 8, Color.html("a83a5a"))
	g.icosa(Vector3(at.x, 1.62, at.y), Vector3(0.1, 0.12, 0.1), 0.0, Color.html("e8d8c0"))
	k.merge(g, "char")


func _bookshelves(k) -> void:
	var r: RandomNumberGenerator = k.rng
	_solid(k, Vector3(0, 1.4, -D * 0.5 + 0.3), Vector3(W - 1.0, 2.8, 0.5), "wood", Color(0.5, 0.36, 0.24))
	var g = k._tmp(false)
	for shelf in [0.5, 1.15, 1.8, 2.45]:
		var x := -W * 0.5 + 0.8
		while x < W * 0.5 - 0.8:
			var w := r.randf_range(0.06, 0.12)
			g.box(Vector3(x, shelf + 0.2, -D * 0.5 + 0.6), Vector3(w, r.randf_range(0.3, 0.42), 0.26), Color.html(["8a2a2a", "2a4a8a", "2a6a3a", "8a6a2a", "4a2a6a", "6a3a1a"][r.randi() % 6]))
			x += w + 0.01
	# Maps on the side wall.
	for i in 3:
		g.box(Vector3(-W * 0.5 + 0.06, 1.8, -1.5 + i * 1.4), Vector3(0.02, 0.8, 1.1), Color.html("e8d8b0"))
		g.box(Vector3(-W * 0.5 + 0.08, 1.8, -1.5 + i * 1.4), Vector3(0.01, 0.5, 0.7), Color.html(["6a9a5a", "c8a060", "5a7aa8"][i]))
	k.merge(g, "char")


func _desk(k) -> void:
	_solid(k, Vector3(1.6, 0.4, -D * 0.5 + 3.0), Vector3(1.8, 0.8, 0.9), "wood", Color(0.56, 0.4, 0.26))
	var g = k._tmp(false)
	g.box(Vector3(1.4, 0.82, -D * 0.5 + 3.0), Vector3(0.6, 0.02, 0.45), Color.html("f0e8d0"))
	g.prism(Vector3(2.1, 0.8, -D * 0.5 + 3.0), 0.05, Vector3(2.1, 0.9, -D * 0.5 + 3.0), 0.04, 6, Color.html("2a2a3a"))
	g.prism(Vector3(-2.6, 0.0, 1.8), 0.15, Vector3(-2.6, 0.9, 1.8), 0.04, 6, Color.html("6a4a2a"))
	g.icosa(Vector3(-2.6, 1.15, 1.8), Vector3(0.28, 0.28, 0.28), 0.0, Color.html("4a7ac8"))
	k.merge(g, "char")


func _bench(k) -> void:
	_solid(k, Vector3(0, 0.45, -D * 0.5 + 1.4), Vector3(W - 3.0, 0.9, 0.9), "wood", Color(0.6, 0.44, 0.28))
	var r: RandomNumberGenerator = k.rng
	var g = k._tmp(false)
	for i in 8:
		var p := Vector3(-W * 0.5 + 2.0 + i * (W - 4.0) / 8.0, 0.95, -D * 0.5 + 1.4 + r.randf_range(-0.2, 0.2))
		match i % 3:
			0:
				g.box(p + Vector3(0, 0.06, 0), Vector3(0.18, 0.12, 0.18), Color.html(["e84a3a", "3a8ae8", "f0d040"][r.randi() % 3]))
			1:
				g.icosa(p + Vector3(0, 0.08, 0), Vector3(0.08, 0.08, 0.08), 0.0, Color.html(["8ad84a", "e88a3a", "c84ad8"][r.randi() % 3]))
			2:
				g.prism(p, 0.02, p + Vector3(0.2, 0.02, 0), 0.02, 4, Color.html("8a8a92"))
	k.merge(g, "char")
	for i in 3:
		_solid(k, Vector3(W * 0.5 - 0.5, 0.15 + i * 0.3, -1.0), Vector3(0.6, 0.12, 2.0), "wood", Color(0.66, 0.5, 0.32))


func _cauldron(k) -> void:
	var g = k._tmp(false)
	g.prism(Vector3(-W * 0.5 + 1.4, 0.0, 1.2), 0.45, Vector3(-W * 0.5 + 1.4, 0.7, 1.2), 0.5, 10, Color.html("2a2a30"))
	k.merge(g, "char")
	var gl = k._tmp(false)
	gl.prism(Vector3(-W * 0.5 + 1.4, 0.66, 1.2), 0.44, Vector3(-W * 0.5 + 1.4, 0.68, 1.2), 0.44, 10, Color.html("5ae86a"))
	k.merge(gl, "glow")
	k.col_box(Vector3(-W * 0.5 + 1.4, 0.35, 1.2), Vector3(1.0, 0.7, 1.0))


## The Golden Bun: the bar along the west wall, barrels behind it, tables,
## a hearth, and the band's little stage at the back.
func _inn(k) -> void:
	_solid(k, Vector3(-W * 0.5 + 2.4, 0.55, 0.0), Vector3(0.8, 1.1, D - 4.0), "wood", Color(0.62, 0.42, 0.26))
	for i in 4:
		k.barrel(-W * 0.5 + 0.7, -D * 0.5 + 2.0 + i * 1.6)
	for p in [Vector2(1.0, 0.4), Vector2(3.8, 2.2), Vector2(1.2, 3.2)]:
		_solid(k, Vector3(p.x, 0.4, p.y), Vector3(1.4, 0.8, 1.4), "wood", Color(0.62, 0.46, 0.3))
		for a in 4:
			var o := Vector2(cos(a * PI * 0.5), sin(a * PI * 0.5)) * 1.1
			_solid(k, Vector3(p.x + o.x, 0.22, p.y + o.y), Vector3(0.4, 0.44, 0.4), "wood", Color(0.56, 0.4, 0.26))
		var mugs = k._tmp(false)
		mugs.prism(Vector3(p.x + 0.2, 0.8, p.y), 0.07, Vector3(p.x + 0.2, 0.98, p.y), 0.07, 6, Color.html("c8a060"))
		k.merge(mugs, "char")
	# The stage.
	_solid(k, Vector3(0.0, 0.15, -D * 0.5 + 1.5), Vector3(5.0, 0.3, 2.4), "wood", Color(0.5, 0.34, 0.22))
	var bunting = k._tmp(false)
	for i in 9:
		var x := -2.4 + i * 0.6
		bunting.face([Vector3(x - 0.2, 3.4, -D * 0.5 + 0.2), Vector3(x + 0.2, 3.4, -D * 0.5 + 0.2), Vector3(x, 3.0, -D * 0.5 + 0.2)], Color.html(["e84a3a", "f0d040", "3a8ae8"][i % 3]), Vector3(x, 3.2, -D * 0.5 + 1.0))
	k.merge(bunting, "char")
	k.pixel_text("THE GOLDEN BUN", Vector3(0, 3.7, -D * 0.5 + 0.08), 0.0, 0.06, Color.html("f0d060"))
	var hx := W * 0.5 - 0.35
	_solid(k, Vector3(hx, 1.2, 1.5), Vector3(0.7, 2.4, 2.0), "stone", Color(0.6, 0.56, 0.52))
	var glow = k._tmp(false)
	glow.box(Vector3(hx - 0.36, 0.45, 1.5), Vector3(0.04, 0.6, 1.0), Color.html("ff9a3a"))
	k.merge(glow, "glow")


func _tent_walls(k, col: Color) -> void:
	var cloth := col
	var t = k._tmp(false)
	var hw := W * 0.5
	var hd := D * 0.5
	# Sloping canvas walls up to a ridge pole along X, seen from inside (each
	# face's normal points away from a point outside the tent).
	for sz in [-1.0, 1.0]:
		t.face([Vector3(-hw, 0.0, sz * hd), Vector3(hw, 0.0, sz * hd), Vector3(hw, WALL_H, 0.0), Vector3(-hw, WALL_H, 0.0)], cloth.darkened(0.1 if sz > 0 else 0.0), Vector3(0, WALL_H * 2.0, sz * hd * 3.0))
	for sx in [-1.0, 1.0]:
		t.face([Vector3(sx * hw, 0.0, -hd), Vector3(sx * hw, 0.0, hd), Vector3(sx * hw, WALL_H, 0.0)], cloth.darkened(0.15), Vector3(sx * hw * 3.0, WALL_H * 0.3, 0))
	t.box(Vector3(0, WALL_H - 0.05, 0), Vector3(W + 0.2, 0.08, 0.08), Color.html("5a4630"))
	k.merge(t, "char")
	k.col_box(Vector3(0, 1.5, -hd - 0.2), Vector3(W, 3.0, 0.4))
	k.col_box(Vector3(-hw - 0.2, 1.5, 0), Vector3(0.4, 3.0, D))
	k.col_box(Vector3(hw + 0.2, 1.5, 0), Vector3(0.4, 3.0, D))
	k.col_box(Vector3(-hw * 0.55, 1.5, hd + 0.2), Vector3(hw * 0.9, 3.0, 0.4))
	k.col_box(Vector3(hw * 0.55, 1.5, hd + 0.2), Vector3(hw * 0.9, 3.0, 0.4))


func _tent(k) -> void:
	var g = k._tmp(false)
	g.box(Vector3(-1.8, 0.1, -1.4), Vector3(1.0, 0.2, 2.0), Color.html("6a5a4a"))
	g.box(Vector3(-1.8, 0.22, -2.0), Vector3(0.8, 0.12, 0.5), Color.html("c8b8a0"))
	k.merge(g, "char")
	k.fire(1.0, 0.6, 0.5, FLOOR_Y, true)
	k.crate(2.2, -1.8, 0.3, 0.8, FLOOR_Y)
