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

# Sky / tonemap
const SKY_GROUND_BOTTOM := Color(0.2, 0.25, 0.2)
const TONEMAP_EXPOSURE := 1.05
const TONEMAP_WHITE := 5.0

# Glow (bloom)
const GLOW_INTENSITY := 0.9
const GLOW_STRENGTH := 1.1
const GLOW_BLOOM := 0.08
const GLOW_HDR_THRESHOLD := 0.95
## Weight of each glow mip level, index = level.
const GLOW_LEVELS := [0.0, 1.0, 1.0, 0.6, 0.3]

# SSAO
const SSAO_RADIUS := 1.4
const SSAO_INTENSITY := 2.2
const SSAO_POWER := 1.6
const SSAO_DETAIL := 0.6

# Fog
const FOG_SKY_AFFECT := 0.3
const FOG_AERIAL_PERSPECTIVE := 0.15

# Colour grade
const GRADE_SATURATION := 1.18
const GRADE_CONTRAST := 1.06
const GRADE_BRIGHTNESS := 1.0

# Sun shadows
const SUN_SHADOW_BLUR := 1.5
const SUN_SHADOW_BIAS := 0.04
const SUN_SHADOW_NORMAL_BIAS := 1.2
const SUN_SHADOW_MAX_DISTANCE := 45.0

# Depth of field (distances relative to the focus distance)
const DOF_FAR_OFFSET := 4.0
const DOF_FAR_TRANSITION := 9.0
const DOF_NEAR_OFFSET := 7.0
const DOF_NEAR_MIN_DISTANCE := 0.5
const DOF_NEAR_TRANSITION := 4.0
const DOF_BLUR_AMOUNT := 0.14

# Dust motes
const MOTE_DEFAULT_AMOUNT := 90
const MOTE_LIFETIME := 7.0
const MOTE_PREPROCESS := 7.0
const MOTE_DIRECTION := Vector3(0.2, 1, 0)
const MOTE_SPREAD := 60.0
const MOTE_GRAVITY := Vector3(0, 0.03, 0)
const MOTE_VELOCITY_MIN := 0.05
const MOTE_VELOCITY_MAX := 0.25
const MOTE_SCALE_MIN := 0.5
const MOTE_SCALE_MAX := 1.0
const MOTE_SIZE := Vector2(0.09, 0.09)
const MOTE_EMISSION := Color(1.0, 0.85, 0.5)
const MOTE_EMISSION_ENERGY := 2.5
## Fade in, hold, fade out over the particle lifetime.
const MOTE_RAMP_OFFSETS := [0.0, 0.2, 0.8, 1.0]
const MOTE_RAMP_COLORS := [Color(1.0, 0.9, 0.6, 0.0), Color(1.0, 0.9, 0.6, 0.9),
	Color(1.0, 0.85, 0.5, 0.8), Color(1.0, 0.8, 0.4, 0.0)]


static func make_environment(mood: String = "field") -> WorldEnvironment:
	var m: Dictionary = MOODS[mood]
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = m.sky_top
	sky_mat.sky_horizon_color = m.sky_horizon
	sky_mat.ground_horizon_color = m.sky_horizon
	sky_mat.ground_bottom_color = SKY_GROUND_BOTTOM
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = m.ambient
	env.ambient_light_energy = m.ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = TONEMAP_EXPOSURE
	env.tonemap_white = TONEMAP_WHITE
	# Bloom: makes lanterns, windows, water sparkles and spell effects glow.
	env.glow_enabled = true
	env.glow_intensity = GLOW_INTENSITY
	env.glow_strength = GLOW_STRENGTH
	env.glow_bloom = GLOW_BLOOM
	env.glow_hdr_threshold = GLOW_HDR_THRESHOLD
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	for level in GLOW_LEVELS.size():
		env.set_glow_level(level, GLOW_LEVELS[level])
	# Contact shadows that ground the sprites in the scene.
	env.ssao_enabled = true
	env.ssao_radius = SSAO_RADIUS
	env.ssao_intensity = SSAO_INTENSITY
	env.ssao_power = SSAO_POWER
	env.ssao_detail = SSAO_DETAIL
	# Soft aerial perspective.
	env.fog_enabled = true
	env.fog_light_color = m.fog
	env.fog_density = m.fog_density
	env.fog_sky_affect = FOG_SKY_AFFECT
	env.fog_aerial_perspective = FOG_AERIAL_PERSPECTIVE
	# Slightly punchy grade.
	env.adjustment_enabled = true
	env.adjustment_saturation = GRADE_SATURATION
	env.adjustment_contrast = GRADE_CONTRAST
	env.adjustment_brightness = GRADE_BRIGHTNESS

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
	sun.shadow_blur = SUN_SHADOW_BLUR
	sun.shadow_bias = SUN_SHADOW_BIAS
	sun.shadow_normal_bias = SUN_SHADOW_NORMAL_BIAS
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = SUN_SHADOW_MAX_DISTANCE
	return sun


## Depth of field that keeps the playing field crisp and melts the foreground and
## background into bokeh, which sells the "miniature diorama" look.
static func make_camera_attributes(focus_distance: float) -> CameraAttributesPractical:
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = focus_distance + DOF_FAR_OFFSET
	attrs.dof_blur_far_transition = DOF_FAR_TRANSITION
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = max(focus_distance - DOF_NEAR_OFFSET, DOF_NEAR_MIN_DISTANCE)
	attrs.dof_blur_near_transition = DOF_NEAR_TRANSITION
	attrs.dof_blur_amount = DOF_BLUR_AMOUNT
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
static func make_motes(extents: Vector3, amount: int = MOTE_DEFAULT_AMOUNT) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = MOTE_LIFETIME
	p.preprocess = MOTE_PREPROCESS
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = MOTE_DIRECTION
	p.spread = MOTE_SPREAD
	p.gravity = MOTE_GRAVITY
	p.initial_velocity_min = MOTE_VELOCITY_MIN
	p.initial_velocity_max = MOTE_VELOCITY_MAX
	p.scale_amount_min = MOTE_SCALE_MIN
	p.scale_amount_max = MOTE_SCALE_MAX
	var quad := QuadMesh.new()
	quad.size = MOTE_SIZE
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SpriteFactory.particle_dot()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = MOTE_EMISSION
	mat.emission_energy_multiplier = MOTE_EMISSION_ENERGY
	quad.material = mat
	p.mesh = quad
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array(MOTE_RAMP_OFFSETS)
	grad.colors = PackedColorArray(MOTE_RAMP_COLORS)
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
