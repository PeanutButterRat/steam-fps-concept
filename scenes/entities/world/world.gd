extends Spatial


export var LocalPlayerScene: PackedScene
export var OnlinePlayerScene: PackedScene

var local_player: KinematicBody
var online_players: Dictionary


func _ready() -> void:
	var packet_processor: Object = funcref(self, '_on_Global_game_state_changed')
	Global.register_func_ref(packet_processor, 'game_state_changed')


func _on_Global_game_state_changed(packet: Dictionary) -> void:
	var player: int = packet.get('from')
	var message: String = packet.get('position')  # Ex. (0, 0, 0)
	var position: Vector3 = Vector3(
		int(message[1]), int(message[4]), int(message[7])
	)
	
	if not player in online_players:
		print('Player %d joined.' % player)
		online_players[player] = OnlinePlayerScene.instance()
	
	online_players[player].global_translation = position
