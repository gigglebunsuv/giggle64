extends "res://tests/armory_capture.gd"
## Screenshots of Beta 1.4.0 "Black Water Ridge" (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/ridge_capture.tscn -- --automation --out=<dir>
## The knights' camp in the marsh (the quintain, the black water and the
## road), the Ridge (its camps, the falls, the Keep), Ridge Keep's storeys,
## the Jailer, the Iron Flail thrown, Mara at the top of the falls, and the
## memorial banner in Castle Town.

const CH5 := ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned",
	"ch5:cinder_done", "ch5:front_seen"]

var _cam: Camera3D


func _ready() -> void:
	out_dir = "user://ridge_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	for f in CH5:
		Progress.set_flag(f)
	Progress.give_shield("iron")
	Progress.give_sword("bun")
	DayNight.set_hour(14.0)
	# The marsh: the camp, the quintain, the black water over the road.
	await _load("marsh", "")
	await _frames(60)
	await _look(Vector3(-24.0, 4.0, 14.0), Vector3(-40.0, 0.5, 4.0), "01_front_camp")
	await _look(Vector3(-36.0, 3.0, 6.0), Vector3(-56.0, 0.5, 6.0), "02_black_water_road")
	Progress.set_flag("ch5:ridge_open")
	await _frames(10)
	await _look(Vector3(-36.0, 3.0, 6.0), Vector3(-56.0, 0.5, 6.0), "03_road_parted")
	# The Ridge.
	Progress.set_flag("ch5:ridge_reached")
	await _load("black_water_ridge", "from_marsh")
	await _frames(60)
	await _look(Vector3(66.0, 6.0, 46.0), Vector3(20.0, 10.0, 10.0), "04_ridge_way_in")
	await _look(Vector3(40.0, 14.0, 34.0), Vector3(24.0, 6.0, 16.0), "05_camp_one")
	await _look(Vector3(25.0, 7.8, 30.5), Vector3(24.0, 7.0, 24.0), "05b_camp_knights")
	await _look(Vector3(-20.0, 24.0, 6.0), Vector3(-40.0, 16.0, -12.0), "06_camp_two")
	await _look(Vector3(30.0, 34.0, -40.0), Vector3(-6.0, 40.0, -110.0), "07_keep_from_camp_three")
	await _look(Vector3(10.0, 40.0, -80.0), Vector3(-6.0, 38.0, -112.0), "08_keep_gate")
	DayNight.set_hour(23.0)
	await _frames(20)
	await _look(Vector3(30.0, 34.0, -40.0), Vector3(-6.0, 40.0, -110.0), "09_keep_at_night")
	DayNight.set_hour(14.0)
	# Ridge Keep.
	Progress.set_flag("ch5:camps_done")
	await _load("ridge_keep", "from_black_water_ridge")
	await _frames(60)
	await _look(Vector3(0.0, 2.0, 26.0), Vector3(0.0, 1.5, 0.0), "10_keep_gate_hall")
	await _look(Vector3(10.0, 3.5, 9.0), Vector3(-6.0, 1.0, -8.0), "11_hall")
	await _look(Vector3(57.0, 3.0, 6.0), Vector3(48.0, 0.5, -3.0), "12_crypt")
	await _look(Vector3(-24.0, 11.5, 8.0), Vector3(-34.0, 9.0, -2.0), "13_gaol_gaoler")
	await _look(Vector3(-27.0, 10.6, 3.0), Vector3(-32.0, 10.0, 0.0), "13b_gaoler_close")
	await _look(Vector3(8.0, 20.0, -28.0), Vector3(-2.0, 17.0, -40.0), "14_bridge_chasm")
	await _look(Vector3(-24.0, 20.5, 8.0), Vector3(-34.0, 20.0, -6.0), "15_chains_bells")
	await _look(Vector3(0.0, 28.0, 10.0), Vector3(0.0, 25.0, -12.0), "16_ramparts")
	await _look(Vector3(5.0, 26.6, -36.0), Vector3(0.0, 25.4, -46.0), "17_falls_mara")
	await _look(Vector3(1.6, 25.9, -42.6), Vector3(0.0, 25.4, -46.0), "17c_mara_close")
	await _look(Vector3(0.0, 30.0, -28.0), Vector3(0.0, 30.0, -70.0), "17b_the_falls")
	# The Iron Flail thrown at a grate in the hall.
	var p := GameManager.player
	GetItem.apply(p, "iron_flail")
	Progress.assign("item_x", "iron_flail")
	p.global_position = Vector3(0.0, 0.3, -6.0)
	p.face_direction(Vector3(0, 0, -1))
	if is_instance_valid(_cam):
		_cam.queue_free()
	_cam = null
	var rig := World.area_node.get_node("CameraRig")
	rig.snap_behind_target()
	for c in rig.find_children("*", "Camera3D", true, false):
		(c as Camera3D).make_current()
	await _frames(20)
	await _tap("item_x")
	await _frames(14)
	await _shot("18_flail_thrown")
	await _frames(60)
	# The memorial in Castle Town.
	Progress.set_flag("ch5:mara_done")
	_cam = null
	await _load("castle_town_restored", "")
	await _frames(60)
	await _look(Vector3(-8.0, 2.0, 2.0), Vector3(-12.0, 3.0, -4.0), "19_memorial")
	get_tree().quit()


## A still from `eye` looking at `at`.
func _look(eye: Vector3, at: Vector3, shot_name: String) -> void:
	if _cam == null or not is_instance_valid(_cam):
		_cam = Camera3D.new()
		_cam.fov = 55.0
		_cam.far = 500.0
		World.area_node.add_child(_cam)
	_cam.global_position = eye
	_cam.look_at(at)
	_cam.make_current()
	await _frames(3)
	await _shot(shot_name)
