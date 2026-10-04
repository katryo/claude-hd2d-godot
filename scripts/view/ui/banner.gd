class_name Banner
extends Control
## Centered title card ("Lumen Hollow", "VICTORY", ...) that fades in and out.

# Layout
const TOP_OFFSET := 90
const SEPARATION := 6
const TITLE_SHADOW_OFFSET := 3
## Gold rule drawn above and below the text.
const LINE_SIZE := Vector2(420, 2)

# Timing (seconds)
const FADE_IN_TIME := 0.6
const DEFAULT_HOLD := 2.2
const FADE_OUT_TIME := 0.8

var _title: Label
var _subtitle: Label
var _line_top: ColorRect
var _line_bottom: ColorRect
var _tween: Tween


func _init() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.offset_top = TOP_OFFSET
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", SEPARATION)
	add_child(box)
	_line_top = _make_line()
	box.add_child(_line_top)
	_title = UITheme.label("", UITheme.FONT_BANNER, UITheme.TEXT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("shadow_offset_x", TITLE_SHADOW_OFFSET)
	_title.add_theme_constant_override("shadow_offset_y", TITLE_SHADOW_OFFSET)
	box.add_child(_title)
	_subtitle = UITheme.label("", UITheme.FONT_BODY, UITheme.GOLD)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	_line_bottom = _make_line()
	box.add_child(_line_bottom)
	modulate.a = 0.0


func _make_line() -> ColorRect:
	var r := ColorRect.new()
	r.color = UITheme.GOLD
	r.custom_minimum_size = LINE_SIZE
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return r


func show_text(title: String, subtitle: String = "", hold: float = DEFAULT_HOLD) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_TIME)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_TIME)
	await _tween.finished
