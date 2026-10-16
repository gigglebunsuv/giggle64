class_name MessageBox
extends Control
## Draws the Dialogue autoload's text box at the 320x240 logical resolution: the
## dark translucent box of OoT's default textbox (TEXTBOX_TYPE_BLACK, alpha 170)
## low on the screen, typed-out text with red *key words*, the green blinking
## triangle (more to read) or square (last box), and the two-choice cursor.

const BOX := Rect2(34, 164, 252, 60)
const TEXT_POS := Vector2(46, 172)
const LINE_H := 11
const WHITE := Color(1, 1, 1)
const RED := Color(1.0, 0.31, 0.24)
## Key words on the wooden box (Message_SetTextColor: 255, 120, 0).
const ORANGE := Color(1.0, 0.47, 0.0)
const GREEN := Color(0.27, 0.9, 0.3)

## The title screen keeps its own box (over its letterbox) for the lines in
## its scenes; the HUD's box draws only in play.
var on_title := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if Dialogue.active or visible:
		queue_redraw()


func _draw() -> void:
	var d: Node = Dialogue
	if not d.active or on_title != (GameManager.state == GameManager.GameState.TITLE):
		return
	var g: Vector2 = d.grow()
	var alpha := 1.0
	if d.phase == d.Phase.CLOSING:
		alpha = clampf(1.0 - d.timer / 3.0, 0.0, 1.0)
	var size := Vector2(BOX.size.x * g.x, BOX.size.y * g.y)
	var r := Rect2(BOX.get_center() - size * 0.5, size)
	var wooden: bool = d.style == "wooden"
	if wooden:
		# TEXTBOX_TYPE_WOODEN: brown (70, 50, 30) at alpha 230, with a grain.
		draw_rect(r, Color(70 / 255.0, 50 / 255.0, 30 / 255.0, 0.9 * alpha))
		var gy := r.position.y + 6.0
		while gy < r.end.y - 4.0:
			draw_rect(Rect2(r.position.x + 3, gy, r.size.x - 6, 1), Color(0.18, 0.12, 0.07, 0.35 * alpha))
			gy += 9.0
	else:
		draw_rect(r, Color(0, 0, 0, 0.67 * alpha))
	draw_rect(r.grow(-2), Color(0.06, 0.06, 0.1, 0.25 * alpha), false, 1.0)
	if d.phase == d.Phase.OPENING or d.phase == d.Phase.CLOSING:
		return
	# Who is speaking (cutscenes with several people): a small tab on the box.
	var who := String(d.page.get("name", ""))
	if who != "":
		var w := who.length() * PixelFont.ADVANCE + 10
		var tab := Rect2(BOX.position.x + 6, BOX.position.y - 10, w, 11)
		draw_rect(tab, Color(0, 0, 0, 0.75 * alpha))
		PixelFont.draw(self, tab.position + Vector2(5, 2), who.to_upper(), Color(1.0, 0.86, 0.3, alpha))
	var y := TEXT_POS.y
	var choosing: bool = d.page.has("choices")
	var key := ORANGE if wooden else RED
	for i in d.lines.size():
		_draw_line(Vector2(TEXT_POS.x, y), d.visible_text(i), alpha, WHITE, key)
		y += LINE_H
	if choosing and d.phase == d.Phase.CHOOSING:
		for c in d.page.choices.size():
			var cy: float = y + c * LINE_H
			var label: String = d.page.choices[c][0]
			_draw_line(Vector2(TEXT_POS.x + 12, cy), label, alpha, GREEN if c == d.choice else WHITE)
			if c == d.choice:
				_triangle_right(Vector2(TEXT_POS.x + 2, cy + 1), alpha)
	if d.phase == d.Phase.WAITING and not d.auto and fmod(d.timer, 16.0) < 11.0:
		var c := Vector2(BOX.end.x - 12, BOX.end.y - 10)
		if d.is_last_page():
			draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color(GREEN, alpha))
		else:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -3), c + Vector2(4, -3), c + Vector2(0, 3)]), Color(GREEN, alpha))


## One line with *star* markers switching between white and red.
func _draw_line(pos: Vector2, text: String, alpha: float, base := WHITE, key := RED) -> void:
	var red := false
	var x := pos.x
	var run := ""
	for ch in text + "*":
		if ch == "*":
			if run != "":
				PixelFont.draw_mixed(self, Vector2(x, pos.y), run, Color(key if red else base, alpha))
				x += run.length() * PixelFont.ADVANCE
				run = ""
			red = not red
		else:
			run += ch
	# (the appended "*" only flushes the last run)


func _triangle_right(p: Vector2, alpha: float) -> void:
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(0, 6), p + Vector2(5, 3)]), Color(GREEN, alpha))
