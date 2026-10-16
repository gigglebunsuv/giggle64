extends "res://tools/world/tower_region.gd"
## The Cinder Vault, under Cinderhold (Chapter V): where Serielye kept the
## Gauntlet of Fire, long before Bunsriel had kings. Its upper halls are a
## forge of black stone and lava, still burning; below, the goddess's wardens
## laid a frost over the vault that never thawed. Its treasure is the EMBER
## ROD; its master MAGMAW, the lava serpent that swims under the cradle's
## floor (Frost Arrows crust it, then the sword). At its heart the old anvil,
## where Firebuns III has rekindled the Gauntlet (Story.vault_heart).
##
## Storeys, top down (north is -Z):
##   1F (y 0)    gate S      in from the mountain; Serielye's words
##               forge C     the great forge; a lava trench; rime-ice closes
##                           the north door (the Ember Rod)
##               bellows W   fire jets; two torches lit by burning arrows -> Key 1
##               anvils E    a great stone over the way down (the Gauntlets);
##                           the Map
##               smelter N   behind the rime (the Ember Rod): a treasure
##   B1 (y -8)   quench E    in by the ladder; the quenching pool
##               foundry C   a fight (shutters); locked north (Key 1)
##               moulds W    the Vault Warden (mini-boss) -> the Ember Rod
##               kiln S      four torches (the Ember Rod) open the floor
##               ore N       thorns (the Ember Rod) -> the Compass; the Hookshot
##                           over a lava trench -> Key 2
##   B2 (y -16)  cistern S   in by the drop; a ladder back up
##               frost C     the wardens' frost: rime walls to melt; locked
##                           north (Key 2)
##               wardens W   three torches cased in rime -> the Boss Key
##               forgefire E fire jets in turn; a chest
##               vent N      a ledge over a floor seal (the Down Thrust)
##   B3 (y -24)  nave N      in by the seal; the boss door north
##               boss        the cradle: MAGMAW
##               heart       the old anvil; the blue warp out

const D := "cinder_vault"
const BASALT := Color(0.42, 0.36, 0.36)
const EMBER := Color(1.6, 0.55, 0.18)
const FROST := Color(0.78, 0.86, 0.96)
## Ladders back up: [storey below, pier x, pier z, out].
const LADDERS := [
	[2, 26.0, 6.0, Vector2(1, 0)],
	[1, -5.5, 21.0, Vector2(1, 0)],
	[0, -8.0, -30.0, Vector2(1, 0)],
]
const KILN_HOLE := Vector3(2.5, -8.0, 24.0)
const SEAL := Vector2(0.0, -40.0)


func setup() -> void:
	id = "cinder_vault"
	interior = true
	seed_value = 1304
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
	wall_col = BASALT
	ceil_col = Color(0.2, 0.16, 0.16)
	slab_col = Color(0.44, 0.38, 0.38)
	rooms = {
		# 1F
		"gate": {"f": 3, "r": Rect2(-6, 18, 12, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}, {"side": "s", "at": 0.0}]},
		"forge": {"f": 3, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"bellows": {"f": 3, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}]},
		"anvils": {"f": 3, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"smelter": {"f": 3, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B1
		"quench": {"f": 2, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}], "col": Color(0.36, 0.4, 0.44)},
		"foundry": {"f": 2, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "e", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}]},
		"moulds": {"f": 2, "r": Rect2(-40, -10, 20, 20), "h": 6.5, "doors": [{"side": "e", "at": 0.0}]},
		"kiln": {"f": 2, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}]},
		"ore": {"f": 2, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B2
		"cistern": {"f": 1, "r": Rect2(-7, 18, 14, 12), "h": 6.0, "doors": [{"side": "n", "at": 0.0}], "col": FROST.darkened(0.3)},
		"frost": {"f": 1, "r": Rect2(-14, -12, 28, 24), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "w", "at": 0.0}, {"side": "e", "at": 0.0}, {"side": "n", "at": 0.0}], "col": FROST.darkened(0.15)},
		"wardens": {"f": 1, "r": Rect2(-40, -10, 20, 20), "h": 6.0, "doors": [{"side": "e", "at": 0.0}], "col": FROST.darkened(0.2)},
		"forgefire": {"f": 1, "r": Rect2(20, -10, 20, 20), "h": 6.0, "doors": [{"side": "w", "at": 0.0}]},
		"vent": {"f": 1, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "s", "at": 0.0}]},
		# B3
		"nave": {"f": 0, "r": Rect2(-11, -46, 22, 20), "h": 6.5, "doors": [{"side": "n", "at": 0.0}]},
		"boss": {"f": 0, "r": Rect2(-16, -86, 32, 32), "h": 6.5, "doors": [{"side": "s", "at": 0.0}, {"side": "n", "at": 0.0}], "col": BASALT.darkened(0.2)},
		"heart": {"f": 0, "r": Rect2(-10, -116, 20, 22), "h": 6.5, "doors": [{"side": "s", "at": 0.0}], "col": Color(0.5, 0.3, 0.26)},
	}
	corridors = [
		{"f": 3, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 3, "r": Rect2(-20, -2, 6, 4), "x": true},
		{"f": 3, "r": Rect2(14, -2, 6, 4), "x": true},
		{"f": 3, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 2, "r": Rect2(14, -2, 6, 4), "x": true},
		{"f": 2, "r": Rect2(-20, -2, 6, 4), "x": true},
		{"f": 2, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 2, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 1, "r": Rect2(-2, 12, 4, 6), "x": false},
		{"f": 1, "r": Rect2(-20, -2, 6, 4), "x": true},
		{"f": 1, "r": Rect2(14, -2, 6, 4), "x": true},
		{"f": 1, "r": Rect2(-2, -26, 4, 14), "x": false},
		{"f": 0, "r": Rect2(-2, -54, 4, 8), "x": false},
		{"f": 0, "r": Rect2(-2, -94, 4, 8), "x": false},
	]
	holes = []
	for l: Array in LADDERS:
		holes.append({"f": int(l[0]) + 1, "r": ladder_hole(l[1], l[2], l[3])})
	holes.append({"f": 2, "r": Rect2(KILN_HOLE.x - 1.3, KILN_HOLE.z - 1.3, 2.6, 2.6)})
	holes.append({"f": 1, "r": Rect2(SEAL - Vector2(1.3, 1.3), Vector2(2.6, 2.6))})
	mood = {
		"sky_top": Color.html("140808"), "sky_mid": Color.html("140808"), "sky_horizon": Color.html("140808"),
		"cloud": Color.html("140808"), "cloud_amount": 0.0,
		"fog": Color.html("241210"), "fog_begin": 14.0, "fog_end": 56.0,
		"ambient": Color.html("7a5048"), "sun": Color.html("ffc890"), "sun_rot": Vector3(-70, 30, 0),
		"sun_energy": 0.45, "fill": Color.html("6a3428"), "fill_energy": 0.45,
		"horizon": Color.html("140808"), "hill_height": 0.0,
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


## Black basalt flags with ember-red seams; frost-white on the warden's
## storey; the cradle's floor a crust of cooled lava over the serpent's sea.
func floor_paint(x: float, z: float, f: int, r: RandomNumberGenerator) -> Color:
	if not _inside(x, z, f):
		return pick(r, ["0a0606", "0e0808"])
	var p := Vector2(x, z)
	if f == 1 and not (rooms.forgefire.r as Rect2).has_point(p):
		var seam_f := fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08
		return Color.html("9aa8b8") if seam_f else Color.html(["d8e0ea", "ccd6e2", "e2e8f0"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.06))
	if f == 0 and (rooms.boss.r as Rect2).has_point(p):
		var q := p - room_center("boss")
		if fposmod(q.length() * 0.7 + noise.get_noise_2d(x * 3.0, z * 3.0) * 2.0, 2.0) < 0.12:
			return Color.html("c04a1a")
		return Color.html(["2a2220", "302624", "26201e"][r.randi() % 3])
	var seam := fposmod(x, 2.0) < 0.08 or fposmod(z, 2.0) < 0.08
	if seam:
		return Color.html("7a2a14")
	return Color.html(["3a3232", "342c2c", "403636"][r.randi() % 3]).darkened(r.randf_range(0.0, 0.06))


func build_rooms(k) -> void:
	k.door_link(Vector3(0, 0, 29.98), 0.0, 2.0, 3.0, "cinderhold", "from_cinder_vault", Color(0.3, 0.18, 0.16))
	k.entrance("from_cinderhold", 0.0, 27.0, 0.0)
	for l: Array in LADDERS:
		ladder_up(k, l[0], l[1], l[2], l[3])
	_f1(k)
	_b1(k)
	_b2(k)
	_b3(k)


func _fires(k, rid: String, inset := 2.0) -> void:
	var r: Rect2 = rooms[rid].r
	var y := room_y(rid)
	for p in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset),
			Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
		k.torch(p.x, p.y, true, "", y)


func _jet(k, pos: Vector3, yaw: float, opts := {}) -> void:
	k._dyn("res://scripts/dungeon/fire_jet.gd", "FireJet", pos, yaw, opts, Node3D.new())


## A grate over a hole in the floor at `at` (its top), gone once `flag` is set.
func _cover(k, at: Vector3, flag: String) -> void:
	var m = k._tmp(false)
	for i in 6:
		m.box(Vector3(-1.2 + i * 0.48, -0.1, 0), Vector3(0.12, 0.2, 2.8), Color(0.3, 0.24, 0.22))
	for j in 3:
		m.box(Vector3(0, -0.1, -1.0 + j * 1.0), Vector3(2.8, 0.2, 0.12), Color(0.3, 0.24, 0.22))
	k.flag_barrier(at + Vector3(0, -0.15, 0), Vector3(2.9, 0.3, 2.9), 0.0, flag, m, "char")


# --- 1F ---------------------------------------------------------------------------

func _f1(k) -> void:
	k.examine(Vector3(-3.0, 0.0, 18.8), PI, [{"text": "Cut into the black stone over the way in, in letters taller than you:\n*WHAT BURNS, BURNS OUT. WHAT IS KEPT, IS KEPT FROM YOU.*\n-S.", "instant": true}])
	for z in [21.0, 27.0]:
		for sx in [-1.0, 1.0]:
			k.pillar(sx * 4.6, z, 6.0, 0.45, false, "stone", 0.0)
	# The great forge: anvils, braziers, and the north door frozen shut in
	# rime-ice.
	for p in [Vector2(-8.0, 6.0), Vector2(8.0, 6.0), Vector2(-8.0, -2.0), Vector2(8.0, -2.0)]:
		k.display_mesh("res://assets/models/anvil_mesh.tres", Transform3D(Basis(Vector3.UP, p.x * 0.1).scaled(Vector3.ONE * 2.2), Vector3(p.x, 0.0, p.y)))
		k.col_box(Vector3(p.x, 0.75, p.y), Vector3(1.4, 1.5, 0.7), p.x * 0.1)
	k.burnable("rime", 0.0, -12.2, 0.0, D + ":forge_rime", Vector3(3.6, 3.6, 1.0), 0.0)
	k.examine(Vector3(-3.0, 0.0, -7.0), PI, [{"text": "The north door is sealed in a slab of blue-white rime. It is so cold it smokes, even here in the forge's heat.\nNo blade, no hammer will mark it. Only fire hot enough to melt a goddess's frost.", "instant": true}])
	_fires(k, "forge")
	# The bellows: fire jets breathing across the room; two cold torches.
	for i in 3:
		_jet(k, Vector3(-21.0, 1.0, -6.0 + i * 6.0), -PI / 2.0, {"length": 18.0, "period": 3.0, "burn": 1.4, "phase": i * 1.0})
	k.torch(-37.0, -7.0, true, "", 0.0)
	k.torch(-37.0, 7.0, false, D + ":bellows_t1", 0.0)
	k.torch(-24.0, 7.5, false, D + ":bellows_t2", 0.0)
	k.flag_all([D + ":bellows_t1", D + ":bellows_t2"], D + ":bellows_lit")
	k.chest(-37.0, 0.0, PI / 2.0, "small_key", false, D + ":chest_key1", D + ":bellows_lit", 0.0)
	k.examine(Vector3(-22.0, 0.0, -8.6), -PI / 2.0, [{"text": "A smith's note, burnt at the edges:\n*THE BELLOWS FIRE WILL CATCH ON AN ARROW. MIND THE JETS.*", "instant": true}])
	# The anvils: the Map, and a great stone over the way down.
	k.chest(36.0, -6.0, -PI / 2.0, "map", false, D + ":chest_map", "", 0.0)
	var hole := ladder_hole(26.0, 6.0, Vector2(1, 0))
	k.great_stone(hole.get_center().x, hole.get_center().y, PI * 0.5, D + ":anvil_stone", 0.0, 1.0)
	k.examine(Vector3(34.0, 0.0, 8.0), -PI * 0.75, [{"text": "Scratches on the floor round the great stone, as if it has been dragged here, and dragged back, many times.", "instant": true}])
	_fires(k, "anvils")
	# The smelter, behind the rime: the smiths' strongbox.
	k.chest(-6.0, -42.0, 0.0, "rupee_gold", false, D + ":chest_smelter", "", 0.0)
	k.chest(6.0, -42.0, 0.0, "bombs_10", false, D + ":chest_smelter_b", "", 0.0)
	for p in [Vector2(-8.0, -30.0), Vector2(8.0, -30.0)]:
		k.display_mesh("res://assets/models/anvil_mesh.tres", Transform3D(Basis().scaled(Vector3.ONE * 2.0), Vector3(p.x, 0.0, p.y)))
		k.col_box(Vector3(p.x, 0.7, p.y), Vector3(1.3, 1.4, 0.6))
	_fires(k, "smelter")


# --- B1 ---------------------------------------------------------------------------

func _b1(k) -> void:
	var y := fy(2)
	# The quench: a pool of dark water, ladder up.
	var qc := room_center("quench")
	k.water_plane(Rect2(qc.x - 2.0, qc.y - 8.0, 12.0, 8.0), y + 0.05, Color(0.2, 0.26, 0.3, 0.8))
	_fires(k, "quench")
	# The foundry: a fight. Shutters until it is won; locked north.
	k.shutter(13.4, 0.0, PI / 2.0, "foundry", y)
	k.shutter(-13.4, 0.0, PI / 2.0, "foundry", y)
	k.shutter(0.0, 11.4, 0.0, "foundry", y)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key1", false, y)
	for p in [Vector2(-9.0, -7.0), Vector2(9.0, -7.0), Vector2(-9.0, 7.0), Vector2(9.0, 7.0)]:
		k.pillar(p.x, p.y, 6.5, 0.6, false, "stone", y)
	_fires(k, "foundry")
	# The moulds: the Vault Warden; beaten, the Ember Rod.
	k.shutter(-20.6, 0.0, PI / 2.0, "moulds", y)
	var mc := room_center("moulds")
	k.chest(mc.x - 6.0, mc.y, PI / 2.0, "ember_rod", true, D + ":chest_ember", D + ":moulds_clear", y)
	for z in [-7.0, 7.0]:
		k.statue(mc.x - 8.4, z, PI * 0.5, 1.0, "stone", y)
	_fires(k, "moulds")
	# The kiln: four cold torches round the floor grate.
	var flags: Array = []
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var f := D + ":kiln_t%d" % i
		k.torch(KILN_HOLE.x + cos(a) * 3.2, KILN_HOLE.z + sin(a) * 3.2, false, f, y)
		flags.append(f)
	k.flag_all(flags, D + ":kiln_lit")
	_cover(k, KILN_HOLE, D + ":kiln_lit")
	k.examine(Vector3(-5.5, y, 28.0), -PI / 2.0, [{"text": "The kiln's four torches are cold, and no common flame will reach them all from here.\n*FIRE FOR THE FIRE-CHUTE.*", "instant": true}])
	# The ore room: thorns over the Compass; Key 2 up on a ledge, the Hookshot up.
	k.burnable("thorns", -7.5, -32.0, PI * 0.5, D + ":ore_thorns", Vector3(5.2, 2.8, 1.0), y)
	# (Too sheer to climb: over them is no way round the thorns. Beta 1.5.1.)
	k.block(Vector3(-9.0, y + 1.5, -29.2), Vector3(4.0, 3.0, 0.6), 0.0, "stone", BASALT).set_meta("no_climb", true)
	k.block(Vector3(-9.0, y + 1.5, -34.8), Vector3(4.0, 3.0, 0.6), 0.0, "stone", BASALT).set_meta("no_climb", true)
	k.chest(-9.6, -32.0, PI / 2.0, "compass", false, D + ":chest_compass", "", y)
	k.block(Vector3(3.0, y + 1.9, -43.5), Vector3(8.0, 3.8, 3.0), 0.0, "stone", BASALT.darkened(0.2))
	k.chest(3.0, -43.5, 0.0, "small_key", false, D + ":chest_key2", "", y + 3.8)
	k.hook_target(Vector3(5.5, y + 5.6, -45.9), 0.0)
	var bm = k._tmp(false)
	bm.prism(Vector3(1.0, y + 4.6, -44.5), 0.5, Vector3(1.0, y + 5.4, -44.5), 0.3, 8, EMBER)
	k.merge(bm, "glow")
	_fires(k, "ore")


# --- B2 ---------------------------------------------------------------------------

func _b2(k) -> void:
	var y := fy(1)
	k.pot(4.5, 28.5, "magic_small", false, y)
	k.pot(-4.5, 28.5, "arrows_10", false, y)
	# The frost hall: walls of rime across it; melt a way through.
	# Two walls of ice right across the hall, each with one span of rime.
	for seg in [[-14.0, 3.2, 4.0], [6.8, 14.0, 4.0], [-14.0, -6.8, -4.0], [-3.2, 14.0, -4.0]]:
		var xa: float = seg[0]
		var xb: float = seg[1]
		var wz: float = seg[2]
		# Glassy ice: no handhold to climb over the rime by (Beta 1.5.1).
		k.block(Vector3((xa + xb) * 0.5, y + 1.6, wz), Vector3(xb - xa, 3.2, 1.0), 0.0, "ice", FROST).set_meta("no_climb", true)
	k.burnable("rime", 5.0, 4.0, 0.0, D + ":frost_rime_a", Vector3(3.6, 3.2, 1.0), y)
	k.burnable("rime", -5.0, -4.0, 0.0, D + ":frost_rime_b", Vector3(3.6, 3.2, 1.0), y)
	k.locked_door(0.0, -12.4, 0.0, D + ":door_key2", false, y)
	# The wardens: three torches cased in rime; all three lit -> the Boss Key.
	var flags: Array = []
	var wc := room_center("wardens")
	for i in 3:
		var at := Vector2(wc.x - 6.0, wc.y - 6.0 + i * 6.0)
		var f := D + ":warden_t%d" % i
		k.torch(at.x, at.y, false, f, y)
		k.burnable("rime", at.x, at.y, 0.0, D + ":warden_rime_%d" % i, Vector3(1.4, 2.0, 1.4), y)
		flags.append(f)
	k.flag_all(flags, D + ":wardens_lit")
	k.chest(wc.x + 5.0, wc.y, -PI / 2.0, "boss_key", true, D + ":chest_boss_key", D + ":wardens_lit", y)
	k.examine(Vector3(wc.x + 8.0, y, wc.y + 6.0), -PI * 0.75, [{"text": "Serielye's wardens froze the vault's fires one by one, so the Gauntlet could never be forged again.\n*THREE FIRES KEEP THE CRADLE'S KEY.*", "instant": true}])
	# The forgefire: jets in turn across the way to a chest.
	for i in 3:
		_jet(k, Vector3(24.0, y + 1.0, -6.0 + i * 6.0), -PI / 2.0, {"length": 16.0, "period": 2.6, "burn": 1.2, "phase": i * 0.85})
	k.chest(37.0, 0.0, -PI / 2.0, "rupee_purple", false, D + ":chest_forgefire", "", y)
	_fires(k, "forgefire")
	# The vent: a ledge over the floor seal (the Down Thrust).
	k.technique_target("seal", SEAL.x, SEAL.y, D + ":vent_seal", y, {"size": 2.6})
	k.block(Vector3(3.8, y + 1.5, SEAL.y), Vector3(5.0, 3.0, 8.0), 0.0, "stone", BASALT)
	k.stairs(3.8, SEAL.y + 6.6, 0.0, 3.0, 2.6, 3.0, "stone", y)
	k.examine(Vector3(-2.2, y, SEAL.y + 2.2), PI * 0.75, [{"text": "The floor here is a seal of cracked basalt, set with a red stone. It rings hollow.\n*ONLY A BLOW FROM ABOVE.*", "instant": true}])
	_fires(k, "vent")


# --- B3 ---------------------------------------------------------------------------

func _b3(k) -> void:
	var y := fy(0)
	_fires(k, "nave")
	k.pot(8.0, -28.0, "heart", false, y)
	k.pot(8.0, -29.2, "magic_small", false, y)
	k.pot(-8.0, -42.0, "arrows_10", false, y)
	k.locked_door(0.0, -46.4, 0.0, D + ":boss_door", true, y)
	var rb: Rect2 = rooms.boss.r
	var bc := room_center("boss")
	k.shutter(0.0, rb.end.y - 0.6, 0.0, "boss", y)
	for i in 8:
		var a := TAU * i / 8.0
		k.pillar(bc.x + cos(a) * 14.5, bc.y + sin(a) * 14.5, 6.5, 0.6, i % 3 == 1, "stone", y)
	var clear := D + ":boss_clear"
	k.heart_container(bc.x, bc.y + 9.0, clear, D + ":heart_container", y)
	k.flag_bars(0.0, rb.position.y - 0.6, 0.0, clear, y)
	# The cradle: the old anvil where the Gauntlet was first kept.
	var hc := room_center("heart")
	k.platform(hc.x, hc.y - 3.0, Vector2(6.0, 6.0), y + 0.6, "stone", BASALT.darkened(0.3))
	k.display_mesh("res://assets/models/anvil_mesh.tres", Transform3D(Basis().scaled(Vector3.ONE * 2.6), Vector3(hc.x, y + 0.6, hc.y - 3.0)))
	k.col_box(Vector3(hc.x, y + 1.5, hc.y - 3.0), Vector3(1.8, 1.8, 1.0))
	k.mark("cs_vault_hero", Vector3(hc.x, y, hc.y + 5.0), 0.0)
	k.mark("cs_vault_anvil", Vector3(hc.x, y + 0.6, hc.y - 3.0))
	k.mark("cs_vault_cam", Vector3(hc.x + 6.0, y + 3.0, hc.y + 6.0))
	k.story_trigger("vault_heart", Rect2(hc.x - 8.0, hc.y + 3.0, 16.0, 6.0), y, "ch5:cinder_done", clear)
	k.blue_warp(hc.x, hc.y + 8.0, "ch5:cinder_done", "cinderhold", "from_cinder_vault", y)
	_fires(k, "heart")


func populate(k) -> void:
	var b1 := fy(2)
	var b2 := fy(1)
	var b3 := fy(0)
	k.enemy("charred_stalfos", -4.0, 2.0, 0.0, {}, 0.0)
	k.enemy("fire_keese", 6.0, -4.0, 0.0, {}, 4.0)
	k.enemy("cinderling", -30.0, 4.0, 0.0, {}, 0.0)
	k.enemy("cinderling", 30.0, 2.0, 0.0, {}, 0.0)
	k.enemy("fire_keese", 28.0, -6.0, 0.0, {}, 4.0)
	k.enemy("charred_stalfos", 0.0, -36.0, 0.0, {}, 0.0)
	k.enemy("cinderling", 28.0, -4.0, 0.0, {}, b1)
	k.enemy("ember_knight", -5.0, -3.0, PI, {"room": "foundry"}, b1)
	k.enemy("cinderling", 5.0, -3.0, PI, {"room": "foundry"}, b1)
	k.enemy("cinderling", 0.0, 5.0, PI, {"room": "foundry"}, b1)
	k.enemy("vault_warden", -30.0, 0.0, PI / 2.0, {"room": "moulds"}, b1)
	k.enemy("fire_keese", 0.0, 24.0, 0.0, {}, b1 + 4.0)
	k.enemy("charred_stalfos", 4.0, -32.0, 0.0, {}, b1)
	k.enemy("ice_keese", 0.0, 24.0, 0.0, {}, b2 + 4.0)
	k.enemy("freezard", -8.0, 8.0, 0.0, {}, b2)
	k.enemy("freezard", 8.0, -8.0, 0.0, {}, b2)
	k.enemy("frost_stalfos", 0.0, 0.0, 0.0, {}, b2)
	k.enemy("ice_keese", -30.0, 6.0, 0.0, {}, b2 + 4.0)
	k.enemy("frost_stalfos", -26.0, -4.0, 0.0, {}, b2)
	k.enemy("cinderling", 30.0, -6.0, 0.0, {}, b2)
	k.enemy("ember_knight", 0.0, -32.0, 0.0, {}, b2)
	k.enemy("ember_knight", 0.0, -34.0, 0.0, {}, b3)
	k.enemy("magmaw", 0.0, -70.0, 0.0, {"room": "boss"}, b3)
