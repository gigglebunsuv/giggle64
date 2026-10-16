class_name PauseArt
extends RefCounted
## The pause pages' dressing, in the spirit of OoT's kaleido pages: a carved
## slate panel in a bevelled gold frame (the page textures in
## ovl_kaleido_scope), a title banner, recessed trays that hold a section's
## items, round sockets, OoT's four-cornered cursor that breathes in and out,
## and the outline OoT draws round an equipped item (gEquippedItemOutlineTex).
##
## The page background is painted once into an image (noise for the stone,
## a faint carved lattice, a vignette and the frame) and shared by every page.

const GOLD := Color(0.86, 0.68, 0.3)
const GOLD_LIGHT := Color(1.0, 0.9, 0.58)
const GOLD_DARK := Color(0.42, 0.29, 0.1)
const INK := Color(0.03, 0.03, 0.07)
const LABEL := Color(1.0, 0.86, 0.45)

static var _bg: Dictionary = {}


## The shared page backing for a page of `size` (made once per size).
static func page_background(size: Vector2i) -> Texture2D:
	if _bg.has(size):
		return _bg[size]
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 64
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	var top := Color(0.2, 0.23, 0.36)
	var bottom := Color(0.07, 0.08, 0.15)
	var centre := Vector2(size) * 0.5
	for y in size.y:
		for x in size.x:
			var c := top.lerp(bottom, float(y) / size.y)
			# Mottled stone.
			var n := noise.get_noise_2d(x, y)
			c = c.lightened(n * 0.08) if n > 0.0 else c.darkened(-n * 0.12)
			# A carved lattice of diamonds: lit on the upper-left edges, shaded below.
			var u := fposmod(x + y, 16.0)
			var v := fposmod(x - y, 16.0)
			if u < 1.0 or v < 1.0:
				c = c.darkened(0.12)
			elif u < 2.0 or v < 2.0:
				c = c.lightened(0.05)
			# Vignette.
			var d := ((Vector2(x, y) - centre) / centre).length()
			c = c.darkened(clampf((d - 0.55) * 0.55, 0.0, 0.4))
			c.a = 0.93
			img.set_pixel(x, y, c)
	_frame(img)
	var t := ImageTexture.create_from_image(img)
	_bg[size] = t
	return t


## A bevelled gold frame round the image, with corner brackets and rivets.
static func _frame(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var e := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if e > 3:
				continue
			var c := INK
			if e == 1 or e == 2:
				# Lit from the upper left.
				var lit := x < w - 1 - x and y < h - 1 - y
				var near_tl := (x <= 2 or y <= 2) and not (x >= w - 3 or y >= h - 3)
				c = GOLD_LIGHT if (e == 1 and near_tl) else (GOLD if e == 2 or lit else GOLD_DARK)
			elif e == 3:
				c = Color(0, 0, 0, 0.6)
			img.set_pixel(x, y, c)
	# Corner brackets: an L of gold a few pixels in, with a diamond rivet.
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var sx := 1 if corner.x == 0 else -1
		var sy := 1 if corner.y == 0 else -1
		var ox := 0 if corner.x == 0 else w - 1
		var oy := 0 if corner.y == 0 else h - 1
		for i in range(5, 16):
			_px(img, ox + sx * i, oy + sy * 6, GOLD_DARK)
			_px(img, ox + sx * 6, oy + sy * i, GOLD_DARK)
			_px(img, ox + sx * i, oy + sy * 5, GOLD)
			_px(img, ox + sx * 5, oy + sy * i, GOLD)
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if absi(dx) + absi(dy) <= 2:
					var col := GOLD_LIGHT if dx + dy < 0 else (GOLD if dx + dy == 0 else GOLD_DARK)
					_px(img, ox + sx * (10) + dx, oy + sy * 10 + dy, col)


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


## A shape with its corners cut off by `cut` pixels (the plates and trays).
static func chamfer(r: Rect2, cut: float) -> PackedVector2Array:
	return PackedVector2Array([
		r.position + Vector2(cut, 0), Vector2(r.end.x - cut, r.position.y), Vector2(r.end.x, r.position.y + cut),
		Vector2(r.end.x, r.end.y - cut), Vector2(r.end.x - cut, r.end.y), Vector2(r.position.x + cut, r.end.y),
		Vector2(r.position.x, r.end.y - cut), Vector2(r.position.x, r.position.y + cut)])


static func _outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, width := 1.0) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, width)


## The page title on a banner: a dark red plate edged in gold, swallow-tailed
## ends, and the name in gold with a shadow.
static func title_plate(ci: CanvasItem, cx: float, y: float, text: String) -> void:
	var tw := PixelFont.measure(text).x
	var half := tw * 0.5 + 14.0
	var r := Rect2(cx - half, y, half * 2.0, 13.0)
	# Ribbon tails behind the plate.
	for s in [-1.0, 1.0]:
		var x0: float = cx + s * (half - 4.0)
		var x1: float = cx + s * (half + 12.0)
		var tail := PackedVector2Array([Vector2(x0, y + 3), Vector2(x1, y + 3), Vector2(x1 - s * 5.0, y + 8.5), Vector2(x1, y + 14), Vector2(x0, y + 14)])
		ci.draw_colored_polygon(tail, Color(0.32, 0.08, 0.07))
		_outline(ci, tail, GOLD_DARK)
	var plate := chamfer(r, 3.0)
	ci.draw_colored_polygon(plate, Color(0.5, 0.12, 0.1))
	ci.draw_rect(Rect2(r.position.x + 3, r.position.y + 1, r.size.x - 6, 4), Color(1, 0.6, 0.45, 0.18))
	_outline(ci, plate, GOLD, 1.0)
	_outline(ci, chamfer(r.grow(-2), 2.0), Color(GOLD_DARK, 0.8), 1.0)
	for s in [-1.0, 1.0]:
		diamond(ci, Vector2(cx + s * (half - 7.0), y + 6.5), 2.0, GOLD_LIGHT)
	PixelFont.draw_centered(ci, cx + 1, y + 4, text, Color(0.1, 0.02, 0.0, 0.9))
	PixelFont.draw_centered(ci, cx, y + 3, text, LABEL)


static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


## A recessed tray holding one section's items: shadowed along the top, lit
## along the bottom, a gold hairline round it.
static func tray(ci: CanvasItem, r: Rect2) -> void:
	var shape := chamfer(r, 4.0)
	ci.draw_colored_polygon(shape, Color(0.0, 0.01, 0.04, 0.42))
	ci.draw_line(Vector2(r.position.x + 4, r.position.y + 1), Vector2(r.end.x - 4, r.position.y + 1), Color(0, 0, 0, 0.55), 1.0)
	ci.draw_line(Vector2(r.position.x + 4, r.end.y - 1), Vector2(r.end.x - 4, r.end.y - 1), Color(1, 1, 1, 0.08), 1.0)
	_outline(ci, shape, Color(GOLD, 0.45))


## The section's name on a small gold-edged plate at the left of its tray.
static func label_plate(ci: CanvasItem, r: Rect2, text: String, lit: bool) -> void:
	var shape := chamfer(r, 3.0)
	ci.draw_colored_polygon(shape, Color(0.3, 0.2, 0.08) if lit else Color(0.18, 0.13, 0.07))
	ci.draw_rect(Rect2(r.position.x + 2, r.position.y + 1, r.size.x - 4, r.size.y * 0.4), Color(1, 0.9, 0.6, 0.1 if lit else 0.05))
	_outline(ci, shape, GOLD if lit else GOLD_DARK)
	var c := r.get_center()
	PixelFont.draw_centered(ci, c.x, c.y - 3, text, LABEL if lit else Color(0.72, 0.62, 0.42))


## A round socket sunk into the tray (brighter when something sits in it).
static func socket(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	ci.draw_circle(c + Vector2(0, 1), r + 1.0, Color(1, 1, 1, 0.07))
	ci.draw_circle(c, r + 1.0, Color(0, 0, 0, 0.65))
	var base := Color(0.17, 0.2, 0.33) if filled else Color(0.09, 0.11, 0.19)
	ci.draw_circle(c, r, base)
	ci.draw_circle(c + Vector2(0, 1.5), r - 2.0, base.lightened(0.06))
	# The upper rim in shadow, as if sunk into the stone.
	ci.draw_arc(c, r - 0.5, PI * 1.1, PI * 1.9, 10, Color(0, 0, 0, 0.45), 1.5)


## OoT's cursor: four corner brackets round a slot, breathing in and out,
## its color pulsing.
static func cursor(ci: CanvasItem, c: Vector2, half: float, t: float, col: Color) -> void:
	var breathe := half + 1.5 + sin(t * 6.0) * 1.2
	var arm := 5.0
	var glow := col.lerp(Color(1, 1, 1), 0.35 + 0.35 * sin(t * 6.0))
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p: Vector2 = c + s * breathe
		var pts := PackedVector2Array([p - Vector2(s.x * arm, 0), p, p - Vector2(0, s.y * arm)])
		ci.draw_polyline(pts, Color(0, 0, 0, 0.6), 3.0)
		ci.draw_polyline(pts, glow, 1.5)


## The gold outline round an equipped item (gEquippedItemOutlineTex).
static func equipped_outline(ci: CanvasItem, c: Vector2, half: float) -> void:
	var shape := chamfer(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), 4.0)
	ci.draw_colored_polygon(shape, Color(1.0, 0.8, 0.3, 0.12))
	_outline(ci, shape, Color(1.0, 0.82, 0.35, 0.85))


## A plate across the screen (the name panel under the pages).
static func name_panel(ci: CanvasItem, r: Rect2) -> void:
	var shape := chamfer(r, 4.0)
	ci.draw_colored_polygon(chamfer(r.grow(1), 4.0), Color(0, 0, 0, 0.6))
	ci.draw_colored_polygon(shape, Color(0.06, 0.07, 0.14, 0.92))
	ci.draw_rect(Rect2(r.position.x + 4, r.position.y + 1, r.size.x - 8, r.size.y * 0.4), Color(1, 1, 1, 0.05))
	_outline(ci, shape, GOLD)
	for s in [-1.0, 1.0]:
		diamond(ci, Vector2(r.get_center().x + s * (r.size.x * 0.5 - 6.0), r.get_center().y), 2.0, GOLD)
