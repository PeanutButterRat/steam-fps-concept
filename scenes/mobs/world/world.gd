extends Spatial


onready var spawn: Spatial = $'%Spawn'

var command_spawn: FuncRef = funcref(self, '_on_Command_spawn')
var command_teleport_player: FuncRef = funcref(self, '_on_Command_teleport_player')
var command_op_player: FuncRef = funcref(self, '_on_Command_op_player')
var mobs: Dictionary = {}
var local_player: Mob


func _ready() -> void:
	Global.connect('player_list_changed', self, '_update_players')
	Global.connect('mob_spawned', self, '_on_Global_mob_spawned')
	Global.connect('mob_killed', self, '_on_Global_mob_killed')
	
	Console.register('spawn', command_spawn)
	Console.register('tp', command_teleport_player)
	Console.register('op', command_op_player)
	

	var data: Array = [Mob.Type.ONLINE_PLAYER, Global.STEAM_ID, spawn.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)


func spawn_mob(type: int, mob_id: int, mob_translation: Vector3) -> Mob:
	var mob: Mob = Mob.create(type, mob_id)
	mob.translation = mob_translation
	mobs[mob_id] = mob
	add_child(mob)
	
	return mob


func remove_mob(id: int) -> void:
	var mob: Mob = mobs[id]
	remove_child(mob)
	mobs.erase(id)
	mob.queue_free()


func _on_Command_spawn(arguments: Array) -> String:
	if not len(arguments) == 1:
		return Console.COUNT_ERROR
	
	var mob: String = arguments[0]
	var type: int
	
	match mob.to_lower():
		'timmy':
			type = Mob.Type.TIMMY
		_:
			return 'Invalid mob type.'
	
	var data: Array = [type, Global.generate_unique_id(), local_player.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)
	return Console.SUCCESS


func _on_Global_mob_spawned(data: Array) -> void:
	var type: int = data[0]
	var mob_id: int = data[1]
	var mob_translation: Vector3 = data[2]
	
	if mob_id == Global.STEAM_ID:
		type = Mob.Type.LOCAL_PLAYER
	
	var mob: Mob = spawn_mob(type, mob_id, mob_translation)
	
	if mob_id == Global.STEAM_ID:
		local_player = mob


func _on_Global_mob_killed(data: Array) -> void:
	var id: int = data[0]
	if id in mobs:
		if id == local_player.id:
			local_player.kill()
		else:
			remove_mob(id)


func _on_Command_teleport_player(args: Array) -> String:
	if len(args) != 1:
		return Console.COMMAND_COUNT_ERROR
	
	var player_name: String = args[0]
	
	for key in Global.lobby_members:
		var steam_name: String = Steam.getFriendPersonaName(key)
		if player_name == steam_name:
			var data: Array = [local_player.translation]
			Global.send_signal(Global.Signals.PLAYER_TELEPORTED, data)
			return Console.COMMAND_SUCCESS
	
	if player_name == Global.STEAM_USERNAME:
		return 'You cannot teleport yourself.'
	
	return "No player found with the name of '%s.'" % player_name


func _on_Command_op_player(args: Array) -> String:
	if len(args) != 1:
		return Console.COMMAND_COUNT_ERROR
	
	var player_name: String = args[0]

	for key in Global.lobby_members:
		var steam_name: String = Steam.getFriendPersonaName(key)
		if player_name == steam_name and key != Global.STEAM_ID:
			var data: Array = [local_player.translation]
			Global.send_signal(Global.Signals.PLAYER_CONSOLE_ENABLE, data)
			return Console.COMMAND_SUCCESS
	
	if player_name == Global.STEAM_USERNAME:
		return 'You cannot change your own permissions.'
	
	return "No player found with the name of '%s.'" % player_name 


func _on_LocalPlayer_died() -> void:
	var data: Array = [Global.STEAM_ID]
	Global.send_signal(Global.Signals.PLAYER_DIED, data)
	
	local_player.translation = spawn.translation


func _on_Command_kill(args: Array) -> String:
	for player in args:
		for steam_id in Global.lobby_members:
			if mobs[steam_id].nametag == player:
				Global.send_signal(Global.Signals.PLAYER_DIED, [steam_id])
	
	if len(args) == 0:
		local_player.kill()
	
	return Console.COMMAND_SUCCESS

#[Mob type, mob ID, transform]
func _on_LocalPlayer_respawned() -> void:
	remove_mob(local_player.id)
	var data: Array = [Mob.Type.ONLINE_PLAYER, Global.STEAM_ID, spawn.translation]
	Global.send_signal(Global.Signals.MOB_SPAWNED, data)
