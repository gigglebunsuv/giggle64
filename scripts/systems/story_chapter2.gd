class_name StoryChapter2
extends RefCounted
## Chapter II, "The Gauntlet's Trail" (Beta 1.0.0): the scenes after the lost
## battle. Played through Story's wrappers (StoryTrigger calls Story.<scene>):
## - wake_home():  the first morning after the ending: the hero wakes at home,
##                 and Himeko bursts in with the news (flag "ch2:woke")
## - shelter():    Castle Town's survivors in Himeko's palace: the Questlords
##                 and Pink tell him where Firebuns went and what he needs
##                 (flag "ch2:shelter_met")
## The quest goes on in the people's lines (shelter_lines.gd), the Order's
## letter in Frostpeak Hollow (order_letter_lines.gd) and the scorched map in
## the Sun Trial (order_map_lines.gd).

const HIMEKO := "Himeko"


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


## Home, three days after the castle: he wakes as on the first morning, and
## before he is properly up Himeko flings the door open.
static func wake_home() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch2:woke"):
		return
	Cutscene.begin(false, [], "chapter_two")
	Progress.set_flag("ch2:woke")
	# Chapter II's card first, over black.
	Story._ensure_overlay().black = 1.0
	var bed_mark := Story._spot("cs_bed", p.global_position)
	var at: Vector3 = bed_mark.global_position
	p.visible = false
	var sleeper := Cutscene.actor("sir_gigglebuns", at + Vector3(0, -0.08, -0.05), PI, &"sleep")
	if sleeper:
		for n in sleeper.find_children("*", "Node3D", true, false):
			var nn := String(n.name)
			if nn.begins_with("Sword") or nn.begins_with("Shield") or nn.begins_with("Scabbard") or nn.begins_with("Bow"):
				(n as Node3D).visible = false
	Cutscene.cut(at + Vector3(1.7, 1.5, 2.6), at + Vector3(0, 0.25, -0.5), 50.0)
	await Story.chapter_card(2)
	await Story._black(0.0, 1.2)
	Story._clear_overlay()
	await Cutscene.wait(1.0)
	if not _playing("chapter_two"):
		return
	await Cutscene.say(["...Three days. Sir Gigglebuns IV has slept for three days."])
	Sfx.play("rooster", -2.0, 0.0)
	Cutscene.play(sleeper, &"wake", 0.3)
	await Cutscene.wait(2.6)
	if not _playing("chapter_two"):
		return
	if is_instance_valid(sleeper):
		sleeper.queue_free()
	if not is_instance_valid(p):
		return
	p.visible = true
	Cutscene.play(p, &"land")
	Sfx.play("land", -4.0)
	# The door flies open.
	var door := World.area_node.find_child("from_village", true, false) as Node3D
	var door_at: Vector3 = door.global_position if door else p.global_position + Vector3(2, 0, 3)
	Sfx.play("door_open", 0.0)
	var hime := Cutscene.actor("himeko", door_at, PI, &"talk")
	var mid := p.global_position.lerp(door_at, 0.55)
	Cutscene.cut(p.global_position + (door_at - p.global_position).normalized().rotated(Vector3.UP, 1.2) * 3.0 + Vector3.UP * 1.6, mid + Vector3.UP * 1.1, 52.0)
	await Cutscene.walk(hime, p.global_position.lerp(door_at, 0.4), 3.6, &"talk")
	if not _playing("chapter_two"):
		return
	Cutscene.face(hime, p.global_position)
	Cutscene.face(p, hime.global_position)
	Cutscene.play(hime, &"happy")
	await Cutscene.say([
		"My knight!! You're AWAKE!",
		"Three days! You slept for THREE DAYS! That pink-haired blacksmith carried you all the way home from the castle on her back!",
	], HIMEKO)
	Cutscene.play(hime, &"pout")
	await Cutscene.say([
		"Castle Town has... fallen. Everyone who got out is staying in *my palace*. All of them. In my palace. Eating my cake.",
	], HIMEKO)
	Cutscene.play(hime, &"laugh")
	await Cutscene.say([
		"...Ahem! A princess opens her doors to her people, naturally. Ohohoho!",
		"The Questlords wish to see you at once. Come to the *palace*, my knight. That is a royal order!",
	], HIMEKO)
	if not _playing("chapter_two"):
		return
	Cutscene.play(hime, &"talk")
	await Cutscene.walk(hime, door_at, 4.0, &"talk")
	Sfx.play("door_open", -4.0, 0.0, 1.2)
	if is_instance_valid(hime):
		hime.queue_free()
	if _playing("chapter_two"):
		Cutscene.end()


## In the palace: Aladriel, Idrith and Pink tell him what they know.
static func shelter() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch2:shelter_met") or not is_instance_valid(World.area_node):
		return
	var folk := {}
	for who in ["Aladriel", "Idrith", "Pink", "Himeko"]:
		folk[who] = World.area_node.find_child(who, true, false) as Npc
	Cutscene.begin(false, folk.values().filter(func(n: Variant) -> bool: return n != null), "shelter")
	Progress.set_flag("ch2:shelter_met")
	var ala: Npc = folk.Aladriel
	var idr: Npc = folk.Idrith
	var pink: Npc = folk.Pink
	var hime: Npc = folk.Himeko
	var centre := p.global_position
	for n: Npc in [ala, idr, pink]:
		if n:
			centre = centre.lerp(n.global_position, 0.3)
	Cutscene.cut(p.global_position + Vector3(-2.5, 2.2, 3.0), centre + Vector3.UP * 1.2, 55.0)
	await Cutscene.say(["The palace is crowded with the people of Castle Town: blankets on the marble, bundles by the pond, and in the middle of it all..."])
	if ala:
		Story._close_on(ala, 1.0, 2.6, 1.55)
		ala.cs_anim = &"talk"
	await Cutscene.say([
		"You're up. Good. ...Don't look at me like that, knight. We all lost back there.",
		"Firebuns didn't stay to rule Haven. Three nights ago he marched east out of the castle with half the *Sapphire Order*. He's hunting for something.",
	], "Aladriel")
	if not _playing("shelter"):
		return
	if idr:
		Story._close_on(idr, -1.0, 2.4, 1.45)
		idr.cs_anim = &"talk"
	await Cutscene.say([
		"Th-the mages talked about *Frostpeak* while they marched us to the cells. A hollow under the mountain... behind the *frozen falls*.",
	], "Idrith")
	if pink:
		Story._close_on(pink, 1.0, 2.4, 1.4)
		pink.cs_anim = &"stand"
	await Cutscene.say([
		"And you won't get through ice like that with a sword. You need a hammer. A BIG one.",
		"The royal *Iron Mallet*! It hung in the *castle armory*. Those goblins couldn't even lift it. I bet it's still there!",
	], "Pink")
	if not _playing("shelter"):
		return
	if ala:
		Story._close_on(ala, 1.0, 2.6, 1.55)
	await Cutscene.say([
		"Get the mallet. Break into the Hollow and find out where he's going. We'll keep Haven safe while you're gone.",
	], "Aladriel")
	if hime:
		Story._close_on(hime, 1.0, 2.6, 1.5)
		hime.cs_anim = &"laugh"
	await Cutscene.say(["And I shall... supervise! Ohohoho!"], HIMEKO)
	for n: Npc in [ala, idr, pink, hime]:
		if n:
			n.cs_anim = &""
	if _playing("shelter"):
		Cutscene.end()
