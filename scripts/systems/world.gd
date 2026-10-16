extends Node
## Loads the areas of Haven into the game viewport and moves the hero between
## them with a faked N64 loading screen, timed like OoT (zeldaret/oot):
## - TransitionFade (z_fbdemo_fade.c) fades linearly over transFadeDuration = 60
##   ticks at R_UPDATE_RATE 3 per 20 Hz frame, i.e. 1 s out and 1 s in (z_play.c).
##   The hero keeps walking into the exit while the picture fades.
## - A short black hold stands in for the scene load.
## - On arrival he walks a few steps out of the entrance, and the place-name card
##   (TitleCard_InitPlaceName, z_player.c / z_actor.c) appears centered on screen
##   after a 20-frame delay: alpha steps +10 and brightness +20 per frame, holds
##   80 frames, then fades with alpha -30 and brightness -70 per frame.

signal area_changed(area: String)

const FADE_OUT := 1.0
## Black hold that stands in for the N64's loading time.
const LOAD_HOLD := 0.4
const FADE_IN := 1.0
const WALK_IN_TIME := 0.8
## Title card timing in OoT 20 Hz frames.
const TITLE_DELAY := 20
const TITLE_DURATION := 80
## Area music (WorldData.music): loops while in the area, fades out with the
## picture when leaving for an area with a different track, and starts on
## arrival. The same track carries on uninterrupted between areas.
const MUSIC_DB := 0.0
## Ambience loops (WorldData.ambience) sit under the music and cross-fade
## between areas with the picture.
const AMBIENCE_DB := -14.0

## Area and entrance to load at the next boot (tests and the warp menu set these).
var area_id := WorldData.START_AREA
var entrance_id := WorldData.START_ENTRANCE
var area_node: Node3D = null
## Counts area loads (things that happen "once a visit" remember the count).
var load_count := 0
## Where the hero entered the current area (the minimap's red arrow).
var entry_transform := Transform3D.IDENTITY
var transitioning := false
## Black overlay opacity, 0..1.
var fade := 0.0
## Title card state (TitleCardContext): timers in 20 Hz frames, alpha and
## brightness 0..255.
var title_text := ""
## A line above the name (a boss's epithet); "" for place names.
var title_sub := ""
var title_delay := 0.0
var title_duration := 0.0
var title_alpha := 0.0
var title_intensity := 0.0

var _viewport: SubViewport = null
var _overlay: Control = null
## Hero health carried between areas (-1 = full).
var _saved_health := -1
## The track playing ("" = none).
var music_track := ""
var _music: AudioStreamPlayer
var _music_tween: Tween
var _missing_music := {}
## A scored cutscene's music (Story.legend): played once, beside the area
## music, and its playback position is the scene's clock.
var _score: AudioStreamPlayer
var score_track := ""
## The ambience loop playing ("" = none).
var ambience_track := ""
## A MusicZone's track while the hero stands in it (Ashwick's camp in the
## Fells): it plays instead of the area's, day or night.
var zone_track := ""
var _left_zone := ""
## The fight playing its music ("" none, "boss", "miniboss"): OoT's
## NA_BGM_BOSS and NA_BGM_MINI_BOSS. See start_battle / end_battle.
var battle := ""
## The mini-bosses' own fight track; until its file exists they borrow the
## boss theme.
const MINIBOSS_TRACK := "miniboss"
const BOSS_TRACK := "boss_battle"
var _ambience: AudioStreamPlayer
var _ambience_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.name = "AreaMusic"
	_music.bus = "Music"
	add_child(_music)
	_score = AudioStreamPlayer.new()
	_score.name = "Score"
	_score.bus = "Music"
	add_child(_score)
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "Ambience"
	_ambience.bus = "Ambience"
	add_child(_ambience)
	GameManager.settings_changed.connect(apply_fog)


## Called by the main scene once its viewport exists: loads the current area.
func boot(viewport: SubViewport) -> void:
	_viewport = viewport
	transitioning = false
	fade = 0.0
	Dialogue.cancel()
	_saved_health = -1
	var layer := CanvasLayer.new()
	layer.name = "TransitionLayer"
	layer.layer = 20
	_overlay = TransitionOverlay.new()
	_overlay.name = "TransitionOverlay"
	layer.add_child(_overlay)
	viewport.add_child(layer)
	var debug_layer := CanvasLayer.new()
	debug_layer.name = "DebugLayer"
	debug_layer.layer = 15
	debug_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if DebugMenu.allowed():
		var debug := DebugMenu.new()
		debug.name = "DebugMenu"
		debug_layer.add_child(debug)
	# Loaded by path: a class reference here would make World and BugReport depend on each other.
	var report: Control = load("res://scripts/systems/bug_report.gd").new()
	report.name = "BugReport"
	debug_layer.add_child(report)
	viewport.add_child(debug_layer)
	_spawn(area_id, entrance_id)
	if GameManager.skip_title:
		_play_music(area_id)
		_play_ambience(area_id)
		if not WorldData.is_interior(area_id):
			_show_title()
	else:
		_play_music("")


## Where a saved game starts again: this area at the entrance the hero came
## in by (the debug test area saves as the hero's home).
func save_area() -> String:
	return WorldData.START_AREA if area_id == "test_area" else area_id


func save_entrance() -> String:
	return WorldData.START_ENTRANCE if area_id == "test_area" else entrance_id


## The dungeon the hero is in ("" = none).
func dungeon_id() -> String:
	return WorldData.dungeon(area_id)


## The storeys of a dungeon of several floors, bottom first, as [name, floor
## height] pairs ([] in an area of one floor).
func floors() -> Array:
	return area_node.get_meta("floors", []) if is_instance_valid(area_node) else []


## Which of floors() something at height `y` is on: the highest storey whose
## floor is at most a meter above it.
func floor_at(y: float) -> int:
	var best := 0
	var f := floors()
	for i in f.size():
		if y >= float(f[i][1]) - 1.0:
			best = i
	return best


## Moves the hero to `area`, arriving at `entrance` ("" = the area's first entrance).
func change_area(area: String, entrance := "") -> void:
	if transitioning or _viewport == null:
		return
	area = WorldData.resolve(area)
	if not ResourceLoader.exists(WorldData.scene_path(area)):
		push_warning("World: no scene for area '%s'" % area)
		return
	transitioning = true
	var from_area := area_id
	Dialogue.cancel()
	var player := GameManager.player
	if is_instance_valid(player):
		player.auto_walk(player.forward(), FADE_OUT + 0.3)
	if track_for(area) != music_track:
		_fade_music(FADE_OUT)
	if WorldData.ambience(area) != ambience_track:
		_fade_ambience(FADE_OUT)
	await _fade_to(1.0, FADE_OUT)
	get_tree().paused = true
	_spawn(area, entrance)
	await get_tree().create_timer(LOAD_HOLD, true).timeout
	get_tree().paused = GameManager.state != GameManager.GameState.PLAYING
	_play_music(area)
	_play_ambience(area)
	player = GameManager.player
	if is_instance_valid(player):
		player.auto_walk(player.forward(), WALK_IN_TIME)
		_arrival_shot(player)
	# OoT shows the place name when arriving in a region, not for houses or on
	# stepping back outside, nor when the woods turn you round (the Forest of
	# the Dead's wrong ways lead back into the same area).
	if not WorldData.is_interior(area) and not WorldData.is_interior(from_area) and area != from_area:
		_show_title()
	else:
		title_alpha = 0.0
		title_duration = 0.0
		title_delay = 0.0
	await _fade_to(0.0, FADE_IN)
	transitioning = false


## Coming in through a door (a dungeon's way in, a house): OoT's arrival
## shot. The camera waits inside, ahead of the hero and to one side, and
## watches him step in through the door, then glides round behind him.
func _arrival_shot(player: PlayerController, extra := 0.0) -> void:
	if not is_instance_valid(player) or player.camera_rig == null:
		return
	var door: Door = null
	for d in get_tree().get_nodes_in_group("doors"):
		var dn := d as Door
		if dn and dn.is_inside_tree() and dn.global_position.distance_to(player.global_position) < 4.5:
			door = dn
	if door == null:
		return
	# The door's -Z faces whoever stands at it on this side: into the room.
	var inward := -door.global_basis.z
	inward = Vector3(inward.x, 0, inward.z).normalized()
	var side := Vector3(-inward.z, 0, inward.x)
	var start := player.global_position
	var up := Vector3.UP * 1.5
	player.camera_rig.snap_behind_target()
	player.camera_rig.hold_shot_from([start + inward * 5.0 + side * 2.0 + up, start + inward * 5.0 - side * 2.0 + up,
		start + inward * 4.0 + side * 1.2 + up, start + inward * 4.0 - side * 1.2 + up, start + inward * 3.5 + up],
		start + Vector3.UP * 1.0, WALK_IN_TIME + 0.55 + extra, 0.8, player, 58.0, 2.5)


## Title screen scenery: loads `area` as a backdrop, with the hero hidden. The
## tree stays paused, so nothing in it moves; the title screen flies its own camera.
func show_scenery(area: String) -> void:
	if _viewport == null or not ResourceLoader.exists(WorldData.scene_path(area)):
		return
	GameManager.clear_area()
	_spawn(area, "")
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = false


## Leaves the title screen: loads `area` at `entrance` ("" = its first entrance)
## and starts play, fading in from black with the place-name card.
func begin_game(area: String, entrance := "", health := -1) -> void:
	if _viewport == null:
		return
	area = WorldData.resolve(area)
	GameManager.clear_area()
	_saved_health = -1
	_spawn(area, entrance)
	var p := GameManager.player
	if p and health > 0:
		p.health.health = mini(health, p.health.max_health)
		p.health.health_changed.emit(p.health.health, p.health.max_health)
	fade = 1.0
	GameManager.start_game()
	if is_instance_valid(p):
		_arrival_shot(p, 0.6)
	_play_music(area)
	_play_ambience(area)
	if not WorldData.is_interior(area):
		_show_title()
	_fade_to(0.0, FADE_IN)


## Debug warp from the pause menu.
func warp(area: String) -> void:
	GameManager.resume_game()
	change_area(area, "")


## Cutscenes: fades to black, loads `area` with the hero at `entrance`
## (hidden with `hide_hero`, and halted for the scene) and fades back in.
func cutscene_load(area: String, entrance := "", hide_hero := false, music := true) -> void:
	if _viewport == null:
		return
	await _fade_to(1.0, 0.8)
	_spawn(area, entrance)
	if music:
		_play_music(area)
	_play_ambience(area)
	title_alpha = 0.0
	title_duration = 0.0
	var p := GameManager.player
	if is_instance_valid(p):
		Cutscene.halt_player()
		p.visible = not hide_hero
	await get_tree().create_timer(0.3, false, true).timeout
	await _fade_to(0.0, 0.8)


## Game over's CONTINUE (GameOver): the area loads again from the entrance
## the hero last came in by (a dungeon's door, an area's road), its creatures
## back where they were, and the hero up with `health` half-hearts.
func continue_after_game_over(health: int) -> void:
	if _viewport == null:
		return
	Cutscene.stop_skip()
	if Cutscene.active:
		Cutscene.end()
	Dialogue.cancel()
	fade = 1.0
	_saved_health = -1
	_spawn(WorldData.resolve(area_id), entrance_id)
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.health = mini(health, p.health.max_health)
		p.health.health_changed.emit(p.health.health, p.health.max_health)
	get_tree().paused = false
	music_track = ""
	_play_music(area_id)
	_play_ambience(area_id)
	await get_tree().create_timer(LOAD_HOLD, true).timeout
	if is_instance_valid(p):
		_arrival_shot(p)
	await _fade_to(0.0, FADE_IN)


## Fades the picture to black (1) or back (0) over `time` (cutscenes).
func fade_to(target: float, time: float) -> void:
	await _fade_to(target, time)


func _fade_to(target: float, time: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "fade", target, time)
	await tween.finished


## The track for `area` now: out in the open after dark there is no music,
## only the ambience and the night layer (DayNight), as on OoT's field at night.
func track_for(area: String) -> String:
	if zone_track != "" and area == area_id:
		return zone_track
	if DayNight.is_night() and DayNight.is_open_air(area):
		return ""
	return WorldData.music(area)


## Dusk or dawn came while here: the area's day or night track takes over
## (unless something else, a boss fight, is playing).
func refresh_music() -> void:
	if transitioning or GameManager.state == GameManager.GameState.TITLE or Cutscene.active:
		return
	if music_track != "" and music_track != WorldData.music(area_id) and music_track != zone_track and music_track != _left_zone:
		return
	_left_zone = ""
	var track := track_for(area_id)
	if track != music_track:
		play_track(track)


## A MusicZone the hero walked into (track) or out of (""): its track takes
## over from the area's, and the area's comes back on leaving.
func set_zone_track(track: String) -> void:
	if track == zone_track:
		return
	_left_zone = zone_track
	zone_track = track
	refresh_music()


## Starts `area`'s track looping (silence for none); a track already playing
## carries on.
func _play_music(area: String) -> void:
	var track := track_for(area)
	if track == music_track and (_music.playing or track == ""):
		return
	_start_track(track)


func _start_track(track: String) -> void:
	if _music_tween:
		_music_tween.kill()
	_music.stop()
	music_track = track
	if track == "":
		return
	for ext in [".ogg", ".mp3", ".wav"]:
		var path: String = WorldData.MUSIC_DIR + track + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamWAV:
				var wav := stream as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_begin = 0
				wav.loop_end = int(wav.get_length() * wav.mix_rate)
			elif "loop" in stream:
				stream.set("loop", true)
			_music.stream = stream
			_music.volume_db = MUSIC_DB + AudioLevels.music(track)
			_music.play()
			return
	# An optional track nobody has supplied yet (see assets/music/README.txt):
	# the area is simply quiet. Say so once.
	if not _missing_music.has(track):
		_missing_music[track] = true
		print("World: no music file for '%s' (optional)" % track)


## Starts `area`'s ambience loop; the same loop carries on between areas.
func _play_ambience(area: String) -> void:
	var track := WorldData.ambience(area)
	if track == ambience_track and (_ambience.playing or track == ""):
		return
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience.stop()
	ambience_track = track
	var path := Sfx.AUDIO_DIR + track + ".wav"
	if track == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStreamWAV = load(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_ambience.stream = stream
	_ambience.volume_db = -40.0
	_ambience.play()
	_ambience_tween = create_tween()
	_ambience_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ambience_tween.tween_property(_ambience, "volume_db", AMBIENCE_DB + AudioLevels.ambience(track), FADE_IN)


## Stops the ambience (the title screen, the file select).
func stop_ambience() -> void:
	_fade_ambience(0.5)
	ambience_track = ""


func _fade_ambience(time: float) -> void:
	if not _ambience.playing:
		return
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	_ambience_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ambience_tween.tween_property(_ambience, "volume_db", -60.0, time)
	_ambience_tween.tween_callback(_ambience.stop)


func _fade_music(time: float) -> void:
	if not _music.playing:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music, "volume_db", -60.0, time)
	_music_tween.tween_callback(_music.stop)


## Plays a cutscene's score once from the start (no loop); false when nobody
## has supplied the file yet (the scene then keeps its own time).
func play_score(track: String) -> bool:
	_score.stop()
	score_track = ""
	for ext in [".ogg", ".mp3", ".wav"]:
		var path: String = WorldData.MUSIC_DIR + track + ext
		if ResourceLoader.exists(path):
			var stream: AudioStream = (load(path) as AudioStream).duplicate()
			if stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
			elif "loop" in stream:
				stream.set("loop", false)
			_score.stream = stream
			_score.volume_db = MUSIC_DB + AudioLevels.music(track)
			_score.play()
			score_track = track
			return true
	if not _missing_music.has(track):
		_missing_music[track] = true
		print("World: no music file for '%s' (optional)" % track)
	return false


## Stops a cutscene's score (a skipped scene keeps its own time instead).
func stop_score() -> void:
	_score.stop()
	score_track = ""


## Seconds into the score playing now (what is heard, allowing for the mix
## ahead of the speakers), or -1 when none is.
func score_position() -> float:
	if score_track == "" or not _score.playing:
		return -1.0
	return maxf(0.0, _score.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())


## True when a music file for `track` is in res://assets/music/.
func has_music(track: String) -> bool:
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(WorldData.MUSIC_DIR + track + ext):
			return true
	return false


## A fight begins: a boss plays `track` (its own theme, or the boss theme), a
## mini-boss the mini-boss theme (or, until that is supplied, the boss theme).
func start_battle(kind: String, track := "") -> void:
	battle = kind
	if kind == "miniboss":
		track = MINIBOSS_TRACK if has_music(MINIBOSS_TRACK) else BOSS_TRACK
	elif track == "" or not has_music(track):
		# A boss's own theme nobody has rendered yet: the boss theme meanwhile.
		track = BOSS_TRACK
	play_track(track)


## The fight is won: after a boss the room falls silent (as in OoT, until the
## heart container and the blue light); after a mini-boss the dungeon's own
## music comes back.
func end_battle(kind: String) -> void:
	if battle == "" and kind != "boss":
		return
	battle = ""
	play_track("" if kind == "boss" else track_for(area_id))


## A boss's name card (OoT's boss title cards): the name with its epithet above.
func show_boss_title(boss_name: String, epithet: String) -> void:
	_show_title()
	title_text = boss_name
	title_sub = epithet
	title_delay = 10


## Plays `track` from res://assets/music/ ("" = silence) in place of the area's
## own (a boss fight); the area's track returns on the next area change.
func play_track(track: String) -> void:
	if track == music_track and _music.playing:
		return
	_fade_music(0.6)
	if track != "":
		await get_tree().create_timer(0.6, true).timeout
		_start_track(track)
	else:
		music_track = ""


func _show_title() -> void:
	title_sub = ""
	title_text = WorldData.title(area_id)
	title_delay = TITLE_DELAY
	title_duration = TITLE_DURATION
	title_alpha = 0.0
	title_intensity = 0.0


## TitleCard_Update, run in OoT frames.
func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.TITLE and (title_alpha > 0.0 or title_duration > 0.0):
		var frames := delta * 20.0
		if title_delay > 0.0:
			title_delay -= frames
		elif title_duration > 0.0:
			title_duration -= frames
			title_alpha = move_toward(title_alpha, 255.0, 10.0 * frames)
			title_intensity = move_toward(title_intensity, 255.0, 20.0 * frames)
		else:
			title_alpha = move_toward(title_alpha, 0.0, 30.0 * frames)
			title_intensity = move_toward(title_intensity, 0.0, 70.0 * frames)
	if is_instance_valid(_overlay):
		_overlay.queue_redraw()


func _spawn(area: String, entrance: String) -> void:
	zone_track = ""
	_left_zone = ""
	battle = ""
	var old_player := GameManager.player
	var riding := false
	if is_instance_valid(old_player) and is_instance_valid(area_node):
		_saved_health = old_player.health.health
		riding = old_player.is_riding()
	if is_instance_valid(area_node):
		_viewport.remove_child(area_node)
		area_node.queue_free()
	GameManager.clear_area()
	var scene: Node3D = load(WorldData.scene_path(area)).instantiate()
	var marker := _find_entrance(scene, entrance)
	var player := scene.get_node_or_null("Player") as Node3D
	if marker and player:
		player.transform = Transform3D(Basis(Vector3.UP, marker.rotation.y), marker.position)
	if player:
		entry_transform = player.transform
	area_id = area
	entrance_id = marker.name if marker else entrance
	area_node = scene
	load_count += 1
	# Every place the hero has set foot in (the journal's "visited:<area>").
	if area != "test_area":
		Progress.flags["visited:" + area] = true
	_viewport.add_child(scene)
	_viewport.move_child(scene, 0)
	apply_fog()
	var p := GameManager.player
	if p and _saved_health > 0:
		p.health.health = mini(_saved_health, p.health.max_health)
		p.health.health_changed.emit(p.health.health, p.health.max_health)
	# Riding from one stretch of open country to the next, Biscuit comes too;
	# into a town or a forest the hero goes on foot.
	if riding and p and WorldData.horse_allowed(area):
		var h := Horse.spawn(scene, p.global_position, p.facing_yaw)
		p.mount(h, true)
	area_changed.emit(area)


## The GRAPHICS > FOG option: turns the current area's depth fog on or off.
func apply_fog() -> void:
	if not is_instance_valid(area_node):
		return
	for n in area_node.find_children("*", "WorldEnvironment", true, false):
		var env := (n as WorldEnvironment).environment
		if env:
			env.fog_enabled = GameManager.fog_enabled


func _find_entrance(scene: Node, entrance: String) -> Node3D:
	var group := scene.get_node_or_null("Entrances")
	if group == null or group.get_child_count() == 0:
		return null
	if entrance != "" and group.has_node(entrance):
		return group.get_node(entrance)
	return group.get_child(0)


## Black fade and the area name card, drawn over everything at 320x240.
class TransitionOverlay extends Control:
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w: Node = World
		var alpha: float = w.title_alpha / 255.0
		if alpha > 0.0 and GameManager.state == GameManager.GameState.PLAYING:
			# Place name centered on screen (OoT draws it at 160, 120), tinted by
			# the card's brightness so it rises out of black into white.
			var i: float = w.title_intensity / 255.0
			var text: String = w.title_text
			var width := text.length() * PixelFont.ADVANCE * 2
			var y := 113.0
			PixelFont.draw_centered(self, 160, y, text, Color(i, i, i, alpha), 2)
			if w.title_sub != "":
				PixelFont.draw_centered(self, 160, y - 11, w.title_sub, Color(i, i * 0.85, i * 0.6, alpha))
			var half := width * 0.5 + 6.0
			draw_rect(Rect2(160 - half, y + 18, half * 2, 1), Color(i, i * 0.9, i * 0.6, alpha * 0.9))
		var f: float = w.fade
		if f > 0.0:
			draw_rect(GameManager.screen_rect(), Color(0, 0, 0, f))
		# A scene being skipped plays on behind black (Cutscene.skip).
		if Cutscene.skipping:
			draw_rect(GameManager.screen_rect(), Color.BLACK)
			var dots := ".".repeat(1 + int(Time.get_ticks_msec() / 300) % 3)
			PixelFont.draw_centered(self, 160, 114, "SKIPPING" + dots, Color(0.8, 0.8, 0.9))
