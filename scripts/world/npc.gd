class_name NPC
extends AnimatableBody3D
## A villager the player can talk to. Optionally wanders around its home cell.

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
	shape.radius = 0.3
	shape.height = 1.0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.5, 0)
	add_child(cs)
	sprite = CharacterSprite.new()
	sprite.setup(data.sprite)
	sprite.facing = data.get("facing", 0)
	add_child(sprite)
	_bubble = Label3D.new()
	_bubble.text = "!"
	_bubble.font_size = 64
	_bubble.outline_size = 16
	_bubble.pixel_size = 0.008
	_bubble.modulate = Color(1.0, 0.92, 0.45)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.position = Vector3(0, 1.95, 0)
	_bubble.visible = false
	add_child(_bubble)
	_rng.seed = hash(npc_id)


func _ready() -> void:
	home = position
	_target = home
	_wait = _rng.randf_range(0.5, 2.0)


func show_bubble(on: bool) -> void:
	_bubble.visible = on and not talking
	if on:
		_bubble.position.y = 1.95 + sin(Time.get_ticks_msec() * 0.008) * 0.05


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
			var offset := Vector3(_rng.randf_range(-2.0, 2.0), 0, _rng.randf_range(-1.5, 1.5))
			_target = home + offset
		return
	var to := _target - position
	to.y = 0
	if to.length() < 0.05:
		_wait = _rng.randf_range(1.0, 3.0)
		return
	var step := to.normalized() * 1.6 * delta
	var col := move_and_collide(step, true)
	if col:
		_wait = _rng.randf_range(0.5, 1.5)
		return
	position += step
	sprite.walking = true
	sprite.face_vector(Vector2(step.x, step.z))
