extends Node



const NO_LOBBY: int = 0

var LobbyScene: PackedScene = preload('res://scenes/gui/lobby/lobby.tscn')
var WorldScene: PackedScene = preload('res://scenes/world/world.tscn')
var world: Spatial
var lobby: Control

onready var options_menu: PopupPanel = $"%OptionsMenu"



func _ready() -> void:
	Global.connect('game_started', self, '_on_Global_game_started')
	Global.connect('game_ended', self, '_on_Global_game_ended')
	
	lobby = LobbyScene.instance()
	add_child(lobby)
	var lobby_id: int = get_lobby_id_from_invite()
	if lobby_id != NO_LOBBY:
		Global.join_lobby(lobby_id)


func get_lobby_id_from_invite() -> int:
	var ARGUMENTS: Array = OS.get_cmdline_args()
	
	# A Steam connection argument and lobby invite exists.
	if len(ARGUMENTS) > 0 and ARGUMENTS[0] == "+connect_lobby" and int(ARGUMENTS[1]) > 0:
		var invite: int = int(ARGUMENTS[1])
		Logging.debug('Joining command line invite: %d' % invite)
		return invite
	
	return NO_LOBBY


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
	
	elif event is InputEventMouseButton:
		if event.is_pressed():
			pass
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_Global_game_ended(_data: Array) -> void:
	lobby = LobbyScene.instance()
	add_child(lobby)
	world.queue_free()
	Global.update_lobby_list()


