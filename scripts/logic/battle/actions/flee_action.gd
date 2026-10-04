class_name FleeAction
extends BattleAction
## Attempts to escape. On success the model's outcome becomes FLED.

var succeeded := false


func uses_boost() -> bool:
	return false


func execute(model: BattleModel) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = [BattleEvent.message("The party tries to run...")]
	succeeded = model.can_flee() and model.rng.randf() < BattleRules.FLEE_CHANCE
	if succeeded:
		model.outcome = BattleModel.Outcome.FLED
		events.append(BattleEvent.message("Got away safely!"))
	else:
		events.append(BattleEvent.message("Couldn't escape!"))
	return events
