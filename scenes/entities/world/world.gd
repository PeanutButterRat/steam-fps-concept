extends Spatial


export var LocalPlayerScene: PackedScene
export var OnlinePlayerScene: PackedScene

onready var spawn: Spatial = $'%Spawn'
var local_player: KinematicBody
var online_players: Dictionary


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Event_player_moved')
	Global.connect('player_list_changed', self, '_update_players')
	_update_players(Global.lobby_members)



func _on_Event_player_moved(event: int, packet: Dictionary) -> void:
	if event != Global.EVENT.PLAYER_MOVED: return
	
	var player: int = packet.get('from')
	var message: String = packet.get('position', '(0,0,0)').trim_prefix('(').trim_suffix(')')
	var floats: PoolRealArray = message.split_floats(',')
	
	var position: Vector3 = Vector3(floats[0], floats[1], floats[2])
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
			add_child(instance)
