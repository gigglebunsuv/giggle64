extends "res://tools/world/tower_region.gd"
## The burning Citadel (Chapter IV's last dungeon): the Castle of Haven, the
## castle the hero knew, now burning from within as the Dark Prophecy foretold.
## Lava-lit halls, collapsed floors, burning banners, fire breathing from the
## walls; goblins, the Order's knights and mages, the Gauntlet's flame wards.
## Its treasure is the LONGSHOT (the library); at its top, on the throne-room
## roof under a sky of fire, Firebuns III waits, and this time the hero wins
## (Story.citadel_roof / sealing). Thirty-one rooms on six storeys: the
## largest dungeon yet.
##
## Storeys (north is -Z; W, C, E columns; S, M, N, NN rows):
##   B1 (y -8)  cellar CM    in by the drop from the hall; a cracked wall north
##              prison WM    a fight (bombs); the way north to the crypt
##              cistern EM   lava with a walk round it; targets (Hookshot)
##              vault CN     behind the cracked wall: a treasure chart
##              crypt WN     the royal crypt: dig spots
##              furnace EN   fire jets in turn; a chest at the end
##   1F (y 0)   gate CS      in from the burning town
##              hall CM      the Great Hall, its gallery fallen in: the Map
##              armory WM   three stakes for the Iron Mallet -> Key 1
##              kitchen EM   a fire jet over the Compass (Sapphire Staff)
##              stairhall CN (Key 1) a ladder up
##              garden WN    the burnt garden, open to the sky: dig -> Key 2
##              chapel EN    a flame ward before the altar (starlight)
##   2F (y 8)   landing CN   ladders up and down
##              library WN   (Key 2) a fight -> the LONGSHOT
##              gallery CM   its floor fallen into the hall; a ledge (Longshot)
##              solar EN     a gale toward the broken floor (Wind or Anchor Boots)
##              barracks WM  a fight -> Key 3
##              pantry EM    goblins and a chest
##   3F (y 16)  keep CN      (Key 3 north) the stair to the belfry
##              rampart_w WN open sky, archers and a gale
##              rampart_e EN open sky, its floor fallen: across by Longshot
##              ward_w WM    knights; a ladder to the west loft
##              ward_e EM    two weight plates -> Key 4; a ladder to the east loft
##              belfry CNN   two flame wards; the ladder up
##   4F (y 24)  tower_top CNN (Key 4 south) the ladder to the throne stair
##              guard CN     the Order's last guard: the Boss Key
##              loft_w WM    treasure
##              loft_e EM    treasure
##   5F (y 32)  throne_ante CNN the boss door
##              boss CN      the burning throne-room roof: Firebuns III

const D := "citadel_assault"
const STONE := Color(0.86, 0.84, 0.82)
const CHAR := Color(0.3, 0.26, 0.24)
const BURNT := Color(0.66, 0.56, 0.52)
const LAVA := Color(1.0, 0.45, 0.12)
const W_M := Rect2(-44, -10, 20, 20)
const C_M := Rect2(-15, -14, 30, 28)
const E_M := Rect2(24, -10, 20, 20)
const W_N := Rect2(-44, -46, 20, 22)
const C_N := Rect2(-12, -46, 24, 22)
const E_N := Rect2(24, -46, 20, 22)
const C_NN := Rect2(-11, -80, 22, 20)
const C_S := Rect2(-7, 18, 14, 12)
const LADDERS := [
	[0, -8.0, 6.0, Vector2(1, 0)],
	[1, 8.0, -40.0, Vector2(0, 1)],
	[2, -8.0, -40.0, Vector2(0, 1)],
	[3, 6.0, -76.0, Vector2(0, 1)],
	[4, -6.0, -74.0, Vector2(0, -1)],
	[3, -28.0, -6.0, Vector2(-1, 0)],
	[3, 28.0, -6.0, Vector2(1, 0)],
]
const GALLERY_HOLE := Rect2(-15, -4, 30, 10)
## The lava pool in the cistern (B1): a pit in the floor.
const CISTERN_LAVA := Rect2(28, -6, 12, 12)
## The east rampart's fallen floor: the whole middle, too far for the Hookshot.
const RAMPART_GAP := Rect2(27, -46, 14, 22)
## The west rampart's broken parapet.
const PARAPET_GAP := Rect2(-44, -46, 3, 22)
const SOLAR_HOLE := Rect2(37, -45, 6, 20)


func _doors_m(w: bool, e: bool, n: bool, s: bool, nx := 0.0) -> Array:
	var out: Array = []
	if w:
		out.append({"side": "w", "at": 0.0})
	if e:
		out.append({"side": "e", "at": 0.0})
	if n:
		out.append({"side": "n", "at": nx})
	if s:
		out.append({"side": "s", "at": nx})
	return out


func setup() -> void:
	id = "citadel_assault"
	interior = true
	seed_value = 1818
	x_min = -50.0
	x_max = 50.0
	z_min = -86.0
	z_max = 34.0
	outer = 3.0
	cell = 1.0
	tex_size = 512
	rim_height = 0.0
	links = []
	floors = [["B1", -8.0], ["1F", 0.0], ["2F", 8.0], ["3F", 16.0], ["4F", 24.0], ["5F", 32.0]]
	entry_floor = 1
	wall_col = STONE.darkened(0.08)
	ceil_col = Color(0.28, 0.2, 0.18)
	slab_col = Color(0.78, 0.74, 0.7)
	var dark := Color(0.56, 0.5, 0.48)
	rooms = {
		# B1
		"cellar": {"f": 0, "r": Rect2(-13, -12, 26, 24), "h": 6.5, "doors": [{"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "col": dark},
		"prison": {"f": 0, "r": W_M, "h": 6.0, "doors": [{"side": "e", "at": 0.0}, {"side": "n", "at": -34.0}], "col": dark},
		"cistern": {"f": 0, "r": E_M, "h": 6.0, "doors": [{"side": "w", "at": 0.0}, {"side": "n", "at": 34.0}], "col": dark},
		"vault": {"f": 0, "r": C_N, "h": 6.0, "doors": [{"side": "s", "at": 0.0}], "col": dark},
		"crypt": {"f": 0, "r": W_N, "h": 6.0, "doors": [{"side": "s", "at": -34.0}], "col": dark.darkened(0.1)},
		"furnace": {"f": 0, "r": E_N, "h": 6.0, "doors": [{"side": "s", "at": 34.0}], "col": CHAR},
		# 1F
		"gate": {"f": 1, "r": C_S, "h": 6.5, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}], "col": BURNT},
		"hall": {"f": 1, "r": C_M, "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "col": BURNT},
		"armoury": {"f": 1, "r": W_M, "h": 6.0, "doors": [{"side": "e", "at": 0.0}]},
		"kitchen": {"f": 1, "r": E_M, "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "col": BURNT},
		"stairhall": {"f": 1, "r": C_N, "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": -35.0}, {"side": "e", "at": -35.0}]},
		"garden": {"f": 1, "r": W_N, "h": 6.0, "doors": [{"side": "e", "at": -35.0}], "ceiling": false, "col": BURNT},
		"chapel": {"f": 1, "r": E_N, "h": 6.5, "doors": [{"side": "w", "at": -35.0}], "col": Color(0.9, 0.88, 0.86)},
		# 2F
		"landing": {"f": 2, "r": C_N, "h": 6.5, "doors": [{"side": "w", "at": -35.0}, {"side": "e", "at": -35.0}, {"side": "s", "at": 0.0}]},
		"library": {"f": 2, "r": W_N, "h": 6.5, "doors": [{"side": "e", "at": -35.0}, {"side": "s", "at": -34.0}], "floor_mat": "wood", "floor_col": Color(0.7, 0.58, 0.42)},
		"gallery": {"f": 2, "r": C_M, "h": 6.5, "doors": [{"side": "n", "at": 0.0}], "col": BURNT},
		"solar": {"f": 2, "r": E_N, "h": 6.5, "doors": [{"side": "w", "at": -35.0}, {"side": "s", "at": 34.0}], "floor_mat": "wood", "floor_col": Color(0.7, 0.58, 0.42)},
		"barracks": {"f": 2, "r": W_M, "h": 6.0, "doors": [{"side": "n", "at": -34.0}]},
		"pantry": {"f": 2, "r": E_M, "h": 6.0, "doors": [{"side": "n", "at": 34.0}]},
		# 3F
		"keep": {"f": 3, "r": C_N, "h": 6.5, "doors": [{"side": "w", "at": -35.0}, {"side": "e", "at": -35.0}, {"side": "n", "at": 0.0}]},
		"rampart_w": {"f": 3, "r": W_N, "h": 4.0, "doors": [{"side": "e", "at": -35.0}, {"side": "s", "at": -34.0}], "ceiling": false, "col": BURNT},
		"rampart_e": {"f": 3, "r": E_N, "h": 4.0, "doors": [{"side": "w", "at": -35.0}, {"side": "s", "at": 42.5}], "ceiling": false, "col": BURNT},
		"ward_w": {"f": 3, "r": W_M, "h": 6.0, "doors": [{"side": "n", "at": -34.0}]},
		"ward_e": {"f": 3, "r": E_M, "h": 6.0, "doors": [{"side": "n", "at": 42.5}]},
		"belfry": {"f": 3, "r": C_NN, "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# 4F
		"tower_top": {"f": 4, "r": C_NN, "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		"guard": {"f": 4, "r": C_N, "h": 6.5, "doors": [{"side": "n", "at": 0.0}], "col": Color(0.7, 0.72, 0.86)},
		"loft_w": {"f": 4, "r": W_M, "h": 5.0, "doors": [], "floor_mat": "wood", "floor_col": Color(0.66, 0.54, 0.4)},
		"loft_e": {"f": 4, "r": E_M, "h": 5.0, "doors": [], "floor_mat": "wood", "floor_col": Color(0.66, 0.54, 0.4)},
		# 5F
		"throne_ante": {"f": 5, "r": C_NN, "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": BURNT},
		"boss": {"f": 5, "r": Rect2(-18, -52, 36, 30), "h": 4.0, "doors": [{"side": "n", "at": 0.0}], "ceiling": false, "col": BURNT},
	}
	corridors = [
		# B1
		{"f": 0, "r": Rect2(-24, -2, 11, 4), "x": true},
		{"f": 0, "r": Rect2(13, -2, 11, 4), "x": true},
		{"f": 0, "r": Rect2(-2, -24, 4, 12), "x": false},
		{"f": 0, "r": Rect2(-36, -24, 4, 14), "x": false},
		{"f": 0, "r": Rect2(32, -24, 4, 14), "x": false},
		# 1F
		{"f": 1, "r": Rect2(-2, 14, 4, 4), "x": false},
		{"f": 1, "r": Rect2(-24, -2, 9, 4), "x": true},
		{"f": 1, "r": Rect2(15, -2, 9, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -24, 4, 10), "x": false},
		{"f": 1, "r": Rect2(-24, -37, 12, 4), "x": true},
		{"f": 1, "r": Rect2(12, -37, 12, 4), "x": true},
		# 2F
		{"f": 2, "r": Rect2(-24, -37, 12, 4), "x": true},
		{"f": 2, "r": Rect2(12, -37, 12, 4), "x": true},
		{"f": 2, "r": Rect2(-2, -24, 4, 10), "x": false},
		{"f": 2, "r": Rect2(-36, -24, 4, 14), "x": false},
		{"f": 2, "r": Rect2(32, -24, 4, 14), "x": false},
		# 3F
		{"f": 3, "r": Rect2(-24, -37, 12, 4), "x": true},
		{"f": 3, "r": Rect2(12, -37, 12, 4), "x": true},
		{"f": 3, "r": Rect2(-36, -24, 4, 14), "x": false},
		{"f": 3, "r": Rect2(40.5, -24, 4, 14), "x": false},
		{"f": 3, "r": Rect2(-2, -60, 4, 14), "x": false},
		# 4F
		{"f": 4, "r": Rect2(-2, -60, 4, 14), "x": false},
		# 5F
		{"f": 5, "r": Rect2(-2, -60, 4, 8), "x": false},
	]
	holes = [
		{"f": 2, "r": GALLERY_HOLE},
		{"f": 3, "r": RAMPART_GAP},
		{"f": 3, "r": PARAPET_GAP},
		{"f": 2, "r": SOLAR_HOLE},
	]
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	mood = {
		"sky_top": Color.html("1e0a0a"), "sky_mid": Color.html("6a1e14"), "sky_horizon": Color.html("e05a24"),
		"cloud": Color.html("3a1a14"), "cloud_amount": 0.9,
		"fog": Color.html("3a1410"), "fog_begin": 12.0, "fog_end": 62.0,
		"ambient": Color.html("7a4a3a"), "sun": Color.html("ff9a4a"), "sun_rot": Vector3(-30, 25, 0),
		"sun_energy": 0.9, "fill": Color.html("5a2a3a"), "fill_energy": 0.5,
		"horizon": Color.html("3a1410"), "hill_height": 0.0, "particles": "embers",
	}


## The lowest storey's floor, with the cistern's lava pit sunk into it.
func base_height(x: float, z: float) -> float:
	if CISTERN_LAVA.has_point(Vector2(x, z)) and not Rect2(32, -2, 4, 4).has_point(Vector2(x, z)):
		return fy(0) - 0.9
	return fy(0)


func _inside(x: float, z: float, f: int) -> bool:
	for rid: String in rooms:
		var rm: Dictionary = rooms[rid]
		if rm.f == f and (rm.r as Rect2).grow(1.0).has_point(Vector2(x, z)):
			return true
	for c: Dictionary in corridors:
		if c.f == f and (c.r as Rect2).has_point(Vector2(x, z)):
			return true
	return false


## The castle's white flagstones scorched black, red carpets burnt to rags,
## cracks glowing with the fire beneath.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["0e0806", "120a08"])
	var p := Vector2(x, z)
	if f == 1 and (rooms.hall.r as Rect2).has_point(p) and absf(x) < 2.6:
		return Color.html("6a1a14").darkened(r.randf_range(0.0, 0.2)) if r.randf() < 0.8 else Color.html("2a1a14")
	var crack := detail.get_noise_2d(x * 3.0, z * 3.0)
	if absf(crack) < 0.025:
		return Color.html("ff7a2a")
	var burn := noise.get_noise_2d(x * 1.5 + f * 13.0, z * 1.5)
	var base := Color.html(["d8d0c4", "cec6ba", "e0d8cc"][r.randi() % 3])
	return base.lerp(Color.html("2a2220"), clampf(burn * 1.4 + 0.35, 0.0, 0.85)).darkened(r.randf_range(0.0, 0.06))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 1.8, 2.8, "castle_town_fallen", "from_castle", Color(0.5, 0.36, 0.3))
	k.entrance("from_castle_town", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	_b1(k)
	_f1(k)
	_f2(k)
	_f3(k)
	_f4(k)
	_f5(k)


# --- Dressing --------------------------------------------------------------------

func _fires(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.fire(p.x, p.y, 0.8, y, true)


func _burning_banner(k, x: float, y: float, z: float, yaw: float) -> void:
	k.banner(x, y, z, yaw, Color.html("3a2a4a"), 2.0)
	k.fire(x, z + (0.3 if yaw == 0.0 else 0.0), 0.5, y - 1.6, false)


## A pool of lava over the x/z rectangle `r` at `y`: glowing, and a fall into
## it burns and returns the hero to where he came into the room.
func _lava(k, r: Rect2, y: float) -> void:
	var m = k._tmp(false)
	m.box(Vector3(r.get_center().x, y - 0.55, r.get_center().y), Vector3(r.size.x, 0.1, r.size.y), LAVA)
	k.merge(m, "glow")
	k.void_zone(Vector3(r.get_center().x, y - 0.6, r.get_center().y), Vector3(r.size.x - 0.6, 0.5, r.size.y - 0.6), 2)
	k.fire(r.get_center().x, r.get_center().y, 1.4, y - 0.6, true)


func _jet(k, pos: Vector3, yaw: float, opts := {}) -> void:
	k._dyn("res://scripts/dungeon/fire_jet.gd", "FireJet", pos, yaw, opts, Node3D.new())


# --- B1 -------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(0)
	_fires(k, "cellar")
	k.bomb_wall(0.0, -12.4, 0.0, D + ":vault_wall", y)
	for p in [Vector2(-10, -9), Vector2(10, 9), Vector2(9, -9)]:
		k.barrel(p.x, p.y)
	# The prison: a fight; bombs.
	k.shutter(-24.6, 0.0, PI / 2.0, "prison", y)
	k.chest(-40.0, 6.0, PI / 2.0, "bombs_10", false, D + ":chest_prison", D + ":prison_clear", y)
	# The cistern: a lava pool, a walk round its edge, a chest on an islet.
	_lava(k, CISTERN_LAVA, y)
	k.platform(34.0, 0.0, Vector2(4.0, 4.0), y + 0.4, "stone", STONE.darkened(0.2))
	k.chest(33.6, 0.0, -PI / 2.0, "rupee_gold", false, D + ":chest_cistern", "", y + 0.4)
	k.block(Vector3(35.6, y + 2.0, 0.0), Vector3(0.6, 3.2, 0.6), 0.0, "stone", STONE.darkened(0.3))
	k.hook_target(Vector3(35.25, y + 2.8, 0.0), -PI / 2.0)
	# The vault: behind the cracked wall, a treasure chart.
	k.chest(-4.0, -42.0, 0.0, "chart_6", false, D + ":chest_chart", "", y)
	k.chest(4.0, -42.0, 0.0, "rupee_red", false, D + ":chest_vault", "", y)
	# The crypt: the kings' tombs, the soft earth of the old graves.
	for x in [-40.0, -34.0, -28.0]:
		k.block(Vector3(x, y + 0.5, -42.0), Vector3(1.8, 1.0, 3.0), 0.0, "stone", STONE.darkened(0.2))
	k.dig_spot("citadel_grave_a", -40.0, -32.0, "rupee_purple", {"loose": true}, y)
	k.dig_spot("citadel_grave_b", -30.0, -30.0, "heart", {"loose": true}, y)
	# The furnace: three jets in turn across the way to the chest.
	for i in 3:
		_jet(k, Vector3(25.0, y + 1.0, -30.0 - i * 5.0), -PI / 2.0, {"length": 18.0, "period": 3.0, "burn": 1.4, "phase": i * 1.0})
	k.chest(34.0, -44.0, 0.0, "rupee_red", false, D + ":chest_furnace", "", y)


# --- 1F -------------------------------------------------------------------------

func _f1(k) -> void:
	var y := fy(1)
	# The gate.
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 5.0, z, 6.0, 0.45, true, "stone", y)
	k.pot(5.4, 28.5, "heart", false, y)
	k.pot(-5.4, 28.5, "magic_small", false, y)
	# The Great Hall: its gallery fallen in, fires in the rubble, the Map.
	for p in [Vector2(-8, -2), Vector2(9, 4), Vector2(2, -6)]:
		k.rubble(p.x, p.y, k.rng.randf() * TAU, 1.2, y)
	_fires(k, "hall", 3.0)
	_burning_banner(k, -6.0, y + 5.0, -13.4, 0.0)
	_burning_banner(k, 6.0, y + 5.0, -13.4, 0.0)
	k.chest(12.0, 10.0, PI, "map", false, D + ":chest_map", "", y)
	k.locked_door(0.0, -14.4, 0.0, D + ":door_key1", false, y)
	# The armory: three stakes -> Key 1.
	var flags: Array = []
	for s in [[-40.0, -6.0, "stake_a"], [-40.0, 6.0, "stake_b"], [-30.0, 0.0, "stake_c"]]:
		k.mallet_stake(s[0], s[1], D + ":" + s[2], y)
		flags.append(D + ":" + s[2])
	k.flag_all(flags, D + ":stakes")
	k.chest(-34.0, -7.0, 0.0, "small_key", false, D + ":chest_key1", D + ":stakes", y)
	_fires(k, "armoury")
	# The kitchen: a fire jet across the alcove before the Compass.
	k.block(Vector3(40.0, y + 1.5, -3.0), Vector3(8.0, 3.0, 0.4), 0.0, "stone", STONE)
	k.block(Vector3(40.0, y + 1.5, 3.0), Vector3(8.0, 3.0, 0.4), 0.0, "stone", STONE)
	_jet(k, Vector3(43.6, y + 1.0, 0.0), -PI / 2.0, {"length": 10.0, "period": 0.0})
	k.chest(42.0, 0.0, -PI / 2.0, "compass", false, D + ":chest_compass", "", y)
	k.examine(Vector3(26.0, y, 4.0), -PI / 2.0, [{"text": "A cook's note, singed:\n*THE ORDER SAYS THE STOVE BURNS FOREVER NOW. NOTHING STOPS THAT FIRE BUT THEIR OWN BLUE STONE.*", "instant": true}])
	# The stair hall.
	_fires(k, "stairhall")
	# The garden: burnt to the earth; something buried in the old rose bed.
	for i in 6:
		var a := TAU * i / 6.0
		k.tree_dead(-34.0 + cos(a) * 6.0, -35.0 + sin(a) * 6.0, 0.8)
	k.dig_spot("citadel_garden", -38.0, -40.0, "small_key", {}, y)
	k.dig_spot("citadel_rose", -30.0, -30.0, "rupee_blue", {"loose": true}, y)
	k.examine(Vector3(-25.0, y, -33.0), PI / 2.0, [{"text": "The princess's rose bed is ash. A little sign is still stuck in it:\n*PLEASE DO NOT DIG IN THE ROSES. -THE GARDENER*", "instant": true}])
	# The chapel: a ward of the Order's fire before the altar.
	k.sapphire_ward(34.0, -40.0, 0.0, 19.6, D + ":chapel_ward", y)
	k.platform(34.0, -44.0, Vector2(6.0, 2.0), y + 0.5, "stone", STONE)
	k.pot(31.0, -44.0, "heart", false, y + 0.5)
	k.pot(37.0, -44.0, "magic_small", false, y + 0.5)
	k._dyn("res://scripts/items/fairy.gd", "ChapelFairy", Vector3(34.0, y + 1.8, -44.0), 0.0, {}, Node3D.new())


# --- 2F -------------------------------------------------------------------------

func _f2(k) -> void:
	var y := fy(2)
	_fires(k, "landing")
	# The library: burning shelves; a fight; the Longshot.
	k.locked_door(-24.4, -35.0, PI / 2.0, D + ":door_key2", false, y)
	for z in [-42.0, -36.0, -30.0]:
		k.block(Vector3(-36.0, y + 1.5, z), Vector3(10.0, 3.0, 0.6), 0.0, "wood", Color(0.36, 0.26, 0.2))
		k.fire(-38.0, z, 0.6, y + 3.0, false)
	k.chest(-34.0, -26.0, PI, "longshot", true, D + ":chest_longshot", D + ":library_clear", y)
	# The gallery: the floor fallen into the hall; a ledge at the far end,
	# a target over it for the Longshot.
	k.chest(0.0, 11.0, PI, "rupee_gold", false, D + ":chest_gallery", "", y)
	k.hook_target(Vector3(0.0, y + 3.2, 13.4), PI)
	# The solar: a gale through the shattered windows toward the broken floor.
	k.wind_zone(Vector3(32.0, y + 1.5, -35.0), Vector3(14.0, 3.0, 20.0), Vector3(1, 0, 0), 6.0)
	k.chest(30.0, -44.0, 0.0, "rupee_purple", false, D + ":chest_solar", "", y)
	# The barracks: a fight -> Key 3.
	k.shutter(-34.0, -10.6, 0.0, "barracks", y)
	for x in [-40.0, -36.0, -32.0, -28.0]:
		k.block(Vector3(x, y + 0.5, 7.0), Vector3(1.4, 1.0, 2.6), 0.0, "wood", Color(0.5, 0.38, 0.28))
	k.chest(-40.0, -6.0, PI / 2.0, "small_key", false, D + ":chest_key3", D + ":barracks_clear", y)
	# The pantry: goblins, a chest.
	k.chest(40.0, 6.0, PI, "bombs_10", false, D + ":chest_pantry", "", y)
	for p in [Vector2(28, 6), Vector2(29, 7.5), Vector2(41, -6)]:
		k.barrel(p.x, p.y)


# --- 3F -------------------------------------------------------------------------

func _f3(k) -> void:
	var y := fy(3)
	_fires(k, "keep")
	k.locked_door(0.0, -46.4, 0.0, D + ":door_key3", false, y)
	# The west rampart: archers on the wall, a gale off the broken parapet.
	k.wind_zone(Vector3(-34.0, y + 1.5, -35.0), Vector3(18.0, 3.0, 8.0), Vector3(-1, 0, 0), 5.0)
	for p in [Vector2(-42, -44), Vector2(-42, -26)]:
		k.war_banner(p.x, p.y, PI / 2.0, y)
	# The east rampart: its middle fallen away, a target on the far wall over
	# the last strip of floor (too far for the Hookshot: the Longshot).
	k.hook_target(Vector3(43.6, y + 2.6, -35.0), -PI / 2.0)
	k.examine(Vector3(25.5, y, -30.0), -PI / 2.0, [{"text": "The rampart has fallen in. Far across the gap, a beam of the old roof still juts from the wall.", "instant": true}])
	# The west ward: knights; the ladder to its loft.
	_fires(k, "ward_w")
	# The east ward: two weight plates -> Key 4.
	for x in [28.0, 40.0]:
		k._dyn("res://scripts/dungeon/hold_switch.gd", "WeightPlate", Vector3(x, y, 4.0), 0.0, {"result": D + ":ward_plates"}, Area3D.new())
	k.chest(34.0, 7.0, PI, "small_key", false, D + ":chest_key4", D + ":ward_plates", y)
	# The belfry: two flame wards on the way to the ladder.
	for z in [-64.0, -70.0]:
		for sx in [-1.0, 1.0]:
			k.block(Vector3(sx * 7.0, y + 3.25, z), Vector3(8.0, 6.5, 0.6), 0.0, "stone", STONE.darkened(0.12))
	k.sapphire_ward(0.0, -64.0, 0.0, 6.0, D + ":belfry_ward_a", y)
	k.sapphire_ward(0.0, -70.0, 0.0, 6.0, D + ":belfry_ward_b", y)
	_fires(k, "belfry")


# --- 4F -------------------------------------------------------------------------

func _f4(k) -> void:
	var y := fy(4)
	k.locked_door(0.0, -60.4, PI, D + ":door_key4", false, y)
	_fires(k, "tower_top")
	# The Order's last guard: a battle-mage and two knights; the Boss Key.
	k.shutter(0.0, -45.4, 0.0, "guard", y)
	k.chest(0.0, -28.0, PI, "boss_key", true, D + ":chest_boss_key", D + ":guard_clear", y)
	for p in [Vector2(-9, -43), Vector2(9, -43), Vector2(-9, -27), Vector2(9, -27)]:
		k.sapphire_brazier(p.x, p.y, y)
	# The lofts.
	k.chest(-40.0, 6.0, PI, "rupee_gold", false, D + ":chest_loft_w", "", y)
	k.pot(-36.0, 7.0, "magic_small", false, y)
	k.pot(36.0, 7.0, "heart", false, y)
	k.pot(40.0, 7.0, "heart", false, y)
	k.chest(40.0, -6.0, -PI / 2.0, "arrows_30", false, D + ":chest_loft_e", "", y)


# --- 5F -------------------------------------------------------------------------

func _f5(k) -> void:
	var y := fy(5)
	k.locked_door(0.0, -60.4, PI, D + ":boss_door", true, y)
	for p in [Vector2(-7, -76), Vector2(7, -76)]:
		k.pot(p.x, p.y, "heart", false, y)
	k.pot(-7.0, -64.0, "magic_small", false, y)
	k.pot(7.0, -64.0, "arrows_10", false, y)
	# The burning roof of the throne room: broken parapets, fire everywhere.
	var rb: Rect2 = rooms.boss.r
	k.shutter(0.0, rb.position.y + 0.6, 0.0, "boss", y)
	for p in [Vector2(-15, -48), Vector2(15, -48), Vector2(-15, -26), Vector2(15, -26), Vector2(0, -24)]:
		k.fire(p.x, p.y, 1.6, y, true)
	for p in [Vector2(-12, -38), Vector2(12, -38)]:
		k.pillar(p.x, p.y, 3.0, 0.7, true, "stone", y)
	var c := rb.get_center()
	k.mark("cs_roof_firebuns", Vector3(c.x, y, c.y + 6.0), 0.0)
	k.mark("cs_roof_hero", Vector3(c.x, y, c.y - 8.0), PI)
	k.mark("cs_roof_cam", Vector3(c.x + 7.0, y + 3.5, c.y - 12.0))
	k.story_trigger("citadel_roof", Rect2(rb.position.x, rb.position.y, rb.size.x, 6.0), y, "ch4:roof_seen", "")


func populate(k) -> void:
	var b1 := fy(0)
	var f1 := fy(1)
	var f2 := fy(2)
	var f3 := fy(3)
	var f4 := fy(4)
	var f5 := fy(5)
	# B1
	k.enemy("charred_stalfos", -4.0, 4.0, 0.0, {}, b1)
	k.enemy("fire_keese", 6.0, -6.0, 0.0, {}, b1 + 3.5)
	k.enemy("basic_enemy", -36.0, -4.0, PI / 2.0, {"room": "prison"}, b1)
	k.enemy("basic_enemy", -32.0, 4.0, PI / 2.0, {"room": "prison"}, b1)
	k.enemy("goblin_archer", -40.0, 0.0, -PI / 2.0, {"room": "prison"}, b1)
	k.enemy("fire_keese", 30.0, 6.0, 0.0, {}, b1 + 3.5)
	k.enemy("charred_stalfos", -34.0, -36.0, 0.0, {}, b1)
	k.enemy("charred_stalfos", -28.0, -40.0, 0.0, {}, b1)
	# 1F
	k.enemy("basic_enemy", -6.0, 6.0, 0.0, {}, f1)
	k.enemy("basic_enemy", 6.0, 0.0, 0.0, {}, f1)
	k.enemy("goblin_archer", 0.0, -10.0, PI, {}, f1)
	k.enemy("sapphire_knight", -34.0, 4.0, 0.0, {}, f1)
	k.enemy("fire_keese", 34.0, 6.0, 0.0, {}, f1 + 3.5)
	k.enemy("sapphire_mage", 0.0, -30.0, PI, {}, f1)
	k.enemy("shadow_wolf", -34.0, -34.0, 0.0, {}, f1)
	k.enemy("shadow_wolf", -38.0, -30.0, 0.0, {}, f1)
	# 2F
	k.enemy("sapphire_knight", -34.0, -40.0, 0.0, {"room": "library"}, f2)
	k.enemy("sapphire_knight", -30.0, -30.0, 0.0, {"room": "library"}, f2)
	k.enemy("sapphire_mage", -40.0, -34.0, PI / 2.0, {"room": "library"}, f2)
	k.enemy("fire_keese", 0.0, -36.0, 0.0, {}, f2 + 3.5)
	k.enemy("basic_enemy", -36.0, 0.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", -30.0, 4.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("boar_rider", -34.0, -4.0, 0.0, {"room": "barracks"}, f2)
	k.enemy("basic_enemy", 32.0, 0.0, 0.0, {}, f2)
	k.enemy("goblin_archer", 38.0, -4.0, -PI / 2.0, {}, f2)
	# 3F
	k.enemy("charred_stalfos", 4.0, -36.0, 0.0, {}, f3)
	k.enemy("goblin_archer", -40.0, -40.0, PI / 2.0, {}, f3)
	k.enemy("goblin_archer", -40.0, -30.0, PI / 2.0, {}, f3)
	k.enemy("sapphire_knight", -34.0, 0.0, 0.0, {}, f3)
	# One of the Order's plain knights here, no name card (the Southern Tower's is the mini-boss).
	k.enemy("rust_knight", -30.0, 4.0, 0.0, {"title_name": "", "title_epithet": ""}, f3)
	k.enemy("fire_keese", 34.0, -2.0, 0.0, {}, f3 + 3.5)
	k.enemy("sapphire_mage", 0.0, -74.0, 0.0, {}, f3)
	# 4F
	k.enemy("battle_mage", 0.0, -36.0, PI, {"room": "guard"}, f4)
	k.enemy("sapphire_knight", -6.0, -34.0, PI, {"room": "guard"}, f4)
	k.enemy("sapphire_knight", 6.0, -34.0, PI, {"room": "guard"}, f4)
	# 5F: Firebuns III on the roof (the second battle).
	k.enemy("firebuns", 0.0, -31.0, 0.0, {"room": "boss", "sealing": true}, f5)
