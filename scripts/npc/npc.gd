class_name Npc
extends Node3D
## A townsperson the hero can speak to with A ("SPEAK", OoT's DO_ACTION_SPEAK).
##
## Like OoT's NPCs (Npc_TrackPoint in z_actor.c) the head follows the hero when
## he is near, up to 70 degrees either side, and while talking the whole body
## turns to face him; afterward it turns back to where it was standing.
## The lines come from a script resource: a static `lines(npc) -> Array` in
## `lines_script` (see Dialogue for the page format).

@export var npc_name := ""
@export var lines_script: Script
## Head tracking range and speed.
@export var look_range := 6.0
@export var head_limit_deg := 70.0
@export var turn_speed := 5.0
## Turn the whole body to the hero while talking (seated people only turn their heads).
@export var turn_body := true
## A sibling NPC (node name) this one is sweet on: while the partner is being
## talked to, this one blushes and plays "shy".
@export var partner_name := ""
## The pose while not talking (Pink stands instead of hammering in the castle).
@export var idle_anim: StringName = &"idle"
## Only here once this flag is set, and gone once `hide_flag` is (the
## castle folk at Himeko's palace after the fall; "" = always).
@export var show_flag := ""
@export var hide_flag := ""

var model: CharacterModel
var talking := false
## Times this NPC has been spoken to (the lines can depend on it).
var talks := 0
var _home_yaw := 0.0
var _anim: StringName = &"idle"
var _look := Vector2.ZERO
var _partner: Npc
## Treasures to hand over (GetItem ids) once the conversation ends; the lines
## script's on_event adds them.
var gifts: Array[String] = []
## A cutscene's pose for this person ("" = their own behavior).
var cs_anim: StringName = &""


func _ready() -> void:
	if (show_flag != "" and not Progress.flag(show_flag)) or (hide_flag != "" and Progress.flag(hide_flag)):
		queue_free()
		return
	add_to_group("interactable")
	add_to_group("npcs")
	model = get_node_or_null("Model") as CharacterModel
	_home_yaw = rotation.y
	Dialogue.page_started.connect(_on_page)
	if partner_name != "":
		_partner = get_parent().get_node_or_null(partner_name) as Npc


func interact_label() -> String:
	return "SPEAK"


func interact(player: Node) -> void:
	if talking or Dialogue.active:
		return
	talking = true
	# After the true ending, the people you know have a word about it
	# (EpilogueLines, Beta 1.5.0), every other time.
	var script: Array = EpilogueLines.lines(self)
	if script.is_empty():
		script = lines_script.call("lines", self) if lines_script else ["..."]
	talks += 1
	if player is PlayerController:
		(player as PlayerController).begin_talk(self)
	Dialogue.start(script, self)
	await Dialogue.finished
	# Gifts promised during the talk, each with OoT's get-item fanfare.
	while not gifts.is_empty() and player is PlayerController and is_instance_valid(player):
		await GetItem.present(player as PlayerController, gifts.pop_front())
	talking = false
	_anim = idle_anim
	if player is PlayerController and is_instance_valid(player):
		(player as PlayerController).end_talk()


func _on_page(page: Dictionary) -> void:
	if Dialogue.speaker == self:
		_anim = StringName(page.get("anim", "talk"))
		if page.has("event") and lines_script:
			lines_script.call("on_event", self, String(page.event))


func _process(delta: float) -> void:
	if model == null:
		return
	if cs_anim != &"":
		if model.anim.has_animation(cs_anim):
			model.play(cs_anim, 0.25)
		model.look = model.look.lerp(Vector2.ZERO, 1.0 - exp(-6.0 * delta))
		return
	var player := GameManager.player
	var want := Vector2.ZERO
	var body_target := _home_yaw
	if is_instance_valid(player):
		var to := player.global_position - global_position
		var flat := Vector2(to.x, to.z)
		if flat.length() < look_range or talking:
			var yaw := atan2(-to.x, -to.z)
			if talking and turn_body:
				body_target = yaw
			var rel := angle_difference(rotation.y, yaw)
			var limit := deg_to_rad(head_limit_deg)
			if absf(rel) < deg_to_rad(110.0) or talking:
				want.x = clampf(rel, -limit, limit)
				var eye_y := global_position.y + 1.6
				want.y = clampf(atan2((player.global_position.y + 1.5) - eye_y, flat.length()), -0.4, 0.4)
	if talking and _anim == &"huff":
		want = Vector2.ZERO   # looking pointedly away
	rotation.y += angle_difference(rotation.y, body_target) * (1.0 - exp(-turn_speed * delta))
	_look = _look.lerp(want, 1.0 - exp(-6.0 * delta))
	model.look = _look
	var anim := _anim if talking else idle_anim
	# On their feet (standing or on guard), people who sit by default (the
	# Questlords, whose plain "talk" is seated) talk standing: their own
	# "stand_" pose for it, or the plain standing talk.
	if talking and idle_anim in [&"stand", &"guard"] and model.anim.has_animation(&"stand_talk") 			and not String(anim).begins_with("stand"):
		var standing := StringName("stand_" + String(anim))
		anim = standing if model.anim.has_animation(standing) else &"stand_talk"
	var shy := not talking and _partner != null and _partner.talking
	if shy and model.anim.has_animation(&"shy"):
		anim = &"shy"
	model.set_blush(shy or (talking and _anim == &"shy"))
	model.play(anim, 0.25)
