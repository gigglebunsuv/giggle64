extends "res://tools/world/region.gd"
## Black Water Ridge (Chapter V, Beta 1.4.0): a dark ridge west of the
## marshes where the undead are strongest. The road climbs from the marsh
## causeway in the east up a canyon of black rock in switchbacks, past three
## shelves, each holding one of MARA's camps (WarCamp, "ridge:camp_1..3"),
## to the plateau at the top where RIDGE KEEP stands with the black falls
## pouring down behind it. Black water falls from the ledges into still
## pools. The Keep's gate is chained shut to the three camps until all are
## broken ("ch5:camps_done"). Haven's knights fight beside the hero at each
## camp (Ally), and hold it once it is freed: a sentry, a clean fire to rest
## by, Haven's banner. At night the dead here are one tier stronger
## (EnemyScale.NIGHT_AREAS).
##
## North is -Z. The marsh is east.

const WATER_COL := Color(0.04, 0.05, 0.08, 0.92)
## The road up, with the height at each point (the ground follows it; away
## from it the canyon walls rise).
const ROAD := [
	[Vector2(78, 40), 0.5], [Vector2(52, 34), 1.5], [Vector2(32, 22), 6.0], [Vector2(18, 14), 6.0],
	[Vector2(-4, 22), 10.0], [Vector2(-28, 10), 15.0], [Vector2(-40, -8), 16.0], [Vector2(-38, -26), 18.5],
	[Vector2(-14, -40), 23.0], [Vector2(14, -52), 26.0], [Vector2(26, -60), 26.0], [Vector2(18, -78), 30.5],
	[Vector2(0, -92), 34.0], [Vector2(-10, -98), 34.0],
]
## The three camps' shelves and the keep's plateau: [center, height, radius].
const CAMPS := [[Vector2(24, 16), 6.0, 11.0], [Vector2(-40, -12), 16.0, 11.0], [Vector2(24, -60), 26.0, 11.0]]
const PLATEAU := Vector2(-6, -98)
const PLATEAU_Y := 34.0
const PLATEAU_R := 16.0
const GATE := Vector2(-6, -112)
## Black pools under the falls: [center, radius, water height].
const POOLS := [[Vector2(46, 10), 7.0, 0.2], [Vector2(-12, -6), 7.0, 9.0], [Vector2(-20, -62), 6.5, 18.5]]
## Where the waystone stands (world_kit._auto_waystone): by the way in.
var waystone_at := Vector2(66, 44)


func setup() -> void:
	id = "black_water_ridge"
	seed_value = 1401
	x_min = -70.0
	x_max = 80.0
	z_min = -130.0
	z_max = 60.0
	rim_height = 26.0
	rim_margin = 8.0
	cliff_col = Color(0.3, 0.3, 0.34)
	rock_col = Color.html("1e1e24")
	links = [
		{"to": "marsh", "p": Vector2(80, 40), "d": Vector2(-1, 0), "w": 4.0, "y": 0.5},
	]
	water = []
	for pl in POOLS:
		var c: Vector2 = pl[0]
		var r: float = pl[1]
		water.append({"rect": Rect2(c.x - r - 1.0, c.y - r - 1.0, r * 2.0 + 2.0, r * 2.0 + 2.0), "y": pl[2], "col": WATER_COL})
	mood = {
		"sky_top": Color.html("141824"), "sky_mid": Color.html("2a3042"), "sky_horizon": Color.html("5e6680"),
		"cloud": Color.html("343846"), "cloud_amount": 0.9,
		"fog": Color.html("404858"), "fog_begin": 34.0, "fog_end": 180.0,
		"ambient": Color.html("6a7088"), "sun": Color.html("c8d0e8"), "sun_energy": 0.8, "sun_rot": Vector3(-40, 60, 0),
		"fill": Color.html("2a3048"), "fill_energy": 0.5,
		"horizon": Color.html("1a1c26"), "hill_height": 30.0,
		"far": [
			{"type": "peak", "yaw": -30.0, "w": 80.0, "h": 70.0, "col": Color.html("16161e")},
			{"type": "peak", "yaw": 200.0, "w": 90.0, "h": 50.0, "col": Color.html("1e1e28")},
		],
	}


## The nearest point of the road: [distance, the road's height there].
func road_at(x: float, z: float) -> Array:
	var p := Vector2(x, z)
	var best := INF
	var hy := 0.0
	for i in ROAD.size() - 1:
		var a: Vector2 = ROAD[i][0]
		var b: Vector2 = ROAD[i + 1][0]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			hy = lerpf(float(ROAD[i][1]), float(ROAD[i + 1][1]), t)
	return [best, hy]


func path_dist(x: float, z: float) -> float:
	return float(road_at(x, z)[0])


## A canyon climbing with the road: the ground is the road's height near it
## and rises into black walls away from it; the shelves and the plateau are
## flat; the pools sink below.
func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var ra := road_at(x, z)
	var d: float = ra[0]
	var h: float = ra[1]
	h += smoothstep(6.0, 18.0, d) * 12.0 + smoothstep(18.0, 40.0, d) * 10.0
	h += noise.get_noise_2d(x * 1.4, z * 1.4) * 2.2 * smoothstep(5.0, 14.0, d) + detail.get_noise_2d(x * 0.5, z * 0.5) * 0.3
	for cp in CAMPS:
		var c: Vector2 = cp[0]
		var dc := p.distance_to(c)
		if dc < float(cp[2]) + 4.0:
			h = lerpf(float(cp[1]), h, smoothstep(float(cp[2]) - 1.0, float(cp[2]) + 4.0, dc))
	var dp := p.distance_to(PLATEAU)
	if dp < PLATEAU_R + 5.0:
		h = lerpf(PLATEAU_Y, h, smoothstep(PLATEAU_R - 1.0, PLATEAU_R + 5.0, dp))
	for pl in POOLS:
		var c: Vector2 = pl[0]
		var dpl := p.distance_to(c)
		var r: float = pl[1]
		if dpl < r + 3.0:
			h = lerpf(float(pl[2]) - 1.6, h, smoothstep(r - 2.0, r + 3.0, dpl))
	return h


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	for pl in POOLS:
		if p.distance_to(pl[0]) < float(pl[1]):
			return pick(r, ["0e1014", "12141a"])
	var d := path_dist(x, z)
	if d < 2.2 + r.randf_range(-0.4, 0.4):
		return pick(r, ["4a4844", "52504a", "44423e"])
	for cp in CAMPS:
		if p.distance_to(cp[0]) < float(cp[2]) - 1.0:
			return pick(r, ["3a3834", "343230", "403c36"])
	if p.distance_to(PLATEAU) < PLATEAU_R:
		var seam := fposmod(x * 0.5, 2.5) < 0.1 or fposmod(z * 0.5, 2.5) < 0.1
		return Color.html("1a1a20") if seam else pick(r, ["2a2a30", "26262c", "2e2e34"])
	var b := noise.get_noise_2d(x * 3.0, z * 3.0)
	var rock := Color.html("1e1e24").lerp(Color.html("34343c"), clampf(b + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))
	if d < 8.0 and r.randf() < 0.25:
		return Color.html("3a4030")
	return rock


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	if Vector2(x, z).distance_to(PLATEAU) < PLATEAU_R:
		return "stone"
	return "dirt" if path_dist(x, z) < 2.4 else "stone"


func build(k) -> void:
	k.story_trigger("ridge_arrive", Rect2(64.0, 32.0, 10.0, 16.0), k.h(68.0, 40.0) - 1.0, "ch5:ridge_reached", "", 5.0)
	k.mark("cs_ridge_cam", Vector3(62.0, k.h(62.0, 40.0) + 3.0, 42.0))
	k.mark("cs_ridge_keep", Vector3(GATE.x, PLATEAU_Y + 12.0, GATE.y))
	k.mark("cs_ridge_gate", Vector3(GATE.x, PLATEAU_Y, GATE.y + 2.0))
	_rift(k)
	_falls(k)
	_keep(k)
	for i in CAMPS.size():
		_camp(k, i)
	_scatter(k)


## Black falls from the ledges into the pools, and the great falls behind the
## Keep.
func _falls(k) -> void:
	# Black water with a slate sheen, so it reads against the night.
	var black := Color(0.16, 0.18, 0.26, 0.9)
	for pl in POOLS:
		var c: Vector2 = pl[0]
		var wy: float = pl[2]
		var top := Vector3(c.x, wy + 9.0, c.y - float(pl[1]) - 0.5)
		k.waterfall(top, 4.0, 9.0, Vector2(0, 1), black)
		k.examine(Vector3(c.x + float(pl[1]) * 0.7, k.h(c.x + float(pl[1]) * 0.7, c.y + float(pl[1]) * 0.7), c.y + float(pl[1]) * 0.7), PI * 0.75, [], "res://scripts/npc/ridge_lines.gd", "black_falls")
	for sx in [-1.0, 1.0]:
		k.waterfall(Vector3(GATE.x + sx * 16.0, PLATEAU_Y + 30.0, GATE.y - 6.0), 7.0, 30.0, Vector2(0, 1), black)


## Ridge Keep: a black fortress on the plateau, its gate chained to the
## three camps until they fall.
func _keep(k) -> void:
	var y: float = PLATEAU_Y
	var stone := Color(0.22, 0.22, 0.26)
	k.block(Vector3(GATE.x, y + 7.0, GATE.y - 7.0), Vector3(22.0, 14.0, 12.0), 0.0, "stone", stone)
	for sx in [-1.0, 1.0]:
		k.tower(GATE.x + sx * 12.5, GATE.y - 4.0, 3.4, 22.0, "stone", stone, Color.html("2a1a22"), 0.0, {"sides": 6, "crenel": true, "roof_h": 4.0, "seal": "solid"})
	var trim = k._tmp(false)
	trim.box(Vector3(GATE.x, y + 2.4, GATE.y - 0.95), Vector3(4.2, 4.8, 0.1), Color.html("0a0a0e"))
	trim.box(Vector3(GATE.x, y + 5.2, GATE.y - 0.9), Vector3(5.4, 0.6, 0.4), Color.html("3a3640"))
	k.merge(trim, "stone")
	k.door_link(Vector3(GATE.x, y, GATE.y - 0.98), PI, 3.0, 4.6, "ridge_keep", "from_black_water_ridge", Color(0.2, 0.18, 0.22),
		"ch5:camps_done", "", "Three great chains hold the Keep's gate shut. Each runs down the slope to one of Mara's camps.")
	k.entrance("from_ridge_keep", GATE.x, GATE.y + 3.5, PI)
	k.entrance("warp_ridge_keep", GATE.x + 2.0, GATE.y + 5.0, PI)
	# The three chains from the gate down the slope, until the camps fall.
	var ch = k._tmp(false)
	for i in 3:
		var a := -0.5 + i * 0.5
		var to := Vector3(GATE.x + sin(a) * 14.0, y + 0.3, GATE.y + cos(a) * 14.0)
		var from := Vector3(GATE.x + sin(a) * 1.6, y + 3.4, GATE.y - 0.6)
		for j in 14:
			var t := float(j) / 13.0
			var pnt := from.lerp(to, t) + Vector3(0, -sin(t * PI) * 0.8, 0)
			ch.icosa(pnt, Vector3(0.16, 0.16, 0.16), 0.0, Color.html("4a4a52"))
	k.flag_props("", ch, "stone", "ch5:camps_done")
	k.examine(Vector3(GATE.x - 4.0, y, GATE.y + 4.5), PI, [], "res://scripts/npc/ridge_lines.gd", "keep_gate")


## Mara's camp `i`: a bone fire burning green, tents of rotten hide, her
## banner; undead round it (the WarCamp counts them); two knights of Haven
## at its edge. Freed: Haven's banner, a sentry, a clean fire to rest by.
func _camp(k, i: int) -> void:
	var c: Vector2 = CAMPS[i][0]
	var y: float = CAMPS[i][1]
	var flag := "ridge:camp_%d" % (i + 1)
	k.war_camp(flag, c.x, c.y, 11.0).set("ridge", true)
	for t in 3:
		var a := TAU * t / 3.0 + 0.6 + i
		var at := c + Vector2(cos(a), sin(a)) * 6.5
		k.tent(at.x, at.y, a + PI * 0.5, 2.6, 3.0, 1.9, Color.html("4a4036"), y)
	# The bone fire: a heap of bones and a green flame, out once the camp is broken.
	var bones = k._tmp(false)
	for j in 10:
		var a := TAU * j / 10.0
		bones.prism(Vector3(c.x + cos(a) * 0.9, y, c.y + sin(a) * 0.9), 0.07, Vector3(c.x + cos(a) * 0.2, y + 0.9, c.y + sin(a) * 0.2), 0.05, 5, Color.html("d8d0b8"))
	k.merge(bones, "char")
	var green = k._tmp(false)
	green.prism(Vector3(c.x, y + 0.2, c.y), 0.55, Vector3(c.x, y + 1.6, c.y), 0.0, 5, Color(0.5, 1.8, 0.7))
	k.flag_props("", green, "glow", flag)
	var clean = k._tmp(false)
	clean.prism(Vector3(c.x, y + 0.2, c.y), 0.4, Vector3(c.x, y + 1.0, c.y), 0.0, 5, Color(1.8, 1.1, 0.4))
	k.flag_props(flag, clean, "glow")
	k.examine(Vector3(c.x + 1.6, y, c.y + 1.6), PI * 0.75, [], "res://scripts/npc/ridge_lines.gd", "rest_fire").set("show_flag", flag)
	# Mara's banner until it falls; Haven's after.
	var mb = k._tmp(false)
	var bp := c + Vector2(-3.0, -3.0)
	mb.prism(Vector3(bp.x, y, bp.y), 0.07, Vector3(bp.x, y + 4.2, bp.y), 0.05, 5, Color.html("1a161c"))
	mb.box(Vector3(bp.x + 0.5, y + 3.4, bp.y), Vector3(1.0, 1.6, 0.03), Color.html("6a1420"))
	mb.box(Vector3(bp.x + 0.5, y + 3.4, bp.y + 0.02), Vector3(0.12, 1.0, 0.02), Color.html("d8d0b8"))
	k.flag_props("", mb, "char", flag)
	var hb = k._tmp(false)
	hb.prism(Vector3(bp.x, y, bp.y), 0.07, Vector3(bp.x, y + 4.2, bp.y), 0.05, 5, Color.html("5a4630"))
	hb.box(Vector3(bp.x + 0.5, y + 3.4, bp.y), Vector3(1.0, 1.6, 0.03), Color.html("2a4a92"))
	hb.box(Vector3(bp.x + 0.5, y + 3.4, bp.y + 0.02), Vector3(0.4, 0.4, 0.02), Color.html("d8dce4"))
	k.flag_props(flag, hb, "char")
	k.npc("Camp Sentry", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/ridge_lines.gd", c.x - 2.0, c.y + 3.5, PI * 0.25, y, {"show": flag})
	if i == 0:
		k.npc("Commander Rowena", "res://assets/models/rowena.tscn", "res://scripts/npc/ridge_lines.gd", c.x + 3.0, c.y + 4.0, -PI * 0.3, y, {"show": flag})
	# Two knights of Haven at the camp's edge (Ally), toward the road.
	for s in [-1.0, 1.0]:
		var at := c + Vector2(s * 3.0, 9.0)
		k._dyn("res://scripts/npc/ally.gd", "AllyKnight", Vector3(at.x, y, at.y), 0.0,
			{"model_scene": "res://assets/models/haven_soldier.tscn", "hero_sword": "red", "camp_flag": flag, "leash": 13.0}, Node3D.new())
	k.pot(c.x + 7.5, c.y - 3.0, "heart", false, y)
	k.pot(c.x + 8.2, c.y - 2.0, "arrows_5", false, y)


func _scatter(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for i in 110:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		var p := Vector2(x, z)
		if in_corridor(x, z, 3.0) or path_dist(x, z) < 4.5 or p.distance_to(PLATEAU) < PLATEAU_R + 3.0:
			continue
		var skip := false
		for cp in CAMPS:
			if p.distance_to(cp[0]) < float(cp[2]) + 2.0:
				skip = true
		for pl in POOLS:
			if p.distance_to(pl[0]) < float(pl[1]) + 2.0:
				skip = true
		if skip:
			continue
		match i % 6:
			0, 1:
				k.rock(x, z, r.randf_range(0.8, 2.0), "rock", true, Color(0.24, 0.24, 0.28))
			2, 3:
				k.spire(x, z, r.randf_range(0.8, 1.6), r.randf_range(3.0, 8.0), "rock", Color(0.18, 0.18, 0.22), 0.5, 6)
			4:
				k.tree_dead(x, z, r.randf_range(0.8, 1.3))
			5:
				k.reeds(x, z, 4)


## Mara's camps' dead (the WarCamp gathers those within its radius), and the
## Ridge's wanderers between them.
func populate(k) -> void:
	var foes := [
		[["stalfos", 2], ["barrow_knight", 1]],
		[["stalfos", 2], ["barrow_knight", 2]],
		[["stalfos", 2], ["barrow_knight", 2], ["keese", 1]],
	]
	for i in CAMPS.size():
		var c: Vector2 = CAMPS[i][0]
		var y: float = CAMPS[i][1]
		for f in foes[i]:
			for n in int(f[1]):
				var a: float = k.rng.randf() * TAU
				var at: Vector2 = c + Vector2(cos(a), sin(a)) * k.rng.randf_range(2.5, 6.0)
				k.enemy(f[0], at.x, at.y, a, {}, y + (2.5 if f[0] == "keese" else 0.0))
	for c in [Vector2(40, 30), Vector2(0, 18), Vector2(-36, -32), Vector2(2, -46), Vector2(20, -78)]:
		k.enemies_near("keese", c, 4.0, 1)
	k.collectible("rupee_red", -26.0, 8.0)
	k.pot(68.0, 44.0, "heart")
	k.pot(69.0, 45.0, "magic_small")
	k.pot(-2.0, -94.0, "heart", false, PLATEAU_Y)
	k.pot(-10.0, -94.0, "arrows_5", false, PLATEAU_Y)


## Beta 1.5.0: the crack in the sky over the falls (from Mara's fall until
## Firebuns' end), Rowena's news on the plateau, and the mouth of the Astral
## Rift that the cracked Seal opens beside the Keep ("ch5:rift_open").
func _rift(k) -> void:
	var y: float = PLATEAU_Y
	var crack := Vector3(GATE.x, y + 62.0, GATE.y - 40.0)
	k.mark("cs_ridge_crack", crack)
	k.story_trigger("rift_seen", Rect2(GATE.x - 7.0, GATE.y + 2.0, 14.0, 10.0), y - 1.0, "ch5:rift_seen", "ch5:mara_done", 4.0)
	# The crack: a long jagged split of starless black, rimmed in violet.
	var rim = k._tmp(false)
	rim.shade_jitter = 0.0
	var core = k._tmp(false)
	core.shade_jitter = 0.0
	var pts: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 1505
	for i in 9:
		pts.append(crack + Vector3(-34.0 + i * 8.5, r.randf_range(-5.0, 5.0), r.randf_range(-2.0, 2.0)))
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var w := 1.5 + 3.0 * sin(PI * (i + 0.5) / (pts.size() - 1))
		core.face_dir([a + Vector3(0, -w * 0.6, 0), b + Vector3(0, -w * 0.6, 0), b + Vector3(0, w * 0.6, 0), a + Vector3(0, w * 0.6, 0)], Color(0.01, 0.0, 0.03), Vector3(0, 0, 1))
		rim.face_dir([a + Vector3(0, -w, -0.3), b + Vector3(0, -w, -0.3), b + Vector3(0, w, -0.3), a + Vector3(0, w, -0.3)], Color(0.62, 0.5, 1.0), Vector3(0, 0, 1))
	k.flag_props("ch5:mara_done", core, "char", "ch5:firebuns_end")
	k.flag_props("ch5:mara_done", rim, "glow", "ch5:firebuns_end")
	# The Rift's mouth, east on the plateau: a tall doorway of dark edged in
	# violet light, under a falling beam of starless light.
	var mouth := PLATEAU + Vector2(10.0, 4.0)
	var my: float = y
	k.mark("cs_rift_mouth", Vector3(mouth.x, my, mouth.y))
	k.story_trigger("rift_open", Rect2(mouth.x - 9.0, mouth.y - 6.0, 12.0, 12.0), my - 1.0, "ch5:rift_open", "ch5:dream", 4.0)
	var frame = k._tmp(false)
	frame.shade_jitter = 0.0
	var dark = k._tmp(false)
	dark.shade_jitter = 0.0
	var yaw := -PI * 0.5
	var bs := Basis(Vector3.UP, yaw)
	var ctr := Vector3(mouth.x, my, mouth.y)
	for i in 10:
		var a0 := PI * i / 10.0
		var a1 := PI * (i + 1) / 10.0
		var p0 := ctr + bs * Vector3(cos(a0) * 1.8, 2.2 + sin(a0) * 2.4, 0)
		var p1 := ctr + bs * Vector3(cos(a1) * 1.8, 2.2 + sin(a1) * 2.4, 0)
		frame.prism(p0, 0.16, p1, 0.16, 5, Color(0.7, 0.58, 1.0))
	for sx in [-1.0, 1.0]:
		frame.prism(ctr + bs * Vector3(sx * 1.8, 0.0, 0), 0.16, ctr + bs * Vector3(sx * 1.8, 2.2, 0), 0.16, 5, Color(0.7, 0.58, 1.0))
	dark.face_dir([ctr + bs * Vector3(-1.7, 0.02, 0), ctr + bs * Vector3(1.7, 0.02, 0), ctr + bs * Vector3(1.7, 2.3, 0), ctr + bs * Vector3(-1.7, 2.3, 0)], Color(0.02, 0.0, 0.05), bs * Vector3(0, 0, 1))
	dark.face_dir([ctr + bs * Vector3(1.7, 0.02, 0), ctr + bs * Vector3(-1.7, 0.02, 0), ctr + bs * Vector3(-1.7, 2.3, 0), ctr + bs * Vector3(1.7, 2.3, 0)], Color(0.02, 0.0, 0.05), bs * Vector3(0, 0, -1))
	# The falling beam of starless light: see-through (the shadow material).
	var beam = k._tmp(false)
	beam.shade_jitter = 0.0
	beam.prism(ctr + Vector3(0, 0.5, 0), 1.2, ctr + Vector3(0, 60.0, 0), 1.6, 10, Color(0.55, 0.45, 0.9, 0.16))
	k.flag_props("ch5:rift_open", frame, "glow", "ch5:firebuns_end")
	k.flag_props("ch5:rift_open", beam, "shadow", "ch5:firebuns_end")
	k.flag_props("ch5:rift_open", dark, "char", "ch5:firebuns_end")
	k.area_exit(ctr + Vector3(0, 1.5, 0), yaw, Vector3(3.0, 3.0, 0.6), "astral_rift", "from_black_water_ridge")
	var ex: Node = k._exits.get_child(k._exits.get_child_count() - 1)
	ex.set("need_flag", "ch5:rift_open")
	ex.set("hide_flag", "ch5:firebuns_end")
	k.entrance("from_astral_rift", mouth.x - 3.0, mouth.y, -yaw)
