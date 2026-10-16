extends Node
## The mixer: the audio buses every sound plays through, their volumes from the
## OPTIONS > SOUND page, and the mix moves made during play.
##
## Buses (made here at start-up, so no bus layout file is needed):
## - Master
##   - Music      area tracks, cutscene scores, the title theme
##   - Ambience   area loops and the night layer
##   - SFX        everything else from Sfx
##     - Footsteps  steps, landings, ladder rungs (Sfx routes "step_*" here)
##     - Text       the text box sounds (msg_*)
##
## Mix moves:
## - pause muffle: while the pause screen is up, music and ambience go through
##   a low-pass, as if heard from the next room (some N64 games did this);
## - dialogue duck: music drops DUCK_DB while a text box is open.

const MUSIC := "Music"
const AMBIENCE := "Ambience"
const SFX := "SFX"
const FOOTSTEPS := "Footsteps"
const TEXT := "Text"
## The SOUND page's sliders, in order: [setting key, bus, label].
const SLIDERS := [
	["master", "Master", "MASTER"],
	["music", MUSIC, "MUSIC"],
	["sfx", SFX, "SOUND FX"],
	["footsteps", FOOTSTEPS, "FOOTSTEPS"],
	["ambience", AMBIENCE, "AMBIENCE"],
	["text", TEXT, "TEXT SOUNDS"],
]
const STEPS := 10
## Music under an open text box.
const DUCK_DB := -6.0
## Low-pass cutoffs (Hz): open and paused.
const OPEN_HZ := 20000.0
const PAUSE_HZ := 650.0

## The music bus's duck, in dB (0 = none): eased toward its target each frame.
var duck := 0.0
## The music's low-pass cutoff now (eased) and the ambience's.
var music_hz := OPEN_HZ
var ambience_hz := OPEN_HZ


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	apply_volumes()
	GameManager.settings_changed.connect(apply_volumes)


## Makes the buses (and their effects) if the project has none yet.
static func ensure_buses() -> void:
	_bus(MUSIC, "Master", [AudioEffectLowPassFilter.new()])
	_bus(AMBIENCE, "Master", [AudioEffectLowPassFilter.new()])
	_bus(SFX, "Master", [])
	_bus(FOOTSTEPS, SFX, [])
	_bus(TEXT, SFX, [])
	# Mono output: the stereo spread pulled in to nothing.
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var mono := AudioEffectStereoEnhance.new()
		mono.pan_pullout = 0.0
		AudioServer.add_bus_effect(master, mono)
		AudioServer.set_bus_effect_enabled(master, 0, false)


static func _bus(bus_name: String, send: String, effects: Array) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, send)
	for e: AudioEffect in effects:
		if e is AudioEffectLowPassFilter:
			(e as AudioEffectLowPassFilter).cutoff_hz = OPEN_HZ
		AudioServer.add_bus_effect(i, e)


## A slider step (0..STEPS) as decibels: an even loudness curve, 0 = silent.
static func step_db(step: int) -> float:
	if step <= 0:
		return -80.0
	return linear_to_db(pow(float(step) / STEPS, 2.0))


## Sets every bus from GameManager's sound settings.
func apply_volumes() -> void:
	for s in SLIDERS:
		var i := AudioServer.get_bus_index(s[1])
		if i < 0:
			continue
		var step: int = GameManager.volume(s[0])
		AudioServer.set_bus_mute(i, step <= 0)
		AudioServer.set_bus_volume_db(i, step_db(step) + (duck if s[1] == MUSIC else 0.0))
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) > 0:
		AudioServer.set_bus_effect_enabled(master, 0, GameManager.mono_audio)


func _process(delta: float) -> void:
	var paused := GameManager.state == GameManager.GameState.PAUSED and GameManager.pause_muffle
	var duck_to := DUCK_DB if Dialogue.active and GameManager.state == GameManager.GameState.PLAYING else 0.0
	var k := 1.0 - exp(-delta * 6.0)
	var new_duck := lerpf(duck, duck_to, k)
	if absf(new_duck - duck) > 0.01:
		duck = new_duck
		var mi := AudioServer.get_bus_index(MUSIC)
		AudioServer.set_bus_volume_db(mi, step_db(GameManager.volume("music")) + duck)
	var music_to := PAUSE_HZ if paused else OPEN_HZ
	var amb_to := PAUSE_HZ if paused else OPEN_HZ
	music_hz = _ease_hz(music_hz, music_to, delta)
	ambience_hz = _ease_hz(ambience_hz, amb_to, delta)
	_set_lowpass(MUSIC, music_hz)
	_set_lowpass(AMBIENCE, ambience_hz)


## Eases a cutoff in octaves (so the sweep sounds even), fast enough to follow
## the pause screen swinging in.
static func _ease_hz(hz: float, to: float, delta: float) -> float:
	var a := log(hz) / log(2.0)
	var b := log(to) / log(2.0)
	return pow(2.0, move_toward(a, b, delta * 14.0))


static func _set_lowpass(bus_name: String, hz: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i < 0 or AudioServer.get_bus_effect_count(i) == 0:
		return
	var f := AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter
	if f == null:
		return
	var on := hz < OPEN_HZ * 0.95
	AudioServer.set_bus_effect_enabled(i, 0, on)
	if on:
		f.cutoff_hz = hz
