class_name TechniqueTarget
extends StaticBody3D
## Things that answer to the Knight's Techniques (PlayerCombat), one `mode` each:
## - "seal":  a cracked floor seal over a hole (the Barrow of Kings). Solid
##            underfoot; a DOWN THRUST onto it shatters it and the hero drops
##            through. Sets `flag`.
## - "plate": a straw target on the training ground (the Knights' Yard): a
##            DOWN THRUST onto it sets `flag` (it does not break).
## - "ring":  a ring of rune bells (or training dummies) round a center: one
##            GREAT SPIN from inside the ring strikes them all at once and
##            sets `flag`. A plain swing only rings one.
## - "pell":  a training post with a wooden shield (the Knights' Yard): the
##            sword just knocks on the shield; a SHIELD BASH knocks the shield
##            flying, then a blow to the post sets `flag`.
## Done, it stays done (`flag`).

@export var mode := "seal"
@export var flag := ""
## The seal's / plate's size across, or the ring's radius.
@export var size := 2.6
## For "ring": how many bells, and their mesh ("rune_bell" or "training_dummy").
@export var count := 4
@export var post_mesh := "rune_bell"

var done := false
var _shield_off := false
var _parts: Array[Node3D] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	done = flag != "" and Progress.flag(flag)
	match mode:
		"seal":
			if done:
				queue_free()
				return
			_mesh("floor_seal_mesh", Vector3(size, 1.0, size), Vector3(0, -0.15, 0))
			_box(Vector3(size, 0.3, size), Vector3(0, -0.15, 0), "stone")
			add_to_group("thrust_targets")
		"plate":
			_mesh("training_plate_mesh", Vector3(size, 1.0, size), Vector3.ZERO)
			add_to_group("thrust_targets")
		"ring":
			for i in count:
				var a := TAU * i / count + PI / count
				var at := Vector3(cos(a) * size, 0, sin(a) * size)
				var post := _mesh(post_mesh + "_mesh", Vector3.ONE, at)
				post.rotation.y = -a + PI * 0.5
				_parts.append(post)
				_box(Vector3(0.5, 1.6, 0.5), at + Vector3(0, 0.8, 0), "wood" if post_mesh == "training_dummy" else "stone")
				if done:
					_ring_down(post, true)
			add_to_group("spin_targets")
		"pell":
			_parts.append(_mesh("training_pell_mesh", Vector3.ONE, Vector3.ZERO))
			_parts.append(_mesh("training_pell_shield_mesh", Vector3.ONE, Vector3.ZERO))
			_box(Vector3(0.6, 1.8, 0.6), Vector3(0, 0.9, 0), "wood")
			if done:
				_parts[1].visible = false
				_shield_off = true
			add_to_group("bash_targets")
			_add_hurtbox()


func _mesh(mesh_name: String, scale_by: Vector3, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name.to_pascal_case()
	var path := "res://assets/models/%s.tres" % mesh_name
	if ResourceLoader.exists(path):
		mi.mesh = load(path)
	mi.scale = scale_by
	mi.position = at
	add_child(mi)
	return mi


func _box(s: Vector3, at: Vector3, surface: String) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = s
	cs.shape = box
	cs.position = at
	cs.set_meta("no_climb", mode != "seal" and mode != "plate")
	cs.set_meta("surface", surface)
	add_child(cs)


## The pell takes sword blows (layer 16) so the shield can turn them.
func _add_hurtbox() -> void:
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.receiver = self
	hb.collision_layer = 16
	hb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 1.8, 0.8)
	cs.shape = box
	cs.position = Vector3(0, 0.9, 0)
	hb.add_child(cs)
	add_child(hb)


## A Hurtbox calls this (the pell).
func take_hit(info: HitInfo) -> int:
	if mode != "pell":
		return Hurtbox.Result.IGNORED
	if info.kind == "bash":
		bash_hit(info.attacker)
		return Hurtbox.Result.HIT
	if done:
		Sfx.play("wall_hit_soft", -6.0, 0.05)
		return Hurtbox.Result.HIT
	if not _shield_off:
		Sfx.play("shield_block", -2.0, 0.05, 0.9)
		_wobble(_parts[0], 0.12)
		return Hurtbox.Result.BLOCKED
	_wobble(_parts[0], 0.3)
	Sfx.play("sword_hit", -2.0)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.2, 10, 2.5, 2.5, 0.6, 0.6, Color(0.9, 0.8, 0.45))
	_finish()
	return Hurtbox.Result.HIT


func thrust_reach() -> float:
	return size * 0.5 + 0.4


func thrust_hit(_by: Node3D) -> void:
	if done:
		return
	match mode:
		"seal":
			done = true
			remove_from_group("thrust_targets")
			Sfx.play("rock_break", 0.0, 0.05, 0.8)
			Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position, 20, 3.0, 2.0, 1.0, 1.2, Color(0.62, 0.58, 0.52))
			if flag != "":
				Progress.set_flag(flag)
			Sfx.play("secret", -4.0)
			queue_free()
		"plate":
			Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 0.2, 14, 2.5, 3.0, 0.7, 0.7, Color(0.9, 0.8, 0.45))
			_finish()


func spin_hit(by: Node3D) -> void:
	if mode != "ring" or done or by == null:
		return
	var to := by.global_position - global_position
	if Vector2(to.x, to.z).length() > size + 0.4:
		return
	for post in _parts:
		_ring_down(post, false)
	if post_mesh == "training_dummy":
		Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.0, 24, 4.0, 3.0, 0.8, 0.8, Color(0.9, 0.8, 0.45))
	else:
		Sfx.play("temple_bell", -4.0, 0.0, 1.4)
	_finish()


func bash_hit(_by: Node3D) -> void:
	if mode != "pell" or _shield_off:
		return
	_shield_off = true
	Sfx.play("wood_break", -2.0, 0.05)
	var sh := _parts[1]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sh, "position", sh.position + Vector3(0, -0.6, 1.4), 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(sh, "rotation:x", -PI * 0.5, 0.35)


func _ring_down(post: Node3D, instant: bool) -> void:
	if instant:
		post.rotation.x = -0.4 if post_mesh == "training_dummy" else 0.0
		return
	var tw := post.create_tween()
	tw.tween_property(post, "rotation:x", -0.5, 0.15)
	tw.tween_property(post, "rotation:x", -0.4 if post_mesh == "training_dummy" else 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC)


func _wobble(n: Node3D, amount: float) -> void:
	var tw := n.create_tween()
	tw.tween_property(n, "rotation:x", -amount, 0.08)
	tw.tween_property(n, "rotation:x", 0.0, 0.4).set_trans(Tween.TRANS_ELASTIC)


func _finish() -> void:
	if done:
		return
	done = true
	if flag != "":
		Progress.set_flag(flag)
	Sfx.play("puzzle_solved", -2.0)
