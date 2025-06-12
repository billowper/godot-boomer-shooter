class_name CharacterController
extends CharacterBody3D

@export var gravity = 18.0
@export var walk_speed = 3.0
@export var run_speed = 6.0
@export var crouch_speed = 2.0
@export var stop_speed = 2.0
@export var acceleration = 1.5
@export var max_air_speed = 1.5
@export var jump_velocity = 4.5
@export var wall_jump_force = 4.5
@export var friction = 4.5
@export var coyote_time = .15
@export var step_height := 0.4 
@export var step_height_air := 0.4 
@export var step_offset := 0.1
@export var step_safe_margin := 0.1
@export var collision_default: CollisionShape3D
@export var collision_crouched: CollisionShape3D
@export var ledge_detection_settings: LedgeDetectionSettings

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
	
	move_and_slide()

	update_stepping(velocity_before_main_ms, delta)

	if not was_grounded and is_on_floor():
		landed.emit()

	var ledge_query = LedgeDetectionUtil.try_find_ledge(get_world_3d().direct_space_state, global_position + Vector3.UP * step_safe_margin, -transform.basis.z, ledge_detection_settings, collision_mask)
	
	if (ledge_query["summary"] == LedgeDetectionUtil.Results.FOUND_LEDGE):
		print("Ledge Found: ", ledge_query["ledge"])
		DebugDraw3D.draw_line(ledge_query["ledge"].start, ledge_query["ledge"].end, Color.GREEN)


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

func update_stepping(velocity_before_move: Vector3, _delta: float) -> void:

	var horizontal_vel = Vector3(velocity_before_move.x, 0, velocity_before_move.z)

	# if we're trying to move horizontally, can step and hit something, then lets try to step up it
	if horizontal_vel.length_squared() > 0.01 and can_step() and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)

			# make sure the collision is a wall
			if collision and collision.get_collider() != null and abs(collision.get_normal().y) < 0.3:
				
				var up_motion = Vector3.UP * (step_height if is_on_floor() else step_height_air)
			
				# try and move upwards
				if not test_move(transform, up_motion, null, step_safe_margin):

					var original_pos = global_position
					var original_vel = velocity

					global_position += up_motion

					var step_velocity = horizontal_vel.normalized() * step_offset

					# now try to move forwards onto the step
					if not test_move(transform, step_velocity, null, step_safe_margin): 
						
						global_position += step_velocity

						apply_floor_snap()
						move_and_slide()

						if is_on_floor():
							return

						global_position = original_pos
						velocity = original_vel
						print("Failed to step up, reverting position")
						return

					else:
						
						# revert the up motion we failed to step and return
						global_position -= up_motion
						apply_floor_snap()
						return

				return
