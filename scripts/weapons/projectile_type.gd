class_name ProjectileType
extends Resource

@export var damage: int = 10
@export var hit_effect: Resource = null
@export var hit_sound: Resource = null
@export var spread: float = 0.0
@export var projectile_count: int = 1

func create(
    origin: Vector3,
    direction: Vector3,
    owner: Actor
) -> void:
    # This method should be overridden by subclasses
    pass