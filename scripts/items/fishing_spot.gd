class_name FishingSpot
extends Node3D
## Fishing off the end of Mira's dock, a little after OoT's fishing pond
## (ovl_Fishing): fish swim as shadows under the water, the float bobs when
## one nibbles and dips when it bites; hook it then and reel it in without
## snapping the line. The biggest fish of the lake weighs over ten pounds.
##
## Mira lends the rod (flag `rod_flag`). Standing at the end of the dock, A
## ("FISH") takes it out:
##   READY   stick turns the cast; hold A to wind up, release to cast; B puts the rod away
##   WAIT    the float sits in the water; hold A to reel it slowly in (fish follow a
##           moving lure), B reels all the way back
##   (a nibble bobs the float; the bite pulls it under for a moment: press A!)
##   HOOKED  hold A to reel in; while the fish is pulling hard, let go or the
##           line snaps; if it gets too far away it slips the hook
## A catch is held up and weighed. The heaviest is remembered (`Progress.fish_record`);
## one over ten pounds sets `big_flag` (Mira has a prize for that).
##
## With the Fishing Rod (an item since 1.6.0) the hero fishes from any shore:
## `from_shore` makes a roaming spot where he stands, with a few smaller fish
## in the water ahead, and it goes away when he puts the rod down.

signal caught(pounds: int)

## The kinds of fish in Haven's waters (Progress.fish_records keeps the best of
## each; Mira pins them up on her wall). Mirror Lake has perch and carp, and
## its lords; rivers and ponds elsewhere have their own.
const SPECIES := {
	"perch": "MIRROR PERCH", "carp": "HAVEN CARP", "lunker": "LAKE LORD",
	"trout": "SNOWMELT TROUT", "catfish": "BOG CATFISH", "icefish": "FROSTFIN",
	# The black tarn in the Batela Fells (Beta 1.1.0): gray as the ash.
	"ashfin": "TARN ASHFIN",
	# Cinderhold's hot spring (Beta 1.3.0): red as a coal, happy in near-boiling water.
	"cinderfin": "CINDERFIN",
}
const SPECIES_ORDER := ["perch", "carp", "lunker", "trout", "catfish", "icefish", "ashfin", "cinderfin"]

enum Phase { OFF, READY, CAST, WAIT, HOOKED, LANDED }

@export var rod_flag := "mira_rod"
@export var big_flag := "lake:big_fish"
## The water surface height.
@export var water_y := 0.0
## Where the fish live: center (relative to this node, along its -Z) and radius.
@export var pond_distance := 11.0
@export var pond_radius := 8.0
@export var fish_count := 5

## The fishing spot currently in use (the HUD reads it), or null.
static var current: FishingSpot = null
## Made by the Fishing Rod on the spot (smaller fish; freed when done).
var roaming := false

var phase := Phase.OFF
var charge := 0.0
var _charging := false
var aim := 0.0
## Line tension while a fish is hooked (0..1; snaps after holding at 1).
var tension := 0.0
var _player: PlayerController
var _float: MeshInstance3D
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _fish: Array = []
var _hooked: Dictionary = {}
var _cast_from := Vector3.ZERO
var _cast_to := Vector3.ZERO
var _t := 0.0
var _bite := 0.0
var _nibble := 0.0
var _strain := 0.0
var _pull := 0.0
var _pull_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if not roaming:
		add_to_group("interactable")
	add_to_group("fishing_spots")
	_rng.randomize()
	_float = MeshInstance3D.new()
	_float.name = "Float"
	_float.mesh = load("res://assets/models/fishing_float_mesh.tres")
	_float.top_level = true
	_float.visible = false
	add_child(_float)
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.name = "Line"
	_line.mesh = _line_mesh
	_line.top_level = true
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.92, 0.92, 0.95)
	_line.material_override = lm
	add_child(_line)
	for i in fish_count:
		_spawn_fish(i == 0)


func _exit_tree() -> void:
	if current == self:
		current = null


## A fish: its shadow mesh, a weight in pounds and a wandering target.
func _spawn_fish(lord: bool) -> void:
	var f := MeshInstance3D.new()
	f.name = "Fish%d" % _fish.size()
	f.mesh = load("res://assets/models/fish_shadow_mesh.tres")
	f.top_level = true
	add_child(f)
	var pounds := _rng.randi_range(11, 13) if lord else (_rng.randi_range(1, 6) if roaming else _rng.randi_range(2, 8))
	# Now and then the lake's true lord is about: fourteen pounds or more.
	if lord and _rng.randf() < 0.3:
		pounds = _rng.randi_range(14, 15)
	var size := 0.35 + pounds * 0.045
	f.scale = Vector3.ONE * size
	var fish := {"node": f, "pounds": pounds, "goal": _pond_point(), "speed": 1.2 - pounds * 0.04, "scared": 0.0}
	f.global_position = fish.goal
	_fish.append(fish)


func _pond_centre() -> Vector3:
	var c := global_transform * Vector3(0, 0, -pond_distance)
	c.y = water_y - 0.45
	return c


func _pond_point() -> Vector3:
	var area := World.area_node if is_instance_valid(World.area_node) else null
	var pt := _pond_centre()
	for i in 8:
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * pond_radius
		pt = _pond_centre() + Vector3(cos(a) * d, 0, sin(a) * d)
		# A roaming spot keeps its fish in the water.
		if not roaming or area == null or not is_nan(Surface.water_level(area, pt)):
			break
	return pt


func can_interact(_by: Node3D) -> bool:
	return phase == Phase.OFF and (Progress.flag(rod_flag) or Progress.has_item("fishing_rod"))


## A fishing spot where `player` stands, facing open water a few steps ahead
## (deep enough that the lure will not touch the bottom), or null.
static func from_shore(player: PlayerController) -> FishingSpot:
	var area := World.area_node if is_instance_valid(World.area_node) else null
	if area == null or player.is_swimming():
		return null
	var here := Surface.water_level(area, player.global_position)
	if not is_nan(here) and here > player.global_position.y + 0.05:
		return null
	var fwd := player.forward()
	var space := player.get_world_3d().direct_space_state
	for d in [2.0, 3.0, 4.0, 5.5, 7.0]:
		var pt: Vector3 = player.global_position + fwd * d
		var wy := Surface.water_level(area, pt)
		if is_nan(wy) or wy > player.global_position.y + 0.3:
			continue
		var q := PhysicsRayQueryParameters3D.create(Vector3(pt.x, wy + 0.1, pt.z), Vector3(pt.x, wy - 1.0, pt.z), 1)
		if not space.intersect_ray(q).is_empty():
			continue
		var spot := FishingSpot.new()
		spot.name = "ShoreFishing"
		spot.roaming = true
		spot.rod_flag = ""
		spot.big_flag = ""
		spot.water_y = wy
		spot.pond_distance = d + 4.0
		spot.pond_radius = 4.0
		spot.fish_count = 3
		spot.transform = area.global_transform.affine_inverse() * Transform3D(Basis.looking_at(fwd, Vector3.UP), player.global_position)
		area.add_child(spot)
		return spot
	return null


func interact_label() -> String:
	return "FISH"


func interact(player: Node) -> void:
	if phase != Phase.OFF or not (player is PlayerController):
		return
	_player = player as PlayerController
	_player.begin_talk(null)
	_player.face_direction(-global_basis.z)
	_player.set_fishing(true)
	current = self
	aim = 0.0
	_set_phase(Phase.READY)
	charge = 0.0


func _set_phase(p: Phase) -> void:
	phase = p
	_t = 0.0
	_charging = false


func _stop() -> void:
	_float.visible = false
	_line_mesh.clear_surfaces()
	if _hooked:
		_release(_hooked)
	_hooked = {}
	var p := _player
	_player = null
	current = null
	_set_phase(Phase.OFF)
	if is_instance_valid(p):
		p.set_fishing(false)
		# Let go of him next frame, so the B that put the rod away doesn't
		# also swing the sword.
		await get_tree().physics_frame
		if is_instance_valid(p):
			p.end_talk()
	if roaming:
		queue_free()


func rod_tip() -> Vector3:
	if is_instance_valid(_player):
		return _player.rod_tip()
	return global_position + Vector3.UP * 2.0


func _physics_process(delta: float) -> void:
	_t += delta
	_swim(delta)
	if phase == Phase.OFF:
		return
	if not is_instance_valid(_player) or _player.is_dead():
		_stop()
		return
	var a_held := Input.is_action_pressed("interact")
	var b := Input.is_action_just_pressed("attack")
	match phase:
		Phase.READY:
			var stick := Input.get_axis("move_left", "move_right")
			aim = clampf(aim - stick * delta * 1.2, -0.7, 0.7)
			_player.face_direction(Basis(Vector3.UP, aim) * -global_basis.z)
			# The wind-up starts with a fresh press of A (not the one that took
			# the rod out or closed a message) and casts on letting go.
			if _charging:
				if a_held:
					charge = minf(charge + delta / 1.2, 1.0)
				else:
					_cast()
			elif Input.is_action_just_pressed("interact") and _t > 0.05:
				_charging = true
				charge = 0.0
			if b:
				_stop()
				return
		Phase.CAST:
			var k := clampf(_t / 0.7, 0.0, 1.0)
			var p := _cast_from.lerp(_cast_to, k)
			p.y += sin(k * PI) * (1.5 + charge * 2.5)
			_float.global_position = p
			if k >= 1.0:
				Sfx.play("step_water_0", -6.0, 0.05, 1.3)
				_set_phase(Phase.WAIT)
		Phase.WAIT:
			_wait(delta, a_held, b)
		Phase.HOOKED:
			_fight(delta, a_held)
		Phase.LANDED:
			pass
	_draw_line()


func _cast() -> void:
	var dir := _player.forward()
	_cast_from = rod_tip()
	_cast_to = global_position + dir * (4.0 + charge * 14.0)
	_cast_to.y = water_y + 0.02
	_float.visible = true
	_float.global_position = _cast_from
	Sfx.play("boomerang_throw", -6.0, 0.05, 1.4)
	_bite = 0.0
	_nibble = 0.0
	_set_phase(Phase.CAST)


## The float sits in the water: reel it in with A, a fish may come to it.
func _wait(delta: float, a_held: bool, b: bool) -> void:
	var fp := _float.global_position
	var home := global_position + Vector3(0, water_y - global_position.y + 0.02, 0)
	if b or (a_held and Vector2(fp.x - home.x, fp.z - home.z).length() < 1.2):
		_reset_cast()
		return
	if a_held:
		var to := home - fp
		to.y = 0.0
		fp += to.normalized() * minf(to.length(), 1.6 * delta)
		if fmod(_t, 0.2) < delta:
			Sfx.play("rupee_tick", -22.0, 0.1, 0.5)
	var dip := 0.0
	if _bite > 0.0:
		_bite -= delta
		dip = -0.12
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
			_hook()
			return
		if _bite <= 0.0:
			# Too slow: it got away with the bait.
			_scare_biter()
	elif _nibble > 0.0:
		_nibble -= delta
		dip = -0.04 * absf(sin(_t * 18.0))
		if a_held and _nibble > 0.3:
			_scare_biter()
		elif _nibble <= 0.0:
			_bite = 0.7
			Sfx.play("splash_big", -10.0, 0.05, 1.6)
			GameManager.rumble(0.3, 0.15)
	fp.y = water_y + 0.02 + dip + sin(_t * 2.0) * 0.01
	_float.global_position = fp


func _reset_cast() -> void:
	_float.visible = false
	_scare_biter()
	charge = 0.0
	_set_phase(Phase.READY)


func _biter() -> Dictionary:
	for f in _fish:
		if f.get("biting", false):
			return f
	return {}


func _scare_biter() -> void:
	var f := _biter()
	if f:
		f.biting = false
		f.scared = 4.0
		f.goal = _pond_point()
	_nibble = 0.0
	_bite = 0.0


func _hook() -> void:
	_hooked = _biter()
	if not _hooked:
		return
	_hooked.biting = false
	_hooked.dist = Vector2(_float.global_position.x - global_position.x, _float.global_position.z - global_position.z).length()
	_hooked.dir = Vector2(_float.global_position.x - global_position.x, _float.global_position.z - global_position.z).normalized()
	tension = 0.0
	_strain = 0.0
	_pull = 0.0
	_pull_time = 0.5
	Sfx.play("snap", -4.0, 0.05, 1.3)
	GameManager.rumble(0.6, 0.25)
	_set_phase(Phase.HOOKED)


## The fight: the fish pulls in spells (bigger fish harder), A reels it in.
func _fight(delta: float, a_held: bool) -> void:
	var f := _hooked
	var strength: float = 0.4 + f.pounds * 0.08
	_pull_time -= delta
	if _pull_time <= 0.0:
		var pulling := _pull <= 0.0
		_pull = strength if pulling else 0.0
		_pull_time = _rng.randf_range(0.8, 1.6) if pulling else _rng.randf_range(0.9, 1.8)
		if pulling:
			f.dir = f.dir.rotated(_rng.randf_range(-0.6, 0.6))
	# It swims off while pulling; reeling between pulls brings it in. Reeling
	# against a pull gains less and strains the line.
	var reel := 2.6 if a_held else 0.0
	f.dist += (_pull * 1.2 - reel * (1.0 - minf(_pull, 1.0) * 0.6)) * delta
	var want := _pull if a_held else _pull * 0.25
	tension = move_toward(tension, clampf(want, 0.0, 1.0), delta * 3.0)
	if tension > 0.85:
		_strain += delta
		GameManager.rumble(0.2, 0.05)
	else:
		_strain = maxf(_strain - delta * 2.0, 0.0)
	if _strain > 1.0:
		_lose("The line snapped!")
		return
	if f.dist > pond_distance + pond_radius + 6.0:
		_lose("It slipped the hook...")
		return
	var p: Vector3 = global_position + Vector3(f.dir.x, 0, f.dir.y) * f.dist
	p.y = water_y + 0.02 - (0.1 if _pull > 0.0 else 0.03)
	_float.global_position = p
	(f.node as Node3D).global_position = Vector3(p.x, water_y - 0.4, p.z)
	if f.dist < 1.6:
		_land(f)


func _lose(why: String) -> void:
	_release(_hooked)
	_hooked = {}
	_float.visible = false
	_set_phase(Phase.LANDED)
	Sfx.play("error", -4.0)
	Dialogue.start([why], null)
	await Dialogue.finished
	if phase == Phase.LANDED:
		charge = 0.0
		_set_phase(Phase.READY)


func _release(f: Dictionary) -> void:
	if f:
		f.scared = 6.0
		f.goal = _pond_point()


## The kind of a `pounds` fish caught here.
func species_for(pounds: int) -> String:
	var area := World.area_id
	if not roaming or area == "lake":
		return "lunker" if pounds >= 10 else ("carp" if pounds >= 6 else "perch")
	match area:
		"marsh", "bog_tower":
			return "catfish"
		"snow", "cliffs", "skyreach_spire":
			return "icefish"
		"batela_fells":
			return "ashfin"
		"cinderhold":
			return "cinderfin"
	return "trout"


## Landed: weighed, shown, let go (a new fish comes to the pond later).
func _land(f: Dictionary) -> void:
	_hooked = {}
	_float.visible = false
	_set_phase(Phase.LANDED)
	var pounds: int = f.pounds
	_fish.erase(f)
	(f.node as Node3D).queue_free()
	var record := Progress.fish_record
	var kind := species_for(pounds)
	var kind_best := int(Progress.fish_records.get(kind, 0))
	var kind_record := Progress.record_fish(kind, pounds)
	# The Mirror Lake record (Mira's prizes) counts only the lake's fish.
	var at_lake := not roaming or World.area_id == "lake"
	if pounds > record and at_lake:
		Progress.fish_record = pounds
	var big := pounds >= 10 and not Progress.flag(big_flag)
	if pounds >= 10:
		Progress.set_flag(big_flag)
	caught.emit(pounds)
	var held := MeshInstance3D.new()
	held.mesh = load("res://assets/models/fish_mesh.tres")
	held.scale = Vector3.ONE * (0.35 + pounds * 0.045)
	held.rotation = Vector3(0, PI / 2.0, 0)
	_player.add_child(held)
	held.position = Vector3(0, 1.9, -0.3)
	Sfx.play("fanfare_item", -2.0, 0.0)
	var text: Array = ["You caught a *%d-pound %s*!" % [pounds, String(SPECIES[kind]).capitalize()]]
	if kind_record and kind_best > 0:
		text.append("That's a new record for that kind! (The old one was %d pounds.)" % kind_best)
	elif pounds > record and record > 0 and at_lake:
		text.append("That's a new lake record! (The old one was %d pounds.)" % record)
	if big:
		text.append("What a monster! Mira will want to see this... Go and tell her!")
	elif at_lake and ((pounds >= 12 and Progress.scale < 1) or (pounds >= 14 and Progress.scale < 2)):
		text.append("A real giant! Mira should hear about this one...")
	# With an empty bottle along, the catch can go into it (OoT's bottled
	# fish); otherwise, or by choice, it goes back into the water.
	var empty := Progress.bottles.find("empty")
	if empty >= 0:
		text.append({"text": "What will you do with it?", "choices": [
			["Put it in a bottle", ["You put the fish in an *empty bottle*!
Let it out by water and it will swim away."]],
			["Let it go", ["You let it go back into the water."]],
		]})
	else:
		text.append("You let it go back into the water.")
	Dialogue.start(text, null)
	await Dialogue.finished
	if empty >= 0 and Dialogue.last_choice == "Put it in a bottle" and Progress.bottle(empty) == "empty":
		Progress.set_bottle(empty, "fish")
		Sfx.play("bottle_catch", -2.0, 0.0)
	held.queue_free()
	# Another fish soon wanders in to take its place.
	_spawn_fish(false)
	if phase == Phase.LANDED:
		charge = 0.0
		_set_phase(Phase.READY)


## The fish wander about the pond; a calm one near a still float comes to
## nibble at it.
func _swim(delta: float) -> void:
	var lure := _float.global_position
	var lure_out := phase == Phase.WAIT and _bite <= 0.0 and _nibble <= 0.0 and not _biter()
	for f in _fish:
		if f == _hooked:
			continue
		var n := f.node as Node3D
		f.scared = maxf(f.scared - delta, 0.0)
		var goal: Vector3 = f.goal
		if lure_out and f.scared <= 0.0 and Vector2(lure.x - n.global_position.x, lure.z - n.global_position.z).length() < 5.0:
			goal = Vector3(lure.x, water_y - 0.4, lure.z)
			if Vector2(lure.x - n.global_position.x, lure.z - n.global_position.z).length() < 0.6:
				f.biting = true
				_nibble = _rng.randf_range(0.8, 2.6)
				lure_out = false
		var to := goal - n.global_position
		to.y = 0.0
		if to.length() < 0.3 and not f.get("biting", false):
			f.goal = _pond_point()
		elif to.length() > 0.05:
			var speed: float = f.speed * (2.0 if f.scared > 0.0 else 1.0)
			n.global_position += to.normalized() * minf(to.length(), speed * delta)
			n.rotation.y = atan2(-to.x, -to.z)


## The line from the rod tip to the float, sagging a little.
func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	if not _float.visible:
		return
	var a := rod_tip()
	var b := _float.global_position + Vector3(0, 0.08, 0)
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 9:
		var k := i / 8.0
		var p := a.lerp(b, k)
		p.y -= sin(k * PI) * (0.4 if phase != Phase.HOOKED else 0.05)
		_line_mesh.surface_add_vertex(p)
	_line_mesh.surface_end()


## The A button's word while fishing.
func a_label() -> String:
	match phase:
		Phase.READY:
			return "CAST"
		Phase.WAIT, Phase.HOOKED:
			return "REEL"
	return ""


## The hint along the bottom of the screen while fishing (Glyphs tokens).
func hint(_pad := true) -> String:
	match phase:
		Phase.READY:
			return "{MOVE} AIM  HOLD {A} CAST  {B} DONE"
		Phase.WAIT:
			return "HOLD {A} REEL  BITE: {A}  {B} REEL IN"
		Phase.HOOKED:
			return "HOLD {A} REEL IN  LET GO WHEN IT PULLS!"
	return ""
