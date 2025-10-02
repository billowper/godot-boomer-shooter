extends Control

func start_game() -> void:
	Game.start_game()

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
