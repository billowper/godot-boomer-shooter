class_name ViewModelAnimationController
extends Node3D # Inherit from Node3D as this controls 3D transforms

# --- Exported Properties (equivalent to [SerializeField] in Unity) ---
@export var root_transform: NodePath # Path to the root transform of the view model
@export var recoil_transform: NodePath # Path to the transform that handles recoil
@export var idle_offset_transform: NodePath # Path to the transform for idle offsets
@export var attack_idle_timeout: float = 0.5 # Time before idle animation activates after attack
@export var debug: bool = false

# --- Public Properties ---
# Check if the holster animation is active
func is_holster_animation_active() -> bool:
	return m_holster_animation != null and m_holster_animation.is_active()

# Check if the equip animation is active (less than 90% complete)
func is_equip_anim_active() -> bool:
	return m_equip_anim != null and m_equip_anim.get_progress_percentage() < 0.9

func set_inputs(move_input: Vector2, look_input: Vector2, velocity: Vector3,) -> void:
	_move_input = move_input
	_look_input = look_input
	_velocity = velocity


# --- Private Member Variables ---
var m_root_transform_node: Node3D
var m_recoil_transform_node: Node3D
var m_idle_offset_transform_node: Node3D

var m_active_recoil: DurationalAnimation = null # Currently active recoil animation
var m_vm_animation: ViewModelAnimation = null # Base view model animation settings
var m_vm_animation_aiming: ViewModelAnimation = null # View model animation settings when aiming
var m_equip_anim: DurationalAnimation = null # Equip animation
var m_holster_animation: DurationalAnimation = null # Holster animation
var m_idle_timer: float = 0.0 # Timer for idle animation activation
var m_is_holstered: bool = false # Flag indicating if the weapon is holstered

var _weapon: Weapon = null # Parameters for the currently equipped item
var _move_input: Vector2
var _look_input: Vector2
var _is_aiming: bool
var _velocity: Vector3

var bob_multiplier: float = 1.0

# --- Godot Lifecycle Methods ---

func _ready() -> void:
	m_root_transform_node = get_node(root_transform)
	m_recoil_transform_node = get_node(recoil_transform)
	m_idle_offset_transform_node = get_node(idle_offset_transform)

func _process(delta: float) -> void:

	if debug:
		_velocity = Vector3.ONE * 5
		_move_input = Vector2(0, 1) # Simulate movement input

	if m_vm_animation == null:
		return

	if m_is_holstered:
		return

	# Handle holster animation
	if m_holster_animation and m_holster_animation.is_active():
		var anim_result = m_holster_animation.update_lerped(delta)
		m_recoil_transform_node.position = anim_result["position"]
		m_recoil_transform_node.quaternion = anim_result["rotation"]

		if not m_holster_animation.is_active():
			m_is_holstered = true
		return # Exit early if holstering

	# --- Idle Offset Calculation ---
	# Determine if the view model should be in an idle state
	var is_idle = not _is_aiming and \
				  (m_active_recoil == null or not m_active_recoil.is_active()) and \
				  (m_equip_anim == null or not m_equip_anim.is_active())

	if is_idle:
		m_idle_timer += delta
	else:
		m_idle_timer = 0.0

	var target_pos_offset = Vector3.ZERO
	var target_rot_offset = Vector3.ZERO

	if is_idle and m_idle_timer > attack_idle_timeout:
		if _weapon:
			target_pos_offset = _weapon.idle_position_offset
			target_rot_offset = _weapon.idle_rotation_offset

	# Apply idle offset or reset if aiming
	if _is_aiming:
		m_idle_offset_transform_node.position = Vector3.ZERO
		m_idle_offset_transform_node.rotation = Vector3.ZERO
	else:
		m_idle_offset_transform_node.position = m_idle_offset_transform_node.position.slerp(target_pos_offset, delta * 3.0)
		# Quaternion.Euler is converted to Basis.from_euler and then get_rotation_quaternion()
		m_idle_offset_transform_node.quaternion = m_idle_offset_transform_node.quaternion.slerp(
			Basis.from_euler(target_rot_offset).get_rotation_quaternion(), delta * 3.0
		)

	# --- Equip and Recoil Animations ---
	if m_equip_anim and m_equip_anim.is_active():
		var anim_result = m_equip_anim.update_lerped(delta)
		m_recoil_transform_node.position = anim_result["position"]
		m_recoil_transform_node.quaternion = anim_result["rotation"]
	else:
		if m_active_recoil and m_active_recoil.is_active():
			var anim_result = m_active_recoil.update_continuous(delta)
			m_recoil_transform_node.position = anim_result["position"]
			m_recoil_transform_node.quaternion = anim_result["rotation"]
		else:
			# Lerp recoil back to zero if no active recoil
			m_recoil_transform_node.position = m_recoil_transform_node.position.slerp(Vector3.ZERO, delta * 3.0)
			m_recoil_transform_node.quaternion = m_recoil_transform_node.quaternion.slerp(Quaternion.IDENTITY, delta * 3.0)

	var current_vm_animation = m_vm_animation
	if _is_aiming:
		current_vm_animation = m_vm_animation_aiming

	if not current_vm_animation: # Ensure vmAnimation is not null
		return

	# --- Bob Position ---
	var speed = _velocity.length() # .magnitude in Unity is .length() in Godot

	# var final_bob_multiplier = bob_multiplier * Game.get("Options", {}).get("Gameplay", {}).get("WeaponBobMultiplier", 1.0) # Placeholder
	var final_bob_multiplier = bob_multiplier
	var sway_position = current_vm_animation.bob.update_sway(delta, speed, speed, final_bob_multiplier)

	m_root_transform_node.position = current_vm_animation.position + sway_position

	# --- Lean/Bank and Sway Rotation ---
	var local_euler_angles = current_vm_animation.rotation

	var lean_multiplier = 1.0

	local_euler_angles.z += current_vm_animation.lean.get_value(_move_input.x, lean_multiplier, delta)
	local_euler_angles.y += current_vm_animation.horizontal_sway.get_value(_move_input.x, lean_multiplier, delta)
	local_euler_angles.x += current_vm_animation.vertical_sway.get_value(_move_input.y, lean_multiplier, delta)

	# Apply rotation to the root transform
	# Convert Euler angles to Quaternion for setting local_rotation
	m_root_transform_node.quaternion = Basis.from_euler(local_euler_angles).get_rotation_quaternion()

# --- Event Handlers ---
# Handles the weapon fired event, activating recoil animation.
func on_weapon_fired(weapon: Weapon) -> void:
	var recoil_anim = weapon.recoil_anim_aiming if _is_aiming else weapon.recoil_anim

	m_idle_offset_transform_node.position = Vector3.ZERO
	m_idle_offset_transform_node.rotation = Vector3.ZERO

	m_active_recoil = recoil_anim
	if m_active_recoil:
		m_active_recoil.activate(m_recoil_transform_node.position)

# --- Public Methods ---
# Sets the parameters for the currently equipped item.
func set_weapon(weapon: Weapon) -> void:
	m_is_holstered = false

	if _weapon != weapon:
		_weapon = weapon

		if weapon != null:
			m_vm_animation = weapon.view_model_animation
			m_vm_animation_aiming = weapon.view_model_animation_aiming
			m_holster_animation = weapon.anim_holster
			if m_holster_animation:
				m_holster_animation.reset()

			m_equip_anim = weapon.anim_equip
			if m_equip_anim:
				m_equip_anim.activate(m_recoil_transform_node.position)
		else:
			# Clear all references if no weapon
			m_vm_animation = null
			m_vm_animation_aiming = null
			m_equip_anim = null
			m_holster_animation = null

		m_idle_offset_transform_node.position = Vector3.ZERO
		m_idle_offset_transform_node.rotation = Vector3.ZERO

# Plays the holster animation.
func play_holster_animation() -> void:
	if m_holster_animation != null:
		m_holster_animation.activate(m_recoil_transform_node.position)
