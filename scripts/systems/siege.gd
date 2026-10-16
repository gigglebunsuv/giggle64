class_name Siege
extends Node3D
## The Siege of Haven (Chapter IV's great set piece): the night after
## Eastgate's beacon dies, Firebuns' horde comes for Haven Village, the last
## refuge. The hero holds the north palisade through four waves, with
## Aladriel holding the east of the wall and Idrith the west (Ally):
##   1 LADDERS     goblins throw scaling ladders up (SiegeLadder): cut their
##                 ropes from inside before too many come over
##   2 ENGINES     siege towers roll on the wall (SiegeTower), war boars ram
##                 the gate (BoarRider -> SiegeGate), archers on the slope:
##                 man the gatehouse ballista (Ballista)
##   3 THE STORM   ladders, a tower and boars all at once
##   4 THE MAGE    an Order battle-mage blinks in over the wall with goblins
##                 at its back; beaten low it flees west, to Westmarch
## Each side of the wall has a HOLD: standing ladders, a docked tower, and
## goblins loose inside on that side wear it down; empty, that side breaks.
## A broken side, a broken gate, or the hero falling loses the wave: the
## scene fades, the wall is set right, and the wave begins again. Between
## waves the gate's loose planks can be mended with the Iron Mallet.
##
## It runs (at night) while "ch4:eastgate_fallen" is set and
## "ch4:siege_won" is not; Story.siege_begins / siege_won are its scenes.

signal wave_started(n: int)
signal wave_won(n: int)
signal wave_lost(n: int, why: String)

const READY := "ch4:eastgate_fallen"
const WON := "ch4:siege_won"
const WAVES := 4
const HOLD_MAX := 100.0
## Per second, from each standing ladder / docked tower / goblin inside.
const DRAIN_LADDER := 2.4
const DRAIN_TOWER := 5.0
const DRAIN_GOBLIN := 1.6
const REGEN := 1.5
const BREAK_TIME := 9.0
## The palisade line (z), and the ladders' feet along it.
const WALL_Z := -38.0
const LADDER_X := [-27.0, -15.0, 15.0, 27.0]
const TOWER_X := [-20.0, 20.0]
const FIELD_Z := -82.0

## The wave's script: [time, what, which].
const PLANS := {
	1: [[1.0, "ladder", 0], [5.0, "ladder", 3], [12.0, "ladder", 1], [18.0, "ladder", 2]],
	2: [[0.5, "archer", 0], [0.5, "archer", 1], [0.5, "archer", 2], [1.0, "tower", 0], [4.0, "boar", 0], [9.0, "tower", 1], [16.0, "boar", 1]],
	3: [[0.5, "ladder", 0], [2.0, "ladder", 2], [4.0, "tower", 1], [6.0, "boar", 0], [9.0, "ladder", 3], [12.0, "archer", 1], [15.0, "boar", 1]],
	4: [[1.5, "mage", 0], [2.0, "goblin", 0], [2.0, "goblin", 1], [8.0, "ladder", 1], [8.0, "ladder", 2]],
}
const WAVE_NAMES := ["", "LADDERS", "SIEGE ENGINES", "THE STORM", "THE BATTLE-MAGE"]

var running := false
var wave := 0
var hold := {"w": HOLD_MAX, "e": HOLD_MAX}
var _t := 0.0
var _plan: Array = []
var _break := -1.0
var _losing := false
var _threats: Array[Node] = []
var _gate: SiegeGate
var _hud: CanvasLayer
var _gate_at_start := SiegeGate.MAX_HP


static func active() -> bool:
	return Progress.flag(READY) and not Progress.flag(WON)


func _ready() -> void:
	add_to_group("sieges")
	if active() and GameManager.state == GameManager.GameState.PLAYING:
		_begin.call_deferred()


func gate() -> SiegeGate:
	if not is_instance_valid(_gate) and is_inside_tree():
		var gs := get_tree().get_nodes_in_group("siege_gates")
		_gate = gs[0] as SiegeGate if not gs.is_empty() else null
	return _gate


func allies() -> Array:
	return get_tree().get_nodes_in_group("allies") if is_inside_tree() else []


func _begin() -> void:
	if running or not is_inside_tree():
		return
	running = true
	DayNight.set_hour(22.0)
	DayNight.frozen = true
	if gate():
		gate().set_shut(true)
		gate().reset_hp()
	var p := GameManager.player
	if p and not p.respawned.is_connected(_on_hero_fell):
		p.respawned.connect(_on_hero_fell)
	_make_hud()
	World.play_track("siege_of_haven")
	if Story.has_method("siege_begins"):
		await Story.siege_begins(self)
	for a in allies():
		a.set("active", true)
	start_wave(1)


func start_wave(n: int) -> void:
	wave = n
	_t = 0.0
	_break = -1.0
	_losing = false
	hold = {"w": HOLD_MAX, "e": HOLD_MAX}
	_plan = (PLANS[n] as Array).duplicate(true)
	_gate_at_start = gate().hp if gate() else SiegeGate.MAX_HP
	Sfx.play("war_horn", -2.0, 0.0)
	wave_started.emit(n)


func side_of(p: Vector3) -> String:
	return "w" if p.x < 0.0 else "e"


func _physics_process(delta: float) -> void:
	if not running or Cutscene.active or _losing:
		return
	if _break >= 0.0:
		_break += delta
		if _break >= BREAK_TIME:
			start_wave(wave + 1)
		return
	_t += delta
	while not _plan.is_empty() and float(_plan[0][0]) <= _t:
		var step: Array = _plan.pop_front()
		_spawn(String(step[1]), int(step[2]))
	_threats = _threats.filter(func(n: Node) -> bool: return is_instance_valid(n) and _alive(n))
	_drain(delta)
	for s: String in hold:
		if hold[s] <= 0.0:
			lose("The %s wall is breaking!" % ("west" if s == "w" else "east"))
			return
	if gate() and gate().hp <= 0:
		lose("The gate has given way!")
		return
	if _plan.is_empty() and _threats.is_empty() and _inside_goblins().is_empty():
		_wave_done()


func _alive(n: Node) -> bool:
	if n is SiegeLadder:
		return (n as SiegeLadder).standing
	if n is SiegeTower:
		return not (n as SiegeTower).is_broken()
	if n is Enemy:
		return not (n as Enemy).is_dead() and n.is_in_group("enemies")
	return false


func _inside_goblins() -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e: Node) -> bool:
		return e is Enemy and not (e as Enemy).is_dead() and (e as Node3D).global_position.z > WALL_Z + 0.4)


func _drain(delta: float) -> void:
	var load_ := {"w": 0.0, "e": 0.0}
	for n in _threats:
		var s := side_of((n as Node3D).global_position)
		if n is SiegeLadder:
			load_[s] += DRAIN_LADDER
		elif n is SiegeTower and (n as SiegeTower).at_wall:
			load_[s] += DRAIN_TOWER
	for e in _inside_goblins():
		load_[side_of((e as Node3D).global_position)] += DRAIN_GOBLIN
	for s: String in hold:
		if load_[s] > 0.0:
			hold[s] = maxf(hold[s] - load_[s] * delta, 0.0)
		else:
			hold[s] = minf(hold[s] + REGEN * delta, HOLD_MAX)


func _spawn(what: String, which: int) -> void:
	var parent := get_parent()
	match what:
		"ladder":
			var l := SiegeLadder.new()
			l.side = "w" if float(LADDER_X[which]) < 0.0 else "e"
			parent.add_child(l)
			l.global_position = _ground(Vector3(float(LADDER_X[which]), 0, WALL_Z - SiegeLadder.WALL_T * 0.5 - 1.6))
			_threats.append(l)
		"tower":
			var t := SiegeTower.new()
			t.side = "w" if float(TOWER_X[which]) < 0.0 else "e"
			parent.add_child(t)
			t.global_position = _ground(Vector3(float(TOWER_X[which]), 0, FIELD_Z))
			t.dock = _ground(Vector3(float(TOWER_X[which]), 0, WALL_Z - 2.4))
			_threats.append(t)
		"boar":
			var b := _enemy("boar_rider", Vector3(-6.0 + which * 12.0, 0, FIELD_Z + 2.0))
			if b:
				b.set("gate", gate())
				_threats.append(b)
		"archer":
			var a := _enemy("goblin_archer", Vector3(-24.0 + which * 24.0, 0, -60.0 + (which % 2) * 4.0))
			if a:
				a.set("notice_range", 40.0)
				_threats.append(a)
		"goblin":
			var g := _enemy("basic_enemy", Vector3(-6.0 + which * 12.0, 0, -14.0))
			if g:
				g.set("tint", Color(0.8, 0.85, 1.3))
				_threats.append(g)
		"mage":
			var m := _enemy("battle_mage", Vector3(0, 0, -16.0))
			if m:
				m.set("flee_at", 6)
				m.set("roam", 9.0)
				m.connect("fled", _on_mage_fled)
				_threats.append(m)


func _enemy(kind: String, at: Vector3) -> Enemy:
	var path := "res://scenes/enemies/%s.tscn" % kind
	if not ResourceLoader.exists(path):
		return null
	var e := (load(path) as PackedScene).instantiate() as Enemy
	e.drop_table = 1
	get_parent().add_child(e)
	e.global_position = _ground(at)
	e.facing_yaw = 0.0 if at.z < WALL_Z else PI
	e.rotation.y = e.facing_yaw
	return e


func _ground(at: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, 40.0, at.z), Vector3(at.x, -20.0, at.z), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else at


func _on_mage_fled() -> void:
	if running and wave == 4:
		_wave_done()


func _on_hero_fell() -> void:
	if running and not _losing:
		lose("You have fallen!")


func _wave_done() -> void:
	if not running:
		return
	Sfx.play("puzzle_solved", -2.0, 0.0)
	wave_won.emit(wave)
	_clear_field()
	if wave >= WAVES:
		_win()
		return
	_break = 0.0
	if Story.has_method("siege_break"):
		Story.siege_break(wave)


## The wave is lost: to black, the wall set right, the wave again.
func lose(why: String) -> void:
	if _losing or not running:
		return
	_losing = true
	wave_lost.emit(wave, why)
	Sfx.play("war_horn", 0.0, 0.0, 0.8)
	await World.fade_to(1.0, 0.8)
	_clear_field()
	if gate():
		gate().reset_hp(maxi(_gate_at_start, SiegeGate.MAX_HP / 2))
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.health = p.health.max_health
		p.health.health_changed.emit(p.health.health, p.health.max_health)
		var spot := _ground(Vector3(0, 0, -30.0))
		p.global_position = spot + Vector3.UP * 0.2
		p.face_direction(Vector3(0, 0, -1))
		if p.camera_rig:
			p.camera_rig.snap_behind_target()
	for a in allies():
		a.call("go_home")
		a.set("active", true)
	await World.fade_to(0.0, 0.8)
	Dialogue.start([{"text": "%s Hold the line... and try again!" % why, "instant": true}], null)
	await Dialogue.finished
	start_wave(wave)


func _clear_field() -> void:
	for n in _threats:
		if is_instance_valid(n):
			n.queue_free()
	_threats.clear()
	for e in _inside_goblins():
		e.queue_free()
	for l in get_tree().get_nodes_in_group("siege_ladders"):
		l.queue_free()


func _win() -> void:
	running = false
	for a in allies():
		a.set("active", false)
	if is_instance_valid(_hud):
		_hud.queue_free()
	for b in get_tree().get_nodes_in_group("ballistas"):
		(b as Ballista).leave()
	Progress.set_flag(WON)
	if gate():
		gate().set_shut(false)
	DayNight.frozen = false
	if Story.has_method("siege_won"):
		await Story.siege_won(self)
	else:
		DayNight.set_hour(6.0)


## Skips straight to `n` (tests and the debug menu).
func debug_jump(n: int) -> void:
	_clear_field()
	if not running:
		running = true
		if gate():
			gate().set_shut(true)
		_make_hud()
	start_wave(n)


func _make_hud() -> void:
	if is_instance_valid(_hud):
		return
	_hud = CanvasLayer.new()
	_hud.layer = 1
	var bar := SiegeHud.new()
	bar.siege = self
	_hud.add_child(bar)
	add_child(_hud)


## The siege's meters across the top: the west and east holds, the gate, the wave.
class SiegeHud extends Control:
	var siege: Siege

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _bar(at: Vector2, label: String, k: float, col: Color) -> void:
		PixelFont.draw_centered(self, at.x + 24, at.y - 9, label, Color(1, 1, 1, 0.95))
		draw_rect(Rect2(at, Vector2(48, 5)), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(46.0 * clampf(k, 0.0, 1.0), 3)), col)

	func _draw() -> void:
		if siege == null or not siege.running or GameManager.state != GameManager.GameState.PLAYING:
			return
		var r := GameManager.screen_rect()
		var cx := r.get_center().x
		var y := r.position.y + 54.0
		_bar(Vector2(cx - 100, y), "WEST", siege.hold.w / HOLD_MAX, Color(0.9, 0.75, 0.3))
		var g := siege.gate()
		_bar(Vector2(cx - 24, y), "GATE", float(g.hp) / SiegeGate.MAX_HP if g else 0.0, Color(0.85, 0.55, 0.3))
		_bar(Vector2(cx + 52, y), "EAST", siege.hold.e / HOLD_MAX, Color(0.9, 0.75, 0.3))
		var title := "WAVE %d: %s" % [siege.wave, WAVE_NAMES[clampi(siege.wave, 0, WAVES)]] if siege._break < 0.0 else "THE HORDE REGROUPS..."
		PixelFont.draw_centered(self, cx, y + 10, title, Color(1.0, 0.85, 0.5, 0.95))
