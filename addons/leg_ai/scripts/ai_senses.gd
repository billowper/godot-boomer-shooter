class_name AI_Senses
extends Node3D

@export var vision_range: float = 20.0
@export var vision_field_of_view_degrees: float = 90.0
@export var hearing_range: float = 25.0
@export var detection_time: float = 3.0
@export_flags_3d_physics var collision_mask: int = 1

var actor_self: Actor
var current_target: Actor = null

const _SOUND_MEMORY_DURATION_SEC: float = 5.0

var _recent_sound_events: Array[Dictionary] = []
var _target_data: Dictionary = {}

signal heard_sound(position: Vector3)

func _ready() -> void:
	# Ensure actors are ready before connecting signals
	call_deferred("_register_sound_listeners")
	actor_self = self.get_parent() as Actor
	if not actor_self:
		push_error("AI_Senses must be a child of an Actor node.")
		return
	
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

func hear(_delta: float) -> void:
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
		print("%s heard %s" % [name, best_sound_target.name])
		heard_sound.emit(best_sound_target.global_position)
		_recent_sound_events.clear() # React to one sound event cluster, then clear

func see(delta: float) -> void:
	var actors = get_tree().get_nodes_in_group("actors")

	for actor_node in actors:
		if actor_node is Actor:
			var target_actor = actor_node as Actor
			var data: SenseData = _target_data.get_or_add(target_actor.name, SenseData.new())
			
			update_target_data(data, target_actor, delta)

	var closest_visible_target: Actor = null
	var min_dist_sq: float = INF

	for actor_node in actors:
		if actor_node is Actor:
			var target_actor = actor_node as Actor
			var data: SenseData = _target_data.get_or_add(target_actor.name, SenseData.new())
			
			if data.visible_time >= detection_time and data.dist_sq < min_dist_sq:
				min_dist_sq = data.dist_sq
				closest_visible_target = target_actor

	if closest_visible_target:
		current_target = closest_visible_target
	else:
		current_target = null 

func update_target_data(data: Variant, target_actor: Actor, delta: float) -> void:
	
	var space_state = get_world_3d().direct_space_state
	var prev_visible_time = data.visible_time

	data.visible = false
	data.visible_time = 0.0
	data.dist_sq = INF

	if not target_actor.is_alive() or target_actor == actor_self:
		_target_data.erase(target_actor.name)
		return

	var dir_to_target = (target_actor.global_position - global_position)
	if dir_to_target.length_squared() > vision_range * vision_range:
		print("%s is too far from %s to see" % [actor_self.name, target_actor.name])
		return

	var facing_alignment = -global_transform.basis.z.dot(dir_to_target.normalized())
	var is_facing_target = facing_alignment > 0

	if not is_facing_target:
		print("%s is not facing %s" % [actor_self.name, target_actor.name])
		return

	var angle_to_target = acos(facing_alignment)
	var field_of_view_radians = deg_to_rad(vision_field_of_view_degrees / 2.0)
	var in_field_of_view = angle_to_target <= field_of_view_radians

	if not in_field_of_view:
		print("%s is not in field of view of %s" % [target_actor.name, actor_self.name])
		return

	var ray_target_pos = target_actor.global_position + Vector3.UP
	var query = PhysicsRayQueryParameters3D.create(global_position, ray_target_pos, collision_mask, [actor_self.character, target_actor.character])
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		var dist_sq = global_position.distance_squared_to(target_actor.global_position)
		data.visible = true
		data.visible_time = prev_visible_time + delta
		data.dist_sq = dist_sq
		print("%s can see %s - %s" % [actor_self.name, target_actor.name, data.visible_time])
	else:
		print("%s cannot see %s due to obstruction" % [actor_self.name, target_actor.name])

class SenseData:
	var visible: bool = false
	var visible_time: float = 0.0
	var dist_sq: float = INF
