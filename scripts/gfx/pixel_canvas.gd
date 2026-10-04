class_name PixelCanvas
extends RefCounted
## Small helper for drawing pixel art into an Image at runtime.

# Colors & alpha
const TRANSPARENT := Color(0, 0, 0, 0)
## Pixels with alpha at or below this count as empty.
const ALPHA_EPSILON := 0.01

# shade_ellipse(): light direction weights and the band where the mid tone sits.
const SHADE_DIR_X := 0.45
const SHADE_DIR_Y := 0.9
const SHADE_BAND := 0.45

# auto_shade() defaults
const AUTO_SHADE_DARK := 0.22
const AUTO_SHADE_LIGHT := 0.12

# Neighbor offsets used by outline()
const ORTHOGONAL_NEIGHBORS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAGONAL_NEIGHBORS := [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1)]

var image: Image
var width: int
var height: int


func _init(w: int, h: int) -> void:
	width = w
	height = h
	image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)


func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		image.set_pixel(x, y, c)


func get_px(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= width or y >= height:
		return TRANSPARENT
	return image.get_pixel(x, y)


func is_filled(x: int, y: int) -> bool:
	return get_px(x, y).a > ALPHA_EPSILON


func rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for iy in range(y, y + h):
		for ix in range(x, x + w):
			px(ix, iy, c)


func hline(x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(min(x0, x1), max(x0, x1) + 1):
		px(x, y, c)


func vline(x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(min(y0, y1), max(y0, y1) + 1):
		px(x, y, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				px(x, y, c)


## Shades an already-drawn ellipse region with a vertical gradient (top light, bottom dark).
func shade_ellipse(cx: float, cy: float, rx: float, ry: float, light: Color, mid: Color, dark: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			# Light comes from the upper left.
			var t := (nx * SHADE_DIR_X + ny * SHADE_DIR_Y)
			if t < -SHADE_BAND:
				px(x, y, light)
			elif t > SHADE_BAND:
				px(x, y, dark)
			else:
				px(x, y, mid)


## Adds a 1px outline around all opaque pixels.
func outline(c: Color, diagonal: bool = false) -> void:
	var src := image.duplicate() as Image
	for y in height:
		for x in width:
			if src.get_pixel(x, y).a > ALPHA_EPSILON:
				continue
			var hit := false
			for d in ORTHOGONAL_NEIGHBORS:
				if _src_filled(src, x + d.x, y + d.y):
					hit = true
					break
			if not hit and diagonal:
				for d in DIAGONAL_NEIGHBORS:
					if _src_filled(src, x + d.x, y + d.y):
						hit = true
						break
			if hit:
				image.set_pixel(x, y, c)


## Darkens the right-most/bottom pixels and lightens the top-left edge of each shape
## to give flat-colored sprites a little volume.
func auto_shade(dark_amount: float = AUTO_SHADE_DARK, light_amount: float = AUTO_SHADE_LIGHT) -> void:
	var src := image.duplicate() as Image
	for y in height:
		for x in width:
			var c := src.get_pixel(x, y)
			if c.a < ALPHA_EPSILON:
				continue
			var right_empty := not _src_filled(src, x + 1, y)
			var below_empty := not _src_filled(src, x, y + 1)
			var left_empty := not _src_filled(src, x - 1, y)
			var above_empty := not _src_filled(src, x, y - 1)
			if right_empty or below_empty:
				image.set_pixel(x, y, c.darkened(dark_amount))
			elif left_empty and above_empty:
				image.set_pixel(x, y, c.lightened(light_amount))


func blit(other: PixelCanvas, ox: int, oy: int, flip_h: bool = false) -> void:
	for y in other.height:
		for x in other.width:
			var c := other.image.get_pixel(x, y)
			if c.a < ALPHA_EPSILON:
				continue
			var tx := ox + (other.width - 1 - x if flip_h else x)
			px(tx, oy + y, c)


func to_texture() -> ImageTexture:
	return ImageTexture.create_from_image(image)


func _src_filled(src: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return src.get_pixel(x, y).a > ALPHA_EPSILON
