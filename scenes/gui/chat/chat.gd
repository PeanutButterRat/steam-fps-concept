extends Control


export(int) var _max_line_count = 50
onready var _history: RichTextLabel = $'%History'
onready var _message: LineEdit = $'%Message'


func _ready() -> void:
	_message.clear_button_enabled = true
	Global.connect('chat_event_occured', self, '_on_Global_chat_event_occured')
	
	var packet_processor: Object = funcref(self, "_on_Global_chat_message_recieved")
	Global.register_func_ref(packet_processor, 'chat_message')


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_accept') and _message:
		_on_Message_text_entered(_message.text)
		_message.text = ''


func _on_Send_pressed() -> void:
	_on_Message_text_entered(_message.text)


func _on_Message_text_entered(new_text: String) -> void:
	_message.set_text("")
	if new_text.strip_edges().empty(): return  # Take no action if message is whitespace.
	
	send_message(new_text)


func record(message: String) -> void:
	_history.add_text(message + '\n')
	
	if _history.get_line_count() > _max_line_count + 1:  # Line count starts at 1.
		_history.remove_line(0)


func send_message(message: String) -> void:
	var data: Dictionary = {
		'chat_message': message,
	}
	
	Global.send_P2P_Packet(Global.RECIPIENT.ALL_MEMBERS, data)


func _on_Global_chat_message_recieved(packet: Dictionary) -> void:
	var sender: int = packet.get('from')
	var message: String = packet.get('chat_message')
	var from: String
	
	if sender == Global.STEAM_ID: 
		from = "You: "
	else: 
		from = Steam.getFriendPersonaName(sender) + ": "
		
	record(from + message)


func _on_Global_chat_event_occured(event: String) -> void:
	record(event)
