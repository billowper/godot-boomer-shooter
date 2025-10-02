class_name AI_Actor
extends Actor

@export_group("Components")
@export var senses: AI_Senses
@export var nav_agent: NavigationAgent3D

@export_group("Parameters")
@export var tick_rate: float = 0.5

@export_group("Animations")
@export var animations: AnimationTree

var _active_schedule: AI_Schedule = null
var _last_schedule: AI_Schedule = null
var _schedules: Array[AI_Schedule] = []

var condition_took_hit = AI_SignalCondition.new("took hit")
var condition_heard_sound = AI_SignalCondition.new("heard sound")
var condition_has_target = AI_Condition.new(func(_user: Actor) -> bool:
	return senses.current_target != null
, "has target")

func on_ready() -> void:
	var default_schedule = setup_schedules(_schedules)
	_set_active_schedule(default_schedule)
	died.connect(_on_died)
	on_hit.connect(_on_hit)
	senses.heard_sound.connect(_on_heard_sound)
	animations.set("parameters/state/transition_request", "moving")

func _on_died() -> void:
	_set_active_schedule(null)	
	character.set_process(false)
	character.set_physics_process(false)
	character.set_wish_dir(Vector3.ZERO)  
	character.velocity = Vector3.ZERO  
	character.disable_collision()
	play_sound(death_sound) 
	nav_agent.set_target_position(Vector3.ZERO)  # Reset navigation target
	animations.set("parameters/state/transition_request", "dead")

func setup_schedules(schedules: Array[AI_Schedule]) -> AI_Schedule:
	return null
	
func _physics_process(_delta: float):

	if not is_alive():
		return

	senses.hear(_delta)
	senses.see(_delta)

func _process(delta: float):

	if not is_alive():
		return

	_think(delta)
	_animate(delta)

var last_tick: float = 0.0

func _think(delta: float) -> void:

	if _active_schedule:
		var status = _active_schedule.execute(self, delta)

		if status != AI_Schedule.ExecutionStatus.Running:
			_last_schedule = _active_schedule
			var next_schedule = _active_schedule.get_next(status)
			LEG_Log.log(name + " schedule finished: " + _active_schedule._name + " with status: " + str(status) + " next: " + (next_schedule._name if next_schedule else "null"))
			_active_schedule.stop(self)
			if next_schedule:
				_set_active_schedule(next_schedule)
			else:
				_set_active_schedule(null)

	if not _active_schedule:

		last_tick += delta

		if last_tick < tick_rate:
			return 

		last_tick = 0.0

		for schedule in _schedules:
			if schedule.evaluate(self):
				_set_active_schedule(schedule)
				break
			
func _animate(_delta: float) -> void:
	animations.set("parameters/movement/blend_position", character.velocity.normalized().dot(-character.basis.z))

func _set_active_schedule(schedule: AI_Schedule) -> void:
	_active_schedule = schedule
	if _active_schedule != null:
		LEG_Log.log(name + " new schedule: " + _active_schedule._name)
		_active_schedule.start(self)

func _on_heard_sound(sound_location: Vector3) -> void:
	condition_heard_sound.set_true()
	pass

func _on_hit(source: Entity, origin: Vector3, direction: Vector3, damage: int) -> void:
	condition_took_hit.set_true()
	pass
