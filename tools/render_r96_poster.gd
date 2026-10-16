extends Node
class_name R96Poster
## Render96-style key-art poster (OoT box-art composition): the cast
## remastered as smooth high-poly models (R96Kit / R96Head / R96Hair /
## R96Detail) with HD painted faces, rendered as separate layers that
## _giggle64_work/r96/compose_poster.py paints together. Run windowed:
##   Godot --path <project> --rendering-method forward_plus res://tools/render_r96_poster.tscn -- --out=<dir> [--scale=1] [--only=cast,bg,...]
## Layers: bg (Bunsriel Castle over the fields, for blurring), villain
## (Firebuns looming), goddess (Lothelye), cast (hero, Mira, Himeko, Mara).

const HD_FACE_DIR := "res://promo/r96/faces/"
const SIZE := Vector2i(2000, 3000)

var _args := {}
var _vp: SubViewport
var _groups := {}
var _lights := {}
var _env: WorldEnvironment
var _envs := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	no_n64_mode(get_tree())
	load_hd_faces()
	_vp = SubViewport.new()
	_vp.size = Vector2i(Vector2(SIZE) * float(_args.get("scale", "1")))
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_8X
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_environment()
	var only: Array = String(_args.get("only", "bg,villain,mara,goddess,cast")).split(",")
	if only.has("cast"):
		_build_cast()
	if only.has("villain"):
		_build_villain()
	if only.has("goddess"):
		_build_goddess()
	if only.has("mara"):
		_build_mara()
	if only.has("bg"):
		_build_bg()
	var out: String = _args.get("out", ProjectSettings.globalize_path("res://promo/r96/layers"))
	DirAccess.make_dir_recursive_absolute(out)
	for layer: String in ["bg", "villain", "mara", "goddess", "cast"]:
		if not only.has(layer):
			continue
		for g: String in _groups:
			(_groups[g] as Node3D).visible = g == layer
		for g: String in _lights:
			for l: Node3D in _lights[g]:
				l.visible = g == layer
		var cam := (_groups[layer] as Node3D).find_child("Cam", true, false) as Camera3D
		cam.current = true
		_env.environment = _envs[layer]
		for i in 12:
			await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.save_png(out + "/" + layer + ".png")
		print("render_r96_poster: %s -> %s" % [layer, out])
	get_tree().quit()


# --- Shared ---------------------------------------------------------------------------

## Loads hand-painted HD faces (promo/r96/faces/face_<id>.png) for R96Kit.
static func load_hd_faces() -> void:
	var dir := ProjectSettings.globalize_path(HD_FACE_DIR)
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			var img := Image.load_from_file(dir + f)
			R96Kit.hd_faces[f.get_basename()] = ImageTexture.create_from_image(img)


## The promo renders want the modern renderer's materials, not TRUE N64 MODE.
static func no_n64_mode(tree: SceneTree) -> void:
	var gm := tree.root.get_node_or_null("GameManager")
	if gm and gm.get("true_n64"):
		gm.set("true_n64", false)
	var n64 := tree.root.get_node_or_null("N64Mode")
	if n64:
		n64.call("_apply_settings")
		n64.set("post_enabled", false)
		n64.call("_update_post")


## Soft CGI studio lighting (used by the comparison tool).
static func studio_lights(parent: Node, bg: Color, transparent := false) -> void:
	var env := WorldEnvironment.new()
	env.environment = _studio_env(bg)
	parent.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32, -28, 0)
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = 1.25
	key.shadow_enabled = true
	key.shadow_blur = 2.0
	key.directional_shadow_max_distance = 12.0
	parent.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 40, 0)
	fill.light_color = Color(0.7, 0.78, 1.0)
	fill.light_energy = 0.4
	parent.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_color = Color(1.0, 0.92, 0.8)
	rim.light_energy = 1.1
	parent.add_child(rim)


static func _studio_env(bg: Color, sky_top := Color(0.35, 0.42, 0.6), sky_hor := Color(0.85, 0.7, 0.55)) -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = sky_top
	sm.sky_horizon_color = sky_hor
	sm.ground_bottom_color = Color(0.12, 0.1, 0.1)
	sm.ground_horizon_color = sky_hor * 0.6
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 0.25
	e.ssao_intensity = 1.6
	return e


func _environment() -> void:
	_env = WorldEnvironment.new()
	_vp.add_child(_env)
	# Characters: dusk sky reflections, warm below, cool above.
	for g in ["cast", "villain", "goddess", "mara"]:
		_envs[g] = _studio_env(Color(0, 0, 0, 0), Color(0.3, 0.32, 0.55), Color(0.95, 0.62, 0.42))
	var bg := Environment.new()
	bg.background_mode = Environment.BG_COLOR
	bg.background_color = Color(0, 0, 0, 0)
	bg.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	bg.ambient_light_color = Color(0.55, 0.5, 0.65)
	bg.ambient_light_energy = 0.7
	bg.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	bg.fog_enabled = true
	bg.fog_light_color = Color(0.85, 0.62, 0.55)
	bg.fog_density = 0.0025
	bg.fog_sky_affect = 0.0
	bg.ssao_enabled = true
	_envs["bg"] = bg


func _group(name: String) -> Node3D:
	var g := Node3D.new()
	g.name = name
	_vp.add_child(g)
	_groups[name] = g
	_lights[name] = []
	return g


func _light(group: String, rot: Vector3, col: Color, energy: float, shadow := false) -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = rot
	l.light_color = col
	l.light_energy = energy
	l.shadow_enabled = shadow
	l.shadow_blur = 1.5
	l.directional_shadow_max_distance = 14.0
	_vp.add_child(l)
	_lights[group].append(l)
	return l


func _cam(parent: Node3D, eye: Vector3, at: Vector3, fov: float) -> Camera3D:
	var c := Camera3D.new()
	c.name = "Cam"
	c.fov = fov
	c.far = 2000.0
	parent.add_child(c)
	c.look_at_from_position(eye, at, Vector3.UP)
	return c


## Loads a model, freezes it on a frame of `anim`, remasters it.
func _model(parent: Node3D, file: String, id: String, at: Vector3, yaw: float, anim: String, t: float, gear := []) -> Node3D:
	var m := (load("res://assets/models/%s.tscn" % file) as PackedScene).instantiate() as Node3D
	parent.add_child(m)
	m.position = at
	m.rotation_degrees.y = yaw
	if not gear.is_empty() and m.has_method("set_gear"):
		m.call("set_gear", gear[0], gear[1])
		m.call("set_sword_drawn", true)
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		ap.play(anim if ap.has_animation(anim) else &"idle")
		ap.seek(t, true)
		ap.pause()
	m.process_mode = Node.PROCESS_MODE_DISABLED
	R96Detail.apply(id, m)
	R96Kit.remaster(m, 2, 0.5, id)
	return m


func _j(m: Node3D, n: String) -> Node3D:
	return m.find_child(n, true, false) as Node3D


func _rot(m: Node3D, n: String, deg: Vector3) -> void:
	var j := _j(m, n)
	if j:
		j.rotation_degrees = deg


# --- The cast ------------------------------------------------------------------------

func _build_cast() -> void:
	var g := _group("cast")
	# The hero: Bun Sword raised high, Questlord shield forward, cape streaming.
	var hero := _model(g, "sir_gigglebuns", "gigglebuns", Vector3(0, 0, 0.55), 180.0 - 18.0, "idle", 0.3, ["bun", "questlord"])
	_pose_hero(hero)
	var mira := _model(g, "mira", "mira", Vector3(-0.74, 0.0, -0.05), 180.0 + 24.0, "huff", 0.6)
	_look(mira, _j(mira, "Head"), Vector3(0, 1.0, 6.0))
	var hime := _model(g, "himeko", "himeko", Vector3(0.74, 0.0, -0.05), 180.0 - 28.0, "idle", 0.4)
	_look(hime, _j(hime, "Head"), Vector3(-0.4, 1.4, 6.0))
	_cam(g, Vector3(0.0, 0.85, 5.9), Vector3(0.0, 1.27, 0.0), 33.0)
	# Key from the upper left, cool fill from the right, a hot golden rim from
	# behind (the light the hero stands in), and fire from the lower left.
	_light("cast", Vector3(-28, -38, 0), Color(1.0, 0.86, 0.7), 1.35, true)
	_light("cast", Vector3(-12, 42, 0), Color(0.62, 0.7, 1.0), 0.55)
	_light("cast", Vector3(-18, 170, 0), Color(1.0, 0.82, 0.5), 1.6)
	_light("cast", Vector3(-25, -150, 0), Color(1.0, 0.45, 0.25), 0.9)


func _pose_hero(hero: Node3D) -> void:
	var hips := _j(hero, "Hips")
	hips.position.y -= 0.07
	_rot(hero, "Torso", Vector3(-6, 14, 2))
	_rot(hero, "LegL", Vector3(-30, 0, 10))
	_rot(hero, "KneeL", Vector3(30, 0, 0))
	_rot(hero, "LegR", Vector3(26, 0, -8))
	_rot(hero, "KneeR", Vector3(12, 0, 0))
	# Sword arm: hand above the head on the right, blade raised to the sky.
	_solve_arm(hero, "R", _j(hero, "Sword"), hero.to_global(Vector3(0.34, 1.86, -0.12)), (hero.global_basis * Vector3(0.32, 1.0, -0.2)).normalized())
	# Shield arm: braced forward across the body.
	_solve_arm(hero, "L", null, hero.to_global(Vector3(-0.2, 1.22, -0.36)), Vector3.ZERO)
	_look(hero, _j(hero, "Head"), Vector3(0.15, 1.75, 5.9))


# --- The looming figures --------------------------------------------------------------

func _build_villain() -> void:
	var g := _group("villain")
	g.position = Vector3(40, 0, 0)
	var fb := _model(g, "firebuns", "firebuns", Vector3.ZERO, 180.0 - 22.0, "laugh", 0.45)
	_look(fb, _j(fb, "Head"), g.to_global(Vector3(0.4, 1.0, 4.0)))
	var head := _j(fb, "Head").global_position
	_cam(g, head + Vector3(-0.3, -0.05, 2.0), head + Vector3(0.0, -0.36, 0), 40.0)
	_light("villain", Vector3(20, -30, 0), Color(1.0, 0.45, 0.18), 1.6, true)
	_light("villain", Vector3(-30, 150, 0), Color(1.0, 0.3, 0.1), 2.0)
	_light("villain", Vector3(-20, 40, 0), Color(0.5, 0.3, 0.6), 0.4)


## Mara, the Scourge of Bunsriel, looming beneath Firebuns with her flail.
func _build_mara() -> void:
	var g := _group("mara")
	g.position = Vector3(80, 0, 0)
	var ma := _model(g, "mara", "mara", Vector3.ZERO, 180.0 - 30.0, "windup", 0.5)
	_look(ma, _j(ma, "Head"), g.to_global(Vector3(0.8, 1.2, 4.0)))
	var head := _j(ma, "Head").global_position
	_cam(g, head + Vector3(-0.4, -0.2, 2.6), head + Vector3(0.05, -0.45, 0), 40.0)
	_light("mara", Vector3(15, -40, 0), Color(1.0, 0.4, 0.2), 1.3, true)
	_light("mara", Vector3(-25, 150, 0), Color(0.9, 0.25, 0.35), 2.0)
	_light("mara", Vector3(-20, 50, 0), Color(0.45, 0.4, 0.7), 0.5)


func _build_goddess() -> void:
	var g := _group("goddess")
	g.position = Vector3(-40, 0, 0)
	var lo := _model(g, "lothelye", "lothelye", Vector3.ZERO, 180.0 + 14.0, "idle", 0.8)
	_look(lo, _j(lo, "Head"), g.to_global(Vector3(-1.4, 1.0, 3.0)))
	var head := _j(lo, "Head").global_position
	_cam(g, head + Vector3(0.25, -0.1, 2.3), head + Vector3(0.0, -0.4, 0), 40.0)
	_light("goddess", Vector3(-40, 20, 0), Color(1.0, 0.97, 0.92), 1.2, true)
	_light("goddess", Vector3(-10, 160, 0), Color(0.75, 0.8, 1.0), 2.0)
	_light("goddess", Vector3(-5, -60, 0), Color(0.9, 0.85, 1.0), 0.5)


# --- Bunsriel Castle over the fields ----------------------------------------------------

func _build_bg() -> void:
	var g := _group("bg")
	g.position = Vector3(0, -200, 0)
	var k := preload("res://tools/mesh_kit.gd").new(64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	# Rolling fields rising to the castle hill.
	var n := 70
	var size := 520.0
	var hgt := func(x: float, z: float) -> float:
		var h := sin(x * 0.021) * 4.0 + cos(z * 0.017 + 1.3) * 5.0 + sin((x + z) * 0.043) * 1.6
		var hill := exp(-(pow(x / 70.0, 2.0) + pow((z + 210.0) / 62.0, 2.0))) * 42.0
		return h + hill
	var grass := [Color("4c7a2c"), Color("5a8a34"), Color("6a9a3c"), Color("3e6a26")]
	for i in n:
		for j in n:
			var x0 := -size * 0.5 + size * i / n
			var z0 := -size * 0.8 + size * j / n
			var x1 := x0 + size / n
			var z1 := z0 + size / n
			var p := [Vector3(x0, hgt.call(x0, z0), z0), Vector3(x1, hgt.call(x1, z0), z0), Vector3(x1, hgt.call(x1, z1), z1), Vector3(x0, hgt.call(x0, z1), z1)]
			var cs := []
			for q: Vector3 in p:
				var cc: Color = grass[int(absf(sin(q.x * 0.05) * cos(q.z * 0.04)) * 3.99)]
				cs.append(cc.lerp(Color("8a7a4a"), clampf((q.y - 30.0) / 20.0, 0.0, 0.4)))
			k.tri_vc([p[0], p[1], p[2]], [cs[0], cs[1], cs[2]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, -100, 0))
			k.tri_vc([p[0], p[2], p[3]], [cs[0], cs[2], cs[3]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], Vector3(0, -100, 0))
	# The road winding up to the town gate.
	for i in 40:
		var t := float(i) / 40.0
		var z := lerpf(10.0, -160.0, t)
		var x := sin(t * 5.0) * 22.0 * (1.0 - t)
		k.box(Vector3(x, hgt.call(x, z) + 0.15, z), Vector3(5.0, 0.3, 5.0), Color("b09a6a"))
	# Castle Town on the hill: a ring wall and roofs climbing toward the castle.
	var top: float = hgt.call(0.0, -210.0)
	var stone := Color("a8a49c")
	var stone_d := Color("8a867e")
	for i in 36:
		var a := TAU * i / 36.0
		var p := Vector3(cos(a) * 58.0, 0, -210.0 + sin(a) * 50.0)
		p.y = hgt.call(p.x, p.z)
		k.box(p + Vector3(0, 4.0, 0), Vector3(10.5, 9.0, 2.5), stone_d)
		if i % 4 == 0:
			k.prism(p, 3.2, p + Vector3(0, 13, 0), 3.2, 10, stone)
			k.prism(p + Vector3(0, 13, 0), 3.8, p + Vector3(0, 19, 0), 0.0, 10, Color("4a5a8a"))
	var roofs := [Color("b8402e"), Color("c85a32"), Color("4a6aa8"), Color("a83a3a"), Color("d07a3a")]
	var walls := [Color("e8dcc0"), Color("d8c8a0"), Color("e0d0b8"), Color("c8b898")]
	for i in 110:
		var a := rng.randf() * TAU
		var r := rng.randf_range(16.0, 50.0)
		var p := Vector3(cos(a) * r, 0, -210.0 + sin(a) * r * 0.85)
		p.y = hgt.call(p.x, p.z)
		var w := rng.randf_range(4.0, 7.0)
		var h := rng.randf_range(4.0, 7.0)
		var d := rng.randf_range(4.0, 6.0)
		k.box(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), walls[i % walls.size()])
		var rc: Color = roofs[rng.randi() % roofs.size()]
		k.hexa([p + Vector3(-w * 0.6, h, -d * 0.6), p + Vector3(w * 0.6, h, -d * 0.6), p + Vector3(w * 0.6, h, d * 0.6), p + Vector3(-w * 0.6, h, d * 0.6),
			p + Vector3(-w * 0.6, h + 3.5, 0), p + Vector3(w * 0.6, h + 3.5, 0), p + Vector3(w * 0.6, h + 3.5, 0), p + Vector3(-w * 0.6, h + 3.5, 0)], rc)
	# Bunsriel Castle: a tall keep with spired towers, gray stone, slate roofs.
	var c := Vector3(0, top, -228.0)
	var slate := Color("3e4a78")
	k.box(c + Vector3(0, 14, 0), Vector3(30, 28, 22), stone)
	k.box(c + Vector3(0, 34, 0), Vector3(18, 16, 14), stone)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tp: Vector3 = c + Vector3(15.0 * sx, 0, 11.0 * sz)
			k.prism(tp, 4.2, tp + Vector3(0, 40, 0), 4.0, 14, stone)
			k.prism(tp + Vector3(0, 40, 0), 5.2, tp + Vector3(0, 54, 0), 0.0, 14, slate)
	k.prism(c + Vector3(0, 42, 0), 5.0, c + Vector3(0, 66, 0), 4.6, 14, stone)
	k.prism(c + Vector3(0, 66, 0), 6.4, c + Vector3(0, 90, 0), 0.0, 14, slate)
	for sx in [-1.0, 1.0]:
		var tp: Vector3 = c + Vector3(7.0 * sx, 42, -6.0)
		k.prism(tp, 2.6, tp + Vector3(0, 14, 0), 2.4, 12, stone)
		k.prism(tp + Vector3(0, 14, 0), 3.2, tp + Vector3(0, 24, 0), 0.0, 12, slate)
	for i in 12:
		k.box(c + Vector3(-14.0 + i * 2.55, 28.8, -11.2), Vector3(1.4, 1.8, 1.2), stone)
	# Trees: round canopies scattered over the fields.
	for i in 160:
		var x := rng.randf_range(-220.0, 220.0)
		var z := rng.randf_range(-170.0, 20.0)
		if absf(x) < 70.0 and z < -140.0:
			continue
		var y: float = hgt.call(x, z)
		var s := rng.randf_range(2.2, 4.5)
		k.prism(Vector3(x, y, z), 0.5, Vector3(x, y + s, z), 0.4, 6, Color("5a3a22"))
		k.icosa(Vector3(x, y + s * 1.6, z), Vector3(s, s * 1.1, s), 0.1, [Color("2e5a22"), Color("3a6a2a"), Color("44782e")][i % 3], true)
	# Far mountains behind, blue with distance, snow on the peaks.
	for i in 9:
		var x := -300.0 + i * 75.0 + rng.randf_range(-20, 20)
		var z := rng.randf_range(-520.0, -440.0)
		var h := rng.randf_range(90.0, 170.0)
		k.prism(Vector3(x, -10, z), rng.randf_range(70.0, 110.0), Vector3(x + rng.randf_range(-15, 15), h, z), 0.0, 7, Color("6a6e98"))
		k.prism(Vector3(x, h * 0.72, z), 26.0, Vector3(x, h + 1.0, z), 0.0, 7, Color("e8e4f0"))
	k.smooth_normals(50.0)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = k.build(m)
	g.add_child(mi)
	_cam(g, g.to_global(Vector3(0, 24, 60)), g.to_global(Vector3(0, 52, -228)), 40.0)
	var sun := _light("bg", Vector3(-12, -55, 0), Color(1.0, 0.7, 0.45), 1.6, true)
	sun.directional_shadow_max_distance = 600.0
	_light("bg", Vector3(-30, 120, 0), Color(0.55, 0.55, 0.85), 0.5)


# --- Posing helpers (as in render_clash) -------------------------------------------------

## Turns shoulder, elbow and hand so the hand (or `tool`'s grip) reaches
## `target` and, with a tool, its blade points along `dir`.
func _solve_arm(m: Node3D, side: String, tool: Node3D, target: Vector3, dir: Vector3) -> void:
	var joints: Array[Node3D] = [_j(m, "Shoulder" + side), _j(m, "Elbow" + side), _j(m, "Hand" + side)]
	var tip: Node3D = tool if tool else joints[2]
	var axis := _blade_axis(tool) if tool else Vector3.ZERO
	var start: Array[Vector3] = []
	for j in joints:
		start.append(j.rotation)
	var cost := func() -> float:
		var c := tip.global_position.distance_squared_to(target) * 40.0
		if tool:
			var d := (tip.global_basis * axis).normalized()
			c += (1.0 - d.dot(dir)) * 3.0
		for i in 3:
			c += (joints[i].rotation - start[i]).length_squared() * 0.004
		return c
	var best: float = cost.call()
	var step := 0.5
	for it in 500:
		var improved := false
		for ji in 3:
			for ax in 3:
				for sgn in [1.0, -1.0]:
					var r := joints[ji].rotation
					r[ax] += step * sgn
					var old := joints[ji].rotation
					joints[ji].rotation = r
					var c: float = cost.call()
					if c < best:
						best = c
						improved = true
					else:
						joints[ji].rotation = old
		if not improved:
			step *= 0.6
			if step < 0.002:
				break
	print("render_r96_poster: %s %s arm off by %.3f m" % [m.name, side, tip.global_position.distance_to(target)])


func _blade_axis(tool: Node3D) -> Vector3:
	var box := AABB()
	for c in tool.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			box = (c as MeshInstance3D).get_aabb()
	var s := box.size
	var c := box.get_center()
	if s.x >= s.y and s.x >= s.z:
		return Vector3(signf(c.x), 0, 0)
	if s.y >= s.z:
		return Vector3(0, signf(c.y), 0)
	return Vector3(0, 0, signf(c.z))


## Turns the head (its face is -Z) to look at `point`.
func _look(m: Node3D, head: Node3D, point: Vector3) -> void:
	if head == null:
		return
	var best := INF
	var keep := head.rotation
	for x in range(-40, 41, 4):
		for y in range(-60, 61, 4):
			head.rotation = Vector3(deg_to_rad(x), deg_to_rad(y), 0)
			var fwd := -head.global_basis.z.normalized()
			var c := 1.0 - fwd.dot((point - head.global_position).normalized())
			if c < best:
				best = c
				keep = head.rotation
	head.rotation = keep
