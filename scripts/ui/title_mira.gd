class_name TitleMira
extends TitleScene
## A title scene (see TitleScene): Mirror Lake at dusk. Mira sits alone at
## the end of the fishing dock with her old rod, talking to the lake about
## nobody ever coming by. A tiny fish bites and she lets it go; the first star
## comes out and she nearly makes a wish on it. Her lines play by themselves.

const AREA := "lake"
const AMBIENCE := "res://assets/audio/amb_lake.wav"
const MUSIC := "res://assets/music/mirror_lake.ogg"
const MIRA := "res://assets/models/mira.tscn"
const ROD := "res://assets/models/fishing_rod_mesh.tres"
const FLOAT := "res://assets/models/fishing_float_mesh.tres"
const FISH := "res://assets/models/fish_mesh.tres"
## On the end of the dock (lake.gd: HUT + (1, 20)), a little back from the
## edge, looking out over the water to the south.
const SEAT := Vector2(-1.0, -32.15)
const FACING := Vector2(0, 1)
const WATER_Y := 0.0
## Where the float sits, from the seat (right, forward) in meters.
const FLOAT_AT := Vector2(0.55, 2.7)
## The low sun, over the lake to the south-west (azimuth, elevation).
const SUN := Vector2(200.0, 14.0)
## Where the first star comes out.
const STAR := Vector2(178.0, 15.0)

const DUSK := {
	"sky": [
		[-25.0, Color(0.16, 0.12, 0.24)], [-2.0, Color(0.55, 0.3, 0.32)], [2.0, Color(1.0, 0.58, 0.32)],
		[8.0, Color(0.98, 0.52, 0.42)], [18.0, Color(0.7, 0.42, 0.55)], [34.0, Color(0.36, 0.3, 0.55)],
		[60.0, Color(0.18, 0.18, 0.42)], [90.0, Color(0.1, 0.11, 0.3)],
	],
	"hills": Color(0.42, 0.3, 0.42),
	"fog": Color(0.6, 0.42, 0.46), "fog_begin": 30.0, "fog_end": 150.0,
	"ambient": Color(0.5, 0.42, 0.56), "ambient_energy": 0.9,
	"sun": Color(1.0, 0.62, 0.38), "sun_energy": 0.85, "sun_rot": Vector3(-14.0, 200.0 - 180.0, 0.0),
	"fill": Color(0.35, 0.32, 0.6), "fill_energy": 0.4,
	"water": Color(1.0, 0.72, 0.78),
}

var _mira: TitleWalker = null
var _rod: MeshInstance3D = null
var _float: MeshInstance3D = null
var _fish: MeshInstance3D = null
var _line: MeshInstance3D = null
var _line_mesh: ImmediateMesh = null
var _star: Node3D = null
var _seat_y := 0.6
## The float's bob, and how far it is pulled under (0..1).
var _bob_t := 0.0
var _dip := 0.0
## The line runs to the float, or hangs slack from the tip once it is reeled in.
var _line_out := true


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


## A point near Mira: `x` to her right, `y` up from the boards, `z` ahead.
func _p(x: float, y: float, z: float) -> Vector3:
	var f := Vector3(FACING.x, 0, FACING.y)
	var r := Vector3(-f.z, 0, f.x)
	return Vector3(SEAT.x, _seat_y, SEAT.y) + r * x + Vector3.UP * y + f * z


func _cast() -> void:
	_grade(DUSK)
	_sky_disc(SUN.x, SUN.y, 9.0, Color(1.0, 0.86, 0.6), Color(1.0, 0.6, 0.35, 0.55))
	_stars(70, 30.0, 21)
	_star = _sky_disc(STAR.x, STAR.y, 1.4, Color(1.0, 0.98, 0.9), Color(0.9, 0.9, 1.0, 0.6))
	if _star:
		_star.visible = false
	_mira = _walker(MIRA)
	_mira.auto = false
	_mira.turn_to_motion = false
	_mira.global_position = Vector3(SEAT.x, 2.0, SEAT.y)
	_mira.settle()
	_seat_y = _mira.global_position.y
	_mira.face(FACING)
	_mira.act(&"sit_fish", 1.0, 0.0)
	var hand_r := _mira.model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	if hand_r:
		_rod = MeshInstance3D.new()
		_rod.name = "Rod"
		_rod.mesh = load(ROD)
		_rod.position = Vector3(0, -0.08, 0)
		hand_r.add_child(_rod)
	var hand_l := _mira.model.get_node_or_null("Hips/Torso/ShoulderL/ElbowL/HandL") as Node3D
	if hand_l:
		_fish = MeshInstance3D.new()
		_fish.name = "LittleFish"
		_fish.mesh = load(FISH)
		_fish.scale = Vector3.ONE * 0.22
		_fish.position = Vector3(0, -0.1, -0.02)
		_fish.rotation = Vector3(0, PI * 0.5, PI * 0.5)
		_fish.visible = false
		hand_l.add_child(_fish)
	_float = _prop(load(FLOAT), Transform3D(Basis.IDENTITY, _float_rest()))
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.name = "Line"
	_line.mesh = _line_mesh
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.95, 0.9, 0.85, 0.8)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line.material_override = lm
	World.area_node.add_child(_line)
	_actors.append(_line)
	_fireflies()
	_loop(_music, MUSIC, -15.0, 3.0)


func _float_rest() -> Vector3:
	var p := _p(FLOAT_AT.x, 0.0, FLOAT_AT.y)
	return Vector3(p.x, WATER_Y, p.z)


## A few fireflies drifting over the boards and the water.
func _fireflies() -> void:
	var p := CPUParticles3D.new()
	p.name = "Fireflies"
	p.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.disable_fog = true
	quad.material = mat
	p.mesh = quad
	p.amount = 18
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(4.0, 0.8, 4.0)
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.85, 1.0, 0.4, 0.0))
	ramp.set_color(1, Color(0.85, 1.0, 0.4, 0.0))
	ramp.add_point(0.3, Color(0.9, 1.0, 0.45, 1.0))
	ramp.add_point(0.5, Color(0.9, 1.0, 0.45, 0.2))
	ramp.add_point(0.7, Color(0.9, 1.0, 0.45, 1.0))
	p.color_ramp = ramp
	World.area_node.add_child(p)
	p.global_position = _p(0.0, 1.0, 0.5)
	_actors.append(p)


func _process(delta: float) -> void:
	super(delta)
	if not running or not is_instance_valid(_float):
		return
	_bob_t += delta
	var rest := _float_rest()
	_float.global_position = rest + Vector3(0, sin(_bob_t * 2.2) * 0.025 - _dip * 0.16, 0)
	if _line_mesh and is_instance_valid(_rod):
		var tip := _rod.global_transform * Vector3(0, 0, -2.1)
		var end := _float.global_position + Vector3(0, 0.06, 0) if _line_out else tip + Vector3(0, -0.5, 0)
		_line_mesh.clear_surfaces()
		_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		# A gentle sag between the tip and the float.
		for i in 9:
			var k := i / 8.0
			_line_mesh.surface_add_vertex(tip.lerp(end, k) + Vector3(0, -sin(k * PI) * 0.12, 0))
		_line_mesh.surface_end()


# --- The scene ------------------------------------------------------------------

func _play(run: int) -> void:
	var say := func(text: String, anim: StringName) -> Dictionary:
		return {"text": text, "name": "Mira", "actor": _mira, "anim": anim}
	# 1. Wide from the beach: the sun going down over Mirror Lake, and a small
	# figure at the end of the dock.
	_cut(_p(7.5, 2.2, -7.0), _p(-1.5, 0.9, 6.0), 48.0)
	_glide(_p(6.0, 1.9, -5.5), _p(-1.0, 0.8, 5.0), 7.0)
	_tween().tween_property(self, "fade", 0.0, 2.0)
	if not await _wait(run, 6.5):
		return
	# 2. Behind her, over the water toward the sun.
	_cut(_p(-0.6, 0.85, -1.35), _p(0.25, 0.85, 3.0), 46.0)
	_glide(_p(-0.5, 0.85, -1.15), _p(0.25, 0.86, 3.0), 9.0)
	if not await _wait(run, 1.2):
		return
	if not await _say(run, [
		say.call("...Nothing's biting tonight.", &"sit_fish"),
		say.call("That's fine. I like it quiet out here.\n...Most of the time.", &"sit_sigh"),
	]):
		return
	# 3. From the water, low, looking back at her.
	_cut(_p(1.3, 0.75, 2.3), _p(0.0, 0.62, 0.0), 44.0)
	_glide(_p(1.1, 0.8, 2.0), _p(0.0, 0.64, 0.0), 12.0)
	if not await _say(run, [
		say.call("Hey, lake. You see everyone who comes down the South Road, don't you?", &"sit_talk"),
		say.call("Does anybody ever... come this way?", &"sit_talk"),
	]):
		return
	_mira.act(&"sit_sigh", 1.0, 0.4)
	if not await _wait(run, 1.0):
		return
	if not await _say(run, [say.call("...Didn't think so.", &"sit_sigh")]):
		return
	# 4. The float bobs... and goes under.
	_mira.act(&"sit_fish", 1.0, 0.4)
	var fl := _float_rest()
	_cut(fl + _p(-0.9, 0.35, -1.4) - _p(0, 0, 0), fl + Vector3(0, 0.05, 0), 40.0)
	if not await _wait(run, 1.6):
		return
	for d in [0.4, 0.0, 0.7, 0.1]:
		_tween().tween_property(self, "_dip", d, 0.12)
		Sfx.play("step_water_0", -14.0, 0.1, 1.4)
		if not await _wait(run, 0.35):
			return
	_tween().tween_property(self, "_dip", 1.0, 0.1)
	Sfx.play("step_water_1", -8.0, 0.05, 1.2)
	if not await _wait(run, 0.25):
		return
	# She yanks it up: a fish, no bigger than her hand.
	_cut(_p(1.5, 1.1, 1.6), _p(-0.1, 0.75, 0.1), 46.0)
	_mira.act(&"sit_tug", 1.0, 0.05)
	Sfx.play("swim_stroke", -6.0, 0.05, 1.3)
	_float.visible = false
	_line_out = false
	if not await _wait(run, 0.7):
		return
	_fish.visible = true
	_mira.act(&"sit_hold", 1.0, 0.25)
	Sfx.play("item_pop", -10.0, 0.0, 1.2)
	_cut(_p(0.8, 0.85, 1.35), _p(-0.1, 0.5, 0.0), 40.0)
	_glide(_p(0.7, 0.85, 1.2), _p(-0.1, 0.52, 0.0), 9.0)
	if not await _say(run, [
		say.call("Oh! ...Hello, little one.", &"sit_hold"),
		say.call("You're far too small to keep.\nGo on. Go home.", &"sit_hold"),
	]):
		return
	_mira.act(&"sit_toss", 1.0, 0.1)
	if not await _wait(run, 0.35):
		return
	_fish.visible = false
	if not await _wait(run, 0.2):
		return
	Sfx.play("step_water_0", -6.0, 0.05, 1.5)
	if not await _wait(run, 0.6):
		return
	if not await _say(run, [say.call("...Hmph. Even the fish have somewhere to be.", &"sit_sigh")]):
		return
	# 5. From behind again, wider: the first star comes out over the lake.
	_line_out = true
	_dip = 0.0
	_float.visible = true
	_mira.act(&"sit_fish", 1.0, 0.4)
	_cut(_p(-0.8, 0.6, -1.6), _p(0.35, 0.75, 4.0), 46.0)
	_glide(_p(-0.7, 0.6, -1.45), _p(0.35, 0.8, 4.0), 12.0)
	if not await _wait(run, 1.2):
		return
	if _star:
		_star.visible = true
		_star.scale = Vector3.ONE * 0.01
		_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(_star, "scale", Vector3.ONE, 0.8)
		Sfx.play("light_hum", -14.0, 0.0, 1.6)
	if not await _wait(run, 0.6):
		return
	_mira.act(&"sit_look", 1.0, 0.5)
	if not await _wait(run, 1.0):
		return
	if not await _say(run, [
		say.call("...The first star.", &"sit_look"),
		say.call("If I wished on it... would somebody come? Somebody nice?", &"sit_look"),
		say.call("Somebody who knocks first.", &"sit_look"),
	]):
		return
	_mira.act(&"sit_fish", 1.0, 0.6)
	if not await _wait(run, 0.8):
		return
	if not await _say(run, [say.call("...Goodnight, lake.", &"sit_fish")]):
		return
	# 6. Up and away over the water, leaving her to it.
	_glide(_p(-6.0, 6.0, -12.0), _p(0.0, 0.8, 4.0), 7.0, 54.0)
	if not await _wait(run, 3.5):
		return
	await _end(run, 2.5)
