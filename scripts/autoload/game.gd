extends Node
## Global game state: party, inventory, gold and story flags.

signal gold_changed(amount: int)

# New-game defaults
const STARTING_GOLD := 50
const STARTING_INVENTORY := {"potion": 3, "ether": 1, "feather": 1}

var party: Array[Combatant] = []
var inventory := STARTING_INVENTORY.duplicate()
var gold: int = STARTING_GOLD
var flags := {}


func _ready() -> void:
	InputBindings.install()
	new_game()


func new_game() -> void:
	party.clear()
	for id in ["aren", "lyra", "kit"]:
		party.append(BattleData.make_party_member(id))
	inventory = STARTING_INVENTORY.duplicate()
	gold = STARTING_GOLD
	flags.clear()


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
