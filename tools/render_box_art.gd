extends Node
## Renders the layers for the box art and the OST album cover (put together by
## _giggle64_work/tools/make_box_art.py). Each layer is a PNG: an area backdrop
## seen from a camera, or a posed model on a transparent background.
##
## Run windowed (needs a GPU), one shot per run:
##   Godot --path <project> res://tools/render_box_art.tscn -- --shot=<name> --out=<png> [--scale=1]
## Shots live in SHOTS below. "area" shots load scenes/areas/<area>.tscn; "model"
## shots load a character scene (or a mesh) alone with their own lights.

const SHOTS := {
	# Old Castle Town after the fall, looking up the high street to the castle.
	"box_bg": {"type": "area", "area": "castle_town_fallen", "size": Vector2i(2720, 2000), "clear_sky": true,
		"eye": Vector3(1.5, 1.4, -7.0), "at": Vector3(0.0, 17.0, -66.0), "fov": 56.0,
		"grade": {"fog": Color(0.42, 0.18, 0.12), "fog_begin": 30.0, "fog_end": 160.0,
			"ambient": Color(0.62, 0.38, 0.32), "sun": Color(1.0, 0.55, 0.3), "sun_energy": 1.1,
			"sun_rot": Vector3(-14.0, 160.0, 0.0)}},
	# The fallen town from the square, castle ahead (album cover).
	"cover_bg": {"type": "area", "area": "castle_town_fallen", "size": Vector2i(2400, 2400), "clear_sky": true,
		"eye": Vector3(-2.0, 3.0, 16.0), "at": Vector3(0.0, 26.0, -66.0), "fov": 56.0,
		"grade": {"fog": Color(0.36, 0.2, 0.22), "fog_begin": 40.0, "fog_end": 220.0,
			"ambient": Color(0.5, 0.36, 0.4), "sun": Color(1.0, 0.5, 0.28), "sun_energy": 0.9,
			"sun_rot": Vector3(-8.0, 0.0, 0.0)}},
	# Sir Gigglebuns on guard: Bun Sword up, Mirror Shield forward.
	"hero": {"type": "model", "scene": "res://assets/models/sir_gigglebuns.tscn", "size": Vector2i(2000, 2500),
		"anim": "block", "time": 0.3, "sword": "bun", "shield": "mirror", "drawn": true,
		"yaw": 160.0, "eye": Vector3(0.0, 1.05, 3.8), "at": Vector3(0.0, 1.0, 0.0), "fov": 34.0},
	# The same pose from behind (album cover: he faces the castle).
	"hero_back": {"type": "model", "scene": "res://assets/models/sir_gigglebuns.tscn", "size": Vector2i(2000, 2500),
		"anim": "item_get", "time": 0.8, "sword": "bun", "shield": "mirror", "drawn": true,
		"yaw": 20.0, "eye": Vector3(0.0, 1.05, 3.8), "at": Vector3(0.0, 1.0, 0.0), "fov": 34.0},
	# Firebuns III, sword raised, pointing down at the hero.
	"firebuns": {"type": "model", "scene": "res://assets/models/firebuns.tscn", "size": Vector2i(2000, 2500),
		"anim": "point", "time": 0.6, "flame": true,
		"yaw": 165.0, "eye": Vector3(0.0, 1.4, 5.2), "at": Vector3(0.0, 1.25, 0.0), "fov": 36.0,
		"key": Color(1.0, 0.55, 0.3), "rim": Color(1.0, 0.3, 0.1)},
	# The Gauntlet of Fire on its own.
	"gauntlet": {"type": "mesh", "mesh": "res://assets/models/gauntlet_mesh.tres", "size": Vector2i(2000, 2500),
		"rot": Vector3(8.0, -28.0, -14.0), "eye": Vector3(0.0, 0.36, -1.9), "at": Vector3(0.0, 0.34, 0.0), "fov": 24.0,
		"key": Color(1.0, 0.85, 0.7), "rim": Color(1.0, 0.4, 0.12)},
	# Avalon, Keeper of the Stars, hands on the Luminous Blade.
	"avalon": {"type": "model", "scene": "res://assets/models/avalon.tscn", "size": Vector2i(1600, 2000),
		"anim": "idle", "time": 0.0, "yaw": 180.0, "eye": Vector3(0.0, 1.0, 3.6), "at": Vector3(0.0, 0.95, 0.0), "fov": 34.0,
		"key": Color(1.0, 0.97, 0.94), "rim": Color(0.6, 0.75, 1.0)},
	# The Bun Sword on its own, broadside (blade along -Z), for the box front.
	"bun_sword": {"type": "mesh", "mesh": "res://assets/models/sword_bun_mesh.tres", "size": Vector2i(3000, 900),
		"rot": Vector3(0.0, 0.0, 0.0), "eye": Vector3(2.6, 0.0, -0.5), "at": Vector3(0.0, 0.0, -0.5), "fov": 26.0,
		"key": Color(1.0, 0.95, 0.85), "rim": Color(1.0, 0.6, 0.2)},
}

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var name: String = _args.get("shot", "box_bg")
	var s: Dictionary = SHOTS[name].duplicate(true)
	for k in ["eye", "at"]:
		if _args.has(k):
			var p: PackedStringArray = (_args[k] as String).split(",")
			s[k] = Vector3(float(p[0]), float(p[1]), float(p[2]))
	for k in ["fov", "time", "yaw"]:
		if _args.has(k):
			s[k] = float(_args[k])
	if _args.has("anim"):
		s["anim"] = _args["anim"]
	var scale := float(_args.get("scale", "1"))
	var size := Vector2i(Vector2(s["size"]) * scale)
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.transparent_bg = s["type"] != "area" or s.get("clear_sky", false)
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	match s["type"]:
		"area":
			_stage_area(vp, s)
		"model":
			_stage_model(vp, s)
		"mesh":
			_stage_mesh(vp, s)
	var cam := Camera3D.new()
	cam.fov = s["fov"]
	cam.far = 900.0
	vp.add_child(cam)
	cam.look_at_from_position(s["eye"], s["at"], Vector3.UP)
	cam.current = true
	for i in 30:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var out: String = _args.get("out", "user://box_%s.png" % name)
	var err := img.save_png(out)
	print("render_box_art: %s -> %s (%s)" % [name, out, error_string(err)])
	get_tree().quit()


func _stage_area(vp: SubViewport, s: Dictionary) -> void:
	var node := (load(WorldData.scene_path(s["area"])) as PackedScene).instantiate() as Node3D
	vp.add_child(node)
	for n in node.find_children("*", "Npc", true, false):
		(n as Node3D).visible = false
	if s.get("clear_sky", false):
		var dome := node.get_node_or_null("SkyDome") as Node3D
		if dome:
			dome.visible = false
	var m: Dictionary = s.get("grade", {})
	if m.is_empty():
		return
	var we := node.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment.duplicate() as Environment
		env.background_color = m.fog
		env.fog_light_color = m.fog
		env.fog_depth_begin = m.fog_begin
		env.fog_depth_end = m.fog_end
		env.ambient_light_color = m.ambient
		if s.get("clear_sky", false):
			env.background_mode = Environment.BG_CLEAR_COLOR
		we.environment = env
	var sun := node.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = m.sun
		sun.light_energy = m.sun_energy
		sun.rotation_degrees = m.sun_rot


func _lights(vp: SubViewport, s: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = s.get("ambient", Color(0.5, 0.42, 0.42))
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35), deg_to_rad(200), 0)
	key.light_color = s.get("key", Color(1.0, 0.93, 0.82))
	key.light_energy = 1.15
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-10), deg_to_rad(-40), 0)
	rim.light_color = s.get("rim", Color(1.0, 0.45, 0.15))
	rim.light_energy = 1.0
	vp.add_child(rim)


func _stage_model(vp: SubViewport, s: Dictionary) -> void:
	_lights(vp, s)
	var model := (load(s["scene"]) as PackedScene).instantiate() as Node3D
	vp.add_child(model)
	model.rotation_degrees.y = s.get("yaw", 180.0)
	if model.has_method("set_gear") and s.has("sword"):
		model.call("set_gear", s["sword"], s["shield"])
	if model.has_method("set_sword_drawn") and s.has("drawn"):
		model.call("set_sword_drawn", s["drawn"])
	var flame := model.find_child("GauntletFlame", true, false) as Node3D
	if flame:
		flame.visible = s.get("flame", false)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and s.has("anim"):
		ap.play(s["anim"])
		ap.seek(s.get("time", 0.0), true)
		ap.pause()
	model.process_mode = Node.PROCESS_MODE_DISABLED


func _stage_mesh(vp: SubViewport, s: Dictionary) -> void:
	_lights(vp, s)
	var mi := MeshInstance3D.new()
	mi.mesh = load(s["mesh"])
	mi.rotation_degrees = s["rot"]
	vp.add_child(mi)
