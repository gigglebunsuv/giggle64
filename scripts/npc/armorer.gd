class_name Armorer
extends Npc
## Pink at her anvil: while nobody talks to her she works a blade, and every
## blow of her hammer (0.55 s into her "idle" loop) rings the anvil and
## throws a few sparks. Talking to her stops the work.

const STRIKE_TIME := 0.55

var _last_pos := 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if model == null or talking or model.current_anim != &"idle":
		_last_pos = 0.0
		return
	var pos := model.anim.current_animation_position
	if _last_pos < STRIKE_TIME and pos >= STRIKE_TIME:
		_strike()
	_last_pos = pos


func _strike() -> void:
	var anvil := global_transform * Vector3(0, 0.78, -0.62)
	var near := GameManager.player != null and GameManager.player.global_position.distance_to(global_position) < 14.0
	if near:
		Sfx.play("anvil", -9.0, 0.06)
	Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), anvil, 5, 2.2, 1.6, 0.35, 0.25, Color(2.0, 1.2, 0.3))
