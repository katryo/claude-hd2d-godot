class_name Banner
extends Control
## Centered title card ("Lumen Hollow", "VICTORY", ...) that fades in and out.

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
	box.offset_top = 90
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_line_top = _make_line()
	box.add_child(_line_top)
	_title = UITheme.label("", 46, UITheme.TEXT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("shadow_offset_x", 3)
	_title.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(_title)
	_subtitle = UITheme.label("", 22, UITheme.GOLD)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)
	_line_bottom = _make_line()
	box.add_child(_line_bottom)
	modulate.a = 0.0


func _make_line() -> ColorRect:
	var r := ColorRect.new()
	r.color = UITheme.GOLD
	r.custom_minimum_size = Vector2(420, 2)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return r


func show_text(title: String, subtitle: String = "", hold: float = 2.2) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.6)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	await _tween.finished
