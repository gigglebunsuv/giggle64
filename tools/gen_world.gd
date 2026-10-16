extends RefCounted
## Builds the overworld: every region in tools/world/regions/ becomes
## res://scenes/areas/<id>.tscn, with its painted ground texture and sky in
## res://assets/textures/world/.
##
## Mood keys a region sets (tools/world/region.gd `mood`):
##   sky_top, sky_mid, sky_horizon  sky gradient (zenith, 30 deg, horizon)
##   cloud, cloud_amount            cloud color and cover (0..1)
##   fog, fog_begin, fog_end        fog color and depth range (m); also the clear color
##   ambient, sun, sun_rot          ambient color, key light color and rotation (deg)
##   fill, fill_energy              optional fill light (OoT light2)
##   horizon, hill_height, far      distant hill ring color/height and landmark list
##   particles                      "snow", "motes" or "dust"

const WorldKit := preload("res://tools/world/world_kit.gd")
const Media := preload("res://tools/gen_media.gd")
const REGIONS := [
	"field", "village", "castle_town", "forest", "hidden_forest", "marsh",
	"southern_fields", "desert", "cliffs", "snow", "south_road", "lake", "lake_house", "lake_shrine", "armory", "library", "shop", "hero_house", "himeko_house", "spring_alan", "spring_aphiel", "spring_serielye", "spring_lothelye_magic", "spring_lothelye_defense", "southern_tower", "ladhellin_tower", "skyreach_spire", "bog_tower", "castle_town_fallen", "castle",
	"frostpeak_hollow", "sun_trial", "forest_of_the_dead", "batela_fells", "sapphire_sanctum",
	"field_war", "village_refuge", "westmarch_fortress", "dark_forest", "temple_of_bun", "citadel_assault", "castle_town_rebuilt",
	"castle_town_restored", "barrow_of_kings", "cinderhold", "cinder_vault", "black_water_ridge", "ridge_keep",
	"sanctum_ruin", "astral_rift",
]
const TEX_DIR := "world/"
const SCENE_DIR := "res://scenes/areas/"


## REGIONS, or a comma-separated subset from the G64_REGIONS environment variable
## (handy while iterating on one area).
static func regions() -> Array:
	var env := OS.get_environment("G64_REGIONS")
	if env != "":
		return Array(env.split(","))
	# Every house you can walk into (HouseData, Beta 1.5.0) after the areas.
	return REGIONS + HouseData.HOUSES.keys()


static func region(id: String):
	if HouseData.has(id):
		var hi = load("res://tools/world/regions/house_interior.gd")
		hi.next_id = id
		return hi.new()
	return load("res://tools/world/regions/%s.gd" % id).new()


func run_media() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/textures/world"))
	var media := Media.new()
	for id in regions():
		var r = region(id)
		var t0 := Time.get_ticks_msec()
		media._save(r.paint_ground(), TEX_DIR + id + "_ground")
		media._save(paint_sky(r.mood, r.seed_value), TEX_DIR + id + "_sky")
		var maps := paint_maps(r)
		media._save(maps[0], TEX_DIR + id + "_map")
		media._save(maps[1], TEX_DIR + id + "_mini")
		# A dungeon of several storeys has a map of each (<id>_map_f<n>).
		if r.has_method("map_floor_count"):
			for f in r.map_floor_count():
				var fm := paint_maps(r, f)
				media._save(fm[0], TEX_DIR + "%s_map_f%d" % [id, f])
				media._save(fm[1], TEX_DIR + "%s_mini_f%d" % [id, f])
		print("gen_world: painted %s (%d ms)" % [id, Time.get_ticks_msec() - t0])
	media._save(paint_world_map(), TEX_DIR + "world_map")
	print("gen_world: painted the world map")


func run_scenes(shared: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/materials/world"))
	for id in regions():
		var t0 := Time.get_ticks_msec()
		var r = region(id)
		var mats := shared.duplicate()
		mats["ground_" + id] = _material("res://assets/textures/world/%s_ground.png" % id, "ground_" + id, false)
		mats["sky_" + id] = _material("res://assets/textures/world/%s_sky.png" % id, "sky_" + id, true)
		var scene: Node3D = WorldKit.new().build(r, mats)
		_save(scene, SCENE_DIR + id + ".tscn")
		print("gen_world: built %s (%d ms)" % [id, Time.get_ticks_msec() - t0])


func _material(tex_path: String, mat_name: String, sky: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if sky else BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.albedo_texture = load(tex_path)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.texture_repeat = false
	if sky:
		m.disable_fog = true
		m.disable_receive_shadows = true
	var path := "res://assets/materials/world/%s.tres" % mat_name
	ResourceSaver.save(m, path)
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


## Sky panorama, stretched once around the dome: u = heading, v = 90 deg (top)
## down to -10 deg (bottom); the horizon sits at v = 0.9. Painted clouds bunch
## up toward the horizon like the cloud skyboxes of the 1996-97 builds.
static func paint_sky(mood: Dictionary, seed_value: int) -> Image:
	var w := 256
	var hgt := 128
	var img := Image.create(w, hgt, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = seed_value + 400
	n.frequency = 1.0
	n.fractal_octaves = 4
	var top: Color = mood.sky_top
	var mid: Color = mood.get("sky_mid", top.lerp(mood.sky_horizon, 0.5))
	var hor: Color = mood.sky_horizon
	var cloud: Color = mood.get("cloud", Color(1, 1, 1))
	var amount: float = mood.get("cloud_amount", 0.4)
	var fog: Color = mood.fog
	for y in hgt:
		var elev := 90.0 - float(y) / hgt * 100.0
		var base: Color
		if elev > 30.0:
			base = mid.lerp(top, smoothstep(30.0, 90.0, elev))
		elif elev > 0.0:
			base = hor.lerp(mid, smoothstep(0.0, 30.0, elev))
		else:
			base = hor.lerp(fog, clampf(-elev / 6.0, 0.0, 1.0))
		for x in w:
			var a := TAU * x / w
			# Squash the noise toward the horizon so clouds read as receding layers.
			var squash := 1.0 / maxf(sin(deg_to_rad(maxf(elev, 2.0))), 0.08)
			var r := 1.6
			var v := n.get_noise_3d(cos(a) * r, sin(a) * r, elev * 0.045 * (1.0 + squash * 0.15))
			var density := amount * (0.6 + 0.6 * (1.0 - smoothstep(5.0, 70.0, elev)))
			var cm := smoothstep(0.55 - density, 0.75 - density, v * 0.5 + 0.5)
			if elev < -1.0:
				cm = 0.0
			var shade := n.get_noise_3d(cos(a) * r, sin(a) * r, elev * 0.045 + 0.35)
			var cc := cloud.darkened(clampf(0.25 - shade * 0.5, 0.0, 0.35))
			img.set_pixel(x, y, base.lerp(cc, cm * 0.92))
	return img


## Top-down maps of the area (north up, the play rectangle centered in a square):
## "<id>_map" in color for the pause screen, "<id>_mini" as a light silhouette
## that the HUD tints like OoT's minimap (G_IM_FMT_IA modulated by a prim color).
## Walkable ground is opaque; cliffs and the outside are transparent.
static func paint_maps(r, storey := -1) -> Array[Image]:
	var n := 128
	var colour := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var mini := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var side := maxf(r.x_max - r.x_min, r.z_max - r.z_min)
	var centre := Vector2((r.x_min + r.x_max) * 0.5, (r.z_min + r.z_max) * 0.5)
	var origin := centre - Vector2(side, side) * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for py in n:
		for px in n:
			var x: float = origin.x + (px + 0.5) / n * side
			var z: float = origin.y + (py + 0.5) / n * side
			colour.set_pixel(px, py, Color(0, 0, 0, 0))
			mini.set_pixel(px, py, Color(0, 0, 0, 0))
			if not r.inside(x, z):
				continue
			if storey >= 0:
				# One storey of a tower: its rooms, flat and evenly lit.
				if not r.map_walkable_floor(x, z, storey):
					continue
				var fc: Color = r.map_floor_color(x, z, storey, rng)
				colour.set_pixel(px, py, Color(fc.r, fc.g, fc.b, 1.0))
				var fv := clampf(0.5 + fc.get_luminance() * 1.1, 0.55, 1.0)
				mini.set_pixel(px, py, Color(fv, fv, fv, 0.8))
				continue
			var hh: float = r.height(x, z)
			var step := side / n
			var slope := (absf(r.height(x + step, z) - hh) + absf(r.height(x, z + step) - hh)) / step
			if slope > 1.4:
				continue
			if r.has_method("map_walkable") and not r.map_walkable(x, z):
				continue
			var wet := false
			for wt in r.water:
				var wr: Rect2 = wt.rect
				if wr.has_point(Vector2(x, z)) and hh < wt.y:
					wet = true
			var light := clampf(1.0 - (r.height(x + 1.0, z) - hh + r.height(x, z + 1.0) - hh) * 0.4, 0.6, 1.3)
			var col: Color = Color(0.3, 0.5, 0.85) if wet else r.ground_color(x, z, hh, rng)
			colour.set_pixel(px, py, Color(col.r * light, col.g * light, col.b * light, 1.0))
			# Brightness follows the ground color, so roads and rock read darker than grass.
			var lum := col.get_luminance()
			var v := clampf(0.5 + lum * 1.1, 0.55, 1.0) * clampf(light, 0.85, 1.1)
			mini.set_pixel(px, py, Color(v, v, v, 0.45 if wet else 0.8))
	# Dark outline around everything walkable, as on OoT's overworld minimaps.
	var src := mini.duplicate() as Image
	for py in n:
		for px in n:
			if src.get_pixel(px, py).a == 0.0:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(px, py) + o
				if q.x < 0 or q.y < 0 or q.x >= n or q.y >= n or src.get_pixelv(q).a == 0.0:
					mini.set_pixel(px, py, Color(0.2, 0.2, 0.25, 1.0))
					break
	return [colour, mini]


func _set_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		# Instanced scenes (the hero) keep their own internals.
		if child.scene_file_path == "":
			_set_owner(child, owner)


func _save(root: Node3D, path: String) -> void:
	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, path)
	if err != OK:
		push_error("Failed to save %s: %s" % [path, err])
	root.free()


# --- World map ----------------------------------------------------------------

const WORLD_MAP_SIZE := Vector2i(238, 153)

## The pause screen's overhead map of the whole land, in the spirit of OoT's
## painted Hyrule map (gWorldMapImageTex): the wild country between the regions
## colored after its nearest region and darkened, mountains round the edge,
## the roads and the snowmelt river, then every region's own top-down map
## (<id>_map.png) laid in its place on WorldData.MAP_LAYOUT's grid (WorldData.MAP_GRID), with
## a dark outline. North is up.
static func paint_world_map() -> Image:
	var size := WORLD_MAP_SIZE
	var px := size.x / WorldData.MAP_GRID.x
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 64
	n.frequency = 0.05
	n.fractal_octaves = 4
	var areas: Array = WorldData.MAP_LAYOUT.keys()
	# 1. Country: blend of the nearest regions' colors, darkened, hilly shading.
	for y in size.y:
		for x in size.x:
			var gp := Vector2((x + 0.5) / px, (y + 0.5) / px)
			var total := 0.0
			var col := Color(0, 0, 0)
			for a: String in areas:
				var r: Rect2 = WorldData.MAP_LAYOUT[a][0]
				var d := _rect_dist(gp, r)
				var wgt := 1.0 / pow(0.35 + d, 3.0)
				var c: Color = WorldData.MAP_LAYOUT[a][1]
				col += c * wgt
				total += wgt
			col /= total
			var hill := n.get_noise_2d(x, y)
			col = col.darkened(0.42 - hill * 0.18)
			# Mountains closing in at the edges of the land.
			var edge := minf(minf(gp.x, WorldData.MAP_GRID.x - gp.x), minf(gp.y, WorldData.MAP_GRID.y - gp.y))
			var m := 1.0 - smoothstep(0.0, 0.55 + hill * 0.25, edge)
			col = col.lerp(Color.html("6a5e52").lightened(hill * 0.3), m)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, 1.0))
	# 2. The snowmelt river from the summit through the field to the marsh.
	var river: Array[Vector2] = [Vector2(10.6, 1.0), Vector2(9.2, 2.4), Vector2(7.6, 3.6), Vector2(5.6, 4.4), Vector2(3.6, 4.6), Vector2(2.2, 4.5)]
	for i in river.size() - 1:
		_line(img, river[i] * px, river[i + 1] * px, 2.2, Color.html("3a6ac8"))
	# 3. Roads between linked regions.
	for road in WorldData.ROADS:
		_line(img, WorldData.map_point(road[0]) * px, WorldData.map_point(road[1]) * px, 1.6, Color.html("b89060"))
	# 4. Each region's own map laid over its place, outlined.
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	for a: String in areas:
		var path := ProjectSettings.globalize_path("res://assets/textures/world/%s_map.png" % a)
		var src := Image.load_from_file(path)
		if src == null or src.is_empty():
			continue
		src.convert(Image.FORMAT_RGBA8)
		var r: Rect2 = WorldData.MAP_LAYOUT[a][0]
		var side := maxf(r.size.x, r.size.y) * px
		var origin := r.get_center() * px - Vector2(side, side) * 0.5
		var x0 := maxi(int(origin.x), 0)
		var y0 := maxi(int(origin.y), 0)
		var x1 := mini(int(origin.x + side) + 1, size.x)
		var y1 := mini(int(origin.y + side) + 1, size.y)
		for y in range(y0, y1):
			for x in range(x0, x1):
				var u := (x + 0.5 - origin.x) / side
				var v := (y + 0.5 - origin.y) / side
				if u < 0.0 or v < 0.0 or u >= 1.0 or v >= 1.0:
					continue
				var c := src.get_pixel(int(u * src.get_width()), int(v * src.get_height()))
				if c.a < 0.5:
					continue
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
				mask[y * size.x + x] = 1
	for y in size.y:
		for x in size.x:
			if mask[y * size.x + x] == 1:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and mask[q.y * size.x + q.x] == 1:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.55))
					break
	return img


static func _rect_dist(p: Vector2, r: Rect2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


static func _line(img: Image, a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var steps := int(a.distance_to(b)) + 1
	var r := int(ceil(width))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		for oy in range(-r, r + 1):
			for ox in range(-r, r + 1):
				if Vector2(ox, oy).length() > width * 0.5 + 0.3:
					continue
				var q := Vector2i(int(p.x) + ox, int(p.y) + oy)
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
					img.set_pixelv(q, col)
