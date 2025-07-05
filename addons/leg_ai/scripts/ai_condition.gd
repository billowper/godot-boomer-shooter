class_name AI_Condition

var name: String
var _callable: Callable

func _init(callable: Callable, condition_name: String) -> void:
	name = condition_name
	_callable = callable

func check(_user: AI_Actor) -> bool:
	if _callable:
		return _callable.call(_user)
	return false
