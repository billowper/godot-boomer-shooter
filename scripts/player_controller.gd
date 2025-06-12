extends CharacterBody3D
class_name PlayerController

@export var gravity = 18.0
@export var walk_speed = 3.0
@export var run_speed = 6.0
@export var crouch_speed = 2.0
@export var stop_speed = 2.0
@export var acceleration = 1.5
@export var max_air_speed = 1.5
@export var jump_velocity = 4.5
@export var friction = 4.5
@export var coyote_time = .15
@export var mouse_look_sensitivity := 0.1
@export var joypad_sensitivity := 1.0
@export var crouch_camera_offset := .5
@export var step_height := 0.4 
@export var step_height_air := 0.4 
@export var step_offset := 0.1
@export var step_safe_margin := 0.1
@export var fps_camera:  FirstPersonCamera
@export var collision_default: CollisionShape3D
@export var collision_crouched: CollisionShape3D

var _jump_requested := false
var _move_direction := Vector2.ZERO
var _crouch_requested := false
var _is_crouching := false
var _time_since_grounded := 0.0

signal jumped
signal landed

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	collision_crouched.disabled = true;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_look_sensitivity))
		fps_camera.rotate_x(deg_to_rad(-event.relative.y * mouse_look_sensitivity))

func _process(_delta: float) -> void:

	# Camera Look
	var look_x = Input.get_axis("look_left", "look_right") 
	var look_y = Input.get_axis("look_up", "look_down") 

	rotate_y(deg_to_rad(-look_x * joypad_sensitivity))
	fps_camera.rotate_x(deg_to_rad(-look_y * joypad_sensitivity))

	fps_camera.rotation.x = clamp(fps_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("fire"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if Input.is_action_just_pressed("jump"):
		_jump_requested = true

	_crouch_requested = Input.is_action_pressed("crouch")

func _physics_process(delta: float) -> void:

	var wish_direction := (transform.basis * Vector3(_move_direction.x, 0, _move_direction.y)).normalized()

	# handle crouch
	if _crouch_requested:
		set_crouch(true)
	elif can_stand():
		set_crouch(false)

	# jump
	if _jump_requested and can_jump():
		velocity.y = sqrt(2 * gravity * jump_velocity)
		velocity = update_velocity_air(wish_direction, delta)
		jumped.emit()

	_jump_requested = false

	# movement

	var was_grounded = is_on_floor()

	if is_on_floor():
		velocity = update_velocity_grounded(wish_direction, get_max_ground_speed(), delta)
		_time_since_grounded = 0
	else:
		velocity = update_velocity_air(wish_direction, delta)
		_time_since_grounded += delta

	var velocity_before_main_ms = velocity
	
	move_and_slide()

	handle_steps(velocity_before_main_ms, delta)

	if !was_grounded and is_on_floor():
		landed.emit()

func get_max_ground_speed() -> float:
	var max_speed = crouch_speed if _is_crouching else run_speed

	if !_is_crouching and Input.is_action_pressed("walk"):
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

func can_jump() -> bool:
	if is_on_floor():
		return true

	if (_time_since_grounded < coyote_time):
		return true

	return false

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
		if _is_crouching:
			fps_camera.position -= Vector3(0, crouch_camera_offset, 0)
		else:
			fps_camera.position += Vector3(0, crouch_camera_offset, 0)

		collision_default.disabled = _is_crouching
		collision_crouched.disabled = !_is_crouching

func can_step() -> bool:
	return is_on_floor() or _crouch_requested

func handle_steps(velocity_before_move: Vector3, _delta: float) -> void:

	var horizontal_vel = Vector3(velocity_before_move.x, 0, velocity_before_move.z)

	# if we're trying to move horizontally, can step and hit something, then lets try to step up it

	if horizontal_vel.length_squared() > 0.01 and can_step() and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)

			# make sure the collision is a wall
			if collision and collision.get_collider() != null and abs(collision.get_normal().y) < 0.3:
				
				var up_motion = Vector3.UP * (step_height if is_on_floor() else step_height_air)

				print("trying to step")
			
				# try and move upwards
				if not test_move(transform, up_motion, null, step_safe_margin):

					print("can move up")

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
							print("stepped")
							return

						global_position = original_pos
						velocity = original_vel
						print("step failed didnt snap/find floor")
						return

					else:
						
						# revert the up motion we failed to step and return
						print("step offset failed")
						global_position -= up_motion
						return

				return
