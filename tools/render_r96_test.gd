extends Node
## Side-by-side check of the R96Kit remaster: game model (left) vs remastered
## (right). Windowed:
##   Godot --path <project> res://tools/render_r96_test.tscn -- --model=sir_gigglebuns --out=<png> [--yaw=20] [--focus=head]

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	R96Poster.no_n64_mode(get_tree())
	R96Poster.load_hd_faces()
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 1200)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var path := "res://assets/models/%s.tscn" % _args.get("model", "sir_gigglebuns")
	var yaw := float(_args.get("yaw", "20"))
	var models: Array[Node3D] = []
	for i in 2:
		var m := (load(path) as PackedScene).instantiate() as Node3D
		vp.add_child(m)
		m.position = Vector3(-0.6 + 1.2 * i, 0, 0)
		m.rotation_degrees.y = 180.0 + yaw
		if m.has_method("set_gear") and _args.has("sword"):
			m.call("set_gear", _args.sword, _args.get("shield", "questlord"))
			m.call("set_sword_drawn", true)
		var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			ap.play(_args.get("anim", "idle"))
			ap.seek(0.3, true)
			ap.pause()
		m.process_mode = Node.PROCESS_MODE_DISABLED
		models.append(m)
	var t0 := Time.get_ticks_msec()
	R96Detail.apply(_args.get("hair", ""), models[1])
	R96Kit.remaster(models[1], int(_args.get("levels", "2")), 0.5, _args.get("hair", ""))
	print("remaster: %d ms" % (Time.get_ticks_msec() - t0))
	for n in models[1].find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mt := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mt and mt.albedo_texture:
				print(mi.name, " tex ", mt.albedo_texture, " ", mt.albedo_texture.get_size(), " filter ", mt.texture_filter)
				RenderingServer.texture_2d_get(mt.albedo_texture.get_rid()).save_png("G:/Games/Godot Games/_giggle64_work/r96/test/gpu_tex.png")
				if _args.has("checker"):
					var ci := Image.create(1024, 1024, false, Image.FORMAT_RGB8)
					for y in 1024:
						for x in 1024:
							ci.set_pixel(x, y, Color.WHITE if ((x / 16) + (y / 16)) % 2 == 0 else Color.BLACK)
					mt.albedo_texture = ImageTexture.create_from_image(ci)
				if _args.has("plain"):
					var pm := StandardMaterial3D.new()
					pm.albedo_texture = mt.albedo_texture
					pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
					if _args.has("unshaded"):
						pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
						pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					mi.mesh.surface_set_material(s, pm)
				if _args.has("red"):
					mt.albedo_texture = null
					mt.albedo_color = Color.RED
				print("  override=", mi.material_override, " surf_ov=", mi.get_surface_override_material(s), " shader=", mt.get_rid())
	R96Poster.studio_lights(vp, Color(0.32, 0.34, 0.4))
	if _args.has("back"):
		models[1].rotation_degrees.y = yaw
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.current = true
	cam.fov = 30.0
	if _args.get("focus", "") == "face":
		var h := models[1].find_child("Head", true, false) as Node3D
		var p := h.global_position + Vector3(0, 0.16, 0)
		cam.fov = 7.0
		models[0].free()
		cam.look_at_from_position(p + Vector3(0, 0, 3.2), p, Vector3.UP)
	elif _args.get("focus", "") == "head":
		var h := models[1].find_child("Head", true, false) as Node3D
		var y := h.global_position.y + 0.17
		cam.fov = 22.0
		cam.look_at_from_position(Vector3(0, y, 3.2), Vector3(0, y, 0), Vector3.UP)
	else:
		cam.look_at_from_position(Vector3(0, 1.0, 4.6), Vector3(0, 0.95, 0), Vector3.UP)
	if _args.has("quad"):
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 0.5)
		q.mesh = qm
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.albedo_texture = R96Kit.hd_faces["face_mira"]
		q.material_override = sm
		vp.add_child(q)
		q.global_position = cam.global_position + (-cam.global_basis.z) * 2.5
		q.look_at(cam.global_position, Vector3.UP, true)
	for i in 8:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(_args.get("out", "user://r96_test.png"))
	get_tree().quit()
