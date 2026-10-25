extends Node
## Handheld performance log (GameManager adds it with --handheld or --perf).
##
## Every few seconds prints one "PERF" line to stdout (the PortMaster launcher
## keeps it in log.txt): the area, frame rate, mean and worst frame time, and
## where the main thread's time went: every node's _process, every node's
## _physics_process (both timed between a marker that runs first and one that
## runs last) and the rendering server's frame on the CPU (frame_pre_draw to
## frame_post_draw, which includes the buffer swap and so any wait for vsync).
## No GPU timer queries: they can stall Mali drivers. Then the 3D draw calls,
## objects, primitives, nodes and active physics bodies.
##
## --perf-area=<area>[:<entrance>] starts a game straight in that area once the
## title is up, as the file menu does (a survey runs one process per area).

const INTERVAL := 5.0

var _area := ""
var _entrance := ""
var _boot_frames := 0
var _t := 0.0
var _frames := 0
var _last := 0
var _frame_sum := 0
var _frame_max := 0
var _proc_sum := 0
var _phys_sum := 0
var _phys_steps := 0
var _render_sum := 0.0
var _draw_max := 0
var _proc_start := 0
var _phys_start := 0
var _draw_start := 0
var _reports := 0


class Marker extends Node:
	var on_process: Callable
	var on_physics: Callable

	func _process(_d: float) -> void:
		on_process.call()

	func _physics_process(_d: float) -> void:
		on_physics.call()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--perf-area="):
			var spec := a.substr(12).split(":")
			_area = spec[0]
			_entrance = spec[1] if spec.size() > 1 else ""
	var first := Marker.new()
	first.process_priority = -1000000
	first.process_physics_priority = -1000000
	first.on_process = func() -> void: _proc_start = Time.get_ticks_usec()
	first.on_physics = func() -> void: _phys_start = Time.get_ticks_usec()
	var last := Marker.new()
	last.process_priority = 1000000
	last.process_physics_priority = 1000000
	last.on_process = func() -> void: _proc_sum += Time.get_ticks_usec() - _proc_start
	last.on_physics = func() -> void:
		_phys_sum += Time.get_ticks_usec() - _phys_start
		_phys_steps += 1
	for m: Node in [first, last]:
		m.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(m)
	RenderingServer.frame_pre_draw.connect(func() -> void: _draw_start = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func() -> void:
		if _draw_start != 0:
			_render_sum += (Time.get_ticks_usec() - _draw_start) / 1000.0)
	print("PERF start: %s, %d cores, %s, %s" % [OS.get_processor_name(), OS.get_processor_count(),
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])


func _process(_delta: float) -> void:
	if _area != "" and GameManager.state == GameManager.GameState.TITLE:
		_boot_frames += 1
		if _boot_frames == 30:
			World.begin_game(_area, _entrance)
			_area = ""
	var now := Time.get_ticks_usec()
	if _last != 0:
		var dt := now - _last
		_frames += 1
		_frame_sum += dt
		_frame_max = maxi(_frame_max, dt)
		_t += dt / 1000000.0
	_last = now
	_draw_max = maxi(_draw_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	if _t < INTERVAL or _frames == 0:
		return
	_reports += 1
	if _reports == 3 and "--perf-dump" in OS.get_cmdline_user_args():
		dump()
	var n := float(_frames)
	print("PERF %s fps %.1f frame %.1f/%.1f ms | process %.1f physics %.1f (%d steps) draw+swap %.1f ms | draws %d (max %d) objects %d prims %dk nodes %d bodies %d vmem %d MB" % [
		World.area_id if GameManager.state != GameManager.GameState.TITLE else "title",
		n / _t, _frame_sum / n / 1000.0, _frame_max / 1000.0,
		_proc_sum / n / 1000.0, _phys_sum / n / 1000.0, _phys_steps, _render_sum / n,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), _draw_max,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)) / 1000,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)),
		int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) >> 20])
	_t = 0.0
	_frames = 0
	_frame_sum = 0
	_frame_max = 0
	_proc_sum = 0
	_phys_sum = 0
	_phys_steps = 0
	_render_sum = 0.0
	_draw_max = 0


## --perf-dump: what the draws are. Visible geometry counted by the area's
## top-level groups (and by mesh name inside the biggest ones), lights, and the
## scripts that run every frame.
func dump() -> void:
	var by_group := {}
	var by_mesh := {}
	var lights := []
	var procs := {}
	var stack: Array[Node] = [get_tree().root]
	var area: Node = World.area_node
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if (n.is_processing() or n.is_physics_processing()) and n.get_script() != null:
			var sp: String = (n.get_script() as Script).resource_path.get_file()
			procs[sp] = procs.get(sp, 0) + 1
		if n is Light3D and (n as Light3D).is_visible_in_tree():
			lights.append("%s %s shadow=%s range=%.0f" % [n.get_class(), n.name, (n as Light3D).shadow_enabled, n.get("omni_range") if n is OmniLight3D else 0.0])
		if not (n is GeometryInstance3D) or not (n as GeometryInstance3D).is_visible_in_tree():
			continue
		var group := "(outside the area)"
		if area and area.is_ancestor_of(n):
			var top: Node = n
			while top.get_parent() != area:
				top = top.get_parent()
			group = String(top.name)
		var surfaces := 1
		var tris := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mesh: Mesh = (n as MeshInstance3D).mesh
			surfaces = mesh.get_surface_count()
			if mesh is ArrayMesh:
				for si in surfaces:
					var idx := (mesh as ArrayMesh).surface_get_array_index_len(si)
					tris += (idx if idx > 0 else (mesh as ArrayMesh).surface_get_array_len(si)) / 3
		var g: Array = by_group.get(group, [0, 0, 0])
		g[0] += 1
		g[1] += surfaces
		g[2] += tris
		by_group[group] = g
		var mesh_name := n.get_class()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var m: Mesh = (n as MeshInstance3D).mesh
			mesh_name = m.resource_path.get_file() if m.resource_path != "" else (m.resource_name if m.resource_name != "" else String(n.name).rstrip("0123456789"))
		by_mesh[group + " / " + mesh_name] = by_mesh.get(group + " / " + mesh_name, 0) + 1
	print("PERF dump %s: geometry by group (instances, surfaces, triangles):" % World.area_id)
	var keys := by_group.keys()
	keys.sort_custom(func(a, b) -> bool: return by_group[a][1] > by_group[b][1])
	for k in keys:
		print("PERF   %5d %5d %7d  %s" % [by_group[k][0], by_group[k][1], by_group[k][2], k])
	print("PERF dump: top meshes")
	var mk := by_mesh.keys()
	mk.sort_custom(func(a, b) -> bool: return by_mesh[a] > by_mesh[b])
	for k in mk.slice(0, 25):
		print("PERF   %5d  %s" % [by_mesh[k], k])
	print("PERF dump: %d lights" % lights.size())
	for l in lights.slice(0, 20):
		print("PERF   " + l)
	print("PERF dump: per-frame scripts")
	var pk := procs.keys()
	pk.sort_custom(func(a, b) -> bool: return procs[a] > procs[b])
	for k in pk.slice(0, 25):
		print("PERF   %5d  %s" % [procs[k], k])
