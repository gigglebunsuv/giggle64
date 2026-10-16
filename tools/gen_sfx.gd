extends RefCounted
## Every sound effect, footstep and ambience loop in res://assets/audio/,
## synthesised from physical models instead of chip-tune waves:
## - impacts are noise bursts ringing resonator banks tuned like wood, stone,
##   metal, glass or pottery (modal synthesis);
## - air (swings, whooshes, wind, fire, water) is shaped and filtered noise;
## - strings (the bow) are Karplus-Strong plucks;
## - voices (growls, roars, croaks, cries, a neigh, a laugh) are a pulsing
##   glottal source through vowel formants, with jitter and breath;
## - jingles are a plucked harp, a soft brass pad and bells;
## - a small reverb (Freeverb-style combs and allpasses) adds room.
## Every file is then leveled: its loudest 400 ms window, K-weighted as in
## ITU-R BS.1770 (a 38 Hz high-pass and a +4 dB shelf above 1.7 kHz), is
## brought to TARGET_LUFS plus its MIX trim (loops are leveled by their
## whole length), with a soft limiter keeping peaks under PEAK. The trims are
## the mix: small, frequent sounds (cursor ticks, footsteps, pickups) sit
## under the big moments, so nothing everyday is as loud as an explosion.
## Replace any .wav in assets/audio/ with a recording of the same name to
## swap it.

const AUDIO_DIR := "res://assets/audio/"
const SR := 32000
## Ambience loops are filtered noise and birdsong: a lower rate keeps them small.
const AMB_SR := 22050
const TARGET_LUFS := -17.0
const PEAK := 0.89
const LOOP := 14.0
## The mix: dB added to TARGET_LUFS per sound (exact name first, then the
## longest matching prefix). Everyday and repeated sounds sit lower.
const MIX := {
	"step_": -6.0, "step_stone_": -9.0, "step_ice_": -8.0, "step_wood_": -7.0, "step_wet_": -8.0,
	"ladder_step": -7.0, "climb": -4.0, "land": -4.0, "jump": -5.0, "swim_stroke": -4.0, "ledge_grab": -4.0,
	"menu_move": -6.0, "menu_select": -3.0, "msg_next": -7.0, "msg_open": -5.0, "msg_close": -5.0, "error": -3.0,
	"rupee_tick": -8.0, "rupee": -3.0, "rupee_big": -2.0, "item_pop": -4.0, "pickup": -2.0, "heart": -3.0,
	"camera_in": -5.0, "camera_out": -5.0, "light_hum": -5.0, "low_health": -4.0,
	"grass_cut": -3.0, "bush_cut": -3.0, "lift_plant": -3.0, "lift_pot": -3.0, "throw": -3.0,
	"sword_swing": -2.0, "bow_draw": -3.0, "bomb_fuse": -5.0, "boomerang_spin": -6.0, "torch_light": -3.0,
	"bottle_": -2.0, "fairy_loop": -9.0, "owl_hoot": -6.0, "rooster": -3.0, "night_howl": -2.0,
	"magic_cast": -2.0, "nut_pop": -2.0, "lens_on": -3.0, "magic_refill": -3.0, "ice_freeze": -2.0,
	"cluck": -6.0, "cup_slide": -6.0, "cup_lift": -5.0, "shiver": -5.0, "ice_shatter": -1.0, "rooster_angry": -1.0, "serpent_roar": 0.0,
	"bomb_explode": 1.0, "boss_roar": 1.0, "boss_die": 1.0, "quake_rumble": 1.0,
}
var rng := RandomNumberGenerator.new()
var _sr := SR
## Loudness of each file written (name -> LUFS before leveling), for checks.
var report := {}


func run() -> void:
	rng.seed = 6464
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AUDIO_DIR))
	_footsteps()
	_ui()
	_combat()
	_items()
	_creatures()
	_world()
	_horse()
	_story()
	_beta()
	_fells()
	_war()
	_ch5()
	_sr = AMB_SR
	_ambiences()
	_sr = SR
	print("gen_sfx: wrote %d sounds" % report.size())


# =============================================================================
# DSP toolkit
# =============================================================================

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(maxi(1, int(seconds * _sr)))
	return b


func _n() -> float:
	return rng.randf_range(-1.0, 1.0)


## RBJ biquad (Audio EQ Cookbook). Kinds: lp, hp, bp, peak, hshelf, lshelf.
class Biquad:
	var b0 := 1.0
	var b1 := 0.0
	var b2 := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var sr := 32000.0

	func _init(rate: float) -> void:
		sr = rate

	func setup(kind: String, freq: float, q := 0.707, gain_db := 0.0) -> Biquad:
		var f := clampf(freq, 10.0, sr * 0.45)
		var w := TAU * f / sr
		var cw := cos(w)
		var sw := sin(w)
		var alpha := sw / (2.0 * maxf(q, 0.05))
		var A := pow(10.0, gain_db / 40.0)
		var a0 := 1.0
		match kind:
			"lp":
				b0 = (1.0 - cw) * 0.5; b1 = 1.0 - cw; b2 = (1.0 - cw) * 0.5
				a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
			"hp":
				b0 = (1.0 + cw) * 0.5; b1 = -(1.0 + cw); b2 = (1.0 + cw) * 0.5
				a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
			"bp":
				b0 = alpha; b1 = 0.0; b2 = -alpha
				a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
			"peak":
				b0 = 1.0 + alpha * A; b1 = -2.0 * cw; b2 = 1.0 - alpha * A
				a0 = 1.0 + alpha / A; a1 = -2.0 * cw; a2 = 1.0 - alpha / A
			"hshelf":
				var sq := 2.0 * sqrt(A) * alpha
				b0 = A * ((A + 1.0) + (A - 1.0) * cw + sq)
				b1 = -2.0 * A * ((A - 1.0) + (A + 1.0) * cw)
				b2 = A * ((A + 1.0) + (A - 1.0) * cw - sq)
				a0 = (A + 1.0) - (A - 1.0) * cw + sq
				a1 = 2.0 * ((A - 1.0) - (A + 1.0) * cw)
				a2 = (A + 1.0) - (A - 1.0) * cw - sq
			"lshelf":
				var sq2 := 2.0 * sqrt(A) * alpha
				b0 = A * ((A + 1.0) - (A - 1.0) * cw + sq2)
				b1 = 2.0 * A * ((A - 1.0) - (A + 1.0) * cw)
				b2 = A * ((A + 1.0) - (A - 1.0) * cw - sq2)
				a0 = (A + 1.0) + (A - 1.0) * cw + sq2
				a1 = -2.0 * ((A - 1.0) + (A + 1.0) * cw)
				a2 = (A + 1.0) + (A - 1.0) * cw - sq2
		b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
		return self

	func tick(x: float) -> float:
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		return y


func _bq(kind: String, freq: float, q := 0.707, gain := 0.0) -> Biquad:
	return Biquad.new(_sr).setup(kind, freq, q, gain)


## Filters a whole buffer in place.
func _filter(b: PackedFloat32Array, kind: String, freq: float, q := 0.707, gain := 0.0) -> PackedFloat32Array:
	var f := _bq(kind, freq, q, gain)
	for i in b.size():
		b[i] = f.tick(b[i])
	return b


## Filters with a center frequency that moves along `curve` (Callable t->Hz).
func _sweep(b: PackedFloat32Array, kind: String, curve: Callable, q := 1.0) -> PackedFloat32Array:
	var f := Biquad.new(_sr)
	for i in b.size():
		if i % 32 == 0:
			var hz: float = curve.call(float(i) / b.size())
			var y1 := f.y1
			var y2 := f.y2
			var x1 := f.x1
			var x2 := f.x2
			f.setup(kind, hz, q)
			f.y1 = y1; f.y2 = y2; f.x1 = x1; f.x2 = x2
		b[i] = f.tick(b[i])
	return b


func _white(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for i in b.size():
		b[i] = _n()
	return b


## Pink noise (Paul Kellet's economy filter).
func _pink(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	for i in b.size():
		var w := _n()
		b0 = 0.99765 * b0 + w * 0.0990460
		b1 = 0.96300 * b1 + w * 0.2965164
		b2 = 0.57000 * b2 + w * 1.0526913
		b[i] = (b0 + b1 + b2 + w * 0.1848) * 0.2
	return b


## Brown (red) noise.
func _brown(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var y := 0.0
	for i in b.size():
		y = clampf(y * 0.998 + _n() * 0.04, -1.0, 1.0)
		b[i] = y
	return b


## Shapes `b` by an envelope given as [[t, level], ...] (t in seconds,
## linear between points, held after the last).
func _env(b: PackedFloat32Array, pts: Array) -> PackedFloat32Array:
	var j := 0
	for i in b.size():
		var t := float(i) / _sr
		while j < pts.size() - 2 and t > float(pts[j + 1][0]):
			j += 1
		var a: Array = pts[j]
		var c: Array = pts[mini(j + 1, pts.size() - 1)]
		var span := float(c[0]) - float(a[0])
		var k := clampf((t - float(a[0])) / span, 0.0, 1.0) if span > 0.0 else 1.0
		if t > float(pts.back()[0]):
			k = 1.0
			b[i] *= float(pts.back()[1])
			continue
		b[i] *= lerpf(float(a[1]), float(c[1]), k)
	return b


## Attack then exponential decay (time constant `tau`).
func _decay(b: PackedFloat32Array, attack: float, tau: float, delay := 0.0) -> PackedFloat32Array:
	for i in b.size():
		var t := float(i) / _sr - delay
		if t < 0.0:
			b[i] = 0.0
		elif t < attack:
			b[i] *= t / maxf(attack, 1e-5)
		else:
			b[i] *= exp(-(t - attack) / tau)
	return b


func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, at := 0.0, gain := 1.0) -> PackedFloat32Array:
	var o := int(at * _sr)
	for i in src.size():
		var j := o + i
		if j >= 0 and j < dst.size():
			dst[j] += src[i] * gain
	return dst


func _gain(b: PackedFloat32Array, g: float) -> PackedFloat32Array:
	for i in b.size():
		b[i] *= g
	return b


## Soft saturation (tanh) for weight and warmth.
func _drive(b: PackedFloat32Array, amount: float) -> PackedFloat32Array:
	var norm := tanh(amount)
	for i in b.size():
		b[i] = tanh(b[i] * amount) / norm
	return b


func _peak_of(b: PackedFloat32Array) -> float:
	var m := 0.0
	for v in b:
		m = maxf(m, absf(v))
	return m


func _norm(b: PackedFloat32Array, peak := 1.0) -> PackedFloat32Array:
	var m := _peak_of(b)
	return _gain(b, peak / m) if m > 0.0 else b


## A bank of decaying sine modes: [freq Hz, decay s, amplitude] each, struck
## at t = 0 (modal synthesis of a solid body).
func _modes(seconds: float, modes: Array, jitter := 0.0) -> PackedFloat32Array:
	var b := _buf(seconds)
	for m in modes:
		var f: float = float(m[0]) * (1.0 + rng.randf_range(-jitter, jitter))
		var tau: float = m[1]
		var amp: float = m[2]
		var ph := rng.randf() * TAU
		var w := TAU * f / _sr
		for i in b.size():
			var t := float(i) / _sr
			var e := exp(-t / tau)
			if e < 0.0005:
				break
			b[i] += sin(ph + w * i) * amp * e
	return b


## A noise burst `exc_len` long ringing a bank of resonators [freq, q, gain]:
## wood, stone, metal and pottery hits.
func _strike(seconds: float, exc_len: float, res: Array, exc_lp := 6000.0, raw := 0.15) -> PackedFloat32Array:
	var exc := _white(seconds)
	_decay(exc, 0.0005, exc_len)
	_filter(exc, "lp", exc_lp)
	var b := _buf(seconds)
	for r in res:
		var f := _bq("bp", float(r[0]), float(r[1]))
		var g: float = r[2]
		for i in b.size():
			b[i] += f.tick(exc[i]) * g
	for i in b.size():
		b[i] += exc[i] * raw
	return b


## Karplus-Strong plucked string at `freq`, `damp` 0..1 (higher = brighter).
func _pluck(seconds: float, freq: float, damp := 0.5, decay := 0.996) -> PackedFloat32Array:
	var b := _buf(seconds)
	var n := maxi(2, int(_sr / freq))
	var line := PackedFloat32Array()
	line.resize(n)
	for i in n:
		line[i] = _n()
	var idx := 0
	var last := 0.0
	for i in b.size():
		var cur := line[idx]
		var nxt := line[(idx + 1) % n]
		var v := (cur * (0.5 + damp * 0.5) + nxt * (0.5 - damp * 0.5)) * decay
		line[idx] = v
		b[i] = cur
		last = v
		idx = (idx + 1) % n
	return b


## A voice: a glottal pulse train at `f0` (Callable t->Hz over 0..1 of the
## length) through vowel formants [[Hz, bandwidth Q, gain], ...], with pitch
## jitter, roughness (subharmonic growl) and breath noise.
func _voice(seconds: float, f0: Callable, formants: Array, rough := 0.0, breath := 0.15, jitter := 0.02) -> PackedFloat32Array:
	var src := _buf(seconds)
	var ph := 0.0
	var sub := 0.0
	var jit := 0.0
	var bn := 0.0
	for i in src.size():
		var t := float(i) / src.size()
		if i % 64 == 0:
			jit = lerpf(jit, rng.randf_range(-1.0, 1.0) * jitter, 0.3)
		var f: float = float(f0.call(t)) * (1.0 + jit)
		ph += f / _sr
		if ph >= 1.0:
			ph -= 1.0
			sub = -sub if rng.randf() < 0.85 else sub
			if sub == 0.0:
				sub = 1.0
		# Rosenberg-like pulse: a smooth rise and a quick fall each period.
		var g := 0.0
		if ph < 0.4:
			g = 0.5 * (1.0 - cos(PI * ph / 0.4))
		elif ph < 0.56:
			g = cos(PI * (ph - 0.4) / 0.32)
		# Breath: soft, low-passed noise riding on the pulse (the airflow).
		bn = bn * 0.7 + _n() * 0.3
		src[i] = (g - 0.35) * (1.0 + rough * sub * 0.8) * 2.0 + bn * breath * (0.6 + g)
	var out := _buf(seconds)
	for fm in formants:
		var bp := _bq("bp", float(fm[0]), float(fm[1]))
		var gg: float = fm[2]
		for i in out.size():
			out[i] += bp.tick(src[i]) * gg
	return out


## Vowel formants (adult, roughly): a, e, i, o, u, and a growl's open "ah".
const VOWELS := {
	"a": [[750, 6.0, 1.0], [1200, 8.0, 0.6], [2600, 10.0, 0.25]],
	"e": [[450, 6.0, 1.0], [1900, 10.0, 0.5], [2600, 10.0, 0.3]],
	"i": [[300, 6.0, 1.0], [2300, 12.0, 0.4], [3000, 12.0, 0.3]],
	"o": [[480, 6.0, 1.0], [800, 8.0, 0.6], [2500, 10.0, 0.15]],
	"u": [[320, 6.0, 1.0], [700, 8.0, 0.4], [2400, 10.0, 0.1]],
	"growl": [[380, 3.0, 1.0], [900, 4.0, 0.7], [1900, 5.0, 0.35]],
}


## Freeverb-style reverb: 4 parallel damped combs and 2 allpasses, mixed in.
func _reverb(b: PackedFloat32Array, wet: float, size := 0.8, damp := 0.4, tail := 0.0) -> PackedFloat32Array:
	if tail > 0.0:
		var ext := b.size() + int(tail * _sr)
		b.resize(ext)
	var scale := float(_sr) / 44100.0
	var comb_len := [1116, 1188, 1277, 1356]
	var ap_len := [556, 441]
	var combs: Array = []
	for L in comb_len:
		var a := PackedFloat32Array()
		a.resize(maxi(8, int(L * scale * (0.6 + size * 0.5))))
		combs.append(a)
	var aps: Array = []
	for L in ap_len:
		var a := PackedFloat32Array()
		a.resize(maxi(8, int(L * scale)))
		aps.append(a)
	var ci := [0, 0, 0, 0]
	var cs := [0.0, 0.0, 0.0, 0.0]
	var ai := [0, 0]
	var fb := 0.7 + size * 0.26
	var out := PackedFloat32Array()
	out.resize(b.size())
	for i in b.size():
		var x := b[i] * 0.25
		var acc := 0.0
		for c in 4:
			var buf: PackedFloat32Array = combs[c]
			var idx: int = ci[c]
			var y := buf[idx]
			cs[c] = y * (1.0 - damp) + float(cs[c]) * damp
			buf[idx] = x + float(cs[c]) * fb
			combs[c] = buf
			ci[c] = (idx + 1) % buf.size()
			acc += y
		for a in 2:
			var abuf: PackedFloat32Array = aps[a]
			var aidx: int = ai[a]
			var bo := abuf[aidx]
			abuf[aidx] = acc + bo * 0.5
			aps[a] = abuf
			ai[a] = (aidx + 1) % abuf.size()
			acc = bo - acc
		out[i] = b[i] + acc * wet
	return out


## A falling or rising tone (sine, with optional extra harmonics).
func _chirp(seconds: float, f0: float, f1: float, harmonics := [1.0], curve := 1.0) -> PackedFloat32Array:
	var b := _buf(seconds)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / b.size()
		var f := lerpf(f0, f1, pow(t, curve))
		ph += f / _sr
		var v := 0.0
		for h in harmonics.size():
			v += sin(TAU * ph * (h + 1)) * float(harmonics[h])
		b[i] = v
	return b


## Random short clicks (crackle, grit, bone rattles): `rate` a second,
## each a resonant tick at a random pitch between `lo` and `hi` Hz.
func _grains(seconds: float, rate: float, lo: float, hi: float, tick := 0.004, q := 4.0) -> PackedFloat32Array:
	var b := _buf(seconds)
	var n := int(seconds * rate)
	for k in n:
		var at := rng.randf() * seconds
		var g := _strike(tick * 6.0, tick, [[rng.randf_range(lo, hi), q, 1.0]], 9000.0, 0.3)
		_mix(b, g, at, rng.randf_range(0.3, 1.0))
	return b


## A bell (a struck bar/bell's inharmonic partials) at `f`.
func _bell(f: float, seconds: float, bright := 1.0) -> PackedFloat32Array:
	return _modes(seconds, [[f, seconds * 0.5, 1.0], [f * 2.0, seconds * 0.35, 0.5 * bright], [f * 2.76, seconds * 0.22, 0.4 * bright],
		[f * 5.4, seconds * 0.12, 0.25 * bright], [f * 8.93, seconds * 0.06, 0.12 * bright]], 0.002)


## A note of the jingles: a plucked harp string with a bell-like edge.
func _harp(f: float, seconds: float) -> PackedFloat32Array:
	var b := _pluck(seconds, f, 0.35, 0.9985)
	_mix(b, _gain(_bell(f * 2.0, minf(seconds, 1.2), 0.5), 0.12))
	return _filter(b, "lp", 6000.0)


## A soft brass/organ pad note: a few harmonics with a slow swell.
func _pad(f: float, seconds: float, swell := 0.06) -> PackedFloat32Array:
	var b := _buf(seconds)
	var ph := rng.randf()
	for i in b.size():
		var t := float(i) / _sr
		ph += f * (1.0 + 0.004 * sin(TAU * 5.0 * t)) / _sr
		b[i] = sin(TAU * ph) + 0.5 * sin(TAU * ph * 2.0) + 0.3 * sin(TAU * ph * 3.0) + 0.15 * sin(TAU * ph * 4.0) + 0.08 * sin(TAU * ph * 5.0)
	_env(b, [[0.0, 0.0], [swell, 1.0], [seconds - 0.12, 0.85], [seconds, 0.0]])
	return _filter(b, "lp", 2800.0)


## A jingle: [[midi note, beat length], ...] on harp with a brass pad under
## the long notes and a sparkle on the last.
func _jingle(notes: Array, beat: float, pad := true, last_ring := 1.6) -> PackedFloat32Array:
	var total := last_ring
	for n in notes:
		total += float(n[1]) * beat
	var b := _buf(total + 0.4)
	var t := 0.0
	for i in notes.size():
		var midi: float = notes[i][0]
		var f := 440.0 * pow(2.0, (midi - 69.0) / 12.0)
		var d: float = float(notes[i][1]) * beat
		var last := i == notes.size() - 1
		var ring := d + (last_ring if last else 0.25)
		_mix(b, _harp(f, ring + 0.3), t, 0.8)
		if pad and (d >= beat * 1.5 or last):
			_mix(b, _pad(f * 0.5, ring, 0.05), t, 0.35)
			_mix(b, _pad(f, ring, 0.05), t, 0.18)
		if last:
			_mix(b, _gain(_bell(f * 2.0, 1.8), 0.35), t)
		t += d
	return _reverb(b, 0.35, 0.7, 0.3, 0.6)


# --- Leveling and saving -----------------------------------------------------

## K-weighted loudness (LUFS) of `b`: the loudest 400 ms window, or (loops)
## the whole thing.
func _loudness(b: PackedFloat32Array, integrated := false) -> float:
	var hp := _bq("hp", 38.0, 0.5)
	var sh := _bq("hshelf", 1681.0, 0.707, 4.0)
	var sq := PackedFloat32Array()
	sq.resize(b.size())
	for i in b.size():
		var y := sh.tick(hp.tick(b[i]))
		sq[i] = y * y
	if integrated:
		var total := 0.0
		for v in sq:
			total += v
		return -0.691 + 10.0 * log(maxf(total / maxf(sq.size(), 1), 1e-12)) / log(10.0)
	var win := int(0.4 * _sr)
	var hop := int(0.1 * _sr)
	if sq.size() <= win:
		var total2 := 0.0
		for v in sq:
			total2 += v
		return -0.691 + 10.0 * log(maxf(total2 / win, 1e-12)) / log(10.0)
	var best := 0.0
	var running := 0.0
	for i in win:
		running += sq[i]
	best = running
	var start := 0
	while start + win + hop <= sq.size():
		for i in hop:
			running += sq[start + win + i] - sq[start + i]
		start += hop
		best = maxf(best, running)
	return -0.691 + 10.0 * log(maxf(best / win, 1e-12)) / log(10.0)


## A sound's MIX trim in dB (exact name, else the longest matching prefix).
static func mix_trim(sfx_name: String) -> float:
	if MIX.has(sfx_name):
		return MIX[sfx_name]
	var best := ""
	for k: String in MIX:
		if k.ends_with("_") and sfx_name.begins_with(k) and k.length() > best.length():
			best = k
	return MIX[best] if best != "" else 0.0


## Brings `b` to TARGET_LUFS + `trim`, softly limiting anything over PEAK.
func _level(b: PackedFloat32Array, integrated := false, trim := 0.0) -> PackedFloat32Array:
	var lufs := _loudness(b, integrated)
	var g := pow(10.0, (TARGET_LUFS + trim - lufs) / 20.0)
	for i in b.size():
		var v := b[i] * g
		var a := absf(v)
		if a > PEAK * 0.8:
			# Soft knee from 80% of the ceiling up to it.
			var over := (a - PEAK * 0.8) / (PEAK * 0.2)
			a = PEAK * 0.8 + PEAK * 0.2 * tanh(over)
			v = signf(v) * a
		b[i] = v
	return b


## A short fade at both ends (no clicks), then leveled and saved as 16-bit mono.
func _save(sfx_name: String, b: PackedFloat32Array, loop := false) -> void:
	if not loop:
		var f := mini(int(0.004 * _sr), b.size() / 4)
		for i in f:
			b[i] *= float(i) / f
		var tail := mini(int(0.03 * _sr), b.size() / 3)
		for i in tail:
			b[b.size() - 1 - i] *= float(i) / tail
	report[sfx_name] = _loudness(b, loop)
	_level(b, loop, mix_trim(sfx_name))
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = _sr
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = b.size()
	var err := s.save_to_wav(AUDIO_DIR + sfx_name + ".wav")
	if err != OK:
		push_error("gen_sfx: failed to save %s: %s" % [sfx_name, err])


## Makes a buffer loop seamlessly: the last `xfade` seconds are blended
## (equal power) into the start, and cut off.
func _seamless(b: PackedFloat32Array, xfade := 1.0) -> PackedFloat32Array:
	var x := int(xfade * _sr)
	var n := b.size() - x
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = b[i]
	for i in x:
		var k := float(i) / x * PI * 0.5
		out[i] = b[n + i] * cos(k) + b[i] * sin(k)
	return out


# =============================================================================
# Footsteps (one pair of takes per surface)
# =============================================================================

func _footsteps() -> void:
	for take in 2:
		rng.seed = 900 + take * 31
		var p := 1.0 + (take - 0.5) * 0.08
		_save("step_grass_%d" % take, _step_soft(p, 260.0, 0.35, func() -> PackedFloat32Array: return _rustle(0.14, 2600.0, 0.045, 0.9)))
		_save("step_dirt_%d" % take, _step_soft(p, 220.0, 0.6, func() -> PackedFloat32Array: return _grit(0.12, 1600.0, 0.03)))
		_save("step_sand_%d" % take, _step_soft(p, 180.0, 0.4, func() -> PackedFloat32Array: return _sand(0.2)))
		_save("step_stone_%d" % take, _step_stone(p))
		_save("step_wood_%d" % take, _step_wood(p))
		_save("step_water_%d" % take, _splash(0.32 + take * 0.04, 0.6))
		_save("step_snow_%d" % take, _step_snow(p))
		_save("step_ice_%d" % take, _step_ice(p))
		_save("step_mud_%d" % take, _step_mud(p))
		_save("step_carpet_%d" % take, _step_soft(p, 160.0, 0.2, func() -> PackedFloat32Array: return _rustle(0.08, 900.0, 0.03, 0.3)))
		_save("step_wet_%d" % take, _step_wet(p))
		# Ash (the Batela Fells): a soft, dry, powdery crunch.
		_save("step_ash_%d" % take, _step_soft(p, 190.0, 0.4, func() -> PackedFloat32Array: return _mix(_rustle(0.12, 1300.0, 0.04, 0.5), _grit(0.1, 900.0, 0.025), 0.0, 0.5)))


## A heel thump (low, short) and a texture `layer` after it.
func _step_soft(pitch: float, thump_hz: float, layer_gain: float, layer: Callable) -> PackedFloat32Array:
	var b := _buf(0.3)
	var th := _white(0.12)
	_decay(th, 0.002, 0.018)
	_filter(th, "lp", thump_hz * pitch)
	_filter(th, "lp", thump_hz * pitch * 1.5)
	_mix(b, _gain(th, 3.0))
	_mix(b, _gain(layer.call(), layer_gain), 0.012)
	return _reverb(b, 0.08, 0.3, 0.6)


## Torn, crisp leaves or grass blades: crackly high noise.
func _rustle(seconds: float, cut: float, tau: float, crackle := 0.5) -> PackedFloat32Array:
	var b := _white(seconds)
	_filter(b, "hp", cut)
	_filter(b, "lp", cut * 3.0)
	for i in b.size():
		if rng.randf() < 0.02 * crackle:
			b[i] *= 3.0
	return _decay(b, 0.004, tau)


func _grit(seconds: float, centre: float, tau: float) -> PackedFloat32Array:
	var b := _grains(seconds, 260.0, centre * 0.6, centre * 1.8, 0.002, 3.0)
	_mix(b, _gain(_filter(_white(seconds), "bp", centre, 1.2), 0.25))
	return _decay(b, 0.002, tau)


func _sand(seconds: float) -> PackedFloat32Array:
	var b := _white(seconds)
	_filter(b, "bp", 3200.0, 0.8)
	_env(b, [[0.0, 0.0], [0.02, 1.0], [0.08, 0.6], [seconds, 0.0]])
	return b


## A leather sole on stone: mostly a dull heel thud and a soft scuff of grit.
## (It used to ring like a struck tile at 1.8 and 3.1 kHz, a sharp click that
## cut through everything; now the stone's ring is low, short and quiet.)
func _step_stone(pitch: float) -> PackedFloat32Array:
	var b := _strike(0.2, 0.005, [[520.0 * pitch, 4.0, 0.5], [1150.0 * pitch, 4.0, 0.25], [260.0 * pitch, 3.0, 0.6]], 2400.0, 0.08)
	_decay(b, 0.002, 0.025)
	_gain(b, 0.5)
	var th := _filter(_decay(_white(0.12), 0.002, 0.018), "lp", 260.0)
	_filter(th, "lp", 380.0)
	_mix(b, _gain(th, 2.6))
	var scuff := _grit(0.08, 1500.0, 0.025)
	_filter(scuff, "lp", 3500.0)
	_mix(b, _gain(scuff, 0.18), 0.015)
	_filter(b, "lp", 4500.0)
	return _reverb(b, 0.14, 0.4, 0.6)


## Wet boots: a soft squelch under the step (after swimming).
func _step_wet(pitch: float) -> PackedFloat32Array:
	var b := _white(0.22)
	_sweep(b, "bp", func(t: float) -> float: return lerpf(1400.0, 500.0, t) * pitch, 2.5)
	_env(b, [[0.0, 0.0], [0.02, 1.0], [0.1, 0.4], [0.22, 0.0]])
	for k in 4:
		var bub := _chirp(0.03, rng.randf_range(700.0, 1300.0) * pitch, rng.randf_range(1500.0, 2200.0) * pitch)
		_decay(bub, 0.001, 0.01)
		_mix(b, bub, rng.randf_range(0.02, 0.12), 0.3)
	return b


func _step_wood(pitch: float) -> PackedFloat32Array:
	var b := _strike(0.3, 0.004, [[190.0 * pitch, 8.0, 1.0], [430.0 * pitch, 10.0, 0.6], [980.0 * pitch, 10.0, 0.35], [2100.0 * pitch, 8.0, 0.15]], 5000.0, 0.15)
	_decay(b, 0.001, 0.07)
	return _reverb(b, 0.12, 0.4, 0.5)


func _step_snow(pitch: float) -> PackedFloat32Array:
	var b := _grains(0.2, 900.0, 900.0 * pitch, 3200.0 * pitch, 0.0015, 2.0)
	_env(b, [[0.0, 0.0], [0.015, 1.0], [0.12, 0.5], [0.2, 0.0]])
	var th := _filter(_decay(_white(0.1), 0.002, 0.02), "lp", 220.0)
	_mix(b, _gain(th, 1.5))
	return b


func _step_ice(pitch: float) -> PackedFloat32Array:
	var b := _strike(0.35, 0.002, [[2400.0 * pitch, 30.0, 0.5], [3700.0 * pitch, 40.0, 0.35], [5200.0 * pitch, 40.0, 0.2]], 9000.0, 0.3)
	_decay(b, 0.0005, 0.06)
	var slide := _filter(_white(0.15), "bp", 5000.0, 2.0)
	_env(slide, [[0.0, 0.0], [0.03, 0.15], [0.15, 0.0]])
	_mix(b, slide, 0.01)
	return _reverb(b, 0.2, 0.5, 0.3)


func _step_mud(pitch: float) -> PackedFloat32Array:
	var b := _white(0.32)
	_sweep(b, "bp", func(t: float) -> float: return lerpf(260.0, 900.0, t) * pitch, 3.0)
	_env(b, [[0.0, 0.0], [0.03, 1.0], [0.18, 0.5], [0.32, 0.0]])
	# The suck of the foot coming free: a quick rising "plop".
	_mix(b, _gain(_decay(_chirp(0.08, 300.0 * pitch, 700.0 * pitch), 0.002, 0.03), 0.6), 0.2)
	return b


## Water: a broad splash and bubbles rising after it.
func _splash(seconds: float, size: float) -> PackedFloat32Array:
	var b := _white(seconds)
	_filter(b, "hp", 400.0)
	_filter(b, "lp", 2500.0 + size * 3000.0)
	_env(b, [[0.0, 0.0], [0.01, 1.0], [0.06, 0.55], [seconds, 0.0]])
	for k in int(6 + size * 18):
		var at := rng.randf_range(0.02, seconds * 0.8)
		var f := rng.randf_range(500.0, 1600.0) / (0.6 + size * 0.6)
		var bub := _chirp(rng.randf_range(0.02, 0.06), f, f * 1.8)
		_decay(bub, 0.001, 0.015)
		_mix(b, bub, at, rng.randf_range(0.15, 0.4))
	return _reverb(b, 0.1, 0.4, 0.5)


# =============================================================================
# Menus, text boxes, pickups and jingles
# =============================================================================

func _ui() -> void:
	rng.seed = 7100
	# A soft wooden tick for the cursor (a marimba bar), a two-note chime to decide.
	_save("menu_move", _reverb(_modes(0.12, [[1320.0, 0.03, 1.0], [5280.0, 0.008, 0.3]]), 0.12, 0.3, 0.4, 0.1))
	var sel := _buf(0.5)
	_mix(sel, _bell(1318.5, 0.35, 0.6))
	_mix(sel, _bell(1975.5, 0.4, 0.6), 0.07)
	_save("menu_select", _reverb(sel, 0.2, 0.5, 0.4, 0.2))
	# A muffled double knock: "no".
	var err := _buf(0.3)
	for k in 2:
		var kn := _strike(0.12, 0.004, [[160.0, 5.0, 1.0], [330.0, 6.0, 0.5]], 1500.0, 0.05)
		_decay(kn, 0.001, 0.04)
		_mix(err, kn, k * 0.11)
	_save("error", _drive(err, 1.5))
	# Text boxes: a soft paper whoosh opening, a tick per page, a whoosh closing.
	var op := _white(0.16)
	_sweep(op, "bp", func(t: float) -> float: return lerpf(900.0, 3200.0, t), 2.0)
	_env(op, [[0.0, 0.0], [0.06, 1.0], [0.16, 0.0]])
	_mix(op, _gain(_bell(2637.0, 0.25, 0.3), 0.25), 0.05)
	_save("msg_open", op)
	_save("msg_next", _modes(0.08, [[2093.0, 0.02, 1.0], [4186.0, 0.01, 0.3]]))
	var cl := _white(0.14)
	_sweep(cl, "bp", func(t: float) -> float: return lerpf(2800.0, 800.0, t), 2.0)
	_env(cl, [[0.0, 0.0], [0.03, 1.0], [0.14, 0.0]])
	_save("msg_close", cl)
	# First-person view: a soft lens whir in and out.
	for io in [["camera_in", 600.0, 1800.0], ["camera_out", 1800.0, 600.0]]:
		var cam := _white(0.2)
		_sweep(cam, "bp", func(t: float) -> float: return lerpf(io[1], io[2], t), 4.0)
		_env(cam, [[0.0, 0.0], [0.05, 1.0], [0.2, 0.0]])
		_mix(cam, _gain(_modes(0.05, [[3000.0, 0.01, 1.0]]), 0.3), 0.15)
		_save(io[0], cam)
	# Rupees: crystal chimes (green: two notes; blue/red: three), the counter's tick.
	_save("rupee", _rupee([88, 95]))
	_save("rupee_big", _rupee([84, 88, 96]))
	_save("rupee_tick", _modes(0.05, [[3520.0, 0.012, 1.0], [7040.0, 0.005, 0.3]]))
	# A recovery heart: a warm rising harp arpeggio.
	_save("heart", _jingle([[72, 0.5], [76, 0.5], [79, 0.5], [84, 1.0]], 0.07, false, 0.8))
	_save("pickup", _jingle([[79, 0.5], [84, 0.5], [88, 1.0]], 0.06, false, 0.6))
	var pop := _decay(_chirp(0.08, 400.0, 1200.0, [1.0, 0.3]), 0.001, 0.025)
	_mix(pop, _gain(_bell(2637.0, 0.3, 0.4), 0.3), 0.03)
	_save("item_pop", pop)
	_save("carrot_recover", _jingle([[76, 0.5], [79, 0.5], [83, 1.0]], 0.08, false, 0.6))
	# Jingles (OoT's item get, big item get, secret, heart container).
	_save("fanfare_item", _jingle([[72, 1], [76, 1], [79, 1], [84, 3]], 0.13))
	_save("fanfare_big", _jingle([[67, 1], [72, 1], [76, 1], [79, 2], [77, 1], [81, 1], [84, 5]], 0.14))
	_save("puzzle_solved", _jingle([[86, 1], [89, 1], [93, 1], [91, 1], [96, 1], [100, 4]], 0.085, false, 1.2))
	_save("heart_container", _jingle([[72, 1], [76, 1], [79, 1], [84, 1], [79, 1], [84, 1], [88, 6]], 0.15))
	# The low-health alarm: a soft, rounded double beep.
	var lh := _buf(0.3)
	for k in 2:
		var bp := _chirp(0.08, 880.0, 870.0, [1.0, 0.15])
		_env(bp, [[0.0, 0.0], [0.006, 1.0], [0.05, 0.6], [0.08, 0.0]])
		_mix(lh, bp, k * 0.13)
	_save("low_health", _filter(lh, "lp", 3000.0))
	# Sparkles and the warp.
	var sp := _buf(0.6)
	for k in 9:
		_mix(sp, _bell(rng.randf_range(2000.0, 4200.0), 0.3, 0.4), k * 0.035, 0.4)
	_save("magic_burst", _reverb(sp, 0.3, 0.6, 0.3, 0.3))
	_save("warp", _warp())
	var hum := _buf(0.7)
	for f in [440.0, 660.0, 880.0]:
		var h := _chirp(0.7, f, f, [1.0, 0.2])
		_env(h, [[0.0, 0.0], [0.15, 1.0], [0.5, 0.8], [0.7, 0.0]])
		_mix(hum, h, 0.0, 0.3)
	_save("light_hum", _reverb(hum, 0.25, 0.6, 0.3))
	# Bottles: a glassy swing, the cork going in on a catch, a pour.
	var bsw := _swish(0.25, 700.0, 2200.0, 3.0)
	_mix(bsw, _gain(_bell(2349.3, 0.3, 0.5), 0.15), 0.12)
	_save("bottle_swing", bsw)
	var bc := _buf(0.6)
	_mix(bc, _decay(_chirp(0.06, 500.0, 1400.0, [1.0, 0.3]), 0.001, 0.02))
	_mix(bc, _gain(_bell(1568.0, 0.4, 0.7), 0.5), 0.05)
	_mix(bc, _gain(_bell(2093.0, 0.4, 0.7), 0.4), 0.12)
	_save("bottle_catch", _reverb(bc, 0.2, 0.5, 0.3, 0.2))
	var bp := _white(0.7)
	_sweep(bp, "bp", func(t: float) -> float: return lerpf(500.0, 1400.0, t), 3.0)
	_env(bp, [[0.0, 0.0], [0.1, 1.0], [0.6, 0.7], [0.7, 0.0]])
	for k in 10:
		var gl := _chirp(0.04, rng.randf_range(400.0, 900.0), rng.randf_range(1000.0, 1600.0))
		_decay(gl, 0.001, 0.012)
		_mix(bp, gl, rng.randf_range(0.05, 0.6), 0.4)
	_save("bottle_pour", bp)
	# A fairy: a loop of tiny high bells, and her healing swirl.
	var fl := _buf(LOOP * 0.25)
	for k in 26:
		_mix(fl, _bell(rng.randf_range(3200.0, 5600.0), 0.25, 0.4), rng.randf_range(0.0, LOOP * 0.25 - 0.3), rng.randf_range(0.2, 0.45))
	_save("fairy_loop", _seamless(_reverb(fl, 0.4, 0.6, 0.3), 0.2), true)
	var fh := _buf(1.6)
	for k in 16:
		_mix(fh, _bell(880.0 * pow(2.0, float([0, 4, 7, 12, 16, 19, 24, 28][k % 8]) / 12.0), 0.5, 0.6), k * 0.06, 0.3)
	_save("fairy_heal", _reverb(fh, 0.45, 0.8, 0.3, 0.6))
	# A rest in the hero's bed: a soft lullaby on the harp.
	_save("rest_jingle", _jingle([[64, 1], [67, 1], [71, 2], [69, 1], [67, 1], [64, 3]], 0.22, true, 2.0))


func _rupee(notes: Array) -> PackedFloat32Array:
	var b := _buf(0.6)
	for i in notes.size():
		var f := 440.0 * pow(2.0, (float(notes[i]) - 69.0) / 12.0)
		_mix(b, _bell(f, 0.35, 0.8), i * 0.055, 0.7)
	return _reverb(b, 0.18, 0.5, 0.3, 0.2)


func _warp() -> PackedFloat32Array:
	var b := _white(1.6)
	_sweep(b, "bp", func(t: float) -> float: return lerpf(300.0, 4000.0, t * t), 6.0)
	_env(b, [[0.0, 0.0], [0.4, 0.8], [1.2, 1.0], [1.6, 0.0]])
	for k in 14:
		_mix(b, _bell(lerpf(800.0, 3200.0, k / 14.0), 0.4, 0.5), k * 0.08, 0.25)
	return _reverb(b, 0.35, 0.8, 0.3, 0.6)


# =============================================================================
# Swords, shields, bows and blows
# =============================================================================

## A blade (or anything) cutting the air: band-passed noise whose pitch rises
## and falls with the swing, loudest at its fastest.
func _swish(seconds: float, lo: float, hi: float, q := 2.5) -> PackedFloat32Array:
	var b := _white(seconds)
	_sweep(b, "bp", func(t: float) -> float: return lerpf(lo, hi, sin(t * PI)), q)
	_env(b, [[0.0, 0.0], [seconds * 0.45, 1.0], [seconds, 0.0]])
	return b


## Metal ringing (a shield, armor, an anvil): inharmonic modes.
func _metal(seconds: float, f: float, ring: float) -> PackedFloat32Array:
	var b := _strike(seconds, 0.002, [[f, 30.0, 0.7], [f * 2.31, 40.0, 0.5], [f * 3.89, 50.0, 0.35], [f * 5.73, 60.0, 0.2], [f * 7.1, 60.0, 0.12]], 10000.0, 0.2)
	return _decay(b, 0.0005, ring)


func _thud(seconds: float, hz: float, tau: float) -> PackedFloat32Array:
	var b := _white(seconds)
	_decay(b, 0.001, tau)
	_filter(b, "lp", hz)
	_filter(b, "lp", hz * 1.3)
	_mix(b, _gain(_decay(_chirp(seconds, hz * 0.6, hz * 0.3), 0.001, tau * 1.5), 0.6))
	return b


func _combat() -> void:
	rng.seed = 7300
	_save("sword_swing", _swish(0.2, 700.0, 2600.0))
	_save("heavy_swing", _reverb(_swish(0.45, 260.0, 1100.0, 2.0), 0.1, 0.4, 0.5))
	var hit := _thud(0.25, 180.0, 0.05)
	var slash := _filter(_decay(_white(0.08), 0.001, 0.02), "bp", 2400.0, 1.0)
	_mix(hit, _gain(slash, 1.4))
	_save("sword_hit", _drive(hit, 2.0))
	var blk := _metal(0.6, 640.0, 0.18)
	_mix(blk, _gain(_thud(0.15, 300.0, 0.03), 0.8))
	_save("shield_block", _reverb(blk, 0.15, 0.5, 0.4))
	var clang := _metal(1.0, 380.0, 0.35)
	_mix(clang, _gain(_thud(0.2, 200.0, 0.05), 0.8))
	_save("armor_clang", _reverb(clang, 0.2, 0.6, 0.4))
	_save("wall_hit_hard", _reverb(_mix(_strike(0.3, 0.003, [[900.0, 4.0, 0.8], [2300.0, 6.0, 0.5]], 7000.0, 0.3), _metal(0.4, 1500.0, 0.06), 0.0, 0.35), 0.15, 0.4, 0.5))
	_save("wall_hit_soft", _thud(0.2, 260.0, 0.04))
	# The hero hurt: a short grunt over the blow.
	var ph := _voice(0.28, func(t: float) -> float: return lerpf(190.0, 140.0, t), VOWELS.a, 0.1, 0.25)
	_env(ph, [[0.0, 0.0], [0.02, 1.0], [0.12, 0.7], [0.28, 0.0]])
	_mix(ph, _gain(_thud(0.15, 220.0, 0.03), 0.8))
	_save("player_hurt", ph)
	# Creatures hurt, dying, attacking, noticing.
	var eh := _voice(0.22, func(t: float) -> float: return lerpf(420.0, 300.0, t), VOWELS.e, 0.4, 0.3, 0.05)
	_env(eh, [[0.0, 0.0], [0.015, 1.0], [0.22, 0.0]])
	_mix(eh, _gain(_thud(0.12, 250.0, 0.03), 0.6))
	_save("enemy_hurt", eh)
	var ed := _voice(0.7, func(t: float) -> float: return lerpf(320.0, 120.0, t), VOWELS.o, 0.6, 0.35, 0.06)
	_env(ed, [[0.0, 0.0], [0.03, 1.0], [0.45, 0.5], [0.7, 0.0]])
	var poof := _white(0.5)
	_sweep(poof, "lp", func(t: float) -> float: return lerpf(3000.0, 400.0, t), 0.7)
	_env(poof, [[0.0, 0.0], [0.05, 0.6], [0.5, 0.0]])
	_mix(ed, poof, 0.25)
	_save("enemy_death", _reverb(ed, 0.12, 0.5, 0.4))
	var ea := _voice(0.35, func(t: float) -> float: return lerpf(150.0, 190.0, sin(t * PI)), VOWELS.growl, 0.9, 0.35, 0.08)
	_env(ea, [[0.0, 0.0], [0.05, 1.0], [0.25, 0.8], [0.35, 0.0]])
	_save("enemy_attack", ea)
	var al := _voice(0.18, func(t: float) -> float: return lerpf(380.0, 520.0, t), VOWELS.a, 0.3, 0.2, 0.03)
	_env(al, [[0.0, 0.0], [0.02, 1.0], [0.18, 0.0]])
	_save("enemy_alert", al)
	# Bow: a creaking draw, the string's snap, the shot, and arrows landing.
	var draw := _grains(0.3, 90.0, 300.0, 900.0, 0.003, 6.0)
	var rub := _filter(_white(0.3), "bp", 700.0, 3.0)
	_env(rub, [[0.0, 0.0], [0.25, 0.4], [0.3, 0.0]])
	_mix(draw, rub)
	_save("bow_draw", draw)
	var twang := _pluck(0.3, 110.0, 0.7, 0.99)
	_decay(twang, 0.001, 0.08)
	_save("bow_flick", _filter(twang, "lp", 4000.0))
	for name in ["arrow_shoot", "bow_shoot"]:
		var shot := _pluck(0.4, 98.0 if name == "arrow_shoot" else 140.0, 0.75, 0.99)
		_decay(shot, 0.001, 0.07)
		_mix(shot, _gain(_swish(0.3, 1200.0, 3000.0, 3.0), 0.6), 0.02)
		_save(name, shot)
	var ah := _thud(0.2, 300.0, 0.03)
	_mix(ah, _gain(_filter(_decay(_white(0.05), 0.0005, 0.01), "hp", 2000.0), 0.6))
	_save("arrow_hit", ah)
	var stick := _strike(0.35, 0.003, [[240.0, 10.0, 0.9], [560.0, 10.0, 0.5]], 4000.0, 0.2)
	_decay(stick, 0.001, 0.08)
	# The shaft quivering.
	var quiver := _chirp(0.3, 34.0, 30.0)
	_decay(quiver, 0.001, 0.08)
	for i in quiver.size():
		stick[i] *= 1.0 + 0.5 * quiver[i]
	_save("arrow_stick", stick)
	var tg := _strike(0.3, 0.004, [[180.0, 6.0, 1.0], [410.0, 6.0, 0.5]], 3000.0, 0.3)
	_save("target_hit", _decay(tg, 0.001, 0.06))
	_save("target_bell", _reverb(_bell(1318.0, 1.6), 0.25, 0.6, 0.3, 0.4))
	# The Bun Sword's beam.
	var beam := _swish(0.4, 900.0, 3600.0, 3.0)
	for k in 6:
		_mix(beam, _bell(1800.0 + k * 320.0, 0.25, 0.5), k * 0.04, 0.2)
	_save("sword_beam", _reverb(beam, 0.2, 0.5, 0.3, 0.2))


# =============================================================================
# Items: boomerang, hookshot, bombs, the Bloom Rod
# =============================================================================

func _items() -> void:
	rng.seed = 7500
	_save("boomerang_throw", _swish(0.3, 500.0, 1800.0, 3.0))
	# A seamless whirr: whooshes repeating at the spin rate.
	var spin := _white(1.0)
	_filter(spin, "bp", 900.0, 2.0)
	for i in spin.size():
		var t := float(i) / _sr
		spin[i] *= 0.3 + 0.7 * pow(0.5 + 0.5 * sin(TAU * 12.0 * t), 2.0)
	_save("boomerang_spin", spin, true)
	var catch := _thud(0.15, 400.0, 0.025)
	_mix(catch, _gain(_strike(0.1, 0.002, [[900.0, 6.0, 1.0]], 5000.0, 0.2), 0.4))
	_save("boomerang_catch", catch)
	# The hookshot: a spring's kick and the chain paying out; biting in; glancing off.
	var hf := _metal(0.25, 1200.0, 0.04)
	_mix(hf, _grains(0.4, 70.0, 2500.0, 5000.0, 0.002, 12.0), 0.03, 0.6)
	_mix(hf, _gain(_swish(0.3, 800.0, 2400.0, 3.0), 0.4))
	_save("hookshot_fire", hf)
	var hs := _strike(0.3, 0.003, [[220.0, 8.0, 1.0], [520.0, 8.0, 0.5]], 4000.0, 0.3)
	_decay(hs, 0.001, 0.07)
	_mix(hs, _grains(0.2, 50.0, 2500.0, 4500.0, 0.002, 12.0), 0.02, 0.5)
	_save("hookshot_stick", hs)
	_save("hookshot_reflect", _reverb(_metal(0.5, 2200.0, 0.12), 0.15, 0.4, 0.3))
	# Bombs: the fuse, a bounce, the blast.
	var fuse := _white(0.7)
	_filter(fuse, "hp", 3000.0)
	for i in fuse.size():
		fuse[i] *= 0.4 + (2.5 if rng.randf() < 0.01 else 0.0)
	_mix(fuse, _gain(_grains(0.7, 60.0, 3000.0, 7000.0, 0.001, 3.0), 0.5))
	_env(fuse, [[0.0, 0.0], [0.05, 1.0], [0.6, 0.8], [0.7, 0.0]])
	_save("bomb_fuse", fuse)
	var bb := _strike(0.25, 0.003, [[300.0, 6.0, 1.0], [720.0, 8.0, 0.5], [1500.0, 8.0, 0.25]], 4000.0, 0.2)
	_save("bomb_bounce", _decay(bb, 0.001, 0.05))
	_save("bomb_explode", _explosion(2.2, 1.0))
	# The Bloom Rod: a seed's soft "pthup", and a pod bursting out of the ground.
	var seed := _white(0.15)
	_filter(seed, "bp", 900.0, 1.5)
	_env(seed, [[0.0, 0.0], [0.008, 1.0], [0.15, 0.0]])
	_mix(seed, _gain(_rustle(0.12, 2500.0, 0.04), 0.4), 0.02)
	_save("seed_shoot", seed)
	var grow := _rustle(0.6, 1200.0, 0.3, 1.5)
	_mix(grow, _grains(0.5, 40.0, 120.0, 400.0, 0.008, 8.0), 0.02, 0.7)
	_mix(grow, _gain(_decay(_chirp(0.25, 120.0, 260.0, [1.0, 0.5, 0.25]), 0.02, 0.12), 0.6))
	_mix(grow, _gain(_decay(_chirp(0.06, 250.0, 700.0), 0.001, 0.02), 0.8), 0.32)
	_save("bloom_grow", _reverb(grow, 0.1, 0.4, 0.5))
	_satchel()


## The Satchel update's sounds (1.6.0): the blessings' cast, the mallet's
## blow, a Puff Nut's pop, the Looking Glass, ice forming, the gale's wind, a
## Sun Arrow's burst and a magic jar's refill.
func _satchel() -> void:
	rng.seed = 7700
	# A rising shimmer of bells over a soft swell.
	var cast := _pad(392.0, 1.1, 0.25)
	for k in 7:
		_mix(cast, _bell(lerpf(880.0, 2640.0, k / 7.0), 0.5, 0.7), 0.05 + k * 0.07, 0.3)
	_save("magic_cast", _reverb(_env(cast, [[0.0, 0.0], [0.15, 1.0], [0.9, 0.6], [1.1, 0.0]]), 0.35, 0.7, 0.4, 0.5))
	# The mallet: a heavy thud into the ground, an iron clang and grit.
	var smash := _thud(0.6, 160.0, 0.12)
	_mix(smash, _gain(_metal(0.5, 380.0, 0.09), 0.45))
	_mix(smash, _gain(_grit(0.4, 1800.0, 0.12), 0.5), 0.01)
	_save("mallet_smash", _reverb(_drive(smash, 1.4), 0.12, 0.5, 0.4))
	# A Puff Nut: a dry crack and a hiss of spores, with a bright flash tone.
	var pop := _strike(0.2, 0.002, [[1400.0, 10.0, 1.0], [3100.0, 10.0, 0.5]], 7000.0, 0.4)
	_decay(pop, 0.0005, 0.03)
	var hiss := _white(0.5)
	_filter(hiss, "hp", 2500.0)
	_env(hiss, [[0.0, 0.0], [0.02, 0.7], [0.5, 0.0]])
	_mix(pop, hiss, 0.01, 0.6)
	_mix(pop, _gain(_bell(2093.0, 0.4, 1.0), 0.35), 0.0)
	_save("nut_pop", pop)
	# The Looking Glass raised: a hollow, eerie two-note shimmer.
	var lens := _pad(311.0, 0.8, 0.1)
	_mix(lens, _gain(_pad(466.0, 0.7, 0.1), 0.7), 0.12)
	_mix(lens, _gain(_bell(1244.0, 0.6, 0.6), 0.3), 0.05)
	_save("lens_on", _reverb(lens, 0.4, 0.8, 0.4, 0.4))
	# Ice forming: crackling ticks rising, and a glassy ring.
	var ice := _grains(0.45, 120.0, 2500.0, 7000.0, 0.002, 10.0)
	_env(ice, [[0.0, 0.2], [0.3, 1.0], [0.45, 0.0]])
	_mix(ice, _gain(_bell(2637.0, 0.6, 1.2), 0.4), 0.25)
	_save("ice_freeze", _reverb(ice, 0.2, 0.5, 0.3))
	# The gale: a whoosh of wind that swirls up and away.
	var wind := _white(1.0)
	_sweep(wind, "bp", func(t: float) -> float: return lerpf(300.0, 2400.0, sin(t * PI * 0.5)), 3.0)
	_env(wind, [[0.0, 0.0], [0.3, 1.0], [1.0, 0.0]])
	_save("warp_wind", _reverb(wind, 0.3, 0.7, 0.3, 0.4))
	# A Sun Arrow bursting: a bright chord struck at once.
	var sun := _bell(1046.0, 0.8, 1.2)
	_mix(sun, _bell(1318.0, 0.8, 1.2), 0.0, 0.8)
	_mix(sun, _bell(1568.0, 0.8, 1.2), 0.0, 0.7)
	_mix(sun, _gain(_swish(0.25, 2000.0, 6000.0, 2.0), 0.4))
	_save("sun_arrow", _reverb(sun, 0.3, 0.6, 0.3, 0.3))
	# A magic jar: a quick rising glug of notes.
	_save("magic_refill", _jingle([[79, 0.5], [83, 0.5], [86, 0.5], [91, 1.0]], 0.05, false, 0.6))


## A blast: the shock's low punch, a roaring burst of air, debris pattering,
## and the room answering.
func _explosion(seconds: float, size: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var punch := _chirp(0.6, 110.0 * (1.2 - size * 0.2), 32.0, [1.0, 0.4], 0.6)
	_decay(punch, 0.002, 0.18)
	_mix(b, _gain(punch, 1.2))
	var roar := _brown(seconds)
	_filter(roar, "lp", 900.0)
	_env(roar, [[0.0, 0.0], [0.01, 1.0], [0.3, 0.6], [seconds, 0.0]])
	_mix(b, _gain(roar, 2.5))
	var crack := _white(0.2)
	_decay(crack, 0.0005, 0.03)
	_filter(crack, "lp", 6000.0)
	_mix(b, crack)
	_mix(b, _grains(seconds * 0.7, 40.0, 400.0, 2500.0, 0.004, 4.0), 0.15, 0.3)
	_drive(b, 2.2)
	return _reverb(b, 0.35, 0.8, 0.5, 0.5)


# =============================================================================
# Creatures
# =============================================================================

func _creatures() -> void:
	rng.seed = 7700
	# Keese: a bat's shrill chittering screech.
	var keese := _buf(0.25)
	for k in 3:
		var ch := _chirp(0.06, rng.randf_range(4200.0, 5200.0), rng.randf_range(2600.0, 3200.0), [1.0, 0.3])
		_decay(ch, 0.002, 0.025)
		_mix(keese, ch, k * 0.07)
	_save("keese_cry", keese)
	var rat := _chirp(0.11, 3400.0, 3900.0, [1.0, 0.2])
	for i in rat.size():
		rat[i] *= 0.6 + 0.4 * sin(TAU * 45.0 * float(i) / _sr)
	_env(rat, [[0.0, 0.0], [0.01, 1.0], [0.08, 0.7], [0.11, 0.0]])
	_save("rat_squeak", rat)
	var moan := _voice(1.0, func(t: float) -> float: return 105.0 + 12.0 * sin(t * 6.0), VOWELS.o, 0.5, 0.4, 0.04)
	_env(moan, [[0.0, 0.0], [0.25, 1.0], [0.7, 0.7], [1.0, 0.0]])
	_save("mummy_moan", _reverb(moan, 0.3, 0.7, 0.4, 0.4))
	var shriek := _voice(0.5, func(t: float) -> float: return lerpf(900.0, 380.0, t), VOWELS.i, 0.2, 0.5, 0.03)
	_env(shriek, [[0.0, 0.0], [0.03, 1.0], [0.5, 0.0]])
	_save("shade_shriek", _reverb(shriek, 0.45, 0.8, 0.3, 0.5))
	_save("bone_rattle", _reverb(_grains(0.35, 70.0, 700.0, 2600.0, 0.006, 10.0), 0.1, 0.4, 0.4))
	var snap := _strike(0.15, 0.002, [[1100.0, 4.0, 1.0], [2600.0, 5.0, 0.5]], 8000.0, 0.4)
	_mix(snap, _gain(_thud(0.1, 400.0, 0.02), 0.6))
	_save("snap", _decay(snap, 0.0005, 0.04))
	_save("hop", _thud(0.18, 200.0, 0.04))
	var hs := _thud(0.5, 110.0, 0.12)
	_mix(hs, _gain(_grit(0.2, 1200.0, 0.05), 0.4), 0.02)
	_save("heavy_step", _reverb(hs, 0.15, 0.6, 0.5))
	_save("boss_roar", _roar(1.5, 72.0, 1.0))
	_save("boss_hurt", _roar(0.55, 120.0, 0.6))
	var stomp := _explosion(1.0, 0.4)
	_mix(stomp, _gain(_thud(0.6, 80.0, 0.2), 1.5))
	_save("boss_stomp", stomp)
	var die := _roar(2.4, 90.0, 1.0, -40.0)
	_mix(die, _gain(_explosion(2.4, 0.7), 0.5), 0.4)
	_save("boss_die", die)
	var flap := _buf(0.4)
	for k in 2:
		var f := _white(0.15)
		_filter(f, "lp", 700.0)
		_env(f, [[0.0, 0.0], [0.04, 1.0], [0.15, 0.0]])
		_mix(flap, f, k * 0.18)
	_save("wing_flap", flap)
	var clamp := _strike(0.2, 0.002, [[1250.0, 6.0, 1.0], [2900.0, 8.0, 0.5]], 7000.0, 0.3)
	_save("shell_clamp", _decay(clamp, 0.0005, 0.05))
	var bub := _decay(_chirp(0.12, 280.0, 900.0, [1.0, 0.2], 0.5), 0.002, 0.04)
	_save("bubble_pop", bub)
	var sh := _white(0.8)
	_filter(sh, "bp", 4000.0, 0.7)
	_mix(sh, _gain(_grains(0.8, 300.0, 2000.0, 6000.0, 0.001, 2.0), 0.4))
	_env(sh, [[0.0, 0.0], [0.15, 1.0], [0.6, 0.7], [0.8, 0.0]])
	_save("sand_hiss", sh)
	# The Mire Toad: a great croak, a long inhale, and its tongue's crack.
	var croak := _voice(0.7, func(t: float) -> float: return lerpf(70.0, 55.0, t), [[350, 4.0, 1.0], [700, 5.0, 0.5], [1300, 6.0, 0.2]], 0.8, 0.2, 0.04)
	for i in croak.size():
		var t := float(i) / _sr
		croak[i] *= pow(0.5 + 0.5 * sin(TAU * 18.0 * t), 1.5)
	_env(croak, [[0.0, 0.0], [0.05, 1.0], [0.5, 0.8], [0.7, 0.0]])
	_save("toad_croak", _reverb(croak, 0.2, 0.6, 0.4, 0.3))
	var inhale := _pink(3.0)
	_sweep(inhale, "bp", func(t: float) -> float: return lerpf(300.0, 1400.0, t), 1.8)
	_env(inhale, [[0.0, 0.0], [0.5, 0.6], [2.6, 1.0], [3.0, 0.0]])
	_save("toad_inhale", inhale)
	var whip := _decay(_swish(0.12, 1500.0, 4500.0, 2.0), 0.001, 0.06)
	var crack := _filter(_decay(_white(0.06), 0.0003, 0.008), "hp", 1500.0)
	_mix(whip, _gain(crack, 1.5), 0.09)
	_mix(whip, _gain(_step_mud(1.4), 0.4), 0.1)
	_save("whip_crack", whip)


## A great beast's roar: a rough, low voice with a growling subharmonic,
## breath and the room's echo; `bend` Hz over its length.
func _roar(seconds: float, f0: float, size: float, bend := 15.0) -> PackedFloat32Array:
	var v := _voice(seconds, func(t: float) -> float: return f0 + bend * sin(t * PI) - (f0 * 0.25 if t > 0.8 else 0.0) * (t - 0.8) * 5.0,
		VOWELS.growl, 1.4, 0.5, 0.08)
	_env(v, [[0.0, 0.0], [0.08, 1.0], [seconds * 0.7, 0.85], [seconds, 0.0]])
	var low := _brown(seconds)
	_filter(low, "lp", 200.0)
	_env(low, [[0.0, 0.0], [0.1, 1.0], [seconds, 0.0]])
	_mix(v, _gain(low, 1.5 * size))
	_drive(v, 2.0)
	return _reverb(v, 0.3 * size, 0.8, 0.4, 0.6)


# =============================================================================
# The world: plants, pots, doors, chests, water, climbing
# =============================================================================

func _world() -> void:
	rng.seed = 7900
	var gc := _swish(0.1, 1500.0, 3000.0, 3.0)
	_mix(gc, _gain(_rustle(0.16, 2400.0, 0.05), 0.8), 0.02)
	_save("grass_cut", gc)
	var bc := _swish(0.12, 1200.0, 2600.0, 3.0)
	_mix(bc, _gain(_rustle(0.3, 1600.0, 0.09, 1.2), 1.0), 0.02)
	_save("bush_cut", bc)
	var chop := _strike(0.3, 0.003, [[260.0, 6.0, 1.0], [620.0, 6.0, 0.5], [1400.0, 6.0, 0.3]], 6000.0, 0.4)
	_mix(chop, _gain(_grains(0.15, 120.0, 1500.0, 3500.0, 0.002, 5.0), 0.5), 0.02)
	_save("sign_cut", _decay(chop, 0.001, 0.08))
	_save("pot_break", _shatter())
	_save("rock_break", _rock_break())
	_save("chest_open", _creak(0.7, 260.0, 180.0, true))
	var door := _creak(0.6, 320.0, 220.0, false)
	_mix(door, _gain(_thud(0.25, 160.0, 0.06), 0.8), 0.5)
	_save("door_open", door)
	_save("door_unlock", _unlock())
	_save("shutter_close", _slam(0.6, true))
	_save("shutter_open", _slam(0.7, false))
	var sw := _strike(0.25, 0.004, [[400.0, 6.0, 1.0], [950.0, 6.0, 0.4]], 4000.0, 0.3)
	_mix(sw, _gain(_thud(0.2, 140.0, 0.05), 1.0), 0.02)
	_save("switch_press", _reverb(_decay(sw, 0.001, 0.07), 0.15, 0.5, 0.5))
	_save("crystal_hit", _reverb(_bell(1760.0, 1.2), 0.3, 0.6, 0.3, 0.4))
	var tl := _fire_burst(0.7)
	_save("torch_light", tl)
	# Lifting a pot, a rock, a plant (scrape and grab), and throwing.
	var lp := _strike(0.15, 0.003, [[700.0, 5.0, 0.8], [1700.0, 6.0, 0.4]], 5000.0, 0.2)
	_save("lift_pot", _decay(lp, 0.001, 0.05))
	var lr := _filter(_white(0.25), "bp", 900.0, 1.0)
	_mix(lr, _grains(0.25, 120.0, 600.0, 2000.0, 0.003, 4.0), 0.0, 0.6)
	_env(lr, [[0.0, 0.0], [0.03, 1.0], [0.25, 0.0]])
	_save("lift_rock", lr)
	_save("lift_plant", _rustle(0.3, 1400.0, 0.08, 1.4))
	_save("throw", _swish(0.22, 500.0, 1500.0, 2.5))
	# Climbing: cloth and a hand on stone; ladder rungs.
	var cl := _rustle(0.25, 900.0, 0.08, 0.2)
	_mix(cl, _gain(_thud(0.1, 400.0, 0.02), 0.8), 0.1)
	_save("climb", cl)
	var lg := _filter(_decay(_white(0.1), 0.001, 0.015), "bp", 1200.0, 1.0)
	_mix(lg, _gain(_thud(0.1, 300.0, 0.02), 0.8))
	_save("ledge_grab", lg)
	_save("ladder_step", _step_wood(1.3))
	var jp := _swish(0.15, 400.0, 1200.0, 2.0)
	_save("jump", jp)
	_save("land", _thud(0.2, 240.0, 0.04))
	_save("splash_big", _splash(0.9, 1.6))
	var stroke := _white(0.35)
	_filter(stroke, "bp", 900.0, 1.0)
	_env(stroke, [[0.0, 0.0], [0.08, 1.0], [0.35, 0.0]])
	_mix(stroke, _splash(0.25, 0.3), 0.05, 0.5)
	_save("swim_stroke", stroke)
	var anv := _metal(1.0, 1240.0, 0.25)
	_mix(anv, _gain(_metal(0.6, 1870.0, 0.12), 0.5))
	_save("anvil", _reverb(anv, 0.2, 0.5, 0.3))
	# Day and night (DayNight): the rooster at dawn, a far howl at nightfall,
	# an owl now and then in the dark.
	var ro := _buf(1.4)
	var crow := [[0.0, 0.12, 700.0, 900.0], [0.16, 0.14, 900.0, 1100.0], [0.34, 0.75, 1150.0, 820.0]]
	for c in crow:
		var f0: float = c[2]
		var f1: float = c[3]
		var syl := _voice(float(c[1]) + 0.05, func(t: float) -> float: return lerpf(f0, f1, t), VOWELS.o, 0.5, 0.25, 0.04)
		_env(syl, [[0.0, 0.0], [0.02, 1.0], [float(c[1]) * 0.7, 0.8], [float(c[1]) + 0.05, 0.0]])
		_mix(ro, syl, c[0])
	_save("rooster", _reverb(ro, 0.35, 0.8, 0.4, 0.4))
	var how := _voice(2.6, func(t: float) -> float: return 380.0 + 180.0 * sin(clampf(t * 1.4, 0.0, 1.0) * PI * 0.5) - 140.0 * maxf(t - 0.7, 0.0) / 0.3, VOWELS.u, 0.0, 0.2, 0.01)
	_env(how, [[0.0, 0.0], [0.4, 1.0], [2.0, 0.8], [2.6, 0.0]])
	_save("night_howl", _reverb(_filter(how, "lp", 2400.0), 0.6, 0.95, 0.4, 1.4))
	_save("owl_hoot", _amb_event("owl"))


## Beta 1.0.0's sounds: ice shattering (the frozen falls, the serpent's
## shell), the rooster's clucks and his furious crow, Tansy's cups sliding and
## lifting, a shiver in the cold, and the Meltwater Serpent's roar.
func _beta() -> void:
	var ice := _thud(0.9, 220.0, 0.06)
	for k in 34:
		var f := rng.randf_range(2200.0, 8000.0)
		var shard := _modes(0.3, [[f, rng.randf_range(0.03, 0.08), 1.0], [f * 2.3, 0.02, 0.5]])
		_mix(ice, shard, rng.randf_range(0.0, 0.4) * rng.randf(), rng.randf_range(0.1, 0.3))
	_mix(ice, _gain(_bell(1975.0, 0.9, 1.4), 0.35), 0.02)
	_save("ice_shatter", _reverb(ice, 0.3, 0.7, 0.3, 0.5))
	var cl := _buf(0.32)
	for i in 3:
		var syl := _voice(0.07, func(t: float) -> float: return 620.0 + 180.0 * t, VOWELS.a, 0.6, 0.3, 0.05)
		_env(syl, [[0.0, 0.0], [0.01, 1.0], [0.05, 0.6], [0.07, 0.0]])
		_mix(cl, syl, i * 0.09 + rng.randf_range(0.0, 0.02))
	_save("cluck", cl)
	var ang := _buf(1.2)
	for c in [[0.0, 0.1, 900.0, 1200.0], [0.12, 0.1, 1200.0, 1400.0], [0.26, 0.7, 1500.0, 1000.0]]:
		var f0: float = c[2]
		var f1: float = c[3]
		var syl := _voice(float(c[1]) + 0.05, func(t: float) -> float: return lerpf(f0, f1, t) + 40.0 * sin(t * 90.0), VOWELS.a, 0.9, 0.35, 0.06)
		_env(syl, [[0.0, 0.0], [0.015, 1.0], [float(c[1]) * 0.7, 0.9], [float(c[1]) + 0.05, 0.0]])
		_mix(ang, syl, c[0])
	_save("rooster_angry", _reverb(ang, 0.25, 0.6, 0.4, 0.3))
	var slide := _rustle(0.28, 1800.0, 0.12, 0.2)
	_mix(slide, _gain(_thud(0.1, 180.0, 0.02), 0.5), 0.2)
	_save("cup_slide", slide)
	var lift := _modes(0.4, [[880.0, 0.12, 1.0], [1760.0, 0.06, 0.4], [2640.0, 0.03, 0.2]])
	_mix(lift, _gain(_thud(0.12, 240.0, 0.02), 0.6))
	_save("cup_lift", _reverb(lift, 0.15, 0.4, 0.4))
	var sh := _voice(0.6, func(t: float) -> float: return 240.0 + 30.0 * sin(t * 70.0), VOWELS.u, 0.4, 0.6, 0.1)
	_env(sh, [[0.0, 0.0], [0.08, 1.0], [0.45, 0.6], [0.6, 0.0]])
	_mix(sh, _gain(_rustle(0.5, 3000.0, 0.15, 0.3), 0.3), 0.05)
	_save("shiver", sh)
	var roar := _voice(1.6, func(t: float) -> float: return 110.0 + 90.0 * sin(clampf(t * 1.8, 0.0, 1.0) * PI) - 30.0 * t, VOWELS.o, 1.0, 0.5, 0.05)
	_env(roar, [[0.0, 0.0], [0.15, 1.0], [1.1, 0.8], [1.6, 0.0]])
	_mix(roar, _gain(_splash(0.8, 1.0), 0.5), 0.0)
	_save("serpent_roar", _reverb(_filter(roar, "lp", 3000.0), 0.4, 0.9, 0.4, 0.8))


## Pottery shattering: a thud, then many small shards ringing high.
func _shatter() -> PackedFloat32Array:
	var b := _thud(0.6, 300.0, 0.04)
	for k in 26:
		var f := rng.randf_range(1800.0, 6500.0)
		var shard := _modes(0.15, [[f, rng.randf_range(0.01, 0.04), 1.0], [f * 1.7, 0.01, 0.4]])
		_mix(b, shard, rng.randf_range(0.0, 0.25) * rng.randf(), rng.randf_range(0.1, 0.35))
	_mix(b, _gain(_rustle(0.3, 2500.0, 0.08, 1.5), 0.4))
	return _reverb(b, 0.12, 0.4, 0.5)


func _rock_break() -> PackedFloat32Array:
	var b := _strike(0.6, 0.004, [[500.0, 3.0, 1.0], [1200.0, 4.0, 0.6], [2600.0, 5.0, 0.3]], 7000.0, 0.4)
	_decay(b, 0.001, 0.1)
	_mix(b, _grains(0.5, 80.0, 400.0, 2400.0, 0.005, 4.0), 0.03, 0.6)
	_mix(b, _gain(_thud(0.3, 140.0, 0.08), 1.0))
	return _reverb(b, 0.15, 0.5, 0.5)


## A wooden creak (a lid, a door): friction stick-slip, a pitch drifting.
func _creak(seconds: float, f0: float, f1: float, latch: bool) -> PackedFloat32Array:
	var b := _buf(seconds + 0.2)
	var t := 0.0
	var start := 0.08 if latch else 0.0
	while t < seconds - start:
		var k := t / (seconds - start)
		var f := lerpf(f0, f1, k) * (1.0 + 0.1 * sin(k * 9.0))
		var tick := _strike(0.03, 0.0015, [[f * 4.0, 6.0, 0.6], [f * 9.0, 8.0, 0.3]], 6000.0, 0.2)
		_mix(b, tick, start + t, 0.5 + 0.5 * sin(k * PI))
		t += 1.0 / f * 6.0 * rng.randf_range(0.7, 1.3)
	if latch:
		_mix(b, _gain(_metal(0.15, 2400.0, 0.03), 0.6))
	return _reverb(b, 0.12, 0.4, 0.5)


func _unlock() -> PackedFloat32Array:
	var b := _buf(0.8)
	_mix(b, _metal(0.15, 2600.0, 0.02), 0.0, 0.6)
	_mix(b, _metal(0.15, 2200.0, 0.02), 0.12, 0.6)
	var slide := _filter(_white(0.25), "bp", 1500.0, 2.0)
	_env(slide, [[0.0, 0.0], [0.05, 0.6], [0.25, 0.0]])
	_mix(b, slide, 0.25)
	_mix(b, _gain(_thud(0.3, 200.0, 0.06), 1.2), 0.48)
	_mix(b, _metal(0.3, 900.0, 0.08), 0.48, 0.5)
	return _reverb(b, 0.18, 0.5, 0.5)


## A stone shutter: grinding, and (closing) the slam at the end.
func _slam(seconds: float, close: bool) -> PackedFloat32Array:
	var b := _brown(seconds)
	_filter(b, "bp", 300.0, 1.0)
	_mix(b, _grains(seconds, 150.0, 300.0, 1500.0, 0.004, 3.0), 0.0, 0.5)
	_env(b, [[0.0, 0.0], [0.05, 0.8], [seconds - 0.1, 0.8], [seconds, 0.0]])
	if close:
		_mix(b, _gain(_thud(0.4, 120.0, 0.1), 2.0), seconds - 0.12)
		_mix(b, _gain(_strike(0.3, 0.004, [[600.0, 4.0, 1.0]], 4000.0, 0.3), 0.6), seconds - 0.12)
		b.resize(b.size() + int(0.35 * _sr))
	return _reverb(b, 0.25, 0.7, 0.4, 0.3)


## Fire catching: a soft whoomph swelling, then crackle.
func _fire_burst(seconds: float) -> PackedFloat32Array:
	var b := _brown(seconds)
	_sweep(b, "lp", func(t: float) -> float: return lerpf(200.0, 1800.0, minf(t * 3.0, 1.0)), 0.8)
	_env(b, [[0.0, 0.0], [0.12, 1.0], [seconds, 0.0]])
	_mix(b, _crackle(seconds, 40.0), 0.05, 0.6)
	return b


func _crackle(seconds: float, rate: float) -> PackedFloat32Array:
	return _grains(seconds, rate, 1200.0, 5000.0, 0.0015, 2.5)


# =============================================================================
# Biscuit the horse
# =============================================================================

func _horse() -> void:
	rng.seed = 8100
	var clop := _strike(0.2, 0.002, [[620.0, 6.0, 1.0], [1500.0, 8.0, 0.5]], 6000.0, 0.3)
	_mix(clop, _gain(_thud(0.12, 200.0, 0.025), 1.0))
	_mix(clop, _gain(_grit(0.08, 1500.0, 0.02), 0.3), 0.01)
	_save("horse_step", _decay(clop, 0.0008, 0.05))
	var neigh := _voice(1.1, func(t: float) -> float: return 300.0 + 220.0 * sin(t * PI) * (1.0 + 0.15 * sin(t * 70.0)), VOWELS.e, 0.6, 0.3, 0.05)
	_env(neigh, [[0.0, 0.0], [0.08, 1.0], [0.7, 0.8], [1.1, 0.0]])
	_save("horse_neigh", _reverb(neigh, 0.15, 0.5, 0.4, 0.3))
	var snort := _pink(0.4)
	_filter(snort, "bp", 600.0, 1.2)
	_env(snort, [[0.0, 0.0], [0.02, 1.0], [0.12, 0.6], [0.4, 0.0]])
	for i in snort.size():
		snort[i] *= 1.0 + 0.6 * sin(TAU * 40.0 * float(i) / _sr)
	_save("horse_snort", snort)
	var spur := _thud(0.15, 300.0, 0.03)
	_mix(spur, _gain(snort.duplicate(), 0.5), 0.05)
	_save("horse_spur", spur)
	var hj := _swish(0.35, 300.0, 900.0, 2.0)
	_mix(hj, _gain(snort.duplicate(), 0.4))
	_save("horse_jump", hj)
	var hl := _buf(0.5)
	_mix(hl, _thud(0.25, 150.0, 0.06), 0.0)
	_mix(hl, _thud(0.25, 140.0, 0.06), 0.09)
	_mix(hl, _gain(_grit(0.2, 1200.0, 0.05), 0.4), 0.02)
	_save("horse_land", hl)


# =============================================================================
# The fall of Castle Town: fire, mages, the quake, the bells, a laugh
# =============================================================================

func _story() -> void:
	rng.seed = 8300
	var fw := _brown(1.1)
	_sweep(fw, "lp", func(t: float) -> float: return lerpf(300.0, 2500.0, sin(t * PI)), 0.7)
	_env(fw, [[0.0, 0.0], [0.2, 1.0], [0.6, 0.8], [1.1, 0.0]])
	_mix(fw, _crackle(1.0, 60.0), 0.1, 0.5)
	_save("fire_whoosh", _reverb(fw, 0.15, 0.6, 0.4))
	# The Sapphire Order: a shimmering appearance and a crystalline cast.
	var ma := _white(0.7)
	_sweep(ma, "bp", func(t: float) -> float: return lerpf(4000.0, 800.0, t), 5.0)
	_env(ma, [[0.0, 0.0], [0.1, 1.0], [0.7, 0.0]])
	for k in 6:
		_mix(ma, _bell(rng.randf_range(1800.0, 3600.0), 0.4, 0.5), k * 0.05, 0.25)
	_save("mage_appear", _reverb(ma, 0.35, 0.7, 0.3, 0.4))
	var mc := _chirp(0.5, 600.0, 2400.0, [1.0, 0.0, 0.3, 0.0, 0.15], 0.5)
	_env(mc, [[0.0, 0.0], [0.05, 0.6], [0.35, 1.0], [0.5, 0.0]])
	_mix(mc, _gain(_swish(0.4, 1500.0, 5000.0, 4.0), 0.5), 0.1)
	_save("mage_cast", _reverb(mc, 0.3, 0.6, 0.3, 0.3))
	var quake := _brown(3.2)
	_filter(quake, "lp", 110.0)
	_filter(quake, "lp", 140.0)
	for i in quake.size():
		var t := float(i) / _sr
		quake[i] *= 0.6 + 0.4 * sin(TAU * 1.3 * t + sin(t * 3.1))
	_env(quake, [[0.0, 0.0], [0.5, 1.0], [2.4, 0.9], [3.2, 0.0]])
	_mix(quake, _grains(3.0, 25.0, 200.0, 900.0, 0.01, 3.0), 0.2, 0.25)
	_drive(quake, 1.8)
	_save("quake_rumble", quake)
	# Alarm bells ringing across the town.
	var bells := _buf(3.0)
	for k in 6:
		_mix(bells, _bell(523.25 if k % 2 == 0 else 440.0, 1.4, 0.8), k * 0.42, 0.6)
	_save("alarm", _reverb(bells, 0.45, 0.9, 0.3, 0.5))
	# Firebuns III laughing: "ha... ha ha HA!"
	var laugh := _buf(2.0)
	var beats := [[0.0, 0.18, 115.0, 0.6], [0.45, 0.16, 120.0, 0.7], [0.68, 0.16, 125.0, 0.8], [0.92, 0.42, 135.0, 1.0]]
	for bt in beats:
		var dur: float = bt[1]
		var f0: float = bt[2]
		var syl := _voice(dur + 0.05, func(t: float) -> float: return f0 * (1.0 + 0.15 * (1.0 - t)), VOWELS.a, 0.35, 0.35, 0.03)
		_env(syl, [[0.0, 0.0], [0.02, 1.0], [dur * 0.6, 0.8], [dur + 0.05, 0.0]])
		var h := _filter(_white(0.06), "bp", 1600.0, 1.0)
		_decay(h, 0.002, 0.025)
		_mix(syl, _gain(h, 0.6))
		_mix(laugh, syl, bt[0], bt[3])
	_save("firebuns_laugh", _reverb(laugh, 0.4, 0.85, 0.3, 0.6))
	# Lothelye appearing: a rising shimmer of bells over a soft choir chord
	# (E minor, the main motif's key), opening out into a long reverb.
	var ga := _choir(3.6, [64.0, 67.0, 71.0, 76.0], 0.9)
	var sh := _white(2.2)
	_sweep(sh, "bp", func(t: float) -> float: return lerpf(1500.0, 7000.0, t), 6.0)
	_env(sh, [[0.0, 0.0], [1.6, 0.5], [2.2, 0.0]])
	_mix(ga, sh, 0.0, 0.35)
	for k in 12:
		_mix(ga, _bell(440.0 * pow(2.0, ([64, 67, 71, 74, 76, 79][k % 6] + 12.0 * float(k / 6) - 57.0) / 12.0), 1.4, 0.6), 0.15 + k * 0.11, 0.22)
	_save("goddess_appear", _reverb(ga, 0.5, 0.95, 0.25, 1.2))
	# A goddess's light: one bright bell chord with a sung "ah" under it.
	var gc := _choir(2.4, [71.0, 76.0, 83.0], 0.4)
	_mix(gc, _gain(_bell(987.77, 2.2, 0.8), 0.6))
	_mix(gc, _gain(_bell(1318.5, 1.8, 0.6), 0.4), 0.06)
	_save("goddess_chime", _reverb(gc, 0.45, 0.9, 0.25, 0.8))


## A soft choir: one sung "ah" per MIDI note (high voices, slow vibrato,
## breathy), swelling in over `swell` seconds and fading out.
func _choir(seconds: float, notes: Array, swell: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for i in notes.size():
		var f0 := 440.0 * pow(2.0, (float(notes[i]) - 69.0) / 12.0)
		var ph := rng.randf() * TAU
		var v := _voice(seconds, func(t: float) -> float: return f0 * (1.0 + 0.008 * sin(ph + t * seconds * TAU * 5.2)), VOWELS.a, 0.0, 0.25, 0.01)
		_env(v, [[0.0, 0.0], [swell, 1.0], [seconds * 0.7, 0.8], [seconds, 0.0]])
		_mix(b, v, 0.0, 0.5 / notes.size() * 2.0)
	return _filter(b, "lp", 5000.0)


# =============================================================================
# Ambience loops
# =============================================================================

## Beta 1.1.0 (the Batela Fells): the wisps' chime, a sapphire ward going
## out, Incunax's pages and covers.
func _fells() -> void:
	# A wisp's chime: two soft glassy bells a fifth apart, far off.
	var wc := _buf(1.8)
	_mix(wc, _gain(_bell(1568.0, 1.6, 0.5), 0.6))
	_mix(wc, _gain(_bell(2349.0, 1.4, 0.4), 0.45), 0.12)
	_save("wisp_chime", _reverb(wc, 0.6, 0.9, 0.3, 0.8))
	# A ward guttering out: a cold hiss falling away, and a little shimmer.
	var wo := _sweep(_white(1.0), "bp", func(t: float) -> float: return lerpf(3200.0, 400.0, t), 2.0)
	_env(wo, [[0.0, 0.0], [0.03, 1.0], [0.6, 0.4], [1.0, 0.0]])
	_mix(wo, _gain(_bell(2637.0, 0.9, 0.8), 0.35), 0.05)
	_mix(wo, _gain(_bell(3136.0, 0.8, 0.8), 0.25), 0.15)
	_save("ward_out", _reverb(wo, 0.35, 0.7, 0.4, 0.5))
	# Pages riffling open: quick bursts of dry rustle.
	var pf := _buf(0.7)
	for i in 9:
		_mix(pf, _rustle(0.06, 4500.0, 0.02, 0.6), i * 0.06 + rng.randf_range(0.0, 0.015), rng.randf_range(0.4, 0.8))
	_save("page_flutter", pf)
	# A great book slamming shut: a deep leather thud with a boom under it.
	var bs := _thud(0.6, 70.0, 0.12)
	_mix(bs, _gain(_rustle(0.12, 2200.0, 0.04, 0.3), 0.6))
	_mix(bs, _gain(_thud(0.3, 160.0, 0.05), 0.5), 0.01)
	_save("book_slam", _reverb(bs, 0.4, 0.85, 0.4, 0.6))


## Beta 1.2.0 (Chapter IV, the war): the Grave Spade biting soil, Pepper's
## bark, a goblin war horn, the ballista, timber giving way, the war boar,
## Grukk's roar.
func _war() -> void:
	# The spade: a gritty crunch of earth and a soft thump.
	var dg := _grit(0.35, 900.0, 0.08)
	_mix(dg, _gain(_thud(0.25, 110.0, 0.05), 0.7))
	_mix(dg, _gain(_rustle(0.2, 2400.0, 0.06, 0.8), 0.5), 0.04)
	_save("dig", dg)
	# A small dog's bark: two quick yaps.
	var bk := _buf(0.5)
	for i in 2:
		var y := _voice(0.12, func(t: float) -> float: return lerpf(720.0, 540.0, t), VOWELS.a, 0.5, 0.25, 0.04)
		_env(y, [[0.0, 0.0], [0.01, 1.0], [0.06, 0.6], [0.12, 0.0]])
		_mix(bk, y, i * 0.2)
	_save("dog_bark", _reverb(bk, 0.15, 0.4, 0.4))
	# A goblin war horn: a rough low blare rising a little, held, falling.
	var wh := _voice(1.8, func(t: float) -> float: return 98.0 * (1.0 + 0.06 * sin(t * PI)), VOWELS.o, 0.8, 0.15, 0.01)
	_env(wh, [[0.0, 0.0], [0.15, 1.0], [1.4, 0.85], [1.8, 0.0]])
	_save("war_horn", _reverb(_drive(wh, 1.4), 0.5, 0.95, 0.35, 1.2))
	# The ballista: a heavy twang, the arms slamming home, a rush of air.
	var bf := _pluck(0.6, 82.0, 0.4, 0.992)
	_mix(bf, _gain(_thud(0.3, 70.0, 0.06), 0.9))
	var air := _sweep(_white(0.4), "bp", func(t: float) -> float: return lerpf(2400.0, 600.0, t), 1.5)
	_env(air, [[0.0, 0.0], [0.02, 1.0], [0.4, 0.0]])
	_mix(bf, _gain(air, 0.5), 0.02)
	_save("ballista_fire", _reverb(bf, 0.25, 0.6, 0.4))
	# Timber giving way: a deep crack and splinters.
	var wc := _thud(0.7, 60.0, 0.15)
	for i in 10:
		_mix(wc, _rustle(0.08, 3000.0, 0.02, 1.0), 0.02 + i * 0.05 + rng.randf_range(0.0, 0.02), rng.randf_range(0.4, 0.8))
	_mix(wc, _gain(_grit(0.3, 1500.0, 0.08), 0.6))
	_save("wood_crash", _reverb(wc, 0.35, 0.8, 0.4, 0.5))
	# The war boar: a grunting squeal.
	var bs := _voice(0.5, func(t: float) -> float: return lerpf(380.0, 620.0, sin(t * PI)), VOWELS.e, 0.9, 0.3, 0.05)
	_env(bs, [[0.0, 0.0], [0.04, 1.0], [0.35, 0.8], [0.5, 0.0]])
	_save("boar_squeal", _drive(bs, 1.3))
	# Grukk the Siegebreaker's roar: the boss roar, lower and rougher.
	_save("ogre_roar", _reverb(_roar(1.8, 52.0, 1.3, 20.0), 0.5, 0.9, 0.35, 0.8))
	# A beacon catching (or dying): a great rushing whoosh.
	var bc := _sweep(_white(1.6), "bp", func(t: float) -> float: return lerpf(300.0, 1800.0, sin(t * PI * 0.5)), 1.2)
	_env(bc, [[0.0, 0.0], [0.4, 1.0], [1.6, 0.0]])
	_save("beacon_flare", _reverb(bc, 0.5, 0.9, 0.3, 0.8))


## Chapter V (Beta 1.3.0): the Knight's Techniques, the Ember Rod, the great
## stones, the undead rising, Cinderhold's lava.
func _ch5() -> void:
	# Gathering strength for the Great Spin: a rising shimmer of metal.
	var sc := _chirp(0.8, 600.0, 1400.0, [1.0, 0.5, 0.25], 1.5)
	_env(sc, [[0.0, 0.0], [0.6, 0.6], [0.8, 0.0]])
	_save("spin_charge", _reverb(sc, 0.3, 0.5, 0.4))
	# Charged: a bright ring.
	_save("spin_ready", _reverb(_bell(1760.0, 0.6, 1.4), 0.35, 0.5, 0.4, 0.3))
	# The spin itself: a long sweeping whoosh round the head.
	var sp := _sweep(_white(0.5), "bp", func(t: float) -> float: return lerpf(500.0, 3200.0, sin(t * PI)), 2.0)
	_env(sp, [[0.0, 0.0], [0.08, 1.0], [0.35, 0.8], [0.5, 0.0]])
	_save("spin_attack", _reverb(sp, 0.25, 0.5, 0.4))
	# The Down Thrust landing: a heavy thump and the ring of steel in stone.
	var dt := _thud(0.6, 70.0, 0.12)
	_mix(dt, _gain(_modes(0.5, [[2100.0, 0.12, 0.6], [3300.0, 0.06, 0.3]]), 0.5), 0.01)
	_mix(dt, _gain(_grit(0.3, 1200.0, 0.06), 0.6))
	_save("down_thrust", _reverb(dt, 0.3, 0.7, 0.4, 0.3))
	# The Shield Bash: a wooden-iron clunk and a grunt of air.
	var sb := _thud(0.3, 140.0, 0.05)
	_mix(sb, _gain(_modes(0.25, [[620.0, 0.05, 1.0], [1450.0, 0.03, 0.5]]), 0.7))
	_save("shield_bash", sb)
	# The Ember Rod: a quick roaring puff of fire.
	var ec := _sweep(_pink(0.5), "bp", func(t: float) -> float: return lerpf(1600.0, 500.0, t), 1.2)
	_env(ec, [[0.0, 0.0], [0.03, 1.0], [0.5, 0.0]])
	_save("ember_cast", _drive(ec, 1.3))
	# Melting ice: a hiss and crackle of steam.
	var sz := _filter(_white(1.0), "hp", 2500.0)
	_env(sz, [[0.0, 0.0], [0.05, 1.0], [1.0, 0.0]])
	for i in 8:
		_mix(sz, _rustle(0.05, 4000.0, 0.01, 1.0), rng.randf_range(0.0, 0.8), 0.5)
	_save("sizzle", sz)
	# Gripping and dragging a great stone: a grunt of stone, then a long grind.
	_save("stone_grip", _gain(_thud(0.3, 90.0, 0.06), 0.8))
	var gr := _sweep(_brown(2.2), "bp", func(t: float) -> float: return 180.0 + sin(t * 18.0) * 60.0, 1.5)
	_mix(gr, _gain(_grit(2.2, 700.0, 1.0), 0.5))
	_env(gr, [[0.0, 0.0], [0.2, 1.0], [2.0, 0.9], [2.2, 0.0]])
	_save("stone_drag", _drive(gr, 1.2))
	# Ice cracking: sharp splitting snaps.
	var ic := _buf(0.9)
	for i in 5:
		_mix(ic, _modes(0.3, [[rng.randf_range(2500.0, 4200.0), 0.04, 1.0], [rng.randf_range(5000.0, 7000.0), 0.02, 0.4]]), i * 0.13 + rng.randf_range(0.0, 0.04), 1.0 - i * 0.12)
	_save("ice_crack", _reverb(ic, 0.4, 0.8, 0.3, 0.4))
	# The dead rising: a low groan through a grinding of earth and bone.
	var ur := _voice(1.6, func(t: float) -> float: return lerpf(110.0, 80.0, t), VOWELS.o, 0.9, 0.4, 0.05)
	_env(ur, [[0.0, 0.0], [0.4, 1.0], [1.2, 0.7], [1.6, 0.0]])
	_mix(ur, _gain(_grit(1.4, 600.0, 0.6), 0.5), 0.1)
	_save("undead_rise", _reverb(ur, 0.5, 0.9, 0.35, 0.8))
	# Lava: a thick bubble and plop.
	var lb := _chirp(0.3, 140.0, 320.0, [1.0, 0.4], 2.0)
	_env(lb, [[0.0, 0.0], [0.02, 1.0], [0.3, 0.0]])
	_save("lava_bubble", _reverb(lb, 0.2, 0.4, 0.5))
	# A wooden shield knocked flying.
	var wb := _thud(0.4, 180.0, 0.06)
	for i in 4:
		_mix(wb, _rustle(0.06, 2800.0, 0.02, 1.0), 0.02 + i * 0.04, 0.6)
	_save("wood_break", wb)
	# The Barrow's rune bells.
	_save("temple_bell", _reverb(_bell(523.0, 2.6, 0.8), 0.5, 0.9, 0.3, 1.0))


func _ambiences() -> void:
	rng.seed = 9100
	_save("wind_loop", _amb_wind(16.0, 220.0, 820.0, 0.8), true)
	var specs := {
		"amb_field": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 250.0, 900.0, 0.6), [["bird", 7, 0.35], ["cricket", 5, 0.12]]),
		"amb_village": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 300.0, 800.0, 0.35), [["bird", 9, 0.4], ["cluck", 3, 0.2]]),
		"amb_town": func() -> PackedFloat32Array: return _amb_layers(_amb_murmur(LOOP + 1.0), [["bird", 4, 0.25]]),
		"amb_forest": func() -> PackedFloat32Array: return _amb_layers(_amb_leaves(LOOP + 1.0), [["bird", 10, 0.45], ["owl", 1, 0.25]]),
		"amb_hidden": func() -> PackedFloat32Array: return _amb_layers(_amb_hum(LOOP + 1.0), [["drip", 6, 0.2]]),
		"amb_marsh": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 200.0, 600.0, 0.3), [["frog", 10, 0.4], ["cricket", 8, 0.15], ["bubble", 6, 0.2]]),
		"amb_farm": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 250.0, 800.0, 0.45), [["bird", 6, 0.35], ["cluck", 4, 0.25]]),
		"amb_desert": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 400.0, 1400.0, 1.0), [["sand", 5, 0.25]]),
		"amb_cliffs": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 180.0, 1100.0, 1.0), [["bird", 2, 0.2]]),
		"amb_snow": func() -> PackedFloat32Array: return _amb_layers(_amb_wind(LOOP + 1.0, 500.0, 1600.0, 0.9), []),
		"amb_lake": func() -> PackedFloat32Array: return _amb_layers(_amb_waves(LOOP + 1.0), [["gull", 3, 0.3], ["bird", 3, 0.2]]),
		"amb_hearth": func() -> PackedFloat32Array: return _amb_layers(_amb_fire(LOOP + 1.0), []),
		"amb_shrine": func() -> PackedFloat32Array: return _amb_layers(_amb_drone(LOOP + 1.0, 55.0), [["drip", 9, 0.35]]),
		"amb_bog": func() -> PackedFloat32Array: return _amb_layers(_amb_drone(LOOP + 1.0, 48.0), [["frog", 7, 0.35], ["bubble", 10, 0.3], ["drip", 6, 0.2]]),
		"amb_ruins": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_amb_fire(LOOP + 1.0), _amb_wind(LOOP + 1.0, 200.0, 700.0, 0.6)), [["rumble", 2, 0.35]]),
		"amb_vision": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_choir_drone(LOOP + 1.0), _amb_hum(LOOP + 1.0)), [["chime", 9, 0.3]]),
		# The Forest of the Dead: a low, still wind in dead branches, far-off chimes.
		"amb_dead": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_gain(_amb_wind(LOOP + 1.0, 120.0, 420.0, 0.35), 0.8), _gain(_amb_drone(LOOP + 1.0, 41.0), 0.5)), [["chime", 4, 0.18], ["owl", 1, 0.15]]),
		# The Batela Fells: a cold upland wind over ash, a far fire, a crow now and then.
		"amb_fells": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_amb_wind(LOOP + 1.0, 160.0, 900.0, 0.85), _gain(_amb_fire(LOOP + 1.0), 0.25)), [["rumble", 1, 0.25], ["crow", 3, 0.3]]),
		# Bunsriel at war (Chapter IV): wind over burning grass, distant fighting.
		"amb_war": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_amb_wind(LOOP + 1.0, 200.0, 800.0, 0.6), _gain(_amb_fire(LOOP + 1.0), 0.45)), [["rumble", 3, 0.35], ["crow", 2, 0.25]]),
		# The Barrow of Kings: a deep still drone, water dripping in the vaults.
		"amb_crypt": func() -> PackedFloat32Array: return _amb_layers(_gain(_amb_drone(LOOP + 1.0, 38.0), 0.9), [["drip", 8, 0.3], ["chime", 1, 0.1]]),
		# Cinderhold: the mountain's rumble under a crackle of fire and hot wind.
		"amb_cinder": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_gain(_amb_fire(LOOP + 1.0), 0.7), _amb_wind(LOOP + 1.0, 120.0, 600.0, 0.5)), [["rumble", 4, 0.4], ["bubble", 8, 0.3]]),
		# Rain (Weather): a steady hiss with heavier drops in it.
		"amb_rain": func() -> PackedFloat32Array: return _amb_layers(_amb_mix(_filter(_pink(LOOP + 1.0), "hp", 900.0), _gain(_amb_wind(LOOP + 1.0, 200.0, 700.0, 0.35), 0.6)), [["drip", 30, 0.25]]),
		# The night layer (DayNight lays it over any open-air area after dark).
		"amb_night": func() -> PackedFloat32Array: return _amb_layers(_gain(_amb_wind(LOOP + 1.0, 180.0, 500.0, 0.25), 0.5), [["cricket", 26, 0.3], ["owl", 1, 0.2]]),
	}
	for amb_name: String in specs:
		var b: PackedFloat32Array = specs[amb_name].call()
		_save(amb_name, _seamless(b, 1.0), true)


## Lothelye's realm: a slow, distant choir moving between E minor and C
## major chords (no beat, so it loops anywhere).
func _choir_drone(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var chords := [[52.0, 59.0, 64.0, 67.0], [48.0, 55.0, 64.0, 67.0], [52.0, 59.0, 64.0, 71.0], [50.0, 57.0, 62.0, 66.0]]
	var step := seconds / chords.size()
	for i in chords.size():
		_mix(b, _choir(step + 2.0, chords[i], 1.6), i * step - 1.0 if i > 0 else 0.0, 0.8)
	_mix(b, _choir(2.2, chords[0], 1.0), seconds - 1.2, 0.6)
	return _reverb(b, 0.6, 0.95, 0.3, 1.0)


func _amb_mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	return _mix(a, b, 0.0, 1.0)


## Scatters `count` of each event kind over the loop: [kind, count, gain].
func _amb_layers(base: PackedFloat32Array, layers: Array) -> PackedFloat32Array:
	var dur := float(base.size()) / _sr
	for l in layers:
		for k in int(l[1]):
			var ev := _amb_event(String(l[0]))
			_mix(base, ev, rng.randf_range(0.0, dur - float(ev.size()) / _sr - 0.05), float(l[2]) * rng.randf_range(0.6, 1.0))
	return base


func _amb_event(kind: String) -> PackedFloat32Array:
	match kind:
		"bird":
			# A short warble of a few rising and falling chirps.
			var b := _buf(0.6)
			var base := rng.randf_range(2600.0, 4200.0)
			for k in rng.randi_range(2, 5):
				var c := _chirp(0.07, base * rng.randf_range(0.9, 1.1), base * rng.randf_range(1.1, 1.4), [1.0, 0.15])
				_env(c, [[0.0, 0.0], [0.01, 1.0], [0.07, 0.0]])
				_mix(b, c, k * 0.09)
			return b
		"cricket":
			var b2 := _buf(0.5)
			var f := rng.randf_range(4200.0, 5000.0)
			for k in 4:
				var c2 := _chirp(0.04, f, f, [1.0])
				for i in c2.size():
					c2[i] *= 0.5 + 0.5 * sin(TAU * 60.0 * float(i) / _sr)
				_env(c2, [[0.0, 0.0], [0.005, 1.0], [0.04, 0.0]])
				_mix(b2, c2, k * 0.06)
			return b2
		"frog":
			var fr := _voice(0.35, func(t: float) -> float: return rng.randf_range(90.0, 140.0), [[400, 4.0, 1.0], [900, 5.0, 0.4]], 0.6, 0.1, 0.03)
			for i in fr.size():
				fr[i] *= pow(0.5 + 0.5 * sin(TAU * 22.0 * float(i) / _sr), 2.0)
			_env(fr, [[0.0, 0.0], [0.03, 1.0], [0.3, 0.7], [0.35, 0.0]])
			return fr
		"bubble":
			return _decay(_chirp(0.1, rng.randf_range(150.0, 300.0), rng.randf_range(400.0, 800.0), [1.0, 0.2], 0.5), 0.002, 0.03)
		"drip":
			var d := _decay(_chirp(0.15, rng.randf_range(900.0, 1500.0), rng.randf_range(1800.0, 2600.0), [1.0], 0.3), 0.001, 0.035)
			return _reverb(d, 0.6, 0.85, 0.3, 0.6)
		"chime":
			return _reverb(_bell(rng.randf_range(1200.0, 2400.0), 1.5, 0.6), 0.5, 0.8, 0.3, 0.5)
		"owl":
			var o := _buf(1.2)
			for k in 2:
				var hoot := _voice(0.3, func(t: float) -> float: return 380.0 - 40.0 * t, VOWELS.u, 0.0, 0.1, 0.01)
				_env(hoot, [[0.0, 0.0], [0.05, 1.0], [0.25, 0.6], [0.3, 0.0]])
				_mix(o, hoot, k * 0.45)
			return _reverb(o, 0.4, 0.8, 0.4)
		"gull":
			var g := _voice(0.5, func(t: float) -> float: return lerpf(1300.0, 900.0, t), VOWELS.e, 0.2, 0.2, 0.04)
			_env(g, [[0.0, 0.0], [0.04, 1.0], [0.5, 0.0]])
			return g
		"cluck":
			var cl := _buf(0.6)
			for k in rng.randi_range(2, 4):
				var c3 := _voice(0.08, func(t: float) -> float: return 600.0, VOWELS.a, 0.3, 0.2, 0.05)
				_decay(c3, 0.004, 0.03)
				_mix(cl, c3, k * 0.12)
			return cl
		"sand":
			var s := _sand(1.2)
			_filter(s, "lp", 6000.0)
			return s
		"crow":
			var cw := _buf(1.0)
			for k in rng.randi_range(1, 3):
				var caw := _voice(0.22, func(t: float) -> float: return lerpf(560.0, 420.0, t), VOWELS.a, 1.0, 0.4, 0.06)
				_env(caw, [[0.0, 0.0], [0.02, 1.0], [0.16, 0.6], [0.22, 0.0]])
				_mix(cw, caw, k * 0.28)
			return _reverb(cw, 0.3, 0.7, 0.4)
		"rumble":
			var r := _brown(2.5)
			_filter(r, "lp", 160.0)
			_env(r, [[0.0, 0.0], [0.8, 1.0], [2.5, 0.0]])
			return r
	return _buf(0.1)


## Gusting wind: noise through a band-pass whose pitch and level ride slow gusts.
func _amb_wind(seconds: float, lo: float, hi: float, strength: float) -> PackedFloat32Array:
	var b := _pink(seconds)
	var f := Biquad.new(_sr)
	for i in b.size():
		var t := float(i) / _sr
		var gust := clampf(0.5 + 0.28 * sin(TAU * t / 9.0) + 0.14 * sin(TAU * t / 3.7 + 1.0) + 0.08 * sin(TAU * t / 1.9 + 2.0), 0.0, 1.0)
		if i % 64 == 0:
			var y1 := f.y1
			var y2 := f.y2
			var x1 := f.x1
			var x2 := f.x2
			f.setup("bp", lerpf(lo, hi, gust), 1.3)
			f.y1 = y1; f.y2 = y2; f.x1 = x1; f.x2 = x2
		b[i] = f.tick(b[i]) * (0.3 + 0.7 * gust * strength)
	var low := _brown(seconds)
	_filter(low, "lp", 120.0)
	return _mix(b, low, 0.0, 0.5 * strength)


func _amb_leaves(seconds: float) -> PackedFloat32Array:
	var b := _amb_wind(seconds, 600.0, 2400.0, 0.5)
	return _mix(b, _grains(seconds, 25.0, 2000.0, 5000.0, 0.002, 2.0), 0.0, 0.25)


## A town's murmur: many soft voices blurred together, and footsteps.
func _amb_murmur(seconds: float) -> PackedFloat32Array:
	var b := _pink(seconds)
	_filter(b, "bp", 500.0, 0.8)
	for i in b.size():
		var t := float(i) / _sr
		b[i] *= 0.6 + 0.25 * sin(TAU * t * 0.7) + 0.15 * sin(TAU * t * 2.3)
	for k in 14:
		var v := _voice(rng.randf_range(0.4, 0.9), func(t: float) -> float: return rng.randf_range(140.0, 240.0), VOWELS[["a", "e", "o"][k % 3]], 0.0, 0.2, 0.06)
		_filter(v, "lp", 1500.0)
		_env(v, [[0.0, 0.0], [0.1, 1.0], [float(v.size()) / _sr, 0.0]])
		_mix(b, v, rng.randf_range(0.0, seconds - 1.0), 0.15)
	return b


func _amb_waves(seconds: float) -> PackedFloat32Array:
	var b := _pink(seconds)
	var f := Biquad.new(_sr)
	for i in b.size():
		var t := float(i) / _sr
		var w := pow(0.5 + 0.5 * sin(TAU * t / 3.5), 2.0)
		if i % 64 == 0:
			var y1 := f.y1
			var y2 := f.y2
			var x1 := f.x1
			var x2 := f.x2
			f.setup("lp", lerpf(400.0, 2200.0, w), 0.7)
			f.y1 = y1; f.y2 = y2; f.x1 = x1; f.x2 = x2
		b[i] = f.tick(b[i]) * (0.25 + 0.75 * w)
	return b


func _amb_fire(seconds: float) -> PackedFloat32Array:
	var b := _brown(seconds)
	_filter(b, "lp", 500.0)
	_gain(b, 0.6)
	return _mix(b, _crackle(seconds, 18.0), 0.0, 0.5)


func _amb_hum(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for f in [220.0, 330.0, 440.0]:
		var h := _chirp(seconds, f, f, [1.0, 0.2])
		for i in h.size():
			h[i] *= 0.5 + 0.5 * sin(TAU * float(i) / _sr / (5.0 + f * 0.01))
		_mix(b, h, 0.0, 0.15)
	return _mix(b, _amb_wind(seconds, 400.0, 900.0, 0.2), 0.0, 0.6)


## A low, slowly beating drone with reverb (shrines, the bog tower).
func _amb_drone(seconds: float, f: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	for r in [1.0, 1.5, 2.01]:
		var h := _chirp(seconds, f * r, f * r, [1.0, 0.3])
		_mix(b, h, 0.0, 0.25 / r)
	var air := _pink(seconds)
	_filter(air, "lp", 400.0)
	return _mix(b, air, 0.0, 0.4)
