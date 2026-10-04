class_name Shop
extends RefCounted
## Buying from a merchant. `wallet` needs `gold`, `add_gold()`, `add_item()` and an
## `inventory` Dictionary (the Game autoload).

enum Result { BOUGHT, TOO_POOR }

## Array of [item id, price].
var stock: Array


func _init(p_stock: Array) -> void:
	stock = p_stock


func item_id(index: int) -> String:
	return stock[index][0]


func price(index: int) -> int:
	return stock[index][1]


func buy(index: int, wallet: Object) -> Result:
	if wallet.gold < price(index):
		return Result.TOO_POOR
	wallet.add_gold(-price(index))
	wallet.add_item(item_id(index))
	return Result.BOUGHT
