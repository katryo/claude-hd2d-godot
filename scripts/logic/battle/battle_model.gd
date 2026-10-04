class_name BattleModel
extends RefCounted
## The rules-level state of one battle: who is fighting, whose turn it is, Boost
## bookkeeping and the outcome. Contains no nodes or visuals, so it can be driven
## headlessly (tests, auto-battles) and rendered by any view.

enum Outcome { NONE, VICTORY, DEFEAT, FLED }

## Suffixes given to duplicate enemy names ("Jelly Slime A", "Jelly Slime B", ...).
const DUPLICATE_SUFFIXES := "ABCDEFG"

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var is_boss := false
## Item storage: needs `inventory: Dictionary` and `use_item(id) -> bool` (the Game autoload).
var bag: Object
var rng: RandomNumberGenerator

var round_number := 0
## Combatants in acting order for the current round.
var turn_order: Array[Combatant] = []
## Index into turn_order of the combatant acting now (-1 before the first turn).
var turn_index := -1
var outcome: Outcome = Outcome.NONE

## Party members who spent BP this round (they don't gain BP at round end).
var _boosted := {}
## Combatants that already took their bonus action this turn.
var _extra_action_taken := {}


func _init(p_party: Array[Combatant], enemy_ids: Array, boss: bool, p_bag: Object,
		p_rng: RandomNumberGenerator = null) -> void:
	party = p_party
	is_boss = boss
	bag = p_bag
	rng = p_rng if p_rng else RandomNumberGenerator.new()
	if not p_rng:
		rng.randomize()
	for id in enemy_ids:
		enemies.append(BattleData.make_enemy(id))
	_name_duplicates()
	for m in party:
		m.defending = false
		m.break_turns = 0


func _name_duplicates() -> void:
	var counts := {}
	for e in enemies:
		counts[e.display_name] = counts.get(e.display_name, 0) + 1
	var seen := {}
	for e in enemies:
		var base_name := e.display_name
		if counts[base_name] > 1:
			seen[base_name] = seen.get(base_name, 0) + 1
			e.display_name += " " + DUPLICATE_SUFFIXES[seen[base_name] - 1]


# --------------------------------------------------------------------------
# Queries
# --------------------------------------------------------------------------

func all_combatants() -> Array[Combatant]:
	var all: Array[Combatant] = []
	all.append_array(party)
	all.append_array(enemies)
	return all


static func alive(list: Array) -> Array:
	return list.filter(func(c): return c.is_alive())


static func fallen(list: Array) -> Array:
	return list.filter(func(c): return not c.is_alive())


func opponents_of(c: Combatant) -> Array:
	return alive(party if c.is_enemy else enemies)


func allies_of(c: Combatant) -> Array:
	return alive(enemies if c.is_enemy else party)


## Resolves a skill's target kind (from the user's point of view) to candidate targets.
func candidates_for(user: Combatant, target_kind: String) -> Array:
	match target_kind:
		"enemy", "all_enemies":
			return opponents_of(user)
		"ally", "all_allies":
			return allies_of(user)
		"ally_dead":
			return fallen(enemies if user.is_enemy else party)
	return []


func enemies_defeated() -> bool:
	return alive(enemies).is_empty()


func party_defeated() -> bool:
	return alive(party).is_empty()


func is_over() -> bool:
	return outcome != Outcome.NONE or enemies_defeated() or party_defeated()


func can_flee() -> bool:
	return not is_boss


func max_boost(c: Combatant) -> int:
	return min(c.bp, Combatant.MAX_BOOST)


# --------------------------------------------------------------------------
# Round / turn flow
# --------------------------------------------------------------------------

func begin_round() -> Array[Combatant]:
	round_number += 1
	var entries := []
	for c in all_combatants():
		if c.is_alive():
			entries.append([c, BattleRules.turn_priority(rng, c)])
	entries.sort_custom(func(a, b): return a[1] > b[1])
	turn_order.clear()
	for entry in entries:
		turn_order.append(entry[0])
	turn_index = -1
	return turn_order


## Advances to the next combatant in the round, or returns null when the round is over.
## Fallen combatants are skipped; broken ones are returned (the caller announces them).
func next_turn() -> Combatant:
	while true:
		turn_index += 1
		if turn_index >= turn_order.size():
			return null
		var c := turn_order[turn_index]
		if c.is_alive():
			_extra_action_taken.erase(c)
			return c
	return null


## Enraged bosses (below half HP) act twice per turn.
func grants_extra_action(c: Combatant) -> bool:
	if not (is_boss and c.is_enemy) or _extra_action_taken.has(c):
		return false
	if c.hp >= c.max_hp / 2 or c.is_broken() or is_over():
		return false
	_extra_action_taken[c] = true
	return true


func spend_boost(c: Combatant, level: int) -> void:
	if level <= 0:
		return
	c.bp -= level
	_boosted[c] = true


## Ends the round: ticks break/defend timers and grants BP to members who didn't boost.
func end_round() -> void:
	for c in all_combatants():
		c.end_of_round()
	for m in party:
		if m.is_alive() and not _boosted.has(m):
			m.gain_bp(BattleRules.BP_PER_ROUND)
	_boosted.clear()


func resolve_outcome() -> Outcome:
	if outcome == Outcome.NONE:
		if enemies_defeated():
			outcome = Outcome.VICTORY
		elif party_defeated():
			outcome = Outcome.DEFEAT
	return outcome


# --------------------------------------------------------------------------
# Results
# --------------------------------------------------------------------------

func rewards() -> Dictionary:
	var xp := 0
	var gold := 0
	for e in enemies:
		xp += e.exp_reward
		gold += e.gold_reward
	return {"xp": xp, "gold": gold}


## Grants experience; fallen members earn half. Returns the members who levelled up.
func grant_experience(xp: int) -> Array[Combatant]:
	var levelled: Array[Combatant] = []
	for m in party:
		if m.add_exp(xp if m.is_alive() else xp / 2) > 0:
			levelled.append(m)
	return levelled


## Clears battle-only status and revives the fallen after a win or escape.
func cleanup() -> void:
	for m in party:
		m.defending = false
		m.break_turns = 0
		if outcome != Outcome.DEFEAT and not m.is_alive():
			m.hp = BattleRules.POST_BATTLE_REVIVE_HP


static func outcome_name(o: Outcome) -> String:
	match o:
		Outcome.VICTORY: return "win"
		Outcome.DEFEAT: return "lose"
		Outcome.FLED: return "flee"
	return ""
