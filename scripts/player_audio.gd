class_name PlayerAudio
extends AudioStreamPlayer3D

@export var actor : Actor
@export var jump_sound : AudioStream
@export var landed_sound : AudioStream

@export_group("Footstep Settings")
@export var footstep_sound: AudioStream
@export var footstep_interval_walk: float = 8
@export var footstep_interval_run: float = 12
@export var footstep_interval_crouch: float = 5

var _step_cycle: float = 0.0

func _ready():
	actor.character.jumped.connect(self.on_jump)
	actor.character.landed.connect(self.on_landed)

func on_jump():
	if jump_sound:
		actor.play_sound(jump_sound)

func on_landed():
	if landed_sound:
		actor.play_sound(landed_sound)
		_step_cycle = 0
	
func _physics_process(delta: float) -> void:
	var player_vel = actor.character.velocity * Vector3(1, 0, 1)
	if player_vel.length() > 0.0:
		_step_cycle += (player_vel.length() * actor.character.get_max_ground_speed()) * delta
	else:
		_step_cycle = 0

	if _step_cycle > get_footstep_interval():
		_step_cycle = 0
		actor.play_sound(footstep_sound)

func get_footstep_interval() -> float:
	if actor.character.is_crouching:
		return footstep_interval_crouch
	elif actor.character.walk_requested:
		return footstep_interval_walk
	else:
		return footstep_interval_run
