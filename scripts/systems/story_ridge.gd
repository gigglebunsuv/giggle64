class_name StoryRidge
extends RefCounted
## Chapter V, second half: "Black Water Ridge" (Beta 1.4.0). Played through
## Story's wrappers:
## - front_camp():      the first sight of the knights' camp at the marsh's
##                      west end, where the black water stops them
##                      ("ch5:front_seen")
## - part_water():      the Parry learned, Rowena asks for the sword: its
##                      starlight drives the black water back and a causeway
##                      of old stones shows through ("ch5:ridge_open")
## - ridge_arrive():    the first sight of the Ridge, its black falls and
##                      Mara's keep at the top; the knights follow
##                      ("ch5:ridge_reached")
## - camps_broken():    the third undead camp falls: the three great chains
##                      that hold the Keep's gate shut snap ("ch5:camps_done")
## - mara_falls(mara):  Mara beaten at the top of the falls: her last words,
##                      the dead lie down all over the Ridge, and Firebuns III
##                      steps into a crack in the sky ("ch5:mara_done")

const ROWENA := "Commander Rowena"
const MARA := "Mara"
const FIREBUNS := "Firebuns III"
const KNIGHT := "Sir Brannoc"


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


static func _npc(npc_name: String) -> Node3D:
	if not is_instance_valid(World.area_node):
		return null
	return World.area_node.find_child(npc_name, true, false) as Node3D


# --- The marsh-front camp ---------------------------------------------------------

static func front_camp() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:front_seen"):
		return
	Cutscene.begin(false, [], "front_camp")
	Progress.set_flag("ch5:front_seen")
	var cam := Story._spot("cs_front_cam", p.global_position + Vector3(-4, 3, 4))
	var water := Story._spot("cs_front_water", p.global_position + Vector3(-14, 0, 0))
	Cutscene.cut(cam.global_position, water.global_position + Vector3.UP * 1.0, 52.0)
	Cutscene.glide(cam.global_position + Vector3(-3, 1, 0), water.global_position, 4.5, 48.0)
	await Cutscene.wait(1.2)
	if not _playing("front_camp"):
		return
	await Cutscene.say([
		"At the marsh's west end the knights of Haven have pitched their tents on the last dry ground. Past them, the black water lies still as glass.",
		"Nothing grows near it. Nothing crosses it. Far off, beyond it, a dark ridge... and the endless sound of falling water.",
	])
	if _playing("front_camp"):
		Cutscene.end()


## Rowena asks for the sword: Lothelye's starlight against Mara's water.
static func part_water() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:ridge_open"):
		return
	Cutscene.begin(true, [], "part_water")
	var water := Story._spot("cs_front_water", p.global_position + p.forward() * 8.0)
	var stand := Story._spot("cs_front_stand", water.global_position + Vector3(6, 0, 0))
	p.global_position = stand.global_position
	p.face_direction(water.global_position - stand.global_position)
	var rowena := _npc(ROWENA)
	Cutscene.cut(stand.global_position + Vector3(2.5, 1.8, 3.0), water.global_position + Vector3.UP * 0.6, 50.0)
	await Cutscene.wait(0.8)
	await Cutscene.say([
		"The dead don't like starlight. Lothelye's light is in that blade of yours now. Let's see what Mara's water thinks of it.",
	], ROWENA, rowena)
	# The hero raises the blade; a beam of starlight strikes the water.
	p.model.set_gear("bun_awake", Progress.shield)
	p.model.set_starlight(true)
	p.model.set_sword_drawn(true)
	Cutscene.play(p, &"item_get")
	Sfx.play("goddess_chime", -2.0, 0.0, 1.1)
	await Cutscene.wait(0.9)
	var beam := SwordBeam.new()
	beam.starlight = true
	p.get_parent().add_child(beam)
	beam.launch(p.global_position + Vector3.UP * 1.4 + p.forward() * 0.6, (water.global_position - p.global_position).normalized())
	await Cutscene.wait(0.5)
	Story._flash(Color(0.85, 0.75, 1.0, 0.9), 0.15, 1.2)
	Sfx.play("sword_beam", 2.0, 0.0, 0.6)
	Cutscene.shake(0.08, 1.4)
	Progress.set_flag("ch5:ridge_open")
	Cutscene.cut(water.global_position + Vector3(10.0, 6.0, 8.0), water.global_position, 55.0)
	Cutscene.glide(water.global_position + Vector3(4.0, 8.0, 10.0), water.global_position + Vector3(-8, 0, 0), 4.0, 50.0)
	await Cutscene.wait(1.2)
	await Cutscene.say([
		"The black water shrinks back from the light like something alive. Under it, a road of old white stones runs west, as if it had always been there.",
	])
	Cutscene.cut(stand.global_position + Vector3(2.5, 1.8, 3.0), stand.global_position + Vector3.UP * 1.4, 50.0)
	await Cutscene.say([
		"...Huh. I was half joking. Remind me never to argue with that sword.",
		"Knights! *Up!* We march for *Black Water Ridge*. Mara has three camps on the slopes below her keep. We break them one by one, together.",
	], ROWENA, rowena)
	p.model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	p.model.set_starlight(Progress.sword == "bun" and Progress.sword_awake())
	p.model.set_sword_drawn(false)
	Cutscene.end()


# --- Black Water Ridge ----------------------------------------------------------------

static func ridge_arrive() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:ridge_reached"):
		return
	Cutscene.begin(false, [], "ridge_arrive")
	Progress.set_flag("ch5:ridge_reached")
	var cam := Story._spot("cs_ridge_cam", p.global_position + Vector3(-4, 3, 4))
	var keep := Story._spot("cs_ridge_keep", p.global_position + Vector3(-60, 30, -120))
	Cutscene.cut(cam.global_position, keep.global_position, 55.0)
	Cutscene.glide(cam.global_position + Vector3(0, 5, 0), keep.global_position, 6.0, 46.0)
	await Cutscene.wait(1.6)
	if not _playing("ridge_arrive"):
		return
	await Cutscene.say([
		"*Black Water Ridge*. Black falls pour from every ledge into pools that never ripple. The dead are strong here; you can feel it, like cold on the back of your neck.",
		"High above, at the top of the falls, a keep of black stone. Three fires burn on the slopes below it: Mara's camps, between you and her door.",
	])
	if not _playing("ridge_arrive"):
		return
	World.play_track("")
	Sfx.play("undead_rise", -6.0, 0.0, 0.6)
	await Cutscene.say([
		"...Little knight. You came after all. Do you hear them? Every soul that ever drowned in this water answers to me.",
		"Come up, if you can. I will be waiting at the top of the falls.",
	], MARA)
	if _playing("ridge_arrive"):
		Cutscene.end()
		World.play_track(WorldData.music(World.area_id))


## The third camp has fallen: the chains on the Keep's gate snap.
static func camps_broken() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:camps_done"):
		return
	await p.get_tree().create_timer(1.2, false).timeout
	Cutscene.begin(false, [], "camps_broken")
	Progress.set_flag("ch5:camps_done")
	var gate := Story._spot("cs_ridge_gate", p.global_position + Vector3(0, 10, -30))
	Cutscene.cut(gate.global_position + Vector3(6.0, 4.0, 14.0), gate.global_position + Vector3.UP * 3.0, 50.0)
	await Cutscene.wait(0.8)
	Sfx.play("mallet_smash", 0.0, 0.0, 0.6)
	Cutscene.shake(0.12, 0.8)
	Story._burst(gate.global_position + Vector3(0, 5.0, 0), Color(0.5, 0.6, 0.9), 3.0)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"With the last camp's fire out, the three great chains across the Keep's gate snap one after another, and the gate groans open.",
	])
	await Cutscene.say([
		"That's the last of them! The way up is open, Knight. We'll hold the slopes. You go and finish this.",
	], ROWENA)
	Cutscene.end()


## Mara beaten at the top of the falls.
static func mara_falls(mara: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:mara_done"):
		return
	Cutscene.begin(true, [mara] if is_instance_valid(mara) else [], "mara_falls")
	World.play_track("")
	var at := mara.global_position if is_instance_valid(mara) else p.global_position + p.forward() * 4.0
	if is_instance_valid(mara):
		Cutscene.face(mara, p.global_position)
	Cutscene.cut(p.global_position + Vector3(3.0, 2.0, 3.0), at + Vector3.UP * 1.4, 48.0)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"Mara sinks to one knee. Her glaive rings on the stone and slides away toward the edge of the falls.",
	])
	await Cutscene.say([
		"...A well-placed strike. I did not think the little knight had it in him.",
		"Do you know what I was, before? A knight. Like you. I drowned in this water defending a king who never came for me.",
		"The burning one promised I would never drown again. ...He lied. They always lie.",
	], MARA, mara)
	Sfx.play("goddess_chime", -6.0, 0.0, 0.5)
	if is_instance_valid(mara):
		var t := mara.create_tween()
		t.tween_property(mara, "scale", Vector3(mara.scale.x, 0.05, mara.scale.z), 1.8)
		t.tween_callback(mara.queue_free)
	await Cutscene.wait(1.4)
	Progress.set_flag("ch5:mara_done")
	await Cutscene.say([
		"All over the Ridge the dead lie down where they stand, as quietly as people going to sleep. The black falls run clear.",
	])
	# Firebuns, high on the cliff over the falls, and the crack in the sky.
	var top := Story._spot("cs_falls_top", at + Vector3(0, 9.0, -12.0))
	var fb := Cutscene.actor("firebuns", top.global_position, 0.0, &"idle")
	if fb:
		Cutscene.face(fb, p.global_position)
		Story._gauntlet(fb, true)
	Cutscene.cut(p.global_position + Vector3(-2.0, 1.6, 4.0), top.global_position + Vector3.UP * 1.6, 44.0)
	await Cutscene.wait(1.0)
	Sfx.play("firebuns_laugh", -4.0, 0.0)
	await Cutscene.say([
		"Well. There goes my army. You do keep breaking my things, little knight.",
		"No matter. Mara was only ever meant to keep you busy while the crack grew wide enough.",
	], FIREBUNS, fb)
	Story._tint_area(Color(0.6, 0.55, 1.0), 1.2)
	Sfx.play("goddess_appear", -4.0, 0.0, 0.4)
	Cutscene.shake(0.1, 1.6)
	await Cutscene.say([
		"Over the falls the sky splits like old ice. Behind the crack there are no stars at all... and something in that dark is *listening*.",
	])
	await Cutscene.say([
		"The one behind the dark has waited a very long time. Follow me if you dare. *The Astral Rift* is open.",
	], FIREBUNS, fb)
	if fb:
		Story._burst(fb.global_position + Vector3.UP * 1.0, Color(0.7, 0.6, 1.0), 3.0)
		fb.queue_free()
	Story._tint_area(Color(1, 1, 1), 1.4)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"*Mara is gone, and her army with her.* But the crack in the sky stays open over Black Water Ridge.",
		"Rowena will want to hear of it. And somewhere, Lothelye is surely watching.",
	])
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))
