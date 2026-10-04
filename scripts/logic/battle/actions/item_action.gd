class_name ItemAction
extends BattleAction
## Uses an item from the bag on one ally. Boost strengthens its effect.

var item_id := ""


func _init(by: Combatant, id: String, on: Array = [], boost_level: int = 0) -> void:
	super(by, on, boost_level)
	item_id = id


func execute(model: BattleModel) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var item: Dictionary = BattleData.ITEMS[item_id]
	var target: Combatant = targets[0]
	model.bag.use_item(item_id)
	events.append(BattleEvent.message("%s uses %s." % [actor.display_name, item.name]))
	events.append(BattleEvent.action_start(actor, target, BattleEvent.Motion.CAST, "heal"))
	var mult := BattleRules.item_mult(boost)
	if item.revive:
		target.hp = 0
		events.append(BattleEvent.on_target(BattleEvent.Type.REVIVE, target))
	if item.hp > 0:
		var healed := target.heal(int(item.hp * mult))
		events.append(BattleEvent.on_target(BattleEvent.Type.HEAL, target, healed))
	if item.sp > 0:
		var restored := target.restore_sp(int(item.sp * mult))
		events.append(BattleEvent.on_target(BattleEvent.Type.SP_RESTORE, target, restored))
	events.append(BattleEvent.action_end(actor, BattleEvent.Motion.CAST))
	return events
