extends Node
## Character cards: each of the main cast in a realm of their own colors,
## with a name card along the bottom in the game's pixel font (the same look
## as the Avalon promo). Run windowed (needs a GPU):
##   Godot --path <project> res://tools/render_character_card.tscn -- [--who=a,b] [--aspect=portrait|landscape|both] [--dir=<folder>] [--scale=1]
##   ... -- --list    prints each model's animations and size, renders nothing
## Writes <dir>/<id>.png (16:9, 1920x1080) and <dir>/<id>_9x16.png (1080x1920).
## The cast, plus three of the foes the user asked for (Mara, Firebuns III,
## Velloran); other bosses and enemies are left out.

const ASPECTS := {
	"landscape": {"size": Vector2i(1920, 1080), "suffix": "", "card_scale": 3, "glyph": 2, "fov": 40.0, "fill": 0.66, "low": -0.03},
	"portrait": {"size": Vector2i(1080, 1920), "suffix": "_9x16", "card_scale": 4, "grow": true, "glyph": 1, "fov": 50.0, "fill": 0.6, "low": 0.1},
	# The figure alone on a transparent background (the instruction booklet).
	"cutout": {"size": Vector2i(1200, 1600), "suffix": "_cut", "card_scale": 4, "glyph": 1, "fov": 30.0, "fill": 0.86, "low": 0.0},
}

## The palette of each realm: sky heart, sky edge, glare, halo/rules accent,
## floor glow, shard tint, shard glow, motes, and the motes' kind
## ("stars", "embers", "snow", "petals", "dust", "bubbles", "leaves").
const THEMES := {
	"hero": ["#2a4fa8", "#d9a441", "#fff2c8", "#ffd36a", "#ffcf6a", "#bcd4ff", "#3a66d0", "#ffe9a8", "stars"],
	"forge": ["#b8431a", "#3a1208", "#ffd0a0", "#ffb054", "#ff7a2a", "#5a3a30", "#ff5a1a", "#ffb060", "embers"],
	"sand": ["#d08a3a", "#6a2a18", "#fff0c0", "#ffd27a", "#ffbe6a", "#f0c48a", "#c86a2a", "#ffe0a0", "dust"],
	"dusk_sand": ["#7a3f8a", "#d0703a", "#ffe0c8", "#ffc0d8", "#ff9a7a", "#e8b0d0", "#a04a9a", "#ffd8e8", "stars"],
	"lake": ["#1f7fa0", "#0a2a5a", "#d8f6ff", "#a8ecff", "#7ad8ff", "#a8e0f0", "#2a90c0", "#d0f4ff", "bubbles"],
	"palace": ["#e070b0", "#7a4ab8", "#fff0f8", "#ffd0ec", "#ff9ad0", "#ffc8e6", "#e060a8", "#ffd8ee", "petals"],
	"library": ["#9a6a30", "#3a2410", "#fff0d0", "#ffd890", "#f0b860", "#e0c8a0", "#a87a3a", "#ffe8b8", "dust"],
	"store": ["#e8902a", "#8a3a1a", "#fff4d0", "#ffe080", "#ffc04a", "#ffd890", "#e08a2a", "#fff0b0", "petals"],
	"fields": ["#4aa860", "#2a6ab0", "#f8ffe0", "#e8ff9a", "#b8f07a", "#c8f0a0", "#4ab060", "#f0ffc8", "leaves"],
	"frost": ["#7ab8e8", "#2a3a7a", "#ffffff", "#e0f4ff", "#bfe8ff", "#d8f0ff", "#6ab0f0", "#ffffff", "snow"],
	"town": ["#5a3a90", "#e0904a", "#fff0d8", "#ffd27a", "#ffb870", "#e8c8f0", "#8a5ac0", "#ffe8c0", "stars"],
	"herald": ["#a82a3a", "#2a2a7a", "#fff0c0", "#ffd860", "#ffc04a", "#f0c8a0", "#c8303a", "#ffe8a0", "stars"],
	"cosmic": ["#e8862a", "#3a1a6a", "#fff4d8", "#ffcf7a", "#ffaa4a", "#ffd8a0", "#ff9a3a", "#fff0c8", "stars"],
	"hells": ["#6a2ab8", "#b01428", "#ffe8e0", "#ffc850", "#ff6a1e", "#3a1a2a", "#b01e14", "#ff8a3a", "embers"],
	"ash": ["#5a4a6a", "#8a3a1a", "#f0e0d0", "#ffb070", "#ff8a3a", "#6a5a6a", "#c0501a", "#ffb070", "embers"],
	"grave": ["#2a6a5a", "#1a1a3a", "#e0fff0", "#a8ffd0", "#6ae0a8", "#a0c8b8", "#2ab080", "#c0ffe0", "stars"],
	"steel": ["#3a5a8a", "#8a1a2a", "#f0f4ff", "#e0e8ff", "#c8d8ff", "#c0cce0", "#4a6ab0", "#e8f0ff", "stars"],
	"dawn": ["#e88aa0", "#f0c060", "#fff8e8", "#fff0b0", "#ffd890", "#ffd8e0", "#f0a0b0", "#fff4d0", "petals"],
	"hearth": ["#c8783a", "#5a3a8a", "#fff0d0", "#ffd890", "#ffb870", "#f0c8a0", "#d08a40", "#ffe8b8", "leaves"],
	"meadow": ["#d8a040", "#3a8a5a", "#fff8d8", "#fff0a0", "#ffe080", "#f0e0a0", "#c89a3a", "#fff8c0", "leaves"],
	"undead": ["#1e4a3a", "#2a0e2a", "#d8ffe8", "#9affc8", "#4ae08a", "#3a4a42", "#2ac070", "#a8ffc8", "embers"],
	"inferno": ["#c83a10", "#200404", "#ffe0a0", "#ffb040", "#ff5a10", "#3a1a12", "#ff3a0a", "#ffa040", "embers"],
	"sapphire": ["#1a3aa8", "#2a0e5a", "#e0ecff", "#8ab8ff", "#4a8aff", "#6a8ae0", "#2a5aff", "#c0d8ff", "stars"],
}

## id: [model, card text, theme, anim, time, turn (degrees)(, how much of the
## frame it fills, 1 = a person's share)].
const CAST := {
	"sir_gigglebuns": ["sir_gigglebuns", "Sir Gigglebuns IV, Knight of Haven", "hero", "idle", 0.5, 160.0],
	"pink": ["pink", "Pink of the Armory", "forge", "idle", 0.5, 165.0],
	"aladriel": ["aladriel", "Aladriel, Questlord of Ladhellin", "sand", "stand", 0.5, 160.0],
	"idrith": ["idrith", "Idrith, Leader of the Questlords", "dusk_sand", "stand", 0.5, 168.0],
	"mira": ["mira", "Mira of Mirror Lake", "lake", "idle", 0.5, 165.0],
	"himeko": ["himeko", "Princess Himeko of Haven Village", "palace", "idle", 0.5, 165.0],
	"ottilie": ["ottilie", "Ottilie of the Haven Library", "library", "idle", 0.5, 165.0],
	"marigold": ["marigold", "Marigold of the Village Store", "store", "idle", 0.5, 165.0],
	"clover": ["clover", "Clover of the Southern Fields", "fields", "idle", 0.5, 165.0],
	"hilde": ["hilde", "Hilde of Frostpeak", "frost", "idle", 0.5, 165.0],
	"tansy": ["tansy", "Tansy of Castle Town", "town", "idle", 0.5, 165.0],
	"pip": ["pip", "Pip, Herald of Haven", "herald", "idle", 0.5, 165.0],
	"lothelye": ["lothelye", "Lothelye, the Cosmic Deity", "cosmic", "idle", 0.5, 168.0],
	"serielye": ["serielye", "Serielye, Goddess of Destruction", "hells", "point", 0.6, 150.0],
	"maud": ["maud", "Elder Maud of Ashwick", "ash", "idle", 0.5, 165.0],
	"wren": ["wren", "Wren, Gravekeeper of Ashwick", "grave", "idle", 0.5, 165.0],
	"odile": ["odile", "Odile of Ashwick", "ash", "idle", 0.5, 160.0],
	"tamsin": ["tamsin", "Tamsin of Ashwick", "hearth", "idle", 0.5, 165.0],
	"rowena": ["rowena", "Commander Rowena of the Haven Guard", "steel", "idle", 0.5, 160.0],
	"posy": ["posy", "Posy of Castle Town", "dawn", "idle", 0.5, 165.0],
	"pepper": ["pepper", "Pepper the Dog", "hearth", "idle", 0.5, 135.0, 0.55],
	"biscuit": ["horse", "Biscuit the Horse", "meadow", "idle", 0.5, 120.0, 0.9],
	# The user asked for these three foes as well.
	"mara": ["mara", "Mara, Scourge of Bunsriel", "undead", "guard", 0.5, 160.0],
	"firebuns": ["firebuns", "Firebuns III, King of Batela Fells", "inferno", "raise", 0.5, 160.0, 1.1],
	"velloran": ["velloran", "Archmagus Velloran of the Sapphire Order", "sapphire", "idle", 0.5, 165.0],
}

## Cut-outs whose measured bounds miss part of the posed figure.
const CUT_FILL := {"firebuns": 0.6}

var _args := {}


func _ready() -> void:
	R96Poster.no_n64_mode(get_tree())
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var ids: Array = CAST.keys()
	if _args.has("who"):
		ids = Array(String(_args.who).split(","))
	if _args.has("list"):
		for id: String in ids:
			var m := _model(id)
			add_child(m)
			var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
			print("%s: %s  size %s" % [id, ap.get_animation_list() if ap else [], _bounds(m).size])
			m.queue_free()
		get_tree().quit()
		return
	var which: String = _args.get("aspect", "both")
	var aspects: Array = ["landscape", "portrait"] if which == "both" else [which]
	if _args.has("cutout"):
		aspects = ["cutout"]
	var dir: String = _args.get("dir", "res://promo/cards")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir)
	for id: String in ids:
		for asp: String in aspects:
			await _render(id, asp, dir)
	get_tree().quit()


func _model(id: String) -> Node3D:
	return (load("res://assets/models/%s.tscn" % CAST[id][0]) as PackedScene).instantiate() as Node3D


## The posed model's bounds (in its own space, it standing at the origin).
func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var b: AABB = root.global_transform.affine_inverse() * m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _render(id: String, asp: String, dir: String) -> void:
	var c: Array = CAST[id]
	var f: Dictionary = ASPECTS[asp]
	var th := _theme(String(c[2]))
	var scale := float(_args.get("scale", "1"))
	var size := Vector2i(Vector2(f.size) * scale)
	var holder := Node.new()
	add_child(holder)
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = asp == "cutout"
	holder.add_child(vp)
	var model := _model(id)
	vp.add_child(model)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var anim := String(c[3])
		# Cut-outs stand at rest (Firebuns' raised sword would shrink him).
		if asp == "cutout" and ap.has_animation("idle"):
			anim = "idle"
		if not ap.has_animation(anim):
			for a in ap.get_animation_list():
				if a != "RESET":
					anim = a
					break
		ap.play(anim)
		ap.seek(float(c[4]), true)
		ap.pause()
	model.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().process_frame
	# Frame the model: it fills `fill` of the picture's height, standing a
	# little above the name card.
	var box := _bounds(model)
	model.rotation_degrees.y = float(c[5])
	var h := maxf(box.size.y, 0.4)
	var long := maxf(box.size.x, box.size.z)
	var span := maxf(h, long * (0.75 if asp == "landscape" else 0.95))
	if asp == "cutout":
		# Lopsided props (a sword held out) reach further from the middle.
		var reach := maxf(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z)))
		span = maxf(h, reach * 2.0 * 1.33)
	var k := clampf(span / 1.8, 0.45, 1.8)
	_build_realm(vp, th, k, asp == "cutout")
	var fov: float = f.fov
	var half := deg_to_rad(fov) * 0.5
	var fill: float = float(f.fill) * (float(c[6]) if c.size() > 6 and asp != "cutout" else 1.0)
	if asp == "cutout":
		fill *= float(CUT_FILL.get(id, 1.0))
	var dist := (span / fill) * 0.5 / tan(half)
	var mid_y := box.position.y + h * 0.5
	# Aim a little above their middle, so they stand low in the frame, clear
	# of the card band (as in the Avalon picture).
	var at := Vector3(0, mid_y + span / fill * float(f.low), 0)
	var eye := at + Vector3(dist * 0.09, h * 0.05, dist)
	var cam := Camera3D.new()
	cam.fov = fov
	cam.far = 900.0
	vp.add_child(cam)
	cam.look_at_from_position(eye, at, Vector3.UP)
	cam.current = true
	if asp == "cutout":
		for i in 30:
			await RenderingServer.frame_post_draw
		var cut := vp.get_texture().get_image()
		cut.convert(Image.FORMAT_RGBA8)
		var cut_out := dir.path_join("%s%s.png" % [id, f.suffix])
		print("render_character_card: %s -> %s (%s)" % [id, cut_out, error_string(cut.save_png(cut_out))])
		holder.queue_free()
		await get_tree().process_frame
		return
	var card_vp := SubViewport.new()
	# Short names get the bigger lettering when they fit.
	var cs: int = f.card_scale
	if f.has("grow") and PixelFont.measure(String(c[1]), f.glyph).x + 40 <= f.size.x / (cs + 1):
		cs += 1
	card_vp.size = Vector2i(f.size.x / cs, f.size.y / cs)
	card_vp.transparent_bg = true
	card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(card_vp)
	var card := NameCard.new()
	card.text = String(c[1])
	card.glyph = f.glyph
	card.accent = th.accent
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
	var out := dir.path_join("%s%s.png" % [id, f.suffix])
	var err := img.save_png(out)
	print("render_character_card: %s -> %s (%s)" % [id, out, error_string(err)])
	holder.queue_free()
	await get_tree().process_frame


func _theme(name: String) -> Dictionary:
	var t: Array = THEMES[name]
	return {"mid": Color(t[0]), "edge": Color(t[1]), "glare": Color(t[2]), "accent": Color(t[3]), "floor": Color(t[4]),
		"shard": Color(t[5]), "shard_glow": Color(t[6]), "mote": Color(t[7]), "motes": String(t[8])}


# --- The realm -------------------------------------------------------------------------

## Sky, halo, floor, shards and motes, sized by `k` (1 = a grown-up's height).
func _build_realm(vp: SubViewport, th: Dictionary, k: float, cutout := false) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR if cutout else Environment.BG_COLOR
	env.background_color = th.mid.darkened(0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.74, 0.78).lerp(th.mid, 0.2)
	env.ambient_light_energy = 0.78
	env.glow_enabled = not cutout
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, 165, 0)
	key.light_color = Color(1.0, 0.97, 0.95)
	key.light_energy = 1.0
	vp.add_child(key)
	for side in [-1.0, 1.0]:
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = Vector3(-14, 28.0 * side, 0)
		rim.light_color = Color(1, 1, 1).lerp(th.edge, 0.55)
		rim.light_energy = 0.55
		vp.add_child(rim)
	var under := OmniLight3D.new()
	under.position = Vector3(0, 0.25, 0.6) * k
	under.light_color = Color(1, 1, 1).lerp(th.floor, 0.5)
	under.light_energy = 0.4
	under.omni_range = 3.0 * k
	vp.add_child(under)
	if cutout:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(th.mid.to_html())
	vp.add_child(_sky(rng, th))
	var near := Node3D.new()
	near.scale = Vector3.ONE * k
	vp.add_child(near)
	near.add_child(_halo(th))
	near.add_child(_floor(rng, th))
	near.add_child(_shards(rng, th))
	near.add_child(_motes(rng, th))


func _mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
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


## The sky's heart in the theme's main color, its edges and the ground in the
## other, a soft glare high on the left, and a scatter of stars.
func _sky(rng: RandomNumberGenerator, th: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Sky"
	const R := 120.0
	var clouds := SurfaceTool.new()
	clouds.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 150:
		var d := _rand_dir(rng)
		if i < 110:
			d = (Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(-0.7, 1.0), -1.0)).normalized()
		var edge := clampf(absf(d.x) * 1.5 + maxf(0.0, -d.y) * 1.2, 0.0, 1.0)
		var base: Color = th.mid if rng.randf() > edge else th.edge
		var col := base.lightened(rng.randf_range(-0.1, 0.15))
		col.a = rng.randf_range(0.12, 0.24)
		TitleScene._disc(clouds, d * (R + 6.0), -d, rng.randf_range(14.0, 34.0), col, Color(col, 0.0))
	for side in [-1.0, 1.0]:
		for i in 22:
			var t := float(i) / 21.0
			var d := Vector3(side * rng.randf_range(0.8, 1.5), lerpf(-0.7, 0.9, t), -1.0).normalized()
			var col := Color(th.edge, lerpf(0.16, 0.08, t))
			TitleScene._disc(clouds, d * (R + 4.0), -d, rng.randf_range(10.0, 20.0), col, Color(col, 0.0))
	var g := Vector3(-0.85, 0.75, -1.0).normalized()
	TitleScene._disc(clouds, g * (R + 2.0), -g, 22.0, Color(th.glare, 0.26), Color(th.glare, 0.0))
	TitleScene._disc(clouds, g * (R + 1.0), -g, 6.0, Color(th.glare, 0.5), Color(th.glare, 0.0))
	root.add_child(_mesh(clouds, _mat(true), "Nebula"))
	var stars := SurfaceTool.new()
	stars.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 1800:
		var d := _rand_dir(rng)
		var c := Color(1, 1, 1).lerp(th.glare, rng.randf()) * rng.randf_range(0.4, 0.9)
		c.a = 1.0
		TitleScene._quad(stars, d * R, -d, rng.randf_range(0.1, 0.24) * (2.0 if rng.randf() < 0.04 else 1.0), c)
	root.add_child(_mesh(stars, _mat(false), "Stars"))
	return root


## A great soft ring of light behind them, with eight faint points.
func _halo(th: Dictionary) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3(0, 1.3, -2.4)
	TitleScene._disc(st, c, Vector3.BACK, 2.7, Color(th.mid.lightened(0.3), 0.16), Color(th.edge, 0.0))
	TitleScene._disc(st, c, Vector3.BACK, 1.0, Color(th.glare, 0.1), Color(th.glare, 0.0))
	var seg := 64
	for ring in [[1.55, 1.585, 0.38], [1.85, 1.865, 0.2]]:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var col := Color(th.accent, ring[2])
			var p := [Vector3(cos(a0), sin(a0), 0), Vector3(cos(a1), sin(a1), 0)]
			var q := [c + p[0] * ring[0], c + p[1] * ring[0], c + p[1] * ring[1], c + p[0] * ring[1]]
			for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(col)
				st.add_vertex(v)
	for i in 8:
		var a := TAU * i / 8.0 + PI / 8.0
		var dir := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-sin(a), cos(a), 0) * 0.025
		var tip := c + dir * (3.3 if i % 2 == 0 else 2.4)
		for v in [c + side, tip, c - side]:
			st.set_color(Color(th.accent, 0.1))
			st.add_vertex(v)
	return _mesh(st, _mat(true), "Halo")


## The floor of light they stand on, ringed and marked with a star.
func _floor(rng: RandomNumberGenerator, th: Dictionary) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	TitleScene._disc(st, Vector3(0, -0.02, 0), Vector3.UP, 2.6, Color(th.floor, 0.3), Color(th.edge, 0.0))
	var seg := 64
	for ring in [[1.6, 1.66, 0.7], [1.15, 1.18, 0.55], [2.2, 2.22, 0.45]]:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p0 := Vector3(sin(a0), 0, cos(a0))
			var p1 := Vector3(sin(a1), 0, cos(a1))
			var q := [p0 * ring[0], p1 * ring[0], p1 * ring[1], p0 * ring[1]]
			for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.set_color(Color(th.floor, ring[2]))
				st.add_vertex(v)
	for i in 10:
		var a := TAU * i / 10.0
		var tip := Vector3(sin(a), 0, cos(a)) * (1.55 if i % 2 == 0 else 1.15)
		var side := Vector3(cos(a), 0, -sin(a)) * 0.06
		for v in [side, tip, -side]:
			st.set_color(Color(th.accent, 0.35))
			st.add_vertex(v + Vector3(0, 0.005, 0))
	return _mesh(st, _mat(true), "Floor")


## Crystal shards drifting round them, in the theme's tint.
func _shards(rng: RandomNumberGenerator, th: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Shards"
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.emission_enabled = true
	m.emission = th.shard_glow
	m.emission_energy_multiplier = 0.55
	m.roughness = 0.2
	m.metallic_specular = 0.9
	var spots := [Vector3(-1.9, 2.0, -1.2), Vector3(1.8, 1.7, -0.9), Vector3(-1.45, 0.55, -0.5), Vector3(1.6, 0.45, -1.5),
		Vector3(-2.8, 1.2, -3.0), Vector3(2.7, 2.4, -3.2), Vector3(-0.95, 2.7, -2.6), Vector3(1.0, 2.85, -1.8),
		Vector3(-3.4, 2.6, -5.0), Vector3(3.6, 0.9, -4.5), Vector3(-2.2, -0.2, -2.4), Vector3(2.4, -0.1, -2.0),
		Vector3(-1.05, 1.5, -2.2), Vector3(1.15, 1.25, -2.4)]
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
			var lit: Color = th.shard.lerp(th.shard.darkened(0.35), float(i % 2) * 0.6)
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


## Specks floating round them: stars, embers (with trails), snow, petals,
## dust, bubbles or leaves.
func _motes(rng: RandomNumberGenerator, th: Dictionary) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kind: String = th.motes
	var n := Vector3(0.1, 0.2, 1.0).normalized()
	for i in 200:
		var p := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-0.2, 3.2), rng.randf_range(-3.5, 1.5))
		if absf(p.x) < 0.55 and p.z > -0.6:
			continue
		var s := rng.randf_range(0.006, 0.02)
		var col: Color = th.mote * Color(1, 1, 1, rng.randf_range(0.5, 1.0))
		match kind:
			"petals", "leaves":
				# A small tilted kite.
				var a := rng.randf() * TAU
				var u := Vector3(cos(a), sin(a), 0.3).normalized() * s * 2.6
				var v := Vector3(-sin(a), cos(a), -0.2).normalized() * s * 1.3
				var pc := col if kind == "petals" else col.lerp(th.floor, 0.4)
				pc.a = minf(1.0, col.a + 0.2)
				for q in [p - u, p + v, p + u, p - u, p + u, p - v]:
					st.set_color(pc)
					st.add_vertex(q)
			"bubbles":
				TitleScene._disc(st, p, n, s * 3.0, Color(col, 0.0), Color(col, col.a * 0.7))
			_:
				TitleScene._disc(st, p, n, s * 3.0, Color(col, col.a * 0.5), Color(col, 0.0))
				if kind == "embers" and rng.randf() < 0.3:
					var up := Vector3(rng.randf_range(-0.02, 0.02), s * 9.0, 0)
					var w := Vector3(s * 0.5, 0, 0)
					st.set_color(col)
					st.add_vertex(p - w)
					st.add_vertex(p + w)
					st.set_color(Color(col, 0.0))
					st.add_vertex(p + up)
				else:
					TitleScene._quad(st, p, n, s * (1.6 if kind == "snow" else 1.0), col)
	return _mesh(st, _mat(true), "Motes")


# --- The name card --------------------------------------------------------------------

## A dark band along the bottom with the name across it in the game's pixel
## font, between two thin rules in the theme's accent.
class NameCard extends Control:
	var text := ""
	var glyph := 2
	var accent := Color(0.78, 0.86, 1.0)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var u := float(glyph) * 0.5
		var band := 78.0 * u
		for i in int(band):
			var t := float(i) / band
			draw_rect(Rect2(0, h - band + i, w, 1), Color(0.0, 0.0, 0.02, minf(t * 1.6, 0.84)))
		var scale := glyph
		var tw := PixelFont.measure(text, scale).x
		var x := floorf((w - tw) * 0.5)
		var y := floorf(h - 40.0 * u)
		var rule := minf(tw * 0.5 + 14.0 * u, w * 0.5 - 10.0)
		var above := y - roundf(8.0 * u)
		var below := y + 7 * glyph + roundf(7.0 * u)
		var col := Color(accent, 0.92)
		draw_rect(Rect2(w * 0.5 - rule, above, rule * 2, 1), col)
		draw_rect(Rect2(w * 0.5 - rule, below, rule * 2, 1), col)
		for sx in [-1.0, 1.0]:
			var cx: float = w * 0.5 + (rule + 5.0) * sx
			for cy: float in [above, below]:
				draw_rect(Rect2(cx - 1, cy - 2, 1, 5), col)
				draw_rect(Rect2(cx - 3, cy, 5, 1), col)
		PixelFont._draw_run(self, Vector2(x + scale, y + scale), text, Color(0, 0, 0, 0.85), scale, true)
		PixelFont._draw_run(self, Vector2(x, y), text, Color(1, 1, 1), scale, true)
