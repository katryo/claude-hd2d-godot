class_name BattleAction
extends RefCounted
## Command pattern: one thing a combatant does on its turn. `execute()` mutates the model
## and returns the BattleEvents describing what happened, for the view to replay.

var actor: Combatant
var targets: Array = []
## Boost level spent on this action (0-3). BP is deducted by the model before execution.
var boost := 0


func _init(by: Combatant, on: Array = [], boost_level: int = 0) -> void:
	actor = by
	targets = on
	boost = boost_level


func execute(_model: BattleModel) -> Array[BattleEvent]:
	return []


## Whether spending BP on this action makes sense (Defend / Flee ignore boost).
func uses_boost() -> bool:
	return true


## Shared damage helper: applies one hit and appends HIT / SHIELD_BREAK / DEFEATED events.
static func strike(model: BattleModel, events: Array[BattleEvent], by: Combatant, on: Combatant,
		kind: String, power: float, element: String, from_skill: bool) -> void:
	var dmg := BattleRules.calc_damage(model.rng, by, on, kind, power, element)
	var dealt := on.take_damage(dmg.amount)
	events.append(BattleEvent.hit(by, on, dealt, dmg.weak, element, from_skill))
	if on.hit_shield(element):
		events.append(BattleEvent.on_target(BattleEvent.Type.SHIELD_BREAK, on))
	if not on.is_alive():
		events.append(BattleEvent.on_target(BattleEvent.Type.DEFEATED, on))
