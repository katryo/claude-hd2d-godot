// Stylised pixel-art water: quantised waves, drifting sparkles and shoreline foam.
shader_type spatial;
render_mode cull_back;

uniform vec4 deep_color : source_color = vec4(0.13, 0.33, 0.62, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.25, 0.58, 0.82, 1.0);
uniform vec4 sparkle_color : source_color = vec4(0.85, 0.96, 1.0, 1.0);
uniform float pixels_per_unit = 16.0;

// Classic sin-dot hash.
const vec2 HASH_DIR = vec2(127.1, 311.7);
const float HASH_SCALE = 43758.5453;
// Three summed sine waves (frequency per world unit, speed per second).
const float WAVE1_FREQ = 2.1;
const float WAVE1_SPEED = 1.3;
const float WAVE2_FREQ = 3.3;
const float WAVE2_SPEED = 1.1;
const float WAVE2_SKEW = 0.8;
const float WAVE3_FREQ = 1.7;
const float WAVE3_SPEED = 0.7;
// Quantise the wave sum into a few flat colour bands.
const float BAND_BIAS = 1.5;
const float BAND_STEPS = 1.5;
const float BAND_RANGE = 4.5;
// Sparkles: size of a sparkle cell in texels, share of cells that sparkle, and blink timing.
const float SPARKLE_CELL_PX = 3.0;
const float SPARKLE_CHANCE = 0.985;
const float SPARKLE_DUTY = 0.6;
const float SPARKLE_SPEED = 2.0;
const float SPARKLE_PHASE_SCALE = 50.0;
const float SPARKLE_GLOW = 1.6;
// Drifting current streaks.
const float STREAK_THRESHOLD = 0.93;
const float STREAK_FREQ = 6.0;
const float STREAK_SPEED = 2.2;
const float STREAK_WOBBLE_FREQ = 4.0;
const float STREAK_WOBBLE = 1.5;
const float STREAK_ROW_GAP = 0.4;
const float STREAK_ROW_FREQ = 1.25;
const float STREAK_STRENGTH = 0.55;
const float WATER_ROUGHNESS = 0.18;
const float WATER_SPECULAR = 0.7;
const float BASE_GLOW = 0.06;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, HASH_DIR)) * HASH_SCALE);
}

void fragment() {
	vec2 p = floor(world_pos.xz * pixels_per_unit) / pixels_per_unit;
	float w = sin(p.x * WAVE1_FREQ + TIME * WAVE1_SPEED)
			+ sin(p.y * WAVE2_FREQ - TIME * WAVE2_SPEED + p.x * WAVE2_SKEW)
			+ sin((p.x + p.y) * WAVE3_FREQ + TIME * WAVE3_SPEED);
	float band = floor((w * 0.5 + BAND_BIAS) * BAND_STEPS) / BAND_RANGE;
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, clamp(band, 0.0, 1.0));
	// Sparkles: a few cells flash on and off.
	vec2 cell = floor(world_pos.xz * pixels_per_unit / SPARKLE_CELL_PX);
	float h = hash(cell);
	float flicker = step(SPARKLE_CHANCE, h) * step(SPARKLE_DUTY, sin(TIME * SPARKLE_SPEED + h * SPARKLE_PHASE_SCALE));
	// Streaks that drift with the current.
	float streak = step(STREAK_THRESHOLD, sin(p.x * STREAK_FREQ - TIME * STREAK_SPEED + sin(p.y * STREAK_WOBBLE_FREQ) * STREAK_WOBBLE))
			* step(STREAK_ROW_GAP, fract(p.y * STREAK_ROW_FREQ));
	col = mix(col, sparkle_color.rgb, max(flicker, streak * STREAK_STRENGTH));
	ALBEDO = col;
	ROUGHNESS = WATER_ROUGHNESS;
	SPECULAR = WATER_SPECULAR;
	EMISSION = sparkle_color.rgb * flicker * SPARKLE_GLOW + col * BASE_GLOW;
}
