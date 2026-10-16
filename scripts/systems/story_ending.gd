class_name StoryEnding
extends RefCounted
## The true ending (Beta 1.5.0):
## - final_blow(fb):  the last blow of the Bun Sword; Firebuns III's last
##                    words; Denangdyn's shadow tears loose and reaches for
##                    the hero; SERIELYE appears and snuffs it out without
##                    effort; she looks at the hero, and this hero does NOT
##                    raise his sword (the opposite of Gigglebuns I); she
##                    goes; the Rift lets go of him ("ch5:firebuns_end")
## - credits():       the staff roll as a tour of Bunsriel at peace, timed
##                    to credits.ogg (CREDIT_CUES: one place per section of
##                    the music, the names in the corner as in Super Mario
##                    64), the dedication over black, the hook toward Saga V
##                    (riders in the Batela Fells, and a scythe), THE END,
##                    the save, and the post-game ("game_complete")

const FIREBUNS := "Firebuns III"
const DENANGDYN := "???"
const SERIELYE := "Serielye"
const LOTHELYE := "Lothelye"

## ending_cutscene.ogg's moments in seconds (make_ending_cutscene_midi.py, 60
## bpm: bar n starts at 4(n-1) s until bar 29): Appear bars 1-6, the
## violin harmonic alone at bar 7, the closing choir chord at bar 8 beat 3,
## Gaze bars 9-16, Lowered (D major) at bar 17, Home at bar 23, the end of
## the last chord at bar 31.
const ENDING_CUES := {
	"appear_text": 1.5, "raise": 16.0, "harmonic": 24.0, "snuff": 30.0, "embers": 40.0,
	"gaze": 48.0, "gaze_hero": 52.0, "lowered": 64.0, "home": 88.0, "lothelye": 100.0,
	"white": 109.0, "end": 121.44,
}

## credits.ogg's sections in seconds (Beta 1.6.0's credits.mid, printed by
## _giggle64_work/tools/make_credits_midi.py, which holds them as bars):
## intro 1-4 (the main motif remembered), A 5-12 (the main motif), B 13-20
## (the motif in G, "home"), C 21-28 (Avalon's motif over her canon), D 29-36
## (the Firebuns figure in major, then a candle for Firebuns II), bridge 37-44
## (the Black Water Ridge motif, the riff of Age of Enlightenment, Mara's
## theme), bridge2 45-48 (Firebuns III's figure, the lift), finale 49-56 (the
## main motif in E major), finale2 57-64 (Avalon and the Ridge in E major),
## coda 65-70 (Mara's fourth, resolved).
const CREDIT_CUES := {
	"intro": 0.0, "a": 13.33, "a2": 24.76, "b": 36.19, "b2": 47.62, "c": 59.05, "c2": 70.48,
	"d": 81.9, "d2": 93.9, "bridge": 106.06, "bridge2": 128.92, "finale": 140.57, "finale2": 163.43,
	"coda": 186.28, "end": 206.39,
}
## A place takes LOAD_LEAD seconds to fade out and in again (to black 0.45 s,
## World.cutscene_load's 0.8 + 0.3 + 0.8 s, back from black 0.45 s): each
## load starts that long before its cue so the new place is up on the beat.
const LOAD_LEAD := 2.7

## The credits, card by card: [cue, lines]. The first line of each card is
## its heading (gold).
const CARDS := [
	[2.5, ["GIGGLE 64", "THE GAUNTLET OF FIRE"]],
	[14.2, ["DEVELOPED BY", "SAOIRSE REDMOND", "DARCY SHAW"]],
	[19.9, ["STORY AND THE WORLD OF BUNSRIEL", "SAOIRSE REDMOND"]],
	[25.7, ["ART AND CHARACTER DESIGN", "SAOIRSE REDMOND", "DARCY SHAW"]],
	[31.4, ["GAME DESIGN", "SAOIRSE REDMOND", "DARCY SHAW"]],
	[37.1, ["MUSIC", "ANOTHER (SAOIRSE REDMOND)", "WATER ON RED"]],
	[42.8, ["SIR GIGGLEBUNS IV", "PINK", "ALADRIEL AND IDRITH", "THE QUESTLORDS OF LADHELLIN"]],
	[48.5, ["MIRA OF MIRROR LAKE", "PRINCESS HIMEKO", "OTTILIE, MARIGOLD AND CLOVER"]],
	[54.2, ["HILDE OF FROSTPEAK", "TANSY OF CASTLE TOWN", "PIP, HERALD OF HAVEN"]],
	[59.9, ["LOTHELYE", "AVALON, KEEPER OF THE STARS"]],
	[65.7, ["ALAN, APHIEL", "AND SERIELYE"]],
	[71.4, ["POSY, PEPPER THE DOG", "AND BISCUIT THE HORSE"]],
	[77.1, ["COMMANDER ROWENA", "AND THE KNIGHTS OF HAVEN"]],
	[82.8, ["ELDER MAUD", "WREN, ODILE AND TAMSIN", "AND THE PEOPLE OF ASHWICK"]],
	[94.8, ["FIREBUNS II", "A GOOD KING"]],
	[100.8, ["ARCHMAGUS VELLORAN", "AND THE SAPPHIRE ORDER"]],
	[118.4, ["MARA", "SCOURGE OF BUNSRIEL"]],
	[129.8, ["AND", "FIREBUNS III"]],
	[141.5, ["SPECIAL THANKS", "DARCY SHAW", "ZABI", "AVALON"]],
	[147.2, ["SPECIAL THANKS", "TRENT", "JOHN", "ZACH"]],
	[155.8, ["LORD BUBBLES", "AS HIMSELF"]],
	[167.2, ["AND YOU"]],
	[187.2, ["THANK YOU FOR PLAYING!"]],
]

## The tour: [cue, area, entrance, eye offset, look offset, scene] (offsets from
## the area's entrance marker); `scene` names who stands where (_stage).
const TOUR := [
	["intro", "field", "", Vector3(-6, 6, 10), Vector3(0, 2, -20), "dawn"],
	["a", "village", "", Vector3(6, 4, 8), Vector3(0, 1.5, -10), "haven"],
	["b", "castle_town", "", Vector3(-5, 4, 9), Vector3(0, 2, -14), "town"],
	["b2", "lake", "", Vector3(5, 3, 7), Vector3(0, 2, -8), "mira"],
	["c", "hidden_forest", "", Vector3(-4, 3, 7), Vector3(0, 1.5, -10), "pedestal"],
	["d", "batela_fells", "ashwick_bed", Vector3(5, 3.5, 7), Vector3(0, 1.5, -8), "ashwick"],
	["d2", "batela_fells", "keep_hall", Vector3(-3, 2, 5), Vector3(0, 1.2, -4), "candle"],
	["bridge", "black_water_ridge", "", Vector3(6, 5, 9), Vector3(0, 6, -26), "ridge"],
	["bridge2", "cliffs", "", Vector3(-6, 4, 8), Vector3(0, 3, -18), "dawn"],
	["finale", "castle_town", "", Vector3(4, 3, 7), Vector3(0, 1.6, -9), "celebration"],
	["finale2", "desert", "", Vector3(-5, 3, 6), Vector3(0, 1.4, -6), "questlords"],
	["coda", "village", "", Vector3(-4, 2.5, 6), Vector3(0, 1.4, -5), "home"],
]


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


# --- The last blow ---------------------------------------------------------------------

static func final_blow(fb: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	Cutscene.begin(true, [fb] if is_instance_valid(fb) else [], "final_blow")
	World.play_track("")
	var at := fb.global_position if is_instance_valid(fb) else p.global_position + p.forward() * 3.0
	# The blow, seen low and close: a white flash on the beat.
	p.model.set_starlight(true)
	p.model.set_sword_drawn(true)
	Cutscene.play(p, &"slash")
	Cutscene.cut(p.global_position + Vector3(1.6, 0.9, 1.6), at + Vector3.UP * 1.4, 40.0)
	Story._flash(Color(1, 1, 1, 1), 0.35, 2.0)
	Sfx.play("sword_beam", 4.0, 0.0, 0.6)
	Cutscene.shake(0.2, 1.0)
	await Cutscene.wait(1.6)
	if is_instance_valid(fb):
		var fm := fb.get_node_or_null("Model") as Node3D
		if fm:
			Cutscene.play(fm, &"stagger")
		fb.call("set_flame", false)
		Story._gauntlet(fb, false)
		Story._close_on(fb, 1.0, 2.6, 1.3)
	await Cutscene.wait(1.0)
	await Story.say_auto([
		"Firebuns III falls to his knees. The Gauntlet of Fire slips from his hand and rings on the black glass, and its light goes out like a blown candle.",
	])
	await Story.say_auto([
		"...Cold. It's so cold, little knight. It was always cold. Even in the fire.",
		"My father... they say he died a hero. Do you think... there's a place where...",
	], FIREBUNS, fb)
	await Cutscene.wait(0.6)
	# The shadow tears loose.
	Story._tint_area(Color(0.55, 0.45, 0.85), 1.0)
	Sfx.play("undead_rise", 2.0, 0.0, 0.3)
	Cutscene.shake(0.16, 2.4)
	var shade := Cutscene.actor("firebuns", at + Vector3(0, 0.2, -1.2), 0.0, &"raise")
	if shade:
		Cutscene.face(shade, p.global_position)
		(shade as CharacterModel).set_tint(Color(0.05, 0.03, 0.12))
		shade.scale = Vector3.ONE * 0.4
		var t := shade.create_tween()
		t.tween_property(shade, "scale", Vector3.ONE * 2.4, 2.4).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(shade, "global_position", at + Vector3(0, 1.0, -3.0), 2.4)
	Cutscene.cut(p.global_position + Vector3(-2.0, 1.0, 3.0), at + Vector3.UP * 4.0, 62.0)
	await Cutscene.wait(2.6)
	await Story.say_auto([
		"The shadow of Denangdyn pours up out of the fallen king, a vast black shape against the dark, and reaches for you.",
	])
	await Story.say_auto([
		"*YOU.* Child of the Nameless. Your blood sealed me. Your blood will open me. Come here, little light...",
	], DENANGDYN, shade)
	# Serielye. From here the scene runs on ending_cutscene.ogg's clock
	# (Beta 1.6.1; ENDING_CUES): each moment waits for its place in the music
	# and the words go on by themselves.
	Story.start_score("ending_cutscene")
	Sfx.play("goddess_appear", 0.0, 0.0, 0.6)
	var ser_at := at + Vector3(2.2, 0.0, 1.0)
	var ser := Cutscene.actor("serielye", ser_at, 0.0, &"idle")
	if ser:
		Cutscene.face(ser, shade.global_position if shade else at)
		Story._burst(ser_at + Vector3.UP * 1.2, Color(1.0, 0.35, 0.3), 3.0)
	Story._flash(Color(1.0, 0.3, 0.25, 0.7), 0.1, 1.0)
	Cutscene.cut(ser_at + Vector3(2.6, 1.5, 3.2), ser_at + Vector3.UP * 1.6, 44.0)
	Cutscene.glide(ser_at + Vector3(2.2, 1.6, 2.6), ser_at + Vector3.UP * 1.6, ENDING_CUES.raise, 42.0)
	# Appear (bars 1-6): the bell, her motif on the horn.
	await Story.say_window([
		"She is simply there, between one breath and the next: silver hair, a halo of gold, a long thin sword held low. *Serielye*, goddess of destruction, of endings, of balance.",
	], ENDING_CUES.appear_text, ENDING_CUES.raise - 0.3)
	await Story._at_time(ENDING_CUES.raise)
	if ser:
		Cutscene.play(ser, &"raise")
	# Snuff (bars 7-8): the violin harmonic alone under the shadow's last word...
	await Story._at_time(ENDING_CUES.harmonic)
	if shade:
		Cutscene.cut(ser_at + Vector3(-1.5, 1.4, 4.0), shade.global_position + Vector3.UP * 3.0, 60.0)
	await Story.say_window(["...*no*. Not you. Not again—"], ENDING_CUES.harmonic + 0.5, ENDING_CUES.snuff - 0.3, DENANGDYN, shade)
	# ...and the choir chord that closes like a hand.
	await Story._at_time(ENDING_CUES.snuff)
	if ser:
		Cutscene.play(ser, &"close")
	Sfx.play("ward_out", 4.0, 0.0, 0.3)
	Story._flash(Color(1, 1, 1, 1), 0.2, 1.4)
	if shade:
		Fragments.burst(shade.get_parent(), load("res://assets/models/shard_mesh.tres"), shade.global_position + Vector3.UP * 2.0, 40, 6.0, 5.0, 1.4, 1.4, Color(0.3, 0.2, 0.5))
		shade.queue_free()
	Story._tint_area(Color(1.0 / 0.55, 1.0 / 0.45, 1.0 / 0.85), 2.0)
	await Story.say_window([
		"She closes her hand, and the shadow of the Dark Lord is gone, as easily as a candle pinched out. After a thousand years, there is not even an echo of it left.",
	], ENDING_CUES.snuff + 1.0, ENDING_CUES.embers - 0.3)
	# Gaze (bars 9-16): the king goes in embers; she looks at the hero.
	await Story._at_time(ENDING_CUES.embers)
	if is_instance_valid(fb):
		Fragments.burst(fb.get_parent(), load("res://assets/models/shard_mesh.tres"), fb.global_position + Vector3.UP * 1.0, 30, 2.0, 4.0, 2.0, 1.4, Color(2.0, 1.0, 0.4))
		var tf := fb.create_tween()
		tf.tween_property(fb, "scale", Vector3.ONE * 0.05, 2.0)
	await Story.say_window([
		"Firebuns III goes too, quietly, in a drift of embers that rise and do not burn anything.",
	], ENDING_CUES.embers + 0.5, ENDING_CUES.gaze - 0.3)
	await Story._at_time(ENDING_CUES.gaze)
	if ser:
		Cutscene.face(ser, p.global_position)
		Cutscene.play(ser, &"idle")
		Story._close_on(ser, 1.0, 2.4, 1.65)
	await Story._at_time(ENDING_CUES.gaze_hero)
	Cutscene.cut(p.global_position + Vector3(1.4, 1.5, 2.0), p.global_position + Vector3.UP * 1.5, 42.0)
	await Story.say_window([
		"For a long moment Serielye only looks at you, the way the first Gigglebuns was looked at, long ago, before he raised his sword against her.",
		"Your hand is still on your sword. You take it away.",
	], ENDING_CUES.gaze_hero + 0.5, ENDING_CUES.lowered - 0.3)
	# Lowered (bars 17-22): the strings open to D major as he lets go; "Good."
	await Story._at_time(ENDING_CUES.lowered)
	p.model.set_sword_drawn(false)
	Cutscene.play(p, &"idle")
	if ser:
		Story._close_on(ser, -1.0, 2.6, 1.65)
		Cutscene.play(ser, &"talk")
	await Story.say_window([
		"...Good.",
		"The first of your line did not understand what I am. The second fought me for his family's pride. You are wiser than both of them.",
		"I do not save the world, knight. I keep it in balance. Tonight, that happened to be the same thing.",
		"Go home. Your people are waiting.",
	], ENDING_CUES.lowered + 1.2, ENDING_CUES.home - 0.4, SERIELYE, ser)
	# Home (bars 23-30): she goes; the Rift folds; the hero's motif, and Lothelye.
	await Story._at_time(ENDING_CUES.home)
	if ser:
		Story._burst(ser.global_position + Vector3.UP * 1.2, Color(1.0, 0.35, 0.3), 2.5)
		ser.queue_free()
	Sfx.play("goddess_chime", -4.0, 0.0, 0.7)
	Progress.set_flag("ch5:firebuns_end")
	Cutscene.shake(0.1, 3.0)
	await Story.say_window([
		"All round you the Astral Rift begins to fold up like a dream at morning. The floating shores and towers drift away into the dark, smaller and smaller.",
	], ENDING_CUES.home + 1.2, ENDING_CUES.lothelye - 0.3)
	await Story.say_window([
		"It's over, Knight. Close your eyes. I'll bring you home.",
	], ENDING_CUES.lothelye, ENDING_CUES.white - 0.3, LOTHELYE)
	await Story._at_time(ENDING_CUES.white)
	Story._white(1.0, 2.0)
	await Story._at_time(ENDING_CUES.end)
	Story.stop_score()
	World.stop_score()
	if not _playing("final_blow"):
		return
	await credits()


# --- The credits ------------------------------------------------------------------------

## The staff roll, as a tour of Bunsriel at peace (see CREDIT_CUES / TOUR /
## CARDS), then the dedication, the hook, THE END and the save.
static func credits() -> void:
	var o := Story._ensure_overlay()
	o.black = 1.0
	o.flash = Color(1, 1, 1, 0)
	if not Cutscene.active:
		Cutscene.begin(true, [], "credits_tour")
	Story.start_score("credits")
	DayNight.frozen = true
	_run_cards(o)
	for i in TOUR.size():
		var shot: Array = TOUR[i]
		var cue: float = CREDIT_CUES[shot[0]]
		await Story._at_time(maxf(cue - LOAD_LEAD, 0.0))
		if not Cutscene.active:
			return
		await _show_place(shot, i == 0)
	await Story._at_time(CREDIT_CUES.end - 3.0)
	if not Cutscene.active:
		return
	await Story._black(1.0, 2.5)
	await Story._at_time(CREDIT_CUES.end)
	Story.stop_score()
	o.card = []
	# The dedication, over black and silence.
	await Cutscene.wait(1.5)
	o.lines = ["IN LOVING MEMORY OF", "", "MARYBETH REDMOND", "1969 - 2024"]
	o.line_alpha = 0.0
	var t := Story.create_tween()
	t.tween_property(o, "line_alpha", 1.0, 2.0)
	t.tween_interval(6.0)
	t.tween_property(o, "line_alpha", 0.0, 2.0)
	await t.finished
	o.lines = []
	await Cutscene.wait(1.5)
	await _hook(o)
	DayNight.frozen = false
	await _the_end(o)


static func _run_cards(o) -> void:
	for c: Array in CARDS:
		await Story._at_time(float(c[0]))
		if not Cutscene.active or not is_instance_valid(o):
			return
		o.card = c[1]
		o.card_alpha = 0.0
		var t := Story.create_tween()
		t.tween_property(o, "card_alpha", 1.0, 0.8)
		t.tween_interval(4.0)
		t.tween_property(o, "card_alpha", 0.0, 0.8)


## Loads one place of the tour, stages it, and frames it.
static func _show_place(shot: Array, first: bool) -> void:
	var area: String = shot[1]
	var o := Story._ensure_overlay()
	if not first:
		await Story._black(1.0, 0.45)
	DayNight.set_hour(18.6 if shot[5] in ["home", "candle"] else (6.8 if shot[5] == "dawn" else 11.0))
	World.area_id = area
	await World.cutscene_load(area, String(shot[2]), true, false)
	var p := GameManager.player
	var base := p.global_position if is_instance_valid(p) else Vector3.ZERO
	var fwd := p.forward() if is_instance_valid(p) else Vector3(0, 0, -1)
	var right := Vector3(-fwd.z, 0, fwd.x)
	var basis := Basis(right, Vector3.UP, -fwd)
	var eye: Vector3 = base + basis * (shot[3] as Vector3)
	var look: Vector3 = base + basis * (shot[4] as Vector3)
	Cutscene.halt_player()
	Cutscene.cut(eye, look, 50.0)
	Cutscene.glide(eye + basis * Vector3(2.0, 0.6, -1.5), look, 11.0, 46.0)
	_stage(String(shot[5]), base, fwd, right)
	await Story._black(0.0, 0.45 if not first else 1.6)
	o.black = 0.0


## The people of each place, at peace.
static func _stage(scene: String, base: Vector3, fwd: Vector3, right: Vector3) -> void:
	var yaw_back := atan2(fwd.x, fwd.z)
	var put := func(model: String, off: Vector3, anim: StringName) -> Node3D:
		var pos := base + right * off.x + fwd * -off.z
		var a := Cutscene.actor(model, pos, yaw_back, anim)
		return a
	match scene:
		"haven":
			put.call("mira", Vector3(-1.6, 0, -6), &"happy")
			put.call("ottilie", Vector3(1.4, 0, -6.5), &"talk")
			put.call("marigold", Vector3(2.8, 0, -8), &"idle")
			put.call("clover", Vector3(-3.0, 0, -8.5), &"happy")
			put.call("posy", Vector3(0.2, 0, -5.2), &"happy")
		"town":
			put.call("himeko", Vector3(0, 0, -8), &"talk")
			put.call("tansy", Vector3(2.4, 0, -9), &"idle")
			put.call("pink", Vector3(-2.4, 0, -9), &"talk")
		"mira":
			put.call("mira", Vector3(0, 0, -4), &"idle")
		"pedestal":
			put.call("sir_gigglebuns", Vector3(0, 0, -6), &"idle")
		"ashwick":
			put.call("maud", Vector3(0, 0, -5), &"talk")
			put.call("wren", Vector3(1.8, 0, -6), &"idle")
			put.call("odile", Vector3(-1.8, 0, -6), &"idle")
			put.call("tamsin", Vector3(0.8, 0, -3.8), &"happy")
		"candle":
			var c := Story._flames(base + fwd * 3.0 + Vector3.UP * 0.2, 0.18, true)
			if c:
				Cutscene.actors.append(c)
		"ridge":
			put.call("rowena", Vector3(0, 0, -6), &"idle")
			put.call("haven_soldier", Vector3(1.6, 0, -7), &"idle")
		"celebration":
			put.call("sir_gigglebuns", Vector3(0, 0, -6), &"idle")
			put.call("himeko", Vector3(1.5, 0, -6.5), &"happy")
			put.call("pink", Vector3(-1.5, 0, -6.5), &"happy")
			put.call("rowena", Vector3(3.0, 0, -7.5), &"idle")
			put.call("mira", Vector3(-3.0, 0, -7.5), &"happy")
			put.call("posy", Vector3(0.8, 0, -4.8), &"happy")
		"questlords":
			put.call("idrith", Vector3(-0.5, 0, -4), &"idle")
			put.call("aladriel", Vector3(0.5, 0, -4.4), &"idle")
		"home":
			put.call("sir_gigglebuns", Vector3(0, 0, -4), &"idle")


## After the credits: the Batela Fells at dusk, riders gathering on the ridge,
## and a scythe catching the last light. Saga V is coming.
static func _hook(o) -> void:
	World.area_id = "batela_fells"
	DayNight.set_hour(19.2)
	await World.cutscene_load("batela_fells", "keep_hall", true, false)
	var p := GameManager.player
	var base := p.global_position if is_instance_valid(p) else Vector3.ZERO
	Cutscene.halt_player()
	o.black = 0.0
	var ridge := base + Vector3(0, 2.0, -12.0)
	for i in 5:
		var r := Cutscene.actor("haven_soldier", ridge + Vector3(-6.0 + i * 3.0, 0, -i % 2 * 1.5), 0.0, &"idle")
		if r:
			(r as CharacterModel).set_tint(Color(0.06, 0.05, 0.08))
	var reaper := Cutscene.actor("haven_soldier", ridge + Vector3(0, 0.6, -4.0), 0.0, &"idle")
	if reaper:
		(reaper as CharacterModel).set_tint(Color(0.03, 0.03, 0.04))
		reaper.scale = Vector3.ONE * 1.35
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/scythe_mesh.tres") if ResourceLoader.exists("res://assets/models/scythe_mesh.tres") else null
		reaper.add_child(mi)
		mi.position = Vector3(0.5, 0.9, -0.2)
	Cutscene.cut(base + Vector3(3.0, 1.2, 4.0), ridge + Vector3.UP * 1.4, 50.0)
	# On game_over.ogg's clock (Beta 1.6.1): the camera creeps up the ridge
	# under the tired music box; the scythe catches the light as Firebuns'
	# figure comes in on the clarinet (bar 3, 8.28 s); dark with the last bar.
	Story.start_score("game_over")
	Cutscene.glide(base + Vector3(1.0, 1.5, 1.0), ridge + Vector3(0, 2.2, -4.0), 8.28, 36.0)
	await Story._at_time(8.28)
	Sfx.play("sword_swing", -2.0, 0.0, 0.5)
	Story._flash(Color(0.9, 0.9, 1.0, 0.4), 0.05, 0.5)
	await Story._at_time(12.41)
	await Story._black(1.0, 3.5)
	await Story._at_time(17.2)
	Story.stop_score()
	World.stop_score()


static func _the_end(o) -> void:
	o.big = "THE END"
	o.big_alpha = 0.0
	var t := Story.create_tween()
	t.tween_property(o, "big_alpha", 1.0, 1.6)
	t.tween_interval(4.0)
	await t.finished
	Progress.set_flag("game_complete")
	if Cutscene.active:
		Cutscene.end()
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = false
		p.begin_cutscene()
	if not Story.viewing:
		Dialogue.start([{"text": "Thank you for playing. Save your adventure? You will wake at home in Haven, in a kingdom at peace, with every road still open to you.", "choices": [["Save", []], ["Don't save", []]]}])
		await Dialogue.finished
		if Dialogue.last_choice == "Save":
			Story._save_after_ending()
			Dialogue.start(["Your game has been saved. A star shines beside its name on the file screen."])
			await Dialogue.finished
	o.big = ""
	await Cutscene.wait(0.5)
	Story._clear_overlay()
	if Story.end_to_title:
		GameManager.return_to_title()
