class_name TitleScreen
extends CanvasLayer
## Title card shown over the live field diorama.

const LAYER := 40
const SHADE_COLOR := Color(0.03, 0.03, 0.1, 0.35)
const SEPARATION := 10
const TITLE_SHADOW_OFFSET := 4
const SPACER_SIZE := Vector2(0, 60)
const FADE_OUT_TIME := 0.8
## The "Press Z" prompt pulses between this alpha and fully opaque.
const PROMPT_BLINK_ALPHA := 0.25
const PROMPT_BLINK_TIME := 0.9
const TITLE := "LUMEN HOLLOW"
const SUBTITLE := "~ An HD-2D Tale ~"
const PROMPT := "Press Z / Enter to begin"
const CONTROLS := "Move: WASD / Arrows    Confirm: Z / Enter    Cancel: X / Esc    Boost: E / Q"

var _root: Control


func _init() -> void:
	layer = LAYER
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UITheme.get_theme()
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = SHADE_COLOR
	_root.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", SEPARATION)
	_root.add_child(box)
	var title := _centered(UITheme.label(TITLE, UITheme.FONT_TITLE, UITheme.TEXT))
	title.add_theme_constant_override("shadow_offset_x", TITLE_SHADOW_OFFSET)
	title.add_theme_constant_override("shadow_offset_y", TITLE_SHADOW_OFFSET)
	box.add_child(title)
	box.add_child(_centered(UITheme.label(SUBTITLE, UITheme.FONT_HEADING, UITheme.GOLD)))
	var spacer := Control.new()
	spacer.custom_minimum_size = SPACER_SIZE
	box.add_child(spacer)
	var prompt := _centered(UITheme.label(PROMPT, UITheme.FONT_LARGE, UITheme.TEXT))
	prompt.name = "Prompt"
	box.add_child(prompt)
	box.add_child(_centered(UITheme.label(CONTROLS, UITheme.FONT_SMALL, UITheme.DIM)))
	var tw := prompt.create_tween().set_loops()
	tw.tween_property(prompt, "modulate:a", PROMPT_BLINK_ALPHA, PROMPT_BLINK_TIME)
	tw.tween_property(prompt, "modulate:a", 1.0, PROMPT_BLINK_TIME)


## Fades out and frees itself.
func dismiss() -> void:
	var tw := _root.create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, FADE_OUT_TIME)
	tw.tween_callback(queue_free)


func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
