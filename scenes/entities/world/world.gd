extends Spatial


export var OnlinePlayerScene: PackedScene
export var TimmyScene: PackedScene

onready var spawn: Spatial = $'%Spawn'
onready var local_player: KinematicBody = $'%Player'
var online_players: Dictionary

onready var command_spawn_timmy: FuncRef = funcref(self, '_on_Command_command_spawn_timmy')


func _ready() -> void:
	Global.connect('player_moved', self, '_on_Event_player_moved')
	Global.connect('timmy_spawned', self, '_on_Event_timmy_spawned')
	Global.connect('player_list_changed', self, '_update_players')
	Console.register('spawn_timmy', command_spawn_timmy)
	
	_update_players(Global.lobby_members)


func _on_Event_player_moved(packet: Dictionary) -> void:
	var player: int = packet.get('from')
	var position: Vector3 = Global.get_event_data(packet)
	online_players[player].translation = position


func _update_players(players: Array) -> void:
	# Check for players that left the game.
	for player in online_players:
		if not player in players:
			online_players[player].queue_free()
			online_players.erase(player)
	
	# Check for players that joined the game.
	for player in players:
		if player != Global.STEAM_ID and not player in online_players:
			var instance: KinematicBody = OnlinePlayerScene.instance()
			online_players[player] = instance
			instance.translation = spawn.translation
			instance.set_nametag(Steam.getFriendPersonaName(player))
			add_child(instance)


func _on_Command_command_spawn_timmy(_arguments: Array) -> String:
	var data: Dictionary = {
		Global.EVENT_OCCURRED: Global.EVENTS.TIMMY_SPAWNED,
		Global.EVENT_DATA: [local_player.translation]
	}
	
	Global.send_P2P_Packet(Global.Recipient.ALL_MEMBERS, data)
	return Console.COMMAND_SUCCESS


func _on_Event_timmy_spawned(packet: Dictionary) -> void:
	var data: Array = packet.get(Global.EVENT_DATA)
	var timmy: KinematicBody = TimmyScene.instance()
	timmy.translation = data[0]
	
	add_child(timmy)
