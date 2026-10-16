class_name LightMirror
extends StaticBody3D
## A great bronze mirror on a turning stand (the Spirit Temple's sun mirrors):
## light striking its face is sent on along the way it faces (-Z). A ("TURN")
## swings it round an eighth of a turn. With `fixed` it cannot be turned.

@export var fixed := false
## Eighths of a turn per press (negative turns it the other way).
@export var step := 1

var turning := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("light_mirrors")
	if not fixed:
		add_to_group("interactable")


## Where the light goes after striking it traveling along `d`; nothing if it
## came from behind.
func reflect(d: Vector3) -> Vector3:
	var face := -global_basis.z
	face.y = 0.0
	face = face.normalized()
	if d.dot(face) > 0.3:
		return Vector3.ZERO
	return face


func can_interact(_by: Node3D) -> bool:
	return not fixed and not turning


func interact_label() -> String:
	return "TURN"


func interact(_player: Node) -> void:
	if turning or fixed:
		return
	turning = true
	Sfx.play("lift_rock", -4.0, 0.05, 0.8)
	var t := create_tween()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(self, "rotation:y", rotation.y + PI / 4.0 * step, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: turning = false)
