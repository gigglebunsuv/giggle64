class_name Telegraph
extends MeshInstance3D
## A boss's tell, drawn on the world for a moment (OoT shows its bosses'
## blows coming: King Dodongo's inhale, Bongo Bongo's shadow, Volvagia's
## falling rocks' shadows): flat, unshaded, see-through and fogless, so it
## reads in the gloom of any lair.
## - ring: a ring on the ground, pulsing (where a leap will land, and how far
##   its shockwave reaches);
## - strip: a band along the ground (a tongue's or a charge's line);
## - shockwave: a ring that rushes outward and fades;
## - glow: a soft pulsing ball (a weak point opening).

var life := 1.0
var _age := 0.0
var _grow := 0.0
var _pulse := true
var _base_scale := Vector3.ONE
var _col := Color(1, 0.3, 0.2, 0.5)
var _follow: Node3D
var _follow_off := Vector3.ZERO


static func _material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	m.no_depth_test = false
	m.albedo_color = col
	return m


static func _spawn(parent: Node, mesh: Mesh, at: Vector3, time: float, col: Color) -> Telegraph:
	var t := Telegraph.new()
	t.name = "Telegraph"
	t.mesh = mesh
	t.life = time
	t._col = col
	t.material_override = _material(col)
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	t.top_level = true
	parent.add_child(t)
	t.global_position = at
	return t


## A pulsing ring on the ground, `radius` across, for `time` seconds.
static func ring(parent: Node, at: Vector3, radius: float, time: float, col := Color(1.0, 0.35, 0.15, 0.55)) -> Telegraph:
	var tm := TorusMesh.new()
	tm.inner_radius = 0.86
	tm.outer_radius = 1.0
	tm.rings = 28
	tm.ring_segments = 4
	var t := _spawn(parent, tm, at + Vector3.UP * 0.06, time, col)
	t._base_scale = Vector3(radius, 0.05, radius)
	t.scale = t._base_scale
	return t


## A band along the ground from `from` along `dir`, `length` by `width`.
static func strip(parent: Node, from: Vector3, dir: Vector3, length: float, width: float, time: float, col := Color(1.0, 0.3, 0.15, 0.45)) -> Telegraph:
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.02, length)
	var flat := Vector3(dir.x, 0, dir.z).normalized()
	var t := _spawn(parent, bm, from + flat * length * 0.5 + Vector3.UP * 0.06, time, col)
	if flat.length() > 0.01:
		t.global_basis = Basis(Vector3.UP, atan2(-flat.x, -flat.z))
	return t


## A ring that rushes out to `radius` and fades (a shockwave).
static func shockwave(parent: Node, at: Vector3, radius: float, time: float, col := Color(1.0, 0.85, 0.5, 0.7)) -> Telegraph:
	var t := ring(parent, at, 0.3, time, col)
	t._grow = radius
	t._pulse = false
	return t


## A soft glowing ball at `at` (following `follow`, if given).
static func glow(parent: Node, at: Vector3, radius: float, time: float, col := Color(1.0, 0.95, 0.4, 0.45), follow: Node3D = null) -> Telegraph:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 6
	var t := _spawn(parent, sm, at, time, col)
	t._base_scale = Vector3.ONE * radius
	t.scale = t._base_scale
	if follow:
		t._follow = follow
		t._follow_off = at - follow.global_position
	return t


## Ends it early.
func finish() -> void:
	life = minf(life, _age + 0.12)


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	if is_instance_valid(_follow):
		global_position = _follow.global_position + _follow_off
	var k := _age / maxf(life, 0.01)
	var m := material_override as StandardMaterial3D
	if _grow > 0.0:
		var r := lerpf(0.3, _grow, 1.0 - (1.0 - k) * (1.0 - k))
		scale = Vector3(r, 0.05, r)
		m.albedo_color.a = _col.a * (1.0 - k)
		return
	var fade_in := clampf(_age / 0.12, 0.0, 1.0)
	var fade_out := clampf((life - _age) / 0.15, 0.0, 1.0)
	var beat := 0.75 + 0.25 * sin(_age * 18.0) if _pulse else 1.0
	m.albedo_color.a = _col.a * fade_in * fade_out * beat
	scale = _base_scale * (1.0 + (0.06 * sin(_age * 18.0) if _pulse else 0.0))
