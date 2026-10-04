class_name StateMachine
extends RefCounted
## Minimal finite state machine. The owner forwards `update()` and `handle_input()`
## from its own `_process()` / `_unhandled_input()`, which keeps the machine free of
## scene-tree dependencies and easy to drive from tests.

signal state_changed(from: StringName, to: StringName)

var host: Object
var states := {}
var current: State
## Name of the current state ("" before start).
var current_name: StringName = &""


func _init(owner_object: Object) -> void:
	host = owner_object


func add_state(state_name: StringName, state: State) -> StateMachine:
	state.machine = self
	state.host = host
	state.name = state_name
	states[state_name] = state
	return self


func start(state_name: StringName, msg: Dictionary = {}) -> void:
	transition_to(state_name, msg)


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	assert(states.has(state_name), "Unknown state: %s" % state_name)
	var previous := current_name
	if current:
		current.exit()
	current = states[state_name]
	current_name = state_name
	state_changed.emit(previous, state_name)
	current.enter(msg)


func is_in(state_name: StringName) -> bool:
	return current_name == state_name


func update(delta: float) -> void:
	if current:
		current.update(delta)


func handle_input(event: InputEvent) -> bool:
	return current != null and current.handle_input(event)
