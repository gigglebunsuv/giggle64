class_name TitleFallen
extends TitleScene
## A title scene (see TitleScene): Old Castle Town after the fall, under its
## red sky and drifting embers. Firebuns III stands by the dry fountain and
## gives the Sapphire Order its orders: find the knight with the sword. A
## goblin rummages through a pot. When they have gone, Pink slips out of an
## alley, looks up at the scorched sign of her armory, and makes a promise of
## her own. Their lines play by themselves.

const AREA := "castle_town_fallen"
const AMBIENCE := "res://assets/audio/amb_ruins.wav"
const FIREBUNS := "res://assets/models/firebuns.tscn"
const MAGE := "res://assets/models/sapphire_mage.tscn"
const GOBLIN := "res://assets/models/cinder_goblin.tscn"
const PINK := "res://assets/models/pink.tscn"
## The fountain in the square (castle_town.gd SQUARE) and the armory's sign.
const SQUARE := Vector2(0, 2)
const SIGN := Vector2(-31.0, -17.5)

## The burning town at dusk: a smoke-red sky, ember light, long shadows.
const EMBERS := {
	"sky": [
		[-25.0, Color(0.08, 0.02, 0.02)], [0.0, Color(0.55, 0.16, 0.08)], [8.0, Color(0.38, 0.1, 0.07)],
		[30.0, Color(0.18, 0.05, 0.06)], [90.0, Color(0.07, 0.02, 0.04)],
	],
	"hills": Color(0.2, 0.07, 0.06),
	"fog": Color(0.24, 0.08, 0.05), "fog_begin": 16.0, "fog_end": 90.0,
	"ambient": Color(0.5, 0.26, 0.2), "ambient_energy": 0.7,
	"sun": Color(1.0, 0.55, 0.3), "sun_energy": 0.8, "sun_rot": Vector3(-18.0, 30.0, 0.0),
	"fill": Color(0.3, 0.16, 0.3), "fill_energy": 0.35,
}

var _fb: TitleWalker = null
var _mages: Array[TitleWalker] = []
var _gob: TitleWalker = null
var _pink: TitleWalker = null
var _y := 0.0


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


## Shots laid out in the square's own heights.
func _at_y(v: Vector3) -> Vector3:
	return v + Vector3.UP * _y


func _cast() -> void:
	_grade(EMBERS)
	_y = TitleWalker.ground_y(World.area_node, SQUARE + Vector2(0, 7), 5.0, 80.0, 0.0)
	_fb = _walker(FIREBUNS)
	_fb.hero_stride = false
	_fb.stride = 1.6
	_fb.place(SQUARE + Vector2(0, 7.0))
	_fb.face(Vector2(0, 1))
	_fb.settle()
	_fb.act(&"idle")
	for i in 2:
		var m := _walker(MAGE)
		m.hero_stride = false
		m.walk_anim = &"walk"
		m.place(SQUARE + Vector2(-2.2 + i * 4.4, 11.0))
		m.face(Vector2(0, -1))
		m.settle()
		m.act(&"idle")
		_mages.append(m)
	_gob = _walker(GOBLIN)
	_gob.hero_stride = false
	_gob.place(Vector2(9.4, -9.6))
	_gob.face(Vector2(0, -1))
	_gob.settle()
	_gob.act(&"idle")
	_pink = _walker(PINK)
	_pink.hero_stride = false
	_pink.stride = 1.8
	_pink.place(Vector2(-22.0, 6.0))
	_pink.settle()
	_pink.visible = false
	var flame := _fb.model.find_child("GauntletFlame", true, false) as Node3D if _fb.model else null
	if flame:
		flame.visible = true


func _play(run: int) -> void:
	# 1. Wide over the square: smoke, embers, the Order gathered at the fountain.
	_cut(_at_y(Vector3(10.0, 6.0, 26.0)), _at_y(Vector3(0.0, 1.6, 6.0)))
	_glide(_at_y(Vector3(6.0, 4.0, 20.0)), _at_y(Vector3(0.0, 1.6, 7.0)), 6.0)
	_tween().tween_property(self, "fade", 0.0, 1.5)
	if not await _wait(run, 3.2):
		return
	# 2. Close on Firebuns.
	_cut(_fb.global_position + Vector3(1.6, 1.7, 3.0), _fb.global_position + Vector3(0, 1.75, 0), 42.0)
	_glide(_fb.global_position + Vector3(1.2, 1.75, 2.6), _fb.global_position + Vector3(0, 1.8, 0), 6.0)
	if not await _say(run, [
		{"text": "The knight with the goddesses' sword crawled away from my throne. *Alive.*", "actor": _fb, "anim": &"talk"},
		{"text": "Search every cellar and every rooftop. Search every village in Haven. Bring me that sword.", "actor": _fb, "anim": &"point"},
	]):
		return
	# 3. The mages answer, and fade away in blue light.
	_cut(_at_y(Vector3(0.0, 2.4, 2.0)), _at_y(Vector3(0.0, 1.5, 11.0)), 50.0)
	for m in _mages:
		m.act(&"cast")
	if not await _say(run, [{"text": "As you command, Lord Firebuns.", "actor": _mages[0], "anim": &"talk"}]):
		return
	Sfx.play("mage_appear", -6.0)
	for m in _mages:
		var tw := _tween()
		tw.tween_property(m, "scale", Vector3(0.05, 1.6, 0.05), 0.5)
		tw.tween_callback(m.hide)
	if not await _wait(run, 0.8):
		return
	# 4. He laughs, and walks away north toward the burning castle.
	_cut(_fb.global_position + Vector3(-3.0, 1.4, 4.0), _fb.global_position + Vector3(0, 1.6, -2.0), 48.0)
	_fb.act(&"laugh")
	Sfx.play("firebuns_laugh", -4.0)
	if not await _wait(run, 1.6):
		return
	_fb.release()
	_walk(_fb, SQUARE + Vector2(0, -20.0), 1.6)
	if not await _wait(run, 2.4):
		return
	# 5. A goblin rummages through a pot by the stalls, finds nothing, sulks off.
	_cut(_gob.global_position + Vector3(3.1, 1.5, 3.6), _gob.global_position + Vector3(0, 0.6, -0.6), 48.0)
	_gob.act(&"attack" if _gob.model and _gob.model.anim.has_animation(&"attack") else &"idle")
	Sfx.play("pot_break", -6.0)
	if not await _wait(run, 1.2):
		return
	_gob.release()
	_walk(_gob, Vector2(20.0, -10.0), 2.0)
	if not await _wait(run, 1.4):
		return
	# 6. Pink slips out of the alley to her armory's scorched sign.
	_pink.visible = true
	_cut(_pink.global_position + Vector3(2.0, 1.8, -12.0), _pink.global_position + Vector3(-4.0, 1.2, -16.0), 50.0)
	_glide(_pink.global_position + Vector3(0.0, 1.7, -14.0), _pink.global_position + Vector3(-6.0, 1.4, -20.0), 5.0)
	_pink.release()
	await _walk(_pink, SIGN + Vector2(2.5, 3.0), 2.6)
	if not _alive(run):
		return
	_pink.face_point(SIGN)
	_pink.act(&"worried")
	if not await _wait(run, 1.0):
		return
	_cut(_pink.global_position + Vector3(-1.4, 1.5, 2.4), _pink.global_position + Vector3(0, 1.45, 0), 44.0)
	if not await _say(run, [
		{"text": "...My forge. My beautiful forge.", "actor": _pink, "anim": &"worried"},
		{"text": "Hang on, everyone. Hang on, knight. We're taking it back.", "actor": _pink, "anim": &"stand"},
	]):
		return
	await _end(run)
