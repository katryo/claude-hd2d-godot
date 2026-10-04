class_name UITheme
extends RefCounted
## JRPG-style window theme (deep navy panels with gold trim), built in code.

const GOLD := Color(0.93, 0.79, 0.45)
const TEXT := Color(0.96, 0.94, 0.88)
const DIM := Color(0.55, 0.55, 0.62)
const HP_COLOR := Color(0.45, 0.85, 0.45)
const SP_COLOR := Color(0.45, 0.7, 1.0)
const BP_COLOR := Color(1.0, 0.62, 0.25)

# Shared font sizes (pixels), smallest to largest.
const FONT_TINY := 14
const FONT_XSMALL := 16
const FONT_SMALL := 18
const FONT_MEDIUM := 20
const FONT_BODY := 22
const FONT_LARGE := 24
const FONT_DIALOGUE := 25
const FONT_MESSAGE := 26
const FONT_HEADING := 28
const FONT_BANNER := 46
const FONT_TITLE := 76

const TEXT_SHADOW_COLOR := Color(0, 0, 0, 0.75)
const TEXT_SHADOW_OFFSET := 2

const PANEL_COLOR := Color(0.05, 0.06, 0.16)
const PANEL_ALPHA := 0.86
const PANEL_BORDER_WIDTH := 2
const PANEL_CORNER_RADIUS := 6
const PANEL_SHADOW_COLOR := Color(0, 0, 0, 0.45)
const PANEL_SHADOW_SIZE := 6
const PANEL_SHADOW_OFFSET := Vector2(2, 3)
const PANEL_MARGIN_X := 18
const PANEL_MARGIN_Y := 12

const BAR_BG_COLOR := Color(0.02, 0.02, 0.05, 0.7)
const BAR_CORNER_RADIUS := 3
const BAR_DEFAULT_HEIGHT := 8.0
## ProgressBar has no text when show_percentage is off, so its font is shrunk to nothing.
const BAR_FONT_SIZE := 1

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_BODY
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("panel", "Panel", panel_style())
	t.set_color("font_color", "Label", TEXT)
	for type in ["Label", "RichTextLabel"]:
		t.set_color("font_shadow_color", type, TEXT_SHADOW_COLOR)
		t.set_constant("shadow_offset_x", type, TEXT_SHADOW_OFFSET)
		t.set_constant("shadow_offset_y", type, TEXT_SHADOW_OFFSET)
	t.set_color("default_color", "RichTextLabel", TEXT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG_COLOR
	bg.set_corner_radius_all(BAR_CORNER_RADIUS)
	var fill := StyleBoxFlat.new()
	fill.bg_color = HP_COLOR
	fill.set_corner_radius_all(BAR_CORNER_RADIUS)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_font_size("font_size", "ProgressBar", BAR_FONT_SIZE)
	_theme = t
	return t


static func panel_style(alpha: float = PANEL_ALPHA) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PANEL_COLOR, alpha)
	sb.border_color = GOLD
	sb.set_border_width_all(PANEL_BORDER_WIDTH)
	sb.set_corner_radius_all(PANEL_CORNER_RADIUS)
	sb.shadow_color = PANEL_SHADOW_COLOR
	sb.shadow_size = PANEL_SHADOW_SIZE
	sb.shadow_offset = PANEL_SHADOW_OFFSET
	sb.content_margin_left = PANEL_MARGIN_X
	sb.content_margin_right = PANEL_MARGIN_X
	sb.content_margin_top = PANEL_MARGIN_Y
	sb.content_margin_bottom = PANEL_MARGIN_Y
	return sb


static func make_bar(color: Color, height: float = BAR_DEFAULT_HEIGHT) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(BAR_CORNER_RADIUS)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func label(text: String, size: int = FONT_BODY, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
