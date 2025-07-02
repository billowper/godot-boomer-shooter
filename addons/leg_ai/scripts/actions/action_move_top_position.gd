class_name MoveToPosition
extends AI_Action

var _get_position: Callable

func _init(get_position: Callable) -> void:
	_get_position = get_position

func start(_user: AI_Actor) -> void: 
	_user.nav_agent.target_position = _get_position.call() as Vector3
	_user.nav_agent.target_desired_distance = 2.0
	super.start(_user)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:

	match _status:
		AI_Schedule.ExecutionStatus.Running:

			var wish_dir = _user.global_position.direction_to(_user.nav_agent.get_next_path_position())

			_user.character.set_wish_dir(wish_dir)
			_user.character.set_look_dir(wish_dir)

			if _user.nav_agent.is_target_reached():
				return AI_Schedule.ExecutionStatus.Complete

	return _status
			
func on_stop(_user: AI_Actor) -> void:
	_user.character.set_wish_dir(Vector3.ZERO)
