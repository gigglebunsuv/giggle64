class_name TitleRidge
extends TitleScene
## A title scene (see TitleScene, Beta 1.4.0): Black Water Ridge at night.
## On the shelf of Mara's third camp, the knight in Haven blue, Commander
## Rowena and Sir Brannoc look up the last of the slope at Ridge Keep, the
## black falls pouring silent off the ledges behind it. Their lines play by
## themselves.

const AREA := "black_water_ridge"
const AMBIENCE := "res://assets/audio/amb_marsh.wav"
const ROWENA := "res://assets/models/rowena.tscn"
const SOLDIER := "res://assets/models/haven_soldier.tscn"
## The third camp's shelf and the Keep's gate (black_water_ridge.gd CAMPS[2], GATE).
const SPOT := Vector2(22.0, -64.0)
const GATE := Vector3(-6.0, 34.0, -112.0)

## A cold night: blue-black sky, a pale moon low behind the keep.
const BLACK_NIGHT := {
	"sky": [
		[-25.0, Color(0.03, 0.03, 0.05)], [0.0, Color(0.16, 0.18, 0.28)], [8.0, Color(0.12, 0.13, 0.22)],
		[30.0, Color(0.07, 0.08, 0.14)], [90.0, Color(0.03, 0.03, 0.06)],
	],
	"hills": Color(0.06, 0.06, 0.09),
	"fog": Color(0.12, 0.13, 0.18), "fog_begin": 14.0, "fog_end": 120.0,
	"ambient": Color(0.36, 0.4, 0.56), "ambient_energy": 0.7,
	"sun": Color(0.7, 0.78, 1.0), "sun_energy": 0.45, "sun_rot": Vector3(-20.0, 20.0, 0.0),
	"fill": Color(0.2, 0.24, 0.42), "fill_energy": 0.4,
}

var _hero: TitleWalker = null
var _row: TitleWalker = null
var _bran: TitleWalker = null


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


func _cast() -> void:
	_grade(BLACK_NIGHT)
	for n in World.area_node.find_children("*", "Npc", true, false):
		(n as Node3D).visible = false
	var up := Vector2(GATE.x - SPOT.x, GATE.z - SPOT.y).normalized()
	var side := Vector2(-up.y, up.x)
	_hero = _walker()
	_hero.place(SPOT)
	_hero.face(up)
	_hero.settle()
	if _hero.model:
		_hero.model.set_outfit("haven", "knight")
	_hero.act(&"idle")
	_row = _walker(ROWENA)
	_row.hero_stride = false
	_row.place(SPOT + side * 1.6 - up * 0.6)
	_row.face(up)
	_row.settle()
	_row.act(&"idle")
	_bran = _walker(SOLDIER)
	_bran.hero_stride = false
	_bran.place(SPOT - side * 1.6 - up * 0.8)
	_bran.face(up)
	_bran.settle()
	_bran.act(&"idle")


func _play(run: int) -> void:
	var at := _hero.global_position
	# 1. The Keep against the night, the black falls either side of it.
	_cut(at + Vector3(4.0, 1.6, 6.0), GATE + Vector3(0.0, 8.0, 0.0), 52.0)
	_glide(at + Vector3(2.0, 2.4, 4.0), GATE + Vector3(0.0, 12.0, 0.0), 7.0)
	_tween().tween_property(self, "fade", 0.0, 1.5)
	if not await _wait(run, 3.6):
		return
	# 2. The three of them, from in front.
	var up := (GATE - at)
	up.y = 0.0
	up = up.normalized()
	_cut(at + up * 4.0 + Vector3(0.0, 1.5, 0.0), at + Vector3(0.0, 1.3, 0.0), 44.0)
	if not await _say(run, [
		{"text": "Nothing's climbed out of those falls since sundown. ...That's good. Right? That's good?", "actor": _bran, "anim": &"talk"},
		{"text": "It's quiet because she's waiting, Brannoc. Up there, at the top.", "actor": _row, "anim": &"talk"},
		{"text": "Shields up, Knight. Whatever's at the top of those falls has waited a hundred years for someone to come.", "actor": _row, "anim": &"idle"},
	]):
		return
	# 3. Over their shoulders, up the slope to the gate.
	_cut(at - up * 3.0 + Vector3(0.0, 1.8, 0.0), GATE + Vector3(0.0, 3.0, 0.0), 40.0)
	_glide(at - up * 1.5 + Vector3(0.0, 2.2, 0.0), GATE + Vector3(0.0, 6.0, 0.0), 6.0, 34.0)
	if not await _wait(run, 5.5):
		return
	await _end(run)
