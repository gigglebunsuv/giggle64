class_name BlueWarp
extends Area3D
## The blue light that appears when a dungeon's master falls (OoT's Door_Warp1,
## blue warp type): stepping into it lifts the hero away in a shimmer of light
## and sets him down outside, at `target_entrance` of `target_area`. It only
## shows once `flag` is set.

@export var flag := ""
@export var target_area := "lake"
@export var target_entrance := ""

var _used := false
var _mesh: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	add_to_group("warps")
	_mesh = MeshInstance3D.new()
	_mesh.name = "Light"
	_mesh.mesh = load("res://assets/models/warp_mesh.tres")
	add_child(_mesh)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.75, 1.0)
	light.light_energy = 2.0
	light.omni_range = 9.0
	light.position = Vector3(0, 2, 0)
	add_child(light)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 3.0
	cs.shape = cyl
	cs.position = Vector3(0, 1.5, 0)
	add_child(cs)
	body_entered.connect(_on_body)
	_set_shown(flag == "" or Progress.flag(flag))
	if not visible:
		Progress.changed.connect(_check)


func _check() -> void:
	if not visible and Progress.flag(flag):
		Progress.changed.disconnect(_check)
		_set_shown(true)
		Sfx.play("warp", -4.0, 0.0)


func _set_shown(on: bool) -> void:
	visible = on
	set_deferred("monitoring", on)


func _process(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.rotation.y = _t * 0.8
		_mesh.scale = Vector3(1.0 + sin(_t * 3.0) * 0.04, 1.0, 1.0 + sin(_t * 3.0) * 0.04)


func _on_body(body: Node3D) -> void:
	if _used or not visible or not (body is PlayerController) or World.transitioning:
		return
	_used = true
	Sfx.play("warp", -2.0, 0.0)
	var p := body as PlayerController
	p.input_enabled = false
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(p.model, "position:y", 2.5, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	World.change_area(target_area, target_entrance)
