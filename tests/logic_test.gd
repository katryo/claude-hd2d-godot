extends SceneTree
## Pure logic tests: exercises the rules layer (scripts/logic, scripts/core) with no
## scene, view or timers. Runs in well under a second.
## Run: godot --headless --path . -s tests/logic_test.gd

const SEED := 12345
const BATTLES_PER_GROUP := 20
## Safety cap so a rules bug can't loop forever.
const MAX_ROUNDS := 200
const PARTY_IDS := ["aren", "lyra", "kit"]
const STRONG_LEVELS := 15

var failures := 0


## Stand-in for the Game autoload's bag/wallet API.
class FakeBag:
	var inventory := {"potion": 2, "ether": 1, "feather": 1}
	var gold := 100

	func use_item(id: String) -> bool:
		if inventory.get(id, 0) <= 0:
			return false
		inventory[id] -= 1
		return true

	func add_gold(amount: int) -> void:
		gold += amount

	func add_item(id: String, count: int = 1) -> void:
		inventory[id] = inventory.get(id, 0) + count


func _initialize() -> void:
	_test_state_machine()
	_test_damage_rules()
	_test_break_and_boost()
	_test_actions()
	_test_full_battles()
	_test_encounters()
	_test_shop()
	print("LOGIC TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _party(levels: int = 0) -> Array[Combatant]:
	var party: Array[Combatant] = []
	for id in PARTY_IDS:
		var m := BattleData.make_party_member(id)
		if levels > 0:
			for i in levels:
				m.add_exp(m.exp_to_next())
		party.append(m)
	return party


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng


class Recorder extends State:
	var entries: Array

	func _init(p_log: Array) -> void:
		entries = p_log

	func enter(msg: Dictionary = {}) -> void:
		entries.append("enter %s %s" % [name, msg.get("n", "")])

	func exit() -> void:
		entries.append("exit %s" % name)


func _test_state_machine() -> void:
	var log := []
	var m := StateMachine.new(self)
	m.add_state(&"a", Recorder.new(log)).add_state(&"b", Recorder.new(log))
	m.start(&"a")
	m.transition_to(&"b", {"n": 7})
	_check(m.is_in(&"b"), "state machine switches state")
	_check(log == ["enter a ", "exit a", "enter b 7"], "enter/exit hooks run in order with messages")


func _test_damage_rules() -> void:
	var rng := _rng()
	var hero := BattleData.make_party_member("aren")
	var slime := BattleData.make_enemy("slime")
	var normal := BattleRules.calc_damage(rng, hero, slime, "physical", 1.0, "bow")
	var weak := BattleRules.calc_damage(rng, hero, slime, "physical", 1.0, "sword")
	_check(normal.amount >= BattleRules.MIN_DAMAGE and not normal.weak, "non-weak hit deals damage")
	_check(weak.weak and weak.amount > normal.amount, "weakness hit is flagged and stronger")
	slime.defending = true
	var guarded := BattleRules.calc_damage(rng, hero, slime, "physical", 1.0, "bow")
	_check(guarded.amount < normal.amount, "defending reduces damage")


func _test_break_and_boost() -> void:
	var model := BattleModel.new(_party(), ["slime"], false, FakeBag.new(), _rng())
	var slime := model.enemies[0]
	var shield := slime.shield
	for i in shield:
		slime.hit_shield("sword")
	_check(slime.is_broken() and slime.shield == 0, "hitting a weakness %d times breaks the shield" % shield)
	model.end_round()
	_check(slime.is_broken(), "still broken through the next round")
	model.end_round()
	_check(not slime.is_broken() and slime.shield == slime.max_shield, "shield restores after the break")

	var hero := model.party[0]
	hero.bp = Combatant.MAX_BP
	_check(model.max_boost(hero) == Combatant.MAX_BOOST, "boost is capped at %d" % Combatant.MAX_BOOST)
	model.spend_boost(hero, 2)
	model.end_round()
	_check(hero.bp == Combatant.MAX_BP - 2, "boosting skips the round's BP gain")
	var lyra := model.party[1]
	var before := lyra.bp
	model.end_round()
	_check(lyra.bp == before + BattleRules.BP_PER_ROUND, "non-boosters gain BP each round")


func _test_actions() -> void:
	var bag := FakeBag.new()
	var model := BattleModel.new(_party(), ["slime", "slime"], false, bag, _rng())
	_check(model.enemies[0].display_name.ends_with(" A") and model.enemies[1].display_name.ends_with(" B"),
		"duplicate enemies get A/B suffixes")
	var hero := model.party[0]
	var events := AttackAction.new(hero, [model.enemies[0]], 2).execute(model)
	var hits := events.filter(func(e): return e.type == BattleEvent.Type.HIT).size()
	_check(hits == BattleRules.attack_hits(2) or not model.enemies[0].is_alive(), "boost 2 attack hits 3 times")
	_check(events.front().type == BattleEvent.Type.ACTION_START and events.back().type == BattleEvent.Type.ACTION_END,
		"actions are bracketed by start/end events")

	var lyra := model.party[1]
	lyra.hp = 1
	var sp_before := lyra.sp
	SkillAction.new(lyra, "heal", [lyra]).execute(model)
	_check(lyra.hp > 1 and lyra.sp == sp_before - BattleData.SKILLS["heal"].cost, "heal restores HP and costs SP")

	var kit := model.party[2]
	kit.hp = 0
	var revive_events := ItemAction.new(hero, "feather", [kit]).execute(model)
	_check(kit.is_alive() and bag.inventory["feather"] == 0, "phoenix down revives and is consumed")
	_check(revive_events.any(func(e): return e.type == BattleEvent.Type.REVIVE), "revive emits a REVIVE event")

	var boss_model := BattleModel.new(_party(), ["king_slime"], true, bag, _rng())
	FleeAction.new(boss_model.party[0]).execute(boss_model)
	_check(boss_model.outcome != BattleModel.Outcome.FLED, "cannot flee from the boss")


## Plays whole battles with AI on both sides, entirely in the logic layer.
func _simulate(enemy_ids: Array, boss: bool, levels: int, rng: RandomNumberGenerator) -> BattleModel:
	var model := BattleModel.new(_party(levels), enemy_ids, boss, FakeBag.new(), rng)
	var enemy_ai := EnemyAI.new()
	var auto := AutoPartyController.new()
	while not model.is_over() and model.round_number < MAX_ROUNDS:
		model.begin_round()
		var actor := model.next_turn()
		while actor != null and not model.is_over():
			if not actor.is_broken():
				var acts := 1
				while acts > 0:
					acts -= 1
					var controller: BattleController = enemy_ai if actor.is_enemy else auto
					var action := controller.choose_action(model, actor)
					if action:
						model.spend_boost(actor, action.boost)
						action.execute(model)
					if model.grants_extra_action(actor):
						acts += 1
			actor = model.next_turn()
		if not model.is_over():
			model.end_round()
	model.resolve_outcome()
	model.cleanup()
	return model


func _test_full_battles() -> void:
	var rng := _rng()
	var finished := 0
	var wins := 0
	for group in BattleData.ENCOUNTERS:
		for i in BATTLES_PER_GROUP:
			var model := _simulate(group, false, 0, rng)
			if model.outcome != BattleModel.Outcome.NONE:
				finished += 1
			if model.outcome == BattleModel.Outcome.VICTORY:
				wins += 1
	var total := BattleData.ENCOUNTERS.size() * BATTLES_PER_GROUP
	_check(finished == total, "all %d simulated encounters reach an outcome" % total)
	_check(wins > total / 2, "level-1 party wins most random encounters (%d/%d)" % [wins, total])
	var boss := _simulate(["king_slime"], true, STRONG_LEVELS, rng)
	_check(boss.outcome == BattleModel.Outcome.VICTORY, "a well-levelled party beats the King Slime")
	_check(boss.party.all(func(m): return m.is_alive()), "fallen members are revived after a win")


func _test_encounters() -> void:
	var tracker := EncounterTracker.new(_rng())
	_check(tracker.advance(100.0, ".").is_empty(), "no encounters off the tall grass")
	var group := tracker.advance(EncounterTracker.THRESHOLD_MAX, EncounterTracker.ENCOUNTER_TERRAIN)
	_check(not group.is_empty() and BattleData.ENEMIES.has(group[0]), "tall grass eventually triggers a battle")


func _test_shop() -> void:
	var shop := Shop.new(StoryData.SHOP_STOCK)
	var wallet := FakeBag.new()
	wallet.gold = shop.price(0)
	_check(shop.buy(0, wallet) == Shop.Result.BOUGHT and wallet.gold == 0, "buying deducts the price")
	_check(shop.buy(0, wallet) == Shop.Result.TOO_POOR, "can't buy without enough gold")
