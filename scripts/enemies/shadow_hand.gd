class_name ShadowHand
extends Enemy
## A hand of DENANGDYN'S SHADOW, reaching through Firebuns III in the last
## battle's third phase (Beta 1.5.0; Bongo Bongo's hands in z_boss_sst.c lend
## the pattern). Two of them, left and right of the shadow-wrapped king:
## - it hovers over the hero, rises, and SLAMS down (its shadow on the floor
##   warns); then it lies STUCK a moment, its palm-eye open: one blow of a
##   blade that carries Avalon's starlight stuns it;
## - it SWEEPS across the floor at hip height; a well-timed Parry stuns it
##   too (any other guard is simply knocked back).
## It cannot be killed. With both hands stunned at once, the king is laid
## bare (FirebunsFinal reads `stunned()`).

enum State { WAIT, HOVER, RAISE, SLAM, STUCK, SWEEP_WINDUP, SWEEP, STUNNED, GONE }

## -1 left, 1 right of the king, as seen from where the hero comes in.
@export var side := 1.0

const HOVER_H := 4.0
const SLAM_DAMAGE := 3
const SWEEP_DAMAGE := 2
const STUN_TIME := 6.0
const STUCK_TIME := 2.2

var state := State.WAIT
var king: Node3D = null
var _t := 0.0
var _plan := 1.5
var _mark: MeshInstance3D
var _floor_y := 0.0
var _sweep_from := Vector3.ZERO
var _sweep_to := Vector3.ZERO
var _hit_this := false


func _ready() -> void:
	corpse_time = 0.5
	super._ready()
	add_to_group("bosses")
	add_to_group("shadow_hands")
	_floor_y = global_position.y
	_mark = MeshInstance3D.new()
	_mark.name = "SlamMark"
	_mark.mesh = load("res://assets/models/blob_shadow_mesh.tres")
	_mark.top_level = true
	_mark.visible = false
	add_child(_mark)
	visible = false
	_set_hurtbox(false)
	collision_layer = 0


## The third phase begins: the hands come.
func wake(by: Node3D) -> void:
	king = by
	visible = true
	_set_hurtbox(true)
	_plan = 0.8 + (0.6 if side > 0.0 else 0.0)
	_go(State.HOVER)


func stunned() -> bool:
	return state == State.STUNNED


func is_targetable() -> bool:
	return visible and state in [State.STUCK, State.STUNNED, State.SWEEP_WINDUP]


## Gone with the shadow (the last blow).
func vanish() -> void:
	_go(State.GONE)
	_mark.visible = false
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 0.05, 0.8)
	t.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if state in [State.WAIT, State.GONE]:
		return
	_t += delta
	var p := _player()
	var alive := p != null and not p.is_dead() and not p.in_cutscene
	match state:
		State.HOVER:
			model.play(&"idle", 0.2)
			if alive:
				var over := Vector3(p.global_position.x + side * 1.5, _floor_y + HOVER_H, p.global_position.z)
				global_position = global_position.lerp(over, minf(delta * 2.2, 1.0))
			if _t >= _plan and alive and not Cutscene.active:
				_go(State.RAISE if randf() < 0.6 else State.SWEEP_WINDUP)
		State.RAISE:
			global_position.y = move_toward(global_position.y, _floor_y + HOVER_H + 1.2, delta * 3.0)
			_show_mark()
			if _t >= 0.7:
				_go(State.SLAM)
		State.SLAM:
			global_position.y = move_toward(global_position.y, _floor_y + 0.1, delta * 22.0)
			if global_position.y <= _floor_y + 0.15:
				_slam_land(p)
				_go(State.STUCK)
		State.STUCK:
			if _t >= STUCK_TIME:
				_plan = randf_range(1.2, 2.2)
				_go(State.HOVER)
		State.SWEEP_WINDUP:
			var c := king.global_position if is_instance_valid(king) else global_position
			_sweep_from = Vector3(c.x + side * 9.0, _floor_y + 0.8, c.z + 6.0)
			_sweep_to = Vector3(c.x - side * 9.0, _floor_y + 0.8, c.z + 6.0)
			if alive:
				_sweep_from.z = p.global_position.z
				_sweep_to.z = p.global_position.z
			global_position = global_position.lerp(_sweep_from, minf(delta * 4.0, 1.0))
			if _t >= 0.9:
				_hit_this = false
				_go(State.SWEEP)
		State.SWEEP:
			global_position = _sweep_from.lerp(_sweep_to, clampf(_t / 0.9, 0.0, 1.0))
			if alive and not _hit_this and global_position.distance_to(p.global_position + Vector3.UP * 0.8) < 1.6:
				_hit_this = true
				var info := HitInfo.new()
				info.damage = SWEEP_DAMAGE
				info.knockback = 9.0
				info.attacker = self
				info.source_position = global_position - (_sweep_to - _sweep_from).normalized()
				p.take_hit(info)
			if _t >= 0.9:
				_plan = randf_range(1.0, 2.0)
				_go(State.HOVER)
		State.STUNNED:
			global_position.y = move_toward(global_position.y, _floor_y + 0.1, delta * 4.0)
			if _t >= STUN_TIME:
				_plan = 1.0
				_go(State.HOVER)


func _show_mark() -> void:
	_mark.visible = true
	_mark.global_position = Vector3(global_position.x, _floor_y + 0.05, global_position.z)
	_mark.scale = Vector3.ONE * 3.4


func _slam_land(p: PlayerController) -> void:
	_mark.visible = false
	Sfx.play("mallet_smash", 0.0, 0.05, 0.6)
	GameManager.rumble(0.8, 0.3)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position, 12, 3.0, 2.0, 0.6, 0.8, Color(0.5, 0.35, 1.0))
	if p and not p.is_dead() and Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length() < 1.9 and absf(p.global_position.y - _floor_y) < 1.5:
		var info := HitInfo.new()
		info.damage = SLAM_DAMAGE
		info.knockback = 8.0
		info.unblockable = true
		info.attacker = self
		info.source_position = global_position
		p.take_hit(info)


func _go(s: State) -> void:
	state = s
	_t = 0.0
	match s:
		State.RAISE:
			model.play(&"raise", 0.1, 1.0, true)
		State.SLAM:
			model.play(&"slam", 0.02, 1.0, true)
		State.STUCK:
			model.play(&"idle", 0.2)
		State.SWEEP_WINDUP:
			model.play(&"raise", 0.1, 1.0, true)
			Sfx.play("heavy_swing", -6.0, 0.05, 0.5)
		State.SWEEP:
			Sfx.play("heavy_swing", 0.0, 0.05, 0.6)
		State.STUNNED:
			model.play(&"stunned", 0.1)
			Sfx.play("ward_out", 0.0, 0.0, 0.5)
			Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 0.6, 14, 3.0, 3.0, 0.6, 0.8, Color(1.4, 1.4, 2.0))


## Only starlight wounds the shadow: the Bun Sword with Avalon's blessing.
func _guard(info: HitInfo) -> int:
	if state != State.STUCK or not (info.attacker is PlayerController) or not Progress.flag("rift:blessed"):
		Sfx.play("shield_block", -4.0, 0.06, 0.5)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT


func take_hit(info: HitInfo) -> int:
	var r := _guard(info)
	if r == Hurtbox.Result.HIT:
		model.flash(Color(1.0, 1.0, 1.4), 0.1)
		_go(State.STUNNED)
	return r


## A Parry turns the sweep: the hand reels, stunned.
func parried(_by: Node3D) -> void:
	if state in [State.SWEEP, State.SWEEP_WINDUP]:
		_go(State.STUNNED)


func daze(_seconds: float, _ice := false) -> void:
	pass


func stun(_seconds: float) -> void:
	pass
