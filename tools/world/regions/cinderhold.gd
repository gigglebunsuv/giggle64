extends "res://tools/world/region.gd"
## Cinderhold (Chapter V): Serielye's old volcano, east past the Northeastern
## Cliffs' great stone. Black slopes of ash and obsidian climb to a wide
## plateau round the smoking crater; pools of lava lie in the hollows, the
## sky is red with embers. At the mountain's foot a hot spring steams (the
## Cinderfin swims in it). On the plateau's north side, in a spire of black
## glass, the gate of the CINDER VAULT, where the Gauntlet of Fire was first
## kept. Serielye's broken statue still watches over it.
##
## North is -Z. The road comes in from the cliffs in the west.

const CRATER := Vector2(0, -62)
const PLATEAU_Y := 30.0
const PIT_R := 14.0
const PLATEAU_R := 25.0
const LAVA_Y := 19.5
const SPRING := Vector2(-50, 46)
const SPRING_Y := -0.3
const POOL_A := Vector2(-28, 8)
const POOL_B := Vector2(30, -14)
const GATE := Vector2(0, -86)
## Where the waystone stands (world_kit._auto_waystone): by the spring.
var waystone_at := Vector2(-58, 34)

var paths: Array = [
	[Vector2(-75, 42), Vector2(-56, 38), Vector2(-40, 22), POOL_A + Vector2(0, 8), POOL_A + Vector2(0, -8), Vector2(-24, -16), Vector2(-20, -40)],
	[Vector2(-20, -40), Vector2(-14, -54), Vector2(-10, -76), GATE + Vector2(0, 6)],
]


func setup() -> void:
	id = "cinderhold"
	seed_value = 1303
	x_min = -75.0
	x_max = 75.0
	z_min = -110.0
	z_max = 60.0
	rim_height = 22.0
	rim_margin = 8.0
	cliff_col = Color(0.5, 0.4, 0.38)
	rock_col = Color.html("3a2a26")
	links = [
		{"to": "cliffs", "p": Vector2(-75, 42), "d": Vector2(1, 0), "w": 5.0, "y": 0.5},
	]
	water = [{"rect": Rect2(SPRING.x - 7.0, SPRING.y - 6.0, 14.0, 12.0), "y": SPRING_Y, "col": Color(0.35, 0.72, 0.7, 0.75)}]
	mood = {
		"sky_top": Color.html("2a1012"), "sky_mid": Color.html("6a2a1a"), "sky_horizon": Color.html("c8602a"),
		"cloud": Color.html("3a2420"), "cloud_amount": 0.85,
		"fog": Color.html("6a3a2a"), "fog_begin": 24.0, "fog_end": 140.0,
		"ambient": Color.html("7a4a3a"), "sun": Color.html("ffb070"), "sun_energy": 0.75, "sun_rot": Vector3(-30, 140, 0),
		"fill": Color.html("8a3020"), "fill_energy": 0.5,
		"horizon": Color.html("4a2420"), "hill_height": 24.0, "particles": "embers",
		"far": [
			{"type": "peak", "yaw": 40.0, "w": 90.0, "h": 60.0, "col": Color.html("3a2622")},
			{"type": "peak", "yaw": 160.0, "w": 70.0, "h": 40.0, "col": Color.html("44302a")},
		],
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


## A cone rising to the plateau round the crater, the crater's pit, hollows
## of lava and the hot spring's basin at the foot.
func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var r := p.distance_to(CRATER)
	var h := minf(maxf((100.0 - r) * 0.4, 0.0), PLATEAU_Y)
	h += noise.get_noise_2d(x * 1.1, z * 1.1) * 1.8 * clampf((r - PLATEAU_R) / 20.0, 0.0, 1.0) + detail.get_noise_2d(x * 0.4, z * 0.4) * 0.3
	if r < PIT_R + 1.0:
		h = lerpf(LAVA_Y - 1.5, h, smoothstep(PIT_R - 3.0, PIT_R + 1.0, r))
	for c in [POOL_A, POOL_B]:
		var d := p.distance_to(c)
		if d < 9.0:
			var floor_y := minf(maxf((100.0 - c.distance_to(CRATER)) * 0.4, 0.0), PLATEAU_Y) - 1.6
			h = lerpf(floor_y, h, smoothstep(5.0, 9.0, d))
	var ds := Vector2((x - SPRING.x) / 1.15, z - SPRING.y).length()
	if ds < 10.0:
		h = lerpf(SPRING_Y - 1.3, h, smoothstep(5.5, 10.0, ds))
	# The road worn a little smoother.
	h = lerpf(h * 0.97, h, smoothstep(1.5, 5.0, path_dist(x, z)))
	return h


## Each lava hollow's surface height.
func pool_y(c: Vector2) -> float:
	return minf(maxf((100.0 - c.distance_to(CRATER)) * 0.4, 0.0), PLATEAU_Y) - 1.0


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	var dc := p.distance_to(CRATER)
	if dc < PIT_R:
		return pick(r, ["2a1410", "3a1a12"])
	for c in [POOL_A, POOL_B]:
		if p.distance_to(c) < 6.0:
			return pick(r, ["3a1a12", "2a1410"])
	if Vector2((x - SPRING.x) / 1.15, z - SPRING.y).length() < 7.0 and h < SPRING_Y + 0.4:
		return pick(r, ["4a6a62", "3e5a54"])
	if path_dist(x, z) < 1.8 + r.randf_range(-0.4, 0.4):
		return pick(r, ["5a4a42", "54443c", "62524a"])
	if dc < PLATEAU_R + 1.0:
		var seam := fposmod(x * 0.7 + z * 0.3, 3.0) < 0.12
		if seam:
			return Color.html("8a3018")
		return pick(r, ["2e2624", "342a28", "282220"])
	var b := noise.get_noise_2d(x * 4.0, z * 4.0)
	var ash := Color.html("2e2826").lerp(Color.html("4e423e"), clampf(b + 0.5 + r.randf_range(-0.12, 0.12), 0.0, 1.0))
	if r.randf() < 0.03:
		return Color.html("b04a20")
	return ash


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	if Vector2(x, z).distance_to(CRATER) < PLATEAU_R + 1.0:
		return "stone"
	return super.surface_at(x, z, h, r) if path_dist(x, z) < 2.0 else "ash"


func build(k) -> void:
	k.story_trigger("cinder_arrive", Rect2(-68.0, 34.0, 8.0, 16.0), k.h(-64.0, 42.0) - 1.0, "ch5:cinder_seen", "", 5.0)
	k.mark("cs_cinder_cam", Vector3(-60.0, k.h(-60.0, 40.0) + 3.0, 44.0))
	k.mark("cs_cinder_peak", Vector3(CRATER.x, PLATEAU_Y + 14.0, CRATER.y))
	_crater(k)
	_lava(k, POOL_A, 5.6, pool_y(POOL_A))
	_lava(k, POOL_B, 5.6, pool_y(POOL_B))
	# The road crosses the first hollow on a span of black stone.
	var ya: float = pool_y(POOL_A) + 1.6
	k.bridge(Vector3(POOL_A.x, ya, POOL_A.y + 7.5), Vector3(POOL_A.x, ya, POOL_A.y - 7.5), 3.4, "stone", 0.8, Color(0.35, 0.3, 0.3), "stone")
	# A spire in the second hollow, a chest on top, a hookshot target on its face.
	var yb: float = pool_y(POOL_B)
	k.spire(POOL_B.x, POOL_B.y, 1.8, yb + 6.0 - k.h(POOL_B.x, POOL_B.y), "rock", Color(0.35, 0.28, 0.28), 0.9, 6)
	k.block(Vector3(POOL_B.x, yb + 6.15, POOL_B.y), Vector3(2.6, 0.3, 2.6), 0.0, "stone", Color(0.3, 0.26, 0.26))
	k.chest(POOL_B.x, POOL_B.y, PI * 0.75, "rupee_purple", false, "cinderhold:spire_chest", "", yb + 6.3)
	k.hook_target(Vector3(POOL_B.x - 1.3, yb + 5.4, POOL_B.y + 1.3), PI * 0.75)
	_spring(k)
	_gate(k)
	_scatter(k)


## The crater: a pit of lava inside a ring of black stone, smoke rising.
func _crater(k) -> void:
	var m = k._tmp(false)
	m.prism(Vector3(CRATER.x, LAVA_Y - 0.05, CRATER.y), PIT_R + 0.5, Vector3(CRATER.x, LAVA_Y + 0.05, CRATER.y), PIT_R + 0.5, 20, Color(1.6, 0.6, 0.2))
	k.merge(m, "glow")
	k.void_zone(Vector3(CRATER.x, LAVA_Y - 0.6, CRATER.y), Vector3(PIT_R * 1.9, 1.0, PIT_R * 1.9), 2)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		k.fire(CRATER.x + cos(a) * 7.0, CRATER.y + sin(a) * 7.0, 2.0, LAVA_Y, i % 2 == 0)
	# A low wall of black glass round the pit's lip.
	for i in 24:
		var a := TAU * i / 24.0
		if absf(angle_difference(a, PI * 0.5)) < 0.2:
			continue
		var at := CRATER + Vector2(cos(a), sin(a)) * (PIT_R + 1.6)
		k.rock(at.x, at.y, 0.9 + 0.3 * float(i % 3), "rock", true, Color(0.32, 0.26, 0.26))


## A hollow full of lava: a glowing surface, and a fall into it burns.
func _lava(k, c: Vector2, radius: float, y: float) -> void:
	var m = k._tmp(false)
	m.prism(Vector3(c.x, y - 0.05, c.y), radius, Vector3(c.x, y + 0.05, c.y), radius, 16, Color(1.6, 0.55, 0.18))
	k.merge(m, "glow")
	k.void_zone(Vector3(c.x, y - 0.5, c.y), Vector3(radius * 1.8, 1.0, radius * 1.8), 2)
	k.fire(c.x + 1.5, c.y - 1.0, 1.2, y, true)


## The hot spring at the mountain's foot, steaming.
func _spring(k) -> void:
	for i in 10:
		var a := TAU * i / 10.0
		k.rock(SPRING.x + cos(a) * 8.0, SPRING.y + sin(a) * 7.0, 0.7 + 0.2 * float(i % 3), "rock", true, Color(0.55, 0.5, 0.48))
	var steam := CPUParticles3D.new()
	steam.name = "SpringSteam"
	steam.amount = 60
	steam.lifetime = 4.0
	steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	steam.emission_box_extents = Vector3(5.0, 0.2, 4.5)
	steam.direction = Vector3.UP
	steam.spread = 20.0
	steam.gravity = Vector3(0.1, 0.4, 0)
	steam.initial_velocity_min = 0.3
	steam.initial_velocity_max = 0.8
	steam.scale_amount_min = 0.6
	steam.scale_amount_max = 1.4
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	qm.material = mat
	steam.mesh = qm
	steam.color = Color(0.95, 0.95, 1.0, 0.25)
	steam.position = Vector3(SPRING.x, SPRING_Y + 0.2, SPRING.y)
	k._misc.add_child(steam)
	k.examine(Vector3(SPRING.x + 6.0, k.h(SPRING.x + 6.0, SPRING.y - 6.0), SPRING.y - 6.0), PI * 0.75, [], "res://scripts/npc/chapter5_lines.gd", "hot_spring")


## The Vault's gate in a spire of black glass on the plateau's north side,
## Serielye's broken statue beside it.
func _gate(k) -> void:
	var gy: float = PLATEAU_Y
	var glass := Color(0.22, 0.18, 0.2)
	k.spire(GATE.x - 6.0, GATE.y - 3.0, 3.6, 16.0, "rock", glass, 0.4, 7)
	k.spire(GATE.x + 6.0, GATE.y - 3.0, 3.6, 18.0, "rock", glass, 0.4, 7)
	k.block(Vector3(GATE.x, gy + 4.0, GATE.y - 2.0), Vector3(9.0, 8.0, 3.0), 0.0, "stone", glass)
	var trim = k._tmp(false)
	trim.box(Vector3(GATE.x, gy + 2.0, GATE.y - 0.45), Vector3(3.4, 4.0, 0.1), Color.html("1a0c0a"))
	for sx in [-1.0, 1.0]:
		trim.box(Vector3(GATE.x + sx * 1.9, gy + 2.2, GATE.y - 0.4), Vector3(0.3, 4.4, 0.3), Color.html("b04a20"))
	trim.box(Vector3(GATE.x, gy + 4.5, GATE.y - 0.4), Vector3(4.1, 0.3, 0.3), Color.html("b04a20"))
	k.merge(trim, "glow")
	k.door_link(Vector3(GATE.x, gy, GATE.y - 0.5), PI, 3.0, 4.0, "cinder_vault", "from_cinderhold", Color(0.25, 0.12, 0.1))
	k.entrance("from_cinder_vault", GATE.x, GATE.y + 3.5, PI)
	k.statue(GATE.x + 9.5, GATE.y + 4.0, PI * 1.1, 2.6, "stone", gy)
	k.rubble(GATE.x + 8.0, GATE.y + 6.5, 0.4, 1.2, gy)
	k.signpost(GATE.x - 5.0, GATE.y + 7.0, Vector2(GATE.x - 4.0, GATE.y + 11.0), "*THE CINDER VAULT*\nHere the goddess kept the fire\nthat breaks the world.\n\nLeave it be.")


func _scatter(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for i in 90:
		var x := r.randf_range(x_min + 8, x_max - 8)
		var z := r.randf_range(z_min + 8, z_max - 8)
		var p := Vector2(x, z)
		if in_corridor(x, z, 3.0) or path_dist(x, z) < 4.0 or p.distance_to(CRATER) < PLATEAU_R + 2.0:
			continue
		if p.distance_to(POOL_A) < 10.0 or p.distance_to(POOL_B) < 10.0 or p.distance_to(SPRING) < 11.0:
			continue
		match i % 5:
			0, 1:
				k.rock(x, z, r.randf_range(0.7, 1.8), "rock", true, Color(0.4, 0.32, 0.3))
			2:
				k.spire(x, z, r.randf_range(0.8, 1.6), r.randf_range(3.0, 7.0), "rock", Color(0.26, 0.2, 0.22), 0.5, 6)
			3:
				k.tree_dead(x, z, r.randf_range(0.8, 1.2))
			4:
				if r.randf() < 0.4:
					k.fire(x, z, 0.5, INF, false)


func populate(k) -> void:
	k.examine(Vector3(-60.0, k.h(-60.0, 46.0), 46.0), -PI * 0.5, [], "res://scripts/npc/chapter5_lines.gd", "cinder_sign")
	k.enemies_near("cinderling", POOL_A + Vector2(8, 4), 5.0, 2)
	k.enemies_near("cinderling", POOL_B + Vector2(-8, 6), 6.0, 2)
	k.enemies_near("cinderling", Vector2(-14, -30), 6.0, 2)
	for c in [Vector2(-40, 10), Vector2(10, -20), Vector2(-14, -60)]:
		var p: Vector2 = k.spot(c, 6.0)
		if p != Vector2.INF:
			k.enemy("fire_keese", p.x, p.y, 0.0, {}, k.h(p.x, p.y) + 3.5)
	k.enemies_near("goblin_archer", Vector2(-18, -44), 5.0, 2)
	k.enemies_near("tektite", Vector2(-40, 28), 8.0, 2)
	for c in [Vector2(-48, 30), Vector2(-20, 24), Vector2(12, 4)]:
		k.lift_rocks_near(c, 6.0, 2, Color(0.5, 0.42, 0.4))
	k.collectible("rupee_red", -30.0, -22.0)
	k.pot(-56.0, 36.0, "heart")
	k.pot(-55.0, 36.8, "magic_small")
