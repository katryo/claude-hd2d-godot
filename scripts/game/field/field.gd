class_name Field
extends Node3D
## Presenter for the overworld. Owns the actors (player, villagers, boss), the field
## rules (EncounterTracker, Shop, interactions) and a StateMachine for the exploration
## modes; delegates everything visual to FieldView.

signal battle_requested(enemy_ids: Array, is_boss: bool)

const States = preload("res://scripts/game/field/field_states.gd")

## Where the party wakes up after losing a battle.
const INN_RESPAWN_CELL := Vector2i(8, 26)
const REST_HOLD_TIME := 0.7
const VICTORY_BANNER_HOLD := 2.5

var view: FieldView
var player: Player
var npcs: Array[NPC] = []
var boss: BossEntity
var interactions: Array[Interaction] = []
var encounters := EncounterTracker.new()
var shop := Shop.new(StoryData.SHOP_STOCK)
var machine: StateMachine

## Shortcuts to the view's dialogue box (used by interactions and tests).
var dialogue: DialogueBox:
	get:
		return view.dialogue


func _ready() -> void:
	view = FieldView.new()
	add_child(view)
	view.build()
	_spawn_player()
	_spawn_npcs()
	if not Game.has_flag(StoryData.BOSS_DEFEATED):
		_spawn_boss()
	for cell in view.chest_cells():
		interactions.append(ChestInteraction.new(cell))
		if Game.has_flag(StoryData.chest_flag(cell)):
			view.set_chest_open(cell)
	for s in MapData.SIGNS:
		interactions.append(SignInteraction.new(s.cell, s.text))
	machine = StateMachine.new(self)
	machine.add_state(&"suspended", States.Suspended.new()) \
		.add_state(&"explore", States.Explore.new()) \
		.add_state(&"interact", States.Interact.new()) \
		.add_state(&"status", States.Status.new())
	machine.start(&"suspended")
	view.set_ui_visible(false)


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = MapData.cell_center(MapData.find("@"))
	player.sprite.facing = CharacterSprite.Facing.UP
	player.moved.connect(_on_player_moved)
	view.follow(player)


func _spawn_npcs() -> void:
	for data in MapData.NPCS:
		var npc := NPC.new()
		npc.setup(data)
		npc.position = MapData.cell_center(data.cell)
		add_child(npc)
		npcs.append(npc)
		interactions.append(NpcInteraction.new(npc))


func _spawn_boss() -> void:
	boss = BossEntity.new(StoryData.BOSS_ID)
	boss.position = MapData.cell_center(MapData.find("K"))
	add_child(boss)
	interactions.append(BossInteraction.new(boss))


# --------------------------------------------------------------------------
# Called by the game flow
# --------------------------------------------------------------------------

## Hands control to the player (after the title screen).
func activate() -> void:
	view.set_ui_visible(true)
	machine.transition_to(&"explore")
	view.banner.show_text(StoryData.LOCATION_TITLE, StoryData.LOCATION_SUBTITLE)


func request_battle(enemy_ids: Array, is_boss: bool) -> void:
	machine.transition_to(&"suspended")
	battle_requested.emit(enemy_ids, is_boss)


## Called by the game flow when the field is shown again after a battle.
func on_battle_finished(result: String, was_boss: bool) -> void:
	encounters.reset()
	view.reactivate_camera()
	if result == "lose":
		run_script(_wake_up_at_inn)
	elif result == "win" and was_boss:
		run_script(_celebrate_boss_victory)
	else:
		machine.transition_to(&"explore")


## Plays a scripted scene (a coroutine Callable), then returns to exploring.
func run_script(script: Callable) -> void:
	machine.transition_to(&"interact", {"script": script})


# --------------------------------------------------------------------------
# Services used by interactions
# --------------------------------------------------------------------------

func run_service(service: String, speaker: String) -> void:
	match service:
		"inn":
			await _rest()
		"shop":
			await _shop(speaker)


func _rest() -> void:
	Audio.set_music(&"inn")
	await view.fade.fade_out()
	Game.heal_party()
	await get_tree().create_timer(REST_HOLD_TIME).timeout
	await view.fade.fade_in()


func _shop(speaker: String) -> void:
	var greeting := StoryData.SHOP_GREETING
	while true:
		var choices := []
		for i in shop.stock.size():
			choices.append("%s  (%d G)" % [BattleData.ITEMS[shop.item_id(i)].name, shop.price(i)])
		choices.append(StoryData.SHOP_LEAVE)
		var choice := await dialogue.say(speaker, [greeting], choices)
		if choice < 0 or choice >= shop.stock.size():
			await dialogue.say(speaker, [StoryData.SHOP_FAREWELL])
			return
		match shop.buy(choice, Game):
			Shop.Result.TOO_POOR:
				Audio.play_sfx(&"cancel")
				await dialogue.say(speaker, [StoryData.SHOP_TOO_POOR])
			Shop.Result.BOUGHT:
				Audio.play_sfx(&"coin")
				var id := shop.item_id(choice)
				await dialogue.say(speaker, [StoryData.SHOP_THANKS % [BattleData.ITEMS[id].name, Game.inventory[id]]])
		greeting = StoryData.SHOP_AGAIN % Game.gold


func _wake_up_at_inn() -> void:
	Game.heal_party()
	player.global_position = MapData.cell_center(INN_RESPAWN_CELL)
	player.sprite.facing = CharacterSprite.Facing.DOWN
	view.reactivate_camera()
	await dialogue.say(StoryData.RESCUER_NAME, StoryData.RESCUE_LINES)


func _celebrate_boss_victory() -> void:
	Game.set_flag(StoryData.BOSS_DEFEATED)
	if boss:
		for i in interactions.duplicate():
			if i is BossInteraction:
				interactions.erase(i)
		boss.queue_free()
		boss = null
	await view.banner.show_text(StoryData.BOSS_VICTORY_TITLE, StoryData.BOSS_VICTORY_SUBTITLE, VICTORY_BANNER_HOLD)
	await dialogue.say("", StoryData.BOSS_VICTORY_LINES)


# --------------------------------------------------------------------------
# Per-frame
# --------------------------------------------------------------------------

func current_target() -> Interaction:
	return InteractionFinder.find(interactions, player.global_position, player.facing_vector3())


func update_bubbles(target: Interaction) -> void:
	var talking_to := target.npc() if target else null
	for npc in npcs:
		npc.show_bubble(npc == talking_to)


func _process(delta: float) -> void:
	machine.update(delta)
	view.hud.set_gold(Game.gold)


func _unhandled_input(event: InputEvent) -> void:
	if machine.handle_input(event):
		get_viewport().set_input_as_handled()


func _on_player_moved(distance: float) -> void:
	if not machine.is_in(&"explore"):
		return
	var cell := MapData.world_to_cell(player.global_position)
	var group := encounters.advance(distance, MapData.cell(cell.x, cell.y))
	if not group.is_empty():
		request_battle(group, false)
