class_name TitleWalker
extends Node3D
## A character for the title screen's scenes (TitleFlyover, TitleAttract): a
## generated model that keeps to the ground and animates itself while the
## tree is paused. Moved by setting its x/z with place(); unless an action is
## playing (act), it picks idle / walk / run from how fast it is going, with
## the hero's stride rates from OoT's walk cycle (see PlayerController).

const HERO := "res://assets/models/sir_gigglebuns.tscn"
## OoT units per frame -> m/s (PlayerController._to_mps: rate 1.5, 20 Hz,
## 0.03 m per unit).
const OOT_MPS := 1.5 * 20.0 * 0.03

var model: CharacterModel = null
## Pick idle / walk / run from the motion (off while an act plays).
var auto := true
## The hero's walk-cycle rates; other creatures use `stride` (meters per
## loop of their walk or run).
var hero_stride := true
var stride := 2.0
var walk_anim := &"walk"
var run_anim := &"run"
## Above this speed (m/s) the run plays instead of the walk.
var run_speed := 3.3
## Turn to face the way it moves.
var turn_to_motion := true
## Ignored by place() (the hero is hopping, say): no ground snap.
var airborne := false
## Kept for TitleFlyover, which says when the walk ends.
var walking := true

var _last := Vector3.ZERO
var _speed := 0.0
var _floor_y := 0.0


## A walker of `model_path` (the hero by default) added under `parent`.
static func make(parent: Node, model_path := HERO) -> TitleWalker:
	var w := TitleWalker.new()
	w.name = "TitleWalker"
	w.process_mode = Node.PROCESS_MODE_ALWAYS
	var m: Node3D = load(model_path).instantiate()
	m.name = "Model"
	w.add_child(m)
	w.model = m as CharacterModel
	if w.model:
		w.model.process_mode = Node.PROCESS_MODE_ALWAYS
	if parent:
		parent.add_child(w)
	if w.model and model_path == HERO:
		w.model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
		w.model.set_sword_drawn(false)
	return w


## Height of the ground under `xz`, looking from `near_y + reach_up` down (so
## a roof or an arch overhead is not taken for it); `miss` (default `near_y`)
## if nothing is hit.
static func ground_y(node: Node3D, xz: Vector2, near_y: float, reach_up := 80.0, miss := NAN) -> float:
	if is_nan(miss):
		miss = near_y
	if node == null or not node.is_inside_tree():
		return miss
	var space := node.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(xz.x, near_y + reach_up, xz.y), Vector3(xz.x, near_y - 40.0, xz.y), 1)
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if hit else miss


## Moves to `xz` on the ground.
func place(xz: Vector2) -> void:
	var y := global_position.y
	if not airborne:
		_floor_y = ground_y(self, xz, _floor_y, 1.5)
		y = _floor_y
	global_position = Vector3(xz.x, y, xz.y)


## Snaps to the ground where it stands (after being put somewhere) and
## forgets its motion.
func settle() -> void:
	_floor_y = ground_y(self, Vector2(global_position.x, global_position.z), global_position.y + 2.0, 80.0)
	global_position.y = _floor_y
	_last = global_position
	_speed = 0.0
	if model and auto:
		model.play(&"idle", 0.0)


func xz() -> Vector2:
	return Vector2(global_position.x, global_position.z)


## Faces along `dir` (x/z).
func face(dir: Vector2) -> void:
	if dir.length() > 0.001:
		rotation.y = atan2(-dir.x, -dir.y)


## Faces the point `xz`.
func face_point(p: Vector2) -> void:
	face(p - xz())


## Plays an action (the walk/idle picking stops until free()).
func act(anim: StringName, speed := 1.0, blend := 0.08) -> void:
	auto = false
	if model:
		model.play(anim, blend, speed, true)


## Back to idle / walk / run by motion.
func release() -> void:
	auto = true


## Length of `anim` in seconds at `speed`.
func anim_length(anim: StringName, speed := 1.0) -> float:
	if model and model.anim.has_animation(anim):
		return model.anim.get_animation(anim).length / maxf(absf(speed), 0.01)
	return 0.5


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var moved := global_position - _last
	moved.y = 0.0
	_last = global_position
	# A jump between shots is not a dash.
	var v := moved.length() / delta if moved.length() < 2.0 else 0.0
	_speed = lerpf(_speed, v, minf(delta * 12.0, 1.0))
	if turn_to_motion and v > 0.3:
		var yaw := atan2(-moved.x, -moved.z)
		rotation.y = lerp_angle(rotation.y, yaw, minf(delta * 10.0, 1.0))
	if not auto or model == null:
		return
	if _speed < 0.15:
		model.play(&"idle", 0.15)
	elif hero_stride:
		# PlayerController._animate_ground: a 29-frame stride advanced by
		# 0.55 + 0.27 * speed frames per game frame.
		var s := _speed / OOT_MPS
		var cycles := (0.55 + 0.27 * s) * 1.5 * 20.0 / 29.0
		if _speed >= run_speed:
			model.play(run_anim, 0.1, cycles * 0.56)
		else:
			model.play(walk_anim, 0.1, cycles * 0.84)
	elif _speed >= run_speed:
		model.play(run_anim, 0.1, _speed / stride)
	else:
		model.play(walk_anim, 0.1, _speed / stride)
