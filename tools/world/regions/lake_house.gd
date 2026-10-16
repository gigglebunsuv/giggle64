extends "res://tools/world/region.gd"
## Inside Mira's house at Mirror Lake. Like OoT's houses it is its own little
## scene, roomier inside than the outside suggests: plank floor, beamed
## ceiling, a hearth on the back wall, her bed, a table, shelves of jars and
## fishing gear. Mira stands by the table. The door in the south wall leads back
## out to the lake.

const W := 10.0
const D := 8.0
const WALL_H := 3.6
const FLOOR_Y := 0.0
const PLANK := ["8a6440", "946c46", "7e5a3a", "9a7450"]


func setup() -> void:
	id = "lake_house"
	interior = true
	seed_value = 131
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
		"sky_top": Color.html("2a1e18"), "sky_mid": Color.html("2a1e18"), "sky_horizon": Color.html("2a1e18"),
		"cloud": Color.html("2a1e18"), "cloud_amount": 0.0,
		"fog": Color.html("1a120e"), "fog_begin": 20.0, "fog_end": 60.0,
		"ambient": Color.html("8a7462"), "sun": Color.html("ffe0b0"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.8, "fill": Color.html("6a7a9a"), "fill_energy": 0.35,
		"horizon": Color.html("2a1e18"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


## Floorboards, with the rug before the hearth.
func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "carpet" if absf(x) < 1.4 and absf(z + 1.6) < 0.9 else "wood"


## Floorboards running east-west, a plank every half meter.
func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var row := int(floor((z + 20.0) / 0.5))
	var c := Color.html(PLANK[row % PLANK.size()])
	var seam := fmod(z + 20.0, 0.5) < 0.04 or fmod(x + 20.0 + row * 1.3, 2.4) < 0.04
	if seam:
		return c.darkened(0.35)
	return c.darkened(r.randf_range(0.0, 0.08))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "wood", Color(0.92, 0.84, 0.74), Color(0.7, 0.6, 0.5))
	# The door out to the lake, and where the hero stands on coming in.
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.2, 2.2, "lake", "from_lake_house")
	k.entrance("from_lake", 0.0, D * 0.5 - 1.4, 0.0)
	# Windows: bright panes of lake light on the side walls.
	var glass := Color.html("bfe0ff")
	for wz in [-1.8, 1.6]:
		_window(k, Vector3(-W * 0.5 + 0.02, 1.7, wz), Vector3(0.04, 0.9, 1.0), glass)
		_window(k, Vector3(W * 0.5 - 0.02, 1.7, wz), Vector3(0.04, 0.9, 1.0), glass)
	_window(k, Vector3(-2.6, 1.7, D * 0.5 - 0.02), Vector3(1.0, 0.9, 0.04), glass)
	_window(k, Vector3(2.6, 1.7, D * 0.5 - 0.02), Vector3(1.0, 0.9, 0.04), glass)
	# Hearth on the north wall with a glowing fire, and a warm light.
	_solid(k, Vector3(0, 0.7, -D * 0.5 + 0.45), Vector3(2.2, 1.4, 0.9), "stone", Color(0.85, 0.82, 0.78))
	_solid(k, Vector3(0, 2.5, -D * 0.5 + 0.35), Vector3(1.4, 2.2, 0.7), "stone", Color(0.8, 0.77, 0.74))
	var fire = k._tmp(false)
	fire.box(Vector3(0, 0.55, -D * 0.5 + 0.92), Vector3(1.1, 0.6, 0.06), Color.html("1a0e08"))
	fire.prism(Vector3(-0.2, 0.3, -D * 0.5 + 0.9), 0.16, Vector3(-0.2, 0.75, -D * 0.5 + 0.9), 0.0, 5, Color.html("ff8a20"))
	fire.prism(Vector3(0.15, 0.3, -D * 0.5 + 0.9), 0.14, Vector3(0.15, 0.68, -D * 0.5 + 0.9), 0.0, 5, Color.html("ffc040"))
	k.merge(fire, "glow")
	var light := OmniLight3D.new()
	light.name = "HearthLight"
	light.position = Vector3(0, 1.0, -D * 0.5 + 1.4)
	light.light_color = Color.html("ffb060")
	light.light_energy = 1.4
	light.omni_range = 7.0
	light.shadow_enabled = false
	k._misc.add_child(light)
	# Bed in the north-west corner: frame, mattress, teal blanket, pillow.
	var bx := -W * 0.5 + 1.1
	var bz := -D * 0.5 + 1.6
	_solid(k, Vector3(bx, 0.25, bz), Vector3(1.6, 0.5, 2.4), "wood", Color(0.85, 0.75, 0.65))
	var bed = k._tmp(false)
	bed.box(Vector3(bx, 0.58, bz + 0.1), Vector3(1.45, 0.18, 2.1), Color.html("f0ece0"))
	bed.box(Vector3(bx, 0.68, bz + 0.35), Vector3(1.5, 0.08, 1.6), Color.html("2e7d7a"))
	bed.box(Vector3(bx, 0.72, bz - 0.75), Vector3(1.0, 0.16, 0.45), Color.html("fafaf4"))
	bed.box(Vector3(bx, 0.95, bz - 1.2), Vector3(1.6, 0.9, 0.12), Color.html("7a5236"))
	k.merge(bed, "char")
	# Table and two stools in the middle of the room, a vase of lake flowers.
	var tx := 1.8
	var tz := -0.6
	_solid(k, Vector3(tx, 0.4, tz), Vector3(1.6, 0.8, 1.0), "wood", Color(0.9, 0.8, 0.7))
	var vase = k._tmp(false)
	vase.prism(Vector3(tx - 0.3, 0.8, tz), 0.09, Vector3(tx - 0.3, 1.0, tz), 0.06, 6, Color.html("4a6ac0"))
	for i in 5:
		var a := TAU * i / 5.0
		vase.icosa(Vector3(tx - 0.3 + cos(a) * 0.07, 1.08, tz + sin(a) * 0.07), Vector3(0.05, 0.05, 0.05), 0.2, Color.html(["f04060", "f0f0f0", "f0d040"][i % 3]))
	vase.box(Vector3(tx + 0.35, 0.83, tz + 0.1), Vector3(0.3, 0.04, 0.3), Color.html("e0d8c8"))
	k.merge(vase, "char")
	for sx in [-1.0, 1.0]:
		_solid(k, Vector3(tx + sx * 1.15, 0.25, tz), Vector3(0.45, 0.5, 0.45), "wood", Color(0.8, 0.7, 0.6))
	# Rug before the hearth.
	var rug = k._tmp(false)
	rug.box(Vector3(0, 0.015, -1.6), Vector3(2.8, 0.03, 1.8), Color.html("a83a32"))
	rug.box(Vector3(0, 0.02, -1.6), Vector3(2.4, 0.03, 1.4), Color.html("c8a050"))
	rug.box(Vector3(0, 0.025, -1.6), Vector3(2.0, 0.03, 1.0), Color.html("a83a32"))
	k.merge(rug, "char")
	# Shelves of jars along the west wall.
	var sx0 := -W * 0.5 + 0.35
	_solid(k, Vector3(sx0, 1.0, 1.2), Vector3(0.5, 2.0, 2.0), "wood", Color(0.75, 0.62, 0.5))
	var jars = k._tmp(false)
	var r: RandomNumberGenerator = k.rng
	for shelf in [0.75, 1.35, 1.95]:
		for i in 5:
			var jz := 0.4 + i * 0.38
			var col := Color.html(["d8b060", "80b0d0", "c86048", "90c070", "e0e0d0"][r.randi_range(0, 4)])
			jars.prism(Vector3(sx0 + 0.22, shelf + 0.05, jz), 0.08, Vector3(sx0 + 0.22, shelf + 0.28, jz), 0.07, 6, col)
	k.merge(jars, "char")
	# Fishing gear by the east wall: a rod rack, a net and a barrel of fish.
	var ex := W * 0.5 - 0.3
	var gear = k._tmp(false)
	for i in 3:
		var gz := 1.0 + i * 0.35
		gear.prism(Vector3(ex - 0.1, 0.1, gz), 0.025, Vector3(ex - 0.2, 2.6, gz + 0.1), 0.015, 4, Color.html("8a6440"))
	# A fishing net hung on pegs: a loose lattice of cord.
	for i in 7:
		gear.box(Vector3(ex, 2.0, -2.25 + i * 0.25), Vector3(0.03, 1.1, 0.03), Color.html("c8b890"))
	for j in 5:
		gear.box(Vector3(ex, 1.5 + j * 0.25, -1.5), Vector3(0.03, 0.03, 1.55), Color.html("b8a880"))
	k.merge(gear, "char")
	k.barrel(ex - 0.5, -2.8)
	k.crate(ex - 0.6, 2.9, 0.2, 0.8)
	# Mira, standing by her table.
	k.npc("Mira", "res://assets/models/mira.tscn", "res://scripts/npc/mira_lines.gd", 0.9, 0.4, PI * 0.85)
	_record_board(k)


## Mira's record board on the north wall, east of the hearth (FishBoard):
## a wooden outline of every kind of fish the hero has landed.
func _record_board(k) -> void:
	k._dyn("res://scripts/items/fish_board.gd", "FishBoard", Vector3(2.8, FLOOR_Y, -D * 0.5 + 0.06), PI, {}, Node3D.new())


## Furniture: solid, but never a ledge to climb.
func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color) -> void:
	var cs: CollisionShape3D = k.block(center, size, 0.0, mat, col)
	cs.set_meta("no_climb", true)


func _window(k, center: Vector3, size: Vector3, col: Color) -> void:
	var thin_x := size.x < 0.1
	var frame = k._tmp(false)
	frame.box(center, size + Vector3(0.0 if thin_x else 0.16, 0.16, 0.16 if thin_x else 0.0), Color.html("6a4a30"))
	k.merge(frame, "char")
	var pane = k._tmp(false)
	pane.box(center, size + Vector3(0.03 if thin_x else 0.0, 0.0, 0.0 if thin_x else 0.03), col)
	k.merge(pane, "glow")
