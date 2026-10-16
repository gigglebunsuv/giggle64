class_name DigSpot
extends Node3D
## A patch of soft, dark earth the Grave Spade can turn over (Chapter IV): a
## treasure chart's X, a grave in Ashwick, the buried stairs into the Temple
## of Bun. Dug once (flag "dug:<id>"), it gives up `prize` (a GetItem id, or
## a pickup when `loose`), sets `reveal_flag` if it has one, and is left a
## flat dark hole.

@export var id := ""
## A GetItem id ("" = nothing but `reveal_flag`).
@export var prize := ""
## A pickup that pops out instead of the get-item scene (rupees, hearts).
@export var loose := false
@export var reveal_flag := ""
## Only diggable once this flag is set ("" = always).
@export var need_flag := ""
## The mound's look: "earth", "sand", "snow", "ash".
@export var soil := "earth"
## How close in front of the hero the spade must bite.
const REACH := 1.6

var _mound: MeshInstance3D


func _ready() -> void:
	add_to_group("dig_spots")
	_mound = MeshInstance3D.new()
	_mound.name = "Mound"
	var path := "res://assets/models/dig_mound_%s_mesh.tres" % soil
	if not ResourceLoader.exists(path):
		path = "res://assets/models/dig_mound_earth_mesh.tres"
	if ResourceLoader.exists(path):
		_mound.mesh = load(path)
	add_child(_mound)
	_refresh()
	Progress.changed.connect(_refresh)


func flag_name() -> String:
	return "dug:" + id


func is_dug() -> bool:
	return id != "" and Progress.flag(flag_name())


func can_dig() -> bool:
	return not is_dug() and (need_flag == "" or Progress.flag(need_flag))


func _refresh() -> void:
	if _mound and is_inside_tree():
		# Dug: a flat, darker scar; not yet: the soft mound.
		_mound.scale = Vector3(1.0, 0.25, 1.0) if is_dug() else Vector3.ONE


## The spade bit here.
func dig(player: PlayerController) -> void:
	if not can_dig():
		return
	Progress.set_flag(flag_name())
	if reveal_flag != "":
		Progress.set_flag(reveal_flag)
	Sfx.play("secret", -2.0, 0.0)
	if prize == "":
		return
	if loose:
		Drops.spawn(prize, global_position + Vector3.UP * 0.4, get_parent(), true)
		return
	if is_instance_valid(player):
		await GetItem.present(player, prize)


## The dig spot within reach of a spade swung at `at` (null when none).
static func near(tree: SceneTree, at: Vector3) -> DigSpot:
	var best: DigSpot = null
	var best_d := REACH
	for n in tree.get_nodes_in_group("dig_spots"):
		var s := n as DigSpot
		if s == null or not s.can_dig():
			continue
		var d := Vector2(s.global_position.x - at.x, s.global_position.z - at.z).length()
		if d < best_d and absf(s.global_position.y - at.y) < 1.5:
			best = s
			best_d = d
	return best
