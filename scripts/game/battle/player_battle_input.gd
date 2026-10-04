class_name PlayerBattleInput
extends BattleController
## Lets the human pick a party member's action through the battle menus, the target
## cursor and the Boost keys. Bridges the view (menus, cursor) and the logic (actions).

signal _target_chosen(result: Variant)

var view: BattleView
## The party member whose command is being chosen (null when not choosing).
var actor: Combatant
var boost_level := 0

var _model: BattleModel
var _targets: Array = []
var _target_index := 0
var _target_all := false
var _picking := false


func _init(battle_view: BattleView) -> void:
	view = battle_view


func is_automatic() -> bool:
	return false


func choose_action(model: BattleModel, who: Combatant) -> BattleAction:
	_model = model
	actor = who
	set_boost(0)
	while true:
		var cmd := await view.ui.choose_command(who, model.can_flee())
		match cmd:
			"attack":
				var target = await _pick_one(model.opponents_of(who))
				if target != null:
					return _done(AttackAction.new(who, [target], boost_level))
			"skill":
				var skill_id := await view.ui.choose_skill(who)
				if skill_id != "":
					var targets := await _pick_for(BattleData.SKILLS[skill_id].target)
					if not targets.is_empty():
						return _done(SkillAction.new(who, skill_id, targets, boost_level))
			"item":
				var item_id := await view.ui.choose_item(model.bag)
				if item_id != "":
					var kind := "ally_dead" if BattleData.ITEMS[item_id].revive else "ally"
					var target = await _pick_one(model.candidates_for(who, kind))
					if target != null:
						return _done(ItemAction.new(who, item_id, [target], boost_level))
			"defend":
				return _done(DefendAction.new(who))
			"flee":
				return _done(FleeAction.new(who))
	return null


func set_boost(level: int) -> void:
	if actor == null:
		return
	boost_level = clampi(level, 0, _model.max_boost(actor))
	view.ui.set_boost_preview(boost_level)
	view.effects.show_boost(view.view_of(actor).position(), boost_level)


## Boost keys while choosing; arrows/accept/cancel while targeting. Returns true if used.
func handle_input(event: InputEvent) -> bool:
	if actor == null:
		return false
	if event.is_action_pressed("boost_up"):
		set_boost(boost_level + 1)
		return true
	if event.is_action_pressed("boost_down"):
		set_boost(boost_level - 1)
		return true
	if not _picking:
		return false
	if event.is_action_pressed("accept"):
		_end_picking(_targets if _target_all else [_targets[_target_index]])
		return true
	if event.is_action_pressed("cancel"):
		_end_picking(null)
		return true
	if _target_all:
		return false
	var step := 0
	if event.is_action_pressed("move_down", true) or event.is_action_pressed("move_right", true):
		step = 1
	elif event.is_action_pressed("move_up", true) or event.is_action_pressed("move_left", true):
		step = -1
	if step == 0:
		return false
	_target_index = posmod(_target_index + step, _targets.size())
	_show_target()
	return true


func _done(action: BattleAction) -> BattleAction:
	if not action.uses_boost():
		set_boost(0)
	actor = null
	return action


## Returns the chosen Combatant, or null if cancelled.
func _pick_one(candidates: Array) -> Variant:
	if candidates.is_empty():
		return null
	# Sort top-to-bottom on screen so up/down feel natural.
	candidates.sort_custom(func(a, b): return view.view_of(a).home.z < view.view_of(b).home.z)
	_targets = candidates
	_target_all = false
	_target_index = clampi(_target_index, 0, candidates.size() - 1)
	_picking = true
	_show_target()
	var result = await _target_chosen
	return null if result == null else result[0]


func _pick_all(candidates: Array) -> Array:
	if candidates.is_empty():
		return []
	_targets = candidates
	_target_all = true
	_picking = true
	view.cursor.point_at_all(view.views_of(candidates))
	view.ui.show_help("Targets all. Confirm with Z/Enter.")
	var result = await _target_chosen
	return [] if result == null else result


func _pick_for(target_kind: String) -> Array:
	var candidates := _model.candidates_for(actor, target_kind)
	if target_kind.begins_with("all_"):
		return await _pick_all(candidates)
	var one = await _pick_one(candidates)
	return [] if one == null else [one]


func _show_target() -> void:
	var t: Combatant = _targets[_target_index]
	view.cursor.point_at(view.view_of(t))
	if t.is_enemy:
		view.ui.show_help("%s   Shield %d" % [t.display_name, t.shield])
	else:
		view.ui.show_help("%s   HP %d/%d   SP %d/%d" % [t.display_name, t.hp, t.max_hp, t.sp, t.max_sp])


func _end_picking(result: Variant) -> void:
	_picking = false
	view.cursor.dismiss()
	view.ui.show_help("")
	_target_chosen.emit(result)
