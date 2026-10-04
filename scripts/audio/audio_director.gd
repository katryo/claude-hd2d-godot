extends Node
## "Audio" autoload. Plays sound effects and drives background music with a
## StateMachine whose states are musical situations:
##
##   silent, title, field, battle, boss      looping (field resumes where it left off)
##   victory, defeat, inn                    one-shot jingles that hand over when done:
##                                           victory/inn -> field, defeat -> silent
##
## Gameplay code only says what is happening (`set_music(&"battle")`); each state
## decides which track plays, how it fades in and what follows it. Tracks are rendered
## on worker threads when music is first requested, so nothing hitches during play (and
## headless tools that never play music never pay for it).

signal track_ready(id: String)

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MUSIC_VOLUME_DB := -4.0
const SFX_VOLUME_DB := -2.0
const REVERB_ROOM_SIZE := 0.55
const REVERB_WET := 0.18
const SFX_VOICES := 8
## Volume used for "silent" when fading players (linear amplitude).
const SILENT := 0.0
const FULL := 1.0
const DEFAULT_FADE := 0.8
const QUICK_FADE := 0.25
## Tweens need a non-zero duration.
const MIN_FADE := 0.01

var machine: StateMachine
var _streams := {}
var _sfx := {}
## Track id -> WorkerThreadPool task id.
var _tasks := {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _fade: Tween


## A musical situation: which track plays, how it starts, and what follows a jingle.
class MusicState extends State:
	var track := ""
	var fade := DEFAULT_FADE
	## Loops resume from where they were left (e.g. the field theme after a battle).
	var resume := false
	## For one-shot tracks: the state to enter when the jingle ends.
	var then := &""
	var _position := 0.0

	func _init(track_id: String, fade_time: float = DEFAULT_FADE, resume_play: bool = false,
			next_state: StringName = &"") -> void:
		track = track_id
		fade = fade_time
		resume = resume_play
		then = next_state

	func enter(_msg: Dictionary = {}) -> void:
		var audio = host
		var stream: AudioStreamWAV = await audio.stream_for(track)
		if not is_current():
			return
		audio.crossfade_to(stream, fade, _position if resume else 0.0)
		if not MusicLibrary.is_looping(track):
			await audio.get_tree().create_timer(stream.get_length()).timeout
			if is_current() and then != &"":
				transition_to(then)

	func exit() -> void:
		if resume:
			_position = host.music_position()


class SilentState extends State:
	func enter(msg: Dictionary = {}) -> void:
		host.fade_out(msg.get("fade", DEFAULT_FADE))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS
		p.volume_db = linear_to_db(SILENT)
		add_child(p)
		_players.append(p)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_players.append(p)
	machine = StateMachine.new(self)
	machine.add_state(&"silent", SilentState.new()) \
		.add_state(&"title", MusicState.new("title")) \
		.add_state(&"field", MusicState.new("field", DEFAULT_FADE, true)) \
		.add_state(&"battle", MusicState.new("battle", QUICK_FADE)) \
		.add_state(&"boss", MusicState.new("boss", QUICK_FADE)) \
		.add_state(&"victory", MusicState.new("victory", QUICK_FADE, false, &"field")) \
		.add_state(&"defeat", MusicState.new("defeat", QUICK_FADE, false, &"silent")) \
		.add_state(&"inn", MusicState.new("inn", QUICK_FADE, false, &"field"))
	machine.start(&"silent", {"fade": 0.0})
	for sfx_name in SfxLibrary.names():
		_sfx[sfx_name] = SfxLibrary.render(sfx_name)


func _exit_tree() -> void:
	for task in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(task)


func _process(delta: float) -> void:
	machine.update(delta)


# --------------------------------------------------------------------------
# Public API
# --------------------------------------------------------------------------

## Switches the music to a situation (a state name). Re-requesting the current one is a no-op.
func set_music(state: StringName) -> void:
	prewarm()
	if not machine.is_in(state):
		machine.transition_to(state)


func music_state() -> StringName:
	return machine.current_name


## Starts rendering every music track in the background (idempotent).
func prewarm() -> void:
	for id in MusicLibrary.track_ids():
		_request_render(id)


## True once every music track has finished rendering.
func is_ready() -> bool:
	return _streams.size() == MusicLibrary.track_ids().size()


## Plays a one-shot sound effect from SfxLibrary.
func play_sfx(sfx_name: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStreamWAV = _sfx.get(String(sfx_name))
	if stream == null:
		push_warning("Unknown sound effect: %s" % sfx_name)
		return
	var p := _free_sfx_player()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


# --------------------------------------------------------------------------
# Used by the music states
# --------------------------------------------------------------------------

## Returns the rendered track, waiting for its worker thread if necessary.
func stream_for(id: String) -> AudioStreamWAV:
	_request_render(id)
	while not _streams.has(id):
		await track_ready
	return _streams[id]


func crossfade_to(stream: AudioStreamWAV, fade: float, from_position: float = 0.0) -> void:
	var outgoing := _players[_active]
	_active = 1 - _active
	var incoming := _players[_active]
	incoming.stream = stream
	incoming.volume_db = linear_to_db(SILENT)
	incoming.play(from_position)
	_restart_fade()
	_fade.tween_method(_set_volume.bind(incoming), SILENT, FULL, maxf(fade, MIN_FADE))
	_fade.tween_method(_set_volume.bind(outgoing), db_to_linear(outgoing.volume_db), SILENT, maxf(fade, MIN_FADE))
	_fade.chain().tween_callback(outgoing.stop)


func fade_out(fade: float) -> void:
	_restart_fade()
	for p in _players:
		_fade.tween_method(_set_volume.bind(p), db_to_linear(p.volume_db), SILENT, maxf(fade, MIN_FADE))
	_fade.chain().tween_callback(func() -> void:
		for p in _players:
			p.stop())


func music_position() -> float:
	var p := _players[_active]
	return p.get_playback_position() if p.playing else 0.0


# --------------------------------------------------------------------------
# Internals
# --------------------------------------------------------------------------

func _request_render(id: String) -> void:
	if not _tasks.has(id):
		_tasks[id] = WorkerThreadPool.add_task(_render_track.bind(id), false, "music " + id)


func _render_track(id: String) -> void:
	var stream := MusicLibrary.render(id)
	_on_track_rendered.call_deferred(id, stream)


func _on_track_rendered(id: String, stream: AudioStreamWAV) -> void:
	_streams[id] = stream
	track_ready.emit(id)


func _restart_fade() -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel(true)


func _set_volume(linear: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(linear)


func _free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	return _sfx_players[_next_sfx]


func _setup_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	var music := AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_volume_db(music, MUSIC_VOLUME_DB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), SFX_VOLUME_DB)
	# A touch of room reverb gives the chiptunes an HD-2D "orchestral hall" sheen.
	var reverb := AudioEffectReverb.new()
	reverb.room_size = REVERB_ROOM_SIZE
	reverb.wet = REVERB_WET
	AudioServer.add_bus_effect(music, reverb)
