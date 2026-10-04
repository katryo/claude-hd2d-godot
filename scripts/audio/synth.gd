class_name Synth
extends RefCounted
## Tiny offline synthesizer: renders chiptune-style tones and noise into float buffers
## and packs them as AudioStreamWAV. Everything audible in the game is made here, so the
## project ships no audio files.

const SAMPLE_RATE := 22050
const A4_FREQ := 440.0
const A4_MIDI := 69
const SEMITONES := 12.0
const PCM16_MAX := 32767.0
const BYTES_PER_SAMPLE := 2

enum Wave { PULSE, TRIANGLE, SAW, SINE, NOISE }

const NOTE_OFFSETS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


## Instrument / envelope settings for one note. Times are in seconds.
class Voice:
	var wave: Wave = Wave.PULSE
	## Pulse width for Wave.PULSE (0.5 = square).
	var duty := 0.5
	var volume := 0.2
	var attack := 0.005
	var decay := 0.08
	var sustain := 0.6
	var release := 0.06
	## Vibrato depth in semitones and rate in Hz (starts after vibrato_delay).
	var vibrato_depth := 0.0
	var vibrato_rate := 5.5
	var vibrato_delay := 0.15
	## Pitch glide over the note, in semitones (negative = falls).
	var slide := 0.0

	func _init(w: Wave = Wave.PULSE, vol: float = 0.2) -> void:
		wave = w
		volume = vol

	func with_env(a: float, d: float, s: float, r: float) -> Voice:
		attack = a
		decay = d
		sustain = s
		release = r
		return self


static func midi_to_freq(midi: float) -> float:
	return A4_FREQ * pow(2.0, (midi - A4_MIDI) / SEMITONES)


## Parses note names like "C4", "F#5", "Bb3" into MIDI numbers.
static func note_to_midi(note: String) -> int:
	var letter := note.substr(0, 1).to_upper()
	var rest := note.substr(1)
	var offset: int = NOTE_OFFSETS[letter]
	while rest.begins_with("#") or rest.begins_with("b"):
		offset += 1 if rest.begins_with("#") else -1
		rest = rest.substr(1)
	return (int(rest) + 1) * int(SEMITONES) + offset


static func seconds_to_samples(seconds: float) -> int:
	return int(seconds * SAMPLE_RATE)


## Adds one note to `buf` starting at `start` (samples), lasting `length` seconds plus
## the voice's release. With `wrap` the tail wraps to the buffer start (seamless loops).
static func add_note(buf: PackedFloat32Array, start: int, freq: float, length: float, v: Voice,
		wrap: bool = false, rng: RandomNumberGenerator = null) -> void:
	mix(buf, start, render_note(freq, length, v, rng), wrap)


## Adds a pre-rendered note into `buf` at `start`, wrapping its tail if `wrap`.
static func mix(buf: PackedFloat32Array, start: int, note: PackedFloat32Array, wrap: bool = false) -> void:
	var n := buf.size()
	var count := note.size()
	if start + count <= n:
		for i in count:
			buf[start + i] += note[i]
		return
	for i in count:
		var idx := start + i
		if idx >= n:
			if not wrap:
				return
			idx -= n
		buf[idx] += note[i]


## Renders a single note (with its release tail) into a new buffer.
static func render_note(freq: float, length: float, v: Voice, rng: RandomNumberGenerator = null) -> PackedFloat32Array:
	var held := seconds_to_samples(length)
	var total := held + seconds_to_samples(v.release)
	var out := PackedFloat32Array()
	out.resize(total)
	# Envelope, precomputed as a level per sample (cheap branches, no per-sample math calls).
	var attack_s := maxf(v.attack * SAMPLE_RATE, 1.0)
	var decay_end := attack_s + maxf(v.decay * SAMPLE_RATE, 1.0)
	var release_s := maxf(v.release * SAMPLE_RATE, 1.0)
	var decay_drop := (1.0 - v.sustain) / (decay_end - attack_s)
	# Pitch: slide as a constant per-sample ratio; vibrato as a small linear wobble.
	var inc := freq / SAMPLE_RATE
	var slide_ratio := pow(2.0, v.slide / SEMITONES / maxf(total, 1)) if v.slide != 0.0 else 1.0
	var vib := pow(2.0, v.vibrato_depth / SEMITONES) - 1.0
	var vib_w := TAU * v.vibrato_rate / SAMPLE_RATE
	var vib_start := int(v.vibrato_delay * SAMPLE_RATE)
	var phase := 0.0
	var noise_value := 0.0
	var vol := v.volume
	var duty := v.duty
	var wave := v.wave
	for i in total:
		var level: float
		if i < attack_s:
			level = i / attack_s
		elif i < decay_end:
			level = 1.0 - (i - attack_s) * decay_drop
		elif i < held:
			level = v.sustain
		else:
			level = v.sustain * (1.0 - (i - held) / release_s)
			if level < 0.0:
				level = 0.0
		var step := inc
		if vib != 0.0 and i > vib_start:
			step *= 1.0 + vib * sin(vib_w * i)
		inc *= slide_ratio
		phase += step
		var wrapped := phase >= 1.0
		if wrapped:
			phase -= floorf(phase)
		var s: float
		if wave == Wave.PULSE:
			s = 1.0 if phase < duty else -1.0
		elif wave == Wave.TRIANGLE:
			s = 4.0 * absf(phase - 0.5) - 1.0
		elif wave == Wave.SINE:
			s = sin(TAU * phase)
		elif wave == Wave.SAW:
			s = 2.0 * phase - 1.0
		else:
			# Sample-and-hold noise: a new random value each cycle, so pitch = brightness.
			if wrapped or i == 0:
				noise_value = rng.randf_range(-1.0, 1.0) if rng else randf_range(-1.0, 1.0)
			s = noise_value
		out[i] = s * level * vol
	return out


## Soft-clips and packs a float buffer as a mono 16-bit AudioStreamWAV.
static func to_stream(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * BYTES_PER_SAMPLE)
	for i in buf.size():
		var x := buf[i]
		x = x / (1.0 + absf(x))
		bytes.encode_s16(i * BYTES_PER_SAMPLE, int(x * PCM16_MAX))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buf.size()
	return stream


static func make_buffer(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(seconds_to_samples(seconds))
	return buf
