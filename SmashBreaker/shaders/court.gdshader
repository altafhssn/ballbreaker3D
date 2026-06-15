shader_type spatial;

// Hangar floor — clean dark metal, no grid. A faint accent tint breathes
// from the centre and a soft energy wash sits at the far (brick) end.
// Uniform names kept compatible with game.gd's _apply_theme().

uniform vec3 base_color : source_color = vec3(0.035, 0.05, 0.085);
uniform vec3 base_color_2 : source_color = vec3(0.015, 0.025, 0.05);
uniform vec3 grid_color : source_color = vec3(0.2, 0.85, 1.0);   // accent tint
uniform vec3 hot_color : source_color = vec3(0.95, 0.3, 0.8);    // far-end wash

uniform vec2 court_size = vec2(10.8, 19.2);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1, 0)), u.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 p = UV * court_size;

	// Brushed-metal base: layered noise, very low contrast.
	float n = noise(p * 6.0) * 0.30 + noise(p * 22.0) * 0.15;
	vec3 base = mix(base_color_2, base_color, 0.5 + n * 0.5);

	// Soft accent pool around the centre of the court.
	float centre = smoothstep(0.75, 0.15, length(UV - vec2(0.5, 0.55)));
	vec3 emission = grid_color * centre * 0.05;

	// Faint energy wash at the far end, under the brick wall.
	float far_glow = smoothstep(0.22, 0.0, UV.y);
	emission += hot_color * far_glow * 0.05;

	// Vignette toward the mesh edges.
	float edge = smoothstep(0.0, 0.05, min(min(UV.x, UV.y), min(1.0 - UV.x, 1.0 - UV.y)));
	base *= mix(0.5, 1.0, edge);

	ALBEDO = base + emission * 0.3;
	EMISSION = emission;
	ROUGHNESS = 0.5;
	METALLIC = 0.45;
}
