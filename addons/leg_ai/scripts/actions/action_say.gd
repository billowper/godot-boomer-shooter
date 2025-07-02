class_name Say
extends AI_Action

var _message: String = ""

func _init(message: String) -> void:
	_message = message

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
	print(_user.name + ": " + _message)
	return AI_Schedule.ExecutionStatus.Complete
