extends Node
## Promo picture: Himeko and Mira at the end of Mira's dock on Mirror Lake at
## dusk. Mira fishes, watching her float, none the wiser; Himeko stands just
## behind her, turned away with her nose in the air, and can't help sneaking
## a look back at her, blushing. Run windowed (needs a GPU):
##   Godot --path <project> res://tools/render_himeko_mira.tscn -- --out=<png> [--aspect=portrait] [--scale=1] [--pose=laugh|pout]
## The lake is the real area, graded with the Mira title scene's dusk.

const ASPECTS := {
	"landscape": {"size": Vector2i(1920, 1080), "fov": 36.0, "eye": Vector3(-1.75, 0.85, 3.1), "at": Vector3(0.3, 1.02, -0.35)},
	"portrait": {"size": Vector2i(1080, 1920), "fov": 52.0, "eye": Vector3(-1.45, 0.8, 2.6), "at": Vector3(0.28, 1.05, -0.35)},
}

const MIRA := "res://assets/models/mira.tscn"
const HIMEKO := "res://assets/models/himeko.tscn"
const ROD := "res://assets/models/fishing_rod_mesh.tres"
const FLOAT := "res://assets/models/fishing_float_mesh.tres"

var _args := {}
## The scene's own space: origin at Mira's seat, +Z the way she faces (out
## over the lake, south), +X to her right... seen from the world.
var _stage: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var f: Dictionary = ASPECTS[_args.get("aspect", "landscape")]
	var size := Vector2i(Vector2(f.size) * float(_args.get("scale", "1")))
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var area := (load("res://scenes/areas/lake.tscn") as PackedScene).instantiate() as Node3D
	area.process_mode = Node.PROCESS_MODE_DISABLED
	vp.add_child(area)
	for n in area.find_children("*", "", true, false):
		if n.scene_file_path.contains("/enemies/") or n.scene_file_path.contains("/npc"):
			n.queue_free()
	# The dusk of Mira's title scene: its grade, low sun, stars and first star.
	var was: Node3D = World.area_node
	World.area_node = area
	var ts := TitleMira.new()
	add_child(ts)
	ts._grade(TitleMira.DUSK)
	ts._sky_disc(TitleMira.SUN.x, TitleMira.SUN.y, 9.0, Color(1.0, 0.86, 0.6), Color(1.0, 0.6, 0.35, 0.55))
	ts._stars(70, 30.0, 21)
	ts._sky_disc(TitleMira.STAR.x, TitleMira.STAR.y, 1.4, Color(1.0, 0.98, 0.9), Color(0.9, 0.9, 1.0, 0.6))
	World.area_node = was
	await get_tree().physics_frame
	await get_tree().physics_frame
	var seat := Vector3(TitleMira.SEAT.x, 0.0, TitleMira.SEAT.y)
	var q := PhysicsRayQueryParameters3D.create(seat + Vector3.UP * 4.0, seat + Vector3.DOWN * 4.0)
	var hit := vp.find_world_3d().direct_space_state.intersect_ray(q)
	seat.y = float(hit.position.y) if not hit.is_empty() else 0.7
	_stage = Node3D.new()
	vp.add_child(_stage)
	_stage.global_position = seat
	# Mira faces the lake, +Z of the world (TitleMira.FACING).
	_stage.rotation.y = 0.0
	var mira := _model(MIRA, Vector3.ZERO, 180.0, "sit_fish", 1.0)
	var hand_r := mira.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	if hand_r:
		var rod := MeshInstance3D.new()
		rod.mesh = load(ROD)
		rod.position = Vector3(0, -0.08, 0)
		# Swung out over the water, clear of Himeko (degrees about the fist).
		rod.rotation_degrees = Vector3(float(_args.get("rod_x", "0")), float(_args.get("rod_y", "-40")), float(_args.get("rod_z", "0")))
		hand_r.add_child(rod)
	var flt := MeshInstance3D.new()
	flt.mesh = load(FLOAT)
	_stage.add_child(flt)
	flt.global_position = Vector3(seat.x - 0.55, 0.0, seat.z + 2.7)
	# Himeko just behind her and to her left, turned away from her (facing
	# out to the east, toward us), with her head turned back over her
	# shoulder to steal a look at Mira.
	var pose: String = _args.get("pose", "laugh")
	var hime := _model(HIMEKO, Vector3(0.75, 0.0, -0.55), float(_args.get("yaw", "-66")), pose, 0.6 if pose == "laugh" else 1.0)
	if hime.has_method("set_blush"):
		hime.call("set_blush", true)
	var head := hime.get_node_or_null("Hips/Torso/Head") as Node3D
	if head:
		_look(head, mira.global_position + Vector3(0, 0.75, 0), float(_args.get("chin", "-8")), float(_args.get("turn", "0.7")))
	_sparkles(hime)
	var cam := Camera3D.new()
	cam.fov = f.fov
	cam.far = 900.0
	_stage.add_child(cam)
	cam.look_at_from_position(_stage.to_global(f.eye), _stage.to_global(f.at), Vector3.UP)
	cam.current = true
	for i in 40:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var out: String = _args.get("out", "res://promo/himeko_and_mira.png")
	print("render_himeko_mira: -> %s (%s)" % [out, error_string(img.save_png(out))])
	get_tree().quit()


func _model(path: String, at: Vector3, yaw: float, anim: String, time: float) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	_stage.add_child(m)
	m.position = at
	m.rotation_degrees.y = yaw
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		ap.play(anim)
		ap.seek(time, true)
		ap.pause()
	m.process_mode = Node.PROCESS_MODE_DISABLED
	return m


## Turns the head (face along -Z) `turn` of the way toward `point` (a
## sidelong look, not a stare), then tips the chin up by `chin` degrees
## (negative = up: haughty even while she looks).
func _look(head: Node3D, point: Vector3, chin: float, turn := 1.0) -> void:
	var rest := head.rotation
	var best := INF
	var keep := head.rotation
	for x in range(-40, 41, 2):
		for y in range(-130, 131, 2):
			head.rotation = Vector3(deg_to_rad(x), deg_to_rad(y), 0)
			var fwd := -head.global_basis.z.normalized()
			var c := 1.0 - fwd.dot((point - head.global_position).normalized())
			if c < best:
				best = c
				keep = head.rotation
	keep = rest.lerp(keep, turn)
	keep.x += deg_to_rad(chin)
	head.rotation = keep


## A few soft pink sparkles about her: the feeling she won't admit to.
func _sparkles(hime: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var head := hime.get_node_or_null("Hips/Torso/Head") as Node3D
	var c: Vector3 = head.global_position if head else hime.global_position + Vector3.UP * 1.5
	var to_cam := Vector3(-0.5, 0.1, 0.86).normalized()
	for i in 9:
		var p := c + Vector3(rng.randf_range(-0.45, 0.35), rng.randf_range(-0.15, 0.35), rng.randf_range(-0.3, 0.3))
		var s := rng.randf_range(0.018, 0.04)
		var col := Color(1.0, 0.72, 0.86, rng.randf_range(0.6, 0.95))
		TitleScene._disc(st, p, to_cam, s * 2.6, Color(col, col.a * 0.35), Color(col, 0.0))
		# A four-pointed twinkle.
		var b := TitleScene._basis_for(to_cam)
		for ax in [b.x, b.y]:
			var w: Vector3 = (b.y if ax == b.x else b.x) * s * 0.18
			for v in [p - ax * s, p + w, p + ax * s, p - ax * s, p + ax * s, p - w]:
				st.set_color(col)
				st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.get_parent().add_child(mi)
