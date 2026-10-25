extends Node
## Geometry audit (no screenshots; runs headless). For every area:
##
## BLOCKERS: everything that should hold the hero back until something is done
## (locked doors, bars, shutters, bombable walls and boulders, heavy rocks,
## great stones, thorns and ice, seals and story barriers). The walkable
## ground around each one is flood-filled with the hero's capsule (steps up
## to STEP_UP, drops of up to DROP); a blocker the fill gets past from one
## side to the other is reported, with the cell where it got through.
##
## EXITS: the hero is set down at each exit's own return spot (the marker
## "from_<target>" when there is one, else 4 m in front of it) and runs
## straight at the loading zone; an exit he cannot get into within a few
## seconds is reported.
##
## DOORS: every door the hero opens with A (a house, a dungeon's way out):
## set down in front of it, facing it, A must take him through (unless the
## door is meant to be barred just now).
##
## With --climb the blocker fill also climbs ledges the way the hero does
## (up to LEDGE_UP, onto flat ground, unless the wall or the top is no_climb),
## so a barrier with climbable rock beside it is caught too.
##
##   Godot --headless --path <project> --fixed-fps 60 res://tests/geometry_audit.tscn -- [--areas=a,b] [--only=blockers|exits] [--climb]

const CELL := 0.25
const RADIUS := 7.0
const STEP_UP := 0.65
const DROP := 2.6
const HERO_R := 0.32
const HERO_H := 1.8
## The tallest ledge the hero gets onto: he walks up to LEDGE_PULL and jumps
## at the wall to catch anything up to PlayerController.LEDGE_PROBE (units of
## 0.03 m).
const LEDGE_UP := PlayerController.LEDGE_PROBE * 0.03

var _climb := false
## With --climb, the drop the hero may take on purpose (he lands hurt but alive).
const CLIMB_DROP := 9.0
var _climbs := 0
## AUDIT_DUMP="x,z,r": the path reports plain steps within r of (x, z) too.
var _dump_at := Vector2.ZERO
var _dump_r := 0.0
var _why := {}

var _main: Node
var _space: PhysicsDirectSpaceState3D
var _capsule := CapsuleShape3D.new()
var _exclude: Array[RID] = []
var _problems := 0


func _ready() -> void:
	var areas: Array = WorldData.AREAS.keys().filter(func(a: String) -> bool: return a != "test_area" and ResourceLoader.exists(WorldData.scene_path(a)))
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--areas="):
			areas = Array(a.substr(8).split(","))
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a == "--climb":
			_climb = true
	GameManager.skip_title = true
	var dump := OS.get_environment("AUDIT_DUMP")
	if dump != "":
		var d := dump.split(",")
		_dump_at = Vector2(float(d[0]), float(d[1]))
		_dump_r = float(d[2])
	_capsule.radius = HERO_R
	_capsule.height = HERO_H
	if only == "enemies":
		for area: String in areas:
			if WorldData.dungeon(area) != "":
				await _enemy_places(area)
		print("== AUDIT DONE: %d problems" % _problems)
		get_tree().quit(1 if _problems > 0 else 0)
		return
	if only == "routes":
		for area: String in areas:
			if WorldData.dungeon(area) != "":
				await _routes(area)
		print("== AUDIT DONE: %d problems" % _problems)
		get_tree().quit(1 if _problems > 0 else 0)
		return
	if only == "heights":
		await _load(areas[0], "")
		await _frames(10)
		for x in range(-62, -40, 3):
			var row := "x %4d:" % x
			for z in range(-30, 44, 3):
				var q := PhysicsRayQueryParameters3D.create(Vector3(x, 60, z), Vector3(x, -30, z), 1)
				q.exclude = _exclude
				var h := _space.intersect_ray(q)
				row += " %5.1f" % (h.position.y if not h.is_empty() else -99.0)
			print(row)
		get_tree().quit(0)
		return
	if only == "walk":
		await _walk_mode(areas[0])
		get_tree().quit(0)
		return
	if only == "gates":
		_climb = not OS.get_cmdline_user_args().has("--noclimb")
		for area: String in areas:
			await _gates(area)
		print("== AUDIT DONE")
		get_tree().quit(0)
		return
	if only == "reach":
		await _reach_mode(areas[0])
		get_tree().quit(0)
		return
	if only == "selftest":
		await _climb_selftest()
		get_tree().quit(1 if _problems > 0 else 0)
		return
	if only == "fall":
		await _fall_probes()
		get_tree().quit(0)
		return
	if only == "sight":
		for area: String in areas:
			await _sight(area)
		print("== AUDIT DONE: %d problems" % _problems)
		get_tree().quit(1 if _problems > 0 else 0)
		return
	if only == "climb":
		await _climb_probes()
		print("== AUDIT DONE: %d problems" % _problems)
		get_tree().quit(1 if _problems > 0 else 0)
		return
	for area: String in areas:
		if only != "exits" and only != "doors" and only != "swim":
			await _load(area, "")
			await _blockers(area)
		if only == "" or only == "exits":
			await _exits(area)
		if only == "" or only == "doors":
			await _doors(area)
		if only == "swim":
			await _swim(area)
	if _climb:
		print("== ledges climbed in the fills: %d %s" % [_climbs, _why])
	print("== AUDIT DONE: %d problems" % _problems)
	get_tree().quit(1 if _problems > 0 else 0)


func _load(area: String, entrance: String) -> void:
	if _main:
		_main.queue_free()
		await _frames(3)
	World.area_id = area
	World.entrance_id = entrance
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	await _frames(12)
	for e in get_tree().get_nodes_in_group("enemies"):
		(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var p: PlayerController = GameManager.player
	_exclude.clear()
	if p:
		_exclude.append(p.get_rid())
	_space = (World.area_node as Node3D).get_world_3d().direct_space_state


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _report(area: String, what: String) -> void:
	_problems += 1
	print("  [%s] %s" % [area, what])


# --- Blockers ---------------------------------------------------------------------

## [node, kind, normal (horizontal, unit), half depth] for every blocker.
func _find_blockers() -> Array:
	var out: Array = []
	for n in World.area_node.find_children("*", "", true, false):
		var s: Script = n.get_script()
		if s == null or not (n is Node3D):
			continue
		var b := n as Node3D
		var path := s.resource_path.get_file()
		var z := b.global_basis.z
		var nrm := Vector3(z.x, 0, z.z).normalized()
		match path:
			"locked_door.gd":
				out.append([b, "locked door", nrm, 0.25])
			"flag_mover.gd":
				if String(b.name).begins_with("Bars"):
					out.append([b, "bars", nrm, 0.15])
			"bomb_wall.gd":
				out.append([b, "bomb boulder" if b.get("boulder") else "bomb wall", nrm, 1.2 if b.get("boulder") else 0.3])
			"great_stone.gd":
				out.append([b, "great stone", nrm, 1.15])
			"burnable.gd":
				# Rime cased round a torch is not a way through.
				if (b.get("size") as Vector3).x >= 2.0:
					out.append([b, "burnable " + String(b.get("kind")), nrm, 0.5])
			"flag_barrier.gd":
				# One that never goes (a tent, a cage) is scenery, not a gate.
				if String(b.get("gone_flag")) == "":
					continue
				# A lid over a hole in the floor is not a wall.
				var cs := b.get_node_or_null("Shape") as CollisionShape3D
				if cs and cs.shape is BoxShape3D and (cs.shape as BoxShape3D).size.y < 1.2:
					continue
				out.append([b, "barrier " + String(b.get("gone_flag")), nrm, 0.5])
			"mallet_stake.gd":
				if String(b.name).begins_with("IceSheet"):
					out.append([b, "ice sheet", nrm, 0.3])
			"sapphire_ward.gd":
				out.append([b, "sapphire ward", nrm, 0.3])
			"lift_rock.gd":
				if b.get("heavy") and String(b.get("gone_flag")) != "":
					out.append([b, "heavy rock " + String(b.get("gone_flag")), Vector3.ZERO, 0.62])
	return out


## The loading zones of the area: [node, center, facing out (unit, horizontal)].
func _exit_zones() -> Array:
	var out: Array = []
	for n in World.area_node.find_children("*", "Area3D", true, false):
		if n.get_script() and n.get_script().resource_path.get_file() == "area_exit.gd":
			var a := n as Area3D
			out.append(a)
	return out


func _blockers(area: String) -> void:
	var list := _find_blockers()
	var exits := _exit_zones()
	print("== %s: %d blockers" % [area, list.size()])
	for bl: Array in list:
		var b: Node3D = bl[0]
		if not is_instance_valid(b) or not b.is_inside_tree():
			continue
		var p := b.global_position
		var nrm: Vector3 = bl[2]
		var d: float = bl[3] + 0.9
		var side_a := Vector3.INF
		var side_b := Vector3.INF
		# A blocker next to a loading zone guards it: one side is the zone.
		var lump: bool = String(bl[1]).begins_with("heavy rock") or String(bl[1]).begins_with("great stone")
		var guard: Area3D = null
		for ex: Area3D in exits:
			if _flat(ex.global_position - p).length() < (8.0 if lump else 4.5):
				guard = ex
		# A boulder or great stone in the open (over a hole, in a field) only
		# matters where it guards a way out.
		if lump and guard == null:
			continue
		if guard:
			var away := _flat(p - guard.global_position).normalized()
			if away == Vector3.ZERO:
				away = nrm
			side_a = _floor_near(p + away * (d + 0.6), p.y)
			# The goal is the zone itself (_in_zone), not a spot to stand on.
			side_b = guard.global_position
		elif nrm != Vector3.ZERO:
			side_a = _floor_near(p + nrm * d, p.y)
			side_b = _floor_near(p - nrm * d, p.y)
		if side_a == Vector3.INF or side_b == Vector3.INF:
			# No floor to stand on one side: try it turned a quarter (a door
			# set the wrong way round across its doorway).
			if guard == null and nrm != Vector3.ZERO:
				var turned := Vector3(-nrm.z, 0, nrm.x)
				var ta := _floor_near(p + turned * d, p.y)
				var tb := _floor_near(p - turned * d, p.y)
				if ta != Vector3.INF and tb != Vector3.INF:
					_report(area, "%s at %s stands side-on in its way (free ground at both its ends, none in front and behind)" % [bl[1], _v(p)])
			print("    (skipped %s at %s: no floor on one side)" % [bl[1], _v(p)])
			continue
		var res := _flood(side_a, side_b, p, guard)
		if res.reached:
			_report(area, "%s at %s can be walked past from %s (got through near %s)%s" % [bl[1], _v(p), _v(side_a), _v(res.at), (" via " + String(res.climbs)) if String(res.get("climbs", "")) != "" else ""])


## The floor under `at`, within a couple of meters of `y`, or INF.
func _floor_near(at: Vector3, y: float) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, y + 2.0, at.z), Vector3(at.x, y - 3.0, at.z), 1)
	q.exclude = _exclude
	var hit := _space.intersect_ray(q)
	if hit.is_empty():
		return Vector3.INF
	var f: Vector3 = hit.position
	return f if _fits(f) else Vector3.INF


## The hero's capsule stands at `floor` without touching anything.
func _fits(floor: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _capsule
	q.transform = Transform3D(Basis(), floor + Vector3.UP * (HERO_H * 0.5 + 0.18))
	q.collision_mask = 1
	q.exclude = _exclude
	return _space.intersect_shape(q, 1).is_empty()


## Flood-fills the ground from `from` within RADIUS of `center`; reached
## when it comes within a cell of `to` (or into the loading zone `zone`).
func _flood(from: Vector3, to: Vector3, centre: Vector3, zone: Area3D, radius := RADIUS, max_steps := 9000) -> Dictionary:
	var seen := {}
	var queue: Array = [from]
	# How each spot was reached (for the climbs on the way through).
	var came := {}
	var key0 := _key(from)
	seen[key0] = true
	var steps := 0
	while not queue.is_empty() and steps < max_steps:
		steps += 1
		var c: Vector3 = queue.pop_front()
		if _flat(c - to).length() < CELL * 1.5 and absf(c.y - to.y) < 1.0:
			return {"reached": true, "at": c, "climbs": _climbs_on(came, c)}
		if zone and _in_zone(zone, c):
			return {"reached": true, "at": c, "climbs": _climbs_on(came, c)}
		for dir in [Vector3(CELL, 0, 0), Vector3(-CELL, 0, 0), Vector3(0, 0, CELL), Vector3(0, 0, -CELL)]:
			var n: Vector3 = c + dir
			if _flat(n - centre).length() > radius:
				continue
			var k := _key(n)
			if seen.has(k):
				continue
			seen[k] = true
			var q := PhysicsRayQueryParameters3D.create(Vector3(n.x, c.y + STEP_UP, n.z), Vector3(n.x, c.y - (CLIMB_DROP if _climb else DROP), n.z), 1)
			q.exclude = _exclude
			var hit := _space.intersect_ray(q)
			if _climb and not hit.is_empty() and (hit.normal as Vector3).y >= 0.6 and not _fits(hit.position) and (hit.position as Vector3).y < c.y - STEP_UP:
				# Dropping off a ledge he lands a little way out from its foot.
				var land := _drop_landing(c, (dir as Vector3).normalized())
				if land != Vector3.INF and not seen.has(_key(land)):
					seen[_key(land)] = true
					if not came.has(land):
						came[land] = [c, "drop"]
					queue.append(land)
				continue
			if hit.is_empty() or (hit.normal as Vector3).y < 0.6 or not _fits(hit.position):
				if _climb:
					var up := _ledge_up(c, n)
					if up != Vector3.INF:
						_climbs += 1
						if not came.has(up):
							came[up] = [c, "climb"]
						queue.append(up)
				continue
			if not came.has(hit.position):
				came[hit.position] = [c, ""]
			queue.append(hit.position)
	return {"reached": false, "at": Vector3.ZERO}


## --only=walk --areas=<one> --path=x,z;x,z;... [--flags=a,b]: the real hero
## is set down at the first point and steered to each next one in turn (the
## stick held toward it); prints where he got to and any loading zone taken.
func _walk_mode(area: String) -> void:
	var pts: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--flags="):
			for f in a.substr(8).split(","):
				Progress.set_flag(f)
		elif a.begins_with("--path="):
			for pt in a.substr(7).split(";"):
				var xy := pt.split(",")
				pts.append(Vector2(float(xy[0]), float(xy[1])))
	await _load(area, "")
	await _frames(30)
	var p: PlayerController = GameManager.player
	var first: Vector2 = pts[0]
	var f0 := _floor_near(Vector3(first.x, 60.0, first.y), 0.0)
	var q := PhysicsRayQueryParameters3D.create(Vector3(first.x, 80.0, first.y), Vector3(first.x, -40.0, first.y), 1)
	q.exclude = _exclude
	var hit := _space.intersect_ray(q)
	f0 = hit.position if not hit.is_empty() else Vector3(first.x, 5.0, first.y)
	p.global_position = f0 + Vector3.UP * 0.2
	p.velocity = Vector3.ZERO
	await _frames(20)
	var went := {"to": ""}
	World.area_changed.connect(func(a2: String) -> void: went.to = a2)
	for i in range(1, pts.size()):
		var goal: Vector2 = pts[i]
		for f in 600:
			if not is_instance_valid(p) or World.transitioning or went.to != "":
				break
			var to := Vector2(goal.x - p.global_position.x, goal.y - p.global_position.z)
			if to.length() < 0.5:
				break
			p.debug_use_move_input = true
			p.debug_move_input = Vector3(to.normalized().x, 0, to.normalized().y)
			await get_tree().physics_frame
		if not is_instance_valid(p) or World.transitioning or went.to != "":
			break
		print("   reached %s ~ %s (y %.1f) state %s" % [goal, _v(p.global_position), p.global_position.y, PlayerController.State.keys()[p.state]])
	if is_instance_valid(p):
		p.debug_use_move_input = false
	await _frames(90)
	print("== walk %s: loading zone taken: %s (now in %s)" % [area, went.to != "" or World.transitioning, World.area_id])


## --only=gates: from where the hero comes into each area, one climbing
## fill over the whole area (half-meter cells); prints every loading zone it
## reaches or not, with the climbs on the way. Run it with the story flags
## of the moment (--flags=a,b) to see which ways out are really shut.
func _gates(area: String) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--flags="):
			for f in a.substr(8).split(","):
				Progress.set_flag(f)
	await _load(area, "")
	await _frames(30)
	var p: PlayerController = GameManager.player
	var start := _floor_near(p.global_position, p.global_position.y)
	var zones := _exit_zones()
	print("== %s: %d ways out, from %s" % [area, zones.size(), _v(start)])
	if start == Vector3.INF:
		return
	var res := _flood_all(start, zones)
	for z: Area3D in zones:
		var info: Dictionary = res.get(z, {})
		var gate := ""
		if String(z.get("need_flag")) != "":
			gate = " (needs %s)" % z.get("need_flag")
		print("   %-28s %s%s %s" % [String(z.get("target_area")), "REACHED" if not info.is_empty() else "held", gate, String(info.get("climbs", ""))])
	print("   (%d cells)" % int(res.get("_cells", 0)))


## One climbing fill from `from` over the whole area with half-meter cells,
## noting each zone of `zones` it reaches: {zone: {climbs}}.
func _flood_all(from: Vector3, zones: Array) -> Dictionary:
	var cell := 0.5
	var seen := {}
	var came := {}
	var queue: Array = [from]
	var head := 0
	var out := {}
	seen[_key2(from, cell)] = true
	while head < queue.size() and queue.size() < 400000:
		var c: Vector3 = queue[head]
		head += 1
		for z: Area3D in zones:
			if not out.has(z) and _in_zone(z, c):
				out[z] = {"climbs": _climbs_on(came, c)}
		for dir: Vector3 in [Vector3(cell, 0, 0), Vector3(-cell, 0, 0), Vector3(0, 0, cell), Vector3(0, 0, -cell)]:
			var n: Vector3 = c + dir
			var q := PhysicsRayQueryParameters3D.create(Vector3(n.x, c.y + STEP_UP, n.z), Vector3(n.x, c.y - CLIMB_DROP, n.z), 1)
			q.exclude = _exclude
			var hit := _space.intersect_ray(q)
			var nxt := Vector3.INF
			var how := ""
			if not hit.is_empty() and (hit.normal as Vector3).y >= 0.6 and _fits(hit.position):
				nxt = hit.position
				if nxt.y < c.y - STEP_UP:
					how = "drop"
			elif not hit.is_empty() and (hit.normal as Vector3).y >= 0.6 and (hit.position as Vector3).y < c.y - STEP_UP:
				nxt = _drop_landing(c, dir.normalized())
				how = "drop"
			elif _climb:
				nxt = _ledge_up(c, n)
				how = "climb"
			if nxt == Vector3.INF:
				continue
			var k := _key2(nxt, cell)
			if seen.has(k):
				continue
			seen[k] = true
			came[nxt] = [c, how]
			queue.append(nxt)
	out["_cells"] = queue.size()
	return out


## --only=reach --areas=<one> --from=x,y,z --to=x,y,z [--radius=r] [--climb]:
## can the hero walk (and with --climb, climb and drop) from one spot to the
## other? Prints REACHED with the climbs on the way, or HELD.
func _reach_mode(area: String) -> void:
	var from := Vector3.INF
	var to := Vector3.INF
	var radius := 60.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from = _vec(a.substr(7))
		elif a.begins_with("--to="):
			to = _vec(a.substr(5))
		elif a.begins_with("--radius="):
			radius = float(a.substr(9))
	await _load(area, "")
	await _frames(30)
	var a := _floor_near(from, from.y)
	var b := _floor_near(to, to.y)
	print("== reach %s: from %s (floor %s) to %s (floor %s)" % [area, _v(from), _v(a), _v(to), _v(b)])
	if a == Vector3.INF or b == Vector3.INF:
		print("   no floor at one end")
		return
	var res := _flood(a, b, (a + b) * 0.5, null, radius, 200000)
	print("   %s %s" % ["REACHED" if res.reached else "HELD", String(res.get("climbs", ""))])


func _vec(t: String) -> Vector3:
	var p := t.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


## Where the hero lands stepping off a ledge at `c` along `dir`: the first
## spot a cell or two out where he fits, or INF.
func _drop_landing(c: Vector3, dir: Vector3) -> Vector3:
	for i in [2, 3, 4]:
		var at: Vector3 = c + dir * (CELL * i)
		var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, c.y + 0.3, at.z), Vector3(at.x, c.y - CLIMB_DROP, at.z), 1)
		q.exclude = _exclude
		var hit := _space.intersect_ray(q)
		if not hit.is_empty() and (hit.normal as Vector3).y >= 0.6 and _fits(hit.position):
			return hit.position
	return Vector3.INF


## Checks the climbing fill on walls built in the test area: a 2 m and a 3 m
## wall must be climbed, a 4.5 m one and a no_climb one must not.
func _climb_selftest() -> void:
	_climb = true
	await _load("test_area", "")
	var p: PlayerController = GameManager.player
	var at := p.global_position + Vector3(0, 0, -6)
	for c: Array in [[2.0, false, true], [3.0, false, true], [4.5, false, false], [2.0, true, false]]:
		var wall := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(30.0, c[0], 3.0)
		cs.shape = box
		if c[1]:
			cs.set_meta("no_climb", true)
		wall.add_child(cs)
		World.area_node.add_child(wall)
		var a := _floor_near(at + Vector3(0, 0, 3.0), at.y)
		wall.global_position = Vector3(at.x, a.y + c[0] * 0.5, at.z)
		await _frames(3)
		var from := _floor_near(at + Vector3(0, 0, 3.0), at.y)
		var to := _floor_near(at + Vector3(0, 0, -3.0), at.y)
		var res := _flood(from, to, at, null)
		print("  selftest wall %.1f m%s: crossed %s (expected %s) climbs %d %s from %s to %s" % [c[0], " no_climb" if c[1] else "", res.reached, c[2], _climbs, _why, from, to])
		if res.reached != c[2]:
			_problems += 1
		wall.queue_free()
		await _frames(3)
	print("== SELFTEST: %d problems" % _problems)


## The top of a ledge the hero could pull himself onto from `c` toward `n`
## (a wall in the way that is not no_climb, flat ground on top within
## LEDGE_UP), or INF.
func _ledge_up(c: Vector3, n: Vector3) -> Vector3:
	var dir := _flat(n - c).normalized()
	var wq := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 0.4, c + Vector3.UP * 0.4 + dir * (HERO_R + CELL * 2.0), 1)
	wq.exclude = _exclude
	var wall := _space.intersect_ray(wq)
	if wall.is_empty() or PlayerController._shape_meta(PlayerController._hit_shape(wall), "no_climb"):
		_why["wall"] = _why.get("wall", 0) + 1
		return Vector3.INF
	# Like _probe_ledge: look for the top a little way in past the wall's face.
	var over: Vector3 = (wall.position as Vector3) + dir * 0.3
	var tq := PhysicsRayQueryParameters3D.create(Vector3(over.x, c.y + LEDGE_UP + 0.05, over.z), Vector3(over.x, c.y + STEP_UP, over.z), 1)
	tq.exclude = _exclude
	var top := _space.intersect_ray(tq)
	if top.is_empty() or (top.normal as Vector3).y < 0.856:
		_why["top"] = _why.get("top", 0) + 1
		return Vector3.INF
	if PlayerController._shape_meta(PlayerController._hit_shape(top), "no_climb"):
		_why["topnc"] = _why.get("topnc", 0) + 1
		return Vector3.INF
	var f: Vector3 = top.position
	# The controller's own rules (_probe_ledge): nothing overhead up to 20
	# units over the top, and the top goes on 0.55 m (no perching on walls
	# and rails too thin to stand on).
	var cq := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 1.0, Vector3(c.x, f.y + 0.6, c.z), 1)
	cq.exclude = _exclude
	if not _space.intersect_ray(cq).is_empty():
		_why["ceiling"] = _why.get("ceiling", 0) + 1
		return Vector3.INF
	var deep: Vector3 = (wall.position as Vector3) + dir * 0.55
	var dq := PhysicsRayQueryParameters3D.create(Vector3(deep.x, f.y + 0.5, deep.z), Vector3(deep.x, f.y - 0.3, deep.z), 1)
	dq.exclude = _exclude
	var din := _space.intersect_ray(dq)
	if din.is_empty() or absf((din.position as Vector3).y - f.y) > 0.3:
		_why["thin"] = _why.get("thin", 0) + 1
		return Vector3.INF
	var side := Vector3(-dir.z, 0, dir.x) * PlayerController.PERCH_HALF_WIDTH
	for sd: Vector3 in [side, -side]:
		var sq := PhysicsRayQueryParameters3D.create(Vector3(deep.x + sd.x, f.y + 0.5, deep.z + sd.z), Vector3(deep.x + sd.x, f.y - 0.3, deep.z + sd.z), 1)
		sq.exclude = _exclude
		var sh := _space.intersect_ray(sq)
		if sh.is_empty() or absf((sh.position as Vector3).y - f.y) > 0.3:
			_why["narrow"] = _why.get("narrow", 0) + 1
			return Vector3.INF
	# Room to stand up there (a step further in, as the climb ends past the lip).
	if _fits(f):
		return f
	var g := _floor_near(f + dir * CELL, f.y)
	return g if g != Vector3.INF and absf(g.y - f.y) < 0.1 else Vector3.INF


## The climbs and drops on the way to `at` (for the report).
func _climbs_on(came: Dictionary, at: Vector3) -> String:
	var out: Array = []
	var c := at
	var guard := 0
	while came.has(c) and guard < 5000:
		guard += 1
		var step: Array = came[c]
		if String(step[1]) != "":
			out.push_front("%s %s->%s" % [step[1], _v(step[0]), _v(c)])
		elif _dump_r > 0.0 and Vector2(c.x - _dump_at.x, c.z - _dump_at.y).length() < _dump_r:
			out.push_front("at %s" % _v(c))
		c = step[0]
	return ", ".join(out)


func _in_zone(zone: Area3D, p: Vector3) -> bool:
	var cs := zone.get_node_or_null("Shape") as CollisionShape3D
	if cs == null or not (cs.shape is BoxShape3D):
		return _flat(p - zone.global_position).length() < 0.8
	var l := cs.global_transform.affine_inverse() * (p + Vector3.UP * 0.9)
	var half := (cs.shape as BoxShape3D).size * 0.5 + Vector3(HERO_R, 0.9, HERO_R)
	return absf(l.x) <= half.x and absf(l.y) <= half.y and absf(l.z) <= half.z


func _key(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x / CELL), roundi(p.y / 1.5), roundi(p.z / CELL))


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


# --- Exits ------------------------------------------------------------------------

func _doors(area: String) -> void:
	await _load(area, "")
	var list: Array = []
	for d in get_tree().get_nodes_in_group("doors"):
		var door := d as Door
		if door and not door.barred() and door.can_interact(GameManager.player):
			list.append(String(door.get_path()))
	print("== %s: %d doors" % [area, list.size()])
	for path: String in list:
		await _load(area, "")
		await _frames(60)
		var door := get_node_or_null(path) as Door
		if door == null:
			continue
		var p: PlayerController = GameManager.player
		var front := -door.global_basis.z
		front = Vector3(front.x, 0, front.z).normalized()
		var spot := door.global_position + front * 1.1
		var floor_at := _floor_near(spot, door.global_position.y)
		p.global_position = (floor_at if floor_at != Vector3.INF else spot) + Vector3.UP * 0.05
		p.velocity = Vector3.ZERO
		p.face_direction(-front)
		await _frames(10)
		var thing := p.interact_candidate()
		if thing != door:
			_report(area, "door %s -> %s: standing in front of it, A does not reach it (candidate %s)" % [door.name, door.target_area, thing.name if thing else "none"])
			continue
		door.interact(p)
		var went := false
		for i in 30:
			await get_tree().physics_frame
			if World.transitioning:
				went = true
				break
		if not went:
			_report(area, "door %s -> %s: A did not open it" % [door.name, door.target_area])
		for i in 200:
			if not World.transitioning:
				break
			await get_tree().process_frame


## SIGHT (--only=sight): every interactable that can be used right now has
## some free floor within its reach, at about the hero's height, from which
## the hero's line of sight (PlayerController._can_see_interactable) gets to
## it. Catches things whose own solid is baked into the area's collision.
func _sight(area: String) -> void:
	await _load(area, "")
	await _frames(30)
	var p: PlayerController = GameManager.player
	if p == null:
		return
	var count := 0
	for n in get_tree().get_nodes_in_group("interactable"):
		var node := n as Node3D
		if node == null or not node.has_method("interact") or not node.is_visible_in_tree():
			continue
		if node.has_method("can_interact") and not node.can_interact(p):
			continue
		count += 1
		var reach: float = node.interact_reach() if node.has_method("interact_reach") else p.interact_range
		var c := node.global_position
		var seen := false
		var stood := false
		for r: float in [reach * 0.9, reach * 0.65, reach * 0.4]:
			for i in 16:
				var a := TAU * i / 16.0
				var floor_at := _stand_near(c + Vector3(cos(a), 0, sin(a)) * r, c.y)
				if floor_at == Vector3.INF:
					continue
				var dy := c.y - floor_at.y
				if dy < PlayerController.INTERACT_BELOW or dy > PlayerController.INTERACT_ABOVE:
					continue
				stood = true
				p.global_position = floor_at + Vector3.UP * 0.05
				if p._can_see_interactable(node):
					seen = true
					break
			if seen:
				break
		if not seen:
			_report(area, "%s at %s: %s" % [node.name, _v(c),
				"no line of sight from any spot within reach" if stood else "no free floor within reach"])
			if OS.get_environment("AUDIT_SIGHT_WHY") != "":
				_sight_why(p, node, reach * 0.65)
	print("== %s: %d interactables" % [area, count])


## Like _floor_near, but a walkable slope counts too (the capsule set a
## little higher, so its foot clears the uphill side).
func _stand_near(at: Vector3, y: float) -> Vector3:
	var f := _floor_near(at, y)
	if f != Vector3.INF:
		return f
	var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, y + 2.0, at.z), Vector3(at.x, y - 3.0, at.z), 1)
	q.exclude = _exclude
	var hit := _space.intersect_ray(q)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.7:
		return Vector3.INF
	var lifted: Vector3 = hit.position + Vector3.UP * 0.35
	return hit.position if _fits(lifted) else Vector3.INF


func _points_box(s: Shape3D) -> String:
	if not s is ConvexPolygonShape3D or (s as ConvexPolygonShape3D).points.is_empty():
		return ""
	var pts := (s as ConvexPolygonShape3D).points
	var b := AABB(pts[0], Vector3.ZERO)
	for v in pts:
		b = b.expand(v)
	return "box %s..%s" % [_v(b.position), _v(b.end)]


## Why a SIGHT problem: per direction, the floor the ray finds, whether the
## hero fits there, and what the line of sight meets.
func _sight_why(p: PlayerController, node: Node3D, r: float) -> void:
	var c := node.global_position
	for i in 8:
		var a := TAU * i / 8.0
		var at := c + Vector3(cos(a), 0, sin(a)) * r
		var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, c.y + 2.0, at.z), Vector3(at.x, c.y - 3.0, at.z), 1)
		q.exclude = _exclude
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			print("      dir %d: no floor" % i)
			continue
		var f: Vector3 = hit.position
		var blocker := ""
		var sq := PhysicsShapeQueryParameters3D.new()
		sq.shape = _capsule
		sq.transform = Transform3D(Basis(), f + Vector3.UP * (HERO_H * 0.5 + 0.18))
		sq.collision_mask = 1
		sq.exclude = _exclude
		for h in _space.intersect_shape(sq, 4):
			blocker += " %s#%d" % [(h.collider as Node).name, h.shape]
			var co := h.collider as CollisionObject3D
			var owner_node := co.shape_owner_get_owner(co.shape_find_owner(h.shape)) as Node3D if co else null
			if owner_node:
				var s: Shape3D = co.shape_owner_get_shape(co.shape_find_owner(h.shape), 0)
				blocker += "(%s at %s %s)" % [s.get_class(), _v(owner_node.global_position),
					str(s.size) if s is BoxShape3D else (str(s.radius) if "radius" in s else _points_box(s))]
		p.global_position = f + Vector3.UP * 0.05
		var from := p.global_position + Vector3.UP * 1.5
		var sr := PhysicsRayQueryParameters3D.create(from, Vector3(c.x, from.y, c.z), 1)
		sr.exclude = [p.get_rid()]
		var sh := _space.intersect_ray(sr)
		var seen := "clear" if sh.is_empty() else "%s at %s" % [(sh.collider as Node).name, _v(sh.position)]
		print("      dir %d: floor %s (on %s), capsule hits [%s], sight -> %s" % [i, _v(f), (hit.collider as Node).name, blocker, seen])


## ENEMIES: in a dungeon, every creature starts with floor under it, not
## inside a wall, and (when it belongs to a room) inside that room.
func _enemy_places(area: String) -> void:
	await _load(area, "")
	var zones := {}
	for z in get_tree().get_nodes_in_group("rooms"):
		zones[String(z.get("room_id"))] = z
	var n := 0
	for e in World.area_node.find_children("*", "CharacterBody3D", true, false):
		if not (e is Enemy):
			continue
		n += 1
		var en := e as Enemy
		var p := en.global_position
		var msg := ""
		if en.has_meta("room"):
			var id: String = en.get_meta("room")
			var z = zones.get(id)
			if z == null:
				msg += " no room '%s';" % id
			elif not z.contains(p) and not z.contains(p + Vector3.UP * 1.0):
				msg += " outside its room %s;" % id
		var floating: bool = en.motion_mode == CharacterBody3D.MOTION_MODE_FLOATING
		if not floating:
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 12.0, 1)
			q.exclude = [en.get_rid()]
			if _space.intersect_ray(q).is_empty():
				msg += " no floor below;"
		var pq := PhysicsPointQueryParameters3D.new()
		pq.position = p + Vector3.UP * 0.8
		pq.collision_mask = 1
		pq.exclude = [en.get_rid()]
		var inside := _space.intersect_point(pq, 4)
		if not inside.is_empty():
			msg += " inside %s;" % (inside[0].collider as Node).name
		if msg != "":
			_report(area, "%s at %s:%s" % [en.name, _v(p), msg])
	print("== %s: %d creatures" % [area, n])


## ROUTES: a locked door must be the only way on. From one side of it the
## dungeon is flooded far and wide (climbing up to LEDGE_PULL, dropping down
## whole storeys) with every lock, bar and seal in place; reaching the other
## side means there is a way round it.
func _routes(area: String) -> void:
	await _load(area, "")
	var doors: Array = []
	for d in get_tree().get_nodes_in_group("locked_doors"):
		doors.append(d)
	print("== %s: %d locked doors" % [area, doors.size()])
	for d: Node3D in doors:
		var p := d.global_position
		var z := d.global_basis.z
		var nrm := Vector3(z.x, 0, z.z).normalized()
		var a := _floor_near(p + nrm * 1.2, p.y)
		var b := _floor_near(p - nrm * 1.2, p.y)
		if a == Vector3.INF or b == Vector3.INF:
			continue
		var res := _flood_wide(a, b, 60000)
		print("    door at %s: flood %d cells, %s" % [_v(p), res.cells, "REACHED" if res.reached else "held"])
		if res.reached:
			_report(area, "locked door at %s can be got round (reached its far side near %s, %d cells)" % [_v(p), _v(res.at), res.cells])


func _flood_wide(from: Vector3, to: Vector3, max_cells: int) -> Dictionary:
	var step := 0.5
	var seen := {}
	var queue: Array = [from]
	var head := 0
	seen[_key2(from, step)] = true
	while head < queue.size() and queue.size() < max_cells:
		var c: Vector3 = queue[head]
		head += 1
		if _flat(c - to).length() < step * 1.2 and absf(c.y - to.y) < 1.0:
			return {"reached": true, "at": c, "cells": queue.size()}
		for dir in [Vector3(step, 0, 0), Vector3(-step, 0, 0), Vector3(0, 0, step), Vector3(0, 0, -step)]:
			var n: Vector3 = c + dir
			var q := PhysicsRayQueryParameters3D.create(Vector3(n.x, c.y + 2.4, n.z), Vector3(n.x, c.y - 9.0, n.z), 1)
			q.exclude = _exclude
			var hit := _space.intersect_ray(q)
			if hit.is_empty() or (hit.normal as Vector3).y < 0.6:
				continue
			var f: Vector3 = hit.position
			var k := _key2(f, step)
			if seen.has(k):
				continue
			seen[k] = true
			# Over a rise of more than a step he climbs: headroom over the edge.
			if f.y - c.y > 0.6:
				var hq := PhysicsRayQueryParameters3D.create(Vector3(c.x, f.y + 1.6, c.z), Vector3(n.x, f.y + 1.6, n.z), 1)
				hq.exclude = _exclude
				if not _space.intersect_ray(hq).is_empty():
					continue
			if not _fits(f):
				continue
			queue.append(f)
	return {"reached": false, "at": Vector3.ZERO, "cells": queue.size()}


func _key2(p: Vector3, step: float) -> Vector3i:
	return Vector3i(roundi(p.x / step), roundi(p.y / 1.2), roundi(p.z / step))


## FALL: runs off real drops and reports the fall and the damage.
const FALL_PROBES := [
	["cliffs", Vector3(-20.0, 33.0, -40.0), Vector3(0, 0, 1)],
	["cliffs", Vector3(-20.0, 21.0, -10.0), Vector3(0, 0, 1)],
	["cliffs", Vector3(-20.0, 10.0, 20.0), Vector3(0, 0, 1)],
]


func _fall_probes() -> void:
	for c: Array in FALL_PROBES:
		await _load(c[0], "")
		await _frames(40)
		var p: PlayerController = GameManager.player
		var start: Vector3 = c[1]
		var q := PhysicsRayQueryParameters3D.create(start + Vector3.UP * 5.0, start + Vector3.DOWN * 5.0, 1)
		var hit := _space.intersect_ray(q)
		if not hit.is_empty():
			start = hit.position
		p.global_position = start + Vector3.UP * 0.1
		p.velocity = Vector3.ZERO
		await _frames(20)
		var hp := p.health.health
		var top := p.global_position.y
		var low := top
		p.debug_use_move_input = true
		for i in 300:
			p.debug_move_input = c[2] if i < 90 else Vector3.ZERO
			await get_tree().physics_frame
			low = minf(low, p.global_position.y)
			if i > 90 and p.is_on_floor() and p.state != PlayerController.State.AIR:
				break
		p.debug_use_move_input = false
		print("  fall %s from y %.1f to %.1f (%.1f m, %.0f units): health %d -> %d, state %d" % [c[0], top, p.global_position.y, top - p.global_position.y, (top - p.global_position.y) / 0.03, hp, p.health.health, p.state])


## CLIMB: known stepping stones the hero must be able to climb onto from
## the water or sludge round them: [area, start, direction to push].
const CLIMB_PROBES := [
	["hidden_forest", Vector3(0.0, -1.7, 14.25), Vector3(0, 0, -1)],
	["hidden_forest", Vector3(0.0, -1.7, 7.25), Vector3(0, 0, -1)],
	["hidden_forest", Vector3(0.0, -1.7, 18.6), Vector3(0, 0, -1)],
	["bog_tower", Vector3(24.1, 0.0, 1.4), Vector3(1, 0, 0)],
	["bog_tower", Vector3(30.1, 0.0, -0.4), Vector3(-1, 0, 0)],
]


func _climb_probes() -> void:
	for c: Array in CLIMB_PROBES:
		await _load(c[0], "")
		await _frames(40)
		var p: PlayerController = GameManager.player
		var dir: Vector3 = c[2]
		p.global_position = c[1]
		p.velocity = Vector3.ZERO
		p.face_direction(dir)
		await _frames(20)
		var y0 := p.global_position.y
		var ok := false
		p.debug_use_move_input = true
		for i in 240:
			p.debug_move_input = dir
			await get_tree().physics_frame
			if p.is_on_floor() and p.global_position.y > y0 + 0.4 and p.state != PlayerController.State.SWIM:
				ok = true
				break
		p.debug_use_move_input = false
		print("  climb %s from %s: %s (state %d at %s)" % [c[0], _v(c[1]), "OK" if ok else "STUCK", p.state, _v(p.global_position)])
		if not ok:
			_report(String(c[0]), "could not climb out onto the stone ahead of %s" % _v(c[1]))


## SWIM: every low stone or tile standing just out of deep water (its top up
## to 0.9 m over the surface) must be one the hero can climb onto from the
## water: he swims up to it and pushes against it.
func _swim(area: String) -> void:
	await _load(area, "")
	var water: Array = World.area_node.get_meta("water", [])
	var tiles: Array = []
	for w: Array in water:
		var r: Rect2 = w[0]
		var wy: float = w[1]
		var step := 1.0
		var x := r.position.x + 0.5
		while x < r.end.x:
			var z := r.position.y + 0.5
			while z < r.end.y:
				var q := PhysicsRayQueryParameters3D.create(Vector3(x, wy + 1.0, z), Vector3(x, wy - 3.0, z), 1)
				var hit := _space.intersect_ray(q)
				if not hit.is_empty() and hit.position.y > wy + 0.05 and hit.position.y < wy + 0.9 and (hit.normal as Vector3).y > 0.85:
					# Deep water beside it (a swim, not a wade) on some side?
					for d: Vector3 in [Vector3(1.6, 0, 0), Vector3(-1.6, 0, 0), Vector3(0, 0, 1.6), Vector3(0, 0, -1.6)]:
						var q2 := PhysicsRayQueryParameters3D.create(Vector3(x, wy + 1.0, z) + d, Vector3(x, wy - 4.0, z) + d, 1)
						var h2 := _space.intersect_ray(q2)
						if h2.is_empty() or h2.position.y < wy - 2.0:
							var key := Vector2i(roundi(hit.position.x / 3.0), roundi(hit.position.z / 3.0))
							if not tiles.any(func(t: Array) -> bool: return t[0] == key):
								tiles.append([key, hit.position, d.normalized(), wy])
							break
				z += step
			x += step
	print("== %s: %d tiles in water" % [area, tiles.size()])
	for t: Array in tiles.slice(0, 12):
		await _load(area, "")
		await _frames(40)
		var p: PlayerController = GameManager.player
		var top: Vector3 = t[1]
		var out: Vector3 = t[2]
		var wy: float = t[3]
		# Find the edge: walk out from the tile's point until off its top.
		var edge := top
		for i in 30:
			var probe := top + out * (0.15 * i)
			var q := PhysicsRayQueryParameters3D.create(Vector3(probe.x, wy + 1.0, probe.z), Vector3(probe.x, wy - 0.5, probe.z), 1)
			if _space.intersect_ray(q).is_empty():
				edge = probe
				break
		p.global_position = Vector3(edge.x, wy - 1.3, edge.z) + out * 1.0
		p.velocity = Vector3.ZERO
		await _frames(30)
		var ok := false
		p.debug_use_move_input = true
		for i in 180:
			p.debug_move_input = -out
			await get_tree().physics_frame
			if p.global_position.y > top.y - 0.15 and p.is_on_floor():
				ok = true
				break
		p.debug_use_move_input = false
		if not ok:
			_report(area, "tile in water at %s (top %.2f over the water): the hero could not climb out onto it (state %d, at %s)" % [_v(top), top.y - wy, p.state, _v(p.global_position)])


## Every loading zone: set down at its return spot, the hero runs straight
## into it. Blocked ones (a locked or sealed way: a blocker within 4.5 m)
## are skipped.
func _exits(area: String) -> void:
	await _load(area, "")
	var zones: Array = []
	for ex: Area3D in _exit_zones():
		zones.append([String(ex.name), ex.global_position, String(ex.get("target_area"))])
	var marks := {}
	var entrances := World.area_node.get_node_or_null("Entrances")
	if entrances:
		for m in entrances.get_children():
			marks[String(m.name)] = (m as Node3D).global_transform
	var blockers: Array = _find_blockers().map(func(bl: Array) -> Vector3: return (bl[0] as Node3D).global_position)
	print("== %s: %d exits" % [area, zones.size()])
	for z: Array in zones:
		var target: String = z[2]
		var at: Vector3 = z[1]
		if blockers.any(func(bp: Vector3) -> bool: return _flat(bp - at).length() < 4.5):
			continue
		var start: Variant = null
		for mname: String in ["from_" + target, "from_" + WorldData.resolve(target)]:
			if marks.has(mname) and _flat((marks[mname] as Transform3D).origin - at).length() < 12.0:
				start = (marks[mname] as Transform3D).origin
		if start == null:
			continue
		await _load(area, "")
		await _frames(60)
		var p: PlayerController = GameManager.player
		p.global_position = start
		p.velocity = Vector3.ZERO
		await _frames(4)
		var entered := false
		p.debug_use_move_input = true
		for i in 240:
			var to := _flat(at - p.global_position)
			if to.length() > 0.05:
				p.debug_move_input = to.normalized()
			await get_tree().physics_frame
			if World.transitioning or World.area_id != area:
				entered = true
				break
		p.debug_use_move_input = false
		if not entered:
			_report(area, "exit %s -> %s: from %s the hero could not run into it (stuck at %s, %.1f m short)" % [z[0], target, _v(start), _v(p.global_position), _flat(at - p.global_position).length()])
		# Let any transition finish before the next load.
		for i in 120:
			if not World.transitioning:
				break
			await get_tree().process_frame
