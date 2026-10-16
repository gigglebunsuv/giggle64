extends "res://scripts/enemies/firebuns.gd"
## FIREBUNS III, the true final battle (Beta 1.5.0), at the heart of the
## Astral Rift beside his shattered ice prison. Everything he has, in three
## phases (the masterplan's flame, Gauntlet, and Denangdyn's shadow):
##   1 FLAME     the Citadel roof again, hotter: the FLAME SHIELD turns
##               everything until a Starfall Arrow breaks it; then the duel.
##   2 GAUNTLET  no shield now; the Gauntlet answers him fully: METEORS fall
##               where the hero stands (shadows warn), and the GREAT ORB
##               (VolleyOrb) homes on him: struck back with the sword it
##               rallies until the king misses and takes it in the chest,
##               staggering. Otherwise his guard holds head-on as ever.
##   3 SHADOW    Denangdyn's shadow pours through him: he hangs wrapped in it
##               over the ice, untouchable, while two SHADOW HANDS strike.
##               Stun both (a blessed blade on a stuck palm, or a Parry of a
##               sweep) and the king is laid bare for a few breaths: only the
##               Bun Sword carrying Avalon's starlight can wound him then.
## Between phases the story takes a breath (Story.final_phase); the last
## blow ends it (Story.final_blow).

const P_HITS := [0, 8, 8, 6]
const BARE_TIME := 5.0
const METEOR_DAMAGE := 3

var phase := 1
var _hands: Array[Node] = []
var _bare := 0.0
var _volley_cool := 0.0
var _meteor_marks: Array[Node3D] = []
var _shadow_mesh: MeshInstance3D


func _ready() -> void:
	sealing = true
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = 4


## His entrance (Story.rift_heart wakes him): his own card and the last
## battle's music.
func _go(s: State) -> void:
	if s == State.RISE:
		state = s
		_t = 0.0
		model.play(&"idle", 0.4)
		Cutscene.boss_intro(self, TITLE, "THE LAST FLAME OF BATELA", "true_final_battle", 1.9, 6.5, 2.6)
		return
	super._go(s)


func hits_needed() -> int:
	return P_HITS[phase]


func _begin_finale() -> void:
	state = State.FINALE
	_ring = -1.0
	velocity = Vector3.ZERO
	if attack_hitbox:
		attack_hitbox.deactivate()
	_set_hurtbox(false)
	_set_shield(false)
	for m in _meteor_marks:
		if is_instance_valid(m):
			m.queue_free()
	_meteor_marks.clear()
	for n in get_tree().get_nodes_in_group("projectiles"):
		if n is VolleyOrb or n is Rock:
			(n as Node).queue_free()
	if phase < 3:
		Story.final_phase(self, phase + 1)
	else:
		for h in _hands:
			if is_instance_valid(h):
				h.call("vanish")
		Story.final_blow(self)


## The story's breath is over: the next phase begins.
func begin_phase(n: int) -> void:
	phase = n
	hits = 0
	enraged = false
	_set_hurtbox(true)
	match n:
		2:
			sealing = false
			_set_shield(false)
			_plan = 1.0
			_go(State.STALK)
		3:
			sealing = false
			_set_shield(false)
			_wrap_in_shadow(true)
			for h in get_tree().get_nodes_in_group("shadow_hands"):
				_hands.append(h)
				h.call("wake", self)
			state = State.STAGGER
			_t = 0.0
			model.play(&"raise", 0.3)


func _wrap_in_shadow(on: bool) -> void:
	if on and _shadow_mesh == null:
		_shadow_mesh = MeshInstance3D.new()
		_shadow_mesh.name = "Shadow"
		var sm := SphereMesh.new()
		sm.radius = 1.6
		sm.height = 3.4
		sm.radial_segments = 14
		sm.rings = 8
		_shadow_mesh.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.08, 0.04, 0.16, 0.55)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.disable_fog = true
		_shadow_mesh.material_override = m
		_shadow_mesh.position = Vector3(0, 1.4, 0)
		add_child(_shadow_mesh)
	if _shadow_mesh:
		_shadow_mesh.visible = on


func _physics_process(delta: float) -> void:
	_update_meteors(delta)
	_volley_cool = maxf(_volley_cool - delta, 0.0)
	if phase == 3 and not _dead and state != State.FINALE:
		_phase3(delta)
		return
	super._physics_process(delta)


## Phase 3: he hangs over the ice in the shadow while the hands fight; both
## hands stunned at once lay him bare.
func _phase3(delta: float) -> void:
	_update_ring(delta)
	velocity = Vector3.ZERO
	var both := _hands.size() >= 2
	for h in _hands:
		if not is_instance_valid(h) or not h.call("stunned"):
			both = false
	if _bare > 0.0:
		_bare -= delta
		if _bare <= 0.0:
			_wrap_in_shadow(true)
			model.play(&"raise", 0.3)
			Sfx.play("undead_rise", -4.0, 0.0, 0.6)
	elif both:
		_bare = BARE_TIME
		_wrap_in_shadow(false)
		model.play(&"stagger", 0.1)
		Sfx.play("boss_hurt", 0.0, 0.0, 0.8)
	var p := _player()
	if p:
		_turn_to(p.global_position, 60.0, delta)
	rotation.y = facing_yaw


func _choose(dist: float) -> void:
	if phase == 2:
		var r := randf()
		if r < 0.3 and _volley_cool <= 0.0:
			_volley_cool = 6.0
			_go(State.CAST)
			return
		if r < 0.5:
			_go(State.RING)
			return
	super._choose(dist)


## Phase 2: the CAST throws the great orb (or the fireballs while one is out);
## the RING calls meteors down instead of fire along the floor.
func _fireballs() -> void:
	if phase != 2:
		super._fireballs()
		return
	for n in get_tree().get_nodes_in_group("projectiles"):
		if n is VolleyOrb:
			super._fireballs()
			return
	var orb := VolleyOrb.new()
	get_parent().add_child(orb)
	orb.launch(global_position + Vector3.UP * 2.2 + _forward() * 0.6, self)
	Sfx.play("fire_whoosh", 0.0, 0.0, 0.6)


func _update_ring(delta: float) -> void:
	if phase == 2 and _ring >= 0.0:
		_ring = -1.0
		_meteors()
	super._update_ring(delta)


func _meteors() -> void:
	var p := _player()
	if p == null:
		return
	Sfx.play("firebuns_laugh", -4.0, 0.0, 0.9)
	for i in 5:
		var off := Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)) if i > 0 else Vector3.ZERO
		var m := MeshInstance3D.new()
		m.name = "MeteorMark"
		m.mesh = load("res://assets/models/blob_shadow_mesh.tres")
		m.top_level = true
		m.set_meta("t", 0.0)
		m.set_meta("delay", 0.9 + i * 0.25)
		get_parent().add_child(m)
		m.global_position = Vector3(p.global_position.x, global_position.y + 0.05, p.global_position.z) + off
		m.scale = Vector3.ONE * 2.6
		_meteor_marks.append(m)


func _update_meteors(delta: float) -> void:
	for m in _meteor_marks.duplicate():
		if not is_instance_valid(m):
			_meteor_marks.erase(m)
			continue
		var t: float = float(m.get_meta("t")) + delta
		m.set_meta("t", t)
		var delay: float = m.get_meta("delay")
		m.scale = Vector3.ONE * lerpf(2.6, 1.2, clampf(t / delay, 0.0, 1.0))
		if t >= delay:
			_meteor_marks.erase(m)
			var at: Vector3 = m.global_position
			m.queue_free()
			Story._flames(at, 0.7, false)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), at + Vector3.UP * 0.4, 10, 3.0, 3.0, 0.6, 0.8, Color(2.0, 1.1, 0.4))
			Sfx.play("bomb_explode", -6.0, 0.08, 1.2)
			var p := GameManager.player
			if p and not p.is_dead() and Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() < 1.4 and absf(p.global_position.y - at.y) < 1.5:
				var info := HitInfo.new()
				info.damage = METEOR_DAMAGE
				info.knockback = 6.0
				info.unblockable = true
				info.attacker = self
				info.source_position = at
				p.take_hit(info)


## The great orb came back to him: he bats it back while the rally is short,
## and the longer it runs the likelier he misses.
func volley_reached(orb: VolleyOrb) -> void:
	if state in [State.FINALE] or _dead:
		orb.queue_free()
		return
	if randf() < clampf(0.75 - orb.rally * 0.18, 0.0, 0.75):
		model.play(&"slash", 0.02, 1.0, true)
		orb.send_back()
		return
	orb.queue_free()
	Story._burst(global_position + Vector3.UP * 1.4, Color(1.0, 0.7, 0.35), 2.5)
	Sfx.play("boss_hurt", 0.0, 0.0, 0.85)
	_go(State.STAGGER)


func _guard(info: HitInfo) -> int:
	if phase == 3:
		if _bare > 0.0 and info.attacker is PlayerController and Progress.flag("rift:blessed") and not info.bomb:
			return Hurtbox.Result.HIT
		Sfx.play("shield_block", -4.0, 0.06, 0.5)
		return Hurtbox.Result.BLOCKED
	return super._guard(info)
