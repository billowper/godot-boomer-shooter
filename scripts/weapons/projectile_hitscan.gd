class_name ProjectileHitScan
extends ProjectileType

@export var max_range: float = 100.0
@export_flags_3d_physics var collision_mask: int = 1

func create(
	origin: Vector3,
	direction: Vector3,
	owner: Actor
) -> void:
	var end_position = origin + direction.normalized() * max_range
	var space_state = owner.get_world_3d().direct_space_state

	var params = PhysicsRayQueryParameters3D.new()
  
	params.from = origin
	params.to = end_position
	params.exclude = [owner]
	params.collision_mask = collision_mask

	var result: Dictionary = space_state.intersect_ray(params)

	if result:
		var hit_position = result.position
		var hit_normal = result.normal
		var collider = result.collider
		
		print("hit object: ", collider)

#        if collider:
#            collider.apply_damage(damage, owner)
#
#        if hit_effect:
#            hit_effect.create(hit_position, hit_normal, owner)

		if hit_sound:
			hit_sound.play(hit_position)
	else:
		# Handle the case where no collision was detected
		pass
