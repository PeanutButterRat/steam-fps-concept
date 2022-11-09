extends Control


export(int) var _max_line_count = 50
onready var _history: RichTextLabel = $'%History'
onready var _message: LineEdit = $'%Message'


func _ready() -> void:
	_message.clear_button_enabled = true
	Global.connect('chat_message_recieved', self, '_on_Global_chat_message_recieved')


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_accept') and _message:
		pass


func _on_Send_pressed() -> void:
	_on_Message_text_entered(_message.get_text())


func _on_Message_text_entered(new_text: String) -> void:
	_message.set_text("")
	if new_text.strip_edges().empty(): return  # Take no action if message is whitespace.
	
	record("You: " + new_text)
	send_message(new_text)


func record(message: String) -> void:
	_history.add_text(message + '\n')
	
	if _history.get_line_count() > _max_line_count + 1:  # Line count starts at 1.
		var _error = _history.remove_line(0)


func send_message(message: String) -> void:
	print(message)
	var data: Dictionary = {
		'chat_message': message,
		'from': Global.STEAM_ID
	}
	
	Global.send_P2P_Packet(Global.RECIPIENT.ALL_MEMBERS, data)


func _on_Global_chat_message_recieved(message: String, sender: int) -> void:
	var from: String
	
	match sender:
		Global.SENDER.NONE: from = ""
		Global.SENDER.UNKNOWN: from = "Unknown: "
		_: from = Steam.getFriendPersonaName(sender) + ": "
		
	record(from + message)
