class_name BattleEffects
extends Node3D
## Transient battle visuals: damage numbers, particle bursts, the "BREAK!" callout and
## the Boost aura.

const LABEL3D_PIXEL_SIZE := 0.006

# Damage / heal popups
const POPUP_FONT_SIZE := 72
const POPUP_FONT_SIZE_BIG := 96
const POPUP_OUTLINE_SIZE := 20
const POPUP_OUTLINE_COLOR := Color(0.1, 0.05, 0.1)
const POPUP_RENDER_PRIORITY := 10
const POPUP_OUTLINE_RENDER_PRIORITY := 9
const POPUP_OFFSET := Vector3(0, 1.4, 0)
## Consecutive popups cycle through a small grid so multi-hit numbers don't overlap.
const POPUP_STAGGER_COLUMNS := 3
const POPUP_STAGGER_ROWS := 2
const POPUP_STAGGER_X := 0.45
const POPUP_STAGGER_Y := 0.35
const POPUP_STAGGER_Z := 0.3
const POPUP_RISE := 0.7
const POPUP_RISE_TIME := 0.8
const POPUP_FADE_TIME := 0.4
const POPUP_FADE_DELAY := 0.6

# "BREAK!" callout
const BREAK_FONT_SIZE := 140
const BREAK_OUTLINE_SIZE := 14
const BREAK_OUTLINE_COLOR := Color(0.35, 0.08, 0.0)
const BREAK_TEXT_COLOR := Color(1.0, 0.85, 0.3)
const BREAK_RENDER_PRIORITY := 11
const BREAK_TEXT_OFFSET := Vector3(0, 1.2, 0.5)
const BREAK_TEXT_START_SCALE := 0.3
const BREAK_TEXT_POP_SCALE := 1.1
const BREAK_TEXT_POP_TIME := 0.15
const BREAK_TEXT_HOLD_TIME := 0.5
const BREAK_TEXT_FADE_TIME := 0.3

# Particle bursts
const BURST_COLORS := {
	"sword": Color(0.9, 0.95, 1.0), "bow": Color(0.7, 1.0, 0.5), "staff": Color(0.9, 0.75, 0.5),
	"fire": Color(1.0, 0.45, 0.15), "ice": Color(0.5, 0.85, 1.0), "thunder": Color(1.0, 0.95, 0.3),
	"light": Color(1.0, 0.95, 0.7), "heal": Color(0.45, 1.0, 0.55), "boost": Color(1.0, 0.6, 0.2),
	"dark": Color(0.7, 0.35, 1.0), "break": Color(1.0, 0.7, 0.3), "death": Color(0.9, 0.6, 1.0),
	"": Color(1, 1, 1),
}
const BURST_EXPLOSIVENESS := 0.9
const BURST_PARTICLES := 28
const BURST_MIN_PARTICLES := 4
const BURST_PARTICLE_LIFETIME := 0.7
const BURST_SPARK_SIZE := 0.11
const BURST_SPREAD := 180.0
const BURST_VELOCITY_MIN := 1.5
const BURST_VELOCITY_MAX := 3.5
const BURST_GRAVITY := -3.0
## Healing sparkles float upward instead of falling.
const HEAL_BURST_GRAVITY := 1.5
const BURST_DAMPING_MIN := 2.0
const BURST_DAMPING_MAX := 4.0
const BURST_RAMP_START := Color(1, 1, 1, 1)
const BURST_RAMP_END := Color(1, 1, 1, 0)
const BURST_LIGHT_ENERGY := 3.0
const BURST_LIGHT_RANGE := 4.0
const BURST_LIGHT_OFFSET := Vector3(0, 0.3, 0.6)
const BURST_LIGHT_FADE_TIME := 0.5
const BURST_CLEANUP_TIME := 1.5
const SPARK_EMISSION_ENERGY := 3.0

# Boost aura
const BOOST_AURA_START_AMOUNT := 40
const BOOST_AURA_BASE_AMOUNT := 20
const BOOST_AURA_AMOUNT_PER_LEVEL := 25
const BOOST_AURA_SCALE_PER_LEVEL := 0.5
const BOOST_AURA_LIFETIME := 0.9
const BOOST_AURA_RADIUS := 0.5
const BOOST_AURA_SPREAD := 15
const BOOST_AURA_GRAVITY := Vector3(0, 2.0, 0)
const BOOST_AURA_VELOCITY_MIN := 0.3
const BOOST_AURA_VELOCITY_MAX := 0.8
const BOOST_AURA_COLOR := Color(1.0, 0.55, 0.15)
const BOOST_AURA_SPARK_SIZE := 0.08
const BOOST_AURA_OFFSET := Vector3(0, 0.6, 0)

var _popup_count := 0
var _boost_aura: CPUParticles3D


func _ready() -> void:
	_boost_aura = CPUParticles3D.new()
	_boost_aura.emitting = false
	_boost_aura.amount = BOOST_AURA_START_AMOUNT
	_boost_aura.lifetime = BOOST_AURA_LIFETIME
	_boost_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_boost_aura.emission_sphere_radius = BOOST_AURA_RADIUS
	_boost_aura.direction = Vector3.UP
	_boost_aura.spread = BOOST_AURA_SPREAD
	_boost_aura.gravity = BOOST_AURA_GRAVITY
	_boost_aura.initial_velocity_min = BOOST_AURA_VELOCITY_MIN
	_boost_aura.initial_velocity_max = BOOST_AURA_VELOCITY_MAX
	_boost_aura.mesh = _spark_mesh(BOOST_AURA_COLOR, BOOST_AURA_SPARK_SIZE)
	_boost_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_boost_aura)


## Shows the Boost aura around `at` scaled by boost level (0 hides it).
func show_boost(at: Vector3, level: int) -> void:
	_boost_aura.global_position = at + BOOST_AURA_OFFSET
	_boost_aura.emitting = level > 0
	_boost_aura.amount = BOOST_AURA_BASE_AMOUNT + level * BOOST_AURA_AMOUNT_PER_LEVEL
	_boost_aura.scale_amount_max = 1.0 + level * BOOST_AURA_SCALE_PER_LEVEL


func hide_boost() -> void:
	_boost_aura.emitting = false


func popup(at: Vector3, text: String, color: Color, big: bool = false) -> void:
	var l := _make_label(text, POPUP_FONT_SIZE_BIG if big else POPUP_FONT_SIZE, POPUP_OUTLINE_SIZE,
		color, POPUP_OUTLINE_COLOR, POPUP_RENDER_PRIORITY)
	l.outline_render_priority = POPUP_OUTLINE_RENDER_PRIORITY
	_popup_count += 1
	var stagger := Vector3((_popup_count % POPUP_STAGGER_COLUMNS - 1) * POPUP_STAGGER_X,
		(_popup_count % POPUP_STAGGER_ROWS) * POPUP_STAGGER_Y, POPUP_STAGGER_Z)
	l.global_position = at + POPUP_OFFSET + stagger
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + POPUP_RISE, POPUP_RISE_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, POPUP_FADE_TIME).set_delay(POPUP_FADE_DELAY)
	tw.tween_property(l, "outline_modulate:a", 0.0, POPUP_FADE_TIME).set_delay(POPUP_FADE_DELAY)
	tw.chain().tween_callback(l.queue_free)


func break_callout(at: Vector3) -> void:
	var l := _make_label("BREAK!", BREAK_FONT_SIZE, BREAK_OUTLINE_SIZE, BREAK_TEXT_COLOR,
		BREAK_OUTLINE_COLOR, BREAK_RENDER_PRIORITY)
	l.global_position = at + BREAK_TEXT_OFFSET
	l.scale = Vector3.ONE * BREAK_TEXT_START_SCALE
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * BREAK_TEXT_POP_SCALE, BREAK_TEXT_POP_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(BREAK_TEXT_HOLD_TIME)
	tw.tween_property(l, "modulate:a", 0.0, BREAK_TEXT_FADE_TIME)
	tw.tween_callback(l.queue_free)


func burst(at: Vector3, element: String, strength: float = 1.0) -> void:
	var color: Color = BURST_COLORS.get(element, Color.WHITE)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = BURST_EXPLOSIVENESS
	p.amount = int(BURST_PARTICLES * strength) + BURST_MIN_PARTICLES
	p.lifetime = BURST_PARTICLE_LIFETIME
	p.mesh = _spark_mesh(color, BURST_SPARK_SIZE)
	p.direction = Vector3.UP
	p.spread = BURST_SPREAD
	p.initial_velocity_min = BURST_VELOCITY_MIN * strength
	p.initial_velocity_max = BURST_VELOCITY_MAX * strength
	p.gravity = Vector3(0, HEAL_BURST_GRAVITY if element == "heal" else BURST_GRAVITY, 0)
	p.damping_min = BURST_DAMPING_MIN
	p.damping_max = BURST_DAMPING_MAX
	var grad := Gradient.new()
	grad.set_color(0, BURST_RAMP_START)
	grad.set_color(1, BURST_RAMP_END)
	p.color_ramp = grad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = at
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = BURST_LIGHT_ENERGY * strength
	light.omni_range = BURST_LIGHT_RANGE
	add_child(light)
	light.global_position = at + BURST_LIGHT_OFFSET
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, BURST_LIGHT_FADE_TIME)
	tw.tween_callback(light.queue_free)
	get_tree().create_timer(BURST_CLEANUP_TIME).timeout.connect(p.queue_free)


func _make_label(text: String, font_size: int, outline: int, color: Color, outline_color: Color,
		priority: int) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.outline_size = outline
	l.outline_modulate = outline_color
	l.pixel_size = LABEL3D_PIXEL_SIZE
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = priority
	add_child(l)
	return l


static func _spark_mesh(color: Color, size: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = SpriteFactory.particle_dot()
	mat.albedo_color = color
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = SPARK_EMISSION_ENERGY
	quad.material = mat
	return quad
