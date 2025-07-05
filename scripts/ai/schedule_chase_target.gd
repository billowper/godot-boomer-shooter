class_name Schedule_ChaseTarget
extends AI_Schedule

func _init() -> void:
	add_action(Say.new("chasing!"))
	add_action(FollowTarget.new())
	with_condition(AI_Condition.new(func(_user: AI_Actor) -> bool:
		return _user.senses.current_target != null, "Has Target"))
	super._init("Chase Target")   