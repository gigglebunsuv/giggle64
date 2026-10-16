extends "res://tools/world/regions/castle_town.gd"
## Old Castle Town after Firebuns III is sealed (the end of Chapter IV): the
## people come home and rebuild. Marigold runs the Rebuilding Fund from a
## board in the square; each district paid for (RebuildFund, flags
## "rebuild:<district>") clears its rubble and scaffolding and brings its
## people back:
##   market    the stalls swept and mended, Tansy and her cups back
##   fountain  the fountain running again
##   homes     the houses' scaffolds down, families home (Posy and Pepper)
##   armory    Pink's Armory open for business again
## Until then each district shows the fire's damage. The castle itself is
## shut while it is rebuilt.


## Years later (castle_town_restored): every district long finished, so no
## scaffolds, rubble, fund board or castle notice at all.
var finished := false


func setup() -> void:
	super.setup()
	id = "castle_town_rebuilt"
	link_id = "castle_town"
	seed_value = 3131
	armory_door = false


func ground_color(x: float, z: float, h: float, r: RandomNumberGenerator) -> Color:
	var c := super.ground_color(x, z, h, r)
	# Soot still in the cracks: the cobbles are being scrubbed.
	return c.lerp(CHAR, clampf(noise.get_noise_2d(x * 2.0, z * 2.0) * 0.4, 0.0, 0.25))


## Scenery that is there until a district is rebuilt: a MeshKit shown while
## `district` is not paid for, solid (FlagBarrier) if `solid` is given.
func _until(k, district: String, mk, mat := "char", solid := Rect2(), y := 0.0) -> void:
	if finished:
		return
	var flag := "rebuild:" + district
	k.flag_props("", mk, mat, flag)
	if solid.size != Vector2.ZERO:
		k.flag_barrier(Vector3(solid.get_center().x, y + 1.5, solid.get_center().y), Vector3(solid.size.x, 3.0, solid.size.y), 0.0, flag)


func _scaffold(m, x: float, z: float, yaw: float, w: float, hh: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var base := Vector3(x, 0, z)
	var pole := Color.html("8a6a44")
	for i in 3:
		var t := -w * 0.5 + i * w * 0.5
		m.prism(base + basis * Vector3(t, 0, 0), 0.06, base + basis * Vector3(t, hh, 0), 0.06, 5, pole)
	for y in [hh * 0.4, hh * 0.85]:
		m.box(base + basis * Vector3(0, y, 0), Vector3(w + 0.2, 0.12, 0.6), pole.darkened(0.15))


func build(k) -> void:
	super.build(k)
	var r: RandomNumberGenerator = k.rng
	# The market: rubble and charred stalls until it is rebuilt.
	var mk = k._tmp()
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		var p := SQUARE + Vector2(cos(a), sin(a)) * 11.5
		mk.icosa(Vector3(p.x, k.h(p.x, p.y) + 0.3, p.y + 1.2), Vector3(1.0, 0.5, 0.8), 0.25, Color.html("3a3430"))
		mk.box(Vector3(p.x + 0.8, k.h(p.x, p.y) + 0.15, p.y - 1.4), Vector3(1.6, 0.3, 0.4), Color.html("2a2420"))
	_until(k, "market", mk)
	# The fountain: dry, its basin full of ash.
	var fk = k._tmp()
	fk.prism(Vector3(SQUARE.x, k.h(SQUARE.x, SQUARE.y) + 0.55, SQUARE.y), 4.1, Vector3(SQUARE.x, k.h(SQUARE.x, SQUARE.y) + 0.62, SQUARE.y), 4.1, 16, Color.html("4a4440"))
	fk.icosa(Vector3(SQUARE.x + 1.5, k.h(SQUARE.x, SQUARE.y) + 0.8, SQUARE.y - 1.0), Vector3(0.8, 0.4, 0.8), 0.2, Color.html("3a3430"))
	_until(k, "fountain", fk)
	# The homes: scaffolding up the house fronts on the main street.
	var hk = k._tmp()
	for z in [36.0, 29.0, 22.0]:
		for sx in [-1.0, 1.0]:
			_scaffold(hk, sx * 5.6, z, PI * 0.5, 5.0, 6.0)
	for z in [-21.0, -28.0]:
		for sx in [-1.0, 1.0]:
			_scaffold(hk, sx * 5.6, z, PI * 0.5, 5.0, 6.0)
	_until(k, "homes", hk, "wood")
	# The armory: boarded up, scaffolding round its front.
	var ak = k._tmp()
	var fx := -42.0 + 7.0
	_scaffold(ak, fx + 0.6, -21.0, PI * 0.5, 9.0, 7.5)
	for i in 3:
		ak.box(Vector3(fx + 0.25, k.h(fx, -21.0) + 0.6 + i * 0.7, -21.0), Vector3(0.1, 0.25, 1.8), Color.html("6a5038"))
	_until(k, "armory", ak, "wood", Rect2(fx, -22.0, 0.8, 2.0), k.h(fx, -21.0))
	# The rebuilding fund's board by the fountain, and the castle shut.
	var board := Vector2(-7.0, 15.0)
	var by: float = k.h(board.x, board.y)
	var bk = k._tmp()
	bk.box(Vector3(board.x, by + 1.6, board.y), Vector3(2.2, 1.4, 0.12), Color.html("6a4a2a"))
	bk.box(Vector3(board.x, by + 1.6, board.y - 0.07), Vector3(2.0, 1.2, 0.02), Color.html("e8dcc0"))
	for sx in [-1.0, 1.0]:
		bk.box(Vector3(board.x + sx * 0.9, by + 0.8, board.y), Vector3(0.12, 1.6, 0.12), Color.html("5a3a20"))
	if finished:
		return
	k.merge(bk, "wood")
	k.col_box(Vector3(board.x, by + 1.2, board.y), Vector3(2.2, 2.4, 0.3))
	k.examine(Vector3(board.x, by, board.y - 0.4), 0.0, [], "res://scripts/npc/rebuild_lines.gd", "board", 1.8)
	if finished:
		return
	var cy: float = k.h(0, CASTLE_Z)
	k.examine(Vector3(0, cy, CASTLE_Z + 3.0), PI, [{"text": "A notice is nailed across the old seal:
*THE CASTLE IS CLOSED WHILE IT IS MADE SAFE. BY ORDER OF THE HAVEN GUARD.*
Underneath, someone has drawn a little knight with a very big sword.", "instant": true}])


func populate(k) -> void:
	k.signpost(-4.0, 36, Vector2(0, 32), "*Old Castle Town*\nWelcome home!\n\nThe Rebuilding Fund's board\nis by the fountain.")
	for p in [Vector2(-7.0, 11.8), Vector2(11.0, -9.0), Vector2(23.0, 11.0), Vector2(-20.0, 11.0)]:
		k.pot(p.x, p.y)
	k.npc("Marigold", "res://assets/models/marigold.tscn", "res://scripts/npc/rebuild_lines.gd", -9.0, 16.5, PI * 0.8)
	k.npc("Captain Rowena", "res://assets/models/rowena.tscn", "res://scripts/npc/rebuild_lines.gd", 3.0, 37.0, PI)
	# Back with the market: Tansy and her cups.
	var to_square := (SQUARE - Vector2(8.5, 7.5)).normalized()
	var cups = k.cup_game(8.5, 7.5, k.yaw_of(to_square))
	cups.set("show_flag", "rebuild:market")
	var behind := Vector2(8.5, 7.5) - to_square * 0.75
	k.npc("Tansy", "res://assets/models/tansy.tscn", "res://scripts/npc/tansy_lines.gd", behind.x, behind.y, k.yaw_of(to_square), INF, {"show": "rebuild:market"})
	_market(k, "rebuild:market")
	# Back with the homes: Posy and Pepper.
	k.npc("Posy", "res://assets/models/posy.tscn", "res://scripts/npc/rebuild_lines.gd", 8.0, 30.0, -PI * 0.5, INF, {"show": "rebuild:homes"})
	k.npc("Haven Folk", "res://assets/models/haven_soldier.tscn", "res://scripts/npc/rebuild_lines.gd", -8.0, -24.0, PI * 0.5, INF, {"show": "rebuild:homes"})
	# Pink's Armory: open again once it is rebuilt.
	var fx := -42.0 + 7.0
	var gy: float = k.h(fx + 0.5, -21.0)
	k.door_link(Vector3(fx + 0.06, gy, -21.0), PI * 1.5, 1.4, 2.4, "armory", "from_castle_town", Color(1, 1, 1), "rebuild:armory", "",
		"The armory is boarded up while it is rebuilt.\nA note in Pink's writing:\n*BACK SOON! BIGGER! WITH A DOOR THAT LOCKS!*")
	k.entrance("from_armory", fx + 1.8, -21.0, -PI * 0.5)
