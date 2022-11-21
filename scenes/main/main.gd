extends Node


export var LobbyScene: PackedScene
export var WorldScene: PackedScene

var world: Spatial
var lobby: Control


func _ready() -> void:
	var packet_processor: Object = funcref(self, "_on_Global_started_game")
	Global.register_callback(packet_processor, Global.EVENT.GAME_STARTED)
	
	_check_Command_Line()
	
	if lobby == null:
		lobby = LobbyScene.instance()
		add_child(lobby)


func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()
	
	if ARGUMENTS.size() > 0:  # A Steam connection argument and lobby invite exists.
		if ARGUMENTS[0] == "+connect_lobby" and int(ARGUMENTS[1]) > 0:
			Logging.debug('Joining command line invite.')
			lobby = LobbyScene.instance()
			add_child(lobby)
			Global._join_Lobby(int(ARGUMENTS[1]))


func _on_Global_started_game(_packet: Dictionary):
	world = WorldScene.instance()
	add_child(world)
	lobby.queue_free()
