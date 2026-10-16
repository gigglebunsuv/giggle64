class_name HudScreen
extends Control
## The HUD, laid out like OoT's interface (z_parameter.c, z_lifemeter.c) at
## the 320x240 logical resolution: life hearts, the rupee counter (and small
## keys in a dungeon), the B button with the equipped sword, the A button with
## its action word, the two item buttons where OoT has C-Left and C-Right, and
## the small first-person button in C-Up's place. Also the foe counter in the
## test area, context hints, the Z-target / aiming letterbox and the reticle.
##
## As in OoT the buttons and hearts are smooth textures (tools/gen_media.gd)
## tinted per button, and the item pictures are renders of the items' 3D
## models (tools/render_icons.gd), drawn with bilinear filtering.

## OoT letterbox while Z-targeting (CAM_LETTERBOX_MEDIUM in z_camera.c): 27 lines
## top and bottom, sliding 10 lines per 20 Hz game frame (Letterbox_Update).
const LETTERBOX_SIZE := 27.0
const LETTERBOX_SPEED := 200.0

## OoT's C-button yellow and the ammo count colors (green when full).
const C_YELLOW := Color(1.0, 0.86, 0.12)
const AMMO := Color(1, 1, 1)
const AMMO_FULL := Color(0.47, 1.0, 0.0)

## Button colors (interface.h: B 0,150,0; A 90,90,255; z_construct.c's
## R_C_BTN_COLOR 255,160,0) and positions (top-left corner and width, from
## B_BUTTON_X/Y, A_BUTTON_X/Y, C_*_BUTTON_X/Y and R_ITEM_BTN_WIDTH).
const B_COLOR := Color8(0, 150, 0)
const A_COLOR := Color8(90, 90, 255)
const C_COLOR := Color8(255, 160, 0)
const B_RECT := Rect2(160, 17, 29, 29)
const A_RECT := Rect2(188, 10, 28, 28)
const C_LEFT_RECT := Rect2(227, 18, 27, 27)
const C_RIGHT_RECT := Rect2(271, 18, 27, 27)
const C_UP_RECT := Rect2(254, 14, 16, 16)
## Item pictures: 30 on B, 24 on the C buttons (R_ITEM_ICON_WIDTH).
const B_ICON := 26.0
const C_ICON := 22.0
## Hearts (Health_DrawMeter): from (30, 26), 10 apart. OoT fits its 20 in two
## rows of ten; Giggle 64's 22 sit in two rows of eleven.
const HEARTS_AT := Vector2(25, 21)
const HEART_STEP := 10.0
const HEART_SIZE := 10.0
const HEARTS_PER_ROW := 11
## The magic meter's scale: the doubled meter (96) is as long as a full row
## of hearts, so the single one reaches halfway along it.
const MAGIC_PX := (HEARTS_PER_ROW * HEART_STEP - 6.0) / (2.0 * Progress.MAGIC_SINGLE)

const BUTTON_TEX := "res://assets/textures/hud_button.png"
const HEART_TEX := ["res://assets/textures/hud_heart_empty.png", "res://assets/textures/hud_heart_half.png", "res://assets/textures/hud_heart_full.png"]

## Textures drawn by the HUD and the pause pages, kept loaded (a texture
## loaded inside _draw must stay referenced, or it renders white).
static var _textures := {}

var _player: PlayerController
var _hp := 10
var _max_hp := 10
var _alive := 0
var _total := 0
var _time := 0.0
var _clear_time := -1.0
## Current letterbox height in lines.
var letterbox := 0.0
## The HUD fades out while a cutscene plays.
var hud_alpha := 1.0


## The rupee count on screen. As in OoT (Interface_Update's rupeeAccumulator)
## it counts toward the purse one rupee per 20 Hz frame with a tick, ten at a
## time while 50 or more are being paid out.
var shown_rupees := -1
var _rupee_step := 0.0
## Health_UpdateBeatingHeart: the alarm sounds each time the beat (10 frames
## out, 10 back) comes round while health is critical.
var _beat := 0.0

## The A button flips over (OoT turns it on its side and back) when its word changes.
var _a_label := ""
var _a_flip := 1.0
## The magic meter's yellow "spent" part shrinks down to the real level.
var _magic_shown := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Smooth, bilinear pictures like the N64's (the icons carry mipmaps).
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var minimap := Minimap.new()
	minimap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(minimap)
	var box := MessageBox.new()
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(box)
	GameManager.enemy_count_changed.connect(_on_enemy_count)
	# The HUD (and minimap) only redraw in _process, which stops while the
	# tree is paused: a change of state (into TITLE for a debug attract scene,
	# or back) must clear or restore what they last drew.
	GameManager.state_changed.connect(func(_s: int) -> void:
		queue_redraw()
		minimap.queue_redraw())
	_alive = GameManager.enemies_alive
	_total = GameManager.enemies_total


func _on_enemy_count(alive: int, total: int) -> void:
	_alive = alive
	_total = total
	if total == 0:
		_clear_time = -1.0
	elif alive == 0:
		_clear_time = 0.0


func _on_health(current: int, maximum: int) -> void:
	_hp = current
	_max_hp = maximum


func _process(delta: float) -> void:
	# The hero is a new node in every area: follow whichever one is current.
	if not is_instance_valid(_player):
		_player = null
	if GameManager.player and _player != GameManager.player:
		_player = GameManager.player
		_player.health.health_changed.connect(_on_health)
		_hp = _player.health.health
		_max_hp = _player.health.max_health
	_time += delta
	if _clear_time >= 0.0:
		_clear_time += delta
	# CAM_LETTERBOX_MEDIUM while Z-targeting and while aiming (CAM_MODE_AIM_ADULT).
	var z := _player != null and (_player.is_z_targeting() or _player.state == PlayerController.State.AIM)
	# Cutscenes close in to 32 lines (z_demo.c Letterbox_SetSizeTarget(32))
	# and the HUD fades out (HUD_VISIBILITY_NOTHING).
	var want := Cutscene.LETTERBOX if Cutscene.active else (LETTERBOX_SIZE if z else 0.0)
	letterbox = move_toward(letterbox, want, LETTERBOX_SPEED * delta)
	hud_alpha = move_toward(hud_alpha, 0.0 if Cutscene.active else 1.0, delta * 4.0)
	for c in get_children():
		if c is Minimap:
			(c as Minimap).visible = hud_alpha > 0.5
	var label := _player.a_action_label().to_upper() if _player else ""
	if label != _a_label:
		_a_label = label
		_a_flip = 0.0
	_a_flip = minf(_a_flip + delta / 0.15, 1.0)
	_update_rupees(delta)
	_update_magic(delta)
	_update_alarm(delta)
	queue_redraw()


func _update_magic(delta: float) -> void:
	if _magic_shown < Progress.magic:
		_magic_shown = Progress.magic
	else:
		_magic_shown = move_toward(_magic_shown, Progress.magic, 30.0 * delta)


func _update_rupees(delta: float) -> void:
	var target := Progress.rupees
	if shown_rupees < 0 or GameManager.state != GameManager.GameState.PLAYING:
		shown_rupees = target
		return
	if shown_rupees == target:
		_rupee_step = 0.0
		return
	_rupee_step += delta
	while _rupee_step >= 0.05 and shown_rupees != target:
		_rupee_step -= 0.05
		var diff := target - shown_rupees
		shown_rupees += (-10 if diff <= -50 else signi(diff))
		Sfx.play("rupee_tick", -12.0, 0.0)


## Health_IsCritical: one heart or less with up to 5 hearts (OoT's 0x10),
## 1.5 up to 10, 2 up to 15, and 2.75 beyond.
static func is_critical(hp: int, max_hp: int) -> bool:
	var critical := 2 if max_hp <= 10 else (3 if max_hp <= 20 else (4 if max_hp <= 30 else 5))
	return hp > 0 and hp <= critical


func _update_alarm(delta: float) -> void:
	var on := _player != null and GameManager.state == GameManager.GameState.PLAYING and not get_tree().paused 		and not Dialogue.active and is_critical(_hp, _max_hp)
	if not on:
		_beat = 0.0
		return
	_beat += delta
	if _beat >= 1.0:
		_beat -= 1.0
		Sfx.play("low_health", -9.0, 0.0)


func _draw() -> void:
	if GameManager.state == GameManager.GameState.TITLE:
		return
	# The hero was replaced after this frame's _process (leaving the title):
	# skip one frame rather than read the old one.
	if _player != GameManager.player:
		return
	# Z-target letterbox bars. As in OoT the HUD stays put and draws over them.
	var bar := roundf(letterbox)
	if bar > 0.0:
		var full := GameManager.screen_rect()
		draw_rect(Rect2(full.position.x, 0, full.size.x, bar), Color.BLACK)
		draw_rect(Rect2(full.position.x, 240 - bar, full.size.x, bar), Color.BLACK)
		# A scene watched before can be skipped (Cutscene.skip).
		if Cutscene.can_skip() and bar >= Cutscene.LETTERBOX - 1.0 and not Dialogue.active:
			Glyphs.draw_hint(self, full.end.x - 44, 240 - bar * 0.5 - 4, "{START} SKIP", Color(1, 1, 1, 0.75))
	# The aiming reticle for the bow (EnArrow draws it) and the boomerang
	# (GRAPHICS > CROSSHAIR hides it).
	if hud_alpha < 0.5:
		return
	if reticle_shown():
		_draw_reticle()
	if _player and _player.items and _player.items.lens_on:
		_draw_lens()
	# 16:9: the left group (hearts, counters, carrots) moves out to the left
	# edge and the buttons to the right, as in the widescreen OoT ports.
	var pad := GameManager.ui_pad()
	draw_set_transform(Vector2(-pad, 0))
	_draw_hearts()
	_draw_magic()
	if _total > 0 and World.area_id == "test_area":
		PixelFont.draw(self, Vector2(25, 33 + 10 * (heart_rows() - 1)), "FOES %d" % _alive, Color(0.95, 0.85, 0.6))
	_draw_counters()
	draw_set_transform(Vector2(pad, 0))
	_draw_buttons()
	draw_set_transform(Vector2(-pad, 0))
	_draw_riding_carrots()
	draw_set_transform(Vector2.ZERO)
	_draw_course_clock()
	_draw_range_clock()
	_draw_chill()
	_draw_messages()


## Fishing: the hint, the cast's wind-up and the line's tension.
func _draw_fishing(spot: FishingSpot, pad: bool) -> void:
	Glyphs.draw_hint(self, 160, 240.0 - 17.0, spot.hint(pad), Color(1, 1, 1, 0.9))
	var bar := Rect2(110, 196, 100, 6)
	if spot.phase == FishingSpot.Phase.READY and spot.charge > 0.0:
		draw_rect(bar.grow(1), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * spot.charge, bar.size.y)), Color(0.4, 0.8, 1.0))
		PixelFont.draw_centered(self, 160, 186, "CAST", Color(1, 1, 1, 0.9))
	elif spot.phase == FishingSpot.Phase.HOOKED:
		draw_rect(bar.grow(1), Color(0, 0, 0, 0.7))
		var col := Color(0.4, 1.0, 0.3).lerp(Color(1.0, 0.2, 0.15), spot.tension)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * spot.tension, bar.size.y)), col)
		PixelFont.draw_centered(self, 160, 186, "TENSION", Color(1, 1, 1, 0.9))


## On horseback, the six carrots (OoT's Interface_DrawHorseBoosts) under the
## hearts; and the jumping course's clock while it runs.
func _draw_riding_carrots() -> void:
	if _player and _player.is_riding():
		var n: int = _player.horse.carrots
		var row_y := HEARTS_AT.y + HEART_STEP * heart_rows() + 4.0
		for i in Horse.CARROTS:
			var c := Vector2(HEARTS_AT.x + 5 + i * 11, row_y)
			var col := Color(1.0, 0.55, 0.1) if i < n else Color(0.3, 0.3, 0.3, 0.6)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, -3), c + Vector2(2.5, -3), c + Vector2(0, 5)]), col)
			draw_rect(Rect2(c + Vector2(-1.5, -6), Vector2(3, 3)), Color(0.3, 0.75, 0.2) if i < n else Color(0.25, 0.3, 0.25, 0.6))


func _draw_course_clock() -> void:
	var course := FenceCourse.current
	if is_instance_valid(course) and course.phase == FenceCourse.Phase.RUNNING:
		text(self, Vector2(160, 52), "%02d:%04.1f" % [int(course.time) / 60, fmod(course.time, 60.0)], 14, Color(1, 1, 0.8))
		text(self, Vector2(160, 62), "JUMPS %d / %d" % [course.jumps, course.fences_needed], 8, Color(1, 0.9, 0.7))


## True while the aiming reticle is drawn.
## Clover's target range while a round runs: the time left and the golds hit.
func _draw_range_clock() -> void:
	var r := ArcheryRange.current
	if is_instance_valid(r) and r.running:
		text(self, Vector2(160, 52), "%02d:%04.1f" % [int(r.time_left) / 60, fmod(r.time_left, 60.0)], 14, Color(1, 1, 0.8) if r.time_left > 10.0 else Color(1, 0.5, 0.4))
		text(self, Vector2(160, 62), "GOLDS %d / %d" % [r.hits(), r.target_count()], 8, Color(1, 0.9, 0.7))


## Frostpeak Hollow's cold, after OoT's heat timer: a snowflake and the
## seconds before the cold starts to bite (red and shaking once it does).
func _draw_chill() -> void:
	if not is_instance_valid(_player) or not _player.chilled():
		return
	var left := _player.chill_left
	# Under the hearts and the magic meter, as OoT shows its heat timer.
	var c := Vector2(48.0 - GameManager.ui_pad(), 52.0 + 10.0 * (heart_rows() - 1))
	var biting := left <= 0.0
	if biting:
		c.x += sin(_time * 40.0) * 1.0
	var col := Color(1.0, 0.45, 0.4) if biting else (Color(0.75, 0.9, 1.0) if left > 20.0 else Color(1.0, 0.85, 0.5))
	for i in 3:
		var a := PI * i / 3.0
		var d := Vector2(cos(a), sin(a)) * 5.0
		draw_line(c + Vector2(-18, -3) - d, c + Vector2(-18, -3) + d, col, 1.5)
	text(self, c + Vector2(-10, -8), "COLD %d" % int(ceil(left)) if not biting else "FREEZING!", 10, col, false)


func reticle_shown() -> bool:
	if GameManager.crosshair and _player != null and _player.riding_aim:
		return true
	return GameManager.crosshair and _player != null and _player.state == PlayerController.State.AIM 		and _player.aim_item in ["bow", "boomerang", "hookshot"]


## The aiming mark at the center of the view: faint while the bow is drawn or
## the boomerang readied, red once it can fly, and yellow-green while it lies
## on something the shot can hit within its reach.
func _draw_reticle() -> void:
	var c := Vector2(160, 120)
	var ready: bool = _player.bow_phase == PlayerController.Bow.DRAWN if _player.aim_item in ["bow", "hookshot"] 		else _player._boom_ready >= _player.boomerang_ready_time
	var col := Color(1.0, 0.25, 0.15, 0.9) if ready else Color(1, 1, 1, 0.55)
	if _player.aim_on_target:
		col = Color(0.75, 1.0, 0.2, 0.95) if ready else Color(0.85, 1.0, 0.5, 0.7)
	draw_rect(Rect2(c.x - 7, c.y, 4, 1), col)
	draw_rect(Rect2(c.x + 4, c.y, 4, 1), col)
	draw_rect(Rect2(c.x, c.y - 7, 1, 4), col)
	draw_rect(Rect2(c.x, c.y + 4, 1, 4), col)
	draw_rect(Rect2(c.x - 1, c.y - 1, 3, 3), col)


# --- Textures and text ----------------------------------------------------------

static func tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## The rendered picture of an item, sword or shield ("bow", "sword_red"...).
static func icon(icon_name: String) -> Texture2D:
	return tex(Equipment.icon_path(icon_name))


## The HUD's smooth font (OoT's interface text is smooth, not pixel art).
static func font() -> Font:
	if not _textures.has("font"):
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 0.6
		_textures["font"] = f
	return _textures["font"]


## Smooth text with a dark outline; `pos` is the center of the baseline
## (or its left end when not `centered`).
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, centered := true, outline := Color(0, 0, 0, 0.8)) -> void:
	var f := font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos - Vector2(w * 0.5 if centered else 0.0, 0.0)
	if outline.a > 0.0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, outline)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## A picture centered on `c`, `side` pixels across.
static func draw_icon(ci: CanvasItem, t: Texture2D, c: Vector2, side: float, tint := Color(1, 1, 1)) -> void:
	if t:
		ci.draw_texture_rect(t, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), false, tint)


# --- Counters and hearts ---------------------------------------------------------

## Rupees at the bottom left (OoT draws the 16x16 icon at 26, 206 and the
## digits from x 42, zero-padded to the wallet: green when the wallet is full,
## gray at none). In a dungeon the small keys sit above them at y 190.
func _draw_counters() -> void:
	draw_icon(self, icon("rupee"), Vector2(34, 214), 16)
	var n := shown_rupees if shown_rupees >= 0 else Progress.rupees
	var digits := 2 if Progress.wallet < 100 else 3
	var col := Color8(120, 255, 0) if n >= Progress.wallet else (Color(1, 1, 1) if n > 0 else Color(0.62, 0.62, 0.62))
	text(self, Vector2(43, 220), str(n).pad_zeros(digits), 13, col, false)
	var d := World.dungeon_id()
	if d != "":
		draw_icon(self, icon("small_key"), Vector2(34, 197), 15)
		text(self, Vector2(43, 203), str(Progress.keys(d)), 13, Color(1, 1, 1), false)


## How many rows the hearts take.
func heart_rows() -> int:
	return maxi(int(ceil(_max_hp / 2.0)) - 1, 0) / HEARTS_PER_ROW + 1


## OoT's life meter: a row of hearts (two at most), the one being emptied
## beating (it swells and settles, faster when health is low).
func _draw_hearts() -> void:
	var hearts := int(ceil(_max_hp / 2.0))
	var beating := clampi(int(ceil(_hp / 2.0)) - 1, 0, hearts - 1)
	var rate := 6.0 if _hp <= 4 else 3.5
	for i in hearts:
		var fill := clampi(_hp - i * 2, 0, 2)
		var c := HEARTS_AT + Vector2((i % HEARTS_PER_ROW) * HEART_STEP, (i / HEARTS_PER_ROW) * HEART_STEP) + Vector2(HEART_SIZE, HEART_SIZE) * 0.5
		var side := HEART_SIZE
		if i == beating and _hp > 0:
			side *= 1.0 + 0.18 * maxf(sin(_time * rate), 0.0)
		if Progress.defense > 1:
			# Double defense: OoT rims each heart in white.
			draw_icon(self, tex(HEART_TEX[2]), c + Vector2(0, 0.3), side * 1.28, Color(9, 9, 9))
		draw_icon(self, tex(HEART_TEX[fill]), c, side)


## Looking through Mira's Looking Glass: the view inside a round silver
## rim, the world beyond it dimmed violet (OoT's Lens of Truth circle).
func _draw_lens() -> void:
	var c := Vector2(160, 120)
	var r := 92.0 + sin(_time * 3.0) * 1.5
	# The dimmed outside, as a band of quads out past the screen's corners.
	var steps := 40
	var dim := Color(0.18, 0.05, 0.3, 0.55)
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		draw_colored_polygon(PackedVector2Array([c + d0 * r, c + d1 * r, c + d1 * 340.0, c + d0 * 340.0]), dim)
	draw_arc(c, r, 0.0, TAU, 48, Color(0.85, 0.85, 0.95, 0.9), 2.5, true)
	draw_arc(c, r + 3.0, 0.0, TAU, 48, Color(0.45, 0.35, 0.65, 0.8), 2.0, true)


## OoT's magic meter (Magic_DrawMeter) under the hearts once the hero has
## magic: a rounded frame as long as the meter (48 units, 96 doubled: then as
## long as a row of hearts, MAGIC_PX) with the
## fill in Giggle 64's blue (OoT uses green); it flashes yellow for a moment
## when magic is spent.
const MAGIC_BLUE := Color8(30, 110, 255)


func _draw_magic() -> void:
	if Progress.magic_max <= 0:
		return
	var y := HEARTS_AT.y + heart_rows() * HEART_STEP + 1.0
	var x := HEARTS_AT.x
	var w := roundf(Progress.magic_max * MAGIC_PX)
	var frame := Rect2(x, y, w + 6.0, 9.0)
	draw_rect(frame.grow(1.0), Color(0, 0, 0, 0.55))
	draw_rect(frame, Color(0.92, 0.92, 0.95))
	draw_rect(frame.grow(-1.0), Color(0.08, 0.08, 0.1))
	if _magic_shown > Progress.magic:
		draw_rect(Rect2(x + 3.0, y + 2.0, _magic_shown * MAGIC_PX, 5.0), Color8(250, 250, 0))
	var fill := Rect2(x + 3.0, y + 2.0, Progress.magic * MAGIC_PX, 5.0)
	draw_rect(fill, MAGIC_BLUE)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 1.5)), Color(0.6, 0.8, 1.0, 0.7))


# --- Buttons ---------------------------------------------------------------------

func _draw_buttons() -> void:
	if GameManager.hud_modern:
		_draw_buttons_modern()
		return
	var attacking := _player != null and _player.combat.is_attacking()
	# B: the equipped sword.
	var bc := B_RECT.get_center()
	_draw_button(B_RECT, B_COLOR, attacking)
	draw_icon(self, icon("sword_" + Equipment.sword_look(Progress.sword)), bc, B_ICON)
	_glyph(bc + Vector2(0, B_RECT.size.y * 0.5 + 6), "B")
	# A: the action word (OoT's do-action icon), on a button that flips over
	# whenever the word changes.
	var ac := A_RECT.get_center()
	var squash := absf(cos(_a_flip * PI)) if _a_flip < 1.0 else 1.0
	var r := Rect2(A_RECT.position.x, ac.y - A_RECT.size.y * 0.5 * squash, A_RECT.size.x, A_RECT.size.y * squash)
	_draw_button(r, A_COLOR, _a_label != "")
	if _a_label != "" and _a_flip >= 0.5:
		text(self, ac + Vector2(0, 3), _a_label.capitalize(), 9, Color(1, 1, 1), true, Color(0.05, 0.05, 0.25, 0.9))
	_glyph(ac + Vector2(0, A_RECT.size.y * 0.5 + 6), "A")
	# The item buttons in C-Left's and C-Right's places, and first person on C-Up.
	_draw_item_button(C_LEFT_RECT, "item_x", "X")
	_draw_item_button(C_RIGHT_RECT, "item_y", "Y")
	var looking := _player != null and _player.is_first_person()
	_draw_button(C_UP_RECT, C_COLOR, looking)
	var ec := C_UP_RECT.get_center()
	draw_circle(ec, 3.6, Color(0.25, 0.12, 0.0, 0.85), true, -1.0, true)
	draw_circle(ec, 2.4, Color(1, 1, 1), true, -1.0, true)
	draw_circle(ec, 1.2, Color(0.1, 0.1, 0.2), true, -1.0, true)
	_glyph(ec + Vector2(0, -C_UP_RECT.size.y * 0.5 - 1), "RB")


## The MODERN layout: the four face buttons in a diamond as on today's pads
## (top: the second item, left: the first, right: the sword, bottom: the
## action, its word beside it), each marked with the pad's own glyph; the
## look button above.
const DIAMOND := Vector2(268, 44)
const DIAMOND_STEP := 18.0


func _draw_buttons_modern() -> void:
	var fam := Glyphs.family()
	var attacking := _player != null and _player.combat.is_attacking()
	var north := DIAMOND + Vector2(0, -DIAMOND_STEP)
	var west := DIAMOND + Vector2(-DIAMOND_STEP, 0)
	var east := DIAMOND + Vector2(DIAMOND_STEP, 0)
	var south := DIAMOND + Vector2(0, DIAMOND_STEP)
	# Right: the sword.
	_modern_disc(east, "B", fam, attacking)
	draw_icon(self, icon("sword_" + Equipment.sword_look(Progress.sword)), east, 15)
	# Left and top: the two items.
	for pair in [[west, "item_x", "X"], [north, "item_y", "Y"]]:
		var c: Vector2 = pair[0]
		var action: String = pair[1]
		var item := Progress.item_on(action)
		var active: bool = _player != null and _player.is_aiming() and _player._aim_button == action
		_modern_disc(c, pair[2], fam, active)
		if item != "":
			var dim := item == "boomerang" and _player != null and is_instance_valid(_player.boomerang)
			draw_icon(self, icon(Progress.icon_id(item)), c, 14, Color(0.5, 0.5, 0.5, 0.8) if dim else Color(1, 1, 1))
			if Progress.ammo_of(item) >= 0:
				var n := Progress.ammo_of(item)
				var col := Color8(120, 255, 0) if n >= Progress.ammo_max_of(item) else (AMMO if n > 0 else Color8(100, 100, 100))
				text(self, c + Vector2(-10, 9), str(n), 8, col, false)
	# Bottom: the action, its word on a pill to the left.
	_modern_disc(south, "A", fam, _a_label != "")
	if _a_label != "":
		var word := _a_label.capitalize()
		var w := font().get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 8.0
		var pill := Rect2(south.x - 12.0 - w, south.y - 5.5, w, 11.0)
		draw_rect(pill, Color(0.05, 0.05, 0.12, 0.7))
		text(self, pill.get_center() + Vector2(0, 3), word, 9, Color(1, 1, 1), true, Color(0, 0, 0, 0))
	# Above: first-person view.
	var look := DIAMOND + Vector2(-34, -30)
	var looking := _player != null and _player.is_first_person()
	draw_circle(look, 5.5, Color(0.08, 0.08, 0.14, 0.75 if not looking else 0.95), true, -1.0, true)
	draw_circle(look, 2.6, Color(1, 1, 1), true, -1.0, true)
	draw_circle(look, 1.2, Color(0.1, 0.1, 0.2), true, -1.0, true)
	Glyphs.draw_badge(self, look + Vector2(7, -4), "RB", 0.95, fam)


## A face button: a dark disc ringed in the button's color (Xbox's colors,
## PlayStation's shape colors, Nintendo's gray), its glyph at the corner.
func _modern_disc(c: Vector2, token: String, fam: String, active: bool) -> void:
	var ring := Color(0.75, 0.75, 0.8)
	if fam == "xbox":
		ring = Glyphs.XBOX_COLORS[token]
	elif fam == "playstation":
		ring = Glyphs.PS_COLORS[token]
	draw_circle(c, 9.5, Color(0.06, 0.06, 0.12, 0.8 if active else 0.62), true, -1.0, true)
	draw_arc(c, 9.0, 0.0, TAU, 24, ring.lightened(0.25) if active else ring, 1.4, true)
	if fam == "keyboard":
		var w := Glyphs.badge_width(token, fam)
		Glyphs.draw_badge(self, c + Vector2(-w * 0.5, 9.0), token, 0.9, fam)
	else:
		Glyphs.draw_badge(self, c + Vector2(4.5, 2.5), token, 1.0, fam)


func _draw_item_button(rect: Rect2, action: String, token: String) -> void:
	var item := Progress.item_on(action)
	var active := _player != null and _player.is_aiming() and _player._aim_button == action
	var c := rect.get_center()
	_draw_button(rect, C_COLOR, active)
	if item == "":
		# OoT's empty C button shows its arrow.
		var d := -1.0 if action == "item_x" else 1.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(d * 5, 0), c + Vector2(-d * 3, -5), c + Vector2(-d * 3, 5)]), Color(0.45, 0.25, 0.0, 0.8))
	else:
		var dim := item == "boomerang" and _player != null and is_instance_valid(_player.boomerang)
		draw_icon(self, icon(Progress.icon_id(item)), c, C_ICON, Color(0.5, 0.5, 0.5, 0.8) if dim else Color(1, 1, 1))
	if item != "" and Progress.ammo_of(item) >= 0:
		# Interface_DrawAmmoCount: the count at the button's lower left.
		var n := Progress.ammo_of(item)
		var col := Color8(120, 255, 0) if n >= Progress.ammo_max_of(item) else (AMMO if n > 0 else Color8(100, 100, 100))
		text(self, rect.position + Vector2(2, rect.size.y - 1), str(n), 9, col, false)
	_glyph(c + Vector2(0, rect.size.y * 0.5 + 6), token)


## A button: the smooth disc tinted `col` (brighter while in use).
func _draw_button(rect: Rect2, col: Color, active: bool) -> void:
	var t := tex(BUTTON_TEX)
	var tint := col.lightened(0.3) if active else col
	if t:
		draw_texture_rect(t, rect, false, tint)
	else:
		draw_circle(rect.get_center(), rect.size.x * 0.5, tint)


## The small key name under a button.
func _label(pos: Vector2, s: String) -> void:
	text(self, pos, s, 7, Color(1, 1, 1, 0.85), true, Color(0, 0, 0, 0.7))


## The button's glyph (or key) centered under a button, at a label's place.
func _glyph(pos: Vector2, token: String) -> void:
	var w := Glyphs.badge_width(token)
	Glyphs.draw_badge(self, Vector2(pos.x - w * 0.5, pos.y - 7.0), token, 0.95)


func _draw_messages() -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if _player and _player.is_dead():
		PixelFont.draw_centered(self, 160, 100, "YOU HAVE FALLEN...", Color(0.95, 0.25, 0.15), 2)
		return
	if _clear_time >= 0.0 and _clear_time < 4.0 and World.area_id == "test_area":
		PixelFont.draw_centered(self, 160, 92, "AREA CLEAR!", Color(1.0, 0.85, 0.3), 2)
	var hint := ""
	var pad := GameManager.using_gamepad
	if Dialogue.active:
		return
	var spot := FishingSpot.current
	if is_instance_valid(spot) and spot.phase != FishingSpot.Phase.OFF:
		_draw_fishing(spot, pad)
		return
	# Prompts name buttons by token (see Glyphs); where the keyboard works
	# differently (the mouse aims, Space returns) it has its own line.
	if Cutscene.active:
		return
	if _player and _player.state == PlayerController.State.AIM and _player.aim_item == "boomerang":
		hint = "{LOOK} AIM  RELEASE: THROW  {B} DONE" if pad else "{LOOK} AIM  RELEASE: THROW  {A} DONE"
	elif _player and _player.state == PlayerController.State.AIM:
		hint = "{LOOK} AIM  RELEASE: SHOOT  {B} DONE" if pad else "{LOOK} AIM  CLICK: SHOOT  {A} DONE"
	elif _player and _player.state == PlayerController.State.LOOK:
		hint = "{LOOK} LOOK  {RB}/{A} RETURN"
	elif _player and _player.is_riding():
		if _player.riding_aim:
			hint = "{LOOK} AIM  RELEASE: SHOOT  {B} DONE" if pad else "{LOOK} AIM  CLICK: SHOOT  {A} DONE"
		else:
			hint = "{MOVE} RIDE  {A} FASTER  {B} SWORD"
	elif _player and _player.state == PlayerController.State.SWIM:
		if _player.diving > 0:
			hint = "HOLD {A} DIVE DEEPER"
		else:
			hint = "{MOVE} SWIM  {A} DIVE"
	elif _player and _player.state == PlayerController.State.HANG:
		hint = "{MOVE} CLIMB UP  {A} DROP"
	elif _player and _player.state == PlayerController.State.LADDER:
		hint = "{MOVE} CLIMB  {A} DROP"
	elif _player and is_instance_valid(_player.held) and _player.held is Bomb:
		hint = "{A}/{B} THROW  STILL+{A} SET DOWN"
	elif _player and _player.lock_target:
		hint = "{A} JUMP SLASH  {A}+{MOVE} HOP  {RT} SHIELD"
	elif _player and _player.parallel:
		hint = "HOLD {LT} STRAFE  {A}+{MOVE} HOP"
	elif _time < 9.0:
		hint = "{MOVE} MOVE  {A} ROLL  {LB} CAMERA"
	elif _time < 18.0:
		hint = "{B} SWORD  {RT} SHIELD  {LT} TARGET"
	elif _time < 27.0:
		hint = "{X} BOW  {RB} LOOK AROUND"
	# Promo screenshots (tests/box_capture) turn the prompt line off.
	if hint != "" and not GameManager.has_meta("no_hints"):
		Glyphs.draw_hint(self, 160, 240.0 - 17.0, hint, Color(1, 1, 1, 0.9))
