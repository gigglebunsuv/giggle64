class_name CupGame
extends Node3D
## Tansy's cup game (the shell game): three copper cups on her striped table,
## a rupee under one. She lifts the cup to show it, puts it down and shuffles
## the cups round each other; the hero picks a cup. Each round costs FEE; a
## right guess pays PRIZE back, and every win in a row shuffles faster and
## longer. Win STREAK_PRIZE rounds in a row for her Giant Wallet (once; after
## that a streak pays a big rupee bonus).
##
## Tansy's lines start it (`play` event); the table is this node, the cups and
## the rupee its children. The game runs while the hero stands talking.

signal round_done(won: bool)

const FEE := 10
const PRIZE := 20
const STREAK_PRIZE := 5
const CUP_X := [-0.32, 0.0, 0.32]
const TOP := 0.812

var playing := false
var streak := 0
## Which cup (0-2, by its node) the rupee is under.
var under := 1
## The cups as they stand left to right (indices into _cups).
var order := [0, 1, 2]
var _cups: Array[MeshInstance3D] = []
var _rupee: MeshInstance3D
var _rng := RandomNumberGenerator.new()
## Tests set the hero's pick here instead of asking (-1 = ask; 0-2 a cup;
## 3 always the right one, 4 always a wrong one).
var forced_pick := -1
## Only there once this flag is set (the palace's table after the fall).
@export var show_flag := ""
## Gone once this flag is set (the Castle Town table, after the fall).
@export var hide_flag := ""


func _ready() -> void:
	if (show_flag != "" and not Progress.flag(show_flag)) or (hide_flag != "" and Progress.flag(hide_flag)):
		queue_free()
		return
	_rng.randomize()
	add_to_group("cup_games")
	var table := MeshInstance3D.new()
	table.name = "Table"
	table.mesh = load("res://assets/models/cup_table_mesh.tres")
	add_child(table)
	var body := StaticBody3D.new()
	body.name = "Body"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 0.8, 0.7)
	cs.shape = box
	cs.position = Vector3(0, 0.4, 0)
	cs.set_meta("no_climb", true)
	body.add_child(cs)
	add_child(body)
	_rupee = MeshInstance3D.new()
	_rupee.name = "Rupee"
	_rupee.mesh = load("res://assets/models/rupee_green_mesh.tres")
	_rupee.scale = Vector3.ONE * 0.6
	add_child(_rupee)
	for i in 3:
		var c := MeshInstance3D.new()
		c.name = "Cup%d" % i
		c.mesh = load("res://assets/models/shell_cup_mesh.tres")
		c.position = Vector3(CUP_X[i], TOP, 0)
		add_child(c)
		_cups.append(c)
	_rupee.position = Vector3(CUP_X[1], TOP + 0.05, 0)


## The cup standing in slot `slot` (0 left, 1 middle, 2 right).
func cup_at(slot: int) -> MeshInstance3D:
	return _cups[order[slot]]


## The slot the rupee's cup stands in now.
func rupee_slot() -> int:
	return order.find(under)


## One round: show, shuffle, pick, reveal. Returns true if the pick was right.
func play_round(player: PlayerController) -> bool:
	playing = true
	under = _rng.randi_range(0, 2)
	_rupee.position = Vector3(CUP_X[rupee_slot()], TOP + 0.05, 0)
	_rupee.visible = true
	await _lift(rupee_slot(), true)
	await get_tree().create_timer(0.6).timeout
	await _lift(rupee_slot(), false)
	_rupee.visible = false
	var swaps := 3 + streak * 2
	var time := maxf(0.42 - streak * 0.06, 0.16)
	for i in swaps:
		var a := _rng.randi_range(0, 2)
		var b := (a + _rng.randi_range(1, 2)) % 3
		await _swap(a, b, time)
	var pick := forced_pick
	if pick == 3:
		pick = rupee_slot()
	elif pick == 4:
		pick = (rupee_slot() + 1) % 3
	if pick < 0:
		Dialogue.start([{"text": "Which cup is it under?", "choices": [["Left", []], ["Middle", []], ["Right", []]]}], null)
		await Dialogue.finished
		pick = ["Left", "Middle", "Right"].find(Dialogue.last_choice)
	pick = clampi(pick, 0, 2)
	var won := pick == rupee_slot()
	_rupee.position = Vector3(CUP_X[rupee_slot()], TOP + 0.05, 0)
	_rupee.visible = true
	await _lift(pick, true)
	if not won:
		await get_tree().create_timer(0.4).timeout
		await _lift(rupee_slot(), true)
		await _lift(rupee_slot(), false)
	await get_tree().create_timer(0.4).timeout
	await _lift(pick, false)
	_rupee.visible = false
	streak = streak + 1 if won else 0
	Sfx.play("rupee_big" if won else "error", -2.0)
	playing = false
	round_done.emit(won)
	return won


func _lift(slot: int, up: bool) -> void:
	var c := cup_at(slot)
	Sfx.play("cup_lift", -4.0, 0.08)
	var tw := create_tween()
	tw.tween_property(c, "position:y", TOP + (0.3 if up else 0.0), 0.18)
	await tw.finished


## Two cups trade places along little arcs (one passes in front, one behind).
func _swap(a: int, b: int, time: float) -> void:
	var ca := cup_at(a)
	var cb := cup_at(b)
	var xa: float = CUP_X[a]
	var xb: float = CUP_X[b]
	Sfx.play("cup_slide", -6.0, 0.1)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(t: float) -> void:
		ca.position = Vector3(lerpf(xa, xb, t), TOP, -sin(t * PI) * 0.12), 0.0, 1.0, time)
	tw.tween_method(func(t: float) -> void:
		cb.position = Vector3(lerpf(xb, xa, t), TOP, sin(t * PI) * 0.12), 0.0, 1.0, time)
	await tw.finished
	var tmp: int = order[a]
	order[a] = order[b]
	order[b] = tmp
