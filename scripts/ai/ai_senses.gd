class_name AI_Senses
extends Node3D

@export var actor_self: Actor
@export var vision_range: float = 20.0
@export var vision_field_of_view_degrees: float = 90.0
@export var hearing_range: float = 25.0
@export_flags_3d_physics var collision_mask: int = 1

var current_target: Actor = null

const _SOUND_MEMORY_DURATION_SEC: float = 5.0
var _recent_sound_events: Array[Dictionary] = []

func _ready() -> void:
	# Ensure actors are ready before connecting signals
	call_deferred("_register_sound_listeners")
	
func _register_sound_listeners() -> void:
	await get_tree().physics_frame # Wait a frame to ensure nodes are ready
	var actors = get_tree().get_nodes_in_group("actors")
	for actor_node in actors:
		if actor_node == actor_self or not actor_node is Actor:
			continue
		var actor = actor_node as Actor
		if actor.is_connected("emitted_sound", Callable(self, "_on_actor_emitted_sound")):
			continue # Already connected
		actor.emitted_sound.connect(_on_actor_emitted_sound)

func _on_actor_emitted_sound(source_actor: Actor, sound_location: Vector3, sound_volume: float) -> void:
	if not is_instance_valid(source_actor) or source_actor == actor_self or not source_actor.is_alive():
		return
	
	_recent_sound_events.append({
		"source": source_actor,
		"location": sound_location,
		"volume": sound_volume,
		"time": Time.get_unix_time_from_system()
	})

func hear() -> void:
	if current_target: # Already has a visual target
		return

	var current_time = Time.get_unix_time_from_system()
	_recent_sound_events = _recent_sound_events.filter(
		func(event: Dictionary) -> bool: 
			return (current_time - event.time) < _SOUND_MEMORY_DURATION_SEC and \
					is_instance_valid(event.source) and (event.source as Actor).is_alive()
	)

	var best_sound_target: Actor = null
	var closest_sound_dist_sq: float = INF

	for event in _recent_sound_events:
		var source_actor = event.source as Actor
		var distance_sq = global_position.distance_squared_to(event.location)
		if distance_sq <= hearing_range * hearing_range:
			if distance_sq < closest_sound_dist_sq:
				closest_sound_dist_sq = distance_sq
				best_sound_target = source_actor
	
	if best_sound_target:
		current_target = best_sound_target
		print("%s heard %s" % [name, current_target.name])
		_recent_sound_events.clear() # React to one sound event cluster, then clear

func see() -> void:
	current_target = null # Reset visual target each frame
	var actors = get_tree().get_nodes_in_group("actors")
	var space_state = get_world_3d().direct_space_state

	var closest_visible_target: Actor = null
	var min_dist_sq: float = INF

	for actor_node in actors:
		if not actor_node is Actor:
			continue
		var target_actor = actor_node as Actor
		if not target_actor.is_alive() or target_actor == actor_self:
			continue

		var dir_to_target = (target_actor.global_position - global_position)
		if dir_to_target.length_squared() > vision_range * vision_range:
			continue

		var dot_product = -global_transform.basis.z.dot(dir_to_target.normalized())
		print("Dot product with %s: %f" % [target_actor.get_parent().name, dot_product])
		if dot_product < deg_to_rad(vision_field_of_view_degrees):
			continue

		var ray_target_pos = target_actor.global_position + Vector3.UP # Approx center of target
		var query = PhysicsRayQueryParameters3D.create(global_position, ray_target_pos, collision_mask, [self, target_actor])
		var result = space_state.intersect_ray(query)

		if result.is_empty(): # empty means no obstacles in the way
			var dist_sq = global_position.distance_squared_to(target_actor.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_visible_target = target_actor
	
	if closest_visible_target:
		current_target = closest_visible_target
		print("%s sees %s" % [name, current_target.name])
