extends "res://tools/world/region.gd"
## The Haven Library, inside the stone hall on the south-east of Haven Village.
## Tall bookcases line the walls, two reading tables stand on a long blue rug
## with books lying open on them, and a lectern holds the big Book of Haven.
## A gallery runs along the north wall above the cases, reached by a ladder;
## up there, between the top shelves, someone has left a Piece of Heart.
## Ottilie keeps the place from her desk by the door.

const W := 14.0
const D := 12.0
const WALL_H := 6.0
const FLOOR_Y := 0.0
## The gallery along the north wall.
const GALLERY_Y := 2.7
const GALLERY_D := 2.2
const SPINES := ["8a2a2a", "2a4a8a", "3a6a3a", "8a6a2a", "5a2a6a", "a0582a", "2a6a6a", "6a1a1a", "e0c060", "4a3a2a"]


func setup() -> void:
	id = "library"
	interior = true
	seed_value = 151
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
		"sky_top": Color.html("1e1a24"), "sky_mid": Color.html("1e1a24"), "sky_horizon": Color.html("1e1a24"),
		"cloud": Color.html("1e1a24"), "cloud_amount": 0.0,
		"fog": Color.html("14101a"), "fog_begin": 22.0, "fog_end": 70.0,
		"ambient": Color.html("7a7480"), "sun": Color.html("fff0d8"), "sun_rot": Vector3(-65, 30, 0),
		"sun_energy": 0.7, "fill": Color.html("7080a8"), "fill_energy": 0.35,
		"horizon": Color.html("1e1a24"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "carpet" if absf(x) < 2.2 and z > -3.4 and z < 4.6 else "wood"


## Parquet: short planks laid in alternating squares.
func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var cx := int(floor((x + 20.0) / 1.2))
	var cz := int(floor((z + 20.0) / 1.2))
	var along_x := (cx + cz) % 2 == 0
	var t := fmod((z if along_x else x) + 20.0, 0.3)
	var c := Color.html(["7a5634", "86603a", "70502e"][(cx * 3 + cz) % 3])
	if t < 0.03 or fmod(x + 20.0, 1.2) < 0.03 or fmod(z + 20.0, 1.2) < 0.03:
		return c.darkened(0.35)
	return c.darkened(r.randf_range(0.0, 0.08))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "stone", Color(0.86, 0.84, 0.9), Color(0.5, 0.46, 0.56))
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.4, 2.4, "village", "from_library")
	k.entrance("from_village", 0.0, D * 0.5 - 1.4, 0.0)
	# Tall windows on the side walls.
	for wz in [-1.0, 2.6]:
		for sx in [-1.0, 1.0]:
			var frame = k._tmp(false)
			frame.box(Vector3(sx * (W * 0.5 - 0.02), 2.6, wz), Vector3(0.06, 2.4, 1.1), Color.html("4a3a2a"))
			k.merge(frame, "char")
			var pane = k._tmp(false)
			pane.box(Vector3(sx * (W * 0.5 - 0.05), 2.6, wz), Vector3(0.04, 2.2, 0.9), Color.html("d8e4f8"))
			k.merge(pane, "glow")
	# Bookcases: the north wall under and above the gallery, and the side walls.
	for i in 6:
		_bookcase(k, Vector3(-W * 0.5 + 1.2 + i * 2.33, FLOOR_Y, -D * 0.5 + 0.35), 0.0, 2.6)
		_bookcase(k, Vector3(-W * 0.5 + 1.2 + i * 2.33, GALLERY_Y, -D * 0.5 + 0.35), 0.0, 2.6)
	for z in [-3.2, 0.9, 4.0]:
		_bookcase(k, Vector3(-W * 0.5 + 0.35, FLOOR_Y, z), PI * 0.5, 3.0)
		_bookcase(k, Vector3(W * 0.5 - 0.35, FLOOR_Y, z), -PI * 0.5, 3.0)
	_gallery(k)
	_reading_room(k)
	_desk(k)
	# Hanging lamps.
	for p in [Vector3(-3.0, 0, 0.5), Vector3(3.0, 0, 0.5), Vector3(0, 0, 3.8)]:
		var lamp := OmniLight3D.new()
		lamp.name = "Lamp%d" % k._misc.get_child_count()
		lamp.position = p + Vector3(0, 3.8, 0)
		lamp.light_color = Color.html("ffd8a0")
		lamp.light_energy = 0.9
		lamp.omni_range = 8.0
		k._misc.add_child(lamp)
		var lk = k._tmp(false)
		lk.prism(p + Vector3(0, 4.0, 0), 0.01, p + Vector3(0, WALL_H, 0), 0.01, 4, Color.html("2c2c30"))
		lk.prism(p + Vector3(0, 3.7, 0), 0.25, p + Vector3(0, 4.0, 0), 0.05, 8, Color.html("2c2c30"))
		k.merge(lk, "char")
		var lg = k._tmp(false)
		lg.icosa(p + Vector3(0, 3.72, 0), Vector3(0.14, 0.12, 0.14), 0.0, Color.html("ffe0a0"))
		k.merge(lg, "glow")


## A bookcase `width` wide, 2.5 m tall, its open face toward local +Z after `yaw`.
func _bookcase(k, base: Vector3, yaw: float, width: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var r: RandomNumberGenerator = k.rng
	var hh := 2.5
	var depth := 0.5
	var frame = k._tmp()
	frame.push(Transform3D(basis, base))
	frame.box(Vector3(0, hh * 0.5, -depth * 0.5 + 0.03), Vector3(width, hh, 0.06), Color(0.55, 0.42, 0.32))
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(sx * width * 0.5, hh * 0.5, 0), Vector3(0.08, hh, depth), Color(0.7, 0.55, 0.42))
	for i in 5:
		frame.box(Vector3(0, 0.04 + i * 0.6, 0), Vector3(width, 0.06, depth), Color(0.72, 0.56, 0.42))
	frame.pop()
	k.merge(frame, "wood")
	var books = k._tmp(false)
	books.push(Transform3D(basis, base))
	for shelf in 4:
		var x := -width * 0.5 + 0.08
		var y := 0.07 + shelf * 0.6
		while x < width * 0.5 - 0.14:
			var bw := r.randf_range(0.05, 0.1)
			var bh := r.randf_range(0.36, 0.5)
			if r.randf() < 0.06:
				x += bw   # a gap
				continue
			books.box(Vector3(x + bw * 0.5, y + bh * 0.5, 0.02), Vector3(bw * 0.92, bh, 0.36), Color.html(SPINES[r.randi_range(0, SPINES.size() - 1)]))
			x += bw
	books.pop()
	k.merge(books, "char")
	var cs: CollisionShape3D = k.col_box_basis(base + basis * Vector3(0, hh * 0.5, 0), Vector3(width, hh, depth), basis)
	cs.set_meta("no_climb", true)


## The gallery: a balcony along the north wall on posts, with a railing, and
## a ladder up from the floor at its west end. The Piece of Heart waits at
## the east end.
func _gallery(k) -> void:
	var z0 := -D * 0.5 + 0.6
	var cz := -D * 0.5 + GALLERY_D * 0.5
	var deck = k._tmp()
	deck.box(Vector3(0, GALLERY_Y - 0.15, cz), Vector3(W, 0.3, GALLERY_D), Color(0.78, 0.62, 0.46))
	k.merge(deck, "wood")
	var floor_cs: CollisionShape3D = k.col_box(Vector3(0, GALLERY_Y - 0.15, cz), Vector3(W, 0.3, GALLERY_D))
	floor_cs.set_meta("surface", "wood")
	var rail = k._tmp()
	var front := -D * 0.5 + GALLERY_D
	rail.box(Vector3(0.6, GALLERY_Y + 0.9, front - 0.05), Vector3(W - 1.2, 0.08, 0.08), Color(0.65, 0.5, 0.38))
	var x := -W * 0.5 + 1.4
	while x < W * 0.5:
		rail.box(Vector3(x, GALLERY_Y + 0.45, front - 0.05), Vector3(0.06, 0.9, 0.06), Color(0.7, 0.55, 0.42))
		x += 0.5
	for px in [-W * 0.5 + 1.2, -2.5, 2.5, W * 0.5 - 0.6]:
		rail.box(Vector3(px, (GALLERY_Y - 0.3) * 0.5, front - 0.12), Vector3(0.22, GALLERY_Y - 0.3, 0.22), Color(0.6, 0.46, 0.34))
		k.col_box(Vector3(px, (GALLERY_Y - 0.3) * 0.5, front - 0.12), Vector3(0.22, GALLERY_Y - 0.3, 0.22)).set_meta("no_climb", true)
	k.merge(rail, "wood")
	var rcs: CollisionShape3D = k.col_box(Vector3(0.6, GALLERY_Y + 0.5, front - 0.05), Vector3(W - 1.2, 1.0, 0.1))
	rcs.set_meta("no_climb", true)
	# The ladder up at the west end, through the gap in the railing.
	k.ladder(-W * 0.5 + 0.7, front + 0.12, Vector2(0, 1), FLOOR_Y, GALLERY_Y, 0.8)
	k.heart_piece(W * 0.5 - 1.0, z0 + 0.5, "library:heart_piece", GALLERY_Y)


## Two reading tables on the rug, each with a book lying open, and the lectern
## with the Book of Haven between them.
func _reading_room(k) -> void:
	var rug = k._tmp(false)
	rug.box(Vector3(0, 0.015, 0.6), Vector3(4.4, 0.03, 8.0), Color.html("2a3a7a"))
	rug.box(Vector3(0, 0.02, 0.6), Vector3(4.0, 0.03, 7.6), Color.html("c8a050"))
	rug.box(Vector3(0, 0.025, 0.6), Vector3(3.6, 0.03, 7.2), Color.html("2a3a7a"))
	k.merge(rug, "char")
	var tables := [Vector3(-3.4, 0, -1.4), Vector3(3.4, 0, -1.4), Vector3(-3.4, 0, 1.6), Vector3(3.4, 0, 1.6)]
	for t: Vector3 in tables:
		_solid(k, t + Vector3(0, 0.38, 0), Vector3(2.0, 0.76, 1.1), "wood", Color(0.75, 0.58, 0.42))
		for sz in [-1.0, 1.0]:
			_solid(k, t + Vector3(0, 0.23, sz * 0.9), Vector3(1.4, 0.46, 0.4), "wood", Color(0.68, 0.52, 0.38))
	var books := _books()
	for i in tables.size():
		var t: Vector3 = tables[i]
		var b: Array = books[i]
		k.book(t + Vector3(0.3, 0.77, 0), 0.2 * (1 if i % 2 else -1), b[0], b[1], Color.html(SPINES[i * 2]))
		# A candle and a stack of closed books beside each.
		var deco = k._tmp(false)
		deco.prism(t + Vector3(-0.6, 0.76, -0.2), 0.04, t + Vector3(-0.6, 0.94, -0.2), 0.04, 6, Color.html("f0e8d0"))
		for j in 3:
			deco.box(t + Vector3(-0.55, 0.8 + j * 0.06, 0.25), Vector3(0.3, 0.06, 0.22), Color.html(SPINES[(i + j * 3) % SPINES.size()]))
		k.merge(deco, "char")
		var flame = k._tmp(false)
		flame.prism(t + Vector3(-0.6, 0.94, -0.2), 0.025, t + Vector3(-0.6, 1.02, -0.2), 0.0, 5, Color.html("ffc040"))
		k.merge(flame, "glow")
	# The lectern and the Book of Haven.
	var lp := Vector3(0, 0, 1.0)
	_solid(k, lp + Vector3(0, 0.55, 0), Vector3(0.6, 1.1, 0.5), "wood", Color(0.62, 0.46, 0.34))
	var top = k._tmp()
	top.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20)), lp + Vector3(0, 1.15, 0)))
	top.box(Vector3.ZERO, Vector3(0.8, 0.06, 0.55), Color(0.7, 0.52, 0.38))
	top.pop()
	k.merge(top, "wood")
	var lore: Array = _book_of_haven()
	k.book(lp + Vector3(0, 1.2, -0.02), 0.0, lore[0], lore[1], Color.html("2a2a6a"))


## Ottilie's desk by the door, with ledgers, a quill and a little bell.
func _desk(k) -> void:
	var d := Vector3(3.8, 0, 4.4)
	_solid(k, d + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 0.9), "wood", Color(0.62, 0.44, 0.3))
	var top = k._tmp(false)
	top.box(d + Vector3(-0.5, 0.94, 0.0), Vector3(0.6, 0.08, 0.45), Color.html("3a5a3a"))
	top.box(d + Vector3(0.6, 0.93, 0.1), Vector3(0.4, 0.06, 0.3), Color.html("8a2a2a"))
	top.prism(d + Vector3(0.2, 0.9, -0.2), 0.04, d + Vector3(0.2, 0.96, -0.2), 0.04, 6, Color.html("2a2a30"))
	top.prism(d + Vector3(0.2, 0.96, -0.2), 0.004, d + Vector3(0.25, 1.2, -0.25), 0.012, 4, Color.html("f0f0f0"))
	top.prism(d + Vector3(-1.0, 0.9, -0.2), 0.06, d + Vector3(-1.0, 1.0, -0.2), 0.0, 8, Color.html("e8c050"))
	k.merge(top, "char")
	k.npc("Ottilie", "res://assets/models/ottilie.tscn", "res://scripts/npc/ottilie_lines.gd", d.x - 1.75, d.z + 0.2, 0.0, FLOOR_Y)


## The books on the reading tables: [title, pages].
func _books() -> Array:
	return [
		["A Knight's Handbook", [
			"Chapter One: *Locking On*. Hold Z to face your foe. With a foe in your sights, the stick steps, circles and backs away.",
			"While targeting, press A to leap and strike from above: the *jump slash*! It hits twice as hard as a swing.",
			"Press A with the stick to the side to hop out of the way, or back to flip backward. Even in the middle of a hop, B turns it into a jump slash!",
		]],
		["Shields of Haven", [
			"Hold your shield without targeting and you will crouch behind it, feet planted. Target a foe and you can raise it and still move.",
			"The *Wooden Shield* stops arrows and claws, but heavy blows go straight through it. An *Iron Shield* stops even those.",
			"They say a polished *Silvered Shield* throws every shot back at whoever loosed it.",
		]],
		["Swimming for Beginners", [
			"Deep water is no danger to a knight who can swim! Wade in and you will float. Push the stick to swim.",
			"Press A to dive under. You can't stay down for long, so come up for air!",
			"A knight cannot swing a sword while swimming. Climb out where the bank is low.",
		]],
		["Horses of the Southern Fields", [
			"The farm in the *Southern Fields* keeps fine horses. A horse that trusts you will come running for a *Sugar Cube*.",
			"Walk up to a horse and press A to mount. Push the stick to ride, and press A to spur her on. A spur needs a moment to come back.",
			"Horses jump low fences on their own. Ride out on the open fields: they will not follow you into towns or forests.",
		]],
	]


func _book_of_haven() -> Array:
	return ["The Book of Haven", [
		"Haven is a green land in the world of *Bunsriel*. At its heart lie the wide *Bunsriel Fields*, and every road in Haven leads there.",
		"North stands *Old Castle Town* and the castle. North-west, the *Forest*, and past its stone gate the *Hidden Forest*, where few have walked.",
		"West lie the *Marshlands*, east the *Desert of Ladhellin*, and in the north-east the *Cliffs* climb toward the snows of *Frostpeak*.",
		"South, past the farms of the *Southern Fields* and our own *Haven Village*, the *South Road* winds to *Mirror Lake*.",
		"Old towers and shrines stand all over Haven. Their doors have been sealed for longer than anyone remembers.",
		"Hearts, they say, can be found in pieces, tucked into high and hidden places. Four pieces make a whole heart.",
	]]


## Furniture: solid, but never a ledge to climb.
func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color) -> void:
	var cs: CollisionShape3D = k.block(center, size, 0.0, mat, col)
	cs.set_meta("no_climb", true)
