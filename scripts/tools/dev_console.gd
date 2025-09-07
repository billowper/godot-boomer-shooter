class_name Console
extends Node

@export var container: Control = null
@export var scroll_container: ScrollContainer = null
@export var line_edit: LineEdit = null
@export var output: RichTextLabel = null

enum LogTypes { INFO, WARNING, ERROR }

static var instance: Console 

static func add_command(cmd_name: String, delegate: Callable, closeOnExecute: bool = false) -> void:
	var cmd = ConsoleCommand.new()
	cmd.name = cmd_name
	cmd.delegate = delegate
	cmd.closeOnExecute = closeOnExecute
	instance._commands.append(cmd)

static func add_log(msg: String, type: LogTypes = LogTypes.INFO) -> void:
	print_debug(msg)
	var datetime = Time.get_datetime_dict_from_system()
	var time = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]

	var color = Color.WHITE

	match type:
		LogTypes.WARNING:
			color = Color.YELLOW
		LogTypes.ERROR:
			color = Color.RED
	
	instance.output.push_color(color)
	instance.output.append_text("\n["+ time +"] " + msg)
	instance.output.pop()

	await instance.scroll_container.get_v_scroll_bar().changed
	instance.scroll_container.scroll_vertical = int(instance.scroll_container.get_v_scroll_bar().max_value)

# ---------------------------------------------- private	

var _cmd_history: Array = []
var _cmd_index: int = -1
var _commands: Array = []

func _ready():
	instance = self
	line_edit.text_submitted.connect(_on_submit)
	container.visible = false
	output.text = ""
	add_command("help", _cmd_help, false)

func _cmd_help() -> void:
	var help_text = "Available commands:\n"
	for cmd in _commands:
		help_text += "- " + cmd.name + "\n"
	add_log(help_text, LogTypes.INFO)

func _exit_tree() -> void:
	instance = null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_console"):
		_set_visible(!_get_is_visible())

	if not container.visible:
		return
		
	if Input.is_action_just_pressed("ui_cancel"):
		_set_visible(false)		

	if Input.is_action_just_pressed("ui_up") and not _cmd_history.is_empty():
		_cmd_index -= 1
		if _cmd_index < 0:
			_cmd_index = _cmd_history.size() - 1
		line_edit.text = _cmd_history[_cmd_index]

	if Input.is_action_just_pressed("ui_down") and not _cmd_history.is_empty():
		_cmd_index += 1
		if _cmd_index > _cmd_history.size() - 1:
			_cmd_index = 0
		line_edit.text = _cmd_history[_cmd_index]

func _on_submit(cmd: String) -> void:
	_run_command(cmd)	
	line_edit.clear()

func _get_command(cmd_name: String) -> ConsoleCommand:
	for cmd in _commands:
		if cmd.name == cmd_name:
			return cmd
	return null

func _run_command(cmd: String) -> void:
	var parts = cmd.strip_edges().split(" ", false)
	if parts.is_empty() or parts[0] == "":
		return

	_cmd_history.append(cmd)
	_cmd_index = -1

	var command_name = parts[0]
	var args = parts.slice(1)

	var command = _get_command(command_name)
	if command != null:

		var argCount = command.delegate.get_argument_count()
		if args.size() != argCount:
			add_log("Invalid command usage, expected " + str(argCount) + " arguments.", LogTypes.ERROR)
			return

		command.delegate.callv(args)
		if command.closeOnExecute:
			_set_visible(false)
		return

	add_log("Invalid command.", LogTypes.ERROR)

func _get_is_visible() -> bool:
	return container.visible

func _set_visible(state: bool) -> void:
	container.visible = state
	if container.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		line_edit.grab_focus()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		line_edit.clear()
