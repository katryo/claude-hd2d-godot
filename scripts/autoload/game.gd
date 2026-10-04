extends Node
## Global game state: party, inventory, story flags and input setup.

signal gold_changed(amount: int)

# New-game defaults
const STARTING_GOLD := 50
const STARTING_INVENTORY := {"potion": 3, "ether": 1, "feather": 1}

## Analog stick deadzone for every bound action.
const INPUT_DEADZONE := 0.3

var party: Array[Combatant] = []
var inventory := STARTING_INVENTORY.duplicate()
var gold: int = STARTING_GOLD
var flags := {}
var steps_since_battle: int = 0


func _ready() -> void:
	_setup_input()
	new_game()


func new_game() -> void:
	party.clear()
	for id in ["aren", "lyra", "kit"]:
		party.append(BattleData.make_party_member(id))
	inventory = STARTING_INVENTORY.duplicate()
	gold = STARTING_GOLD
	flags.clear()
	steps_since_battle = 0


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count


func use_item(item_id: String) -> bool:
	if inventory.get(item_id, 0) <= 0:
		return false
	inventory[item_id] -= 1
	return true


func heal_party() -> void:
	for member in party:
		member.full_restore()


func party_alive() -> bool:
	for member in party:
		if member.is_alive():
			return true
	return false


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


# --- Input ---------------------------------------------------------------

func _setup_input() -> void:
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


func _bind(action: String, keys: Array, buttons: Array) -> void:
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


func _bind_axis(action: String, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
