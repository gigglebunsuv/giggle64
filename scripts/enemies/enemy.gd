class_name Enemy
extends CharacterBody3D
## What every creature that fights shares: health, being Z-targeted, taking
## hits, the boomerang's stun, item drops (Item_DropCollectibleRandom) and the
## GameManager's foe count. Each kind of creature extends it with its own AI.
##
## Expected children (all optional): Health (HealthComponent), Model
## (CharacterModel), Hurtbox, AttackHitbox (Hitbox).

signal died

## OoT speeds are units per 20 Hz frame, moved x1.5 (R_UPDATE_RATE 3 * 0.5) at
## 0.03 m a unit: one unit a frame is 0.9 m/s, and a gravity of one unit a
## frame per frame is 18 m/s^2.
const OOT_SPEED := 0.9
const OOT_GRAVITY := 18.0
## Every enemy's shortest crossfade between animations (CharacterModel.min_blend).
const ENEMY_MIN_BLEND := 0.08

## Drop table for Drops.random() when it dies (-1 = nothing).
@export var drop_table := 1
## Height of the lock-on arrow above the feet.
@export var target_offset := 1.3
## Seconds a boomerang hit stuns it (0 = it shrugs it off).
@export var boomerang_stun := 2.5
## Damage the boomerang does (frail creatures like keese fall to it).
@export var boomerang_damage := 0
@export var gravity := 21.0
## Tint multiplied over the model (color variants).
@export var tint := Color(1, 1, 1)
## Seconds the body lies before sinking away.
@export var corpse_time := 1.2

@onready var health: HealthComponent = get_node_or_null("Health")
@onready var model: CharacterModel = get_node_or_null("Model")
@onready var hurtbox: Hurtbox = get_node_or_null("Hurtbox")
@onready var attack_hitbox: Hitbox = get_node_or_null("AttackHitbox")

var facing_yaw := 0.0
## Seconds left stunned (boomerang, a blocked attack...).
var stun_left := 0.0
var _home := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _dead := false
var _room: DungeonRoom
var _room_looked := false
## Dazed by a Puff Nut or frozen by a Frost Arrow (see daze()).
var dazed := false
var frozen := false
var _daze_token := 0
var _daze_fx: Node3D
## The noticing ranges each kind of foe has (scaled by Progress.stealth()).
const SIGHT_KEYS := ["notice_range", "detection_range", "close_detection_range"]
var _sight := {}
## The dungeon tier it woke up in (EnemyScale): tougher and harder-hitting.
var tier := 0
## Kinds of creature that are dead already (the Ember Rod burns them twice
## as hard) and kinds made of fire (it does not burn them at all).
const UNDEAD_KINDS := ["stalfos", "charred_stalfos", "frost_stalfos", "bog_stalfos", "mummy", "mummy_lord", "shade",
	"barrow_knight", "barrow_champion", "hollow_king", "gaoler", "mara"]
const FIREPROOF_KINDS := ["fire_keese", "cinder_wyvern", "cinderling", "ember_knight", "magmaw", "firebuns"]
## Mini-bosses with no name card of their own: their fight music starts when
## the hero comes near (the named ones start it with their card).
const MINIBOSS_KINDS := ["mummy_lord", "battle_mage", "dark_gigglebuns"]
const MINIBOSS_MUSIC_RANGE := 11.0


func _apply_stealth() -> void:
	if not is_inside_tree():
		return
	# Tougher ranks notice the hero from a little further off.
	var keen := EnemyScale.haste(tier)
	for key: String in _sight:
		set(key, float(_sight[key]) * Progress.stealth() * keen)


func _ready() -> void:
	_rng.randomize()
	_home = global_position
	facing_yaw = rotation.y
	if health:
		health.died.connect(_on_died)
	if attack_hitbox:
		attack_hitbox.hit_landed.connect(_on_attack_landed)
	if model:
		model.min_blend = ENEMY_MIN_BLEND
	if model and tint != Color(1, 1, 1):
		model.set_tint(tint)
	add_to_group("enemies")
	var kid := kind_id()
	if kid in UNDEAD_KINDS:
		add_to_group("undead")
	if kid in FIREPROOF_KINDS:
		add_to_group("fireproof")
	if kid in MINIBOSS_KINDS:
		_watch_for_fight.call_deferred()
	_in_dungeon = World.dungeon_id() != ""
	GameManager.register_enemy(self)
	# The Shade Cloak: foes notice the hero only from close by.
	for key in SIGHT_KEYS:
		var v = get(key)
		if v is float:
			_sight[key] = v
	_apply_stealth()
	Progress.gear_changed.connect(_apply_stealth)
	get_tree().physics_frame.connect(_snap_to_ground, CONNECT_ONE_SHOT)
	_apply_tier.call_deferred()


## Scales it to the dungeon it lives in (after the kind's own _ready, so
## bosses have joined their group and are left alone).
func _apply_tier() -> void:
	if not is_inside_tree() or _dead:
		return
	if is_in_group("bosses"):
		# A boss is made for its own fight (EnemyScale.BOSS_HEALTH).
		if health and not has_meta("boss_scaled"):
			set_meta("boss_scaled", true)
			var full := health.health >= health.max_health
			health.max_health = EnemyScale.boss_health(kind_id(), health.max_health)
			if full:
				health.health = health.max_health
		return
	tier = EnemyScale.tier(World.area_id)
	if tier <= 0:
		return
	if health:
		var full := health.health >= health.max_health
		health.max_health = EnemyScale.health(health.max_health, tier)
		if full:
			health.health = health.max_health
	_apply_haste(EnemyScale.haste(tier))
	_apply_stealth()
	tint *= EnemyScale.tint(tier)
	if model and not frozen:
		model.set_tint(tint)


## Its exported speeds go up, and its wind-ups and rests come down, by `h`.
const HASTE_FASTER := ["walk_speed", "chase_speed", "strafe_speed", "rush_speed", "patrol_speed", "lunge_speed",
	"hop_speed", "fly_speed", "charge_speed", "turn_speed_deg", "start_rate"]
const HASTE_SOONER := ["windup_time", "recover_time", "rest_time", "draw_time", "charge_time", "breath_time"]


func _apply_haste(h: float) -> void:
	if h <= 1.0:
		return
	for prop in get_property_list():
		var n: String = prop.name
		if prop.type != TYPE_FLOAT or not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if n in HASTE_FASTER:
			set(n, float(get(n)) * h)
		elif n in HASTE_SOONER:
			set(n, float(get(n)) / h)


## Which kind of creature it is (its scene's name: "stalfos", "basic_enemy").
func kind_id() -> String:
	return scene_file_path.get_file().get_basename() if scene_file_path != "" else ""


## Its name in the Bestiary, with its rank ("Veteran Stalfos").
func rank_name(base: String) -> String:
	var r := EnemyScale.rank(tier)
	return base if r == "" else r + " " + base


func _snap_to_ground() -> void:
	var from := global_position + Vector3.UP * 2.0
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 30.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not motion_mode == MOTION_MODE_FLOATING:
		global_position.y = hit.position.y
	_home = global_position


func is_targetable() -> bool:
	return not _dead and is_inside_tree() and visible


func is_dead() -> bool:
	return _dead


func target_height() -> float:
	return target_offset


## Where the hero's shots and throws home in while it is locked on (OoT aims
## at an actor's focus point): the middle of the body, or its weak point.
func aim_point() -> Vector3:
	return global_position + Vector3.UP * target_height() * 0.6


## Where the lock-on arrow floats over it.
func marker_point() -> Vector3:
	return global_position + Vector3.UP * (target_height() + 0.35)


## The hero, or null while he is out of its reach: a creature that belongs to
## a dungeon room (meta "room") only notices and chases him inside that room,
## as OoT's room-bound actors do, so nothing hunts him through a floor or wall.
## One that belongs to no room (in a passage) must see him, on its own level:
## once it has, it keeps after him for SIGHT_MEMORY seconds out of sight.
## Online (Net), every hero in the area counts and the nearest it may chase
## is the one.
func _player() -> PlayerController:
	if not Net.active:
		return _chases(GameManager.player)
	var best: PlayerController = null
	var best_d := INF
	for h: PlayerController in Net.heroes():
		if h.is_dead() and h != GameManager.player:
			continue
		var c := _chases(h)
		if c:
			var d := _flat_dist(c.global_position)
			if d < best_d:
				best_d = d
				best = c
	return best


func _chases(p: PlayerController) -> PlayerController:
	if p == null:
		return null
	var room := _room_zone()
	if room:
		if not room.contains(p.global_position):
			return null
	elif _in_dungeon and not is_in_group("bosses"):
		if absf(p.global_position.y - global_position.y) > 3.5:
			return null
		var now := Time.get_ticks_msec() * 0.001
		var key := p.get_instance_id()
		if now - float(_sight_checks.get(key, -10.0)) > 0.2:
			_sight_checks[key] = now
			if _sees(p):
				_seen_ats[key] = now
		if now - float(_seen_ats.get(key, -100.0)) > SIGHT_MEMORY:
			return null
	return p


## When each hero was last looked for, and last seen (instance id -> seconds).
var _sight_checks := {}
var _seen_ats := {}


const SIGHT_MEMORY := 2.5
var _in_dungeon := false


## A clear line from its head to his (walls and floors block it).
func _sees(p: PlayerController) -> bool:
	var from := global_position + Vector3.UP * minf(target_height(), 1.6)
	var q := PhysicsRayQueryParameters3D.create(from, p.global_position + Vector3.UP * 1.3, 1)
	q.exclude = [get_rid(), p.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _room_zone() -> DungeonRoom:
	if not _room_looked and has_meta("room") and is_inside_tree():
		_room_looked = true
		var id: String = get_meta("room")
		for r: Node in get_tree().get_nodes_in_group("rooms"):
			if r is DungeonRoom and r.room_id == id:
				_room = r
				break
	return _room if is_instance_valid(_room) else null


func _forward() -> Vector3:
	return Vector3(-sin(facing_yaw), 0.0, -cos(facing_yaw))


func _flat_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


func _flat_to(p: Vector3) -> Vector3:
	var d := p - global_position
	d.y = 0.0
	return d


func _yaw_to(p: Vector3) -> float:
	var to := p - global_position
	return atan2(-to.x, -to.z)


## Turns toward `point` by at most `deg_per_s` this frame.
func _turn_to(point: Vector3, deg_per_s: float, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	var diff := angle_difference(facing_yaw, atan2(-to.x, -to.z))
	var step := deg_to_rad(deg_per_s) * delta
	facing_yaw += clampf(diff, -step, step)


func _brake(delta: float, rate := 14.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)
	velocity.z = move_toward(velocity.z, 0.0, rate * delta)


func _fall(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


func _can_see_player(range_m: float, max_dy := 4.0) -> bool:
	var p := _player()
	if p == null or p.is_dead():
		return false
	if global_position.distance_to(p.global_position) > range_m or absf(p.global_position.y - global_position.y) > max_dy:
		return false
	var eye := global_position + Vector3.UP * 0.8
	var q := PhysicsRayQueryParameters3D.create(eye, p.global_position + Vector3.UP * 1.0, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


# --- Damage -------------------------------------------------------------------

## Called by the Hurtbox. Override `_hurt` for reactions; return a Hurtbox.Result.
func take_hit(info: HitInfo) -> int:
	if _dead:
		return Hurtbox.Result.IGNORED
	if info.kind == "bash":
		return _bashed(info)
	_frozen_blow(info)
	var r := _guard(info)
	if r != Hurtbox.Result.HIT:
		return r
	health.apply_damage(info.damage)
	if model:
		model.flash(Color(1.0, 0.95, 0.8), 0.08)
	if health.is_dead:
		return Hurtbox.Result.HIT
	Sfx.play("enemy_hurt")
	_hurt(info)
	return Hurtbox.Result.HIT


## The hero's Shield Bash (HitInfo.kind "bash"): no harm done, but it is
## shoved back and staggered for a moment. Bosses stand firm unless they say
## otherwise; an undead knight's guard breaks (BarrowKnight).
func _bashed(info: HitInfo) -> int:
	if is_in_group("bosses"):
		Sfx.play("shield_block", -4.0, 0.05, 0.7)
		return Hurtbox.Result.BLOCKED
	var away := _flat_to(info.source_position) * -1.0
	away = away.normalized() if away.length() > 0.01 else -_forward()
	velocity.x = away.x * info.knockback
	velocity.z = away.z * info.knockback
	stun(1.0)
	return Hurtbox.Result.HIT


## The hero's Parry turned this one's blow: it reels as from a Shield Bash
## (an undead knight's guard breaks), and longer. Bosses answer it themselves.
func parried(by: Node3D) -> void:
	if _dead or is_in_group("bosses"):
		return
	var info := HitInfo.new()
	info.damage = 0
	info.knockback = 5.0
	info.kind = "bash"
	info.attacker = by
	info.source_position = by.global_position
	_bashed(info)
	stun_left = maxf(stun_left, 1.8)


## Override: return BLOCKED (or IGNORED) to shrug a hit off before it lands.
func _guard(_info: HitInfo) -> int:
	return Hurtbox.Result.HIT


## Override: react to a hit that did not kill.
func _hurt(info: HitInfo) -> void:
	var away := _flat_to(info.source_position) * -1.0
	away = away.normalized() if away.length() > 0.01 else -_forward()
	velocity.x = away.x * info.knockback
	velocity.z = away.z * info.knockback


## The boomerang (scripts/items/boomerang.gd) struck it.
func boomerang_hit(_b: Node3D) -> void:
	if boomerang_stun > 0.0 and not _dead:
		stun(boomerang_stun)


## Override to play a stun animation; the AI should idle while stun_left > 0.
func stun(seconds: float) -> void:
	stun_left = maxf(stun_left, seconds)
	Sfx.play("shell_clamp", -6.0, 0.05, 1.6)


## Puff Nuts daze it and Frost Arrows freeze it (OoT's Deku Nut stun and ice
## arrows): it stops dead where it is, its AI and animation held, its attack
## put away, for `seconds` (bosses shake it off sooner). Frozen, it is cased
## in ice and the next blow shatters the ice for double damage.
func daze(seconds: float, ice := false) -> void:
	if _dead or not is_inside_tree() or (ice and not can_freeze()):
		return
	if is_in_group("bosses"):
		seconds *= 0.35
	_daze_token += 1
	var token := _daze_token
	stun_left = maxf(stun_left, seconds)
	if not dazed:
		dazed = true
		set_physics_process(false)
		set_process(false)
		velocity = Vector3.ZERO
		if model and model.anim:
			model.anim.pause()
		if attack_hitbox:
			attack_hitbox.deactivate()
	if ice and not frozen:
		frozen = true
		if model:
			model.set_tint(Color(0.55, 0.8, 1.35))
		Sfx.play("ice_freeze", -2.0, 0.05)
	if is_instance_valid(_daze_fx):
		_daze_fx.queue_free()
	_daze_fx = SpellEffect.make(self, "ice" if frozen else "stars", global_position + Vector3.UP * (0.0 if frozen else target_offset + 0.3))
	if frozen:
		_daze_fx.set("size", Vector3(1.3, target_offset + 0.5, 1.3))
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		if token == _daze_token and is_instance_valid(self):
			_undaze())


## Creatures made of ice (or fire) cannot be frozen.
func can_freeze() -> bool:
	return true


func is_dazed() -> bool:
	return dazed


func _undaze(shatter := false) -> void:
	if not dazed:
		return
	dazed = false
	_daze_token += 1
	if is_instance_valid(_daze_fx):
		_daze_fx.queue_free()
	_daze_fx = null
	if frozen:
		frozen = false
		if model:
			model.set_tint(tint)
		if shatter and get_parent():
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * target_offset * 0.6, 14, 3.0, 3.5, 0.8, 0.9, Color(0.8, 0.95, 1.3))
			Sfx.play("crystal_hit", -2.0, 0.05, 1.2)
	if _dead:
		return
	set_physics_process(true)
	set_process(true)
	if model and model.anim:
		model.anim.play()


## A blow on the frozen creature breaks the ice and lands twice as hard.
func _frozen_blow(info: HitInfo) -> void:
	if frozen:
		info.damage *= 2
		_undaze(true)


func _on_attack_landed(_hb: Hurtbox, _result: int) -> void:
	pass


func _on_died() -> void:
	if dazed:
		_undaze()
	_dead = true
	remove_from_group("enemies")
	collision_layer = 0
	if attack_hitbox:
		attack_hitbox.deactivate()
		attack_hitbox.set_deferred("monitoring", false)
	_set_hurtbox(false)
	Sfx.play("enemy_death")
	Progress.note_kill(kind_id(), tier)
	# Its fight music ends with it (the boss: silence; a mini-boss: the dungeon's own).
	if has_meta("battle"):
		World.end_battle(String(get_meta("battle")))
	elif is_in_group("bosses"):
		World.end_battle("boss")
	died.emit()
	drop_items()
	_die()


## A mini-boss (MINIBOSS_KINDS) waits for the hero to come near on its own
## floor, then starts the mini-boss music.
func _watch_for_fight() -> void:
	while is_inside_tree() and not _dead and not has_meta("battle"):
		await get_tree().create_timer(0.3, false).timeout
		if not is_inside_tree() or _dead:
			return
		var p := GameManager.player
		if p and not p.is_dead() and _flat_dist(p.global_position) < MINIBOSS_MUSIC_RANGE 				and absf(p.global_position.y - global_position.y) < 3.0 and not Cutscene.active:
			set_meta("battle", "miniboss")
			World.start_battle("miniboss")


## Override for a custom death; the default plays "death" and sinks away.
func _die() -> void:
	if model:
		model.play(&"death", 0.03, 1.0, true)
	var tween := create_tween()
	tween.tween_interval(corpse_time)
	if model:
		tween.tween_property(model, "position:y", -0.8, 0.6)
	tween.tween_callback(queue_free)


## Turns the hurtbox on or off (hidden or dead creatures cannot be hit, not
## even by arrows, which look for hurtboxes by layer).
func _set_hurtbox(on: bool) -> void:
	if hurtbox:
		hurtbox.set_deferred("monitorable", on)
		hurtbox.set_deferred("collision_layer", 16 if on else 0)


func drop_items() -> void:
	if drop_table >= 0 and get_parent():
		Drops.random(drop_table, global_position + Vector3.UP * 0.3, get_parent())
