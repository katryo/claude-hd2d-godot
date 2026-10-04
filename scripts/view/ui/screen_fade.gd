class_name ScreenFade
extends ColorRect
## Full-screen fade to black and back (used when resting at the inn).

const FADE_TIME := 0.6


func _init() -> void:
	color = Color(0, 0, 0, 0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "color:a", 1.0, FADE_TIME)
	await tw.finished


func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(self, "color:a", 0.0, FADE_TIME)
	await tw.finished
