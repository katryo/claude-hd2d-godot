class_name LampFlicker
extends Node
## Makes street-lamp lights flicker like flames: two summed sine waves per lamp.

const FREQ_A := 9.0
## Per-lamp phase step so neighbouring lamps don't flicker in sync.
const PHASE_A := 1.7
const AMP_A := 0.08
const FREQ_B := 23.0
const AMP_B := 0.05

var _lamps: Array[OmniLight3D] = []
var _base_energy: Array[float] = []
var _time := 0.0


func _init(lamps: Array[OmniLight3D]) -> void:
	_lamps = lamps
	for lamp in lamps:
		_base_energy.append(lamp.light_energy)


func _process(delta: float) -> void:
	_time += delta
	for i in _lamps.size():
		var flicker := sin(_time * FREQ_A + i * PHASE_A) * AMP_A + sin(_time * FREQ_B + i) * AMP_B
		_lamps[i].light_energy = _base_energy[i] * (1.0 + flicker)
