class_name SfxLibrary
extends RefCounted
## Sound effect recipes. Each one is a short list of synthesized notes, rendered once
## with Synth and cached.

## Every effect: a list of note specs.
##   wave, freq (Hz), at / len (seconds), vol, slide (semitones over the note),
##   duty, env [attack, decay, sustain, release]
const SOUNDS := {
	# --- UI ---
	"cursor": [
		{"wave": "pulse", "freq": 1320.0, "len": 0.025, "vol": 0.12, "duty": 0.25, "env": [0.001, 0.02, 0.2, 0.01]},
	],
	"confirm": [
		{"wave": "pulse", "freq": 880.0, "len": 0.04, "vol": 0.14, "duty": 0.25, "env": [0.001, 0.03, 0.4, 0.01]},
		{"wave": "pulse", "freq": 1320.0, "at": 0.045, "len": 0.06, "vol": 0.14, "duty": 0.25, "env": [0.001, 0.05, 0.3, 0.03]},
	],
	"cancel": [
		{"wave": "pulse", "freq": 660.0, "len": 0.04, "vol": 0.13, "duty": 0.5, "env": [0.001, 0.03, 0.4, 0.01]},
		{"wave": "pulse", "freq": 440.0, "at": 0.045, "len": 0.06, "vol": 0.13, "duty": 0.5, "env": [0.001, 0.05, 0.3, 0.03]},
	],
	"text": [
		{"wave": "pulse", "freq": 1046.5, "len": 0.018, "vol": 0.06, "duty": 0.5, "env": [0.001, 0.015, 0.1, 0.005]},
	],
	# --- Field ---
	"encounter": [
		{"wave": "noise", "freq": 6000.0, "len": 0.45, "vol": 0.14, "slide": -30.0, "env": [0.05, 0.3, 0.3, 0.1]},
		{"wave": "pulse", "freq": 1568.0, "len": 0.06, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 1175.0, "at": 0.07, "len": 0.06, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 880.0, "at": 0.14, "len": 0.06, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 587.0, "at": 0.21, "len": 0.2, "vol": 0.12, "duty": 0.25},
	],
	"chest": [
		{"wave": "triangle", "freq": 523.25, "len": 0.08, "vol": 0.3},
		{"wave": "triangle", "freq": 783.99, "at": 0.08, "len": 0.08, "vol": 0.3},
		{"wave": "triangle", "freq": 1046.5, "at": 0.16, "len": 0.3, "vol": 0.3, "env": [0.002, 0.2, 0.4, 0.3]},
		{"wave": "sine", "freq": 2093.0, "at": 0.2, "len": 0.25, "vol": 0.1, "env": [0.002, 0.2, 0.2, 0.2]},
	],
	"coin": [
		{"wave": "pulse", "freq": 987.77, "len": 0.06, "vol": 0.12, "duty": 0.5},
		{"wave": "pulse", "freq": 1318.5, "at": 0.06, "len": 0.25, "vol": 0.12, "duty": 0.5, "env": [0.001, 0.15, 0.3, 0.15]},
	],
	# --- Battle ---
	"swing": [
		{"wave": "noise", "freq": 2500.0, "len": 0.1, "vol": 0.12, "slide": 18.0, "env": [0.02, 0.06, 0.2, 0.03]},
	],
	"hit": [
		{"wave": "noise", "freq": 1800.0, "len": 0.07, "vol": 0.3, "env": [0.001, 0.06, 0.0, 0.02]},
		{"wave": "sine", "freq": 160.0, "len": 0.1, "vol": 0.45, "slide": -12.0, "env": [0.001, 0.09, 0.0, 0.02]},
	],
	"weak_hit": [
		{"wave": "noise", "freq": 3500.0, "len": 0.09, "vol": 0.32, "env": [0.001, 0.08, 0.0, 0.02]},
		{"wave": "sine", "freq": 220.0, "len": 0.12, "vol": 0.45, "slide": -14.0, "env": [0.001, 0.1, 0.0, 0.02]},
		{"wave": "pulse", "freq": 1760.0, "at": 0.02, "len": 0.06, "vol": 0.1, "duty": 0.25, "slide": -5.0},
	],
	"break": [
		{"wave": "noise", "freq": 8000.0, "len": 0.35, "vol": 0.25, "slide": -12.0, "env": [0.001, 0.3, 0.1, 0.1]},
		{"wave": "sine", "freq": 2637.0, "len": 0.25, "vol": 0.12, "env": [0.001, 0.2, 0.2, 0.15]},
		{"wave": "sine", "freq": 3520.0, "at": 0.04, "len": 0.2, "vol": 0.1, "env": [0.001, 0.15, 0.2, 0.15]},
		{"wave": "sine", "freq": 3136.0, "at": 0.09, "len": 0.25, "vol": 0.1, "env": [0.001, 0.2, 0.2, 0.2]},
		{"wave": "sine", "freq": 110.0, "len": 0.3, "vol": 0.4, "slide": -12.0, "env": [0.001, 0.25, 0.0, 0.05]},
	],
	"spell": [
		{"wave": "sine", "freq": 330.0, "len": 0.35, "vol": 0.18, "slide": 24.0, "env": [0.03, 0.2, 0.5, 0.1]},
		{"wave": "triangle", "freq": 660.0, "at": 0.05, "len": 0.3, "vol": 0.1, "slide": 24.0, "env": [0.03, 0.2, 0.4, 0.1]},
		{"wave": "noise", "freq": 4000.0, "len": 0.3, "vol": 0.05, "env": [0.05, 0.2, 0.3, 0.1]},
	],
	"heal": [
		{"wave": "sine", "freq": 1046.5, "len": 0.08, "vol": 0.2},
		{"wave": "sine", "freq": 1318.5, "at": 0.07, "len": 0.08, "vol": 0.2},
		{"wave": "sine", "freq": 1568.0, "at": 0.14, "len": 0.08, "vol": 0.2},
		{"wave": "sine", "freq": 2093.0, "at": 0.21, "len": 0.25, "vol": 0.2, "env": [0.002, 0.2, 0.3, 0.2]},
	],
	"boost": [
		{"wave": "pulse", "freq": 440.0, "len": 0.15, "vol": 0.12, "duty": 0.25, "slide": 12.0, "env": [0.005, 0.1, 0.6, 0.05]},
		{"wave": "noise", "freq": 5000.0, "len": 0.15, "vol": 0.05, "env": [0.03, 0.1, 0.3, 0.05]},
	],
	"enemy_down": [
		{"wave": "pulse", "freq": 880.0, "len": 0.35, "vol": 0.14, "duty": 0.5, "slide": -24.0, "env": [0.001, 0.3, 0.4, 0.05]},
		{"wave": "noise", "freq": 1500.0, "len": 0.3, "vol": 0.12, "slide": -12.0, "env": [0.01, 0.25, 0.2, 0.05]},
	],
	"party_down": [
		{"wave": "sine", "freq": 220.0, "len": 0.3, "vol": 0.35, "slide": -12.0, "env": [0.001, 0.25, 0.2, 0.05]},
		{"wave": "triangle", "freq": 330.0, "at": 0.05, "len": 0.25, "vol": 0.15, "slide": -7.0},
	],
	"level_up": [
		{"wave": "pulse", "freq": 523.25, "len": 0.07, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 659.25, "at": 0.07, "len": 0.07, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 783.99, "at": 0.14, "len": 0.07, "vol": 0.12, "duty": 0.25},
		{"wave": "pulse", "freq": 1046.5, "at": 0.21, "len": 0.35, "vol": 0.12, "duty": 0.25, "env": [0.002, 0.2, 0.5, 0.2]},
	],
	"flee": [
		{"wave": "noise", "freq": 3000.0, "len": 0.3, "vol": 0.12, "slide": -18.0, "env": [0.01, 0.25, 0.2, 0.05]},
		{"wave": "pulse", "freq": 784.0, "len": 0.25, "vol": 0.08, "duty": 0.125, "slide": -12.0},
	],
}

## Elements tune the generic "spell" sound (semitone offsets).
const SPELL_PITCH := {
	"fire": -3.0, "ice": 7.0, "thunder": -7.0, "light": 9.0, "heal": 5.0,
	"sword": 0.0, "bow": 2.0, "staff": -2.0, "dark": -9.0, "": -5.0,
}

const WAVES := {
	"pulse": Synth.Wave.PULSE, "triangle": Synth.Wave.TRIANGLE, "saw": Synth.Wave.SAW,
	"sine": Synth.Wave.SINE, "noise": Synth.Wave.NOISE,
}
const DEFAULT_ENV := [0.002, 0.05, 0.5, 0.03]
const DEFAULT_DUTY := 0.5
const SFX_SEED := 99
## Silence padded after the longest note so releases aren't cut off.
const TAIL := 0.1


static func names() -> Array:
	return SOUNDS.keys()


static func render(sfx_name: String) -> AudioStreamWAV:
	var notes: Array = SOUNDS[sfx_name]
	var length := 0.0
	for n in notes:
		var env: Array = n.get("env", DEFAULT_ENV)
		length = maxf(length, n.get("at", 0.0) + n.len + env[3])
	var buf := Synth.make_buffer(length + TAIL)
	var rng := RandomNumberGenerator.new()
	rng.seed = SFX_SEED
	for n in notes:
		var v := Synth.Voice.new(WAVES[n.wave], n.vol)
		var env: Array = n.get("env", DEFAULT_ENV)
		v.with_env(env[0], env[1], env[2], env[3])
		v.duty = n.get("duty", DEFAULT_DUTY)
		v.slide = n.get("slide", 0.0)
		Synth.add_note(buf, Synth.seconds_to_samples(n.get("at", 0.0)), n.freq, n.len, v, false, rng)
	return Synth.to_stream(buf)


static func spell_pitch_scale(element: String) -> float:
	return pow(2.0, SPELL_PITCH.get(element, 0.0) / Synth.SEMITONES)
