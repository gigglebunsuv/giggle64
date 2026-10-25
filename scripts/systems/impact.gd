class_name Impact
extends Node
## Hit-stop (Beta 1.8.0): when the blade bites, the whole world holds still
## for a few frames (the impact frames: the swing stops dead in the foe), then
## runs on in a brief slow-down that eases back to full speed, and a heavy
## blow flashes the screen white for a frame. Zelda games freeze the action on
## a solid hit (Wind Waker and Twilight Princess most of all, Breath of the
## Wild on a flurry's last cut); Dark Souls holds the frame and slows the moment
## a parry lands.
##
## Engine.time_scale carries it, timed in unscaled frame time (each frame's
## delta with the slow-down taken back out, so a recording paced by Movie
## Maker holds it as long as play does); whatever scale was in force before
## (the debug menu's game speed) is put back. Headless runs (the
## tests) leave time alone, so frame counts in them stay what they were.

## [freeze seconds, slow-down seconds, slowest scale, white flash 0-1].
const LIGHT := [0.045, 0.12, 0.5, 0.0]
const HEAVY := [0.075, 0.22, 0.35, 0.3]
const PARRY := [0.12, 0.55, 0.22, 0.5]
const RIPOSTE := [0.1, 0.6, 0.25, 0.45]
## How slow "still" is (never quite zero: nothing divides by a zero delta).
const STILL := 0.02

static var _node: Impact
## The screen flash, read by the HUD (0-1, fading in real time).
static var flash := 0.0
static var enabled := true

var _active := false
var _base := 1.0
var _t := 0.0
var _freeze := 0.0
var _slow := 0.0
var _scale := 1.0


static func hit(kind: Array) -> void:
	if not enabled or DisplayServer.get_name() == "headless":
		return
	if _node == null or not is_instance_valid(_node):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		_node = Impact.new()
		_node.name = "Impact"
		_node.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(_node)
	_node._start(kind)


## True while time is held or slowed.
static func active() -> bool:
	return _node != null and is_instance_valid(_node) and _node._active


func _start(kind: Array) -> void:
	if not _active:
		# A cutscene being skipped runs time fast: leave it be.
		if Engine.time_scale > 1.5:
			return
		_base = Engine.time_scale
	elif float(kind[0]) + float(kind[1]) < _freeze + _slow - _t:
		# A lighter hit never cuts a heavier one short.
		return
	_active = true
	_t = 0.0
	_freeze = kind[0]
	_slow = kind[1]
	_scale = kind[2]
	flash = maxf(flash, float(kind[3]))
	_apply()


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001)
	if flash > 0.0:
		flash = maxf(flash - real * 6.0, 0.0)
	if _active:
		_t += real
		_apply()


func _apply() -> void:
	var t := _t
	if t < _freeze:
		Engine.time_scale = _base * STILL
	elif t < _freeze + _slow:
		var k := (t - _freeze) / _slow
		Engine.time_scale = _base * lerpf(_scale, 1.0, k * k)
	else:
		Engine.time_scale = _base
		_active = false


func _exit_tree() -> void:
	if _active:
		Engine.time_scale = _base
		_active = false
