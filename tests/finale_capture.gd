extends "res://tests/armory_capture.gd"
## Screenshots of Beta 1.5.0 "The Astral Rift" (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/finale_capture.tscn -- --automation --out=<dir>
## The crack over the Ridge and the Rift's mouth, Velloran in his ward, the
## Rift's drifts (the hub, the dream stair, a drift from afar), Avalon's
## garden, the prison arena (Firebuns, the shadow hands), Serielye, Pip in
## the square and the Golden Bun's band.

const FLAGS := ["castle_fallen", "ch4:war", "ch4:sealed", "ch4:peace", "ch5:knight", "ch5:trained", "ch5:returned",
	"ch5:cinder_done", "ch5:front_seen", "tech:parry", "front:parry_done", "ch5:ridge_open", "ch5:ridge_reached", "ch5:camps_done",
	"ch5:mara_done", "ch5:rift_seen", "ch5:velloran_met"]

var _cam: Camera3D


func _ready() -> void:
	out_dir = "user://finale_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Guide.auto_scenes = false
	Progress.reset()
	for f in FLAGS:
		Progress.set_flag(f)
	Progress.give_sword("bun")
	DayNight.set_hour(15.0)
	# The Ridge: the crack, and (once opened) the Rift's mouth.
	Progress.set_flag("ch5:dream")
	Progress.set_flag("ch5:rift_open")
	await _load("black_water_ridge", "warp_ridge_keep")
	await _frames(60)
	var mouth := _mark("cs_rift_mouth")
	await _look(mouth + Vector3(-10.0, 4.0, 8.0), mouth + Vector3(0, 6.0, -10.0), "01_ridge_crack_and_mouth")
	await _look(mouth + Vector3(-4.0, 2.0, 3.0), mouth + Vector3.UP * 1.6, "02_rift_mouth_close")
	# The Sanctum Ruin: Velloran in his ward.
	Progress.flags.erase("ch5:velloran_done")
	await _load("sanctum_ruin", "")
	await _frames(60)
	var v := _mark("cs_ruin_velloran")
	await _look(v + Vector3(6.0, 3.0, 10.0), v + Vector3.UP * 1.6, "03_velloran_circle")
	await _look(v + Vector3(1.6, 1.8, 3.6), v + Vector3.UP * 2.0, "04_velloran_close")
	# The Astral Rift.
	Progress.set_flag("ch5:velloran_done")
	Progress.set_flag("rift:arrived")
	await _load("astral_rift", "from_black_water_ridge")
	await _frames(60)
	var hub := _mark("cs_rift_hub")
	await _look(hub + Vector3(0.0, 6.0, 22.0), hub + Vector3.UP * 4.0, "05_hub_and_dream_stair")
	await _look(hub + Vector3(-20.0, 20.0, 40.0), hub + Vector3(-60.0, 10.0, -40.0), "06_drifts_afar")
	PlayerItems.dreaming = true
	get_tree().call_group("dream_light", "dream", true)
	await _frames(5)
	await _look(hub + Vector3(6.0, 3.0, 9.0), hub + Vector3.UP * 6.0, "07_dream_stair_dreaming")
	var f2 := _mark("f2_in")
	await _look(f2 + Vector3(0.0, 5.0, 10.0), f2 + Vector3(0, 0, -20.0), "08_spires_drift")
	var f3 := _mark("f3_in")
	await _look(f3 + Vector3(0.0, 5.0, 10.0), f3 + Vector3(0, 0, -20.0), "09_burning_halls")
	var f4 := _mark("f4_in")
	await _look(f4 + Vector3(0.0, 5.0, 10.0), f4 + Vector3(0, 0, -20.0), "10_barrow_of_night")
	var f5 := _mark("f5_in")
	await _look(f5 + Vector3(0.0, 6.0, 8.0), f5 + Vector3(0, 0, -16.0), "11_starfield_dreaming")
	PlayerItems.dreaming = false
	get_tree().call_group("dream_light", "dream", false)
	await _frames(5)
	await _look(f5 + Vector3(0.0, 6.0, 8.0), f5 + Vector3(0, 0, -16.0), "12_starfield_awake")
	# Avalon's garden.
	var av := _mark("cs_avalon")
	var a := Cutscene.actor("avalon", av, 0.0, &"talk", true)
	if a:
		a.rotation.y = PI
	await _look(av + Vector3(2.0, 1.8, 4.0), av + Vector3.UP * 1.4, "13_avalon_garden")
	await _look(av + Vector3(0.6, 1.7, 2.2), av + Vector3.UP * 1.6, "14_avalon_close")
	# The prison: Firebuns, the hands, Serielye.
	var pr := _mark("cs_final")
	await _look(pr + Vector3(0.0, 6.0, 16.0), pr + Vector3(0, 1.0, -6.0), "15_prison_arena")
	for h in get_tree().get_nodes_in_group("shadow_hands"):
		h.call("wake", null)
	await _frames(30)
	await _look(pr + Vector3(5.0, 4.0, 10.0), pr + Vector3(0, 3.0, -6.0), "16_shadow_hands")
	var s := Cutscene.actor("serielye", pr + Vector3(2.0, 0, 0), 0.0, &"raise", true)
	if s:
		s.rotation.y = PI * 0.8
	await _frames(40)
	await _look(pr + Vector3(4.0, 1.7, 3.6), pr + Vector3(2.0, 1.6, 0.0), "17_serielye")
	# Pip in the square, the Golden Bun's band.
	Progress.reset()
	await _load("castle_town", "")
	await _frames(60)
	await _look(Vector3(8.0, 2.4, 14.0), Vector3(3.4, 1.4, 6.6), "18_pip_and_market")
	await _load("ct_08", "from_castle_town")
	await _frames(60)
	await _look(Vector3(2.0, 2.4, 3.6), Vector3(0.0, 1.0, -4.0), "19_golden_bun_band")
	await _load("aw_2", "from_batela_fells")
	await _frames(60)
	await _look(Vector3(0.0, 1.8, 2.4), Vector3(0.0, 1.0, -1.5), "20_ashwick_tent")
	get_tree().quit()


func _mark(n: String) -> Vector3:
	var m := World.area_node.find_child(n, true, false) as Node3D
	return m.global_position if m else Vector3.ZERO


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


func _load(area: String, entrance: String) -> void:
	_cam = null
	await super._load(area, entrance)
