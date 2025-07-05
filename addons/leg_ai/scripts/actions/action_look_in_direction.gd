class_name LookInDirection
extends AI_Action

var _get_position: Callable
var _time: float = 1.0

func _init(get_position: Callable, time: float = 1.0) -> void:
	_get_position = get_position
	_time = time

func start(_user: AI_Actor) -> void: 
	var look_dir = _user.global_position.direction_to(_get_position.call() as Vector3)
	_user.character.set_look_dir(look_dir)
	super.start(_user)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:

	var look_dir = _user.global_position.direction_to(_get_position.call() as Vector3)
	_user.character.set_look_dir(look_dir)

	if _elapsed_time > _time:
		return AI_Schedule.ExecutionStatus.Complete

	return _status
		
func _to_string() -> String:
	return "LookInDirection"