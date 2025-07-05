class_name Schedule_Investigate
extends AI_Schedule

var target_pos: Vector3

func _init() -> void:

    var pos_getter = func() -> Vector3: 
        return target_pos		

    add_action(Say.new("huh?"))
    add_action(LookInDirection.new(pos_getter))
    add_action(MoveToPosition.new(pos_getter))
    super._init("Investigate")