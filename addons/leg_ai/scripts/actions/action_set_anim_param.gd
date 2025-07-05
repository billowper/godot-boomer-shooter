class_name AnimOneShot
extends AI_Action

var _param: String
var _value: AnimationNodeOneShot.OneShotRequest

func _init(param: String, request: AnimationNodeOneShot.OneShotRequest) -> void:
	_param = param
	_value = request

func start(_user: AI_Actor) -> void:
	super.start(_user)
	_user.animations.set("parameters/" + _param, _value)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
	return AI_Schedule.ExecutionStatus.Complete

func _to_string() -> String:
	return "AnimOneShot: " + _param + " = " + str(_value)