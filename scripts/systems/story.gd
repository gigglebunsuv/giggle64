extends Node
## The story's cutscenes (the "Fall of Castle Town" chapter), played through
## Cutscene (z_demo.c-style scenes: halted hero, scene camera, letterbox):
## - wake_up():     a new game: the hero wakes in his bed at home
## - legend():      the Bun Sword drawn: Lothelye appears and shows the hero
##                  the legend of Saga 0 in her dream (VisionRealm)
## - takeover():    after the Bun Sword is drawn, Firebuns III takes Old
##                  Castle Town with the Gauntlet of Fire ("castle_fallen")
## - rescue():      Pink, Aladriel and Idrith found in their cell under the
##                  castle; Pink hands over the Boss Key, Idrith heals
## - throne_room(): Firebuns rises from the throne of Haven and the last
##                  fight begins
## - finale(boss):  the fight he ends: the Gauntlet's full power, the hero
##                  struck down, the rescue, the escape, and the ending
## - chapter_two(), shelter_briefing(): Chapter II (StoryChapter2)
## - fells_arrive(), keep_duel(), keep_duel_end(fb), sanctum_ritual():
##   Chapter III (StoryChapter3)
## - war_begins() ... sealing(fb), peace_ending(): Chapter IV (StoryChapter4)
## - knighting(), returned(), hollow_king_freed(king), cinder_arrive(),
##   vault_heart(): Chapter V, first half (StoryChapter5)
## Castle scenes find their spots by name in the area (Marker3D "cs_*").

const FIREBUNS := "Firebuns III"

## After the ending, back to the title screen (tests turn this off: reloading
## the scene would restart them).
var end_to_title := true
## Played from the debug menu's SCENES tab: the ending offers no save.
var viewing := false

var _layer: CanvasLayer = null
var _overlay: StoryOverlay = null

## The chapters' numbers on their title cards.
const NUMERALS := ["", "I", "II", "III", "IV", "V"]


func _ready() -> void:
	Dialogue.page_started.connect(_on_dialogue_page)


# --- Chapter cards ----------------------------------------------------------------

## A chapter's name, as the journal writes it ("THE GAUNTLET OF FIRE").
func chapter_title(n: int) -> String:
	return String(Quests.find("ch%d" % n).get("title", ""))


## A chapter's title card over black: "CHAPTER I" and its name fade in and out
## (`ending`: "END OF CHAPTER I" and TO BE CONTINUED). The screen is left
## black for the caller to fade back in.
func chapter_card(n: int, ending := false) -> void:
	var o := _ensure_overlay()
	if o.black < 1.0:
		await _black(1.0, 0.8)
	o.chapter = ("END OF CHAPTER %s" if ending else "CHAPTER %s") % NUMERALS[n]
	o.chapter_sub = "TO BE CONTINUED..." if ending else chapter_title(n)
	o.chapter_alpha = 0.0
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(o, "chapter_alpha", 1.0, 1.2)
	t.tween_interval(2.8)
	t.tween_property(o, "chapter_alpha", 0.0, 1.0)
	t.tween_interval(0.3)
	await t.finished
	if not is_instance_valid(o):
		return
	o.chapter = ""
	o.chapter_sub = ""


## A chapter's card as a scene of its own: to black, the card, back to play.
func chapter_scene(n: int, ending := false) -> void:
	if Cutscene.active:
		return
	Cutscene.begin(false, [], "chapter_card")
	await chapter_card(n, ending)
	await _black(0.0, 0.8)
	_clear_overlay()
	if Cutscene.active and Cutscene.scene_id == "chapter_card":
		Cutscene.end()


## A page marked {"chapter_card": n} (or {"chapter_end": n}) shows that card
## once the talk is over and the hero is free again.
func _on_dialogue_page(page: Dictionary) -> void:
	if not (page.has("chapter_card") or page.has("chapter_end")):
		return
	var ending := page.has("chapter_end")
	var n := int(page.get("chapter_end" if ending else "chapter_card"))
	await Dialogue.finished
	for i in 120:
		await get_tree().process_frame
		var p := GameManager.player
		if not Dialogue.active and not Cutscene.active and (p == null or p.state != PlayerController.State.TALK):
			break
	await chapter_scene(n, ending)
	# Chapter III ends in the library, and Chapter IV begins there.
	if ending and n == 3 and not Progress.flag("ch4:war"):
		await StoryChapter4.war_begins()


# --- Helpers --------------------------------------------------------------------

## The black, the flash and the ending's words, drawn over the world but under
## the HUD's text box (CanvasLayer 0; the HUD is layer 1).
func _ensure_overlay() -> StoryOverlay:
	if is_instance_valid(_overlay) and _overlay.is_inside_tree():
		return _overlay
	var vp: Node = World._viewport if World._viewport else get_tree().root
	_layer = CanvasLayer.new()
	_layer.name = "StoryLayer"
	_layer.layer = 0
	vp.add_child(_layer)
	_overlay = StoryOverlay.new()
	_overlay.name = "StoryOverlay"
	_layer.add_child(_overlay)
	return _overlay


func _clear_overlay() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_overlay = null


## A flash of color over the picture (a burst of fire, a smoke bomb).
func _flash(col: Color, hold := 0.1, fade := 0.6) -> void:
	var o := _ensure_overlay()
	o.flash = col
	var t := create_tween()
	t.tween_interval(hold)
	t.tween_property(o, "flash:a", 0.0, fade)


func _black(target: float, time: float) -> void:
	var o := _ensure_overlay()
	var t := create_tween()
	t.tween_property(o, "black", target, time)
	await t.finished


## Fire springing up at `pos` (scenery for a scene; it goes with the area).
func _flames(pos: Vector3, size := 1.0, light := true) -> Node3D:
	var f := Node3D.new()
	f.name = "SceneFire"
	f.set_script(load("res://scripts/systems/torch_flicker.gd"))
	var parent: Node = World.area_node if is_instance_valid(World.area_node) else self
	parent.add_child(f)
	f.global_position = pos
	for i in 3:
		var a := TAU * i / 3.0
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/flame_mesh.tres")
		mi.position = Vector3(cos(a), 0, sin(a)) * 0.3 * size if i > 0 else Vector3.ZERO
		mi.scale = Vector3.ONE * size * (2.6 if i == 0 else 1.8)
		f.add_child(mi)
	if light:
		var l := OmniLight3D.new()
		l.name = "Light"
		l.light_color = Color(1.0, 0.55, 0.25)
		l.light_energy = 2.0
		l.omni_range = 8.0 * size
		l.position = Vector3(0, size, 0)
		f.add_child(l)
	f.scale = Vector3.ONE * 0.1
	create_tween().tween_property(f, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return f


## A ball of light bursting (no harm in it: the scenes' blasts).
func _burst(pos: Vector3, col := Color(1.0, 0.7, 0.35), size := 2.5) -> void:
	var parent: Node = World.area_node if is_instance_valid(World.area_node) else self
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	ball.mesh = sphere
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col, 0.9)
	m.disable_fog = true
	ball.material_override = m
	parent.add_child(ball)
	ball.global_position = pos
	ball.scale = Vector3.ONE * 0.1
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 4.0
	l.omni_range = size * 4.0
	ball.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(ball, "scale", Vector3.ONE * size, 0.4)
	t.tween_property(m, "albedo_color:a", 0.0, 0.6)
	t.tween_property(l, "light_energy", 0.0, 0.6)
	t.chain().tween_callback(ball.queue_free)
	Sfx.play("bomb_explode", -2.0, 0.08)


## Turns the area's light toward `col` over `time` (the sky reddening).
func _tint_area(col: Color, time: float) -> void:
	if not is_instance_valid(World.area_node):
		return
	for n in World.area_node.find_children("*", "DirectionalLight3D", true, false):
		var dl := n as DirectionalLight3D
		create_tween().tween_property(dl, "light_color", dl.light_color * col, time)
	for n in World.area_node.find_children("*", "WorldEnvironment", true, false):
		var env := (n as WorldEnvironment).environment
		if env:
			create_tween().tween_property(env, "ambient_light_color", env.ambient_light_color * col, time)
			create_tween().tween_property(env, "fog_light_color", env.fog_light_color * col, time)


func _spot(mark_name: String, fallback := Vector3.ZERO) -> Node3D:
	var n: Node3D = World.area_node.find_child(mark_name, true, false) as Node3D if is_instance_valid(World.area_node) else null
	if n == null:
		var m := Marker3D.new()
		m.position = fallback
		return m
	return n


## A line from an NPC already standing in the area: its pose, then the box.
func _npc_line(npc: Npc, anim: StringName, pages: Array) -> void:
	if is_instance_valid(npc):
		npc.cs_anim = anim
	await Cutscene.say(pages, npc.npc_name if is_instance_valid(npc) else "", npc)


## A camera on someone's face, from a little to one side.
func _close_on(who: Node3D, side := 1.0, dist := 2.6, height := 1.55) -> void:
	if not is_instance_valid(who):
		return
	var f := -who.global_basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	var s := Vector3(-f.z, 0, f.x) * side
	var head := who.global_position + Vector3.UP * height
	Cutscene.cut(head + f * dist + s * dist * 0.45 + Vector3.UP * 0.15, head, 45.0)


## OoT's "something opened over there" shot (the camera sent to a door a
## switch unbarred, Camera_Demo / the chest-and-door demo cams): a cut to
## `target` (a Marker3D's name in the area, or a Vector3), seen from the
## hero's side and above, a slow push in, the line `text` if any, and back.
## `from` (optional) puts the camera at a given place instead.
func unlock_pan(target, text := "", from = null) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Cutscene.active or not is_instance_valid(World.area_node):
		return
	var at: Vector3
	if target is Vector3:
		at = target
	else:
		var n := World.area_node.find_child(String(target), true, false) as Node3D
		if n == null:
			return
		at = n.global_position
	Cutscene.begin(true, [], "")
	var back := p.global_position - at
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3(0, 0, 1)
	var dist := clampf(p.global_position.distance_to(at) * 0.35, 6.0, 12.0)
	var eye: Vector3 = from if from is Vector3 else at + back * dist + Vector3.UP * dist * 0.55
	var focus := at + Vector3.UP * 1.2
	Cutscene.cut(eye, focus, 50.0)
	Cutscene.glide(eye.lerp(focus, 0.2), focus, 2.6, 46.0)
	await Cutscene.wait(1.0)
	if text != "":
		await Cutscene.say([text])
	else:
		await Cutscene.wait(1.6)
	if Cutscene.active and Cutscene.scene_id == "":
		Cutscene.end()


func _gauntlet(who: Node3D, on: bool) -> void:
	var fl := who.find_child("GauntletFlame", true, false) as Node3D
	if fl:
		fl.visible = on


# --- The legend -------------------------------------------------------------------

const LOTHELYE := "Lothelye"
## The goddesses' colors (their figures of light, their power in the sword).
const ALAN_COL := Color(0.5, 1.0, 0.55, 0.85)
const APHIEL_COL := Color(0.55, 0.78, 1.0, 0.85)
const SERIELYE_COL := Color(1.0, 0.45, 0.32, 0.85)
const HERO_GOLD := Color(1.0, 0.86, 0.45, 0.9)
## How far above the area Lothelye's dream is played (out of sight of it).
const DREAM_HEIGHT := 600.0
## Seconds a scored box takes besides its typing and reading: the box opening
## (8 frames) and closing (3), Cutscene.say's beat after it, and some slack.
const SAY_OVERHEAD := 0.85

## Everything said in the legend, by cue. LegendScore.CUES says when each
## block starts and ends; _giggle64_work/tools/make_lothelye_midi.py reads
## these lines to time the boxes, so after changing one, run it again.
const LEGEND_LINES := {
	"hello": ["*Gigglebuns*..."],
	"welcome": [
		"Do not be afraid, child. I am *Lothelye*. I dreamed this world... and every soul that walks in it.",
		"The blade in your hand has slept in that stone for an age.",
		"Before you carry it into the dark, you must know what it is...",
	],
	"come": ["...and who *you* are. Come. Look with me."],
	"long_ago": ["Long ago, before the first dawn, there was only the dark... and I, dreaming in it."],
	"bunsriel": [
		"From my dream, a world was born: *Bunsriel*.",
		"But it was bare, and silent. So I dreamed three daughters, to shape it.",
	],
	"alan_say": [
		"*Alan*, Goddess of the Harvest, woke first, from the soil.",
		"Forests rose where she walked, and every field and beast was hers to tend.",
	],
	"aphiel_say": [
		"*Aphiel*, Lady of the Sky, came down from the heavens.",
		"She gave the world its skies and rivers... its wisdom, and its freedom.",
	],
	"serielye_say": [
		"And *Serielye*, Goddess of Destruction, made the hells and the mountains of fire.",
		"She was never cruel. She was the balance, so that nothing grew without end.",
	],
	"heavens": ["For ages they watched over Bunsriel. Then, at last, they left it to mortal hands, and rose to the heavens."],
	"denangdyn": [
		"But in the deepest of the hells, a darkness was born: the Dark Lord, *Denangdyn*.",
		"His armies poured out of the fire to swallow the land of the living.",
	],
	"called": ["My daughters could not stand against him alone. They called out to me..."],
	"answered": ["...and I answered."],
	"nameless_say": [
		"From the light I called a warrior. No one ever learned his name...",
		"...and so the songs call him only the *Nameless hero*.",
	],
	"sword_say": [
		"Into his blade my daughters poured their power, Alan's, Aphiel's and Serielye's, made one...",
		"...the *Magical Sword of Bun*.",
	],
	"war": [
		"The war was long, and terrible. But at the last, the hero struck down Denangdyn...",
		"...and sealed him in the *Astral Dimension*, the prison I made for the darkest of things.",
	],
	"sapphire": ["Yet some of his servants escaped him: a guild of mages, the *Sapphire Order*."],
	"fled": ["They fled to the far places of the world... and they are waiting still."],
	"line": [
		"When the war was over, the sword was laid to sleep in its stone.",
		"In every age it wakes again... for one of the hero's own blood.",
		"His blood did not end with him. It ran on through the ages, into a line of knights...",
	],
	"first_say": ["*Gigglebuns the First*, who walked the Path of Souls..."],
	"second_say": ["*Gigglebuns the Second*, who won back his family's honor..."],
	"third_say": ["*Gigglebuns the Third*, who drew this very blade against the Evil King, *Firebuns the First*."],
	"realise": ["......!"],
	"fourth": [
		"And now the sword has woken for you. *Gigglebuns the Fourth*...",
		"...the blood of the Nameless hero runs in your veins.",
	],
	"warning_say": [
		"But hear me. The sword's waking was felt far beyond your forest.",
		"One who holds a stolen fire felt it too... and he is already moving.",
	],
	"farewell": [
		"I cannot walk beside you, child. But my daughters' power is in your hand...",
		"...and I will be watching over you.",
		"Now wake... and be brave.",
	],
}

## The area's lights and sky, put aside while the dream plays.
var _put_aside: Array[Node3D] = []
var _saved_light := {}
## The legend's clock: seconds since its score began. While the score plays
## it is the music's own playback position, so the picture can never drift
## from it; without a music file (or headless) it is scene time.
var _score_on := false
var _score_clock := 0.0
## The most any block of lines ran past its cue's end (tests check it stays 0).
var score_late := 0.0


func _physics_process(delta: float) -> void:
	if not _score_on:
		return
	_score_clock += delta
	var pos := World.score_position()
	if pos >= 0.0 and DisplayServer.get_name() != "headless":
		_score_clock = pos


## A pitch scale `semis` semitones from a sound's own (the goddess chime is
## an E, so its notes sit in the score's chords).
static func _semi(semis: float) -> float:
	return pow(2.0, semis / 12.0)


## Waits until the legend's score reaches `cue` (LegendScore.CUES).
func _at(cue: String) -> void:
	await _at_time(float(LegendScore.CUES[cue]))


func _at_time(t: float) -> void:
	while _score_on and _score_clock < t:
		await get_tree().physics_frame


## The lines for `cue` (LEGEND_LINES), from its cue to the next: the boxes go
## on by themselves, no button needed. Each one types out, then stays up for
## its share of the time left (longer boxes longer), so the last closes just
## as the next cue comes.
func _say_cue(cue: String, speaker := LOTHELYE) -> void:
	await _at(cue)
	var pages: Array = LEGEND_LINES[cue]
	var left: float = float(LegendScore.CUES[cue + "_end"]) - _score_clock - SAY_OVERHEAD
	var weights: Array[float] = []
	var total_w := 0.0
	for text: String in pages:
		var n := 0
		for l in Dialogue.wrap_text(text):
			n += l.length()
		left -= n * Dialogue.FRAME
		weights.append(LegendScore.READ_BASE + LegendScore.READ_PER_CHAR * n)
		total_w += weights[-1]
	var out: Array = []
	for i in pages.size():
		var d := {"text": pages[i], "hold": maxf(0.5, left * weights[i] / total_w)}
		if speaker != "":
			d["name"] = speaker
		out.append(d)
	Dialogue.start(out, null, "black", true)
	await Dialogue.finished
	score_late = maxf(score_late, _score_clock - float(LegendScore.CUES[cue + "_end"]))


## Starts a scored scene's clock on `track` (played once, World.play_score):
## the music's own playback position while it plays, scene time without it.
func start_score(track: String) -> void:
	World.stop_score()
	_score_clock = 0.0
	World.play_score(track)
	_score_on = true


func stop_score() -> void:
	_score_on = false


## Lines that run on by themselves between `t0` and `t1` on the score's
## clock (seconds): they wait for `t0`, then each box types out and stays
## up for its share of the time left, so the last one closes by `t1`.
func say_window(pages: Array, t0: float, t1: float, speaker := "", who: Node = null) -> void:
	await _at_time(t0)
	var left := t1 - _score_clock - SAY_OVERHEAD
	var weights: Array[float] = []
	var total_w := 0.0
	for text: String in pages:
		var n := 0
		for l in Dialogue.wrap_text(text):
			n += l.length()
		left -= n * Dialogue.FRAME
		weights.append(LegendScore.READ_BASE + LegendScore.READ_PER_CHAR * n)
		total_w += weights[-1]
	var out: Array = []
	for i in pages.size():
		var d := {"text": pages[i], "hold": maxf(0.6, left * weights[i] / total_w)}
		if speaker != "":
			d["name"] = speaker
		out.append(d)
	Dialogue.start(out, who, "black", true)
	await Dialogue.finished
	# How far past its window it ran (tests keep this near 0).
	if _score_on:
		score_late = maxf(score_late, _score_clock - t1)


## Lines that go on by themselves at reading pace (Beta 1.6.1), for the
## stretches of a scored scene before or after its music: each box types
## out, then stays up as long as LegendScore's reading time for it.
func say_auto(pages: Array, speaker := "", who: Node = null) -> void:
	var out: Array = []
	for page in pages:
		var d: Dictionary = page.duplicate() if page is Dictionary else {"text": String(page)}
		var n := 0
		for l in Dialogue.wrap_text(String(d.text)):
			n += l.length()
		d["hold"] = LegendScore.READ_BASE + LegendScore.READ_PER_CHAR * n
		if speaker != "" and not d.has("name"):
			d["name"] = speaker
		out.append(d)
	Dialogue.start(out, who, "black", true)
	await Dialogue.finished


## The moment the Bun Sword leaves its stone (after Ocarina of Time's Temple
## of Time and the Deku Tree's tale): the forest darkens, Lothelye, the Cosmic
## Deity, appears over the pedestal and takes the hero into her dream. There
## she shows him the legend of Saga 0: the world dreamed out of the dark, the
## three goddesses, the Dark Lord Denangdyn, and the Nameless hero who sealed
## him away with the Magical Sword of Bun. Then she names the hero's line,
## Gigglebuns the First to the Third, and him, the Fourth, their heir. She
## warns him the sword's waking was felt, and he wakes at the pedestal.
## The whole scene is scored (LegendScore): every moment waits for its cue in
## the music, and the text goes on by itself.
## With `then_end` false the scene camera stays for the takeover that follows.
## A new game (OoT's opening in Link's house, minus the fairy): Sir
## Gigglebuns IV asleep in his bed in the morning light. The rooster crows,
## he sits up and stretches, and then he is out of bed beside it and the day
## is his. The bed's spot is the area's "cs_bed" marker; the hero already
## stands where he gets up (hero_house's "bed" entrance).
func wake_up() -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	Cutscene.begin(false, [], "wake_up")
	Progress.set_flag("woke_up")
	# The house's music would carry on under the card and the prologue's own
	# score: silence it (it comes back when he wakes at home).
	World.play_track("")
	# The game opens on its first chapter's card.
	_ensure_overlay().black = 1.0
	p.visible = false
	await chapter_card(1)
	if not _playing("wake_up"):
		return
	# Far away, that same night: the prologue in the Cinder Vault (StoryIntro).
	await StoryIntro.prologue()
	if not _playing("wake_up"):
		return
	await World.cutscene_load(WorldData.START_AREA, WorldData.START_ENTRANCE, true)
	p = GameManager.player
	if not is_instance_valid(p) or not _playing("wake_up"):
		return
	Cutscene.halt_player()
	p.visible = false
	var at: Vector3 = _spot("cs_bed", p.global_position).global_position
	# Asleep under the red blanket, his head on the pillow at the headboard.
	var sleeper := Cutscene.actor("sir_gigglebuns", at + Vector3(0, -0.08, -0.05), PI, &"sleep")
	if sleeper:
		for n in sleeper.find_children("*", "Node3D", true, false):
			var nn := String(n.name)
			if nn.begins_with("Sword") or nn.begins_with("Shield") or nn.begins_with("Scabbard") or nn.begins_with("Bow"):
				(n as Node3D).visible = false
	Cutscene.cut(at + Vector3(1.7, 1.5, 2.6), at + Vector3(0, 0.25, -0.5), 50.0)
	await _black(0.0, 1.2)
	_clear_overlay()
	if not _playing("wake_up"):
		return
	await Cutscene.wait(1.0)
	if not _playing("wake_up"):
		return
	Sfx.play("rooster", -2.0, 0.0)
	Cutscene.glide(at + Vector3(1.3, 1.15, 1.7), at + Vector3(0, 0.45, -0.6), 2.6)
	await Cutscene.wait(2.0)
	if not _playing("wake_up"):
		return
	Cutscene.play(sleeper, &"wake", 0.3)
	await Cutscene.wait(3.1)
	if not _playing("wake_up"):
		return
	# Out of bed with a hop, beside it.
	if is_instance_valid(sleeper):
		sleeper.queue_free()
	if is_instance_valid(p):
		p.visible = true
		Cutscene.play(p, &"land")
		var f := -p.global_basis.z
		f.y = 0.0
		f = f.normalized() if f.length() > 0.01 else Vector3.BACK
		Cutscene.cut(p.global_position + f * 2.8 + Vector3(-f.z, 0, f.x) * 0.9 + Vector3.UP * 1.5, p.global_position + Vector3.UP * 1.1, 50.0)
	Sfx.play("land", -4.0)
	await Cutscene.wait(0.5)
	if not _playing("wake_up"):
		return
	Cutscene.play(p, &"idle")
	# The castle's page at the door (StoryIntro.messenger).
	await StoryIntro.messenger()
	if _playing("wake_up"):
		Cutscene.end()


## Chapter II (StoryChapter2): the first morning after the ending, at home.
func chapter_two() -> void:
	await StoryChapter2.wake_home()


## Chapter II: Castle Town's survivors in Himeko's palace.
func shelter_briefing() -> void:
	await StoryChapter2.shelter()


## Chapter III (StoryChapter3): the Batela Fells.
func fells_arrive() -> void:
	await StoryChapter3.fells_arrive()


func keep_duel() -> void:
	await StoryChapter3.keep_duel()


func keep_duel_end(fb: Node3D) -> void:
	await StoryChapter3.keep_duel_end(fb)


func sanctum_ritual() -> void:
	await StoryChapter3.sanctum_ritual()


## Chapter IV (StoryChapter4): the Fall of Bunsriel.
func war_begins() -> void:
	await StoryChapter4.war_begins()


func eastgate_falls() -> void:
	await StoryChapter4.eastgate_falls()


func siege_begins(siege: Node) -> void:
	await StoryChapter4.siege_begins(siege)


func siege_break(wave: int) -> void:
	await StoryChapter4.siege_break(wave)


func siege_won(siege: Node) -> void:
	await StoryChapter4.siege_won(siege)


func westmarch_fall() -> void:
	await StoryChapter4.westmarch_fall()


func despair() -> void:
	await StoryChapter4.despair()


func grove_arrive() -> void:
	await StoryChapter4.grove_arrive()


func temple_heart() -> void:
	await StoryChapter4.temple_heart()


func citadel_roof() -> void:
	await StoryChapter4.citadel_roof()


func sealing(fb: Node3D) -> void:
	await StoryChapter4.sealing(fb)


func peace_ending() -> void:
	await StoryChapter4.peace_ending()


## Chapter V (StoryChapter5): Firebuns Returns.
func knighting() -> void:
	await StoryChapter5.knighting()


func returned() -> void:
	await StoryChapter5.returned()


func hollow_king_freed(king: Node3D) -> void:
	await StoryChapter5.hollow_king_freed(king)


func cinder_arrive() -> void:
	await StoryChapter5.cinder_arrive()


func vault_heart() -> void:
	await StoryChapter5.vault_heart()


## Chapter V, second half (StoryRidge): Black Water Ridge.
func front_camp() -> void:
	await StoryRidge.front_camp()


func part_water() -> void:
	await StoryRidge.part_water()


func ridge_arrive() -> void:
	await StoryRidge.ridge_arrive()


func camps_broken() -> void:
	await StoryRidge.camps_broken()


## Small beats (StoryBeats, Beta 1.5.0).
func lake_done() -> void:
	await StoryBeats.lake_done()


func peace_morning() -> void:
	await StoryBeats.peace_morning()


## Chapter V's end and the true ending (StoryFinal, StoryEnding).
func rift_seen() -> void:
	await StoryFinal.rift_seen()


func velloran_stand() -> void:
	await StoryFinal.velloran_stand()


func velloran_falls(v: Node3D) -> void:
	await StoryFinal.velloran_falls(v)


func dream_gift() -> void:
	await StoryFinal.dream_gift()


func rift_open() -> void:
	await StoryFinal.rift_open()


func rift_arrive() -> void:
	await StoryFinal.rift_arrive()


func avalon_scene() -> void:
	await StoryFinal.avalon_scene()


func rift_heart() -> void:
	await StoryFinal.rift_heart()


func final_phase(fb: Node3D, n: int) -> void:
	await StoryFinal.final_phase(fb, n)


func final_blow(fb: Node3D) -> void:
	await StoryEnding.final_blow(fb)


## The true ending's credits tour on its own (the debug SCENES tab).
func credits_tour() -> void:
	await StoryEnding.credits()


func mara_falls(mara: Node3D) -> void:
	await StoryRidge.mara_falls(mara)


## True while the scene `id` is still the one playing (it may have been ended
## from outside, e.g. the area unloaded).
func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


func legend(pedestal: Node3D, then_end := true) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or not is_instance_valid(pedestal):
		return
	Cutscene.begin(true, [], "legend")
	World.play_track("")
	_score_clock = 0.0
	score_late = 0.0
	_score_on = true
	World.play_score(LegendScore.TRACK)
	var ped := pedestal.global_position
	var hero := p.global_position
	var toward := Vector3(ped.x - hero.x, 0, ped.z - hero.z)
	toward = toward.normalized() if toward.length() > 0.1 else Vector3.FORWARD
	Cutscene.face(p, ped)
	Cutscene.play(p, &"idle")
	# --- At the pedestal: the forest darkens and a column of light comes down.
	var ghost_at := ped - toward * 0.7 + Vector3.UP * 1.0
	var side := Vector3(-toward.z, 0, toward.x)
	Cutscene.cut(hero - toward * 2.6 + side * 1.3 + Vector3.UP * 0.9, ghost_at + Vector3.UP * 1.6, 55.0)
	_dim_area(Color(0.45, 0.5, 0.8), 2.0)
	await _at("appear")
	Sfx.play("goddess_appear", 0.0, 0.0)
	var beam := _light_column(ghost_at)
	var loth: CharacterModel = load("res://assets/models/lothelye.tscn").instantiate()
	loth.name = "LothelyeVision"
	World.area_node.add_child(loth)
	loth.global_position = ghost_at
	loth.rotation.y = atan2(toward.x, toward.z)
	loth.scale = Vector3.ONE * 1.15
	var ghost := VisionRealm.ghost(loth, 0.45)
	var motes := _vision_motes(ghost_at + Vector3.UP * 1.2)
	await _at("brighten")
	VisionRealm.ghost_alpha(self, ghost, 0.85, 2.2)
	Cutscene.glide(hero - toward * 1.8 + side * 0.9 + Vector3.UP * 1.0, ghost_at + Vector3.UP * 1.9, 3.0)
	await _at("hello")
	Cutscene.play(loth, &"idle")
	_close_on(loth, -1.0, 3.2, 1.9)
	await _say_cue("hello")
	Cutscene.play(loth, &"talk")
	await _say_cue("welcome")
	await _at("come")
	Cutscene.play(loth, &"reach")
	Cutscene.cut(hero - toward * 1.4 - side * 1.0 + Vector3.UP * 1.5, ghost_at + Vector3.UP * 1.7, 50.0)
	await _say_cue("come")
	await _at("warp")
	Sfx.play("warp", 0.0, 0.0)
	await _white(1.0, 1.0)
	# --- The dream.
	World.stop_ambience()
	if is_instance_valid(loth):
		loth.queue_free()
	if is_instance_valid(beam):
		beam.queue_free()
	if is_instance_valid(motes):
		motes.queue_free()
	await _dream(ped + Vector3.UP * DREAM_HEIGHT)
	# --- Awake at the pedestal.
	_restore_area(0.1)
	var cam_from := hero - toward * 2.2 + side * 1.6 + Vector3.UP * 1.4
	Cutscene.cut(cam_from, hero + Vector3.UP * 1.2, 50.0)
	Cutscene.play(p, &"idle")
	World._play_ambience(World.area_id)
	await _at("awake")
	await _white(0.0, 1.4)
	await _at("end")
	_score_on = false
	Progress.set_flag("legend_told")
	if then_end:
		Cutscene.end()


## The dream played out in light at `origin`, high over the area.
func _dream(origin: Vector3) -> void:
	_put_away_area()
	var realm := VisionRealm.new()
	World.area_node.add_child(realm)
	realm.global_position = origin
	var at := func(v: Vector3) -> Vector3: return origin + v
	# The hero (as he is) on the floor of light, and Lothelye before him.
	var hero: CharacterModel = load("res://assets/models/sir_gigglebuns.tscn").instantiate()
	realm.add_child(hero)
	hero.position = Vector3(0, 0, 1.6)
	hero.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	hero.set_sword_drawn(false)
	hero.set_shield_on_back(true)
	hero.play(&"idle")
	var loth: CharacterModel = load("res://assets/models/lothelye.tscn").instantiate()
	realm.add_child(loth)
	loth.position = Vector3(0, 0.45, -1.3)
	loth.rotation.y = PI
	loth.scale = Vector3.ONE * 1.15
	var loth_mats := VisionRealm.ghost(loth, 0.3)
	VisionRealm.ghost_alpha(self, loth_mats, 1.0, 0.01)
	loth.play(&"idle")
	Cutscene.cut(at.call(Vector3(1.8, 1.3, 4.6)), at.call(Vector3(0, 1.3, 0)), 50.0)
	if is_instance_valid(Cutscene.camera):
		Cutscene.camera.environment = realm.env
	hero.look = Vector2(0, 0.25)
	await _at("dream")
	await _white(0.0, 1.2)
	realm.show_stars(1.0, 4.0)
	Cutscene.glide(at.call(Vector3(1.2, 1.5, 3.6)), at.call(Vector3(0, 1.6, -0.4)), 4.0)
	await _at("long_ago")
	Cutscene.play(loth, &"talk")
	await _say_cue("long_ago")

	# --- Creation: a point of light swells into a world.
	var stage: Vector3 = at.call(Vector3(0, 2.4, -9.0))
	await _at("creation")
	_drift(loth, Vector3(-2.3, 0.45, -1.2), 1.2)
	loth.rotation.y = deg_to_rad(-20.0)
	Cutscene.cut(at.call(Vector3(2.6, 1.6, 3.8)), stage, 55.0)
	Cutscene.play(loth, &"raise")
	Sfx.play("goddess_chime", -2.0, 0.0, _semi(-9.0))
	var world := realm.dream_world(stage - origin)
	realm.sparkle(stage - origin, Color(1.0, 0.95, 0.8), 60)
	var grow := create_tween()
	grow.tween_property(world, "scale", Vector3.ONE, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	Cutscene.glide(at.call(Vector3(1.5, 2.4, -3.8)), stage, 3.0)
	await _say_cue("bunsriel")

	# --- The three goddesses (their chimes on D, E and F#).
	var goddesses: Array[CharacterModel] = []
	var specs := [
		[Vector3(-2.7, -2.6, 0.6), Vector3(-2.7, -1.0, 0.6), ALAN_COL, "life", -2.0, "alan"],
		[Vector3(0, 4.0, -1.2), Vector3(0, 1.7, -1.2), APHIEL_COL, "sky", 0.0, "aphiel"],
		[Vector3(2.7, -2.6, 0.6), Vector3(2.7, -1.0, 0.6), SERIELYE_COL, "fire", 2.0, "serielye"],
	]
	for spec: Array in specs:
		var cue: String = spec[5]
		await _at(cue)
		var from: Vector3 = stage - origin + spec[0]
		var to: Vector3 = stage - origin + spec[1]
		var g := realm.figure("lothelye", from, 0.0, spec[2], 0.7)
		# Facing the watcher, turned a little toward the world between them.
		g.rotation.y = atan2(spec[1].x * 0.15, -1.0)
		g.play(&"idle")
		goddesses.append(g)
		var mid := origin + to + Vector3.UP * 1.1
		Cutscene.cut(mid + (mid - stage).normalized() * 1.0 + Vector3(0.6, 0.3, 4.2), mid, 50.0)
		Sfx.play("goddess_chime", 0.0, 0.0, _semi(spec[4]))
		realm.fade(g, true, 1.2)
		var rise := create_tween()
		rise.tween_property(g, "position", to, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await _at(cue + "_bloom")
		realm.sparkle(to + Vector3.UP * 1.0, spec[2])
		g.play(&"raise")
		realm.reveal(spec[3], 0.95 if spec[3] != "sky" else 0.28, 2.0)
		await _say_cue(cue + "_say")
		g.play(&"idle")

	# --- They leave for the heavens, three stars left shining.
	await _at("heavens")
	Cutscene.cut(at.call(Vector3(0.0, 1.8, -1.0)), stage + Vector3.UP * 1.5, 60.0)
	Cutscene.play(loth, &"talk")
	await _say_cue("heavens")
	await _at("ascend")
	var stars: Array[Node3D] = []
	for i in goddesses.size():
		var g := goddesses[i]
		var sky: Vector3 = stage - origin + Vector3((i - 1) * 2.2, 6.5 - absf(i - 1) * 0.6, -2.0)
		var t := create_tween()
		t.tween_property(g, "position", sky - Vector3.UP * 1.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		realm.fade(g, false, 2.2)
		var star := realm.orb(sky, [ALAN_COL, APHIEL_COL, SERIELYE_COL][i], 0.1)
		star.scale = Vector3.ONE * 0.01
		create_tween().tween_property(star, "scale", Vector3.ONE, 1.0).set_delay(1.8)
		stars.append(star)
	Cutscene.glide(at.call(Vector3(0.0, 2.2, -1.5)), stage + Vector3.UP * 4.5, 2.6)

	# --- The Dark Lord rises.
	await _at("darkness")
	for g in goddesses:
		g.queue_free()
	var wpos := stage - origin
	create_tween().tween_property(world, "position", wpos + Vector3(0, 2.8, -6.0), 2.5).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(world, "scale", Vector3.ONE * 0.6, 2.5)
	realm.shadow_world(true, 2.0)
	var amb_from := realm.env.ambient_light_color
	create_tween().tween_property(realm.env, "ambient_light_color", Color(0.55, 0.2, 0.25), 2.0)
	create_tween().tween_property(realm.env, "background_color", Color(0.24, 0.04, 0.05), 2.0)
	var dark := realm.figure("shade", wpos + Vector3(0, -7.0, -3.4), 0.0, Color(0.03, 0.0, 0.03, 0.96), 5.2, Color(1.0, 0.15, 0.1))
	dark.play(&"float")
	Sfx.play("quake_rumble", -2.0, 0.0)
	Cutscene.shake(0.05, 2.5)
	Cutscene.cut(at.call(Vector3(0.0, 0.6, -1.0)), stage + Vector3(0, 2.0, -3.4), 62.0)
	realm.fade(dark, true, 2.0)
	var up := create_tween()
	up.tween_property(dark, "position", wpos + Vector3(0, -1.6, -3.4), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _at("roar")
	Sfx.play("boss_roar", 0.0, 0.0, 0.7)
	Cutscene.shake(0.08, 1.0)
	await _at("denangdyn")
	Cutscene.play(loth, &"sorrow")
	await _say_cue("denangdyn")
	await _at("called")
	_close_on(loth, -1.0, 3.8, 1.8)
	await _say_cue("called")
	await _at("answered")
	Cutscene.play(loth, &"reach")
	await _say_cue("answered")

	# --- The Nameless hero.
	await _at("nameless")
	var nameless := realm.figure("sir_gigglebuns", wpos + Vector3(0, -2.4, 1.4), 0.0, HERO_GOLD, 1.15)
	nameless.set_gear("bun", "")
	_hide_shield(nameless)
	realm.repaint(nameless)
	nameless.set_sword_drawn(true)
	nameless.play(&"idle")
	Cutscene.cut(at.call(Vector3(3.2, 0.6, -3.6)), origin + wpos + Vector3(0, -1.0, 0.6), 55.0)
	Sfx.play("goddess_appear", -2.0, 0.0, _semi(4.0))
	var col_beam := _light_column(origin + wpos + Vector3(0, -2.4, 1.4), Color(HERO_GOLD, 0.16))
	realm.fade(nameless, true, 1.4)
	realm.sparkle(wpos + Vector3(0, -1.4, 1.4), HERO_GOLD, 60)
	await _say_cue("nameless_say")
	# The goddesses' stars come down into his blade, one chime each (D, E, F#).
	await _at("stars")
	var hand := nameless.find_child("HandR", true, false) as Node3D
	nameless.play(&"item_get")
	Cutscene.cut(at.call(Vector3(2.4, 0.4, -4.8)), origin + wpos + Vector3(0, 0.2, 1.2), 55.0)
	for i in stars.size():
		var s := stars[i]
		var arrive: float = LegendScore.CUES["star%d" % (i + 1)]
		await _at_time(arrive - 0.7)
		var dest: Vector3 = hand.global_position - origin if hand else wpos + Vector3(0, -0.2, 1.4)
		var t := create_tween()
		t.tween_property(s, "position", dest, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(s.queue_free)
		await _at_time(arrive)
		Sfx.play("goddess_chime", -3.0, 0.0, _semi([-2.0, 0.0, 2.0][i]))
	await _at("sword")
	realm.sparkle(nameless.position + Vector3.UP * 2.4, HERO_GOLD, 80)
	_flash(Color(1.0, 0.95, 0.8, 0.7), 0.1, 0.6)
	Sfx.play("magic_burst", 0.0, 0.0)
	await _say_cue("sword_say")
	# The war, and the last stroke.
	await _at("battle")
	nameless.play(&"jumpslash")
	Cutscene.cut(at.call(Vector3(4.6, 0.0, -2.8)), origin + wpos + Vector3(0, -1.0, -1.0), 60.0)
	var leap := create_tween()
	leap.tween_property(nameless, "position", wpos + Vector3(0, -1.6, -0.6), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Sfx.play("sword_beam", 0.0, 0.0)
	await _at("strike")
	Sfx.play("boss_die", -2.0, 0.0)
	_flash(Color(1, 1, 1, 0.9), 0.15, 0.8)
	Cutscene.shake(0.1, 1.0)
	realm.open_vortex(wpos + Vector3(0, -0.6, -5.0), 3.2)
	await _at("swallow")
	var swallow := create_tween().set_parallel(true)
	swallow.tween_property(dark, "position", wpos + Vector3(0, -0.8, -5.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	swallow.tween_property(dark, "scale", Vector3.ONE * 0.1, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	swallow.tween_property(dark, "rotation:y", TAU * 2.0, 1.6)
	realm.fade(dark, false, 1.6)
	Sfx.play("shade_shriek", 0.0, 0.0, 0.6)
	await _at("sealed")
	realm.close_vortex(0.6)
	nameless.play(&"idle")
	await _say_cue("war")
	if is_instance_valid(dark):
		dark.queue_free()

	# --- The ones who got away.
	await _at("sapphire")
	var mages: Array[CharacterModel] = []
	for i in 4:
		var mx: float = [-2.0, -0.8, 0.8, 2.0][i]
		var m := realm.figure("sapphire_mage", wpos + Vector3(mx, -2.6, -2.8 - absf(mx) * 0.3), 0.0, Color(0.16, 0.26, 0.62, 0.85), 1.0, Color(0.6, 0.85, 1.0))
		m.rotation.y = PI + mx * 0.15
		m.play(&"idle")
		realm.fade(m, true, 1.0)
		mages.append(m)
	Sfx.play("mage_appear", -2.0, 0.0)
	Cutscene.cut(at.call(Vector3(1.0, 0.4, -3.2)), origin + wpos + Vector3(0, -1.2, -2.8), 55.0)
	Cutscene.play(loth, &"talk")
	await _say_cue("sapphire")
	await _at("fled")
	for m in mages:
		var away := create_tween().set_parallel(true)
		away.tween_property(m, "position", m.position + Vector3(0, 0, -4.0), 2.4)
		realm.fade(m, false, 2.4)
	await _say_cue("fled")
	await _at("restore")
	for m in mages:
		if is_instance_valid(m):
			m.queue_free()
	realm.shadow_world(false, 2.0)
	create_tween().tween_property(realm.env, "ambient_light_color", amb_from, 2.0)
	create_tween().tween_property(realm.env, "background_color", Color(0.025, 0.02, 0.06), 2.0)
	create_tween().tween_property(world, "position", wpos + Vector3(0, 3.0, -6.0), 2.0)
	if is_instance_valid(col_beam):
		col_beam.queue_free()
	realm.fade(nameless, false, 0.8)

	# --- The line of heroes, down to the Fourth (chimes on C, D, E, F#).
	await _at("line")
	var line: Array[CharacterModel] = []
	var line_at := [Vector3(0, 0, -8.6), Vector3(-1.1, 0, -6.8), Vector3(1.1, 0, -5.0), Vector3(0, 0, -3.3)]
	var line_col := [HERO_GOLD, Color(1.0, 0.8, 0.5, 0.85), Color(1.0, 0.76, 0.55, 0.85), Color(1.0, 0.72, 0.6, 0.85)]
	for i in 4:
		var f := realm.figure("sir_gigglebuns", line_at[i], PI, line_col[i], 1.0)
		f.set_gear("bun", "")
		_hide_shield(f)
		realm.repaint(f)
		f.set_sword_drawn(false)
		f.play(&"idle")
		line.append(f)
	nameless.queue_free()
	Cutscene.cut(at.call(Vector3(1.4, 1.5, 0.2)), at.call(Vector3(0, 1.1, -8.6)), 50.0)
	realm.fade(line[0], true, 1.2)
	Sfx.play("goddess_chime", -4.0, 0.0, _semi(-4.0))
	Cutscene.play(loth, &"talk")
	await _say_cue("line")
	for i in 3:
		var cue: String = ["first", "second", "third"][i]
		await _at(cue)
		var f := line[i + 1]
		Cutscene.glide(at.call(Vector3(1.6, 1.5, 0.6)), origin + f.position + Vector3.UP * 1.1, 0.8)
		realm.fade(f, true, 1.0)
		realm.sparkle(f.position + Vector3.UP * 1.0, line_col[i + 1], 30)
		Sfx.play("goddess_chime", -4.0, 0.0, _semi([-2.0, 0.0, 2.0][i]))
		await _say_cue(cue + "_say")
	# The line looks back at the one at its end.
	await _at("turn")
	Cutscene.cut(at.call(Vector3(0.9, 1.5, -2.6)), at.call(Vector3(0, 1.4, 1.6)), 45.0)
	hero.look = Vector2.ZERO
	await _say_cue("realise", "")
	await _at("fourth")
	_drift(loth, Vector3(-1.4, 0.45, 0.2), 1.0)
	# Turned to the hero beside her.
	loth.rotation.y = atan2(-1.4, -1.4)
	Cutscene.play(loth, &"reach")
	Cutscene.cut(at.call(Vector3(2.2, 1.6, 2.6)), at.call(Vector3(-0.6, 1.5, 0.9)), 50.0)
	await _say_cue("fourth")

	# --- A warning, and farewell.
	await _at("warning")
	for f in line:
		realm.fade(f, false, 1.5)
	_drift(loth, Vector3(0, 0.45, -1.3), 1.2)
	loth.rotation.y = PI
	await _at("warning_say")
	Cutscene.play(loth, &"talk")
	_close_on(loth, 1.0, 3.0, 2.25)
	await _say_cue("warning_say")
	await _at("farewell")
	Cutscene.play(loth, &"bless")
	Cutscene.cut(at.call(Vector3(-1.4, 1.4, 3.8)), at.call(Vector3(0, 1.6, -0.6)), 50.0)
	await _say_cue("farewell")
	await _at("wake")
	Cutscene.play(loth, &"reach")
	realm.hush(1.2)
	Sfx.play("warp", 0.0, 0.0)
	await _white(1.0, 1.2)
	if is_instance_valid(Cutscene.camera):
		Cutscene.camera.environment = null
	realm.queue_free()
	_bring_back_area()


## Floats an actor to `to` (in its parent's space) over `time` seconds.
func _drift(who: Node3D, to: Vector3, time: float) -> void:
	create_tween().tween_property(who, "position", to, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_shield(m: Node3D) -> void:
	for n in ["ShieldMesh", "ShieldBackMesh"]:
		var s := m.find_child(n, true, false) as Node3D
		if s:
			s.visible = false


## A white-out over the picture (into and out of the dream).
func _white(target: float, time: float) -> void:
	var o := _ensure_overlay()
	o.flash = Color(1, 1, 1, o.flash.a)
	var t := create_tween()
	t.tween_property(o, "flash:a", target, time)
	await t.finished


## A tall shaft of light coming down onto `foot` (fades in, and goes with the area).
func _light_column(foot: Vector3, col := Color(0.85, 0.88, 1.0, 0.3)) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = "LightColumn"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 0.8
	cyl.height = 40.0
	cyl.radial_segments = 16
	cyl.cap_top = false
	cyl.cap_bottom = false
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true
	m.albedo_color = Color(col, 0.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	World.area_node.add_child(mi)
	mi.global_position = foot + Vector3.UP * 20.0
	var l := OmniLight3D.new()
	l.light_color = Color(col, 1.0)
	l.light_energy = 0.0
	l.omni_range = 7.0
	l.position = Vector3(0, -18.5, 0)
	mi.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(m, "albedo_color:a", minf(col.a, 0.35), 1.2)
	t.tween_property(l, "light_energy", 2.0, 1.2)
	return mi


## Motes of light drifting round the vision at the pedestal.
func _vision_motes(at: Vector3) -> Node3D:
	var p := CPUParticles3D.new()
	p.name = "VisionMotes"
	World.area_node.add_child(p)
	p.global_position = at
	p.amount = 40
	p.lifetime = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.6
	p.gravity = Vector3(0, 0.25, 0)
	p.initial_velocity_max = 0.15
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.disable_fog = true
	m.albedo_color = Color(0.95, 0.95, 1.0)
	q.material = m
	p.mesh = q
	return p


## Turns the area's light toward `col` (the forest hushing as she comes),
## remembering how it was for `_restore_area`.
func _dim_area(col: Color, time: float) -> void:
	if not is_instance_valid(World.area_node):
		return
	_saved_light.clear()
	for n in World.area_node.find_children("*", "DirectionalLight3D", true, false):
		var dl := n as DirectionalLight3D
		_saved_light[dl] = dl.light_color
		create_tween().tween_property(dl, "light_color", dl.light_color * col, time)
	for n in World.area_node.find_children("*", "WorldEnvironment", true, false):
		var env := (n as WorldEnvironment).environment
		if env:
			_saved_light[env] = [env.ambient_light_color, env.fog_light_color]
			create_tween().tween_property(env, "ambient_light_color", env.ambient_light_color * col, time)
			create_tween().tween_property(env, "fog_light_color", env.fog_light_color * col, time)


func _restore_area(time: float) -> void:
	for k in _saved_light:
		if not is_instance_valid(k):
			continue
		if k is DirectionalLight3D:
			create_tween().tween_property(k, "light_color", _saved_light[k], time)
		elif k is Environment:
			create_tween().tween_property(k, "ambient_light_color", _saved_light[k][0], time)
			create_tween().tween_property(k, "fog_light_color", _saved_light[k][1], time)
	_saved_light.clear()


## Hides the area's sun and sky dome while the dream is played over it.
func _put_away_area() -> void:
	_put_aside.clear()
	if not is_instance_valid(World.area_node):
		return
	for n in World.area_node.find_children("*", "DirectionalLight3D", true, false):
		if (n as Node3D).visible:
			_put_aside.append(n)
	var sky := World.area_node.get_node_or_null("SkyDome") as Node3D
	if sky and sky.visible:
		_put_aside.append(sky)
	for n in _put_aside:
		n.visible = false


func _bring_back_area() -> void:
	for n in _put_aside:
		if is_instance_valid(n):
			n.visible = true
	_put_aside.clear()


# --- The takeover ---------------------------------------------------------------

## After the Bun Sword leaves its stone: the ground shakes, and far away
## Firebuns III marches into Old Castle Town with the Sapphire Order, raises
## the Gauntlet of Fire and sets the town and castle ablaze.
func takeover() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("castle_fallen"):
		return
	Cutscene.begin(true, [], "takeover")
	var pos := p.global_position
	# Castle Town lies east of the Hidden Forest.
	var east := Vector3(1, 0, -0.35).normalized()
	Cutscene.cut(pos - east * 3.0 + Vector3(0, 1.7, 2.2), pos + Vector3(0, 1.4, 0), 50.0)
	Sfx.play("quake_rumble", 0.0, 0.0)
	Cutscene.shake(0.06, 2.4)
	_tint_area(Color(1.0, 0.45, 0.38), 2.5)
	await Cutscene.wait(1.3)
	Cutscene.face(p, pos + east * 10.0)
	Cutscene.glide(pos - east * 2.4 + Vector3(0.0, 1.3, 1.6), pos + east * 14.0 + Vector3(0, 7, 0), 2.2)
	await Cutscene.wait(1.2)
	await Cutscene.say(["...!?", "The ground is shaking! Far off to the east, the sky over *Old Castle Town* is turning red..."])
	World.play_track("")
	await World.cutscene_load("castle_town", "from_field", true, false)
	await _castle_town_burns()
	Progress.set_flag("castle_fallen")
	await World.cutscene_load("castle_town_fallen", "from_field", true, false)
	Cutscene.cut(Vector3(-10, 4.5, -28), Vector3(0, 14, -72), 55.0)
	Cutscene.approach(Vector3(-4, 3.5, -40), Vector3(0, 16, -72), 0.03, 20.0)
	await Cutscene.wait(1.0)
	await Cutscene.say(["I will be waiting on the throne of Haven, little knight.", "Come and take it back... if you dare."], FIREBUNS)
	await World.cutscene_load("hidden_forest", "pedestal", false, true)
	p = GameManager.player
	if is_instance_valid(p):
		Cutscene.cut(p.global_position + Vector3(2.2, 1.7, 3.0), p.global_position + Vector3(0, 1.3, 0), 50.0)
		Cutscene.play(p, &"idle")
	await Cutscene.say(["Old Castle Town has fallen to *Firebuns III*!",
		"Pink, Aladriel and Idrith were in town... Hurry to the *Castle of Haven*!"])
	Cutscene.end()


## The town scene: Firebuns and four mages march up the main street from the
## gate to the fountain, fires spring up round them, he speaks and raises the
## Gauntlet, and flame swallows the castle.
func _castle_town_burns() -> void:
	Sfx.play("alarm", -4.0, 0.0)
	var gate := Vector3(0, 0.2, 38.0)
	var stop := Vector3(0, 0.2, 18.0)
	Cutscene.cut(Vector3(9.0, 5.0, 12.0), Vector3(0, 2.0, 30.0), 55.0)
	var fb := Cutscene.actor("firebuns", gate, 0.0, &"walk")
	var mages: Array[Node3D] = []
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := float(i / 2)
		mages.append(Cutscene.actor("sapphire_mage", gate + Vector3(side * (1.6 + row * 0.6), 0, 2.4 + row * 2.0), 0.0, &"walk"))
	Cutscene.track(fb, Vector3(0, 1.6, 0))
	for i in mages.size():
		var m := mages[i]
		Cutscene.walk(m, Vector3(m.global_position.x, 0.2, stop.z + 2.4 + float(i / 2) * 2.0), 2.2, &"walk")
	for z in [34.0, 28.0]:
		_flames(Vector3(-7.0, 1.5, z), 1.2, z > 30.0)
		_flames(Vector3(7.0, 1.5, z - 3.0), 1.2, false)
	await Cutscene.walk(fb, stop, 2.2, &"walk")
	Cutscene.play(fb, &"talk")
	_close_on(fb, 1.0, 3.0, 1.9)
	await Cutscene.say([
		"So... the little knight has pulled the goddesses' toy from its stone.",
		"I felt it the moment the Bun Sword woke. And so did *this*.",
	], FIREBUNS)
	# The Gauntlet raised: fire everywhere.
	Cutscene.play(fb, &"raise")
	_gauntlet(fb, true)
	Sfx.play("fire_whoosh", 0.0, 0.0)
	Cutscene.cut(fb.global_position + Vector3(4.0, 1.0, 6.0), fb.global_position + Vector3(0, 2.6, 0), 55.0)
	await Cutscene.wait(0.5)
	_flash(Color(1.0, 0.6, 0.3, 0.8), 0.1, 0.8)
	Cutscene.shake(0.12, 1.2)
	for p in [Vector3(-12, 1.0, 6), Vector3(12, 1.0, 8), Vector3(-9, 1.0, -8), Vector3(10, 1.0, -9), Vector3(-20, 1.0, 1), Vector3(20, 1.0, 3)]:
		_flames(p, 1.4, absf(p.x) < 15.0)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"People of Haven! Your castle is mine. Your king has fled.",
		"Every flame in Bunsriel kneels to *Firebuns the Third*, and to the *Gauntlet of Fire*!",
	], FIREBUNS)
	var mage := mages[0]
	Cutscene.play(mage, &"talk")
	Cutscene.face(mage, fb.global_position)
	_close_on(mage, -1.0, 2.6, 1.7)
	await Cutscene.say(["My lord. The armorer and her friends still hold the castle gate."], "Sapphire Mage")
	Cutscene.play(fb, &"laugh")
	_gauntlet(fb, false)
	Sfx.play("firebuns_laugh", 0.0, 0.0)
	_close_on(fb, -1.0, 3.0, 1.9)
	await Cutscene.say([
		"Then let them burn with it. Take the castle. Seal the town.",
		"And when the knight comes... leave him to me.",
	], FIREBUNS)
	# Flame takes the castle.
	Cutscene.cut(Vector3(-6.0, 4.0, -30.0), Vector3(0, 12, -70), 60.0)
	Cutscene.approach(Vector3(-3.0, 6.0, -40.0), Vector3(0, 14, -70), 0.04, 20.0)
	var cy := 3.2
	for i in 4:
		var x: float = [-40.0, -14.0, 14.0, 40.0][i]
		_flames(Vector3(x, cy + 19.0, -66.0), 1.8, absf(x) < 20.0)
		Sfx.play("fire_whoosh", -6.0, 0.1, 0.8)
		Cutscene.shake(0.05, 0.4)
		await Cutscene.wait(0.45)
	_flames(Vector3(0, cy + 36.0, -84.0), 2.2, true)
	_flash(Color(1.0, 0.5, 0.25, 0.6), 0.1, 1.0)
	await Cutscene.wait(2.0)


# --- The rescue -------------------------------------------------------------------

## The cell under the castle, once the Warden has fallen: Pink, Aladriel and
## Idrith, worn out from holding the castle against the Order.
func rescue() -> void:
	var area := World.area_node
	var p := GameManager.player
	if not is_instance_valid(area) or not is_instance_valid(p) or Progress.flag("castle:rescued"):
		return
	var pink := area.find_child("Pink", true, false) as Npc
	var ala := area.find_child("Aladriel", true, false) as Npc
	var idr := area.find_child("Idrith", true, false) as Npc
	Cutscene.begin(true, [], "rescue")
	var spot := _spot("cs_rescue_hero", p.global_position)
	p.global_position = spot.global_position
	p.face_direction(Vector3(1, 0, 0))
	var cam := _spot("cs_rescue_cam", p.global_position + Vector3(0, 2.5, 5))
	if pink:
		Cutscene.cut(cam.global_position, pink.global_position + Vector3.UP * 1.3, 50.0)
		Cutscene.face(pink, p.global_position)
	await _npc_line(pink, &"happy", [
		"Is that... it IS you! Oh, thank goodness!",
	])
	_close_on(pink, 1.0)
	await _npc_line(pink, &"talk", [
		"They came at sunset. Fire everywhere... *Firebuns III* and his mages, the *Sapphire Order*.",
		"We ran to the castle to help the guards. We held the gate as long as we could.",
	])
	if ala and idr:
		Cutscene.cut((ala.global_position + idr.global_position) * 0.5 + Vector3(0.6, 1.4, 3.0), (ala.global_position + idr.global_position) * 0.5 + Vector3(0, 0.9, 0), 50.0)
	await _npc_line(ala, &"talk", [
		"Idrith fought like a storm. But there were too many of them. They threw us down here.",
	])
	await _npc_line(idr, &"talk", [
		"Wh-when he raised that gauntlet, every torch in the hall leapt at us. It was like... like the endless sandstorm.",
		"Like *Dailah*.",
	])
	if idr:
		idr.cs_anim = &"shy"
	await _npc_line(ala, &"talk", [
		"And we beat Dailah. Back to back, swords together. Remember?",
		"We'll face this together, always.",
	])
	if ala:
		ala.cs_anim = &"weary"
	if pink:
		_close_on(pink, -1.0)
	await _npc_line(pink, &"talk", [
		"And look at you! That's the real *Bun Sword*, isn't it? So that's what woke him up...",
		"He's waiting in the throne room, at the very top of the keep. And I grabbed THIS off a guard's belt!",
	])
	# Pink's present: the castle's Boss Key.
	Cutscene.cut(p.global_position + Vector3(2.6, 1.6, 2.2), p.global_position + Vector3(0, 1.6, 0), 50.0)
	await GetItem.present(p, "boss_key")
	Cutscene.halt_player()
	if idr:
		_close_on(idr, 1.0, 2.2, 0.9)
	await _npc_line(idr, &"talk", [
		"Here... take one of my honey buns. You'll need your strength.",
	])
	if is_instance_valid(p):
		p.health.heal(p.health.max_health)
		Sfx.play("heart", -2.0, 0.0)
	if pink:
		_close_on(pink, 1.0)
	await _npc_line(pink, &"happy", [
		"We'll rest up and hold this floor, so nothing follows you. Now go show that tin king what a real sword can do!",
	])
	for n in [pink, ala, idr]:
		if is_instance_valid(n):
			n.cs_anim = &""
	Progress.set_flag("castle:rescued")
	Cutscene.end()


# --- The throne room ----------------------------------------------------------------

func _firebuns() -> Node3D:
	for b in get_tree().get_nodes_in_group("bosses"):
		if b.has_method("wake"):
			return b
	return null


## Firebuns III on the throne of Haven, the burning sky behind him.
func throne_room() -> void:
	var fb := _firebuns()
	var p := GameManager.player
	if fb == null or not is_instance_valid(p) or Progress.flag("castle:throne_seen"):
		return
	Cutscene.begin(true, [fb], "throne_room")
	var hero := _spot("cs_throne_hero", p.global_position)
	p.global_position = hero.global_position
	p.face_direction(Vector3(0, 0, -1))
	var cam := _spot("cs_throne_cam", p.global_position + Vector3(4, 2.5, 0))
	Cutscene.cut(cam.global_position, fb.global_position + Vector3.UP * 1.4, 50.0)
	Cutscene.approach(cam.global_position + Vector3(-2.0, -0.4, -6.0), fb.global_position + Vector3.UP * 1.5, 0.03, 20.0)
	await Cutscene.wait(1.2)
	await Cutscene.say(["So. You came after all."], FIREBUNS, null)
	fb.model.play(&"idle", 0.5)
	Sfx.play("armor_clang", -6.0, 0.05, 0.7)
	await Cutscene.wait(0.8)
	_close_on(fb, 1.0, 3.2, 1.9)
	fb.model.play(&"talk", 0.3)
	await Cutscene.say([
		"I was a king once. My own people poisoned me in my sleep. And yet... here I stand.",
		"The goddesses chose you, little knight. But the Gauntlet chose *me*.",
	], FIREBUNS)
	fb.model.play(&"point", 0.2)
	Cutscene.cut(p.global_position + Vector3(1.2, 1.7, 2.8), fb.global_position + Vector3.UP * 1.6, 50.0)
	await Cutscene.say(["Show me what the goddesses' sword can do!"], FIREBUNS)
	Progress.set_flag("castle:throne_seen")
	Cutscene.end()
	fb.wake()


# --- The finale -------------------------------------------------------------------

## The last fight cut short: Firebuns unleashes the Gauntlet's full power, the
## hero falls, the Questlords and Pink burst in, and they escape. Then the
## ending (the end of Chapter I) and back to the title.
func finale(fb: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p):
		return
	# The fight's music gives way.
	World.play_track("")
	Cutscene.begin(true, [fb], "finale")
	var fbm: CharacterModel = fb.model
	var to_hero := p.global_position - fb.global_position
	to_hero.y = 0.0
	to_hero = to_hero.normalized() if to_hero.length() > 0.1 else Vector3(0, 0, 1)
	fb.facing_yaw = atan2(-to_hero.x, -to_hero.z)
	fb.rotation.y = fb.facing_yaw
	p.face_direction(-to_hero)
	_close_on(fb, 1.0, 3.2, 1.8)
	fbm.play(&"stagger", 0.1)
	await Cutscene.wait(1.2)
	fbm.play(&"laugh", 0.2)
	Sfx.play("firebuns_laugh", 0.0, 0.0)
	await Cutscene.say([
		"Ha... ha ha HA! Not bad, little knight. Not bad at all.",
		"But you still don't understand. The Gauntlet of Fire is not a weapon.",
	], FIREBUNS)
	fbm.play(&"raise", 0.2)
	_gauntlet(fb, true)
	Sfx.play("fire_whoosh", 0.0, 0.0)
	Cutscene.cut(fb.global_position + to_hero * 6.0 + Vector3(0, 0.8, 0) + Vector3(-to_hero.z, 0, to_hero.x) * 3.0, fb.global_position + Vector3.UP * 2.8, 60.0)
	await Cutscene.wait(0.4)
	_flash(Color(1.0, 0.55, 0.25, 0.9), 0.1, 0.7)
	Cutscene.shake(0.14, 1.4)
	for i in 8:
		var a := TAU * i / 8.0
		_flames(fb.global_position + Vector3(cos(a), 0, sin(a)) * 6.5, 1.5, i % 3 == 0)
	await Cutscene.say(["It is the flame itself. And every flame in Bunsriel... *bows to me*!"], FIREBUNS)
	# The firestorm strikes the hero down.
	Cutscene.cut(p.global_position + Vector3(-to_hero.z, 0, to_hero.x) * 4.0 + to_hero * 2.0 + Vector3(0, 1.4, 0), (p.global_position + fb.global_position) * 0.5 + Vector3.UP * 1.2, 55.0)
	var orb := MeshInstance3D.new()
	orb.mesh = load("res://assets/models/fire_orb_mesh.tres")
	orb.scale = Vector3.ONE * 3.0
	World.area_node.add_child(orb)
	orb.global_position = fb.global_position + Vector3.UP * 2.2 + to_hero * 0.8
	Sfx.play("fire_whoosh", 0.0, 0.0, 0.7)
	var ft := create_tween()
	ft.tween_property(orb, "global_position", p.global_position + Vector3.UP * 1.0, 0.45)
	await ft.finished
	orb.queue_free()
	_burst(p.global_position + Vector3.UP * 1.0, Color(1.0, 0.6, 0.3), 3.5)
	_flash(Color(1.0, 0.85, 0.6, 1.0), 0.15, 0.9)
	Cutscene.shake(0.2, 0.8)
	Cutscene.play(p, &"hurt")
	p.health.health = 1
	p.health.health_changed.emit(p.health.health, p.health.max_health)
	Sfx.play("player_hurt", 0.0, 0.0)
	await Cutscene.wait(0.5)
	Cutscene.play(p, &"death")
	await Cutscene.wait(1.6)
	Cutscene.cut(p.global_position + Vector3(0.0, 0.5, 0.0) - to_hero * 2.6 + Vector3(-to_hero.z, 0, to_hero.x) * 0.8, fb.global_position + Vector3.UP * 1.8, 50.0)
	# He comes for the sword.
	_gauntlet(fb, false)
	fbm.play(&"walk", 0.2)
	var near := p.global_position - to_hero * 2.4
	var wt := create_tween()
	wt.tween_property(fb, "global_position", Vector3(near.x, fb.global_position.y, near.z), fb.global_position.distance_to(near) / 1.6)
	await wt.finished
	fbm.play(&"idle", 0.2)
	await Cutscene.say([
		"The goddesses' chosen one... face down in the ashes.",
		"That sword will make a fine trophy for my throne.",
	], FIREBUNS)
	fbm.play(&"slash_windup", 0.1)
	Sfx.play("heavy_swing", -4.0, 0.0, 0.7)
	await Cutscene.wait(0.5)
	# The Questlords burst in.
	var door := _spot("cs_throne_door", p.global_position + to_hero * 12.0)
	Sfx.play("shield_block", 0.0, 0.0, 0.8)
	var side := Vector3(-to_hero.z, 0, to_hero.x)
	var ala := Cutscene.actor("aladriel", door.global_position + side * 0.8, door.rotation.y, &"walk")
	var idr := Cutscene.actor("idrith", door.global_position - side * 0.8, door.rotation.y, &"walk")
	var pink := Cutscene.actor("pink", door.global_position + Vector3(0, 0, 1.5), door.rotation.y, &"walk")
	_arm(ala, "hand_r", "giant_sword_mesh")
	_arm(idr, "hand_r", "scimitar_mesh")
	_arm(idr, "hand_l", "scimitar_mesh")
	Cutscene.cut(p.global_position + side * 5.0 + Vector3(0, 2.2, 0), p.global_position + Vector3.UP * 1.0, 60.0)
	var guard := p.global_position - to_hero * 1.2
	# Both arrive before they take their guard (a walk still running would
	# put its owner back in her own pose afterward).
	var ala_at := guard + side * 0.5
	var idr_at := guard - side * 0.5
	var da: float = ala.global_position.distance_to(ala_at) if ala else 0.0
	var di: float = idr.global_position.distance_to(idr_at) if idr else 0.0
	var run_time := maxf(maxf(da, di) / 7.0, 0.1)
	Cutscene.walk(ala, ala_at, maxf(da, 0.01) / run_time, &"walk")
	await Cutscene.walk(idr, idr_at, maxf(di, 0.01) / run_time, &"walk")
	await Cutscene.wait(0.05)
	Cutscene.face(ala, fb.global_position)
	Cutscene.face(idr, fb.global_position + side * 3.0)
	ala.rotation.y = fb.facing_yaw + PI
	idr.rotation.y = fb.facing_yaw + PI
	Cutscene.play(ala, &"guard")
	Cutscene.play(idr, &"guard")
	Sfx.play("armor_clang", -2.0, 0.0)
	fbm.play(&"guard", 0.1)
	_close_on(ala, 1.0, 2.8, 1.5)
	await Cutscene.say(["Not while we're standing!"], "Aladriel")
	_close_on(idr, -1.0, 2.6, 1.45)
	await Cutscene.say(["T-together, Aladriel!"], "Idrith")
	Cutscene.cut((ala.global_position + idr.global_position) * 0.5 + side * 3.5 - to_hero * 1.5 + Vector3(0, 1.5, 0), (ala.global_position + idr.global_position) * 0.5 + Vector3.UP * 1.3, 50.0)
	await Cutscene.say(["We'll face this together. Always."], "Aladriel")
	fbm.play(&"laugh", 0.2)
	Sfx.play("firebuns_laugh", -2.0, 0.0)
	_close_on(fb, 1.0, 3.4, 1.9)
	await Cutscene.say(["The Questlords of Ladhellin... how touching. You'll burn together, then."], FIREBUNS)
	# Pink drags the hero away under a smoke bomb.
	await Cutscene.walk(pink, p.global_position - to_hero * 0.8 + side * 0.4, 6.0, &"walk")
	Cutscene.face(pink, p.global_position)
	Cutscene.play(pink, &"worried")
	_close_on(pink, -1.0, 2.4, 1.4)
	await Cutscene.say(["Up you get! We're leaving, NOW!"], "Pink")
	Cutscene.play(pink, &"happy")
	_burst(p.global_position + to_hero * 1.5 + Vector3.UP * 0.6, Color(0.95, 0.95, 0.95), 6.0)
	_flash(Color(1, 1, 1, 1), 0.6, 0.0)
	await _black(1.0, 0.8)
	_ensure_overlay().flash = Color(1, 1, 1, 0)
	await Cutscene.wait(0.6)
	Sfx.play("firebuns_laugh", -4.0, 0.0, 0.9)
	await Cutscene.say([
		"Run, then. Run and hide, all of you.",
		"Haven is mine. Soon all of Bunsriel will burn... and I will be waiting.",
	], FIREBUNS)
	await ending()


## A heavy weapon in an actor's hand for the scene.
func _arm(actor: Node3D, joint: String, mesh: String) -> void:
	if not is_instance_valid(actor):
		return
	CharacterModel.grip_weapon(actor.find_child("Hand" + ("R" if joint == "hand_r" else "L"), true, false) as Node3D, mesh)


## The ending over black: what became of Haven, END OF CHAPTER I,
## the offer to save, and back to the title screen. No credits: they roll at the very end.
func ending() -> void:
	var o := _ensure_overlay()
	o.black = 1.0
	Progress.set_flag("game_beaten")
	# ending.ogg was written to these pages (make_ending_midi.py): each one
	# comes in on its bar (Beta 1.6.1, ENDING_PAGE_CUES).
	start_score("ending")
	await pages_on_cues([
		["HAVEN HAS FALLEN.", "FIREBUNS III RULES FROM THE BURNING CASTLE,"],
		["AND THE GAUNTLET OF FIRE", "COMMANDS EVERY FLAME IN BUNSRIEL."],
		["BUT THE BUN SWORD STILL SHINES...", "AND WHILE IT SHINES, THERE IS HOPE."],
	])
	# The end of the first chapter, not the game: the credits wait for the
	# very end (OPTIONS > CREDITS shows them meanwhile).
	await chapter_card(1, true)
	stop_score()
	if Cutscene.active:
		Cutscene.end()
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = false
		p.begin_cutscene()
	if not viewing:
		Dialogue.start([{"text": "Your journey will continue... Save your progress?", "choices": [["Save", []], ["Don't save", []]]}])
		await Dialogue.finished
	if not viewing and Dialogue.last_choice == "Save":
		_save_after_ending()
		Dialogue.start(["Your game has been saved. When you continue, you'll wake up at home in *Haven Village*."])
		await Dialogue.finished
	await Cutscene.wait(0.5)
	_clear_overlay()
	if end_to_title:
		GameManager.return_to_title()


## ending.ogg's bars in seconds (66 bpm): the pages over black come in on
## bar 1 (Firebuns' melody on the cello), bar 2's third beat (the Fm swell),
## bar 4 (the horn finds the main motif) and bar 5, and the chapter card on
## bar 6 (suspended, the celesta: "to be continued").
const ENDING_PAGE_CUES := [0.3, 5.45, 10.91, 14.55]
const ENDING_CARD_CUE := 18.18


## Pages of words over black, each fading in on its cue in the score
## (ENDING_PAGE_CUES) and out before the next; then it waits for the chapter
## card's cue.
func pages_on_cues(pages: Array) -> void:
	var o := _ensure_overlay()
	var cues: Array = ENDING_PAGE_CUES.slice(0, pages.size())
	for i in pages.size():
		var at: float = cues[i]
		var nxt: float = cues[i + 1] if i + 1 < cues.size() else ENDING_CARD_CUE
		await _at_time(at)
		o.lines = pages[i]
		o.line_alpha = 0.0
		var t := create_tween()
		t.tween_property(o, "line_alpha", 1.0, 0.8)
		t.tween_interval(maxf(nxt - at - 2.0, 0.5))
		t.tween_property(o, "line_alpha", 0.0, 0.8)
		await t.finished
	o.lines = []
	await _at_time(ENDING_CARD_CUE)


## The credits (OPTIONS > CREDITS for now; the game's true ending will roll them).
const CREDITS := [
	"GIGGLE 64", "THE GAUNTLET OF FIRE", "BETA 1.7.0", "",
	"DEVELOPED BY", "SAOIRSE REDMOND", "DARCY SHAW", "",
	"STORY AND THE WORLD OF BUNSRIEL", "SAOIRSE REDMOND", "",
	"ART AND CHARACTER DESIGN", "SAOIRSE REDMOND", "DARCY SHAW", "",
	"GAME DESIGN", "SAOIRSE REDMOND", "DARCY SHAW", "",
	"MUSIC", "ANOTHER (SAOIRSE REDMOND)", "WATER ON RED", "",
	"SIR GIGGLEBUNS IV", "PINK", "ALADRIEL AND IDRITH", "THE QUESTLORDS OF LADHELLIN", "",
	"MIRA OF MIRROR LAKE", "PRINCESS HIMEKO", "OTTILIE, MARIGOLD AND CLOVER", "HILDE OF FROSTPEAK", "TANSY OF CASTLE TOWN", "PIP, HERALD OF HAVEN", "",
	"LOTHELYE", "AVALON, KEEPER OF THE STARS", "ALAN, APHIEL AND SERIELYE", "",
	"ELDER MAUD", "WREN, ODILE AND TAMSIN OF ASHWICK", "",
	"COMMANDER ROWENA", "AND THE KNIGHTS OF HAVEN", "POSY, PEPPER THE DOG", "AND BISCUIT THE HORSE", "",
	"ARCHMAGUS VELLORAN", "AND THE SAPPHIRE ORDER", "MARA, SCOURGE OF BUNSRIEL", "",
	"FIREBUNS II", "", "AND", "FIREBUNS III", "",
	"SPECIAL THANKS", "DARCY SHAW", "ZABI", "AVALON", "TRENT", "JOHN", "ZACH", "",
	"LORD BUBBLES AS HIMSELF", "",
	"THANK YOU FOR PLAYING!", "", "",
	"IN LOVING MEMORY OF", "MARYBETH REDMOND", "1969 - 2024",
]


## Rolls the credits up the black screen.
func _roll_credits(o: StoryOverlay) -> void:
	o.credits = CREDITS.duplicate()
	o.scroll = 0.0
	var t3 := create_tween()
	t3.tween_property(o, "scroll", 1.0, CREDITS.size() * 0.75)
	await t3.finished
	if is_instance_valid(o):
		o.credits = []


## OPTIONS > CREDITS: the credits on their own, over black, then back to play.
func credits_roll() -> void:
	if Cutscene.active:
		return
	Cutscene.begin(true, [], "credits")
	var o := _ensure_overlay()
	await _black(1.0, 0.8)
	var was := World.music_track
	World.play_track("ending")
	await _roll_credits(o)
	await _black(0.0, 0.8)
	_clear_overlay()
	World.play_track(was)
	if Cutscene.active:
		Cutscene.end()


## Saves to the game's own file (or the first free one), starting again at
## home in Haven Village with the story where the ending left it.
func _save_after_ending() -> void:
	var slot := Progress.slot
	if slot < 0:
		slot = 0
		for i in SaveGame.SLOTS:
			if not SaveGame.exists(i):
				slot = i
				break
	var area := World.area_id
	var entrance := World.entrance_id
	World.area_id = WorldData.START_AREA
	World.entrance_id = WorldData.START_ENTRANCE
	var p := GameManager.player
	if is_instance_valid(p):
		p.health.health = p.health.max_health
	SaveGame.save(slot)
	World.area_id = area
	World.entrance_id = entrance


## The scenes' black, flash and words at the 320x240 logical resolution.
class StoryOverlay extends Control:
	var black := 0.0
	var flash := Color(1, 1, 1, 0)
	var lines: Array = []
	var line_alpha := 0.0
	var big := ""
	var big_alpha := 0.0
	var credits: Array = []
	var scroll := 0.0
	## A chapter's title card ("CHAPTER I" over its name).
	var chapter := ""
	var chapter_sub := ""
	var chapter_alpha := 0.0
	## A credit card in the corner (the true ending's tour, as in Super Mario
	## 64's staff roll): its first line is the gold heading.
	var card: Array = []
	var card_alpha := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if black > 0.0:
			draw_rect(GameManager.screen_rect(), Color(0, 0, 0, black))
		if flash.a > 0.0:
			draw_rect(GameManager.screen_rect(), flash)
		var y := 104.0
		for l in lines:
			PixelFont.draw_centered(self, 160, y, String(l), Color(1, 1, 1, line_alpha))
			y += 14.0
		if big != "":
			PixelFont.draw_centered(self, 160, 112, big, Color(1.0, 0.85, 0.5, big_alpha), 2)
		if chapter != "" and chapter_alpha > 0.0:
			var gold := Color(1.0, 0.85, 0.5, chapter_alpha)
			PixelFont.draw_centered(self, 160, 98, chapter, gold, 2)
			draw_rect(Rect2(100, 119, 120, 1), Color(gold, chapter_alpha * 0.7))
			PixelFont.draw_centered(self, 160, 126, chapter_sub, Color(1, 1, 1, chapter_alpha))
		if not card.is_empty() and card_alpha > 0.0:
			var r := GameManager.screen_rect()
			var x0 := r.position.x + 14.0
			var y0 := 168.0 - (card.size() - 1) * 12.0
			for i in card.size():
				var col := Color(1.0, 0.85, 0.5, card_alpha) if i == 0 and card.size() > 1 else Color(1, 1, 1, card_alpha)
				PixelFont.draw(self, Vector2(x0, y0 + i * 12.0), String(card[i]), col, 1, true)
		if not credits.is_empty():
			var top := 250.0 - scroll * (250.0 + credits.size() * 14.0)
			for i in credits.size():
				var cy := top + i * 14.0
				if cy > -10.0 and cy < 245.0:
					var col := Color(1.0, 0.85, 0.5) if i < 2 else Color(1, 1, 1)
					PixelFont.draw_centered(self, 160, cy, String(credits[i]), col)
