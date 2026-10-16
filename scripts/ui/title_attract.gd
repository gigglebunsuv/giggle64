class_name TitleAttract
extends TitleScene
## A title scene (see TitleScene): out in Bunsriel Fields, Sir Gigglebuns
## gives a straw dummy a sound thrashing, is bitten on the ankle by a rat, and
## gives chase; the dummy, left spinning, gets a visit from a curious horse.
## Nothing to do with the story.

const AREA := "field"
## Where it happens (open, flat grass north of the field's middle).
const DUMMY := Vector2(2, -72)
const HERO_SPOT := Vector2(0.55, -72)
const STRAWMAN := "res://assets/models/strawman.tscn"
const RAT := "res://assets/models/rat.tscn"
const HORSE := "res://assets/models/horse.tscn"
const AMBIENCE := "res://assets/audio/amb_field.wav"

var _hero: TitleWalker = null
var _dummy: TitleWalker = null
var _rat: TitleWalker = null
var _horse: TitleWalker = null


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


func _cast() -> void:
	_dummy = _walker(STRAWMAN)
	_dummy.turn_to_motion = false
	_dummy.global_position = Vector3(DUMMY.x, 0, DUMMY.y)
	_dummy.face(Vector2(-1, 0.25))
	_dummy.settle()
	_dummy.act(&"idle")
	_hero = _walker()
	_hero.global_position = Vector3(-10, 0, -71)
	_hero.face(Vector2(1, 0))
	_hero.settle()
	_rat = _walker(RAT)
	_rat.hero_stride = false
	_rat.walk_anim = &"run"
	_rat.stride = 2.4
	_rat.global_position = Vector3(-14, 0, -73)
	_rat.settle()
	_rat.visible = false
	_horse = _walker(HORSE)
	_horse.hero_stride = false
	_horse.run_anim = &"trot"
	_horse.run_speed = 2.6
	_horse.stride = 2.2
	_horse.global_position = Vector3(16, 0, -66)
	_horse.settle()
	_horse.visible = false


# --- The scene ------------------------------------------------------------------

func _play(run: int) -> void:
	# 1. Wide: the dummy stands in the grass; the hero strolls in from the left.
	_cut(Vector3(1.0, 2.3, -61.5), Vector3(-1.5, 1.0, -72.0))
	_glide(Vector3(2.2, 1.9, -63.0), Vector3(0.5, 1.0, -72.0), 5.0)
	_tween().tween_property(self, "fade", 0.0, 1.0)
	_walk(_hero, HERO_SPOT, 1.8)
	if not await _wait(run, 5.4):
		return
	_hero.face_point(DUMMY)
	# 2. Medium, from his left: draw, two cuts, and a jump slash.
	_cut(Vector3(-1.2, 1.35, -68.6), Vector3(1.4, 1.0, -72.1))
	_glide(Vector3(-0.6, 1.5, -68.2), Vector3(1.3, 1.0, -72.1), 5.5)
	if not await _wait(run, 0.5):
		return
	_hero.model.set_sword_drawn(true)
	Sfx.play("sword_swing", -6.0, 0.05, 1.3)
	if not await _wait(run, 0.3):
		return
	for cut in [&"attack_1", &"attack_2"]:
		_hero.act(cut)
		Sfx.play("sword_swing", -2.0)
		if not await _wait(run, 0.18):
			return
		_hit_dummy()
		if not await _wait(run, maxf(_hero.anim_length(cut) - 0.18, 0.3)):
			return
	_hero.act(&"jumpslash")
	Sfx.play("jump", -4.0)
	var jump := _hero.anim_length(&"jumpslash")
	if not await _wait(run, jump):
		return
	_hero.act(&"jumpslash_land")
	Sfx.play("heavy_swing", -2.0)
	_hit_dummy(true)
	if not await _wait(run, _hero.anim_length(&"jumpslash_land") + 0.2):
		return
	# 3. In front of him: the sword goes away. A satisfied pause.
	_cut(Vector3(3.3, 1.45, -68.9), Vector3(0.55, 1.15, -72.0), 46.0)
	_glide(Vector3(3.0, 1.35, -69.3), Vector3(0.55, 1.2, -72.0), 3.0)
	_hero.face(Vector2(1, 1.2))
	_hero.act(&"sheathe")
	if not await _wait(run, minf(_hero.anim_length(&"sheathe"), 1.2) * 0.6):
		return
	_hero.model.set_sword_drawn(false)
	if not await _wait(run, minf(_hero.anim_length(&"sheathe"), 1.2) * 0.4 + 0.2):
		return
	_hero.act(&"idle", 1.0, 0.25)
	if not await _wait(run, 1.3):
		return
	# 4. Something in the grass behind him...
	_cut(Vector3(0.0, 1.0, -66.4), Vector3(-1.2, 0.6, -72.0), 50.0)
	_glide(Vector3(0.6, 1.1, -66.0), Vector3(-0.4, 0.7, -72.0), 3.0)
	_rat.visible = true
	_rat.global_position = Vector3(-9, 0, -72.9)
	_rat.settle()
	Sfx.play("rat_squeak", -6.0)
	await _walk(_rat, Vector2(-0.15, -72.35), 4.5)
	if not _alive(run):
		return
	_rat.face_point(_hero.xz())
	_rat.act(&"bite")
	if not await _wait(run, 0.2):
		return
	_hero.act(&"hurt")
	_hero.model.flash(Color(1, 0.3, 0.3), 0.15)
	Sfx.play("player_hurt", -2.0)
	_shake(0.05, 0.3)
	if not await _wait(run, 0.35):
		return
	_hero.act(&"jump")
	_hop(_hero, 0.45, 0.5)
	if not await _wait(run, 0.6):
		return
	# The rat bolts, and the hero, sword out again, is after it.
	_rat.release()
	Sfx.play("rat_squeak", -4.0, 0.05, 1.2)
	_walk(_rat, Vector2(-3.5, -90.0), 5.5)
	if not await _wait(run, 0.35):
		return
	_hero.face_point(Vector2(-3.5, -90.0))
	_hero.model.set_sword_drawn(true)
	_hero.release()
	_walk(_hero, Vector2(-4.0, -92.0), 4.6)
	if not await _wait(run, 2.6):
		return
	# 5. Back at the dummy, still turning. A moment of quiet, then the chase
	# comes back the other way. (The first chase is still under way off
	# screen: stop it before placing them.)
	_kill_tweens()
	_rat.global_position = Vector3(-8, 0, -70.9)
	_rat.settle()
	_hero.global_position = Vector3(-11, 0, -70.6)
	_hero.settle()
	_cut(Vector3(3.4, 1.5, -66.6), Vector3(1.6, 1.0, -72.4), 46.0)
	if not await _wait(run, 1.4):
		return
	Sfx.play("rat_squeak", -6.0, 0.05, 1.3)
	_walk(_rat, Vector2(16.0, -71.1), 5.5)
	if not await _wait(run, 0.55):
		return
	_walk(_hero, Vector2(16.0, -70.8), 4.6)
	if not await _wait(run, 4.2):
		return
	_rat.visible = false
	_hero.visible = false
	# 6. A horse wanders up and considers the dummy. The dummy considers it back.
	_horse.visible = true
	Sfx.play("horse_snort", -8.0)
	_cut(Vector3(-1.6, 1.7, -66.8), Vector3(3.5, 1.4, -71.0), 50.0)
	_glide(Vector3(-1.0, 1.9, -66.4), Vector3(3.2, 1.4, -71.0), 5.0)
	await _walk(_horse, Vector2(4.3, -70.0), 1.7)
	if not _alive(run):
		return
	_horse.face_point(DUMMY)
	_horse.act(&"idle")
	if not await _wait(run, 1.0):
		return
	_dummy.act(&"hop")
	Sfx.play("hop", -6.0)
	if not await _wait(run, 0.4):
		return
	_horse.act(&"rear")
	Sfx.play("horse_neigh", -4.0)
	if not await _wait(run, 1.6):
		return
	await _end(run)


## The dummy takes a blow: it reels, or spins round on its pole for the last.
func _hit_dummy(big := false) -> void:
	Sfx.play("sword_hit", -2.0 if big else -4.0)
	_dummy.act(&"spin" if big else &"stunned", 1.0, 0.04)
	if big:
		_shake(0.06, 0.25)


# The scene was laid out on ground at about this height; follow the real
# ground under the dummy so the shots sit right if the field changes.
func _lift() -> float:
	return _dummy.global_position.y - 0.4 if is_instance_valid(_dummy) else 0.0
