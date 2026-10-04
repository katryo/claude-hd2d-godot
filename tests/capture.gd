extends SceneTree
## Renders a few showcase screenshots (needs a real renderer, e.g. under xvfb-run).
## Run: godot --path . -s tests/capture.gd -- --out=<dir>

const ELDER_CELL := Vector2i(17, 28)

# Input timing (frames)
const PRESS_HOLD_FRAMES := 2
const RELEASE_FRAMES := 2
const FACE_SETTLE_FRAMES := 3
const DIALOGUE_SKIP_PRESSES := 20
const DIALOGUE_SKIP_GAP_FRAMES := 3
const TARGET_CURSOR_FRAMES := 3

# Waits before each shot (seconds)
const TITLE_WAIT_SEC := 2.5
const FIELD_WAIT_SEC := 1.5
const DIALOGUE_OPEN_SEC := 1.0
const DIALOGUE_STEP_SEC := 0.3
## Lets the typewriter text finish before the dialogue shot.
const DIALOGUE_TYPE_SEC := 2.0
const BATTLE_INTRO_SEC := 4.0
const BOOST_SETTLE_SEC := 0.6
## Catches the break effect mid-flash.
const BREAK_FLASH_SEC := 0.75

# Boss-shot setup
const CAPTURE_BP := 3
## Leaves the boss one weakness hit from breaking so the shot shows a BREAK.
const ONE_HIT_SHIELD := 1

var out_dir := "user://"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.trim_prefix("--out=")
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(PRESS_HOLD_FRAMES)
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await _frames(RELEASE_FRAMES)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(TITLE_WAIT_SEC).timeout
	await _shot("title")
	await _press("accept")
	await create_timer(FIELD_WAIT_SEC).timeout
	var field = main.field
	field.player.global_position = MapData.cell_center(ELDER_CELL)
	field.player.sprite.face_vector(Vector2.UP)
	field.view.reactivate_camera()
	await _frames(FACE_SETTLE_FRAMES)
	await _press("accept")
	await create_timer(DIALOGUE_OPEN_SEC).timeout
	await _press("accept")
	await create_timer(DIALOGUE_STEP_SEC).timeout
	await _press("accept")
	await create_timer(DIALOGUE_TYPE_SEC).timeout
	await _shot("dialogue")
	for i in DIALOGUE_SKIP_PRESSES:
		await _press("accept")
		await _frames(DIALOGUE_SKIP_GAP_FRAMES)
	field.request_battle(["king_slime"], true)
	await create_timer(BATTLE_INTRO_SEC).timeout
	var battle = main.battle
	while not battle.view.ui.command_menu.active:
		await process_frame
	var actor = battle.player_input.actor
	actor.bp = CAPTURE_BP
	battle.model.enemies[0].shield = ONE_HIT_SHIELD
	actor.weapon = "sword"
	await _press("boost_up")
	await _press("boost_up")
	await _press("boost_up")
	await create_timer(BOOST_SETTLE_SEC).timeout
	await _shot("boss_boost")
	await _press("accept")
	await _frames(TARGET_CURSOR_FRAMES)
	await _press("accept")
	await create_timer(BREAK_FLASH_SEC).timeout
	await _shot("boss_break")
	quit()
