extends RefCounted
## Generates the small textures (faces, HUD, surfaces) and, through
## tools/gen_sfx.gd, every sound.

const Layout := preload("res://tools/level_layout.gd")
const TEX_DIR := "res://assets/textures/"


func run() -> void:
	_textures()
	preload("res://tools/gen_sfx.gd").new().run()


# --- Textures -----------------------------------------------------------------

func _textures() -> void:
	# One stretched texture covers the whole terrain, with the path painted in.
	_save(Layout.paint_terrain_texture(), "terrain")
	_save(_noise(32, ["55514c", "65605a", "746e67", "847d74"], 4, 0.5, 14), "rock")
	_save(_strata(_noise(32, ["4e4740", "5c544b", "6a6157", "776d61"], 4, 0.5, 15)), "cliff")
	_save(_bricks(_noise(32, ["6e6a62", "7c776e", "8a847a", "958f84"], 8, 0.45, 16)), "stone_brick")
	_save(_noise_stretched(32, ["35251a", "432f20", "523a27", "60462f"], Vector2i(2, 8), 0.5, 17), "bark")
	_save(_noise(32, ["213d17", "2c4f1e", "386124", "47722c"], 4, 0.7, 18), "leaves")
	_save(_planks(_noise_stretched(32, ["5e4128", "6b4b2e", "785534", "84603b"], Vector2i(8, 2), 0.5, 19)), "wood")
	# Overworld surfaces. Light and neutral: vertex colors tint them per object.
	_save(_noise(32, ["d6d0c2", "e0dacd", "e9e4d8", "f2eee4"], 4, 0.35, 21), "plaster")
	_save(_timber(), "timber")
	_save(_tiles(_noise(32, ["c4bcb4", "d0c8c0", "dbd4cc", "e6e0d8"], 4, 0.4, 22)), "roof_tiles")
	_save(_noise_stretched(32, ["9c7e42", "ae904e", "c0a25c", "d0b26a"], Vector2i(10, 2), 0.5, 23), "thatch")
	_save(_strata(_noise(64, ["c49862", "d0a66e", "dcb47a", "e6c288"], 6, 0.4, 24)), "sandstone")
	_save(_noise(32, ["dce4ee", "e6ecf4", "eff3f9", "f8faff"], 4, 0.3, 25), "snow")
	_save(_noise_stretched(32, ["9cc6dc", "afd4e8", "c2e0f0", "d6ecf6"], Vector2i(2, 8), 0.3, 26), "ice")
	_save(_noise(64, ["8aaed6", "9cbee2", "b0ceec", "c6def4"], 8, 0.25, 27), "water")
	_save(_door(), "door")
	_save(_seal(), "seal")
	_save(_noise(32, ["1c3a22", "244a2a", "2e5832", "3a6a3c"], 4, 0.7, 28), "pine")
	_save(_strata(_noise(128, ["948e86", "a39d94", "b1aba1", "bfb9ae"], 10, 0.45, 29)), "cliff_rock")
	_save(_cobbles(), "cobble")
	# The Lake Shrine: blue-green bricks under a carved band of waves, and coral.
	_save(_shrine_wall(), "shrine_wall")
	_save(_noise(32, ["c86a6a", "d88078", "e89a8a", "f0b0a0"], 6, 0.6, 41), "coral")
	# Character faces are painted, the way N64 Zelda faces were: the head is a
	# smooth low-poly shape and the eyes, brows, beard and mouth live in the texture.
	_save(_face_gigglebuns(), "face_gigglebuns")
	_save(_face_goblin(), "face_goblin")
	_save(_face_mira(), "face_mira")
	_save(_face_pink(), "face_pink")
	_save(_face_aladriel(), "face_aladriel")
	_save(_face_idrith(), "face_idrith")
	_save(_face_ottilie(), "face_ottilie")
	_save(_face_marigold(), "face_marigold")
	_save(_face_clover(), "face_clover")
	_save(_face_firebuns(), "face_firebuns")
	_save(_face_mage(), "face_mage")
	_save(_face_lothelye(), "face_lothelye")
	_save(_face_himeko(), "face_himeko")
	_save(_face_hilde(), "face_hilde")
	_save(_face_tansy(), "face_tansy")
	_save(_face_maud(), "face_maud")
	_save(_face_wren(), "face_wren")
	_save(_face_odile(), "face_odile")
	_save(_face_tamsin(), "face_tamsin")
	_save(_face_rowena(), "face_rowena")
	_save(_face_soldier(), "face_soldier")
	_save(_face_posy(), "face_posy")
	_save(_face_mara(), "face_mara")
	_save(_face_avalon(), "face_avalon")
	_save(_face_serielye(), "face_serielye")
	for spec: Dictionary in preload("res://tools/folk_specs.gd").FOLK:
		_save(_face_folk(spec), "face_" + String(spec.id))
	_save(_chrome_env(), "chrome_env")
	_save(_sparkle(), "sparkle")
	# HUD pieces, smooth like OoT's interface textures (tinted when drawn).
	_save(_hud_button(), "hud_button")
	_save(_hud_heart(2), "hud_heart_full")
	_save(_hud_heart(1), "hud_heart_half")
	_save(_hud_heart(0), "hud_heart_empty")


func _hex(h: String) -> Color:
	return Color.html(h)


func _fill(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), col)


## Mirrored pixel pair around the face center column (x = 32 is straight ahead).
func _pair(img: Image, dx: int, y: int, w: int, h: int, col: Color) -> void:
	_fill(img, 32 + dx, y, w, h, col)
	_fill(img, 32 - dx - w, y, w, h, col)


## Head wrap for Sir Gigglebuns IV. 64x64, u wraps once around the head
## (front = center), v runs from the crown (top) to under the jaw (bottom).
## The head loft has evenly spaced rings from y = -0.03 to 0.37, so one texel
## row is 6.25 mm: eyes sit on row 26, the brow on 21, the mouth on 46.
func _face_gigglebuns() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var skin := _hex("e3b08a")
	var skin_d := _hex("c9946e")
	var skin_l := _hex("efc39f")
	var beard := _hex("5b3420")
	var beard_d := _hex("44261a")
	var beard_l := _hex("6e4129")
	img.fill(skin)
	# Gentle crown highlight and darker back of the skull.
	_fill(img, 20, 0, 24, 6, skin_l)
	_fill(img, 0, 0, 10, 64, skin_d)
	_fill(img, 54, 0, 10, 64, skin_d)
	# Full beard: jaw, chin and cheeks, with sideburns up to the ears.
	for y in range(34, 64):
		var half := 19 if y >= 38 else 15
		_fill(img, 32 - half, y, half * 2, 1, beard)
	_pair(img, 13, 24, 6, 14, beard)            # sideburns
	_pair(img, 12, 40, 7, 24, beard_d)          # shadowed jaw sides
	_fill(img, 26, 50, 12, 10, beard_l)         # chin tuft catching light
	# Mustache over a dark mouth line.
	_fill(img, 26, 38, 12, 4, beard_d)
	_fill(img, 29, 43, 6, 2, _hex("2e1810"))
	_fill(img, 30, 45, 4, 1, _hex("8a4a3a"))     # lower lip
	# Nose: shaded ridge and nostrils.
	_fill(img, 31, 28, 2, 7, skin_l)
	_pair(img, 2, 30, 1, 5, skin_d)
	_pair(img, 1, 35, 2, 1, _hex("9c6248"))
	# Eyes: whites, brown irises toward the center, dark upper lid.
	_pair(img, 2, 25, 6, 3, _hex("eee6d2"))
	_pair(img, 3, 25, 3, 3, _hex("5e3417"))
	_pair(img, 4, 26, 1, 1, _hex("1e120a"))
	_pair(img, 2, 24, 6, 1, _hex("7a4a34"))
	# Stern brows, low at the center and rising outward.
	_pair(img, 1, 22, 3, 2, _hex("3a2014"))
	_pair(img, 4, 21, 3, 2, _hex("3a2014"))
	_pair(img, 7, 20, 2, 2, _hex("3a2014"))
	# Brow-ridge shadow and a frown crease.
	_pair(img, 1, 24, 1, 1, skin_d)
	_fill(img, 31, 18, 2, 3, skin_d)
	# Ear shading at the sides.
	_pair(img, 15, 26, 3, 8, skin_d)
	return img


## Head wrap for Mira. Same layout as the hero's (64x64, front at x = 32,
## crown at the top), but her head loft is a little smaller: one row is 5.6 mm,
## so the brows sit on row 21, the eyes on rows 24-29 and the mouth on 43.
## Everything outside the face is hair; the bangs hang to the brows.
func _face_mira() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var hair := _hex("a4482a")
	var hair_d := _hex("7a321c")
	var hair_l := _hex("bc5a34")
	var skin := _hex("f0c8a8")
	var skin_d := _hex("dcae8c")
	var skin_l := _hex("f8d8bc")
	var blush := _hex("f0a090")
	img.fill(hair)
	# Strands: darker streaks down the back and sides.
	for x in range(0, 64, 4):
		_fill(img, x, 0, 1, 64, hair_d)
	for x in range(2, 64, 8):
		_fill(img, x, 0, 1, 64, hair_l)
	# The face: forehead down under the chin and onto the neck (only the back
	# and sides of the head are hair).
	for y in range(19, 64):
		var half := 14
		if y > 46:
			half = maxi(14 - int((y - 46) * 0.45), 9)
		_fill(img, 32 - half, y, half * 2, 1, skin if y < 54 else skin_d)
	# Shading toward the sides.
	_pair(img, 11, 24, 3, 24, skin_d)
	_pair(img, 3, 31, 6, 4, skin_l)
	# Bangs: a jagged fringe, parted a little to her right.
	var tips := [20, 21, 19, 20, 22, 21, 19, 18, 20, 21, 22, 20, 19, 21, 20, 22, 21, 19, 20, 21, 22, 21, 20, 19, 21, 20, 21, 22]
	for i in tips.size():
		var x := 18 + i
		_fill(img, x, 12, 1, tips[i] - 12, hair if i % 3 else hair_l)
	_fill(img, 29, 12, 1, 6, hair_d)
	# Brows: thin and lowered toward the middle (a stubborn little frown).
	_pair(img, 2, 22, 2, 1, hair_d)
	_pair(img, 4, 21, 3, 1, hair_d)
	_pair(img, 7, 21, 2, 1, hair_d)
	# Big eyes: thick upper lashes flicking out, green irises, bright catchlights.
	_pair(img, 2, 24, 6, 6, _hex("f4f0ea"))
	_pair(img, 3, 24, 4, 6, _hex("3a9a5a"))
	_pair(img, 4, 25, 2, 4, _hex("1e5a34"))
	_pair(img, 4, 26, 1, 2, _hex("101818"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, _hex("2a1410"))
	_pair(img, 8, 22, 1, 2, _hex("2a1410"))
	_pair(img, 2, 30, 5, 1, skin_d)
	# Blush across the cheeks.
	_pair(img, 6, 32, 5, 2, blush)
	_pair(img, 7, 34, 3, 1, skin.lerp(blush, 0.5))
	# Nose tip and a small pouting mouth turned down at the corners.
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 30, 43, 4, 1, _hex("b0505a"))
	_pair(img, 2, 44, 1, 1, _hex("b0505a"))
	_fill(img, 31, 44, 2, 1, _hex("e88a8a"))
	return img


## The three faces in Pink's Armory share Mira's head layout (64x64, front at
## x = 32, crown at the top; brows near row 21, eyes rows 24-29, mouth 43).
## Everything outside the face is hair. `fringe` is the bangs' lower edge per
## column across the forehead.
func _face_base(hair: Color, hair_d: Color, hair_l: Color, skin: Color, skin_d: Color, fringe: Array) -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(hair)
	for x in range(0, 64, 4):
		_fill(img, x, 0, 1, 64, hair_d)
	for x in range(2, 64, 8):
		_fill(img, x, 0, 1, 64, hair_l)
	for y in range(19, 64):
		var half := 14
		if y > 46:
			half = maxi(14 - int((y - 46) * 0.45), 9)
		_fill(img, 32 - half, y, half * 2, 1, skin if y < 54 else skin_d)
	_pair(img, 11, 24, 3, 24, skin_d)
	for i in fringe.size():
		var x := 18 + i
		_fill(img, x, 12, 1, int(fringe[i]) - 12, hair if i % 3 else hair_l)
	return img


## Pink, the armorer: warm brown skin, long pink hair with soft bangs, big
## friendly brown eyes and a wide smile.
func _face_pink() -> Image:
	var skin := _hex("7a4a32")
	var skin_d := _hex("623a26")
	var skin_l := _hex("8e5a3e")
	var img := _face_base(_hex("f27ab8"), _hex("d0568f"), _hex("ff9ccb"), skin, skin_d,
		[21, 21, 20, 20, 19, 19, 20, 21, 20, 19, 19, 20, 21, 20, 19, 19, 20, 21, 20, 19, 19, 20, 20, 21, 21, 22, 22, 22])
	_pair(img, 3, 31, 6, 4, skin_l)
	# Soft, rounded brows.
	_pair(img, 3, 21, 5, 1, _hex("3a2018"))
	# Big dark eyes, little white showing, lashes and bright catchlights.
	_pair(img, 3, 24, 5, 6, _hex("e8dcd4"))
	_pair(img, 3, 24, 4, 6, _hex("4a2618"))
	_pair(img, 4, 25, 2, 4, _hex("1e0e08"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 2, 23, 6, 1, _hex("140806"))
	_pair(img, 7, 22, 2, 2, _hex("140806"))
	# Rosy cheeks, nose and a big smile with pink lips.
	_pair(img, 7, 32, 4, 2, _hex("a05a4a"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 28, 42, 8, 1, _hex("3a1410"))
	_pair(img, 4, 41, 1, 1, _hex("3a1410"))
	_fill(img, 29, 43, 6, 1, _hex("d0607a"))
	return img


## Aladriel: pale, red-eyed and fierce. Messy brown bangs falling in points,
## brows angled down toward the middle, a flat little mouth and a blush.
func _face_aladriel() -> Image:
	var skin := _hex("fbeee4")
	var skin_d := _hex("e6d2c4")
	var img := _face_base(_hex("9a5530"), _hex("74391e"), _hex("c07a50"), skin, skin_d,
		[22, 24, 20, 18, 23, 25, 21, 19, 24, 22, 18, 20, 25, 23, 19, 21, 24, 26, 20, 18, 22, 25, 23, 19, 21, 24, 22, 23])
	# A pale streak through the hair, as in her picture.
	for y in range(0, 12):
		_fill(img, 22 + y, y, 3, 1, _hex("e2b496"))
	# Fierce brows sloping down to the middle.
	_pair(img, 1, 22, 3, 1, _hex("4a2414"))
	_pair(img, 4, 21, 2, 1, _hex("4a2414"))
	_pair(img, 6, 20, 2, 1, _hex("4a2414"))
	# Narrowed red eyes.
	_pair(img, 2, 24, 6, 4, _hex("f8f0ea"))
	_pair(img, 3, 24, 4, 4, _hex("d23a28"))
	_pair(img, 4, 25, 2, 2, _hex("8a1810"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, _hex("1a0a08"))
	_pair(img, 2, 28, 6, 1, _hex("3a1a12"))
	# Blush, nose, and a small flat, slightly wobbly mouth.
	_pair(img, 6, 31, 5, 2, _hex("f4b0b0"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 28, 43, 4, 1, _hex("4a2a24"))
	_fill(img, 32, 42, 4, 1, _hex("4a2a24"))
	# The black choker shows at the bottom of the neck.
	_fill(img, 18, 60, 28, 3, _hex("1a1a1e"))
	return img


## Idrith: pale and freckled, gentle half-closed yellow-green eyes, a shy
## smile, rosy cheeks, long blonde hair with a side-swept fringe.
func _face_idrith() -> Image:
	var skin := _hex("fdf0e6")
	var skin_d := _hex("ead8ca")
	var img := _face_base(_hex("e8d08a"), _hex("c8ae68"), _hex("f8e8b0"), skin, skin_d,
		[18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 21, 19, 18, 17, 17, 18, 18, 19, 19, 20, 20, 20, 21, 21, 21, 22, 22])
	# Soft, raised brows.
	_pair(img, 3, 20, 4, 1, _hex("b89858"))
	# Content, half-lidded eyes: the lid covers the top half.
	_pair(img, 2, 26, 6, 3, _hex("f8f2ea"))
	_pair(img, 3, 26, 4, 3, _hex("b8c030"))
	_pair(img, 4, 26, 2, 2, _hex("6a7010"))
	_pair(img, 1, 25, 8, 1, _hex("2a1a10"))
	_pair(img, 8, 25, 1, 2, _hex("2a1a10"))
	_pair(img, 2, 24, 6, 1, skin_d)
	# Freckles over the nose and cheeks, and a blush.
	for p in [Vector2i(26, 32), Vector2i(28, 33), Vector2i(30, 32), Vector2i(33, 32), Vector2i(35, 33), Vector2i(37, 32), Vector2i(27, 34), Vector2i(36, 34), Vector2i(29, 34), Vector2i(34, 34)]:
		_fill(img, p.x, p.y, 1, 1, _hex("d0a080"))
	_pair(img, 7, 31, 5, 2, _hex("f6b4b4"))
	_fill(img, 31, 36, 2, 1, skin_d)
	# A small, shy smile.
	_fill(img, 30, 43, 4, 1, _hex("8a4a40"))
	_pair(img, 2, 42, 1, 1, _hex("8a4a40"))
	# The gray collar of her cloak at the neck.
	_fill(img, 16, 58, 32, 6, _hex("7a7a7e"))
	return img


## Ottilie, the librarian: fair and lined, silver hair parted neatly, kind
## gray-blue eyes behind spectacles (the frames are modeled), smile lines.
func _face_ottilie() -> Image:
	var skin := _hex("f2d2bc")
	var skin_d := _hex("dcb8a0")
	var img := _face_base(_hex("d8d8e0"), _hex("b0b0bc"), _hex("f0f0f6"), skin, skin_d,
		[17, 17, 17, 18, 18, 18, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17])
	_pair(img, 3, 21, 5, 1, _hex("a8a8b4"))
	_pair(img, 3, 24, 5, 4, _hex("f4ece4"))
	_pair(img, 4, 24, 3, 4, _hex("5a7898"))
	_pair(img, 5, 25, 1, 2, _hex("23303e"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 2, 23, 7, 1, _hex("5a4038"))
	# Smile lines at the eyes and mouth, a soft blush, a gentle smile.
	_pair(img, 9, 25, 1, 2, skin_d)
	_pair(img, 6, 31, 4, 2, _hex("eab0a0"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_pair(img, 5, 39, 1, 3, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("8a4a44"))
	_pair(img, 3, 41, 1, 1, _hex("8a4a44"))
	return img


## Marigold, the shopkeeper: ginger hair, a face full of freckles, bright
## green eyes and a big welcoming grin.
func _face_marigold() -> Image:
	var skin := _hex("f6d6c0")
	var skin_d := _hex("e0bca4")
	var img := _face_base(_hex("d0602a"), _hex("a8461c"), _hex("e8783a"), skin, skin_d,
		[20, 21, 22, 21, 20, 21, 22, 22, 21, 20, 21, 22, 21, 20, 20, 21, 22, 21, 20, 21, 22, 22, 21, 20, 21, 22, 21, 20])
	_pair(img, 3, 21, 5, 1, _hex("a8461c"))
	_pair(img, 3, 24, 5, 5, _hex("f4ece4"))
	_pair(img, 3, 24, 4, 5, _hex("3a8a3a"))
	_pair(img, 4, 25, 2, 3, _hex("1a3a1a"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 2, 23, 6, 1, _hex("3a1a10"))
	for p in [Vector2i(25, 31), Vector2i(27, 32), Vector2i(29, 31), Vector2i(34, 31), Vector2i(36, 32), Vector2i(38, 31),
			Vector2i(24, 33), Vector2i(28, 34), Vector2i(35, 34), Vector2i(39, 33), Vector2i(26, 35), Vector2i(37, 35)]:
		_fill(img, p.x, p.y, 1, 1, _hex("c8865a"))
	_fill(img, 31, 35, 2, 1, skin_d)
	# A wide open grin.
	_fill(img, 27, 41, 10, 1, _hex("3a1410"))
	_fill(img, 28, 42, 8, 2, _hex("8a2a2a"))
	_fill(img, 29, 42, 6, 1, _hex("f4f0ec"))
	_pair(img, 5, 40, 1, 1, _hex("3a1410"))
	return img


## Clover, the rancher: sun-browned, dark eyes, thick brows, a confident
## lopsided smile and a little scar on the chin.
func _face_clover() -> Image:
	var skin := _hex("b07a52")
	var skin_d := _hex("946240")
	var img := _face_base(_hex("2a1c16"), _hex("1a100c"), _hex("3e2a20"), skin, skin_d,
		[19, 19, 20, 20, 21, 21, 22, 22, 21, 21, 20, 20, 19, 19, 19, 19, 20, 20, 21, 21, 22, 22, 21, 21, 20, 20, 19, 19])
	_pair(img, 2, 21, 6, 2, _hex("1a100c"))
	_pair(img, 3, 24, 5, 4, _hex("efe4da"))
	_pair(img, 3, 24, 4, 4, _hex("3a2216"))
	_pair(img, 4, 25, 2, 2, _hex("140a06"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 2, 23, 6, 1, _hex("140a06"))
	_pair(img, 6, 31, 4, 2, _hex("a8603e"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("4a1e14"))
	_fill(img, 35, 41, 2, 1, _hex("4a1e14"))
	_fill(img, 33, 47, 3, 1, _hex("c89878"))
	return img


## The reflection picked by the chrome material's view-space normal: bright
## sky above a white horizon band, the dark ground below, and two diagonal
## glints (OoT's metal reflections are this kind of soft, banded picture).
## Firebuns III: long straight brown hair parted from a sharp widow's peak,
## heavy brows slanting down to a scowl, narrowed brown eyes with pale
## blue-white whites, a small hard-set mouth (his picture, at adult size).
func _face_firebuns() -> Image:
	var skin := _hex("f6d2a6")
	var skin_d := _hex("dcb088")
	var hair := _hex("8a4e2c")
	var hair_d := _hex("6a3820")
	var hair_l := _hex("a8643a")
	var img := _face_base(hair, hair_d, hair_l, skin, skin_d,
		[13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 13, 13, 13])
	# Hair falling straight past the cheeks.
	_pair(img, 13, 20, 3, 36, hair)
	_pair(img, 12, 22, 1, 34, hair_d)
	# Heavy brows angled down toward the nose.
	_pair(img, 1, 21, 3, 2, _hex("4a2414"))
	_pair(img, 4, 20, 3, 2, _hex("4a2414"))
	_pair(img, 7, 19, 2, 2, _hex("4a2414"))
	# Narrowed eyes: pale blue-white, brown iris, a heavy upper lid.
	_pair(img, 2, 24, 6, 3, _hex("e4eef6"))
	_pair(img, 3, 24, 3, 3, _hex("6a3a1e"))
	_pair(img, 4, 25, 1, 1, _hex("1a0e08"))
	_pair(img, 1, 23, 8, 1, _hex("2a140a"))
	_pair(img, 2, 27, 6, 1, _hex("c09070"))
	# A frown crease, the nose, and a small flat mouth.
	_fill(img, 31, 19, 2, 3, skin_d)
	_fill(img, 31, 28, 2, 7, _hex("ffe0bc"))
	_pair(img, 1, 34, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("5a2a1e"))
	_pair(img, 3, 43, 1, 1, _hex("8a5040"))
	return img


## Mara, the Scourge of Bunsriel (Chapter V): skin as gray as old marble,
## black hair cut hard across the brow, eyes like coals (glowing red, no
## whites), dark lips set in a thin line, and a pale scar down one cheek.
func _face_mara() -> Image:
	var skin := _hex("b8b0b8")
	var skin_d := _hex("8e8690")
	var hair := _hex("141018")
	var hair_d := _hex("08060a")
	var hair_l := _hex("2a2230")
	var img := _face_base(hair, hair_d, hair_l, skin, skin_d,
		[19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19])
	_pair(img, 13, 20, 2, 34, hair)
	# Straight dark brows, low over the eyes.
	_pair(img, 1, 21, 8, 1, _hex("0a080c"))
	# The eyes: two coals.
	_pair(img, 2, 24, 6, 3, _hex("2a0a0a"))
	_pair(img, 3, 24, 4, 2, _hex("ff3a1a"))
	_pair(img, 4, 24, 2, 1, _hex("ffc08a"))
	_pair(img, 2, 27, 6, 1, skin_d)
	# The scar down her left cheek.
	_fill(img, 39, 22, 1, 16, _hex("dcd6dc"))
	# Nose, and dark thin lips.
	_fill(img, 31, 28, 2, 7, _hex("c8c0c8"))
	_pair(img, 1, 34, 2, 1, skin_d)
	_fill(img, 28, 42, 8, 1, _hex("3a1424"))
	_fill(img, 29, 43, 6, 1, _hex("5a2a3a"))
	return img


## A Sapphire Order mage's face, deep in the shadow of the hood: dark blue,
## with only two cold glowing eyes and the gleam of a sapphire on the brow.

## Lothelye, the Cosmic Deity: luminous fair skin, bright white hair with a
## center parting, calm half-lidded golden eyes, a faint knowing smile and a
## small gold star on her brow.
func _face_lothelye() -> Image:
	var skin := _hex("fbf0ea")
	var skin_d := _hex("eadad2")
	var img := _face_base(_hex("f4f4fa"), _hex("d4d4e6"), _hex("ffffff"), skin, skin_d,
		[22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 13, 12, 12, 12, 12, 12, 12, 13, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22])
	# The center parting.
	_fill(img, 31, 0, 2, 13, _hex("d4d4e6"))
	# Fine, high brows.
	_pair(img, 3, 20, 5, 1, _hex("c8c8dc"))
	# Serene half-lidded eyes: gold irises under a soft lid, long lashes.
	_pair(img, 2, 26, 6, 3, _hex("fbf6ee"))
	_pair(img, 3, 26, 4, 3, _hex("e0a830"))
	_pair(img, 4, 26, 2, 2, _hex("8a5a10"))
	_pair(img, 5, 26, 1, 1, _hex("ffffff"))
	_pair(img, 1, 25, 8, 1, _hex("6a5a7a"))
	_pair(img, 8, 24, 2, 2, _hex("6a5a7a"))
	_pair(img, 2, 24, 6, 1, _hex("e2cede"))
	# The gold star on her brow.
	_fill(img, 31, 15, 2, 5, _hex("ffd860"))
	_fill(img, 29, 17, 6, 1, _hex("ffd860"))
	_fill(img, 32, 17, 1, 1, _hex("fff4c0"))
	# Faint rose on the cheeks, the nose, and a small, knowing smile.
	_pair(img, 6, 32, 4, 2, _hex("f6d0d4"))
	_fill(img, 31, 36, 2, 1, skin_d)
	_fill(img, 30, 43, 4, 1, _hex("c07888"))
	_pair(img, 2, 42, 1, 1, _hex("c07888"))
	# A gold collar at the neck.
	_fill(img, 16, 59, 32, 5, _hex("e8c060"))
	return img


## Avalon (Val), Keeper of the Stars: fair skin, short blue hair cut in a
## soft bob with a sweeping fringe, big kind brown eyes, rosy cheeks and a
## warm, gentle smile. A little silver star clip sits over her left temple.
func _face_avalon() -> Image:
	var skin := _hex("fcece2")
	var skin_d := _hex("ecd4c6")
	var skin_l := _hex("fff6ee")
	var img := _face_base(_hex("4a7ce0"), _hex("3058b0"), _hex("7aa8f6"), skin, skin_d,
		[20, 21, 21, 22, 22, 21, 20, 19, 18, 18, 17, 17, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 22, 22])
	_pair(img, 3, 31, 6, 4, skin_l)
	# Soft, raised brows (a gentle, open look).
	_pair(img, 3, 20, 4, 1, _hex("5a82d8"))
	# Big warm brown eyes with long lashes and bright catchlights.
	_pair(img, 2, 24, 6, 6, _hex("fbf6f0"))
	_pair(img, 3, 24, 4, 6, _hex("8a5232"))
	_pair(img, 3, 27, 4, 3, _hex("a8683e"))
	_pair(img, 4, 25, 2, 4, _hex("3e200e"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 3, 28, 1, 1, _hex("f0d8c0"))
	_pair(img, 1, 23, 8, 1, _hex("1e1430"))
	_pair(img, 8, 22, 2, 2, _hex("1e1430"))
	_pair(img, 2, 30, 5, 1, skin_d)
	# Rosy cheeks, the nose, and a sweet smile.
	_pair(img, 6, 32, 5, 2, _hex("f6b8bc"))
	_pair(img, 7, 34, 3, 1, skin.lerp(_hex("f6b8bc"), 0.5))
	_fill(img, 31, 36, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("b85866"))
	_pair(img, 3, 41, 1, 1, _hex("b85866"))
	_fill(img, 30, 43, 4, 1, _hex("ec98a4"))
	# A fine silver chain at the neck.
	_fill(img, 18, 60, 28, 1, _hex("d8e2f4"))
	return img


## Serielye, goddess of destruction and balance (the user's art, Beta 1.5.0):
## pale skin, long silver-gray hair with a heavy side fringe swept over her
## right eye, so only her left shows: red, calm and unreadable. A dark cross
## marked on the brow, green streaks running down from the eyes like old
## tears, a level, unsmiling mouth, and a black choker at the throat.
func _face_serielye() -> Image:
	var hair := _hex("b8bcc8")
	var hair_d := _hex("8a8e9c")
	var hair_l := _hex("e0e2ea")
	var skin := _hex("f4e6de")
	var skin_d := _hex("dcc8bc")
	var img := _face_base(hair, hair_d, hair_l, skin, skin_d,
		[30, 31, 31, 32, 32, 31, 30, 28, 26, 24, 22, 21, 20, 20, 20, 21, 21, 21, 22, 22, 21, 21, 21, 22, 22, 22, 22, 22])
	# The fringe sweeping down over her right eye (the left of the picture).
	for i in 10:
		_fill(img, 18 + i, 20, 1, 12 - absi(i - 5), hair_d if i % 3 == 0 else hair)
	_fill(img, 19, 31, 9, 1, hair_d)
	# Her left eye (picture right): a level brow, the red eye under heavy lids.
	_fill(img, 35, 22, 6, 1, hair_d)
	_fill(img, 34, 25, 6, 4, _hex("f6eeea"))
	_fill(img, 35, 25, 4, 4, _hex("a8141e"))
	_fill(img, 36, 26, 2, 2, _hex("4a060a"))
	_fill(img, 38, 25, 1, 1, _hex("ffd8d8"))
	_fill(img, 33, 24, 8, 1, _hex("1a1418"))
	_fill(img, 34, 29, 6, 1, skin_d)
	# The green streaks from both eyes, down the cheeks.
	for x in [28, 36, 38]:
		_fill(img, x, 30, 1, 6, _hex("3a8a52"))
		_fill(img, x, 36, 1, 2, _hex("2a6a3e"))
	# The dark cross on the brow.
	_fill(img, 31, 13, 2, 7, _hex("2a1418"))
	_fill(img, 29, 15, 6, 2, _hex("2a1418"))
	# The nose, and a level mouth that gives nothing away.
	_fill(img, 31, 36, 2, 1, skin_d)
	_fill(img, 29, 43, 6, 1, _hex("9a5a5e"))
	# The black choker.
	_fill(img, 18, 58, 28, 3, _hex("141016"))
	_fill(img, 31, 61, 2, 3, _hex("c8b070"))
	return img


## A townsperson's face (Beta 1.5.0, tools/folk_specs.gd): skin, hair and
## eyes from the spec; a beard or a mustache, the lines of an older face, a
## child's round cheeks, a bald crown; always a friendly little smile.
func _face_folk(spec: Dictionary) -> Image:
	var skin := _hex(String(spec.skin))
	var skin_d := skin.darkened(0.1)
	var skin_l := skin.lightened(0.08)
	var bald: bool = spec.get("style", "") == "bald"
	var hair := _hex(String(spec.hair))
	var hair_d := hair.darkened(0.22)
	var hair_l := hair.lightened(0.18)
	var child: bool = float(spec.get("height", 1.0)) < 0.75
	var fringe: Array = []
	for i in 28:
		fringe.append(16 if bald else (20 + int(2.0 * sin(i * 0.9))))
	var img := _face_base(skin if bald else hair, skin_d if bald else hair_d, skin_l if bald else hair_l, skin, skin_d, fringe)
	if bald:
		_fill(img, 18, 8, 28, 12, skin)
	_pair(img, 3, 31, 6, 4, skin_l)
	# Brows, eyes (bigger on children), the nose.
	var brow := hair_d if not bald else _hex("8a8a8a")
	_pair(img, 3, 22, 5, 1, brow)
	var eh := 5 if child else 4
	_pair(img, 2, 24, 6, eh, _hex("f8f4f0"))
	_pair(img, 3, 24, 4, eh, _hex(String(spec.eyes)))
	_pair(img, 4, 25, 2, eh - 2, _hex(String(spec.eyes)).darkened(0.55))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, hair_d.darkened(0.3))
	_fill(img, 31, 35, 2, 1, skin_d)
	if child:
		_pair(img, 6, 32, 5, 2, _hex("f4a8a8"))
	if spec.get("lines", false):
		_pair(img, 9, 27, 2, 1, skin_d.darkened(0.08))
		_pair(img, 7, 38, 1, 4, skin_d.darkened(0.06))
		_fill(img, 26, 19, 12, 1, skin_d)
	# The mouth: a small smile.
	_fill(img, 29, 43, 6, 1, _hex("a85a54"))
	_pair(img, 3, 42, 1, 1, _hex("a85a54"))
	match String(spec.get("beard", "")):
		"full":
			for y in range(38, 58):
				var half := 13 - maxi(0, (y - 50))
				_fill(img, 32 - half, y, half * 2, 1, hair if y % 3 else hair_d)
			_fill(img, 28, 43, 8, 1, _hex("6a3a34"))
		"mous":
			_fill(img, 26, 40, 12, 2, hair_d)
	return img


## Himeko, the self-styled Princess of Haven Village: fair skin, glossy black
## hair in a hime cut (blunt bangs straight across the brow, side locks cut
## square at the cheeks), big brown eyes under thick lashes, lids lowered a
## touch (she is looking down on you, kindly), fine raised brows, a hint of
## rose on the cheeks and a small, pleased, one-sided smile.
func _face_himeko() -> Image:
	var hair := _hex("16141c")
	var hair_d := _hex("0a090e")
	var hair_l := _hex("34304a")
	var skin := _hex("fae6d8")
	var skin_d := _hex("ead0be")
	var img := _face_base(hair, hair_d, hair_l, skin, skin_d,
		[21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21])
	# The blunt edge of the bangs, and their sheen.
	_fill(img, 18, 20, 28, 1, hair_d)
	_fill(img, 20, 14, 24, 1, hair_l)
	# Side locks hanging straight down past the cheeks, cut square.
	_pair(img, 12, 19, 3, 22, hair)
	_pair(img, 13, 19, 1, 22, hair_l)
	_pair(img, 12, 40, 3, 1, hair_d)
	# Fine brows, arched and raised.
	_pair(img, 3, 22, 2, 1, hair_d)
	_pair(img, 5, 21, 3, 1, hair_d)
	# Big brown eyes, the lids a little lowered, thick lashes flicking out.
	_pair(img, 2, 25, 6, 5, _hex("fbf6f0"))
	_pair(img, 3, 25, 4, 5, _hex("7a4422"))
	_pair(img, 4, 26, 2, 3, _hex("3a1c0c"))
	_pair(img, 4, 27, 1, 1, _hex("1a0c06"))
	_pair(img, 5, 26, 1, 1, _hex("ffffff"))
	_pair(img, 3, 29, 1, 1, _hex("b07a4a"))
	_pair(img, 1, 24, 8, 1, _hex("0e0a10"))
	_pair(img, 2, 25, 6, 1, _hex("2a1a20"))
	_pair(img, 8, 23, 2, 2, _hex("0e0a10"))
	_pair(img, 2, 30, 5, 1, skin_d)
	# A touch of rose on the cheeks.
	_pair(img, 6, 32, 4, 2, _hex("f6c4c4"))
	# The nose, and a small smile turned up on one side only.
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 29, 43, 5, 1, _hex("b84a5a"))
	_fill(img, 34, 42, 1, 1, _hex("b84a5a"))
	_fill(img, 30, 44, 3, 1, _hex("e88a96"))
	# The white under-collar of her kimono at the neck.
	_fill(img, 18, 59, 28, 5, _hex("f8f4ee"))
	_fill(img, 30, 59, 4, 5, _hex("b8182a"))
	return img


## Hilde of the mountain hut: weathered fair skin with ruddy cheeks, pale
## blue eyes in smile lines, gray-blonde hair swept back under her hat.
func _face_hilde() -> Image:
	var skin := _hex("f0c8b0")
	var skin_d := _hex("d8aa92")
	var img := _face_base(_hex("c8bc98"), _hex("a89c7a"), _hex("e0d6b4"), skin, skin_d,
		[16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16, 16])
	_pair(img, 3, 21, 5, 1, _hex("8a7a5a"))
	_pair(img, 2, 24, 6, 4, _hex("f4f0ea"))
	_pair(img, 3, 24, 4, 4, _hex("6aa0d0"))
	_pair(img, 4, 25, 2, 2, _hex("2a4a6a"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, _hex("4a3424"))
	# Smile lines and ruddy cheeks.
	_pair(img, 9, 27, 1, 2, skin_d)
	_pair(img, 6, 31, 5, 3, _hex("e8907a"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 28, 42, 8, 1, _hex("7a3a30"))
	_pair(img, 4, 41, 1, 1, _hex("7a3a30"))
	# Her fur collar at the neck.
	_fill(img, 16, 58, 32, 6, _hex("f2f0ea"))
	return img


## Tansy of Castle Town: freckles, bright green eyes, one brow up, a sly grin,
## short auburn hair under her cap.
func _face_tansy() -> Image:
	var skin := _hex("f4d4bc")
	var skin_d := _hex("dcb8a0")
	var img := _face_base(_hex("a8482a"), _hex("84361e"), _hex("c4603a"), skin, skin_d,
		[20, 19, 18, 18, 19, 21, 20, 19, 18, 19, 21, 22, 20, 19, 18, 19, 20, 22, 21, 19, 18, 19, 21, 20, 19, 20, 21, 22])
	# One brow cocked.
	_fill(img, 18, 21, 5, 1, _hex("6a2a14"))
	_fill(img, 41, 20, 5, 1, _hex("6a2a14"))
	_pair(img, 2, 24, 6, 4, _hex("f8f0e8"))
	_pair(img, 3, 24, 4, 4, _hex("3aa04a"))
	_pair(img, 4, 25, 2, 2, _hex("164a1e"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, _hex("2a1408"))
	for pt in [Vector2i(25, 32), Vector2i(27, 33), Vector2i(29, 32), Vector2i(34, 32), Vector2i(36, 33), Vector2i(38, 32), Vector2i(26, 34), Vector2i(37, 34)]:
		_fill(img, pt.x, pt.y, 1, 1, _hex("c08060"))
	_fill(img, 31, 35, 2, 1, skin_d)
	# The sly grin: higher on one side.
	_fill(img, 28, 43, 5, 1, _hex("7a3424"))
	_fill(img, 33, 42, 3, 1, _hex("7a3424"))
	_fill(img, 36, 41, 1, 1, _hex("7a3424"))
	return img

## Elder Maud of Ashwick: an old face, lined at the eyes and mouth, soft gray
## eyes, a tired mouth that has not smiled much lately, white hair under a
## gray headscarf.
func _face_maud() -> Image:
	var skin := _hex("e8c4a8")
	var skin_d := _hex("cca68c")
	var img := _face_base(_hex("e8e6e0"), _hex("ccc8c0"), _hex("f4f2ee"), skin, skin_d,
		[15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 15])
	_pair(img, 3, 21, 5, 1, _hex("b8b4ac"))
	_pair(img, 2, 24, 6, 3, _hex("f0ece4"))
	_pair(img, 3, 24, 4, 3, _hex("8a9098"))
	_pair(img, 4, 25, 2, 2, _hex("3a3e44"))
	_pair(img, 1, 23, 8, 1, _hex("5a4a3e"))
	# Lines at the eyes, under them, and down from the nose.
	_pair(img, 9, 24, 2, 1, skin_d)
	_pair(img, 9, 26, 2, 1, skin_d)
	_pair(img, 3, 28, 5, 1, skin_d)
	_pair(img, 7, 36, 1, 5, skin_d)
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 28, 42, 8, 1, _hex("8a5a4a"))
	_pair(img, 4, 43, 1, 1, _hex("8a5a4a"))
	# The scarf across the brow.
	_fill(img, 0, 13, 64, 3, _hex("7a7874"))
	return img


## Wren the gravekeeper: pale, dark hair, heavy-lidded dark eyes, a small
## patient smile.
func _face_wren() -> Image:
	var skin := _hex("f0d8c8")
	var skin_d := _hex("d4baa8")
	var img := _face_base(_hex("2a2226"), _hex("1a1418"), _hex("3e3438"), skin, skin_d,
		[18, 19, 20, 21, 22, 22, 21, 20, 19, 18, 18, 19, 20, 21, 21, 20, 19, 18, 18, 19, 20, 21, 22, 22, 21, 20, 19, 18])
	_pair(img, 3, 22, 5, 1, _hex("1a1418"))
	_pair(img, 2, 25, 6, 3, _hex("f4f0ec"))
	_pair(img, 3, 25, 4, 3, _hex("4a3a44"))
	_pair(img, 4, 26, 2, 2, _hex("1a1418"))
	# Heavy lids.
	_pair(img, 1, 24, 8, 2, _hex("a8908a"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("8a5a5a"))
	_pair(img, 3, 41, 1, 1, _hex("8a5a5a"))
	return img


## Odile, the old guard of Batela Keep: weathered brown skin, hard brown eyes,
## a pale scar down through the left brow, a set jaw, short black hair.
func _face_odile() -> Image:
	var skin := _hex("c8946e")
	var skin_d := _hex("aa785a")
	var img := _face_base(_hex("1e1a1a"), _hex("120e0e"), _hex("342e2e"), skin, skin_d,
		[14, 14, 15, 15, 16, 16, 15, 15, 14, 14, 15, 15, 16, 16, 15, 15, 14, 14, 15, 15, 16, 16, 15, 15, 14, 14, 15, 15])
	_fill(img, 18, 20, 7, 2, _hex("1e1a1a"))
	_fill(img, 39, 20, 7, 2, _hex("1e1a1a"))
	_pair(img, 2, 24, 6, 3, _hex("f0e8e0"))
	_pair(img, 3, 24, 4, 3, _hex("6a4224"))
	_pair(img, 4, 25, 2, 2, _hex("2a1608"))
	_pair(img, 1, 23, 8, 1, _hex("2a1608"))
	# The scar.
	for i in 9:
		_fill(img, 21 + i / 3, 17 + i, 1, 1, _hex("e8c0a0"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 27, 42, 10, 1, _hex("6a3a2a"))
	_fill(img, 26, 47, 12, 1, skin_d)
	return img


## Tamsin of Ashwick, ten years old: freckles everywhere, big hazel eyes, a
## gap-toothed grin, a mop of brown curls.
func _face_tamsin() -> Image:
	var skin := _hex("f4d6c0")
	var skin_d := _hex("dcbaa4")
	var img := _face_base(_hex("6a4428"), _hex("4e3018"), _hex("8a5a38"), skin, skin_d,
		[18, 20, 22, 21, 19, 18, 20, 22, 21, 19, 18, 20, 22, 21, 19, 18, 20, 22, 21, 19, 18, 20, 22, 21, 19, 18, 20, 22])
	_pair(img, 3, 22, 5, 1, _hex("4e3018"))
	_pair(img, 2, 24, 7, 5, _hex("fcf6f0"))
	_pair(img, 3, 25, 5, 4, _hex("8a7a3a"))
	_pair(img, 4, 26, 3, 3, _hex("2a2010"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	for pt in [Vector2i(24, 32), Vector2i(26, 33), Vector2i(28, 32), Vector2i(25, 34), Vector2i(35, 32), Vector2i(37, 33), Vector2i(39, 32), Vector2i(38, 34), Vector2i(30, 31), Vector2i(33, 31)]:
		_fill(img, pt.x, pt.y, 1, 1, _hex("c8885a"))
	_fill(img, 31, 35, 2, 1, skin_d)
	# The grin, with a gap in it.
	_fill(img, 27, 41, 10, 1, _hex("7a3424"))
	_fill(img, 28, 42, 8, 2, _hex("f8f4f0"))
	_fill(img, 31, 42, 2, 2, _hex("7a3424"))
	_fill(img, 27, 44, 10, 1, _hex("7a3424"))
	return img



## Captain Rowena of the Haven Guard: sun-browned, steady gray eyes under
## straight dark brows, a firm mouth, auburn hair cropped short under her
## helm, a small white scar on the chin.
func _face_rowena() -> Image:
	var skin := _hex("d8a888")
	var skin_d := _hex("bc8c6c")
	var img := _face_base(_hex("8a3a22"), _hex("6a2814"), _hex("aa5434"), skin, skin_d,
		[15, 15, 16, 16, 16, 17, 17, 16, 16, 15, 15, 16, 16, 17, 17, 16, 16, 15, 15, 16, 16, 16, 17, 17, 16, 16, 15, 15])
	_pair(img, 2, 21, 6, 1, _hex("3a1a10"))
	_pair(img, 2, 24, 6, 3, _hex("f4ece4"))
	_pair(img, 3, 24, 4, 3, _hex("6a7884"))
	_pair(img, 4, 25, 2, 2, _hex("1e262e"))
	_pair(img, 5, 24, 1, 1, _hex("ffffff"))
	_pair(img, 1, 23, 8, 1, _hex("2a1610"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 28, 42, 8, 1, _hex("7a3a2e"))
	_fill(img, 33, 47, 2, 1, _hex("f0d4c0"))
	return img


## A soldier of the Haven Guard: plain and tired, brown eyes, short brown
## hair (the helm's cheek guards cover the rest).
func _face_soldier() -> Image:
	var skin := _hex("e8c0a0")
	var skin_d := _hex("cca484")
	var img := _face_base(_hex("5a3a24"), _hex("442a18"), _hex("74503a"), skin, skin_d,
		[15, 16, 16, 17, 16, 15, 16, 17, 16, 15, 16, 16, 17, 16, 15, 16, 17, 16, 15, 16, 16, 17, 16, 15, 16, 17, 16, 15])
	_pair(img, 3, 22, 5, 1, _hex("3a2414"))
	_pair(img, 2, 24, 6, 3, _hex("f4ece4"))
	_pair(img, 3, 24, 4, 3, _hex("5a3a20"))
	_pair(img, 4, 25, 2, 2, _hex("1e1208"))
	_pair(img, 1, 23, 8, 1, _hex("2a1a10"))
	# Tired shadows under the eyes.
	_pair(img, 2, 27, 6, 1, skin_d)
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("7a4a3a"))
	return img


## Posy, a refugee girl of Castle Town (about eight): round cheeks, big blue
## eyes, two blonde pigtails, a worried little mouth.
func _face_posy() -> Image:
	var skin := _hex("fae0cc")
	var skin_d := _hex("e2c4b0")
	var img := _face_base(_hex("e8c060"), _hex("c8a040"), _hex("f8dc8a"), skin, skin_d,
		[18, 18, 19, 19, 20, 20, 19, 19, 18, 18, 19, 19, 20, 20, 19, 19, 18, 18, 19, 19, 20, 20, 19, 19, 18, 18, 19, 19])
	_pair(img, 3, 22, 5, 1, _hex("b89040"))
	_pair(img, 2, 24, 7, 5, _hex("fcf8f4"))
	_pair(img, 3, 25, 5, 4, _hex("4a7ac8"))
	_pair(img, 4, 26, 3, 3, _hex("1a2a4a"))
	_pair(img, 5, 25, 1, 1, _hex("ffffff"))
	_pair(img, 6, 32, 5, 2, _hex("f4a8a8"))
	_fill(img, 31, 35, 2, 1, skin_d)
	_fill(img, 29, 42, 6, 1, _hex("b05a5a"))
	_pair(img, 3, 43, 1, 1, _hex("b05a5a"))
	return img


func _face_mage() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(_hex("141830"))
	for y in range(19, 64):
		_fill(img, 18, y, 28, 1, _hex("0c0e1e"))
	_pair(img, 3, 25, 5, 3, _hex("8ad8ff"))
	_pair(img, 4, 26, 2, 1, _hex("ffffff"))
	_fill(img, 30, 15, 4, 4, _hex("3a7aff"))
	return img


func _chrome_env() -> Image:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		var v := float(y) / (s - 1)
		var col: Color
		if v < 0.56:
			col = _hex("a4b8d8").lerp(_hex("e4ecfa"), v / 0.56)
		elif v < 0.63:
			col = _hex("ffffff")
		elif v < 0.7:
			col = _hex("ffffff").lerp(_hex("6a6a74"), (v - 0.63) / 0.07)
		else:
			col = _hex("6a6a74").lerp(_hex("3a3436"), (v - 0.7) / 0.3)
		for x in s:
			var u := float(x) / (s - 1)
			var c := col * (0.92 + 0.08 * cos((u - 0.5) * PI))
			var d1 := absf((u - v) * 0.7 + 0.12)
			var d2 := absf((u - v) * 0.7 - 0.2)
			if d1 < 0.025 or d2 < 0.015:
				c = Color(1, 1, 1)
			img.set_pixel(x, y, Color(clampf(c.r, 0, 1), clampf(c.g, 0, 1), clampf(c.b, 0, 1)))
	return img


## OoT's button background (gButtonBackgroundTex): a soft-edged disc, drawn
## white so the HUD tints it (B green, A blue, C yellow). A rim a little
## brighter than the middle, a glossy highlight up top and a darker lower edge
## give it the slightly plasticky look of the N64 buttons. Anti-aliased by
## supersampling 4x4 per texel.
func _hud_button() -> Image:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var acc := Color(0, 0, 0, 0)
			for sy in 4:
				for sx in 4:
					var p := Vector2(x + (sx + 0.5) / 4.0, y + (sy + 0.5) / 4.0) / s * 2.0 - Vector2.ONE
					var r := p.length()
					if r > 0.97:
						continue
					var v := 0.78
					v += smoothstep(0.78, 0.92, r) * 0.18          # bright rim
					v -= smoothstep(0.92, 0.97, r) * 0.25          # darker outer lip
					v -= clampf(p.y, 0.0, 1.0) * 0.12              # shade toward the bottom
					var gloss := clampf(1.0 - (p - Vector2(-0.18, -0.48)).length() / 0.42, 0.0, 1.0)
					v += gloss * gloss * 0.35
					var a := 0.82 + smoothstep(0.78, 0.92, r) * 0.15
					acc += Color(v, v, v, a)
			acc /= 16.0
			if acc.a > 0.0:
				acc = Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, acc.a)
			img.set_pixel(x, y, Color(clampf(acc.r, 0, 1), clampf(acc.g, 0, 1), clampf(acc.b, 0, 1), acc.a))
	return img


## OoT's life hearts (prim 255,70,50 over an env 50,40,60 rim): a red heart
## with a dark rim and a small shine. `fill` 2 = full, 1 = the left half,
## 0 = an empty heart (just the dark body and rim). 32x32, supersampled.
func _hud_heart(fill: int) -> Image:
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var red := Color8(255, 70, 50)
	var rim := Color8(50, 40, 60)
	var empty := Color8(70, 30, 30)
	for y in s:
		for x in s:
			var acc := Color(0, 0, 0, 0)
			for sy in 4:
				for sx in 4:
					var u := (x + (sx + 0.5) / 4.0) / s
					var v := (y + (sy + 0.5) / 4.0) / s
					# Classic implicit heart, point down.
					var hx := (u - 0.5) * 2.5
					var hy := (0.56 - v) * 2.5
					var f := pow(hx * hx + hy * hy - 1.0, 3.0) - hx * hx * hy * hy * hy
					if f > 0.0:
						continue
					var ix := hx * 1.22
					var iy := hy * 1.22 + 0.06
					var inner := pow(ix * ix + iy * iy - 1.0, 3.0) - ix * ix * iy * iy * iy <= 0.0
					var col := rim
					if inner:
						var lit := fill == 2 or (fill == 1 and u < 0.5)
						col = red if lit else empty
						if lit and (Vector2(u, v) - Vector2(0.32, 0.3)).length() < 0.08:
							col = col.lerp(Color(1, 0.85, 0.8), 0.6)
					acc += Color(col.r, col.g, col.b, 1.0)
			acc /= 16.0
			if acc.a > 0.0:
				acc = Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, acc.a)
			img.set_pixel(x, y, acc)
	return img


## A soft four-pointed star for magic sparkles (additive, so black is clear).
func _sparkle() -> Image:
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x + 0.5 - s * 0.5, y + 0.5 - s * 0.5) / (s * 0.5)
			var core := clampf(1.0 - d.length() * 2.2, 0.0, 1.0)
			var rays := clampf(1.0 - absf(d.x) * 9.0, 0.0, 1.0) * clampf(1.0 - absf(d.y), 0.0, 1.0) 				+ clampf(1.0 - absf(d.y) * 9.0, 0.0, 1.0) * clampf(1.0 - absf(d.x), 0.0, 1.0)
			var a := clampf(core + rays * 0.8, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img


## Head wrap for the Cinder Goblin: heavy brow, dark eye pits (the glowing
## eyes are separate geometry), flat nose, wide mouth with teeth.
func _face_goblin() -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var skin := _hex("8a4630")
	var skin_d := _hex("6a3222")
	var skin_dd := _hex("4a2016")
	var skin_l := _hex("a35a3c")
	img.fill(skin)
	_fill(img, 0, 0, 12, 64, skin_d)
	_fill(img, 52, 0, 12, 64, skin_d)
	# Warty speckles.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 70:
		img.set_pixel(rng.randi_range(0, 63), rng.randi_range(0, 63), skin_d if i % 2 == 0 else skin_l)
	# Brow ridge and eye pits.
	_fill(img, 18, 18, 28, 4, skin_l)
	_pair(img, 2, 22, 8, 6, skin_dd)
	_fill(img, 30, 22, 4, 5, skin_d)
	# Snout: broad nose with flared nostrils.
	_fill(img, 27, 28, 10, 8, skin_l)
	_pair(img, 1, 34, 3, 2, _hex("2a0e08"))
	# Wide mouth with a row of teeth and tusks.
	_fill(img, 19, 42, 26, 6, _hex("2a0e08"))
	for x in range(20, 44, 3):
		_fill(img, x, 42, 2, 2, _hex("d8cdaa"))
	_pair(img, 9, 44, 3, 4, _hex("e6dcb8"))
	_fill(img, 18, 48, 28, 3, skin_d)
	return img


## Tileable value noise quantised to a small palette.
func _noise(size: int, pal_hex: Array, cell: int, grain: float, seed_value: int) -> Image:
	return _noise_stretched(size, pal_hex, Vector2i(cell, cell), grain, seed_value)


func _noise_stretched(size: int, pal_hex: Array, cells: Vector2i, grain: float, seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pal: Array[Color] = []
	for h in pal_hex:
		pal.append(_hex(h))
	var grid := []
	for y in cells.y:
		var row := []
		for x in cells.x:
			row.append(rng.randf())
		grid.append(row)
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var gx := float(x) / size * cells.x
			var gy := float(y) / size * cells.y
			var x0 := int(gx) % cells.x
			var y0 := int(gy) % cells.y
			var x1 := (x0 + 1) % cells.x
			var y1 := (y0 + 1) % cells.y
			var fx := smoothstep(0.0, 1.0, gx - floor(gx))
			var fy := smoothstep(0.0, 1.0, gy - floor(gy))
			var v: float = lerp(lerp(grid[y0][x0], grid[y0][x1], fx), lerp(grid[y1][x0], grid[y1][x1], fx), fy)
			v = lerp(v, rng.randf(), grain)
			img.set_pixel(x, y, pal[clampi(int(v * pal.size()), 0, pal.size() - 1)])
	return img


## Half-timbered plaster: dark frame, posts and braces over light infill.
func _timber() -> Image:
	var img := _noise(64, ["d6d0c2", "e0dacd", "e9e4d8", "f2eee4"], 4, 0.35, 30)
	var beam := _hex("4a3628")
	for i in 64:
		for t in 3:
			img.set_pixel(i, t, beam)
			img.set_pixel(i, 63 - t, beam)
			img.set_pixel(i, 30 + t, beam)
			img.set_pixel(t, i, beam)
			img.set_pixel(63 - t, i, beam)
			img.set_pixel(31 + t - 1, i, beam)
	for i in 28:
		for t in 2:
			img.set_pixel(3 + i, 3 + i + t, beam)
			img.set_pixel(60 - i, 33 + i + t - 1, beam)
	return img


## Roof tiles: staggered rows with a dark lip.
func _tiles(img: Image) -> Image:
	var s := img.get_width()
	for y in s:
		var row := y / 4
		for x in s:
			if y % 4 == 3:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.35))
			elif (x + (3 if row % 2 == 1 else 0)) % 6 == 0:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.18))
	return img


func _door() -> Image:
	var img := _noise_stretched(32, ["5e4128", "6b4b2e", "785534", "84603b"], Vector2i(2, 8), 0.5, 31)
	for y in 32:
		for x in 32:
			if x % 8 == 7:
				img.set_pixel(x, y, _hex("3a2816"))
			if y in [5, 6, 25, 26]:
				img.set_pixel(x, y, _hex("2c2c34"))
	return img


## Stone slab with a carved ring for the sealed doors.
func _seal() -> Image:
	var img := _noise(32, ["7c8090", "888c9c", "9498a8", "a0a4b2"], 4, 0.35, 32)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length()
			if absf(d - 11.0) < 1.0 or x < 2 or x > 29 or y < 2 or y > 29:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.35))
	return img


## 64x64: eight rows of bricks, four to a row, with a frieze of carved waves
## across the middle two rows. Stretched over wall stretches about 6 m long.
func _shrine_wall() -> Image:
	var img := _noise(64, ["4e6e76", "587a82", "62868c", "6c9096"], 8, 0.4, 40)
	var mortar := _hex("2e4248")
	for y in 64:
		var row := y / 8
		for x in 64:
			var off := 8 if row % 2 == 1 else 0
			if row == 3 or row == 4:
				# The wave band: a smooth surface with a carved wave line.
				var c := _hex("6a9aa0")
				var wy := 31.5 + sin((x / 64.0) * TAU * 4.0) * 3.0
				if absf(y - wy) < 1.2:
					c = _hex("2e5a64")
				elif absf(y - wy - 3.0) < 0.8:
					c = _hex("8ab8bc")
				if y == 24 or y == 39:
					c = mortar
				img.set_pixel(x, y, c)
			elif y % 8 == 7 or (x + off) % 16 == 15:
				img.set_pixel(x, y, mortar)
			elif y % 8 == 0:
				img.set_pixel(x, y, img.get_pixel(x, y).lightened(0.1))
	return img


func _cobbles() -> Image:
	var img := _noise(32, ["8a8a90", "96969c", "a2a2a8", "aeaeb4"], 4, 0.5, 33)
	for y in 32:
		for x in 32:
			var row := y / 6
			if y % 6 == 5 or (x + (4 if row % 2 == 1 else 0)) % 8 == 7:
				img.set_pixel(x, y, _hex("55555c"))
	return img


func _strata(img: Image) -> Image:
	var s := img.get_width()
	for y in s:
		if y % 8 == 0 or y % 8 == 5:
			for x in s:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.25))
	return img


func _bricks(img: Image) -> Image:
	var s := img.get_width()
	var mortar := _hex("4a463f")
	for y in s:
		var row := y / 8
		for x in s:
			var off := 8 if row % 2 == 1 else 0
			if y % 8 == 7 or (x + off) % 16 == 15:
				img.set_pixel(x, y, mortar)
			elif y % 8 == 0:
				img.set_pixel(x, y, img.get_pixel(x, y).lightened(0.12))
	return img


func _planks(img: Image) -> Image:
	var s := img.get_width()
	for y in s:
		if y % 8 == 7:
			for x in s:
				img.set_pixel(x, y, _hex("3a2816"))
	return img


func _save(img: Image, tex_name: String) -> void:
	var path := TEX_DIR + tex_name + ".png"
	var err := img.save_png(path)
	if err != OK:
		push_error("Failed to save texture %s: %s" % [tex_name, err])
		return
	# Lossless with mipmaps; textures clamp (never repeat) at the material level.
	var f := FileAccess.open(path + ".import", FileAccess.WRITE)
	f.store_string("""[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=0
""" % path)
	f.close()
