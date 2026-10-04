class_name ChestInteraction
extends Interaction
## Opens a treasure chest once; its state is remembered as a story flag.

var _cell: Vector2i


func _init(cell: Vector2i) -> void:
	_cell = cell


func position() -> Vector3:
	return MapData.cell_center(_cell)


func run(field: Field) -> void:
	var flag := StoryData.chest_flag(_cell)
	if Game.has_flag(flag):
		await field.dialogue.say("", [StoryData.CHEST_EMPTY])
		return
	Game.set_flag(flag)
	field.view.set_chest_open(_cell)
	Audio.play_sfx(&"chest")
	var loot: Dictionary = MapData.CHESTS.get(_cell, StoryData.DEFAULT_CHEST_LOOT)
	Game.add_item(loot.item, loot.count)
	await field.dialogue.say("", [StoryData.CHEST_FOUND % [BattleData.ITEMS[loot.item].name, loot.count]])
