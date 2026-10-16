extends Node
## Renders the Gauntlet of Fire model into the title screen picture that sits
## behind the G of the logo (assets/textures/title_gauntlet.png).
##
## It renders at SUPERSAMPLE times the final size with a transparent background,
## shrinks the result (smooth edges like the hand-made logo) and adds a soft
## dark shadow so it reads over the moving scenery.
##
## Run windowed (needs a GPU), then import:
##   Godot --path <project> res://tools/render_title_art.tscn
##   Godot --headless --path <project> --import

const MESH := "res://assets/models/gauntlet_mesh.tres"
const OUT := "res://assets/textures/title_gauntlet.png"
## Final picture size in 320x240 screen pixels.
const SIZE := Vector2i(80, 116)
const SUPERSAMPLE := 6


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = SIZE * SUPERSAMPLE
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.42, 0.4)
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	# Warm key light from the upper left, and a fiery rim from behind on the right.
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35), deg_to_rad(200), 0)
	key.light_color = Color(1.0, 0.92, 0.8)
	key.light_energy = 1.1
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-10), deg_to_rad(-40), 0)
	rim.light_color = Color(1.0, 0.45, 0.15)
	rim.light_energy = 0.9
	vp.add_child(rim)
	var mi := MeshInstance3D.new()
	mi.mesh = load(MESH)
	# Raised fist, tipped a little to the right and turned to show its thumb side.
	mi.rotation = Vector3(deg_to_rad(8), deg_to_rad(-28), deg_to_rad(-14))
	vp.add_child(mi)
	var cam := Camera3D.new()
	cam.fov = 24
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.36, -1.9), Vector3(0.0, 0.34, 0), Vector3.UP)
	cam.current = true
	for i in 6:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var out := _with_shadow(img)
	var err := out.save_png(ProjectSettings.globalize_path(OUT))
	print("render_title_art: saved %s (%s)" % [OUT, error_string(err)])
	vp.queue_free()
	await _render_knight()
	get_tree().quit()


## Knight Gigglebuns (Chapter V's title art, assets/textures/title_knight.png):
## the hero in the Knight's Tabard and cape, the awakened Bun Sword raised
## overhead, standing to the left under the logo.
const KNIGHT_OUT := "res://assets/textures/title_knight.png"
const KNIGHT_SIZE := Vector2i(66, 112)


func _render_knight() -> void:
	var vp := SubViewport.new()
	vp.size = KNIGHT_SIZE * SUPERSAMPLE
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.48, 0.6)
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-30), deg_to_rad(160), 0)
	key.light_color = Color(1.0, 0.92, 0.82)
	key.light_energy = 1.2
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-15), deg_to_rad(-20), 0)
	rim.light_color = Color(0.6, 0.75, 1.0)
	rim.light_energy = 0.9
	vp.add_child(rim)
	var hero: CharacterModel = (load("res://assets/models/sir_gigglebuns.tscn") as PackedScene).instantiate()
	vp.add_child(hero)
	hero.set_gear("bun", "questlord")
	hero.set_outfit("haven", "knight")
	hero.set_sword_drawn(true)
	hero.rotation.y = deg_to_rad(22)
	hero.play(&"jumpslash", 0.0, 1.0, true)
	for i in 3:
		await RenderingServer.frame_post_draw
	hero.anim.seek(0.42, true)
	hero.anim.pause()
	var cam := Camera3D.new()
	cam.fov = 24
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0.6, 1.3, -7.6), Vector3(0.0, 1.25, 0), Vector3.UP)
	cam.current = true
	for i in 8:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(KNIGHT_SIZE.x, KNIGHT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var err := _with_shadow(img).save_png(ProjectSettings.globalize_path(KNIGHT_OUT))
	print("render_title_art: saved %s (%s)" % [KNIGHT_OUT, error_string(err)])


## Puts a soft dark shadow (blurred, nudged down-right) under the picture.
func _with_shadow(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := 0.0
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var sx := x - 1 + dx
					var sy := y - 1 + dy
					if sx >= 0 and sy >= 0 and sx < w and sy < h:
						a += img.get_pixel(sx, sy).a
			out.set_pixel(x, y, Color(0.08, 0.02, 0.02, minf(a / 25.0 * 1.3, 1.0) * 0.75))
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var under := out.get_pixel(x, y)
				out.set_pixel(x, y, under.blend(c))
	return out
