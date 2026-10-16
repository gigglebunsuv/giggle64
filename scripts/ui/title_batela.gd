class_name TitleBatela
extends TitleScene
## A title scene (see TitleScene): the Batela Fells at dusk, ash falling.
## Elder Maud sits by Ashwick's fire with little Tamsin, who cannot sleep.
## Up on the ridge, on the broken wall of Batela Keep, a tall figure holds a
## light in his hand and looks down at the camp. Their lines play by
## themselves.

const AREA := "batela_fells"
const AMBIENCE := "res://assets/audio/amb_fells.wav"
const MAUD := "res://assets/models/maud.tscn"
const TAMSIN := "res://assets/models/tamsin.tscn"
const FIREBUNS := "res://assets/models/firebuns.tscn"
## Ashwick's fire and the keep's south wall (batela_fells.gd CAMP, KEEP).
const CAMP := Vector2(-20, 30)
const KEEP := Vector2(12, -44)
const KEEP_Y := 6.0

## Dusk over the ash: a bruised orange horizon under gray, embers' light.
const ASH_DUSK := {
	"sky": [
		[-25.0, Color(0.06, 0.05, 0.05)], [0.0, Color(0.52, 0.28, 0.16)], [8.0, Color(0.36, 0.22, 0.18)],
		[30.0, Color(0.2, 0.17, 0.18)], [90.0, Color(0.08, 0.07, 0.09)],
	],
	"hills": Color(0.16, 0.13, 0.12),
	"fog": Color(0.26, 0.2, 0.17), "fog_begin": 14.0, "fog_end": 110.0,
	"ambient": Color(0.42, 0.32, 0.28), "ambient_energy": 0.7,
	"sun": Color(1.0, 0.6, 0.38), "sun_energy": 0.6, "sun_rot": Vector3(-12.0, 60.0, 0.0),
	"fill": Color(0.26, 0.22, 0.32), "fill_energy": 0.3,
}

var _maud: TitleWalker = null
var _tam: TitleWalker = null
var _fb: TitleWalker = null
var _y := 0.0


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


func _cast() -> void:
	_grade(ASH_DUSK)
	# The camp's own people step aside for the scene's.
	for n in World.area_node.find_children("*", "Npc", true, false):
		(n as Node3D).visible = false
	_y = TitleWalker.ground_y(World.area_node, CAMP + Vector2(0, 2), 5.0, 80.0, 0.0)
	_maud = _walker(MAUD)
	_maud.hero_stride = false
	_maud.place(CAMP + Vector2(-1.8, 1.6))
	_maud.face_point(CAMP)
	_maud.settle()
	_maud.act(&"idle")
	_tam = _walker(TAMSIN)
	_tam.hero_stride = false
	_tam.place(CAMP + Vector2(-0.4, 2.6))
	_tam.face_point(CAMP + Vector2(-1.8, 1.6))
	_tam.settle()
	_tam.act(&"idle")
	_fb = _walker(FIREBUNS)
	_fb.hero_stride = false
	_fb.place(KEEP + Vector2(-3.0, 13.6))
	_fb.face(Vector2(-0.4, 1))
	_fb.settle()
	_fb.act(&"idle")
	var flame := _fb.model.find_child("GauntletFlame", true, false) as Node3D if _fb.model else null
	if flame:
		flame.visible = true


func _play(run: int) -> void:
	var fire := Vector3(CAMP.x, _y, CAMP.y)
	# 1. Wide over the moor at dusk, ash drifting, the camp's fire far below the ridge.
	_cut(fire + Vector3(18.0, 9.0, 24.0), fire + Vector3(0.0, 1.0, 0.0))
	_glide(fire + Vector3(10.0, 5.0, 14.0), fire + Vector3(0.0, 1.0, 0.0), 6.0)
	_tween().tween_property(self, "fade", 0.0, 1.5)
	if not await _wait(run, 3.4):
		return
	# 2. By the fire.
	_cut(fire + Vector3(1.5, 1.3, 5.0), fire + Vector3(-1.2, 0.9, 1.8), 46.0)
	_glide(fire + Vector3(0.8, 1.2, 4.4), fire + Vector3(-1.2, 0.95, 2.0), 7.0)
	if not await _say(run, [
		{"text": "Maud? I can't sleep. The ash keeps getting in my blanket.", "actor": _tam, "anim": &"talk"},
		{"text": "Then sit with me a while, little one. The fire's warm enough for two.", "actor": _maud, "anim": &"talk"},
		{"text": "Will the knight from Haven come? Wren says a knight with a goddess sword is coming.", "actor": _tam, "anim": &"happy"},
		{"text": "...Maybe. Knights are like rain, child. You can't call them. You can only leave the door open.", "actor": _maud, "anim": &"talk"},
	]):
		return
	# 3. Up on the ridge: a figure on the keep's wall, a light in his hand.
	var top := _fb.global_position
	_cut(top + Vector3(-6.0, 1.2, 14.0), top + Vector3(0, 2.0, 0), 34.0)
	_glide(top + Vector3(-4.0, 1.6, 9.0), top + Vector3(0, 2.1, 0), 5.0)
	if not await _wait(run, 2.6):
		return
	_cut(top + Vector3(1.2, 1.9, 2.6), top + Vector3(0, 1.85, 0), 40.0)
	_fb.act(&"laugh")
	Sfx.play("firebuns_laugh", -8.0)
	if not await _wait(run, 1.8):
		return
	# 4. Back at the fire, Tamsin looks up at the ridge.
	_cut(fire + Vector3(-2.6, 1.0, 4.2), fire + Vector3(4.0, 3.0, -30.0), 48.0)
	_tam.face_point(KEEP)
	if not await _say(run, [
		{"text": "Maud... there's a light on the old keep.", "actor": _tam, "anim": &"idle"},
		{"text": "Don't look at it, child. Look at the fire. Look at our fire.", "actor": _maud, "anim": &"talk"},
	]):
		return
	await _end(run)
