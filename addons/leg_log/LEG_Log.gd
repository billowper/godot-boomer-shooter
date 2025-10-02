extends Node

signal log_added(message: String, msg_type: LEG_Console.MessageType)

func log(message: String) -> void:
    print(message)
    emit_signal("log_added", message, LEG_Console.MessageType.Info)

func warn(message: String) -> void:
    push_warning(message)
    emit_signal("log_added", message, LEG_Console.MessageType.Warning)

func error(message: String) -> void:
    push_error(message)
    emit_signal("log_added", message, LEG_Console.MessageType.Error)