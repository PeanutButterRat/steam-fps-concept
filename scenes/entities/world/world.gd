extends Spatial


const MAX_ENTITIES: int = 40

export var OnlinePlayerScene: PackedScene
export var TimmyScene: PackedScene

onready var spawn: Spatial = $'%Spawn'
onready var local_player: KinematicBody = $'%LocalPlayer'
onready var command_spawn_timmy: FuncRef = funcref(self, '_on_Command_spawn_timmy')
onready var command_clear_entities: FuncRef = funcref(self, '_on_Command_clear_entities')

var online_players: Dictionary = {}
var entities: Array = []


func _ready() -> void:
	Global.connect('event_occurred', self, '_on_Global_event_occurred')
	Global.connect('player_list_changed', self, '_update_players')
	Console.register('spawn_timmy', command_spawn_timmy)
	Console.register('clear_entities', command_clear_entities)
	local_player.connect('died', self, '_on_LocalPlayer_died')
	
	_update_players(Global.lobby_members)


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
			instance.set_steam_id(player)
			add_child(instance)


func _on_Command_spawn_timmy(_arguments: Array) -> String:
	var data: Dictionary = {
		Global.EVENT_OCCURRED: Global.Events.TIMMY_SPAWNED,
		Global.EVENT_DATA: [local_player.translation]
	}
	
	Global.send_P2P_Packet(Global.Recipient.ALL_MEMBERS, data)
	return Console.COMMAND_SUCCESS


func _on_Global_event_occurred(event: int, packet: Dictionary) -> void:
	var sender: int = packet.get(Global.PACKET_SENDER_KEY)
	var data: Array = packet.get(Global.EVENT_DATA)
	
	if event == Global.Events.TIMMY_SPAWNED:
		var timmy: KinematicBody = TimmyScene.instance()
		timmy.translation = data[0]
		add_child(timmy)
	
	elif event == Global.Events.PLAYER_MOVED:
		var transformation: Transform = data[0]
		online_players[sender].transform = transformation
	
	elif event == Global.Events.SHOT_ENVIRONMENT:
		var wall: CSGCylinder = CSGCylinder.new()
		wall.scale = Vector3(1, 20, 1)
		wall.translation = data[0]
		
		add_entity(wall)
	
	elif event == Global.Events.PLAYER_DIED:
		var player = data[0]
		if player in online_players:
			online_players[player].translation = spawn.translation


func _on_Command_clear_entities(args: Array) -> String:
	if not args.empty(): return Console.COMMAND_COUNT_ERROR
	
	for entity in entities:
		entity.queue_free()
	
	entities.clear()
	
	return Console.COMMAND_SUCCESS


func _on_LocalPlayer_died() -> void:
	var data: Array = [Global.STEAM_ID]
	Global.emit_event(Global.Events.PLAYER_DIED, data, Global.Recipient.ALL_MEMBERS)
	
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
				Global.emit_event(Global.Events.PLAYER_DIED, [steam_id], Global.Recipient.ALL_MEMBERS)
	
	if len(args) == 0:
		local_player.kill()
	
	return Console.COMMAND_SUCCESS
