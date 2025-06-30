class_name AI_Action

var _status: = AI_Schedule.ExecutionStatus.NotStarted
var _elapsed_time: float = 0.0

func start(_user: AI_Actor) -> void:
	_elapsed_time = 0.0
	_status = AI_Schedule.ExecutionStatus.Running

func execute(_user: AI_Actor, delta: float) -> AI_Schedule.ExecutionStatus:
	_elapsed_time += delta
	_status = on_execute(_user)
	return _status

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
	return _status

func on_stop(_user: AI_Actor) -> void:
	pass
