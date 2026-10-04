class_name SkillAction
extends BattleAction
## Uses a skill from BattleData.SKILLS. Boost multiplies its power.

var skill_id := ""


func _init(by: Combatant, id: String, on: Array = [], boost_level: int = 0) -> void:
	super(by, on, boost_level)
	skill_id = id


func skill() -> Dictionary:
	return BattleData.SKILLS[skill_id]


func execute(model: BattleModel) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var s := skill()
	actor.spend_sp(s.cost)
	if actor.is_enemy:
		events.append(BattleEvent.message("%s uses %s!" % [actor.display_name, s.name]))
	else:
		events.append(BattleEvent.message(s.name + ("  (Boost x%d)" % boost if boost > 0 else "")))
	var single_physical: bool = s.kind == "physical" and targets.size() == 1
	var motion := BattleEvent.Motion.LUNGE if single_physical else BattleEvent.Motion.CAST
	var first: Combatant = targets[0] if not targets.is_empty() else null
	events.append(BattleEvent.action_start(actor, first, motion, s.element))
	match s.kind:
		"physical", "magic":
			var power: float = s.power * BattleRules.skill_power_mult(boost)
			for t in targets:
				for h in int(s.hits):
					if not t.is_alive():
						break
					strike(model, events, actor, t, s.kind, power, s.element, true)
		"heal":
			for t in targets:
				var healed := (t as Combatant).heal(BattleRules.heal_amount(actor, s.power, boost))
				events.append(BattleEvent.on_target(BattleEvent.Type.HEAL, t, healed))
		"buff_bp":
			var amount := BattleRules.bp_buff_amount(boost)
			for t in targets:
				(t as Combatant).gain_bp(amount)
				events.append(BattleEvent.on_target(BattleEvent.Type.BP_GAIN, t, amount))
	events.append(BattleEvent.action_end(actor, motion))
	return events
