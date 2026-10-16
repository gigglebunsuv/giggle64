class_name GreatStone
extends StaticBody3D
## A great stone (Chapter V): a boulder far too big to lift, worn smooth where
## old hands once gripped it. With the Questlord's Gauntlets the hero takes
## hold of it (A) and drags it back toward himself, step by step; then it
## rolls aside, and whatever it sealed is open. `flag` keeps it moved. Without
## the gauntlets it will not budge.
##
## The stone's front (where the hero grips it) faces its local +Z; it is
## dragged PULL meters out along +Z, then rolls ROLL meters to its local +X
## (`roll_side` -1 rolls it the other way).

const PULL := 2.2
const ROLL := 2.8
const PULL_TIME := 2.2
const RADIUS := 1.15

@export var flag := ""
@export var roll_side := 1.0
@export var tint := Color(1, 1, 1)
## The story must have reached `need_flag` before it moves even for the
## gauntlets; until then A reads `wait_text` (the cliffs' pass waits for the
## Hollow King, who sends the hero east. Beta 1.5.1).
@export var need_flag := ""
@export_multiline var wait_text := ""

var moved := false
var _mesh: MeshInstance3D
var _busy := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = load("res://assets/models/great_stone_mesh.tres") if ResourceLoader.exists("res://assets/models/great_stone_mesh.tres") else null
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
	cyl.radius = RADIUS
	cyl.height = 2.3
	cs.shape = cyl
	cs.position = Vector3(0, 1.15, 0)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "stone")
	add_child(cs)
	if flag != "" and Progress.flag(flag):
		moved = true
		position += _final_offset()
		return
	add_to_group("interactable")
	add_to_group("great_stones")


func _final_offset() -> Vector3:
	return basis * Vector3(ROLL * roll_side, 0, PULL)


func can_interact(by: Node3D) -> bool:
	if moved or _busy:
		return false
	# Only from the front, where it can be gripped.
	var to := by.global_position - global_position
	to.y = 0.0
	return to.length() > 0.1 and (global_basis * Vector3.BACK).dot(to.normalized()) > 0.5


func interact_reach() -> float:
	return RADIUS + 1.1


func interact_label() -> String:
	return "GRAB"


func interact(by: Node) -> void:
	var p := by as PlayerController
	if p == null or _busy or moved:
		return
	if not Progress.can_pull_great():
		p.begin_talk(null)
		Dialogue.start(["A great stone, far too big to lift. Its sides are worn smooth in two places, as if once, long ago, a pair of strong hands gripped it and *dragged* it..."], null)
		await Dialogue.finished
		if is_instance_valid(p):
			p.end_talk()
		return
	if need_flag != "" and not Progress.flag(need_flag):
		p.begin_talk(null)
		Dialogue.start([wait_text if wait_text != "" else "The great stone won't budge."], null)
		await Dialogue.finished
		if is_instance_valid(p):
			p.end_talk()
		return
	_busy = true
	remove_from_group("interactable")
	var front := global_basis * Vector3.BACK
	front.y = 0.0
	front = front.normalized()
	p.begin_cutscene()
	p.global_position = Vector3(global_position.x, p.global_position.y, global_position.z) + front * (RADIUS + 0.55)
	p.face_direction(-front)
	p.cs_anim = &"pull"
	Sfx.play("stone_grip", -2.0, 0.05)
	await get_tree().create_timer(0.35, false).timeout
	Sfx.play("stone_drag", 0.0, 0.0)
	GameManager.rumble(0.5, PULL_TIME)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", global_position + front * PULL, PULL_TIME).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "global_position", p.global_position + front * PULL, PULL_TIME).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if not is_instance_valid(p):
		return
	p.cs_anim = &"idle"
	# It tips and rolls aside.
	var side := global_basis * Vector3.RIGHT * roll_side
	side.y = 0.0
	var roll := create_tween().set_parallel(true)
	roll.tween_property(self, "global_position", global_position + side.normalized() * ROLL, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	roll.tween_property(_mesh, "rotation:z", _mesh.rotation.z - PI * 0.5 * roll_side, 0.9)
	Sfx.play("rock_break", -4.0, 0.0, 0.6)
	await roll.finished
	if p.camera_rig:
		p.camera_rig.shake(0.1, 0.3)
	Sfx.play("quake_rumble", -6.0, 0.0, 1.2)
	moved = true
	_busy = false
	if flag != "":
		Progress.set_flag(flag)
	Sfx.play("secret", -2.0)
	p.end_cutscene()
