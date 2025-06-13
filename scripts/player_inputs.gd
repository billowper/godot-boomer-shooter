class_name PlayerInputs	
extends Node

@export var player_controller: CharacterController
@export var fps_camera: FirstPersonCamera
@export var mouse_look_sensitivity = 0.1
@export var joypad_sensitivity = 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player_controller.rotate_y(deg_to_rad(-event.relative.x * mouse_look_sensitivity))
		var add_rotation = deg_to_rad(-event.relative.y * mouse_look_sensitivity)
		fps_camera.rotation.x = clamp(fps_camera.rotation.x + add_rotation, deg_to_rad(-89), deg_to_rad(89))	

func _process(_delta: float) -> void:

	var look_x = Input.get_axis("look_left", "look_right") 
	var look_y = Input.get_axis("look_up", "look_down") 

	player_controller.rotate_y(deg_to_rad(-look_x * joypad_sensitivity))
	var add_rotation = deg_to_rad(-look_y * joypad_sensitivity)
	fps_camera.rotation.x = clamp(fps_camera.rotation.x + add_rotation, deg_to_rad(-89), deg_to_rad(89))

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("fire"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var jump_requested = false
	if Input.is_action_just_pressed("jump"):
		jump_requested = true

	var crouch_requested = Input.is_action_pressed("crouch")
	var walk_requested = Input.is_action_pressed("walk")
	var wish_direction := (player_controller.transform.basis * Vector3(move_direction.x, 0, move_direction.y)).normalized()
	var climb_requested = Input.is_action_pressed("jump") and wish_direction.length() > 0.1 and wish_direction.normalized().dot(-player_controller.transform.basis.z) > 0

	player_controller.set_inputs(crouch_requested, jump_requested, climb_requested, walk_requested, wish_direction)
