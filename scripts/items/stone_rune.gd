class_name StoneRune
extends StaticBody3D
## A rune stone set into one of the Hidden Forest's standing stones. Struck
## by an arrow, the boomerang or the sword it glows for `lit_time` seconds,
## ticking as it fades (like OoT's timed torches, Obj_Syokudai). When every
## rune in the area glows at once they stay lit for good and set `flag`: the
## stones are awake, and the pedestal offers up the Bun Sword.

@export var flag := "hidden_forest:stones_awake"
@export var lit_time := 9.0

var lit := 0.0
var _gem: MeshInstance3D
var _mat: StandardMaterial3D
var _tick := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("stone_runes")
	_gem = MeshInstance3D.new()
	_gem.name = "Gem"
	_gem.mesh = load("res://assets/models/crystal_mesh.tres")
	_gem.scale = Vector3(0.9, 0.7, 0.9)
	add_child(_gem)
	_mat = (_gem.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_gem.material_override = _mat
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.5
	cs.shape = sph
	cs.set_meta("no_climb", true)
	add_child(cs)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.receiver = self
	var hcs := CollisionShape3D.new()
	var hs := SphereShape3D.new()
	hs.radius = 0.55
	hcs.shape = hs
	hb.add_child(hcs)
	add_child(hb)
	_colour()


func awake() -> bool:
	return Progress.flag(flag)


func is_lit() -> bool:
	return awake() or lit > 0.0


func _colour() -> void:
	if awake():
		_mat.albedo_color = Color(1.8, 1.5, 0.5)
	elif lit > 0.0:
		var k := clampf(lit / lit_time, 0.0, 1.0)
		_mat.albedo_color = Color(0.4, 0.9, 1.0).lerp(Color(0.6, 1.6, 1.8), k)
	else:
		_mat.albedo_color = Color(0.25, 0.55, 0.6)


func take_hit(info: HitInfo) -> int:
	if info.attacker is PlayerController:
		strike()
	return Hurtbox.Result.HIT


func arrow_hit(_arrow: Node3D, _point: Vector3) -> void:
	strike()


func boomerang_hit(_b: Node3D) -> void:
	strike()


func strike() -> void:
	if awake():
		return
	Sfx.play("crystal_hit", -3.0, 0.0, 0.8)
	lit = lit_time
	_colour()
	for r in get_tree().get_nodes_in_group("stone_runes"):
		if not (r as StoneRune).is_lit():
			return
	# All of them at once: the stones wake.
	Progress.set_flag(flag)
	Sfx.play("puzzle_solved", -2.0, 0.0)
	for r in get_tree().get_nodes_in_group("stone_runes"):
		(r as StoneRune)._colour()


func _process(delta: float) -> void:
	_gem.rotation.y += delta * (1.5 if is_lit() else 0.3)
	if lit <= 0.0 or awake():
		return
	lit = maxf(lit - delta, 0.0)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5 if lit > 3.0 else 0.25
		Sfx.play("rupee_tick", -14.0, 0.0, 0.6)
	_colour()
