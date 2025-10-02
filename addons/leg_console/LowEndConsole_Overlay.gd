extends Node

@onready var _root : Control = $Root
@onready var _output : RichTextLabel = $Root/Output

func is_visible() -> bool:
	return _root.visible

func add_log(message: String, msg_type: LEG_Console.MessageType):
	var color = Color.WHITE if msg_type == LEG_Console.MessageType.Info else Color.YELLOW if msg_type == LEG_Console.MessageType.Warning else Color.RED

	_output.push_color(color)
	_output.append_text("\n%s" % message)
	_output.pop()

	await %ScrollContainer.get_v_scroll_bar().changed
	%ScrollContainer.scroll_vertical = int(%ScrollContainer.get_v_scroll_bar().max_value)

func clear():
	_output.clear()

func show():
	_root.visible = true

func hide():
	_root.visible = false

func _enter_tree() -> void:
	LEG_Console.log_added.connect(add_log)

func _exit_tree() -> void:
	LEG_Console.log_added.disconnect(add_log)

func toggle():
	if _root.visible:
		hide()
	else:
		show()
		
func _ready():
	_output.clear()