class_name SelectMenu
extends PanelContainer
## Keyboard/gamepad driven list menu with a cursor. Await `finished` for the chosen
## index (-1 when cancelled).

signal finished(index: int)
signal hovered(index: int)

# Layout
const ROW_SEPARATION := 4
const COLUMN_SEPARATION := 28

# Highlight
## How much lighter a disabled item gets when the cursor is on it.
const DISABLED_HIGHLIGHT_LIGHTEN := 0.2
## The selected item's alpha pulses around BASE by +/- DEPTH.
const CURSOR_BLINK_BASE_ALPHA := 0.75
const CURSOR_BLINK_DEPTH := 0.25
const CURSOR_BLINK_SPEED := 8.0

var items: Array = []
var index := 0
var active := false
var cancellable := true
var columns := 1

var _box: GridContainer
var _labels: Array[Label] = []
var _blink := 0.0


func _init() -> void:
	theme = UITheme.get_theme()
	_box = GridContainer.new()
	_box.add_theme_constant_override("v_separation", ROW_SEPARATION)
	_box.add_theme_constant_override("h_separation", COLUMN_SEPARATION)
	add_child(_box)


## items: Array of { "text": String, "enabled": bool (optional), "right": String (optional) }
func set_items(new_items: Array, start_index: int = 0) -> void:
	items = new_items
	_box.columns = columns
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_labels.clear()
	for item in items:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		_box.add_child(l)
		_labels.append(l)
	index = clampi(start_index, 0, max(items.size() - 1, 0))
	_refresh()


func open() -> void:
	active = true
	visible = true
	_refresh()
	hovered.emit(index)


func close() -> void:
	active = false
	visible = false


func _refresh() -> void:
	for i in _labels.size():
		var item: Dictionary = items[i]
		var enabled: bool = item.get("enabled", true)
		var prefix := "▶ " if (i == index and active) else "   "
		var right: String = item.get("right", "")
		_labels[i].text = prefix + item.text + ("   " + right if right != "" else "")
		var col := UITheme.TEXT if enabled else UITheme.DIM
		if i == index and active:
			col = UITheme.GOLD if enabled else UITheme.DIM.lightened(DISABLED_HIGHLIGHT_LIGHTEN)
		_labels[i].add_theme_color_override("font_color", col)


func _process(delta: float) -> void:
	if not active or _labels.is_empty():
		return
	_blink += delta
	_labels[index].modulate.a = CURSOR_BLINK_BASE_ALPHA + CURSOR_BLINK_DEPTH * sin(_blink * CURSOR_BLINK_SPEED)


func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		return
	var moved := 0
	if event.is_action_pressed("move_down", true):
		moved = columns
	elif event.is_action_pressed("move_up", true):
		moved = -columns
	elif columns > 1 and event.is_action_pressed("move_right", true):
		moved = 1
	elif columns > 1 and event.is_action_pressed("move_left", true):
		moved = -1
	elif event.is_action_pressed("accept"):
		get_viewport().set_input_as_handled()
		if items.is_empty() or not items[index].get("enabled", true):
			return
		_choose(index)
		return
	elif event.is_action_pressed("cancel") and cancellable:
		get_viewport().set_input_as_handled()
		_choose(-1)
		return
	if moved != 0 and not items.is_empty():
		get_viewport().set_input_as_handled()
		_labels[index].modulate.a = 1.0
		index = posmod(index + moved, items.size())
		_refresh()
		hovered.emit(index)


func _choose(i: int) -> void:
	active = false
	if not _labels.is_empty():
		_labels[index].modulate.a = 1.0
	_refresh()
	finished.emit(i)
