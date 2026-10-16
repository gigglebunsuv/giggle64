extends RefCounted
## Base description of one area of Haven, used by tools/gen_world.gd.
##
## A region supplies a height field (its own shape plus a cliff rim around the
## play rectangle, broken by exit corridors), a painter for its one stretched
## ground texture, its sky/fog/light mood, and build() which places everything
## else through the WorldKit. Coordinates are meters: +X east, -Z north.

var id := ""
var x_min := -50.0
var x_max := 50.0
var z_min := -50.0
var z_max := 50.0
## Terrain grid spacing.
var cell := 2.0
## Terrain continues this far past the play rectangle (cliff tops, corridor ends).
var outer := 20.0
var tex_size := 256
## An interior (a house): no sky dome, and the world map shows `parent` instead.
var interior := false
## The name other areas know this one by in their entrance markers
## ("from_<link_id>"); another version of an area (the fallen Castle Town)
## keeps the original's. "" = id.
var link_id := ""

## Boundary rim: a cliff that starts `rim_margin` inside the edge and rises
## `rim_height` over `rim_run` meters (steeper than the hero can climb).
var rim_height := 16.0
var rim_margin := 9.0
var rim_run := 5.0
var rim_wobble := 4.0
## Exits: each is {"to": area, "p": Vector2 edge point, "d": Vector2 inward,
## "w": corridor half width, "y": floor height, "wall": corridor wall run,
## "spawn": entrance distance inside the edge, "corridor": cut the rim}.
var links: Array = []
## Flat water surfaces: {"rect": Rect2 (x, z), "y": height, "col": Color}.
var water: Array = []
## Sky, fog and light. See gen_world.gd for the keys.
var mood := {}
## Terrain steeper than this (normal.y) uses the cliff texture.
var cliff_normal_y := 0.62
var cliff_col := Color(0.62, 0.56, 0.5)
var rock_col := Color.html("6a645d")
var noise := FastNoiseLite.new()
var detail := FastNoiseLite.new()
var seed_value := 1


func _init() -> void:
	setup()
	noise.seed = seed_value
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	detail.seed = seed_value + 7
	detail.frequency = 0.08
	for l in links:
		l.merge({"w": 6.0, "wall": 5.0, "spawn": 9.0, "corridor": true, "tilt": 0.0}, false)
		if not l.has("y"):
			l.y = base_height(l.p.x + l.d.x * 20.0, l.p.y + l.d.y * 20.0)


func link_name() -> String:
	return link_id if link_id != "" else id


## Override: set the rectangle, links, water and mood.
func setup() -> void:
	pass


## Override: the area's own terrain shape (before the rim).
func base_height(_x: float, _z: float) -> float:
	return 0.0


## Override: ground color for the painted texture.
func ground_color(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> Color:
	return Color.html("4a6a28")


## Override: place props, buildings, exits and entrances.
func build(_k) -> void:
	pass


## Footstep surface of the ground at (x, z) (see scripts/systems/surface.gd).
## By default it is read off the painted ground color; regions override it
## where the color alone would guess wrong (floorboards, mud).
func surface_at(x: float, z: float, h: float, r: RandomNumberGenerator) -> String:
	return classify(ground_color(x, z, h, r))


## Guesses a surface from a ground color: near-white is snow, gray is stone,
## green is grass, pale yellow-brown is sand, other browns are dirt.
static func classify(c: Color) -> String:
	if c.s < 0.12 and c.v > 0.85 and c.b >= c.r:
		return "snow"
	if c.s < 0.2:
		return "stone"
	var hue := c.h * 360.0
	if hue > 65.0 and hue < 175.0:
		return "grass"
	if hue > 160.0 and hue < 260.0:
		return "stone"
	if hue > 28.0 and hue <= 65.0 and c.v > 0.75 and c.s < 0.55:
		return "sand"
	return "dirt"


## The terrain's footstep surfaces on a 1 m grid over terrain_bounds():
## [PackedByteArray of Surface ids (row-major, north first), Rect2, Vector2i].
## Slopes steep enough to paint as bare rock are stone.
func surface_grid() -> Array:
	var b := terrain_bounds()
	var size := Vector2i(int(ceil(b.size.x)), int(ceil(b.size.y)))
	var names: Array = load("res://scripts/systems/surface.gd").NAMES
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 17 + 3
	var grid := PackedByteArray()
	grid.resize(size.x * size.y)
	for v in size.y:
		for u in size.x:
			var x := b.position.x + (u + 0.5) * b.size.x / size.x
			var z := b.position.y + (v + 0.5) * b.size.y / size.y
			var hh := height(x, z)
			var slope := Vector2(height(x + 0.5, z) - height(x - 0.5, z), height(x, z + 0.5) - height(x, z - 0.5)).length()
			var s := "stone" if slope > 1.05 else surface_at(x, z, hh, r)
			grid[v * size.x + u] = maxi(names.find(s), 0)
	return [grid, b, size]


## Final terrain height: the region's shape, the boundary rim and the exit corridors.
func height(x: float, z: float) -> float:
	var h := base_height(x, z)
	if rim_height <= 0.0:
		return h
	var d_edge := minf(minf(x - x_min, x_max - x), minf(z - z_min, z_max - z))
	var m := rim_margin + noise.get_noise_2d(x * 3.0, z * 3.0) * rim_wobble
	var t := clampf((m - d_edge) / rim_run, 0.0, 1.0)
	var rim := rim_height * t * t * (3.0 - 2.0 * t)
	rim += maxf(-d_edge, 0.0) * 0.4 + detail.get_noise_2d(x, z) * 2.0 * t
	h += rim
	for l in links:
		if not l.corridor:
			continue
		var p: Vector2 = l.p
		var d: Vector2 = l.d
		var a := p - d * (outer + 10.0)
		var b := p + d * (rim_margin + rim_run + rim_wobble + 2.0)
		var dist := seg_dist(Vector2(x, z), a, b)
		var c := 1.0 - smoothstep(l.w, l.w + l.wall, dist)
		if c > 0.0:
			h = lerpf(h, l.y + _corridor_noise(x, z), c)
	return h


func _corridor_noise(x: float, z: float) -> float:
	return detail.get_noise_2d(x * 0.5, z * 0.5) * 0.15


## True if (x, z) lies inside an exit corridor (no props there).
func in_corridor(x: float, z: float, pad := 2.0) -> bool:
	for l in links:
		var p: Vector2 = l.p
		var d: Vector2 = l.d
		var b := p + d * (rim_margin + rim_run + rim_wobble + 6.0)
		if seg_dist(Vector2(x, z), p - d * outer, b) < l.w + pad:
			return true
	return false


func inside(x: float, z: float, pad := 0.0) -> bool:
	return x > x_min + pad and x < x_max - pad and z > z_min + pad and z < z_max - pad


# --- Geometry helpers ---------------------------------------------------------

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func poly_dist(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		best = minf(best, seg_dist(p, pts[i], pts[i + 1]))
	return best


## Smooth bump: 1 at the center falling to 0 at `r` (elliptical with `sx`, `sz`).
static func bump(x: float, z: float, c: Vector2, r: float, sx := 1.0, sz := 1.0) -> float:
	var d := Vector2((x - c.x) / sx, (z - c.y) / sz).length() / r
	if d >= 1.0:
		return 0.0
	return 1.0 - d * d * (3.0 - 2.0 * d)


## Flat-topped plateau with steep sides: 1 inside r0, 0 outside r1.
static func mesa(x: float, z: float, c: Vector2, r0: float, r1: float) -> float:
	return 1.0 - smoothstep(r0, r1, Vector2(x, z).distance_to(c))


static func pick(r: RandomNumberGenerator, cols: Array) -> Color:
	return Color.html(cols[r.randi_range(0, cols.size() - 1)])


# --- Ground texture -----------------------------------------------------------

func terrain_bounds() -> Rect2:
	return Rect2(x_min - outer, z_min - outer, x_max - x_min + outer * 2.0, z_max - z_min + outer * 2.0)


## Paints the one stretched ground texture, with bare rock wherever the slope is steep.
func paint_ground() -> Image:
	var n := tex_size
	var b := terrain_bounds()
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for py in n:
		for px in n:
			heights[py * n + px] = height(b.position.x + (px + 0.5) / n * b.size.x, b.position.y + (py + 0.5) / n * b.size.y)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 31 + 5
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var step := Vector2(b.size.x / n, b.size.y / n)
	for py in n:
		for px in n:
			var hh := heights[py * n + px]
			var hx := heights[py * n + mini(px + 1, n - 1)] - heights[py * n + maxi(px - 1, 0)]
			var hz := heights[mini(py + 1, n - 1) * n + px] - heights[maxi(py - 1, 0) * n + px]
			var slope := Vector2(hx / (2.0 * step.x), hz / (2.0 * step.y)).length()
			var x := b.position.x + (px + 0.5) * step.x
			var z := b.position.y + (py + 0.5) * step.y
			var c: Color
			if slope > 1.05 + r.randf_range(-0.2, 0.2):
				var k := r.randf_range(0.85, 1.12)
				c = Color(rock_col.r * k, rock_col.g * k, rock_col.b * k)
			else:
				c = ground_color(x, z, hh, r)
			img.set_pixel(px, py, c)
	return img
