class_name StoryChapter4
extends RefCounted
## Chapter IV, "The Fall of Bunsriel" (Beta 1.2.0, Saga IV Arc II). Played
## through Story's wrappers:
## - war_begins():     after Ottilie reads the Dark Prophecy (END OF CHAPTER
##                     III): the Chapter IV card, then a guard runs into the
##                     library: Northwatch is burning ("ch4:war")
## - eastgate_falls(): the third war camp broken, the east beacon goes out
##                     ("ch4:eastgate_fallen"); the horde marches on Haven
## - siege_begins(s), siege_break(n), siege_won(s): the Siege of Haven (Siege)
## - westmarch_fall(): Grukk beaten, Firebuns' fire falls on Westmarch; the
##                     Questlords bring the hero home ("ch4:westmarch_fallen"),
##                     then despair() in the refuge: the hero remembers the
##                     grove ("ch4:despair", "ch4:grove_known")
## - grove_arrive():   the sacred grove in the Dark Forest ("ch4:grove_seen")
## - temple_heart():   past the Pedestal Guardian: the old pedestal, Firebuns
##                     II's ghost, the sword awakens, Lothelye's Astral Seal
##                     ("ch4:sword_awake", "ch4:astral_seal")
## - citadel_roof():   Firebuns III on the burning throne-room roof
## - sealing(fb):      beaten, he is sealed in ice and sent to the Astral
##                     Dimension ("ch4:sealed"), then the peace and END OF
##                     CHAPTER IV ("ch4:peace")

const FIREBUNS := "Firebuns III"
const ROWENA := "Captain Rowena"
const LOTHELYE := "Lothelye"
const GHOST := "Firebuns II"


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


# --- The war begins ------------------------------------------------------------------

## In the library, after the END OF CHAPTER III card: the Chapter IV card,
## then a soldier of the Haven Guard with the news.
static func war_begins() -> void:
	if Progress.flag("ch4:war"):
		return
	Cutscene.begin(false, [], "war_begins")
	await Story.chapter_card(4)
	Progress.set_flag("ch4:war")
	var p := GameManager.player
	if not is_instance_valid(p):
		Cutscene.end()
		return
	var door := p.global_position + p.forward() * -6.0
	var guard := Cutscene.actor("haven_soldier", door, p.facing_yaw, &"idle")
	Cutscene.cut(p.global_position + Vector3(3.0, 2.2, 3.0), p.global_position + Vector3.UP * 1.2, 50.0)
	await Story._black(0.0, 0.8)
	Sfx.play("door_open", -2.0, 0.0)
	if guard:
		await Cutscene.walk(guard, p.global_position - p.forward() * -1.8, 4.0, &"talk")
		Cutscene.face(guard, p.global_position)
		Story._close_on(guard, 1.0, 2.4, 1.5)
	await Cutscene.say([
		"Sir Gigglebuns! The captain sent me, she said you'd be here... *Northwatch is burning!*",
		"The beacon went out an hour ago. Goblins, thousands of them, pouring over the field. The farms are emptying into Haven.",
		"Captain Rowena's taking command in the village. She asks for you. Please. Hurry!",
	], "Haven Guard", guard)
	if guard:
		await Cutscene.walk(guard, door, 4.5, &"talk")
	Cutscene.end()
	Story._clear_overlay()


# --- Eastgate falls ----------------------------------------------------------------

## The last war camp broken: far to the east, Eastgate's beacon flares and
## dies. They're coming for Haven.
static func eastgate_falls() -> void:
	if Progress.flag("ch4:eastgate_fallen"):
		return
	while Cutscene.active or Dialogue.active:
		await Cutscene.wait(0.2)
	var p := GameManager.player
	if not is_instance_valid(p):
		Progress.set_flag("ch4:eastgate_fallen")
		return
	Cutscene.begin(true, [], "eastgate_falls")
	var at := p.global_position
	Cutscene.cut(at + Vector3(-2.0, 2.2, 3.0), at + Vector3(60.0, 8.0, -20.0), 55.0)
	await Cutscene.wait(0.8)
	var beacon := at + Vector3(90.0, 14.0, -30.0)
	Story._burst(beacon, Color(1.0, 0.6, 0.25), 5.0)
	Sfx.play("beacon_flare", 0.0, 0.0)
	await Cutscene.wait(1.2)
	Story._flash(Color(1.0, 0.5, 0.2, 0.5), 0.1, 0.8)
	await Cutscene.say([
		"Far to the east, a beacon flares on the horizon... then gutters, and goes out.",
		"*Eastgate* has fallen. Two of the Citadel's three fortresses are dark.",
	])
	Sfx.play("war_horn", 0.0, 0.0)
	await Cutscene.say(["A war horn sounds across the field, and then another, and another. They are turning toward *Haven Village*."])
	await Cutscene.say(["Hurry back to Haven Village! The horde will be at its wall by nightfall."])
	Progress.set_flag("ch4:eastgate_fallen")
	if DayNight.hour() < 15.0 and not DayNight.is_night():
		DayNight.set_hour(17.0)
	Cutscene.end()


# --- The Siege of Haven ------------------------------------------------------------

static func siege_begins(siege: Node) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	Cutscene.begin(true, [], "siege_begins")
	var cam := Story._spot("cs_siege_cam", Vector3(0, 9, -26))
	var field := Story._spot("cs_siege_field", Vector3(0, 1, -70))
	Cutscene.cut(cam.global_position, field.global_position, 60.0)
	for i in 6:
		Story._flames(field.global_position + Vector3(-25.0 + i * 10.0, 0.0, randf_range(-6.0, 6.0)), 0.8, i % 2 == 0)
	Sfx.play("war_horn", 0.0, 0.0)
	await Cutscene.wait(1.4)
	await Cutscene.say(["Night has fallen over Haven Village. Out on the dark slope below the wall, a thousand torches."])
	var rowena := World.area_node.find_child("Captain Rowena", true, false) as Npc if is_instance_valid(World.area_node) else null
	if rowena:
		Story._close_on(rowena, 1.0, 2.4, 1.6)
		rowena.cs_anim = &"talk"
	await Cutscene.say([
		"Here they come. Guard, to the wall! Archers on the gatehouse!",
		"Sir Gigglebuns: ladders will come up the palisade. Cut their ropes from inside before they get a foothold.",
		"When the siege towers roll up, take the *ballista* on the gatehouse. Up the stair, behind the gate.",
		"Aladriel holds the east wall, Idrith the west. Haven stands or falls tonight. Let's make it stand.",
	], ROWENA, rowena)
	if rowena:
		rowena.cs_anim = &""
	# She gave him his orders in person, so they've met (the journal's first
	# Chapter IV step, when the camps were broken before she was found).
	Progress.set_flag("ch4:captain_met")
	Cutscene.end()


## Between waves: a word from the wall.
static func siege_break(wave: int) -> void:
	var lines := {
		1: ["The ladders are down! But listen... wheels. *Siege towers*, and boars at the gate. Man the ballista!"],
		2: ["The towers are burning! They'll come at us with everything now. Hold!"],
		3: ["...Do you see that? Blue fire, over the wall. The *battle-mage* from Eastgate. It's coming in itself!"],
	}
	if not lines.has(wave):
		return
	Dialogue.start([{"text": String(lines[wave][0]), "name": ROWENA}], null)
	await Dialogue.finished
	Dialogue.start([{"text": "The horde regroups. Mend the gate's loose planks with the *Iron Mallet* while you can!", "instant": true}], null)


static func siege_won(_siege: Node) -> void:
	var p := GameManager.player
	Cutscene.begin(true, [], "siege_won")
	World.play_track("")
	await Story._black(1.0, 1.0)
	DayNight.set_hour(6.0)
	await Cutscene.wait(0.5)
	if is_instance_valid(p):
		var spot := Story._spot("cs_rowena", p.global_position)
		p.global_position = spot.global_position + Vector3(0, 0.2, -2.5)
		p.face_direction(Vector3(0, 0, 1))
	var cam := Story._spot("cs_siege_cam", Vector3(0, 9, -26))
	Cutscene.cut(cam.global_position + Vector3(0, -4.0, 6.0), cam.global_position + Vector3(0, -6.0, -20.0), 55.0)
	await Story._black(0.0, 1.2)
	Sfx.play("rooster", -6.0, 0.0)
	await Cutscene.say(["Dawn comes up gray over Haven Village. The wall still stands."])
	var rowena := World.area_node.find_child("Captain Rowena", true, false) as Npc if is_instance_valid(World.area_node) else null
	if rowena:
		Story._close_on(rowena, 1.0, 2.4, 1.6)
		rowena.cs_anim = &"happy"
	await Cutscene.say([
		"We held. We actually held. ...Somebody write that down.",
	], ROWENA, rowena)
	if rowena:
		rowena.cs_anim = &"talk"
	await Cutscene.say([
		"That mage got away, though. Blinked out over the wall, heading *west*. Toward *Westmarch*, the last fortress standing.",
		"Aladriel and Idrith have already ridden after it. They said to tell you: the west hills, past the marshes road. Westmarch can't fall too.",
	], ROWENA, rowena)
	if rowena:
		rowena.cs_anim = &""
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))


# --- Westmarch falls ---------------------------------------------------------------

static func westmarch_fall() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch4:westmarch_fallen"):
		return
	Cutscene.begin(true, [], "westmarch_fall")
	World.play_track("")
	var hero := Story._spot("cs_wm_hero", p.global_position)
	p.global_position = hero.global_position
	var cam := Story._spot("cs_wm_cam", p.global_position + Vector3(6, 4, 6))
	Cutscene.cut(cam.global_position, p.global_position + Vector3(0, 6.0, -10.0), 60.0)
	Sfx.play("firebuns_laugh", -2.0, 0.0)
	await Cutscene.say(["...Little knight. You saved the village. How noble."], FIREBUNS, null)
	await Cutscene.say(["A voice from the burning sky. Firebuns III is nowhere, and everywhere at once: every flame on the roof leans toward you and speaks with his voice."])
	await Cutscene.say(["But I did tell you. *Watch it burn.*"], FIREBUNS, null)
	Story._flash(Color(1.0, 0.5, 0.2, 0.9), 0.15, 1.2)
	Cutscene.shake(0.2, 2.5)
	Sfx.play("fire_whoosh", 0.0, 0.0, 0.6)
	for i in 10:
		var a := TAU * i / 10.0
		Story._flames(p.global_position + Vector3(cos(a) * 9.0, 0.0, sin(a) * 9.0), 1.6, i % 3 == 0)
		await Cutscene.wait(0.08)
	var ala := Cutscene.actor("aladriel", p.global_position + Vector3(5.0, 0, 3.0), PI * 0.75, &"stand")
	var idr := Cutscene.actor("idrith", p.global_position + Vector3(6.0, 0, 1.5), PI * 0.75, &"stand")
	if ala:
		Cutscene.face(ala, p.global_position)
		Story._close_on(ala, 1.0, 2.6, 1.5)
	await Cutscene.say(["The keep's on fire from the cellars to the roof! Knight, it's lost. Westmarch is lost. *Out, now!*"], "Aladriel", ala)
	if idr:
		Story._close_on(idr, -1.0, 2.4, 1.45)
	await Cutscene.say(["The garrison's out. Everyone's out. P-please, come on!"], "Idrith", idr)
	Progress.set_flag("ch4:westmarch_fallen")
	await World.cutscene_load("village_refuge", "from_field", false, true)
	await despair()


## In the refuge: three fortresses fallen, and no hope left. The hero
## remembers the prophecy's last line, and the grove.
static func despair() -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		Cutscene.end()
		return
	Cutscene.begin(false, [], "despair")
	Progress.set_flag("ch4:despair")
	World.play_track("haven_refuge")
	var spot := p.global_position + p.forward() * 8.0
	var ala := Cutscene.actor("aladriel", spot + Vector3(-1.0, 0, 0), 0.0, &"stand")
	var idr := Cutscene.actor("idrith", spot + Vector3(1.0, 0, 0), 0.0, &"weary")
	if ala:
		Cutscene.face(ala, p.global_position)
	if idr:
		Cutscene.face(idr, p.global_position)
	Cutscene.cut(p.global_position + Vector3(4.0, 3.0, 4.0), spot + Vector3.UP * 1.2, 55.0)
	await Cutscene.say([
		"Westmarch burns behind them on the hills, a red smear on the sky. All three fortresses of the Citadel of Haven have fallen.",
		"In the refuge, nobody speaks above a whisper. Some of the refugees have started packing. To go where, nobody can say.",
	])
	await Cutscene.say(["Three fortresses. Not one left. It's just like the prophecy said."], "Aladriel", ala)
	await Cutscene.say(["*\"And the people shall lose all hope...\"*"], "Idrith", idr)
	Cutscene.cut(p.global_position + p.forward() * 2.2 + Vector3.UP * 1.6, p.global_position + Vector3.UP * 1.5, 45.0)
	await Cutscene.say(["...*save one, who remembers the grove in the Dark Forest, where the sleeping sword waits for a heart that is pure.*", "You remember. The Bun Sword was drawn, but it never woke. It is waiting in the grove of the *Dark Forest*, south of the desert of Ladhellin."])
	if ala:
		Story._close_on(ala, 1.0, 2.6, 1.5)
	await Cutscene.say([
		"The Dark Forest? Nobody's found the grove in a hundred years. The old priests' road into it was buried when the temple was abandoned.",
		"Buried... Then we need someone who knows how to dig. Properly. Respectfully. Like a gravekeeper.",
	], "Aladriel", ala)
	if idr:
		Story._close_on(idr, -1.0, 2.4, 1.45)
	await Cutscene.say(["*Wren!* The gravekeeper in Ashwick, in the Fells! She said she had a spade older than the Keep!"], "Idrith", idr)
	Progress.set_flag("ch4:grove_known")
	Sfx.play("secret", -2.0, 0.0)
	await Cutscene.say(["The brambles that choked the way south into the *Dark Forest* will not stop someone who knows where they are going."])
	Cutscene.end()


# --- The Dark Forest and the Temple of Bun ---------------------------------------------

static func grove_arrive() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch4:grove_seen"):
		return
	Cutscene.begin(false, [], "grove_arrive")
	Progress.set_flag("ch4:grove_seen")
	var cam := Story._spot("cs_grove_cam", p.global_position + Vector3(-6, 4, -6))
	Cutscene.cut(cam.global_position, p.global_position + Vector3(12.0, 3.0, 4.0), 60.0)
	Sfx.play("goddess_chime", -6.0, 0.0)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"The trees open onto a grove where the air is clear and still and smells of rain. White flowers. An old, old tree. A broken ring of standing stones.",
		"This is the place. The *sacred grove*. And before the great tree, the earth is soft and dark, as if something lies just beneath it.",
	])
	if not Progress.has_item("grave_spade"):
		await Cutscene.say(["You'll need something to dig with."])
	Cutscene.end()


## The temple's heart: the old pedestal. The hero lays the Bun Sword on it
## and takes it up again, and it wakes.
static func temple_heart() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch4:sword_awake"):
		return
	Cutscene.begin(true, [], "temple_heart")
	World.play_track("")
	var ped := Story._spot("cs_heart_pedestal", p.global_position + Vector3(0, 0.6, -7))
	var hero := Story._spot("cs_heart_hero", p.global_position)
	p.global_position = hero.global_position
	p.face_direction(Vector3(0, 0, -1))
	var cam := Story._spot("cs_heart_cam", p.global_position + Vector3(6, 3, 2))
	Cutscene.cut(cam.global_position, ped.global_position + Vector3.UP * 1.2, 50.0)
	await Cutscene.wait(1.0)
	await Cutscene.say(["In the temple's heart stands the old pedestal, empty, a slot of gold cut into it the shape of a blade."])
	# The ghost of Firebuns II.
	var ghost := Cutscene.actor("firebuns", ped.global_position + Vector3(2.4, -0.6, 1.0), -PI * 0.6, &"idle")
	if ghost and ghost.has_method("set_tint"):
		ghost.call("set_tint", Color(0.55, 0.75, 1.5))
	Sfx.play("goddess_appear", -6.0, 0.0, 0.8)
	if ghost:
		Story._burst(ghost.global_position + Vector3.UP * 1.0, Color(0.6, 0.75, 1.0), 2.0)
		Cutscene.face(ghost, p.global_position)
		Story._close_on(ghost, -1.0, 3.0, 1.9)
	await Cutscene.say([
		"Don't be afraid. I know whose face I wear. I am not him.",
		"I was *Firebuns II*. He is my son. The last time a Gigglebuns came to this grove, I walked beside him.",
	], GHOST, ghost)
	await Cutscene.say([
		"You met your own shadow below, and when it knelt, you did not strike it. That is the trial. That is what the sword waits for.",
		"Listen, knight. The Gauntlet commands every flame in Bunsriel. But there are two things no flame can touch: *ice*, and *starlight*.",
		"My son will not die by any sword. But he can be *held*. Go now. Wake the blade.",
	], GHOST, ghost)
	if ghost:
		var gt := ghost.create_tween()
		gt.tween_property(ghost, "scale", Vector3.ONE * 0.02, 1.2)
		gt.tween_callback(ghost.queue_free)
	# The sword laid on the pedestal, and taken up again.
	Cutscene.cut(p.global_position + Vector3(2.2, 1.8, 2.0), ped.global_position + Vector3.UP * 1.0, 45.0)
	await Cutscene.walk(p, ped.global_position + Vector3(0, -0.6, 1.4), 1.5)
	Cutscene.play(p, &"item_get")
	Sfx.play("goddess_chime", -2.0, 0.0)
	await Cutscene.wait(1.0)
	Story._flash(Color(0.85, 0.9, 1.0, 1.0), 0.2, 1.6)
	Cutscene.shake(0.08, 1.2)
	Progress.set_flag(Progress.SWORD_AWAKE)
	Progress.gear_changed.emit()
	Story._burst(ped.global_position + Vector3.UP * 1.4, Color(0.8, 0.88, 1.0), 4.0)
	await Cutscene.say([
		"The Bun Sword blazes with starlight in your hands, and its blade turns a shining rose-pink. It is *awake*.",
		"*Bun Sword (Awakened)*: it cuts harder, and its beam of starlight flies at any health, putting out the Order's wards wherever it strikes.",
	])
	# Lothelye, and the Astral Seal.
	var lothelye := Cutscene.actor("lothelye", ped.global_position + Vector3(0, -0.6, -2.0), 0.0, &"bless")
	Sfx.play("goddess_appear", -2.0, 0.0)
	if lothelye:
		Cutscene.face(lothelye, p.global_position)
		Story._burst(lothelye.global_position + Vector3.UP * 1.2, Color(0.85, 0.85, 1.0), 3.0)
		Story._close_on(lothelye, 1.0, 3.0, 1.7)
	await Cutscene.say([
		"Gigglebuns. Child of my dream. You did not strike the one who knelt.",
		"Long ago I made a dimension of stars to hold what must not be loosed on Bunsriel. Take this: a piece of it, a crystal of the *Astral Dimension*.",
		"When the burning king falls, it will hold him. Ice and starlight. Go to the Citadel. It is burning, and he is waiting on its roof.",
	], LOTHELYE, lothelye)
	Cutscene.end()
	await GetItem.present(p, "astral_seal")
	World.play_track(WorldData.music(World.area_id))


# --- The burning Citadel ---------------------------------------------------------------

static func _firebuns() -> Node3D:
	for b in GameManager.player.get_tree().get_nodes_in_group("bosses"):
		if b.has_method("wake") and b.get("sealing") == true:
			return b
	return null


static func citadel_roof() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch4:roof_seen"):
		var fb0 := _firebuns()
		if fb0:
			fb0.call("wake")
		return
	var fb := _firebuns()
	if fb == null:
		return
	Cutscene.begin(true, [fb], "citadel_roof")
	Progress.set_flag("ch4:roof_seen")
	var cam := Story._spot("cs_roof_cam", p.global_position + Vector3(5, 3, -4))
	Cutscene.cut(cam.global_position, fb.global_position + Vector3.UP * 1.6, 55.0)
	await Cutscene.wait(1.0)
	await Cutscene.say(["You came. Of course you came. Look at it, little knight. *Look.* The Citadel of Haven, burning to the ground. Just as it was written."], FIREBUNS, null)
	Story._close_on(fb, 1.0, 3.2, 1.9)
	(fb.get("model") as CharacterModel).play(&"talk", 0.3)
	await Cutscene.say([
		"I had a father who died a hero. I had a people who poisoned me. And I had a deal with something that does not die.",
		"...That sword. It's awake now. I can feel it from here. Like a cold wind.",
	], FIREBUNS)
	(fb.get("model") as CharacterModel).play(&"raise", 0.2)
	Story._gauntlet(fb, true)
	Sfx.play("fire_whoosh", 0.0, 0.0)
	await Cutscene.say(["It doesn't matter. *Every flame in Bunsriel* stands between you and me!"], FIREBUNS)
	Cutscene.end()
	fb.call("wake")
	await Cutscene.wait(0.1)
	Dialogue.start([{"text": "A wall of fire wraps Firebuns III. No blade can touch him through it... but no flame can touch starlight.", "instant": true}], null)


## firebuns_sealed.ogg's moments in seconds (make_firebuns_sealed_midi.py,
## bar times from bar_times.py): A, the flame failing, bars 1-6 (the seal
## raised at bar 4); B, the ice, bars 7-12; C, peace, from bar 13 (the strings
## from bar 17); the last chord ends at 77.2 s.
const SEALED_CUES := {
	"flame": 1.0, "seal": 10.61, "ice": 23.27, "closes": 33.0, "rise": 43.27, "peace": 47.27,
	"strings": 61.81, "fade": 69.09, "end": 77.24,
}


## He falls to his knees, and the Astral Seal takes him.
static func sealing(fb: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	World.play_track("")
	Cutscene.begin(true, [fb], "sealing")
	# The whole scene runs on firebuns_sealed.ogg's clock (Beta 1.6.1;
	# SEALED_CUES): the flame failing, the ice, and peace, and the words go
	# on by themselves.
	Story.start_score("firebuns_sealed")
	var fbm := fb.get("model") as CharacterModel
	var to_hero := p.global_position - fb.global_position
	to_hero.y = 0.0
	to_hero = to_hero.normalized() if to_hero.length() > 0.1 else Vector3(0, 0, 1)
	fb.set("facing_yaw", atan2(-to_hero.x, -to_hero.z))
	fb.rotation.y = atan2(-to_hero.x, -to_hero.z)
	p.face_direction(-to_hero)
	Story._gauntlet(fb, false)
	if fbm:
		fbm.play(&"stagger", 0.1)
	Story._close_on(fb, 1.0, 3.2, 1.6)
	# A (bars 1-6): his figure slows and loses its fire.
	await Story.say_window(["No... no. The flame... it won't answer. *Why won't it answer?*"], SEALED_CUES.flame, SEALED_CUES.seal - 0.3, FIREBUNS)
	await Story._at_time(SEALED_CUES.seal)
	Cutscene.cut(p.global_position - to_hero * 2.4 + Vector3(-to_hero.z, 0, to_hero.x) * 1.2 + Vector3.UP * 1.4, p.global_position + Vector3.UP * 1.6, 50.0)
	Cutscene.play(p, &"item_get")
	var seal := MeshInstance3D.new()
	seal.mesh = load("res://assets/models/astral_seal_mesh.tres")
	seal.scale = Vector3.ONE * 2.2
	p.add_child(seal)
	seal.position = Vector3(0, 2.3, 0)
	Sfx.play("goddess_chime", 0.0, 0.0)
	await Story.say_window(["The *Astral Seal* blazes in your raised hands, cold as the space between the stars."], SEALED_CUES.seal + 0.6, SEALED_CUES.ice - 0.3)
	# B (bars 7-12): the ice, celesta and glass and choir.
	await Story._at_time(SEALED_CUES.ice)
	Cutscene.cut(fb.global_position + to_hero * 6.0 + Vector3.UP * 2.0 + Vector3(-to_hero.z, 0, to_hero.x) * 2.5, fb.global_position + Vector3.UP * 1.6, 55.0)
	Story._flash(Color(0.75, 0.88, 1.0, 1.0), 0.2, 1.2)
	Sfx.play("ice_freeze", 2.0, 0.0, 0.6)
	var ice := MeshInstance3D.new()
	ice.mesh = load("res://assets/models/ice_prison_mesh.tres")
	World.area_node.add_child(ice)
	ice.global_position = fb.global_position
	ice.scale = Vector3(0.1, 0.1, 0.1)
	var it := ice.create_tween()
	it.tween_property(ice, "scale", Vector3.ONE * 1.1, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await it.finished
	if fb.has_method("daze"):
		fb.call("daze", 30.0, true)
	if is_instance_valid(seal):
		seal.queue_free()
	await Story.say_window(["...You... haven't won... It is... *waiting*... for me..."], SEALED_CUES.ice + 1.6, SEALED_CUES.closes - 0.3, FIREBUNS)
	await Story.say_window(["Ice closes over the burning king, and over the Gauntlet of Fire on his fist. Its flame goes out."], SEALED_CUES.closes, SEALED_CUES.rise - 0.3)
	# Up into the stars, as the ice section ends.
	await Story._at_time(SEALED_CUES.rise)
	Cutscene.cut(fb.global_position + to_hero * 9.0 + Vector3.UP * 1.0, fb.global_position + Vector3.UP * 6.0, 65.0)
	Sfx.play("warp_wind", 0.0, 0.0, 0.7)
	var up := ice.create_tween().set_parallel(true)
	up.tween_property(ice, "global_position", ice.global_position + Vector3.UP * 40.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	up.tween_property(fb, "global_position", fb.global_position + Vector3.UP * 40.0, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# C (bar 13): peace, the hero's motif in E major on the horn.
	await Story._at_time(SEALED_CUES.peace)
	Story._flash(Color(1, 1, 1, 1), 0.4, 1.6)
	if is_instance_valid(ice):
		ice.queue_free()
	if is_instance_valid(fb):
		fb.queue_free()
	Progress.set_flag("ch4:sealed")
	# The fires on the roof go out one by one.
	if is_instance_valid(World.area_node):
		for n in World.area_node.find_children("Fire*", "Node3D", true, false):
			(n as Node3D).visible = false
	Story._tint_area(Color(0.6, 0.7, 1.0), 3.0)
	await Story.say_window([
		"Firebuns III is gone, sealed in a block of ice and carried away into the *Astral Dimension*, where he can never harm Bunsriel again.",
	], SEALED_CUES.peace + 1.4, SEALED_CUES.strings - 0.3)
	# The strings take the motif; the picture goes with the last chord.
	await Story._at_time(SEALED_CUES.fade)
	await Story._black(1.0, SEALED_CUES.end - SEALED_CUES.fade)
	Story.stop_score()
	await peace_ending()


## Over black: what became of Bunsriel, END OF CHAPTER IV, the save, and
## home in Haven Village at peace.
static func peace_ending() -> void:
	var o: Object = Story._ensure_overlay()
	await Story._black(1.0, 1.4)
	# Over ending.ogg, its pages on the music's bars (Story.ENDING_PAGE_CUES).
	Story.start_score("ending")
	await Story.pages_on_cues([
		["THE CITADEL'S FIRES DIED BY MORNING.", "THE GOBLIN HORDES SCATTERED TO THE HILLS."],
		["THE PEOPLE OF HAVEN CAME HOME,", "AND BEGAN TO BUILD AGAIN."],
		["AND ASHWICK'S SURVIVORS WERE INVITED", "TO LIVE IN HAVEN, AS NEIGHBORS."],
		["THOUGH PEACE WOULD NOT", "LAST FOREVER..."],
	])
	await Story.chapter_card(4, true)
	Story.stop_score()
	Progress.set_flag("ch4:peace")
	if Cutscene.active:
		Cutscene.end()
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = false
		p.begin_cutscene()
	if not Story.viewing:
		Dialogue.start([{"text": "Your journey will continue... Save your progress?", "choices": [["Save", []], ["Don't save", []]]}])
		await Dialogue.finished
	if not Story.viewing and Dialogue.last_choice == "Save":
		Story._save_after_ending()
		Dialogue.start(["Your game has been saved. When you continue, you'll wake up at home in *Haven Village*, at peace."])
		await Dialogue.finished
	await Cutscene.wait(0.5)
	Story._clear_overlay()
	if Story.end_to_title:
		GameManager.return_to_title()
