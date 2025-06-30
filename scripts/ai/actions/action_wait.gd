class_name Wait
extends AI_Action

var _time: float = 1.0

func _init(time: float) -> void:
    _time = time

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
    if _elapsed_time >= _time:
        return AI_Schedule.ExecutionStatus.Complete

    return AI_Schedule.ExecutionStatus.Running
