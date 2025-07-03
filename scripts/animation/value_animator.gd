# ValueAnimator.gd
# Converted from ValueAnimator.cs

# This script animates a float value using a speed and a curve, wrapping around the curve.
# It handles both fixed and random ranges for the animation.

class_name ValueAnimator
extends Resource # Extend Resource for easier saving/loading in Godot

@export var range_value: float = 0.0 # Renamed from 'Range' to avoid conflict with GDScript keyword
@export var speed: float = 1.0
@export var curve: Curve = Curve.new() # AnimationCurve equivalent in Godot
@export var loop: bool = true

@export_group("random")
@export var random: bool = false
@export var range_min_max: Vector2 = Vector2(0.0, 0.0) # Used for random range

var _cycle_time: float = 0.0
var _current_range: float = 0.0 # Stores the actual range used (either fixed or random)

# Called when the script is initialized or reset.
# Sets the initial range and resets the cycle time.
func reset_values() -> void:
	_current_range = randf_range(range_min_max.x, range_min_max.y) if random else range_value
	_cycle_time = 0.0

# Returns a lerped value based on a given lerp_value (0.0 to 1.0).
# This is used for durational animations where progress is known.
func get_lerped_value(lerp_value: float) -> float:
	var current_range_to_use = range_value if not random else _current_range
	var value = curve.sample(lerp_value) * current_range_to_use
	_cycle_time = lerp_value # Update cycle time to reflect the lerp progress
	return value

# Returns a continuous value based on delta_time, speed_multiplier, and range_multiplier.
# This is used for continuous animations like sway.
func get_value(delta_time: float, speed_multiplier: float, range_multiplier: float = 1.0) -> float:
	var current_range_to_use = range_value if not random else _current_range
	var value = curve.sample(_cycle_time) * (current_range_to_use * range_multiplier)

	_cycle_time += speed * delta_time * speed_multiplier

	if loop:
		# Ensure cycle_time wraps around between 0 and 1
		if _cycle_time > 1.0:
			_cycle_time -= 1.0
		elif _cycle_time < 0.0: # Handle negative delta_time if needed, though not in original
			_cycle_time += 1.0
	else:
		# Clamp cycle_time between 0 and 1 if not wrapping
		_cycle_time = clampf(_cycle_time, 0.0, 1.0)

	return value

