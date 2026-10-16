extends "res://tools/world/region.gd"
## West Marshlands: shallow murky water between mud islands, dead trees and
## reeds, boardwalks on stilts, a hut on stilts, and the Bog Tower standing
## alone in deep water (its boardwalk is broken short: the Hookshot crosses).

const WATER_Y := -0.3
const TOWER := Vector2(-28, -25)
const ISLET_R := 9.5
const MOAT_R := 15.0
const HUT := Vector2(-36, 40)
## The rocky islet in its deep pool (a Spring of Lothelye), and the boardwalk
## spur ending at the pool's edge, a Hookshot's reach from the islet's post.
const ISLE := Vector2(28, -45)
const ISLE_R := 5.5
const ISLE_POOL_R := 11.0
const SPUR_END := Vector2(29, -31)
## Beta 1.4.0: the knights' camp on the last dry ground at the west end, and
## the road west to Black Water Ridge (thicket and black water until the
## sword's starlight parts it: "ch5:ridge_open").
const CAMP := Vector2(-36, 6)
const CAMP_R := 10.0

var walks: Array = [
	[Vector2(34, 2), Vector2(14, 6), Vector2(2, -6), Vector2(-12.7, -18.9)],
	[Vector2(14, 6), Vector2(-4, 20), Vector2(-26, 34), Vector2(-31, 38)],
	[Vector2(34, 2), Vector2(30, 24), Vector2(34, 42)],
	[Vector2(34, 2), Vector2(32, -14), SPUR_END],
	[Vector2(-4, 20), Vector2(-18, 12), Vector2(-27, 8)],
]


func setup() -> void:
	id = "marsh"
	seed_value = 61
	x_min = -60.0
	x_max = 60.0
	z_min = -65.0
	z_max = 65.0
	rim_height = 11.0
	rim_margin = 8.0
	cliff_col = Color(0.62, 0.6, 0.48)
	rock_col = Color.html("4e4a3a")
	links = [
		{"to": "field", "p": Vector2(60, 0), "d": Vector2(-1, 0), "w": 6.0, "y": 0.4},
		{"to": "black_water_ridge", "p": Vector2(-60, 6), "d": Vector2(1, 0), "w": 4.0, "y": 0.5},
	]
	water = [{"rect": Rect2(-80, -85, 160, 170), "y": WATER_Y, "col": Color(0.36, 0.5, 0.52, 0.72)}]
	mood = {
		"sky_top": Color.html("4a4a60"), "sky_mid": Color.html("707060"), "sky_horizon": Color.html("a0a07e"),
		"cloud": Color.html("8e8c78"), "cloud_amount": 0.75,
		"fog": Color.html("7e846a"), "fog_begin": 8.0, "fog_end": 68.0,
		"ambient": Color.html("5c5c50"), "sun": Color.html("d8d0b0"), "sun_energy": 0.85, "sun_rot": Vector3(-35, -60, 0),
		"fill": Color.html("4a4a5a"),
		"horizon": Color.html("4a5040"), "hill_height": 20.0,
	}


func walk_dist(x: float, z: float) -> float:
	var best := INF
	for pts in walks:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	# Mud islands poking out of shallow water (never deeper than ~0.7 m).
	var n := noise.get_noise_2d(x * 1.8, z * 1.8) + detail.get_noise_2d(x * 0.35, z * 0.35) * 0.35
	var h := n * 3.5 - 0.1
	h = clampf(h, -0.95, 1.0)
	# Dry ground along the entrance and under the hut.
	h = maxf(h, lerpf(-1.0, 0.4, smoothstep(30.0, 38.0, x)))
	h = maxf(h, lerpf(-1.0, 0.5, 1.0 - smoothstep(6.0, 9.0, Vector2(x, z).distance_to(HUT))))
	h = maxf(h, lerpf(-1.0, 0.6, 1.0 - smoothstep(6.0, 10.0, Vector2(x, z).distance_to(Vector2(40, 44)))))
	# The knights' camp: the last dry ground before the west end.
	h = maxf(h, lerpf(-1.0, 0.5, 1.0 - smoothstep(CAMP_R - 2.0, CAMP_R + 2.0, Vector2(x, z).distance_to(CAMP))))
	# The spring's islet in its deep pool.
	var di := Vector2(x, z).distance_to(ISLE)
	if di < ISLE_POOL_R + 3.0:
		h = lerpf(-3.0, h, smoothstep(ISLE_POOL_R - 1.0, ISLE_POOL_R + 3.0, di))
		h = maxf(h, lerpf(-3.0, 0.7, 1.0 - smoothstep(ISLE_R - 1.0, ISLE_R + 1.0, di)))
	# The Bog Tower's islet inside its deep moat.
	var dt := Vector2(x, z).distance_to(TOWER)
	if dt < MOAT_R + 3.0:
		h = lerpf(-3.5, h, smoothstep(MOAT_R - 1.0, MOAT_R + 3.0, dt))
		h = maxf(h, 0.6 * (1.0 - smoothstep(ISLET_R - 1.0, ISLET_R + 1.0, dt)) + (-3.5 * smoothstep(ISLET_R - 1.0, ISLET_R + 1.0, dt)))
	return h


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	return "mud" if h < WATER_Y + 0.6 else super.surface_at(x, z, h, r)


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	if h < WATER_Y - 0.1:
		return pick(r, ["3a3a26", "44402a", "34341e"])
	if h < WATER_Y + 0.25:
		return pick(r, ["5a5232", "64583a"])
	var b := noise.get_noise_2d(x * 5.0, z * 5.0)
	return Color.html("4a5428").lerp(Color.html("6a6a34"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# Boardwalks on stilts (no rails).
	for pts in walks:
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			k.bridge(Vector3(a.x, 0.25, a.y), Vector3(b.x, 0.25, b.y), 2.6, "wood", 0.0, Color(0.7, 0.66, 0.6), "wood", false)
	# The Bog Tower: square, mossy, sealed; its boardwalk stops short of the moat.
	var moss := Color(0.68, 0.82, 0.66)
	var door_yaw: float = k.yaw_of(Vector2(1, 0.4).normalized())
	k.tower(TOWER.x, TOWER.y, 4.8, 22.0, "stone", moss, Color.html("3a5a3a"), door_yaw,
		{"sides": 4, "crenel": true, "roof_h": 0.0, "seal": "open"})
	# The way in: a heavy mossy door facing the broken boardwalk.
	var dd := Vector3(-sin(door_yaw), 0, -cos(door_yaw))
	var ty: float = k.h(TOWER.x, TOWER.y) - 0.3
	var door_pos := Vector3(TOWER.x, ty + 0.3, TOWER.y) + dd * (4.8 * 1.04)
	var frame = k._tmp()
	frame.push(Transform3D(Basis(Vector3.UP, door_yaw), door_pos))
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(sx * 1.3, 1.6, 0.05), Vector3(0.6, 3.2, 0.7), moss)
	frame.box(Vector3(0, 3.45, 0.05), Vector3(3.2, 0.5, 0.75), moss)
	frame.pop()
	k.merge(frame, "stone")
	k.door_link(door_pos - dd * 0.02, door_yaw, 2.0, 3.0, "bog_tower", "from_marsh", Color(0.7, 0.8, 0.62))
	# Out on the little islet, beside the old mooring post in front of the door.
	var side := Vector3(dd.z, 0, -dd.x)
	var out: Vector3 = door_pos + dd * 0.9 + side * 1.0
	k.entrance("from_bog_tower", out.x, out.z, door_yaw)
	var warp: Vector3 = door_pos + dd * 0.9 - side * 1.0
	k.entrance("warp_bog_tower", warp.x, warp.z, door_yaw)
	for i in 3:
		var a := 0.9 + i * 0.45
		k.pillar(TOWER.x + cos(a) * 12.0, TOWER.y + sin(a) * 12.0, 1.2, 0.18, false, "wood", -1.5)
	# The hut on stilts.
	var hut_y := 1.6
	k.platform(HUT.x, HUT.y, Vector2(8.0, 7.0), hut_y, "wood")
	k.house(HUT.x, HUT.y + 0.5, PI, 6.0, 5.0, 3.0, Color(0.8, 0.75, 0.65), Color(0.9, 0.85, 0.7), {"wall": "wood", "roof": "thatch", "y": hut_y + 0.2})
	k.stairs(HUT.x + 3.0, HUT.y - 7.5, PI, 2.0, 4.0, hut_y - k.h(HUT.x + 3.0, HUT.y - 7.5), "wood")
	k.cave_in_cliff(40, 44, Vector2(1, 0.3), 3.0, 3.0, "heavy", "rupee_red")
	# A Spring of Lothelye in the islet's rocks, facing the boardwalk.
	k.spring_cave(ISLE.x, ISLE.y - 1.2, k.yaw_of(Vector2(0, 1)), "spring_lothelye_magic", "", {"mound": true, "y": k.h(ISLE.x, ISLE.y - 1.2) - 0.2, "tint": Color(0.75, 0.75, 0.7)})
	# Dead trees, reeds, lilies, mushrooms, logs.
	for i in 140:
		var x := r.randf_range(x_min + 6, x_max - 6)
		var z := r.randf_range(z_min + 6, z_max - 6)
		if walk_dist(x, z) < 2.6 or in_corridor(x, z) or Vector2(x, z).distance_to(TOWER) < MOAT_R + 2.0 or Vector2(x, z).distance_to(HUT) < 6.0 \
				or Vector2(x, z).distance_to(CAMP) < CAMP_R + 2.0 \
				or Vector2(x, z).distance_to(ISLE) < ISLE_POOL_R + 1.0:
			continue
		var hh := height(x, z)
		match i % 7:
			0, 1:
				k.tree_dead(x, z, r.randf_range(0.8, 1.5))
			2, 3:
				k.reeds(x, z, 6)
			4:
				if hh < WATER_Y:
					k.lily(x, z, WATER_Y)
				else:
					k.mushroom(x, z, r.randf_range(0.6, 1.2), Color.html("b8a060"))
			5:
				k.bush(x, z, r.randf_range(0.6, 1.0), Color(0.7, 0.7, 0.5))
			6:
				if hh > WATER_Y:
					k.log(x, z, r.randf_range(2.5, 5.0), r.randf() * PI, 0.4)
	for i in 30:
		k.lily(TOWER.x + r.randf_range(-14, 14), TOWER.y + r.randf_range(-14, 14), WATER_Y)


## The marsh: octoroks in the channels, snapping plants on the mud islands,
## dry grass, and a sign by the way in.
func populate(k) -> void:
	# Chapter V: black water rising at the marsh's west end, toward the Ridge.
	var bw = k._tmp(false)
	for i in 5:
		bw.prism(Vector3(-46.0 + i * 1.2, k.h(-46.0, -20.0 + i * 9.0) + 0.06, -20.0 + i * 9.0), 4.0, Vector3(-46.0 + i * 1.2, k.h(-46.0, -20.0 + i * 9.0) + 0.08, -20.0 + i * 9.0), 4.4, 12, Color.html("06080a"))
	# The black water over the road west too, until the starlight parts it.
	bw.box(Vector3(-52.0, 0.56, CAMP.y), Vector3(14.0, 0.04, 17.0), Color.html("06080a"))
	k.flag_props("ch5:returned", bw, "char", "ch5:ridge_open")
	k.examine(Vector3(-41.0, k.h(-41.0, -2.0), -2.0), -PI * 0.5, [], "res://scripts/npc/chapter5_lines.gd", "black_water").set("show_flag", "ch5:returned")
	_ridge_road(k)
	_front_camp(k)
	k.signpost(48, 6, Vector2(42, 3), "*West Marshlands*\nKeep to the boardwalks!\n\nThe water round the Bog Tower\nis deeper than it looks.")
	# An old mooring post on the tower's islet, facing the broken boardwalk,
	# with a target the Hookshot can reach from its end (about 10 m off). It
	# stands well back from the islet's edge, so the hero lands on dry ground.
	var dir := Vector2(1, 0.4).normalized()
	var post: Vector2 = TOWER + dir * (ISLET_R - 3.0)
	var py: float = k.h(post.x, post.y)
	k.block(Vector3(post.x, py + 1.5, post.y), Vector3(0.7, 3.0, 0.7), 0.0, "wood", Color(0.7, 0.6, 0.45)).set_meta("no_climb", true)
	var face: Vector2 = post + dir * 0.44
	k.hook_target(Vector3(face.x, py + 2.2, face.y), k.yaw_of(dir))
	# The islet's mooring post, its target facing the end of the boardwalk spur.
	var to_spur: Vector2 = (SPUR_END - ISLE).normalized()
	var ipost: Vector2 = ISLE + to_spur * (ISLE_R - 1.6) + Vector2(-1.4, 0)
	var ipy: float = k.h(ipost.x, ipost.y)
	k.block(Vector3(ipost.x, ipy + 1.5, ipost.y), Vector3(0.7, 3.0, 0.7), 0.0, "wood", Color(0.7, 0.6, 0.45)).set_meta("no_climb", true)
	var iface: Vector2 = ipost + to_spur * 0.44
	k.hook_target(Vector3(iface.x, ipy + 2.2, iface.y), k.yaw_of(to_spur))
	for c in [Vector2(10, 20), Vector2(-5, -45), Vector2(25, -30), Vector2(-20, 44)]:
		var p: Vector2 = Vector2.INF
		for i in 20:
			var q: Vector2 = c + Vector2(k.rng.randf_range(-8, 8), k.rng.randf_range(-8, 8))
			if height(q.x, q.y) < WATER_Y - 0.25 and walk_dist(q.x, q.y) > 3.0 and q.distance_to(TOWER) > MOAT_R + 3.0 and q.distance_to(ISLE) > ISLE_POOL_R + 3.0:
				p = q
				break
		if p != Vector2.INF:
			k.enemy("octorok", p.x, p.y, 0.0, {}, WATER_Y - 0.45)
	for c in [Vector2(20, 35), Vector2(-15, 25), Vector2(30, -10)]:
		k.enemies_near("snapper", c, 10.0, 1, {}, WATER_Y + 0.1)
	for c in [Vector2(35, 10), Vector2(-20, 45), Vector2(15, -20)]:
		k.shrubs_near(c, 6.0, 5, Color(0.85, 0.85, 0.6), WATER_Y + 0.1)
	k.collectible("rupee_red", HUT.x - 2.5, HUT.y - 2.5, 1.65)
	# The fourth treasure chart's X: out behind the hermit's hut.
	var c4: Vector2 = k.spot(HUT + Vector2(-6.0, 6.0), 6.0, 1.2)
	if c4 != Vector2.INF:
		k.dig_spot("chart_4", c4.x, c4.y, TreasureCharts.prize(4))


## The road west: a thicket of dead trees and drowned logs across it (and the
## black water over it from Chapter V), until the starlight parts them all;
## then a causeway of old white stones shows through.
func _ridge_road(k) -> void:
	var t = k._tmp(false)
	var r: RandomNumberGenerator = k.rng
	for i in 14:
		var z := CAMP.y - 8.5 + i * 1.3
		var x := -49.0 + r.randf_range(-0.8, 0.8)
		t.prism(Vector3(x, 0.0, z), 0.22, Vector3(x + r.randf_range(-0.6, 0.6), 3.2 + r.randf_range(0.0, 1.4), z + r.randf_range(-0.5, 0.5)), 0.05, 5, Color.html("3a3026"))
		t.prism(Vector3(x - 1.2, 0.5 + float(i % 3) * 0.6, z - 0.8), 0.16, Vector3(x + 1.2, 0.7 + float(i % 2) * 0.8, z + 0.9), 0.14, 5, Color.html("4a3e30"))
	# Bank to bank, and out over the water either side: an 18 m wall could be
	# waded round at its ends (Beta 1.5.1). The thicket goes out with it.
	for i in 10:
		for side in [-1.0, 1.0]:
			var z: float = CAMP.y + side * (9.5 + i * 0.6)
			var x := -49.0 + r.randf_range(-0.8, 0.8)
			var gy: float = minf(k.h(x, z), 0.0)
			t.prism(Vector3(x, gy, z), 0.2, Vector3(x + r.randf_range(-0.6, 0.6), gy + 3.0 + r.randf_range(0.0, 1.2), z + r.randf_range(-0.5, 0.5)), 0.05, 5, Color.html("3a3026"))
	k.flag_props("", t, "wood", "ch5:ridge_open")
	k.flag_barrier(Vector3(-49.0, 3.0, CAMP.y), Vector3(32.0, 8.0, 1.6), PI * 0.5, "ch5:ridge_open")
	# The marsh's water runs on past both ends of the thicket, so the road is
	# sealed again where its mouth narrows between the rims (Beta 1.5.1).
	k.flag_barrier(Vector3(-55.5, 8.0, CAMP.y), Vector3(24.0, 16.0, 1.6), PI * 0.5, "ch5:ridge_open")
	var c = k._tmp(false)
	for i in 9:
		var x := -44.0 - i * 2.0
		for j in 3:
			c.box(Vector3(x + r.randf_range(-0.3, 0.3), 0.58, CAMP.y - 1.4 + j * 1.4 + r.randf_range(-0.2, 0.2)), Vector3(1.6, 0.14, 1.2), Color.html("d8d4e0").darkened(r.randf_range(0.0, 0.15)))
	k.flag_props("ch5:ridge_open", c, "char")
	k.mark("cs_front_water", Vector3(-51.0, 0.6, CAMP.y))
	k.mark("cs_front_stand", Vector3(-44.5, k.h(-44.5, CAMP.y), CAMP.y))
	k.mark("cs_front_cam", Vector3(-30.0, 3.2, CAMP.y + 9.0))


## The knights' camp (from "ch5:cinder_done"): tents round a fire, Haven's
## banners, the quintain for the Parry, Rowena and her knights.
func _front_camp(k) -> void:
	var need := "ch5:cinder_done"
	var y: float = 0.5
	var blue := Color.html("2a4a92")
	var m = k._tmp(false)
	for t in [[Vector2(-38.0, -1.0), 0.3], [Vector2(-31.5, -0.5), -0.4], [Vector2(-41.0, 12.0), 2.6], [Vector2(-30.0, 13.0), 3.4]]:
		var at: Vector2 = t[0]
		var yaw: float = t[1]
		m.push(Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, y - 0.05, at.y)))
		for sx in [-1.0, 1.0]:
			m.face([Vector3(sx * 1.4, 0, -1.6), Vector3(sx * 1.4, 0, 1.6), Vector3(0, 2.0, 1.6), Vector3(0, 2.0, -1.6)], Color.html("e8e2d4").darkened(0.12 if sx > 0 else 0.0), Vector3(sx * 4.0, 2.0, 0))
		m.face([Vector3(-1.4, 0, 1.6), Vector3(1.4, 0, 1.6), Vector3(0, 2.0, 1.6)], Color.html("c8c2b4"), Vector3(0, 0.8, 5.6))
		m.box(Vector3(0, 1.0, -1.65), Vector3(0.08, 2.0, 0.08), Color.html("5a4630"))
		m.box(Vector3(0, 2.4, -1.65), Vector3(0.04, 0.8, 0.04), Color.html("5a4630"))
		m.box(Vector3(0.22, 2.55, -1.65), Vector3(0.4, 0.3, 0.02), blue)
		m.pop()
		k.flag_barrier(Vector3(at.x, y + 0.7, at.y), Vector3(2.2, 1.4, 2.0), yaw, "", null, "char", need)
	k.flag_props(need, m, "char")
	# The fire, and a ring of stones round it.
	var f = k._tmp(false)
	var fire := CAMP + Vector2(1.0, 5.0)
	for i in 8:
		var a := TAU * i / 8.0
		f.icosa(Vector3(fire.x + cos(a) * 0.8, y + 0.1, fire.y + sin(a) * 0.8), Vector3(0.22, 0.15, 0.22), 0.2, Color.html("6a6660"))
	f.prism(Vector3(fire.x, y, fire.y), 0.4, Vector3(fire.x, y + 0.8, fire.y), 0.0, 5, Color(1.8, 1.0, 0.35))
	k.flag_props(need, f, "glow")
	# Banner poles at the camp's edge.
	var b = k._tmp(false)
	for at in [CAMP + Vector2(-7.0, -6.0), CAMP + Vector2(-7.0, 9.0), CAMP + Vector2(6.0, -7.0)]:
		b.prism(Vector3(at.x, y, at.y), 0.06, Vector3(at.x, y + 3.6, at.y), 0.05, 5, Color.html("5a4630"))
		b.box(Vector3(at.x + 0.45, y + 3.0, at.y), Vector3(0.9, 1.1, 0.03), blue)
		b.box(Vector3(at.x + 0.45, y + 3.0, at.y + 0.02), Vector3(0.3, 0.3, 0.02), Color.html("d8dce4"))
	k.flag_props(need, b, "char")
	# The quintain on the training ground, facing the camp.
	var q := CAMP + Vector2(6.5, 9.0)
	k._dyn("res://scripts/dungeon/quintain.gd", "Quintain", Vector3(q.x, y, q.y), k.yaw_of(Vector2(-0.4, -1).normalized()) + PI, {"flag": "front:parry_done", "need_flag": need}, StaticBody3D.new())
	k.examine(Vector3(q.x + 1.6, y, q.y + 1.2), PI * 0.25, [], "res://scripts/npc/ridge_lines.gd", "quintain").set("show_flag", need)
	k.examine(Vector3(CAMP.x + 4.6, y, CAMP.y - 6.0), PI * 0.85, [], "res://scripts/npc/ridge_lines.gd", "front_board").set("show_flag", need)
	var east: float = k.yaw_of(Vector2(1, 0))
	k.npc("Commander Rowena", "res://assets/models/rowena.tscn", "res://scripts/npc/ridge_lines.gd", CAMP.x - 5.0, CAMP.y + 1.0, east, y, {"show": need})
	k.npc("Quartermaster", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/ridge_lines.gd", CAMP.x + 3.5, CAMP.y - 3.5, k.yaw_of(Vector2(-1, 0.4)), y, {"show": need})
	k.npc("Sir Brannoc", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/ridge_lines.gd", CAMP.x + 2.8, CAMP.y + 7.6, k.yaw_of(Vector2(-0.6, -1)), y, {"show": need})
	k.npc("Dame Elsabet", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/ridge_lines.gd", CAMP.x - 1.5, CAMP.y + 2.0, k.yaw_of(Vector2(0.7, 1)), y, {"show": need})
	k.story_trigger("front_camp", Rect2(CAMP.x + 6.0, CAMP.y - 10.0, 10.0, 20.0), y - 1.0, "ch5:front_seen", need, 5.0)
