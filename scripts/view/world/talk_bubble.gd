class_name TalkBubble
extends Label3D
## Bobbing "!" shown over a villager the player can talk to.

const FONT_SIZE := 64
const OUTLINE_SIZE := 16
const PIXEL_SIZE := 0.008
const COLOR := Color(1.0, 0.92, 0.45)
const HEIGHT := 1.95
## Bob speed in radians per millisecond.
const BOB_SPEED := 0.008
const BOB_AMPLITUDE := 0.05


func _init() -> void:
	text = "!"
	font_size = FONT_SIZE
	outline_size = OUTLINE_SIZE
	pixel_size = PIXEL_SIZE
	modulate = COLOR
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	position = Vector3(0, HEIGHT, 0)
	visible = false


func _process(_delta: float) -> void:
	if visible:
		position.y = HEIGHT + sin(Time.get_ticks_msec() * BOB_SPEED) * BOB_AMPLITUDE
