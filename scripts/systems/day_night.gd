extends Node
## Time of day, after OoT's day/night (gSaveContext.dayTime, z_kankyo.c):
## - The clock runs only in the open air (fields, towns, the lake), never in
##   houses or dungeons, and not while the game is paused or a scene plays.
##   A day takes DAY_SECONDS of play; the night hours go by faster, as in OoT.
## - Each open-air area keeps the light it was built with as its noon, and is
##   carried from there toward dusk, night and dawn (Environment_Update
##   blending its light settings): the sky dome and its distant hills darken,
##   the fog and ambient turn blue, the sun becomes a dim cool moonlight, and
##   stars and a moon come out.
## - The night layer (amb_night: crickets and an owl) rises under the area's
##   own ambience. A rooster crows at dawn in the village and on the farm, and
##   a far howl marks nightfall out in the fields.
## - Out in the open there is no music at night, only the ambience and the
##   night layer; the area's music fades out at dusk and back in at dawn.
## - Shops keep hours (SHOP_HOURS): their doors are shut at night. Some people
##   go home after dark (AWAY_AT_NIGHT).
## - Out in the fields, Stalfos claw their way up out of the ground at night
##   (OoT's Stalchildren) and sink away again at dawn.
## - Fairies drift over a few flower patches after dark (FAIRY_SPOTS).
## - Progress.flag("time:night") / ("time:day") read the clock, so a chest
##   can appear only at night (the moonlit chest at Mirror Lake).

signal hour_changed(hour: int)
signal night_changed(is_night: bool)

## Real seconds in one full day (the night half goes by NIGHT_SPEED times faster).
const DAY_SECONDS := 1080.0
const NIGHT_SPEED := 1.6
## The hours the day begins and ends (night is DUSK..DAWN).
const DAWN := 6.0
const DUSK := 18.0
## A new game starts mid-morning.
const START_HOUR := 9.0
## Night colors the area's light is carried toward.
const NIGHT_AMBIENT := Color(0.17, 0.2, 0.36)
const NIGHT_FOG := Color(0.05, 0.07, 0.15)
const MOON_LIGHT := Color(0.58, 0.66, 1.0)
const NIGHT_SKY := Color(0.1, 0.12, 0.27)
const DUSK_TINT := Color(1.0, 0.74, 0.58)
const DAWN_TINT := Color(1.0, 0.82, 0.8)
## The sky dome's radius (WorldKit.SKY_RADIUS).
const SKY_RADIUS := 240.0
## Areas whose light never changes (the burning town keeps its red sky).
const FIXED := ["castle_town_fallen", "test_area"]
## Doors shut outside their opening hours: target area -> [open, close, notice].
const SHOP_HOURS := {
	"shop": [6.0, 21.0, "A sign hangs on the door:\n*CLOSED*\n\"Open from 6 in the morning till 9 at night. -Marigold\""],
	"library": [7.0, 21.0, "The library is shut for the night.\nA little brass plate reads: \"Open 7 to 9. Quiet, please.\""],
}
## People who go home after dark: area -> node names.
const AWAY_AT_NIGHT := {"southern_fields": ["Clover"]}
## Where the dead rise at night, and which creature (OoT's Stalchildren).
const NIGHT_SPAWNS := {"field": "stalfos", "field_war": "stalfos", "south_road": "stalfos", "southern_fields": "stalfos"}
const NIGHT_MAX := 3
## After the fall ("castle_fallen") the Sapphire Order camps out on the open
## country at night: a blue fire, a mage and two goblin sentries at each spot
## (the Shade Cloak lets the hero slip past them). Gone by morning.
const NIGHT_CAMPS := {
	"field": [Vector2(-28, -46), Vector2(46, 56), Vector2(-58, 62)],
	"south_road": [Vector2(10, -4)],
}
## Fairies over the flowers after dark: area -> spots (x, z).
const FAIRY_SPOTS := {
	"field": [Vector2(-41, 43)],
	"field_war": [Vector2(-41, 43)],
	"village": [Vector2(-25, 25.5), Vector2(-35, 25.5)],
	"village_refuge": [Vector2(-25, 25.5), Vector2(-35, 25.5)],
	"hidden_forest": [Vector2(14, 18)],
	"lake": [Vector2(-26, -21)],
	"southern_fields": [Vector2(-37, -9)],
}

## The music that dawn and dusk bring in, and the cries that go with them.
var _was_night := false
var _last_hour := -1
## The area being lit now and its noon light.
var _rigged: Node3D = null
var _base := {}
var _stars: MeshInstance3D = null
var _moon: MeshInstance3D = null
var _night_amb: AudioStreamPlayer
var _spawn_t := 0.0
var _spawned: Array[Node3D] = []
var _fairies: Array[Node3D] = []
var _camps: Array[Node3D] = []
## The clock stands still (debug).
var frozen := false
## A rest under way (DayNight.rest).
var resting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_night_amb = AudioStreamPlayer.new()
	_night_amb.name = "NightAmbience"
	_night_amb.bus = "Ambience"
	add_child(_night_amb)
	var path := Sfx.AUDIO_DIR + "amb_night.wav"
	if ResourceLoader.exists(path):
		var st: AudioStreamWAV = load(path)
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		_night_amb.stream = st


# --- The clock --------------------------------------------------------------------

## The hour now, 0..24.
func hour() -> float:
	return Progress.day_time


func set_hour(h: float) -> void:
	Progress.day_time = fposmod(h, 24.0)
	_check_changes(false)


static func is_night_at(h: float) -> bool:
	return h >= DUSK or h < DAWN


func is_night() -> bool:
	return is_night_at(hour())


## Progress.flag's "time:" flags: "time:night", "time:day".
func flag(f: String) -> bool:
	match f:
		"time:night": return is_night()
		"time:day": return not is_night()
	return false


## "6:30 AM" style.
static func clock_text(h: float) -> String:
	var hh := int(floor(h)) % 24
	var mm := int(floor((h - floor(h)) * 60.0 / 10.0)) * 10
	var ampm := "AM" if hh < 12 else "PM"
	var h12 := hh % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, mm, ampm]


## Open air: not a house, not a dungeon.
static func is_open_air(area: String) -> bool:
	return WorldData.known(area) and not WorldData.is_interior(area) and WorldData.dungeon(area) == "" and not area in FIXED


## A shop door's closed state now ("" = open, else the notice on it).
func door_notice(target_area: String) -> String:
	if not SHOP_HOURS.has(target_area):
		return ""
	var hrs: Array = SHOP_HOURS[target_area]
	var h := hour()
	return "" if h >= float(hrs[0]) and h < float(hrs[1]) else String(hrs[2])


## How far into night the hour is (0 = full day, 1 = full night), and how
## much dusk or dawn colors the light (0..1).
static func night_amount(h: float) -> float:
	if h >= 7.0 and h <= 17.0:
		return 0.0
	if h > 17.0 and h < 19.5:
		var k := (h - 17.0) / 2.5
		return k * k * (3.0 - 2.0 * k)
	if h >= 4.5 and h < 7.0:
		var k2 := 1.0 - (h - 4.5) / 2.5
		return k2 * k2 * (3.0 - 2.0 * k2)
	return 1.0


static func dusk_amount(h: float) -> float:
	return maxf(0.0, 1.0 - absf(h - 18.0) / 1.4)


static func dawn_amount(h: float) -> float:
	return maxf(0.0, 1.0 - absf(h - 5.8) / 1.1)


func _clock_runs() -> bool:
	return not frozen and not resting and GameManager.state == GameManager.GameState.PLAYING \
		and not World.transitioning and not Cutscene.active and not Dialogue.active \
		and is_open_air(World.area_id)


func _process(delta: float) -> void:
	if _clock_runs():
		var rate := 24.0 / DAY_SECONDS * (NIGHT_SPEED if is_night() else 1.0)
		Progress.day_time = fposmod(Progress.day_time + delta * rate, 24.0)
		_check_changes(true)
	if GameManager.state == GameManager.GameState.TITLE or not is_instance_valid(World.area_node):
		_night_amb.stop()
		return
	if World.area_node != _rigged:
		_rig(World.area_node)
	var open := is_open_air(World.area_id)
	_update_night_ambience(open, delta)
	if not open or Cutscene.active:
		return
	_apply_light()
	_update_spawns(delta)


## Hour and night/day edges: the cries at dawn and nightfall, the night
## music, the shop doors, and the creatures of the night.
func _check_changes(live: bool) -> void:
	var hr := int(floor(hour()))
	if hr != _last_hour:
		if live and _last_hour >= 0:
			if hr == int(DAWN) and World.area_id in ["village", "village_refuge", "southern_fields"]:
				Sfx.play("rooster", -6.0, 0.02)
			if hr == int(DUSK) + 1 and World.area_id in ["field", "field_war", "south_road", "southern_fields", "cliffs"]:
				Sfx.play("night_howl", -8.0, 0.02)
		_last_hour = hr
		hour_changed.emit(hr)
	var n := is_night()
	if n != _was_night:
		_was_night = n
		night_changed.emit(n)
		Progress.changed.emit()
		if is_instance_valid(World.area_node):
			_apply_people(World.area_node)
			_apply_fairies(World.area_node)
			_apply_camps(World.area_node)
			if not n:
				_dawn_sink()
		World.refresh_music()


# --- Lighting the area -------------------------------------------------------------

## Takes the area's built light as its noon and adds the stars and the moon.
func _rig(area: Node3D) -> void:
	_rigged = area
	_base.clear()
	_stars = null
	_moon = null
	_spawned.clear()
	_fairies.clear()
	_camps.clear()
	_was_night = is_night()
	_last_hour = int(floor(hour()))
	_apply_people(area)
	if not is_open_air(World.area_id):
		return
	for n in area.find_children("*", "WorldEnvironment", true, false):
		var we := n as WorldEnvironment
		if we.environment:
			# Its own copy: the scene's Environment is shared with the next load.
			we.environment = we.environment.duplicate()
			var env := we.environment
			_base["env"] = env
			_base["ambient"] = env.ambient_light_color
			_base["fog"] = env.fog_light_color
			_base["bg"] = env.background_color
			_base["fog_end"] = env.fog_depth_end
		break
	var sun := area.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		_base["sun"] = sun
		_base["sun_col"] = sun.light_color
		_base["sun_energy"] = sun.light_energy
	var fill := area.get_node_or_null("FillLight") as DirectionalLight3D
	if fill:
		_base["fill"] = fill
		_base["fill_energy"] = fill.light_energy
	var sky := area.get_node_or_null("SkyDome") as Node3D
	if sky:
		_base["sky_mats"] = []
		for part in ["Dome", "Horizon"]:
			var mi := sky.get_node_or_null(part) as MeshInstance3D
			if mi and mi.mesh and mi.mesh.get_surface_count() > 0:
				var m := mi.mesh.surface_get_material(0)
				if m is StandardMaterial3D:
					var copy := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
					mi.material_override = copy
					(_base["sky_mats"] as Array).append([copy, copy.albedo_color])
		_stars = _make_stars()
		sky.add_child(_stars)
		_moon = _make_moon(sun)
		sky.add_child(_moon)
	_apply_light()
	_apply_fairies(area)
	_apply_camps(area)


func _apply_light() -> void:
	if _base.is_empty():
		return
	var h := hour()
	var n := night_amount(h)
	var warm := DUSK_TINT.lerp(Color.WHITE, 1.0 - dusk_amount(h))
	warm = warm * DAWN_TINT.lerp(Color.WHITE, 1.0 - dawn_amount(h))
	# A rainy day is greyer and darker (Weather).
	warm = warm * Weather.dim()
	var env: Environment = _base.get("env")
	if env:
		env.ambient_light_color = (_base.ambient as Color).lerp(NIGHT_AMBIENT, n * 0.85) * warm.lerp(Color.WHITE, 0.4)
		var fog := (_base.fog as Color).lerp(NIGHT_FOG, n) * warm
		env.fog_light_color = fog
		env.background_color = (_base.bg as Color).lerp(NIGHT_FOG, n) * warm
		env.fog_depth_end = lerpf(_base.fog_end, _base.fog_end * 0.8, n)
	var sun := _base.get("sun") as DirectionalLight3D
	if is_instance_valid(sun):
		sun.light_color = (_base.sun_col as Color).lerp(MOON_LIGHT, n) * warm
		sun.light_energy = lerpf(_base.sun_energy, _base.sun_energy * 0.35, n) * lerpf(1.0, 0.55, Weather.amount)
	var fill := _base.get("fill") as DirectionalLight3D
	if is_instance_valid(fill):
		fill.light_energy = lerpf(_base.fill_energy, _base.fill_energy * 0.55, n)
	for pair in _base.get("sky_mats", []):
		var mat: StandardMaterial3D = pair[0]
		mat.albedo_color = (pair[1] as Color) * Color.WHITE.lerp(NIGHT_SKY, n) * warm
	var star_k := clampf((n - 0.45) / 0.55, 0.0, 1.0)
	if is_instance_valid(_stars):
		_stars.visible = star_k > 0.0
		(_stars.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, star_k)
	if is_instance_valid(_moon):
		_moon.visible = n > 0.05
		(_moon.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, clampf(n * 1.4, 0.0, 1.0))


## A scatter of stars over the upper dome (small quads facing its center).
func _make_stars() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2424
	var r := SKY_RADIUS * 0.96
	for i in 260:
		var yaw := rng.randf() * TAU
		var elev := asin(rng.randf_range(0.12, 1.0))
		var dir := Vector3(sin(yaw) * cos(elev), sin(elev), -cos(yaw) * cos(elev))
		var c := dir * r
		var side := dir.cross(Vector3.UP).normalized() if absf(dir.y) < 0.99 else Vector3.RIGHT
		var up := side.cross(dir).normalized()
		var s := r * rng.randf_range(0.0022, 0.005)
		var b := rng.randf_range(0.55, 1.0)
		var col := Color(b, b, lerpf(b, 1.0, 0.3)) if rng.randf() < 0.85 else Color(1.0, 0.9, 0.7)
		var q := [c - side * s - up * s, c + side * s - up * s, c + side * s + up * s, c - side * s + up * s]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.add_vertex(q[idx])
	var mi := MeshInstance3D.new()
	mi.name = "Stars"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	mat.no_depth_test = false
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A pale moon opposite the day's sun, painted with a few soft maria.
func _make_moon(sun: DirectionalLight3D) -> MeshInstance3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var spots := []
	for i in 6:
		spots.append([Vector2(rng.randf_range(18, 46), rng.randf_range(18, 46)), rng.randf_range(4, 10)])
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length()
			var a := clampf(29.5 - d, 0.0, 1.0)
			var glow := clampf(1.0 - (d - 29.0) / 3.0, 0.0, 1.0) * 0.25 if d > 29.0 else 0.0
			var shade := 1.0
			for sp in spots:
				var e := Vector2(x, y).distance_to(sp[0])
				if e < sp[1]:
					shade -= 0.12 * (1.0 - e / sp[1])
			img.set_pixel(x, y, Color(0.95 * shade, 0.96 * shade, 1.0 * shade, maxf(a, glow)))
	var tex := ImageTexture.create_from_image(img)
	var q := QuadMesh.new()
	q.size = Vector2(16, 16)
	var mi := MeshInstance3D.new()
	mi.name = "Moon"
	mi.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = tex
	mat.disable_fog = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mi.material_override = mat
	var yaw := 0.0
	if sun:
		var f := -sun.global_basis.z
		yaw = atan2(-f.x, f.z)
	var elev := deg_to_rad(38.0)
	mi.position = Vector3(sin(yaw) * cos(elev), sin(elev), -cos(yaw) * cos(elev)) * SKY_RADIUS * 0.9
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _update_night_ambience(open: bool, delta: float) -> void:
	if _night_amb.stream == null:
		return
	var want := -60.0
	if open and GameManager.state != GameManager.GameState.TITLE:
		want = lerpf(-60.0, -15.0, clampf(night_amount(hour()) * 1.3, 0.0, 1.0))
	if want <= -59.0:
		if _night_amb.playing:
			_night_amb.volume_db = move_toward(_night_amb.volume_db, -60.0, delta * 30.0)
			if _night_amb.volume_db <= -59.0:
				_night_amb.stop()
		return
	if not _night_amb.playing:
		_night_amb.volume_db = -60.0
		_night_amb.play()
	_night_amb.volume_db = move_toward(_night_amb.volume_db, want, delta * 20.0)


# --- People, fairies and the creatures of the night ---------------------------------

## People out only by day (AWAY_AT_NIGHT).
func _apply_people(area: Node3D) -> void:
	for who: String in AWAY_AT_NIGHT.get(World.area_id, []):
		var n := area.find_child(who, true, false) as Node3D
		if n:
			var away := is_night()
			n.visible = not away
			n.process_mode = Node.PROCESS_MODE_DISABLED if away else Node.PROCESS_MODE_INHERIT
			if away:
				n.remove_from_group("interactable")
			elif not n.is_in_group("interactable"):
				n.add_to_group("interactable")
			var body := n.get_node_or_null("Body") as StaticBody3D
			if body:
				body.collision_layer = 0 if away else 4


func _apply_fairies(area: Node3D) -> void:
	for f in _fairies:
		if is_instance_valid(f):
			f.queue_free()
	_fairies.clear()
	if not is_night():
		return
	for spot: Vector2 in FAIRY_SPOTS.get(World.area_id, []):
		var y := _ground_y(area, Vector3(spot.x, 0, spot.y))
		if is_nan(y):
			continue
		var f := Fairy.new()
		f.name = "NightFairy"
		area.add_child(f)
		f.global_position = Vector3(spot.x, y + 1.2, spot.y)
		_fairies.append(f)


## The Order's night camps (NIGHT_CAMPS), after the fall.
func _apply_camps(area: Node3D) -> void:
	for c in _camps:
		if is_instance_valid(c):
			c.queue_free()
	_camps.clear()
	if not is_night() or not Progress.flag("castle_fallen") or Progress.flag("ch2:trail_found"):
		return
	var holder := area.get_node_or_null("Enemies")
	for spot: Vector2 in NIGHT_CAMPS.get(World.area_id, []):
		var y := _ground_y(area, Vector3(spot.x, 0, spot.y))
		if is_nan(y):
			continue
		var at := Vector3(spot.x, y, spot.y)
		var fire := _camp_fire()
		area.add_child(fire)
		fire.global_position = at
		_camps.append(fire)
		for m in [["sapphire_mage", Vector3(0, 0, -2.2)], ["basic_enemy", Vector3(2.0, 0, 0.8)], ["basic_enemy", Vector3(-2.0, 0, 0.8)]]:
			var e := (load("res://scenes/enemies/%s.tscn" % m[0]) as PackedScene).instantiate() as Enemy
			e.name = "OrderSentry%d" % _camps.size()
			e.drop_table = 2
			if m[0] == "basic_enemy":
				e.tint = Color(0.72, 0.82, 1.3)
			(holder if holder else area).add_child(e)
			e.global_position = at + (m[1] as Vector3)
			e.add_to_group("night_patrol")
			_camps.append(e)


## A camp's fire: blue Order flames on a ring of stones, with a cold light.
func _camp_fire() -> Node3D:
	var f := Node3D.new()
	f.name = "OrderCampFire"
	f.add_to_group("order_camps")
	for i in 3:
		var a := TAU * i / 3.0
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/flame_mesh.tres")
		mi.position = Vector3(cos(a) * 0.25, 0.0, sin(a) * 0.25) if i > 0 else Vector3.ZERO
		mi.scale = Vector3.ONE * (2.2 if i == 0 else 1.5)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.45, 0.65, 1.0)
		mi.material_override = m
		f.add_child(mi)
	for i in 7:
		var a := TAU * i / 7.0
		var st := MeshInstance3D.new()
		st.mesh = load("res://assets/models/rock_mesh.tres")
		st.position = Vector3(cos(a) * 0.7, 0.05, sin(a) * 0.7)
		st.scale = Vector3.ONE * 1.4
		f.add_child(st)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.7, 1.0)
	light.light_energy = 1.6
	light.omni_range = 9.0
	light.position = Vector3(0, 1.0, 0)
	light.distance_fade_enabled = true
	light.distance_fade_begin = 40.0
	light.distance_fade_length = 10.0
	f.add_child(light)
	return f


func _update_spawns(delta: float) -> void:
	var kind: String = NIGHT_SPAWNS.get(World.area_id, "")
	if kind == "" or not is_night() or night_amount(hour()) < 0.8:
		return
	_spawned = _spawned.filter(func(e: Node3D) -> bool: return is_instance_valid(e) and not (e as Enemy).is_dead())
	_spawn_t -= delta
	var p := GameManager.player
	if _spawn_t > 0.0 or _spawned.size() >= NIGHT_MAX or not is_instance_valid(p) or p.is_riding():
		return
	_spawn_t = randf_range(6.0, 11.0)
	var a := randf() * TAU
	var d := randf_range(9.0, 15.0)
	var at := p.global_position + Vector3(cos(a) * d, 0, sin(a) * d)
	var y := _ground_y(World.area_node, at)
	if is_nan(y) or absf(y - p.global_position.y) > 3.0:
		return
	at.y = y
	if Surface.under(World.area_node.get_world_3d(), at + Vector3.UP * 0.2, World.area_node) == "water":
		return
	var e := (load("res://scenes/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.name = "NightStalfos%d" % _spawned.size()
	e.drop_table = 1
	var holder := World.area_node.get_node_or_null("Enemies")
	(holder if holder else World.area_node).add_child(e)
	e.global_position = at
	e.facing_yaw = atan2(-(p.global_position.x - at.x), -(p.global_position.z - at.z))
	e.rotation.y = e.facing_yaw
	e.add_to_group("night_spawn")
	_spawned.append(e)
	_rise(e)


## Clawing up out of the earth.
func _rise(e: Enemy) -> void:
	var model := e.model as Node3D
	if model == null:
		return
	model.position.y = -2.0
	Sfx.play("bone_rattle", -4.0, 0.08, 0.9)
	Fragments.burst(e.get_parent(), load("res://assets/models/shard_mesh.tres"), e.global_position + Vector3.UP * 0.2, 10, 2.2, 3.5, 0.9, 1.2, Color(0.45, 0.35, 0.25))
	var tw := e.create_tween()
	tw.tween_property(model, "position:y", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## At dawn the night's creatures sink back into the ground.
func _dawn_sink() -> void:
	for e in _spawned:
		if is_instance_valid(e) and not (e as Enemy).is_dead():
			var model := (e as Enemy).model as Node3D
			e.process_mode = Node.PROCESS_MODE_DISABLED
			var tw := create_tween()
			if model:
				tw.tween_property(model, "position:y", -2.2, 1.2)
			tw.tween_callback(e.queue_free)
	_spawned.clear()


static func _ground_y(area: Node3D, at: Vector3) -> float:
	if not is_instance_valid(area):
		return NAN
	var space := area.get_world_3d().direct_space_state
	for nudge in [Vector3.ZERO, Vector3(0.13, 0, 0.07), Vector3(-0.11, 0, 0.17)]:
		var from: Vector3 = at + nudge + Vector3.UP * 40.0
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 80.0, 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			return hit.position.y
	return NAN


# --- Resting ----------------------------------------------------------------------------

## A rest until `target` o'clock (Mira's fireside): fades out, the lullaby,
## the clock moves on, and the picture fades back.
func rest(target: float) -> void:
	if resting:
		return
	resting = true
	if Dialogue.active:
		await Dialogue.finished
	var p := GameManager.player
	if is_instance_valid(p):
		Cutscene.halt_player()
	await World.fade_to(1.0, 0.8)
	Sfx.play("rest_jingle", -2.0, 0.0)
	await get_tree().create_timer(2.6, true).timeout
	set_hour(target)
	if is_instance_valid(p):
		p.health.reset()
		p.health.health_changed.emit(p.health.health, p.health.max_health)
		p.end_cutscene()
	await World.fade_to(0.0, 0.8)
	resting = false
