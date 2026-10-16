class_name SapphireBlock
extends StaticBody3D
## The block the Sapphire Staff conjures (Chapter IV): a great cube of the
## Order's sapphire, set down two steps ahead of the hero. It is solid (he
## can climb onto it), heavy enough to hold down a floor switch, and fire
## breaks on it. Only one stands at a time; using the staff again (or
## walking off too far) dispels it. Firebuns' flame and the Siege Ogre's
## charge smash it (`shatter`).

const SIZE := 1.6
## Further than this from the hero and it fades away.
const LEASH := 40.0

static var current: SapphireBlock = null

var _mesh: MeshInstance3D
var _t := 0.0


static func conjure(parent: Node, at: Vector3, yaw: float) -> SapphireBlock:
	if is_instance_valid(current):
		current.dispel()
	var b := SapphireBlock.new()
	b.name = "SapphireBlock"
	parent.add_child(b)
	b.global_position = at
	b.rotation.y = yaw
	current = b
	return b


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("sapphire_blocks")
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * SIZE
	cs.shape = box
	cs.position = Vector3(0, SIZE * 0.5, 0)
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	if ResourceLoader.exists("res://assets/models/sapphire_block_mesh.tres"):
		_mesh.mesh = load("res://assets/models/sapphire_block_mesh.tres")
	_mesh.scale = Vector3(1, 0.01, 1)
	add_child(_mesh)
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 0.55, 1.0)
	light.light_energy = 0.8
	light.omni_range = 4.0
	light.position = Vector3(0, SIZE * 0.6, 0)
	add_child(light)
	var t := create_tween()
	t.tween_property(_mesh, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("crystal_hit", -2.0, 0.05, 0.8)
	_press_switches.call_deferred()


## Its weight on whatever floor switch it stands on.
func _press_switches() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("switches"):
		if n.has_method("weigh_down"):
			n.call("weigh_down", global_position + Vector3.UP * 0.1)


func _physics_process(delta: float) -> void:
	_t += delta
	var p := GameManager.player
	if is_instance_valid(p) and p.global_position.distance_to(global_position) > LEASH:
		dispel()


## Gone in a puff of blue.
func dispel() -> void:
	if current == self:
		current = null
	if not is_inside_tree():
		return
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * SIZE * 0.5, 10, 2.5, 2.0, 0.6, 0.6, Color(0.5, 0.65, 1.4))
	Sfx.play("ward_out", -6.0, 0.05, 1.3)
	queue_free()


## Smashed (a charging ogre, a fireball).
func shatter() -> void:
	Sfx.play("crystal_hit", 0.0, 0.05, 0.6)
	dispel()
