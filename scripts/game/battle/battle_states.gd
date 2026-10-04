extends RefCounted
## States of the battle flow (host: Battle).
##
##   intro -> round_start -> turn_start -> choose_action -> resolve_action -> turn_start ...
##                              |                                              |
##                              +-> round_end -> round_start                   +-> choose_action (boss bonus action)
##   Any state that finds the battle decided goes to outcome -> victory | defeat -> finished.


class Intro extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		var names := b.model.enemies.map(func(e): return e.display_name)
		var line := ("%s blocks the way!" if b.model.is_boss else "%s appeared!") % " & ".join(names)
		await b.view.announce(line, Battle.INTRO_MESSAGE_TIME)
		if is_current():
			transition_to(&"round_start")


class RoundStart extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		b.view.ui.set_turn_order(b.model.begin_round())
		transition_to(&"turn_start")


class TurnStart extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		if b.model.is_over():
			transition_to(&"outcome")
			return
		var previous := b.model.turn_index
		var actor := b.model.next_turn()
		# Grey out anyone skipped because they fell earlier this round.
		for i in range(previous + 1, b.model.turn_index):
			b.view.ui.mark_turn_done(i)
		if actor == null:
			transition_to(&"round_end")
			return
		if actor.is_broken():
			await b.view.announce("%s is broken and cannot act!" % actor.display_name, Battle.BROKEN_MESSAGE_TIME)
			if not is_current():
				return
			b.view.ui.mark_turn_done(b.model.turn_index)
			transition_to(&"turn_start")
			return
		transition_to(&"choose_action", {"actor": actor})


class ChooseAction extends State:
	var actor: Combatant
	var controller: BattleController

	func enter(msg: Dictionary = {}) -> void:
		var b: Battle = host
		actor = msg.actor
		controller = b.controller_for(actor)
		b.view.ui.set_active(actor)
		b.view.view_of(actor).step_forward()
		if controller.is_automatic() and not actor.is_enemy:
			await b.view.wait(Battle.AUTO_THINK_TIME)
			if not is_current():
				return
		var action := await controller.choose_action(b.model, actor)
		if is_current():
			transition_to(&"resolve_action", {"action": action, "actor": actor})

	func handle_input(event: InputEvent) -> bool:
		return controller is PlayerBattleInput and controller.handle_input(event)


class ResolveAction extends State:
	func enter(msg: Dictionary = {}) -> void:
		var b: Battle = host
		var actor: Combatant = msg.actor
		var action: BattleAction = msg.action
		if action:
			if action.uses_boost() and action.boost > 0:
				b.model.spend_boost(actor, action.boost)
				b.view.effects.show_boost(b.view.view_of(actor).position(), action.boost)
				b.view.ui.show_message("BOOST x%d!" % action.boost)
			b.view.ui.set_boost_preview(0)
			await b.view.play(action.execute(b.model))
			b.view.effects.hide_boost()
			if not is_current():
				return
		if b.model.outcome == BattleModel.Outcome.FLED:
			transition_to(&"outcome")
			return
		if b.model.grants_extra_action(actor):
			transition_to(&"choose_action", {"actor": actor})
			return
		b.view.view_of(actor).step_back()
		b.view.ui.mark_turn_done(b.model.turn_index)
		b.view.ui.set_active(null)
		transition_to(&"turn_start")


class RoundEnd extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		if b.model.is_over():
			transition_to(&"outcome")
			return
		b.model.end_round()
		b.view.refresh_status()
		transition_to(&"round_start")


class Outcome extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		match b.model.resolve_outcome():
			BattleModel.Outcome.VICTORY:
				transition_to(&"victory")
			BattleModel.Outcome.DEFEAT:
				transition_to(&"defeat")
			_:
				transition_to(&"finished")


class Victory extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		var rewards := b.model.rewards()
		b.model.bag.add_gold(rewards.gold)
		b.view.banner.show_text("VICTORY", "%d EXP   %d G" % [rewards.xp, rewards.gold], Battle.BANNER_TIME)
		await b.view.wait(Battle.VICTORY_BANNER_WAIT)
		for m in b.model.grant_experience(rewards.xp):
			b.view.ui.show_message("%s reached level %d!" % [m.display_name, m.level])
			b.view.celebrate(m)
			await b.view.wait(Battle.LEVEL_UP_TIME)
		b.view.ui.refresh()
		await b.view.wait(Battle.VICTORY_END_TIME)
		if is_current():
			transition_to(&"finished")


class Defeat extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		b.view.banner.show_text("DEFEAT", "The party has fallen...", Battle.BANNER_TIME)
		await b.view.wait(Battle.DEFEAT_WAIT)
		if is_current():
			transition_to(&"finished")


class Finished extends State:
	func enter(_msg: Dictionary = {}) -> void:
		var b: Battle = host
		b.model.cleanup()
		var result := BattleModel.outcome_name(b.model.outcome)
		print("[battle] finished: %s after %d rounds" % [result, b.model.round_number])
		b.finished.emit(result)
