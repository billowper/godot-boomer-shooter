# SwayController.gd
# Converted from SwayController.cs

# This script manages a 2D sway effect using two ValueAnimator instances.

class_name SwayController
extends Resource # Extend Resource for easier saving/loading in Godot

@export var sway_x: ValueAnimator = ValueAnimator.new() # Instance of ValueAnimator for X-axis sway
@export var sway_y: ValueAnimator = ValueAnimator.new() # Instance of ValueAnimator for Y-axis sway
@export var lerp_speed: float = 5.0

var _position: Vector3 = Vector3.ZERO # Internal position for the sway effect

# Updates the sway position based on input speeds and a range multiplier.
# delta_time: The time elapsed since the last frame.
# speed_x: The speed multiplier for the X-axis sway.
# speed_y: The speed multiplier for the Y-axis sway.
# range_multiplier: A multiplier applied to the range of the sway.
func update_sway(delta_time: float, 
	speed_x: float, 
	speed_y: float, 
	range_multiplier: float,
	speed_multiplier: float = 1.0) -> Vector3:
	var new_sway_position: Vector3 = Vector3.ZERO

	# Calculate X-axis sway if speed_x is greater than 0
	if speed_x > 0:
		new_sway_position.x = sway_x.get_value(delta_time, speed_x * speed_multiplier, range_multiplier)

	# Calculate Y-axis sway if speed_y is greater than 0
	if speed_y > 0:
		new_sway_position.y = sway_y.get_value(delta_time, speed_y * speed_multiplier, range_multiplier)

	# Lerp the current position towards the new sway position
	_position = _position.lerp(new_sway_position, delta_time * lerp_speed)

	return _position
