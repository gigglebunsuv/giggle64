extends "res://tools/world/region.gd"
## Marigold's Goods, the general store on Haven Village's shop lane (the
## orange house with the red roof). A long counter crosses the room with the
## wares on it, Marigold behind it, shelves of jars, sacks and baskets on the
## walls. The door in the south wall leads back out.

const W := 9.0
const D := 7.0
const WALL_H := 3.6
const FLOOR_Y := 0.0
const COUNTER_Z := -0.9
## [kind, price, mesh, x along the counter]
const WARES := [
	["arrows_10", 20, "arrow_bundle_mesh", -3.0],
	["big_quiver", 90, "quiver_mesh", -2.25],
	["bomb_bag", 80, "bomb_bag_mesh", -1.5],
	["bombs_10", 25, "bomb_mesh", -0.75],
	["puff_nuts", 30, "puff_nut_mesh", 0.0],
	["heart", 10, "heart_mesh", 0.75],
	["honey_bun", 25, "honey_bun_mesh", 1.5],
	["bottle", 120, "bottle_empty_mesh", 2.25],
	["red_potion", 40, "bottle_red_potion_mesh", 3.0],
]


func setup() -> void:
	id = "shop"
	interior = true
	seed_value = 161
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
		"sky_top": Color.html("2a1e14"), "sky_mid": Color.html("2a1e14"), "sky_horizon": Color.html("2a1e14"),
		"cloud": Color.html("2a1e14"), "cloud_amount": 0.0,
		"fog": Color.html("1a120c"), "fog_begin": 20.0, "fog_end": 60.0,
		"ambient": Color.html("8a7866"), "sun": Color.html("ffe8c0"), "sun_rot": Vector3(-70, 20, 0),
		"sun_energy": 0.8, "fill": Color.html("7080a0"), "fill_energy": 0.3,
		"horizon": Color.html("2a1e14"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func surface_at(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "wood"


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var row := int(floor((x + 20.0) / 0.45))
	var c := Color.html(["9a7048", "a47a50", "8e663e"][row % 3])
	if fmod(x + 20.0, 0.45) < 0.035 or fmod(z + 20.0 + row * 0.9, 2.2) < 0.035:
		return c.darkened(0.35)
	return c.darkened(r.randf_range(0.0, 0.08))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "plaster", Color(0.98, 0.9, 0.78), Color(0.7, 0.58, 0.46))
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.2, 2.2, "village", "from_shop")
	k.entrance("from_village", 0.0, D * 0.5 - 1.3, 0.0)
	for wx in [-2.8, 2.8]:
		var pane = k._tmp(false)
		pane.box(Vector3(wx, 1.8, D * 0.5 - 0.05), Vector3(1.1, 0.9, 0.04), Color.html("f0e8d0"))
		k.merge(pane, "glow")
	# The counter: a long wooden top on a paneled front.
	_solid(k, Vector3(0, 0.5, COUNTER_Z), Vector3(7.0, 1.0, 0.7), "wood", Color(0.78, 0.6, 0.42))
	var top = k._tmp()
	top.box(Vector3(0, 1.03, COUNTER_Z), Vector3(7.2, 0.06, 0.8), Color(0.62, 0.44, 0.3))
	k.merge(top, "wood")
	# The goods on little cloths, each one for sale.
	for w: Array in WARES:
		var cloth = k._tmp(false)
		cloth.box(Vector3(w[3], 1.065, COUNTER_Z + 0.05), Vector3(0.62, 0.01, 0.5), Color.html("e8e0c8"))
		k.merge(cloth, "char")
		k._dyn("res://scripts/items/shop_item.gd", "Ware", Vector3(w[3], 1.08, COUNTER_Z + 0.05), 0.0,
			{"kind": w[0], "price": w[1], "mesh": w[2]}, Node3D.new())
		k.pixel_text("%d" % w[1], Vector3(w[3], 0.75, COUNTER_Z + 0.36), 0.0, 0.035, Color.html("f0d060"))
	# Shelves behind the counter, full of jars, sacks and baskets.
	var r: RandomNumberGenerator = k.rng
	_solid(k, Vector3(0, 1.3, -D * 0.5 + 0.3), Vector3(7.5, 2.6, 0.5), "wood", Color(0.72, 0.56, 0.4))
	var stock = k._tmp(false)
	for shelf in [0.75, 1.45, 2.15]:
		var x := -3.5
		while x < 3.5:
			var kind := r.randi_range(0, 2)
			var p := Vector3(x + 0.2, shelf, -D * 0.5 + 0.62)
			match kind:
				0:
					stock.prism(p, 0.1, p + Vector3(0, 0.26, 0), 0.08, 6, Color.html(["c8603a", "4a8ac8", "e8c050", "8ab84a"][r.randi_range(0, 3)]))
					stock.prism(p + Vector3(0, 0.26, 0), 0.05, p + Vector3(0, 0.3, 0), 0.05, 6, Color.html("8a6a4a"))
				1:
					stock.icosa(p + Vector3(0, 0.14, 0), Vector3(0.16, 0.15, 0.14), 0.1, Color.html("d8c8a0"))
				2:
					stock.prism(p, 0.15, p + Vector3(0, 0.16, 0), 0.18, 8, Color.html("b88a4a"))
					for i in 3:
						stock.icosa(p + Vector3(-0.06 + i * 0.06, 0.2, 0), Vector3(0.05, 0.05, 0.05), 0.0, Color.html(["e83a3a", "f0d040", "8ad84a"][i]))
			x += r.randf_range(0.42, 0.6)
	k.merge(stock, "char")
	# Sacks of grain and a barrel by the walls.
	for p in [Vector2(-W * 0.5 + 0.6, 1.8), Vector2(-W * 0.5 + 0.6, 2.6), Vector2(W * 0.5 - 0.6, 2.2)]:
		var sack = k._tmp(false)
		sack.icosa(Vector3(p.x, 0.35, p.y), Vector3(0.3, 0.36, 0.28), 0.1, Color.html("d8c49a"))
		k.merge(sack, "char")
	k.barrel(W * 0.5 - 0.6, 1.2)
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0, 3.0, 0.4)
	lamp.light_color = Color.html("ffd8a0")
	lamp.light_energy = 0.9
	lamp.omni_range = 8.0
	k._misc.add_child(lamp)
	k.npc("Marigold", "res://assets/models/marigold.tscn", "res://scripts/npc/marigold_lines.gd", 0.0, COUNTER_Z - 0.75, 0.0, FLOOR_Y)


## Furniture: solid, but never a ledge to climb.
func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color) -> void:
	var cs: CollisionShape3D = k.block(center, size, 0.0, mat, col)
	cs.set_meta("no_climb", true)
