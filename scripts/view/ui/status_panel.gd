class_name StatusPanel
extends PanelContainer
## Pause-menu window listing the party, the bag, gold and the current goal.

const HALF_WIDTH := 380
const HALF_HEIGHT := 230
const SEPARATION := 10
const ROW_SEPARATION := 26
const NAME_MIN_SIZE := Vector2(90, 0)


func _init() -> void:
	theme = UITheme.get_theme()
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -HALF_WIDTH
	offset_right = HALF_WIDTH
	offset_top = -HALF_HEIGHT
	offset_bottom = HALF_HEIGHT
	visible = false


func open(party: Array[Combatant], inventory: Dictionary, gold: int, objective: String) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", SEPARATION)
	add_child(vb)
	vb.add_child(UITheme.label("Party", UITheme.FONT_HEADING, UITheme.GOLD))
	for m in party:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", ROW_SEPARATION)
		var name_l := UITheme.label(m.display_name, UITheme.FONT_LARGE)
		name_l.custom_minimum_size = NAME_MIN_SIZE
		row.add_child(name_l)
		row.add_child(UITheme.label("Lv %d" % m.level, UITheme.FONT_BODY, UITheme.GOLD))
		row.add_child(UITheme.label("HP %d/%d" % [m.hp, m.max_hp], UITheme.FONT_BODY, UITheme.HP_COLOR))
		row.add_child(UITheme.label("SP %d/%d" % [m.sp, m.max_sp], UITheme.FONT_BODY, UITheme.SP_COLOR))
		row.add_child(UITheme.label("ATK %d  MAG %d  DEF %d  SPD %d" % [m.atk, m.mag, m.def, m.spd],
			UITheme.FONT_SMALL, UITheme.DIM))
		vb.add_child(row)
	vb.add_child(HSeparator.new())
	vb.add_child(UITheme.label("Items", UITheme.FONT_HEADING, UITheme.GOLD))
	for id in inventory:
		if inventory[id] > 0:
			var item: Dictionary = BattleData.ITEMS[id]
			vb.add_child(UITheme.label("%s  x%d   - %s" % [item.name, inventory[id], item.desc], UITheme.FONT_MEDIUM))
	vb.add_child(HSeparator.new())
	vb.add_child(UITheme.label("Gold: %d G" % gold, UITheme.FONT_BODY, UITheme.GOLD))
	vb.add_child(UITheme.label("Goal: " + objective, UITheme.FONT_MEDIUM, UITheme.TEXT))
	visible = true


func close() -> void:
	visible = false
