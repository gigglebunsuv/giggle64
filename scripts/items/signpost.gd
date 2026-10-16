class_name Signpost
extends StaticBody3D
## A wooden sign, after OoT's En_Kanban (z_en_kanban.c):
## - Facing its board, A reads it: the A button says CHECK (OoT gives
##   DO_ACTION_CHECK for anything that is not an NPC) and the text appears at
##   once in the wooden text box (TEXTBOX_TYPE_WOODEN).
## - The sword cuts the board off its post; the halves tumble away and the
##   sign cannot be read again until the area is reloaded.
## The board faces local -Z.

## The sign's text. "\n\n" starts a new box; *stars* color words (orange on wood).
@export_multiline var text := ""

var cut := false
var _board: Node3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	add_to_group("signs")
	var post := MeshInstance3D.new()
	post.name = "Post"
	post.mesh = load("res://assets/models/sign_post_mesh.tres")
	add_child(post)
	_board = Node3D.new()
	_board.name = "Board"
	_board.position = Vector3(0, 1.15, 0)
	add_child(_board)
	for m in ["sign_board_mesh", "sign_text_mesh"]:
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/%s.tres" % m)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_board.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 1.4, 0.2)
	cs.shape = box
	cs.position = Vector3(0, 0.7, 0.04)
	cs.set_meta("no_climb", true)
	cs.set_meta("surface", "wood")
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hbox := BoxShape3D.new()
	hbox.size = Vector3(1.0, 0.6, 0.3)
	hcs.shape = hbox
	hcs.position = Vector3(0, 1.15, 0)
	hb.add_child(hcs)
	add_child(hb)


## Read from the front only.
func can_interact(by: Node3D) -> bool:
	var front := -global_basis.z
	var to := by.global_position - global_position
	return not cut and Vector2(front.x, front.z).dot(Vector2(to.x, to.z)) > 0.0


func interact_label() -> String:
	return "CHECK"


func interact(player: Node) -> void:
	if Dialogue.active or cut:
		return
	var pages: Array = []
	for p in text.split("\n\n"):
		pages.append({"text": p, "instant": true})
	if player is PlayerController:
		(player as PlayerController).begin_talk(self)
	Dialogue.start(pages, self, "wooden")
	await Dialogue.finished
	if player is PlayerController and is_instance_valid(player):
		(player as PlayerController).end_talk()


func take_hit(info: HitInfo) -> int:
	if cut or not (info.attacker is PlayerController):
		return Hurtbox.Result.IGNORED
	cut = true
	remove_from_group("interactable")
	_board.visible = false
	Sfx.play("sign_cut", -2.0)
	Fragments.burst(get_parent(), load("res://assets/models/sign_half_mesh.tres"), _board.global_position, 2, 1.6, 3.0, 1.6, 1.0)
	return Hurtbox.Result.HIT
