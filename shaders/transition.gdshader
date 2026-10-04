// Diamond-pattern screen wipe used for battle transitions.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float cells = 18.0;
uniform vec4 color : source_color = vec4(0.02, 0.02, 0.05, 1.0);
uniform vec2 aspect = vec2(1.777, 1.0);

// Weights of the diagonal sweep direction (top-left to bottom-right).
const float SWEEP_X = 0.6;
const float SWEEP_Y = 0.4;

void fragment() {
	vec2 uv = UV * aspect * cells;
	vec2 f = fract(uv) - 0.5;
	float diamond = abs(f.x) + abs(f.y);
	float sweep = (UV.x * SWEEP_X + UV.y * SWEEP_Y);
	float t = progress * 2.0 - sweep;
	float a = step(diamond, t);
	COLOR = vec4(color.rgb, a * color.a);
}
