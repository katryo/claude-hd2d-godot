class_name Combatant
extends RefCounted
## Runtime stats for anyone who can take part in a battle (party member or enemy).

signal changed

const MAX_BP := 5
const MAX_BOOST := 3

var id: String = ""
var display_name: String = ""
var is_enemy: bool = false
var sprite_id: String = ""
var sprite_scale: float = 1.0

var level: int = 1
var xp: int = 0
var max_hp: int = 100
var hp: int = 100
var max_sp: int = 20
var sp: int = 20
var atk: int = 10
var mag: int = 10
var def: int = 5
var spd: int = 10

## Weapon/element used by the basic "Attack" command.
var weapon: String = "sword"
## Skill ids this combatant can use (see BattleData.SKILLS).
var skills: Array[String] = []

# --- Break & Boost -------------------------------------------------------
var bp: int = 1
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
		# Broken for the rest of this round and the whole next one.
		break_turns = 2
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
	bp = 1
	break_turns = 0
	shield = max_shield
	defending = false
	changed.emit()


func exp_to_next() -> int:
	return 20 + level * level * 12


## Adds experience, returns the number of levels gained.
func add_exp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= exp_to_next():
		xp -= exp_to_next()
		level += 1
		gained += 1
		max_hp += 12 + randi() % 6
		max_sp += 3 + randi() % 3
		atk += 2 + randi() % 2
		mag += 2 + randi() % 2
		def += 1 + randi() % 2
		spd += 1
	if gained > 0:
		hp = max_hp
		sp = max_sp
	changed.emit()
	return gained
