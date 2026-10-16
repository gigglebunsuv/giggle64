extends "res://tools/world/region.gd"
## A Goddess Spring (after OoT's Great Fairy Fountains): a round cave at the
## end of a short tunnel, a shining pool at its far end, stone steps down to
## the water and the goddess's mark set in the floor before it. Praying on the
## mark (A, "PRAY") calls the spring's keeper up out of the water: one of the
## three goddesses, who gives her blessing, or Lothelye, who gives a lasting
## gift. Fairies drift over the pool (a bottle catches them).
##
## Each spring is a small region file setting `keeper`, `gift`, `host` (the
## area outside) and calling `theme()`; this script builds the cave.

## The chamber's radius and the pool (center, radius, water height).
const R_CAVE := 11.0
const POOL := Vector2(0, -3.5)
const POOL_R := 4.6
const POOL_Y := -0.25
const MARK := Vector2(0, 2.6)
const TUNNEL_W := 1.9

## "alan", "aphiel", "serielye" or "lothelye".
var keeper := "alan"
## What praying here gives (a GetItem id).
var gift := ""
## The area the tunnel leads back out to.
var host := ""
## The look: stone, glow, flowers and motes (see theme()).
var stone := Color(0.8, 0.8, 0.8)
var glow := Color(1, 1, 1)
var water_col := Color(0.6, 0.85, 1.0, 0.7)
var floor_cols: Array = ["8a8a8a", "949494"]
var accent: Array = ["f0f0ff"]


## Sets the cave's colors and mood for `kind` (the keeper, or "lothelye").
func theme(kind: String) -> void:
	var m := {
		"cloud_amount": 0.0, "hill_height": 0.0, "fog_begin": 14.0, "fog_end": 46.0,
		"sun_rot": Vector3(-75, 20, 0), "sun_energy": 0.7, "fill_energy": 0.4,
	}
	match kind:
		"alan":
			stone = Color(0.62, 0.78, 0.56)
			glow = Color.html("c8ff9a")
			water_col = Color(0.5, 0.9, 0.6, 0.72)
			floor_cols = ["4a6a3a", "547444", "5e7e48"]
			accent = ["f8e070", "f0f0ff", "ffa0c0"]
			m.merge({"fog": Color.html("16261a"), "ambient": Color.html("6a8a5a"), "sun": Color.html("fff0b0"), "fill": Color.html("4a7a4a"), "particles": "motes"})
		"aphiel":
			stone = Color(0.78, 0.86, 1.0)
			glow = Color.html("bfe4ff")
			water_col = Color(0.55, 0.8, 1.0, 0.68)
			floor_cols = ["9aa8bc", "a6b4c8", "b0bed2"]
			accent = ["ffffff", "c8e8ff", "a0c8ff"]
			m.merge({"fog": Color.html("1a2436"), "ambient": Color.html("7a8aa8"), "sun": Color.html("f0f8ff"), "fill": Color.html("6a8ac0"), "particles": "motes"})
		"serielye":
			stone = Color(0.55, 0.42, 0.42)
			glow = Color.html("ff8a5a")
			water_col = Color(1.0, 0.5, 0.35, 0.7)
			floor_cols = ["3a2a2a", "443030", "4e3634"]
			accent = ["ff6a3a", "ffb050", "ff4a4a"]
			m.merge({"fog": Color.html("1e0c0a"), "ambient": Color.html("7a4a42"), "sun": Color.html("ffc8a0"), "fill": Color.html("8a3a3a"), "particles": "embers"})
		_:
			stone = Color(0.78, 0.72, 0.95)
			glow = Color.html("f0e0ff")
			water_col = Color(0.75, 0.68, 1.0, 0.7)
			floor_cols = ["6a6488", "746e94", "7e78a0"]
			accent = ["fff4c0", "f0e8ff", "c8b8ff"]
			m.merge({"fog": Color.html("120e22"), "ambient": Color.html("7a72a0"), "sun": Color.html("fff4e0"), "fill": Color.html("6a5aa8"), "particles": "motes"})
	for key in ["sky_top", "sky_mid", "sky_horizon", "cloud", "horizon"]:
		m[key] = m.fog
	mood = m
	cliff_col = stone
	rock_col = stone.darkened(0.3)


func spring_setup() -> void:
	interior = true
	x_min = -16.0
	x_max = 16.0
	z_min = -16.0
	z_max = 20.0
	outer = 4.0
	cell = 1.0
	tex_size = 256
	rim_height = 0.0
	links = [{"to": host, "p": Vector2(0, z_max), "d": Vector2(0, -1), "w": TUNNEL_W, "y": 0.0, "corridor": false, "spawn": 5.0}]
	water = [{"rect": Rect2(POOL.x - POOL_R - 1.0, POOL.y - POOL_R - 1.0, POOL_R * 2 + 2.0, POOL_R * 2 + 2.0), "y": POOL_Y, "col": water_col}]


## Round chamber walls rising steeply all round, the tunnel cut south, and the
## pool's basin sunk in the floor.
func base_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var d := p.length()
	var wall := 22.0 * smoothstep(R_CAVE - 0.5, R_CAVE + 3.0, d) + noise.get_noise_2d(x * 4.0, z * 4.0) * 1.2 * smoothstep(R_CAVE, R_CAVE + 2.0, d)
	if z > 0.0:
		# The tunnel out to the south.
		var tw := 1.0 - smoothstep(TUNNEL_W, TUNNEL_W + 1.6, absf(x))
		wall = lerpf(wall, 0.0, tw)
	var h := wall
	var dp := p.distance_to(POOL)
	if dp < POOL_R + 0.6:
		h = lerpf(-1.4, 0.0, smoothstep(POOL_R - 1.4, POOL_R + 0.6, dp))
	return h


func surface_at(_x: float, _z: float, h: float, _r: RandomNumberGenerator) -> String:
	return "water" if h < POOL_Y else "stone"


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if h > 2.0:
		return stone.darkened(r.randf_range(0.25, 0.4))
	if h < POOL_Y:
		return water_col.darkened(0.55)
	# A ring of pale flagstones round the pool and a path to the mark.
	var dp := p.distance_to(POOL)
	if (dp < POOL_R + 2.2 and dp > POOL_R + 0.4) or (absf(x) < 1.4 and z > POOL.y and z < 12.0):
		var ring := (int(floor(dp * 1.4)) + int(floor(z * 1.4))) % 2
		return Color(stone, 1.0).lerp(Color.WHITE, 0.25 if ring == 0 else 0.1).darkened(r.randf_range(0.0, 0.08))
	if r.randf() < 0.04:
		return Color.html(accent[r.randi_range(0, accent.size() - 1)])
	return pick(r, floor_cols)


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	# Pillars of the cave's own stone round the walls, and boulders at their feet.
	for i in 14:
		var a := TAU * i / 14.0 + r.randf_range(-0.1, 0.1)
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.45:
			continue
		var d := R_CAVE + 0.6
		k.spire(cos(a) * d, sin(a) * d, r.randf_range(1.0, 1.6), r.randf_range(7.0, 12.0), "rock", stone, 0.6, 6)
	for i in 10:
		var a := r.randf() * TAU
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.5:
			continue
		k.rock(cos(a) * (R_CAVE - 1.2), sin(a) * (R_CAVE - 1.2), r.randf_range(0.5, 1.0), "rock", true, stone)
	# Low steps round the pool's edge, and the curb of its basin.
	var kerb = k._tmp()
	for i in 24:
		var a := TAU * i / 24.0
		var c := POOL + Vector2(cos(a), sin(a)) * (POOL_R + 0.35)
		kerb.box(Vector3(c.x, -0.05, c.y), Vector3(0.9, 0.3, 0.5), Color(stone, 1.0).lightened(0.2))
	k.merge(kerb, "stone")
	# The goddess's mark in the floor (where the hero prays).
	var mark = k._tmp(false)
	mark.push(Transform3D(Basis.IDENTITY, Vector3(MARK.x, k.h(MARK.x, MARK.y) + 0.03, MARK.y)))
	mark.prism(Vector3(0, -0.02, 0), 1.0, Vector3(0, 0.0, 0), 1.0, 16, glow.darkened(0.5))
	mark.prism(Vector3(0, 0.0, 0), 0.8, Vector3(0, 0.015, 0), 0.8, 16, glow)
	for i in 6:
		var a := TAU * i / 6.0
		mark.prism(Vector3(cos(a) * 0.45, 0.015, sin(a) * 0.45), 0.16, Vector3(cos(a) * 0.45, 0.025, sin(a) * 0.45), 0.16, 6, Color.WHITE)
	mark.pop()
	k.merge(mark, "glow")
	# Glowing crystals or flowers by the walls, and a soft light over the pool.
	var shine = k._tmp(false)
	for i in 18:
		var a := r.randf() * TAU
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.5:
			continue
		var d := r.randf_range(R_CAVE - 2.6, R_CAVE - 0.8)
		var base := Vector3(cos(a) * d, 0.0, sin(a) * d)
		base.y = k.h(base.x, base.z)
		var col := Color.html(accent[i % accent.size()])
		if keeper == "alan":
			shine.icosa(base + Vector3(0, 0.25, 0), Vector3(0.14, 0.14, 0.14), 0.2, col)
			shine.prism(base, 0.02, base + Vector3(0, 0.2, 0), 0.02, 4, Color.html("5aa04a"))
		else:
			var tip := base + Vector3(r.randf_range(-0.2, 0.2), r.randf_range(0.6, 1.3), r.randf_range(-0.2, 0.2))
			shine.prism(base, 0.16, tip, 0.0, 5, col)
	k.merge(shine, "glow")
	var light := OmniLight3D.new()
	light.name = "PoolLight"
	light.position = Vector3(POOL.x, 2.5, POOL.y)
	light.light_color = glow
	light.light_energy = 1.6
	light.omni_range = 13.0
	light.shadow_enabled = false
	k._misc.add_child(light)
	# A column of light falling on the pool from far above.
	var shaft = k._tmp(false)
	shaft.prism(Vector3(POOL.x, POOL_Y, POOL.y), 2.6, Vector3(POOL.x, 24.0, POOL.y), 3.4, 12, Color(glow, 0.1))
	shaft.prism(Vector3(POOL.x, POOL_Y, POOL.y), 1.6, Vector3(POOL.x, 24.0, POOL.y), 2.2, 12, Color(glow, 0.1))
	k.merge(shaft, "shadow")
	# The spring itself: the keeper rises from the pool when the hero prays.
	k._dyn("res://scripts/dungeon/goddess_spring.gd", "GoddessSpring", Vector3(MARK.x, k.h(MARK.x, MARK.y), MARK.y), 0.0,
		{"keeper": keeper, "gift": gift, "spring_id": id, "pool": Vector3(POOL.x, POOL_Y, POOL.y)}, Node3D.new())


## Fairies over the water, for an empty bottle.
func populate(k) -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		var f := Node3D.new()
		f.name = "Fairy%d" % i
		f.set_script(load("res://scripts/items/fairy.gd"))
		f.position = Vector3(POOL.x + cos(a) * 2.6, 1.4, POOL.y + sin(a) * 2.6)
		k._misc.add_child(f)
