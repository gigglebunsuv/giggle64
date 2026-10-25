extends SceneTree
## Regenerates every procedural asset in the project.
##
## Run via tools/build_assets.ps1, which performs, in order:
##   1. --script tools/build_assets.gd -- media   (textures + sounds)
##   2. --import                                   (import the new files)
##   3. --script tools/build_assets.gd -- scenes  (materials, models, environment)
##   4. --import                                   (register generated scenes)

const MAT_DIR := "res://assets/materials/"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var step: String = args[0] if args.size() > 0 else ""
	match step:
		"media":
			preload("res://tools/gen_media.gd").new().run()
			preload("res://tools/gen_world.gd").new().run_media()
		"scenes":
			var mats := _materials()
			preload("res://tools/gen_characters.gd").new().run(mats)
			preload("res://tools/gen_characters.gd").new().run_playable(mats)
			preload("res://tools/gen_items.gd").new().run(mats)
			preload("res://tools/gen_update_items.gd").new().run(mats)
			preload("res://tools/gen_tower_items.gd").new().run(mats)
			preload("res://tools/gen_fall_items.gd").new().run(mats)
			preload("res://tools/gen_night_items.gd").new().run(mats)
			preload("res://tools/gen_satchel_items.gd").new().run(mats)
			preload("res://tools/gen_beta_items.gd").new().run(mats)
			preload("res://tools/gen_fells_items.gd").new().run(mats)
			preload("res://tools/gen_ch4_items.gd").new().run(mats)
			preload("res://tools/gen_ch5_items.gd").new().run(mats)
			preload("res://tools/gen_ridge_items.gd").new().run(mats)
			preload("res://tools/gen_final_items.gd").new().run(mats)
			preload("res://tools/remaster_items.gd").new().run()
			preload("res://tools/gen_creatures.gd").new().run(mats)
			preload("res://tools/gen_shrine_creatures.gd").new().run(mats)
			preload("res://tools/gen_tower_creatures.gd").new().run(mats)
			preload("res://tools/gen_desert_creatures.gd").new().run(mats)
			preload("res://tools/gen_sky_creatures.gd").new().run(mats)
			preload("res://tools/gen_bog_creatures.gd").new().run(mats)
			preload("res://tools/gen_castle_creatures.gd").new().run(mats)
			preload("res://tools/gen_beta_creatures.gd").new().run(mats)
			preload("res://tools/gen_fells_creatures.gd").new().run(mats)
			preload("res://tools/gen_ch4_creatures.gd").new().run(mats)
			preload("res://tools/gen_ch5_creatures.gd").new().run(mats)
			preload("res://tools/gen_ridge_creatures.gd").new().run(mats)
			preload("res://tools/gen_final_creatures.gd").new().run(mats)
			preload("res://tools/gen_environment.gd").new().run(mats)
			preload("res://tools/gen_world.gd").new().run_scenes(mats)
		"chars":
			# Quick rebuild of the character models alone (while working on them).
			preload("res://tools/gen_characters.gd").new().run(_materials())
			preload("res://tools/remaster_items.gd").new().run()
		"hero":
			# Quick rebuild of the hero's model and gear alone.
			preload("res://tools/gen_characters.gd").new().run_hero(_materials())
			preload("res://tools/remaster_items.gd").new().run()
		"playable":
			# The co-op companions (playable_<id>.tscn) alone.
			preload("res://tools/gen_characters.gd").new().run_playable(_materials())
			preload("res://tools/remaster_items.gd").new().run()
		"items":
			# Quick rebuild of the update's item meshes alone.
			var mats := _materials()
			preload("res://tools/gen_update_items.gd").new().run(mats)
			preload("res://tools/gen_tower_items.gd").new().run(mats)
			preload("res://tools/gen_fall_items.gd").new().run(mats)
			preload("res://tools/gen_night_items.gd").new().run(mats)
			preload("res://tools/gen_satchel_items.gd").new().run(mats)
			preload("res://tools/gen_beta_items.gd").new().run(mats)
			preload("res://tools/gen_fells_items.gd").new().run(mats)
			preload("res://tools/gen_ch4_items.gd").new().run(mats)
			preload("res://tools/gen_ch5_items.gd").new().run(mats)
			preload("res://tools/gen_ridge_items.gd").new().run(mats)
			preload("res://tools/gen_final_items.gd").new().run(mats)
			preload("res://tools/remaster_items.gd").new().run()
		"world":
			# Quick rebuild of the area scenes alone (G64_REGIONS picks some).
			preload("res://tools/gen_world.gd").new().run_scenes(_materials())
		"creatures":
			# Quick rebuild of the creature models and enemy scenes alone.
			var mats := _materials()
			preload("res://tools/gen_creatures.gd").new().run(mats)
			preload("res://tools/gen_shrine_creatures.gd").new().run(mats)
			preload("res://tools/gen_tower_creatures.gd").new().run(mats)
			preload("res://tools/gen_desert_creatures.gd").new().run(mats)
			preload("res://tools/gen_sky_creatures.gd").new().run(mats)
			preload("res://tools/gen_bog_creatures.gd").new().run(mats)
			preload("res://tools/gen_castle_creatures.gd").new().run(mats)
			preload("res://tools/gen_beta_creatures.gd").new().run(mats)
			preload("res://tools/gen_fells_creatures.gd").new().run(mats)
			preload("res://tools/gen_ch4_creatures.gd").new().run(mats)
			preload("res://tools/gen_ch5_creatures.gd").new().run(mats)
			preload("res://tools/gen_ridge_creatures.gd").new().run(mats)
			preload("res://tools/gen_final_creatures.gd").new().run(mats)
		"remaster":
			# Paint the item and gear meshes again (tools/remaster_items.gd).
			preload("res://tools/remaster_items.gd").new().run()
		_:
			push_error("Usage: -- media | scenes | chars | hero | playable | items | creatures | world | remaster")
	print("build_assets: finished step '%s'" % step)
	quit()


func _materials() -> Dictionary:
	var mats := {
		"char": _vc_material(),
		"glow": _vc_material("", true),
		"face_gigglebuns": _vc_material("face_gigglebuns"),
		"face_goblin": _vc_material("face_goblin"),
		"face_mira": _vc_material("face_mira"),
		"face_pink": _vc_material("face_pink"),
		"face_aladriel": _vc_material("face_aladriel"),
		"face_idrith": _vc_material("face_idrith"),
		"face_ottilie": _vc_material("face_ottilie"),
		"face_marigold": _vc_material("face_marigold"),
		"face_clover": _vc_material("face_clover"),
		"face_firebuns": _vc_material("face_firebuns"),
		"face_mage": _vc_material("face_mage"),
		"face_lothelye": _vc_material("face_lothelye"),
		"face_himeko": _vc_material("face_himeko"),
		"face_hilde": _vc_material("face_hilde"),
		"face_tansy": _vc_material("face_tansy"),
		"face_maud": _vc_material("face_maud"),
		"face_wren": _vc_material("face_wren"),
		"face_odile": _vc_material("face_odile"),
		"face_tamsin": _vc_material("face_tamsin"),
		"face_rowena": _vc_material("face_rowena"),
		"face_soldier": _vc_material("face_soldier"),
		"face_posy": _vc_material("face_posy"),
		"face_mara": _vc_material("face_mara"),
		"face_avalon": _vc_material("face_avalon"),
		"face_serielye": _vc_material("face_serielye"),
		"ground": _vc_material("terrain"),
		"cliff": _vc_material("cliff"),
		"stone": _vc_material("stone_brick"),
		"rock": _vc_material("rock"),
		"bark": _vc_material("bark"),
		"leaves": _vc_material("leaves"),
		"wood": _vc_material("wood"),
		"plaster": _vc_material("plaster"),
		"timber": _vc_material("timber"),
		"roof": _vc_material("roof_tiles"),
		"thatch": _vc_material("thatch"),
		"sandstone": _vc_material("sandstone"),
		"snow": _vc_material("snow"),
		"ice": _vc_material("ice"),
		"door": _vc_material("door"),
		"seal": _vc_material("seal"),
		"pine": _vc_material("pine"),
		"cliff_rock": _vc_material("cliff_rock"),
		"cobble": _vc_material("cobble"),
		"shrine": _vc_material("shrine_wall"),
		"coral": _vc_material("coral"),
	}
	var water := _vc_material("water")
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	mats.water = water
	# Polished metal (the Magical and Bun Swords, the Mirror Shield).
	var chrome := ShaderMaterial.new()
	chrome.shader = load("res://assets/shaders/chrome.gdshader")
	chrome.set_shader_parameter("env_tex", load("res://assets/textures/chrome_env.png"))
	mats.chrome = chrome
	# Fog-colored curtain at the far end of exit corridors.
	mats.veil = _vc_material("", true)
	var shadow := _vc_material("", true)
	shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.cull_mode = BaseMaterial3D.CULL_DISABLED
	mats.shadow = shadow
	var sky := _vc_material("", true)
	sky.disable_fog = true
	sky.disable_receive_shadows = true
	mats.sky = sky
	# Beta 1.5.0's townsfolk faces (tools/folk_specs.gd).
	for fid: String in preload("res://tools/folk_specs.gd").ids():
		mats["face_" + fid] = _vc_material("face_" + fid)
	# Save and reload so meshes reference shared external material files.
	var out := {}
	for key in mats:
		var path: String = MAT_DIR + key + ".tres"
		var err := ResourceSaver.save(mats[key], path)
		if err != OK:
			push_error("Failed to save material %s" % path)
		out[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return out


## Simple N64-style material: vertex colors, Gouraud (per-vertex) lighting,
## no specular, and an optional small texture stretched across the surface.
func _vc_material(texture := "", unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	m.metallic_specular = 0.0
	if texture != "":
		m.albedo_texture = load("res://assets/textures/%s.png" % texture)
		# The N64 RDP sampled textures bilinearly with no mipmaps (OoT almost never
		# used texture LOD); repeat is off so textures stretch.
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		m.texture_repeat = false
	return m
