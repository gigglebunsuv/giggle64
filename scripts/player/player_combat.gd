class_name PlayerCombat
extends Node
## Sword attacks and shield blocking for the player.
##
## Driven explicitly by PlayerController.physics_update() so timing is
## deterministic relative to movement.

signal attack_started(index: int)
signal blocked_hit

@export var sword_hitbox: Hitbox
@export var sword_damage := 1
@export_group("Attack Timing")
@export var attack_duration := 0.42
@export var hit_start := 0.10
@export var hit_end := 0.24
@export var combo_window_start := 0.14
@export var combo_transition := 0.30
@export var input_buffer_time := 0.18
@export var lunge_speed := 2.5
@export_group("Shield")
## Attacks within this angle of the player's facing are stopped by the shield.
@export var block_half_angle_deg := 75.0

var attack_index := 0
var attack_time := 0.0

## The cuts (Beta 1.6.0), after OoT's D_80854190. Which one comes out is the
## controller's choice (PlayerController._melee_kind, after func_80837818);
## the third of the same kind in a row is its finisher ("_fin", the
## *_kiru_finsh animations: func_80837948 adds 2 once unk_845 reaches 3).
## Per cut: its length, when the blade is live ("hit"), when a buffered B
## chains on and when the next cut starts ("chain"), the hitbox's width (x
## the box) and extra reach, the forward step it lunges with (OoT units per
## frame; the stab's speedXZ = 15 on its first frame), and the knockback.
## The animations are built to these times (gen_characters._sword_anims).
const SWINGS := {
	"slash_left": {"len": 0.42, "hit": [0.07, 0.21], "chain": [0.13, 0.28], "width": 1.0, "reach": 0.0, "step": 0.0, "knock": 4.0},
	"slash_right": {"len": 0.42, "hit": [0.07, 0.21], "chain": [0.13, 0.28], "width": 1.0, "reach": 0.0, "step": 0.0, "knock": 4.0},
	"slash_down": {"len": 0.42, "hit": [0.08, 0.2], "chain": [0.13, 0.28], "width": 0.7, "reach": 0.15, "step": 0.0, "knock": 4.0},
	"stab": {"len": 0.36, "hit": [0.05, 0.17], "chain": [0.12, 0.24], "width": 0.35, "reach": 0.45, "step": 15.0, "knock": 4.0},
	"slash_left_fin": {"len": 0.56, "hit": [0.1, 0.27], "chain": [0.3, 0.44], "width": 1.25, "reach": 0.15, "step": 6.0, "knock": 7.0},
	"slash_right_fin": {"len": 0.56, "hit": [0.1, 0.27], "chain": [0.3, 0.44], "width": 1.25, "reach": 0.15, "step": 6.0, "knock": 7.0},
	"slash_down_fin": {"len": 0.6, "hit": [0.15, 0.3], "chain": [0.32, 0.48], "width": 0.8, "reach": 0.25, "step": 4.0, "knock": 7.0},
	"stab_fin": {"len": 0.52, "hit": [0.1, 0.25], "chain": [0.28, 0.42], "width": 0.4, "reach": 0.6, "step": 20.0, "knock": 7.0},
}
## The cut now swinging, the last plain cut and how many of it in a row.
var swing_kind := ""
var _last_kind := ""
var _same_count := 0

var _player: PlayerController
## The swing timings as authored (one-handed); a two-handed sword's `slow`
## stretches them all, and its swings play slower to match.
var _base_timing := {}
var swing_slow := 1.0
## The sword hitbox's box as authored (sized for the Squire's Sword).
var _reach_size := Vector3.ZERO
var _reach_z := 0.0
var _attack_buffer := 0.0
var _combo_queued := false
var _swing_done := false
## The blade has already struck a wall this swing.
var clinked := false
## func_808428D8: B behind the crouched shield stabs (PLAYER_MWA_STAB_1H)
## along the aimed shield instead of swinging.
const STAB_TIME := 0.3
const STAB_HIT_START := 0.05
const STAB_HIT_END := 0.16
## The thrust is a narrow line, not the swing's wide arc.
const STAB_WIDTH := 0.6
var stabbing := false

## The Knight's Techniques (Chapter V), taught by Rowena in the Knights' Yard:
## - GREAT SPIN (OoT's spin attack): B held on past a swing gathers strength;
##   once charged (SPIN_CHARGE), letting go turns the blade a full circle
##   round the hero, every foe in reach struck twice as hard.
## - DOWN THRUST: B while dropping from a height drives the blade straight
##   down; where he lands a shock strikes and dazes what stands round him,
##   and cracked floor seals ("thrust_targets") break.
## - SHIELD BASH: A behind the raised shield shoves it forward: foes are
##   knocked back and staggered, and an undead knight's guard breaks.
const TECH_SPIN := "tech:spin"
const TECH_THRUST := "tech:thrust"
const TECH_BASH := "tech:bash"
## - PARRY (Beta 1.4.0, taught at the marsh-front camp): a Shield Bash timed
##   to the blow. A hit that meets the shield in the bash's first
##   PARRY_WINDOW is turned aside: no push, and the attacker staggers
##   (Enemy.parried), its guard wide open.
const TECH_PARRY := "tech:parry"
const PARRY_WINDOW := 0.22
const SPIN_CHARGE := 0.8
const SPIN_TIME := 0.42
const SPIN_REACH := 2.6
const THRUST_RADIUS := 1.8
const THRUST_QUAKE := 3.2
const BASH_TIME := 0.38
const BASH_REACH := 1.3
const BASH_RADIUS := 1.1
const BASH_KNOCKBACK := 8.5
## Gathering strength for the Great Spin (B held), and how long.
var charging := false
var charge := 0.0
var spinning := false
var thrusting := false
var bashing := false
var _tech_t := 0.0
var _charged_sfx := false
var _charge_light: OmniLight3D
var _bash_done := false


static func knows(tech: String) -> bool:
	return Progress.flag(tech)


func setup(player: PlayerController) -> void:
	_player = player
	for k in ["attack_duration", "hit_start", "hit_end", "combo_window_start", "combo_transition"]:
		_base_timing[k] = get(k)
	sword_hitbox.damage = sword_damage
	sword_hitbox.hit_landed.connect(_on_sword_hit)
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D:
		# Each hero gets his own box, since longer blades stretch it.
		cs.shape = cs.shape.duplicate()
		_reach_size = (cs.shape as BoxShape3D).size
		_reach_z = cs.position.z
	apply_gear()


## Takes the equipped sword's damage and reach and the shield's guard angle
## (Equipment). A longer blade stretches the hitbox forward.
func apply_gear() -> void:
	var sw := Equipment.sword(Progress.sword)
	sword_damage = sw.damage
	sword_hitbox.damage = sword_damage
	swing_slow = float(sw.get("slow", 1.0))
	sword_hitbox.cleave = sw.get("two_handed", false)
	for k in _base_timing:
		set(k, float(_base_timing[k]) * swing_slow)
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		var reach: float = sw.reach * 1.6
		(cs.shape as BoxShape3D).size = _reach_size + Vector3(0, 0, reach)
		cs.position.z = _reach_z - reach * 0.5
	block_half_angle_deg = Equipment.guard().half_angle


func physics_update(delta: float) -> void:
	if _player.input_enabled and Input.is_action_just_pressed("attack"):
		_attack_buffer = input_buffer_time
	else:
		_attack_buffer = maxf(_attack_buffer - delta, 0.0)

	if sword_hitbox.active and not clinked and not spinning:
		_check_wall_clink()
	if stabbing:
		_update_stab(delta)
		return
	if spinning:
		_update_spin(delta)
		return
	if bashing:
		_update_bash(delta)
		return
	if charging:
		_update_charge(delta)
	if attack_index == 0:
		return
	attack_time += delta
	if not _swing_done and attack_time >= hit_start:
		_swing_done = true
		sword_hitbox.activate()
		# NA_SE_IT_SWORD_SWING_HARD for the finisher.
		if is_finisher():
			Sfx.play("sword_swing", -1.0, 0.03, 0.8)
		else:
			Sfx.play("sword_swing", -4.0)
		_try_beam()
	if sword_hitbox.active and attack_time >= hit_end:
		sword_hitbox.deactivate()
	if attack_time >= combo_window_start and _attack_buffer > 0.0:
		_combo_queued = true
		_attack_buffer = 0.0
	if _combo_queued and attack_time >= combo_transition:
		_begin(attack_index + 1)
	elif attack_time >= attack_duration:
		# B still held at the end of a swing: gather strength for the Great Spin.
		var hold := knows(TECH_SPIN) and _player.input_enabled and Input.is_action_pressed("attack")
		cancel_attack()
		if hold:
			_begin_charge()


func wants_attack() -> bool:
	return _attack_buffer > 0.0 and attack_index == 0 and not jumpslash and not stabbing and not charging \
		and not spinning and not bashing and not thrusting


## The blade is cutting (SwordTrail draws behind it): a cut's live frames and
## a moment either side, the jump slash, the Great Spin, the thrusts.
func trail_wanted() -> bool:
	if spinning or thrusting or stabbing or jumpslash:
		return true
	return attack_index > 0 and attack_time >= hit_start - 0.05 and attack_time <= hit_end + 0.08


## B was pressed and not yet used, whatever is under way.
func buffered() -> bool:
	return _attack_buffer > 0.0


## The Shield Bash cut short (a riposte follows the parry at once).
func end_bash() -> void:
	bashing = false


## Forgets a buffered B press (B also skips text, so a conversation clears it).
func clear_buffer() -> void:
	_attack_buffer = 0.0


func wants_block() -> bool:
	return _player.input_enabled and Input.is_action_pressed("shield")


func is_attacking() -> bool:
	return attack_index > 0 or jumpslash or stabbing or spinning or bashing or thrusting


## A quick thrust `yaw` radians off the facing (left +), shield kept up.
func start_stab(yaw: float) -> void:
	cancel_attack()
	_attack_buffer = 0.0
	stabbing = true
	attack_time = 0.0
	_swing_done = false
	clinked = false
	sword_hitbox.rotation.y = yaw
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D:
		(cs.shape as BoxShape3D).size.x = STAB_WIDTH


func _update_stab(delta: float) -> void:
	attack_time += delta
	if not _swing_done and attack_time >= STAB_HIT_START:
		_swing_done = true
		sword_hitbox.activate()
		Sfx.play("sword_swing", -6.0, 0.05, 1.25)
	if sword_hitbox.active and attack_time >= STAB_HIT_END:
		sword_hitbox.deactivate()
	if attack_time >= STAB_TIME:
		_end_stab()


func _end_stab() -> void:
	stabbing = false
	sword_hitbox.deactivate()
	sword_hitbox.rotation.y = 0.0
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		(cs.shape as BoxShape3D).size.x = _reach_size.x


## Starts cut `kind` (one of SWINGS' plain cuts; the controller picks it).
func start_attack(kind := "slash_left") -> void:
	_attack_buffer = 0.0
	_begin(1, kind)


func _begin(index: int, kind := "") -> void:
	# A chained cut is picked afresh from the stick as it starts.
	if kind == "":
		kind = _player.chain_swing()
	# func_80837948: the same cut again counts up; the third is the finisher,
	# and after it the count starts over.
	if kind == _last_kind and _same_count < 3:
		_same_count += 1
	else:
		_same_count = 1
	_last_kind = kind
	if _same_count >= 3:
		kind += "_fin"
	_set_swing(kind)
	attack_index = index
	attack_time = 0.0
	_combo_queued = false
	_swing_done = false
	clinked = false
	sword_hitbox.deactivate()
	_player.model.play(StringName(kind), 0.03, 1.0 / swing_slow, true)
	if float(SWINGS[kind].step) > 0.0:
		_player.swing_step(float(SWINGS[kind].step))
	attack_started.emit(index)


## Takes cut `kind`'s timings (stretched for a two-handed sword), and shapes
## the blade's box to it.
func _set_swing(kind: String) -> void:
	swing_kind = kind
	var sw: Dictionary = SWINGS[kind]
	attack_duration = float(sw.len) * swing_slow
	hit_start = float(sw.hit[0]) * swing_slow
	hit_end = float(sw.hit[1]) * swing_slow
	combo_window_start = float(sw.chain[0]) * swing_slow
	combo_transition = float(sw.chain[1]) * swing_slow
	sword_hitbox.knockback = float(sw.knock)
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		var reach: float = Equipment.sword(Progress.sword).reach * 1.6 + float(sw.reach)
		(cs.shape as BoxShape3D).size = Vector3(_reach_size.x * float(sw.width), _reach_size.y, _reach_size.z + reach)
		cs.position.z = _reach_z - reach * 0.5


## Is the cut now swinging a finisher?
func is_finisher() -> bool:
	return swing_kind.ends_with("_fin")


## The jump slash (func_8083BA90 / func_80837948 with PLAYER_MWA_JUMPSLASH_START):
## OoT gives jump attacks their own, stronger damage type (DMG_JUMP_* deal twice
## a slash), so the sword hits for double while it lasts.
var jumpslash := false


func start_jumpslash() -> void:
	cancel_attack()
	_attack_buffer = 0.0
	jumpslash = true
	clinked = false
	sword_hitbox.damage = sword_damage * 2


## Switches the jump slash's blade on (from frame 6 until the landing chop ends).
func jumpslash_hit(on: bool) -> void:
	if on and not sword_hitbox.active:
		sword_hitbox.activate()
		Sfx.play("sword_swing", -2.0, 0.0, 0.85)
	elif not on and sword_hitbox.active:
		sword_hitbox.deactivate()


## The landing chop (PLAYER_MWA_JUMPSLASH_FINISH) carries the blade on down.
## It is one blow with the leap: whatever the blade struck in the air is not
## struck again (enemies here have no invincibility frames to absorb it).
func jumpslash_land() -> void:
	if not sword_hitbox.active:
		sword_hitbox.activate()
	_try_beam()


func end_jumpslash() -> void:
	if not jumpslash:
		return
	jumpslash = false
	sword_hitbox.deactivate()
	sword_hitbox.damage = sword_damage


func cancel_attack() -> void:
	end_jumpslash()
	if stabbing:
		_end_stab()
	if spinning:
		_end_spin()
	bashing = false
	thrusting = false
	sword_hitbox.kind = ""
	if attack_index > 0:
		_rest_swing()
	attack_index = 0
	attack_time = 0.0
	_combo_queued = false
	sword_hitbox.deactivate()


## Back to the forehand's timings and box between cuts. A chain that stops
## starts its count over (OoT clears unk_845 once unk_844 runs out, 8 frames
## after a cut begins unless the next one has).
func _rest_swing() -> void:
	swing_kind = ""
	_last_kind = ""
	_same_count = 0
	sword_hitbox.knockback = 4.0
	for k in _base_timing:
		set(k, float(_base_timing[k]) * swing_slow)
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		var reach: float = Equipment.sword(Progress.sword).reach * 1.6
		(cs.shape as BoxShape3D).size = _reach_size + Vector3(0, 0, reach)
		cs.position.z = _reach_z - reach * 0.5


# --- The Great Spin -------------------------------------------------------------

func _begin_charge() -> void:
	charging = true
	charge = 0.0
	_charged_sfx = false
	Sfx.play("spin_charge", -10.0, 0.0, 0.8)


## Stops gathering strength (without a spin).
func end_charge() -> void:
	if not charging:
		return
	charging = false
	charge = 0.0
	_glow(false)


func is_charged() -> bool:
	return charging and charge >= SPIN_CHARGE


func _update_charge(delta: float) -> void:
	var p := _player
	# Only on his feet, sword in hand, with nothing else going on.
	if not p.is_on_floor() or not p.sword_drawn or p.is_carrying() \
			or not (p.state in [PlayerController.State.IDLE, PlayerController.State.TURN, PlayerController.State.MOVE]):
		end_charge()
		return
	if p.input_enabled and Input.is_action_pressed("attack"):
		charge += delta
		if charge >= SPIN_CHARGE and not _charged_sfx:
			_charged_sfx = true
			Sfx.play("spin_ready", -4.0, 0.0)
			_glow(true)
		if _charge_light and _charge_light.visible:
			_charge_light.light_energy = 1.4 + sin(Time.get_ticks_msec() * 0.03) * 0.4
		return
	# Let go.
	var ready := charge >= SPIN_CHARGE
	end_charge()
	if ready:
		p.start_spin()


## The blade's glow while the spin is ready.
func _glow(on: bool) -> void:
	if on and _charge_light == null:
		var hand := _player.model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
		_charge_light = OmniLight3D.new()
		_charge_light.name = "SpinGlow"
		_charge_light.light_color = Color(1.0, 0.85, 0.5)
		_charge_light.omni_range = 3.0
		_charge_light.shadow_enabled = false
		(hand if hand else _player as Node3D).add_child(_charge_light)
	if _charge_light:
		_charge_light.visible = on


## The spin itself (PlayerController.start_spin turns the body; the blade's
## hitbox, active all the way round, sweeps everything in reach).
func start_spin() -> void:
	cancel_attack()
	_attack_buffer = 0.0
	spinning = true
	_tech_t = 0.0
	clinked = false
	sword_hitbox.kind = "spin"
	sword_hitbox.damage = sword_damage * 2
	sword_hitbox.knockback = 7.0
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		(cs.shape as BoxShape3D).size.x = _reach_size.x * 1.6
	sword_hitbox.activate()
	Sfx.play("spin_attack", -1.0, 0.03)
	_player.model.play(&"spin_attack" if _player.model.anim.has_animation(&"spin_attack") else &"attack_2", 0.03, 1.0, true)
	GameManager.rumble(0.6, 0.2)
	_try_beam()
	# Everything in reach that answers to a spin (rune bells, dummies...).
	for n in _player.get_tree().get_nodes_in_group("spin_targets"):
		var node := n as Node3D
		if node and node.is_inside_tree():
			var to := node.global_position - _player.global_position
			if Vector2(to.x, to.z).length() < SPIN_REACH + 0.6 and absf(to.y) < 2.5:
				node.call("spin_hit", _player)


func _update_spin(delta: float) -> void:
	_tech_t += delta
	if _tech_t >= SPIN_TIME:
		_end_spin()


func _end_spin() -> void:
	spinning = false
	sword_hitbox.deactivate()
	sword_hitbox.kind = ""
	sword_hitbox.damage = sword_damage
	sword_hitbox.knockback = 4.0
	var cs := sword_hitbox.get_node_or_null("Shape") as CollisionShape3D
	if cs and cs.shape is BoxShape3D and _reach_size != Vector3.ZERO:
		(cs.shape as BoxShape3D).size.x = _reach_size.x


# --- The Down Thrust ----------------------------------------------------------------

func start_thrust() -> void:
	end_charge()
	cancel_attack()
	_attack_buffer = 0.0
	thrusting = true
	clinked = false
	sword_hitbox.kind = "thrust"
	sword_hitbox.damage = sword_damage * 2
	sword_hitbox.activate()
	Sfx.play("sword_swing", -2.0, 0.0, 0.7)


## Where he lands: the shock round his feet.
func thrust_land() -> void:
	var p := _player
	sword_hitbox.deactivate()
	var at := p.global_position
	var hit := {}
	for h in _shape_hits(at + Vector3.UP * 0.5, THRUST_RADIUS):
		var hb := h as Hurtbox
		if hit.has(hb.receiver):
			continue
		hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = sword_damage * 2
		info.knockback = 6.0
		info.heavy = true
		info.kind = "thrust"
		info.attacker = p
		info.source_position = at
		hb.receive_hit(info)
	for e in p.get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en and not en.is_dead() and not hit.has(en) and en.global_position.distance_to(at) < THRUST_QUAKE and en.is_on_floor():
			en.daze(1.2)
	for n in p.get_tree().get_nodes_in_group("thrust_targets"):
		var node := n as Node3D
		if node == null or not node.is_inside_tree():
			continue
		var to := node.global_position - at
		if Vector2(to.x, to.z).length() < float(node.call("thrust_reach")) and to.y > -1.2 and to.y < 0.6:
			node.call("thrust_hit", p)
	Sfx.play("down_thrust", 0.0, 0.03)
	if not hit.is_empty():
		Impact.hit(Impact.HEAVY)
	SpellEffect.make(p.get_parent(), "quake", at + Vector3.UP * 0.05)
	Fragments.burst(p.get_parent(), load("res://assets/models/rock_chip_mesh.tres"), at + Vector3.UP * 0.1, 10, 3.0, 3.5, 0.5, 0.6, Color(0.6, 0.56, 0.5))
	GameManager.rumble(0.9, 0.3)
	if p.camera_rig:
		p.camera_rig.shake(0.14, 0.3)


func end_thrust() -> void:
	thrusting = false
	sword_hitbox.deactivate()
	sword_hitbox.kind = ""
	sword_hitbox.damage = sword_damage


# --- The Shield Bash ---------------------------------------------------------------

func start_bash() -> void:
	end_charge()
	cancel_attack()
	_attack_buffer = 0.0
	bashing = true
	_bash_done = false
	_tech_t = 0.0
	Sfx.play("shield_bash", -2.0, 0.05)


func _update_bash(delta: float) -> void:
	_tech_t += delta
	if not _bash_done and _tech_t >= 0.1:
		_bash_done = true
		_bash_blow()
	if _tech_t >= BASH_TIME:
		bashing = false


func _bash_blow() -> void:
	var p := _player
	var at := p.global_position + p.shield_forward() * BASH_REACH + Vector3.UP * 1.0
	var hit := {}
	var landed := false
	for h in _shape_hits(at, BASH_RADIUS):
		var hb := h as Hurtbox
		if hit.has(hb.receiver):
			continue
		hit[hb.receiver] = true
		var info := HitInfo.new()
		info.damage = 0
		info.knockback = BASH_KNOCKBACK
		info.kind = "bash"
		info.attacker = p
		info.source_position = p.global_position
		if hb.receive_hit(info) != Hurtbox.Result.IGNORED:
			landed = true
	for n in p.get_tree().get_nodes_in_group("bash_targets"):
		var node := n as Node3D
		if node and node.is_inside_tree() and node.global_position.distance_to(at) < BASH_RADIUS + 0.9:
			node.call("bash_hit", p)
			landed = true
	if landed:
		Impact.hit(Impact.LIGHT)
		Sfx.play("shield_block", 0.0, 0.05, 0.8)
		GameManager.rumble(0.6, 0.15)
		if p.camera_rig:
			p.camera_rig.shake(0.06, 0.15)


## The foes' hurtboxes (layer 16) inside a sphere.
func _shape_hits(center: Vector3, radius: float) -> Array:
	var space := _player.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = radius
	q.shape = s
	q.transform = Transform3D(Basis(), center)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 16
	var out: Array = []
	for h in space.intersect_shape(q, 24):
		var hb := h.collider as Hurtbox
		if hb and hb.monitorable and hb.receiver != _player:
			out.append(hb)
	return out


## The Bun Sword looses a beam with every swing while health is full.
func _try_beam() -> void:
	var sw := Equipment.sword(Progress.sword)
	if not sw.get("beam", false):
		return
	# Awake, the blade looses its starlight at any health.
	var starlight: bool = sw.get("starlight", false)
	if _player.health.health < _player.health.max_health and not starlight:
		return
	var beam := SwordBeam.new()
	beam.starlight = starlight
	_player.get_parent().add_child(beam)
	beam.launch(_player.global_position + Vector3.UP * 1.05 + _player.forward() * 0.9, _player.forward())
	Sfx.play("sword_beam", -5.0)


## func_80842DF4: a line from the hilt out past the tip; if the blade meets a
## wall (not something it can cut), sparks fly, it rings off the wall
## (NA_SE_IT_WALL_HIT_HARD, or _SOFT on soft earth) and the hero recoils
## (speedXZ = -14) with a rumble.
func _check_wall_clink() -> void:
	var reach := 1.3 + float(Equipment.sword(Progress.sword).reach) * 1.6
	var from := _player.global_position + Vector3.UP * 1.0
	var to := from + _player.forward() * reach
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or absf((hit.normal as Vector3).y) > 0.5:
		return
	if not _is_wall(hit.collider):
		return
	clinked = true
	var surface := Surface.of_hit(hit)
	var soft := surface in ["dirt", "grass", "mud", "sand", "snow"]
	Sfx.play("wall_hit_soft" if soft else "wall_hit_hard", -3.0, 0.06)
	var spark_col := Color(0.6, 0.45, 0.3) if soft or surface == "wood" else Color(2.0, 1.4, 0.4)
	Fragments.burst(_player.get_parent(), load("res://assets/models/shard_mesh.tres"), hit.position, 6, 2.4, 1.8, 0.3, 0.22, spark_col)
	_player.sword_recoil()
	GameManager.rumble(0.7, 0.2)


## Solid scenery only: anything with a hurtbox, or that can be lifted, cut or
## talked to, is the hitbox's business instead.
static func _is_wall(node: Object) -> bool:
	var n := node as Node
	if n == null or n.is_in_group("enemies") or n.is_in_group("liftables") or n.is_in_group("interactable") 			or n.is_in_group("cuttable") or n.is_in_group("player"):
		return false
	for owner_node in [n, n.get_parent()]:
		if owner_node == null:
			continue
		for c in owner_node.get_children():
			if c is Hurtbox:
				return false
	return n is StaticBody3D or n is AnimatableBody3D


## The bash is young enough to turn a blow aside (the Parry).
func is_parrying() -> bool:
	return bashing and _tech_t < PARRY_WINDOW and knows(TECH_PARRY)


func can_block_from(source: Vector3) -> bool:
	var to := source - _player.global_position
	to.y = 0.0
	if to.length() < 0.01:
		return true
	return _player.shield_forward().dot(to.normalized()) >= cos(deg_to_rad(block_half_angle_deg))


func on_blocked() -> void:
	Sfx.play("shield_block")
	blocked_hit.emit()


func _on_sword_hit(_hurtbox: Hurtbox, result: int) -> void:
	if result == Hurtbox.Result.HIT:
		Sfx.play("sword_hit")
		GameManager.rumble(0.35, 0.1)
		# The impact frames (Impact): a held beat as the blade bites, longer
		# and with a flash for a finisher, the Great Spin or a jump slash.
		var heavy := is_finisher() or spinning or _player.state == PlayerController.State.JUMPSLASH
		Impact.hit(Impact.HEAVY if heavy else Impact.LIGHT)
		if heavy and _player.camera_rig:
			_player.camera_rig.shake(0.05, 0.12)
