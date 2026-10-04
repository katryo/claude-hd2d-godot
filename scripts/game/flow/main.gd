class_name Main
extends Node
## Entry point. Owns the field (kept alive while battles run) and drives the top-level
## flow with a StateMachine: title -> explore <-> battle.

const States = preload("res://scripts/game/flow/flow_states.gd")

# Screen transitions (seconds)
const TRANSITION_TO_BATTLE := 0.55
const TRANSITION_DURATION := 0.5

# Developer flags
const DEFAULT_SHOT_DELAY := 3.0
const DEV_BATTLE_ENEMIES := ["slime", "bat", "mushroom"]

var field: Field
var battle: Battle
var transition: ScreenTransition
var machine: StateMachine
## When true, battles play themselves (set by --autobattle or tests).
var autobattle := false


func _ready() -> void:
	add_child(Visuals.make_vignette())
	transition = ScreenTransition.new()
	add_child(transition)
	field = Field.new()
	field.name = "Field"
	add_child(field)
	field.battle_requested.connect(_on_battle_requested)
	machine = StateMachine.new(self)
	machine.add_state(&"title", States.Title.new()) \
		.add_state(&"explore", States.Explore.new()) \
		.add_state(&"battle", States.InBattle.new())
	machine.start(&"title")
	_handle_dev_args()


func _exit_tree() -> void:
	# The field is detached while a battle runs; make sure it is freed on quit.
	if field and not field.is_inside_tree():
		field.free()


func _unhandled_input(event: InputEvent) -> void:
	if machine.handle_input(event):
		get_viewport().set_input_as_handled()


func _on_battle_requested(enemy_ids: Array, is_boss: bool) -> void:
	machine.transition_to(&"battle", {"enemy_ids": enemy_ids, "is_boss": is_boss})


## Developer flags (after `--` on the command line):
##   --skip-title          start exploring immediately
##   --battle / --boss     jump straight into a random / the boss battle
##   --autobattle          the party picks its own actions (smoke testing)
##   --at=<x>,<z>          start the player on the given map cell
##   --shot=<path>         save a screenshot after --shot-delay=<seconds> (default 3) and quit
func _handle_dev_args() -> void:
	var args := OS.get_cmdline_user_args()
	autobattle = args.has("--autobattle")
	if args.has("--skip-title") or args.has("--battle") or args.has("--boss"):
		machine.transition_to(&"explore")
	if args.has("--battle"):
		field.request_battle(DEV_BATTLE_ENEMIES.duplicate(), false)
	elif args.has("--boss"):
		field.request_battle([StoryData.BOSS_ID], true)
	var shot := ""
	var delay := DEFAULT_SHOT_DELAY
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
		elif a.begins_with("--shot-delay="):
			delay = a.trim_prefix("--shot-delay=").to_float()
		elif a.begins_with("--at="):
			var xz := a.trim_prefix("--at=").split(",")
			field.player.global_position = MapData.cell_center(Vector2i(xz[0].to_int(), xz[1].to_int()))
			field.view.reactivate_camera()
	if shot != "":
		await get_tree().create_timer(delay).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
