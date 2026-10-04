class_name Combatant
extends RefCounted
## Runtime stats for anyone who can take part in a battle (party member or enemy).

signal changed

# Break & Boost
const MAX_BP := 5
const MAX_BOOST := 3
## BP a party member holds at the start of a battle / after a full restore.
const START_BP := 1
## Turns a broken enemy stays stunned: the rest of this round and the whole next one.
const BREAK_DURATION_TURNS := 2

# Placeholder stats (overwritten by BattleData when a combatant is created)
const DEFAULT_MAX_HP := 100
const DEFAULT_MAX_SP := 20
const DEFAULT_ATK := 10
const DEFAULT_MAG := 10
const DEFAULT_DEF := 5
const DEFAULT_SPD := 10

# Experience curve: EXP_CURVE_BASE + level^2 * EXP_CURVE_FACTOR to reach the next level
const EXP_CURVE_BASE := 20
const EXP_CURVE_FACTOR := 12

# Level-up stat growth: base + randi() % spread
const GROWTH_HP_BASE := 12
const GROWTH_HP_SPREAD := 6
const GROWTH_SP_BASE := 3
const GROWTH_SP_SPREAD := 3
const GROWTH_ATK_BASE := 2
const GROWTH_ATK_SPREAD := 2
const GROWTH_MAG_BASE := 2
const GROWTH_MAG_SPREAD := 2
const GROWTH_DEF_BASE := 1
const GROWTH_DEF_SPREAD := 2
const GROWTH_SPD := 1

var id: String = ""
var display_name: String = ""
var is_enemy: bool = false
var sprite_id: String = ""
var sprite_scale: float = 1.0

var level: int = 1
var xp: int = 0
var max_hp: int = DEFAULT_MAX_HP
var hp: int = DEFAULT_MAX_HP
var max_sp: int = DEFAULT_MAX_SP
var sp: int = DEFAULT_MAX_SP
var atk: int = DEFAULT_ATK
var mag: int = DEFAULT_MAG
var def: int = DEFAULT_DEF
var spd: int = DEFAULT_SPD

## Weapon/element used by the basic "Attack" command.
var weapon: String = "sword"
## Skill ids this combatant can use (see BattleData.SKILLS).
var skills: Array[String] = []

# --- Break & Boost -------------------------------------------------------
var bp: int = START_BP
var weaknesses: Array[String] = []
var revealed_weaknesses: Array[String] = []
var max_shield: int = 0
var shield: int = 0
## Number of turns the combatant still has to skip because it is broken.
var break_turns: int = 0
var defending: bool = false

# Rewards (enemies only)
var exp_reward: int = 0
var gold_reward: int = 0


func is_alive() -> bool:
	return hp > 0


func is_broken() -> bool:
	return break_turns > 0


func take_damage(amount: int) -> int:
	amount = max(amount, 1)
	hp = max(hp - amount, 0)
	changed.emit()
	return amount


func heal(amount: int) -> int:
	var before := hp
	hp = min(hp + amount, max_hp)
	changed.emit()
	return hp - before


func restore_sp(amount: int) -> int:
	var before := sp
	sp = min(sp + amount, max_sp)
	changed.emit()
	return sp - before


func spend_sp(amount: int) -> bool:
	if sp < amount:
		return false
	sp -= amount
	changed.emit()
	return true


func gain_bp(amount: int = 1) -> void:
	bp = clampi(bp + amount, 0, MAX_BP)
	changed.emit()


## Returns true when this hit broke the shield.
func hit_shield(element: String) -> bool:
	if not is_enemy or is_broken() or not weaknesses.has(element):
		return false
	if not revealed_weaknesses.has(element):
		revealed_weaknesses.append(element)
	shield = max(shield - 1, 0)
	changed.emit()
	if shield == 0:
		break_turns = BREAK_DURATION_TURNS
		return true
	return false


func end_of_round() -> void:
	defending = false
	if break_turns > 0:
		break_turns -= 1
		if break_turns == 0:
			shield = max_shield
	changed.emit()


func full_restore() -> void:
	hp = max_hp
	sp = max_sp
	bp = START_BP
	break_turns = 0
	shield = max_shield
	defending = false
	changed.emit()


func exp_to_next() -> int:
	return EXP_CURVE_BASE + level * level * EXP_CURVE_FACTOR


## Adds experience, returns the number of levels gained.
func add_exp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= exp_to_next():
		xp -= exp_to_next()
		level += 1
		gained += 1
		max_hp += GROWTH_HP_BASE + randi() % GROWTH_HP_SPREAD
		max_sp += GROWTH_SP_BASE + randi() % GROWTH_SP_SPREAD
		atk += GROWTH_ATK_BASE + randi() % GROWTH_ATK_SPREAD
		mag += GROWTH_MAG_BASE + randi() % GROWTH_MAG_SPREAD
		def += GROWTH_DEF_BASE + randi() % GROWTH_DEF_SPREAD
		spd += GROWTH_SPD
	if gained > 0:
		hp = max_hp
		sp = max_sp
	changed.emit()
	return gained
