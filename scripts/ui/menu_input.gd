class_name MenuInput
extends RefCounted
## The cursor input every menu shares (pause screen, file select, waystones,
## text box choices, the debug menu). The d-pad and the keys step at once; the
## stick only counts once it is pushed well over (OoT's menus want about half
## a tilt), only along its stronger axis, and with a little hysteresis so a
## stick resting near the threshold does not flicker. Held, it repeats: the
## first step at once, a pause, then a steady beat.

## Stick tilt (after the action dead zone) that starts a step, and the tilt it
## must fall under before it counts as let go.
const ENGAGE := 0.6
const RELEASE := 0.4
## How much stronger one axis must be than the other to win a diagonal.
const AXIS_BIAS := 1.3

var first_delay := 0.3
var repeat_delay := 0.12
var _dir := Vector2i.ZERO
var _time := 0.0


func _init(first := 0.3, repeat := 0.12) -> void:
	first_delay = first
	repeat_delay = repeat


## The strongest of the move and ui directions (x right, y down).
static func raw() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var u := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return v if v.length() >= u.length() else u


## The direction held now, one axis only (no repeat).
func held() -> Vector2i:
	var v := raw()
	if v.length() < (RELEASE if _dir != Vector2i.ZERO else ENGAGE):
		return Vector2i.ZERO
	var ax := absf(v.x)
	var ay := absf(v.y)
	if ax > ay * AXIS_BIAS:
		return Vector2i(int(signf(v.x)), 0)
	if ay > ax * AXIS_BIAS:
		return Vector2i(0, int(signf(v.y)))
	# A diagonal: keep going the way it was already going.
	if _dir.x != 0 and signf(v.x) == float(_dir.x):
		return _dir
	if _dir.y != 0 and signf(v.y) == float(_dir.y):
		return _dir
	return Vector2i(int(signf(v.x)), 0) if ax >= ay else Vector2i(0, int(signf(v.y)))


## One step when a direction is first held, then one every `repeat_delay`.
func step(delta: float) -> Vector2i:
	var d := held()
	if d == Vector2i.ZERO:
		_dir = d
		return d
	if d != _dir:
		_dir = d
		_time = first_delay
		return d
	_time -= delta
	if _time <= 0.0:
		_time = repeat_delay
		return d
	return Vector2i.ZERO


## A fresh press only (text box choices): true the frame a direction starts.
func pressed() -> Vector2i:
	var d := held()
	var fresh := d != _dir
	_dir = d
	return d if fresh else Vector2i.ZERO
