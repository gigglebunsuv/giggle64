extends "res://tools/world/region.gd"
## The Forest of the Dead: the lost woods between the Desert of Ladhellin and
## the Batela Fells. Dead gray trees grown so thick no one walks between them,
## nine clearings joined by lanes, and fog that turns a traveler round. The
## wisps of the Batela dead, who fled this way when Firebuns burned his land,
## bob at the mouth of the right lane and chime; a wrong lane fades into the
## fog and leads back to where the woods began (OoT's Lost Woods: a wrong exit
## loops to the entrance). Chapter III.
##
## Clearings (a 3 x 3 grid, north is -Z): the road comes in from the desert at
## the south-west clearing and leaves for the Fells from the north-east one.
##   route  SW -> S -> C -> W -> NW -> N -> NE -> east, to the Fells
##   side   S -> SE (a sleeping knight and a chest), C -> E (the old bell
##          and a page of the Fari Incunabulum on a grave)

const STEP := 36.0
## Half the width of a clearing.
const CLEAR := 11.0
## Half the width of a lane.
const LANE := 3.0
## Clearing centers by name.
const C := {
	"sw": Vector2(-36, 36), "s": Vector2(0, 36), "se": Vector2(36, 36),
	"w": Vector2(-36, 0), "c": Vector2(0, 0), "e": Vector2(36, 0),
	"nw": Vector2(-36, -36), "n": Vector2(0, -36), "ne": Vector2(36, -36),
}
## Real lanes (both ways).
const LANES := [["sw", "s"], ["s", "c"], ["c", "w"], ["w", "nw"], ["nw", "n"], ["n", "ne"], ["s", "se"], ["c", "e"]]
## Wrong ways: [clearing, direction] -> a short lane into the fog that loops.
const WRONG := [["c", Vector2(0, -1)], ["w", Vector2(0, 1)], ["e", Vector2(0, -1)], ["se", Vector2(0, -1)],
	["nw", Vector2(-1, 0)], ["s", Vector2(0, 1)]]
## How far a wrong way runs before the fog takes it.
const WRONG_RUN := 7.0
## Where each wisp waits: the way on from each clearing of the route.
const NEXT := {"sw": "s", "s": "c", "c": "w", "w": "nw", "nw": "n", "n": "ne"}


func setup() -> void:
	id = "forest_of_the_dead"
	seed_value = 313
	x_min = -60.0
	x_max = 60.0
	z_min = -60.0
	z_max = 60.0
	rim_height = 14.0
	rim_margin = 6.0
	cliff_col = Color(0.55, 0.55, 0.52)
	rock_col = Color.html("4a4842")
	links = [
		{"to": "desert", "p": Vector2(-60, 36), "d": Vector2(1, 0), "w": LANE, "y": 0.2},
		{"to": "batela_fells", "p": Vector2(60, -36), "d": Vector2(-1, 0), "w": LANE, "y": 0.2},
	]
	mood = {
		"sky_top": Color.html("2a2e30"), "sky_mid": Color.html("3a4040"), "sky_horizon": Color.html("4a5250"),
		"cloud": Color.html("5a6260"), "cloud_amount": 0.6,
		"fog": Color.html("3e4844"), "fog_begin": 5.0, "fog_end": 30.0,
		"ambient": Color.html("4a5654"), "sun": Color.html("aab8c0"), "sun_energy": 0.35, "sun_rot": Vector3(-60, 30, 0),
		"fill": Color.html("3a4a5a"), "fill_energy": 0.3,
		"horizon": Color.html("3e4844"), "hill_height": 8.0, "particles": "ghost",
	}


func _lane_dist(p: Vector2) -> float:
	var best := INF
	for l: Array in LANES:
		best = minf(best, seg_dist(p, C[l[0]], C[l[1]]))
	return best


func base_height(x: float, z: float) -> float:
	var h := 0.3 + noise.get_noise_2d(x * 2.0, z * 2.0) * 0.6
	# Lanes are worn a little lower than the moss either side.
	h -= (1.0 - smoothstep(1.0, LANE + 1.0, _lane_dist(Vector2(x, z)))) * 0.15
	return h


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if _lane_dist(p) < 1.4 + r.randf_range(-0.4, 0.4):
		return pick(r, ["7a7468", "726c60", "827c70"])
	var b := noise.get_noise_2d(x * 5.0, z * 5.0)
	var moss := Color.html("3e463a").lerp(Color.html("54584a"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))
	if r.randf() < 0.04:
		return Color.html("b8b0a0")   # bone-white flecks
	return moss


func surface_at(_x: float, _z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "dirt"


## The sides of clearing `id` that have a way out (a lane, a wrong way or the
## road): Vector2 directions.
func _openings(cid: String) -> Array:
	var out: Array = []
	for l: Array in LANES:
		if l[0] == cid:
			out.append((C[l[1]] - C[cid]).normalized())
		elif l[1] == cid:
			out.append((C[l[0]] - C[cid]).normalized())
	for w: Array in WRONG:
		if w[0] == cid:
			out.append(w[1])
	if cid == "sw":
		out.append(Vector2(-1, 0))
	if cid == "ne":
		out.append(Vector2(1, 0))
	return out


## A hedge of dead trees along the line a -> b, and an invisible wall so no
## one slips between the trunks.
func _hedge(k, a: Vector2, b: Vector2, r: RandomNumberGenerator, thick := true) -> void:
	var d := b - a
	var n: int = maxi(1, int(d.length() / 2.6))
	var side := Vector2(-d.y, d.x).normalized()
	for i in n + 1:
		var t := float(i) / n
		var p := a + d * t + side * r.randf_range(-0.6, 0.6)
		k.tree_dead(p.x, p.y, r.randf_range(0.9, 1.4))
		if thick and r.randf() < 0.7:
			var q := p + side * r.randf_range(1.8, 3.4) * (1.0 if r.randf() < 0.5 else -1.0)
			k.tree_dead(q.x, q.y, r.randf_range(1.0, 1.6))
	k.invisible_wall(a, b, 8.0)


## The walls of a clearing: each side a hedge, broken where a way leads out.
func _clearing_walls(k, cid: String, r: RandomNumberGenerator) -> void:
	var c: Vector2 = C[cid]
	var opens := _openings(cid)
	for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var mid := c + dir * CLEAR
		var along := Vector2(-dir.y, dir.x)
		if opens.has(dir):
			_hedge(k, mid - along * CLEAR, mid - along * LANE, r)
			_hedge(k, mid + along * LANE, mid + along * CLEAR, r)
		else:
			_hedge(k, mid - along * CLEAR, mid + along * CLEAR, r)


## The walls along a lane from clearing edge to clearing edge.
func _lane_walls(k, a: Vector2, b: Vector2, r: RandomNumberGenerator) -> void:
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var p0 := a + dir * CLEAR
	var p1 := b - dir * CLEAR
	for s in [-1.0, 1.0]:
		_hedge(k, p0 + side * LANE * s, p1 + side * LANE * s, r)


## A wrong way: a lane into the fog that ends in a loading zone back to the
## entrance (from_desert).
func _wrong_way(k, cid: String, dir: Vector2, r: RandomNumberGenerator) -> void:
	var c: Vector2 = C[cid]
	var side := Vector2(-dir.y, dir.x)
	var p0 := c + dir * CLEAR
	var p1 := c + dir * (CLEAR + WRONG_RUN)
	for s in [-1.0, 1.0]:
		_hedge(k, p0 + side * LANE * s, p1 + side * LANE * s, r)
	_hedge(k, p1 + dir * 1.5 - side * LANE, p1 + dir * 1.5 + side * LANE, r, false)
	var at := p1 - dir * 1.0
	k.area_exit(Vector3(at.x, k.h(at.x, at.y) + 2.0, at.y), k.yaw_of(dir), Vector3(LANE * 2.0, 6.0, 1.5), id, "from_desert")
	# A darker veil of fog hangs where the lane gives out.
	for i in 3:
		var q := p1 - dir * (2.0 + i * 1.2) + side * r.randf_range(-1.5, 1.5)
		k.rock(q.x, q.y, r.randf_range(0.4, 0.8), "rock", false, Color(0.55, 0.55, 0.55))


func _grave(k, x: float, z: float, yaw: float, r: RandomNumberGenerator) -> void:
	var m = k._tmp()
	var base: Vector3 = k.g(x, z, -0.1)
	m.push(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.2, 0.2)) * Basis(Vector3.RIGHT, r.randf_range(-0.12, 0.12)), base))
	var col := Color(0.7, 0.7, 0.68).darkened(r.randf_range(0.0, 0.2))
	m.box(Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.18), col)
	m.box(Vector3(0, 1.02, 0), Vector3(0.5, 0.12, 0.18), col)
	m.box(Vector3(0, 0.06, 0.6), Vector3(0.8, 0.14, 1.3), Color(0.32, 0.3, 0.26))
	m.pop()
	k.merge(m, "stone")
	k.col_box(base + Vector3(0, 0.5, 0), Vector3(0.7, 1.0, 0.25), yaw)


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for cid: String in C:
		_clearing_walls(k, cid, r)
	for l: Array in LANES:
		_lane_walls(k, C[l[0]], C[l[1]], r)
	for w: Array in WRONG:
		_wrong_way(k, w[0], w[1], r)
	# The road in and out: hedges along the corridors to the edges.
	for pair in [[C.sw, Vector2(-1, 0)], [C.ne, Vector2(1, 0)]]:
		var c: Vector2 = pair[0]
		var dir: Vector2 = pair[1]
		var side := Vector2(-dir.y, dir.x)
		for s in [-1.0, 1.0]:
			_hedge(k, c + dir * CLEAR + side * LANE * s, c + dir * 26.0 + side * LANE * s, r)
	# The wisps: one at the mouth of the right lane out of each clearing of the route.
	for cid: String in NEXT:
		var dir: Vector2 = (C[NEXT[cid]] - C[cid]).normalized()
		var at: Vector2 = C[cid] + dir * (CLEAR - 2.0)
		k.wisp(Vector3(at.x, k.h(at.x, at.y) + 1.6, at.y), Vector3(dir.x, 0, dir.y))
	var out: Vector2 = C.ne + Vector2(CLEAR - 2.0, 0)
	k.wisp(Vector3(out.x, k.h(out.x, out.y) + 1.6, out.y), Vector3(1, 0, 0))
	# Graves in every clearing, more toward the Fells.
	for cid: String in C:
		var c: Vector2 = C[cid]
		var n := 2 + r.randi_range(0, 3)
		for i in n:
			var p := c + Vector2(r.randf_range(-7.5, 7.5), r.randf_range(-7.5, 7.5))
			if p.distance_to(c) < 3.0:
				continue
			_grave(k, p.x, p.y, r.randf() * TAU, r)
		for i in 3:
			var p := c + Vector2(r.randf_range(-8.0, 8.0), r.randf_range(-8.0, 8.0))
			if p.distance_to(c) > 4.0:
				k.rock(p.x, p.y, r.randf_range(0.4, 0.9), "rock", true, Color(0.62, 0.62, 0.6))
		k.stump(c.x + r.randf_range(-6, 6), c.y + r.randf_range(-6, 6), r.randf_range(0.8, 1.2))
	# The old bell of Batela's dead, hung in a dead tree in the east clearing.
	var bell: Vector2 = C.e + Vector2(3.0, -3.0)
	k.tree_dead(bell.x, bell.y, 1.8)
	var bm = k._tmp(false)
	var bp: Vector3 = k.g(bell.x, bell.y) + Vector3(1.4, 3.0, 0)
	bm.prism(bp + Vector3(0, -0.6, 0), 0.45, bp, 0.22, 10, Color.html("5a6a5a"))
	bm.box(bp + Vector3(0, 0.25, 0), Vector3(0.05, 0.5, 0.05), Color.html("3a3026"))
	k.merge(bm, "char")
	# A signpost at the edge of the woods.
	k.signpost(-50.0, 32.0, Vector2(-44, 36), "*Forest of the Dead*\nThe dead know the way.\nFollow the lights, or walk forever.")


func populate(k) -> void:
	k.enemies_near("keese", C.s, 7.0, 2)
	k.enemies_near("keese", C.nw, 7.0, 2)
	k.enemies_near("charred_stalfos", C.c, 5.0, 1)
	k.enemies_near("charred_stalfos", C.n, 5.0, 1)
	k.enemies_near("stalfos", C.se, 4.0, 1)
	# The side clearings: a chest guarded in the south-east, a page of the
	# Fari Incunabulum on a grave in the east.
	k.chest(C.se.x + 6.0, C.se.y + 5.0, PI, "rupee_red", false, "dead_forest:chest")
	k.incunabulum_page(C.e.x - 3.0, C.e.y + 4.0, 1)
	for cid: String in ["sw", "w", "n", "ne"]:
		k.shrubs_near(C[cid], 6.0, 3, Color(0.7, 0.7, 0.6))
	k.pot(C.ne.x - 6.0, C.ne.y - 7.0)
	k.pot(C.ne.x - 7.0, C.ne.y - 6.0, "heart")
