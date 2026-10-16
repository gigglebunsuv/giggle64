extends "res://scripts/enemies/mummy.gd"
## The Mummy Lord, mini-boss of Ladhellin Tower's crypt: the old high priest of
## the sun, crowned and twice a man's height in his grave-wrappings. He fights
## like his mummies, slower and harder, and sweeps round with both arms when
## the hero gets behind him. Half beaten, he calls two mummies from their
## coffins. Fire does him real harm: burning arrows from the crypt's braziers.

const MINION := "res://scenes/enemies/mummy.tscn"

var _called := false
var _sweep: Hitbox


func _ready() -> void:
	super._ready()
	corpse_time = 2.0
	walk_speed = 1.0
	reach_time = 0.9
	notice_range = 14.0
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 8.0
	_sweep = Hitbox.new()
	_sweep.name = "SweepHitbox"
	_sweep.collision_layer = 64
	_sweep.collision_mask = 8
	_sweep.attacker = self
	_sweep.damage = 2
	_sweep.knockback = 7.0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.8
	cyl.height = 1.6
	cs.shape = cyl
	cs.position = Vector3(0, 1.0, 0)
	_sweep.add_child(cs)
	add_child(_sweep)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _dead:
		_sweep.deactivate()
		return
	# The sweep: when the hero is close behind him, the arms swing round.
	if state == State.GRAB and _sweep_round:
		if _t >= 0.08 and _t < 0.35 and not _sweep.active:
			_sweep.activate()
		elif _t >= 0.35:
			_sweep.deactivate()
	elif _sweep.active:
		_sweep.deactivate()


var _sweep_round := false


func _go(s: State) -> void:
	if s == State.REACH:
		var p := _player()
		_sweep_round = p != null and _forward().dot(_flat_to(p.global_position).normalized()) < 0.3
	super._go(s)
	if s == State.GRAB and _sweep_round:
		model.play(&"sweep", 0.03, 1.0, true)
		if attack_hitbox:
			attack_hitbox.deactivate()


func _hurt(info: HitInfo) -> void:
	super._hurt(info)
	if not _called and health.health <= health.max_health / 2:
		_called = true
		_call_minions()


func _call_minions() -> void:
	Sfx.play("boss_roar", -4.0, 0.05, 1.3)
	for side in [-1.0, 1.0]:
		var m: Node3D = load(MINION).instantiate()
		m.set_meta("room", get_meta("room", ""))
		get_parent().add_child(m)
		m.global_position = global_position + global_basis.x * side * 3.5 + Vector3.UP * 0.2
		m.rotation.y = rotation.y


func burn() -> void:
	if _dead:
		return
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 2.2, 16, 2.4, 3.4, 1.4, 1.2, Color(1.8, 0.8, 0.2))
	Sfx.play("torch_light", -1.0)
	health.apply_damage(3)
	stun(1.6)


func _die() -> void:
	_sweep.deactivate()
	Sfx.play("boss_die", -4.0, 0.05, 1.2)
	super._die()
