extends RefCounted
## Meshes for Beta 1.2.0 ("The Fall of Bunsriel", Chapter IV): the Grave
## Spade, the Sapphire Staff and its block, the Starfall Arrows, the Astral
## Seal and the ice it makes, the Longshot, the Anchor Boots, a treasure
## chart scrap, the purple and gold rupees, the dig mounds, and the siege's
## engines (the ballista and its bolt, ladders, siege towers, the gate, the
## war camps' cages and banners). Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 6400


func run(materials: Dictionary) -> void:
	M = materials
	_grave_spade()
	_sapphire_staff()
	_sapphire_block()
	_starfall_arrow()
	_astral_seal()
	_ice_prison()
	_longshot()
	_anchor_boots()
	_chart_scrap()
	_rupee("purple", _c("9a3ad8"))
	_rupee("gold", _c("f0c020"))
	for soil in [["earth", _c("4a3424")], ["sand", _c("b89a64")], ["snow", _c("d8e0ec")], ["ash", _c("3a3836")]]:
		_mound(soil[0], soil[1])
	_ballista()
	_bolt()
	_ladder()
	_siege_tower()
	_cage()
	_war_banner()
	_star_eye()
	print("gen_ch4_items: done")


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


## The Grave Spade: Wren's old spade, a long ash-wood shaft worn pale at the
## grips, a T handle, and a dull iron blade. Held like the mallet: the shaft
## along -Z from the fist, the blade at the far end.
func _grave_spade() -> void:
	var k := _k()
	var wood := _c("8a6a44")
	var iron := _c("5a5c64")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.12, 0), 0.022, Vector3(0, 0.7, 0), 0.024, 6, wood)
	k.prism(Vector3(0, -0.02, 0), 0.026, Vector3(0, 0.12, 0), 0.026, 6, wood.lightened(0.2))
	k.pop()
	# The T handle behind the fist.
	k.box(Vector3(0, 0, 0.14), Vector3(0.16, 0.035, 0.035), wood.darkened(0.2))
	# The blade: a rounded iron plate, its face across Y, a socket on the shaft.
	k.prism(Vector3(0, 0, -0.7), 0.035, Vector3(0, 0, -0.78), 0.04, 6, iron.darkened(0.2))
	k.box(Vector3(0, 0, -0.9), Vector3(0.2, 0.025, 0.24), iron)
	k.prism(Vector3(0, -0.005, -1.02), 0.1, Vector3(0, 0.005, -1.02), 0.1, 8, iron.lightened(0.1))
	k.smooth_normals(35.0)
	_save(k.build(M.char), "grave_spade_mesh.tres")


## The Sapphire Staff: a black rod bound in silver, crowned by a sapphire
## claw holding a great glowing stone. Along -Z from the fist.
func _sapphire_staff() -> void:
	var k := _k()
	var rod := _c("1e2030")
	var silver := _c("a8b0c8")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.45, 0), 0.02, Vector3(0, 0.85, 0), 0.026, 6, rod)
	for y in [-0.3, 0.0, 0.4, 0.8]:
		k.prism(Vector3(0, y, 0), 0.032, Vector3(0, y + 0.04, 0), 0.032, 6, silver)
	# The claw: four silver prongs curling up round the stone.
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		k.prism(Vector3(0, 0.85, 0) + d * 0.02, 0.014, Vector3(0, 0.98, 0) + d * 0.075, 0.01, 4, silver)
		k.prism(Vector3(0, 0.98, 0) + d * 0.075, 0.01, Vector3(0, 1.06, 0) + d * 0.04, 0.0, 4, silver.lightened(0.2))
	k.pop()
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0, -0.98), Vector3(0.07, 0.07, 0.09), 0.0, _c("4a6aff"), true)
	g.add_to(mesh, M.glow)
	_save(mesh, "sapphire_staff_mesh.tres")


## The staff's block: a 1.6 m cube of faceted sapphire, its foot at the
## origin, bevelled edges and lighter facets.
func _sapphire_block() -> void:
	var k := _k()
	var s := 0.8
	var b := 0.12
	var col := _c("3a5ad8")
	k.box(Vector3(0, s, 0), Vector3(s * 2.0 - b * 2.0, s * 2.0, s * 2.0 - b * 2.0), col)
	k.box(Vector3(0, s, 0), Vector3(s * 2.0, s * 2.0 - b * 2.0, s * 2.0 - b * 2.0), col.lightened(0.12))
	k.box(Vector3(0, s, 0), Vector3(s * 2.0 - b * 2.0, s * 2.0 - b * 2.0, s * 2.0), col.darkened(0.08))
	var mesh := k.build(M.char)
	var g := _k()
	# Lit seams on each side face: the Order's sigil, a diamond.
	for f: Vector3 in [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var c := Vector3(0, s, 0) + f * (s + 0.005)
		var up := Vector3.UP * 0.35
		var side := Vector3(-f.z, 0, f.x) * 0.35
		g.face_dir([c + up, c + side, c - up, c - side], _c("8aa8ff"), f)
	g.add_to(mesh, M.glow)
	_save(mesh, "sapphire_block_mesh.tres")


## A Starfall Arrow: a pale shaft, a four-pointed star for a head, white
## fletching, and a glowing star-white gem.
func _starfall_arrow() -> void:
	var a := _k()
	var col := _c("e8eeff")
	a.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	a.prism(Vector3(0, -0.42, 0), 0.009, Vector3(0, 0.34, 0), 0.009, 4, _c("c8c8d8"))
	a.prism(Vector3(0, 0.33, 0), 0.03, Vector3(0, 0.49, 0), 0.0, 4, col)
	for i in 4:
		var d := Vector3(cos(TAU * i / 4.0 + PI / 4.0), 0, sin(TAU * i / 4.0 + PI / 4.0))
		a.prism(Vector3(0, 0.37, 0), 0.008, Vector3(0, 0.37, 0) + d * 0.07, 0.0, 3, col)
	for i in 3:
		var ang := TAU * i / 3.0
		var d := Vector3(cos(ang), 0, sin(ang))
		var vane := [Vector3(0, -0.42, 0), Vector3(0, -0.25, 0), Vector3(0, -0.3, 0) + d * 0.04, Vector3(0, -0.42, 0) + d * 0.04]
		a.face_dir(vane, _c("f8f8ff") if i > 0 else _c("8aa0ff"), Vector3(d.z, 0, -d.x))
		a.face_dir(vane, _c("f8f8ff") if i > 0 else _c("8aa0ff"), Vector3(-d.z, 0, d.x))
	a.pop()
	var mesh := a.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0, -0.37), Vector3(0.04, 0.04, 0.04), 0.0, _c("d8e4ff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "starfall_arrow_mesh.tres")


## The Astral Seal: a long eight-sided crystal of the Astral Dimension, pale
## violet and starry, held in a silver cradle ringed with Lothelye's stars.
func _astral_seal() -> void:
	var k := _k()
	var silver := _c("c0c8d8")
	k.prism(Vector3(0, -0.14, 0), 0.08, Vector3(0, -0.1, 0), 0.07, 8, silver.darkened(0.2))
	for i in 4:
		var a := TAU * i / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		k.prism(Vector3(0, -0.1, 0) + d * 0.06, 0.012, Vector3(0, 0.0, 0) + d * 0.075, 0.008, 4, silver)
	var mesh := k.build(M.char)
	var g := _k()
	g.prism(Vector3(0, -0.1, 0), 0.0, Vector3(0, 0.0, 0), 0.07, 8, _c("b8a8ff"))
	g.prism(Vector3(0, 0.0, 0), 0.07, Vector3(0, 0.14, 0), 0.06, 8, _c("c8c0ff"))
	g.prism(Vector3(0, 0.14, 0), 0.06, Vector3(0, 0.24, 0), 0.0, 8, _c("e0dcff"))
	for i in 5:
		var a := TAU * i / 5.0
		g.icosa(Vector3(cos(a) * 0.03, 0.04 + i * 0.03, sin(a) * 0.03), Vector3(0.012, 0.012, 0.012), 0.0, _c("ffffff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "astral_seal_mesh.tres")


## The ice the Astral Seal makes round Firebuns: a tall jagged block of pale
## blue crystal (about 3 m tall), its foot at the origin.
func _ice_prison() -> void:
	var k := _k()
	k.prism(Vector3(0, 0, 0), 1.3, Vector3(0, 2.6, 0), 1.0, 7, _c("a8c8f0"))
	k.prism(Vector3(0, 2.6, 0), 1.0, Vector3(0.1, 3.4, 0), 0.0, 7, _c("c8e0ff"))
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		k.prism(d * 0.9 + Vector3(0, 0.2, 0), 0.35, d * 1.4 + Vector3(0, 1.8 + (i % 3) * 0.4, 0), 0.0, 5, _c("b8d8ff"))
	_save(k.build(M.glow), "ice_prison_mesh.tres")


## The Longshot: the Hookshot's launcher, longer, its drum bronze and its
## barrel banded in gold.
func _longshot() -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.08, 0), 0.05, Vector3(0, 0.42, 0), 0.045, 8, _c("8a8a96"))
	k.prism(Vector3(0, 0.42, 0), 0.06, Vector3(0, 0.46, 0), 0.06, 8, _c("5a5a66"))
	for y in [0.2, 0.3]:
		k.prism(Vector3(0, y, 0), 0.052, Vector3(0, y + 0.03, 0), 0.052, 8, _c("e0b040"))
	k.prism(Vector3(0, 0.03, 0.0), 0.08, Vector3(0, 0.15, 0.0), 0.08, 10, _c("a8682a"))
	k.pop()
	k.push(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20)), Vector3(0, -0.02, 0.04)))
	k.prism(Vector3(0, -0.14, 0), 0.03, Vector3(0, 0.0, 0), 0.032, 6, _c("4a3020"))
	k.pop()
	_save(k.build(M.char), "longshot_mesh.tres")


## The Anchor Boots: squat boots of black iron, riveted, with a little
## anchor on each.
func _anchor_boots() -> void:
	var k := _k()
	var col := _c("3a3c44")
	var dark := _c("22242a")
	for sx in [-1.0, 1.0]:
		var x: float = 0.07 * sx
		k.prism(Vector3(x, 0.02, 0.0), 0.056, Vector3(x, 0.19, 0.0), 0.052, 8, col)
		k.prism(Vector3(x, 0.18, 0.0), 0.062, Vector3(x, 0.22, 0.0), 0.064, 8, dark)
		k.box(Vector3(x, 0.03, -0.05), Vector3(0.1, 0.06, 0.14), col)
		k.box(Vector3(x, 0.008, -0.02), Vector3(0.11, 0.02, 0.2), dark)
		for r in 4:
			var a := TAU * r / 4.0
			k.icosa(Vector3(x + cos(a) * 0.056, 0.1, sin(a) * 0.056), Vector3(0.008, 0.008, 0.008), 0.0, _c("8a8c94"))
		# The anchor on the outside of the shaft.
		k.box(Vector3(x + 0.055 * sx, 0.12, 0), Vector3(0.006, 0.07, 0.012), _c("b89a48"))
		k.box(Vector3(x + 0.055 * sx, 0.09, 0), Vector3(0.006, 0.012, 0.05), _c("b89a48"))
	k.smooth_normals(40.0)
	_save(k.build(M.char), "boots_anchor_mesh.tres")


## A scrap of an old treasure chart: torn parchment with a dotted trail and
## a red X. Stands upright facing +Z.
func _chart_scrap() -> void:
	var k := _k()
	var vellum := _c("d8c49a")
	k.box(Vector3(0, 0, 0), Vector3(0.34, 0.28, 0.01), vellum)
	for i in 4:
		k.box(Vector3(0.17, -0.1 + i * 0.07, 0), Vector3(0.025, 0.04, 0.012), vellum.darkened(0.3))
	for s in [-1.0, 1.0]:
		for i in 6:
			k.box(Vector3(-0.12 + i * 0.035, -0.06 + sin(i * 0.9) * 0.04, s * 0.006), Vector3(0.014, 0.014, 0.002), _c("5a4a3a"))
		k.box(Vector3(0.08, 0.05, s * 0.006), Vector3(0.09, 0.018, 0.002), _c("b02a20"))
		k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
		k.box(Vector3(0.05, -0.08, s * 0.006), Vector3(0.09, 0.018, 0.002), _c("b02a20"))
		k.pop()
	_save(k.build(M.char), "chart_scrap_mesh.tres")


## A coin like gen_items' (Beta 1.6.0), in its own color.
func _rupee(kind: String, col: Color) -> void:
	var k := _k()
	preload("res://tools/gen_items.gd").build_coin(k, col)
	_save(k.build(M.glow), "rupee_%s_mesh.tres" % kind)


## Soft turned earth (a DigSpot): a low lumpy mound a meter across, its foot
## at the origin, a few clods and pebbles in it.
func _mound(soil: String, col: Color) -> void:
	var k := _k()
	k.icosa(Vector3(0, 0.0, 0), Vector3(0.6, 0.16, 0.55), 0.04, col, true)
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		k.icosa(Vector3(cos(a) * 0.38, 0.08, sin(a) * 0.32), Vector3(0.09, 0.06, 0.08), 0.02, col.darkened(0.2) if i % 2 == 0 else col.lightened(0.1))
	k.icosa(Vector3(0.12, 0.13, -0.1), Vector3(0.05, 0.04, 0.05), 0.0, _c("8a8478"))
	k.smooth_normals(50.0)
	_save(k.build(M.char), "dig_mound_%s_mesh.tres" % soil)


## The gatehouse ballista: a heavy timber stand, a turning cradle, the two
## great bow arms and their cord, and a bolt laid ready. The node turns the
## whole thing; it aims along -Z, its pivot 1.1 m up at the origin's +Y.
func _ballista() -> void:
	var k := _k()
	var wood := _c("6a4a2a")
	var dark := _c("4a3220")
	var iron := _c("5a5c64")
	# The stand (in its own frame: drawn with the pivot at y 0 here).
	k.box(Vector3(0, 0.1, 0.4), Vector3(0.3, 0.2, 1.6), dark)
	k.box(Vector3(0, 0.0, 0), Vector3(0.9, 0.12, 0.3), dark)
	k.box(Vector3(0, 0.25, -0.5), Vector3(0.26, 0.26, 0.4), wood)
	# The bow arms.
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.UP, deg_to_rad(18.0 * sx)), Vector3(0.1 * sx, 0.28, -0.6)))
		k.box(Vector3(0.6 * sx, 0, 0.1), Vector3(1.2, 0.09, 0.09), wood)
		k.box(Vector3(1.18 * sx, 0, 0.18), Vector3(0.08, 0.14, 0.08), iron)
		k.pop()
	# The cord, drawn back to the trigger.
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.UP, atan2(-1.1 * sx, 1.05)), Vector3(1.2 * sx, 0.28, -0.4)))
		k.box(Vector3(0, 0, 0.75), Vector3(0.015, 0.015, 1.5), _c("d8c8a0"))
		k.pop()
	k.box(Vector3(0, 0.32, 0.65), Vector3(0.12, 0.1, 0.12), iron)
	k.box(Vector3(0, 0.35, 0.05), Vector3(0.05, 0.05, 1.3), _c("8a6a44"))
	k.prism(Vector3(0, 0.35, -0.6), 0.04, Vector3(0, 0.35, -0.85), 0.0, 4, iron)
	_save(k.build(M.char), "ballista_mesh.tres")
	# Its post and turning base (fixed to the wall walk).
	var b := _k()
	b.prism(Vector3(0, 0, 0), 0.45, Vector3(0, 0.2, 0), 0.42, 8, dark)
	b.prism(Vector3(0, 0.2, 0), 0.16, Vector3(0, 0.95, 0), 0.14, 6, wood)
	b.box(Vector3(0, 1.0, 0), Vector3(0.5, 0.1, 0.5), iron)
	_save(b.build(M.char), "ballista_base_mesh.tres")


## A ballista bolt: a long iron-headed shaft with leather fins, along -Z.
func _bolt() -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.6, 0), 0.03, Vector3(0, 0.55, 0), 0.03, 6, _c("8a6a44"))
	k.prism(Vector3(0, 0.55, 0), 0.06, Vector3(0, 0.8, 0), 0.0, 4, _c("6a6c74"))
	for i in 3:
		var d := Vector3(cos(TAU * i / 3.0), 0, sin(TAU * i / 3.0))
		k.face_dir([Vector3(0, -0.6, 0), Vector3(0, -0.35, 0), Vector3(0, -0.42, 0) + d * 0.09, Vector3(0, -0.6, 0) + d * 0.09], _c("6a3a24"), Vector3(d.z, 0, -d.x))
		k.face_dir([Vector3(0, -0.6, 0), Vector3(0, -0.35, 0), Vector3(0, -0.42, 0) + d * 0.09, Vector3(0, -0.6, 0) + d * 0.09], _c("6a3a24"), Vector3(-d.z, 0, d.x))
	k.pop()
	_save(k.build(M.char), "ballista_bolt_mesh.tres")


## A goblin siege ladder: two rough poles 6 m long and lashed rungs, hooked
## at the top. Its foot at the origin, leaning along -Z (rotated by the node).
func _ladder() -> void:
	var k := _k()
	var pole := _c("5a4028")
	for sx in [-1.0, 1.0]:
		k.prism(Vector3(0.38 * sx, 0, 0), 0.06, Vector3(0.38 * sx, 6.0, 0), 0.05, 5, pole)
		k.prism(Vector3(0.38 * sx, 6.0, 0), 0.04, Vector3(0.38 * sx, 6.2, -0.25), 0.02, 4, _c("4a4c54"))
	for i in 14:
		var y := 0.35 + i * 0.42
		k.box(Vector3(0, y, 0), Vector3(0.78, 0.06, 0.07), pole.lightened(0.1))
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.38 * sx, y, 0), Vector3(0.1, 0.09, 0.1), _c("8a7a54"))
	_save(k.build(M.char), "siege_ladder_mesh.tres")


## A siege tower: a tall timber frame on four wheels, hide-covered on the
## front, a drawbridge folded up at the top. Its foot at the origin, front
## toward -Z; about 3 m wide and 7 m tall.
func _siege_tower() -> void:
	var k := _k()
	var wood := _c("6a4a2a")
	var dark := _c("4a3220")
	var hide := _c("8a6a4a")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(1.4 * sx, 3.6, 1.4 * sz), Vector3(0.22, 7.0, 0.22), dark)
	for y in [0.6, 2.4, 4.2, 6.0, 7.0]:
		k.box(Vector3(0, y, -1.4), Vector3(3.0, 0.18, 0.18), wood)
		k.box(Vector3(0, y, 1.4), Vector3(3.0, 0.18, 0.18), wood)
		k.box(Vector3(-1.4, y, 0), Vector3(0.18, 0.18, 3.0), wood)
		k.box(Vector3(1.4, y, 0), Vector3(0.18, 0.18, 3.0), wood)
	# Hides over the front and sides.
	k.box(Vector3(0, 3.4, -1.5), Vector3(2.9, 5.6, 0.06), hide)
	k.box(Vector3(-1.5, 3.4, 0), Vector3(0.06, 5.6, 2.9), hide.darkened(0.12))
	k.box(Vector3(1.5, 3.4, 0), Vector3(0.06, 5.6, 2.9), hide.darkened(0.12))
	# The drawbridge, folded up.
	k.box(Vector3(0, 7.9, -1.5), Vector3(2.4, 1.6, 0.14), wood.lightened(0.1))
	# Wheels.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(1.6 * sx, 0.55, 1.0 * sz)))
			k.prism(Vector3(0, -0.12, 0), 0.55, Vector3(0, 0.12, 0), 0.55, 10, dark)
			k.pop()
	_save(k.build(M.char), "siege_tower_mesh.tres")


## A goblin cage: a square pen of rough poles lashed together under a hide
## roof. Its foot at the origin, about 2.4 m across.
func _cage() -> void:
	var k := _k()
	var pole := _c("4a3424")
	for i in 7:
		var t := -1.1 + i * (2.2 / 6.0)
		for s in [-1.1, 1.1]:
			k.prism(Vector3(t, 0, s), 0.05, Vector3(t, 2.2, s), 0.045, 5, pole)
			k.prism(Vector3(s, 0, t), 0.05, Vector3(s, 2.2, t), 0.045, 5, pole)
	for y in [0.4, 2.1]:
		for s in [-1.1, 1.1]:
			k.box(Vector3(0, y, s), Vector3(2.3, 0.08, 0.08), pole.lightened(0.1))
			k.box(Vector3(s, y, 0), Vector3(0.08, 0.08, 2.3), pole.lightened(0.1))
	k.box(Vector3(0, 2.3, 0), Vector3(2.5, 0.08, 2.5), _c("6a5a44"))
	_save(k.build(M.char), "goblin_cage_mesh.tres")


## Firebuns' war banner on a pole: black cloth, a red-gold flame. Foot at the
## origin; the cloth faces -Z.
func _war_banner() -> void:
	var k := _k()
	k.prism(Vector3(0, 0, 0), 0.06, Vector3(0, 4.2, 0), 0.05, 6, _c("3a2a1a"))
	k.box(Vector3(0.65, 3.9, 0), Vector3(1.3, 0.06, 0.06), _c("3a2a1a"))
	k.box(Vector3(0.65, 3.1, 0), Vector3(1.2, 1.6, 0.03), _c("1a1414"))
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.65, 3.15, s * 0.02), Vector3(0.36, 0.7, 0.01), _c("c83a1a"))
		k.box(Vector3(0.65, 3.3, s * 0.022), Vector3(0.18, 0.4, 0.01), _c("f0b030"))
	_save(k.build(M.char), "war_banner_mesh.tres")


## A star eye (the Temple of Bun): a round stone boss with a closed eye of
## pale crystal that opens to a Starfall Arrow. Faces -Z, middle at the node.
func _star_eye() -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, 0.12, 0), 0.5, Vector3(0, -0.06, 0), 0.45, 12, _c("c8c0a8"))
	k.pop()
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0, -0.1), Vector3(0.28, 0.16, 0.08), 0.0, _c("ffffff"))
	g.icosa(Vector3(0, 0, -0.16), Vector3(0.1, 0.1, 0.04), 0.0, _c("ffffff"))
	var mat: StandardMaterial3D = (M.glow as StandardMaterial3D).duplicate()
	g.add_to(mesh, mat)
	_save(mesh, "star_eye_mesh.tres")
