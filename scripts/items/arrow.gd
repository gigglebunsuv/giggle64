class_name Arrow
extends Node3D
## A fired arrow, after EnArrow (z_en_arrow.c):
## - Actor_SetProjectileSpeed(150): 150 units per frame along the aim, moved
##   x1.5 per 20 Hz frame like every actor (about 135 m/s).
## - It lives 12 frames. Once fewer than 7.2 are left it starts to drop
##   (gravity -0.4 per frame).
## - Each frame a line test from the last position (BgCheck_ProjectileLineTest)
##   finds walls and the floor. A wall hit sticks the arrow in place for 20
##   frames (func_809B45E0) and tells the surface (archery targets react).
## - Passing through a lit torch's flame sets it burning (OoT's arrow through
##   a torch); a burning arrow lights an unlit torch it passes through or hits.
## - Hitting an enemy deals the arrow's damage and, as in func_809B3CEC, the
##   arrow bounces off: it turns around +/- 0x3000, pops up by 0.4-0.8 of its
##   speed, keeps 4-34% of its speed and falls with gravity -1.5 for 50 frames.
## - `kind` "sun" (OoT's light arrow) and "frost" (the ice arrow) are the magic
##   arrows: a Sun Arrow strikes harder, bursts into light where it lands
##   (it wakes sun switches and shows shades and the wyrm for what they are);
##   a Frost Arrow freezes what it hits (Enemy.daze) and freezes open water
##   into a floe (IceFloe). Neither catches fire.
## - `kind` "starfall" (Chapter IV, the Temple of Bun): Lothelye's light. It
##   strikes hardest, puts out the Order's sapphire wards, lights star
##   braziers, wakes star eyes (anything with starfall_hit) and breaks
##   Firebuns' flame shield.

enum Phase { FLY, STUCK, BOUNCE }

const OOT_FPS := 20.0
const OOT_RATE := 1.5
const SPEED := 150.0
const LIFE := 12.0
const DROP_AT := 7.2
const STUCK_TIME := 20.0
const BOUNCE_TIME := 50.0
## World (1) and enemy hurtboxes (16).
const HIT_MASK := 1 | 16
const MESH_PATH := "res://assets/models/arrow_mesh.tres"

@export var damage := 2
@export var oot_unit := 0.03
## "" (a plain arrow), "sun" or "frost".
@export var kind := ""
## A Sun Arrow's blow (OoT's light arrows hit far harder than plain ones).
const SUN_DAMAGE := 4
const FROST_FREEZE := 4.0
const STARFALL_DAMAGE := 5
const STARFALL_REACH := 3.0

var phase := Phase.FLY
## Set alight by a torch's flame.
var burning := false
var _torches_passed: Array = []
## Meters per second.
var velocity := Vector3.ZERO
var shooter: CollisionObject3D = null
## What it hit last (a collider), for tests.
var hit_object: Object = null
var _timer := LIFE
var _gravity := 0.0
var _spin := 0.0


func _ready() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load(MESH_PATH)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	add_to_group("arrows")
	if kind != "":
		_magic_glow()


## The magic arrows glow at the tip and light their way.
func _magic_glow() -> void:
	var c: Color = {"sun": Color(1.0, 0.85, 0.35), "starfall": Color(0.85, 0.9, 1.25)}.get(kind, Color(0.55, 0.85, 1.0))
	var tip := MeshInstance3D.new()
	tip.name = "Glow"
	var s := SphereMesh.new()
	s.radius = 0.09
	s.height = 0.18
	s.radial_segments = 8
	s.rings = 4
	tip.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r * 1.5, c.g * 1.5, c.b * 1.5)
	m.disable_fog = true
	tip.material_override = m
	tip.position = Vector3(0, 0, -0.35)
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tip)
	var light := OmniLight3D.new()
	light.light_color = c
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position = tip.position
	add_child(light)


## Starts the flight from `from` along `dir`.
func launch(from: Vector3, dir: Vector3, by: CollisionObject3D) -> void:
	shooter = by
	global_position = from
	velocity = dir.normalized() * _mps(SPEED)
	_face_velocity()


func _mps(units: float) -> float:
	return units * OOT_RATE * OOT_FPS * oot_unit


func _physics_process(delta: float) -> void:
	var frames := delta * OOT_FPS
	_timer -= frames
	match phase:
		Phase.FLY:
			if _timer <= 0.0:
				queue_free()
				return
			if _timer < DROP_AT:
				_gravity = 0.4
			velocity.y -= _mps(_gravity) * OOT_FPS * delta
			_fly(delta)
		Phase.STUCK:
			if _timer <= 0.0:
				queue_free()
		Phase.BOUNCE:
			if _timer <= 0.0:
				queue_free()
				return
			velocity.y -= _mps(_gravity) * OOT_FPS * delta
			global_position += velocity * delta
			_spin += 14.0 * delta
			_face_velocity()
			rotate_object_local(Vector3.RIGHT, _spin)


func _fly(delta: float) -> void:
	var from := global_position
	var to := from + velocity * delta
	if kind == "frost" and _freeze_water(from, to):
		return
	if kind == "":
		_check_flames(from, to)
	var q := PhysicsRayQueryParameters3D.create(from, to, HIT_MASK)
	q.collide_with_areas = true
	if shooter:
		q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		global_position = to
		_face_velocity()
		return
	hit_object = hit.collider
	global_position = hit.position
	var hb := hit.collider as Hurtbox
	if hb:
		if hb.receiver == shooter:
			global_position = to
			return
		if burning and hb.receiver and hb.receiver.has_method("burn"):
			hb.receiver.burn()
		if kind in ["sun", "starfall"] and hb.receiver and hb.receiver.has_method("light_hit"):
			hb.receiver.light_hit(10.0, velocity.normalized())
		if kind == "starfall" and hb.receiver and hb.receiver.has_method("starfall_hit"):
			hb.receiver.starfall_hit(self)
		var info := HitInfo.new()
		info.damage = SUN_DAMAGE if kind == "sun" else (STARFALL_DAMAGE if kind == "starfall" else damage)
		info.knockback = 2.0
		info.attacker = shooter as Node3D
		info.source_position = from - velocity.normalized() * 2.0
		var result := hb.receive_hit(info)
		if result == Hurtbox.Result.IGNORED:
			# Collected an item (or met something it cannot hurt): fly on.
			global_position = to
			return
		Sfx.play("arrow_hit" if result == Hurtbox.Result.HIT else "shield_block", -4.0)
		if kind == "frost" and hb.receiver is Enemy:
			(hb.receiver as Enemy).daze(FROST_FREEZE, true)
		if kind != "":
			_magic_burst(hit.position)
			queue_free()
			return
		_bounce()
		return
	# A Starfall Arrow puts out a sapphire ward it meets.
	if kind == "starfall" and hit.collider is SapphireWard:
		(hit.collider as SapphireWard).gutter_out()
		_magic_burst(hit.position)
		queue_free()
		return
	if kind == "starfall" and hit.collider.has_method("starfall_hit"):
		hit.collider.starfall_hit(self)
	# Stuck in a wall or the ground.
	phase = Phase.STUCK
	_timer = STUCK_TIME
	Sfx.play("arrow_stick", -6.0)
	if hit.collider.has_method("arrow_hit"):
		hit.collider.arrow_hit(self, hit.position)
	if kind != "":
		_magic_burst(hit.position)


## Torch flames along this frame's flight (Torch's FlameZone, layer 128).
func _check_flames(from: Vector3, to: Vector3) -> void:
	var q := PhysicsRayQueryParameters3D.create(from, to, 128)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var torch := (hit.collider as Node).get_parent() as Torch
	if torch and not torch in _torches_passed:
		_torches_passed.append(torch)
		torch.arrow_pass(self)


## A magic arrow's end: a Sun Arrow bursts into light, waking anything that
## wakes to light close by (sun switches, shades); a Frost Arrow leaves a puff
## of ice.
func _magic_burst(at: Vector3) -> void:
	if not is_inside_tree():
		return
	if kind == "starfall":
		SpellEffect.make(get_parent(), "sun", at)
		Sfx.play("ward_out", -4.0, 0.05, 1.4)
		for t in get_tree().get_nodes_in_group("torches"):
			var torch := t as Torch
			if torch and not torch.lit and torch.star and torch.global_position.distance_to(at) < STARFALL_REACH:
				torch.light_up()
		for w in get_tree().get_nodes_in_group("sapphire_wards"):
			var ward := w as SapphireWard
			if ward and ward.global_position.distance_to(at) < STARFALL_REACH + ward.width * 0.5:
				ward.gutter_out()
		for n in get_tree().get_nodes_in_group("star_eyes"):
			var eye := n as Node3D
			if eye and eye.global_position.distance_to(at) < STARFALL_REACH and eye.has_method("starfall_hit"):
				eye.call("starfall_hit", self)
		for e in get_tree().get_nodes_in_group("enemies"):
			var en := e as Node3D
			if en and en.has_method("light_hit") and en.global_position.distance_to(at) < STARFALL_REACH:
				en.call("light_hit", 10.0, velocity.normalized())
		return
	if kind == "sun":
		SpellEffect.make(get_parent(), "sun", at)
		Sfx.play("sun_arrow", -2.0, 0.05)
		for n in get_tree().get_nodes_in_group("sun_switches"):
			var sw := n as Node3D
			if sw and sw.global_position.distance_to(at) < 2.5 and sw.has_method("light_hit"):
				sw.light_hit(10.0, velocity.normalized())
		for e in get_tree().get_nodes_in_group("enemies"):
			var en := e as Node3D
			if en and en.has_method("light_hit") and en.global_position.distance_to(at) < 3.0:
				en.call("light_hit", 10.0, velocity.normalized())
	else:
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), at, 8, 2.0, 2.5, 0.5, 0.6, Color(0.8, 0.95, 1.3))


## A Frost Arrow meeting open water this frame freezes a floe there.
func _freeze_water(from: Vector3, to: Vector3) -> bool:
	var area := World.area_node if is_instance_valid(World.area_node) else null
	if area == null:
		return false
	var wy := Surface.water_level(area, to)
	if is_nan(wy) or not (from.y >= wy and to.y < wy):
		return false
	var k := (from.y - wy) / maxf(from.y - to.y, 0.0001)
	var at := from.lerp(to, k)
	# Not where it would only skim a shallow edge: the bed must be below.
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at + Vector3.DOWN * 0.6, 1)
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return false
	IceFloe.freeze_at(area, Vector3(at.x, wy, at.z))
	queue_free()
	return true


## Catches fire from a torch: a little flame at the tip.
func ignite() -> void:
	if burning or kind != "":
		return
	burning = true
	var f := MeshInstance3D.new()
	f.name = "Fire"
	f.mesh = load("res://assets/models/flame_mesh.tres")
	f.scale = Vector3.ONE * 0.45
	f.position = Vector3(0, 0, -0.35)
	add_child(f)
	Sfx.play("torch_light", -8.0, 0.05, 1.4)


func _bounce() -> void:
	phase = Phase.BOUNCE
	_timer = BOUNCE_TIME
	var speed := Vector2(velocity.x, velocity.z).length()
	var yaw := atan2(velocity.x, velocity.z) + PI + randf_range(-0.5, 0.5) * 0x6000 * TAU / 65536.0
	velocity.y += speed * randf_range(0.4, 0.8)
	speed *= randf_range(0.04, 0.34)
	velocity.x = sin(yaw) * speed
	velocity.z = cos(yaw) * speed
	_gravity = 1.5


func _face_velocity() -> void:
	if velocity.length() < 0.01:
		return
	var fwd := velocity.normalized()
	var up := Vector3.UP if absf(fwd.y) < 0.99 else Vector3.BACK
	global_basis = Basis.looking_at(fwd, up)
