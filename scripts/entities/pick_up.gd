class_name PickUp
extends RigidBody3D

@export var weapon: Weapon = null
@export var ammo: int = 0
@export var health: int = 0
@export var pick_up_effect: Resource = null
@export var spin_speed: float = 0.0

signal picked_up

func _ready():
	add_to_group("pickups")

func _process(delta):
	
	if spin_speed != 0.0:
		rotate_y(spin_speed * delta)

