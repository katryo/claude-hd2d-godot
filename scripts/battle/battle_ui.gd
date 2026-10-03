class_name BattleUI
extends Control
## HUD for battles: party status with BP pips, command menus, turn order and the
## shield/weakness readouts that float above each enemy.

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var camera: Camera3D
var actor_nodes := {}

var command_menu: SelectMenu
var sub_menu: SelectMenu
var _message_panel: PanelContainer
var _message: Label
var _help_panel: PanelContainer
var _help: Label
var _turn_box: HBoxContainer
var _party_rows := {}
var _enemy_tags := {}
var _active: Combatant
## Each character's command cursor is remembered between turns.
var _last_command := {}
var _boost_preview := 0


func _init() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(p_party: Array[Combatant], p_enemies: Array[Combatant], p_camera: Camera3D, nodes: Dictionary) -> void:
	party = p_party
	enemies = p_enemies
	camera = p_camera
	actor_nodes = nodes
	_build_message()
	_build_turn_order()
	_build_party_panel()
	_build_menus()
	_build_enemy_tags()
	refresh()


# --------------------------------------------------------------------------
# Construction
# --------------------------------------------------------------------------

func _build_message() -> void:
	_message_panel = PanelContainer.new()
	_message_panel.anchor_left = 0.5
	_message_panel.anchor_right = 0.5
	_message_panel.offset_left = -300
	_message_panel.offset_right = 300
	_message_panel.offset_top = 70
	_message_panel.visible = false
	add_child(_message_panel)
	_message = UITheme.label("", 26)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_panel.add_child(_message)

	_help_panel = PanelContainer.new()
	_help_panel.anchor_left = 0.0
	_help_panel.anchor_right = 0.0
	_help_panel.anchor_top = 1.0
	_help_panel.anchor_bottom = 1.0
	_help_panel.offset_left = 24
	_help_panel.offset_right = 560
	_help_panel.offset_top = -66
	_help_panel.offset_bottom = -20
	_help_panel.visible = false
	add_child(_help_panel)
	_help = UITheme.label("", 18, UITheme.TEXT)
	_help_panel.add_child(_help)


func _build_turn_order() -> void:
	var panel := PanelContainer.new()
	var style := UITheme.panel_style(0.7)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(20, 14)
	add_child(panel)
	_turn_box = HBoxContainer.new()
	_turn_box.add_theme_constant_override("separation", 12)
	panel.add_child(_turn_box)


func _build_party_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -560
	panel.offset_right = -20
	panel.offset_top = -190
	panel.offset_bottom = -20
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	for m in party:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var name_l := UITheme.label(m.display_name, 22)
		name_l.custom_minimum_size = Vector2(70, 0)
		row.add_child(name_l)
		var hp_box := VBoxContainer.new()
		hp_box.add_theme_constant_override("separation", 0)
		hp_box.custom_minimum_size = Vector2(150, 0)
		var hp_l := UITheme.label("", 18, UITheme.TEXT)
		hp_box.add_child(hp_l)
		var hp_bar := UITheme.make_bar(UITheme.HP_COLOR, 6)
		hp_box.add_child(hp_bar)
		row.add_child(hp_box)
		var sp_box := VBoxContainer.new()
		sp_box.add_theme_constant_override("separation", 0)
		sp_box.custom_minimum_size = Vector2(100, 0)
		var sp_l := UITheme.label("", 18, UITheme.TEXT)
		sp_box.add_child(sp_l)
		var sp_bar := UITheme.make_bar(UITheme.SP_COLOR, 6)
		sp_box.add_child(sp_bar)
		row.add_child(sp_box)
		var bp_l := Label.new()
		bp_l.add_theme_font_size_override("font_size", 22)
		row.add_child(bp_l)
		vb.add_child(row)
		_party_rows[m] = {"name": name_l, "hp": hp_l, "hp_bar": hp_bar, "sp": sp_l, "sp_bar": sp_bar, "bp": bp_l}


func _build_menus() -> void:
	command_menu = SelectMenu.new()
	command_menu.anchor_top = 1.0
	command_menu.anchor_bottom = 1.0
	command_menu.offset_left = 24
	command_menu.offset_top = -84
	command_menu.offset_bottom = -84
	command_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	command_menu.visible = false
	command_menu.cancellable = false
	add_child(command_menu)
	sub_menu = SelectMenu.new()
	sub_menu.anchor_top = 1.0
	sub_menu.anchor_bottom = 1.0
	sub_menu.offset_left = 200
	sub_menu.offset_top = -84
	sub_menu.offset_bottom = -84
	sub_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sub_menu.visible = false
	add_child(sub_menu)


func _build_enemy_tags() -> void:
	var counts := {}
	for e in enemies:
		counts[e.display_name] = counts.get(e.display_name, 0) + 1
	var seen := {}
	for e in enemies:
		if counts[e.display_name] > 1:
			seen[e.display_name] = seen.get(e.display_name, 0) + 1
			e.display_name += " " + "ABCDEFG"[seen[e.display_name] - 1]
		var tag := VBoxContainer.new()
		tag.add_theme_constant_override("separation", 2)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 6)
		top.alignment = BoxContainer.ALIGNMENT_CENTER
		var shield := Label.new()
		shield.add_theme_font_size_override("font_size", 22)
		var shield_bg := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.25, 0.3, 0.45, 0.9)
		sb.border_color = Color(0.8, 0.85, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		shield_bg.add_theme_stylebox_override("panel", sb)
		shield_bg.add_child(shield)
		top.add_child(shield_bg)
		var weak_box := HBoxContainer.new()
		weak_box.add_theme_constant_override("separation", 2)
		top.add_child(weak_box)
		tag.add_child(top)
		var name_l := UITheme.label(e.display_name, 16, UITheme.TEXT)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_child(name_l)
		var hp_bar := UITheme.make_bar(Color(0.9, 0.35, 0.35), 4)
		hp_bar.custom_minimum_size = Vector2(90, 4)
		hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tag.add_child(hp_bar)
		add_child(tag)
		_enemy_tags[e] = {"root": tag, "shield": shield, "shield_bg": shield_bg, "weak": weak_box,
			"hp": hp_bar, "name": name_l}


# --------------------------------------------------------------------------
# Updates
# --------------------------------------------------------------------------

func refresh() -> void:
	for m in _party_rows:
		var row: Dictionary = _party_rows[m]
		row.hp.text = "HP %d/%d" % [m.hp, m.max_hp]
		row.hp_bar.max_value = m.max_hp
		row.hp_bar.value = m.hp
		row.sp.text = "SP %d" % m.sp
		row.sp_bar.max_value = max(m.max_sp, 1)
		row.sp_bar.value = m.sp
		var name_color := UITheme.TEXT
		if not m.is_alive():
			name_color = Color(0.8, 0.3, 0.3)
		elif m == _active:
			name_color = UITheme.GOLD
		row.name.add_theme_color_override("font_color", name_color)
		var pips := ""
		var spend := _boost_preview if m == _active else 0
		for i in Combatant.MAX_BP:
			pips += "●" if i < m.bp else "○"
		row.bp.text = pips
		row.bp.add_theme_color_override("font_color", UITheme.BP_COLOR.lightened(0.35) if spend > 0 else UITheme.BP_COLOR)
		if spend > 0:
			row.bp.text = pips.substr(0, m.bp - spend) + "◆".repeat(spend) + pips.substr(m.bp)
	for e in _enemy_tags:
		var tag: Dictionary = _enemy_tags[e]
		tag.root.visible = e.is_alive()
		tag.shield.text = "BREAK" if e.is_broken() else "%d" % e.shield
		tag.shield.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2) if e.is_broken() else Color.WHITE)
		tag.hp.max_value = e.max_hp
		tag.hp.value = e.hp
		for child in tag.weak.get_children():
			tag.weak.remove_child(child)
			child.queue_free()
		for el in e.weaknesses:
			var revealed: bool = e.revealed_weaknesses.has(el)
			var info: Dictionary = BattleData.ELEMENT_INFO[el]
			var box := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.08, 0.08, 0.14, 0.9)
			sb.border_color = info.color if revealed else Color(0.4, 0.4, 0.5)
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(3)
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			box.add_theme_stylebox_override("panel", sb)
			var l := Label.new()
			l.text = info.label if revealed else " ? "
			l.add_theme_font_size_override("font_size", 14)
			l.add_theme_color_override("font_color", info.color if revealed else Color(0.6, 0.6, 0.7))
			box.add_child(l)
			tag.weak.add_child(box)


func _process(_delta: float) -> void:
	if not camera:
		return
	for e in _enemy_tags:
		var node: Node3D = actor_nodes.get(e)
		if not node:
			continue
		var top := node.global_position + Vector3(0, 1.55 * e.sprite_scale + 0.2, 0)
		var screen := camera.unproject_position(top)
		var tag: Control = _enemy_tags[e].root
		tag.position = screen - Vector2(tag.size.x * 0.5, tag.size.y)


func set_active(actor: Combatant) -> void:
	_active = actor
	_boost_preview = 0
	refresh()


func set_boost_preview(level: int) -> void:
	_boost_preview = level
	refresh()


func set_turn_order(order: Array) -> void:
	for child in _turn_box.get_children():
		_turn_box.remove_child(child)
		child.queue_free()
	_turn_box.add_child(UITheme.label("Turn:", 18, UITheme.GOLD))
	for c in order:
		var l := UITheme.label(c.display_name, 18, Color(1.0, 0.6, 0.6) if c.is_enemy else Color(0.7, 0.85, 1.0))
		_turn_box.add_child(l)


func mark_turn_done(index: int) -> void:
	# index 0 is the "Turn:" caption.
	var child := _turn_box.get_child(index + 1) as Label
	if child:
		child.modulate.a = 0.35


func show_message(text: String) -> void:
	_message.text = text
	_message_panel.visible = true


func hide_message() -> void:
	_message_panel.visible = false


func show_help(text: String) -> void:
	_help.text = text
	_help_panel.visible = text != ""


# --------------------------------------------------------------------------
# Menus
# --------------------------------------------------------------------------

func choose_command(actor: Combatant, can_flee: bool) -> String:
	var cmds := [
		{"text": "Attack", "id": "attack", "help": "Strike with %s. Boost adds extra hits." % actor.weapon.capitalize()},
		{"text": "Skills", "id": "skill", "help": "Use a skill. Boost multiplies its power."},
		{"text": "Items", "id": "item", "help": "Use an item from the bag."},
		{"text": "Defend", "id": "defend", "help": "Halve damage taken until your next turn."},
		{"text": "Flee", "id": "flee", "help": "Try to escape.", "enabled": can_flee},
	]
	command_menu.set_items(cmds, _last_command.get(actor, 0))
	var on_hover := func(i: int) -> void:
		show_help(cmds[i].help + "   [Q/E: Boost]")
	command_menu.hovered.connect(on_hover)
	command_menu.open()
	var idx: int = await command_menu.finished
	command_menu.hovered.disconnect(on_hover)
	command_menu.close()
	if idx >= 0:
		_last_command[actor] = idx
	show_help("")
	return cmds[idx].id if idx >= 0 else ""


func choose_skill(actor: Combatant) -> String:
	var items := []
	for s in actor.skills:
		var d: Dictionary = BattleData.SKILLS[s]
		items.append({"text": d.name, "id": s, "right": "%d SP" % d.cost, "enabled": actor.sp >= d.cost,
			"help": d.desc})
	return await _sub_choose(items)


func choose_item() -> String:
	var items := []
	for id in Game.inventory:
		var count: int = Game.inventory[id]
		if count <= 0:
			continue
		var d: Dictionary = BattleData.ITEMS[id]
		items.append({"text": d.name, "id": id, "right": "x%d" % count, "help": d.desc})
	if items.is_empty():
		items.append({"text": "(empty)", "id": "", "enabled": false, "help": "No items left."})
	return await _sub_choose(items)


func _sub_choose(items: Array) -> String:
	command_menu.visible = true
	sub_menu.set_items(items)
	var on_hover := func(i: int) -> void:
		show_help(items[i].get("help", ""))
	sub_menu.hovered.connect(on_hover)
	sub_menu.open()
	var idx: int = await sub_menu.finished
	sub_menu.hovered.disconnect(on_hover)
	sub_menu.close()
	command_menu.visible = false
	show_help("")
	return items[idx].id if idx >= 0 else ""
