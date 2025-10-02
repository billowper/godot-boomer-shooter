@tool
extends EditorPlugin

func _enter_tree() -> void:
    add_autoload_singleton("LEG_Log", "res://addons/leg_log/LEG_Log.gd")
