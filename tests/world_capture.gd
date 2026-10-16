extends Node
## Screenshots of the overworld areas for visual checks: for each area, the view
## from every entrance (after the walk-in), a few seconds of running, and two
## high overview shots.
##
## Run windowed (needs a GPU):
##   Godot --path <project> --resolution 640x480 res://tests/world_capture.tscn -- --automation --out=<dir> [--areas=field,village] [--quick]

var out_dir := "user://world_captures"
var _main: Node


func _ready() -> void:
	var areas: Array = WorldData.WARP_ORDER.filter(func(a: String) -> bool: return a != "test_area")
	var quick := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--areas="):
			areas = Array(a.substr(8).split(","))
		elif a == "--quick":
			quick = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	for area: String in areas:
		var scene: Node = load(WorldData.scene_path(area)).instantiate()
		var entrances: Array = []
		for m in scene.get_node("Entrances").get_children():
			entrances.append(m.name)
		var size: Vector2 = Vector2(200, 200)
		scene.free()
		for e: String in entrances:
			await _load(area, e)
			await _frames(70)
			await _shot("%s_%s" % [area, e])
			if quick and e != entrances[0]:
				continue
			var p: PlayerController = GameManager.player
			p.debug_use_move_input = true
			p.debug_move_input = p.forward()
			await _frames(150)
			p.debug_use_move_input = false
			await _shot("%s_%s_run" % [area, e])
		await _load(area, entrances[0])
		await _frames(30)
		await _overview(area, "overview_s", Vector3(0, 70, 0), Vector3(0, 0, 1))
		await _overview(area, "overview_n", Vector3(0, 70, 0), Vector3(0, 0, -1))
	get_tree().quit()


func _load(area: String, entrance: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _overview(area: String, label: String, height: Vector3, from_dir: Vector3) -> void:
	var cam := Camera3D.new()
	cam.far = 600.0
	cam.fov = 60.0
	World.area_node.add_child(cam)
	var r: Vector3 = World.area_node.get_meta("bounds", Vector3(100, 100, 0))
	var span := maxf(r.x, r.y) * 1.25
	cam.global_position = Vector3(0, span * 0.75, 0) + from_dir * span
	cam.look_at(-from_dir * span * 0.15, Vector3.UP)
	cam.current = true
	var env: Environment = World.area_node.get_node("WorldEnvironment").environment
	env.fog_enabled = false
	await _frames(5)
	await _shot("%s_%s" % [area, label])
	env.fog_enabled = true
	cam.queue_free()
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: SubViewport = _main.get_node("GameView/GameViewport")
	var img := vp.get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
