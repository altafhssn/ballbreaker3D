shader_type canvas_item;

// Deep-space backdrop: wispy domain-warped nebula, layered parallax
// starfield with twinkle + occasional flared bright stars, and a soft
// diagonal galactic band. No grid — pure space.
//
// Uniform names kept from the old synthwave version so existing scenes
// don't need edits:
//   grid_color    -> star / band tint
//   grid_strength -> galactic band intensity
//   star_density  -> overall star density

uniform vec3 deep_color : source_color = vec3(0.006, 0.012, 0.030);
uniform vec3 nebula_a : source_color = vec3(0.05, 0.22, 0.38);
uniform vec3 nebula_b : source_color = vec3(0.30, 0.07, 0.28);
uniform vec3 grid_color : source_color = vec3(0.55, 0.75, 0.95);
uniform float grid_strength : hint_range(0.0, 1.0) = 0.55;
uniform float star_density : hint_range(0.0, 1.0) = 0.35;
uniform float aspect = 0.5625;   // viewport w/h, for round stars in portrait

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + 19.19));
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(13.7, 7.1);
		a *= 0.5;
	}
	return v;
}

// One parallax star layer. `sq` is square-corrected uv.
float star_layer(vec2 sq, float scale, float drift, float size_px, float twinkle_amt) {
	vec2 sp = sq * scale + vec2(drift * TIME * 0.004, 0.0);
	vec2 cell = floor(sp);
	float h = hash(cell);
	// Only some cells contain a star.
	if (h < 1.0 - star_density * 0.45) {
		return 0.0;
	}
	vec2 spos = 0.15 + 0.7 * hash2(cell * 1.37);   // position inside cell
	float d = length(fract(sp) - spos);
	float size = size_px * (0.5 + h * 0.8);
	float tw = 1.0 - twinkle_amt * 0.5 * (1.0 + sin(TIME * (0.8 + h * 3.0) + h * 80.0));
	return smoothstep(size, 0.0, d) * tw * (0.4 + h * 0.6);
}

void fragment() {
	vec2 uv = UV;
	vec2 sq = vec2(uv.x * aspect, uv.y);   // square space for round stars

	// --- Base: near-black with the faintest vertical depth gradient.
	vec3 col = deep_color * (0.85 + 0.5 * (1.0 - uv.y));

	// --- Galactic band: soft diagonal milky strip.
	vec2 band_dir = normalize(vec2(0.82, -0.58));
	float band_d = abs(dot(uv - vec2(0.5, 0.42), band_dir));
	float band = exp(-band_d * band_d * 38.0);

	// --- Nebula: domain-warped fbm, drifting very slowly.
	vec2 np = sq * 2.6;
	vec2 warp = vec2(
		fbm(np + vec2(TIME * 0.006, 0.0)),
		fbm(np + vec2(5.2, TIME * 0.005)));
	float neb1 = fbm(np + 1.8 * warp);
	float neb2 = fbm(np * 1.7 - 1.2 * warp + 9.3);
	// Clouds concentrate loosely along the band.
	float neb_mask = 0.35 + 0.65 * band;
	col += nebula_a * neb1 * neb1 * 0.38 * neb_mask;
	col += nebula_b * neb2 * neb2 * 0.30 * neb_mask;
	// Milky core of the band.
	col += grid_color * band * grid_strength * 0.10;
	col += grid_color * band * neb1 * grid_strength * 0.12;

	// --- Stars: three parallax layers, denser inside the band.
	float dens_boost = 1.0 + band * 0.8;
	float s = 0.0;
	s += star_layer(sq, 38.0, 1.0, 0.10, 0.55) * 0.55;          // far dust
	s += star_layer(sq + 3.7, 22.0, 1.8, 0.10, 0.45) * 0.8;     // mid
	s += star_layer(sq + 8.1, 11.0, 3.0, 0.09, 0.35) * 1.0;     // near
	col += vec3(0.85, 0.92, 1.0) * s * dens_boost;

	// --- Rare bright stars with a cross flare.
	vec2 bp = sq * 6.0;
	vec2 bcell = floor(bp);
	float bh = hash(bcell + 4.2);
	if (bh > 0.965) {
		vec2 spos = 0.2 + 0.6 * hash2(bcell * 2.11);
		vec2 dv = fract(bp) - spos;
		float d = length(dv);
		float tw = 0.75 + 0.25 * sin(TIME * (0.5 + bh * 2.0) + bh * 40.0);
		float core = smoothstep(0.05, 0.0, d);
		float flare = smoothstep(0.018, 0.0, abs(dv.x)) * smoothstep(0.30, 0.0, abs(dv.y))
					+ smoothstep(0.018, 0.0, abs(dv.y)) * smoothstep(0.30, 0.0, abs(dv.x));
		col += (vec3(0.9, 0.95, 1.0) * core + grid_color * flare * 0.45) * tw;
	}

	// --- Grade: gentle vignette, slight blue lift in shadows.
	float vig = smoothstep(1.25, 0.3, length(uv - vec2(0.5, 0.5)));
	col *= mix(0.55, 1.0, vig);
	col += vec3(0.004, 0.008, 0.018);

	COLOR = vec4(col, 1.0);
}
