extends "res://tools/world/tower_region.gd"
## THE ASTRAL RIFT (Beta 1.5.0), the last dungeon: the broken edge of the
## Astral Dimension behind the crack over Black Water Ridge. No sky, no
## ground, no stars: only dark, and drifting in it MEMORY ISLANDS, pieces of
## every place the hero has been, walled with old stone and joined by
## bridges, some of dream-light (Lothelye's Dream). Five drifts of islands
## hang far apart at different heights; rings of starlight (AstralGate) carry
## the hero between them. 40 rooms.
##
##   1F  THE SHORE OF STARS (y 0, the lake's memory; the hub)
##       landing S (in from the Ridge) -> HUB C: the four star locks, and in
##       the middle a spiral stair of dream-light up to the gate to the heart
##       (lock 4). Gates: W -> 2F (lock 1), E -> 3F (lock 2), N -> 4F (lock 3).
##       mirror SW (by dream-light from W): a pit; the Hookshot across -> MAP
##       drowned NW: a crystal switch across a pit raises a bridge -> KEY
##       lily SE: a fight -> COMPASS
##       lock 1 NE: locked (key); tide knights; STAR LOCK 1
##   2F  THE SPIRES OF MEMORY (y 14, Skyreach's sky): wind over the void
##       (the gale walk -> key), the Hookshot over a pit to a switch (bars ->
##       a chest), a dream-light island, the SPIRE ECHO (corvax) -> LOCK 2
##   3F  THE BURNING HALLS (y 28, the Citadel's fire): fire jets the Sapphire
##       Staff blocks (-> key), star braziers for starlight (bars), the
##       EMBER ECHO (ember knight) -> LOCK 3
##   4F  THE BARROW OF NIGHT (y 42, the dead): a great stone the Gauntlets
##       drag (-> key), three bells for the Iron Flail (bars -> the BOSS
##       KEY), the BARROW ECHO (barrow champion) -> LOCK 4
##   5F  THE HEART (y 60): the starfield (a maze of dream-light over the
##       void, veils of dark), the hall of remembrance, a fountain, AVALON'S
##       garden (her scene), the antechamber, and THE SHATTERED PRISON: the
##       boss door (the boss key), FIREBUNS III, the true final battle.

const D := "astral_rift"
const STONE := Color(0.62, 0.62, 0.74)
const DREAM := Color(0.72, 0.64, 1.0)
const ROOM_H := 3.4
const STEP := 28.0
## Each drift of islands: storey -> [origin (x, z), floor height, wall color, name].
const GROUPS := {
	1: [Vector2(0, 0), 0.0, Color(0.6, 0.7, 0.82), "THE SHORE OF STARS"],
	2: [Vector2(-130, -70), 14.0, Color(0.74, 0.78, 0.86), "THE SPIRES OF MEMORY"],
	3: [Vector2(130, -70), 28.0, Color(0.7, 0.5, 0.44), "THE BURNING HALLS"],
	4: [Vector2(0, -150), 42.0, Color(0.42, 0.44, 0.5), "THE BARROW OF NIGHT"],
	5: [Vector2(0, -270), 60.0, Color(0.82, 0.8, 0.94), "THE HEART OF THE RIFT"],
}
## [room a, room b, kind]: "stone", "dream", "barred:<flag>", "locked:<flag>"
## (the door into b is locked), "boss:<flag>".
var bridges: Array = []
## Bridge rects per storey, for the maps.
var _bridge_rects: Array = []


func setup() -> void:
	id = "astral_rift"
	interior = true
	seed_value = 1550
	x_min = -175.0
	x_max = 175.0
	z_min = -340.0
	z_max = 40.0
	outer = 10.0
	cell = 2.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["VOID", -60.0], ["1F", 0.0], ["2F", 14.0], ["3F", 28.0], ["4F", 42.0], ["5F", 60.0]]
	entry_floor = 1
	wall_col = STONE
	ceil_col = Color(0.2, 0.2, 0.28)
	slab_col = Color(0.7, 0.7, 0.82)
	rooms = {}
	# 1F: the hub drift.
	_room("landing", 1, 0, 1, 16, 14)
	_room("hub", 1, 0, 0, 24, 24)
	_room("w1", 1, -1, 0)
	_room("e1", 1, 1, 0)
	_room("n1", 1, 0, -1)
	_room("mirror", 1, -1, 1)
	_room("drowned", 1, -1, -1)
	_room("lily", 1, 1, 1)
	_room("lock1", 1, 1, -1)
	bridges = [
		["landing", "hub", "stone"], ["hub", "w1", "stone"], ["hub", "e1", "stone"], ["hub", "n1", "stone"],
		["w1", "mirror", "dream"], ["w1", "drowned", "stone"], ["e1", "lily", "stone"], ["e1", "lock1", "locked:" + D + ":door_lock1"],
	]
	# 2F-4F: the same plan, each drift its own memory.
	for f in [2, 3, 4]:
		var s := str(f)
		_room("arrive" + s, f, 0, 1, 16, 14)
		_room("rest" + s, f, -1, 1, 16, 16)
		_room("hall" + s, f, 0, 0)
		_room("west" + s, f, -1, 0)
		_room("nw" + s, f, -1, -1, 16, 16)
		_room("east" + s, f, 1, 0)
		_room("ne" + s, f, 1, -1, 16, 16)
		_room("lock" + s, f, 0, -1)
		bridges.append_array([
			["arrive" + s, "hall" + s, "stone"], ["arrive" + s, "rest" + s, "stone"], ["hall" + s, "west" + s, "stone"],
			["west" + s, "nw" + s, "dream"], ["hall" + s, "east" + s, "stone"], ["east" + s, "ne" + s, "barred:" + D + ":bars" + s],
			["hall" + s, "lock" + s, "locked:" + D + ":door_lock" + s],
		])
	# 5F: the heart.
	_room("in5", 5, 0, 1, 16, 14)
	_room("star", 5, 0, 0, 26, 26)
	_room("rem", 5, -1, 0, 16, 16)
	_room("fount", 5, 1, 0, 16, 16)
	_room("avalon", 5, 0, -1, 20, 20)
	_room("ante", 5, 0, -2, 14, 10)
	var g5: Vector2 = GROUPS[5][0]
	rooms["prison"] = {"f": 5, "r": Rect2(g5.x - 17.0, g5.y - 3.0 * STEP - 26.0, 34.0, 34.0), "h": ROOM_H, "ceiling": false, "doors": [], "col": Color(0.5, 0.56, 0.72)}
	bridges.append_array([
		["in5", "star", "stone"], ["star", "rem", "stone"], ["star", "fount", "stone"], ["star", "avalon", "stone"],
		["avalon", "ante", "stone"], ["ante", "prison", "boss:" + D + ":boss_door"],
	])
	for b: Array in bridges:
		_link(b)
	corridors = []
	holes = []
	# The pits: the mirror's and the drowned shrine's on 1F, the hook room on
	# 2F, and the starfield's whole floor (dream-light only) on 5F.
	for pit: Array in pits():
		holes.append({"f": pit[0], "r": pit[1]})
	mood = {
		"sky_top": Color.html("030208"), "sky_mid": Color.html("07050f"), "sky_horizon": Color.html("0e0a1c"),
		"cloud": Color.html("0a0814"), "cloud_amount": 0.0,
		"fog": Color.html("0a0816"), "fog_begin": 30.0, "fog_end": 150.0,
		"ambient": Color.html("6a6a8e"), "sun": Color.html("c8c8ff"), "sun_rot": Vector3(-60, 30, 0),
		"sun_energy": 0.7, "fill": Color.html("4a3a7a"), "fill_energy": 0.6,
		"horizon": Color.html("030208"), "hill_height": 0.0, "particles": "motes",
	}


## The pits that make the puzzles (no walking round them): [storey, rect].
##   mirror   wall to wall, between the way in (north) and the Map's island
##            (south): only the Hookshot crosses
##   drowned  wall to wall, between the way in (south) and the switch and the
##            key (north): something thrown or shot must reach the switch
##   east2    a band north to south between the way in (west) and the switch
##            and the barred door (east): the Hookshot again
##   west2    the gale walk: only a strip along the north wall, where the wind
##            blows toward the pit
##   star     the starfield's whole floor but a landing at each door
func pits() -> Array:
	var mr: Rect2 = rooms.mirror.r
	var dr: Rect2 = rooms.drowned.r
	var er: Rect2 = rooms.east2.r
	var wr: Rect2 = rooms.west2.r
	var sr: Rect2 = rooms.star.r
	return [
		[1, Rect2(mr.position.x + 0.8, mr.position.y + 5.0, mr.size.x - 1.6, mr.size.y - 9.0)],
		[1, Rect2(dr.position.x + 0.8, dr.position.y + 5.0, dr.size.x - 1.6, dr.size.y - 10.0)],
		[2, Rect2(er.get_center().x - 7.5, er.position.y + 0.8, 5.7, er.size.y - 1.6)],
		[2, Rect2(wr.get_center().x - 3.0, wr.position.y + 4.0, 6.0, wr.size.y - 4.8)],
		[5, sr.grow(-0.8)],
	]


## A room in drift `f`, grid cell (i, j) from its origin (north is -j).
func _room(rid: String, f: int, i: int, j: int, w := 20.0, d := 20.0) -> void:
	var o: Vector2 = GROUPS[f][0]
	var c := o + Vector2(i * STEP, j * STEP)
	rooms[rid] = {"f": f, "r": Rect2(c.x - w * 0.5, c.y - d * 0.5, w, d), "h": ROOM_H, "ceiling": false, "doors": [], "col": GROUPS[f][2]}


func _inset(rid: String, ix: float, iz: float) -> Rect2:
	var r: Rect2 = rooms[rid].r
	return r.grow_individual(-ix, -iz, -ix, -iz)


## A bridge's doors in both rooms' walls, and its deck (for the map).
func _link(b: Array) -> void:
	var ra: Rect2 = rooms[b[0]].r
	var rb: Rect2 = rooms[b[1]].r
	var ca := ra.get_center()
	var cb := rb.get_center()
	var along_x := absf(ca.y - cb.y) < 0.5
	var deck: Rect2
	if along_x:
		var east := cb.x > ca.x
		rooms[b[0]].doors.append({"side": "e" if east else "w", "at": ca.y})
		rooms[b[1]].doors.append({"side": "w" if east else "e", "at": ca.y})
		var x0 := (ra.end.x if east else rb.end.x) + 0.8
		var x1 := (rb.position.x if east else ra.position.x) - 0.8
		deck = Rect2(x0, ca.y - 1.5, x1 - x0, 3.0)
	else:
		var south := cb.y > ca.y
		rooms[b[0]].doors.append({"side": "s" if south else "n", "at": ca.x})
		rooms[b[1]].doors.append({"side": "n" if south else "s", "at": ca.x})
		var z0 := (ra.end.y if south else rb.end.y) + 0.8
		var z1 := (rb.position.y if south else ra.position.y) - 0.8
		deck = Rect2(ca.x - 1.5, z0, 3.0, z1 - z0)
	b.append(deck)
	_bridge_rects.append([int(rooms[b[0]].f), deck])


func map_walkable_floor(x: float, z: float, f: int) -> bool:
	if super.map_walkable_floor(x, z, f):
		return true
	for br: Array in _bridge_rects:
		if br[0] == f and (br[1] as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## The void far below: dark violet with a scatter of stars.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if f == 0:
		var n := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
		if n > 0.996:
			return Color.html("e8e8ff")
		return Color.html(["06040e", "08061a", "050310"][r.randi() % 3])
	if f == 5:
		var p := Vector2(x, z)
		if (rooms.prison.r as Rect2).has_point(p):
			return Color.html(["10101a", "14141f", "0c0c16"][r.randi() % 3])
	if fposmod(x, 2.0) < 0.07 or fposmod(z, 2.0) < 0.07:
		return Color.html("3a3a4e")
	var base: Color = GROUPS.get(f, GROUPS[1])[2]
	return base.darkened(0.25 + r.randf_range(0.0, 0.08))


func build_rooms(k) -> void:
	for b: Array in bridges:
		_bridge(k, b)
	for f in [1, 2, 3, 4, 5]:
		var o: Vector2 = GROUPS[f][0]
		var y: float = GROUPS[f][1]
		# Catch whoever falls off a drift (back to the room he came in by).
		k.void_zone(Vector3(o.x, y - 16.0, o.y - (40.0 if f == 5 else 0.0)), Vector3(110.0, 4.0, 160.0 if f == 5 else 110.0), 2)
		_drift(k, f)
	_g1(k)
	for f in [2, 3, 4]:
		_gate_rooms(k, f)
	_g2(k)
	_g3(k)
	_g4(k)
	_g5(k)


func _y(rid: String) -> float:
	return room_y(rid)


func _c(rid: String) -> Vector2:
	return room_center(rid)


func _bridge(k, b: Array) -> void:
	var kind: String = b[2]
	var deck: Rect2 = b[3]
	var y := _y(b[0])
	if kind == "dream":
		k.dream_light(Vector3(deck.get_center().x, y - 0.25, deck.get_center().y), Vector3(deck.size.x, 0.5, deck.size.y), "path", DREAM)
	else:
		k.floor_slab(deck, y, [], "stone", STONE.darkened(0.1))
		var along_x := deck.size.x > deck.size.y
		for side in [-1.0, 1.0]:
			if along_x:
				k.block(Vector3(deck.get_center().x, y + 0.3, deck.get_center().y + side * 1.35), Vector3(deck.size.x, 0.6, 0.3), 0.0, "stone", STONE)
			else:
				k.block(Vector3(deck.get_center().x + side * 1.35, y + 0.3, deck.get_center().y), Vector3(0.3, 0.6, deck.size.y), 0.0, "stone", STONE)
	if kind.begins_with("locked:") or kind.begins_with("boss:") or kind.begins_with("barred:"):
		var rb: Rect2 = rooms[b[1]].r
		var ca := _c(b[0])
		var cb := rb.get_center()
		var flag := kind.get_slice(":", 1) + ":" + kind.get_slice(":", 2)
		var pos: Vector2
		var yaw := 0.0
		if absf(ca.y - cb.y) < 0.5:
			pos = Vector2(rb.position.x - 0.4 if cb.x > ca.x else rb.end.x + 0.4, cb.y)
			yaw = PI / 2.0
		else:
			pos = Vector2(cb.x, rb.end.y + 0.4 if cb.y < ca.y else rb.position.y - 0.4)
		if kind.begins_with("barred:"):
			k.flag_bars(pos.x, pos.y, yaw, flag, y)
		else:
			k.locked_door(pos.x, pos.y, yaw, flag, kind.begins_with("boss:"), y)


## Floating memories round a drift: bits of the places it remembers, on
## broken rocks, drifting in the dark below and around.
func _drift(k, f: int) -> void:
	var o: Vector2 = GROUPS[f][0]
	var y: float = GROUPS[f][1]
	var r := RandomNumberGenerator.new()
	r.seed = 1550 + f * 31
	for i in 7:
		var a := TAU * i / 7.0 + r.randf_range(-0.2, 0.2)
		var d := r.randf_range(52.0, 66.0)
		var c := o + Vector2(cos(a), sin(a)) * d
		var cy := y + r.randf_range(-22.0, 10.0)
		# The rock underneath, tapering to a point.
		var rock = k._tmp(false)
		rock.prism(Vector3(c.x, cy - 0.5, c.y), 5.0, Vector3(c.x, cy - 9.0, c.y), 0.0, 7, Color(0.24, 0.22, 0.3))
		rock.prism(Vector3(c.x, cy - 0.5, c.y), 5.0, Vector3(c.x, cy, c.y), 4.6, 7, Color(0.36, 0.34, 0.42))
		k.merge(rock, "rock")
		match (i + f) % 4:
			0:
				k.house(c.x, c.y, r.randf() * TAU, 5.0, 4.0, 3.5, Color.html(["e8d8b8", "c8d0e8", "e8c8b0"][i % 3]), Color.html("8a3a2a"), {"y": cy, "door": true})
			1:
				k.tower(c.x, c.y, 2.0, 9.0, "stone", Color(0.8, 0.8, 0.86), Color.html("4a5aa8"), 0.0, {"y": cy - 0.3, "crenel": true, "roof_h": 3.0, "seal": "solid"})
			2:
				for t in 3:
					var tx := c.x + r.randf_range(-2.5, 2.5)
					var tz := c.y + r.randf_range(-2.5, 2.5)
					if f >= 3:
						k.tree_dead(tx, tz, r.randf_range(0.8, 1.2))
					else:
						k.tree_round(tx, tz, r.randf_range(0.8, 1.2))
			3:
				k.pillar(c.x - 1.5, c.y, 6.0, 0.5, true, "stone", cy)
				k.pillar(c.x + 1.5, c.y, 4.0, 0.5, true, "stone", cy)


func _lights(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := _y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", y)


# --- 1F: the Shore of Stars ------------------------------------------------------------

func _g1(k) -> void:
	var lc := _c("landing")
	var ly := _y("landing")
	# The way back out, a doorway of dark like the one on the Ridge.
	k.area_exit(Vector3(lc.x, ly + 1.5, rooms.landing.r.end.y - 0.4), 0.0, Vector3(3.0, 3.0, 0.8), "black_water_ridge", "from_astral_rift")
	k.entrance("from_black_water_ridge", lc.x, rooms.landing.r.end.y - 3.0, 0.0)
	k.examine(Vector3(lc.x - 4.0, ly, lc.y), PI * 0.5, [{"text": "A stone of the Ridge, torn loose and floating here with the rest. Scratched on it, in a hand you know:\n*I HELD THIS ROAD.*\nThe dark has been collecting memories.", "instant": true}])
	k.story_trigger("rift_arrive", Rect2(lc.x - 6.0, lc.y - 4.0, 12.0, 8.0), ly - 1.0, "rift:arrived", "")
	_lights(k, "landing", 1.5)
	# The hub: the four star locks round the dais, and the dream stair.
	var hc := _c("hub")
	var hy := _y("hub")
	k.mark("cs_rift_hub", Vector3(hc.x, hy, hc.y))
	k.mark("hub_in", Vector3(hc.x, hy, hc.y + 8.0), 0.0)
	var cols := [Color(0.6, 0.85, 1.0), Color(0.85, 0.95, 1.0), Color(1.0, 0.65, 0.4), Color(0.7, 0.6, 1.0)]
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		k.star_lock(hc.x + cos(a) * 8.0, hc.y + sin(a) * 8.0, hy, {"flag": D + ":lock%d" % (i + 1), "display": true, "star_col": cols[i]})
	k.examine(Vector3(hc.x, hy, hc.y + 10.5), 0.0, [], "res://scripts/npc/finale_lines.gd", "hub_plaque")
	_dream_stair(k, hc, hy)
	# The gate rooms.
	var w := _c("w1")
	k.astral_gate(w.x - 4.0, w.y, hy, PI * 0.5, "f2_in", D + ":lock1", "A ring of cold stone. It will not wake until a star lock is lit... the one on the far side of this shore, perhaps.")
	k.mark("w1_gate", Vector3(w.x - 4.0, hy, w.y))
	var e := _c("e1")
	k.astral_gate(e.x + 4.0, e.y, hy, -PI * 0.5, "f3_in", D + ":lock2", "A ring of cold stone, dark as the others. Its star lock must burn somewhere among the Spires.")
	k.mark("e1_gate", Vector3(e.x + 4.0, hy, e.y))
	for p in [Vector2(e.x - 6, e.y - 6), Vector2(e.x + 6, e.y + 6)]:
		k.torch(p.x, p.y, false, "", hy)
	var n := _c("n1")
	k.astral_gate(n.x, n.y - 4.0, hy, 0.0, "f4_in", D + ":lock3", "A ring of cold stone. Beyond it, very faintly, you hear old bells... and something walking that should be lying still.")
	k.mark("n1_gate", Vector3(n.x, hy, n.y - 4.0))
	# The mirror shore: a pit, the Hookshot across, the Map on the far side.
	var mr: Rect2 = rooms.mirror.r
	var mp: Rect2 = pits()[0][1]
	k.block(Vector3(mr.get_center().x + 3.0, hy + 1.0, mr.end.y - 1.5), Vector3(0.5, 2.0, 0.5), 0.0, "stone", STONE)
	k.hook_target(Vector3(mr.get_center().x + 3.0, hy + 2.2, mr.end.y - 1.8), 0.0)
	k.block(Vector3(mr.get_center().x + 3.0, hy + 1.0, mr.position.y + 1.5), Vector3(0.5, 2.0, 0.5), 0.0, "stone", STONE)
	k.hook_target(Vector3(mr.get_center().x + 3.0, hy + 2.2, mr.position.y + 1.8), PI)
	k.chest(mr.get_center().x - 3.0, mr.end.y - 1.8, 0.0, "map", false, D + ":chest_map", "", hy)
	k.water_plane(mp, hy - 6.0, Color(0.3, 0.45, 0.8, 0.55))
	k.examine(Vector3(mr.end.x - 2.0, hy, mr.position.y + 2.0), -PI * 0.5, [{"text": "Far below the island, a lake shines in the dark: Mirror Lake, remembered. The far shore is too far to jump.", "instant": true}])
	# The drowned shrine: a crystal switch across the pit raises a bridge.
	var dr: Rect2 = rooms.drowned.r
	var dh: Rect2 = pits()[1][1]
	k.crystal_switch(dr.get_center().x, dr.position.y + 2.2, D + ":drowned_switch", hy)
	k.flag_bridge(Rect2(dr.get_center().x - 1.2, dh.position.y - 0.2, 2.4, dh.size.y + 0.4), hy, D + ":drowned_switch", 2.0)
	k.chest(dr.get_center().x + 3.0, dr.position.y + 2.0, 0.0, "small_key", false, D + ":chest_key1", "", hy)
	k.examine(Vector3(dr.get_center().x - 3.0, hy, dr.end.y - 2.0), PI, [{"text": "The Lake Shrine's old switch, floating out of reach across the pit. Something thrown, or shot, might reach it.", "instant": true}])
	# The lily pools: a fight for the Compass.
	var lr: Rect2 = rooms.lily.r
	k.shutter(lr.position.x + 0.6, lr.get_center().y, PI / 2.0, "lily", hy)
	k.water_plane(lr.grow(-3.0), hy + 0.06, Color(0.3, 0.5, 0.8, 0.5))
	k.chest(lr.get_center().x, lr.get_center().y, 0.0, "compass", false, D + ":chest_compass", D + ":lily_clear", hy)
	# Lock 1: tide knights; the first star lock.
	var l1 := _c("lock1")
	k.shutter(l1.x, rooms.lock1.r.end.y - 0.6, 0.0, "lock1", hy)
	k.star_lock(l1.x, l1.y - 4.0, hy, {"flag": D + ":lock1", "need_flag": D + ":lock1_clear", "pan_to": "w1_gate",
		"pan_text": "Far across the shore, the western ring of stone wakes with a cold white light.", "star_col": cols[0]})
	_lights(k, "lock1")
	_lights(k, "lily")
	_lights(k, "drowned", 1.6)


## A spiral of dream-light steps round the hub's dais, rising to the gate to
## the heart (it wakes with the fourth star lock).
func _dream_stair(k, hc: Vector2, hy: float) -> void:
	var top := 12.0
	var n := 24
	for i in n:
		var a := TAU * i / 12.0
		var rise := top * float(i + 1) / n
		var p := hc + Vector2(cos(a), sin(a)) * 4.2
		k.dream_light(Vector3(p.x, hy + rise - 0.2, p.y), Vector3(1.6, 0.4, 1.6), "path", DREAM)
	k.dream_light(Vector3(hc.x, hy + top - 0.2, hc.y), Vector3(4.4, 0.4, 4.4), "path", DREAM)
	k.astral_gate(hc.x, hc.y, hy + top, 0.0, "f5_in", D + ":lock4", "The highest ring of all. It waits for the last of the four stars.")
	k.mark("stair_gate", Vector3(hc.x, hy + top, hc.y))
	# The dais under it.
	k.block(Vector3(hc.x, hy + 0.25, hc.y), Vector3(3.0, 0.5, 3.0), 0.0, "stone", STONE.lightened(0.15))


# --- 2F-4F: arrivals, rests and the gates home ----------------------------------------

func _gate_rooms(k, f: int) -> void:
	var s := str(f)
	var a := _c("arrive" + s)
	var y := _y("arrive" + s)
	k.mark("f%d_in" % f, Vector3(a.x, y, a.y - 1.0), 0.0)
	k.astral_gate(a.x, a.y + 4.0, y, PI, "hub_in", "")
	k.examine(Vector3(a.x - 5.0, y, a.y), PI * 0.5, [], "res://scripts/npc/finale_lines.gd", "drift_%d" % f)
	var rc := _c("rest" + s)
	k.pot(rc.x - 3.0, rc.y - 3.0, "heart", false, y)
	k.pot(rc.x + 3.0, rc.y - 3.0, "magic_small", false, y)
	k.pot(rc.x - 3.0, rc.y + 3.0, "arrows_10", false, y)
	k.pot(rc.x + 3.0, rc.y + 3.0, "heart", false, y)
	var lk := _c("lock" + s)
	k.astral_gate(lk.x + 6.0, lk.y - 6.0, y, 0.0, "hub_in", D + ":lock" + s)
	var hall := _c("hall" + s)
	var hr: Rect2 = rooms["hall" + s].r
	k.shutter(hall.x, hr.end.y - 0.6, 0.0, "hall" + s, y)
	k.shutter(hr.position.x + 0.6, hall.y, PI / 2.0, "hall" + s, y)
	k.shutter(hr.end.x - 0.6, hall.y, PI / 2.0, "hall" + s, y)
	var lr: Rect2 = rooms["lock" + s].r
	k.shutter(lk.x, lr.end.y - 0.6, 0.0, "lock" + s, y)
	_lights(k, "hall" + s)
	_lights(k, "lock" + s)


func _lock(k, f: int, pan_to: String, text: String, col: Color) -> void:
	var s := str(f)
	var lk := _c("lock" + s)
	k.star_lock(lk.x, lk.y - 5.0, _y("lock" + s), {"flag": D + ":lock" + s, "need_flag": D + ":lock" + s + "_clear", "pan_to": pan_to, "pan_text": text, "star_col": col})


# --- 2F: the Spires of Memory -----------------------------------------------------------

func _g2(k) -> void:
	var y := _y("hall2")
	# The gale walk: a gale across a narrow way over the pit, the key beyond.
	var wr: Rect2 = rooms.west2.r
	var wc := wr.get_center()
	var gale: Rect2 = pits()[3][1]
	k.wind_zone(Vector3(wc.x, y + 1.5, wr.position.y + 2.2), Vector3(gale.size.x + 2.0, 3.0, 3.6), Vector3(0, 0, 1), 5.0)
	k.chest(wr.position.x + 2.0, wc.y, PI * 0.5, "small_key", false, D + ":chest_key2", "", y)
	k.examine(Vector3(wr.end.x - 2.0, y, wr.position.y + 2.0), -PI * 0.5, [{"text": "Skyreach's old wind, still blowing round a memory of its spire. It wants to push you off the edge.\nHeavy boots might hold you down.", "instant": true}])
	# The hook room: across the pit to the switch that lifts the bars.
	var er: Rect2 = rooms.east2.r
	var ec := er.get_center()
	var band: Rect2 = pits()[2][1]
	k.block(Vector3(band.end.x + 0.6, y + 1.0, ec.y + 3.0), Vector3(0.5, 2.0, 0.5), 0.0, "stone", STONE)
	k.hook_target(Vector3(band.end.x + 0.6, y + 2.2, ec.y + 3.0), -PI * 0.5)
	k.block(Vector3(band.position.x - 0.6, y + 1.0, ec.y - 3.0), Vector3(0.5, 2.0, 0.5), 0.0, "stone", STONE)
	k.hook_target(Vector3(band.position.x - 0.6, y + 2.2, ec.y - 3.0), PI * 0.5)
	k.crystal_switch(er.end.x - 2.0, er.position.y + 2.0, D + ":bars2", y)
	k.examine(Vector3(band.position.x - 1.4, y, ec.y + 2.0), -PI * 0.5, [{"text": "A drop into nothing between here and the far side. A post stands over there, as if for something to bite into.", "instant": true}])
	# The island beyond the bars, and the dream island.
	var ne := _c("ne2")
	k.chest(ne.x, ne.y, 0.0, "rupee_gold", true, D + ":chest_ne2", "", y)
	var nw := _c("nw2")
	k.chest(nw.x, nw.y, 0.0, "magic_large", false, D + ":chest_nw2", "", y)
	_lock(k, 2, "e1_gate", "Back on the Shore of Stars, the eastern ring kindles: the way to the Burning Halls.", Color(0.85, 0.95, 1.0))


# --- 3F: the Burning Halls ----------------------------------------------------------------

func _g3(k) -> void:
	var y := _y("hall3")
	# The fire walk: jets breathe across the room; a Sapphire block stops one.
	var wr: Rect2 = rooms.west3.r
	for i in 3:
		var z := wr.position.y + 4.0 + i * 6.0
		k._dyn("res://scripts/dungeon/fire_jet.gd", "FireJet", Vector3(wr.end.x - 0.4, y + 0.9, z), PI * 0.5, {"length": 18.0, "period": 0.0 if i == 1 else 2.6, "phase": i * 0.8}, Node3D.new())
	k.chest(wr.position.x + 2.0, wr.position.y + 2.0, PI * 0.5, "small_key", false, D + ":chest_key3", "", y)
	k.examine(Vector3(wr.end.x - 2.0, y, wr.end.y - 2.0), -PI * 0.5, [{"text": "The Citadel's fire, burning in a memory of its halls. The middle jet never sleeps.\nThe Order's sapphire takes no fire.", "instant": true}])
	# The braziers: three star braziers want starlight; lit, the bars rise.
	var ec := _c("east3")
	var flags: Array = []
	for i in 3:
		var a := TAU * i / 3.0 - PI * 0.5
		var f := D + ":brazier3_%d" % i
		k.star_brazier(ec.x + cos(a) * 6.0, ec.y + sin(a) * 6.0, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":bars3")
	k.examine(Vector3(ec.x, y, ec.y + 8.0), PI, [{"text": "Three braziers of pale stone, cold. *ONLY THE LIGHT THE FIRE CANNOT RULE*, says the rim of each.", "instant": true}])
	var ne := _c("ne3")
	k.chest(ne.x, ne.y, 0.0, "rupee_gold", true, D + ":chest_ne3", "", y)
	var nw := _c("nw3")
	k.chest(nw.x, nw.y, 0.0, "rupee_purple", false, D + ":chest_nw3", "", y)
	for p in [Vector2(-4, -4), Vector2(4, 4)]:
		var hc := _c("hall3")
		k.fire(hc.x + p.x, hc.y + p.y, 0.8, y, true)
	_lock(k, 3, "n1_gate", "On the Shore of Stars, the northern ring wakes. Old bells ring somewhere behind it.", Color(1.0, 0.65, 0.4))


# --- 4F: the Barrow of Night ---------------------------------------------------------------

func _g4(k) -> void:
	var y := _y("hall4")
	# The great stone: dragged aside with the Gauntlets, the key behind it.
	var wr: Rect2 = rooms.west4.r
	var wc := wr.get_center()
	k.block(Vector3(wr.position.x + 2.0, y + 1.5, wc.y - 2.6), Vector3(4.0, 3.0, 0.6), 0.0, "stone", STONE.darkened(0.3))
	k.block(Vector3(wr.position.x + 2.0, y + 1.5, wc.y + 2.6), Vector3(4.0, 3.0, 0.6), 0.0, "stone", STONE.darkened(0.3))
	k.great_stone(wr.position.x + 4.6, wc.y, PI * 0.5, D + ":stone4", y)
	k.chest(wr.position.x + 1.4, wc.y, PI * 0.5, "small_key", false, D + ":chest_key4", "", y)
	# The bells: three for the Iron Flail; rung, the bars lift.
	var ec := _c("east4")
	var bells: Array = []
	for i in 3:
		var f := D + ":bell4_%d" % i
		k.flail_target("bell", ec.x - 6.0 + i * 6.0, ec.y - 7.0 + (i % 2) * 3.0, f, y, {"tall": 4.4})
		bells.append(f)
	k.flag_all(bells, D + ":bars4")
	k.examine(Vector3(ec.x + 7.0, y, ec.y + 7.0), PI * 0.75, [{"text": "Three bells from Ridge Keep, hung on nothing over the dark. *RING ALL THREE*, says someone who isn't there.", "instant": true}])
	# The boss key, beyond the bars; the dream island.
	var ne := _c("ne4")
	k.chest(ne.x, ne.y, 0.0, "boss_key", true, D + ":chest_boss_key", "", y)
	var nw := _c("nw4")
	k.chest(nw.x, nw.y, 0.0, "rupee_gold", false, D + ":chest_nw4", "", y)
	var hc := _c("hall4")
	for p in [Vector2(-6, -6), Vector2(6, -6)]:
		k.statue(hc.x + p.x, hc.y + p.y, 0.0, 1.0, "stone", y)
	_lock(k, 4, "stair_gate", "Over the great hall of the Shore of Stars, the highest ring blazes white. The dream stair leads up to it.", Color(0.7, 0.6, 1.0))


# --- 5F: the heart ---------------------------------------------------------------------------

func _g5(k) -> void:
	var y := _y("star")
	var a := _c("in5")
	k.mark("f5_in", Vector3(a.x, y, a.y - 1.0), 0.0)
	k.astral_gate(a.x, a.y + 4.0, y, PI, "hub_in", "")
	# The starfield: a maze of dream-light tiles over the void, and veils of
	# dark that stand only while the hero is awake.
	var sc := _c("star")
	var path := [Vector2(0, 11), Vector2(0, 8), Vector2(0, 5), Vector2(-3, 5), Vector2(-6, 5), Vector2(-6, 2), Vector2(-6, -1),
		Vector2(-3, -1), Vector2(0, -1), Vector2(3, -1), Vector2(6, -1), Vector2(6, -4), Vector2(6, -7), Vector2(3, -7),
		Vector2(0, -7), Vector2(0, -10), Vector2(-9, 0), Vector2(-9, 2), Vector2(9, 0), Vector2(9, -1)]
	for p: Vector2 in path:
		k.dream_light(Vector3(sc.x + p.x, y - 0.25, sc.y + p.y), Vector3(3.0, 0.5, 3.0), "path", DREAM)
	var sr2: Rect2 = rooms.star.r
	for pad: Rect2 in [Rect2(sc.x - 1.6, sr2.end.y - 3.0, 3.2, 2.2), Rect2(sc.x - 1.6, sr2.position.y + 0.8, 3.2, 2.2),
			Rect2(sr2.position.x + 0.8, sc.y - 1.6, 2.2, 3.2), Rect2(sr2.end.x - 3.0, sc.y - 1.6, 2.2, 3.2)]:
		k.floor_slab(pad, y, [], "stone", STONE)
	for p: Vector2 in [Vector2(3, 5), Vector2(-3, -7), Vector2(3, 2)]:
		k.dream_light(Vector3(sc.x + p.x, y + 1.5, sc.y + p.y), Vector3(3.0, 3.0, 3.0), "veil")
	k.examine(Vector3(sc.x + 4.0, y, sc.y + 12.0), PI, [{"text": "Where the floor should be there is only dark, and in it, very faint, the outline of a path of light... as if it were only waiting for someone to dream it.", "instant": true}])
	# The hall of remembrance and the fountain.
	var rc := _c("rem")
	k.examine(Vector3(rc.x, y, rc.y - 5.0), 0.0, [], "res://scripts/npc/finale_lines.gd", "remembrance")
	for i in 4:
		k.statue(rc.x - 4.5 + i * 3.0, rc.y - 6.0, 0.0, 0.9, "stone", y)
	var fc := _c("fount")
	k.fountain(fc.x, fc.y, 2.5)
	k.pot(fc.x - 5.0, fc.y + 5.0, "heart", false, y)
	k.pot(fc.x + 5.0, fc.y + 5.0, "magic_large", false, y)
	k.pot(fc.x - 5.0, fc.y - 5.0, "arrows_10", false, y)
	k.pot(fc.x + 5.0, fc.y - 5.0, "heart", false, y)
	# Avalon's garden of light.
	var av := _c("avalon")
	k.mark("cs_avalon", Vector3(av.x, y, av.y - 3.0))
	k.mark("cs_avalon_hero", Vector3(av.x, y, av.y + 3.0))
	k.story_trigger("avalon_scene", Rect2(av.x - 6.0, av.y + 1.0, 12.0, 8.0), y - 1.0, "rift:blessed", "")
	var r := RandomNumberGenerator.new()
	r.seed = 1777
	var shine = k._tmp(false)
	for i in 30:
		var p := av + Vector2(r.randf_range(-9.0, 9.0), r.randf_range(-9.0, 9.0))
		if p.distance_to(av) < 4.0:
			continue
		var base := Vector3(p.x, y, p.y)
		shine.prism(base, 0.12, base + Vector3(r.randf_range(-0.1, 0.1), r.randf_range(0.5, 1.4), r.randf_range(-0.1, 0.1)), 0.0, 5, Color.html(["bfe2ff", "ffffff", "d8c8ff"][i % 3]))
	k.merge(shine, "glow")
	# The antechamber, and the prison.
	var an := _c("ante")
	k.pot(an.x - 4.0, an.y, "heart", false, y)
	k.pot(an.x + 4.0, an.y, "magic_small", false, y)
	var pr: Rect2 = rooms.prison.r
	var pc := pr.get_center()
	k.mark("cs_prison", Vector3(pc.x, y, pc.y - 4.0))
	k.story_trigger("rift_heart", Rect2(pc.x - 5.0, pr.end.y - 6.0, 10.0, 4.0), y - 1.0, "rift:heart_seen", "")
	k.shutter(pc.x, pr.end.y - 0.6, 0.0, "prison", y)
	for i in 9:
		var ang := TAU * i / 9.0
		var d := 3.0 + (i % 3) * 1.2
		k.display_mesh("res://assets/models/prison_shard_mesh.tres", Transform3D(Basis(Vector3.UP, ang) * Basis(Vector3.RIGHT, 0.25 + (i % 2) * 0.3), Vector3(pc.x + cos(ang) * d, y, pc.y - 6.0 + sin(ang) * d)))
	k.mark("cs_final", Vector3(pc.x, y, pc.y))


func populate(k) -> void:
	var y1 := _y("hub")
	var y2 := _y("hall2")
	var y3 := _y("hall3")
	var y4 := _y("hall4")
	var y5 := _y("star")
	var c := func(rid: String) -> Vector2: return _c(rid)
	# 1F
	var lily: Vector2 = c.call("lily")
	k.enemy("octorok", lily.x - 4.0, lily.y, 0.0, {"room": "lily"}, y1)
	k.enemy("tektite_blue", lily.x + 4.0, lily.y - 3.0, 0.0, {"room": "lily"}, y1)
	k.enemy("tektite_blue", lily.x + 2.0, lily.y + 4.0, 0.0, {"room": "lily"}, y1)
	var e1: Vector2 = c.call("e1")
	k.enemy("shade", e1.x, e1.y - 3.0, 0.0, {}, y1)
	k.enemy("shade", e1.x - 3.0, e1.y + 3.0, 0.0, {}, y1)
	var l1: Vector2 = c.call("lock1")
	k.enemy("tide_knight", l1.x - 3.0, l1.y + 2.0, PI, {"room": "lock1"}, y1)
	k.enemy("tide_knight", l1.x + 3.0, l1.y + 2.0, PI, {"room": "lock1"}, y1)
	k.enemy("keese", c.call("w1").x, c.call("w1").y, 0.0, {}, y1 + 3.0)
	# 2F
	var h2: Vector2 = c.call("hall2")
	k.enemy("wind_wisp", h2.x - 4.0, h2.y - 3.0, 0.0, {"room": "hall2"}, y2 + 1.0)
	k.enemy("wind_wisp", h2.x + 4.0, h2.y - 3.0, 0.0, {"room": "hall2"}, y2 + 1.0)
	k.enemy("stalfos", h2.x, h2.y + 2.0, PI, {"room": "hall2"}, y2)
	k.enemy("keese", c.call("east2").x, c.call("east2").y, 0.0, {}, y2 + 3.0)
	var l2: Vector2 = c.call("lock2")
	k.enemy("corvax", l2.x, l2.y, PI, {"room": "lock2"}, y2 + 2.0)
	# 3F
	var h3: Vector2 = c.call("hall3")
	k.enemy("cinderling", h3.x - 4.0, h3.y - 2.0, 0.0, {"room": "hall3"}, y3)
	k.enemy("cinderling", h3.x + 4.0, h3.y - 2.0, 0.0, {"room": "hall3"}, y3)
	k.enemy("charred_stalfos", h3.x, h3.y + 3.0, PI, {"room": "hall3"}, y3)
	k.enemy("fire_keese", h3.x, h3.y - 5.0, 0.0, {"room": "hall3"}, y3 + 3.0)
	k.enemy("fire_keese", c.call("east3").x, c.call("east3").y, 0.0, {}, y3 + 3.0)
	var l3: Vector2 = c.call("lock3")
	k.enemy("ember_knight", l3.x, l3.y, PI, {"room": "lock3"}, y3)
	k.enemy("cinderling", l3.x - 5.0, l3.y + 3.0, PI, {"room": "lock3"}, y3)
	# 4F
	var h4: Vector2 = c.call("hall4")
	k.enemy("stalfos", h4.x - 4.0, h4.y, 0.0, {"room": "hall4"}, y4)
	k.enemy("barrow_knight", h4.x + 4.0, h4.y, 0.0, {"room": "hall4"}, y4)
	k.enemy("barrow_knight", h4.x, h4.y - 4.0, 0.0, {"room": "hall4"}, y4)
	k.enemy("mummy", c.call("west4").x + 3.0, c.call("west4").y + 5.0, 0.0, {}, y4)
	k.enemy("shade", c.call("east4").x, c.call("east4").y + 4.0, 0.0, {}, y4)
	var l4: Vector2 = c.call("lock4")
	k.enemy("barrow_champion", l4.x, l4.y, PI, {"room": "lock4"}, y4)
	# 5F
	k.enemy("shadow_wolf", c.call("rem").x, c.call("rem").y + 3.0, 0.0, {}, y5)
	var pr: Vector2 = (rooms.prison.r as Rect2).get_center()
	k.enemy("firebuns_final", pr.x, pr.y - 6.0, 0.0, {"room": "prison"}, y5)
	k.enemy("shadow_hand", pr.x - 6.0, pr.y - 8.0, 0.0, {"room": "prison", "side": -1.0}, y5)
	k.enemy("shadow_hand", pr.x + 6.0, pr.y - 8.0, 0.0, {"room": "prison", "side": 1.0}, y5)
