class_name Collectible
extends Area3D
## A small item lying in the world: rupees, recovery hearts, arrows, small
## keys. Behaves like OoT's EnItem00 (z_en_item00.c):
## - A dropped item (Item_DropCollectibleRandom) pops out with velocity.y 8 and
##   speed 2 in a random direction under gravity -0.9 (OoT units per 20 Hz
##   frame, moved x1.5), grows from nothing to full size, bounces off the floor
##   at 0.8x while falling faster than 2, and settles. It vanishes after 220
##   frames, flickering through the last 40 (func_8001E5C8 / unk_156).
## - Placed items stay until taken. Rupees spin 960 binary angle units a frame;
##   a falling recovery heart drifts down slowly (gravity -0.4, at most 1.5)
##   swaying from side to side (func_8001E304).
## - Touching it (or striking it with the sword, an arrow or the boomerang)
##   collects it; it then floats over the hero's head for 15 frames.

const OOT_FPS := 20.0
const OOT_RATE := 1.5
const UNIT := 0.03
const DESPAWN := 220.0
const FLICKER := 40.0
const BINANG := TAU / 65536.0
const MODEL_DIR := "res://assets/models/"

## rupee_green / rupee_blue / rupee_red / heart / arrows_5 / arrows_10 /
## arrows_30 / small_key.
@export var kind := "rupee_green"
## Dropped by something (pops up, vanishes after a while) or placed (stays).
@export var dropped := false

var collected := false
## OoT units per frame.
var _vy := 0.0
var _speed := 0.0
var _yaw := 0.0
var _gravity := 0.0
var _frames := 0.0
var _age := 0.0
var _scale := 1.0
var _sway := 0.0
var _settled := true
var _visual: Node3D
var _carrier: Node3D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("pickups")
	add_to_group("collectibles")
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var s := SphereShape3D.new()
	s.radius = 0.55
	cs.shape = s
	cs.position = Vector3(0, 0.35, 0)
	add_child(cs)
	# The sword, arrows and boomerang collect items too (AC_TYPE_PLAYER).
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	# EnItem00's cylinder: radius 10, height 30 units (about the boomerang's flight height).
	var hcs := CollisionShape3D.new()
	var hs := CylinderShape3D.new()
	hs.radius = 0.4
	hs.height = 1.2
	hcs.shape = hs
	hcs.position = Vector3(0, 0.6, 0)
	hb.add_child(hcs)
	add_child(hb)
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = _mesh()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(mi)
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = load(MODEL_DIR + "blob_shadow_mesh.tres")
	shadow.set_script(load("res://scripts/systems/blob_shadow.gd"))
	shadow.set("radius", 0.22)
	add_child(shadow)
	body_entered.connect(_on_body_entered)
	if dropped:
		_vy = 8.0
		_speed = 2.0
		_gravity = 0.9
		_yaw = randf() * 40000.0 * BINANG
		_scale = 0.0
		_settled = false
	_visual.position.y = 0.3
	_visual.scale = Vector3.ONE * maxf(_scale, 0.01)


func _mesh() -> Mesh:
	var file := kind
	if kind.begins_with("arrows"):
		file = "arrow_bundle"
	elif kind.begins_with("bombs"):
		file = "bomb"
	elif kind.begins_with("nuts"):
		file = "puff_nut"
	var path := MODEL_DIR + file + "_mesh.tres"
	return load(path) if ResourceLoader.exists(path) else load(MODEL_DIR + "rupee_green_mesh.tres")


func value() -> int:
	match kind:
		"rupee_green": return 1
		"rupee_blue": return 5
		"rupee_red": return 20
		"arrows_5": return 5
		"arrows_10": return 10
		"arrows_30": return 30
		"bombs_5": return 5
		"bombs_10": return 10
		"nuts_5": return 5
		"nuts_10": return 10
		# OoT's magic jars: the small one 12 units, the large one fills the meter.
		"magic_small": return 12
		"magic_large": return 96
	return 1


func _physics_process(delta: float) -> void:
	if collected:
		return
	var f := delta * OOT_FPS
	_age += delta
	if _carrier:
		if is_instance_valid(_carrier):
			global_position = _carrier.global_position - Vector3.UP * 0.3
		else:
			_carrier = null
		return
	if not _settled:
		_fly(f)
	# Touching it collects it once it has been out a moment (it may appear
	# right on top of the hero).
	if _age > 0.25 and _age - delta <= 0.25:
		for b in get_overlapping_bodies():
			if b is PlayerController and not b.is_dead():
				collect(b)
				return
	if dropped:
		_frames += f
		if _frames >= DESPAWN:
			queue_free()
			return
		var left := DESPAWN - _frames
		_visual.visible = left > FLICKER or int(_frames) % 2 == 0
	_scale = move_toward(_scale, 1.0, maxf((1.0 - _scale) * 0.1, 0.1) * f)
	_visual.scale = Vector3.ONE * maxf(_scale, 0.01)


func _process(delta: float) -> void:
	if collected or _visual == null:
		return
	if kind.begins_with("rupee") or kind == "small_key":
		_visual.rotation.y += 960.0 * BINANG * OOT_FPS * delta
	elif kind == "heart":
		_visual.rotation.y += 400.0 * BINANG * OOT_FPS * delta
	elif kind.begins_with("arrows"):
		_visual.rotation.y += 600.0 * BINANG * OOT_FPS * delta


## Rising and falling under gravity, bouncing off the floor.
func _fly(f: float) -> void:
	var heart := kind == "heart"
	if heart and _vy < 0.0:
		# The recovery heart floats down, swaying (func_8001E304).
		_speed = 0.0
		_gravity = 0.4
		_vy = maxf(_vy, -1.5)
		_sway += (_vy + 3.0) * 1000.0 * BINANG * f
	_vy -= _gravity * f
	if heart and _vy < 0.0:
		_vy = maxf(_vy, -1.5)
	var step := Vector3(-sin(_yaw) * _speed, _vy, -cos(_yaw) * _speed) * OOT_RATE * UNIT * f
	if heart and _speed == 0.0:
		step.x += cos(_sway) * 3.0 * UNIT * f * 0.5
	var from := global_position
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.3, from + step + Vector3.DOWN * 0.02, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and step.y <= 0.0:
		global_position = hit.position
		if _vy > -2.0 or heart:
			_settled = true
			_vy = 0.0
			_speed = 0.0
		else:
			_vy *= -0.8
		return
	if not hit.is_empty():
		# A wall: stop moving sideways.
		_speed = 0.0
		step.x = 0.0
		step.z = 0.0
	global_position = from + step


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and not body.is_dead() and _age > 0.25:
		collect(body)


## The sword or an arrow touched it.
func take_hit(info: HitInfo) -> int:
	if info.attacker is PlayerController and not collected:
		collect(info.attacker)
	return Hurtbox.Result.IGNORED


## The boomerang carries it back to the hero.
func attach_to(carrier: Node3D) -> void:
	_carrier = carrier
	_settled = true


func collect(by: Node3D) -> void:
	if collected:
		return
	collected = true
	_give(by)
	set_deferred("monitoring", false)
	var hb := get_node_or_null("Hurtbox") as Area3D
	if hb:
		hb.set_deferred("monitorable", false)
		hb.set_deferred("collision_layer", 0)
	var shadow := get_node_or_null("BlobShadow")
	if shadow:
		shadow.queue_free()
	# EnItem00_Collected: it bounces above the hero's head for 15 frames.
	_visual.visible = true
	_visual.scale = Vector3.ONE
	var t := create_tween()
	var head := by.global_position + Vector3.UP * 2.1 if by else global_position + Vector3.UP
	_visual.top_level = true
	_visual.global_position = head
	t.tween_property(_visual, "global_position", head + Vector3.UP * 0.35, 0.375).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(queue_free)


func _give(_by: Node3D) -> void:
	match kind:
		"rupee_green":
			Progress.add_rupees(1)
			Sfx.play("rupee", -4.0, 0.0)
		"rupee_blue", "rupee_red":
			Progress.add_rupees(value())
			Sfx.play("rupee_big", -4.0, 0.0)
		"heart":
			var p := GameManager.player
			if p:
				p.health.heal(2)
			Sfx.play("heart", -4.0, 0.0)
		"small_key":
			Progress.add_key(World.dungeon_id())
			Sfx.play("puzzle_solved", -6.0, 0.0)
		_:
			if kind.begins_with("arrows"):
				Progress.add_arrows(value())
				Sfx.play("pickup", -4.0)
			elif kind.begins_with("bombs"):
				Progress.add_bombs(value())
				Sfx.play("pickup", -4.0)
			elif kind.begins_with("nuts"):
				Progress.add_nuts(value())
				Sfx.play("pickup", -4.0)
			elif kind.begins_with("magic"):
				Progress.add_magic(value())
				Sfx.play("magic_refill", -4.0, 0.0)
