extends RefCounted
## Builds the meshes of small things the hero picks up, breaks, opens or
## presses: rupees, hearts, keys, the boomerang, pots, shrubs, signs, chests,
## dungeon doors and switches, and the blue warp. All saved as .tres meshes in
## res://assets/models/ (the scripts in scripts/items/ and scripts/dungeon/
## load them by name).

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 500


func run(materials: Dictionary) -> void:
	M = materials
	_rupees()
	_hearts()
	_keys()
	_dungeon_items()
	_boomerang()
	_sword_beam()
	_pots()
	_shrub()
	_lift_rock()
	_coral_crust()
	_sign()
	_chests()
	_doors()
	_switches()
	_warp()


func _c(h: String) -> Color:
	return Color.html(h)


func _k(textured := false) -> MeshKit:
	_seed += 1
	var k := MeshKit.new(_seed)
	k.textured = textured
	return k


func _save(res: Resource, file: String) -> void:
	var err := ResourceSaver.save(res, MODEL_DIR + file)
	if err != OK:
		push_error("Failed to save %s: %s" % [file, err])


# --- Rupees and hearts -------------------------------------------------------

## Coins (Beta 1.6.0; they were OoT's hexagonal rupee crystals): a thick
## twelve-sided disc of colored metal standing on edge, a raised rim round a
## sunken field on each face, and a stamped diamond in the middle, shaded so
## it glints as it spins. The meshes keep their old file names.
func _rupees() -> void:
	for kind in [["green", "3ad04a"], ["blue", "3a6af0"], ["red", "e83a3a"]]:
		var k := _k()
		build_coin(k, _c(kind[1]))
		_save(k.build(M.glow), "rupee_%s_mesh.tres" % kind[0])


## Builds one coin into `k` (also used by gen_ch4_items for the purple and gold).
static func build_coin(k: MeshKit, col: Color) -> void:
	var rim := col.darkened(0.2)
	var field := col
	var stamp := col.lightened(0.35)
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	# The rim, then a lower field on each face (the prism runs along Y = the
	# coin's thickness once turned), then the diamond standing proud of it.
	k.prism(Vector3(0, -0.022, 0), 0.14, Vector3(0, 0.022, 0), 0.14, 12, rim, PI / 12.0)
	for sy in [-1.0, 1.0]:
		k.prism(Vector3(0, 0.022 * sy, 0), 0.105, Vector3(0, 0.026 * sy, 0), 0.1, 12, field, PI / 12.0)
		k.prism(Vector3(0, 0.026 * sy, 0), 0.05, Vector3(0, 0.034 * sy, 0), 0.03, 4, stamp)
	k.pop()


## The recovery heart: two lobes over a point, a little thick. The heart
## container is the same shape, larger and deeper red.
func _hearts() -> void:
	for spec in [["heart_mesh.tres", 1.0, "e8202a"], ["heart_container_mesh.tres", 2.2, "c8101e"]]:
		var s: float = spec[1]
		var col := _c(spec[2])
		var k := _k()
		k.shade_jitter = 0.0
		for sx in [-1.0, 1.0]:
			k.icosa(Vector3(0.07 * sx, 0.05, 0) * s, Vector3(0.085, 0.085, 0.05) * s, 0.0, col, true)
		k.push(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.03, 0) * s))
		k.prism(Vector3.ZERO, 0.13 * s, Vector3(0, 0.17 * s, 0), 0.0, 8, col.darkened(0.1))
		k.pop()
		k.smooth_normals(80.0)
		_save(k.build(M.char), spec[0])


# --- Keys, map and compass ------------------------------------------------------

func _keys() -> void:
	# Small key: a silver ring, a shaft and two teeth (vertical, head up).
	var k := _k()
	var steel := _c("c4ccd8")
	for i in 8:
		var a := TAU * i / 8.0
		k.box(Vector3(cos(a) * 0.055, 0.14 + sin(a) * 0.055, 0), Vector3(0.035, 0.035, 0.03), steel)
	k.box(Vector3(0, -0.02, 0), Vector3(0.03, 0.26, 0.03), steel)
	k.box(Vector3(0.035, -0.11, 0), Vector3(0.05, 0.03, 0.03), steel.darkened(0.1))
	k.box(Vector3(0.03, -0.06, 0), Vector3(0.04, 0.025, 0.03), steel.darkened(0.1))
	k.smooth_normals(30.0)
	_save(k.build(M.char), "small_key_mesh.tres")
	# Boss key: big and golden, a red gem in its ornate head.
	var b := _k()
	var gold := _c("e8b830")
	for i in 10:
		var a := TAU * i / 10.0
		b.box(Vector3(cos(a) * 0.1, 0.24 + sin(a) * 0.1, 0), Vector3(0.06, 0.06, 0.05), gold)
	for sx in [-1.0, 1.0]:
		b.prism(Vector3(0.16 * sx, 0.24, 0), 0.04, Vector3(0.24 * sx, 0.24, 0), 0.0, 4, gold.darkened(0.1))
	b.icosa(Vector3(0, 0.24, 0), Vector3(0.045, 0.045, 0.03), 0.0, _c("e02030"))
	b.box(Vector3(0, -0.04, 0), Vector3(0.05, 0.42, 0.05), gold)
	b.box(Vector3(0.06, -0.2, 0), Vector3(0.08, 0.05, 0.05), gold.darkened(0.15))
	b.box(Vector3(0.05, -0.12, 0), Vector3(0.06, 0.04, 0.05), gold.darkened(0.15))
	b.smooth_normals(30.0)
	_save(b.build(M.char), "boss_key_mesh.tres")


func _dungeon_items() -> void:
	# Dungeon map: a rolled parchment tied with a red ribbon.
	var m := _k()
	m.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
	m.prism(Vector3(0, -0.2, 0), 0.07, Vector3(0, 0.2, 0), 0.07, 8, _c("e8dcb0"))
	m.prism(Vector3(0, -0.03, 0), 0.075, Vector3(0, 0.03, 0), 0.075, 8, _c("c02028"))
	m.pop()
	m.smooth_normals(60.0)
	_save(m.build(M.char), "map_mesh.tres")
	# Compass: a brass disc with a red and white needle.
	var c := _k()
	c.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	c.prism(Vector3(0, -0.03, 0), 0.16, Vector3(0, 0.03, 0), 0.16, 12, _c("c8a040"))
	c.prism(Vector3(0, -0.035, 0), 0.13, Vector3(0, -0.031, 0), 0.13, 12, _c("f0ecd8"))
	c.pop()
	c.face([Vector3(-0.025, 0, -0.04), Vector3(0.025, 0, -0.04), Vector3(0, 0.12, -0.041)], _c("e02020"), Vector3(0, 0, -1))
	c.face([Vector3(-0.025, 0, -0.04), Vector3(0.025, 0, -0.04), Vector3(0, -0.12, -0.041)], _c("f8f8f8"), Vector3(0, 0, -1))
	_save(c.build(M.char), "compass_mesh.tres")


# --- The boomerang ------------------------------------------------------------

## The Lake Shrine's boomerang: sea-glass blue arms bound in gold, a pearl at
## the elbow. Flat in the XZ plane (it spins about Y), the elbow at the origin,
## the arms reaching toward -Z.
func _boomerang() -> void:
	var k := _k()
	var glass := _c("3ab8b0")
	var gold := _c("e8c050")
	for sx in [-1.0, 1.0]:
		var tip := Vector3(0.24 * sx, 0, -0.17)
		var dir := tip.normalized()
		var side := Vector3(-dir.z, 0, dir.x) * 0.05
		var pts := [Vector3(0, -0.02, 0) - side, Vector3(0, -0.02, 0) + side, tip + Vector3(0, -0.015, 0) + side * 0.6, tip + Vector3(0, -0.015, 0) - side * 0.6,
			Vector3(0, 0.02, 0) - side, Vector3(0, 0.02, 0) + side, tip + Vector3(0, 0.015, 0) + side * 0.6, tip + Vector3(0, 0.015, 0) - side * 0.6]
		k.hexa(pts, glass)
		k.box(tip * 0.98 + Vector3(0, 0, 0), Vector3(0.05, 0.035, 0.05), gold)
	k.prism(Vector3(0, -0.03, 0.01), 0.06, Vector3(0, 0.03, 0.01), 0.06, 8, gold)
	k.icosa(Vector3(0, 0.035, 0.01), Vector3(0.035, 0.025, 0.035), 0.0, _c("f4f0ff"))
	k.smooth_normals(30.0)
	_save(k.build(M.char), "boomerang_mesh.tres")


## The Bun Sword's beam: a flat golden crescent bowed forward (-Z), bright
## in the middle and fading to orange at the horns. Unshaded (glow).
func _sword_beam() -> void:
	var k := _k()
	var n := 10
	for i in n:
		var a0 := deg_to_rad(-75.0 + 150.0 * i / n)
		var a1 := deg_to_rad(-75.0 + 150.0 * (i + 1) / n)
		var w0 := 0.16 * cos(a0 * 0.9)
		var w1 := 0.16 * cos(a1 * 0.9)
		var o0 := Vector3(sin(a0), 0, -cos(a0)) * 0.55
		var o1 := Vector3(sin(a1), 0, -cos(a1)) * 0.55
		var i0 := Vector3(sin(a0), 0, -cos(a0)) * (0.55 - w0) + Vector3(0, 0, 0.12)
		var i1 := Vector3(sin(a1), 0, -cos(a1)) * (0.55 - w1) + Vector3(0, 0, 0.12)
		var t := absf((i + 0.5) / n - 0.5) * 2.0
		var col := _c("fff6c0").lerp(_c("f0a020"), t)
		var hgt := 0.035 * (1.0 - t * 0.6)
		k.hexa([i0 - Vector3(0, hgt, 0), i1 - Vector3(0, hgt, 0), o1 - Vector3(0, hgt, 0), o0 - Vector3(0, hgt, 0),
			i0 + Vector3(0, hgt, 0), i1 + Vector3(0, hgt, 0), o1 + Vector3(0, hgt, 0), o0 + Vector3(0, hgt, 0)], col)
	_save(k.build(M.glow), "sword_beam_mesh.tres")


# --- Pots ---------------------------------------------------------------------

## OoT's clay pot (Obj_Tsubo): a round belly, a narrow neck and a lip, about
## 0.6 m tall. The shrine's pots are glazed blue. Shards for when it breaks.
func _pots() -> void:
	for spec in [["pot_mesh.tres", "b0683a", "8a4a28"], ["pot_blue_mesh.tres", "4a82b8", "2e5a8a"]]:
		var col := _c(spec[1])
		var band := _c(spec[2])
		var k := _k()
		k.loft([
			[0.0, 0.0, 0.0, col.darkened(0.2)], [0.01, 0.17, 0.17, col.darkened(0.15)], [0.12, 0.27, 0.27, col],
			[0.24, 0.3, 0.3, band], [0.3, 0.29, 0.29, band], [0.4, 0.22, 0.22, col], [0.5, 0.14, 0.14, col.darkened(0.1)],
			[0.54, 0.17, 0.17, col.lightened(0.1)], [0.58, 0.16, 0.16, col.lightened(0.1)], [0.58, 0.11, 0.11, _c("1a120c")],
		], 10)
		k.smooth_normals(70.0)
		_save(k.build(M.char), spec[0])
	var s := _k()
	s.icosa(Vector3.ZERO, Vector3(0.07, 0.03, 0.06), 0.3, _c("a8643a"))
	_save(s.build(M.char), "shard_mesh.tres")


# --- Shrubs -------------------------------------------------------------------

## OoT's cuttable shrub (gCuttableShrubStalkDL / TipDL): a tuft of broad
## leaves round a short stalk, about 0.55 m tall. Regions tint it (dry in the
## desert, frosted on the peak). A stub stays while it regrows, and leaves fly
## when it is cut.
func _shrub() -> void:
	var k := _k(true)
	var green := Color(1, 1, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	k.prism(Vector3(0, 0, 0), 0.08, Vector3(0, 0.2, 0), 0.06, 5, _c("a0b880"))
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var tilt := rng.randf_range(0.35, 0.8)
		var base := Vector3(0, 0.08, 0)
		var tip := base + d * 0.42 + Vector3(0, 0.55 - tilt * 0.3, 0)
		var side := Vector3(-d.z, 0, d.x) * 0.13
		var mid := base.lerp(tip, 0.55)
		k.face_dir([base, mid + side, tip, mid - side], green * rng.randf_range(0.85, 1.05), (d + Vector3.UP).normalized())
		k.face_dir([base, mid - side, tip, mid + side], green * 0.8, -(d + Vector3.UP).normalized())
	k.icosa(Vector3(0, 0.32, 0), Vector3(0.24, 0.2, 0.24), 0.2, green * 0.95)
	_save(k.build(M.leaves), "shrub_mesh.tres")
	var stub := _k(true)
	for i in 5:
		var a := TAU * i / 5.0
		var p := Vector3(cos(a), 0, sin(a)) * 0.08
		stub.prism(p, 0.03, p * 1.4 + Vector3(0, 0.12, 0), 0.02, 4, Color(0.9, 0.95, 0.8))
	_save(stub.build(M.leaves), "shrub_stub_mesh.tres")
	var leaf := _k(true)
	leaf.face_dir([Vector3(0, 0, -0.08), Vector3(0.04, 0, 0), Vector3(0, 0, 0.08), Vector3(-0.04, 0, 0)], Color(1, 1, 1), Vector3.UP)
	leaf.face_dir([Vector3(0, -0.005, -0.08), Vector3(-0.04, -0.005, 0), Vector3(0, -0.005, 0.08), Vector3(0.04, -0.005, 0)], Color(0.8, 0.8, 0.8), Vector3.DOWN)
	_save(leaf.build(M.leaves), "leaf_mesh.tres")


# --- Rocks --------------------------------------------------------------------

## OoT's small liftable rock (En_Ishi ROCK_SMALL, gFieldSmallRockOpaDL): a lumpy
## gray stone about 0.5 m across and 0.4 m tall, resting on its flat underside.
## Chips fly when a thrown one breaks.
func _lift_rock() -> void:
	var k := _k(true)
	k.icosa(Vector3(0, 0.19, 0), Vector3(0.27, 0.21, 0.24), 0.18, Color(1, 1, 1))
	k.icosa(Vector3(0.08, 0.3, -0.04), Vector3(0.14, 0.1, 0.13), 0.2, Color(0.92, 0.92, 0.9))
	_save(k.build(M.rock), "lift_rock_mesh.tres")
	var chip := _k(true)
	chip.icosa(Vector3.ZERO, Vector3(0.07, 0.05, 0.06), 0.3, Color(1, 1, 1))
	_save(chip.build(M.rock), "rock_chip_mesh.tres")


## A mound of brittle coral (BrittleCrust) about 1.6 m across and 1.3 m tall:
## pink and white lumps with stubby branches. Only a thrown pot or rock breaks it.
func _coral_crust() -> void:
	var k := _k()
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var cols := [_c("e8a090"), _c("f0c8b0"), _c("d87868"), _c("f4e4d0")]
	k.icosa(Vector3(0, 0.5, 0), Vector3(0.8, 0.6, 0.7), 0.15, cols[0])
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var p := Vector3(cos(a) * 0.55, rng.randf_range(0.25, 0.75), sin(a) * 0.48)
		k.icosa(p, Vector3.ONE * rng.randf_range(0.22, 0.36), 0.25, cols[i % 4])
	for i in 7:
		var a := TAU * i / 7.0 + 0.3
		var base := Vector3(cos(a) * 0.4, 0.8, sin(a) * 0.35)
		var tip := base + Vector3(cos(a) * 0.25, rng.randf_range(0.3, 0.55), sin(a) * 0.25)
		k.prism(base, 0.08, tip, 0.04, 5, cols[(i + 1) % 4])
		k.icosa(tip, Vector3(0.08, 0.08, 0.08), 0.2, cols[3])
	k.smooth_normals(60.0)
	_save(k.build(M.char), "coral_crust_mesh.tres")


# --- Signs --------------------------------------------------------------------

## A wooden signpost (En_Kanban): a post and a board that the sword can cut in
## two. The board's face is toward -Z.
func _sign() -> void:
	var post := _k(true)
	post.box(Vector3(0, 0.65, 0.04), Vector3(0.12, 1.3, 0.12), Color(0.85, 0.85, 0.85))
	_save(post.build(M.wood), "sign_post_mesh.tres")
	for spec in [["sign_board_mesh.tres", 0.55], ["sign_half_mesh.tres", 0.275]]:
		var h: float = spec[1]
		var b := _k(true)
		b.box(Vector3(0, 0, 0), Vector3(1.0, h, 0.07), Color(1, 1, 1))
		_save(b.build(M.wood), spec[0])
		# Lettering scratched into the face.
		if h > 0.5:
			var t := _k()
			for row in 3:
				var w: float = [0.7, 0.55, 0.62][row]
				t.box(Vector3(-0.04 + (0.7 - w) * -0.2, 0.13 - row * 0.12, -0.037), Vector3(w, 0.04, 0.005), _c("3a2414"))
			_save(t.build(M.char), "sign_text_mesh.tres")


# --- Chests -------------------------------------------------------------------

## Treasure chests (En_Box): the small one in brown wood with iron bands, the
## big one dark blue with gold trim. Bases sit on the floor with the front
## toward -Z; lids pivot on their back edge (the origin of the lid mesh).
func _chests() -> void:
	for spec in [["chest", Vector3(0.95, 0.5, 0.62), "8a5a32", "3a3a44", "d8b040"], ["bigchest", Vector3(1.5, 0.75, 1.0), "2a4a8a", "e0b040", "e0b040"]]:
		var size: Vector3 = spec[1]
		var wood := _c(spec[2])
		var band := _c(spec[3])
		var latch := _c(spec[4])
		var base := _k()
		base.box(Vector3(0, size.y * 0.5, 0), size, wood)
		for x in [-0.36, 0.36]:
			base.box(Vector3(x * size.x, size.y * 0.5, 0), Vector3(0.07 * size.x, size.y * 1.02, size.z * 1.02), band)
		base.box(Vector3(0, size.y * 0.06, 0), Vector3(size.x * 1.02, size.y * 0.12, size.z * 1.02), band)
		base.box(Vector3(0, size.y * 0.82, -size.z * 0.51), Vector3(0.14, 0.18, 0.04) * (size.x / 0.95), latch)
		_save(base.build(M.char), spec[0] + "_base_mesh.tres")
		var lid := _k()
		var lh := size.y * 0.55
		# A rounded lid: a half barrel from the back edge (origin) toward -Z.
		var segs := 6
		for i in segs:
			var a0 := PI * float(i) / segs
			var a1 := PI * float(i + 1) / segs
			var r := size.z * 0.5
			var p0 := Vector3(0, sin(a0) * lh, -r + cos(a0) * r)
			var p1 := Vector3(0, sin(a1) * lh, -r + cos(a1) * r)
			for x in [[-size.x * 0.5, size.x * 0.5, wood]]:
				lid.face([Vector3(x[0], p0.y, p0.z), Vector3(x[1], p0.y, p0.z), Vector3(x[1], p1.y, p1.z), Vector3(x[0], p1.y, p1.z)], x[2] * (1.0 - i * 0.03), Vector3(0, 0, -r))
			for sx in [-1.0, 1.0]:
				lid.face([Vector3(sx * size.x * 0.5, 0, -r), Vector3(sx * size.x * 0.5, p0.y, p0.z), Vector3(sx * size.x * 0.5, p1.y, p1.z)], wood.darkened(0.15), Vector3(0, lh * 0.3, -r))
			for bx in [-0.36, 0.36]:
				var w := 0.035 * size.x
				lid.face([Vector3(bx * size.x - w, p0.y * 1.03, p0.z * 1.0), Vector3(bx * size.x + w, p0.y * 1.03, p0.z), Vector3(bx * size.x + w, p1.y * 1.03, p1.z), Vector3(bx * size.x - w, p1.y * 1.03, p1.z)], band, Vector3(0, -1, -r))
		lid.face([Vector3(-size.x * 0.5, 0, 0), Vector3(size.x * 0.5, 0, 0), Vector3(size.x * 0.5, 0, -size.z), Vector3(-size.x * 0.5, 0, -size.z)], wood.darkened(0.4), Vector3(0, 1, -size.z * 0.5))
		lid.box(Vector3(0, lh * 0.1, -size.z - 0.01), Vector3(0.12, 0.14, 0.04) * (size.x / 0.95), latch)
		_save(lid.build(M.char), spec[0] + "_lid_mesh.tres")


# --- Dungeon doors -------------------------------------------------------------

## Pieces of the shrine's doors, each 2.4 m wide and 3.2 m tall, centered on
## the doorway at floor level and facing -Z:
## - shutter: a carved stone slab that drops to seal a room (Door_Shutter)
## - bars: iron bars that slide up out of the way
## - lock: chains and a padlock over a door (small key); bosslock: the big one
func _doors() -> void:
	var s := _k(true)
	s.box(Vector3(0, 1.6, 0), Vector3(2.4, 3.2, 0.25), Color(0.75, 0.88, 0.92))
	for i in 3:
		s.box(Vector3(0, 0.6 + i * 1.0, -0.13), Vector3(2.0, 0.08, 0.02), Color(0.5, 0.62, 0.68))
	_save(s.build(M.stone), "shutter_mesh.tres")
	var e := _k()
	e.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 1.9, -0.13)))
	e.prism(Vector3(0, -0.03, 0), 0.38, Vector3(0, 0.03, 0), 0.38, 10, _c("2a7a8a"))
	e.pop()
	_save(e.build(M.glow), "shutter_emblem_mesh.tres")
	var bars := _k()
	for i in 7:
		bars.box(Vector3(-1.05 + i * 0.35, 1.6, 0), Vector3(0.08, 3.2, 0.08), _c("3a3a46"))
	for y in [0.4, 1.6, 2.8]:
		bars.box(Vector3(0, y, 0), Vector3(2.4, 0.1, 0.1), _c("2e2e38"))
	_save(bars.build(M.char), "bars_mesh.tres")
	for spec in [["lock_mesh.tres", 1.0, "8a8a96"], ["bosslock_mesh.tres", 1.6, "d8b040"]]:
		var sc: float = spec[1]
		var metal := _c(spec[2])
		var l := _k()
		for d in [-1.0, 1.0]:
			for i in 9:
				var t := float(i) / 8.0
				var p := Vector3(lerpf(-1.1, 1.1, t) * d, lerpf(0.3, 2.9, t), -0.18)
				l.box(p, Vector3(0.14, 0.09, 0.05), _c("5a5a64"))
		l.box(Vector3(0, 1.45, -0.25), Vector3(0.5, 0.42, 0.14) * sc, metal)
		l.prism(Vector3(-0.15, 1.65, -0.25) * Vector3(sc, 1, 1) + Vector3(0, 0.1 * sc, 0), 0.04, Vector3(-0.15 * sc, 1.85 + 0.1 * sc, -0.25), 0.04, 4, metal.darkened(0.2))
		l.prism(Vector3(0.15 * sc, 1.65 + 0.1 * sc, -0.25), 0.04, Vector3(0.15 * sc, 1.85 + 0.1 * sc, -0.25), 0.04, 4, metal.darkened(0.2))
		l.box(Vector3(0, 1.85 + 0.12 * sc, -0.25), Vector3(0.34 * sc, 0.06, 0.06), metal.darkened(0.2))
		l.box(Vector3(0, 1.4, -0.33), Vector3(0.08, 0.16, 0.02) * sc, _c("101014"))
		_save(l.build(M.char), spec[0])


# --- Switches -----------------------------------------------------------------

func _switches() -> void:
	# Crystal switch (Obj_Switch, crystal type): a diamond on a short stone stand.
	var c := _k()
	c.prism(Vector3(0, 0.45, 0), 0.3, Vector3(0, 0.9, 0), 0.0, 6, Color(1, 1, 1))
	c.prism(Vector3(0, 0.45, 0), 0.3, Vector3(0, 0.0, 0), 0.0, 6, Color(0.8, 0.8, 0.8))
	_save(c.build(M.glow), "crystal_mesh.tres")
	var cb := _k(true)
	cb.prism(Vector3(0, 0, 0), 0.45, Vector3(0, 0.35, 0), 0.35, 8, Color(0.8, 0.9, 0.95))
	_save(cb.build(M.stone), "crystal_base_mesh.tres")
	# Floor switch (Obj_Switch, floor type): a rusty square plate on a frame.
	var f := _k()
	f.box(Vector3(0, 0.08, 0), Vector3(1.2, 0.16, 1.2), _c("b05a2a"))
	f.box(Vector3(0, 0.17, 0), Vector3(0.5, 0.04, 0.5), _c("e0a040"))
	_save(f.build(M.char), "floor_switch_mesh.tres")
	var fr := _k()
	for side in [[Vector3(0, 0.05, 0.7), Vector3(1.6, 0.1, 0.2)], [Vector3(0, 0.05, -0.7), Vector3(1.6, 0.1, 0.2)], [Vector3(0.7, 0.05, 0), Vector3(0.2, 0.1, 1.2)], [Vector3(-0.7, 0.05, 0), Vector3(0.2, 0.1, 1.2)]]:
		fr.box(side[0], side[1], _c("4a4a52"))
	_save(fr.build(M.char), "floor_switch_frame_mesh.tres")


# --- Blue warp ----------------------------------------------------------------

## The blue light that carries the hero out after the boss (Door_Warp1): a
## translucent glowing column over a bright ring on the floor.
func _warp() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	ResourceSaver.save(mat, "res://assets/materials/warp.tres")
	var m: Material = ResourceLoader.load("res://assets/materials/warp.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	var k := _k()
	k.prism(Vector3(0, 0, 0), 1.3, Vector3(0, 7.0, 0), 0.9, 16, Color(0.35, 0.6, 1.0, 0.45))
	k.prism(Vector3(0, 0.02, 0), 1.6, Vector3(0, 0.08, 0), 1.6, 16, Color(0.6, 0.85, 1.0, 0.8))
	_save(k.build(m), "warp_mesh.tres")
