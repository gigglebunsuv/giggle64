extends Node
## TRUE N64 MODE (GRAPHICS option, Beta 1.3.1; off by default): draws the game
## the way the N64's Reality Display Processor and Video Interface would.
##
## Already true of the game in every mode (and left alone here): 320x240 output
## upscaled softly, depth (range) fog, per-vertex (Gouraud) lighting on the
## generated models, small stretched textures with no mipmaps, low polygon
## counts, perspective-correct texturing.
##
## What the mode adds:
## - TEXTURES (the RDP's texture unit): every textured material is drawn by a
##   shader (n64_surface) that fetches texels itself and blends them with the
##   RDP's 3-point (triangular) filter: of the four texels round the sample
##   point it uses the three of the triangle the point falls in, which gives
##   the N64's hexagonal "rupee" blur instead of the diamond of 4-point
##   bilinear. Texels are first cut to 16 bits (RGBA5551), as in TMEM. A
##   texture over 64 x 64 (TMEM's 4 KB) is shrunk to fit, except the painted
##   terrain (and the skies), which keep their size (the user's choice: the
##   terrain is one stretched picture, and shrinking it would turn it to mush).
##   N64 MIPMAPS (its own option) adds the 2-cycle LOD blend: past one texel
##   per pixel the sample fades toward the next, half-size level (each of its
##   texels the average of four), like the RDP's trilinear mode.
##   Lit surfaces are lit per vertex (Gouraud) in every case here.
## - THE FRAMEBUFFER (n64_post, a full-screen pass over the finished 320x240
##   picture, HUD and all, as the N64 drew its HUD into the same buffer):
##   color cut to 15 bits (RGB555) with the RDP's 4x4 "magic square" ordered
##   dither; then the VI's dither filter (each channel nudged toward its 8
##   neighbors by at most one 5-bit step, which hides most of the dither but
##   leaves its faint pattern); then the coverage edge anti-aliasing,
##   approximated by softening only where a pixel stands out sharply from its
##   neighbors; then the VI's horizontal resampling blur.
## - The picture is always 240 lines (the RESOLUTION option waits until the
##   mode is off) and never multisampled.
##
## The materials are swapped per mesh instance, in its surface override slots
## (never in the shared mesh resources, which the game reads back for tints,
## nor in material_override, which hit flashes and the like use). New meshes
## are caught as they enter the tree, and a rolling re-check picks up any
## surface the game re-materials later. Turning the mode off puts every
## swapped slot back.

signal changed(on: bool)

## TMEM holds 4 KB: 64 x 64 at most for the textures here (larger ones shrink).
const TEX_LIMIT := 64
## Textures that keep their size: the painted terrain (see above): each area's
## ground (world/<area>_ground.png) and the shared terrain pictures, and the
## sky panoramas, which the N64 drew from many tiles.
const TEX_KEEP := ["terrain", "cliff_rock"]
const TEX_KEEP_SUFFIX := ["_ground", "_sky"]
## Mesh instances re-checked per frame by the rolling scan.
const SCAN_PER_FRAME := 120

var active := false
var lod := false
## The framebuffer / VI pass (tools and captures can turn it off to compare).
var post_enabled := true

## StandardMaterial3D -> ShaderMaterial made from it.
var _converted := {}
## Shader source key -> Shader.
var _shaders := {}
## Texture -> the TMEM-sized copy (or the texture itself).
var _textures := {}
## Mesh instances being kept converted, and where the rolling scan is.
var _nodes: Array[MeshInstance3D] = []
var _scan := 0
var _post_layer: CanvasLayer = null
var _post_rect: ColorRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	GameManager.settings_changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	var want: bool = GameManager.true_n64
	var want_lod: bool = GameManager.n64_mipmaps
	if want_lod != lod:
		lod = want_lod
		for m: ShaderMaterial in _converted.values():
			m.set_shader_parameter("lod_blend", lod)
	if want == active:
		_update_post()
		return
	active = want
	if active:
		_nodes.clear()
		_collect(get_tree().root)
	else:
		_restore_all()
	_update_post()
	changed.emit(active)


# --- Mesh instances -------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if active and node is MeshInstance3D:
		_watch.call_deferred(node)


func _watch(mi: MeshInstance3D) -> void:
	if not is_instance_valid(mi) or not mi.is_inside_tree():
		return
	if not _nodes.has(mi):
		_nodes.append(mi)
	_convert_node(mi)


func _collect(node: Node) -> void:
	if node is MeshInstance3D:
		_nodes.append(node)
		_convert_node(node)
	for c in node.get_children():
		_collect(c)


func _process(_delta: float) -> void:
	if not active:
		return
	_update_post_rect()
	var n := _nodes.size()
	if n == 0:
		return
	var count := mini(SCAN_PER_FRAME, n)
	var i := 0
	while i < count and not _nodes.is_empty():
		_scan = _scan % _nodes.size()
		var mi := _nodes[_scan]
		if not is_instance_valid(mi) or not mi.is_inside_tree():
			_nodes.remove_at(_scan)
		else:
			_convert_node(mi)
			_scan += 1
		i += 1


## Swaps each surface of `mi` whose material can be drawn the N64 way, keeping
## what was in the slot (meta "n64_orig": {surface: material or null}).
func _convert_node(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	var orig: Dictionary = mi.get_meta("n64_orig", {})
	for s in mi.mesh.get_surface_count():
		var slot := mi.get_surface_override_material(s)
		if slot is ShaderMaterial and slot.has_meta("n64_from"):
			# Ours: keep it in step with the material it came from.
			_sync(slot as ShaderMaterial)
			continue
		var src: Material = slot if slot else mi.mesh.surface_get_material(s)
		var std := src as StandardMaterial3D
		if std == null or not _eligible(std):
			continue
		orig[s] = slot
		mi.set_surface_override_material(s, convert_material(std))
	if not orig.is_empty():
		mi.set_meta("n64_orig", orig)


func _restore_all() -> void:
	for mi in _nodes:
		if not is_instance_valid(mi) or not mi.has_meta("n64_orig"):
			continue
		var orig: Dictionary = mi.get_meta("n64_orig")
		for s: int in orig:
			if s >= mi.get_surface_override_material_count():
				continue
			var slot := mi.get_surface_override_material(s)
			if slot is ShaderMaterial and slot.has_meta("n64_from"):
				mi.set_surface_override_material(s, orig[s])
		mi.remove_meta("n64_orig")
	_nodes.clear()


## Only plain lit/unlit materials: billboards, triplanar mapping, fades and
## chained passes are left as they are.
func _eligible(m: StandardMaterial3D) -> bool:
	return m.billboard_mode == BaseMaterial3D.BILLBOARD_DISABLED and not m.uv1_triplanar \
		and m.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_DISABLED and not m.proximity_fade_enabled \
		and m.next_pass == null and not m.use_point_size and m.grow == false \
		and not m.normal_enabled and not m.refraction_enabled


# --- Materials ---------------------------------------------------------------------------

## The n64_surface ShaderMaterial for `m` (one per source material).
func convert_material(m: StandardMaterial3D) -> ShaderMaterial:
	if _converted.has(m):
		return _converted[m]
	var sm := ShaderMaterial.new()
	sm.set_meta("n64_from", m)
	sm.shader = _shader_for(m)
	sm.render_priority = m.render_priority
	_converted[m] = sm
	_sync(sm)
	return sm


## Copies the source material's values (the game changes some at run time).
func _sync(sm: ShaderMaterial) -> void:
	var m := sm.get_meta("n64_from") as StandardMaterial3D
	if m == null:
		return
	var key := _key(m)
	if sm.get_meta("n64_key", "") != key:
		sm.shader = _shader_for(m)
		sm.set_meta("n64_key", key)
	sm.set_shader_parameter("albedo", m.albedo_color)
	if m.albedo_texture:
		sm.set_shader_parameter("tex", tmem_texture(m.albedo_texture))
	sm.set_shader_parameter("uv_scale", m.uv1_scale)
	sm.set_shader_parameter("uv_offset", m.uv1_offset)
	sm.set_shader_parameter("alpha_scissor", m.alpha_scissor_threshold)
	sm.set_shader_parameter("emission", m.emission if m.emission_enabled else Color.BLACK)
	sm.set_shader_parameter("emission_energy", m.emission_energy_multiplier if m.emission_enabled else 0.0)
	sm.set_shader_parameter("lod_blend", lod)


## A texture as TMEM would hold it: at most 64 x 64 (the terrain excepted).
func tmem_texture(t: Texture2D) -> Texture2D:
	if _textures.has(t):
		return _textures[t]
	var out := t
	var path := t.resource_path
	var base := path.get_file().get_basename()
	var keep := base in TEX_KEEP or TEX_KEEP_SUFFIX.any(func(k: String) -> bool: return base.ends_with(k))
	if not keep and (t.get_width() > TEX_LIMIT or t.get_height() > TEX_LIMIT):
		var img := t.get_image()
		if img:
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			var k := minf(float(TEX_LIMIT) / img.get_width(), float(TEX_LIMIT) / img.get_height())
			img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_BILINEAR)
			out = ImageTexture.create_from_image(img)
	_textures[t] = out
	return out


func _key(m: StandardMaterial3D) -> String:
	var unshaded := m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
	var point := m.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC]
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [int(unshaded), m.transparency, m.cull_mode, m.blend_mode, m.depth_draw_mode,
		int(m.no_depth_test), int(m.disable_fog), int(m.albedo_texture != null), int(m.vertex_color_use_as_albedo),
		int(m.vertex_color_is_srgb), int(m.texture_repeat), int(point), int(m.emission_enabled)]


func _shader_for(m: StandardMaterial3D) -> Shader:
	var key := _key(m)
	if _shaders.has(key):
		return _shaders[key]
	var sh := Shader.new()
	sh.code = surface_code(m)
	_shaders[key] = sh
	return sh


## The n64_surface shader for the material's options.
func surface_code(m: StandardMaterial3D) -> String:
	var modes: Array[String] = []
	modes.append(["blend_mix", "blend_add", "blend_sub", "blend_mul", "blend_premul_alpha"][clampi(m.blend_mode, 0, 4)])
	modes.append(["depth_draw_opaque", "depth_draw_always", "depth_draw_never"][clampi(m.depth_draw_mode, 0, 2)])
	modes.append(["cull_back", "cull_front", "cull_disabled"][clampi(m.cull_mode, 0, 2)])
	modes.append("diffuse_lambert")
	modes.append("specular_disabled")
	if m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		modes.append("unshaded")
	else:
		modes.append("vertex_lighting")
	if m.no_depth_test:
		modes.append("depth_test_disabled")
	if m.disable_fog:
		modes.append("fog_disabled")
	if m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
		modes.append("depth_prepass_alpha")
	var has_tex := m.albedo_texture != null
	var point := m.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC]
	var alpha := m.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS]
	var scissor := m.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH]
	var c := "shader_type spatial;\nrender_mode %s;\n\n" % ", ".join(modes)
	c += "uniform vec4 albedo : source_color = vec4(1.0);\n"
	c += "uniform sampler2D tex : filter_nearest, %s;\n" % ("repeat_enable" if m.texture_repeat else "repeat_disable")
	c += "uniform vec3 uv_scale = vec3(1.0);\nuniform vec3 uv_offset = vec3(0.0);\n"
	c += "uniform float alpha_scissor = 0.5;\nuniform vec4 emission : source_color = vec4(0.0);\nuniform float emission_energy = 0.0;\n"
	c += "uniform bool lod_blend = false;\n\n"
	c += "void vertex() {\n\tUV = UV * uv_scale.xy + uv_offset.xy;\n"
	if m.vertex_color_use_as_albedo and m.vertex_color_is_srgb:
		# As BaseMaterial3D does: only when the renderer works in linear space
		# (the Compatibility renderer draws in sRGB: OUTPUT_IS_SRGB).
		c += "\tif (!OUTPUT_IS_SRGB) {\n\t\tCOLOR.rgb = mix(pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), COLOR.rgb * (1.0 / 12.92), lessThan(COLOR.rgb, vec3(0.04045)));\n\t}\n"
	c += "}\n\n"
	if has_tex:
		c += TEXEL_CODE % ["fract(vec2(p) / vec2(size)) * vec2(size)" if m.texture_repeat else "clamp(vec2(p), vec2(0.0), vec2(size - 1))"]
	c += "void fragment() {\n\tvec4 c = albedo;\n"
	if has_tex:
		c += "\tvec4 t = %s;\n" % ("rdp_point(UV)" if point else "rdp_sample(UV)")
		c += "\tif (!OUTPUT_IS_SRGB) {\n\t\tt.rgb = srgb_to_linear(t.rgb);\n\t}\n\tc *= t;\n"
	if m.vertex_color_use_as_albedo:
		c += "\tc *= COLOR;\n"
	c += "\tALBEDO = c.rgb;\n"
	if alpha:
		c += "\tALPHA = c.a;\n"
	elif scissor:
		c += "\tALPHA = c.a;\n\tALPHA_SCISSOR_THRESHOLD = alpha_scissor;\n"
	if m.emission_enabled:
		c += "\tEMISSION = emission.rgb * emission_energy;\n"
	c += "}\n"
	return c


## The RDP texture unit. %s wraps or clamps a texel coordinate.
const TEXEL_CODE := """vec3 srgb_to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

// One texel as TMEM holds it: 16 bits, RGBA5551 (5 bits a colour, in the
// texture's own gamma, as the N64 stored them).
vec4 texel(ivec2 p, ivec2 size) {
	vec2 q = %s;
	vec4 t = texelFetch(tex, ivec2(q), 0);
	return vec4(floor(t.rgb * 31.0 + 0.5) / 31.0, t.a);
}

// Level 1 of the RDP's LOD: each texel the average of four of level 0.
vec4 texel1(ivec2 p, ivec2 size) {
	ivec2 b = p * 2;
	return (texel(b, size) + texel(b + ivec2(1, 0), size) + texel(b + ivec2(0, 1), size) + texel(b + ivec2(1, 1), size)) * 0.25;
}

// The 3-point (triangular) filter: of the four texels round the point, only
// the three of the triangle it lies in, weighted by its distance along the
// triangle's two edges.
vec4 tri(vec4 t00, vec4 t10, vec4 t01, vec4 t11, vec2 f) {
	if (f.x + f.y < 1.0) {
		return t00 + f.x * (t10 - t00) + f.y * (t01 - t00);
	}
	return t11 + (1.0 - f.x) * (t01 - t11) + (1.0 - f.y) * (t10 - t11);
}

vec4 rdp_level0(vec2 st, ivec2 size) {
	vec2 i = floor(st);
	ivec2 p = ivec2(i);
	return tri(texel(p, size), texel(p + ivec2(1, 0), size), texel(p + ivec2(0, 1), size), texel(p + ivec2(1, 1), size), st - i);
}

vec4 rdp_level1(vec2 st, ivec2 size) {
	vec2 i = floor(st);
	ivec2 p = ivec2(i);
	return tri(texel1(p, size), texel1(p + ivec2(1, 0), size), texel1(p + ivec2(0, 1), size), texel1(p + ivec2(1, 1), size), st - i);
}

vec4 rdp_sample(vec2 uv) {
	ivec2 size = textureSize(tex, 0);
	vec2 st = uv * vec2(size) - 0.5;
	vec4 c = rdp_level0(st, size);
	if (lod_blend) {
		// 2-cycle mode: past one texel a pixel, blend toward level 1.
		vec2 d = max(abs(dFdx(st)), abs(dFdy(st)));
		float lod = log2(max(max(d.x, d.y), 1e-4));
		if (lod > 0.0) {
			vec4 c1 = rdp_level1(uv * vec2(size) * 0.5 - 0.5, size);
			c = mix(c, c1, clamp(lod, 0.0, 1.0));
		}
	}
	return c;
}

vec4 rdp_point(vec2 uv) {
	ivec2 size = textureSize(tex, 0);
	return texel(ivec2(floor(uv * vec2(size))), size);
}

"""


# --- The framebuffer and the VI ---------------------------------------------------------

func _update_post() -> void:
	if not active or not post_enabled:
		if is_instance_valid(_post_layer):
			_post_layer.visible = false
		return
	var vp := _game_viewport()
	if vp == null:
		return
	if not is_instance_valid(_post_layer) or _post_layer.get_parent() != vp:
		if is_instance_valid(_post_layer):
			_post_layer.queue_free()
		_post_layer = CanvasLayer.new()
		_post_layer.name = "N64Post"
		# Over everything in the picture (HUD, menus, fades): the N64 drew it
		# all into one framebuffer before the VI read it out.
		_post_layer.layer = 100
		_post_rect = ColorRect.new()
		_post_rect.name = "VI"
		_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/shaders/n64_post.gdshader")
		_post_rect.material = mat
		_post_layer.add_child(_post_rect)
		vp.add_child(_post_layer)
	_post_layer.visible = true
	_update_post_rect()


func _update_post_rect() -> void:
	if not is_instance_valid(_post_rect):
		if active and _game_viewport():
			_update_post()
		return
	var r := GameManager.screen_rect()
	# The layer is offset to center the 320-wide layout; screen_rect() is in those terms.
	_post_rect.position = r.position
	_post_rect.size = r.size


func _game_viewport() -> SubViewport:
	var main := get_tree().root.find_child("GameViewport", true, false)
	return main as SubViewport


## For tests: how many surfaces are drawn the N64 way now.
func converted_surfaces() -> int:
	var n := 0
	for mi in _nodes:
		if not is_instance_valid(mi) or mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var slot := mi.get_surface_override_material(s)
			if slot is ShaderMaterial and slot.has_meta("n64_from"):
				n += 1
	return n
