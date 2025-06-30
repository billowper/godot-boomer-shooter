class_name TimeSince 

var time: float

func _init(initial_time: float = -1.0):
	# If initial_time is -1.0, it means it's a new TimeSince instance
	# set to the current WorldClock.
	# Otherwise, it's being initialized with a specific time.
	if initial_time == -1.0:
		time = get_world_clock()
	else:
		time = get_world_clock() - initial_time

static func get_world_clock() -> float:
	return Time.get_ticks_msec() / 1000.0

func get_elapsed_time() -> float:
	return get_world_clock() - time