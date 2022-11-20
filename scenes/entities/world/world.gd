extends Spatial


export var LocalPlayerScene: PackedScene
export var OnlinePlayerScene: PackedScene

var local_player: KinematicBody
var online_players: Dictionary


func _ready() -> void:
	var packet_processor: Object = funcref(self, '_on_Global_game_state_changed')
	Global.register_callback(packet_processor, 'game_state_changed')
	Global.connect('player_list_changed', self, '_update_players')
	_update_players(Global.lobby_members)


func _on_Global_game_state_changed(packet: Dictionary) -> void:
	var player: int = packet.get('from')
	var message: String = packet.get('position')  # Ex. (0, 0, 0)
	var position: Vector3 = Vector3(
		int(message[1]), int(message[4]), int(message[7])
	)
	
	if not player in online_players:
		Logging.debug('Player %d joined.' % player)
		online_players[player] = OnlinePlayerScene.instance()
	
	online_players[player].global_translation = position


func _update_players(players: Array) -> void:
	for player in online_players:
		if not player in players:
			online_players[player].queue_free()
			online_players.erase(player)
	
	for player in players:
		if not player in online_players:
			online_players[player] = OnlinePlayerScene.instance()
