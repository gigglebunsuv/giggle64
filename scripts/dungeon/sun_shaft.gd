class_name SunShaft
extends Node3D
## A shaft of sunlight falling through a window or an oculus in Ladhellin
## Tower (OoT's Spirit Temple sunbeams). Standing in its pool with the Mirror
## Shield raised, the hero throws the light on along his shield (aimed with
## the stick while crouched behind it). With `beam` the shaft shines straight
## along its own -Z instead, with nobody holding it (light through a slit in
## the wall).
##
## The light bounces off standing mirrors (LightMirror), wakes sun switches
## (SunSwitch) and scorches whatever is weak to it: anything it touches that
## has light_hit(delta, dir) is told so every frame.

const MAX_BOUNCES := 6
const REACH := 40.0
const BEAM_WIDTH := 0.28
## Light thrown within this angle of a mirror or a sun face is drawn onto its
## middle, so it need not be aimed to the degree from across a room.
const ASSIST_ANGLE := deg_to_rad(12.0)

## The column of light comes down from this far above the pool.
@export var height := 7.0
@export var radius := 1.1
@export var beam := false
## It only shines once this flag is set ("" = always).
@export var flag := ""

## The light's path this frame as [from, to] pairs (for tests).
var segments: Array = []
var _column: MeshInstance3D
var _segs: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D
var _hum := 0.0


func _ready() -> void:
	add_to_group("sun_shafts")
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.albedo_color = Color(1.0, 0.86, 0.5, 0.55)
	_mat.disable_receive_shadows = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not beam:
		_column = MeshInstance3D.new()
		_column.name = "Column"
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius * 0.9
		cyl.bottom_radius = radius
		cyl.height = height
		cyl.radial_segments = 12
		cyl.cap_top = false
		cyl.cap_bottom = false
		var cm := _mat.duplicate() as StandardMaterial3D
		cm.albedo_color = Color(1.0, 0.85, 0.45, 0.22)
		cyl.material = cm
		_column.mesh = cyl
		_column.position = Vector3(0, height * 0.5, 0)
		_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_column)


func active() -> bool:
	return flag == "" or Progress.flag(flag)


## The hero stands in the pool with the Mirror Shield up.
func reflecting(p: PlayerController) -> bool:
	if p == null or p.is_dead() or not p.is_shielding():
		return false
	if not Equipment.guard().get("mirror", false):
		return false
	var d := p.global_position - global_position
	return Vector2(d.x, d.z).length() <= radius and absf(d.y) < 1.2


func _physics_process(delta: float) -> void:
	segments.clear()
	if _column:
		_column.visible = active()
	if not active():
		_draw()
		return
	var p := GameManager.player
	if beam:
		_trace(global_position, -global_basis.z, delta, p)
	elif reflecting(p):
		_trace(p.shield_point(), p.shield_beam_dir(), delta, p)
		_hum -= delta
		if _hum <= 0.0:
			_hum = 0.6
			Sfx.play("light_hum", -14.0, 0.05)
	_draw()


func _trace(origin: Vector3, dir: Vector3, delta: float, p: PlayerController) -> void:
	var from := origin
	var d := dir.normalized()
	var ex: Array[RID] = []
	if p:
		ex.append(p.get_rid())
		var hb := p.get_node_or_null("Hurtbox") as Area3D
		if hb:
			ex.append(hb.get_rid())
	var space := get_world_3d().direct_space_state
	for i in MAX_BOUNCES:
		d = _assist(from, d, ex, space)
		var q := PhysicsRayQueryParameters3D.create(from, from + d * REACH, 1 | 16)
		q.collide_with_areas = true
		q.exclude = ex
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			segments.append([from, from + d * REACH])
			return
		segments.append([from, hit.position])
		var target: Object = hit.collider
		if target is Hurtbox:
			target = (target as Hurtbox).receiver
		if target and target.has_method("light_hit"):
			target.light_hit(delta, d)
		if target is LightMirror:
			var nd: Vector3 = (target as LightMirror).reflect(d)
			if nd == Vector3.ZERO:
				return
			ex.append((target as CollisionObject3D).get_rid())
			# The light leaves from the middle of the mirror's face, whichever
			# part of it was struck.
			var mc := (target as Node3D).global_position
			from = Vector3(mc.x, hit.position.y, mc.z) + nd * 0.05
			segments[-1][1] = Vector3(mc.x, hit.position.y, mc.z)
			d = nd
			continue
		return


## The way to the nearest mirror or sun face (in plain sight) lying within
## ASSIST_ANGLE of `d`, or `d` itself if there is none.
func _assist(from: Vector3, d: Vector3, ex: Array[RID], space: PhysicsDirectSpaceState3D) -> Vector3:
	var best := d
	var best_angle := ASSIST_ANGLE
	for g in ["light_mirrors", "sun_switches"]:
		for t: Node3D in get_tree().get_nodes_in_group(g):
			if (t as CollisionObject3D).get_rid() in ex:
				continue
			if t is SunSwitch and (t as SunSwitch).on:
				continue
			var c := t.global_position + (Vector3.UP * 1.1 if t is LightMirror else Vector3.ZERO)
			var to := c - from
			if to.length() > REACH or to.length() < 0.3:
				continue
			var a := d.angle_to(to)
			if a >= best_angle:
				continue
			var q := PhysicsRayQueryParameters3D.create(from, c, 1 | 16)
			q.collide_with_areas = true
			q.exclude = ex
			var hit := space.intersect_ray(q)
			if hit.is_empty() or hit.collider != t:
				continue
			best = to.normalized()
			best_angle = a
	return best


func _draw() -> void:
	while _segs.size() < segments.size():
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(BEAM_WIDTH, BEAM_WIDTH, 1.0)
		box.material = _mat
		mi.mesh = box
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.top_level = true
		add_child(mi)
		_segs.append(mi)
	for i in _segs.size():
		var mi := _segs[i]
		if i >= segments.size():
			mi.visible = false
			continue
		var a: Vector3 = segments[i][0]
		var b: Vector3 = segments[i][1]
		var length := a.distance_to(b)
		if length < 0.01:
			mi.visible = false
			continue
		mi.visible = true
		var dir := (b - a) / length
		var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
		var basis := Basis.looking_at(dir, up).scaled(Vector3(1, 1, length))
		mi.global_transform = Transform3D(basis, (a + b) * 0.5)
