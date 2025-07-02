class_name Weapon
extends Resource

@export_group("Behaviour")
@export var is_automatic: bool
@export var rate_of_fire: float = 0.5
@export var projectile_count: int = 1
@export var damage: int = 10

@export_group("Spread")
@export var base_spread: float = 0.0
@export var max_spread: float = 0.2
@export var spread_increase_per_shot: float
@export var spread_recovery_speed: float = 0.5

@export_group("Physics")
@export var force: float = 100.0
