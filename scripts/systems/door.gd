class_name Door
extends Node3D
## A door the hero opens with A ("OPEN" on the A button, OoT's DO_ACTION_OPEN).
## The leaf swings inward and the hero walks through while the screen fades,
## then World loads `target_area` at `target_entrance` (OoT doors into houses
## lead to a separate interior scene the same way).
##
## The node stands at the middle of the doorway on the floor, its -Z axis
## pointing out of the door toward whoever opens it.

@export var target_area := ""
@export var target_entrance := ""
## Leaf hinge swing in radians.
@export var swing := -1.6
## A Progress flag the door waits for (barred until it is set; "" = none).
@export var need_flag := ""
## A Progress flag that shuts the door for good (a shop closed after the
## takeover), and the notice A reads on it then.
@export var bar_flag := ""
@export_multiline var barred_text := ""

var _leaf: Node3D
var _open := false
var _solid: StaticBody3D


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("doors")
	_leaf = get_node_or_null("Leaf")
	# Shut, the door is solid (OoT's doors are), so neither the hero nor the
	# camera passes into the dark beyond it.
	var w := absf(_leaf.position.x) * 2.0 if _leaf else 1.6
	var hh := 2.6
	var lm := get_node_or_null("Leaf/LeafMesh") as MeshInstance3D
	if lm and lm.mesh:
		hh = lm.mesh.get_aabb().size.y
	_solid = StaticBody3D.new()
	_solid.name = "Solid"
	_solid.collision_layer = 1
	_solid.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w + 0.1, hh, 0.3)
	cs.shape = box
	cs.position = Vector3(0, hh * 0.5, 0.05)
	cs.set_meta("no_climb", true)
	_solid.add_child(cs)
	add_child(_solid)


## The size of the doorway (width, height).
func doorway() -> Vector2:
	var w := absf(_leaf.position.x) * 2.0 if _leaf else 1.6
	var lm := get_node_or_null("Leaf/LeafMesh") as MeshInstance3D
	return Vector2(w, lm.mesh.get_aabb().size.y if lm and lm.mesh else 2.6)


func can_interact(_by: Node3D) -> bool:
	return need_flag == "" or Progress.flag(need_flag) or _waits_with_notice()


## Waiting on `need_flag`, with a notice to read meanwhile (Westmarch's gate
## before the war).
func _waits_with_notice() -> bool:
	return need_flag != "" and not Progress.flag(need_flag) and bar_flag == "" and barred_text != ""


func barred() -> bool:
	return (bar_flag != "" and Progress.flag(bar_flag)) or DayNight.door_notice(target_area) != "" or _waits_with_notice()


func interact_label() -> String:
	return "CHECK" if barred() else "OPEN"


func interact(player: Node) -> void:
	if _open or World.transitioning or Dialogue.active:
		return
	if barred():
		var pc := player as PlayerController
		if pc:
			pc.begin_talk(self)
		Sfx.play("door_unlock", -8.0, 0.05, 0.6)
		var notice := barred_text if (bar_flag != "" and Progress.flag(bar_flag)) or _waits_with_notice() else DayNight.door_notice(target_area)
		Dialogue.start([notice if notice != "" else "It's locked tight."], self, "wooden")
		await Dialogue.finished
		if is_instance_valid(pc):
			pc.end_talk()
		return
	_open = true
	if _solid:
		_solid.queue_free()
		_solid = null
	Sfx.play("door_open", -2.0)
	if _leaf:
		var t := create_tween()
		t.tween_property(_leaf, "rotation:y", swing, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Face straight through the doorway before walking in; the camera stands
	# back to one side to watch him go (OoT's door shot).
	if player is PlayerController:
		var p := player as PlayerController
		var inward := global_basis.z
		p.face_direction(Vector3(inward.x, 0, inward.z))
		if p.camera_rig:
			var out := -Vector3(inward.x, 0, inward.z).normalized()
			var side := Vector3(-out.z, 0, out.x)
			var at := global_position + Vector3.UP * 1.2
			var up := Vector3.UP * 0.7
			p.camera_rig.hold_shot_from([at + out * 3.4 + side * 1.6 + up, at + out * 3.4 - side * 1.6 + up, at + out * 3.6 + up * 1.4], at, World.FADE_OUT + 0.6, 0.3, null, 55.0)
	World.change_area(target_area, target_entrance)
