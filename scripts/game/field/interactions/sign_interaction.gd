class_name SignInteraction
extends Interaction
## Reads a signpost.

var _cell: Vector2i
var _lines: Array


func _init(cell: Vector2i, lines: Array) -> void:
	_cell = cell
	_lines = lines


func position() -> Vector3:
	return MapData.cell_center(_cell)


func run(field: Field) -> void:
	await field.dialogue.say("", _lines)
