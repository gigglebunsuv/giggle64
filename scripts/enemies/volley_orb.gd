class_name VolleyOrb
extends Node3D
## The Gauntlet's great orb in the last battle's second phase (Beta 1.5.0),
## after Ganondorf's energy ball in OoT (z_boss_ganon.c, the "tennis" volley):
## it homes on the hero; a swing of the sword sends it back at Firebuns,
## faster each time. He bats it back while he can; when the rally beats him
## he takes it full in the chest and staggers (FirebunsFinal.volley_reached).
## A shield only stops it (it bursts); left alone it strikes the hero.

const DAMAGE := 3
const SPEED := 8.0
const SPEED_UP := 1.8
const HIT_REACH := 0.9

var shooter: Node3D = null
var toward_hero := true
var rally := 0
var speed := SPEED
var _life := 8.0
var _mesh: MeshInstance3D
var _light: OmniLight3D
var _hurtbox: Hurtbox


func _ready() -> void:
	add_to_group("projectiles")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/fire_orb_mesh.tres")
	_mesh.scale = Vector3.ONE * 2.4
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.25)
	_light.light_energy = 2.0
	_light.omni_range = 5.0
	add_child(_light)
	# The hero's blade finds it like a creature (layer 16).
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.receiver = self
	_hurtbox.collision_layer = 16
	_hurtbox.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.6
	cs.shape = sp
	_hurtbox.add_child(cs)
	add_child(_hurtbox)


func launch(from: Vector3, by: Node3D) -> void:
	shooter = by
	global_position = from


func _target() -> Vector3:
	if toward_hero:
		var p := GameManager.player
		return p.global_position + Vector3.UP * 1.1 if is_instance_valid(p) else global_position
	return shooter.global_position + Vector3.UP * 1.4 if is_instance_valid(shooter) else global_position


func _physics_process(delta: float) -> void:
	_life -= delta
	_mesh.rotation.y += delta * 6.0
	if _life <= 0.0 or not is_instance_valid(shooter):
		_burst()
		return
	var to := _target()
	var d := to - global_position
	if d.length() < HIT_REACH:
		if toward_hero:
			_strike_hero()
		else:
			shooter.call("volley_reached", self)
		return
	global_position += d.normalized() * minf(speed * delta, d.length())


func _strike_hero() -> void:
	var p := GameManager.player
	if is_instance_valid(p) and not p.is_dead():
		var info := HitInfo.new()
		info.damage = DAMAGE
		info.knockback = 7.0
		info.attacker = shooter
		info.source_position = global_position - (p.global_position - global_position).normalized()
		p.take_hit(info)
	_burst()


## The hero's sword: back it goes, faster. (Anything else just bursts it.)
func take_hit(info: HitInfo) -> int:
	if not toward_hero:
		return Hurtbox.Result.IGNORED
	if info.attacker is PlayerController and not info.reflected and not info.bomb:
		send_back()
		return Hurtbox.Result.HIT
	_burst()
	return Hurtbox.Result.HIT


## Turned round toward Firebuns (or, from him, toward the hero again).
func send_back() -> void:
	toward_hero = not toward_hero
	rally += 1
	speed += SPEED_UP
	_life = 8.0
	Sfx.play("sword_beam" if not toward_hero else "fire_whoosh", -2.0, 0.05, 1.2 + rally * 0.05)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 6, 2.0, 2.0, 0.4, 0.5, Color(2.0, 1.2, 0.5))


func _burst() -> void:
	Sfx.play("fire_whoosh", -4.0, 0.08, 1.6)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 10, 3.0, 3.0, 0.6, 0.8, Color(2.0, 1.1, 0.4))
	queue_free()
