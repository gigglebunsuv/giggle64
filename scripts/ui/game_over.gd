class_name GameOver
extends Control
## Game over (Beta 1.5.0), after OoT's: when the hero falls with no fairy in a
## bottle, the death pose holds, the picture sinks into a dark red and then to
## black, GAME OVER rises out of it to its own short theme ("game_over",
## played once), and a choice follows:
##   CONTINUE          back where the hero last came in (an area's road or
##                     door, or a dungeon's entrance) with three hearts, as
##                     OoT's Continue puts Link at the dungeon's door
##                     (Play_SetupRespawnPoint RESPAWN_MODE_DOWN / the
##                     "gameover" path through Gameplay_Init)
##   SAVE & CONTINUE   the same, after writing the file
##   SAVE & QUIT       the file is written and the game goes back to the title
## A game with no file (the debug start) offers CONTINUE and QUIT only.
##
## PlayerController opens it (open()) once the death pose has played; the
## game is paused meanwhile. Tests set `auto_respawn` to keep the old instant
## respawn, so a test whose hero falls by accident never waits on the menu.

signal closed(choice: String)

## The old behavior: get straight back up at the spawn point, full health.
static var auto_respawn := false
## Hearts (in halves) a continued game starts with (OoT: 0x30 = 3 hearts).
const CONTINUE_HEALTH := 6

const RED := Color(0.32, 0.02, 0.03)
const GOLD := Color(1.0, 0.82, 0.45)
const CURSOR := Color8(255, 220, 120)
## Seconds into the screen: red, black, the words, the choices.
const T_RED := 0.9
const T_BLACK := 1.8
const T_WORDS := 2.0
const T_MENU := 3.6

var options: Array[String] = []
var cursor := 0
var _time := 0.0
var _done := false
var _cursor := MenuInput.new(0.35, 0.15)


## Opens the screen over the game (one at a time).
static func open() -> GameOver:
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group("game_over"):
		return n as GameOver
	var layer := CanvasLayer.new()
	layer.name = "GameOverLayer"
	layer.layer = 21
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var g := GameOver.new()
	g.name = "GameOver"
	layer.add_child(g)
	var vp: Viewport = World.area_node.get_viewport() if is_instance_valid(World.area_node) else null
	if vp:
		vp.add_child(layer)
	else:
		tree.root.add_child(layer)
	return g


## True while the screen is up.
static func showing() -> bool:
	return not (Engine.get_main_loop() as SceneTree).get_nodes_in_group("game_over").is_empty()


func _ready() -> void:
	add_to_group("game_over")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if Progress.slot >= 0:
		options = ["CONTINUE", "SAVE & CONTINUE", "SAVE & QUIT"]
	else:
		options = ["CONTINUE", "QUIT"]
	if World.battle != "":
		World.battle = ""
	World.play_track("")
	World.stop_ambience()
	Dialogue.cancel()
	get_tree().paused = true


func _process(delta: float) -> void:
	var was := _time
	_time += delta
	queue_redraw()
	if was < T_WORDS and _time >= T_WORDS:
		World.play_score("game_over")
	if _done or _time < T_MENU:
		return
	var d := _cursor.step(delta)
	if d.y != 0:
		cursor = wrapi(cursor + d.y, 0, options.size())
		Sfx.play("menu_move", -6.0)
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pause"):
		pick(cursor)


func _gui_input(event: InputEvent) -> void:
	if _done or _time < T_MENU:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var i := _row_at(mm.position)
		if i >= 0 and i != cursor:
			cursor = i
			Sfx.play("menu_move", -8.0)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _row_at(mb.position) >= 0:
		pick(_row_at(mb.position))


func _row_at(p: Vector2) -> int:
	for i in options.size():
		if Rect2(100, _row_y(i) - 2, 120, 12).has_point(p):
			return i
	return -1


func _row_y(i: int) -> float:
	return 140.0 + i * 16.0


## Chooses option `i` (tests call it directly).
func pick(i: int) -> void:
	if _done:
		return
	_done = true
	cursor = i
	var choice: String = options[i]
	Sfx.play("menu_select", -3.0)
	if choice.begins_with("SAVE"):
		_save()
	World.stop_score()
	closed.emit(choice)
	if choice == "SAVE & QUIT" or choice == "QUIT":
		get_parent().queue_free()
		GameManager.return_to_title()
		return
	World.fade = 1.0
	visible = false
	await World.continue_after_game_over(CONTINUE_HEALTH)
	if is_instance_valid(get_parent()):
		get_parent().queue_free()


## Writes the file as Continue will find it: three hearts, at the entrance.
func _save() -> void:
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.health = mini(CONTINUE_HEALTH, p.health.max_health)
	SaveGame.save(Progress.slot)


func _draw() -> void:
	var r := GameManager.screen_rect()
	# The picture sinks into red, then black.
	var red := clampf(_time / T_RED, 0.0, 1.0)
	draw_rect(r, Color(RED, 0.65 * red))
	var black := clampf((_time - T_RED) / (T_BLACK - T_RED), 0.0, 1.0)
	if black > 0.0:
		draw_rect(r, Color(0, 0, 0, black))
	var words := clampf((_time - T_WORDS) / 1.2, 0.0, 1.0)
	if words > 0.0:
		var glow := 0.75 + 0.25 * sin(_time * 1.6)
		PixelFont.draw_centered(self, 160, 96, "GAME OVER", Color(GOLD.r * glow, GOLD.g * glow * 0.6, GOLD.b * 0.4, words), 3)
	var menu := clampf((_time - T_MENU) / 0.4, 0.0, 1.0)
	if menu <= 0.0:
		return
	for i in options.size():
		var y := _row_y(i)
		var sel := i == cursor
		var col := Color(CURSOR, menu) if sel else Color(0.75, 0.75, 0.8, menu)
		PixelFont.draw_centered(self, 160, y, options[i], col)
		if sel:
			var w := PixelFont.measure(options[i]).x
			var pulse := 0.6 + 0.4 * absf(sin(_time * 4.0))
			PixelFont.draw(self, Vector2(160 - w * 0.5 - 12, y), ">", Color(CURSOR, menu * pulse))
	var hint := "{A} CHOOSE" if GameManager.using_gamepad else "SPACE CHOOSE"
	Glyphs.draw_hint(self, 160, 210, hint, Color(1, 1, 1, 0.6 * menu))
