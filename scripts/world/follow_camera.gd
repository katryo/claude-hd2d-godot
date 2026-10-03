class_name FollowCamera
extends Camera3D
## Tilted, narrow-FOV camera that smoothly trails a target, HD-2D style.
## The focus distance of the depth-of-field effect follows the target.

var target: Node3D
var pitch_deg := 40.0
var distance := 21.0
var look_offset := Vector3(0, 0.8, 0)
var smoothing := 5.0
var bounds := Rect2(-1000, -1000, 2000, 2000)
var sway_time := 0.0


func _ready() -> void:
	fov = 30.0
	near = 0.5
	far = 200.0


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
		attrs.dof_blur_far_distance = focus_dist + 4.0
		attrs.dof_blur_near_distance = max(focus_dist - 7.0, 0.5)


func _look() -> void:
	var pitch := deg_to_rad(pitch_deg)
	# Gentle breathing motion keeps the diorama feeling alive.
	var yaw := sin(sway_time * 0.25) * 0.012
	rotation = Vector3(-pitch, yaw, 0)
