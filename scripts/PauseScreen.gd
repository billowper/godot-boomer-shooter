extends Control

func _on_btn_resume_pressed() -> void:
	Game.toggle_pause()

func _on_btn_options_pressed() -> void:
	pass # Replace with function body.

func _on_btn_quit_pressed() -> void:
	Game.quit_to_menu()

