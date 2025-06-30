class_name Wander
extends AI_Action

var _radius: Callable
var _nav_agent: NavigationAgent3D = null

func _init(nav_agent: NavigationAgent3D, get_radius: Callable) -> void:
	_nav_agent = nav_agent
	_radius = get_radius

func start(_user: AI_Actor) -> void: 
	var rad = _radius.call() as float
	var target_position = _user.global_position + Vector3(randf_range(-rad, rad), 0, randf_range(-rad, rad))
	_nav_agent.target_position = target_position
	super.start(_user)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:

	match _status:
		AI_Schedule.ExecutionStatus.Running:

			var wish_dir = _user.global_position.direction_to(_nav_agent.get_next_path_position())

			_user.character.set_wish_dir(wish_dir)
			_user.character.set_look_dir(wish_dir)

			if _nav_agent.is_target_reached():
				return AI_Schedule.ExecutionStatus.Complete

	return _status
			
func on_stop(_user: AI_Actor) -> void:
	_user.character.set_wish_dir(Vector3.ZERO)
