extends "res://tests/armory_capture.gd"
## Screenshots of the Questlord's Greatsword (Beta 1.4.0) on the hero, from a
## free camera round him (windowed):
##   Godot --path <project> --resolution 640x480 res://tests/greatsword_capture.tscn -- --automation --out=<dir>
## Sheathed (shield on the arm, the long scabbard on the back), drawn and held
## ready in both hands (shield on the back), the blade guard, a swing, the
## Great Spin, and Aladriel handing it over in the armory.

var _cam: Camera3D


func _ready() -> void:
	out_dir = "user://greatsword_captures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	GameManager.skip_title = true
	Progress.reset()
	Progress.give_shield("iron")
	Progress.give_sword("great")
	Progress.set_flag(PlayerCombat.TECH_SPIN)
	await _load("field", "from_village")
	await _frames(60)
	var p := GameManager.player
	p.face_direction(Vector3(0, 0, -1))
	await _frames(10)
	await _around(p, "1_sheathed")
	p._set_sword_drawn(true)
	await _frames(20)
	await _around(p, "2_ready")
	Input.action_press("shield")
	await _frames(25)
	await _around(p, "3_guard")
	Input.action_release("shield")
	await _frames(15)
	await _tap("attack")
	await _frames(7)
	await _view_from(p, Vector3(2.6, 1.4, -1.2), "4_swing_a")
	await _frames(6)
	await _view_from(p, Vector3(2.6, 1.4, -1.2), "4_swing_b")
	await _frames(40)
	p.start_spin()
	await _frames(10)
	await _view_from(p, Vector3(0, 2.4, -3.2), "5_spin")
	await _frames(40)
	# The hand-over in the armory, knighted, without the sword yet.
	Progress.reset()
	Progress.set_flag("ch5:knight")
	_cam = null
	await _load("armory", "from_castle_town")
	p = GameManager.player
	await _frames(60)
	var ala := World.area_node.get_node("Features/Aladriel") as Node3D
	await _face_npc(p, ala, 1.0)
	await _tap("interact")
	for i in 10:
		await _secs(1.0)
		if p.item_get:
			break
		await _tap("interact")
	await _secs(1.2)
	await _shot("6_got_greatsword")
	await _finish_talk(p)
	await _frames(30)
	print("greatsword_capture: has great=%s equipped=%s" % [Progress.has_sword("great"), Progress.sword])
	get_tree().quit()


## Four views round the hero: front-left, front-right, side, back.
func _around(p: PlayerController, tag: String) -> void:
	for v in [["fl", Vector3(-1.8, 1.5, -2.4)], ["fr", Vector3(2.2, 1.4, -2.0)], ["side", Vector3(3.0, 1.3, 0.0)],
			["back", Vector3(0.6, 1.7, 2.8)]]:
		await _view_from(p, v[1], tag + "_" + v[0])


## A camera at `off` in the hero's own frame (-Z is where he faces), on him.
func _view_from(p: PlayerController, off: Vector3, shot_name: String) -> void:
	if _cam == null or not is_instance_valid(_cam):
		_cam = Camera3D.new()
		_cam.fov = 50.0
		World.area_node.add_child(_cam)
	var basis := Basis(Vector3.UP, p.facing_yaw)
	_cam.global_position = p.global_position + basis * off
	_cam.look_at(p.global_position + Vector3.UP * 1.05)
	_cam.make_current()
	await _frames(2)
	await _shot(shot_name)
