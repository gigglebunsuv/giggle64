extends "res://tools/world/region.gd"
## Inside Sir Gigglebuns IV's cottage in Haven Village, where a new game
## begins (Story.wake_up: he wakes in his bed and hops out). Like Mira's
## house it is roomier inside than out: floorboards, a beamed ceiling, his bed
## with its red blanket in the north-west corner, a hearth on the east wall,
## the table with a basket of buns, a writing desk with his journal, a bench
## of spare gear and the portraits of the three Gigglebunses before him. The
## door in the south wall leads out onto his mound in the village.

const W := 11.0
const D := 9.0
const WALL_H := 3.8
const FLOOR_Y := 0.0
const PLANK := ["8a6440", "946c46", "7e5a3a", "9a7450"]
## The bed (center of its frame) and where he stands once out of it.
const BED := Vector2(-W * 0.5 + 1.15, -D * 0.5 + 1.75)
const BED_Y := 0.62
const RED := "8c1d17"


func setup() -> void:
	id = "hero_house"
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
		"sky_top": Color.html("2a1e18"), "sky_mid": Color.html("2a1e18"), "sky_horizon": Color.html("2a1e18"),
		"cloud": Color.html("2a1e18"), "cloud_amount": 0.0,
		"fog": Color.html("1a120e"), "fog_begin": 20.0, "fog_end": 60.0,
		"ambient": Color.html("8a7866"), "sun": Color.html("fff0c8"), "sun_rot": Vector3(-55, 60, 0),
		"sun_energy": 0.85, "fill": Color.html("6a7a9a"), "fill_energy": 0.35,
		"horizon": Color.html("2a1e18"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


## Floorboards, with the rug in the middle of the room.
func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "carpet" if absf(x - 0.6) < 1.6 and absf(z - 0.4) < 1.1 else "wood"


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var row := int(floor((x + 20.0) / 0.5))
	var c := Color.html(PLANK[row % PLANK.size()])
	var seam := fmod(x + 20.0, 0.5) < 0.04 or fmod(z + 20.0 + row * 1.1, 2.2) < 0.04
	if seam:
		return c.darkened(0.35)
	return c.darkened(r.randf_range(0.0, 0.08))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "timber", Color(0.96, 0.9, 0.82), Color(0.72, 0.62, 0.52))
	# The door out to the village, and where the hero stands on coming in.
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.2, 2.2, "village", "home")
	k.entrance("from_village", 0.0, D * 0.5 - 1.4, 0.0)
	# Beside the bed, facing into the room: where he stands after waking.
	k.entrance("bed", BED.x + 1.5, BED.y + 0.9, k.yaw_of(Vector2(0.6, 1.0).normalized()))
	# Beta 1.5.0: the first morning after the true ending.
	k.story_trigger("peace_morning", Rect2(BED.x - 0.5, BED.y - 1.5, 4.0, 4.5), FLOOR_Y - 0.5, "postgame:woke", "game_complete", 3.0)
	# Morning light through the windows.
	var glass := Color.html("fff4d0")
	_window(k, Vector3(-W * 0.5 + 0.02, 1.8, 0.6), Vector3(0.04, 1.0, 1.1), glass)
	_window(k, Vector3(-W * 0.5 + 0.02, 1.8, 2.8), Vector3(0.04, 1.0, 1.1), glass)
	_window(k, Vector3(-2.8, 1.8, D * 0.5 - 0.02), Vector3(1.1, 1.0, 0.04), glass)
	_window(k, Vector3(2.8, 1.8, D * 0.5 - 0.02), Vector3(1.1, 1.0, 0.04), glass)
	_window(k, Vector3(1.2, 2.0, -D * 0.5 + 0.02), Vector3(1.0, 0.9, 0.04), glass)
	_bed(k)
	_hearth(k)
	_table(k)
	_desk(k)
	_gear(k)
	_portraits(k)
	# A rug of Haven red and gold in the middle of the room.
	var rug = k._tmp(false)
	rug.box(Vector3(0.6, 0.015, 0.4), Vector3(3.4, 0.03, 2.4), Color.html(RED))
	rug.box(Vector3(0.6, 0.02, 0.4), Vector3(3.0, 0.03, 2.0), Color.html("d8b050"))
	rug.box(Vector3(0.6, 0.025, 0.4), Vector3(2.6, 0.03, 1.6), Color.html(RED))
	rug.box(Vector3(0.6, 0.03, 0.4), Vector3(0.5, 0.03, 0.5), Color.html("d8b050"))
	k.merge(rug, "char")
	# Barrels and a crate in the south-east corner, a pot by the door.
	k.barrel(W * 0.5 - 0.6, D * 0.5 - 0.7)
	k.crate(W * 0.5 - 1.5, D * 0.5 - 0.6, 0.15, 0.8)
	# The wake-up scene plays when a new game starts here (once).
	var trig := Area3D.new()
	trig.name = "WakeTrigger"
	trig.set_script(load("res://scripts/systems/story_trigger.gd"))
	trig.set("scene", "wake_up")
	trig.set("flag", "woke_up")
	trig.position = Vector3(BED.x + 1.2, 1.0, BED.y + 0.8)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.0, 1.6)
	cs.shape = box
	trig.add_child(cs)
	k._misc.add_child(trig)
	# The first morning after the ending (Chapter II): Himeko bursts in.
	var trig2 := Area3D.new()
	trig2.name = "Chapter2Trigger"
	trig2.set_script(load("res://scripts/systems/story_trigger.gd"))
	trig2.set("scene", "chapter_two")
	trig2.set("flag", "ch2:woke")
	trig2.set("need_flag", "game_beaten")
	trig2.position = Vector3(BED.x + 1.2, 1.0, BED.y + 0.8)
	var cs2 := CollisionShape3D.new()
	cs2.name = "Shape"
	var box2 := BoxShape3D.new()
	box2.size = Vector3(1.6, 2.0, 1.6)
	cs2.shape = box2
	trig2.add_child(cs2)
	k._misc.add_child(trig2)
	var mark := Marker3D.new()
	mark.name = "cs_bed"
	mark.position = Vector3(BED.x, BED_Y, BED.y)
	k._misc.add_child(mark)
	k.collectible("rupee_green", BED.x + 1.0, BED.y - 0.9, FLOOR_Y + 0.4)


## His bed in the north-west corner: a sturdy frame with a carved bun on the
## headboard, white sheets, the red blanket and a fat pillow.
func _bed(k) -> void:
	var bx: float = BED.x
	var bz: float = BED.y
	_solid(k, Vector3(bx, 0.25, bz + 0.1), Vector3(1.7, 0.5, 2.6), "wood", Color(0.85, 0.72, 0.6))
	var bed = k._tmp(false)
	bed.box(Vector3(bx, 0.55, bz + 0.15), Vector3(1.55, 0.14, 2.3), Color.html("f4efe4"))
	bed.box(Vector3(bx, 0.64, bz + 0.45), Vector3(1.62, 0.08, 1.7), Color.html(RED))
	bed.box(Vector3(bx, 0.69, bz + 0.45), Vector3(1.3, 0.02, 1.4), Color.html("a3261d"))
	bed.box(Vector3(bx, 0.67, bz - 0.7), Vector3(1.1, 0.18, 0.5), Color.html("fafaf4"))
	# The headboard, with the round bun carved in it.
	bed.box(Vector3(bx, 1.0, bz - 1.2), Vector3(1.75, 1.0, 0.14), Color.html("7a5236"))
	bed.prism(Vector3(bx, 1.32, bz - 1.13), 0.24, Vector3(bx, 1.32, bz - 1.09), 0.24, 10, Color.html("c89a5a"))
	bed.prism(Vector3(bx, 1.36, bz - 1.09), 0.16, Vector3(bx, 1.36, bz - 1.07), 0.12, 10, Color.html("e0b878"))
	bed.box(Vector3(bx, 0.45, bz + 1.4), Vector3(1.75, 0.6, 0.12), Color.html("7a5236"))
	k.merge(bed, "char")
	# A little table by the bed with a candle.
	_solid(k, Vector3(bx + 1.35, 0.3, bz - 0.9), Vector3(0.6, 0.6, 0.6), "wood", Color(0.8, 0.68, 0.55))
	var candle = k._tmp(false)
	candle.prism(Vector3(bx + 1.35, 0.6, bz - 0.9), 0.05, Vector3(bx + 1.35, 0.78, bz - 0.9), 0.05, 6, Color.html("f0e8d0"))
	k.merge(candle, "char")
	var flame = k._tmp(false)
	flame.prism(Vector3(bx + 1.35, 0.78, bz - 0.9), 0.025, Vector3(bx + 1.35, 0.86, bz - 0.9), 0.0, 5, Color.html("ffc040"))
	k.merge(flame, "glow")


## The hearth on the east wall, a fire burning in it, a pot on the hob.
func _hearth(k) -> void:
	var hx := W * 0.5 - 0.45
	var hz := -1.2
	_solid(k, Vector3(hx, 0.7, hz), Vector3(0.9, 1.4, 2.2), "stone", Color(0.85, 0.82, 0.78))
	_solid(k, Vector3(hx + 0.1, 2.6, hz), Vector3(0.7, 2.4, 1.4), "stone", Color(0.8, 0.77, 0.74))
	var fire = k._tmp(false)
	fire.box(Vector3(hx - 0.47, 0.55, hz), Vector3(0.06, 0.6, 1.1), Color.html("1a0e08"))
	fire.prism(Vector3(hx - 0.45, 0.3, hz - 0.2), 0.16, Vector3(hx - 0.45, 0.75, hz - 0.2), 0.0, 5, Color.html("ff8a20"))
	fire.prism(Vector3(hx - 0.45, 0.3, hz + 0.15), 0.14, Vector3(hx - 0.45, 0.68, hz + 0.15), 0.0, 5, Color.html("ffc040"))
	k.merge(fire, "glow")
	var pot = k._tmp(false)
	pot.prism(Vector3(hx - 0.2, 1.4, hz + 0.65), 0.2, Vector3(hx - 0.2, 1.65, hz + 0.65), 0.17, 8, Color.html("2a2a30"))
	k.merge(pot, "char")
	var light := OmniLight3D.new()
	light.name = "HearthLight"
	light.position = Vector3(hx - 1.2, 1.0, hz)
	light.light_color = Color.html("ffb060")
	light.light_energy = 1.3
	light.omni_range = 7.5
	light.shadow_enabled = false
	k._misc.add_child(light)


## The table with two stools, a basket of buns and a mug of milk.
func _table(k) -> void:
	var tx := 1.9
	var tz := -2.3
	_solid(k, Vector3(tx, 0.4, tz), Vector3(1.8, 0.8, 1.1), "wood", Color(0.9, 0.8, 0.7))
	for sx in [-1.0, 1.0]:
		_solid(k, Vector3(tx + sx * 1.25, 0.25, tz), Vector3(0.45, 0.5, 0.45), "wood", Color(0.8, 0.7, 0.6))
	var food = k._tmp(false)
	food.prism(Vector3(tx - 0.3, 0.8, tz), 0.3, Vector3(tx - 0.3, 0.95, tz), 0.34, 10, Color.html("b8864a"))
	for i in 5:
		var a := TAU * i / 5.0
		food.icosa(Vector3(tx - 0.3 + cos(a) * 0.14, 1.0, tz + sin(a) * 0.14), Vector3(0.09, 0.06, 0.09), 0.1, Color.html("e0a860"))
	food.icosa(Vector3(tx - 0.3, 1.04, tz), Vector3(0.09, 0.06, 0.09), 0.1, Color.html("eab070"))
	food.prism(Vector3(tx + 0.45, 0.8, tz + 0.15), 0.07, Vector3(tx + 0.45, 0.97, tz + 0.15), 0.07, 8, Color.html("8a6440"))
	food.prism(Vector3(tx + 0.45, 0.96, tz + 0.15), 0.055, Vector3(tx + 0.45, 0.975, tz + 0.15), 0.055, 8, Color.html("f6f2e8"))
	k.merge(food, "char")
	# After the peace (Chapter IV's end): the summons from the castle, sealed
	# in blue wax. Read it when ready, and Chapter V begins (Story.knighting).
	var letter = k._tmp(false)
	letter.box(Vector3(tx + 0.35, 0.81, tz - 0.3), Vector3(0.34, 0.012, 0.24), Color.html("f2ead8"))
	letter.prism(Vector3(tx + 0.35, 0.815, tz - 0.3), 0.045, Vector3(tx + 0.35, 0.83, tz - 0.3), 0.045, 8, Color.html("2a4aa8"))
	k.flag_props("ch4:peace", letter, "char")
	# On the letter itself, readable from any side of the table.
	var summons: Node3D = k.examine(Vector3(tx + 0.35, 0.81, tz - 0.3), PI, [], "res://scripts/npc/chapter5_lines.gd", "summons", 1.6)
	summons.set("front_only", false)
	summons.set("show_flag", "ch4:peace")


## The writing desk under the west windows, his journal open on it.
func _desk(k) -> void:
	var dx := -W * 0.5 + 0.5
	var dz := 1.7
	_solid(k, Vector3(dx, 0.4, dz), Vector3(0.8, 0.8, 1.6), "wood", Color(0.82, 0.7, 0.58))
	_solid(k, Vector3(dx + 0.85, 0.25, dz), Vector3(0.45, 0.5, 0.45), "wood", Color(0.8, 0.7, 0.6))
	var ink = k._tmp(false)
	ink.prism(Vector3(dx, 0.8, dz - 0.55), 0.05, Vector3(dx, 0.88, dz - 0.55), 0.04, 6, Color.html("1a1a2a"))
	ink.box(Vector3(dx - 0.02, 0.94, dz - 0.52), Vector3(0.02, 0.2, 0.02), Color.html("f0f0f0"))
	k.merge(ink, "char")
	k.book(Vector3(dx + 0.05, 0.8, dz + 0.1), k.yaw_of(Vector2(1, 0)), "Knight's Journal", [
		"*Knight's Journal*\nSir Gigglebuns IV, knight of Haven.",
		"Day 1. Swore my oath at the castle today. The King says a knight's first duty is to *listen*: to the people, to the land, to the old stories.",
		"Day 12. Mira at Mirror Lake says the big fish in the lake is a legend. I say it's just shy.",
		"Day 30. Strange smoke in the north again. Probably nothing. Probably.",
		"Day 31. Someone in the village has started calling herself a *princess*. I did not know we had one.",
	])


## The bench of spare gear by the door: a practice sword, a shield on the
## wall with Haven's crest, his travel pack.
func _gear(k) -> void:
	var gx := -W * 0.5 + 1.4
	var gz := D * 0.5 - 0.45
	_solid(k, Vector3(gx, 0.25, gz), Vector3(1.6, 0.5, 0.5), "wood", Color(0.8, 0.68, 0.56))
	var g = k._tmp(false)
	# A wooden practice sword leaning on the wall.
	g.push(Transform3D(Basis(Vector3.BACK, 0.25), Vector3(gx + 1.2, 0.6, gz + 0.12)))
	g.box(Vector3(0, 0.3, 0), Vector3(0.07, 0.9, 0.03), Color.html("c8a070"))
	g.box(Vector3(0, -0.18, 0), Vector3(0.26, 0.05, 0.05), Color.html("6a4a30"))
	g.box(Vector3(0, -0.32, 0), Vector3(0.05, 0.25, 0.05), Color.html("4a3020"))
	g.pop()
	# The travel pack on the bench.
	g.icosa(Vector3(gx - 0.35, 0.68, gz - 0.02), Vector3(0.28, 0.2, 0.18), 0.1, Color.html("6b4529"))
	g.box(Vector3(gx - 0.35, 0.78, gz - 0.2), Vector3(0.3, 0.04, 0.02), Color.html("c9a64e"))
	# Haven's crest on a round shield over the bench.
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(gx, 1.9, D * 0.5 - 0.04)))
	g.prism(Vector3(0, -0.03, 0), 0.42, Vector3(0, 0.03, 0), 0.42, 14, Color.html("7a5236"))
	g.prism(Vector3(0, -0.04, 0), 0.34, Vector3(0, 0.04, 0), 0.34, 14, Color.html(RED))
	g.box(Vector3(0, -0.06, 0), Vector3(0.1, 0.02, 0.5), Color.html("d8b050"))
	g.box(Vector3(0, -0.06, -0.05), Vector3(0.4, 0.02, 0.1), Color.html("d8b050"))
	g.pop()
	k.merge(g, "char")


## Three portraits on the north wall: Gigglebuns I, II and III, each in a
## gilt frame with a red-cloaked figure on a colored ground.
func _portraits(k) -> void:
	var grounds := ["4a6aa8", "6a8a4a", "8a4a6a"]
	var p = k._tmp(false)
	for i in 3:
		var px := -1.6 + i * 1.3
		var at := Vector3(px - 1.6, 2.3, -D * 0.5 + 0.03)
		p.box(at, Vector3(0.9, 1.1, 0.05), Color.html("c9a64e"))
		p.box(at + Vector3(0, 0, 0.02), Vector3(0.74, 0.94, 0.03), Color.html(grounds[i]))
		# The figure: red body, a face and a dash of hair.
		p.box(at + Vector3(0, -0.2, 0.04), Vector3(0.36, 0.42, 0.02), Color.html(RED))
		p.box(at + Vector3(0, 0.14, 0.04), Vector3(0.18, 0.2, 0.02), Color.html("e3b08a"))
		p.box(at + Vector3(0, 0.25, 0.045), Vector3(0.22, 0.07, 0.02), Color.html(["d8b050", "6a4020", "f0f0f0"][i]))
	k.merge(p, "char")
	for i in 3:
		var px := -1.6 + i * 1.3 - 1.6
		k.pixel_text(["I", "II", "III"][i], Vector3(px, 1.66, -D * 0.5 + 0.06), 0.0, 0.04, Color.html("f0d060"))
		# CHECK a portrait for its story (portrait_lines.gd).
		k.examine(Vector3(px, FLOOR_Y, -D * 0.5 + 0.5), PI, [], "res://scripts/npc/portrait_lines.gd", str(i + 1), 1.3)


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
