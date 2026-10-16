extends "res://tools/world/region.gd"
## Inside Himeko's "palace" in Haven Village: one grand pink room, every inch
## of it as pleased with itself as she is. A red carpet runs from the door to
## a gilded chair on a little dais, under an enormous portrait of Himeko
## herself; a crystal chandelier, a canopy bed hung with pink silk, a vanity
## with an oval mirror and a row of scent bottles, a tea table laid with a
## cake stand, roses everywhere, a shelf of romance novels, and a round stone
## pond with no fish in it (yet: see himeko_lines.gd). Himeko stands before
## her chair, receiving visitors.
##
## After the fall (Chapter II, "game_beaten") the palace shelters Castle Town's
## survivors: bedrolls on the marble, Pink, the Questlords Aladriel and Idrith,
## and Tansy with her cup game; walking in the first time plays their
## briefing (Story.shelter_briefing).

const W := 13.0
const D := 10.0
const WALL_H := 4.6
const FLOOR_Y := 0.0
const DAIS_Y := 0.35
const POND := Vector2(-4.4, 2.6)
const POND_R := 1.1
const PINK := "f4c4d4"
const ROSE := "d8203a"
const GOLD := "e0b84a"
const PLUM := "7a2a5a"


func setup() -> void:
	id = "himeko_house"
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
		"sky_top": Color.html("2a1a20"), "sky_mid": Color.html("2a1a20"), "sky_horizon": Color.html("2a1a20"),
		"cloud": Color.html("2a1a20"), "cloud_amount": 0.0,
		"fog": Color.html("1a1014"), "fog_begin": 22.0, "fog_end": 60.0,
		"ambient": Color.html("9a7a84"), "sun": Color.html("fff0f0"), "sun_rot": Vector3(-70, 20, 0),
		"sun_energy": 0.8, "fill": Color.html("8a6a9a"), "fill_energy": 0.35,
		"horizon": Color.html("2a1a20"), "hill_height": 0.0,
	}


func base_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func surface_at(x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "carpet" if absf(x) < 0.8 else "stone"


## Polished pink and white marble in a diamond check, the carpet's line
## painted darker under it.
func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var u := floori((x + z + 40.0) / 1.1)
	var v := floori((x - z + 40.0) / 1.1)
	var c := Color.html("f6e8ee") if (u + v) % 2 == 0 else Color.html("e8b8c8")
	var seam := fmod(x + z + 40.0, 1.1) < 0.04 or fmod(x - z + 40.0, 1.1) < 0.04
	if seam:
		c = Color.html(GOLD).darkened(0.1)
	return c.darkened(r.randf_range(0.0, 0.05))


func build(k) -> void:
	k.room(0.0, 0.0, W, D, WALL_H, FLOOR_Y, "plaster", Color.html(PINK), Color(0.95, 0.85, 0.9))
	k.door_link(Vector3(0, FLOOR_Y, D * 0.5 - 0.02), 0.0, 1.3, 2.3, "village", "from_himeko_house", Color(1.0, 0.85, 0.9))
	k.entrance("from_village", 0.0, D * 0.5 - 1.4, 0.0)
	_trim(k)
	_carpet_and_dais(k)
	_portrait(k)
	_chandelier(k)
	_bed(k)
	_vanity(k)
	_tea(k)
	_pond(k)
	_shelf(k)
	# Roses in tall vases along the walls.
	for p in [Vector2(-1.6, -D * 0.5 + 0.5), Vector2(1.6, -D * 0.5 + 0.5), Vector2(-1.4, D * 0.5 - 0.5), Vector2(1.4, D * 0.5 - 0.5)]:
		_roses(k, Vector3(p.x, FLOOR_Y, p.y))
	# Himeko, before her chair, receiving visitors.
	k.npc("Himeko", "res://assets/models/himeko.tscn", "res://scripts/npc/himeko_lines.gd", 0.0, -2.4, PI, DAIS_Y)
	_shelter(k)
	# A gilt plaque on the pond's rim: its royal resident.
	k.examine(Vector3(POND.x + POND_R + 0.35, FLOOR_Y, POND.y), k.yaw_of(Vector2(1, 0)), [], "res://scripts/npc/pond_plaque_lines.gd", "", 1.2)


## Castle Town's survivors, after the fall: bedrolls and bundles, and the
## people on them.
func _shelter(k) -> void:
	const BEATEN := "game_beaten"
	var props = k._tmp(false)
	var rolls := [Vector3(-2.4, 0.0, 4.2), Vector3(-1.4, 0.0, 4.25), Vector3(1.5, 0.0, 4.2), Vector3(2.6, 0.0, 4.3), Vector3(-5.6, 0.0, 0.6), Vector3(5.6, 0.0, 0.4)]
	var cols := ["8a5a3a", "5a6a8a", "7a3a4a", "6a7a4a", "8a7a5a", "4a5a6a"]
	for i in rolls.size():
		var r: Vector3 = rolls[i]
		var along_x: bool = absf(r.x) > 5.0
		var size := Vector3(1.9, 0.12, 0.8) if along_x else Vector3(0.8, 0.12, 1.9)
		props.box(r + Vector3(0, 0.06, 0), size, Color.html(cols[i]))
		props.box(r + (Vector3(0.75, 0.15, 0) if along_x else Vector3(0, 0.15, -0.7)), Vector3(0.36, 0.14, 0.5) if along_x else Vector3(0.5, 0.14, 0.36), Color.html("e8e0d0"))
	# Bundles, a cooking pot and a crate of what they saved.
	for b in [Vector3(-3.2, 0.0, 4.4), Vector3(3.3, 0.0, 4.45), Vector3(-6.0, 0.0, -0.6)]:
		props.icosa(b + Vector3(0, 0.2, 0), Vector3(0.26, 0.2, 0.22), 0.1, Color.html("a08a64"))
	props.prism(Vector3(0.0, 0.0, 3.6), 0.25, Vector3(0.0, 0.3, 3.6), 0.28, 8, Color.html("3a3a40"))
	k.flag_props(BEATEN, props, "char")
	k.npc("Aladriel", "res://assets/models/aladriel.tscn", "res://scripts/npc/shelter_lines.gd", 2.4, 1.0, k.yaw_of(Vector2(-1, 0)), FLOOR_Y,
		{"show": BEATEN, "hide": "ch4:siege_won", "partner": "Idrith"})
	k.npc("Idrith", "res://assets/models/idrith.tscn", "res://scripts/npc/shelter_lines.gd", 2.4, 2.2, k.yaw_of(Vector2(-1, 0)), FLOOR_Y,
		{"show": BEATEN, "hide": "ch4:siege_won", "partner": "Aladriel"})
	k.npc("Pink", "res://assets/models/pink.tscn", "res://scripts/npc/shelter_lines.gd", 4.6, -1.0, k.yaw_of(Vector2(-1, 0)), FLOOR_Y,
		{"show": BEATEN, "idle": "stand"})
	# Tansy and her cups, by the bed.
	var table_at := Vector2(-3.0, -0.4)
	var face := Vector2(1, 0)
	k.cup_game(table_at.x, table_at.y, k.yaw_of(face), FLOOR_Y).set("show_flag", BEATEN)
	k.npc("Tansy", "res://assets/models/tansy.tscn", "res://scripts/npc/tansy_lines.gd", table_at.x - 0.75, table_at.y, k.yaw_of(face), FLOOR_Y, {"show": BEATEN})
	# Pip, the King's page, sheltering with the rest (Beta 1.5.0).
	k.npc("Pip", "res://assets/models/pip.tscn", "res://scripts/npc/market_lines.gd", -1.8, 2.6, k.yaw_of(Vector2(0.4, -1).normalized()), FLOOR_Y, {"show": "castle_fallen", "hide": "ch4:war"})
	# The briefing, the first time he walks in after the fall.
	var trig := Area3D.new()
	trig.name = "ShelterTrigger"
	trig.set_script(load("res://scripts/systems/story_trigger.gd"))
	trig.set("scene", "shelter_briefing")
	trig.set("flag", "ch2:shelter_met")
	trig.set("need_flag", BEATEN)
	trig.position = Vector3(0, 1.0, D * 0.5 - 1.6)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 2.0, 2.6)
	cs.shape = box
	trig.add_child(cs)
	k._misc.add_child(trig)


## Gold mouldings round the room at the top of the walls and at dado height,
## and tall windows with pink drapes.
func _trim(k) -> void:
	var t = k._tmp(false)
	var gold := Color.html(GOLD)
	for y in [1.05, WALL_H - 0.15]:
		t.box(Vector3(0, y, -D * 0.5 + 0.03), Vector3(W, 0.12, 0.06), gold)
		t.box(Vector3(0, y, D * 0.5 - 0.03), Vector3(W, 0.12, 0.06), gold)
		t.box(Vector3(-W * 0.5 + 0.03, y, 0), Vector3(0.06, 0.12, D), gold)
		t.box(Vector3(W * 0.5 - 0.03, y, 0), Vector3(0.06, 0.12, D), gold)
	k.merge(t, "char")
	for wz in [-2.4, 1.4]:
		for sx in [-1.0, 1.0]:
			var wx: float = sx * (W * 0.5 - 0.02)
			var glass = k._tmp(false)
			glass.box(Vector3(wx, 2.3, wz), Vector3(0.04, 1.8, 1.1), Color.html("fff4f8"))
			k.merge(glass, "glow")
			var drape = k._tmp(false)
			for dz in [-0.75, 0.75]:
				drape.box(Vector3(wx - sx * 0.06, 2.4, wz + dz), Vector3(0.06, 2.6, 0.4), Color.html("e88aa8"))
			drape.box(Vector3(wx - sx * 0.07, 3.6, wz), Vector3(0.08, 0.3, 1.9), Color.html("c8507a"))
			drape.box(Vector3(wx - sx * 0.04, 2.3, wz), Vector3(0.05, 1.9, 1.2), Color.html(GOLD))
			k.merge(drape, "char")


## The red carpet from the door to the dais, edged in gold; the dais and
## the gilded chair (her "throne") with plum cushions.
func _carpet_and_dais(k) -> void:
	var c = k._tmp(false)
	c.box(Vector3(0, 0.012, 0.6), Vector3(1.6, 0.024, D - 3.2), Color.html("b8182a"))
	for sx in [-1.0, 1.0]:
		c.box(Vector3(sx * 0.76, 0.016, 0.6), Vector3(0.08, 0.026, D - 3.2), Color.html(GOLD))
	k.merge(c, "char")
	var dz := -D * 0.5 + 1.6
	var cs: CollisionShape3D = k.block(Vector3(0, DAIS_Y * 0.5, dz), Vector3(4.6, DAIS_Y, 3.2), 0.0, "stone", Color(1.0, 0.92, 0.95))
	cs.set_meta("no_climb", true)
	var top = k._tmp(false)
	top.box(Vector3(0, DAIS_Y + 0.01, dz), Vector3(4.2, 0.02, 2.8), Color.html("b8182a"))
	top.box(Vector3(0, DAIS_Y * 0.5, dz + 1.61), Vector3(4.6, DAIS_Y, 0.02), Color.html(GOLD))
	k.merge(top, "char")
	# The chair: gold frame, plum seat and a tall back crowned with a fan.
	var cz := -D * 0.5 + 0.75
	var chair = k._tmp(false)
	var gold := Color.html(GOLD)
	chair.box(Vector3(0, DAIS_Y + 0.25, cz), Vector3(1.0, 0.5, 0.8), gold)
	chair.box(Vector3(0, DAIS_Y + 0.54, cz + 0.02), Vector3(0.86, 0.1, 0.7), Color.html(PLUM))
	chair.box(Vector3(0, DAIS_Y + 1.2, cz - 0.35), Vector3(1.0, 1.4, 0.12), gold)
	chair.box(Vector3(0, DAIS_Y + 1.15, cz - 0.28), Vector3(0.78, 1.1, 0.04), Color.html(PLUM))
	for sx in [-1.0, 1.0]:
		chair.box(Vector3(sx * 0.5, DAIS_Y + 0.75, cz), Vector3(0.1, 0.12, 0.8), gold)
	for i in 7:
		var a := deg_to_rad(-60.0 + i * 20.0)
		chair.push(Transform3D(Basis(Vector3.BACK, a), Vector3(0, DAIS_Y + 1.9, cz - 0.36)))
		chair.box(Vector3(0, 0.22, 0), Vector3(0.09, 0.44, 0.04), gold if i % 2 else Color.html("f4d878"))
		chair.pop()
	k.merge(chair, "char")
	var hit: CollisionShape3D = k.col_box(Vector3(0, DAIS_Y + 0.8, cz - 0.1), Vector3(1.0, 1.6, 0.9))
	hit.set_meta("no_climb", true)


## The portrait over the chair: Himeko herself, life size and then some, in
## a heavy gold frame (long black hair, crimson kimono, the fan).
func _portrait(k) -> void:
	var at := Vector3(0, 3.0, -D * 0.5 + 0.04)
	var p = k._tmp(false)
	p.box(at, Vector3(1.9, 2.2, 0.06), Color.html(GOLD))
	p.box(at + Vector3(0, 0, 0.02), Vector3(1.6, 1.9, 0.04), Color.html("3a1a3a"))
	var f := at + Vector3(0, 0, 0.05)
	p.box(f + Vector3(0, 0.05, 0), Vector3(0.82, 1.3, 0.02), Color.html("16141c"))
	p.box(f + Vector3(0, 0.38, 0.01), Vector3(0.42, 0.5, 0.02), Color.html("fae6d8"))
	p.box(f + Vector3(0, 0.6, 0.015), Vector3(0.46, 0.12, 0.02), Color.html("16141c"))
	for sx in [-1.0, 1.0]:
		p.box(f + Vector3(sx * 0.2, 0.32, 0.02), Vector3(0.07, 0.36, 0.02), Color.html("16141c"))
		p.box(f + Vector3(sx * 0.1, 0.4, 0.022), Vector3(0.06, 0.05, 0.02), Color.html("7a4422"))
	p.box(f + Vector3(0, -0.45, 0.012), Vector3(0.9, 0.82, 0.02), Color.html("b8182a"))
	p.box(f + Vector3(0, -0.34, 0.016), Vector3(0.9, 0.16, 0.02), Color.html(GOLD))
	p.box(f + Vector3(0, 0.05, 0.016), Vector3(0.12, 0.2, 0.02), Color.html("f8f4ee"))
	for i in 5:
		var a := deg_to_rad(-50.0 + i * 25.0)
		p.push(Transform3D(Basis(Vector3.BACK, a), f + Vector3(0.3, -0.3, 0.03)))
		p.box(Vector3(0, 0.12, 0), Vector3(0.07, 0.24, 0.01), Color.html(PLUM))
		p.pop()
	k.merge(p, "char")
	k.pixel_text("HIMEKO", at + Vector3(0, -1.0, 0.05), 0.0, 0.03, Color.html("fff0a0"))


## A crystal chandelier over the middle of the room, with a warm light.
func _chandelier(k) -> void:
	var c := Vector3(0, WALL_H - 1.1, 0.4)
	var ch = k._tmp(false)
	ch.box(c + Vector3(0, 0.6, 0), Vector3(0.04, 1.0, 0.04), Color.html(GOLD))
	ch.prism(c, 0.7, c + Vector3(0, 0.06, 0), 0.7, 12, Color.html(GOLD))
	ch.prism(c + Vector3(0, 0.06, 0), 0.25, c + Vector3(0, 0.5, 0), 0.05, 8, Color.html(GOLD))
	k.merge(ch, "char")
	var lights = k._tmp(false)
	for i in 8:
		var a := TAU * i / 8.0
		var p := c + Vector3(cos(a) * 0.65, 0.06, sin(a) * 0.65)
		lights.prism(p, 0.03, p + Vector3(0, 0.14, 0), 0.03, 6, Color.html("fff4e0"))
		lights.prism(p + Vector3(0, 0.14, 0), 0.02, p + Vector3(0, 0.22, 0), 0.0, 5, Color.html("ffd060"))
		lights.icosa(p + Vector3(0, -0.15, 0), Vector3(0.04, 0.08, 0.04), 0.0, Color.html("f0f4ff"))
	k.merge(lights, "glow")
	var light := OmniLight3D.new()
	light.name = "ChandelierLight"
	light.position = c + Vector3(0, -0.3, 0)
	light.light_color = Color.html("ffe8d0")
	light.light_energy = 1.5
	light.omni_range = 10.0
	light.shadow_enabled = false
	k._misc.add_child(light)


## A canopy bed against the west wall: four gilt posts, pink silk hangings,
## white covers and a heap of heart-shaped cushions.
func _bed(k) -> void:
	var bx := -W * 0.5 + 1.2
	var bz := -2.0
	_solid(k, Vector3(bx, 0.3, bz), Vector3(2.0, 0.6, 2.6), "wood", Color(1.0, 0.9, 0.95))
	var b = k._tmp(false)
	b.box(Vector3(bx, 0.66, bz), Vector3(1.9, 0.14, 2.5), Color.html("fff8fa"))
	b.box(Vector3(bx + 0.1, 0.75, bz), Vector3(1.6, 0.06, 2.52), Color.html("f4a0b8"))
	for sz in [-0.4, 0.4]:
		b.icosa(Vector3(bx - 0.6, 0.86, bz + sz), Vector3(0.14, 0.14, 0.24), 0.0, Color.html("e83a6a"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(bx + sx * 0.95, 1.4, bz + sz * 1.25), Vector3(0.1, 2.8, 0.1), Color.html(GOLD))
	b.box(Vector3(bx, 2.82, bz), Vector3(2.1, 0.1, 2.7), Color.html(GOLD))
	b.box(Vector3(bx, 2.9, bz), Vector3(2.0, 0.12, 2.6), Color.html("e88aa8"))
	for sz in [-1.0, 1.0]:
		b.box(Vector3(bx, 2.2, bz + sz * 1.3), Vector3(2.0, 1.2, 0.04), Color.html("f4b0c8"))
	b.box(Vector3(bx - 1.02, 1.8, bz), Vector3(0.04, 2.0, 2.6), Color.html("f4b0c8"))
	k.merge(b, "char")


## The vanity on the east wall: a little table, an oval mirror in a gold frame
## and a row of scent bottles, with a cushioned stool.
func _vanity(k) -> void:
	var vx := W * 0.5 - 0.45
	var vz := -2.2
	_solid(k, Vector3(vx, 0.4, vz), Vector3(0.7, 0.8, 1.6), "wood", Color(1.0, 0.92, 0.96))
	var v = k._tmp(false)
	v.push(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(vx + 0.3, 1.65, vz)))
	v.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	v.prism(Vector3(0, -0.02, 0), 0.5, Vector3(0, 0.02, 0), 0.5, 16, Color.html(GOLD))
	v.pop()
	v.pop()
	for i in 5:
		var p := Vector3(vx - 0.1, 0.8, vz - 0.6 + i * 0.3)
		v.prism(p, 0.05, p + Vector3(0, 0.14, 0), 0.03, 6, Color.html(["e870a0", "a070e0", "70c0e0", "f0c040", "e85050"][i]))
	k.merge(v, "char")
	var mirror = k._tmp(false)
	mirror.push(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(vx + 0.27, 1.65, vz)))
	mirror.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	mirror.prism(Vector3(0, -0.03, 0), 0.42, Vector3(0, 0.0, 0), 0.42, 16, Color.html("dce8f4"))
	mirror.pop()
	mirror.pop()
	k.merge(mirror, "glow")
	_solid(k, Vector3(vx - 0.8, 0.22, vz), Vector3(0.5, 0.44, 0.5), "wood", Color(0.95, 0.75, 0.85))


## The tea table by the east windows: a round table, two chairs, a cake stand
## of three tiers and the best china.
func _tea(k) -> void:
	var tx := 3.6
	var tz := 2.0
	var cs: CollisionShape3D = k.block(Vector3(tx, 0.38, tz), Vector3(1.1, 0.76, 1.1), 0.0, "wood", Color(1.0, 0.95, 0.98))
	cs.set_meta("no_climb", true)
	var t = k._tmp(false)
	t.prism(Vector3(tx, 0.76, tz), 0.62, Vector3(tx, 0.79, tz), 0.62, 14, Color.html("fff8fa"))
	t.prism(Vector3(tx, 0.79, tz), 0.025, Vector3(tx, 1.25, tz), 0.025, 6, Color.html(GOLD))
	for tier in 3:
		var y := 0.85 + tier * 0.15
		var r := 0.22 - tier * 0.05
		t.prism(Vector3(tx, y, tz), r, Vector3(tx, y + 0.015, tz), r, 10, Color.html("f8f4ee"))
		for j in 4:
			var a := TAU * j / 4.0 + tier
			t.icosa(Vector3(tx + cos(a) * r * 0.6, y + 0.05, tz + sin(a) * r * 0.6), Vector3(0.04, 0.035, 0.04), 0.1, Color.html(["f4a0b8", "fff0c0", "a0d080"][tier]))
	for sx in [-1.0, 1.0]:
		var cup := Vector3(tx + sx * 0.38, 0.79, tz + 0.1)
		t.prism(cup, 0.06, cup + Vector3(0, 0.01, 0), 0.08, 10, Color.html("f8f4ee"))
		t.prism(cup + Vector3(0, 0.01, 0), 0.035, cup + Vector3(0, 0.08, 0), 0.05, 8, Color.html("f8f4ee"))
	t.prism(Vector3(tx, 0.79, tz - 0.3), 0.08, Vector3(tx, 0.95, tz - 0.3), 0.06, 8, Color.html("f4a0b8"))
	k.merge(t, "char")
	for sx in [-1.0, 1.0]:
		_solid(k, Vector3(tx + sx * 0.95, 0.25, tz), Vector3(0.48, 0.5, 0.48), "wood", Color(1.0, 0.85, 0.92))


## The palace pond: a round stone basin with lilies, waiting for a fish.
func _pond(k) -> void:
	var p := Vector3(POND.x, FLOOR_Y, POND.y)
	var cs: CollisionShape3D = k.block(p + Vector3(0, 0.2, 0), Vector3(POND_R * 2.0, 0.4, POND_R * 2.0), 0.0, "stone", Color(0.95, 0.92, 0.96))
	cs.set_meta("no_climb", true)
	# Kept out of the water by a taller (unseen) wall round the rim.
	cs = k.col_box(p + Vector3(0, 0.5, 0), Vector3(POND_R * 2.2, 1.0, POND_R * 2.2))
	cs.set_meta("no_climb", true)
	var rim = k._tmp(false)
	rim.prism(p, POND_R + 0.12, p + Vector3(0, 0.48, 0), POND_R + 0.12, 16, Color.html("e8e0e8"))
	rim.prism(p + Vector3(0, 0.401, 0), POND_R - 0.02, p + Vector3(0, 0.402, 0), POND_R - 0.02, 16, Color.html("4a7a9a"))
	k.merge(rim, "stone")
	var water = k._tmp(false)
	water.prism(p + Vector3(0, 0.465, 0), POND_R - 0.02, p + Vector3(0, 0.47, 0), POND_R - 0.02, 16, Color(0.4, 0.7, 0.95, 0.5))
	k.merge(water, "shadow")
	var lily = k._tmp(false)
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		var lp := p + Vector3(cos(a) * 0.55, 0.472, sin(a) * 0.55)
		lily.prism(lp, 0.16, lp + Vector3(0, 0.01, 0), 0.16, 8, Color.html("4a9a4a"))
		if i == 0:
			lily.icosa(lp + Vector3(0, 0.05, 0), Vector3(0.06, 0.05, 0.06), 0.1, Color.html("ffc8d8"))
	k.merge(lily, "char")
	k._dyn("res://scripts/npc/pond_fish.gd", "PondFish", p + Vector3(0, 0.435, 0), 0.0, {"flag": "himeko:fish_given", "radius": POND_R * 0.55}, Node3D.new())


## A shelf of romance novels by the door, and one left open on a side table.
func _shelf(k) -> void:
	var sx := W * 0.5 - 0.3
	var sz := 3.6
	_solid(k, Vector3(sx, 1.0, sz), Vector3(0.5, 2.0, 1.8), "wood", Color(1.0, 0.9, 0.95))
	var books = k._tmp(false)
	var r: RandomNumberGenerator = k.rng
	for shelf in [0.5, 1.1, 1.7]:
		for i in 8:
			var bz := sz - 0.75 + i * 0.2
			var h := r.randf_range(0.2, 0.3)
			books.box(Vector3(sx - 0.26, shelf + h * 0.5, bz), Vector3(0.18, h, 0.13), Color.html(["e870a0", "c8507a", "f4b0c8", "a050a0", "e83a6a"][r.randi_range(0, 4)]))
	k.merge(books, "char")
	_solid(k, Vector3(sx - 1.0, 0.35, sz), Vector3(0.6, 0.7, 0.6), "wood", Color(1.0, 0.9, 0.95))
	k.book(Vector3(sx - 1.0, 0.7, sz), k.yaw_of(Vector2(-1, 0)), "The Princess and the Pauper Knight", [
		"*The Princess and the Pauper Knight*\nVolume Seven",
		"\"You may kiss my hand,\" said the Princess, \"but only because it is Tuesday.\"",
		"The pages here are worn thin from reading. Someone has pressed a pink rose between them.",
	])


func _roses(k, at: Vector3) -> void:
	var v = k._tmp(false)
	v.prism(at, 0.16, at + Vector3(0, 0.6, 0), 0.12, 8, Color.html("f8f4ee"))
	v.prism(at + Vector3(0, 0.6, 0), 0.12, at + Vector3(0, 0.66, 0), 0.15, 8, Color.html(GOLD))
	for i in 7:
		var a := TAU * i / 7.0
		v.icosa(at + Vector3(cos(a) * 0.12, 0.85 + (i % 2) * 0.08, sin(a) * 0.12), Vector3(0.07, 0.07, 0.07), 0.15, Color.html(ROSE if i % 3 else "f070a0"))
	v.icosa(at + Vector3(0, 0.95, 0), Vector3(0.08, 0.08, 0.08), 0.15, Color.html(ROSE))
	k.merge(v, "char")


func _solid(k, center: Vector3, size: Vector3, mat: String, col: Color) -> void:
	var cs: CollisionShape3D = k.block(center, size, 0.0, mat, col)
	cs.set_meta("no_climb", true)
