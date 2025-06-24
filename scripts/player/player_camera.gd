class_name PlayerCamera
extends Camera3D

@export var player_character : CharacterController
@export var strafe_lean_range : float
@export var strafe_lean_speed : float
@export var default_camera_height := 1.65
@export var crouch_camera_height := .75
@export var camera_height_adjust_speed := 2.0

var lean_amount := float(0)

func _process(delta):
	update_camera_height(delta)
	update_strafe_lean(delta)

func update_camera_height(_delta: float) -> void:

	var crouch_progress = player_character.get_crouch_progress()
	if crouch_progress > 0:
		position.y = lerp(default_camera_height, crouch_camera_height, crouch_progress)
	else: 
		position.y = move_toward(position.y, default_camera_height, camera_height_adjust_speed * _delta)

func update_strafe_lean(delta: float) -> void:
	var player_vel = player_character.velocity.normalized()
	var speed_x = player_vel.dot(player_character.transform.basis.x)
	var target_lean_amount = lerp(-strafe_lean_range, strafe_lean_range, remap(speed_x, -1, 1, 0, 1))

	if is_zero_approx(speed_x):
		target_lean_amount = 0

	lean_amount = move_toward(lean_amount, target_lean_amount, strafe_lean_speed * delta)

	var rot = rotation_degrees
	rot.z = -lean_amount
	rotation_degrees = rot
