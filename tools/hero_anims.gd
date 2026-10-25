extends RefCounted
## Sir Gigglebuns' item, idle and stance animations (Beta 1.8.0), built from
## whole poses like gen_characters._pose_anim, but with two differences:
##
## - Arms can be placed by where the fist goes (`arm`, a two-bone reach), so
##   the bow's grip sits under the reticle and the drawing fist at the cheek,
##   as the first-person view needs (OoT's adult bow view, CAM_MODE_AIM_ADULT:
##   the eye 14 units behind the head, the bow fist low in the middle, the
##   string fist at the bottom corner, the bow canted across the view).
## - Poses are kept as quaternions and eased through on a spherical cubic
##   (Quaternion.spherical_cubic_interpolate_in_time) at 30 keys a second. An
##   arm held straight out sits at the Euler gimbal lock (X = 90), where easing
##   each angle on its own (gen_characters._smooth_keys) can twist the arm
##   round between two keys a few degrees apart.
##
## gen_characters builds the hero's skeleton; its _anim does the keying.
##
## Co-op (Beta 1.9.0): the same set is built for the playable companions,
## whose skeleton is smaller (lady()). Poses are written for the hero; every
## position in them (the hips, the fists' targets) is scaled by `measure` as it is
## used, the bone lengths come from the skeleton settings, and the IK solves
## the companion's own arms to the scaled targets.

var g: Object
var lib: AnimationLibrary
var rest: Dictionary

const RATE := 30.0
## The hero's skeleton (gen_characters._build_gigglebuns); poses are written
## in its measure.
const HIPS := Vector3(0, 0.92, 0)
## The fist's middle below the wrist (the Sword node), and the bow's grip
## (the Bow node), for the hero.
const FIST := 0.06
const GRIP := 0.07
## The skeleton being animated (the hero's unless lady() says otherwise):
## the torso and shoulder joints, the arm bones, how much smaller the hand
## is than his, and `measure`, the scale from his measure to this one's.
var torso_at := Vector3(0, 0.08, 0)
var shoulder_at := Vector3(0.2, 0.33, 0)
var upper := 0.27
var fore := 0.23
var hand_k := 1.0
var measure := 1.0
## Where the aiming camera looks from (PlayerController.aim_origin with the
## bow): eye height 1.68 less OoT's atOffset (3 units down).
const SIGHT_Y := 1.59

## The standing ready stance (gen_characters._gigglebuns_anims).
var STAND := {
	"hips@pos": HIPS,
	"shoulder_r": Vector3(10, 0, 8), "elbow_r": Vector3(35, 0, 0), "hand_r": Vector3(-20, 0, 0),
	"shoulder_l": Vector3(5, 0, -10), "elbow_l": Vector3(20, 0, 0),
	"leg_r": Vector3(0, 0, 3), "leg_l": Vector3(0, 0, -3),
}


func _init(generator: Object, library: AnimationLibrary, rest_pos: Dictionary) -> void:
	g = generator
	lib = library
	rest = rest_pos


## The companions' skeleton (gen_characters._build_woman and _build_mira):
## hips at 0.84, shoulders 0.165 out and 0.3 up the torso, a 0.24 upper arm
## and a 0.21 forearm, a smaller fist.
func lady() -> RefCounted:
	torso_at = Vector3(0, 0.07, 0)
	shoulder_at = Vector3(0.165, 0.3, 0)
	upper = 0.24
	fore = 0.21
	hand_k = 0.85
	measure = 0.84 / HIPS.y
	return self


func build() -> void:
	_aim_anims()
	_move_anims()
	_idle_anims()
	_combat_anims()
	_item_anims()
	_sword_anims()
	_rework_moves()
	_rework_traverse()
	_rework_misc()


# --- Building --------------------------------------------------------------------

static func _q(v: Variant) -> Quaternion:
	if v is Quaternion:
		return v
	var e: Vector3 = v
	return Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))


static func _basis(v: Variant) -> Basis:
	return Basis(_q(v))


## `a` with `b`'s entries over it.
static func with(a: Dictionary, b: Dictionary) -> Dictionary:
	var c := a.duplicate()
	c.merge(b, true)
	return c


## An animation from whole poses: keys = [[time, pose], ...]; a joint a pose
## leaves out holds `base`'s value (or rest). Rotations are eased through on a
## spherical cubic, positions on a cubic, sampled RATE times a second.
func clip(anim_name: String, length: float, keys: Array, base: Dictionary, loop := false) -> void:
	# A newer take on one of gen_characters' animations replaces it.
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	var joints := {}
	for k in keys:
		for j in (k[1] as Dictionary):
			joints[j] = true
	for j in base:
		joints[j] = true
	var times: Array[float] = []
	for k in keys:
		times.append(float(k[0]))
	var n := times.size()
	var data := {}
	for j: String in joints:
		var is_pos := j.ends_with("@pos")
		var vals: Array = []
		for k in keys:
			var pose: Dictionary = k[1]
			var v: Variant = pose.get(j, base.get(j, HIPS if is_pos else Vector3.ZERO))
			vals.append((v as Vector3) * measure if is_pos else _q(v))
		if not is_pos:
			# Keep each quaternion on the same side as the one before it.
			for i in range(1, n):
				if (vals[i] as Quaternion).dot(vals[i - 1]) < 0.0:
					vals[i] = -(vals[i] as Quaternion)
		var out: Array = []
		var t := 0.0
		var step := 1.0 / RATE
		var stamps: Array[float] = []
		while t < length - 1e-4:
			stamps.append(t)
			t += step
		for tt in times:
			if not stamps.has(tt):
				stamps.append(tt)
		stamps.append(length)
		stamps.sort()
		for s in stamps:
			out.append([s, _sample(vals, times, s, loop, length, is_pos)])
		data[j] = out
	g._anim(lib, anim_name, length, loop, data, rest, false)


func _sample(vals: Array, times: Array[float], t: float, loop: bool, length: float, is_pos: bool) -> Variant:
	var n := times.size()
	var v: Variant
	if n == 1 or t <= times[0] and not loop:
		v = vals[0]
	elif t >= times[n - 1] and not loop:
		v = vals[n - 1]
	else:
		# The segment holding t, with its neighbours (wrapped round a loop;
		# a loop's last key returns to its first at `length`).
		var tv := times.duplicate()
		var vv := vals.duplicate()
		if loop:
			tv.append(length)
			vv.append(vals[0])
		var m := tv.size()
		var i := 0
		while i < m - 2 and t >= tv[i + 1]:
			i += 1
		var a: Variant = vv[i]
		var b: Variant = vv[i + 1]
		var ta: float = tv[i]
		var tb: float = tv[i + 1]
		var pre: Variant = vv[i - 1] if i > 0 else (vv[m - 2] if loop else a)
		var tpre: float = tv[i - 1] if i > 0 else ((tv[m - 2] - length) if loop else ta - (tb - ta))
		var post: Variant = vv[i + 2] if i + 2 < m else (vv[1] if loop else b)
		var tpost: float = tv[i + 2] if i + 2 < m else ((tv[1] + length) if loop else tb + (tb - ta))
		var h := maxf(tb - ta, 1e-5)
		var w := clampf((t - ta) / h, 0.0, 1.0)
		if is_pos:
			var pa: Vector3 = a
			v = pa.cubic_interpolate_in_time(b, pre, post, w, h, tpre - ta, tpost - ta)
		else:
			var qa: Quaternion = a
			var qb: Quaternion = b
			var qpre: Quaternion = pre
			var qpost: Quaternion = post
			if qb.dot(qa) < 0.0:
				qb = -qb
			if qpre.dot(qa) < 0.0:
				qpre = -qpre
			if qpost.dot(qb) < 0.0:
				qpost = -qpost
			if qa.is_equal_approx(qb):
				v = qa
			else:
				v = qa.spherical_cubic_interpolate_in_time(qb, qpre, qpost, w, h, tpre - ta, tpost - ta)
	if is_pos:
		return v
	var e := (v as Quaternion).normalized().get_euler()
	return Vector3(rad_to_deg(e.x), rad_to_deg(e.y), rad_to_deg(e.z))


# --- Reaching ------------------------------------------------------------------

## The torso's frame in the model for a pose (hips rotation and position too).
func chest(body: Dictionary) -> Transform3D:
	var hb := _basis(body.get("hips", Vector3.ZERO))
	var hp: Vector3 = body.get("hips@pos", HIPS) * measure
	var tb := hb * _basis(body.get("torso", Vector3.ZERO))
	return Transform3D(tb, hp + hb * torso_at)


## Two-bone reach for one arm (side +1 right, -1 left): the shoulder, elbow and
## wrist rotations that put the fist's middle (or, with `grip` = GRIP, the bow's
## grip) at `fist`, in the model's frame. `pole` is the way the elbow points;
## `hand_z` the way the hand's +Z should lie (a held item points along the
## hand's -Z; the bow's limbs run along +Z). The wrist stays in line with the
## forearm, as with N64-style rigid fists, unless `wrist` lets the hand turn
## so its +Z lies exactly along `hand_z` (the bow's tilt). An out-of-reach
## fist is reached for with a straight arm.
## `fist` is in the hero's measure unless `raw` (already in this skeleton's).
func arm(side: float, body: Dictionary, fist: Vector3, pole: Vector3, hand_z: Vector3, grip := FIST, wrist := false, raw := false) -> Dictionary:
	var sfx := "_r" if side > 0.0 else "_l"
	var c := chest(body)
	var s := c * Vector3(shoulder_at.x * side, shoulder_at.y, 0)
	if not raw:
		fist *= measure
	grip *= hand_k
	var a := upper
	var b := fore + grip
	var target := fist
	if wrist:
		# The hand turns away from the forearm: reach the wrist instead, which
		# sits back from the fist along the hand's +Y (refined a few times, as
		# that axis depends on where the forearm ends up).
		b = fore
		var hz := hand_z.normalized()
		var guess := (s - fist)
		for i in 4:
			var hy := (guess - hz * guess.dot(hz)).normalized()
			target = fist + hy * grip
			var r := arm(side, body, target, pole, hand_z, 0.0, false, true)
			var t := chest(body) * Transform3D(_basis(r["shoulder" + sfx]), Vector3(shoulder_at.x * side, shoulder_at.y, 0))
			t = t * Transform3D(_basis(r["elbow" + sfx]), Vector3(0, -upper, 0))
			guess = t.origin - target
	var to := target - s
	var d := clampf(to.length(), absf(a - b) + 0.002, a + b - 0.0005)
	var u := to.normalized()
	var v := pole - u * pole.dot(u)
	if v.length() < 0.001:
		v = c.basis * Vector3(side, -1, 0.5)
		v -= u * v.dot(u)
	v = v.normalized()
	var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var e := s + u * a * cos_a + v * a * sqrt(1.0 - cos_a * cos_a)
	var up := (e - s) / a
	var f := ((s + u * d) - e).normalized()
	# The upper arm hangs down its -Y; the elbow bends the forearm toward the
	# shoulder's -Z, so +Z is the way the elbow points.
	var sy := -up
	var sz := (v - up * v.dot(up)).normalized()
	var bs := Basis(sy.cross(sz), sy, sz).orthonormalized()
	var beta := acos(clampf(up.dot(f), -1.0, 1.0))
	var be := bs * Basis(Vector3.RIGHT, beta)
	var hy := -f
	var hz := hand_z - hy * hand_z.dot(hy)
	if hz.length() < 0.001:
		hz = be.z
	hz = hz.normalized()
	if wrist:
		hz = hand_z.normalized()
		hy = (hy - hz * hy.dot(hz)).normalized()
	var hb := Basis(hy.cross(hz), hy, hz).orthonormalized()
	return {
		"shoulder" + sfx: (c.basis.inverse() * bs).get_rotation_quaternion(),
		"elbow" + sfx: Quaternion(Vector3.RIGHT, beta),
		"hand" + sfx: (be.inverse() * hb).get_rotation_quaternion(),
	}


## The arm held out along `dir` (a pointing forearm: the Hookshot and the
## Bloom Rod sit in the fist along the forearm, like a pistol), with the fist
## as near `fist` as the arm's length allows: it slides along the line of
## `dir` until the upper arm reaches the elbow. `hand_z` sets the fist's roll.
func arm_point(side: float, body: Dictionary, fist: Vector3, dir: Vector3, hand_z: Vector3) -> Dictionary:
	var sfx := "_r" if side > 0.0 else "_l"
	var c := chest(body)
	var s := c * Vector3(shoulder_at.x * side, shoulder_at.y, 0)
	fist *= measure
	var f := dir.normalized()
	var b := fore + FIST * hand_k
	var p0 := fist - f * b - s
	# |p0 + t f| = upper, the root nearest the asked-for fist.
	var pb := p0.dot(f)
	var disc := pb * pb - (p0.length_squared() - upper * upper)
	var t := 0.0
	if disc >= 0.0:
		var r1 := -pb + sqrt(disc)
		var r2 := -pb - sqrt(disc)
		t = r1 if absf(r1) < absf(r2) else r2
	var e := s + (p0 + f * t).normalized() * upper
	var up := (e - s) / upper
	var bend := f - up * f.dot(up)
	var sz := (-bend).normalized() if bend.length() > 0.001 else (c.basis * Vector3(side, -1, 0.5)).normalized()
	sz = (sz - up * sz.dot(up)).normalized()
	var sy := -up
	var bs := Basis(sy.cross(sz), sy, sz).orthonormalized()
	var beta := acos(clampf(up.dot(f), -1.0, 1.0))
	var be := bs * Basis(Vector3.RIGHT, beta)
	var hy := -f
	var hz := hand_z - hy * hand_z.dot(hy)
	if hz.length() < 0.001:
		hz = be.z
	hz = hz.normalized()
	var hb := Basis(hy.cross(hz), hy, hz).orthonormalized()
	return {
		"shoulder" + sfx: (c.basis.inverse() * bs).get_rotation_quaternion(),
		"elbow" + sfx: Quaternion(Vector3.RIGHT, beta),
		"hand" + sfx: (be.inverse() * hb).get_rotation_quaternion(),
	}


## The hand joint's frame in the model for a pose (two-handed grips find the
## second fist's place on the haft from it).
func hand_xform(side: float, pose: Dictionary) -> Transform3D:
	var sfx := "_r" if side > 0.0 else "_l"
	var t := chest(pose) * Transform3D(_basis(pose.get("shoulder" + sfx, Vector3.ZERO)), Vector3(shoulder_at.x * side, shoulder_at.y, 0))
	t = t * Transform3D(_basis(pose.get("elbow" + sfx, Vector3.ZERO)), Vector3(0, -upper, 0))
	return t * Transform3D(_basis(pose.get("hand" + sfx, Vector3.ZERO)), Vector3(0, -fore, 0))


## The left fist on the haft the right fist holds (a mallet, a spade), `along`
## further down it (the haft runs along the right hand's -Z).
func second_hand(pose: Dictionary, along: float, pole := Vector3(-0.6, -1, 0.3)) -> Dictionary:
	var h := hand_xform(1.0, pose)
	var at := h * Vector3(0, -FIST * hand_k, -along * measure)
	return with(pose, arm(-1.0, pose, at, pole, h.basis.z, FIST, false, true))


## Where a pose puts a fist (or the bow's grip): for checking the reach.
func fist_of(side: float, pose: Dictionary, grip := FIST) -> Vector3:
	var sfx := "_r" if side > 0.0 else "_l"
	var c := chest(pose)
	var t := c * Transform3D(_basis(pose.get("shoulder" + sfx, Vector3.ZERO)), Vector3(shoulder_at.x * side, shoulder_at.y, 0))
	t = t * Transform3D(_basis(pose.get("elbow" + sfx, Vector3.ZERO)), Vector3(0, -upper, 0))
	t = t * Transform3D(_basis(pose.get("hand" + sfx, Vector3.ZERO)), Vector3(0, -fore, 0))
	return t * Vector3(0, -grip * hand_k, 0)


## A pose: the body's joints with both arms reached by `reaches`
## ([side, fist, pole, hand_z, grip?, wrist?], ...).
func reach(body: Dictionary, reaches: Array) -> Dictionary:
	var pose := body.duplicate()
	for r: Array in reaches:
		var grip: float = r[4] if r.size() > 4 else FIST
		var wrist: bool = r[5] if r.size() > 5 else false
		pose.merge(arm(r[0], body, r[1], r[2], r[3], grip, wrist), true)
	return pose


# --- First person: the bow, the Hookshot, the boomerang, the Bloom Rod ------------

## The upper body's joints the item animations play on (over the legs).
const ARMS := ["torso", "head", "shoulder_r", "elbow_r", "hand_r", "shoulder_l", "elbow_l", "hand_l"]


func _aim_anims() -> void:
	var low := with(STAND, {})
	# -- The bow (gPlayerAnim_link_bow_bow_ready / _wait / _shoot_next / _end).
	# The archer stands side-on (the torso turned 35 degrees, the bow shoulder
	# forward), the head turned back to the target with the cheek to the string.
	# Seen from the aiming eye, as in OoT's bow view (mirrored: this hero holds
	# the bow in his left hand): the bow fist low in the middle, the bow canted
	# with its top leaning right, the string fist just under the bottom edge
	# and the arrow running up out of it to the bow.
	var side_on := {"torso": Vector3(-2, -35, 0), "head": Vector3(-2, 33, -6)}
	var cant := Vector3(sin(deg_to_rad(20)), cos(deg_to_rad(20)), 0.0)
	var grip := Vector3(-0.04, 1.39, -0.6)
	var bow_elbow := Vector3(-0.4, -1.0, 0.15)
	# Drawn to the jaw, beside the face.
	var anchor := Vector3(0.08, 1.41, -0.07)
	var draw_elbow := Vector3(1.0, 0.45, 0.8)
	var fist_up := Vector3(0, 1, 0)
	var drawn := reach(side_on, [[-1.0, grip, bow_elbow, cant, GRIP, true], [1.0, anchor, draw_elbow, fist_up]])
	# Nocking low, below the view: the bow held down and across, the fist
	# at the string behind the grip.
	var low_grip := Vector3(-0.1, 1.18, -0.46)
	var low_cant := Vector3(sin(deg_to_rad(55)), cos(deg_to_rad(55)), 0.0)
	var nocking := reach(with(side_on, {"torso": Vector3(4, -26, 0), "head": Vector3(6, 24, 0)}),
		[[-1.0, low_grip, bow_elbow, low_cant, GRIP, true], [1.0, low_grip + Vector3(0.1, 0.02, 0.14), Vector3(1, -0.6, 0.3), fist_up]])
	# Fetching the arrow: the right fist down by the hip.
	var fetch := reach(with(side_on, {"torso": Vector3(4, -20, 0), "head": Vector3(4, 18, 0)}),
		[[-1.0, low_grip + Vector3(-0.04, -0.04, 0.06), bow_elbow, low_cant, GRIP, true], [1.0, Vector3(0.26, 1.0, 0.04), Vector3(0.5, 0, 1), fist_up]])
	# Raising the bow from the side, the fist at the hip.
	var raise := reach(with(STAND, {"torso": Vector3(0, -12, 0)}),
		[[-1.0, Vector3(-0.22, 1.05, -0.3), Vector3(-1, -0.5, 0.3), Vector3(0.6, 0.6, -0.4), GRIP, true], [1.0, Vector3(0.24, 1.0, 0.0), Vector3(0.5, 0, 1), fist_up]])
	clip("bow_ready", 0.3, [[0.0, raise], [0.08, fetch], [0.16, nocking], [0.3, drawn]], low)
	# Held at full draw: breathing, the string fist creeping back a little.
	var breathe := reach(with(side_on, {"torso": Vector3(-3, -35.5, 0)}),
		[[-1.0, grip + Vector3(0, 0.006, 0), bow_elbow, cant.rotated(Vector3.BACK, 0.012), GRIP, true], [1.0, anchor + Vector3(0.004, 0.004, 0.012), draw_elbow, fist_up]])
	clip("bow_wait", 1.8, [[0.0, drawn], [0.9, breathe]], low, true)
	# The loose: the string fist flies back past the jaw and out, the bow arm
	# pushes on and the bow rolls forward in the fist.
	var loose := reach(with(side_on, {"torso": Vector3(-1, -37, 0), "head": Vector3(-2, 34, -4)}),
		[[-1.0, grip + Vector3(-0.01, -0.03, -0.03), bow_elbow, cant.rotated(Vector3.RIGHT, -0.35), GRIP, true],
		[1.0, anchor + Vector3(0.1, 0.04, 0.12), draw_elbow + Vector3(0.4, 0.2, 0.3), fist_up]])
	var after := reach(with(side_on, {"torso": Vector3(-2, -33, 0)}),
		[[-1.0, grip + Vector3(0, -0.015, -0.01), bow_elbow, cant.rotated(Vector3.RIGHT, -0.12), GRIP, true],
		[1.0, anchor + Vector3(0.13, 0.02, 0.14), draw_elbow + Vector3(0.4, 0.0, 0.3), fist_up]])
	clip("bow_shoot", 0.4, [[0.0, drawn], [0.05, loose], [0.18, after], [0.4, after]], low)
	# The next arrow (bow_shoot_next): fetched from the hip, nocked and drawn.
	clip("bow_next", 0.3, [[0.0, after], [0.08, fetch], [0.16, nocking], [0.3, drawn]], low)
	if OS.get_environment("G64_ANIM_CHECK") != "":
		print("BOW grip ", fist_of(-1.0, drawn, GRIP), " anchor ", fist_of(1.0, drawn), " (wanted ", grip, " ", anchor, ")")

	# -- The Hookshot (gPlayerAnim_link_hook_shot_ready / hook_wait): held out
	# at arm's length in the right fist like a pistol (it sits along the
	# forearm: PlayerController._show_hookshot), low at the right of the view
	# and pointing at the reticle; the shield arm low and out of the way.
	var hook_body := {"torso": Vector3(-2, 10, 0), "head": Vector3(0, -8, 0)}
	var hook_fist := Vector3(0.12, 1.42, -0.5)
	var at_reticle := (Vector3(0, SIGHT_Y, -12.0) - hook_fist).normalized()
	var grip_down := Vector3(0, -1, 0)
	var guard_l := Vector3(-0.3, 1.0, -0.12)
	var guard := [-1.0, guard_l, Vector3(-1, -0.2, 0.6), Vector3(0, 0, 1)]
	var held_out := func(body: Dictionary, fist: Vector3, dir: Vector3) -> Dictionary:
		var pose := reach(body, [guard])
		pose.merge(arm_point(1.0, body, fist, dir, grip_down), true)
		return pose
	var aimed: Dictionary = held_out.call(hook_body, hook_fist, at_reticle)
	var hook_up: Dictionary = held_out.call(with(STAND, {"torso": Vector3(0, 4, 0)}), Vector3(0.24, 1.15, -0.3), Vector3(0.1, -0.5, -1))
	clip("hook_ready", 0.3, [[0.0, low], [0.12, hook_up], [0.3, aimed]], low)
	var hook_breathe: Dictionary = held_out.call(with(hook_body, {"torso": Vector3(-3, 10.5, 0)}), hook_fist + Vector3(0, 0.006, 0), at_reticle)
	clip("hook_wait", 1.8, [[0.0, aimed], [0.9, hook_breathe]], low, true)
	# The kick as the chain fires: the fist jolts up and back, the muzzle lifts.
	var kick: Dictionary = held_out.call(with(hook_body, {"torso": Vector3(2, 12, 0)}), hook_fist + Vector3(0.01, 0.05, 0.07), at_reticle.rotated(Vector3.RIGHT, 0.3))
	clip("hook_fire", 0.4, [[0.0, aimed], [0.04, kick], [0.2, aimed], [0.4, aimed]], low)

	# -- The Bloom Rod: held out like a wand, tip up a little, then flicked.
	var rod_dir := (Vector3(0, SIGHT_Y + 1.6, -12.0) - hook_fist).normalized()
	var rod: Dictionary = held_out.call(hook_body, hook_fist + Vector3(0, -0.02, 0.04), rod_dir)
	clip("rod_ready", 0.3, [[0.0, low], [0.12, hook_up], [0.3, rod]], low)
	var rod_breathe: Dictionary = held_out.call(with(hook_body, {"torso": Vector3(-3, 10.5, 0)}), hook_fist + Vector3(0, -0.014, 0.04), rod_dir.rotated(Vector3.RIGHT, 0.03))
	clip("rod_wait", 1.8, [[0.0, rod], [0.9, rod_breathe]], low, true)
	# Cocked back (the tip high over the shoulder), then snapped forward.
	var rod_cock: Dictionary = held_out.call(with(hook_body, {"torso": Vector3(4, 16, 0)}), hook_fist + Vector3(0.03, 0.1, 0.16), rod_dir.rotated(Vector3.RIGHT, 0.8))
	var rod_snap: Dictionary = held_out.call(with(hook_body, {"torso": Vector3(-8, 4, 0)}), hook_fist + Vector3(-0.02, -0.05, -0.08), rod_dir.rotated(Vector3.RIGHT, -0.4))
	clip("rod_flick", 0.4, [[0.0, rod], [0.06, rod_cock], [0.12, rod_snap], [0.26, rod], [0.4, rod]], low)

	# -- The boomerang (boom_throw_wait2waitR / waitR / throwR / catch): drawn
	# back beside the right ear with the body wound up, then flung forward
	# across the body (it leaves the hand at 0.2 s) and followed through.
	var wound := {"torso": Vector3(4, 28, 0), "head": Vector3(0, -24, 0)}
	var cocked := reach(wound, [[1.0, Vector3(0.36, 1.66, 0.1), Vector3(0.8, -0.6, 0.5), Vector3(0.3, 0.2, 1)], [-1.0, Vector3(-0.3, 1.04, -0.16), Vector3(-1, -0.5, 0.2), Vector3(0, 0, 1)]])
	clip("boom_ready", 0.25, [[0.0, low], [0.25, cocked]], low)
	var cocked_b := reach(with(wound, {"torso": Vector3(3, 29, 0)}), [[1.0, Vector3(0.37, 1.67, 0.11), Vector3(0.8, -0.6, 0.5), Vector3(0.3, 0.2, 1)], [-1.0, Vector3(-0.3, 1.03, -0.16), Vector3(-1, -0.5, 0.2), Vector3(0, 0, 1)]])
	clip("boom_wait", 1.6, [[0.0, cocked], [0.8, cocked_b]], low, true)
	var whip := reach({"torso": Vector3(-6, 8, 0), "head": Vector3(0, -6, 0)},
		[[1.0, Vector3(0.24, 1.6, -0.34), Vector3(0.9, -0.3, 0.2), Vector3(0.2, 0.4, 1)], [-1.0, Vector3(-0.3, 1.2, -0.1), Vector3(-1, -0.5, 0.4), Vector3(0, 0, 1)]])
	var let_go := reach({"torso": Vector3(-10, -12, 0), "head": Vector3(0, 10, 0)},
		[[1.0, Vector3(0.06, 1.44, -0.56), Vector3(0.9, -0.6, 0.0), Vector3(0, 0.3, 1)], [-1.0, Vector3(-0.3, 1.1, 0.0), Vector3(-1, -0.5, 0.4), Vector3(0, 0, 1)]])
	var across := reach({"torso": Vector3(-12, -26, 0), "head": Vector3(0, 22, 0)},
		[[1.0, Vector3(-0.16, 1.2, -0.4), Vector3(0.5, -1, 0.0), Vector3(0, 0.6, 1)], [-1.0, Vector3(-0.3, 1.05, 0.08), Vector3(-1, -0.5, 0.4), Vector3(0, 0, 1)]])
	clip("boom_throw", 0.55, [[0.0, cocked], [0.12, whip], [0.2, let_go], [0.32, across], [0.55, low]], low)
	# Catching it on its way back: the right hand snaps up in front of the
	# face and the catch is pulled in to the chest.
	var snatch := reach({"torso": Vector3(4, 12, 0), "head": Vector3(-8, -6, 0)}, [[1.0, Vector3(0.18, 1.62, -0.42), Vector3(0.9, -0.6, 0.1), Vector3(0, 0.4, 1)]])
	var tuck := reach({"torso": Vector3(-6, 6, 0)}, [[1.0, Vector3(0.14, 1.3, -0.24), Vector3(1, -0.6, 0.3), Vector3(0, 0.6, 1)]])
	clip("boom_catch", 0.5, [[0.0, low], [0.08, snatch], [0.24, tuck], [0.5, low]], low)


# --- Moving: the gaits, the leap, the fall and landing, rolls and hops -----------

## Walk and run cycles (replacing gen_characters' gait). One stride of two
## steps, the right foot down at the start and the left halfway (footsteps
## key off those). Eight poses a stride, as before, with what OoT's
## link_normal_run / _walk and Twilight Princess' run show more of: the heel
## striking and the toe pushing off, the shoulders turning against the hips,
## the head held level over the bob, and in the run a forward lean, high knees
## and fists pumping close to the body.
func _move_anims() -> void:
	_gait("walk", 0.84, false)
	_gait("run", 0.56, true)
	_gait("run_sword", 0.56, true, true)

	# The leap off a ledge (OoT's run-off jump, link_normal_jump): a stride
	# into the air, lead knee up, trailing leg back, arms thrown against them.
	var push := with(STAND, {
		"hips@pos": Vector3(0, 0.84, 0), "torso": Vector3(-16, 0, 0), "head": Vector3(10, 0, 0),
		"leg_r": Vector3(30, 0, 3), "knee_r": Vector3(-60, 0, 0), "foot_r": Vector3(28, 0, 0),
		"leg_l": Vector3(-14, 0, -3), "knee_l": Vector3(-20, 0, 0), "foot_l": Vector3(34, 0, 0),
		"shoulder_r": Vector3(-30, 0, 18), "elbow_r": Vector3(40, 0, 0), "shoulder_l": Vector3(40, 0, -16), "elbow_l": Vector3(60, 0, 0),
	})
	var stride := with(STAND, {
		"hips@pos": Vector3(0, 0.95, 0), "torso": Vector3(-8, 6, 0), "head": Vector3(2, -4, 0),
		"leg_r": Vector3(62, 0, 4), "knee_r": Vector3(-78, 0, 0), "foot_r": Vector3(22, 0, 0),
		"leg_l": Vector3(-28, 0, -4), "knee_l": Vector3(-46, 0, 0), "foot_l": Vector3(30, 0, 0),
		"shoulder_r": Vector3(-34, 0, 26), "elbow_r": Vector3(30, 0, 0), "shoulder_l": Vector3(56, 0, -22), "elbow_l": Vector3(40, 0, 0),
	})
	var gather := with(stride, {"leg_l": Vector3(20, 0, -4), "knee_l": Vector3(-60, 0, 0), "leg_r": Vector3(44, 0, 4), "knee_r": Vector3(-56, 0, 0),
		"shoulder_r": Vector3(20, 0, 40), "shoulder_l": Vector3(20, 0, -40)})
	clip("jump", 0.34, [[0.0, push], [0.1, stride], [0.34, gather]], STAND)
	# Falling (link_normal_fall_wait): arms up and out, wheeling slowly for
	# balance, the legs pedalling.
	var fall_a := with(STAND, {
		"hips@pos": Vector3(0, 0.92, 0), "torso": Vector3(4, 0, 2), "head": Vector3(-6, 0, 0),
		"leg_r": Vector3(30, 0, 6), "knee_r": Vector3(-50, 0, 0), "foot_r": Vector3(28, 0, 0),
		"leg_l": Vector3(4, 0, -6), "knee_l": Vector3(-24, 0, 0), "foot_l": Vector3(24, 0, 0),
		"shoulder_r": Vector3(40, 0, 70), "elbow_r": Vector3(36, 0, 0), "shoulder_l": Vector3(14, 0, -62), "elbow_l": Vector3(24, 0, 0),
	})
	var fall_b := with(fall_a, {
		"torso": Vector3(4, 0, -2), "head": Vector3(-4, 0, 0),
		"leg_r": Vector3(6, 0, 6), "knee_r": Vector3(-26, 0, 0), "leg_l": Vector3(32, 0, -6), "knee_l": Vector3(-52, 0, 0),
		"shoulder_r": Vector3(14, 0, 62), "elbow_r": Vector3(24, 0, 0), "shoulder_l": Vector3(40, 0, -70), "elbow_l": Vector3(36, 0, 0),
	})
	clip("fall", 0.8, [[0.0, fall_a], [0.4, fall_b]], STAND, true)
	# Landing: the knees take it (squash), a little rebound, standing.
	var squat := with(STAND, {
		"hips@pos": Vector3(0, 0.72, 0.02), "torso": Vector3(-22, 0, 0), "head": Vector3(14, 0, 0),
		"leg_r": Vector3(56, 0, 5), "knee_r": Vector3(-100, 0, 0), "foot_r": Vector3(44, 0, 0),
		"leg_l": Vector3(54, 0, -5), "knee_l": Vector3(-98, 0, 0), "foot_l": Vector3(44, 0, 0),
		"shoulder_r": Vector3(-4, 0, 30), "elbow_r": Vector3(30, 0, 0), "shoulder_l": Vector3(-4, 0, -30), "elbow_l": Vector3(30, 0, 0),
	})
	var rebound := with(STAND, {"hips@pos": Vector3(0, 0.935, 0), "torso": Vector3(2, 0, 0), "head": Vector3(-2, 0, 0)})
	clip("land", 0.24, [[0.0, with(fall_a, {"hips@pos": Vector3(0, 0.86, 0)})], [0.05, squat], [0.16, rebound], [0.24, STAND]], STAND)
	# The hard landing (landing_damage): slammed down onto one knee and a
	# fist, a beat stunned, then pushing himself up.
	var slam := with(STAND, {
		"hips@pos": Vector3(0, 0.56, 0.03), "torso": Vector3(-44, 0, 4), "head": Vector3(34, 0, 0),
		"leg_r": Vector3(98, 0, 6), "knee_r": Vector3(-132, 0, 0), "foot_r": Vector3(34, 0, 0),
		"leg_l": Vector3(22, 0, -8), "knee_l": Vector3(-116, 0, 0), "foot_l": Vector3(-18, 0, 0),
		"shoulder_r": Vector3(40, 0, 16), "elbow_r": Vector3(10, 0, 0), "shoulder_l": Vector3(48, 0, -20), "elbow_l": Vector3(6, 0, 0),
	})
	var stunned := with(slam, {"hips@pos": Vector3(0, 0.6, 0.03), "torso": Vector3(-34, 0, 2), "head": Vector3(22, 6, 0)})
	var push_up := with(slam, {"hips@pos": Vector3(0, 0.74, 0.0), "torso": Vector3(-24, 0, 0), "head": Vector3(10, 0, 0),
		"leg_r": Vector3(60, 0, 5), "knee_r": Vector3(-90, 0, 0), "foot_r": Vector3(30, 0, 0)})
	clip("land_hard", 0.9, [[0.0, squat], [0.06, slam], [0.55, stunned], [0.74, push_up], [0.9, STAND]], STAND)

	# The forward roll (OoT: 20 frames at 1.25x, 0.53 s): a dive with the arms
	# reaching for the ground, a tight tuck turned once round the hips, and up
	# out of a crouch.
	var tuck := {
		"torso": Vector3(-46, 0, 0), "head": Vector3(-24, 0, 0),
		"leg_r": Vector3(116, 0, 6), "knee_r": Vector3(-142, 0, 0), "foot_r": Vector3(30, 0, 0),
		"leg_l": Vector3(114, 0, -6), "knee_l": Vector3(-140, 0, 0), "foot_l": Vector3(30, 0, 0),
		"shoulder_r": Vector3(72, 0, 14), "elbow_r": Vector3(84, 0, 0), "hand_r": Vector3(-30, 0, 0),
		"shoulder_l": Vector3(72, 0, -14), "elbow_l": Vector3(84, 0, 0),
	}
	var dive := with(STAND, {
		"hips@pos": Vector3(0, 0.74, -0.04), "torso": Vector3(-48, 0, 0), "head": Vector3(-10, 0, 0),
		"leg_r": Vector3(40, 0, 4), "knee_r": Vector3(-60, 0, 0), "foot_r": Vector3(36, 0, 0),
		"leg_l": Vector3(-10, 0, -4), "knee_l": Vector3(-30, 0, 0), "foot_l": Vector3(40, 0, 0),
		"shoulder_r": Vector3(104, 0, 12), "elbow_r": Vector3(24, 0, 0), "shoulder_l": Vector3(104, 0, -12), "elbow_l": Vector3(24, 0, 0),
	})
	var rise := with(STAND, {
		"hips@pos": Vector3(0, 0.66, 0.02), "torso": Vector3(-30, 0, 0), "head": Vector3(18, 0, 0),
		"leg_r": Vector3(70, 0, 5), "knee_r": Vector3(-112, 0, 0), "foot_r": Vector3(42, 0, 0),
		"leg_l": Vector3(66, 0, -5), "knee_l": Vector3(-108, 0, 0), "foot_l": Vector3(42, 0, 0),
		"shoulder_r": Vector3(30, 0, 22), "elbow_r": Vector3(50, 0, 0), "shoulder_l": Vector3(30, 0, -22), "elbow_l": Vector3(50, 0, 0),
	})
	var spin := func(deg: float, y: float) -> Dictionary:
		return with(with(STAND, tuck), {"hips": Vector3(deg, 0, 0), "hips@pos": Vector3(0, y, 0)})
	clip("roll", 0.53, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.86, 0), "torso": Vector3(-14, 0, 0)})], [0.06, dive],
		[0.12, spin.call(-90, 0.44)], [0.2, spin.call(-180, 0.42)], [0.28, spin.call(-270, 0.42)], [0.36, spin.call(-360, 0.46)],
		[0.44, rise], [0.53, with(STAND, {"hips@pos": Vector3(0, 0.88, 0)})]], STAND)
	# The backflip (Z-targeting, A with the stick back): crouch, the arms
	# swing up overhead as he springs, a tuck turned once backward, and down
	# into a crouch.
	var spring := with(STAND, {"hips@pos": Vector3(0, 0.8, 0.02), "torso": Vector3(-14, 0, 0),
		"leg_r": Vector3(36, 0, 4), "knee_r": Vector3(-64, 0, 0), "foot_r": Vector3(28, 0, 0),
		"leg_l": Vector3(36, 0, -4), "knee_l": Vector3(-64, 0, 0), "foot_l": Vector3(28, 0, 0),
		"shoulder_r": Vector3(-30, 0, 14), "elbow_r": Vector3(20, 0, 0), "shoulder_l": Vector3(-30, 0, -14), "elbow_l": Vector3(20, 0, 0)})
	var arch := with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "hips": Vector3(30, 0, 0), "torso": Vector3(16, 0, 0), "head": Vector3(-24, 0, 0),
		"leg_r": Vector3(-6, 0, 4), "knee_r": Vector3(-30, 0, 0), "foot_r": Vector3(40, 0, 0),
		"leg_l": Vector3(-6, 0, -4), "knee_l": Vector3(-30, 0, 0), "foot_l": Vector3(40, 0, 0),
		"shoulder_r": Vector3(168, 0, 10), "elbow_r": Vector3(16, 0, 0), "shoulder_l": Vector3(168, 0, -10), "elbow_l": Vector3(16, 0, 0)})
	var ftuck := with(with(STAND, tuck), {"torso": Vector3(-26, 0, 0), "leg_r": Vector3(84, 0, 6), "leg_l": Vector3(84, 0, -6),
		"knee_r": Vector3(-112, 0, 0), "knee_l": Vector3(-112, 0, 0)})
	clip("backflip", 0.48, [[0.0, spring], [0.06, arch], [0.14, with(ftuck, {"hips": Vector3(120, 0, 0), "hips@pos": Vector3(0, 0.72, 0)})],
		[0.22, with(ftuck, {"hips": Vector3(210, 0, 0), "hips@pos": Vector3(0, 0.7, 0)})], [0.3, with(ftuck, {"hips": Vector3(300, 0, 0), "hips@pos": Vector3(0, 0.7, 0)})],
		[0.38, with(rise, {"hips": Vector3(360, 0, 0), "hips@pos": Vector3(0, 0.72, 0)})], [0.48, with(STAND, {"hips@pos": Vector3(0, 0.9, 0)})]], STAND)
	# Side hops: a skip sideways, legs tucked under, the body leaning into it
	# and the arms out for balance, and a soft landing.
	for variant in [["sidehop_r", 1.0], ["sidehop_l", -1.0]]:
		var d: float = variant[1]
		var crouch := with(STAND, {"hips@pos": Vector3(0, 0.84, 0), "torso": Vector3(-8, 0, 4 * d),
			"leg_r": Vector3(20, 0, 4), "knee_r": Vector3(-36, 0, 0), "foot_r": Vector3(16, 0, 0),
			"leg_l": Vector3(20, 0, -4), "knee_l": Vector3(-36, 0, 0), "foot_l": Vector3(16, 0, 0)})
		var air := with(STAND, {"hips@pos": Vector3(0, 0.92, 0), "hips": Vector3(0, 0, 14 * d), "torso": Vector3(-6, 0, -12 * d), "head": Vector3(0, 0, 6 * d),
			"leg_r": Vector3(36, 0, 12 * d + 4), "knee_r": Vector3(-72, 0, 0), "foot_r": Vector3(30, 0, 0),
			"leg_l": Vector3(36, 0, 12 * d - 4), "knee_l": Vector3(-72, 0, 0), "foot_l": Vector3(30, 0, 0),
			"shoulder_r": Vector3(24, 0, 52), "elbow_r": Vector3(40, 0, 0), "shoulder_l": Vector3(24, 0, -52), "elbow_l": Vector3(40, 0, 0)})
		var touch := with(crouch, {"hips@pos": Vector3(0, 0.82, 0), "hips": Vector3(0, 0, 4 * d), "torso": Vector3(-10, 0, -4 * d),
			"shoulder_r": Vector3(16, 0, 34), "shoulder_l": Vector3(16, 0, -34)})
		clip(variant[0], 0.32, [[0.0, crouch], [0.07, air], [0.26, with(air, {"hips@pos": Vector3(0, 0.9, 0)})], [0.32, touch]], STAND)

	# Flying on the Hookshot's chain (link_hook_fly_start / _wait): drawn out
	# along the chain behind the launcher, the free arm and the legs trailing.
	var fly := with(STAND, {"torso": Vector3(-14, 10, 0), "head": Vector3(-8, -8, 0),
		"leg_r": Vector3(-16, 0, 5), "knee_r": Vector3(-34, 0, 0), "foot_r": Vector3(44, 0, 0),
		"leg_l": Vector3(-4, 0, -5), "knee_l": Vector3(-18, 0, 0), "foot_l": Vector3(40, 0, 0),
		"shoulder_l": Vector3(-34, 0, -24), "elbow_l": Vector3(24, 0, 0)})
	fly.merge(arm_point(1.0, fly, Vector3(0.12, 1.55, -0.62), Vector3(0, 0.12, -1), Vector3(0, -1, 0)), true)
	var fly_b := with(fly, {"leg_r": Vector3(-6, 0, 5), "knee_r": Vector3(-22, 0, 0), "leg_l": Vector3(-14, 0, -5), "knee_l": Vector3(-32, 0, 0),
		"shoulder_l": Vector3(-30, 0, -28)})
	clip("hook_fly", 0.6, [[0.0, fly], [0.3, fly_b]], STAND, true)


func _gait(n: String, L: float, run: bool, sword := false) -> void:
	var hip: Array = [32, 18, -4, -30, -38, -4, 46, 42] if run else [24, 14, 2, -14, -22, -8, 14, 24]
	var knee: Array = [-14, -40, -24, -16, -44, -112, -88, -30] if run else [-4, -14, -6, -8, -28, -58, -30, -6]
	var foot: Array = [-10, 8, 12, 30, 40, 22, 0, -12] if run else [-16, 2, 4, 14, 28, 12, -4, -16]
	var hy: Array = [0.88, 0.85, 0.872, 0.915, 0.885, 0.852, 0.872, 0.915] if run else [0.895, 0.905, 0.92, 0.905, 0.893, 0.905, 0.92, 0.905]
	var keys: Array = []
	for i in 8:
		var ph := i / 8.0
		var o := (i + 4) % 8
		var c := cos(ph * TAU)
		var ac := cos(ph * TAU - 0.35)
		var pose := {
			"hips@pos": Vector3(0.012 * sin(ph * TAU) * (0.5 if run else 1.0), hy[i], 0),
			"hips": Vector3(0, (8.0 if run else 6.0) * c, (2.0 if run else 3.0) * sin(ph * TAU)),
			# The shoulders turn against the hips; the head holds the line.
			"torso": Vector3(-12.0 if run else -3.0, (-17.0 if run else -9.0) * c, 0),
			"head": Vector3(9.0 if run else 2.0, (9.0 if run else 3.0) * c, 0),
			"leg_r": Vector3(hip[i], 0, 3), "knee_r": Vector3(knee[i], 0, 0), "foot_r": Vector3(foot[i], 0, 0),
			"leg_l": Vector3(hip[o], 0, -3), "knee_l": Vector3(knee[o], 0, 0), "foot_l": Vector3(foot[o], 0, 0),
		}
		if sword:
			# The blade held low and level at his side, swinging a little.
			pose["shoulder_r"] = Vector3(14 - 14 * ac, 0, 14)
			pose["elbow_r"] = Vector3(30 + 6 * ac, 0, 0)
			pose["hand_r"] = Vector3(-36, 0, 0)
			pose["shoulder_l"] = Vector3(8 + 40 * ac, 0, -12)
			pose["elbow_l"] = Vector3(84 - 16 * ac, 0, 0)
		elif run:
			pose["shoulder_r"] = Vector3(4 - 48 * ac, 0, 12)
			pose["elbow_r"] = Vector3(86 + 18 * ac, 0, 0)
			pose["hand_r"] = Vector3(-20, 0, 0)
			pose["shoulder_l"] = Vector3(4 + 48 * ac, 0, -12)
			pose["elbow_l"] = Vector3(86 - 18 * ac, 0, 0)
		else:
			pose["shoulder_r"] = Vector3(2 - 24 * ac, 0, 9)
			pose["elbow_r"] = Vector3(24 - 10 * ac, 0, 0)
			pose["hand_r"] = Vector3(-20, 0, 0)
			pose["shoulder_l"] = Vector3(2 + 24 * ac, 0, -9)
			pose["elbow_l"] = Vector3(24 + 10 * ac, 0, 0)
		keys.append([ph * L, pose])
	clip(n, L, keys, STAND, true)


# --- Standing: breathing, the fidgets, the battle stance -------------------------

## OoT gives Link a fidget every other idle cycle (Player_ChooseNextIdleAnim,
## sFidgetAnimations), chosen by the room and his state: he looks around
## (link_normal_wait_typeA), shivers in the cold and sneezes (typeC), wipes the
## sweat off his brow in the heat (typeB), stretches (wait_typeD), doubles
## over panting at critical health (wait_heat1 / heat2), or one of the common
## four: a practice swing (wait_itemD1), tugging his tunic straight
## (wait_itemA), tapping the dirt off his boots (wait_itemB) or setting his
## shield on his arm (wait_itemC). PlayerController picks them the same way.
func _idle_anims() -> void:
	var hip_l := [-1.0, Vector3(-0.25, 0.99, 0.02), Vector3(-1, 0, 0.8), Vector3(0, 0, -1)]
	var hip_r := [1.0, Vector3(0.25, 0.99, 0.02), Vector3(1, 0, 0.8), Vector3(0, 0, -1)]

	# Standing: breathing, the weight drifting from foot to foot.
	var breathe_in := with(STAND, {"hips@pos": Vector3(0.01, 0.915, 0), "hips": Vector3(0, 2, 1.5), "torso": Vector3(-1, -1.5, -1.5),
		"head": Vector3(2, 3, 0), "shoulder_r": Vector3(13, 0, 9), "shoulder_l": Vector3(8, 0, -11), "elbow_r": Vector3(40, 0, 0),
		"leg_r": Vector3(-1, 0, 1.5), "leg_l": Vector3(1, 0, -4.5), "knee_l": Vector3(-7, 0, 0), "foot_l": Vector3(5, 0, 0)})
	var mid := with(STAND, {"hips@pos": Vector3(0, 0.906, 0), "torso": Vector3(-3, 0, 0), "head": Vector3(3, 0, 0),
		"knee_r": Vector3(-5, 0, 0), "knee_l": Vector3(-5, 0, 0), "foot_r": Vector3(4, 0, 0), "foot_l": Vector3(4, 0, 0)})
	var breathe_out := with(STAND, {"hips@pos": Vector3(-0.01, 0.912, 0), "hips": Vector3(0, -2, -1.5), "torso": Vector3(-2, 1.5, 1.5),
		"head": Vector3(2, -4, 0), "shoulder_r": Vector3(12, 0, 9), "shoulder_l": Vector3(7, 0, -11),
		"leg_r": Vector3(1, 0, 4.5), "leg_l": Vector3(-1, 0, -1.5), "knee_r": Vector3(-7, 0, 0), "foot_r": Vector3(5, 0, 0)})
	clip("idle", 2.4, [[0.0, STAND], [0.6, breathe_in], [1.2, mid], [1.8, breathe_out]], STAND, true)

	# Looking around (typeA): a long look left, then right, chin a little up.
	var look_l := with(STAND, {"hips@pos": Vector3(-0.01, 0.915, 0), "hips": Vector3(0, 5, 1), "torso": Vector3(0, 12, 0), "head": Vector3(-6, 46, 3),
		"shoulder_l": Vector3(4, 0, -12)})
	var look_r := with(STAND, {"hips@pos": Vector3(0.01, 0.915, 0), "hips": Vector3(0, -5, -1), "torso": Vector3(0, -12, 0), "head": Vector3(-6, -48, -3),
		"shoulder_r": Vector3(12, 0, 11)})
	clip("idle_look", 3.4, [[0.0, STAND], [0.5, look_l], [1.2, with(look_l, {"head": Vector3(-8, 54, 0)})],
		[1.8, look_r], [2.5, with(look_r, {"head": Vector3(-8, -56, 0)})], [3.0, with(STAND, {"head": Vector3(3, 0, 0)})], [3.4, STAND]], STAND)

	# The cold (typeC): arms wrapped round himself, shivering, then a sneeze.
	var hunch := with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "torso": Vector3(-8, 0, 0), "head": Vector3(10, 0, 0),
		"leg_r": Vector3(4, 0, -1), "leg_l": Vector3(4, 0, 1), "knee_r": Vector3(-8, 0, 0), "knee_l": Vector3(-8, 0, 0), "foot_r": Vector3(4, 0, 0), "foot_l": Vector3(4, 0, 0)})
	var hug := func(body: Dictionary, jig: float) -> Dictionary:
		return reach(body, [[1.0, Vector3(-0.17, 1.27 + jig, -0.11), Vector3(0.3, -1, -0.6), Vector3(0, 1, 0)],
			[-1.0, Vector3(0.17, 1.24 - jig, -0.12), Vector3(-0.3, -1, -0.6), Vector3(0, 1, 0)]])
	var cold_keys: Array = [[0.0, STAND], [0.35, hug.call(hunch, 0.0)]]
	var t := 0.4
	var flip := 1.0
	while t < 1.35:
		cold_keys.append([t, hug.call(with(hunch, {"torso": Vector3(-8, 0, 2.5 * flip), "head": Vector3(10, 0, -2 * flip)}), 0.008 * flip)])
		t += 0.06
		flip = -flip
	cold_keys.append([1.5, hug.call(with(hunch, {"torso": Vector3(4, 0, 0), "head": Vector3(-16, 0, 0), "hips@pos": Vector3(0, 0.91, 0.01)}), 0.0)])
	cold_keys.append([1.62, hug.call(with(hunch, {"torso": Vector3(-26, 0, 0), "head": Vector3(30, 0, 0), "hips@pos": Vector3(0, 0.88, -0.02)}), 0.0)])
	cold_keys.append([1.95, hug.call(with(hunch, {"torso": Vector3(-10, 0, 0), "head": Vector3(8, 6, 0)}), 0.0)])
	cold_keys.append([2.4, with(STAND, {"torso": Vector3(-4, 0, 0), "head": Vector3(6, 0, 0)})])
	cold_keys.append([2.9, STAND])
	clip("idle_cold", 2.9, cold_keys, STAND)

	# The heat (typeB): the back of the wrist across the brow, the sweat
	# flicked off, a sagging sigh; the other fist on his hip.
	var brow_r := reach(with(STAND, {"head": Vector3(-4, -10, -4)}), [[1.0, Vector3(0.14, 1.66, -0.17), Vector3(1, -0.3, 0.2), Vector3(0, 0, 1)], hip_l])
	var brow_l := reach(with(STAND, {"head": Vector3(-2, 8, 2)}), [[1.0, Vector3(-0.09, 1.69, -0.16), Vector3(1, -0.1, 0.1), Vector3(0, 0, 1)], hip_l])
	var flick := reach(with(STAND, {"torso": Vector3(-2, -8, 0), "head": Vector3(4, -6, 0)}), [[1.0, Vector3(0.34, 1.24, -0.22), Vector3(1, -0.6, 0.3), Vector3(0, 0, -1)], hip_l])
	var flick_b := reach(with(STAND, {"torso": Vector3(-2, -8, 0), "head": Vector3(4, -6, 0)}), [[1.0, Vector3(0.36, 1.31, -0.18), Vector3(1, -0.6, 0.3), Vector3(0, 0, -1)], hip_l])
	var sag := reach(with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "torso": Vector3(-8, 0, 0), "head": Vector3(12, 0, 0)}), [hip_l])
	clip("idle_hot", 2.7, [[0.0, STAND], [0.35, brow_r], [0.75, brow_l], [0.95, flick], [1.08, flick_b], [1.2, flick], [1.7, sag], [2.7, STAND]], STAND)

	# Stretching (typeD): up on his toes with the fists locked overhead,
	# leaning one way and the other, then the arms swept down.
	var reach_up := with(STAND, {"hips@pos": Vector3(0, 0.945, 0), "torso": Vector3(8, 0, 0), "head": Vector3(-16, 0, 0),
		"foot_r": Vector3(16, 0, 0), "foot_l": Vector3(16, 0, 0)})
	var overhead := func(body: Dictionary) -> Dictionary:
		return reach(body, [[1.0, Vector3(0.04, 2.04, -0.02), Vector3(1, 0, 0.3), Vector3(0, 0, -1)], [-1.0, Vector3(-0.04, 2.04, -0.02), Vector3(-1, 0, 0.3), Vector3(0, 0, -1)]])
	var spread := reach(with(STAND, {"torso": Vector3(4, 0, 0), "head": Vector3(-4, 0, 0)}),
		[[1.0, Vector3(0.62, 1.42, -0.02), Vector3(0, -1, 0.5), Vector3(0, 0, -1)], [-1.0, Vector3(-0.62, 1.42, -0.02), Vector3(0, -1, 0.5), Vector3(0, 0, -1)]])
	clip("idle_stretch", 3.0, [[0.0, STAND], [0.55, overhead.call(reach_up)], [1.15, overhead.call(with(reach_up, {"torso": Vector3(7, 0, 9)}))],
		[1.65, overhead.call(with(reach_up, {"torso": Vector3(7, 0, -9)}))], [2.1, spread], [2.55, with(STAND, {"torso": Vector3(-3, 0, 0)})], [3.0, STAND]], STAND)

	# Critical health (wait_heat1, then heat2 over and over): bent over, hands
	# on his knees, heaving for breath.
	var bent := with(STAND, {"hips@pos": Vector3(0, 0.84, 0.05), "torso": Vector3(-40, 0, 0), "head": Vector3(-28, 0, 0),
		"leg_r": Vector3(24, 0, 6), "knee_r": Vector3(-46, 0, 0), "foot_r": Vector3(22, 0, 0),
		"leg_l": Vector3(24, 0, -6), "knee_l": Vector3(-46, 0, 0), "foot_l": Vector3(22, 0, 0)})
	var on_knees := func(body: Dictionary) -> Dictionary:
		return reach(body, [[1.0, Vector3(0.15, 0.62, -0.14), Vector3(1, 0.2, 0.5), Vector3(0, 0, -1)], [-1.0, Vector3(-0.15, 0.62, -0.14), Vector3(-1, 0.2, 0.5), Vector3(0, 0, -1)]])
	var heave := with(bent, {"hips@pos": Vector3(0, 0.855, 0.05), "torso": Vector3(-33, 0, 0), "head": Vector3(-24, 0, 0)})
	clip("idle_crit_start", 0.8, [[0.0, STAND], [0.45, on_knees.call(heave)], [0.8, on_knees.call(bent)]], STAND)
	clip("idle_crit", 1.6, [[0.0, on_knees.call(bent)], [0.45, on_knees.call(heave)], [0.8, on_knees.call(bent)], [1.25, on_knees.call(heave)]], STAND, true)

	# Tugging his tunic straight (itemA): both fists at the hem, two pulls, a
	# roll of the shoulders and a hand smoothing it down the chest.
	var look_down := with(STAND, {"torso": Vector3(-10, 0, 0), "head": Vector3(16, 0, 0)})
	var hem := func(y: float, body: Dictionary) -> Dictionary:
		return reach(body, [[1.0, Vector3(0.17, y, -0.13), Vector3(1, 0, 0.6), Vector3(0, 0, -1)], [-1.0, Vector3(-0.17, y, -0.13), Vector3(-1, 0, 0.6), Vector3(0, 0, -1)]])
	var smooth_top := reach(with(STAND, {"head": Vector3(12, 0, 0)}), [[1.0, Vector3(0.04, 1.36, -0.18), Vector3(1, -1, 0.3), Vector3(0, 1, 0)]])
	var smooth_low := reach(with(STAND, {"head": Vector3(14, 0, 0)}), [[1.0, Vector3(0.05, 1.16, -0.19), Vector3(1, -1, 0.3), Vector3(0, 1, 0)]])
	clip("idle_tunic", 3.2, [[0.0, STAND], [0.4, hem.call(0.87, look_down)], [0.75, hem.call(0.78, with(look_down, {"torso": Vector3(-14, 0, 0)}))],
		[1.05, hem.call(0.86, look_down)], [1.35, hem.call(0.78, with(look_down, {"torso": Vector3(-14, 0, 0)}))],
		[1.75, with(STAND, {"torso": Vector3(4, 0, 0), "head": Vector3(-4, 0, 0)})], [2.15, smooth_top], [2.55, smooth_low], [3.2, STAND]], STAND)

	# Tapping the dirt off his boots (itemB): weight onto one foot, the other
	# toe knocked on the ground behind him twice, then the other foot.
	var on_l := with(STAND, {"hips@pos": Vector3(-0.03, 0.915, 0), "hips": Vector3(0, 0, -3), "head": Vector3(10, -12, 0)})
	var on_r := with(STAND, {"hips@pos": Vector3(0.03, 0.915, 0), "hips": Vector3(0, 0, 3), "head": Vector3(10, 12, 0)})
	var tap_r := with(on_l, {"leg_r": Vector3(-18, 0, 4), "knee_r": Vector3(-24, 0, 0), "foot_r": Vector3(52, 0, 0)})
	var lift_r := with(on_l, {"leg_r": Vector3(-10, 0, 4), "knee_r": Vector3(-48, 0, 0), "foot_r": Vector3(40, 0, 0)})
	var tap_l := with(on_r, {"leg_l": Vector3(-18, 0, -4), "knee_l": Vector3(-24, 0, 0), "foot_l": Vector3(52, 0, 0)})
	var lift_l := with(on_r, {"leg_l": Vector3(-10, 0, -4), "knee_l": Vector3(-48, 0, 0), "foot_l": Vector3(40, 0, 0)})
	clip("idle_feet", 2.7, [[0.0, STAND], [0.3, on_l], [0.5, lift_r], [0.62, tap_r], [0.78, lift_r], [0.9, tap_r], [1.15, STAND],
		[1.45, on_r], [1.65, lift_l], [1.77, tap_l], [1.93, lift_l], [2.05, tap_l], [2.35, STAND], [2.7, STAND]], STAND)

	# Setting his shield (itemC): the shield arm brought up to look at, the
	# strap tugged twice, the arm lowered and shaken out.
	var shield_up := with(STAND, {"torso": Vector3(0, 12, 0), "head": Vector3(16, 22, 0),
		"shoulder_l": Vector3(56, -24, -12), "elbow_l": Vector3(96, 0, 0), "shield": Vector3(0, 18, 0)})
	var strap := func(body: Dictionary, dx: float) -> Dictionary:
		return reach(body, [[1.0, Vector3(-0.1 + dx, 1.27, -0.3), Vector3(1, -0.6, 0.2), Vector3(0, 1, 0)]])
	clip("idle_shield", 3.2, [[0.0, STAND], [0.5, shield_up], [0.8, strap.call(shield_up, 0.0)],
		[1.0, strap.call(with(shield_up, {"shield": Vector3(0, 26, 6)}), 0.06)], [1.2, strap.call(shield_up, 0.0)],
		[1.4, strap.call(with(shield_up, {"shield": Vector3(0, 26, -6)}), 0.06)], [1.8, with(shield_up, {"elbow_l": Vector3(104, 0, 0)})],
		[2.4, with(STAND, {"elbow_l": Vector3(34, 0, 0)})], [2.7, with(STAND, {"elbow_l": Vector3(14, 0, 0)})], [3.2, STAND]], STAND)

	# A practice swing (itemD1, sword in hand): the blade twirled round the
	# wrist, then a cut down with a step, and back.
	var twirl := with(STAND, {"shoulder_r": Vector3(62, 0, 22), "elbow_r": Vector3(56, 0, 0), "torso": Vector3(0, -8, 0), "head": Vector3(6, -10, 0)})
	var cut_up := with(STAND, {"torso": Vector3(6, -14, 0), "head": Vector3(-4, 10, 0), "shoulder_r": Vector3(165, -10, 18),
		"elbow_r": Vector3(80, 0, 0), "hand_r": Vector3(-30, 0, 0), "shoulder_l": Vector3(40, 10, -26), "elbow_l": Vector3(70, 0, 0)})
	var cut_down := with(STAND, {"hips@pos": Vector3(0, 0.84, -0.07), "torso": Vector3(-20, 12, 0), "head": Vector3(14, -8, 0),
		"shoulder_r": Vector3(58, 12, 4), "elbow_r": Vector3(8, 0, 0), "hand_r": Vector3(-74, 0, 0),
		"shoulder_l": Vector3(36, 18, -22), "elbow_l": Vector3(78, 0, 0),
		"leg_l": Vector3(32, 0, -4), "knee_l": Vector3(-42, 0, 0), "foot_l": Vector3(10, 0, 0),
		"leg_r": Vector3(-20, 0, 5), "knee_r": Vector3(-16, 0, 0), "foot_r": Vector3(32, 0, 0)})
	clip("idle_sword", 2.0, [[0.0, STAND], [0.25, with(twirl, {"hand_r": Vector3(-20, 0, 0)})], [0.37, with(twirl, {"hand_r": Vector3(-20, 120, 0)})],
		[0.49, with(twirl, {"hand_r": Vector3(-20, 240, 0)})], [0.61, with(twirl, {"hand_r": Vector3(-20, 360, 0)})],
		[0.85, cut_up], [1.0, cut_down], [1.3, with(cut_down, {"shoulder_r": Vector3(52, 14, 4), "hand_r": Vector3(-66, 0, 0)})], [2.0, STAND]], STAND)

	# The battle stance while locked on to a foe (OoT's Z-target wait,
	# link_anchor / fighter wait): knees bent, the left foot forward, the
	# shield up before the chest and the blade's point toward the foe,
	# bobbing a little on the balls of his feet.
	var guard := with(STAND, {"hips@pos": Vector3(0, 0.86, 0.02), "torso": Vector3(-8, -14, 0), "head": Vector3(4, 14, 0),
		"leg_l": Vector3(24, 0, -6), "knee_l": Vector3(-36, 0, 0), "foot_l": Vector3(12, 0, 0),
		"leg_r": Vector3(-10, 0, 8), "knee_r": Vector3(-24, 0, 0), "foot_r": Vector3(32, 0, 0),
		"shoulder_l": Vector3(42, -18, -12), "elbow_l": Vector3(92, 0, 0), "shield": Vector3(0, 36, 0),
		"shoulder_r": Vector3(34, 0, 14), "elbow_r": Vector3(42, 0, 0), "hand_r": Vector3(-38, 0, 0)})
	var bob := with(guard, {"hips@pos": Vector3(0, 0.845, 0.02), "torso": Vector3(-10, -14, 0), "shoulder_r": Vector3(37, 0, 14),
		"knee_l": Vector3(-40, 0, 0), "foot_l": Vector3(14, 0, 0), "knee_r": Vector3(-28, 0, 0), "foot_r": Vector3(34, 0, 0)})
	clip("idle_battle", 1.2, [[0.0, guard], [0.6, bob]], STAND, true)


# --- Fighting: the parry and riposte, taking hits, falling, the sword put away ----

func _combat_anims() -> void:
	var ready := with(STAND, {"hips@pos": Vector3(0, 0.88, 0), "torso": Vector3(-6, -8, 0), "head": Vector3(2, 8, 0),
		"leg_l": Vector3(16, 0, -5), "knee_l": Vector3(-22, 0, 0), "foot_l": Vector3(6, 0, 0),
		"leg_r": Vector3(-8, 0, 6), "knee_r": Vector3(-14, 0, 0), "foot_r": Vector3(22, 0, 0)})

	# The Parry (Dark Souls' parry, a flick of the shield): the shield arm
	# snaps out and across to knock the blow wide, the body turning with it,
	# and the sword drawn back ready to answer.
	var flick := with(ready, {"torso": Vector3(-8, 26, 0), "head": Vector3(0, -18, 0),
		"shoulder_l": Vector3(62, -70, -30), "elbow_l": Vector3(46, 0, 0), "shield": Vector3(0, 70, 20),
		"shoulder_r": Vector3(10, 30, 30), "elbow_r": Vector3(70, 0, 0), "hand_r": Vector3(-60, 90, 0)})
	var open := with(flick, {"torso": Vector3(-6, 32, 0), "shoulder_l": Vector3(40, -84, -50), "elbow_l": Vector3(30, 0, 0), "shield": Vector3(0, 60, 30)})
	clip("parry", 0.5, [[0.0, ready], [0.05, flick], [0.16, open], [0.5, with(ready, {"shoulder_r": Vector3(14, 20, 24), "elbow_r": Vector3(60, 0, 0),
		"hand_r": Vector3(-60, 90, 0)})]], STAND)

	# The riposte (Dark Souls' riposte): a step in, the blade driven through
	# the reeling foe and held there, a twist, then the foe shoved off the
	# blade with the shield and the sword whipped clear.
	var draw := with(ready, {"hips@pos": Vector3(0, 0.86, 0.06), "torso": Vector3(-4, -30, 0), "head": Vector3(0, 26, 0),
		"shoulder_r": Vector3(8, -16, 24), "elbow_r": Vector3(108, 0, 0), "hand_r": Vector3(-88, 90, 0),
		"shoulder_l": Vector3(52, 20, -20), "elbow_l": Vector3(84, 0, 0)})
	var drive := with(ready, {"hips@pos": Vector3(0, 0.74, -0.26), "torso": Vector3(-18, 26, 0), "head": Vector3(6, -20, 0),
		"leg_l": Vector3(62, 0, -5), "knee_l": Vector3(-82, 0, 0), "foot_l": Vector3(20, 0, 0),
		"leg_r": Vector3(-38, 0, 6), "knee_r": Vector3(-10, 0, 0), "foot_r": Vector3(50, 0, 0),
		"shoulder_r": Vector3(88, 14, 2), "elbow_r": Vector3(0, 0, 0), "hand_r": Vector3(-90, 90, 0),
		"shoulder_l": Vector3(40, -30, -30), "elbow_l": Vector3(70, 0, 0)})
	var twist := with(drive, {"hips@pos": Vector3(0, 0.73, -0.28), "torso": Vector3(-20, 32, 0), "hand_r": Vector3(-90, 125, 0), "shoulder_r": Vector3(86, 18, 2)})
	var shove := with(ready, {"hips@pos": Vector3(0, 0.8, -0.1), "torso": Vector3(-14, -6, 0), "head": Vector3(6, 4, 0),
		"leg_l": Vector3(34, 0, -5), "knee_l": Vector3(-50, 0, 0), "leg_r": Vector3(-24, 0, 6), "knee_r": Vector3(-18, 0, 0),
		"shoulder_l": Vector3(84, 6, -8), "elbow_l": Vector3(24, 0, 0), "shield": Vector3(0, 62, 0),
		"shoulder_r": Vector3(30, -40, 40), "elbow_r": Vector3(40, 0, 0), "hand_r": Vector3(-50, 90, 0)})
	var clear := with(ready, {"torso": Vector3(-6, -24, 0), "shoulder_r": Vector3(50, -70, 30), "elbow_r": Vector3(20, 0, 0), "hand_r": Vector3(-60, 90, 0)})
	clip("riposte", 1.2, [[0.0, ready], [0.14, draw], [0.26, drive], [0.62, with(drive, {"hips@pos": Vector3(0, 0.75, -0.27)})], [0.72, twist],
		[0.86, shove], [0.98, clear], [1.2, ready]], STAND)

	# Hit from the front (link_normal_damage_run...): knocked back, the head
	# thrown back and the arms flung; hit from behind: pitched forward.
	clip("hurt", 0.4, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.88, 0.06), "torso": Vector3(26, 0, 6), "head": Vector3(-22, 0, 0),
		"shoulder_r": Vector3(30, 0, 56), "elbow_r": Vector3(24, 0, 0), "shoulder_l": Vector3(30, 0, -56), "elbow_l": Vector3(24, 0, 0),
		"leg_r": Vector3(-14, 0, 3), "leg_l": Vector3(22, 0, -3), "knee_l": Vector3(-26, 0, 0), "foot_l": Vector3(10, 0, 0)})],
		[0.12, with(STAND, {"hips@pos": Vector3(0, 0.84, 0.04), "torso": Vector3(14, 0, 2), "head": Vector3(-6, 0, 0),
		"shoulder_r": Vector3(16, 0, 36), "shoulder_l": Vector3(16, 0, -36), "knee_r": Vector3(-16, 0, 0), "knee_l": Vector3(-22, 0, 0)})],
		[0.4, STAND]], STAND)
	clip("hurt_back", 0.4, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.88, -0.06), "torso": Vector3(-30, 0, -4), "head": Vector3(-14, 0, 0),
		"shoulder_r": Vector3(-36, 0, 30), "elbow_r": Vector3(20, 0, 0), "shoulder_l": Vector3(-36, 0, -30), "elbow_l": Vector3(20, 0, 0),
		"leg_r": Vector3(26, 0, 3), "knee_r": Vector3(-30, 0, 0), "foot_r": Vector3(14, 0, 0), "leg_l": Vector3(-12, 0, -3)})],
		[0.14, with(STAND, {"hips@pos": Vector3(0, 0.85, -0.03), "torso": Vector3(-14, 0, 0), "head": Vector3(6, 0, 0),
		"shoulder_r": Vector3(-10, 0, 20), "shoulder_l": Vector3(-10, 0, -20), "knee_r": Vector3(-20, 0, 0)})], [0.4, STAND]], STAND)

	# Falling in battle: the blow rocks him, his knees give, he sags on them
	# and pitches forward onto his face (OoT's Link goes down the same way
	# before the GAME OVER).
	var reel := with(STAND, {"hips@pos": Vector3(0, 0.88, 0.04), "torso": Vector3(18, 0, 6), "head": Vector3(-20, 10, 0),
		"shoulder_r": Vector3(20, 0, 40), "shoulder_l": Vector3(20, 0, -40), "knee_r": Vector3(-10, 0, 0)})
	var knees := with(STAND, {"hips@pos": Vector3(0, 0.52, 0.06), "torso": Vector3(-14, 0, 0), "head": Vector3(26, 0, 0),
		"leg_r": Vector3(16, 0, 8), "knee_r": Vector3(-102, 0, 0), "foot_r": Vector3(46, 0, 0),
		"leg_l": Vector3(14, 0, -8), "knee_l": Vector3(-100, 0, 0), "foot_l": Vector3(46, 0, 0),
		"shoulder_r": Vector3(-6, 0, 12), "elbow_r": Vector3(10, 0, 0), "shoulder_l": Vector3(-6, 0, -12), "elbow_l": Vector3(10, 0, 0)})
	var sag := with(knees, {"hips@pos": Vector3(0, 0.5, 0.08), "torso": Vector3(-30, 0, 4), "head": Vector3(36, 0, 0)})
	var face_down := with(STAND, {"hips@pos": Vector3(0, 0.2, -0.28), "hips": Vector3(-84, 0, 0), "torso": Vector3(-2, 0, 0), "head": Vector3(-18, 30, 0),
		"leg_r": Vector3(-4, 0, 8), "knee_r": Vector3(-14, 0, 0), "foot_r": Vector3(60, 0, 0),
		"leg_l": Vector3(2, 0, -6), "knee_l": Vector3(-6, 0, 0), "foot_l": Vector3(60, 0, 0),
		"shoulder_r": Vector3(-6, 0, 24), "elbow_r": Vector3(10, 0, 0), "hand_r": Vector3(90, 0, 0), "shoulder_l": Vector3(40, 0, -60), "elbow_l": Vector3(20, 0, 0)})
	clip("death", 1.5, [[0.0, STAND], [0.12, reel], [0.42, knees], [0.72, sag], [1.05, with(face_down, {"hips@pos": Vector3(0, 0.26, -0.26)})], [1.18, face_down], [1.5, face_down]], STAND)

	# Putting the sword away with a flourish (Twilight Princess spins the
	# blade before he sheathes it): a twirl round the wrist out to the side,
	# the hilt brought up over the right shoulder (the blade goes into the
	# scabbard at sheathe_time / 2), pushed home, and the hand back down.
	var out := with(STAND, {"torso": Vector3(0, -10, 0), "head": Vector3(0, -8, 0), "shoulder_r": Vector3(40, 0, 50), "elbow_r": Vector3(30, 0, 0)})
	var overhead := with(STAND, {"torso": Vector3(4, -12, 0), "head": Vector3(-4, 10, 0), "shoulder_r": Vector3(158, 0, 12),
		"elbow_r": Vector3(104, 0, 0), "hand_r": Vector3(-30, 0, 0)})
	clip("sheathe", 0.8, [[0.0, STAND], [0.08, with(out, {"hand_r": Vector3(-20, 0, 0)})], [0.16, with(out, {"hand_r": Vector3(-20, 120, 0)})],
		[0.24, with(out, {"hand_r": Vector3(-20, 240, 0)})], [0.32, with(out, {"hand_r": Vector3(-20, 360, 0)})], [0.4, overhead],
		[0.5, with(overhead, {"shoulder_r": Vector3(150, 0, 12), "elbow_r": Vector3(112, 0, 0)})], [0.62, with(STAND, {"shoulder_r": Vector3(60, 0, 20), "elbow_r": Vector3(70, 0, 0)})],
		[0.8, STAND]], STAND)


# --- The items: bottles, nuts, the mallet and spade, rods, the flail, spells --------

func _item_anims() -> void:
	var hip_l := [-1.0, Vector3(-0.25, 0.99, 0.02), Vector3(-1, 0, 0.8), Vector3(0, 0, -1)]
	var lunge := {"hips@pos": Vector3(0, 0.84, -0.06), "leg_l": Vector3(30, 0, -5), "knee_l": Vector3(-42, 0, 0), "foot_l": Vector3(12, 0, 0),
		"leg_r": Vector3(-20, 0, 6), "knee_r": Vector3(-16, 0, 0), "foot_r": Vector3(34, 0, 0)}

	# The bottle swung through the air (link_bottle_bug_in): a scoop from the
	# right across to the left, the mouth leading.
	var b_cock := reach(with(STAND, {"torso": Vector3(-2, -26, 0), "head": Vector3(0, 20, 0)}),
		[[1.0, Vector3(0.44, 1.32, -0.12), Vector3(1, -0.4, 0.4), Vector3(1, 0, 0)]])
	var b_mid := reach(with(with(STAND, lunge), {"torso": Vector3(-12, 0, 0), "head": Vector3(6, 0, 0)}),
		[[1.0, Vector3(0.05, 1.18, -0.64), Vector3(1, -0.6, 0.2), Vector3(1, 0, 0)]])
	var b_end := reach(with(with(STAND, lunge), {"torso": Vector3(-8, 28, 0), "head": Vector3(4, -16, 0)}),
		[[1.0, Vector3(-0.34, 1.24, -0.4), Vector3(0.6, -0.8, 0.4), Vector3(1, 0, 0.6)]])
	clip("bottle_swing", 0.55, [[0.0, STAND], [0.1, b_cock], [0.2, b_mid], [0.3, b_end], [0.55, STAND]], STAND)
	# Drinking (link_bottle_drink_demo): the bottle tipped up at the lips, the
	# head back, a few swallows, a sigh.
	var lips := reach(with(STAND, {"head": Vector3(-8, 0, 0)}), [[1.0, Vector3(0.06, 1.58, -0.2), Vector3(1, -1, 0), Vector3(0, -0.3, -1)], hip_l])
	var tip := reach(with(STAND, {"torso": Vector3(6, 0, 0), "head": Vector3(-30, 0, 0)}), [[1.0, Vector3(0.04, 1.7, -0.15), Vector3(1, -0.8, 0), Vector3(0, -1, -0.5)], hip_l])
	var gulp := reach(with(STAND, {"torso": Vector3(6, 0, 0), "head": Vector3(-26, 0, 0)}), [[1.0, Vector3(0.04, 1.69, -0.15), Vector3(1, -0.8, 0), Vector3(0, -1, -0.5)], hip_l])
	var sigh := reach(with(STAND, {"torso": Vector3(-6, 0, 0), "head": Vector3(10, 0, 0)}), [[1.0, Vector3(0.2, 1.16, -0.26), Vector3(1, -1, 0.3), Vector3(0, 0, -1)], hip_l])
	clip("drink", 1.6, [[0.0, STAND], [0.3, lips], [0.5, tip], [0.7, gulp], [0.85, tip], [1.0, gulp], [1.25, sigh], [1.6, STAND]], STAND)
	# Letting out what a bottle holds: held out at arm's length and tipped.
	var hold_out := reach(with(STAND, {"torso": Vector3(-6, 0, 0)}), [[1.0, Vector3(0.12, 1.3, -0.5), Vector3(1, -1, 0.2), Vector3(0, -1, 0)]])
	var tipped := reach(with(STAND, {"torso": Vector3(-8, 0, 0)}), [[1.0, Vector3(0.12, 1.32, -0.54), Vector3(1, -1, 0.2), Vector3(0, -0.2, 1)]])
	clip("bottle_release", 0.7, [[0.0, STAND], [0.18, hold_out], [0.32, tipped], [0.5, tipped], [0.7, STAND]], STAND)

	# A Puff Nut flung down ahead (OoT's Deku Nut throw): a snap of the arm
	# from beside the ear, let go at 0.12 s.
	var n_cock := reach(with(STAND, {"torso": Vector3(4, -16, 0), "head": Vector3(0, 12, 0)}), [[1.0, Vector3(0.3, 1.64, 0.06), Vector3(1, -0.6, 0.3), Vector3(0, 1, 0)]])
	var n_go := reach(with(with(STAND, lunge), {"torso": Vector3(-16, 8, 0), "head": Vector3(10, -6, 0)}), [[1.0, Vector3(0.12, 1.36, -0.52), Vector3(1, -0.6, 0.2), Vector3(0, 0, 1)]])
	var n_end := reach(with(with(STAND, lunge), {"torso": Vector3(-18, 12, 0)}), [[1.0, Vector3(0.02, 1.04, -0.44), Vector3(1, -0.2, 0.4), Vector3(0, 0, 1)]])
	clip("nut_throw", 0.36, [[0.0, STAND], [0.07, n_cock], [0.12, n_go], [0.2, n_end], [0.36, STAND]], STAND)

	# The Iron Mallet (link_hammer_hit): both fists on the haft, heaved up
	# over the head and behind (raised at 0.2 s), brought down two steps
	# ahead at 0.28 s into a deep lunge, the jolt, and up again.
	var m_up := reach(with(STAND, {"hips@pos": Vector3(0, 0.94, 0.03), "torso": Vector3(14, 0, 0), "head": Vector3(-12, 0, 0),
		"leg_l": Vector3(10, 0, -5), "leg_r": Vector3(-6, 0, 6)}), [[1.0, Vector3(0.08, 1.94, 0.1), Vector3(1, 0, 0.4), Vector3(0, -0.4, -1)]])
	var m_down := reach(with(STAND, {"hips@pos": Vector3(0, 0.7, -0.1), "torso": Vector3(-42, 0, 0), "head": Vector3(26, 0, 0),
		"leg_l": Vector3(58, 0, -6), "knee_l": Vector3(-86, 0, 0), "foot_l": Vector3(26, 0, 0),
		"leg_r": Vector3(-14, 0, 6), "knee_r": Vector3(-52, 0, 0), "foot_r": Vector3(64, 0, 0)}),
		[[1.0, Vector3(0.05, 0.86, -0.56), Vector3(1, -0.2, 0.4), Vector3(0, 0.75, 1)]])
	var m_jolt := reach(with(m_down, {"hips@pos": Vector3(0, 0.72, -0.1), "torso": Vector3(-38, 0, 0)}), [[1.0, Vector3(0.05, 0.9, -0.55), Vector3(1, -0.2, 0.4), Vector3(0, 0.6, 1)]])
	clip("mallet_swing", 0.7, [[0.0, second_hand(STAND, 0.12)], [0.2, second_hand(m_up, 0.12)], [0.28, second_hand(m_down, 0.12)],
		[0.38, second_hand(m_jolt, 0.12)], [0.7, second_hand(reach(STAND, [[1.0, Vector3(0.2, 1.05, -0.3), Vector3(1, -0.4, 0.4), Vector3(0, 0.3, 1)]]), 0.12)]], STAND)
	# The Grave Spade: raised in both fists, driven into the earth a step
	# ahead at 0.3 s, levered back.
	var s_up := reach(with(STAND, {"torso": Vector3(4, 0, 0), "head": Vector3(10, 0, 0)}), [[1.0, Vector3(0.08, 1.42, -0.22), Vector3(1, -0.6, 0.3), Vector3(0, 1, 0.4)]])
	var s_in := reach(with(with(STAND, lunge), {"hips@pos": Vector3(0, 0.8, -0.06), "torso": Vector3(-30, 0, 0), "head": Vector3(22, 0, 0)}),
		[[1.0, Vector3(0.05, 0.98, -0.42), Vector3(1, -0.4, 0.3), Vector3(0, 1, 0.45)]])
	var s_lever := reach(with(with(STAND, lunge), {"hips@pos": Vector3(0, 0.82, -0.03), "torso": Vector3(-18, 0, 0), "head": Vector3(16, 0, 0)}),
		[[1.0, Vector3(0.07, 1.1, -0.3), Vector3(1, -0.4, 0.3), Vector3(0, 0.8, 0.9)]])
	clip("dig", 0.65, [[0.0, second_hand(STAND, 0.16)], [0.16, second_hand(s_up, 0.16)], [0.3, second_hand(s_in, 0.16)], [0.45, second_hand(s_lever, 0.16)], [0.65, STAND]], STAND)

	# The Ember Rod (ALttP's Fire Rod): cocked by the ear, flicked out at
	# the target (the fireball leaves at 0.12 s), back.
	var e_cock := reach(with(STAND, {"torso": Vector3(4, -14, 0), "head": Vector3(0, 10, 0)}), [[1.0, Vector3(0.28, 1.62, 0.02), Vector3(1, -0.8, 0.2), Vector3(0, -1, -0.3), FIST, true]])
	var e_flick := reach(with(with(STAND, lunge), {"torso": Vector3(-12, 8, 0), "head": Vector3(6, -6, 0)}), [[1.0, Vector3(0.12, 1.4, -0.54), Vector3(1, -0.8, 0.2), Vector3(0, -0.15, 1), FIST, true]])
	clip("ember_flick", 0.4, [[0.0, STAND], [0.07, e_cock], [0.12, e_flick], [0.24, with(e_flick, {})], [0.4, STAND]], STAND)
	# The Sapphire Staff: raised high, then thrust at the spot where the
	# block will stand (0.3 s).
	var st_up := reach(with(STAND, {"torso": Vector3(6, 0, 0), "head": Vector3(-14, 0, 0)}), [[1.0, Vector3(0.2, 1.9, -0.12), Vector3(1, -0.4, 0.3), Vector3(0, -1, 0), FIST, true], hip_l])
	var st_point := reach(with(with(STAND, lunge), {"torso": Vector3(-14, 4, 0), "head": Vector3(14, 0, 0)}), [[1.0, Vector3(0.14, 1.42, -0.54), Vector3(1, -0.6, 0.2), Vector3(0, 0.45, 1), FIST, true],
		[-1.0, Vector3(-0.42, 1.36, -0.2), Vector3(-1, -0.4, 0.4), Vector3(0, 0, -1)]])
	clip("staff_cast", 0.6, [[0.0, STAND], [0.16, st_up], [0.3, st_point], [0.45, st_point], [0.6, STAND]], STAND)
	# The Iron Flail (ALttP's Ball and Chain): wound right back, the ball
	# hurled underhand at 0.22 s, the arm held out while it flies, the haul
	# back as it swings home.
	var f_back := reach(with(STAND, {"hips@pos": Vector3(0, 0.86, 0.04), "torso": Vector3(-6, -38, 0), "head": Vector3(0, 30, 0),
		"leg_r": Vector3(-14, 0, 8), "knee_r": Vector3(-24, 0, 0), "leg_l": Vector3(14, 0, -6), "knee_l": Vector3(-20, 0, 0)}),
		[[1.0, Vector3(0.38, 1.0, 0.34), Vector3(1, -0.2, -0.4), Vector3(0, 0, -1)]])
	var f_hurl := reach(with(with(STAND, lunge), {"torso": Vector3(-14, 18, 0), "head": Vector3(6, -14, 0)}), [[1.0, Vector3(0.1, 1.32, -0.58), Vector3(1, -0.8, 0.0), Vector3(0, 0, -1)]])
	var f_pull := reach(with(STAND, {"hips@pos": Vector3(0, 0.86, 0.04), "torso": Vector3(-4, -6, 0), "leg_r": Vector3(-10, 0, 6), "knee_r": Vector3(-18, 0, 0)}),
		[[1.0, Vector3(0.2, 1.18, -0.24), Vector3(1, -0.8, 0.4), Vector3(0, 0, -1)]])
	clip("flail_hurl", 0.9, [[0.0, STAND], [0.14, f_back], [0.22, f_hurl], [0.5, f_hurl], [0.72, f_pull], [0.9, STAND]], STAND)

	# The goddesses' blessings, after OoT's three spells (link_magic_tame,
	# then kaze / honoo / tamashii): the magic goes out at 0.35 s.
	var gather := reach(with(STAND, {"hips@pos": Vector3(0, 0.88, 0), "head": Vector3(14, 0, 0)}),
		[[1.0, Vector3(0.05, 1.34, -0.22), Vector3(1, -1, 0.3), Vector3(0, 1, 0)], [-1.0, Vector3(-0.05, 1.34, -0.22), Vector3(-1, -1, 0.3), Vector3(0, 1, 0)]])
	# Serielye's Ruin (Din's Fire, honoo): the fists raised high, then down
	# with a fist punched into the earth.
	var r_up := reach(with(STAND, {"hips@pos": Vector3(0, 0.94, 0), "torso": Vector3(8, 0, 0), "head": Vector3(-20, 0, 0)}),
		[[1.0, Vector3(0.1, 2.02, -0.06), Vector3(1, 0, 0.3), Vector3(0, 0, -1)], [-1.0, Vector3(-0.1, 2.02, -0.06), Vector3(-1, 0, 0.3), Vector3(0, 0, -1)]])
	var r_punch := reach(with(STAND, {"hips@pos": Vector3(0, 0.56, 0.02), "torso": Vector3(-46, 0, 0), "head": Vector3(30, 0, 0),
		"leg_r": Vector3(96, 0, 8), "knee_r": Vector3(-130, 0, 0), "foot_r": Vector3(34, 0, 0),
		"leg_l": Vector3(30, 0, -10), "knee_l": Vector3(-110, 0, 0), "foot_l": Vector3(-14, 0, 0)}),
		[[1.0, Vector3(0.1, 0.18, -0.36), Vector3(1, 0.4, 0.4), Vector3(0, 0, -1)], [-1.0, Vector3(-0.46, 0.9, 0.1), Vector3(-1, -0.4, 0.2), Vector3(0, 0, -1)]])
	clip("cast_ruin", 0.9, [[0.0, STAND], [0.14, gather], [0.26, r_up], [0.35, r_punch], [0.62, r_punch], [0.9, STAND]], STAND)
	# Aphiel's Gale (Farore's Wind, kaze): the arms thrown up and wide, the
	# head back, then swept down round the sides.
	var g_up := reach(with(STAND, {"hips@pos": Vector3(0, 0.94, 0), "torso": Vector3(10, 0, 0), "head": Vector3(-24, 0, 0)}),
		[[1.0, Vector3(0.5, 1.96, -0.06), Vector3(1, 0, 0.3), Vector3(0, 0, -1)], [-1.0, Vector3(-0.5, 1.96, -0.06), Vector3(-1, 0, 0.3), Vector3(0, 0, -1)]])
	var g_round := reach(with(STAND, {"torso": Vector3(2, 0, 0)}),
		[[1.0, Vector3(0.62, 1.36, 0.02), Vector3(0, -1, 0.5), Vector3(0, 0, -1)], [-1.0, Vector3(-0.62, 1.36, 0.02), Vector3(0, -1, 0.5), Vector3(0, 0, -1)]])
	clip("cast_gale", 0.9, [[0.0, STAND], [0.14, gather], [0.35, g_up], [0.55, g_up], [0.72, g_round], [0.9, STAND]], STAND)
	# Alan's Harvest (Nayru's Love, tamashii): head bowed over hands together
	# in prayer, then the arms opened wide, palms out.
	var pray := reach(with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "head": Vector3(24, 0, 0), "torso": Vector3(-4, 0, 0)}),
		[[1.0, Vector3(0.03, 1.42, -0.22), Vector3(1, -1, 0.3), Vector3(0, 1, 0)], [-1.0, Vector3(-0.03, 1.42, -0.22), Vector3(-1, -1, 0.3), Vector3(0, 1, 0)]])
	var bloom := reach(with(STAND, {"torso": Vector3(6, 0, 0), "head": Vector3(-10, 0, 0)}),
		[[1.0, Vector3(0.56, 1.5, -0.2), Vector3(0, -1, 0.5), Vector3(0, 0, -1)], [-1.0, Vector3(-0.56, 1.5, -0.2), Vector3(0, -1, 0.5), Vector3(0, 0, -1)]])
	clip("cast_harvest", 0.9, [[0.0, STAND], [0.2, pray], [0.3, pray], [0.4, bloom], [0.65, bloom], [0.9, STAND]], STAND)
	# Lothelye's Dream: the hands raised slowly to the sky, the head tipped
	# back as he dreams awake.
	var dream := reach(with(STAND, {"hips@pos": Vector3(0, 0.93, 0), "torso": Vector3(10, 0, 0), "head": Vector3(-28, 0, 0)}),
		[[1.0, Vector3(0.26, 2.0, -0.18), Vector3(1, -0.2, 0.3), Vector3(0, 0, -1)], [-1.0, Vector3(-0.26, 2.0, -0.18), Vector3(-1, -0.2, 0.3), Vector3(0, 0, -1)]])
	clip("cast_dream", 0.9, [[0.0, STAND], [0.18, gather], [0.38, dream], [0.65, with(dream, {"head": Vector3(-24, 0, 0)})], [0.9, STAND]], STAND)


# --- The sword: cuts, finishers, the jump slash, the Great Spin, the bash -----------

## The cuts (after OoT's func_80837818 and its *_kiru animations), with their
## timings kept to PlayerCombat.SWINGS: wound up with the weight on the back
## foot, the hips driving the cut and the head leading it, the arm stretched
## to its fullest just past the middle (an over-reach, like the smear of a
## cartoon swing), carried round past the far side and settled, while the
## shield arm swings the other way to balance him. The blade keeps its edge
## first: through the level cuts the forearm is rolled a quarter turn
## (hand_r Y = 90) and the chops keep it upright.
func _sword_anims() -> void:
	var ready := with(STAND, {"hips@pos": Vector3(0, 0.91, 0), "torso": Vector3(-5, 0, 0)})
	var lunge := {
		"hips@pos": Vector3(0, 0.85, -0.05),
		"leg_l": Vector3(32, 0, -4), "knee_l": Vector3(-42, 0, 0), "foot_l": Vector3(10, 0, 0),
		"leg_r": Vector3(-22, 0, 5), "knee_r": Vector3(-16, 0, 0), "foot_r": Vector3(32, 0, 0),
		"shoulder_l": Vector3(38, 18, -22), "elbow_l": Vector3(78, 0, 0),
	}
	for spec in [["slash_left", -1.0, false], ["slash_right", 1.0, false], ["slash_left_fin", -1.0, true], ["slash_right_fin", 1.0, true]]:
		var n: String = spec[0]
		var d: float = spec[1]
		var fin: bool = spec[2]
		var big := 1.35 if fin else 1.0
		var cock := with(with(ready, lunge), {
			"hips@pos": Vector3(0.02 * d, 0.88, 0.03), "hips": Vector3(0, 12 * d, 0),
			"leg_l": Vector3(12, 0, -4), "knee_l": Vector3(-22, 0, 0), "foot_l": Vector3(4, 0, 0),
			"leg_r": Vector3(-6, 0, 5), "knee_r": Vector3(-24, 0, 0), "foot_r": Vector3(14, 0, 0),
			"torso": Vector3(-2, 28 * d * big, 0), "head": Vector3(0, -30 * d, 0),
			"shoulder_r": (Vector3(62, -82 * big, 14) if d < 0 else Vector3(48, 62, -6)),
			"elbow_r": (Vector3(58, 0, 0) if d < 0 else Vector3(96, 0, 0)),
			"hand_r": (Vector3(-58, 90, 0) if d < 0 else Vector3(-62, 90, 0)),
			"shoulder_l": Vector3(46, 24 * d, -18), "elbow_l": Vector3(70, 0, 0),
		})
		var mid := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.84, -0.06 * big), "hips": Vector3(0, -4 * d, 0),
			"torso": Vector3(-10, 4 * d, 0), "head": Vector3(2, -2 * d, 0),
			"shoulder_r": Vector3(84, 8 * d, 2), "elbow_r": Vector3(8, 0, 0), "hand_r": Vector3(-82, 90, 0),
		})
		var reach_out := with(mid, {
			"hips": Vector3(0, -10 * d, 0), "torso": Vector3(-12, -14 * d * big, 0), "head": Vector3(2, 10 * d, 0),
			"shoulder_r": Vector3(86, -36 * d, 0), "elbow_r": Vector3(0, 0, 0), "hand_r": Vector3(-86, 90, 0),
			"shoulder_l": Vector3(26, -20 * d, -34), "elbow_l": Vector3(56, 0, 0),
		})
		var follow := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.84, -0.07 * big), "hips": Vector3(0, -14 * d, 0),
			"torso": Vector3(-12, -32 * d * big, 0), "head": Vector3(0, 24 * d, 0),
			"shoulder_r": (Vector3(78, 78 * big, -8) if d < 0 else Vector3(76, -80 * big, 16)),
			"elbow_r": Vector3(18, 0, 0), "hand_r": Vector3(-76, 90, 0),
			"shoulder_l": Vector3(18, -34 * d, -40), "elbow_l": Vector3(44, 0, 0),
			"foot_r": Vector3(40, 0, 0),
		})
		var settle := with(follow, {
			"hips": Vector3(0, -10 * d, 0),
			"shoulder_r": (Vector3(66, 70 * big, -6) if d < 0 else Vector3(64, -72 * big, 18)),
			"elbow_r": Vector3(30, 0, 0), "hand_r": Vector3(-62, 70, 0),
			"torso": Vector3(-10, -26 * d * big, 0), "shoulder_l": Vector3(30, -10 * d, -28), "elbow_l": Vector3(66, 0, 0),
		})
		if fin:
			# The finisher winds further, steps right through and sweeps wide.
			var step := with(mid, {"hips@pos": Vector3(0, 0.8, -0.16), "leg_l": Vector3(48, 0, -4), "knee_l": Vector3(-60, 0, 0),
				"leg_r": Vector3(-34, 0, 6), "knee_r": Vector3(-12, 0, 0), "foot_r": Vector3(42, 0, 0)})
			var step_out := with(reach_out, {"hips@pos": Vector3(0, 0.79, -0.18), "leg_l": Vector3(50, 0, -4), "knee_l": Vector3(-64, 0, 0),
				"leg_r": Vector3(-36, 0, 6), "knee_r": Vector3(-12, 0, 0), "foot_r": Vector3(44, 0, 0)})
			follow["hips@pos"] = Vector3(0, 0.8, -0.18)
			settle["hips@pos"] = Vector3(0, 0.81, -0.18)
			clip(n, 0.56, [[0.0, ready], [0.1, cock], [0.16, step], [0.2, step_out], [0.26, follow], [0.38, settle], [0.56, ready]], ready)
		else:
			clip(n, 0.42, [[0.0, ready], [0.06, cock], [0.12, mid], [0.155, reach_out], [0.2, follow], [0.28, settle], [0.42, ready]], ready)

	# The chop (normal_kiru): up over the right shoulder, the heel of the rear
	# foot lifting, and down across to the left, the knees giving at the
	# bottom; the finisher rises up on the toes first and drops into a crouch.
	for spec in [["slash_down", false], ["slash_down_fin", true]]:
		var n: String = spec[0]
		var fin: bool = spec[1]
		var up := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.95 if fin else 0.9, 0.03),
			"leg_l": Vector3(16, 0, -4), "knee_l": Vector3(-20, 0, 0), "leg_r": Vector3(-6, 0, 5), "knee_r": Vector3(-10, 0, 0),
			"foot_r": Vector3(24 if fin else 14, 0, 0), "foot_l": Vector3(14 if fin else 4, 0, 0),
			"torso": Vector3(12 if fin else 6, -16, 0), "head": Vector3(-10, 12, 0),
			"shoulder_r": Vector3(174, -18, 16), "elbow_r": Vector3(80, 0, 0), "hand_r": Vector3(-34, 0, 0),
			"shoulder_l": Vector3(64, 14, -30), "elbow_l": Vector3(70, 0, 0),
		})
		var mid := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.84, -0.06),
			"torso": Vector3(-10, -4, 0), "head": Vector3(4, 2, 0),
			"shoulder_r": Vector3(118, 0, 8), "elbow_r": Vector3(14, 0, 0), "hand_r": Vector3(-62, 0, 0),
		})
		var down := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.7 if fin else 0.8, -0.1 if fin else -0.07),
			"leg_l": Vector3(58 if fin else 46, 0, -4), "knee_l": Vector3(-82 if fin else -62, 0, 0),
			"leg_r": Vector3(-26, 0, 6), "knee_r": Vector3(-44 if fin else -24, 0, 0), "foot_r": Vector3(44, 0, 0),
			"torso": Vector3(-34 if fin else -24, 16, 0), "head": Vector3(18, -10, 0),
			"shoulder_r": Vector3(46, 16, 2), "elbow_r": Vector3(4, 0, 0), "hand_r": Vector3(-84, 0, 0),
			"shoulder_l": Vector3(14, -16, -40), "elbow_l": Vector3(48, 0, 0),
		})
		var sink := with(down, {"hips@pos": Vector3(0, 0.66 if fin else 0.77, -0.1 if fin else -0.07),
			"torso": Vector3(-38 if fin else -27, 18, 0), "shoulder_r": Vector3(40, 18, 2), "hand_r": Vector3(-86, 0, 0)})
		var hold := with(down, {"shoulder_r": Vector3(42, 18, 2), "elbow_r": Vector3(12, 0, 0), "hand_r": Vector3(-74, 0, 0)})
		if fin:
			clip(n, 0.6, [[0.0, ready], [0.14, up], [0.2, mid], [0.25, down], [0.3, sink], [0.42, hold], [0.6, ready]], ready)
		else:
			clip(n, 0.42, [[0.0, ready], [0.07, up], [0.12, mid], [0.17, down], [0.21, sink], [0.28, hold], [0.42, ready]], ready)

	# The thrust (pierce_kiru): the blade drawn back level at the hip with the
	# weight on the back foot, then driven straight out off it with the right
	# shoulder turned in behind, past full stretch, and recovered.
	for spec in [["stab", false], ["stab_fin", true]]:
		var n: String = spec[0]
		var fin: bool = spec[1]
		var draw := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.85, 0.06), "hips": Vector3(0, -8, 0),
			"leg_l": Vector3(16, 0, -4), "knee_l": Vector3(-28, 0, 0), "leg_r": Vector3(-8, 0, 5), "knee_r": Vector3(-28, 0, 0),
			"torso": Vector3(-6, -26, 0), "head": Vector3(0, 24, 0),
			"shoulder_r": Vector3(8, -14, 22), "elbow_r": Vector3(106, 0, 0), "hand_r": Vector3(-88, 90, 0),
			"shoulder_l": Vector3(52, 22, -18), "elbow_l": Vector3(84, 0, 0),
		})
		var out := with(with(ready, lunge), {
			"hips@pos": Vector3(0, 0.76 if fin else 0.82, -0.22 if fin else -0.12), "hips": Vector3(0, 8, 0),
			"leg_l": Vector3(56 if fin else 44, 0, -4), "knee_l": Vector3(-74 if fin else -58, 0, 0),
			"leg_r": Vector3(-36 if fin else -30, 0, 6), "knee_r": Vector3(-8, 0, 0), "foot_r": Vector3(48, 0, 0),
			"torso": Vector3(-14, 22, 0), "head": Vector3(2, -18, 0),
			"shoulder_r": Vector3(86, 14, 2), "elbow_r": Vector3(0, 0, 0), "hand_r": Vector3(-90, 90, 0),
			"shoulder_l": Vector3(20, -20, -34), "elbow_l": Vector3(50, 0, 0),
		})
		var stretch := with(out, {"hips@pos": Vector3(0, 0.75 if fin else 0.81, -0.26 if fin else -0.15), "torso": Vector3(-16, 26, 0), "shoulder_r": Vector3(88, 16, 0)})
		var hold := with(out, {"shoulder_r": Vector3(82 if fin else 80, 12, 3), "elbow_r": Vector3(8 if fin else 12, 0, 0)})
		if fin:
			clip(n, 0.52, [[0.0, ready], [0.09, draw], [0.16, out], [0.21, stretch], [0.32, hold], [0.52, ready]], ready)
		else:
			clip(n, 0.36, [[0.0, ready], [0.05, draw], [0.11, out], [0.14, stretch], [0.2, hold], [0.36, ready]], ready)

	# The old names (the title's attract scene, the dark double) play the two cuts.
	for alias in [["attack_1", "slash_left"], ["attack_2", "slash_right"]]:
		if lib.has_animation(alias[0]):
			lib.remove_animation(alias[0])
		lib.add_animation(alias[0], lib.get_animation(alias[1]))

	# The jump slash (Lpower_jump_kiru): a crouch, a spring with the blade
	# swung up behind his head and the back arched, the knees tucked at the
	# top, held till he lands; then (_hit / _end) the chop into a deep crouch,
	# a sink through it, and up.
	var crouch := with(STAND, {"hips@pos": Vector3(0, 0.8, 0.02), "torso": Vector3(-16, 0, 0), "head": Vector3(10, 0, 0),
		"leg_r": Vector3(36, 0, 4), "knee_r": Vector3(-64, 0, 0), "foot_r": Vector3(28, 0, 0),
		"leg_l": Vector3(36, 0, -4), "knee_l": Vector3(-64, 0, 0), "foot_l": Vector3(28, 0, 0),
		"shoulder_r": Vector3(-20, 0, 18), "elbow_r": Vector3(40, 0, 0), "hand_r": Vector3(-20, 0, 0)})
	var raised := with(STAND, {
		"hips@pos": Vector3(0, 0.95, 0), "torso": Vector3(12, 0, 0), "head": Vector3(-10, 0, 0),
		"shoulder_r": Vector3(168, 0, 6), "elbow_r": Vector3(56, 0, 0), "hand_r": Vector3(-14, 0, 0),
		"shoulder_l": Vector3(34, 0, -38), "elbow_l": Vector3(50, 0, 0),
		"leg_r": Vector3(58, 0, 4), "knee_r": Vector3(-100, 0, 0), "foot_r": Vector3(32, 0, 0),
		"leg_l": Vector3(22, 0, -4), "knee_l": Vector3(-64, 0, 0), "foot_l": Vector3(26, 0, 0)})
	clip("jumpslash", 0.45, [[0.0, crouch], [0.07, with(raised, {"hips@pos": Vector3(0, 0.92, 0), "leg_r": Vector3(10, 0, 4), "knee_r": Vector3(-20, 0, 0),
		"leg_l": Vector3(4, 0, -4), "knee_l": Vector3(-14, 0, 0), "shoulder_r": Vector3(120, 0, 10)})], [0.15, raised],
		[0.45, with(raised, {"torso": Vector3(16, 0, 0), "shoulder_r": Vector3(172, 0, 6)})]], STAND)
	var chop := with(STAND, {
		"hips@pos": Vector3(0, 0.6, 0.04), "torso": Vector3(-26, 0, 0), "head": Vector3(16, 0, 0),
		"shoulder_r": Vector3(56, 0, 4), "elbow_r": Vector3(4, 0, 0), "hand_r": Vector3(-80, 0, 0),
		"shoulder_l": Vector3(-20, 0, -42), "elbow_l": Vector3(40, 0, 0),
		"leg_l": Vector3(74, 0, -6), "knee_l": Vector3(-102, 0, 0), "foot_l": Vector3(28, 0, 0),
		"leg_r": Vector3(-8, 0, 8), "knee_r": Vector3(-72, 0, 0), "foot_r": Vector3(56, 0, 0)})
	var deep := with(chop, {"hips@pos": Vector3(0, 0.56, 0.05), "torso": Vector3(-32, 0, 0), "shoulder_r": Vector3(50, 0, 4), "hand_r": Vector3(-84, 0, 0)})
	clip("jumpslash_land", 0.5, [[0.0, with(raised, {"torso": Vector3(16, 0, 0)})], [0.06, chop], [0.12, deep], [0.28, with(deep, {"hips@pos": Vector3(0, 0.6, 0.04)})],
		[0.5, with(STAND, {"hips@pos": Vector3(0, 0.91, 0)})]], STAND)

	# Gathering the Great Spin: crouched, the blade drawn back low at his
	# side, the body wound up, trembling with the strength held in.
	var gather := with(STAND, {
		"hips@pos": Vector3(0, 0.82, 0.01), "hips": Vector3(0, 10, 0),
		"torso": Vector3(-12, 30, 0), "head": Vector3(8, -34, 0),
		"shoulder_r": Vector3(20, 60, 30), "elbow_r": Vector3(30, 0, 0), "hand_r": Vector3(-60, 90, 0),
		"shoulder_l": Vector3(44, -24, -24), "elbow_l": Vector3(66, 0, 0),
		"leg_l": Vector3(32, 0, -14), "knee_l": Vector3(-46, 0, 0), "foot_l": Vector3(14, 0, 0),
		"leg_r": Vector3(-12, 0, 14), "knee_r": Vector3(-28, 0, 0), "foot_r": Vector3(26, 0, 0)})
	var shake: Array = []
	for i in 6:
		var s := 1.0 if i % 2 == 0 else -1.0
		shake.append([i * 0.1, with(gather, {"torso": Vector3(-12 + 0.6 * s, 30 + 1.2 * s, 0.8 * s),
			"shoulder_r": Vector3(20 + 1.4 * s, 60, 30), "hips@pos": Vector3(0, 0.82 + 0.003 * s, 0.01)})])
	clip("spin_charge", 0.6, shake, STAND, true)
	# The Great Spin: low in a wide stance, the blade out flat at arm's
	# length, the body leaning out against the turn and the shield arm flung
	# wide (the controller turns him the full circle).
	var spin_out := with(STAND, {
		"hips@pos": Vector3(0, 0.78, 0), "torso": Vector3(-10, -14, -8), "head": Vector3(4, 16, 0),
		"shoulder_r": Vector3(86, -64, 0), "elbow_r": Vector3(4, 0, 0), "hand_r": Vector3(-84, 90, 0),
		"shoulder_l": Vector3(16, 0, -70), "elbow_l": Vector3(30, 0, 0),
		"leg_l": Vector3(34, 0, -16), "knee_l": Vector3(-52, 0, 0), "foot_l": Vector3(18, 0, 0),
		"leg_r": Vector3(-14, 0, 16), "knee_r": Vector3(-28, 0, 0), "foot_r": Vector3(32, 0, 0)})
	clip("spin_attack", 0.42, [[0.0, with(gather, {})], [0.08, spin_out], [0.3, with(spin_out, {"shoulder_r": Vector3(86, -74, 0), "torso": Vector3(-10, -20, -10)})],
		[0.42, with(STAND, {"hips@pos": Vector3(0, 0.86, 0), "shoulder_r": Vector3(60, -40, 0), "elbow_r": Vector3(20, 0, 0), "hand_r": Vector3(-60, 90, 0)})]], STAND)

	# The Shield Bash (Twilight Princess' shield attack): the shield drawn in,
	# the weight rocked back, then a shove behind it off the back foot, past
	# full stretch, and back.
	var b_in := with(STAND, {"hips@pos": Vector3(0, 0.86, 0.04), "torso": Vector3(-4, -26, 0), "head": Vector3(4, 16, 0),
		"shoulder_l": Vector3(44, -16, -18), "elbow_l": Vector3(104, 0, 0), "shield": Vector3(0, 62, 0),
		"shoulder_r": Vector3(18, 0, 16), "elbow_r": Vector3(40, 0, 0),
		"leg_l": Vector3(8, 0, -4), "knee_l": Vector3(-20, 0, 0), "leg_r": Vector3(-6, 0, 4), "knee_r": Vector3(-22, 0, 0)})
	var shove := with(STAND, {"hips@pos": Vector3(0, 0.82, -0.12), "torso": Vector3(-18, 10, 0), "head": Vector3(10, -6, 0),
		"shoulder_l": Vector3(88, 10, -6), "elbow_l": Vector3(30, 0, 0), "shield": Vector3(0, 62, 0),
		"shoulder_r": Vector3(-20, 0, 20), "elbow_r": Vector3(50, 0, 0),
		"leg_l": Vector3(42, 0, -4), "knee_l": Vector3(-42, 0, 0), "leg_r": Vector3(-26, 0, 4), "knee_r": Vector3(-12, 0, 0), "foot_r": Vector3(36, 0, 0)})
	var b_far := with(shove, {"hips@pos": Vector3(0, 0.81, -0.15), "torso": Vector3(-20, 14, 0), "shoulder_l": Vector3(90, 12, -4), "elbow_l": Vector3(20, 0, 0)})
	clip("shield_bash", 0.38, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.88, 0)})], [0.05, b_in], [0.1, shove], [0.14, b_far], [0.25, shove], [0.38, with(STAND, {"hips@pos": Vector3(0, 0.88, 0)})]], STAND)

	# The shield raised (Z-target guard), and the jolt of a blow on it.
	var guard := with(STAND, {"hips@pos": Vector3(0, 0.86, 0), "torso": Vector3(-8, -8, 0), "head": Vector3(6, 0, 0),
		"shoulder_l": Vector3(58, -32, 0), "elbow_l": Vector3(118, 0, 0), "shield": Vector3(0, 62, 0),
		"shoulder_r": Vector3(25, 0, 18), "elbow_r": Vector3(45, 0, 0), "hand_r": Vector3(-5, 0, 0),
		"leg_l": Vector3(20, 0, -5), "knee_l": Vector3(-28, 0, 0), "leg_r": Vector3(-12, 0, 5), "knee_r": Vector3(-18, 0, 0), "foot_r": Vector3(25, 0, 0)})
	clip("block", 0.12, [[0.0, STAND], [0.08, with(guard, {"hips@pos": Vector3(0, 0.845, 0), "shoulder_l": Vector3(62, -34, 0)})], [0.12, guard]], STAND)
	clip("block_hit", 0.3, [[0.0, with(guard, {"hips@pos": Vector3(0, 0.82, 0.08), "torso": Vector3(6, -10, 0), "head": Vector3(-4, 0, 0),
		"shoulder_l": Vector3(48, -24, 0), "elbow_l": Vector3(128, 0, 0)})], [0.08, with(guard, {"hips@pos": Vector3(0, 0.83, 0.05), "torso": Vector3(0, -9, 0)})],
		[0.3, guard]], STAND)
	# The crouched guard (OoT's defense without Z): low behind the shield,
	# front knee forward and back knee deep, the sword held low behind.
	var low_guard := with(STAND, {
		"hips@pos": Vector3(0, 0.64, 0.03), "torso": Vector3(-16, -10, 0), "head": Vector3(14, 6, 0),
		"leg_l": Vector3(68, 0, -6), "knee_l": Vector3(-95, 0, 0), "foot_l": Vector3(26, 0, 0),
		"leg_r": Vector3(22, 0, 8), "knee_r": Vector3(-88, 0, 0), "foot_r": Vector3(62, 0, 0),
		"shoulder_l": Vector3(62, -30, 0), "elbow_l": Vector3(112, 0, 0), "shield": Vector3(0, 62, 0),
		"shoulder_r": Vector3(-12, 0, 22), "elbow_r": Vector3(40, 0, 0), "hand_r": Vector3(-15, 0, 0)})
	clip("block_crouch", 0.12, [[0.0, STAND], [0.08, with(low_guard, {"hips@pos": Vector3(0, 0.61, 0.03), "torso": Vector3(-18, -10, 0)})], [0.12, low_guard]], STAND)
	clip("block_crouch_hit", 0.3, [[0.0, with(low_guard, {"hips@pos": Vector3(0, 0.6, 0.12), "torso": Vector3(-2, -12, 0), "head": Vector3(4, 6, 0),
		"shoulder_l": Vector3(52, -22, 0), "elbow_l": Vector3(122, 0, 0)})], [0.09, with(low_guard, {"hips@pos": Vector3(0, 0.62, 0.07), "torso": Vector3(-10, -11, 0)})],
		[0.3, low_guard]], STAND)


# --- Getting about: side steps, turning, the bonk, slopes ---------------------------

func _rework_moves() -> void:
	# The side step (OoT's Z-target side walk): the lead foot reaches out,
	# the other closes after it, the body bobbing and swaying over them, the
	# shield up and the blade ready. Played forward it steps right, backward left.
	var side_base := with(STAND, {"torso": Vector3(-6, 4, 0), "head": Vector3(4, -4, 0),
		"shoulder_r": Vector3(24, 0, 14), "elbow_r": Vector3(42, 0, 0), "hand_r": Vector3(-42, 0, 0),
		"shoulder_l": Vector3(35, -20, -15), "elbow_l": Vector3(70, 0, 0)})
	var sk: Array = []
	for i in 8:
		var ph := i / 8.0
		var sn := sin(ph * TAU)
		var out := maxf(sn, 0.0)
		var close := maxf(-sn, 0.0)
		sk.append([ph * 0.6, with(side_base, {
			"hips@pos": Vector3(0.015 * sn, 0.885 + 0.03 * absf(sn), 0), "hips": Vector3(0, 0, 4 * sn), "torso": Vector3(-6, 4, -3 * sn),
			"leg_r": Vector3(8 + 8 * out, 0, 4 + 18 * out), "knee_r": Vector3(-18 - 26 * out, 0, 0), "foot_r": Vector3(10 + 12 * out, 0, -4 - 10 * out),
			"leg_l": Vector3(8 + 8 * close, 0, -4 + 16 * close), "knee_l": Vector3(-18 - 26 * close, 0, 0), "foot_l": Vector3(10 + 12 * close, 0, 4 - 8 * close),
			"shoulder_r": Vector3(22 + 3 * sn, 0, 14)})])
	clip("sidestep", 0.6, sk, STAND, true)
	# Turning on the spot: little pivoting steps, the shoulders leading.
	var tk: Array = []
	for i in 4:
		var r := i % 2 == 0
		tk.append([i * 0.1, with(STAND, {"hips@pos": Vector3(0, 0.93 if i % 2 == 1 else 0.905, 0), "torso": Vector3(-2, 6, 0), "head": Vector3(0, 10, 0),
			"leg_r": Vector3(22 if r and i == 0 else 0, 0, 5), "knee_r": Vector3(-36 if r and i == 0 else -4, 0, 0), "foot_r": Vector3(16 if r and i == 0 else 0, 0, 0),
			"leg_l": Vector3(22 if i == 2 else 0, 0, -5), "knee_l": Vector3(-36 if i == 2 else -4, 0, 0), "foot_l": Vector3(16 if i == 2 else 0, 0, 0)})])
	clip("turn", 0.4, tk, STAND, true)
	# The bonk (rolling into a wall, OoT): bounced off, down on his seat with
	# a jolt, the head shaken clear, and up (State.BONK lasts 0.5 s).
	var seat := with(STAND, {"hips@pos": Vector3(0, 0.42, 0.08), "torso": Vector3(-20, 0, 0), "head": Vector3(6, 0, 0),
		"leg_r": Vector3(84, 0, 10), "knee_r": Vector3(-40, 0, 0), "foot_r": Vector3(10, 0, 0),
		"leg_l": Vector3(84, 0, -10), "knee_l": Vector3(-44, 0, 0), "foot_l": Vector3(10, 0, 0),
		"shoulder_r": Vector3(-24, 0, 26), "elbow_r": Vector3(16, 0, 0), "shoulder_l": Vector3(-24, 0, -26), "elbow_l": Vector3(16, 0, 0)})
	clip("bonk", 0.5, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.8, 0.04), "torso": Vector3(26, 0, 0), "head": Vector3(-26, 0, 0),
		"shoulder_r": Vector3(30, 0, 44), "shoulder_l": Vector3(30, 0, -44)})], [0.1, seat], [0.16, with(seat, {"hips@pos": Vector3(0, 0.46, 0.08)})],
		[0.24, with(seat, {"head": Vector3(10, 16, 0)})], [0.3, with(seat, {"head": Vector3(10, -16, 0)})], [0.36, with(seat, {"head": Vector3(8, 10, 0)})],
		[0.5, with(STAND, {"hips@pos": Vector3(0, 0.82, 0.02), "torso": Vector3(-14, 0, 0)})]], STAND)
	# Sliding down a slippery slope facing down it: crouched, leaning back,
	# arms out and wobbling for balance; and backward facing up it, bent over
	# and clawing at the slope.
	var slip := with(STAND, {"hips@pos": Vector3(0, 0.74, -0.05), "torso": Vector3(10, 0, 3), "head": Vector3(12, 0, 0),
		"leg_r": Vector3(55, 0, 8), "knee_r": Vector3(-80, 0, 0), "foot_r": Vector3(30, 0, 0),
		"leg_l": Vector3(30, 0, -8), "knee_l": Vector3(-60, 0, 0), "foot_l": Vector3(25, 0, 0),
		"shoulder_r": Vector3(-15, 0, 72), "elbow_r": Vector3(15, 0, 0), "shoulder_l": Vector3(-10, 0, -60), "elbow_l": Vector3(15, 0, 0)})
	clip("slope_slip", 0.6, [[0.0, slip], [0.3, with(slip, {"hips@pos": Vector3(0, 0.72, -0.05), "torso": Vector3(10, 0, -4),
		"shoulder_r": Vector3(-8, 0, 60), "shoulder_l": Vector3(-16, 0, -74)})]], STAND, true)
	var claw := with(STAND, {"hips@pos": Vector3(0, 0.76, 0.06), "torso": Vector3(-45, 0, 0), "head": Vector3(-25, 0, 0),
		"leg_r": Vector3(40, 0, 6), "knee_r": Vector3(-50, 0, 0), "foot_r": Vector3(10, 0, 0),
		"leg_l": Vector3(45, 0, -6), "knee_l": Vector3(-55, 0, 0), "foot_l": Vector3(10, 0, 0),
		"shoulder_r": Vector3(-82, 0, 15), "elbow_r": Vector3(10, 0, 0), "shoulder_l": Vector3(-68, 0, -15), "elbow_l": Vector3(14, 0, 0)})
	clip("slope_slip_up", 0.6, [[0.0, claw], [0.3, with(claw, {"hips@pos": Vector3(0, 0.74, 0.06), "torso": Vector3(-42, 0, 0),
		"shoulder_r": Vector3(-68, 0, 15), "shoulder_l": Vector3(-84, 0, -15)})]], STAND, true)


# --- Climbing, swimming, riding ---------------------------------------------------

func _rework_traverse() -> void:
	# Hanging from a ledge (jump_climb_hold / _wait): arms straight up to the
	# edge, the body swaying a little under them, the legs swinging loose.
	var hang := with(STAND, {"hips@pos": Vector3(0, 0.92, 0.04), "torso": Vector3(-4, 0, 0), "head": Vector3(10, 0, 0),
		"shoulder_r": Vector3(162, 0, -4), "elbow_r": Vector3(12, 0, 0), "hand_r": Vector3(-30, 0, 0),
		"shoulder_l": Vector3(162, 0, 4), "elbow_l": Vector3(12, 0, 0),
		"leg_r": Vector3(8, 0, 4), "knee_r": Vector3(-14, 0, 0), "foot_r": Vector3(30, 0, 0),
		"leg_l": Vector3(-4, 0, -4), "knee_l": Vector3(-8, 0, 0), "foot_l": Vector3(30, 0, 0)})
	clip("hang", 1.6, [[0.0, hang], [0.8, with(hang, {"hips": Vector3(2, 0, 1.5), "torso": Vector3(-5, 0, -1),
		"leg_r": Vector3(-2, 0, 4), "knee_r": Vector3(-6, 0, 0), "leg_l": Vector3(8, 0, -4), "knee_l": Vector3(-16, 0, 0)})]], STAND, true)
	# Pulling up (jump_climb_up): a kick of the legs, the elbows bending and
	# pushing down, a knee onto the edge, a crouch on top, standing.
	var standing := with(STAND, {})
	var pull := with(STAND, {"hips@pos": Vector3(0, 0.86, 0.05), "torso": Vector3(-32, 0, 0), "head": Vector3(14, 0, 0),
		"shoulder_r": Vector3(35, 0, 12), "elbow_r": Vector3(95, 0, 0), "hand_r": Vector3(-40, 0, 0),
		"shoulder_l": Vector3(35, 0, -12), "elbow_l": Vector3(95, 0, 0),
		"leg_r": Vector3(85, 0, 6), "knee_r": Vector3(-110, 0, 0), "foot_r": Vector3(20, 0, 0),
		"leg_l": Vector3(-10, 0, -4), "knee_l": Vector3(-25, 0, 0), "foot_l": Vector3(35, 0, 0)})
	var top := with(STAND, {"hips@pos": Vector3(0, 0.62, 0.02), "torso": Vector3(-28, 0, 0), "head": Vector3(16, 0, 0),
		"shoulder_r": Vector3(30, 0, 18), "elbow_r": Vector3(45, 0, 0), "hand_r": Vector3(-20, 0, 0),
		"shoulder_l": Vector3(30, 0, -18), "elbow_l": Vector3(45, 0, 0),
		"leg_r": Vector3(80, 0, 6), "knee_r": Vector3(-120, 0, 0), "foot_r": Vector3(40, 0, 0),
		"leg_l": Vector3(35, 0, -5), "knee_l": Vector3(-100, 0, 0), "foot_l": Vector3(60, 0, 0)})
	var kick := with(hang, {"leg_r": Vector3(30, 0, 4), "knee_r": Vector3(-50, 0, 0), "leg_l": Vector3(-12, 0, -4), "elbow_r": Vector3(30, 0, 0), "elbow_l": Vector3(30, 0, 0)})
	clip("hang_up", 1.0, [[0.0, hang], [0.12, kick], [0.34, pull], [0.66, top], [0.86, with(standing, {"hips@pos": Vector3(0, 0.94, 0)})], [1.0, standing]], STAND)
	# Stepping up onto chest-high and head-high ledges (100step_up / 150step_up).
	var reach_up := with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "torso": Vector3(-8, 0, 0), "head": Vector3(12, 0, 0),
		"shoulder_r": Vector3(135, 0, 6), "elbow_r": Vector3(25, 0, 0), "hand_r": Vector3(-30, 0, 0),
		"shoulder_l": Vector3(135, 0, -6), "elbow_l": Vector3(25, 0, 0),
		"leg_r": Vector3(10, 0, 3), "knee_r": Vector3(-20, 0, 0), "foot_r": Vector3(10, 0, 0),
		"leg_l": Vector3(0, 0, -3), "knee_l": Vector3(-10, 0, 0), "foot_l": Vector3(10, 0, 0)})
	for variant in [["climb_low", 0.55], ["climb_high", 0.8]]:
		var L: float = variant[1]
		clip(variant[0], L, [[0.0, reach_up], [L * 0.3, pull], [L * 0.68, top], [L * 0.86, with(standing, {"hips@pos": Vector3(0, 0.935, 0)})], [L, standing]], STAND)
	# Springing up the wall to catch a high ledge (250jump_start).
	clip("jump_reach", 0.3, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.8, 0), "torso": Vector3(-14, 0, 0), "head": Vector3(6, 0, 0),
		"shoulder_r": Vector3(-24, 0, 10), "elbow_r": Vector3(30, 0, 0), "shoulder_l": Vector3(-24, 0, -10), "elbow_l": Vector3(30, 0, 0),
		"leg_r": Vector3(40, 0, 3), "knee_r": Vector3(-70, 0, 0), "foot_r": Vector3(25, 0, 0), "leg_l": Vector3(40, 0, -3), "knee_l": Vector3(-70, 0, 0), "foot_l": Vector3(25, 0, 0)})],
		[0.12, with(STAND, {"hips@pos": Vector3(0, 0.95, 0), "torso": Vector3(-2, 0, 0), "head": Vector3(16, 0, 0),
		"shoulder_r": Vector3(168, 0, -2), "elbow_r": Vector3(8, 0, 0), "shoulder_l": Vector3(168, 0, 2), "elbow_l": Vector3(8, 0, 0),
		"leg_r": Vector3(5, 0, 3), "knee_r": Vector3(-10, 0, 0), "foot_r": Vector3(34, 0, 0), "leg_l": Vector3(-5, 0, -3), "knee_l": Vector3(-5, 0, 0), "foot_l": Vector3(34, 0, 0)})],
		[0.3, with(STAND, {"hips@pos": Vector3(0, 0.94, 0), "head": Vector3(14, 0, 0), "shoulder_r": Vector3(164, 0, -2), "elbow_r": Vector3(12, 0, 0),
		"shoulder_l": Vector3(164, 0, 2), "elbow_l": Vector3(12, 0, 0), "leg_r": Vector3(14, 0, 3), "knee_r": Vector3(-30, 0, 0), "foot_r": Vector3(30, 0, 0)})]], STAND)
	# The ladder (climb_upL / climb_upR): hand over hand, foot over foot,
	# the body swaying toward the reaching hand; one cycle is two rungs.
	var rung_a := with(STAND, {"hips@pos": Vector3(0, 0.92, 0.05), "hips": Vector3(0, 0, 2), "torso": Vector3(-6, 0, -2), "head": Vector3(10, 4, 0),
		"shoulder_r": Vector3(152, 0, -4), "elbow_r": Vector3(38, 0, 0), "hand_r": Vector3(-30, 0, 0),
		"shoulder_l": Vector3(98, 0, 4), "elbow_l": Vector3(72, 0, 0),
		"leg_r": Vector3(64, 0, 4), "knee_r": Vector3(-92, 0, 0), "foot_r": Vector3(26, 0, 0),
		"leg_l": Vector3(10, 0, -4), "knee_l": Vector3(-20, 0, 0), "foot_l": Vector3(15, 0, 0)})
	var rung_b := with(rung_a, {"hips": Vector3(0, 0, -2), "torso": Vector3(-6, 0, 2), "head": Vector3(10, -4, 0),
		"shoulder_r": Vector3(98, 0, -4), "elbow_r": Vector3(72, 0, 0), "shoulder_l": Vector3(152, 0, 4), "elbow_l": Vector3(38, 0, 0),
		"leg_r": Vector3(10, 0, 4), "knee_r": Vector3(-20, 0, 0), "foot_r": Vector3(15, 0, 0),
		"leg_l": Vector3(64, 0, -4), "knee_l": Vector3(-92, 0, 0), "foot_l": Vector3(26, 0, 0)})
	clip("ladder_climb", 1.0, [[0.0, rung_a], [0.25, with(rung_a, {"hips@pos": Vector3(0, 0.95, 0.05)})], [0.5, rung_b], [0.75, with(rung_b, {"hips@pos": Vector3(0, 0.95, 0.05)})]], STAND, true)

	# Swimming (link_swimer_swim): a breaststroke, the hands reaching ahead
	# together, sweeping out and round, tucked under the chin and shot forward
	# again, the frog kick snapping shut as the arms reach, the head lifting
	# to breathe on the pull.
	var sw := 0.75
	var glide := with(STAND, {"hips@pos": Vector3(0, 1.14, 0.12), "hips": Vector3(-62, 0, 0), "torso": Vector3(4, 0, 0), "head": Vector3(34, 0, 0),
		"shoulder_r": Vector3(170, 0, 8), "elbow_r": Vector3(8, 0, 0), "shoulder_l": Vector3(170, 0, -8), "elbow_l": Vector3(8, 0, 0),
		"leg_r": Vector3(-8, 0, 6), "knee_r": Vector3(-10, 0, 0), "foot_r": Vector3(46, 0, 0),
		"leg_l": Vector3(-8, 0, -6), "knee_l": Vector3(-10, 0, 0), "foot_l": Vector3(46, 0, 0)})
	var sweep := with(glide, {"hips@pos": Vector3(0, 1.16, 0.12), "head": Vector3(44, 0, 0), "torso": Vector3(-4, 0, 0),
		"shoulder_r": Vector3(118, 0, 72), "elbow_r": Vector3(24, 0, 0), "shoulder_l": Vector3(118, 0, -72), "elbow_l": Vector3(24, 0, 0)})
	var tuck := with(glide, {"hips@pos": Vector3(0, 1.17, 0.12), "head": Vector3(40, 0, 0),
		"shoulder_r": Vector3(46, 0, 36), "elbow_r": Vector3(100, 0, 0), "shoulder_l": Vector3(46, 0, -36), "elbow_l": Vector3(100, 0, 0),
		"leg_r": Vector3(44, 0, 22), "knee_r": Vector3(-100, 0, 0), "foot_r": Vector3(20, 0, 0),
		"leg_l": Vector3(44, 0, -22), "knee_l": Vector3(-100, 0, 0), "foot_l": Vector3(20, 0, 0)})
	var shoot := with(glide, {"shoulder_r": Vector3(120, 0, 10), "elbow_r": Vector3(60, 0, 0), "shoulder_l": Vector3(120, 0, -10), "elbow_l": Vector3(60, 0, 0),
		"leg_r": Vector3(10, 0, 26), "knee_r": Vector3(-40, 0, 0), "leg_l": Vector3(10, 0, -26), "knee_l": Vector3(-40, 0, 0)})
	clip("swim", sw, [[0.0, glide], [sw * 0.32, sweep], [sw * 0.56, tuck], [sw * 0.8, shoot]], STAND, true)
	# Treading water: upright, the hands sculling out and in, the legs
	# pedalling slowly under him.
	var tread := with(STAND, {"hips@pos": Vector3(0, 0.9, 0), "hips": Vector3(-12, 0, 0), "head": Vector3(8, 0, 0),
		"shoulder_r": Vector3(35, 0, 55), "elbow_r": Vector3(40, 0, 0), "shoulder_l": Vector3(35, 0, -55), "elbow_l": Vector3(40, 0, 0),
		"leg_r": Vector3(25, 0, 6), "knee_r": Vector3(-60, 0, 0), "foot_r": Vector3(30, 0, 0),
		"leg_l": Vector3(-5, 0, -6), "knee_l": Vector3(-20, 0, 0), "foot_l": Vector3(30, 0, 0)})
	clip("swim_wait", 1.2, [[0.0, tread], [0.6, with(tread, {"hips@pos": Vector3(0, 0.93, 0), "head": Vector3(12, 0, 0),
		"shoulder_r": Vector3(38, 0, 24), "elbow_r": Vector3(62, 0, 0), "shoulder_l": Vector3(38, 0, -24), "elbow_l": Vector3(62, 0, 0),
		"leg_r": Vector3(-5, 0, 6), "knee_r": Vector3(-20, 0, 0), "leg_l": Vector3(25, 0, -6), "knee_l": Vector3(-60, 0, 0)})]], STAND, true)
	# Diving (swim_deep_start): head first, the arms pulling him down, the legs kicking.
	var down := with(STAND, {"hips@pos": Vector3(0, 1.0, 0.2), "hips": Vector3(-120, 0, 0), "head": Vector3(20, 0, 0),
		"shoulder_r": Vector3(172, 0, 6), "elbow_r": Vector3(6, 0, 0), "shoulder_l": Vector3(172, 0, -6), "elbow_l": Vector3(6, 0, 0),
		"leg_r": Vector3(-15, 0, 4), "knee_r": Vector3(-10, 0, 0), "foot_r": Vector3(45, 0, 0),
		"leg_l": Vector3(15, 0, -4), "knee_l": Vector3(-50, 0, 0), "foot_l": Vector3(45, 0, 0)})
	clip("dive", 0.8, [[0.0, down], [0.4, with(down, {"shoulder_r": Vector3(140, 0, 50), "elbow_r": Vector3(30, 0, 0), "shoulder_l": Vector3(140, 0, -50), "elbow_l": Vector3(30, 0, 0),
		"leg_r": Vector3(15, 0, 4), "knee_r": Vector3(-50, 0, 0), "leg_l": Vector3(-15, 0, -4), "knee_l": Vector3(-10, 0, 0)})]], STAND, true)

	# On horseback: astride the saddle, the knees round her barrel, the hands
	# forward on the reins moving with her head; at the gallop he rises out of
	# the saddle in the stirrups and leans into the wind.
	var seat := with(STAND, {"hips@pos": Vector3(0, 0.92, 0), "torso": Vector3(-6, 0, 0),
		"leg_r": Vector3(62, 0, 28), "knee_r": Vector3(-78, 0, 0), "foot_r": Vector3(20, 0, 0),
		"leg_l": Vector3(62, 0, -28), "knee_l": Vector3(-78, 0, 0), "foot_l": Vector3(20, 0, 0),
		"shoulder_r": Vector3(38, -14, 10), "elbow_r": Vector3(62, 0, 0), "hand_r": Vector3(-20, 0, 0),
		"shoulder_l": Vector3(38, 14, -10), "elbow_l": Vector3(62, 0, 0)})
	clip("ride", 1.8, [[0.0, seat], [0.45, with(seat, {"hips@pos": Vector3(0, 0.93, 0), "torso": Vector3(-5, 0, 1), "head": Vector3(0, 6, 0)})],
		[0.9, with(seat, {"hips@pos": Vector3(0, 0.935, 0), "torso": Vector3(-4, 0, 0), "shoulder_r": Vector3(40, -14, 10), "shoulder_l": Vector3(40, 14, -10)})],
		[1.35, with(seat, {"hips@pos": Vector3(0, 0.925, 0), "head": Vector3(0, -6, 0)})]], STAND, true)
	var gal := with(seat, {"hips@pos": Vector3(0, 0.97, 0.02), "torso": Vector3(-20, 0, 0), "head": Vector3(14, 0, 0),
		"leg_r": Vector3(46, 0, 26), "knee_r": Vector3(-90, 0, 0), "foot_r": Vector3(32, 0, 0),
		"leg_l": Vector3(46, 0, -26), "knee_l": Vector3(-90, 0, 0), "foot_l": Vector3(32, 0, 0),
		"shoulder_r": Vector3(50, -14, 10), "elbow_r": Vector3(50, 0, 0), "shoulder_l": Vector3(50, 14, -10), "elbow_l": Vector3(50, 0, 0)})
	clip("ride_gallop", 0.5, [[0.0, gal], [0.25, with(gal, {"hips@pos": Vector3(0, 1.04, -0.02), "torso": Vector3(-14, 0, 0), "head": Vector3(9, 0, 0),
		"knee_r": Vector3(-70, 0, 0), "knee_l": Vector3(-70, 0, 0), "leg_r": Vector3(38, 0, 24), "leg_l": Vector3(38, 0, -24),
		"shoulder_r": Vector3(42, -14, 10), "elbow_r": Vector3(64, 0, 0), "shoulder_l": Vector3(42, 14, -10), "elbow_l": Vector3(64, 0, 0)})]], STAND, true)


# --- Carrying, treasure, the story's poses ------------------------------------------

func _rework_misc() -> void:
	# Lifting (OoT's carryB): a squat with the back straight, hands on it at
	# 0.13 s, a heave up through the legs, and it overhead.
	var carry_up := {"torso": Vector3(4, 0, 0), "head": Vector3(-6, 0, 0),
		"shoulder_r": Vector3(165, 0, 16), "elbow_r": Vector3(30, 0, 0), "hand_r": Vector3(-40, 0, 0),
		"shoulder_l": Vector3(165, 0, -16), "elbow_l": Vector3(30, 0, 0)}
	var squat := with(STAND, {"hips@pos": Vector3(0, 0.6, 0.06), "torso": Vector3(-34, 0, 0), "head": Vector3(22, 0, 0),
		"shoulder_r": Vector3(64, 0, 14), "elbow_r": Vector3(16, 0, 0), "hand_r": Vector3(-30, 0, 0),
		"shoulder_l": Vector3(64, 0, -14), "elbow_l": Vector3(16, 0, 0),
		"leg_r": Vector3(64, 0, 9), "knee_r": Vector3(-104, 0, 0), "foot_r": Vector3(38, 0, 0),
		"leg_l": Vector3(64, 0, -9), "knee_l": Vector3(-104, 0, 0), "foot_l": Vector3(38, 0, 0)})
	var heave := with(STAND, {"hips@pos": Vector3(0, 0.8, 0.02), "torso": Vector3(-10, 0, 0), "head": Vector3(6, 0, 0),
		"shoulder_r": Vector3(96, 0, 18), "elbow_r": Vector3(70, 0, 0), "shoulder_l": Vector3(96, 0, -18), "elbow_l": Vector3(70, 0, 0),
		"leg_r": Vector3(26, 0, 5), "knee_r": Vector3(-44, 0, 0), "foot_r": Vector3(16, 0, 0), "leg_l": Vector3(26, 0, -5), "knee_l": Vector3(-44, 0, 0), "foot_l": Vector3(16, 0, 0)})
	clip("lift", 0.5, [[0.0, STAND], [0.13, squat], [0.22, with(squat, {"hips@pos": Vector3(0, 0.63, 0.05), "torso": Vector3(-28, 0, 0)})],
		[0.34, heave], [0.42, with(with(STAND, carry_up), {"hips@pos": Vector3(0, 0.93, 0)})], [0.5, with(STAND, carry_up)]], STAND)
	# Throwing it (OoT's throw): drawn back behind the head with a lean back,
	# a step and a two-handed heave (released at 0.1 s), followed through.
	clip("throw_carry", 0.45, [[0.0, with(STAND, carry_up)],
		[0.05, with(STAND, {"torso": Vector3(14, 0, 0), "head": Vector3(-12, 0, 0), "hips@pos": Vector3(0, 0.92, 0.03),
		"shoulder_r": Vector3(178, 0, 18), "elbow_r": Vector3(80, 0, 0), "shoulder_l": Vector3(178, 0, -18), "elbow_l": Vector3(80, 0, 0)})],
		[0.12, with(STAND, {"hips@pos": Vector3(0, 0.86, -0.04), "torso": Vector3(-20, 0, 0), "head": Vector3(8, 0, 0),
		"shoulder_r": Vector3(100, 0, 16), "elbow_r": Vector3(6, 0, 0), "shoulder_l": Vector3(100, 0, -16), "elbow_l": Vector3(6, 0, 0),
		"leg_l": Vector3(30, 0, -4), "knee_l": Vector3(-32, 0, 0), "leg_r": Vector3(-18, 0, 4), "knee_r": Vector3(-10, 0, 0), "foot_r": Vector3(22, 0, 0)})],
		[0.3, with(STAND, {"hips@pos": Vector3(0, 0.88, -0.02), "torso": Vector3(-12, 0, 0), "shoulder_r": Vector3(76, 0, 14), "elbow_r": Vector3(14, 0, 0),
		"shoulder_l": Vector3(76, 0, -14), "elbow_l": Vector3(14, 0, 0), "leg_l": Vector3(24, 0, -4), "knee_l": Vector3(-26, 0, 0), "leg_r": Vector3(-12, 0, 4)})],
		[0.45, STAND]], STAND)
	# A treasure held up (OoT's get-item pose): a little dip, then both hands
	# thrust high overhead, chin up, feet set.
	var held := with(STAND, {"hips@pos": Vector3(0, 0.93, 0), "torso": Vector3(8, 0, 0), "head": Vector3(14, 0, 0),
		"shoulder_r": Vector3(168, 0, 16), "elbow_r": Vector3(22, 0, 0), "hand_r": Vector3(-10, 0, 0),
		"shoulder_l": Vector3(168, 0, -16), "elbow_l": Vector3(22, 0, 0),
		"leg_r": Vector3(0, 0, 8), "leg_l": Vector3(0, 0, -8)})
	clip("item_get", 0.35, [[0.0, with(STAND, {"hips@pos": Vector3(0, 0.88, 0), "torso": Vector3(-6, 0, 0),
		"shoulder_r": Vector3(40, 0, 20), "elbow_r": Vector3(80, 0, 0), "shoulder_l": Vector3(40, 0, -20), "elbow_l": Vector3(80, 0, 0)})],
		[0.2, with(held, {"hips@pos": Vector3(0, 0.95, 0), "shoulder_r": Vector3(176, 0, 18), "shoulder_l": Vector3(176, 0, -18)})], [0.35, held]], STAND)
	# A thing tossed underarm (the old boomerang throw, kept for scenes).
	clip("throw", 0.4, [[0.0, STAND], [0.12, with(STAND, {"torso": Vector3(-4, 35, 0), "shoulder_r": Vector3(70, 0, 70), "elbow_r": Vector3(100, 0, 0)})],
		[0.22, with(STAND, {"torso": Vector3(-8, -30, 0), "shoulder_r": Vector3(80, 0, 20), "elbow_r": Vector3(10, 0, 0),
		"leg_r": Vector3(-12, 0, 3), "leg_l": Vector3(14, 0, -3)})], [0.4, STAND]], STAND)
	# The knighting: down on his right knee, head bowed, breathing.
	var kneel := with(STAND, {"hips@pos": Vector3(0, 0.5, 0.08), "torso": Vector3(-8, 0, 0), "head": Vector3(28, 0, 0),
		"leg_l": Vector3(85, 0, -4), "knee_l": Vector3(-90, 0, 0), "foot_l": Vector3(5, 0, 0),
		"leg_r": Vector3(-10, 0, 4), "knee_r": Vector3(-95, 0, 0), "foot_r": Vector3(40, 0, 0),
		"shoulder_l": Vector3(40, 0, -10), "elbow_l": Vector3(50, 0, 0), "shoulder_r": Vector3(5, 0, 10), "elbow_r": Vector3(20, 0, 0)})
	clip("kneel", 1.6, [[0.0, kneel], [0.8, with(kneel, {"hips@pos": Vector3(0, 0.495, 0.08), "torso": Vector3(-6, 0, 0), "head": Vector3(30, 0, 0)})]], STAND, true)
	# Dragging a great stone (the Questlord's Gauntlets): crouched, both hands
	# on it at arm's length, heaving back with each step.
	var pk: Array = []
	for i in 4:
		var a := i % 2 == 0
		pk.append([i * 0.2, with(STAND, {"hips@pos": Vector3(0, 0.74 if a else 0.71, 0.06 if a else 0.09), "torso": Vector3(-16 if a else -10, 0, 0), "head": Vector3(10, 0, 0),
			"shoulder_r": Vector3(78 if a else 72, 0, 10), "elbow_r": Vector3(12, 0, 0), "hand_r": Vector3(-20, 0, 0),
			"shoulder_l": Vector3(78 if a else 72, 0, -10), "elbow_l": Vector3(12, 0, 0),
			"leg_r": Vector3([50, 20, -10, 30][i], 0, 6), "knee_r": Vector3([-80, -50, -30, -70][i], 0, 0), "foot_r": Vector3(22, 0, 0),
			"leg_l": Vector3([-10, 30, 50, 20][i], 0, -6), "knee_l": Vector3([-30, -70, -80, -50][i], 0, 0), "foot_l": Vector3(22, 0, 0)})])
	clip("pull", 0.8, pk, STAND, true)
	# Asleep on his back (the model along its +Z; turned to fit the bed),
	# breathing slowly, head rolled aside.
	var lie := with(STAND, {"hips@pos": Vector3(0, 0.13, 0), "hips": Vector3(88, 0, 0), "head": Vector3(4, 18, 0),
		"shoulder_r": Vector3(8, 0, 8), "elbow_r": Vector3(20, 0, 0), "shoulder_l": Vector3(30, 0, -10), "elbow_l": Vector3(70, 0, 0),
		"leg_r": Vector3(0, 0, 3), "leg_l": Vector3(2, 0, -4), "knee_r": Vector3(-4, 0, 0), "knee_l": Vector3(-10, 0, 0),
		"foot_r": Vector3(30, 0, 0), "foot_l": Vector3(30, 0, 0)})
	clip("sleep", 3.0, [[0.0, lie], [1.5, with(lie, {"torso": Vector3(-3, 0, 0), "head": Vector3(2, 20, 0), "shoulder_l": Vector3(31, 0, -10)})]], STAND, true)
	# Waking: sitting up, a stretch with a yawn, rubbing his eyes, a scratch
	# of the head.
	var sit := with(STAND, {"hips@pos": Vector3(0, 0.12, 0.05), "hips": Vector3(2, 0, 0), "torso": Vector3(8, 0, 0), "head": Vector3(-6, 0, 0),
		"leg_r": Vector3(86, 0, 4), "leg_l": Vector3(84, 0, -4), "knee_r": Vector3(-6, 0, 0), "knee_l": Vector3(-12, 0, 0), "foot_r": Vector3(30, 0, 0), "foot_l": Vector3(30, 0, 0),
		"shoulder_r": Vector3(20, 0, 12), "elbow_r": Vector3(20, 0, 0), "shoulder_l": Vector3(20, 0, -12), "elbow_l": Vector3(20, 0, 0)})
	clip("wake", 3.0, [[0.0, lie], [0.7, sit],
		[1.2, with(sit, {"torso": Vector3(-12, 0, 0), "head": Vector3(24, 0, 0), "shoulder_r": Vector3(165, 0, 18), "shoulder_l": Vector3(165, 0, -18)})],
		[1.7, with(sit, {"torso": Vector3(-14, 0, 0), "head": Vector3(26, 0, 0), "shoulder_r": Vector3(170, 0, 22), "shoulder_l": Vector3(170, 0, -22)})],
		[2.2, with(sit, {"torso": Vector3(6, 0, 0), "head": Vector3(-12, 0, 0), "shoulder_r": Vector3(60, 25, 0), "elbow_r": Vector3(130, 0, 0), "shoulder_l": Vector3(25, 0, -12)})],
		[2.6, with(sit, {"torso": Vector3(4, 0, 0), "head": Vector3(-4, -10, 0), "shoulder_r": Vector3(150, 0, 30), "elbow_r": Vector3(120, 0, 0)})],
		[3.0, with(sit, {"torso": Vector3(4, 0, 0), "head": Vector3(-4, -10, 0), "shoulder_r": Vector3(25, 0, 12), "elbow_r": Vector3(30, 0, 0)})]], STAND)
