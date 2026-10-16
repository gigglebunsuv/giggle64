extends Enemy
## Kherash, the Sand Devourer: master of Ladhellin Tower, a great armored
## wyrm that swims through the sand of the Sun Chamber's floor.
##
## Built round the tower's treasure, as OoT's bosses are round theirs:
## - It hunts under the sand (only a moving mound and a hiss show where), then
##   bursts up some way from the hero and rears, swaying, its one great eye
##   glaring. If he does nothing it lunges, jaws wide, and dives again.
## - Its armor turns the sword. But it cannot bear the sun: the hero stands
##   in the light falling through the chamber's oculus and throws it into the
##   rearing wyrm's eye with the Mirror Shield. Blinded, it crashes down onto
##   the sand, dazed, and its head is open to the sword.
## - Half beaten it hunts faster, rears for less time and spits sand.
##
## The scene's root is the head; the body is a chain of segments arching from
## where it broke the surface up to the head.

enum State { WAIT, ROAR, BURROWED, SURFACE, REAR, SPIT, LUNGE, DIVE, STUNNED, RISE, DEAD }

const TITLE := "KHERASH"
const SUBTITLE := "THE SAND DEVOURER"
const SEGMENTS := 7
const SEGMENT_SCENE := "res://assets/models/wyrm_segment.tscn"
const REAR_HEIGHT := 2.3
const LIGHT_NEEDED := 0.3

@export var notice_range := 11.0
## The arena it swims in: its center (where it was placed) and radius.
@export var arena_radius := 12.0

var state := State.WAIT
var stunned_time := 0.0
var _t := 0.0
var _floor_y := 0.0
var _centre := Vector3.ZERO
## Where it broke the surface, and where the mound under the sand is.
var _hole := Vector3.ZERO
var _mound := Vector3.ZERO
var _light := 0.0
var _phase2 := false
var _lunge_from := Vector3.ZERO
var _lunge_to := Vector3.ZERO
var _segs: Array[Node3D] = []
var _mound_mesh: MeshInstance3D
var _dust := 0.0
var _hits := 0


func _ready() -> void:
	corpse_time = 2.5
	super._ready()
	add_to_group("bosses")
	_centre = global_position
	_floor_y = global_position.y
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 9.0
	var seg_scene: PackedScene = load(SEGMENT_SCENE) if ResourceLoader.exists(SEGMENT_SCENE) else null
	for i in SEGMENTS:
		var s: Node3D = seg_scene.instantiate() if seg_scene else Node3D.new()
		s.name = "Segment%d" % i
		s.top_level = true
		var k := 1.0 - float(i) / SEGMENTS * 0.45
		s.scale = Vector3.ONE * k
		add_child(s)
		_segs.append(s)
	_mound_mesh = MeshInstance3D.new()
	_mound_mesh.name = "Mound"
	var sph := SphereMesh.new()
	sph.radius = 1.3
	sph.height = 1.0
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.86, 0.72, 0.48)
	sph.material = m
	_mound_mesh.mesh = sph
	_mound_mesh.top_level = true
	add_child(_mound_mesh)
	_hole = _centre
	_set_hidden(true)


## It is placed on the sand; no settling.
func _snap_to_ground() -> void:
	_home = global_position


func is_targetable() -> bool:
	return state in [State.REAR, State.SPIT, State.LUNGE, State.STUNNED, State.RISE] and super.is_targetable()


func is_stunned() -> bool:
	return state == State.STUNNED


func light_hit(delta: float, _dir: Vector3) -> void:
	if _dead or not (state in [State.REAR, State.SPIT, State.SURFACE]):
		return
	_light += delta
	if _light >= LIGHT_NEEDED:
		_light = 0.0
		Sfx.play("boss_hurt", -2.0, 0.05, 0.8)
		_go(State.STUNNED)


## Armor turns the sword unless it lies stunned.
func _guard(_info: HitInfo) -> int:
	if state == State.STUNNED:
		return Hurtbox.Result.HIT
	if state in [State.WAIT, State.BURROWED, State.DIVE]:
		return Hurtbox.Result.IGNORED
	Sfx.play("armor_clang", -4.0, 0.08)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -4.0, 0.05)
	_hits += 1
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	if _hits >= 3:
		_go(State.RISE)


func _physics_process(delta: float) -> void:
	_t += delta
	velocity = Vector3.ZERO
	if _dead:
		global_position.y = move_toward(global_position.y, _floor_y + 0.4, delta * 2.0)
		_place_body()
		return
	var p := _player()
	var alive := p != null and not p.is_dead()
	match state:
		State.WAIT:
			if alive and _flat_dist(p.global_position) < notice_range and absf(p.global_position.y - _floor_y) < 3.0:
				_hole = _centre
				_go(State.ROAR)
		State.ROAR:
			_rise_to(minf(_t / 0.8, 1.0))
			if alive:
				_face(p, delta, 300.0)
			if _t >= 2.4:
				_go(State.DIVE)
		State.BURROWED:
			# The mound runs under the sand to a spot some way from the hero.
			var goal := _surface_spot(p)
			var to := goal - _mound
			to.y = 0.0
			var speed := 7.5 if _phase2 else 5.5
			_mound += to.normalized() * minf(speed * delta, to.length())
			_mound_mesh.global_position = Vector3(_mound.x, _floor_y - 0.25 + sin(_t * 12.0) * 0.05, _mound.z)
			_dust -= delta
			if _dust <= 0.0:
				_dust = 0.15
				Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), _mound + Vector3.UP * 0.2, 3, 1.5, 2.0, 0.6, 0.3, Color(0.9, 0.78, 0.5))
			if _t >= (1.6 if _phase2 else 2.4) and to.length() < 0.5:
				_hole = _mound
				_go(State.SURFACE)
		State.SURFACE:
			_rise_to(minf(_t / 0.5, 1.0))
			if alive:
				_face(p, delta, 400.0)
			if _t >= 0.5:
				_go(State.REAR)
		State.REAR:
			_rise_to(1.0)
			if alive:
				_face(p, delta, 120.0)
			# A slow sway, as a cobra's.
			global_position += global_basis.x * sin(_t * 2.2) * 0.4 * delta
			if _phase2 and _t >= 0.8 and _t - delta < 0.8:
				_spit(p)
			if _t >= (1.9 if _phase2 else 2.8):
				_go(State.LUNGE)
		State.LUNGE:
			var k := clampf(_t / 0.35, 0.0, 1.0)
			global_position = _lunge_from.lerp(_lunge_to, k * (2.0 - k))
			if attack_hitbox and _t >= 0.05 and _t < 0.4 and not attack_hitbox.active:
				attack_hitbox.activate()
			if _t >= 0.6:
				_go(State.DIVE)
		State.DIVE:
			_sink(minf(_t / 0.5, 1.0))
			if _t >= 0.5:
				_go(State.BURROWED)
		State.STUNNED:
			stunned_time += delta
			var down := Vector3(global_position.x, _floor_y + 0.75, global_position.z)
			global_position = global_position.lerp(down, clampf(delta * 8.0, 0.0, 1.0))
			if _t >= 3.6:
				_go(State.RISE)
		State.RISE:
			_rise_to(minf(_t / 0.6, 1.0))
			if _t >= 0.6:
				_go(State.DIVE)
	_place_body()
	rotation.y = facing_yaw


func _face(p: PlayerController, delta: float, rate: float) -> void:
	_turn_to(p.global_position, rate, delta)


## Some way from the hero (5-9 m), inside the arena.
func _surface_spot(p: PlayerController) -> Vector3:
	if p == null:
		return _centre
	var from := p.global_position
	var away := Vector3(_mound.x - from.x, 0, _mound.z - from.z)
	if away.length() < 0.1:
		away = Vector3(1, 0, 0)
	var spot := from + away.normalized() * 7.0
	var off := Vector3(spot.x - _centre.x, 0, spot.z - _centre.z)
	if off.length() > arena_radius - 2.0:
		spot = _centre + off.normalized() * (arena_radius - 2.0)
	spot.y = _floor_y
	return spot


## Head up out of the hole, `k` of the way to its rearing height.
func _rise_to(k: float) -> void:
	var up := _hole + Vector3.UP * lerpf(-1.5, REAR_HEIGHT, k * (2.0 - k))
	global_position = Vector3(global_position.x, up.y, global_position.z) if state == State.REAR else up


func _sink(k: float) -> void:
	global_position = global_position.lerp(_hole + Vector3.DOWN * 2.0, clampf(k, 0.0, 1.0))


## The body arches from the hole up to the head.
func _place_body() -> void:
	var base := _hole + Vector3.DOWN * 1.0
	var head := global_position
	var ctrl := (base + head) * 0.5 + Vector3.UP * 1.6 - _forward() * 1.4
	for i in _segs.size():
		var t := 1.0 - float(i + 1) / (_segs.size() + 1)
		var a := base.lerp(ctrl, t)
		var b := ctrl.lerp(head, t)
		var pt := a.lerp(b, t)
		var s := _segs[i]
		s.global_position = pt
		var tangent := (b - a).normalized()
		if tangent.length() > 0.1:
			s.global_basis = Basis.looking_at(tangent, Vector3.UP if absf(tangent.y) < 0.95 else Vector3.BACK).scaled(s.scale)
		s.visible = model.visible and pt.y > _floor_y - 0.6


func _set_hidden(on: bool) -> void:
	if model:
		model.visible = not on
	_mound_mesh.visible = on and state == State.BURROWED
	_set_hurtbox(not on)


func _spit(p: PlayerController) -> void:
	if p == null:
		return
	var r := Rock.new()
	get_parent().add_child(r)
	var from := global_position + _forward() * 1.4
	r.launch(from, p.global_position - from, self)
	Sfx.play("snap", -2.0, 0.05, 0.6)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	if attack_hitbox and s != State.LUNGE:
		attack_hitbox.deactivate()
	match s:
		State.ROAR:
			_set_hidden(false)
			model.play(&"roar", 0.05, 1.0, true)
			Sfx.play("boss_roar", 0.0, 0.0, 0.7)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 1.5, 9.0)
		State.BURROWED:
			_mound = Vector3(global_position.x, _floor_y, global_position.z)
			_set_hidden(true)
			_mound_mesh.visible = true
			Sfx.play("sand_hiss", -4.0, 0.1)
		State.SURFACE:
			_mound_mesh.visible = false
			_set_hidden(false)
			global_position = _hole + Vector3.DOWN * 1.5
			model.play(&"rear", 0.1)
			Sfx.play("splash_big", -2.0, 0.05, 0.5)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), _hole + Vector3.UP * 0.4, 14, 3.0, 4.0, 1.2, 0.6, Color(0.9, 0.78, 0.5))
		State.REAR:
			_light = 0.0
			model.play(&"rear", 0.1)
		State.LUNGE:
			model.play(&"bite", 0.03, 1.0, true)
			Sfx.play("boss_roar", -4.0, 0.05, 1.3)
			_lunge_from = global_position
			var p := _player()
			var to := (p.global_position + Vector3.UP * 0.8) if p else global_position + _forward() * 5.0
			var d := to - _lunge_from
			_lunge_to = _lunge_from + d.normalized() * minf(d.length(), 7.0)
		State.DIVE:
			model.play(&"rear", 0.1)
		State.STUNNED:
			_hits = 0
			stunned_time = 0.0
			model.play(&"stunned", 0.08)
			Sfx.play("boss_stomp", -2.0)
		State.RISE:
			model.play(&"rear", 0.1)


func _die() -> void:
	state = State.DEAD
	_mound_mesh.visible = false
	Sfx.play("boss_die", 0.0)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 24, 4.0, 5.0, 2.0, 2.0, Color(0.85, 0.7, 0.45))
	super._die()
