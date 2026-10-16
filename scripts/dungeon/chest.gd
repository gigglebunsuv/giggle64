class_name TreasureChest
extends StaticBody3D
## A treasure chest, after OoT's En_Box (z_en_box.c): stand in front of it and
## A says OPEN; the lid swings up and the hero holds up what was inside
## (GetItem). Small chests hold small things; big chests hold the dungeon's
## treasures (the item, the boss key). A chest can be hidden until a flag is
## set (OoT's chests that appear when a room is cleared or a switch is hit),
## and it remembers being opened.

## What it holds (see GetItem.ITEMS).
@export var item := "rupee_blue"
@export var big := false
## Progress flag set once opened.
@export var flag := ""
## Hidden until this Progress flag is set ("" = always there).
@export var appear_flag := ""
## Unseen but there (OoT's invisible chests): only Mira's Looking Glass shows
## it, though it can be opened by anyone who knows where it stands.
@export var lens_hidden := false

var opened := false
var _lid: Node3D
var _shape: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("chests")
	var size := Vector3(1.5, 1.2, 1.0) if big else Vector3(0.95, 0.75, 0.62)
	var stem := "bigchest" if big else "chest"
	var base := MeshInstance3D.new()
	base.name = "Base"
	base.mesh = load("res://assets/models/%s_base_mesh.tres" % stem)
	add_child(base)
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0, size.y * 0.62, size.z * 0.5)
	add_child(_lid)
	var lid := MeshInstance3D.new()
	lid.mesh = load("res://assets/models/%s_lid_mesh.tres" % stem)
	_lid.add_child(lid)
	_shape = CollisionShape3D.new()
	_shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position = Vector3(0, size.y * 0.5, 0)
	_shape.set_meta("surface", "wood")
	add_child(_shape)
	opened = flag != "" and Progress.flag(flag)
	if opened:
		_lid.rotation.x = 1.9
	elif lens_hidden:
		add_to_group("lens_hidden")
		lens_show(false)
	if appear_flag != "" and not Progress.flag(appear_flag):
		_show(false)
		Progress.changed.connect(_check_appear)
	else:
		add_to_group("interactable")


## The Looking Glass shows or hides the chest's picture (it stays solid).
func lens_show(on: bool) -> void:
	for c in get_children():
		if c is MeshInstance3D or c == _lid:
			(c as Node3D).visible = on or opened


func _show(on: bool) -> void:
	visible = on
	_shape.set_deferred("disabled", not on)


func _check_appear() -> void:
	if not visible and Progress.flag(appear_flag):
		Progress.changed.disconnect(_check_appear)
		_show(true)
		add_to_group("interactable")
		# OoT's chests appear in a puff of smoke with the secret jingle.
		Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 0.5, 10, 2.0, 2.0, 0.8, 1.2, Color(2, 2, 2))
		Sfx.play("puzzle_solved", -3.0, 0.0)


## Opened from the front only.
func can_interact(by: Node3D) -> bool:
	if opened or not visible:
		return false
	var front := -global_basis.z
	var to := (by.global_position - global_position)
	to.y = 0.0
	return to.length() > 0.01 and Vector2(front.x, front.z).normalized().dot(Vector2(to.x, to.z).normalized()) > 0.4


func interact_label() -> String:
	return "OPEN"


func interact(player: Node) -> void:
	if opened:
		return
	opened = true
	if flag != "":
		Progress.set_flag(flag)
	remove_from_group("interactable")
	var p := player as PlayerController
	if p:
		p.begin_talk(self)
		_shot(p)
	Sfx.play("chest_open", -2.0)
	var t := create_tween()
	t.tween_interval(0.25 if not big else 0.6)
	t.tween_property(_lid, "rotation:x", 1.9, 0.6 if not big else 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	if p and is_instance_valid(p):
		await GetItem.present(p, item)
		if is_instance_valid(p) and p.camera_rig:
			p.camera_rig.release_shot()


## OoT's treasure-box camera: it swings round in front of the hero, off to
## his side, low for a small chest and further back for a big one, and holds
## there while the lid comes up and he raises what was inside.
func _shot(p: PlayerController) -> void:
	if p.camera_rig == null:
		return
	var front := -global_basis.z
	front = Vector3(front.x, 0, front.z).normalized()
	var side := Vector3(-front.z, 0, front.x)
	var at := (global_position + p.global_position) * 0.5 + Vector3.UP * (1.0 if big else 0.85)
	var back := front * (3.6 if big else 2.9)
	var off := side * (2.2 if big else 1.7)
	var up := Vector3.UP * (1.9 if big else 1.4)
	var base := global_position
	p.camera_rig.hold_shot_from([base + back + off + up, base + back - off + up, base + back * 1.15 + up * 1.2], at, 30.0, 0.6, null, 55.0, 1.8)
