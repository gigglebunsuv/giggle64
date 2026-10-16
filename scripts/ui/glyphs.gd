class_name Glyphs
extends RefCounted
## Button pictures for prompts, matched to what the player is holding: the
## keyboard's key names, or the face buttons of an Xbox pad (colored A B X Y),
## a PlayStation pad (cross, circle, square, triangle) or a Nintendo pad (whose
## letters sit in other places: B at the bottom, A on the right).
##
## Prompts are written with tokens for the game's buttons by their position
## on an Xbox pad, which is how Godot names them (JOY_BUTTON_A is the bottom
## face button on every pad):
##   {A} bottom  {B} right  {X} left  {Y} top  {LB} {RB} {LT} {RT}
##   {START} {SELECT} {MOVE} (left stick / WASD) {LOOK} (right stick / mouse)
## draw_hint() draws such a prompt with each token as a little badge.

const FAMILIES := ["AUTO", "XBOX", "PLAYSTATION", "NINTENDO"]

const XBOX_COLORS := {"A": Color8(93, 184, 46), "B": Color8(229, 53, 44), "X": Color8(47, 127, 214), "Y": Color8(242, 193, 46)}
const PS_COLORS := {"A": Color8(127, 181, 255), "B": Color8(255, 107, 107), "X": Color8(231, 156, 216), "Y": Color8(94, 211, 163)}
## What each position is called on a Nintendo pad.
const NINTENDO_LETTERS := {"A": "B", "B": "A", "X": "Y", "Y": "X"}
const SHOULDERS := {
	"xbox": {"LB": "LB", "RB": "RB", "LT": "LT", "RT": "RT", "START": "MENU", "SELECT": "VIEW"},
	"playstation": {"LB": "L1", "RB": "R1", "LT": "L2", "RT": "R2", "START": "OPTIONS", "SELECT": "CREATE"},
	"nintendo": {"LB": "L", "RB": "R", "LT": "ZL", "RT": "ZR", "START": "+", "SELECT": "-"},
}
## The keyboard and mouse controls (project.godot's input map).
const KEYS := {
	"A": "SPACE", "B": "LMB", "X": "1", "Y": "2", "LB": "SHIFT", "RB": "F", "LT": "Q", "RT": "RMB",
	"START": "ESC", "SELECT": "M", "MOVE": "WASD", "LOOK": "MOUSE",
}
const FACE := ["A", "B", "X", "Y"]


## "keyboard", "xbox", "playstation" or "nintendo".
static func family() -> String:
	if not GameManager.using_gamepad:
		return "keyboard"
	var forced: String = FAMILIES[clampi(GameManager.glyph_family, 0, FAMILIES.size() - 1)]
	if forced != "AUTO":
		return forced.to_lower()
	return detect(_pad_name())


static func _pad_name() -> String:
	var pads := Input.get_connected_joypads()
	return Input.get_joy_name(pads[0]) if not pads.is_empty() else ""


## Guesses the family from a pad's name (SDL's controller names).
static func detect(pad_name: String) -> String:
	var n := pad_name.to_lower()
	for k in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony", "wireless controller"]:
		if n.contains(k):
			return "playstation"
	for k in ["nintendo", "switch", "pro controller", "joy-con", "joycon", "gamecube"]:
		if n.contains(k):
			return "nintendo"
	return "xbox"


## The plain name of a button (for places that only take text).
static func label(token: String, fam := "") -> String:
	if fam == "":
		fam = family()
	if fam == "keyboard":
		return KEYS.get(token, token)
	if token in FACE:
		match fam:
			"nintendo":
				return NINTENDO_LETTERS[token]
			"playstation":
				return {"A": "CROSS", "B": "CIRCLE", "X": "SQUARE", "Y": "TRIANGLE"}[token]
		return token
	match token:
		"MOVE":
			return "STICK"
		"LOOK":
			return "R-STICK"
	return SHOULDERS.get(fam, SHOULDERS.xbox).get(token, token)


## Width in pixels of a badge for `token`.
static func badge_width(token: String, fam := "") -> float:
	if fam == "":
		fam = family()
	if fam != "keyboard" and token in FACE:
		return 9.0
	return label(token, fam).length() * PixelFont.ADVANCE + 4.0


## Draws the badge for `token` with its left edge at x and text row y (the
## pixel font's top): a colored face button, or the name in a little frame.
static func draw_badge(ci: CanvasItem, pos: Vector2, token: String, alpha := 1.0, fam := "") -> float:
	if fam == "":
		fam = family()
	var w := badge_width(token, fam)
	var mid := Vector2(pos.x + w * 0.5, pos.y + 3.5)
	if fam != "keyboard" and token in FACE:
		match fam:
			"xbox":
				ci.draw_circle(mid, 4.6, Color(XBOX_COLORS[token], alpha), true, -1.0, true)
				PixelFont.draw(ci, mid - Vector2(2.5, 3.5), token, Color(0.05, 0.05, 0.05, alpha) if token == "Y" else Color(1, 1, 1, alpha), 1, false)
			"playstation":
				ci.draw_circle(mid, 4.6, Color(0.17, 0.17, 0.2, alpha), true, -1.0, true)
				_ps_shape(ci, mid, token, Color(PS_COLORS[token], alpha))
			_:
				ci.draw_circle(mid, 4.6, Color(0.22, 0.22, 0.25, alpha), true, -1.0, true)
				PixelFont.draw(ci, mid - Vector2(2.5, 3.5), NINTENDO_LETTERS[token], Color(1, 1, 1, alpha), 1, false)
		return w
	var text := label(token, fam)
	var r := Rect2(pos.x, pos.y - 1.5, w, 10.0)
	ci.draw_rect(r, Color(0.12, 0.12, 0.16, 0.85 * alpha))
	ci.draw_rect(r, Color(0.8, 0.8, 0.85, 0.7 * alpha), false, 1.0)
	PixelFont.draw(ci, Vector2(pos.x + 2.0, pos.y), text, Color(1, 1, 1, alpha), 1, false)
	return w


## The PlayStation shapes, drawn small: cross, circle, square, triangle.
static func _ps_shape(ci: CanvasItem, c: Vector2, token: String, col: Color) -> void:
	match token:
		"A":
			ci.draw_line(c + Vector2(-2.3, -2.3), c + Vector2(2.3, 2.3), col, 1.2, true)
			ci.draw_line(c + Vector2(-2.3, 2.3), c + Vector2(2.3, -2.3), col, 1.2, true)
		"B":
			ci.draw_arc(c, 2.4, 0.0, TAU, 14, col, 1.1, true)
		"X":
			ci.draw_rect(Rect2(c - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), col, false, 1.1)
		"Y":
			var pts := PackedVector2Array([c + Vector2(0, -2.7), c + Vector2(2.6, 2.0), c + Vector2(-2.6, 2.0), c + Vector2(0, -2.7)])
			ci.draw_polyline(pts, col, 1.1, true)


## Splits a prompt into text runs and tokens: [[is_token, string], ...].
static func _parts(text: String) -> Array:
	var out: Array = []
	var i := 0
	while i < text.length():
		var open := text.find("{", i)
		if open < 0:
			out.append([false, text.substr(i)])
			break
		if open > i:
			out.append([false, text.substr(i, open - i)])
		var close := text.find("}", open)
		if close < 0:
			out.append([false, text.substr(open)])
			break
		out.append([true, text.substr(open + 1, close - open - 1)])
		i = close + 1
	return out


static func hint_width(text: String) -> float:
	var fam := family()
	var w := 0.0
	for p in _parts(text):
		w += badge_width(p[1], fam) if p[0] else String(p[1]).length() * PixelFont.ADVANCE
	return w


## Draws a prompt centered on `center_x`, its tokens as badges.
static func draw_hint(ci: CanvasItem, center_x: float, y: float, text: String, color: Color) -> void:
	var fam := family()
	var x := roundf(center_x - hint_width(text) * 0.5)
	for p in _parts(text):
		if p[0]:
			x += draw_badge(ci, Vector2(x, y), p[1], color.a, fam)
		else:
			var s: String = p[1]
			PixelFont.draw(ci, Vector2(x, y), s, color)
			x += s.length() * PixelFont.ADVANCE


## Draws a prompt starting at `pos` (left aligned).
static func draw_hint_left(ci: CanvasItem, pos: Vector2, text: String, color: Color) -> void:
	draw_hint(ci, pos.x + hint_width(text) * 0.5, pos.y, text, color)
