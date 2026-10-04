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

# Shared palette
const TRANSPARENT := Color(0, 0, 0, 0)
const OFF_WHITE := Color("f0f0f0")
const GOLD := Color("f2c84a")
const FOLIAGE_GREEN := Color("3f8a3a")
const PETAL_PINK := Color("f06090")
const PETAL_YELLOW := Color("f0e060")
const PETAL_BLUE := Color("8ab0ff")

# Shading amounts for darkened()/lightened()
const SHADE_FAINT := 0.08
const SHADE_SUBTLE := 0.1
const SHADE_SOFT := 0.15
const SHADE_MEDIUM := 0.2
const SHADE_DARK := 0.25
const SHADE_HEAVY := 0.3

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

# Sheet layout
const CHAR_FRAMES := 3
const SHEET_ROW_DOWN := 0
const SHEET_ROW_LEFT := 1
const SHEET_ROW_RIGHT := 2
const SHEET_ROW_UP := 3
const SHEET_ROWS := 4

# Facing directions and animation frames
const DIR_DOWN := 0
const DIR_SIDE := 2
const DIR_UP := 3
const FRAME_STAND := 0
const FRAME_STEP_A := 1
const FRAME_STEP_B := 2
const ARM_SWING := [0, 1, -1]

# Character palette extras
const DEFAULT_HAT_HEX := "ffffff"
const QUIVER_BROWN := Color("7a4a2a")
const ARROW_FLETCH := Color("e8e8e8")
const BLUSH_PINK := Color("ff8080")
const BLUSH_MIX := 0.25
const PLUME_RED := Color("c03030")
const PLUME_MIX := 0.7

# Rows of the 16x24 frame (top to bottom)
const HAT_TIP_ROW := 0
const HAT_TOP := 2
const HEAD_TOP := 3
const BRIM_ROW := 5
const FACE_TOP := 6
const EYE_ROW := 8
const CHEEK_ROW := 10
const CHIN_ROW := 11
const TORSO_TOP := 12
const APRON_TOP := 14
const BELT_ROW := 16
const LEGS_TOP := 17
const BOOTS_TOP := 21

# Heights
const FACE_HEIGHT := CHIN_ROW - FACE_TOP
const TORSO_HEIGHT := LEGS_TOP - TORSO_TOP
const LEG_HEIGHT := BOOTS_TOP - LEGS_TOP
const BOOT_HEIGHT := 2
const ARM_LENGTH := 4
const EYE_HEIGHT := 2
const SIDEBURN_LENGTH := 3
const SIDE_HAIR_HEIGHT := 4
const HAIR_SHINE_LENGTH := 4
const LONG_HAIR_LENGTH := 7
const CAPE_LENGTH := 8
const APRON_HEIGHT := 6
const BEARD_LENGTH := 3
const HELMET_HEIGHT := 4
const HELMET_RIM_ROW := HEAD_TOP + HELMET_HEIGHT
const HELMET_SIDE_GUARD_HEIGHT := 3
const STRAW_CROWN_HEIGHT := 3

# Columns, front/back view
const HEAD_LEFT := 4
const HEAD_WIDTH := 8
const HEAD_RIGHT := HEAD_LEFT + HEAD_WIDTH - 1
const FACE_LEFT := 5
const FACE_WIDTH := 6
const FACE_RIGHT := FACE_LEFT + FACE_WIDTH - 1
const LEFT_EYE_X := 6
const RIGHT_EYE_X := 9
const CENTER_X := 7
const BODY_LEFT := 5
const BODY_WIDTH := 6
const ROBE_LEFT := BODY_LEFT - 1
const ROBE_WIDTH := BODY_WIDTH + 2
const LEFT_ARM_X := 4
const RIGHT_ARM_X := 11
const LEFT_LEG_X := 5
const RIGHT_LEG_X := 9
const LEG_WIDTH := 2
const APRON_LEFT := 6
const APRON_WIDTH := 4
const QUIVER_TOP := 11
const QUIVER_BACK_X := 9
const QUIVER_BACK_LENGTH := 6

# Columns, side view (facing right)
const SIDE_FACE_LEFT := 8
const SIDE_FACE_WIDTH := 4
const SIDE_EYE_X := 10
const SIDE_BODY_LEFT := 6
const SIDE_BODY_WIDTH := 5
const SIDE_ARM_X := 7
const SIDE_LEG_X := 7
const SIDE_FOOT_WIDTH := 3
const QUIVER_SIDE_LENGTH := 5

# Headwear
const WIZARD_BRIM_LEFT := 2
const WIZARD_BRIM_WIDTH := 12
const WIZARD_GLINT_X := 10
const WIZARD_GLINT_X_SIDE := 5
const CAP_BILL_X := 9
const CAP_BILL_LENGTH := 5
const STRAW_BRIM_LEFT := 1
const STRAW_BRIM_WIDTH := 14


static func character_sheet(kind: String) -> Texture2D:
	var key := "char_" + kind
	if _cache.has(key):
		return _cache[key]
	var look: Dictionary = LOOKS.get(kind, LOOKS["hero"])
	var sheet := PixelCanvas.new(CHAR_W * CHAR_FRAMES, CHAR_H * SHEET_ROWS)
	for frame in CHAR_FRAMES:
		var down := _draw_character(look, DIR_DOWN, frame)
		var side := _draw_character(look, DIR_SIDE, frame)
		var up := _draw_character(look, DIR_UP, frame)
		sheet.blit(down, frame * CHAR_W, CHAR_H * SHEET_ROW_DOWN)
		sheet.blit(side, frame * CHAR_W, CHAR_H * SHEET_ROW_LEFT, true)
		sheet.blit(side, frame * CHAR_W, CHAR_H * SHEET_ROW_RIGHT)
		sheet.blit(up, frame * CHAR_W, CHAR_H * SHEET_ROW_UP)
	var tex := sheet.to_texture()
	_cache[key] = tex
	return tex


## dir: DIR_DOWN (front), DIR_SIDE (facing right), DIR_UP (back).
## frame: FRAME_STAND, or FRAME_STEP_A / FRAME_STEP_B while walking.
static func _draw_character(look: Dictionary, dir: int, frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(CHAR_W, CHAR_H)
	var skin := _c(look.skin)
	var hair := _c(look.hair)
	var outfit := _c(look.outfit)
	var outfit_dark := outfit.darkened(SHADE_DARK)
	var outfit_light := outfit.lightened(SHADE_MEDIUM)
	var pants := _c(look.pants)
	var boots := _c(look.boots)
	var accent := _c(look.accent)
	var robe: bool = look.get("robe", false)
	var long_hair: bool = look.get("long_hair", false)
	var hat: String = look.get("hat", "")
	var hat_color := _c(look.get("hat_color", DEFAULT_HAT_HEX))
	var cape_hex: String = look.get("cape", "")
	var beard_hex: String = look.get("beard", "")
	var arm_swing: int = ARM_SWING[frame]

	# ---- Things behind the body ----
	if cape_hex != "":
		var cape := _c(cape_hex)
		match dir:
			DIR_DOWN:
				cv.rect(HEAD_LEFT - 1, TORSO_TOP, 1, CAPE_LENGTH - 1, cape.darkened(SHADE_MEDIUM))
				cv.rect(HEAD_RIGHT + 1, TORSO_TOP, 1, CAPE_LENGTH - 1, cape.darkened(SHADE_MEDIUM))
			DIR_SIDE:
				cv.rect(LEFT_ARM_X, TORSO_TOP, 2, CAPE_LENGTH, cape)
				cv.px(LEFT_ARM_X - 1, TORSO_TOP + CAPE_LENGTH - 1, cape)
	if look.get("quiver", false):
		match dir:
			DIR_DOWN:
				cv.px(QUIVER_BACK_X + 2, QUIVER_TOP - 1, ARROW_FLETCH)
			DIR_SIDE:
				cv.rect(LEFT_ARM_X, QUIVER_TOP, 2, QUIVER_SIDE_LENGTH, QUIVER_BROWN)
				cv.px(LEFT_ARM_X, QUIVER_TOP - 1, ARROW_FLETCH)
				cv.px(LEFT_ARM_X + 1, QUIVER_TOP - 2, ARROW_FLETCH)
	if long_hair:
		match dir:
			DIR_DOWN:
				cv.rect(HEAD_LEFT - 1, FACE_TOP, 1, LONG_HAIR_LENGTH, hair.darkened(SHADE_SOFT))
				cv.rect(HEAD_RIGHT + 1, FACE_TOP, 1, LONG_HAIR_LENGTH, hair.darkened(SHADE_SOFT))
			DIR_SIDE:
				cv.rect(HEAD_LEFT - 1, FACE_TOP, 2, LONG_HAIR_LENGTH, hair.darkened(SHADE_SUBTLE))

	# ---- Legs ----
	if robe:
		var hem := 0 if frame == FRAME_STAND else 1
		match dir:
			DIR_DOWN, DIR_UP:
				cv.rect(LEFT_LEG_X, BOOTS_TOP, LEG_WIDTH, 1 + (1 if frame == FRAME_STEP_B else 0), boots)
				cv.rect(RIGHT_LEG_X, BOOTS_TOP, LEG_WIDTH, 1 + (1 if frame == FRAME_STEP_A else 0), boots)
			DIR_SIDE:
				cv.rect(SIDE_LEG_X + hem, BOOTS_TOP, SIDE_FOOT_WIDTH, 1, boots)
	else:
		match dir:
			DIR_DOWN, DIR_UP:
				var lift_l := 1 if frame == FRAME_STEP_A else 0
				var lift_r := 1 if frame == FRAME_STEP_B else 0
				cv.rect(CENTER_X, LEGS_TOP, 2, 1, pants)
				cv.rect(LEFT_LEG_X, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT - lift_l, pants)
				cv.rect(RIGHT_LEG_X, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT - lift_r, pants)
				cv.rect(LEFT_LEG_X, BOOTS_TOP - lift_l, LEG_WIDTH, BOOT_HEIGHT, boots)
				cv.rect(RIGHT_LEG_X, BOOTS_TOP - lift_r, LEG_WIDTH, BOOT_HEIGHT, boots)
			DIR_SIDE:
				match frame:
					FRAME_STAND:
						cv.rect(SIDE_LEG_X, LEGS_TOP, SIDE_FOOT_WIDTH, LEG_HEIGHT, pants)
						cv.rect(SIDE_LEG_X, BOOTS_TOP, SIDE_FOOT_WIDTH + 1, BOOT_HEIGHT, boots)
					FRAME_STEP_A:
						cv.rect(LEFT_LEG_X, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT - 1, pants.darkened(SHADE_SOFT))
						cv.rect(LEFT_LEG_X - 1, BOOTS_TOP - 1, SIDE_FOOT_WIDTH, BOOT_HEIGHT, boots.darkened(SHADE_SOFT))
						cv.rect(RIGHT_LEG_X, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT, pants)
						cv.rect(RIGHT_LEG_X, BOOTS_TOP, SIDE_FOOT_WIDTH, BOOT_HEIGHT, boots)
					FRAME_STEP_B:
						cv.rect(SIDE_LEG_X + 1, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT - 1, pants.darkened(SHADE_SOFT))
						cv.rect(SIDE_LEG_X + 1, BOOTS_TOP - 1, SIDE_FOOT_WIDTH, BOOT_HEIGHT, boots.darkened(SHADE_SOFT))
						cv.rect(LEFT_LEG_X, LEGS_TOP, LEG_WIDTH, LEG_HEIGHT, pants)
						cv.rect(LEFT_LEG_X, BOOTS_TOP, SIDE_FOOT_WIDTH, BOOT_HEIGHT, boots)

	# ---- Torso ----
	match dir:
		DIR_DOWN, DIR_UP:
			if robe:
				cv.rect(BODY_LEFT, TORSO_TOP, BODY_WIDTH, TORSO_HEIGHT, outfit)
				cv.rect(ROBE_LEFT, LEGS_TOP, ROBE_WIDTH, LEG_HEIGHT, outfit)
				cv.rect(ROBE_LEFT, BOOTS_TOP - 1, ROBE_WIDTH, 1, outfit_dark)
			else:
				cv.rect(BODY_LEFT, TORSO_TOP, BODY_WIDTH, TORSO_HEIGHT, outfit)
			if dir == DIR_DOWN:
				cv.rect(CENTER_X, TORSO_TOP, 2, 1, outfit_light)
				if look.has("apron"):
					cv.rect(APRON_LEFT, APRON_TOP, APRON_WIDTH, APRON_HEIGHT, _c(look.apron))
			cv.rect(BODY_LEFT, BELT_ROW, BODY_WIDTH, 1, accent)
			# Arms
			cv.rect(LEFT_ARM_X, TORSO_TOP + arm_swing, 1, ARM_LENGTH, outfit_dark)
			cv.px(LEFT_ARM_X, TORSO_TOP + ARM_LENGTH + arm_swing, skin)
			cv.rect(RIGHT_ARM_X, TORSO_TOP - arm_swing, 1, ARM_LENGTH, outfit_dark)
			cv.px(RIGHT_ARM_X, TORSO_TOP + ARM_LENGTH - arm_swing, skin)
		DIR_SIDE:
			if robe:
				cv.rect(SIDE_BODY_LEFT, TORSO_TOP, SIDE_BODY_WIDTH, TORSO_HEIGHT, outfit)
				cv.rect(SIDE_BODY_LEFT - 1, LEGS_TOP, SIDE_BODY_WIDTH + 2, LEG_HEIGHT, outfit)
				cv.rect(SIDE_BODY_LEFT - 1, BOOTS_TOP - 1, SIDE_BODY_WIDTH + 2, 1, outfit_dark)
			else:
				cv.rect(SIDE_BODY_LEFT, TORSO_TOP, SIDE_BODY_WIDTH, TORSO_HEIGHT, outfit)
			if look.has("apron"):
				cv.rect(SIDE_BODY_LEFT + SIDE_BODY_WIDTH - 1, APRON_TOP, 1, APRON_HEIGHT, _c(look.apron))
			cv.rect(SIDE_BODY_LEFT, BELT_ROW, SIDE_BODY_WIDTH, 1, accent)
			cv.rect(SIDE_ARM_X + arm_swing, TORSO_TOP, 2, ARM_LENGTH, outfit_dark)
			cv.rect(SIDE_ARM_X + arm_swing, TORSO_TOP + ARM_LENGTH, 2, 1, skin)

	# Cape covers the back.
	if cape_hex != "" and dir == DIR_UP:
		var cape := _c(cape_hex)
		cv.rect(HEAD_LEFT, TORSO_TOP, HEAD_WIDTH, CAPE_LENGTH, cape)
		cv.rect(HEAD_LEFT, TORSO_TOP + CAPE_LENGTH - 1, HEAD_WIDTH, 1, cape.darkened(SHADE_DARK))
		cv.rect(CENTER_X, TORSO_TOP, 2, 1, cape.lightened(SHADE_SOFT))
	if look.get("quiver", false) and dir == DIR_UP:
		cv.rect(QUIVER_BACK_X, QUIVER_TOP, 2, QUIVER_BACK_LENGTH, QUIVER_BROWN)
		cv.px(QUIVER_BACK_X, QUIVER_TOP - 1, ARROW_FLETCH)
		cv.px(QUIVER_BACK_X + 1, QUIVER_TOP - 2, ARROW_FLETCH)

	# ---- Head ----
	match dir:
		DIR_DOWN:
			cv.rect(FACE_LEFT, FACE_TOP, FACE_WIDTH, FACE_HEIGHT, skin)
			cv.rect(FACE_LEFT + 1, CHIN_ROW, FACE_WIDTH - 2, 1, skin)
			cv.rect(HEAD_LEFT + 1, HEAD_TOP, HEAD_WIDTH - 2, 1, hair)
			cv.rect(HEAD_LEFT, HEAD_TOP + 1, HEAD_WIDTH, 2, hair)
			cv.rect(HEAD_LEFT, FACE_TOP, 1, SIDEBURN_LENGTH, hair)
			cv.rect(HEAD_RIGHT, FACE_TOP, 1, SIDEBURN_LENGTH, hair)
			# Bangs
			cv.px(FACE_LEFT, FACE_TOP, hair)
			cv.px(FACE_LEFT + 1, FACE_TOP, hair.darkened(SHADE_SOFT))
			cv.px(FACE_RIGHT - 1, FACE_TOP, hair)
			cv.px(FACE_RIGHT, FACE_TOP, hair)
			cv.rect(LEFT_EYE_X, EYE_ROW, 1, EYE_HEIGHT, EYE)
			cv.rect(RIGHT_EYE_X, EYE_ROW, 1, EYE_HEIGHT, EYE)
			cv.px(FACE_LEFT, CHEEK_ROW, skin.darkened(SHADE_FAINT).lerp(BLUSH_PINK, BLUSH_MIX))
			cv.px(FACE_RIGHT, CHEEK_ROW, skin.darkened(SHADE_FAINT).lerp(BLUSH_PINK, BLUSH_MIX))
		DIR_SIDE:
			cv.rect(SIDE_FACE_LEFT, FACE_TOP, SIDE_FACE_WIDTH, FACE_HEIGHT, skin)
			cv.rect(SIDE_FACE_LEFT - 1, CHIN_ROW, SIDE_FACE_WIDTH, 1, skin)
			cv.px(SIDE_FACE_LEFT + SIDE_FACE_WIDTH, EYE_ROW, skin)
			cv.rect(HEAD_LEFT + 1, HEAD_TOP, HEAD_WIDTH - 2, 1, hair)
			cv.rect(HEAD_LEFT, HEAD_TOP + 1, HEAD_WIDTH, 2, hair)
			cv.rect(HEAD_LEFT, FACE_TOP, SIDE_FACE_LEFT - HEAD_LEFT, SIDE_HAIR_HEIGHT, hair)
			cv.px(SIDE_FACE_LEFT, FACE_TOP, hair)
			cv.px(HEAD_RIGHT, FACE_TOP, hair)
			cv.rect(HEAD_LEFT + 1, CHEEK_ROW, 2, 1, hair.darkened(SHADE_SOFT))
			cv.rect(SIDE_EYE_X, EYE_ROW, 1, EYE_HEIGHT, EYE)
		DIR_UP:
			cv.rect(HEAD_LEFT + 1, HEAD_TOP, HEAD_WIDTH - 2, 1, hair)
			cv.rect(HEAD_LEFT, HEAD_TOP + 1, HEAD_WIDTH, CHIN_ROW - HEAD_TOP - 1, hair)
			cv.rect(HEAD_LEFT + 1, CHIN_ROW, HEAD_WIDTH - 2, 1, hair.darkened(SHADE_MEDIUM))
			cv.rect(HEAD_LEFT + 2, HEAD_TOP + 2, 1, HAIR_SHINE_LENGTH, hair.lightened(SHADE_SUBTLE))
			if long_hair:
				cv.rect(HEAD_LEFT, CHIN_ROW, HEAD_WIDTH, 2, hair.darkened(SHADE_SUBTLE))

	# ---- Headwear ----
	match hat:
		"wizard":
			var band := accent
			cv.rect(WIZARD_BRIM_LEFT, BRIM_ROW, WIZARD_BRIM_WIDTH, 1, hat_color.darkened(SHADE_SOFT))
			cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, 2, hat_color)
			cv.rect(HEAD_LEFT, HEAD_TOP + 1, HEAD_WIDTH, 1, band)
			cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
			cv.rect(HEAD_LEFT + 2, HAT_TOP - 1, HEAD_WIDTH - 4, 1, hat_color)
			cv.rect(CENTER_X, HAT_TIP_ROW, 2, 1, hat_color)
			cv.px(WIZARD_GLINT_X if dir != DIR_SIDE else WIZARD_GLINT_X_SIDE, HAT_TIP_ROW,
				hat_color.lightened(SHADE_SUBTLE))
		"helmet":
			cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
			cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, HELMET_HEIGHT, hat_color)
			cv.rect(CENTER_X, HAT_TIP_ROW, 2, 2, accent.lerp(PLUME_RED, PLUME_MIX))
			match dir:
				DIR_DOWN:
					cv.rect(HEAD_LEFT, HELMET_RIM_ROW, 1, 2, hat_color.darkened(SHADE_SOFT))
					cv.rect(HEAD_RIGHT, HELMET_RIM_ROW, 1, 2, hat_color.darkened(SHADE_SOFT))
					cv.rect(HEAD_LEFT + 1, HELMET_RIM_ROW - 1, HEAD_WIDTH - 2, 1, hat_color.darkened(SHADE_HEAVY))
				DIR_SIDE:
					cv.rect(HEAD_LEFT, HELMET_RIM_ROW, SIDE_FACE_LEFT - HEAD_LEFT, HELMET_SIDE_GUARD_HEIGHT,
						hat_color.darkened(SHADE_SUBTLE))
				DIR_UP:
					cv.rect(HEAD_LEFT, HELMET_RIM_ROW, HEAD_WIDTH, CHIN_ROW - HELMET_RIM_ROW,
						hat_color.darkened(SHADE_SUBTLE))
		"hood":
			match dir:
				DIR_DOWN:
					cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
					cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, FACE_TOP - HEAD_TOP, hat_color)
					cv.rect(HEAD_LEFT - 1, HEAD_TOP + 1, 1, TORSO_TOP - HEAD_TOP - 1, hat_color.darkened(SHADE_SUBTLE))
					cv.rect(HEAD_RIGHT + 1, HEAD_TOP + 1, 1, TORSO_TOP - HEAD_TOP - 1, hat_color.darkened(SHADE_SUBTLE))
					cv.rect(HEAD_LEFT, FACE_TOP, 1, TORSO_TOP - FACE_TOP, hat_color)
					cv.rect(HEAD_RIGHT, FACE_TOP, 1, TORSO_TOP - FACE_TOP, hat_color)
				DIR_SIDE:
					cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
					cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, FACE_TOP - HEAD_TOP, hat_color)
					cv.rect(HEAD_LEFT - 1, HEAD_TOP + 1, SIDE_FACE_LEFT - HEAD_LEFT + 1, TORSO_TOP - HEAD_TOP - 1,
						hat_color)
					cv.px(HEAD_LEFT - 2, FACE_TOP, hat_color.darkened(SHADE_SOFT))
				DIR_UP:
					cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
					cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, TORSO_TOP - HEAD_TOP, hat_color)
					cv.rect(CENTER_X, HAT_TOP - 1, 2, 1, hat_color.darkened(SHADE_SUBTLE))
					cv.rect(HEAD_LEFT + 2, CHEEK_ROW, HEAD_WIDTH - 4, 2, hat_color.darkened(SHADE_SOFT))
		"cap":
			cv.rect(HEAD_LEFT, HEAD_TOP, HEAD_WIDTH, FACE_TOP - HEAD_TOP, hat_color)
			cv.rect(HEAD_LEFT + 1, HAT_TOP, HEAD_WIDTH - 2, 1, hat_color)
			match dir:
				DIR_DOWN:
					cv.rect(HEAD_LEFT, FACE_TOP, HEAD_WIDTH, 1, hat_color.darkened(SHADE_DARK))
				DIR_SIDE:
					cv.rect(CAP_BILL_X, FACE_TOP, CAP_BILL_LENGTH, 1, hat_color.darkened(SHADE_DARK))
		"straw":
			cv.rect(HEAD_LEFT, HAT_TOP, HEAD_WIDTH, STRAW_CROWN_HEIGHT, hat_color)
			cv.rect(HEAD_LEFT, HEAD_TOP + 1, HEAD_WIDTH, 1, accent)
			cv.rect(STRAW_BRIM_LEFT, BRIM_ROW, STRAW_BRIM_WIDTH, 1, hat_color.darkened(SHADE_SUBTLE))

	if beard_hex != "":
		var beard := _c(beard_hex)
		match dir:
			DIR_DOWN:
				cv.rect(FACE_LEFT, CHEEK_ROW, FACE_WIDTH, BEARD_LENGTH, beard)
				cv.rect(FACE_LEFT + 1, CHEEK_ROW + BEARD_LENGTH, FACE_WIDTH - 2, 1, beard)
				cv.rect(CENTER_X, CHEEK_ROW, 2, 1, beard.darkened(SHADE_SOFT))
			DIR_SIDE:
				cv.rect(SIDE_FACE_LEFT + 1, CHEEK_ROW, SIDE_FACE_WIDTH - 1, BEARD_LENGTH, beard)
				cv.px(SIDE_FACE_LEFT + 1, CHEEK_ROW + BEARD_LENGTH, beard)

	cv.auto_shade()
	cv.outline(OUTLINE)
	return cv


# --------------------------------------------------------------------------
# Enemies (two 24x24 idle frames side by side)
# --------------------------------------------------------------------------

const ENEMY_SIZE := 24
const ENEMY_FRAMES := 2

# Enemy palettes
const SLIME_GREEN := Color("5fcf6a")
const KING_SLIME_BLUE := Color("5a7bea")
const SLIME_RED := Color("cf5f5f")
const GLOSS_BRIGHT := Color(1, 1, 1, 0.95)
const GLOSS_SOFT := Color(1, 1, 1, 0.85)
const CROWN_RUBY := Color("e03050")
const CROWN_SAPPHIRE := Color("50c0f0")
const BAT_BODY := Color("6a4a8a")
const BAT_WING := Color("4a3060")
const BAT_EYE := Color("ff4a4a")
const MUSHROOM_CAP := Color("d0443a")
const MUSHROOM_STEM := Color("f0e2c0")
const MUSHROOM_MOUTH := Color("8a5a4a")

# Slime body: frame 0 is tall, frame 1 squashed wide. It sits on SLIME_FLOOR.
const SLIME_CX := 12.0
const SLIME_FLOOR := 23.0
const SLIME_RX_IDLE := 9.0
const SLIME_RX_SQUASH := 10.0
const SLIME_RY_IDLE := 7.0
const SLIME_RY_SQUASH := 6.0
const SLIME_BASE_BAND := 2
const SLIME_GLOSS_X := 7
const SLIME_GLOSS_WIDTH := 3
const SLIME_LEFT_EYE_X := 9
const SLIME_RIGHT_EYE_X := 15
const SLIME_EYE_HEIGHT := 3
const SLIME_MOUTH_X := 11
const SLIME_MOUTH_DROP := 3
const SLIME_MOUTH_WIDTH := 3
const SLIME_MOUTH_SHADE := 0.5

# King slime crown, positioned CROWN_LIFT rows above the top of the body.
const CROWN_LIFT := 4
const CROWN_LEFT := 7
const CROWN_WIDTH := 10
const CROWN_RIGHT := CROWN_LEFT + CROWN_WIDTH - 1
const CROWN_MID_X := 12
const CROWN_BAND_HEIGHT := 3

# Bat (centered; frame 1 drops by BAT_FLAP_DROP with wings lowered)
const BAT_CX := 12
const BAT_CY := 12
const BAT_BODY_RADIUS := 4.5
const BAT_FLAP_DROP := 2
const BAT_WING_SEGMENTS := 7
const BAT_WING_INNER_LEFT := 9
const BAT_WING_INNER_RIGHT := 14
const BAT_WING_UP_TOP := 6
const BAT_WING_UP_BOTTOM := 12
const BAT_WING_DOWN_TOP := 10
const BAT_WING_DOWN_BOTTOM := 14
const BAT_WING_TOP_SLOPE := 2
const BAT_WING_BOTTOM_SLOPE := 3
const BAT_WING_TIP_LEFT := 2
const BAT_WING_TIP_RIGHT := 21
const BAT_WING_TIP_TOP := 9
const BAT_WING_TIP_BOTTOM := 11
const BAT_EAR_LEFT_X := 9
const BAT_EAR_RIGHT_X := 14
const BAT_EAR_TOP := 7
const BAT_EYE_LEFT_X := 10
const BAT_EYE_RIGHT_X := 13
const BAT_EYE_ROW := 11
const BAT_FANG_X := 11
const BAT_FANG_ROW := 14

# Mushroom
const MUSHROOM_CX := 12
const MUSHROOM_CAP_CY := 9
const MUSHROOM_CAP_RX := 10.5
const MUSHROOM_CAP_RY := 6.5
## Rows below the cap center where the cap is cut flat.
const MUSHROOM_CAP_UNDERSIDE := 4
const MUSHROOM_GILL_LEFT := 3
const MUSHROOM_GILL_WIDTH := 18
const MUSHROOM_GILL_SHADE := 0.35
## Cap spots as (x, row offset from the cap center, w, h).
const MUSHROOM_BRIGHT_SPOTS := [Rect2i(7, -3, 2, 2), Rect2i(13, -4, 3, 2)]
const MUSHROOM_DIM_SPOTS := [Rect2i(17, -1, 2, 2), Rect2i(4, 0, 2, 1), Rect2i(10, 0, 2, 2)]
const MUSHROOM_STEM_LEFT := 8
const MUSHROOM_STEM_WIDTH := 8
const MUSHROOM_STEM_SIDE_SHADE := 0.12
const MUSHROOM_LEFT_EYE_X := 10
const MUSHROOM_RIGHT_EYE_X := 13
const MUSHROOM_MOUTH_X := 11
const MUSHROOM_MOUTH_DROP := 5
const MUSHROOM_FEET_TOP := 21
const MUSHROOM_FOOT_WIDTH := 3


static func enemy_sheet(kind: String) -> Texture2D:
	var key := "enemy_" + kind
	if _cache.has(key):
		return _cache[key]
	var sheet := PixelCanvas.new(ENEMY_SIZE * ENEMY_FRAMES, ENEMY_SIZE)
	for frame in ENEMY_FRAMES:
		var cv: PixelCanvas
		match kind:
			"slime":
				cv = _draw_slime(frame, SLIME_GREEN, false)
			"king_slime":
				cv = _draw_slime(frame, KING_SLIME_BLUE, true)
			"bat":
				cv = _draw_bat(frame)
			"mushroom":
				cv = _draw_mushroom(frame)
			_:
				cv = _draw_slime(frame, SLIME_RED, false)
		sheet.blit(cv, frame * ENEMY_SIZE, 0)
	var tex := sheet.to_texture()
	_cache[key] = tex
	return tex


static func _draw_slime(frame: int, base: Color, crowned: bool) -> PixelCanvas:
	var cv := PixelCanvas.new(ENEMY_SIZE, ENEMY_SIZE)
	var rx := SLIME_RX_IDLE if frame == 0 else SLIME_RX_SQUASH
	var ry := SLIME_RY_IDLE if frame == 0 else SLIME_RY_SQUASH
	var cy := SLIME_FLOOR - ry - 1.0
	cv.ellipse(SLIME_CX, cy, rx, ry, base)
	cv.rect(int(SLIME_CX - rx + 1), int(cy + ry - SLIME_BASE_BAND), int(rx * 2 - 2), SLIME_BASE_BAND,
		base.darkened(SHADE_HEAVY))
	cv.shade_ellipse(SLIME_CX, cy, rx, ry, base.lightened(SHADE_HEAVY), base, base.darkened(SHADE_DARK))
	# Glossy highlight
	cv.rect(SLIME_GLOSS_X, int(cy - ry + 2), SLIME_GLOSS_WIDTH, 1, GLOSS_BRIGHT)
	cv.rect(SLIME_GLOSS_X - 1, int(cy - ry + 3), 2, 2, GLOSS_SOFT)
	# Face
	var ey := int(cy)
	cv.rect(SLIME_LEFT_EYE_X, ey - 1, 1, SLIME_EYE_HEIGHT, EYE)
	cv.rect(SLIME_RIGHT_EYE_X, ey - 1, 1, SLIME_EYE_HEIGHT, EYE)
	cv.px(SLIME_LEFT_EYE_X, ey - 1, Color.WHITE)
	cv.px(SLIME_RIGHT_EYE_X, ey - 1, Color.WHITE)
	cv.rect(SLIME_MOUTH_X, ey + SLIME_MOUTH_DROP, SLIME_MOUTH_WIDTH, 1, base.darkened(SLIME_MOUTH_SHADE))
	if crowned:
		var top := int(cy - ry) - CROWN_LIFT
		cv.rect(CROWN_LEFT, top + 2, CROWN_WIDTH, CROWN_BAND_HEIGHT, GOLD)
		# Prongs
		cv.px(CROWN_LEFT, top, GOLD)
		cv.px(CROWN_LEFT, top + 1, GOLD)
		cv.px(CROWN_MID_X, top, GOLD)
		cv.px(CROWN_MID_X - 1, top + 1, GOLD)
		cv.px(CROWN_MID_X, top + 1, GOLD)
		cv.px(CROWN_RIGHT, top, GOLD)
		cv.px(CROWN_RIGHT, top + 1, GOLD)
		# Jewels
		cv.px(CROWN_MID_X, top + 3, CROWN_RUBY)
		cv.px(CROWN_LEFT + 2, top + 3, CROWN_SAPPHIRE)
		cv.px(CROWN_RIGHT - 1, top + 3, CROWN_SAPPHIRE)
		cv.rect(CROWN_LEFT, top + 2 + CROWN_BAND_HEIGHT - 1, CROWN_WIDTH, 1, GOLD.darkened(SHADE_HEAVY))
	cv.outline(OUTLINE)
	return cv


static func _draw_bat(frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(ENEMY_SIZE, ENEMY_SIZE)
	var oy := 0 if frame == 0 else BAT_FLAP_DROP
	# Wings
	if frame == 0:
		for i in BAT_WING_SEGMENTS:
			var y0 := BAT_WING_UP_TOP + oy + i / BAT_WING_TOP_SLOPE
			var y1 := BAT_WING_UP_BOTTOM + oy - i / BAT_WING_BOTTOM_SLOPE
			cv.vline(BAT_WING_INNER_LEFT - i, y0, y1, BAT_WING)
			cv.vline(BAT_WING_INNER_RIGHT + i, y0, y1, BAT_WING)
		cv.vline(BAT_WING_TIP_LEFT, BAT_WING_TIP_TOP + oy, BAT_WING_TIP_BOTTOM + oy, BAT_WING.lightened(SHADE_SOFT))
		cv.vline(BAT_WING_TIP_RIGHT, BAT_WING_TIP_TOP + oy, BAT_WING_TIP_BOTTOM + oy, BAT_WING.lightened(SHADE_SOFT))
	else:
		for i in BAT_WING_SEGMENTS:
			var y1 := BAT_WING_DOWN_BOTTOM + oy + i / BAT_WING_TOP_SLOPE
			cv.vline(BAT_WING_INNER_LEFT - i, BAT_WING_DOWN_TOP + oy, y1, BAT_WING)
			cv.vline(BAT_WING_INNER_RIGHT + i, BAT_WING_DOWN_TOP + oy, y1, BAT_WING)
	cv.ellipse(BAT_CX, BAT_CY + oy, BAT_BODY_RADIUS, BAT_BODY_RADIUS, BAT_BODY)
	cv.shade_ellipse(BAT_CX, BAT_CY + oy, BAT_BODY_RADIUS, BAT_BODY_RADIUS,
		BAT_BODY.lightened(SHADE_MEDIUM), BAT_BODY, BAT_BODY.darkened(SHADE_DARK))
	# Ears
	cv.px(BAT_EAR_LEFT_X, BAT_EAR_TOP + oy, BAT_BODY)
	cv.px(BAT_EAR_LEFT_X, BAT_EAR_TOP + 1 + oy, BAT_BODY)
	cv.px(BAT_EAR_RIGHT_X, BAT_EAR_TOP + oy, BAT_BODY)
	cv.px(BAT_EAR_RIGHT_X, BAT_EAR_TOP + 1 + oy, BAT_BODY)
	# Eyes & fangs
	cv.px(BAT_EYE_LEFT_X, BAT_EYE_ROW + oy, BAT_EYE)
	cv.px(BAT_EYE_RIGHT_X, BAT_EYE_ROW + oy, BAT_EYE)
	cv.px(BAT_FANG_X, BAT_FANG_ROW + oy, Color.WHITE)
	cv.px(BAT_FANG_X + 1, BAT_FANG_ROW + oy, Color.WHITE)
	cv.outline(OUTLINE)
	return cv


static func _draw_mushroom(frame: int) -> PixelCanvas:
	var cv := PixelCanvas.new(ENEMY_SIZE, ENEMY_SIZE)
	var squash := 0 if frame == 0 else 1
	# Cap (flattened underneath)
	var cy := MUSHROOM_CAP_CY + squash
	var ry := MUSHROOM_CAP_RY - squash * 0.5
	cv.ellipse(MUSHROOM_CX, cy, MUSHROOM_CAP_RX, ry, MUSHROOM_CAP)
	cv.shade_ellipse(MUSHROOM_CX, cy, MUSHROOM_CAP_RX, ry,
		MUSHROOM_CAP.lightened(SHADE_MEDIUM), MUSHROOM_CAP, MUSHROOM_CAP.darkened(SHADE_DARK))
	cv.rect(0, cy + MUSHROOM_CAP_UNDERSIDE, ENEMY_SIZE, ENEMY_SIZE, TRANSPARENT)
	cv.rect(MUSHROOM_GILL_LEFT, cy + MUSHROOM_CAP_UNDERSIDE - 1, MUSHROOM_GILL_WIDTH, 1,
		MUSHROOM_CAP.darkened(MUSHROOM_GILL_SHADE))
	# Spots
	for s: Rect2i in MUSHROOM_BRIGHT_SPOTS:
		cv.rect(s.position.x, cy + s.position.y, s.size.x, s.size.y, Color.WHITE)
	for s: Rect2i in MUSHROOM_DIM_SPOTS:
		cv.rect(s.position.x, cy + s.position.y, s.size.x, s.size.y, OFF_WHITE)
	# Stem with face
	var top := cy + MUSHROOM_CAP_UNDERSIDE
	var stem_height := MUSHROOM_FEET_TOP - top
	var stem_right := MUSHROOM_STEM_LEFT + MUSHROOM_STEM_WIDTH
	cv.rect(MUSHROOM_STEM_LEFT, top, MUSHROOM_STEM_WIDTH, stem_height, MUSHROOM_STEM)
	cv.rect(MUSHROOM_STEM_LEFT, top, MUSHROOM_STEM_WIDTH, 1, MUSHROOM_STEM.darkened(SHADE_HEAVY))
	cv.rect(stem_right - 2, top, 2, stem_height, MUSHROOM_STEM.darkened(MUSHROOM_STEM_SIDE_SHADE))
	cv.rect(MUSHROOM_LEFT_EYE_X, top + 2, 1, 2, EYE)
	cv.rect(MUSHROOM_RIGHT_EYE_X, top + 2, 1, 2, EYE)
	cv.rect(MUSHROOM_MOUTH_X, top + MUSHROOM_MOUTH_DROP, 2, 1, MUSHROOM_MOUTH)
	# Feet
	cv.rect(MUSHROOM_STEM_LEFT - 1, MUSHROOM_FEET_TOP, MUSHROOM_FOOT_WIDTH, 2, MUSHROOM_STEM.darkened(SHADE_MEDIUM))
	cv.rect(stem_right - 2, MUSHROOM_FEET_TOP, MUSHROOM_FOOT_WIDTH, 2, MUSHROOM_STEM.darkened(SHADE_MEDIUM))
	cv.outline(OUTLINE)
	return cv


# --------------------------------------------------------------------------
# Scenery
# --------------------------------------------------------------------------

# Broadleaf tree (32x48): trunk at the bottom, canopy built from overlapping blobs.
const TREE_W := 32
const TREE_H := 48
const TREE_SEED_BASE := 1000
const TREE_SEED_STRIDE := 77
const TREE_FRUIT_VARIANT := 1
const TREE_AUTUMN_VARIANT := 2
const TREE_BARK := Color("6b4528")
const TREE_FRUIT := Color("e04040")
## Darkest to brightest leaf shade.
const LEAF_GREENS := [Color("2f6b2f"), FOLIAGE_GREEN, Color("5aa846"), Color("86c95a")]
const AUTUMN_LEAVES := [Color("6b4a1f"), Color("a0602a"), Color("d08a30"), Color("f0b84a")]
const TRUNK_X := 13
const TRUNK_TOP := 28
const TRUNK_WIDTH := 6
const TRUNK_HEIGHT := TREE_H - TRUNK_TOP
const ROOTS_X := 11
const ROOTS_TOP := 45
const ROOTS_WIDTH := 10
## Canopy blobs as (center x, center y, radius).
const CANOPY_BLOBS := [
	Vector3(16, 18, 12), Vector3(9, 24, 7), Vector3(23, 24, 7),
	Vector3(11, 12, 7), Vector3(21, 12, 7), Vector3(16, 8, 7),
]
const CANOPY_SQUASH := 0.9
const CANOPY_INNER_INSET := 1.5
const CANOPY_HIGHLIGHT_LIFT := 2.5
const CANOPY_HIGHLIGHT_RX := 0.45
const CANOPY_HIGHLIGHT_RY := 0.38
const CANOPY_SPECKLES := 40
const CANOPY_SPECKLE_MIN := Vector2i(4, 3)
const CANOPY_SPECKLE_MAX := Vector2i(28, 30)
const SPECKLE_DARK_CHANCE := 0.6
const SPECKLE_BRIGHT_CHANCE := 0.5
const FRUIT_COUNT := 6
const FRUIT_MIN := Vector2i(7, 8)
const FRUIT_MAX := Vector2i(25, 26)

# Pine (24x48): stacked triangular tiers centered on PINE_CENTER_X.
const PINE_W := 24
const PINE_H := 48
const PINE_BARK := Color("5a3a22")
const PINE_DARK := Color("1f4a3a")
const PINE_MID := Color("2f6b4a")
const PINE_LIGHT := Color("4f9060")
const PINE_CENTER_X := 12
const PINE_TRUNK_X := 10
const PINE_TRUNK_TOP := 38
const PINE_TRUNK_WIDTH := 4
const PINE_TIP_TOP := 1
const PINE_TIP_HEIGHT := 4
## Tiers as [top row, bottom row, half width at the bottom].
const PINE_TIERS := [[4, 14, 9], [12, 24, 10], [21, 34, 11], [29, 41, 11]]
const PINE_HIGHLIGHT_EVERY := 3

# Bush (20x14): three overlapping blobs as (cx, cy, rx, ry); the top one gets shaded.
const BUSH_W := 20
const BUSH_H := 14
const BUSH_LEFT_BLOB := Vector4(6, 8, 5.5, 5)
const BUSH_RIGHT_BLOB := Vector4(14, 8, 5.5, 5)
const BUSH_TOP_BLOB := Vector4(10, 6, 6, 5.5)
const BUSH_BASE_X := 2
const BUSH_BASE_ROW := 11
const BUSH_BASE_WIDTH := 16
const BUSH_BLOSSOMS := [[Vector2i(7, 5), PETAL_YELLOW], [Vector2i(13, 8), PETAL_PINK], [Vector2i(4, 9), OFF_WHITE]]

# Grass tuft (16x12): random blades growing up from the bottom row.
const TUFT_W := 16
const TUFT_H := 12
const TUFT_SEED_BASE := 300
const TUFT_DARK_VARIANT_MIN := 2
const TUFT_SHADES := [Color("2f6b2f"), Color("4a9a3f"), Color("6fbf4f"), Color("9ad66a")]
const TUFT_SHADES_DARK := [Color("2a5a2a"), Color("3a7a35"), Color("569a44"), Color("78b85a")]
const TUFT_BLADES := 11
const TUFT_MIN_X := 1
const TUFT_MAX_X := 14
const TUFT_MIN_HEIGHT := 4
const TUFT_MAX_HEIGHT := 11
## Fraction of a blade's height after which it leans.
const TUFT_LEAN_START := 0.6
const TUFT_ROOT_ROWS := 2

# Flowers (14x10)
const FLOWER_W := 14
const FLOWER_H := 10
const FLOWER_PETALS := [PETAL_PINK, PETAL_YELLOW, PETAL_BLUE, OFF_WHITE]
const FLOWER_CENTER := Color("ffd040")
const FLOWER_HEADS := [Vector2i(3, 3), Vector2i(9, 2), Vector2i(6, 5), Vector2i(11, 6)]

# Lamp post (10x30): lantern cage on top of a pole.
const LAMP_W := 10
const LAMP_H := 30
const LAMP_IRON := Color("2f2f3a")
const LANTERN_GLASS := Color("ffe9a0")
const LANTERN_CORE := Color("fffbe8")
const LAMP_CAGE_LEFT := 2
const LAMP_CAGE_WIDTH := 6
const LAMP_ROOF_ROW := 2
const LAMP_GLASS_TOP := 3
const LAMP_GLASS_HEIGHT := 5
const LAMP_POLE_X := 4
const LAMP_POLE_TOP := LAMP_GLASS_TOP + LAMP_GLASS_HEIGHT
const LAMP_BASE_TOP := 27

# Rock (18x12): body and bump as (cx, cy, rx, ry).
const ROCK_W := 18
const ROCK_H := 12
const ROCK_GREY := Color("8a8a95")
const ROCK_MOSS := Color("5a8a4a")
const ROCK_BODY := Vector4(9, 7, 8, 5)
const ROCK_BUMP := Vector4(6, 5, 4, 3)
const ROCK_CRACK_X := 5
const ROCK_CRACK_ROW := 6
const ROCK_CRACK_WIDTH := 3
const ROCK_MOSS_X := 12
const ROCK_MOSS_ROW := 4

# Signpost (14x16)
const SIGN_W := 14
const SIGN_H := 16
const SIGN_WOOD := Color("a0703a")
const SIGN_BOARD_LEFT := 1
const SIGN_BOARD_TOP := 1
const SIGN_BOARD_WIDTH := 12
const SIGN_BOARD_HEIGHT := 8
const SIGN_POST_X := 6
const SIGN_POST_TOP := SIGN_BOARD_TOP + SIGN_BOARD_HEIGHT - 1
const SIGN_TEXT_LEFT := 3
## Carved "text" lines as (end x, row).
const SIGN_TEXT_LINES := [Vector2i(10, 3), Vector2i(8, 5)]
const SIGN_CARVE_SHADE := 0.4

# Chest (two 16x16 frames: closed / open)
const CHEST_SIZE := 16
const CHEST_FRAMES := 2
const CHEST_WOOD := Color("9a5a2a")
const CHEST_INTERIOR := Color("2a1a10")
const CHEST_LEFT := 1
const CHEST_WIDTH := 14
const CHEST_LID_TOP := 3
const CHEST_BODY_TOP := 7
const CHEST_BODY_HEIGHT := 8
const CHEST_OPEN_LID_HEIGHT := 3
const CHEST_LOCK_X := 7
const CHEST_LOCK_HEIGHT := 3
const CHEST_TREASURE_X := 5
const CHEST_TREASURE_WIDTH := 6

# Door (16x24): arched plank door.
const DOOR_W := 16
const DOOR_H := 24
const DOOR_WOOD := Color("6b3f22")
const DOOR_OUTLINE := Color("3a2a1c")
const DOOR_LEFT := 2
const DOOR_WIDTH := 12
const DOOR_ARCH_TOP := 2
const DOOR_SLAB_TOP := 4
const DOOR_PLANK_SEAMS := [5, 8, 11]
const DOOR_KNOB_X := 10
const DOOR_KNOB_Y := 13

# Window (14x14)
const WINDOW_SIZE := 14
const WINDOW_FRAME := Color("5a3a22")
const WINDOW_GLOW := Color("ffcf6a")
const WINDOW_GLARE := Color("ffe7a8")
const WINDOW_SILL := Color("8a5a32")
const WINDOW_PANE_INSET := 2
const WINDOW_GLARE_HEIGHT := 4
const WINDOW_MULLION_X := 6
const WINDOW_TRANSOM_ROW := 7
const WINDOW_SILL_HEIGHT := 2

# Particle dot (4x4 rounded square)
const DOT_SIZE := 4


static func tree(variant: int = 0) -> Texture2D:
	var key := "tree_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = TREE_SEED_BASE + variant * TREE_SEED_STRIDE
	var cv := PixelCanvas.new(TREE_W, TREE_H)
	cv.rect(TRUNK_X, TRUNK_TOP, TRUNK_WIDTH, TRUNK_HEIGHT, TREE_BARK)
	cv.rect(TRUNK_X, TRUNK_TOP, 2, TRUNK_HEIGHT, TREE_BARK.lightened(SHADE_SOFT))
	cv.rect(TRUNK_X + TRUNK_WIDTH - 2, TRUNK_TOP, 2, TRUNK_HEIGHT, TREE_BARK.darkened(SHADE_DARK))
	cv.rect(ROOTS_X, ROOTS_TOP, ROOTS_WIDTH, TREE_H - ROOTS_TOP, TREE_BARK.darkened(SHADE_SUBTLE))
	cv.px(ROOTS_X - 1, TREE_H - 1, TREE_BARK.darkened(SHADE_SUBTLE))
	cv.px(ROOTS_X + ROOTS_WIDTH, TREE_H - 1, TREE_BARK.darkened(SHADE_SUBTLE))
	var greens := LEAF_GREENS
	if variant == TREE_AUTUMN_VARIANT:
		greens = AUTUMN_LEAVES
	for b in CANOPY_BLOBS:
		cv.ellipse(b.x, b.y, b.z, b.z * CANOPY_SQUASH, greens[0])
	for b in CANOPY_BLOBS:
		cv.ellipse(b.x - 1, b.y - 1, b.z - CANOPY_INNER_INSET, (b.z - CANOPY_INNER_INSET) * CANOPY_SQUASH, greens[1])
	for b in CANOPY_BLOBS:
		cv.ellipse(b.x - 2, b.y - CANOPY_HIGHLIGHT_LIFT, b.z * CANOPY_HIGHLIGHT_RX, b.z * CANOPY_HIGHLIGHT_RY, greens[2])
	for i in CANOPY_SPECKLES:
		var x := rng.randi_range(CANOPY_SPECKLE_MIN.x, CANOPY_SPECKLE_MAX.x)
		var y := rng.randi_range(CANOPY_SPECKLE_MIN.y, CANOPY_SPECKLE_MAX.y)
		if cv.get_px(x, y) == greens[1]:
			cv.px(x, y, greens[0] if rng.randf() < SPECKLE_DARK_CHANCE else greens[2])
		elif cv.get_px(x, y) == greens[2] and rng.randf() < SPECKLE_BRIGHT_CHANCE:
			cv.px(x, y, greens[3])
	if variant == TREE_FRUIT_VARIANT:
		# Little red fruit
		for i in FRUIT_COUNT:
			var x := rng.randi_range(FRUIT_MIN.x, FRUIT_MAX.x)
			var y := rng.randi_range(FRUIT_MIN.y, FRUIT_MAX.y)
			if cv.is_filled(x, y):
				cv.px(x, y, TREE_FRUIT)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func pine() -> Texture2D:
	if _cache.has("pine"):
		return _cache["pine"]
	var cv := PixelCanvas.new(PINE_W, PINE_H)
	cv.rect(PINE_TRUNK_X, PINE_TRUNK_TOP, PINE_TRUNK_WIDTH, PINE_H - PINE_TRUNK_TOP, PINE_BARK)
	cv.rect(PINE_CENTER_X, PINE_TRUNK_TOP, 2, PINE_H - PINE_TRUNK_TOP, PINE_BARK.darkened(SHADE_MEDIUM))
	for t in PINE_TIERS:
		var top: int = t[0]
		var bottom: int = t[1]
		var half: int = t[2]
		for y in range(top, bottom + 1):
			var w := int(lerp(1.0, float(half), float(y - top) / float(bottom - top)))
			cv.hline(PINE_CENTER_X - w, PINE_CENTER_X - 1 + w, y, PINE_MID)
			cv.hline(PINE_CENTER_X, PINE_CENTER_X - 1 + w, y, PINE_DARK)
			if y % PINE_HIGHLIGHT_EVERY == 0:
				cv.hline(PINE_CENTER_X - w, PINE_CENTER_X - w + max(w / 2, 1), y, PINE_LIGHT)
		cv.hline(PINE_CENTER_X - half, PINE_CENTER_X - 1 + half, bottom, PINE_DARK.darkened(SHADE_MEDIUM))
	cv.rect(PINE_CENTER_X - 1, PINE_TIP_TOP, 2, PINE_TIP_HEIGHT, PINE_MID)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["pine"] = tex
	return tex


static func bush() -> Texture2D:
	if _cache.has("bush"):
		return _cache["bush"]
	var cv := PixelCanvas.new(BUSH_W, BUSH_H)
	var g := FOLIAGE_GREEN
	for b: Vector4 in [BUSH_LEFT_BLOB, BUSH_RIGHT_BLOB, BUSH_TOP_BLOB]:
		cv.ellipse(b.x, b.y, b.z, b.w, g)
	var top := BUSH_TOP_BLOB
	cv.shade_ellipse(top.x, top.y, top.z, top.w, g.lightened(SHADE_DARK), g, g.darkened(SHADE_MEDIUM))
	cv.rect(BUSH_BASE_X, BUSH_BASE_ROW, BUSH_BASE_WIDTH, 2, g.darkened(SHADE_HEAVY))
	for blossom in BUSH_BLOSSOMS:
		var p: Vector2i = blossom[0]
		cv.px(p.x, p.y, blossom[1])
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["bush"] = tex
	return tex


static func grass_tuft(variant: int = 0) -> Texture2D:
	var key := "tuft_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = TUFT_SEED_BASE + variant
	var cv := PixelCanvas.new(TUFT_W, TUFT_H)
	var shades := TUFT_SHADES
	if variant >= TUFT_DARK_VARIANT_MIN:
		shades = TUFT_SHADES_DARK
	for i in TUFT_BLADES:
		var x := rng.randi_range(TUFT_MIN_X, TUFT_MAX_X)
		var h := rng.randi_range(TUFT_MIN_HEIGHT, TUFT_MAX_HEIGHT)
		var lean := rng.randi_range(-1, 1)
		var col: Color = shades[rng.randi_range(0, shades.size() - 1)]
		for k in h:
			var xx := x + (lean if k > h * TUFT_LEAN_START else 0)
			cv.px(xx, TUFT_H - 1 - k, col.darkened(SHADE_DARK) if k < TUFT_ROOT_ROWS else col)
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func flowers(variant: int = 0) -> Texture2D:
	var key := "flowers_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var petal: Color = FLOWER_PETALS[variant % FLOWER_PETALS.size()]
	var cv := PixelCanvas.new(FLOWER_W, FLOWER_H)
	for p: Vector2i in FLOWER_HEADS:
		cv.vline(p.x, p.y + 1, FLOWER_H - 1, FOLIAGE_GREEN)
		cv.px(p.x - 1, p.y, petal)
		cv.px(p.x + 1, p.y, petal)
		cv.px(p.x, p.y - 1, petal)
		cv.px(p.x, p.y + 1, petal)
		cv.px(p.x, p.y, FLOWER_CENTER)
	var tex := cv.to_texture()
	_cache[key] = tex
	return tex


static func lamp_post() -> Texture2D:
	if _cache.has("lamp"):
		return _cache["lamp"]
	var cv := PixelCanvas.new(LAMP_W, LAMP_H)
	var cage_right := LAMP_CAGE_LEFT + LAMP_CAGE_WIDTH - 1
	cv.rect(LAMP_POLE_X, LAMP_POLE_TOP, 2, LAMP_BASE_TOP - LAMP_POLE_TOP + 1, LAMP_IRON)
	cv.rect(LAMP_POLE_X - 1, LAMP_BASE_TOP, 4, LAMP_H - LAMP_BASE_TOP, LAMP_IRON)
	cv.rect(LAMP_CAGE_LEFT, LAMP_ROOF_ROW, LAMP_CAGE_WIDTH, 1, LAMP_IRON)
	cv.rect(LAMP_CAGE_LEFT + 1, LAMP_ROOF_ROW - 1, LAMP_CAGE_WIDTH - 2, 1, LAMP_IRON)
	cv.rect(LAMP_CAGE_LEFT, LAMP_GLASS_TOP, 1, LAMP_GLASS_HEIGHT, LAMP_IRON)
	cv.rect(cage_right, LAMP_GLASS_TOP, 1, LAMP_GLASS_HEIGHT, LAMP_IRON)
	cv.rect(LAMP_CAGE_LEFT + 1, LAMP_GLASS_TOP, LAMP_CAGE_WIDTH - 2, LAMP_GLASS_HEIGHT, LANTERN_GLASS)
	cv.rect(LAMP_CAGE_LEFT + 2, LAMP_GLASS_TOP + 1, LAMP_CAGE_WIDTH - 4, LAMP_GLASS_HEIGHT - 2, LANTERN_CORE)
	cv.rect(LAMP_CAGE_LEFT, LAMP_POLE_TOP, LAMP_CAGE_WIDTH, 1, LAMP_IRON)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["lamp"] = tex
	return tex


static func rock() -> Texture2D:
	if _cache.has("rock"):
		return _cache["rock"]
	var cv := PixelCanvas.new(ROCK_W, ROCK_H)
	var g := ROCK_GREY
	var b := ROCK_BODY
	cv.ellipse(b.x, b.y, b.z, b.w, g)
	cv.ellipse(ROCK_BUMP.x, ROCK_BUMP.y, ROCK_BUMP.z, ROCK_BUMP.w, g)
	cv.shade_ellipse(b.x, b.y, b.z, b.w, g.lightened(SHADE_DARK), g, g.darkened(SHADE_HEAVY))
	cv.rect(ROCK_CRACK_X, ROCK_CRACK_ROW, ROCK_CRACK_WIDTH, 1, g.darkened(SHADE_HEAVY))
	cv.rect(ROCK_MOSS_X, ROCK_MOSS_ROW, 2, 1, ROCK_MOSS)
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["rock"] = tex
	return tex


static func signpost() -> Texture2D:
	if _cache.has("sign"):
		return _cache["sign"]
	var cv := PixelCanvas.new(SIGN_W, SIGN_H)
	cv.rect(SIGN_POST_X, SIGN_POST_TOP, 2, SIGN_H - SIGN_POST_TOP, SIGN_WOOD.darkened(SHADE_MEDIUM))
	cv.rect(SIGN_BOARD_LEFT, SIGN_BOARD_TOP, SIGN_BOARD_WIDTH, SIGN_BOARD_HEIGHT, SIGN_WOOD)
	cv.rect(SIGN_BOARD_LEFT, SIGN_BOARD_TOP + SIGN_BOARD_HEIGHT - 1, SIGN_BOARD_WIDTH, 1,
		SIGN_WOOD.darkened(SHADE_HEAVY))
	for line: Vector2i in SIGN_TEXT_LINES:
		cv.hline(SIGN_TEXT_LEFT, line.x, line.y, SIGN_WOOD.darkened(SIGN_CARVE_SHADE))
	cv.outline(OUTLINE)
	var tex := cv.to_texture()
	_cache["sign"] = tex
	return tex


## Two frames: closed / open.
static func chest() -> Texture2D:
	if _cache.has("chest"):
		return _cache["chest"]
	var sheet := PixelCanvas.new(CHEST_SIZE * CHEST_FRAMES, CHEST_SIZE)
	for frame in CHEST_FRAMES:
		var cv := PixelCanvas.new(CHEST_SIZE, CHEST_SIZE)
		var wood := CHEST_WOOD
		var chest_right := CHEST_LEFT + CHEST_WIDTH - 1
		cv.rect(CHEST_LEFT, CHEST_BODY_TOP, CHEST_WIDTH, CHEST_BODY_HEIGHT, wood)
		cv.rect(CHEST_LEFT, CHEST_BODY_TOP + CHEST_BODY_HEIGHT - 1, CHEST_WIDTH, 1, wood.darkened(SHADE_HEAVY))
		if frame == 0:
			cv.rect(CHEST_LEFT, CHEST_LID_TOP, CHEST_WIDTH, CHEST_BODY_TOP - CHEST_LID_TOP, wood.lightened(SHADE_SUBTLE))
			cv.rect(CHEST_LEFT + 1, CHEST_LID_TOP - 1, CHEST_WIDTH - 2, 1, wood.lightened(SHADE_SUBTLE))
			cv.rect(CHEST_LEFT, CHEST_BODY_TOP - 1, CHEST_WIDTH, 1, GOLD)
			cv.rect(CHEST_LOCK_X, CHEST_BODY_TOP - 1, 2, CHEST_LOCK_HEIGHT, GOLD)
		else:
			cv.rect(CHEST_LEFT, CHEST_LID_TOP - 1, CHEST_WIDTH, CHEST_OPEN_LID_HEIGHT, wood.darkened(SHADE_MEDIUM))
			cv.rect(CHEST_LEFT + 1, CHEST_BODY_TOP - 2, CHEST_WIDTH - 2, 2, CHEST_INTERIOR)
			cv.rect(CHEST_TREASURE_X, CHEST_BODY_TOP - 2, CHEST_TREASURE_WIDTH, 1, GOLD.lightened(SHADE_HEAVY))
		cv.rect(CHEST_LEFT, CHEST_BODY_TOP, 1, CHEST_BODY_HEIGHT, GOLD.darkened(SHADE_MEDIUM))
		cv.rect(chest_right, CHEST_BODY_TOP, 1, CHEST_BODY_HEIGHT, GOLD.darkened(SHADE_MEDIUM))
		cv.outline(OUTLINE)
		sheet.blit(cv, frame * CHEST_SIZE, 0)
	var tex := sheet.to_texture()
	_cache["chest"] = tex
	return tex


static func door() -> Texture2D:
	if _cache.has("door"):
		return _cache["door"]
	var cv := PixelCanvas.new(DOOR_W, DOOR_H)
	cv.rect(DOOR_LEFT, DOOR_SLAB_TOP, DOOR_WIDTH, DOOR_H - DOOR_SLAB_TOP, DOOR_WOOD)
	cv.rect(DOOR_LEFT + 2, DOOR_ARCH_TOP, DOOR_WIDTH - 4, 2, DOOR_WOOD)
	cv.rect(DOOR_LEFT + 1, DOOR_ARCH_TOP + 1, DOOR_WIDTH - 2, 1, DOOR_WOOD)
	for x in DOOR_PLANK_SEAMS:
		cv.vline(x, DOOR_SLAB_TOP, DOOR_H - 1, DOOR_WOOD.darkened(SHADE_HEAVY))
	cv.rect(DOOR_KNOB_X, DOOR_KNOB_Y, 2, 2, GOLD)
	cv.outline(DOOR_OUTLINE)
	var tex := cv.to_texture()
	_cache["door"] = tex
	return tex


static func window() -> Texture2D:
	if _cache.has("window"):
		return _cache["window"]
	var cv := PixelCanvas.new(WINDOW_SIZE, WINDOW_SIZE)
	var pane_size := WINDOW_SIZE - WINDOW_PANE_INSET * 2
	var pane_end := WINDOW_SIZE - WINDOW_PANE_INSET - 1
	cv.rect(0, 0, WINDOW_SIZE, WINDOW_SIZE, WINDOW_FRAME)
	cv.rect(WINDOW_PANE_INSET, WINDOW_PANE_INSET, pane_size, pane_size, WINDOW_GLOW)
	cv.rect(WINDOW_PANE_INSET, WINDOW_PANE_INSET, pane_size, WINDOW_GLARE_HEIGHT, WINDOW_GLARE)
	cv.vline(WINDOW_MULLION_X, WINDOW_PANE_INSET, pane_end, WINDOW_FRAME)
	cv.vline(WINDOW_MULLION_X + 1, WINDOW_PANE_INSET, pane_end, WINDOW_FRAME)
	cv.hline(WINDOW_PANE_INSET, pane_end, WINDOW_TRANSOM_ROW, WINDOW_FRAME)
	cv.rect(0, WINDOW_SIZE - WINDOW_SILL_HEIGHT, WINDOW_SIZE, WINDOW_SILL_HEIGHT, WINDOW_SILL)
	var tex := cv.to_texture()
	_cache["window"] = tex
	return tex


static func particle_dot() -> Texture2D:
	if _cache.has("dot"):
		return _cache["dot"]
	var cv := PixelCanvas.new(DOT_SIZE, DOT_SIZE)
	cv.rect(1, 0, DOT_SIZE - 2, DOT_SIZE, Color.WHITE)
	cv.rect(0, 1, DOT_SIZE, DOT_SIZE - 2, Color.WHITE)
	var tex := cv.to_texture()
	_cache["dot"] = tex
	return tex
