class_name Actor
extends Entity

@export_group("Components")
@export var character: CharacterController

func on_ready() -> void:
	add_to_group("actors")
	pass


