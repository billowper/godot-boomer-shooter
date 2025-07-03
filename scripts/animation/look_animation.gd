class_name LookAnimation
extends Resource

@export var duration: float = 0.3
@export var x_animator: ValueAnimator = ValueAnimator.new() # Renamed from 'X' to avoid conflict
@export var y_animator: ValueAnimator = ValueAnimator.new() # Renamed from 'Y' to avoid conflict

var _time_elapsed: float = 0.0
var _rotation_vector: Vector3 = Vector3.ZERO # Using Vector3 to match C# Vector3 for m_rotation

var _is_active: bool = false

# Activates the look animation.
func activate() -> void:
    _time_elapsed = 0.0
    x_animator.reset_values()
    y_animator.reset_values()
    _is_active = true

# Returns true if the look animation is active.
func is_active() -> bool:
    return _is_active

# Gets the look vector based on delta_time.
func get_look_vector(delta_time: float) -> Vector2:
    _rotation_vector.x = x_animator.get_value(delta_time, 1.0)
    _rotation_vector.y = y_animator.get_value(delta_time, 1.0)

    _time_elapsed += delta_time

    if _time_elapsed > duration:
        _is_active = false

    return Vector2(_rotation_vector.x, _rotation_vector.y)
