class_name Shrub
extends Node3D
## A cuttable shrub, after OoT's En_Kusa (z_en_kusa.c):
## - The sword (or an arrow, or the boomerang) cuts it: leaves fly
##   (EnKusa_SpawnFragments), NA_SE_EV_PLANT_BROKEN plays and it drops from
##   COLLECTIBLE_DROP_TABLE_0 (EnKusa_DropCollectible).
## - ENKUSA_TYPE_1 shrubs regrow: after 120 frames (6 s) the stub grows back,
##   x by 0.011 and y by 0.014 of its full 0.4 scale a frame (EnKusa_Regrow).
##   Others (ENKUSA_TYPE_0) are gone until the area is reloaded.
## - The hero can lift it (Actor_OfferCarry: within 50 units, 1.5 m, facing it),
##   pulling it up by the roots (NA_SE_PL_PULL_UP_PLANT), and throw it (see
##   Throwable). An uprooted regrowing shrub leaves no stub and grows back in
##   the same 120 frames (EnKusa_UprootedWaitRegrow).

const OOT_FPS := 20.0
const REGROW_WAIT := 120.0

@export var regrow := true
@export var drop_table := 0
## Multiplied over the leaves (dry or frosted variants).
@export var tint := Color(1, 1, 1)

var cut := false
var _wait := 0.0
var _growing := false
var _grow := Vector2.ONE
var _mesh: MeshInstance3D
var _stub: MeshInstance3D
var _hurt: Hurtbox


func _ready() -> void:
	add_to_group("shrubs")
	add_to_group("liftables")
	_mesh = _make("Mesh", "res://assets/models/shrub_mesh.tres")
	_stub = _make("Stub", "res://assets/models/shrub_stub_mesh.tres")
	_stub.visible = false
	_hurt = Hurtbox.new()
	_hurt.name = "Hurtbox"
	_hurt.collision_layer = 16
	_hurt.collision_mask = 0
	_hurt.receiver = self
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 0.8
	cs.shape = cyl
	cs.position = Vector3(0, 0.4, 0)
	_hurt.add_child(cs)
	add_child(_hurt)


func _make(node_name: String, path: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = load(path)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tint != Color(1, 1, 1) and mi.mesh:
		var m := mi.mesh.surface_get_material(0) as StandardMaterial3D
		if m:
			var t: StandardMaterial3D = m.duplicate()
			t.albedo_color = tint
			mi.material_override = t
	add_child(mi)
	return mi


## Actor_OfferCarry's xz and y ranges (Actor_OfferGetItemNearby), in meters.
func lift_range() -> Vector2:
	return Vector2(50.0, 10.0) * 0.03


func can_lift() -> bool:
	return not cut


## Pulls the shrub up to be carried. A regrowing one starts its wait; the rest
## are gone for good.
func lift(by: PlayerController) -> Throwable:
	Sfx.play("lift_plant", -4.0)
	var t := Throwable.create(Throwable.Kind.GRASS, _mesh.mesh, _mesh.material_override)
	t.drop_table = drop_table
	t.tint = tint
	t.thrower = by
	get_parent().add_child(t)
	t.global_transform = _mesh.global_transform
	cut = true
	_mesh.visible = false
	_stub.visible = false
	_hurt.set_deferred("monitorable", false)
	_wait = 0.0
	_growing = false
	if not regrow:
		queue_free()
	return t


func take_hit(info: HitInfo) -> int:
	if cut or not (info.attacker is PlayerController):
		return Hurtbox.Result.IGNORED
	cut_down()
	return Hurtbox.Result.IGNORED


func boomerang_hit(_b: Node3D) -> void:
	if not cut:
		cut_down()


func cut_down() -> void:
	cut = true
	_mesh.visible = false
	_stub.visible = true
	_hurt.set_deferred("monitorable", false)
	Sfx.play("grass_cut", -4.0)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 0.35, 9, 2.2, 3.0, 1.1, 1.3, tint, 9.0)
	Drops.random(drop_table, global_position + Vector3.UP * 0.2, get_parent())
	_wait = 0.0
	_growing = false


func _physics_process(delta: float) -> void:
	if not cut or not regrow:
		return
	var f := delta * OOT_FPS
	if not _growing:
		_wait += f
		if _wait >= REGROW_WAIT:
			_growing = true
			_grow = Vector2(0.1, 0.1)
			_mesh.visible = true
			_mesh.scale = Vector3(_grow.x, _grow.y, _grow.x)
		return
	_grow.x = move_toward(_grow.x, 1.0, 0.011 / 0.4 * f)
	_grow.y = move_toward(_grow.y, 1.0, 0.014 / 0.4 * f)
	_mesh.scale = Vector3(_grow.x, _grow.y, _grow.x)
	if _grow.x >= 1.0 and _grow.y >= 1.0:
		cut = false
		_growing = false
		_stub.visible = false
		_hurt.set_deferred("monitorable", true)
