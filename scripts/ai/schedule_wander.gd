class_name Schedule_Wander
extends AI_Schedule

var target_pos: Vector3
func _init(get_radius: Callable) -> void:
	add_action(Say.new("wandering!"))
	add_action(Wander.new(get_radius))
	super._init("Wander")   