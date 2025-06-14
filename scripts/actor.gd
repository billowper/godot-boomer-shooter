class_name Actor
extends Node3D

@export_group("Components")
@export var character_controller: CharacterController
@export var audio_player: AudioStreamPlayer3D

@export_group("Stats")
@export var max_health: int = 100

@export_group("Sounds")
@export var damage_sound : AudioStream
@export var death_sound : AudioStream

var current_health: int = 100

signal health_changed(new_health: int)
signal died
signal healed(amount: int) # Amount healed by
signal emitted_sound(actor: CharacterController, location: Vector3, volume: float)

func _ready():
	current_health = max_health
	add_to_group("actors") # Add to actors group for easy access
	on_ready()

func on_ready() -> void:
	# Override this method in subclasses to perform additional setup
	pass

# --------------------------------------- health
	
func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0

	health_changed.emit(current_health)
	
	if current_health == 0:
		die()

func die() -> void:
	if death_sound:
		play_sound(death_sound)
	
	# disable()
	died.emit()

func get_health() -> int:
	return current_health

func set_health(new_health: int) -> void:
	current_health = new_health
	clamp(current_health, 0, max_health)
	if current_health <= 0:
		die()
	else:
		health_changed.emit(current_health)

func is_alive() -> bool:
	return current_health > 0

func heal(amount: int) -> void:
	if is_alive():
		current_health += amount
		clamp(current_health, 0, max_health)
		healed.emit(amount)

# --------------------------------------- audio 

func play_sound(sound: AudioStream) -> void:
	if !audio_player.is_playing():
		audio_player.play()
	
	var playback := audio_player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback:
		playback.play_stream(sound)
		emitted_sound.emit(self, audio_player.global_position, audio_player.volume_db)
