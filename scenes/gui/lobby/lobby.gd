extends Control


onready var lobby_list: VBoxContainer = $'%Lobbies'
onready var player_list: VBoxContainer = $'%PlayerList'
onready var lobby_name_edit: LineEdit = $'%Name'
onready var chat: Control = $'%Chat'


func _ready() -> void:
	Global.connect('player_list_changed', self, '_on_Global_player_list_changed')
	Global.connect('recieved_lobby_list', self, '_on_Global_recieved_lobby_list')


func _on_Create_pressed() -> void:
	if Global.lobby_id == 0:
		var lobby_name: String = lobby_name_edit.text.strip_edges()
		lobby_name_edit.clear()
		
		if lobby_name.empty(): lobby_name = Global.STEAM_USERNAME + "'s Lobby"
		Global.lobby_name = lobby_name
		Steam.createLobby(Global.LobbyVisibility.PUBLIC, Global.lobby_max_members)


func _on_Find_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(3)  # Set distance to worldwide.

	Logging.debug("Requesting a lobby list...")
	Steam.requestLobbyList()


func _on_Leave_pressed() -> void:
	Global.leave_Lobby()


func _on_Global_player_list_changed(players: Array) -> void:
	for label in player_list.get_children():
		label.queue_free()
	
	for player in players:
		var label: Label = Label.new()
		label.text = Steam.getFriendPersonaName(player)
		
		player_list.add_child(label)


func _on_Global_recieved_lobby_list(lobbies: Array) -> void:
	for option in lobby_list.get_children():
		option.queue_free()

	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, Global.LOBBY_NAME_KEY)
		var lobby_mode: String = Steam.getLobbyData(lobby, Global.LOBBY_MODE_KEY)
		var members: int = Steam.getNumLobbyMembers(lobby)
		
		if lobby_name and lobby_mode:
			var button: Button = Button.new()
			button.text = '%s: %s (%d)' % [lobby_name, lobby_mode, members]
			button.connect("pressed", Global, "join_lobby", [lobby])
		
			lobby_list.add_child(button)


func _on_Start_pressed() -> void:
	if Global.lobby_id == 0:
		return  # Must be in a lobby to start a game.
	if Steam.getLobbyOwner(Global.lobby_id) != Global.STEAM_ID:
		return  # Must be host.
	
	Global.send_signal(Global.SignalConstants.GAME_STARTED, [], Global.Recipient.ALL_MEMBERS)
