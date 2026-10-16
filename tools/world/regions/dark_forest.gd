extends "res://tools/world/region.gd"
## The Dark Forest (Chapter IV): the old wood south of the Desert of
## Ladhellin that the legends say the sleeping sword's grove lies in. Vast
## black-barked trees, violet fog, glowing fungus, the howl of shadow wolves.
## Like the Forest of the Dead it is a maze that turns travelers round (a
## wrong lane leads back to where the wood began), but here no wisps help:
## the way is marked by STAR-STONES, old waymarks of Lothelye's priests that
## only show in her own light. Hold up the lit Starlight Lantern and the
## stone at the mouth of the true lane glows (StarStone).
##
## Sixteen clearings (4 x 4, north is -Z). The road comes in from the desert
## at the north clearing n2 and ends at the SACRED GROVE in the south-east,
## where the old stair down to the Temple of Bun lies buried (the Grave
## Spade digs it out: DigSpot "grove_stair", flag "ch4:temple_found").
##   route  n2 -> b2 -> b1 -> c1 -> c2 -> s2 -> grove
##   side   b1 -> n1 -> n0 (a Piece of Heart in a hollow tree)
##          c2 -> c3 (a treasure chart in a ruined shrine)
##          c1 -> c0 -> s0 (the wolves' den, a chest)
##          b2 -> b3 (a pool with a fairy)

const STEP := 34.0
const CLEAR := 11.0
const LANE := 3.0
## Clearing centers. Rows n, b, c, s run north to south; columns 0..3 west to east.
const C := {
	"n0": Vector2(-51, -51), "n1": Vector2(-17, -51), "n2": Vector2(17, -51), "n3": Vector2(51, -51),
	"b0": Vector2(-51, -17), "b1": Vector2(-17, -17), "b2": Vector2(17, -17), "b3": Vector2(51, -17),
	"c0": Vector2(-51, 17), "c1": Vector2(-17, 17), "c2": Vector2(17, 17), "c3": Vector2(51, 17),
	"s0": Vector2(-51, 51), "s1": Vector2(-17, 51), "s2": Vector2(17, 51), "grove": Vector2(51, 51),
}
const LANES := [["n2", "b2"], ["b2", "b1"], ["b1", "c1"], ["c1", "c2"], ["c2", "s2"], ["s2", "grove"],
	["b1", "n1"], ["n1", "n0"], ["c2", "c3"], ["c1", "c0"], ["c0", "s0"], ["b2", "b3"]]
## Wrong ways (into the fog, back to the start).
const WRONG := [["n2", Vector2(1, 0)], ["b2", Vector2(0, 1)], ["b1", Vector2(-1, 0)], ["c1", Vector2(0, 1)],
	["c2", Vector2(0, -1)], ["s2", Vector2(-1, 0)], ["n1", Vector2(0, 1)], ["c0", Vector2(0, -1)], ["b3", Vector2(0, -1)], ["c3", Vector2(0, 1)]]
const WRONG_RUN := 7.0
## The route: from each clearing, the true way on (a star-stone at its mouth).
const NEXT := {"n2": "b2", "b2": "b1", "b1": "c1", "c1": "c2", "c2": "s2", "s2": "grove"}
## The sacred grove is larger than the other clearings.
const GROVE_R := 15.0
const STAIR := Vector2(55.0, 55.0)


func setup() -> void:
	id = "dark_forest"
	seed_value = 4141
	x_min = -74.0
	x_max = 74.0
	z_min = -74.0
	z_max = 74.0
	rim_height = 16.0
	rim_margin = 6.0
	cliff_col = Color(0.32, 0.3, 0.36)
	rock_col = Color.html("2e2a34")
	links = [
		{"to": "desert", "p": Vector2(17, -74), "d": Vector2(0, 1), "w": LANE, "y": 0.2},
	]
	mood = {
		"sky_top": Color.html("120e1c"), "sky_mid": Color.html("1e1830"), "sky_horizon": Color.html("2e2442"),
		"cloud": Color.html("2a2438"), "cloud_amount": 0.7,
		"fog": Color.html("221c34"), "fog_begin": 4.0, "fog_end": 30.0,
		"ambient": Color.html("3a3450"), "sun": Color.html("9a90c8"), "sun_energy": 0.3, "sun_rot": Vector3(-70, 20, 0),
		"fill": Color.html("2a2a4a"), "fill_energy": 0.3,
		"horizon": Color.html("221c34"), "hill_height": 10.0, "particles": "ghost",
	}


func _size(cid: String) -> float:
	return GROVE_R if cid == "grove" else CLEAR


func _lane_dist(p: Vector2) -> float:
	var best := INF
	for l: Array in LANES:
		best = minf(best, seg_dist(p, C[l[0]], C[l[1]]))
	return best


func base_height(x: float, z: float) -> float:
	var h := 0.3 + noise.get_noise_2d(x * 2.0, z * 2.0) * 0.7
	h -= (1.0 - smoothstep(1.0, LANE + 1.0, _lane_dist(Vector2(x, z)))) * 0.15
	# The grove's floor rises a little toward the great tree.
	h += maxf(0.0, 1.0 - Vector2(x, z).distance_to(C.grove) / GROVE_R) * 0.6
	return h


func ground_color(x: float, z: float, _h: float, r: RandomNumberGenerator) -> Color:
	var p := Vector2(x, z)
	if p.distance_to(C.grove) < GROVE_R:
		# Pale moss and white flowers in the grove: the one gentle place.
		if r.randf() < 0.05:
			return Color.html("e8e4f8")
		return Color.html("3e5a3a").lerp(Color.html("4e6a46"), r.randf())
	if _lane_dist(p) < 1.4 + r.randf_range(-0.4, 0.4):
		return pick(r, ["4a4048", "524650", "443a42"])
	var b := noise.get_noise_2d(x * 5.0, z * 5.0)
	var moss := Color.html("1e2620").lerp(Color.html("2a3428"), clampf(b + 0.5 + r.randf_range(-0.15, 0.15), 0.0, 1.0))
	if r.randf() < 0.03:
		return Color.html("8a6ac8")   # violet fungus
	return moss


func surface_at(x: float, z: float, _h: float, _r: RandomNumberGenerator) -> String:
	return "grass" if Vector2(x, z).distance_to(C.grove) < GROVE_R else "dirt"


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
	if cid == "n2":
		out.append(Vector2(0, -1))
	return out


## A wall of great black trees along a -> b (and an invisible wall).
func _hedge(k, a: Vector2, b: Vector2, r: RandomNumberGenerator, thick := true) -> void:
	var d := b - a
	var n: int = maxi(1, int(d.length() / 3.0))
	var side := Vector2(-d.y, d.x).normalized()
	for i in n + 1:
		var t := float(i) / n
		var p := a + d * t + side * r.randf_range(-0.6, 0.6)
		if i % 3 == 0:
			k.tree_giant(p.x, p.y, r.randf_range(0.9, 1.3), r.randf_range(14.0, 22.0))
		else:
			k.tree_round(p.x, p.y, r.randf_range(1.2, 1.7), Color(0.32, 0.3, 0.45))
		if thick and r.randf() < 0.5:
			var q := p + side * r.randf_range(2.0, 3.6) * (1.0 if r.randf() < 0.5 else -1.0)
			k.tree_round(q.x, q.y, r.randf_range(1.3, 1.8), Color(0.28, 0.26, 0.4))
	k.invisible_wall(a, b, 10.0)


func _clearing_walls(k, cid: String, r: RandomNumberGenerator) -> void:
	var c: Vector2 = C[cid]
	var s := _size(cid)
	var opens := _openings(cid)
	for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var mid := c + dir * s
		var along := Vector2(-dir.y, dir.x)
		if opens.has(dir):
			_hedge(k, mid - along * s, mid - along * LANE, r)
			_hedge(k, mid + along * LANE, mid + along * s, r)
		else:
			_hedge(k, mid - along * s, mid + along * s, r)


func _lane_walls(k, a_id: String, b_id: String, r: RandomNumberGenerator) -> void:
	var a: Vector2 = C[a_id]
	var b: Vector2 = C[b_id]
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var p0 := a + dir * _size(a_id)
	var p1 := b - dir * _size(b_id)
	for s in [-1.0, 1.0]:
		_hedge(k, p0 + side * LANE * s, p1 + side * LANE * s, r)


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
	for i in 3:
		var q := p1 - dir * (2.0 + i * 1.2) + side * r.randf_range(-1.5, 1.5)
		k.mushroom(q.x, q.y, r.randf_range(0.8, 1.3), Color.html("6a4ab8"))


func build(k) -> void:
	var r: RandomNumberGenerator = k.rng
	for cid: String in C:
		_clearing_walls(k, cid, r)
	for l: Array in LANES:
		_lane_walls(k, l[0], l[1], r)
	for w: Array in WRONG:
		_wrong_way(k, w[0], w[1], r)
	# The road in from the desert.
	var c0: Vector2 = C.n2
	for s in [-1.0, 1.0]:
		_hedge(k, c0 + Vector2(LANE * s, -CLEAR), c0 + Vector2(LANE * s, -24.0), r)
	# The star-stones at the mouth of each true lane.
	for cid: String in NEXT:
		var dir: Vector2 = (C[NEXT[cid]] - C[cid]).normalized()
		var at: Vector2 = C[cid] + dir * (_size(cid) - 2.0) + Vector2(-dir.y, dir.x) * (LANE + 0.6)
		k._dyn("res://scripts/dungeon/star_stone.gd", "StarStone", k.g(at.x, at.y, -0.1), k.yaw_of(dir), {}, Node3D.new())
	# Fungus and fallen logs in every clearing.
	for cid: String in C:
		if cid == "grove":
			continue
		var c: Vector2 = C[cid]
		for i in 4:
			var p := c + Vector2(r.randf_range(-8.0, 8.0), r.randf_range(-8.0, 8.0))
			if p.distance_to(c) > 3.5:
				k.mushroom(p.x, p.y, r.randf_range(0.6, 1.4), Color.html(["6a4ab8", "4a8ab8", "b84a8a"][i % 3]))
		k.log(c.x + r.randf_range(-6, 6), c.y + r.randf_range(-6, 6), r.randf_range(3.0, 5.0), r.randf() * TAU)
	_grove(k, r)
	_sides(k, r)
	k.signpost(13.5, -62.0, Vector2(17, -56), "*The Dark Forest*\nTurn back.\nWhat is lost in here stays lost.")


## The sacred grove: a ring of white-barked trees round a great old one, a
## broken ring of standing stones, and before the tree, the soft earth over
## the buried stair (dug out: the steps down to the Temple of Bun).
func _grove(k, r: RandomNumberGenerator) -> void:
	var c: Vector2 = C.grove
	k.tree_great(c.x - 2.0, c.y - 3.0, 1.6)
	for i in 10:
		var a := TAU * i / 10.0
		k.tree_round(c.x + cos(a) * 11.5, c.y + sin(a) * 11.5, r.randf_range(1.0, 1.3), Color(1.2, 1.25, 1.3))
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		k.pillar(c.x + cos(a) * 8.0, c.y + sin(a) * 8.0, 3.6, 0.6, i % 3 == 0, "stone")
	k.flowers(c.x - 4.0, c.y + 4.0, 3.0, 16, ["f0f0ff", "d8d0f8", "ffffff"])
	k.flowers(c.x + 3.0, c.y - 6.0, 2.5, 12, ["f0f0ff", "d8d0f8", "ffffff"])
	# The buried stair: steps down, an old door at their foot (the temple).
	var st := STAIR
	var y: float = k.h(st.x, st.y)
	var m = k._tmp()
	for i in 6:
		m.box(Vector3(st.x, y - 0.3 - i * 0.45, st.y - 1.0 + i * 0.6), Vector3(2.6, 0.45, 0.6), Color(0.72, 0.7, 0.66))
	m.box(Vector3(st.x - 1.6, y - 1.4, st.y + 0.6), Vector3(0.5, 3.2, 4.6), Color(0.62, 0.6, 0.58))
	m.box(Vector3(st.x + 1.6, y - 1.4, st.y + 0.6), Vector3(0.5, 3.2, 4.6), Color(0.62, 0.6, 0.58))
	m.box(Vector3(st.x, y - 1.6, st.y + 3.0), Vector3(3.6, 3.6, 0.5), Color(0.62, 0.6, 0.58))
	var stair_props = k.flag_props("ch4:temple_found", m, "stone")
	stair_props.name = "BuriedStair"
	k.door_link(Vector3(st.x, y - 3.0, st.y + 2.7), PI, 1.6, 2.4, "temple_of_bun", "", Color(0.85, 0.82, 0.7), "ch4:temple_found")
	k.entrance("from_temple_of_bun", st.x, st.y - 3.0, 0.0)
	# The earth over it, solid until it is dug away.
	var mound = k._tmp()
	mound.icosa(Vector3(st.x, y - 0.2, st.y + 0.8), Vector3(2.4, 0.7, 2.8), 0.08, Color.html("3a3024"), true)
	k.flag_barrier(Vector3(st.x, y - 1.2, st.y + 0.8), Vector3(4.0, 3.6, 5.4), 0.0, "ch4:temple_found", mound, "char")
	k.dig_spot("grove_stair", st.x, st.y - 1.4, "", {"reveal_flag": "ch4:temple_found"})
	k.mark("cs_grove_cam", Vector3(c.x - 8.0, y + 4.0, c.y - 10.0))
	k.story_trigger("grove_arrive", Rect2(c.x - GROVE_R, c.y - GROVE_R, 6.0, GROVE_R * 2.0), k.h(c.x - GROVE_R + 3.0, c.y) - 0.5, "ch4:grove_seen")


func _sides(k, r: RandomNumberGenerator) -> void:
	# n0: a hollow tree with a Piece of Heart in it (Hookshot up to the hollow).
	var h0: Vector2 = C.n0 + Vector2(-4.0, -4.0)
	k.tree_giant(h0.x, h0.y, 1.6, 20.0)
	k.platform(h0.x + 2.2, h0.y + 2.2, Vector2(2.4, 2.4), k.h(h0.x, h0.y) + 4.0, "wood", Color(0.35, 0.3, 0.3))
	k.heart_piece(h0.x + 2.2, h0.y + 2.2, "dark_forest:heart_piece", k.h(h0.x, h0.y) + 4.6)
	k.hook_target(Vector3(h0.x + 2.2, k.h(h0.x, h0.y) + 5.8, h0.y + 0.9), PI)
	# c3: a ruined shrine of Lothelye's priests, a chart scrap on its altar.
	var s3: Vector2 = C.c3
	for i in 5:
		var a := TAU * i / 5.0
		k.pillar(s3.x + cos(a) * 5.0, s3.y + sin(a) * 5.0, 4.0, 0.5, i != 2, "stone")
	k.platform(s3.x, s3.y, Vector2(3.0, 2.0), k.h(s3.x, s3.y) + 0.8, "stone", Color(0.8, 0.78, 0.74))
	k.chest(s3.x, s3.y, PI, "chart_4", false, "dark_forest:chest_chart", "", k.h(s3.x, s3.y) + 0.8)
	# s0: the wolves' den, bones and a chest.
	var d0: Vector2 = C.s0
	for i in 8:
		k.rock(d0.x + r.randf_range(-6, 6), d0.y + r.randf_range(-6, 6), 0.25, "char", false, Color.html("e8e0d0"))
	k.chest(d0.x + 5.0, d0.y + 5.0, PI, "rupee_purple", false, "dark_forest:chest_den", "", INF)
	# b3: a still pool, and a fairy over it.
	k.water_plane(Rect2(C.b3.x - 4.0, C.b3.y - 3.0, 8.0, 6.0), k.h(C.b3.x, C.b3.y) - 0.15, Color(0.3, 0.32, 0.55, 0.7))
	k.reeds(C.b3.x - 4.5, C.b3.y, 5, Color.html("3a4a5a"))


func populate(k) -> void:
	k.enemies_near("shadow_wolf", C.b2, 6.0, 2)
	k.enemies_near("shadow_wolf", C.c1, 6.0, 2)
	k.enemies_near("shadow_wolf", C.s0, 5.0, 3)
	k.enemies_near("shadow_wolf", C.s2, 6.0, 2)
	k.enemies_near("shade", C.b1, 6.0, 1)
	k.enemies_near("shade", C.c2, 6.0, 1)
	k.enemies_near("keese", C.n1, 6.0, 2)
	k.enemies_near("snapper", C.c0, 6.0, 2)
	k.enemies_near("snapper", C.n0, 6.0, 2)
	for cid: String in ["n2", "b1", "c2", "s2"]:
		k.shrubs_near(C[cid], 6.0, 3, Color(0.5, 0.45, 0.65))
	k.pot(C.n2.x + 6.0, C.n2.y - 6.0, "heart")
	k.pot(C.s2.x - 6.0, C.s2.y + 6.0, "magic_small")
	# A fairy over the pool in b3 (always; it is the forest's one kindness).
	k._dyn("res://scripts/items/fairy.gd", "PoolFairy", k.g(C.b3.x, C.b3.y, 1.2), 0.0, {}, Node3D.new())
