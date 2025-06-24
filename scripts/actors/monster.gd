class_name Monster
extends Actor

enum TaskTypes{
	MOVE_TO_POSITION,
	LOOK_AT_POSITION,
	SHOOT_AT_TARGET,
	FIND_FLEE_POSITION,
}

@export_group("Components")
@export var senses: AI_Senses

@export_group("Animations")
@export var animations: AnimationPlayer
@export var idle_animation: String = "idle"
@export var walk_animation: String = "walk" 
@export var run_animation: String = "run"
@export var attack_animation: String = "attack"
@export var death_animation: String = "die"

func _physics_process(delta: float):
	senses.hear() # Check for sounds every physics frame
	senses.see() # Check for visual targets every physics frame

func _process(delta: float):
	think()

func think() -> void:
	if senses.current_target:
		print("target flags: ", senses.current_target.get_flags())
