class_name NPC
extends AnimatableBody3D
## A villager the player can talk to. Optionally wanders around its home cell.

# Collision capsule
const COLLIDER_RADIUS := 0.3
const COLLIDER_HEIGHT := 1.0
const COLLIDER_OFFSET := Vector3(0, 0.5, 0)

# "!" talk bubble
const BUBBLE_FONT_SIZE := 64
const BUBBLE_OUTLINE_SIZE := 16
const BUBBLE_PIXEL_SIZE := 0.008
const BUBBLE_COLOR := Color(1.0, 0.92, 0.45)
const BUBBLE_HEIGHT := 1.95
## Bob speed in radians per millisecond.
const BUBBLE_BOB_SPEED := 0.008
const BUBBLE_BOB_AMPLITUDE := 0.05

# Wandering
const WALK_SPEED := 1.6
## Max offset of a wander target from the home position.
const WANDER_RANGE_X := 2.0
const WANDER_RANGE_Z := 1.5
const ARRIVE_DISTANCE := 0.05
# Pause durations (seconds), randomised in [MIN, MAX]
const INITIAL_WAIT_MIN := 0.5
const INITIAL_WAIT_MAX := 2.0
const IDLE_WAIT_MIN := 1.0
const IDLE_WAIT_MAX := 3.0
const BLOCKED_WAIT_MIN := 0.5
const BLOCKED_WAIT_MAX := 1.5

var npc_id := ""
var display_name := ""
var sprite: CharacterSprite
var wander := false
var home := Vector3.ZERO
var talking := false

var _target := Vector3.ZERO
var _wait := 0.0
var _bubble: Label3D
var _rng := RandomNumberGenerator.new()


func setup(data: Dictionary) -> void:
	npc_id = data.id
	display_name = data.name
	wander = data.get("wander", false)
	sync_to_physics = false
	var shape := CapsuleShape3D.new()
	shape.radius = COLLIDER_RADIUS
	shape.height = COLLIDER_HEIGHT
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = COLLIDER_OFFSET
	add_child(cs)
	sprite = CharacterSprite.new()
	sprite.setup(data.sprite)
	sprite.facing = data.get("facing", 0)
	add_child(sprite)
	_bubble = Label3D.new()
	_bubble.text = "!"
	_bubble.font_size = BUBBLE_FONT_SIZE
	_bubble.outline_size = BUBBLE_OUTLINE_SIZE
	_bubble.pixel_size = BUBBLE_PIXEL_SIZE
	_bubble.modulate = BUBBLE_COLOR
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.position = Vector3(0, BUBBLE_HEIGHT, 0)
	_bubble.visible = false
	add_child(_bubble)
	_rng.seed = hash(npc_id)


func _ready() -> void:
	home = position
	_target = home
	_wait = _rng.randf_range(INITIAL_WAIT_MIN, INITIAL_WAIT_MAX)


func show_bubble(on: bool) -> void:
	_bubble.visible = on and not talking
	if on:
		_bubble.position.y = BUBBLE_HEIGHT + sin(Time.get_ticks_msec() * BUBBLE_BOB_SPEED) * BUBBLE_BOB_AMPLITUDE


func face_towards(p: Vector3) -> void:
	var d := p - global_position
	sprite.face_vector(Vector2(d.x, d.z))


func _physics_process(delta: float) -> void:
	if not wander or talking:
		sprite.walking = false
		return
	if _wait > 0.0:
		_wait -= delta
		sprite.walking = false
		if _wait <= 0.0:
			var offset := Vector3(_rng.randf_range(-WANDER_RANGE_X, WANDER_RANGE_X), 0,
				_rng.randf_range(-WANDER_RANGE_Z, WANDER_RANGE_Z))
			_target = home + offset
		return
	var to := _target - position
	to.y = 0
	if to.length() < ARRIVE_DISTANCE:
		_wait = _rng.randf_range(IDLE_WAIT_MIN, IDLE_WAIT_MAX)
		return
	var step := to.normalized() * WALK_SPEED * delta
	var col := move_and_collide(step, true)
	if col:
		_wait = _rng.randf_range(BLOCKED_WAIT_MIN, BLOCKED_WAIT_MAX)
		return
	position += step
	sprite.walking = true
	sprite.face_vector(Vector2(step.x, step.z))
