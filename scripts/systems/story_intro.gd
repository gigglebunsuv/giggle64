class_name StoryIntro
extends RefCounted
## The opening of a new game (Beta 1.5.0, design/chapter_one_opening.md):
## - prologue():   after the CHAPTER I card, far away in the CINDER VAULT
##                 under Serielye's mountain, Firebuns III walks through the
##                 dark to the old anvil, where the Gauntlet of Fire lies
##                 frozen in Serielye's ice; fire springs up where he steps,
##                 the ice knows him and breaks, and the Gauntlet is his.
##                 (Chapter V's Cinder Vault scene remembers this night.)
## - messenger():  back home, as the hero gets up: knocking, and PIP, page to
##                 the King of Haven, bursts in out of breath with the King's
##                 summons, and the first step of the road (the Lake Shrine).
## Story.wake_up plays them around the hero waking.

const FIREBUNS := "Firebuns III"
const PIP := "Pip"


## prologue.ogg's moments, in seconds (make_prologue_midi.py; bar times from
## bar_times.py): Ice bars 1-6 (the narrator), Footfalls bars 7-14 (his
## steps on bars 7-10, the low brass swell under his words at bar 11), The
## ice bars 15-18 (the celesta's falling run, the timpani rumble from bar
## 16), Ice melts bar 19 (his motif bursts out), and the held chord.
const PROLOGUE_CUES := {
	"narration": 4.0, "narration_end": 16.0,
	"footfalls": 25.71, "swell": 42.86,
	"crack": 60.0, "rumble": 64.29, "shatter": 72.86, "burst": 77.14,
	"fade": 88.0, "end": 95.97,
}


static func _playing() -> bool:
	return Cutscene.active and Cutscene.scene_id == "wake_up"


## The prologue, in the Cinder Vault. Returns with the screen black, ready
## for home.
static func prologue() -> void:
	# The hero has not been here (the journal and the map must not think so).
	var had := Progress.flag("visited:cinder_vault")
	await World.cutscene_load("cinder_vault", "", true, false)
	if not had:
		Progress.flags.erase("visited:cinder_vault")
	if not _playing():
		return
	Cutscene.begin(true, [], "wake_up")
	# The scene runs on prologue.ogg's clock (Beta 1.6.1): every moment waits
	# for its place in the music (PROLOGUE_CUES) and the words go on by
	# themselves, as in Lothelye's legend.
	Story.start_score("prologue")
	var anvil := Story._spot("cs_vault_anvil", Vector3.ZERO).global_position
	var hero_spot := Story._spot("cs_vault_hero", anvil + Vector3(0, 0, 8)).global_position
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = false
	Story._tint_area(Color(0.55, 0.6, 0.85), 0.01)
	# Serielye's ice round the Gauntlet on the anvil.
	var ice := MeshInstance3D.new()
	ice.mesh = load("res://assets/models/ice_prison_mesh.tres") if ResourceLoader.exists("res://assets/models/ice_prison_mesh.tres") else null
	ice.scale = Vector3.ONE * 0.55
	World.area_node.add_child(ice)
	ice.global_position = anvil + Vector3(0, 0.6, 0)
	var gl := MeshInstance3D.new()
	gl.mesh = load("res://assets/models/gauntlet_mesh.tres") if ResourceLoader.exists("res://assets/models/gauntlet_mesh.tres") else null
	gl.scale = Vector3.ONE * 1.6
	World.area_node.add_child(gl)
	gl.global_position = anvil + Vector3(0, 1.3, 0)
	Cutscene.actors.append(ice)
	Cutscene.actors.append(gl)
	# Ice (bars 1-6): the dark vault, the frozen cradle, and the narrator.
	Cutscene.cut(anvil + Vector3(2.5, 1.6, 3.0), anvil + Vector3.UP * 1.2, 46.0)
	Cutscene.glide(anvil + Vector3(1.2, 1.9, 2.4), anvil + Vector3.UP * 1.3, 14.0, 40.0)
	await Story._black(0.0, 2.0)
	if not _playing():
		return
	await Story.say_window(["Far away, in a mountain that was once a goddess's forge, something has waited a very long time in the ice."],
		PROLOGUE_CUES.narration, PROLOGUE_CUES.narration_end)
	if not _playing():
		return
	# Footfalls (bars 7-10): he comes, one step to each of his motif's cells,
	# and fire where he walks.
	var start := hero_spot + Vector3(0, 0, 4.0)
	var fb := Cutscene.actor("firebuns", start, 0.0, &"idle")
	if fb:
		fb.visible = false
		Cutscene.face(fb, anvil)
		Story._gauntlet(fb, false)
	await Story._at_time(PROLOGUE_CUES.footfalls)
	if not _playing():
		return
	if fb:
		fb.visible = true
	Cutscene.cut(anvil + Vector3(-1.5, 0.7, 1.0), start + Vector3.UP * 1.4, 50.0)
	Cutscene.track(fb, Vector3.UP * 1.5)
	var steps := 5
	var stride: float = (PROLOGUE_CUES.swell - PROLOGUE_CUES.footfalls) / steps
	for i in steps:
		await Story._at_time(PROLOGUE_CUES.footfalls + i * stride)
		if not _playing():
			return
		var to := start.lerp(anvil + Vector3(0, 0, 1.8), float(i + 1) / steps)
		if fb:
			Cutscene.play(fb, &"walk")
			Cutscene.walk(fb, Vector3(to.x, start.y, to.z), stride * 0.8)
		Story._flames(Vector3(to.x, start.y, to.z) + Vector3(0.8 if i % 2 == 0 else -0.8, 0, 0), 0.5, i % 2 == 0)
		Sfx.play("fire_whoosh", -8.0, 0.1, 0.8)
	# The low brass swell (bar 11): "There you are."
	await Story._at_time(PROLOGUE_CUES.swell)
	if not _playing():
		return
	if fb:
		Cutscene.play(fb, &"idle")
		Story._close_on(fb, 1.0, 2.6, 1.8)
	Sfx.play("firebuns_laugh", -6.0, 0.0, 0.9)
	await Story.say_window([
		"There you are.",
		"They poisoned me in my sleep, you know. My own people. They thought that was the end of a king.",
		"Serielye's ice, is it? How like her. To make a thing that can burn the world... and then put it somewhere cold, and walk away.",
	], PROLOGUE_CUES.swell + 0.4, PROLOGUE_CUES.crack - 0.3, FIREBUNS, fb)
	if not _playing():
		return
	# The ice (bars 15-18): the celesta's falling run is the ice cracking;
	# the timpani's rumble, the crack spreading; it gives way before the burst.
	await Story._at_time(PROLOGUE_CUES.crack)
	Cutscene.cut(anvil + Vector3(2.0, 1.2, 2.2), anvil + Vector3.UP * 1.2, 44.0)
	if fb:
		Cutscene.play(fb, &"raise")
	Sfx.play("ice_crack", 0.0, 0.0, 0.8)
	Cutscene.shake(0.06, 1.0)
	await Story._at_time(PROLOGUE_CUES.rumble)
	Sfx.play("ice_crack", -2.0, 0.0, 0.7)
	Cutscene.shake(0.08, 3.0)
	await Story._at_time(PROLOGUE_CUES.shatter)
	Sfx.play("ice_shatter", 2.0, 0.0, 0.7)
	Fragments.burst(World.area_node, load("res://assets/models/shard_mesh.tres"), anvil + Vector3.UP * 1.2, 30, 4.0, 4.0, 1.0, 1.0, Color(0.7, 0.85, 1.2))
	if is_instance_valid(ice):
		ice.queue_free()
	await Story.say_window(["Ice melts."], PROLOGUE_CUES.shatter + 0.6, PROLOGUE_CUES.burst - 0.2, FIREBUNS, fb)
	if not _playing():
		return
	# Ice melts (bar 19): his motif bursts out, and so does the fire.
	await Story._at_time(PROLOGUE_CUES.burst)
	if is_instance_valid(gl):
		gl.queue_free()
	if fb:
		Story._gauntlet(fb, true)
	Story._flash(Color(1.0, 0.55, 0.2, 1.0), 0.3, 1.2)
	Sfx.play("fire_whoosh", 4.0, 0.0, 0.5)
	Cutscene.shake(0.14, 1.4)
	for i in 8:
		var a := TAU * i / 8.0
		Story._flames(anvil + Vector3(cos(a) * 3.2, 0.0, sin(a) * 3.2), 1.0, i % 2 == 0)
	Cutscene.glide(anvil + Vector3(3.4, 2.4, 4.2), anvil + Vector3.UP * 1.4, 12.0, 48.0)
	# The held chord: the picture goes as the music does.
	await Story._at_time(PROLOGUE_CUES.fade)
	await Story._black(1.0, PROLOGUE_CUES.end - PROLOGUE_CUES.fade)
	Story.stop_score()
	World.stop_score()
	for a in Cutscene.actors:
		if is_instance_valid(a):
			a.queue_free()
	Cutscene.actors.clear()


## Pip at the door: the King's summons, and where to begin.
static func messenger() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or not _playing():
		return
	var door := World.area_node.find_child("Door_village", true, false) as Node3D
	var door_at := door.global_position if door else p.global_position + p.forward() * 4.0
	for i in 3:
		Sfx.play("wall_hit_soft", 0.0, 0.05, 0.9)
		Cutscene.shake(0.02, 0.15)
		await Cutscene.wait(0.32)
	await Cutscene.say([{"text": "*KNOCK KNOCK KNOCK!*\n\"Sir Gigglebuns! Sir Gigglebuns, are you awake?!\""}])
	Sfx.play("door_open", 0.0)
	var inward := -door.global_basis.z if door else -p.forward()
	inward.y = 0.0
	inward = inward.normalized() if inward.length() > 0.1 else Vector3(0, 0, -1)
	var pip := Cutscene.actor("pip", door_at + inward * 0.6, 0.0, &"walk")
	if pip:
		Cutscene.face(pip, p.global_position)
		Cutscene.cut(p.global_position + (door_at - p.global_position) * 0.4 + Vector3.UP * 1.6 + inward.cross(Vector3.UP) * 2.0, door_at + Vector3.UP * 1.0, 52.0)
		await Cutscene.walk(pip, p.global_position + (door_at - p.global_position).normalized() * 1.6, 3.0)
		Cutscene.face(pip, p.global_position)
		Cutscene.face(p, pip.global_position)
		Cutscene.play(pip, &"bow")
		Story._close_on(pip, 1.0, 2.2, 1.2)
	await Cutscene.wait(0.8)
	if pip:
		Cutscene.play(pip, &"talk")
	await Cutscene.say([
		"Oh, thank the goddesses, you're up! Sir Gigglebuns the Fourth? Of course you are, who else lives here. I'm *Pip*, page to His Majesty the King.",
		"I ran all the way from Castle Town. The King sends for you, sir. Well... he sent me. And now I'm sending you.",
		"Last night the watch on the castle walls saw fire in the far east, where nothing should be burning. And the court seer woke up screaming one word: *Gauntlet*.",
		"The King says the old stories are true. Before whatever is out there grows strong, the *Bun Sword* must be found and drawn, and the legend says it answers only one who carries the three goddesses' pieces of the Bun.",
		"The road starts at the *Lake Shrine*, on *Mirror Lake*. Go *east* along the South Road; Mira of Mirror Lake lives on the shore, and she knows the lake better than anyone.",
	], PIP, pip)
	if pip:
		Cutscene.play(pip, &"happy")
	await Cutscene.say([
		"I have to run back before anyone notices I'm gone. Good luck, Sir Gigglebuns! I'll be at the castle square if you need news. I'm *always* where the news is!",
	], PIP, pip)
	if pip:
		await Cutscene.walk(pip, door_at + inward * 0.4, 3.4)
		pip.visible = false
	Sfx.play("door_open", -4.0, 0.0, 1.1)
	Progress.set_flag("ch1:summoned")
