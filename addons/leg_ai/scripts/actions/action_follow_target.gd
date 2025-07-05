class_name FollowTarget
extends AI_Action

func start(_user: AI_Actor) -> void: 

	if _user.senses.current_target == null:
		self._status = AI_Schedule.ExecutionStatus.Failed
		return

	print("follow " + _user.senses.current_target.name)

	_user.nav_agent.target_position = _user.senses.current_target.global_position
	_user.nav_agent.target_desired_distance = 2.0
	super.start(_user)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:

	if _user.senses.current_target == null:
		return AI_Schedule.ExecutionStatus.Failed

	match _status:
		AI_Schedule.ExecutionStatus.Running:

			_user.nav_agent.target_position = _user.senses.current_target.global_position

			var wish_dir = _user.global_position.direction_to(_user.nav_agent.get_next_path_position())

			_user.character.set_wish_dir(wish_dir)
			_user.character.set_look_dir(wish_dir)

			if _user.nav_agent.is_target_reached():
				return AI_Schedule.ExecutionStatus.Complete

	return _status
			
func on_stop(_user: AI_Actor) -> void:
	_user.character.set_wish_dir(Vector3.ZERO)

func _to_string() -> String:
	return "FollowTarget"