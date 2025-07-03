class_name PlayerPickUps
extends Area3D

@export var player_weapons: PlayerWeapons	
@export var actor: Actor

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is PickUp:
		var pickup: PickUp = body as PickUp	
		if try_collect_pickup(pickup):
			pickup.picked_up.emit()
			pickup.queue_free()

func try_collect_pickup(pickup: PickUp) -> bool:
	if pickup.weapon:
		return player_weapons.add_weapon(pickup.weapon)

	if pickup.ammo > 0:
		return player_weapons.add_ammo(pickup.ammo)

	if pickup.health > 0:
		return actor.heal(pickup.health)

	return false
