class_name Horse
extends CharacterBody3D
## Biscuit, the hero's horse, ridden like Epona in OoT (ovl_En_Horse,
## z_en_horse.c). Numbers are OoT units per 20 Hz frame, as on the hero.
##
## The stick is read raw, as EnHorse_StickDirection does: up is "on ahead"
## and left/right turn her, whatever the camera is doing.
##
## Standing (EnHorse_MountedIdle / MountedTurn / Reverse): stick ahead walks
## on after a short gather (8 frames); stick aside (over 45 degrees) wheels
## her round on the spot (800 a frame); stick back backs her up at 2.
##
## Riding (EnHorse_UpdateSpeed):
## - Three gaits with their own base speeds: walk 3, trot 6, gallop 8. The
##   speed steps by 0.5 a frame toward base / 54 x the stick (so a full stick
##   gallops a little over 8), easing back by 0.06 above the base; it moves
##   up to a trot over 3 and a gallop at 6, and back down below them.
## - The turn follows the stick's angle to her heading cubed
##   (angle * (angle / 32236)^2), scaled by traction (2.2 - speed / 14) and
##   capped at 400 x traction a frame: tight turns while slow, wide at speed.
## - Pulling the stick back (cos <= -0.5) brakes by 0.3 a frame (at a gallop
##   she skids to a halt, EnHorse_Stopping, 0.6 a frame); letting go slows
##   her by 0.06 a frame, and a walk stops at the end of its stride.
## - A spurs her on (EnHorse_CheckBoost): one of six carrots; her speed climbs
##   to 14 over 16 frames, then eases back. The first spent carrot comes back
##   after 60 frames and the rest every 11; spend all six and they all come
##   back together after 140 (EnHorse_RegenBoost).
## - Galloping into a fence low enough (EnHorse_CheckFenceJump: 19-72 units,
##   with level ground beyond) she jumps it (speed 12, a 0.8 s leap); slower,
##   or anything taller, she pulls up and rears.
## She won't wade into deep water. Unridden she stands and swishes her tail;
## called with a Sugar Cube she gallops over to the hero.

signal jumped
signal spurred

enum Mode { FREE, COME, MOUNTED, JUMP, REAR }
enum Gait { STAND, WALK, TROT, GALLOP }
## What she is doing under the rider (ENHORSE_ACT_MOUNTED_*).
enum Act { IDLE, TURN, WALK, TROT, GALLOP, STOP, REVERSE }

const OOT_FPS := 20.0
const OOT_RATE := 1.5
const UNIT := 0.03
const BINANG := TAU / 65536.0
const BASE_SPEED := {Gait.STAND: 3.0, Gait.WALK: 3.0, Gait.TROT: 6.0, Gait.GALLOP: 8.0}
const BOOST_SPEED := 14.0
const CARROTS := 6

@export var turn_speed := 400.0
## Whether she has been given to the hero (Progress flag "horse_owned").
var mode := Mode.FREE
var gait := Gait.STAND
var act := Act.IDLE
var _act_t := 0.0
var _wait := 0.0
## Ground speed in OoT units per frame, and her heading (Godot yaw).
var speed := 0.0
var yaw := 0.0
var carrots := CARROTS
var rider: PlayerController = null
var model: CharacterModel
var _regen := 0.0
var _boosting := false
var _boost_t := 0.0
var _boost_decel := false
var _first_regen := true
var _jump_t := 0.0
var _jump_y := 0.0
var _jump_h := 1.0
var _rear_t := 0.0
var _come_to := Vector3.ZERO
var _vy := 0.0
var _step_phase := 0.0
var _seat: Node3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_max_angle = deg_to_rad(40.0)
	floor_snap_length = 0.5
	add_to_group("horses")
	add_to_group("interactable")
	model = get_node_or_null("Model") as CharacterModel
	_seat = model.find_child("Saddle", true, false) as Node3D if model else null
	yaw = rotation.y
	# A low sphere carries her on the ground; a box is her body above the legs.
	var feet := CollisionShape3D.new()
	feet.name = "Feet"
	var s := SphereShape3D.new()
	s.radius = 0.35
	feet.shape = s
	feet.position = Vector3(0, 0.35, 0)
	add_child(feet)
	var trunk := CollisionShape3D.new()
	trunk.name = "Trunk"
	var b := BoxShape3D.new()
	b.size = Vector3(0.75, 0.9, 2.0)
	trunk.shape = b
	trunk.position = Vector3(0, 1.25, 0)
	add_child(trunk)


## A horse with her model, at `pos` under `parent`.
static func spawn(parent: Node, pos: Vector3, heading: float) -> Horse:
	var h := Horse.new()
	h.name = "Biscuit"
	var m: Node3D = load("res://assets/models/horse.tscn").instantiate()
	m.name = "Model"
	h.add_child(m)
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = load("res://assets/models/blob_shadow_mesh.tres")
	shadow.set_script(load("res://scripts/systems/blob_shadow.gd"))
	shadow.set("radius", 0.9)
	h.add_child(shadow)
	h.rotation.y = heading
	parent.add_child(h)
	h.global_position = pos
	return h


## OoT units per frame -> meters per second.
static func to_mps(units: float) -> float:
	return units * OOT_RATE * OOT_FPS * UNIT


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


## Where the rider's hips go.
func seat_transform() -> Transform3D:
	var p := _seat.global_position if _seat else global_position + Vector3.UP * 1.6
	return Transform3D(Basis(Vector3.UP, yaw), p)


# --- Interaction ----------------------------------------------------------------

func can_interact(by: Node3D) -> bool:
	return rider == null and mode in [Mode.FREE, Mode.COME] and by is PlayerController \
		and not (by as PlayerController).is_carrying()


func interact_label() -> String:
	return "RIDE"


## She's big: A reaches her from further than a person.
func interact_reach() -> float:
	return 2.6


func interact(player: Node) -> void:
	if player is PlayerController and can_interact(player as Node3D):
		(player as PlayerController).mount(self)


func on_mounted(p: PlayerController) -> void:
	rider = p
	mode = Mode.MOUNTED
	gait = Gait.STAND
	_set_act(Act.IDLE)
	speed = 0.0
	remove_from_group("interactable")
	Sfx.play("horse_snort", -6.0, 0.05)


func on_dismounted() -> void:
	rider = null
	mode = Mode.FREE
	speed = 0.0
	gait = Gait.STAND
	_boosting = false
	_boost_decel = false
	add_to_group("interactable")


## A Sugar Cube: gallop over to `where` (the hero).
func call_to(where: Vector3) -> void:
	if rider:
		return
	_come_to = where
	mode = Mode.COME
	Sfx.play("horse_neigh", -4.0, 0.05)


## A spur (EnHorse_CheckBoost). Returns false when there's no carrot left.
func spur() -> bool:
	if _boosting or mode != Mode.MOUNTED or not (act in [Act.WALK, Act.TROT, Act.GALLOP]) or _wait > 0.0:
		return false
	if carrots <= 0:
		if randf() < 0.1:
			Sfx.play("horse_neigh", -8.0, 0.05)
		return false
	carrots -= 1
	_boosting = true
	_boost_decel = false
	_boost_t = 0.0
	if carrots == 0:
		_regen = 140.0
	elif _first_regen:
		_regen = 60.0
		_first_regen = false
	GameManager.rumble(0.7, 0.3)
	Sfx.play("horse_spur", -4.0, 0.05)
	spurred.emit()
	return true


# --- Update ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var f := delta * OOT_FPS
	match mode:
		Mode.FREE:
			speed = move_toward(speed, 0.0, 0.5 * f)
		Mode.COME:
			_come(f)
		Mode.MOUNTED:
			_mounted(f)
		Mode.JUMP:
			_jump(delta, f)
		Mode.REAR:
			speed = 0.0
			_rear_t -= delta
			if _rear_t <= 0.0:
				mode = Mode.MOUNTED if rider else Mode.FREE
	_regen_carrots(f)
	rotation.y = yaw
	var v := forward() * to_mps(speed)
	velocity.x = v.x
	velocity.z = v.z
	if mode != Mode.JUMP:
		if is_on_floor():
			velocity.y = -0.5
		else:
			# OoT's horse falls hard (gravity 3.5 a frame).
			velocity.y = maxf(velocity.y - to_mps(3.5) * OOT_FPS * delta, -to_mps(30.0))
	move_and_slide()
	_animate(delta)


func _come(f: float) -> void:
	var to := _come_to - global_position
	to.y = 0.0
	if to.length() < 3.0:
		speed = move_toward(speed, 0.0, 1.0 * f)
		if speed == 0.0:
			mode = Mode.FREE
		return
	var want := atan2(-to.x, -to.z)
	yaw += clampf(angle_difference(yaw, want), -1200.0 * BINANG * f, 1200.0 * BINANG * f)
	speed = move_toward(speed, BASE_SPEED[Gait.GALLOP], 0.5 * f)
	if _blocked_ahead():
		speed = 0.0
		mode = Mode.FREE


func _mounted(f: float) -> void:
	var mag := rider.stick_magnitude()
	var rel := rider.ride_stick_angle(yaw) if mag > 0.0 else 0.0
	# Aiming from the saddle, the stick is the bow's (EnHorse_PlayerCanMove).
	var can_move := not rider.is_riding_aim()
	var back := mag > 10.0 and cos(rel) <= -0.5
	_act_t += f
	match act:
		Act.IDLE:
			# EnHorse_MountedIdle: back reverses, aside turns on the spot,
			# ahead walks on after a short gather (waitTimer 8).
			speed = 0.0
			if mag > 10.0 and can_move:
				if back:
					_set_act(Act.REVERSE)
				elif cos(rel) <= 0.7071:
					_set_act(Act.TURN)
				else:
					_set_act(Act.WALK)
					_wait = 8.0
		Act.TURN:
			# EnHorse_MountedTurn: wheels round in place, 800 a frame at most.
			speed = 0.0
			if mag <= 10.0 or not can_move:
				_set_act(Act.IDLE)
			elif back:
				_set_act(Act.REVERSE)
			elif cos(rel) <= 0.7071:
				var a := clampf(rel / BINANG, -800.0, 800.0)
				yaw += a * BINANG * f
			else:
				_set_act(Act.WALK)
		Act.WALK:
			if _wait > 0.0:
				speed = 0.0
				_wait -= f
			else:
				_update_speed(f, mag, rel, can_move, 3.0)
				# At the end of a stride, no stick (or stick back) stands her.
				if (mag < 10.0 or back) and _act_t >= 6.0:
					speed = 0.0
				if speed == 0.0:
					_set_act(Act.IDLE)
				elif speed > 3.0:
					_set_act(Act.TROT)
		Act.TROT:
			_update_speed(f, mag, rel, can_move, 6.0)
			if speed < 3.0:
				_set_act(Act.WALK)
			elif speed >= 6.0:
				_set_act(Act.GALLOP)
		Act.GALLOP:
			_update_speed(f, mag, rel, can_move, 8.0)
			if back and can_move:
				# EnHorse_StartBraking: she digs in and skids to a halt.
				_set_act(Act.STOP)
				_boosting = false
				Sfx.play("horse_neigh", -8.0, 0.05, 1.1)
				if model:
					model.play(&"rear", 0.08, 1.5, true)
			elif speed < 6.0:
				_set_act(Act.TROT)
		Act.STOP:
			# EnHorse_Stopping: 0.6 a frame off, dead still from frame 29 of
			# the skid (played at x1.5).
			speed = maxf(speed - 0.6 * f, 0.0)
			if _act_t * 1.5 > 29.0:
				speed = 0.0
			if _act_t * 1.5 > 40.0:
				_set_act(Act.IDLE)
		Act.REVERSE:
			# EnHorse_Reverse: backs up at 2, the stick's sideways lean
			# swinging her round (1200 a frame at most); let go and she stops.
			if can_move and (mag < 10.0 or cos(rel) > -0.5):
				speed = 0.0
				_set_act(Act.IDLE)
			else:
				var r := rel if mag >= 10.0 else -PI
				speed = -2.0
				var turn := clampf(wrapf(PI - r, -PI, PI) / BINANG, -1200.0, 1200.0)
				yaw += turn * BINANG * f
	gait = _gait_of(act)
	if speed > 0.5:
		_check_obstacle()


## EnHorse_UpdateSpeed(brakeDecel 0.3, brakeAngle -0.5, minStickMag 10,
## decel 0.06, baseSpeed, turnSpeed 400).
func _update_speed(f: float, mag: float, rel: float, can_move: bool, base: float) -> void:
	if not can_move:
		if speed > 8.0:
			speed -= 0.06 * f
		return
	if cos(rel) <= -0.5 and mag > 0.0:
		speed = maxf(speed - 0.3 * f, 0.0)
		return
	if mag < 10.0:
		_boosting = false
		_boost_decel = false
		speed = maxf(speed - 0.06 * f, 0.0)
		return
	if _boosting:
		_boost_t += f
		var left := 16.0 - _boost_t
		speed = speed + (BOOST_SPEED - speed) / left * f if left > 1.0 else BOOST_SPEED
		if speed >= BOOST_SPEED - 0.01:
			_boosting = false
			_boost_decel = true
	elif _boost_decel:
		if speed > base:
			speed -= 0.06 * f
		else:
			speed = base
			_boost_decel = false
	else:
		speed += (1.0 if speed <= base / 54.0 * mag else -1.0) * 0.5 * f
		if speed > base:
			speed = maxf(speed - 0.06 * f, base)
	# The turn: cubic in the stick's angle, wider at speed.
	var a := rel / BINANG
	var traction := 2.2 - speed / BOOST_SPEED
	var turn := a * pow(a / 32236.0, 2.0) * traction
	var cap := turn_speed * traction
	yaw += clampf(turn, -cap, cap) * BINANG * f


func _set_act(a: Act) -> void:
	act = a
	_act_t = 0.0


static func _gait_of(a: Act) -> Gait:
	match a:
		Act.WALK, Act.TURN, Act.REVERSE:
			return Gait.WALK
		Act.TROT:
			return Gait.TROT
		Act.GALLOP:
			return Gait.GALLOP
	return Gait.STAND


## A gets off only while she stands still.
func can_dismount() -> bool:
	return mode == Mode.MOUNTED and act in [Act.IDLE, Act.TURN] and absf(speed) < 0.3


## EnHorse_CheckFenceJump, simplified: something low ahead with level ground
## beyond is jumped at a trot or faster; anything else stops her.
func _check_obstacle() -> void:
	var space := get_world_3d().direct_space_state
	var fwd := forward()
	var reach := 1.4 + to_mps(speed) * 0.25
	var from := global_position + Vector3.UP * 0.45 + fwd * 0.9
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * reach, 1)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if _water_ahead(fwd * (reach + 0.6)):
		_pull_up()
		return
	if hit.is_empty() or absf((hit.normal as Vector3).y) > 0.5:
		return
	# Just past the face: rails and fence boxes are thin.
	var probe: Vector3 = hit.position + fwd * 0.08
	var top := _down_ray(Vector3(probe.x, global_position.y + 3.0, probe.z), 4.0)
	if top.is_empty():
		return
	var height: float = top.position.y - global_position.y
	var beyond := global_position + fwd * (reach + 4.5)
	var land := _down_ray(beyond + Vector3.UP * 3.0, 6.0)
	var level := not land.is_empty() and absf(land.position.y - global_position.y) < 1.4
	if height > 19.0 * UNIT and height <= 72.0 * UNIT and level and speed >= 6.0:
		_start_jump(height)
	elif speed > 1.0:
		_pull_up()


func _blocked_ahead() -> bool:
	var fwd := forward()
	var from := global_position + Vector3.UP * 0.45 + fwd * 0.9
	var q := PhysicsRayQueryParameters3D.create(from, from + fwd * 1.2, 1)
	q.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty() or _water_ahead(fwd * 2.0)


## Deep water ahead (more than her knees): she won't go in.
func _water_ahead(offset: Vector3) -> bool:
	var p := global_position + offset
	var level := Surface.water_level(World.area_node, p) if is_instance_valid(World.area_node) else NAN
	if is_nan(level):
		return false
	var hit := _down_ray(p + Vector3.UP * 3.0, 9.0)
	if hit.is_empty():
		return false
	return level - float(hit.position.y) > 0.8


## A ray straight down `length` meters from `from`. A perfectly vertical ray
## can slip through the terrain's heightmap at a cell edge, so a miss is tried
## again a hair to the side.
func _down_ray(from: Vector3, length: float) -> Dictionary:
	var space := get_world_3d().direct_space_state
	for nudge in [Vector3.ZERO, Vector3(0.011, 0, 0.007), Vector3(-0.013, 0, 0.017)]:
		var q := PhysicsRayQueryParameters3D.create(from + nudge, from + nudge + Vector3.DOWN * length, 1)
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			return hit
	return {}


## Pulls up short and rears (EnHorse_StartBraking / EnHorse_StartRearing).
func _pull_up() -> void:
	if mode != Mode.MOUNTED:
		return
	speed = 0.0
	gait = Gait.STAND
	_boosting = false
	_boost_decel = false
	mode = Mode.REAR
	_set_act(Act.IDLE)
	_rear_t = 1.2
	model.play(&"rear", 0.06, 1.0, true)
	Sfx.play("horse_neigh", -2.0, 0.05)
	GameManager.rumble(0.7, 0.4)


func _start_jump(height: float) -> void:
	mode = Mode.JUMP
	_jump_t = 0.0
	_jump_y = global_position.y
	_jump_h = height + 0.7
	speed = 12.0 if speed < 13.8 else 13.0
	model.play(&"jump", 0.05, 1.0, true)
	Sfx.play("horse_jump", -3.0, 0.05)
	GameManager.rumble(0.5, 0.2)
	jumped.emit()


## The leap: up over the fence and down onto the far side.
func _jump(delta: float, _f: float) -> void:
	_jump_t += delta
	var k := clampf(_jump_t / 0.8, 0.0, 1.0)
	var want := _jump_y + sin(k * PI) * _jump_h
	velocity.y = (want - global_position.y) / maxf(delta, 0.001)
	if (k > 0.55 and is_on_floor()) or k >= 1.0:
		mode = Mode.MOUNTED if rider else Mode.FREE
		speed = 8.0 if rider else 0.0
		gait = Gait.GALLOP if rider else Gait.STAND
		_set_act(Act.GALLOP if rider else Act.IDLE)
		velocity.y = 0.0
		Sfx.play("horse_land", -3.0, 0.05)
		GameManager.rumble(0.8, 0.2)


## EnHorse_RegenBoost.
func _regen_carrots(f: float) -> void:
	if carrots >= CARROTS:
		return
	_regen -= f
	if _regen > 0.0:
		return
	if carrots == 0:
		carrots = CARROTS
	else:
		carrots += 1
		_regen = 11.0
	if rider:
		Sfx.play("carrot_recover", -10.0, 0.0)
	if carrots >= CARROTS:
		_first_regen = true


func _animate(delta: float) -> void:
	if model == null or mode in [Mode.JUMP, Mode.REAR] or (mode == Mode.MOUNTED and act == Act.STOP):
		return
	var anim := &"idle"
	var rate := 1.0
	match gait if mode == Mode.MOUNTED else (Gait.GALLOP if speed > 6.0 else (Gait.TROT if speed > 3.0 else (Gait.WALK if speed > 0.1 else Gait.STAND))):
		Gait.WALK:
			anim = &"walk"
			# Backing up plays the walk in reverse; turning on the spot steps it.
			rate = -0.75 if speed < 0.0 else maxf(speed / 3.0, 0.4) if mode != Mode.MOUNTED or act != Act.TURN else 1.0
		Gait.TROT:
			anim = &"trot"
			rate = speed / 6.0
		Gait.GALLOP:
			anim = &"gallop"
			rate = speed / 8.0
	model.play(anim, 0.15, rate)
	# Hoofbeats: two per gait cycle.
	if anim != &"idle":
		var length := model.anim.current_animation_length if model.anim.current_animation != "" else 1.0
		var before := _step_phase
		_step_phase = fmod(_step_phase + delta * absf(rate) / maxf(length, 0.1) * 2.0, 1.0)
		if _step_phase < before:
			var near := GameManager.player != null and GameManager.player.global_position.distance_to(global_position) < 30.0
			if near:
				Sfx.play("horse_step", -10.0 if anim == &"walk" else -6.0, 0.08)
