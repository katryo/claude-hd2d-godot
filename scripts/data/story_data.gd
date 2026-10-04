class_name StoryData
extends RefCounted
## Story content: NPC dialogue, shop stock and scripted lines. Kept as data so writing
## and balancing never require touching the field logic.
##
## NPC_DIALOGUE maps an NPC id to a list of variants; the first variant whose conditions
## hold is used. Variant keys:
##   lines       Array[String]  what the NPC says
##   if_flag     String         only if this story flag is set
##   set_flag    String         set this flag when the variant plays
##   choices     Array[String]  options offered after the last line
##   service     String         "inn" or "shop", run after the lines
##   service_on  int            only run the service if this choice was picked
##   after       Array[String]  lines spoken after the service

const BOSS_DEFEATED := "boss_defeated"
const QUEST_STARTED := "quest_started"

const NPC_DIALOGUE := {
	"elder": [
		{"if_flag": BOSS_DEFEATED, "lines": [
			"You did it! The shrine's light shines over the meadow once more.",
			"Lumen Hollow owes you everything, young ones. Stay as long as you like.",
		]},
		{"set_flag": QUEST_STARTED, "lines": [
			"Aren, Lyra, Kit... thank the stars you're here.",
			"A monstrous [color=#7aa0ff]King Slime[/color] has oozed into the Old Shrine north of the meadow.",
			"Its gloom is drawing monsters into the tall grass. Travelers can't even reach the bridge!",
			"Its hide is weak to [color=#e0e0e0]blades[/color], [color=#ff7a3d]fire[/color] and [color=#fff4c2]holy light[/color].",
			"Strike its weaknesses to [color=#ffd36b]Break[/color] its guard, then [color=#ffa040]Boost[/color] your attacks while it reels.",
			"Rest at Rosa's inn and stock up at Tobin's before you go.",
		]},
	],
	"innkeeper": [
		{"lines": [
			"Welcome to the Sleeping Fox! Heroes stay free of charge, of course.",
			"Would you like to rest?",
		], "choices": ["Rest", "Not now"], "service": "inn", "service_on": 0,
		"after": ["Good morning! You look ready for anything."]},
	],
	"merchant": [
		{"lines": [], "service": "shop"},
	],
	"child": [
		{"lines": [
			"Did you know? Every turn in battle you store up [color=#ffa040]Boost Points[/color]!",
			"Press [color=#ffd36b]E[/color] before choosing an action to spend them. Attack more times, or make skills way stronger!",
			"Press [color=#ffd36b]Q[/color] to take some back. I'm gonna be a hero too someday!",
		]},
	],
	"guard": [
		{"if_flag": BOSS_DEFEATED, "lines": ["The meadow's calmer already. Fine work, all of you."]},
		{"lines": [
			"Halt! ...Oh, it's you three. The meadow's crawling with monsters.",
			"Each monster carries a [color=#c8d0e0]shield[/color]. Hit it with something it's weak to and the shield cracks.",
			"Bring it to zero and it [color=#ffd36b]BREAKS[/color]: it loses its next turn and takes double damage.",
			"Weaknesses you discover show up above the monster. Mix your weapons and spells!",
		]},
	],
	"fisher": [
		{"lines": [
			"Shh... the river fish are skittish today.",
			"Monsters only bother folk walking through the [color=#9ad66a]tall grass[/color]. Stick to the path if you're weary.",
			"Hold [color=#ffd36b]Shift[/color] to hurry along, young'un.",
		]},
	],
}
const DEFAULT_NPC_LINES := ["..."]

# Shop: [item id, price in gold]
const SHOP_STOCK := [["potion", 20], ["ether", 40], ["feather", 80]]
const SHOP_GREETING := "Welcome! Have a look - finest curatives this side of the river."
const SHOP_AGAIN := "Anything else? You have %d G."
const SHOP_LEAVE := "Leave"
const SHOP_FAREWELL := "Safe travels!"
const SHOP_TOO_POOR := "Ah... you're a little short on coin, friend."
const SHOP_THANKS := "One %s. Thank you kindly! (Owned: %d)"

# Chests
const DEFAULT_CHEST_LOOT := {"item": "potion", "count": 1}
const CHEST_EMPTY := "The chest is empty."
const CHEST_FOUND := "Found [color=#ffd36b]%s x%d[/color]!"

# Boss
const BOSS_ID := "king_slime"
const BOSS_NAME := "King Slime"
const BOSS_TAUNT := [
	"BLORP... Tiny morsels wander into MY shrine?",
	"This sacred light tastes delicious. I shall gobble up your village next!",
]
const BOSS_CHOICES := ["Fight!", "Retreat for now"]
const BOSS_FIGHT_CHOICE := 0
const BOSS_VICTORY_TITLE := "The Shrine is Cleansed"
const BOSS_VICTORY_SUBTITLE := "Peace returns to Lumen Hollow"
const BOSS_VICTORY_LINES := [
	"With the King Slime defeated, warm light spills from the Old Shrine across the meadow.",
	"Thank you for playing! Feel free to keep exploring and battling in the tall grass.",
]

# Defeat
const RESCUER_NAME := "Innkeeper Rosa"
const RESCUE_LINES := [
	"Oh my! The guard carried you all back here, battered and bruised.",
	"You've rested up now. Please be careful out there!",
]

# Location
const LOCATION_TITLE := "Lumen Hollow"
const LOCATION_SUBTITLE := "~ a quiet village at the meadow's edge ~"


static func npc_variant(npc_id: String, flags: Callable) -> Dictionary:
	for variant in NPC_DIALOGUE.get(npc_id, []):
		if variant.has("if_flag") and not flags.call(variant.if_flag):
			continue
		return variant
	return {"lines": DEFAULT_NPC_LINES}


static func objective(boss_defeated: bool) -> String:
	if boss_defeated:
		return "Peace has returned to Lumen Hollow."
	return "Defeat the King Slime in the Old Shrine (north)."


static func chest_flag(cell: Vector2i) -> String:
	return "chest_%d_%d" % [cell.x, cell.y]
