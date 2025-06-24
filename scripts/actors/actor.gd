class_name Actor
extends Node3D

enum ActorFlags{
	NO_FLAGS = 0,
	NO_COLLISION = 1 << 0, ## Disable collision for this actor
	NO_PHYSICS = 1 << 1, ## Disable physics for this actor
	NO_AI = 1 << 2, ## Disable AI for this actor
	NO_ANIMATIONS = 1 << 3, ## Disable animations for this actor
	NO_AUDIO = 1 << 4, ## Disable audio for this actor
	NO_INPUT = 1 << 5, ## Disable input for this actor
	NO_RENDER = 1 << 6, ## Disable rendering for this actor
	NO_AI_SENSES = 1 << 7, ## Disable AI senses for this actor
	NO_AI_TASKS = 1 << 8, ## Disable AI tasks for this actor

	IS_PLAYER = 1 << 9, ## This actor is a player character
	IS_ENEMY = 1 << 10, ## This actor is an enemy character
	IS_NPC = 1 << 11, ## This actor is a non-player character
	IS_FRIENDLY = 1 << 12, ## This actor is a friendly character
	IS_NEUTRAL = 1 << 13, ## This actor is a neutral character

	CAN_MOVE = 1 << 14, ## This actor can move
	CAN_ATTACK = 1 << 15, ## This actor can attack
	CAN_HEAL = 1 << 16, ## This actor can heal
	CAN_DIE = 1 << 17 ## This actor can die
}

@export_group("Components")
@export var character: CharacterController
@export var audio: AudioStreamPlayer3D

@export_group("Stats")
@export var default_flags : Array[ActorFlags]
@export var max_health: int = 100

@export_group("Sounds")
@export var damage_sound : AudioStream
@export var death_sound : AudioStream

var current_health: int = 100
var flags: = 0

signal health_changed(new_health: int)
signal died
signal healed(amount: int) # Amount healed by
signal emitted_sound(actor: CharacterController, location: Vector3, volume: float)

func set_flags(new_flags: ActorFlags) -> void:
	flags = new_flags

func set_flag(flag: ActorFlags) -> void:
	flags |= flag
	print("Setting flag: ", flag, " Current flags: ", flags)

func clear_flag(flag: ActorFlags) -> void:
	flags &= ~flag

func has_flag(flag: ActorFlags) -> bool:
	return (flags & flag) != 0

func get_flags() -> int:
	return flags

func _ready():
	current_health = max_health
	for flag in default_flags:
		set_flag(flag)
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
	if !audio.is_playing():
		audio.play()
	
	var playback := audio.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback:
		playback.play_stream(sound)
		emitted_sound.emit(self, audio.global_position, audio.volume_db)
