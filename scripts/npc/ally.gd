class_name Ally
extends Node3D
## A friend who fights at the hero's side (the Siege of Haven): Aladriel with
## her giant sword holds the east of the wall, Idrith with her two scimitars
## the west. Each keeps to her side (`side`: -1 west, +1 east of x = 0) and
## inside the palisade (z > `wall_z`), runs at the nearest goblin there,
## and cuts it down (DAMAGE a blow, every COOLDOWN). With nothing to fight
## she returns to her post and stands guard. She cannot fall.
##
## Beta 1.4.0: the knights of Haven on Black Water Ridge. An ally with a
## `camp_flag` stands by one of Mara's camps (once the road to the Ridge is
## open) and fights while the hero is near and the camp is not yet broken,
## anything within `leash` of its post; `hero_sword` puts one of the hero's
## sword meshes in its fist.

const SPEED := 4.2
const REACH := 1.7
const COOLDOWN := 1.1
const DAMAGE := 2

@export var model_scene := ""
@export var weapon_mesh := ""
@export var side := 1.0
@export var wall_z := -38.0
@export var leash := 18.0
@export var camp_flag := ""
@export var hero_sword := ""

var model: CharacterModel
var active := false
var _post := Vector3.ZERO
var _cool := 0.0
var _swing := -1.0
var _target: Enemy


func _ready() -> void:
	# They stand on Haven's wall only for the siege; the knights on the Ridge
	# once the road there is open.
	if camp_flag == "" and not Siege.active():
		queue_free()
		return
	if camp_flag != "" and not Progress.flag("ch5:ridge_open"):
		queue_free()
		return
	add_to_group("allies")
	_post = global_position
	var ps := load(model_scene) as PackedScene if model_scene != "" else null
	if ps:
		model = ps.instantiate() as CharacterModel
		model.name = "Model"
		add_child(model)
		for hand_name in (["HandR", "HandL"] if weapon_mesh.contains("scimitar") else ["HandR"]):
			CharacterModel.grip_weapon(model.find_child(hand_name, true, false) as Node3D, weapon_mesh)
		var fist := model.find_child("HandR", true, false) as Node3D
		if hero_sword != "" and fist and ResourceLoader.exists(Equipment.sword_mesh(hero_sword)):
			var blade := MeshInstance3D.new()
			blade.name = "Sword"
			blade.mesh = load(Equipment.sword_mesh(hero_sword))
			blade.position = Vector3(0, -0.06, 0)
			fist.add_child(blade)
		model.play(&"guard", 0.0)


## Her side of the village (and inside the wall); a knight's camp.
func covers(p: Vector3) -> bool:
	if camp_flag != "":
		return _post.distance_to(p) < leash and absf(p.y - _post.y) < 4.0
	return signf(p.x) == side and p.z > wall_z + 0.3 and _post.distance_to(p) < leash


func _physics_process(delta: float) -> void:
	if model == null:
		return
	_cool = maxf(_cool - delta, 0.0)
	if camp_flag != "":
		var p := GameManager.player
		active = not Progress.flag(camp_flag) and is_instance_valid(p) and _post.distance_to(p.global_position) < leash + 6.0
	if _swing >= 0.0:
		_swing += delta
		if _swing >= 0.3 and _swing - delta < 0.3:
			_strike()
		if _swing >= 0.6:
			_swing = -1.0
		return
	if not active:
		_walk_to(_post, delta)
		return
	if not is_instance_valid(_target) or _target.is_dead() or not covers(_target.global_position):
		_target = _pick()
	if _target == null:
		_walk_to(_post, delta)
		return
	var to := _target.global_position - global_position
	to.y = 0.0
	if to.length() > REACH:
		_walk_to(_target.global_position, delta)
	else:
		rotation.y = atan2(-to.x, -to.z)
		if _cool <= 0.0:
			_swing = 0.0
			_cool = COOLDOWN
			model.play(&"swing", 0.05, 1.0, true)
			Sfx.play("heavy_swing" if side > 0.0 else "sword_swing", -6.0, 0.08)
		else:
			model.play(&"guard", 0.15)


func _pick() -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var en := e as Enemy
		if en == null or en.is_dead() or en.is_in_group("bosses") or not covers(en.global_position):
			continue
		var d := en.global_position.distance_to(global_position)
		if d < best_d:
			best = en
			best_d = d
	return best


func _strike() -> void:
	if not is_instance_valid(_target) or _target.is_dead():
		return
	if _target.global_position.distance_to(global_position) > REACH + 0.8:
		return
	var info := HitInfo.new()
	info.damage = DAMAGE
	info.knockback = 6.0
	info.attacker = self
	info.source_position = global_position
	_target.take_hit(info)
	Sfx.play("sword_hit", -4.0, 0.08)


func _walk_to(target: Vector3, delta: float) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.25:
		model.play(&"guard" if active else &"stand", 0.2)
		if not active:
			rotation.y = lerp_angle(rotation.y, 0.0, 0.1)
		return
	var step := to.normalized() * minf(SPEED * delta, to.length())
	var next := global_position + step
	if camp_flag == "":
		next.z = maxf(next.z, wall_z + 0.6)
	global_position = next
	rotation.y = atan2(-to.x, -to.z)
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.0, global_position + Vector3.DOWN * 3.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position.y = hit.position.y
	model.play(&"walk", 0.15, 1.3)


func go_home() -> void:
	active = false
	_target = null
	global_position = _post
