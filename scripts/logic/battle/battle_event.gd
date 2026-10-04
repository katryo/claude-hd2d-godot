class_name BattleEvent
extends RefCounted
## Something that happened in the battle model. Actions return a list of these; the view
## replays them as animations, so game rules never touch nodes and visuals never decide
## outcomes.

enum Type {
	MESSAGE,       ## text: narration line
	ACTION_START,  ## actor, target (may be null), motion, element
	ACTION_END,    ## actor, motion
	HIT,           ## actor, target, amount, weak, element, from_skill
	SHIELD_BREAK,  ## target
	DEFEATED,      ## target
	HEAL,          ## target, amount
	SP_RESTORE,    ## target, amount
	BP_GAIN,       ## target, amount
	REVIVE,        ## target
}

## How the acting combatant moves while performing an action.
enum Motion { NONE, LUNGE, CAST }

var type: Type
var actor: Combatant
var target: Combatant
var amount := 0
var weak := false
var element := ""
var from_skill := false
var motion: Motion = Motion.NONE
var text := ""


static func message(msg: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.MESSAGE
	e.text = msg
	return e


static func action_start(by: Combatant, toward: Combatant, how: Motion, el: String = "") -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.ACTION_START
	e.actor = by
	e.target = toward
	e.motion = how
	e.element = el
	return e


static func action_end(by: Combatant, how: Motion) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.ACTION_END
	e.actor = by
	e.motion = how
	return e


static func hit(by: Combatant, on: Combatant, dmg: int, is_weak: bool, el: String, skill: bool) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.HIT
	e.actor = by
	e.target = on
	e.amount = dmg
	e.weak = is_weak
	e.element = el
	e.from_skill = skill
	return e


static func on_target(t: Type, on: Combatant, value: int = 0) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = t
	e.target = on
	e.amount = value
	return e
