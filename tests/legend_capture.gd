extends Node
## Screenshots of Lothelye's legend (Story.legend) at the Hidden Forest's
## pedestal, for visual checks (windowed). A frame is saved once every text
## box has drawn its text, and every `--every=` seconds between boxes:
##   Godot --path <project> --resolution 640x480 res://tests/legend_capture.tscn -- --out=<dir> [--every=1.5]

var out_dir := "user://legend_captures"
var every := 1.5
var _main: Node
var _n := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--every="):
			every = float(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	World.area_id = "hidden_forest"
	World.entrance_id = "pedestal"
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(20)
	Progress.give_sword("bun")
	var ped: BunPedestal = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is BunPedestal:
			ped = n
	var p := GameManager.player
	p.global_position = ped.global_position + Vector3(0, 0.1, 1.2)
	p.face_direction(Vector3(0, 0, -1))
	# Let the area title card fade.
	await _secs(4.0)
	Story.legend(ped)
	var since := 0.0
	var shot_page := false
	while true:
		await _secs(0.1)
		since += 0.1
		if Dialogue.active and Dialogue.phase == Dialogue.Phase.WAITING:
			if not shot_page:
				await _shot()
				shot_page = true
			await _secs(0.2)
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
			await _frames(3)
			ev = InputEventAction.new()
			ev.action = "interact"
			ev.pressed = false
			Input.parse_input_event(ev)
			since = 0.0
		elif not Dialogue.active:
			shot_page = false
			if since >= every:
				await _shot()
				since = 0.0
			if not Cutscene.active:
				break
		else:
			shot_page = false
	await _secs(0.5)
	await _shot()
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot() -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	_n += 1
	vp.get_texture().get_image().save_png(out_dir.path_join("legend_%03d.png" % _n))
