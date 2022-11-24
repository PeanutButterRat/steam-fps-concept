extends Node


export var LobbyScene: PackedScene
export var WorldScene: PackedScene

var world: Spatial
var lobby: Control


func _ready() -> void:
	Global.connect('game_started', self, '_on_Event_game_started')
	
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


func _on_Event_game_started(_packet: Dictionary):
	world = WorldScene.instance()
	add_child(world)
	lobby.queue_free()

