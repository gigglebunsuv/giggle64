extends "res://tools/world/regions/castle_town_rebuilt.gd"
## Castle Town years later (Chapter V, castle_town_restored): every district
## long finished, bunting across the streets, the castle's banners flying,
## and two new things:
## - the KNIGHTS' YARD on the castle's west lawn, where Commander Rowena trains
##   the new knight (knights_lines.gd): a ring of straw dummies (the Great
##   Spin), a watch platform over a straw target (the Down Thrust) and a
##   shield pell (the Shield Bash), all TechniqueTargets;
## - the old royal chapel east of the square, its doors opening onto the
##   BARROW OF KINGS once the crypt wakes ("ch5:barrow_open").
## The knighting (Story.knighting) happens on the castle avenue (the
## "knighting" entrance and the cs_knight_* marks).

## The Knights' Yard, and the height its ground is leveled to.
const YARD := Rect2(-50.0, -63.0, 28.0, 16.0)
const YARD_Y := 1.7
const RING := Vector2(-42.0, -52.5)
const PLATFORM := Vector2(-30.0, -59.0)
const PLATFORM_H := 3.2
const PELL := Vector2(-36.0, -60.5)
const KNIGHT := Vector2(0.0, -55.0)


func setup() -> void:
	super.setup()
	id = "castle_town_restored"
	link_id = "castle_town"
	seed_value = 3151
	finished = true
	chapel_open = true
	tree_skip = YARD


## The yard's ground leveled flat, easing into the lawn round it.
func base_height(x: float, z: float) -> float:
	var h := super.base_height(x, z)
	var d := _rect_dist(YARD, Vector2(x, z))
	return lerpf(YARD_Y, h, smoothstep(0.0, 5.0, d))


static func _rect_dist(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0)
	var dz := maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)
	return Vector2(dx, dz).length()


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if YARD.grow(-0.5).has_point(Vector2(x, z)):
		# Packed earth and sawdust, scuffed by a thousand drills.
		return Color.html(["a08a64", "98825c", "aa9470"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08))
	return super.ground_color(x, z, h, r)


func build(k) -> void:
	super.build(k)
	var r: RandomNumberGenerator = k.rng
	_bunting(k, r)
	_yard(k)
	# The knighting on the castle avenue.
	var ky: float = k.h(KNIGHT.x, KNIGHT.y)
	k.entrance("knighting", KNIGHT.x, KNIGHT.y + 1.5, 0.0)
	k.mark("cs_knight_hero", Vector3(KNIGHT.x, ky, KNIGHT.y), 0.0)
	k.mark("cs_knight_rowena", Vector3(KNIGHT.x - 0.6, k.h(KNIGHT.x, KNIGHT.y - 2.4), KNIGHT.y - 2.4), PI)
	k.mark("cs_knight_himeko", Vector3(KNIGHT.x + 2.0, k.h(KNIGHT.x + 2.0, KNIGHT.y - 2.0), KNIGHT.y - 2.0), PI * 0.8)
	k.mark("cs_knight_cam", Vector3(KNIGHT.x + 5.5, ky + 3.0, KNIGHT.y + 5.0))
	k.mark("cs_vision", Vector3(0.0, 320.0, 0.0))
	var cy: float = k.h(0, CASTLE_Z)
	k.examine(Vector3(0, cy, CASTLE_Z + 3.0), PI, [], "res://scripts/npc/chapter5_lines.gd", "castle")
	k.examine(Vector3(32.4, k.h(32.4, -18.6), -18.6), -PI * 0.5, [], "res://scripts/npc/chapter5_lines.gd", "chapel")


## Strings of little flags across the main street and round the square.
func _bunting(k, r: RandomNumberGenerator) -> void:
	var m = k._tmp(false)
	var cols := [Color.html("3048a8"), Color.html("e8e0d0"), Color.html("c83a2a"), Color.html("e8c050")]
	var lines := [[Vector2(-5.0, 34.0), Vector2(5.0, 34.0)], [Vector2(-5.0, 24.0), Vector2(5.0, 24.0)], [Vector2(-5.0, -24.0), Vector2(5.0, -24.0)],
		[Vector2(-15.0, 2.0), Vector2(-4.0, 12.0)], [Vector2(15.0, 2.0), Vector2(4.0, 12.0)], [Vector2(-15.0, 2.0), Vector2(-4.0, -8.0)], [Vector2(15.0, 2.0), Vector2(4.0, -8.0)]]
	for ln: Array in lines:
		var a: Vector2 = ln[0]
		var b: Vector2 = ln[1]
		var ya: float = k.h(a.x, a.y) + 5.2
		var yb: float = k.h(b.x, b.y) + 5.2
		var n := int(a.distance_to(b) / 0.8)
		for i in n:
			var t := (i + 0.5) / n
			var p := a.lerp(b, t)
			var y := lerpf(ya, yb, t) - sin(t * PI) * 0.8
			m.box(Vector3(p.x, y - 0.18, p.y), Vector3(0.3, 0.36, 0.03), cols[(i + r.randi_range(0, 1)) % cols.size()])
		m.box(Vector3((a.x + b.x) * 0.5, (ya + yb) * 0.5 - 0.42, (a.y + b.y) * 0.5), Vector3(0.02, 0.02, 0.02), Color.html("4a3a2a"))
	k.merge(m, "char")
	for z in [30.0, 20.0, -20.0, -30.0]:
		for sx in [-1.0, 1.0]:
			k.banner(sx * 4.6, k.h(sx * 4.6, z) + 5.0, z, PI * 0.5 * -sx, Color.html("3048a8") if int(z) % 20 == 0 else Color.html("c83a2a"), 2.2)


## The Knights' Yard: a timber fence round packed earth, open toward the avenue.
func _yard(k) -> void:
	var y := YARD_Y
	var x0 := YARD.position.x
	var x1 := YARD.end.x
	var z0 := YARD.position.y
	var z1 := YARD.end.y
	var wood := Color(0.82, 0.68, 0.5)
	k.fence([Vector2(x1, z1 - 4.5), Vector2(x1, z1), Vector2(x0, z1), Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z0 + 4.5)], wood, 1.2)
	k.signpost(x1 + 1.2, z1 - 6.0, Vector2(x1 + 4.0, z1 - 6.0), "*THE KNIGHTS' YARD*\nTraining at dawn.\n\nSquires: mind the dummies.")
	# The ring of straw dummies (the Great Spin).
	k.technique_target("ring", RING.x, RING.y, "yard:spin_done", y, {"size": 1.7, "count": 4, "post_mesh": "training_dummy"})
	k.examine(Vector3(RING.x + 3.2, y, RING.y + 2.6), PI * 0.25, [], "res://scripts/npc/knights_lines.gd", "ring")
	# The watch platform over the straw target (the Down Thrust).
	k.platform(PLATFORM.x, PLATFORM.y, Vector2(3.0, 3.0), y + PLATFORM_H, "wood", wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.pillar(PLATFORM.x + sx * 1.3, PLATFORM.y + sz * 1.3, PLATFORM_H, 0.14, false, "wood", y)
	k.ladder(PLATFORM.x - 1.5, PLATFORM.y, Vector2(-1, 0), y, y + PLATFORM_H)
	k.technique_target("plate", PLATFORM.x, PLATFORM.y + 3.6, "yard:thrust_done", y + 0.02, {"size": 2.6})
	k.examine(Vector3(PLATFORM.x + 2.4, y, PLATFORM.y + 1.2), -PI * 0.5, [], "res://scripts/npc/knights_lines.gd", "platform")
	# The shield pell (the Shield Bash).
	k.technique_target("pell", PELL.x, PELL.y, "yard:bash_done", y, {"yaw": 0.0})
	k.examine(Vector3(PELL.x - 2.4, y, PELL.y + 1.0), PI * 0.5, [], "res://scripts/npc/knights_lines.gd", "pell")
	# Racks of practice swords, a barrel of water, the notice board.
	for i in 3:
		k.barrel(x0 + 2.0 + i * 0.9, z1 - 1.5)
	var rack = k._tmp(false)
	for i in 2:
		var rx := x0 + 1.0
		var rz := z0 + 3.0 + i * 3.0
		rack.box(Vector3(rx, y + 0.45, rz), Vector3(0.5, 0.08, 1.6), Color.html("6a4428"))
		rack.box(Vector3(rx, y + 1.25, rz), Vector3(0.5, 0.08, 1.6), Color.html("6a4428"))
		for e in [-0.7, 0.7]:
			rack.box(Vector3(rx, y + 0.75, rz + e), Vector3(0.08, 1.5, 0.08), Color.html("5a3820"))
		k.col_box(Vector3(rx, y + 0.75, rz), Vector3(0.5, 1.5, 1.6))
		for j in 3:
			k.display_mesh("res://assets/models/sword_squire_mesh.tres", Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(rx, y + 1.35, rz - 0.5 + j * 0.5)))
	k.merge(rack, "char")
	var bk = k._tmp()
	var bp := Vector2(x1 - 3.0, z1 - 0.8)
	bk.box(Vector3(bp.x, y + 1.6, bp.y), Vector3(2.0, 1.2, 0.12), Color.html("6a4a2a"))
	bk.box(Vector3(bp.x, y + 1.6, bp.y - 0.07), Vector3(1.8, 1.0, 0.02), Color.html("e8dcc0"))
	for sx in [-1.0, 1.0]:
		bk.box(Vector3(bp.x + sx * 0.8, y + 0.8, bp.y), Vector3(0.12, 1.6, 0.12), Color.html("5a3a20"))
	k.merge(bk, "wood")
	k.col_box(Vector3(bp.x, y + 1.2, bp.y), Vector3(2.0, 2.4, 0.3))
	k.examine(Vector3(bp.x, y, bp.y - 0.4), 0.0, [], "res://scripts/npc/knights_lines.gd", "board", 1.8)
	k.banner(x0 + 0.4, y + 4.0, (z0 + z1) * 0.5, PI * 0.5, Color.html("3048a8"), 3.0)


func populate(k) -> void:
	k.signpost(-4.0, 36, Vector2(0, 32), "*Castle Town*\nMarket every day but Sunday.\n\nThe Knights' Yard is on the\ncastle's west lawn.")
	k.signpost(28.0, -15.0, Vector2(31.0, -18.0), "*The Royal Chapel*\nThe old kings sleep below.")
	for p in [Vector2(-7.0, 11.8), Vector2(11.0, -9.0), Vector2(23.0, 11.0), Vector2(-20.0, 11.0), Vector2(-8.0, 11.9)]:
		k.pot(p.x, p.y)
	k.pot(9.4, -10.4, "rupee_red")
	k.npc("Marigold", "res://assets/models/marigold.tscn", "res://scripts/npc/chapter5_lines.gd", -9.0, 16.5, PI * 0.8)
	var to_square := (SQUARE - Vector2(8.5, 7.5)).normalized()
	k.cup_game(8.5, 7.5, k.yaw_of(to_square))
	var behind := Vector2(8.5, 7.5) - to_square * 0.75
	k.npc("Tansy", "res://assets/models/tansy.tscn", "res://scripts/npc/tansy_lines.gd", behind.x, behind.y, k.yaw_of(to_square))
	_market(k)
	# On the street before the homes (the houses run from |x| 5 to 12).
	k.npc("Posy", "res://assets/models/posy.tscn", "res://scripts/npc/chapter5_lines.gd", 3.0, 28.4, PI * 0.5)
	k._dyn("res://scripts/npc/pepper.gd", "Pepper", k.g(2.2, 27.6), PI * 0.5, {"grown": true}, Node3D.new())
	k.npc("Haven Folk", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/chapter5_lines.gd", -3.0, -25.5, -PI * 0.5)
	# The Knights' Yard.
	# (She marches west with the knights once Firebuns leaves the Vault.)
	k.npc("Commander Rowena", "res://assets/models/rowena.tscn", "res://scripts/npc/knights_lines.gd", YARD.end.x - 4.0, YARD.end.y - 4.0, PI * 0.75, YARD_Y, {"hide": "ch5:cinder_done"})
	_memorial(k)
	k.npc("Squire", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/knights_lines.gd", YARD.position.x + 4.0, YARD.position.y + 3.0, -PI * 0.25, YARD_Y)
	# Pink's Armory, open as ever.
	var fx := -42.0 + 7.0
	var gy: float = k.h(fx + 0.5, -21.0)
	k.door_link(Vector3(fx + 0.06, gy, -21.0), PI * 1.5, 1.4, 2.4, "armory", "from_castle_town")
	k.entrance("from_armory", fx + 1.8, -21.0, -PI * 0.5)


## Beta 1.4.0: once Mara has fallen, a memorial banner in the square for the
## knights lost on Black Water Ridge.
func _memorial(k) -> void:
	var at := Vector2(-12.0, -4.0)
	var y: float = k.h(at.x, at.y)
	var m = k._tmp(false)
	m.prism(Vector3(at.x, y, at.y), 0.4, Vector3(at.x, y + 0.5, at.y), 0.34, 8, Color.html("8a8a92"))
	m.prism(Vector3(at.x, y + 0.5, at.y), 0.07, Vector3(at.x, y + 5.0, at.y), 0.06, 6, Color.html("5a4630"))
	m.box(Vector3(at.x, y + 4.7, at.y), Vector3(1.8, 0.08, 0.08), Color.html("c8a84a"))
	m.box(Vector3(at.x, y + 3.6, at.y + 0.04), Vector3(1.6, 2.2, 0.03), Color.html("1a2e62"))
	m.box(Vector3(at.x, y + 3.9, at.y + 0.07), Vector3(0.5, 0.5, 0.02), Color.html("d8dce4"))
	for i in 6:
		m.box(Vector3(at.x, y + 3.3 - i * 0.22, at.y + 0.07), Vector3(1.1, 0.05, 0.02), Color.html("c8ccd8"))
	k.flag_props("ch5:mara_done", m, "char")
	k.examine(Vector3(at.x, y, at.y + 1.2), 0.0, [{"text": "A banner of Haven blue, stitched in silver with the names of the knights who fell on Black Water Ridge.\nUnder them, newer stitching: *AND FOR THE KING'S ROAD GUARD, WHO HELD THE RIDGE BEFORE US.*", "instant": true}]).set("show_flag", "ch5:mara_done")
