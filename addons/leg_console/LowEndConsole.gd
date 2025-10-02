extends Node

signal log_added(message: String, msg_type: MessageType)

var _logger: ConsoleLogger = ConsoleLogger.new()
var _cmd_history: Array = []
var _cmd_index: int = -1
var _commands: Array = []
var _logs = []
var _mutex = Mutex.new()

enum MessageType{ Info, Warning, Error}

@onready var MainWindow := $MainConsole
@onready var OverlayWindow := $OverlayConsole

func add_command(cmd_name: String, delegate: Callable, closeOnExecute: bool = false, description: String = "") -> void:
	if _get_command(cmd_name) != null:
		return

	var cmd = ConsoleCommand.new()
	cmd.name = cmd_name
	cmd.delegate = delegate
	cmd.closeOnExecute = closeOnExecute
	cmd.description = description
	_commands.append(cmd)
	
func remove_command(cmd: ConsoleCommand) -> void:
	if cmd != null:
		_commands.erase(cmd)

func remove_command_by_name(cmd_name: String) -> void:
	var cmd = _get_command(cmd_name)
	if cmd != null:
		_commands.erase(cmd)

func add_log(message: String, msg_type: MessageType):
	_mutex.lock()
	var text = "[%s|%s] (%s) %s" % [Time.get_time_string_from_system(), Engine.get_frames_drawn(), MessageType.find_key(msg_type), message]
	_logs.append([text, msg_type])
	_mutex.unlock()

func get_logs():
	return _logs

func get_command_from_history(offset: int) -> String:
	if _cmd_history.is_empty():
		return ""
	_cmd_index += offset
	if _cmd_index < 0:
		_cmd_index = _cmd_history.size() - 1
	elif _cmd_index >= _cmd_history.size():
		_cmd_index = 0
	return _cmd_history[_cmd_index]

func try_run_command(cmd: String) -> bool:
	var parts = cmd.strip_edges().split(" ", false)
	if parts.is_empty() or parts[0] == "":
		return false

	_cmd_history.append(cmd)
	_cmd_index = -1

	var command_name = parts[0]
	var args = parts.slice(1)

	var command = _get_command(command_name)
	if command != null:
		var argCount = command.delegate.get_argument_count()
		if args.size() != argCount:
			add_log("Invalid command usage, expected " + str(argCount) + " arguments.", MessageType.Error)
			return false

		var result = await command.delegate.callv(args)
		if result and command.closeOnExecute:
			MainWindow.hide()
		return result

	add_log("Invalid command.", MessageType.Warning)
	return true

func _enter_tree() -> void:
	OS.add_logger(_logger)
	LEG_Log.log_added.connect(add_log)

func _exit_tree() -> void:
	OS.remove_logger(_logger)
	LEG_Log.log_added.disconnect(add_log)

func _ready():
	add_command("help", _cmd_help, false, "Shows a list of commands")

func _process(delta):
	if _logs.size() > 0:
		for o in _logs:
			log_added.emit(o[0], o[1])
		_logs.clear()
	
func _get_command(cmd_name: String) -> ConsoleCommand:
	for cmd in _commands:
		if cmd.name == cmd_name:
			return cmd
	return null

func _cmd_help() -> bool:
	var help_text = "Available commands:\n"
	for cmd in _commands:
		help_text += "- " + cmd.name + ": " + cmd.description + "\n"
	add_log(help_text, MessageType.Info)
	return true

class ConsoleLogger extends Logger:
	signal updated(message: String, message_type: MessageType)
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var message = "[Error] %s:%d in %s: %s" % [file, line, function, rationale]
		var message_type = MessageType.Error
		if error_type == ERROR_TYPE_WARNING:
			message_type = MessageType.Warning
		updated.emit(message, message_type)

class ConsoleCommand:
	var name: String
	var delegate: Callable
	var closeOnExecute: bool = false
	var description: String = ""
