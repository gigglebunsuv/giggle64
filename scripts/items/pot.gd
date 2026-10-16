class_name Pot
extends StaticBody3D
## A clay pot, after OoT's Obj_Tsubo (z_obj_tsubo.c): solid to walk into, it
## shatters into shards (ObjTsubo_SpawnBreakEffect) when struck by the sword,
## an arrow or the boomerang, and drops its item: a set one, or a random
## pick from its drop table (ObjTsubo_SpawnCollectible).
## It can also be lifted (ObjTsubo_Idle offers it with Actor_OfferGetItem(GI_NONE,
## 30, 30): within 30 units, 0.9 m, of the hero, who faces it) and thrown, and
## then breaks where it lands (see Throwable).

## A fixed item (see Collectible.kind), or "" for a random drop.
@export var item := ""
@export var drop_table := 2
## The shrine's blue-glazed pots.
@export var glazed := false

var broken := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("pots")
	add_to_group("liftables")
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = load("res://assets/models/%s.tres" % ("pot_blue_mesh" if glazed else "pot_mesh"))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 0.6
	cs.shape = cyl
	cs.position = Vector3(0, 0.3, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hcyl := CylinderShape3D.new()
	hcyl.radius = 0.38
	hcyl.height = 0.7
	hcs.shape = hcyl
	hcs.position = Vector3(0, 0.35, 0)
	hb.add_child(hcs)
	add_child(hb)


## Actor_OfferGetItem's xz and y ranges, in meters.
func lift_range() -> Vector2:
	return Vector2(30.0, 30.0) * 0.03


func can_lift() -> bool:
	return not broken


## NA_SE_PL_PULL_UP_POT: hands the pot over to be carried (ObjTsubo_SetupLiftedUp).
func lift(by: PlayerController) -> Throwable:
	broken = true
	Sfx.play("lift_pot", -4.0)
	var mi := get_node("Mesh") as MeshInstance3D
	var t := Throwable.create(Throwable.Kind.POT, mi.mesh)
	t.item = item
	t.drop_table = drop_table
	t.tint = Color(0.55, 0.75, 1.2) if glazed else Color(1, 1, 1)
	t.thrower = by
	get_parent().add_child(t)
	t.global_transform = global_transform
	queue_free()
	return t


func take_hit(info: HitInfo) -> int:
	if broken or not (info.attacker is PlayerController):
		return Hurtbox.Result.IGNORED
	shatter()
	return Hurtbox.Result.HIT


func arrow_hit(_arrow: Node3D, _point: Vector3) -> void:
	shatter()


func boomerang_hit(_b: Node3D) -> void:
	shatter()


func shatter() -> void:
	if broken:
		return
	broken = true
	Sfx.play("pot_break", -3.0)
	var tint := Color(0.55, 0.75, 1.2) if glazed else Color(1, 1, 1)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.3, 12, 2.5, 4.0, 1.0, 1.0, tint)
	var at := global_position + Vector3.UP * 0.2
	if item != "":
		Drops.spawn(item, at, get_parent(), true)
	else:
		Drops.random(drop_table, at, get_parent())
	queue_free()
