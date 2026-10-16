class_name Torch
extends StaticBody3D
## A torch stand or brazier (OoT's Obj_Syokudai). A lit one sets fire to an
## arrow shot through its flame; a burning arrow lights an unlit one, which
## then stays lit and sets its `flag` (doors and chests wait on all of them).
## `lit_at_start` torches burn from the beginning and set nothing.

@export var lit_at_start := false
@export var flag := ""
## A star brazier (the Sapphire Sanctum): it takes only Lothelye's starlight
## (the Starlight Lantern), and burns cold and blue; a common flame or a
## burning arrow will not light it.
@export var star := false
## Height of the bowl's top (the flame sits on it).
@export var bowl_height := 1.3

var lit := false
var _flame: Node3D
var _zone: Area3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("torches")
	_flame = Node3D.new()
	_flame.name = "Flame"
	_flame.position = Vector3(0, bowl_height, 0)
	_flame.set_script(load("res://scripts/systems/torch_flicker.gd"))
	var mi := MeshInstance3D.new()
	mi.name = "FlameMesh"
	mi.mesh = load("res://assets/models/%s.tres" % ("star_flame_mesh" if star else "flame_mesh"))
	_flame.add_child(mi)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 0.5, 0)
	light.light_color = Color(0.55, 0.75, 1.0) if star else Color(1.0, 0.6, 0.29)
	light.light_energy = 1.2
	light.omni_range = 6.0
	_flame.add_child(light)
	add_child(_flame)
	# The space over the bowl that arrows pass through (layer 128).
	_zone = Area3D.new()
	_zone.name = "FlameZone"
	_zone.collision_layer = 128
	_zone.collision_mask = 0
	_zone.monitoring = false
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.55
	cs.shape = s
	cs.position = Vector3(0, bowl_height + 0.35, 0)
	_zone.add_child(cs)
	add_child(_zone)
	lit = lit_at_start or (flag != "" and Progress.flag(flag))
	_flame.visible = lit


## A burning arrow struck the stand itself.
func arrow_hit(arrow: Node3D, _point: Vector3) -> void:
	if not lit and arrow.get("burning") and not star:
		light_up()


## An arrow flew through the flame zone.
func arrow_pass(arrow: Node3D) -> void:
	if lit:
		if arrow.has_method("ignite") and not star:
			arrow.ignite()
	elif arrow.get("burning") and not star:
		light_up()


func light_up() -> void:
	if lit:
		return
	lit = true
	_flame.visible = true
	Sfx.play("torch_light", -2.0, 0.05)
	if flag != "":
		Progress.set_flag(flag)
