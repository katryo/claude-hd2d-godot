extends SceneTree
## Headless smoke test: boots the game, walks through dialogue, shop, inn and chests by
## injecting input, then checks game state.
## Run: godot --headless --path . --fixed-fps 30 -s tests/smoke_test.gd

# Map cells the test teleports the player to
const ELDER_CELL := Vector2i(17, 28)
const SHOP_CELL := Vector2i(32, 27)
const INN_CELL := Vector2i(9, 27)
const CHEST_CELL := Vector2i(37, 11)
const GRASS_CELL := Vector2i(8, 11)

# Input timing (frames)
const PRESS_HOLD_FRAMES := 2
const RELEASE_FRAMES := 2
const DIALOGUE_PRESS_GAP_FRAMES := 4
const CHOICE_POLL_FRAMES := 20
const DIALOGUE_MAX_PRESSES := 40
const CHOICES_MAX_PRESSES := 20

# Field waits (frames)
const BOOT_FRAMES := 10
const TITLE_DISMISS_FRAMES := 30
const WALK_FRAMES := 30
const FACE_SETTLE_FRAMES := 3
const DIALOGUE_OPEN_FRAMES := 5
const SHOP_PURCHASE_FRAMES := 10
const SHOP_LOOP_FRAMES := 40
const INN_REST_FRAMES := 120
const CHEST_OPEN_FRAMES := 30
const BATTLE_START_FRAMES := 60

# Battle waits (frames)
const MENU_SETTLE_FRAMES := 2
const MENU_STEP_FRAMES := 4
const ATTACK_RESOLVE_FRAMES := 90
const SKILL_RESOLVE_FRAMES := 120
const ITEM_RESOLVE_FRAMES := 90
const MENU_TIMEOUT_FRAMES := 1500
const AUTOBATTLE_TIMEOUT_FRAMES := 3000
const BOSS_TIMEOUT_FRAMES := 6000

# Field expectations
## Minimum distance (world units) the player must cover when walking north.
const WALK_MIN_DISTANCE := 0.5
## Accept presses needed to get through the purchase confirmation lines.
const SHOP_CONFIRM_PRESSES := 3
## Cursor moves from the first shop entry down to "Leave".
const SHOP_LEAVE_MOVES := 3
const POTION_PRICE := 20
## HP the leader is wounded to before resting at the inn.
const INN_TEST_HP := 10
const CHEST_ETHERS := 2
## Encounter meter value that guarantees a battle on the next step.
const ENCOUNTER_METER_FULL := 100.0
const ENCOUNTER_STEP_DELTA := 0.1

# Battle expectations
const TEST_BP := 3
const EXPECTED_BOOST_AFTER_UP := 2
const EXPECTED_BOOST_AFTER_DOWN := 1
const EXPECTED_BP_AFTER_BOOST := 2

# Battle command menu indices
const CMD_SKILLS := 1
const CMD_ITEMS := 2
const CMD_DEFEND := 3

var main: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _press(action: String, hold_frames: int = PRESS_HOLD_FRAMES) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(hold_frames)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(RELEASE_FRAMES)


## Mash accept until the dialogue box closes.
func _finish_dialogue(field, max_presses: int = DIALOGUE_MAX_PRESSES) -> void:
	for i in max_presses:
		if not field.dialogue.visible:
			return
		await _press("accept")
		await _frames(DIALOGUE_PRESS_GAP_FRAMES)


## Advance dialogue lines until a choice menu is showing.
func _until_choices(field, max_presses: int = CHOICES_MAX_PRESSES) -> void:
	for i in max_presses:
		await _frames(CHOICE_POLL_FRAMES)
		if field.dialogue._choices.active:
			return
		await _press("accept")


func _run() -> void:
	var game = root.get_node_or_null("Game")
	_check(game != null, "Game autoload present")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(BOOT_FRAMES)
	await _press("accept")
	await _frames(TITLE_DISMISS_FRAMES)
	var field = main.field
	_check(field.player.controls_enabled, "title dismissed, player has control")

	# Walk north a little.
	var start: Vector3 = field.player.global_position
	Input.action_press("move_up")
	await _frames(WALK_FRAMES)
	Input.action_release("move_up")
	_check(field.player.global_position.z < start.z - WALK_MIN_DISTANCE, "player walks north")

	# Talk to the elder.
	field.player.global_position = MapData.cell_center(ELDER_CELL)
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(FACE_SETTLE_FRAMES)
	await _press("accept")
	await _frames(DIALOGUE_OPEN_FRAMES)
	_check(field.dialogue.visible, "elder dialogue opens")
	await _finish_dialogue(field)
	_check(game.has_flag("quest_started"), "elder starts the quest")
	_check(field.player.controls_enabled, "control returns after dialogue")

	# Buy a potion from the merchant.
	var potions: int = game.inventory["potion"]
	var gold: int = game.gold
	field.player.global_position = MapData.cell_center(SHOP_CELL)
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(FACE_SETTLE_FRAMES)
	await _press("accept")
	await _until_choices(field)
	await _press("accept")  # choose first item (Healing Grape)
	await _frames(SHOP_PURCHASE_FRAMES)
	await _finish_dialogue(field, SHOP_CONFIRM_PRESSES)
	await _frames(SHOP_LOOP_FRAMES)
	# The shop loops; pick "Leave" (last option).
	for i in SHOP_LEAVE_MOVES:
		await _press("move_down")
	await _press("accept")
	await _finish_dialogue(field)
	_check(game.inventory["potion"] == potions + 1, "bought a potion")
	_check(game.gold == gold - POTION_PRICE, "paid 20 G")
	_check(not field.busy and field.player.controls_enabled, "shop closes cleanly")

	# Rest at the inn.
	game.party[0].hp = INN_TEST_HP
	field.player.global_position = MapData.cell_center(INN_CELL)
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(FACE_SETTLE_FRAMES)
	await _press("accept")
	await _until_choices(field)
	await _press("accept")  # "Rest"
	await _frames(INN_REST_FRAMES)
	await _finish_dialogue(field)
	_check(game.party[0].hp == game.party[0].max_hp, "inn restores HP")

	# Open a chest.
	var ethers: int = game.inventory["ether"]
	field.player.global_position = MapData.cell_center(CHEST_CELL)
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(FACE_SETTLE_FRAMES)
	await _press("accept")
	await _frames(CHEST_OPEN_FRAMES)
	await _finish_dialogue(field)
	_check(game.inventory["ether"] == ethers + CHEST_ETHERS, "chest gives 2 ethers")

	# Status menu toggles.
	await _press("menu")
	_check(field.status_panel.visible, "status menu opens")
	await _press("cancel")
	_check(not field.status_panel.visible and field.player.controls_enabled, "status menu closes")

	# Random encounter in tall grass leads to a battle.
	main.autobattle = true
	field.player.global_position = MapData.cell_center(GRASS_CELL)
	field._encounter_meter = ENCOUNTER_METER_FULL
	field._on_player_moved(ENCOUNTER_STEP_DELTA)
	await _frames(BATTLE_START_FRAMES)
	_check(main.battle != null, "encounter starts a battle")
	if main.battle:
		for i in AUTOBATTLE_TIMEOUT_FRAMES:
			await process_frame
			if main.battle == null and field.is_inside_tree():
				break
		_check(field.is_inside_tree(), "returned to the field after battle")

	await _manual_battle(field, game)

	print("SMOKE TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _wait_for_menu(battle) -> bool:
	for i in MENU_TIMEOUT_FRAMES:
		if battle == null or not is_instance_valid(battle):
			return false
		if battle.ui.command_menu.active:
			await _frames(MENU_SETTLE_FRAMES)
			return true
		await process_frame
	return false


func _menu_to(menu, target_index: int) -> void:
	while menu.index != target_index:
		await _press("move_down")


func _enemy_hp(battle) -> int:
	var total := 0
	for e in battle.enemies:
		total += e.hp
	return total


## Drives a battle with real key presses: boost + attack, a skill, then an item.
func _manual_battle(field, game) -> void:
	main.autobattle = false
	game.heal_party()
	field._start_battle(["king_slime"], true)
	await _frames(BATTLE_START_FRAMES)
	var battle = main.battle
	_check(battle != null, "boss battle starts")
	if battle == null:
		return

	_check(await _wait_for_menu(battle), "command menu appears")
	var actor = battle._choosing_for
	actor.bp = TEST_BP
	await _press("boost_up")
	await _press("boost_up")
	_check(battle.boost_level == EXPECTED_BOOST_AFTER_UP, "E raises boost level")
	await _press("boost_down")
	_check(battle.boost_level == EXPECTED_BOOST_AFTER_DOWN, "Q lowers boost level")
	var hp_before := _enemy_hp(battle)
	await _press("accept")  # Attack
	await _frames(MENU_STEP_FRAMES)
	_check(battle._cursor.visible, "target cursor shows")
	await _press("accept")
	await _frames(ATTACK_RESOLVE_FRAMES)
	_check(_enemy_hp(battle) < hp_before, "boosted attack damages the boss")
	_check(actor.bp == EXPECTED_BP_AFTER_BOOST, "boost spent 1 BP")

	_check(await _wait_for_menu(battle), "next command menu appears")
	actor = battle._choosing_for
	var sp_before: int = actor.sp
	await _menu_to(battle.ui.command_menu, CMD_SKILLS)  # Skills
	await _press("accept")
	await _frames(MENU_STEP_FRAMES)
	_check(battle.ui.sub_menu.active, "skill list opens")
	await _press("accept")  # first skill
	await _frames(MENU_STEP_FRAMES)
	await _press("accept")  # confirm target(s)
	await _frames(SKILL_RESOLVE_FRAMES)
	_check(actor.sp < sp_before, "skill consumed SP")

	_check(await _wait_for_menu(battle), "third command menu appears")
	var item_id: String = ""
	for id in game.inventory:
		if game.inventory[id] > 0 and not BattleData.ITEMS[id].revive:
			item_id = id
			break
	var count_before: int = game.inventory[item_id]
	await _menu_to(battle.ui.command_menu, CMD_ITEMS)  # Items
	await _press("accept")
	await _frames(MENU_STEP_FRAMES)
	# Move the cursor to the chosen item.
	var idx := 0
	for id in game.inventory:
		if game.inventory[id] <= 0:
			continue
		if id == item_id:
			break
		idx += 1
	for i in idx:
		await _press("move_down")
	await _press("accept")
	await _frames(MENU_STEP_FRAMES)
	await _press("accept")
	await _frames(ITEM_RESOLVE_FRAMES)
	_check(game.inventory[item_id] == count_before - 1, "item used up (%s)" % item_id)

	battle.autoplay = true
	if await _wait_for_menu(battle):
		await _menu_to(battle.ui.command_menu, CMD_DEFEND)  # Defend
		await _press("accept")
	for i in BOSS_TIMEOUT_FRAMES:
		await process_frame
		if main.battle == null and field.is_inside_tree():
			break
	_check(field.is_inside_tree(), "boss battle resolves and returns to the field")
