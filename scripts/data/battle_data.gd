class_name BattleData
extends RefCounted
## Static game data: elements, skills, items, party members and enemies.

const ELEMENTS := ["sword", "bow", "staff", "fire", "ice", "thunder", "light"]

const ELEMENT_INFO := {
	"sword": {"label": "Swd", "color": Color("d8dde6")},
	"bow": {"label": "Bow", "color": Color("b8e07a")},
	"staff": {"label": "Stf", "color": Color("c9a36b")},
	"fire": {"label": "Fir", "color": Color("ff7a3d")},
	"ice": {"label": "Ice", "color": Color("7ad7ff")},
	"thunder": {"label": "Thu", "color": Color("ffe34d")},
	"light": {"label": "Lgt", "color": Color("fff4c2")},
}

## Boost level (0-3) -> damage multiplier for skills.
const BOOST_POWER := [1.0, 1.8, 2.6, 3.4]

## target: enemy | all_enemies | ally | all_allies
## kind: physical | magic | heal | buff_bp
const SKILLS := {
	"cross_slash": {"name": "Cross Slash", "cost": 6, "element": "sword", "kind": "physical",
		"target": "enemy", "power": 0.9, "hits": 2, "desc": "Two quick sword strikes."},
	"radiant_edge": {"name": "Radiant Edge", "cost": 9, "element": "light", "kind": "physical",
		"target": "enemy", "power": 1.8, "hits": 1, "desc": "A blade of light. Strong vs. darkness."},
	"fire": {"name": "Fire", "cost": 5, "element": "fire", "kind": "magic",
		"target": "enemy", "power": 1.7, "hits": 1, "desc": "Fire damage to one foe."},
	"ice": {"name": "Ice", "cost": 5, "element": "ice", "kind": "magic",
		"target": "enemy", "power": 1.7, "hits": 1, "desc": "Ice damage to one foe."},
	"thunder": {"name": "Thunder", "cost": 7, "element": "thunder", "kind": "magic",
		"target": "all_enemies", "power": 1.0, "hits": 1, "desc": "Thunder damage to all foes."},
	"heal": {"name": "Heal", "cost": 6, "element": "light", "kind": "heal",
		"target": "ally", "power": 2.4, "hits": 1, "desc": "Restore HP to one ally."},
	"twin_shot": {"name": "Twin Shot", "cost": 5, "element": "bow", "kind": "physical",
		"target": "enemy", "power": 0.8, "hits": 2, "desc": "Fire two arrows."},
	"spark_arrow": {"name": "Spark Arrow", "cost": 6, "element": "thunder", "kind": "physical",
		"target": "enemy", "power": 1.5, "hits": 1, "desc": "A crackling arrow."},
	"rally": {"name": "Rally", "cost": 8, "element": "", "kind": "buff_bp",
		"target": "all_allies", "power": 1.0, "hits": 1, "desc": "Grant every ally 1 BP."},
	# --- Enemy skills ---
	"spore_cloud": {"name": "Spore Cloud", "cost": 0, "element": "", "kind": "magic",
		"target": "all_enemies", "power": 0.8, "hits": 1, "desc": ""},
	"body_slam": {"name": "Body Slam", "cost": 0, "element": "", "kind": "physical",
		"target": "enemy", "power": 1.9, "hits": 1, "desc": ""},
	"goo_wave": {"name": "Goo Wave", "cost": 0, "element": "", "kind": "magic",
		"target": "all_enemies", "power": 1.1, "hits": 1, "desc": ""},
	"sonic_screech": {"name": "Sonic Screech", "cost": 0, "element": "", "kind": "magic",
		"target": "enemy", "power": 1.3, "hits": 1, "desc": ""},
}

const ITEMS := {
	"potion": {"name": "Healing Grape", "target": "ally", "hp": 60, "sp": 0, "revive": false,
		"desc": "Restores 60 HP."},
	"ether": {"name": "Inspiriting Plum", "target": "ally", "hp": 0, "sp": 20, "revive": false,
		"desc": "Restores 20 SP."},
	"feather": {"name": "Phoenix Down", "target": "ally_dead", "hp": 40, "sp": 0, "revive": true,
		"desc": "Revives a fallen ally."},
}

const PARTY := {
	"aren": {"name": "Aren", "sprite": "hero", "hp": 150, "sp": 30, "atk": 17, "mag": 7, "def": 9,
		"spd": 11, "weapon": "sword", "skills": ["cross_slash", "radiant_edge"]},
	"lyra": {"name": "Lyra", "sprite": "mage", "hp": 100, "sp": 60, "atk": 8, "mag": 18, "def": 6,
		"spd": 12, "weapon": "staff", "skills": ["fire", "ice", "thunder", "heal"]},
	"kit": {"name": "Kit", "sprite": "hunter", "hp": 120, "sp": 36, "atk": 14, "mag": 10, "def": 7,
		"spd": 16, "weapon": "bow", "skills": ["twin_shot", "spark_arrow", "rally"]},
}

const ENEMIES := {
	"slime": {"name": "Jelly Slime", "sprite": "slime", "scale": 1.0, "hp": 70, "atk": 11, "mag": 6,
		"def": 4, "spd": 7, "weak": ["sword", "fire"], "shield": 2, "exp": 12, "gold": 8,
		"skills": []},
	"bat": {"name": "Dusk Bat", "sprite": "bat", "scale": 1.0, "hp": 55, "atk": 12, "mag": 8,
		"def": 3, "spd": 15, "weak": ["bow", "thunder"], "shield": 2, "exp": 14, "gold": 10,
		"skills": ["sonic_screech"]},
	"mushroom": {"name": "Sporecap", "sprite": "mushroom", "scale": 1.0, "hp": 95, "atk": 11,
		"mag": 10, "def": 6, "spd": 6, "weak": ["fire", "ice", "staff"], "shield": 3, "exp": 16,
		"gold": 12, "skills": ["spore_cloud"]},
	"king_slime": {"name": "King Slime", "sprite": "king_slime", "scale": 1.8, "hp": 1200,
		"atk": 21, "mag": 16, "def": 9, "spd": 9, "weak": ["sword", "fire", "light"], "shield": 6,
		"exp": 220, "gold": 200, "skills": ["body_slam", "goo_wave"]},
}

## Random encounter groups for the tall grass.
const ENCOUNTERS := [
	["slime"],
	["slime", "slime"],
	["bat", "slime"],
	["mushroom"],
	["bat", "bat"],
	["mushroom", "slime"],
	["slime", "bat", "slime"],
]


static func make_party_member(member_id: String) -> Combatant:
	var d: Dictionary = PARTY[member_id]
	var c := Combatant.new()
	c.id = member_id
	c.display_name = d.name
	c.sprite_id = d.sprite
	c.max_hp = d.hp
	c.hp = d.hp
	c.max_sp = d.sp
	c.sp = d.sp
	c.atk = d.atk
	c.mag = d.mag
	c.def = d.def
	c.spd = d.spd
	c.weapon = d.weapon
	for s in d.skills:
		c.skills.append(s)
	return c


static func make_enemy(enemy_id: String) -> Combatant:
	var d: Dictionary = ENEMIES[enemy_id]
	var c := Combatant.new()
	c.id = enemy_id
	c.is_enemy = true
	c.display_name = d.name
	c.sprite_id = d.sprite
	c.sprite_scale = d.scale
	c.max_hp = d.hp
	c.hp = d.hp
	c.max_sp = 0
	c.sp = 0
	c.atk = d.atk
	c.mag = d.mag
	c.def = d.def
	c.spd = d.spd
	c.weapon = ""
	for w in d.weak:
		c.weaknesses.append(w)
	c.max_shield = d.shield
	c.shield = d.shield
	c.exp_reward = d.exp
	c.gold_reward = d.gold
	for s in d.skills:
		c.skills.append(s)
	c.bp = 0
	return c
