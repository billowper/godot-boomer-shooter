# ledge_detection_util.gd
# A utility script with a static function to find ledges in the 3D world.
class_name LedgeDetectionUtil

# Corresponds to the LedgeDetectionResults enum in C#.
enum Results {
	FOUND_NO_WALL,
	FOUND_NO_SURFACE_OVERHANG_DISTANCE_TOO_CLOSE,
	FOUND_NO_SURFACE_OBSTRUCTED,
	TOO_CLOSE_TO_GROUND,
	FOUND_LEDGE,
	SURFACE_OBSTRUCTED_NO_CLEARANCE
}


# Tries to find a ledge from a given ray.
#
# Parameters:
# - space_state: The current PhysicsDirectSpaceState3D. Get this from get_world_3d().direct_space_state.
# - ray_origin: The starting point of the ray.
# - ray_direction: The direction the ray is pointing.
# - settings: A LedgeDetectionSettings resource with the desired parameters.
# - collision_mask: The physics layer mask for world geometry.
#
# Returns:
# A Dictionary containing the result summary and ledge data if found, otherwise null.
# The dictionary has the format:
# {
#   "summary": Results,
#   "ground_distance": float,
#   "ledge": Ledge
# }
static func try_find_ledge(space_state: PhysicsDirectSpaceState3D, exclude: Object, ray_origin: Vector3, ray_direction: Vector3, settings: LedgeDetectionSettings, collision_mask: int = 1) -> Dictionary:
	var result_info := {
		"summary": Results.FOUND_NO_WALL,
		"ground_distance": 0.0,
		"ledge": null
		}

	# 1. Find a wall by casting a ray forward.
	var wall_ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 10.0, collision_mask)
	wall_ray_query.exclude = [exclude]
	var wall_hit: Dictionary = space_state.intersect_ray(wall_ray_query)

	if not wall_hit.is_empty():

		# 2. Step up the wall and search for a valid surface.
		var found_surface := false
		var ledge_midpoint := Vector3.ZERO
		var overlap_point: Vector3 = wall_hit.position + Vector3.UP * settings.max_surface_raycast_step_interval
		
		for i in range(settings.max_surface_raycast_steps):
			# 3. Check if the point above the wall is obstructed.
			# sphere check is maybe a bit overkill, but it ensures we don't miss small obstructions.
			var sphere_shape := SphereShape3D.new()
			sphere_shape.radius = 0.1
			var shape_query := PhysicsShapeQueryParameters3D.new()
			shape_query.transform = Transform3D(Basis(), overlap_point)
			shape_query.shape = sphere_shape
			shape_query.collision_mask = collision_mask
			shape_query.exclude = [exclude]
						
			if space_state.intersect_shape(shape_query).is_empty():
				# 4. Point is clear, cast down to find the surface.
				var surface_ray_origin: Vector3 = overlap_point + Vector3.UP;
				surface_ray_origin += (-wall_hit.normal.normalized() * (settings.obstruction_check_size / 2.0))
				var surface_ray_end: Vector3 = surface_ray_origin + Vector3.DOWN * 2
				var surface_ray_query := PhysicsRayQueryParameters3D.create(surface_ray_origin, surface_ray_end, collision_mask)
				surface_ray_query.exclude = [exclude]
				var surface_hit := space_state.intersect_ray(surface_ray_query)

				if not surface_hit.is_empty():

					ledge_midpoint = wall_hit.position
					ledge_midpoint.y = surface_hit.position.y

					result_info.summary = Results.SURFACE_OBSTRUCTED_NO_CLEARANCE
					
					# 5. Found a surface, now check if there's clearance to stand up.
					var box_center : Vector3 = surface_hit.position + Vector3.UP * (settings.clearance_height * 0.5 + 0.01)
					var box_size := Vector3(settings.obstruction_check_size, settings.clearance_height, settings.obstruction_check_size)
					
					var box_shape := BoxShape3D.new()
					box_shape.size = box_size
					
					var box_transform := Transform3D()
					box_transform.origin = box_center
					# Orient the box to align with the wall and surface normals.
					box_transform.basis = Basis.looking_at(-wall_hit.normal, surface_hit.normal)
					
					var clearance_query := PhysicsShapeQueryParameters3D.new()
					clearance_query.transform = box_transform
					clearance_query.shape = box_shape
					clearance_query.collision_mask = settings.obstruction_layers
					clearance_query.exclude = [exclude]
					
					if space_state.intersect_shape(clearance_query).is_empty():
						# 6. Clearance is good. We found a valid spot.
						found_surface = true
						break
			else:
				result_info.summary = Results.FOUND_NO_SURFACE_OBSTRUCTED
			
			overlap_point += Vector3.UP * settings.max_surface_raycast_step_interval

		if found_surface:
			# 7. Found a surface, now get the distance to the ground below it.
			var ground_ray_origin : Vector3 = ledge_midpoint + (wall_hit.normal.normalized() * 0.25)
			var ground_ray_query := PhysicsRayQueryParameters3D.create(ground_ray_origin, ground_ray_origin + Vector3.DOWN * 1000.0, collision_mask)
			ground_ray_query.exclude = [exclude]
			var ground_hit := space_state.intersect_ray(ground_ray_query)
			
			var ground_distance: float = INF
			if not ground_hit.is_empty():
				ground_distance = ground_hit.position.distance_to(ground_ray_origin)

			# 8. Check if the ledge is too close to the ground.
			if ground_distance < settings.min_distance_to_ground:
				result_info.summary = Results.TOO_CLOSE_TO_GROUND
				result_info.ground_distance = ground_distance
				return result_info # Return info, but it's not a valid "grabbable" ledge

			# 9. All checks passed. Create the Ledge data object.
			var cross: Vector3 = wall_hit.normal.cross(Vector3.UP)
			var ledge_start := ledge_midpoint - cross * settings.min_ledge_width * 0.5
			var ledge_end := ledge_midpoint + cross * settings.min_ledge_width * 0.5
			
			var ledge := Ledge.new()
			ledge.start = ledge_start
			ledge.end = ledge_end
			ledge.normal = wall_hit.normal
			ledge.distance_from_ground = ground_distance

			result_info.summary = Results.FOUND_LEDGE
			result_info.ledge = ledge

	# If we reach here, no valid ledge was found for one of the reasons checked.
	return result_info
