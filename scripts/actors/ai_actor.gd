class_name AI_Actor
extends Actor

@export_group("Components")
@export var senses: AI_Senses
@export var nav_agent: NavigationAgent3D
@export var wait_time = 10.0
@export var wander_radius = 10.0

@export_group("Animations")
@export var animations: AnimationTree

var _schedule_idle: Schedule_Idle = null
var _schedule_wander: Schedule_Wander = null
var _schedule_chase: Schedule_ChaseTarget = null

var _active_schedule: AI_Schedule = null

func on_ready() -> void:
	var default_schedule = setup_schedules()
	_set_active_schedule(default_schedule)
	
func setup_schedules() -> AI_Schedule:
	_schedule_idle = Schedule_Idle.new(wait_time)
	_schedule_wander = Schedule_Wander.new(_get_wander_radius)
	_schedule_chase = Schedule_ChaseTarget.new()

	_schedule_wander.set_next(_schedule_idle)
	return _schedule_idle
	
func _physics_process(_delta: float):
	senses.hear()
	senses.see()

func _process(delta: float):
	_think(delta)
	_animate(delta)

func _think(delta: float) -> void:
	if _active_schedule:
		var status = _active_schedule.execute(self, delta)

		if status == AI_Schedule.ExecutionStatus.Complete:
			var next_schedule = _active_schedule.get_next()
			if next_schedule:
				_set_active_schedule(next_schedule)
			else:
				_set_active_schedule(null)

		if status == AI_Schedule.ExecutionStatus.Break or status == AI_Schedule.ExecutionStatus.Failed or status == AI_Schedule.ExecutionStatus.Interrupted:
			_set_active_schedule(null)

	if _active_schedule == null:
		if senses.current_target != null:
			_set_active_schedule(_schedule_chase)
		else:
			_set_active_schedule(_schedule_wander)

func _animate(_delta: float) -> void:
	animations.set("parameters/movement/blend_position", character.velocity.normalized().dot(-character.basis.z))

func _get_wander_radius() -> float:
	return wander_radius

func _set_active_schedule(schedule: AI_Schedule) -> void:
	_active_schedule = schedule
	if _active_schedule != null:
		print(name + " new schedule: " + _active_schedule._name)
		_active_schedule.start(self)

class Schedule_Idle:
	extends AI_Schedule
	func _init(wait_time: float) -> void:
		add_action(Say.new("I am idle"))
		add_action(Wait.new(wait_time))
		with_break_condition("has target", func(_user: AI_Actor) -> bool:
			return _user.senses.current_target != null
		)
		super._init("Idle")
		
class Schedule_Wander:
	extends AI_Schedule
	func _init(get_radius: Callable) -> void:
		add_action(Say.new("wandering!"))
		add_action(Wander.new(get_radius))
		with_break_condition("has target", func(_user: AI_Actor) -> bool:
			return _user.senses.current_target != null
		)
		super._init("Wander")
		
class Schedule_ChaseTarget:
	extends AI_Schedule
	func _init() -> void:
		add_action(Say.new("chasing!"))
		add_action(FollowTarget.new())
		super._init("Chase Target")
