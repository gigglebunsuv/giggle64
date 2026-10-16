class_name StoryFinal
extends RefCounted
## The end of Chapter V and of the game (Beta 1.5.0, "The Astral Rift"),
## played through Story's wrappers:
## - rift_seen():          back on the Ridge after Mara: the crack in the sky,
##                         and Rowena's news of the Order in the Fells
##                         ("ch5:rift_seen")
## - velloran_stand():     the Order's last stand round the ritual circle in
##                         the Sanctum Ruin ("ch5:velloran_met")
## - velloran_falls(v):    Velloran beaten; his last words; Lothelye calls
##                         the hero to her spring ("ch5:velloran_done")
## - dream_gift():         Lothelye at her spring in the marshes gives her
##                         last gift, LOTHELYE'S DREAM ("ch5:dream")
## - rift_open():          the cracked Astral Seal raised under the crack at
##                         the top of the Ridge: the way in opens
##                         ("ch5:rift_open")
## - rift_arrive():        the first steps into the starless dark
##                         ("rift:arrived")
## - avalon_scene():       AVALON, Keeper of the Stars, in her garden of light
##                         before the heart; scored to avalon.ogg (AVALON_CUES):
##                         she heals the hero and blesses the Bun Sword with
##                         the Luminous Blade's starlight ("rift:blessed")
## - rift_heart():         Firebuns III beside his shattered prison
## - final_phase(fb, n):   the breath between the last battle's phases
## - final_blow(fb):       the last blow; Denangdyn's shadow reaches out;
##                         SERIELYE ends it; the hero does not raise his sword;
##                         then the ending (StoryEnding)

const ROWENA := "Commander Rowena"
const VELLORAN := "Archmagus Velloran"
const LOTHELYE := "Lothelye"
const AVALON := "Avalon"
const FIREBUNS := "Firebuns III"
const DENANGDYN := "???"
const SERIELYE := "Serielye"

## avalon.ogg's sections in seconds (avalon.mid, 72 bpm, 4/4: a bar is 3.33 s;
## from _giggle64_work/tools/bar_times.py make_avalon_midi.py):
##   intro 1-4, A 5-12 (her motif, D Lydian), A' 13-20 (A major), B 21-28
##   (the canon), B' 29-36 (her motif over the canon: the climax), coda 37-40.
const AVALON_CUES := {
	"intro": 0.0, "appear": 10.0, "a": 13.33, "a2": 40.0, "canon": 66.67,
	"heal": 80.0, "climax": 93.33, "coda": 120.0, "fade": 126.67, "end": 133.33,
}


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


static func _npc(npc_name: String) -> Node3D:
	if not is_instance_valid(World.area_node):
		return null
	return World.area_node.find_child(npc_name, true, false) as Node3D


static func _crack_at(p: PlayerController) -> Vector3:
	var m := Story._spot("cs_ridge_crack", p.global_position + Vector3(0, 40, -90))
	return m.global_position


# --- Black Water Ridge, after Mara ------------------------------------------------

static func rift_seen() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:rift_seen") or not Progress.flag("ch5:mara_done"):
		return
	Cutscene.begin(false, [], "rift_seen")
	Progress.set_flag("ch5:rift_seen")
	var crack := _crack_at(p)
	Cutscene.cut(p.global_position + Vector3(2.0, 1.4, 4.0), crack, 55.0)
	Cutscene.glide(p.global_position + Vector3(1.0, 2.4, 3.0), crack, 4.0, 45.0)
	await Cutscene.wait(1.2)
	await Cutscene.say([
		"Out of the Keep, the falls run clear and white. But high over the Ridge the sky is still split open, a long black wound with no stars in it.",
		"Now and then something moves behind it, slow and patient, like a fish under ice.",
	])
	var rowena := Cutscene.actor("rowena", p.global_position + p.forward() * 6.0 + Vector3(2.0, 0, 0), 0.0, &"walk")
	if rowena:
		Cutscene.face(rowena, p.global_position)
		await Cutscene.walk(rowena, p.global_position + p.forward() * 2.2 + Vector3(0.6, 0, 0), 2.6)
		Cutscene.face(rowena, p.global_position)
		Story._close_on(rowena, 1.0, 2.8, 1.6)
	await Cutscene.say([
		"You're alive. Good. The knights are already telling the story; it gets bigger every time.",
		"But we've got trouble. A scout from Ashwick rode in at dawn. The last of the *Sapphire Order* have dug in at the old chapel in the *Batela Fells*, where their Sanctum fell in.",
		"*Velloran* is with them. He cracked that seal in the first place. If anyone knows how to walk through that crack... or how to close it... it's him.",
		"Go *east*, to the *Batela Fells*. The crypt under the old chapel, west of Ashwick. I'll keep the Ridge. And Knight? Come back.",
	], ROWENA, rowena)
	Cutscene.end()


# --- The Sanctum Ruin --------------------------------------------------------------

static func velloran_stand() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:velloran_met"):
		return
	Cutscene.begin(true, [], "velloran_stand")
	Progress.set_flag("ch5:velloran_met")
	var at := Story._spot("cs_ruin_velloran", p.global_position + Vector3(0, 0, -14)).global_position
	var v := World.area_node.find_child("Velloran*", true, false) as Node3D if is_instance_valid(World.area_node) else null
	var cam := Story._spot("cs_ruin_cam", at + Vector3(6, 3, 16)).global_position
	Cutscene.cut(cam, at + Vector3.UP * 2.0, 52.0)
	Cutscene.glide(cam + Vector3(-4, 1, -4), at + Vector3.UP * 2.0, 4.0, 46.0)
	Sfx.play("mage_cast", -6.0, 0.0, 0.6)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"Round a circle of blue fire, under the open gray sky, the last of the Sapphire Order chant the same words over and over. Above the circle, the crack in the sky seems very close.",
	])
	if is_instance_valid(v):
		Cutscene.face(v, p.global_position)
		Story._close_on(v, -1.0, 3.2, 2.4)
	await Cutscene.say([
		"...and the door opens from both sides. *So it is written.* So it was always written.",
		"Ah. The Knight. You keep arriving at the end of things, don't you? Westmarch. The Citadel. And now here.",
		"Look at it, Knight. The crack in the sky. Our Lord waited a thousand years behind that seal. Firebuns was only ever the hammer we struck it with.",
		"The hammer has gone through the hole now. And I mean to hold the door open until our Lord walks out of it.",
	], VELLORAN, v)
	if is_instance_valid(v):
		Cutscene.play(v, &"cast")
	Sfx.play("ward_out", 0.0, 0.0, 0.5)
	Story._flash(Color(0.45, 0.55, 1.0, 0.8), 0.1, 0.8)
	await Cutscene.say([
		"A ward of blue fire closes round the Archmagus. Steel would only ring off it... but the Order's fire has always feared one light.",
	])
	Cutscene.end()


static func velloran_falls(v: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:velloran_done"):
		return
	Cutscene.begin(true, [v] if is_instance_valid(v) else [], "velloran_falls")
	World.play_track("")
	var at := v.global_position if is_instance_valid(v) else p.global_position + p.forward() * 4.0
	if is_instance_valid(v):
		Cutscene.face(v, p.global_position)
		Story._close_on(v, 1.0, 3.0, 1.5)
	await Cutscene.wait(0.8)
	await Cutscene.say([
		"Velloran sinks to his knees. His staff cracks across, and the blue fire round the circle gutters out one flame at a time.",
	])
	await Cutscene.say([
		"...Ha. Lothelye's light. Of course. It was always going to be her light.",
		"You think this ends it? The door is open, Knight. It does not need me to stay open.",
		"And you cannot follow. No living thing walks the astral way. Only the dead... and the dreaming...",
		"...Our Lord will be so... disappointed in me.",
	], VELLORAN, v)
	if is_instance_valid(v):
		Fragments.burst(v.get_parent(), load("res://assets/models/shard_mesh.tres"), at + Vector3.UP * 1.2, 26, 3.0, 4.0, 1.2, 1.2, Color(1.3, 1.25, 1.0))
		Sfx.play("page_flutter", 0.0, 0.0, 0.8)
		var t := v.create_tween()
		t.tween_property(v, "scale", Vector3(0.05, 0.05, 0.05), 1.2)
		t.tween_callback(v.queue_free)
	await Cutscene.wait(1.4)
	await Cutscene.say([
		"The Archmagus comes apart like old paper in the wind, and his pages blow away over the ruin. The Sapphire Order is no more.",
	])
	Progress.set_flag("ch5:velloran_done")
	# Lothelye's voice, out of the starlight in the sword.
	p.model.set_starlight(true)
	Sfx.play("goddess_chime", -4.0, 0.0, 1.0)
	Story._close_on(p, 1.0, 2.4, 1.4)
	await Cutscene.wait(0.6)
	await Cutscene.say([
		"Knight of Haven. Can you hear me? It is Lothelye.",
		"He was right about one thing: the living cannot walk the astral way. But dreamers can. I made that world out of a dream, long ago.",
		"Come to my spring in the *West Marshlands*, on the islet in the reeds. I have one last gift for you.",
	], LOTHELYE)
	p.model.set_starlight(Progress.sword == "bun" and Progress.sword_awake())
	Cutscene.end()


# --- Lothelye's spring --------------------------------------------------------------

static func dream_gift() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:dream") or not Progress.flag("ch5:velloran_done"):
		return
	Cutscene.begin(false, [], "dream_gift")
	var pool := Vector3(0, -0.25, -3.5)
	p.global_position = Vector3(0, p.global_position.y, 2.6)
	p.face_direction(Vector3(0, 0, -1))
	Cutscene.cut(Vector3(3.5, 2.2, 5.5), pool + Vector3.UP * 1.6, 50.0)
	Sfx.play("goddess_appear", -2.0)
	await Cutscene.wait(0.8)
	var col := Story._light_column(pool, Color(0.85, 0.88, 1.0, 0.3))
	var l := Cutscene.actor("lothelye", pool + Vector3.UP * 0.4, 0.0, &"idle")
	if l:
		Cutscene.face(l, p.global_position)
		l.scale = Vector3.ONE * 0.05
		var t := l.create_tween()
		t.tween_property(l, "scale", Vector3.ONE, 1.4).set_trans(Tween.TRANS_SINE)
	await Cutscene.wait(1.6)
	if l:
		Story._close_on(l, -1.0, 3.2, 1.7)
		Cutscene.play(l, &"talk")
	await Cutscene.say([
		"You came. You always come, Knight. It is the best thing about you.",
		"Listen. When the Order cracked my seal, they made a door between your world and the Astral Dimension, the prison I made for the darkest things.",
		"The oldest thing in that prison is what is left of *Denangdyn*. It is only a shadow now. But a shadow can still reach through a crack, and pull a broken king through to it.",
		"Firebuns has gone to it. Every hour he stays there, the shadow grows into him, and the crack grows wider.",
	], LOTHELYE, l)
	if l:
		Cutscene.play(l, &"bless")
	Sfx.play("goddess_chime", -2.0, 0.0, 1.2)
	Story._flash(Color(0.85, 0.8, 1.0, 0.7), 0.1, 1.0)
	await Cutscene.wait(0.8)
	await Cutscene.say([
		"This is my *Dream*. While you hold it, the astral way will hold you. Where the dark is only dark, you will see the paths of dream-light I left there long ago.",
	], LOTHELYE, l)
	Cutscene.end(true)
	await GetItem.present(p, "lothelyes_dream")
	Progress.set_flag("ch5:dream")
	Cutscene.begin(false, [], "dream_gift_2")
	if l:
		Story._close_on(l, -1.0, 3.2, 1.7)
		Cutscene.play(l, &"talk")
	await Cutscene.say([
		"Go to the top of *Black Water Ridge*, beneath the crack in the sky. Raise the cracked *Astral Seal* there: it still remembers the way in.",
		"And when the dark is all around you, Knight... dream.",
	], LOTHELYE, l)
	if l:
		var t2 := l.create_tween()
		t2.tween_property(l, "scale", Vector3.ONE * 0.05, 1.0)
	if is_instance_valid(col):
		col.queue_free()
	await Cutscene.wait(1.0)
	for a in Cutscene.actors:
		if is_instance_valid(a):
			a.queue_free()
	Cutscene.actors.clear()
	Cutscene.end()


# --- The way in ----------------------------------------------------------------------

static func rift_open() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:rift_open") or not Progress.flag("ch5:dream"):
		return
	Cutscene.begin(true, [], "rift_open")
	var crack := _crack_at(p)
	var mouth := Story._spot("cs_rift_mouth", p.global_position + p.forward() * 6.0).global_position
	Cutscene.cut(p.global_position + Vector3(3.0, 1.6, 3.0), p.global_position + Vector3.UP * 1.4, 48.0)
	await Cutscene.wait(0.5)
	await Cutscene.say([
		"Under the crack, the cracked *Astral Seal* grows cold in your pack, then colder, then it is singing.",
	])
	Cutscene.play(p, &"item_get")
	Sfx.play("goddess_chime", 0.0, 0.0, 0.9)
	await Cutscene.wait(0.8)
	Cutscene.cut(mouth + Vector3(8.0, 4.0, 10.0), crack, 60.0)
	Cutscene.glide(mouth + Vector3(4.0, 2.0, 12.0), mouth + Vector3.UP * 4.0, 4.5, 50.0)
	Story._flash(Color(0.8, 0.75, 1.0, 0.8), 0.1, 1.2)
	Cutscene.shake(0.12, 2.0)
	Sfx.play("goddess_appear", -2.0, 0.0, 0.5)
	Progress.set_flag("ch5:rift_open")
	await Cutscene.wait(1.6)
	await Cutscene.say([
		"A beam of starless light falls from the crack to the ground, and in it the air tears open like a curtain: a doorway of dark, edged in pale violet.",
		"*The way into the Astral Rift is open.* Beyond it there is nothing at all... except, very far off, the sound of someone laughing.",
	])
	Cutscene.end()


static func rift_arrive() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("rift:arrived"):
		return
	Cutscene.begin(false, [], "rift_arrive")
	Progress.set_flag("rift:arrived")
	var hub := Story._spot("cs_rift_hub", p.global_position + Vector3(0, 0, -30)).global_position
	Cutscene.cut(p.global_position + Vector3(-3.0, 3.0, 5.0), hub, 58.0)
	Cutscene.glide(p.global_position + Vector3(-8.0, 10.0, 8.0), hub + Vector3(0, 6.0, -20.0), 6.0, 62.0)
	await Cutscene.wait(1.6)
	await Cutscene.say([
		"*The Astral Rift.* No sky, no ground, no stars. Only dark, and floating in it, pieces of every place you have ever been, torn loose and drifting.",
		"A lake shore. A tower's broken top. The burning halls of the Citadel. The Barrow's old stones. They hang in the dark like memories of a dream.",
		"Four star locks stand cold in the great hall ahead. Somewhere above them, Firebuns waits.",
	])
	await Cutscene.say([
		"Welcome, little knight. Come and see what I've become.",
	], FIREBUNS)
	Cutscene.end()


# --- Avalon ------------------------------------------------------------------------

## Avalon's garden of light, timed to her theme (AVALON_CUES): she gathers out
## of starlight as the intro ends, speaks through her motif, heals the hero as
## the canon starts, and on the climax touches the Luminous Blade to the Bun
## Sword. The boxes run on by themselves (Story.say_window).
static func avalon_scene() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("rift:blessed"):
		return
	Cutscene.begin(true, [], "avalon")
	World.play_track("")
	var c := AVALON_CUES
	var at := Story._spot("cs_avalon", p.global_position + p.forward() * 6.0).global_position
	var hero_at := Story._spot("cs_avalon_hero", at + Vector3(0, 0, 5.0)).global_position
	p.global_position = hero_at
	p.face_direction(at - hero_at)
	Story.start_score("avalon")
	# Intro: the light gathers.
	Cutscene.cut(hero_at + Vector3(-5.0, 2.0, 6.0), at + Vector3.UP * 1.5, 55.0)
	Cutscene.glide(hero_at + Vector3(-2.0, 1.6, 4.0), at + Vector3.UP * 1.5, c.appear - 0.5, 48.0)
	var col := Story._light_column(at, Color(0.75, 0.85, 1.0, 0.28))
	var motes := Story._vision_motes(at)
	await Story._at_time(c.appear)
	var av := Cutscene.actor("avalon", at, 0.0, &"idle")
	if av:
		Cutscene.face(av, hero_at)
		av.scale = Vector3.ONE * 0.05
		var t := av.create_tween()
		t.tween_property(av, "scale", Vector3.ONE, 2.6).set_trans(Tween.TRANS_SINE)
	Sfx.play("goddess_appear", -4.0, 0.0, 1.2)
	await Story._at_time(c.a)
	if av:
		Story._close_on(av, 1.0, 2.6, 1.6)
		Cutscene.play(av, &"talk")
	await Story.say_window([
		"Oh... you must be so tired. You have come such a long way through the dark.",
		"It's all right. Nothing can hurt you here. This little garden is mine, and the dark does not come in.",
		"I am *Avalon*. Some call me the Keeper of the Stars. I was born from the prayers of Bunsriel's people, every one they ever whispered to the night sky.",
	], c.a + 0.6, c.a2 - 0.4, AVALON, av)
	if av:
		Cutscene.glide(at + Vector3(2.6, 1.7, 2.8), at + Vector3.UP * 1.4, 6.0, 46.0)
	await Story.say_window([
		"Do you know, they are praying now? In Haven, in Ashwick, in the knights' tents on the Ridge. They light candles and look up, and say your name.",
		"Lothelye told me you would come. She said you were the kind of hero who keeps getting back up.",
		"I'm so glad she was right.",
	], c.a2 + 0.4, c.canon - 0.4, AVALON, av)
	# The canon: she heals him.
	await Story._at_time(c.canon)
	Cutscene.cut(hero_at + Vector3(3.0, 1.4, 1.5), (hero_at + at) * 0.5 + Vector3.UP * 1.3, 50.0)
	if av:
		Cutscene.play(av, &"bless")
	await Story.say_window([
		"What waits for you at the heart is not only Firebuns. The shadow of *Denangdyn* has crawled inside him. No blade of the living world can touch a shadow.",
	], c.canon + 0.6, c.heal - 0.3, AVALON, av)
	await Story._at_time(c.heal)
	Sfx.play("fairy_heal", 0.0, 0.0, 0.9)
	p.health.health = p.health.max_health
	p.health.health_changed.emit(p.health.health, p.health.max_health)
	Progress.magic = Progress.magic_max
	Progress.changed.emit()
	Fragments.burst(p.get_parent(), load("res://assets/models/leaf_mesh.tres"), p.global_position + Vector3.UP * 1.0, 20, 2.0, 3.0, 1.2, 1.2, Color(1.6, 1.7, 2.0))
	await Story.say_window([
		"There. Every wound closed, and your magic full. But a shadow needs more than a brave heart and a good sword.",
		"It needs starlight.",
	], c.heal + 0.5, c.climax - 0.3, AVALON, av)
	# The climax: the Luminous Blade touches the Bun Sword.
	await Story._at_time(c.climax)
	p.model.set_gear("bun_awake", Progress.shield)
	p.model.set_sword_drawn(true)
	Cutscene.play(p, &"item_get")
	Story._flash(Color(1.0, 1.0, 1.0, 0.95), 0.2, 1.6)
	Sfx.play("goddess_chime", 0.0, 0.0, 1.0)
	Cutscene.shake(0.05, 1.5)
	Progress.set_flag("rift:blessed")
	p.model.set_starlight(true)
	Cutscene.cut(hero_at + Vector3(1.8, 1.9, 2.2), hero_at + Vector3.UP * 1.6, 44.0)
	Cutscene.glide(hero_at + Vector3(-1.6, 2.4, 3.2), (hero_at + at) * 0.5 + Vector3.UP * 1.6, 8.0, 50.0)
	Fragments.burst(p.get_parent(), load("res://assets/models/shard_mesh.tres"), p.global_position + Vector3.UP * 1.8, 30, 3.0, 4.0, 1.4, 1.2, Color(1.8, 1.8, 2.2))
	await Story.say_window([
		"*The Luminous Blade's light passes into the Bun Sword.* Its old pink glow deepens, and through it runs a seam of pure white starlight.",
	], c.climax + 1.2, c.climax + 9.5)
	if av:
		Story._close_on(av, -1.0, 2.6, 1.6)
		Cutscene.play(av, &"talk")
	await Story.say_window([
		"Now it carries my light, and the hope of everyone who ever looked up at the stars and asked for help.",
		"When the shadow shows itself, strike it with this. It will not be able to bear it.",
		"And when it's over... go home, and rest. Promise me you'll rest.",
	], c.climax + 10.0, c.coda - 0.4, AVALON, av)
	# The coda: she smiles, and is starlight again.
	await Story._at_time(c.coda)
	if av:
		Cutscene.play(av, &"idle")
		Cutscene.glide(at + Vector3(0.0, 1.8, 3.6), at + Vector3.UP * 1.5, 6.0, 44.0)
	await Story.say_window(["Be brave, Knight of Haven. The stars are with you."], c.coda + 0.6, c.fade - 0.3, AVALON, av)
	await Story._at_time(c.fade)
	if av:
		var t2 := av.create_tween()
		t2.tween_property(av, "scale", Vector3.ONE * 0.05, 3.0).set_trans(Tween.TRANS_SINE)
		Fragments.burst(av.get_parent(), load("res://assets/models/shard_mesh.tres"), at + Vector3.UP * 1.4, 24, 2.0, 3.0, 2.0, 1.2, Color(1.6, 1.8, 2.2))
	Sfx.play("goddess_chime", -6.0, 0.0, 1.5)
	await Story._at_time(c.end - 1.0)
	if is_instance_valid(col):
		col.queue_free()
	if is_instance_valid(motes):
		motes.queue_free()
	Story.stop_score()
	p.model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	p.model.set_sword_drawn(false)
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))


# --- The heart of the Rift ----------------------------------------------------------

static func rift_heart() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("rift:heart_seen"):
		_wake_final()
		return
	var fb := World.area_node.find_child("FirebunsFinal*", true, false) as Node3D if is_instance_valid(World.area_node) else null
	Cutscene.begin(true, [fb] if fb else [], "rift_heart")
	Progress.set_flag("rift:heart_seen")
	World.play_track("")
	var prison := Story._spot("cs_prison", p.global_position + Vector3(0, 0, -16)).global_position
	Cutscene.cut(p.global_position + Vector3(4.0, 3.0, 6.0), prison + Vector3.UP * 3.0, 55.0)
	Cutscene.glide(p.global_position + Vector3(2.0, 2.0, 3.0), prison + Vector3.UP * 2.0, 5.0, 48.0)
	await Cutscene.wait(1.4)
	await Cutscene.say([
		"At the heart of the Rift, the ice prison you sealed him in lies shattered across a floor of black glass. The pieces still glow faintly blue, like a cold fire going out.",
	])
	if fb:
		Cutscene.face(fb, p.global_position)
		Story._gauntlet(fb, true)
		Story._close_on(fb, 1.0, 3.0, 1.7)
	Sfx.play("firebuns_laugh", -2.0, 0.0, 0.9)
	await Cutscene.say([
		"There you are. Do you know how long I sat in that ice? Neither do I. There's no time here. Only the cold, and the voice.",
		"It talked to me, little knight. Every endless moment. It told me what Batela did to me. What Haven did to my father's name. What YOU did.",
		"And it gave me a promise. Burn one more kingdom, and I'll never be cold again.",
	], FIREBUNS, fb)
	Story._tint_area(Color(0.7, 0.6, 1.0), 1.2)
	Sfx.play("undead_rise", -4.0, 0.0, 0.4)
	Cutscene.shake(0.06, 2.0)
	await Cutscene.say([
		"...the line of the Nameless... at last... at the very end... *come closer*...",
	], DENANGDYN)
	await Cutscene.say(["A voice from behind the dark, older than the stars. The shadow round Firebuns' feet stirs when it speaks."])
	if fb:
		Story._close_on(fb, -1.0, 3.0, 1.7)
	await Cutscene.say([
		"No more sealing. No more prisons. This time one of us doesn't get up.",
	], FIREBUNS, fb)
	Story._tint_area(Color(1.0 / 0.7, 1.0 / 0.6, 1.0), 1.0)
	Cutscene.end()
	_wake_final()


static func _wake_final() -> void:
	var fb := World.area_node.find_child("FirebunsFinal*", true, false) if is_instance_valid(World.area_node) else null
	if fb and fb.has_method("wake"):
		fb.call("wake")


static func final_phase(fb: Node3D, n: int) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or not is_instance_valid(fb):
		return
	Cutscene.begin(true, [fb], "final_phase_%d" % n)
	Cutscene.face(fb, p.global_position)
	Story._close_on(fb, 1.0, 3.2, 1.7)
	if n == 2:
		fb.call("set_flame", true)
		Sfx.play("fire_whoosh", 0.0, 0.0, 0.7)
		await Cutscene.say([
			"Ha... ha. Starlight. Always her starlight.",
			"Then have ALL of it. Every flame in Bunsriel answers this Gauntlet!",
		], FIREBUNS, fb)
		Story._flash(Color(1.0, 0.6, 0.3, 0.8), 0.15, 1.0)
		Cutscene.shake(0.1, 1.2)
	else:
		Cutscene.play(fb, &"stagger")
		await Cutscene.say([
			"No... no, no, not again, not the ice, I won't go back, I WON'T...",
		], FIREBUNS, fb)
		World.play_track("")
		Story._tint_area(Color(0.6, 0.5, 0.9), 1.4)
		Sfx.play("undead_rise", 0.0, 0.0, 0.35)
		Cutscene.shake(0.14, 2.6)
		Cutscene.cut(fb.global_position + Vector3(0, 2.0, 7.0), fb.global_position + Vector3.UP * 3.0, 62.0)
		await Cutscene.say([
			"The shadow round his feet rises like black water and pours into him. His eyes go dark. When he speaks again, two voices come out of him.",
		])
		await Cutscene.say([
			"*ENOUGH.* I will wear this king to the end, knight, and then I will wear you.",
		], DENANGDYN, fb)
		await Cutscene.say([
			"Two great hands of shadow climb up out of the dark on either side of him. Only one light in the world can hurt them now... and it is in your sword.",
		])
		World.play_track("final_hope" if World.has_music("final_hope") else "true_final_battle")
	Cutscene.end()
	if is_instance_valid(fb):
		fb.call("begin_phase", n)


static func final_blow(fb: Node3D) -> void:
	await StoryEnding.final_blow(fb)
