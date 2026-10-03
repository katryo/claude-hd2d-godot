// Stylised pixel-art water: quantised waves, drifting sparkles and shoreline foam.
shader_type spatial;
render_mode cull_back;

uniform vec4 deep_color : source_color = vec4(0.13, 0.33, 0.62, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.25, 0.58, 0.82, 1.0);
uniform vec4 sparkle_color : source_color = vec4(0.85, 0.96, 1.0, 1.0);
uniform float pixels_per_unit = 16.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = floor(world_pos.xz * pixels_per_unit) / pixels_per_unit;
	float w = sin(p.x * 2.1 + TIME * 1.3) + sin(p.y * 3.3 - TIME * 1.1 + p.x * 0.8) + sin((p.x + p.y) * 1.7 + TIME * 0.7);
	float band = floor((w * 0.5 + 1.5) * 1.5) / 4.5;
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, clamp(band, 0.0, 1.0));
	// Sparkles: a few cells flash on and off.
	vec2 cell = floor(world_pos.xz * pixels_per_unit / 3.0);
	float h = hash(cell);
	float flicker = step(0.985, h) * step(0.6, sin(TIME * 2.0 + h * 50.0));
	// Streaks that drift with the current.
	float streak = step(0.93, sin(p.x * 6.0 - TIME * 2.2 + sin(p.y * 4.0) * 1.5)) * step(0.4, fract(p.y * 1.25));
	col = mix(col, sparkle_color.rgb, max(flicker, streak * 0.55));
	ALBEDO = col;
	ROUGHNESS = 0.18;
	SPECULAR = 0.7;
	EMISSION = sparkle_color.rgb * flicker * 1.6 + col * 0.06;
}
