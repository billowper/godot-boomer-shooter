class_name Wait
extends AI_Action

var get_time: Callable
var _time: float = 0.0

func _init(get_time: Callable) -> void:
    self.get_time = get_time

func start(_user: AI_Actor) -> void:
    super.start(_user)
    _time = get_time.call() as float

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
    if _elapsed_time >= _time:
        return AI_Schedule.ExecutionStatus.Complete

    return AI_Schedule.ExecutionStatus.Running

func _to_string() -> String:
    return "Wait " + str(_time)