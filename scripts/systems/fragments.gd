class_name Fragments
extends Node3D
## A burst of debris (leaves from a cut shrub, pot shards, sign pieces, bones):
## each piece flies out, tumbles under gravity, bounces once on the floor height
## it started from and shrinks away (OoT's EffectSsKakera).

var _pieces: Array = []
var _time := 0.0
var _life := 1.0
var _floor := 0.0
var _gravity := 14.0


## Throws `count` copies of `mesh` out from `pos` under `parent`.
## `speed` is the outward speed (m/s), `up` the upward one.
static func burst(parent: Node, mesh: Mesh, pos: Vector3, count: int, speed := 2.5, up := 3.5, life := 1.0, scale := 1.0, tint := Color(1, 1, 1), gravity := 14.0) -> Fragments:
	var f := Fragments.new()
	f.name = "Fragments"
	parent.add_child(f)
	f.global_position = pos
	f._life = life
	f._floor = pos.y - 0.3
	f._gravity = gravity
	var mat: Material = null
	if tint != Color(1, 1, 1) and mesh and mesh.get_surface_count() > 0:
		var base := mesh.surface_get_material(0) as StandardMaterial3D
		if base:
			mat = base.duplicate()
			(mat as StandardMaterial3D).albedo_color = tint
	for i in count:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mat:
			mi.material_override = mat
		f.add_child(mi)
		var a := randf() * TAU
		var s := randf_range(0.5, 1.0) * speed
		mi.scale = Vector3.ONE * scale * randf_range(0.7, 1.2)
		mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		f._pieces.append({
			"node": mi,
			"v": Vector3(cos(a) * s, randf_range(0.6, 1.0) * up, sin(a) * s),
			"spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9)),
			"scale": mi.scale,
		})
	return f


func _physics_process(delta: float) -> void:
	_time += delta
	var k := clampf(1.0 - (_time - _life * 0.6) / (_life * 0.4), 0.0, 1.0)
	for p: Dictionary in _pieces:
		var n: MeshInstance3D = p.node
		var v: Vector3 = p.v
		v.y -= _gravity * delta
		var pos := n.position + v * delta
		if pos.y + global_position.y < _floor and v.y < 0.0:
			v.y = -v.y * 0.3
			v.x *= 0.5
			v.z *= 0.5
			pos.y = _floor - global_position.y
		n.position = pos
		p.v = v
		n.rotation += p.spin * delta
		n.scale = p.scale * k
	if _time >= _life:
		queue_free()
