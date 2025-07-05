class_name AI_SignalCondition
extends AI_Condition

var _cachedValue: bool = false

func _init(condition_name: String = "Signal Condition") -> void:
	super._init(func(_user: Actor) -> bool: return _cachedValue, condition_name)

func set_true() -> void:
	_cachedValue = true

func check(_user: AI_Actor) -> bool:
	if _cachedValue:
		_cachedValue = false
		return true
	return false