class_name PlayerInputs	
extends Node

@export var actor : Actor
@export var character: CharacterController
@export var fps_camera: PlayerCamera
@export var weapons: PlayerWeapons
@export var mouse_look_sensitivity = 0.1
@export var joypad_sensitivity = 1.0
@export var interaction_distance = 10.0
@export_flags_3d_physics var interaction_mask: int = 1
@export var use_attempt_sound : AudioStream

static var _local: PlayerInputs

var look_direction: Vector3
var wish_direction: Vector3
var _move_input: Vector2
var _look_input: Vector2
var _lookAnimation: LookAnimation = null

func _ready():
	_local = self
	look_direction = character.transform.basis.z
	weapons.fired.connect(on_weapon_fired)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var horizontal_rotation_rads = deg_to_rad(-event.relative.x * mouse_look_sensitivity)
		look_direction = look_direction.rotated(Vector3.UP, horizontal_rotation_rads)
		var add_rotation = deg_to_rad(-event.relative.y * mouse_look_sensitivity)
		fps_camera.rotation.x = clamp(fps_camera.rotation.x + add_rotation, deg_to_rad(-89), deg_to_rad(89))	

func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
		
	# look input

	var look_x = Input.get_axis("look_left", "look_right") 
	var look_y = Input.get_axis("look_up", "look_down")

	_look_input = Vector2(look_x, look_y)
	
	if _lookAnimation and _lookAnimation.is_active():
		_look_input += _lookAnimation.get_look_vector(delta)

	var rads = deg_to_rad(-look_x * joypad_sensitivity)
	look_direction = look_direction.rotated(Vector3.UP, rads)

	var add_rotation = deg_to_rad(-look_y * joypad_sensitivity)

	fps_camera.rotation.x = clamp(fps_camera.rotation.x + add_rotation, deg_to_rad(-89), deg_to_rad(89))

	# move input

	_move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var jump_requested = false
	if Input.is_action_just_pressed("jump"):
		jump_requested = true

	var crouch_requested = Input.is_action_pressed("crouch")
	var walk_requested = Input.is_action_pressed("walk")
	var climb_requested = Input.is_action_pressed("jump") and wish_direction.length() > 0.1 and wish_direction.normalized().dot(-character.transform.basis.z) > 0

	wish_direction = (character.transform.basis * Vector3(_move_input.x, 0, _move_input.y)).normalized()

	character.set_inputs(crouch_requested, jump_requested, climb_requested, walk_requested, wish_direction)
	character.set_look_dir(look_direction)	

func _physics_process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	# use interact 

	var origin = fps_camera.global_position
	var ray_target_pos = origin + (-fps_camera.global_basis.z * interaction_distance)
	
	var query = PhysicsRayQueryParameters3D.create(origin, ray_target_pos, interaction_mask, [character])
	var space_state = character.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	var entity: Entity = null

	if not result.is_empty(): 
		entity = result.collider.get_parent() as Entity
	
	if Input.is_action_just_pressed("use"):
		try_use_entity(entity)
		
	# weapons

	var fire_was_pressed = Input.is_action_just_pressed("fire")
	var fire_was_released = Input.is_action_just_released("fire")
	var fire_is_held = Input.is_action_pressed("fire")

	weapons.set_inputs(fire_was_pressed, fire_was_released, fire_is_held, _move_input, _look_input, character.velocity)

func try_use_entity(entity: Entity) -> void:
	if entity == null:
		actor.play_sound(use_attempt_sound)
		return
	entity.use()
	LEG_Log.log("used " + entity.name)
			 
func on_weapon_fired(weapon: Weapon) -> void:
	# var recoil_anim = weapon.recoil_view_aiming_anim if is_aiming else weapon.recoil_view_anim
	_lookAnimation = weapon.recoil_view_anim
	if _lookAnimation:
		_lookAnimation.activate()
