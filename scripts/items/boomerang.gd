class_name Boomerang
extends Node3D
## The Boomerang, after OoT's EnBoom (z_en_boom.c):
## - Thrown from 10 units in front of the hero and 30 up, it flies at 12 units
##   a frame (Actor_SetProjectileSpeed(12): about 10.8 m/s) for 20 frames
##   (returnTimer), then turns for home and flies back to him; within 40 units
##   (1.2 m) he catches it.
## - Thrown while Z-targeting, it sets off 14000 units to the side and curves
##   in on the target, turning faster the closer it gets (distXYZScale).
## - Hitting a wall, a creature or a switch sends it straight back
##   (returnTimer = 0). Creatures are stunned (and the frailest, like keese,
##   fall); crystal switches flip; shrubs are cut and pots break.
## - An item it touches (rupees, hearts, keys) rides back with it to the hero.

const OOT_FPS := 20.0
const UNIT := 0.03
const SPEED := 12.0 * 1.5 * UNIT * OOT_FPS
const RETURN_FRAMES := 20.0
const CATCH := 40.0 * UNIT
## How far it flies before it turns for home.
const RANGE := SPEED * RETURN_FRAMES / OOT_FPS
const BINANG := TAU / 65536.0
const MAX_LIFE := 6.0
## World (1) and every hurtbox that is not the hero's (16).
const HIT_MASK := 1 | 16

var thrower: PlayerController = null
var target: Node3D = null
var carried: Collectible = null
var returning := false
var hits: Array = []
var _yaw := 0.0
var _pitch := 0.0
var _timer := RETURN_FRAMES
var _life := 0.0
var _mesh: MeshInstance3D
var _sound: AudioStreamPlayer


func _ready() -> void:
	add_to_group("boomerangs")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/boomerang_mesh.tres")
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.rotation.x = 0.25
	add_child(_mesh)
	_sound = AudioStreamPlayer.new()
	_sound.bus = "SFX"
	var spin_path := "res://assets/audio/boomerang_spin.wav"
	if ResourceLoader.exists(spin_path):
		var s: AudioStreamWAV = load(spin_path)
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
		_sound.stream = s
		_sound.volume_db = -10.0
	add_child(_sound)


## Throws it from the hero, along his facing (or the aim's yaw and pitch), or
## at `lock` when he is Z-targeting. An aimed throw passes `from` on the
## camera's line of sight, so it flies to the middle of the view.
func throw(by: PlayerController, yaw: float, pitch: float, lock: Node3D, from := Vector3.INF) -> void:
	thrower = by
	target = lock
	_yaw = yaw + (14000.0 * BINANG if lock else 0.0)
	_pitch = pitch
	if from != Vector3.INF:
		global_position = from
	else:
		global_position = by.global_position + Vector3(-sin(yaw), 0, -cos(yaw)) * 10.0 * UNIT + Vector3.UP * 0.9
	if _sound.stream:
		_sound.play()
	Sfx.play("boomerang_throw", -4.0)


func _dir() -> Vector3:
	return Vector3(-sin(_yaw) * cos(_pitch), sin(_pitch), -cos(_yaw) * cos(_pitch))


func _physics_process(delta: float) -> void:
	_life += delta
	if not is_instance_valid(thrower) or thrower.is_dead() or _life > MAX_LIFE:
		_finish()
		return
	var f := delta * OOT_FPS
	var home := thrower.global_position + Vector3.UP * 1.0
	var goal: Node3D = null
	if returning:
		_steer(home, f)
	elif is_instance_valid(target):
		goal = target
		var aim: Vector3 = target.aim_point() if target.has_method("aim_point") else target.global_position + Vector3.UP * 1.0
		var yaw_to := atan2(-(aim - global_position).x, -(aim - global_position).z)
		if absf(angle_difference(_yaw, yaw_to)) > PI / 2.0:
			target = null
		else:
			_steer(aim, f)
	_timer -= f
	if _timer <= 0.0 and not returning:
		returning = true
	if returning and global_position.distance_to(home) < CATCH:
		_caught()
		return
	var from := global_position
	var to := from + _dir() * SPEED * delta
	if not returning:
		var q := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK)
		q.collide_with_areas = true
		var ex: Array[RID] = [thrower.get_rid()]
		var phb := thrower.get_node_or_null("Hurtbox") as Area3D
		if phb:
			ex.append(phb.get_rid())
		q.exclude = ex
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			_strike(hit)
			_bounce()
			return
	global_position = to
	if carried and is_instance_valid(carried):
		carried.global_position = global_position - Vector3.UP * 0.3
	_mesh.rotation.y += 28.0 * delta
	var _unused := goal


## EnBoom_Fly: turn toward `point` by a share of the gap that grows as it nears.
func _steer(point: Vector3, f: float) -> void:
	var to := point - global_position
	var dist_units := to.length() / UNIT
	var k := maxf((200.0 - dist_units) * 0.005, 0.12)
	var yaw_t := atan2(-to.x, -to.z)
	var pitch_t := atan2(to.y, Vector2(to.x, to.z).length())
	var dy := angle_difference(_yaw, yaw_t)
	var dp := pitch_t - _pitch
	_yaw += clampf(dy, -absf(dy) * k * 1.5 * f, absf(dy) * k * 1.5 * f)
	_pitch += clampf(dp, -absf(dp) * k * 1.5 * f, absf(dp) * k * 1.5 * f)
	if returning and to.length() < 3.0:
		# Close in: home straight onto the hero's hands.
		_yaw = yaw_t
		_pitch = pitch_t


## What it touched: creatures, switches, plants, pots and items.
func _strike(hit: Dictionary) -> void:
	var hb := hit.collider as Hurtbox
	var who: Object = hb.receiver if hb else hit.collider
	if who == null:
		Sfx.play("shield_block", -10.0, 0.05, 1.4)
		return
	hits.append(who)
	if who is Collectible:
		carried = who as Collectible
		carried.attach_to(self)
		return
	if who is Enemy:
		var e := who as Enemy
		e.boomerang_hit(self)
		if e.boomerang_damage > 0 and hb:
			var info := HitInfo.new()
			info.damage = e.boomerang_damage
			info.knockback = 1.5
			info.attacker = thrower
			info.source_position = global_position - _dir()
			hb.receive_hit(info)
		Sfx.play("arrow_hit", -6.0, 0.05, 1.3)
		return
	if who.has_method("boomerang_hit"):
		who.boomerang_hit(self)
		return
	Sfx.play("shield_block", -10.0, 0.05, 1.4)


## Back to the hero at once (returnTimer = 0, rot.y += 0x8000).
func _bounce() -> void:
	returning = true
	_timer = 0.0
	_yaw += PI
	_pitch = -_pitch


func _caught() -> void:
	if carried and is_instance_valid(carried):
		carried.collect(thrower)
	Sfx.play("boomerang_catch", -6.0)
	_finish()


func _finish() -> void:
	if is_instance_valid(thrower) and thrower.boomerang == self:
		thrower.boomerang = null
	queue_free()
