extends Control


enum LOBBY_VISIBILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}

# Lobby variables.
const PACKET_READ_LIMIT: int = 32
var STEAM_USERNAME: String = ""
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 4

func _ready() -> void:
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	Steam.connect("persona_state_change", self, "_on_Persona_Change")
	Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")

	# Check for command line arguments
	_check_Command_Line()

func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:

		# A Steam connection argument exists
		if ARGUMENTS[0] == "+connect_lobby":
		
			# Lobby invite exists so try to connect to it
			if int(ARGUMENTS[1]) > 0:

				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("CMD Line Lobby ID: "+str(ARGUMENTS[1]))
				_join_Lobby(int(ARGUMENTS[1]))


func _process(_delta) -> void:
	# If the player is connected, read packets.
	if LOBBY_ID > 0:
		_read_All_P2P_Packets()


func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= Global.PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)


func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var PACKET_SENDER: int = PACKET['steam_id_remote']

		# Make the packet data readable
		var PACKET_CODE: PoolByteArray = PACKET['data']
		var READABLE: Dictionary = bytes2var(PACKET_CODE)

		# Print the packet to output
		print("Packet: "+str(READABLE))

		# Append logic here to deal with packet data

func _create_Lobby() -> void:
	# Make sure a lobby is not already set
	if LOBBY_ID == 0:
		Steam.createLobby(LOBBY_VISIBILITY.PUBLIC, Global.LOBBY_MAX_MEMBERS)


func _on_Lobby_Created(connect: int, lobby_id: int) -> void:
	if connect == 1:
		LOBBY_ID = lobby_id
		print("Created a lobby: "+str(lobby_id))

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "Gramps' Lobby")
		Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var RELAY: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: "+str(RELAY))


func _join_Lobby(lobby_id: int) -> void:
	print("Attempting to join lobby "+str(lobby_id)+"...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	Global.LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)


func _on_Open_Lobby_List_pressed() -> void:
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(3)

	print("Requesting a lobby list")
	Steam.requestLobbyList()  # Calls back _on_Lobby_Match_List.


func _on_Lobby_Match_List(lobbies: Array) -> void:
	for LOBBY in lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var LOBBY_NAME: String = Steam.getLobbyData(LOBBY, "name")
		var LOBBY_MODE: String = Steam.getLobbyData(LOBBY, "mode")

		# Get the current number of members
		var LOBBY_NUM_MEMBERS: int = Steam.getNumLobbyMembers(LOBBY)

		# Create a button for the lobby
		var LOBBY_BUTTON: Button = Button.new()
		#LOBBY_BUTTON.set_text("Lobby ", LOBBY, ": ", LOBBY_NAME, " [", LOBBY_MODE, "] - ", LOBBY_NUM_MEMBERS, " Player(s)")
		LOBBY_BUTTON.set_size(Vector2(800, 50))
		LOBBY_BUTTON.set_name("lobby_"+str(LOBBY))
		LOBBY_BUTTON.connect("pressed", self, "_join_Lobby", [LOBBY])

		# Add the new lobby to the list
		$"Lobby Panel/Panel/Scroll/VBox".add_child(LOBBY_BUTTON)
