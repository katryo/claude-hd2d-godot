class_name BattleRules
extends RefCounted
## Pure battle formulas (no nodes, no visuals). Everything that decides numbers lives here.

# Turn flow
const BP_PER_ROUND := 1
## Random 0..N added to speed when sorting the turn order.
const TURN_ORDER_JITTER := 4
## Broken combatants are pushed to the end of the turn order.
const BROKEN_TURN_PENALTY := 100
const FLEE_CHANCE := 0.75

# Damage
const BASIC_ATTACK_POWER := 1.0
const MAGIC_ARMOR_FACTOR := 0.6
const DAMAGE_POWER_SCALE := 2.2
## Damage never drops below this fraction of stat * power (before variance).
const MIN_DAMAGE_FACTOR := 0.4
const DAMAGE_VARIANCE_MIN := 0.9
const DAMAGE_VARIANCE_MAX := 1.1
const WEAKNESS_MULT := 1.3
const BREAK_DAMAGE_MULT := 2.0
const DEFEND_DAMAGE_MULT := 0.5
const MIN_DAMAGE := 1

# Healing & items
const HEAL_MAG_SCALE := 1.6
const HEAL_BASE := 25
## Item effects grow by this fraction per boost level.
const ITEM_BOOST_PER_LEVEL := 0.5

# Results
## HP that fallen members are revived with after a won or fled battle.
const POST_BATTLE_REVIVE_HP := 1


## Returns { "amount": int, "weak": bool }.
static func calc_damage(rng: RandomNumberGenerator, actor: Combatant, target: Combatant,
		kind: String, power: float, element: String) -> Dictionary:
	var physical := kind == "physical"
	var stat := actor.atk if physical else actor.mag
	var armor := target.def * (1.0 if physical else MAGIC_ARMOR_FACTOR)
	var base := stat * power * DAMAGE_POWER_SCALE - armor
	base = max(base, stat * power * MIN_DAMAGE_FACTOR)
	base *= rng.randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX)
	var weak := target.weaknesses.has(element)
	if weak:
		base *= WEAKNESS_MULT
	if target.is_broken():
		base *= BREAK_DAMAGE_MULT
	if target.defending:
		base *= DEFEND_DAMAGE_MULT
	return {"amount": max(MIN_DAMAGE, int(base)), "weak": weak}


static func skill_power_mult(boost: int) -> float:
	return BattleData.BOOST_POWER[boost]


static func heal_amount(actor: Combatant, skill_power: float, boost: int) -> int:
	return int((actor.mag * skill_power * HEAL_MAG_SCALE + HEAL_BASE) * skill_power_mult(boost))


static func item_mult(boost: int) -> float:
	return 1.0 + boost * ITEM_BOOST_PER_LEVEL


## Basic attacks hit once plus once per boost level.
static func attack_hits(boost: int) -> int:
	return 1 + boost


## BP granted to each ally by a BP-buff skill.
static func bp_buff_amount(boost: int) -> int:
	return 1 + boost


static func turn_priority(rng: RandomNumberGenerator, c: Combatant) -> int:
	return c.spd + rng.randi_range(0, TURN_ORDER_JITTER) - (BROKEN_TURN_PENALTY if c.is_broken() else 0)
