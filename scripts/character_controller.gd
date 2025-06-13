class_name CharacterController
extends CharacterBody3D

@export_group("General Settings")
@export var gravity = 18.0
@export var friction = 4.5
@export var walk_speed = 3.0
@export var run_speed = 6.0
@export var crouch_speed = 2.0
@export var acceleration = 1.5
@export var stop_speed = 2.0

@export_group("Jumping & Air Control")
@export var max_air_speed = 1.5
@export var jump_velocity = 4.5
@export var wall_jump_force = 4.5
@export var coyote_time = .15

@export_group("Stepping")
@export var stepping_enabled := false
@export var step_height := 0.4 
@export var step_height_air := 0.4 
@export var step_offset := 0.1
@export var step_safe_margin := 0.1
@export var step_ledge_dist := 0.1
@export var step_climb_speed_multi := 2.0

@export_group("Climbing")
## max horizontal distance to a ledge to be considered for climbing.
@export var climb_ledge_dist := 2.0
@export var climb_speed := 4.0
## Minimum height of a ledge to be considered for climbing. 
@export var climb_ledge_min_height := 4.0

@export_group("Collision Shapes")
@export var collision_default: CollisionShape3D
@export var collision_crouched: CollisionShape3D

@export_group("Ledge Detection")
@export var ledge_detection_settings: LedgeDetectionSettings
@export var show_ledge_debug := false

enum JumpTypes
{
	None,
	Normal,
	DoubleJump,
	WallJump
}

var _jump_requested := false
var _wish_direction := Vector3.ZERO
var _crouch_requested := false
var _walk_requested := false
var _climb_requested := false
var _is_crouching := false
var _time_since_grounded := 0.0
var _stepping_ledge: Ledge = null
var _climbing_ledge: Ledge = null

signal jumped
signal landed
signal crouchStateChanged(state: bool)

func set_inputs(crouch_requested: bool, jump_requested: bool, climb_requested: bool, walk_requested: bool, wish_direction: Vector3) -> void:
	_crouch_requested = crouch_requested
	_jump_requested = jump_requested
	_wish_direction = wish_direction
	_walk_requested = walk_requested
	_climb_requested = climb_requested

func _ready():
	collision_crouched.disabled = true;

func _physics_process(delta: float) -> void:

	# handle crouch
	if _crouch_requested:
		set_crouch(true)
	elif can_stand():
		set_crouch(false)

	# jump
	if _jump_requested:
		var jump_type = can_jump()
		jump(jump_type, delta)

	_jump_requested = false

	if _stepping_ledge:
		update_step_movement(delta)
		return

	if _climbing_ledge:
		update_climb_movement(delta)
		return

	if try_find_ledge(global_position, delta):
		return

	var was_grounded := is_on_floor()

	if is_on_floor():
		velocity = update_velocity_grounded(_wish_direction, get_max_ground_speed(), delta)
		_time_since_grounded = 0
	else:
		velocity = update_velocity_air(_wish_direction, delta)
		_time_since_grounded += delta

	move_and_slide()

	if not was_grounded and is_on_floor():
		print("Landed")
		landed.emit()

func jump(jump_type: JumpTypes, delta: float) -> void:

	if jump_type == JumpTypes.None:
		return

	print("jumped:", jump_type)

	match jump_type:
		JumpTypes.Normal:
			velocity.y = sqrt(2 * gravity * jump_velocity)
		JumpTypes.DoubleJump:
			velocity.y = sqrt(2 * gravity * jump_velocity)
		JumpTypes.WallJump:
			velocity.y = sqrt(2 * gravity * jump_velocity)
			velocity += get_slide_collision(0).get_normal() * wall_jump_force

	velocity = update_velocity_air(-_wish_direction, delta)
	jumped.emit()

func get_max_ground_speed() -> float:
	var max_speed = crouch_speed if _is_crouching else run_speed

	if !_is_crouching and _walk_requested:
		max_speed = walk_speed

	return max_speed

func update_velocity_grounded(wish_direction: Vector3, max_speed: float, delta: float) -> Vector3:
	var speed = velocity.length()
	if (speed != 0):
		var control = max(stop_speed, speed)
		var drop = control * friction * delta
		velocity *= max(speed - drop, 0) / speed

	return accelerate(wish_direction, max_speed, delta)

func update_velocity_air(wish_direction: Vector3, delta: float) -> Vector3:
	velocity += Vector3.DOWN * gravity * delta
	return accelerate(wish_direction, max_air_speed, delta)

func accelerate(wish_direction: Vector3, max_speed: float, delta: float) -> Vector3:
	var current_speed = velocity.dot(wish_direction)
	var add_speed = clamp(max_speed - current_speed, 0, (acceleration * max_speed) * delta)
	return velocity + add_speed * wish_direction

func can_jump() -> JumpTypes:
	if is_on_floor():
		return JumpTypes.Normal
	if (_time_since_grounded < coyote_time):
		return JumpTypes.Normal
	if (get_slide_collision_count() > 0 and get_slide_collision(0) and get_slide_collision(0).get_collider() != null):
		if (get_slide_collision(0).get_normal().y < 0.3 && _wish_direction.dot(get_slide_collision(0).get_normal()) < 0):
			return JumpTypes.WallJump

	return JumpTypes.None

func can_stand() -> bool:
	if !_is_crouching:
		return true

	var space_state = get_world_3d().direct_space_state
	var parameters = PhysicsShapeQueryParameters3D.new()
	parameters.shape = collision_default.shape
	parameters.transform = collision_default.global_transform
	parameters.collision_mask = self.collision_mask 
	parameters.exclude = [self]
	return space_state.intersect_shape(parameters).is_empty()

func set_crouch(state :bool) -> void:
	if _is_crouching != state:
		_is_crouching = state
		collision_default.disabled = _is_crouching
		collision_crouched.disabled = !_is_crouching
		crouchStateChanged.emit(state)
	
func try_find_ledge(origin: Vector3, delta: float) -> bool:
	# if we're moving horizontally, check for ledges
	var flat_wish_direction = _wish_direction * Vector3(1, 0, 1)
	if flat_wish_direction.length_squared() < 0.01:
		return false

	var space_state = get_world_3d().direct_space_state

	var ledge_query = LedgeDetectionUtil.try_find_ledge(space_state, self, origin + Vector3.UP * step_safe_margin, flat_wish_direction.normalized(), ledge_detection_settings, collision_mask)
	if (ledge_query["summary"] == LedgeDetectionUtil.Results.FOUND_LEDGE):
		
		var ledge: Ledge = ledge_query["ledge"]

		if show_ledge_debug:
			DebugDraw3D.draw_line(ledge.start, ledge.end, Color.GREEN)
			DebugDraw3D.draw_text(ledge.get_midpoint() + Vector3.UP * .1, str(ledge.distance_from_ground), 16, Color.WHITE)

		# ledge is below us, early out
		if ledge.get_midpoint().y <= origin.y:
			print("ledge is below us, skipping")
			return false

		var pos_flat = origin * Vector3(1, 0, 1)
		var ledge_midpoint_flat = ledge.get_midpoint() * Vector3(1, 0, 1)
		var horiz_distance = pos_flat.distance_to(ledge_midpoint_flat)
		var vertical_distance = ledge.get_midpoint().y - origin.y
			
		var can_step = (stepping_enabled and is_on_floor() or _crouch_requested)
		if can_step:
			if (vertical_distance < (step_height if is_on_floor() else step_height_air) and horiz_distance <= (vertical_distance + (collision_default.shape.radius * 4))):
				_stepping_ledge = ledge
				print("found step")
				update_step_movement(delta)
				return true

		var ledge_in_range = vertical_distance < climb_ledge_dist and horiz_distance < collision_default.shape.radius * 2
		var ledge_high_enough = ledge.distance_from_ground > climb_ledge_min_height
		var can_climb = not is_on_floor() and _climb_requested and ledge_in_range and ledge_high_enough
		if can_climb:
			_climbing_ledge = ledge
			print("found climbing ledge")
			if show_ledge_debug:
				DebugDraw3D.draw_line(ledge.get_midpoint(), ledge.get_midpoint() + Vector3.UP, Color.BLUE, 5)
			return true

	return false

func update_step_movement(delta: float) -> void: 

	if _wish_direction.length() < 0.01:
		_stepping_ledge = null
		velocity += Vector3.DOWN * gravity
		move_and_slide()
		apply_floor_snap()
		return

	var ledge_origin_at_wall = _stepping_ledge.get_midpoint()
	var step_landing_offset_vec = -_stepping_ledge.normal.normalized() * step_offset
	
	var target_horizontal_landing_point = (ledge_origin_at_wall + step_landing_offset_vec) * Vector3(1,0,1)
	var target_vertical_landing_point_y = ledge_origin_at_wall.y + step_safe_margin
	
	var target_position = Vector3(target_horizontal_landing_point.x, target_vertical_landing_point_y, target_horizontal_landing_point.z)
	var vector_to_target = target_position - global_position
	
	if vector_to_target.length_squared() > 0.0001: # Ensure there's a valid direction to move
		# Use the character's horizontal speed when approaching the wall for the step-up motion.
		velocity = update_velocity_grounded(_wish_direction, get_max_ground_speed(), delta)
		velocity += Vector3.UP * get_max_ground_speed() * step_climb_speed_multi * delta
		move_and_slide()

	if vector_to_target.dot(-transform.basis.z) < 0:
		var origin = global_position
		origin.y = _stepping_ledge.get_midpoint().y
		_stepping_ledge = null
		print("step complete")
		if !try_find_ledge(origin, delta):
			velocity += Vector3.DOWN * gravity
			move_and_slide()
			apply_floor_snap()

func update_climb_movement(delta: float) -> void: 

	if not _climb_requested:
		_climbing_ledge = null
		print("stopped climbing ledge")
		return

	var dir_to_ledge = (_climbing_ledge.get_midpoint() * Vector3(1, 0, 1)) - (global_position * Vector3(1, 0, 1))

	var ledge_in_front = dir_to_ledge.dot(-transform.basis.z) > 0
	var ledge_above_us = global_position.y < (_climbing_ledge.get_midpoint().y + safe_margin)

	if ledge_above_us:
		velocity = Vector3.UP * climb_speed
	else:
		velocity = update_velocity_air(-_climbing_ledge.normal.normalized(), delta)

	if not ledge_in_front:
		_climbing_ledge = null
		apply_floor_snap()
		print("finished climbing ledge")
		return

	move_and_slide()
