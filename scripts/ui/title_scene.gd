class_name TitleScene
extends Node
## A scene for the title screen to play once its music has ended (OoT plays
## its intro and gameplay demos the same way when the title is left alone).
## The title keeps several and picks one at random, never the same one twice
## running. Each is played on the paused tree like TitleFlyover: its own
## camera, TitleWalker actors, tweens and timers that run while paused, and
## lines that play out by themselves (Dialogue's auto mode). Any button skips.
##
## A scene overrides area(), ambience(), _cast() and _play(run); whatever it
## makes goes in _actors so stop() clears it away. _grade() relights the area
## for a time of day the game itself never shows (dusk, night).

signal finished

## OoT's cutscene letterbox (Letterbox_SetSizeTarget(32)).
const LETTERBOX := 32.0
## The sky the scenes paint inside the area's own (and outside its horizon
## hills, at SKY_RADIUS - 15 in world_kit).
const SKY_R := 236.0

## Black over the picture 0..1, and the letterbox height (the title draws both).
var fade := 1.0
var bars := 0.0
var running := false

var _cam: Camera3D = null
## Everything the scene put in the area (freed by stop()).
var _actors: Array[Node] = []
var _amb: AudioStreamPlayer = null
## A second loop (a campfire's crackle over the wind, say).
var _amb2: AudioStreamPlayer = null
var _music: AudioStreamPlayer = null
## Bumped by stop(): a scene coroutine from an older run gives up.
var _run := 0
var _tweens: Array[Tween] = []
## The camera's aim, eased between shots by _glide.
var _eye := Vector3.ZERO
var _at := Vector3.ZERO
## A short camera shake (amplitude in meters, seconds left).
var _shake_amp := 0.0
var _shake_left := 0.0
## Whether auto lines are playing (stop() cancels them).
var _speaking := false
## The camera move under way (a cut or a new move replaces it).
var _cam_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_amb = _player("Ambience")
	_amb2 = _player("Ambience2")
	_music = _player("Music")


func _player(n: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.bus = "Music" if n == "Music" else "Ambience"
	add_child(p)
	return p


## The area the scene happens in.
func area() -> String:
	return ""


## The area's ambient loop ("" for none).
func ambience() -> String:
	return ""


## Loads the area and plays the scene in `viewport`; `finished` is emitted
## once it has faded out (not when stopped early).
func start(viewport: SubViewport) -> void:
	stop()
	running = true
	_run += 1
	fade = 1.0
	bars = LETTERBOX
	World.show_scenery(area())
	TitleFlyover.hush_area()
	_cam = Camera3D.new()
	_cam.name = "SceneCamera"
	_cam.fov = 50.0
	_cam.far = 600.0
	viewport.add_child(_cam)
	_cam.make_current()
	_cast()
	_loop(_amb, ambience(), -16.0, 1.5)
	_play(_run)


## Ends the scene at once (skipped, or the title is leaving).
func stop() -> void:
	_run += 1
	running = false
	_kill_tweens()
	if _speaking:
		_speaking = false
		Dialogue.cancel()
	for n in _actors + [_cam]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_actors.clear()
	_cam = null
	for p in [_amb, _amb2, _music]:
		if p and p.playing:
			p.stop()


## Puts the scene's people and props in place (the area is loaded).
func _cast() -> void:
	pass


## The scene itself; gives up quietly once `_alive(run)` turns false.
func _play(_r: int) -> void:
	pass


## Fades out, then reports the scene done.
func _end(run: int, time := 1.4) -> void:
	_tween().tween_property(self, "fade", 1.0, time)
	for p in [_amb, _amb2, _music]:
		if p.playing:
			_tween().tween_property(p, "volume_db", -60.0, time)
	if not await _wait(run, time + 0.2):
		return
	stop()
	finished.emit()


# --- Lines ------------------------------------------------------------------------

## Plays `pages` in auto boxes (see Dialogue) and waits for the last to close;
## false if the scene was stopped meanwhile. A page may carry "actor" (a
## TitleWalker) with "anim" to play on it, and "blush" (true/false) for the
## models that have one.
func _say(run: int, pages: Array) -> bool:
	if not _alive(run):
		return false
	_speaking = true
	Dialogue.page_started.connect(_on_page)
	Dialogue.start(pages, null, "black", true)
	await Dialogue.finished
	if Dialogue.page_started.is_connected(_on_page):
		Dialogue.page_started.disconnect(_on_page)
	_speaking = false
	return await _wait(run, 0.25)


func _on_page(page: Dictionary) -> void:
	var who = page.get("actor")
	if not (who is TitleWalker) or not is_instance_valid(who):
		return
	var walker := who as TitleWalker
	if page.has("anim"):
		walker.act(StringName(page.anim), 1.0, 0.3)
	if page.has("blush") and walker.model:
		walker.model.set_blush(page.blush)


# --- Time of day ------------------------------------------------------------------

## Relights the loaded area. `m` holds:
##   sky: [[elevation deg, Color], ...] bottom to top (painted over the area's
##     sky), hills: tint for the horizon silhouettes, fog, fog_begin, fog_end,
##     ambient, ambient_energy, sun, sun_energy, sun_rot (degrees), fill,
##     fill_energy, water: tint for the water, dust: false hides sky particles.
## The area's own resources are not touched (copies are changed), so the
## next load of the area is lit as usual.
func _grade(m: Dictionary) -> void:
	var node := World.area_node
	if node == null:
		return
	var we := node.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment.duplicate() as Environment
		env.background_color = m.fog
		env.fog_light_color = m.fog
		env.fog_depth_begin = m.get("fog_begin", env.fog_depth_begin)
		env.fog_depth_end = m.get("fog_end", env.fog_depth_end)
		env.ambient_light_color = m.ambient
		env.ambient_light_energy = m.get("ambient_energy", 1.0)
		we.environment = env
	var sun := node.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.light_color = m.sun
		sun.light_energy = m.get("sun_energy", 1.0)
		if m.has("sun_rot"):
			sun.rotation_degrees = m.sun_rot
	var fill := node.get_node_or_null("FillLight") as DirectionalLight3D
	if fill and m.has("fill"):
		fill.light_color = m.fill
		fill.light_energy = m.get("fill_energy", fill.light_energy)
	var sky := node.get_node_or_null("SkyDome") as Node3D
	if sky:
		var dome := sky.get_node_or_null("Dome") as Node3D
		if dome:
			dome.visible = false
		var hills := sky.get_node_or_null("Horizon") as MeshInstance3D
		if hills and m.has("hills"):
			_tint(hills, m.hills)
		var dust := sky.get_node_or_null("Particles") as Node3D
		if dust and not m.get("dust", true):
			dust.visible = false
		var paint := MeshInstance3D.new()
		paint.name = "SceneSky"
		paint.mesh = _sky_mesh(m.sky)
		paint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sky.add_child(paint)
		_actors.append(paint)
	if m.has("water"):
		for w in _water_nodes(node):
			_tint(w, m.water)


## Multiplies a mesh's colors by `col` (on a copy of its material).
func _tint(mi: MeshInstance3D, col: Color) -> void:
	var mat := mi.material_override
	if mat == null and mi.mesh and mi.mesh.get_surface_count() > 0:
		mat = mi.get_active_material(0)
	if mat is BaseMaterial3D:
		var c := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
		c.albedo_color = c.albedo_color * col
		mi.material_override = c
	elif mat is ShaderMaterial:
		# Water and such: a shader with an albedo-like tint uniform, if any.
		var sm := (mat as ShaderMaterial).duplicate() as ShaderMaterial
		for u in ["tint", "albedo", "color", "water_color"]:
			var v = sm.get_shader_parameter(u)
			if v is Color:
				sm.set_shader_parameter(u, (v as Color) * col)
		mi.material_override = sm


func _water_nodes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var feats := node.get_node_or_null("Features")
	if feats:
		for c in feats.get_children():
			if c is MeshInstance3D and String(c.name).begins_with("Water"):
				out.append(c)
	return out


## A dome of color bands (unlit, no fog) at SKY_R, in rows a few degrees
## tall so its flat facets stay behind the stars and discs painted on it.
static func _sky_mesh(stops: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 64
	var rows: Array = []
	for r in stops.size() - 1:
		var lo := float(stops[r][0])
		var hi := float(stops[r + 1][0])
		var n := maxi(int(ceil((hi - lo) / 3.0)), 1)
		for j in n:
			var k0 := float(j) / n
			var k1 := float(j + 1) / n
			rows.append([lerpf(lo, hi, k0), (stops[r][1] as Color).lerp(stops[r + 1][1], k0),
				lerpf(lo, hi, k1), (stops[r][1] as Color).lerp(stops[r + 1][1], k1)])
	for row in rows:
		var e0 := deg_to_rad(float(row[0]))
		var e1 := deg_to_rad(float(row[2]))
		var c0: Color = row[1]
		var c1: Color = row[3]
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p00 := _dir(a0, e0) * SKY_R
			var p10 := _dir(a1, e0) * SKY_R
			var p01 := _dir(a0, e1) * SKY_R
			var p11 := _dir(a1, e1) * SKY_R
			for v in [[p00, c0], [p11, c1], [p10, c0], [p00, c0], [p01, c1], [p11, c1]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	st.set_material(_unlit(false))
	return st.commit()


## Direction for azimuth `a` (radians clockwise from north, -z) and elevation `e`.
static func _dir(a: float, e: float) -> Vector3:
	return Vector3(sin(a) * cos(e), sin(e), -cos(a) * cos(e))


static func _unlit(blend: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	m.disable_receive_shadows = true
	if blend:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.render_priority = 1
	return m


## A field of stars over the sky (above `low` degrees), `count` of them,
## spread evenly over it.
func _stars(count: int, low := 6.0, seed_value := 7) -> void:
	var sky := World.area_node.get_node_or_null("SkyDome") if World.area_node else null
	if sky == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var a := rng.randf() * TAU
		var e := asin(lerpf(sin(deg_to_rad(low)), 1.0, rng.randf()))
		var d := _dir(a, e)
		var size := rng.randf_range(1.4, 2.4) * (1.5 if rng.randf() < 0.08 else 1.0)
		var warm := rng.randf()
		var col := Color(1.0, 0.95, 0.85).lerp(Color(0.8, 0.88, 1.0), warm) * rng.randf_range(0.55, 1.0)
		col.a = 1.0
		_quad(st, d * (SKY_R - 2.0), d, size, col)
	st.set_material(_unlit(false))
	var mi := MeshInstance3D.new()
	mi.name = "Stars"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky.add_child(mi)
	_actors.append(mi)


## A disc in the sky (the moon, the low sun) with a soft halo round it:
## azimuth/elevation in degrees, `radius` in sky meters.
func _sky_disc(azimuth: float, elevation: float, radius: float, col: Color, halo: Color, marks := false) -> Node3D:
	var sky := World.area_node.get_node_or_null("SkyDome") if World.area_node else null
	if sky == null:
		return null
	var d := _dir(deg_to_rad(azimuth), deg_to_rad(elevation))
	var root := Node3D.new()
	root.name = "SkyDisc"
	sky.add_child(root)
	_actors.append(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_disc(st, d * (SKY_R - 4.0), d, radius, col, col)
	if marks:
		# A few darker seas on the moon's face.
		for o in [Vector2(-0.3, 0.25), Vector2(0.2, -0.1), Vector2(0.05, 0.4), Vector2(-0.15, -0.35)]:
			var b := _basis_for(d)
			var p: Vector3 = d * (SKY_R - 4.3) + (b.x * o.x + b.y * o.y) * radius
			_disc(st, p, d, radius * 0.22, col.darkened(0.12), col.darkened(0.12))
	st.set_material(_unlit(false))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var hs := SurfaceTool.new()
	hs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var clear := Color(halo, 0.0)
	_disc(hs, d * (SKY_R - 3.0), d, radius * 3.2, halo, clear)
	hs.set_material(_unlit(true))
	var glow := MeshInstance3D.new()
	glow.mesh = hs.commit()
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glow)
	return root


## A shooting star: a bright streak with a fading tail, crossing from
## (azimuth, elevation) to another over `time` seconds.
func _shooting_star(from: Vector2, to: Vector2, time: float) -> void:
	var sky := World.area_node.get_node_or_null("SkyDome") if World.area_node else null
	if sky == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "ShootingStar"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky.add_child(mi)
	_actors.append(mi)
	var draw := func(k: float) -> void:
		if not is_instance_valid(mi):
			return
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var head := from.lerp(to, k)
		var tail := from.lerp(to, maxf(k - 0.35, 0.0))
		var hd := _dir(deg_to_rad(head.x), deg_to_rad(head.y)) * (SKY_R - 5.0)
		var td := _dir(deg_to_rad(tail.x), deg_to_rad(tail.y)) * (SKY_R - 5.0)
		var side := (hd - td).cross(hd).normalized() * 0.5
		var a := sin(k * PI)
		var bright := Color(1.0, 0.97, 0.85, a)
		var dim := Color(0.8, 0.85, 1.0, 0.0)
		for v in [[hd + side, bright], [hd - side, bright], [td, dim]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
		_disc(st, hd, hd.normalized(), 0.9, bright, Color(bright, 0.0))
		st.set_material(_unlit(true))
		mi.mesh = st.commit()
	_tween().tween_method(draw, 0.0, 1.0, time)


static func _basis_for(d: Vector3) -> Basis:
	var up := Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD
	var x := up.cross(d).normalized()
	var y := d.cross(x).normalized()
	return Basis(x, y, d)


static func _quad(st: SurfaceTool, c: Vector3, n: Vector3, size: float, col: Color) -> void:
	var b := _basis_for(n)
	var x := b.x * size * 0.5
	var y := b.y * size * 0.5
	for v in [c - x - y, c + x - y, c + x + y, c - x - y, c + x + y, c - x + y]:
		st.set_color(col)
		st.add_vertex(v)


static func _disc(st: SurfaceTool, c: Vector3, n: Vector3, r: float, mid: Color, rim: Color) -> void:
	var b := _basis_for(n)
	var seg := 16
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		st.set_color(mid)
		st.add_vertex(c)
		st.set_color(rim)
		st.add_vertex(c + (b.x * cos(a0) + b.y * sin(a0)) * r)
		st.set_color(rim)
		st.add_vertex(c + (b.x * cos(a1) + b.y * sin(a1)) * r)


# --- Sound ------------------------------------------------------------------------

## Starts `player` looping `path`, fading up to `db` over `time`.
func _loop(player: AudioStreamPlayer, path: String, db: float, time: float) -> void:
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = int(w.get_length() * w.mix_rate)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	player.volume_db = -60.0
	player.play()
	_tween().tween_property(player, "volume_db", db, time)


# --- Helpers ----------------------------------------------------------------------

func _alive(run: int) -> bool:
	return running and run == _run


## Waits `seconds` (on the paused tree); false if the scene was stopped.
func _wait(run: int, seconds: float) -> bool:
	await get_tree().create_timer(seconds, true).timeout
	return _alive(run)


func _kill_tweens() -> void:
	for t in _tweens:
		if t.is_valid():
			t.kill()
	_tweens.clear()


func _tween() -> Tween:
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tweens.append(t)
	return t


## A walker of `model_path` in the area, freed with the scene.
func _walker(model_path := TitleWalker.HERO) -> TitleWalker:
	var w := TitleWalker.make(World.area_node, model_path)
	_actors.append(w)
	return w


## A plain mesh in the area, freed with the scene.
func _prop(mesh: Mesh, at: Transform3D, material: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if material:
		mi.material_override = material
	World.area_node.add_child(mi)
	mi.global_transform = at
	_actors.append(mi)
	return mi


## Walks (or runs, by speed) `who` to `to`; returns on arrival.
func _walk(who: TitleWalker, to: Vector2, speed: float) -> void:
	if not is_instance_valid(who):
		return
	var from := who.xz()
	who.face_point(to)
	var step := func(k: float) -> void:
		if is_instance_valid(who):
			who.place(from.lerp(to, k))
	var t := _tween()
	t.tween_method(step, 0.0, 1.0, from.distance_to(to) / maxf(speed, 0.01))
	await t.finished


## A little hop off the ground (`height` m over `time` s).
func _hop(who: TitleWalker, height: float, time: float) -> void:
	who.airborne = true
	var base := who.global_position.y
	var arc := func(k: float) -> void:
		if is_instance_valid(who):
			who.global_position.y = base + 4.0 * height * k * (1.0 - k)
	var land := func() -> void:
		if is_instance_valid(who):
			who.airborne = false
	var t := _tween()
	t.tween_method(arc, 0.0, 1.0, time)
	t.tween_callback(land)


func _cut(eye: Vector3, at: Vector3, field := 50.0) -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	_eye = eye
	_at = at
	if is_instance_valid(_cam):
		_cam.fov = field
	_apply()


## Eases the camera from where it is to a new eye and aim over `time`
## (and the field of view to `field`, if given).
func _glide(eye: Vector3, at: Vector3, time: float, field := -1.0) -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	var t := _tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	_cam_tween = t
	t.tween_property(self, "_eye", eye, time)
	t.tween_property(self, "_at", at, time)
	if field > 0.0 and is_instance_valid(_cam):
		t.tween_property(_cam, "fov", field, time)


func _shake(amplitude: float, seconds: float) -> void:
	_shake_amp = amplitude
	_shake_left = seconds


## Added to every shot's height (the ground the scene was laid out on).
func _lift() -> float:
	return 0.0


func _process(delta: float) -> void:
	if running:
		_shake_left = maxf(_shake_left - delta, 0.0)
		_apply()


func _apply() -> void:
	if not is_instance_valid(_cam):
		return
	var e := _eye
	if _shake_left > 0.0:
		e += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake_amp
	var lift := _lift()
	if e.distance_to(_at) > 0.01:
		_cam.look_at_from_position(e + Vector3.UP * lift, _at + Vector3.UP * lift, Vector3.UP)
