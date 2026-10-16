class_name FileSelect
extends Control
## The file select screen, after OoT's (zeldaret/oot, z_file_choose.c):
## - A blue window (windowColor 100, 150, 255 at alpha 200) slides in from the
##   right as the black screen fill fades (FileSelect_StartFadeIn: -40 alpha and
##   20 px per frame, then the title label and buttons fade in).
## - "Please select a file." over FILE 1-3; the stick moves a cyan highlight
##   (highlightColor 155, 255, 255) whose alpha pulses between 70 and 200 every
##   20 frames (FileSelect_PulsateCursor).
## - Choosing a file fades the other files out and slides the chosen one to the
##   top over 8 frames (SM_FADE_MAIN_TO_SELECT, SM_MOVE_FILE_TO_TOP), while the
##   title label cross-fades (+-31 alpha per frame).
## - B backs out the same way; confirming fills the screen with black and loads.
##
## Files are SaveGame's three slots. A saved file shows the hero's hearts and
## rupees and offers CONTINUE or ERASE (with a YES / NO check, like OoT's erase
## screen); an empty one begins a new game in Haven Village, outside the hero's
## house. DEBUG, under the files, begins an unsaved game there with the debug
## menu (DebugMenu) open. Timers run in OoT 20 Hz frames.

## Emitted once the screen is black after confirming: where to start, and
## the health to start with (-1 = full, a new game).
signal chosen(area: String, entrance: String, health: int)
## B on the main menu: back to the title.
signal cancelled

enum Mode { FADE_IN, MAIN, TO_SELECT, SELECT, TO_MAIN, FADE_OUT, DONE }

const WINDOW_COLOR := Color8(100, 150, 255)
const HIGHLIGHT := Color8(155, 255, 255)
const WINDOW := Rect2(28, 22, 264, 186)
## Steps of the file / select transitions (actionTimer).
const ACTION_FRAMES := 8.0
const FILE_Y := [52.0, 72.0, 92.0]
const LIST_TOP := 74.0
const ROW_H := 11.0
const ROWS := 10
const DEBUG_INDEX := 3
const DEBUG_BTN := Rect2(14, 92, 54, 13)

var mode := Mode.FADE_IN
## 0-2 the files, DEBUG_INDEX the debug button.
var file_index := 0
var area_index := 0
## The list shown once a saved file is picked: [label, action] rows, where
## action is "continue", "erase", "erase_yes" or "back".
var rows: Array = []
## What the open list is for: "saved" or "erase".
var list_kind := "saved"
## How the confirmed choice starts: "new", "debug" or "list" (the open list's row).
var start_kind := "list"
## SaveGame.summary() per slot ({} = empty), read when the screen opens.
var summaries: Array = [{}, {}, {}]

## Screen fill (black) and window alpha, 0..255 like the decomp.
var _fill := 255.0
var _window_x := 100.0
var _content := 0.0
var _k := 0.0
var _scroll := 0
var _pulse := 70.0
var _pulse_dir := 1
var _pulse_timer := 20.0
var _cursor := MenuInput.new(0.3, 0.1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Opens the screen from black.
func open() -> void:
	mode = Mode.FADE_IN
	_fill = 255.0
	_window_x = 100.0
	_content = 0.0
	file_index = 0
	visible = true
	refresh()


## Rereads the save files.
func refresh() -> void:
	summaries = []
	for i in SaveGame.SLOTS:
		summaries.append(SaveGame.summary(i))


func _open_list(kind: String) -> void:
	list_kind = kind
	rows = []
	match kind:
		"saved":
			rows = [["CONTINUE", "continue"], ["ERASE FILE", "erase"]]
		"erase":
			rows = [["NO", "back"], ["YES, ERASE IT", "erase_yes"]]
	area_index = 0
	_scroll = 0


func _process(delta: float) -> void:
	if not visible:
		return
	var f := delta * 20.0
	_update_pulse(f)
	match mode:
		Mode.FADE_IN:
			_fill = maxf(_fill - 40.0 * f, 0.0)
			_window_x = maxf(_window_x - 20.0 * f, 0.0)
			if _window_x <= 0.0:
				_content = minf(_content + 0.1 * f, 1.0)
				if _content >= 1.0:
					mode = Mode.MAIN
		Mode.MAIN:
			_main_input(delta)
		Mode.TO_SELECT:
			_k = minf(_k + f / ACTION_FRAMES, 1.0)
			if _k >= 1.0:
				mode = Mode.SELECT
		Mode.SELECT:
			_select_input(delta)
		Mode.TO_MAIN:
			_k = maxf(_k - f / ACTION_FRAMES, 0.0)
			if _k <= 0.0:
				mode = Mode.MAIN
		Mode.FADE_OUT:
			_fill = minf(_fill + 25.0 * f, 255.0)
			if _fill >= 255.0:
				mode = Mode.DONE
				_start()
	queue_redraw()


func _main_input(delta: float) -> void:
	if _accept():
		# A file written by a newer version of the game is left alone.
		if file_index < summaries.size() and summaries[file_index].get("too_new", false):
			Sfx.play("error")
			return
		Sfx.play("menu_select")
		if file_index == DEBUG_INDEX or summaries[file_index].is_empty():
			# A new game (or the debug one) begins at once, in Haven.
			start_kind = "debug" if file_index == DEBUG_INDEX else "new"
			GameManager.rumble(0.5, 0.25)
			mode = Mode.FADE_OUT
			return
		start_kind = "list"
		mode = Mode.TO_SELECT
		_k = 0.0
		_open_list("saved")
	elif _back():
		Sfx.play("msg_close")
		visible = false
		cancelled.emit()
	else:
		var d := _stick(delta)
		if d != 0:
			Sfx.play("menu_move")
			file_index = wrapi(file_index + d, 0, DEBUG_INDEX + 1)


func _select_input(delta: float) -> void:
	if _accept():
		match rows[area_index][1]:
			"erase":
				Sfx.play("menu_select")
				_open_list("erase")
			"back":
				Sfx.play("msg_close")
				_open_list("saved")
			"erase_yes":
				Sfx.play("door_unlock")
				SaveGame.erase(file_index)
				refresh()
				mode = Mode.TO_MAIN
			_:
				Sfx.play("menu_select")
				GameManager.rumble(0.5, 0.25)
				mode = Mode.FADE_OUT
	elif _back():
		Sfx.play("msg_close")
		if list_kind == "erase":
			_open_list("saved")
		else:
			mode = Mode.TO_MAIN
	else:
		var d := _stick(delta)
		if d != 0:
			Sfx.play("menu_move")
			area_index = wrapi(area_index + d, 0, rows.size())
			_scroll = clampi(_scroll, area_index - ROWS + 1, area_index)


## The screen is black: load the file, or begin a new game in Haven Village
## outside the hero's house (the debug game is saved nowhere until asked).
func _start() -> void:
	if start_kind == "list" and rows[area_index][1] == "continue":
		var at := SaveGame.load_slot(file_index)
		if not at.is_empty():
			chosen.emit(at.area, at.entrance, at.health)
			return
	Progress.reset()
	Progress.slot = -1 if start_kind == "debug" else file_index
	DebugMenu.open_on_start = start_kind == "debug"
	if start_kind == "debug":
		# A debug game skips the wake-up scene.
		Progress.set_flag("woke_up")
	chosen.emit(WorldData.START_AREA, WorldData.START_ENTRANCE, -1)


func _accept() -> bool:
	# START decides too (OoT), but not Esc, which shares the pause action.
	var start := Input.is_action_just_pressed("pause") and not Input.is_key_pressed(KEY_ESCAPE)
	return start or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact")


func _back() -> bool:
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_cancel")


## Up/down with OoT-style hold repeat: -1 up, 1 down, 0 nothing this frame.
func _stick(delta: float) -> int:
	return _cursor.step(delta).y


## FileSelect_PulsateCursor: the highlight alpha eases to 70 or 200, then turns.
func _update_pulse(f: float) -> void:
	var target := 200.0 if _pulse_dir == 1 else 70.0
	_pulse = move_toward(_pulse, target, absf(target - _pulse) / maxf(_pulse_timer, 1.0) * f)
	_pulse_timer -= f
	if _pulse_timer <= 0.0:
		_pulse = target
		_pulse_timer = 20.0
		_pulse_dir ^= 1


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	var a := _content
	var w := WINDOW
	w.position.x += _window_x
	_box(w, Color(WINDOW_COLOR, 200.0 / 255.0 * (1.0 - _fill / 255.0)), 4.0)
	var x0 := w.position.x
	# Title labels, cross-fading as a file is opened.
	var k := _k if mode in [Mode.TO_SELECT, Mode.SELECT, Mode.TO_MAIN, Mode.FADE_OUT, Mode.DONE] else 0.0
	PixelFont.draw_mixed(self, Vector2(x0 + 14, w.position.y + 10), "Please select a file.", Color(1, 1, 1, a * (1.0 - k)))
	var question := "Continue your adventure?"
	if list_kind == "erase":
		question = "Erase this file for good?"
	PixelFont.draw_mixed(self, Vector2(x0 + 14, w.position.y + 10), question, Color(1, 1, 1, a * k))
	# Files: the others fade out, the chosen one rises to the top row.
	for i in 3:
		var fa := a * (1.0 - k if i != file_index else 1.0)
		if fa <= 0.0:
			continue
		var y: float = lerpf(FILE_Y[i], FILE_Y[0], k) if i == file_index else FILE_Y[i]
		var btn := Rect2(x0 + 14, y, 54, 15)
		var name_box := Rect2(x0 + 72, y, 178, 15)
		_box(btn, Color(WINDOW_COLOR.darkened(0.25), fa * 0.9), 2.0)
		_box(name_box, Color(WINDOW_COLOR.darkened(0.25), fa * 0.9), 2.0)
		if mode == Mode.MAIN and i == file_index:
			_box(btn.grow(1), Color(HIGHLIGHT, _pulse / 255.0 * 0.8), 2.0)
		PixelFont.draw(self, btn.position + Vector2(8, 4), "FILE %d" % (i + 1), Color(1, 1, 1, fa))
		var info: Dictionary = summaries[i] if i < summaries.size() else {}
		if info.is_empty():
			PixelFont.draw(self, name_box.position + Vector2(8, 4), "NEW ADVENTURE", Color(0.78, 0.86, 1.0, fa * 0.8))
		elif info.get("too_new", false):
			PixelFont.draw(self, name_box.position + Vector2(8, 4), "SAVED BY A NEWER VERSION", Color(1.0, 0.6, 0.5, fa * 0.9))
		else:
			# The hero's name, his hearts and his purse (OoT's file info).
			PixelFont.draw(self, name_box.position + Vector2(6, 4), "GIGGLEBUNS", Color(1, 1, 1, fa))
			# The true ending seen (Beta 1.5.0): a gold star by the name.
			if info.get("complete", false):
				_star(name_box.position + Vector2(68, 7.5), 4.0, Color(1.0, 0.85, 0.3, fa))
			var hx := name_box.position.x + 72
			for h in mini(int(info.hearts), 10):
				var hc := Vector2(hx + h * 7, name_box.position.y + 7.5)
				var heart := HudScreen.tex(HudScreen.HEART_TEX[2])
				if heart:
					draw_texture_rect(heart, Rect2(hc - Vector2(3, 3), Vector2(6, 6)), false, Color(1, 1, 1, fa))
			PixelFont.draw(self, Vector2(name_box.end.x - 30, name_box.position.y + 4), "%3d" % int(info.rupees), Color(0.55, 1.0, 0.45, fa))
	# The highlighted file's progress, under the buttons.
	if mode == Mode.MAIN and file_index < 3 and file_index < summaries.size():
		_draw_completion(summaries[file_index], Rect2(x0 + 14, w.position.y + 116, 236, 58), a)
	# The DEBUG button, under the files.
	var da := a * (1.0 - k)
	if da > 0.0:
		var dbtn := Rect2(DEBUG_BTN.position + Vector2(x0, w.position.y), DEBUG_BTN.size)
		_box(dbtn, Color(Color8(120, 70, 160), da * 0.9), 2.0)
		if mode == Mode.MAIN and file_index == DEBUG_INDEX:
			_box(dbtn.grow(1), Color(HIGHLIGHT, _pulse / 255.0 * 0.8), 2.0)
		PixelFont.draw(self, dbtn.position + Vector2(9, 3), "DEBUG", Color(1, 1, 1, da))
	# The saved file's choices.
	if k > 0.0:
		var list := Rect2(x0 + 14, LIST_TOP, 236, ROWS * ROW_H + 6)
		_box(list, Color(WINDOW_COLOR.darkened(0.35), a * k * 0.9), 3.0)
		for r in ROWS:
			var i := _scroll + r
			if i >= rows.size():
				break
			var y := list.position.y + 3 + r * ROW_H
			if i == area_index:
				draw_rect(Rect2(list.position.x + 3, y, list.size.x - 6, ROW_H - 1), Color(HIGHLIGHT, _pulse / 255.0 * 0.6 * k))
			PixelFont.draw(self, Vector2(list.position.x + 10, y + 2), String(rows[i][0]), Color(1, 1, 1, a * k))
		var arrow := Color(1, 1, 1, a * k * (0.5 + 0.5 * _pulse / 200.0))
		var ax := list.end.x - 9
		if _scroll > 0:
			draw_colored_polygon(PackedVector2Array([Vector2(ax - 4, list.position.y + 8), Vector2(ax + 4, list.position.y + 8), Vector2(ax, list.position.y + 3)]), arrow)
		if _scroll + ROWS < rows.size():
			draw_colored_polygon(PackedVector2Array([Vector2(ax - 4, list.end.y - 8), Vector2(ax + 4, list.end.y - 8), Vector2(ax, list.end.y - 3)]), arrow)
	# Controls along the bottom.
	Glyphs.draw_hint(self, 160, 216, "{A} DECIDE    {B} BACK" if GameManager.using_gamepad else "ENTER DECIDE    ESC BACK", Color(1, 1, 1, a * 0.9))
	if _fill > 0.0:
		draw_rect(GameManager.screen_rect(), Color(0, 0, 0, _fill / 255.0))


## The chosen file's completion: an overall percent with a bar, and its
## items, Goddess Springs and Pieces of Heart (SaveGame.completion).
func _draw_completion(info: Dictionary, r: Rect2, a: float) -> void:
	if info.is_empty() or info.get("too_new", false):
		return
	_box(r, Color(WINDOW_COLOR.darkened(0.35), a * 0.85), 3.0)
	var pct := int(info.get("percent", 0))
	PixelFont.draw(self, r.position + Vector2(8, 6), "COMPLETE", Color(1, 0.9, 0.5, a))
	var bar := Rect2(r.position + Vector2(64, 6), Vector2(128, 7))
	draw_rect(bar, Color(0, 0, 0, 0.5 * a))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * pct / 100.0, bar.size.y)), Color(0.4, 0.9, 0.35, a))
	PixelFont.draw(self, Vector2(bar.end.x + 6, r.position.y + 6), "%d%%" % pct, Color(1, 1, 1, a))
	var rows := [
		["ITEMS", "%d / %d" % [int(info.get("items", 0)), int(info.get("items_max", 20))]],
		["SPRINGS", "%d / %d" % [int(info.get("springs", 0)), int(info.get("springs_max", 5))]],
		["HEART SHARDS", "%d / %d" % [int(info.get("heart_pieces", 0)), int(info.get("heart_pieces_max", SaveGame.HEART_PIECE_COUNT))]],
	]
	for i in rows.size():
		var y := r.position.y + 20 + i * 11
		PixelFont.draw(self, Vector2(r.position.x + 8, y), String(rows[i][0]), Color(0.78, 0.86, 1.0, a))
		PixelFont.draw(self, Vector2(r.position.x + 100, y), String(rows[i][1]), Color(1, 1, 1, a))
	var chapter := int(info.get("chapter", 1))
	if info.get("complete", false):
		PixelFont.draw(self, Vector2(r.end.x - 76, r.position.y + 31), "THE END", Color(1.0, 0.85, 0.3, a))
		_star(Vector2(r.end.x - 26, r.position.y + 34), 4.0, Color(1.0, 0.85, 0.3, a))
	else:
		PixelFont.draw(self, Vector2(r.end.x - 76, r.position.y + 31), "CHAPTER %s" % Story.NUMERALS[chapter], Color(1.0, 0.6, 0.4, a))
	# Time played (Beta 1.6.1).
	PixelFont.draw(self, Vector2(r.end.x - 76, r.position.y + 42), "TIME " + Progress.clock_text(float(info.get("play_time", 0.0))), Color(0.78, 0.86, 1.0, a))


## A small five-pointed star (the file of a game played to its true end).
func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)


## A window panel with clipped corners, like OoT's file select frames.
func _box(r: Rect2, col: Color, corner: float) -> void:
	if col.a <= 0.0:
		return
	var c := corner
	var pts := PackedVector2Array([
		r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), r.position + Vector2(0, c),
	])
	draw_colored_polygon(pts, col)
