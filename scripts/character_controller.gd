class_name CharacterController
extends CharacterBody3D

@export_group("General Settings")
@export var collision_default: CollisionShape3D
@export var gravity = 18.0
@export var friction = 4.5
@export var walk_speed = 3.0
@export var run_speed = 6.0
@export var acceleration = 1.5
@export var stop_speed = 2.0

@export_group("Crouch Behavior")
@export var collision_crouched: CollisionShape3D
@export var crouch_speed = 2.0
@export var crouch_time = .8

@export_group("Jumping & Air Control")
@export var max_air_speed = 1.5
@export var jump_velocity = 4.5
@export var wall_jump_force = 4.5
@export var coyote_time = .15

@export_group("Stepping")
@export var step_on_ground := false
@export var step_in_air := false
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
@export var climbing_end_distance := 1.0
## Minimum height of a ledge to be considered for climbing. 
@export var climb_ledge_min_height := 4.0

@export_group("Ledge Detection")
@export var ledge_detection_settings: LedgeDetectionSettings
@export var show_ledge_debug := false

signal jumped
signal landed

var jump_requested := false
var wish_direction := Vector3.ZERO
var crouch_requested := false
var walk_requested := false
var climb_requested := false
var is_crouching := false
var time_since_grounded := 0.0
var stepping_ledge: Ledge = null
var climbing_ledge: Ledge = null
var crouch_timer = 0.0
var crouch_was_requested = false

enum JumpTypes
{
	None,
	Normal,
	DoubleJump,
	WallJump
}

func set_inputs(is_crouching_requested: bool, is_jump_requested: bool, is_climb_requested: bool, is_walk_requested: bool, wish_dir: Vector3) -> void:
	self.crouch_requested = is_crouching_requested
	self.jump_requested = is_jump_requested
	self.wish_direction = wish_dir
	self.walk_requested = is_walk_requested
	self.climb_requested = is_climb_requested

func _ready():
	collision_crouched.disabled = true;

func _physics_process(delta: float) -> void:

	update_crouch_state(delta)

	if jump_requested:
		var jump_type = can_jump()
		jump(jump_type, delta)

	jump_requested = false

	if stepping_ledge:
		update_step_movement(delta)
		return

	if climbing_ledge:
		update_climb_movement(delta)
		return

	if try_find_ledge(global_position, delta):
		return

	var was_grounded := is_on_floor()

	if was_grounded:
		velocity = update_velocity_grounded(wish_direction, delta)
		time_since_grounded = 0
	else:
		velocity = update_velocity_air(wish_direction, delta)
		time_since_grounded += delta

	move_and_slide()

	if not was_grounded and is_on_floor():
		print("Landed")
		landed.emit()

func update_crouch_state(delta: float) -> void:

	# if we were crouching, but no longer requested, end crouch (if we can stand up)
	if !crouch_requested and is_crouching && can_stand():
		is_crouching = false
		collision_default.disabled = false
		collision_crouched.disabled = true
		return

	# crouch requested, increment timer until we crouch
	if crouch_requested and crouch_was_requested and not is_crouching:
		crouch_timer += delta
		if crouch_timer >= crouch_time:
			is_crouching = true
			collision_default.disabled = true
			collision_crouched.disabled = false

	# crouch requested, start timer if not already crouching
	if crouch_requested and not crouch_was_requested and not is_crouching:

		if is_on_floor():
			crouch_was_requested = true
			crouch_timer = 0.0
		else:
			is_crouching = true
			collision_default.disabled = true
			collision_crouched.disabled = false

	crouch_was_requested = crouch_requested

func get_crouch_progress() -> float:
	if not crouch_requested and not is_crouching:
		return 0.0
	if is_crouching:
		return 1.0
	return clamp(crouch_timer / crouch_time, 0.0, 1.0)

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

	velocity = update_velocity_air(-wish_direction, delta)
	jumped.emit()

func get_max_ground_speed() -> float:
	var max_speed = crouch_speed if is_crouching else run_speed

	if !is_crouching and walk_requested:
		max_speed = walk_speed

	return max_speed

func update_velocity_grounded(wish_dir: Vector3, delta: float) -> Vector3:
	var max_speed = get_max_ground_speed()
	var speed = velocity.length()
	if (speed != 0):
		var control = max(stop_speed, speed)
		var drop = control * friction * delta
		velocity *= max(speed - drop, 0) / speed

	return accelerate(wish_dir, max_speed, delta)

func update_velocity_air(wish_dir: Vector3, delta: float) -> Vector3:
	velocity += Vector3.DOWN * gravity * delta
	return accelerate(wish_dir, max_air_speed, delta)

func accelerate(wish_dir: Vector3, max_speed: float, delta: float) -> Vector3:
	var current_speed = velocity.dot(wish_dir)
	var add_speed = clamp(max_speed - current_speed, 0, (acceleration * max_speed) * delta)
	return velocity + add_speed * wish_dir

func can_jump() -> JumpTypes:
	if is_on_floor():
		return JumpTypes.Normal
	if (time_since_grounded < coyote_time):
		return JumpTypes.Normal
	if (get_slide_collision_count() > 0 and get_slide_collision(0) and get_slide_collision(0).get_collider() != null):
		if (get_slide_collision(0).get_normal().y < 0.3 && wish_direction.dot(get_slide_collision(0).get_normal()) < 0):
			return JumpTypes.WallJump

	return JumpTypes.None

func can_stand() -> bool:
	if !is_crouching:
		return true

	var space_state = get_world_3d().direct_space_state
	var parameters = PhysicsShapeQueryParameters3D.new()
	parameters.shape = collision_default.shape
	parameters.transform = collision_default.global_transform
	parameters.collision_mask = self.collision_mask 
	parameters.exclude = [self]
	return space_state.intersect_shape(parameters).is_empty()
	
func try_find_ledge(origin: Vector3, delta: float) -> bool:
	# if we're moving horizontally, check for ledges
	var flat_wish_direction = wish_direction * Vector3(1, 0, 1)
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
			
		var can_step = ((step_on_ground and is_on_floor()) or (not is_on_floor() and step_in_air and is_crouching))
		if can_step:
			if (vertical_distance < (step_height if is_on_floor() else step_height_air) and horiz_distance <= (vertical_distance + (collision_default.shape.radius * 4))):
				stepping_ledge = ledge
				print("found step")
				update_step_movement(delta)
				return true

		var ledge_in_range = vertical_distance < climb_ledge_dist and horiz_distance < collision_default.shape.radius * 2
		var ledge_high_enough = ledge.distance_from_ground > climb_ledge_min_height
		var can_climb = not is_on_floor() and climb_requested and ledge_in_range and ledge_high_enough
		if can_climb:
			climbing_ledge = ledge
			print("found climbing ledge")
			if show_ledge_debug:
				DebugDraw3D.draw_line(ledge.get_midpoint(), ledge.get_midpoint() + Vector3.UP, Color.BLUE, 5)
			return true

	return false

func update_step_movement(delta: float) -> void: 

	if wish_direction.length() < 0.01:
		stepping_ledge = null
		velocity += Vector3.DOWN * gravity
		move_and_slide()
		apply_floor_snap()
		return

	velocity = update_velocity_grounded(wish_direction, delta)
	velocity += Vector3.UP * get_max_ground_speed() * step_climb_speed_multi * delta
	move_and_slide()

	var dir_to_ledge = (stepping_ledge.get_midpoint() * Vector3(1, 0, 1)) - (global_position * Vector3(1, 0, 1))
	var ledge_behind_us = dir_to_ledge.dot(-transform.basis.z) < 0

	if ledge_behind_us:
		var origin = global_position
		origin.y = stepping_ledge.get_midpoint().y
		stepping_ledge = null
		print("step complete")
		if !try_find_ledge(origin, delta):
			velocity += Vector3.DOWN * gravity
			move_and_slide()
			apply_floor_snap()

func update_climb_movement(delta: float) -> void: 

	if not climb_requested:
		climbing_ledge = null
		print("stopped climbing ledge")
		return

	var dir_to_ledge = (climbing_ledge.get_midpoint() * Vector3(1, 0, 1)) - (global_position * Vector3(1, 0, 1))

	var ledge_in_front = dir_to_ledge.dot(-transform.basis.z) > 0
	var vertical_distance = climbing_ledge.get_midpoint().y - global_position.y

	if vertical_distance > climbing_end_distance:
		velocity = Vector3.UP * climb_speed
	else:
		velocity = update_velocity_air(-climbing_ledge.normal.normalized(), delta)

	# make sure we're up and over the ledge

	if not ledge_in_front && dir_to_ledge.length() > .1:
		climbing_ledge = null
		velocity += Vector3.DOWN * gravity
		move_and_slide()
		apply_floor_snap()
		print("finished climbing ledge")
		return

	move_and_slide()
