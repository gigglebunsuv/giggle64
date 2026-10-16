extends Node
## Scripted scenes, after OoT's cutscene handling (z_demo.c, and the "manual"
## cutscenes actors run themselves, like BossGoma_Encounter in z_boss_goma.c):
## - Cutscene_StartManual / Player_SetCsActionWithHaltedActors: the hero stops
##   where he is and takes no orders (or blows) until the scene ends; other
##   creatures can be halted too.
## - Play_CreateSubCamera / Play_ChangeCameraStatus: a camera of the scene's own
##   takes over from the follow camera. Its eye and focus ("at") are moved
##   with Math_ApproachF (a fraction of the way each 20 Hz frame, capped at a
##   step in OoT units), or cut and glided between set shots.
## - Letterbox_SetSizeTarget(32): black bars 32 lines tall while it plays, and
##   the HUD fades away (Interface_ChangeHudVisibilityMode HUD_VISIBILITY_NOTHING).
## - Play_ReturnToMainCam: the follow camera picks up behind the hero again.
##
## A scene is a coroutine: `await Cutscene.begin()`, then shots, lines and
## actors, then `Cutscene.end()`. Text boxes may carry a speaker's "name".
##
## Skipping: a scene begun with an id is remembered as watched once it ends
## (GameManager.mark_seen, kept with the settings, across files). The next
## time it plays, START skips it: the picture goes black, the sound goes
## quiet, and the scene runs through at SKIP_SCALE times speed with every
## text box answered at once, so everything it sets up still happens.

signal started
signal ended

## Letterbox_SetSizeTarget(32) in z_demo.c.
const LETTERBOX := 32.0
## OoT units in meters, and its frame rate (Math_ApproachF steps per frame).
const UNIT := 0.03
const OOT_FPS := 20.0

## The time scale a skipped scene runs at.
const SKIP_SCALE := 12.0

var active := false
## The id of the scene playing ("" = none given: never skippable).
var scene_id := ""
## True while START is fast-forwarding a watched scene.
var skipping := false
var _scale_before := 1.0
var camera: Camera3D = null
## The scene camera's eye and focus point.
var eye := Vector3.ZERO
var at := Vector3.ZERO
var fov := 50.0
## Math_ApproachF targets: each 20 Hz frame eye and at move `fraction` of
## the way, at most `step` units.
var _eye_to := Vector3.ZERO
var _at_to := Vector3.ZERO
var _fraction := 0.0
var _step := 0.0
var _approaching := false
## A node the focus follows (with an offset), e.g. a boss rising.
var _track: Node3D = null
var _track_offset := Vector3.ZERO
var _tween: Tween = null
## Characters brought on for the scene (freed when it ends).
var actors: Array[Node3D] = []
## Creatures stopped for the scene.
var _halted: Array[Node] = []
## Quake (Quake_Request): amplitude in meters and time left.
var _shake := 0.0
var _shake_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Starts a scene: the hero halts and the letterbox closes in. With
## `halt_enemies` every creature but those in `keep` stands still.
func begin(halt_enemies := false, keep: Array = [], id := "") -> void:
	if id != "":
		# One scene running straight on into the next (the legend into the
		# takeover): the first was watched to its end.
		if active and scene_id != "" and scene_id != id:
			GameManager.mark_seen(scene_id)
		scene_id = id
	active = true
	_halted.clear()
	halt_player()
	if halt_enemies:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e in keep or not (e is Node) or (e as Node).process_mode == Node.PROCESS_MODE_DISABLED:
				continue
			(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
			_halted.append(e)
	started.emit()


## Player_SetCsActionWithHaltedActors: stops the current hero (again after an
## area change brings a new one).
func halt_player() -> void:
	var p := GameManager.player
	if is_instance_valid(p) and not p.is_dead():
		p.begin_cutscene()


## Play_ReturnToMainCam and Cutscene_StopManual: the follow camera takes over
## behind the hero, the actors leave and everything moves again.
func end(keep_actors := false) -> void:
	_approaching = false
	_track = null
	if _tween:
		_tween.kill()
	if is_instance_valid(camera):
		camera.queue_free()
	camera = null
	if not keep_actors:
		for a in actors:
			if is_instance_valid(a):
				a.queue_free()
		actors.clear()
	for e in _halted:
		if is_instance_valid(e):
			e.process_mode = Node.PROCESS_MODE_INHERIT
	_halted.clear()
	var p := GameManager.player
	if is_instance_valid(p):
		p.visible = true
		p.end_cutscene()
		if p.camera_rig:
			p.camera_rig.camera.current = true
			p.camera_rig.snap_behind_target()
	active = false
	GameManager.mark_seen(scene_id)
	scene_id = ""
	stop_skip()
	ended.emit()


## True when START would skip the scene playing (watched before).
func can_skip() -> bool:
	return active and not skipping and GameManager.has_seen(scene_id)


## Fast-forwards the scene playing (see the top of this file).
func skip() -> void:
	if not can_skip():
		return
	skipping = true
	_scale_before = Engine.time_scale
	Engine.time_scale = SKIP_SCALE
	World.stop_score()
	AudioServer.set_bus_mute(0, true)


## Back to normal time and sound (the scene ended, or the game reloads).
func stop_skip() -> void:
	if not skipping:
		return
	skipping = false
	Engine.time_scale = _scale_before
	AudioServer.set_bus_mute(0, false)
	AudioMix.apply_volumes()


func _process(_delta: float) -> void:
	if can_skip() and Input.is_action_just_pressed("pause") and not DebugMenu.combo_held():
		skip()


# --- Camera ---------------------------------------------------------------------

## Play_CreateSubCamera: the scene's camera, made current.
func _ensure_camera() -> void:
	if is_instance_valid(camera) and camera.is_inside_tree():
		return
	camera = Camera3D.new()
	camera.name = "CutsceneCamera"
	camera.near = 0.1
	camera.far = 300.0
	camera.fov = fov
	var parent: Node = World.area_node if is_instance_valid(World.area_node) else self
	parent.add_child(camera)
	camera.current = true
	_apply()


## Cuts straight to a shot.
func cut(eye_pos: Vector3, at_pos: Vector3, field := -1.0) -> void:
	_approaching = false
	_track = null
	if _tween:
		_tween.kill()
	eye = eye_pos
	at = at_pos
	if field > 0.0:
		fov = field
	_ensure_camera()
	_apply()


## Glides from the current shot to another over `time` seconds (eased).
func glide(eye_pos: Vector3, at_pos: Vector3, time: float, field := -1.0) -> void:
	_ensure_camera()
	_approaching = false
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(self, "eye", eye_pos, time)
	if _track == null:
		_tween.tween_property(self, "at", at_pos, time)
	if field > 0.0:
		_tween.tween_property(self, "fov", field, time)


## Math_ApproachF on every axis of eye and at: each 20 Hz frame they move
## `fraction` of the remaining way, by at most `step` OoT units.
func approach(eye_pos: Vector3, at_pos: Vector3, fraction: float, step: float) -> void:
	_ensure_camera()
	if _tween:
		_tween.kill()
	_eye_to = eye_pos
	_at_to = at_pos
	_fraction = fraction
	_step = step
	_approaching = true


## Keeps the focus on `node` (plus `offset`) until the next cut.
func track(node: Node3D, offset := Vector3.ZERO) -> void:
	_track = node
	_track_offset = offset


## Quake_Request: a short shake of the scene camera.
func shake(amplitude: float, seconds: float) -> void:
	_shake = amplitude
	_shake_left = seconds
	GameManager.rumble(clampf(amplitude * 3.0, 0.2, 1.0), seconds)


static func _approach_f(v: float, target: float, fraction: float, step: float) -> float:
	var s := clampf((target - v) * fraction, -step, step)
	return v + s


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(camera):
		return
	if _approaching:
		var frames := delta * OOT_FPS
		var step := _step * UNIT * frames
		var frac := 1.0 - pow(1.0 - clampf(_fraction, 0.0, 1.0), frames)
		for i in 3:
			eye[i] = _approach_f(eye[i], _eye_to[i], frac, step)
			if _track == null:
				at[i] = _approach_f(at[i], _at_to[i], frac, step)
	if is_instance_valid(_track):
		at = _track.global_position + _track_offset
	_shake_left = maxf(_shake_left - delta, 0.0)
	_apply()


func _apply() -> void:
	if not is_instance_valid(camera):
		return
	var e := eye
	if _shake_left > 0.0:
		e += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * minf(_shake_left * 4.0, 1.0)
	if e.distance_to(at) < 0.01:
		return
	var up := Vector3.UP if absf((at - e).normalized().y) < 0.98 else Vector3.BACK
	camera.global_transform = Transform3D(Basis.looking_at(at - e, up), e)
	camera.fov = fov


# --- Lines, actors and time -------------------------------------------------------

## Seconds of scene time (physics frames, so tests at a fixed rate agree).
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout


## Text boxes from `speaker_name` (shown on the box), the pose of `who`
## following the pages' "anim". Returns when the last box closes.
func say(pages: Array, speaker_name := "", who: Node = null) -> void:
	var out: Array = []
	for p in pages:
		var d: Dictionary = p.duplicate() if p is Dictionary else {"text": String(p)}
		if speaker_name != "" and not d.has("name"):
			d["name"] = speaker_name
		out.append(d)
	Dialogue.start(out, who)
	await Dialogue.finished
	# A beat between boxes, as OoT's scenes leave between lines.
	await wait(0.1)


## A character model (res://assets/models/<model>.tscn, a CharacterModel)
## standing at `pos` facing `yaw`, for this scene only unless `keep`.
func actor(model: String, pos: Vector3, yaw: float, anim := &"idle", keep := false) -> Node3D:
	var path := model if model.begins_with("res://") else "res://assets/models/%s.tscn" % model
	if not ResourceLoader.exists(path):
		push_warning("Cutscene: no model %s" % path)
		return null
	var m: Node3D = load(path).instantiate()
	m.name = "Actor_" + path.get_file().get_basename().to_pascal_case()
	var parent: Node = World.area_node if is_instance_valid(World.area_node) else self
	parent.add_child(m)
	m.global_position = pos
	m.rotation.y = yaw
	play(m, anim)
	if not keep:
		actors.append(m)
	return m


## Plays `anim` on an actor (or the hero) if it has it.
func play(who: Node3D, anim: StringName, blend := 0.2) -> void:
	if who is PlayerController:
		(who as PlayerController).cs_anim = anim
		return
	var cm := who as CharacterModel
	if cm and cm.anim and cm.anim.has_animation(anim):
		cm.play(anim, blend)


## Walks an actor (or the hero) to `to` at `speed` m/s playing `anim`, turned
## along the way; returns on arrival.
func walk(who: Node3D, to: Vector3, speed := 1.8, anim := &"walk") -> void:
	if not is_instance_valid(who):
		return
	var from := who.global_position
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	if flat.length() > 0.01:
		who.rotation.y = atan2(-flat.x, -flat.z)
		if who is PlayerController:
			(who as PlayerController).face_direction(flat)
	play(who, anim)
	var t := create_tween()
	t.tween_property(who, "global_position", to, from.distance_to(to) / maxf(speed, 0.01))
	await t.finished
	# Arrived on foot: people whose idle is a seated or busy pose (the
	# Questlords, Pink at her anvil) have a "stand" to stop in.
	var cm := who as CharacterModel
	play(who, &"stand" if cm and cm.anim and cm.anim.has_animation(&"stand") else &"idle")


## Turns an actor (or the hero) to look at `point`.
func face(who: Node3D, point: Vector3) -> void:
	var flat := Vector3(point.x - who.global_position.x, 0, point.z - who.global_position.z)
	if flat.length() < 0.01:
		return
	if who is PlayerController:
		(who as PlayerController).face_direction(flat)
	else:
		who.rotation.y = atan2(-flat.x, -flat.z)


# --- Boss encounters ----------------------------------------------------------------

## A boss's entrance, after BossGoma_Encounter: the scene camera starts just
## behind the hero looking past him into the lair, then glides across to
## frame the boss as it rises and cries out (its own AI keeps acting it out),
## the name card shows on the cry (TitleCard_InitBossName) with the boss
## music (SEQCMD_PLAY_SEQUENCE NA_BGM_BOSS), and the follow camera returns.
## Only the first meeting plays it: after that (EVENTCHKINF_BEGAN_*_BATTLE)
## the fight starts straight away with its music.
## `music` "miniboss" marks a mini-boss (World.start_battle picks its track).
func boss_intro(boss: Node3D, title: String, epithet: String, music := "boss_battle", focus_height := 2.0, distance := 7.0, length := 3.4) -> void:
	var kind := "miniboss" if music == World.MINIBOSS_TRACK else "boss"
	if is_instance_valid(boss):
		boss.set_meta("battle", kind)
	var seen := "boss_intro:%s:%s" % [World.area_id, title]
	if Progress.flag(seen) or active or not is_instance_valid(boss):
		World.start_battle(kind, music)
		return
	Progress.set_flag(seen)
	var p := GameManager.player
	if not is_instance_valid(p):
		World.show_boss_title(title, epithet)
		World.start_battle(kind, music)
		return
	begin()
	var focus := boss.global_position + Vector3.UP * focus_height
	var to_hero := p.global_position - boss.global_position
	to_hero.y = 0.0
	if to_hero.length() < 0.1:
		to_hero = Vector3(0, 0, 1)
	to_hero = to_hero.normalized()
	var side := Vector3(-to_hero.z, 0, to_hero.x)
	# Over the hero's shoulder, looking into the lair...
	cut(p.global_position + to_hero * 2.6 + side * 0.9 + Vector3.UP * 1.9, focus, 55.0)
	track(boss, Vector3.UP * focus_height)
	# ...then sweeping across to face the boss from the entrance side.
	approach(focus + to_hero * distance + side * distance * 0.35 + Vector3.UP * 0.6 - Vector3.UP * focus_height * 0.3, focus, 0.12, 60.0)
	await wait(0.7)
	if not active:
		return
	World.show_boss_title(title, epithet)
	World.start_battle(kind, music)
	shake(0.06, 0.8)
	await wait(length - 0.7)
	if active:
		end()
