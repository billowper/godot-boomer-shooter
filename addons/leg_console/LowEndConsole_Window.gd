extends Node

var _windowed: bool = false

const _default_height: int = 400

@onready var _root : Control = $Root
@onready var _output : RichTextLabel = $Root/PanelContainer/VBoxContainer/ScrollContainer/MarginContainer/Output
@onready var _input : LineEdit = %Input

func add_log(message: String, msg_type: LEG_Console.MessageType):
	var color = Color.WHITE if msg_type == LEG_Console.MessageType.Info else Color.YELLOW if msg_type == LEG_Console.MessageType.Warning else Color.RED

	_output.push_color(color)
	_output.append_text("\n%s" % message)
	_output.pop()

	await %ScrollContainer.get_v_scroll_bar().changed
	%ScrollContainer.scroll_vertical = int(%ScrollContainer.get_v_scroll_bar().max_value)

func show():
	_root.visible = true
	LEG_Console.add_command("clear", _cmd_clear, false, "Clears the console output")
	_input.grab_focus()
	_input.clear()
	_input.text_changed.connect(_on_input_changed)
	if _windowed:
		$PopoutWindow.show()
		await get_tree().process_frame
		_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_root.size = $PopoutWindow.size
		$PopoutWindow.grab_focus()


func hide():
	_input.clear()
	_input.text_changed.disconnect(_on_input_changed)
	_root.visible = false
	LEG_Console.remove_command_by_name("clear")
	$PopoutWindow.hide()

func toggle():
	if _root.visible:
		hide()
	else:
		show()

func is_visible() -> bool:
	return _root.visible

func _enter_tree() -> void:
	LEG_Console.log_added.connect(add_log)

func _exit_tree() -> void:
	LEG_Console.log_added.disconnect(add_log)

func _ready():
	_root.visible = false
	_input.text_submitted.connect(_on_submit)

	$PopoutWindow.focus_entered.connect(func(): 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)

	$PopoutWindow.focus_exited.connect(func(): 
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	

	%PopoutToggle.pressed.connect(func():
		_windowed = not _windowed
		if _windowed:
			$PopoutWindow.popup()
			_root.reparent($PopoutWindow)
			await get_tree().process_frame
			_root.set_anchors_preset(Control.PRESET_FULL_RECT)
			_root.size = $PopoutWindow.size

		else:
			_root.reparent(self)
			_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
			_root.size = get_viewport().get_visible_rect().size
			_root.size.y = _default_height

			$PopoutWindow.hide()
	)

func _on_input_changed(new_text: String):
	if new_text.ends_with("`"):
		hide()

func _cmd_clear() -> bool:
	_output.clear()
	_output.push_color(Color.WHITE)
	_output.pop()
	return true

func _on_submit(input_string: String):
	_input.clear()
	LEG_Console.try_run_command(input_string)

func _process(delta):
	if not _root.visible:
		return
		
	if Input.is_action_just_pressed("ui_cancel"):
		hide()
		return

	if Input.is_action_just_pressed("ui_up"):
		_input.text = LEG_Console.get_command_from_history(-1)

	if Input.is_action_just_pressed("ui_down"):
		_input.text = LEG_Console.get_command_from_history(1)
