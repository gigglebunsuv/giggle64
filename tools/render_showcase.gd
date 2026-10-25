extends Node
## The animation showcase (Beta 1.8.0): every one of the hero's animations
## played in a gallery with its name and where it comes from, then the new
## first-person item views, the impact frames, the parry and riposte, and a
## fidget, in real play. Windowed, recorded by Movie Maker:
##   Godot --path <project> --resolution 1280x720 --fixed-fps 30
##     --write-movie <dir>/f.avi res://tools/render_showcase.tscn
##     -- --automation --out=<dir> [--only=gallery|play]
## The game viewport is saved as <dir>/c<frame>.jpg while it records (Movie
## Maker's own frames come at the window's size, so its sound is what is
## used); _giggle64_work/showcase/make_showcase.py makes the video.

const FPS := 30.0

var _args := {}
var _main: Node
var _frame := 0
var _out := ""
var _recording := false
var _saves: Array[int] = []
var _hide_hud := true
var p: PlayerController
var _cam: Camera3D
var _orbit := false
var _orbit_center := Vector3.ZERO
var _orbit_yaw := 0.0
var _orbit_speed := 0.35
var _orbit_r := 3.8
var _orbit_h := 0.45
## [{frame, title, sub, card?}] in order: what the encoder writes over the picture.
var _captions: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	GameManager.widescreen = true
	GameManager.render_index = int(_args.get("res", "2"))
	GameManager.smoothing = true
	GameManager.guide_beacon = false
	GameManager.minimap_enabled = false
	GameManager.skip_title = true
	var mi := AudioServer.get_bus_index("Music")
	if mi >= 0:
		AudioServer.set_bus_mute(mi, true)
	_out = _args.get("out", "")
	RenderingServer.frame_post_draw.connect(_grab)
	var only: String = _args.get("only", "")
	await _boot("field")
	if only == "" or only == "gallery":
		await _gallery()
	if only == "" or only == "play":
		await _play()
	await _title_card("GIGGLE 64", "BETA 1.8.0 - EVERY ANIMATION, REWORKED", 3.0)
	_recording = false
	for t in _saves:
		WorkerThreadPool.wait_for_task_completion(t)
	_saves.clear()
	_captions.append({"frame": _frame, "title": "", "sub": "", "end": true})
	if _out != "":
		var f := FileAccess.open(_out.path_join("captions.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(_captions, "  "))
		f.close()
	await _frames(2)
	get_tree().quit()


func _process(delta: float) -> void:
	_frame += 1
	if _main:
		var vp := _main.get_node_or_null("GameView/GameViewport")
		if vp:
			for n in ["TransitionLayer", "DebugLayer"]:
				var l := vp.get_node_or_null(n) as CanvasLayer
				if l:
					l.visible = false
			var hud := vp.get_node_or_null("HUD") as CanvasLayer
			if hud:
				hud.visible = not _hide_hud
		World.title_alpha = 0.0
	if _orbit and _cam:
		# Movie Maker paces frames: the orbit turns by frame, not by game time.
		_orbit_yaw += _orbit_speed / FPS
		var eye := _orbit_center + Vector3(sin(_orbit_yaw) * _orbit_r, _orbit_h, cos(_orbit_yaw) * _orbit_r)
		_cam.global_position = eye
		_cam.look_at(_orbit_center, Vector3.UP)
		_cam.current = true


# --- Booting, frames and captions ------------------------------------------------

func _boot(area: String, entrance := "") -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(2)
	GameManager.start_game()
	World.fade = 0.0
	World.title_alpha = 0.0
	World.title_duration = 0.0
	await _frames(30)
	p = GameManager.player
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
	_cam = Camera3D.new()
	_cam.fov = 42.0
	World.area_node.add_child(_cam)


## The caption from this frame on (make_showcase.py draws it on).
func caption(title: String, source := "") -> void:
	_captions.append({"frame": _frame, "title": title, "sub": source})
	print("showcase: %d %s" % [_frame, title])


## A title card over the next `secs` (drawn by make_showcase.py too).
func _title_card(title: String, sub: String, secs: float) -> void:
	_recording = true
	_captions.append({"frame": _frame, "title": title, "sub": sub, "card": true})
	await _secs(secs)
	_captions.append({"frame": _frame, "title": "", "sub": ""})


func _grab() -> void:
	if _out == "" or _main == null or not _recording:
		return
	var vp := _main.get_node_or_null("GameView/GameViewport") as SubViewport
	if vp == null:
		return
	var path := _out.path_join("c%06d.jpg" % _frame)
	var img := vp.get_texture().get_image()
	_saves.append(WorkerThreadPool.add_task(func() -> void: img.save_jpg(path, 0.92)))
	while _saves.size() > 12:
		WorkerThreadPool.wait_for_task_completion(_saves.pop_front())


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _secs(s: float) -> void:
	await _frames(int(round(s * FPS)))


# --- The gallery ------------------------------------------------------------------

## The hero held still (no controller) on open ground, the camera circling.
func _stage() -> void:
	p.set_physics_process(false)
	p.input_enabled = false
	p.velocity = Vector3.ZERO
	var at := Vector3(0, 0, 0)
	var hit := p.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 60, 0), Vector3(0, -60, 0)))
	if not hit.is_empty():
		at = hit.position
	p.global_position = at
	p.rotation.y = 0.0
	p.model.position = Vector3.ZERO
	_orbit_center = at + Vector3.UP * 1.0
	_orbit_yaw = deg_to_rad(-40.0)
	_orbit = true


func _reset_model() -> void:
	var m := p.model
	m.set_upper_pose({})
	m.upper_weight = 0.0
	m.stop_upper()
	m.bow_nocked = false
	m.set_bow_out(false)
	m.set_boomerang_in_hand(false)
	m.show_prop("", 0.0)
	m.aim_pitch = 0.0
	m.set_arms_only(false)
	m.visible = true
	p._show_hookshot(false)
	p._show_bloom_rod(false)
	p.items._show_mallet(false)
	p.items._show_tool("")
	m.set_shield_on_back(false)


## Plays `anim` (looped or twice through) under a caption.
func _show(anim: StringName, title: String, source: String, sword := true, secs := 0.0, setup := Callable()) -> void:
	_reset_model()
	p.model.set_sword_drawn(sword)
	if setup.is_valid():
		setup.call()
	caption(title, source)
	var a := p.model.anim.get_animation(anim)
	if a == null:
		push_warning("showcase: no animation " + anim)
		return
	var loop := a.loop_mode != Animation.LOOP_NONE
	var hold := secs if secs > 0.0 else (maxf(a.length * 2.0, 2.4) if loop else 0.0)
	if loop:
		p.model.play(anim, 0.15, 1.0, true)
		await _secs(hold)
	else:
		for i in 2:
			p.model.play(anim, 0.12, 1.0, true)
			await _secs(a.length + 0.45)


## An item's upper-body animation over the standing body.
func _show_upper(clips: Array, title: String, source: String, setup: Callable) -> void:
	_reset_model()
	p.model.set_sword_drawn(false)
	setup.call()
	caption(title, source)
	p.model.play(&"idle", 0.1, 1.0, true)
	for c: Array in clips:
		var clip: StringName = c[0]
		var loop: bool = PlayerController.UPPER_CLIPS.get(String(clip), false)
		p.model.set_upper_clip(clip, PlayerController.UPPER_CLIP_PATHS, loop)
		p.model.upper_weight = 1.0
		if c.size() > 2:
			(c[2] as Callable).call()
		await _secs(c[1])


func _gallery() -> void:
	_hide_hud = true
	_stage()
	await _frames(5)
	await _title_card("GIGGLE 64 - ANIMATION SHOWCASE", "SIR GIGGLEBUNS IV, EVERY MOVE (BETA 1.8.0)", 3.0)

	# Getting about.
	await _show(&"idle", "IDLE", "Breathing, the weight drifting foot to foot - OoT link_normal_wait", false)
	await _show(&"walk", "WALK", "Heel strike to toe-off, shoulders against the hips - OoT link_normal_walk", false)
	await _show(&"run", "RUN", "Forward lean, high knees, fists pumping - OoT / Twilight Princess run", false)
	await _show(&"run_sword", "RUN, SWORD DRAWN", "The blade held low and level at his side - OoT")
	await _show(&"sidestep", "Z-TARGET SIDE STEP", "Shuffling round a foe behind the shield - OoT")
	await _show(&"turn", "TURN IN PLACE", "Stepping round on the spot - OoT", false)
	await _show(&"jump", "LEDGE LEAP", "A stride into the air off an edge - OoT link_normal_jump", false)
	await _show(&"fall", "FALLING", "Arms wheeling for balance, legs pedalling - OoT link_normal_fall_wait", false)
	await _show(&"land", "LANDING", "Squash, rebound, stand - OoT link_normal_landing", false)
	await _show(&"land_hard", "HARD LANDING", "Slammed onto a knee, stunned, up again - OoT landing_damage", false)
	await _show(&"roll", "ROLL", "A dive, a tight tuck round once, up out of a crouch - OoT 20-frame roll")
	await _show(&"backflip", "BACKFLIP", "Arms swung overhead as he springs back - OoT Z-target backflip")
	await _show(&"sidehop_l", "SIDE HOP", "Legs tucked, leaning into the hop - OoT")
	await _show(&"bonk", "BONK", "Rolled into a wall and sat down hard - OoT", false)
	await _show(&"slope_slip", "SLIDING DOWNHILL", "Crouched, arms out - OoT down_slope_slip", false)

	# Standing still: the fidgets (Player_ChooseNextIdleAnim).
	await _show(&"idle_look", "FIDGET: LOOKING AROUND", "OoT link_normal_wait_typeA", false)
	await _show(&"idle_cold", "FIDGET: THE COLD (FROSTPEAK)", "Shivering, then a sneeze - OoT wait_typeC", false)
	await _show(&"idle_hot", "FIDGET: THE HEAT (DESERT, CINDERS)", "Mopping his brow - OoT wait_typeB", false)
	await _show(&"idle_stretch", "FIDGET: STRETCH", "OoT wait_typeD", false)
	await _show(&"idle_tunic", "FIDGET: TUGGING HIS TUNIC STRAIGHT", "OoT wait_itemA", false)
	await _show(&"idle_feet", "FIDGET: KNOCKING THE DIRT OFF HIS BOOTS", "OoT wait_itemB", false)
	await _show(&"idle_shield", "FIDGET: SETTING HIS SHIELD", "OoT wait_itemC", false)
	await _show(&"idle_sword", "FIDGET: A PRACTICE SWING", "OoT wait_itemD1 (sword drawn)")
	await _show(&"idle_crit_start", "FIDGET: CRITICAL HEALTH", "Doubled over, hands on knees - OoT wait_heat1", false)
	await _show(&"idle_crit", "FIDGET: CRITICAL HEALTH (LOOP)", "Heaving for breath - OoT wait_heat2", false, 3.2)
	await _show(&"idle_battle", "BATTLE STANCE (LOCKED ON)", "Low, shield up, the point on the foe - OoT Z-target wait")

	# The sword and shield, the trail behind every stroke (the 1998 builds' sheet).
	_orbit_speed = 0.25
	p.trail.emitting = true
	p.trail.color = SwordTrail.WHITE
	await _show(&"slash_left", "FOREHAND CUT", "Right to left, edge first - OoT Lside_kiru")
	await _show(&"slash_right", "BACKHAND CUT", "Left to right - OoT Rside_kiru")
	await _show(&"slash_down", "VERTICAL CHOP", "Over the shoulder and down - OoT normal_kiru")
	await _show(&"stab", "THRUST", "Z-target, stick forward - OoT pierce_kiru")
	await _show(&"slash_left_fin", "FINISHER: FOREHAND", "Third cut of a kind - OoT *_kiru_finsh")
	await _show(&"slash_down_fin", "FINISHER: CHOP", "OoT normal_kiru_finsh")
	await _show(&"stab_fin", "FINISHER: THRUST", "OoT pierce_kiru_finsh")
	await _show(&"jumpslash", "JUMP SLASH", "Sprung up, blade high behind - OoT Lpower_jump_kiru")
	await _show(&"jumpslash_land", "JUMP SLASH: THE CHOP", "OoT Lpower_jump_kiru_hit / _end")
	await _show(&"spin_charge", "GREAT SPIN: CHARGING", "OoT spin attack charge")
	p.trail.color = SwordTrail.RED
	await _show(&"spin_attack", "GREAT SPIN", "OoT spin attack - its trail red, as in the 1998 builds")
	p.trail.color = SwordTrail.WHITE
	await _show(&"shield_bash", "SHIELD BASH", "Twilight Princess shield attack")
	await _show(&"block", "SHIELD UP (Z-TARGET)", "OoT")
	await _show(&"block_crouch", "CROUCHED GUARD", "OoT defense without Z")
	await _show(&"block_crouch_hit", "GUARD TAKES A BLOW", "OoT")
	await _show(&"parry", "PARRY", "A flick of the shield - Dark Souls parry")
	await _show(&"riposte", "RIPOSTE", "Run through, held, twisted, shoved off - Dark Souls riposte")
	await _show(&"sheathe", "SHEATHING, WITH A FLOURISH", "The blade twirled first - Twilight Princess")
	p.trail.emitting = false
	await _show(&"hurt", "HIT FROM THE FRONT", "Thrown back - OoT damage")
	await _show(&"hurt_back", "HIT FROM BEHIND", "Pitched forward - OoT damage")
	await _show(&"death", "FALLING IN BATTLE", "Knees give, then face down - OoT game over")

	# The aimed items, from the side (the first-person views follow in play).
	_orbit_speed = 0.2
	var bow_up := func() -> void:
		p.model.set_bow_out(true)
		p.model.bow_nocked = true
	var loosed := func() -> void: p.model.bow_nocked = false
	var nocked := func() -> void: p.model.bow_nocked = true
	await _show_upper([[&"bow_ready", 0.6], [&"bow_wait", 1.4], [&"bow_shoot", 0.8, loosed], [&"bow_next", 0.6, nocked], [&"bow_wait", 1.0], [&"bow_shoot", 0.9, loosed]],
		"THE BOW: NOCK, DRAW, HOLD, LOOSE, NEXT", "OoT bow_bow_ready / _wait / _shoot_next - the string drawn to the fist", bow_up)
	await _show_upper([[&"hook_ready", 0.7], [&"hook_wait", 1.2], [&"hook_fire", 1.0]], "THE HOOKSHOT", "OoT hook_shot_ready / hook_wait - held like a pistol",
		func() -> void: p._show_hookshot(true))
	await _show_upper([[&"rod_ready", 0.7], [&"rod_wait", 1.0], [&"rod_flick", 1.0]], "THE BLOOM ROD", "Aimed like a wand, flicked",
		func() -> void: p._show_bloom_rod(true))
	await _show_upper([[&"boom_ready", 0.5], [&"boom_wait", 1.0], [&"boom_throw", 0.9, func() -> void: p.model.set_boomerang_in_hand(true)],
		[&"boom_catch", 0.9, func() -> void: p.model.set_boomerang_in_hand(true)]],
		"THE BOOMERANG: WIND UP, THROW, CATCH", "OoT boom_throw_wait2waitR / boom_throwR / boom_catch", func() -> void: p.model.set_boomerang_in_hand(true))

	# The other items.
	_orbit_speed = 0.3
	var bottle := func(content: String) -> Callable:
		return func() -> void: p.model.show_prop("res://assets/models/bottle_%s_mesh.tres" % content, 999.0, PlayerController.BOTTLE_GRIP)
	await _show(&"bottle_swing", "BOTTLE: CATCHING A FAIRY", "OoT link_bottle_bug_in", false, 0.0, bottle.call("empty"))
	await _show(&"drink", "BOTTLE: DRINKING", "OoT link_bottle_drink_demo", false, 0.0, bottle.call("red_potion"))
	await _show(&"bottle_release", "BOTTLE: LETTING IT OUT", "OoT bottle release", false, 0.0, bottle.call("fairy"))
	await _show(&"nut_throw", "PUFF NUT", "OoT Deku Nut throw", false)
	await _show(&"mallet_swing", "IRON MALLET", "Both hands, overhead and down - OoT link_hammer_hit", false, 0.0, func() -> void: p.items._show_mallet(true))
	await _show(&"dig", "GRAVE SPADE", "Driven in, levered back - Majora's Mask shovel", false, 0.0, func() -> void: p.items._show_tool("grave_spade_mesh"))
	await _show(&"ember_flick", "EMBER ROD", "Cocked and flicked - A Link to the Past Fire Rod", false, 0.0, func() -> void: p.items._show_tool("ember_rod_mesh"))
	await _show(&"staff_cast", "SAPPHIRE STAFF", "Raised, then pointed at the spot", false, 0.0, func() -> void: p.items._show_tool("sapphire_staff_mesh"))
	await _show(&"flail_hurl", "IRON FLAIL", "Wound back, hurled, hauled in - A Link to the Past Ball and Chain", false, 0.0, func() -> void: p.items._show_tool("iron_flail_handle_mesh"))
	await _show(&"cast_harvest", "ALAN'S HARVEST", "Prayer, then arms open - OoT Nayru's Love (tamashii)", false)
	await _show(&"cast_gale", "APHIEL'S GALE", "Arms thrown up and wide - OoT Farore's Wind (kaze)", false)
	await _show(&"cast_ruin", "SERIELYE'S RUIN", "Fists up, then punched into the earth - OoT Din's Fire (honoo)", false)
	await _show(&"cast_dream", "LOTHELYE'S DREAM", "Hands raised to the sky", false)
	await _show(&"lift", "LIFTING", "OoT carryB", false)
	await _show(&"throw_carry", "THROWING", "OoT throw", false)
	await _show(&"item_get", "TREASURE!", "OoT get-item pose", false)
	await _show(&"pull", "DRAGGING A STONE", "Questlord's Gauntlets", false)

	# Climbing, swimming, the chain, the saddle and the story.
	await _show(&"jump_reach", "JUMPING FOR A LEDGE", "OoT 250jump_start", false)
	await _show(&"hang", "HANGING", "OoT jump_climb_hold / _wait", false)
	await _show(&"hang_up", "PULLING UP", "OoT jump_climb_up", false)
	await _show(&"climb_low", "STEPPING UP", "OoT 100step_up", false)
	await _show(&"climb_high", "CLIMBING UP", "OoT 150step_up", false)
	await _show(&"ladder_climb", "LADDER", "OoT climb_upL / climb_upR", false)
	await _show(&"swim", "SWIMMING", "Breaststroke - OoT link_swimer_swim", false)
	await _show(&"swim_wait", "TREADING WATER", "OoT link_swimer_swim_wait", false)
	await _show(&"dive", "DIVING", "OoT swim_deep_start", false)
	await _show(&"hook_fly", "FLYING ON THE CHAIN", "OoT link_hook_fly_start / _wait", false, 0.0, func() -> void: p._show_hookshot(true))
	await _show(&"ride", "RIDING", "OoT uma", false)
	await _show(&"ride_gallop", "GALLOPING", "OoT uma", false)
	await _show(&"kneel", "THE KNIGHTING", "Chapter V", false)
	await _show(&"sleep", "ASLEEP", "The opening", false, 3.0)
	await _show(&"wake", "WAKING", "OoT's Link waking in his house", false)
	_reset_model()
	_orbit = false
	caption("")


# --- In play ------------------------------------------------------------------------

func _play() -> void:
	if _orbit_center == Vector3.ZERO:
		_stage()
	p.set_physics_process(true)
	_hide_hud = false
	_orbit = false
	_cam.current = false
	p.input_enabled = true
	var cam: AdventureCamera = World.area_node.get_node("CameraRig")
	var prog := Progress
	for id in ["bow", "hookshot", "boomerang", "bloom_rod"]:
		prog.give_item(id)
	prog.arrows = 30
	# Open ground in the middle of the field (the gallery's spot).
	_reset_model()
	p.global_position = _orbit_center - Vector3.UP * 1.0 + Vector3.UP * 0.2
	p.velocity = Vector3.ZERO
	p.face_direction(Vector3(0, 0, -1))
	p.rotation.y = p.facing_yaw
	cam.snap_behind_target()
	await _secs(0.5)
	_recording = true

	# First person: the bow.
	caption("FIRST PERSON: THE BOW", "OoT's bow view: the eye 14 units behind the head, the bow canted, the string drawn to the fist")
	prog.assign("item_x", "bow")
	p.debug_bow_hold = true
	p._use_item("item_x")
	await _secs(1.6)
	p.debug_bow_hold = false
	await _secs(1.0)
	caption("FIRST PERSON: THE NEXT ARROW", "OoT bow_bow_shoot_next")
	p.debug_bow_hold = true
	p._bow_ready()
	await _secs(1.4)
	p.debug_bow_hold = false
	await _secs(1.0)
	p._leave_first_person()
	await _secs(0.6)

	caption("FIRST PERSON: THE HOOKSHOT", "Held out like a pistol, low at the right, pointing at the reticle - Majora's Mask / OoT")
	prog.assign("item_x", "hookshot")
	p.debug_bow_hold = true
	p._use_item("item_x")
	await _secs(1.5)
	p.debug_bow_hold = false
	await _secs(1.8)
	p._leave_first_person()
	await _secs(0.6)

	caption("FIRST PERSON: THE BLOOM ROD", "Cocked and flicked, the seed away")
	prog.assign("item_x", "bloom_rod")
	p.debug_bow_hold = true
	p._use_item("item_x")
	await _secs(1.4)
	p.debug_bow_hold = false
	await _secs(1.2)
	p._leave_first_person()
	await _secs(0.6)

	caption("THE BOOMERANG: AIMED, THROWN, CAUGHT", "OoT boom_throw_waitR / boom_throwR / boom_catch")
	prog.assign("item_x", "boomerang")
	p.debug_bow_hold = true
	p._use_item("item_x")
	await _secs(1.3)
	p.debug_bow_hold = false
	await _secs(3.2)

	# The sword trails in play.
	await _home()
	caption("SWORD TRAILS", "Broad glassy sheets after the 1998 builds of the classic - the Great Spin's in red")
	prog.set_flag(PlayerCombat.TECH_SPIN)
	_side_view(1.0)
	for i in 3:
		await _tap("attack")
		await _secs(0.45)
	await _secs(0.5)
	Input.action_press("attack")
	await _secs(1.6)
	Input.action_release("attack")
	await _secs(1.4)

	# Impact frames on a combo.
	caption("IMPACT FRAMES", "The world holds still as the blade bites, then eases back - Wind Waker / Twilight Princess")
	await _home()
	var goblin := _spawn("res://scenes/enemies/basic_enemy.tscn", 1.4)
	_side_view(1.0)
	await _secs(0.5)
	for i in 3:
		await _tap("attack")
		await _secs(0.42)
	await _secs(1.2)
	caption("A FINISHER: A HEAVIER HOLD AND A FLASH", "The third cut of a kind")
	if is_instance_valid(goblin):
		goblin.queue_free()
	goblin = _spawn("res://scenes/enemies/basic_enemy.tscn", 1.4)
	await _secs(0.3)
	for i in 3:
		await _tap("attack")
		await _secs(0.5)
	await _secs(1.5)
	if is_instance_valid(goblin):
		goblin.queue_free()

	# The parry and riposte.
	caption("PARRY", "A Shield Bash timed to the blow - the frame held, time slowed (Dark Souls)")
	prog.give_shield("iron")
	prog.set_flag(PlayerCombat.TECH_BASH)
	prog.set_flag(PlayerCombat.TECH_PARRY)
	await _home()
	var knight := _spawn("res://scenes/enemies/barrow_knight.tscn", 1.8)
	_side_view(-1.0)
	await _secs(0.6)
	Input.action_press("shield")
	await _secs(0.4)
	if knight.model and knight.model.anim.has_animation(&"attack"):
		knight.model.play(&"attack", 0.05, 1.0, true)
	await _secs(0.25)
	await _tap("interact")
	var info := HitInfo.new()
	info.damage = 2
	info.attacker = knight
	info.source_position = knight.global_position
	_log("before parry")
	var res := p.take_hit(info)
	_log("parry result %d" % res)
	await _secs(0.5)
	Input.action_release("shield")
	caption("RIPOSTE", "B while the foe reels: the camera swings in, the blade goes through (Dark Souls)")
	_cam.current = false
	await _secs(0.15)
	_log("riposte?")
	await _tap("attack")
	await _frames(3)
	_log("after B")
	await _secs(2.4)
	_log("after riposte")
	if is_instance_valid(knight):
		knight.queue_free()

	# A fidget in play.
	caption("STANDING AT CRITICAL HEALTH", "He bends over panting until he is out of danger - OoT")
	_cam.current = false
	cam.snap_behind_target()
	p.health.health = 1
	p.face_direction(Vector3(1, 0, 0.3))
	for i in 14:
		await _secs(0.5)
		_log("crit")
	p.health.health = p.health.max_health
	caption("")


## Back to the open ground in the middle of the field, facing north, settled.
func _home() -> void:
	p.global_position = _orbit_center - Vector3.UP * 1.0 + Vector3.UP * 0.2
	p.velocity = Vector3.ZERO
	p.face_direction(Vector3(0, 0, -1))
	p.rotation.y = p.facing_yaw
	await _secs(0.4)


func _spawn(path: String, dist: float) -> Enemy:
	var e: Enemy = (load(path) as PackedScene).instantiate()
	World.area_node.add_child(e)
	e.global_position = p.global_position + p.forward() * dist
	e.look_at(p.global_position, Vector3.UP)
	e.set_physics_process(false)
	return e


## The director's camera off to one side of the hero, looking across him.
func _side_view(side: float) -> void:
	var right := p.forward().cross(Vector3.UP).normalized()
	var at := p.global_position + p.forward() * 0.8 + Vector3.UP * 1.0
	_cam.global_position = at + right * side * 4.0 + Vector3.UP * 0.6 - p.forward() * 0.6
	_cam.look_at(at, Vector3.UP)
	_cam.current = true


func _log(what: String) -> void:
	print("showcase: %d %s | state %s anim %s pos %s riposte %.2f hp %d" % [_frame, what, PlayerController.State.keys()[p.state], p.model.current_anim,
		p.global_position, p._riposte_open, p.health.health])


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
