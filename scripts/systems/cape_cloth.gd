class_name CapeCloth
extends MeshInstance3D
## A cape hung from the shoulders that swings, streams and settles like
## Ganondorf's cape in Ocarina of Time (EnGanonMant, z_en_ganon_mant.c).
##
## A row of strands hangs from a curved collar, each a chain of joints a fixed
## length apart (EnGanonMant_UpdateStrand). Every tick, top to bottom, a joint
## aims from the joint above toward where it was plus its velocity, pushed back
## off the body and out to the sides (strongest at the collar, fading down the
## strand), and pulled down; it is then put exactly one joint length from the
## joint above. A cylinder round the body that widens toward the hem keeps it
## off the legs (minDist x sDistMultipliers), a floor keeps it off the ground
## (minY), and its new velocity is 80% of how far it moved, clamped. The mesh's
## vertices are the joints (EnGanonMant_UpdateVertices).
##
## Positions live in the world, so the cape lags, whips round on turns and
## streams back on a run by itself. Ticks run at OoT's 20 Hz at the game's x1.5
## rate; drawn frames between ticks interpolate the joints relative to the
## collar, so it never trails behind the shoulders.

const STRANDS := 12
const JOINTS := 12
const TICK := 1.0 / 30.0
## The middle strand (checked for warps).
const MID := 6
## One OoT unit in meters (the player's oot_unit): the tuning below is in units.
const UNIT := 0.03

## How much each joint is pushed back off the body, out to the sides, and how
## far from the body it is kept (sBackSwayCoefficients, sSideSwayCoefficients,
## sDistMultipliers).
const BACK_K: Array[float] = [0.0, 1.0, 0.5, 0.25, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
const SIDE_K: Array[float] = [0.0, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.0]
const DIST_K: Array[float] = [0.0, 1.0, 1.0, 1.0, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7]

## EnGanonMant's fields, in OoT units (Ganondorf: gravity -3, backPush -3,
## backSwayMagnitude 0.25, sideSwayMagnitude -3, minDist 20; a short cape on
## a smaller body wants less push and a tighter body). Negative pushes away.
@export var gravity := -3.0
@export var back_push := -1.5
@export var back_sway := 1.0
@export var side_sway := -0.9
@export var min_dist := 5.5

## The cape's shape: hanging length, the collar's half-width, how far behind
## the torso joint it sits and how much it curves round the back.
@export var length := 0.78
@export var collar_half := 0.27
@export var collar_back := 0.14
@export var collar_curve := 0.07
## Cloth, its shadowed foot and the hem.
var colors: Array = ["b01e2a", "7a1018", "d8b050"]
## Whose origin is the middle of the body and the floor (the CharacterModel).
var body: Node3D

var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
## Each joint relative to its strand's collar point, at the last two ticks.
var _rel := PackedVector3Array()
var _rel_prev := PackedVector3Array()
var _roots := PackedVector3Array()
var _acc := 0.0
var _settled := false
var _back := Vector3.BACK
var _side := Vector3.RIGHT
var _arrays := []
var _material: StandardMaterial3D


func _ready() -> void:
	var n := STRANDS * JOINTS
	_pos.resize(n)
	_vel.resize(n)
	_rel.resize(n)
	_rel_prev.resize(n)
	_roots.resize(STRANDS)
	_build_arrays()
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_material.roughness = 1.0
	mesh = ArrayMesh.new()
	# The joints wander anywhere round the hero: never cull the cape by its bounds.
	custom_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var n64 := get_node_or_null("/root/N64Mode")
	if n64:
		n64.changed.connect(_on_n64)
		_on_n64(n64.active)
	else:
		material_override = _material
	visibility_changed.connect(func() -> void: _settled = false)
	_step_frame(0.0)


func _on_n64(on: bool) -> void:
	var n64 := get_node_or_null("/root/N64Mode")
	material_override = n64.convert_material(_material) if on and n64 else _material


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_step_frame(delta)


## Hangs the cape straight and lets it settle where it rests, without swinging
## in from wherever it last was (on first showing, after a warp or a cut).
func reset() -> void:
	_settled = false


func _step_frame(delta: float) -> void:
	_update_frame()
	if not _settled:
		_hang()
		for i in 40:
			_tick()
		_rel_prev = _rel.duplicate()
		_settled = true
		_acc = 0.0
	else:
		_acc += minf(delta, 0.25)
		while _acc >= TICK:
			_acc -= TICK
			_update_frame()
			# A warp: the collar jumped further than any run, so start afresh.
			if _roots[MID].distance_to(_pos[MID * JOINTS]) > 1.5:
				_hang()
			_rel_prev = _rel.duplicate()
			_tick()
	_draw(clampf(_acc / TICK, 0.0, 1.0))


## The collar points in the world, and the body's back and side directions
## on the ground (EnGanonMant_Draw's roots and baseYaw).
func _update_frame() -> void:
	var xf := global_transform
	for s in STRANDS:
		var t := float(s) / (STRANDS - 1)
		_roots[s] = xf * Vector3(-cos(t * PI) * collar_half, 0.0, collar_back + sin(t * PI) * collar_curve)
	var b := xf.basis.z
	b.y = 0.0
	if b.length_squared() > 0.01:
		_back = b.normalized()
		_side = Vector3.UP.cross(_back).normalized()


func _hang() -> void:
	var seg := length / (JOINTS - 1)
	for s in STRANDS:
		for j in JOINTS:
			var i := s * JOINTS + j
			_pos[i] = _roots[s] + Vector3(0, -seg * j, 0) + _back * 0.01 * j
			_vel[i] = Vector3.ZERO


## One OoT frame of every strand (EnGanonMant_UpdateStrand).
func _tick() -> void:
	var seg := length / (JOINTS - 1)
	var centre := body.global_position if body else global_position
	var floor_y := centre.y + 0.03 if body else -INF
	var grav := Vector3(0, gravity * UNIT, 0)
	var decel := 0.1 * UNIT
	var vmax := 5.0 * UNIT
	for s in STRANDS:
		var base := s * JOINTS
		_pos[base] = _roots[s]
		_rel[base] = Vector3.ZERO
		# The folds (a fixed ripple across the strands) and the flare outward.
		var fold := back_push + sin(s * TAU / 2.1) * back_sway
		var flare := cos(s * PI / (STRANDS - 1)) * side_sway
		for j in range(1, JOINTS):
			var i := base + j
			var p := _pos[i]
			var v := _vel[i]
			v = Vector3(_approach_zero(v.x, decel), _approach_zero(v.y, decel), _approach_zero(v.z, decel))
			var up := _pos[i - 1]
			var push := -_back * (fold * BACK_K[j] * UNIT) + _side * (flare * SIDE_K[j] * UNIT)
			var aim := (p + v - up) + push + grav
			if aim.length_squared() < 1e-12:
				aim = Vector3.DOWN
			var np := up + aim.normalized() * seg
			# Kept off the body.
			var r := min_dist * DIST_K[j] * UNIT
			var off := Vector2(np.x - centre.x, np.z - centre.z)
			if off.length_squared() < r * r:
				var dir := off.normalized() if off.length_squared() > 1e-8 else Vector2(_back.x, _back.z)
				np.x = centre.x + dir.x * r
				np.z = centre.z + dir.y * r
			np.y = maxf(np.y, floor_y)
			v = (np - p) * 0.8
			v = v.clamp(Vector3(-vmax, -vmax, -vmax), Vector3(vmax, vmax, vmax))
			_pos[i] = np
			_vel[i] = v
			_rel[i] = np - _roots[s]


static func _approach_zero(x: float, step: float) -> float:
	return x - clampf(x, -step, step)


## Index and color arrays (fixed); each side has its own vertices so the
## inside of the cape lights as the inside.
func _build_arrays() -> void:
	var cloth := Color.html(String(colors[0]))
	var foot := Color.html(String(colors[1]))
	var hem := Color.html(String(colors[2]))
	var n := STRANDS * JOINTS
	var cols := PackedColorArray()
	cols.resize(n * 2)
	for s in STRANDS:
		for j in JOINTS:
			var v := float(j) / (JOINTS - 1)
			var c := hem if j == JOINTS - 1 else cloth.lerp(foot, clampf(v / 0.9, 0.0, 1.0))
			cols[s * JOINTS + j] = c
			cols[n + s * JOINTS + j] = c
	var idx := PackedInt32Array()
	for s in STRANDS - 1:
		for j in JOINTS - 1:
			var a := s * JOINTS + j
			var b := a + JOINTS
			var c := b + 1
			var d := a + 1
			idx.append_array([a, b, c, a, c, d])
			idx.append_array([n + a, n + c, n + b, n + a, n + d, n + c])
	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_COLOR] = cols
	_arrays[Mesh.ARRAY_INDEX] = idx


func _draw(t: float) -> void:
	var inv := global_transform.affine_inverse()
	var n := STRANDS * JOINTS
	var local := PackedVector3Array()
	local.resize(n)
	for s in STRANDS:
		for j in JOINTS:
			var i := s * JOINTS + j
			local[i] = inv * (_roots[s] + _rel_prev[i].lerp(_rel[i], t))
	var verts := PackedVector3Array()
	verts.resize(n * 2)
	var norms := PackedVector3Array()
	norms.resize(n * 2)
	for s in STRANDS:
		for j in JOINTS:
			var i := s * JOINTS + j
			var across := local[mini(s + 1, STRANDS - 1) * JOINTS + j] - local[maxi(s - 1, 0) * JOINTS + j]
			var down := local[s * JOINTS + mini(j + 1, JOINTS - 1)] - local[s * JOINTS + maxi(j - 1, 0)]
			var nm := down.cross(across)
			nm = nm.normalized() if nm.length_squared() > 1e-12 else Vector3.BACK
			verts[i] = local[i]
			verts[n + i] = local[i]
			norms[i] = nm
			norms[n + i] = -nm
	_arrays[Mesh.ARRAY_VERTEX] = verts
	_arrays[Mesh.ARRAY_NORMAL] = norms
	var m := mesh as ArrayMesh
	m.clear_surfaces()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
