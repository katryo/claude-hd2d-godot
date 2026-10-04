class_name TextureFactory
extends RefCounted
## Procedural 16x16 pixel-art tile textures and the materials that use them.
## One tile = one world unit = 16 texels, matching the sprite pixel density.

const SIZE := 16
## Highest texel index along either axis.
const LAST := SIZE - 1

# Palettes. Grass palettes are [base, dark speck, light blade, highlight].
const PAL_GRASS := [Color("4f9a3e"), Color("3f8434"), Color("67b24c"), Color("8acd62")]
const PAL_GRASS_DARK := [Color("3d7d36"), Color("2f6a2e"), Color("4f9a3e"), Color("6fb653")]
const PAL_TALL_GRASS := [Color("3a7a33"), Color("2c652a"), Color("4c9440"), Color("5faa4c")]
const PAL_CLIFF_TOP := [Color("4a8f3c"), Color("3a7a33"), Color("5fa64a"), Color("7cc05c")]
const PAL_FALLBACK := [Color.MAGENTA, Color.MAGENTA, Color.MAGENTA, Color.MAGENTA]
const COLOR_WOOD := Color("a0703a")
const COLOR_BEAM := Color("6b4528")
const COLOR_ROOF_RED := Color("b84a3a")
const COLOR_ROOF_BLUE := Color("3f6ab0")
const COLOR_ROOF_GREEN := Color("4f8a5a")
const COLOR_ROOF_BROWN := Color("8a5a3a")
const COLOR_DIRT := Color("b08a5a")
const COLOR_PEBBLE_LIGHT := Color("8a8a8a")
const COLOR_PEBBLE_MID := Color("6a6a6a")
const COLOR_PEBBLE_DARK := Color("5a5a5a")
const COLOR_MORTAR := Color("8a8070")
const COLOR_FLAGSTONE := Color("c8bca4")
const COLOR_CLIFF := Color("8a7a66")
const COLOR_CLIFF_FRINGE := Color("4a8f3c")
const COLOR_GROUND_SIDE := Color("7a5a3a")
const COLOR_GROUND_FRINGE := Color("4f9a3e")
const COLOR_PLASTER := Color("e8dcc0")

# Per-texture RNG seeds (fixed so every run produces identical tiles).
const SEED_GRASS := 11
const SEED_GRASS_DARK := 12
const SEED_TALL_GRASS := 13
const SEED_CLIFF_TOP := 14
const SEED_FALLBACK := 1
const SEED_DIRT := 21
const SEED_STONE := 31
const SEED_PLANKS := 41
const SEED_CLIFF_SIDE_TOP := 51
const SEED_CLIFF_SIDE := 52
const SEED_GROUND_SIDE := 61
const SEED_HOUSE_WALL := 71

# Materials
const TILE_ROUGHNESS := 0.92
const TILE_SPECULAR := 0.25
const ROOF_ROUGHNESS := 0.7
const ROOF_SPECULAR := 0.4

# Grass
const GRASS_DARK_SPECKS := 40
## Two-texel-tall light blades.
const GRASS_BLADES := 22
const GRASS_HIGHLIGHTS := 6

# Dirt
const DIRT_DARK_SPECKS := 45
const DIRT_LIGHT_SPECKS := 18
const DIRT_SPECK_SHADE := 0.12
## Three-texel pebbles (L shape), so they start at most one texel from the edge.
const DIRT_PEBBLES := 4

# Stone floor: two rows of offset flagstones per tile.
const STONE_ROWS := 2
const STONE_COLS := 3
## Distance between flagstone origins (stone + one mortar line).
const STONE_PITCH := 8
const STONE_SIZE := 7
const STONE_ROW_OFFSET := 4
const STONE_TONE_VARIATION := 0.15
const STONE_BEVEL_SHADE := 0.15
const STONE_CRACKS := 10
const STONE_CRACK_SHADE := 0.1

# Planks
const PLANK_COUNT := 4
const PLANK_HEIGHT := 4
const PLANK_TONE_VARIATION := 0.12
const PLANK_GAP_SHADE := 0.35
const PLANK_TOP_LIGHT := 0.08
const PLANK_SEAM_MIN := 2
const PLANK_SEAM_MAX := 13
const PLANK_KNOT_SHADE := 0.18

# Cliff side
const CLIFF_STRATA_HEIGHT := 3
const CLIFF_STRATA_SHADE := 0.08
const CLIFF_CRACKS := 6
const CLIFF_CRACK_MIN_LEN := 2
const CLIFF_CRACK_MAX_LEN := 5
const CLIFF_CRACK_SHADE := 0.35
const CLIFF_CRACK_LIP_LIGHT := 0.12
## Three-texel-tall vertical holes.
const CLIFF_HOLES := 3
const CLIFF_HOLE_HEIGHT := 3
const CLIFF_HOLE_SHADE := 0.4
const CLIFF_HOLE_TAIL_SHADE := 0.3
const CLIFF_FRINGE_MIN_DEPTH := 2
const CLIFF_FRINGE_DEPTH_RANGE := 3.0
## Every Nth column (at the given phase) gets a longer grass clump.
const CLIFF_FRINGE_CLUMP_SPACING := 5
const CLIFF_FRINGE_CLUMP_PHASE := 2
const CLIFF_FRINGE_CLUMP_EXTRA := 2
const CLIFF_FRINGE_EDGE_SHADE := 0.3
const CLIFF_FRINGE_TOP_LIGHT := 0.2

# Ground side
const GROUND_DARK_SPECKS := 30
const GROUND_DARK_SHADE := 0.2
const GROUND_LIGHT_SPECKS := 10
const GROUND_LIGHT_SHADE := 0.15
const GROUND_FRINGE_MIN_DEPTH := 2
## Column multiplier / modulus for the pseudo-random fringe depth.
const GROUND_FRINGE_HASH := 7
const GROUND_FRINGE_DEPTH_RANGE := 3
const GROUND_FRINGE_EDGE_SHADE := 0.3

# House wall
const WALL_SPECKS := 20
const WALL_SPECK_SHADE := 0.07
const WALL_RIGHT_BEAM_SHADE := 0.2
const WALL_SILL_SHADE := 0.15

# Roof shingles
const SHINGLE_ROWS := 4
const SHINGLE_HEIGHT := 4
const SHINGLE_WIDTH := 4
## Horizontal offset of odd shingle rows.
const SHINGLE_STAGGER := 2
const SHINGLE_GAP_SHADE := 0.35
const SHINGLE_TOP_LIGHT := 0.15
const SHINGLE_EDGE_SHADE := 0.2

static var _textures := {}
static var _materials := {}


static func get_texture(kind: String) -> Texture2D:
	if _textures.has(kind):
		return _textures[kind]
	var img: Image
	match kind:
		"grass": img = _grass(PAL_GRASS, SEED_GRASS)
		"grass_dark": img = _grass(PAL_GRASS_DARK, SEED_GRASS_DARK)
		"tall_grass": img = _grass(PAL_TALL_GRASS, SEED_TALL_GRASS)
		"cliff_top": img = _grass(PAL_CLIFF_TOP, SEED_CLIFF_TOP)
		"dirt": img = _dirt()
		"stone": img = _stone_floor()
		"wood": img = _planks(COLOR_WOOD)
		"cliff_side": img = _cliff_side(false)
		"cliff_side_top": img = _cliff_side(true)
		"ground_side": img = _ground_side()
		"house_wall": img = _house_wall()
		"house_beam": img = _planks(COLOR_BEAM)
		"roof_red": img = _roof(COLOR_ROOF_RED)
		"roof_blue": img = _roof(COLOR_ROOF_BLUE)
		"roof_green": img = _roof(COLOR_ROOF_GREEN)
		"roof_brown": img = _roof(COLOR_ROOF_BROWN)
		_: img = _grass(PAL_FALLBACK, SEED_FALLBACK)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_textures[kind] = tex
	return tex


static func get_material(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = get_texture(kind)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = TILE_ROUGHNESS
	mat.metallic_specular = TILE_SPECULAR
	if kind.begins_with("roof"):
		mat.roughness = ROOF_ROUGHNESS
		mat.metallic_specular = ROOF_SPECULAR
	_materials[kind] = mat
	return mat


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## `palette` is [base, dark, light, highlight].
static func _grass(palette: Array, seed_value: int) -> Image:
	var base: Color = palette[0]
	var dark: Color = palette[1]
	var light: Color = palette[2]
	var highlight: Color = palette[3]
	var rng := _rng(seed_value)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in GRASS_DARK_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), dark)
	for i in GRASS_BLADES:
		var x := rng.randi_range(0, LAST)
		var y := rng.randi_range(1, LAST)
		img.set_pixel(x, y, light)
		img.set_pixel(x, y - 1, light)
	for i in GRASS_HIGHLIGHTS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), highlight)
	return img


static func _dirt() -> Image:
	var rng := _rng(SEED_DIRT)
	var base := COLOR_DIRT
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in DIRT_DARK_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), base.darkened(DIRT_SPECK_SHADE))
	for i in DIRT_LIGHT_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), base.lightened(DIRT_SPECK_SHADE))
	for i in DIRT_PEBBLES:
		var x := rng.randi_range(0, LAST - 1)
		var y := rng.randi_range(0, LAST - 1)
		img.set_pixel(x, y, COLOR_PEBBLE_LIGHT)
		img.set_pixel(x + 1, y, COLOR_PEBBLE_MID)
		img.set_pixel(x, y + 1, COLOR_PEBBLE_DARK)
	return img


static func _stone_floor() -> Image:
	var rng := _rng(SEED_STONE)
	var mortar := COLOR_MORTAR
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(mortar)
	# Two rows of offset flagstones per tile.
	for row in STONE_ROWS:
		var y0 := row * STONE_PITCH
		var offset := 0 if row == 0 else STONE_ROW_OFFSET
		for col in STONE_COLS:
			var x0 := col * STONE_PITCH - offset
			var tone := COLOR_FLAGSTONE.darkened(rng.randf_range(0.0, STONE_TONE_VARIATION))
			for y in range(y0, y0 + STONE_SIZE):
				for x in range(x0, x0 + STONE_SIZE):
					var wx := posmod(x, SIZE)
					var c := tone
					if y == y0:
						c = tone.lightened(STONE_BEVEL_SHADE)
					elif y == y0 + STONE_SIZE - 1 or x == x0 + STONE_SIZE - 1:
						c = tone.darkened(STONE_BEVEL_SHADE)
					img.set_pixel(wx, y, c)
	for i in STONE_CRACKS:
		var x := rng.randi_range(0, LAST)
		var y := rng.randi_range(0, LAST)
		img.set_pixel(x, y, img.get_pixel(x, y).darkened(STONE_CRACK_SHADE))
	return img


static func _planks(base: Color) -> Image:
	var rng := _rng(SEED_PLANKS)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for plank in PLANK_COUNT:
		var y0 := plank * PLANK_HEIGHT
		var tone := base.darkened(rng.randf_range(0.0, PLANK_TONE_VARIATION))
		for y in range(y0, y0 + PLANK_HEIGHT):
			for x in SIZE:
				var c := tone
				if y == y0 + PLANK_HEIGHT - 1:
					c = base.darkened(PLANK_GAP_SHADE)
				elif y == y0:
					c = tone.lightened(PLANK_TOP_LIGHT)
				img.set_pixel(x, y, c)
		var seam := rng.randi_range(PLANK_SEAM_MIN, PLANK_SEAM_MAX)
		img.set_pixel(seam, y0 + 1, base.darkened(PLANK_GAP_SHADE))
		img.set_pixel(seam, y0 + 2, base.darkened(PLANK_GAP_SHADE))
		img.set_pixel(rng.randi_range(0, LAST), y0 + 1, tone.darkened(PLANK_KNOT_SHADE))
	return img


static func _cliff_side(with_fringe: bool) -> Image:
	var rng := _rng(SEED_CLIFF_SIDE_TOP if with_fringe else SEED_CLIFF_SIDE)
	var base := COLOR_CLIFF
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	# Horizontal strata.
	for y in SIZE:
		var band := base.darkened(CLIFF_STRATA_SHADE * float((y / CLIFF_STRATA_HEIGHT) % 2))
		for x in SIZE:
			img.set_pixel(x, y, band)
	for i in CLIFF_CRACKS:
		var x := rng.randi_range(0, LAST)
		var y := rng.randi_range(0, LAST)
		var length := rng.randi_range(CLIFF_CRACK_MIN_LEN, CLIFF_CRACK_MAX_LEN)
		for k in length:
			img.set_pixel(posmod(x + k, SIZE), y, base.darkened(CLIFF_CRACK_SHADE))
			if y > 0:
				img.set_pixel(posmod(x + k, SIZE), y - 1, base.lightened(CLIFF_CRACK_LIP_LIGHT))
	for i in CLIFF_HOLES:
		var x := rng.randi_range(0, LAST)
		var y := rng.randi_range(0, SIZE - CLIFF_HOLE_HEIGHT)
		img.set_pixel(x, y, base.darkened(CLIFF_HOLE_SHADE))
		img.set_pixel(x, y + 1, base.darkened(CLIFF_HOLE_SHADE))
		img.set_pixel(x, y + 2, base.darkened(CLIFF_HOLE_TAIL_SHADE))
	if with_fringe:
		var g := COLOR_CLIFF_FRINGE
		for x in SIZE:
			var depth := CLIFF_FRINGE_MIN_DEPTH + int(rng.randf() * CLIFF_FRINGE_DEPTH_RANGE)
			if x % CLIFF_FRINGE_CLUMP_SPACING == CLIFF_FRINGE_CLUMP_PHASE:
				depth += CLIFF_FRINGE_CLUMP_EXTRA
			for y in depth:
				img.set_pixel(x, y, g if y < depth - 1 else g.darkened(CLIFF_FRINGE_EDGE_SHADE))
			img.set_pixel(x, depth, base.darkened(CLIFF_FRINGE_EDGE_SHADE))
		for x in SIZE:
			img.set_pixel(x, 0, g.lightened(CLIFF_FRINGE_TOP_LIGHT))
	return img


static func _ground_side() -> Image:
	var rng := _rng(SEED_GROUND_SIDE)
	var base := COLOR_GROUND_SIDE
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in GROUND_DARK_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), base.darkened(GROUND_DARK_SHADE))
	for i in GROUND_LIGHT_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), base.lightened(GROUND_LIGHT_SHADE))
	var g := COLOR_GROUND_FRINGE
	for x in SIZE:
		var depth := GROUND_FRINGE_MIN_DEPTH + (x * GROUND_FRINGE_HASH % GROUND_FRINGE_DEPTH_RANGE)
		for y in depth:
			img.set_pixel(x, y, g if y < depth - 1 else g.darkened(GROUND_FRINGE_EDGE_SHADE))
	return img


static func _house_wall() -> Image:
	var rng := _rng(SEED_HOUSE_WALL)
	var plaster := COLOR_PLASTER
	var beam := COLOR_BEAM
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(plaster)
	for i in WALL_SPECKS:
		img.set_pixel(rng.randi_range(0, LAST), rng.randi_range(0, LAST), plaster.darkened(WALL_SPECK_SHADE))
	for y in SIZE:
		img.set_pixel(0, y, beam)
		img.set_pixel(LAST, y, beam.darkened(WALL_RIGHT_BEAM_SHADE))
	for x in SIZE:
		img.set_pixel(x, LAST, beam.darkened(WALL_SILL_SHADE))
	return img


static func _roof(base: Color) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for row in SHINGLE_ROWS:
		var y0 := row * SHINGLE_HEIGHT
		var offset := 0 if row % 2 == 0 else SHINGLE_STAGGER
		for y in range(y0, y0 + SHINGLE_HEIGHT):
			for x in SIZE:
				var c := base
				if y == y0 + SHINGLE_HEIGHT - 1:
					c = base.darkened(SHINGLE_GAP_SHADE)
				elif y == y0:
					c = base.lightened(SHINGLE_TOP_LIGHT)
				if (x + offset) % SHINGLE_WIDTH == 0 and y != y0 + SHINGLE_HEIGHT - 1:
					c = base.darkened(SHINGLE_EDGE_SHADE)
				img.set_pixel(x, y, c)
	return img
