class_name TitleQuestlords
extends TitleScene
## A title scene (see TitleScene): night in the Desert of Ladhellin, the
## Questlords' home. Idrith and Aladriel walk up a dune hand in hand to a
## campfire by a fallen column, sit together under the stars looking out over
## the oasis (Ladhellin Tower at their backs), remember Dailah's sandstorm, and
## share a little kiss and a shooting star. Their lines play by themselves.

const AREA := "desert"
const AMBIENCE := "res://assets/audio/amb_desert.wav"
const CRACKLE := "res://assets/audio/amb_hearth.wav"
const ALADRIEL := "res://assets/models/aladriel.tscn"
const IDRITH := "res://assets/models/idrith.tscn"
const SANDSTONE := "res://assets/materials/sandstone.tres"
const WOOD := "res://assets/materials/wood.tres"
const FLAME := "res://assets/models/flame_mesh.tres"
const FLICKER := "res://scripts/systems/torch_flicker.gd"
const SWORD := "res://assets/models/giant_sword_mesh.tres"
const SCIMITAR := "res://assets/models/scimitar_mesh.tres"
## The fallen column they sit on: a flat dune top above the oasis.
const SEAT := Vector2(-13.0, 12.0)
## Ladhellin Tower (desert.gd TOWER), at their backs.
const TOWER := Vector2(18.0, -12.0)
## Half the gap between them on the column (as on the armory bench).
const SIDE := 0.24
## The column's top, above the sand.
const SEAT_H := 0.45
## Over the oasis, ahead of them (azimuth, elevation).
const MOON := Vector2(236.0, 24.0)

const NIGHT := {
	"sky": [
		[-25.0, Color(0.02, 0.025, 0.07)], [0.0, Color(0.1, 0.12, 0.26)], [8.0, Color(0.07, 0.09, 0.22)],
		[30.0, Color(0.035, 0.05, 0.15)], [90.0, Color(0.015, 0.02, 0.08)],
	],
	"hills": Color(0.12, 0.13, 0.24),
	"fog": Color(0.07, 0.08, 0.18), "fog_begin": 22.0, "fog_end": 125.0,
	"ambient": Color(0.2, 0.24, 0.46), "ambient_energy": 0.45,
	"sun": Color(0.6, 0.7, 1.0), "sun_energy": 0.35, "sun_rot": Vector3(-24.0, 236.0 - 180.0, 0.0),
	"fill": Color(0.14, 0.14, 0.3), "fill_energy": 0.3,
	"water": Color(0.35, 0.4, 0.7),
	"dust": false,
}

var _ala: TitleWalker = null
var _idr: TitleWalker = null
var _fire: Node3D = null
var _seat_y := 0.0
var _f := Vector3.FORWARD
var _r := Vector3.RIGHT


func area() -> String:
	return AREA


func ambience() -> String:
	return AMBIENCE


## A point by the column: `x` to their right, `y` up from the sand, `z` ahead.
func _p(x: float, y: float, z: float) -> Vector3:
	return Vector3(SEAT.x, _seat_y, SEAT.y) + _r * x + Vector3.UP * y + _f * z


func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _cast() -> void:
	_grade(NIGHT)
	_stars(600, 4.0, 11)
	_sky_disc(MOON.x, MOON.y, 11.0, Color(0.98, 0.97, 0.88), Color(0.6, 0.7, 1.0, 0.35), true)
	var d := (SEAT - TOWER).normalized()
	_f = Vector3(d.x, 0, d.y)
	_r = Vector3(-_f.z, 0, _f.x)
	_seat_y = TitleWalker.ground_y(World.area_node, SEAT, 10.0)
	_column()
	_campfire(_p(0.0, 0.0, 1.55))
	# Their weapons, at hand: her giant sword in the sand at Aladriel's end,
	# Idrith's scimitar leaning on the column at hers.
	var lean := Basis(_f, deg_to_rad(-12.0))
	_prop(load(SWORD), Transform3D(lean * Basis(Vector3.UP, atan2(-_f.x, -_f.z)), _p(-1.25, -0.15, 0.1)))
	_prop(load(SCIMITAR), Transform3D(Basis(_f, deg_to_rad(28.0)) * Basis(Vector3.UP, atan2(-_r.x, -_r.z)), _p(1.15, 0.0, 0.32)))
	_ala = _pair_walker(ALADRIEL)
	_idr = _pair_walker(IDRITH)
	_loop(_amb2, CRACKLE, -60.0, 0.1)


func _pair_walker(path: String) -> TitleWalker:
	var w := _walker(path)
	w.hero_stride = false
	w.walk_anim = &"walk_hand"
	w.stride = 1.05
	w.run_speed = 99.0
	w.visible = false
	return w


## A broken column lying half in the sand, long enough for two.
func _column() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.27
	cyl.bottom_radius = 0.27
	cyl.height = 2.1
	cyl.radial_segments = 8
	cyl.rings = 1
	# Lying along their left-right, top at SEAT_H.
	var b := Basis(Vector3.UP, atan2(-_f.x, -_f.z)) * Basis(Vector3.BACK, PI * 0.5)
	_prop(cyl, Transform3D(b, _p(0.0, SEAT_H - 0.27, 0.06)), load(SANDSTONE))
	var drum := CylinderMesh.new()
	drum.top_radius = 0.3
	drum.bottom_radius = 0.32
	drum.height = 0.5
	drum.radial_segments = 8
	drum.rings = 1
	_prop(drum, Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, 0.2), _p(-1.65, 0.1, 0.5)), load(SANDSTONE))


## A ring of stones, crossed logs, a flickering flame and its warm light.
func _campfire(at: Vector3) -> void:
	var stone_mat: Material = load(SANDSTONE)
	for i in 8:
		var a := TAU * i / 8.0
		var s := SphereMesh.new()
		s.radius = 0.11
		s.height = 0.16
		s.radial_segments = 6
		s.rings = 3
		_prop(s, Transform3D(Basis(Vector3.UP, a), at + Vector3(cos(a) * 0.42, 0.03, sin(a) * 0.42)), stone_mat)
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		var stick := CylinderMesh.new()
		stick.top_radius = 0.05
		stick.bottom_radius = 0.06
		stick.height = 0.62
		stick.radial_segments = 5
		stick.rings = 1
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, deg_to_rad(68.0))
		_prop(stick, Transform3D(b, at + Vector3(0, 0.12, 0)), load(WOOD))
	_fire = Node3D.new()
	_fire.name = "Campfire"
	_fire.set_script(load(FLICKER))
	var flame := MeshInstance3D.new()
	flame.name = "FlameMesh"
	flame.mesh = load(FLAME)
	flame.scale = Vector3.ONE * 1.25
	_fire.add_child(flame)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 0.5, 0)
	light.light_color = Color(1.0, 0.6, 0.3)
	light.light_energy = 1.7
	light.omni_range = 6.5
	_fire.add_child(light)
	World.area_node.add_child(_fire)
	_fire.global_position = at + Vector3(0, 0.08, 0)
	_actors.append(_fire)
	# Sparks drifting up.
	var p := CPUParticles3D.new()
	p.name = "Sparks"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.035)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	p.amount = 14
	p.lifetime = 1.6
	p.preprocess = 2.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.15
	p.direction = Vector3.UP
	p.spread = 20.0
	p.gravity = Vector3(0, 0.3, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 0.9
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	ramp.set_color(1, Color(1.0, 0.35, 0.1, 0.0))
	p.color_ramp = ramp
	World.area_node.add_child(p)
	p.global_position = at + Vector3(0, 0.35, 0)
	_actors.append(p)


## Sits them on the column: Aladriel on the left, Idrith leaning on her.
func _sit() -> void:
	# The walk up the dune may still be finishing off screen.
	_kill_tweens()
	for w in [_ala, _idr]:
		w.visible = true
		w.auto = false
		w.face(Vector2(_f.x, _f.z))
	_ala.global_position = _p(-SIDE, 0.0, 0.0)
	_idr.global_position = _p(SIDE, 0.0, 0.0)
	_ala.act(&"idle", 1.0, 0.0)
	_idr.act(&"idle", 1.0, 0.0)


# --- The scene ------------------------------------------------------------------

func _play(run: int) -> void:
	var idr := func(text: String, anim: StringName, blush := false) -> Dictionary:
		return {"text": text, "name": "Idrith", "actor": _idr, "anim": anim, "blush": blush}
	var ala := func(text: String, anim: StringName, blush := false) -> Dictionary:
		return {"text": text, "name": "Aladriel", "actor": _ala, "anim": anim, "blush": blush}
	# 1. The night sky over Ladhellin, then down to a campfire on the dunes.
	_cut(_p(-1.2, 1.6, -4.5), _p(1.5, 15.0, 14.0), 52.0)
	_glide(_p(-1.5, 1.7, -4.8), _p(0.0, 0.5, 1.2), 7.5)
	_tween().tween_property(self, "fade", 0.0, 2.0)
	_tween().tween_property(_amb2, "volume_db", -14.0, 6.0)
	if not await _wait(run, 4.0):
		return
	# 2. Up the dune hand in hand (walking side by side, a hand apart).
	var from := _p(-4.6, 0.0, -5.6)
	var to := _p(-0.4, 0.0, -1.1)
	var dir := (to - from).normalized()
	var side := Vector3(-dir.z, 0, dir.x) * (SIDE + 0.03)
	for w in [_ala, _idr]:
		w.visible = true
	_ala.global_position = from - side
	_idr.global_position = from + side
	_ala.settle()
	_idr.settle()
	_walk(_ala, _xz(to - side), 1.05)
	_walk(_idr, _xz(to + side), 1.05)
	if not await _wait(run, 3.6):
		return
	_cut(_p(3.6, 1.25, -0.4), _p(-1.2, 1.15, -4.2), 46.0)
	_glide(_p(3.5, 1.25, 0.2), _p(0.0, 1.1, -2.0), 5.0)
	if not await _say(run, [idr.call("Aladriel, look! You can see every single star tonight.", &"walk_hand")]):
		return
	# 3. The fire, close; then the two of them on the column, across it.
	_cut(_p(0.3, 0.45, 2.6), _p(0.0, 0.3, 1.55), 40.0)
	_sit()
	if not await _wait(run, 1.6):
		return
	_cut(_p(0.35, 1.0, 3.6), _p(0.0, 0.68, 0.0), 42.0)
	_glide(_p(0.25, 0.95, 3.1), _p(0.0, 0.7, 0.0), 14.0)
	if not await _wait(run, 1.0):
		return
	_ala.act(&"stargaze", 1.0, 0.4)
	if not await _say(run, [
		idr.call("The stars are so bright out here...\nYou never see them like this in Haven.", &"stargaze"),
		ala.call("Told you. Best sky in the whole kingdom. Ladhellin doesn't do anything halfway.", &"talk"),
	]):
		return
	_ala.act(&"idle", 1.0, 0.4)
	# 4. Closer: remembering the sandstorm.
	_cut(_p(-1.0, 1.0, 2.1), _p(0.1, 0.92, 0.0), 40.0)
	_glide(_p(-0.9, 1.0, 1.9), _p(0.1, 0.93, 0.0), 14.0)
	if not await _say(run, [
		idr.call("Do you remember *Dailah's* sandstorm? I thought we'd never see the sky again.", &"talk"),
		ala.call("Back to back, swords locked together.\nHard to forget.", &"talk"),
		idr.call("I was so scared... but you never once let go of my hand.", &"shy"),
	]):
		return
	_ala.act(&"lean_in", 1.0, 0.5)
	_idr.act(&"idle", 1.0, 0.4)
	if not await _say(run, [ala.call("And I never will. Whatever comes next, we face it together. Always.", &"lean_in")]):
		return
	# 5. A little kiss on the cheek.
	_cut(_p(0.25, 1.05, 1.9), _p(-0.05, 0.98, 0.0), 38.0)
	_idr.act(&"kiss", 1.0, 0.35)
	if not await _wait(run, 0.5):
		return
	Sfx.play("heart", -10.0, 0.0, 1.2)
	if not await _wait(run, 0.9):
		return
	_idr.act(&"shy", 1.0, 0.3)
	_ala.act(&"shy", 1.0, 0.25)
	_ala.model.set_blush(true)
	if not await _wait(run, 0.6):
		return
	if not await _say(run, [
		ala.call("...W-what was that for?", &"shy", true),
		idr.call("You were about to get grumpy.", &"talk", true),
		ala.call("...Was not.", &"shy", true),
	]):
		return
	_ala.act(&"idle", 1.0, 0.5)
	_idr.act(&"idle", 1.0, 0.5)
	# 6. From behind them: the fire, the oasis, the moon... and a shooting star.
	_cut(_p(-1.2, 1.15, -4.6), _p(0.3, 3.1, 12.0), 52.0)
	_glide(_p(-1.1, 1.15, -4.3), _p(0.3, 3.3, 12.0), 10.0)
	if not await _wait(run, 1.4):
		return
	_shooting_star(Vector2(MOON.x - 20.0, 25.0), Vector2(MOON.x + 16.0, 13.0), 1.1)
	Sfx.play("light_hum", -10.0, 0.0, 2.0)
	if not await _wait(run, 0.5):
		return
	_idr.act(&"stargaze", 1.0, 0.2)
	_ala.act(&"stargaze", 1.0, 0.3)
	if not await _say(run, [idr.call("Oh! A shooting star! Quick, Aladriel, make a wish!", &"stargaze")]):
		return
	# Across the fire again: she only has eyes for Idrith.
	_cut(_p(0.35, 1.0, 3.2), _p(0.0, 0.72, 0.0), 42.0)
	_ala.act(&"lean_in", 1.0, 0.3)
	_idr.act(&"idle", 1.0, 0.3)
	if not await _say(run, [ala.call("Nah. Don't need one.\nEverything I want is right here.", &"lean_in")]):
		return
	_idr.act(&"shy", 1.0, 0.3)
	_idr.model.set_blush(true)
	if not await _wait(run, 1.6):
		return
	# 7. Up to the stars, leaving them by the fire.
	_cut(_p(-0.8, 1.5, -3.4), _p(0.3, 1.4, 6.0), 50.0)
	_glide(_p(-1.5, 4.0, -6.5), _p(0.5, 10.0, 14.0), 7.0, 56.0)
	if not await _wait(run, 4.0):
		return
	await _end(run, 2.5)
