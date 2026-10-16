class_name WaystoneMenu
extends Control
## The waystone menu (Beta 1.3.1): every waystone as a picture of its region
## in a 5 x 3 grid (room for 15), in Waystone.ORDER. Stones not yet awakened
## are dark with "???"; the one the hero touched is marked HERE. The stick (or
## the arrows, or the mouse) moves the cursor, A travels, B stays.
##
## Waystone.interact opens it with `choose()` and waits for `chosen`: the area
## to travel to, or "" to stay. The game is paused while it is open.

signal chosen(area: String)

const COLS := 5
const THUMB := Vector2(52, 39)
const GAP := Vector2(6, 9)
const GRID_TOP := 40.0
const PANEL := Rect2(12, 8, 296, 224)
const WINDOW_COLOR := Color8(16, 26, 52)
const RIM := Color8(120, 190, 255)
const CURSOR := Color8(255, 220, 120)
const PICTURES := "res://assets/textures/waystones/"
## A press that opened the menu must not also pick in it.
const INPUT_DELAY := 0.2

var here := ""
var cursor := 0
var _open_time := 0.0
var _blink := 0.0
var _pictures := {}
var _cursor := MenuInput.new(0.35, 0.12)
var _done := false


## Opens the menu over the game, the cursor on `from`. Await `chosen`.
static func choose(from: String) -> WaystoneMenu:
	var layer := CanvasLayer.new()
	layer.name = "WaystoneLayer"
	# Over the area's title card (the transition layer, 20); it closes before any fade.
	layer.layer = 21
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var menu := WaystoneMenu.new()
	menu.name = "WaystoneMenu"
	menu.here = from
	layer.add_child(menu)
	var vp: Viewport = World.area_node.get_viewport() if is_instance_valid(World.area_node) else null
	if vp:
		vp.add_child(layer)
	else:
		(Engine.get_main_loop() as SceneTree).root.add_child(layer)
	return menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for a: String in Waystone.ORDER:
		for suffix in ["", "_dark"]:
			var path: String = PICTURES + a + suffix + ".png"
			if ResourceLoader.exists(path):
				_pictures[a + suffix] = load(path)
	cursor = maxi(Waystone.ORDER.find(here), 0)
	get_tree().paused = true
	if not GameManager.automation:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("menu_select", -4.0)


func _process(delta: float) -> void:
	_open_time += delta
	_blink += delta
	queue_redraw()
	if _done or _open_time < INPUT_DELAY:
		return
	var d := _dir(delta)
	if d != Vector2i.ZERO:
		move_cursor(d)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		pick()
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_cancel") \
			or Input.is_action_just_pressed("pause"):
		close("")


## Moves the cursor one box (wrapping round the grid).
func move_cursor(d: Vector2i) -> void:
	var n := Waystone.ORDER.size()
	var rows := ceili(float(n) / COLS)
	var c := cursor % COLS
	var r := cursor / COLS
	c = wrapi(c + d.x, 0, COLS)
	r = wrapi(r + d.y, 0, rows)
	var next := mini(r * COLS + c, n - 1)
	if next != cursor:
		cursor = next
		_blink = 0.0
		Sfx.play("menu_move", -6.0)


## A on the box under the cursor: travel there, stay (here), or a buzz (not found).
func pick() -> void:
	var a: String = Waystone.ORDER[cursor]
	if a == here:
		close("")
	elif Waystone.awake(a):
		Sfx.play("menu_select", -4.0)
		close(a)
	else:
		Sfx.play("error", -6.0)


func close(area: String) -> void:
	if _done:
		return
	_done = true
	get_tree().paused = false
	if not GameManager.automation and GameManager.state == GameManager.GameState.PLAYING:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if area == "":
		Sfx.play("msg_close", -4.0)
	chosen.emit(area)
	get_parent().queue_free()


func box_rect(i: int) -> Rect2:
	var c := i % COLS
	var r := i / COLS
	var w := COLS * THUMB.x + (COLS - 1) * GAP.x
	var x0 := roundf(160.0 - w * 0.5)
	return Rect2(Vector2(x0 + c * (THUMB.x + GAP.x), GRID_TOP + r * (THUMB.y + GAP.y)), THUMB)


func _gui_input(event: InputEvent) -> void:
	if _done or _open_time < INPUT_DELAY:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var i := _box_at(mm.position)
		if i >= 0 and i != cursor:
			cursor = i
			_blink = 0.0
			Sfx.play("menu_move", -8.0)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_LEFT and _box_at(mb.position) >= 0:
			cursor = _box_at(mb.position)
			pick()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			close("")


func _box_at(p: Vector2) -> int:
	for i in Waystone.ORDER.size():
		if box_rect(i).grow(GAP.x * 0.5).has_point(p):
			return i
	return -1


## Held-direction auto-repeat, like the pause menu's cursor.
func _dir(delta: float) -> Vector2i:
	return _cursor.step(delta)


func _draw() -> void:
	var fade := clampf(_open_time / 0.15, 0.0, 1.0)
	draw_rect(GameManager.screen_rect(), Color(0, 0, 0, 0.5 * fade))
	draw_rect(PANEL, Color(WINDOW_COLOR, 0.94 * fade))
	draw_rect(PANEL.grow(-2), Color(RIM, 0.5 * fade), false, 1.0)
	PixelFont.draw_centered(self, 160, PANEL.position.y + 7, "WAYSTONES", Color(RIM.lightened(0.4), fade))
	PixelFont.draw_centered(self, 160, PANEL.position.y + 17, "WHERE WILL THE WAYSTONE TAKE YOU?", Color(1, 1, 1, 0.75 * fade))
	for i in Waystone.ORDER.size():
		_draw_box(i, fade)
	# The name of the stone under the cursor, and the buttons.
	var a: String = Waystone.ORDER[cursor]
	var found := Waystone.awake(a) or a == here
	var label := WorldData.title(a) if found else "???"
	if a == here:
		label += "  (YOU ARE HERE)"
	PixelFont.draw_centered(self, 160, PANEL.end.y - 27, label, Color(CURSOR, fade))
	var hint := "{A} TRAVEL    {B} STAY" if GameManager.using_gamepad else "SPACE TRAVEL    LMB / ESC STAY"
	Glyphs.draw_hint(self, 160, PANEL.end.y - 14, hint, Color(1, 1, 1, 0.8 * fade))


func _draw_box(i: int, fade: float) -> void:
	var a: String = Waystone.ORDER[i]
	var r := box_rect(i)
	var found := Waystone.awake(a) or a == here
	draw_rect(r.grow(1), Color(0, 0, 0, fade))
	var tex: Texture2D = _pictures.get(a if found else a + "_dark")
	if tex:
		draw_texture_rect(tex, r, false, Color(1, 1, 1, fade))
	else:
		draw_rect(r, Color(0.12, 0.12, 0.14, fade))
	if not found:
		PixelFont.draw_centered(self, r.get_center().x, r.get_center().y - 4, "???", Color(0.75, 0.75, 0.8, fade))
	elif a == here:
		var tag := Rect2(r.position + Vector2(2, 2), Vector2(PixelFont.measure("HERE").x + 4, 9))
		draw_rect(tag, Color(0, 0, 0, 0.6 * fade))
		PixelFont.draw(self, tag.position + Vector2(2, 1), "HERE", Color(RIM.lightened(0.3), fade), 1, false)
	if i == cursor:
		var pulse := 0.6 + 0.4 * absf(sin(_blink * 4.0))
		draw_rect(r.grow(2), Color(CURSOR, pulse * fade), false, 2.0)
