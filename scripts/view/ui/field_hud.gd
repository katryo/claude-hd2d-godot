class_name FieldHUD
extends Control
## Exploration overlay: gold counter and control hints.

const GOLD_POSITION := Vector2(24, 18)
## Offset from the bottom-left corner.
const HINT_POSITION := Vector2(24, -34)
const HINT_TEXT := "WASD/Arrows: Move   Shift: Run   Z/Enter: Talk   Tab: Status"

var _gold: Label


func _init() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold = UITheme.label("", UITheme.FONT_MEDIUM, UITheme.GOLD)
	_gold.position = GOLD_POSITION
	add_child(_gold)
	var hint := UITheme.label(HINT_TEXT, UITheme.FONT_XSMALL, UITheme.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = HINT_POSITION
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	add_child(hint)


func set_gold(amount: int) -> void:
	_gold.text = "%d G" % amount
