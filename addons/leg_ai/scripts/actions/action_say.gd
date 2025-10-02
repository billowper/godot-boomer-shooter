class_name Say
extends AI_Action

var _message: String = ""

func _init(message: String) -> void:
	_message = message

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
	LEG_Log.log(_user.name + ": " + _message)
	return AI_Schedule.ExecutionStatus.Complete

func _to_string() -> String:
	return "Say: " + _message if _message else "Say: No Message"