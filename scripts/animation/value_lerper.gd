# ValueLerper.gd
# Converted from ValueLerper.cs

# This script lerps a value between -Range and +Range using a specified speed.

class_name ValueLerper
extends Resource # Extend Resource for easier saving/loading in Godot

@export var range_value: float = 0.0 # Renamed from 'Range' to avoid conflict with GDScript keyword
@export var speed: float = 0.0

var _multiplier: float = 0.0 # Internal multiplier for the lerped value

# Calculates and returns the lerped value.
# target_multiplier: The target value for the internal multiplier (-1.0 to 1.0).
# range_multiplier: A multiplier applied to the overall range.
# delta_time: The time elapsed since the last frame.
func get_value(target_multiplier: float, range_multiplier: float, delta_time: float) -> float:
	# Lerp the internal multiplier towards the target
	_multiplier = lerp(_multiplier, target_multiplier, speed * delta_time)
	# Clamp the multiplier to ensure it stays within -1.0 and 1.0
	_multiplier = clampf(_multiplier, -1.0, 1.0)

	# Calculate the final value based on range, range_multiplier, and the current multiplier
	return range_value * range_multiplier * _multiplier

