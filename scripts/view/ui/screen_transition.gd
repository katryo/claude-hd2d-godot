class_name ScreenTransition
extends CanvasLayer
## Diamond-pattern screen wipe used between the field and battles.

const LAYER := 50

var _rect: ColorRect
var _material: ShaderMaterial


func _init() -> void:
	layer = LAYER
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/transition.gdshader")
	_rect.material = _material
	add_child(_rect)


func _ready() -> void:
	_set_progress(0.0)


## Wipes the screen to black.
func cover(duration: float) -> void:
	await _animate(0.0, 1.0, duration)


## Wipes the black away again.
func reveal(duration: float) -> void:
	await _animate(1.0, 0.0, duration)


func _animate(from: float, to: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_method(_set_progress, from, to, duration)
	await tw.finished


func _set_progress(p: float) -> void:
	_material.set_shader_parameter("progress", p)
	var vp := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2.ONE
	_material.set_shader_parameter("aspect", Vector2(vp.x / vp.y, 1.0))
