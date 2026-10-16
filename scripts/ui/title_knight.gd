class_name TitleKnight
extends TitleScene
## A title scene (see TitleScene): Castle Town years later (Chapter V), at
## dawn on the castle avenue. A knight in Haven blue kneels before the castle
## gate; Commander Rowena stands over him, and Himeko, sword in hand, insists
## on doing the knighting herself. The Guard lines the avenue, banners stir,
## and the sun comes up behind the towers. Their lines play by themselves.

const AREA := "castle_town_restored"
const AMBIENCE := "res://assets/audio/amb_town.wav"
const ROWENA := "res://assets/models/rowena.tscn"
const HIMEKO := "res://assets/models/himeko.tscn"
const SOLDIER := "res://assets/models/haven_soldier.tscn"
const SPOT := Vector2(0.0, -55.0)

const DAWN := {
	"sky": [
		[-25.0, Color(0.18, 0.14, 0.2)], [0.0, Color(1.0, 0.62, 0.4)], [8.0, Color(0.96, 0.76, 0.6)],
		[30.0, Color(0.5, 0.6, 0.85)], [90.0, Color(0.24, 0.32, 0.6)],
	],
	"hills": Color(0.4, 0.34, 0.42),
	"fog": Color(0.62, 0.48, 0.46), "fog_begin": 30.0, "fog_end": 150.0,
	"ambient": Color(0.72, 0.6, 0.62), "ambient_energy": 0.9,
	"sun": Color(1.0, 0.78, 0.55), "sun_energy": 1.0, "sun_rot": Vector3(-12.0, 170.0, 0.0),
	"fill": Color(0.5, 0.52, 0.8), "fill_energy": 0.4,
}

var _hero: TitleWalker = null
var _row: TitleWalker = null
var _him: TitleWalker = null
var _guard: Array[TitleWalker] = []


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


func _cast() -> void:
	_grade(DAWN)
	for n in World.area_node.find_children("*", "Npc", true, false):
		(n as Node3D).visible = false
	for n in World.area_node.find_children("Pepper*", "Node3D", true, false):
		(n as Node3D).visible = false
	_hero = _walker()
	_hero.place(SPOT)
	_hero.face(Vector2(0, -1))
	_hero.settle()
	if _hero.model:
		_hero.model.set_outfit("haven", "knight")
	_hero.act(&"kneel")
	_row = _walker(ROWENA)
	_row.hero_stride = false
	_row.place(SPOT + Vector2(-0.8, -2.4))
	_row.face(Vector2(0.2, 1))
	_row.settle()
	_row.act(&"idle")
	_him = _walker(HIMEKO)
	_him.hero_stride = false
	_him.place(SPOT + Vector2(2.2, -2.0))
	_him.face(Vector2(-0.6, 1))
	_him.settle()
	_him.act(&"idle")
	for i in 6:
		var sx := -1.0 if i % 2 == 0 else 1.0
		var g := _walker(SOLDIER)
		g.hero_stride = false
		g.place(SPOT + Vector2(sx * 3.6, -1.0 + int(i / 2) * 2.4))
		g.face(Vector2(-sx, 0))
		g.settle()
		g.act(&"idle")
		_guard.append(g)


func _play(run: int) -> void:
	var at := _hero.global_position
	# 1. Wide, low down the avenue: the castle against the dawn, the guard.
	_cut(at + Vector3(-3.0, 1.4, 12.0), at + Vector3(0.0, 6.0, -20.0), 55.0)
	_glide(at + Vector3(-1.5, 2.6, 8.0), at + Vector3(0.0, 4.0, -20.0), 7.0)
	_tween().tween_property(self, "fade", 0.0, 1.5)
	if not await _wait(run, 3.4):
		return
	# 2. Rowena over the kneeling knight.
	var r := _row.global_position
	_cut(r + Vector3(2.4, 1.5, 2.8), r + Vector3(0.0, 1.5, 0.0), 42.0)
	if not await _say(run, [
		{"text": "By the will of the Crown, and with the thanks of every soul in Haven...", "actor": _row, "anim": &"talk"},
		{"text": "*Wait!* A knighting needs a princess. Everyone knows that.", "actor": _him, "anim": &"talk"},
		{"text": "...Fine. Mind his ears.", "actor": _row, "anim": &"idle"},
	]):
		return
	# 3. Close on the knight, the sword's touch.
	_cut(at + Vector3(1.8, 1.2, 1.6), at + Vector3(0.0, 0.9, 0.0), 40.0)
	Sfx.play("sword_swing", -10.0, 0.0, 0.8)
	if not await _wait(run, 0.6):
		return
	Sfx.play("sword_swing", -10.0, 0.0, 0.9)
	if not await _say(run, [
		{"text": "I dub thee *Knight Gigglebuns*. Arise!", "actor": _him, "anim": &"laugh"},
	]):
		return
	_hero.act(&"idle")
	Sfx.play("fanfare_big", -12.0)
	for g in _guard:
		g.act(&"happy")
	# 4. Up over the avenue as the sun clears the towers.
	_cut(at + Vector3(0.0, 3.0, 9.0), at + Vector3(0.0, 1.4, 0.0), 50.0)
	_glide(at + Vector3(0.0, 12.0, 16.0), at + Vector3(0.0, 8.0, -30.0), 6.0)
	if not await _wait(run, 5.0):
		return
	await _end(run)
