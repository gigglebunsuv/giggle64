class_name SwordTrail
extends MeshInstance3D
## The sword's trail (Beta 1.8.0), after the 1998 builds of the classic rather
## than its final release: a broad, flat sheet of pale glass swept out between
## the blade's root and its tip, laid down in a few hard-edged facets (the
## blade sampled about 20 times a second, as the N64 did) with a bright line
## along the path of the tip, the whole sheet fading within a few frames.
## Those builds drew the spin attack's trail red, so the Great Spin's is red.
##
## The sheet lives in the world (top_level): each sample is the blade's root
## and tip where they were. Samples age with the game's own (scaled) time, so
## the trail holds still through the impact frames (Impact).

## How long a sample lasts, and how often the blade is sampled.
const LIFE := 0.26
const SAMPLE := 0.04
## Opacity of the newest edge of the sheet and of the tip line.
const SHEET_ALPHA := 0.62
const EDGE_ALPHA := 0.9
const WHITE := Color(0.93, 0.95, 1.0)
const RED := Color(1.0, 0.32, 0.26)

## The blade it follows (the hero's Sword node: the blade runs along its -Z).
var blade: Node3D
## Where along -Z the sheet starts (just past the guard) and ends (the tip).
var root_z := 0.15
var tip_z := 0.86
var emitting := false
var color := WHITE
## [[root, tip, age], ...], newest last.
var _samples: Array = []
var _since := 0.0
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_meta("no_tint", true)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material_override = mat


## Fits the sheet to the blade in hand (its mesh's length along -Z).
func fit_to(sword_mesh: Mesh) -> void:
	if sword_mesh == null:
		return
	var aabb := sword_mesh.get_aabb()
	tip_z = maxf(-aabb.position.z, 0.3)
	root_z = minf(0.15, tip_z * 0.2)


func _process(delta: float) -> void:
	global_transform = Transform3D.IDENTITY
	for s: Array in _samples:
		s[2] += delta
	while not _samples.is_empty() and float(_samples[0][2]) > LIFE:
		_samples.pop_front()
	var live := emitting and is_instance_valid(blade) and blade.is_visible_in_tree()
	if live:
		_since += delta
		var root := blade.global_transform * Vector3(0, 0, -root_z)
		var tip := blade.global_transform * Vector3(0, 0, -tip_z)
		if _samples.is_empty() or _since >= SAMPLE:
			_since = 0.0
			_samples.append([root, tip, 0.0])
		else:
			# The newest edge always sits on the blade itself.
			_samples[-1][0] = root
			_samples[-1][1] = tip
	_draw()


func _draw() -> void:
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(_samples.size() - 1):
		var a: Array = _samples[i]
		var b: Array = _samples[i + 1]
		# Solid through most of its life, then gone quickly, as the old
		# sheets were (not a soft gradient).
		var fa := 1.0 - pow(float(a[2]) / LIFE, 3.0)
		var fb := 1.0 - pow(float(b[2]) / LIFE, 3.0)
		var ca := Color(color, SHEET_ALPHA * fa)
		var cb := Color(color, SHEET_ALPHA * fb)
		# The facet between two samples: a flat quad, root to tip.
		_vert(a[0], Color(ca, ca.a * 0.55))
		_vert(a[1], ca)
		_vert(b[1], cb)
		_vert(a[0], Color(ca, ca.a * 0.55))
		_vert(b[1], cb)
		_vert(b[0], Color(cb, cb.a * 0.55))
		# The bright line the tip draws: a thin band just inside it.
		var ea := Color(WHITE.lerp(color, 0.4), EDGE_ALPHA * fa)
		var eb := Color(WHITE.lerp(color, 0.4), EDGE_ALPHA * fb)
		var ia: Vector3 = (a[1] as Vector3).lerp(a[0], 0.06)
		var ib: Vector3 = (b[1] as Vector3).lerp(b[0], 0.06)
		_vert(ia, ea)
		_vert(a[1], ea)
		_vert(b[1], eb)
		_vert(ia, ea)
		_vert(b[1], eb)
		_vert(ib, eb)
	_mesh.surface_end()


func _vert(p: Vector3, c: Color) -> void:
	_mesh.surface_set_color(c)
	_mesh.surface_add_vertex(p)


## Drops the trail at once (a new area, a cutscene).
func clear() -> void:
	_samples.clear()
	_mesh.clear_surfaces()
