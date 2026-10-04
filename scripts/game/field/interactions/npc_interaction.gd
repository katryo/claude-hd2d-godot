class_name NpcInteraction
extends Interaction
## Talks to a villager using the data-driven dialogue in StoryData.NPC_DIALOGUE.

var _npc: NPC


func _init(p_npc: NPC) -> void:
	_npc = p_npc


func position() -> Vector3:
	return _npc.global_position


func npc() -> NPC:
	return _npc


func run(field: Field) -> void:
	_npc.talking = true
	_npc.face_towards(field.player.global_position)
	field.player.face_towards(_npc.global_position)
	var variant := StoryData.npc_variant(_npc.npc_id, Game.has_flag)
	if variant.has("set_flag"):
		Game.set_flag(variant.set_flag)
	var choice := -1
	var lines: Array = variant.get("lines", [])
	if not lines.is_empty():
		choice = await field.dialogue.say(_npc.display_name, lines, variant.get("choices", []))
	var service: String = variant.get("service", "")
	if service != "" and (not variant.has("service_on") or choice == variant.service_on):
		await field.run_service(service, _npc.display_name)
		if variant.has("after"):
			await field.dialogue.say(_npc.display_name, variant.after)
	_npc.talking = false
