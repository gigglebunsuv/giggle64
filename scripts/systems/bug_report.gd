class_name BugReport
extends Control
## F8 anywhere (Beta 1.7.0): writes a bug report for playtesters to send in.
## Each report is a folder under user://bug_reports/<date_time>/ holding
##   screenshot.png   the picture as it was on screen
##   report.txt       version, machine, where the hero is, what he's doing,
##                    the clock, the settings and every story flag
##   save.json        the whole game state, as a save file would hold it
##                    (load it with the debug menu's STATE tab, or copy it
##                    over a save slot)
##   godot.log        the log of this run so far (errors and warnings)
## A line in the corner says where it went. World.boot adds it on its own
## layer, so it works in every build, paused or not.

const KEY := KEY_F8
const DIR := "user://bug_reports"
## Seconds the "saved" line stays up.
const SHOW_TIME := 4.0

var _shown := 0.0
var _was_down := false
## The frame of the last report, so one press never makes two.
var _last_frame := -100
var _label := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# This node sits inside the game's SubViewport, where key events may never
	# arrive, so it listens at the window as well.
	get_tree().root.window_input.connect(_input)


# F8 by its event (a tap shorter than a frame still counts), at the window
# or here, and by polling whether it is held, in case neither event comes.
func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY:
		_trigger()


func _trigger() -> void:
	var frame := Engine.get_process_frames()
	if frame - _last_frame < 10:
		return
	_last_frame = frame
	save_report()


func _process(delta: float) -> void:
	var down := Input.is_physical_key_pressed(KEY)
	if down and not _was_down:
		_trigger()
	_was_down = down
	if _shown > 0.0:
		_shown -= delta
		queue_redraw()


## Writes a report and returns its folder (absolute path), or "" on failure.
func save_report() -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var dir := DIR.path_join(stamp)
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		push_error("BugReport: cannot make %s" % dir)
		return ""
	# The picture first, before the "saved" line is drawn over it (there is
	# no picture headless, where frame_post_draw never comes).
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var img := get_tree().root.get_texture().get_image()
		if img:
			img.save_png(dir.path_join("screenshot.png"))
	else:
		await get_tree().process_frame
	_write(dir.path_join("report.txt"), report_text())
	_write(dir.path_join("save.json"), JSON.stringify(state(), "\t"))
	var log_path := "user://logs/godot.log"
	if FileAccess.file_exists(log_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(log_path), ProjectSettings.globalize_path(dir.path_join("godot.log")))
	var abs_dir := ProjectSettings.globalize_path(dir)
	print("BugReport: saved %s" % abs_dir)
	_label = "BUG REPORT SAVED: BUG_REPORTS/%s" % stamp
	_shown = SHOW_TIME
	Sfx.play("menu_select", -6.0)
	return abs_dir


## The game state, shaped like a save file (SaveGame.save).
static func state() -> Dictionary:
	var data := Progress.to_dict()
	data["version"] = SaveGame.VERSION
	data["area"] = World.area_id
	data["entrance"] = World.entrance_id
	var p := GameManager.player
	if is_instance_valid(p):
		data["health"] = p.health.health
	return data


## The human-readable part of a report.
static func report_text() -> String:
	var lines: PackedStringArray = []
	var v := Engine.get_version_info()
	lines.append("GIGGLE 64: THE GAUNTLET OF FIRE  %s" % GameManager.VERSION)
	lines.append("Written %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("Godot %s.%s.%s (%s build)  %s %s" % [v.major, v.minor, v.patch, "debug" if OS.is_debug_build() else "release", OS.get_name(), OS.get_version()])
	lines.append("GPU %s  (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()])
	lines.append("")
	lines.append("WHERE")
	lines.append("  area %s  (came in by \"%s\")" % [World.area_id, World.entrance_id])
	var p := GameManager.player
	if is_instance_valid(p):
		var pos := p.global_position
		lines.append("  hero at (%.2f, %.2f, %.2f), facing %.0f deg, state %s, on floor %s" % [pos.x, pos.y, pos.z,
			rad_to_deg(atan2(p.forward().x, p.forward().z)), PlayerController.State.keys()[p.state], p.is_on_floor()])
		lines.append("  hearts %.1f / %d" % [p.health.health / 2.0, Progress.max_health / 2])
	lines.append("  time of day %s, game state %s" % [DayNight.clock_text(DayNight.hour()), GameManager.GameState.keys()[GameManager.state]])
	lines.append("  play time %d:%02d, file %d" % [int(Progress.play_time / 3600.0), int(Progress.play_time / 60.0) % 60, Progress.slot])
	lines.append("  cutscene %s, dialogue %s" % [Cutscene.active, Dialogue.active])
	lines.append("")
	lines.append("SETTINGS")
	lines.append("  fps %d, resolution %d, widescreen %s, TRUE N64 %s, pad %s (icons %s)" % [GameManager.frame_rate,
		GameManager.render_index, GameManager.widescreen, GameManager.true_n64, GameManager.using_gamepad,
		Glyphs.FAMILIES[GameManager.glyph_family]])
	lines.append("")
	lines.append("STORY FLAGS")
	var flags: Array = Progress.to_dict().get("flags", {}).keys()
	flags.sort()
	for f in flags:
		lines.append("  " + str(f))
	lines.append("")
	lines.append("What happened? (write it here, or in your message)")
	lines.append("")
	return "\n".join(lines)


static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()


func _draw() -> void:
	if _shown <= 0.0:
		return
	var a := clampf(_shown, 0.0, 1.0)
	var r := GameManager.screen_rect()
	var w := PixelFont.measure(_label).x + 8
	var box := Rect2(r.position.x + 4, 4, w, 13)
	draw_rect(box, Color(0, 0, 0, 0.7 * a))
	PixelFont.draw(self, box.position + Vector2(4, 3), _label, Color(1.0, 0.86, 0.5, a))
