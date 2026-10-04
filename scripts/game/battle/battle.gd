class_name Battle
extends Node3D
## Presenter for one battle. Wires together:
## * BattleModel (logic: turns, Break & Boost, outcome),
## * BattleView (visuals: stage, sprites, effects, HUD),
## * BattleControllers (who decides: the player, the enemy AI or autoplay),
## and drives them with a StateMachine (see battle_states.gd).
##
## Break & Boost in short: every enemy has a shield; hitting a weakness removes a point
## and at zero the enemy BREAKS (loses its next turn, takes double damage). Party members
## bank Boost Points each round and spend up to 3 per action for extra power.

signal finished(result: String)

const States = preload("res://scripts/game/battle/battle_states.gd")

# Pacing (seconds)
const INTRO_MESSAGE_TIME := 1.3
const BROKEN_MESSAGE_TIME := 0.9
const AUTO_THINK_TIME := 0.2
const BANNER_TIME := 1.6
const VICTORY_BANNER_WAIT := 1.2
const LEVEL_UP_TIME := 1.0
const VICTORY_END_TIME := 1.0
const DEFEAT_WAIT := 2.8

var enemy_ids: Array = []
var is_boss := false
## Lets the party act on its own (used by the --autobattle dev flag and smoke tests).
var autoplay := false

var model: BattleModel
var view: BattleView
var machine: StateMachine
var player_input: PlayerBattleInput
var enemy_ai := EnemyAI.new()
var auto_party := AutoPartyController.new()


func setup(ids: Array, boss: bool) -> void:
	enemy_ids = ids
	is_boss = boss


func _ready() -> void:
	model = BattleModel.new(Game.party, enemy_ids, is_boss, Game)
	view = BattleView.new()
	add_child(view)
	view.build(model)
	player_input = PlayerBattleInput.new(view)
	machine = StateMachine.new(self)
	machine.add_state(&"intro", States.Intro.new()) \
		.add_state(&"round_start", States.RoundStart.new()) \
		.add_state(&"turn_start", States.TurnStart.new()) \
		.add_state(&"choose_action", States.ChooseAction.new()) \
		.add_state(&"resolve_action", States.ResolveAction.new()) \
		.add_state(&"round_end", States.RoundEnd.new()) \
		.add_state(&"outcome", States.Outcome.new()) \
		.add_state(&"victory", States.Victory.new()) \
		.add_state(&"defeat", States.Defeat.new()) \
		.add_state(&"finished", States.Finished.new())
	machine.start.call_deferred(&"intro")


func controller_for(actor: Combatant) -> BattleController:
	if actor.is_enemy:
		return enemy_ai
	return auto_party if autoplay else player_input


func _process(delta: float) -> void:
	machine.update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if machine.handle_input(event):
		get_viewport().set_input_as_handled()
