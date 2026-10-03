extends SceneTree
## Headless smoke test: boots the game, walks through dialogue, shop, inn and chests by
## injecting input, then checks game state.
## Run: godot --headless --path . --fixed-fps 30 -s tests/smoke_test.gd

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


func _press(action: String, hold_frames: int = 2) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(hold_frames)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


## Mash accept until the dialogue box closes.
func _finish_dialogue(field, max_presses: int = 40) -> void:
	for i in max_presses:
		if not field.dialogue.visible:
			return
		await _press("accept")
		await _frames(4)


## Advance dialogue lines until a choice menu is showing.
func _until_choices(field, max_presses: int = 20) -> void:
	for i in max_presses:
		await _frames(20)
		if field.dialogue._choices.active:
			return
		await _press("accept")


func _run() -> void:
	var game = root.get_node_or_null("Game")
	_check(game != null, "Game autoload present")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(10)
	await _press("accept")
	await _frames(30)
	var field = main.field
	_check(field.player.controls_enabled, "title dismissed, player has control")

	# Walk north a little.
	var start: Vector3 = field.player.global_position
	Input.action_press("move_up")
	await _frames(30)
	Input.action_release("move_up")
	_check(field.player.global_position.z < start.z - 0.5, "player walks north")

	# Talk to the elder.
	field.player.global_position = MapData.cell_center(Vector2i(17, 28))
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(3)
	await _press("accept")
	await _frames(5)
	_check(field.dialogue.visible, "elder dialogue opens")
	await _finish_dialogue(field)
	_check(game.has_flag("quest_started"), "elder starts the quest")
	_check(field.player.controls_enabled, "control returns after dialogue")

	# Buy a potion from the merchant.
	var potions: int = game.inventory["potion"]
	var gold: int = game.gold
	field.player.global_position = MapData.cell_center(Vector2i(32, 27))
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(3)
	await _press("accept")
	await _until_choices(field)
	await _press("accept")  # choose first item (Healing Grape)
	await _frames(10)
	await _finish_dialogue(field, 3)
	await _frames(40)
	# The shop loops; pick "Leave" (last option).
	for i in 3:
		await _press("move_down")
	await _press("accept")
	await _finish_dialogue(field)
	_check(game.inventory["potion"] == potions + 1, "bought a potion")
	_check(game.gold == gold - 20, "paid 20 G")
	_check(not field.busy and field.player.controls_enabled, "shop closes cleanly")

	# Rest at the inn.
	game.party[0].hp = 10
	field.player.global_position = MapData.cell_center(Vector2i(9, 27))
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(3)
	await _press("accept")
	await _until_choices(field)
	await _press("accept")  # "Rest"
	await _frames(120)
	await _finish_dialogue(field)
	_check(game.party[0].hp == game.party[0].max_hp, "inn restores HP")

	# Open a chest.
	var ethers: int = game.inventory["ether"]
	field.player.global_position = MapData.cell_center(Vector2i(37, 11))
	field.player.sprite.face_vector(Vector2.UP)
	await _frames(3)
	await _press("accept")
	await _frames(30)
	await _finish_dialogue(field)
	_check(game.inventory["ether"] == ethers + 2, "chest gives 2 ethers")

	# Status menu toggles.
	await _press("menu")
	_check(field.status_panel.visible, "status menu opens")
	await _press("cancel")
	_check(not field.status_panel.visible and field.player.controls_enabled, "status menu closes")

	# Random encounter in tall grass leads to a battle.
	main.autobattle = true
	field.player.global_position = MapData.cell_center(Vector2i(8, 11))
	field._encounter_meter = 100.0
	field._on_player_moved(0.1)
	await _frames(60)
	_check(main.battle != null, "encounter starts a battle")
	if main.battle:
		for i in 3000:
			await process_frame
			if main.battle == null and field.is_inside_tree():
				break
		_check(field.is_inside_tree(), "returned to the field after battle")

	await _manual_battle(field, game)

	print("SMOKE TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _wait_for_menu(battle) -> bool:
	for i in 1500:
		if battle == null or not is_instance_valid(battle):
			return false
		if battle.ui.command_menu.active:
			await _frames(2)
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
	await _frames(60)
	var battle = main.battle
	_check(battle != null, "boss battle starts")
	if battle == null:
		return

	_check(await _wait_for_menu(battle), "command menu appears")
	var actor = battle._choosing_for
	actor.bp = 3
	await _press("boost_up")
	await _press("boost_up")
	_check(battle.boost_level == 2, "E raises boost level")
	await _press("boost_down")
	_check(battle.boost_level == 1, "Q lowers boost level")
	var hp_before := _enemy_hp(battle)
	await _press("accept")  # Attack
	await _frames(4)
	_check(battle._cursor.visible, "target cursor shows")
	await _press("accept")
	await _frames(90)
	_check(_enemy_hp(battle) < hp_before, "boosted attack damages the boss")
	_check(actor.bp == 2, "boost spent 1 BP")

	_check(await _wait_for_menu(battle), "next command menu appears")
	actor = battle._choosing_for
	var sp_before: int = actor.sp
	await _menu_to(battle.ui.command_menu, 1)  # Skills
	await _press("accept")
	await _frames(4)
	_check(battle.ui.sub_menu.active, "skill list opens")
	await _press("accept")  # first skill
	await _frames(4)
	await _press("accept")  # confirm target(s)
	await _frames(120)
	_check(actor.sp < sp_before, "skill consumed SP")

	_check(await _wait_for_menu(battle), "third command menu appears")
	var item_id: String = ""
	for id in game.inventory:
		if game.inventory[id] > 0 and not BattleData.ITEMS[id].revive:
			item_id = id
			break
	var count_before: int = game.inventory[item_id]
	await _menu_to(battle.ui.command_menu, 2)  # Items
	await _press("accept")
	await _frames(4)
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
	await _frames(4)
	await _press("accept")
	await _frames(90)
	_check(game.inventory[item_id] == count_before - 1, "item used up (%s)" % item_id)

	battle.autoplay = true
	if await _wait_for_menu(battle):
		await _menu_to(battle.ui.command_menu, 3)  # Defend
		await _press("accept")
	for i in 6000:
		await process_frame
		if main.battle == null and field.is_inside_tree():
			break
	_check(field.is_inside_tree(), "boss battle resolves and returns to the field")
