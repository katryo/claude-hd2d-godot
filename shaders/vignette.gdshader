// Soft vignette with a gentle warm/cool grade, drawn on top of the 3D view.
shader_type canvas_item;

uniform float strength = 0.55;
uniform float radius = 0.78;
uniform float softness = 0.55;
uniform vec4 shadow_tint : source_color = vec4(0.05, 0.04, 0.12, 1.0);

// Widen the falloff horizontally so the vignette follows the 16:9-ish frame.
const float ASPECT_STRETCH = 1.35;

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= ASPECT_STRETCH;
	float d = length(uv);
	float v = smoothstep(radius - softness, radius, d);
	COLOR = vec4(shadow_tint.rgb, v * strength);
}
