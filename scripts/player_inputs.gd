extends Node
class_name PlayerInputs	

@export var player_controller: CharacterController
@export var fps_camera: FirstPersonCamera
@export var mouse_look_sensitivity = 0.1
@export var joypad_sensitivity = 1.0
@export var crouch_camera_offset := .5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_controller.crouchStateChanged.connect(self.set_crouch)

func set_crouch(state: bool) -> void:
	if state:
		fps_camera.position -= Vector3(0, crouch_camera_offset, 0)
	else:
		fps_camera.position += Vector3(0, crouch_camera_offset, 0)
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player_controller.rotate_y(deg_to_rad(-event.relative.x * mouse_look_sensitivity))
		fps_camera.rotate_x(deg_to_rad(-event.relative.y * mouse_look_sensitivity))

func _process(_delta: float) -> void:

	var look_x = Input.get_axis("look_left", "look_right") 
	var look_y = Input.get_axis("look_up", "look_down") 

	player_controller.rotate_y(deg_to_rad(-look_x * joypad_sensitivity))
	fps_camera.rotate_x(deg_to_rad(-look_y * joypad_sensitivity))
	fps_camera.rotation.x = clamp(fps_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

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

	player_controller.set_inputs(crouch_requested, jump_requested, walk_requested, wish_direction)
