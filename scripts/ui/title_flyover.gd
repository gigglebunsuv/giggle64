class_name TitleFlyover
extends Node
## The title screen's backdrop: Sir Gigglebuns out walking through Haven,
## a few areas in turn, each filmed with a slow camera of its own and cut
## together with short fades through black (OoT's title has Link riding
## Epona across Hyrule Field). The areas are loaded by the World autoload
## with the real hero hidden; the tree stays paused throughout, so this node
## walks a stand-in model of its own (TitleWalker) along the ground.

## Each shot: the area, the walk (from and to, x/z), when the walk ends (a
## fraction of the shot; he stands and looks about after), and the camera.
## The camera's two points (start and end of the shot) are in the walk's own
## frame: x = to his right, y = up from the ground he stands on, z = ahead.
## "follow" cameras move with him; "fixed" ones are placed from the walk's
## start and turn to keep him in view. "ahead" aims the camera that far in
## front of him (looking where he is going), "look" is the aim's height.
const SHOTS := [
	{"area": "village", "from": Vector2(0, -34), "to": Vector2(0, -19), "stop": 0.85,
		"mode": "follow", "cam": [Vector3(2.4, 1.3, 4.6), Vector3(-2.2, 1.9, 5.4)], "look": 1.1},
	{"area": "field", "from": Vector2(-5, 88), "to": Vector2(-5, 72),
		"mode": "fixed", "cam": [Vector3(7.5, 1.6, 15.0), Vector3(8.5, 2.6, 17.0)], "look": 1.4},
	{"area": "castle_town", "from": Vector2(0, 37), "to": Vector2(0, 22),
		"mode": "follow", "cam": [Vector3(-1.4, 1.5, -4.2), Vector3(1.6, 2.4, -6.0)], "look": 2.0, "ahead": 10.0},
	{"area": "lake", "from": Vector2(-59, -45), "to": Vector2(-44, -45), "stop": 0.9,
		"mode": "fixed", "cam": [Vector3(-6.5, 1.6, 3.0), Vector3(-5.0, 2.2, 12.0)], "look": 1.2},
	{"area": "forest", "from": Vector2(20, 49), "to": Vector2(20, 34),
		"mode": "follow", "cam": [Vector3(1.3, 0.8, 3.6), Vector3(-1.6, 1.3, 4.2)], "look": 1.2},
	{"area": "desert", "from": Vector2(-54, -15), "to": Vector2(-39, -15),
		"mode": "fixed", "cam": [Vector3(6.0, 3.5, 19.0), Vector3(9.0, 2.6, 19.0)], "look": 1.2},
	{"area": "southern_fields", "from": Vector2(25, -44), "to": Vector2(25, -30), "stop": 0.85,
		"mode": "follow", "cam": [Vector3(4.2, 1.2, 1.5), Vector3(3.8, 1.6, -1.0)], "look": 1.1},
	{"area": "snow", "from": Vector2(0, 49), "to": Vector2(0, 34),
		"mode": "follow", "cam": [Vector3(2.0, 2.8, -5.0), Vector3(-2.0, 2.0, -4.2)], "look": 1.6, "ahead": 6.0},
]
## Seconds per shot, and the fade through black at each cut.
const SHOT_TIME := 9.0
const FADE_TIME := 0.8
## The camera never dips closer than this to the ground under it.
const CAM_CLEARANCE := 0.6

## Black overlay opacity 0..1 (the title screen draws it).
var fade := 1.0
var shot := -1

var _cam: Camera3D = null
var _t := 0.0
var _hero: TitleWalker = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Starts the shots, flying a camera of its own in `viewport`.
func start(viewport: SubViewport) -> void:
	if _cam != null:
		return
	_cam = Camera3D.new()
	_cam.name = "TitleCamera"
	_cam.fov = 55.0
	_cam.far = 600.0
	viewport.add_child(_cam)
	_next_shot()


func stop() -> void:
	if is_instance_valid(_cam):
		_cam.queue_free()
	_cam = null
	if is_instance_valid(_hero):
		_hero.queue_free()
	_hero = null


func running() -> bool:
	return _cam != null


func _process(delta: float) -> void:
	if _cam == null:
		return
	# A long frame (an area just loaded) must not skip the start of a shot.
	_t += minf(delta, 1.0 / 30.0)
	if _t >= SHOT_TIME:
		_next_shot()
	_update_shot()
	fade = clampf(maxf(1.0 - _t / FADE_TIME, 1.0 - (SHOT_TIME - _t) / FADE_TIME), 0.0, 1.0)


## Places the hero along the walk and the camera for time _t.
func _update_shot() -> void:
	var s: Dictionary = SHOTS[shot]
	var k := _t / SHOT_TIME
	var from: Vector2 = s["from"]
	var to: Vector2 = s["to"]
	var stop_at: float = s.get("stop", 1.0)
	var walk_k := minf(k / stop_at, 1.0)
	if is_instance_valid(_hero):
		_hero.walking = walk_k < 1.0
		_hero.place(from.lerp(to, walk_k))
	var hero_pos := _hero.global_position if is_instance_valid(_hero) else Vector3(from.x, 0, from.y)
	var fwd2 := (to - from).normalized()
	var fwd := Vector3(fwd2.x, 0, fwd2.y)
	var right := Vector3(-fwd.z, 0, fwd.x)
	var cams: Array = s["cam"]
	var local: Vector3 = (cams[0] as Vector3).lerp(cams[1], _ease(k))
	var origin := hero_pos
	if s["mode"] == "fixed":
		origin = Vector3(from.x, TitleWalker.ground_y(_cam, from, hero_pos.y), from.y)
	var eye := origin + right * local.x + fwd * local.z + Vector3.UP * local.y
	# Lifted over rising ground (a hill within a few meters above the eye too,
	# but not a roof far overhead).
	var floor_y := TitleWalker.ground_y(_cam, Vector2(eye.x, eye.z), eye.y, 6.0, -INF)
	eye.y = maxf(eye.y, floor_y + CAM_CLEARANCE)
	var look := hero_pos + Vector3.UP * float(s.get("look", 1.2)) + fwd * float(s.get("ahead", 0.0))
	if eye.distance_to(look) > 0.05:
		_cam.look_at_from_position(eye, look, Vector3.UP)


func _next_shot() -> void:
	shot = (shot + 1) % SHOTS.size()
	_t = 0.0
	fade = 1.0
	var s: Dictionary = SHOTS[shot]
	World.show_scenery(s["area"])
	hush_area()
	_hero = TitleWalker.make(World.area_node)
	var from: Vector2 = s["from"]
	_hero.global_position = Vector3(from.x, 0.0, from.y)
	_hero.face(s["to"] - from)
	_hero.settle()
	_cam.make_current()
	_update_shot()


## The loaded area as a backdrop for the title: its creatures are hidden (the
## paused tree would leave them frozen mid-step), and its townsfolk breathe
## (their models animate though their scripts stay paused).
static func hush_area() -> void:
	var area := World.area_node
	if not is_instance_valid(area):
		return
	for e in area.get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and area.is_ancestor_of(e):
			(e as Node3D).visible = false
	for n in area.get_tree().get_nodes_in_group("npcs"):
		if n is Node and area.is_ancestor_of(n):
			var m := (n as Node).get_node_or_null("Model")
			if m is CharacterModel:
				(m as CharacterModel).process_mode = Node.PROCESS_MODE_ALWAYS


static func _ease(k: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(k, 0.0, 1.0))
