# DurationalAnimation.gd
# Converted from DurationalAnimation.cs

# This script handles animations with a fixed duration, for both position and rotation.
# It supports both lerped (progress-based) and continuous (delta-time based) updates.

class_name DurationalAnimation
extends Resource # Extend Resource for easier saving/loading in Godot

@export var duration: float = 0.3
@export var position_x: ValueAnimator = ValueAnimator.new() # For X-axis position animation
@export var position_y: ValueAnimator = ValueAnimator.new() # For Y-axis position animation
@export var position_z: ValueAnimator = ValueAnimator.new() # For Z-axis position animation
@export var rotation_x: ValueAnimator = ValueAnimator.new() # For X-axis rotation animation
@export var rotation_y: ValueAnimator = ValueAnimator.new() # For Y-axis rotation animation
@export var rotation_z: ValueAnimator = ValueAnimator.new() # For Z-axis rotation animation

var _position: Vector3 = Vector3.ZERO
var _time_since_start: float = 100.0 # Initialize to a high value to be inactive by default

# Activates the animation, setting the starting position and resetting animators.
func activate(start_pos: Vector3) -> void:
	_position = start_pos
	_time_since_start = 0.0

	position_x.reset_values()
	position_y.reset_values()
	position_z.reset_values()

	rotation_x.reset_values()
	rotation_y.reset_values()
	rotation_z.reset_values()

# Resets the animation, making it inactive.
func reset() -> void:
	_time_since_start = INF # Use INF for float.MaxValue equivalent

# Returns true if the animation is currently active (time_since_start is less than duration).
func is_active() -> bool:
	return _time_since_start < duration

# Returns the progress of the animation as a percentage (0.0 to 1.0).
func get_progress_percentage() -> float:
	return _time_since_start / duration

# Updates the animation using lerped values based on the progress percentage.
# This is suitable for animations where the total duration is known and progress is key.
func update_lerped(delta_time: float) -> Dictionary:
	_time_since_start += delta_time

	var progress = get_progress_percentage()

	_position.x = position_x.get_lerped_value(progress)
	_position.y = position_y.get_lerped_value(progress)
	_position.z = position_z.get_lerped_value(progress)

	var rotation_euler = Vector3(
		rotation_x.get_lerped_value(progress),
		rotation_y.get_lerped_value(progress),
		rotation_z.get_lerped_value(progress)
	)
	# In Godot, Quaternion.Euler is not directly available.
	# We can construct a Basis from Euler angles and then get its rotation quaternion.
	var rotation_quat = Basis.from_euler(rotation_euler).get_rotation_quaternion()

	return {"position": _position, "rotation": rotation_quat}

# Updates the animation using continuous values based on delta_time.
# This is suitable for animations that run continuously without a fixed end.
func update_continuous(delta_time: float) -> Dictionary:
	_time_since_start += delta_time

	_position.x = position_x.get_value(delta_time, 1.0)
	_position.y = position_y.get_value(delta_time, 1.0)
	_position.z = position_z.get_value(delta_time, 1.0)

	var rotation_euler = Vector3(
		rotation_x.get_value(delta_time, 1.0),
		rotation_y.get_value(delta_time, 1.0),
		rotation_z.get_value(delta_time, 1.0)
	)
	var rotation_quat = Basis.from_euler(rotation_euler).get_rotation_quaternion()

	return {"position": _position, "rotation": rotation_quat}


