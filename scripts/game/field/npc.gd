class_name NPC
extends AnimatableBody3D
## A villager the player can talk to. Wanderers run a small state machine:
## wait (pause, pick a spot) -> walk (head there) -> wait ... ; talking freezes them.

# Collision capsule
const COLLIDER_RADIUS := 0.3
const COLLIDER_HEIGHT := 1.0
const COLLIDER_OFFSET := Vector3(0, 0.5, 0)

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

var machine: StateMachine
var _bubble: TalkBubble
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
	_bubble = TalkBubble.new()
	add_child(_bubble)
	_rng.seed = hash(npc_id)


func _ready() -> void:
	home = position
	machine = StateMachine.new(self)
	machine.add_state(&"wait", WaitState.new()).add_state(&"walk", WalkState.new())
	machine.start(&"wait", {"min": INITIAL_WAIT_MIN, "max": INITIAL_WAIT_MAX})


func show_bubble(on: bool) -> void:
	_bubble.visible = on and not talking


func face_towards(p: Vector3) -> void:
	var d := p - global_position
	sprite.face_vector(Vector2(d.x, d.z))


func _physics_process(delta: float) -> void:
	if not wander or talking:
		sprite.walking = false
		return
	machine.update(delta)


func random_wait(min_time: float, max_time: float) -> float:
	return _rng.randf_range(min_time, max_time)


func random_wander_target() -> Vector3:
	return home + Vector3(_rng.randf_range(-WANDER_RANGE_X, WANDER_RANGE_X), 0,
		_rng.randf_range(-WANDER_RANGE_Z, WANDER_RANGE_Z))


## Stands still for a random time, then walks to a random spot near home.
class WaitState extends State:
	var remaining := 0.0

	func enter(msg: Dictionary = {}) -> void:
		var npc: NPC = host
		remaining = npc.random_wait(msg.get("min", NPC.IDLE_WAIT_MIN), msg.get("max", NPC.IDLE_WAIT_MAX))
		npc.sprite.walking = false

	func update(delta: float) -> void:
		remaining -= delta
		if remaining <= 0.0:
			transition_to(&"walk", {"target": (host as NPC).random_wander_target()})


## Walks toward a target; stops early (and waits) if something is in the way.
class WalkState extends State:
	var target := Vector3.ZERO

	func enter(msg: Dictionary = {}) -> void:
		target = msg.target

	func update(delta: float) -> void:
		var npc: NPC = host
		var to := target - npc.position
		to.y = 0
		if to.length() < NPC.ARRIVE_DISTANCE:
			transition_to(&"wait")
			return
		var step := to.normalized() * NPC.WALK_SPEED * delta
		if npc.move_and_collide(step, true):
			transition_to(&"wait", {"min": NPC.BLOCKED_WAIT_MIN, "max": NPC.BLOCKED_WAIT_MAX})
			return
		npc.position += step
		npc.sprite.walking = true
		npc.sprite.face_vector(Vector2(step.x, step.z))
