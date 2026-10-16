extends "res://tests/armory_capture.gd"
## A screenshot of the guiding light (Guide, Beta 1.5.0) in the field, a new
## game's goal being the Lake Shrine (the road south-east), from near and far.
##   Godot --path <project> --resolution 640x480 res://tests/beacon_capture.tscn -- --automation --out=<dir>


func _ready() -> void:
	out_dir = "user://beacon_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Guide.auto_scenes = false
	Progress.reset()
	Progress.set_flag("woke_up")
	DayNight.set_hour(13.0)
	await _load("field", "from_village")
	await _frames(90)
	await _shot("01_field_from_village")
	var p := GameManager.player
	var exit := World.area_node.find_child("To_south_road", true, false) as Node3D
	if exit and p:
		p.global_position = exit.global_position + Vector3(-40, 0, -30)
		p.global_position.y = 3.0
		p.face_direction(exit.global_position - p.global_position)
		var rig := World.area_node.get_node("CameraRig")
		rig.snap_behind_target()
		await _frames(60)
		await _shot("02_toward_the_light")
	DayNight.set_hour(21.0)
	await _frames(40)
	await _shot("03_at_night")
	get_tree().quit()
