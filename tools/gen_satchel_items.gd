extends RefCounted
## Meshes for "The Satchel" update (alpha 1.6.0): the Sun and Frost Arrows,
## Puff Nuts, the Iron Mallet, the Lantern, Mira's Looking Glass, the three
## goddesses' blessings (orbs, as OoT draws its spells), the blue magic jars
## and the Frost Arrow's ice floe. Saved as .tres meshes in res://assets/models/.
##
## Things held in the hand are built along -Z from the grip (as the bloom rod
## and the arrow are); the lantern hangs down from its hook at the origin.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 3100


func run(materials: Dictionary) -> void:
	M = materials
	_magic_arrow("sun", _c("e8b830"), _c("fff2a0"))
	_magic_arrow("frost", _c("7ac8f0"), _c("e0f6ff"))
	_puff_nut()
	_iron_mallet()
	_lantern()
	_looking_glass()
	_blessing("alans_harvest", _c("58d050"), _c("c8a040"))
	_blessing("aphiels_gale", _c("8af0d0"), _c("d8e8f0"))
	_blessing("serielyes_ruin", _c("e03050"), _c("6a3048"))
	_magic_jar("magic_small", 0.13)
	_magic_jar("magic_large", 0.19)
	_ice_floe()
	_fishing_rod_icon()


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


## An arrow (the plain arrow's shape, along -Z) with a colored head and
## fletching, and a glowing gem behind the head: gold for the sun, ice blue
## for frost.
func _magic_arrow(kind: String, col: Color, glow: Color) -> void:
	var a := _k()
	a.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	a.prism(Vector3(0, -0.42, 0), 0.009, Vector3(0, 0.34, 0), 0.009, 4, _c("c8a070") if kind == "sun" else _c("a8b8c8"))
	if kind == "sun":
		# A broad leaf-shaped head with rays.
		a.prism(Vector3(0, 0.34, 0), 0.03, Vector3(0, 0.47, 0), 0.0, 6, col)
		for i in 4:
			var d := Vector3(cos(TAU * i / 4.0), 0, sin(TAU * i / 4.0))
			a.prism(Vector3(0, 0.36, 0) + d * 0.02, 0.006, Vector3(0, 0.33, 0) + d * 0.06, 0.0, 3, col.lightened(0.2))
	else:
		# A crystal head of ice.
		a.prism(Vector3(0, 0.32, 0), 0.0, Vector3(0, 0.37, 0), 0.032, 5, col)
		a.prism(Vector3(0, 0.37, 0), 0.032, Vector3(0, 0.48, 0), 0.0, 5, col.lightened(0.25))
	for i in 3:
		var ang := TAU * i / 3.0
		var d := Vector3(cos(ang), 0, sin(ang))
		var vcol := col if i == 0 else _c("f8f4e8")
		var vane := [Vector3(0, -0.42, 0), Vector3(0, -0.25, 0), Vector3(0, -0.3, 0) + d * 0.04, Vector3(0, -0.42, 0) + d * 0.04]
		a.face_dir(vane, vcol, Vector3(d.z, 0, -d.x))
		a.face_dir(vane, vcol, Vector3(-d.z, 0, d.x))
	a.pop()
	var mesh := a.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0, -0.33), Vector3(0.035, 0.035, 0.035), 0.0, glow)
	g.add_to(mesh, M.glow)
	_save(mesh, "%s_arrow_mesh.tres" % kind)


## A Puff Nut: a round tan nut (0.15 m) with a dark cap and a little tuft,
## its seams showing.
func _puff_nut() -> void:
	var k := _k()
	var shell := _c("c89a5a")
	k.loft([
		[-0.07, 0.0, 0.0, shell.darkened(0.25)], [-0.055, 0.05, 0.05, shell.darkened(0.1)], [-0.02, 0.072, 0.072, shell],
		[0.02, 0.07, 0.07, shell.lightened(0.08)], [0.05, 0.05, 0.05, shell], [0.062, 0.03, 0.03, _c("6a4a2a")],
		[0.07, 0.0, 0.0, _c("5a3a1a")],
	], 9)
	k.prism(Vector3(0, 0.065, 0), 0.008, Vector3(0.01, 0.1, 0), 0.0, 4, _c("4a6a2a"))
	for i in 3:
		var a := TAU * i / 3.0
		k.box(Vector3(cos(a) * 0.071, 0.0, sin(a) * 0.071), Vector3(0.006, 0.09, 0.006), shell.darkened(0.3))
	k.smooth_normals(60.0)
	_save(k.build(M.char), "puff_nut_mesh.tres")


## The Iron Mallet: a stout wooden handle wound with leather (0.7 m along -Z)
## and a heavy iron head across it, banded in brass, its faces studded.
func _iron_mallet() -> void:
	var k := _k()
	var wood := _c("6a4a2a")
	var iron := _c("6a6e78")
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
	k.prism(Vector3(0, -0.1, 0), 0.026, Vector3(0, 0.62, 0), 0.03, 6, wood)
	k.prism(Vector3(0, -0.1, 0), 0.031, Vector3(0, 0.1, 0), 0.031, 6, _c("4a2e1a"))
	k.prism(Vector3(0, -0.13, 0), 0.036, Vector3(0, -0.1, 0), 0.036, 6, _c("b89a48"))
	k.pop()
	# The head, its axis across the handle (along X).
	k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(0, 0, -0.68)))
	k.prism(Vector3(0, -0.2, 0), 0.1, Vector3(0, 0.2, 0), 0.1, 8, iron, PI / 8.0)
	k.prism(Vector3(0, -0.23, 0), 0.115, Vector3(0, -0.2, 0), 0.115, 8, iron.darkened(0.25), PI / 8.0)
	k.prism(Vector3(0, 0.2, 0), 0.115, Vector3(0, 0.23, 0), 0.115, 8, iron.darkened(0.25), PI / 8.0)
	for y in [-0.12, 0.12]:
		k.prism(Vector3(0, y - 0.018, 0), 0.106, Vector3(0, y + 0.018, 0), 0.106, 8, _c("c8a040"), PI / 8.0)
	k.pop()
	k.smooth_normals(40.0)
	_save(k.build(M.char), "iron_mallet_mesh.tres")


## The Lantern: a brass cage round a glass with a warm flame, a little peaked
## roof and a ring to hang it by. The ring is at the origin; it hangs down.
func _lantern() -> void:
	var k := _k()
	var brass := _c("b88a38")
	k.prism(Vector3(0, -0.03, 0), 0.016, Vector3(0, 0.0, 0), 0.016, 6, brass.lightened(0.15))
	k.prism(Vector3(0, -0.07, 0), 0.075, Vector3(0, -0.035, 0), 0.0, 6, brass)
	k.prism(Vector3(0, -0.085, 0), 0.08, Vector3(0, -0.07, 0), 0.08, 6, brass.darkened(0.2))
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(cos(a) * 0.07, -0.16, sin(a) * 0.07), Vector3(0.012, 0.15, 0.012), brass.darkened(0.1))
	k.prism(Vector3(0, -0.25, 0), 0.08, Vector3(0, -0.235, 0), 0.08, 6, brass.darkened(0.2))
	k.prism(Vector3(0, -0.275, 0), 0.05, Vector3(0, -0.25, 0), 0.07, 6, brass)
	k.smooth_normals(35.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.prism(Vector3(0, -0.235, 0), 0.06, Vector3(0, -0.085, 0), 0.06, 6, _c("ffd890"))
	g.icosa(Vector3(0, -0.17, 0), Vector3(0.03, 0.05, 0.03), 0.0, _c("fff6d0"))
	g.add_to(mesh, M.glow)
	_save(mesh, "lantern_mesh.tres")


## Mira's Looking Glass: a round hand mirror in a silver frame worked with
## little moons, its glass a pale violet, on a short handle. The glass faces
## +Z, the handle hangs down.
func _looking_glass() -> void:
	var k := _k()
	var silver := _c("c8ccd8")
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.0, 0)))
	k.prism(Vector3(0, -0.018, 0), 0.13, Vector3(0, 0.018, 0), 0.13, 14, silver.darkened(0.15))
	k.pop()
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		k.icosa(Vector3(cos(a) * 0.13, sin(a) * 0.13, 0.0), Vector3(0.022, 0.022, 0.022), 0.0, _c("e8d898"))
	k.prism(Vector3(0, -0.32, 0), 0.02, Vector3(0, -0.12, 0), 0.026, 6, silver)
	k.icosa(Vector3(0, -0.33, 0), Vector3(0.03, 0.03, 0.03), 0.0, _c("8a6ac8"))
	k.smooth_normals(45.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	g.prism(Vector3(0, -0.022, 0), 0.105, Vector3(0, 0.022, 0), 0.105, 14, _c("b8a8f0"))
	g.pop()
	g.icosa(Vector3(-0.03, 0.035, 0.024), Vector3(0.03, 0.02, 0.004), 0.0, _c("f4f0ff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "looking_glass_mesh.tres")


## A goddess's blessing as OoT draws its spells: a glowing orb in a small
## setting. Alan's sits in three golden leaves, Aphiel's in a ring of wind
## with a feather, Serielye's in jagged dark horns.
func _blessing(id: String, orb: Color, trim: Color) -> void:
	var k := _k()
	match id:
		"alans_harvest":
			for i in 3:
				var a := TAU * i / 3.0
				k.push(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.BACK, 0.9), Vector3(0, -0.06, 0)))
				k.slab(Vector3.ZERO, Vector2(0.05, 0.012), Vector3(0, 0.16, 0), Vector2(0.0, 0.004), trim)
				k.pop()
			k.prism(Vector3(0, -0.12, 0), 0.03, Vector3(0, -0.06, 0), 0.05, 6, trim.darkened(0.2))
		"aphiels_gale":
			for i in 10:
				var a := TAU * i / 10.0
				k.push(Transform3D(Basis(Vector3.UP, a), Vector3.ZERO))
				k.box(Vector3(0.13, -0.01 + 0.012 * sin(a * 2.0), 0), Vector3(0.025, 0.012, 0.045), trim)
				k.pop()
			k.push(Transform3D(Basis(Vector3.BACK, -0.5), Vector3(0.05, 0.05, 0.02)))
			k.slab(Vector3.ZERO, Vector2(0.04, 0.008), Vector3(0, 0.2, 0), Vector2(0.0, 0.004), _c("f4f8ff"))
			k.pop()
		"serielyes_ruin":
			for i in 5:
				var a := TAU * i / 5.0
				k.push(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.BACK, 1.25), Vector3(0, 0.0, 0)))
				k.prism(Vector3.ZERO, 0.035, Vector3(0, 0.2, 0), 0.0, 4, trim)
				k.pop()
	k.smooth_normals(40.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0, 0.03, 0), Vector3(0.085, 0.085, 0.085), 0.0, orb.lightened(0.15), true)
	g.icosa(Vector3(-0.025, 0.06, 0.06), Vector3(0.025, 0.02, 0.012), 0.0, orb.lightened(0.6))
	g.add_to(mesh, M.glow)
	_save(mesh, "%s_mesh.tres" % id)


## OoT's magic jars: a squat pot with a cork, blue to match the meter (the large one bigger).
func _magic_jar(file: String, h: float) -> void:
	var k := _k()
	var green := _c("2a6ad8")
	var r := h * 0.55
	k.loft([
		[0.0, 0.0, 0.0, green.darkened(0.3)], [0.005, r * 0.7, r * 0.7, green.darkened(0.15)], [h * 0.35, r, r, green],
		[h * 0.65, r * 0.85, r * 0.85, green.lightened(0.15)], [h * 0.8, r * 0.45, r * 0.45, green], [h * 0.88, r * 0.5, r * 0.5, green.lightened(0.1)],
		[h * 0.9, 0.0, 0.0, green],
	], 10)
	k.prism(Vector3(0, h * 0.86, 0), r * 0.36, Vector3(0, h * 1.05, 0), r * 0.4, 8, _c("c8a070"))
	k.smooth_normals(60.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(-r * 0.4, h * 0.5, r * 0.75), Vector3(r * 0.18, r * 0.25, r * 0.08), 0.0, _c("c8e0ff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "%s_mesh.tres" % file)


## The Fishing Rod as its icon shows it: a short stout rod with a cork grip
## and a reel, the line hanging from the tip to a red and white float.
func _fishing_rod_icon() -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.BACK, -0.6), Vector3.ZERO))
	k.prism(Vector3(0, -0.3, 0), 0.03, Vector3(0, -0.1, 0), 0.03, 6, _c("c8a070"))
	k.prism(Vector3(0, -0.1, 0), 0.02, Vector3(0, 0.45, 0), 0.008, 6, _c("5a3a22"))
	k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(0.05, -0.16, 0)))
	k.prism(Vector3(0, -0.02, 0), 0.05, Vector3(0, 0.02, 0), 0.05, 10, _c("a8acb4"))
	k.pop()
	k.pop()
	var tip := Basis(Vector3.BACK, -0.6) * Vector3(0, 0.45, 0)
	k.prism(tip + Vector3(0, -0.32, 0), 0.003, tip, 0.003, 3, _c("e8e8f0"))
	k.icosa(tip + Vector3(0, -0.34, 0), Vector3(0.035, 0.03, 0.035), 0.0, _c("f0f0f0"))
	k.icosa(tip + Vector3(0, -0.37, 0), Vector3(0.035, 0.025, 0.035), 0.0, _c("e02a2a"))
	k.smooth_normals(45.0)
	_save(k.build(M.char), "fishing_rod_icon_mesh.tres")


## The Frost Arrow's floe: a rough disc of ice, its top 0.12 m above the
## water at the origin's height.
func _ice_floe() -> void:
	var k := _k(true)
	var ice := _c("cfe8f4")
	var rings := [
		[-0.23, 1.15, 1.15, ice.darkened(0.25)], [-0.05, 1.32, 1.32, ice.darkened(0.08)],
		[0.08, 1.4, 1.4, ice], [0.12, 1.3, 1.3, ice.lightened(0.1)], [0.125, 0.0, 0.0, ice.lightened(0.15)],
	]
	k.loft(rings, 11)
	_save(k.build(M.ice), "ice_floe_mesh.tres")
