class_name Minimap
extends Control
## Overworld minimap in the bottom-right corner, after OoT's Minimap_Draw
## (z_map_exp.c): the area's silhouette (an IA texture modulated by the prim
## color 0,255,255) at R_OW_MINIMAP_X/Y = 238,164, a yellow-green arrow
## (200,255,0) for the hero and his facing, a red arrow (200,0,0) where he
## entered the area, and dungeon-entrance markers. L toggles it in OoT; here
## the Back/View button or M does (GameManager.minimap_enabled).

const MAP_POS := Vector2(238, 164)
const MAP_SIZE := 64.0
const TINT := Color(0.0, 1.0, 1.0, 0.75)
const HERO := Color8(200, 255, 0)
const ENTRY := Color8(200, 0, 0)
const ICON := Color8(255, 200, 40)

var _tex: Texture2D = null
var _area := ""
## The storey shown in a tower of several (-1 = one-floor area).
var _floor := -1
var _rect := Rect2()
var _icons: Array[Vector2] = []
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	if _area != World.area_id:
		_load_area()
	elif _floor >= 0 and is_instance_valid(GameManager.player) and World.floor_at(GameManager.player.global_position.y) != _floor:
		_load_area()
	queue_redraw()


func _load_area() -> void:
	_area = World.area_id
	_tex = null
	_icons.clear()
	_floor = -1
	var path := "res://assets/textures/world/%s_mini.png" % _area
	if World.floors().size() > 1 and is_instance_valid(GameManager.player):
		_floor = World.floor_at(GameManager.player.global_position.y)
		path = "res://assets/textures/world/%s_mini_f%d.png" % [_area, _floor]
	if not is_instance_valid(World.area_node) or not ResourceLoader.exists(path):
		return
	_tex = load(path)
	_rect = World.area_node.get_meta("rect", Rect2())
	var icons := World.area_node.get_node_or_null("MapIcons")
	if icons:
		for m: Node3D in icons.get_children():
			_icons.append(Vector2(m.position.x, m.position.z))


## World position -> minimap pixel (the play rectangle is centered in a square).
func to_map(p: Vector2) -> Vector2:
	var side := maxf(_rect.size.x, _rect.size.y)
	var origin := _rect.get_center() - Vector2(side, side) * 0.5
	return MAP_POS + (p - origin) / side * MAP_SIZE


func _draw() -> void:
	# Like OoT, the minimap only shows during play (pauseCtx.state <= PAUSE_STATE_INIT).
	# Hidden while a text box is up, as OoT fades its minimap out for messages.
	if _tex == null or not GameManager.minimap_enabled or GameManager.state != GameManager.GameState.PLAYING or Dialogue.active:
		return
	var p := GameManager.player
	if p == null or not is_instance_valid(p):
		return
	# 16:9: out at the right edge with the buttons.
	draw_set_transform(Vector2(GameManager.ui_pad(), 0))
	draw_texture_rect(_tex, Rect2(MAP_POS, Vector2(MAP_SIZE, MAP_SIZE)), false, TINT)
	for icon in _icons:
		var c := to_map(icon)
		draw_rect(Rect2(c - Vector2(2, 2), Vector2(5, 5)), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(c - Vector2(1, 1), Vector2(3, 3)), ICON)
	var entry := World.entry_transform
	if _floor < 0 or World.floor_at(entry.origin.y) == _floor:
		_arrow(to_map(Vector2(entry.origin.x, entry.origin.z)), entry.basis.get_euler().y, ENTRY, 3.5)
	# The hero's arrow blinks very slightly so it reads against busy maps.
	var hero_col := HERO if fmod(_time, 1.0) < 0.85 else HERO.lightened(0.4)
	_arrow(to_map(Vector2(p.global_position.x, p.global_position.z)), p.facing_yaw, hero_col, 4.5)


## Arrow pointing along a Godot yaw (0 = north / up on the map).
func _arrow(c: Vector2, yaw: float, col: Color, size: float) -> void:
	var fwd := Vector2(-sin(yaw), -cos(yaw))
	var side := Vector2(-fwd.y, fwd.x)
	var pts := PackedVector2Array([c + fwd * size, c - fwd * size * 0.6 + side * size * 0.7, c - fwd * size * 0.25, c - fwd * size * 0.6 - side * size * 0.7])
	var outline := PackedVector2Array()
	for q in pts:
		outline.append(c + (q - c) * 1.35)
	draw_colored_polygon(outline, Color(0, 0, 0, 0.75))
	draw_colored_polygon(pts, col)
