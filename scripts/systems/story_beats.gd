class_name StoryBeats
extends RefCounted
## Small scenes for story beats that used to pass without one (Beta 1.5.0):
## - vista(area):      the first time the hero comes into a great region, the
##                     camera rises behind him and looks out to where the
##                     story wants him (its dungeon's door), with a line
## - bun_piece(who):   a goddess's piece of the Bun taken: her voice, her
##                     light, and the road to the next piece (Serielye, alone
##                     of the three, shows herself, as she will at the end)

## area -> [the node to look at (a name, wildcards allowed), the line]
const VISTAS := {
	"lake": ["Door_lake_shrine", "*Mirror Lake*. Out on the water an old shrine stands half sunk, as if the lake had been waiting a long time for someone to come and open it."],
	"southern_fields": ["Door_southern_tower", "The *Southern Fields*: windmills, barley, and over it all the *Southern Tower*, Alan's tower, lights moving in its windows."],
	"desert": ["Door_ladhellin_tower", "The *Desert of Ladhellin*. Through the heat-shimmer, *Ladhellin Tower* stands alone in the sand. The wind round it sounds like moaning."],
	"snow": ["Door_skyreach_spire", "*Frostpeak*. High above the snowfields, *Skyreach Spire* climbs into the clouds. Somewhere at the top, the sky goddess's piece is waiting."],
	"marsh": ["Door_bog_tower", "The *West Marshlands*. Out in the reeds a tower leans, green with rot: the *Bog Tower*. Things croak in there that are not frogs."],
	"forest": ["To_hidden_forest", "*The Forest*. Somewhere beyond these trees, the old stories say, a hidden glade where a sword sleeps in a stone."],
	"cliffs": ["To_snow", "The *Northeastern Cliffs*. The path climbs and climbs, up toward the snows of Frostpeak."],
	"hidden_forest": ["BunPedestal*", "*The Hidden Forest*. Under a tree like a cathedral, a stone pedestal... and in it, a sword."],
}

const VOICES := {
	"alan": ["Alan", Color(0.5, 1.0, 0.55), [
		"Little knight. I am Alan, who makes the fields grow. I kept my piece of the Bun for the one who would need it.",
		"My sisters keep theirs: Serielye in her tower in the *desert*, Aphiel at the top of *Skyreach*, on Frostpeak. Gather all three, and the sword will answer you.",
	]],
	"aphiel": ["Aphiel", Color(0.55, 0.78, 1.0), [
		"You climbed all this way. I am Aphiel, of the sky and the winds. Take my piece, with my blessing.",
		"When the three are together, go to the *Hidden Forest*. The sword has slept long enough.",
		"But first, little knight: in the *West Marshlands* a rotten tower leans in the reeds. What it hides will carry you where a sword cannot. The *Bog Tower*. Do not leave it behind.",
	]],
}


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


## The first view of a great region (once: flag "vista:<area>").
static func vista(area: String) -> void:
	var v: Array = VISTAS.get(area, [])
	var p := GameManager.player
	if v.is_empty() or not is_instance_valid(p) or Progress.flag("vista:" + area) or Cutscene.active or not is_instance_valid(World.area_node):
		return
	var target := World.area_node.find_child(String(v[0]), true, false) as Node3D
	if target == null:
		return
	Progress.set_flag("vista:" + area)
	var id := "vista_" + area
	Cutscene.begin(false, [], id)
	var at := target.global_position + Vector3.UP * 4.0
	var back := p.global_position - target.global_position
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3(0, 0, 1)
	var side := Vector3(-back.z, 0, back.x)
	Cutscene.cut(p.global_position + back * 3.0 + side * 1.2 + Vector3.UP * 2.0, at, 52.0)
	Cutscene.glide(p.global_position + back * 1.0 + side * 2.0 + Vector3.UP * 6.0, at, 5.0, 44.0)
	await Cutscene.wait(1.4)
	if not _playing(id):
		return
	await Cutscene.say([String(v[1])])
	if _playing(id):
		Cutscene.end()


## A goddess's piece of the Bun taken (GetItem.present calls it after the box).
static func bun_piece(who: String) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Cutscene.active:
		return
	var id := "bun_voice_" + who
	Cutscene.begin(true, [], id)
	Story._close_on(p, 1.0, 2.6, 1.5)
	if who == "serielye":
		await _serielye_glimpse(p, id)
	else:
		var v: Array = VOICES.get(who, [])
		if v.is_empty():
			Cutscene.end()
			return
		Story._flash(Color(v[1], 0.6), 0.1, 1.2)
		Sfx.play("goddess_chime", -2.0, 0.0, 1.0 if who == "alan" else 1.2)
		var col := Story._light_column(p.global_position, Color(v[1], 0.25))
		await Cutscene.wait(0.8)
		await Cutscene.say(v[2], String(v[0]))
		if is_instance_valid(col):
			col.queue_free()
	if _playing(id):
		Cutscene.end()


## At Ladhellin Tower Serielye herself stands there a moment, in her own
## form: silver hair, a halo, a sword held low. She says very little.
static func _serielye_glimpse(p: PlayerController, id: String) -> void:
	var at := p.global_position + p.forward() * 4.0
	var s := Cutscene.actor("serielye", at, 0.0, &"idle")
	var mats: Array[StandardMaterial3D] = []
	if s:
		Cutscene.face(s, p.global_position)
		mats = VisionRealm.ghost(s, 0.2)
		VisionRealm.ghost_alpha(s, mats, 0.85, 1.2)
		Story._close_on(s, -1.0, 2.8, 1.7)
	Sfx.play("goddess_appear", -4.0, 0.0, 0.6)
	await Cutscene.wait(1.4)
	if not _playing(id):
		return
	if s:
		Cutscene.play(s, &"talk")
	await Cutscene.say([
		"...So. The line of the Nameless, again.",
		"Take it. You will need all three, and more besides, before the end. We will meet then, you and I.",
	], "Serielye", s)
	if s:
		VisionRealm.ghost_alpha(s, mats, 0.0, 1.0)
	await Cutscene.wait(1.1)
	var left := 3 - Progress.bun_piece_count()
	if left > 0:
		await Cutscene.say(["The goddess is gone, as if she had never been there. %s" % ("Aphiel's piece still waits at the top of *Skyreach Spire*, on Frostpeak." if not Progress.has_bun_piece("aphiel") else "Alan's piece still waits in the *Southern Tower*.")])


## Out of the Lake Shrine for the first time: the first trial done, and the
## road to the goddesses' towers.
static func lake_done() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch1:lake_told"):
		return
	Cutscene.begin(false, [], "lake_done")
	Progress.set_flag("ch1:lake_told")
	Cutscene.cut(p.global_position + Vector3(3.0, 2.4, 4.0), p.global_position + Vector3.UP * 1.2, 50.0)
	Cutscene.glide(p.global_position + Vector3(6.0, 6.0, 9.0), p.global_position + Vector3(-10, 2, -10), 5.0, 56.0)
	Sfx.play("goddess_chime", -6.0, 0.0, 1.1)
	await Cutscene.wait(1.0)
	if not _playing("lake_done"):
		return
	await Cutscene.say([
		"Behind you the shrine's old light goes out, and Mirror Lake lies quiet and clear, the way it must have been long ago.",
		"The legend Pip spoke of needs the three goddesses' pieces of the Bun. The nearest of their towers is *Alan's*, in the *Southern Fields*, just west of Haven Village.",
	])
	if _playing("lake_done"):
		Cutscene.end()


## The first morning after the true ending, at home (the post-game).
static func peace_morning() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("postgame:woke") or not Progress.flag("game_complete"):
		return
	Cutscene.begin(false, [], "peace_morning")
	Progress.set_flag("postgame:woke")
	Cutscene.cut(p.global_position + Vector3(2.2, 1.6, 2.6), p.global_position + Vector3.UP * 1.2, 50.0)
	await Cutscene.wait(0.6)
	Sfx.play("rooster", -2.0, 0.0)
	await Cutscene.wait(1.2)
	if not _playing("peace_morning"):
		return
	await Cutscene.say([
		"*Sir Gigglebuns IV* wakes in his own bed, to birdsong and the smell of somebody's baking.",
		"No summons on the table. No smoke on the horizon. The sky over Bunsriel is whole.",
		"Every road is still open: friends to visit, treasures still buried, fish still uncaught. And they say the band at the Golden Bun has a new song.",
	])
	if _playing("peace_morning"):
		Cutscene.end()
