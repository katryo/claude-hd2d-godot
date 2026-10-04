class_name InputBindings
extends RefCounted
## Registers the game's input actions (keyboard + gamepad) at startup, so the project
## file stays free of hand-written InputEvent serialisation.

## Analog stick deadzone for every bound action.
const INPUT_DEADZONE := 0.3


static func install() -> void:
	_bind("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP])
	_bind("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN])
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT])
	_bind("accept", [KEY_ENTER, KEY_SPACE, KEY_Z, KEY_KP_ENTER], [JOY_BUTTON_A])
	_bind("cancel", [KEY_ESCAPE, KEY_X, KEY_BACKSPACE], [JOY_BUTTON_B])
	_bind("menu", [KEY_TAB, KEY_C], [JOY_BUTTON_START])
	_bind("boost_up", [KEY_E, KEY_PAGEUP], [JOY_BUTTON_RIGHT_SHOULDER])
	_bind("boost_down", [KEY_Q, KEY_PAGEDOWN], [JOY_BUTTON_LEFT_SHOULDER])
	_bind("run", [KEY_SHIFT], [JOY_BUTTON_X])
	_bind_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_bind_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


static func _bind(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, INPUT_DEADZONE)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button
		InputMap.action_add_event(action, jb)


static func _bind_axis(action: String, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
