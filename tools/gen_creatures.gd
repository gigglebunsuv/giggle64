extends "res://tools/gen_characters.gd"
## Builds the overworld creatures of Haven, each after an Ocarina of Time
## enemy, as jointed low-poly models with keyframed animations (same method as
## gen_characters.gd), and assembles their enemy scenes in res://scenes/enemies/:
##
##   tektite / tektite_blue  hopping one-eyed spiders (EnTite)
##   keese                   cave bats that swoop (EnFirefly)
##   snapper / snapper_coral biting plants rooted in the ground (EnDekubaba)
##   leever                  spinning burrowers of the desert (EnReeba)
##   octorok                 rock-spitters that live in the water (EnOkuta)
##
## Creatures face -Z.

const SCENE_DIR := "res://scenes/enemies/"


func run(materials: Dictionary) -> void:
	_mats = materials
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	_build_tektite("tektite", _c("c8402c"), _c("8a2418"), _c("5a2420"))
	_build_tektite("tektite_blue", _c("3a78d8"), _c("1e4a9a"), _c("2a2e5a"))
	_build_keese()
	_build_snapper("snapper", _c("3a8a32"), _c("2a6a26"), _c("e8d870"), _c("c84a6a"))
	_build_snapper("snapper_coral", _c("2a9a9a"), _c("1e6a7a"), _c("f0e0c0"), _c("e86a5a"))
	_build_leever()
	_build_octorok()
	_build_rock()
	_scenes()


# --- Scene assembly -----------------------------------------------------------

## An enemy scene: CharacterBody3D (layer 3 "enemy") with the AI script, a body
## shape, the model, health, a hurtbox (layer 5) and an attack hitbox (layer 7
## against the hero's hurtbox), and a blob shadow.
## spec keys: script, model, hp, body: [radius, height, y], hurt: [radius, height, y],
## hit: [Vector3 size, Vector3 pos], shadow, floating, exports (Dictionary).
func enemy_scene(scene_name: String, spec: Dictionary) -> void:
	var root := CharacterBody3D.new()
	root.name = scene_name.to_pascal_case()
	root.collision_layer = 4
	root.collision_mask = 7
	root.set_script(load(spec.script))
	if spec.get("floating", false):
		root.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var body: Array = spec.body
	var col := CollisionShape3D.new()
	col.name = "Collision"
	col.shape = _capsule(body[0], body[1])
	col.position = Vector3(0, body[2], 0)
	root.add_child(col)
	var ps: PackedScene = ResourceLoader.load(MODEL_DIR + spec.model + ".tscn", "", ResourceLoader.CACHE_MODE_REPLACE)
	var model := ps.instantiate()
	model.name = "Model"
	root.add_child(model)
	var health := Node.new()
	health.name = "Health"
	health.set_script(load("res://scripts/combat/health_component.gd"))
	health.set("max_health", spec.hp)
	root.add_child(health)
	var hurt: Array = spec.hurt
	var hb := Area3D.new()
	hb.name = "Hurtbox"
	hb.collision_layer = 16
	hb.collision_mask = 0
	hb.set_script(load("res://scripts/combat/hurtbox.gd"))
	root.add_child(hb)
	var hcs := CollisionShape3D.new()
	hcs.name = "Shape"
	hcs.shape = _capsule(hurt[0], hurt[1])
	hcs.position = Vector3(0, hurt[2], 0)
	hb.add_child(hcs)
	if spec.has("hit"):
		var hit: Array = spec.hit
		var ab := Area3D.new()
		ab.name = "AttackHitbox"
		ab.collision_layer = 64
		ab.collision_mask = 8
		ab.set_script(load("res://scripts/combat/hitbox.gd"))
		root.add_child(ab)
		var acs := CollisionShape3D.new()
		acs.name = "Shape"
		var box := BoxShape3D.new()
		box.size = hit[0]
		acs.shape = box
		acs.position = hit[1]
		ab.add_child(acs)
	var shadow := MeshInstance3D.new()
	shadow.name = "BlobShadow"
	shadow.mesh = load(MODEL_DIR + "blob_shadow_mesh.tres")
	shadow.set_script(load("res://scripts/systems/blob_shadow.gd"))
	shadow.set("radius", spec.get("shadow", 0.5))
	root.add_child(shadow)
	for key in spec.get("exports", {}):
		root.set(key, spec.exports[key])
	_set_owner(root, root)
	# The instanced model keeps its own internals.
	for c in model.get_children():
		_clear_owner(c)
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, SCENE_DIR + scene_name + ".tscn")
	if err != OK:
		push_error("Failed to save enemy %s: %s" % [scene_name, err])
	root.free()


func _clear_owner(n: Node) -> void:
	n.owner = null
	for c in n.get_children():
		_clear_owner(c)


func _capsule(r: float, h: float) -> Shape3D:
	if h <= r * 2.0:
		var s := SphereShape3D.new()
		s.radius = r
		return s
	var c := CapsuleShape3D.new()
	c.radius = r
	c.height = h
	return c


func _scenes() -> void:
	for t in ["tektite", "tektite_blue"]:
		enemy_scene(t, {"script": "res://scripts/enemies/tektite.gd", "model": t, "hp": 2 if t == "tektite" else 3,
			"body": [0.45, 0.9, 0.5], "hurt": [0.6, 1.2, 0.55], "hit": [Vector3(1.2, 0.9, 1.2), Vector3(0, 0.5, 0)], "shadow": 0.6,
			"exports": {"target_offset": 1.2, "boomerang_stun": 3.0}})
	enemy_scene("keese", {"script": "res://scripts/enemies/keese.gd", "model": "keese", "hp": 1, "floating": true,
		"body": [0.25, 0.5, 0.0], "hurt": [0.4, 0.8, 0.0], "hit": [Vector3(0.7, 0.6, 0.7), Vector3(0, 0, 0)], "shadow": 0.3,
		"exports": {"target_offset": 0.3, "boomerang_stun": 4.0, "boomerang_damage": 1}})
	for t in ["snapper", "snapper_coral"]:
		enemy_scene(t, {"script": "res://scripts/enemies/snapper.gd", "model": t, "hp": 2,
			"body": [0.35, 1.2, 0.6], "hurt": [0.45, 2.0, 1.0], "hit": [Vector3(1.0, 1.0, 2.2), Vector3(0, 0.9, -1.7)], "shadow": 0.6,
			"exports": {"target_offset": 1.6, "boomerang_stun": 3.0}})
	enemy_scene("leever", {"script": "res://scripts/enemies/leever.gd", "model": "leever", "hp": 2,
		"body": [0.4, 1.0, 0.5], "hurt": [0.55, 1.3, 0.6], "hit": [Vector3(1.1, 1.0, 1.1), Vector3(0, 0.5, 0)], "shadow": 0.55,
		"exports": {"target_offset": 1.2, "boomerang_stun": 2.0}})
	enemy_scene("octorok", {"script": "res://scripts/enemies/octorok.gd", "model": "octorok", "hp": 1,
		"body": [0.45, 0.9, 0.45], "hurt": [0.55, 1.1, 0.5], "shadow": 0.0,
		"exports": {"target_offset": 1.1, "boomerang_stun": 3.0}})


# --- Tektite (EnTite) -----------------------------------------------------------

## A round body on four long jointed legs, one big eye in front. It crouches,
## then springs toward the hero in a high arc.
func _build_tektite(file: String, body_col: Color, spot_col: Color, leg_col: Color) -> void:
	var WHITE := Color.WHITE
	_root = Node3D.new()
	_root.name = file.to_pascal_case() + "Model"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.6, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([
			[-0.26, 0.0, 0.0, spot_col], [-0.22, 0.2, 0.22, spot_col], [-0.1, 0.33, 0.34, body_col],
			[0.04, 0.36, 0.36, body_col], [0.16, 0.3, 0.3, body_col.lightened(0.1)], [0.26, 0.16, 0.16, spot_col], [0.3, 0.0, 0.0, spot_col],
		], 10)
		var h := p.k("hard")
		for i in 6:
			var a := TAU * i / 6.0 + 0.4
			h.icosa(Vector3(cos(a) * 0.3, 0.12, sin(a) * 0.3), Vector3(0.07, 0.04, 0.07), 0.1, spot_col.darkened(0.2))
		# The eye: a white ball with a dark slit, glowing a little.
		h.icosa(Vector3(0, 0.05, -0.3), Vector3(0.16, 0.16, 0.1), 0.0, WHITE, true)
		var g := p.k("glow")
		g.box(Vector3(0, 0.05, -0.395), Vector3(0.05, 0.16, 0.01), _c("101010"))
		g.box(Vector3(0, 0.05, -0.39), Vector3(0.13, 0.03, 0.005), _c("e8d040"))
	)
	for leg in [["fl", Vector3(-0.22, 0, -0.18), -135.0], ["fr", Vector3(0.22, 0, -0.18), -45.0], ["bl", Vector3(-0.22, 0, 0.18), 135.0], ["br", Vector3(0.22, 0, 0.18), 45.0]]:
		var mount := Node3D.new()
		mount.name = "Mount" + leg[0].to_upper()
		mount.position = leg[1]
		# The mount turns so its +X points out from the body.
		mount.rotation.y = deg_to_rad(-leg[2])
		body.add_child(mount)
		var hip := _joint(mount, "leg_" + leg[0], "Leg" + leg[0].to_upper(), Vector3.ZERO, func(p: Parts) -> void:
			var k := p.k()
			k.push(_aim(Vector3(1, 0.7, 0), Vector3.ZERO))
			k.loft([[0.0, 0.06, 0.06, leg_col], [0.25, 0.05, 0.05, leg_col.lightened(0.1)], [0.48, 0.045, 0.045, leg_col], [0.5, 0.0, 0.0, leg_col]], 6)
			k.pop()
		)
		_joint(hip, "knee_" + leg[0], "Knee" + leg[0].to_upper(), Vector3(1, 0.7, 0).normalized() * 0.48, func(p: Parts) -> void:
			var k := p.k()
			k.push(_aim(Vector3(0.45, -1, 0), Vector3.ZERO))
			k.loft([[0.0, 0.05, 0.05, leg_col], [0.45, 0.035, 0.035, leg_col.darkened(0.1)], [0.9, 0.02, 0.02, leg_col.darkened(0.2)], [0.95, 0.0, 0.0, leg_col.darkened(0.3)]], 6)
			k.pop()
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3(0, 0.6, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var legs := ["fl", "fr", "bl", "br"]
	var pose := func(hip_z: float, knee_z: float) -> Dictionary:
		var d := {}
		for l: String in legs:
			d["leg_" + l] = [[0.0, V.call(0, 0, hip_z)]]
			d["knee_" + l] = [[0.0, V.call(0, 0, knee_z)]]
		return d
	_anim(lib, "RESET", 0.1, false, {}, rest)
	var idle := {"body@pos": [[0.0, V.call(0, 0.6, 0)], [0.5, V.call(0, 0.56, 0)]], "body": [[0.0, V.call(0, 0, 0)], [0.5, V.call(3, 0, 0)]]}
	for i in legs.size():
		var l: String = legs[i]
		var ph := 0.25 * (i % 2)
		idle["leg_" + l] = [[0.0, V.call(0, 0, 0)], [0.5, V.call(0, 0, -6)]]
		idle["knee_" + l] = [[0.0, V.call(0, 0, 0)], [0.5, V.call(0, 0, 8)]]
		var _unused := ph
	_anim(lib, "idle", 1.0, true, idle, rest)
	var crouch: Dictionary = pose.call(-25.0, 30.0)
	crouch["body@pos"] = [[0.0, V.call(0, 0.6, 0)], [0.25, V.call(0, 0.32, 0)]]
	crouch["body"] = [[0.0, V.call(0, 0, 0)], [0.25, V.call(-10, 0, 0)]]
	for l in legs:
		crouch["leg_" + l] = [[0.0, V.call(0, 0, 0)], [0.25, V.call(0, 0, -25)]]
		crouch["knee_" + l] = [[0.0, V.call(0, 0, 0)], [0.25, V.call(0, 0, 30)]]
	_anim(lib, "crouch", 0.25, false, crouch, rest)
	var jump: Dictionary = {}
	jump["body@pos"] = [[0.0, V.call(0, 0.32, 0)], [0.12, V.call(0, 0.7, 0)]]
	jump["body"] = [[0.0, V.call(-10, 0, 0)], [0.12, V.call(8, 0, 0)]]
	for l in legs:
		jump["leg_" + l] = [[0.0, V.call(0, 0, -25)], [0.12, V.call(0, 0, 25)]]
		jump["knee_" + l] = [[0.0, V.call(0, 0, 30)], [0.12, V.call(0, 0, -35)]]
	_anim(lib, "jump", 0.4, false, jump, rest)
	var land: Dictionary = {"body@pos": [[0.0, V.call(0, 0.4, 0)], [0.2, V.call(0, 0.6, 0)]]}
	for l in legs:
		land["leg_" + l] = [[0.0, V.call(0, 0, -15)], [0.2, V.call(0, 0, 0)]]
		land["knee_" + l] = [[0.0, V.call(0, 0, 18)], [0.2, V.call(0, 0, 0)]]
	_anim(lib, "land", 0.2, false, land, rest)
	var hurt: Dictionary = {"body": [[0.0, V.call(25, 0, 10)], [0.3, V.call(0, 0, 0)]]}
	_anim(lib, "hurt", 0.3, false, hurt, rest)
	var stun: Dictionary = {"body": [[0.0, V.call(0, 0, 15)], [0.3, V.call(0, 0, -15)]], "body@pos": [[0.0, V.call(0, 0.45, 0)]]}
	for l in legs:
		stun["leg_" + l] = [[0.0, V.call(0, 0, 20)], [0.3, V.call(0, 0, -10)]]
	_anim(lib, "stunned", 0.6, true, stun, rest)
	# Death: flipped onto its back, legs curled (OoT's tektites flip over).
	var death: Dictionary = {"body@pos": [[0.0, V.call(0, 0.6, 0)], [0.3, V.call(0, 0.9, 0)], [0.6, V.call(0, 0.3, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 180)]]}
	for l in legs:
		death["leg_" + l] = [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 40)]]
		death["knee_" + l] = [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, 0, 60)]]
	_anim(lib, "death", 0.9, false, death, rest)
	_finish_character(root, lib)
	_save_scene(root, file + ".tscn")


# --- Keese (EnFirefly) ----------------------------------------------------------

## A small bat: a furry body, big ears, one glowing eye and two leathery
## wings that flap fast. The model's origin is the middle of the body.
func _build_keese() -> void:
	var FUR := _c("3a2a46")
	var FUR_L := _c("4e3a5e")
	var SKIN := _c("6a4a7a")
	var EYE := _c("ffd030")
	_root = Node3D.new()
	_root.name = "KeeseModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3.ZERO, Vector3(0.16, 0.15, 0.18), 0.05, FUR, true)
		for sx in [-1.0, 1.0]:
			k.prism(Vector3(0.08 * sx, 0.1, -0.02), 0.05, Vector3(0.12 * sx, 0.28, 0.02), 0.0, 4, FUR_L)
		k.prism(Vector3(0, -0.12, 0.05), 0.04, Vector3(0, -0.2, 0.1), 0.0, 4, SKIN)
		var g := p.k("glow")
		g.icosa(Vector3(0, 0.02, -0.165), Vector3(0.065, 0.065, 0.03), 0.0, EYE)
		g.box(Vector3(0, 0.02, -0.196), Vector3(0.02, 0.06, 0.005), _c("200808"))
	)
	for side in [1.0, -1.0]:
		var sfx := "r" if side > 0 else "l"
		_joint(body, "wing_" + sfx, "Wing" + sfx.to_upper(), Vector3(0.12 * side, 0.03, 0), func(p: Parts) -> void:
			var k := p.k()
			var tip := Vector3(0.5 * side, 0.12, 0.05)
			var f1 := Vector3(0.42 * side, -0.08, 0.12)
			var f2 := Vector3(0.24 * side, -0.12, 0.14)
			for pts in [[Vector3.ZERO, tip, f1], [Vector3.ZERO, f1, f2], [Vector3.ZERO, f2, Vector3(0.05 * side, -0.08, 0.1)]]:
				k.face_dir(pts, SKIN, Vector3.UP)
				k.face_dir(pts, SKIN.darkened(0.25), Vector3.DOWN)
			var h := p.k("hard")
			h.prism(Vector3.ZERO, 0.02, tip, 0.008, 4, FUR)
		)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 0.24, true, {
		"wing_r": [[0.0, V.call(0, 0, 45)], [0.12, V.call(0, 0, -40)]],
		"wing_l": [[0.0, V.call(0, 0, -45)], [0.12, V.call(0, 0, 40)]],
		"body@pos": [[0.0, V.call(0, 0.03, 0)], [0.12, V.call(0, -0.03, 0)]],
	}, rest)
	_anim(lib, "swoop", 0.16, true, {
		"wing_r": [[0.0, V.call(0, 0, 25)], [0.08, V.call(0, 0, -20)]],
		"wing_l": [[0.0, V.call(0, 0, -25)], [0.08, V.call(0, 0, 20)]],
		"body": [[0.0, V.call(-25, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.6, true, {
		"wing_r": [[0.0, V.call(0, 0, -60)]], "wing_l": [[0.0, V.call(0, 0, 60)]],
		"body": [[0.0, V.call(0, 0, 20)], [0.3, V.call(0, 0, -20)]],
	}, rest)
	_anim(lib, "death", 0.5, false, {
		"wing_r": [[0.0, V.call(0, 0, 40)], [0.5, V.call(0, 0, -70)]], "wing_l": [[0.0, V.call(0, 0, -40)], [0.5, V.call(0, 0, 70)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.5, V.call(80, 0, 180)]],
	}, rest)
	_finish_character(root, lib)
	_save_scene(root, "keese.tscn")


# --- Snapper (EnDekubaba) -------------------------------------------------------

## A biting plant: a rosette of broad leaves on the ground, a long stalk that
## hides below them, and a head of two toothed jaws.
func _build_snapper(file: String, leaf: Color, stem: Color, inside: Color, lip: Color) -> void:
	var TOOTH := _c("f4f0e0")
	_root = Node3D.new()
	_root.name = file.to_pascal_case() + "Model"
	_paths = {}
	var root := _root
	_joint(root, "leaves", "Leaves", Vector3.ZERO, func(p: Parts) -> void:
		var k := p.k()
		for i in 6:
			var a := TAU * i / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			var side := Vector3(-d.z, 0, d.x) * 0.22
			var tip := d * 0.85 + Vector3(0, 0.05, 0)
			var mid := d * 0.45 + Vector3(0, 0.16, 0)
			k.face_dir([Vector3(0, 0.05, 0), mid + side, tip, mid - side], leaf, Vector3.UP)
			k.face_dir([Vector3(0, 0.04, 0), mid - side, tip, mid + side], leaf.darkened(0.3), Vector3.DOWN)
	)
	var s1 := _joint(root, "stem1", "Stem1", Vector3(0, 0, 0), func(p: Parts) -> void:
		p.k().loft([[0.0, 0.07, 0.07, stem], [0.5, 0.06, 0.06, stem.lightened(0.1)], [0.62, 0.055, 0.055, stem]], 6)
	)
	var s2 := _joint(s1, "stem2", "Stem2", Vector3(0, 0.6, 0), func(p: Parts) -> void:
		p.k().loft([[0.0, 0.06, 0.06, stem], [0.5, 0.05, 0.05, stem.lightened(0.1)], [0.62, 0.05, 0.05, stem]], 6)
		var k := p.k()
		for sx in [-1.0, 1.0]:
			k.face_dir([Vector3(0, 0.3, 0), Vector3(0.25 * sx, 0.42, 0.05), Vector3(0.12 * sx, 0.3, 0.08)], leaf, Vector3(0, 0.3, 1))
	)
	var head := _joint(s2, "head", "Head", Vector3(0, 0.6, 0), func(p: Parts) -> void:
		var k := p.k()
		k.icosa(Vector3(0, 0.0, 0.08), Vector3(0.22, 0.19, 0.22), 0.05, stem.darkened(0.1))
	)
	for jaw in [["jaw_top", 1.0], ["jaw_bot", -1.0]]:
		var sy: float = jaw[1]
		_joint(head, jaw[0], jaw[0].to_pascal_case(), Vector3(0, 0.0, 0.05), func(p: Parts) -> void:
			var k := p.k()
			var h := p.k("hard")
			# A big half-dome jaw reaching forward (-Z), lips round the rim, teeth inside.
			var big := Transform3D(Basis().scaled(Vector3(1.7, 1.7, 1.7)), Vector3.ZERO)
			k.push(big)
			h.push(big)
			k.push(_aim(Vector3(0, 0, -1), Vector3.ZERO))
			k.loft([[0.0, 0.14, 0.12, lip], [0.18, 0.22, 0.19, leaf], [0.36, 0.2, 0.17, leaf.lightened(0.1)], [0.46, 0.1, 0.08, lip], [0.5, 0.0, 0.0, lip]], 8)
			k.pop()
			k.pop()
			h.box(Vector3(0, -0.06 * sy, -0.25), Vector3(0.3, 0.02, 0.36), inside)
			for i in 5:
				var t := float(i) / 4.0
				h.prism(Vector3(lerpf(-0.13, 0.13, t), -0.06 * sy, -0.12 - absf(t - 0.5) * 0.1), 0.025, Vector3(lerpf(-0.12, 0.12, t), -0.13 * sy, -0.12 - absf(t - 0.5) * 0.1), 0.0, 4, TOOTH)
			h.pop()
			# Flatten: squash the dome toward this jaw's half.
			for kk in [k, h]:
				for vi in kk.verts.size():
					var v: Vector3 = kk.verts[vi]
					if v.y * sy < 0.0:
						v.y *= 0.15
					kk.verts[vi] = v
		)
	var lib := AnimationLibrary.new()
	var rest := {"stem1": Vector3(0, 0, 0)}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	var hidden: Vector3 = V.call(0, -1.3, 0)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "hide", 0.3, false, {"stem1@pos": [[0.0, hidden]], "jaw_top": [[0.0, V.call(0, 0, 0)]], "jaw_bot": [[0.0, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "rise", 0.35, false, {
		"stem1@pos": [[0.0, hidden], [0.3, V.call(0, 0.05, 0)], [0.35, V.call(0, 0, 0)]],
		"stem1": [[0.0, V.call(0, 0, 0)], [0.35, V.call(-8, 0, 0)]],
		"head": [[0.0, V.call(40, 0, 0)], [0.35, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "idle", 1.4, true, {
		"stem1": [[0.0, V.call(-8, 0, 6)], [0.7, V.call(-6, 0, -6)]],
		"stem2": [[0.0, V.call(10, 0, -6)], [0.7, V.call(6, 0, 6)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.7, V.call(20, 0, 0)]],
		"jaw_top": [[0.0, V.call(-25, 0, 0)], [0.35, V.call(-10, 0, 0)], [0.7, V.call(-25, 0, 0)], [1.05, V.call(-10, 0, 0)]],
		"jaw_bot": [[0.0, V.call(25, 0, 0)], [0.35, V.call(10, 0, 0)], [0.7, V.call(25, 0, 0)], [1.05, V.call(10, 0, 0)]],
	}, rest)
	# Rear back with jaws wide, then lunge forward and snap.
	_anim(lib, "windup", 0.4, false, {
		"stem1": [[0.0, V.call(-8, 0, 0)], [0.4, V.call(18, 0, 0)]],
		"stem2": [[0.0, V.call(10, 0, 0)], [0.4, V.call(25, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.4, V.call(-20, 0, 0)]],
		"jaw_top": [[0.0, V.call(-20, 0, 0)], [0.4, V.call(-55, 0, 0)]],
		"jaw_bot": [[0.0, V.call(20, 0, 0)], [0.4, V.call(45, 0, 0)]],
	}, rest)
	_anim(lib, "bite", 0.35, false, {
		"stem1": [[0.0, V.call(18, 0, 0)], [0.1, V.call(-50, 0, 0)], [0.35, V.call(-45, 0, 0)]],
		"stem2": [[0.0, V.call(25, 0, 0)], [0.1, V.call(-20, 0, 0)]],
		"head": [[0.0, V.call(-20, 0, 0)], [0.1, V.call(50, 0, 0)]],
		"jaw_top": [[0.0, V.call(-55, 0, 0)], [0.12, V.call(0, 0, 0)]],
		"jaw_bot": [[0.0, V.call(45, 0, 0)], [0.12, V.call(0, 0, 0)]],
	}, rest)
	_anim(lib, "recover", 0.5, false, {
		"stem1": [[0.0, V.call(-45, 0, 0)], [0.5, V.call(-8, 0, 0)]],
		"stem2": [[0.0, V.call(-20, 0, 0)], [0.5, V.call(10, 0, 0)]],
		"head": [[0.0, V.call(50, 0, 0)], [0.5, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.8, true, {
		"stem1": [[0.0, V.call(-20, 0, 25)]], "stem2": [[0.0, V.call(40, 0, 10)], [0.4, V.call(45, 0, 20)]],
		"head": [[0.0, V.call(60, 0, 0)]], "jaw_top": [[0.0, V.call(-15, 0, 0)]], "jaw_bot": [[0.0, V.call(15, 0, 0)]],
	}, rest)
	_anim(lib, "hurt", 0.3, false, {
		"stem1": [[0.0, V.call(20, 0, 0)], [0.3, V.call(-8, 0, 0)]], "head": [[0.0, V.call(-30, 0, 0)], [0.3, V.call(10, 0, 0)]],
	}, rest)
	_anim(lib, "death", 0.8, false, {
		"stem1": [[0.0, V.call(-8, 0, 0)], [0.6, V.call(-85, 0, 10)]], "stem2": [[0.0, V.call(10, 0, 0)], [0.6, V.call(30, 0, 0)]],
		"head": [[0.0, V.call(10, 0, 0)], [0.6, V.call(40, 0, 0)]],
		"jaw_top": [[0.0, V.call(-20, 0, 0)], [0.6, V.call(-40, 0, 0)]], "jaw_bot": [[0.0, V.call(20, 0, 0)], [0.6, V.call(40, 0, 0)]],
	}, rest)
	_finish_character(root, lib)
	(root.get_node("AnimationPlayer") as AnimationPlayer).autoplay = "hide"
	_save_scene(root, file + ".tscn")


# --- Leever (EnReeba) -----------------------------------------------------------

## A squat spinning burrower: a ridged top-shaped body ringed with tan spikes
## and a round dark mouth on top. The script spins the whole model.
func _build_leever() -> void:
	var BODY := _c("7a8a3a")
	var BODY_D := _c("5a6a2a")
	var SPIKE := _c("d8c890")
	_root = Node3D.new()
	_root.name = "LeeverModel"
	_paths = {}
	var root := _root
	_joint(root, "body", "Body", Vector3(0, 0, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.0, 0.0, BODY_D], [0.05, 0.3, 0.3, BODY_D], [0.35, 0.45, 0.45, BODY], [0.7, 0.36, 0.36, BODY], [0.95, 0.2, 0.2, BODY_D], [1.0, 0.12, 0.12, _c("2a1a12")]], 9)
		var h := p.k("hard")
		for ring in [[0.3, 0.44, 9, 0.0], [0.62, 0.38, 9, 0.35]]:
			for i in ring[2]:
				var a: float = TAU * i / ring[2] + ring[3]
				var d := Vector3(cos(a), 0, sin(a))
				h.prism(d * (ring[1] - 0.04) + Vector3(0, ring[0], 0), 0.1, d * (ring[1] + 0.34) + Vector3(0, ring[0] + 0.1, 0), 0.0, 4, SPIKE)
		var g := p.k("glow")
		for sx in [-1.0, 1.0]:
			g.icosa(Vector3(0.12 * sx, 0.8, -0.27), Vector3(0.05, 0.06, 0.03), 0.0, _c("f0e040"))
	)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 0.4, true, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.2, V.call(0, 0.05, 0)]], "body": [[0.0, V.call(4, 0, 0)], [0.2, V.call(-4, 0, 3)]]}, rest)
	_anim(lib, "buried", 0.2, false, {"body@pos": [[0.0, V.call(0, -1.2, 0)]]}, rest)
	_anim(lib, "rise", 0.5, false, {"body@pos": [[0.0, V.call(0, -1.2, 0)], [0.5, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "sink", 0.6, false, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, -1.2, 0)]]}, rest)
	_anim(lib, "stunned", 0.6, true, {"body": [[0.0, V.call(15, 0, 10)], [0.3, V.call(-15, 0, -10)]]}, rest)
	_anim(lib, "death", 0.6, false, {"body": [[0.0, V.call(0, 0, 0)], [0.6, V.call(70, 0, 30)]], "body@pos": [[0.0, V.call(0, 0, 0)], [0.6, V.call(0, -0.3, 0)]]}, rest)
	_finish_character(root, lib)
	(root.get_node("AnimationPlayer") as AnimationPlayer).autoplay = "buried"
	_save_scene(root, "leever.tscn")


# --- Octorok (EnOkuta) ----------------------------------------------------------

## A round head with a tube of a snout and big eyes, little tentacles below.
## It bobs up out of the water to spit rocks.
func _build_octorok() -> void:
	var SKIN := _c("8a4ab0")
	var SKIN_L := _c("a868c8")
	var SKIN_D := _c("5e2e7e")
	_root = Node3D.new()
	_root.name = "OctorokModel"
	_paths = {}
	var root := _root
	var body := _joint(root, "body", "Body", Vector3(0, 0.0, 0), func(p: Parts) -> void:
		var k := p.k()
		k.loft([[0.0, 0.0, 0.0, SKIN_D], [0.08, 0.32, 0.32, SKIN_D], [0.3, 0.44, 0.44, SKIN], [0.55, 0.42, 0.42, SKIN_L], [0.8, 0.26, 0.26, SKIN], [0.9, 0.0, 0.0, SKIN]], 10)
		for i in 6:
			var a := TAU * i / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			k.push(_aim(d + Vector3(0, -0.6, 0), d * 0.25 + Vector3(0, 0.08, 0)))
			k.loft([[0.0, 0.07, 0.07, SKIN_D], [0.18, 0.04, 0.04, SKIN], [0.24, 0.0, 0.0, SKIN]], 5)
			k.pop()
		var h := p.k("hard")
		for sx in [-1.0, 1.0]:
			h.icosa(Vector3(0.18 * sx, 0.58, -0.3), Vector3(0.11, 0.13, 0.08), 0.0, Color.WHITE, true)
			h.icosa(Vector3(0.18 * sx, 0.58, -0.37), Vector3(0.05, 0.07, 0.03), 0.0, _c("1a0a10"))
	)
	_joint(body, "snout", "Snout", Vector3(0, 0.42, -0.35), func(p: Parts) -> void:
		var k := p.k()
		k.push(_aim(Vector3(0, 0, -1), Vector3.ZERO))
		k.loft([[0.0, 0.13, 0.13, SKIN], [0.2, 0.1, 0.1, SKIN_L], [0.3, 0.13, 0.13, SKIN_L], [0.3, 0.07, 0.07, _c("2a0a1a")]], 8)
		k.pop()
	)
	var lib := AnimationLibrary.new()
	var rest := {"body": Vector3.ZERO}
	var V := func(x: float, y: float, z: float) -> Vector3: return Vector3(x, y, z)
	_anim(lib, "RESET", 0.1, false, {}, rest)
	_anim(lib, "idle", 1.0, true, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.5, V.call(0, 0.08, 0)]], "body": [[0.0, V.call(0, 0, 3)], [0.5, V.call(0, 0, -3)]]}, rest)
	_anim(lib, "hidden", 0.2, false, {"body@pos": [[0.0, V.call(0, -1.1, 0)]]}, rest)
	_anim(lib, "rise", 0.4, false, {"body@pos": [[0.0, V.call(0, -1.1, 0)], [0.3, V.call(0, 0.15, 0)], [0.4, V.call(0, 0, 0)]]}, rest)
	_anim(lib, "sink", 0.4, false, {"body@pos": [[0.0, V.call(0, 0, 0)], [0.4, V.call(0, -1.1, 0)]]}, rest)
	_anim(lib, "shoot", 0.4, false, {
		"body@pos": [[0.0, V.call(0, 0, 0)], [0.15, V.call(0, 0.12, 0.08)], [0.4, V.call(0, 0, 0)]],
		"body": [[0.0, V.call(0, 0, 0)], [0.15, V.call(-12, 0, 0)], [0.25, V.call(15, 0, 0)], [0.4, V.call(0, 0, 0)]],
		"snout": [[0.0, V.call(0, 0, 0)], [0.25, V.call(-10, 0, 0)]],
	}, rest)
	_anim(lib, "stunned", 0.6, true, {"body": [[0.0, V.call(0, 0, 20)], [0.3, V.call(0, 0, -20)]]}, rest)
	_anim(lib, "death", 0.7, false, {"body": [[0.0, V.call(0, 0, 0)], [0.7, V.call(-60, 0, 0)]], "body@pos": [[0.0, V.call(0, 0, 0)], [0.3, V.call(0, 0.4, 0)], [0.7, V.call(0, -0.9, 0)]]}, rest)
	_finish_character(root, lib)
	(root.get_node("AnimationPlayer") as AnimationPlayer).autoplay = "hidden"
	_save_scene(root, "octorok.tscn")


## The rock an octorok spits (and the hero can bat back with his shield).
func _build_rock() -> void:
	var k := MeshKit.new(77)
	k.icosa(Vector3.ZERO, Vector3(0.15, 0.13, 0.14), 0.15, _c("8a8078"))
	k.smooth_normals(50.0)
	_save_res(k.build(_mats.char), "rock_mesh.tres")
