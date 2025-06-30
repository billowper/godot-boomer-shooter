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

var _active_schedule: AI_Schedule = null

func on_ready() -> void:
	var default_schedule = setup_schedules()
	_set_active_schedule(default_schedule)
	
func setup_schedules() -> AI_Schedule:
	_schedule_idle = Schedule_Idle.new(wait_time)
	_schedule_wander = Schedule_Wander.new(nav_agent, _get_wander_radius)

	_schedule_idle.set_next(_schedule_wander)
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

		if status != AI_Schedule.ExecutionStatus.Running:
			var next_schedule = _active_schedule.get_next()
			if next_schedule:
				_set_active_schedule(next_schedule)
			else:
				_set_active_schedule(_schedule_idle)

	if _active_schedule == null:
		_set_active_schedule(_schedule_idle)

func _animate(_delta: float) -> void:
	animations.set("parameters/movement/blend_position", character.velocity.normalized().dot(-character.basis.z))

func _get_wander_radius() -> float:
	return wander_radius

func _set_active_schedule(schedule: AI_Schedule) -> void:
	_active_schedule = schedule
	if _active_schedule != null:
		print_debug(name + " new schedule: " + _active_schedule._name)
		_active_schedule.start(self)

class Schedule_Idle:
	extends AI_Schedule
	func _init(wait_time: float) -> void:
		add_action(Say.new("I am idle"))
		add_action(Wait.new(wait_time))
		super._init("Idle")
		
class Schedule_Wander:
	extends AI_Schedule
	func _init(nav_agent: NavigationAgent3D, get_radius: Callable) -> void:
		add_action(Say.new("wandering!"))
		add_action(Wander.new(nav_agent, get_radius))
		super._init("Wander")
