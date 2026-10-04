class_name EncounterTracker
extends RefCounted
## Random encounters: walking through encounter terrain fills a meter; once it passes a
## randomly chosen threshold a monster group is rolled.

const ENCOUNTER_TERRAIN := ","
const THRESHOLD_MIN := 7.0
const THRESHOLD_MAX := 15.0

var rng: RandomNumberGenerator
## Distance walked in encounter terrain since the last battle.
var meter := 0.0
var threshold := THRESHOLD_MAX


func _init(p_rng: RandomNumberGenerator = null) -> void:
	rng = p_rng if p_rng else RandomNumberGenerator.new()
	if not p_rng:
		rng.randomize()
	reset()


func reset() -> void:
	meter = 0.0
	threshold = rng.randf_range(THRESHOLD_MIN, THRESHOLD_MAX)


## Records `distance` walked on `terrain`. Returns the enemy ids to fight, or [] if none.
func advance(distance: float, terrain: String) -> Array:
	if terrain != ENCOUNTER_TERRAIN:
		return []
	meter += distance
	if meter < threshold:
		return []
	var group: Array = BattleData.ENCOUNTERS[rng.randi_range(0, BattleData.ENCOUNTERS.size() - 1)]
	return group.duplicate()
