class_name FollowCamera
extends Camera3D
## Tilted, narrow-FOV camera that smoothly trails a target, HD-2D style.
## The focus distance of the depth-of-field effect follows the target.

# Default framing (tunable per instance through the vars below)
const DEFAULT_PITCH_DEG := 40.0
const DEFAULT_DISTANCE := 21.0
const DEFAULT_LOOK_OFFSET := Vector3(0, 0.8, 0)
const DEFAULT_SMOOTHING := 5.0
## Effectively unbounded until the field sets real bounds.
const DEFAULT_BOUNDS := Rect2(-1000, -1000, 2000, 2000)

# Lens
const FOV := 30.0
const NEAR_CLIP := 0.5
const FAR_CLIP := 200.0

# Depth of field, relative to the focus distance
const DOF_FAR_OFFSET := 4.0
const DOF_NEAR_OFFSET := 7.0
const DOF_MIN_NEAR_DISTANCE := 0.5

# Idle sway
const SWAY_SPEED := 0.25
## Yaw amplitude in radians.
const SWAY_AMPLITUDE := 0.012

var target: Node3D
var pitch_deg := DEFAULT_PITCH_DEG
var distance := DEFAULT_DISTANCE
var look_offset := DEFAULT_LOOK_OFFSET
var smoothing := DEFAULT_SMOOTHING
var bounds := DEFAULT_BOUNDS
var sway_time := 0.0


func _ready() -> void:
	fov = FOV
	near = NEAR_CLIP
	far = FAR_CLIP


func snap() -> void:
	if target:
		global_position = _desired_position(target.global_position)
		_look()


func _desired_position(focus: Vector3) -> Vector3:
	var clamped := focus
	clamped.x = clamp(clamped.x, bounds.position.x, bounds.end.x)
	clamped.z = clamp(clamped.z, bounds.position.y, bounds.end.y)
	var pitch := deg_to_rad(pitch_deg)
	var back := Vector3(0, sin(pitch), cos(pitch)) * distance
	return clamped + look_offset + back


func _process(delta: float) -> void:
	if not target:
		return
	sway_time += delta
	var desired := _desired_position(target.global_position)
	global_position = global_position.lerp(desired, 1.0 - exp(-smoothing * delta))
	_look()
	var attrs := attributes as CameraAttributesPractical
	if attrs:
		var focus_dist := distance
		attrs.dof_blur_far_distance = focus_dist + DOF_FAR_OFFSET
		attrs.dof_blur_near_distance = max(focus_dist - DOF_NEAR_OFFSET, DOF_MIN_NEAR_DISTANCE)


func _look() -> void:
	var pitch := deg_to_rad(pitch_deg)
	# Gentle breathing motion keeps the diorama feeling alive.
	var yaw := sin(sway_time * SWAY_SPEED) * SWAY_AMPLITUDE
	rotation = Vector3(-pitch, yaw, 0)
