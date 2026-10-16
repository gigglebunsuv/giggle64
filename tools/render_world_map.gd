extends Node
## Renders a straight-down orthographic picture of each outdoor region of Haven
## from its real geometry, for the printable world map (make_world_map.py in
## _giggle64_work/tools). Noon, no rain, no fog, sky dome, corridor veils,
## hero or enemies. Also writes layout.json: each region's play rectangle, its
## exits (target + position) and its dungeon map icons, in meters.
##
## Run windowed (needs a GPU):
##   Godot --path <project> res://tools/render_world_map.tscn [-- --areas=field,lake --ppm=10]

const REGIONS := ["field", "village", "castle_town", "forest", "hidden_forest", "marsh",
	"southern_fields", "desert", "cliffs", "snow", "south_road", "lake",
	"forest_of_the_dead", "batela_fells", "dark_forest", "cinderhold", "black_water_ridge"]
const OUT_DIR := "G:/Games/Godot Games/_giggle64_work/tmp/worldmap/"
## Pixels per meter in the saved pictures.
var ppm := 10.0
## Largest side of one rendered tile (big regions are drawn in tiles).
const TILE := 4096

var _main: Node


func _ready() -> void:
	var areas: Array = REGIONS.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--areas="):
			areas = Array(a.substr(8).split(","))
		elif a.begins_with("--ppm="):
			ppm = float(a.substr(6))
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	GameManager.skip_title = true
	GameManager.automation = true
	var layout := {}
	var f_old := FileAccess.open(OUT_DIR + "layout.json", FileAccess.READ)
	if f_old:
		var parsed: Variant = JSON.parse_string(f_old.get_as_text())
		if parsed is Dictionary:
			layout = parsed
		f_old.close()
	for area: String in areas:
		await _load(area)
		await _frames(40)
		layout[area] = await _shot(area)
	var f := FileAccess.open(OUT_DIR + "layout.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(layout, "  "))
	f.close()
	print("render_world_map: %d regions" % areas.size())
	get_tree().quit()


func _load(area: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = ""
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)


func _shot(area: String) -> Dictionary:
	DayNight.set_hour(12.5)
	DayNight.frozen = true
	Weather.amount = 0.0
	var p: PlayerController = GameManager.player
	if p:
		p.visible = false
	var root: Node3D = World.area_node
	for n in ["SkyDome", "Enemies", "CameraRig"]:
		var c := root.get_node_or_null(n) as Node3D
		if c:
			c.visible = false
	# One even light for every region (the moody areas are near black from
	# above): a soft white ambient and a sun from the north-west.
	for n in root.find_children("*", "WorldEnvironment", true, false):
		var env := (n as WorldEnvironment).environment
		if env:
			env.fog_enabled = false
			env.volumetric_fog_enabled = false
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(1, 1, 1)
			env.ambient_light_energy = 0.55
			env.adjustment_enabled = false
			env.glow_enabled = false
	for n in root.find_children("*", "DirectionalLight3D", true, false):
		(n as DirectionalLight3D).visible = false
	var sun := DirectionalLight3D.new()
	sun.name = "MapSun"
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 800.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	root.add_child(sun)
	sun.rotation = Vector3(deg_to_rad(-60.0), deg_to_rad(45.0), 0.0)
	DayNight.frozen = true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m and m.resource_path.contains("veil"):
				mi.visible = false
	var R = load("res://tools/world/regions/%s.gd" % area).new()
	# The play rectangle plus the exit corridors running out past it.
	var x0: float = R.x_min - 12.0
	var x1: float = R.x_max + 12.0
	var z0: float = R.z_min - 12.0
	var z1: float = R.z_max + 12.0
	var w := int(ceil((x1 - x0) * ppm))
	var h := int(ceil((z1 - z0) * ppm))
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var tiles_x := int(ceil(float(w) / TILE))
	var tiles_y := int(ceil(float(h) / TILE))
	var tw := int(ceil(float(w) / tiles_x))
	var th := int(ceil(float(h) / tiles_y))
	var game_vp := root.get_viewport()
	for ty in tiles_y:
		for tx in tiles_x:
			var vp := SubViewport.new()
			vp.size = Vector2i(tw, th)
			vp.world_3d = game_vp.find_world_3d()
			vp.msaa_3d = Viewport.MSAA_4X
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			add_child(vp)
			var cam := Camera3D.new()
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.keep_aspect = Camera3D.KEEP_HEIGHT
			cam.size = th / ppm
			cam.near = 1.0
			cam.far = 1200.0
			vp.add_child(cam)
			var cx := x0 + (tx * tw + tw * 0.5) / ppm
			var cz := z0 + (ty * th + th * 0.5) / ppm
			cam.global_position = Vector3(cx, 500.0, cz)
			cam.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
			cam.current = true
			await _frames(10)
			var part := vp.get_texture().get_image()
			part.convert(Image.FORMAT_RGB8)
			var cw := mini(tw, w - tx * tw)
			var ch := mini(th, h - ty * th)
			img.blit_rect(part, Rect2i(0, 0, cw, ch), Vector2i(tx * tw, ty * th))
			vp.queue_free()
			await _frames(2)
	img.save_png(OUT_DIR + area + ".png")
	var exits := []
	var ex := root.get_node_or_null("Exits")
	if ex:
		for e in ex.get_children():
			var gp := (e as Node3D).global_position
			exits.append({"to": str(e.get("target_area")), "entrance": str(e.get("target_entrance")),
				"pos": [gp.x, gp.z]})
	var icons := []
	var ic := root.get_node_or_null("MapIcons")
	if ic:
		for i in ic.get_children():
			var gp := (i as Node3D).global_position
			icons.append({"name": String(i.name), "pos": [gp.x, gp.z], "meta": _metas(i)})
	var links := []
	for l in R.links:
		links.append({"to": l.to, "p": [l.p.x, l.p.y], "d": [l.d.x, l.d.y], "w": l.w})
	return {"rect": [R.x_min, R.z_min, R.x_max, R.z_max], "image_rect": [x0, z0, x1, z1],
		"ppm": ppm, "links": links, "exits": exits, "icons": icons}


func _metas(n: Node) -> Dictionary:
	var d := {}
	for k in n.get_meta_list():
		d[k] = str(n.get_meta(k))
	return d


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
