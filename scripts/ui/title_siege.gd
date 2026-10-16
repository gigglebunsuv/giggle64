class_name TitleSiege
extends TitleScene
## A title scene (see TitleScene): Haven Village at night in the war
## (Chapter IV), the refuge's palisade lit by braziers. Out on the slope below
## the wall the horde's torches gather; on the gatehouse walk Captain Rowena
## and a soldier of the Guard keep watch; far on the horizon the fortress
## beacons burn, and one of them goes out. Aladriel and Idrith stand back to
## back on the wall. Their lines play by themselves.

const AREA := "village_refuge"
const AMBIENCE := "res://assets/audio/amb_war.wav"
const ROWENA := "res://assets/models/rowena.tscn"
const SOLDIER := "res://assets/models/haven_soldier.tscn"
const ALADRIEL := "res://assets/models/aladriel.tscn"
const IDRITH := "res://assets/models/idrith.tscn"
const FLAME := "res://assets/models/flame_mesh.tres"
const FLICKER := "res://scripts/systems/torch_flicker.gd"
const WALK := Vector2(1.0, -35.2)
const WALL_Z := -40.0

const WAR_NIGHT := {
	"sky": [
		[-25.0, Color(0.03, 0.02, 0.04)], [0.0, Color(0.3, 0.12, 0.08)], [8.0, Color(0.14, 0.07, 0.1)],
		[30.0, Color(0.05, 0.04, 0.1)], [90.0, Color(0.02, 0.02, 0.06)],
	],
	"hills": Color(0.09, 0.07, 0.1),
	"fog": Color(0.1, 0.06, 0.08), "fog_begin": 20.0, "fog_end": 120.0,
	"ambient": Color(0.26, 0.2, 0.3), "ambient_energy": 0.5,
	"sun": Color(1.0, 0.55, 0.35), "sun_energy": 0.35, "sun_rot": Vector3(-14.0, 10.0, 0.0),
	"fill": Color(0.16, 0.14, 0.3), "fill_energy": 0.3,
}

var _row: TitleWalker = null
var _sol: TitleWalker = null
var _ala: TitleWalker = null
var _idr: TitleWalker = null
var _beacons: Array[Node3D] = []


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


func _torch_at(p: Vector3, size := 1.0) -> Node3D:
	var f := Node3D.new()
	f.set_script(load(FLICKER))
	World.area_node.add_child(f)
	f.global_position = p
	var mi := MeshInstance3D.new()
	mi.mesh = load(FLAME)
	mi.scale = Vector3.ONE * 2.0 * size
	f.add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.25)
	l.light_energy = 1.6
	l.omni_range = 6.0 * size
	l.position = Vector3(0, 0.6, 0)
	f.add_child(l)
	_actors.append(f)
	return f


func _cast() -> void:
	_grade(WAR_NIGHT)
	_stars(260, 8.0, 41)
	for n in World.area_node.find_children("*", "Npc", true, false):
		(n as Node3D).visible = false
	# The horde's torches on the slope, and braziers along the palisade.
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	for i in 34:
		var x := rng.randf_range(-42.0, 42.0)
		var z := rng.randf_range(-82.0, -52.0)
		_torch_at(Vector3(x, TitleWalker.ground_y(World.area_node, Vector2(x, z), 4.0, 40.0, 0.0) + 1.4, z), 0.35)
	for x in [-30.0, -18.0, 18.0, 30.0]:
		_torch_at(Vector3(x, TitleWalker.ground_y(World.area_node, Vector2(x, WALL_Z + 1.5), 4.0, 40.0, 0.0) + 3.6, WALL_Z + 1.2), 0.6)
	# The fortress beacons on the far horizon.
	for b in [Vector2(-140.0, -150.0), Vector2(150.0, -120.0)]:
		_beacons.append(_torch_at(Vector3(b.x, 26.0, b.y), 3.2))
	_row = _walker(ROWENA)
	_row.hero_stride = false
	_row.place(WALK)
	_row.face(Vector2(0, -1))
	_row.settle()
	_row.act(&"idle")
	_sol = _walker(SOLDIER)
	_sol.hero_stride = false
	_sol.place(WALK + Vector2(2.4, 0.4))
	_sol.face(Vector2(-0.3, -1))
	_sol.settle()
	_sol.act(&"idle")
	_ala = _walker(ALADRIEL)
	_ala.hero_stride = false
	_ala.place(Vector2(16.0, -37.0))
	_ala.face(Vector2(0, -1))
	_ala.settle()
	_ala.act(&"guard")
	_idr = _walker(IDRITH)
	_idr.hero_stride = false
	_idr.place(Vector2(15.0, -37.4))
	_idr.face(Vector2(-0.4, -1))
	_idr.settle()
	_idr.act(&"guard")


func _play(run: int) -> void:
	var gate := Vector3(0.0, TitleWalker.ground_y(World.area_node, Vector2(0, -30), 4.0, 40.0, 0.0), -30.0)
	# 1. Low behind the palisade: the wall black against a slope of torches.
	_cut(gate + Vector3(-10.0, 2.0, 12.0), gate + Vector3(0.0, 3.0, -40.0), 55.0)
	_glide(gate + Vector3(-6.0, 5.0, 6.0), gate + Vector3(0.0, 2.0, -40.0), 7.0)
	_tween().tween_property(self, "fade", 0.0, 1.5)
	if not await _wait(run, 3.6):
		return
	# 2. On the gatehouse walk.
	var top := _row.global_position
	_cut(top + Vector3(2.8, 1.6, 3.4), top + Vector3(0.6, 1.5, 0.0), 44.0)
	if not await _say(run, [
		{"text": "How many, would you say?", "actor": _row, "anim": &"talk"},
		{"text": "More than the stars, Captain.", "actor": _sol, "anim": &"talk"},
		{"text": "Then we'll be busy. Good. I hate standing about.", "actor": _row, "anim": &"talk"},
	]):
		return
	# 3. The horizon: a beacon flares, and goes out.
	var far: Node3D = _beacons[1]
	_cut(top + Vector3(0.0, 1.8, 0.4), far.global_position, 30.0)
	if not await _wait(run, 1.8):
		return
	var t := _tween()
	t.tween_property(far, "scale", Vector3.ONE * 2.2, 0.4)
	t.tween_property(far, "scale", Vector3.ONE * 0.01, 1.2)
	Sfx.play("beacon_flare", -10.0)
	if not await _wait(run, 2.2):
		return
	_cut(top + Vector3(-1.4, 1.7, 2.4), top + Vector3(0.0, 1.55, 0.0), 40.0)
	if not await _say(run, [
		{"text": "...Eastgate.", "actor": _sol, "anim": &"idle"},
		{"text": "Sound the horn. Everyone on the wall.", "actor": _row, "anim": &"talk"},
	]):
		return
	Sfx.play("war_horn", -10.0)
	# 4. The Questlords on the east wall, back to back.
	var q := _ala.global_position
	_cut(q + Vector3(2.4, 1.4, 3.2), q + Vector3(-0.4, 1.3, 0.0), 42.0)
	_glide(q + Vector3(1.6, 1.6, 2.6), q + Vector3(-0.4, 1.35, 0.0), 6.0)
	if not await _say(run, [
		{"text": "T-together?", "actor": _idr, "anim": &"guard"},
		{"text": "Always.", "actor": _ala, "anim": &"guard"},
	]):
		return
	await _end(run)
