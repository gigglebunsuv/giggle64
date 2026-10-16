extends Control
## Boot sequence: the studio splash screens, then the title over Sir
## Gigglebuns out walking through Haven (TitleFlyover), then the file select
## (FileSelect), then the game in the chosen area.
##
## Wind (assets/audio/wind_loop.wav, from tools/gen_media.gd) loops from the
## first splash until the game starts, under the title music too.
##
## Title music: drop a file named title_theme (.ogg, .mp3 or .wav) into
## res://assets/music/. It starts when the title appears and plays once; when it
## ends (and the title is left alone ATTRACT_DELAY longer) the picture fades
## to one of the attract scenes (TitleScene: the hero and the rat, Mira at
## Mirror Lake, the Questlords in the desert at night; picked at random, never
## the same one twice running), and after it the boot sequence starts over
## from the splashes. Any button during the scene returns to the title.
## The music fades out when a file is chosen. Without the file the title is
## simply silent and never moves on.

enum Phase { SPLASH, TITLE, TO_FILES, FILES, TO_ATTRACT, ATTRACT, TO_TITLE, STARTING, DONE }

## Splash screens in order, each a 320x240 logo (transparent around it) drawn
## over its own animated backdrop (see SPLASH_STYLES).
const SPLASHES := [
	preload("res://assets/textures/splash_unknown_vengeance.png"),
	preload("res://assets/textures/splash_perhaps_playable.png"),
]
## Per splash: gradient top and bottom, the glow behind the logo, the light
## rays, the drifting motes, the trim lines, and whether motes twinkle as stars.
const SPLASH_STYLES := [
	{
		"top": Color("f7f0e4"), "bottom": Color("ddcdea"), "glow": Color("fffaf0"),
		"rays": Color("e8c25a"), "motes": Color("8a5cb0"), "trim": Color("b8922c"), "stars": false,
	},
	{
		"top": Color("f0f7ff"), "bottom": Color("c4dcf8"), "glow": Color("ffffff"),
		"rays": Color("7ec8ff"), "motes": Color("3f8ff0"), "trim": Color("2a7ae0"), "stars": true,
	},
]
## Where the logos sit on their canvases (the rays and glow center here).
const SPLASH_CENTER := Vector2(160, 120)
## The logo rises this many pixels into place as it fades in.
const SPLASH_RISE := 6.0
const SPLASH_FADE_IN := 0.6
const SPLASH_HOLD := 2.2
const SPLASH_FADE_OUT := 0.6
## Black between splashes, and before the title.
const SPLASH_GAP := 0.35

## The 320x240 title art (transparent around the logo), drawn 1:1.
const LOGO := preload("res://assets/textures/title_logo.png")
## The Gauntlet of Fire behind the G (rendered by tools/render_title_art.tscn).
const GAUNTLET := preload("res://assets/textures/title_gauntlet.png")
const GAUNTLET_POS := Vector2(47, 2)
## Slightly dimmed so the gold G in front of it stays readable.
const GAUNTLET_TINT := Color(0.82, 0.76, 0.74)
## Knight Gigglebuns (Beta 1.3.0), sword raised, to the left under the logo
## (also rendered by tools/render_title_art.tscn; left out if not there yet).
const KNIGHT_ART := "res://assets/textures/title_knight.png"
const KNIGHT_POS := Vector2(16, 92)
var _knight_art: Texture2D = load(KNIGHT_ART) if ResourceLoader.exists(KNIGHT_ART) else null
const LOGO_FADE := 0.5
## Ignore START this long after the title appears (a held splash skip).
const TITLE_INPUT_DELAY := 0.6

const MUSIC_BASE := "res://assets/music/title_theme"
const MUSIC_DB := 0.0
## Idle seconds on the title after the music ends before the attract scene;
## longer when back from the file select after it ended.
const ATTRACT_DELAY := 2.0
const ATTRACT_DELAY_BACK := 12.0
## Fade to black from the title into the attract scene.
const ATTRACT_FADE := 1.5
## Fade to black when the scene is skipped, back to the title.
const SKIP_FADE := 0.5

const WIND := preload("res://assets/audio/wind_loop.wav")
const WIND_DB := -20.0
const WIND_FADE_IN := 1.5

var phase := Phase.SPLASH
var splash_index := 0

var _t := 0.0
var _time := 0.0
var _logo_alpha := 0.0
var _flyover: TitleFlyover
var _files: FileSelect
## The scene playing (or last played), and all of them.
var _attract: TitleScene
var _scenes: Array[TitleScene] = []
var _last_scene := -1
var _music: AudioStreamPlayer
var _wind: AudioStreamPlayer
## Seconds left before the attract scene (-1 while the music plays).
var _attract_in := -1.0
## Black over the picture while it fades into or out of the attract scene.
var _restart_fade := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flyover = TitleFlyover.new()
	_flyover.name = "Flyover"
	add_child(_flyover)
	_files = FileSelect.new()
	_files.name = "FileSelect"
	_files.visible = false
	add_child(_files)
	_files.chosen.connect(_on_file_chosen)
	_files.cancelled.connect(_on_files_cancelled)
	for s: TitleScene in [TitleAttract.new(), TitleMira.new(), TitleQuestlords.new(), TitleFallen.new(), TitleBatela.new(), TitleSiege.new(), TitleKnight.new(), TitleRidge.new()]:
		s.name = String(s.get_script().get_global_name()).trim_prefix("Title")
		add_child(s)
		s.finished.connect(_on_attract_finished)
		_scenes.append(s)
	_attract = _scenes[0]
	# The scenes' lines, over their letterbox (the HUD's box is for play).
	var box := MessageBox.new()
	box.on_title = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(box)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.volume_db = MUSIC_DB
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_on_music_finished)
	_wind = AudioStreamPlayer.new()
	_wind.name = "Wind"
	_wind.bus = "Ambience"
	add_child(_wind)
	if GameManager.state != GameManager.GameState.TITLE:
		phase = Phase.DONE
		return
	_play_wind()
	if "--skip-splash" in OS.get_cmdline_user_args():
		_enter_title()


func _process(delta: float) -> void:
	if phase != Phase.DONE and GameManager.state != GameManager.GameState.TITLE:
		# Started from elsewhere (a test or tool).
		_finish()
	visible = phase != Phase.DONE
	if not visible:
		return
	_t += delta
	_time += delta
	match phase:
		Phase.SPLASH:
			_update_splash()
		Phase.TITLE:
			_logo_alpha = minf(_logo_alpha + delta / LOGO_FADE, 1.0)
			if _t >= TITLE_INPUT_DELAY and _start_pressed():
				Sfx.play("menu_select")
				phase = Phase.TO_FILES
				_t = 0.0
			elif _attract_in >= 0.0:
				_attract_in -= delta
				if _attract_in <= 0.0:
					phase = Phase.TO_ATTRACT
					_t = 0.0
		Phase.TO_FILES:
			_logo_alpha = maxf(_logo_alpha - delta / LOGO_FADE, 0.0)
			if _logo_alpha <= 0.0:
				phase = Phase.FILES
				_files.open()
		Phase.TO_ATTRACT:
			_logo_alpha = maxf(_logo_alpha - delta / LOGO_FADE, 0.0)
			_restart_fade = minf(_t / ATTRACT_FADE, 1.0)
			if _restart_fade >= 1.0:
				start_attract()
		Phase.ATTRACT:
			if _t >= TITLE_INPUT_DELAY and _skip_pressed():
				phase = Phase.TO_TITLE
				_t = 0.0
				_restart_fade = _attract.fade
		Phase.TO_TITLE:
			_restart_fade = minf(_restart_fade + delta / SKIP_FADE, 1.0)
			if _restart_fade >= 1.0:
				_attract.stop()
				_restart_fade = 0.0
				_enter_title()
	queue_redraw()


func _update_splash() -> void:
	var total := SPLASH_FADE_IN + SPLASH_HOLD + SPLASH_FADE_OUT + SPLASH_GAP
	# Any button cuts the current splash short (straight to its fade out).
	if _skip_pressed() and _t < SPLASH_FADE_IN + SPLASH_HOLD:
		_t = SPLASH_FADE_IN + SPLASH_HOLD
	if _t >= total:
		_t = 0.0
		splash_index += 1
		if splash_index >= SPLASHES.size():
			_enter_title()


func _enter_title() -> void:
	phase = Phase.TITLE
	_t = 0.0
	_logo_alpha = 0.0
	_attract_in = -1.0
	_flyover.start(get_viewport() as SubViewport)
	_play_music()


## An attract scene, after the title music (also used by capture tools):
## `which` indexes _scenes, or -1 for a random one other than the last.
func start_attract(which := -1) -> void:
	if which < 0 or which >= _scenes.size():
		which = pick_scene()
	_last_scene = which
	_attract = _scenes[which]
	_flyover.stop()
	_stop_music(0.1)
	phase = Phase.ATTRACT
	_t = 0.0
	_logo_alpha = 0.0
	_restart_fade = 0.0
	_attract_in = -1.0
	_attract.start(get_viewport() as SubViewport)


## A random scene index, never the one played last.
func pick_scene() -> int:
	var pool: Array[int] = []
	for i in _scenes.size():
		if i != _last_scene or _scenes.size() == 1:
			pool.append(i)
	return pool.pick_random()


func _on_attract_finished() -> void:
	if phase == Phase.ATTRACT:
		_restart_splashes()


## Back to the first splash after the attract scene (the wind keeps going).
func _restart_splashes() -> void:
	_flyover.stop()
	_attract.stop()
	phase = Phase.SPLASH
	splash_index = 0
	_t = 0.0
	_logo_alpha = 0.0
	_restart_fade = 0.0
	_attract_in = -1.0


## Opacity of the current splash (it fades in from and out to black).
func splash_alpha() -> float:
	if _t < SPLASH_FADE_IN:
		return _t / SPLASH_FADE_IN
	if _t < SPLASH_FADE_IN + SPLASH_HOLD:
		return 1.0
	return clampf(1.0 - (_t - SPLASH_FADE_IN - SPLASH_HOLD) / SPLASH_FADE_OUT, 0.0, 1.0)


func _start_pressed() -> bool:
	return Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact") \
		or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("pause")


func _skip_pressed() -> bool:
	return _start_pressed() or Input.is_action_just_pressed("ui_cancel")


func _on_files_cancelled() -> void:
	phase = Phase.TITLE
	_t = 0.0
	# Back from the files after the music ended: a while longer on the title.
	if _attract_in >= 0.0:
		_attract_in = ATTRACT_DELAY_BACK


func _on_music_finished() -> void:
	if phase in [Phase.TITLE, Phase.TO_FILES, Phase.FILES]:
		_attract_in = ATTRACT_DELAY


func _on_file_chosen(area: String, entrance: String, health: int) -> void:
	start_at(area, entrance, health)


## Leaves the title for the game in `area` (also used by capture tools).
func start_at(area: String, entrance := "", health := -1) -> void:
	phase = Phase.STARTING
	_stop_music(0.6)
	_fade_out(_wind, 0.6)
	_flyover.stop()
	_attract.stop()
	_files.visible = false
	World.begin_game(area, entrance, health)
	phase = Phase.DONE


func _finish() -> void:
	_flyover.stop()
	_attract.stop()
	_files.visible = false
	_stop_music(0.6)
	_fade_out(_wind, 0.6)
	phase = Phase.DONE


# --- Music and wind ------------------------------------------------------------

func _play_music() -> void:
	if _music.playing:
		return
	for ext in [".ogg", ".mp3", ".wav"]:
		var path: String = MUSIC_BASE + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			# Plays once (the import may have looping on).
			if stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
			elif "loop" in stream:
				stream.set("loop", false)
			_music.stream = stream
			_music.volume_db = MUSIC_DB
			_music.play()
			return


func _stop_music(time: float) -> void:
	_fade_out(_music, time)


func _fade_out(player: AudioStreamPlayer, time: float) -> void:
	if not player.playing:
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", -60.0, time)
	tween.tween_callback(player.stop)


func _play_wind() -> void:
	if _wind.playing:
		return
	var stream := WIND as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_wind.stream = stream
	_wind.volume_db = -60.0
	_wind.play()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_wind, "volume_db", WIND_DB, WIND_FADE_IN)


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	if phase == Phase.SPLASH:
		draw_rect(GameManager.screen_rect(), Color(0, 0, 0))
		if splash_index < SPLASHES.size():
			_draw_splash(SPLASH_STYLES[splash_index], SPLASHES[splash_index])
			draw_rect(GameManager.screen_rect(), Color(0, 0, 0, 1.0 - splash_alpha()))
		return
	var full := GameManager.screen_rect()
	if phase in [Phase.ATTRACT, Phase.TO_TITLE]:
		# The attract scene: OoT's cutscene letterbox, and its fades.
		var bar := roundf(_attract.bars)
		if bar > 0.0:
			draw_rect(Rect2(full.position.x, 0, full.size.x, bar), Color.BLACK)
			draw_rect(Rect2(full.position.x, 240 - bar, full.size.x, bar), Color.BLACK)
		var black := maxf(_attract.fade, _restart_fade)
		if black > 0.0:
			draw_rect(full, Color(0, 0, 0, black))
		return
	# Scenery: a light veil for the logo, darker toward the bottom text.
	draw_rect(GameManager.screen_rect(), Color(0.05, 0.02, 0.06, 0.15))
	for i in 8:
		draw_rect(Rect2(full.position.x, 160 + i * 10, full.size.x, 10), Color(0.03, 0.01, 0.04, 0.05 * (i + 1)))
	if _flyover.fade > 0.0:
		draw_rect(GameManager.screen_rect(), Color(0, 0, 0, _flyover.fade))
	if _logo_alpha > 0.0:
		var tint := Color(1, 1, 1, _logo_alpha)
		draw_texture(GAUNTLET, GAUNTLET_POS, GAUNTLET_TINT * tint)
		if _knight_art:
			draw_texture(_knight_art, KNIGHT_POS, tint)
		draw_texture(LOGO, Vector2.ZERO, tint)
		if phase == Phase.TITLE and fmod(_time, 1.0) < 0.65:
			Glyphs.draw_hint(self, 160, 176, "PRESS {START}" if GameManager.using_gamepad else "PRESS ENTER", tint)
		PixelFont.draw_centered(self, 160, 218, "BETA 1.6.1 - PAGES TURNED", Color(0.75, 0.7, 0.8, _logo_alpha))
		_beta_stamp(tint)
	if _restart_fade > 0.0:
		draw_rect(GameManager.screen_rect(), Color(0, 0, 0, _restart_fade))


## A red "BETA" stamp slapped at an angle on the corner of the logo.
func _beta_stamp(tint: Color) -> void:
	var at := Vector2(246, 128)
	draw_set_transform(at, -0.22)
	var r := Rect2(-24, -9, 48, 18)
	var col := Color(0.86, 0.16, 0.14, 0.92 * tint.a)
	draw_rect(r.grow(2), Color(col, col.a * 0.25))
	draw_rect(r, col, false, 2.0)
	draw_rect(r.grow(-3), col, false, 1.0)
	draw_set_transform(at + Vector2(1, 1), -0.22, Vector2(2, 2))
	PixelFont.draw_centered(self, 0, -3.5, "BETA", Color(0.2, 0.0, 0.0, 0.5 * tint.a))
	draw_set_transform(at, -0.22, Vector2(2, 2))
	PixelFont.draw_centered(self, 0, -4, "BETA", col)
	draw_set_transform(Vector2.ZERO)


## One splash: a banded gradient, slowly turning light rays and a soft glow
## behind the logo, drifting motes, trim lines that draw outward, a vignette,
## and the logo rising into place. Timed by _t (the splash's own clock).
func _draw_splash(style: Dictionary, logo: Texture2D) -> void:
	var top: Color = style["top"]
	var bottom: Color = style["bottom"]
	# The whole screen (wider than the 320 layout in 16:9).
	var full := GameManager.screen_rect()
	var x0 := full.position.x
	var x1 := full.end.x
	# Gradient in 4-pixel bands, for a console-era stepped look.
	for y in range(0, 240, 4):
		draw_rect(Rect2(x0, y, full.size.x, 4), top.lerp(bottom, y / 236.0))
	# Light rays fanning from behind the logo, fading toward their tips.
	var rays: Color = style["rays"]
	var spin := _t * 0.12 + splash_index * 0.4
	for i in 14:
		var a0 := spin + TAU * i / 14.0
		var tip := Color(rays, 0.0)
		draw_polygon(
			PackedVector2Array([SPLASH_CENTER,
				SPLASH_CENTER + Vector2.from_angle(a0 - 0.07) * 300.0,
				SPLASH_CENTER + Vector2.from_angle(a0 + 0.07) * 300.0]),
			PackedColorArray([Color(rays, 0.32), tip, tip]))
	# Soft elliptical glow under the logo.
	var glow: Color = style["glow"]
	draw_set_transform(SPLASH_CENTER, 0.0, Vector2(1.7, 0.75))
	for i in 10:
		draw_circle(Vector2.ZERO, 95.0 - i * 8.0, Color(glow, 0.09))
	draw_set_transform(Vector2.ZERO)
	# Motes drifting up and sideways, wrapping around the screen.
	var motes: Color = style["motes"]
	var stars: bool = style["stars"]
	for i in 36:
		var h1 := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
		var h2 := fposmod(sin(i * 78.233) * 12543.123, 1.0)
		var drift := (4.0 + h2 * 6.0) * (1.0 if i % 2 == 0 else -1.0)
		var x := floorf(fposmod(h1 * (full.size.x + 20.0) + _t * drift, full.size.x + 20.0) - 10.0 + x0)
		var y := floorf(fposmod(h2 * 260.0 - _t * (6.0 + h1 * 10.0), 260.0) - 10.0)
		var twinkle := 0.5 + 0.5 * sin(_t * (2.0 + h1 * 3.0) + i)
		var size := 1.0 if h2 < 0.6 else 2.0
		if stars:
			var c := Color(motes, 0.35 + 0.65 * twinkle)
			draw_rect(Rect2(x, y, 1, 1), c)
			if twinkle > 0.7:
				var arm := Color(c, c.a * 0.6)
				draw_rect(Rect2(x - size, y, 1 + size * 2.0, 1), arm)
				draw_rect(Rect2(x, y - size, 1, 1 + size * 2.0), arm)
		else:
			draw_rect(Rect2(x, y, size, size), Color(motes, 0.3 + 0.4 * twinkle))
	# Trim lines above and below the logo, drawing outward from the center.
	var trim: Color = style["trim"]
	var reach := roundf(110.0 * _ease_out(clampf((_t - 0.2) / 1.0, 0.0, 1.0)))
	if reach >= 1.0:
		for y in [66, 174]:
			draw_rect(Rect2(160.0 - reach, y, reach * 2.0, 1), Color(trim, 0.85))
			draw_rect(Rect2(160.0 - roundf(reach * 0.7), y + 2, roundf(reach * 0.7) * 2.0, 1), Color(trim, 0.35))
			for side in [-1.0, 1.0]:
				var end := Vector2(160.0 + side * reach, y + 0.5)
				draw_colored_polygon(PackedVector2Array([end + Vector2(0, -2.5), end + Vector2(2.5, 0),
					end + Vector2(0, 2.5), end + Vector2(-2.5, 0)]), trim)
	# Vignette.
	var shade := Color(0.1, 0.05, 0.15, 0.022)
	for i in 6:
		var w := 4.0 * (6 - i)
		draw_rect(Rect2(x0, 0, full.size.x, w), shade)
		draw_rect(Rect2(x0, 240 - w, full.size.x, w), shade)
		draw_rect(Rect2(x0, 0, w, 240), shade)
		draw_rect(Rect2(x1 - w, 0, w, 240), shade)
	# The logo, rising into place as it fades in (whole pixels, no blur).
	var rise := roundf(SPLASH_RISE * (1.0 - _ease_out(clampf(_t / (SPLASH_FADE_IN * 1.5), 0.0, 1.0))))
	draw_texture(logo, Vector2(0, rise))


static func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)
