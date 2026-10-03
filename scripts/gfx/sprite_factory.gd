class_name SpriteFactory
extends RefCounted
## Procedurally generates every pixel-art sprite used by the game, so the project has no
## binary art assets. Textures are cached after the first request.
##
## Character sheets are 3 columns (stand, step A, step B) x 4 rows (down, left, right, up)
## of 16x24 frames.

const CHAR_W := 16
const CHAR_H := 24
const OUTLINE := Color("1a1220")
const EYE := Color("23182e")

const LOOKS := {
	"hero": {"skin": "f2c29b", "hair": "7a4527", "outfit": "2f63b5", "pants": "4a3a2a",
		"boots": "3a2a1c", "accent": "d9a83a", "cape": "b8323a"},
	"mage": {"skin": "f7d3b4", "hair": "f0d77a", "outfit": "6a3f9e", "pants": "4a2c6e",
		"boots": "3a2440", "accent": "e8c04a", "hat": "wizard", "hat_color": "4f2c7a",
		"robe": true, "long_hair": true},
	"hunter": {"skin": "d9a679", "hair": "3a2a22", "outfit": "5a8a3f", "pants": "6b4a2e",
		"boots": "3f2d1d", "accent": "a07040", "hat": "hood", "hat_color": "3f6e35",
		"quiver": true},
	"elder": {"skin": "e8b896", "hair": "e6e6e6", "outfit": "8a5a3a", "pants": "5a3a2a",
		"boots": "3a2a1c", "accent": "c9b27a", "robe": true, "beard": "f0f0f0"},
	"innkeeper": {"skin": "f0c09a", "hair": "a0402a", "outfit": "9a3a3a", "pants": "5a2a2a",
		"boots": "3a2020", "accent": "f2ece0", "robe": true, "long_hair": true, "apron": "f2ece0"},
	"merchant": {"skin": "e0ad84", "hair": "2a2a2a", "outfit": "d08a2a", "pants": "5a4a3a",
		"boots": "3a2a1c", "accent": "6a3a1a", "hat": "cap", "hat_color": "8a2a2a",
		"beard": "2a2a2a"},
	"child": {"skin": "f5cba7", "hair": "f0a030", "outfit": "3fa0a0", "pants": "2f5a7a",
		"boots": "5a3a2a", "accent": "f0f0f0"},
	"guard": {"skin": "e0b090", "hair": "5a3a2a", "outfit": "8a8f9a", "pants": "4a4f5a",
		"boots": "2a2a30", "accent": "c9a24a", "hat": "helmet", "hat_color": "b8bfca",
		"cape": "2f4f8f"},
	"fisher": {"skin": "d8a07a", "hair": "9a9a9a", "outfit": "5a7a9a", "pants": "3a4a5a",
		"boots": "3a2a1c", "accent": "c04a3a", "hat": "straw", "hat_color": "e0c070",
		"beard": "b0b0b0"},
}

static var _cache := {}


static func _c(hex: String) -> Color:
	return Color(hex)


# --------------------------------------------------------------------------
# Characters
# --------------------------------------------------------------------------

static func character_sheet(kind: String) -> Texture2D:
	var key := "char_" + kind
	if _cache.has(key):
		return _cache[key]
	var look: Dictionary = LOOKS.get(kind, LOOKS["hero"])
	var sheet := PixelCanvas.new(CHAR_W * 3, CHAR_H * 4)
	for frame in 3:
		var down := _draw_character(look, 0, frame)
		var side := _draw_character(look, 2, frame)
		var up := _draw_character(look, 3, frame)
		sheet.blit(down, frame * CHAR_W, 0)
		sheet.blit(side, frame * CHAR_W, CHAR_H, true)
		sheet.blit(side, frame * CHAR_W, CHAR_H * 2)
		sheet.blit(up, frame * CHAR_W, CHAR_H * 3)
	var tex := sheet.to_texture()
	_cache[key] = tex
	return tex


## dir: 0 = down/front, 2 = right/side, 3 = up/back. frame: 0 stand, 1 & 2 walking.
static func _draw_character(look: Dictionary, dir: int, frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(CHAR_W, CHAR_H)
	var skin := _c(look.skin)
	var hair := _c(look.hair)
	var outfit := _c(look.outfit)
	var outfit_dark := outfit.darkened(0.25)
	var outfit_light := outfit.lightened(0.2)
	var pants := _c(look.pants)
	var boots := _c(look.boots)
	var accent := _c(look.accent)
	var robe: bool = look.get("robe", false)
	var long_hair: bool = look.get("long_hair", false)
	var hat: String = look.get("hat", "")
	var hat_color := _c(look.get("hat_color", "ffffff"))
	var cape_hex: String = look.get("cape", "")
	var beard_hex: String = look.get("beard", "")
	var arm_swing: int = [0, 1, -1][frame]

	# ---- Things behind the body ----
	if cape_hex != "":
		var cape := _c(cape_hex)
		match dir:
			0:
				cv.rect(3, 12, 1, 7, cape.darkened(0.2))
				cv.rect(12, 12, 1, 7, cape.darkened(0.2))
			2:
				cv.rect(4, 12, 2, 8, cape)
				cv.px(3, 19, cape)
	if look.get("quiver", false):
		var quiver := Color("7a4a2a")
		match dir:
			0:
				cv.px(11, 10, Color("e8e8e8"))
			2:
				cv.rect(4, 11, 2, 5, quiver)
				cv.px(4, 10, Color("e8e8e8"))
				cv.px(5, 9, Color("e8e8e8"))
	if long_hair:
		match dir:
			0:
				cv.rect(3, 6, 1, 7, hair.darkened(0.15))
				cv.rect(12, 6, 1, 7, hair.darkened(0.15))
			2:
				cv.rect(3, 6, 2, 7, hair.darkened(0.1))

	# ---- Legs ----
	if robe:
		var hem := 0 if frame == 0 else 1
		match dir:
			0, 3:
				cv.rect(5, 21, 2, 1 + (1 if frame == 2 else 0), boots)
				cv.rect(9, 21, 2, 1 + (1 if frame == 1 else 0), boots)
			2:
				cv.rect(7 + hem, 21, 3, 1, boots)
	else:
		match dir:
			0, 3:
				var lift_l := 1 if frame == 1 else 0
				var lift_r := 1 if frame == 2 else 0
				cv.rect(7, 17, 2, 1, pants)
				cv.rect(5, 17, 2, 4 - lift_l, pants)
				cv.rect(9, 17, 2, 4 - lift_r, pants)
				cv.rect(5, 21 - lift_l, 2, 2, boots)
				cv.rect(9, 21 - lift_r, 2, 2, boots)
			2:
				match frame:
					0:
						cv.rect(7, 17, 3, 4, pants)
						cv.rect(7, 21, 4, 2, boots)
					1:
						cv.rect(5, 17, 2, 3, pants.darkened(0.15))
						cv.rect(4, 20, 3, 2, boots.darkened(0.15))
						cv.rect(9, 17, 2, 4, pants)
						cv.rect(9, 21, 3, 2, boots)
					2:
						cv.rect(8, 17, 2, 3, pants.darkened(0.15))
						cv.rect(8, 20, 3, 2, boots.darkened(0.15))
						cv.rect(5, 17, 2, 4, pants)
						cv.rect(5, 21, 3, 2, boots)

	# ---- Torso ----
	match dir:
		0, 3:
			if robe:
				cv.rect(5, 12, 6, 5, outfit)
				cv.rect(4, 17, 8, 4, outfit)
				cv.rect(4, 20, 8, 1, outfit_dark)
			else:
				cv.rect(5, 12, 6, 5, outfit)
			if dir == 0:
				cv.rect(7, 12, 2, 1, outfit_light)
				if look.has("apron"):
					cv.rect(6, 14, 4, 6, _c(look.apron))
			cv.rect(5, 16, 6, 1, accent)
			# Arms
			cv.rect(4, 12 + arm_swing, 1, 4, outfit_dark)
			cv.px(4, 16 + arm_swing, skin)
			cv.rect(11, 12 - arm_swing, 1, 4, outfit_dark)
			cv.px(11, 16 - arm_swing, skin)
		2:
			if robe:
				cv.rect(6, 12, 5, 5, outfit)
				cv.rect(5, 17, 7, 4, outfit)
				cv.rect(5, 20, 7, 1, outfit_dark)
			else:
				cv.rect(6, 12, 5, 5, outfit)
			if look.has("apron"):
				cv.rect(10, 14, 1, 6, _c(look.apron))
			cv.rect(6, 16, 5, 1, accent)
			cv.rect(7 + arm_swing, 12, 2, 4, outfit_dark)
			cv.rect(7 + arm_swing, 16, 2, 1, skin)

	# Cape covers the back.
	if cape_hex != "" and dir == 3:
		var cape := _c(cape_hex)
		cv.rect(4, 12, 8, 8, cape)
		cv.rect(4, 19, 8, 1, cape.darkened(0.25))
		cv.rect(7, 12, 2, 1, cape.lightened(0.15))
	if look.get("quiver", false) and dir == 3:
		cv.rect(9, 11, 2, 6, Color("7a4a2a"))
		cv.px(9, 10, Color("e8e8e8"))
		cv.px(10, 9, Color("e8e8e8"))

	# ---- Head ----
	match dir:
		0:
			cv.rect(5, 6, 6, 5, skin)
			cv.rect(6, 11, 4, 1, skin)
			cv.rect(5, 3, 6, 1, hair)
			cv.rect(4, 4, 8, 2, hair)
			cv.rect(4, 6, 1, 3, hair)
			cv.rect(11, 6, 1, 3, hair)
			cv.px(5, 6, hair)
			cv.px(6, 6, hair.darkened(0.15))
			cv.px(9, 6, hair)
			cv.px(10, 6, hair)
			cv.rect(6, 8, 1, 2, EYE)
			cv.rect(9, 8, 1, 2, EYE)
			cv.px(5, 10, skin.darkened(0.08).lerp(Color("ff8080"), 0.25))
			cv.px(10, 10, skin.darkened(0.08).lerp(Color("ff8080"), 0.25))
		2:
			cv.rect(8, 6, 4, 5, skin)
			cv.rect(7, 11, 4, 1, skin)
			cv.px(12, 8, skin)
			cv.rect(5, 3, 6, 1, hair)
			cv.rect(4, 4, 8, 2, hair)
			cv.rect(4, 6, 4, 4, hair)
			cv.px(8, 6, hair)
			cv.px(11, 6, hair)
			cv.rect(5, 10, 2, 1, hair.darkened(0.15))
			cv.rect(10, 8, 1, 2, EYE)
		3:
			cv.rect(5, 3, 6, 1, hair)
			cv.rect(4, 4, 8, 7, hair)
			cv.rect(5, 11, 6, 1, hair.darkened(0.2))
			cv.rect(6, 5, 1, 4, hair.lightened(0.1))
			if long_hair:
				cv.rect(4, 11, 8, 2, hair.darkened(0.1))

	# ---- Headwear ----
	match hat:
		"wizard":
			var band := accent
			cv.rect(2, 5, 12, 1, hat_color.darkened(0.15))
			cv.rect(4, 3, 8, 2, hat_color)
			cv.rect(4, 4, 8, 1, band)
			cv.rect(5, 2, 6, 1, hat_color)
			cv.rect(6, 1, 4, 1, hat_color)
			cv.rect(7, 0, 2, 1, hat_color)
			cv.px(10 if dir != 2 else 5, 0, hat_color.lightened(0.1))
		"helmet":
			cv.rect(5, 2, 6, 1, hat_color)
			cv.rect(4, 3, 8, 4, hat_color)
			cv.rect(7, 0, 2, 2, accent.lerp(Color("c03030"), 0.7))
			match dir:
				0:
					cv.rect(4, 7, 1, 2, hat_color.darkened(0.15))
					cv.rect(11, 7, 1, 2, hat_color.darkened(0.15))
					cv.rect(5, 6, 6, 1, hat_color.darkened(0.3))
				2:
					cv.rect(4, 7, 4, 3, hat_color.darkened(0.1))
				3:
					cv.rect(4, 7, 8, 4, hat_color.darkened(0.1))
		"hood":
			match dir:
				0:
					cv.rect(5, 2, 6, 1, hat_color)
					cv.rect(4, 3, 8, 3, hat_color)
					cv.rect(3, 4, 1, 8, hat_color.darkened(0.1))
					cv.rect(12, 4, 1, 8, hat_color.darkened(0.1))
					cv.rect(4, 6, 1, 6, hat_color)
					cv.rect(11, 6, 1, 6, hat_color)
				2:
					cv.rect(5, 2, 6, 1, hat_color)
					cv.rect(4, 3, 8, 3, hat_color)
					cv.rect(3, 4, 5, 8, hat_color)
					cv.px(2, 6, hat_color.darkened(0.15))
				3:
					cv.rect(5, 2, 6, 1, hat_color)
					cv.rect(4, 3, 8, 9, hat_color)
					cv.rect(7, 1, 2, 1, hat_color.darkened(0.1))
					cv.rect(6, 10, 4, 2, hat_color.darkened(0.15))
		"cap":
			cv.rect(4, 3, 8, 3, hat_color)
			cv.rect(5, 2, 6, 1, hat_color)
			match dir:
				0:
					cv.rect(4, 6, 8, 1, hat_color.darkened(0.25))
				2:
					cv.rect(9, 6, 5, 1, hat_color.darkened(0.25))
		"straw":
			cv.rect(4, 2, 8, 3, hat_color)
			cv.rect(4, 4, 8, 1, accent)
			cv.rect(1, 5, 14, 1, hat_color.darkened(0.1))

	if beard_hex != "":
		var beard := _c(beard_hex)
		match dir:
			0:
				cv.rect(5, 10, 6, 3, beard)
				cv.rect(6, 13, 4, 1, beard)
				cv.rect(7, 10, 2, 1, beard.darkened(0.15))
			2:
				cv.rect(9, 10, 3, 3, beard)
				cv.px(9, 13, beard)

	cv.auto_shade()
	cv.outline(OUTLINE)
	return cv


# --------------------------------------------------------------------------
# Enemies (two 24x24 idle frames side by side)
# --------------------------------------------------------------------------

static func enemy_sheet(kind: String) -> Texture2D:
	var key := "enemy_" + kind
	if _cache.has(key):
		return _cache[key]
	var sheet := PixelCanvas.new(48, 24)
	for frame in 2:
		var cv: PixelCanvas
		match kind:
			"slime":
				cv = _draw_slime(frame, Color("5fcf6a"), false)
			"king_slime":
				cv = _draw_slime(frame, Color("5a7bea"), true)
			"bat":
				cv = _draw_bat(frame)
			"mushroom":
				cv = _draw_mushroom(frame)
			_:
				cv = _draw_slime(frame, Color("cf5f5f"), false)
		sheet.blit(cv, frame * 24, 0)
	var tex := sheet.to_texture()
	_cache[key] = tex
	return tex


static func _draw_slime(frame: int, base: Color, crowned: bool) -> PixelCanvas:
	var cv := PixelCanvas.new(24, 24)
	var rx := 9.0 if frame == 0 else 10.0
	var ry := 7.0 if frame == 0 else 6.0
	var cy := 23.0 - ry - 1.0
	cv.ellipse(12, cy, rx, ry, base)
	cv.rect(int(12 - rx + 1), int(cy + ry - 2), int(rx * 2 - 2), 2, base.darkened(0.3))
	cv.shade_ellipse(12, cy, rx, ry, base.lightened(0.3), base, base.darkened(0.25))
	# Glossy highlight
	cv.rect(7, int(cy - ry + 2), 3, 1, Color(1, 1, 1, 0.95))
	cv.rect(6, int(cy - ry + 3), 2, 2, Color(1, 1, 1, 0.85))
	# Face
	var ey := int(cy)
	cv.rect(9, ey - 1, 1, 3, EYE)
	cv.rect(15, ey - 1, 1, 3, EYE)
	cv.px(9, ey - 1, Color.WHITE)
	cv.px(15, ey - 1, Color.WHITE)
	cv.rect(11, ey + 3, 3, 1, base.darkened(0.5))
	if crowned:
		var gold := Color("f2c84a")
		var top := int(cy - ry) - 4
		cv.rect(7, top + 2, 10, 3, gold)
		cv.px(7, top, gold)
		cv.px(7, top + 1, gold)
		cv.px(12, top, gold)
		cv.px(11, top + 1, gold)
		cv.px(12, top + 1, gold)
		cv.px(16, top, gold)
		cv.px(16, top + 1, gold)
		cv.px(12, top + 3, Color("e03050"))
		cv.px(9, top + 3, Color("50c0f0"))
		cv.px(15, top + 3, Color("50c0f0"))
		cv.rect(7, top + 4, 10, 1, gold.darkened(0.3))
	cv.outline(OUTLINE)
	return cv


static func _draw_bat(frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(24, 24)
	var body := Color("6a4a8a")
	var wing := Color("4a3060")
	var oy := 0 if frame == 0 else 2
	# Wings
	if frame == 0:
		for i in 7:
			cv.vline(11 - i - 2, 6 + oy + i / 2, 12 + oy - i / 3, wing)
			cv.vline(12 + i + 2, 6 + oy + i / 2, 12 + oy - i / 3, wing)
		cv.vline(2, 9 + oy, 11 + oy, wing.lightened(0.15))
		cv.vline(21, 9 + oy, 11 + oy, wing.lightened(0.15))
	else:
		for i in 7:
			cv.vline(11 - i - 2, 10 + oy, 14 + oy + i / 2, wing)
			cv.vline(12 + i + 2, 10 + oy, 14 + oy + i / 2, wing)
	cv.ellipse(12, 12 + oy, 4.5, 4.5, body)
	cv.shade_ellipse(12, 12 + oy, 4.5, 4.5, body.lightened(0.2), body, body.darkened(0.25))
	# Ears
	cv.px(9, 7 + oy, body)
	cv.px(9, 8 + oy, body)
	cv.px(14, 7 + oy, body)
	cv.px(14, 8 + oy, body)
	# Eyes & fangs
	cv.px(10, 11 + oy, Color("ff4a4a"))
	cv.px(13, 11 + oy, Color("ff4a4a"))
	cv.px(11, 14 + oy, Color.WHITE)
	cv.px(12, 14 + oy, Color.WHITE)
	cv.outline(OUTLINE)
	return cv


static func _draw_mushroom(frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(24, 24)
	var cap := Color("d0443a")
	var stem := Color("f0e2c0")
	var squash := 0 if frame == 0 else 1
	# Cap (flattened underneath)
	var cy := 9 + squash
	var ry := 6.5 - squash * 0.5
	cv.ellipse(12, cy, 10.5, ry, cap)
	cv.shade_ellipse(12, cy, 10.5, ry, cap.lightened(0.2), cap, cap.darkened(0.25))
	cv.rect(0, cy + 4, 24, 24, Color(0, 0, 0, 0))
	cv.rect(3, cy + 3, 18, 1, cap.darkened(0.35))
	# Spots
	cv.rect(7, cy - 3, 2, 2, Color.WHITE)
	cv.rect(13, cy - 4, 3, 2, Color.WHITE)
	cv.rect(17, cy - 1, 2, 2, Color("f0f0f0"))
	cv.rect(4, cy, 2, 1, Color("f0f0f0"))
	cv.rect(10, cy, 2, 2, Color("f0f0f0"))
	# Stem with face
	var top := cy + 4
	cv.rect(8, top, 8, 21 - top, stem)
	cv.rect(8, top, 8, 1, stem.darkened(0.3))
	cv.rect(14, top, 2, 21 - top, stem.darkened(0.12))
	cv.rect(10, top + 2, 1, 2, EYE)
	cv.rect(13, top + 2, 1, 2, EYE)
	cv.rect(11, top + 5, 2, 1, Color("8a5a4a"))
	# Feet
	cv.rect(7, 21, 3, 2, stem.darkened(0.2))
	cv.rect(14, 21, 3, 2, stem.darkened(0.2))
	cv.outline(OUTLINE)
	return cv


# --------------------------------------------------------------------------
# Scenery
# --------------------------------------------------------------------------

static func tree(variant: int = 0) -> Texture2D:
	var key := "tree_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + variant * 77
	var cv := PixelCanvas.new(32, 48)
	var bark := Color("6b4528")
	cv.rect(13, 28, 6, 20, bark)
	cv.rect(13, 28, 2, 20, bark.lightened(0.15))
	cv.rect(17, 28, 2, 20, bark.darkened(0.25))
	cv.rect(11, 45, 10, 3, bark.darkened(0.1))
	cv.px(10, 47, bark.darkened(0.1))
	cv.px(21, 47, bark.darkened(0.1))
	var greens := [Color("2f6b2f"), Color("3f8a3a"), Color("5aa846"), Color("86c95a")]
	if variant == 2:
		greens = [Color("6b4a1f"), Color("a0602a"), Color("d08a30"), Color("f0b84a")]
	var blobs := [
		Vector3(16, 18, 12), Vector3(9, 24, 7), Vector3(23, 24, 7),
		Vector3(11, 12, 7), Vector3(21, 12, 7), Vector3(16, 8, 7),
	]
	for b in blobs:
		cv.ellipse(b.x, b.y, b.z, b.z * 0.9, greens[0])
	for b in blobs:
		cv.ellipse(b.x - 1, b.y - 1, b.z - 1.5, (b.z - 1.5) * 0.9, greens[1])
	for b in blobs:
		cv.ellipse(b.x - 2, b.y - 2.5, b.z * 0.45, b.z * 0.38, greens[2])
	for i in 40:
		var x := rng.randi_range(4, 28)
		var y := rng.randi_range(3, 30)
		if cv.get_px(x, y) == greens[1]:
			cv.px(x, y, greens[0] if rng.randf() < 0.6 else greens[2])
		elif cv.get_px(x, y) == greens[2] and rng.randf() < 0.5:
			cv.px(x, y, greens[3])
	if variant == 1:
		# Little red fruit
		for i in 6:
			var x := rng.randi_range(7, 25)
			var y := rng.randi_range(8, 26)
			if cv.is_filled(x, y):
				cv.px(x, y, Color("e04040"))
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func pine() -> Texture2D:
	if _cache.has("pine"):
		return _cache["pine"]
	var cv := PixelCanvas.new(24, 48)
	var bark := Color("5a3a22")
	cv.rect(10, 38, 4, 10, bark)
	cv.rect(12, 38, 2, 10, bark.darkened(0.2))
	var dark := Color("1f4a3a")
	var mid := Color("2f6b4a")
	var light := Color("4f9060")
	var tiers := [[4, 14, 9], [12, 24, 10], [21, 34, 11], [29, 41, 11]]
	for t in tiers:
		var top: int = t[0]
		var bottom: int = t[1]
		var half: int = t[2]
		for y in range(top, bottom + 1):
			var w := int(lerp(1.0, float(half), float(y - top) / float(bottom - top)))
			cv.hline(12 - w, 11 + w, y, mid)
			cv.hline(12, 11 + w, y, dark)
			if y % 3 == 0:
				cv.hline(12 - w, 12 - w + max(w / 2, 1), y, light)
		cv.hline(12 - half, 11 + half, bottom, dark.darkened(0.2))
	cv.rect(11, 1, 2, 4, mid)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["pine"] = tex
	return tex


static func bush() -> Texture2D:
	if _cache.has("bush"):
		return _cache["bush"]
	var cv := PixelCanvas.new(20, 14)
	var g := Color("3f8a3a")
	cv.ellipse(6, 8, 5.5, 5, g)
	cv.ellipse(14, 8, 5.5, 5, g)
	cv.ellipse(10, 6, 6, 5.5, g)
	cv.shade_ellipse(10, 6, 6, 5.5, g.lightened(0.25), g, g.darkened(0.2))
	cv.rect(2, 11, 16, 2, g.darkened(0.3))
	cv.px(7, 5, Color("f0e060"))
	cv.px(13, 8, Color("f06090"))
	cv.px(4, 9, Color("f0f0f0"))
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["bush"] = tex
	return tex


static func grass_tuft(variant: int = 0) -> Texture2D:
	var key := "tuft_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + variant
	var cv := PixelCanvas.new(16, 12)
	var shades := [Color("2f6b2f"), Color("4a9a3f"), Color("6fbf4f"), Color("9ad66a")]
	if variant >= 2:
		shades = [Color("2a5a2a"), Color("3a7a35"), Color("569a44"), Color("78b85a")]
	for i in 11:
		var x := rng.randi_range(1, 14)
		var h := rng.randi_range(4, 11)
		var lean := rng.randi_range(-1, 1)
		var col: Color = shades[rng.randi_range(0, 3)]
		for k in h:
			var xx := x + (lean if k > h * 0.6 else 0)
			cv.px(xx, 11 - k, col.darkened(0.25) if k < 2 else col)
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func flowers(variant: int = 0) -> Texture2D:
	var key := "flowers_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var petal_colors := [Color("f06090"), Color("f0e060"), Color("8ab0ff"), Color("f0f0f0")]
	var petal: Color = petal_colors[variant % petal_colors.size()]
	var cv := PixelCanvas.new(14, 10)
	var stem := Color("3f8a3a")
	for p in [Vector2i(3, 3), Vector2i(9, 2), Vector2i(6, 5), Vector2i(11, 6)]:
		cv.vline(p.x, p.y + 1, 9, stem)
		cv.px(p.x - 1, p.y, petal)
		cv.px(p.x + 1, p.y, petal)
		cv.px(p.x, p.y - 1, petal)
		cv.px(p.x, p.y + 1, petal)
		cv.px(p.x, p.y, Color("ffd040"))
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func lamp_post() -> Texture2D:
	if _cache.has("lamp"):
		return _cache["lamp"]
	var cv := PixelCanvas.new(10, 30)
	var iron := Color("2f2f3a")
	cv.rect(4, 8, 2, 20, iron)
	cv.rect(3, 27, 4, 3, iron)
	cv.rect(2, 2, 6, 1, iron)
	cv.rect(3, 1, 4, 1, iron)
	cv.rect(2, 3, 1, 5, iron)
	cv.rect(7, 3, 1, 5, iron)
	cv.rect(3, 3, 4, 5, Color("ffe9a0"))
	cv.rect(4, 4, 2, 3, Color("fffbe8"))
	cv.rect(2, 8, 6, 1, iron)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["lamp"] = tex
	return tex


static func rock() -> Texture2D:
	if _cache.has("rock"):
		return _cache["rock"]
	var cv := PixelCanvas.new(18, 12)
	var g := Color("8a8a95")
	cv.ellipse(9, 7, 8, 5, g)
	cv.ellipse(6, 5, 4, 3, g)
	cv.shade_ellipse(9, 7, 8, 5, g.lightened(0.25), g, g.darkened(0.3))
	cv.rect(5, 6, 3, 1, g.darkened(0.3))
	cv.rect(12, 4, 2, 1, Color("5a8a4a"))
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["rock"] = tex
	return tex


static func signpost() -> Texture2D:
	if _cache.has("sign"):
		return _cache["sign"]
	var cv := PixelCanvas.new(14, 16)
	var wood := Color("a0703a")
	cv.rect(6, 8, 2, 8, wood.darkened(0.2))
	cv.rect(1, 1, 12, 8, wood)
	cv.rect(1, 8, 12, 1, wood.darkened(0.3))
	cv.hline(3, 10, 3, wood.darkened(0.4))
	cv.hline(3, 8, 5, wood.darkened(0.4))
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["sign"] = tex
	return tex


## Two frames: closed / open.
static func chest() -> Texture2D:
	if _cache.has("chest"):
		return _cache["chest"]
	var sheet := PixelCanvas.new(32, 16)
	for frame in 2:
		var cv := PixelCanvas.new(16, 16)
		var wood := Color("9a5a2a")
		var gold := Color("f2c84a")
		cv.rect(1, 7, 14, 8, wood)
		cv.rect(1, 14, 14, 1, wood.darkened(0.3))
		if frame == 0:
			cv.rect(1, 3, 14, 4, wood.lightened(0.1))
			cv.rect(2, 2, 12, 1, wood.lightened(0.1))
			cv.rect(1, 6, 14, 1, gold)
			cv.rect(7, 6, 2, 3, gold)
		else:
			cv.rect(1, 2, 14, 3, wood.darkened(0.2))
			cv.rect(2, 5, 12, 2, Color("2a1a10"))
			cv.rect(5, 5, 6, 1, gold.lightened(0.3))
		cv.rect(1, 7, 1, 8, gold.darkened(0.2))
		cv.rect(14, 7, 1, 8, gold.darkened(0.2))
		cv.outline(OUTLINE)
		sheet.blit(cv, frame * 16, 0)
	var tex := sheet.to_texture()
	_cache["chest"] = tex
	return tex


static func door() -> Texture2D:
	if _cache.has("door"):
		return _cache["door"]
	var cv := PixelCanvas.new(16, 24)
	var wood := Color("6b3f22")
	cv.rect(2, 4, 12, 20, wood)
	cv.rect(4, 2, 8, 2, wood)
	cv.rect(3, 3, 10, 1, wood)
	for x in [5, 8, 11]:
		cv.vline(x, 4, 23, wood.darkened(0.3))
	cv.rect(10, 13, 2, 2, Color("f2c84a"))
	cv.outline(Color("3a2a1c"))
	var tex := cv.to_texture()
	_cache["door"] = tex
	return tex


static func window() -> Texture2D:
	if _cache.has("window"):
		return _cache["window"]
	var cv := PixelCanvas.new(14, 14)
	var frame_c := Color("5a3a22")
	cv.rect(0, 0, 14, 14, frame_c)
	cv.rect(2, 2, 10, 10, Color("ffcf6a"))
	cv.rect(2, 2, 10, 4, Color("ffe7a8"))
	cv.vline(6, 2, 11, frame_c)
	cv.vline(7, 2, 11, frame_c)
	cv.hline(2, 11, 7, frame_c)
	cv.rect(0, 12, 14, 2, Color("8a5a32"))
	var tex := cv.to_texture()
	_cache["window"] = tex
	return tex


static func particle_dot() -> Texture2D:
	if _cache.has("dot"):
		return _cache["dot"]
	var cv := PixelCanvas.new(4, 4)
	cv.rect(1, 0, 2, 4, Color.WHITE)
	cv.rect(0, 1, 4, 2, Color.WHITE)
	var tex := cv.to_texture()
	_cache["dot"] = tex
	return tex
