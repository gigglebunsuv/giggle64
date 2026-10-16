extends Enemy
## Firebuns III on the throne of Haven: the last fight, which the hero cannot
## win (the story's defeat, see Story.finale). He fights like a duellist
## (OoT's Ganondorf and Phantom Ganon, z_boss_ganon.c, lend the pattern):
## - he stalks the hero with the broadsword low; head-on, his guard turns
##   blows aside (the blade rings) until he swings: a raised windup, a heavy
##   slash, and a moment open after it;
## - the Gauntlet thrown forward flings a spread of fireballs (any shield
##   turns them, the Mirror Shield straight back into him, which staggers him);
## - the Gauntlet raised high sends a ring of fire rolling out across the
##   floor (the shield holds it back).
## Hurt enough (THRONE_HITS blows landed) he stops fighting and the finale
## begins: the Gauntlet's full power, which no sword can answer yet. Every
## fight with him is counted in blows, not health, so a stronger sword does
## not cut it short; halfway through he gives up playing (`enraged`): he
## stalks faster, chains his slashes, lunges across the floor at a hero who
## keeps away, throws five fireballs at a time and sends two rings of fire.
##
## Chapter IV (`sealing`, the burning throne-room roof of the Citadel): the
## second battle, which the hero WINS. The Gauntlet wraps him in a FLAME
## SHIELD that nothing touches (blades, bombs, even returned fire) until a
## Starfall Arrow breaks it; then for SHIELD_DOWN seconds he is the duellist
## of the first fight, and the awakened Bun Sword wounds him. The shield
## comes back hotter each time (faster fireballs). After SEAL_HITS, he falls
## to his knees and the Astral Seal takes him (Story.sealing).

enum State { THRONE, RISE, STALK, SLASH_WINDUP, SLASH, RECOVER, CAST, RING, STAGGER, FINALE, DASH_WINDUP, DASH }

const TITLE := "FIREBUNS III"
const SUBTITLE := "RISEN KING OF BATELA FELLS"
## The throne-room fight ends (for the story) after this many blows land.
const THRONE_HITS := 16
## The duel at Batela Keep (Chapter III): how long he plays with the hero,
## how many blows he lets land, and the health (half-hearts) at which he
## stops before the hero falls.
const DUEL_TIME := 80.0
const DUEL_HITS := 14
const DUEL_SPARE := 4
## The second battle: blows (in his shield's open moments) before the seal.
const SEAL_HITS := 16
const RING_SPEED := 7.0
const RING_MAX := 11.0
## The second battle (sealing): how long the shield stays broken.
const SHIELD_DOWN := 8.0

## The duel at Batela Keep: a fight the hero survives but cannot win. He
## stands instead of sitting, hits a little softer, and ends it himself
## (Story.keep_duel_end) before the hero falls.
@export var duel := false
## The second battle on the Citadel roof (Chapter IV), which is won.
@export var sealing := false

var state := State.THRONE
var _duel_t := 0.0
var _duel_over := false
var _t := 0.0
var _plan := 1.6
var _ring := -1.0
var _ring_hit := false
var _ring_mesh: MeshInstance3D
var _flame: Node3D
var _chained := false
## His blows landed so far, and whether he has given up playing.
var hits := 0
var enraged := false
## The flame shield (sealing): up, and seconds left while it is broken.
var shield_up := false
var _shield_down := 0.0
var _shield_breaks := 0
var _shield_mesh: MeshInstance3D


func _ready() -> void:
	corpse_time = 99.0
	super._ready()
	add_to_group("bosses")
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 9.0
	_flame = model.find_child("GauntletFlame", true, false) as Node3D
	if duel and attack_hitbox:
		attack_hitbox.damage = 3
	if sealing and attack_hitbox:
		attack_hitbox.damage = 4
	# The fights are counted in blows (hits_needed): his health only keeps
	# him from falling first.
	if health:
		health.max_health = 999
		health.health = 999
	if Progress.flag("game_beaten") and not duel and not sealing:
		# After the ending the throne room stands empty.
		set_physics_process(false)
		queue_free()
		return
	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.name = "FireRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 6
	_ring_mesh.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.15)
	m.disable_fog = true
	_ring_mesh.material_override = m
	_ring_mesh.top_level = true
	_ring_mesh.visible = false
	add_child(_ring_mesh)
	model.play(&"idle" if duel or sealing else &"sit", 0.0)
	if sealing:
		add_to_group("star_eyes")
		_shield_mesh = MeshInstance3D.new()
		_shield_mesh.name = "FlameShield"
		var sm := SphereMesh.new()
		sm.radius = 1.5
		sm.height = 3.2
		sm.radial_segments = 14
		sm.rings = 8
		_shield_mesh.mesh = sm
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.albedo_color = Color(1.0, 0.5, 0.15, 0.32)
		fm.cull_mode = BaseMaterial3D.CULL_DISABLED
		fm.disable_fog = true
		_shield_mesh.material_override = fm
		_shield_mesh.position = Vector3(0, 1.4, 0)
		add_child(_shield_mesh)
		_set_shield(true)


## The flame shield (sealing) up or down.
func _set_shield(on: bool) -> void:
	shield_up = on
	if _shield_mesh:
		_shield_mesh.visible = on
	set_flame(on)


## A Starfall Arrow struck him (or burst beside him).
func starfall_hit(_arrow: Node3D) -> void:
	if not sealing or not shield_up or state in [State.THRONE, State.FINALE]:
		return
	_shield_breaks += 1
	_shield_down = SHIELD_DOWN
	_set_shield(false)
	Sfx.play("ward_out", 2.0, 0.0, 0.7)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.4, 20, 4.0, 4.0, 1.0, 1.0, Color(2.0, 1.1, 0.4))
	_go(State.STAGGER)


func set_flame(on: bool) -> void:
	if _flame:
		_flame.visible = on


## The throne-room scene starts the fight (Story.throne_room).
func wake() -> void:
	if state == State.THRONE:
		_go(State.RISE)


func is_targetable() -> bool:
	return super.is_targetable() and state != State.THRONE and state != State.FINALE


func _physics_process(delta: float) -> void:
	_update_ring(delta)
	if duel:
		_duel_check(delta)
	if sealing and not shield_up and _shield_down > 0.0 and state != State.FINALE:
		_shield_down -= delta
		if _shield_down <= 0.0:
			_set_shield(true)
			Sfx.play("fire_whoosh", 0.0, 0.0, 0.8)
	if _shield_mesh and _shield_mesh.visible:
		_shield_mesh.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.04)
	if state == State.THRONE and Progress.flag("castle:throne_seen") and not Cutscene.active and not duel and not sealing:
		# Back after a fall or a retreat: he rises as soon as the hero returns.
		var hp := _player()
		if hp and not hp.is_dead() and _flat_dist(hp.global_position) < 16.0 and absf(hp.global_position.y - global_position.y) < 3.0:
			wake()
	if _dead or state in [State.THRONE, State.FINALE]:
		velocity = Vector3.ZERO
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead() and not p.in_cutscene
	var dist := _flat_dist(p.global_position) if p else 99.0
	match state:
		State.RISE:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 90.0, delta)
			if _t >= 1.2:
				_go(State.STALK)
		State.STALK:
			if not alive:
				_brake(delta)
				model.play(&"idle", 0.2)
			else:
				_turn_to(p.global_position, 150.0, delta)
				if dist > 2.6:
					var v := _forward() * _pace()
					velocity.x = v.x
					velocity.z = v.z
					model.play(&"walk", 0.15)
				else:
					_brake(delta)
					model.play(&"guard", 0.15)
				if _t >= _plan:
					_choose(dist)
		State.SLASH_WINDUP:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 120.0, delta)
			if _t >= (0.42 if enraged else 0.55):
				_go(State.SLASH)
		State.SLASH:
			var lunge := _forward() * (6.0 if _t < 0.15 else 0.0)
			velocity.x = lunge.x
			velocity.z = lunge.z
			if attack_hitbox:
				if _t >= 0.05 and _t < 0.2 and not attack_hitbox.active:
					attack_hitbox.activate()
				elif _t >= 0.2:
					attack_hitbox.deactivate()
			if _t >= 0.35:
				# Enraged, a second cut follows the first more often than not.
				if enraged and not _chained and dist < 4.0 and randf() < 0.6:
					_chained = true
					_go(State.SLASH_WINDUP)
				else:
					_chained = false
					_go(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if _t >= (0.65 if enraged else 0.75):
				_plan = _next_plan(1.0, 1.8)
				_go(State.STALK)
		State.DASH_WINDUP:
			# Crouched low with the blade back and the Gauntlet blazing: then
			# he crosses the floor in a rush of flame.
			_brake(delta)
			if p:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.55:
				_go(State.DASH)
		State.DASH:
			var dv := _forward() * 13.0
			velocity.x = dv.x
			velocity.z = dv.z
			if attack_hitbox and not attack_hitbox.active:
				attack_hitbox.activate()
			if int(_t * 20.0) != int((_t - delta) * 20.0):
				Story._flames(global_position, 0.6, false)
			if _t >= 0.45 or (alive and dist < 1.6):
				_go(State.RECOVER)
		State.CAST:
			_brake(delta)
			if p:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.32 and _t - delta < 0.32:
				_fireballs()
			if enraged and _t >= 0.62 and _t - delta < 0.62:
				_fireballs()
			if _t >= 0.9:
				set_flame(false)
				_plan = _next_plan(1.2, 2.0)
				_go(State.STALK)
		State.RING:
			_brake(delta)
			for at: float in ([0.8, 1.35] if enraged else [0.8]):
				if _t >= at and _t - delta < at:
					_ring = 0.5
					_ring_hit = false
					Sfx.play("fire_whoosh", 0.0, 0.05)
			if _t >= (2.0 if enraged else 1.6):
				set_flame(false)
				_plan = _next_plan(1.2, 2.0)
				_go(State.STALK)
		State.STAGGER:
			_brake(delta)
			if _t >= 2.0:
				_plan = 0.8
				_go(State.STALK)
	_fall(delta)
	move_and_slide()
	rotation.y = facing_yaw


## The duel ends when he has had his fun: time up, enough blows landed, or
## the hero nearly down.
func _duel_check(delta: float) -> void:
	if _duel_over or state in [State.THRONE, State.RISE, State.FINALE] or Cutscene.active:
		return
	_duel_t += delta
	var p := _player()
	var low := p != null and p.health.health <= DUEL_SPARE
	if _duel_t >= DUEL_TIME or hits >= DUEL_HITS or low:
		_duel_over = true
		_begin_finale()


## The blows this fight takes before the story takes over.
func hits_needed() -> int:
	return DUEL_HITS if duel else (SEAL_HITS if sealing else THRONE_HITS)


## His stalking pace.
func _pace() -> float:
	return 3.3 if enraged else 2.6


## How long he weighs his next move.
func _next_plan(lo: float, hi: float) -> float:
	return randf_range(lo, hi) * (0.6 if enraged else 0.85)


func _choose(dist: float) -> void:
	var r := randf()
	if dist < 3.4 and r < 0.65:
		_go(State.SLASH_WINDUP)
	elif dist > 6.0 and r < (0.45 if enraged else 0.25):
		_go(State.DASH_WINDUP)
	elif r < 0.55:
		_go(State.CAST)
	elif r < 0.85:
		_go(State.RING)
	else:
		_go(State.SLASH_WINDUP)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.SLASH and s != State.DASH:
		attack_hitbox.deactivate()
	match s:
		State.RISE:
			model.play(&"idle", 0.4)
			Cutscene.boss_intro(self, TITLE, "THE BURNING KING" if sealing else SUBTITLE, "firebuns_theme" if duel else "final_battle", 1.9, 6.0, 2.6)
		State.SLASH_WINDUP:
			model.play(&"slash_windup", 0.06, 1.0, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.7)
		State.SLASH:
			model.play(&"slash", 0.02, 1.0, true)
			Sfx.play("heavy_swing", -2.0, 0.05)
		State.RECOVER:
			model.play(&"recover", 0.05, 1.0, true)
		State.CAST:
			model.play(&"cast", 0.06, 1.0, true)
			set_flame(true)
			Sfx.play("fire_whoosh", -4.0, 0.05, 1.3)
		State.RING:
			model.play(&"raise", 0.1)
			set_flame(true)
			Sfx.play("firebuns_laugh", -4.0, 0.0)
		State.STAGGER:
			model.play(&"stagger", 0.08)
			set_flame(false)
			Sfx.play("boss_hurt", -2.0, 0.05, 0.9)
		State.DASH_WINDUP:
			model.play(&"slash_windup", 0.08, 0.7, true)
			set_flame(true)
			Sfx.play("fire_whoosh", -2.0, 0.05, 0.8)
		State.DASH:
			model.play(&"slash", 0.02, 1.0, true)
			Sfx.play("heavy_swing", 0.0, 0.05, 0.85)


func _fireballs() -> void:
	var p := _player()
	var aim := _forward()
	if p:
		aim = _flat_to(p.global_position).normalized()
	Sfx.play("fire_whoosh", -2.0, 0.05, 1.5)
	var n := 5 if enraged else 3
	for i in n:
		var a := (float(i) - (n - 1) * 0.5) * deg_to_rad(16.0 if enraged else 18.0)
		var orb := Rock.new()
		orb.mesh_path = "res://assets/models/fire_orb_mesh.tres"
		orb.damage = 2
		orb.speed = (10.0 if enraged else 9.0) + (_shield_breaks * 1.2 if sealing else 0.0)
		orb.life = 2.6
		orb.burst_tint = Color(2.0, 1.1, 0.4)
		get_parent().add_child(orb)
		orb.launch(global_position + Vector3.UP * 1.5 + aim * 0.8, aim.rotated(Vector3.UP, a), self)


## The ring of fire rolling out across the floor from his feet.
func _update_ring(delta: float) -> void:
	if _ring < 0.0:
		_ring_mesh.visible = false
		return
	_ring += RING_SPEED * delta
	_ring_mesh.visible = true
	_ring_mesh.global_position = Vector3(global_position.x, global_position.y + 0.4, global_position.z)
	_ring_mesh.scale = Vector3(_ring, 2.0, _ring)
	var p := _player()
	if p and not _ring_hit and not p.is_dead():
		var d := _flat_dist(p.global_position)
		if absf(d - _ring) < 0.6 and absf(p.global_position.y - global_position.y) < 1.5:
			_ring_hit = true
			var info := HitInfo.new()
			info.damage = 2
			info.knockback = 7.0
			info.attacker = self
			info.source_position = global_position
			p.take_hit(info)
	if _ring > RING_MAX:
		_ring = -1.0


# --- Damage -------------------------------------------------------------------

## Head-on, his guard turns blades aside, except while he is open.
func _guard(info: HitInfo) -> int:
	if state in [State.THRONE, State.RISE, State.FINALE]:
		return Hurtbox.Result.IGNORED
	# The flame shield turns everything but starlight.
	if sealing and shield_up:
		Sfx.play("fire_whoosh", -4.0, 0.08, 1.6)
		return Hurtbox.Result.BLOCKED
	if info.reflected or info.bomb:
		return Hurtbox.Result.HIT
	if state in [State.RECOVER, State.STAGGER, State.CAST, State.RING]:
		return Hurtbox.Result.HIT
	var from := _flat_to(info.source_position).normalized()
	if from.dot(_forward()) > 0.2:
		Sfx.play("shield_block", -2.0, 0.08, 0.8)
		model.play(&"guard", 0.04)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func take_hit(info: HitInfo) -> int:
	var r := super.take_hit(info)
	if r == Hurtbox.Result.HIT and not _dead and state != State.FINALE:
		hits += 1
		# His health is only a guard against falling early (hits_needed ends it).
		health.health = maxi(health.health, health.max_health / 2)
		if not enraged and hits * 2 >= hits_needed():
			enraged = true
			Sfx.play("firebuns_laugh", -2.0, 0.0, 0.85)
			_plan = 0.4
		if info.reflected:
			_go(State.STAGGER)
		if hits >= hits_needed() and not duel:
			_begin_finale()
	return r


func _hurt(_info: HitInfo) -> void:
	model.play(&"hurt", 0.02, 1.0, true)
	Sfx.play("boss_hurt", -4.0, 0.08, 1.1)


## He has had enough of playing: the story takes over.
func _begin_finale() -> void:
	state = State.FINALE
	_ring = -1.0
	velocity = Vector3.ZERO
	if attack_hitbox:
		attack_hitbox.deactivate()
	_set_hurtbox(false)
	if duel:
		Story.keep_duel_end(self)
	elif sealing:
		_set_shield(false)
		Story.sealing(self)
	else:
		Story.finale(self)


## He never falls here (the finale cuts the fight short).
func _die() -> void:
	_begin_finale()
