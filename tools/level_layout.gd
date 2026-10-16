extends RefCounted
## Shared description of the test area: terrain height field, path and the
## painted (stretched, non-tiling) terrain texture.

const X_MIN := -32.0
const X_MAX := 26.0     # East edge is a cliff dropping into the void.
const Z_MIN := -36.0
const Z_MAX := 32.0
const CELL := 2.0
const TERRAIN_TEX_SIZE := 128

const PATH: Array[Vector2] = [
	Vector2(0, 31), Vector2(1.5, 19), Vector2(2.0, 10), Vector2(-1.0, 1.0),
	Vector2(0.5, -8.0), Vector2(0.0, -14.0), Vector2(0.0, -20.5),
]
const PLATEAU := Vector2(-17, -4)
const MOUND := Vector2(13, 13)
const RUIN := Vector2(0, -24.5)


static func path_distance(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	for i in PATH.size() - 1:
		var a := PATH[i]
		var b := PATH[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


static func height(x: float, z: float) -> float:
	var h := 0.35 * sin(x * 0.35 + 1.3) * cos(z * 0.28) + 0.25 * sin((x + z) * 0.21) + 0.15
	var clear := smoothstep(6.0, 11.0, Vector2(x, z - 2.0).length())
	var on_path := smoothstep(1.5, 4.0, path_distance(x, z))
	var ruin_area := smoothstep(6.0, 9.0, Vector2(x * 0.7, z - RUIN.y).length())
	h *= lerpf(0.12, 1.0, minf(minf(clear, on_path), ruin_area))
	# Low grassy mound to the south-east.
	h = maxf(h, 1.3 * (1.0 - smoothstep(2.5, 6.5, Vector2(x, z).distance_to(MOUND))))
	# Rocky plateau to the west, reached by a ramp on its east side.
	h = maxf(h, 2.6 * (1.0 - smoothstep(5.5, 8.5, Vector2(x, z).distance_to(PLATEAU))))
	var ramp := 2.6 * clampf((-7.0 - x) / 6.5, 0.0, 1.0) * (1.0 - smoothstep(1.4, 2.6, absf(z - PLATEAU.y)))
	if x > PLATEAU.x:
		h = maxf(h, ramp)
	# Steep rims enclosing the west, north and south sides.
	if x < -24.0:
		h += (-24.0 - x) * 1.35
	if z < -29.5:
		h += (-29.5 - z) * 1.35
	if z > 25.0:
		h += (z - 25.0) * 1.35
	return h


## True for terrain the texture painter should show as bare rock.
static func is_rocky(x: float, z: float) -> bool:
	var h := height(x, z)
	var slope := absf(height(x + 0.5, z) - height(x - 0.5, z)) + absf(height(x, z + 0.5) - height(x, z - 0.5))
	return slope > 0.85 or (h > 2.0 and Vector2(x, z).distance_to(PLATEAU) < 9.0 and slope > 0.35)


static func paint_terrain_texture() -> Image:
	var n := TERRAIN_TEX_SIZE
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var grass: Array[Color] = [Color.html("3b581d"), Color.html("466725"), Color.html("53762a"), Color.html("5f8331")]
	var dry: Array[Color] = [Color.html("5c6a2a"), Color.html("6b7631")]
	var dirt: Array[Color] = [Color.html("5d4429"), Color.html("6d5131"), Color.html("7c5e39")]
	var rock: Array[Color] = [Color.html("5a554f"), Color.html("6a645d"), Color.html("78716a")]
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for py in n:
		for px in n:
			var x := lerpf(X_MIN, X_MAX, (px + 0.5) / n)
			var z := lerpf(Z_MIN, Z_MAX, (py + 0.5) / n)
			var d := path_distance(x, z) + rng.randf_range(-0.35, 0.35)
			var ruin_d := Vector2(x * 0.75, z - RUIN.y).length() + rng.randf_range(-0.4, 0.4)
			var c: Color
			if d < 1.3 or ruin_d < 5.5:
				c = dirt[rng.randi_range(0, dirt.size() - 1)]
			elif is_rocky(x, z):
				c = rock[rng.randi_range(0, rock.size() - 1)]
			elif d < 1.9 and rng.randf() < 0.5:
				c = dirt[0]
			else:
				var blotch := sin(x * 0.9) * cos(z * 0.7) + sin((x - z) * 0.37)
				if blotch > 1.2 and rng.randf() < 0.6:
					c = dry[rng.randi_range(0, 1)]
				else:
					c = grass[clampi(int((blotch * 0.25 + 0.5 + rng.randf_range(-0.3, 0.3)) * grass.size()), 0, grass.size() - 1)]
			img.set_pixel(px, py, c)
	return img
