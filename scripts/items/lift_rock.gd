class_name LiftRock
extends StaticBody3D
## A small rock the hero can lift and throw, after OoT's En_Ishi (ROCK_SMALL):
## - It offers itself to be lifted (Actor_OfferGetItem(GI_NONE, 50, 10)) when the
##   hero stands within 50 units (1.5 m) and 10 units (0.3 m) of its height,
##   facing it.
## - Lifted, it plays NA_SE_PL_PULL_UP_ROCK; thrown, it breaks into chips where
##   it lands (EnIshi_Fly) and drops from its drop table
##   (EnIshi_DropCollectible). The sword only clangs off it.
## A `heavy` rock (OoT's ROCK_LARGE, lifted with the Goron's Bracelet) is a
## big dark boulder that only the Bun Bracers can lift; until then it is just
## in the way, like the one sealing the Sun Trial.

@export var drop_table := 0
## Multiplied over the stone (sandstone in the desert, frosted on the peak).
@export var tint := Color(1, 1, 1)
@export var heavy := false
## Set once a heavy rock has been lifted away (it stays gone).
@export var gone_flag := ""

var lifted := false
var _mesh: MeshInstance3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if gone_flag != "" and Progress.flag(gone_flag):
		queue_free()
		return
	add_to_group("liftables")
	if heavy:
		add_to_group("heavy_rocks")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/%s.tres" % ("heavy_rock_mesh" if heavy else "lift_rock_mesh"))
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tint != Color(1, 1, 1) and _mesh.mesh:
		var m := _mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if m:
			var t: StandardMaterial3D = m.duplicate()
			t.albedo_color = tint
			_mesh.material_override = t
	add_child(_mesh)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.62 if heavy else 0.3
	cyl.height = 1.1 if heavy else 0.5
	cs.shape = cyl
	cs.position = Vector3(0, cyl.height * 0.5, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	add_child(cs)


## Actor_OfferGetItem's xz and y ranges, in meters.
func lift_range() -> Vector2:
	return Vector2(80.0 if heavy else 50.0, 10.0) * 0.03


func can_lift() -> bool:
	return not lifted and (not heavy or Progress.can_lift_heavy())


## Hands the rock over to be carried and leaves the ground empty.
func lift(by: PlayerController) -> Throwable:
	lifted = true
	Sfx.play("lift_rock", -4.0, 0.0, 0.7 if heavy else 1.0)
	if gone_flag != "":
		Progress.set_flag(gone_flag)
	var t := Throwable.create(Throwable.Kind.ROCK, _mesh.mesh, _mesh.material_override)
	t.drop_table = drop_table
	t.tint = tint
	t.thrower = by
	get_parent().add_child(t)
	t.global_transform = global_transform
	queue_free()
	return t
