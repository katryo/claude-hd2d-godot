class_name DialogueBox
extends Control
## Bottom-of-screen message window with name plate, typewriter text and optional choices.
## Usage: `var choice := await dialogue.say("Name", ["Line one", "Line two"], ["Yes", "No"])`

signal _advance

const CHARS_PER_SEC := 55.0

var _panel: PanelContainer
var _name_panel: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _arrow: Label
var _choices: SelectMenu
var _typing := false
var _waiting := false
var _time := 0.0

var is_open: bool:
	get:
		return visible


func _init() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style(0.9))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -470
	_panel.offset_right = 470
	_panel.offset_top = -190
	_panel.offset_bottom = -28
	add_child(_panel)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_font_size_override("bold_font_size", 25)
	_text.custom_minimum_size = Vector2(0, 110)
	_panel.add_child(_text)

	_name_panel = PanelContainer.new()
	var name_style := UITheme.panel_style(0.95)
	name_style.content_margin_top = 4
	name_style.content_margin_bottom = 4
	name_style.bg_color = Color(0.16, 0.1, 0.22, 0.95)
	_name_panel.add_theme_stylebox_override("panel", name_style)
	_name_panel.anchor_left = 0.5
	_name_panel.anchor_right = 0.5
	_name_panel.anchor_top = 1.0
	_name_panel.anchor_bottom = 1.0
	_name_panel.offset_left = -450
	_name_panel.offset_right = -300
	_name_panel.offset_top = -212
	_name_panel.offset_bottom = -176
	add_child(_name_panel)
	_name_label = UITheme.label("", 22, UITheme.GOLD)
	_name_panel.add_child(_name_label)

	_arrow = UITheme.label("▼", 20, UITheme.GOLD)
	_arrow.anchor_left = 0.5
	_arrow.anchor_right = 0.5
	_arrow.anchor_top = 1.0
	_arrow.anchor_bottom = 1.0
	_arrow.offset_left = 438
	_arrow.offset_top = -62
	add_child(_arrow)

	_choices = SelectMenu.new()
	_choices.anchor_left = 0.5
	_choices.anchor_right = 0.5
	_choices.anchor_top = 1.0
	_choices.anchor_bottom = 1.0
	_choices.offset_left = 250
	_choices.offset_top = -330
	_choices.visible = false
	add_child(_choices)


func say(speaker: String, lines: Array, choices: Array = []) -> int:
	visible = true
	_name_panel.visible = speaker != ""
	_name_label.text = speaker
	for i in lines.size():
		_text.text = lines[i]
		_text.visible_characters = 0
		_typing = true
		_waiting = false
		if i == lines.size() - 1 and not choices.is_empty():
			while _typing:
				await get_tree().process_frame
			_waiting = false
			break
		await _advance
	var result := -1
	if not choices.is_empty():
		var items := []
		for c in choices:
			items.append({"text": c})
		_choices.cancellable = true
		_choices.set_items(items)
		_choices.open()
		result = await _choices.finished
		_choices.close()
		if result == -1:
			result = choices.size() - 1
	visible = false
	_typing = false
	_waiting = false
	return result


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _typing:
		var total := _text.get_total_character_count()
		_text.visible_characters = min(_text.visible_characters + max(1, int(CHARS_PER_SEC * delta + 0.5)), total)
		if _text.visible_characters >= total:
			_typing = false
			_waiting = true
	_arrow.visible = _waiting and not _choices.active
	_arrow.offset_top = -62 + sin(_time * 6.0) * 3.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _choices.active:
		return
	if event.is_action_pressed("accept") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _typing:
			_text.visible_characters = -1
			_typing = false
			_waiting = true
		elif _waiting:
			_waiting = false
			_advance.emit()
