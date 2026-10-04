class_name Interaction
extends RefCounted
## Something the player can press "accept" on. Subclasses implement `run()`, a coroutine
## that plays out the interaction using the field's services (dialogue, inn, shop...).


func position() -> Vector3:
	return Vector3.ZERO


## Extra reach for large targets.
func extra_reach() -> float:
	return 0.0


## The NPC to show a "!" bubble over while this is the current target, if any.
func npc() -> NPC:
	return null


func run(_field: Field) -> void:
	pass
