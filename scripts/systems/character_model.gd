class_name CharacterModel
extends Node3D
## Runtime interface for a generated, segmented low-poly character.
##
## Each limb is a rigid mesh on its own joint node (the way N64-era characters
## were built), animated by the AnimationPlayer generated alongside it.
##
## On top of the keyframed animation, the controller can lean the upper body
## (OoT tilts Link's chest forward with speed and rolls it into turns, with the
## head counter-rotating by half). The lean is layered after the animation each
## frame, so the AnimationPlayer is advanced manually here.
##
## A second layer, `upper_pose`, holds some joints in a fixed pose over whatever
## the legs are doing (OoT plays the Z-target shield on a separate upper-body
## skeleton, Player_SetUpperActionFunc(func_80834B5C), while the legs walk).

@onready var anim: AnimationPlayer = $AnimationPlayer

var current_anim: StringName = &""
## The shortest crossfade between two animations (Beta 1.7.0). Enemies and
## people set it so no change of state snaps from one pose to the next, as
## OoT morphs between animations over a few frames (Animation_Change's
## morphFrames). The hero keeps 0: his blends are tuned one by one.
var min_blend := 0.0
## Upper-body lean in radians: x = forward pitch, y = roll into a turn.
var lean := Vector2.ZERO
## Head turn layered over the animation in radians: x = yaw (left +), y = pitch
## (up +). NPCs track the hero with it (OoT's Npc_TrackPoint).
var look := Vector2.ZERO
## Upper body turned over the hips in radians: x = yaw (left +), y = pitch
## (forward/down +). The crouched shield is aimed with it (OoT's upperLimbRot).
var upper_turn := Vector2.ZERO
## Joint -> rotation held over the animation, blended in by `upper_weight` (0-1).
var upper_pose: Dictionary = {}
var upper_weight := 0.0
## Aiming in first person: the chest (and the arms and the item with it)
## tilts up or down with the view, radians up +, as OoT's upper body follows
## the aim; `aim_kick` (0-1) jolts it back a little when a shot is loosed.
var aim_pitch := 0.0
var aim_kick := 0.0
var _meshes: Array[MeshInstance3D] = []
var _flash_material: StandardMaterial3D
var _flash_time := 0.0
var _torso: Node3D
var _head: Node3D
var _torso_offset := Quaternion.IDENTITY
var _head_offset := Quaternion.IDENTITY
var _pose_restore: Dictionary = {}
var _hand_sword: Node3D
var _back_sword: Node3D
var _bow: Node3D
var _arm_shield: Node3D
var _back_shield: Node3D
var _look_offset := Quaternion.IDENTITY
var _hand_boomerang: MeshInstance3D
var _arms_only := false
## Meshes hidden while only the arms are drawn, with their visibility before.
var _arms_hidden: Dictionary = {}
## The sword and shield shown (Equipment ids; "" until set_gear).
var gear_sword := ""
## A two-handed sword (the Questlord's Greatsword): while it is out the shield
## rides on the back and the left hand takes the grip below the right
## (OoT's Biggoron's Sword).
var two_hand := false
## Why the shield is on the back: the bow is out, both hands carry something,
## or a two-handed sword is drawn. It goes back on the arm when none is left.
var _bow_out := false
var _carry_back := false
var _drawn := false
var gear_shield := ""
## Sparkles and light of the Bun Sword (made the first time it is equipped).
var _magic: Array[Node3D] = []
var _magic_light: OmniLight3D
var _magic_time := 0.0


func _ready() -> void:
	if _meshes.is_empty():
		_collect_meshes(self)
	_flash_material = StandardMaterial3D.new()
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_material.albedo_color = Color.WHITE
	_torso = get_node_or_null("Hips/Torso")
	_head = get_node_or_null("Hips/Torso/Head")
	_hand_sword = find_child("Sword", true, false) as Node3D
	_back_sword = find_child("SheathedSword", true, false) as Node3D
	_bow = find_child("Bow", true, false) as Node3D
	_arm_shield = find_child("Shield", true, false) as Node3D
	_back_shield = find_child("ShieldBack", true, false) as Node3D
	if _bow:
		_bow.visible = false
	if _back_shield:
		_back_shield.visible = false
	if _bow and _bow.get_node_or_null("BowMesh"):
		_string_bow()
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


func _collect_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
		_collect_meshes(child)


## Plays an animation. Re-requesting the current animation only updates its speed
## unless `restart` is set. A negative speed plays it backward.
func play(anim_name: StringName, blend := 0.06, speed := 1.0, restart := false) -> void:
	if not anim.has_animation(anim_name):
		return
	anim.speed_scale = speed
	if anim_name == current_anim and not restart:
		return
	var same := anim_name == current_anim
	current_anim = anim_name
	# A restart cuts straight to the first frame, except that a model with a
	# min_blend still eases from a different animation into it.
	if restart and (same or min_blend <= 0.0):
		anim.stop()
		anim.play(anim_name, blend)
		return
	anim.play(anim_name, maxf(blend, min_blend))


func animation_finished() -> bool:
	return not anim.is_playing()


## Shows the sword in the hand (drawn) or in the scabbard on the back.
func set_sword_drawn(drawn: bool) -> void:
	_drawn = drawn
	if _hand_sword:
		_hand_sword.visible = drawn and not _sword_hidden
	if _back_sword:
		_back_sword.visible = not drawn
	_place_shield()


## Shows the sword and shield `sword_id` / `shield_id` (Equipment ids): the
## meshes on the fist, the back and the forearm are swapped for that piece's,
## which tools/gen_characters.gd builds in the same frames.
func set_gear(sword_id: String, shield_id: String) -> void:
	if sword_id != gear_sword:
		gear_sword = sword_id
		_swap_mesh(_hand_sword, "SwordMesh", _styled(Equipment.sword_mesh(sword_id)))
		_swap_mesh(_back_sword, "SheathedSwordMesh", _styled(Equipment.sword_hilt_mesh(sword_id)))
		_swap_mesh(find_child("SwordBack", true, false) as Node3D, "SwordBackMesh", _styled(Equipment.scabbard_mesh(sword_id)))
		_set_magic(Equipment.sword(sword_id).get("beam", false))
		two_hand = Equipment.two_handed(sword_id)
		_place_shield()
	if shield_id != gear_shield:
		gear_shield = shield_id
		_swap_mesh(_arm_shield, "ShieldMesh", _styled(Equipment.shield_mesh(shield_id)))
		_swap_mesh(_back_shield, "ShieldBackMesh", _styled(Equipment.shield_back_mesh(shield_id)))


## A co-op companion carries her own version of each piece (meta "gear_style":
## sword_squire_pink_mesh.tres for sword_squire_mesh.tres), when there is one.
func _styled(path: String) -> String:
	var style := String(get_meta("gear_style", ""))
	if style == "":
		return path
	var own := path.trim_suffix("_mesh.tres") + "_%s_mesh.tres" % style
	return own if ResourceLoader.exists(own) else path


## Pink's gold leaf on the shields (the lost garrison's last reward,
## Chapter IV): a warm gold sheen over the shield on the arm and the back.
var _gilded := false


func set_gilded(on: bool) -> void:
	if on == _gilded:
		return
	_gilded = on
	var mat: StandardMaterial3D = null
	if on:
		mat = StandardMaterial3D.new()
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.32, 0.24, 0.06)
	for holder in [_arm_shield, _back_shield]:
		if holder == null:
			continue
		for c in holder.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).material_overlay = mat


## The awakened Bun Sword: its pink blade glows with a pale rose starlight
## instead of gold.
func set_starlight(on: bool) -> void:
	if _magic_light:
		_magic_light.light_color = Color(1.0, 0.72, 0.9) if on else Color(1.0, 0.85, 0.4)
		_magic_light.light_energy = 0.9 if on else 0.6
	for n in _magic:
		if n is CPUParticles3D:
			(n as CPUParticles3D).color = Color(1.5, 0.95, 1.35) if on else Color(1.6, 1.3, 0.5)


## Boots: the feet take the boots' tint (the Wind Boots' pale blue).
var gear_boots := "leather"


func set_boots(id: String) -> void:
	if id == gear_boots:
		return
	gear_boots = id
	var tint: Color = Equipment.boots(id).get("tint", Color(1, 1, 1))
	for foot in ["FootL", "FootR"]:
		var n := find_child(foot, true, false)
		if n == null:
			continue
		for c in n.get_children():
			var mi := c as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			if tint == Color(1, 1, 1):
				mi.material_override = null
			else:
				var m := (mi.mesh.surface_get_material(0) as StandardMaterial3D)
				if m:
					var t := m.duplicate() as StandardMaterial3D
					t.albedo_color = tint
					mi.material_override = t


## The tunic and vanity outfit shown (Equipment ids; "haven" / "").
var gear_tunic := "haven"
var gear_vanity := ""
## Each mesh instance's own mesh before any recolouring.
var _base_meshes := {}
var _cape: MeshInstance3D
## Recolored meshes, shared by every model wearing the same outfit
## ("<mesh id>|<outfit>" -> ArrayMesh).
static var _outfit_cache := {}


## Dresses the hero: the tunic's colors (Equipment.TUNICS palette) or the
## vanity outfit's over them, and the outfit's cape. Only the body is
## recolored; the sword, shield, bow and face keep their own colors.
func set_outfit(tunic_id: String, vanity_id := "") -> void:
	if tunic_id == gear_tunic and vanity_id == gear_vanity:
		return
	gear_tunic = tunic_id
	gear_vanity = vanity_id
	# Dressed before it is ready (straight after instancing): find the meshes now.
	if _meshes.is_empty():
		_collect_meshes(self)
	var look: Dictionary = Equipment.vanity(vanity_id) if vanity_id != "" else Equipment.tunic(tunic_id)
	var palette: Dictionary = _garment_palette(look.get("palette", {}))
	var key := vanity_id if vanity_id != "" else tunic_id
	for mi in _meshes:
		if not is_instance_valid(mi) or mi.get_meta("no_tint", false) or not _body_mesh(mi):
			continue
		if not _base_meshes.has(mi):
			_base_meshes[mi] = mi.mesh
		var base: Mesh = _base_meshes[mi]
		mi.mesh = base if palette.is_empty() else _recoloured(base, key, palette)
	_set_cape(look.get("cape", false), look.get("cape_cols", CAPE_COLS))


## The body's own meshes (not the gear held or carried on it).
func _body_mesh(mi: MeshInstance3D) -> bool:
	for gear in [_hand_sword, _back_sword, _bow, _arm_shield, _back_shield, _hand_boomerang, find_child("SwordBack", true, false)]:
		if gear != null and (mi == gear or (gear as Node).is_ancestor_of(mi)):
			return false
	return mi.mesh is ArrayMesh and not String(mi.name).begins_with("Blush")


static func _recoloured(base: Mesh, key: String, palette: Dictionary) -> ArrayMesh:
	var ck := "%d|%s" % [base.get_instance_id(), key]
	if _outfit_cache.has(ck) and is_instance_valid(_outfit_cache[ck]):
		return _outfit_cache[ck]
	var src: Array[Color] = []
	var dst: Array[Color] = []
	for from: String in palette:
		src.append(Color.html(from))
		dst.append(Color.html(String(palette[from])))
	var out := ArrayMesh.new()
	for si in base.get_surface_count():
		var arrays := base.surface_get_arrays(si)
		var cols = arrays[Mesh.ARRAY_COLOR]
		if cols is PackedColorArray:
			var pc: PackedColorArray = cols
			for i in pc.size():
				var c := pc[i]
				for j in src.size():
					var f := src[j]
					if absf(c.r - f.r) + absf(c.g - f.g) + absf(c.b - f.b) < 0.06:
						# Keep the vertex's little shade of light or dark.
						var lum := (c.r + c.g + c.b) / maxf(f.r + f.g + f.b, 0.001)
						pc[i] = Color(dst[j].r * lum, dst[j].g * lum, dst[j].b * lum, c.a)
						break
			arrays[Mesh.ARRAY_COLOR] = pc
		out.add_surface_from_arrays(base.surface_get_primitive_type(si), arrays)
		out.surface_set_material(si, base.surface_get_material(si))
	_outfit_cache[ck] = out
	return out


## A co-op companion wears each tunic in her own cut: the hero's tunic colors
## (its red, lit and shaded) go onto her main garment and his trousers'
## onto her second (meta "garment", five colors), whatever she wears.
const HERO_GARMENT := ["8c1d17", "a3261d", "6a140f", "9b9ea3", "80838a"]


func _garment_palette(palette: Dictionary) -> Dictionary:
	if not has_meta("garment") or palette.is_empty():
		return palette
	var own: Array = get_meta("garment")
	var out := {}
	for i in HERO_GARMENT.size():
		if palette.has(HERO_GARMENT[i]) and i < own.size():
			out[String(own[i])] = palette[HERO_GARMENT[i]]
	return out


## The regalia's cape colors (cloth, its shadowed foot, the hem); an outfit
## may give its own ("cape_cols", the Knight's Tabard's blue and silver).
const CAPE_COLS := ["b01e2a", "7a1018", "d8b050"]
var _cape_cols: Array = []


## A short cape hung from the shoulders (the Knight's Regalia, the Knight's
## Tabard), made once per coloring: cloth that swings, streams back on a run
## and settles, the way Ganondorf's cape does (CapeCloth, after EnGanonMant).
func _set_cape(on: bool, cape_cols: Array = CAPE_COLS) -> void:
	if not on:
		if _cape:
			_cape.visible = false
		return
	if _cape != null and _cape_cols != cape_cols:
		_cape.queue_free()
		_cape = null
	if _cape == null:
		var torso := get_node_or_null("Hips/Torso") as Node3D
		if torso == null:
			return
		_cape_cols = cape_cols.duplicate()
		var cloth := CapeCloth.new()
		cloth.name = "Cape"
		cloth.colors = cape_cols.duplicate()
		cloth.body = self
		cloth.set_meta("no_tint", true)
		cloth.position = Vector3(0, 0.4, 0)
		_cape = cloth
		torso.add_child(_cape)
	_cape.visible = true


func _swap_mesh(holder: Node3D, mesh_name: String, path: String) -> void:
	if holder == null or not ResourceLoader.exists(path):
		return
	var mi := holder.get_node_or_null(mesh_name) as MeshInstance3D
	if mi:
		mi.mesh = load(path)


## The Bun Sword gives off magic: golden sparkles drifting off the blade (left
## behind as it swings) and a soft pulsing light, on the drawn blade and the
## hilt over the shoulder.
func _set_magic(on: bool) -> void:
	if on and _magic.is_empty():
		if _hand_sword:
			_magic.append(_sparkles(_hand_sword, Vector3(0, 0, -0.62), Vector3(0.02, 0.05, 0.5), 18))
			var light := OmniLight3D.new()
			light.name = "MagicLight"
			light.light_color = Color(1.0, 0.85, 0.4)
			light.light_energy = 0.6
			light.omni_range = 2.2
			light.position = Vector3(0, 0, -0.6)
			_hand_sword.add_child(light)
			_magic.append(light)
			_magic_light = light
		if _back_sword:
			_magic.append(_sparkles(_back_sword, Vector3(0, 0.02, 0), Vector3(0.05, 0.08, 0.05), 5))
	for n in _magic:
		n.visible = on
		if n is CPUParticles3D:
			(n as CPUParticles3D).emitting = on


func _sparkles(parent: Node3D, center: Vector3, extents: Vector3, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "MagicSparkles"
	p.position = center
	p.amount = amount
	p.lifetime = 0.8
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.gravity = Vector3(0, 0.35, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.2))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	ramp.set_color(1, Color(1.0, 0.7, 0.2, 0.0))
	p.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load("res://assets/textures/sparkle.png")
	quad.material = mat
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


## Rosy cheeks (models with a "Blush" mesh on the head: Aladriel, Idrith).
## Where a prop weapon is gripped, up its own +Y (the armory props stand
## point down, the hilt on top): Aladriel's giant sword and Idrith's scimitar.
const GRIPS := {"giant_sword_mesh": 1.46, "scimitar_mesh": 0.86}


## Puts a prop weapon (res://assets/models/<mesh>.tres) in a hand, held by
## its grip with the blade pointing out of the fist along the hand's -Z, the
## way the hero holds his sword.
static func grip_weapon(hand: Node3D, mesh: String) -> MeshInstance3D:
	var path := "res://assets/models/%s.tres" % mesh
	if hand == null or not ResourceLoader.exists(path):
		return null
	var mi := MeshInstance3D.new()
	mi.name = "Held_" + mesh
	mi.mesh = load(path)
	# The point is down the prop's -Y: turned a quarter about X, -Y runs
	# along -Z, and the grip is pulled back into the fist.
	mi.rotation = Vector3(PI / 2.0, 0, 0)
	mi.position = Vector3(0, -0.02, 0) + Basis(Vector3.RIGHT, PI / 2.0) * Vector3(0, -float(GRIPS.get(mesh, 0.0)), 0)
	hand.add_child(mi)
	return mi


func set_blush(on: bool) -> void:
	var b := get_node_or_null("Hips/Torso/Head/Blush") as Node3D
	if b:
		b.visible = on


## Bow in the left hand; the shield moves to the back meanwhile (OoT's adult
## hero slings his shield over his back when he takes out the bow).
func set_bow_out(out: bool) -> void:
	if _bow:
		_bow.visible = out
	_bow_out = out
	_place_shield()


## The bow's string (Beta 1.8.0), strung at run time between the limb tips:
## while an arrow is nocked it runs to the right fist, wherever the animation
## takes it (OoT stretches gLinkAdultBowStringDL out to the drawing hand,
## Player_PostLimbDrawGameplay), and the arrow lies from the fist across the
## bow hand. Loosed, the string snaps back and quivers. Frames are the Bow
## node's: limbs along Z, the string BOW_STRING behind the grip.
const BOW_TIP := 0.56
const BOW_STRING := 0.13
## Where the arrow crosses the bow: on the fist, just above the grip.
const ARROW_REST := Vector3(0, -0.005, 0.07)
const ARROW_SCALE := 0.8
## The arrow mesh's nock end (gen_characters: shaft along -Z, nock at +0.42).
const ARROW_NOCK := 0.42
const TWANG_TIME := 0.3
var bow_nocked := false
var _strings: Array[MeshInstance3D] = []
var _nocked_arrow: MeshInstance3D
var _arrow_kind := "-"
var _twang := 0.0
var _was_nocked := false


func _string_bow() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d8d2c2")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var box := BoxMesh.new()
	box.size = Vector3(0.006, 0.006, 1.0)
	box.material = mat
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.name = "BowString%d" % i
		mi.mesh = box
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta("no_tint", true)
		_bow.add_child(mi)
		_strings.append(mi)
		_meshes.append(mi)
	_nocked_arrow = MeshInstance3D.new()
	_nocked_arrow.name = "NockedArrow"
	_nocked_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_nocked_arrow.set_meta("no_tint", true)
	_nocked_arrow.visible = false
	_bow.add_child(_nocked_arrow)
	_meshes.append(_nocked_arrow)
	set_nocked_arrow("")


## The arrow on the string: "" (plain), "sun", "frost" or "starfall".
func set_nocked_arrow(kind: String) -> void:
	if kind == _arrow_kind or _nocked_arrow == null:
		return
	_arrow_kind = kind
	var path := "res://assets/models/%s.tres" % ("arrow_mesh" if kind == "" else kind + "_arrow_mesh")
	if not ResourceLoader.exists(path):
		path = "res://assets/models/arrow_mesh.tres"
	_nocked_arrow.mesh = load(path)


func _update_bow_string(delta: float) -> void:
	if _strings.is_empty() or not _bow.visible:
		_was_nocked = false
		return
	var top := Vector3(0, BOW_STRING, BOW_TIP)
	var bottom := Vector3(0, BOW_STRING, -BOW_TIP)
	var mid := Vector3(0, BOW_STRING, 0)
	var hand := get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	var nocked := bow_nocked and hand != null
	if nocked:
		mid = _bow.global_transform.affine_inverse() * (hand.global_transform * Vector3(0, -0.06, 0))
		# The string never passes in front of the bow.
		mid.y = maxf(mid.y, BOW_STRING)
	elif _was_nocked:
		_twang = TWANG_TIME
	_was_nocked = nocked
	if _twang > 0.0:
		_twang = maxf(_twang - delta, 0.0)
		var k := _twang / TWANG_TIME
		mid.y += sin((TWANG_TIME - _twang) * 95.0) * 0.035 * k * k
	_span(_strings[0], top, mid)
	_span(_strings[1], mid, bottom)
	_nocked_arrow.visible = nocked
	if nocked:
		var dir := (ARROW_REST - mid).normalized()
		var up := Vector3.RIGHT if absf(dir.dot(Vector3.RIGHT)) < 0.9 else Vector3.UP
		_nocked_arrow.transform = Transform3D(Basis.looking_at(dir, up).scaled_local(Vector3.ONE * ARROW_SCALE),
			mid + dir * ARROW_NOCK * ARROW_SCALE)


## Stretches a string piece (a unit-long box along Z) from `a` to `b`.
static func _span(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var length := maxf(d.length(), 0.001)
	var up := Vector3.RIGHT if absf((d / length).dot(Vector3.RIGHT)) < 0.9 else Vector3.UP
	mi.transform = Transform3D(Basis.looking_at(d / length, up).scaled_local(Vector3(1, 1, length)), (a + b) * 0.5)


## Midway between the palms (a carried object rests here). Zero if the model
## has no hands.
func palms_position() -> Vector3:
	var r := get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	var l := get_node_or_null("Hips/Torso/ShoulderL/ElbowL/HandL") as Node3D
	if r == null or l == null:
		return Vector3.ZERO
	return (r.global_transform * Vector3(0, -0.08, 0) + l.global_transform * Vector3(0, -0.08, 0)) * 0.5


## The shield slung on the back (while both hands carry something overhead).
func set_shield_on_back(on: bool) -> void:
	_carry_back = on
	_place_shield()


## The shield on the arm, or on the back for any reason that still holds.
func _place_shield() -> void:
	if _back_shield and _arm_shield:
		var back := _bow_out or _carry_back or (two_hand and _drawn)
		_back_shield.visible = back
		_arm_shield.visible = not back


## The left fist on a two-handed sword's grip, just below the right (the
## grip runs back from the right fist along the sword's +Z). A two-bone reach
## for the left arm, layered after the animation like the lean: the elbow
## keeps the side it was animated on.
const TWO_HAND_GRIP := Vector3(0, 0, 0.15)


func _two_hand_reach() -> void:
	var sh := get_node_or_null("Hips/Torso/ShoulderL") as Node3D
	var el := get_node_or_null("Hips/Torso/ShoulderL/ElbowL") as Node3D
	var hd := get_node_or_null("Hips/Torso/ShoulderL/ElbowL/HandL") as Node3D
	var hr := get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	if sh == null or el == null or hd == null or hr == null or _hand_sword == null:
		return
	for j in [sh, el, hd]:
		if not _pose_restore.has(j):
			_pose_restore[j] = j.quaternion
	# The left wrist sits where the right one does over its fist.
	var hand_off: Vector3 = hr.global_transform.basis * Vector3(0, 0.06, 0)
	var target: Vector3 = _hand_sword.global_transform * TWO_HAND_GRIP + hand_off
	var s0 := sh.global_position
	var e0 := el.global_position
	var a := s0.distance_to(e0)
	var b := e0.distance_to(hd.global_position)
	var to := target - s0
	var d := clampf(to.length(), absf(a - b) + 0.001, a + b - 0.001)
	var u := to.normalized()
	var bend := (e0 - s0) - u * (e0 - s0).dot(u)
	if bend.length() < 0.001:
		bend = global_transform.basis * Vector3(-1, -1, 0) - u * (global_transform.basis * Vector3(-1, -1, 0)).dot(u)
	var v := bend.normalized()
	var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var e1 := s0 + u * a * cos_a + v * a * sqrt(1.0 - cos_a * cos_a)
	_turn_to(sh, (e0 - s0).normalized(), (e1 - s0).normalized())
	var e_now := el.global_position
	_turn_to(el, (hd.global_position - e_now).normalized(), (s0 + u * d - e_now).normalized())
	# Both fists the same way round on the grip.
	_set_global_rotation(hd, hr.global_basis.get_rotation_quaternion())


## Turns a joint (in world space) so that `from` points along `to`.
static func _turn_to(j: Node3D, from: Vector3, to: Vector3) -> void:
	if from.length() < 0.001 or to.length() < 0.001 or from.dot(to) > 0.99999:
		return
	var q := Quaternion(from.normalized(), to.normalized())
	_set_global_rotation(j, q * j.global_basis.get_rotation_quaternion())


## Gives a joint the world rotation `q` by its local quaternion alone. Writing
## the global transform instead rebuilds the local scale too, and the frame's
## pose restore puts back only the rotation: the rounding left in the scale
## piled up swing after swing until the hand swelled and vanished.
static func _set_global_rotation(j: Node3D, q: Quaternion) -> void:
	var parent := j.get_parent() as Node3D
	var pq := parent.global_basis.get_rotation_quaternion() if parent else Quaternion.IDENTITY
	j.quaternion = (pq.inverse() * q).normalized()


## Something else in the right fist (the Hookshot, the Bloom Rod): the drawn
## sword is hidden meanwhile, as OoT's hand holds one thing at a time.
var _sword_hidden := false


func hide_hand_sword(hidden: bool) -> void:
	_sword_hidden = hidden
	if _hand_sword:
		_hand_sword.visible = _drawn and not hidden


## A prop in the right fist for `seconds` (a bottle while it is swung, drunk
## from or emptied), placed by `grip` in the hand's frame; "" takes it away.
var _prop: MeshInstance3D
var _prop_left := 0.0


func show_prop(path: String, seconds: float, grip := Transform3D.IDENTITY) -> void:
	var hand := get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	if hand == null:
		return
	if _prop == null:
		if path == "":
			return
		_prop = MeshInstance3D.new()
		_prop.name = "HandProp"
		_prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_prop.set_meta("no_tint", true)
		hand.add_child(_prop)
	_prop_left = seconds if path != "" else 0.0
	_prop.visible = path != "" and ResourceLoader.exists(path)
	if _prop.visible:
		_prop.mesh = load(path)
		_prop.transform = grip
	hide_hand_sword(_prop.visible)


## The boomerang held in the right hand while it is readied (the hero's own
## model only; it is added to the hand the first time).
func set_boomerang_in_hand(on: bool) -> void:
	if _hand_boomerang == null:
		if not on:
			return
		var hand := get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
		if hand == null:
			return
		_hand_boomerang = MeshInstance3D.new()
		_hand_boomerang.name = "HandBoomerang"
		_hand_boomerang.mesh = load("res://assets/models/boomerang_mesh.tres")
		_hand_boomerang.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hand_boomerang.position = Vector3(0, -0.1, 0.02)
		_hand_boomerang.rotation = Vector3(PI / 2.0, 0.0, 0.6)
		hand.add_child(_hand_boomerang)
		_meshes.append(_hand_boomerang)
	_hand_boomerang.visible = on


## Draws only the arms and what they hold (OoT's
## Player_OverrideLimbDrawGameplayFirstPerson, while the camera is right behind
## the head): the whole right arm, and the left forearm and hand.
func set_arms_only(on: bool) -> void:
	if on == _arms_only:
		return
	_arms_only = on
	if on:
		var arms: Array[Node] = []
		for path in ["Hips/Torso/ShoulderR", "Hips/Torso/ShoulderL/ElbowL"]:
			var n := get_node_or_null(path)
			if n:
				arms.append(n)
		# Every mesh on the body now (the cape and the vanity pieces are added
		# after _ready), save the arms; and in the fists, only what is aimed:
		# never the sword or the shield on the forearm.
		for m: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			var in_arm := false
			for a in arms:
				if a.is_ancestor_of(m):
					in_arm = true
			if in_arm and (_hand_sword and (_hand_sword == m or _hand_sword.is_ancestor_of(m)) 					or _arm_shield and (_arm_shield == m or _arm_shield.is_ancestor_of(m))):
				in_arm = false
			if not in_arm:
				_arms_hidden[m] = m.visible
				m.visible = false
	else:
		for m: MeshInstance3D in _arms_hidden:
			if is_instance_valid(m):
				m.visible = _arms_hidden[m]
		_arms_hidden.clear()


## Sets `upper_pose` from {node path: euler degrees}.
## A third layer (Beta 1.6.0): a whole animation played on a few joints over
## whatever the rest of the body does, as OoT runs its upper-body skeleton
## through its own animation (the slash from the saddle, the stab from behind
## the crouched shield). It fades in and out over UPPER_FADE.
const UPPER_FADE := 0.05
var _upper_anim: Animation
var _upper_tracks: Array = []
var _upper_t := 0.0
var _upper_speed := 1.0


## Plays `anim_name` on the joints at `paths` only (relative to the model).
func play_upper(anim_name: StringName, paths: Array, speed := 1.0) -> void:
	if not anim.has_animation(anim_name):
		return
	_upper_anim = anim.get_animation(anim_name)
	_upper_t = 0.0
	_upper_speed = speed
	_upper_tracks.clear()
	for i in _upper_anim.get_track_count():
		if _upper_anim.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var p := String(_upper_anim.track_get_path(i))
		if p in paths:
			var j := get_node_or_null(p) as Node3D
			if j:
				_upper_tracks.append([i, j])


func stop_upper() -> void:
	_upper_anim = null
	_upper_tracks.clear()


func upper_playing() -> bool:
	return _upper_anim != null


func _apply_upper_anim(delta: float) -> void:
	if _upper_anim == null:
		return
	_upper_t += delta * _upper_speed
	var length := _upper_anim.length
	if _upper_t >= length:
		stop_upper()
		return
	var w := minf(minf(_upper_t, length - _upper_t) / UPPER_FADE, 1.0)
	for tr: Array in _upper_tracks:
		var j: Node3D = tr[1]
		if not _pose_restore.has(j):
			_pose_restore[j] = j.quaternion
		var q: Quaternion = _upper_anim.rotation_track_interpolate(tr[0], _upper_t)
		j.quaternion = j.quaternion.slerp(q, w)


func set_upper_pose(pose: Dictionary) -> void:
	_begin_upper_fade(UPPER_SWAP)
	_uclip = null
	_uclip_name = &""
	upper_pose.clear()
	for path: String in pose:
		var j := get_node_or_null(path) as Node3D
		if j:
			var e: Vector3 = pose[path]
			upper_pose[j] = Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))


## The upper body's clip (Beta 1.8.0): in place of a still `upper_pose`, an
## animation on some joints over whatever the legs do, as OoT runs its upper
## skeleton through bow_bow_ready, bow_bow_wait, bow_bow_shoot_next... while
## the legs stand or walk. A clip holds its last frame or loops; a new pose or
## clip eases in from what the layer showed over UPPER_SWAP (OoT morphs the
## upper skeleton the same way), and `upper_weight` still fades the layer.
const UPPER_SWAP := 0.08
var _uclip: Animation
var _uclip_name := &""
var _uclip_t := 0.0
var _uclip_loop := false
var _uclip_speed := 1.0
var _uclip_tracks: Array = []
## What the layer showed last frame, and when it changed (joint -> Quaternion).
var _upper_shown := {}
var _upper_from := {}
var _upper_fade := 0.0
var _upper_fade_t := 0.0


## Plays `anim_name` on the joints at `paths` as the upper layer, from `start`
## seconds in. Asking again for the clip already playing only sets its speed.
func set_upper_clip(anim_name: StringName, paths: Array, loop := false, speed := 1.0, start := 0.0) -> void:
	if anim_name == _uclip_name and _uclip != null:
		_uclip_speed = speed
		return
	if not anim.has_animation(anim_name):
		return
	_begin_upper_fade(UPPER_SWAP)
	upper_pose.clear()
	_uclip = anim.get_animation(anim_name)
	_uclip_name = anim_name
	_uclip_t = start
	_uclip_loop = loop
	_uclip_speed = speed
	_uclip_tracks.clear()
	for i in _uclip.get_track_count():
		if _uclip.track_get_type(i) != Animation.TYPE_ROTATION_3D:
			continue
		var p := String(_uclip.track_get_path(i))
		if p in paths:
			var j := get_node_or_null(p) as Node3D
			if j:
				_uclip_tracks.append([i, j])


func upper_clip() -> StringName:
	return _uclip_name


## How far the upper clip has played (seconds).
func upper_clip_time() -> float:
	return _uclip_t


func _begin_upper_fade(time: float) -> void:
	_upper_from = _upper_shown.duplicate()
	_upper_fade = time
	_upper_fade_t = 0.0


## The rotations the upper layer shows this frame (joint -> Quaternion).
func _upper_targets(delta: float) -> Dictionary:
	var out := {}
	if _uclip != null:
		_uclip_t += delta * _uclip_speed
		var length := _uclip.length
		var t := fposmod(_uclip_t, length) if _uclip_loop else minf(_uclip_t, length)
		for tr: Array in _uclip_tracks:
			out[tr[1]] = _uclip.rotation_track_interpolate(tr[0], t)
	else:
		for j: Node3D in upper_pose:
			out[j] = upper_pose[j]
	return out


## Multiplies every tintable surface by `color` (used for enemy color variants).
func set_tint(color: Color) -> void:
	for m in _meshes:
		if m.has_meta("no_tint") or m.mesh == null:
			continue
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat is StandardMaterial3D:
				var tinted: StandardMaterial3D = mat.duplicate()
				tinted.albedo_color = color
				m.set_surface_override_material(s, tinted)


## Briefly renders the whole model as a flat color (hit feedback).
func flash(color: Color, duration := 0.08) -> void:
	_flash_material.albedo_color = color
	for m in _meshes:
		m.material_override = _flash_material
	_flash_time = duration


func _process(delta: float) -> void:
	# Remove last frame's lean, advance the animation, then layer the new lean.
	for j: Node3D in _pose_restore:
		j.quaternion = _pose_restore[j]
	_pose_restore.clear()
	if _torso:
		_torso.quaternion = _torso.quaternion * _torso_offset.inverse()
		_head.quaternion = _head.quaternion * _head_offset.inverse()
	anim.advance(delta)
	if _torso:
		_torso_offset = Quaternion(Vector3.UP, upper_turn.x) * Quaternion(Vector3.RIGHT, -lean.x - upper_turn.y) 			* Quaternion(Vector3.BACK, lean.y)
		# The head counters half the lean, then turns toward whatever it looks at.
		_head_offset = Quaternion(Vector3.RIGHT, lean.x * 0.5) * Quaternion(Vector3.BACK, -lean.y * 0.5) 			* Quaternion(Vector3.UP, look.x) * Quaternion(Vector3.RIGHT, look.y)
		_torso.quaternion = _torso.quaternion * _torso_offset
		_head.quaternion = _head.quaternion * _head_offset
	var targets := _upper_targets(delta)
	_upper_fade_t += delta
	var k := 1.0 if _upper_fade <= 0.0 else smoothstep(0.0, 1.0, _upper_fade_t / _upper_fade)
	for j: Node3D in targets:
		var q: Quaternion = targets[j]
		if k < 1.0 and _upper_from.has(j):
			q = (_upper_from[j] as Quaternion).slerp(q, k)
		_upper_shown[j] = q
		if upper_weight > 0.0:
			_pose_restore[j] = j.quaternion
			j.quaternion = j.quaternion.slerp(q, upper_weight)
	_apply_upper_anim(delta)
	if _torso and (aim_pitch != 0.0 or aim_kick > 0.0):
		if not _pose_restore.has(_torso):
			_pose_restore[_torso] = _torso.quaternion
		_torso.quaternion = _torso.quaternion * Quaternion(Vector3.UP, aim_kick * 0.06) * Quaternion(Vector3.RIGHT, aim_pitch + aim_kick * 0.1)
		aim_kick = maxf(aim_kick - delta / 0.18, 0.0)
	if two_hand and _drawn and _hand_sword and _hand_sword.visible:
		_two_hand_reach()
	_update_bow_string(delta)
	if _prop_left > 0.0:
		_prop_left -= delta
		if _prop_left <= 0.0:
			show_prop("", 0.0)
	if _magic_light and _magic_light.visible:
		_magic_time += delta
		_magic_light.light_energy = 0.55 + 0.2 * sin(_magic_time * 4.0)
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0:
			for m in _meshes:
				m.material_override = null
