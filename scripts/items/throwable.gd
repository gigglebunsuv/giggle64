class_name Throwable
extends Node3D
## Something the hero has lifted (a pot, a rock or a shrub), carried over his
## head and thrown. Pot, LiftRock and Shrub hand one of these over when lifted
## (Player_ActionHandler_2: A with an actor offering itself in range).
##
## The flight follows the actors' own thrown states (ObjTsubo_Thrown,
## EnIshi_Fly, EnKusa_Fall). Velocities are in OoT units per 20 Hz frame and
## move the object x1.5 per frame (Actor_UpdatePos):
## - Thrown with the hero's speed + 8 forward and 12 up (func_8084409C, called
##   from Player_Action_80846578 on frame 3 of the throw).
## - Pots and small rocks fall with gravity -1.2 (no drag); shrubs with -3.2
##   but lose 5% of their velocity a frame (EnKusa_RandScaleVecToZero), so
##   they flutter down sooner.
## - Velocity never goes below minVelocityY (-20 pots and rocks, -17 shrubs).
## - Touching the ground or a wall, or hitting a creature, breaks it
##   (ObjTsubo_AirBreak, sFragmentSpawnFuncs, EnKusa_SpawnFragments) and it drops
##   its item. A creature it hits takes 1 damage (the pot's AT collider).
## - A pot or rock breaks brittle coral (BrittleCrust) and presses a floor
##   switch it lands on.
## - It tumbles as it flies (the rot.x / rot.y spin speeds set when thrown).

enum Kind { POT, ROCK, GRASS }
enum Phase { HELD, FLYING, DONE }

const OOT_FPS := 20.0
const OOT_RATE := 1.5
const UNIT := 0.03
const BINANG := TAU / 65536.0
## World (1) and every hurtbox (16).
const WORLD_MASK := 1
const HURT_MASK := 16
const RADIUS := 0.22
## Gravity, minVelocityY and per-frame drag for each kind (sInitChain values).
const PHYSICS := {
	Kind.POT: [-1.2, -20.0, 0.0],
	Kind.ROCK: [-1.2, -20.0, 0.0],
	Kind.GRASS: [-3.2, -17.0, 0.05],
}

var kind := Kind.POT
## Pots: a fixed item, or "" for a random pick from `drop_table`.
var item := ""
var drop_table := 0
## Color multiplied over the break fragments (glazed pots, tinted grass).
var tint := Color(1, 1, 1)
var phase := Phase.HELD
var thrower: PlayerController = null
## Velocity in OoT units per frame (x, y, z in Godot axes).
var velocity_oot := Vector3.ZERO
## What it struck when it broke (a collider or receiver), for tests.
var hit_object: Object = null
var _mesh: MeshInstance3D
var _spin := Vector2.ZERO
var _spin_target := Vector2.ZERO
var _life := 0.0


## Builds one from `mesh` (already tinted by the caller if needed).
static func create(k: Kind, mesh: Mesh, material: Material = null) -> Throwable:
	var t := Throwable.new()
	t.kind = k
	t.name = "Thrown" + ["Pot", "Rock", "Grass"][k]
	t._mesh = MeshInstance3D.new()
	t._mesh.name = "Mesh"
	t._mesh.mesh = mesh
	t._mesh.material_override = material
	t._mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	t.add_child(t._mesh)
	return t


func _ready() -> void:
	add_to_group("throwables")


## How far its origin sits above the hero's palms while he carries it (the
## pot and rock rest on their bases; a shrub is held by its root ball).
func rest_offset() -> float:
	return -0.08 if kind == Kind.GRASS else -0.02


## Lets go of it with `yaw` (Godot convention), horizontal `speed` and vertical
## `vy`, both in OoT units per frame.
func release(yaw: float, speed: float, vy: float) -> void:
	phase = Phase.FLYING
	velocity_oot = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed + Vector3.UP * vy
	# The tumble each actor sets up when it leaves the hands.
	match kind:
		Kind.POT:
			_spin_target = Vector2((randf() - 0.7) * 2800.0, (randf() - 0.5) * 2000.0)
		Kind.ROCK:
			_spin = Vector2((randf() - 0.5) * 16000.0, (randf() - 0.5) * 2400.0)
			_spin_target = _spin
		Kind.GRASS:
			_spin_target = Vector2(-0xBB8, (randf() - 0.5) * 1600.0)


func _physics_process(delta: float) -> void:
	if phase != Phase.FLYING:
		return
	_life += delta
	var f := delta * OOT_FPS
	var p: Array = PHYSICS[kind]
	velocity_oot.y = maxf(velocity_oot.y + p[0] * f, p[1])
	if p[2] > 0.0:
		velocity_oot *= pow(1.0 - p[2], f)
	var step_rate := 0x1F4 if kind == Kind.GRASS else 0x64
	_spin.x = move_toward(_spin.x, _spin_target.x, step_rate * f)
	_spin.y = move_toward(_spin.y, _spin_target.y, (0xAA if kind == Kind.GRASS else 0x64) * f)
	rotation.x += _spin.x * BINANG * f
	rotation.y += _spin.y * BINANG * f
	var from := global_position + Vector3.UP * RADIUS
	var motion := velocity_oot * OOT_RATE * UNIT * f
	if _hit_creature(from, motion):
		return
	var hit := _cast_world(from, motion)
	if hit < 1.0:
		global_position += motion * hit
		smash()
		return
	global_position += motion
	if _in_water() or _life > 6.0 or global_position.y < -50.0:
		smash()


## A creature, pot or shrub in the way takes the blow and the object breaks.
func _hit_creature(from: Vector3, motion: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	q.shape = s
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = HURT_MASK
	for k in [0.5, 1.0]:
		q.transform = Transform3D(Basis(), from + motion * k)
		for r in get_world_3d().direct_space_state.intersect_shape(q, 8):
			var hb := r.collider as Hurtbox
			if hb == null or not hb.monitorable or (is_instance_valid(thrower) and hb.receiver == thrower):
				continue
			var info := HitInfo.new()
			info.damage = 1
			info.knockback = 3.0
			info.attacker = thrower
			info.heavy = kind != Kind.GRASS
			info.source_position = global_position - Vector3(motion.x, 0, motion.z).normalized()
			if hb.receive_hit(info) == Hurtbox.Result.IGNORED and not (hb.receiver is Shrub):
				continue
			hit_object = hb.receiver
			global_position = from - Vector3.UP * RADIUS + motion * k
			smash()
			return true
	return false


## Fraction of `motion` a sphere at `from` can travel before touching the world.
func _cast_world(from: Vector3, motion: Vector3) -> float:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	q.shape = s
	q.transform = Transform3D(Basis(), from)
	q.motion = motion
	q.collision_mask = WORLD_MASK
	var r := get_world_3d().direct_space_state.cast_motion(q)
	if r.size() > 0 and r[1] < 1.0:
		hit_object = null
		return r[0]
	return 1.0


func _in_water() -> bool:
	var area := World.area_node if is_instance_valid(World.area_node) else null
	if area == null:
		return false
	for w: Array in area.get_meta("water", []):
		var rect: Rect2 = w[0]
		if rect.has_point(Vector2(global_position.x, global_position.z)) and global_position.y < float(w[1]):
			Sfx.play("splash_big", -6.0)
			return true
	return false


## Breaks it where it is: fragments, the sound, and its drop.
func smash() -> void:
	if phase == Phase.DONE:
		return
	phase = Phase.DONE
	var parent := get_parent()
	# Landing on a floor switch presses it (pots and rocks are heavy enough).
	if kind != Kind.GRASS:
		for sw in get_tree().get_nodes_in_group("switches"):
			if sw.has_method("weigh_down"):
				sw.weigh_down(global_position)
	var at := global_position + Vector3.UP * 0.2
	match kind:
		Kind.POT:
			Sfx.play("pot_break", -3.0)
			Fragments.burst(parent, load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.3, 12, 2.5, 4.0, 1.0, 1.0, tint)
			if item != "":
				Drops.spawn(item, at, parent, true)
			else:
				Drops.random(drop_table, at, parent)
		Kind.ROCK:
			Sfx.play("rock_break", -3.0)
			Fragments.burst(parent, load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3.UP * 0.2, 10, 2.8, 4.5, 0.9, 1.0, tint)
			Drops.random(drop_table, at, parent)
		Kind.GRASS:
			Sfx.play("grass_cut", -4.0)
			Fragments.burst(parent, load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 0.35, 9, 2.2, 3.0, 1.1, 1.3, tint, 9.0)
			Drops.random(drop_table, at, parent)
	queue_free()


## Puts it down gently (the hero was hurt or interrupted): it drops from where
## it is and breaks on the ground.
func drop() -> void:
	release(rotation.y, 0.0, 0.0)
