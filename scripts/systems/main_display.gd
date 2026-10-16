extends Control
## Shows the game's 320x240 SubViewport scaled up to the window.
##
## The 3D world and HUD are rendered at exactly 320x240 inside GameViewport
## (426x240 with GRAPHICS > ASPECT RATIO 16:9); this node only enlarges that
## image, keeping its shape with black pillar/letterbox bars (integer scale
## factors when possible). The enlargement is bilinear, giving the
## soft picture of an N64 (whose video interface also smoothed the image).

const BASE_SIZE := Vector2(320, 240)

## Use whole-number scale factors. When false, scale to fit.
@export var integer_scaling := true
## Bilinear upscale like the N64. When false, nearest-neighbor (sharp pixels).
## The pause screen's GRAPHICS > ANTI-ALIASING option switches it too.
@export var bilinear := true

## The aspect ratio the window was last shaped for (false = 4:3, the default).
var _wide := false

@onready var view: SubViewportContainer = $GameView
@onready var game_viewport: SubViewport = $GameView/GameViewport


func _enter_tree() -> void:
	GameManager.reset_level()


func _ready() -> void:
	game_viewport.child_entered_tree.connect(_on_layer_added)
	_apply_filter()
	GameManager.settings_changed.connect(_apply_filter)
	GameManager.settings_changed.connect(_apply_resolution)
	_apply_resolution()
	World.boot(game_viewport)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var win := get_viewport_rect().size
	var base := Vector2(GameManager.ui_width(), BASE_SIZE.y)
	var s := minf(win.x / base.x, win.y / base.y)
	if integer_scaling and s >= 1.0 and GameManager.render_height() <= 240:
		s = floorf(s)
	var size := Vector2(game_viewport.size)
	view.size = size
	var k := s * base.y / size.y
	view.scale = Vector2(k, k)
	view.position = ((win - base * s) * 0.5).floor()


## GRAPHICS > RESOLUTION: the world is drawn at the chosen height while every
## 2D layer (HUD, menus, text boxes) still lays itself out at 320x240 and is
## stretched to match (size_2d_override), so nothing moves. Above 240p the
## edges are also smoothed with 4x multisampling.
##
## ASPECT RATIO 16:9 widens the picture (the cameras keep their height of
## view, so more of the world shows at the sides) and the 2D space to 426x240;
## every CanvasLayer is shifted to center its 320x240 layout (_place_layers).
func _apply_resolution() -> void:
	var h := GameManager.render_height()
	var size := Vector2i(GameManager.render_width(h), h)
	if game_viewport.size != size:
		game_viewport.size = size
		game_viewport.size_2d_override = Vector2i(int(GameManager.ui_width()), 240) if h != 240 else Vector2i.ZERO
		game_viewport.size_2d_override_stretch = h != 240
		game_viewport.snap_2d_transforms_to_pixel = h == 240
		game_viewport.snap_2d_vertices_to_pixel = h == 240
	game_viewport.msaa_3d = Viewport.MSAA_4X if h > 240 and GameManager.smoothing else Viewport.MSAA_DISABLED
	_place_layers()
	if _wide != GameManager.widescreen:
		_wide = GameManager.widescreen
		_reshape_window()
	_fit()


## Centers every 320x240 layer in the (possibly wider) 2D space.
func _place_layers() -> void:
	for c in game_viewport.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).offset = Vector2(GameManager.ui_pad(), 0.0)


func _on_layer_added(node: Node) -> void:
	if node is CanvasLayer and node.get_parent() == game_viewport:
		(node as CanvasLayer).offset = Vector2(GameManager.ui_pad(), 0.0)


## A window (not full screen) changes shape with the aspect ratio, keeping
## its height, so the picture fills it without bars.
func _reshape_window() -> void:
	var w := get_window()
	if w.mode != Window.MODE_WINDOWED or GameManager.automation:
		return
	var h := w.size.y
	var width := int(round(h * (16.0 / 9.0 if GameManager.widescreen else 4.0 / 3.0)))
	var screen := DisplayServer.screen_get_usable_rect(w.current_screen)
	if width > screen.size.x:
		width = screen.size.x
		h = int(round(width / (16.0 / 9.0 if GameManager.widescreen else 4.0 / 3.0)))
	var center := w.position + w.size / 2
	w.size = Vector2i(width, h)
	w.position = (center - w.size / 2).clamp(screen.position, screen.end - w.size)


func _apply_filter() -> void:
	var smooth := bilinear and GameManager.smoothing
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if smooth else CanvasItem.TEXTURE_FILTER_NEAREST
