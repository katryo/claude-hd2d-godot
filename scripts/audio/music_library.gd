class_name MusicLibrary
extends RefCounted
## Original chiptune score for the game, written as data and rendered by Synth.
##
## Per track:
##   bpm, chords      one chord per bar ("F", "Dm", "Bb", "C#m", ...)
##   melody           space-separated "Note/eighths" tokens ("E5/2", "r/1" = rest)
##   bass             per-bar pattern, one char per step: R root, F fifth, O octave, - rest
##   arp              per-bar pattern of chord-tone indices (0 root, 1 third, 2 fifth, 3 octave)
##   drums            per-bar pattern: k kick, s snare, h hat, - rest
##   pad              sustain soft chord tones under each bar
##   loop             false for one-shot jingles (victory, defeat, inn)
## A pattern's length sets its step size (8 chars = eighths, 16 = sixteenths).

const EIGHTHS_PER_BAR := 8
## Extra seconds rendered after one-shot jingles so their last notes can ring out.
const JINGLE_TAIL := 1.2
## Note length as a fraction of its step for bass/arp (leaves a tiny gap = articulation).
const STEP_GATE := 0.85
## Held notes (a step followed by rests) are played nearly legato.
const HELD_GATE := 0.98
const BASS_OCTAVE := 2
const ARP_OCTAVE := 4
const PAD_OCTAVE := 4
## Chord tones by quality, in semitones above the root.
const MAJOR := [0, 4, 7, 12]
const MINOR := [0, 3, 7, 12]
const FIFTH := 7

const TRACKS := {
	"title": {
		"bpm": 76, "loop": true, "pad": true,
		"chords": ["Am", "F", "C", "G", "Am", "F", "Dm", "E"],
		"melody": "E5/4 A4/2 B4/2  C5/3 B4/1 A4/4  G4/2 C5/2 E5/4  D5/6 r/2 " +
			"E5/4 A5/2 G5/2  F5/3 E5/1 C5/4  D5/2 F5/2 A5/2 G5/2  B4/2 E5/2 G#5/4",
		"melody_voice": "bell", "bass": "R-------", "bass_voice": "soft_bass",
		"arp": "0123210-0123210-", "arp_voice": "harp", "drums": "",
	},
	"field": {
		"bpm": 104, "loop": true, "pad": false,
		"chords": ["F", "C", "Dm", "Bb", "F", "C", "Bb", "C"],
		"melody": "A4/2 C5/2 F5/3 E5/1  D5/2 C5/2 G4/4  A4/2 D5/2 F5/2 E5/1 D5/1  D5/3 C5/1 Bb4/2 A4/2 " +
			"A4/2 C5/2 F5/3 G5/1  A5/2 G5/2 E5/2 C5/2  D5/2 F5/2 E5/1 D5/1 C5/2  E5/2 G5/2 C5/4",
		"melody_voice": "lead", "bass": "R-F-R-F-", "bass_voice": "soft_bass",
		"arp": "0-1-2-1-", "arp_voice": "harp", "drums": "k-h-s-h-k-h-s-hh",
	},
	"battle": {
		"bpm": 152, "loop": true, "pad": false,
		"chords": ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Bb", "A"],
		"melody": "D5/1 D5/1 A4/1 D5/1 F5/2 E5/1 D5/1  C5/1 D5/1 r/1 A4/1 D5/2 F5/2  " +
			"G5/2 F5/1 E5/1 F5/2 D5/2  E5/2 C5/1 D5/1 E5/2 G5/2  A5/3 G5/1 F5/2 E5/2  " +
			"D5/1 E5/1 F5/1 G5/1 A5/4  Bb5/2 A5/1 G5/1 F5/2 G5/2  A5/2 E5/2 C#5/2 A4/2",
		"melody_voice": "lead", "bass": "RRORRORR", "bass_voice": "drive_bass",
		"arp": "0102010201020102", "arp_voice": "chip", "drums": "k-hsk-hskkhs-khs",
	},
	"boss": {
		"bpm": 138, "loop": true, "pad": true,
		"chords": ["Em", "Em", "C", "D", "Em", "Em", "C", "B"],
		"melody": "E5/2 r/1 E5/1 G5/2 F#5/2  E5/1 D5/1 B4/2 r/2 B4/2  C5/2 E5/2 G5/3 F#5/1  " +
			"F#5/2 E5/1 D5/1 A4/4  E5/1 F#5/1 G5/2 B5/2 A5/2  G5/1 F#5/1 E5/2 B4/4  " +
			"C6/2 B5/2 G5/2 E5/2  D#5/2 F#5/2 B5/4",
		"melody_voice": "boss_lead", "bass": "RORORORF", "bass_voice": "saw_bass",
		"arp": "0201020102010201", "arp_voice": "chip", "drums": "k-skk-s-k-skkss-",
	},
	"victory": {
		"bpm": 150, "loop": false, "pad": true,
		"chords": ["C", "F", "G", "C"],
		"melody": "G4/1 C5/1 E5/1 G5/3 E5/1 G5/1  A5/3 F5/1 A5/2 C6/2  B5/2 G5/2 D5/2 B4/2  C5/1 E5/1 G5/1 C6/5",
		"melody_voice": "lead", "bass": "R---F---", "bass_voice": "soft_bass",
		"arp": "", "arp_voice": "", "drums": "k---s---",
	},
	"defeat": {
		"bpm": 66, "loop": false, "pad": true,
		"chords": ["Am", "Dm", "E", "Am"],
		"melody": "E5/4 C5/4  F5/4 D5/4  B4/4 G#4/4  A4/8",
		"melody_voice": "bell", "bass": "R-------", "bass_voice": "soft_bass",
		"arp": "", "arp_voice": "", "drums": "",
	},
	"inn": {
		"bpm": 84, "loop": false, "pad": true,
		"chords": ["C", "F", "G", "C"],
		"melody": "E5/2 G5/2 C6/4  A5/2 F5/2 C5/4  D5/2 G5/2 B5/4  C6/8",
		"melody_voice": "bell", "bass": "R-------", "bass_voice": "soft_bass",
		"arp": "0-1-2-3-", "arp_voice": "harp", "drums": "",
	},
}

# Drum voices
const KICK_FREQ := 140.0
const KICK_LENGTH := 0.12
const KICK_SLIDE := -24.0
const KICK_VOLUME := 0.5
const SNARE_FREQ := 3200.0
const SNARE_LENGTH := 0.09
const SNARE_VOLUME := 0.16
const HAT_FREQ := 9000.0
const HAT_LENGTH := 0.025
const HAT_VOLUME := 0.06
const PAD_VOLUME := 0.045
const DRUM_SEED := 7
## Pads sustain the root, third and fifth.
const PAD_TONES := 3


## Mixes notes into a track buffer, synthesizing each distinct note only once.
class NoteCache:
	var buf: PackedFloat32Array
	var loop: bool
	var rng: RandomNumberGenerator
	var _notes := {}
	var _voices := {}

	func _init(p_buf: PackedFloat32Array, p_loop: bool, p_rng: RandomNumberGenerator) -> void:
		buf = p_buf
		loop = p_loop
		rng = p_rng

	## Plays a pitched note (MIDI number) on a named voice.
	func play(voice_name: String, midi: int, at: float, length: float) -> void:
		play_freq(voice_name, Synth.midi_to_freq(midi), at, length)

	func play_freq(voice_name: String, freq: float, at: float, length: float) -> void:
		var key := "%s|%.2f|%d" % [voice_name, freq, Synth.seconds_to_samples(length)]
		if not _notes.has(key):
			if not _voices.has(voice_name):
				_voices[voice_name] = MusicLibrary.voice(voice_name)
			_notes[key] = Synth.render_note(freq, length, _voices[voice_name], rng)
		Synth.mix(buf, Synth.seconds_to_samples(at), _notes[key], loop)


static func track_ids() -> Array:
	return TRACKS.keys()


static func is_looping(id: String) -> bool:
	return TRACKS[id].loop


## Renders a track to an AudioStreamWAV (loops are seamless). Safe to call from a thread.
static func render(id: String) -> AudioStreamWAV:
	var t: Dictionary = TRACKS[id]
	var eighth: float = 60.0 / float(t.bpm) / 2.0
	var bar_len: float = eighth * EIGHTHS_PER_BAR
	var chords: Array = t.chords
	var loop: bool = t.loop
	var length: float = bar_len * chords.size() + (0.0 if loop else JINGLE_TAIL)
	var buf := Synth.make_buffer(length)
	var rng := RandomNumberGenerator.new()
	rng.seed = DRUM_SEED
	# Identical notes (same voice, pitch and length) are synthesized once per track.
	var cache := NoteCache.new(buf, loop, rng)
	_render_melody(cache, t.melody, eighth, t.melody_voice)
	for bar in chords.size():
		var start: float = bar * bar_len
		var tones := chord_tones(chords[bar])
		_render_pattern(cache, t.bass, start, bar_len, tones, BASS_OCTAVE, t.bass_voice, true)
		if t.arp != "":
			_render_pattern(cache, t.arp, start, bar_len, tones, ARP_OCTAVE, t.arp_voice, false)
		if t.pad:
			for i in PAD_TONES:
				var midi: int = tones[i] + (PAD_OCTAVE + 1) * 12
				cache.play("pad", midi, start, bar_len)
		if t.drums != "":
			_render_drums(cache, t.drums, start, bar_len)
	return Synth.to_stream(buf, loop)


## Returns MIDI numbers (octave 0 based) for a chord name: root, third, fifth, octave.
static func chord_tones(chord: String) -> Array:
	var minor := chord.length() > 1 and chord.ends_with("m")
	var root_name := chord.trim_suffix("m") if minor else chord
	var root := Synth.note_to_midi(root_name + "-1")
	var out := []
	for interval in (MINOR if minor else MAJOR):
		out.append(root + interval)
	return out


static func voice(voice_name: String) -> Synth.Voice:
	var v: Synth.Voice
	match voice_name:
		"lead":
			v = Synth.Voice.new(Synth.Wave.PULSE, 0.16).with_env(0.01, 0.12, 0.65, 0.08)
			v.duty = 0.25
			v.vibrato_depth = 0.25
		"boss_lead":
			v = Synth.Voice.new(Synth.Wave.PULSE, 0.17).with_env(0.005, 0.1, 0.7, 0.06)
			v.duty = 0.5
			v.vibrato_depth = 0.3
		"bell":
			v = Synth.Voice.new(Synth.Wave.TRIANGLE, 0.3).with_env(0.005, 0.4, 0.35, 0.4)
			v.vibrato_depth = 0.15
		"harp":
			v = Synth.Voice.new(Synth.Wave.TRIANGLE, 0.13).with_env(0.003, 0.15, 0.2, 0.15)
		"chip":
			v = Synth.Voice.new(Synth.Wave.PULSE, 0.06).with_env(0.002, 0.05, 0.4, 0.03)
			v.duty = 0.125
		"soft_bass":
			v = Synth.Voice.new(Synth.Wave.TRIANGLE, 0.32).with_env(0.005, 0.2, 0.6, 0.08)
		"drive_bass":
			v = Synth.Voice.new(Synth.Wave.TRIANGLE, 0.34).with_env(0.003, 0.08, 0.7, 0.03)
		"saw_bass":
			v = Synth.Voice.new(Synth.Wave.SAW, 0.16).with_env(0.003, 0.1, 0.6, 0.04)
		"pad":
			v = Synth.Voice.new(Synth.Wave.SINE, PAD_VOLUME).with_env(0.3, 0.5, 0.8, 0.5)
		"kick":
			v = Synth.Voice.new(Synth.Wave.SINE, KICK_VOLUME).with_env(0.001, KICK_LENGTH, 0.0, 0.01)
			v.slide = KICK_SLIDE
		"snare":
			v = Synth.Voice.new(Synth.Wave.NOISE, SNARE_VOLUME).with_env(0.001, SNARE_LENGTH, 0.0, 0.01)
		"hat":
			v = Synth.Voice.new(Synth.Wave.NOISE, HAT_VOLUME).with_env(0.001, HAT_LENGTH, 0.0, 0.005)
		_:
			v = Synth.Voice.new()
	return v


static func _render_melody(cache: NoteCache, melody: String, eighth: float, voice_name: String) -> void:
	var t := 0.0
	for token in melody.split(" ", false):
		var parts := token.split("/")
		var dur := float(parts[1]) * eighth
		if parts[0] != "r":
			cache.play(voice_name, Synth.note_to_midi(parts[0]), t, dur * STEP_GATE)
		t += dur


static func _render_pattern(cache: NoteCache, pattern: String, start: float, bar_len: float, tones: Array,
		octave: int, voice_name: String, is_bass: bool) -> void:
	if pattern == "":
		return
	var step := bar_len / pattern.length()
	for i in pattern.length():
		var c := pattern[i]
		if c == "-":
			continue
		var midi: int
		if is_bass:
			match c:
				"F": midi = tones[0] + FIFTH
				"O": midi = tones[0] + 12
				_: midi = tones[0]
		else:
			midi = tones[int(c)]
		# Hold bass notes through following rests.
		var steps := 1
		while is_bass and i + steps < pattern.length() and pattern[i + steps] == "-":
			steps += 1
		var gate := HELD_GATE if steps > 1 else STEP_GATE
		cache.play(voice_name, midi + (octave + 1) * 12, start + i * step, step * steps * gate)


static func _render_drums(cache: NoteCache, pattern: String, start: float, bar_len: float) -> void:
	var step := bar_len / pattern.length()
	for i in pattern.length():
		var at := start + i * step
		match pattern[i]:
			"k": cache.play_freq("kick", KICK_FREQ, at, KICK_LENGTH)
			"s": cache.play_freq("snare", SNARE_FREQ, at, SNARE_LENGTH)
			"h": cache.play_freq("hat", HAT_FREQ, at, HAT_LENGTH)
