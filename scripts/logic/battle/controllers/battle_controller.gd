class_name BattleController
extends RefCounted
## Strategy pattern: decides what a combatant does on its turn. Implementations may be
## coroutines (the player's controller waits for input); callers always `await`.


## Returns the action to perform, or null to skip the turn.
func choose_action(_model: BattleModel, _actor: Combatant) -> BattleAction:
	return null


## Automatic controllers get a short "thinking" pause in the presentation.
func is_automatic() -> bool:
	return true


## Builds the target list for a skill or item target kind.
static func pick_targets(model: BattleModel, actor: Combatant, target_kind: String) -> Array:
	var pool := model.candidates_for(actor, target_kind)
	if pool.is_empty():
		return []
	match target_kind:
		"all_enemies", "all_allies":
			return pool
		"ally":
			# Help whoever is hurt the most.
			pool.sort_custom(func(a, b): return a.hp < b.hp)
			return [pool[0]]
	return [pool[model.rng.randi_range(0, pool.size() - 1)]]
