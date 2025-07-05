class_name PlaySound
extends AI_Action

var _stream: AudioStream = null

func _init(stream: AudioStream) -> void:
	_stream = stream

func start(_user: AI_Actor) -> void:
	super.start(_user)
	if _stream:
		_user.play_sound(_stream)

func on_execute(_user: AI_Actor) -> AI_Schedule.ExecutionStatus:
	return AI_Schedule.ExecutionStatus.Complete

func _to_string() -> String:
	return "PlaySound: " + (_stream.name if _stream else "Unnamed Sound")