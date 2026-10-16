class_name VisionRealm
extends Node3D
## Lothelye's dream: the starry void where the legend of Bunsriel is shown to
## the hero after he draws the Bun Sword (Story.legend). Like the Sacred Realm
## and the Deku Tree's tale of the goddesses in Ocarina of Time, the story is
## played out in light: a world dreamed out of the dark, the three goddesses as
## colored figures of light, the Dark Lord as a towering shadow, and the
## Nameless hero in gold.
##
## Built at run time high above the loaded area (out of sight of it) and freed
## when the vision ends. The scene camera takes `env` as its own environment,
## so the area's sky and fog do not reach it.

## Radius of the sphere of stars round the realm.
const STAR_R := 90.0
const GLOBE_R := 1.5

## The realm's own sky (no fog, a deep night color).
var env: Environment
## The world, once it has been dreamed (layers fade in as the goddesses come).
var globe: Node3D
var _layers := {}
var _sky_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _amb: AudioStreamPlayer
var _vortex: MeshInstance3D = null


func _init() -> void:
	name = "VisionRealm"


func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.02, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.58, 0.82)
	env.ambient_light_energy = 0.9
	env.fog_enabled = false
	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.rotation_degrees = Vector3(-50, 25, 0)
	key.light_color = Color(0.95, 0.92, 1.0)
	key.light_energy = 0.75
	add_child(key)
	_build_sky()
	_build_floor()
	_build_motes()
	_amb = AudioStreamPlayer.new()
	_amb.name = "Ambience"
	_amb.bus = "Ambience"
	add_child(_amb)
	if ResourceLoader.exists("res://assets/audio/amb_vision.wav"):
		_amb.stream = load("res://assets/audio/amb_vision.wav")
		_amb.volume_db = -40.0
		_amb.play()
		# Kept low under a scored scene's music (its choir chords are in E minor).
		create_tween().tween_property(_amb, "volume_db", -22.0 if World.score_position() >= 0.0 else -6.0, 2.5)


func _process(delta: float) -> void:
	if is_instance_valid(globe):
		globe.rotate_y(delta * 0.25)
	if is_instance_valid(_vortex):
		_vortex.rotate_y(delta * 3.0)


## Fades the realm's sound out (before it is freed).
func hush(time: float) -> void:
	if _amb.playing:
		create_tween().tween_property(_amb, "volume_db", -60.0, time)


# --- The void -----------------------------------------------------------------------

## The stars and colored clouds of the void (faded in by `show_stars`).
func _build_sky() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1964
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 70:
		var d := _rand_dir(rng)
		var col: Color = [Color(0.45, 0.25, 0.7), Color(0.2, 0.35, 0.75), Color(0.65, 0.3, 0.55), Color(0.15, 0.5, 0.6)][i % 4]
		col.a = rng.randf_range(0.12, 0.28)
		TitleScene._disc(st, d * (STAR_R + 4.0), -d, rng.randf_range(10.0, 24.0), col, Color(col, 0.0))
	for i in 1100:
		var d := _rand_dir(rng)
		var c := Color(1.0, 0.95, 0.85).lerp(Color(0.75, 0.85, 1.0), rng.randf()) * rng.randf_range(0.5, 1.0)
		c.a = 1.0
		TitleScene._quad(st, d * STAR_R, -d, rng.randf_range(0.25, 0.55) * (2.0 if rng.randf() < 0.05 else 1.0), c)
	_sky_mat = _unlit(Color(1, 1, 1, 0))
	_sky_mat.vertex_color_use_as_albedo = true
	_sky_mat.render_priority = -1
	st.set_material(_sky_mat)
	var mi := MeshInstance3D.new()
	mi.name = "Stars"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = STAR_R * 2.0
	add_child(mi)


func _rand_dir(rng: RandomNumberGenerator) -> Vector3:
	var z := rng.randf_range(-1.0, 1.0)
	var a := rng.randf() * TAU
	var r := sqrt(1.0 - z * z)
	return Vector3(r * cos(a), z, r * sin(a))


## A round floor of pale light under the hero, ringed and marked with an
## eight-pointed star (faded in with the stars).
func _build_floor() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold := Color(1.0, 0.92, 0.7, 0.5)
	TitleScene._disc(st, Vector3(0, 0.01, 0), Vector3.UP, 3.4, Color(1.0, 0.95, 0.85, 0.32), Color(0.75, 0.75, 1.0, 0.05))
	for ring in [[3.0, 3.12], [2.2, 2.26]]:
		_annulus(st, ring[0], ring[1], 0.02, gold)
	for i in 8:
		var a := TAU * i / 8.0
		var tip := Vector3(sin(a), 0, cos(a)) * (2.9 if i % 2 == 0 else 2.2)
		var side := Vector3(cos(a), 0, -sin(a)) * 0.05
		for v in [Vector3(0, 0.025, 0) + side, tip + Vector3(0, 0.025, 0), Vector3(0, 0.025, 0) - side]:
			st.set_color(gold)
			st.add_vertex(v)
	_floor_mat = _unlit(Color(1, 1, 1, 0))
	_floor_mat.vertex_color_use_as_albedo = true
	st.set_material(_floor_mat)
	var mi := MeshInstance3D.new()
	mi.name = "Floor"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var l := OmniLight3D.new()
	l.name = "FloorLight"
	l.position = Vector3(0, 0.6, 0)
	l.light_color = Color(1.0, 0.92, 0.8)
	l.light_energy = 0.8
	l.omni_range = 6.0
	add_child(l)


func _annulus(st: SurfaceTool, r0: float, r1: float, y: float, col: Color) -> void:
	var seg := 48
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p := [Vector3(sin(a0) * r0, y, cos(a0) * r0), Vector3(sin(a1) * r0, y, cos(a1) * r0),
			Vector3(sin(a1) * r1, y, cos(a1) * r1), Vector3(sin(a0) * r1, y, cos(a0) * r1)]
		for v in [p[0], p[1], p[2], p[0], p[2], p[3]]:
			st.set_color(col)
			st.add_vertex(v)


## Motes of light drifting up through the void.
func _build_motes() -> void:
	var p := CPUParticles3D.new()
	p.name = "Motes"
	p.position = Vector3(0, 0, -4)
	p.amount = 60
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(10, 3, 10)
	p.gravity = Vector3(0, 0.15, 0)
	p.initial_velocity_max = 0.1
	p.color = Color(1.0, 0.95, 0.8, 0.8)
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := _unlit(Color(1.0, 0.95, 0.8, 0.8))
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	p.mesh = q
	add_child(p)


## Fades the stars and the floor in (or out).
func show_stars(to: float, time: float) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_sky_mat, "albedo_color:a", to, time)
	t.tween_property(_floor_mat, "albedo_color:a", to, time)


# --- The world ---------------------------------------------------------------------

## Bunsriel as it was dreamed: a small world at `pos`, a point of light that
## swells into a barren globe. Its layers ("life", "sky", "fire") wait for
## the goddesses (`reveal`).
func dream_world(pos: Vector3) -> Node3D:
	globe = Node3D.new()
	globe.name = "Globe"
	add_child(globe)
	globe.position = pos
	var noise := FastNoiseLite.new()
	noise.seed = 31
	noise.frequency = 1.4
	var barren := func(d: Vector3) -> Color:
		var n := noise.get_noise_3dv(d)
		return Color(0.42, 0.36, 0.3).lerp(Color(0.6, 0.52, 0.42), clampf(n + 0.5, 0.0, 1.0))
	var alive := func(d: Vector3) -> Color:
		var n := noise.get_noise_3dv(d)
		if absf(d.y) > 0.88:
			return Color(0.95, 0.97, 1.0)
		if n < 0.0:
			return Color(0.15, 0.35, 0.75).lerp(Color(0.25, 0.5, 0.85), clampf(n + 0.6, 0.0, 1.0))
		if n < 0.05:
			return Color(0.85, 0.78, 0.55)
		return Color(0.25, 0.55, 0.22).lerp(Color(0.18, 0.4, 0.16), clampf(n * 2.0, 0.0, 1.0))
	_layers.ground = _sphere_layer("Ground", GLOBE_R, barren, false)
	_layers.life = _sphere_layer("Life", GLOBE_R * 1.005, alive, true)
	_layers.sky = _sphere_layer("Sky", GLOBE_R * 1.1, func(_d: Vector3) -> Color: return Color(0.6, 0.8, 1.0), true, true)
	# Fire: glowing points where the land rises highest (the volcanoes).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var placed := 0
	for i in 400:
		var d := _rand_dir(rng)
		if noise.get_noise_3dv(d) > 0.28 and absf(d.y) < 0.8:
			TitleScene._disc(st, d * GLOBE_R * 1.012, d, 0.09, Color(1.0, 0.85, 0.4), Color(1.0, 0.25, 0.1, 0.0))
			placed += 1
			if placed >= 10:
				break
	var fire_mat := _unlit(Color(1, 1, 1, 0))
	fire_mat.vertex_color_use_as_albedo = true
	st.set_material(fire_mat)
	var fire := MeshInstance3D.new()
	fire.name = "Fire"
	fire.mesh = st.commit()
	globe.add_child(fire)
	_layers.fire = fire_mat
	var l := OmniLight3D.new()
	l.name = "Glow"
	l.light_color = Color(1.0, 0.95, 0.85)
	l.light_energy = 1.5
	l.omni_range = 5.0
	globe.add_child(l)
	globe.scale = Vector3.ONE * 0.02
	return globe


func _sphere_layer(layer_name: String, r: float, paint: Callable, fade: bool, unshaded := false) -> StandardMaterial3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 16
	var seg := 24
	for j in rings:
		for i in seg:
			var pts: Array[Vector3] = []
			for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
				var th := PI * float(c[1]) / rings
				var ph := TAU * float(c[0]) / seg
				pts.append(Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph)))
			for k in [0, 2, 1, 0, 3, 2]:
				var d: Vector3 = pts[k]
				st.set_normal(d)
				var col: Color = paint.call(d)
				st.set_color(col)
				st.add_vertex(d * r)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.disable_fog = true
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if fade:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		m.albedo_color = Color(1, 1, 1, 0)
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.name = layer_name
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	globe.add_child(mi)
	return m


## Fades a layer of the world in: "life" (Alan's forests and fields), "sky"
## (Aphiel's skies and rivers), "fire" (Serielye's volcanoes).
func reveal(layer: String, to: float, time: float) -> void:
	if _layers.has(layer):
		create_tween().tween_property(_layers[layer], "albedo_color:a", to, time)


## Darkens the world (the Dark Lord's war), or lights it again.
func shadow_world(dark: bool, time: float) -> void:
	if not is_instance_valid(globe):
		return
	var col := Color(0.35, 0.18, 0.2) if dark else Color.WHITE
	for k in ["ground", "life"]:
		var m: StandardMaterial3D = _layers[k]
		create_tween().tween_property(m, "albedo_color", Color(col, m.albedo_color.a), time)
	var l := globe.get_node("Glow") as OmniLight3D
	create_tween().tween_property(l, "light_color", Color(0.8, 0.2, 0.15) if dark else Color(1.0, 0.95, 0.85), time)


# --- Figures of light ----------------------------------------------------------------

## A character drawn as a figure of light (a goddess, the Nameless hero) or
## of shadow: every part one flat color, starting unseen. `fade` brings it in.
func figure(model: String, pos: Vector3, yaw: float, col: Color, size := 1.0, eye_col := Color(0, 0, 0, 0)) -> CharacterModel:
	var m: CharacterModel = load("res://assets/models/%s.tscn" % model).instantiate()
	add_child(m)
	m.position = pos
	m.rotation.y = yaw
	m.scale = Vector3.ONE * size
	var mat := _unlit(Color(col, 0.0))
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	m.set_meta("glow_mat", mat)
	m.set_meta("glow_alpha", col.a)
	var eye_mat: StandardMaterial3D = null
	if eye_col.a > 0.0:
		eye_mat = _unlit(Color(eye_col, 0.0))
		m.set_meta("eye_mat", eye_mat)
	repaint(m)
	if col.a > 0.0 and col.get_luminance() > 0.2:
		var l := OmniLight3D.new()
		l.name = "Aura"
		l.position = Vector3(0, 1.2, 0)
		l.light_color = Color(col, 1.0)
		l.light_energy = 0.0
		l.omni_range = 4.0
		m.add_child(l)
	return m


## Paints a figure's parts again (after its gear changes meshes).
func repaint(m: Node3D) -> void:
	var mat: Material = m.get_meta("glow_mat")
	var eye_mat: Material = m.get_meta("eye_mat") if m.has_meta("eye_mat") else null
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.material_override = eye_mat if eye_mat and mi.has_meta("no_tint") else mat


## Fades a figure in (to its color's alpha) or out (to 0), its aura with it.
func fade(m: Node3D, show: bool, time: float) -> Tween:
	var t := create_tween().set_parallel(true)
	if not is_instance_valid(m):
		t.tween_interval(time)
		return t
	var a: float = m.get_meta("glow_alpha", 1.0) if show else 0.0
	if m.has_meta("glow_mat"):
		t.tween_property(m.get_meta("glow_mat"), "albedo_color:a", a, time)
	if m.has_meta("eye_mat"):
		t.tween_property(m.get_meta("eye_mat"), "albedo_color:a", 1.0 if show else 0.0, time)
	var aura := m.get_node_or_null("Aura") as OmniLight3D
	if aura:
		t.tween_property(aura, "light_energy", 1.4 if show else 0.0, time)
	return t


## A ball of colored light (a goddess's power) with a glow round it.
func orb(pos: Vector3, col: Color, size := 0.25) -> Node3D:
	var o := Node3D.new()
	o.name = "Orb"
	add_child(o)
	o.position = pos
	var core := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.0
	s.radial_segments = 12
	s.rings = 6
	core.mesh = s
	core.material_override = _unlit(Color(col.lightened(0.5), 1.0))
	o.add_child(core)
	var halo := MeshInstance3D.new()
	var h := SphereMesh.new()
	h.radius = size * 2.2
	h.height = size * 4.4
	h.radial_segments = 12
	h.rings = 6
	halo.mesh = h
	halo.material_override = _unlit(Color(col, 0.3))
	o.add_child(halo)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.6
	l.omni_range = 4.0
	o.add_child(l)
	return o


## A burst of sparkles at `pos` (a figure appearing).
func sparkle(pos: Vector3, col: Color, amount := 40) -> void:
	var p := CPUParticles3D.new()
	p.name = "Sparkle"
	add_child(p)
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = amount
	p.lifetime = 1.4
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.4
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0, -0.4, 0)
	p.damping_min = 0.8
	p.damping_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := _unlit(Color(col.lightened(0.4), 1.0))
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	p.mesh = q
	p.emitting = true
	get_tree().create_timer(2.0, false).timeout.connect(p.queue_free)


## The Astral Dimension opening: a swirling violet whirl at `pos`, `radius`
## wide, that swallows what is pulled into it. `close_vortex` shuts it.
func open_vortex(pos: Vector3, radius: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for arm in 5:
		var off := TAU * arm / 5.0
		for i in 40:
			var k0 := float(i) / 40.0
			var k1 := float(i + 1) / 40.0
			var a0 := off + k0 * TAU * 1.2
			var a1 := off + k1 * TAU * 1.2
			var w0 := 0.18 * (1.0 - k0) + 0.02
			var w1 := 0.18 * (1.0 - k1) + 0.02
			var r0 := radius * (1.0 - k0)
			var r1 := radius * (1.0 - k1)
			var c0 := Color(0.6, 0.35, 1.0, 0.85 * (1.0 - k0 * 0.5))
			var c1 := Color(0.6, 0.35, 1.0, 0.85 * (1.0 - k1 * 0.5))
			var p0 := Vector3(cos(a0) * r0, 0, sin(a0) * r0)
			var p1 := Vector3(cos(a1) * r1, 0, sin(a1) * r1)
			var n0 := Vector3(cos(a0), 0, sin(a0)) * w0 * radius
			var n1 := Vector3(cos(a1), 0, sin(a1)) * w1 * radius
			for v in [[p0 - n0, c0], [p1 - n1, c1], [p1 + n1, c1], [p0 - n0, c0], [p1 + n1, c1], [p0 + n0, c0]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	TitleScene._disc(st, Vector3(0, -0.01, 0), Vector3.UP, radius * 0.35, Color(0.05, 0.0, 0.12, 1.0), Color(0.3, 0.1, 0.6, 0.0))
	var m := _unlit(Color.WHITE)
	m.vertex_color_use_as_albedo = true
	st.set_material(m)
	_vortex = MeshInstance3D.new()
	_vortex.name = "Vortex"
	_vortex.mesh = st.commit()
	add_child(_vortex)
	_vortex.position = pos
	# Standing on edge, facing the watcher (+Z), like a door in the dark.
	_vortex.rotation = Vector3(PI / 2.0, 0, 0)
	_vortex.scale = Vector3.ONE * 0.05
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.35, 1.0)
	l.light_energy = 2.0
	l.omni_range = radius * 3.0
	_vortex.add_child(l)
	create_tween().tween_property(_vortex, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_vortex(time: float) -> void:
	if not is_instance_valid(_vortex):
		return
	var v := _vortex
	var t := create_tween()
	t.tween_property(v, "scale", Vector3.ONE * 0.01, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(v.queue_free)


static func _unlit(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	m.disable_receive_shadows = true
	m.albedo_color = col
	return m


# --- The apparition ----------------------------------------------------------------

## Lothelye as a vision: her own colors, glowing softly and a little see-
## through, faded by `ghost_alpha`. Returns the materials (to fade).
static func ghost(m: Node3D, glow := 0.35) -> Array[StandardMaterial3D]:
	var mats: Array[StandardMaterial3D] = []
	for n in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var base := mi.get_active_material(s) as StandardMaterial3D
			if base == null:
				continue
			var c := base.duplicate() as StandardMaterial3D
			c.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			c.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
			c.disable_fog = true
			c.emission_enabled = true
			c.emission = Color(0.85, 0.85, 1.0) * glow
			c.albedo_color = Color(c.albedo_color, 0.0)
			mi.set_surface_override_material(s, c)
			mats.append(c)
	return mats


static func ghost_alpha(owner: Node, mats: Array[StandardMaterial3D], to: float, time: float) -> Tween:
	var t := owner.create_tween().set_parallel(true)
	for c in mats:
		t.tween_property(c, "albedo_color:a", to, time)
	if mats.is_empty():
		t.tween_interval(time)
	return t
