class_name PlayerCamera
extends Camera3D

@export var player_character : CharacterController
@export var strafe_lean_range : float
@export var strafe_lean_speed : float
@export var default_camera_height := 1.65
@export var crouch_camera_height := .75
@export var camera_height_adjust_speed := 2.0
@export var camera_bob: SwayController = SwayController.new()
@export var camera_bob_walk_multiplier: Vector2 = Vector2(.6, .6)
@export var camera_bob_crouch_multiplier: Vector2 = Vector2(.5, .5)

var lean_amount := float(0)
var desired_camera_height: float = default_camera_height

func _process(delta):
	_update_bob(delta)
	_update_camera_height(delta)
	_update_strafe_lean(delta)

func _update_bob(delta: float) -> void:
	var player_vel = player_character.velocity.normalized()
	var speed_x = player_vel.dot(player_character.transform.basis.x)
	var speed_z = player_vel.dot(-player_character.transform.basis.z)

	var multi = Vector2(1, 1)

	if player_character.walk_requested:
		multi = camera_bob_walk_multiplier
	elif player_character.is_crouching:
		multi = camera_bob_crouch_multiplier

	var sway_position = camera_bob.update_sway(delta, abs(speed_x), abs(speed_z), multi.x, multi.y)

	position = Vector3(0, desired_camera_height, 0) # Reset position to avoid cumulative sway
	position += sway_position

func _update_camera_height(delta: float) -> void:
	var crouch_progress = player_character.get_crouch_progress()
	if crouch_progress > 0:
		desired_camera_height = lerp(default_camera_height, crouch_camera_height, crouch_progress)
	else: 
		desired_camera_height = move_toward(desired_camera_height, default_camera_height, camera_height_adjust_speed * delta)

func _update_strafe_lean(delta: float) -> void:
	var player_vel = player_character.velocity.normalized()
	var speed_x = player_vel.dot(player_character.transform.basis.x)
	var target_lean_amount = lerp(-strafe_lean_range, strafe_lean_range, remap(speed_x, -1, 1, 0, 1))

	if is_zero_approx(speed_x):
		target_lean_amount = 0

	lean_amount = move_toward(lean_amount, target_lean_amount, strafe_lean_speed * delta)

	var rot = rotation_degrees
	rot.z = -lean_amount
	rotation_degrees = rot
