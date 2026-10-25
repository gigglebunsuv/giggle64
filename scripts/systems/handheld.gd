class_name Handheld
extends Node
## Handheld mode's draw savings (GameManager adds it with --handheld).
##
## Handheld CPUs (PortMaster's ARM boards) spend most of a frame issuing draw
## calls, and the game draws everything in an area whatever its distance.
## Depth fog (density 1) has turned everything past fog_depth_end into flat
## fog color, so geometry wholly beyond it is not drawn at all here: each
## small or medium mesh gets a visibility range ending at the fog's end. The
## terrain, walls and other large meshes (whose centers can be far off while
## they reach the camera) and the sky dome (drawn without fog) are left alone,
## as is everything while the FOG option is off. Outdoors the fog also comes
## in closer (FOG_SCALE, applied by DayNight to the area's own Environment).
##
## Small parts also stop being drawn once they would cover only a couple of
## the 240 lines: the characters are built from many little meshes (hands,
## eyes, buckles), each its own draw call, and from across a town they are a
## pixel or two (PIXEL_RANGE meters per meter of the part's longest side).

## Meshes longer than this (in meters, on their longest side) are always drawn.
const MAX_SIZE := 40.0
## Hysteresis so an object at the boundary does not flicker.
const MARGIN := 4.0
## Outdoor fog distances are multiplied by this.
const FOG_SCALE := 0.6
## A part is drawn out to this many times its size: about 2.5 of 240 lines at
## the game cameras' field of view.
const PIXEL_RANGE := 80.0
## Nothing is cut nearer than this.
const MIN_RANGE := 10.0

var _area: Node = null
## Where the current area's fog is complete (0 = no culling).
var _cull := 0.0
var _check := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	GameManager.settings_changed.connect(_refresh)


func _process(delta: float) -> void:
	if World.area_node != _area:
		_area = World.area_node
		_refresh()
		return
	# The fog can change after the area is up (DayNight sets it up, night pulls it in).
	_check += delta
	if _check >= 1.0 and is_instance_valid(_area):
		_check = 0.0
		var cull := _fog_end(_area) if GameManager.fog_enabled else 0.0
		if absf(cull - _cull) > 8.0:
			_cull = cull
			_apply_tree(_area)


func _refresh() -> void:
	if not is_instance_valid(_area):
		_cull = 0.0
		return
	_cull = _fog_end(_area) if GameManager.fog_enabled else 0.0
	_apply_tree(_area)


func _fog_end(area: Node) -> float:
	for n in area.find_children("*", "WorldEnvironment", true, false):
		var env := (n as WorldEnvironment).environment
		if env and env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and env.fog_density >= 1.0:
			return env.fog_depth_end
	return 0.0


func _apply_tree(node: Node) -> void:
	if node is GeometryInstance3D:
		_apply(node)
	for c in node.get_children():
		_apply_tree(c)


func _on_node_added(node: Node) -> void:
	if node is GeometryInstance3D and is_instance_valid(_area) and _area.is_ancestor_of(node):
		_apply.call_deferred(node)


func _apply(g: GeometryInstance3D) -> void:
	if not is_instance_valid(g) or not g.is_inside_tree():
		return
	var parent := g.get_parent()
	while parent and parent != _area:
		if parent.name == &"SkyDome":
			return
		parent = parent.get_parent()
	var b := g.global_transform.basis
	var size := (b.x * g.get_aabb().size.x).abs() + (b.y * g.get_aabb().size.y).abs() + (b.z * g.get_aabb().size.z).abs()
	var longest := maxf(size.x, maxf(size.y, size.z))
	if longest > MAX_SIZE:
		g.visibility_range_end = 0.0
		return
	var end := maxf(MIN_RANGE, longest * PIXEL_RANGE)
	if _cull > 0.0:
		end = minf(end, _cull + longest * 0.5)
	g.visibility_range_end = end
	g.visibility_range_end_margin = MARGIN
