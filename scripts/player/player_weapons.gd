class_name PlayerWeapons
extends Node3D

@export var player_audio: PlayerAudio
@export var player_camera: PlayerCamera
@export var player_character: CharacterController
@export var actor: Actor
@export var weapon_slot: Node3D
@export var shoot_point: Node3D
@export var view_model_anim_control: ViewModelAnimationController = null

var active_weapon: Weapon = null
var weapons: Array[Weapon] = []
var _model: Node3D
var is_aiming: bool = false

signal fired(weapon: Weapon)

func set_inputs(fire_was_pressed: bool,
	fire_was_released: bool, 
	fire_is_held: bool,
	move: Vector2,
	look: Vector2,
	velocity: Vector3) -> void:
	if not active_weapon:
		return

	view_model_anim_control.set_inputs(move, look, player_character.velocity)
		
	if fire_was_pressed:
		fire_weapon()
	elif fire_was_released:
		stop_firing()

func add_weapon(weapon: Weapon) -> bool:
	if not weapon:
		push_error("Attempted to add a null weapon.")
		return false

	if weapon in weapons:
		push_warning("Weapon already exists in the inventory: %s" % weapon.get_name())
		return false

	weapons.append(weapon)

	if not active_weapon:
		set_active_weapon(0)
	
	return true
	
func add_ammo(amount: int) -> bool:
	return true

func set_active_weapon(index: int) -> void:
	
	if index < 0 or index >= weapons.size():
		push_error("Weapon index out of bounds: %d" % index)
		return

	var weapon: Weapon = weapons[index]
	if not weapon:
		push_error("No weapon found at index: %d" % index)
		return

	active_weapon = weapon

	if _model:
		_model.queue_free()

	_model = weapon.view_model.instantiate() as Node3D
	weapon_slot.add_child(_model)

	view_model_anim_control.set_weapon(active_weapon)
	player_audio.play_2d(active_weapon.equip_sound)

func fire_weapon() -> void:

	if not active_weapon:
		return

	player_audio.play_2d(active_weapon.fire_sound)

	active_weapon.projectile.create(
		get_fire_origin(),
		get_fire_direction(),
		actor
	)

	fired.emit(active_weapon)

	view_model_anim_control.on_weapon_fired(active_weapon)

func stop_firing() -> void:
	pass

func get_fire_origin() -> Vector3:
	return shoot_point.global_transform.origin

func get_fire_direction() -> Vector3:
	return -shoot_point.global_transform.basis.z.normalized()
