extends SceneTree
## Audio tests: renders every music track and sound effect, checks their levels, and
## walks the music state machine through its transitions.
## Run: godot --headless --path . --fixed-fps 60 -s tests/audio_test.gd

## Rendered audio must be audible but never pinned at full scale.
const MIN_PEAK := 0.05
const MAX_PEAK := 0.98
const MIN_TRACK_SECONDS := 4.0
const MAX_SFX_SECONDS := 1.0
const BYTES_PER_SAMPLE := 2
const PCM16_MAX := 32767.0
## Safety cap while waiting for jingles to finish (frames).
const WAIT_FRAMES := 2000
## Safety cap while waiting for the background renders (milliseconds of real time).
const RENDER_TIMEOUT_MS := 60000

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _peak(stream: AudioStreamWAV) -> float:
	var data := stream.data
	var peak := 0
	for i in range(0, data.size(), BYTES_PER_SAMPLE):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return peak / PCM16_MAX


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	for id in MusicLibrary.track_ids():
		var stream := MusicLibrary.render(id)
		var peak := _peak(stream)
		var looping := stream.loop_mode == AudioStreamWAV.LOOP_FORWARD
		_check(stream.get_length() >= MIN_TRACK_SECONDS and peak > MIN_PEAK and peak < MAX_PEAK,
			"track '%s': %.1fs, peak %.2f" % [id, stream.get_length(), peak])
		_check(looping == MusicLibrary.is_looping(id), "track '%s' loop mode matches its score" % id)
	print("    (rendered all tracks in %d ms)" % (Time.get_ticks_msec() - t0))
	for sfx in SfxLibrary.names():
		var stream := SfxLibrary.render(sfx)
		var peak := _peak(stream)
		_check(stream.get_length() < MAX_SFX_SECONDS and peak > MIN_PEAK and peak < MAX_PEAK,
			"sfx '%s': %.2fs, peak %.2f" % [sfx, stream.get_length(), peak])

	var audio: Node = root.get_node("Audio")
	audio.prewarm()
	var wait_start := Time.get_ticks_msec()
	while not audio.is_ready() and Time.get_ticks_msec() - wait_start < RENDER_TIMEOUT_MS:
		await process_frame
	_check(audio.is_ready(), "background rendering finished")
	_check(audio.music_state() == &"silent", "music starts silent")
	audio.set_music(&"battle")
	_check(audio.music_state() == &"battle", "battle music state")
	audio.set_music(&"victory")
	await _wait_for_state(audio, &"field")
	_check(audio.music_state() == &"field", "victory fanfare hands over to the field theme")
	audio.set_music(&"inn")
	await _wait_for_state(audio, &"field")
	_check(audio.music_state() == &"field", "inn jingle returns to the field theme")
	audio.set_music(&"defeat")
	await _wait_for_state(audio, &"silent")
	_check(audio.music_state() == &"silent", "defeat jingle ends in silence")
	audio.play_sfx(&"hit")
	audio.play_sfx(&"nonexistent_sound")
	_check(true, "playing sounds (including an unknown one) does not crash")

	print("AUDIO TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _wait_for_state(audio: Node, state: StringName) -> void:
	for i in WAIT_FRAMES:
		if audio.music_state() == state:
			return
		await process_frame
