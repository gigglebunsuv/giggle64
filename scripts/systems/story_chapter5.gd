class_name StoryChapter5
extends RefCounted
## Chapter V, "Firebuns Returns" (Beta 1.3.0: its first half, Saga IV Arc
## III). Played through Story's wrappers:
## - knighting():      the summons read at home after the peace: the years
##                     pass over black, the CHAPTER V card, and the hero is
##                     knighted in the castle yard ("ch5:knight"). Castle Town
##                     is finished (every rebuild flag), the Knight's Tabard.
## - returned():       Rowena's three trials passed: the sky over the yard
##                     cracks, the Astral Seal splits, a vision of the ice
##                     prison breaking, Firebuns III and MARA; the ground under
##                     Haven shakes and the royal crypt opens ("ch5:returned",
##                     "ch5:barrow_open")
## - hollow_king_freed(king): the Hollow King beaten, his last words: the
##                     burning one has gone to Cinderhold ("ch5:barrow_done");
##                     the cliffs' east pass is now known
## - cinder_arrive():  the first sight of Cinderhold ("ch5:cinder_seen")
## - vault_heart():    the Cinder Vault's heart: too late. Firebuns has
##                     rekindled the Gauntlet; Mara comes for him; Serielye's
##                     echo watches; they leave for Black Water Ridge
##                     ("ch5:cinder_done")

const FIREBUNS := "Firebuns III"
const ROWENA := "Commander Rowena"
const HIMEKO := "Himeko"
const MARA := "Mara"
const SERIELYE := "Serielye"
const KING := "The Hollow King"
const SERIELYE_COL := Color(1.0, 0.45, 0.32, 0.85)


static func _playing(id: String) -> bool:
	return Cutscene.active and Cutscene.scene_id == id


static func _area_npc(npc_name: String) -> Npc:
	if not is_instance_valid(World.area_node):
		return null
	return World.area_node.find_child(npc_name, true, false) as Npc


## A goddess as a figure of light in her color, taller than the hero (as
## the springs show them): Serielye's echo.
static func _goddess(pos: Vector3, col: Color) -> CharacterModel:
	# Serielye in her own form (Beta 1.5.0, the user's art), a little
	# see-through: an echo of her, not the goddess herself.
	if ResourceLoader.exists("res://assets/models/serielye.tscn") and is_instance_valid(World.area_node):
		var sm: CharacterModel = (load("res://assets/models/serielye.tscn") as PackedScene).instantiate()
		sm.name = "SerielyeEcho"
		World.area_node.add_child(sm)
		sm.global_position = pos
		sm.scale = Vector3.ONE * 1.2
		var mats := VisionRealm.ghost(sm, 0.25)
		sm.set_meta("ghost", mats)
		var aura2 := OmniLight3D.new()
		aura2.position = Vector3(0, 1.4, 0)
		aura2.light_color = Color(col, 1.0)
		aura2.light_energy = 0.0
		aura2.omni_range = 8.0
		sm.add_child(aura2)
		VisionRealm.ghost_alpha(sm, mats, 0.8, 1.4)
		sm.create_tween().tween_property(aura2, "light_energy", 2.0, 1.4)
		return sm
	var ps := load("res://assets/models/lothelye.tscn") as PackedScene
	if ps == null or not is_instance_valid(World.area_node):
		return null
	var m: CharacterModel = ps.instantiate()
	m.name = "SerielyeEcho"
	World.area_node.add_child(m)
	m.global_position = pos
	m.scale = Vector3.ONE * 1.6
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mat.disable_fog = true
	mat.albedo_color = Color(col, 0.0)
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.material_override = mat
	var aura := OmniLight3D.new()
	aura.position = Vector3(0, 1.4, 0)
	aura.light_color = Color(col, 1.0)
	aura.light_energy = 0.0
	aura.omni_range = 8.0
	m.add_child(aura)
	m.set_meta("glow_mat", mat)
	var t := m.create_tween().set_parallel(true)
	t.tween_property(mat, "albedo_color:a", col.a, 1.4)
	t.tween_property(aura, "light_energy", 2.0, 1.4)
	return m


static func _goddess_fade(m: CharacterModel) -> void:
	if not is_instance_valid(m):
		return
	if m.has_meta("ghost"):
		var mats: Array[StandardMaterial3D] = []
		mats.assign(m.get_meta("ghost"))
		var tg := VisionRealm.ghost_alpha(m, mats, 0.0, 1.2)
		tg.chain().tween_callback(m.queue_free)
		return
	var mat := m.get_meta("glow_mat") as StandardMaterial3D
	var t := m.create_tween()
	if mat:
		t.tween_property(mat, "albedo_color:a", 0.0, 1.2)
	t.tween_callback(m.queue_free)


# --- The summons and the knighting ------------------------------------------------

## Read at home after the peace. Years pass; then the knighting.
static func knighting() -> void:
	if Progress.flag("ch5:knight"):
		return
	var p := GameManager.player
	Cutscene.begin(false, [], "knighting")
	var o: Object = Story._ensure_overlay()
	await Story._black(1.0, 1.4)
	World.play_track("")
	var pages := [
		["THE YEARS PASSED IN PEACE.", ""],
		["CASTLE TOWN WAS FINISHED AT LAST,", "AND ITS BANNERS FLEW AGAIN."],
		["THE BOY WHO FROZE THE BURNING KING", "GREW INTO A MAN."],
		["AND ONE SPRING MORNING,", "HAVEN CALLED HIM TO THE CASTLE."],
	]
	for lines in pages:
		o.set("lines", lines)
		o.set("line_alpha", 0.0)
		var t := GameManager.create_tween()
		t.tween_property(o, "line_alpha", 1.0, 1.0)
		t.tween_interval(2.4)
		t.tween_property(o, "line_alpha", 0.0, 1.0)
		await t.finished
	o.set("lines", [])
	# Years later: every district finished, the knight's tabard waiting.
	Progress.set_flag("ch5:knight")
	for d: String in RebuildFund.ORDER:
		Progress.set_flag(RebuildFund.flag_of(d))
	DayNight.set_hour(8.5)
	await Story.chapter_card(5)
	await World.cutscene_load("castle_town_restored", "knighting", false, false)
	p = GameManager.player
	World.play_track("haven_restored")
	if not is_instance_valid(p):
		await Story._black(0.0, 1.0)
		Story._clear_overlay()
		Cutscene.end()
		return
	Cutscene.halt_player()
	var spot := Story._spot("cs_knight_hero", p.global_position)
	p.global_position = spot.global_position
	p.face_direction(-spot.global_basis.z)
	var row_at := Story._spot("cs_knight_rowena", p.global_position + p.forward() * 2.2)
	var him_at := Story._spot("cs_knight_himeko", p.global_position + p.forward() * 2.2 + Vector3(2.0, 0, 0))
	var rowena := Cutscene.actor("rowena", row_at.global_position, row_at.global_rotation.y, &"idle")
	var himeko := Cutscene.actor("himeko", him_at.global_position, him_at.global_rotation.y, &"idle")
	# The crowd and the Guard either side of the avenue.
	var crowd: Array = []
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := p.global_position + Vector3(side * 3.6, 0, -1.0 + int(i / 2) * 2.2)
		var who: String = "haven_soldier" if i < 4 else ["marigold", "ottilie"][i - 4]
		var a := Cutscene.actor(who, at, 0.0, &"idle")
		if a:
			Cutscene.face(a, p.global_position)
			crowd.append(a)
	var cam := Story._spot("cs_knight_cam", p.global_position + Vector3(5, 3, 5))
	Cutscene.cut(cam.global_position, p.global_position + Vector3.UP * 1.4, 55.0)
	await Story._black(0.0, 1.4)
	Story._clear_overlay()
	Sfx.play("fanfare_big", -10.0, 0.0)
	await Cutscene.say([
		"Castle Town, finished at last. Banners fly from every tower, and this morning half of Haven has squeezed into the castle yard.",
	])
	if rowena:
		Story._close_on(rowena, 1.0, 2.6, 1.6)
		Cutscene.play(rowena, &"talk")
	await Cutscene.say([
		"Sir Gigglebuns. I remember the day you came to the Guard asking where the castle was. You were covered in pond weed.",
		"Since then you've stormed that castle twice, held this town's wall through a night I still dream about, and frozen a king solid.",
		"So. By the will of the Crown, and with the thanks of every soul in Haven... *kneel*.",
	], ROWENA, rowena)
	Cutscene.play(p, &"kneel")
	if himeko:
		Cutscene.play(himeko, &"talk")
		Story._close_on(himeko, -1.0, 2.6, 1.5)
	await Cutscene.say([
		"*Wait!* Wait. Stop everything. A knighting needs a *princess*. Everyone knows that.",
		"Commander, the sword, if you please. Ohohoho! Don't look at me like that. I've been practicing.",
	], HIMEKO, himeko)
	if rowena:
		Cutscene.play(rowena, &"idle")
	await Cutscene.say(["...Fine. Mind his ears."], ROWENA, rowena)
	if himeko:
		await Cutscene.walk(himeko, p.global_position + p.forward() * 1.1 + Vector3(0.4, 0, 0), 1.6, &"walk")
		Cutscene.face(himeko, p.global_position)
		Cutscene.play(himeko, &"laugh")
	Cutscene.cut(p.global_position + p.forward() * 2.6 + Vector3(-1.6, 1.4, 0) + Vector3.UP * 0.2, p.global_position + Vector3.UP * 0.9, 45.0)
	Sfx.play("sword_swing", -4.0, 0.0, 0.8)
	await Cutscene.wait(0.5)
	Sfx.play("sword_swing", -4.0, 0.0, 0.9)
	await Cutscene.say([
		"I dub thee *Knight Gigglebuns*: Knight of Haven, Keeper of the Citadel, Protector of the Realm... and my personal favorite. *Arise!*",
	], HIMEKO, himeko)
	Cutscene.play(p, &"idle")
	Story._flash(Color(1.0, 0.95, 0.8, 0.5), 0.1, 0.8)
	Sfx.play("fanfare_big", -4.0, 0.0)
	for a in crowd:
		if is_instance_valid(a):
			Cutscene.play(a, &"happy")
	Cutscene.cut(cam.global_position + Vector3(0, 2.0, 0), p.global_position + Vector3.UP * 1.6, 60.0)
	await Cutscene.say(["*Knight Gigglebuns!* The yard roars. Somewhere at the back, a dog is barking its head off."])
	Cutscene.end()
	await GetItem.present(p, "vanity_knight")
	if Progress.vanity_on != "knight":
		Progress.toggle_vanity("knight")
	if rowena:
		Cutscene.begin(false, [], "knighting_after")
		Story._close_on(rowena, 1.0, 2.6, 1.6)
		Cutscene.play(rowena, &"talk")
		await Cutscene.say([
			"Looks good on you. Now: being a knight isn't all ceremonies and princesses.",
			"Come and find me in the *Knights' Yard*, on the west lawn by the castle wall. There are a few things a Knight of Haven ought to know that nobody ever bothered teaching you.",
		], ROWENA, rowena)
		Cutscene.end()
	World.play_track(WorldData.music(World.area_id))


# --- Firebuns returns --------------------------------------------------------------

## firebuns_returns.mid's sections in seconds from its start (60 bpm for bars
## 1-9, 150 for 10-17, 72 for 18-25; see make_firebuns_returns_midi.py):
## the ice prison, the shadow's glide (bar 3), the crack (bar 5), the
## shattering's orchestra hit (bar 9), Firebuns' theme (bar 10), Mara (bar
## 18), Firebuns answering her (bar 20), Haven shaking (bar 22), the end.
const RETURNS_CUES := {
	"prison": 0.0, "shadow": 8.0, "crack": 16.0, "shatter": 32.0, "theme": 36.0,
	"mara": 48.8, "mara_reply": 55.47, "shakes": 62.13, "end": 75.47,
}

## Rowena's trials are passed, and the sky over the yard cracks.
static func returned() -> void:
	if Progress.flag("ch5:returned"):
		return
	while Dialogue.active:
		await Cutscene.wait(0.1)
	var p := GameManager.player
	if not is_instance_valid(p):
		Progress.set_flag("ch5:returned")
		Progress.set_flag("ch5:barrow_open")
		return
	Cutscene.begin(true, [], "returned")
	World.play_track("")
	var at := p.global_position
	var rowena := _area_npc("Commander Rowena")
	Cutscene.cut(at + p.forward() * -3.0 + Vector3(1.5, 2.0, 0), at + Vector3.UP * 1.4, 50.0)
	Sfx.play("ice_crack", 0.0, 0.0, 0.6)
	await Cutscene.wait(0.6)
	await Story.say_auto(["A sound like ice breaking on a winter pond... but there's no ice anywhere. It came from your *pack*."])
	# The Astral Seal, split through.
	Cutscene.play(p, &"item_get")
	var seal := MeshInstance3D.new()
	seal.mesh = load("res://assets/models/astral_seal_mesh.tres")
	seal.scale = Vector3.ONE * 2.0
	p.add_child(seal)
	seal.position = Vector3(0, 2.3, 0)
	Cutscene.cut(p.global_position + p.forward() * 2.4 + Vector3.UP * 1.8, p.global_position + Vector3.UP * 2.2, 42.0)
	await Cutscene.wait(0.6)
	Sfx.play("ice_crack", 2.0, 0.0, 1.0)
	Story._flash(Color(0.75, 0.85, 1.0, 0.8), 0.1, 0.6)
	var st := seal.create_tween()
	st.tween_property(seal, "rotation:z", 0.3, 0.1)
	st.tween_property(seal, "rotation:z", -0.2, 0.1)
	st.tween_property(seal, "rotation:z", 0.0, 0.1)
	await Story.say_auto(["The *Astral Seal* has cracked from end to end. Through the crack, for a moment, you see..."])
	if is_instance_valid(seal):
		seal.queue_free()
	# The vision, scored: from here every moment waits for its place in
	# firebuns_returns.mid (RETURNS_CUES), and the boxes run on by themselves.
	await Story._black(1.0, 0.6)
	Story.start_score("firebuns_returns")
	var vision := Story._spot("cs_vision", at + Vector3(0, 300, 0))
	var vp: Vector3 = vision.global_position
	var ice := MeshInstance3D.new()
	ice.mesh = load("res://assets/models/ice_prison_mesh.tres")
	World.area_node.add_child(ice)
	ice.global_position = vp
	ice.scale = Vector3.ONE * 1.1
	var fb := Cutscene.actor("firebuns", vp, 0.0, &"stagger")
	if fb and fb.has_method("set_tint"):
		fb.call("set_tint", Color(0.6, 0.75, 1.3))
	var star_light := OmniLight3D.new()
	star_light.light_color = Color(0.6, 0.7, 1.0)
	star_light.light_energy = 2.0
	star_light.omni_range = 12.0
	World.area_node.add_child(star_light)
	star_light.global_position = vp + Vector3(0, 3, 3)
	Cutscene.cut(vp + Vector3(0.0, 1.6, 6.0), vp + Vector3.UP * 1.4, 50.0)
	# The ice prison (bars 1-4: celesta and high strings).
	Story._black(0.0, 1.0)
	Cutscene.glide(vp + Vector3(1.0, 1.8, 4.6), vp + Vector3.UP * 1.4, RETURNS_CUES.shadow, 48.0)
	await Story.say_window(["Starless dark. Ice drifts in it, a king frozen inside, his burning fist at his chest. And behind him, far off..."],
		RETURNS_CUES.prison + 0.6, RETURNS_CUES.shadow - 0.2)
	# The remnant of Denangdyn: a shadow behind the crack.
	await Story._at_time(RETURNS_CUES.shadow)
	var shadow := Cutscene.actor("lothelye", vp + Vector3(0, -1.0, -9.0), 0.0, &"idle")
	if shadow:
		shadow.scale = Vector3.ONE * 4.0
		if shadow.has_method("set_tint"):
			shadow.call("set_tint", Color(0.05, 0.03, 0.08))
	Cutscene.glide(vp + Vector3(0.0, 2.0, 8.0), vp + Vector3(0, 5.0, -9.0), RETURNS_CUES.crack - RETURNS_CUES.shadow, 55.0)
	# The crack (bars 5-8: the low tremolo climbing): the rumble comes in with it.
	await Story._at_time(RETURNS_CUES.crack)
	Sfx.play("quake_rumble", 0.0, 0.0, 0.5)
	Cutscene.glide(vp + Vector3(0, 5.0, -9.0) + Vector3(0, -1.0, 12.0), vp + Vector3(0, 2.2, 0), RETURNS_CUES.shatter - RETURNS_CUES.crack, 52.0)
	await Story.say_window([
		"...*a shadow*, vast as a hill, standing behind a crack in the dark. The crack the Order made, years ago, in the Fells.",
		"It reaches through. It lays one hand on the ice.",
	], RETURNS_CUES.crack + 0.4, RETURNS_CUES.shatter - 0.3)
	# The shattering, on the orchestra hit (bar 9).
	await Story._at_time(RETURNS_CUES.shatter)
	Sfx.play("ice_shatter", 4.0, 0.0, 0.6)
	Story._flash(Color(1, 1, 1, 1), 0.15, 1.0)
	Cutscene.shake(0.25, 1.5)
	if is_instance_valid(ice):
		Fragments.burst(World.area_node, load("res://assets/models/shard_mesh.tres"), ice.global_position + Vector3.UP * 1.5, 40, 6.0, 6.0, 1.6, 1.8, Color(0.8, 0.92, 1.0))
		ice.queue_free()
	if fb:
		if fb.has_method("set_tint"):
			fb.call("set_tint", Color(1, 1, 1))
		Cutscene.play(fb, &"stagger")
		Story._close_on(fb, 1.0, 4.0, 1.7)
	# His theme (bar 10, 150 bpm): the Gauntlet blazes up on its first beat.
	await Story._at_time(RETURNS_CUES.theme)
	if fb:
		Cutscene.play(fb, &"raise")
		Story._gauntlet(fb, true)
		Story._close_on(fb, 1.0, 3.2, 1.9)
	Sfx.play("firebuns_laugh", 0.0, 0.0)
	await Story.say_window([
		"*Haaah.* ...Air. Fire. *Years*, little knight, in the cold, in the dark. Do you know how long a year is in the dark?",
		"I told you it was waiting for me. I told you.",
	], RETURNS_CUES.theme + 0.6, RETURNS_CUES.mara - 0.3, FIREBUNS, fb)
	# Mara rises with her motif in the choir and organ (bar 18).
	await Story._at_time(RETURNS_CUES.mara)
	var mara := Cutscene.actor("mara", vp + Vector3(2.2, 0, 0.6), -PI * 0.5, &"idle")
	Sfx.play("undead_rise", 0.0, 0.0, 0.8)
	if mara:
		Story._burst(mara.global_position + Vector3.UP * 1.0, Color(0.6, 0.15, 0.2), 2.5)
		Cutscene.face(mara, fb.global_position if fb else vp)
		Story._close_on(mara, -1.0, 3.0, 1.8)
	await Story.say_window([
		"My king. The dead remember you. Every grave in Bunsriel turned over when the ice broke.",
	], RETURNS_CUES.mara + 0.8, RETURNS_CUES.mara_reply - 0.2, MARA, mara)
	if fb:
		Cutscene.face(fb, mara.global_position if mara else vp)
		Story._close_on(fb, -1.0, 3.0, 1.9)
	await Story.say_window([
		"*Mara.* Good. Begin with Haven's dead. Wake its kings to knock on its door.",
	], RETURNS_CUES.mara_reply, RETURNS_CUES.shakes - 0.9, FIREBUNS, fb)
	# Haven shakes (bar 22): black, and back in the yard on the timpani roll.
	await Story._at_time(RETURNS_CUES.shakes - 0.8)
	await Story._black(1.0, 0.8)
	for a in [fb, mara, shadow]:
		if is_instance_valid(a):
			(a as Node3D).queue_free()
	if is_instance_valid(star_light):
		star_light.queue_free()
	Progress.set_flag("ch5:returned")
	Progress.set_flag("ch5:barrow_open")
	# Back in the yard: the ground shakes.
	Cutscene.cut(at + p.forward() * -3.0 + Vector3(1.5, 2.0, 0), at + Vector3.UP * 1.4, 50.0)
	await Story._black(0.0, 0.8)
	Sfx.play("quake_rumble", 4.0, 0.0, 0.7)
	Cutscene.shake(0.2, 2.5)
	GameManager.rumble(1.0, 1.5)
	await Story.say_window(["The vision is gone. The yard is shaking under your feet. Across the square, in the old royal chapel, stone grinds on stone."],
		RETURNS_CUES.shakes + 1.2, RETURNS_CUES.end - 0.3)
	# The unresolved chord just stops: the rest at the reader's own pace.
	await Story._at_time(RETURNS_CUES.end)
	Story.stop_score()
	if rowena:
		Story._close_on(rowena, 1.0, 2.6, 1.6)
		rowena.cs_anim = &"talk"
	await Story.say_auto([
		"What was *that*? ...The chapel. The kings' crypt is under the chapel, the *Barrow of Kings*. It's been sealed for a hundred years.",
		"Knight. Your first duty. Find out what's crawling out of our crypt, and put it back.",
	], ROWENA, rowena)
	if rowena:
		rowena.cs_anim = &""
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))


# --- The Barrow of Kings -----------------------------------------------------------

## The Hollow King on one knee, his crown fallen. Freed, he remembers.
static func hollow_king_freed(king: Node3D) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:barrow_done"):
		return
	Cutscene.begin(true, [king] if is_instance_valid(king) else [], "hollow_king")
	World.play_track("")
	var at := king.global_position if is_instance_valid(king) else p.global_position + p.forward() * 4.0
	Cutscene.cut(p.global_position + Vector3(3.0, 2.4, 3.0), at + Vector3.UP * 2.2, 50.0)
	await Cutscene.wait(1.0)
	await Cutscene.say([
		"...The fire in the old king's helm gutters, and goes out. What is left of his voice is very tired.",
	])
	await Cutscene.say([
		"I was *Harrow*. I bargained with the dark for a crown that would never fall... and so I could not fall either, not even into death.",
		"She found us here. *Mara*. She knows the dark's bargains; she pulled on mine like a leash, and every king in this place rose with me.",
		"Listen, knight. The burning one did not stay to watch us. He went where his Gauntlet was first kept: *Cinderhold*, the old goddess's mountain, east past the cliffs.",
		"A great stone closes the pass. ...But you have a Questlord's grip now. Go. And let the kings *sleep*.",
	], KING, king)
	Progress.set_flag("ch5:barrow_done")
	Sfx.play("goddess_chime", -6.0, 0.0, 0.7)
	if is_instance_valid(king):
		var t := king.create_tween()
		t.tween_property(king, "scale", Vector3(king.scale.x, 0.05, king.scale.z), 1.6)
		t.tween_callback(king.queue_free)
	await Cutscene.wait(1.2)
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))


# --- Cinderhold ----------------------------------------------------------------------

static func cinder_arrive() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:cinder_seen"):
		return
	Cutscene.begin(false, [], "cinder_arrive")
	Progress.set_flag("ch5:cinder_seen")
	var cam := Story._spot("cs_cinder_cam", p.global_position + Vector3(-4, 3, 4))
	var peak := Story._spot("cs_cinder_peak", p.global_position + Vector3(0, 40, -90))
	Cutscene.cut(cam.global_position, peak.global_position, 55.0)
	Cutscene.glide(cam.global_position + Vector3(0, 4, 0), peak.global_position, 5.0, 50.0)
	await Cutscene.wait(1.4)
	if not _playing("cinder_arrive"):
		return
	await Cutscene.say([
		"*Cinderhold*. Serielye's mountain. The goddess of destruction kept the Gauntlet of Fire here, long before any king of Bunsriel was born.",
		"Rivers of fire run down its sides. The air shakes with heat. And at the top, where the smoke is thickest, something has lit the old forge again.",
	])
	if _playing("cinder_arrive"):
		Cutscene.end()


## The Vault's heart: the old anvil where the Gauntlet was first kept.
static func vault_heart() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or Progress.flag("ch5:cinder_done"):
		return
	Cutscene.begin(true, [], "vault_heart")
	World.play_track("")
	var anvil := Story._spot("cs_vault_anvil", p.global_position + Vector3(0, 0, -8))
	var hero := Story._spot("cs_vault_hero", p.global_position)
	p.global_position = hero.global_position
	p.face_direction(anvil.global_position - hero.global_position)
	var cam := Story._spot("cs_vault_cam", p.global_position + Vector3(5, 3, 3))
	var fb := Cutscene.actor("firebuns", anvil.global_position + Vector3(0, 0, 1.6), 0.0, &"raise")
	if fb:
		Cutscene.face(fb, anvil.global_position)
		Story._gauntlet(fb, true)
	Cutscene.cut(cam.global_position, anvil.global_position + Vector3.UP * 1.5, 52.0)
	Sfx.play("fire_whoosh", 0.0, 0.0, 0.5)
	for i in 6:
		var a := TAU * i / 6.0
		Story._flames(anvil.global_position + Vector3(cos(a) * 3.0, 0.0, sin(a) * 3.0), 0.9, i % 2 == 0)
	await Cutscene.wait(1.2)
	await Cutscene.say(["The old anvil at the Vault's heart is white-hot. Firebuns III stands over it with his fist in the fire... and the Gauntlet *drinks* it."])
	if fb:
		Cutscene.face(fb, p.global_position)
		Story._close_on(fb, 1.0, 3.2, 1.9)
		Cutscene.play(fb, &"talk")
	Sfx.play("firebuns_laugh", -2.0, 0.0)
	await Cutscene.say([
		"Late again, little knight. You are always just a little late. It's almost sweet.",
		"This is where she kept it, you know. *Serielye*. The goddess of breaking things kept the one thing that could break *everything*. And then she simply... left it here.",
		"All those years of ice took the fire out of it. One night in this forge put it back. *Feel that heat?*",
	], FIREBUNS, fb)
	var mara := Cutscene.actor("mara", anvil.global_position + Vector3(-3.0, 0, 2.5), PI * 0.4, &"idle")
	Sfx.play("undead_rise", -2.0, 0.0, 0.8)
	if mara:
		Story._burst(mara.global_position + Vector3.UP * 1.0, Color(0.6, 0.15, 0.2), 2.5)
		Cutscene.face(mara, fb.global_position if fb else anvil.global_position)
		Story._close_on(mara, -1.0, 3.0, 1.8)
	await Cutscene.say([
		"The army is gathered, my king. On *Black Water Ridge*, where the dead are strongest. They are waiting for you to lead them.",
	], MARA, mara)
	if mara:
		Cutscene.face(mara, p.global_position)
	await Cutscene.say(["...And this is the knight. He is smaller than I expected."], MARA, mara)
	# Serielye's echo.
	World.play_track("")
	Sfx.play("goddess_appear", -2.0, 0.0, 0.6)
	var echo := _goddess(anvil.global_position + Vector3(0, 0, -3.0), SERIELYE_COL)
	Story._tint_area(Color(1.0, 0.6, 0.5), 1.4)
	Cutscene.cut(p.global_position + Vector3(-2.4, 1.6, 2.6), anvil.global_position + Vector3(0, 2.6, -3.0), 48.0)
	await Cutscene.wait(1.4)
	if fb:
		Cutscene.play(fb, &"guard")
	await Cutscene.say(["The fires lean away from the anvil. Behind it, a shape of red light: tall, still, watching all three of you with the same calm face."])
	await Cutscene.say([
		"You took it out of my mountain, burning king. I let you. I let a great many things happen.",
		"Every fire goes out. Every king falls. That is not a threat. It is only what I am.",
	], SERIELYE, echo)
	if fb:
		Cutscene.play(fb, &"talk")
	await Cutscene.say(["...Then stay out of my way, goddess, and watch."], FIREBUNS, fb)
	Story._flash(Color(1.0, 0.5, 0.2, 0.9), 0.15, 1.0)
	Sfx.play("fire_whoosh", 2.0, 0.0, 0.5)
	Cutscene.shake(0.15, 1.2)
	for a in [fb, mara]:
		if is_instance_valid(a):
			Story._burst((a as Node3D).global_position + Vector3.UP * 1.0, Color(1.0, 0.45, 0.2), 3.0)
			(a as Node3D).queue_free()
	await Cutscene.wait(0.8)
	await Cutscene.say(["In a roar of flame they are gone: west, toward the marshes and the dark ridge beyond them."])
	Cutscene.cut(p.global_position + p.forward() * 2.6 + Vector3.UP * 1.5, p.global_position + Vector3.UP * 1.5, 46.0)
	await Cutscene.say([
		"And you, little knight. Gigglebuns. The first of your name raised his sword to me, once.",
		"*Don't.* ...Good. You are wiser than he was. Or more tired.",
		"Go to the Ridge, if you must. Something there is older than Mara, and it is listening. When the time comes, I will be watching. I always am.",
	], SERIELYE, echo)
	_goddess_fade(echo)
	Story._tint_area(Color(1, 1, 1), 1.4)
	Progress.set_flag("ch5:cinder_done")
	Progress.set_flag("ch5:ridge_known")
	await Cutscene.wait(1.2)
	await Cutscene.say(["*Black Water Ridge* lies west, beyond the marshes. But the black water is rising there, and for now it floods the only way in."])
	Cutscene.end()
	World.play_track(WorldData.music(World.area_id))
