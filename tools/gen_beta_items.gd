extends RefCounted
## Meshes for Beta 1.0.0 ("The Gauntlet's Trail"): the tunics and Himeko's
## Knight's Regalia (each shown folded over a little wooden hanger, as the
## pause screen and the get-item scene hold them up), the Bun Bracers, the
## Silver and Golden Scales, the Giant Wallet, the heavy rock and its chips,
## Tansy's cups and table, the rooster, the mallet stake, and the fish
## outlines on Mira's record board. Saved as .tres meshes in res://assets/models/.

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"

var M: Dictionary
var _seed := 5200


func run(materials: Dictionary) -> void:
	M = materials
	for id: String in Equipment.TUNIC_ORDER:
		_tunic(id, Equipment.TUNICS[id].palette)
	_tunic("regalia", Equipment.VANITY.regalia.palette, true)
	# The Knight's Tabard (Chapter V): silver trim and a Haven-blue cape.
	_tunic("knight", Equipment.VANITY.knight.palette, true, "d8dce4", "2a4a92")
	_bracers()
	_scale("silver", _c("c8d4e0"), _c("f4f8ff"))
	_scale("golden", _c("e8b838"), _c("fff2b0"))
	_giant_wallet()
	_heavy_rock()
	_cup()
	_cup_table()
	_rooster()
	_stake()
	_fish_outline()
	_ice_sheet()


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


## A tunic on a wooden hanger: the body lofted from hem to shoulders, short
## sleeves out to the sides, a belt and a collar. `palette` swaps the Haven
## Tunic's red (as on the hero's model); the regalia gets its gold trim and
## a little crimson cape behind.
func _tunic(id: String, palette: Dictionary, regalia := false, trim_hex := "d8b050", cape_hex := "b01e2a") -> void:
	var swap := func(h: String) -> Color: return _c(String(palette.get(h, h)))
	var body: Color = swap.call("8c1d17")
	var light: Color = swap.call("a3261d")
	var dark: Color = swap.call("6a140f")
	var belt: Color = swap.call("5a3820")
	var k := _k()
	k.loft([
		[-0.34, 0.2, 0.06, dark], [-0.3, 0.2, 0.065, body], [-0.1, 0.17, 0.06, body],
		[0.05, 0.16, 0.055, light], [0.16, 0.18, 0.055, body], [0.22, 0.1, 0.045, dark], [0.24, 0.0, 0.0, dark],
	], 10)
	k.loft([[-0.12, 0.172, 0.064, belt], [-0.07, 0.168, 0.062, belt]], 10)
	k.box(Vector3(0, -0.095, -0.064), Vector3(0.05, 0.04, 0.01), _c(trim_hex) if regalia else _c("c9a64e"))
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, sx * 1.2), Vector3(sx * 0.15, 0.15, 0)))
		k.loft([[0.0, 0.06, 0.05, body], [0.1, 0.055, 0.045, light], [0.14, 0.05, 0.04, dark], [0.15, 0.0, 0.0, dark]], 7)
		k.pop()
	# The hanger and its hook.
	k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(0, 0.22, 0)))
	k.prism(Vector3(0, -0.22, 0), 0.012, Vector3(0, 0.22, 0), 0.012, 6, _c("8a6040"))
	k.pop()
	k.prism(Vector3(0, 0.22, 0), 0.006, Vector3(0, 0.3, 0), 0.006, 4, _c("a8acb4"))
	k.prism(Vector3(0, 0.3, 0), 0.006, Vector3(0.03, 0.32, 0), 0.006, 4, _c("a8acb4"))
	if regalia:
		# Gold trim at the hem and collar, and the cape hanging behind.
		k.loft([[-0.345, 0.205, 0.068, _c(trim_hex)], [-0.325, 0.205, 0.068, _c(trim_hex)]], 10)
		k.loft([[0.2, 0.13, 0.05, _c(trim_hex)], [0.215, 0.11, 0.048, _c(trim_hex)]], 10)
		k.slab(Vector3(0, 0.2, 0.07), Vector2(0.36, 0.01), Vector3(0, -0.35, 0.1), Vector2(0.44, 0.01), _c(cape_hex))
		k.slab(Vector3(0, -0.33, 0.1), Vector2(0.44, 0.012), Vector3(0, -0.36, 0.105), Vector2(0.45, 0.012), _c(trim_hex))
	elif id == "frost":
		# Fur at the collar and hem.
		for y in [-0.33, 0.19]:
			k.loft([[y - 0.02, 0.21 if y < 0 else 0.15, 0.08, _c("f8f8fa")], [y + 0.02, 0.21 if y < 0 else 0.15, 0.08, _c("e8eaee")]], 10)
	elif id == "shade":
		# A deep hood at the back.
		k.icosa(Vector3(0, 0.22, 0.05), Vector3(0.11, 0.09, 0.08), 0.1, dark)
	elif id == "tide":
		# Shell clasps down the front.
		for y in [0.1, 0.0]:
			k.icosa(Vector3(0, y, -0.06), Vector3(0.018, 0.018, 0.01), 0.0, _c("f0e8dc"))
	k.smooth_normals(50.0)
	_save(k.build(M.char), "tunic_%s_mesh.tres" % id)


## The Bun Bracers: a pair of leather cuffs with gold bands, each stamped with
## a golden bun.
func _bracers() -> void:
	var k := _k()
	for sx in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0) * Basis(Vector3.UP, sx * 0.2), Vector3(sx * 0.1, 0, 0)))
		k.prism(Vector3(0, -0.07, 0), 0.055, Vector3(0, 0.07, 0), 0.05, 10, _c("6a4630"))
		for y in [-0.06, 0.06]:
			k.prism(Vector3(0, y - 0.01, 0), 0.058, Vector3(0, y + 0.01, 0), 0.058, 10, _c("d8b050"))
		k.icosa(Vector3(0, 0, -0.058), Vector3(0.024, 0.02, 0.012), 0.0, _c("f0c860"))
		k.pop()
	k.smooth_normals(45.0)
	_save(k.build(M.char), "bun_bracers_mesh.tres")


## A scale: a broad teardrop leaf with a raised rib, glinting at its tip.
func _scale(kind: String, col: Color, glint: Color) -> void:
	var k := _k()
	k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	k.loft([
		[-0.11, 0.0, 0.0, col.darkened(0.2)], [-0.08, 0.06, 0.015, col], [0.0, 0.085, 0.018, col.lightened(0.1)],
		[0.06, 0.06, 0.015, col], [0.1, 0.0, 0.0, col.darkened(0.1)],
	], 9)
	k.pop()
	k.box(Vector3(0, 0, -0.02), Vector3(0.012, 0.17, 0.006), col.lightened(0.2))
	k.smooth_normals(60.0)
	var mesh := k.build(M.char)
	var g := _k()
	g.icosa(Vector3(0.0, 0.07, -0.02), Vector3(0.016, 0.016, 0.006), 0.0, glint)
	g.add_to(mesh, M.glow)
	_save(mesh, "%s_scale_mesh.tres" % kind)


## The Giant Wallet: a fat purple purse with a gold clasp and a rupee charm.
func _giant_wallet() -> void:
	var k := _k()
	var cloth := _c("6a3a8a")
	k.loft([
		[-0.12, 0.08, 0.06, cloth.darkened(0.25)], [-0.08, 0.16, 0.1, cloth], [0.02, 0.17, 0.11, cloth.lightened(0.1)],
		[0.1, 0.13, 0.08, cloth], [0.13, 0.06, 0.04, cloth.darkened(0.2)], [0.14, 0.0, 0.0, cloth.darkened(0.2)],
	], 10)
	k.prism(Vector3(0, 0.12, 0), 0.03, Vector3(0, 0.16, 0), 0.035, 8, _c("d8b050"))
	k.push(Transform3D(Basis(Vector3.UP, 0.4), Vector3(0, -0.02, -0.11)))
	k.prism(Vector3(0, -0.04, 0), 0.0, Vector3(0, 0.0, 0), 0.03, 6, _c("e04040"))
	k.prism(Vector3(0, 0.0, 0), 0.03, Vector3(0, 0.04, 0), 0.0, 6, _c("ff7070"))
	k.pop()
	k.smooth_normals(55.0)
	_save(k.build(M.char), "giant_wallet_mesh.tres")


## A heavy rock (the Bun Bracers lift it): a big dark boulder, about 1.2 m
## across, with a pale vein so it reads as different from the small ones.
func _heavy_rock() -> void:
	var k := _k(true)
	k.icosa(Vector3(0, 0.55, 0), Vector3(0.68, 0.58, 0.62), 0.16, _c("5a5650"), true)
	k.icosa(Vector3(0.18, 0.95, -0.1), Vector3(0.3, 0.22, 0.28), 0.12, _c("6a645c"))
	k.box(Vector3(-0.2, 0.62, -0.55), Vector3(0.6, 0.06, 0.04), _c("b8b0a0"))
	_save(k.build(M.rock if M.has("rock") else M.char), "heavy_rock_mesh.tres")


## One of Tansy's cups: a tall copper cup upside down (the open end at the bottom).
func _cup() -> void:
	var k := _k()
	var copper := _c("b8683a")
	k.loft([
		[0.0, 0.11, 0.11, copper.darkened(0.25)], [0.02, 0.105, 0.105, copper], [0.18, 0.08, 0.08, copper.lightened(0.12)],
		[0.22, 0.075, 0.075, copper], [0.24, 0.0, 0.0, copper.lightened(0.2)],
	], 12, false)
	k.prism(Vector3(0, 0.0, 0), 0.112, Vector3(0, 0.025, 0), 0.112, 12, _c("d8b050"))
	k.smooth_normals(50.0)
	_save(k.build(M.char), "shell_cup_mesh.tres")


## Tansy's folding table with its striped cloth, 0.8 m high.
func _cup_table() -> void:
	var k := _k()
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(sx * 0.5, 0.38, sz * 0.28), Vector3(0.05, 0.76, 0.05), _c("6a4a30"))
	k.box(Vector3(0, 0.78, 0), Vector3(1.2, 0.04, 0.7), _c("8a5a3a"))
	for i in 6:
		k.box(Vector3(-0.5 + i * 0.2, 0.805, 0), Vector3(0.2, 0.012, 0.72), _c("c83a3a") if i % 2 == 0 else _c("f0e8d8"))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(sx * 0.6, 0.66, 0), Vector3(0.012, 0.25, 0.72), _c("c83a3a"))
	k.box(Vector3(0, 0.66, -0.36), Vector3(1.22, 0.25, 0.012), _c("c83a3a"))
	_save(k.build(M.char), "cup_table_mesh.tres")


## The rooster of Haven: a plump white body, a red comb and wattle, a golden
## beak, a fan of dark tail feathers and little orange legs. About 0.5 m tall,
## facing -Z.
func _rooster() -> void:
	var k := _k()
	var white := _c("f4f0e8")
	k.icosa(Vector3(0, 0.3, 0.02), Vector3(0.16, 0.14, 0.2), 0.05, white, true)
	k.icosa(Vector3(0, 0.44, -0.12), Vector3(0.08, 0.09, 0.08), 0.03, white)
	k.prism(Vector3(0, 0.44, -0.19), 0.025, Vector3(0, 0.43, -0.25), 0.0, 4, _c("e8b030"))
	for i in 3:
		k.icosa(Vector3(0, 0.53 + i * 0.005, -0.15 + i * 0.035), Vector3(0.012, 0.035, 0.02), 0.0, _c("e02828"))
	k.icosa(Vector3(0, 0.39, -0.19), Vector3(0.012, 0.03, 0.015), 0.0, _c("d82020"))
	for i in 5:
		var a := -0.7 + i * 0.35
		k.push(Transform3D(Basis(Vector3.BACK, a * 0.5) * Basis(Vector3.RIGHT, -0.6), Vector3(0, 0.36, 0.18)))
		k.slab(Vector3.ZERO, Vector2(0.04, 0.01), Vector3(0, 0.22, 0), Vector2(0.015, 0.006), _c("2a2a3a") if i % 2 == 0 else _c("3a5a4a"))
		k.pop()
	for sx in [-1.0, 1.0]:
		k.icosa(Vector3(sx * 0.15, 0.3, 0.03), Vector3(0.025, 0.08, 0.12), 0.0, white.darkened(0.08))
		k.prism(Vector3(sx * 0.06, 0.18, 0.02), 0.012, Vector3(sx * 0.06, 0.0, 0.0), 0.01, 4, _c("e89030"))
		k.box(Vector3(sx * 0.06, 0.005, -0.03), Vector3(0.05, 0.01, 0.08), _c("e89030"))
	k.smooth_normals(55.0)
	var mesh := k.build(M.char)
	var g := _k()
	for sx in [-1.0, 1.0]:
		g.icosa(Vector3(sx * 0.07, 0.46, -0.16), Vector3(0.012, 0.012, 0.008), 0.0, _c("101010"))
	g.add_to(mesh, M.char)
	_save(mesh, "rooster_mesh.tres")


## A stake for the Iron Mallet: a thick wooden post with an iron cap, 0.7 m
## out of the ground (it sinks as it is driven in).
func _stake() -> void:
	var k := _k()
	k.prism(Vector3(0, -0.6, 0), 0.0, Vector3(0, -0.4, 0), 0.16, 6, _c("6a4a30"))
	k.prism(Vector3(0, -0.4, 0), 0.16, Vector3(0, 0.6, 0), 0.16, 6, _c("7a5838"))
	k.prism(Vector3(0, 0.6, 0), 0.19, Vector3(0, 0.72, 0), 0.19, 6, _c("5a5e68"))
	for y in [0.0, 0.35]:
		k.prism(Vector3(0, y, 0), 0.168, Vector3(0, y + 0.05, 0), 0.168, 6, _c("4a4e58"))
	_save(k.build(M.char), "mallet_stake_mesh.tres")


## A fish outline cut from pale wood, for Mira's record board (0.5 m long, facing +Z).
func _fish_outline() -> void:
	var k := _k()
	var wood := _c("d8c8a8")
	k.push(Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))
	k.loft([
		[-0.25, 0.0, 0.0, wood], [-0.2, 0.06, 0.012, wood], [-0.05, 0.1, 0.015, wood.lightened(0.05)],
		[0.12, 0.06, 0.012, wood], [0.18, 0.02, 0.01, wood],
	], 8)
	k.pop()
	k.slab(Vector3(0.17, 0, 0), Vector2(0.01, 0.01), Vector3(0.27, 0, 0), Vector2(0.14, 0.012), wood.darkened(0.1))
	k.icosa(Vector3(-0.19, 0.02, 0.012), Vector3(0.012, 0.012, 0.006), 0.0, _c("2a2018"))
	_save(k.build(M.char), "fish_outline_mesh.tres")


## The frozen falls sealing Frostpeak Hollow: a sheet of blue-white ice, 4 m
## wide and 5 m high, rippled like water caught falling. The Iron Mallet
## shatters it.
func _ice_sheet() -> void:
	var k := _k()
	for i in 7:
		var x := -1.8 + i * 0.6
		var w := 0.34 + 0.08 * sin(i * 1.7)
		k.prism(Vector3(x, 0.0, 0.0), w, Vector3(x + 0.05 * sin(i * 2.3), 5.0, -0.05), w * 0.85, 6,
			_c("bfe0f4").lerp(_c("e8f6ff"), 0.5 + 0.5 * sin(i * 1.3)), 0.3 * i)
	k.box(Vector3(0, 2.5, 0.12), Vector3(4.0, 5.0, 0.2), _c("a8d0ec"))
	_save(k.build(M.glow), "ice_sheet_mesh.tres")
