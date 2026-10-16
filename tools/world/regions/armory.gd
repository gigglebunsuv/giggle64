extends "res://tools/world/region.gd"
## Pink's Armory, inside the timber hall on the west side of Old Castle Town's
## square. Stone walls and flagstones, the forge glowing in the north-west
## corner with Pink at her anvil before it, every sword she makes on the north
## wall and her shields on the east wall. On the bench along the west wall sit
## Aladriel and Idrith, close together, with Aladriel's giant sword and
## Idrith's scimitar leaning on the bench ends and a plate of Idrith's honey
## buns on the little table. The door in the south wall leads back out.

const W := 12.0
const D := 10.0
const WALL_H := 4.2
const FLOOR_Y := 0.0
const BENCH_X := -W * 0.5 + 0.45
const BENCH_Z := 0.4


func setup() -> void:
	id = "armory"
	interior = true
	seed_value = 141
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
	mood = {
		"sky_top": Color.html("2a1a14"), "sky_mid": Color.html("2a1a14"), "sky_horizon": Color.html("2a1a14"),
		"cloud": Color.html("2a1a14"), "cloud_amount": 0.0,
		"fog": Color.html("1a100c"), "fog_begin": 20.0, "fog_end": 60.0,
		"ambient": Color.html("8a7466"), "sun": Color.html("ffd8a8"), "sun_rot": Vector3(-70, 40, 0),
		"sun_energy": 0.75, "fill": Color.html("6a7090"), "fill_energy": 0.3,
		"horizon": Color.html("2a1a14"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "carpet" if absf(x - 0.5) < 1.8 and absf(z - 0.6) < 1.3 else "stone"


## Big warm-gray flagstones in staggered rows.
func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var row := int(floor((z + 20.0) / 0.9))
	var off := 0.45 if row % 2 == 0 else 0.0
	var seam := fmod(z + 20.0, 0.9) < 0.05 or fmod(x + 20.0 + off, 1.2) < 0.05
	var c := Color.html(["8a8078", "948a80", "7e766e"][row % 3])
	if seam:
		return c.darkened(0.4)
	return c.darkened(r.randf_range(0.0, 0.1))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "stone", Color(0.92, 0.86, 0.8), Color(0.62, 0.52, 0.44))
	# The door out to the square, and where the hero stands on coming in.
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.4, 2.4, "castle_town", "from_armory")
	k.entrance("from_castle_town", 0.0, D * 0.5 - 1.4, 0.0)
	# Windows on the front wall, lit from the square outside.
	for wx in [-3.2, 3.2]:
		var frame = k._tmp(false)
		frame.box(Vector3(wx, 1.9, D * 0.5 - 0.02), Vector3(1.3, 1.1, 0.06), Color.html("5a3a24"))
		k.merge(frame, "char")
		var pane = k._tmp(false)
		pane.box(Vector3(wx, 1.9, D * 0.5 - 0.05), Vector3(1.1, 0.9, 0.04), Color.html("d8e0f0"))
		k.merge(pane, "glow")
	_forge(k)
	_weapon_wall(k)
	_shield_wall(k)
	_bench(k)
	# Rug in the middle, barrels of spare blades, crates, and lamps.
	var rug = k._tmp(false)
	rug.box(Vector3(0.5, 0.015, 0.6), Vector3(3.6, 0.03, 2.6), Color.html("8a2a2a"))
	rug.box(Vector3(0.5, 0.02, 0.6), Vector3(3.2, 0.03, 2.2), Color.html("d8a838"))
	rug.box(Vector3(0.5, 0.025, 0.6), Vector3(2.8, 0.03, 1.8), Color.html("8a2a2a"))
	k.merge(rug, "char")
	for p in [Vector2(W * 0.5 - 0.7, 1.4), Vector2(W * 0.5 - 0.7, 2.4)]:
		k.barrel(p.x, p.y)
		var blades = k._tmp(false)
		for i in 4:
			var a := TAU * i / 4.0 + 0.4
			blades.push(Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 0.18), Vector3(p.x + cos(a) * 0.12, 0.95, p.y + sin(a) * 0.12)))
			blades.prism(Vector3.ZERO, 0.025, Vector3(0, 0.55, 0), 0.02, 4, Color.html("b8bec8"))
			blades.box(Vector3(0, 0.55, 0), Vector3(0.16, 0.03, 0.04), Color.html("8a6a3a"))
			blades.prism(Vector3(0, 0.56, 0), 0.018, Vector3(0, 0.68, 0), 0.018, 5, Color.html("5a3a22"))
			blades.pop()
		k.merge(blades, "char")
	k.crate(W * 0.5 - 0.8, D * 0.5 - 0.9, 0.2, 0.9)
	k.crate(W * 0.5 - 1.8, D * 0.5 - 0.8, -0.3, 0.7)
	for p in [Vector3(-2.0, 0, 1.6), Vector3(2.8, 0, -1.0)]:
		var lamp := OmniLight3D.new()
		lamp.name = "Lamp%d" % k._misc.get_child_count()
		lamp.position = p + Vector3(0, 3.3, 0)
		lamp.light_color = Color.html("ffd090")
		lamp.light_energy = 0.8
		lamp.omni_range = 7.0
		k._misc.add_child(lamp)
		var lk = k._tmp(false)
		lk.prism(p + Vector3(0, 3.5, 0), 0.01, p + Vector3(0, WALL_H, 0), 0.01, 4, Color.html("2c2c30"))
		lk.box(p + Vector3(0, 3.3, 0), Vector3(0.3, 0.36, 0.3), Color.html("2c2c30"))
		k.merge(lk, "char")
		var lg = k._tmp(false)
		lg.box(p + Vector3(0, 3.3, 0), Vector3(0.24, 0.3, 0.24) * 1.05, Color.html("ffd890"))
		k.merge(lg, "glow")
	# Pink at her anvil before the forge, facing the room; the anvil sits
	# where her hammer comes down.
	var pink := Vector2(-2.6, -2.7)
	k.display_mesh("res://assets/models/anvil_mesh.tres", Transform3D(Basis.IDENTITY, Vector3(pink.x, FLOOR_Y, pink.y + 0.62)))
	_solid(k, Vector3(pink.x, 0.35, pink.y + 0.62), Vector3(0.62, 0.7, 0.3), "stone", Color(0.4, 0.4, 0.42), false)
	k.npc("Pink", "res://assets/models/pink.tscn", "res://scripts/npc/pink_lines.gd", pink.x, pink.y, PI, INF, {"script": "res://scripts/npc/armorer.gd"})
	# Aladriel and Idrith on the bench, side by side, facing into the room.
	var yaw := -PI * 0.5
	k.npc("Aladriel", "res://assets/models/aladriel.tscn", "res://scripts/npc/aladriel_lines.gd", BENCH_X + 0.05, BENCH_Z - 0.24, yaw, INF,
		{"turn_body": false, "partner": "Idrith", "seated": true})
	k.npc("Idrith", "res://assets/models/idrith.tscn", "res://scripts/npc/idrith_lines.gd", BENCH_X + 0.05, BENCH_Z + 0.24, yaw, INF,
		{"turn_body": false, "partner": "Aladriel", "seated": true})


## The forge in the north-west corner: a stone hearth of glowing coals under a
## hood and chimney, a water trough, and a warm flickering light.
func _forge(k) -> void:
	var fx := -W * 0.5 + 1.6
	var fz := -D * 0.5 + 0.9
	_solid(k, Vector3(fx, 0.5, fz), Vector3(2.4, 1.0, 1.4), "stone", Color(0.75, 0.7, 0.66))
	var coals = k._tmp(false)
	coals.box(Vector3(fx, 1.02, fz + 0.05), Vector3(1.8, 0.06, 1.0), Color.html("ff7a20"))
	for i in 7:
		coals.icosa(Vector3(fx - 0.7 + i * 0.23, 1.06, fz + 0.05 + (0.2 if i % 2 else -0.2)), Vector3(0.1, 0.06, 0.1), 0.2, Color.html(["ffb040", "ff6a10", "ffd060"][i % 3]))
	k.merge(coals, "glow")
	var hood = k._tmp()
	hood.slab(Vector3(fx, 2.2, fz - 0.05), Vector2(2.6, 1.5), Vector3(fx, 3.0, fz - 0.15), Vector2(0.9, 0.8), Color(0.7, 0.66, 0.62))
	hood.box(Vector3(fx, 3.6, fz - 0.15), Vector3(0.9, 1.2, 0.8), Color(0.7, 0.66, 0.62))
	k.merge(hood, "stone")
	var light := OmniLight3D.new()
	light.name = "ForgeLight"
	light.position = Vector3(fx, 1.5, fz + 0.9)
	light.light_color = Color.html("ff9a50")
	light.light_energy = 1.6
	light.omni_range = 7.5
	k._misc.add_child(light)
	# Quench trough beside it.
	_solid(k, Vector3(fx + 1.9, 0.3, fz - 0.1), Vector3(1.0, 0.6, 0.6), "wood", Color(0.75, 0.65, 0.55))
	var water = k._tmp(false)
	water.box(Vector3(fx + 1.9, 0.6, fz - 0.1), Vector3(0.85, 0.02, 0.45), Color.html("4a6a8a"))
	k.merge(water, "char")


## Every sword Pink makes, standing point up on a board on the north wall,
## each on its peg, with a pixel-lettered plaque above.
func _weapon_wall(k) -> void:
	var z := -D * 0.5 + 0.04
	var board = k._tmp(false)
	board.box(Vector3(2.6, 2.1, z + 0.03), Vector3(4.6, 2.2, 0.06), Color.html("6a4428"))
	board.box(Vector3(2.6, 2.1, z + 0.05), Vector3(4.4, 2.0, 0.04), Color.html("8a5a34"))
	k.merge(board, "char")
	var flat := Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
	var ids := ["squire", "red", "magical", "bun"]
	for i in ids.size():
		var x := 1.1 + i * 1.0
		k.display_mesh("res://assets/models/sword_%s_mesh.tres" % ids[i], Transform3D(flat, Vector3(x, 1.25, z + 0.12)))
	k.pixel_text("SWORDS", Vector3(2.6, 3.45, z + 0.06), 0.0, 0.06, Color.html("e8c050"))


## Her shields on the east wall, one above the other row, under a plaque.
func _shield_wall(k) -> void:
	var x := W * 0.5 - 0.06
	var face := Basis(Vector3.BACK, PI * 0.5)
	var ids := ["wooden", "iron"]
	for i in ids.size():
		var z := -2.6 + i * 1.25
		k.display_mesh("res://assets/models/shield_%s_flat_mesh.tres" % ids[i], Transform3D(face, Vector3(x - 0.02, 2.1, z)))
	k.pixel_text("SHIELDS", Vector3(x - 0.02, 3.3, -1.95), -PI * 0.5, 0.06, Color.html("e8c050"))


## The bench along the west wall, the couple's weapons leaning on its ends,
## and the little table with Idrith's honey buns.
func _bench(k) -> void:
	_solid(k, Vector3(BENCH_X, 0.21, BENCH_Z), Vector3(0.5, 0.42, 1.9), "wood", Color(0.85, 0.72, 0.58))
	var back = k._tmp()
	back.box(Vector3(-W * 0.5 + 0.12, 0.85, BENCH_Z), Vector3(0.08, 0.6, 1.9), Color(0.8, 0.68, 0.55))
	k.merge(back, "wood")
	# A cushion on the seat.
	var cushion = k._tmp(false)
	cushion.box(Vector3(BENCH_X, 0.44, BENCH_Z), Vector3(0.44, 0.05, 1.3), Color.html("6a4a8a"))
	k.merge(cushion, "char")
	# Aladriel's giant sword (at her end) and Idrith's scimitar, leaning on the wall.
	var lean := Basis(Vector3.BACK, deg_to_rad(10))
	k.display_mesh("res://assets/models/giant_sword_mesh.tres", Transform3D(lean * Basis(Vector3.UP, PI * 0.5), Vector3(-W * 0.5 + 0.38, 0.0, BENCH_Z - 1.2)))
	k.display_mesh("res://assets/models/scimitar_mesh.tres", Transform3D(lean * Basis(Vector3.UP, PI * 0.5), Vector3(-W * 0.5 + 0.3, 0.0, BENCH_Z + 1.15)))
	# The table and its plate of honey buns.
	var tz := BENCH_Z + 1.75
	var tx := BENCH_X + 0.1
	var table = k._tmp(false)
	table.prism(Vector3(tx, 0.0, tz), 0.06, Vector3(tx, 0.55, tz), 0.05, 6, Color.html("6a4428"))
	table.prism(Vector3(tx, 0.55, tz), 0.32, Vector3(tx, 0.6, tz), 0.32, 10, Color.html("8a5a34"))
	table.prism(Vector3(tx, 0.6, tz), 0.22, Vector3(tx, 0.62, tz), 0.24, 10, Color.html("f0ece0"))
	for i in 5:
		var a := TAU * i / 5.0
		var c := Vector3(tx + cos(a) * 0.12, 0.66, tz + sin(a) * 0.12) if i < 4 else Vector3(tx, 0.7, tz)
		table.icosa(c, Vector3(0.07, 0.045, 0.07), 0.1, Color.html("c88a3a"))
		table.icosa(c + Vector3(0, 0.03, 0), Vector3(0.05, 0.02, 0.05), 0.0, Color.html("f4e0a0"))
	k.merge(table, "char")
	k.col_cyl(Vector3(tx, 0.0, tz), 0.3, 0.62)


## Furniture: solid, but never a ledge to climb.
func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color, visible := true) -> void:
	var cs: CollisionShape3D
	if visible:
		cs = k.block(center, size, 0.0, mat, col)
	else:
		cs = k.col_box(center, size)
	cs.set_meta("no_climb", true)
