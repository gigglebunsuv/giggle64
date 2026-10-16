class_name ArrowPickup
extends Area3D
## A bundle of arrows lying in the world (OoT's ITEM00_ARROWS_SMALL / _MEDIUM /
## _LARGE drops give 5, 10 or 30). It spins slowly like OoT's item drops and
## refills the quiver when the hero touches it.

@export var amount := 10

var _visual: Node3D
var _time := 0.0
## Dropped by an enemy: it disappears after a while, as OoT's drops do.
var lifetime := -1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("pickups")
	if get_node_or_null("Shape") == null:
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		var s := SphereShape3D.new()
		s.radius = 0.6
		cs.shape = s
		cs.position = Vector3(0, 0.4, 0)
		add_child(cs)
	_visual = get_node_or_null("Visual")
	if _visual == null:
		_visual = Node3D.new()
		_visual.name = "Visual"
		add_child(_visual)
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/arrow_bundle_mesh.tres")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_visual.add_child(mi)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.rotation.y = _time * 2.0
	_visual.position.y = 0.25 + sin(_time * 3.0) * 0.06
	if lifetime > 0.0:
		lifetime -= delta
		_visual.visible = lifetime > 3.0 or fmod(lifetime, 0.2) < 0.12
		if lifetime <= 0.0:
			queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController and not body.is_dead():
		Progress.add_arrows(amount)
		Sfx.play("pickup", -4.0)
		queue_free()
