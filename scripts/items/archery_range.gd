class_name ArcheryRange
extends Node3D
## Clover's target range in the Southern Fields (after OoT's shooting
## galleries): ROUND_TIME seconds to put an arrow in the gold center of every
## one of its targets (ArcheryTargets with the meta "range" = `range_id`).
## Clover refills the quiver to start. A clean round wins the Biggest Quiver
## the first time, a purse of rupees after that.
##
## Clover's lines start it (`start`); the HUD shows the clock while it runs.

signal finished(won: bool)

const ROUND_TIME := 45.0
const FEE := 20

static var current: ArcheryRange = null

## Its targets carry this as their "range" meta.
@export var range_id := "clover"

var running := false
var time_left := 0.0
var _targets: Array[ArcheryTarget] = []
var _hit := {}


func _ready() -> void:
	add_to_group("archery_ranges")
	_find_targets.call_deferred()


func _exit_tree() -> void:
	if current == self:
		current = null


func _find_targets() -> void:
	_targets.clear()
	for t in get_tree().get_nodes_in_group("archery_targets"):
		var at := t as ArcheryTarget
		if at and String(at.get_meta("range", "")) == range_id:
			_targets.append(at)
			if not at.hit.is_connected(_on_hit.bind(at)):
				at.hit.connect(_on_hit.bind(at))


func target_count() -> int:
	return _targets.size()


func hits() -> int:
	return _hit.size()


func start() -> void:
	if _targets.is_empty():
		_find_targets()
	_hit.clear()
	time_left = ROUND_TIME
	running = true
	current = self
	Progress.set_flag("range:played")
	Progress.add_arrows(Progress.arrows_max)
	Sfx.play("target_bell", -2.0, 0.0, 0.8)


func _on_hit(bullseye: bool, target: ArcheryTarget) -> void:
	if not running or not bullseye:
		return
	_hit[target] = true
	if _hit.size() >= _targets.size():
		_end(true)


func _process(delta: float) -> void:
	if not running or GameManager.state != GameManager.GameState.PLAYING or Dialogue.active:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_end(false)


func _end(won: bool) -> void:
	running = false
	finished.emit(won)
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	if won:
		Sfx.play("puzzle_solved", -2.0, 0.0)
		if Progress.arrows_max < Progress.BIGGEST_QUIVER:
			Dialogue.start([{"text": "Yee-haw! Every gold center! I've never seen shooting like it, partner. You've earned this!"}])
			await Dialogue.finished
			if is_instance_valid(p):
				await GetItem.present(p, "biggest_quiver")
		else:
			Progress.add_rupees(30)
			Sfx.play("rupee_big", -2.0)
			Dialogue.start(["Every gold center again! Here's *30 Coins* for the trouble. You'll put me out of business!"])
			await Dialogue.finished
	else:
		Dialogue.start(["Time's up! You hit *%d* of the %d. Come try again, partner!" % [_hit.size(), _targets.size()]])
		await Dialogue.finished
