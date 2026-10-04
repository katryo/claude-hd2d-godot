class_name AutoPartyController
extends BattleController
## Plays party members automatically (used by --autobattle and the smoke tests):
## random boost, then a random affordable skill or a basic attack.

const SKILL_CHANCE := 0.5


func choose_action(model: BattleModel, actor: Combatant) -> BattleAction:
	var foes := model.opponents_of(actor)
	if foes.is_empty():
		return null
	var boost := model.rng.randi_range(0, model.max_boost(actor))
	var usable := actor.skills.filter(func(s): return actor.sp >= BattleData.SKILLS[s].cost)
	if not usable.is_empty() and model.rng.randf() < SKILL_CHANCE:
		var skill_id: String = usable[model.rng.randi_range(0, usable.size() - 1)]
		var targets := pick_targets(model, actor, BattleData.SKILLS[skill_id].target)
		if not targets.is_empty():
			return SkillAction.new(actor, skill_id, targets, boost)
	return AttackAction.new(actor, [foes[model.rng.randi_range(0, foes.size() - 1)]], boost)
