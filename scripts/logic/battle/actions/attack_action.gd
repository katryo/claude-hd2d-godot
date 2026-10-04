class_name AttackAction
extends BattleAction
## Basic weapon attack. Each boost level adds one extra hit.


func execute(model: BattleModel) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var target: Combatant = targets[0]
	if actor.is_enemy:
		events.append(BattleEvent.message("%s attacks %s!" % [actor.display_name, target.display_name]))
	events.append(BattleEvent.action_start(actor, target, BattleEvent.Motion.LUNGE))
	for i in BattleRules.attack_hits(boost):
		if not target.is_alive():
			break
		strike(model, events, actor, target, "physical", BattleRules.BASIC_ATTACK_POWER, actor.weapon, false)
	events.append(BattleEvent.action_end(actor, BattleEvent.Motion.LUNGE))
	return events
