extends "res://tools/world/region.gd"
## Frostpeak: the snowfield at the top of the Northeastern Cliffs. Drifts and
## snow-laden pines under an overcast sky, a frozen lake, ice spires, a lone
## mountain hut (Hilde's: she sells the Frost Mantle), a frozen waterfall
## sealing the way into Frostpeak Hollow (the Iron Mallet breaks the ice), and
## the gatehouse of Skyreach Spire on its platform to the north, the spire's
## shaft rising behind it.

const LAKE := Vector2(-16, -2)
const LAKE_R := 19.0
const ICE_Y := 0.6
const SHRINE := Vector2(6, -40)
const SHRINE_Y := 4.2
const HUT := Vector2(30, 28)

var paths: Array = [[Vector2(0, 65), Vector2(4, 30), Vector2(10, 4), Vector2(6, -27)], [Vector2(4, 30), Vector2(26, 26)]]


func setup() -> void:
	id = "snow"
	seed_value = 101
	x_min = -60.0
	x_max = 60.0
	z_min = -60.0
	z_max = 60.0
	rim_height = 32.0
	rim_margin = 8.0
	rim_run = 7.0
	cliff_col = Color(0.82, 0.86, 0.95)
	rock_col = Color.html("7a808e")
	links = [{"to": "cliffs", "p": Vector2(0, 60), "d": Vector2(0, -1), "w": 6.0, "y": 1.0}]
	mood = {
		"sky_top": Color.html("98a6c0"), "sky_mid": Color.html("bcc6d8"), "sky_horizon": Color.html("e6eaf2"),
		"cloud": Color.html("f2f4fa"), "cloud_amount": 0.85,
		"fog": Color.html("dce2ee"), "fog_begin": 12.0, "fog_end": 85.0,
		"ambient": Color.html("8a90a2"), "sun": Color.html("f0f4ff"), "sun_energy": 0.85, "sun_rot": Vector3(-55, 30, 0),
		"fill": Color.html("7a8aaa"),
		"horizon": Color.html("aab4c6"), "hill_height": 45.0, "particles": "snow",
	}


func path_dist(x: float, z: float) -> float:
	var best := INF
	for pts in paths:
		best = minf(best, poly_dist(Vector2(x, z), pts))
	return best


func base_height(x: float, z: float) -> float:
	var h := 1.0 + noise.get_noise_2d(x * 1.5, z * 1.5) * 3.0 + bump(x, z, Vector2(-38, 30), 16.0) * 4.0
	h = maxf(h, 0.8)
	h = lerpf(h * 0.4 + 0.6, h, smoothstep(2.0, 8.0, path_dist(x, z)))
	var d := Vector2(x, z).distance_to(LAKE)
	h = lerpf(ICE_Y, h, smoothstep(LAKE_R - 1.0, LAKE_R + 5.0, d))
	h = lerpf(h, 1.0, 1.0 - smoothstep(12.0, 16.0, Vector2(x, z).distance_to(SHRINE)))
	return h


func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	return "ice" if Vector2(x, z).distance_to(LAKE) < LAKE_R else "snow"


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var d := Vector2(x, z).distance_to(LAKE)
	if d < LAKE_R:
		# Ice with darker cracks.
		var crack := absf(noise.get_noise_2d(x * 6.0, z * 6.0)) < 0.03
		return Color.html("7aa4c4") if crack else pick(r, ["a8cce4", "b4d6ec", "c0dff2"])
	if path_dist(x, z) < 1.8 + r.randf_range(-0.4, 0.4):
		return pick(r, ["c8ccd6", "d0d4de"])
	var b := noise.get_noise_2d(x * 3.0, z * 3.0)
	return Color.html("dfe5f0").lerp(Color.html("f8faff"), clampf(b + 0.5 + r.randf_range(-0.1, 0.1), 0.0, 1.0))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	var ice_stone := Color(0.84, 0.9, 1.0)
	# Skyreach Spire's gatehouse on its platform, reached by steps from the south.
	k.platform(SHRINE.x, SHRINE.y, Vector2(22.0, 16.0), SHRINE_Y, "stone", ice_stone)
	k.stairs(SHRINE.x, SHRINE.y + 8.0 + 6.0, 0.0, 6.0, 6.0, SHRINE_Y - k.h(SHRINE.x, SHRINE.y + 14.0) + 0.05, "stone")
	k.house(SHRINE.x, SHRINE.y - 2.0, 0.0, 14.0, 9.0, 7.0, ice_stone, Color(1, 1, 1), {"wall": "stone", "roof": "snow", "door": false, "y": SHRINE_Y, "roof_h": 3.5})
	# The way into Skyreach Spire, whose shaft rises behind the gatehouse.
	k.tower(SHRINE.x, SHRINE.y - 12.0, 6.0, 46.0, "stone", ice_stone, Color.html("a8c8f0"), PI, {"sides": 10, "crenel": true, "roof_h": 12.0, "y": SHRINE_Y, "seal": "open"})
	var frame = k._tmp()
	for sx in [-1.0, 1.0]:
		frame.box(Vector3(SHRINE.x + sx * 1.35, SHRINE_Y + 1.7, SHRINE.y + 2.6), Vector3(0.5, 3.4, 0.6), ice_stone * Color(0.9, 0.95, 1.0))
	frame.box(Vector3(SHRINE.x, SHRINE_Y + 3.6, SHRINE.y + 2.6), Vector3(3.2, 0.5, 0.65), ice_stone * Color(0.9, 0.95, 1.0))
	k.merge(frame, "stone")
	k.door_link(Vector3(SHRINE.x, SHRINE_Y, SHRINE.y + 2.62), PI, 2.0, 3.0, "skyreach_spire", "from_snow", Color(0.85, 0.92, 1.0))
	k.entrance("from_skyreach_spire", SHRINE.x, SHRINE.y + 5.0, PI)
	k.entrance("warp_skyreach_spire", SHRINE.x + 1.5, SHRINE.y + 5.2, PI)
	for sx in [-5.5, -3.0, 3.0, 5.5]:
		k.pillar(SHRINE.x + sx, SHRINE.y + 4.5, 6.0, 0.45, false, "stone", SHRINE_Y)
	k.brazier(SHRINE.x - 8.5, SHRINE.y + 6.0, false, SHRINE_Y)
	k.brazier(SHRINE.x + 8.5, SHRINE.y + 6.0, false, SHRINE_Y)
	# An ice pillar off the gatehouse platform's east side, too sheer to climb
	# and too far to leap: gliding there in the Wind Boots wins its Piece of Heart.
	k.block(Vector3(SHRINE.x + 20.0, -0.4, SHRINE.y), Vector3(2.6, 5.2, 2.6), 0.0, "ice", Color(0.85, 0.95, 1.0)).set_meta("no_climb", true)
	k.heart_piece(SHRINE.x + 20.0, SHRINE.y, "snow:pillar_heart", 2.2)
	# The mountain hut.
	k.house(HUT.x, HUT.y, -PI * 0.5, 6.0, 5.0, 3.0, Color(0.85, 0.8, 0.75), Color(1, 1, 1), {"wall": "wood", "roof": "snow", "chimney": true})
	for i in 3:
		k.crate(HUT.x - 4.0, HUT.y - 2.0 + i * 1.1, 0.2 * i, 0.9)
	# A frozen waterfall in the east wall, frozen solid over a cave mouth: the
	# way into Frostpeak Hollow. The Iron Mallet shatters the ice.
	var fw: Vector3 = k.cliff_spot(30, -10, Vector2(1, 0), 4.0)
	k.block(fw + Vector3(1.2, 9.0, 0), Vector3(1.6, 8.0, 6.0), 0.0, "ice", Color(0.85, 0.95, 1.0))
	# (The way in stays shut until the ice is broken: the sheet once left a
	# gap at its side, found by the 1.5.0 audit.)
	k.spring_cave(fw.x, fw.z, k.yaw_of(Vector2(-1, 0)), "frostpeak_hollow", "", {"tint": Color(0.85, 0.92, 1.05), "w": 3.4, "h": 4.0, "need_flag": "snow:falls_broken"})
	k.ice_sheet(fw.x - 1.1, fw.z, k.yaw_of(Vector2(-1, 0)), "snow:falls_broken", Vector3(6.2, 5.0, 0.9))
	k.entrance("warp_frostpeak_hollow", fw.x - 4.0, fw.z + 1.5, k.yaw_of(Vector2(-1, 0)))
	k.rock(fw.x - 2.0, fw.z + 4.0, 1.2, "ice", true, Color(0.85, 0.95, 1.0))
	# Ice spires around the lake.
	for i in 9:
		var a := TAU * i / 9.0 + r.randf() * 0.3
		k.spire(LAKE.x + cos(a) * (LAKE_R + 3.0), LAKE.y + sin(a) * (LAKE_R + 3.0), r.randf_range(0.6, 1.2), r.randf_range(2.5, 5.5), "ice", Color(0.8, 0.92, 1.0), 0.2, 5)
	k.cave_in_cliff(-30, 30, Vector2(-1, 0), 3.2, 3.2, "bomb", "rupee_purple")
	# Chapter V's old-world secret: a cave frozen shut in rime-ice (the Ember Rod).
	k.cave_in_cliff(30, -20, Vector2(1, 0), 3.2, 3.2, "rime", "nut_pouch_up")
	# Snow-laden pines, rocks and drifts.
	for i in 120:
		var x := r.randf_range(x_min + 6, x_max - 6)
		var z := r.randf_range(z_min + 6, z_max - 6)
		if path_dist(x, z) < 3.5 or in_corridor(x, z, 3.0) or Vector2(x, z).distance_to(LAKE) < LAKE_R + 4.0 \
				or Rect2(SHRINE.x - 13, SHRINE.y - 10, 26, 30).has_point(Vector2(x, z)) or Vector2(x, z).distance_to(HUT) < 7.0:
			continue
		match i % 4:
			0, 1:
				k.tree_pine(x, z, r.randf_range(0.9, 1.6), true)
			2:
				k.rock(x, z, r.randf_range(0.6, 1.5), "rock", true, Color(0.85, 0.88, 0.95))
			3:
				k.rock(x, z, r.randf_range(0.8, 1.8), "snow", false)


## Frostpeak: blue tektites on the snowfields, frosted grass by the hut, pots
## and a sign at the shrine steps.
func populate(k) -> void:
	k.signpost(SHRINE.x - 5.0, SHRINE.y + 15.0, SHRINE + Vector2(0, 22), "*Skyreach Spire*\nUp top, the wind can blow a knight right off his feet.")
	# Hilde at her hut's door, selling warm clothes.
	k.npc("Hilde", "res://assets/models/hilde.tscn", "res://scripts/npc/hilde_lines.gd", HUT.x - 3.6, HUT.y - 0.2, k.yaw_of(Vector2(-1, 0)))
	k.signpost(HUT.x - 6.0, HUT.y + 3.0, HUT + Vector2(-12, 4), "*Hilde's Hut*\nWarm clothes for cold fools.\n\nFrostpeak Hollow is east, behind the frozen falls. Don't.")
	k.enemies_near("tektite_blue", Vector2(30, 0), 14.0, 2)
	k.enemies_near("tektite_blue", Vector2(-30, 40), 12.0, 1)
	for p in [Vector2(HUT.x - 4.0, HUT.y + 2.0), Vector2(HUT.x - 4.6, HUT.y + 2.9)]:
		k.pot(p.x, p.y)
	for c in [HUT + Vector2(-6, -6), Vector2(20, 45), Vector2(-40, -20)]:
		k.shrubs_near(c, 5.0, 4, Color(0.85, 0.95, 1.1))
		k.lift_rocks_near(c, 6.0, 1, Color(0.9, 0.97, 1.1))
	k.collectible("rupee_blue", LAKE.x, LAKE.y, ICE_Y + 0.05)
	# The fifth treasure chart's X: by Hilde's hut, in the deep drift.
	var c5: Vector2 = k.spot(HUT + Vector2(6.0, 5.0), 6.0, 1.2)
	if c5 != Vector2.INF:
		k.dig_spot("chart_5", c5.x, c5.y, TreasureCharts.prize(5), {"soil": "snow"})
