class_name IceFloe
extends StaticBody3D
## A disc of ice a Frost Arrow freezes out of open water (OoT's ice arrows
## freeze water in places; here any water does). It floats at the surface,
## solid to stand on, for LIFE seconds; it blinks for the last few and melts.
## Only MAX_FLOES stand at once; a new one melts the oldest.

const RADIUS := 1.4
const THICK := 0.35
const LIFE := 25.0
const BLINK := 4.0
const MAX_FLOES := 3

var _t := 0.0
var _mesh: MeshInstance3D


static func freeze_at(parent: Node, at: Vector3) -> IceFloe:
	var floes := parent.get_tree().get_nodes_in_group("ice_floes")
	if floes.size() >= MAX_FLOES:
		(floes[0] as IceFloe).melt()
	var f := IceFloe.new()
	parent.add_child(f)
	f.global_position = at
	return f


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("ice_floes")
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = THICK
	cs.shape = shape
	cs.position = Vector3(0, 0.12 - THICK * 0.5, 0)
	cs.set_meta("surface", "stone")
	cs.set_meta("no_climb", true)
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	var path := "res://assets/models/ice_floe_mesh.tres"
	if ResourceLoader.exists(path):
		_mesh.mesh = load(path)
	else:
		var c := CylinderMesh.new()
		c.top_radius = RADIUS
		c.bottom_radius = RADIUS * 0.85
		c.height = THICK
		c.radial_segments = 12
		_mesh.mesh = c
		_mesh.position.y = 0.12 - THICK * 0.5
	add_child(_mesh)
	scale = Vector3(0.2, 1, 0.2)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("ice_freeze", -2.0, 0.05)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t > LIFE - BLINK:
		_mesh.visible = fmod(_t * 8.0, 1.0) < 0.6
	if _t >= LIFE:
		melt()


func melt() -> void:
	if is_queued_for_deletion():
		return
	remove_from_group("ice_floes")
	Sfx.play("splash_big", -14.0, 0.05, 1.5)
	queue_free()
