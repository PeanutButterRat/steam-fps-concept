extends Node


export var LobbyScene: PackedScene
export var WorldScene: PackedScene

onready var options_menu: PopupPanel = $"%OptionsMenu"

var world: Spatial
var lobby: Control


func _ready() -> void:
	Global.connect('game_started', self, '_on_Global_game_started')
	
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
			Global.join_Lobby(int(ARGUMENTS[1]))


func _on_Global_game_started(_data: Array):
	options_menu.hide()
	world = WorldScene.instance()
	add_child(world)
	lobby.queue_free()
	
	if Steam.getLobbyOwner(Global.lobby_id) != Global.STEAM_ID:
		Console.enabled = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed('quit'):
		get_tree().quit()

