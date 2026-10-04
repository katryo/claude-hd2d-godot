class_name BossEntity
extends StaticBody3D
## The King Slime waiting in the shrine: a solid body with an animated sprite and glow.

const COLLIDER_RADIUS := 1.1
const COLLIDER_HEIGHT := 2.0
const COLLIDER_OFFSET := Vector3(0, 1, 0)
const SPRITE_FRAMES := 2
const PIXEL_SIZE := 1.0 / 16.0 * 2.2
const SPRITE_OFFSET := Vector2(0, 12)
const ANIM_FPS := 2.0
const GLOW_COLOR := Color(0.5, 0.6, 1.0)
const GLOW_ENERGY := 1.5
const GLOW_RANGE := 5.0
const GLOW_OFFSET := Vector3(0, 1.0, 1.2)

var _sprite: Sprite3D
var _time := 0.0


func _init(enemy_sprite_id: String) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = COLLIDER_RADIUS
	shape.height = COLLIDER_HEIGHT
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = COLLIDER_OFFSET
	add_child(cs)
	_sprite = Sprite3D.new()
	_sprite.texture = SpriteFactory.enemy_sheet(enemy_sprite_id)
	_sprite.hframes = SPRITE_FRAMES
	_sprite.pixel_size = PIXEL_SIZE
	_sprite.offset = SPRITE_OFFSET
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.shaded = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	var glow := OmniLight3D.new()
	glow.light_color = GLOW_COLOR
	glow.light_energy = GLOW_ENERGY
	glow.omni_range = GLOW_RANGE
	glow.position = GLOW_OFFSET
	add_child(glow)


func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * ANIM_FPS) % SPRITE_FRAMES
