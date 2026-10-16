class_name FlailTarget
extends StaticBody3D
## Things only the Iron Flail's ball breaks or rings (Beta 1.4.0), one
## `mode` each:
## - "gate":   an iron grate across a doorway, `size` wide: one blow from the
##             ball bursts it open. Sets `flag`.
## - "pillar": a cracked pillar beside a gap: struck, it topples across the gap
##             (the bridge is a FlagBridge on `flag`, laid where it falls).
## - "bell":   an iron bell hung high, out of the sword's reach: the ball rings
##             it and it stays rung. Its `flag` is set; a FlagAll gathers a
##             set of bells.
## The sword and bombs only clang off them. Done, they stay done (`flag`).

@export var mode := "gate"
@export var flag := ""
@export var size := 3.0
@export var tall := 3.2

var done := false
var _mesh: Node3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	done = flag != "" and Progress.flag(flag)
	add_to_group("flail_targets")
	match mode:
		"gate":
			if done:
				queue_free()
				return
			_mesh = _bars()
			_box(Vector3(size, tall, 0.4), Vector3(0, tall * 0.5, 0))
		"pillar":
			_mesh = _pillar()
			if done:
				_fallen(true)
			else:
				_box(Vector3(0.9, tall, 0.9), Vector3(0, tall * 0.5, 0))
		"bell":
			_mesh = _bell()
			if done:
				_mesh.rotation.z = 0.0


func flail_reach() -> float:
	match mode:
		"gate":
			return size * 0.55
		"pillar":
			return 0.9
	return 0.8


func flail_hit(_by: Node3D) -> void:
	if done:
		if mode == "bell":
			Sfx.play("shield_block", -6.0, 0.05, 2.0)
		return
	done = true
	if flag != "":
		Progress.set_flag(flag)
	match mode:
		"gate":
			Sfx.play("mallet_smash", 0.0, 0.05, 0.8)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.4, 14, 4.0, 3.0, 0.5, 0.3, Color(0.4, 0.4, 0.45))
			queue_free()
		"pillar":
			Sfx.play("mallet_smash", 2.0, 0.05, 0.5)
			Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3.UP * 1.0, 12, 3.0, 3.0, 0.6, 0.6, Color(0.4, 0.4, 0.44))
			_fallen(false)
		"bell":
			Sfx.play("shield_block", 2.0, 0.0, 1.8)
			Sfx.play("goddess_chime", -6.0, 0.0, 1.3)
			var t := create_tween()
			t.tween_property(_mesh, "rotation:z", 0.5, 0.15)
			t.tween_property(_mesh, "rotation:z", -0.35, 0.3)
			t.tween_property(_mesh, "rotation:z", 0.0, 0.4)
			Sfx.play("puzzle_solved", -8.0)


## The pillar lies across the gap (forward, -Z); its own collision goes
## (the FlagBridge carries the hero).
func _fallen(at_once: bool) -> void:
	for c in get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).set_deferred("disabled", true)
	if at_once:
		_mesh.rotation.x = -PI * 0.5
		return
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_mesh, "rotation:x", -PI * 0.5, 0.8)
	t.tween_callback(func() -> void:
		Sfx.play("mallet_smash", 3.0, 0.0, 0.4)
		var hero := GameManager.player
		if hero and hero.camera_rig:
			hero.camera_rig.shake(0.15, 0.4))


func _box(s: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = s
	cs.shape = b
	cs.position = at
	cs.set_meta("no_climb", true)
	add_child(cs)


func _mat(col: Color, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = 0.6
	return m


func _bars() -> Node3D:
	var root := Node3D.new()
	root.name = "Bars"
	add_child(root)
	var iron := _mat(Color(0.26, 0.26, 0.3), 0.5)
	var n := int(size / 0.35)
	for i in n + 1:
		var bar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = tall
		cm.radial_segments = 6
		cm.material = iron
		bar.mesh = cm
		bar.position = Vector3(-size * 0.5 + i * size / n, tall * 0.5, 0)
		root.add_child(bar)
	for y in [0.4, tall * 0.5, tall - 0.3]:
		var rail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(size, 0.12, 0.12)
		bm.material = iron
		rail.mesh = bm
		rail.position = Vector3(0, y, 0)
		root.add_child(rail)
	return root


func _pillar() -> Node3D:
	var root := Node3D.new()
	root.name = "Pillar"
	add_child(root)
	var stone := _mat(Color(0.3, 0.3, 0.34))
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.48
	cm.height = tall
	cm.radial_segments = 8
	cm.material = stone
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.position = Vector3(0, tall * 0.5, 0)
	root.add_child(mi)
	# The crack: a pale seam round its foot.
	var seam := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.44
	tm.outer_radius = 0.52
	tm.material = _mat(Color(0.7, 0.68, 0.6))
	seam.mesh = tm
	seam.position = Vector3(0, 0.5, 0)
	root.add_child(seam)
	return root


func _bell() -> Node3D:
	var root := Node3D.new()
	root.name = "Bell"
	root.position = Vector3(0, tall, 0)
	add_child(root)
	var bronze := _mat(Color(0.55, 0.42, 0.22), 0.7)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.42
	cm.height = 0.7
	cm.radial_segments = 10
	cm.material = bronze
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.position = Vector3(0, -0.45, 0)
	root.add_child(mi)
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.14, 0.14)
	bm.material = _mat(Color(0.35, 0.26, 0.18))
	beam.mesh = bm
	root.add_child(beam)
	if not done:
		root.rotation.z = 0.12
	return root
