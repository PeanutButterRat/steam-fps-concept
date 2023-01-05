extends Node



signal player_list_changed(players)
signal lobby_created(lobby_id)
signal recieved_lobby_list(lobbies)
signal chat_event_occured(event)

signal game_started(data)  # []  (lobby)
signal mob_damaged(data)  # [Mob ID, damage, attacker]
signal mob_killed(data)  # [Mob ID, random integer, attacker]
signal mob_moved(data)  # [Mob ID, mob transform]
signal mob_state_changed(data)
signal mob_spawned(data)  # [Mob type, mob ID, transform]

signal weapon_fired(data)
signal weapon_reloaded(data)
signal weapon_swapped(data)

signal player_moved(data)  # [ID, transform]
signal player_teleported(data)
signal player_state_changed(data)
signal player_console_enabled(data)


enum Signals {
	NONE,
	GAME_STARTED,
	MOB_DAMAGED,
	MOB_KILLED,
	MOB_STATE_CHANGED,
	MOB_SPAWNED,
	WEAPON_FIRED,
	WEAPON_RELOADED,
	WEAPON_SWAPPED,
	PLAYER_MOVED,
	PLAYER_TELEPORTED,
	PLAYER_CONSOLE_ENABLED,
	PLAYER_STATE_CHANGED
}

enum Recipient {
	ALL_MEMBERS = -2, 
	ALL_MINUS_CLIENT = -1,
	HOST = 0,
}

enum LobbyVisibility {
	PRIVATE, 
	FRIENDS, 
	PUBLIC, 
	INVISIBLE
}

const SIGNAL_RECIEVED_KEY: String = 'signal'
const SIGNAL_DATA_KEY: String = 'data'
const PACKET_SENDER_KEY: String = 'sender'
const JOINED_LOBBY_SUCCESSFULLY = 1
const LOBBY_NAME_KEY: String = 'name'
const LOBBY_MODE_KEY: String = 'mode'
const STEAM_ID_REMOTE_KEY: String = 'steam_id_remote'

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
var lobby_owner: int = 0

var unique_id_counter: int = 1000 setget set_unique_id_counter


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
	if lobby_id > 0:
		_read_All_P2P_Packets()  # If the player is connected, read packets.


# Only host should generate unique_ids.
func generate_unique_id() -> int:
	var id: int = unique_id_counter
	unique_id_counter += 1
	return id


func set_unique_id_counter(value: int) -> void:
	Logging.warn('Setting unique_id_counter to a value.')
	unique_id_counter = value


func get_signal_string(value: int) -> String:
	var string: String = Signals.keys()[value]
	return string.to_lower()


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
	send_P2P_Packet(Recipient.ALL_MINUS_CLIENT, {'message': 'handshake'})


func send_P2P_Packet(target: int, packet_data: Dictionary) -> void:
	if lobby_id == 0:
		return
		
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0
	
	# Create a data array to send the data through
	var DATA: PoolByteArray = []
	DATA.append_array(var2bytes(packet_data))
	
	# Send the packet to everyone excluding the host.
	if target == Recipient.ALL_MINUS_CLIENT:
		for member in lobby_members:
			if member != Global.STEAM_ID:  # Don't send the packet to yourself.
				Steam.sendP2PPacket(member, DATA, SEND_TYPE, CHANNEL)
	
	# Send the packet to everyone including the host.
	elif target == Recipient.ALL_MEMBERS:
		for member in lobby_members:
			Steam.sendP2PPacket(member, DATA, SEND_TYPE, CHANNEL)
	
	# Send the packet to lobby host.
	elif target == Recipient.HOST:
		Steam.sendP2PPacket(lobby_owner, DATA, SEND_TYPE, CHANNEL)
	
	# Send to specific Recipient.
	else:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	if PACKET_SIZE > 0: # There is a packet.
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)
		
		if PACKET.empty():
			Logging.warn('Read an empty packet with non-zero size.')
		
		var sender: int = PACKET[STEAM_ID_REMOTE_KEY]  # Steam ID.
		var readable_packet: Dictionary = bytes2var(PACKET['data'])
		
		readable_packet[PACKET_SENDER_KEY] = sender
		
		# Deal with packet data.
		var signal_id: int = readable_packet.get(SIGNAL_RECIEVED_KEY, Signals.NONE)
		if signal_id != Signals.NONE:
			var signal_string: String = get_signal_string(signal_id)
			emit_signal(signal_string, readable_packet[SIGNAL_DATA_KEY])
		
		if lobby_owner == STEAM_ID:  # Relay the packet if host.
			send_P2P_Packet(Recipient.ALL_MINUS_CLIENT, readable_packet)


func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return  # Reached the limit on packet-reading.
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
		
		Steam.setLobbyData(lob_id, LOBBY_NAME_KEY, lobby_name)
		Steam.setLobbyData(lob_id, LOBBY_MODE_KEY, 'Duel Beta')


func _on_Lobby_Join_Requested(lob_id: int, friendID: int) -> void:
	emit_signal('chat_message_recieved', 'Joining ' + Steam.getFriendPersonaName(friendID)+ "'s lobby...")
	join_lobby(lob_id)


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


func join_lobby(lob_id: int) -> void:
	emit_signal('chat_event_occured', 'Attempting to join lobby ' + str(lobby_id) + '...')
	
	# Clear any previous lobby members lists, if you were in a previous lobby.
	lobby_members.clear()
	lobby_owner = Steam.getLobbyOwner(lobby_id)
	# Make the lobby join request to Steam.
	Steam.joinLobby(lob_id)


func _on_Lobby_Joined(lob_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:  # Joining was successful.
		lobby_id = lob_id
		lobby_name = Steam.getLobbyData(lobby_id, LOBBY_NAME_KEY)
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
			5:	FAIL_REASON = 'Something unexpected happened.'
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
	Logging.debug('Lobby data updated: ' + 'succeses' if success else 'failed')
	lobby_owner = Steam.getLobbyOwner(_lobby_id)


func leave_Lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id) # Send leave request to Steam
		
		# Close session with all users
		for steam_id in lobby_members:
			if steam_id != Global.STEAM_ID:
				Logging.warn("Closing session with user: " + Steam.getFriendPersonaName(steam_id))
				Steam.closeP2PSessionWithUser(steam_id)
		
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


func send_signal(signal_id: int, data: Array) -> void:
	var message: Dictionary = {
		Global.SIGNAL_RECIEVED_KEY: signal_id,
		Global.SIGNAL_DATA_KEY: data
	}
	
	Global.send_P2P_Packet(Global.Recipient.HOST, message)
