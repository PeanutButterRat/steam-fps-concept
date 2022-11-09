extends Control


onready var lobby_list: VBoxContainer = $'%Lobbies'
onready var player_list: VBoxContainer = $'%PlayerList'
onready var lobby_name_edit: LineEdit = $'%Name'
onready var chat: Control = $'%Chat'


func _ready() -> void:
	Global.connect('player_list_changed', self, '_on_Global_player_list_changed')
	Global.connect('recieved_lobby_list', self, '_on_Global_recieved_lobby_list')


func _on_Create_pressed() -> void:
	if Global.LOBBY_ID == 0:
		var lobby_name: String = lobby_name_edit.text.strip_edges()
		lobby_name_edit.clear()
		
		if lobby_name.empty():
			lobby_name = Global.STEAM_USERNAME + "'s Lobby"
		Global.lobby_name = lobby_name
		
		Steam.createLobby(Global.LOBBY_VISIBILITY.PUBLIC, Global.LOBBY_MAX_MEMBERS)


func _on_Find_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(3)  # Set distance to worldwide.

	print("Requesting a lobby list...")
	Steam.requestLobbyList()


func _on_Chat_sent_message(message) -> void:
	Global.send_P2P_Packet(0, {'message': message})


func _on_Leave_pressed() -> void:
	Global.leave_Lobby()


func _on_Global_player_list_changed(players: Array) -> void:
	for player in player_list.get_children():
		player.queue_free()
	
	for player in players:
		var label: Label = Label.new()
		label.text = player['steam_name']
		
		player_list.add_child(label)


func _on_Global_recieved_lobby_list(lobbies: Array) -> void:
	for option in lobby_list.get_children():
		option.queue_free()

	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(lobby, "mode")
		
		if not lobby_name.empty():
			var button: Button = Button.new()
			button.text = lobby_name + ": " + lobby_mode
			button.connect("pressed", Global, "_join_Lobby", [lobby])
		
			lobby_list.add_child(button)
