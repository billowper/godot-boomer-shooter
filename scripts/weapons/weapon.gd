class_name Weapon
extends Resource

@export_group("Visuals")
@export var view_model: Resource = null

@export_group("Behaviour")
@export var projectile: ProjectileType
@export var max_ammo: int = 120
@export var is_automatic: bool
@export var rate_of_fire: float = 0.5
@export var projectile_count: int = 1
@export var damage: int = 10

@export_group("Spread")
@export var base_spread: float = 0.0
@export var max_spread: float = 0.2
@export var spread_increase_per_shot: float
@export var spread_recovery_speed: float = 0.5

@export_group("SFX")
@export var equip_sound : AudioStream
@export var fire_sound : AudioStream
@export var reload_sound: AudioStream
@export var empty_sound: AudioStream

@export_group("View Model")
@export var anim_equip: DurationalAnimation = DurationalAnimation.new()
@export var anim_holster: DurationalAnimation = DurationalAnimation.new()
@export var idle_position_offset: Vector3
@export var idle_rotation_offset: Vector3
@export var view_model_animation: ViewModelAnimation
@export var view_model_animation_aiming: ViewModelAnimation
@export var recoil_anim: DurationalAnimation
@export var recoil_anim_aiming: DurationalAnimation
@export var look_animation: LookAnimation
@export var look_animation_aiming: LookAnimation