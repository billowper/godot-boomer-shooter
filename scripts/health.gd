class_name Health
extends Node

@export var max_health: int = 100

var current_health: int = 100

signal health_changed(new_health: int)
signal died
signal healed(amount: int)

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health -= amount
    if current_health < 0:
        current_health = 0

    health_changed.emit(current_health)
    
    if current_health == 0:
        died.emit()

func get_health() -> int:
    return current_health

func set_health(new_health: int) -> void:
    current_health = new_health
    clamp(current_health, 0, max_health)

func is_alive() -> bool:
    return current_health > 0

func heal(amount: int) -> void:
    if is_alive():
        current_health += amount
        clamp(current_health, 0, max_health)
        healed.emit(amount)