extends "res://tools/world/tower_region.gd"
## The Barrow of Kings (Chapter V): the royal crypt under the old chapel of
## Castle Town, where seven kings of Haven sleep with their sworn knights.
## Mara has woken them. Gray slate and black marble, gold inlaid crowns,
## bones in the ossuaries, cold blue candle-flames. The dungeon of the Knight's
## Techniques: BARROW KNIGHTS guard with their shields up (the Shield Bash
## breaks their guard), the kings sealed the way down with cracked floor
## seals (only a Down Thrust breaks them), and the rune bells ring together
## only to a Great Spin. Its treasure is the QUESTLORD'S GAUNTLETS (the great
## stones); its master THE HOLLOW KING. Seven tombs with seven epitaphs
## (BarrowLines); read them all and the kings' vault opens.
##
## Storeys, top down (north is -Z); each way down is a floor seal broken from
## a ledge, with a ladder back up:
##   1F (y 0)    stair S     down from the chapel; the inscription
##               hall C      the hall of effigies: two Barrow Knights (shutters);
##                           locked north (Key 1)
##               tombs_w W   tombs I and II; the Map
##               bells E     four rune bells (Great Spin) -> Key 1
##               ossuary N   bones; a ledge over the first floor seal
##   B1 (y -8)   landing N   in by the seal; a ladder back up
##               crypt C     the hall of crowns: tombs III and IV, the kings'
##                           vault (all seven epitaphs); locked south (Key 2)
##               armory W   the Barrow Champion (mini-boss) -> the Gauntlets
##               stones E    two great stones -> the Compass, Key 2
##               chapel S    tomb V; a ledge over the second seal
##   B2 (y -16)  well S      in by the seal; a ladder back up
##               gallery C   the knights' gallery (shutters); locked north (Key 3)
##               harrow W    Harrow's empty tomb (VI); six bells -> Key 3
##               corvin E    tomb VII; a great stone -> the Boss Key
##               ante N      a ledge over the third seal
##   B3 (y -24)  nave N      in by the seal; the boss door north
##               boss        the throne of the dead: THE HOLLOW KING
##               heart       the heart container and the blue warp home

const D := "barrow_of_kings"
const SLATE := Color(0.62, 0.64, 0.7)
const GOLD := Color(0.86, 0.72, 0.38)
## Ladders back up: [storey below, pier x, pier z, out].
const LADDERS := [
	[2, -8.0, -30.0, Vector2(1, 0)],
	[1, -5.5, 21.0, Vector2(1, 0)],
	[0, -8.0, -30.0, Vector2(1, 0)],
]
## The floor seals: [storey of the seal, center].
const SEALS := [[3, Vector2(0.0, -40.0)], [2, Vector2(2.5, 24.5)], [1, Vector2(0.0, -40.0)]]


func setup() -> void:
	id = "barrow_of_kings"
	interior = true
	seed_value = 1301
	x_min = -46.0
	x_max = 46.0
	z_min = -120.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B3", -24.0], ["B2", -16.0], ["B1", -8.0], ["1F", 0.0]]
	entry_floor = 3
	wall_col = SLATE
	ceil_col = Color(0.26, 0.27, 0.32)
	slab_col = Color(0.6, 0.62, 0.68)
	var bone := Color(0.78, 0.74, 0.64)
	rooms = {
		# 1F
		"stair": {"f": 3, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"hall": {"f": 3, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"tombs_w": {"f": 3, "r": Rect2(-38, -9, 18, 18), "h": 6.0, "doors": [{"side": "e", "at": 0.0}]},
		"bells": {"f": 3, "r": Rect2(20, -9, 18, 18), "h": 6.5, "doors": [{"side": "w", "at": 0.0}], "col": SLATE.darkened(0.1)},
		"ossuary": {"f": 3, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": bone},
		# B1
		"landing": {"f": 2, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": bone.darkened(0.15)},
		"crypt": {"f": 2, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "s", "at": 0.0}], "col": Color(0.42, 0.4, 0.46)},
		"armoury": {"f": 2, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"stones": {"f": 2, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"chapel": {"f": 2, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}], "col": SLATE.darkened(0.15)},
		# B2
		"well": {"f": 1, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}], "col": SLATE.darkened(0.25)},
		"gallery": {"f": 1, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"harrow": {"f": 1, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}], "col": Color(0.36, 0.34, 0.4)},
		"corvin": {"f": 1, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"ante": {"f": 1, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": SLATE.darkened(0.2)},
		# B3
		"nave": {"f": 0, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "n", "at": 0.0}], "col": Color(0.3, 0.3, 0.36)},
		"boss": {"f": 0, "r": Rect2(-16, -86, 32, 32), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "col": Color(0.28, 0.27, 0.32)},
		"heart": {"f": 0, "r": Rect2(-10, -116, 20, 22), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.8, 0.8, 0.86)},
	}
	corridors = [
		{"f": 3, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 3, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 3, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 3, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 2, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 2, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 1, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 1, "r": Rect2(-20, -2, 7, 4), "x": true},
		{"f": 1, "r": Rect2(13, -2, 7, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 0, "r": Rect2(-2, -54, 4, 8), "x": false},
		{"f": 0, "r": Rect2(-2, -94, 4, 8), "x": false},
	]
	holes = []
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	for s: Array in SEALS:
		var c: Vector2 = s[1]
		holes.append({"f": int(s[0]), "r": Rect2(c - Vector2(1.3, 1.3), Vector2(2.6, 2.6))})
	mood = {
		"sky_top": Color.html("0c0e14"), "sky_mid": Color.html("0c0e14"), "sky_horizon": Color.html("0c0e14"),
		"cloud": Color.html("0c0e14"), "cloud_amount": 0.0,
		"fog": Color.html("10141c"), "fog_begin": 12.0, "fog_end": 54.0,
		"ambient": Color.html("586274"), "sun": Color.html("c8d8ff"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.4, "fill": Color.html("4a5470"), "fill_energy": 0.4,
		"horizon": Color.html("0c0e14"), "hill_height": 0.0,
	}


func _inside(x: float, z: float, f: int) -> bool:
	for rid: String in rooms:
		var rm: Dictionary = rooms[rid]
		if rm.f == f and (rm.r as Rect2).grow(1.0).has_point(Vector2(x, z)):
			return true
	for c: Dictionary in corridors:
		if c.f == f and (c.r as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## Slate flagstones, gold crowns inlaid in the hall of crowns, bone-strewn
## earth in the ossuaries, a great crowned ring on the throne room floor.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["08090c", "0a0b0e"])
	var p := Vector2(x, z)
	for rid in ["ossuary", "landing"]:
		if rooms[rid].f == f and (rooms[rid].r as Rect2).has_point(p):
			return Color.html(["5a5246", "62584a", "4e463c", "c8c0a8"][r.randi() % 4])
	if f == 2 and (rooms.crypt.r as Rect2).has_point(p):
		var q := p - room_center("crypt")
		if absf(q.length() - 6.0) < 0.35:
			return Color.html("c8a84a")
	if f == 0 and (rooms.boss.r as Rect2).has_point(p):
		var q := p - room_center("boss")
		if absf(q.length() - 9.0) < 0.4 or absf(q.length() - 11.0) < 0.2:
			return Color.html("8a7440")
	var seam := fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08
	if seam:
		return Color.html("2a2c34")
	return Color.html(["5c5e68", "565862", "626470"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.08) + 0.04 * (3 - f))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.6, 2.4, "castle_town_restored", "from_barrow_of_kings", Color(0.7, 0.68, 0.72))
	k.entrance("from_castle_town_restored", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	_f1(k)
	_b1(k)
	_b2(k)
	_b3(k)


## Cold blue candle-flames in the corners (lit braziers, no puzzle).
func _candles(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", y)


## A king's tomb: a sarcophagus with an effigy, its epitaph (BarrowLines).
func _tomb(k, n: int, x: float, z: float, yaw: float, y: float, empty := false) -> void:
	var basis := Basis(Vector3.UP, yaw)
	k.block(Vector3(x, y + 0.55, z), Vector3(1.6, 1.1, 3.0) if absf(sin(yaw)) < 0.5 else Vector3(3.0, 1.1, 1.6), 0.0, "stone", SLATE.darkened(0.1))
	var m = k._tmp(false)
	if not empty:
		# The effigy: a king lying with a stone sword, a gold crown.
		m.box(Vector3(x, y + 1.25, z) + basis * Vector3(0, 0, 0.1), (Vector3(0.7, 0.3, 2.2) if absf(sin(yaw)) < 0.5 else Vector3(2.2, 0.3, 0.7)), SLATE.lightened(0.2))
		m.box(Vector3(x, y + 1.45, z) + basis * Vector3(0, 0, -0.95), Vector3(0.4, 0.14, 0.4), GOLD)
	else:
		# Harrow's: the lid smashed, the effigy gone.
		m.box(Vector3(x, y + 1.15, z) + basis * Vector3(0.5, 0, 0.6), Vector3(0.9, 0.12, 1.2), SLATE.darkened(0.3))
	k.merge(m, "char")
	var front := basis * Vector3(0, 0, 1)
	var side := Vector3(-front.z, 0, front.x)
	k.examine(Vector3(x, y, z) + side * 1.2, k.yaw_of(Vector2(side.x, side.z)), [], "res://scripts/npc/barrow_lines.gd", "epitaph_%d" % n, 1.4)


## A floor seal over the hole at SEALS[i], and the ledge it is broken from.
func _seal(k, i: int, ledge_center: Vector2, ledge_size: Vector2, stairs_at: Vector2, flag_name: String) -> void:
	var f: int = SEALS[i][0]
	var c: Vector2 = SEALS[i][1]
	var y := fy(f)
	k.technique_target("seal", c.x, c.y, D + ":" + flag_name, y, {"size": 2.6})
	var hh := 3.0
	k.block(Vector3(ledge_center.x, y + hh * 0.5, ledge_center.y), Vector3(ledge_size.x, hh, ledge_size.y), 0.0, "stone", SLATE.darkened(0.05))
	k.stairs(stairs_at.x, stairs_at.y, 0.0, minf(ledge_size.x - 0.4, 3.0), 2.6, hh, "stone", y)
	k.examine(Vector3(c.x - 2.2, y, c.y + 2.2), PI * 0.75, [], "res://scripts/npc/barrow_lines.gd", "seals")


# --- 1F ---------------------------------------------------------------------------

func _f1(k) -> void:
	k.examine(Vector3(-3.0, 0.0, 18.8), PI, [], "res://scripts/npc/barrow_lines.gd", "stair")
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.6, z, 6.0, 0.45, false, "stone", 0.0)
	k.pot(4.2, 28.5, "heart")
	# The hall of effigies: the kings' knights in stone, shields up; two of
	# them are not stone. Shutters until they fall.
	for z in [-8.0, -4.0, 4.0, 8.0]:
		for sx in [-1.0, 1.0]:
			k.statue(sx * 11.4, z, PI * 0.5 * -sx, 1.0, "stone", 0.0)
	k.examine(Vector3(-10.4, 0.0, 6.0), -PI * 0.5, [], "res://scripts/npc/barrow_lines.gd", "knights")
	k.shutter(0.0, 11.4, 0.0, "hall", 0.0)
	k.shutter(-12.4, 0.0, PI / 2.0, "hall", 0.0)
	k.shutter(12.4, 0.0, PI / 2.0, "hall", 0.0)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key1", false, 0.0)
	_candles(k, "hall")
	# Tombs I and II; the Map.
	_tomb(k, 1, -33.0, -3.0, 0.0, 0.0)
	_tomb(k, 2, -25.0, -3.0, 0.0, 0.0)
	k.chest(-29.0, 6.0, PI, "map", false, D + ":chest_map", "", 0.0)
	_candles(k, "tombs_w")
	# The rune bells: one Great Spin from the middle rings all four -> Key 1.
	var bc := room_center("bells")
	k.technique_target("ring", bc.x, bc.y, D + ":bells_1", 0.0, {"size": 2.0, "count": 4, "post_mesh": "rune_bell"})
	k.examine(Vector3(bc.x - 5.0, 0.0, bc.y + 6.0), -PI * 0.25, [], "res://scripts/npc/barrow_lines.gd", "bells")
	k.chest(bc.x + 6.0, bc.y, -PI / 2.0, "small_key", false, D + ":chest_key1", D + ":bells_1", 0.0)
	_candles(k, "bells")
	# The ossuary: bones heaped to the vault, and the first seal.
	var m = k._tmp()
	var rng: RandomNumberGenerator = k.rng
	for i in 26:
		var p := Vector2(rng.randf_range(-10.0, -2.5), rng.randf_range(-45.0, -27.0))
		if p.distance_to(Vector2(-6.65, -30.0)) < 2.4:
			continue
		m.icosa(Vector3(p.x, 0.15, p.y), Vector3(0.5, 0.25, 0.5) * rng.randf_range(0.6, 1.3), 0.3, Color.html("d8d0b8"))
	k.merge(m, "stone")
	_seal(k, 0, Vector2(3.8, -40.0), Vector2(5.0, 8.0), Vector2(3.8, -33.4), "seal_1")
	_candles(k, "ossuary")


# --- B1 ---------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(2)
	_candles(k, "landing")
	# The hall of crowns: tombs III and IV, the crown niches, and the vault.
	_tomb(k, 3, -6.0, 6.0, 0.0, y)
	_tomb(k, 4, 6.0, 6.0, 0.0, y)
	for p in [Vector2(-10.0, -6.0), Vector2(-10.0, 2.0), Vector2(10.0, 2.0), Vector2(-4.0, -9.0)]:
		k.pillar(p.x, p.y, 6.5, 0.45, false, "stone", y)
	# The vault: a chamber of black marble in the north-east corner, its front
	# wall gone once all seven kings are read.
	var vx := 8.5
	var vz := -8.6
	k.block(Vector3(vx - 2.1, y + 1.6, vz), Vector3(0.6, 3.2, 3.4), 0.0, "stone", SLATE.darkened(0.4))
	k.block(Vector3(vx + 2.1, y + 1.6, vz), Vector3(0.6, 3.2, 3.4), 0.0, "stone", SLATE.darkened(0.4))
	k.block(Vector3(vx, y + 3.35, vz), Vector3(4.8, 0.3, 3.4), 0.0, "stone", SLATE.darkened(0.4))
	var front = k._tmp()
	front.box(Vector3(vx, y + 1.6, vz + 1.85), Vector3(3.6, 3.2, 0.3), SLATE.darkened(0.3))
	for i in 7:
		front.box(Vector3(vx - 1.5 + i * 0.5, y + 2.7, vz + 2.02), Vector3(0.26, 0.2, 0.04), GOLD)
	k.flag_barrier(Vector3(vx, y + 1.6, vz + 1.85), Vector3(3.6, 3.2, 0.3), 0.0, BarrowLines.VAULT, front, "stone")
	k.chest(vx, vz - 0.4, 0.0, "rupee_gold", false, "barrow:kings_vault", "", y)
	k.examine(Vector3(vx - 3.2, y, vz + 3.0), PI, [], "res://scripts/npc/barrow_lines.gd", "crowns")
	k.locked_door(0.0, 12.4, PI, D + ":door_key2", false, y)
	_candles(k, "crypt")
	# The armory: the Barrow Champion; beaten, the Questlord's Gauntlets.
	k.shutter(-20.6, 0.0, PI / 2.0, "armoury", y)
	var ac := room_center("armoury")
	k.chest(ac.x - 6.0, ac.y, PI / 2.0, "questlord_gauntlets", true, D + ":chest_gauntlets", D + ":armoury_clear", y)
	for z in [-7.0, 7.0]:
		k.statue(ac.x - 8.4, z, PI * 0.5, 1.0, "stone", y)
	_candles(k, "armoury")
	# The stones: a wall across the room, two gaps closed by great stones.
	var wx := 30.5
	for seg in [[-10.0, -6.4], [-3.6, 3.6], [6.4, 10.0]]:
		var za: float = seg[0]
		var zb: float = seg[1]
		k.block(Vector3(wx, y + 3.0, (za + zb) * 0.5), Vector3(1.0, 6.0, zb - za), 0.0, "stone", SLATE)
	k.great_stone(wx - 1.6, -5.0, -PI * 0.5, D + ":stone_n", y, 1.0)
	k.great_stone(wx - 1.6, 5.0, -PI * 0.5, D + ":stone_s", y, -1.0)
	k.examine(Vector3(23.0, y, -8.0), -PI * 0.5, [], "res://scripts/npc/barrow_lines.gd", "stones")
	k.chest(36.0, -5.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", y)
	k.chest(36.0, 5.0, -PI / 2.0, "small_key", false, D + ":chest_key2", "", y)
	# The chapel below: tomb V, and a ledge over the second seal.
	_tomb(k, 5, -3.6, 26.0, 0.0, y)
	_seal(k, 1, Vector2(5.4, 24.5), Vector2(3.0, 6.0), Vector2(5.4, 29.6), "seal_2")


# --- B2 ---------------------------------------------------------------------------

func _b2(k) -> void:
	var y := fy(1)
	k.pot(4.5, 28.5, "bombs_5", false, y)
	k.pot(-5.5, 28.5, "arrows_10", false, y)
	# The knights' gallery: shutters until its guard falls.
	for z in [-8.0, 0.0, 8.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 10.0, z, 6.5, 0.5, false, "stone", y)
	k.shutter(0.0, 11.4, 0.0, "gallery", y)
	k.shutter(-12.4, 0.0, PI / 2.0, "gallery", y)
	k.shutter(12.4, 0.0, PI / 2.0, "gallery", y)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key3", false, y)
	_candles(k, "gallery")
	# Harrow's tomb, empty; six bells round it -> Key 3.
	var hc := room_center("harrow")
	_tomb(k, 6, hc.x - 6.5, hc.y, PI * 0.5, y, true)
	k.technique_target("ring", hc.x + 1.5, hc.y, D + ":bells_2", y, {"size": 2.4, "count": 6, "post_mesh": "rune_bell"})
	k.chest(hc.x + 7.0, hc.y + 6.0, -PI / 2.0, "small_key", false, D + ":chest_key3", D + ":bells_2", y)
	_candles(k, "harrow")
	# Corvin's tomb, and the Boss Key behind a great stone.
	var cc := room_center("corvin")
	_tomb(k, 7, cc.x - 4.0, cc.y - 5.0, 0.0, y)
	var wx := 34.5
	for seg in [[-10.0, -1.4], [1.4, 10.0]]:
		var za: float = seg[0]
		var zb: float = seg[1]
		k.block(Vector3(wx, y + 3.0, (za + zb) * 0.5), Vector3(1.0, 6.0, zb - za), 0.0, "stone", SLATE)
	k.great_stone(wx - 1.6, 0.0, -PI * 0.5, D + ":stone_boss", y, 1.0)
	k.chest(38.0, 0.0, -PI / 2.0, "boss_key", true, D + ":chest_boss_key", "", y)
	_candles(k, "corvin")
	# The ante-chamber: the third seal.
	_seal(k, 2, Vector2(3.8, -40.0), Vector2(5.0, 8.0), Vector2(3.8, -33.4), "seal_3")
	_candles(k, "ante")


# --- B3 ---------------------------------------------------------------------------

func _b3(k) -> void:
	var y := fy(0)
	_candles(k, "nave")
	k.pot(8.0, -28.0, "heart", false, y)
	k.pot(8.0, -29.2, "magic_small", false, y)
	k.locked_door(0.0, -46.4, 0.0, D + ":boss_door", true, y)
	# The throne of the dead.
	var rb: Rect2 = rooms.boss.r
	var bc := room_center("boss")
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	for i in 8:
		var a := TAU * i / 8.0
		k.pillar(bc.x + cos(a) * 13.0, bc.y + sin(a) * 13.0, 6.5, 0.6, i % 3 == 0, "stone", y)
	k.block(Vector3(bc.x, y + 0.6, rb.position.y + 2.5), Vector3(6.0, 1.2, 3.0), 0.0, "stone", SLATE.darkened(0.3))
	var th = k._tmp()
	th.box(Vector3(bc.x, y + 1.9, rb.position.y + 1.6), Vector3(2.0, 1.4, 0.4), SLATE.darkened(0.4))
	th.box(Vector3(bc.x, y + 2.9, rb.position.y + 1.4), Vector3(1.6, 1.4, 0.3), GOLD.darkened(0.3))
	k.merge(th, "stone")
	var clear := D + ":boss_clear"
	k.heart_container(bc.x, bc.y + 8.0, clear, D + ":heart_container", y)
	k.flag_bars(0.0, rb.position.y - 0.6, 0.0, "ch5:barrow_done", y)
	var hc := room_center("heart")
	k.platform(hc.x, hc.y - 3.0, Vector2(6.0, 6.0), y + 0.4, "stone", Color(0.82, 0.82, 0.88))
	k.blue_warp(hc.x, hc.y + 4.0, "ch5:barrow_done", "castle_town_restored", "from_barrow_of_kings", y)
	_candles(k, "heart")


func populate(k) -> void:
	var b1 := fy(2)
	var b2 := fy(1)
	var b3 := fy(0)
	k.enemy("rat", -32.0, 5.0, 0.0, {}, 0.0)
	k.enemy("barrow_knight", -5.0, -4.0, PI, {"room": "hall"}, 0.0)
	k.enemy("barrow_knight", 5.0, -4.0, PI, {"room": "hall"}, 0.0)
	k.enemy("keese", 0.0, 4.0, 0.0, {}, 4.0)
	k.enemy("stalfos", -29.0, 2.0, 0.0, {}, 0.0)
	k.enemy("keese", -26.0, -6.0, 0.0, {}, 4.0)
	k.enemy("shade", 26.0, -4.0, 0.0, {}, 1.3)
	k.enemy("stalfos", -6.0, -36.0, 0.0, {}, 0.0)
	k.enemy("stalfos", 6.0, -30.0, 0.0, {}, 0.0)
	k.enemy("keese", 4.0, -40.0, 0.0, {}, b1 + 4.0)
	k.enemy("barrow_knight", 0.0, 2.0, 0.0, {}, b1)
	k.enemy("stalfos", -6.0, -6.0, 0.0, {}, b1)
	k.enemy("barrow_champion", -30.0, 0.0, PI / 2.0, {"room": "armoury"}, b1)
	k.enemy("rat", 24.0, 6.0, 0.0, {}, b1)
	k.enemy("rat", 25.0, -6.0, 0.0, {}, b1)
	k.enemy("shade", 0.0, 22.0, 0.0, {}, b1 + 1.3)
	k.enemy("keese", 0.0, 24.0, 0.0, {}, b2 + 4.0)
	k.enemy("barrow_knight", -5.0, -2.0, PI, {"room": "gallery"}, b2)
	k.enemy("barrow_knight", 5.0, -2.0, PI, {"room": "gallery"}, b2)
	k.enemy("stalfos", 0.0, -8.0, PI, {"room": "gallery"}, b2)
	k.enemy("shade", -34.0, -5.0, 0.0, {}, b2 + 1.3)
	k.enemy("shade", -26.0, 6.0, 0.0, {}, b2 + 1.3)
	k.enemy("barrow_knight", 26.0, 4.0, 0.0, {}, b2)
	k.enemy("stalfos", -5.0, -30.0, 0.0, {}, b2)
	k.enemy("keese", 6.0, -44.0, 0.0, {}, b2 + 4.0)
	k.enemy("barrow_knight", 0.0, -32.0, 0.0, {}, b3)
	k.enemy("hollow_king", 0.0, -76.0, 0.0, {"room": "boss"}, b3)
