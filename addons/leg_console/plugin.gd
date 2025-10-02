@tool
extends EditorPlugin

func _enter_tree() -> void:
    add_autoload_singleton("LEG_Console", "res://addons/leg_console/LEG_Console.tscn")
