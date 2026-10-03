// Y-axis billboard for pixel-art scenery (trees, grass, lamps) with optional wind sway.
// Uses alpha scissor so the sprites cast crisp shadows and play nicely with depth of field.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D sprite_texture : source_color, filter_nearest_mipmap, repeat_disable;
uniform float sway_strength = 0.0;
uniform float sway_speed = 1.6;
uniform float emission_strength = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	// Wind: only the top of the quad moves (UV.y == 0 at the top).
	float top = 1.0 - UV.y;
	float phase = TIME * sway_speed + origin.x * 0.7 + origin.z * 0.45;
	VERTEX.x += sin(phase) * sway_strength * top * top;
	// Billboard around the Y axis, keeping the node's scale.
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)) * scale.x;
	vec3 fwd = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))) * scale.z;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(0.0, scale.y, 0.0, 0.0), vec4(fwd, 0.0), vec4(origin, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(sprite_texture, UV) * tint;
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	// Very bright warm pixels (lantern glass, windows) glow when emission is enabled.
	float bright = step(0.92, c.r) * step(0.8, c.g);
	EMISSION = c.rgb * bright * emission_strength;
	// Normals point up-ish so foliage is lit like the ground instead of going dark at grazing sun.
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz, 0.55));
}
