class_name TempleBell
extends StaticBody3D
## The great bronze bell over the Bell Hall's pool. The node sits where it hangs
## from its chain; its mesh swings about that point like a pendulum.
##
## An arrow or the boomerang strikes it: it swings away from the blow and tolls.
## Three tolls in a row (each within TOLL_WINDOW of the last) shake loose the
## offerings the shrine's builders hid in its crown, once (`flag`): a shower of
## rupees over the hall, with the secret jingle.

## Seconds allowed between tolls of one run of three.
const TOLL_WINDOW := 6.0
const TOLLS := 3
## Pendulum: natural frequency (rad/s, a 2.5 m bell) and damping (1/s).
const OMEGA := 2.0
const DAMPING := 0.45
## Swing (radians per second) a blow adds.
const KICK := 0.55
## Rupees in the shower, and how widely they fall round the bell (meters).
const SHOWER := ["rupee_red", "rupee_blue", "rupee_blue", "rupee_blue", "rupee_blue",
	"rupee_green", "rupee_green", "rupee_green", "rupee_green", "rupee_green",
	"rupee_green", "rupee_green", "rupee_green", "rupee_green", "rupee_green"]
const SHOWER_RADIUS := Vector2(5.2, 8.5)

@export var flag := ""

## Tolls in the current run, and seconds since the last one.
var tolls := 0
var since_toll := INF
## Swing as a rotation vector (horizontal axis times angle) and its rate.
var swing := Vector3.ZERO
var swing_rate := Vector3.ZERO
var _mesh: Node3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("bells")
	_mesh = get_node_or_null("Mesh")
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.0
	cyl.height = 3.6
	cs.shape = cyl
	cs.position = Vector3(0, -1.9, 0)
	cs.set_meta("no_climb", true)
	add_child(cs)


func arrow_hit(arrow: Node3D, _point: Vector3) -> void:
	strike(arrow.global_position)


func boomerang_hit(b: Node3D) -> void:
	strike(b.global_position)


## A blow from `from`: the bell swings away from it and tolls.
func strike(from: Vector3) -> void:
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	# Turning about UP x away by a negative angle carries the rim along `away`.
	swing_rate += Vector3.UP.cross(away.normalized()) * -KICK
	Sfx.play("target_bell", 2.0, 0.0, 0.3)
	Sfx.play("target_bell", -6.0, 0.0, 0.45)
	GameManager.rumble(0.25, 0.3)
	tolls = tolls + 1 if since_toll <= TOLL_WINDOW else 1
	since_toll = 0.0
	if tolls >= TOLLS and flag != "" and not Progress.flag(flag):
		Progress.set_flag(flag)
		_shower.call_deferred()


func _physics_process(delta: float) -> void:
	since_toll += delta
	swing_rate += (-swing * OMEGA * OMEGA - swing_rate * DAMPING) * delta
	swing += swing_rate * delta
	if _mesh:
		var angle := swing.length()
		_mesh.basis = Basis(swing / angle, angle) if angle > 0.0001 else Basis.IDENTITY


## The offerings come loose: rupees rain down round the bell.
func _shower() -> void:
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	Sfx.play("puzzle_solved", -3.0, 0.0)
	var parent := get_parent()
	for i in SHOWER.size():
		var a := TAU * i / SHOWER.size() + randf_range(-0.2, 0.2)
		var r := randf_range(SHOWER_RADIUS.x, SHOWER_RADIUS.y)
		var p := global_position + Vector3(cos(a) * r, -4.0, sin(a) * r)
		Drops.spawn(SHOWER[i], p, parent, true)
		await get_tree().create_timer(0.06).timeout
		if not is_inside_tree():
			return
