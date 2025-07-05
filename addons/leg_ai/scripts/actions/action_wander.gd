class_name Wander
extends AI_Action

var _radius: Callable

func _init(get_radius: Callable) -> void:
	_radius = get_radius

func start(_user: AI_Actor) -> void: 
	var rad = _radius.call() as float
	var target_position = _user.global_position + Vector3(randf_range(-rad, rad), 0, randf_range(-rad, rad))
	_user.nav_agent.target_position = target_position
	_user.nav_agent.target_desired_distance = 1.5
	super.start(_user)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:

	match _status:
		AI_Schedule.ExecutionStatus.Running:

			var wish_dir = _user.global_position.direction_to(_user.nav_agent.get_next_path_position())

			_user.character.set_wish_dir(wish_dir)
			_user.character.set_look_dir(wish_dir)

			var remaining_distance = _user.nav_agent.get_final_position().distance_to(_user.global_position)
			if remaining_distance < _user.nav_agent.target_desired_distance:
				return AI_Schedule.ExecutionStatus.Complete

	return _status
			
func on_stop(_user: AI_Actor) -> void:
	_user.character.set_wish_dir(Vector3.ZERO)

func _to_string() -> String:
	return "Wander"