class_name  Console
extends Node

@export var container: Control = null
@export var line_edit: LineEdit = null
@export var output: RichTextLabel = null

static var _instance: Console 

func _ready():
	_instance = self
	line_edit.text_submitted.connect(on_submit)
	container.visible = false
	output.text = ""
	add_log("console init")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_console"):
		container.visible = !container.visible
		if container.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			line_edit.grab_focus()

func on_submit(cmd: String) -> void:
	run_command(cmd)
	line_edit.clear()

static func run_command(cmd: String) -> void:
	var expression = Expression.new()
	var parse_error = expression.parse(cmd)
	if parse_error != OK:
		add_log(expression.get_error_text())
		return

	var result = expression.execute([], _instance)
	if result != null:
		add_log(result)

static func add_log(msg: String) -> void:
	print(msg)
	_instance.output.text += "\n" + "["+ Time.get_datetime_string_from_system() +"] " + msg

func map(msg: String) -> void:
	GM.load_map(msg)

func join(address: String) -> void:
	GM.join_game(address)
