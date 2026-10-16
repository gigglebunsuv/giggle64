class_name BloomPod
extends StaticBody3D
## What a Bloom Rod seed grows into (BloomSeed): a bloom-pod on firm ground,
## a lily pad on water or sludge. Either can be stood on. The pod is a
## sturdy bulb 1.5 m tall: the hero climbs onto it by himself, the Hookshot
## bites into it (its shape is "hookable"), and it weighs down a floor switch
## it grows on. A bomb blows it apart, and growing another withers it: only
## one bloom at a time, like the Cane of Somaria's block.

const POD_SIZE := Vector3(1.3, 1.5, 1.3)
const PAD_SIZE := Vector3(2.6, 0.2, 2.6)
## Lily pads sit this far over the sludge's floor (clear of its sinking).
const SLUDGE_LIFT := 0.5
const GROW_TIME := 0.35

static var current: BloomPod = null

var pad := false
var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _dying := false
var _t := 0.0


## Grows a bloom at `at` (a pad if `on_water`), withering the last one.
static func grow(parent: Node, at: Vector3, on_water: bool, yaw := 0.0) -> BloomPod:
	if is_instance_valid(current):
		current.wither()
	var b := BloomPod.new()
	b.pad = on_water
	b.name = "LilyPad" if on_water else "BloomPod"
	parent.add_child(b)
	var y := at.y
	if on_water and BloomSeed._in_sludge(at):
		y += SLUDGE_LIFT
	b.global_position = Vector3(at.x, y, at.z)
	b.rotation.y = yaw
	current = b
	return b


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("blooms")
	add_to_group("bombables")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/%s.tres" % ("lily_pad_mesh" if pad else "bloom_pod_mesh"))
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.scale = Vector3.ONE * 0.05
	add_child(_mesh)
	_shape = CollisionShape3D.new()
	_shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = PAD_SIZE if pad else POD_SIZE
	_shape.shape = box
	_shape.position = Vector3(0, -PAD_SIZE.y * 0.5 + 0.06, 0) if pad else Vector3(0, POD_SIZE.y * 0.5, 0)
	_shape.set_meta("surface", "grass")
	if not pad:
		_shape.set_meta("hookable", true)
	_shape.disabled = true
	add_child(_shape)
	Sfx.play("bloom_grow", -4.0, 0.06, 0.9 if pad else 1.0)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 0.4, 10, 2.4, 3.0, 0.8, 1.0, Color(0.7, 1.0, 0.6))
	var t := create_tween()
	t.tween_property(_mesh, "scale", Vector3.ONE * 1.12, GROW_TIME * 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_mesh, "scale", Vector3.ONE, GROW_TIME * 0.25)
	t.tween_callback(_grown)


func _grown() -> void:
	if _dying:
		return
	_shape.disabled = false
	# Anything standing where it grew is lifted onto it.
	var p := GameManager.player
	if is_instance_valid(p) and not pad:
		var d := p.global_position - global_position
		if absf(d.x) < POD_SIZE.x * 0.5 + 0.2 and absf(d.z) < POD_SIZE.z * 0.5 + 0.2 and d.y > -0.3 and d.y < POD_SIZE.y:
			p.global_position.y = global_position.y + POD_SIZE.y + 0.05
	if not pad:
		for sw in get_tree().get_nodes_in_group("switches"):
			if sw.has_method("weigh_down"):
				sw.weigh_down(global_position + Vector3.UP * 0.1)


func _process(delta: float) -> void:
	_t += delta
	if pad and is_instance_valid(_mesh) and not _dying:
		# Bobbing gently on the water.
		_mesh.position.y = sin(_t * 1.6) * 0.02


func top_y() -> float:
	return global_position.y + (0.06 if pad else POD_SIZE.y)


func bomb_reach() -> float:
	return 1.0


func bomb_hit(_from: Vector3) -> void:
	wither()


## Shrivels away (another bloom grew, or a blast tore it).
func wither() -> void:
	if _dying:
		return
	_dying = true
	if current == self:
		current = null
	_shape.set_deferred("disabled", true)
	Sfx.play("lift_plant", -8.0, 0.05, 0.7)
	var t := create_tween()
	t.tween_property(_mesh, "scale", Vector3(1.2, 0.05, 1.2), 0.3)
	t.tween_callback(queue_free)
