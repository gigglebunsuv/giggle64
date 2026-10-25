extends RefCounted
## Paints the item and gear meshes, after the generators have built them.
##
## Every diffuse surface gets UVs into one 96x96 painted material atlas
## (assets/textures/item_atlas.png: wood, leather, metal, cloth, parchment,
## glass, brass, crystal, pottery in 32x32 cells), picked per triangle from its
## vertex color. Box projection keeps each face inside one cell. Vertex colors
## still carry each item's identity; the atlas only adds painted detail. A few
## items gain small fittings (bow grip wraps, hookshot collars, bag fasteners).
## Chrome blades and glowing surfaces keep their own materials.
## From the prototypes/oot_assets_02 study (remaster.gd there).

const MeshKit := preload("res://tools/mesh_kit.gd")
const MODEL_DIR := "res://assets/models/"
const ATLAS := "res://assets/textures/item_atlas.png"
const KEEP := ["chrome.tres", "glow.tres"]

const ITEMS := [
	"alans_harvest", "aphiels_gale", "arrow", "astral_seal", "big_wallet", "bloom_rod", "bomb_bag", "bomb",
	"boomerang", "boots_anchor", "boots_leather", "boots_wind", "boss_key", "bottle_empty", "bottle_fairy",
	"bottle_fish", "bottle_half_milk", "bottle_milk", "bottle_red_potion", "bow", "bun_bracers",
	"bun_piece_alan", "bun_piece_aphiel", "bun_piece_serielye", "chart_scrap", "chest_base", "chest_lid",
	"compass", "ember_rod", "fishing_rod_icon", "frost_arrow", "giant_wallet", "golden_scale", "grave_spade",
	"heart_container", "heart", "heart_piece", "hookshot", "iron_flail", "iron_mallet", "lantern", "longshot",
	"looking_glass", "lothelyes_dream", "magic_large", "magic_small", "pot", "puff_nut",
	"questlord_gauntlets", "quiver", "rupee_blue", "rupee_gold", "rupee_green", "rupee_purple", "rupee_red",
	"sapphire_staff", "serielyes_ruin", "starfall_arrow", "starlight_lantern", "sugar_cube", "sun_arrow",
	"silver_scale", "small_key", "trade_card", "trade_horseshoe", "trade_ledger", "trade_page",
	"trade_sketch", "tunic_frost", "tunic_haven", "tunic_knight", "tunic_regalia", "tunic_shade", "tunic_tide",
]

var solid: ShaderMaterial
var glass: ShaderMaterial


func run() -> void:
	solid = _material("item")
	glass = _material("item_glass")
	var names: Array[String] = []
	for n: String in ITEMS:
		names.append(n + "_mesh")
	# All the swords, scabbards and shields: held, sheathed, on the back, flat
	# (pickups and icons) and each companion's styled set.
	for f in DirAccess.get_files_at(MODEL_DIR):
		if f.ends_with("_mesh.tres") and (f.begins_with("sword_") or f.begins_with("scabbard_") or f.begins_with("shield_")) \
				and f != "sword_beam_mesh.tres":
			names.append(f.trim_suffix(".tres"))
	var done := 0
	for n in names:
		var path := MODEL_DIR + n + ".tres"
		if not ResourceLoader.exists(path):
			push_error("remaster_items: no %s" % path)
			continue
		var mesh: ArrayMesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if _painted(mesh):
			continue
		_paint(mesh, n)
		if ResourceSaver.save(mesh, path) != OK:
			push_error("remaster_items: could not save %s" % path)
		done += 1
	print("remaster_items: painted %d meshes" % done)


## Shared material file, so every mesh points at the same two materials.
func _material(shader: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/shaders/%s.gdshader" % shader)
	m.set_shader_parameter("atlas", load(ATLAS))
	var path := "res://assets/materials/%s.tres" % shader
	ResourceSaver.save(m, path)
	return load(path)


## Already painted (this step was run again without regenerating the items).
func _painted(mesh: ArrayMesh) -> bool:
	for s in mesh.get_surface_count():
		var m := mesh.surface_get_material(s)
		if m != null and m.resource_path.get_file() in ["item.tres", "item_glass.tres"]:
			return true
	return false


## Rebuilds the mesh in place (same file, same uid), surface by surface.
func _paint(mesh: ArrayMesh, mesh_name: String) -> void:
	var work := mesh.duplicate(true) as ArrayMesh
	var extra = _details(mesh_name)
	if extra != null:
		extra.add_to(work, StandardMaterial3D.new())
	mesh.clear_surfaces()
	for s in work.get_surface_count():
		var arr := work.surface_get_arrays(s)
		var mat := work.surface_get_material(s)
		if mat != null and mat.resource_path.get_file() in KEEP:
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
			continue
		var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if indices.is_empty():
			for i in pos.size():
				indices.append(i)
		# Bounds per material cell, so a small leather grip is not squeezed into
		# the blade's UV range.
		var bounds := {}
		for i in indices:
			var tile := _tile(mesh_name, _col(cols, i), pos[i])
			bounds[tile] = (bounds[tile] as AABB).expand(pos[i]) if bounds.has(tile) else AABB(pos[i], Vector3.ZERO)
		var uv := PackedVector2Array()
		var out_pos := PackedVector3Array()
		var out_norm := PackedVector3Array()
		var out_col := PackedColorArray()
		var see_through := mat != null and mat.resource_path.get_file() == "glass.tres"
		for t in range(0, indices.size(), 3):
			var i0 := indices[t]
			var tile := _tile(mesh_name, _col(cols, i0), pos[i0])
			var b: AABB = bounds[tile]
			var axis := (pos[indices[t + 1]] - pos[i0]).cross(pos[indices[t + 2]] - pos[i0]).abs().max_axis_index()
			for j in 3:
				var idx := indices[t + j]
				var rel := (pos[idx] - b.position) / Vector3(maxf(b.size.x, 0.0001), maxf(b.size.y, 0.0001), maxf(b.size.z, 0.0001))
				var c := Vector2(rel.x, 1.0 - rel.y)
				if axis == 0:
					c = Vector2(rel.z, 1.0 - rel.y)
				elif axis == 1:
					c = Vector2(rel.x, rel.z)
				# One-texel inset keeps bilinear filtering inside the cell.
				uv.append((Vector2(tile % 3, tile / 3) * 32.0 + Vector2.ONE + c.clamp(Vector2.ZERO, Vector2.ONE) * 30.0) / 96.0)
				out_pos.append(pos[idx])
				out_norm.append(norms[idx])
				var col := _col(cols, idx)
				see_through = see_through or col.a < 0.98
				out_col.append(col)
		var out := []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = out_pos
		out[Mesh.ARRAY_NORMAL] = out_norm
		out[Mesh.ARRAY_COLOR] = out_col
		out[Mesh.ARRAY_TEX_UV] = uv
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
		mesh.surface_set_material(mesh.get_surface_count() - 1, glass if see_through else solid)


func _col(cols: PackedColorArray, i: int) -> Color:
	return cols[i] if not cols.is_empty() else Color.WHITE


## Atlas cell: 0 wood, 1 leather, 2 metal, 3 cloth, 4 parchment, 5 glass,
## 6 brass, 7 crystal, 8 pottery.
func _tile(mesh_name: String, c: Color, p: Vector3) -> int:
	if c.a < 0.98:
		return 5
	var brown := c.r > c.g * 1.18 and c.g > c.b * 1.12
	var gold := c.r > c.b * 1.4 and c.g > c.r * 0.7 and c.r > 0.48
	if mesh_name.begins_with("trade_") or mesh_name == "chart_scrap_mesh":
		if "horseshoe" in mesh_name:
			return 2
		if "ledger" in mesh_name:
			return 6 if gold else 1
		return 4
	if gold:
		return 6
	if "tunic" in mesh_name:
		return 1 if brown else 3
	if "wallet" in mesh_name or "bomb_bag" in mesh_name or "quiver" in mesh_name:
		return 1
	if "boots" in mesh_name or "bracers" in mesh_name:
		return 1 if brown else 2
	if "bottle" in mesh_name:
		return 0 if brown else 7
	if "pot_" in mesh_name or "bun_piece" in mesh_name or "puff_nut" in mesh_name:
		return 8
	if mesh_name == "bow_mesh" and absf(p.z) < 0.09:
		return 1
	if brown:
		return 0
	for k in ["heart", "harvest", "gale", "ruin", "seal", "dream", "magic_"]:
		if k in mesh_name:
			return 7
	return 2


## Small fittings added to a few items, built with MeshKit like the items themselves.
func _details(mesh_name: String):
	var k := MeshKit.new(42)
	k.textured = true
	var brass := Color("c4a461")
	var leather := Color("69432e")
	if mesh_name == "bow_mesh":
		for z in [-0.075, -0.045, -0.015, 0.015, 0.045, 0.075]:
			k.box(Vector3(0, 0, z), Vector3(0.057, 0.058, 0.014), leather)
		for z in [-0.42, 0.42]:
			k.box(Vector3(0, 0.073, z), Vector3(0.035, 0.036, 0.025), brass)
	elif mesh_name in ["hookshot_mesh", "longshot_mesh"]:
		for z in [-0.02, -0.19, -0.26]:
			k.push(Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0, z)))
			k.prism(Vector3(0, -0.009, 0), 0.057, Vector3(0, 0.009, 0), 0.057, 8, brass)
			k.pop()
		for x in [-0.054, 0.054]:
			k.icosa(Vector3(x, 0, -0.1), Vector3(0.008, 0.012, 0.012), 0.0, brass)
	elif mesh_name == "bomb_mesh":
		k.prism(Vector3(0, 0.335, 0), 0.071, Vector3(0, 0.35, 0), 0.071, 8, brass)
	elif mesh_name == "boomerang_mesh":
		for side in [-1.0, 1.0]:
			k.prism(Vector3(0.065 * side, 0.023, -0.045), 0.008, Vector3(0.19 * side, 0.018, -0.135), 0.005, 4, brass)
	elif mesh_name in ["big_wallet_mesh", "giant_wallet_mesh", "bomb_bag_mesh"]:
		var at := Vector3(0, 0.12, 0.088)
		if mesh_name == "giant_wallet_mesh":
			at = Vector3(0, 0.02, 0.111)
		elif mesh_name == "bomb_bag_mesh":
			at = Vector3(0, 0.14, 0.164)
		k.box(at, Vector3(0.043, 0.055, 0.012), leather)
		k.icosa(at + Vector3(0, 0.015, 0.009), Vector3(0.012, 0.012, 0.006), 0.0, brass)
	else:
		return null
	return k
