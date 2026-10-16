extends Node
## Renders the item icons for the HUD buttons and the pause pages from the
## items' own 3D meshes, the way OoT's icons are pictures of the models
## (assets/textures/icons/<name>.png, 64x64 with alpha).
##
## Each icon is drawn with an orthographic camera fitted to the mesh, at
## SUPERSAMPLE times the size, then shrunk (smooth edges) and given a soft
## dark rim so it reads on any button color.
##
## Run windowed (needs a GPU), then import:
##   Godot --path <project> res://tools/render_icons.tscn
##   Godot --headless --path <project> --import

const OUT_DIR := "res://assets/textures/icons/"
const SIZE := 64
const SUPERSAMPLE := 4

## name: [[mesh, euler degrees (applied Z * Y * X)], ...]. Several meshes
## share one framing.
var ICONS := {
	"sword_squire": [["sword_squire_mesh", Vector3(90, 90, -45)]],
	"sword_red": [["sword_red_mesh", Vector3(90, 90, -45)]],
	"sword_magical": [["sword_magical_mesh", Vector3(90, 90, -45)]],
	"sword_bun": [["sword_bun_mesh", Vector3(90, 90, -45)]],
	"sword_bun_awake": [["sword_bun_awake_mesh", Vector3(90, 90, -45)]],
	"sword_great": [["sword_great_mesh", Vector3(90, 90, -45)]],
	"shield_wooden": [["shield_wooden_flat_mesh", Vector3(70, -18, 0)]],
	"shield_iron": [["shield_iron_flat_mesh", Vector3(70, -18, 0)]],
	"shield_mirror": [["shield_mirror_flat_mesh", Vector3(70, -18, 0)]],
	"shield_questlord": [["shield_questlord_flat_mesh", Vector3(70, -18, 0)]],
	"trade_horseshoe": [["trade_horseshoe_mesh", Vector3(20, 0, 0)]],
	"trade_sketch": [["trade_sketch_mesh", Vector3(20, 0, 0)]],
	"trade_card": [["trade_card_mesh", Vector3(20, 0, 0)]],
	"trade_ledger": [["trade_ledger_mesh", Vector3(55, 20, 0)]],
	"trade_page": [["trade_page_mesh", Vector3(20, 0, 0)]],
	"trade_item": [["trade_horseshoe_mesh", Vector3(20, 0, 0)]],
	"bow": [["bow_mesh", Vector3(0, 90, 40)], ["arrow_mesh", Vector3(0, 90, -50)]],
	"boomerang": [["boomerang_mesh", Vector3(75, 0, 25)]],
	"rupee": [["rupee_green_mesh", Vector3(0, 25, 0)]],
	"small_key": [["small_key_mesh", Vector3(0, 20, -25)]],
	"hookshot": [["hookshot_mesh", Vector3(0, 90, 30)]],
	"sugar_cube": [["sugar_cube_mesh", Vector3(25, 30, 0)]],
	"heart_piece": [["heart_piece_mesh", Vector3(0, 0, 0)]],
	"heart_container": [["heart_container_mesh", Vector3(0, 0, 0)]],
	"big_wallet": [["big_wallet_mesh", Vector3(10, 20, 0)]],
	"quiver": [["quiver_mesh", Vector3(0, 30, 0)]],
	"bun_piece_alan": [["bun_piece_alan_mesh", Vector3(60, 0, 0)]],
	"bun_piece_serielye": [["bun_piece_serielye_mesh", Vector3(60, 0, 0)]],
	"bun_piece_aphiel": [["bun_piece_aphiel_mesh", Vector3(60, 0, 0)]],
	"boots_leather": [["boots_leather_mesh", Vector3(15, 35, 0)]],
	"boots_wind": [["boots_wind_mesh", Vector3(15, 35, 0)]],
	"bombs": [["bomb_mesh", Vector3(10, 20, 0)]],
	"bomb_bag": [["bomb_bag_mesh", Vector3(10, 20, 0)]],
	"bloom_rod": [["bloom_rod_mesh", Vector3(90, 90, -45)]],
	"bottle_empty": [["bottle_empty_mesh", Vector3(0, 20, -12)]],
	"bottle_fairy": [["bottle_fairy_mesh", Vector3(0, 20, -12)]],
	"bottle_milk": [["bottle_milk_mesh", Vector3(0, 20, -12)]],
	"bottle_half_milk": [["bottle_half_milk_mesh", Vector3(0, 20, -12)]],
	"bottle_red_potion": [["bottle_red_potion_mesh", Vector3(0, 20, -12)]],
	"bottle_fish": [["bottle_fish_mesh", Vector3(0, 20, -12)]],
	"sun_arrows": [["sun_arrow_mesh", Vector3(0, 90, -50)]],
	"frost_arrows": [["frost_arrow_mesh", Vector3(0, 90, -50)]],
	"puff_nuts": [["puff_nut_mesh", Vector3(10, 20, 0)]],
	"iron_mallet": [["iron_mallet_mesh", Vector3(90, 0, 35)]],
	"fishing_rod": [["fishing_rod_icon_mesh", Vector3(0, 0, 0)]],
	"lantern": [["lantern_mesh", Vector3(0, 20, 0)]],
	"starlight_lantern": [["starlight_lantern_mesh", Vector3(0, 20, 0)]],
	"looking_glass": [["looking_glass_mesh", Vector3(0, -15, -20)]],
	"alans_harvest": [["alans_harvest_mesh", Vector3(15, 0, 0)]],
	"aphiels_gale": [["aphiels_gale_mesh", Vector3(15, 0, 0)]],
	"serielyes_ruin": [["serielyes_ruin_mesh", Vector3(15, 0, 0)]],
	"magic": [["magic_large_mesh", Vector3(0, 20, 0)]],
	"tunic_haven": [["tunic_haven_mesh", Vector3(0, 0, 0)]],
	"tunic_tide": [["tunic_tide_mesh", Vector3(0, 0, 0)]],
	"tunic_frost": [["tunic_frost_mesh", Vector3(0, 0, 0)]],
	"tunic_shade": [["tunic_shade_mesh", Vector3(0, 0, 0)]],
	"tunic_regalia": [["tunic_regalia_mesh", Vector3(0, 0, 0)]],
	"bun_bracers": [["bun_bracers_mesh", Vector3(20, 0, 0)]],
	"silver_scale": [["silver_scale_mesh", Vector3(0, 0, 25)]],
	"golden_scale": [["golden_scale_mesh", Vector3(0, 0, 25)]],
	"giant_wallet": [["giant_wallet_mesh", Vector3(10, 20, 0)]],
	# Chapter IV.
	"grave_spade": [["grave_spade_mesh", Vector3(90, 0, 35)]],
	"sapphire_staff": [["sapphire_staff_mesh", Vector3(90, 0, 35)]],
	"starfall_arrows": [["starfall_arrow_mesh", Vector3(0, 90, -50)]],
	"astral_seal": [["astral_seal_mesh", Vector3(10, 0, 15)]],
	"longshot": [["longshot_mesh", Vector3(0, 90, 30)]],
	"boots_anchor": [["boots_anchor_mesh", Vector3(15, 35, 0)]],
	"chart_scrap": [["chart_scrap_mesh", Vector3(20, 0, 0)]],
	# Chapter V.
	"ember_rod": [["ember_rod_mesh", Vector3(90, 0, 35)]],
	"iron_flail": [["iron_flail_mesh", Vector3(70, 0, 30)]],
	"questlord_gauntlets": [["questlord_gauntlets_mesh", Vector3(20, 0, 0)]],
	"tunic_knight": [["tunic_knight_mesh", Vector3(0, 0, 0)]],
	"lothelyes_dream": [["lothelyes_dream_mesh", Vector3(0, 0, 0)]],
}

var _vp: SubViewport
var _cam: Camera3D
var _holder: Node3D


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE) * SUPERSAMPLE
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.62, 0.66)
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	# A warm key light from the upper left and a cool fill from the right.
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-35), 0)
	key.light_energy = 1.15
	key.light_color = Color(1.0, 0.96, 0.9)
	_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-10), deg_to_rad(120), 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.8, 0.85, 1.0)
	_vp.add_child(fill)
	_holder = Node3D.new()
	_vp.add_child(_holder)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_vp.add_child(_cam)
	_cam.current = true
	for icon: String in ICONS:
		await _render(icon, ICONS[icon])
	print("render_icons: saved %d icons" % ICONS.size())
	get_tree().quit()


func _render(icon: String, parts: Array) -> void:
	for c in _holder.get_children():
		c.free()
	var box := AABB()
	var first := true
	for part: Array in parts:
		var path := "res://assets/models/%s.tres" % part[0]
		if not ResourceLoader.exists(path):
			push_error("render_icons: missing %s" % path)
			return
		var mi := MeshInstance3D.new()
		mi.mesh = load(path)
		var e: Vector3 = part[1]
		mi.basis = Basis(Vector3.BACK, deg_to_rad(e.z)) * Basis(Vector3.UP, deg_to_rad(e.y)) * Basis(Vector3.RIGHT, deg_to_rad(e.x))
		_holder.add_child(mi)
		var b := mi.transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	# Center the picture and fit its larger side with a small margin.
	var centre := box.get_center()
	_cam.size = maxf(box.size.x, box.size.y) * 1.12
	_cam.position = Vector3(centre.x, centre.y, box.end.z + 5.0)
	_cam.near = 0.05
	_cam.far = box.size.z + 10.0
	for i in 4:
		await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	var out := _with_rim(img)
	var file := OUT_DIR + icon + ".png"
	out.save_png(ProjectSettings.globalize_path(file))
	_write_import(file)


## A soft dark rim one pixel round the picture (its alpha, dilated).
func _with_rim(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := 0.0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var sx := x + dx
					var sy := y + dy + 1
					if sx >= 0 and sy >= 0 and sx < w and sy < h:
						a = maxf(a, img.get_pixel(sx, sy).a)
			out.set_pixel(x, y, Color(0.05, 0.03, 0.02, a * 0.7))
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				out.set_pixel(x, y, out.get_pixel(x, y).blend(c))
	return out


## Lossless with mipmaps, so the HUD can shrink the icons smoothly.
func _write_import(file: String) -> void:
	var f := FileAccess.open(file + ".import", FileAccess.WRITE)
	f.store_string("""[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=0
mipmaps/generate=true
mipmaps/limit=-1
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=0
""" % file)
	f.close()
