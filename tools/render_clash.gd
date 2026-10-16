extends Node
## Promo picture: Sir Gigglebuns IV and Firebuns III locked blade to blade in
## the Shattered Prison at the heart of the Astral Rift (the last battle),
## the awakened Bun Sword's starlight flaring where the blades meet. Run
## windowed (needs a GPU):
##   Godot --path <project> res://tools/render_clash.tscn -- --out=<png> [--aspect=portrait] [--scale=1]
## The arms are posed by a small solver (the hilts meet at the clash point,
## the blades stand up and cross); the rest of each pose is set by hand.

const ASPECTS := {
	"landscape": {"size": Vector2i(1920, 1080), "fov": 33.0, "eye": Vector3(-0.45, 1.0, 3.8), "at": Vector3(0.05, 1.42, 0.0)},
	"portrait": {"size": Vector2i(1080, 1920), "fov": 50.0, "eye": Vector3(-0.35, 0.95, 3.3), "at": Vector3(0.05, 1.42, 0.0)},
}

## Where the hilts meet (in the stage's own space) and how the blades stand.
const CLASH := Vector3(0.0, 1.3, 0.12)
const FB_BLADE := Vector3(0.2, 1.0, 0.1)
const HERO_BLADE := Vector3(-0.14, 1.0, 0.12)

var _args := {}
var _stage: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var f: Dictionary = ASPECTS[_args.get("aspect", "landscape")]
	var size := Vector2i(Vector2(f.size) * float(_args.get("scale", "1")))
	var vp := SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	# The arena: the real area, frozen, with its foes taken out.
	var area := (load("res://scenes/areas/astral_rift.tscn") as PackedScene).instantiate() as Node3D
	area.process_mode = Node.PROCESS_MODE_DISABLED
	vp.add_child(area)
	for n in area.find_children("*", "", true, false):
		if n.scene_file_path.contains("/enemies/"):
			n.queue_free()
	var mark := area.find_child("cs_prison", true, false) as Node3D
	_stage = Node3D.new()
	vp.add_child(_stage)
	_stage.global_position = (mark.global_position if mark else Vector3(0, 60, -367)) + Vector3(0, 0, 1.0)
	# Firebuns on the left, facing right and a little toward us; the hero on
	# the right, facing him.
	var fb := _model("res://assets/models/firebuns.tscn", Vector3(-0.6, 0, -0.05), -112.0)
	var hero := _model("res://assets/models/sir_gigglebuns.tscn", Vector3(0.56, 0, 0.05), 116.0)
	if hero.has_method("set_gear"):
		hero.call("set_gear", "bun_awake", "questlord")
		hero.call("set_sword_drawn", true)
		hero.call("set_starlight", true)
	_pose_firebuns(fb)
	_pose_hero(hero)
	_build_flare()
	_build_sky()
	var cam := Camera3D.new()
	cam.fov = f.fov
	cam.far = 900.0
	_stage.add_child(cam)
	cam.look_at_from_position(_stage.to_global(f.eye), _stage.to_global(f.at), Vector3.UP)
	cam.current = true
	# Shards of the broken prison that would stand in front of them.
	for mi in area.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh and m3.mesh.resource_path.contains("prison_shard"):
			var lp := _stage.to_local(m3.global_position)
			if lp.z > -1.5 and absf(lp.x) < 5.0:
				m3.visible = false
	for i in 40:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var out: String = _args.get("out", "res://promo/clash.png")
	print("render_clash: -> %s (%s)" % [out, error_string(img.save_png(out))])
	get_tree().quit()


func _model(path: String, at: Vector3, yaw: float) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	_stage.add_child(m)
	m.position = at
	m.rotation_degrees.y = yaw
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		ap.play("idle")
		ap.seek(0.3, true)
		ap.pause()
	# Frozen, so nothing animates over the pose set below.
	m.process_mode = Node.PROCESS_MODE_DISABLED
	return m


func _j(m: Node3D, name: String) -> Node3D:
	return m.find_child(name, true, false) as Node3D


func _rot(m: Node3D, name: String, deg: Vector3) -> void:
	var n := _j(m, name)
	if n:
		n.rotation_degrees = deg


# --- The poses ------------------------------------------------------------------------

## Firebuns looms over him: leaning in, head bowed toward the hero, his sword
## (in his gauntleted left hand) driven against the Bun Sword, his right fist
## clenched back by his hip.
func _pose_firebuns(fb: Node3D) -> void:
	var hips := _j(fb, "Hips")
	hips.position.y -= 0.03
	_rot(fb, "Torso", Vector3(-22, -10, 0))
	_rot(fb, "LegL", Vector3(-22, 0, 4))
	_rot(fb, "KneeL", Vector3(18, 0, 0))
	_rot(fb, "LegR", Vector3(20, 0, -4))
	_rot(fb, "KneeR", Vector3(8, 0, 0))
	var target := _stage.to_global(CLASH + Vector3(-0.07, -0.01, 0))
	var blade := (_stage.global_basis * FB_BLADE).normalized()
	_solve_arm(fb, "L", _j(fb, "Broadsword"), target, blade)
	_solve_arm(fb, "R", null, fb.to_global(Vector3(0.28, 0.95, -0.12)), Vector3.ZERO)
	_look(fb, _j(fb, "Head"), _stage.to_global(Vector3(0.45, 1.3, 0.1)))


## The hero braced low beneath him: feet wide, leaning up into the blow, eyes
## on Firebuns, shield arm flung back for balance.
func _pose_hero(hero: Node3D) -> void:
	var hips := _j(hero, "Hips")
	hips.position.y -= 0.1
	_rot(hero, "Torso", Vector3(-10, 6, 0))
	_rot(hero, "LegL", Vector3(-38, 0, 6))
	_rot(hero, "KneeL", Vector3(42, 0, 0))
	_rot(hero, "LegR", Vector3(30, 0, -6))
	_rot(hero, "KneeR", Vector3(16, 0, 0))
	var target := _stage.to_global(CLASH + Vector3(0.07, -0.04, 0.02))
	var blade := (_stage.global_basis * HERO_BLADE).normalized()
	_solve_arm(hero, "R", _j(hero, "Sword"), target, blade)
	_solve_arm(hero, "L", null, hero.to_global(Vector3(-0.42, 1.0, 0.32)), Vector3.ZERO)
	_look(hero, _j(hero, "Head"), _stage.to_global(Vector3(-0.5, 1.62, 0.0)))


## Turns shoulder, elbow and hand (side "L"/"R") so the hand (or `tool`'s
## grip) reaches `target` and, with a tool, its blade points along `dir`.
## Coordinate descent on the nine Euler angles, kept near the starting pose.
func _solve_arm(m: Node3D, side: String, tool: Node3D, target: Vector3, dir: Vector3) -> void:
	var joints: Array[Node3D] = [_j(m, "Shoulder" + side), _j(m, "Elbow" + side), _j(m, "Hand" + side)]
	var tip: Node3D = tool if tool else joints[2]
	var axis := _blade_axis(tool) if tool else Vector3.ZERO
	var start: Array[Vector3] = []
	for j in joints:
		start.append(j.rotation)
	var cost := func() -> float:
		var c := tip.global_position.distance_squared_to(target) * 40.0
		if tool:
			var d := (tip.global_basis * axis).normalized()
			c += (1.0 - d.dot(dir)) * 3.0
		for i in 3:
			c += (joints[i].rotation - start[i]).length_squared() * 0.004
		return c
	var best: float = cost.call()
	var step := 0.5
	for it in 400:
		var improved := false
		for ji in 3:
			for ax in 3:
				for sgn in [1.0, -1.0]:
					var r := joints[ji].rotation
					r[ax] += step * sgn
					var old := joints[ji].rotation
					joints[ji].rotation = r
					var c: float = cost.call()
					if c < best:
						best = c
						improved = true
					else:
						joints[ji].rotation = old
		if not improved:
			step *= 0.6
			if step < 0.002:
				break
	print("render_clash: %s %s arm off by %.3f m" % [m.name, side, tip.global_position.distance_to(target)])


## The tool's blade direction in its own space: its longest extent, toward
## the far end.
func _blade_axis(tool: Node3D) -> Vector3:
	var box := AABB()
	for c in tool.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			box = (c as MeshInstance3D).get_aabb()
	var s := box.size
	var c := box.get_center()
	if s.x >= s.y and s.x >= s.z:
		return Vector3(signf(c.x), 0, 0)
	if s.y >= s.z:
		return Vector3(0, signf(c.y), 0)
	return Vector3(0, 0, signf(c.z))


## Turns the head (its face is -Z) to look at `point`.
func _look(m: Node3D, head: Node3D, point: Vector3) -> void:
	if head == null:
		return
	var best := INF
	var keep := head.rotation
	for x in range(-40, 41, 4):
		for y in range(-60, 61, 4):
			head.rotation = Vector3(deg_to_rad(x), deg_to_rad(y), 0)
			var fwd := -head.global_basis.z.normalized()
			var c := 1.0 - fwd.dot((point - head.global_position).normalized())
			if c < best:
				best = c
				keep = head.rotation
	head.rotation = keep


# --- The flare ------------------------------------------------------------------------

## Rose-white starlight bursting from where the blades meet: a hot core, a
## soft bloom, long thin rays, and sparks flung out; with a light that catches
## both their faces.
func _build_flare() -> void:
	var at := CLASH + Vector3(0.0, 0.08, 0.04)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0, 0, 0.2)
	light.light_color = Color(1.0, 0.78, 0.92)
	light.light_energy = 1.5
	light.omni_range = 2.6
	_stage.add_child(light)
	var fire := OmniLight3D.new()
	fire.position = CLASH + Vector3(-0.4, 0.2, 0.3)
	fire.light_color = Color(1.0, 0.45, 0.15)
	fire.light_energy = 1.4
	fire.omni_range = 2.0
	_stage.add_child(fire)
	# Rim lights from behind: the Rift's violet on the left, fire on the right.
	for r in [[Vector3(-8, 170, 0), Color(0.6, 0.45, 1.0), 1.1], [Vector3(-10, -160, 0), Color(1.0, 0.55, 0.3), 0.8]]:
		var rim := DirectionalLight3D.new()
		rim.rotation_degrees = r[0]
		rim.light_color = r[1]
		rim.light_energy = r[2]
		_stage.add_child(rim)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3(0.1, 0.0, 1.0).normalized()
	TitleScene._disc(st, at, n, 0.4, Color(1.0, 0.7, 0.9, 0.22), Color(0.9, 0.4, 0.8, 0.0))
	TitleScene._disc(st, at, n, 0.13, Color(1.0, 0.95, 1.0, 0.75), Color(1.0, 0.75, 0.95, 0.0))
	TitleScene._disc(st, at, n, 0.045, Color(1, 1, 1, 1), Color(1, 0.9, 1, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	var right := Vector3(1, 0, -0.1).normalized()
	var up := n.cross(right).normalized()
	for i in 10:
		var a := TAU * i / 10.0 + rng.randf_range(-0.15, 0.15)
		var d := (right * cos(a) + up * sin(a))
		var length := rng.randf_range(0.2, 0.5) * (1.7 if i % 3 == 0 else 1.0)
		var w := (right * -sin(a) + up * cos(a)) * 0.008
		st.set_color(Color(1.0, 0.9, 1.0, 0.5))
		st.add_vertex(at + w)
		st.set_color(Color(1.0, 0.85, 0.97, 0.0))
		st.add_vertex(at + d * length)
		st.set_color(Color(1.0, 0.9, 1.0, 0.5))
		st.add_vertex(at - w)
	# Sparks: short bright streaks flying outward.
	for i in 30:
		var a := rng.randf() * TAU
		var d := (right * cos(a) + up * sin(a) + n * rng.randf_range(-0.3, 0.5)).normalized()
		var p := at + d * rng.randf_range(0.12, 0.6)
		var tail := p - d * rng.randf_range(0.04, 0.12)
		var w := d.cross(n).normalized() * 0.004
		var col := Color(1.0, 0.8, 0.5) if rng.randf() < 0.4 else Color(1.0, 0.85, 1.0)
		for v in [tail + w, p, tail - w]:
			st.set_color(Color(col, 1.0 if v == p else 0.2))
			st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = true
	m.render_priority = 10
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.add_child(mi)


## The Rift's sky over the open prison: violet and blue star-clouds, a glow of
## fire behind Firebuns, and stars.
func _build_sky() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1964
	const R := 42.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 90:
		var d := (Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(0.05, 0.9), -1.0)).normalized()
		var col: Color = [Color(0.42, 0.22, 0.72), Color(0.2, 0.3, 0.8), Color(0.55, 0.25, 0.6)][i % 3]
		if d.x < -0.3 and rng.randf() < 0.6:
			col = Color(0.85, 0.3, 0.12)
		col.a = rng.randf_range(0.1, 0.22)
		TitleScene._disc(st, d * (R + 2.0), -d, rng.randf_range(5.0, 12.0), col, Color(col, 0.0))
	for i in 1800:
		var d := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.02, 1.0), rng.randf_range(-1.0, 0.3)).normalized()
		var c := Color(1.0, 0.95, 0.88).lerp(Color(0.75, 0.82, 1.0), rng.randf()) * rng.randf_range(0.45, 1.0)
		c.a = 1.0
		TitleScene._quad(st, d * R, -d, rng.randf_range(0.04, 0.1) * (2.0 if rng.randf() < 0.04 else 1.0), c)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.position = Vector3(0, -2.0, 0)
	mi.extra_cull_margin = 500.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.add_child(mi)
