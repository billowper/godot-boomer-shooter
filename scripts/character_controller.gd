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
var _is_crouching := false
var _time_since_grounded := 0.0

signal jumped
signal landed
signal crouchStateChanged(state: bool)

func set_inputs(crouch_requested: bool, jump_requested: bool, walk_requested: bool, wish_direction: Vector3) -> void:
	_crouch_requested = crouch_requested
	_jump_requested = jump_requested
	_wish_direction = wish_direction
	_walk_requested = walk_requested

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

	# movement
	var was_grounded := is_on_floor()

	if is_on_floor():
		velocity = update_velocity_grounded(_wish_direction, get_max_ground_speed(), delta)
		_time_since_grounded = 0
	else:
		velocity = update_velocity_air(_wish_direction, delta)
		_time_since_grounded += delta

	var velocity_before_main_ms = velocity
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z).normalized()
	
	move_and_slide()

	if (horizontal_vel.length_squared() > 0.01):
		var ledge_query = LedgeDetectionUtil.try_find_ledge(get_world_3d().direct_space_state, global_position + Vector3.UP * step_safe_margin, horizontal_vel, ledge_detection_settings, collision_mask)
		
		if (ledge_query["summary"] == LedgeDetectionUtil.Results.FOUND_LEDGE) and show_ledge_debug:
			DebugDraw3D.draw_line(ledge_query["ledge"].start, ledge_query["ledge"].end, Color.GREEN)

		if stepping_enabled:
			update_stepping_ledge(velocity_before_main_ms, ledge_query["ledge"], delta)

	if not was_grounded and is_on_floor():
		print("Landed")
		landed.emit()

func jump(jump_type: JumpTypes, delta: float) -> void:

	if jump_type == JumpTypes.None:
		return

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
	
	velocity += Vector3.DOWN * gravity * delta

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
	if (get_slide_collision(0) and get_slide_collision(0).get_collider() != null):
		if (get_slide_collision(0).get_normal().y < 0.3):
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

func can_step() -> bool:
	return is_on_floor() or _crouch_requested

func update_stepping_ledge(velocity_before_move: Vector3, ledge: Ledge, _delta: float) -> void:
	var horizontal_vel = Vector3(velocity_before_move.x, 0, velocity_before_move.z)

	if ledge == null:
		return

	if !can_step():
		return

	var touching_wall = get_slide_collision_count() > 0 and get_slide_collision(0).get_collider() != null and get_slide_collision(0).get_normal().y < 0.3
	var moving_towards_wall = horizontal_vel.length_squared() > 0.01

	if touching_wall and moving_towards_wall:
		var pos_flat = global_position * Vector3(1, 0, 1)
		var ledge_midpoint_flat = ledge.get_midpoint() * Vector3(1, 0, 1)
		var horiz_distance = pos_flat.distance_to(ledge_midpoint_flat)
		var vertical_distance = ledge.get_midpoint().y - global_position.y
		print("Horizontal Distance: ", horiz_distance, " Vertical Distance: ", vertical_distance)
		if (vertical_distance < (step_height if is_on_floor() else step_height_air) and horiz_distance < step_ledge_dist):
			global_position.y = ledge.get_midpoint().y + step_safe_margin
			global_position += -ledge.normal * step_offset
			move_and_slide()
			apply_floor_snap()