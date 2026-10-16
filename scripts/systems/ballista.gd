class_name Ballista
extends Node3D
## The gatehouse ballista of Haven Village (the Siege of Haven, Chapter IV):
## stand behind it and press A (MAN) to take it. The view goes behind the
## great bow; the stick swings and tilts it, B looses a bolt (one every
## RELOAD seconds), and A again lets go. Bolts break siege towers (three
## each), skewer goblin archers and war boars, and fly a long way.

const RELOAD := 1.1
const YAW_LIMIT := 1.1
const PITCH_MIN := -0.45
const PITCH_MAX := 0.25
const TURN := 1.4
const BOLT_SPEED := 48.0
const BOLT_DAMAGE := 8

var manned := false
var _turret: Node3D
var _cam: Camera3D
var _yaw := 0.0
var _pitch := -0.12
var _reload := 0.0
var _hud: CanvasLayer
var _player: PlayerController


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("ballistas")
	var base := MeshInstance3D.new()
	base.mesh = load("res://assets/models/ballista_base_mesh.tres") if ResourceLoader.exists("res://assets/models/ballista_base_mesh.tres") else null
	add_child(base)
	_turret = Node3D.new()
	_turret.name = "Turret"
	_turret.position = Vector3(0, 1.1, 0)
	add_child(_turret)
	var arms := MeshInstance3D.new()
	arms.mesh = load("res://assets/models/ballista_mesh.tres") if ResourceLoader.exists("res://assets/models/ballista_mesh.tres") else null
	_turret.add_child(arms)
	_cam = Camera3D.new()
	_cam.name = "BallistaCamera"
	_cam.position = Vector3(0, 0.9, 2.4)
	_cam.fov = 55.0
	_turret.add_child(_cam)


func can_interact(by: Node3D) -> bool:
	if manned:
		return false
	# From behind it (its back is +Z).
	var local := to_local(by.global_position)
	return local.z > 0.3


func interact_reach() -> float:
	return 2.2


func interact_label() -> String:
	return "MAN"


func interact(player: Node) -> void:
	var p := player as PlayerController
	if p == null or manned:
		return
	_player = p
	manned = true
	p.begin_talk(self)
	p.global_position = global_transform * Vector3(0, 0.0, 1.5)
	p.face_direction(-global_basis.z)
	_cam.make_current()
	_hud = CanvasLayer.new()
	_hud.layer = 2
	var cross := BallistaCross.new()
	cross.ballista = self
	_hud.add_child(cross)
	get_tree().root.add_child(_hud)
	Sfx.play("menu_select", -4.0)


func leave() -> void:
	if not manned:
		return
	manned = false
	if is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null
	if is_instance_valid(_player):
		if _player.camera_rig and _player.camera_rig.camera:
			_player.camera_rig.camera.make_current()
		_player.end_talk()
	_player = null


func _physics_process(delta: float) -> void:
	_reload = maxf(_reload - delta, 0.0)
	if not manned:
		return
	if not is_instance_valid(_player) or _player.is_dead() or GameManager.state != GameManager.GameState.PLAYING:
		leave()
		return
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_yaw = clampf(_yaw - v.x * TURN * delta, -YAW_LIMIT, YAW_LIMIT)
	_pitch = clampf(_pitch - v.y * TURN * 0.6 * delta, PITCH_MIN, PITCH_MAX)
	_turret.rotation = Vector3(_pitch, _yaw, 0)
	if Input.is_action_just_pressed("attack"):
		fire()
	elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("pause"):
		leave()


## Looses a bolt along the turret's aim (false while it reloads).
func fire() -> bool:
	if _reload > 0.0:
		return false
	_reload = RELOAD
	var bolt := BallistaBolt.new()
	get_parent().add_child(bolt)
	var dir := -_turret.global_basis.z
	bolt.launch(_turret.global_position + dir * 1.0 + Vector3.UP * 0.35, dir)
	Sfx.play("ballista_fire", 0.0, 0.05)
	GameManager.rumble(0.5, 0.15)
	return true


func aim_dir() -> Vector3:
	return -_turret.global_basis.z


func set_aim(yaw: float, pitch: float) -> void:
	_yaw = clampf(yaw, -YAW_LIMIT, YAW_LIMIT)
	_pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)
	_turret.rotation = Vector3(_pitch, _yaw, 0)


func reload_left() -> float:
	return _reload


## The ballista's bolt: a heavy shaft flying straight and falling a little.
class BallistaBolt extends Node3D:
	var velocity := Vector3.ZERO
	var _life := 2.5

	func _ready() -> void:
		var mi := MeshInstance3D.new()
		mi.mesh = load("res://assets/models/ballista_bolt_mesh.tres") if ResourceLoader.exists("res://assets/models/ballista_bolt_mesh.tres") else null
		add_child(mi)

	func launch(from: Vector3, dir: Vector3) -> void:
		global_position = from
		velocity = dir.normalized() * BOLT_SPEED
		look_at(from + velocity, Vector3.UP)

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		velocity.y -= 4.0 * delta
		var from := global_position
		var to := from + velocity * delta
		var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
		q.collide_with_areas = true
		var p := GameManager.player
		if p:
			q.exclude = [p.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			global_position = to
			look_at(to + velocity, Vector3.UP)
			return
		var c: Object = hit.collider
		if c is SiegeTower:
			(c as SiegeTower).bolt_hit()
		elif c is Hurtbox and (c as Hurtbox).receiver != p:
			var info := HitInfo.new()
			info.damage = BOLT_DAMAGE
			info.knockback = 8.0
			info.heavy = true
			info.attacker = p
			info.source_position = from
			(c as Hurtbox).receive_hit(info)
		Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), hit.position, 6, 2.5, 2.5, 0.5, 0.5, Color(0.5, 0.4, 0.3))
		Sfx.play("arrow_stick", -2.0, 0.05, 0.6)
		queue_free()


## The sight drawn over the view while manning it: a ring, and the reload bar.
class BallistaCross extends Control:
	var ballista: Ballista

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := GameManager.screen_rect()
		var c := r.get_center()
		var col := Color(1.0, 0.9, 0.6, 0.85)
		draw_arc(c, 9.0, 0.0, TAU, 20, col, 1.0)
		draw_line(c - Vector2(14, 0), c - Vector2(5, 0), col, 1.0)
		draw_line(c + Vector2(5, 0), c + Vector2(14, 0), col, 1.0)
		draw_line(c - Vector2(0, 14), c - Vector2(0, 5), col, 1.0)
		draw_line(c + Vector2(0, 5), c + Vector2(0, 14), col, 1.0)
		if ballista:
			var k := 1.0 - ballista.reload_left() / RELOAD
			draw_rect(Rect2(c.x - 20, c.y + 20, 40, 3), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(c.x - 20, c.y + 20, 40 * k, 3), col)
		PixelFont.draw_centered(self, c.x, r.end.y - 22, "B FIRE   A LEAVE", Color(1, 1, 1, 0.9))
