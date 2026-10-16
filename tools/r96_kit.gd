extends RefCounted
class_name R96Kit
## Render96-style remaster pass for the promo renders (never used in game).
## Takes a loaded character model and swaps every mesh for a smooth,
## high-poly version: two levels of Loop subdivision, where the first level
## keeps sharp edges creased (so boxes and loft caps come out bevelled rather
## than melted) and the second smooths everything. Vertex colors and UVs are
## carried along per face corner, so color bands and painted faces stay put.
## Materials become per-pixel, softly glossy "CGI" plastic, and painted faces
## can be swapped for hand-painted HD versions.

## Edges folding more than this (degrees between face normals) count as creases
## on the first level. Lofts have 5-10 sides (36-72 degrees), so they stay round.
const CREASE_DEG := 78.0
## Node names whose meshes stay crisp-edged (blades, shields, gems).
const RIGID := ["Sword", "Shield", "Broadsword", "Blade", "Bow", "Gem", "Crown", "Fan"]

static var hd_faces := {}   # "face_mira" -> Texture2D

const PAINTED := preload("res://tools/r96_painted.gdshader")
const PATTERNS := {"cloth": 0, "skin": 1, "leather": 2, "metal": 3, "gold": 4, "damask": 5, "sakura": 6, "stars": 7, "enamel": 8, "quilt": 9}

## Which painted look each of a character's colors gets: [hexes, pattern,
## roughness, accent, accent2]. Colors not listed fall back to "cloth"
## (rigid gear to "enamel").
const PALETTES := {
	"gigglebuns": [
		[["8c1d17", "a3261d", "6a140f"], "damask", 0.6, "e0b050"],
		[["9b9ea3", "80838a"], "quilt", 0.75],
		[["2b2b31", "3a3a42", "19191d", "6e4630", "573522", "5a3820", "6b4529", "2b2b30", "3a3a40", "4a2f1c", "5a3a22", "1c4a26", "2e7040"], "leather", 0.55],
		[["c9a64e", "e8b830"], "gold", 0.3],
		[["f0c040", "ffe890"], "enamel", 0.12],
		[["e3b08a", "c9946e", "efc39f"], "skin", 0.6],
		[["d8a840", "b08428"], "damask", 0.4, "fff0b0"],
		[["a01c26", "6e1018"], "cloth", 0.45],
		[["c01828"], "enamel", 0.12],
	],
	"mira": [
		[["2e7d7a", "3a9894", "235f5d"], "cloth", 0.7],
		[["ece2c8", "d4c8a8"], "quilt", 0.75],
		[["f4f0e6", "dcd6c8"], "cloth", 0.65],
		[["e0405a", "b02a40"], "cloth", 0.32],
		[["5a3a28", "3e2818", "3a3040"], "leather", 0.5],
		[["f0c8a8", "d8a888"], "skin", 0.6],
	],
	"himeko": [
		[["b8182a", "d02a3a", "8a1020"], "sakura", 0.45, "f0c040", "ffd0de"],
		[["e0b84a", "f4d878", "b08a2a"], "damask", 0.35, "fff0b0"],
		[["c8203a"], "enamel", 0.3],
		[["fae6d8", "ead0be"], "skin", 0.6],
	],
	"firebuns": [
		[["a89a6a", "c8ba84", "7e7048"], "gold", 0.35],
		[["a83a30", "7a2620"], "damask", 0.55, "e0a040"],
		[["6a4a8a", "4a3466"], "cloth", 0.5],
		[["3a3048"], "quilt", 0.7],
		[["f6d2a6", "dcb088"], "skin", 0.6],
	],
	"mara": [
		[["26222a", "3a343e", "16131a"], "metal", 0.3],
		[["8a6a3a"], "gold", 0.35],
		[["6a1420", "440c14"], "cloth", 0.55],
		[["b8b0b8", "8e8690"], "skin", 0.55],
	],
	"lothelye": [
		[["f4f2fa", "ffffff", "d8d4ea"], "damask", 0.45, "c8c8ff"],
		[["3a3a8a", "1e1e5a"], "stars", 0.5, "ffe8a0"],
		[["e8c060", "fff0a0"], "gold", 0.3],
		[["e6e0f6"], "cloth", 0.5],
		[["fbf0ea", "eadad2"], "skin", 0.6],
	],
}

static var palette: Array = []


## Remasters every MeshInstance3D under `model`. `levels` = subdivision levels.
## `hair` names an R96Hair style: the game's hair on the head is stripped
## (by its colors) and the sculpted hair mesh goes on in its place.
static func remaster(model: Node, levels := 2, gloss := 0.5, hair := "") -> void:
	var cache := {}
	palette = []
	for rule: Array in PALETTES.get(hair, []):
		var cs: Array[Color] = []
		for hx: String in rule[0]:
			cs.append(Color.html(hx))
		palette.append([cs] + rule.slice(1))
	var strip: Array = R96Hair.STRIP.get(hair, [])
	var head := model.find_child("Head", true, false) as Node3D
	for n in model.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not (mi.mesh is ArrayMesh):
			continue
		if hair != "" and head and head.is_ancestor_of(mi):
			# The head is rebuilt: the old face wrap and nose go, the sculpted
			# head (R96Head) and hair take their place.
			var face_mat: Material = null
			var am := mi.mesh as ArrayMesh
			for si in am.get_surface_count():
				var bm := am.surface_get_material(si) as BaseMaterial3D
				if bm and bm.albedo_texture:
					face_mat = bm
			mi.mesh = _remaster_mesh(am, levels, false, gloss, strip, true, hair == "gigglebuns")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if face_mat:
				var skin_mat := _material(face_mat, gloss).duplicate() as StandardMaterial3D
				skin_mat.albedo_texture = null
				var hm := MeshInstance3D.new()
				hm.name = "R96Head"
				var fm := _material(face_mat, gloss) as StandardMaterial3D
				var skin := Color(0.9, 0.7, 0.55)
				if fm.albedo_texture:
					var img := fm.albedo_texture.get_image()
					skin = img.get_pixel(int(img.get_width() * 0.5), int(img.get_height() * 0.455))
				skin_mat.vertex_color_is_srgb = true
				hm.mesh = R96Head.build(hair, fm, skin_mat, skin, skin.darkened(0.15))
				mi.get_parent().add_child(hm)
				hm.transform = mi.transform
			continue
		var rigid := false
		var p: Node = mi
		while p and p != model:
			for r: String in RIGID:
				if String(p.name).begins_with(r) or String(p.name).contains(r):
					rigid = true
			p = p.get_parent()
		var key := "%s|%s" % [mi.mesh.get_rid(), rigid]
		# Blades stay crisp: smoothed normals, no subdivision.
		var blade := false
		var q: Node = mi
		while q and q != model:
			if String(q.name) in ["Sword", "SheathedSword", "Broadsword", "LuminousBlade"]:
				blade = true
			q = q.get_parent()
		if not cache.has(key):
			cache[key] = _remaster_mesh(mi.mesh as ArrayMesh, 0 if blade else levels, rigid, gloss)
		mi.mesh = cache[key]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if hair != "" and head:
		var hm := R96Hair.style(hair)
		if hm:
			var hmi := MeshInstance3D.new()
			hmi.name = "R96Hair"
			hmi.mesh = hm
			head.add_child(hmi)
		# The sculpted head is shorter than the game's: lower everything on it.
		for c in head.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).position.y -= R96Head.DROP


static func _remaster_mesh(src: ArrayMesh, levels: int, rigid: bool, gloss: float, strip: Array = [], new_head := false, no_ears := false) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var mat := src.surface_get_material(s)
		if src.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			out.add_surface_from_arrays(src.surface_get_primitive_type(s), arr)
			out.surface_set_material(out.get_surface_count() - 1, mat)
			continue
		if new_head and mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture:
			continue
		var m := Sub.from_arrays(arr, strip, new_head, no_ears)
		if m.tris.is_empty():
			continue
		var glow := _is_glow(mat)
		if not glow:
			for l in levels:
				var crease := CREASE_DEG if (l == 0 or rigid) else 999.0
				if rigid and l > 0:
					crease = 40.0
				m = m.subdivide(crease)
		var textured := mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture != null
		if glow or textured or palette.is_empty() and not rigid:
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, m.to_arrays(40.0 if rigid else 70.0))
			out.surface_set_material(out.get_surface_count() - 1, mat if glow else _material(mat, gloss))
			continue
		var parts := m.split_by_class(func(c: Color) -> int: return _classify(c, rigid))
		for k: int in parts:
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, (parts[k] as Sub).to_arrays(40.0 if rigid else 70.0))
			out.surface_set_material(out.get_surface_count() - 1, _painted(k, rigid))
	return out


static func _is_glow(mat: Material) -> bool:
	var b := mat as BaseMaterial3D
	return b != null and b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED


static var _mat_cache := {}
static var _painted_cache := {}


## Index of the palette rule matching `c` (-1: default).
static func _classify(c: Color, rigid: bool) -> int:
	var best := -1
	var bd := 0.16
	for i in palette.size():
		for pc: Color in palette[i][0]:
			var d := absf(c.r - pc.r) + absf(c.g - pc.g) + absf(c.b - pc.b)
			if d < bd:
				bd = d
				best = i
	return best


static func _painted(k: int, rigid: bool) -> Material:
	var key := "%d|%s|%d" % [k, rigid, palette.hash()]
	if _painted_cache.has(key):
		return _painted_cache[key]
	var sm := ShaderMaterial.new()
	sm.shader = PAINTED
	var pat := "enamel" if rigid else "cloth"
	var rough := 0.62
	if k >= 0:
		var rule: Array = palette[k]
		pat = rule[1]
		rough = rule[2]
		if rule.size() > 3:
			sm.set_shader_parameter("accent", Color.html(rule[3]))
		if rule.size() > 4:
			sm.set_shader_parameter("accent2", Color.html(rule[4]))
	sm.set_shader_parameter("pattern", PATTERNS[pat])
	sm.set_shader_parameter("rough", rough)
	_painted_cache[key] = sm
	return sm


## Per-pixel glossy version of a game material.
static func _material(mat: Material, gloss: float) -> Material:
	if _mat_cache.has(mat):
		return _mat_cache[mat]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.texture_repeat = false
	m.roughness = 1.0 - gloss
	m.metallic_specular = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	var b := mat as BaseMaterial3D
	if b:
		m.albedo_color = b.albedo_color
		if b.albedo_texture:
			var tex := b.albedo_texture
			var id := tex.resource_path.get_file().get_basename()
			if hd_faces.has(id):
				tex = hd_faces[id]
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
			m.albedo_texture = tex
			m.roughness = 0.62
			m.rim = 0.12
		if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			m.transparency = b.transparency
	elif mat is ShaderMaterial:
		# Chrome: polished steel.
		m.metallic = 0.85
		m.roughness = 0.22
		m.albedo_color = Color(0.92, 0.94, 0.98)
	_mat_cache[mat] = m
	return m


## A welded triangle mesh with per-corner attributes, for Loop subdivision.
class Sub:
	var pos: Array[Vector3] = []          # welded positions
	var tris: PackedInt32Array            # 3 vertex ids per face
	var cuv: Array[Vector2] = []          # per corner (3 per face)
	var ccol: Array[Color] = []

	static func from_arrays(arr: Array, strip: Array = [], no_nose := false, no_ears := false) -> Sub:
		var s := Sub.new()
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols = arr[Mesh.ARRAY_COLOR]
		var uvs = arr[Mesh.ARRAY_TEX_UV]
		var idx = arr[Mesh.ARRAY_INDEX]
		var order := PackedInt32Array()
		if idx != null and (idx as PackedInt32Array).size() > 0:
			order = idx
		else:
			order.resize(verts.size())
			for i in verts.size():
				order[i] = i
		var weld := {}
		var tris := PackedInt32Array()
		tris.resize(order.size())
		for c in order.size():
			var vi := order[c]
			var p := verts[vi]
			var k := Vector3i((p * 20000.0).round())
			var id: int = weld.get(k, -1)
			if id < 0:
				id = s.pos.size()
				weld[k] = id
				s.pos.append(p)
			tris[c] = id
			s.cuv.append((uvs as PackedVector2Array)[vi] if uvs != null else Vector2.ZERO)
			s.ccol.append((cols as PackedColorArray)[vi] if cols != null else Color.WHITE)
		# Drop degenerate faces (welded corners).
		var keep := PackedInt32Array()
		var kuv: Array[Vector2] = []
		var kcol: Array[Color] = []
		for f in tris.size() / 3:
			var a := tris[f * 3]
			var b := tris[f * 3 + 1]
			var c2 := tris[f * 3 + 2]
			if a == b or b == c2 or a == c2:
				continue
			if not strip.is_empty() and _all_in(strip, [s.ccol[f * 3], s.ccol[f * 3 + 1], s.ccol[f * 3 + 2]]):
				continue
			if no_nose:
				var cen := (s.pos[a] + s.pos[b] + s.pos[c2]) / 3.0
				if cen.z < -0.1 and cen.y > 0.08 and absf(cen.x) < 0.04:
					continue
				if no_ears and cen.y > 0.12 and absf(cen.x) > 0.09:
					continue
			keep.append_array([a, b, c2])
			for j in 3:
				kuv.append(s.cuv[f * 3 + j])
				kcol.append(s.ccol[f * 3 + j])
		s.tris = keep
		s.cuv = kuv
		s.ccol = kcol
		return s

	const COLOR_CREASE := 0.35

	static func _all_in(strip: Array, cs: Array) -> bool:
		for c: Color in cs:
			var hit := false
			for h: Color in strip:
				if _cdist(c, h) < 0.07:
					hit = true
					break
			if not hit:
				return false
		return true

	static func _cdist(a: Color, b: Color) -> float:
		return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

	func _fnormal(f: int) -> Vector3:
		var a := pos[tris[f * 3]]
		var b := pos[tris[f * 3 + 1]]
		var c := pos[tris[f * 3 + 2]]
		return (c - a).cross(b - a).normalized()   # clockwise front faces

	## One Loop step. Edges whose faces fold more than `crease_deg`, boundary
	## edges and non-manifold edges are sharp.
	func subdivide(crease_deg: float) -> Sub:
		var nf := tris.size() / 3
		var cos_c := cos(deg_to_rad(crease_deg))
		var fn: Array[Vector3] = []
		for f in nf:
			fn.append(_fnormal(f))
		# Edge table: key -> [faces], opposite vertices.
		var edges := {}
		var color_edge := {}
		for f in nf:
			for j in 3:
				var a := tris[f * 3 + j]
				var b := tris[f * 3 + (j + 1) % 3]
				var k := Vector2i(mini(a, b), maxi(a, b))
				if not edges.has(k):
					edges[k] = []
				edges[k].append(f)
				edges[k].append(tris[f * 3 + (j + 2) % 3])
				# A hem: the edge runs along one color and the face beyond it
				# turns a clearly different color. Kept as a crease on every
				# level so the band stays crisp instead of smearing.
				var ca := ccol[f * 3 + j]
				var cb := ccol[f * 3 + (j + 1) % 3]
				var co := ccol[f * 3 + (j + 2) % 3]
				if _cdist(ca, cb) < 0.06 and _cdist(co, ca) > COLOR_CREASE:
					color_edge[k] = true
		var sharp := {}
		var nbr := {}          # vertex -> Dictionary of neighbor ids
		var sharp_nbr := {}    # vertex -> Array of neighbors along sharp edges
		for k: Vector2i in edges:
			var e: Array = edges[k]
			var is_sharp := e.size() != 4 or color_edge.has(k)
			if not is_sharp:
				is_sharp = fn[e[0]].dot(fn[e[2]]) < cos_c
			sharp[k] = is_sharp
			for pair in [[k.x, k.y], [k.y, k.x]]:
				if not nbr.has(pair[0]):
					nbr[pair[0]] = {}
				nbr[pair[0]][pair[1]] = true
				if is_sharp:
					if not sharp_nbr.has(pair[0]):
						sharp_nbr[pair[0]] = []
					sharp_nbr[pair[0]].append(pair[1])
		var out := Sub.new()
		# New vertex points.
		for v in pos.size():
			var p := pos[v]
			var sn: Array = sharp_nbr.get(v, [])
			if nbr.has(v) and (nbr[v] as Dictionary).size() <= 2:
				p = pos[v]   # a lone corner (a single triangle's tip): keep it
			elif sn.size() == 2:
				p = pos[v] * 0.75 + (pos[sn[0]] + pos[sn[1]]) * 0.125
			elif sn.size() == 0 and nbr.has(v):
				var ns: Dictionary = nbr[v]
				var n := ns.size()
				var beta := 3.0 / 16.0 if n == 3 else 3.0 / (8.0 * n)
				var acc := Vector3.ZERO
				for u: int in ns:
					acc += pos[u]
				p = pos[v] * (1.0 - n * beta) + acc * beta
			out.pos.append(p)
		# Edge points.
		var eid := {}
		for k: Vector2i in edges:
			var e: Array = edges[k]
			var p := (pos[k.x] + pos[k.y]) * 0.5
			if not sharp[k]:
				p = (pos[k.x] + pos[k.y]) * 0.375 + (pos[e[1]] + pos[e[3]]) * 0.125
			eid[k] = out.pos.size()
			out.pos.append(p)
		var t := PackedInt32Array()
		for f in nf:
			var v0 := tris[f * 3]
			var v1 := tris[f * 3 + 1]
			var v2 := tris[f * 3 + 2]
			var e01: int = eid[Vector2i(mini(v0, v1), maxi(v0, v1))]
			var e12: int = eid[Vector2i(mini(v1, v2), maxi(v1, v2))]
			var e20: int = eid[Vector2i(mini(v2, v0), maxi(v2, v0))]
			var u0 := cuv[f * 3]
			var u1 := cuv[f * 3 + 1]
			var u2 := cuv[f * 3 + 2]
			var c0 := ccol[f * 3]
			var c1 := ccol[f * 3 + 1]
			var c2 := ccol[f * 3 + 2]
			var u01 := (u0 + u1) * 0.5
			var u12 := (u1 + u2) * 0.5
			var u20 := (u2 + u0) * 0.5
			var c01 := c0.lerp(c1, 0.5)
			var c12 := c1.lerp(c2, 0.5)
			var c20 := c2.lerp(c0, 0.5)
			t.append_array([v0, e01, e20, e01, v1, e12, e20, e12, v2, e01, e12, e20])
			out.cuv.append_array([u0, u01, u20, u01, u1, u12, u20, u12, u2, u01, u12, u20])
			out.ccol.append_array([c0, c01, c20, c01, c1, c12, c20, c12, c2, c01, c12, c20])
		out.tris = t
		return out

	## Splits the faces by `classify(face color)`: class -> Sub.
	func split_by_class(classify: Callable) -> Dictionary:
		var out := {}
		for f in tris.size() / 3:
			var c := (ccol[f * 3] + ccol[f * 3 + 1] + ccol[f * 3 + 2]) / 3.0
			var k: int = classify.call(c)
			if not out.has(k):
				var n := Sub.new()
				n.pos = pos
				out[k] = n
			var sub: Sub = out[k]
			sub.tris.append_array([tris[f * 3], tris[f * 3 + 1], tris[f * 3 + 2]])
			sub.cuv.append_array([cuv[f * 3], cuv[f * 3 + 1], cuv[f * 3 + 2]])
			sub.ccol.append_array([ccol[f * 3], ccol[f * 3 + 1], ccol[f * 3 + 2]])
		return out

	## Unindexed triangle arrays with normals smoothed across edges folding
	## less than `crease_deg`.
	func to_arrays(crease_deg: float) -> Array:
		var nf := tris.size() / 3
		var fn: Array[Vector3] = []
		var area: Array[float] = []
		var per_v := {}
		for f in nf:
			var a := pos[tris[f * 3]]
			var b := pos[tris[f * 3 + 1]]
			var c := pos[tris[f * 3 + 2]]
			var cr := (c - a).cross(b - a)
			fn.append(cr.normalized())
			area.append(cr.length())
			for j in 3:
				var v := tris[f * 3 + j]
				if not per_v.has(v):
					per_v[v] = []
				per_v[v].append(f)
		var cos_c := cos(deg_to_rad(crease_deg))
		var verts := PackedVector3Array()
		var norms := PackedVector3Array()
		var uvs := PackedVector2Array()
		var cols := PackedColorArray()
		for f in nf:
			for j in 3:
				var v := tris[f * 3 + j]
				var acc := Vector3.ZERO
				for g: int in per_v[v]:
					if fn[g].dot(fn[f]) >= cos_c:
						acc += fn[g] * area[g]
				verts.append(pos[v])
				norms.append(acc.normalized() if acc.length_squared() > 0 else fn[f])
				uvs.append(cuv[f * 3 + j])
				cols.append(ccol[f * 3 + j])
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = norms
		arr[Mesh.ARRAY_TEX_UV] = uvs
		arr[Mesh.ARRAY_COLOR] = cols
		return arr
