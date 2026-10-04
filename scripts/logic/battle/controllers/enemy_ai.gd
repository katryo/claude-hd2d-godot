class_name EnemyAI
extends BattleController
## Monsters attack a random party member, sometimes using one of their skills instead.

const SKILL_CHANCE := 0.3
const BOSS_SKILL_CHANCE := 0.45


func choose_action(model: BattleModel, actor: Combatant) -> BattleAction:
	var foes := model.opponents_of(actor)
	if foes.is_empty():
		return null
	var chance := BOSS_SKILL_CHANCE if model.is_boss else SKILL_CHANCE
	if not actor.skills.is_empty() and model.rng.randf() < chance:
		var skill_id: String = actor.skills[model.rng.randi_range(0, actor.skills.size() - 1)]
		var kind: String = BattleData.SKILLS[skill_id].target
		# Enemy skills either hit everyone or one random party member.
		var targets := foes if kind == "all_enemies" else [foes[model.rng.randi_range(0, foes.size() - 1)]]
		return SkillAction.new(actor, skill_id, targets)
	return AttackAction.new(actor, [foes[model.rng.randi_range(0, foes.size() - 1)]])
