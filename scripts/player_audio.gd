extends AudioStreamPlayer2D

@export var player_character : PlayerController
@export var jump_sound : AudioStream
@export var landed_sound : AudioStream

func _ready():
	player_character.jumped.connect(self.on_jump)
	player_character.landed.connect(self.on_landed)

func on_jump():
	stream = jump_sound
	play()

func on_landed():
	stream = landed_sound
	play()
	
