extends Node
## Renders a promo picture of Avalon, Keeper of the Stars, floating in the
## Astral Dimension, with her name card along the bottom in the game's pixel
## font. Run windowed (needs a GPU):
##   Godot --path <project> res://tools/render_avalon_scene.tscn -- --out=<png> [--scale=1] [--aspect=portrait]
## Landscape is 16:9 (1920x1080); portrait is 9:16 (1080x1920).

## Per aspect: picture size, card scale (the card is drawn small and blown up
## so its pixels are chunky like the game's), card glyph scale, and camera.
const FRAMES := {
	"landscape": {"size": Vector2i(1920, 1080), "card_scale": 3, "glyph": 2, "fov": 42.0,
		"eye": Vector3(0.3, 0.82, 3.4), "at": Vector3(0.0, 0.74, 0.0)},
	"portrait": {"size": Vector2i(1080, 1920), "card_scale": 5, "glyph": 1, "fov": 50.0,
		"eye": Vector3(0.25, 0.72, 3.05), "at": Vector3(0.0, 0.98, 0.0),
		# More shards, closer in, to fill the narrow frame.
		"shards": [Vector3(-0.95, 2.05, -1.0), Vector3(0.85, 1.75, -0.6), Vector3(-0.8, 0.55, -0.4),
			Vector3(0.95, 0.35, -1.0), Vector3(-0.6, 2.65, -2.0), Vector3(0.75, 2.6, -1.6),
			Vector3(-1.05, 1.35, -2.2), Vector3(1.15, 1.2, -2.4), Vector3(0.2, 2.9, -3.0)]},
}

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var f: Dictionary = FRAMES[_args.get("aspect", "landscape")]
	var scale := float(_args.get("scale", "1"))
	var size := Vector2i(Vector2(f.size) * scale)
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_build_realm(vp, f.get("shards", []))
	var model := (load("res://assets/models/avalon.tscn") as PackedScene).instantiate() as Node3D
	vp.add_child(model)
	model.rotation_degrees.y = 168.0
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play(_args.get("anim", "idle"))
	ap.seek(float(_args.get("time", "0.9")), true)
	ap.pause()
	model.process_mode = Node.PROCESS_MODE_DISABLED
	var cam := Camera3D.new()
	cam.fov = f.fov
	cam.far = 900.0
	vp.add_child(cam)
	cam.look_at_from_position(f.eye, f.at, Vector3.UP)
	cam.current = true
	# The name card, drawn in its own transparent viewport.
	var card_vp := SubViewport.new()
	card_vp.size = Vector2i(f.size.x / f.card_scale, f.size.y / f.card_scale)
	card_vp.transparent_bg = true
	card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(card_vp)
	var card := NameCard.new()
	card.glyph = f.glyph
	card.size = Vector2(card_vp.size)
	card_vp.add_child(card)
	for i in 30:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var over := card_vp.get_texture().get_image()
	over.convert(Image.FORMAT_RGBA8)
	over.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	img.blend_rect(over, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	img.convert(Image.FORMAT_RGB8)
	var out: String = _args.get("out", "user://avalon_keeper_of_the_stars.png")
	var err := img.save_png(out)
	print("render_avalon_scene: -> %s (%s)" % [out, error_string(err)])
	get_tree().quit()


# --- The Astral Dimension ------------------------------------------------------------

func _build_realm(vp: SubViewport, extra_shards: Array) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.015, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.58, 0.85)
	env.ambient_light_energy = 0.85
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 165, 0)
	key.light_color = Color(1.0, 0.96, 0.95)
	key.light_energy = 0.95
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, -20, 0)
	rim.light_color = Color(0.55, 0.7, 1.0)
	rim.light_energy = 1.1
	vp.add_child(rim)
	var under := OmniLight3D.new()
	under.position = Vector3(0, 0.25, 0.6)
	under.light_color = Color(0.7, 0.82, 1.0)
	under.light_energy = 0.45
	under.omni_range = 3.0
	vp.add_child(under)
	var rng := RandomNumberGenerator.new()
	rng.seed = 307
	vp.add_child(_sky(rng))
	vp.add_child(_halo())
	vp.add_child(_floor())
	vp.add_child(_shards(rng, extra_shards))
	vp.add_child(_motes(rng))


func _mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


func _mesh(st: SurfaceTool, m: Material, node_name: String) -> MeshInstance3D:
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 500.0
	return mi


func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	var z := rng.randf_range(-1.0, 1.0)
	var a := rng.randf() * TAU
	var r := sqrt(1.0 - z * z)
	return Vector3(r * cos(a), z, r * sin(a))


## Nebula clouds, a band of the starry river behind her, and thousands of stars.
func _sky(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Sky"
	const R := 120.0
	var clouds := SurfaceTool.new()
	clouds.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tints := [Color(0.42, 0.22, 0.72), Color(0.18, 0.32, 0.8), Color(0.62, 0.26, 0.6), Color(0.12, 0.5, 0.7), Color(0.3, 0.2, 0.6)]
	for i in 110:
		var d := _rand_dir(rng)
		# Most of the clouds gather behind her, in view of the camera.
		if i < 70:
			d = (Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(-0.5, 0.8), -1.0)).normalized()
		var col: Color = tints[i % tints.size()]
		col.a = rng.randf_range(0.1, 0.24)
		TitleScene._disc(clouds, d * (R + 6.0), -d, rng.randf_range(14.0, 34.0), col, Color(col, 0.0))
	# The starry river: a diagonal band of pale violet light.
	for i in 40:
		var t := float(i) / 39.0
		var d := Vector3(lerpf(-1.6, 1.6, t), lerpf(-0.35, 0.9, t) + rng.randf_range(-0.06, 0.06), -1.0).normalized()
		TitleScene._disc(clouds, d * (R + 4.0), -d, rng.randf_range(10.0, 16.0), Color(0.7, 0.62, 0.95, 0.12), Color(0.5, 0.4, 0.9, 0.0))
	root.add_child(_mesh(clouds, _mat(true), "Nebula"))
	var stars := SurfaceTool.new()
	stars.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3200:
		var d := _rand_dir(rng)
		if i < 1200:
			var t := rng.randf()
			d = Vector3(lerpf(-1.6, 1.6, t), lerpf(-0.35, 0.9, t) + rng.randf_range(-0.12, 0.12), -1.0).normalized()
		var c := Color(1.0, 0.95, 0.85).lerp(Color(0.72, 0.84, 1.0), rng.randf()) * rng.randf_range(0.5, 1.0)
		c.a = 1.0
		TitleScene._quad(stars, d * R, -d, rng.randf_range(0.1, 0.26) * (2.2 if rng.randf() < 0.04 else 1.0), c)
	root.add_child(_mesh(stars, _mat(false), "Stars"))
	# A few bright stars with four-pointed flares.
	var flares := SurfaceTool.new()
	flares.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 34:
		var d := (Vector3(rng.randf_range(-1.3, 1.3), rng.randf_range(-0.4, 0.75), -1.0)).normalized()
		var p := d * (R - 2.0)
		var b := TitleScene._basis_for(-d)
		var s := rng.randf_range(0.8, 2.2)
		var col := Color(0.9, 0.95, 1.0, 0.9)
		for ax in [b.x, b.y]:
			var w: Vector3 = (b.y if ax == b.x else b.x) * s * 0.06
			for v in [p - ax * s, p + w, p + ax * s, p - ax * s, p + ax * s, p - w]:
				flares.set_color(col)
				flares.add_vertex(v)
		TitleScene._disc(flares, p, -d, s * 0.35, Color(0.85, 0.9, 1.0, 0.6), Color(0.6, 0.7, 1.0, 0.0))
	root.add_child(_mesh(flares, _mat(true), "Flares"))
	return root


## A great soft ring of starlight behind her, like the light of hope.
func _halo() -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(0, 1.25, -2.4)
	TitleScene._disc(st, c, Vector3.BACK, 2.6, Color(0.5, 0.6, 1.0, 0.16), Color(0.4, 0.3, 0.9, 0.0))
	TitleScene._disc(st, c, Vector3.BACK, 1.0, Color(0.9, 0.94, 1.0, 0.1), Color(0.7, 0.8, 1.0, 0.0))
	var seg := 64
	for ring in [[1.55, 1.585, 0.4], [1.85, 1.865, 0.22]]:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var col := Color(0.8, 0.88, 1.0, ring[2])
			var p := [Vector3(cos(a0), sin(a0), 0), Vector3(cos(a1), sin(a1), 0)]
			var q := [c + p[0] * ring[0], c + p[1] * ring[0], c + p[1] * ring[1], c + p[0] * ring[1]]
			for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(col)
				st.add_vertex(v)
	# Eight long rays.
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0) * 0.025
		var tip := c + dir * (3.4 if i % 2 == 0 else 2.4)
		for v in [c + side, tip, c - side]:
			st.set_color(Color(0.8, 0.88, 1.0, 0.1))
			st.add_vertex(v)
	return _mesh(st, _mat(true), "Halo")


## The floor of light she floats over, ringed and marked with a star.
func _floor() -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	TitleScene._disc(st, Vector3(0, -0.02, 0), Vector3.UP, 2.6, Color(0.75, 0.82, 1.0, 0.45), Color(0.4, 0.4, 1.0, 0.0))
	var seg := 64
	for ring in [[1.6, 1.66], [1.15, 1.18], [2.2, 2.22]]:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p0 := Vector3(sin(a0), 0, cos(a0))
			var p1 := Vector3(sin(a1), 0, cos(a1))
			var q := [p0 * ring[0], p1 * ring[0], p1 * ring[1], p0 * ring[1]]
			for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(Color(0.85, 0.9, 1.0, 0.7))
				st.add_vertex(v + Vector3(0, 0.0, 0))
	for i in 10:
		var a := TAU * i / 10.0
		var tip := Vector3(sin(a), 0, cos(a)) * (1.55 if i % 2 == 0 else 1.15)
		var side := Vector3(cos(a), 0, -sin(a)) * 0.06
		for v in [side, tip, -side]:
			st.set_color(Color(0.85, 0.9, 1.0, 0.6))
			st.add_vertex(v + Vector3(0, 0.005, 0))
	return _mesh(st, _mat(true), "Floor")


## Shards of Cosmolite drifting in the void around her.
func _shards(rng: RandomNumberGenerator, extra: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "Shards"
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.emission_enabled = true
	m.emission = Color(0.25, 0.4, 0.9)
	m.emission_energy_multiplier = 0.8
	m.roughness = 0.25
	m.metallic_specular = 0.9
	var spots := [Vector3(-1.9, 1.9, -1.2), Vector3(1.8, 1.6, -0.9), Vector3(-1.4, 0.5, -0.5), Vector3(1.6, 0.4, -1.5),
		Vector3(-2.8, 1.2, -3.0), Vector3(2.7, 2.3, -3.2), Vector3(-0.9, 2.5, -2.6), Vector3(1.0, 2.7, -1.8),
		Vector3(-3.4, 2.6, -5.0), Vector3(3.6, 0.9, -4.5), Vector3(-2.2, -0.2, -2.4), Vector3(2.4, -0.1, -2.0)]
	spots.append_array(extra)
	for p: Vector3 in spots:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var h := rng.randf_range(0.14, 0.3)
		var w := h * rng.randf_range(0.3, 0.45)
		var top := Vector3(0, h, 0)
		var bot := Vector3(0, -h * 0.7, 0)
		var ring := []
		for i in 5:
			var a := TAU * i / 5.0
			ring.append(Vector3(cos(a) * w, rng.randf_range(-0.03, 0.03), sin(a) * w))
		for i in 5:
			var r0: Vector3 = ring[i]
			var r1: Vector3 = ring[(i + 1) % 5]
			var lit := Color(0.75, 0.88, 1.0).lerp(Color(0.45, 0.55, 0.95), float(i % 2) * 0.6)
			for tri in [[top, r0, r1], [bot, r1, r0]]:
				var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
				for v in tri:
					st.set_normal(-n)
					st.set_color(lit)
					st.add_vertex(v)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = m
		mi.position = p
		mi.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
		root.add_child(mi)
	return root


## Specks of starlight floating round her.
func _motes(rng: RandomNumberGenerator) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 160:
		var p := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-0.2, 3.0), rng.randf_range(-3.5, 1.5))
		if absf(p.x) < 0.5 and p.z > -0.6:
			continue
		var s := rng.randf_range(0.006, 0.02)
		var col := Color(0.85, 0.92, 1.0, rng.randf_range(0.5, 1.0))
		TitleScene._disc(st, p, Vector3(0.1, 0.2, 1.0).normalized(), s * 3.0, Color(col, col.a * 0.5), Color(col, 0.0))
		TitleScene._quad(st, p, Vector3(0.1, 0.2, 1.0).normalized(), s, col)
	return _mesh(st, _mat(true), "Motes")


# --- The name card --------------------------------------------------------------------

## A dark band along the bottom with her name across it, in the game's pixel
## font (the way area names are carded), between two thin silver rules.
class NameCard extends Control:
	const TEXT := "Avalon, Keeper of the Stars"
	## Glyph scale: everything on the card is laid out in units of it.
	var glyph := 2

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var u := float(glyph) * 0.5
		var band := 78.0 * u
		for i in int(band):
			var t := float(i) / band
			draw_rect(Rect2(0, h - band + i, w, 1), Color(0.0, 0.0, 0.03, minf(t * 1.6, 0.82)))
		var scale := glyph
		var tw := PixelFont.measure(TEXT, scale).x
		var x := floorf((w - tw) * 0.5)
		var y := floorf(h - 40.0 * u)
		var rule := tw * 0.5 + 14.0 * u
		var above := y - roundf(8.0 * u)
		var below := y + 7 * glyph + roundf(7.0 * u)
		var silver := Color(0.78, 0.86, 1.0, 0.9)
		draw_rect(Rect2(w * 0.5 - rule, above, rule * 2, 1), silver)
		draw_rect(Rect2(w * 0.5 - rule, below, rule * 2, 1), silver)
		# Little stars at the ends of the rules.
		for sx in [-1.0, 1.0]:
			var cx: float = w * 0.5 + (rule + 5.0) * sx
			for cy: float in [above, below]:
				draw_rect(Rect2(cx - 1, cy - 2, 1, 5), silver)
				draw_rect(Rect2(cx - 3, cy, 5, 1), silver)
		PixelFont._draw_run(self, Vector2(x + scale, y + scale), TEXT, Color(0, 0, 0, 0.85), scale, true)
		PixelFont._draw_run(self, Vector2(x, y), TEXT, Color(1, 1, 1), scale, true)
