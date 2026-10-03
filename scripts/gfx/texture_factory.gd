class_name TextureFactory
extends RefCounted
## Procedural 16x16 pixel-art tile textures and the materials that use them.
## One tile = one world unit = 16 texels, matching the sprite pixel density.

const SIZE := 16

static var _textures := {}
static var _materials := {}


static func get_texture(kind: String) -> Texture2D:
	if _textures.has(kind):
		return _textures[kind]
	var img: Image
	match kind:
		"grass": img = _grass(Color("4f9a3e"), Color("3f8434"), Color("67b24c"), Color("8acd62"), 11)
		"grass_dark": img = _grass(Color("3d7d36"), Color("2f6a2e"), Color("4f9a3e"), Color("6fb653"), 12)
		"tall_grass": img = _grass(Color("3a7a33"), Color("2c652a"), Color("4c9440"), Color("5faa4c"), 13)
		"cliff_top": img = _grass(Color("4a8f3c"), Color("3a7a33"), Color("5fa64a"), Color("7cc05c"), 14)
		"dirt": img = _dirt()
		"stone": img = _stone_floor()
		"wood": img = _planks(Color("a0703a"))
		"cliff_side": img = _cliff_side(false)
		"cliff_side_top": img = _cliff_side(true)
		"ground_side": img = _ground_side()
		"house_wall": img = _house_wall()
		"house_beam": img = _planks(Color("6b4528"))
		"roof_red": img = _roof(Color("b84a3a"))
		"roof_blue": img = _roof(Color("3f6ab0"))
		"roof_green": img = _roof(Color("4f8a5a"))
		"roof_brown": img = _roof(Color("8a5a3a"))
		_: img = _grass(Color.MAGENTA, Color.MAGENTA, Color.MAGENTA, Color.MAGENTA, 1)
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
	mat.roughness = 0.92
	mat.metallic_specular = 0.25
	if kind.begins_with("roof"):
		mat.roughness = 0.7
		mat.metallic_specular = 0.4
	_materials[kind] = mat
	return mat


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _grass(base: Color, dark: Color, light: Color, highlight: Color, seed_value: int) -> Image:
	var rng := _rng(seed_value)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in 40:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), dark)
	for i in 22:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(1, 15)
		img.set_pixel(x, y, light)
		img.set_pixel(x, y - 1, light)
	for i in 6:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), highlight)
	return img


static func _dirt() -> Image:
	var rng := _rng(21)
	var base := Color("b08a5a")
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in 45:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), base.darkened(0.12))
	for i in 18:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), base.lightened(0.12))
	for i in 4:
		var x := rng.randi_range(0, 14)
		var y := rng.randi_range(0, 14)
		img.set_pixel(x, y, Color("8a8a8a"))
		img.set_pixel(x + 1, y, Color("6a6a6a"))
		img.set_pixel(x, y + 1, Color("5a5a5a"))
	return img


static func _stone_floor() -> Image:
	var rng := _rng(31)
	var mortar := Color("8a8070")
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(mortar)
	# Two rows of offset flagstones per tile.
	for row in 2:
		var y0 := row * 8
		var offset := 0 if row == 0 else 4
		for col in 3:
			var x0 := col * 8 - offset
			var tone := Color("c8bca4").darkened(rng.randf_range(0.0, 0.15))
			for y in range(y0, y0 + 7):
				for x in range(x0, x0 + 7):
					var wx := posmod(x, SIZE)
					var c := tone
					if y == y0:
						c = tone.lightened(0.15)
					elif y == y0 + 6 or x == x0 + 6:
						c = tone.darkened(0.15)
					img.set_pixel(wx, y, c)
	for i in 10:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.1))
	return img


static func _planks(base: Color) -> Image:
	var rng := _rng(41)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for plank in 4:
		var y0 := plank * 4
		var tone := base.darkened(rng.randf_range(0.0, 0.12))
		for y in range(y0, y0 + 4):
			for x in SIZE:
				var c := tone
				if y == y0 + 3:
					c = base.darkened(0.35)
				elif y == y0:
					c = tone.lightened(0.08)
				img.set_pixel(x, y, c)
		var seam := rng.randi_range(2, 13)
		img.set_pixel(seam, y0 + 1, base.darkened(0.35))
		img.set_pixel(seam, y0 + 2, base.darkened(0.35))
		img.set_pixel(rng.randi_range(0, 15), y0 + 1, tone.darkened(0.18))
	return img


static func _cliff_side(with_fringe: bool) -> Image:
	var rng := _rng(51 if with_fringe else 52)
	var base := Color("8a7a66")
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	# Horizontal strata.
	for y in SIZE:
		var band := base.darkened(0.08 * float((y / 3) % 2))
		for x in SIZE:
			img.set_pixel(x, y, band)
	for i in 6:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		var length := rng.randi_range(2, 5)
		for k in length:
			img.set_pixel(posmod(x + k, SIZE), y, base.darkened(0.35))
			if y > 0:
				img.set_pixel(posmod(x + k, SIZE), y - 1, base.lightened(0.12))
	for i in 3:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 13)
		img.set_pixel(x, y, base.darkened(0.4))
		img.set_pixel(x, y + 1, base.darkened(0.4))
		img.set_pixel(x, y + 2, base.darkened(0.3))
	if with_fringe:
		var g := Color("4a8f3c")
		for x in SIZE:
			var depth := 2 + int(rng.randf() * 3.0)
			if x % 5 == 2:
				depth += 2
			for y in depth:
				img.set_pixel(x, y, g if y < depth - 1 else g.darkened(0.3))
			img.set_pixel(x, depth, base.darkened(0.3))
		for x in SIZE:
			img.set_pixel(x, 0, g.lightened(0.2))
	return img


static func _ground_side() -> Image:
	var rng := _rng(61)
	var base := Color("7a5a3a")
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for i in 30:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), base.darkened(0.2))
	for i in 10:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), base.lightened(0.15))
	var g := Color("4f9a3e")
	for x in SIZE:
		var depth := 2 + (x * 7 % 3)
		for y in depth:
			img.set_pixel(x, y, g if y < depth - 1 else g.darkened(0.3))
	return img


static func _house_wall() -> Image:
	var rng := _rng(71)
	var plaster := Color("e8dcc0")
	var beam := Color("6b4528")
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(plaster)
	for i in 20:
		img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), plaster.darkened(0.07))
	for y in SIZE:
		img.set_pixel(0, y, beam)
		img.set_pixel(15, y, beam.darkened(0.2))
	for x in SIZE:
		img.set_pixel(x, 15, beam.darkened(0.15))
	return img


static func _roof(base: Color) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for row in 4:
		var y0 := row * 4
		var offset := 0 if row % 2 == 0 else 2
		for y in range(y0, y0 + 4):
			for x in SIZE:
				var c := base
				if y == y0 + 3:
					c = base.darkened(0.35)
				elif y == y0:
					c = base.lightened(0.15)
				if (x + offset) % 4 == 0 and y != y0 + 3:
					c = base.darkened(0.2)
				img.set_pixel(x, y, c)
	return img
