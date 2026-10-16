class_name SpellEffect
extends Node3D
## The look of the newer items' magic, all made from simple glowing shapes:
## - "harvest": Alan's Harvest, a ring of green light that sweeps outward over
##   the ground and a column of motes rising round the hero (Nayru's Love's
##   crystal, reworked);
## - "ruin": Serielye's Ruin, a dark red shell of force bursting outward
##   (Din's Fire's dome, with no fire);
## - "gale": Aphiel's Gale, a whirl of pale green wind (Farore's Wind);
## - "gale_point": the small whirl that stays where a Gale Point is set;
## - "flash": a Puff Nut's white flash;
## - "quake": the ring of dust where the Iron Mallet strikes;
## - "sun": a Sun Arrow's burst of golden light;
## - "stars": the ring of little stars over a dazed creature's head;
## - "ice": the block of ice round a frozen creature (`size` across);
## - "steam": a cloud of white steam rising where the Ember Rod melts ice.
## - "dream": Lothelye's Dream, a slow violet ring rising round the hero and
##   pale stars drifting up.

var kind := ""
## The ice block's size (width, height, depth).
var size := Vector3(1.3, 1.8, 1.3)
var _t := 0.0
var _life := 1.0
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D
var _colour := Color.WHITE
var _light_energy := 0.0


static func make(parent: Node, effect: String, pos: Vector3) -> SpellEffect:
	var e := SpellEffect.new()
	e.kind = effect
	e.name = "Spell_" + effect
	if parent == null:
		parent = World.area_node
	parent.add_child(e)
	e.global_position = pos
	return e


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.disable_fog = true
	_mesh = MeshInstance3D.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.material_override = _mat
	add_child(_mesh)
	match kind:
		"harvest":
			_life = 1.1
			_colour = Color(0.45, 1.0, 0.45)
			_mesh.mesh = _ring(1.0, 0.18)
			_add_light(_colour, 3.0, 9.0)
			_motes(Color(0.6, 1.0, 0.5), 18)
		"ruin":
			_life = 0.7
			_colour = Color(1.0, 0.25, 0.35)
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			sphere.radial_segments = 16
			sphere.rings = 8
			_mesh.mesh = sphere
			_add_light(Color(1.0, 0.3, 0.4), 5.0, 12.0)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 18, 7.0, 6.0, 0.6, 0.8, Color(1.6, 0.4, 0.5))
		"dream":
			_life = 1.4
			_colour = Color(0.7, 0.6, 1.0)
			_mesh.mesh = _ring(1.0, 0.1)
			_add_light(_colour, 3.0, 8.0)
			_motes(Color(0.8, 0.75, 1.0), 20)
		"gale", "gale_point":
			_life = 1.0 if kind == "gale" else INF
			_colour = Color(0.55, 1.0, 0.8)
			_mesh.mesh = _ring(0.7, 0.12)
			if kind == "gale":
				_add_light(_colour, 2.0, 6.0)
				_motes(Color(0.7, 1.0, 0.9), 14)
		"flash":
			_life = 0.35
			_colour = Color(1.0, 1.0, 0.85)
			var s := SphereMesh.new()
			s.radius = 1.0
			s.height = 2.0
			_mesh.mesh = s
			_add_light(_colour, 6.0, 8.0)
		"quake":
			_life = 0.5
			_colour = Color(0.75, 0.68, 0.55)
			_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			_mesh.mesh = _ring(1.0, 0.25)
		"sun":
			_life = 0.6
			_colour = Color(1.0, 0.9, 0.45)
			var ss := SphereMesh.new()
			ss.radius = 1.0
			ss.height = 2.0
			_mesh.mesh = ss
			_add_light(Color(1.0, 0.85, 0.5), 6.0, 10.0)
		"stars":
			_life = INF
			_colour = Color(1.0, 0.95, 0.5)
			_mesh.mesh = null
			for i in 3:
				var star := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.07
				sm.height = 0.14
				sm.radial_segments = 6
				sm.rings = 3
				star.mesh = sm
				star.material_override = _mat
				star.position = Vector3(cos(TAU * i / 3.0), 0, sin(TAU * i / 3.0)) * 0.35
				_mesh.add_child(star)
		"steam":
			_life = 1.2
			_colour = Color(0.95, 0.97, 1.0, 0.7)
			_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			var st := SphereMesh.new()
			st.radius = 1.0
			st.height = 2.0
			st.radial_segments = 10
			st.rings = 5
			_mesh.mesh = st
			_motes(Color(0.9, 0.95, 1.0), 12)
		"ice":
			_life = INF
			_colour = Color(0.7, 0.9, 1.0, 0.5)
			_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			var box := BoxMesh.new()
			_mesh.mesh = box
	_mat.albedo_color = _colour
	_update(0.0)


func _add_light(c: Color, energy: float, reach: float) -> void:
	_light = OmniLight3D.new()
	_light.light_color = c
	_light.light_energy = energy
	_light_energy = energy
	_light.omni_range = reach
	_light.position = Vector3.UP * 0.8
	add_child(_light)


## A flat ring on the ground (a torus squashed flat), `width` thick.
func _ring(radius: float, width: float) -> Mesh:
	var t := TorusMesh.new()
	t.inner_radius = radius - width
	t.outer_radius = radius
	t.rings = 24
	t.ring_segments = 6
	return t


## Little glowing motes that rise and fade.
func _motes(c: Color, n: int) -> void:
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.3, n, 1.5, 5.0, 0.6, 1.1, Color(c.r * 1.6, c.g * 1.6, c.b * 1.6))


func _physics_process(delta: float) -> void:
	_t += delta
	_update(delta)
	if _t >= _life:
		queue_free()


func _update(_delta: float) -> void:
	var k := clampf(_t / _life, 0.0, 1.0) if _life < INF else 0.0
	var fade := 1.0 - k
	match kind:
		"harvest":
			_mesh.scale = Vector3(1, 0.4, 1) * (0.5 + k * PlayerItems.HARVEST_RADIUS)
			_mesh.position.y = 0.1
		"ruin":
			_mesh.scale = Vector3.ONE * (0.4 + PlayerItems.RUIN_RADIUS * sqrt(k))
		"dream":
			_mesh.scale = Vector3(1, 0.4, 1) * (0.6 + k * 1.4)
			_mesh.position.y = 0.1 + k * 2.6
			_mesh.rotation.y = _t * 2.0
		"gale":
			_mesh.scale = Vector3(1, 0.5, 1) * (1.6 - k)
			_mesh.position.y = 0.2 + k * 2.2
			_mesh.rotation.y = _t * 9.0
		"gale_point":
			var pulse := 0.85 + sin(_t * 3.0) * 0.15
			_mesh.scale = Vector3(pulse, 0.5, pulse)
			_mesh.position.y = 0.1 + fmod(_t * 0.8, 1.0) * 1.2
			_mesh.rotation.y = _t * 4.0
			fade = 0.55 * (1.0 - fmod(_t * 0.8, 1.0))
		"flash":
			_mesh.scale = Vector3.ONE * (0.3 + k * PuffNut.BURST_RADIUS * 0.6)
		"quake":
			_mesh.scale = Vector3(1, 0.3, 1) * (0.4 + k * PlayerItems.MALLET_QUAKE)
		"sun":
			_mesh.scale = Vector3.ONE * (0.2 + k * 1.6)
		"steam":
			_mesh.scale = Vector3(1.0, 0.7, 1.0) * (0.6 + k * 1.6)
			_mesh.position.y = 0.4 + k * 2.4
		"stars":
			_mesh.rotation.y = _t * 5.0
			fade = 1.0
		"ice":
			_mesh.scale = size
			_mesh.position.y = size.y * 0.5
			fade = 1.0
	# The blast's shell swallows the camera: keep it faint from inside.
	var strength := 0.8
	match kind:
		"quake": strength = 0.6
		"ruin": strength = 0.3
	_mat.albedo_color = Color(_colour, _colour.a * fade * strength)
	if _light:
		_light.light_energy = _light_energy * fade
