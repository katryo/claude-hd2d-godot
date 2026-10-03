class_name Visuals
extends RefCounted
## Shared HD-2D lighting setup: warm key light, cool ambient, bloom, SSAO, fog and
## tilt-shift style depth of field.

const MOODS := {
	"field": {
		"sun_color": Color(1.0, 0.86, 0.66), "sun_energy": 1.25, "sun_pitch": -42.0, "sun_yaw": -38.0,
		"sky_top": Color(0.28, 0.42, 0.72), "sky_horizon": Color(0.95, 0.72, 0.55),
		"ambient": Color(0.55, 0.6, 0.85), "ambient_energy": 0.55,
		"fog": Color(0.75, 0.68, 0.72), "fog_density": 0.006,
	},
	"battle": {
		"sun_color": Color(1.0, 0.84, 0.62), "sun_energy": 1.2, "sun_pitch": -40.0, "sun_yaw": 35.0,
		"sky_top": Color(0.25, 0.38, 0.7), "sky_horizon": Color(0.95, 0.7, 0.5),
		"ambient": Color(0.55, 0.6, 0.85), "ambient_energy": 0.6,
		"fog": Color(0.7, 0.65, 0.75), "fog_density": 0.012,
	},
	"boss": {
		"sun_color": Color(1.0, 0.82, 0.78), "sun_energy": 1.0, "sun_pitch": -35.0, "sun_yaw": 35.0,
		"sky_top": Color(0.2, 0.18, 0.4), "sky_horizon": Color(0.85, 0.5, 0.55),
		"ambient": Color(0.5, 0.5, 0.85), "ambient_energy": 0.5,
		"fog": Color(0.5, 0.42, 0.62), "fog_density": 0.01,
	},
}


static func make_environment(mood: String = "field") -> WorldEnvironment:
	var m: Dictionary = MOODS[mood]
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = m.sky_top
	sky_mat.sky_horizon_color = m.sky_horizon
	sky_mat.ground_horizon_color = m.sky_horizon
	sky_mat.ground_bottom_color = Color(0.2, 0.25, 0.2)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = m.ambient
	env.ambient_light_energy = m.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 5.0
	# Bloom: makes lanterns, windows, water sparkles and spell effects glow.
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.1
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.3)
	# Contact shadows that ground the sprites in the scene.
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.2
	env.ssao_power = 1.6
	env.ssao_detail = 0.6
	# Soft aerial perspective.
	env.fog_enabled = true
	env.fog_light_color = m.fog
	env.fog_density = m.fog_density
	env.fog_sky_affect = 0.3
	env.fog_aerial_perspective = 0.15
	# Slightly punchy grade.
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.06
	env.adjustment_brightness = 1.0

	var we := WorldEnvironment.new()
	we.environment = env
	return we


static func make_sun(mood: String = "field") -> DirectionalLight3D:
	var m: Dictionary = MOODS[mood]
	var sun := DirectionalLight3D.new()
	sun.light_color = m.sun_color
	sun.light_energy = m.sun_energy
	sun.rotation_degrees = Vector3(m.sun_pitch, m.sun_yaw, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 45.0
	return sun


## Depth of field that keeps the playing field crisp and melts the foreground and
## background into bokeh, which sells the "miniature diorama" look.
static func make_camera_attributes(focus_distance: float) -> CameraAttributesPractical:
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = focus_distance + 4.0
	attrs.dof_blur_far_transition = 9.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = max(focus_distance - 7.0, 0.5)
	attrs.dof_blur_near_transition = 4.0
	attrs.dof_blur_amount = 0.14
	return attrs


static func make_vignette() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/vignette.gdshader")
	rect.material = mat
	layer.add_child(rect)
	return layer


## Floating dust motes / fireflies that catch the bloom.
static func make_motes(extents: Vector3, amount: int = 90) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(0.2, 1, 0)
	p.spread = 60.0
	p.gravity = Vector3(0, 0.03, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SpriteFactory.particle_dot()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy_multiplier = 2.5
	quad.material = mat
	p.mesh = quad
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	grad.colors = PackedColorArray([Color(1.0, 0.9, 0.6, 0.0), Color(1.0, 0.9, 0.6, 0.9),
		Color(1.0, 0.85, 0.5, 0.8), Color(1.0, 0.8, 0.4, 0.0)])
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
