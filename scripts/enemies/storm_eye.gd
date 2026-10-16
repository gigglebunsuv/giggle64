extends Enemy
## Aeolos, the Storm Eye: master of Skyreach Spire, a living storm that has
## made the summit its throne. Its heart is one great eye, sealed in a shell
## of four plates of storm-cloud ice.
##
## Built round the tower's treasure, as OoT's bosses are round theirs:
## - It circles over the summit flinging icicles (the shield turns them).
## - Then its plates open like petals and it blows a gale across the summit,
##   hard enough to sweep the hero over the edge, unless he stands firm in
##   the Wind Boots. Only while it blows is its eye bare: an arrow (or the
##   Hookshot) in the eye brings it crashing down, dazed, open to the sword.
## - Half beaten its gales grow fiercer and it flings icicles as it blows.

enum State { WAIT, WAKE, DRIFT, GALE_WINDUP, GALE, STUNNED, RISE, DEAD }

const TITLE := "AEOLOS"
const SUBTITLE := "THE STORM EYE"
const CIRCLE_R := 8.0
const HOVER := 5.0
const GALE := 9.0

@export var notice_range := 12.0

var state := State.WAIT
var _t := 0.0
var _angle := 0.0
var _centre := Vector3.ZERO
var _floor_y := 0.0
var _thrown := 0.0
var _phase2 := false
var _hits := 0
var _gale_dir := Vector3.FORWARD


func _ready() -> void:
	corpse_time = 2.5
	super._ready()
	add_to_group("bosses")
	_centre = global_position
	_floor_y = global_position.y
	global_position.y = _floor_y + HOVER
	if attack_hitbox:
		attack_hitbox.damage = 3
		attack_hitbox.knockback = 8.0


func _snap_to_ground() -> void:
	_home = global_position


func is_stunned() -> bool:
	return state == State.STUNNED


func eye_open() -> bool:
	return state in [State.GALE_WINDUP, State.GALE]


## Which way its gale blows across the summit right now (none when calm).
func gale() -> Vector3:
	return _gale_dir * (GALE * (1.3 if _phase2 else 1.0)) if state == State.GALE else Vector3.ZERO


func _guard(info: HitInfo) -> int:
	if state == State.STUNNED:
		return Hurtbox.Result.HIT
	if state == State.WAIT:
		return Hurtbox.Result.IGNORED
	# An arrow (nothing else reaches it up there) into the bare eye.
	if eye_open() and info.attacker is PlayerController:
		_struck()
		return Hurtbox.Result.BLOCKED
	Sfx.play("armor_clang", -4.0, 0.08, 1.3)
	return Hurtbox.Result.BLOCKED


func _hurt(_info: HitInfo) -> void:
	Sfx.play("boss_hurt", -4.0, 0.05, 1.3)
	_hits += 1
	if not _phase2 and health.health <= health.max_health / 2:
		_phase2 = true
	if _hits >= 3:
		_go(State.RISE)


func arrow_hit(_arrow: Node3D, _point: Vector3) -> void:
	_struck()


func hookshot_hit(_h: Node3D) -> void:
	_struck()


## An arrow or the chain into the bare eye.
func _struck() -> void:
	if eye_open() and not _dead:
		Sfx.play("boss_hurt", -2.0, 0.05, 0.9)
		_go(State.STUNNED)


func _physics_process(delta: float) -> void:
	_t += delta
	velocity = Vector3.ZERO
	if _dead:
		global_position.y = move_toward(global_position.y, _floor_y + 0.6, delta * 3.0)
		return
	var p := _player()
	var alive := p != null and not p.is_dead()
	match state:
		State.WAIT:
			if alive and _flat_dist(p.global_position) < notice_range and absf(p.global_position.y - _floor_y) < 3.0:
				_go(State.WAKE)
		State.WAKE:
			global_position.y = _floor_y + HOVER + sin(_t * 2.0) * 0.3
			if _t >= 2.4:
				_go(State.DRIFT)
		State.DRIFT:
			_angle += delta * (0.8 if _phase2 else 0.55)
			var want := _centre + Vector3(cos(_angle) * CIRCLE_R, HOVER + sin(_t * 1.7) * 0.4, sin(_angle) * CIRCLE_R)
			global_position = global_position.lerp(want, clampf(delta * 2.0, 0.0, 1.0))
			if alive:
				_turn_to(p.global_position, 200.0, delta)
				_thrown += delta
				if _thrown >= (1.0 if _phase2 else 1.4):
					_thrown = 0.0
					_icicle(p)
			if _t >= 5.0:
				_go(State.GALE_WINDUP)
		State.GALE_WINDUP:
			if alive:
				_turn_to(p.global_position, 200.0, delta)
			if _t >= 0.9:
				_go(State.GALE)
		State.GALE:
			# The gale blows from the eye across the summit.
			if alive:
				var d := p.global_position - global_position
				d.y = 0.0
				_gale_dir = d.normalized() if d.length() > 0.1 else -_forward()
				p.wind_push += gale()
				if _phase2:
					_thrown += delta
					if _thrown >= 1.2:
						_thrown = 0.0
						_icicle(p)
			if _t >= 4.0:
				_go(State.DRIFT)
		State.STUNNED:
			var down := Vector3(global_position.x, _floor_y + 1.0, global_position.z)
			global_position = global_position.lerp(down, clampf(delta * 6.0, 0.0, 1.0))
			if _t >= 4.0:
				_go(State.RISE)
		State.RISE:
			var up := Vector3(global_position.x, _floor_y + HOVER, global_position.z)
			global_position = global_position.lerp(up, clampf(delta * 3.0, 0.0, 1.0))
			if _t >= 1.0:
				_go(State.DRIFT)
	rotation.y = facing_yaw


func _icicle(p: PlayerController) -> void:
	var f := Feather.new()
	f.mesh_path = "res://assets/models/icicle_mesh.tres"
	get_parent().add_child(f)
	var from := global_position + _forward() * 1.6
	f.launch(from, (p.global_position + Vector3.UP * 1.0) - from, self)
	Sfx.play("boomerang_throw", -4.0, 0.08, 1.4)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.WAKE:
			model.play(&"open", 0.2, 1.0, true)
			Sfx.play("boss_roar", 0.0, 0.0, 1.5)
			Cutscene.boss_intro(self, TITLE, SUBTITLE, "boss_battle", 0.0, 9.0)
		State.DRIFT:
			_thrown = 0.0
			model.play(&"closed", 0.2)
		State.GALE_WINDUP:
			model.play(&"open", 0.15, 1.0, true)
			Sfx.play("sand_hiss", -2.0, 0.05, 0.6)
		State.GALE:
			model.play(&"gale", 0.1)
			Sfx.play("boss_roar", -4.0, 0.05, 1.8)
		State.STUNNED:
			_hits = 0
			model.play(&"stunned", 0.1)
			Sfx.play("boss_stomp", -2.0)
		State.RISE:
			model.play(&"closed", 0.2)


func _die() -> void:
	state = State.DEAD
	Sfx.play("boss_die", 0.0)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 30, 5.0, 6.0, 2.0, 2.0, Color(0.85, 0.95, 1.3))
	super._die()
