shader_type spatial;
// Render96 / OoT3D-style "painted" surface for the promo remasters: the
// vertex color is the base, with procedural detail standing in for the
// hand-painted textures of the 3DS remake (cloth folds and weave, leather
// grain, brushed metal, prints). Patterns live in the mesh's own space.
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform int pattern = 0;   // 0 cloth, 1 skin, 2 leather, 3 metal, 4 gold, 5 damask, 6 sakura, 7 stars, 8 enamel, 9 quilt
uniform float rough = 0.55;
uniform vec3 accent : source_color = vec3(0.95, 0.78, 0.35);
uniform vec3 accent2 : source_color = vec3(1.0, 0.85, 0.9);
uniform float scale = 1.0;

varying vec3 lp;
varying vec3 ln;

void vertex() {
	lp = VERTEX * scale;
	ln = NORMAL;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// A tone-on-tone damask: diamond lattice with a small flourish in each cell.
float damask2(vec2 uv) {
	vec2 g = uv * 34.0;
	vec2 c = fract(g) - 0.5;
	float d = abs(c.x) + abs(c.y);
	float lattice = smoothstep(0.05, 0.0, abs(d - 0.48));
	float bloom = smoothstep(0.17, 0.12, length(c * vec2(1.0, 0.6))) * 0.8;
	float dots = smoothstep(0.06, 0.03, length(abs(c) - vec2(0.24)));
	return max(lattice, max(bloom, dots));
}

// Five-petal blossoms scattered over the cloth.
float sakura2(vec2 uv, out float centre) {
	vec2 g = uv * 13.0;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	float h = hash(vec3(id, 3.1));
	centre = 0.0;
	if (h < 0.45) return 0.0;
	c += (vec2(hash(vec3(id, 1.0)), hash(vec3(id, 2.0))) - 0.5) * 0.4;
	float r = length(c);
	float a = atan(c.y, c.x) + h * 6.28;
	float petal = 0.2 * (0.62 + 0.38 * abs(cos(2.5 * a)));
	centre = smoothstep(0.05, 0.03, r);
	return smoothstep(petal + 0.015, petal - 0.015, r);
}

float stars2(vec2 uv) {
	vec2 g = uv * 22.0;
	vec2 id = floor(g);
	vec2 c = fract(g) - 0.5;
	float h = hash(vec3(id, 7.7));
	if (h < 0.7) return 0.0;
	c += (vec2(hash(vec3(id, 4.0)), hash(vec3(id, 5.0))) - 0.5) * 0.5;
	float s = abs(c.x) * abs(c.y) * 60.0 + length(c) * 3.0;
	return smoothstep(0.35, 0.15, s);
}

// Triplanar blend of a 2D pattern.
float tri(float px, float py, float pz) {
	vec3 w = pow(abs(ln), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return px * w.x + py * w.y + pz * w.z;
}

void fragment() {
	vec3 c = to_linear(COLOR.rgb);
	float r = rough;
	float m = 0.0;
	float folds = fbm(lp * vec3(9.0, 2.6, 9.0));
	if (pattern == 1) {
		// Skin: soft, a touch of warmth in the shadows.
		c *= mix(0.97, 1.03, noise(lp * 40.0));
		r = 0.62;
	} else if (pattern == 2) {
		// Leather: grain, darker creases, worn lighter highlights.
		float g = fbm(lp * 70.0);
		float crease = fbm(lp * vec3(14.0, 30.0, 14.0));
		c *= mix(0.78, 1.12, g) * mix(0.85, 1.05, crease);
		r = mix(0.45, 0.7, g);
	} else if (pattern == 3 || pattern == 8) {
		// Steel (or enamel): brushed streaks and faint scratches.
		float b = noise(lp * vec3(260.0, 6.0, 260.0));
		float sc = smoothstep(0.92, 1.0, noise(lp * vec3(400.0, 40.0, 30.0)));
		c *= mix(0.9, 1.08, b) + sc * 0.15;
		m = pattern == 3 ? 0.85 : 0.0;
		r = pattern == 3 ? mix(0.22, 0.38, b) : 0.28;
	} else if (pattern == 4) {
		float b = noise(lp * vec3(180.0, 10.0, 180.0));
		c *= mix(0.9, 1.1, b);
		m = 0.95;
		r = mix(0.2, 0.32, b);
	} else {
		// Cloth: folds and a fine weave.
		c *= mix(0.84, 1.07, folds);
		float weave = sin(lp.x * 1400.0 + lp.z * 1400.0) * sin(lp.y * 1400.0);
		c *= 1.0 + weave * 0.025;
		r = rough;
		if (pattern == 5) {
			float d = tri(damask2(lp.zy), damask2(lp.xz), damask2(lp.xy));
			c = mix(c, c * 1.35 + to_linear(accent) * 0.08, d * 0.55);
			r = mix(r, 0.35, d);
		} else if (pattern == 6) {
			float ca; float cb; float cc;
			float fa = sakura2(lp.zy, ca);
			float fb = sakura2(lp.xz, cb);
			float fc = sakura2(lp.xy, cc);
			float f = tri(fa, fb, fc);
			float cen = tri(ca, cb, cc);
			c = mix(c, to_linear(accent2) * mix(0.85, 1.0, folds), f);
			c = mix(c, to_linear(accent), cen);
		} else if (pattern == 7) {
			float s = tri(stars2(lp.zy), stars2(lp.xz), stars2(lp.xy));
			c = mix(c, to_linear(accent) * 2.0, s);
		} else if (pattern == 9) {
			vec2 q = fract(vec2(lp.x + lp.y, lp.y - lp.x + lp.z) * 30.0);
			float st = smoothstep(0.06, 0.0, min(q.x, q.y));
			c *= 1.0 - st * 0.25;
		}
	}
	ALBEDO = c;
	ROUGHNESS = r;
	METALLIC = m;
	SPECULAR = 0.5;
	RIM = pattern == 3 || pattern == 4 ? 0.1 : 0.25;
	RIM_TINT = 0.6;
}
