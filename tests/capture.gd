extends SceneTree
## Renders a few showcase screenshots (needs a real renderer, e.g. under xvfb-run).
## Run: godot --path . -s tests/capture.gd -- --out=<dir>

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
	await _frames(2)
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await _frames(2)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	await _shot("title")
	await _press("accept")
	await create_timer(1.5).timeout
	var field = main.field
	field.player.global_position = MapData.cell_center(Vector2i(17, 28))
	field.player.sprite.face_vector(Vector2.UP)
	field.camera.snap()
	await _frames(3)
	await _press("accept")
	await create_timer(1.0).timeout
	await _press("accept")
	await create_timer(0.3).timeout
	await _press("accept")
	await create_timer(2.0).timeout
	await _shot("dialogue")
	for i in 20:
		await _press("accept")
		await _frames(3)
	field._start_battle(["king_slime"], true)
	await create_timer(4.0).timeout
	var battle = main.battle
	while not battle.ui.command_menu.active:
		await process_frame
	var actor = battle._choosing_for
	actor.bp = 3
	battle.enemies[0].shield = 1
	actor.weapon = "sword"
	await _press("boost_up")
	await _press("boost_up")
	await _press("boost_up")
	await create_timer(0.6).timeout
	await _shot("boss_boost")
	await _press("accept")
	await _frames(3)
	await _press("accept")
	await create_timer(0.75).timeout
	await _shot("boss_break")
	quit()
