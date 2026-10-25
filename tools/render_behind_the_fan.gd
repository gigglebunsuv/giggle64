extends Node
## Promo poster: "Behind the Fan". Himeko and Mira at the end of Mira's dock
## on Mirror Lake, the low sun right behind them. Mira's rod lies forgotten on
## the boards, its float still out on the water. Their foreheads touch and
## Himeko holds her open fan up over their lips, hiding the kiss from the
## world; Mira has one hand behind her back, the other on Himeko's wrist, and
## one foot kicked up. Both have their eyes shut and their cheeks pink
## (poster-only face paint over their own faces). Sakura petals from Himeko's
## palace, hearts and fireflies drift around them. Run windowed (needs a GPU):
##   Godot --path <project> res://tools/render_behind_the_fan.tscn -- --out=<png> [--aspect=poster|portrait|landscape] [--scale=1] [--card=0]
## Poster is 2:3 (1200x1800, --scale=2 for print), portrait 9:16, landscape 16:9.
## The lake is the real area, graded with the Mira title scene's dusk.

const ASPECTS := {
	# 2:3, a print poster.
	"poster": {"size": Vector2i(1200, 1800), "card_scale": 4, "glyph": 1, "fov": 44.0,
		"eye": Vector3(0.1, 0.95, -3.15), "at": Vector3(0.0, 1.12, 0.0)},
	"portrait": {"size": Vector2i(1080, 1920), "card_scale": 4, "glyph": 1, "fov": 48.0,
		"eye": Vector3(0.1, 0.95, -3.2), "at": Vector3(0.0, 1.15, 0.0)},
	"landscape": {"size": Vector2i(1920, 1080), "card_scale": 3, "glyph": 2, "fov": 34.0,
		"eye": Vector3(0.08, 1.25, -3.6), "at": Vector3(0.0, 1.42, 0.0)},
}

const MIRA := "res://assets/models/mira.tscn"
const HIMEKO := "res://assets/models/himeko.tscn"
const ROD := "res://assets/models/fishing_rod_mesh.tres"
const FLOAT := "res://assets/models/fishing_float_mesh.tres"
const SAKURA := Color("ffc8d8")
const SAKURA_D := Color("f08aa8")

var _args := {}
## The scene's own space: origin on the boards at Mira's feet, +Z out over the
## lake (south, toward the low sun), +X toward Himeko.
var _stage: Node3D
var _cam_pos := Vector3.ZERO


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var f: Dictionary = ASPECTS[_args.get("aspect", "poster")]
	var scale := float(_args.get("scale", "1"))
	var size := Vector2i(Vector2(f.size) * scale)
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
	var was: Node3D = World.area_node
	World.area_node = area
	var ts := TitleMira.new()
	add_child(ts)
	ts._grade(TitleMira.DUSK)
	ts._sky_disc(TitleMira.SUN.x, TitleMira.SUN.y, 9.0, Color(1.0, 0.86, 0.6), Color(1.0, 0.6, 0.35, 0.55))
	ts._stars(90, 26.0, 21)
	ts._sky_disc(TitleMira.STAR.x, TitleMira.STAR.y, 1.4, Color(1.0, 0.98, 0.9), Color(0.9, 0.9, 1.0, 0.6))
	World.area_node = was
	for i in 6:
		await get_tree().physics_frame
	var seat := Vector3(TitleMira.SEAT.x + float(_args.get("dx", "0")), 0.0, TitleMira.SEAT.y + float(_args.get("dz", "-0.4")))
	var q := PhysicsRayQueryParameters3D.create(seat + Vector3.UP * 4.0, seat + Vector3.DOWN * 4.0)
	var hit := vp.find_world_3d().direct_space_state.intersect_ray(q)
	seat.y = float(hit.position.y) if not hit.is_empty() else 0.7
	_stage = Node3D.new()
	vp.add_child(_stage)
	_stage.global_position = seat
	_stage.rotation_degrees.y = 180.0 - TitleMira.SUN.x + float(_args.get("turn", "6"))
	print("seat %s (hit: %s)" % [seat, not hit.is_empty()])

	# The islet tree (lake.gd ISLETS[1] + (1, -1)) stands right under the low
	# sun, just behind their heads: take it out of the scenery.
	_fell_tree(area, Vector2(-8.0, -10.0))
	_cam_pos = _stage.to_global(Vector3(0.2, 0, 0) + f.eye)
	# Mira faces +X (toward Himeko), Himeko faces -X.
	var mira := _model(MIRA, Vector3.ZERO, -90.0, "idle", 0.0)
	var hime := _model(HIMEKO, Vector3(0.42, 0.0, 0.0), 90.0, "idle", float(_args.get("flutter", "0.2")))
	_soft_face(mira, "face_mira", true)
	_soft_face(hime, "face_himeko", false)
	_pose_mira(mira)
	_lean(mira, float(_args.get("mira_lean", "4")))
	_lean(hime, float(_args.get("hime_lean", "6")))
	# Close the gap until their foreheads touch.
	for i in 3:
		_aim_heads(mira, hime)
		var d := _stage.to_local(_head_center(hime)) - _stage.to_local(_head_center(mira))
		hime.position.x -= d.x - float(_args.get("touch", "0.22"))
	_aim_heads(mira, hime)
	# Himeko's fan held up in front of them over their lips, its face to us,
	# and Mira's near hand laid over Himeko's wrist.
	var mid0 := (_head_center(mira) + _head_center(hime)) * 0.5
	var to_cam := _cam_pos - mid0
	to_cam.y = 0.0
	to_cam = to_cam.normalized()
	var toward_mira := _fwd(hime)
	var hand_at := mid0 + Vector3.DOWN * float(_args.get("fan_drop", "0.4")) + to_cam * float(_args.get("fan_out", "0.16")) - toward_mira * float(_args.get("fan_side", "0.02"))
	_reach(hime, "R", hand_at, Vector3.DOWN * 0.35 + to_cam * 0.15)
	var fan := _joint(hime, "ShoulderR/ElbowR/HandR/Fan")
	if fan:
		var up := (Vector3.UP - toward_mira * float(_args.get("fan_tip", "0.45"))).normalized()
		var y := -up
		var x := y.cross(to_cam).normalized()
		var z := x.cross(y).normalized()
		var hinge := fan.global_position + to_cam * 0.03
		fan.global_transform = Transform3D(Basis(x, y, z).scaled(Vector3.ONE * float(_args.get("fan_size", "1.25"))), hinge)
	var wrist := _joint(hime, "ShoulderR/ElbowR/HandR")
	var elbow := _joint(hime, "ShoulderR/ElbowR")
	var hold := wrist.global_position + (elbow.global_position - wrist.global_position).normalized() * 0.07 + to_cam * 0.04
	_reach(mira, "L", hold, Vector3.DOWN * 0.3 + to_cam * 0.1)
	var mid := (_head_center(mira) + _head_center(hime)) * 0.5
	var mid_at := _stage.to_local(mid)
	_cam_pos = _stage.to_global(Vector3(mid_at.x, 0, 0) + f.eye)
	print("faces: mira %s hime %s" % [_stage.to_local(_head_center(mira)), _stage.to_local(_head_center(hime))])

	# A soft rosy fill from our side: the sun is behind them.
	var fill := OmniLight3D.new()
	fill.light_color = Color(1.0, 0.8, 0.84)
	fill.light_energy = float(_args.get("fill", "0.7"))
	fill.omni_range = 3.0
	fill.shadow_enabled = false
	_stage.add_child(fill)
	var to_us := _cam_pos - mid
	to_us.y = 0.0
	fill.global_position = mid + to_us.normalized() * 1.1 + Vector3.UP * 0.25
	_props()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_args.get("seed", "14"))
	_hearts(mid, rng)
	_petals(mid, rng)
	_fireflies(mid, rng)

	var cam := Camera3D.new()
	cam.fov = f.fov
	cam.far = 900.0
	_stage.add_child(cam)
	cam.look_at_from_position(_cam_pos, _stage.to_global(Vector3(mid_at.x, 0, 0) + f.at), Vector3.UP)
	cam.current = true
	var card_vp: SubViewport = null
	if _args.get("card", "1") != "0":
		card_vp = SubViewport.new()
		card_vp.size = Vector2i(f.size.x / f.card_scale, f.size.y / f.card_scale)
		card_vp.transparent_bg = true
		card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(card_vp)
		var card := TitleCard.new()
		card.glyph = f.glyph
		card.size = Vector2(card_vp.size)
		card_vp.add_child(card)
	for i in 40:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	if card_vp:
		var over := card_vp.get_texture().get_image()
		over.convert(Image.FORMAT_RGBA8)
		over.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		img.blend_rect(over, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	img.convert(Image.FORMAT_RGB8)
	var out: String = _args.get("out", "res://promo/behind_the_fan.png")
	print("render_behind_the_fan: -> %s (%s)" % [out, error_string(img.save_png(out))])
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


func _joint(m: Node3D, path: String) -> Node3D:
	return m.get_node_or_null("Hips/Torso/" + path) as Node3D


## The middle of the face: the head's own axis, a little under the crown (the
## head mesh's box takes in long hair, so its center sits too low).
func _head_center(m: Node3D) -> Vector3:
	var head := _joint(m, "Head")
	var mi := m.get_node_or_null("Hips/Torso/Head/HeadMesh") as MeshInstance3D
	var top := 0.24
	if mi:
		top = (mi.transform * mi.get_aabb().end).y
	return head.global_transform * Vector3(0, top - float(_args.get("face_down", "0.12")), 0)


## The model's own forward (-Z), in the world.
func _fwd(m: Node3D) -> Vector3:
	return -m.global_basis.z.normalized()


# --- Posing ----------------------------------------------------------------------------

## Her far (right) hand behind her back and her near (left) foot kicked up
## behind her. The near hand is placed later, on Himeko's wrist.
func _pose_mira(m: Node3D) -> void:
	var hips := m.get_node("Hips") as Node3D
	var back := -_fwd(m)
	var right := m.global_basis.x.normalized()
	var at := hips.global_position + back * 0.13
	_reach(m, "R", at + right * 0.04, back * 0.4 + right * 0.3 + Vector3.DOWN * 0.1)
	# The knee bends whichever way carries the foot back and up.
	var knee := m.get_node_or_null("Hips/LegL/KneeL") as Node3D
	var leg := m.get_node_or_null("Hips/LegL") as Node3D
	var foot := m.get_node_or_null("Hips/LegL/KneeL/FootL") as Node3D
	if knee and foot and leg:
		var best := -INF
		var keep := 0.0
		for s in [-1.0, 1.0]:
			knee.rotation_degrees.x = s * float(_args.get("pop", "80"))
			var score := (foot.global_position - hips.global_position).dot(back)
			if score > best:
				best = score
				keep = knee.rotation_degrees.x
		knee.rotation_degrees.x = keep
		leg.rotation_degrees.x = -signf(keep) * 8.0


## Leans the upper body forward from the waist by `deg`.
func _lean(m: Node3D, deg: float) -> void:
	var torso := m.get_node("Hips/Torso") as Node3D
	var head := _joint(m, "Head")
	var rest := torso.rotation
	var before := head.global_position
	torso.rotation.x = rest.x + deg_to_rad(deg)
	if (head.global_position - before).dot(_fwd(m)) < 0.0:
		torso.rotation.x = rest.x - deg_to_rad(deg)


func _aim_heads(mira: Node3D, hime: Node3D) -> void:
	# Both heads bowed a little so their foreheads meet, Himeko's more (she
	# is the taller, just), and tipped a touch to the side.
	_nod(_joint(mira, "Head"), -float(_args.get("mira_down", "4")), float(_args.get("mira_roll", "-5")), float(_args.get("mira_yaw", "6")))
	_nod(_joint(hime, "Head"), -float(_args.get("hime_down", "10")), float(_args.get("hime_roll", "6")), float(_args.get("hime_yaw", "16")))


## Sets the head's pitch (degrees, up +), its roll, and a turn of `yaw`
## degrees toward the camera, so the face shows a little more.
func _nod(head: Node3D, up: float, roll: float, yaw := 0.0) -> void:
	head.rotation = Vector3(deg_to_rad(up), 0, 0)
	if (-head.global_basis.z).y * up < 0.0:
		head.rotation.x = -head.rotation.x
	var pitch := head.rotation.x
	var best := -INF
	var best_yaw := 0.0
	for sgn in [-1.0, 1.0]:
		head.rotation = Vector3(pitch, deg_to_rad(yaw) * sgn, 0)
		var face := (-head.global_basis.z).dot((_cam_pos - head.global_position).normalized())
		if face > best:
			best = face
			best_yaw = head.rotation.y
	head.rotation = Vector3(pitch, best_yaw, deg_to_rad(roll))


## Two-bone reach: the shoulder (three axes) and elbow (bend about X) that put
## the hand at `target`, preferring the elbow out toward `pole` (an offset from
## the shoulder, in the world).
func _reach(m: Node3D, side: String, target: Vector3, pole := Vector3.ZERO) -> void:
	var sh := _joint(m, "Shoulder" + side)
	var el := _joint(m, "Shoulder%s/Elbow%s" % [side, side])
	var hd := _joint(m, "Shoulder%s/Elbow%s/Hand%s" % [side, side, side])
	if sh == null or el == null or hd == null:
		return
	var parent := (sh.get_parent() as Node3D).global_transform
	var pole_at := sh.global_position + pole
	var sp := sh.position
	var ep := el.position
	var hp := hd.position
	# Coordinate descent from a few starting poses, the step halving each pass.
	var best := INF
	var keep := Vector4.ZERO
	for seed_pose: Vector4 in [Vector4(sh.rotation_degrees.x, sh.rotation_degrees.y, sh.rotation_degrees.z, el.rotation_degrees.x),
			Vector4(0, 0, 0, 90), Vector4(60, 0, 0, 60), Vector4(-60, 0, 0, 60), Vector4(120, 0, 0, 30), Vector4(0, 40, 40, 90), Vector4(0, -40, -40, 90)]:
		var v := seed_pose
		var c := _arm_cost(parent, sp, ep, hp, v, target, pole_at)
		var step := 32.0
		while step >= 0.5:
			var moved := false
			for axis in 4:
				for sgn in [-1.0, 1.0]:
					var t := v
					t[axis] += sgn * step
					t.w = clampf(t.w, 0.0, 155.0)
					var k := _arm_cost(parent, sp, ep, hp, t, target, pole_at)
					if k < c:
						c = k
						v = t
						moved = true
			if not moved:
				step *= 0.5
		if c < best:
			best = c
			keep = v
	sh.rotation_degrees = Vector3(keep.x, keep.y, keep.z)
	el.rotation_degrees = Vector3(keep.w, 0, 0)


func _arm_cost(parent: Transform3D, sp: Vector3, ep: Vector3, hp: Vector3, v: Vector4, target: Vector3, pole_at: Vector3) -> float:
	var ts := parent * Transform3D(Basis.from_euler(Vector3(deg_to_rad(v.x), deg_to_rad(v.y), deg_to_rad(v.z))), sp)
	var te := ts * Transform3D(Basis.from_euler(Vector3(deg_to_rad(v.w), 0, 0)), ep)
	return (te * hp).distance_to(target) + 0.04 * te.origin.distance_to(pole_at)


## Strips one of the kit's round trees out of the merged scenery chunks: the
## trunk's triangles (all corners within half a meter of it) and the crown's
## (all corners within 3.4 m and well above the ground).
func _fell_tree(area: Node3D, at: Vector2) -> void:
	for n in area.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not (mi.global_transform * mi.get_aabb()).grow(1.0).has_point(Vector3(at.x, (mi.global_transform * mi.get_aabb()).get_center().y, at.y)):
			continue
		var out := ArrayMesh.new()
		var cut := 0
		for si in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(si)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.is_empty():
				idx.resize(verts.size())
				for i in verts.size():
					idx[i] = i
			var keep := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				var trunk := true
				var crown := true
				for k in 3:
					var v := mi.global_transform * verts[idx[t + k]]
					var d := Vector2(v.x, v.z).distance_to(at)
					trunk = trunk and d < 0.5
					crown = crown and d < 3.4 and v.y > 1.3
				if trunk or crown:
					cut += 1
				else:
					keep.append_array([idx[t], idx[t + 1], idx[t + 2]])
			arrays[Mesh.ARRAY_INDEX] = keep
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			out.surface_set_material(out.get_surface_count() - 1, mi.mesh.surface_get_material(si))
		if cut > 0:
			mi.mesh = out
			print("felled %d triangles in %s" % [cut, mi.name])


# --- The faces -------------------------------------------------------------------------

## Repaints the face texture for the poster: eyes shut, brows soft, blushing.
## The wraps are 64x64 with the front at x = 32, brows near row 21, eyes rows
## 23-30 and cheeks rows 31-34 (gen_media.gd).
func _soft_face(m: Node3D, tex_name: String, mira: bool) -> void:
	var src: Texture2D = load("res://assets/textures/%s.png" % tex_name)
	if src == null:
		return
	var img := src.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGB8)
	var skin := img.get_pixel(32, 27)
	var lash := Color("2a1410") if mira else Color("0e0a10")
	var hair_d := Color("7a321c") if mira else Color("0a090e")
	# Clear the open eyes (and Mira's frown).
	_pair(img, 1, 22 if mira else 23, 9, 9 if mira else 8, skin)
	if mira:
		# Soft, level brows instead of the stubborn little frown.
		_pair(img, 3, 21, 5, 1, hair_d)
	# Shut eyes: a gentle downward curve with the lashes flicking out.
	_pair(img, 2, 27, 1, 1, lash)
	_pair(img, 3, 28, 4, 1, lash)
	_pair(img, 7, 27, 1, 1, lash)
	_pair(img, 8, 26, 1, 1, lash)
	_pair(img, 9, 25, 1, 1, lash)
	if not mira:
		# Her long lower lashes.
		_pair(img, 4, 29, 2, 1, Color("2a1a20"))
	# Pinker cheeks than either would admit to.
	var blush := Color("f08c8c") if mira else Color("f4a0b0")
	_pair(img, 4, 31, 8, 3, skin.lerp(blush, 0.55))
	_pair(img, 5, 31, 6, 2, blush)
	_pair(img, 6, 31, 1, 1, Color("ffffff").lerp(blush, 0.4))
	var tex := ImageTexture.create_from_image(img)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var mat := mesh.surface_get_material(si) as StandardMaterial3D
			if mat and mat.albedo_texture and mat.albedo_texture.resource_path.contains(tex_name):
				var dup := mat.duplicate() as StandardMaterial3D
				dup.albedo_texture = tex
				(mi as MeshInstance3D).set_surface_override_material(si, dup)


func _pair(img: Image, dx: int, y: int, w: int, h: int, col: Color) -> void:
	img.fill_rect(Rect2i(32 + dx, y, w, h), col)
	img.fill_rect(Rect2i(32 - dx - w, y, w, h), col)


# --- Props and the air around them -----------------------------------------------------

## Mira's rod dropped on the boards, its float still out on the water.
func _props() -> void:
	var rod := MeshInstance3D.new()
	rod.mesh = load(ROD)
	_stage.add_child(rod)
	var at := _stage.to_global(Vector3(-0.55, 0.025, -0.35))
	var toward := _stage.to_global(Vector3(-0.1, 0.025, 1.0))
	rod.global_transform = Transform3D(Basis.IDENTITY, at).looking_at(toward, Vector3.UP)
	var flt := MeshInstance3D.new()
	flt.mesh = load(FLOAT)
	_stage.add_child(flt)
	var tip := rod.global_transform * Vector3(0, 0, -2.1)
	flt.global_position = Vector3(tip.x - 0.4, TitleMira.WATER_Y, tip.z + 2.2)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 13:
		var t := float(i) / 12.0
		var p := tip.lerp(flt.global_position, t) + Vector3.DOWN * sin(t * PI) * 0.25
		im.surface_add_vertex(p)
	im.surface_end()
	var line := MeshInstance3D.new()
	line.mesh = im
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.95, 0.9, 0.85, 0.7)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = lm
	_stage.get_parent().add_child(line)


func _fx_mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	return m


func _commit(st: SurfaceTool, m: Material) -> void:
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.get_parent().add_child(mi)


## A heart in the plane facing `n`, `size` across.
func _heart(st: SurfaceTool, c: Vector3, n: Vector3, size: float, col: Color, roll: float) -> void:
	var b := TitleScene._basis_for(n)
	var bx := b.x.rotated(n, roll)
	var by := b.y.rotated(n, roll)
	var pts: Array[Vector3] = []
	var seg := 28
	for i in seg:
		var t := TAU * float(i) / float(seg)
		var hx := pow(sin(t), 3.0)
		var hy := (13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) / 16.0
		pts.append(c + (bx * hx + by * (hy + 0.15)) * size * 0.5)
	var mid := c + by * 0.1 * size
	for i in seg:
		st.set_color(col)
		st.add_vertex(mid)
		st.set_color(col)
		st.add_vertex(pts[i])
		st.set_color(col)
		st.add_vertex(pts[(i + 1) % seg])


func _hearts(kiss: Vector3, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glow := SurfaceTool.new()
	glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	var right := (_cam_pos - kiss).normalized().cross(Vector3.UP).normalized()
	# Rising up out of the kiss in a loose column, small to large.
	var count := int(_args.get("hearts", "7"))
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var p := kiss + Vector3.UP * (0.24 + t * 0.62) + right * (sin(t * 5.0 + 0.6) * 0.16 + rng.randf_range(-0.05, 0.05))
		p += (_cam_pos - p).normalized() * 0.1
		var n := (_cam_pos - p).normalized()
		var s := lerpf(0.05, 0.13, t) * rng.randf_range(0.85, 1.15)
		var col := Color("ff6f9a").lerp(Color("ffb3c8"), rng.randf())
		_heart(st, p, n, s, col, rng.randf_range(-0.35, 0.35))
		TitleScene._disc(glow, p - n * 0.005, n, s * 1.3, Color(1.0, 0.6, 0.75, 0.45), Color(1.0, 0.6, 0.75, 0.0))
	_commit(glow, _fx_mat(true))
	_commit(st, _fx_mat(false))
	# Twinkles about their heads.
	var tw := SurfaceTool.new()
	tw.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 11:
		var p := kiss + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.15, 0.55), rng.randf_range(-0.3, 0.3))
		var n := (_cam_pos - p).normalized()
		var s := rng.randf_range(0.018, 0.04)
		var col := Color(1.0, 0.85, 0.92, rng.randf_range(0.6, 0.95))
		TitleScene._disc(tw, p, n, s * 2.6, Color(col, col.a * 0.35), Color(col, 0.0))
		var b := TitleScene._basis_for(n)
		for ax in [b.x, b.y]:
			var w: Vector3 = (b.y if ax == b.x else b.x) * s * 0.18
			for v in [p - ax * s, p + w, p + ax * s, p - ax * s, p + ax * s, p - w]:
				tw.set_color(col)
				tw.add_vertex(v)
	_commit(tw, _fx_mat(true))


## Sakura petals adrift: little two-tone ovals at every angle.
func _petals(kiss: Vector3, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in int(_args.get("petals", "60")):
		var p := kiss + Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(-1.1, 1.3), rng.randf_range(-1.2, 2.0))
		var n := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var b := TitleScene._basis_for(n)
		var l := rng.randf_range(0.022, 0.036)
		var w := l * 0.6
		var col := SAKURA.lerp(Color.WHITE, rng.randf() * 0.4)
		var seg := 8
		for k in seg:
			var a0 := TAU * float(k) / seg
			var a1 := TAU * float(k + 1) / seg
			# A notch at the petal's tip.
			var r0 := 1.0 - 0.3 * maxf(cos(a0), 0.0) ** 8
			var r1 := 1.0 - 0.3 * maxf(cos(a1), 0.0) ** 8
			st.set_color(SAKURA_D)
			st.add_vertex(p)
			st.set_color(col)
			st.add_vertex(p + b.x * cos(a0) * l * r0 + b.y * sin(a0) * w)
			st.set_color(col)
			st.add_vertex(p + b.x * cos(a1) * l * r1 + b.y * sin(a1) * w)
	var m := _fx_mat(false)
	_commit(st, m)


## Fireflies over the boards and the water: soft yellow-green glows.
func _fireflies(kiss: Vector3, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in int(_args.get("flies", "26")):
		var p := kiss + Vector3(rng.randf_range(-1.8, 1.8), rng.randf_range(-1.2, 0.9), rng.randf_range(-0.8, 3.0))
		var n := (_cam_pos - p).normalized()
		var s := rng.randf_range(0.012, 0.022)
		TitleScene._disc(st, p, n, s * 4.0, Color(0.9, 1.0, 0.45, 0.35), Color(0.9, 1.0, 0.45, 0.0))
		TitleScene._disc(st, p, n, s, Color(1.0, 1.0, 0.8, 1.0), Color(0.9, 1.0, 0.5, 0.8))
	_commit(st, _fx_mat(true))


# --- The title card --------------------------------------------------------------------

## A dark band along the bottom with the title in the game's pixel font,
## between two thin rose rules with little hearts at their ends.
class TitleCard extends Control:
	const TEXT := "Himeko & Mira"
	var glyph := 1

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var u := float(glyph) * 0.5
		var band := 78.0 * u
		for i in int(band):
			var t := float(i) / band
			draw_rect(Rect2(0, h - band + i, w, 1), Color(0.06, 0.0, 0.05, minf(t * 1.6, 0.8)))
		var scale := glyph
		var tw := PixelFont.measure(TEXT, scale).x
		var x := floorf((w - tw) * 0.5)
		var y := floorf(h - 40.0 * u)
		var rule := tw * 0.5 + 14.0 * u
		var above := y - roundf(8.0 * u)
		var below := y + 7 * glyph + roundf(7.0 * u)
		var rose := Color(1.0, 0.78, 0.86, 0.95)
		draw_rect(Rect2(w * 0.5 - rule, above, rule * 2, 1), rose)
		draw_rect(Rect2(w * 0.5 - rule, below, rule * 2, 1), rose)
		# Little pixel hearts at the ends of the rules.
		var heart := [".#.#.", "#####", "#####", ".###.", "..#.."]
		for sx in [-1.0, 1.0]:
			var cx: float = w * 0.5 + (rule + 5.0) * sx
			for cy: float in [above, below]:
				for r in heart.size():
					for c in 5:
						if heart[r][c] == "#":
							draw_rect(Rect2(cx - 2 + c, cy - 2 + r, 1, 1), Color(1.0, 0.55, 0.72))
		PixelFont._draw_run(self, Vector2(x + scale, y + scale), TEXT, Color(0, 0, 0, 0.85), scale, true)
		PixelFont._draw_run(self, Vector2(x, y), TEXT, Color(1, 1, 1), scale, true)
