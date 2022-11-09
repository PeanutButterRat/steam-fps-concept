extends Node


signal chat_message_recieved(message, sender)
signal player_list_changed(players)
signal lobby_created(lobby_id)
signal recieved_lobby_list(lobbies)

const SENDER = {UNKNOWN = -1, NONE = 0}
enum RECIPIENT {ALL_MEMBERS = -1, ALL_MINUS_HOST = 0}
enum LOBBY_VISIBILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}

# Steam variables.
var IS_OWNED: bool = false
var IS_ONLINE: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = ''


# Lobby variables.
const PACKET_READ_LIMIT: int = 32
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 4

var lobby_name = "Default"


func _ready() -> void:
	_initialize_Steam()
	
	Steam.connect('lobby_created', self, '_on_Lobby_Created')
	Steam.connect('lobby_match_list', self, '_on_Lobby_Match_List')
	Steam.connect('lobby_joined', self, '_on_Lobby_Joined')
	Steam.connect('lobby_chat_update', self, '_on_Lobby_Chat_Update')
	Steam.connect('lobby_message', self, '_on_Lobby_Message')
	Steam.connect('lobby_data_update', self, '_on_Lobby_Data_Update')
	Steam.connect('lobby_invite', self, '_on_Lobby_Invite')
	Steam.connect('join_requested', self, '_on_Lobby_Join_Requested')
	Steam.connect('persona_state_change', self, '_on_Persona_Change')
	Steam.connect('p2p_session_request', self, '_on_P2P_Session_Request')
	Steam.connect('p2p_session_connect_fail', self, '_on_P2P_Session_Connect_Fail')


func _process(_delta: float) -> void:
	Steam.run_callbacks()
	# If the player is connected, read packets.
	if LOBBY_ID > 0:
		_read_All_P2P_Packets()


func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	print('Did Steam initialize?: ' + str(INIT))

	if INIT['status'] != 1:
		print('Failed to initialize Steam. ' + str(INIT['verbal']) + ' Shutting down...')
		get_tree().quit()

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_USERNAME = Steam.getPersonaName()
	IS_OWNED = Steam.isSubscribed()
	
	if IS_OWNED == false:
		print('User does not own this game.')
		get_tree().quit()


func _make_P2P_Handshake() -> void:
	print('Sending P2P handshake to the lobby.')
	send_P2P_Packet(RECIPIENT.ALL_MINUS_HOST, {'message': 'handshake'})


func send_P2P_Packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0
	
	packet_data['from'] = STEAM_ID
	
	# Create a data array to send the data through
	var DATA: PoolByteArray
	DATA.append_array(var2bytes(packet_data))

	# Send to specific recipient.
	if target != 0:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)
	# Send the packet to everyone excluding the host.
	elif target == RECIPIENT.ALL_MINUS_HOST and LOBBY_MEMBERS.size() > 1:
		for MEMBER in LOBBY_MEMBERS:
			if MEMBER['steam_id'] != Global.STEAM_ID:  # Don't send the packet to yourself.
				Steam.sendP2PPacket(MEMBER['steam_id'], DATA, SEND_TYPE, CHANNEL)
	# Send the packet to everyone including the host.
	elif target == RECIPIENT.ALL_MEMBERS and LOBBY_MEMBERS.size() > 1:
		for MEMBER in LOBBY_MEMBERS:
			Steam.sendP2PPacket(MEMBER['steam_id'], DATA, SEND_TYPE, CHANNEL)


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	if PACKET_SIZE > 0: # There is a packet.
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)
		
		if PACKET.empty() or PACKET == null:
			print('[Warning]: read an empty packet with non-zero size!')
		
		var PACKET_SENDER: int = PACKET['steam_id_remote']
		var READABLE_PACKET: Dictionary = bytes2var(PACKET['data'])
		
		print('Packet read: '+ str(READABLE_PACKET))
		
		# Deal with packet data.
		if READABLE_PACKET.has('chat_message'):
			var message: String = READABLE_PACKET['chat_message']
			var sender: int = READABLE_PACKET['from']
			emit_signal('chat_message_recieved', message, sender)


func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT: return  # Reached the limit on packet-reading.
	elif Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)


func _on_P2P_Session_Request(remote_id: int) -> void:
	var REQUESTER: String = Steam.getFriendPersonaName(remote_id)

	# Accept or deny the P2P session.
	Steam.acceptP2PSessionWithUser(remote_id)
	_make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	var prefix: String = '[Warning]: Session failure with ' + str(steamID)
	var postfix: String
	
	match session_error:
		0:	postfix = ' [no error given].'
		1:	postfix = ' [target user not running the same game].'
		2:	postfix = " [local user doesn't own app / game]."
		3:	postfix = " [target user isn't connected to Steam]."
		4:	postfix = ' [connection timed out].'
		5:	postfix = ' [unused].'
		_:	postfix = ' [unknown error ' + str(session_error) + '].'
	
	print(prefix + postfix)


func _on_Lobby_Created(connect: int, lobby_id: int) -> void:
	emit_signal('lobby_created', lobby_id)
	
	if connect == 1:  # Creation was successful.
		Steam.setLobbyJoinable(lobby_id, true)  # Just in case (should be default).
		print('Allowing Steam to be relay backup: ' + str(Steam.allowP2PPacketRelay(true)))  # If needed.
		
		Steam.setLobbyData(lobby_id, 'name', lobby_name)
		Steam.setLobbyData(lobby_id, 'mode', 'GodotSteam test')


func _on_Lobby_Join_Requested(lobby_id: int, friendID: int) -> void:
	emit_signal('chat_message_recieved', 'Joining ' + Steam.getFriendPersonaName(friendID)+ "'s lobby...")
	_join_Lobby(lobby_id)


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
	print('[STEAM] A user (' + str(steam_id) + ') had information change, updating the lobby list...')

	LOBBY_MEMBERS = _get_Lobby_Members()
	emit_signal('player_list_changed', LOBBY_MEMBERS)


func _join_Lobby(lobby_id: int) -> void:
	emit_signal('chat_message_recieved', 'Attempting to join lobby ' + str(lobby_id) + '...', SENDER.NONE)
	
	# Clear any previous lobby members lists, if you were in a previous lobby
	LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)


func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:  # Joining was successful.
		emit_signal('chat_message_recieved', 'Lobby joined successfully!', SENDER.NONE)
		
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobby_id

		# Get the lobby members
		LOBBY_MEMBERS = _get_Lobby_Members()
		emit_signal('player_list_changed', LOBBY_MEMBERS)
		
		# Make the initial handshake
		_make_P2P_Handshake()
		
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
		
		emit_signal('chat_message_recieved', FAIL_REASON)
		emit_signal('recieved_lobby_list') # Re-open the lobby list


func _on_Lobby_Data_Update(success: int, lobby_id: int, member_id: int):
	print('Lobby (%d) data was updated, success: %d, member: %d' % [lobby_id, success, member_id])


func leave_Lobby() -> void:
	if LOBBY_ID != 0:
		Steam.leaveLobby(LOBBY_ID) # Send leave request to Steam
		
		# Close session with all users
		for member in LOBBY_MEMBERS:
			if member['steam_id'] != Global.STEAM_ID:
				Steam.closeP2PSessionWithUser(member['steam_id'])  # Close session with lobby member.
		
		LOBBY_MEMBERS.clear()
		LOBBY_ID = 0
		emit_signal('player_list_changed', LOBBY_MEMBERS)
		emit_signal('chat_message_recieved', 'Left the lobby.', SENDER.NONE)


func _get_Lobby_Members() -> Array:
	var lobby_members: Array = []
	
	for member in range(0, Steam.getNumLobbyMembers(LOBBY_ID)):
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(LOBBY_ID, member)
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		
		lobby_members.append(
			{
				'steam_id':MEMBER_STEAM_ID, 
				'steam_name':MEMBER_STEAM_NAME
			}
		)
	
	return lobby_members
