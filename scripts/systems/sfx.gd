extends Node
## Plays the sound effects from res://assets/audio/ (tools/gen_sfx.gd makes
## them, every file leveled to the same loudness).
##
## Replace any .wav there (same name) to swap a sound. Missing files are skipped,
## so the game remains fully playable without audio assets.

## Every sound started (the tests listen for footsteps and pickups).
signal played(sfx_name: String)

const AUDIO_DIR := "res://assets/audio/"
const POOL_SIZE := 16
## The files are level-matched, so the volume offsets callers pass (a soft
## footstep, a quiet tick) are only nudges: half their size in dB.
const CALL_SCALE := 0.5

## The last sound started and its volume (the tests read them).
var last_played := ""
var last_db := 0.0
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## Sounds generated much hotter than the rest, trimmed (dB) wherever they play
## (Beta 1.7.0 mix pass: their loudest 50 ms sat 8-10 dB over the median sound,
## _giggle64_work/tools/sfx_levels.py). Low rumbles are left alone: their
## loudness is mostly bass, which RMS overstates.
const TRIM := {"fire_whoosh": -6.0, "stone_grip": -6.0, "switch_press": -5.0}


func play(sfx_name: String, volume_db := 0.0, pitch_jitter := 0.05, pitch := 1.0) -> void:
	_start(sfx_name, volume_db * CALL_SCALE + float(TRIM.get(sfx_name, 0.0)), pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter)), bus_for(sfx_name))


## A footstep or landing at exactly `volume_db` (no halving: footsteps are
## quiet on purpose, and their loudness carries the hero's pace), on the
## Footsteps bus.
func play_step(sfx_name: String, volume_db: float, pitch := 1.0) -> void:
	_start(sfx_name, volume_db, pitch, "Footsteps")


## Which bus play() uses (AudioMix): the hero's ladder rungs on Footsteps,
## the text box sounds on Text, everything else on SFX (the hero's footsteps
## come through play_step).
static func bus_for(sfx_name: String) -> String:
	if sfx_name == "ladder_step":
		return "Footsteps"
	if sfx_name.begins_with("msg_"):
		return "Text"
	return "SFX"


func _start(sfx_name: String, db: float, pitch_scale: float, bus: String) -> void:
	var stream := _stream(sfx_name)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	p.pitch_scale = pitch_scale
	p.play()
	last_played = sfx_name
	last_db = db
	played.emit(sfx_name)


func _stream(sfx_name: String) -> AudioStream:
	if not _streams.has(sfx_name):
		var path := AUDIO_DIR + sfx_name + ".wav"
		_streams[sfx_name] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sfx_name]
