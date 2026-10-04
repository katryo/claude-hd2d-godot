class_name Player
extends CharacterBody3D
## Free-moving overworld hero.

signal moved(distance: float)

# Movement
const WALK_SPEED := 3.6
const RUN_SPEED := 6.2
## Minimum stick/key input length that counts as walking.
const WALK_INPUT_DEADZONE := 0.1
## Distances below this are not reported through `moved`.
const MIN_MOVE_DISTANCE := 0.0001

# Walk animation speed (frames per second)
const WALK_ANIM_SPEED := 7.0
const RUN_ANIM_SPEED := 10.0

# Collision capsule
const COLLIDER_RADIUS := 0.28
const COLLIDER_HEIGHT := 1.0
const COLLIDER_OFFSET := Vector3(0, 0.5, 0)

var controls_enabled := false
var sprite: CharacterSprite


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CapsuleShape3D.new()
	shape.radius = COLLIDER_RADIUS
	shape.height = COLLIDER_HEIGHT
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = COLLIDER_OFFSET
	add_child(cs)
	sprite = CharacterSprite.new()
	sprite.setup("hero")
	add_child(sprite)


func _physics_process(_delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = Vector3(input.x, 0, input.y) * speed
	sprite.walking = input.length() > WALK_INPUT_DEADZONE
	sprite.anim_speed = RUN_ANIM_SPEED if speed == RUN_SPEED else WALK_ANIM_SPEED
	sprite.face_vector(input)
	var before := global_position
	move_and_slide()
	global_position.y = 0.0
	var dist := before.distance_to(global_position)
	if dist > MIN_MOVE_DISTANCE:
		moved.emit(dist)


func facing_vector3() -> Vector3:
	var f := sprite.facing_vector()
	return Vector3(f.x, 0, f.y)


func face_towards(p: Vector3) -> void:
	var d := p - global_position
	sprite.face_vector(Vector2(d.x, d.z))


func stop() -> void:
	controls_enabled = false
	sprite.walking = false
