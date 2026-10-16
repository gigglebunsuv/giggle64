extends Node
## The weather (Beta 1.1.0). Haven sees rain now and then: at each dawn the
## day is rolled (RAIN_CHANCE), and on a rainy day the open country gets rain
## streaks round the hero, a rain ambience over the area's own, a greyer,
## darker light (DayNight multiplies in `dim()`), and wet footsteps on soft
## ground. The Batela Fells have their own weather, always: ash falling out of
## a dead sky (the area's "ash" particles, built with it).
##
## The day's roll is kept in Progress ("weather:rain"), so it saves.

const RAIN_FLAG := "weather:rain"
const RAIN_CHANCE := 0.22
## Where it can rain (the open country of Haven).
const RAIN_AREAS := ["field", "field_war", "village", "village_refuge", "castle_town", "castle_town_rebuilt", "dark_forest", "forest", "marsh", "southern_fields", "south_road", "lake", "cliffs"]
## How dark and gray a rainy day is (multiplied into the area's light).
const RAIN_TINT := Color(0.66, 0.7, 0.78)
const RAIN_DB := -12.0

## 0..1, eased in and out as the hero comes and goes, or the rain starts.
var amount := 0.0
var _rain: CPUParticles3D = null
var _amb: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_amb = AudioStreamPlayer.new()
	_amb.name = "RainAmbience"
	_amb.bus = "Ambience"
	add_child(_amb)
	var path := Sfx.AUDIO_DIR + "amb_rain.wav"
	if ResourceLoader.exists(path):
		var st: AudioStreamWAV = load(path)
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		_amb.stream = st
	DayNight.night_changed.connect(_on_night_changed)


## A new day (dawn): rain or not.
func _on_night_changed(is_night: bool) -> void:
	# (Not in automation: tests and captures keep a dry, steady light.)
	if not is_night and GameManager.state == GameManager.GameState.PLAYING and not GameManager.automation:
		roll()


func roll(chance := RAIN_CHANCE) -> void:
	Progress.set_flag(RAIN_FLAG, randf() < chance)


func raining() -> bool:
	return Progress.flag(RAIN_FLAG)


## Whether rain falls where the hero is now.
func rains_here() -> bool:
	return raining() and World.area_id in RAIN_AREAS and GameManager.state != GameManager.GameState.TITLE


## The light multiplier for DayNight: white on a dry day, greyer in the rain.
func dim() -> Color:
	return Color.WHITE.lerp(RAIN_TINT, amount)


## Soft ground squelches in the rain.
func wet_ground(surface: String) -> bool:
	return amount > 0.5 and surface in ["grass", "dirt", "sand", "mud"]


func _process(delta: float) -> void:
	var want := 1.0 if rains_here() and not World.transitioning else 0.0
	amount = move_toward(amount, want, delta * 0.4)
	_update_rain()
	_update_sound(delta)


func _update_rain() -> void:
	var p := GameManager.player
	if amount <= 0.01 or not is_instance_valid(p) or not is_instance_valid(World.area_node):
		if is_instance_valid(_rain):
			_rain.emitting = false
		return
	if not is_instance_valid(_rain) or _rain.get_parent() != World.area_node:
		_rain = _make_rain()
		World.area_node.add_child(_rain)
	_rain.emitting = true
	_rain.color = Color(0.75, 0.8, 0.9, 0.55 * amount)
	_rain.global_position = p.global_position + Vector3(0, 9.0, 0) + p.velocity * 0.4


func _update_sound(delta: float) -> void:
	if _amb.stream == null:
		return
	var want := lerpf(-60.0, RAIN_DB, amount)
	if want <= -59.0:
		if _amb.playing:
			_amb.stop()
		return
	if not _amb.playing:
		_amb.volume_db = -60.0
		_amb.play()
	_amb.volume_db = move_toward(_amb.volume_db, want, delta * 20.0)


## Rain: thin pale streaks falling fast round the hero.
func _make_rain() -> CPUParticles3D:
	var r := CPUParticles3D.new()
	r.name = "Rain"
	r.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	r.mesh = quad
	r.amount = 700
	r.lifetime = 0.9
	r.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	r.emission_box_extents = Vector3(16, 0.5, 16)
	r.direction = Vector3(0.12, -1, 0.05)
	r.spread = 4.0
	r.gravity = Vector3(0, -9.0, 0)
	r.initial_velocity_min = 11.0
	r.initial_velocity_max = 14.0
	r.color = Color(0.75, 0.8, 0.9, 0.55)
	return r
