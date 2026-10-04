extends RefCounted
## States of the overworld (host: Field).
##
##   suspended <-> explore <-> interact      (talking, chests, scripted scenes)
##                    ^  \-> status          (pause menu)
##   suspended is used on the title screen and while a battle is running.


class Suspended extends State:
	func enter(_msg: Dictionary = {}) -> void:
		(host as Field).player.stop()


class Explore extends State:
	func enter(_msg: Dictionary = {}) -> void:
		(host as Field).player.controls_enabled = true

	func exit() -> void:
		var f: Field = host
		f.player.stop()
		f.update_bubbles(null)

	func update(_delta: float) -> void:
		var f: Field = host
		f.update_bubbles(f.current_target())

	func handle_input(event: InputEvent) -> bool:
		var f: Field = host
		if event.is_action_pressed("accept"):
			var target := f.current_target()
			if target:
				transition_to(&"interact", {"interaction": target})
				return true
		elif event.is_action_pressed("menu"):
			transition_to(&"status")
			return true
		return false


## Runs an Interaction or a scripted Callable, then returns to exploring unless the
## script moved the field elsewhere (e.g. started a battle).
class Interact extends State:
	func enter(msg: Dictionary = {}) -> void:
		var f: Field = host
		if msg.has("interaction"):
			await (msg.interaction as Interaction).run(f)
		elif msg.has("script"):
			await (msg.script as Callable).call()
		if is_current():
			transition_to(&"explore")


class Status extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var f: Field = host
		f.view.status_panel.open(Game.party, Game.inventory, Game.gold,
			StoryData.objective(Game.has_flag(StoryData.BOSS_DEFEATED)))

	func exit() -> void:
		(host as Field).view.status_panel.close()

	func handle_input(event: InputEvent) -> bool:
		if event.is_action_pressed("cancel") or event.is_action_pressed("menu"):
			transition_to(&"explore")
			return true
		return false
