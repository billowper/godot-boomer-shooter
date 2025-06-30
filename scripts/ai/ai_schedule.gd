class_name AI_Schedule

enum ExecutionStatus {
	NotStarted,
	Running,
	Complete,
	Failed,
	Break,
	Interrupted
}

var _name: String = ""
var _actions: Array = []
var _next_schedule: AI_Schedule = null
var _action_index: = 0
var _cooldown: = 0.0
var _time_since_active: TimeSince = TimeSince.new()

var status: ExecutionStatus = ExecutionStatus.NotStarted

func _init(name: String) -> void:
	_name = name

func set_next(next: AI_Schedule) -> AI_Schedule:
	_next_schedule = next
	return self

func with_cooldown(cooldown: float) -> AI_Schedule:
	_cooldown = cooldown
	return self

func has_cooldown_passed() -> bool:
	return _time_since_active.get_elapsed_time() >= _cooldown

func get_next() -> AI_Schedule:
	return _next_schedule

func add_action(action: AI_Action) -> AI_Schedule:
	_actions.append(action)
	return self

func start(_user: AI_Actor)	-> void:
	_action_index = 0
	status = ExecutionStatus.Running
	_time_since_active._init()
	var action = _actions[_action_index] as AI_Action
	action.start(_user)

func execute(_user: AI_Actor, delta: float) -> AI_Schedule.ExecutionStatus:
	var action: AI_Action = _actions[_action_index]

	if status == ExecutionStatus.Running:
		status = action.execute(_user, delta)

	if status == ExecutionStatus.Complete:
		action.on_stop(_user)
		_action_index += 1
		if _action_index >= _actions.size():
			return ExecutionStatus.Complete
		
		action = _actions[_action_index]
		action.start(_user)
		status = ExecutionStatus.Running

	return status
