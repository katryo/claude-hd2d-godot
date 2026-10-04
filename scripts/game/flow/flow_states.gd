extends RefCounted
## Top-level game flow (host: Main): title -> explore <-> battle.


class Title extends State:
	var screen: TitleScreen

	func enter(_msg: Dictionary = {}) -> void:
		screen = TitleScreen.new()
		(host as Main).add_child(screen)
		Audio.set_music(&"title")

	func exit() -> void:
		screen.dismiss()

	func handle_input(event: InputEvent) -> bool:
		if event.is_action_pressed("accept"):
			Audio.play_sfx(&"confirm")
			transition_to(&"explore")
			return true
		return false


class Explore extends State:
	func enter(msg: Dictionary = {}) -> void:
		var m: Main = host
		if not msg.has("result"):
			Audio.set_music(&"field")
			m.field.activate()
			return
		match msg.result:
			"lose":
				# The party wakes up at the inn: its lullaby leads back into the field theme.
				Audio.set_music(&"inn")
			"win":
				# The victory fanfare hands over to the field theme by itself.
				if Audio.music_state() != &"victory":
					Audio.set_music(&"field")
			_:
				Audio.set_music(&"field")
		m.field.on_battle_finished(msg.result, msg.was_boss)


class InBattle extends State:
	var was_boss := false

	func enter(msg: Dictionary = {}) -> void:
		var m: Main = host
		was_boss = msg.is_boss
		Audio.play_sfx(&"encounter")
		Audio.set_music(&"boss" if was_boss else &"battle")
		await m.transition.cover(Main.TRANSITION_TO_BATTLE)
		m.remove_child(m.field)
		m.battle = Battle.new()
		m.battle.name = "Battle"
		m.battle.setup(msg.enemy_ids, msg.is_boss)
		m.battle.autoplay = m.autobattle
		m.battle.finished.connect(_on_battle_finished)
		m.add_child(m.battle)
		await m.get_tree().process_frame
		await m.transition.reveal(Main.TRANSITION_DURATION)

	func _on_battle_finished(result: String) -> void:
		var m: Main = host
		await m.transition.cover(Main.TRANSITION_DURATION)
		m.battle.queue_free()
		m.battle = null
		m.add_child(m.field)
		transition_to(&"explore", {"result": result, "was_boss": was_boss})
		print("[main] back on the field (result: %s)" % result)
		await m.get_tree().process_frame
		await m.transition.reveal(Main.TRANSITION_DURATION)
