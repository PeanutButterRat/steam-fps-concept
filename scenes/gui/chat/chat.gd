extends Control


export(int) var _max_line_count = 50
onready var _history: RichTextLabel = $'%History'
onready var _message: LineEdit = $'%Message'
var chat_colors: Dictionary = {}


func _ready() -> void:
	Steam.connect('lobby_message', self, '_on_Steam_lobby_message')
	Global.connect('chat_event_occured', self, '_on_Global_chat_event_occured')
	_message.clear_button_enabled = true

	seed(OS.get_unix_time())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('ui_accept') and _message:
		_on_Message_text_entered(_message.text)
		_message.text = ''


func _on_Send_pressed() -> void:
	_on_Message_text_entered(_message.text)


func _on_Message_text_entered(new_text: String) -> void:
	_message.set_text("")
	if new_text.strip_edges().empty(): return  # Take no action if message is whitespace.
	
	Steam.sendLobbyChatMsg(Global.lobby_id, new_text)


func record(message: String, color: Color) -> void:
	_history.push_color(color)
	_history.append_bbcode(message + '\n')
	_history.pop()

	if _history.get_line_count() > _max_line_count + 1:  # Line count starts at 1.
		_history.remove_line(0)


# Callback when Steam recieves a lobby message.
func _on_Steam_lobby_message(_lobby_id: int, user_id: int, message: String, _chat_type: int) -> void:
	var color: Color
	if not user_id in chat_colors: chat_colors[user_id] = Color(randf(), randf(), randf())
	color = chat_colors[user_id]
	
	record('%s: %s' % [Steam.getFriendPersonaName(user_id), message], color)


func _on_Global_chat_event_occured(message: String) -> void:
	record(message, Color.black)

