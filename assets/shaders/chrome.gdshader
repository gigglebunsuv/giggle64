// Polished metal, the way OoT drew the Master Sword and Mirror Shield: the
// texture is looked up by the view-space normal (G_TEXTURE_GEN environment
// mapping), so the shine slides over the blade as it turns. Vertex colours
// tint it (white steel, gold...). Built for tools/build_assets.gd ("chrome").
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D env_tex : source_color, filter_linear, repeat_disable;
uniform float strength = 1.5;

varying vec3 tint;

void vertex() {
	// Vertex colours are sRGB, as on the other character materials.
	vec3 c = COLOR.rgb;
	tint = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void fragment() {
	vec2 uv = NORMAL.xy * vec2(0.48, -0.48) + 0.5;
	vec3 env = texture(env_tex, uv).rgb;
	// Bright streaks in the picture flare white whatever the tint.
	float flare = max(env.r - 0.82, 0.0) * 4.0;
	ALBEDO = min(tint * env * strength + vec3(flare), vec3(1.0));
}
