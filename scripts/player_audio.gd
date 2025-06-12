extends AudioStreamPlayer3D
class_name PlayerAudio

@export var player_character : CharacterController
@export var jump_sound : AudioStream
@export var landed_sound : AudioStream

@export_group("Footstep Settings")
@export var footstep_sound: AudioStream
@export var footstep_interval_walk: float = 8
@export var footstep_interval_run: float = 12
@export var footstep_interval_crouch: float = 5

var _step_cycle: float = 0.0

func _ready():
	player_character.jumped.connect(self.on_jump)
	player_character.landed.connect(self.on_landed)

func on_jump():
	if jump_sound:
		_play_sound(jump_sound)

func on_landed():
	if landed_sound:
		_play_sound(landed_sound)
		_step_cycle = 0
	
func _physics_process(delta: float) -> void:
	var player_vel = player_character.velocity * Vector3(1, 0, 1)
	if player_vel.length() > 0.0:
		_step_cycle += (player_vel.length() * player_character.get_max_ground_speed()) * delta
	else:
		_step_cycle = 0

	if _step_cycle > get_footstep_interval():
		_step_cycle = 0
		_play_sound(footstep_sound)

func get_footstep_interval() -> float:
	if player_character._is_crouching:
		return footstep_interval_crouch
	elif player_character._walk_requested:
		return footstep_interval_walk
	else:
		return footstep_interval_run

func _play_sound(sound: AudioStream) -> void:
	if !self.is_playing():
		self.play()
	
	var playback := self.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback:
		playback.play_stream(sound)
		
