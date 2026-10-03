class_name Player
extends CharacterBody3D
## Free-moving overworld hero.

signal moved(distance: float)

const WALK_SPEED := 3.6
const RUN_SPEED := 6.2

var controls_enabled := false
var sprite: CharacterSprite


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.5, 0)
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
	sprite.walking = input.length() > 0.1
	sprite.anim_speed = 10.0 if speed == RUN_SPEED else 7.0
	sprite.face_vector(input)
	var before := global_position
	move_and_slide()
	global_position.y = 0.0
	var dist := before.distance_to(global_position)
	if dist > 0.0001:
		moved.emit(dist)


func facing_vector3() -> Vector3:
	var f := sprite.facing_vector()
	return Vector3(f.x, 0, f.y)
