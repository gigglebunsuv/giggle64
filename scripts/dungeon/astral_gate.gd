class_name AstralGate
extends Area3D
## A ring of starlight in the Astral Rift (Beta 1.5.0) that carries the hero
## from one drift of memory islands to another, far across the starless dark
## of the same area: step into it and a white flash sets him down at the
## Marker3D named `target`. Dark and cold until `need_flag` is set (a star
## lock lit); then it wakes with a chime.

@export var target := ""
@export var need_flag := ""
## Shown when the hero touches it while it sleeps.
@export var asleep_text := ""

var _ring: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D
var _busy := false
var _awake := false
var _told := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(_on_body)
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.25
	torus.outer_radius = 1.45
	torus.rings = 28
	torus.ring_segments = 8
	_ring.mesh = torus
	_ring.rotation.x = PI / 2.0
	_ring.position = Vector3.UP * 1.6
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.disable_fog = true
	_ring.material_override = _mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_light = OmniLight3D.new()
	_light.position = Vector3.UP * 1.6
	_light.omni_range = 6.0
	_light.light_color = Color(0.75, 0.75, 1.0)
	add_child(_light)
	_awake = need_flag == "" or Progress.flag(need_flag)
	_look()
	Progress.changed.connect(_on_progress)


func _on_progress() -> void:
	if not _awake and (need_flag == "" or Progress.flag(need_flag)):
		_awake = true
		_look()
		Sfx.play("goddess_chime", -6.0, 0.0, 1.2)


func _look() -> void:
	_mat.albedo_color = Color(0.85, 0.88, 1.0) if _awake else Color(0.18, 0.18, 0.26)
	_light.light_energy = 1.6 if _awake else 0.0


func _process(delta: float) -> void:
	_t += delta
	_ring.rotation.z = _t * (0.8 if _awake else 0.1)
	if _awake:
		_ring.scale = Vector3.ONE * (1.0 + sin(_t * 2.5) * 0.04)


func _on_body(body: Node3D) -> void:
	var p := body as PlayerController
	if p == null or _busy or p.is_dead() or Cutscene.active or World.transitioning:
		return
	if not _awake:
		if not _told and asleep_text != "":
			_told = true
			p.begin_talk(null)
			Dialogue.start([asleep_text], null)
			await Dialogue.finished
			if is_instance_valid(p):
				p.end_talk()
		return
	var to := World.area_node.find_child(target, true, false) as Node3D if is_instance_valid(World.area_node) else null
	if to == null:
		return
	_busy = true
	Sfx.play("warp", -2.0, 0.0, 1.2)
	p.begin_cutscene()
	Story._flash(Color(0.9, 0.92, 1.0, 1.0), 0.25, 0.7)
	await get_tree().create_timer(0.25, false).timeout
	if is_instance_valid(p):
		p.global_position = to.global_position
		p.face_direction(-to.global_basis.z)
		p.velocity = Vector3.ZERO
		p.set_respawn(to.global_transform)
		if p.camera_rig:
			p.camera_rig.snap_behind_target()
		p.end_cutscene()
	await get_tree().create_timer(1.0, false).timeout
	_busy = false
