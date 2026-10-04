class_name DialogueBox
extends Control
## Bottom-of-screen message window with name plate, typewriter text and optional choices.
## Usage: `var choice := await dialogue.say("Name", ["Line one", "Line two"], ["Yes", "No"])`

signal _advance

# Typewriter
const CHARS_PER_SEC := 55.0
## A typewriter blip plays every this many revealed characters.
const BLIP_EVERY_CHARS := 3

# Message window (offsets from the bottom-centre of the screen)
const PANEL_ALPHA := 0.9
const PANEL_HALF_WIDTH := 470
const PANEL_TOP := -190
const PANEL_BOTTOM := -28
const TEXT_MIN_SIZE := Vector2(0, 110)

# Name plate
const NAME_PANEL_ALPHA := 0.95
const NAME_PANEL_MARGIN_Y := 4
const NAME_PANEL_COLOR := Color(0.16, 0.1, 0.22, 0.95)
const NAME_PANEL_LEFT := -450
const NAME_PANEL_RIGHT := -300
const NAME_PANEL_TOP := -212
const NAME_PANEL_BOTTOM := -176

# "More text" arrow
const ARROW_LEFT := 438
const ARROW_TOP := -62
const ARROW_BOB_SPEED := 6.0
const ARROW_BOB_AMPLITUDE := 3.0

# Choice menu
const CHOICES_LEFT := 250
const CHOICES_TOP := -330

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
	_panel.add_theme_stylebox_override("panel", UITheme.panel_style(PANEL_ALPHA))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -PANEL_HALF_WIDTH
	_panel.offset_right = PANEL_HALF_WIDTH
	_panel.offset_top = PANEL_TOP
	_panel.offset_bottom = PANEL_BOTTOM
	add_child(_panel)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", UITheme.FONT_DIALOGUE)
	_text.add_theme_font_size_override("bold_font_size", UITheme.FONT_DIALOGUE)
	_text.custom_minimum_size = TEXT_MIN_SIZE
	_panel.add_child(_text)

	_name_panel = PanelContainer.new()
	var name_style := UITheme.panel_style(NAME_PANEL_ALPHA)
	name_style.content_margin_top = NAME_PANEL_MARGIN_Y
	name_style.content_margin_bottom = NAME_PANEL_MARGIN_Y
	name_style.bg_color = NAME_PANEL_COLOR
	_name_panel.add_theme_stylebox_override("panel", name_style)
	_name_panel.anchor_left = 0.5
	_name_panel.anchor_right = 0.5
	_name_panel.anchor_top = 1.0
	_name_panel.anchor_bottom = 1.0
	_name_panel.offset_left = NAME_PANEL_LEFT
	_name_panel.offset_right = NAME_PANEL_RIGHT
	_name_panel.offset_top = NAME_PANEL_TOP
	_name_panel.offset_bottom = NAME_PANEL_BOTTOM
	add_child(_name_panel)
	_name_label = UITheme.label("", UITheme.FONT_BODY, UITheme.GOLD)
	_name_panel.add_child(_name_label)

	_arrow = UITheme.label("▼", UITheme.FONT_MEDIUM, UITheme.GOLD)
	_arrow.anchor_left = 0.5
	_arrow.anchor_right = 0.5
	_arrow.anchor_top = 1.0
	_arrow.anchor_bottom = 1.0
	_arrow.offset_left = ARROW_LEFT
	_arrow.offset_top = ARROW_TOP
	add_child(_arrow)

	_choices = SelectMenu.new()
	_choices.anchor_left = 0.5
	_choices.anchor_right = 0.5
	_choices.anchor_top = 1.0
	_choices.anchor_bottom = 1.0
	_choices.offset_left = CHOICES_LEFT
	_choices.offset_top = CHOICES_TOP
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
		var before := _text.visible_characters
		_text.visible_characters = min(_text.visible_characters + max(1, int(CHARS_PER_SEC * delta + 0.5)), total)
		if before / BLIP_EVERY_CHARS != _text.visible_characters / BLIP_EVERY_CHARS:
			Audio.play_sfx(&"text")
		if _text.visible_characters >= total:
			_typing = false
			_waiting = true
	_arrow.visible = _waiting and not _choices.active
	_arrow.offset_top = ARROW_TOP + sin(_time * ARROW_BOB_SPEED) * ARROW_BOB_AMPLITUDE


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
			Audio.play_sfx(&"cursor")
			_advance.emit()
