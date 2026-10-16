class_name StoryChapter3
extends RefCounted
## Chapter III, "The Batela Fells" (Beta 1.1.0). Played through Story's
## wrappers (StoryTrigger calls Story.<scene>):
## - fells_arrive():    out of the Forest of the Dead, the first sight of the
##                      Fells (flag "ch3:arrived")
## - keep_duel():       Firebuns III waiting in the great hall of Batela Keep;
##                      the duel begins (needs "ch3:maud_met")
## - keep_duel_end(fb): he ends the duel himself, leaves the hero in the ash
##                      and goes; the hero wakes in Ashwick and Elder Maud
##                      confesses ("ch3:keep_duel", "ch3:confession": the
##                      crypt gate opens)
## - sanctum_ritual():  past Incunax, Archmagus Velloran finishes the Order's
##                      ritual: the Astral seal cracks, and he leaves the
##                      hero the Dark Prophecy ("ch3:seal_cracked")
## Ottilie reads the Prophecy in Haven Library (ottilie_lines.gd), and the
## chapter ends there ("ch3:prophecy_read").

const FIREBUNS := "Firebuns III"
const MAUD := "Maud"
const VELLORAN := "Archmagus Velloran"


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


## The Fells, seen from the end of the forest road: ash falling on a dead
## land, the keep on its ridge.
static func fells_arrive() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch3:arrived"):
		return
	Cutscene.begin(false, [], "fells_arrive")
	Progress.set_flag("ch3:arrived")
	var at := p.global_position
	Cutscene.cut(at + Vector3(-3.0, 2.2, 3.0), at + Vector3(10.0, 2.0, -6.0), 55.0)
	Cutscene.glide(at + Vector3(2.0, 9.0, 4.0), at + Vector3(60.0, 4.0, -40.0), 5.0, 60.0)
	await Cutscene.wait(1.6)
	if not _playing("fells_arrive"):
		return
	await Cutscene.say([
		"The *Batela Fells*. Firebuns III's own homeland... burned by his own hand.",
		"Ash still falls out of the sky, though the fires went out long ago. Far off, a thread of smoke: someone has lit a camp fire.",
	])
	if _playing("fells_arrive"):
		Cutscene.end()


## The great hall of Batela Keep: he has been waiting.
static func keep_duel() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch3:keep_duel") or not is_instance_valid(World.area_node):
		return
	var mark := Story._spot("cs_keep_firebuns", p.global_position + Vector3(0, 0, -8))
	var fb: Node3D = (load("res://scenes/enemies/firebuns.tscn") as PackedScene).instantiate()
	fb.set("duel", true)
	World.area_node.add_child(fb)
	fb.global_position = mark.global_position
	fb.set("facing_yaw", PI)
	fb.rotation.y = PI
	Cutscene.begin(true, [fb], "keep_duel")
	var hero := Story._spot("cs_keep_hero", p.global_position)
	p.global_position = hero.global_position
	p.face_direction((fb.global_position - p.global_position) * Vector3(1, 0, 1))
	var cam := Story._spot("cs_keep_cam", p.global_position + Vector3(4, 2.5, 3))
	Cutscene.cut(cam.global_position, fb.global_position + Vector3.UP * 1.6, 50.0)
	await Cutscene.wait(1.0)
	if not _playing("keep_duel"):
		return
	await Cutscene.say(["You followed my trail all the way here. Through the forest of my dead. How touching."], FIREBUNS, null)
	Story._close_on(fb, 1.0, 3.2, 1.9)
	(fb.get("model") as CharacterModel).play(&"talk", 0.3)
	await Cutscene.say([
		"This was my hall. That was my chair. And up those stairs is the room where my loyal people poured poison in my wine and watched me sleep.",
		"They thought it would end me. Kings like me don't end, little knight. We wait.",
	], FIREBUNS)
	if not _playing("keep_duel"):
		return
	(fb.get("model") as CharacterModel).play(&"point", 0.2)
	Cutscene.cut(p.global_position + Vector3(1.2, 1.7, 2.8), fb.global_position + Vector3.UP * 1.6, 50.0)
	await Cutscene.say(["Come, then. Let's see if the goddesses' sword has learned anything since the castle."], FIREBUNS)
	Cutscene.end()
	fb.call("wake")


## He ends it: the Gauntlet's flame throws the hero down, and he goes. Then
## Ashwick, by the fire, and Elder Maud's confession.
static func keep_duel_end(fb: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	World.play_track("")
	Cutscene.begin(true, [fb], "keep_duel_end")
	Progress.set_flag("ch3:keep_duel")
	var fbm := fb.get("model") as CharacterModel
	var to_hero := p.global_position - fb.global_position
	to_hero.y = 0.0
	to_hero = to_hero.normalized() if to_hero.length() > 0.1 else Vector3(0, 0, 1)
	fb.set("facing_yaw", atan2(-to_hero.x, -to_hero.z))
	fb.rotation.y = atan2(-to_hero.x, -to_hero.z)
	p.face_direction(-to_hero)
	Story._close_on(fb, 1.0, 3.2, 1.8)
	fbm.play(&"laugh", 0.2)
	Sfx.play("firebuns_laugh", 0.0, 0.0)
	await Cutscene.say(["Enough. You still swing that sword like it's asleep in your hands. Because it is."], FIREBUNS)
	fbm.play(&"raise", 0.2)
	Story._gauntlet(fb, true)
	Sfx.play("fire_whoosh", 0.0, 0.0)
	await Cutscene.wait(0.4)
	Story._flash(Color(1.0, 0.55, 0.25, 0.9), 0.1, 0.7)
	Cutscene.shake(0.14, 1.0)
	Story._burst(p.global_position + Vector3.UP * 1.0, Color(1.0, 0.6, 0.3), 2.5)
	Cutscene.play(p, &"hurt")
	Sfx.play("player_hurt", 0.0, 0.0)
	await Cutscene.wait(0.5)
	Cutscene.play(p, &"death")
	await Cutscene.wait(1.2)
	Cutscene.cut(p.global_position + Vector3(0.0, 0.5, 0.0) - to_hero * 2.6 + Vector3(-to_hero.z, 0, to_hero.x) * 0.8, fb.global_position + Vector3.UP * 1.8, 50.0)
	Story._gauntlet(fb, false)
	fbm.play(&"idle", 0.2)
	await Cutscene.say([
		"I could finish it. Right here, on the floor of my own hall.",
		"But I want you to see it. Go home, little hero. *Watch it burn.*",
	], FIREBUNS)
	Story._flames(fb.global_position, 1.6, true)
	Sfx.play("fire_whoosh", 0.0, 0.0, 0.8)
	await Cutscene.wait(0.4)
	if is_instance_valid(fb):
		fb.queue_free()
	await Cutscene.wait(1.0)
	# Ashwick, by Maud's tent: she found him and brought him down.
	await World.cutscene_load("batela_fells", "ashwick_bed", false, true)
	p = GameManager.player
	if not is_instance_valid(p):
		Cutscene.end()
		return
	p.health.heal(p.health.max_health)
	var bed := Story._spot("cs_ashwick_bed", p.global_position)
	p.global_position = bed.global_position
	p.face_direction(Vector3(0, 0, 1))
	var maud := World.area_node.find_child(MAUD, true, false) as Npc
	Cutscene.begin(false, [maud] if maud else [], "keep_duel_end")
	var cam := Story._spot("cs_ashwick_cam", p.global_position + Vector3(3, 2, 4))
	Cutscene.cut(cam.global_position, p.global_position + Vector3.UP * 0.9, 50.0)
	Cutscene.play(p, &"land")
	await Cutscene.wait(0.8)
	await confession(maud)
	if _playing("keep_duel_end"):
		Cutscene.end()


## Elder Maud, by the hero's bedside: what her people did, and the key.
static func confession(maud: Npc) -> void:
	var p := GameManager.player
	if is_instance_valid(maud) and is_instance_valid(p):
		Cutscene.face(maud, p.global_position)
		Story._close_on(maud, 1.0, 2.4, 1.35)
		maud.cs_anim = &"talk"
	await Cutscene.say([
		"Easy. Easy now. Odile carried you down from the Keep. You were burning and you didn't make a sound.",
		"You met him, then. He let you live. ...He always did like an audience.",
	], MAUD, maud)
	if is_instance_valid(maud):
		maud.cs_anim = &"idle"
	await Cutscene.say([
		"I should tell you something, young knight. Before you go any further for our sake.",
		"Seven years ago, I mixed the nightshade into his wine. All of us did, a little each, so no one hand did it. Odile kept the door shut.",
		"We thought we were saving Batela from him. And then he came back... and the fire came to every village, one by one.",
		"It was for us. All of it. It was for what I did.",
	], MAUD, maud)
	if is_instance_valid(maud):
		maud.cs_anim = &"talk"
	await Cutscene.say([
		"...Here. The key to the crypt gate under the old chapel. I kept it from you because I was afraid of what you'd find down there, and afraid of what you'd think of us.",
		"Whatever those blue-robes are doing, it started with us. Let it end with you.",
	], MAUD, maud)
	Progress.set_flag("ch3:confession")
	Sfx.play("secret", -2.0, 0.0)
	await Cutscene.say(["Elder Maud opened the *crypt gate* under the old chapel, west of Ashwick."])
	if is_instance_valid(maud):
		maud.cs_anim = &""


## The Order's ritual chamber: Archmagus Velloran, the last words of the
## rite, the seal cracking, and the Prophecy left behind.
static func sanctum_ritual() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch3:seal_cracked") or not is_instance_valid(World.area_node):
		return
	Cutscene.begin(true, [], "sanctum_ritual")
	var spot := Story._spot("cs_ritual_mage", p.global_position + Vector3(0, 0.5, -12))
	var mage := Cutscene.actor("sapphire_mage", spot.global_position, 0.0, &"cast")
	var hero := Story._spot("cs_ritual_hero", p.global_position)
	p.global_position = hero.global_position
	p.face_direction(Vector3(0, 0, -1))
	if mage:
		Cutscene.face(mage, p.global_position)
	var cam := Story._spot("cs_ritual_cam", p.global_position + Vector3(5, 3, 2))
	Cutscene.cut(cam.global_position, spot.global_position + Vector3.UP * 1.6, 50.0)
	await Cutscene.wait(1.0)
	if not _playing("sanctum_ritual"):
		return
	await Cutscene.say(["...and the door opens from both sides. *So it is written.*"], VELLORAN, null)
	if mage:
		Story._close_on(mage, 1.0, 3.0, 1.7)
		Cutscene.play(mage, &"talk")
	await Cutscene.say([
		"Ah. The Knight of Haven. You tore up our poor doorkeeper. Never mind: the Bound Page had done all it was made to do.",
		"I am *Velloran*, Archmagus of the Sapphire Order. And you are just in time to watch the world change.",
	], VELLORAN, mage)
	if mage:
		Cutscene.play(mage, &"cast")
	Sfx.play("boss_roar", -4.0, 0.0, 0.5)
	Story._flash(Color(0.45, 0.5, 1.0, 0.9), 0.15, 1.0)
	Cutscene.shake(0.2, 2.0)
	Cutscene.cut(p.global_position + Vector3(2.0, 1.2, 4.0), spot.global_position + Vector3.UP * 4.0, 65.0)
	Story._burst(spot.global_position + Vector3.UP * 2.0, Color(0.5, 0.6, 1.0), 4.0)
	await Cutscene.wait(1.0)
	await Cutscene.say(["...at... last..."], "???", null)
	await Cutscene.say(["A voice from nowhere: from under the floor, from inside the stone, from far behind the stars. It sounds very old, and very pleased."])
	if not _playing("sanctum_ritual"):
		return
	if mage:
		Story._close_on(mage, 1.0, 3.0, 1.7)
		Cutscene.play(mage, &"talk")
	await Cutscene.say([
		"Do you feel it? The *Astral seal* has cracked. Our Lord stirs in his prison, and the king's fire answers him, everywhere at once.",
		"Firebuns thinks he is our master. He is our key. When he has burned enough, the door will open all the way.",
		"Here. Take this home to your little kingdom, Knight. Let them read how it ends.",
	], VELLORAN, mage)
	Sfx.play("fire_whoosh", -2.0, 0.0, 1.4)
	if mage:
		Story._burst(mage.global_position + Vector3.UP * 1.0, Color(0.45, 0.45, 1.0), 2.0)
		mage.queue_free()
	await Cutscene.wait(0.6)
	Progress.set_flag("ch3:seal_cracked")
	Cutscene.end()
	await GetItem.present(p, "dark_prophecy")
