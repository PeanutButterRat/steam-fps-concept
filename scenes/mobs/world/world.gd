extends Spatial


const MAX_ENTITIES: int = 40

export var OnlinePlayerScene: PackedScene
export var TimmyScene: PackedScene

onready var spawn: Spatial = $'%Spawn'
onready var local_player: KinematicBody = $'%LocalPlayer'

var command_spawn_timmy: FuncRef = funcref(self, '_on_Command_spawn_timmy')
var command_clear_entities: FuncRef = funcref(self, '_on_Command_clear_entities')
var command_teleport_player: FuncRef = funcref(self, '_on_Command_teleport_player')
var command_op_player: FuncRef = funcref(self, '_on_Command_op_player')
var online_players: Dictionary = {}  # Steam_id: reference
var entities: Array = []


func _ready() -> void:
	Global.connect('player_list_changed', self, '_update_players')
	Global.connect('timmy_spawned', self, '_on_Global_timmy_spawned')
	Global.connect('player_died', self, '_on_Global_player_died')
	Global.connect('timmy_died', self, '_on_Global_timmy_died')
	
	Console.register('spawn_timmy', command_spawn_timmy)
	Console.register('clear_entities', command_clear_entities)
	Console.register('tp', command_teleport_player)
	Console.register('op', command_op_player)
	
	local_player.connect('died', self, '_on_LocalPlayer_died')
	_update_players(Global.lobby_members)
	
	_on_Global_timmy_spawned([Global.generate_unique_id(), spawn.translation], 0)

func _update_players(players: Array) -> void:
	# Check for players that left the game.
	for player in online_players:
		if not player in players:
			online_players[player].queue_free()
			online_players.erase(player)
	
	# Check for players that joined the game.
	for player in players:
		if player != Global.STEAM_ID and not player in online_players:
			var instance: Mob = OnlinePlayerScene.instance()
			online_players[player] = instance
			instance.translation = spawn.translation
			instance.set_nametag(Steam.getFriendPersonaName(player))
			instance.steam_id = player
			add_child(instance)


func _on_Command_spawn_timmy(_arguments: Array) -> String:
	var data: Dictionary = {
		Global.SIGNAL_RECIEVED_KEY: Global.SignalConstants.TIMMY_SPAWNED,
		Global.SIGNAL_DATA_KEY: [Global.generate_unique_id(), local_player.translation]
	}
	
	Global.send_P2P_Packet(Global.Recipient.ALL_MEMBERS, data)
	return Console.COMMAND_SUCCESS

func _on_Global_timmy_spawned(data: Array, _sender: int) -> void:
	var timmy: KinematicBody = TimmyScene.instance()
	timmy.id = data[0]
	timmy.translation = data[1]
	add_entity(timmy)


func _on_Global_player_died(data: Array, _sender: int) -> void:
	var player = data[0]
	if player in online_players:
		online_players[player].translation = spawn.translation


func _on_Global_timmy_died(data: Array, _sender: int) -> void:
	var id: int = data[0]
	var killstring_id: int = data[1]
	
	for index in len(entities):
		var entity: Node = entities[index]
		if entity.get('id') == id:
			entities.remove(index)
			entity.queue_free()
			break 


func _on_Command_clear_entities(args: Array) -> String:
	if not args.empty(): return Console.COMMAND_COUNT_ERROR
	
	for entity in entities:
		entity.queue_free()
	
	entities.clear()
	
	return Console.COMMAND_SUCCESS


func _on_Command_teleport_player(args: Array) -> String:
	if len(args) < 0:
		return Console.COMMAND_COUNT_ERROR
	
	for player_name in args:
		for key in online_players:
			var steam_name: String = Steam.getFriendPersonaName(key)
			if steam_name == player_name:
				var data: Array = [local_player.translation]
				Global.send_signal(Global.SignalConstants.PLAYER_TELEPORTED, data, key)
	
	return Console.COMMAND_SUCCESS


func _on_Command_op_player(args: Array) -> String:
	if len(args) < 0:
		return Console.COMMAND_COUNT_ERROR
	
	for player_name in args:
		for key in online_players:
			var steam_name: String = Steam.getFriendPersonaName(key)
			if steam_name == player_name and key != Global.STEAM_ID:
				var data: Array = [local_player.translation]
				Global.send_signal(Global.SignalConstants.PLAYER_OP, data, key)
	
	return Console.COMMAND_SUCCESS


func _on_LocalPlayer_died() -> void:
	var data: Array = [Global.STEAM_ID]
	Global.send_signal(Global.SignalConstants.PLAYER_DIED, data, Global.Recipient.ALL_MEMBERS)
	
	local_player.translation = spawn.translation


func add_entity(entity: Node) -> void:
	if len(entities) >= MAX_ENTITIES:
		var deletion: Node = entities[0]
		entities.remove(0)
		deletion.queue_free()
	
	add_child(entity)
	entities.append(entity)


func _on_Command_kill(args: Array) -> String:
	for player in args:
		for steam_id in online_players:
			if online_players[steam_id].nametag == player:
				Global.send_signal(Global.SignalConstants.PLAYER_DIED, [steam_id], Global.Recipient.ALL_MEMBERS)
	
	if len(args) == 0:
		local_player.kill()
	
	return Console.COMMAND_SUCCESS
