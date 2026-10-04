class_name State
extends RefCounted
## One state of a StateMachine. Override the hooks you need.
##
## `enter()` may be a coroutine (use `await`). Because the machine can move on while a
## coroutine is suspended, call `is_current()` after every `await` before acting on
## the result, and change state only through `transition_to()`.

## The machine this state belongs to. Held weakly: the machine owns its states, and a
## strong back-reference would form a cycle that RefCounted can never free.
var machine: StateMachine:
	get:
		return _machine_ref.get_ref() if _machine_ref else null
	set(value):
		_machine_ref = weakref(value)
## The object the states operate on (the machine's owner: Main, Field, Battle, ...).
var host: Object
## Key the state was registered under.
var name: StringName

var _machine_ref: WeakRef


## Called when the machine switches to this state. `msg` carries transition data.
func enter(_msg: Dictionary = {}) -> void:
	pass


## Called right before the machine leaves this state.
func exit() -> void:
	pass


## Called every frame while this state is current.
func update(_delta: float) -> void:
	pass


## Called for unhandled input while this state is current. Return true to consume it.
func handle_input(_event: InputEvent) -> bool:
	return false


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	machine.transition_to(state_name, msg)


## True while this exact activation is still the current state.
func is_current() -> bool:
	return machine != null and machine.current == self
