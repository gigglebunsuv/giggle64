// TRUE N64 MODE: the framebuffer and the Video Interface (scripts/systems/
// n64_mode.gd). Drawn over the whole finished 320x240 picture, it does what
// the N64 did between the RDP's blender and the TV:
//   1. RGB555: the RDP wrote 16-bit colour (5 bits a channel), dithered with
//      its 4x4 "magic square" ordered matrix (0..7 added before the cut).
//   2. The VI's dither filter: each channel moves toward its 8 neighbours by
//      at most one 5-bit step between them, which hides most of the dither
//      on smooth gradients and keeps edges (and a faint pattern).
//   3. Edge anti-aliasing: the RDP kept coverage per pixel and the VI blended
//      partly covered edge pixels with their neighbours. Without coverage, a
//      pixel that stands out sharply from its neighbours is softened toward
//      them a little: soft, but still low-resolution, edges.
//   4. The VI resampled each line to the TV, blurring a little horizontally.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen : hint_screen_texture, filter_nearest, repeat_disable;
// How much of each stage (0 = off).
uniform float dedither = 1.0;
uniform float edge_aa = 0.55;
uniform float vi_blur = 0.5;

// The RDP's magic square, row by row.
const int MAGIC[16] = int[](0, 6, 1, 7, 4, 2, 5, 3, 3, 5, 2, 4, 7, 1, 6, 0);

ivec2 view_size() {
	return textureSize(screen, 0);
}

// The colour at `p` as the RDP stored it: 5 bits a channel, dithered.
vec3 rdp(ivec2 p) {
	ivec2 s = view_size();
	p = clamp(p, ivec2(0), s - 1);
	vec3 c = texelFetch(screen, p, 0).rgb * 255.0;
	float d = float(MAGIC[(p.y & 3) * 4 + (p.x & 3)]);
	return floor(min(c + d, vec3(255.0)) / 8.0);
}

// The VI's dither filter over 5-bit values, back to 0..1.
vec3 vi_dedither(ivec2 p) {
	vec3 c = rdp(p);
	vec3 acc = vec3(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			if (x == 0 && y == 0) {
				continue;
			}
			acc += clamp(rdp(p + ivec2(x, y)) - c, vec3(-1.0), vec3(1.0));
		}
	}
	return (c + acc / 8.0 * dedither) / 31.0;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	ivec2 s = view_size();
	ivec2 p = ivec2(SCREEN_UV * vec2(s));
	vec3 c = vi_dedither(p);
	vec3 l = vi_dedither(p + ivec2(-1, 0));
	vec3 r = vi_dedither(p + ivec2(1, 0));
	vec3 u = vi_dedither(p + ivec2(0, -1));
	vec3 d = vi_dedither(p + ivec2(0, 1));
	// Edges: softened by how sharply the pixel stands out.
	float lc = luma(c);
	float contrast = max(max(abs(luma(l) - lc), abs(luma(r) - lc)), max(abs(luma(u) - lc), abs(luma(d) - lc)));
	float edge = smoothstep(0.08, 0.3, contrast) * edge_aa;
	c = mix(c, (l + r + u + d) * 0.25, edge * 0.5);
	// The VI's horizontal resample.
	c = mix(c, c * 0.5 + (l + r) * 0.25, vi_blur);
	COLOR = vec4(c, 1.0);
}
