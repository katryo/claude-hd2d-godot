class_name BossInteraction
extends Interaction
## Confronts the King Slime; choosing to fight starts the boss battle.

## The boss is large, so it can be reached from further away.
const EXTRA_REACH := 1.0

var _boss: Node3D


func _init(boss: Node3D) -> void:
	_boss = boss


func position() -> Vector3:
	return _boss.global_position


func extra_reach() -> float:
	return EXTRA_REACH


func run(field: Field) -> void:
	var choice := await field.dialogue.say(StoryData.BOSS_NAME, StoryData.BOSS_TAUNT, StoryData.BOSS_CHOICES)
	if choice == StoryData.BOSS_FIGHT_CHOICE:
		field.request_battle([StoryData.BOSS_ID], true)
