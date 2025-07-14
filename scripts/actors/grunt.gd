class_name Grunt
extends AI_Actor

@export var wait_time: Vector2 = Vector2(1.0, 3.0)
@export var wander_radius = 10.0

var _idle: AI_Schedule = null
var _wander: Schedule_Wander = null
var _investigate: Schedule_Investigate = null
var _react_to_hit: Schedule_ReactToHit = null
var _chase: Schedule_ChaseTarget = null
	
func setup_schedules(schedules: Array[AI_Schedule]) -> AI_Schedule:

	_chase = Schedule_ChaseTarget.new() \
	.with_break_condition(condition_took_hit)
	schedules.append(_chase)

	_investigate = Schedule_Investigate.new().make_one_shot() \
	.with_break_condition(condition_has_target, _chase) \
	.with_break_condition(condition_took_hit, _react_to_hit)
	schedules.append(_investigate)

	_react_to_hit = Schedule_ReactToHit.new(damage_sound).make_one_shot()
	schedules.append(_react_to_hit)
	
	_wander = Schedule_Wander.new(func() -> float:
		return randf() * wander_radius
	) \
	.with_break_condition(condition_has_target, _chase) \
	.with_break_condition(condition_took_hit, _react_to_hit) \
	.with_break_condition(condition_heard_sound, _investigate) \
	.with_cooldown(func() -> float:
		return randf_range(1.0, 3.0)
	) \
	.set_next(_idle)

	schedules.append(_wander)

	_idle = AI_Schedule.new("Idle") \
	.add_action(Say.new("I am idle")) \
	.add_action(Wait.new(func() -> float: 
		return randf_range(wait_time.x, wait_time.y)
	)) \
	.with_break_condition(condition_has_target, _chase) \
	.with_break_condition(condition_took_hit, _react_to_hit) \
	.with_break_condition(condition_heard_sound, _investigate)

	schedules.append(_idle)

	return _idle
	
func _on_heard_sound(sound_location: Vector3) -> void:
	super._on_heard_sound(sound_location)
	_investigate.target_pos = sound_location
	_investigate.set_valid(true)

func _on_hit(source: Entity, origin: Vector3, direction: Vector3, damage: int) -> void:
	super._on_hit(source, origin, direction, damage)
	_react_to_hit.target_pos = origin
	_react_to_hit.set_valid(true)
