class_name FenceCourse
extends Node3D
## Clover's jumping course in the corral on the farm (a little like Lon Lon
## Ranch's obstacle course): ride Biscuit through the start arch, jump every
## fence round the track, and come back through the arch before time runs out.
##
## Clover arms it (`arm()`); the clock starts when the hero rides into the
## arch and stops when he rides into it again, having left it, with
## `fences_needed` jumps behind him. The first clear inside `own_time` gives him Biscuit (her Sugar
## Cube); inside `wallet_time`, her Big Wallet.

signal finished(seconds: float, cleared: bool)

enum Phase { IDLE, ARMED, RUNNING }

@export var gate_size := Vector3(6.0, 4.0, 2.0)
@export var fences_needed := 3
@export var own_time := 50.0
@export var wallet_time := 26.0

## The course in use (the HUD shows its clock), or null.
static var current: FenceCourse = null

var phase := Phase.IDLE
var time := 0.0
var jumps := 0
var best := 0.0
var _gate: Area3D
var _horse: Horse
var _left_gate := false


func _ready() -> void:
	add_to_group("fence_courses")
	_gate = Area3D.new()
	_gate.name = "Gate"
	_gate.collision_layer = 0
	_gate.collision_mask = 2
	_gate.monitorable = false
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = gate_size
	cs.shape = box
	cs.position = Vector3(0, gate_size.y * 0.5, 0)
	_gate.add_child(cs)
	add_child(_gate)
	_gate.body_entered.connect(_on_gate_entered)
	_gate.body_exited.connect(_on_gate_exited)


func _exit_tree() -> void:
	if current == self:
		current = null


## Clover starts it: the clock waits for the hero to ride through the gate.
func arm() -> void:
	phase = Phase.ARMED
	time = 0.0
	jumps = 0
	_left_gate = false
	current = self


func cancel() -> void:
	phase = Phase.IDLE
	if is_instance_valid(_horse) and _horse.jumped.is_connected(_on_jump):
		_horse.jumped.disconnect(_on_jump)
	if current == self:
		current = null


func _on_gate_exited(body: Node3D) -> void:
	if phase == Phase.RUNNING and body is PlayerController:
		_left_gate = true


func _on_gate_entered(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	if phase == Phase.ARMED and (body as PlayerController).is_riding():
		phase = Phase.RUNNING
		time = 0.0
		jumps = 0
		_left_gate = false
		_horse = (body as PlayerController).horse
		if not _horse.jumped.is_connected(_on_jump):
			_horse.jumped.connect(_on_jump)
		Sfx.play("menu_select", -4.0)
		return
	if phase != Phase.RUNNING or not _left_gate:
		return
	if jumps < fences_needed:
		return
	var t := time
	var cleared := t <= own_time
	cancel()
	if cleared and (best == 0.0 or t < best):
		best = t
	finished.emit(t, cleared)
	_announce(t, cleared)


## Clover calls out the time and hands over any prize. He gets down to hear it.
func _announce(seconds: float, cleared: bool) -> void:
	var player := GameManager.player
	if not is_instance_valid(player):
		return
	var text: Array = []
	var prize := ""
	if not cleared:
		text = ["*Clover*: Aw, shucks! %.1f seconds. Come talk to me and give it another go!" % seconds]
	elif not Progress.flag("horse_owned"):
		Progress.set_flag("horse_owned")
		text = ["*Clover*: %.1f seconds! You two are a natural team!" % seconds,
			"*Clover*: You know what? Biscuit's yours. Here, take this: she'll come running for it anywhere out on the fields."]
		prize = "sugar_cube"
	elif seconds <= wallet_time and not Progress.flag("clover_wallet"):
		Progress.set_flag("clover_wallet")
		text = ["*Clover*: %.1f seconds?! That's a farm record! A deal's a deal. Here!" % seconds]
		prize = "big_wallet"
	else:
		text = ["*Clover*: %.1f seconds. Not bad! Want to go again?" % seconds]
	Sfx.play("puzzle_solved" if cleared else "error", -4.0, 0.0)
	player.begin_talk(null)
	Dialogue.start(text, null)
	await Dialogue.finished
	if is_instance_valid(player):
		player.end_talk()
		if prize != "":
			await GetItem.present(player, prize)


func _on_jump() -> void:
	if phase == Phase.RUNNING:
		jumps += 1


func _physics_process(delta: float) -> void:
	if phase != Phase.RUNNING:
		return
	time += delta
	var p := GameManager.player
	# Getting off, or taking far too long, ends the run.
	if not is_instance_valid(p) or not p.is_riding() or time > own_time + 30.0:
		var t := time
		cancel()
		finished.emit(t, false)
		_announce(t, false)
