class_name DefendAction
extends BattleAction
## Halves damage taken until the end of the round.


func uses_boost() -> bool:
	return false


func execute(_model: BattleModel) -> Array[BattleEvent]:
	actor.defending = true
	var events: Array[BattleEvent] = [BattleEvent.message("%s braces for impact." % actor.display_name)]
	return events
