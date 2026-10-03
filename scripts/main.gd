extends Node
## Game flow: title screen -> exploration <-> battles, with screen transitions.

var field: Field
var battle: Battle
var transition: ColorRect
var title: Control
## When true, battles play themselves (set by --autobattle or tests).
var autobattle := false
var _in_title := true
var _was_boss := false


func _ready() -> void:
	add_child(Visuals.make_vignette())

	var tlayer := CanvasLayer.new()
	tlayer.layer = 50
	add_child(tlayer)
	transition = ColorRect.new()
	transition.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/transition.gdshader")
	transition.material = mat
	_set_transition(0.0)
	tlayer.add_child(transition)

	field = Field.new()
	field.name = "Field"
	add_child(field)
	field.battle_requested.connect(_on_battle_requested)
	field.set_controls(false)
	_build_title(tlayer)

	_handle_dev_args()


func _exit_tree() -> void:
	# The field is detached while a battle runs; make sure it is freed on quit.
	if field and not field.is_inside_tree():
		field.free()


func _build_title(layer: CanvasLayer) -> void:
	title = Control.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.theme = UITheme.get_theme()
	layer.add_child(title)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.03, 0.1, 0.35)
	title.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	title.add_child(box)
	var t1 := UITheme.label("LUMEN HOLLOW", 76, UITheme.TEXT)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_constant_override("shadow_offset_x", 4)
	t1.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(t1)
	var t2 := UITheme.label("~ An HD-2D Tale ~", 28, UITheme.GOLD)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t2)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	box.add_child(spacer)
	var t3 := UITheme.label("Press Z / Enter to begin", 24, UITheme.TEXT)
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.name = "Prompt"
	box.add_child(t3)
	var t4 := UITheme.label("Move: WASD / Arrows    Confirm: Z / Enter    Cancel: X / Esc    Boost: E / Q", 18, UITheme.DIM)
	t4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t4)
	var tw := t3.create_tween().set_loops()
	tw.tween_property(t3, "modulate:a", 0.25, 0.9)
	tw.tween_property(t3, "modulate:a", 1.0, 0.9)


func _unhandled_input(event: InputEvent) -> void:
	if _in_title and event.is_action_pressed("accept"):
		get_viewport().set_input_as_handled()
		_start_game()


func _start_game() -> void:
	if not _in_title:
		return
	_in_title = false
	var tw := title.create_tween()
	tw.tween_property(title, "modulate:a", 0.0, 0.8)
	tw.tween_callback(title.queue_free)
	field.set_controls(true)
	field.show_location_banner()


func _set_transition(p: float) -> void:
	(transition.material as ShaderMaterial).set_shader_parameter("progress", p)
	var vp := get_viewport().get_visible_rect().size
	(transition.material as ShaderMaterial).set_shader_parameter("aspect", Vector2(vp.x / vp.y, 1.0))


func _transition(to: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_method(_set_transition, 1.0 - to, to, duration)
	await tw.finished


func _on_battle_requested(enemy_ids: Array, is_boss: bool) -> void:
	_was_boss = is_boss
	await _transition(1.0, 0.55)
	remove_child(field)
	battle = Battle.new()
	battle.name = "Battle"
	battle.setup(enemy_ids, is_boss)
	battle.autoplay = autobattle or OS.get_cmdline_user_args().has("--autobattle")
	battle.finished.connect(_on_battle_finished)
	add_child(battle)
	await get_tree().process_frame
	await _transition(0.0, 0.5)


func _on_battle_finished(result: String) -> void:
	await _transition(1.0, 0.5)
	battle.queue_free()
	battle = null
	add_child(field)
	field.on_battle_finished(result, _was_boss)
	print("[main] back on the field (result: %s)" % result)
	await get_tree().process_frame
	await _transition(0.0, 0.5)


## Developer flags (after `--` on the command line):
##   --skip-title          start exploring immediately
##   --battle / --boss     jump straight into a random / the boss battle
##   --autobattle          the party picks its own actions (smoke testing)
##   --at=<x>,<z>          start the player on the given map cell
##   --shot=<path>         save a screenshot after --shot-delay=<seconds> (default 3) and quit
func _handle_dev_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--skip-title") or args.has("--battle") or args.has("--boss"):
		_start_game()
	if args.has("--battle"):
		field._start_battle(["slime", "bat", "mushroom"], false)
	elif args.has("--boss"):
		field._start_battle(["king_slime"], true)
	var shot := ""
	var delay := 3.0
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
		elif a.begins_with("--shot-delay="):
			delay = a.trim_prefix("--shot-delay=").to_float()
		elif a.begins_with("--at="):
			var xz := a.trim_prefix("--at=").split(",")
			field.player.global_position = MapData.cell_center(Vector2i(xz[0].to_int(), xz[1].to_int()))
			field.camera.snap()
	if shot != "":
		await get_tree().create_timer(delay).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
