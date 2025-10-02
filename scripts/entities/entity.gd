class_name Entity
extends Node3D

# --------------------------------------- setup

func _ready():
	current_health = max_health
	on_ready()

func on_ready() -> void:
	pass

# --------------------------------------- damage

signal on_hit(source: Entity, origin: Vector3, direction: Vector3, damage: int)

func take_hit(source: Entity, origin: Vector3, direction: Vector3, damage: int) -> void:
	if not is_alive():
		return

	LEG_Log.log("Entity %s took hit from %s with damage %d" % [self.name, source, damage])
	
	if damage_sound:
		play_sound(damage_sound)
	
	take_damage(damage)
	
	on_hit.emit(source, origin, direction, damage)

# --------------------------------------- health

@export_group("Stats")
@export var max_health: int = 100

var current_health: int = 100

signal health_changed(new_health: int)
signal died
signal healed(amount: int) # Amount healed by
	
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

func heal(amount: int) -> bool:
	if is_alive():
		current_health += amount
		clamp(current_health, 0, max_health)
		healed.emit(amount)
		return amount > 0
	return false
	
# --------------------------------------- audio 

@export_group("Audio")
@export var audio: AudioStreamPlayer3D
@export var damage_sound : AudioStream
@export var death_sound : AudioStream

signal emitted_sound(actor: CharacterController, location: Vector3, volume: float)

func play_sound(sound: AudioStream) -> void:

	if not audio:
		return

	if !audio.is_playing():
		audio.play()
	
	var playback := audio.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if playback:
		playback.play_stream(sound)
		emitted_sound.emit(self, audio.global_position, audio.volume_db)

# --------------------------------------- usage

signal used()

func use() -> void:
	on_use()
	used.emit()

func on_use() -> void:
	pass;
