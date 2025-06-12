extends Camera3D
class_name FirstPersonCamera

@export var strafe_lean_range : float
@export var strafe_lean_speed : float
@export var player_character : PlayerCharacter

var lean_amount := float(0)

func _process(delta):
	var player_vel = player_character.velocity.normalized()
	var speed_x = player_vel.dot(player_character.transform.basis.x)
	var target_lean_amount = lerp(-strafe_lean_range, strafe_lean_range, remap(speed_x, -1, 1, 0, 1))

	if is_zero_approx(speed_x):
		target_lean_amount = 0

	lean_amount = move_toward(lean_amount, target_lean_amount, strafe_lean_speed * delta)

	var rot = rotation_degrees
	rot.z = -lean_amount
	rotation_degrees = rot
