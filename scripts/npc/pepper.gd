class_name Pepper
extends Node3D
## Pepper, Posy's little dog (Chapter IV side quest, "Where is Pepper?"). He
## ran off when the refugees fled the field, and hides under a cart in a
## goblin war camp, barking when anyone comes near. Found (A: CALL), he
## trots at the hero's heels (flag "pepper:found"), from area to area, until
## he sees Posy in the refuge: then he runs to her ("pepper:home").
##
## One Pepper node stands where he hides (field_war) and one in the refuge;
## while he is following, whichever is in the area comes to the hero.
##
## Years later (Chapter V, `grown`): Pepper all grown up, gray round the
## muzzle and twice the size, lives with Posy in Castle Town (and found his
## own way home long ago if nobody brought him). While the hero is in town he
## trots along at his heels, and now and then stops, sniffs and digs up a
## Rupee. A: PET, or ask him to stay put ("pepper:stay") or come along.

const FOUND := "pepper:found"
const HOME := "pepper:home"
const FOLLOW_GAP := 1.8
const SPEED := 5.5

## The one at Posy's side in the refuge (shown once he is home).
@export var home := false
## Chapter V: the grown-up Pepper in town (see the top of this file).
@export var grown := false
const STAY := "pepper:stay"
const DIG_EVERY := Vector2(35.0, 70.0)
var _dig := 40.0
var _digging := 0.0

var model: CharacterModel
var _bark := 2.0
var _t := 0.0


func _ready() -> void:
	if grown:
		if not Progress.flag("ch5:knight"):
			queue_free()
			return
		var gps := load("res://assets/models/pepper.tscn") as PackedScene
		if gps:
			model = gps.instantiate() as CharacterModel
			model.name = "Model"
			model.scale = Vector3.ONE * 1.35
			add_child(model)
			model.set_tint(Color(0.9, 0.88, 0.86))
		add_to_group("interactable")
		_dig = randf_range(DIG_EVERY.x, DIG_EVERY.y)
		return
	if Progress.flag("ch5:knight"):
		# Years later he lives in Castle Town (the grown-up one).
		queue_free()
		return
	var placed := home and Progress.flag(HOME)
	var hiding := not home and not Progress.flag(FOUND)
	var following := Progress.flag(FOUND) and not Progress.flag(HOME)
	if not (placed or hiding or following):
		queue_free()
		return
	var ps := load("res://assets/models/pepper.tscn") as PackedScene
	if ps:
		model = ps.instantiate() as CharacterModel
		model.name = "Model"
		add_child(model)
	add_to_group("interactable")
	if following:
		# Whichever Pepper is in this area comes to the hero (the other goes).
		_join_hero.call_deferred()


func _join_hero() -> void:
	for n in get_tree().get_nodes_in_group("pepper"):
		if n != self:
			queue_free()
			return
	add_to_group("pepper")
	var p := GameManager.player
	if is_instance_valid(p):
		global_position = p.global_position - p.forward() * FOLLOW_GAP


func can_interact(_by: Node3D) -> bool:
	if grown:
		return _digging <= 0.0
	return not Progress.flag(FOUND) or (home and Progress.flag(HOME))


func interact_reach() -> float:
	return 1.6


func interact_label() -> String:
	return "CALL" if not Progress.flag(FOUND) else "PET"


func interact(player: Node) -> void:
	if Dialogue.active:
		return
	if grown:
		_grown_talk(player as PlayerController)
		return
	var p := player as PlayerController
	if p:
		p.begin_talk(self)
	Sfx.play("dog_bark", -2.0, 0.05)
	if model:
		model.play(&"bark", 0.05, 1.0, true)
	if not Progress.flag(FOUND):
		Progress.set_flag(FOUND)
		Dialogue.start(["A scruffy little black-and-tan dog crawls out from under the cart, his tail going like mad. His collar says *PEPPER*.",
			"Pepper wants to come with you! He'll follow you all the way home to Haven Village."], self)
		add_to_group("pepper")
	else:
		Dialogue.start(["Pepper rolls over for a belly rub. Good boy."], self)
	await Dialogue.finished
	if p and is_instance_valid(p):
		p.end_talk()


func _physics_process(delta: float) -> void:
	_t += delta
	var p := GameManager.player
	if not is_instance_valid(p) or model == null:
		return
	if grown:
		_grown_update(p, delta)
		return
	if not Progress.flag(FOUND):
		# Hiding: a bark now and then while the hero is near.
		_bark -= delta
		if _bark <= 0.0 and p.global_position.distance_to(global_position) < 20.0:
			_bark = randf_range(3.0, 6.0)
			Sfx.play("dog_bark", -6.0, 0.08)
			model.play(&"bark", 0.05, 1.0, true)
		elif not model.anim.is_playing() or model.current_anim == &"bark" and _bark < 2.5:
			model.play(&"idle", 0.2)
		return
	if Progress.flag(HOME):
		_settle(delta)
		return
	# Following: run to Posy once she is in sight, else keep at the hero's heels.
	var posy := _posy()
	if posy and posy.global_position.distance_to(global_position) < 14.0:
		_run_to(posy.global_position + Vector3(0.9, 0, 0.6), delta)
		if Vector2(posy.global_position.x - global_position.x, posy.global_position.z - global_position.z).length() < 1.6:
			Progress.set_flag(HOME)
			Sfx.play("dog_bark", -2.0, 0.05)
			model.play(&"bark", 0.05, 1.0, true)
		return
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() > 25.0:
		global_position = p.global_position - p.forward() * FOLLOW_GAP
	elif to.length() > FOLLOW_GAP:
		_run_to(p.global_position, delta)
	else:
		model.play(&"idle", 0.2)


func _posy() -> Node3D:
	if not is_instance_valid(World.area_node):
		return null
	return World.area_node.find_child("Posy", true, false) as Node3D


func _run_to(target: Vector3, delta: float) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.3:
		model.play(&"idle", 0.2)
		return
	var step := to.normalized() * minf(SPEED * delta, to.length())
	global_position += step
	rotation.y = atan2(-to.x, -to.z)
	# Keep to the ground.
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 2.0, global_position + Vector3.DOWN * 4.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		global_position.y = hit.position.y
	model.play(&"run", 0.15)


## Home at Posy's side: a happy bark for the hero now and then.
func _settle(delta: float) -> void:
	_bark -= delta
	var p := GameManager.player
	if _bark <= 0.0 and is_instance_valid(p) and p.global_position.distance_to(global_position) < 6.0:
		_bark = randf_range(5.0, 9.0)
		Sfx.play("dog_bark", -6.0, 0.08, 1.1)
		model.play(&"bark", 0.05, 1.0, true)
		var to := p.global_position - global_position
		rotation.y = atan2(-to.x, -to.z)
	elif model.current_anim != &"bark" or not model.anim.is_playing():
		model.play(&"idle", 0.2)


# --- All grown up (Chapter V) ----------------------------------------------------

func _grown_talk(p: PlayerController) -> void:
	if p:
		p.begin_talk(self)
	Sfx.play("dog_bark", -4.0, 0.05, 0.8)
	if model:
		model.play(&"bark", 0.05, 0.8, true)
	var staying := Progress.flag(STAY)
	Dialogue.start([{"text": "Pepper, gray round the muzzle now, leans his whole weight against your leg and thumps his tail on the cobbles.",
		"choices": [["Pet him", ["Good boy. The best boy. He agrees."]],
			["Come along, Pepper!" if staying else "Stay here, Pepper.", [("Pepper's ears go up. He's coming with you!" if staying else "Pepper sits down with a sigh. He'll wait right here.")]]]}], self)
	await Dialogue.finished
	if Dialogue.last_choice.begins_with("Come along"):
		Progress.flags.erase(STAY)
		Progress.changed.emit()
	elif Dialogue.last_choice.begins_with("Stay here"):
		Progress.set_flag(STAY)
	if p and is_instance_valid(p):
		p.end_talk()


func _grown_update(p: PlayerController, delta: float) -> void:
	if _digging > 0.0:
		_digging -= delta
		if _digging <= 0.0:
			_dig_up()
		return
	if Progress.flag(STAY) or p.is_riding():
		_settle(delta)
		return
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() > 30.0:
		global_position = p.global_position - p.forward() * FOLLOW_GAP * 1.4
	elif to.length() > FOLLOW_GAP * 1.4:
		_run_to(p.global_position, delta)
		model.anim.speed_scale = 0.85
	else:
		_settle(delta)
	# Now and then a good spot to dig.
	_dig -= delta
	if _dig <= 0.0 and to.length() < 6.0:
		_dig = randf_range(DIG_EVERY.x, DIG_EVERY.y)
		_digging = 1.6
		model.play(&"bark", 0.05, 0.5, true)
		Sfx.play("dig", -6.0, 0.1, 1.3)


func _dig_up() -> void:
	Sfx.play("dog_bark", -4.0, 0.05)
	Fragments.burst(get_parent(), load("res://assets/models/rock_chip_mesh.tres"), global_position + Vector3.UP * 0.2, 8, 2.0, 2.5, 0.4, 0.5, Color(0.35, 0.26, 0.18))
	var drop: String = ["rupee_green", "rupee_green", "rupee_blue", "rupee_red"][randi() % 4]
	Drops.spawn(drop, global_position - global_basis.z * 0.6 + Vector3.UP * 0.3, get_parent(), true)
