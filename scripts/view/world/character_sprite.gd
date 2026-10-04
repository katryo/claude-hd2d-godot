class_name CharacterSprite
extends Sprite3D
## Billboarded pixel-art character with 4-direction walk animation.

enum Facing { DOWN, LEFT, RIGHT, UP }

# Sprite sheet layout: one row per facing, one column per walk frame
const SHEET_COLUMNS := 3
const SHEET_ROWS := 4
const WALK_CYCLE := [1, 0, 2, 0]
## World units per texel (16 texels per world unit).
const PIXEL_SIZE := 1.0 / 16.0
## Lifts the sprite so its feet rest on the ground.
const SPRITE_OFFSET := Vector2(0, 12)

# Animation / facing
const DEFAULT_ANIM_SPEED := 7.0
## Directions shorter than this (squared) keep the current facing.
const MIN_FACE_LENGTH_SQ := 0.0001
## Horizontal bias so diagonals prefer facing up/down.
const HORIZONTAL_FACE_BIAS := 1.05

var facing: int = Facing.DOWN
var walking := false
var anim_speed := DEFAULT_ANIM_SPEED
var _anim_time := 0.0


func setup(kind: String) -> void:
	texture = SpriteFactory.character_sheet(kind)
	hframes = SHEET_COLUMNS
	vframes = SHEET_ROWS
	pixel_size = PIXEL_SIZE
	offset = SPRITE_OFFSET
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	shaded = true
	double_sided = true
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_update_frame()


func face_vector(dir: Vector2) -> void:
	if dir.length_squared() < MIN_FACE_LENGTH_SQ:
		return
	if abs(dir.x) > abs(dir.y) * HORIZONTAL_FACE_BIAS:
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP
	_update_frame()


func facing_vector() -> Vector2:
	match facing:
		Facing.LEFT: return Vector2.LEFT
		Facing.RIGHT: return Vector2.RIGHT
		Facing.UP: return Vector2.UP
	return Vector2.DOWN


func _process(delta: float) -> void:
	if walking:
		_anim_time += delta * anim_speed
	else:
		_anim_time = 0.0
	_update_frame()


func _update_frame() -> void:
	var col := 0
	if walking:
		col = WALK_CYCLE[int(_anim_time) % WALK_CYCLE.size()]
	frame = facing * SHEET_COLUMNS + col
