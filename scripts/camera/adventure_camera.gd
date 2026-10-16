class_name AdventureCamera
extends Node3D
## Ocarina of Time-style follow camera.
##
## The rig is never parented to the player's rotation. It owns its own yaw and a
## horizontal "leash" anchor: the camera trails the player inside a distance band
## (like Camera_Normal1's min/max distance), so walking toward it holds it in
## place and turning around does not swing it. The camera only swings behind the
## player when Shift is pressed (fast) or after standing still for
## `idle_realign_delay` seconds (gentle). Mouse input is never read.
##
## Z-targeting uses the OoT camera modes from z_camera_data.inc.c:
## - Parallel (Z held with nothing to lock on, Camera_Parallel1 / CAM_MODE_Z_PARALLEL):
##   the camera swings behind the hero's frozen facing over 4 OoT frames (each
##   frame covering timer / (timer * (timer + 1) / 2) of the remaining angle),
##   then holds that yaw. Distance 2.5x the hero's height, flatter pitch, FOV 45.
## - Lock-on (CAM_MODE_Z_TARGET_UNFRIENDLY, Camera_Battle1): FOV 50.
## - First person (CAM_MODE_FIRST_PERSON / CAM_MODE_AIM_ADULT, Camera_Subj3): the
##   eye moves into the hero's head over a few frames and looks where he looks,
##   FOV 45. Leaving it puts the camera straight back behind him.
## - Aiming the boomerang or bow (CAM_MODE_AIM_BOOMERANG / CAM_MODE_AIM_ADULT,
##   also Camera_Subj3): the same, but the eye stays 50 units (1.5 m) behind
##   the head along the aim.
## - Talking (CAM_MODE_TALK): the view swings to the side so both speakers show.
##
## The pause screen's CAMERA option picks CLASSIC (all of the above, the
## right stick does nothing) or MODERN: in the normal third-person view the
## right stick (or the mouse) orbits the camera round the hero and tilts it.
## While it is being steered OoT's swing and idle realign hold off; they come
## back `modern_follow_delay` seconds after it is let go.

enum Realign { NONE, MANUAL, AUTO }

@export var target: PlayerController

@export_group("Framing")
@export var follow_distance := 5.2
## The camera holds still until the player gets closer than this fraction of the distance.
@export_range(0.3, 1.0) var min_distance_ratio := 0.72
@export_range(0.0, 60.0) var pitch_deg := 16.0
@export var focus_height := 1.3
@export var fov := 60.0

@export_group("Smoothing")
## How quickly the look-at point follows the player horizontally.
@export var position_smoothing := 12.0
## How quickly it follows vertically (lower = calmer during jumps).
@export var vertical_smoothing := 5.0
## Slow drift toward the player's facing while running away from the camera
## (OoT's moving swing). Never applies when moving toward the camera. 0 disables.
@export var follow_swing_rate := 0.45

@export_group("Realignment")
@export var manual_realign_speed_deg := 720.0
@export var manual_realign_min_time := 0.15
@export var manual_realign_max_time := 0.35
@export var auto_realign_speed_deg := 110.0
@export var auto_realign_min_time := 0.8
@export var auto_realign_max_time := 1.8
## Seconds of continuous standing still before the automatic realignment starts.
@export var idle_realign_delay := 3.0
@export var aligned_threshold_deg := 3.0

@export_group("Collision")
@export_flags_3d_physics var collision_mask := 1
@export var collision_radius := 0.3
@export var min_camera_distance := 0.8
## Camera_Normal1's swing round obstacles: while the line to the camera is
## cut short by a wall, the camera turns toward the clearer side at up to
## this rate (degrees per second).
@export var obstacle_swing_deg := 120.0
## Fraction of full distance regained per second after an obstruction clears.
@export var collision_recover_rate := 1.2

@export_group("Targeting")
@export_range(0.0, 0.8) var target_focus_bias := 0.3
@export var target_swing_rate := 5.0
@export var target_fov := 50.0
## Parallel (Z without a target): 2.5x the hero's 1.85 m height.
@export var parallel_distance := 4.6
@export_range(0.0, 60.0) var parallel_pitch_deg := 6.0
@export var parallel_fov := 45.0
## Camera_Parallel1's 4-frame swing at OoT's 20 Hz.
@export var parallel_swing_time := 0.2
## How quickly FOV, pitch and distance blend between modes (per second).
@export var mode_blend_rate := 8.0

## Camera_Subj3 FOV and the frames it takes to move into the head.
@export var first_person_fov := 45.0
@export var first_person_blend := 0.15
@export var talk_fov := 50.0

@export_group("Modern")
## Orbit and tilt rates at full stick tilt (times the CAMERA SPEED setting).
@export var modern_orbit_speed_deg := 150.0
@export var modern_tilt_speed_deg := 80.0
## Camera elevation limits while tilting.
@export var modern_pitch_min_deg := -10.0
@export var modern_pitch_max_deg := 55.0
## Seconds after the last stick or mouse input before OoT's following resumes.
@export var modern_follow_delay := 2.5
## Camera_GetPitchAdjFromFloorHeightDiffs: the normal view tilts with the floor
## ahead of the hero (down a slope or over an edge it looks down, up a slope it
## looks up). Off with 0.
@export var slope_pitch_scale := 1.0
## Most the floor ahead may tilt the view, degrees (down, up).
@export var slope_pitch_max_down := 28.0
@export var slope_pitch_max_up := 14.0

@onready var camera: Camera3D = $Camera3D

var yaw := 0.0
var realign_mode := Realign.NONE
var idle_time := 0.0

var _auto_used := false
var _realign_from := 0.0
var _realign_delta := 0.0
var _realign_t := 0.0
var _realign_duration := 1.0
var _focus := Vector3.ZERO
var _anchor := Vector3.ZERO
var _distance_ratio := 1.0
var _shape := SphereShape3D.new()
var _shake_amp := 0.0
var _shake_time := 0.0
var _shake_left := 0.0
var _pitch := 0.0
var _parallel := false
var _parallel_from := 0.0
var _parallel_t := 0.0
var _fp_t := 0.0
var _fp_from := Transform3D.IDENTITY
## Modern camera: tilt added to the pitch, and seconds since it was last steered.
var _pitch_offset := 0.0
var _manual_time := INF
## Normal1's slopePitchAdj (degrees, + looks down) and the floor heights it
## last found near and far ahead (relative to the hero's ground).
var _slope_pitch := 0.0
var _floor_near := 0.0
var _floor_far := 0.0
var _floor_frame := 0
## A held shot (hold_shot: a door, a chest, walking in): where it looks
## from and at, what it follows, seconds left, and the glide back.
var _shot_left := 0.0
var _shot_eye := Vector3.ZERO
var _shot_at := Vector3.ZERO
var _shot_track: Node3D = null
var _shot_track_off := Vector3.ZERO
var _shot_fov := 55.0
var _shot_blend := 0.0
var _shot_back := 0.0
var _shot_xf := Transform3D.IDENTITY
## Camera_Battle1 looking up at a lock-on target well above the hero: the
## look-at point is lifted toward it (and the camera drops to about his
## eye line) so a flying or perched foe stays in the frame.
var _look_lift := 0.0


func _ready() -> void:
	top_level = true
	camera.fov = fov
	_pitch = pitch_deg
	camera.current = true
	_shape.radius = collision_radius
	if target:
		snap_behind_target()


## OoT's door and chest shots (the door camera of Camera_Demo / the
## Door_Shutter scene, the treasure-box camera): the camera stands at `eye`
## looking at `at` for `time` seconds (following `track`, if given, with `at`
## as its offset), then glides back to the follow view behind the hero over
## `blend` seconds. The eye is kept on this side of any wall.
func hold_shot(eye: Vector3, at: Vector3, time: float, blend := 0.6, track: Node3D = null, shot_fov := 55.0) -> void:
	_shot_track = track
	_shot_track_off = at - track.global_position if track else Vector3.ZERO
	_shot_at = at
	var dir := eye - at
	_shot_eye = at + dir * _cast_fraction(at, eye)
	_shot_left = time
	_shot_blend = maxf(blend, 0.01)
	_shot_back = 0.0
	_shot_fov = shot_fov
	_shot_xf = _shot_transform()


## hold_shot from the first of several eyes that is wholly clear: a clear
## line to `at` (no wall, no creature), nothing within a step of the lens,
## and at least `min_room` meters off. None is: no shot (false), and the
## follow view simply stays.
func hold_shot_from(eyes: Array, at: Vector3, time: float, blend := 0.6, track: Node3D = null, shot_fov := 55.0, min_room := 1.6) -> bool:
	for e: Vector3 in eyes:
		if (e - at).length() < min_room:
			continue
		if _cast_fraction(at, e) < 0.98 or not _line_clear(e, at) or not _room_round(e):
			continue
		hold_shot(e, at, time, blend, track, shot_fov)
		return true
	return false


## Nothing solid and no creature within `r` of a held shot's lens.
func _room_round(eye: Vector3, r := 0.8) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	q.shape = s
	q.transform = Transform3D(Basis(), eye)
	q.collision_mask = collision_mask | 4
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## Nothing solid and no creature between `eye` and `at` (a pillar or a foe
## right in front of a held shot's lens).
func _line_clear(eye: Vector3, at: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(eye, at, collision_mask | 4)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## True while a held shot (or its glide back) is on screen.
func in_shot() -> bool:
	return _shot_left > 0.0 or _shot_back > 0.0


## Lets a held shot go: the camera glides back behind the hero now.
func release_shot() -> void:
	if _shot_left > 0.0:
		_shot_left = 0.0001


## Ends a held shot at once (the next frame is the follow view).
func end_shot() -> void:
	_shot_left = 0.0
	_shot_back = 0.0


func _shot_transform() -> Transform3D:
	var at := _shot_track.global_position + _shot_track_off if is_instance_valid(_shot_track) else _shot_at
	var xf := Transform3D(Basis(), _shot_eye)
	if (at - _shot_eye).length() > 0.01:
		xf = xf.looking_at(at, Vector3.UP)
	return xf


## Lays the held shot (or the glide out of it) over the follow view placed
## this frame.
func _apply_shot(delta: float) -> void:
	if _shot_left > 0.0:
		_shot_left -= delta
		_shot_xf = _shot_transform()
		camera.global_transform = _shot_xf
		camera.fov = _shot_fov
		if _shot_left <= 0.0:
			_shot_back = _shot_blend
		return
	if _shot_back > 0.0:
		_shot_back = maxf(_shot_back - delta, 0.0)
		var k := smoothstep(0.0, 1.0, 1.0 - _shot_back / _shot_blend)
		camera.global_transform = _shot_xf.interpolate_with(camera.global_transform, k)
		camera.fov = lerpf(_shot_fov, camera.fov, k)


## Instantly places the camera behind the player (used at spawn and respawn).
func snap_behind_target() -> void:
	yaw = behind_yaw()
	_fp_t = 0.0
	_focus = target.focus_position() + Vector3.UP * focus_height
	_anchor = _flat(_focus) + _yaw_dir(yaw) * follow_distance
	_distance_ratio = 1.0
	realign_mode = Realign.NONE
	idle_time = 0.0
	_auto_used = false
	_pitch_offset = 0.0
	_manual_time = INF
	_look_lift = 0.0
	_place_camera(0.0)
	# A held shot (an arrival through a door) stays over the reset view.
	if in_shot():
		_apply_shot(0.0)


## Camera-relative movement axes on the ground plane.
func forward_vector() -> Vector3:
	return -_yaw_dir(yaw)


func right_vector() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## Yaw that puts the camera directly behind the player's facing direction.
func behind_yaw() -> float:
	var back := target.global_basis.z
	return atan2(back.x, back.z)


## Short vertical quake (OoT's Player_RequestQuake on a bonk).
func shake(amplitude: float, duration: float) -> void:
	_shake_amp = amplitude
	_shake_time = duration
	_shake_left = duration


func request_realign() -> void:
	_pitch_offset = 0.0
	_manual_time = INF
	_start_realign(Realign.MANUAL, behind_yaw())


## True while the modern camera is being steered (or was, moments ago).
func is_steered() -> bool:
	return _manual_time < modern_follow_delay


func _start_realign(mode: Realign, target_yaw: float) -> void:
	_realign_from = yaw
	_realign_delta = angle_difference(yaw, target_yaw)
	var degrees := absf(rad_to_deg(_realign_delta))
	if mode == Realign.MANUAL:
		_realign_duration = clampf(degrees / manual_realign_speed_deg, manual_realign_min_time, manual_realign_max_time)
	else:
		_realign_duration = clampf(degrees / auto_realign_speed_deg, auto_realign_min_time, auto_realign_max_time)
	_realign_t = 0.0
	realign_mode = mode


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if target.is_first_person():
		end_shot()
		_first_person(delta)
		return
	_fp_t = 0.0
	var lock := target.lock_target
	var parallel := target.parallel
	if parallel and not _parallel:
		_parallel_from = yaw
		_parallel_t = 0.0
	_parallel = parallel
	if Input.is_action_just_pressed("camera_recenter") and not target.is_z_targeting() and not target.is_dead():
		request_realign()

	# Follow the player's position only, never its rotation.
	var desired := target.focus_position() + Vector3.UP * focus_height
	var partner: Node3D = target.talk_partner
	var lift_want := 0.0
	var lock_elev := 0.0
	if lock:
		var tgt := lock.marker_point() - Vector3.UP * 0.35
		desired = desired.lerp(Vector3(tgt.x, maxf(tgt.y, lock.global_position.y + focus_height), tgt.z), target_focus_bias)
		var rise := tgt.y - desired.y
		lock_elev = rad_to_deg(atan2(rise, maxf(_flat(tgt - target.global_position).length(), 1.0)))
		if rise > 0.5:
			lift_want = rise * 0.6
	elif is_instance_valid(partner):
		desired = desired.lerp(partner.global_position + Vector3.UP * focus_height, 0.45)
	var k := 1.0 - exp(-position_smoothing * delta)
	_focus.x = lerpf(_focus.x, desired.x, k)
	_focus.z = lerpf(_focus.z, desired.z, k)
	_focus.y = lerpf(_focus.y, desired.y, 1.0 - exp(-vertical_smoothing * delta))

	_update_idle(delta)
	_modern_steer(delta, lock != null or parallel or is_instance_valid(partner))

	# Leash: keep the camera inside the distance band and derive yaw from where it trails.
	# On horseback (CAM_SET_HORSE) it hangs further back and a little higher.
	var riding := target.is_riding()
	var full := follow_distance * (1.45 if riding else 1.0)
	var offset := _anchor - _flat(_focus)
	if offset.length() < 0.01:
		offset = _yaw_dir(yaw) * full
	var dist := clampf(offset.length(), full * min_distance_ratio, full)
	yaw = atan2(offset.x, offset.z)

	var want_fov := fov
	var want_pitch := pitch_deg + _pitch_offset + (5.0 if riding else 0.0)
	if lock:
		realign_mode = Realign.NONE
		var away := _flat(target.global_position - lock.global_position)
		if away.length() > 0.01:
			yaw = _approach_angle(yaw, atan2(away.x, away.z), target_swing_rate, delta)
		dist = move_toward(dist, full, full * 2.0 * delta)
		want_fov = target_fov
		# A foe high above: drop toward his eye line to look up at it; one far
		# below: look down on it.
		if lock_elev > 8.0:
			want_pitch = lerpf(pitch_deg, -2.0, clampf((lock_elev - 8.0) / 30.0, 0.0, 1.0))
		elif lock_elev < -12.0:
			want_pitch = minf(pitch_deg + (-lock_elev - 12.0) * 0.6, 45.0)
	elif is_instance_valid(partner):
		# Talking: look across both speakers from one side of the line between them.
		realign_mode = Realign.NONE
		var line := _flat(target.global_position - partner.global_position)
		if line.length() > 0.01:
			var base := atan2(line.x, line.z)
			var side := 1.0 if angle_difference(base, yaw) >= 0.0 else -1.0
			yaw = _approach_angle(yaw, base + side * 0.9, 3.0, delta)
		dist = move_toward(dist, full * 0.8, full * delta)
		want_fov = talk_fov
	elif parallel:
		# Camera_Parallel1: swing behind parallel_yaw, then hold it.
		realign_mode = Realign.NONE
		_parallel_t = minf(_parallel_t + delta, parallel_swing_time)
		var t := _parallel_t / parallel_swing_time if parallel_swing_time > 0.0 else 1.0
		yaw = _parallel_from + angle_difference(_parallel_from, target.parallel_yaw) * (1.0 - (1.0 - t) * (1.0 - t))
		dist = move_toward(dist, parallel_distance, full * 2.0 * delta)
		want_fov = parallel_fov
		want_pitch = parallel_pitch_deg
	elif realign_mode != Realign.NONE:
		_realign_t += delta
		var t := clampf(_realign_t / _realign_duration, 0.0, 1.0)
		yaw = _realign_from + _realign_delta * smoothstep(0.0, 1.0, t)
		dist = move_toward(dist, full, full * 2.0 * delta)
		if t >= 1.0:
			realign_mode = Realign.NONE
	elif not is_steered():
		_moving_swing(delta)
		_obstacle_swing(delta, dist)
	if lock or parallel or is_instance_valid(partner) or riding:
		_slope_pitch = move_toward(_slope_pitch, 0.0, 40.0 * delta)
	else:
		_update_slope_pitch(delta)
	want_pitch += _slope_pitch

	var k_mode := 1.0 - exp(-mode_blend_rate * delta)
	camera.fov = lerpf(camera.fov, want_fov, k_mode)
	_pitch = lerpf(_pitch, want_pitch, k_mode)
	_look_lift = lerpf(_look_lift, lift_want, 1.0 - exp(-5.0 * delta))
	_anchor = _flat(_focus) + _yaw_dir(yaw) * dist
	_place_camera(delta)
	if in_shot():
		_apply_shot(delta)


## Camera_GetPitchAdjFromFloorHeightDiffs (CAM_PITCH_FLOOR_CHECK_*): the floor
## 1x and 2.5x the hero's height ahead in the view, probed from 1.2x his
## height above his ground (the far probe stops at walls), weighted 0.8 near
## and 0.2 far. The pitch target then moves by the angles down (or up) to them,
## scaled by their cosine as in Camera_CalcDefaultPitch, eased slower the faster
## he runs (Camera_Normal1's slopePitchAdj).
func _update_slope_pitch(delta: float) -> void:
	if slope_pitch_scale <= 0.0:
		_slope_pitch = 0.0
		return
	if target.is_on_floor():
		var h := 1.85
		var ground := target.global_position.y
		var fwd := -_yaw_dir(yaw)
		var from := Vector3(target.global_position.x, ground + h * 1.2, target.global_position.z)
		var near_d := h
		var far_d := h * 2.5
		var space := get_world_3d().direct_space_state
		var wall := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + fwd * far_d, collision_mask))
		if not wall.is_empty():
			far_d = maxf(_flat(wall.position - from).length() - 0.15, 0.1)
			near_d = minf(near_d, far_d)
		_floor_frame += 1
		_floor_near = _floor_at(space, from + fwd * near_d, ground)
		if _floor_frame % 2 == 0:
			_floor_far = _floor_at(space, from + fwd * far_d, ground)
		var pitch_near := atan2(0.8 * _floor_near, near_d)
		var pitch_far := atan2(0.2 * _floor_far, far_d)
		var adj := pitch_near + pitch_far
		var want := clampf(-rad_to_deg(adj * cos(adj)) * slope_pitch_scale, -slope_pitch_max_up, slope_pitch_max_down)
		var speed_ratio := clampf(_flat(target.velocity).length() / maxf(target.run_speed, 0.1), 0.0, 1.0)
		_slope_pitch = lerpf(_slope_pitch, want, 1.0 - exp(-(1.2 + 1.2 * (1.0 - speed_ratio)) * delta))


## The floor height under `at` (looking at most 8 m down), relative to `ground`;
## no floor in reach counts as the deepest drop.
func _floor_at(space: PhysicsDirectSpaceState3D, at: Vector3, ground: float) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 8.0, collision_mask))
	if hit.is_empty():
		return -(at.y - ground)
	return hit.position.y - ground


## Camera_Subj3: the eye slides into the hero's head, then turns with his view.
func _first_person(delta: float) -> void:
	if _fp_t == 0.0:
		_fp_from = camera.global_transform
	_fp_t = minf(_fp_t + delta / maxf(first_person_blend, 0.001), 1.0)
	var basis := Basis.from_euler(Vector3(target.look_pitch, target.look_yaw, 0.0))
	var eye := Transform3D(basis, target.eye_position())
	var back := target.aim_camera_back()
	if back > 0.0:
		# CAM_MODE_AIM_BOOMERANG / AIM_ADULT: `back` behind the head along the
		# line of sight, pulled in front of any wall.
		var head := target.aim_origin()
		var offset := basis.z * back
		eye.origin = head + offset * _cast_fraction(head, head + offset)
	var k := smoothstep(0.0, 1.0, _fp_t)
	if _fp_t >= 1.0:
		# Settled in: the eye still eases when the aim distance changes (an item
		# swapped in place, the bow for the boomerang).
		eye.origin = camera.global_position.lerp(eye.origin, 1.0 - exp(-22.0 * delta))
		_fp_from = eye
	camera.global_transform = _fp_from.interpolate_with(eye, k)
	camera.fov = lerpf(camera.fov, first_person_fov, k)
	yaw = target.look_yaw
	realign_mode = Realign.NONE
	idle_time = 0.0


## MODERN camera: the right stick (or the mouse) orbits the camera round the
## hero and tilts it. Steering cancels any realign and restarts the idle timer.
func _modern_steer(delta: float, busy: bool) -> void:
	_manual_time += delta
	if not GameManager.camera_modern or busy or target.is_dead() or not target.input_enabled:
		return
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var m := GameManager.take_mouse_motion()
	var rate := GameManager.camera_speed_scale()
	var inv_x := -1.0 if GameManager.camera_invert_x else 1.0
	var inv_y := -1.0 if GameManager.invert_look else 1.0
	# Right looks right (the camera swings the other way round the hero); up
	# looks up (the camera drops).
	var turn := (stick.x * deg_to_rad(modern_orbit_speed_deg) * rate * delta + m.x * GameManager.mouse_sensitivity) * inv_x
	var tilt := (stick.y * modern_tilt_speed_deg * rate * delta + rad_to_deg(m.y * GameManager.mouse_sensitivity)) * inv_y
	if is_steered() == false and stick == Vector2.ZERO and m == Vector2.ZERO:
		# Let go long enough: OoT's following is back; ease the tilt home.
		_pitch_offset = lerpf(_pitch_offset, 0.0, 1.0 - exp(-1.5 * delta))
		return
	if turn == 0.0 and tilt == 0.0:
		return
	_manual_time = 0.0
	realign_mode = Realign.NONE
	idle_time = 0.0
	_auto_used = false
	_pitch_offset = clampf(pitch_deg + _pitch_offset + tilt, modern_pitch_min_deg, modern_pitch_max_deg) - pitch_deg
	var c := _flat(_focus)
	var off := _anchor - c
	if off.length() < 0.01:
		off = _yaw_dir(yaw) * follow_distance
	_anchor = c + off.rotated(Vector3.UP, -turn)


func _update_idle(delta: float) -> void:
	if target.is_idle_for_camera():
		idle_time += delta
		if idle_time >= idle_realign_delay and not _auto_used and realign_mode == Realign.NONE and not target.is_z_targeting():
			_auto_used = true
			var b := behind_yaw()
			if absf(rad_to_deg(angle_difference(yaw, b))) > aligned_threshold_deg:
				_start_realign(Realign.AUTO, b)
	else:
		idle_time = 0.0
		_auto_used = false
		if realign_mode == Realign.AUTO:
			realign_mode = Realign.NONE


func _moving_swing(delta: float) -> void:
	if follow_swing_rate <= 0.0:
		return
	var riding := target.is_riding()
	var speed := _flat(target.horse.velocity if riding else target.velocity).length()
	if speed < 0.5:
		return
	var diff := angle_difference(yaw, behind_yaw())
	if absf(diff) > deg_to_rad(100.0 if not riding else 150.0):
		return
	var speed_ratio := clampf(speed / target.run_speed, 0.0, 1.0)
	# The horse camera swings in behind her much more firmly.
	var rate := follow_swing_rate * (3.0 if riding else 1.0)
	yaw += diff * (1.0 - exp(-rate * speed_ratio * delta))


func _place_camera(delta: float) -> void:
	var horiz := _anchor - _flat(_focus)
	var offset := horiz + Vector3.UP * horiz.length() * tan(deg_to_rad(_pitch))
	var allowed := _cast_fraction(_focus, _focus + offset)
	if allowed < _distance_ratio or delta == 0.0:
		_distance_ratio = allowed
	else:
		_distance_ratio = minf(allowed, _distance_ratio + collision_recover_rate * delta)
	var length := offset.length() * _distance_ratio
	var eye := _focus + offset.normalized() * length
	if length < min_camera_distance:
		# Backed against a wall: rather than push into it, the camera rises
		# over the hero's head and looks down past him (OoT lifts the eye the
		# same way when its line is blocked close behind Link).
		var lift := offset.normalized() * min_camera_distance * 0.6 + Vector3.UP * (min_camera_distance + 0.6)
		eye = _focus + lift * _cast_fraction(_focus, _focus + lift)
	camera.global_position = eye
	var look := _focus + Vector3.UP * _look_lift
	if (look - eye).length() > 0.05:
		camera.look_at(look, Vector3.UP)
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var k := _shake_left / _shake_time
		camera.global_position.y += sin(_shake_left * 70.0) * _shake_amp * k


## Camera_Normal1's obstacle swing: with the way back to the camera blocked
## (it sits much closer than it wants to), look a little either side and turn
## toward the side with the most room, so a corner or a pillar pushes the
## camera round instead of in.
func _obstacle_swing(delta: float, dist: float) -> void:
	if obstacle_swing_deg <= 0.0 or _distance_ratio > 0.7:
		return
	var best := 0.0
	var best_room := _distance_ratio
	var h := tan(deg_to_rad(_pitch))
	for a: float in [0.4, -0.4, 0.8, -0.8]:
		var dir := _yaw_dir(yaw + a)
		var room := _cast_fraction(_focus, _focus + (dir + Vector3.UP * h) * dist)
		if room > best_room + 0.25:
			best_room = room
			best = a
	if best != 0.0:
		yaw += signf(best) * minf(deg_to_rad(obstacle_swing_deg) * delta, absf(best))


## Fraction of the focus->camera segment a small sphere can travel before hitting the world.
func _cast_fraction(from: Vector3, to: Vector3) -> float:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _shape
	params.transform = Transform3D(Basis(), from)
	params.motion = to - from
	params.collision_mask = collision_mask
	var result := get_world_3d().direct_space_state.cast_motion(params)
	return result[0] if result.size() > 0 else 1.0


func _approach_angle(from: float, to: float, rate: float, delta: float) -> float:
	return from + angle_difference(from, to) * (1.0 - exp(-rate * delta))


func _yaw_dir(y: float) -> Vector3:
	return Vector3(sin(y), 0.0, cos(y))


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
