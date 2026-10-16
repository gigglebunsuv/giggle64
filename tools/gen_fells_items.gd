extends RefCounted
## Meshes for Beta 1.1.0 ("The Batela Fells"): a page of the Fari
## Incunabulum, the Starlight Lantern (the Lantern with Lothelye's cold blue
## light in it), the waystone, and the trade chain's things and the
## Questlord's Shield. Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 5400


func run(materials: Dictionary) -> void:
	M = materials
	_page()
	_starlight_lantern()
	_star_flame()
	_sapphire_flame()
	_sapphire_orb()
	_prophecy()
	_trade_items()


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


## A page torn out of the Fari Incunabulum: yellowed vellum, a ragged edge,
## lines of cramped blue script and a sapphire-ink sigil. Stands upright,
## facing +Z, centered at the origin.
func _page() -> void:
	var k := _k()
	var vellum := _c("e0d0a8")
	k.box(Vector3(0, 0, 0), Vector3(0.36, 0.48, 0.012), vellum)
	# The torn edge: a few nicks out of the left side, darker where it ripped.
	for i in 5:
		k.box(Vector3(-0.185, -0.2 + i * 0.1, 0), Vector3(0.02, 0.05, 0.014), vellum.darkened(0.25))
	for i in 9:
		var w := 0.26 - (0.06 if i % 3 == 2 else 0.0)
		for s in [-1.0, 1.0]:
			k.box(Vector3(-0.01 - (0.26 - w) * 0.5, 0.17 - i * 0.04, s * 0.0065), Vector3(w, 0.012, 0.002), _c("2a3a6a"))
	k.smooth_normals(10.0)
	var mesh := k.build(M.char)
	var g := _k()
	for s in [-1.0, 1.0]:
		g.prism(Vector3(0.09, -0.15, s * 0.006), 0.045, Vector3(0.09, -0.15, s * 0.0075), 0.045, 6, _c("4a6ad8"))
	g.add_to(mesh, M.glow)
	_save(mesh, "incunabulum_page_mesh.tres")


## The Starlight Lantern: the Lantern's brass cage turned silver-blue, and in
## it Lothelye's starlight, a cold blue flame the Gauntlet cannot command.
## Hangs from its hook at the origin, like the Lantern.
func _starlight_lantern() -> void:
	var k := _k()
	var silver := _c("a8b8d8")
	k.prism(Vector3(0, -0.03, 0), 0.016, Vector3(0, 0.0, 0), 0.016, 6, silver.lightened(0.15))
	k.prism(Vector3(0, -0.07, 0), 0.075, Vector3(0, -0.035, 0), 0.0, 6, silver)
	k.prism(Vector3(0, -0.085, 0), 0.08, Vector3(0, -0.07, 0), 0.08, 6, silver.darkened(0.2))
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(cos(a) * 0.07, -0.16, sin(a) * 0.07), Vector3(0.012, 0.15, 0.012), silver.darkened(0.1))
	k.prism(Vector3(0, -0.25, 0), 0.08, Vector3(0, -0.235, 0), 0.08, 6, silver.darkened(0.2))
	k.prism(Vector3(0, -0.275, 0), 0.05, Vector3(0, -0.25, 0), 0.07, 6, silver)
	# A little star on the cap.
	for i in 4:
		var a := TAU * i / 4.0
		k.box(Vector3(cos(a) * 0.02, 0.012, sin(a) * 0.02), Vector3(0.012, 0.012, 0.012), _c("e8eeff"))
	k.smooth_normals(35.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.prism(Vector3(0, -0.235, 0), 0.06, Vector3(0, -0.085, 0), 0.06, 6, _c("90b8ff"))
	g.icosa(Vector3(0, -0.17, 0), Vector3(0.03, 0.05, 0.03), 0.0, _c("e0ecff"))
	g.add_to(mesh, M.glow)
	_save(mesh, "starlight_lantern_mesh.tres")


## Lothelye's starlight burning in a star brazier: the torch flame, cold blue
## and white.
func _star_flame() -> void:
	var f := _k()
	f.prism(Vector3(0, 0, 0), 0.12, Vector3(0, 0.12, 0), 0.14, 5, _c("6a9aff"))
	f.prism(Vector3(0, 0.12, 0), 0.14, Vector3(0, 0.45, 0), 0.0, 5, _c("e0ecff"))
	_save(f.build(M.glow), "star_flame_mesh.tres")


## The Sapphire Order's commanded fire: a tall violet-blue tongue (their
## wards and the braziers they hold).
func _sapphire_flame() -> void:
	var f := _k()
	f.prism(Vector3(0, 0, 0), 0.14, Vector3(0, 0.15, 0), 0.16, 5, _c("3a2ac8"))
	f.prism(Vector3(0, 0.15, 0), 0.16, Vector3(0, 0.6, 0), 0.0, 5, _c("8a6aff"))
	_save(f.build(M.glow), "sapphire_flame_mesh.tres")


## A bolt of the Order's fire (Incunax's spell): a violet-blue orb with a
## white heart.
func _sapphire_orb() -> void:
	var g := _k()
	g.icosa(Vector3.ZERO, Vector3(0.28, 0.28, 0.28), 0.0, _c("5a4aff"), true)
	g.icosa(Vector3.ZERO, Vector3(0.15, 0.15, 0.15), 0.0, _c("e8e4ff"), true)
	_save(g.build(M.glow), "sapphire_orb_mesh.tres")


## Bunsriel's Dark Prophecy: a thin black book with silver corners and a
## burning sigil on the cover. Lies flat, cover up (+Y), spine along X.
func _prophecy() -> void:
	var k := _k()
	k.box(Vector3(0, 0, 0), Vector3(0.36, 0.06, 0.26), _c("1a1418"))
	k.box(Vector3(0.0, 0.0, 0.005), Vector3(0.34, 0.04, 0.24), _c("d8c8a0"))
	for cx in [-0.17, 0.17]:
		for cz in [-0.12, 0.12]:
			k.box(Vector3(cx, 0.0, cz), Vector3(0.04, 0.065, 0.04), _c("b8bcc8"))
	k.box(Vector3(-0.17, 0, 0), Vector3(0.03, 0.065, 0.26), _c("2a2026"))
	var mesh := k.build(M.char)
	var g := _k()
	g.prism(Vector3(0.02, 0.031, 0), 0.06, Vector3(0.02, 0.034, 0), 0.06, 6, _c("e86a2a"))
	g.prism(Vector3(0.02, 0.034, 0), 0.03, Vector3(0.02, 0.036, 0), 0.03, 6, _c("ffd890"))
	g.add_to(mesh, M.glow)
	_save(mesh, "dark_prophecy_mesh.tres")


## The trade chain's things (TradeLines), each held up facing +Z:
## Clover's cracked starmetal horseshoe, Pink's charcoal sketch, Ottilie's
## library card, the armory ledger and the pattern page.
func _trade_items() -> void:
	# The horseshoe: a U of dark, star-flecked metal, cracked at the crown.
	var k := _k()
	var metal := _c("3a4058")
	for i in 11:
		var a := PI * (0.05 + 0.9 * i / 10.0)
		if i == 5:
			continue
		var p := Vector3(cos(a) * 0.14, sin(a) * 0.15 - 0.05, 0)
		k.box(p, Vector3(0.05, 0.05, 0.03), metal if i % 2 == 0 else metal.lightened(0.15))
	for i in 6:
		var a := PI * (0.1 + 0.8 * i / 5.0)
		k.box(Vector3(cos(a) * 0.14, sin(a) * 0.15 - 0.05, 0.016), Vector3(0.012, 0.012, 0.004), _c("e8eeff"))
	_save(k.build(M.char), "trade_horseshoe_mesh.tres")
	# Pink's sketch: a sheet of rough paper with a shield in charcoal.
	k = _k()
	k.box(Vector3.ZERO, Vector3(0.3, 0.34, 0.006), _c("e8dcc4"))
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(cos(a) * 0.08, sin(a) * 0.1, 0.004), Vector3(0.03, 0.03, 0.002), _c("3a3634"))
	k.box(Vector3(0.0, 0.0, 0.004), Vector3(0.012, 0.14, 0.002), _c("3a3634"))
	k.box(Vector3(0.1, 0.12, 0.004), Vector3(0.04, 0.05, 0.002), _c("6a6664"))
	_save(k.build(M.char), "trade_sketch_mesh.tres")
	# Ottilie's library card: a stiff green card with gold lettering.
	k = _k()
	k.box(Vector3.ZERO, Vector3(0.26, 0.16, 0.008), _c("2e6a4a"))
	k.box(Vector3(0, 0.04, 0.005), Vector3(0.2, 0.02, 0.002), _c("d8b050"))
	for j in 3:
		k.box(Vector3(-0.02, -0.01 - j * 0.03, 0.005), Vector3(0.16, 0.008, 0.002), _c("e8e0c0"))
	_save(k.build(M.char), "trade_card_mesh.tres")
	# The armory ledger: a fat book in brown leather with brass corners.
	k = _k()
	k.box(Vector3.ZERO, Vector3(0.28, 0.36, 0.09), _c("5a3a24"))
	k.box(Vector3(0.01, 0, 0), Vector3(0.27, 0.34, 0.07), _c("e0d4b0"))
	for cx in [-0.13, 0.13]:
		for cy in [-0.17, 0.17]:
			k.box(Vector3(cx, cy, 0.046), Vector3(0.04, 0.04, 0.004), _c("b89a48"))
	k.box(Vector3(0, 0.05, 0.047), Vector3(0.14, 0.05, 0.004), _c("8a2a2a"))
	_save(k.build(M.char), "trade_ledger_mesh.tres")
	# The pattern page: an old yellowed page with the shield drawn in blue ink.
	k = _k()
	k.box(Vector3.ZERO, Vector3(0.28, 0.36, 0.006), _c("d8c898"))
	k.box(Vector3(0, 0.02, 0.004), Vector3(0.14, 0.18, 0.002), _c("2a3a7a"))
	k.box(Vector3(0, 0.02, 0.005), Vector3(0.1, 0.14, 0.002), _c("c8b888"))
	k.box(Vector3(0, 0.02, 0.006), Vector3(0.016, 0.14, 0.002), _c("2a3a7a"))
	k.box(Vector3(0.08, -0.14, 0.004), Vector3(0.06, 0.04, 0.002), _c("a89868"))
	_save(k.build(M.char), "trade_page_mesh.tres")
