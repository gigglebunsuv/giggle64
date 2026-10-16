class_name PlayerItems
extends Node
## The hero's newer items (alpha 1.6.0, "The Satchel"), kept apart from
## PlayerController's movement code. The controller hands them every X / Y
## press it does not handle itself (`use`), runs `state_update` while he is in
## State.ITEM, and `physics_update` every frame.
##
## - Puff Nuts (OoT's Deku Nuts): a quick throw; the nut bursts in a flash of
##   spores that stuns everything near it (PuffNut).
## - Iron Mallet (the Megaton Hammer): raised overhead and brought down two
##   steps ahead. The blow is heavy (it breaks brittle crust, boulders and
##   pots, and hits hard); the ground shakes and dazes foes standing close.
## - Lantern: hung at his belt, it lights the dark round him; held out next to
##   an unlit torch, it lights that instead (as ALttP's lamp does).
## - Mira's Looking Glass (the Lens of Truth): looked through in first
##   person, it shows what is hidden (group "lens_hidden") and shows the
##   false for what it is (group "lens_fake"); it draws a unit of magic every
##   half second (OoT drains the Lens at a steady rate).
## - The goddesses' blessings, after OoT's three spells (magic 12 each, and the
##   cast is OoT's raised-arms pose): Alan's Harvest heals three hearts in a
##   ring of green light and shakes loot from the shrubs round him; Aphiel's
##   Gale marks a point, then (Farore's Wind) carries him back to it in the
##   same place; Serielye's Ruin bursts outward in a blast of force (Din's
##   Fire, but no fire) that knocks foes back and breaks brittle things.
## - Fishing Rod: fish from any shore (a FishingSpot made on the spot).
## - Grave Spade (Chapter IV, OoT's... well, Majora's shovel): a stab of the
##   spade into the ground a step ahead. Soft earth (a DigSpot) gives up what
##   is buried there; any other soil now and then a Rupee or a heart; stone
##   just rings.
## - Sapphire Staff (Chapter IV): conjures a SapphireBlock two steps ahead
##   (magic 6), or dispels the one standing.
## - Ember Rod (Chapter V, ALttP's Fire Rod): a flick of the rod throws a
##   fireball (EmberBall) straight ahead (magic 2): it lights torches, burns
##   thorns and webs, melts rime-ice and scorches foes, the undead worst.
## - Iron Flail (Chapter V, Ridge Keep; ALttP's Ball and Chain): the ball is
##   hurled straight ahead (FlailBall) and swings back on its chain. It hits
##   hard, knocks an undead knight's shield aside (HitInfo.cleave) and breaks
##   what answers to it (group "flail_targets": barred gates, cracked
##   pillars, bells).
## - Lothelye's Dream (Chapter V, Beta 1.5.0; the last spell): cast with
##   raised arms, the hero dreams awake. While the Dream lasts the dream-light
##   of the astral way is solid under his feet (DreamLight "path") and the
##   waking world's veils are gone ("veil"); it draws a unit of magic every
##   DREAM_DRAIN seconds and ends when cast again, when the magic runs dry,
##   or on leaving the area.
## - Astral Seal: a story item; it only hums until its moment comes (cracked
##   since Firebuns broke free, it just hums sadly).

const HANDLED := ["puff_nuts", "iron_mallet", "fishing_rod", "lantern", "looking_glass", "alans_harvest", "aphiels_gale", "serielyes_ruin",
	"grave_spade", "sapphire_staff", "astral_seal", "ember_rod", "iron_flail", "lothelyes_dream"]
## The arrows the bow fires from each arrow item.
const ARROW_KINDS := {"sun_arrows": "sun", "frost_arrows": "frost", "starfall_arrows": "starfall"}
const HAND := "Hips/Torso/ShoulderR/ElbowR/HandR"
## The mallet: raised, then brought down (the jump slash's landing chop).
const MALLET_RAISE := 0.2
const MALLET_HIT := 0.28
const MALLET_END := 0.7
const MALLET_REACH := 1.25
const MALLET_RADIUS := 1.2
const MALLET_DAMAGE := 3
const MALLET_QUAKE := 3.2
## The spade: raised, then driven in a step ahead.
const DIG_HIT := 0.3
const DIG_END := 0.65
const DIG_REACH := 1.1
## Soft ground sometimes turns up a little something (Drops table).
const DIG_LUCK := 0.25
## The staff: the block goes down two steps ahead.
const STAFF_AT := 0.3
const STAFF_END := 0.6
const STAFF_REACH := 2.2
## The Ember Rod's flick: the fireball leaves at EMBER_AT.
const EMBER_AT := 0.12
const EMBER_END := 0.36
## The flail: wound back, the ball leaves at FLAIL_AT; he waits for it.
const FLAIL_AT := 0.22
const FLAIL_END := 0.9
## Puff Nut throw: released partway through the throw.
const NUT_RELEASE := 0.12
const NUT_END := 0.32
## A blessing: arms raised, the magic goes out at CAST_AT.
const CAST_AT := 0.35
const CAST_END := 0.9
const HARVEST_HEAL := 6
const HARVEST_RADIUS := 6.0
const RUIN_RADIUS := 4.5
const RUIN_DAMAGE := 4
## The Looking Glass takes a unit of magic every LENS_DRAIN seconds.
const LENS_DRAIN := 0.5
## Lothelye's Dream takes a unit of magic every DREAM_DRAIN seconds.
const DREAM_DRAIN := 0.75
## How close an unlit torch must be for the lantern to light it.
const LANTERN_REACH := 2.2

## How far the lit Starlight Lantern lays shades bare.
const STARLIGHT_REACH := 6.0
## The lantern stays lit from one area to the next.
static var lantern_lit := false
## The hero is dreaming (Lothelye's Dream): DreamLight reads it.
static var dreaming := false

var p: PlayerController
## The action under way in State.ITEM: "nut", "mallet", "harvest", "gale" or "ruin".
var action := ""
var _t := 0.0
var _fired := false
var _raised := false
## Looking through the Looking Glass.
var lens_on := false
var _drain := 0.0
var _dream_drain := 0.0
var _dream_light: OmniLight3D
var _lantern_light: OmniLight3D
var _lantern_mesh: MeshInstance3D
var _mallet: MeshInstance3D
var _tool: MeshInstance3D
## The marker standing at Aphiel's Gale's point, while in its area.
var _gale_marker: Node3D


func setup(player: PlayerController) -> void:
	p = player
	_lantern_light = OmniLight3D.new()
	_lantern_light.name = "LanternLight"
	_lantern_light.light_color = Color(1.0, 0.78, 0.45)
	_lantern_light.light_energy = 1.6
	_lantern_light.omni_range = 8.0
	_lantern_light.omni_attenuation = 1.3
	_lantern_light.shadow_enabled = false
	_lantern_light.position = Vector3(0.35, 1.0, -0.15)
	p.add_child(_lantern_light)
	# The Dream's light: a cold violet glow round him while he dreams.
	dreaming = false
	_dream_light = OmniLight3D.new()
	_dream_light.name = "DreamLight"
	_dream_light.light_color = Color(0.72, 0.62, 1.0)
	_dream_light.light_energy = 1.4
	_dream_light.omni_range = 7.0
	_dream_light.shadow_enabled = false
	_dream_light.position = Vector3(0, 1.2, 0)
	_dream_light.visible = false
	p.add_child(_dream_light)
	_lantern_mesh = MeshInstance3D.new()
	_lantern_mesh.name = "Lantern"
	_lantern_mesh.mesh = load("res://assets/models/lantern_mesh.tres") if ResourceLoader.exists("res://assets/models/lantern_mesh.tres") else null
	_lantern_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hips := p.model.get_node_or_null("Hips") as Node3D
	if hips:
		hips.add_child(_lantern_mesh)
		_lantern_mesh.position = Vector3(0.24, -0.12, -0.02)
	_show_lantern(lantern_lit and Progress.has_item("lantern"))
	Progress.changed.connect(_on_progress)
	_place_gale_marker.call_deferred()


static func handles(id: String) -> bool:
	return id in HANDLED


static func arrow_kind(id: String) -> String:
	return ARROW_KINDS.get(id, "")


func _on_progress() -> void:
	if lantern_lit and not Progress.has_item("lantern"):
		_show_lantern(false)


## An item button with one of these items on it. True when he took up an
## action (the controller stops looking at other input this frame).
func use(item: String, _button: String) -> bool:
	match item:
		"lantern":
			return _use_lantern()
		"looking_glass":
			return _use_lens()
		"fishing_rod":
			return _use_rod()
		"puff_nuts":
			if Progress.nuts <= 0:
				Sfx.play("error", -6.0)
				return false
			return _begin("nut")
		"iron_mallet":
			return _begin("mallet")
		"grave_spade":
			return _begin("dig")
		"sapphire_staff":
			if is_instance_valid(SapphireBlock.current):
				SapphireBlock.current.dispel()
				return false
			if Progress.magic < Progress.magic_cost(item):
				Sfx.play("error", -4.0)
				return false
			return _begin("staff")
		"astral_seal":
			_seal_hums()
			return false
		"ember_rod":
			if Progress.magic < Progress.magic_cost(item):
				Sfx.play("error", -4.0)
				return false
			return _begin("ember")
		"iron_flail":
			return _begin("flail")
		"lothelyes_dream":
			if dreaming:
				set_dream(false)
				return false
			if Progress.magic < Progress.magic_cost(item):
				Sfx.play("error", -4.0)
				return false
			return _begin("dream")
		"alans_harvest", "aphiels_gale", "serielyes_ruin":
			if not _can_act():
				Sfx.play("error", -6.0)
				return false
			if Progress.magic < Progress.magic_cost(item):
				Sfx.play("error", -4.0)
				return false
			if item == "aphiels_gale":
				return _ask_gale()
			return _begin({"alans_harvest": "harvest", "serielyes_ruin": "ruin"}[item])
	return false


## Standing on the ground with his hands free.
func _can_act() -> bool:
	return p.is_on_floor() and not p.is_carrying() and not p.fishing \
		and p.state in [PlayerController.State.IDLE, PlayerController.State.TURN, PlayerController.State.MOVE, PlayerController.State.LAND]


func _begin(kind: String) -> bool:
	if not _can_act():
		Sfx.play("error", -6.0)
		return false
	p._end_bow_z()
	p._cancel_boomerang()
	if kind in ["harvest", "gale", "ruin", "dream"]:
		p._clear_z_targeting()
	action = kind
	_t = 0.0
	_fired = false
	_raised = false
	p.speed_oot = 0.0
	p._change_state(PlayerController.State.ITEM)
	match kind:
		"nut":
			p.model.play(&"throw_carry", 0.04, 1.5, true)
		"mallet":
			p._set_sword_drawn(false)
			_show_mallet(true)
			p.model.play(&"jumpslash", 0.05, 1.0, true)
			Sfx.play("lift_pot", -6.0, 0.05, 0.7)
		"dig":
			p._set_sword_drawn(false)
			_show_tool("grave_spade_mesh")
			p.model.play(&"jumpslash", 0.05, 1.3, true)
		"ember":
			if not Progress.use_magic(Progress.magic_cost("ember_rod")):
				action = ""
				p._change_state(PlayerController.State.IDLE)
				return false
			p._set_sword_drawn(false)
			_show_tool("ember_rod_mesh")
			p.model.play(&"throw", 0.04, 1.6, true)
		"flail":
			p._set_sword_drawn(false)
			_show_tool("iron_flail_handle_mesh")
			p.model.play(&"throw", 0.06, 0.8, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.7)
		"staff":
			if not Progress.use_magic(Progress.magic_cost("sapphire_staff")):
				action = ""
				p._change_state(PlayerController.State.IDLE)
				return false
			p._set_sword_drawn(false)
			_show_tool("sapphire_staff_mesh")
			p.model.play(&"item_get", 0.08, 1.4, true)
			Sfx.play("magic_cast", -4.0, 0.0, 0.8)
		_:
			if Progress.use_magic(Progress.magic_cost({"harvest": "alans_harvest", "gale": "aphiels_gale", "ruin": "serielyes_ruin", "dream": "lothelyes_dream"}[kind])):
				p._set_sword_drawn(false)
				p.model.play(&"item_get", 0.08, 1.2, true)
				Sfx.play("magic_cast", -2.0, 0.0)
			else:
				action = ""
				p._change_state(PlayerController.State.IDLE)
				return false
	return true


## While in State.ITEM.
func state_update(delta: float) -> void:
	_t += delta
	p.speed_oot = move_toward(p.speed_oot, 0.0, p.stop_decel * p._frames(delta))
	if p.lock_target and is_instance_valid(p.lock_target):
		p._face_toward(p.lock_target.global_position, p.target_face_step, delta)
	p.move_yaw = p.facing_yaw
	var end := CAST_END
	match action:
		"nut":
			end = NUT_END
			if not _fired and _t >= NUT_RELEASE:
				_fired = true
				_throw_nut()
		"mallet":
			end = MALLET_END
			if not _raised and _t >= MALLET_RAISE:
				_raised = true
				p.model.play(&"jumpslash_land", 0.03, 1.0, true)
			if not _fired and _t >= MALLET_HIT:
				_fired = true
				_mallet_blow()
		"dig":
			end = DIG_END
			if not _raised and _t >= DIG_HIT * 0.6:
				_raised = true
				p.model.play(&"jumpslash_land", 0.03, 1.2, true)
			if not _fired and _t >= DIG_HIT:
				_fired = true
				_dig()
		"ember":
			end = EMBER_END
			if not _fired and _t >= EMBER_AT:
				_fired = true
				_throw_ember()
		"flail":
			end = FLAIL_END
			if not _fired and _t >= FLAIL_AT:
				_fired = true
				_throw_flail()
		"staff":
			end = STAFF_END
			if not _fired and _t >= STAFF_AT:
				_fired = true
				_conjure()
		"harvest", "ruin", "gale", "dream":
			if not _fired and _t >= CAST_AT:
				_fired = true
				match action:
					"dream": set_dream(true)
					"harvest": _cast_harvest()
					"ruin": _cast_ruin()
					"gale": _cast_gale()
	if _t >= end:
		p._change_state(PlayerController.State.IDLE)


## Leaving State.ITEM, finished or knocked out of it.
func end_action() -> void:
	action = ""
	_show_mallet(false)
	_show_tool("")


## Every frame.
func physics_update(delta: float) -> void:
	if lens_on:
		if not p.is_first_person() or p.is_dead():
			set_lens(false)
		else:
			_drain += delta
			while _drain >= LENS_DRAIN and lens_on:
				_drain -= LENS_DRAIN
				if not Progress.use_magic(1):
					set_lens(false)
					Sfx.play("error", -6.0)
			_reveal(delta)
	if dreaming:
		if p.is_dead():
			set_dream(false)
		else:
			_dream_drain += delta
			while _dream_drain >= DREAM_DRAIN and dreaming:
				_dream_drain -= DREAM_DRAIN
				if not Progress.use_magic(1):
					set_dream(false)
					Sfx.play("error", -6.0)
			_dream_light.light_energy = 1.3 + sin(Time.get_ticks_msec() * 0.004) * 0.25
	if _lantern_mesh and _lantern_mesh.visible:
		# A flicker, and the light goes out under water.
		_lantern_light.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.013) * 0.08 + sin(Time.get_ticks_msec() * 0.031) * 0.05
		if p.is_swimming():
			_show_lantern(false)
		elif starlight():
			_starlight_reveal(delta)


# --- Puff Nuts ------------------------------------------------------------------

func _throw_nut() -> void:
	if not Progress.use_nut():
		return
	var nut := PuffNut.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else p.get_parent()
	parent.add_child(nut)
	var dir := p.forward()
	if p.lock_target and is_instance_valid(p.lock_target):
		var to := p.lock_target.global_position - p.global_position
		to.y = 0.0
		if to.length() > 0.1:
			dir = to.normalized()
	nut.launch(p, p.global_position + Vector3.UP * 1.6 + dir * 0.4, dir)
	Sfx.play("throw", -4.0, 0.05, 1.3)


# --- Iron Mallet ----------------------------------------------------------------

func _show_mallet(on: bool) -> void:
	if _mallet == null and on:
		var hand := p.model.get_node_or_null(HAND) as Node3D
		if hand == null:
			return
		_mallet = MeshInstance3D.new()
		_mallet.name = "HandMallet"
		_mallet.mesh = load("res://assets/models/iron_mallet_mesh.tres") if ResourceLoader.exists("res://assets/models/iron_mallet_mesh.tres") else null
		_mallet.position = Vector3(0, -0.06, 0)
		hand.add_child(_mallet)
	if _mallet:
		_mallet.visible = on


## Where the mallet's head comes down.
func mallet_point() -> Vector3:
	return p.global_position + p.forward() * MALLET_REACH + Vector3.UP * 0.4


func _mallet_blow() -> void:
	var at := mallet_point()
	var hit := {}
	var space := p.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = MALLET_RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), at)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	var landed := false
	for h in space.intersect_shape(q, 24):
		var hb := h.collider as Hurtbox
		if hb == null or not hb.monitorable or hb.receiver == p or hit.has(hb.receiver):
			continue
		hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = MALLET_DAMAGE
		info.knockback = 7.0
		info.heavy = true
		info.attacker = p
		info.source_position = p.global_position
		if hb.receive_hit(info) == Hurtbox.Result.HIT:
			landed = true
	# Boulders and brittle things in reach crack under it (not walls: those
	# take a bomb).
	for n in p.get_tree().get_nodes_in_group("bombables"):
		var node := n as Node3D
		if node == null or hit.has(node) or node is BombWall or not node.is_inside_tree():
			continue
		var reach: float = node.call("bomb_reach") if node.has_method("bomb_reach") else 1.2
		if node.global_position.distance_to(at) < MALLET_RADIUS + reach * 0.6:
			hit[node] = true
			node.call("bomb_hit", at)
	for n in p.get_tree().get_nodes_in_group("mallet_targets"):
		var node := n as Node3D
		if node and node.global_position.distance_to(at) < MALLET_RADIUS + 0.6:
			node.call("mallet_hit", p)
	# The ground shakes: foes standing close are dazed for a moment.
	for e in p.get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and not en.is_dead() and not hit.has(en) and en.global_position.distance_to(at) < MALLET_QUAKE and en.is_on_floor():
			en.daze(1.5)
	Sfx.play("mallet_smash", 0.0, 0.05)
	if landed:
		Sfx.play("enemy_hurt", -2.0)
	Fragments.burst(p.get_parent(), load("res://assets/models/rock_chip_mesh.tres"), at - Vector3.UP * 0.35, 8, 3.0, 4.0, 0.6, 0.8, Color(0.45, 0.4, 0.35))
	SpellEffect.make(p.get_parent(), "quake", at - Vector3.UP * 0.38)
	GameManager.rumble(0.8, 0.25)
	if p.camera_rig:
		p.camera_rig.shake(0.12, 0.3)


# --- Grave Spade and Sapphire Staff -------------------------------------------------

## The spade or the staff in his right hand ("" puts it away).
func _show_tool(mesh: String) -> void:
	if _tool == null and mesh != "":
		var hand := p.model.get_node_or_null(HAND) as Node3D
		if hand == null:
			return
		_tool = MeshInstance3D.new()
		_tool.name = "HandTool"
		_tool.position = Vector3(0, -0.06, 0)
		hand.add_child(_tool)
	if _tool == null:
		return
	_tool.visible = mesh != ""
	var path := "res://assets/models/%s.tres" % mesh
	if mesh != "" and ResourceLoader.exists(path):
		_tool.mesh = load(path)


func _seal_hums() -> void:
	p.begin_talk(null)
	if Progress.flag("ch5:returned"):
		Dialogue.start(["The *Astral Seal* is cracked right through. Its light is faint now, and when you hold it to your ear it hums, very softly, like someone far away calling."], null)
	else:
		Dialogue.start(["The *Astral Seal* hums in your hand, cold as starlight. It is waiting for something..."], null)
	await Dialogue.finished
	if is_instance_valid(p):
		p.end_talk()


## Where the spade bites.
func dig_point() -> Vector3:
	return p.global_position + p.forward() * DIG_REACH


func _dig() -> void:
	var at := dig_point()
	var spot := DigSpot.near(p.get_tree(), at)
	var soil := Surface.under(p.get_world_3d(), at + Vector3.UP * 0.5, World.area_node, 1.5) if is_instance_valid(World.area_node) else "grass"
	var soft := soil in ["grass", "dirt", "sand", "snow", "ash", "mud", "earth", ""]
	var col := Color(0.35, 0.26, 0.18)
	match soil:
		"sand": col = Color(0.85, 0.72, 0.5)
		"snow": col = Color(0.95, 0.97, 1.0)
		"ash": col = Color(0.3, 0.3, 0.32)
	if spot != null:
		Sfx.play("dig", -2.0, 0.05)
		Fragments.burst(p.get_parent(), load("res://assets/models/rock_chip_mesh.tres"), at, 10, 2.5, 3.0, 0.5, 0.7, col)
		spot.dig(p)
		return
	if not soft:
		Sfx.play("wall_hit_hard", -4.0, 0.05, 1.2)
		return
	Sfx.play("dig", -4.0, 0.08)
	Fragments.burst(p.get_parent(), load("res://assets/models/rock_chip_mesh.tres"), at, 6, 2.0, 2.5, 0.4, 0.5, col)
	if randf() < DIG_LUCK:
		Drops.random(1, at + Vector3.UP * 0.3, p.get_parent())


## The fireball leaves the rod's head, along the facing (or at the target).
func _throw_ember() -> void:
	var dir := p.forward()
	if p.lock_target and is_instance_valid(p.lock_target):
		var aim_h := 1.0
		if p.lock_target.has_method("target_height"):
			aim_h = float(p.lock_target.call("target_height")) * 0.6
		var to: Vector3 = p.lock_target.global_position + Vector3.UP * aim_h - (p.global_position + Vector3.UP * 1.3)
		if to.length() > 0.1:
			dir = to.normalized()
	var ball := EmberBall.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else p.get_parent()
	parent.add_child(ball)
	ball.launch(p, p.global_position + Vector3.UP * 1.3 + p.forward() * 0.7, dir)
	Sfx.play("ember_cast", -2.0, 0.05)


func _throw_flail() -> void:
	var dir := p.forward()
	if p.lock_target and is_instance_valid(p.lock_target):
		var to: Vector3 = p.lock_target.global_position - p.global_position
		to.y = 0.0
		if to.length() > 0.1:
			dir = to.normalized()
	var ball := FlailBall.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else p.get_parent()
	parent.add_child(ball)
	ball.launch(p, dir)
	Sfx.play("heavy_swing", 0.0, 0.05, 0.6)


func _conjure() -> void:
	var at := p.global_position + p.forward() * STAFF_REACH
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at + Vector3.DOWN * 3.0, 1)
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		Sfx.play("error", -6.0)
		Progress.add_magic(Progress.magic_cost("sapphire_staff"))
		return
	var parent := World.area_node if is_instance_valid(World.area_node) else p.get_parent()
	SapphireBlock.conjure(parent, hit.position, p.facing_yaw)


# --- Lantern --------------------------------------------------------------------

func _use_lantern() -> bool:
	# Next to an unlit torch, the lantern lights it (a star brazier takes
	# only the starlight).
	var torch := _torch_near()
	if torch and p.is_on_floor():
		if torch.star and not starlight():
			Sfx.play("error", -6.0)
			Dialogue.start(["The brazier is cold as ice. A common flame won't take in it."], null)
			return false
		torch.light_up()
		_show_lantern(true)
		return false
	_show_lantern(not lantern_lit)
	Sfx.play("torch_light" if lantern_lit else "menu_select", -8.0, 0.05, 1.5)
	return false


func _torch_near() -> Torch:
	var best: Torch = null
	var best_d := LANTERN_REACH
	for t in p.get_tree().get_nodes_in_group("torches"):
		var torch := t as Torch
		if torch == null or torch.lit:
			continue
		var to := torch.global_position - p.global_position
		to.y = 0.0
		if to.length() < best_d:
			best = torch
			best_d = to.length()
	return best


func _show_lantern(on: bool) -> void:
	lantern_lit = on
	if _lantern_light:
		_lantern_light.visible = on
		_lantern_light.light_color = Color(0.62, 0.78, 1.0) if starlight() else Color(1.0, 0.78, 0.45)
		_lantern_light.omni_range = 10.0 if starlight() else 8.0
	if _lantern_mesh:
		_lantern_mesh.visible = on
		var mesh_path := "res://assets/models/%s.tres" % ("starlight_lantern_mesh" if starlight() else "lantern_mesh")
		if on and ResourceLoader.exists(mesh_path) and _lantern_mesh.mesh != load(mesh_path):
			_lantern_mesh.mesh = load(mesh_path)


## The lantern holds Lothelye's starlight (the Starlight Lantern).
static func starlight() -> bool:
	return Progress.flag(Progress.STARLIGHT)


## The lit Starlight Lantern lays bare what hides in the dark: shades near the
## hero reel as if caught in sunlight.
func _starlight_reveal(delta: float) -> void:
	for e in p.get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n and n.has_method("light_hit") and n.global_position.distance_to(p.global_position) < STARLIGHT_REACH:
			n.call("light_hit", delta, (n.global_position - p.global_position).normalized())


func lantern_on() -> bool:
	return lantern_lit and _lantern_light != null and _lantern_light.visible


# --- Lothelye's Dream ------------------------------------------------------------

## Starts or ends the Dream: every DreamLight in the area answers.
func set_dream(on: bool) -> void:
	if dreaming == on:
		return
	dreaming = on
	_dream_drain = 0.0
	if _dream_light:
		_dream_light.visible = on
	Sfx.play("goddess_chime" if on else "camera_out", -4.0, 0.0, 1.3 if on else 1.0)
	if on:
		SpellEffect.make(p.get_parent(), "dream", p.global_position + Vector3.UP * 0.8)
	for n in p.get_tree().get_nodes_in_group("dream_light"):
		if n.has_method("dream"):
			n.call("dream", on)


# --- Mira's Looking Glass ---------------------------------------------------------

func _use_lens() -> bool:
	if lens_on:
		set_lens(false)
		return false
	if Progress.magic <= 0:
		Sfx.play("error", -6.0)
		return false
	if p.state != PlayerController.State.LOOK and not p._try_look():
		return false
	set_lens(true)
	return true


func set_lens(on: bool) -> void:
	if lens_on == on:
		return
	lens_on = on
	_drain = 0.0
	Sfx.play("lens_on" if on else "camera_out", -4.0)
	for n in p.get_tree().get_nodes_in_group("lens_hidden"):
		_lens_show(n as Node, on)
	for n in p.get_tree().get_nodes_in_group("lens_fake"):
		_lens_show(n as Node, not on)


## Shows or hides a lens object. Only the picture changes: OoT's hidden
## floors are solid all along, just unseen, and its false walls let him through.
static func _lens_show(n: Node, on: bool) -> void:
	if n.has_method("lens_show"):
		n.call("lens_show", on)
	elif n is Node3D:
		(n as Node3D).visible = on


## Ghosts that hide in the dark show themselves to the glass.
func _reveal(delta: float) -> void:
	for e in p.get_tree().get_nodes_in_group("enemies"):
		var en := e as Node3D
		if en and en.has_method("light_hit") and en.get("revealed") != null and en.global_position.distance_to(p.global_position) < 14.0:
			en.call("light_hit", delta * 2.0, -p.forward())


# --- Fishing Rod ----------------------------------------------------------------

## Fishing from the shore: there must be open water a few steps ahead.
func _use_rod() -> bool:
	if not _can_act():
		Sfx.play("error", -6.0)
		return false
	var spot := FishingSpot.from_shore(p)
	if spot == null:
		Sfx.play("error", -6.0)
		return false
	spot.interact(p)
	return true


# --- The goddesses' blessings ---------------------------------------------------

func _cast_harvest() -> void:
	SpellEffect.make(p.get_parent(), "harvest", p.global_position)
	p.health.heal(HARVEST_HEAL)
	Sfx.play("heart", -4.0)
	for s in p.get_tree().get_nodes_in_group("shrubs"):
		var shrub := s as Node3D
		if shrub and shrub.has_method("cut_down") and not shrub.get("cut") and shrub.global_position.distance_to(p.global_position) < HARVEST_RADIUS:
			shrub.call("cut_down")


func _cast_ruin() -> void:
	SpellEffect.make(p.get_parent(), "ruin", p.global_position + Vector3.UP * 0.8)
	var space := p.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RUIN_RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), p.global_position + Vector3.UP * 0.8)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	var hit := {}
	for h in space.intersect_shape(q, 32):
		var hb := h.collider as Hurtbox
		if hb == null or not hb.monitorable or hb.receiver == p or hit.has(hb.receiver):
			continue
		hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = RUIN_DAMAGE
		info.knockback = 12.0
		info.heavy = true
		info.unblockable = true
		info.attacker = p
		info.source_position = p.global_position
		hb.receive_hit(info)
	for n in p.get_tree().get_nodes_in_group("bombables"):
		var node := n as Node3D
		if node and not hit.has(node) and node.is_inside_tree() and node.global_position.distance_to(p.global_position) < RUIN_RADIUS:
			node.call("bomb_hit", p.global_position)
	GameManager.rumble(1.0, 0.4)
	if p.camera_rig:
		p.camera_rig.shake(0.2, 0.45)


## Aphiel's Gale (Farore's Wind): with no point in this area, set one here;
## with one, ask whether to go back to it or dispel it.
func _ask_gale() -> bool:
	var gp := Progress.gale_point
	if gp.is_empty() or String(gp.get("area", "")) != World.area_id:
		return _begin("gale")
	_gale_question()
	return true


const GALE_WARP := "Return to the Gale Point"
const GALE_DISPEL := "Dispel the Gale Point"


func _gale_question() -> void:
	p.begin_talk(null)
	Dialogue.start([{"text": "*Aphiel's Gale* stirs round you.", "choices": [
		[GALE_WARP, []], [GALE_DISPEL, []], ["Do nothing", []],
	]}], null)
	await Dialogue.finished
	if not is_instance_valid(p):
		return
	p.end_talk()
	match Dialogue.last_choice:
		GALE_WARP:
			_begin("gale")
		GALE_DISPEL:
			Progress.gale_point = {}
			Progress.changed.emit()
			_place_gale_marker()
			Sfx.play("msg_close", -4.0)


func _cast_gale() -> void:
	var gp := Progress.gale_point
	if not gp.is_empty() and String(gp.get("area", "")) == World.area_id:
		# Carried back on the wind.
		SpellEffect.make(p.get_parent(), "gale", p.global_position)
		p.global_position = gp.pos
		p.velocity = Vector3.ZERO
		p.face_direction(Vector3(-sin(float(gp.yaw)), 0, -cos(float(gp.yaw))))
		if p.camera_rig:
			p.camera_rig.snap_behind_target()
		SpellEffect.make(p.get_parent(), "gale", p.global_position)
		Progress.gale_point = {}
		Sfx.play("warp_wind", -2.0)
	else:
		Progress.gale_point = {"area": World.area_id, "pos": p.global_position, "yaw": p.facing_yaw}
		SpellEffect.make(p.get_parent(), "gale", p.global_position)
		Sfx.play("puzzle_solved", -6.0, 0.0)
	Progress.changed.emit()
	_place_gale_marker()


## A small whirl of green light where the Gale Point is (in its own area).
func _place_gale_marker() -> void:
	if is_instance_valid(_gale_marker):
		_gale_marker.queue_free()
		_gale_marker = null
	var gp := Progress.gale_point
	if gp.is_empty() or String(gp.get("area", "")) != World.area_id or not p.is_inside_tree():
		return
	_gale_marker = SpellEffect.make(p.get_parent(), "gale_point", gp.pos)
