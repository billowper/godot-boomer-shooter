class_name AI_Schedule

enum ExecutionStatus {
	NotStarted,
	Running,
	Complete,
	Failed,
	Break,
}

var _name: String = ""
var _actions: Array = []
var _next_schedule: AI_Schedule = null
var _action_index: = 0
var _cooldown: Callable
var _time_since_active: TimeSince = TimeSince.new()
var _break_conditions: Array[Variant] = []
var _conditions: Array[AI_Condition] = []
var _last_break_condition: Variant
var _on_stop: Callable
var _is_valid: bool = true
var _is_one_shot: bool = false
var _no_repeat: bool = false

var status: ExecutionStatus = ExecutionStatus.NotStarted

func _init(name: String) -> void:
	_name = name

func set_valid(valid: bool) -> AI_Schedule:
	_is_valid = valid
	return self

func make_one_shot() -> AI_Schedule:
	_is_one_shot = true
	_is_valid = false
	return self

func set_next(next: AI_Schedule) -> AI_Schedule:
	_next_schedule = next
	return self

func get_next(status: ExecutionStatus) -> AI_Schedule:

	match status:
		ExecutionStatus.Complete:
			return _next_schedule
		ExecutionStatus.Failed:
			return null
		ExecutionStatus.Break:
			if _last_break_condition and _last_break_condition.next_schedule:
				return _last_break_condition.next_schedule
			else:
				return null

	return null

func set_on_stop(on_stop: Callable) -> AI_Schedule:
	_on_stop = on_stop
	return self

func with_cooldown(cooldown: Callable) -> AI_Schedule:
	_cooldown = cooldown
	return self

func with_break_condition(condition: AI_Condition, set_next_schedule: AI_Schedule = null) -> AI_Schedule:
	_break_conditions.append({
		"condition": condition,
		"next_schedule": set_next_schedule
	})
	return self

func with_condition(condition: AI_Condition) -> AI_Schedule:
	_conditions.append(condition)
	return self

func evaluate(_user: AI_Actor) -> bool:

	if _no_repeat and _user._last_schedule == self:
		print(_name + " is set to no repeat, skipping evaluation")
		return false

	if not _is_valid:
		print(_name + " is not valid, skipping evaluation")
		return false

	if _cooldown and _time_since_active.get_elapsed_time() < _cooldown.call() as float:
		print(_name + " is on cooldown, elapsed: " + str(_time_since_active.get_elapsed_time()) + ", cooldown: " + str(_cooldown))
		return false

	for condition in _conditions:
		if not condition.check(_user):
			print(_name + " failed condition: " + condition.name)
			return false

	for entry in _break_conditions:
		var condition = entry.condition as AI_Condition
		if condition.check(_user):
			print(_name + " failed break condition: " + condition.name)
			return false

	return true

func add_action(action: AI_Action) -> AI_Schedule:
	_actions.append(action)
	return self

func start(_user: AI_Actor)	-> void:
	_action_index = 0
	status = ExecutionStatus.Running
	_time_since_active._init()
	_last_break_condition = null
	var action = _actions[_action_index] as AI_Action
	action.start(_user)
	print(_name + " started | action: " + action.to_string())

func stop(_user: AI_Actor) -> void:

	if _is_one_shot:
		_is_valid = false

	if _on_stop:
		_on_stop.call(_user)

	status = ExecutionStatus.NotStarted

	pass

func execute(_user: AI_Actor, delta: float) -> AI_Schedule.ExecutionStatus:

	var action: AI_Action = _actions[_action_index]

	for entry in _break_conditions:
		var condition = entry.condition as AI_Condition
		if condition.check(_user):
			action.on_stop(_user)
			print(_name + " hit break condition: " + condition.name)
			_last_break_condition = entry
			status = ExecutionStatus.Break
			return status
	
	if status == ExecutionStatus.Running:

		var action_status = action._status
		if action_status == ExecutionStatus.Running:
			action_status = action.execute(_user, delta)

		if action_status == ExecutionStatus.Complete:
			print(_name + " action " + str(_action_index + 1) + "/" + str(_actions.size()) + " completed: " + action.to_string())
			action.on_stop(_user)
			_action_index += 1
			if _action_index >= _actions.size():
				return ExecutionStatus.Complete
			
			action = _actions[_action_index]
			action.start(_user)
			action.on_execute(_user)
			print(_name + " action " + str(_action_index + 1) + "/" + str(_actions.size()) + " started: " + action.to_string())

	return status
