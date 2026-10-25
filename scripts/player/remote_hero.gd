class_name RemoteHero
extends PlayerController
## Another player's hero in online co-op (Net). It thinks nothing for itself:
## it stands, faces and moves as its player reports, plays what they play
## (the whole body, the upper body, the sword out, the bow drawn, the trail)
## and wears the party's shared gear. Creatures (run on the host) chase and
## strike it like the host's own hero; their blows, and with PvP this
## player's own, are sent on to its player (Net.hit_remote_hero). A name
## floats over its head.

var peer_id := 0
var net_character := "gigglebuns"
var net_name := ""
var _to_pos := Vector3.ZERO
var _to_yaw := 0.0
var _net_dead := false
var _tag: Label3D


static func make(id: int, character_id: String, who: String) -> RemoteHero:
	var p: RemoteHero = (load("res://scenes/player/remote_hero.tscn") as PackedScene).instantiate()
	p.peer_id = id
	p.net_character = character_id
	p.net_name = who
	p.name = "Remote_%d" % id
	return p


func _ready() -> void:
	if net_character != "gigglebuns":
		use_character(net_character)
	health.max_health = Progress.max_health
	health.health = health.max_health
	add_to_group("remote_players")
	target_marker.top_level = true
	target_marker.visible = false
	model.set_sword_drawn(false)
	model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	model.set_outfit(Progress.tunic, Progress.vanity_on)
	var sword_box := get_node_or_null("SwordHitbox") as Area3D
	if sword_box:
		sword_box.monitoring = false
	collision_mask = 0
	trail = SwordTrail.new()
	trail.name = "SwordTrail"
	trail.blade = model.find_child("Sword", true, false) as Node3D
	add_child(trail)
	_fit_trail()
	_tag = Label3D.new()
	_tag.text = net_name
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.pixel_size = 0.006
	_tag.font_size = 40
	_tag.outline_size = 10
	_tag.modulate = Color(1.0, 0.92, 0.6)
	_tag.no_depth_test = true
	_tag.position = Vector3(0, 2.15 * float(Net.HEIGHTS.get(net_character, 1.0)), 0)
	add_child(_tag)
	_to_pos = global_position
	_to_yaw = rotation.y
	facing_yaw = _to_yaw


## With PvP on, the heroes' own blows and shots land on it too (it joins the
## creatures' hurtbox layer).
func set_pvp(on: bool) -> void:
	hurtbox.collision_layer = 8 | (16 if on else 0)


func apply_state(st: Dictionary) -> void:
	_to_pos = st.get("p", _to_pos)
	_to_yaw = float(st.get("y", _to_yaw))
	var sw := bool(st.get("sw", false))
	if sw != sword_drawn:
		sword_drawn = sw
		model.set_sword_drawn(sw)
	model.set_bow_out(bool(st.get("bo", false)))
	model.bow_nocked = bool(st.get("nk", false))
	var an := StringName(String(st.get("an", "")))
	var at := float(st.get("at", 0.0))
	var speed := float(st.get("as", 1.0))
	if an != &"" and model.anim.has_animation(an):
		if model.current_anim != an:
			model.play(an, 0.1, speed, true)
			model.anim.seek(at, true)
		else:
			model.anim.speed_scale = speed
			if absf(model.anim.current_animation_position - at) > 0.3 and speed >= 0.0:
				model.anim.seek(at, true)
	var up := String(st.get("up", ""))
	if up != _upper_name:
		_upper_name = up
		if UPPER_CLIPS.has(up):
			model.set_upper_clip(StringName(up), UPPER_CLIP_PATHS, UPPER_CLIPS[up])
		elif UPPER_POSES.has(up):
			model.set_upper_pose(UPPER_POSES[up])
	model.upper_weight = float(st.get("uw", 0.0))
	trail.emitting = bool(st.get("tr", false))
	trail.color = SwordTrail.RED if bool(st.get("tc", false)) else SwordTrail.WHITE
	health.max_health = int(st.get("mh", health.max_health))
	health.health = int(st.get("hp", health.health))
	_net_dead = bool(st.get("d", false))
	model.visible = bool(st.get("v", true))
	# The party's shared gear and tunic, as they change.
	model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	model.set_outfit(Progress.tunic, Progress.vanity_on)


func _physics_process(delta: float) -> void:
	if global_position.distance_to(_to_pos) > 4.0:
		global_position = _to_pos
	else:
		global_position = global_position.lerp(_to_pos, 1.0 - exp(-16.0 * delta))
	facing_yaw = lerp_angle(facing_yaw, _to_yaw, 1.0 - exp(-16.0 * delta))
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	if _tag:
		_tag.visible = not _net_dead


func take_hit(info: HitInfo) -> int:
	return Net.hit_remote_hero(self, info)


func is_dead() -> bool:
	return _net_dead
