extends Node



signal player_list_changed(players)
signal lobby_created(lobby_id)
signal recieved_lobby_list(lobbies)
signal chat_event_occured(event)
signal event_occurred(event, packet)


enum Events {
	NONE,
	GAME_STARTED,
	PLAYER_MOVED,
	PLAYER_DAMAGED,
	PLAYER_DIED,
	TIMMY_SPAWNED,
	SHOT_ENVIRONMENT,
}

enum Recipient {
	ALL_MEMBERS = -2, 
	ALL_MINUS_HOST = -1,
	HOST = 0
}

enum LobbyVisibility {
	PRIVATE, 
	FRIENDS, 
	PUBLIC, 
	INVISIBLE
}

const EVENT_OCCURRED: String = 'event'
const EVENT_DATA: String = 'data'
const PACKET_SENDER_KEY: String = 'sender'

# Steam variables.
var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ''

# Lobby variables.
const PACKET_READ_LIMIT: int = 32
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_vote_kick: bool = false
var lobby_max_members: int = 4
var lobby_name: String = "Unnamed Lobby"



func _ready() -> void:
	_initialize_Steam()
	
	Steam.connect('lobby_created', self, '_on_Lobby_Created')
	Steam.connect('lobby_match_list', self, '_on_Lobby_Match_List')
	Steam.connect('lobby_joined', self, '_on_Lobby_Joined')
	Steam.connect('lobby_chat_update', self, '_on_Lobby_Chat_Update')
	Steam.connect('lobby_data_update', self, '_on_Lobby_Data_Update')
	Steam.connect('lobby_invite', self, '_on_Lobby_Invite')
	Steam.connect('join_requested', self, '_on_Lobby_Join_Requested')
	Steam.connect('persona_state_change', self, '_on_Persona_Change')
	Steam.connect('p2p_session_request', self, '_on_P2P_Session_Request')
	Steam.connect('p2p_session_connect_fail', self, '_on_P2P_Session_Connect_Fail')


func _process(_delta: float) -> void:
	Steam.run_callbacks()
	if lobby_id > 0: _read_All_P2P_Packets()  # If the player is connected, read packets.


func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	Logging.debug('Did Steam initialize?: ' + str(INIT))

	if INIT['status'] != 1:
		Logging.error('Failed to initialize Steam. ' + str(INIT['verbal']) + ' Shutting down...')
		get_tree().quit()
	else:
		IS_ONLINE = Steam.loggedOn()
		STEAM_ID = Steam.getSteamID()
		STEAM_USERNAME = Steam.getPersonaName()
		IS_OWNED = Steam.isSubscribed()
		
		if IS_OWNED == false:
			Logging.warn('User does not own this game.')
			get_tree().quit()


func _make_P2P_Handshake() -> void:
	Logging.debug('Sending P2P handshake to the lobby.')
	send_P2P_Packet(Recipient.ALL_MINUS_HOST, {'message': 'handshake'})


func send_P2P_Packet(target: int, packet_data: Dictionary) -> void:
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0
	
	# Create a data array to send the data through
	var DATA: PoolByteArray = []
	DATA.append_array(var2bytes(packet_data))

	# Send the packet to everyone excluding the host.
	if target == Recipient.ALL_MINUS_HOST:
		for member in lobby_members:
			if member != Global.STEAM_ID:  # Don't send the packet to yourself.
				Steam.sendP2PPacket(member, DATA, SEND_TYPE, CHANNEL)
	
	# Send the packet to everyone including the host.
	elif target == Recipient.ALL_MEMBERS:
		for member in lobby_members:
			Steam.sendP2PPacket(member, DATA, SEND_TYPE, CHANNEL)
	
	# Send the packet to lobby host.
	elif target == Recipient.HOST:
		Steam.sendP2PPacket(Steam.getLobbyOwner(lobby_id), DATA, SEND_TYPE, CHANNEL)
	
	# Send to specific Recipient.
	else: Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	if PACKET_SIZE > 0: # There is a packet.
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)
		
		if PACKET.empty() or PACKET == null:
			Logging.warn('Read an empty packet with non-zero size.')
		
		var sender: int = PACKET['steam_id_remote']  # Steam ID.
		var readable_packet: Dictionary = bytes2var(PACKET['data'])
		
		readable_packet[PACKET_SENDER_KEY] = sender
		
		# Logging.debug('Packet read from %s: %s' % [
		#	Steam.getFriendPersonaName(sender), str(readable_packet)
		# ])
		
		# Deal with packet data.
		var event: int = readable_packet.get(EVENT_OCCURRED, Events.NONE)
		if event != Events.NONE: emit_signal('event_occurred', event, readable_packet)


func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT: return  # Reached the limit on packet-reading.
	elif Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)


func _on_P2P_Session_Request(remote_id: int) -> void:
	var _REQUESTER: String = Steam.getFriendPersonaName(remote_id)

	# Accept or deny the P2P session.
	Steam.acceptP2PSessionWithUser(remote_id)
	_make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	var prefix: String = 'Session failure with ' + str(steamID)
	var postfix: String
	
	match session_error:
		0:	postfix = ' [no error given].'
		1:	postfix = ' [target user not running the same game].'
		2:	postfix = " [local user doesn't own app / game]."
		3:	postfix = " [target user isn't connected to Steam]."
		4:	postfix = ' [connection timed out].'
		5:	postfix = ' [unused].'
		_:	postfix = ' [unknown error ' + str(session_error) + '].'
	
	Logging.warn(prefix + postfix)


func _on_Lobby_Created(connect: int, lob_id: int) -> void:
	emit_signal('lobby_created', lob_id)
	
	if connect == 1:  # Creation was successful.
		Steam.setLobbyJoinable(lob_id, true)  # Just in case (should be default).
		Logging.debug('Allowing Steam to be relay backup: ' + str(Steam.allowP2PPacketRelay(true)))  # If needed.
		
		Steam.setLobbyData(lob_id, 'name', lobby_name)
		Steam.setLobbyData(lob_id, 'mode', 'GodotSteam test')


func _on_Lobby_Join_Requested(lob_id: int, friendID: int) -> void:
	emit_signal('chat_message_recieved', 'Joining ' + Steam.getFriendPersonaName(friendID)+ "'s lobby...")
	_join_Lobby(lob_id)


func _on_Lobby_Match_List(lobbies: Array) -> void:
	var list: Array = []
	
	for lobby in lobbies:
		var lobby_data: Dictionary = {
			'id': lobby,
			'name': Steam.getLobbyData(lobby, "name"),
			'mode': Steam.getLobbyData(lobby, "mode"),
			'member_count': Steam.getNumLobbyMembers(lobby)
		}
		
		if not lobby_data['name'].empty():
			list.append(lobby_data)
	
	emit_signal('recieved_lobby_list', lobbies)


func _on_Persona_Change(steam_id: int, _flag: int) -> void:
	Logging.debug('%s had information change, updating lobby list.' % [Steam.getFriendPersonaName(steam_id)])
	lobby_members = _get_lobby_members()
	emit_signal('player_list_changed', lobby_members)


func _join_Lobby(lob_id: int) -> void:
	emit_signal('chat_event_occured', 'Attempting to join lobby ' + str(lobby_id) + '...')
	
	# Clear any previous lobby members lists, if you were in a previous lobby.
	lobby_members.clear()

	# Make the lobby join request to Steam.
	Steam.joinLobby(lob_id)


func _on_Lobby_Joined(lob_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:  # Joining was successful.
		lobby_name = Steam.getLobbyData(lob_id, 'name')
		lobby_id = lob_id
		lobby_members = _get_lobby_members()
		emit_signal('player_list_changed', lobby_members)
		emit_signal('chat_event_occured', 'Joined ' + lobby_name + ' successfully.')
		
		_make_P2P_Handshake()  # Initial handshake.
		
	else:
		var FAIL_REASON: String
		
		match response:
			2:	FAIL_REASON = 'This lobby no longer exists.'
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = 'The lobby is now full.'
			5:	FAIL_REASON = 'Uh... something unexpected happened!'
			6:	FAIL_REASON = 'You are banned from this lobby.'
			7:	FAIL_REASON = 'You cannot join due to having a limited account.'
			8:	FAIL_REASON = 'This lobby is locked or disabled.'
			9:	FAIL_REASON = 'This lobby is community locked.'
			10:	FAIL_REASON = 'A user in the lobby has blocked you from joining.'
			11:	FAIL_REASON = 'A user you have blocked is in the lobby.'
			_:	FAIL_REASON = 'Unknown failure.'
		
		emit_signal('chat_event_occured', FAIL_REASON)
		Steam.requestLobbyList() # Re-open the lobby list.


func _on_Lobby_Data_Update(success: int, _lobby_id: int, _member_id: int):
	Logging.debug('Lobby data updated: ' + 'true' if success else 'false')


func leave_Lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id) # Send leave request to Steam
		
		# Close session with all users
		for member in lobby_members:
			if member != Global.STEAM_ID:
				Logging.warn("Closing session with user: " + member['steam_name'])
				Steam.closeP2PSessionWithUser(member['steam_id'])
		
		lobby_members.clear()
		lobby_id = 0
		
		emit_signal('chat_event_occured', 'Left the lobby.')
		emit_signal('player_list_changed', lobby_members)


func _get_lobby_members() -> Array:
	var members: Array = []
	
	for member in range(0, Steam.getNumLobbyMembers(lobby_id)):
		members.append(Steam.getLobbyMemberByIndex(lobby_id, member))
	
	return members


func _on_Lobby_Chat_Update(_lobby_id: int, changed_id: int, making_change_id: int, _chat_state: int):
	lobby_members = _get_lobby_members()
	emit_signal('player_list_changed', lobby_members)
	Logging.debug('Lobby chat update: %d (changed_id), %d (making_change_id)' % [changed_id, making_change_id])


func emit_event(event: int, data: Array, recipient: int) -> void:
	var message: Dictionary = {
		Global.EVENT_OCCURRED: event,
		Global.EVENT_DATA: data
	}
	
	Global.send_P2P_Packet(recipient, message)
